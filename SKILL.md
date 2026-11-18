---
name: verification-gate-integrity
description: Use when writing or trusting any CI gate, check script or test harness. A gate's whole value is that it goes red — prove it can before trusting green.
---

# Verification gate integrity

Applies to CI gates, check scripts, contract/snapshot comparisons, integration harnesses — anything whose output is "looks fine".

## Three questions every gate must answer

| Question | Meaning |
|:--|:--|
| Can the assertion distinguish inputs? | Different input ⇒ different result. If the variable never reaches the check, you are re-running the same input |
| Does the failure path work? | Inject a real defect ⇒ it actually goes red (not "should go red") |
| Is the coverage what you claim? | The scanned scope equals the scope you believe you scan |

"All green" is not evidence. Only a gate you have seen fail is evidence.

## Fake-green mechanisms

1. **Exit code through a pipe** — `gate.sh | tail -3; echo $?` returns `tail`'s status. Capture to a file; use `set -o pipefail`.
2. **Credential masked into a literal** — `Bearer ***` means the variable never arrives. Every request degrades to one input, exit code stays 0.
3. **Narrower scan than claimed** — `git grep -- 'src/*'` skips subdirectories. Scan the whole tree on day one.
4. **Green by changing the subject** — silencing red by renaming a table or widening a rule. Ask: does this change make the product work? If not, record it as a known gap instead of shipping it.
5. **Display layer drops rows** — join rows with newlines, and assert rendered count == data count.

## Fail closed

When the gate cannot see its input (empty dir, broken glob, missing tool), exit with a **distinct non-zero code** and say so. `0 violations of 0 files` is the most common fake green there is.

## Separate the three failure kinds

Fixture failure / auth failure / assertion failure must be distinguishable in both message and exit code. Otherwise all three read as "401" and the diagnosis lands on a human.

- Assert the fixture immediately after building it (`COUNT(*) = 1`, column exists).
- Replay **all** migrations, in order, when building a fixture database.
- Put the subject and expected value into the assertion message.

## Before trusting a new gate

Break the thing on purpose and watch it fail. Record the failure output. Then restore and confirm green. If you did not see it red, you do not know it works.
