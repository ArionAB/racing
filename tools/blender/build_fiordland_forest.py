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


def _branches(bt, clumps, tpts, r_mid, r_factor=0.5, split_lo=0.28, seg=5):
    """Ramuri groase de la trunchi la fiecare masa de coroana care nu e deja
    deasupra liderului. Pornesc DE-A LUNGUL trunchiului, urca in arc."""
    top_z = tpts[-1].z
    for (c, wx, wy, hz) in clumps:
        horiz = math.hypot(c.x, c.y)
        if horiz < 0.3 and c.z > top_z * 0.75:
            continue
        z_a = c.z - 1.2 * horiz - 0.5
        z_a = max(z_a, split_lo * top_z)
        if z_a > c.z - 0.25:
            z_a = c.z * 0.6
        p0 = _trunk_at(tpts, z_a)
        tgt = Vector((c.x, c.y, c.z - 0.18 * hz))
        if (tgt - p0).length < 0.35:
            continue
        mid = p0.lerp(tgt, 0.5)
        mid.z = p0.z + (tgt.z - p0.z) * 0.62
        r0 = r_mid * r_factor
        bt.taper_sweep([p0, mid, tgt], [r0, r0 * 0.62, r0 * 0.22], TRUNK,
                       segments=seg)


def _clump_records(spec, ppm, axis_x, base_y, k, dspan):
    kx, ky, kz = k
    out = []
    for (px, py, w, h, df) in spec:
        out.append((Vector(((px - axis_x) / ppm * kx, df * dspan * ky,
                            (base_y - py) / ppm * kz)),
                    w / ppm * (0.55 + 0.45 * kx) * 1.15,
                    w / ppm * (0.55 + 0.45 * ky) * 0.95 * 1.15,
                    h / ppm * kz * 1.05))
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
        clumps = _clump_records(spec, ppm, axis_x, base_y, k, dspan)
        bc = Builder()
        allf = set()
        for i, (c, wx, wy, hz) in enumerate(clumps):
            allf |= bc.boulder((c.x, c.y, c.z), (wx, wy, hz), CROWN,
                               seed=seed + i * 13, segments=8, rings=2,
                               deviation=0.20)
            br = _lcg(seed + i * 7)
            for j in range(2):
                ph = 2.0 * math.pi * (j * 0.5 + br() * 0.4)
                allf |= bc.boulder(
                    (c.x + math.cos(ph) * wx * 0.34, c.y + math.sin(ph) * wy * 0.34,
                     c.z + hz * (0.10 + br() * 0.12)),
                    (wx * 0.46, wy * 0.46, hz * 0.72), CROWN,
                    seed=seed + i * 31 + j, segments=5, rings=2, deviation=0.22)
        bc.retag(allf, TRUNK, where="down")
        bc.retag(allf, CROWN, where="up")
        top = max(clumps, key=lambda q: q[0].z)
        top_z = top[0].z - top[3] * 0.30
        bt = Builder()
        tpts = _make_trunk(bt, top_z, r_mid, (top[0].x * 0.55, top[0].y * 0.55), flare=1.7)
        _roots(bt, r_mid, 4, seed + 7)
        _branches(bt, clumps, tpts, r_mid, r_factor=0.64, split_lo=0.30)
        return [bt, bc]

    (bt, bc), k = _fit(assemble, target, (0.7, 0.7, 1.0))
    print("beech fit k=%.3f %.3f %.3f" % tuple(k))
    return bt.to_object("Trunk"), bc.to_object("Crown")


# --- beech_dead ----------------------------------------------------------------

def build_beech_dead():
    """Fag uscat: trunchi gros rupt la varf, evazare + radacini, 5 crengi
    principale care se ramifica din nou, toate conice (planșa: 2 spre stanga
    sus, 1 lunga dreapta-jos, 1 dreapta-sus, 1 tepusa pe varf)."""
    ppm, ax, by = 39.0, 150.0, 350.0
    TARGET = (2.9, 3.3, 8.5)

    def P(px, py, s, u, kx, ky, dsp=0.9):
        return Vector(((px - ax) / ppm * kx, s * dsp * u * ky, (by - py) / ppm))

    # (puncte px, raza start, semn adancime, raza forcii)
    BR = [
        ([(142, 238), (112, 192), (80, 122), (58, 92)], 0.34, -1),
        ([(88, 135), (84, 99)], 0.10, -1),
        ([(100, 172), (42, 152)], 0.16, 1),
        ([(163, 202), (205, 186), (268, 158)], 0.32, 1),
        ([(238, 171), (280, 166)], 0.10, -1),
        ([(252, 166), (238, 148)], 0.08, 1),
        ([(170, 112), (202, 76), (238, 22)], 0.30, -1),
        ([(212, 56), (190, 28)], 0.09, 1),
        ([(152, 104), (143, 52), (135, 18)], 0.20, 1),
    ]

    def assemble(k):
        kx, ky, kz = k
        b = Builder()
        # trunchi: evazare + subtiere, varf rupt (taiat inclinat)
        px_pts = [(150, 350), (149, 322), (150, 270), (155, 190), (161, 120),
                  (166, 52)]
        pts = [P(x, y, 1, 0, kx, ky) for x, y in px_pts]
        # mica deriva pe adancime ca trunchiul sa nu fie un stalp
        for i, p in enumerate(pts):
            p.y += 0.12 * ky * math.sin(i * 1.3)
        pts[-1].x += 0.06
        rad = [0.95, 0.58, 0.46, 0.38, 0.32, 0.27]
        b.taper_sweep(pts, rad, TRUNK, segments=6)
        _roots(b, 0.58, 5, 5207, seg=4)
        for (pp, r0, s) in BR:
            n = len(pp)
            path = []
            for i, (x, y) in enumerate(pp):
                u = i / float(n - 1)
                v = P(x, y, s, u, kx, ky)
                path.append(v)
            ax_pt = _trunk_at(pts, path[0].z)
            path.insert(0, ax_pt)
            # radacina ramurii intra in trunchi
            radii = [r0 * 1.25] + [r0 * (1.0 - 0.6 * (i / float(n - 1))) for i in range(n)]
            n += 1
            radii[-1] = max(radii[-1] * 0.35, 0.03)
            b.taper_sweep(path, radii, TRUNK, segments=6)
        return [b]

    (b,), k = _fit(assemble, TARGET, (0.5, 0.5, 1.0))
    print("beech_dead fit k=%.3f %.3f %.3f" % tuple(k))
    # mușchi: petice mici la baza trunchiului (nodul ia bark_beech oricum)
    b.retag(set(f for f in b.bm.faces if f.is_valid), MOSS,
            where=lambda c, n: (c.z < 1.1) and (n.x > 0.55 or n.y > 0.55)
            and abs(n.z) < 0.5 and (int(c.x * 7 + c.y * 5) % 3 == 0))
    return b.to_object("Beech_Dead")


# --- rata_tree -----------------------------------------------------------------

RATA_SPEC = [
    (178, 40, 70, 38, 0.0),        # varf
    (246, 86, 90, 52, 0.55),       # dreapta-sus, cea mai mare masa
    (108, 100, 72, 48, -0.6),      # stanga-sus
    (158, 108, 56, 42, 0.0),       # mijloc, in spate
    (282, 148, 52, 42, -0.4),      # dreapta-mijloc
    (150, 128, 80, 40, 0.8),       # mijloc-fata
    (232, 118, 60, 40, -0.5),      # umplutura dreapta
    (128, 164, 78, 46, -0.5),      # stanga-jos, intunecata
    (214, 164, 54, 36, 0.6),       # dreapta-jos
]


def build_rata_tree():
    """Rata in floare: copacel cu trunchi VIZIBIL care se ramifica, coroana in
    8 smocuri separate, fiecare stropit cu 6 ciorchini rosii mici (varfuri
    pe suprafata, nu fete mari). Frunzis 21 + 28, flori 7 (§0.1.3)."""
    ppm, ax, by = 58.7, 190.0, 285.0
    TARGET = (4.3, 4.2, 4.6)
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
        # ciorchini: octaedre mici pe fata de sus/laterala a fiecarei mase
        for i, (c, wx, wy, hz) in enumerate(clumps):
            n_cl = 6
            for j in range(n_cl):
                th = math.radians(8.0 + rand() * 62.0)
                ph = 2.0 * math.pi * (j + rand() * 0.6) / n_cl
                p = Vector((c.x + math.sin(th) * math.cos(ph) * wx * 0.5,
                            c.y + math.sin(th) * math.sin(ph) * wy * 0.5,
                            c.z + math.cos(th) * hz * 0.5))
                s = 0.28 + rand() * 0.12
                bcr.boulder((p.x, p.y, p.z), (s, s, s * 0.8), FLOWER,
                            seed=5600 + i * 17 + j, segments=4, rings=1,
                            deviation=0.1)
        top = max(clumps, key=lambda q: q[0].z)
        top_z = top[0].z - top[3] * 0.25
        tr = Builder()
        r_mid = 0.20
        tpts = _make_trunk(tr, top_z, r_mid, (top[0].x * 0.3, top[0].y * 0.3),
                           seg=5, flare=1.5)
        _roots(tr, r_mid, 3, 5303, seg=3)
        _branches(tr, clumps, tpts, r_mid, r_factor=0.55, split_lo=0.30, seg=4)
        _branches(tr, [(c + Vector((wx * 0.2, -wy * 0.2, -hz * 0.1)), wx, wy, hz) for (c, wx, wy, hz) in clumps], tpts, r_mid, r_factor=0.38, split_lo=0.42, seg=4)
        # trunchiul se uneste cu coroana intr-un singur obiect
        bmesh_ops_join(bcr, tr)
        return [bcr]

    (b,), k = _fit(assemble, TARGET, (0.7, 0.7, 1.0))
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
    """Doua smocuri lipite, fiecare o FANTANA deasa de lame curbate in afara:
    lamele centrale inalte, cele marginale lungi si aplecate (arc), varfuri
    galben-oliv. Lama = 3 statii, 20 tri."""
    b = Builder()
    rand = _lcg(5501)
    for (cx, cy, n) in [(-0.12, 0.03, 17), (0.13, -0.04, 17)]:
        for i in range(n):
            a = 2.0 * math.pi * i / n + rand() * 0.4
            d = Vector((math.cos(a), math.sin(a), 0.0))
            rn = (i * 7 % n) / float(n - 1)       # 0 centrala .. 1 marginala
            reach = 0.10 + 0.32 * rn + rand() * 0.05
            h = 0.82 - 0.34 * rn - rand() * 0.06
            base = Vector((cx, cy, 0.0)) + d * (0.05 + 0.04 * rn)
            c = Vector((cx, cy, 0.0))
            path = [base,
                    c + d * (reach * 0.42) + Vector((0, 0, h * 0.92)),
                    c + d * reach + Vector((0, 0, h * (0.70 - 0.25 * rn)))]
            w = 0.030 + rand() * 0.010
            b.blade(path, [0.03, w, 0.0], 0.010, MOSS, up=d)
    zs = [v.co.z for v in b.bm.verts]
    z_hi = max(zs)
    b.retag(set(f for f in b.bm.faces if f.is_valid), DRY_VEGETATION,
            where=lambda c, n: c.z > z_hi * 0.62)
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
    """Ciot evazat: corp care se largeste spre sol, 7 radacini late care se
    contopesc cu el si se intind pe sol, taietura plana cu inel, mușchi."""
    b = Builder()
    rand = _lcg(5601)
    pts = [Vector((0, 0, 0)), Vector((0.01, 0, 0.18)), Vector((0, 0.01, 0.5)),
           Vector((0.03, 0, 0.78))]
    b.taper_sweep(pts, [0.56, 0.41, 0.34, 0.32], TRUNK, segments=8)
    n = 7
    for k in range(n):
        a = 2.0 * math.pi * k / n + rand() * 0.45
        d = Vector((math.cos(a), math.sin(a), 0.0))
        L = 0.66 + rand() * 0.16
        b.taper_sweep([d * 0.20 + Vector((0, 0, 0.50)),
                       d * (L * 0.45) + Vector((0, 0, 0.16)),
                       d * L + Vector((0, 0, 0.04))],
                      [0.20, 0.17, 0.07], TRUNK, segments=5)
    b.retag(set(f for f in b.bm.faces if f.is_valid), MOSS,
            where=lambda c, nn: nn.z > 0.30 and c.z < 0.22
            and math.hypot(c.x, c.y) > 0.38)
    top_z = 0.78
    b.retag(set(f for f in b.bm.faces if f.is_valid), SAND_LIGHT,
            where=lambda c, nn: nn.z > 0.9 and c.z > top_z - 0.02)
    b.frustum((0.03, 0.0, top_z + 0.006), 0.15, 0.15, 0.012, SAND_SHADOW,
              segments=8)
    for k in range(3):
        a = 2.0 * math.pi * (k + 0.3 * rand()) / 3 + 0.5
        b.rock((math.cos(a) * 0.55, math.sin(a) * 0.55, -0.01),
               (0.26, 0.20, 0.05), MOSS, seed=5650 + k, segments=5, rings=1,
               taper=0.3)
    _rescale(b, (1.1, 0.8, 1.0))
    return b.to_object("Stump")


# --- driftwood -----------------------------------------------------------------

def build_driftwood():
    """Buștean gros culcat, capatul rupt zdrentuit (3 aschii + capac intunecat),
    4 crengi groase care se ridica din el (una cu furca), 2 cazute pe sol."""
    b = Builder()
    pts = [Vector((0.0, 0.0, 0.20)), Vector((1.3, 0.05, 0.19)),
           Vector((2.6, 0.0, 0.22)), Vector((3.85, -0.04, 0.27))]
    b.taper_sweep(pts, [0.25, 0.23, 0.19, 0.12], WOOD_SLOT, segments=6)
    # capatul rupt: aschii care ies in afara
    for k, (yy, zz) in enumerate(((0.10, 0.30), (-0.12, 0.20), (0.02, 0.07))):
        b.taper_sweep([Vector((0.10, yy, zz)), Vector((-0.20, yy * 1.3, zz + 0.08))],
                      [0.07, 0.0], WOOD_SLOT, segments=3)
    # capac intunecat (interiorul scorburos)
    b.retag(set(f for f in b.bm.faces if f.is_valid), LOG_DARK,
            where=lambda c, n: n.x < -0.8 and c.x < 0.02)

    def limb(path, radii, seg=4):
        b.taper_sweep([Vector(p) for p in path], radii, WOOD_SLOT, segments=seg)

    # ridicate: pleaca in unghi ascutit, ca pe planșa (inainte, in sus)
    limb([(1.35, 0.00, 0.34), (1.95, 0.08, 0.70), (2.55, 0.14, 1.10)],
         [0.15, 0.11, 0.04], 6)
    limb([(2.15, 0.00, 0.36), (2.65, -0.12, 0.72), (3.25, -0.20, 1.05)],
         [0.15, 0.11, 0.04], 6)
    limb([(2.85, 0.02, 0.34), (3.35, 0.10, 0.62), (3.85, 0.12, 0.95)],
         [0.15, 0.11, 0.04], 6)
    limb([(3.30, 0.10, 0.64), (3.65, 0.24, 0.62), (3.98, 0.26, 0.78)],
         [0.07, 0.05, 0.025])
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
CB_X = 5.76
CB_STEP = 2.5


def _bridge_rail(sign):
    b = Builder()
    hl = CB_LEN * 0.5
    n_posts = int(round(CB_LEN / CB_STEP)) + 1
    for i in range(n_posts):
        y = -hl + i * CB_STEP
        b.box((sign * CB_X, y, 0.30), (0.30, 0.30, 1.40), WOOD_SLOT)
    # scanduri: exterior; randul de sus mai subtire, cel de jos mai inalt
    def row(z_c, h, th, bounds, x_off):
        for y0, y1 in zip(bounds, bounds[1:]):
            b.box((sign * (CB_X + x_off), (y0 + y1) * 0.5, z_c),
                  (th, (y1 - y0) - 0.04, h), WOOD_SLOT)
    top_b = [-hl - 0.25 + 5.0 * i for i in range(0, 9)]
    top_b[-1] = hl + 0.25
    top_b[0] = -hl - 0.25
    low_b = [-hl - 0.25, -hl + 2.5] + [-hl + 2.5 + 5.0 * i for i in range(1, 8)] \
        + [hl + 0.25]
    row(0.80, 0.19, 0.09, top_b, 0.15 + 0.045)
    row(0.40, 0.30, 0.13, low_b, 0.15 + 0.065)
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
    place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
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
    build_beech(BEECH_A_SPEC, 54.0, 155.0, 420.0, (3.7, 4.1, 7.5), 0.36, 6101, 1.0),
    "plants/beech_a.glb", 900)
beech_b_t, beech_b_c = emit_beech(
    build_beech(BEECH_B_SPEC, 36.1, 200.0, 395.0, (4.7, 5.0, 10.6), 0.44, 6201, 1.0),
    "plants/beech_b.glb", 1000)
beech_c_t, beech_c_c = emit_beech(
    build_beech(BEECH_C_SPEC, 28.0, 200.0, 415.0, (7.5, 7.2, 14.3), 0.55, 6301, 1.0),
    "plants/beech_c.glb", 1100)

dead_obj = build_beech_dead()
emit(dead_obj, "plants/beech_dead.glb", AO_TREE, bevel=0.0, budget=250)

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
