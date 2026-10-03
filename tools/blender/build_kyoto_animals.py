"""Kyoto -- animalele cu schelet (brief docs/asset_briefs/kyoto_kit.md §1.10).

  kyoto/animals/sika_deer.glb   cerb sika; rest pose = `Stand`; actiuni EXACT
                                `Stand`, `Graze`, `Bow`; capul spre +Y Blender
  kyoto/animals/crow.glb        cioara, anvergura 1,6 m, actiunea `Fly` (bucla)

Reteta: `build_sea_turtle.py` (rig in cod peste geometria Builder: fiecare piesa
e o insula, greutati cu `weight_ramp`, poze in spatiul armaturii). Aici
insulele se clasifica dupa pozitia centrului lor in coordonatele CONSTRUITE
(scazand deplasarea facuta de `finish`), cu regiuni alese sa nu se atinga.

CONTRACT INGHETAT: inainte = +Y Blender = -Z Godot (capul cerbului, ciocul
cioarei); actiunile cerbului se numesc `Stand`, `Graze`, `Bow`; a cioarei `Fly`.
Rest pose cerb = `Stand` (oasele la zero in fisier si `Stand` incepe/se inchide
pe zero). Buclele (LOOP_LINEAR) se pun la runtime, ca la vaca: ultimul cadru
= primul.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_animals.py [sika_deer|crow]
"""

import math
import bmesh
import bpy
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())


def _wipe():
    """Scena curata: obiecte, mesh-uri, armaturi si ACTIUNI (un GLB nu trebuie
    sa poarte actiunile piesei construite inaintea lui)."""
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for a in list(bpy.data.armatures):
        bpy.data.armatures.remove(a)


def _bbox(obj):
    return island_bbox(obj, range(len(obj.data.vertices)))


def _squash_x(b, faces, k):
    for v in {v for f in faces for v in f.verts}:
        v.co.x *= k


def rx(deg):
    return Matrix.Rotation(math.radians(deg), 3, "X")


def ry(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Y")


def rz(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


def _key(arm, frame, pose):
    """pose: os -> Matrix (rotatie) sau ("move", Vector) sau lista din ele."""
    for name, ops in pose.items():
        pb = arm.pose.bones[name]
        if not isinstance(ops, list):
            ops = [ops]
        for op in ops:
            if isinstance(op, tuple):
                pose_move(pb, op[1])
                pb.keyframe_insert("location", frame=frame)
            else:
                pose_rotate(pb, op)
                pb.keyframe_insert("rotation_quaternion", frame=frame)


def _reset(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


# ===========================================================================
# CERBUL SIKA
# ===========================================================================
DEER_BODY = SAND_MID
DEER_SPOT = CORAL_SAND
DEER_ANTLER = WOOD
DEER_DARK = VOLCANIC_BLACK
DEER_HOOF = ROCK_DARK

AO_DEER = dict(samples=12, dist=0.6, gradient="vertical",
               low=0.62, high=1.0, power=0.8, floor=0.40)


def deer_geometry():
    """`sika_deer_stand/graze/bow.png` -- elementele de pe decupari:
    - corp de mamifer cu spinarea la ~1,1 m, barilul alungit (~1,2 m), gat
      lung care urca oblic, cap mic cu bot ascutit inchis, urechi mari
      ridicate, ochi mici; doi COARNE subtiri cu furca si un pinten pe
      fiecare (stand); coada scurta crem.
    - PETE ALBE (crem) pe spinare si pe flancuri, ~14 pe parte + cateva pe
      linia spinarii; fata de jos (burta, piept) crem; PETA DE PE FESE crem.
    - patru picioare subtiri cu genunchi, copite inchise; picioarele din
      spate cu jaret.
    Culori: SAND_MID (blana), CORAL_SAND (pete), WOOD (coarne), ROCK_DARK copite.
    Orientare: cap spre +Y."""
    b = Builder()
    body = b.taper_sweep([(0, -0.60, 0.88), (0, -0.35, 0.86), (0, 0.0, 0.85), (0, 0.30, 0.88)],
                         [0.21, 0.26, 0.26, 0.225], DEER_BODY, segments=10)
    _squash_x(b, body, 0.78)
    neck = b.taper_sweep([(0, 0.22, 0.92), (0, 0.40, 1.12), (0, 0.58, 1.30)],
                         [0.18, 0.13, 0.09], DEER_BODY, segments=8)
    _squash_x(b, neck, 0.85)
    skull = b.taper_sweep([(0, 0.58, 1.30), (0, 0.70, 1.36), (0, 0.86, 1.30)],
                          [0.10, 0.09, 0.045], DEER_BODY, segments=8)
    _squash_x(b, skull, 0.85)
    b.box((0, 0.875, 1.285), (0.05, 0.04, 0.04), DEER_DARK)                     # nas
    for sx in (-1, 1):
        b.box((sx * 0.062, 0.73, 1.385), (0.02, 0.035, 0.03), DEER_DARK)        # ochi
        b.beam((sx * 0.06, 0.65, 1.40), (sx * 0.2, 0.61, 1.52), (0.07, 0.02), DEER_BODY)  # ureche
        # coarne: fusul + pintenul frontal + furca
        b.taper_sweep([(sx * 0.05, 0.66, 1.44), (sx * 0.085, 0.63, 1.58), (sx * 0.10, 0.59, 1.70)],
                      [0.018, 0.013, 0.006], DEER_ANTLER, segments=5)
        b.taper_sweep([(sx * 0.058, 0.655, 1.5), (sx * 0.075, 0.72, 1.6)],
                      [0.013, 0.005], DEER_ANTLER, segments=5)
        b.taper_sweep([(sx * 0.093, 0.61, 1.62), (sx * 0.13, 0.57, 1.7)],
                      [0.011, 0.005], DEER_ANTLER, segments=5)
        # picioare: fata (genunchi drept) si spate (jaret)
        b.taper_sweep([(sx * 0.12, 0.20, 0.80), (sx * 0.11, 0.22, 0.40), (sx * 0.10, 0.20, 0.04)],
                      [0.085, 0.05, 0.034], DEER_BODY, segments=6)
        b.taper_sweep([(sx * 0.12, -0.42, 0.80), (sx * 0.11, -0.50, 0.42), (sx * 0.10, -0.45, 0.04)],
                      [0.10, 0.055, 0.036], DEER_BODY, segments=6)
        b.box((sx * 0.10, 0.205, 0.03), (0.07, 0.11, 0.06), DEER_HOOF)
        b.box((sx * 0.10, -0.45, 0.03), (0.07, 0.11, 0.06), DEER_HOOF)
        # burta crem pe flancuri
        b.box((sx * 0.128, -0.12, 0.70), (0.03, 0.72, 0.09), DEER_SPOT)
    b.taper_sweep([(0, -0.60, 0.98), (0, -0.72, 0.92), (0, -0.78, 0.84)],
                  [0.05, 0.04, 0.0], DEER_SPOT, segments=6)
    b.box((0, -0.585, 0.92), (0.2, 0.06, 0.2), DEER_SPOT)                       # peta de pe fese
    # pete pe spinare si flancuri
    rnd = _lcg(7)
    for k in range(34):
        side = -1 if k % 2 == 0 else 1
        y = -0.52 + 0.78 * rnd()
        phi = math.radians(8 + 78 * rnd())
        zc = 0.85
        rx_, rz_ = 0.20, 0.26
        x = side * rx_ * 0.97 * math.cos(phi)
        z = zc + rz_ * 0.93 * math.sin(phi)
        s = 0.05 + 0.012 * rnd()
        b.box((x, y, z), (s, s * 1.15, s), DEER_SPOT)
    return b


def deer_rig(obj, shift):
    def P(x, y, z):
        return Vector((x, y, z)) + shift

    bones = [
        dict(name="Body", head=P(0, -0.5, 0.85), tail=P(0, 0.2, 0.85)),
        dict(name="Neck", head=P(0, 0.22, 0.92), tail=P(0, 0.58, 1.30), parent="Body"),
        dict(name="Head", head=P(0, 0.58, 1.30), tail=P(0, 0.88, 1.30), parent="Neck"),
        dict(name="Tail", head=P(0, -0.6, 0.98), tail=P(0, -0.78, 0.84), parent="Body"),
    ]
    for sx, side in ((-1, "L"), (1, "R")):
        bones += [
            dict(name="F%s1" % side, head=P(sx * 0.12, 0.20, 0.80), tail=P(sx * 0.11, 0.22, 0.40),
                 parent="Body"),
            dict(name="F%s2" % side, head=P(sx * 0.11, 0.22, 0.40), tail=P(sx * 0.10, 0.20, 0.04),
                 parent="F%s1" % side),
            dict(name="R%s1" % side, head=P(sx * 0.12, -0.42, 0.80), tail=P(sx * 0.11, -0.50, 0.42),
                 parent="Body"),
            dict(name="R%s2" % side, head=P(sx * 0.11, -0.50, 0.42), tail=P(sx * 0.10, -0.45, 0.04),
                 parent="R%s1" % side),
        ]
    arm = make_armature("Sika_Deer", bones, mesh=obj)

    def zc(co):
        return co.z - shift.z

    def yc(co):
        return co.y - shift.y

    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5 - shift
        size = hi - lo
        if c.z < 0.55:                                   # picior
            leg = ("F" if c.y > 0 else "R") + ("L" if c.x < 0 else "R")
            if size.z < 0.1:                             # copita
                weight_ramp(obj, island, leg + "2", leg + "2", None, 0.0, 1.0)
                name = leg + "2"
            else:
                knee = 0.40 if c.y > 0 else 0.42
                weight_ramp(obj, island, leg + "2", leg + "1", lambda co: -zc(co),
                            -(knee + 0.07), -(knee - 0.07))
                name = leg + "1/2"
        elif c.y > 0.55:
            name = "Head"
            weight_ramp(obj, island, "Head", "Neck", lambda co: 10.0, 0.0, 1.0)
        elif c.y < -0.66:
            name = "Tail"
            weight_ramp(obj, island, "Tail", "Body", lambda co: 10.0, 0.0, 1.0)
        elif c.y > 0.3 and c.z > 1.05:
            name = "Neck"
            weight_ramp(obj, island, "Neck", "Body", yc, 0.22, 0.46)
        else:
            name = "Body"
            weight_ramp(obj, island, "Body", "Body", None, 0.0, 1.0)
        counts[name] = counts.get(name, 0) + 1
    print("  insule pe oase:", counts)
    for need in ("Body", "Neck", "Head", "Tail", "FL1/2", "FR1/2", "RL1/2", "RR1/2"):
        assert need in counts, "regiune goala: %s %r" % (need, counts)
    return arm


def deer_animate(arm):
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()

    def action(name):
        a = bpy.data.actions.new(name)
        arm.animation_data.action = a
        _reset(arm)
        return a

    ident = Matrix.Identity(3)
    # STAND: respiratie + o clipire a capului; incepe si se inchide pe zero.
    action("Stand")
    for f, br, nk, hd, tl in ((1, 0, 0, 0, 0), (13, 0.006, 1.5, -2.5, 7), (25, 0, 0, 0, 0),
                              (37, 0.006, -1.0, 2.0, -6), (49, 0, 0, 0, 0)):
        _key(arm, f, {"Body": ("move", Vector((0, 0, br))), "Neck": rx(nk), "Head": rx(hd),
                      "Tail": rz(tl)})

    # GRAZE: capul jos la iarba, mestecat usor, urechea/coada; bucla 1,5 s.
    action("Graze")
    legs_f = {"FL1": rx(9), "FR1": rx(9), "FL2": rx(-8), "FR2": rx(-8)}
    for f, hd, nk, tl in ((1, -48, -112, 4), (10, -54, -112, -4), (19, -46, -114, 4),
                          (28, -55, -111, -4), (37, -48, -112, 4)):
        pose = {"Body": [("move", Vector((0, 0, 0.02))), rx(-9)], "Neck": rx(nk), "Head": rx(hd),
                "Tail": rz(tl)}
        pose.update(legs_f)
        _key(arm, f, pose)

    # BOW: se apleca adanc (genunchii fata se indoaie), tine, se ridica; 3 s.
    action("Bow")
    def bow(depth):
        d = depth
        pose = {"Body": [("move", Vector((0, 0, -0.16 * d))), rx(-14 * d)],
                "Neck": rx(-58 * d), "Head": rx(-40 * d), "Tail": rz(0),
                "FL1": rx(18 * d), "FR1": rx(18 * d), "FL2": rx(-48 * d), "FR2": rx(-48 * d),
                "RL1": rx(6 * d), "RR1": rx(6 * d), "RL2": rx(-6 * d), "RR2": rx(-6 * d)}
        return pose
    for f, d in ((1, 0.0), (15, 0.55), (28, 1.0), (46, 1.0), (60, 0.45), (73, 0.0)):
        _key(arm, f, bow(d))

    stash_actions(arm, ("Stand", "Graze", "Bow"))
    _reset(arm)


def build_deer():
    _wipe()
    b = deer_geometry()
    obj = b.to_object("Sika_Deer_Mesh")
    lo0, hi0 = _bbox(obj)
    stats = finish(obj, bevel=0.0, origin="base", ao=AO_DEER, smooth_angle=None)
    lo1, hi1 = _bbox(obj)
    c0, c1 = (lo0 + hi0) * 0.5, (lo1 + hi1) * 0.5
    shift = Vector((c1.x - c0.x, c1.y - c0.y, lo1.z - lo0.z))
    print("  deplasarea din finish: %.3f %.3f %.3f" % tuple(shift))
    arm = deer_rig(obj, shift)
    deer_animate(arm)
    bpy.context.view_layer.update()
    d = obj.dimensions
    print("sika_deer.glb  %d tris  %.2f (X) x %.2f (Y) x %.2f (Z) m" %
          (stats["tris"], d.x, d.y, d.z))
    print("GLB:  %s (%d B)" % export_glb([arm, obj], "kyoto/animals/sika_deer.glb", animations=True))
    print("BLEND: %s (%d B)" % save_blend([arm, obj], "kyoto_sika_deer.blend", compress=True))
    return stats["tris"]


# ===========================================================================
# CIOARA
# ===========================================================================
CROW_BODY = ASPHALT
CROW_FEATHER = VOLCANIC_BLACK
CROW_BEAK = TILE_TERRACOTTA

AO_CROW = dict(samples=10, dist=0.3, gradient="vertical",
               low=0.7, high=1.0, power=0.8, floor=0.45)


def crow_geometry():
    """`crow.png` -- elementele de pe decupare:
    - cioara vazuta din fata-lateral, in zbor: corp fus negru-albastrui, cap
      rotund cu CIOC scurt portocaliu-rosu, ochi mic.
    - doua ARIPI mari desfacute (anvergura 1,6 m), late la baza, cu 5
      PENE PRIMARE lungi evantaiate la varf (degete), arcuite usor.
    - COADA in evantai (3 pene), 2 picioare rosii mici lasate sub corp.
    Culori: ASPHALT corp, VOLCANIC_BLACK aripi/coada, TILE_TERRACOTTA cioc si
    picioare. Orientare: cioc spre +Y, origine in centru."""
    b = Builder()
    body = b.taper_sweep([(0, -0.20, 0.0), (0, -0.04, 0.01), (0, 0.12, 0.02), (0, 0.26, 0.03)],
                         [0.045, 0.115, 0.11, 0.06], CROW_BODY, segments=8)
    for v in {v for f in body for v in f.verts}:
        v.co.z = 0.012 + (v.co.z - 0.012) * 0.88
    b.revolve([(0.04, -0.05), (0.065, -0.01), (0.062, 0.04), (0.0, 0.07)], CROW_BODY,
              segments=8, origin=(0, 0.31, 0.05))
    b.frustum((0, 0.40, 0.045), 0.03, 0.008, 0.12, CROW_BEAK, segments=6, axis="Y")
    for sx in (-1, 1):
        b.box((sx * 0.045, 0.34, 0.075), (0.018, 0.02, 0.02), VOLCANIC_BLACK)  # ochi
        b.taper_sweep([(sx * 0.03, 0.05, -0.06), (sx * 0.03, 0.08, -0.15)],
                      [0.01, 0.007], CROW_BEAK, segments=4)
        # aripa: lama larga umar -> cot -> incheietura
        b.blade([(sx * 0.05, 0.10, 0.03), (sx * 0.32, 0.03, 0.05), (sx * 0.52, -0.03, 0.04)],
                [0.34, 0.42, 0.30], 0.025, CROW_FEATHER, up=(0, 0, 1))
        # 5 pene primare evantaiate
        for k, dy in enumerate((0.15, 0.07, -0.01, -0.09, -0.17)):
            tipx = 0.80 - 0.02 * abs(k - 1)
            b.blade([(sx * 0.50, 0.0 + dy * 0.1, 0.04), (sx * 0.66, 0.0 + dy * 0.6, 0.045),
                     (sx * tipx, dy - 0.02, 0.05)],
                    [0.10, 0.09, 0.04], 0.018, CROW_FEATHER, up=(0, 0, 1))
    for k, ex in enumerate((-0.085, 0.0, 0.085)):
        b.blade([(0, -0.16, 0.0), (ex * 0.6, -0.34, 0.0), (ex, -0.52, 0.0)],
                [0.10, 0.15, 0.13], 0.015, CROW_FEATHER, up=(0, 0, 1))
    return b


def crow_rig(obj, shift):
    def P(x, y, z):
        return Vector((x, y, z)) + shift

    bones = [
        dict(name="Body", head=P(0, -0.15, 0.02), tail=P(0, 0.2, 0.02)),
        dict(name="Head", head=P(0, 0.26, 0.04), tail=P(0, 0.42, 0.05), parent="Body"),
        dict(name="Tail", head=P(0, -0.16, 0.0), tail=P(0, -0.52, 0.0), parent="Body"),
    ]
    for sx, s in ((-1, "L"), (1, "R")):
        bones += [
            dict(name="Wing%s1" % s, head=P(sx * 0.05, 0.08, 0.03), tail=P(sx * 0.32, 0.03, 0.05),
                 parent="Body"),
            dict(name="Wing%s2" % s, head=P(sx * 0.32, 0.03, 0.05), tail=P(sx * 0.80, -0.04, 0.05),
                 parent="Wing%s1" % s),
        ]
    arm = make_armature("Crow", bones, mesh=obj)
    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5 - shift
        size = hi - lo
        if abs(c.x) > 0.10 and size.x > 0.12:            # aripa
            s = "L" if c.x < 0 else "R"
            if size.x > 0.4:                              # lama principala
                weight_ramp(obj, island, "Wing%s2" % s, "Wing%s1" % s,
                            lambda co: abs(co.x - shift.x), 0.22, 0.42)
                name = "Wing%s1/2" % s
            else:                                         # pene primare
                weight_ramp(obj, island, "Wing%s2" % s, "Wing%s1" % s,
                            lambda co: 10.0, 0.0, 1.0)
                name = "Wing%s2" % s
        elif c.y > 0.27:
            name = "Head"
            weight_ramp(obj, island, "Head", "Body", lambda co: 10.0, 0.0, 1.0)
        elif c.y < -0.25:
            name = "Tail"
            weight_ramp(obj, island, "Tail", "Body", lambda co: 10.0, 0.0, 1.0)
        else:
            name = "Body"
            weight_ramp(obj, island, "Body", "Body", None, 0.0, 1.0)
        counts[name] = counts.get(name, 0) + 1
    print("  insule pe oase:", counts)
    for need in ("Body", "Head", "Tail", "WingL1/2", "WingR1/2", "WingL2", "WingR2"):
        assert need in counts, "regiune goala: %s %r" % (need, counts)
    return arm


def crow_animate(arm):
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()
    a = bpy.data.actions.new("Fly")
    arm.animation_data.action = a
    _reset(arm)
    n = 24                                   # 1 s, 1 batut pe secunda
    for i in range(n + 1):
        f = 1 + i
        ph = 2 * math.pi * i / n
        a1 = 30.0 * math.cos(ph)
        a2 = 24.0 * math.cos(ph - 0.9)       # varful intarzie fata de umar
        bob = 0.025 * math.cos(ph - 1.6)
        pose = {
            "WingL1": ry(a1), "WingL2": ry(a2),
            "WingR1": ry(-a1), "WingR2": ry(-a2),
            "Body": [("move", Vector((0, 0, bob))), rx(2.0 * math.cos(ph - 0.8))],
            "Tail": rx(-5.0 * math.cos(ph - 1.4)),
            "Head": rx(-1.5 * math.cos(ph - 1.0)),
        }
        _key(arm, f, pose)
    stash_actions(arm, ("Fly",))
    _reset(arm)


def build_crow():
    _wipe()
    b = crow_geometry()
    obj = b.to_object("Crow_Mesh")
    lo0, hi0 = _bbox(obj)
    stats = finish(obj, bevel=0.0, origin="center", ao=AO_CROW, smooth_angle=None)
    lo1, hi1 = _bbox(obj)
    shift = (lo1 + hi1) * 0.5 - (lo0 + hi0) * 0.5
    print("  deplasarea din finish: %.3f %.3f %.3f" % tuple(shift))
    arm = crow_rig(obj, shift)
    crow_animate(arm)
    bpy.context.view_layer.update()
    d = obj.dimensions
    print("crow.glb  %d tris  %.2f (X) x %.2f (Y) x %.2f (Z) m" %
          (stats["tris"], d.x, d.y, d.z))
    print("GLB:  %s (%d B)" % export_glb([arm, obj], "kyoto/animals/crow.glb", animations=True))
    print("BLEND: %s (%d B)" % save_blend([arm, obj], "kyoto_crow.blend", compress=True))
    return stats["tris"]


import sys as _sys
_only = [a for a in _sys.argv[_sys.argv.index("--") + 1:]] if "--" in _sys.argv else []
_only = [a for a in _only if not a.endswith(".py") and not a.startswith("-")]
if not _only or "sika_deer" in _only:
    build_deer()
if not _only or "crow" in _only:
    build_crow()
