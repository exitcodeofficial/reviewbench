# reviewbench.sh

"An AI found this bug with one prompt." Did it? Once, or every time? And would it have said "fix this" or "looks fine"?

`reviewbench.sh` gives a model the same diff and the same question many times, each run in a new empty folder with
tools off (no web search, no files), and keeps every reply, so you can count instead of quoting one screenshot.

```
./reviewbench.sh change.diff 10                          # Claude Code, model "fable", prompt "spot anything erroneous with this?"
./reviewbench.sh change.diff 10 -m opus -p "Review this for security bugs."
./reviewbench.sh change.diff 10 -- my-agent --print      # any agent that reads the prompt on stdin
```

Each run is saved as `runs/<diff>-<n>.json` with the prompt, the reply, the models the CLI reported and the exit code.
Exit 0 means every run replied, 2 means usage, 3 means at least one run failed (it's kept, marked with its exit code).
Labelling is up to you: write the rubric down before you read the replies.

## Example: the Liquid range-proof cache bug (`examples/liquid/`)

On 6 Sep 2026 about 4,000 unbacked L-BTC were minted on Liquid and redeemed for 3,996 BTC. The cause was a fix: commit
`c26d719` added the asset commitment and the script to a cache key, but joined the fields with no lengths, so a valid output
and an invalid one could split the same bytes differently and share a key. A post claimed an AI found "this bug" with the
prompt "spot anything erroneous with this?". We ran that prompt 10 times on each of three real diffs (Fable 5.1 via Claude
Code 2.1.309, 30 Oct 2026), and labelled the replies against `RUBRIC.md`, written before any result was read:

| Diff | Result |
|---|---|
| `2018.diff`: the 2018 key drops the asset and script | caught 10 / 10 |
| `aug2026.diff`: the fix that caused the theft | noticed the missing lengths 9 / 10; called it a bug to fix 3 / 10; said "no error" or a hardening note 6 / 10; 1 / 10 argued it was safe |
| `final.diff`: the correct, length-prefixed fix | false alarms 0 / 10 |

All 30 replies are in `examples/liquid/runs/`, labels with a verbatim quote each in `labels.json`. `collision.py` shows
the key collision in miniature, built like the real attack (Alpen's incident analysis): a valid "seed" output whose script
carries the attacker's fields, and an invalid "target" whose proof is the seed's bytes plus two.

Caveats: one model, 30 runs, three short diffs; in a real review nobody hands the model the right twelve lines. The model
may have been trained on reports of the incident (it made no web searches, and the diffs don't mention Liquid). Every run
also shows a small Haiku 5.5 call (about 2,500 tokens in, 18 out): Claude Code's own housekeeping, not the review.

Sources: https://blog.blockstream.com/liquid-network-security-incident-assessment/ ·
https://github.com/ElementsProject/elements/pull/1592 · https://github.com/ElementsProject/elements/pull/1600 ·
https://www.alpen.org/files/liquid-incident.pdf
