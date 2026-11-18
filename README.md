# Verification gates that can actually fail

A gate's entire value is that it goes red when it should. A gate that cannot fail is worse than no gate: it turns "all green" into decoration, and nothing tells you it stopped working.

This repo is one demo (`examples/gate.sh`) that fails closed, plus the catalogue of ways gates go fake-green that cost us real time.

## The demo

```bash
bash examples/gate.sh examples/fixtures          # clean input
bash examples/gate.sh /tmp/dir-with-bad-html     # one violation
bash examples/gate.sh /tmp/empty-dir             # nothing to scan
```

Actual output, 2026-11-18:

```text
== good only
scanned 1 file(s), 0 violation(s)
EXIT=0

== bad only
VIOLATION /tmp/g_bad/bad.html: bare box-shadow used as a shape
scanned 1 file(s), 1 violation(s)
EXIT=1

== empty dir (must fail closed)
GATE ERROR: no .html files found under /tmp/g_empty — refusing to report green
EXIT=2
```

Three exit codes, not two. The third one matters: **when the gate cannot see its input, it must not report success.** An empty directory, a broken glob, a missing dependency — all of those look exactly like "everything passed" if your script ends with `exit 0` on the happy path only.

## Five ways gates go fake-green

| # | Mechanism | What it looks like | Fix |
|--:|:--|:--|:--|
| 1 | **Exit code through a pipe** | `sh gate.sh \| tail -3; echo $?` reports `tail`'s status (always 0) | capture to a file, then check `$?`; `set -o pipefail` inside the script |
| 2 | **The credential was masked into a literal** | writing `Authorization: Bearer ***` instead of a variable: every request becomes the same request | keep secrets out of adjacent literals; assert "different input ⇒ different result" at least once |
| 3 | **The scan is narrower than the claim** | `git grep -l … -- 'src/*'` misses subdirectories; the gate says "clean" about 1 of 6 directories | `grep -r` over the whole tree; when you add a gate, scan everything on day one |
| 4 | **Green by changing the subject** | a red gate is silenced by renaming a table or widening the rule, not by fixing the code | before silencing, ask: does this change make the *product* work? If not, it is green-washing — record it, do not ship it |
| 5 | **The display layer drops rows** | a report joins 10 rows into one line; the renderer iterates by line and shows 1 | join with newlines, and assert `rendered count == data count` |

Mechanism 2 is the nastiest: it changes the *input* to the test, never the exit code. The gate stays green forever and looks perfectly healthy.

## A gate must also be able to lie about *why*

When a harness fails, three failures look identical from the outside: the fixture was broken, the auth was rejected, or the assertion failed. All three surface as "401" or "empty result".

- Assert the fixture right after creating it (`COUNT(*) = 1`, column exists), and exit with a **distinct code** for fixture failure.
- Write the assertion's subject and expected value into the message, not just "failed".
- Replay **all** migrations for the fixture database, in order. A fixture that replays only the create-table migration goes stale the first time someone runs an `ALTER`.

## Two real incidents from the project this came from

1. **A layout gate caught a cheat.** A decorative second dot was drawn with `box-shadow: 18px 0 0` instead of an element. The gate flagged it, the build failed, and the fix was a `::after` pseudo-element. Without the gate this ships and nobody notices — the pixels look right.
2. **A product gate caught a duplicated control.** A language switcher rendered `EN · EN · 中文` on Chinese pages. A post-build assertion — "each label appears exactly once" — was added, then **proven red** by injecting a second `EN` into the built HTML, before it was trusted.

The second one is the pattern worth copying: after writing a gate, break the thing on purpose and watch it fail. A gate you have not seen fail is a gate you do not know works.

## Use it as an agent skill

`SKILL.md` drops into a Hermes Agent skills directory as-is (`skills/<category>/verification-gate-integrity/SKILL.md`).

## License

MIT — see [LICENSE](LICENSE).
