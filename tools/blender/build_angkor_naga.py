"""Angkor -- val 2, grupul C: balustrada naga, capul naga, uriasii deva/asura
(brief docs/asset_briefs/angkor_kit.md §1.5).

  angkor/kit/naga_balustrade.glb      modul L 4,0 m, h <= 1,05, gros <= 0,6
  angkor/kit/naga_balustrade_gap.glb  acelasi modul rupt; bucati cazute pe +X
  angkor/kit/naga_head.glb            evantai de sapte capete, ~2,5 m, pe soclu
  angkor/kit/deva_giant.glb           uriasul calm, modul L 4,0 m, ~3,0 m inaltime
  angkor/kit/asura_giant.glb          uriasul furios, acelasi modul

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_naga.py
ANK_ONLY=<bal|gap|head|deva|asura> reface doar piesa respectiva.

Axe (Blender): X latime (-X = spre drum, +X = spre exterior), Y lungimea
modulului (trupul naga merge pe Y), Z sus. In Godot: Y -> -Z. Uriasii stau cu
fata spre -X (spre drum); MultiMesh-ul ii roteste cu 180 de grade pe celalalt
rand.

DECIZIA DEZVOLTATORULUI (6 nov 2026): tot ce e sculptural e SIMPLIFICAT. Uriasii
sunt corpuri-bloc (trunchiuri, brate, picioare ca hull-uri masive); fata deva e
`face_relief` (runda 6); fata asura e o varianta incruntata scrisa aici cu
aceleasi forme mari si putin adanci, plus ochi-discuri si colti-pana. Sculptura
adevarata ramane DATORIE DESCHISA (kit §1.1).

TRUPUL NAGA: un tub de 10 laturi, diametru 0,45 m, cu jgheaburi la fiecare 0,5 m
(solzii). Sectiunea de la capete e plina (jgheaburile cad pe mijlocul perioadei),
deci modulele se leaga: aceeasi sectiune in balustrada, in uriasi, in cap.
Capetele modulului sunt PLANE la y = +-2,0 exact (inelul de la capat e fortat).
"""

import math
import os
import bmesh
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")

S = ANK_STONE
LEN = 4.0
HALF_LEN = LEN / 2.0
BODY_R = 0.225            # diametru 0,45 m, la fel in toate piesele
BODY_N = 10               # laturi
GROOVE = 0.20             # adancimea jgheabului de solz (din raza)
PERIOD = 0.5              # distanta intre jgheaburi (4,0 / 0,5 = 8 solzi pe modul)

GIANT_Z = 1.40            # cota trupului prin bratele uriasilor (1,3-1,7 cerut)
GIANT_AMP = 0.04

AO_BAL = dict(samples=24, dist=0.5, gradient="vertical", low=0.62, high=1.0,
              power=0.85, floor=0.30, strength=1.30, z_range=(0.0, 1.05))
AO_HEAD = dict(samples=24, dist=0.6, gradient="vertical", low=0.62, high=1.0,
               power=0.85, floor=0.30, strength=1.30, z_range=(0.0, 2.5))
AO_GIANT = dict(samples=24, dist=0.6, gradient="vertical", low=0.58, high=1.0,
                power=0.85, floor=0.28, strength=1.35, z_range=(0.0, 3.1))


# --- trupul naga ---------------------------------------------------------------

def tube(b, pts, radius, slot, n=BODY_N, groove=GROOVE, period=PERIOD,
         cap_start=True, cap_end=True, flat_y=False, taper=None, break_end=None):
    """Tub de-a lungul unei polilinii, cu jgheaburi de solz la fiecare `period`
    de lungime de arc. `flat_y`: inelele de la capete sunt aduse pe y-ul punctului
    (capat plan, perpendicular pe Y, chiar daca trupul urca lin). `taper(s_frac)`
    inmulteste raza. `break_end(angle)` muta y-ul ultimului inel (ruptura)."""
    pts = [Vector(p) for p in pts]
    m = len(pts)
    # lungimea de arc
    arc = [0.0]
    for i in range(1, m):
        arc.append(arc[-1] + (pts[i] - pts[i - 1]).length)
    total = arc[-1]
    rings = []
    for i in range(m):
        if i == 0:
            d = pts[1] - pts[0]
        elif i == m - 1:
            d = pts[-1] - pts[-2]
        else:
            d = pts[i + 1] - pts[i - 1]
        d = d.normalized()
        u = d.cross(Vector((0.0, 0.0, 1.0)))
        if u.length < 1e-3:
            u = Vector((1.0, 0.0, 0.0))
        u.normalize()
        v = u.cross(d)
        r = radius * (1.0 - groove * (0.5 - 0.5 * math.cos(2.0 * math.pi * arc[i] / period)))
        if taper is not None:
            r *= taper(arc[i] / total)
        ring = []
        for k in range(n):
            a = 2.0 * math.pi * k / n
            p = pts[i] + u * (math.cos(a) * r) + v * (math.sin(a) * r)
            if flat_y and i in (0, m - 1):
                p.y = pts[i].y
            if break_end is not None and i == m - 1:
                p.y += break_end(a)
            ring.append(b.bm.verts.new(p))
        rings.append(ring)
    allv = [v for ring in rings for v in ring]
    for lo, hi in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    if cap_start:
        b.bm.faces.new(tuple(reversed(rings[0])))
    if cap_end:
        b.bm.faces.new(tuple(rings[-1]))
    b._tag(allv, slot)


def body_path(z0, amp, y0=-HALF_LEN, y1=HALF_LEN, x=0.0, step=0.0625, waves=1):
    """Calea trupului pe Y: ondulatie sinus cu perioada 4 m (zero si aceeasi panta la
    ambele capete, deci la lipirea a doua module nu apare treapta)."""
    n = int(round((y1 - y0) / step))
    return [Vector((x, y0 + (y1 - y0) * i / n,
                    z0 + amp * math.sin(2.0 * math.pi * waves * (y0 + (y1 - y0) * i / n) / LEN)))
            for i in range(n + 1)]


def lichen_on(b, rnd, y, x, z, kind, scale=1.0):
    ru = (0.07 + 0.07 * rnd()) * scale
    rw = ru * (0.7 + 0.5 * rnd())
    slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
    lichen_spot(b, (x, y, z), ru, rw, 0.02, slot, yaw_deg=360.0 * rnd(), seed=int(rnd() * 1000))


# --- balustrada ------------------------------------------------------------------
# Piele vizuala a unui zid de coliziune MASIV (Track._build_parapets, stilul 3): baza e
# piatra continua pe toata lungimea, fara goluri (un jucator care vede prin balustrada
# ar da de un zid invizibil); sarpele (diametru 0,38) sta PE baza si ondulează usor.

BAL_R = 0.19              # trupul balustradei: diametru 0,38 (loc pentru unda sub 1,05)
BAL_Z = 0.78              # cota centrului trupului pe balustrada
BAL_AMP = 0.07            # ondulatie (2 cocoase pe modul), varf-la-varf 0,14
BAL_WAVES = 2
CORE_H = 0.23             # miezul bazei: +-0,23 (0,46 gros)
PROUD = 0.04              # blocurile in relief pe cele doua fete: suprafata la +-0,27
BASE_TOP = 0.52           # varful blocurilor; apoi placa de coronament .52-.60
SLAB_TOP = 0.60
PILASTER_Y = (-1.5, -0.5, 0.5, 1.5)

# randurile de blocuri (muchii pe Y; capetele modulului raman la +-2,0, la ras)
COURSES = [(0.0, 0.18, [-2.0, -1.1, -0.05, 1.0, 2.0]),
           (0.18, 0.35, [-2.0, -1.55, -0.6, 0.5, 1.45, 2.0]),
           (0.35, 0.52, [-2.0, -0.95, 0.1, 1.2, 2.0])]


def base_blocks(st, y_lo=-HALF_LEN, y_hi=HALF_LEN, trim_lo=None, trim_hi=None):
    """Randuri de blocuri in relief pe ambele fete. `trim_lo/hi[c]` = cota y la care se
    opreste randul c (rupere zimtata); blocurile intregi dinauntru raman."""
    for c, (z0, z1, edges) in enumerate(COURSES):
        lo = y_lo if trim_lo is None else trim_lo[c]
        hi = y_hi if trim_hi is None else trim_hi[c]
        for ea, eb in zip(edges[:-1], edges[1:]):
            if ea < lo - 1e-6 or eb > hi + 1e-6:
                continue
            a = ea if abs(ea + HALF_LEN) < 1e-6 else ea + 0.015
            b_ = eb if abs(eb - HALF_LEN) < 1e-6 else eb - 0.015
            za, zb = z0 + 0.012, z1 - 0.012
            for sx in (-1, 1):
                st.box((sx * (CORE_H + PROUD / 2 - 0.002), (a + b_) / 2, (za + zb) / 2),
                       (PROUD + 0.004, b_ - a, zb - za), S)


def base_wall(st, ya, yb):
    """Miez + placa de coronament, de la ya la yb (capete plane)."""
    st.box((0.0, (ya + yb) / 2, 0.30), (2 * CORE_H, yb - ya, 0.60), S)
    st.box((0.0, (ya + yb) / 2, (BASE_TOP + SLAB_TOP) / 2), (0.54, yb - ya, SLAB_TOP - BASE_TOP), S)


def pilasters(st, ys):
    for y in ys:
        for sx in (-1, 1):
            st.box((sx * 0.265, y, 0.27), (0.06, 0.34, 0.50), S)


def build_balustrade(gap=False):
    st, li = Builder(), Builder()
    rnd = lcg(91 if not gap else 97)

    def wave(y):
        return BAL_AMP * math.sin(2 * math.pi * BAL_WAVES * y / LEN)

    if not gap:
        base_wall(st, -HALF_LEN, HALF_LEN)
        base_blocks(st)
        pilasters(st, PILASTER_Y)
        tube(st, body_path(BAL_Z, BAL_AMP, waves=BAL_WAVES), BAL_R, S, flat_y=True)
    else:
        # golul: baza si trupul rupte zimtat; golul liber ~2,2-3,0 m
        e = [1.0, 1.3, 1.05, 1.45]       # unde se opreste |y| miezul jos, randul 2, randul 3, placa
        for sgn in (-1, 1):
            pts = []
            for x in (-CORE_H, CORE_H):
                for z, ee in ((0.0, e[0]), (0.30, e[1]), (0.60, e[3])):
                    pts.append(Vector((x, sgn * ee * (1.0 + (0.08 if x > 0 else -0.05)), z)))
                    pts.append(Vector((x, sgn * HALF_LEN, z)))
            hull(st, pts, S)
            ys0, ys1 = sorted((sgn * e[3], sgn * HALF_LEN))
            st.box((0.0, (ys0 + ys1) / 2, (BASE_TOP + SLAB_TOP) / 2), (0.54, ys1 - ys0, SLAB_TOP - BASE_TOP), S)
        base_blocks(st, y_hi=-e[0] - 0.1, trim_hi=[-e[0] - 0.1, -e[1] - 0.1, -e[2] - 0.1])
        base_blocks(st, y_lo=e[0] + 0.1, trim_lo=[e[0] + 0.1, e[1] + 0.1, e[2] + 0.1])
        pilasters(st, (-1.5, 1.5))
        left = body_path(BAL_Z, BAL_AMP, y1=-1.45, waves=BAL_WAVES)
        right = list(reversed(body_path(BAL_Z, BAL_AMP, y0=1.5, waves=BAL_WAVES)))
        tube(st, left, BAL_R, S, flat_y=True, break_end=lambda a: 0.14 * math.cos(a) + 0.06 * math.sin(a))
        tube(st, right, BAL_R, S, flat_y=True, break_end=lambda a: -0.12 * math.cos(a) + 0.08 * math.sin(a))
        # --- bucati cazute PE PARTEA EXTERIOARA (+X), jos pe pamant ---
        base_z = BAL_R * (1 - GROOVE * 0.5)
        d = Vector((0.30, 1.0, 0.0)).normalized()
        c0 = Vector((0.85, -0.15, base_z))
        tube(st, [c0 + d * (-0.55 + 0.1 * i) for i in range(12)], BAL_R, S)
        st.box((0.92, 0.95, 0.12), (0.54, 0.80, 0.24), S, rotation=Matrix.Rotation(math.radians(28.0), 3, "Z"))
        st.box((0.70, -1.10, 0.10), (0.46, 0.42, 0.20), S, rotation=Matrix.Rotation(math.radians(-35.0), 3, "Z"))
        st.box((1.22, -0.78, 0.09), (0.30, 0.26, 0.18), S, rotation=Matrix.Rotation(math.radians(17.0), 3, "Z"))
        st.box((0.55, 0.50, 0.07), (0.30, 0.22, 0.14), S, rotation=Matrix.Rotation(math.radians(60.0), 3, "Z"))
        st.box((1.18, 0.18, 0.06), (0.20, 0.16, 0.12), S, rotation=Matrix.Rotation(math.radians(50.0), 3, "Z"))
    # lichen: pete mici pe placa si pe spinarea trupului (doar acolo unde exista)
    for y in (-1.7, -0.4, 0.9, 1.75):
        if gap and -1.45 < y < 1.5:
            continue
        lichen_on(li, rnd, y, 0.17, SLAB_TOP + 0.002, "g", 0.5)
    for y in (-1.8, -0.9, 0.2, 1.1, 1.8):
        if gap and -1.45 < y < 1.5:
            continue
        lichen_on(li, rnd, y, 0.0, BAL_Z + wave(y) + BAL_R * 0.97 - 0.02, "g" if rnd() < 0.75 else "o", 0.45)
    return [st.to_object("Naga_Stone"), li.to_object("Naga_Lichen")]


# --- capul naga ----------------------------------------------------------------

HEAD_C = Vector((0.0, 0.30, 1.40))      # butucul evantaiului
HEAD_ANGLES = [-54.0, -36.0, -18.0, 0.0, 18.0, 36.0, 54.0]


def build_head():
    st, li = Builder(), Builder()
    rnd = lcg(131)
    # soclu: aceeasi baza continua ca la balustrada (y -1,0..-0,4), apoi trei randuri de piedestal
    base_wall(st, -1.0, -0.40)
    for sx in (-1, 1):
        st.box((sx * (CORE_H + PROUD / 2 - 0.002), -0.70, 0.26), (PROUD + 0.004, 0.57, 0.50), S)
    st.box((0.0, 0.25, 0.10), (1.10, 1.30, 0.20), S)
    st.box((0.0, 0.25, 0.31), (0.92, 1.10, 0.22), S)
    st.box((0.0, 0.25, 0.51), (0.80, 0.96, 0.18), S)
    # trupul: intra plat la 0,76 (aceeasi sectiune si cota ca balustrada), apoi urca
    path = [Vector((0.0, -1.0, BAL_Z)), Vector((0.0, -0.75, BAL_Z)), Vector((0.0, -0.5, BAL_Z)),
            Vector((0.0, -0.3, BAL_Z + 0.05)), Vector((0.0, -0.1, BAL_Z + 0.22)),
            Vector((0.0, 0.06, BAL_Z + 0.46)), Vector((0.0, 0.18, BAL_Z + 0.58)),
            Vector((0.0, 0.26, HEAD_C.z))]
    tube(st, path, BAL_R, S, flat_y=True, cap_end=False, groove=0.07, period=0.4,
         taper=lambda f: 1.0 + 0.30 * max(0.0, f - 0.75) / 0.25)
    # butucul: disc gros in spatele evantaiului
    hub = HEAD_C + Vector((0.0, -0.02, 0.0))
    st.cylinder(hub, 0.30, 0.20, S, segments=12, axis="Y")
    # placa evantaiului: sectoare-invelitoare intre unghiuri consecutive
    sector = [-56.0 + 112.0 * k / 12.0 for k in range(13)]
    R_IN, R_OUT = 0.10, 0.66
    for a0, a1 in zip(sector[:-1], sector[1:]):
        pts = []
        for a in (a0, a1):
            ar = math.radians(a)
            dirv = Vector((math.sin(ar), 0.0, math.cos(ar)))
            for r in (R_IN, R_OUT):
                for dy in (-0.05, 0.07):
                    pts.append(HEAD_C + dirv * r + Vector((0.0, dy, 0.0)))
        hull(st, pts, S)
    # sapte capete: gat, craniu, bot cu sprancene si doi ochi
    for k, phi in enumerate(HEAD_ANGLES):
        ar = math.radians(phi)
        a_ = Vector((math.sin(ar), 0.0, math.cos(ar)))      # de-a lungul gatului
        c_ = Vector((math.cos(ar), 0.0, -math.sin(ar)))     # de-a latul
        f_ = Vector((0.0, 1.0, 0.0))
        L = 0.80 - 0.10 * (abs(phi) / 54.0) ** 2
        base = HEAD_C
        # gat
        pts = []
        for (t, w, th) in ((0.10, 0.10, 0.07), (L, 0.115, 0.075)):
            for sc in (-1, 1):
                for sf in (-1, 1):
                    pts.append(base + a_ * t + c_ * (sc * w) + f_ * (0.03 + sf * th))
        hull(st, pts, S)
        # craniu + bot (pana): spate lat, fata ingusta si inclinata in jos
        tip = base + a_ * L
        pts = []
        for (t, w, fy) in ((-0.02, 0.15, -0.07), (-0.02, 0.15, 0.10), (0.27, 0.13, -0.05), (0.27, 0.13, 0.10),
                           (0.12, 0.085, 0.27), (0.20, 0.085, 0.27)):
            for sc in (-1, 1):
                pts.append(tip + a_ * t + c_ * (sc * w) + f_ * fy)
        hull(st, pts, S)
        # sprancene (bara peste ochi) si doi ochi mici in relief
        brow = tip + a_ * 0.19 + f_ * 0.17
        hull(st, [brow + c_ * (sc * w) + a_ * da + f_ * df
                  for sc in (-1, 1) for (w, da, df) in ((0.13, 0.0, -0.02), (0.13, 0.04, 0.0), (0.0, 0.0, 0.05), (0.0, 0.05, 0.05))], S)
        for sc in (-1, 1):
            eye = tip + a_ * 0.13 + c_ * (sc * 0.085) + f_ * 0.215
            st.box(eye, (0.05, 0.05, 0.05), S, rotation=Matrix.Rotation(ar, 3, "Y"))
    # lichen pe soclu
    for (x, y) in ((0.30, 0.10), (-0.28, 0.45), (0.05, 0.75), (0.2, -0.3)):
        lichen_on(li, rnd, y, x, 0.60 if abs(x) < 0.4 else 0.40, "g" if rnd() < 0.7 else "o", 0.9)
    return [st.to_object("Naga_Stone"), li.to_object("Naga_Lichen")]


# --- fata asura (incruntata, aceleasi forme mari) ----------------------------------

def fierce_face(b, origin, yaw_deg, H, slot=S, us=1.0):
    """Fata asura SIMPLIFICATA: aceeasi placa ovala, urechi si diadema ca la
    `face_relief`, dar sprancene grele in V (capatul dinspre nas mai jos), ochi
    bulbucati ca DISCURI ridicate cu pupila, nas lat, gura larga incruntata (colturile
    in jos) si doi colti-pana. Fara portret: forme mari, putin adanci."""
    fr = Frame(origin, yaw_deg)
    h = H
    rot = fr.rot
    pl = FACE_PLATE

    def P(u, t, w):
        return fr.p(u * h * us, w * h, t * h)

    def chain(path):
        for a_, b_ in zip(path[:-1], path[1:]):
            pts = []
            for (u, t, w, th) in (a_, b_):
                pts += [P(u, t + th, w), P(u, t - th, w), P(u, t + th, pl), P(u, t - th, pl)]
            hull(b, pts, slot)

    def E(u, t, w, ru, rt, rw, seg=10, rings=6):
        ellipsoid(b, P(u, t, w), (ru * h * us, rw * h, rt * h), slot, rot, seg, rings)

    outline = [(0.17, 0.00), (0.29, 0.04), (0.38, 0.16), (0.41, 0.36),
               (0.41, 0.62), (0.40, 0.88), (0.35, 1.10)]
    pts = []
    for (u, t) in outline:
        pts += [P(u, t, 0.0), P(-u, t, 0.0)]
        pts += [P(u * 0.92, t * 0.97 + 0.015, pl), P(-u * 0.92, t * 0.97 + 0.015, pl)]
    hull(b, pts, slot)
    # nas: pana lata, mai bombata la varf
    hull(b, [P(sg * u, t, w) for sg in (-1, 1) for (u, t, w) in
             ((0.04, 0.66, pl + 0.006), (0.075, 0.52, pl + 0.034), (0.07, 0.40, pl + 0.056),
              (0.135, 0.375, pl + 0.030), (0.135, 0.375, pl), (0.045, 0.66, pl))], slot)
    # sprancene in V: capatul de langa nas mai jos, cel exterior mai sus
    for sgn in (-1, 1):
        path = []
        for k in range(5):
            f = k / 4.0
            path.append((sgn * (0.05 + 0.30 * f), 0.70 + 0.12 * f - 0.012 * math.sin(math.pi * f),
                         pl + 0.040, 0.020))
        chain(path)
    # ochi: disc ridicat cu pupila si o pleoapa grea deasupra
    for sgn in (-1, 1):
        E(sgn * 0.19, 0.615, pl + 0.022, 0.082, 0.082, 0.046, 12, 7)
        E(sgn * 0.185, 0.605, pl + 0.060, 0.036, 0.036, 0.022, 8, 5)
        lid = []
        for k in range(4):
            f = k / 3.0
            lid.append((sgn * (0.115 + 0.15 * f), 0.690 + 0.050 * f - 0.020 * math.sin(math.pi * f), pl + 0.050, 0.014))
        chain(lid)
    # gura larga incruntata (colturile in jos) + colti
    hw = 0.21

    def zc(u):
        return 0.215 - 0.060 * (u / hw) ** 2

    upper, lowerlip = [], []
    for k in range(9):
        u = -hw + 2 * hw * k / 8.0
        a = abs(u) / hw
        e = 1.0 - 0.40 * a * a
        upper.append((u, zc(u) + 0.006 + 0.018 * e, pl + 0.026 * e + 0.004, 0.017 * e + 0.003))
        lowerlip.append((u, zc(u) - 0.006 - 0.022 * e, pl + 0.030 * e + 0.004, 0.022 * e + 0.003))
    chain(upper)
    chain(lowerlip)
    for sgn in (-1, 1):
        u = sgn * 0.085
        hull(b, [P(u - 0.020, zc(u) - 0.010, pl + 0.030), P(u + 0.020, zc(u) - 0.010, pl + 0.030),
                 P(u - 0.020, zc(u) - 0.010, pl + 0.052), P(u + 0.020, zc(u) - 0.010, pl + 0.052),
                 P(u, zc(u) + 0.070, pl + 0.058)], slot)
    # urechi (ca la deva) si diadema plata cu trei rozete
    for sgn in (-1, 1):
        hull(b, [P(sgn * 0.405, 0.82, 0.0), P(sgn * 0.46, 0.77, 0.032), P(sgn * 0.485, 0.60, 0.038),
                 P(sgn * 0.47, 0.45, 0.032), P(sgn * 0.405, 0.45, 0.0), P(sgn * 0.41, 0.76, 0.034)], slot)
        hull(b, [P(sgn * 0.42, 0.50, 0.0), P(sgn * 0.47, 0.46, 0.028), P(sgn * 0.465, 0.20, 0.032),
                 P(sgn * 0.43, 0.14, 0.032), P(sgn * 0.405, 0.26, 0.012), P(sgn * 0.41, 0.20, 0.0)], slot)
    bl, bh = 1.075, 1.175
    wb = pl + 0.004
    hull(b, [P(sgn * 0.44, t, w) for sgn in (-1, 1) for t in (bl, bh) for w in (0.0, wb)], slot)
    for u in (-0.25, 0.0, 0.25):
        E(u, (bl + bh) * 0.5, wb + 0.002, 0.040, 0.040, 0.016, 10, 6)
    return bh * h


# --- uriasul -------------------------------------------------------------------

GH = 0.66                 # inaltimea fetei (sprancene-barbie), uriasii au cap mare
GUS = 1.25                # fata mai lata decat a turnului (cap de basm)
Z_CHIN = 1.84
HEAD_X = 0.02
CORE_HALF_X = 0.29        # nucleul capului: fata pe x = HEAD_X - 0.29 = -0.27


def build_giant(kind):
    A = kind == "asura"
    nm = "Asura" if A else "Deva"
    st, li = Builder(), Builder()
    rnd = lcg(211 if A else 173)
    kw = 1.10 if A else 1.0         # asura e mai lat in umeri
    bel = 0.07 if A else 0.0        # si cu burta mai iesita

    # soclu jos in doua randuri (depth 1,56 <= 1,6)
    st.box((0.0, 0.0, 0.07), (1.56, 2.40, 0.14), S)
    st.box((0.0, 0.0, 0.21), (1.42, 2.20, 0.14), S)
    # bazin / sezut
    st.box((0.10, 0.0, 0.53), (0.72, 1.00 * kw, 0.50), S)
    for s in (-1, 1):
        # coapsa: de la sold la genunchi (genunchii sus si departe unul de altul)
        pts = []
        for (x0, x1, yc, yh, z0, z1) in ((-0.05, 0.46, 0.30, 0.26, 0.30, 0.82),
                                         (-0.70, -0.34, 0.70, 0.21, 0.72, 1.14)):
            for x in (x0, x1):
                for y in (s * (yc - yh), s * (yc + yh)):
                    for z in (z0, z1):
                        pts.append(Vector((x, y, z)))
        hull(st, pts, S)
        # gamba, laba, degete
        st.box((-0.52, s * 0.70, 0.63), (0.34, 0.38, 0.64), S)
        st.box((-0.54, s * 0.70, 0.35), (0.44, 0.40, 0.14), S)
        for j in (-1, 0, 1):
            st.box((-0.76, s * (0.70 + j * 0.125), 0.33), (0.07, 0.10, 0.09), S)
    # trunchi: straturi (burta, piept, umeri), usor inclinat pe spate
    layers = [(0.76, -0.30, 0.40, 0.50), (1.05, -0.36 - bel, 0.48, 0.60), (1.42, -0.30 - bel * 0.5, 0.52, 0.72),
              (1.78, -0.20, 0.52, 0.84)]
    pts = []
    for (z, xf, xb, yh) in layers:
        for x in (xf, xb):
            for y in (-yh * kw, yh * kw):
                pts.append(Vector((x, y, z)))
    hull(st, pts, S)
    # cingatoare si colier (benzi plate, relief)
    st.box((0.08, 0.0, 0.82), (0.84, 1.02 * kw, 0.10), S)
    st.box((-0.275 - bel * 0.5, 0.0, 1.62), (0.06, 0.84 * kw, 0.12), S)
    st.box((0.05, 0.0, 1.82), (0.36, 0.44, 0.14), S)       # gat
    # brate: umar, brat, antebrat spre mana de pe trup, mana, degete
    ya = 0.90 * kw
    for s in (-1, 1):
        def Hp(x0, x1, y0, y1, z0, z1):
            return [Vector((x, s * y, z)) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
        hull(st, Hp(-0.20, 0.30, ya - 0.20, ya + 0.20, 1.46, 1.86), S)                          # deltoid
        hull(st, Hp(-0.18, 0.26, ya - 0.12, ya + 0.20, 1.52, 1.82) + Hp(-0.26, 0.12, ya - 0.06, ya + 0.22, 1.05, 1.35), S)
        hull(st, Hp(-0.26, 0.12, ya - 0.15, ya + 0.17, 1.05, 1.35) + Hp(-0.58, -0.30, 0.20, 0.52, 1.68, 1.90), S)
        st.box((-0.44, s * 0.36, 1.84), (0.38, 0.36, 0.22), S)                                  # pumn
        for dx in (-0.255, 0.255):
            st.box((-0.44 + dx, s * 0.36, 1.56), (0.10, 0.32, 0.36), S)                         # degete pe lateral
        st.box((-0.10, s * (ya + 0.05), 1.22), (0.34, 0.30, 0.07), S)                           # bratara de la cot
    # capul: nucleu + banda + coroana
    zc0, zc1 = Z_CHIN, Z_CHIN + 0.72
    hy = 0.38 * kw
    hull(st, [Vector(p_) for p_ in (
        (HEAD_X - CORE_HALF_X, -hy, zc0), (HEAD_X - CORE_HALF_X, hy, zc0), (HEAD_X - CORE_HALF_X, -hy, zc1 - 0.06),
        (HEAD_X - CORE_HALF_X, hy, zc1 - 0.06),
        (HEAD_X, -hy - 0.05, zc0 + 0.03), (HEAD_X, hy + 0.05, zc0 + 0.03), (HEAD_X, -hy - 0.05, zc1), (HEAD_X, hy + 0.05, zc1),
        (HEAD_X + CORE_HALF_X, -hy + 0.06, zc0 + 0.10), (HEAD_X + CORE_HALF_X, hy - 0.06, zc0 + 0.10),
        (HEAD_X + CORE_HALF_X, -hy + 0.06, zc1 - 0.04), (HEAD_X + CORE_HALF_X, hy - 0.06, zc1 - 0.04))], S)
    origin = Vector((HEAD_X - CORE_HALF_X, 0.0, Z_CHIN))
    if A:
        fierce_face(st, origin, 90.0, GH, us=GUS)
    else:
        face_relief(st, origin, 90.0, GH, us=GUS)
    st.box((HEAD_X + 0.02, 0.0, zc1 - 0.01), (2 * CORE_HALF_X + 0.06, 2 * hy + 0.14, 0.12), S)
    z = zc1 + 0.02
    if A:
        # coroana de flacari: doua etaje late si o flacara centrala, sase colturi pe margine
        for (rb, rt, h) in ((0.38, 0.34, 0.06), (0.32, 0.24, 0.08)):
            st.frustum((HEAD_X, 0.0, z + h / 2), rb, rt, h, S, segments=8)
            z += h
        for k in range(8):
            ang = 2 * math.pi * k / 8
            cx, cy = HEAD_X + 0.30 * math.cos(ang), 0.30 * math.sin(ang)
            base_z = zc1 + 0.04
            hull(st, [Vector((cx + dx, cy + dy, base_z)) for dx in (-0.045, 0.045) for dy in (-0.045, 0.045)]
                 + [Vector((cx * 0.92 + HEAD_X * 0.08, cy * 0.92, base_z + 0.30))], S)
        st.frustum((HEAD_X, 0.0, z + 0.12), 0.15, 0.025, 0.24, S, segments=8)
        crown_top = z + 0.24
    else:
        # coroana conica inalta: sase etaje care se subtiaza, cu un finial
        for (rb, rt, h) in ((0.36, 0.32, 0.05), (0.32, 0.25, 0.07), (0.25, 0.18, 0.07),
                            (0.18, 0.12, 0.07), (0.12, 0.06, 0.07), (0.06, 0.015, 0.06)):
            st.frustum((HEAD_X, 0.0, z + h / 2), rb, rt, h, S, segments=8)
            z += h
        crown_top = z
    # lichen: soclu, genunchi, umeri, crestet
    spots = [(0.45, 1.0, 0.285, "g"), (-0.50, -0.95, 0.285, "o"), (0.2, -1.0, 0.285, "g"),
             (-0.55, 0.7, 1.16, "g"), (-0.52, -0.7, 1.16, "o"), (0.05, 0.9 * kw, 1.88, "g"),
             (0.10, -0.92 * kw, 1.88, "g"), (0.05, 0.4, 0.80 + 0.01, "g")]
    for (x, y, zz, k) in spots:
        lichen_on(li, rnd, y, x, zz, k, 1.0)
    # trupul naga: PRIN brate, pe tot modulul (capete plane la y = +-2,0)
    st_body = body_path(GIANT_Z, GIANT_AMP, x=-0.42)
    tube(st, st_body, BODY_R, S, flat_y=True)
    return [st.to_object(nm + "_Stone"), li.to_object(nm + "_Lichen")], crown_top


# --- emit ----------------------------------------------------------------------

def emit_piece(path, objs, ao, anchor):
    emit_angkor(objs, path, ao, bevel=0.0, bevels={"_Lichen": 0.0}, smooth_angle=55.0, anchor=anchor)
    clear_built()


def want(k):
    return not ONLY or ONLY == k


if want("bal"):
    emit_piece("kit/naga_balustrade.glb", build_balustrade(False), AO_BAL, (0.0, 0.0))
if want("gap"):
    emit_piece("kit/naga_balustrade_gap.glb", build_balustrade(True), AO_BAL, (0.0, 0.0))
if want("head"):
    emit_piece("kit/naga_head.glb", build_head(), AO_HEAD, (0.0, -1.0))
if want("deva"):
    o, top = build_giant("deva")
    print("deva crown top z=%.2f" % top)
    emit_piece("kit/deva_giant.glb", o, AO_GIANT, (0.0, 0.0))
if want("asura"):
    o, top = build_giant("asura")
    print("asura crown top z=%.2f" % top)
    emit_piece("kit/asura_giant.glb", o, AO_GIANT, (0.0, 0.0))
report_angkor()
