"""Lipeste iesirea tools/gen_mont_scena.gd in scenes/tracks/Track21.tscn.

    python tools/splice_mont_scena.py <Track21.tscn> <mont.part>

Idempotent: sterge intai nodurile generate (zonele Zona* ale montarii si
nodurile vechi inlocuite: Portal_S/N, Zapada*, ZidAc*), apoi adauga zonele
noi la sfarsitul scenei si ext_resource-urile `m_*`.
"""
import io
import re
import sys

scene, part = sys.argv[1], sys.argv[2]
txt = io.open(scene, encoding="utf-8").read()
frag = io.open(part, encoding="utf-8").read()
hdr, nodes = frag.split("=====NODES=====")
hdr, nodes = hdr.strip("\n"), nodes.strip("\n")

blocks = re.split(r"(?m)^(?=\[node |\[connection )", txt)
head, body = blocks[0], blocks[1:]

ZONES = ("ZonaTunel", "ZonaBaraj", "ZonaZiduri", "ZonaZapada", "ZonaRepere")
OLD = re.compile(r'^\[node name="(Portal_S|Portal_N|Zapada\d+|ZidAc\d+)" parent="DecorManual"')


def drop(b):
    if OLD.match(b):
        return True
    m = re.match(r'^\[node name="[^"]+" parent="DecorManual/(Zona\w+)', b)
    if m and m.group(1) in ZONES:
        return True
    m = re.match(r'^\[node name="(Zona\w+)" type="Node3D" parent="DecorManual"', b)
    return bool(m and m.group(1) in ZONES)


kept = [b for b in body if not drop(b)]

# ext_resource-urile m_* vechi se scot, cele noi se adauga dupa ultimul ext_resource
head = re.sub(r'(?m)^\[ext_resource [^\n]*id="m_[^"]*"\]\n', "", head)
lines = head.split("\n")
last = max(i for i, l in enumerate(lines) if l.startswith("[ext_resource"))
lines[last + 1:last + 1] = hdr.split("\n")
head = "\n".join(lines)

out = head + "".join(kept).rstrip("\n") + "\n\n" + nodes + "\n"
io.open(scene, "w", encoding="utf-8", newline="\n").write(out)
print("lipit: %d noduri noi" % nodes.count("[node "))
