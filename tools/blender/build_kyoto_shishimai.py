"""Kyoto (Track18) -- shishimai, dansul leului japonez, hazardul de la POI H (dreapta
finala Yasaka-dori). Brief: docs/track_briefs/kyoto.md §3 (sectiunea shishimai).

  kyoto/props/shishimai.glb
      Head      capul de lemn lacuit rosu: ochi aurii, sprancene negre, nas auriu, coarne,
                dinti albi sus, coama alba; PIVOT = gatul, la (0, NECK_Y, NECK_Z)
      Jaw       falca de jos (rosie, dinti, limba roz, barba neagra); PIVOT = balamaua, la
                (0, JAW_Y, JAW_Z). Codul o muta copil al lui `Head` (reparent, pastreaza
                transformul global), deci urmeaza capul cand el se leagana
      Body_1..3 panza verde cu spirale albe (karakusa), in 3 segmente care se unduiesc;
                PIVOT = marginea din FATA a segmentului, la sol (yaw in jurul lui Y)
      Leg_FL, Leg_FR, Leg_BL, Leg_BR   picioarele celor doi dansatori (pantaloni albi,
                incaltari negre); PIVOT = soldul (rotation.x = pasul)

CONTRACTUL e scris in `scenes/hazards/shishimai_hazard.gd` (daca difera, codul
castiga). Coordonate de model (Godot): originea = centrul dansului LA SOL (cota
soselei); +X = dreapta, +Z = FATA (spre masina care vine, capul), +Y = sus. In Blender
glTF face (x, y, z)_blender -> (x, z, -y)_godot: fata (+Z Godot) = -Y Blender.

  - Lungime totala ~6,9 m (nas la z = +NOSE_Z, coada la ~ -3,9), cap ~2,5 m lat,
    inaltime ~4,3 m (cornul). Lumea e a masinutelor de jucarie: scara exagerata.
  - Nicio scala neaplicata pe radacina (memoria `scala-glb-neaplicata-la-radacina`).
  - Sloturi: fara CAR_* (verify_glb le marcheaza ILEGAL in decor). Zero materiale in
    plus: un singur atlas, ca toate piesele lumii.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_shishimai.py
"""

import math
import bmesh
from mathutils import Vector, Matrix

# --- Sloturi -------------------------------------------------------------
LACQUER = KERB_RED          # 7   capul (CAR_RED 14 e rezervat masinilor)
GOLD = SAND_LIGHT           # 0   ochi, nas, coarne, urechi
INK = LOG_DARK              # 28  sprancene, pupile, nari, gura, barba, incaltari
WHITE = FOAM_WHITE          # 22  dinti, coama, spirale, pantaloni
CLOTH = TROPICAL_GREEN      # 21  panza
TONGUE = FLAMINGO_PINK      # 31  limba

# --- Cote (Godot-ish: x dreapta, y sus, z fata) ----------------------------
NECK_Y, NECK_Z = 2.10, 1.45           # pivotul capului
JAW_Y, JAW_Z = 2.15, 1.70             # balamaua falcii
HEM_Y = 0.90                          # tiv panza = varful picioarelor vizibile
HIP_Y = 0.95
LEG_X = 0.55
LEG_FZ, LEG_BZ = 0.85, -2.25          # picioarele dansatorilor
# (z_fata, z_spate, semilatime jos, semilatime sus, cota sus) la capete de segment
BODY = {
    1: [(1.55, 1.10, 0.70, 2.30), (0.70, 1.25, 0.85, 2.40), (-0.50, 1.25, 0.88, 2.25)],
    2: [(-0.40, 1.25, 0.88, 2.25), (-1.45, 1.25, 0.88, 2.10), (-2.45, 1.18, 0.82, 2.00)],
    3: [(-2.35, 1.18, 0.82, 2.00), (-3.10, 1.08, 0.74, 1.90), (-3.60, 0.92, 0.55, 1.78)],
}


def G(x, y, z):
    """Godot-ish (x dreapta, y sus, z fata) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def gbox(b, c, size, slot):
    """Cutie in coordonate Godot-ish (size = lat, inalt, adanc)."""
    b.box(G(*c), (size[0], size[2], size[1]), slot)


def gbeam(b, p1, p2, thick, slot):
    b.beam(G(*p1), G(*p2), thick, slot)


def gcyl(b, c, radius, depth, slot, axis="Z", seg=10):
    """axis in coordonate Godot: 'Z' fata (=Y Blender), 'Y' sus, 'X'."""
    ax = {"Z": "Y", "Y": "Z", "X": "X"}[axis]
    b.cylinder(G(*c), radius, depth, slot, segments=seg, axis=ax)


def loft(b, stations, slot):
    """Loft inchis intre sectiuni poligonale (aceleasi N puncte): stations =
    [(z, [(x, y)...]), ...] in Godot-ish. Capace la capete."""
    rings = []
    for z, poly in stations:
        rings.append([b.bm.verts.new(G(x, y, z)) for x, y in poly])
    n = len(rings[0])
    for lo, hi in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    b.bm.faces.new(tuple(rings[0]))
    b.bm.faces.new(tuple(reversed(rings[-1])))
    b._tag([v for r in rings for v in r], slot)


def section(wb, wt, top):
    """Sectiune de panza: trapez cu coltul de sus rotunjit, tivul la HEM_Y."""
    h = top - HEM_Y
    return [(-wb, HEM_Y), (-wb - 0.04, HEM_Y + 0.35 * h), (-wt - 0.10, HEM_Y + 0.82 * h),
            (-wt, top), (wt, top), (wt + 0.10, HEM_Y + 0.82 * h),
            (wb + 0.04, HEM_Y + 0.35 * h), (wb, HEM_Y)]


def flank_x(stations, z, y):
    """Semilatimea REALA a panzei la (z, y): sectiunea se interpoleaza intre statii
    (z descrescator), apoi se citeste latura dreapta a poligonului din `section`."""
    a, c, t = stations[0], stations[0], 0.0
    for lo, hi in zip(stations, stations[1:]):
        a, c = lo, hi
        if hi[0] <= z <= lo[0]:
            t = (lo[0] - z) / (lo[0] - hi[0])
            break
        t = 1.0 if z < hi[0] else 0.0
    wb = a[1] + (c[1] - a[1]) * t
    wt = a[2] + (c[2] - a[2]) * t
    top = a[3] + (c[3] - a[3]) * t
    poly = section(wb, wt, top)
    side = [poly[7], poly[6], poly[5], poly[4]]          # dreapta, de jos in sus
    for (x0, y0), (x1, y1) in zip(side, side[1:]):
        if y0 <= y <= y1:
            return x0 + (x1 - x0) * (y - y0) / max(y1 - y0, 1e-6)
    return side[-1][0] if y > side[-1][1] else side[0][0]


def spiral(b, center_zy, radius, side, turns, stations, flip):
    """Spirala karakusa pe flancul panzei (side = +-1): grinzi scurte albe, lipite de
    panza (un `taper_sweep` plan in x = const degenereaza in panglica lata)."""
    zc, yc = center_zy
    pts = []
    n = 10
    for k in range(n + 1):
        t = k / n
        a = turns * 2.0 * math.pi * t * flip
        r = radius * (0.12 + 0.88 * t)
        z = zc + r * math.cos(a)
        y = yc + r * math.sin(a)
        pts.append(G(side * (flank_x(stations, z, y) + 0.03), y, z))
    for p1, p2 in zip(pts, pts[1:]):
        b.beam(p1, p2, (0.14, 0.09), WHITE, up=(side, 0.0, 0.0))


def spiral_top(b, zc, radius, turns, top, flip):
    pts = []
    n = 16
    for k in range(n + 1):
        t = k / n
        a = turns * 2.0 * math.pi * t * flip
        r = radius * (0.12 + 0.88 * t)
        pts.append(G(r * math.cos(a), top + 0.035, zc + r * math.sin(a)))
    b.taper_sweep(pts, 0.058, WHITE, segments=4, cap_start=True, cap_end=True)


def build_body(idx):
    st = BODY[idx]
    b = Builder()
    loft(b, [(z, section(wb, wt, top)) for z, wb, wt, top in st], CLOTH)
    # tivul rosu pe cele doua laturi de jos
    for sx in (-1.0, 1.0):
        for a, c in zip(st, st[1:]):
            gbeam(b, (sx * (a[1] + 0.02), HEM_Y + 0.05, a[0]),
                  (sx * (c[1] + 0.02), HEM_Y + 0.05, c[0]), (0.10, 0.16), LACQUER)
    # spirale: doua pe fiecare flanc, una pe spate; alternam mana
    z0, z2 = st[0][0], st[-1][0]
    for sx in (-1.0, 1.0):
        for k, f in enumerate((0.28, 0.72)):
            zc = z0 + (z2 - z0) * f
            sec = st[0] if f < 0.5 else st[1]
            yc = HEM_Y + 0.55 * (sec[3] - HEM_Y)
            spiral(b, (zc, yc), 0.40, sx, 1.7, st, flip=sx * (1.0 if k == 0 else -1.0))
    spiral_top(b, z0 + (z2 - z0) * 0.5, 0.42, 1.6, st[1][3], flip=1.0 if idx % 2 else -1.0)
    if idx == 3:
        # coada: un sul de panza (verde) care urca in curba, cu varful alb
        path = [G(0, 1.75, -3.45), G(0, 2.05, -3.80), G(0, 2.60, -3.95), G(0, 3.20, -3.75),
                G(0, 3.60, -3.40)]
        b.taper_sweep(path, [0.34, 0.30, 0.25, 0.19, 0.0], CLOTH, segments=7)
        gcyl(b, (0.0, 3.20, -3.75), 0.2, 0.2, WHITE, axis="X", seg=7)
    return b


def build_leg(sx, z):
    b = Builder()
    gbox(b, (sx * LEG_X, (HIP_Y + 0.12) * 0.5 + 0.02, z), (0.48, HIP_Y - 0.12, 0.52), WHITE)
    gbox(b, (sx * LEG_X, 0.09, z + 0.14), (0.52, 0.20, 0.92), INK)
    return b


def tuft(b, base, tip, slot, thick=0.26):
    """Smoc conic (baza groasa, varf ascutit) -- coama, nu scandura."""
    p0, p1 = Vector(base), Vector(tip)
    mid = (p0 + p1) * 0.5 + Vector((0.0, -0.10, 0.0))
    b.taper_sweep([G(*p0), G(*mid), G(*p1)], [thick * 0.62, thick * 0.48, 0.0], slot,
                  segments=5, cap_start=True, cap_end=True)


def build_head():
    b = Builder()
    ZF = NECK_Z + 1.65     # fata craniului
    # craniul: bloc mare, cu muchii rotunjite (bevel la finish)
    gbox(b, (0.0, NECK_Y + 0.98, NECK_Z + 0.84), (2.56, 1.72, 1.64 * 1.0 + 0.02), LACQUER)
    # urechi si coarne aurii
    for sx in (-1.0, 1.0):
        gcyl(b, (sx * 1.34, NECK_Y + 1.66, NECK_Z + 0.55), 0.42, 0.26, GOLD, axis="X", seg=10)
        gcyl(b, (sx * 1.34, NECK_Y + 1.66, NECK_Z + 0.55), 0.24, 0.34, LACQUER, axis="X", seg=8)
    b.frustum(G(0.0, NECK_Y + 2.28, NECK_Z + 0.95), 0.30, 0.06, 0.78, GOLD, segments=8)
    # ochi: disc auriu mare + pupila neagra
    for sx in (-1.0, 1.0):
        gcyl(b, (sx * 0.66, NECK_Y + 1.28, ZF + 0.03), 0.43, 0.30, GOLD, axis="Z", seg=12)
        gcyl(b, (sx * 0.66, NECK_Y + 1.28, ZF + 0.20), 0.18, 0.14, INK, axis="Z", seg=10)
        # sprancene groase, oblice (privire aprinsa): exteriorul sus
        gbeam(b, (sx * 1.18, NECK_Y + 1.92, ZF - 0.02), (sx * 0.22, NECK_Y + 1.66, ZF - 0.02),
              (0.26, 0.20), INK)
    # nas auriu: punte ingusta intre ochi care se lateste spre nari
    gbox(b, (0.0, NECK_Y + 0.98, ZF + 0.08), (0.52, 0.80, 0.34), GOLD)
    gbox(b, (0.0, NECK_Y + 0.66, ZF + 0.12), (0.86, 0.36, 0.42), GOLD)
    for sx in (-1.0, 1.0):
        gbox(b, (sx * 0.22, NECK_Y + 0.66, ZF + 0.34), (0.20, 0.18, 0.10), INK)
    # dintii de sus
    for k in range(6):
        x = -0.95 + k * 0.38
        gbox(b, (x, NECK_Y + 0.02, ZF - 0.05), (0.30, 0.50, 0.22), WHITE)
    # interiorul gurii: perete negru in spate + tavan
    gbox(b, (0.0, NECK_Y + 0.10, NECK_Z + 0.34), (2.20, 0.80, 0.10), INK)
    gbox(b, (0.0, NECK_Y - 0.04, NECK_Z + 1.05), (2.20, 0.06, 1.50), INK)
    # coama alba: smocuri pe crestet si pe laturi, in evantai spre spate
    for k in range(5):
        x = -1.0 + k * 0.5
        tuft(b, (x, NECK_Y + 1.80, NECK_Z + 0.35), (x * 1.25, NECK_Y + 2.15, NECK_Z - 0.55), WHITE)
    for sx in (-1.0, 1.0):
        for k in range(3):
            y = NECK_Y + 1.35 - k * 0.5
            tuft(b, (sx * 1.20, y, NECK_Z + 0.30),
                 (sx * 1.95, y - 0.25 - 0.1 * k, NECK_Z - 0.35 - 0.1 * k), WHITE, 0.30)
    return b


def build_jaw():
    b = Builder()
    ZF = NECK_Z + 1.65
    gbox(b, (0.0, JAW_Y - 0.36, JAW_Z + 0.82), (2.20, 0.46, 1.64), LACQUER)
    # limba roz
    gbox(b, (0.0, JAW_Y - 0.08, JAW_Z + 0.75), (1.20, 0.08, 1.20), TONGUE)
    # dintii de jos
    for x in (-0.75, -0.25, 0.25, 0.75):
        gbox(b, (x, JAW_Y + 0.0, ZF - 0.18), (0.30, 0.34, 0.20), WHITE)
    # barba neagra
    for k in range(6):
        x = -0.95 + k * 0.38
        tuft(b, (x, JAW_Y - 0.55, ZF - 0.12), (x * 1.08, JAW_Y - 1.35 - 0.08 * (k % 2), ZF + 0.05),
             INK, 0.24)
    return b


clear_built()
legs = {}
for name, sx, z in (("Leg_FL", -1.0, LEG_FZ), ("Leg_FR", 1.0, LEG_FZ),
                    ("Leg_BL", -1.0, LEG_BZ), ("Leg_BR", 1.0, LEG_BZ)):
    legs[name] = build_leg(sx, z).to_object(name)
head = build_head().to_object("Head")
jaw = build_jaw().to_object("Jaw")
bodies = {i: build_body(i).to_object("Body_%d" % i) for i in (1, 2, 3)}

TOP = 4.6


def _ao(low=0.62, dist=1.4):
    return dict(samples=24, dist=dist, gradient="vertical", low=low, high=1.0,
                power=0.9, floor=0.30, z_range=(-0.05, TOP))


stats = {}
for name, o in legs.items():
    stats[name] = finish(o, bevel=0.04, ao=_ao(0.55, 0.9), origin=None, smooth_angle=None)
stats["Head"] = finish(head, bevel=0.10, bevel_segments=1, ao=_ao(0.7, 1.6), origin=None,
                       smooth_angle=45.0)
stats["Jaw"] = finish(jaw, bevel=0.08, bevel_segments=1, ao=_ao(0.7, 1.2), origin=None,
                      smooth_angle=45.0)
for i, o in bodies.items():
    stats["Body_%d" % i] = finish(o, bevel=0.05, ao=_ao(0.58, 1.4), origin=None,
                                  smooth_angle=50.0)

# Pivoturile (finish cu origin=None lasa geometria in coordonate absolute).
for name, sx, z in (("Leg_FL", -1.0, LEG_FZ), ("Leg_FR", 1.0, LEG_FZ),
                    ("Leg_BL", -1.0, LEG_BZ), ("Leg_BR", 1.0, LEG_BZ)):
    set_origin_at(legs[name], G(sx * LEG_X, HIP_Y, z))
set_origin_at(head, G(0.0, NECK_Y, NECK_Z))
set_origin_at(jaw, G(0.0, JAW_Y, JAW_Z))
for i, o in bodies.items():
    set_origin_at(o, G(0.0, 0.0, BODY[i][0][0]))
for o in list(legs.values()) + [head, jaw] + list(bodies.values()):
    o.rotation_euler = (0.0, 0.0, 0.0)

objs = list(legs.values()) + [head, jaw] + [bodies[i] for i in (1, 2, 3)]
path, size = export_glb(objs, "kyoto/props/shishimai.glb")
save_blend(objs, "kyoto_shishimai.blend")
print("== shishimai ==", path, "%.1f KB" % (size / 1024.0))
for k, v in stats.items():
    print("  %-8s tris=%d ao=[%.2f..%.2f]" % (k, v["tris"], v["ao_min"], v["ao_max"]))
print("  total tris:", sum(v["tris"] for v in stats.values()))
