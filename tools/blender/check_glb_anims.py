"""Citeste animatiile DIN glTF (nu din Blender): check_glb_anims.py <glb> Nume1 Nume2 ...
Esueaza daca setul de nume difera exact de cel cerut sau daca vreun canal tinteste un nod inexistent."""
import json, struct, sys
path, want = sys.argv[1], sys.argv[2:]
with open(path, "rb") as f:
    f.read(12)
    ln, _ = struct.unpack("<II", f.read(8))
    g = json.loads(f.read(ln))
names = sorted(a.get("name", "?") for a in g.get("animations", []))
nodes = len(g.get("nodes", []))
bad = [c for a in g.get("animations", []) for c in a["channels"] if c["target"]["node"] >= nodes]
ok = names == sorted(want) and not bad and g.get("skins")
print("%-18s animatii=%s skins=%d %s" % (path.split("/")[-1], names, len(g.get("skins", [])), "OK" if ok else "!! DIFERA (cerut %s)" % want))
sys.exit(0 if ok else 1)
