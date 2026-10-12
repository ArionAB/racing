"""Lipeste fragmentul generat de gen_decor_ok_e.gd in Track20.tscn.

    python tools/splice_ok_e.py <fragment.txt>

Idempotent: scoate Far_capul_E (de oriunde din DecorManual), tot ce e sub
`DecorManual/ZonaE` si ext_resource-urile `e_*`, apoi pune cele noi. Farul e
re-emis sub ZonaE de generator (acelasi ext_resource 12_light).
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
    if b.startswith("[ext_resource") and re.search(r'id="e_', b):
        continue
    hdr = b.split("\n", 1)[0]
    mp = re.search(r'parent="([^"]*)"', hdr)
    parent = mp.group(1) if mp else None
    mn = re.match(r'\[node name="([^"]+)"', hdr)
    name = mn.group(1) if mn else None
    if name == "Far_capul_E" and parent in ("DecorManual", "DecorManual/ZonaE"):
        continue
    if parent and (parent == "DecorManual/ZonaE" or parent.startswith("DecorManual/ZonaE/")):
        continue
    kept.append(b)

last_ext = max(i for i, b in enumerate(kept) if b.startswith("[ext_resource"))
kept[last_ext] = kept[last_ext].rstrip("\n") + "\n" + "\n".join(ext_lines) + "\n"
ze = next(i for i, b in enumerate(kept) if b.startswith('[node name="ZonaE"'))
kept[ze] = kept[ze].rstrip("\n") + "\n\n" + nodes.rstrip("\n") + "\n\n"
open(TSCN, "w", encoding="utf-8", newline="\n").write("".join(kept))
print("ok:", len(ext_lines), "ext_resource,", nodes.count("[node "), "noduri")
