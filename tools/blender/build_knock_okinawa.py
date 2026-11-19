"""knock_okinawa.glb — recuzita LOVIBILA pentru coasta de pescari din Okinawa.

Piese (noduri radacina frati, toate exportate in (0,0,0), originea la baza):
  GlassFloat  SPHERE  Ø0.42                plutitor de sticla verde-turcoaz in
                      plasa de funie (4 meridiane + ecuator, in relief 1.2 cm)
  FishBox     BOX     0.62 x 0.30 x 0.42   lada de polistiren alba, capac, doua
                      chingi albastre
  KameJar     CYL     Ø0.46 x H0.56        borcan de depozitare smaltuit maro, cu
                      umeri, gura mica, capac; urechiusele stau in raza burtii

Sloturi in paleta lumii Okinawa: FOAM_WHITE 22 (barcile, casele), ICE_DEEP 25
si REEF_SHALLOW 17 (recuzita existenta: oglinda, plasele), ROCK_DARK 4 /
LOG_DARK 28 / LARCH_RUST 27 (lemnul inchis al caselor; aici smalt si lut),
DRY_VEGETATION 13 (funie).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_okinawa.py
"""

import math
import bpy
from mathutils import Vector

GLB_PATH = "okinawa/props/knock_okinawa.glb"


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

ROPE = 0.010          # cat iese funia peste sticla (contract: max 1.5 cm)
# Meridianele de sticla dintre funii se ridica si ele putin: altfel fata de
# sticla dintre doua funii ridicate devine CONCAVA si sfera iese cocoloasa.
GLASS_LIFT = 0.005


def glass_float():
    """Sfera cu meridiane DUBLE pe funii: fiecare funie e o coloana ingusta
    (±4 grade, ~2.8 cm) intre doua meridiane ridicate cu ROPE; intre funii, doua
    meridiane de sticla (la +30 si +60 de grade). 16 meridiane -> silueta rotunda.
    Ecuatorul e a cincea funie, la fel construit pe paralele. Calota mica de sus
    e nodul de funie in care se strang meridianele."""
    b = Builder()
    lons = []
    for a in (0.0, 90.0, 180.0, 270.0):
        lons += [a - 4.0, a + 4.0, a + 30.0, a + 60.0]
    rope_lons = {0, 1, 4, 5, 8, 9, 12, 13}    # indicii meridianelor de funie
    lats = (-68, -42, -17, -4, 4, 17, 42, 72)
    rope_lats = {3, 4}

    def slot_of(i, k):
        if k == len(lats):
            return DRY_VEGETATION                 # nodul de sus
        if i in (0, 4, 8, 12):                    # coloana dintre a-4 si a+4
            return DRY_VEGETATION
        if k == 4:                                # banda dintre paralelele ±4
            return DRY_VEGETATION
        return REEF_SHALLOW

    def lift(i, k):
        return ROPE if (i in rope_lons or k in rope_lats) else GLASS_LIFT

    latlong(b, (0.0, 0.0, 0.21), 0.198, 0.198, lons, lats, slot_of, lift)
    return assemble("GlassFloat", [(b, 0.0, 60.0, 60.0)], (0.42, 0.42, 0.42),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.80, high=1.0, floor=0.3))


def fish_box():
    """Lada de polistiren: corp retras 1 cm sub capacul cu buza, doua chingi
    albastre care trec peste capac si coboara pe laturile lungi (X = 0.62)."""
    b = Builder()
    b.box((0.0, 0.0, 0.125), (0.600, 0.400, 0.250), FOAM_WHITE)
    lid = b.box((0.0, 0.0, 0.274), (0.620, 0.420, 0.052), FOAM_WHITE)
    s = Builder()
    for x in (-0.17, 0.17):
        s.box((x, 0.0, 0.1525), (0.060, 0.428, 0.305), ICE_DEEP)
    return assemble("FishBox", [(b, 0.014, 30.0, 30.0), (s, 0.006, 30.0, 30.0)],
                    (0.62, None, 0.30),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.72, high=1.0, floor=0.25))


def kame_jar():
    """Borcan kame: corp smaltuit maro, umeri cu smalt aproape negru scurs,
    gura ingusta cu capac de lut ars (chihlimbariu). Doua
    urechiuse pe umar, la raza 0.20 < burta 0.23 — nu ating colizorul."""
    b = Builder()
    prof = [
        (0.150, 0.000),
        (0.212, 0.115),
        (0.230, 0.255),       # burta: raza maxima
        (0.214, 0.375),
        (0.168, 0.445),       # umar
        (0.112, 0.484),       # gat
        (0.128, 0.510),       # buza capacului
        (0.128, 0.528),
        (0.072, 0.551),
        (0.0, 0.560),
    ]
    body = b.revolve(prof, ROCK_DARK, segments=12)
    b.retag(body, LOG_DARK, where=lambda c, n: 0.36 < c.z < 0.49)       # smalt inchis pe umeri
    b.retag(body, LARCH_RUST, where=lambda c, n: c.z >= 0.49)           # capacul de lut
    lugs = Builder()
    for a in (0.0, 180.0):
        ar = math.radians(a)
        r = 0.185
        lugs.box((r * math.cos(ar), r * math.sin(ar), 0.418), (0.050, 0.036, 0.034),
                 LOG_DARK)
    return assemble("KameJar", [(b, 0.0, 60.0, 55.0), (lugs, 0.007, 30.0, 30.0)],
                    (0.46, 0.46, 0.56),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.62, high=1.0, floor=0.25))


for nm in ("GlassFloat", "FishBox", "KameJar"):
    clear_built(nm)

objs = [glass_float(), fish_box(), kame_jar()]
total = sum(report(o) for o in objs)
print("TOTAL %d tris" % total)
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB: %s (%d B)" % export_glb(objs, GLB_PATH))
