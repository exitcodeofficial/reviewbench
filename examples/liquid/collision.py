# Liquid's cache bug in miniature, with the same shape as the real attack (Alpen's incident analysis, Figure 2).
# The cache key was SHA-256 over proof || value commitment || asset generator || script, with no lengths.
# A valid "seed" output is checked and cached. An invalid "target" splits the same bytes at different places.
import hashlib

def key_concat(proof, commitment, generator, script):          # the Aug 2026 fix (commit c26d719)
    return hashlib.sha256(proof + commitment + generator + script).hexdigest()[:16]

def key_prefixed(proof, commitment, generator, script):        # the Sep 2026 fix (commit 9400096)
    h = hashlib.sha256()
    for f in (proof, commitment, generator, script):
        h.update(len(f).to_bytes(4, "little") + f)
    return h.hexdigest()[:16]

H = b"G" * 4                                         # the L-BTC generator: the same in both (33 bytes in real life)
C_t, S_t = b"tttt", b"j"                             # what the attacker wants accepted: its commitment, a 1-byte script
P_s, C_s = b"valid-proof", b"ssss"                   # a real, valid proof for the seed output
S_s = b"6a" + C_t + H + S_t                          # the seed's script quietly carries the target's fields
P_t = P_s + C_s + H + b"6a"                          # the target's "proof": the seed's bytes, plus two

seed, target = (P_s, C_s, H, S_s), (P_t, C_t, H, S_t)
print("seed   ", [len(f) for f in seed], "  target ", [len(f) for f in target])
print("same bytes end to end:", b"".join(seed) == b"".join(target))
for name, fn in (("concatenated", key_concat), ("length-prefixed", key_prefixed)):
    a, b = fn(*seed), fn(*target)
    print(f"{name:16} seed {a}  target {b}  {'SAME KEY: cached as valid' if a == b else 'different: checked again'}")
