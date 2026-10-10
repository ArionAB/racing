#!/usr/bin/env python3
"""Coacerea decorului Okinawa: WorldProp fara coliziune -> stoluri FlockProp (MultiMesh).

PASUL DE LIVRARE, nu sursa de adevar. Sursa de adevar a decorului ramane fiecare
generator (`tools/gen_decor_ok_*.gd` + `apply_zone_*.py`), care scrie noduri
`WorldProp` in `Track20.tscn`. Dupa ce o ramura aduna decor nou, se ruleaza acest
script O DATA, ca incarcarea pistei sa nu plateasca 3-4 mii de instantieri de GLB
(fiecare nod = un PackedScene intreg, cu toate variantele, plus _ready-ul WorldProp).

  python tools/bake_okinawa_decor.py [--scene scenes/tracks/Track20.tscn]
         [--godot /d/GameDev/Godot_v4.7-stable_win64_console.exe]
         [--manifest cale.json]   # refoloseste un manifest deja generat
         [--cell 80] [--min-group 3] [--dry-run]

Ce face
-------
1. Ruleaza `tools/bake_okinawa_manifest.gd` (headless): incarca pista ca in joc si
   scrie, pentru fiecare model de sub DecorManual, modul de coliziune EFECTIV
   (metadata `coliziune` sau `PROP_COLLISION`), nodurile de mesh VIZIBILE cu
   transformul lor, materialul pe care l-a pus WorldProp (atlas / `atint:` / `tri:` /
   `class:`) si daca mesh-ul a fost modificat fata de GLB. Convertorul nu reimplementeaza
   nicio mapare din world_prop.gd: citeste rezultatul lor.
2. Alege instantele convertibile: coliziune efectiva `none`, fara metadata de
   lumina/racire/clasa pe lant, fara schelet/animatie, mesh-uri neschimbate, material
   cunoscut, umbra pornita, fara oglindire (det < 0) si fara inclinare (basis =
   R_y(yaw) * diag(scala), ca FlockProp), cu parinti fara transform.
3. Grupeaza pe (zona, GLB, celula spatiala de `--cell` m, nod de mesh). O instanta
   ramane WorldProp daca grupul (zona, GLB, celula) are sub `--min-group` instante
   (un stol de 1-2 piese nu castiga nimic) sau daca are noduri-copil de override
   cu altceva decat `visible`.
4. Scrie cate un `FlockProp` pe grup, sub `DecorManual/<Zona>/Coacere`, cu
   `snap_to_ground = false` (cotele sunt deja pe teren), `view_m = 0` (acelasi
   aspect, nicio distanta de taiere noua) si `tri_class` = clasa nodului de mesh
   (FlockProp stie `atint:` / `class:` / `tri:` / atlas). Sterge nodurile
   convertite si blocurile lor de override `visible = false`.

Nu atinge: noduri cu coliziune (trunk/hull/mesh), hazarde, poarta, case, ziduri.

Idempotent si re-rulabil: stolurile `Bk_*` existente se citesc si se contopesc cu
ce apare nou (cheia e numele, derivat din GLB + mesh + zona + celula); a doua
rulare pe aceeasi scena nu schimba nimic. Tinut intentionat fara dependente (stdlib).
"""
import argparse
import collections
import json
import math
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLOCK_SCRIPT = "res://scenes/props/flock.gd"
BK = "Bk_"
CONTAINER = "Coacere"
OK_MATS = ("atlas", "atint:", "tri:", "class:")


def fmt(v, nd=6):
    s = ("%." + str(nd) + "f") % v
    s = s.rstrip("0").rstrip(".") if "." in s else s
    return "0" if s in ("-0", "") else s


def split_blocks(txt):
    return re.split(r"\n(?=\[)", txt)


def node_header(b):
    h = b.split("\n", 1)[0]
    name = re.search(r'name="([^"]*)"', h)
    parent = re.search(r'parent="([^"]*)"', h)
    inst = re.search(r'instance=ExtResource\("([^"]+)"\)', h)
    return (name.group(1) if name else None, parent.group(1) if parent else None,
            inst.group(1) if inst else None, 'type="' in h)


def run_manifest(godot, scene, out):
    scene_arg = "res://" + os.path.relpath(scene, ROOT).replace("\\", "/")
    cmd = [godot, "--headless", "--path", ROOT, "--script",
           "res://tools/bake_okinawa_manifest.gd", "--", "--out=" + out,
           "--scene=" + scene_arg]
    print("manifest:", " ".join(cmd))
    r = subprocess.run(cmd, capture_output=True, text=True)
    sys.stdout.write(r.stdout[-600:])
    if r.returncode != 0 or not os.path.exists(out):
        sys.stderr.write(r.stderr[-2000:])
        sys.exit("manifestul nu s-a generat")


def parse_xf(block):
    m = re.search(r"\ntransform = Transform3D\(([^)]*)\)", block)
    if not m:
        return None
    return [float(x) for x in m.group(1).split(",")]


def decompose(v):
    """Transform3D din .tscn (basis pe RANDURI) -> (pozitie, yaw, scala) sau None.

    FlockProp construieste Basis(UP, yaw) * from_scale(sc). Un basis cu inclinare,
    forfecare sau oglindire nu se poate reprezenta: instanta ramane WorldProp."""
    if len(v) != 12:
        return None
    r = [v[0:3], v[3:6], v[6:9]]
    col = [(r[0][i], r[1][i], r[2][i]) for i in range(3)]
    det = (r[0][0] * (r[1][1] * r[2][2] - r[1][2] * r[2][1])
           - r[0][1] * (r[1][0] * r[2][2] - r[1][2] * r[2][0])
           + r[0][2] * (r[1][0] * r[2][1] - r[1][1] * r[2][0]))
    if det <= 0:
        return None
    sc = [math.sqrt(sum(c * c for c in cc)) for cc in col]
    if min(sc) < 1e-6:
        return None
    yaw = math.atan2(-col[0][2], col[0][0])
    cy, sy = math.cos(yaw), math.sin(yaw)
    # R_y(yaw): coloanele = (c,0,-s), (0,1,0), (s,0,c); cu scala pe coloane.
    rec = [[cy * sc[0], 0, sy * sc[2]], [0, sc[1], 0], [-sy * sc[0], 0, cy * sc[2]]]
    err = max(abs(rec[i][j] - r[i][j]) for i in range(3) for j in range(3))
    if err > 4e-3:
        return None
    return (v[9], v[10], v[11]), yaw, tuple(sc)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scene", default=os.path.join(ROOT, "scenes/tracks/Track20.tscn"))
    ap.add_argument("--godot", default="/d/GameDev/Godot_v4.7-stable_win64_console.exe")
    ap.add_argument("--manifest", default="")
    ap.add_argument("--cell", type=float, default=80.0)
    ap.add_argument("--min-group", type=int, default=3)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    manifest_path = a.manifest
    if not manifest_path:
        manifest_path = os.path.join(tempfile.gettempdir(), "bake_okinawa_manifest.json")
        run_manifest(a.godot, a.scene, manifest_path)
    man = json.load(open(manifest_path, encoding="utf8"))["nodes"]

    with open(a.scene, encoding="utf8", newline="") as f:
        raw = f.read()
    crlf = "\r\n" in raw
    txt = raw.replace("\r\n", "\n")
    blocks = split_blocks(txt)

    # ext_resource: id <-> path
    id_path, path_ids = {}, collections.defaultdict(list)
    for b in blocks:
        m = re.match(r'\[ext_resource [^\]]*?path="([^"]+)"[^\]]*?id="([^"]+)"', b)
        if not m:
            m2 = re.match(r'\[ext_resource [^\]]*?id="([^"]+)"[^\]]*?path="([^"]+)"', b)
            if m2:
                id_path[m2.group(1)] = m2.group(2)
                path_ids[m2.group(2)].append(m2.group(1))
            continue
        id_path[m.group(2)] = m.group(1)
        path_ids[m.group(1)].append(m.group(2))
    flock_id = (path_ids.get(FLOCK_SCRIPT) or [None])[0]

    # cai complete ale nodurilor (relative la DecorManual) + copiii de override
    full = {}
    children_of = collections.defaultdict(list)
    for i, b in enumerate(blocks):
        if not b.startswith("[node"):
            continue
        name, parent, inst, typed = node_header(b)
        if parent is None:
            continue
        path = parent + "/" + name if parent != "." else name
        full[i] = path
    # blocurile de override: parinte = cale de instanta (sau mai adanc)
    inst_paths = {full[i]: i for i, b in enumerate(blocks)
                  if i in full and node_header(b)[2] and full[i].startswith("DecorManual/")}
    override_of = collections.defaultdict(list)  # idx instanta -> [idx override]
    bad_override = set()
    for i, b in enumerate(blocks):
        if i not in full or node_header(b)[2] or node_header(b)[3]:
            continue
        par = node_header(b)[1]
        cur = par
        while cur and cur not in inst_paths:
            cur = cur.rsplit("/", 1)[0] if "/" in cur else None
        if cur and cur in inst_paths:
            override_of[inst_paths[cur]].append(i)
            body = [l for l in b.split("\n")[1:] if l.strip()]
            if any(not l.startswith("visible = false") for l in body):
                bad_override.add(inst_paths[cur])

    # containere cu transform (ar strica coordonatele de lume)
    xf_parent = set()
    for i, b in enumerate(blocks):
        if i in full and b.startswith("[node") and not node_header(b)[2] and "\ntransform" in b:
            xf_parent.add(full[i])

    skip = collections.Counter()
    cand = {}  # idx -> dict
    for idx, path in full.items():
        b = blocks[idx]
        name, parent, inst, typed = node_header(b)
        if not inst or not path.startswith("DecorManual/"):
            continue
        rel = path[len("DecorManual/"):]
        e = man.get(rel)
        if e is None:
            skip["fara intrare in manifest"] += 1
            continue
        if e["mode"] != "none":
            skip["coliziune " + e["mode"]] += 1
            continue
        if e["blocked"] or e["anim"] or e.get("ambiguous"):
            skip["blocat/animat/ambiguu"] += 1
            continue
        if idx in bad_override:
            skip["override cu altceva decat visible"] += 1
            continue
        if not e["meshes"]:
            skip["niciun mesh vizibil"] += 1
            continue
        ok = True
        for m in e["meshes"]:
            if not m["mesh_orig"] or m["cast"] != 1 or m["vr_end"] != 0 or m["vr_begin"] != 0 \
                    or not m["mat"].startswith(OK_MATS):
                ok = False
        if not ok:
            skip["mesh/material/umbra nestandard"] += 1
            continue
        par = parent
        if any(par == p or par.startswith(p + "/") for p in xf_parent):
            skip["parinte cu transform"] += 1
            continue
        d = decompose(parse_xf(b) or [])
        if d is None:
            skip["inclinat/oglindit/forfecat"] += 1
            continue
        zone = rel.split("/")[0]
        cand[idx] = dict(rel=rel, zone=zone, glb=e["glb"], meshes=e["meshes"], xf=d, parent=parent,
                         discs=e.get("discs", []), circle=e.get("circle"))

    # populatia (zona, glb, celula)
    def cell_of(pos):
        return (int(math.floor(pos[0] / a.cell)), int(math.floor(pos[2] / a.cell)))

    pop = collections.Counter()
    for c in cand.values():
        c["cell"] = cell_of(c["xf"][0])
        pop[(c["zone"], c["glb"], c["cell"])] += 1
    chosen = {i: c for i, c in cand.items() if pop[(c["zone"], c["glb"], c["cell"])] >= a.min_group}
    skip["grup sub %d instante" % a.min_group] += len(cand) - len(chosen)

    # stolurile existente (Bk_*), contopite
    stols = collections.OrderedDict()  # (zone, name) -> dict
    drop_blocks = set()
    for i, b in enumerate(blocks):
        if i not in full:
            continue
        name, parent, inst, typed = node_header(b)
        if name and name.startswith(BK) and 'type="MultiMeshInstance3D"' in b.split("\n", 1)[0]:
            g = lambda k: (re.search(r"\n" + k + r' = (.*)', b) or [None, None])[1]
            mid = re.search(r'ExtResource\("([^"]+)"\)', g("model") or "")
            pos = re.findall(r"-?[\d.e+-]+", re.search(r"PackedVector3Array\((.*)\)", g("positions")).group(1))
            yaws = re.findall(r"-?[\d.e+-]+", re.search(r"PackedFloat32Array\((.*)\)", g("yaws")).group(1))
            sc = [x.strip() for v3 in re.findall(r"Vector3\(([^)]*)\)", re.search(r"Array\[Vector3\]\(\[(.*)\]\)", g("scale3_list")).group(1))
                  for x in v3.split(",")]
            tc = re.search(r'"([^"]*)"', g("tri_class") or '""').group(1)
            mn = re.search(r'"([^"]*)"', g("mesh_name") or '""').group(1)
            n = len(yaws)
            def opt(k, rx):
                v = g(k)
                return re.findall(r"-?[\d.]+(?:e-?\d+)?", re.search(rx, v).group(1)) if v else []
            dv = opt("contact_discs", r"PackedVector4Array\((.*)\)")
            fl = opt("contact_flat", r"PackedByteArray\((.*)\)")
            cv = opt("veg_circles", r"PackedVector3Array\((.*)\)")
            stols[(parent, name)] = dict(
                glb=id_path[mid.group(1)], mesh=mn, cls=tc, parent=parent,
                discs=[(tuple(dv[4 * k:4 * k + 4]), fl[k] if k < len(fl) else "0") for k in range(len(dv) // 4)],
                circles=[tuple(cv[3 * k:3 * k + 3]) for k in range(len(cv) // 3)],
                items=[(tuple(pos[3 * k:3 * k + 3]), yaws[k], tuple(sc[3 * k:3 * k + 3])) for k in range(n)])
            drop_blocks.add(i)

    def safe(s):
        return re.sub(r"[^A-Za-z0-9_]", "_", s)

    n_nodes = collections.Counter()
    n_new_stols = set()
    for idx, c in chosen.items():
        pos, yaw, sc = c["xf"]
        for mi, m in enumerate(c["meshes"]):
            x = m["xf"]
            # transformul nodului de mesh e copt in varfuri de FlockProp._mesh_of
            stem = os.path.basename(c["glb"])[:-4]
            cx, cz = c["cell"]
            nm = "%s%s_%s_%s%d_%s%d" % (BK, safe(stem), safe(m["name"]),
                                      "n" if cx < 0 else "p", abs(cx), "n" if cz < 0 else "p", abs(cz))
            parent = "DecorManual/%s/%s" % (c["zone"], CONTAINER)
            key = (parent, nm)
            st = stols.setdefault(key, dict(glb=c["glb"], mesh=m["name"], cls=m["mat"], parent=parent,
                                            items=[], discs=[], circles=[]))
            if st["glb"] != c["glb"] or st["mesh"] != m["name"] or st["cls"] != m["mat"]:
                sys.exit("conflict de nume de stol " + nm)
            item = ((fmt(pos[0], 5), fmt(pos[1], 5), fmt(pos[2], 5)), fmt(yaw),
                    (fmt(sc[0]), fmt(sc[1]), fmt(sc[2])))
            if item not in st["items"]:
                st["items"].append(item)
                n_new_stols.add(key)
            if mi == 0:  # amprenta piesei sta pe primul ei stol (un disc per piesa)
                for dd in c["discs"]:
                    dk = (tuple(fmt(v, 5) for v in dd[:4]), str(dd[4]))
                    if dk not in st["discs"]:
                        st["discs"].append(dk)
                if c["circle"]:
                    ck = tuple(fmt(v, 5) for v in c["circle"])
                    if ck not in st["circles"]:
                        st["circles"].append(ck)
        n_nodes[c["glb"]] += 1

    print("candidate:", len(cand), " convertite:", len(chosen), " stoluri:", len(stols),
          " (noi/modificate: %d)" % len(n_new_stols))
    for k, v in sorted(skip.items()):
        print("  ramase WorldProp -", k, ":", v)
    by_zone = collections.Counter(c["zone"] for c in chosen.values())
    print("  pe zone:", dict(sorted(by_zone.items())))
    if a.dry_run:
        return

    # reconstruieste scena
    remove = set(drop_blocks)
    for idx in chosen:
        remove.add(idx)
        remove.update(override_of.get(idx, []))
    out_blocks = []
    last_node = -1
    for i, b in enumerate(blocks):
        if i in remove:
            continue
        out_blocks.append(b)
        if b.startswith("[node") or b.startswith("[ext_resource") and False:
            last_node = len(out_blocks) - 1
    # containerul Coacere per zona (existent sau nou)
    have = {full[i] for i in full if i not in remove}
    new_ext = []
    new_nodes = []
    zones = sorted({k[0].split("/")[1] for k in stols})
    for z in zones:
        if "DecorManual/%s/%s" % (z, CONTAINER) not in have:
            new_nodes.append('[node name="%s" type="Node3D" parent="DecorManual/%s"]\n' % (CONTAINER, z))
    if stols and flock_id is None:
        flock_id = "bk_flock"
        new_ext.append('[ext_resource type="Script" path="%s" id="%s"]\n' % (FLOCK_SCRIPT, flock_id))
        path_ids[FLOCK_SCRIPT].append(flock_id)
    for (parent, nm), st in sorted(stols.items()):
        ids = path_ids.get(st["glb"])
        if not ids:
            mid = "bk_" + safe(os.path.basename(st["glb"])[:-4])
            new_ext.append('[ext_resource type="PackedScene" path="%s" id="%s"]\n' % (st["glb"], mid))
            path_ids[st["glb"]].append(mid)
            ids = [mid]
        items = st["items"]
        pos = ", ".join(", ".join(it[0]) for it in items)
        yaws = ", ".join(it[1] for it in items)
        sc = ", ".join("Vector3(%s)" % ", ".join(it[2]) for it in items)
        lines = ['[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % (nm, parent),
                 'script = ExtResource("%s")' % flock_id,
                 'model = ExtResource("%s")' % ids[0],
                 'mesh_name = "%s"' % st["mesh"]]
        if st["cls"] not in ("", "atlas"):
            lines.append('tri_class = "%s"' % st["cls"])
        if st["discs"]:
            lines.append("contact_discs = PackedVector4Array(%s)" % ", ".join(", ".join(d[0]) for d in st["discs"]))
            if any(d[1] != "0" for d in st["discs"]):
                lines.append("contact_flat = PackedByteArray(%s)" % ", ".join(d[1] for d in st["discs"]))
        if st["circles"]:
            lines.append("veg_circles = PackedVector3Array(%s)" % ", ".join(", ".join(c) for c in st["circles"]))
        lines += ["positions = PackedVector3Array(%s)" % pos,
                  "yaws = PackedFloat32Array(%s)" % yaws,
                  "scale3_list = Array[Vector3]([%s])" % sc]
        new_nodes.append("\n".join(lines) + "\n")

    # ext_resource noi dupa ultimul ext_resource existent
    if new_ext:
        last_ext = max(i for i, b in enumerate(out_blocks) if b.startswith("[ext_resource"))
        out_blocks[last_ext + 1:last_ext + 1] = [e.rstrip("\n") for e in new_ext]
    # nodurile noi dupa ultimul bloc [node ...] (inaintea [connection]/[editable])
    last_node = max(i for i, b in enumerate(out_blocks) if b.startswith("[node"))
    out_blocks[last_node + 1:last_node + 1] = [n.rstrip("\n") for n in new_nodes]
    res = "\n".join(out_blocks)
    if not res.endswith("\n"):
        res += "\n"
    if crlf:
        res = res.replace("\n", "\r\n")
    with open(a.scene, "w", encoding="utf8", newline="") as f:
        f.write(res)
    print("scris", a.scene)


if __name__ == "__main__":
    main()
