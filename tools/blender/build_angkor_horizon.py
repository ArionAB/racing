"""Angkor -- FUNDALUL (kit docs/asset_briefs/angkor_kit.md §1.8, val 4, grupul C).

  angkor/effects/angkor_horizon.glb   7 noduri, copii directi ai radacinii:
    Canopy_A/B/C   marea de coronament: mase rotunjite (cupole de coroane suprapuse) cu
                   dipterocarpi emergenti; 150-250 m lungime, 20-35 m inaltime
    KulenRidge     creasta joasa si plata (Phnom Kulen, nord-est): ~300 m, 30-45 m
    StormBand_A/B  banda de nori de FURTUNA spre est: 200-300 m, BAZA PLATA la 40-60 m
                   PESTE originea nodului (norul plutește: sub el e cer), turnuri de cumulus
    Paddies_W      orezarii cu diguri + apa + palmieri de zahar, ~250 m, spre vest

CONVENTII (ca la carrara_horizon / fiordland_horizon): noduri copii ale radacinii, volume
INCHISE, lizibile din orice azimut, centrate pe X/Y, originea la BAZA (Z min = 0) --
EXCEPTIE DECLARATA: `StormBand_*` isi pastreaza baza la cota 40-60 (kit §1.8: "baza la
40-60 m"), deci fisierul ramane cu min Y = 0 doar prin celelalte noduri (verify_glb
--origin=assembly). Fara coliziune; `cast_shadow` OFF il pune `_build_horizon`.

SLOTURI (zero noi): Canopy/Kulen: TROPICAL_GREEN 21 (flancuri, jos) + CACTUS_GREEN 12 (fetele
luminate, sus), AO vertical mai inchis spre baza + `tint_gradient`. Furtuna: VOLCANIC_BLACK 20
(baza, flancuri, umbra) + MARBLE_GREY 29 (fetele de sus luminate); baza plata e mereu 20.
Orezarii: 12 camp, 21 diguri/frunze de palmier, 17 apa (REEF_SHALLOW), 20 trunchiuri de palmier
(siluete intunecate).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_horizon.py
"""

import math
import os
import bmesh
import bpy
from mathutils import Vector

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

clear_built()

G_DARK = TROPICAL_GREEN      # 21
G_LIT = CACTUS_GREEN         # 12
WATER = REEF_SHALLOW         # 17
ST_DARK = VOLCANIC_BLACK     # 20
ST_LIT = MARBLE_GREY         # 29


def hash01(a, b, seed=0):
    h = math.sin(a * 12.9898 + b * 78.233 + seed * 4.1) * 43758.5453
    return h - math.floor(h)


def smooth(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def puff(b, cx, cy, z0, rx, ry, hz, n=8, rings=3, down=0.0, rnd=None, slot=0):
    """Cupola de coroana/nor: jumatatea de sus a unui elipsoid, cu baza PLATA la z0.
    `down` > 0 adauga si jumatatea de jos (bila intreaga, pe `down` din `hz`).
    Puncte -> invelitoare convexa: volum inchis, 3*rings*n/2 triunghiuri."""
    rnd = rnd or (lambda: 0.5)
    ph = rnd() * 6.28
    pts = []
    for i in range(n):
        a = ph + 2 * math.pi * i / n
        j = 0.92 + 0.16 * rnd()
        pts.append((cx + math.cos(a) * rx * j, cy + math.sin(a) * ry * j, z0))
    for k in range(1, rings + 1):
        phi = (k / float(rings)) * math.radians(80.0)     # fara apex: calota rotunjita
        rr, zz = math.cos(phi), math.sin(phi) * hz
        m = n if k < rings else max(5, n // 2)
        for i in range(m):
            a = ph + 2 * math.pi * (i + 0.5 * k) / m
            j = 0.9 + 0.2 * rnd()
            pts.append((cx + math.cos(a) * rx * rr * j, cy + math.sin(a) * ry * rr * j, z0 + zz))
    if down > 0:
        for k in range(1, 3):
            phi = (k / 2.0) * math.pi * 0.5
            rr, zz = math.cos(phi), math.sin(phi) * hz * down
            if k == 2:
                pts.append((cx, cy, z0 - zz))
                break
            for i in range(n):
                a = ph + 2 * math.pi * (i + 0.5 * k) / n
                pts.append((cx + math.cos(a) * rx * rr, cy + math.sin(a) * ry * rr, z0 - zz))
    hull(b, pts, slot)


def retag(b, fn):
    """Reatribuie slotul fiecarei fete dupa (centru, normala)."""
    bmesh.ops.recalc_face_normals(b.bm, faces=b.bm.faces[:])
    for f in b.bm.faces:
        f.normal_update()
        f[b.slot] = fn(f.calc_center_median(), f.normal)


# ---------------------------------------------------------------------------
# Canopy: cupole suprapuse pe un contur de plan, + dipterocarpi emergenti
# ---------------------------------------------------------------------------

def canopy(name, L, W, hmean, hmax_em, seed, n_em, ao_hi=1.0):
    b = Builder()
    rnd = lcg(seed)
    step = 13.0
    nx, ny = int(L / step), int(W / step)
    for ix in range(nx + 1):
        for iy in range(ny + 1):
            u = (ix / nx - 0.5) * 2.0
            v = (iy / ny - 0.5) * 2.0
            r = (abs(u) ** 3.0 + abs(v) ** 2.4) ** (1.0 / 2.8)
            if r > 1.0:
                continue
            env = 0.42 + 0.58 * smooth(1.0, 0.45, r)
            cx = u * L * 0.5 + (rnd() - 0.5) * step * 0.8
            cy = v * W * 0.5 + (rnd() - 0.5) * step * 0.8
            noise = 0.5 + 0.5 * math.sin(cx * 0.09 + seed) * math.sin(cy * 0.13 - seed * 0.7)
            h = hmean * env * (0.74 + 0.26 * noise) * (0.9 + 0.2 * rnd())
            rad = step * (0.62 + 0.28 * rnd())
            puff(b, cx, cy, 0.0, rad, rad * 0.9, h, n=8, rings=3, rnd=rnd)
    # dipterocarpi emergenti: trunchi + coroana in nori pe 2-3 cupole
    placed = 0
    tries = 0
    while placed < n_em and tries < 400:
        tries += 1
        u = (rnd() - 0.5) * 2.0 * 0.86
        v = (rnd() - 0.5) * 2.0 * 0.6
        if (abs(u) ** 3.0 + abs(v) ** 2.4) ** (1.0 / 2.8) > 0.8:
            continue
        cx, cy = u * L * 0.5, v * W * 0.5
        top = hmax_em - 2.0 * rnd()
        b.frustum((cx, cy, (top - 6.0) * 0.5), 1.0, 0.6, top - 6.0, G_DARK, segments=6)
        crown_r = 6.5 + 2.5 * rnd()
        puff(b, cx, cy, top - 7.5, crown_r, crown_r, 6.8, n=8, rings=3, down=0.35, rnd=rnd)
        for s in range(2):
            a = rnd() * 6.28
            puff(b, cx + math.cos(a) * crown_r * 0.6, cy + math.sin(a) * crown_r * 0.6,
                 top - 8.5, crown_r * 0.55, crown_r * 0.55, 4.5, n=7, rings=2, rnd=rnd)
        placed += 1

    def slot_fn(c, n):
        zf = c.z / max(hmax_em, 1.0)
        if n.z > 0.45 and c.z > hmean * 0.55 and hash01(round(c.x / 7), round(c.y / 7), seed) < 0.62:
            return G_LIT
        return G_DARK
    retag(b, slot_fn)
    return b.to_object(name)


# ---------------------------------------------------------------------------
# heightfield inchis: creasta Kulen
# ---------------------------------------------------------------------------

def ridge(name, L, W, H, seed, cell=6.0):
    b = Builder()
    nu, nv = int(round(L / cell)), int(round(W / cell))
    grid = {}

    def hfun(x, y):
        u, v = x / (L * 0.5), y / (W * 0.5)
        fx = smooth(1.0, 0.72, abs(u)) ** 0.8
        fy = smooth(1.0, 0.30, abs(v))
        bump = 1.0 + 0.07 * math.sin(x * 0.035 + seed) + 0.05 * math.sin(x * 0.09 + y * 0.1 + seed * 2)
        shoulder = 1.0 + 0.10 * smooth(-0.3, -0.05, u) * smooth(0.35, 0.1, u) # un umar usor, la vest de centru
        return H * fx * fy * bump * shoulder * (0.96 + 0.04 * math.sin(y * 0.2 + x * 0.05))

    for i in range(nu + 1):
        for j in range(nv + 1):
            x = (i / nu - 0.5) * L
            y = (j / nv - 0.5) * W
            border = i in (0, nu) or j in (0, nv)
            z = 0.0 if border else hfun(x, y)
            grid[(i, j)] = b.bm.verts.new((x, y, z))
    for i in range(nu):
        for j in range(nv):
            f = b.bm.faces.new((grid[(i, j)], grid[(i + 1, j)], grid[(i + 1, j + 1)], grid[(i, j + 1)]))
            f[b.slot] = G_DARK
    loop = ([grid[(i, 0)] for i in range(nu + 1)] + [grid[(nu, j)] for j in range(1, nv + 1)]
            + [grid[(i, nv)] for i in range(nu - 1, -1, -1)] + [grid[(0, j)] for j in range(nv - 1, 0, -1)])
    base = b.bm.faces.new(loop[::-1])
    base[b.slot] = G_DARK
    bmesh.ops.triangulate(b.bm, faces=[f for f in b.bm.faces if len(f.verts) > 4])

    def slot_fn(c, n):
        if c.z > H * 0.55 and n.z > 0.6 and hash01(round(c.x / 9), round(c.y / 9), seed) < 0.5:
            return G_LIT
        return G_DARK
    retag(b, slot_fn)
    return b.to_object(name)


# ---------------------------------------------------------------------------
# Banda de furtuna: baza plata la `bz`, turnuri de cumulus
# ---------------------------------------------------------------------------

def storm(name, L, W, bz, tower_h, seed):
    b = Builder()
    rnd = lcg(seed)
    top_z = bz + tower_h
    # stratul de baza: sir de cupole late cu baza PLATA la bz (plafonul furtunii), groase
    nb = int(L / 24)
    for i in range(nb + 1):
        u = (i / nb - 0.5) * 2.0
        env = 0.40 + 0.60 * smooth(1.0, 0.25, abs(u))
        cx = u * L * 0.5 + (rnd() - 0.5) * 12
        for row in (-1, 0, 1):
            cy = row * W * 0.27 + (rnd() - 0.5) * 10
            rr = (30 + 10 * rnd()) * (0.8 + 0.2 * env)
            hz = tower_h * (0.46 + 0.10 * rnd()) * env
            puff(b, cx, cy, bz, rr, rr * 0.9, hz, n=9, rings=4, rnd=rnd)
    # turnurile: cupole inalte + coroana de bile (conopida de cumulus)
    nt = 6
    for i in range(nt):
        u = ((i + 0.5) / nt - 0.5) * 2.0 * 0.86
        cx = u * L * 0.5 + (rnd() - 0.5) * 16
        cy = (rnd() - 0.5) * W * 0.3
        env = 0.55 + 0.45 * smooth(1.0, 0.3, abs(u))
        hz = tower_h * (0.62 + 0.22 * rnd()) * env
        rr = (16 + 7 * rnd()) * (0.75 + 0.25 * env)
        puff(b, cx, cy, bz, rr, rr * 0.9, hz, n=10, rings=4, rnd=rnd)
        tz = bz + hz * 0.70
        th = tower_h * (0.28 + 0.12 * rnd()) * env
        puff(b, cx + (rnd() - 0.5) * 6, cy + (rnd() - 0.5) * 6, tz, rr * 0.85, rr * 0.8, th,
             n=10, rings=4, down=0.6, rnd=rnd)
        for k in range(4):
            a = rnd() * 6.28 + k * 1.57
            rb = rr * (0.32 + 0.14 * rnd())
            puff(b, cx + math.cos(a) * rr * 0.55, cy + math.sin(a) * rr * 0.5,
                 tz + th * (0.25 + 0.35 * rnd()), rb, rb, rb * 0.9, n=10, rings=4, down=1.0, rnd=rnd)
    # umerii laterali
    for i in range(8):
        u = (rnd() - 0.5) * 2.0 * 0.95
        cx = u * L * 0.5
        cy = (rnd() - 0.5) * W * 0.85
        env = 0.45 + 0.55 * smooth(1.0, 0.2, abs(u))
        rr = 10 + 7 * rnd()
        puff(b, cx, cy, bz + tower_h * 0.20 * env, rr, rr * 0.9, tower_h * 0.30 * env,
             n=8, rings=3, down=0.6, rnd=rnd)

    def slot_fn(c, n):
        zf = (c.z - bz) / max(top_z - bz, 1.0)
        # umbrire in straturi (cumulus): jos intunecat, sus luminat, cu o linie de umbra
        # usor ondulata; fetele care privesc in jos raman mereu intunecate. Doua sloturi
        # nu pot face gradient neted -- il face AO-ul copt pe varfuri (0,50 -> 0,80).
        wob = 0.10 * (hash01(round(c.x / 14), round(c.y / 14), seed) - 0.5)
        lit = zf > 0.40 + wob and n.z > 0.05
        return ST_LIT if lit else ST_DARK
    retag(b, slot_fn)
    return b.to_object(name)


# ---------------------------------------------------------------------------
# Paddies_W: orezarii, diguri, apa, palmieri de zahar, perdea de copaci
# ---------------------------------------------------------------------------

def paddies(name, L, W, seed):
    b = Builder()
    rnd = lcg(seed)
    # digurile = placa de baza, mai inalta
    b.box((0, 0, 0.35), (L, W, 0.7), G_DARK)
    cols, rows = 10, 3
    pw, pd = L / cols, (W * 0.62) / rows
    y0 = -W * 0.5 + 2.0
    for i in range(cols):
        for j in range(rows):
            cx = -L * 0.5 + (i + 0.5) * pw
            cy = y0 + (j + 0.5) * pd
            inset = 1.3 + rnd() * 0.4
            wet = hash01(i, j, seed) < 0.42
            b.box((cx, cy, 0.7 + 0.04), (pw - 2 * inset, pd - 2 * inset, 0.16), WATER if wet else G_LIT)
    # perdea de copaci joasa in spate (+Y)
    for i in range(22):
        cx = -L * 0.5 + (i + rnd()) * L / 22
        cy = W * 0.5 - 6.0 - rnd() * 4.0
        puff(b, cx, cy, 0.6, 5.0 + 3 * rnd(), 4.5 + 2 * rnd(), 5.0 + 4.5 * rnd(), n=8, rings=2, rnd=rnd, slot=G_DARK)
    # palmieri de zahar 12-16 m
    n_palm = 13
    for i in range(n_palm):
        cx = -L * 0.5 + (i + 0.3 + 0.4 * rnd()) * L / n_palm
        cy = (rnd() - 0.2) * W * 0.4 + W * 0.12
        h = 10.0 + 3.5 * rnd()
        b.frustum((cx, cy, 0.7 + h * 0.5), 0.55, 0.38, h, ST_DARK, segments=6)
        puff(b, cx, cy, 0.7 + h - 1.6, 3.4, 3.4, 3.2, n=8, rings=3, down=0.55, rnd=rnd, slot=G_DARK)
    obj = b.to_object(name)
    return obj


# ---------------------------------------------------------------------------
# emit
# ---------------------------------------------------------------------------

AO_CANOPY = dict(samples=12, dist=14.0, gradient="vertical", low=0.40, high=1.0, power=0.9,
                 floor=0.30, strength=0.9)
AO_RIDGE = dict(samples=10, dist=20.0, gradient="vertical", low=0.55, high=1.0, power=0.9, floor=0.40)
AO_STORM = dict(samples=10, dist=30.0, gradient="vertical", low=0.50, high=0.80, power=0.8,
                floor=0.40, strength=0.7)
AO_PADDY = dict(samples=10, dist=6.0, gradient="vertical", low=0.70, high=1.0, power=0.9, floor=0.5)

built = []
tris = {}


def emit(obj, ao, keep_z=False, smooth_angle=48.0, tint=None):
    vs = obj.data.vertices
    xs = [v.co.x for v in vs]
    ys = [v.co.y for v in vs]
    zs = [v.co.z for v in vs]
    dx, dy = -(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5
    dz = 0.0 if keep_z else -min(zs)
    for v in vs:
        v.co += Vector((dx, dy, dz))
    ao = dict(ao)
    zs2 = [v.co.z for v in vs]
    ao["z_range"] = (min(zs2), max(zs2))
    st = finish(obj, bevel=0.0, ao=ao, origin=None, smooth_angle=smooth_angle)
    if tint:
        tint_gradient(obj, *tint)
    tris[obj.name] = st["tris"]
    built.append(obj)


TINT_G = ((0.62, 0.68, 0.66), (1.0, 1.0, 0.92))

emit(canopy("Canopy_A", 195.0, 64.0, 21.0, 33.0, 11, 8), AO_CANOPY, tint=TINT_G)
emit(canopy("Canopy_B", 170.0, 58.0, 23.0, 34.0, 23, 6), AO_CANOPY, tint=TINT_G)
emit(canopy("Canopy_C", 225.0, 70.0, 20.0, 32.0, 37, 9), AO_CANOPY, tint=TINT_G)
emit(ridge("KulenRidge", 300.0, 84.0, 38.0, 5), AO_RIDGE, smooth_angle=40.0, tint=TINT_G)
emit(storm("StormBand_A", 240.0, 70.0, 46.0, 78.0, 71), AO_STORM, keep_z=True, smooth_angle=80.0)
emit(storm("StormBand_B", 190.0, 62.0, 54.0, 70.0, 83), AO_STORM, keep_z=True, smooth_angle=80.0)
emit(paddies("Paddies_W", 250.0, 70.0, 91), AO_PADDY, smooth_angle=35.0)

_, sz = export_glb(built, "angkor/effects/angkor_horizon.glb")
print("export: angkor/effects/angkor_horizon.glb (%.0f KB)" % (sz / 1024.0))
total = 0
for o in built:
    zs = [v.co.z for v in o.data.vertices]
    xs = [v.co.x for v in o.data.vertices]
    ys = [v.co.y for v in o.data.vertices]
    print("%-12s tris=%6d  X %.0f  Y %.0f  Z %.1f..%.1f" % (
        o.name, tris[o.name], max(xs) - min(xs), max(ys) - min(ys), min(zs), max(zs)))
    total += tris[o.name]
print("TOTAL horizon: %d tris  %s" % (total, "OK" if total <= 40000 else "PESTE 40000"))
