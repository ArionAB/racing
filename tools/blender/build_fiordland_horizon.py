"""Fiordland — Fundalul (brief §1.2, val 4 din
docs/asset_briefs/fiordland_kit.md; refacut in kit v2, grupa F).

  fiordland/rocks/fiordland_horizon.glb   FarWall_A, FarWall_B, SnowRidge_A, SnowRidge_B

UN SINGUR fisier, 4 noduri. Consumatorul e `Track._build_horizon` (scenes/
tracks/track.gd): ia nodurile DUPA NUME (din `horizon_picks`), le asaza pe
inele la 170-300 m de centroid, le SCALEAZA 0.55-0.75x si le da un YAW
ALEATOR — deci fiecare nod trebuie sa fie un VOLUM INCHIS, lizibil din ORICE
azimut. Nodul ramane pe atlas (fara clasa), deci culorile slotului se vad.

v1 (piramide cu 3 benzi plate) iesea "Toblerone" (sawtooth). v2 pleaca de la planșa:

FarWall_A/B: perete lung (180 m), abrupt pe AMBELE fete, cu creasta zimtata
NEREGULAT (6-7 varfuri cu pante diferite si saua intre ele, nu fierastrau),
fete sparte in contraforturi si RAVENE care coboara de langa creasta. Roca
inchisa (VOLCANIC_BLACK / MARBLE_GREY pe fatetele luminate) ACOPERITA de padure
(TROPICAL_GREEN / LOG_DARK) pe cele ~2/3 de jos, mai sus in ravene si cu pete
izolate; 2-4 cascade FOAM_WHITE subtiri pe fiecare fata lunga, in fundul
ravenelor, de langa creasta in jos.

SnowRidge_A/B: masiv cu 3 varfuri (nu un con), fatete mari, zapada (FOAM_WHITE)
in PETE care coboara pe ravene si pe fetele putin inclinate (nu calota plata),
roca gri inchis dedesubt, brau de padure la baza.

Constructie: nu cuburi/conuri, ci CAMPURI DE INALTIME cusute (coloane pe
lungime pentru perete, inele polare pentru masiv); culoarea se pune pe fiecare
fata din pozitia ei (cost zero triunghiuri).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_horizon.py
"""

import math
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (brief §0.4). ROCK_DARK/ROCK_LIGHT interzise.
GNEISS_LIT = MARBLE_GREY
GNEISS_DARK = VOLCANIC_BLACK
GNEISS_MID = ASPHALT_EDGE
FOREST = TROPICAL_GREEN
FOREST_DARK = LOG_DARK
SNOW = FOAM_WHITE
FALL = FOAM_WHITE

AO_WALL = dict(samples=12, dist=30.0, gradient="vertical",
              low=0.50, high=1.00, power=0.84, floor=0.22)
AO_RIDGE = dict(samples=12, dist=24.0, gradient="vertical",
                low=0.48, high=1.00, power=0.85, floor=0.20)


def _hash(i, j=0, seed=0):
    n = (int(i) * 374761393 + int(j) * 668265263 + int(seed) * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def _vn(x, seed, scale):
    """Zgomot de valoare 1D neted, 0..1."""
    u = x / scale
    i = math.floor(u)
    f = u - i
    f = f * f * (3.0 - 2.0 * f)
    return _hash(i, 0, seed) * (1.0 - f) + _hash(i + 1, 0, seed) * f


def _vn2(x, y, seed, sx, sy):
    """Zgomot de valoare 2D neted, 0..1 (praguri netede pe fatete, nu pe celule)."""
    u, v = x / sx, y / sy
    i, j = math.floor(u), math.floor(v)
    fu, fv = u - i, v - j
    fu = fu * fu * (3.0 - 2.0 * fu)
    fv = fv * fv * (3.0 - 2.0 * fv)
    a = _hash(i, j, seed) * (1 - fu) + _hash(i + 1, j, seed) * fu
    c = _hash(i, j + 1, seed) * (1 - fu) + _hash(i + 1, j + 1, seed) * fu
    return a * (1 - fv) + c * fv


def _sstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


# --- FarWall_A / FarWall_B ----------------------------------------------------
FW_LEN = 180.0
T_ROWS = [0.0, 0.12, 0.26, 0.42, 0.58, 0.72, 0.85, 0.94, 1.0]
N_T = len(T_ROWS)


def _far_wall(seed, name, hmax, n_peaks, ravines_p, ravines_m, buttress_seed):
    """Perete lung. `ravines_p` / `ravines_m`: pozitiile X ale ravenelor pe
    fata +Y / -Y (aici se pun si cascadele)."""
    b = Builder()
    half = FW_LEN * 0.5

    # --- creasta: 6-7 tente cu pante diferite; max = varfuri si sei neregulate
    peaks = []
    for k in range(n_peaks):
        xk = -74.0 + 148.0 * k / (n_peaks - 1.0) + (_hash(k, 1, seed) - 0.5) * 16.0
        hk = 0.62 + 0.38 * _hash(k, 2, seed)
        sl = 0.0075 + 0.0090 * _hash(k, 3, seed)     # panta, in fractii din hmax/m
        peaks.append((xk, hk, sl))
    top = max(p[1] for p in peaks)

    def crest_h(x):
        h = 0.0
        for xk, hk, sl in peaks:
            h = max(h, hk / top - sl * abs(x - xk))
        h = max(h, 0.50 + 0.10 * _vn(x, seed + 5, 22.0))
        # creasta zimtata fin, NEPERIODICA: valoare per pozitie, nu sinus
        h += (_hash(int(round(x * 0.62)), 7, seed) - 0.5) * 0.07
        end = _sstep(half, half - 16.0, abs(x)) * 0.0
        e = min(1.0, (half - abs(x)) / 14.0)
        h *= 0.40 + 0.60 * _sstep(0.0, 1.0, e)
        return max(0.30, h) * hmax

    # --- latimea de baza (jumatate), contraforturi (gaussiene +), pinteni
    def base_w(x, side):
        w = 22.0 + 6.0 * _vn(x, seed + 11, 31.0)
        return w

    butt = {1: [], -1: []}
    for side in (1, -1):
        nb = 3 + (1 if _hash(side, 5, buttress_seed) > 0.5 else 0)
        for k in range(nb):
            bx = -66.0 + 132.0 * (k + _hash(k, side + 9, buttress_seed) * 0.8) / nb
            butt[side].append((bx, 0.16 + 0.20 * _hash(k, side + 13, buttress_seed),
                               5.0 + 4.0 * _hash(k, side + 17, buttress_seed)))
    ravs = {1: ravines_p, -1: ravines_m}
    rav_depth = {s: [6.0 + 4.0 * _hash(k, s + 23, buttress_seed)
                     for k in range(len(ravs[s]))] for s in (1, -1)}
    SIG = 3.4

    def rav_strength(x, side):
        g = 0.0
        for xr in ravs[side]:
            g = max(g, math.exp(-((x - xr) / SIG) ** 2))
        return g

    def half_w(x, t, side):
        m = 1.0
        for bx, amp, bw in butt[side]:
            m += amp * math.exp(-((x - bx) / bw) ** 2)
        p = 1.30 if side > 0 else 1.55     # fata +Y mai abrupta decat -Y
        w = base_w(x, side) * m * (1.0 - t ** p)
        cut = 0.0
        for xr, d in zip(ravs[side], rav_depth[side]):
            g = math.exp(-((x - xr) / SIG) ** 2)
            prof = (0.35 + 0.65 * min(1.0, t / 0.30)) * (1.0 - 0.55 * _sstep(0.86, 1.0, t))
            cut += d * g * prof
        end_k = _sstep(half - 6.0, half - 22.0, abs(x))   # fara ravene la capete
        return max(0.8, w - cut * end_k)

    # --- coloanele: uniforme + 2 suplimentare in jurul fiecarei ravene (fasia
    # de cascada de 1.4 m intre ele)
    xs = [-half + FW_LEN * i / 63.0 for i in range(64)]
    fall_x = []
    for side in (1, -1):
        for xr in ravs[side]:
            fall_x.append((side, xr))
    xs = [x for x in xs if all(abs(x - xr) > 2.0 for _, xr in fall_x)]
    for _, xr in fall_x:
        xs += [xr - 0.7, xr + 0.7]
    xs = sorted(set(round(x, 3) for x in xs))
    xs[0], xs[-1] = -half, half

    def yc(x):
        return (_vn(x, seed + 31, 45.0) - 0.5) * 12.0

    cols = []
    for ci, x in enumerate(xs):
        h = crest_h(x)
        shift = yc(x)
        col = []
        for r in range(2 * N_T - 1):
            if r < N_T - 1:
                t, side = T_ROWS[r], -1
            elif r == N_T - 1:
                t, side = 1.0, 0
            else:
                t, side = T_ROWS[2 * N_T - 2 - r], 1
            if side == 0:
                y = shift
                z = h
            else:
                w = half_w(x, t, side)
                jy = (_hash(ci, r, seed + 3) - 0.5) * 1.6 * (1.0 - t) * (1 if t > 0 else 0.3)
                jz = (_hash(ci, r, seed + 4) - 0.5) * 2.4 if 0.0 < t < 1.0 else 0.0
                y = shift * (0.30 + 0.70 * t) + side * (w + jy)
                z = t * h + jz
            col.append(b.bm.verts.new((x, y, z)))
        cols.append(col)

    n_rows = len(cols[0])
    for i in range(len(xs) - 1):
        xm = 0.5 * (xs[i] + xs[i + 1])
        for r in range(n_rows - 1):
            f = b.bm.faces.new((cols[i][r], cols[i + 1][r],
                               cols[i + 1][r + 1], cols[i][r + 1]))
            if r < N_T - 1:
                side, ti = -1, r
                tmid = 0.5 * (T_ROWS[r] + T_ROWS[r + 1])
            else:
                side = 1
                ti = 2 * N_T - 2 - (r + 1)
                tmid = 0.5 * (T_ROWS[ti] + T_ROWS[ti + 1])
            f[b.slot] = _wall_color(xm, tmid, side, i, r, seed, ravs, fall_x,
                                    rav_strength)
        # talpa
        f = b.bm.faces.new((cols[i][0], cols[i][-1], cols[i + 1][-1], cols[i + 1][0]))
        f[b.slot] = GNEISS_DARK
    e0 = b.bm.faces.new(tuple(reversed(cols[0])))
    e1 = b.bm.faces.new(tuple(cols[-1]))
    e0[b.slot] = GNEISS_DARK
    e1[b.slot] = GNEISS_DARK
    return b.to_object(name)


def _wall_color(xm, t, side, i, r, seed, ravs, fall_x, rav_strength):
    # cascada: fasia dintre cele doua coloane de langa fiecare ravena
    for sd, xr in fall_x:
        if sd == side and abs(xm - xr) < 0.2 and 0.07 < t < 0.94:
            return FALL
    g = rav_strength(xm, side)
    # linia padurii: urmeaza ravenele (+g) si creasta, cu zgomot 2D neted
    # (prag pe inaltimea fetei, nu pe coloana de grila)
    n1 = _vn2(xm, t * 60.0, seed + 41, 14.0, 16.0)
    line = 0.34 + 0.22 * _vn(xm, seed + 51, 38.0) + 0.45 * g + 0.34 * (n1 - 0.5)
    n2 = _vn2(xm, t * 60.0 + 7.0, seed + 43, 9.0, 11.0)
    if t < line:
        # amestec TROPICAL_GREEN / LOG_DARK, LOG_DARK mai des in ravene si la baza. NU 45%: LOG_DARK iese brun pe ecran si 45% da un perete maro, nu padure
        dark = 0.04 + 0.16 * g
        return FOREST_DARK if n2 < dark else FOREST
    # roca: negru vulcanic + gri inchis; cateva fatete usor mai luminoase sus
    if t > 0.82 and side > 0 and n2 > 0.90:
        return GNEISS_LIT
    return GNEISS_DARK if n2 < 0.62 else GNEISS_MID


# --- SnowRidge_A / SnowRidge_B ------------------------------------------------
SR_H = 90.0
SR_R = 60.0


def _snow_ridge(seed, name, peaks, outline=1.0):
    """Masiv cu 3 varfuri. `peaks`: (cx, cy, H, R, p, n_ravene, faza)."""
    b = Builder()
    segs = 36
    rings = [0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.69, 0.77, 0.84, 0.90, 0.95, 1.0]
    hmax = max(p[2] for p in peaks)

    def field(x, y):
        best, bk = 0.0, 0
        for k, (cx, cy, H, R, p, nr, ph) in enumerate(peaks):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            th = math.atan2(dy, dx)
            rv = math.cos(nr * th + ph)
            u = max(0.0, 1.0 - d / R)
            # ravenele cresc spre varf: adancime ~ u, taiate in profil
            z = H * (u ** p) * (1.0 - 0.16 * (0.5 - 0.5 * rv) * min(1.0, u * 2.0))
            if z > best:
                best, bk = z, k
        cx, cy, H, R, p, nr, ph = peaks[bk]
        rv = math.cos(nr * math.atan2(y - cy, x - cx) + ph)
        return best, rv

    def outline_r(a):
        return SR_R * outline * (0.92 + 0.16 * _vn(a * 20.0, seed + 61, 3.0))

    center = b.bm.verts.new((0, 0, field(0, 0)[0]))
    ring_v = []
    for ri, rr in enumerate(rings):
        row = []
        for i in range(segs):
            a = 2.0 * math.pi * i / segs
            R = outline_r(a)
            jr = 1.0 + (_hash(i, ri, seed + 63) - 0.5) * 0.10 * (1.0 if rr < 1.0 else 0.0)
            ja = (_hash(i, ri, seed + 64) - 0.5) * 0.05
            x = math.cos(a + ja) * R * rr * jr
            y = math.sin(a + ja) * R * rr * jr
            z, _ = field(x, y)
            z *= (1.0 - rr ** 5)
            if rr < 1.0:
                z += (_hash(i, ri, seed + 65) - 0.5) * 2.4
                z = max(z, 0.5)
            else:
                z = 0.0
            row.append(b.bm.verts.new((x, y, z)))
        ring_v.append(row)

    faces = []
    for i in range(segs):
        j = (i + 1) % segs
        faces.append(b.bm.faces.new((center, ring_v[0][i], ring_v[0][j])))
    for ri in range(len(rings) - 1):
        for i in range(segs):
            j = (i + 1) % segs
            faces.append(b.bm.faces.new((ring_v[ri][i], ring_v[ri + 1][i],
                                         ring_v[ri + 1][j], ring_v[ri][j])))
    base = b.bm.faces.new(tuple(ring_v[-1][::-1]))
    base[b.slot] = GNEISS_DARK

    bmesh.ops.recalc_face_normals(b.bm, faces=b.bm.faces[:])
    for f in faces:
        f.normal_update()
        c = f.calc_center_median()
        n = f.normal
        zr = c.z / hmax
        _, rv = field(c.x, c.y)
        hv = _hash(int(c.x * 3), int(c.y * 3), seed + 71)
        hv2 = _hash(int(c.x * 2), int(c.y * 2), seed + 73)
        steep = max(0.0, 0.72 - n.z)
        foot = 0.17 + 0.16 * (_vn2(c.x, c.y, seed + 77, 22.0, 22.0) - 0.5) + 0.10 * max(0.0, -rv)
        # zapada: linie joasa in ravene (rv<0 = fund de ravena), mai sus pe
        # coaste; fetele abrupte tin putina
        sline = 0.34 + 0.14 * rv + 0.45 * steep + 0.10 * (hv - 0.5)
        if zr < foot:
            col = FOREST   # fara LOG_DARK: iese brun pe ecran (puncte maro la baza)
        elif zr > sline:
            col = SNOW
            if zr > 0.80 and steep > 0.32 and hv2 < 0.45:
                col = GNEISS_DARK      # coltul de stanca care iese din zapada
        else:
            col = GNEISS_LIT if (n.z > 0.6 and hv2 < 0.05) else (GNEISS_MID if hv2 > 0.70 else GNEISS_DARK)
        f[b.slot] = col
    return b.to_object(name)


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(obj, path_or_none, ao, bevel=0.0, smooth_angle=26.0, origin="base_axis"):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin, smooth_angle=smooth_angle)
    results.append((obj.name, st["tris"], st["ao_min"], st["ao_max"]))
    return obj


# varfuri: (cx, cy, H, R, p, n_ravene, faza)
PEAKS_A = [(-24.0, 2.0, 103.0, 54.0, 1.05, 5, 0.4),
           (26.0, -6.0, 94.0, 52.0, 1.05, 4, 1.7),
           (2.0, 24.0, 73.0, 36.0, 1.05, 6, 0.9)]
PEAKS_B = [(22.0, -3.0, 99.0, 54.0, 1.05, 6, 2.1),
           (-26.0, 8.0, 88.0, 52.0, 1.05, 5, 0.2),
           (0.0, -26.0, 68.0, 36.0, 1.05, 4, 1.1)]

far_a = emit(_far_wall(9101, "FarWall_A", 62.0, 7, [-52.0, -4.0, 44.0],
                       [-36.0, 14.0, 58.0, -70.0], 111),
             None, AO_WALL, bevel=0.0, smooth_angle=12.0)
far_b = emit(_far_wall(9202, "FarWall_B", 68.0, 6, [-60.0, -18.0, 30.0, 66.0],
                       [-44.0, 6.0, 50.0], 222),
             None, AO_WALL, bevel=0.0, smooth_angle=12.0)
ridge_a = emit(_snow_ridge(9301, "SnowRidge_A", PEAKS_A),
               None, AO_RIDGE, bevel=0.0, smooth_angle=14.0)
ridge_b = emit(_snow_ridge(9402, "SnowRidge_B", PEAKS_B),
               None, AO_RIDGE, bevel=0.0, smooth_angle=14.0)

built = [far_a, far_b, ridge_a, ridge_b]
_, sz = export_glb(built, "fiordland/rocks/fiordland_horizon.glb")
print("export: fiordland/rocks/fiordland_horizon.glb (%.0f KB)" % (sz / 1024.0))

total = sum(t for _, t, _, _ in results)
print()
for name, tris, ao_lo, ao_hi in results:
    print("%-14s tris=%6d  AO %.2f..%.2f" % (name, tris, ao_lo, ao_hi))
flag = "OK" if total <= 8000 else "DEPASIT (buget 8000)"
print("TOTAL horizon: %d tris  %s" % (total, flag))

# separate in .blend, ca sa nu se suprapuna la editare
far_b.location.x = 300.0
ridge_a.location.x = 600.0
ridge_b.location.x = 900.0
save_blend(built, "fiordland_horizon.blend")
