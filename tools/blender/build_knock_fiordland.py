"""knock_fiordland.glb — recuzita LOVIBILA pentru drumul si debarcaderul din
fiordurile Noii Zeelande (rece, ud).

Piese (noduri radacina frati, toate exportate in (0,0,0), originea la baza):
  RoadCone     HULL    baza patrata 0.38 x 0.38, H0.70   con de trafic portocaliu
                       cu o banda alba, talpa neagra
  MooringBuoy  SPHERE  Ø0.50   geamandura de ancorare portocalie cu banda alba;
                       ochiul de metal de pe crestet iese sub 3 cm
  FishBin      BOX     0.70 x 0.45 x 0.50   lada de peste din plastic albastru,
                       usor evazata, capac alb, nervuri turnate, manere

Sloturi in paleta lumii Fiordland: LAVA_ORANGE 30 (caiacul; singurul portocaliu
saturat legal), FOAM_WHITE 22, VOLCANIC_BLACK 20, ASPHALT_EDGE 6 (metal),
ICE_DEEP 25 (albastrul rece), ICE_CRACK 26 (golurile manerelor).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_fiordland.py
"""

import math
import bpy
from mathutils import Vector, Matrix

GLB_PATH = "fiordland/props/knock_fiordland.glb"


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

def road_cone():
    """Con de trafic: talpa patrata neagra 0.38 x 0.38 (latura care da
    amprenta), con portocaliu de 14 laturi cu o banda alba reflectorizanta la
    jumatatea inaltimii si un varf retezat."""
    base = Builder()
    base.box((0.0, 0.0, 0.020), (0.38, 0.38, 0.040), VOLCANIC_BLACK)
    cone = Builder()

    def r_at(z):
        return 0.150 - (z - 0.035) * (0.122 / 0.650)

    prof = [(r_at(z), z) for z in (0.035, 0.360, 0.480, 0.685)]
    prof += [(0.024, 0.700), (0.0, 0.700)]
    body = cone.revolve(prof, LAVA_ORANGE, segments=14)
    cone.retag(body, FOAM_WHITE, where=lambda c, n: 0.36 < c.z < 0.48)
    return assemble("RoadCone", [(base, 0.012, 30.0, 30.0), (cone, 0.0, 60.0, 50.0)],
                    (0.38, 0.38, 0.70),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.68, high=1.0, floor=0.25))


def mooring_buoy():
    """Sfera usor turtita (Ø0.50 x 0.47), portocalie, cu banda alba lata pe
    ecuator si un ochi de metal pe crestet (tor vertical, pe jumatate ingropat,
    iese 2.6 cm; contract: max 3 cm)."""
    b = Builder()
    lats = (-70, -46, -24, -9, 9, 24, 46, 70)

    def slot_of(i, k):
        return FOAM_WHITE if k == 4 else LAVA_ORANGE

    latlong(b, (0.0, 0.0, 0.235), 0.25, 0.235, [i * (360.0 / 14) for i in range(14)],
            lats, slot_of)
    eye = Builder()
    eye.torus((0.0, 0.0, 0.470), 0.018, 0.008, ASPHALT_EDGE,
              major_seg=8, minor_seg=4, axis="Y")
    return assemble("MooringBuoy", [(b, 0.0, 60.0, 55.0), (eye, 0.0, 60.0, 60.0)],
                    (0.50, 0.50, None),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.78, high=1.0, floor=0.3))


def fish_bin():
    """Lada de peste din plastic: corp evazat (0.62 x 0.42 jos -> 0.66 x 0.46
    sus), doua nervuri verticale turnate pe fiecare latura lunga (ies 1.5 cm,
    raman in amprenta capacului), capac alb cu buza peste corp (0.70 x 0.50 =
    bbox-ul), manere ca goluri inchise pe laturile scurte."""
    H_BODY = 0.39
    KX, KY = (0.66 / 0.62 - 1.0) / H_BODY, (0.46 / 0.42 - 1.0) / H_BODY
    b = Builder()
    b.box((0.0, 0.0, H_BODY * 0.5), (0.62, 0.42, H_BODY), ICE_DEEP)
    for x in (-0.15, 0.15):
        for sy in (-1.0, 1.0):
            b.box((x, sy * 0.2125, 0.185), (0.045, 0.025, 0.35), ICE_DEEP)
    for v in b.bm.verts:                       # evazarea, si pentru nervuri
        v.co.x *= 1.0 + KX * v.co.z
        v.co.y *= 1.0 + KY * v.co.z
    lid = Builder()
    lid.box((0.0, 0.0, 0.42), (0.70, 0.50, 0.06), FOAM_WHITE)
    holes = Builder()
    for sx in (-1.0, 1.0):
        z = 0.32
        holes.box((sx * 0.31 * (1.0 + KX * z), 0.0, z), (0.026, 0.17, 0.055), ICE_CRACK)
    return assemble("FishBin", [(b, 0.010, 30.0, 30.0), (lid, 0.014, 30.0, 30.0),
                                (holes, 0.0, 30.0, 30.0)],
                    (0.70, 0.50, 0.45),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.65, high=1.0, floor=0.25))


for nm in ("RoadCone", "MooringBuoy", "FishBin"):
    clear_built(nm)

objs = [road_cone(), mooring_buoy(), fish_bin()]
total = sum(report(o) for o in objs)
print("TOTAL %d tris" % total)
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB: %s (%d B)" % export_glb(objs, GLB_PATH))
