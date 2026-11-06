"""Vocabular de forme pentru kitul Angkor (Track24).

Contract: docs/asset_briefs/angkor_kit.md. Pe tiparul carrara_shapes.py, dar
fara dependenta de transfagarasan_shapes: `hull` e definit aici (zece randuri).
Pilotul (`bayon_face_tower_a`) a scris DOAR ce foloseste turnul; fiecare piesa
din valurile urmatoare adauga aici ce cere ea, nu pe nevazute.

FOLOSITE (pilot):
  Frame            sistem local (u dreapta, w in afara, z sus) cu yaw: o fata
                   sau un etaj se modeleaza O DATA, apoi se roteste pe 4 laturi.
  hull             invelitoare convexa dintr-o lista de puncte.
  stone_box        cutie de gresie dintre doua cote, centrata pe (cx, cy).
  stepped_base     baza in trepte (z0, z1, jumatate-latime).
  tier             un etaj: corp + nervuri + stalpi de colt + cornisa + frontoane
                   si finialuri de colt.
  lotus_bud        varful de boboc de lotus (nucleu de revolutie 14 segmente +
                   petale-invelitoare in doua randuri + finial).
  face_relief      FATA BAYON ca GEOMETRIE (vezi mai jos): sprancene, pleoape
                   inchise, nas lat, buze pline zambitoare, urechi cu lobi lungi,
                   diadema. Parametrizata pe inaltimea fetei H (frunte-barbie),
                   deci Poarta de Sud o refoloseste la alta scara.
  lichen_spot      pata plata pe o orizontala (noduri `*_Lichen`).
  streak           dara verticala neagra sub cornisa (noduri `*_Streak`).
  emit_angkor      finish pe fiecare nod, offsetul de origine calculat O DATA pe
                   ansamblu, export in assets/models/angkor/<cale>.

Axe: X latime, Y adancime (fata bogata pe +Y in Blender = -Z in Godot), Z sus.
Se incarca cu exec, dupa dio_lib.
"""

import math
import os
import bmesh
from mathutils import Vector, Matrix

# --- sloturile pe roluri (kit §0, tabelul de sloturi) ------------------------
ANK_STONE = ROCK_LIGHT           # 3: gresia (clasa angkor_sandstone la integrare)
ANK_LICHEN_ORANGE = LAVA_ORANGE  # 30: lichen portocaliu, pete mici pe orizontale
ANK_LICHEN_GREEN = CACTUS_GREEN  # 12: muschi / lichen verde-galbui
ANK_STREAK = VOLCANIC_BLACK      # 20: dare negre sub cornise (NU ROCK_DARK)

ANK_RESULTS = []


def lcg(seed):
    """Generator deterministic [0,1): aceeasi piesa la fiecare rulare."""
    state = [seed * 2654435761 % 4294967296 or 1]

    def rnd():
        state[0] = (state[0] * 1664525 + 1013904223) % 4294967296
        return state[0] / 4294967296.0
    return rnd


def hull(b, pts, slot):
    """Invelitoarea convexa a `pts` (liste de Vector/tuple) in builder-ul `b`."""
    vs = [b.bm.verts.new(Vector(p)) for p in pts]
    bmesh.ops.remove_doubles(b.bm, verts=vs, dist=1e-4)
    vs = [v for v in vs if v.is_valid]
    res = bmesh.ops.convex_hull(b.bm, input=vs)
    junk = [g for g in set(res["geom_interior"]) | set(res["geom_unused"]) if g.is_valid]
    bmesh.ops.delete(b.bm, geom=junk, context="VERTS")
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace) and f.is_valid:
            f[b.slot] = slot


class Frame:
    """Sistem local: `origin` (x, y, z), rotit cu `yaw_deg` in jurul lui Z.
    p(u, w, z): u spre dreapta, w spre exterior (+Y la yaw 0), z in sus."""

    def __init__(self, origin, yaw_deg=0.0):
        self.o = Vector(origin)
        self.rot = Matrix.Rotation(math.radians(yaw_deg), 3, "Z")

    def p(self, u, w, z=0.0):
        v = self.rot @ Vector((u, w, 0.0))
        return Vector((self.o.x + v.x, self.o.y + v.y, self.o.z + z))


def stone_box(b, cx, cy, z0, z1, half, slot=ANK_STONE, half_y=None):
    hy = half if half_y is None else half_y
    b.box((cx, cy, (z0 + z1) * 0.5), (2 * half, 2 * hy, z1 - z0), slot)


def stepped_base(b, steps, cx=0.0, cy=0.0, slot=ANK_STONE, proud=0.04, block_w=0.95):
    """steps = [(z0, z1, half), ...] de jos in sus; intoarce cota de sus.
    Fiecare treapta e un corp de `half - proud` imbracat in blocuri in relief
    (`block_courses`), deci suprafata vizibila ramane la `half` (S1: 1,50)."""
    for i, (z0, z1, half) in enumerate(steps):
        stone_box(b, cx, cy, z0, z1, half - proud, slot)
        block_courses(b, half, z0, z1, 1, block_w, proud=proud, slot=slot, seed=i, cx=cx, cy=cy)
    return steps[-1][1]


def block_courses(b, half, z0, z1, courses, block_w, proud=0.04, gap=0.035,
                  slot=ANK_STONE, seed=0, cx=0.0, cy=0.0):
    """Randuri de blocuri in relief pe cei patru pereti ai unui corp patrat de
    jumatate-latime `half - proud` (suprafata blocurilor e la `half`). Fiecare
    rand are blocuri de latime ~`block_w` (cu variatie), decalate de la un rand
    la altul; rosturile (`gap`) raman pe perete si citesc ca linii intunecate
    prin AO. Geometrie, nu textura: clasa de gresie vine peste ea la integrare."""
    rnd = lcg(seed + 31)
    ch = (z1 - z0) / courses
    for k in range(4):
        fr = Frame((cx, cy, 0.0), 90.0 * k)
        rot = Matrix.Rotation(math.radians(90.0 * k), 3, "Z")
        for c in range(courses):
            za, zb = z0 + c * ch + gap * 0.5, z0 + (c + 1) * ch - gap * 0.5
            n = max(2, int(round(2 * half / block_w)))
            edges = [-half + 2 * half * i / n for i in range(n + 1)]
            if c % 2:
                edges = [-half] + [e + half / n for e in edges[:-1]] + [half]
            edges = [min(max(e + (rnd() - 0.5) * 0.12 * block_w, -half), half) if 0 < i < len(edges) - 1 else e
                     for i, e in enumerate(edges)]
            for ua, ub in zip(edges[:-1], edges[1:]):
                if ub - ua < 0.1:
                    continue
                ua, ub = ua + gap * 0.5, ub - gap * 0.5
                ctr = fr.p((ua + ub) * 0.5, half - proud * 0.5 - 0.005, (za + zb) * 0.5)
                b.box(ctr, (ub - ua, proud + 0.01, zb - za), slot, rotation=rot)


def oct_prism(b, cx, cy, z0, z1, half, cham, slot=ANK_STONE):
    """Prisma octogonala (patrat cu colturile taiate cu `cham`): colturi
    chanfrenate, nu ascutite."""
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for (dx, dy) in ((half, half - cham), (half - cham, half)):
                for z in (z0, z1):
                    pts.append(Vector((cx + sx * dx, cy + sy * dy, z)))
    hull(b, pts, slot)


def tier(b, z0, z1, half, cornice_h, slot=ANK_STONE, cx=0.0, cy=0.0, finials=True):
    """Un etaj = doua randuri de blocuri suprapuse (al doilea cu 4% mai ingust),
    octogonale (colturi chanfrenate), sub o cornisa subtire; la colturile
    cornisei, bucati mici rotunjite (finialuri). FARA frontoane triunghiulare si
    fara tepi de colt (runda 4: citeau „brad de Craciun”). Intoarce cota de sus."""
    zm = (z0 + z1) * 0.5
    oct_prism(b, cx, cy, z0, zm, half, half * 0.16, slot)
    oct_prism(b, cx, cy, zm, z1, half * 0.96, half * 0.16, slot)
    ch = half + 0.05
    oct_prism(b, cx, cy, z1, z1 + cornice_h, ch, ch * 0.16, slot)
    z_top = z1 + cornice_h
    if finials:
        for sx in (-1, 1):
            for sy in (-1, 1):
                c = Vector((cx + sx * (ch - 0.09), cy + sy * (ch - 0.09), z_top))
                pts = [c + Vector((dx * 0.06, dy * 0.06, 0.0)) for dx in (-1, 1) for dy in (-1, 1)]
                pts += [c + Vector((dx * 0.045, dy * 0.045, 0.085)) for dx in (-1, 1) for dy in (-1, 1)]
                hull(b, pts, slot)
    return z_top


def lotus_bud(b, cx, cy, z0, height, radius, slot=ANK_STONE, petals=8, segments=14):
    """Boboc de lotus: inel de baza (frustum), nucleu de revolutie cu
    `segments` laturi, un rand exterior de `petals` petale (invelitori
    ascutite, usor deschise) si unul interior mai inalt, apoi finialul."""
    R = radius
    ring_h = height * 0.14
    b.frustum((cx, cy, z0 + ring_h * 0.5), R * 1.0, R * 0.82, ring_h, slot, segments=segments)
    zb = z0 + ring_h
    hb = height - ring_h
    # nucleu: profil (raza, cota) -> revolutie; ovoid ascutit
    profile = [(R * 0.70, 0.0), (R * 0.82, hb * 0.22),
               (R * 0.66, hb * 0.55), (R * 0.36, hb * 0.82), (R * 0.12, hb * 0.96),
               (0.0, hb)]
    b.revolve(profile, slot, segments=segments, origin=(cx, cy, zb), cap_bottom=True)
    # petale exterioare: invelitori care urmaresc ovoidul, tip usor deschis
    for ring, (r_base, r_belly, r_tip, h_belly, h_tip, half_w, off) in enumerate((
            (R * 0.62, R * 1.0, R * 0.46, 0.28, 0.80, 0.30, 0.0),
            (R * 0.40, R * 0.62, R * 0.10, 0.46, 0.96, 0.21, 0.5))):
        for k in range(petals):
            a = 2.0 * math.pi * (k + off) / petals
            ca, sa = math.cos(a), math.sin(a)
            tx, ty = -sa, ca          # tangenta
            pts = []
            for rr, hh, hw in ((r_base, 0.02, half_w * 0.9), (r_belly, h_belly, half_w),
                               (r_tip, h_tip, 0.012)):
                for side in (-1, 1):
                    pts.append(Vector((cx + ca * rr + tx * side * rr * hw * 1.6,
                                       cy + sa * rr + ty * side * rr * hw * 1.6,
                                       zb + hb * hh)))
            hull(b, pts, slot)
    # finial
    b.frustum((cx, cy, zb + hb * 0.97), R * 0.09, R * 0.015, hb * 0.07, slot, segments=8)


# --- FATA BAYON --------------------------------------------------------------
FACE_DEPTH = 0.07     # cat iese varful nasului in afara planului nucleului, in H
FACE_PLATE = 0.02     # cat iese masa obrajilor/fruntii (bombata) peste nucleu, in H


def face_relief(b, origin, yaw_deg, H, slot=ANK_STONE, smile=0.9):
    """Fata Bayon senina ca GEOMETRIE, pe o latura a nucleului (runda 4).

    origin   punctul (x, y, z) de pe PLANUL NUCLEULUI, sub barbie, pe axa fetei
    yaw_deg  0 = fata priveste spre +Y; 90 spre -X; 180 spre -Y; 270 spre +X
    H        inaltimea sprancene-barbie in metri (3,0 pentru turn)
    smile    0 = buze drepte; 0.9 = zambetul Angkor, colturile urcate usor

    Proportii (in H): latimea fetei 0,80 (maxilar lat si rotunjit, FARA barbie
    ascutita), ochii la 0,55-0,65, nasul 0,34-0,78, gura la 0,20, fruntea pana
    la 1,10, diadema 1,02-1,20. Relieful peste masa obrajilor (0,02·H): nasul
    0,05·H (0,15 m la H = 3), buzele 0,042·H, pleoapele 0,03·H. Adancimea sta in
    nas, pleoape, buze si masa obrajilor, nu intr-un raft de sprancene: sprancena
    e un arc continuu care curge in puntea nasului.

    Pleoape grele, inchise, curbate in jos (semiluna cu partea convexa in jos).
    Nas lat cu aripi late. Buze late (mai late decat aripile nasului), cea de jos
    mai plina. FARA urna de pe frunte (brief angkor.md §8), fara caricatura.
    Urechile cu lobi lungi stau la colturi, unde se intalnesc doua fete.
    Intoarce cota de sus a diademei (m, de la origine)."""
    fr = Frame(origin, yaw_deg)
    h = H

    def P(u, t, w):
        return fr.p(u * h, w * h, t * h)

    def sym(pts):
        out = []
        for (u, t, w) in pts:
            out.append(P(u, t, w))
            if abs(u) > 1e-9:
                out.append(P(-u, t, w))
        return out

    pl = FACE_PLATE
    D = FACE_DEPTH
    # --- masa fetei: oval LAT, bombat spre exterior (trei straturi) -----------
    outline = [(0.17, 0.00), (0.30, 0.04), (0.37, 0.16), (0.40, 0.36),
               (0.40, 0.62), (0.385, 0.88), (0.34, 1.10)]
    pts = []
    for (u, t) in outline:
        pts += sym([(u, t, 0.0)])
        pts += sym([(u * 0.96, t * 0.99 + 0.005, pl * 0.55)])
        pts += sym([(u * 0.86, t * 0.97 + 0.02, pl)])
    hull(b, pts, slot)

    # --- barbia: lata, rotunjita ------------------------------------------------
    hull(b, sym([(0.18, 0.015, 0.0), (0.16, 0.115, 0.0), (0.12, 0.02, pl + 0.016), (0.10, 0.11, pl + 0.018)]), slot)

    # --- nasul lat, plat, cu aripi late -------------------------------------------
    hull(b, sym([(0.045, 0.70, pl + 0.008), (0.066, 0.55, pl + 0.030), (0.080, 0.415, D),
                 (0.165, 0.375, pl + 0.032), (0.135, 0.455, pl + 0.026), (0.085, 0.345, D - 0.008),
                 (0.165, 0.375, pl), (0.05, 0.74, pl)]), slot)

    # --- ochi inchisi + sprancena: lid greu (semiluna convexa in jos), arc continuu --
    # fiecare ochi = o singura masa: sprancena (arc continuu, urca din puntea nasului)
    # + pleoapa grea sub ea, a carei margine de jos e o semiluna cu partea convexa in jos
    eu = [0.045, 0.10, 0.15, 0.20, 0.25, 0.30, 0.345]
    for sgn in (-1, 1):
        for i in range(len(eu) - 1):
            pts = []
            for j in (i, i + 1):
                u = eu[j]
                x = (u - 0.22) / 0.13
                bulge = max(0.0, 1.0 - x * x)
                top = 0.715 - 0.035 * (u / 0.345) ** 2 + 0.012 * bulge      # arc continuu spre tample
                low = 0.625 - 0.080 * bulge - 0.012 * max(0.0, x - 0.4)
                if u < 0.08:
                    low = 0.67                                              # in puntea nasului lid-ul se contopeste
                wlid = pl + 0.012 + 0.020 * bulge
                pts += [P(sgn * u, low, wlid), P(sgn * u, top, wlid + 0.010),
                        P(sgn * u, low + 0.004, pl), P(sgn * u, top, pl)]
            hull(b, pts, slot)

    # --- buzele: LARGI (peste aripile nasului), colturile urcate usor, cea de jos mai plina
    hw = 0.235
    n = 10
    gap = 0.003

    def zc(u):
        return 0.205 + 0.035 * smile * (u / hw) ** 2

    wU, wL = pl + 0.042, pl + 0.048
    for i in range(n):
        ua = -hw + 2 * hw * i / n
        ub = -hw + 2 * hw * (i + 1) / n
        up_pts, lo_pts = [], []
        for u in (ua, ub):
            a = abs(u) / hw
            th_u = 0.055 * (1 - 0.40 * a)
            th_l = 0.078 * (1 - 0.35 * a)
            wu = wU * (1 - 0.35 * a)
            wl = wL * (1 - 0.35 * a)
            z0u = zc(u) + gap
            up_pts += [P(u, z0u, wu), P(u, z0u + th_u, wu - 0.016), P(u, z0u, pl), P(u, z0u + th_u, pl)]
            z0l = zc(u) - gap
            lo_pts += [P(u, z0l, wl - 0.008), P(u, z0l - th_l * 0.5, wl), P(u, z0l - th_l, wl - 0.022),
                       P(u, z0l, pl), P(u, z0l - th_l, pl)]
        hull(b, up_pts, slot)
        hull(b, lo_pts, slot)

    # --- urechile cu lobi lungi: la colturi, unde se intalnesc doua fete -----------
    for sgn in (-1, 1):
        hull(b, [P(sgn * 0.395, 0.82, 0.0), P(sgn * 0.45, 0.77, 0.032), P(sgn * 0.475, 0.60, 0.038),
                 P(sgn * 0.46, 0.45, 0.032), P(sgn * 0.395, 0.45, 0.0), P(sgn * 0.40, 0.76, 0.034)], slot)
        hull(b, [P(sgn * 0.41, 0.50, 0.0), P(sgn * 0.46, 0.46, 0.028), P(sgn * 0.455, 0.20, 0.032),
                 P(sgn * 0.42, 0.14, 0.032), P(sgn * 0.395, 0.26, 0.012), P(sgn * 0.40, 0.20, 0.0)], slot)

    # --- diadema: banda arcuita direct pe frunte, cu nervuri ---------------------------
    xs = [-0.43, -0.32, -0.21, -0.105, 0.0, 0.105, 0.21, 0.32, 0.43]

    def band_lo(u):
        return 1.02 + 0.025 * (1 - (u / 0.43) ** 2)

    def band_hi(u):
        return 1.15 + 0.045 * (1 - (u / 0.43) ** 2)

    wb = pl + 0.020
    for ua, ub in zip(xs[:-1], xs[1:]):
        pts = []
        for u in (ua, ub):
            pts += [P(u, band_lo(u), wb), P(u, band_hi(u), wb - 0.006), P(u, band_lo(u), 0.0), P(u, band_hi(u), 0.0)]
        hull(b, pts, slot)
    for u in (-0.38, -0.30, -0.22, -0.14, -0.07, 0.0, 0.07, 0.14, 0.22, 0.30, 0.38):
        hull(b, [P(u - 0.012, band_lo(u) + 0.012, wb + 0.014), P(u + 0.012, band_lo(u) + 0.012, wb + 0.014),
                 P(u - 0.012, band_hi(u) - 0.012, wb + 0.010), P(u + 0.012, band_hi(u) - 0.012, wb + 0.010),
                 P(u - 0.012, band_lo(u) + 0.012, wb - 0.01), P(u + 0.012, band_hi(u) - 0.012, wb - 0.01)], slot)
    return (1.20 * h)


# --- pete de culoare ---------------------------------------------------------

def lichen_spot(b, fr_point, ru, rw, thick, slot, yaw_deg=0.0, seed=0, n=9):
    """Pata de lichen: disc neregulat (elipsa ru x rw, `n` laturi, zgomot
    deterministic) cu varful bombat, lipit pe o orizontala la `fr_point`
    (x, y, z_suprafata). Doua inele de puncte -> invelitoare."""
    rnd = lcg(seed + 7)
    rot = Matrix.Rotation(math.radians(yaw_deg), 3, "Z")
    cx, cy, cz = fr_point
    pts = []
    for k in range(n):
        a = 2.0 * math.pi * k / n
        j = 0.78 + 0.34 * rnd()
        lx, ly = math.cos(a) * ru * j, math.sin(a) * rw * j
        v = rot @ Vector((lx, ly, 0.0))
        pts.append(Vector((cx + v.x, cy + v.y, cz - 0.004)))
        v2 = rot @ Vector((lx * 0.62, ly * 0.62, 0.0))
        pts.append(Vector((cx + v2.x, cy + v2.y, cz + thick)))
    hull(b, pts, slot)


def streak(b, wall_pt, outward_yaw_deg, width, length, thick, slot):
    """Dara verticala: banda subtire (`thick` in afara peretelui) cu varful in
    `wall_pt` = (x, y, z_sus) si coborand `length`. `outward_yaw_deg`: 0 = peretele
    priveste spre +Y."""
    fr = Frame((wall_pt[0], wall_pt[1], 0.0), outward_yaw_deg)
    z_top = wall_pt[2]
    pts = []
    for (u, z, w) in ((-width * 0.5, z_top, 0.0), (width * 0.5, z_top, 0.0),
                      (-width * 0.5, z_top, thick), (width * 0.5, z_top, thick),
                      (-width * 0.06, z_top - length, 0.0), (width * 0.06, z_top - length, 0.0),
                      (-width * 0.06, z_top - length, thick * 0.5), (width * 0.06, z_top - length, thick * 0.5)):
        pts.append(fr.p(u, w, z))
    hull(b, pts, slot)


# --- emit --------------------------------------------------------------------

def emit_angkor(objs, path, ao, bevels=None, bevel=0.02, smooth_angle=40.0,
                bevel_angle=30.0, center_y=True):
    """Finish pe fiecare nod + export in assets/models/angkor/<path>.

    Offsetul de origine se calculeaza O DATA pe ansamblu (memoria finish-
    recentreaza-fiecare-nod-separat): amprenta centrata pe X si Y (bbox-ul
    tuturor nodurilor), talpa ansamblului la Z = 0. `bevels` = {sufix: latime}
    suprascrie `bevel` pe nodurile cu acel sufix (petele si darele: 0, sunt
    prea subtiri pentru bevel)."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    place = Vector((-(min(xs) + max(xs)) * 0.5,
                    -(min(ys) + max(ys)) * 0.5 if center_y else 0.0,
                    -min(zs)))
    total, per_node = 0, {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao, origin=None,
                    smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "angkor/" + path)
    ANK_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    return total


def report_angkor():
    print()
    for path, tris, dims, per_node, kb in ANK_RESULTS:
        print("%-44s tris=%6d  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)
