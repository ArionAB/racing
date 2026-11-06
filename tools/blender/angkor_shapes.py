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


def tier(b, z0, z1, half, cornice_h, slot=ANK_STONE, cx=0.0, cy=0.0,
         ribs=True, gables=True, corner_finials=True):
    """Un etaj al turnului: corp de gresie [z0, z1] cu jumatatea `half`, nervuri
    verticale (doua pe latura), stalpi de colt, apoi o cornisa de `cornice_h`
    (doua randuri, 0,1 m mai larga decat corpul), frontoane in mijlocul laturilor
    si finialuri piramidale in colturi, asezate pe cornisa. Intoarce cota de sus
    a cornisei. Totul ramane in `half + 0,12`."""
    body_top = z1
    stone_box(b, cx, cy, z0, body_top, half, slot)
    ch = half + 0.10
    z_c = body_top
    # cornisa in doua randuri: un guler mai ingust sub o buza mai lata
    stone_box(b, cx, cy, z_c, z_c + cornice_h * 0.45, ch * 0.96, slot)
    stone_box(b, cx, cy, z_c + cornice_h * 0.45, z_c + cornice_h, ch, slot)
    z_top = z_c + cornice_h
    for k in range(4):
        fr = Frame((cx, cy, 0.0), 90.0 * k)
        if ribs:
            for sgn in (-1, 1):
                u = sgn * half * 0.55
                rib = [fr.p(u + dx, half + dw, z)
                       for dx in (-0.065, 0.065) for dw in (0.0, 0.06)
                       for z in (z0 + 0.04, body_top - 0.04)]
                hull(b, rib, slot)
        if gables:
            gw = max(half * 0.34, 0.12)
            gh = 0.18 + 0.30 * half / 1.2
            pts = [fr.p(sx * gw, ch + 0.0, z_top) for sx in (-1, 1)]
            pts += [fr.p(sx * gw, ch - 0.16, z_top) for sx in (-1, 1)]
            pts += [fr.p(sx * 0.03, ch - 0.06, z_top + gh) for sx in (-1, 1)]
            hull(b, pts, slot)
        if corner_finials:
            cpt = fr.p(ch - 0.10, ch - 0.10, z_top)
            fin = Frame(cpt, 90.0 * k)
            pts = [fin.p(sx * 0.08, sw * 0.08, 0.0) for sx in (-1, 1) for sw in (-1, 1)]
            pts += [fin.p(0.0, 0.0, 0.20)]
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
FACE_DEPTH = 0.135    # cat iese varful nasului in afara planului nucleului, in H
FACE_PLATE = 0.045    # grosimea placii fetei, in H


def face_relief(b, origin, yaw_deg, H, slot=ANK_STONE, smile=0.45):
    """Fata Bayon senina ca GEOMETRIE, pe o latura a nucleului.

    origin   punctul (x, y, z) de pe PLANUL NUCLEULUI, sub barbie, pe axa fetei
    yaw_deg  0 = fata priveste spre +Y; 90 spre -X; 180 spre -Y; 270 spre +X
    H        inaltimea frunte(sprancene)-barbie in metri (2,2 pentru turn)
    smile    1.0 = zambet plin; 0.0 = buze drepte; 0.45 = zambetul linistit al Bayonului

    Tot ce iese din plan: nasul FACE_DEPTH*H (0,30 m la H = 2,2), sprancenele
    pana la 0,115*H, buzele 0,10*H, pleoapele 0,085*H, deci peste placa
    (0,045*H) reliefurile au 12-20 cm la H = 2,2, destul cat sa arunce umbra sub
    soarele de 24 grade. Proportiile: latimea fetei 0,68*H, ochii la 0,63*H de
    la barbie, nasul 0,36-0,76*H, gura la 0,215*H, diadema 1,12-1,27*H.

    FARA urna de pe frunte (iconografie de Buddha: brief angkor.md §8) si fara
    nimic care sa semene cu o caricatura: ochi inchisi, gura plina, chip calm.
    Intoarce inaltimea de sus a fetei (diadema + fronton) in metri, de la origine."""
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
    # --- placa fetei: contur oval, lipita de nucleu, cu fata bombata ---------
    outline = [(0.14, 0.00), (0.27, 0.12), (0.34, 0.30), (0.36, 0.55),
               (0.35, 0.85), (0.33, 1.12)]
    pts = []
    for (u, t) in outline:
        pts += sym([(u, t, 0.0)])
        # fata din fata: mai ingusta si usor comprimata pe verticala
        pts += sym([(u * 0.90, t * 0.97 + 0.015, pl)])
    hull(b, pts, slot)

    # --- barbia ----------------------------------------------------------------
    hull(b, sym([(0.115, 0.015, pl), (0.10, 0.125, pl), (0.085, 0.03, 0.088), (0.075, 0.115, 0.092)]), slot)

    # --- nasul lat ----------------------------------------------------------------
    hull(b, sym([(0.030, 0.77, 0.070), (0.042, 0.60, 0.108), (0.054, 0.44, FACE_DEPTH),
                 (0.095, 0.385, 0.098), (0.080, 0.470, 0.088), (0.052, 0.355, 0.118),
                 (0.095, 0.385, pl), (0.04, 0.80, pl)]), slot)

    # --- sprancenele: creasta care incadreaza ochii --------------------------------
    brow = [(0.03, 0.735), (0.11, 0.752), (0.20, 0.758), (0.27, 0.748), (0.325, 0.722)]
    for sgn in (-1, 1):
        for (ua, ta), (ub, tb) in zip(brow[:-1], brow[1:]):
            pts = []
            for (u, t) in ((ua, ta), (ub, tb)):
                wf = 0.100 - 0.034 * (u / 0.325)
                pts.append(P(sgn * u, t + 0.026, wf - 0.020))
                pts.append(P(sgn * u, t - 0.024, wf))
                pts.append(P(sgn * u, t + 0.026, pl))
                pts.append(P(sgn * u, t - 0.024, pl))
            hull(b, pts, slot)

    # --- ochii inchisi: pleoapa de sus bombata + pleoapa de jos, fanta intre ele ---
    eye_u = [0.075, 0.125, 0.175, 0.225, 0.275]
    eye_tc = [0.630, 0.652, 0.655, 0.638, 0.600]   # capatul exterior mai jos: privire in jos
    eye_w = [0.076, 0.092, 0.094, 0.086, 0.070]
    for sgn in (-1, 1):
        for i in range(len(eye_u) - 1):
            pts = []
            for j in (i, i + 1):
                pts.append(P(sgn * eye_u[j], eye_tc[j] + 0.034, eye_w[j] - 0.022))
                pts.append(P(sgn * eye_u[j], eye_tc[j] - 0.018, eye_w[j]))
                pts.append(P(sgn * eye_u[j], eye_tc[j] + 0.030, pl))
                pts.append(P(sgn * eye_u[j], eye_tc[j] - 0.018, pl))
            hull(b, pts, slot)
            pts = []
            for j in (i, i + 1):
                pts.append(P(sgn * eye_u[j], eye_tc[j] - 0.044, 0.062))
                pts.append(P(sgn * eye_u[j], eye_tc[j] - 0.058, 0.060))
                pts.append(P(sgn * eye_u[j], eye_tc[j] - 0.044, pl))
                pts.append(P(sgn * eye_u[j], eye_tc[j] - 0.058, pl))
            hull(b, pts, slot)

    # --- buzele: pline, zambitoare (colturile mai sus), cu un jgheab intre ----------
    hw = 0.165
    n = 8
    gap = 0.003

    def zc(u):
        return 0.215 + 0.040 * smile * (u / hw) ** 2

    for i in range(n):
        ua = -hw + 2 * hw * i / n
        ub = -hw + 2 * hw * (i + 1) / n
        up_pts, lo_pts = [], []
        for u in (ua, ub):
            a = abs(u) / hw
            th_u = 0.040 * (1 - 0.50 * a)
            th_l = 0.050 * (1 - 0.45 * a)
            w_u = 0.112 - 0.044 * a
            w_l = 0.118 - 0.052 * a
            z0u = zc(u) + gap
            up_pts += [P(u, z0u, w_u), P(u, z0u + th_u, w_u - 0.030),
                       P(u, z0u, pl), P(u, z0u + th_u, pl)]
            z0l = zc(u) - gap
            lo_pts += [P(u, z0l, w_l - 0.014), P(u, z0l - th_l * 0.5, w_l),
                       P(u, z0l - th_l, w_l - 0.026),
                       P(u, z0l, pl), P(u, z0l - th_l, pl)]
        hull(b, up_pts, slot)
        hull(b, lo_pts, slot)
    # gropite de zambet la colturile gurii
    for sgn in (-1, 1):
        hull(b, [P(sgn * 0.185, 0.245, pl), P(sgn * 0.215, 0.255, pl),
                 P(sgn * 0.185, 0.285, pl), P(sgn * 0.215, 0.29, pl),
                 P(sgn * 0.19, 0.255, 0.072), P(sgn * 0.205, 0.27, 0.07)], slot)

    # --- urechile cu lobi lungi (panourile din lateral) -----------------------------
    for sgn in (-1, 1):
        hull(b, [P(sgn * 0.36, 0.84, 0.0), P(sgn * 0.44, 0.80, 0.045), P(sgn * 0.475, 0.62, 0.06),
                 P(sgn * 0.45, 0.46, 0.05), P(sgn * 0.36, 0.45, 0.0), P(sgn * 0.37, 0.80, 0.055)], slot)
        hull(b, [P(sgn * 0.37, 0.50, 0.0), P(sgn * 0.45, 0.48, 0.04), P(sgn * 0.44, 0.22, 0.045),
                 P(sgn * 0.40, 0.17, 0.05), P(sgn * 0.36, 0.30, 0.025), P(sgn * 0.37, 0.22, 0.0)], slot)

    # --- diadema: banda arcuita peste frunte, cu nervuri si fronton --------------
    xs = [-0.43, -0.32, -0.21, -0.105, 0.0, 0.105, 0.21, 0.32, 0.43]

    def band_lo(u):
        return 1.045 + 0.035 * (1 - (u / 0.43) ** 2)

    def band_hi(u):
        return 1.180 + 0.060 * (1 - (u / 0.43) ** 2)

    for ua, ub in zip(xs[:-1], xs[1:]):
        pts = []
        for u in (ua, ub):
            wf = 0.094 - 0.030 * abs(u) / 0.43
            pts += [P(u, band_lo(u), wf), P(u, band_hi(u), wf), P(u, band_lo(u), 0.0), P(u, band_hi(u), 0.0)]
        hull(b, pts, slot)
    for u in (-0.36, -0.27, -0.18, -0.09, 0.0, 0.09, 0.18, 0.27, 0.36):
        wf = 0.094 - 0.030 * abs(u) / 0.43
        hull(b, [P(u - 0.014, band_lo(u) + 0.012, wf + 0.022), P(u + 0.014, band_lo(u) + 0.012, wf + 0.022),
                 P(u - 0.014, band_hi(u) - 0.012, wf + 0.022), P(u + 0.014, band_hi(u) - 0.012, wf + 0.022),
                 P(u - 0.014, band_lo(u) + 0.012, wf - 0.01), P(u + 0.014, band_hi(u) - 0.012, wf - 0.01)], slot)
    # frontonul din varful diademei (cum are desenul)
    hull(b, [P(-0.085, 1.215, 0.080), P(0.085, 1.215, 0.080), P(-0.085, 1.215, 0.0), P(0.085, 1.215, 0.0),
             P(0.0, 1.40, 0.060), P(0.0, 1.40, 0.0)], slot)
    return 1.40 * h


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
                      (-width * 0.42, z_top - length, 0.0), (width * 0.42, z_top - length, 0.0),
                      (-width * 0.42, z_top - length, thick * 0.6), (width * 0.42, z_top - length, thick * 0.6)):
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
