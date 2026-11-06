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


def ellipsoid(b, center, radii, slot, rot, seg=10, rings=6, roll_deg=0.0):
    """Elipsoid neted (sfera UV scalata) in builder-ul `b`. `center` in spatiul
    lumii, `radii` = (r_u, r_w, r_z) in metri, in axele LOCALE ale fetei
    (`rot` = matricea 3x3 a cadrului), `roll_deg` = inclinare in planul fetei
    (in jurul lui w): pleoapele cu colturile exterioare in jos."""
    m = (Matrix.Translation(Vector(center)) @ rot.to_4x4()
         @ Matrix.Rotation(math.radians(roll_deg), 4, "Y")
         @ Matrix.Diagonal(Vector((radii[0], radii[1], radii[2], 1.0))))
    try:
        res = bmesh.ops.create_uvsphere(b.bm, u_segments=seg, v_segments=rings, radius=1.0, matrix=m)
    except TypeError:
        res = bmesh.ops.create_uvsphere(b.bm, u_segments=seg, v_segments=rings, diameter=1.0, matrix=m)
    b._tag(res["verts"], slot)


def face_relief(b, origin, yaw_deg, H, slot=ANK_STONE, smile=0.9):
    """Fata Bayon senina ca GEOMETRIE NETEDA (runda 5): mase rotunjite
    (elipsoizi cu 8-12 segmente + o cupola din inele), nu fatete plane.

    origin   punctul (x, y, z) de pe PLANUL NUCLEULUI, sub barbie, pe axa fetei
    yaw_deg  0 = fata priveste spre +Y; 90 spre -X; 180 spre -Y; 270 spre +X
    H        inaltimea sprancene-barbie in metri (3,0 pentru turn)

    Proportii (in H): oval lat (0,82), maxilar in arc de oval, FARA colturi la
    barbie; ochii la t ~0,60, nasul 0,36-0,64 (~0,27·H de intre ochi), gura la
    0,205 cu latimea 0,36·H (~0,45 din latimea fetei).
    Ochi: DOUA pleoape separate, fiecare o semiluna cu partea convexa in jos si
    colturile exterioare usor in jos, cu suprafata puntii nasului intre ele; deasupra
    fiecareia, o sprancena arcuita moale, despartita de pleoapa printr-un jgheab
    (suprafata fetei, mai jos): umbra orbitei, care face ochii „inchisi”.
    Obrajii: mase rotunjite care urca spre colturile zambetului. Nas: baza lata,
    varf rotund, aripi = doua bumbi rotunzi, fara creasta. Buze: cea de sus un arc
    usor, cea de jos plina, colturile mai mici si urcate. Urechi cu lobi lungi la
    colturi. FARA urna (brief angkor.md §8). Intoarce cota de sus a diademei (m)."""
    fr = Frame(origin, yaw_deg)
    h = H
    rot = fr.rot

    def P(u, t, w):
        return fr.p(u * h, w * h, t * h)

    def E(u, t, w, ru, rt, rw, seg=10, rings=6, roll=0.0):
        ellipsoid(b, P(u, t, w), (ru * h, rw * h, rt * h), slot, rot, seg, rings, roll)

    pl = FACE_PLATE
    D = FACE_DEPTH

    def tube(path, slot_=slot, n=8):
        """Tub neted de-a lungul unui drum de (u, t, w, r_t, r_w): inele eliptice
        in planul (t, w), invelitoare convexa. Un singur corp continuu (nu margele)."""
        pts = []
        for (u, t, w, rt, rw) in path:
            for k in range(n):
                th = 2.0 * math.pi * k / n
                pts.append(P(u, t + rt * math.cos(th), w + rw * math.sin(th)))
        hull(b, pts, slot_)

    def cone(rings, n=12):
        """Corp neted din inele eliptice in planul (u, w), la t crescator:
        (t, u_centru, w_centru, r_u, r_w)."""
        pts = []
        for (t, uc, wc, ru, rw) in rings:
            for k in range(n):
                th = 2.0 * math.pi * k / n
                pts.append(P(uc + ru * math.cos(th), t, wc + rw * math.sin(th)))
        hull(b, pts, slot)

    # --- masa fetei: cupola ovala din inele (maxilar in arc, bombata) -----------------
    pts = []
    for k in range(25):
        t = 1.12 * k / 24.0
        hw = 0.41 * math.sqrt(max(0.03, 1.0 - ((t - 0.60) / 0.64) ** 2))
        for a in range(-90, 91, 6):
            ar = math.radians(a)
            fz = 1.0 if t < 0.85 else 1.0 - 0.55 * ((t - 0.85) / 0.27) ** 2   # fruntea se pierde in diadema
            pts.append(P(hw * math.sin(ar), t, pl * 1.05 * math.cos(ar) ** 0.8 * fz))
    hull(b, pts, slot)

    # --- obraji: mase pline si joase, urca spre colturile zambetului ------------------------
    for sgn in (-1, 1):
        E(sgn * 0.245, 0.37, pl, 0.140, 0.100, 0.026, 16, 10)

    # --- nas: un singur corp rotund, baza lata, varf rotund, fara creasta -----------------
    cone([(0.64, 0.0, pl + 0.004, 0.030, 0.014), (0.55, 0.0, pl + 0.012, 0.048, 0.026),
          (0.45, 0.0, pl + 0.012, 0.070, 0.032), (0.405, 0.0, D - 0.032, 0.080, 0.030),
          (0.372, 0.0, pl + 0.018, 0.100, 0.026), (0.352, 0.0, pl + 0.012, 0.070, 0.012)], 12)
    for sgn in (-1, 1):
        E(sgn * 0.098, 0.385, pl + 0.012, 0.046, 0.040, 0.030, 12, 8)   # aripile = bumbi rotunzi

    # --- ochi: doua pleoape SEPARATE (semiluna convexa in jos, colt exterior in jos) ----
    for sgn in (-1, 1):
        lid = []
        for i in range(5):
            f = i / 4.0
            u = 0.115 + 0.175 * f
            t = 0.640 - 0.050 * f - 0.020 * math.sin(math.pi * f)
            e = math.sin(math.pi * f) ** 0.6
            lid.append((sgn * u, t, pl + 0.003, 0.012 + 0.018 * e, 0.010 + 0.022 * e))
        tube(lid)
        # sprancena: arc moale deasupra, cu jgheab (suprafata fetei) intre ea si pleoapa
        brow = []
        for i in range(5):
            f = i / 4.0
            u = 0.100 + 0.215 * f
            t = 0.735 - 0.050 * f + 0.030 * math.sin(math.pi * f)
            e = math.sin(math.pi * f) ** 0.7
            brow.append((sgn * u, t, pl + 0.003, 0.008 + 0.012 * e, 0.008 + 0.016 * e))
        tube(brow)

    # --- buze: late (0,36·H), cea de sus un arc usor, cea de jos plina ---------------------
    hw = 0.180

    def zc(u):
        return 0.205 + 0.034 * smile * (u / hw) ** 2

    up, lo = [], []
    for i in range(9):
        u = -hw + 2 * hw * i / 8.0
        a = abs(u) / hw
        e = 1.0 - 0.55 * a * a                      # colturile mai mici, stranse
        up.append((u, zc(u) + 0.026 + 0.008 * (1.0 - a), pl + 0.006, 0.014 * e + 0.004, 0.020 * e + 0.006))
        lo.append((u, zc(u) - 0.022, pl + 0.008, 0.028 * e + 0.004, 0.028 * e + 0.006))
    tube(up)
    tube(lo)
    for sgn in (-1, 1):                              # gropite la colturi
        E(sgn * 0.200, zc(0.18) + 0.010, pl + 0.004, 0.016, 0.016, 0.012, 8, 6)

    # --- urechi cu lobi lungi, la colturi -------------------------------------------------
    for sgn in (-1, 1):
        E(sgn * 0.435, 0.52, 0.012, 0.034, 0.230, 0.034, 10, 8)

    # --- diadema: banda PLATA (~0,3 m), lipita de frunte, fara surplomb, cu 3 rozete -----
    bl, bh = 1.075, 1.175
    wb = pl + 0.004
    hull(b, [P(sgn * 0.43, t, w) for sgn in (-1, 1) for t in (bl, bh) for w in (0.0, wb)], slot)
    for u in (-0.25, 0.0, 0.25):
        E(u, (bl + bh) * 0.5, wb + 0.002, 0.040, 0.040, 0.016, 10, 6)
        E(u, (bl + bh) * 0.5, wb + 0.014, 0.020, 0.020, 0.012, 8, 5)
    return bh * h


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
