"""knock_beach.glb — kit de recuzita LOVIBILA pentru plaja insulei de jucarie
(vechea pista de test "Okinawa manual").

Piese (noduri radacina frati, toate exportate in (0,0,0), originea la baza):
  BeachBall   SPHERE  Ø0.60            minge cu felii: alb + rosu + turcoaz
  SwimRing    CYL     Ø0.80 x H0.20    colac culcat, felii portocaliu / alb
  SandBucket  CYL     Ø0.36 (buza) -> Ø0.28 (fund), H0.34; toarta pliata in jos,
                      tinuta SUB raza buzei; nisip ingramadit peste buza

Colizorul se calculeaza din bounding box (cilindru / sfera pe axa verticala),
deci nimic nu iese din corpul rotund: toarta galetii sta lipita de perete, sub
buza, in raza ei.

Totul pe ATLAS (UV-uri colapsate pe centre de slot), AO copt in vertex colors.
Pipeline: piesele se construiesc din parti (fiecare cu bevel-ul ei), se unesc,
se aduc pe cotele cerute, apoi AO-ul se coace o data pe piesa intreaga, ca
partile sa se umbreasca reciproc (nisipul din galeata, de exemplu).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_beach.py
"""

import math
import bpy
from mathutils import Vector

GLB_PATH = "props/knock_beach.glb"


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

def beach_ball():
    """8 felii (16 meridiane, 2 per felie): rosu / alb / turcoaz / alb, calote
    albe la poli — mingea clasica. Fara bevel: sfera n-are muchii."""
    b = Builder()
    gores = (KERB_RED, FOAM_WHITE, REEF_SHALLOW, FOAM_WHITE)
    lats = (-72, -48, -24, 0, 24, 48, 72)

    def slot_of(i, k):
        if k == 0 or k == len(lats):
            return FOAM_WHITE
        return gores[(i // 2) % 4]

    latlong(b, (0.0, 0.0, 0.30), 0.30, 0.30, [i * 22.5 for i in range(16)], lats, slot_of)
    return assemble("BeachBall", [(b, 0.0, 60.0, 55.0)], (0.60, 0.60, 0.60),
                    ao=dict(samples=24, dist=0.4, gradient="vertical",
                            low=0.80, high=1.0, floor=0.3))


def swim_ring():
    """Colac culcat: tor 16 x 8, felii de cate doua segmente alternand
    portocaliu / alb (8 felii). Inelul de jos al torului e plan la z=0, deci
    sta stabil pe sol."""
    b = Builder()
    faces = b.torus(center=(0.0, 0.0, 0.10), major_r=0.30, minor_r=0.10,
                    slot=LAVA_ORANGE, major_seg=16, minor_seg=8)
    b.retag(faces, FOAM_WHITE,
            where=lambda c, n: int(angle_of(c) // 45.0) % 2 == 1)
    return assemble("SwimRing", [(b, 0.0, 60.0, 55.0)], (0.80, 0.80, 0.20),
                    ao=dict(samples=24, dist=0.35, gradient="vertical",
                            low=0.72, high=1.0, floor=0.3))


def sand_bucket():
    """Galeata de jucarie: trunchi de con cu buza tesita la 45° (deci rotunjita
    de shade smooth, fara bevel), nisip ingramadit peste buza, toarta pliata in
    jos, atarnand pe perete SUB buza — in raza ei, ca sa nu umfle colizorul."""
    b = Builder()
    seg = 12
    prof = [
        (0.132, 0.000), (0.140, 0.008),      # fund, cu tesitura
        (0.158, 0.255),                       # perete
        (0.178, 0.271), (0.178, 0.291),       # buza rasfranta
        (0.160, 0.300),                       # muchia de sus a buzei, interior
        (0.115, 0.322), (0.058, 0.338),       # nisip ingramadit (~4.5 cm)
        (0.0, 0.345),
    ]
    body = b.revolve(prof, REEF_SHALLOW, segments=seg)
    b.retag(body, SAND_LIGHT,
            where=lambda c, n: c.z > 0.298 and math.hypot(c.x, c.y) < 0.150)

    # Toarta: un U culcat pe perete, cu capetele intrate in buza (pivotii) si
    # mijlocul atarnand mai jos. Raza exterioara <= 0.172 < buza 0.178.
    h = Builder()
    path = []
    for t in range(7):
        a = math.radians(-90.0 + 30.0 * t)
        z = 0.265 - 0.045 * math.sin(math.radians(30.0 * t))   # atarna la mijloc
        wall = 0.140 + (0.158 - 0.140) * (z - 0.008) / (0.255 - 0.008)
        r = min(wall, 0.160) + 0.010
        path.append((r * math.cos(a), r * math.sin(a), z))
    h.taper_sweep(path, 0.010, FOAM_WHITE, segments=6)
    return assemble("SandBucket", [(b, 0.0, 60.0, 55.0), (h, 0.0, 80.0, 70.0)],
                    (0.36, 0.36, 0.34),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.70, high=1.0, floor=0.25))


for nm in ("BeachBall", "SwimRing", "SandBucket"):
    clear_built(nm)

objs = [beach_ball(), swim_ring(), sand_bucket()]
total = sum(report(o) for o in objs)
print("TOTAL %d tris" % total)
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB: %s (%d B)" % export_glb(objs, GLB_PATH))
