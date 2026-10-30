#!/bin/sh
# reviewbench.sh: ask a model to review a diff, the same way, many times, and keep every reply.
#   ./reviewbench.sh <diff> <runs> [-m model] [-p prompt] [-o outdir] [-- agent...]
# Default agent: claude -p --safe-mode --tools "" --output-format json --model <model> (no web, no files).
# Each run starts in a new empty folder. Exit 0 every run replied, 2 usage, 3 at least one run failed (kept, marked).
set -u
usage() { sed -n '3,5p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
[ $# -ge 2 ] || usage
DIFF=$1 RUNS=$2; shift 2
[ -f "$DIFF" ] || { echo "reviewbench: no such diff: $DIFF" >&2; exit 2; }
case "$RUNS" in ''|*[!0-9]*) usage ;; esac
MODEL=fable PROMPT="spot anything erroneous with this?" OUT=runs AGENT=""
while [ $# -gt 0 ]; do
  case "$1" in
    -m) MODEL=$2; shift 2 ;; -p) PROMPT=$2; shift 2 ;; -o) OUT=$2; shift 2 ;;
    --) shift; AGENT="$*"; break ;; *) usage ;;
  esac
done
[ -n "$AGENT" ] || AGENT="claude -p --safe-mode --tools \"\" --output-format json --model $MODEL"
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd); DIFF=$(cd "$(dirname "$DIFF")" && pwd)/$(basename "$DIFF")
name=$(basename "$DIFF" .diff); failed=0
i=1
while [ "$i" -le "$RUNS" ]; do
  D=$(mktemp -d)
  { printf '```diff\n'; cat "$DIFF"; printf '```\n\n%s\n' "$PROMPT"; } > "$D/prompt.txt"
  ( cd "$D" && sh -c "$AGENT" < prompt.txt > out.txt 2> err.txt ); code=$?
  python3 -I - "$D" "$OUT/$name-$i.json" "$name" "$i" "$code" "$PROMPT" <<'PY'
import json, sys
d, dest, name, i, code, prompt = sys.argv[1:]
raw = open(d + "/out.txt").read()
try:
    o = json.loads(raw); reply, models = o.get("result"), list(o.get("modelUsage", {}))
except ValueError:
    reply, models = raw, []
json.dump({"diff": name, "run": int(i), "exit": int(code), "prompt": prompt, "models": models,
           "reply": reply, "stderr": open(d + "/err.txt").read()[-500:]}, open(dest, "w"), indent=1)
PY
  if [ "$code" -ne 0 ] || [ ! -s "$D/out.txt" ]; then failed=1; echo "reviewbench: $name-$i failed (exit $code)" >&2; else echo "reviewbench: $name-$i ok"; fi
  rm -rf "$D"; i=$((i + 1))
done
[ $failed -eq 0 ] || exit 3
