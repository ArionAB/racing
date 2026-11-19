"""knock_halong.glb — recuzita LOVIBILA pentru satul plutitor de pescari din
golful Ha Long.

Piese (noduri radacina frati, toate exportate in (0,0,0), originea la baza):
  FloatBarrel  CYL   Ø0.50 x H0.82   butoi-flotor de plastic albastru, doua
                     nervuri inelare in relief (1.5 cm), capac plat cu dop
  FishBasket   CYL   Ø0.52 x H0.34   cos deschis de bambus, tesatura in sah,
                     peste argintiu ingramadit peste buza
  HatStack     HULL  Ø0.56 x H0.40   patru palarii conice (non la) stivuite

Sloturi in paleta lumii Ha Long: WOOD 9 si DRY_VEGETATION 13 (barcile, cosurile,
plasele), MARBLE_GREY 29 (piatra; aici solzii), SEA_DEEP 18, ICE_DEEP 25 (cel
mai apropiat albastru legal de albastrul caselor plutitoare), FOAM_WHITE 22,
SAND_LIGHT 0, CORAL_SAND 19 (frunza de palmier a palariilor).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_halong.py
"""

import math
import bpy
from mathutils import Vector, Matrix

GLB_PATH = "halong/props/knock_halong.glb"


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

def float_barrel():
    """Butoi de plastic: corp 0.235, doua nervuri cu profil triunghiular care
    ies 1.5 cm (raza 0.25 = Ø0.50), muchii de sus si de jos tesite, capac plat
    usor adancit sub buza, cu un dop alb. Profilul tesit la 45 de grade nu cere
    bevel: shade smooth il rotunjeste."""
    b = Builder()
    prof = [
        (0.224, 0.000), (0.235, 0.014),
        (0.235, 0.245), (0.250, 0.270), (0.235, 0.295),      # nervura de jos
        (0.235, 0.525), (0.250, 0.550), (0.235, 0.575),      # nervura de sus
        (0.235, 0.802), (0.226, 0.820),                       # buza de sus
        (0.206, 0.810),                                       # capacul, adancit
        (0.0, 0.810),
    ]
    body = b.revolve(prof, ICE_DEEP, segments=12)
    b.retag(body, PAINTED, where=lambda c, n: c.z > 0.805 and math.hypot(c.x, c.y) < 0.2)
    bung = Builder()
    bung.cylinder((0.115, 0.0, 0.817), 0.045, 0.022, FOAM_WHITE, segments=8)
    return assemble("FloatBarrel", [(b, 0.0, 60.0, 50.0), (bung, 0.0, 30.0, 30.0)],
                    (0.50, 0.50, 0.82),
                    ao=dict(samples=24, dist=0.35, gradient="vertical",
                            low=0.65, high=1.0, floor=0.25))


HEAP = [(0.228, 0.262), (0.180, 0.285), (0.100, 0.325), (0.0, 0.340)]


def heap_z(r):
    """Cota suprafetei de peste la raza r (interpolare pe profilul gramezii)."""
    for (r0, z0), (r1, z1) in zip(HEAP, HEAP[1:]):
        if r1 <= r <= r0:
            t = (r - r1) / (r0 - r1)
            return z1 + (z0 - z1) * t
    return HEAP[0][1]


def fish_basket():
    """Cos de bambus: perete in sah (doua tonuri APROPIATE de bambus alternand
    pe coloane si randuri = tesatura, zero triunghiuri in plus; doua tonuri
    departate citeau a tabla de sah), buza groasa mai inchisa, gramada
    cocoloasa de peste argintiu care trece de buza, trei pesti cu spinare
    albastru-inchis culcati deasupra."""
    b = Builder()
    prof = [
        (0.200, 0.000),
        (0.240, 0.090), (0.255, 0.170), (0.260, 0.250),     # perete tesut
        (0.260, 0.276), (0.242, 0.287),                     # buza
    ] + HEAP
    body = b.revolve(prof, DRY_VEGETATION, segments=12)

    def weave(c, n):
        if not (0.0 < c.z < 0.25) or math.hypot(c.x, c.y) < 0.2:
            return False
        col = int(angle_of(c) // 30.0)
        row = 0 if c.z < 0.09 else (1 if c.z < 0.17 else 2)
        return (col + row) % 2 == 0

    b.retag(body, SAND_LIGHT, where=weave)
    b.retag(body, WOOD, where=lambda c, n: 0.25 <= c.z and math.hypot(c.x, c.y) > 0.235)
    b.retag(body, MARBLE_GREY, where=lambda c, n: math.hypot(c.x, c.y) < 0.232 and c.z > 0.255)
    # gramada cocoloasa: varfurile suprafetei de peste salta determinist
    rand = _lcg(7)
    for v in b.bm.verts:
        if v.co.z > 0.28 and math.hypot(v.co.x, v.co.y) < 0.19:
            v.co.z += (rand() - 0.4) * 0.040

    fish = Builder()
    # (cap, coada) in plan: trei pesti culcati in directii diferite, fara sa se
    # intalneasca in centru (adunati la mijloc citeau a elice)
    for head, tail in (((0.165, -0.050), (-0.060, -0.125)),
                       ((-0.160, 0.030), (0.050, 0.115)),
                       ((0.115, 0.060), (0.010, -0.030))):
        h, t_ = Vector(head + (0.0,)), Vector(tail + (0.0,))
        pts = []
        for t in (0.0, 0.5, 0.82, 1.0):
            p = h + (t_ - h) * t
            pts.append(Vector((p.x, p.y, heap_z(math.hypot(p.x, p.y)) + 0.014)))
        # cap, burta, coada ingusta, coada lata
        fish.blade(pts, [0.016, 0.068, 0.014, 0.052], 0.026, SEA_DEEP)
    return assemble("FishBasket", [(b, 0.0, 60.0, 50.0), (fish, 0.0, 60.0, 40.0)],
                    (0.52, 0.52, 0.34),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.62, high=1.0, floor=0.25))


def hat_stack():
    """Patru palarii conice imbucate: fiecare e un con de 0.22 m cu o muchie de
    buza de 2 cm (bambus, mai inchisa), tonuri de frunza alternand intre
    palarii, asezata la +6 cm peste cea de dedesubt. Buzele raman in
    afara conului de sub ele, deci stiva se citeste ca patru trepte; o
    deplasare si o inclinare mica intre palarii o face asezata de mana."""
    parts = []
    jitter = ((0.0, 0.0, 0.0), (0.008, -0.004, 2.5), (-0.006, 0.007, -2.0), (0.004, 0.003, 1.5))
    for k, (dx, dy, tilt) in enumerate(jitter):
        b = Builder()
        z0 = 0.06 * k
        faces = b.revolve([(0.268, 0.0), (0.280, 0.020), (0.0, 0.22)],
                          (CORAL_SAND, SAND_LIGHT)[k % 2], segments=14,
                          origin=(0.0, 0.0, 0.0))
        b.retag(faces, WOOD, where=lambda c, n: c.z < 0.03)        # buza de bambus
        rot = Matrix.Rotation(math.radians(tilt), 3, Vector((math.cos(k), math.sin(k), 0.0)))
        for v in b.bm.verts:
            v.co = rot @ v.co + Vector((dx, dy, z0))
        parts.append((b, 0.0, 60.0, 30.0))
    return assemble("HatStack", parts, (0.56, 0.56, 0.40),
                    ao=dict(samples=24, dist=0.3, gradient="vertical",
                            low=0.62, high=1.0, floor=0.25))


for nm in ("FloatBarrel", "FishBasket", "HatStack"):
    clear_built(nm)

objs = [float_barrel(), fish_basket(), hat_stack()]
total = sum(report(o) for o in objs)
print("TOTAL %d tris" % total)
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB: %s (%d B)" % export_glb(objs, GLB_PATH))
