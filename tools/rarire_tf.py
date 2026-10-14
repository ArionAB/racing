#!/usr/bin/env python3
"""Rarire deterministica a padurii (molizi + fagi) de pe Transfagarasan.

Scoate instante din stolurile `FlockProp` cu `mesh_name` Pine_* / Trunk_* /
Beech_* din `Track21.tscn`, doar in spatele primelor randuri: distanta de la
MARGINEA drumului (axa - semilatime, din `tools/data/tf_rarire/centerline.csv`,
produs de `tools/dump_tf_centerline.gd`). Fara regenerarea POI-urilor:
reparatiile manuale din .tscn raman.

Stolurile cu ACELEASI pozitii (coroana + trunchi, frunze + scoarta) primesc
aceeasi masca, deci nu ramane niciodata un trunchi fara coroana. Masca e un hash
al pozitiei (nu un RNG cu stare): rularea a doua nu schimba nimic.

  python tools/rarire_tf.py            # raport, nu scrie
  python tools/rarire_tf.py --write    # scrie scena
"""
import csv, math, re, sys, collections, hashlib

SCENE = "scenes/tracks/Track21.tscn"
CENTER = "tools/data/tf_rarire/centerline.csv"
KEEP_ALL_M = 40.0
# (de la m, pastrat) — treapta de la cea mai mare distanta potrivita castiga
BANDS = [(40.0, 0.80), (80.0, 0.62), (140.0, 0.48)]
MESH_PREFIX = ("Pine", "Trunk", "Beech")
# AMESTECUL DE TONURI (zero materiale noi): o varianta intreaga de coroana trece
# de pe `tf_jneapan` pe atlas, ca tonurile sa se amestece in spatiu, nu pe
# bucati. A: Pine_C (526 din 1500, 35 %); C: Pine_A (41 din 162, 25 %).
# F si D au deja molizii pe atlas (doar jneapanul/afinul sunt pe tf_jneapan).
TONE_ATLAS = {("ZonaA", "Pine_C"), ("ZonaC", "Pine_A")}


def load_center():
    pts = []
    with open(CENTER) as f:
        for r in csv.DictReader(f):
            pts.append((float(r["x"]), float(r["z"]), float(r["half_width"])))
    return pts


def edge_dist(pts, x, z):
    best = 1e18
    for i in range(len(pts) - 1):
        ax, az, hw = pts[i]
        bx, bz, _ = pts[i + 1]
        dx, dz = bx - ax, bz - az
        l2 = dx * dx + dz * dz
        t = 0.0 if l2 == 0 else max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / l2))
        d = math.hypot(x - (ax + t * dx), z - (az + t * dz)) - hw
        if d < best:
            best = d
    return best


def keep_prob(d):
    p = 1.0
    for lo, k in BANDS:
        if d > lo:
            p = k
    return p


def hash01(x, z):
    h = hashlib.md5(("%.1f,%.1f" % (x, z)).encode()).digest()
    return int.from_bytes(h[:4], "little") / 2**32


def main():
    write = "--write" in sys.argv
    pts = load_center()
    text = open(SCENE, encoding="utf8").read()
    blocks = re.split(r"\n(?=\[node )", text)
    pos_re = re.compile(r"^positions = PackedVector3Array\((.*)\)$", re.M)
    yaw_re = re.compile(r"^yaws = PackedFloat32Array\((.*)\)$", re.M)
    sc_re = re.compile(r"^scale3_list = Array\[Vector3\]\(\[(.*)\]\)$", re.M)
    masks = {}
    stats = collections.defaultdict(lambda: [0, 0])
    out = []
    for b in blocks:
        head = b.split("\n")[0]
        m = re.search(r'mesh_name = "([^"]*)"', b)
        pm = pos_re.search(b)
        if ("MultiMeshInstance3D" not in head or not m or not m.group(1).startswith(MESH_PREFIX) or not pm):
            out.append(b)
            continue
        zone = re.search(r'parent="DecorManual/(Zona.)"', head).group(1)
        if (zone, m.group(1)) in TONE_ATLAS:
            b = re.sub(r'^tri_class = "tf_jneapan"\n', "", b, flags=re.M)
        toks = [t.strip() for t in pm.group(1).split(",")]
        n = len(toks) // 3
        key = pm.group(1)
        if key not in masks:
            mk = []
            for i in range(n):
                x, z = float(toks[3 * i]), float(toks[3 * i + 2])
                d = edge_dist(pts, x, z)
                mk.append(hash01(x, z) < keep_prob(d))
            masks[key] = mk
        mk = masks[key]
        stats[zone][0] += n
        stats[zone][1] += sum(mk)
        if all(mk):
            out.append(b)
            continue
        nb = b
        newpos = ", ".join(toks[3 * i + j] for i in range(n) if mk[i] for j in range(3))
        nb = nb.replace(pm.group(0), "positions = PackedVector3Array(%s)" % newpos)
        ym = yaw_re.search(nb)
        if ym:
            yt = [t.strip() for t in ym.group(1).split(",")]
            assert len(yt) == n, head
            nb = nb.replace(ym.group(0), "yaws = PackedFloat32Array(%s)" % ", ".join(yt[i] for i in range(n) if mk[i]))
        sm = sc_re.search(nb)
        if sm:
            vs = re.findall(r"Vector3\([^)]*\)", sm.group(1))
            assert len(vs) == n, head
            nb = nb.replace(sm.group(0), "scale3_list = Array[Vector3]([%s])" % ", ".join(vs[i] for i in range(n) if mk[i]))
        out.append(nb)
    tot = [0, 0]
    for z in sorted(stats):
        a, k = stats[z]
        tot[0] += a; tot[1] += k
        print("%s: %d -> %d  (scoase %d)" % (z, a, k, a - k))
    print("TOTAL: %d -> %d  (scoase %d)" % (tot[0], tot[1], tot[0] - tot[1]))
    if write:
        open(SCENE, "w", encoding="utf8", newline="").write("\n".join(out))
        print("scris", SCENE)


main()
