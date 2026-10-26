"""Fiordland — Padurea (brief §1.4 din docs/asset_briefs/fiordland_kit.md).

  fiordland/plants/beech_a.glb           fag argintiu 8 m
  fiordland/plants/beech_b.glb           fag argintiu 11 m
  fiordland/plants/beech_c.glb           fag argintiu 14 m
  fiordland/plants/beech_dead.glb        fag uscat 9 m
  fiordland/plants/rata_tree.glb         rata in floare 5 m
  fiordland/plants/tussock_clump.glb     smoc de tussock 0.8 m
  fiordland/props/stump.glb              ciot cu muschi 1.0 m
  fiordland/props/driftwood.glb          trunchi pe mal 4 m
  fiordland/structures/chasm_bridge_rail.glb   balustrade pod, 40 m

BEECH_A INTAI, verificat pe silueta (goluri intre etaje) si pe buget (<300)
INAINTE de b/c (brief §3, val 2). Trunchi NEGRU (LOG_DARK) si SUBTIRE
(0.25-0.45 m baza), gol pe prima jumatate. Coroana: 3-4 volume TURTITE in
ETAJE, discuri neregulate 2-4x mai late decat inalte, la inaltimi diferite,
cu cer intre ele. NU o bila, NU brocoli — planul ChatGPT a gresit exact aici
(vezi brief §1.4 si docs/track_briefs/img/fiordland_assets_v1.jpg randul
"beech forest", care e gresit despre trunchi si coroana).

Tier-ele coroanei se fac cu `rock(flat_top=True, taper mic)` in loc de
`boulder()`: un `boulder` 2-4 m dupa bevel trece usor de 100 tri (masurat in
build_machupicchu_forest.py: 6x3 costa 90 brut, x3.67 dupa bevel), iar un fag
are nevoie de 3-4 dintre ele plus trunchi, in doar 300 tri total. Un `rock()`
turtit (rings=1, segments=5-6) da un disc neregulat fatetat la 10-16 tri
brut — bugetul incape.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_forest.py
"""

import math
import bmesh
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (brief §0.4).
TRUNK = LOG_DARK              # trunchiuri negre, umbra adanca de padure, lemn putred
CROWN = TROPICAL_GREEN        # coronament de fag, muschi pe piatra
MOSS = CACTUS_GREEN           # tussock, muschi uscat, iarba oliv
FLOWER = KERB_RED             # flori de rata (accent rar)
WOOD_SLOT = WOOD              # scanduri, barne, cheiul de lemn

AO_TREE = dict(samples=16, dist=5.0, gradient="vertical",
               low=0.42, high=1.00, power=0.85, floor=0.16)
AO_SMALL = dict(samples=18, dist=1.4, gradient="vertical",
                low=0.48, high=1.00, power=0.90, floor=0.20)
AO_RAIL = dict(samples=16, dist=2.0, gradient="vertical",
               low=0.46, high=1.00, power=0.88, floor=0.18)


# --- unelte comune v2 (fidelitate fata de planse) ----------------------------
#
# Brief v2 (fiordland_kit_v2.md §2 grupa B): planșa bate contractul v1. Copacii
# se construiesc dintr-un LAYOUT citit de pe decuparea planșei (pixeli ->
# metri), nu din reguli generice: fiecare masa de coroana are pozitia ei.
# `_fit` apoi scaleaza pozitiile/marimile pana cand AABB-ul iese pe cotele
# contractului (planșa e desenata mai lata decat cer cotele din §2).

def _bb(builders):
    xs, ys, zs = [], [], []
    for b in builders:
        for v in b.bm.verts:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    return (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))


def _fit(assemble, target, k0, iters=5):
    """`assemble(k)` -> [Builder]; k = (kx, ky, kz). Itereaza k pana cand
    extinderea X/Y(adancime)/Z(inaltime) a ansamblului nimereste `target`."""
    k = list(k0)
    for _ in range(iters):
        bs = assemble(k)
        dx, dy, dz = _bb(bs)
        for b in bs:
            b.bm.free()
        k[0] *= target[0] / dx
        k[1] *= target[1] / dy
        k[2] *= target[2] / dz
    return assemble(k), k


def _trunk_at(pts, z):
    for p0, p1 in zip(pts, pts[1:]):
        if p0.z <= z <= p1.z:
            t = (z - p0.z) / max(p1.z - p0.z, 1e-6)
            return p0.lerp(p1, t)
    return pts[-1].copy() if z > pts[-1].z else pts[0].copy()


def _make_trunk(bt, top_z, r_mid, lean_to, seg=6, flare=1.45):
    """Trunchi cu EVAZARE la baza (planșa: baza se lateste in 3-4 radacini),
    subtiindu-se spre varf; liderul urca pana sub masa cea mai de sus."""
    fr = [0.0, 0.05, 0.16, 0.45, 0.72, 1.0]
    rr = [flare, 1.18, 1.0, 0.82, 0.58, 0.34]
    pts = [Vector((lean_to[0] * t ** 1.6, lean_to[1] * t ** 1.6, top_z * t))
           for t in fr]
    bt.taper_sweep(pts, [r_mid * r for r in rr], TRUNK, segments=seg)
    return pts


def _roots(bt, r_mid, n, seed, seg=4):
    """Radacini joase, care pleaca din evazarea trunchiului si intra in sol."""
    rand = _lcg(seed)
    for k in range(n):
        a = 2.0 * math.pi * k / n + rand() * 0.7
        d = Vector((math.cos(a), math.sin(a), 0.0))
        L = r_mid * (2.1 + rand() * 0.6)
        bt.taper_sweep([d * (r_mid * 0.7) + Vector((0, 0, r_mid * 0.75)),
                        d * (L * 0.55) + Vector((0, 0, r_mid * 0.30)),
                        d * L + Vector((0, 0, 0.0))],
                       [r_mid * 0.55, r_mid * 0.38, r_mid * 0.06], TRUNK,
                       segments=seg)


def _branches(bt, clumps, tpts, r_mid, r_factor=0.5, split_lo=0.42, seg=5):
    """Ramuri groase care pleaca din FURCA trunchiului (V clar) spre masele
    de coroana: masele joase pleaca chiar din furca, cele inalte mai sus pe
    lider. Ramura urca aproape vertical intai, apoi se departeaza (arc)."""
    top_z = tpts[-1].z
    split_z = split_lo * top_z
    for (c, wx, wy, hz) in clumps:
        horiz = math.hypot(c.x, c.y)
        if horiz < 0.3 and c.z > top_z * 0.75:
            continue
        t = min(max((c.z - split_z) / max(top_z - split_z, 1e-6), 0.0), 1.0)
        z_a = split_z + t * 0.8 * (c.z - 0.4 - split_z)
        if z_a > c.z - 0.3:
            z_a = c.z * 0.7
        p0 = _trunk_at(tpts, z_a)
        tgt = Vector((c.x, c.y, c.z - 0.15 * hz))
        if (tgt - p0).length < 0.35:
            continue
        mid = p0.lerp(tgt, 0.45)
        mid.z = p0.z + (tgt.z - p0.z) * 0.75
        r0 = r_mid * r_factor * (1.0 if t < 0.3 else 0.85)
        bt.taper_sweep([p0, mid, tgt], [r0, r0 * 0.66, r0 * 0.25], TRUNK,
                       segments=seg)


def _clump_records(spec, ppm, axis_x, base_y, k, dspan, grow=1.22):
    kx, ky, kz = k
    out = []
    for (px, py, w, h, df) in spec:
        out.append((Vector(((px - axis_x) / ppm * kx, df * dspan * ky,
                            (base_y - py) / ppm * kz)),
                    w / ppm * (0.55 + 0.45 * kx) * grow,
                    w / ppm * (0.55 + 0.45 * ky) * 0.95 * grow,
                    h / ppm * kz * (0.85 + 0.2 * grow)))
    return out


# --- beech (fag argintiu) ----------------------------------------------------
#
# Layout citit de pe decupare: (x_px, y_px, latime_px, inaltime_px, adancime
# in [-1,1]). Coroana = 9 mase fatetate in ETAJE cu cer intre ele, mai late
# decat inalte; trunchi gros cu evazare + 4 radacini, ramuri groase.

BEECH_A_SPEC = [
    (160, 48, 120, 66, 0.0),      # cupola de sus
    (103, 98, 82, 54, -0.7),      # sus-stanga
    (215, 122, 104, 66, 0.5),     # sus-dreapta
    (130, 128, 52, 40, 0.15),     # umplutura dintre ele
    (78, 160, 128, 80, 0.7),      # mijloc-stanga, masa mare
    (198, 186, 100, 58, 0.95),    # mijloc-fata
    (276, 214, 94, 70, -0.45),    # dreapta
    (76, 240, 108, 40, -0.8),     # etajul de jos, stanga
    (206, 242, 70, 34, 0.55),     # etajul de jos, dreapta
]
BEECH_B_SPEC = [
    (190, 40, 80, 60, 0.0),
    (150, 80, 90, 55, -0.7),
    (295, 108, 100, 50, 0.4),
    (215, 112, 52, 40, -0.2),
    (160, 155, 85, 60, 0.8),
    (255, 160, 130, 60, -0.5),
    (97, 218, 110, 80, 0.9),       # ramura joasa pe o parte, ca pe planșă
    (290, 224, 80, 55, -0.7),
]
BEECH_C_SPEC = [
    (205, 40, 95, 50, 0.0),
    (152, 85, 90, 55, -0.8),
    (250, 100, 95, 55, 0.6),
    (205, 118, 42, 40, 0.1),
    (102, 130, 105, 65, 0.7),
    (170, 166, 95, 55, -0.4),
    (290, 186, 130, 60, -0.6),
    (130, 236, 90, 40, 0.9),
    (285, 262, 120, 50, 0.5),
]


def build_beech(spec, ppm, axis_x, base_y, target, r_mid, seed, dspan):
    def assemble(k):
        clumps = _clump_records(spec, ppm, axis_x, base_y, k, dspan, grow=1.5)
        bc = Builder()
        allf = set()
        for i, (c, wx, wy, hz) in enumerate(clumps):
            # mase ROTUNJITE (v3): inaltime/latime ~0.72, nu discuri
            hh = max(hz, 0.72 * 0.5 * (wx + wy))
            allf |= bc.boulder((c.x, c.y, c.z), (wx, wy, hh * 0.95), CROWN,
                               seed=seed + i * 13, segments=8, rings=3,
                               deviation=0.16)
            br = _lcg(seed + i * 7)
            ph = 2.0 * math.pi * br()
            # lob suplimentar atarnat spre exterior (margine de conopida)
            allf |= bc.boulder(
                (c.x + math.cos(ph) * wx * 0.40, c.y + math.sin(ph) * wy * 0.40,
                 c.z - hh * 0.22),
                (wx * 0.55, wy * 0.55, hh * 0.55), CROWN,
                seed=seed + i * 31, segments=6, rings=2, deviation=0.18)
        bc.retag(allf, TRUNK, where="down")
        bc.retag(allf, CROWN, where="up")
        top = max(clumps, key=lambda q: q[0].z)
        top_z = top[0].z - top[3] * 0.30
        bt = Builder()
        tpts = _make_trunk(bt, top_z, r_mid, (top[0].x * 0.35, top[0].y * 0.35), flare=1.7)
        _roots(bt, r_mid, 4, seed + 7)
        _branches(bt, clumps, tpts, r_mid, r_factor=0.70, split_lo=0.42)
        return [bt, bc]

    (bt, bc), k = _fit(assemble, target, (1.0, 1.0, 1.0))
    print("beech fit k=%.3f %.3f %.3f" % tuple(k))
    return bt.to_object("Trunk"), bc.to_object("Crown")


# --- beech_dead ----------------------------------------------------------------

# --- unelte v3 (grupa B, constructor nou): sectiuni arbitrare pe traseu --------

def _ring_sweep(b, pts, sections, slots, up=(0, 0, 1)):
    """Matura o sectiune pe un traseu. `sections[i]` = lista de (u, v) in cadrul
    (x lateral, y normal) al statiei i, sau None pentru un VARF (un singur
    vertex, ex. capatul lamei). `slots[i]` = slotul segmentului i->i+1.
    Capacul de start se inchide cu o fata (corp inchis: se vede din orice
    unghi, fara backface culling)."""
    pts = [Vector(p) for p in pts]
    frames = b._frames(pts, up=up)
    rings = []
    for p, (_t, x, y), sec in zip(pts, frames, sections):
        if sec is None:
            rings.append([b.bm.verts.new(p)])
        else:
            rings.append([b.bm.verts.new(p + x * u + y * v) for (u, v) in sec])
    made = []
    for si, (lo, hi) in enumerate(zip(rings, rings[1:])):
        n = max(len(lo), len(hi))
        fs = []
        if len(hi) == 1:
            for i in range(n):
                fs.append(b.bm.faces.new((lo[i], lo[(i + 1) % n], hi[0])))
        else:
            for i in range(n):
                j = (i + 1) % n
                fs.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
        for f in fs:
            f[b.slot] = slots[si]
        made += fs
    cap = b.bm.faces.new(tuple(reversed(rings[0])))
    cap[b.slot] = slots[0]
    made.append(cap)
    bmesh.ops.recalc_face_normals(b.bm, faces=made)
    return made


def _limb(b, p0, az, L, phi0, phi1, r0, r1, n=4, seg=6, kx=1.0, kz=1.0,
          slot=None, ky=None):
    """Ramura rotunda, subtiata, care porneste la phi0 grade de verticala si se
    curbeaza spre phi1 (mai vertical = se indreapta in sus). Intoarce
    (puncte, raze) ca sa se poata ramifica din ea."""
    slot = TRUNK if slot is None else slot
    ky = kx if ky is None else ky
    a = math.radians(az)
    d = Vector((math.cos(a) * kx, math.sin(a) * ky, 0.0))
    pts, rad = [Vector(p0)], [r0]
    ds = L / n
    for i in range(n):
        t = (i + 0.5) / n
        phi = math.radians(phi0 + (phi1 - phi0) * t)
        pts.append(pts[-1] + d * (math.sin(phi) * ds) + Vector((0, 0, math.cos(phi) * ds * kz)))
        rad.append(r0 + (r1 - r0) * (i + 1) / n)
    b.taper_sweep(pts, rad, slot, segments=seg)
    return pts, rad


def build_beech_dead():
    """Fag uscat (v3): trunchi gros care se subtiaza, baza evazata cu 5
    contraforturi scurte; la ~50% se FURCHEAZA in 3 ramuri groase care se
    desfac 25-45 grade si se curbeaza in sus, fiecare furcheaza inca o data in
    ramuri subtiri; o ramura joasa laterala la ~35%; tulpina continua putin si
    se rupe intr-un ciot cu 3 aschii. Totul rotund si conic, fara varfuri."""
    H = 8.5
    TARGET = (4.8, 4.8, 8.5)

    def assemble(k):
        kx, ky, kz = k
        b = Builder()
        fr = [0.0, 0.04, 0.14, 0.30, 0.50, 0.70, 0.88, 0.94]
        rad = [0.80, 0.52, 0.44, 0.38, 0.30, 0.20, 0.15, 0.13]
        pts = [Vector((0.18 * f * f * 2.2, 0.08 * f * f * 2.0, H * f * kz))
               for f in fr]
        b.taper_sweep(pts, rad, TRUNK, segments=8)
        # contraforturi: creste late si joase care coboara din evazare
        rr = _lcg(5207)
        for j in range(5):
            a = 2.0 * math.pi * j / 5 + rr() * 0.5
            d = Vector((math.cos(a), math.sin(a), 0.0))
            L = 0.62 + rr() * 0.2
            b.taper_sweep([d * 0.22 + Vector((0, 0, 0.62)),
                           d * (L * 0.5) + Vector((0, 0, 0.27)),
                           d * L + Vector((0, 0, 0.0))],
                          [0.17, 0.12, 0.0], TRUNK, segments=6)
        # ciot rupt: trei aschii de inaltimi diferite
        top = pts[-1]
        for j, (hh, ang) in enumerate(((0.75, 20), (0.45, 140), (0.30, 250))):
            a = math.radians(ang)
            d = Vector((math.cos(a), math.sin(a), 0.0))
            b.taper_sweep([top - Vector((0, 0, 0.1)) + d * 0.04,
                           top + d * 0.07 + Vector((0, 0, hh * 0.5)),
                           top + d * 0.10 + Vector((0, 0, hh))],
                          [0.10, 0.065, 0.0], TRUNK, segments=5)
        zf = H * 0.50 * kz
        pf = _trunk_at(pts, zf)
        # 3 ramuri groase din furca
        for az, L, ph0, ph1 in ((15, 4.2, 50, 14), (135, 4.0, 46, 12), (255, 3.8, 42, 10)):
            lp, lr = _limb(b, pf - Vector((0, 0, 0.1)), az, L * kz, ph0, ph1,
                           0.33, 0.08, n=5, seg=7, kx=kx, ky=ky, kz=1.0)
            for idx, sgn, Lf in ((2, 1, 1.7), (3, -1, 1.4), (4, 1, 1.0)):
                _limb(b, lp[idx], az + sgn * 42, Lf, 45, 10, lr[idx] * 0.75,
                      0.03, n=3, seg=5, kx=kx, ky=ky, kz=kz)
        # ramura joasa laterala la ~35%
        pl = _trunk_at(pts, H * 0.35 * kz)
        lp, lr = _limb(b, pl - Vector((0, 0, 0.05)), 190, 3.4, 78, 30, 0.24,
                       0.05, n=4, seg=6, kx=kx, ky=ky, kz=kz)
        _limb(b, lp[2], 190 + 40, 1.1, 40, 8, lr[2] * 0.6, 0.02, n=3, seg=5,
              kx=kx, ky=ky, kz=kz)
        return [b]

    (b,), k = _fit(assemble, TARGET, (1.0, 1.0, 1.0))
    print("beech_dead fit k=%.3f %.3f %.3f" % tuple(k))
    b.retag(set(f for f in b.bm.faces if f.is_valid), MOSS,
            where=lambda c, n: (c.z < 0.9) and abs(n.z) < 0.5
            and (int(c.x * 7 + c.y * 5) % 4 == 0))
    return b.to_object("Beech_Dead")



# --- rata_tree -----------------------------------------------------------------

RATA_SPEC = [
    (178, 40, 70, 38, 0.0),        # varf
    (246, 86, 90, 52, 0.55),       # dreapta-sus, cea mai mare masa
    (108, 100, 72, 48, -0.6),      # stanga-sus
    (158, 110, 52, 40, -0.1),      # mijloc, in spate
    (282, 150, 52, 42, -0.4),      # dreapta-mijloc
    (150, 128, 76, 40, 0.8),       # mijloc-fata
    (128, 166, 78, 46, -0.5),      # stanga-jos
    (214, 166, 54, 36, 0.6),       # dreapta-jos
]


def build_rata_tree():
    """Rata in floare: COPACEL cu trunchi vizibil (~35% din inaltime) care se
    ramifica, coroana deschisa din 8 mase rotunjite, cu cer intre ele; florile
    sunt petice turtite de ciorchini (rosu 7) care ies putin din suprafata
    frunzisului, 5 pe masa — nu piramide in picioare. Frunzis 21 + 28."""
    ppm, ax, by = 54.0, 190.0, 285.0
    TARGET = (4.3, 4.2, 5.0)
    spec = RATA_SPEC

    def assemble(k):
        clumps = _clump_records(spec, ppm, ax, by, k, 1.7)
        bcr = Builder()
        rand = _lcg(5401)
        allf = set()
        for i, (c, wx, wy, hz) in enumerate(clumps):
            allf |= bcr.boulder((c.x, c.y, c.z), (wx, wy, hz), CROWN,
                                seed=5311 + i * 11, segments=6, rings=2,
                                deviation=0.20)
        bcr.retag(allf, TRUNK, where="down")
        bcr.retag(allf, CROWN, where="up")
        for i, (c, wx, wy, hz) in enumerate(clumps):
            n_cl = 5
            for j in range(n_cl):
                th = math.radians(6.0 + rand() * 54.0)
                ph = 2.0 * math.pi * (j + rand() * 0.6) / n_cl
                p = Vector((c.x + math.sin(th) * math.cos(ph) * wx * 0.5,
                            c.y + math.sin(th) * math.sin(ph) * wy * 0.5,
                            c.z + math.cos(th) * hz * 0.5)) \
                    + Vector((0, 0, -0.03))
                s = 0.34 + rand() * 0.14
                bcr.boulder((p.x, p.y, p.z), (s, s, s * 0.42), FLOWER,
                            seed=5600 + i * 17 + j, segments=5, rings=1,
                            deviation=0.12)
        top = max(clumps, key=lambda q: q[0].z)
        top_z = top[0].z - top[3] * 0.25
        tr = Builder()
        r_mid = 0.20
        tpts = _make_trunk(tr, top_z, r_mid, (top[0].x * 0.3, top[0].y * 0.3),
                           seg=5, flare=1.5)
        _roots(tr, r_mid, 3, 5303, seg=3)
        _branches(tr, clumps, tpts, r_mid, r_factor=0.62, split_lo=0.44, seg=4)
        bmesh_ops_join(bcr, tr)
        return [bcr]

    (b,), k = _fit(assemble, TARGET, (0.8, 0.8, 1.0))
    print("rata fit k=%.3f %.3f %.3f" % tuple(k))
    n_red = sum(1 for f in b.bm.faces if f[b.slot] == FLOWER)
    print("rata_tree: %d fete FLOWER din %d" % (n_red, len(b.bm.faces)))
    return b.to_object("Rata")


def bmesh_ops_join(dst, src):
    """Copiaza geometria + slotul fetelor din `src` in `dst`."""
    vmap = {}
    for v in src.bm.verts:
        vmap[v] = dst.bm.verts.new(v.co)
    for f in src.bm.faces:
        nf = dst.bm.faces.new([vmap[v] for v in f.verts])
        nf[dst.slot] = f[src.slot]
    src.bm.free()


# --- tussock_clump ---------------------------------------------------------------

def build_tussock_clump():
    """Smoc DENS (v3): 3 sub-smocuri lipite, ~32 lame fiecare (96 total).
    Lama = panglica subtire cu sectiune triunghiulara (corp inchis, 16 tri),
    2.5 cm la baza -> varf. Pleaca dintr-o baza stransa (raza ~5 cm) la 12-70
    grade de verticala (cele marginale mai culcate), se curbeaza spre afara si
    se apleaca la varf; interioarele sunt scurte si drepte, marginalele lungi
    si cazute: siluet de cupola mai lata sus decat la baza. Baza verde-oliv
    (MOSS), ultimele ~40% paiu (DRY_VEGETATION)."""
    b = Builder()
    rand = _lcg(5503)
    clumps = [(-0.12, 0.05, 38), (0.13, -0.02, 38), (0.0, -0.14, 34)]
    for (cx, cy, n) in clumps:
        for i in range(n):
            a = 2.0 * math.pi * (i * 0.618034 % 1.0) + rand() * 0.3
            d = Vector((math.cos(a), math.sin(a), 0.0))
            rn = (i * 7 % n) / float(n - 1)          # 0 central .. 1 marginal
            rn = rn ** 0.8
            phi0 = math.radians(10.0 + 34.0 * rn + rand() * 14.0)
            dphi = math.radians(24.0 + 58.0 * rn + rand() * 10.0)
            ell = 0.50 + 0.42 * rn + rand() * 0.10   # lungimea
            r0 = 0.015 + 0.04 * rand()
            base = Vector((cx, cy, 0.0)) + d * r0
            stops = (0.0, 0.30, 0.62, 1.0)
            pts = [base]
            ph = phi0
            for si in range(1, 4):
                ds = ell * (stops[si] - stops[si - 1])
                phm = phi0 + dphi * (stops[si] + stops[si - 1]) * 0.5
                pts.append(pts[-1] + d * (math.sin(phm) * ds)
                           + Vector((0, 0, math.cos(phm) * ds)))
            w = 0.040 + rand() * 0.012
            th = w * 0.55
            def sec(f):
                ww = w * f
                return [(-ww * 0.5, 0.0), (ww * 0.5, 0.0), (0.0, th * f)]
            secs = [sec(1.0), sec(0.9), sec(0.62), None]
            _ring_sweep(b, pts, secs, [MOSS, MOSS, DRY_VEGETATION], up=d)
    _rescale(b, (0.68, 0.80, 0.68))
    return b.to_object("Tussock_Clump")



def _rescale(b, target):
    """Scaleaza X/Y/Z (Blender) ca extinderea sa nimereasca `target`
    (x, z_up, y_adancime) — Godot-order: X, Y sus, Z adancime."""
    xs = [v.co.x for v in b.bm.verts]
    ys = [v.co.y for v in b.bm.verts]
    zs = [v.co.z for v in b.bm.verts]
    sx = target[0] / max(max(xs) - min(xs), 1e-6)
    sz = target[1] / max(max(zs) - min(zs), 1e-6)
    sy = target[2] / max(max(ys) - min(ys), 1e-6)
    zlo = min(zs)
    for v in b.bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z = (v.co.z - zlo) * sz + zlo


# --- stump -------------------------------------------------------------------

def build_stump():
    """Ciot (v3): trunchi usor conic cu fatete neregulate (varfurile jitterate
    radial), 6 radacini = CRESTE LATE SI JOASE (sectiune turtita, latime 2-3x
    inaltimea) care pornesc sus pe flancul trunchiului si curg in jos si afara,
    sfarsind LA NIVELUL SOLULUI. Muschi (12) in petice pe creste si baza, nu
    dungi. Taietura de sus deschisa cu inele."""
    b = Builder()
    rand = _lcg(5603)
    pts = [Vector((0, 0, 0)), Vector((0.01, 0, 0.2)), Vector((0, 0.01, 0.5)),
           Vector((0.03, 0, 0.78))]
    b.taper_sweep(pts, [0.58, 0.42, 0.34, 0.30], TRUNK, segments=10)
    jr = _lcg(5604)
    for v in b.bm.verts:
        if v.co.z > 0.03:
            f = 1.0 + (jr() - 0.5) * 0.16
            v.co.x *= f
            v.co.y *= f
    n = 6
    for k in range(n):
        a = 2.0 * math.pi * k / n + (rand() - 0.5) * 0.45
        d = Vector((math.cos(a), math.sin(a), 0.0))
        L = 0.78 + rand() * 0.22
        w0 = 0.19 + rand() * 0.04
        rp = [d * 0.22 + Vector((0, 0, 0.50)),
              d * (L * 0.30) + Vector((0, 0, 0.30)),
              d * (L * 0.52) + Vector((0, 0, 0.15)),
              d * (L * 0.74) + Vector((0, 0, 0.06)),
              d * (L * 0.92) + Vector((0, 0, 0.022)),
              d * L + Vector((0, 0, 0.008))]
        ws = [w0, w0 * 1.1, w0 * 1.0, w0 * 0.8, w0 * 0.5, w0 * 0.18]
        hs = [0.10, 0.085, 0.06, 0.04, 0.02, 0.008]

        def ell(w, h):
            return [(w * math.cos(2 * math.pi * q / 8),
                     h * math.sin(2 * math.pi * q / 8)) for q in range(8)]
        secs = [ell(ws[i], hs[i]) for i in range(6)]
        _ring_sweep(b, rp, secs, [TRUNK] * 5)
    def moss_here(c, nn):
        if nn.z < 0.15 or c.z > 0.45:
            return False
        q = (math.sin(c.x * 11.0 + 1.3) * math.sin(c.y * 9.0 + 0.4)
             + 0.6 * math.sin(c.z * 19.0 + c.x * 7.0))
        return q > 0.5 or c.z < 0.04
    b.retag(set(f for f in b.bm.faces if f.is_valid), MOSS, where=moss_here)
    top_z = 0.78
    b.retag(set(f for f in b.bm.faces if f.is_valid), SAND_LIGHT,
            where=lambda c, nn: nn.z > 0.9 and c.z > top_z - 0.02)
    b.frustum((0.03, 0.0, top_z + 0.006), 0.15, 0.15, 0.012, SAND_SHADOW,
              segments=8)
    _rescale(b, (1.1, 0.8, 1.0))
    return b.to_object("Stump")



# --- driftwood -----------------------------------------------------------------

def build_driftwood():
    """Bustean gros culcat, capatul rupt ZDRENTUIT (6 aschii + capac
    intunecat), 4 ramuri rotunde si conice care se ridica in unghiuri
    diferite (una cu furca), 2 cazute pe sol."""
    b = Builder()
    pts = [Vector((0.0, 0.0, 0.20)), Vector((1.3, 0.05, 0.19)),
           Vector((2.6, 0.0, 0.22)), Vector((3.85, -0.04, 0.27))]
    b.taper_sweep(pts, [0.25, 0.23, 0.19, 0.12], WOOD_SLOT, segments=7)
    for k in range(6):
        a = 2.0 * math.pi * k / 6
        yy, zz = math.cos(a) * 0.17, 0.20 + math.sin(a) * 0.17
        h = 0.18 + 0.16 * ((k * 5) % 3) / 2.0
        b.taper_sweep([Vector((0.12, yy, zz)),
                       Vector((-0.08 - h * 0.5, yy * 1.2, zz + h * 0.4))],
                      [0.055, 0.0], WOOD_SLOT, segments=3)
    b.retag(set(f for f in b.bm.faces if f.is_valid), LOG_DARK,
            where=lambda c, n: n.x < -0.8 and c.x < 0.02)

    def limb(path, radii, seg=6):
        b.taper_sweep([Vector(p) for p in path], radii, WOOD_SLOT, segments=seg)

    # ridicate, in unghiuri diferite (abrupt / inclinat / aproape orizontal)
    limb([(1.30, 0.00, 0.34), (1.52, 0.08, 0.80), (1.72, 0.12, 1.20)],
         [0.15, 0.11, 0.035])
    limb([(2.10, 0.00, 0.36), (2.55, -0.12, 0.66), (3.05, -0.22, 0.88)],
         [0.15, 0.11, 0.035])
    limb([(2.85, 0.02, 0.34), (3.15, 0.12, 0.78), (3.40, 0.16, 1.10)],
         [0.14, 0.10, 0.035])
    limb([(3.20, 0.14, 0.76), (3.55, 0.24, 0.84), (3.92, 0.26, 0.98)],
         [0.07, 0.05, 0.03])
    # cazute pe sol, spre capatul subtire
    limb([(1.20, -0.12, 0.18), (1.85, -0.24, 0.12), (2.50, -0.30, 0.06)],
         [0.12, 0.08, 0.025], 5)
    limb([(2.30, 0.14, 0.19), (2.85, 0.24, 0.12), (3.40, 0.30, 0.06)],
         [0.11, 0.07, 0.025], 5)
    _rescale(b, (4.0, 1.35, 0.62))
    return b.to_object("Driftwood")


# --- chasm_bridge_rail -----------------------------------------------------------
#
# Gard de lemn (planșa): stalpi patrati la 2.5 m, doua randuri de scanduri
# orizontale pe fata exterioara, imbinate (rosturi) si decalate intre randuri.
# Contract inghetat: Rail_L/R centrate la X = ±5.84, lungime 40 m (±20.25),
# Y de la -0.4 (stalpii coboara pe lateralul tablei) la +1.0 (waterline).
CB_LEN = 40.0
CB_X = 5.80
CB_N = 15           # stalpi: 14 deschideri de ~2.86 m


def _bridge_rail(sign):
    """Gard masiv: stalpi 0.20 m patrati (-0.4..1.0), doua scanduri groase
    (0.08 x 0.22 m) pe fata exterioara, imbinate si decalate, lemn inchis."""
    b = Builder()
    hl = CB_LEN * 0.5
    step = CB_LEN / float(CB_N - 1)
    for i in range(CB_N):
        y = -hl + i * step
        b.box((sign * CB_X, y, 0.30), (0.20, 0.20, 1.40), TRUNK)

    def row(z_c, bounds, slot_cycle):
        for j, (y0, y1) in enumerate(zip(bounds, bounds[1:])):
            b.box((sign * (CB_X + 0.10 + 0.04), (y0 + y1) * 0.5, z_c),
                  (0.08, (y1 - y0) - 0.04, 0.22), slot_cycle[j % len(slot_cycle)])
    top_b = [-hl - 0.25 + (CB_LEN + 0.5) * i / 7.0 for i in range(8)]
    top_b.append(hl + 0.25)
    top_b = [-hl - 0.25 + (CB_LEN + 0.5) * i / 7.0 for i in range(8)]
    low_b = [-hl - 0.25, -hl + (CB_LEN + 0.5) / 14.0] + \
        [-hl - 0.25 + (CB_LEN + 0.5) * (i + 0.5) / 7.0 for i in range(1, 7)] + \
        [hl + 0.25]
    row(0.80, top_b, (TRUNK, TRUNK, WOOD_SLOT))
    row(0.40, low_b, (TRUNK, WOOD_SLOT, TRUNK))
    name = "Rail_L" if sign < 0 else "Rail_R"
    return b.to_object(name)


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.02, smooth_angle=45.0,
         budget=None, tint=None):
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((0.0, -(min(ys) + max(ys)) * 0.5, 0.0))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, ao=ao, origin=(origin if solo else None),
                    smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        if tint is not None:
            tint_gradient(o, base=tint[0], tip=tint[1])
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "fiordland/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return total_tris


# Fagul: A intai, verificat, apoi B/C. tint usor pe coroana (baza spre umbra
# rece, varf spre culoarea slotului) - vezi tint_gradient in dio_lib.
CROWN_TINT = ((0.56, 0.62, 0.52), (1.04, 1.00, 0.82))

def emit_beech(objs, path, budget=900):
    trunk_obj, crown_obj = objs
    # tint DOAR pe Crown (verde) — Trunk e LOG_DARK, tint_gradient l-ar sari
    # oricum (green_only), dar apelul separat e mai clar decat un tint comun.
    st_t = finish(trunk_obj, bevel=0.0, ao=AO_TREE, origin=None,
                 smooth_angle=45.0)
    st_c = finish(crown_obj, bevel=0.0, ao=AO_TREE, origin=None,
                 smooth_angle=45.0)
    tint_gradient(crown_obj, base=CROWN_TINT[0], tip=CROWN_TINT[1])
    # origine comuna: baza trunchiului e deja la Z=0 (taper_sweep incepe la
    # (0,0,0)), deci NU trebuie offset suplimentar — dar se calculeaza oricum
    # din bbox-ul ambelor, ca la stirling_ledge, in caz ca trunchiul se
    # apleaca sub 0 din bevel/jitter.
    xs, ys, zs = [], [], []
    for o in (trunk_obj, crown_obj):
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0, 0.0, -min(zs)))
    for o in (trunk_obj, crown_obj):
        for v in o.data.vertices:
            v.co += place
    total_tris = st_t["tris"] + st_c["tris"]
    ao_lo = min(st_t["ao_min"], st_c["ao_min"])
    ao_hi = max(st_t["ao_max"], st_c["ao_max"])
    _, sz = export_glb([trunk_obj, crown_obj], "fiordland/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return trunk_obj, crown_obj


beech_a_t, beech_a_c = emit_beech(
    build_beech(BEECH_A_SPEC, 54.0, 155.0, 420.0, (6.0, 5.6, 7.5), 0.36, 6101, 1.0),
    "plants/beech_a.glb", 900)
beech_b_t, beech_b_c = emit_beech(
    build_beech(BEECH_B_SPEC, 36.1, 200.0, 395.0, (8.0, 7.4, 10.6), 0.44, 6201, 1.0),
    "plants/beech_b.glb", 1000)
beech_c_t, beech_c_c = emit_beech(
    build_beech(BEECH_C_SPEC, 28.0, 200.0, 415.0, (11.0, 10.2, 14.3), 0.55, 6301, 1.0),
    "plants/beech_c.glb", 1100)

dead_obj = build_beech_dead()
emit(dead_obj, "plants/beech_dead.glb", AO_TREE, origin="base_axis", bevel=0.0, budget=900)

rata_obj = build_rata_tree()
emit(rata_obj, "plants/rata_tree.glb", AO_TREE, bevel=0.0, budget=400,
     tint=CROWN_TINT)

tussock_obj = build_tussock_clump()
emit(tussock_obj, "plants/tussock_clump.glb", AO_SMALL, bevel=0.0, budget=150)

stump_obj = build_stump()
emit(stump_obj, "props/stump.glb", AO_SMALL, bevel=0.0, budget=150)

driftwood_obj = build_driftwood()
emit(driftwood_obj, "props/driftwood.glb", AO_SMALL, bevel=0.0, budget=150)

rail_l = _bridge_rail(-1)
rail_r = _bridge_rail(1)
emit([rail_l, rail_r], "structures/chasm_bridge_rail.glb", AO_RAIL,
     origin="base_axis", bevel=0.0, budget=600)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL forest: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([beech_a_t, beech_a_c, beech_b_t, beech_b_c, beech_c_t, beech_c_c,
            dead_obj, rata_obj, tussock_obj, stump_obj, driftwood_obj,
            rail_l, rail_r],
           "fiordland_forest.blend")
