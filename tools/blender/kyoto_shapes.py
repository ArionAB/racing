"""Vocabular de forme japoneze, pentru kitul Kyoto (Track18).

Lectia Jodhpur: fara vocabular, constructorul reinventeaza forma din cutii si
iese altceva decat planșa. Aici sunt formele care definesc Kyoto-ul si pe care
`dio_lib.Builder` nu le are: **acoperisul in patru ape cu streasina curbata in
sus si cu nervuri de tigla** (yosemune), inelele de la varful pagodei, frunzisul
de arțar in ciorchini turtiti.

Se incarca cu exec, dupa dio_lib (vezi build_kyoto_*.py). Functiile primesc un
`Builder` si intorc fetele noi.

Axe: X latime, Y adancime (fata spre +Y in Blender = -Z in Godot), Z sus.
"""

import math
from mathutils import Vector, Matrix


def _lerp(a, b, t):
    return a + (b - a) * t


def hip_roof(b, cx, cy, ze, hx, hy, rise, slot, ridge_half=0.0, lift=0.9,
             thick=0.28, under_slot=None, fascia_slot=None, tile_step=0.8,
             rib=0.05, sag=1.6, rings=(0.0, 0.35, 0.7, 1.0), swell=0.0):
    """Acoperis in patru ape (yosemune), cu streasina concava si colturile
    ridicate. Pagoda: `ridge_half=0` (piramida). Sala/poarta: `ridge_half>0`
    (creasta pe X).

    cx, cy        centrul in plan
    ze            cota streasinii (la mijlocul laturii, partea de sus)
    hx, hy        semi-latimile streasinii
    rise          cat urca creasta/varful peste `ze`
    lift          cat se ridica colturile streasinii fata de mijlocul laturii
    thick         grosimea lemnului de sub tigla (fateta streasinii)
    tile_step     distanta intre nervurile de tigla (m), +/- `rib` pe z
    sag           exponentul concavitatii: >1 = concav (profil japonez)
    swell         cat ies colturile in afara in plan (streasina "zboara")

    Sloturile: `slot` pe fata de tigla, `fascia_slot` pe fateta streasinii
    (implicit slot), `under_slot` pe fata de dedesubt (implicit fascia_slot).
    Intoarce multimea fetelor.
    """
    fascia_slot = slot if fascia_slot is None else fascia_slot
    under_slot = fascia_slot if under_slot is None else under_slot
    # perimetrul streasinii: puncte ordonate antiorar, cu parametrul u pe latura
    per = []
    for side, (ax, ay, dx, dy, ln) in enumerate((
            (hx, -hy, 0.0, 1.0, 2 * hy),     # dreapta, de jos in sus
            (hx, hy, -1.0, 0.0, 2 * hx),      # sus, de la dreapta la stanga
            (-hx, hy, 0.0, -1.0, 2 * hy),     # stanga
            (-hx, -hy, 1.0, 0.0, 2 * hx))):   # jos
        n = max(int(round(ln / tile_step)), 4)
        n += n % 2
        for k in range(n):
            t = k / n
            u = abs(2 * t - 1.0)               # 1 la colt, 0 la mijloc
            per.append((ax + dx * ln * t, ay + dy * ln * t, u ** 3, side, k))
    m = len(per)

    def ridge_pt(x, y):
        return (max(-ridge_half, min(ridge_half, x)), 0.0)

    def profile(s):
        return (1.0 - s) ** sag

    bm = b.bm
    faces = []
    # ringuri: pe fiecare coloana i, punctele (s) de la creasta la streasina
    cols = []
    for i, (px, py, f, side, k) in enumerate(per):
        qx, qy = ridge_pt(px, py)
        col = []
        for s in rings:
            sx = _lerp(qx, px, s)
            sy = _lerp(qy, py, s)
            # colturile zboara in afara
            if swell:
                sx += math.copysign(swell * f * s, px) if abs(px) > 1e-9 else 0.0
                sy += math.copysign(swell * f * s, py) if abs(py) > 1e-9 else 0.0
            z = ze + rise * profile(s) + lift * f * s * s
            if s > 0.2 and (i % 2 == 1):
                z += rib * min(1.0, s)
            col.append((cx + sx, cy + sy, z))
        cols.append(col)

    vcache = {}

    def V(p):
        key = (round(p[0], 5), round(p[1], 5), round(p[2], 5))
        v = vcache.get(key)
        if v is None:
            v = bm.verts.new(p)
            vcache[key] = v
        return v

    def face(pts, slot_):
        vs = []
        for p in pts:
            v = V(p)
            if not vs or vs[-1] is not v:
                vs.append(v)
        if len(vs) > 1 and vs[0] is vs[-1]:
            vs.pop()
        if len(set(vs)) < 3:
            return None
        try:
            f_ = bm.faces.new(vs)
        except ValueError:
            return None
        f_[b.slot] = slot_
        faces.append(f_)
        return f_

    nr = len(rings)
    # fata de sus (tigla)
    for i in range(m):
        j = (i + 1) % m
        for r in range(nr - 1):
            face((cols[i][r], cols[j][r], cols[j][r + 1], cols[i][r + 1]), slot)
    # fateta streasinii + fata de jos
    low = []
    for i in range(m):
        top = cols[i][-1]
        low.append((top[0], top[1], top[2] - thick))
    inner = []
    for i in range(m):
        top = cols[i][-1]
        qx, qy = ridge_pt(per[i][0], per[i][1])
        px, py = per[i][0], per[i][1]
        ix = cx + _lerp(px, qx, 0.55)
        iy = cy + _lerp(py, qy, 0.55)
        inner.append((ix, iy, ze - thick * 0.2 + 0.0))
    for i in range(m):
        j = (i + 1) % m
        face((cols[i][-1], low[i], low[j], cols[j][-1]), fascia_slot)
        face((low[i], inner[i], inner[j], low[j]), under_slot)
    # capac de jos (inchide volumul)
    ring_pts = [inner[i] for i in range(m)]
    vs = []
    for p in reversed(ring_pts):
        v = V(p)
        if not vs or vs[-1] is not v:
            vs.append(v)
    if len(set(vs)) >= 3:
        try:
            f_ = bm.faces.new(vs)
            f_[b.slot] = under_slot
            faces.append(f_)
        except ValueError:
            pass
    # capac de sus, daca nu exista creasta/varf (nu e cazul: ringul 0 e varful)
    return set(faces)


def ring_stack(b, cx, cy, z0, radius_list, step, thick, slot, segments=10):
    """Gramada de discuri subtiri (kurinrin / sorin): raza per disc, pas
    vertical `step`, grosimea `thick`."""
    faces = set()
    for i, r in enumerate(radius_list):
        faces |= b.cylinder((cx, cy, z0 + i * step + thick * 0.5), r, thick,
                            slot, segments=segments)
    return faces


def frame_ring(b, cx, cy, z, hx, hy, h, t, slot):
    """Inel dreptunghiular gol (patru grinzi) -- brau de console, talpa."""
    f = set()
    f |= b.box((cx, cy + hy - t * 0.5, z + h * 0.5), (2 * hx, t, h), slot)
    f |= b.box((cx, cy - hy + t * 0.5, z + h * 0.5), (2 * hx, t, h), slot)
    f |= b.box((cx + hx - t * 0.5, cy, z + h * 0.5), (t, 2 * hy - 2 * t, h), slot)
    f |= b.box((cx - hx + t * 0.5, cy, z + h * 0.5), (t, 2 * hy - 2 * t, h), slot)
    return f


def leaf_cluster(b, center, rx, ry, rz, slot, lobes=8, seed=0, top_slot=None,
                 notch=0.68):
    """Ciorchine de frunze de arțar: o lentila groasa cu ecuatorul in lobi
    (`lobes` varfuri, `notch` = raza crestaturilor fata de varfuri), bombata
    sus, mai plata jos. Nu e glob: raza varie pe unghi, iar ciorchinii se
    suprapun in coroana. ~8*lobes triunghiuri.
    """
    rnd = _lcg(seed)
    cx, cy, cz = center
    n = lobes * 2
    eq, up, lo = [], [], []
    for i in range(n):
        a = 2 * math.pi * i / n + (rnd() - 0.5) * 0.12
        tip = (i % 2 == 0)
        r = (1.0 if tip else notch) * (0.9 + 0.2 * rnd())
        ca, sa = math.cos(a), math.sin(a)
        eq.append(b.bm.verts.new((cx + ca * rx * r, cy + sa * ry * r,
                                  cz + rz * (0.0 + 0.12 * (rnd() - 0.5)))))
        ru = 0.74 if tip else 0.62
        up.append(b.bm.verts.new((cx + ca * rx * r * ru, cy + sa * ry * r * ru,
                                  cz + rz * 0.5)))
        rl = 0.72 if tip else 0.6
        lo.append(b.bm.verts.new((cx + ca * rx * r * rl, cy + sa * ry * r * rl,
                                  cz - rz * 0.5)))
    apex = b.bm.verts.new((cx, cy, cz + rz * 0.78))
    base = b.bm.verts.new((cx, cy, cz - rz * 0.72))
    ts = top_slot if top_slot is not None else slot
    faces = []
    for i in range(n):
        j = (i + 1) % n
        for quad, sl in (((eq[i], eq[j], up[j], up[i]), ts),
                         ((lo[i], lo[j], eq[j], eq[i]), slot)):
            f = b.bm.faces.new(quad)
            f[b.slot] = sl
            faces.append(f)
        f = b.bm.faces.new((up[i], up[j], apex)); f[b.slot] = ts; faces.append(f)
        f = b.bm.faces.new((lo[j], lo[i], base)); f[b.slot] = slot; faces.append(f)
    return set(faces)


# ---------------------------------------------------------------------------
# emit -- comun tuturor build-urilor Kyoto
# ---------------------------------------------------------------------------

RESULTS = []


def emit(objs, path, ao, origin="base", bevel=0.0, smooth_angle=None,
         budget=None, bevel_angle=30.0):
    """Finish pe fiecare nod + export. Pe piesele cu mai multe noduri offsetul
    de origine se calculeaza O DATA pe ansamblu si se aplica identic (memoria
    finish-recentreaza-fiecare-nod-separat). `path` e relativ la
    assets/models/kyoto/ (ex. "structures/yasaka_pagoda.glb")."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        if not solo:
            for v in o.data.vertices:
                v.co += place
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=("base" if solo else None), smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "kyoto/" + path)
    RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


def report():
    print()
    for path, tris, dims, budget, per_node, kb in RESULTS:
        flag = ""
        if budget is not None:
            flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
        print("%-42s tris=%6d%s  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, flag, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)
