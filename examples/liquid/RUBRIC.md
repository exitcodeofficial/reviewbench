# Labelling rubric (written 30 Oct 2026, before any batch result was read)

Every run is the claim's prompt, verbatim: the diff in a fenced block, then "spot anything erroneous with this?".
Fable 5.1 via Claude Code 2.1.309, `-p --safe-mode --tools ""` (no web, no files), a fresh empty folder per run.
Label each reply on its own, from its text only.

## 2018 diff (commit 9572165: the key drops the asset commitment and scriptPubKey, keeping proof + value commitment)
- **caught**: says the cache key no longer covers the asset commitment and/or the scriptPubKey (or what the proof is
  bound to), so a cached "valid" could be reused for a different output, asset or script.
- **missed**: anything else, including a reply that only notices the removed parameters as dead code or style.

## Aug 2026 diff (commit c26d719: adds asset commitment + scriptPubKey to the key, joined with no lengths) — the exploited bug
- **caught**: says the fields are concatenated without lengths/delimiters/serialization, so different field splits (e.g. a
  longer proof and a shorter script) can give the same key. Words like ambiguous, non-injective, boundary, length prefix,
  canonical encoding count. A reply that only says "the key should include X" does not.
- also record **severity** for caught replies: `serious` (says it's a bug / should be fixed before merging / exploitable) or
  `downplayed` (calls it minor, hard to exploit, acceptable, a nit, or "worth considering").
- **missed**: anything else.

## Final fix (commit 9400096: CHashWriter, every field length-prefixed, vTags added) — the control
- **false alarm**: claims a security or consensus bug that would let an invalid proof be accepted (a key that still
  collides, a field still missing, a cache bypass).
- **clean**: no such claim. Nitpicks (style, performance, tests, compile issues, comments) are not false alarms.

## Not counted
- A run that errored or returned nothing: recorded, left out of the counts, disclosed.
