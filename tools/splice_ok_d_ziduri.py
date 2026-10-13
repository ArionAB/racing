"""Inlocuieste DOAR `DecorManual/ZonaD/Ziduri` din Track20.tscn cu cel din fragmentul
generat de gen_decor_ok_d.gd (restul lui ZonaD: palat, pini, flori, shisa — ramane).

    godot --headless --path . res://tools/GenDecorOkD.tscn -- --out=<fragment.txt>
    python tools/splice_ok_d_ziduri.py <fragment.txt>

Idempotent. Adauga ext_resource-ul scriptului `d_wallchain` daca lipseste.
"""
import re
import sys

TSCN = "scenes/tracks/Track20.tscn"
ZURI = "DecorManual/ZonaD/Ziduri"
frag = open(sys.argv[1], encoding="utf-8").read()
head, nodes = frag.split("###NODES###\n", 1)
head_lines = [l for l in head.splitlines() if l.strip()]

# blocurile Ziduri din fragment (grupul + modulele + suprascrierile)
new_blocks = []
for b in re.split(r"(?m)^(?=\[)", nodes):
    hdr = b.split("\n", 1)[0]
    mp = re.search(r'parent="([^"]*)"', hdr)
    mn = re.match(r'\[node name="([^"]+)"', hdr)
    parent = mp.group(1) if mp else None
    name = mn.group(1) if mn else None
    if (name == "Ziduri" and parent == "DecorManual/ZonaD") or (
            parent and (parent == ZURI or parent.startswith(ZURI + "/"))):
        new_blocks.append(b.rstrip("\n") + "\n\n")

text = open(TSCN, encoding="utf-8").read()
blocks = re.split(r"(?m)^(?=\[)", text)
out = []
first = None
for b in blocks:
    hdr = b.split("\n", 1)[0]
    mp = re.search(r'parent="([^"]*)"', hdr)
    mn = re.match(r'\[node name="([^"]+)"', hdr)
    parent = mp.group(1) if mp else None
    name = mn.group(1) if mn else None
    if (name == "Ziduri" and parent == "DecorManual/ZonaD") or (
            parent and (parent == ZURI or parent.startswith(ZURI + "/"))):
        if first is None:
            first = len(out)
            out.append(None)  # loc rezervat
        continue
    out.append(b)
assert first is not None, "nu exista Ziduri in ZonaD"
out[first] = "".join(new_blocks)

# ext_resource script + resursele de zid (daca lipsesc)
joined = "".join(x for x in out if x is not None)
for line in head_lines:
    mid = re.search(r'id="([^"]+)"', line).group(1)
    if mid in ("d_wallchain", "d_curve", "d_straight", "d_arch") and f'id="{mid}"' not in joined:
        last = max(m.end() for m in re.finditer(r"(?m)^\[ext_resource[^\n]*\n", joined))
        joined = joined[:last] + line + "\n" + joined[last:]
open(TSCN, "w", encoding="utf-8", newline="\n").write(joined)
print("ok:", sum(1 for b in new_blocks if b.startswith("[node")), "noduri Ziduri")
