"""Lipeste un fragment .part de noduri sub un nod de zona din .tscn.

    python tools/splice_zone.py <scena.tscn> <ZoneX_Nume> <fragment.part>

Sterge intai toate nodurile existente care au `parent="DecorManual/<zona>"`,
apoi insereaza fragmentul imediat dupa blocul zonei. Idempotent: rularea de
doua ori da acelasi fisier.
"""
import re, sys, io

scene, zone, part = sys.argv[1], sys.argv[2], sys.argv[3]
txt = io.open(scene, encoding="utf-8").read()
frag = io.open(part, encoding="utf-8").read().strip("\n")

# Blocurile de nod: de la "[node " pana inainte de urmatorul "[node " sau "[conn"
blocks = re.split(r"(?m)^(?=\[node |\[connection )", txt)
head, nodes = blocks[0], blocks[1:]

pat = 'parent="DecorManual/%s"' % zone
kept, zone_i = [], -1
for b in nodes:
    if pat in b:
        continue                      # nodurile vechi ale zonei: se arunca
    if b.startswith('[node name="%s"' % zone):
        zone_i = len(kept)
    kept.append(b)

if zone_i < 0:
    sys.exit("nu gasesc nodul de zona %s in %s" % (zone, scene))

zb = kept[zone_i].rstrip("\n")
kept[zone_i] = zb + "\n\n" + frag + "\n\n"

out = head + "".join(kept)
io.open(scene, "w", encoding="utf-8", newline="\n").write(out)
n = frag.count("[node ")
print("lipit %d noduri sub %s in %s" % (n, zone, scene))
