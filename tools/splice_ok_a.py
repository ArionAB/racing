#!/usr/bin/env python3
"""Lipeste iesirea lui gen_decor_ok_a.gd in Track20.tscn (idempotent):
sterge ext_resource-urile `a_*` si toate nodurile `parent="DecorManual/ZonaA"`
(si descendentii lor), apoi le reinsereaza.   python tools/splice_ok_a.py <part>"""
import re, sys
part = open(sys.argv[1], encoding="utf-8").read()
hdr, nodes = part.split("=====NODES=====\n")
tscn_path = "scenes/tracks/Track20.tscn"
t = open(tscn_path, encoding="utf-8").read()
# 1) curata
t = re.sub(r'\[ext_resource [^\]]*id="a_[^"]*"\]\n', "", t)
blocks = re.split(r'(?m)^(?=\[node )', t)
keep = [b for b in blocks if not re.match(r'\[node [^\]]*parent="DecorManual/ZonaA(/|")', b)]
t = "".join(keep)
# 2) ext_resource dupa ultimul ext_resource din antet
lines = t.split("\n")
last = max(i for i, l in enumerate(lines) if l.startswith("[ext_resource"))
lines[last + 1:last + 1] = [l for l in hdr.strip().split("\n") if l]
t = "\n".join(lines)
# 3) noduri dupa ZonaA
m = re.search(r'\[node name="ZonaA"[^\n]*\n(metadata/[^\n]*\n)?\n?', t)
assert m, "ZonaA lipseste"
t = t[:m.end()] + nodes.rstrip("\n") + "\n\n" + t[m.end():]
open(tscn_path, "w", encoding="utf-8", newline="\n").write(t)
print("ok")
