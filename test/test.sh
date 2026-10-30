#!/bin/sh
# sh test/test.sh: checks reviewbench.sh with fake agents. No network, no model.
cd "$(dirname "$0")/.." || exit 1
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
printf -- '--- a/x\n+++ b/x\n@@ -1 +1 @@\n-a\n+b\n' > "$T/x.diff"

./reviewbench.sh "$T/x.diff" 3 -o "$T/r1" -- 'echo "{\"result\": \"looks fine\", \"modelUsage\": {\"m\": {}}}"' >/dev/null; code=$?
check "three runs, three files" '[ $code -eq 0 ] && [ $(ls "$T/r1" | wc -l) -eq 3 ]'
check "the reply and model are kept" 'grep -q "looks fine" "$T/r1/x-2.json" && grep -q "\"m\"" "$T/r1/x-2.json"'

./reviewbench.sh "$T/x.diff" 1 -o "$T/r2" -p "find bugs" -- 'cat' >/dev/null
check "the prompt is the diff, fenced, then the question" 'grep -q "find bugs" "$T/r2/x-1.json" && grep -q "diff" "$T/r2/x-1.json"'

./reviewbench.sh "$T/x.diff" 1 -o "$T/r3" -- 'pwd' >/dev/null
check "each run starts in a fresh temp folder" '! grep -q "$PWD" "$T/r3/x-1.json"'

./reviewbench.sh "$T/x.diff" 2 -o "$T/r4" -- 'exit 4' >/dev/null 2>&1; code=$?
check "a failing agent is kept and the exit code says so" '[ $code -eq 3 ] && [ -f "$T/r4/x-1.json" ]'

./reviewbench.sh "$T/nope.diff" 1 >/dev/null 2>&1; code=$?
check "a missing diff is a usage error" '[ $code -eq 2 ]'
./reviewbench.sh "$T/x.diff" lots >/dev/null 2>&1; code=$?
check "a non-numeric run count is a usage error" '[ $code -eq 2 ]'
exit $fail
