"""Lipeste iesirea gen_decor_ok_h.gd (zonaH.part) in Track20.tscn, idempotent:
scoate grupul provizoriu Dig_tetrapozi, nodurile `parent="DecorManual/ZonaH`
si ext_resource-urile `h_*`, apoi le pune la loc."""
import sys
part = open(sys.argv[1], encoding="utf8").read().split("\n")
scn = "scenes/tracks/Track20.tscn"
txt = open(scn, encoding="utf8", newline="").read()
nl = "\r\n" if "\r\n" in txt else "\n"
lines = txt.replace("\r\n", "\n").split("\n")
ext = [l for l in part if l.startswith("[ext_resource")]
nodes_start = part.index("; --- NODURI (de lipit la sfarsit, sub ZonaH) ---") + 1
nodes = part[nodes_start:]
while nodes and nodes[-1] == "":
    nodes.pop()


def strip(lines, pred):
    out = []
    i = 0
    while i < len(lines):
        l = lines[i]
        if pred(l):
            i += 1
            if l.startswith("[node "):
                while i < len(lines) and lines[i] != "" and not lines[i].startswith("["):
                    i += 1
                while i < len(lines) and lines[i] == "":
                    i += 1
            continue
        out.append(l)
        i += 1
    return out


lines = strip(lines, lambda l: (l.startswith("[ext_resource") and 'id="h_' in l) or
              (l.startswith("[node ") and 'parent="DecorManual/ZonaH' in l) or
              (l.startswith("[node ") and ('name="Dig_tetrapozi"' in l or 'parent="DecorManual/Dig_tetrapozi' in l)))
last = max(k for k, l in enumerate(lines) if l.startswith("[ext_resource"))
lines[last + 1:last + 1] = ext
z = next(k for k, l in enumerate(lines) if l.startswith('[node name="ZonaH"'))
e = z + 1
while e < len(lines) and lines[e] != "":
    e += 1
lines[e + 1:e + 1] = nodes + [""]
open(scn, "w", encoding="utf8", newline="").write(nl.join(lines))
print("ext", len(ext), "noduri", sum(1 for l in nodes if l.startswith("[node ")))
