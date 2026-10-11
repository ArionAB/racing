"""Lipeste fragmentul generat de gen_decor_ok_d.gd in Track20.tscn.

    python tools/splice_ok_d.py <fragment.txt>

Idempotent: scoate `Ziduri_D` (zidurile provizorii), tot ce e sub
`DecorManual/ZonaD` si ext_resource-urile `d_*`, apoi pune cele noi.
`Poarta_D` e mutata sub ZonaD (reparent), neschimbata ca transform.
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
poarta = None
for b in blocks:
    if b.startswith("[ext_resource") and re.search(r'id="d_', b):
        continue
    hdr = b.split("\n", 1)[0]
    mp = re.search(r'parent="([^"]*)"', hdr)
    parent = mp.group(1) if mp else None
    mn = re.match(r'\[node name="([^"]+)"', hdr)
    name = mn.group(1) if mn else None
    if name == "Ziduri_D" and parent == "DecorManual":
        continue
    if parent and (parent == "DecorManual/Ziduri_D" or parent.startswith("DecorManual/Ziduri_D/")):
        continue
    if name == "Poarta_D" and parent in ("DecorManual", "DecorManual/ZonaD"):
        poarta = b
        continue
    if parent and (parent == "DecorManual/ZonaD" or parent.startswith("DecorManual/ZonaD/")):
        continue
    kept.append(b)

poarta = poarta.replace('parent="DecorManual"', 'parent="DecorManual/ZonaD"', 1).rstrip("\n") + "\n\n"
last_ext = max(i for i, b in enumerate(kept) if b.startswith("[ext_resource"))
kept[last_ext] = kept[last_ext].rstrip("\n") + "\n" + "\n".join(ext_lines) + "\n"
zd = next(i for i, b in enumerate(kept) if b.startswith('[node name="ZonaD"'))
kept[zd] = kept[zd].rstrip("\n") + "\n\n" + poarta + nodes.rstrip("\n") + "\n\n"
open(TSCN, "w", encoding="utf-8", newline="\n").write("".join(kept))
print("ok:", len(ext_lines), "ext_resource,", nodes.count("[node "), "noduri")
