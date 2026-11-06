"""Angkor -- val 4, grupul A: copacii care spun "Ta Prohm / Cambodgia" (kit §1.7, brief angkor.md §7 pasul 0).

  angkor/plants/tetrameles_a.glb   22-28 m: trunchi pal-argintiu, CONTRAFORTURI-PLACA (aripi plate
                                   de 3-4 m inaltime, intinse pe 8-10 m), coroana lata si plata sus
  angkor/plants/tetrameles_b.glb   la fel, alt numar/forma de contraforturi si alta coroana
  angkor/plants/dipterocarp.glb    30-38 m: trunchi foarte lung si curat, coroana mica si inalta
  angkor/plants/sugar_palm.glb     12-16 m: palmierul Borassus, trunchi gol, coroana SFERICA de evantaie

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_trees.py
ANK_ONLY=<tet_a|tet_b|dipt|palm> reface doar piesa respectiva.

Conventii (aceleasi ca `trees/banyan.glb`): DOUA noduri, `Tree_Trunk` + `Tree_Leaves`, originea la
baza trunchiului, un singur material (atlas) pe nod, fara ierarhie, fara bevel (copacii intra intr-un
MultiMesh feliat: fiecare triunghi se plateste de sute de ori).

Lectii din inventarul w1b (copacul portii ruinate a fost judecat "tevi" + "brocoli"):
  * CONTRAFORTURILE sunt ARIPI PLATE: fiecare e o serie de trapeze subtiri (grosime 0,34 -> 0,10 m)
    pe o curba concava (lunga la sol, ridicata la trunchi), nu tuburi.
  * COROANA nu e o calota uniforma: ciorchini de mase turtite la inaltimi diferite, atarnati de
    ramuri, cu goluri intre ei; cele mai deschise (`CACTUS_GREEN`) stau sus si pe margini.
Axe (Blender): X latime, Y adancime, Z sus. Frunzisul e GEOMETRIE pe atlas, nu planuri alfa.
"""

import math
import os
import bmesh
import bpy
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")
BARK = CORAL_SAND         # 19, argintiu; AO cald la emit
WOODS = WOOD              # 9 WOOD_WEATHERED: trunchiul palmierului
G_DARK = TROPICAL_GREEN   # 21
G_LIGHT = CACTUS_GREEN    # 12


def want(k):
    return not ONLY or ONLY == k


def pol(a, d, t, z):
    """(radial d, tangential t, z) in unghiul `a` -> punct in lume."""
    return Vector((math.cos(a) * d - math.sin(a) * t, math.sin(a) * d + math.cos(a) * t, z))


def fin(b, a, R, H, L, th0, bend, slot, n=6, p=1.9, th_tip=0.10):
    """Contrafort-PLACA: aripa verticala la unghiul `a`, inalta de `H` la trunchi (raza R), care
    coboara pe o curba concava si se intinde pana la `L` pe sol, grosime th0 -> th_tip.
    `bend` curbeaza aripa lateral (m la varf). n trapeze consecutive, fiecare o invelitoare
    convexa (regiunea de sub o curba concava nu e convexa in intregime)."""
    cols = []
    for i in range(n + 1):
        s = i / n
        d = R * 0.80 + (L - R * 0.80) * (s ** p)
        z = H * (1.0 - s) ** 1.15
        t = bend * (s ** 1.6)
        th = th0 + (th_tip - th0) * s
        cols.append((d, t, z, th))
    # primul trapez porneste din inima trunchiului (R*0.55) ca sa nu ramana fanta
    first = (R * 0.55, 0.0, cols[0][2], th0)
    prev_cols = [first] + cols
    for (d0, t0, z0, h0), (d1, t1, z1, h1) in zip(prev_cols[:-1], prev_cols[1:]):
        zb = 0.0
        pts = []
        for (d, t, z, th) in ((d0, t0, z0, h0), (d1, t1, z1, h1)):
            for sgn in (-1, 1):
                pts.append(pol(a, d, t + sgn * th, z))
                pts.append(pol(a, d, t + sgn * th, zb))
        hull(b, pts, slot)


def limb(b, base, tip, r0, r1, slot, sag=0.0, segments=6):
    """Ramura: taper_sweep cu un punct de mijloc. `sag` > 0 o arcuieste in sus la mijloc."""
    mid = (base + tip) * 0.5 + Vector((0, 0, sag))
    b.taper_sweep([base, mid, tip], [r0, (r0 + r1) * 0.55, r1], slot, segments=segments)


def lump(b, c, rx, rz, slot, seed):
    """Masa de frunzis turtita: elipsoid cu zgomot (boulder: inchis, fara capac plat)."""
    b.boulder(c, (rx, rx * 0.92, rz), slot, seed=seed, segments=8, rings=4, deviation=0.20)


def cluster(b, rnd, cx, cy, cz, rad, n, rx0, rz0, light_from, seed):
    """Ciorchine de `n` mase in jurul (cx, cy, cz), la inaltimi diferite. Masele de la
    `light_from` in sus (cota relativa) sunt `CACTUS_GREEN`."""
    for k in range(n):
        a = rnd() * 2.0 * math.pi
        r = rad * (0.25 + 0.75 * rnd()) if k else 0.0
        dz = (rnd() - 0.3) * rz0 * 1.5 + (k * 0.12)
        s = rx0 * (0.72 + 0.5 * rnd())
        z = cz + dz
        slot = G_LIGHT if (dz > light_from or rnd() < 0.18) else G_DARK
        lump(b, (cx + math.cos(a) * r, cy + math.sin(a) * r, z), s, rz0 * (0.8 + 0.4 * rnd()),
             slot, seed + k * 7)


# ----------------------------------------------------------------------------
def tetrameles(variant):
    """a: 26 m, 7 contraforturi (2 foarte lungi), coroana din 5 ciorchini; b: 23,5 m, 9
    contraforturi mai scurte si mai ramificate, coroana mai lata si mai joasa, in 4 ciorchini."""
    if variant == "a":
        H = 24.0
        fins = [  # (unghi grade, lungime, inaltime, grosime baza, curbura)
            (8, 4.8, 3.7, 0.36, 0.9), (60, 4.0, 3.2, 0.32, -0.7), (118, 4.6, 3.6, 0.36, 0.6),
            (176, 3.9, 3.3, 0.32, -0.8), (228, 4.7, 3.7, 0.36, 0.7), (284, 3.8, 3.1, 0.30, -0.6),
            (332, 4.3, 3.5, 0.34, 0.9)]
        seed = 11
        limbs = [(30, 6.5, H - 11.0, H - 6.2), (95, 7.4, H - 12.5, H - 7.5), (160, 6.2, H - 10.5, H - 5.6),
                 (225, 7.2, H - 12.0, H - 7.0), (290, 6.6, H - 11.5, H - 6.4), (345, 3.6, H - 7.0, H - 1.8),
                 (60, 3.2, H - 6.0, H - 1.2), (200, 3.4, H - 6.5, H - 1.4)]
        sizes = (4.4, 2.1)
        r_trunk = [1.75, 1.30, 1.05, 0.95, 0.88, 0.80]
    else:
        H = 23.5
        fins = [
            (0, 4.5, 3.4, 0.30, 0.8), (42, 3.5, 2.9, 0.26, -0.6), (85, 4.7, 3.8, 0.32, 0.7),
            (130, 3.6, 3.0, 0.27, -0.8), (172, 4.4, 3.5, 0.30, 0.5), (215, 3.7, 3.1, 0.26, 0.9),
            (258, 4.8, 3.9, 0.32, -0.7), (300, 3.4, 2.9, 0.26, 0.6), (342, 4.1, 3.4, 0.29, -0.5)]
        seed = 29
        limbs = [(10, 7.8, H - 9.5, H - 5.2), (80, 6.4, H - 8.5, H - 3.4), (150, 7.6, H - 10.0, H - 6.0),
                 (215, 6.0, H - 8.0, H - 3.0), (280, 7.4, H - 9.8, H - 5.5), (330, 3.4, H - 6.0, H - 1.4)]
        sizes = (4.8, 1.9)
        r_trunk = [1.65, 1.25, 1.00, 0.90, 0.82, 0.76]

    rnd = lcg(seed)
    bt = Builder()
    ztk = [0.0, 3.0, 8.0, 15.0, 21.0, H - 2.0]
    path = [Vector((0.15 * math.sin(z * 0.23), 0.12 * math.cos(z * 0.19), z)) for z in ztk]
    bt.taper_sweep(path, r_trunk, BARK, segments=9)
    for (ad, L, Hf, th, bend) in fins:
        fin(bt, math.radians(ad), r_trunk[1], Hf + 1.3, L + 0.25, th, bend, BARK)
    bc = Builder()
    tips = []
    for (ad, rr, zb, zt) in limbs:
        a = math.radians(ad)
        base = Vector((path[-1].x * 0.0, 0.0, zb))
        tip = Vector((math.cos(a) * rr, math.sin(a) * rr, zt))
        limb(bt, base, tip, 0.62, 0.22, BARK, sag=0.6, segments=6)
        tips.append(tip)
    # coroana: un ciorchine pe fiecare ramura, decalat pe ramura (nu in varf), + capac sus
    for k, tip in enumerate(tips):
        cluster(bc, rnd, tip.x * 0.95, tip.y * 0.95, tip.z + 0.9, 2.8, 4, sizes[0], sizes[1],
                1.0, seed * 3 + k * 31)
    cluster(bc, rnd, 0.0, 0.0, H - 1.0, 2.8, 4, sizes[0] * 0.9, sizes[1] * 0.9, 0.5, seed * 5)
    return H, bt.to_object("Tree_Trunk"), bc.to_object("Tree_Leaves")


def dipterocarp():
    H = 34.0
    rnd = lcg(53)
    bt = Builder()
    ztk = [0.0, 2.0, 8.0, 17.0, 25.0, 29.0]
    path = [Vector((0.12 * math.sin(z * 0.17), 0.10 * math.cos(z * 0.15), z)) for z in ztk]
    bt.taper_sweep(path, [1.15, 0.92, 0.80, 0.72, 0.62, 0.52], BARK, segments=9)
    for k in range(6):  # evazarea mica de la baza: aripi scurte
        a = math.radians(30 + k * 60 + (k % 2) * 14)
        fin(bt, a, 0.92, 1.7 + 0.4 * (k % 3), 2.1 + 0.5 * (k % 2), 0.20, 0.3 * (1 if k % 2 else -1),
            BARK, n=4, p=1.7, th_tip=0.07)
    bc = Builder()
    tips = []
    for ad, rr, zb, zt in ((15, 5.0, 22.0, 28.0), (85, 4.4, 23.5, 30.0), (150, 5.4, 21.5, 27.0),
                           (215, 4.6, 23.0, 29.0), (285, 5.2, 22.5, 28.5), (345, 2.8, 26.0, 32.0)):
        a = math.radians(ad)
        tip = Vector((math.cos(a) * rr, math.sin(a) * rr, zt))
        limb(bt, Vector((0, 0, zb)), tip, 0.46, 0.16, BARK, sag=0.5, segments=6)
        tips.append(tip)
    for k, tip in enumerate(tips):
        cluster(bc, rnd, tip.x * 0.92, tip.y * 0.92, tip.z + 0.8, 2.2, 4, 3.3, 1.8, 0.8, 700 + k * 31)
    cluster(bc, rnd, 0.0, 0.0, H - 1.5, 2.2, 4, 3.2, 1.8, 0.5, 777)
    return H, bt.to_object("Tree_Trunk"), bc.to_object("Tree_Leaves")


def fan(b, d, roll_deg, L, slot, rnd, fingers=7, spread_deg=140.0, droop=0.0):
    """Evantai palmat: `fingers` degete, fiecare o lama ascutita (apex gros -> burta la 60% ->
    varf), toate pornind din acelasi punct, desfacute in planul (d, tangenta); varfurile pica
    usor (`droop`). Golul dintre degete (30%) citeste ca frunza taiata, nu ca placa."""
    d = d.normalized()
    w = d.cross(Vector((0, 0, 1)))
    if w.length < 1e-3:
        w = Vector((1, 0, 0))
    w.normalize()
    n = d.cross(w).normalized()
    rr = Matrix.Rotation(math.radians(roll_deg), 3, d)
    w, n = rr @ w, rr @ n
    apex = d * 0.6
    th = 0.03
    half = math.radians(spread_deg) / 2.0
    for j in range(fingers):
        f = (j + 0.5) / fingers * 2.0 - 1.0
        ang = f * half
        ang_w = half * 2.0 / fingers * 0.46
        dirv = d * math.cos(ang) + w * math.sin(ang)
        ll = L * (1.0 - 0.22 * abs(f) ** 1.5) * (0.92 + 0.16 * rnd())
        mid = apex + dirv * ll * 0.6 + n * 0.12
        tip = apex + dirv * ll + Vector((0, 0, -droop * (0.35 + abs(f)))) + n * 0.05
        tdir = n.cross(dirv).normalized()
        mw = ll * 0.62 * math.tan(ang_w) * 1.25
        pts = []
        for s_ in (-1, 1):
            pts.append(apex + n * s_ * th + tdir * 0.025)
            pts.append(apex + n * s_ * th - tdir * 0.025)
            pts.append(mid + tdir * mw + n * s_ * th * 0.7)
            pts.append(mid - tdir * mw + n * s_ * th * 0.7)
        pts.append(tip)
        hull(b, pts, slot)


def sugar_palm():
    H_TRUNK = 12.0
    rnd = lcg(71)
    bt = Builder()
    ztk = [0.0, 1.2, 4.0, 8.0, H_TRUNK]
    path = [Vector((0.10 * math.sin(z * 0.31), 0.08 * math.cos(z * 0.27), z)) for z in ztk]
    bt.taper_sweep(path, [0.50, 0.40, 0.34, 0.31, 0.29], WOODS, segments=8)
    # inele de cicatrici de frunze: cateva toruri subtiri (Borassus are trunchi rugos)
    for z in (2.6, 5.0, 7.2, 9.4, 11.3):
        r = 0.34 - 0.0085 * z + 0.04
        bt.torus((path[0].x, path[0].y, z), r, 0.055, WOODS, major_seg=8, minor_seg=4)
    bf = Builder()
    cz = H_TRUNK + 0.9
    n_fans = 20
    ga = math.pi * (3.0 - math.sqrt(5.0))
    for i in range(n_fans):
        # Fibonacci pe sfera, de la +1 (varf) la ~-0,35 (sub orizont): coroana sferica
        zc = 0.95 - (i + 0.5) / n_fans * 1.5
        r = math.sqrt(max(0.0, 1.0 - zc * zc))
        ph = i * ga
        d = Vector((math.cos(ph) * r, math.sin(ph) * r, zc))
        slot = G_LIGHT if (i % 3 != 1) else G_DARK
        c = Vector((path[-1].x, path[-1].y, cz))
        tmp = Builder()
        fan(tmp, d, rnd() * 30.0 - 15.0, 2.3 + 0.25 * rnd(), slot, rnd, droop=0.35)
        #)
        # translatam evantaiul in centrul coroanei
        for v in tmp.bm.verts:
            v.co += c
        _merge(bf, tmp)
    return cz + 2.5, bt.to_object("Tree_Trunk"), bf.to_object("Tree_Leaves")


def _merge(dst, src):
    """Copiaza geometria (cu atributul de slot) din builder-ul `src` in `dst`."""
    vmap = {}
    for v in src.bm.verts:
        vmap[v.index] = dst.bm.verts.new(v.co)
    for f in src.bm.faces:
        nf = dst.bm.faces.new([vmap[v.index] for v in f.verts])
        nf[dst.slot] = f[src.slot]


def emit_tree(objs, name, H):
    ao = dict(samples=28, dist=3.6, gradient="vertical", low=0.46, high=1.0, power=0.9,
              floor=0.14, z_range=(0.0, H * 0.9))
    return emit_angkor(objs, "plants/" + name + ".glb", ao, bevel=0.0, smooth_angle=45.0, anchor=(0.0, 0.0),
                       ao_tint={"Tree_Trunk": (0.85, 1.25, 1.75)} if name != "sugar_palm" else None)


clear_built()
for key, fn, name in (("tet_a", lambda: tetrameles("a"), "tetrameles_a"),
                      ("tet_b", lambda: tetrameles("b"), "tetrameles_b"),
                      ("dipt", dipterocarp, "dipterocarp"),
                      ("palm", sugar_palm, "sugar_palm")):
    if not want(key):
        continue
    H, trunk_o, leaves_o = fn()
    emit_tree([trunk_o, leaves_o], name, H)
    clear_built()

report_angkor()
