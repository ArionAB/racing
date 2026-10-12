"""Lipeste fragmentul generat de gen_decor_ok_b.gd in Track20.tscn.

    python tools/splice_ok_b.py <fragment.txt>

Idempotent: scoate intai tot ce e sub `DecorManual/ZonaB` si ext_resource-urile
cu id `c_*`, apoi pune cele noi. Nu atinge altceva din scena.
"""
import re
import sys

TSCN = "scenes/tracks/Track20.tscn"
frag = open(sys.argv[1], encoding="utf-8").read()
head, nodes = frag.split("###NODES###\n", 1)
ext_lines = [l for l in head.splitlines() if l.strip()]

text = open(TSCN, encoding="utf-8").read()
blocks = re.split(r"(?m)^(?=\[)", text)
kept = []
for b in blocks:
    if b.startswith("[ext_resource") and re.search(r'id="b_', b):
        continue
    m = re.match(r'\[node name="[^"]+"[^\]]*parent="DecorManual/ZonaB(/[^"]*)?"', b)
    if m:
        continue
    kept.append(b)

res = []
for i, b in enumerate(kept):
    res.append(b)
# ext_resource dupa ultimul ext_resource
last_ext = max(i for i, b in enumerate(res) if b.startswith("[ext_resource"))
res[last_ext] = res[last_ext].rstrip("\n") + "\n" + "\n".join(ext_lines) + "\n"
# nodurile inainte de ZonaC
zd = next(i for i, b in enumerate(res) if b.startswith('[node name="ZonaC"'))
res[zd - 1] = res[zd - 1].rstrip("\n") + "\n\n" + nodes.rstrip("\n") + "\n\n"
open(TSCN, "w", encoding="utf-8", newline="\n").write("".join(res))
print("ok:", len(ext_lines), "ext_resource,", nodes.count("[node "), "noduri")
