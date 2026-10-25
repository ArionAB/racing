"""Piese comune pentru garajul DESCHIS: figurina de sofer, rotile, exportul.

Se incarca din build-uri cu:
    exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
(globalele dio_lib sunt deja prezente; vezi run_build.py).

CONVENTII DE AXE (dio_lib: Blender +Y -> Godot -Z):
  Vehicul: fata spre Blender -Y (= Godot +Z), ca modelele RgsDev; se
  instantiaza cu `model_rotation_deg = 180`. Stanga masinii = Blender +X.
  Rotile au ORIGINEA IN CENTRU (Car le roteste in jurul originii si citeste
  `position.y` ca raza) si numele contin "wheel" + "front"/"rear".
  Sofer: fata spre Blender +Y (= Godot -Z), instantiat de cod sub `_visual`
  fara rotatie; originea fiecarei piese e in ARTICULATIA ei, originea
  ansamblului pe SEZUT.

`seat_godot((x, y, z))` traduce cota scaunului din spatiul de constructie in
`CarData.driver_seat`: dupa rotirea cu 180°, Blender (x, y, z) -> Godot
(-x, z, y). Soferul pe stanga masinii (Blender +X) ajunge la Godot -X.
"""

import math
import os
from mathutils import Matrix, Vector

# --- paleta comuna -----------------------------------------------------------
TIRE = VOLCANIC_BLACK
RIM = MARBLE_GREY
SKIN = SAND_LIGHT
PANTS = LOG_DARK
SHOE = VOLCANIC_BLACK
HELMET = FOAM_WHITE

AO_PART = dict(samples=12, dist=0.8, gradient="none", floor=0.45)
AO_BODY = dict(samples=16, dist=1.6, gradient="vertical", low=0.55,
               high=1.0, floor=0.35)
AO_WHEEL = dict(samples=8, dist=0.5, gradient="none", floor=0.5)

HERE_PARTS = os.path.join(PROJECT, "tools", "blender")


def rx(deg):
    return Matrix.Rotation(math.radians(deg), 3, "X")


def ry(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Y")


def rz(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


def part(name, build_fn, location, ao=None, bevel=0.02, *args):
    """O piesa ca obiect separat: geometrie LOCALA (centrata in articulatie
    sau in centrul rotii), `finish` fara mutarea originii, apoi obiectul e pus
    la locul lui in ansamblu. glTF scrie `location` pe nod."""
    b = Builder()
    build_fn(b, *args)
    obj = b.to_object(name)
    stats = finish(obj, bevel=bevel, ao=ao or AO_PART, origin=None)
    obj.location = Vector(location)
    print("  %-26s %5d tris  AO %.2f..%.2f" % (name, stats["tris"],
                                               stats["ao_min"], stats["ao_max"]))
    return obj


def remove_objects(objs):
    """Sterge obiectele (si mesh-urile lor), ca numele sa ramana stabile
    pentru urmatoarea varianta exportata in aceeasi sesiune."""
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o, do_unlink=True)
        if me is not None and me.users == 0:
            bpy.data.meshes.remove(me)


def seat_godot(seat):
    x, y, z = seat
    return (-x, z, y)


# --- roti -------------------------------------------------------------------
WHEEL_CORNERS = (
    ("Wheel_Front_Left", +1, -1), ("Wheel_Front_Right", -1, -1),
    ("Wheel_Rear_Left", +1, +1), ("Wheel_Rear_Right", -1, +1),
)


def make_wheel_fn(radius, width, segments=14, rim_frac=0.55):
    def build_wheel(b):
        b.cylinder((0.0, 0.0, 0.0), radius, width, TIRE, segments=segments, axis="X")
        b.cylinder((0.0, 0.0, 0.0), radius * rim_frac, width + 0.04, RIM,
                   segments=8, axis="X")
    return build_wheel


def vehicle_wheels(prefix, radius, width, half_track, y_front, y_rear,
                   half_track_rear=None, wheel_fn=None, wheel_bevel=0.02,
                   wheel_factory=None, radius_rear=None, width_rear=None):
    """Cele 4 roti ca noduri separate, cu origine in centru, la cota razei.

    `wheel_factory(radius, width)` intoarce functia de build a rotii (garajul
    v2: anvelopa rotunjita, garage_v2_parts.toy_wheel_fn); `wheel_fn` e o
    functie fixa, aceeasi pe toate patru. `wheel_bevel=0` cand forma isi aduce
    singura rotunjimea.

    `radius_rear` / `width_rear`: roti spate diferite (hot rod). Raza FIZICA
    o ia Car din PRIMA roata (Front_Left, vezi car.gd `_build_visual`); spatele
    mai mare e doar vizual, dar tot atinge solul, fiindca centrul lui sta la
    cota propriei raze."""
    out = []
    for name, sx, sy in WHEEL_CORNERS:
        rear = sy > 0
        r = radius_rear if (rear and radius_rear) else radius
        w = width_rear if (rear and width_rear) else width
        if wheel_factory is not None:
            fn = wheel_factory(r, w)
        else:
            fn = wheel_fn or make_wheel_fn(r, w)
        y = y_rear if rear else y_front
        ht = half_track_rear if (rear and half_track_rear is not None) else half_track
        out.append(part("%s_%s" % (prefix, name), fn, (sx * ht, y, r),
                        AO_WHEEL, wheel_bevel))
    return out


# Farurile si stopurile NU intra in corp: codul jocului le da un material
# emisiv, iar slotul de paleta e partajat cu vopseaua (stopuri CAR_RED pe
# caroserie rosie). `export_vehicle` pune aici cate un Builder gol inainte sa
# cheme corpul; corpul adauga cu `lamp_tail` / `lamp_head`. Contract Godot:
# noduri `<Prefix>_Lamp_Tail` / `<Prefix>_Lamp_Head`, copii directi ai radacinii,
# in pozitia de ansamblu (origin=None), fara "wheel" in nume.
LAMP_TAIL = None
LAMP_HEAD = None


def lamp_tail(center, size, slot=None, **kw):
    LAMP_TAIL.box(center, size, CAR_RED if slot is None else slot, **kw)


def lamp_head(center, size, slot=None, **kw):
    LAMP_HEAD.box(center, size, FOAM_WHITE if slot is None else slot, **kw)


def lamp_head_round(center, radius, depth, segments=8):
    LAMP_HEAD.cylinder(center, radius, depth, FOAM_WHITE, segments=segments, axis="Y")


def export_vehicle(prefix, build_body, wheel_spec, filename, seat, bevel=0.03,
                   bevel_angle=30.0):
    """Un vehicul: corpul (o singura piesa, origine la sol) + 4 roti + cele doua
    obiecte de lampi (`_Lamp_Tail`, `_Lamp_Head`; vezi LAMP_TAIL mai sus).
    `wheel_spec` = dict(radius, width, half_track, y_front, y_rear[, half_track_rear,
    wheel_fn | wheel_factory, wheel_bevel, radius_rear, width_rear]).
    `bevel_angle` peste 45 lasa nebevelate tuburile cu 8 laturi (fete la 45°):
    rotunjimea lor o da shade smooth, iar bevelul le-ar tripla triunghiurile.
    Tipareste `driver_seat` gata de pus in .tres."""
    print("%s:" % prefix)
    global LAMP_TAIL, LAMP_HEAD
    b = Builder()
    LAMP_TAIL, LAMP_HEAD = Builder(), Builder()
    build_body(b)
    body = b.to_object("%s_Body" % prefix)
    st = finish(body, bevel=bevel, bevel_angle=bevel_angle, ao=AO_BODY, origin=None)
    print("  %-26s %5d tris  AO %.2f..%.2f" % (body.name, st["tris"],
                                               st["ao_min"], st["ao_max"]))
    lamps = []
    for lb, tag in ((LAMP_TAIL, "Tail"), (LAMP_HEAD, "Head")):
        lo_ = lb.to_object("%s_Lamp_%s" % (prefix, tag))
        ls = finish(lo_, bevel=0.01, ao=AO_PART, origin=None)
        print("  %-26s %5d tris  AO %.2f..%.2f" % (lo_.name, ls["tris"],
                                                   ls["ao_min"], ls["ao_max"]))
        lamps.append(lo_)
    wheels = vehicle_wheels(prefix, **wheel_spec)
    objs = [body] + lamps + wheels
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector((min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z)))
            hi = Vector((max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z)))
    print("  gabarit: %.2f lung x %.2f lat x %.2f inalt  -> body_length=%.2f body_width=%.2f"
          % (hi.y - lo.y, hi.x - lo.x, hi.z, hi.y - lo.y, hi.x - lo.x))
    print("  driver_seat = Vector3(%.2f, %.2f, %.2f)" % seat_godot(seat))
    print("GLB:   %s (%d B)" % export_glb(objs, filename))
    return objs


# --- sofer: cote (m, Blender Z-up, fata spre +Y), origine pe sezut -----------
HIP_H = 0.22
TORSO_H = 0.48
TORSO_W = 0.50
HEAD = 0.40
SHOULDER = (0.31, 0.02, HIP_H + TORSO_H - 0.06)
HIP_JOINT = (0.13, 0.10, 0.06)
NECK_Z = HIP_H + TORSO_H


def build_hips(b):
    b.box((0.0, 0.0, HIP_H * 0.5), (0.46, 0.36, HIP_H), PANTS)


def build_torso(b, shirt):
    b.box((0.0, 0.0, TORSO_H * 0.5), (TORSO_W, 0.32, TORSO_H), shirt)
    b.box((0.0, 0.0, TORSO_H - 0.03), (0.30, 0.34, 0.06), HELMET)
    b.box((0.0, 0.165, TORSO_H * 0.5), (0.14, 0.02, TORSO_H - 0.10), HELMET)


def build_head(b, stripe):
    b.box((0.0, 0.0, 0.03 + HEAD * 0.5), (HEAD, HEAD * 0.92, HEAD), SKIN)
    b.box((0.0, -0.02, 0.03 + HEAD + 0.05), (HEAD + 0.06, HEAD, 0.14), HELMET)
    b.box((0.0, -0.02, 0.03 + HEAD + 0.12), (0.12, HEAD - 0.02, 0.03), stripe)
    b.box((0.0, HEAD * 0.46 + 0.005, 0.03 + HEAD * 0.66), (HEAD - 0.08, 0.02, 0.09),
          SHOE)


def build_arm(b, shirt):
    b.box((0.0, 0.24, -0.03), (0.15, 0.48, 0.15), shirt, rotation=rx(8.0))
    b.box((0.0, 0.50, -0.08), (0.13, 0.12, 0.13), SKIN)


def build_leg(b):
    b.box((0.0, 0.20, 0.0), (0.19, 0.42, 0.17), PANTS)
    b.box((0.0, 0.38, -0.20), (0.17, 0.17, 0.40), PANTS)
    b.box((0.0, 0.43, -0.42), (0.18, 0.28, 0.10), SHOE)


def build_driver(shirt, filename, stripe=None):
    """O varianta de figurina (culoarea tricoului), exportata. Numele pieselor
    sunt contractul cu Driver.PART_NAMES, deci fiecare varianta se construieste
    dupa ce precedenta a fost stearsa (`remove_objects`)."""
    print("Driver %s:" % filename)
    stripe = shirt if stripe is None else stripe
    objs = [
        part("Hips", build_hips, (0.0, 0.0, 0.0)),
        part("Torso", build_torso, (0.0, 0.0, HIP_H), AO_PART, 0.02, shirt),
        part("Head", build_head, (0.0, 0.0, NECK_Z), AO_PART, 0.02, stripe),
        part("Arm_L", build_arm, (-SHOULDER[0], SHOULDER[1], SHOULDER[2]),
             AO_PART, 0.02, shirt),
        part("Arm_R", build_arm, (SHOULDER[0], SHOULDER[1], SHOULDER[2]),
             AO_PART, 0.02, shirt),
        part("Leg_L", build_leg, (-HIP_JOINT[0], HIP_JOINT[1], HIP_JOINT[2])),
        part("Leg_R", build_leg, (HIP_JOINT[0], HIP_JOINT[1], HIP_JOINT[2])),
    ]
    print("GLB:   %s (%d B)" % export_glb(objs, filename))
    return objs


def seat_driver(driver_objs, seat):
    """Aseaza figurina (construita cu fata spre +Y) intr-un vehicul cu fata
    spre -Y, pe cota de scaun data — DOAR pentru previzualizare, dupa export."""
    for o in driver_objs:
        base = Vector(o.get("rest_loc", o.location))
        o["rest_loc"] = list(base)
        o.location = Vector((seat[0] - base.x, seat[1] - base.y, seat[2] + base.z))
        o.rotation_euler = (0.0, 0.0, math.pi)


def shift_objects(objs, dx):
    """Muta un vehicul intreg pe X (pentru poza de grup, dupa export)."""
    for o in objs:
        o.location = Vector((o.location.x + dx, o.location.y, o.location.z))
