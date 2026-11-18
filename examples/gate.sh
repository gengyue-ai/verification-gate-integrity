#!/usr/bin/env bash
# A deliberately tiny gate, used to demonstrate that a gate which cannot fail is decoration.
# Usage: bash gate.sh <dir>
# Exit 0 = clean, 1 = violation, 2 = gate itself is broken (cannot see its input).
set -uo pipefail

DIR="${1:-fixtures}"
files=$(find "$DIR" -name '*.html' -type f 2>/dev/null | wc -l | tr -d ' ')

# Fail closed: a gate that scans nothing must not report success.
if [ "$files" -eq 0 ]; then
  echo "GATE ERROR: no .html files found under $DIR — refusing to report green" >&2
  exit 2
fi

violations=0
while IFS= read -r f; do
  # Rule: a responsive layout must not fake bullets with a bare box-shadow offset.
  if grep -qE 'box-shadow:[[:space:]]*[0-9]+px[[:space:]]+0[[:space:]]+0' "$f"; then
    echo "VIOLATION $f: bare box-shadow used as a shape" >&2
    violations=$((violations + 1))
  fi
done < <(find "$DIR" -name '*.html' -type f)

echo "scanned $files file(s), $violations violation(s)"
[ "$violations" -eq 0 ]
