"""knock_monumentvalley.glb — kitul de recuzita LOVIBILA de la ferma din Monument Valley.

Trei piese mici care stau langa drum si zboara cand le loveste o masina:

  RoundBale    CYL  Ø0.90 x 0.90  balot rotund de fan, in picioare pe o fata plata;
                                  sfori in jurul lui, spirala sugerata pe ambele fete
  FeedBucket   CYL  Ø0.36 x 0.34  galeata zincata, usor conica, toarta culcata lipit
                                  de perete, plina cu nutret
  RanchBarrel  CYL  Ø0.56 x 0.78  butoi din doage (burta 0.56), cercuri de fier

Contractul (din kitul de recuzita lovibila, valul 3):
  - fiecare piesa = un nod RADACINA cu numele de mai sus, toate exportate la (0,0,0)
  - originea la centrul bazei, scara aplicata, culoarea DOAR din atlas (UV pe
    centrul slotului) + AO copt in vertex colors
  - CYL primeste un colizor cilindric calculat din AABB pe axa verticala, deci
    toarta galetii sta culcata pe perete, sub raza buzei (nu iese din corp)
  - max 320 de triunghiuri pe piesa

Sloturile vin din ce foloseste deja lumea (census pe assets/models/monumentvalley):
DRY_VEGETATION 13 + SAND_LIGHT 0 / SAND_MID 1 (fanul, fetele taiate, nutretul),
LOG_DARK 28 (sfoara), MARBLE_GREY 29 + ASPHALT_EDGE 6 (tabla zincata, buza,
toarta), WOOD 9 / LARCH_RUST 27 (doagele alternante), VOLCANIC_BLACK 20
(cercurile de fier), SAND_MID 1 si pe capacul butoiului.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_knock_monumentvalley.py
"""

import math
import bpy
from mathutils import Vector

KEY = "monumentvalley"
GLB_PATH = "monumentvalley/props/knock_monumentvalley.glb"
MAX_TRIS = 320

# ============================================================ ajutoare (locale)
# Fiecare build_knock_*.py e de sine statator (contractul permite doar fisierul
# propriu), deci ajutoarele de mai jos se repeta identic in cele cinci kituri.


def circle(r, n, sx=1.0, sy=1.0, phase=0.0):
    """Puncte (x, y) pe un cerc (sau elipsa) cu n laturi."""
    return [(r * sx * math.cos(phase + 2.0 * math.pi * i / n),
             r * sy * math.sin(phase + 2.0 * math.pi * i / n)) for i in range(n)]


def loft(b, sections, bottom=None, top=None):
    """Suprafata prin sectiuni orizontale succesive, cu slot PE BANDA.

    sections: [(pts2d, z, slot_banda_de_deasupra)], toate cu acelasi numar de
    puncte; o sectiune cu UN punct e varf (evantai). Slotul benzii poate fi un
    tuplu: alterneaza pe segmente (doage de butoi, fara niciun triunghi in plus).
    bottom / top: slotul capacului de jos / sus (ngon), sau None = deschis.
    Fetele se eticheteaza direct, nu prin `_tag` (care ar recoloara si vecinii).
    """
    rings = []
    for pts, z, _slot in sections:
        rings.append([b.bm.verts.new((x, y, z)) for x, y in pts])
    out = []

    def put(f, slot):
        f[b.slot] = slot
        out.append(f)

    for k in range(len(rings) - 1):
        lo, hi = rings[k], rings[k + 1]
        slot = sections[k][2]
        n = max(len(lo), len(hi))
        for i in range(n):
            j = (i + 1) % n
            s = slot[i % len(slot)] if isinstance(slot, tuple) else slot
            if len(hi) == 1:
                put(b.bm.faces.new((lo[i], lo[j], hi[0])), s)
            elif len(lo) == 1:
                put(b.bm.faces.new((lo[0], hi[j], hi[i])), s)
            else:
                put(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])), s)
    if bottom is not None and len(rings[0]) > 2:
        put(b.bm.faces.new(tuple(reversed(rings[0]))), bottom)
    if top is not None and len(rings[-1]) > 2:
        put(b.bm.faces.new(tuple(rings[-1])), top)
    return out


def lathe(b, profile, n, bottom=None, top=None, sx=1.0, sy=1.0, phase=0.0):
    """Corp de revolutie din profil [(r, z, slot_banda_de_deasupra)].
    r == 0 la un capat = varf."""
    secs = []
    for r, z, slot in profile:
        pts = [(0.0, 0.0)] if r <= 1e-6 else circle(r, n, sx, sy, phase)
        secs.append((pts, z, slot))
    return loft(b, secs, bottom, top)


def _join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


AO = dict(samples=32, dist=0.35, gradient="vertical", low=0.66, high=1.0,
          power=0.8, floor=0.35)


def assemble(name, groups, ao=None):
    """groups = [(fn(b), bevel, bevel_angle, smooth_angle)]. Fiecare grup isi ia
    bevel-ul lui (snapshot -> bevel -> smooth -> UV pe sloturi), apoi totul se
    uneste, originea se aseaza O DATA pe ansamblu si AO-ul se coace pe tot."""
    parts = []
    for k, (fn, bev, ang, smooth) in enumerate(groups):
        b = Builder()
        fn(b)
        if not b.bm.faces:
            b.bm.free()
            continue
        o = b.to_object("%s_part%d" % (name, k))
        snap = snapshot_slots(o)
        apply_bevel(o, bev, segments=1, angle_deg=ang)
        apply_smooth(o, smooth)
        assign_uvs(o, snap)
        parts.append(o)
    obj = _join(parts, name)
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    set_origin_base(obj, center_xy=True)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    bake_ao(obj, **(ao or AO))
    return obj


def used_slots(obj):
    uv = obj.data.uv_layers.active
    return sorted({int(round(uv.data[p.loop_indices[0]].uv[0] * 32 - 0.5))
                   for p in obj.data.polygons})


def check(obj, kind, spec):
    """Masoara AABB-ul in cotele GODOT (W = x, H = z_bl, D = y_bl) si il compara
    cu specificatia (+-5 %). Pentru CYL verifica si ca nimic nu iese din cercul
    colizorului (raza = max(W, D) / 2, pe axa prin origine)."""
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    w, d, h = max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)
    problems = []
    for label, got, want in (("W", w, spec[0]), ("H", h, spec[1]), ("D", d, spec[2])):
        if abs(got - want) > want * 0.05:
            problems.append("%s %.3f vs %.3f" % (label, got, want))
    if abs(min(zs)) > 1e-4:
        problems.append("baza la z=%.4f" % min(zs))
    if kind in ("CYL", "SPHERE"):
        r_col = max(w, d) * 0.5
        r_max = max(math.hypot(v.co.x, v.co.y) for v in me.vertices)
        if r_max > r_col + 0.03:
            problems.append("iese din colizor: r %.3f > %.3f" % (r_max, r_col))
    if kind == "SPHERE":
        if max(w, h, d) > min(w, h, d) * 1.12 and abs(h - spec[1]) > spec[1] * 0.05:
            problems.append("sfera neuniforma")
    tris = tri_count(obj)
    if tris > MAX_TRIS:
        problems.append("%d tris > %d" % (tris, MAX_TRIS))
    print("KNOCK %-13s %-6s %.3f x %.3f x %.3f m | %3d tris | sloturi %s | %s"
          % (obj.name, kind, w, h, d, tris, ",".join(str(s) for s in used_slots(obj)),
             "OK" if not problems else "PROBLEME: " + "; ".join(problems)))
    return not problems


# ============================================================ piesele

HAY = DRY_VEGETATION    # 13 flancul balotului
END_A = SAND_LIGHT      # 0  fata taiata, spirele deschise
END_B = SAND_MID        # 1  spirele mai inchise
TWINE = LOG_DARK        # 28
GALV = MARBLE_GREY      # 29 tabla zincata
GALV_DARK = ASPHALT_EDGE  # 6 buza rasfranta, nervura, toarta
FEED = SAND_MID         # 1  nutret (graunte)
STAVES = (WOOD, LARCH_RUST)  # 9 / 27 doage alternante, zero triunghiuri in plus
IRON = VOLCANIC_BLACK   # 20 cercurile
BARREL_LID = SAND_MID   # 1  capacul, lemn taiat (2 citea a butoi deschis)


def round_bale(b):
    # Profilul porneste din CENTRUL fetei de jos si se termina in centrul celei
    # de sus, ca ambele fete sa poarte inelele spiralei (balotul se rostogoleste,
    # deci si fata de jos ajunge la vedere).
    prof = [
        (0.150, 0.000, END_B),
        (0.282, 0.000, END_A),
        (0.405, 0.000, HAY),
        (0.450, 0.052, HAY),
        (0.450, 0.292, TWINE),
        (0.450, 0.322, HAY),
        (0.450, 0.578, TWINE),
        (0.450, 0.608, HAY),
        (0.450, 0.848, HAY),
        (0.405, 0.900, END_A),
        (0.282, 0.900, END_B),
        (0.150, 0.900, END_A),
    ]
    faces = lathe(b, prof, 12, bottom=END_A, top=END_A)
    # Spirala: inelele nu sunt concentrice — fiecare isi muta centrul in alta
    # parte (si invers pe cele doua fete), deci ochiul citeste o rulada, nu o tinta.
    verts = sorted({v for f in faces for v in f.verts},
                   key=lambda v: (round(v.co.z, 4), round(math.atan2(v.co.y, v.co.x), 4)))
    rnd = _lcg(71)
    for v in verts:
        r = math.hypot(v.co.x, v.co.y)
        flat = v.co.z < 0.001 or v.co.z > 0.899
        if flat and abs(r - 0.282) < 0.01:
            v.co.x += 0.030 if v.co.z > 0.5 else -0.030
        elif flat and abs(r - 0.150) < 0.01:
            v.co.x -= 0.024 if v.co.z > 0.5 else -0.024
            v.co.y += 0.018
        elif not flat and abs(r - 0.450) < 0.002 and 0.06 < v.co.z < 0.84:
            # flancul de fan nu e strunjit: mici umflaturi radiale, spre
            # interior, ca raza maxima (colizorul) sa ramana 0.450
            k = 1.0 - rnd() * 0.022
            v.co.x *= k
            v.co.y *= k


def feed_bucket(b):
    # Galeata conica: talpa tesita, nervura presata, buza rasfranta, interior,
    # nutret ingramadit. Raza maxima 0.180 = buza.
    prof = [
        (0.138, 0.000, GALV),
        (0.150, 0.014, GALV),
        (0.156, 0.105, GALV_DARK),
        (0.158, 0.128, GALV),
        (0.169, 0.300, GALV_DARK),
        (0.180, 0.322, GALV_DARK),
        (0.178, 0.340, GALV_DARK),
        (0.164, 0.338, GALV),
        (0.160, 0.286, FEED),
        (0.090, 0.304, FEED),
    ]
    lathe(b, prof, 12, bottom=GALV, top=FEED)


def bucket_handle(b):
    # Toarta culcata: coboara de la urechi (pe X) prin fata (+Y) lipita de
    # perete. Sta la r <= 0.180, adica in cercul buzei: colizorul nu se lateste.
    def wall_r(z):
        return 0.158 + (0.169 - 0.158) * (z - 0.128) / (0.300 - 0.128)
    pts = []
    for deg in (8.0, 50.0, 90.0, 130.0, 172.0):
        a = math.radians(deg)
        z = 0.296 - 0.105 * math.sin(a)
        r = wall_r(z) + 0.006
        pts.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    for p0, p1 in zip(pts, pts[1:]):
        b.beam(p0, p1, (0.012, 0.016), GALV_DARK)


def ranch_barrel(b):
    # Butoi de doage cu burta (r 0.280 la mijloc), patru cercuri de fier,
    # capatul doagelor deasupra capacului adancit.
    prof = [
        (0.234, 0.000, IRON),
        (0.244, 0.016, IRON),
        (0.249, 0.060, STAVES),
        (0.265, 0.198, IRON),
        (0.269, 0.236, STAVES),
        (0.280, 0.390, STAVES),
        (0.269, 0.544, IRON),
        (0.265, 0.582, STAVES),
        (0.249, 0.720, IRON),
        (0.244, 0.764, IRON),
        (0.240, 0.780, STAVES),
        (0.220, 0.780, STAVES),
        (0.220, 0.758, BARREL_LID),
    ]
    lathe(b, prof, 12, bottom=IRON, top=BARREL_LID)


# ============================================================ build
clear_built("RoundBale")
clear_built("FeedBucket")
clear_built("RanchBarrel")

SPECS = [
    ("RoundBale", "CYL", (0.90, 0.90, 0.90),
     [(round_bale, 0.0, 30.0, 45.0)]),
    ("FeedBucket", "CYL", (0.36, 0.34, 0.36),
     [(feed_bucket, 0.0, 30.0, 40.0), (bucket_handle, 0.0, 30.0, 40.0)]),
    ("RanchBarrel", "CYL", (0.56, 0.78, 0.56),
     [(ranch_barrel, 0.0, 30.0, 40.0)]),
]

objs, ok = [], True
for name, kind, spec, groups in SPECS:
    o = assemble(name, groups)
    ok = check(o, kind, spec) and ok
    objs.append(o)

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, GLB_PATH))
print("KNOCK VERDICT %s: %s" % (KEY, "OK" if ok else "PROBLEME"))
