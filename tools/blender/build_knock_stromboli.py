"""knock_stromboli.glb — recuzita LOVIBILA pentru insula vulcanica de pescari
din Mediterana (Stromboli).

Piese (noduri radacina frati, toate exportate in (0,0,0), originea la baza):
  FishingBuoy  SPHERE  Ø0.46                geamandura rosu-portocaliu cu banda
                       alba; ochiul de funie iese sub 3 cm deasupra
  LemonCrate   BOX     0.60 x 0.34 x 0.40   lada de sipci, plina varf cu lamai
  Amphora      CYL     Ø0.40 x H0.68        amfora de teracota cu talpa plata;
                       toartele mici stau in raza burtii

Sloturi in paleta lumii Stromboli: KERB_RED 7 (stalpii chevron), FOAM_WHITE 22
(var), WOOD 9, LOG_DARK 28, TILE_TERRACOTTA 23 (vasele), VOLCANIC_BLACK 20,
DRY_VEGETATION 13 (funie), SAND_LIGHT 0 (cel mai galben slot legal = lamaile;
CAR_YELLOW 16 e al masinilor), TROPICAL_GREEN 21 (frunze). LAVA_ORANGE 30 NU se
foloseste aici: pe Stromboli e semnalul lavei.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_stromboli.py
"""

import math
import bpy
from mathutils import Vector, Matrix

GLB_PATH = "stromboli/props/knock_stromboli.glb"


# --- ajutoare comune kiturilor knock (copiate per script, nu importate) -------

def latlong(b, center, rx, rz, lons_deg, lats_deg, slot_of, lift=None):
    """Sfera din meridiane si paralele DATE EXPLICIT (unghiuri in grade).

    Spre deosebire de o sfera uniforma, permite meridiane apropiate (o funie, o
    banda) fara sa platesti rezolutie pe toata sfera. `slot_of(i, k)` da slotul
    fetei din coloana i (intre meridianele i si i+1) si banda k (0 = calota de
    jos, len(lats) = calota de sus). `lift(i, k)` ridica varful (meridian i,
    paralela k) cu atatia metri — benzi in relief."""
    cx, cy, cz = center
    lons = [math.radians(a) for a in lons_deg]
    lats = [math.radians(a) for a in lats_deg]
    n = len(lons)
    rings = []
    for k, la in enumerate(lats):
        ring = []
        for i, lo in enumerate(lons):
            d = lift(i, k) if lift else 0.0
            r = (rx + d) * math.cos(la)
            ring.append(b.bm.verts.new((cx + r * math.cos(lo), cy + r * math.sin(lo),
                                        cz + (rz + d) * math.sin(la))))
        rings.append(ring)
    bot = b.bm.verts.new((cx, cy, cz - rz))
    top = b.bm.verts.new((cx, cy, cz + rz))
    faces = set()
    for k in range(len(lats) - 1):
        for i in range(n):
            j = (i + 1) % n
            f = b.bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
            f[b.slot] = slot_of(i, k + 1)
            faces.add(f)
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((rings[0][j], rings[0][i], bot))
        f[b.slot] = slot_of(i, 0)
        faces.add(f)
        f = b.bm.faces.new((rings[-1][i], rings[-1][j], top))
        f[b.slot] = slot_of(i, len(lats))
        faces.add(f)
    return faces


def angle_of(c):
    return math.degrees(math.atan2(c.y, c.x)) % 360.0


def assemble(name, parts, dims, ao):
    """parts = [(Builder, bevel, bevel_angle, smooth_angle)] -> un singur obiect.

    Fiecare parte trece prin `finish` (bevel -> UV pe sloturi) cu reglajele ei,
    fara mutare de origine; apoi se unesc, se aduc pe `dims` (X, Y, Z Blender;
    None = axa lasata cum e), originea se pune la baza, centrata, si AO-ul se
    coace pe ansamblu."""
    objs = []
    for idx, (b, bev, ang, sm) in enumerate(parts):
        o = b.to_object("%s__p%d" % (name, idx))
        finish(o, bevel=bev, bevel_angle=ang, origin="keep", smooth_angle=sm,
               ao=dict(samples=2, dist=0.05))
        objs.append(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = objs[0]
    obj.name = name
    obj.data.name = name
    me = obj.data
    for a, target in enumerate(dims):
        if not target:
            continue
        vals = [v.co[a] for v in me.vertices]
        lo, hi = min(vals), max(vals)
        s = target / (hi - lo)
        mid = (lo + hi) * 0.5 if a < 2 else lo
        for v in me.vertices:
            v.co[a] = mid + (v.co[a] - mid) * s
    me.update()
    set_origin_base(obj, center_xy=True)
    bake_ao(obj, **ao)
    return obj


def report(obj):
    me = obj.data
    ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
           for a in range(3)]
    w, d, h = (ext[a][1] - ext[a][0] for a in range(3))
    uv = me.uv_layers.active.data
    slots = sorted({int(uv[p.loop_indices[0]].uv[0] * SLOTS) for p in me.polygons})
    print("PIECE %-12s %4d tris | W x H x D = %.3f x %.3f x %.3f | slots %s"
          % (obj.name, tri_count(obj), w, h, d, slots))
    return tri_count(obj)



# --- piesele -----------------------------------------------------------------

def fishing_buoy():
    """Sfera usor turtita (Ø0.46 x 0.43) cu banda alba putin peste ecuator si
    un ochi de funie pe crestet: tor vertical pe jumatate ingropat, iese 2.6 cm
    (contract: max 3 cm), deci inaltimea totala ramane ~0.46."""
    b = Builder()
    lats = (-66, -40, -16, 6, 24, 46, 68)

    def slot_of(i, k):
        return FOAM_WHITE if k == 4 else KERB_RED

    latlong(b, (0.0, 0.0, 0.215), 0.23, 0.215, [i * (360.0 / 14) for i in range(14)],
            lats, slot_of)
    eye = Builder()
    eye.torus((0.0, 0.0, 0.430), 0.018, 0.008, DRY_VEGETATION,
              major_seg=8, minor_seg=4, axis="Y")
    return assemble("FishingBuoy", [(b, 0.0, 60.0, 55.0), (eye, 0.0, 60.0, 60.0)],
                    (0.46, 0.46, None),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.78, high=1.0, floor=0.3))


def lemon_crate():
    """Lada de sipci: un miez inchis (golurile dintre sipci) si trei sipci
    inelare in jurul lui — fiecare sipca e o cutie care inconjoara miezul, deci
    intre ele se vede umbra. Deasupra: o movila joasa acoperita de cinci lamai
    mari, cu varfurile ascutite (polii elipsoidului) culcate in lateral, care
    trec 12 cm peste marginea lazii, si doua frunze. Lamaile sunt ieftine (5 x 2, 20 de
    triunghiuri): la 10-30 m conteaza ca movila e COCOLOASA, nu fatetele."""
    W, D = 0.60, 0.40
    core = Builder()
    core.box((0.0, 0.0, 0.1075), (W - 0.04, D - 0.04, 0.215), LOG_DARK)
    slats = Builder()
    for z0 in (0.0, 0.080, 0.160):
        slats.box((0.0, 0.0, z0 + 0.031), (W, D, 0.062), WOOD)
    heap = Builder()
    heap.boulder((0.0, 0.0, 0.230), (W - 0.08, D - 0.08, 0.11), SAND_LIGHT,
                 seed=11, segments=6, rings=2, deviation=0.06)
    lemons = Builder()
    rand = _lcg(5)
    # Lamai de jucarie, exagerate (15 x 10.5 cm): cinci acopera movila. Mai
    # multe si mai mici citeau a cartofi pe o tava, nu a lada plina.
    for x, y, z, yaw in ((-0.170, -0.065, 0.262, 20.0), (0.000, -0.078, 0.270, -30.0),
                         (0.172, -0.050, 0.262, 65.0), (-0.090, 0.068, 0.276, 80.0),
                         (0.095, 0.062, 0.285, 10.0)):
        fs = lemons.boulder((0.0, 0.0, 0.0), (0.105, 0.105, 0.150), SAND_LIGHT,
                            seed=int(rand() * 1000), segments=5, rings=2, deviation=0.04)
        tilt = (rand() - 0.5) * 24.0
        rot = (Matrix.Rotation(math.radians(yaw), 3, "Z")
               @ Matrix.Rotation(math.radians(90.0 + tilt), 3, "Y"))
        for v in {v for f in fs for v in f.verts}:
            v.co = rot @ v.co + Vector((x, y, z))
    # doua frunze verzi intre lamai: fara ele galbenul paletei (SAND_LIGHT,
    # singurul galben legal) se citea a paine / cartofi, nu a citrice
    leaves = Builder()
    for path in (((-0.02, 0.010, 0.300), (0.05, 0.000, 0.318), (0.12, -0.012, 0.305)),
                 ((-0.04, 0.015, 0.300), (-0.10, -0.010, 0.316), (-0.16, 0.000, 0.300))):
        leaves.blade(path, [0.035, 0.050, 0.0], 0.012, TROPICAL_GREEN)
    return assemble("LemonCrate", [(core, 0.0, 60.0, 30.0), (slats, 0.008, 30.0, 30.0),
                                   (heap, 0.0, 60.0, 70.0), (lemons, 0.0, 95.0, 95.0),
                                   (leaves, 0.0, 95.0, 60.0)],
                    (0.60, 0.40, 0.34),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.62, high=1.0, floor=0.25))


def amphora():
    """Amfora cu talpa plata (stabila in picioare), burta la 0.20, umar cu o
    banda pictata neagra, gat ingust cu buza rasfranta si gura deschisa (con
    intors, intunecat). Doua toarte mici de la gat la umar, raza maxima 0.166
    — in raza burtii, deci colizorul cilindric ramane corect."""
    b = Builder()
    prof = [
        (0.110, 0.000), (0.124, 0.040),       # talpa
        (0.190, 0.200),
        (0.200, 0.300),                       # burta
        (0.185, 0.420), (0.130, 0.520),       # umar
        (0.075, 0.570), (0.070, 0.630),       # gat
        (0.090, 0.655), (0.088, 0.680),       # buza
        (0.060, 0.675), (0.0, 0.610),         # gura, in jos
    ]
    body = b.revolve(prof, TILE_TERRACOTTA, segments=12)
    b.retag(body, VOLCANIC_BLACK, where=lambda c, n: 0.42 < c.z < 0.52)   # banda pictata
    b.retag(body, VOLCANIC_BLACK, where=lambda c, n: c.z > 0.6 and math.hypot(c.x, c.y) < 0.065)
    hd = Builder()
    for a in (0.0, 180.0):
        d = Vector((math.cos(math.radians(a)), math.sin(math.radians(a)), 0.0))
        pts = [d * 0.066 + Vector((0, 0, 0.605)), d * 0.140 + Vector((0, 0, 0.592)),
               d * 0.150 + Vector((0, 0, 0.500))]
        hd.taper_sweep(pts, 0.014, TILE_TERRACOTTA, segments=4)
    return assemble("Amphora", [(b, 0.0, 60.0, 50.0), (hd, 0.0, 95.0, 95.0)],
                    (0.40, 0.40, 0.68),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.62, high=1.0, floor=0.25))


for nm in ("FishingBuoy", "LemonCrate", "Amphora"):
    clear_built(nm)

objs = [fishing_buoy(), lemon_crate(), amphora()]
total = sum(report(o) for o in objs)
print("TOTAL %d tris" % total)
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB: %s (%d B)" % export_glb(objs, GLB_PATH))
