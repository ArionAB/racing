"""Lipeste iesirea gen_decor_ok_dens.gd in Track20.tscn, idempotent: scoate ext_resource-urile
`o_*` si toate nodurile `DecorManual/Densitate` (inclusiv nodul), apoi le pune la loc la sfarsit."""
import sys
part = open(sys.argv[1], encoding="utf8").read().split("\n")
scn = "scenes/tracks/Track20.tscn"
txt = open(scn, encoding="utf8", newline="").read()
nl = "\r\n" if "\r\n" in txt else "\n"
lines = txt.replace("\r\n", "\n").split("\n")
ext = [l for l in part if l.startswith("[ext_resource")]
ns = part.index("; --- NODURI (de lipit la sfarsit) ---") + 1
nodes = part[ns:]
while nodes and nodes[-1] == "":
    nodes.pop()
out = []
i = 0
while i < len(lines):
    l = lines[i]
    drop = (l.startswith("[ext_resource") and 'id="o_' in l) or \
           (l.startswith("[node ") and ('name="Densitate"' in l or 'parent="DecorManual/Densitate' in l))
    if drop:
        i += 1
        if l.startswith("[node "):
            while i < len(lines) and lines[i] != "" and not lines[i].startswith("["):
                i += 1
            while i < len(lines) and lines[i] == "":
                i += 1
        continue
    out.append(l)
    i += 1
lines = out
last = max(k for k, l in enumerate(lines) if l.startswith("[ext_resource"))
lines[last + 1:last + 1] = ext
while lines and lines[-1] == "":
    lines.pop()
lines += [""] + nodes + [""]
open(scn, "w", encoding="utf8", newline="").write(nl.join(lines))
print("ext", len(ext), "noduri", sum(1 for l in nodes if l.startswith("[node ")))
