"""Prototipul „sofer + ragdoll": buggy-ul deschis si figurina de jucarie.

  Toy_Buggy   vehicles/toy_buggy.glb
              Body + 4 roti ca noduri separate (Wheel_Front_Left, ...)
  Toy_Driver  vehicles/toy_driver.glb
              7 piese RIGIDE ca noduri separate: Hips, Torso, Head,
              Arm_L, Arm_R, Leg_L, Leg_R

De ce piese rigide si nu un schelet skinnuit: figurina e o JUCARIE, adica are
membre din bucati — exact ce cere un ragdoll din corpuri rigide legate cu
articulatii. Acelasi GLB hraneste si soferul asezat (piesele se rotesc
procedural din umar/gat/sold) si ragdoll-ul (fiecare piesa devine un
RigidBody3D). Fara skinning, fara PhysicalBone, fara animatii coapte.

CONVENTII DE AXE (vezi antetul dio_lib: Blender +Y -> Godot -Z):

  Buggy: fata spre Blender -Y (= Godot +Z), ca modelele RgsDev din garaj, si
  se instantiaza cu `model_rotation_deg = 180` — asa `Car._build_visual`
  gaseste rotile dupa nume si le mapeaza corect (x>0 in model = stanga
  masinii). Rotile au ORIGINEA IN CENTRUL LOR (Car le roteste in jurul
  originii si citeste `position.y` ca raza), corpul are originea la sol.

  Sofer: fata spre Blender +Y (= Godot -Z), fiindca e instantiat de cod sub
  `_visual`, fara rotatie. ORIGINEA fiecarei piese e in ARTICULATIA ei
  (umar, gat, sold), nu in centrul geometriei: soferul asezat roteste piesa
  in jurul originii, iar ragdoll-ul pune articulatia fizica tot acolo.
  Originea ansamblului e pe SEZUT (baza soldurilor), ca `CarData.driver_seat`
  sa fie o cota de scaun, nu o cota de picioare.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_toy_buggy.py
"""

import math
import os
from mathutils import Matrix, Vector

# --- paleta -----------------------------------------------------------------
BUGGY_PAINT = CAR_YELLOW      # caroseria: accent de masina, nu culoare de decor
BUGGY_CAGE = VOLCANIC_BLACK   # rollcage + bara: negru, nu ROCK_DARK (iese rugina)
BUGGY_SEAT = LOG_DARK
BUGGY_TRIM = FOAM_WHITE       # capota/numere
TIRE = VOLCANIC_BLACK
RIM = MARBLE_GREY

SKIN = SAND_LIGHT
SHIRT = CAR_RED
PANTS = LOG_DARK
SHOE = VOLCANIC_BLACK
HELMET = FOAM_WHITE
HELMET_STRIPE = CAR_RED

AO_PART = dict(samples=12, dist=0.8, gradient="none", floor=0.45)
AO_BODY = dict(samples=16, dist=1.6, gradient="vertical", low=0.55,
               high=1.0, floor=0.35)

# --- buggy: cote (m, Blender Z-up, fata spre -Y) ----------------------------
WHEEL_R = 0.42
WHEEL_W = 0.36
WHEEL_X = 0.86                 # semi-ecartament (centrul rotii)
WHEEL_Y_FRONT = -1.05          # fata e -Y
WHEEL_Y_REAR = 1.05
TUB_W, TUB_L, TUB_H = 1.38, 2.5, 0.42
TUB_Z0 = 0.34                  # talpa cuvei (garda la sol)
SEAT_Z = TUB_Z0 + 0.30         # unde se aseaza soldurile soferului
SEAT_Y = 0.22                  # putin spre spate fata de centrul cuvei


def rx(deg):
    return Matrix.Rotation(math.radians(deg), 3, "X")


def ry(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Y")


def build_buggy_body(b):
    """Cuva, capota inclinata, cutia motorului, rollcage, bare, volan, scaun."""
    z_mid = TUB_Z0 + TUB_H * 0.5
    # cuva principala
    b.box((0.0, 0.0, z_mid), (TUB_W, TUB_L, TUB_H), BUGGY_PAINT)
    # podeaua/sasiul, putin mai lat (aripi mici peste roti)
    b.box((0.0, 0.0, TUB_Z0 + 0.04), (TUB_W + 0.36, TUB_L - 0.3, 0.08), BUGGY_CAGE)
    # capota din fata, inclinata in jos spre bot
    b.box((0.0, -1.42, TUB_Z0 + 0.36), (TUB_W - 0.1, 0.62, 0.16), BUGGY_PAINT,
          rotation=rx(-14.0))
    # bot: bara si farurile
    b.box((0.0, -1.78, TUB_Z0 + 0.22), (TUB_W + 0.1, 0.10, 0.12), BUGGY_CAGE)
    for sx in (-1, 1):
        b.box((sx * 0.42, -1.70, TUB_Z0 + 0.40), (0.20, 0.08, 0.16), BUGGY_TRIM)
    # numarul de pe capota (o placa alba)
    b.box((0.0, -1.20, TUB_Z0 + TUB_H + 0.005), (0.44, 0.34, 0.02), BUGGY_TRIM)
    # cutia motorului din spate
    b.box((0.0, 1.05, TUB_Z0 + TUB_H + 0.12), (TUB_W - 0.30, 0.62, 0.36), BUGGY_CAGE)
    b.box((0.0, 1.05, TUB_Z0 + TUB_H + 0.34), (0.5, 0.36, 0.12), RIM)
    # bara din spate
    b.box((0.0, 1.62, TUB_Z0 + 0.22), (TUB_W + 0.1, 0.10, 0.12), BUGGY_CAGE)
    # scaunul: sezut + spatar
    b.box((0.0, SEAT_Y, SEAT_Z - 0.05), (0.62, 0.56, 0.10), BUGGY_SEAT)
    b.box((0.0, SEAT_Y + 0.30, SEAT_Z + 0.32), (0.62, 0.10, 0.66), BUGGY_SEAT,
          rotation=rx(-8.0))
    # volanul: torus pe o coloana
    col_base = (0.0, SEAT_Y - 0.62, TUB_Z0 + TUB_H)
    col_top = (0.0, SEAT_Y - 0.50, SEAT_Z + 0.46)
    b.beam(col_base, col_top, 0.05, BUGGY_CAGE)
    # volanul e un inel cu axa pe Y (aproape vertical, spre sofer)
    b.torus(col_top, 0.19, 0.03, BUGGY_CAGE, major_seg=10, minor_seg=5, axis="Y")
    # rollcage: doua arcuri (spate si mijloc) legate cu o bara longitudinala
    cage_t = 0.06
    top_z = SEAT_Z + 0.95
    for cy in (SEAT_Y + 0.55, SEAT_Y - 0.55):
        for sx in (-1, 1):
            base = (sx * (TUB_W * 0.5 - 0.06), cy, TUB_Z0 + TUB_H)
            top = (sx * (TUB_W * 0.5 - 0.16), cy, top_z)
            b.beam(base, top, cage_t, BUGGY_CAGE)
        b.beam((-(TUB_W * 0.5 - 0.16), cy, top_z),
               ((TUB_W * 0.5 - 0.16), cy, top_z), cage_t, BUGGY_CAGE)
    for sx in (-1, 1):
        b.beam((sx * (TUB_W * 0.5 - 0.16), SEAT_Y + 0.55, top_z),
               (sx * (TUB_W * 0.5 - 0.16), SEAT_Y - 0.55, top_z), cage_t, BUGGY_CAGE)
        # contrafisa spre capota
        b.beam((sx * (TUB_W * 0.5 - 0.16), SEAT_Y - 0.55, top_z),
               (sx * (TUB_W * 0.5 - 0.10), -1.15, TUB_Z0 + TUB_H + 0.02),
               cage_t * 0.8, BUGGY_CAGE)
    # amortizoare vizibile langa roti (tije)
    for sy in (WHEEL_Y_FRONT, WHEEL_Y_REAR):
        for sx in (-1, 1):
            b.beam((sx * (TUB_W * 0.5 + 0.05), sy, TUB_Z0 + 0.10),
                   (sx * (WHEEL_X - 0.20), sy, WHEEL_R), 0.05, RIM)


def build_wheel(b):
    """Roata centrata in origine, axa pe X."""
    b.cylinder((0.0, 0.0, 0.0), WHEEL_R, WHEEL_W, TIRE, segments=14, axis="X")
    b.cylinder((0.0, 0.0, 0.0), WHEEL_R * 0.55, WHEEL_W + 0.04, RIM, segments=8,
               axis="X")


# --- sofer: cote (m, Blender Z-up, fata spre +Y), origine pe sezut -----------
HIP_H = 0.22
TORSO_H = 0.48
TORSO_W = 0.50
HEAD = 0.40
SHOULDER = (0.31, 0.02, HIP_H + TORSO_H - 0.06)   # x, y, z al umarului (stanga = -x)
HIP_JOINT = (0.13, 0.10, 0.06)                     # articulatia soldului
NECK_Z = HIP_H + TORSO_H


def build_hips(b):
    b.box((0.0, 0.0, HIP_H * 0.5), (0.46, 0.36, HIP_H), PANTS)


def build_torso(b):
    # originea in articulatia sold-trunchi (z = HIP_H)
    b.box((0.0, 0.0, TORSO_H * 0.5), (TORSO_W, 0.32, TORSO_H), SHIRT)
    # gulerul si o dunga pe piept, ca sa aiba fata
    b.box((0.0, 0.0, TORSO_H - 0.03), (0.30, 0.34, 0.06), HELMET)
    b.box((0.0, 0.165, TORSO_H * 0.5), (0.14, 0.02, TORSO_H - 0.10), HELMET)


def build_head(b):
    # originea in gat
    b.box((0.0, 0.0, 0.03 + HEAD * 0.5), (HEAD, HEAD * 0.92, HEAD), SKIN)
    # casca: calota peste crestet, cu o dunga rosie
    b.box((0.0, -0.02, 0.03 + HEAD + 0.05), (HEAD + 0.06, HEAD, 0.14), HELMET)
    b.box((0.0, -0.02, 0.03 + HEAD + 0.12), (0.12, HEAD - 0.02, 0.03), HELMET_STRIPE)
    # vizor (dunga inchisa in fata, la nivelul ochilor)
    b.box((0.0, HEAD * 0.46 + 0.005, 0.03 + HEAD * 0.66), (HEAD - 0.08, 0.02, 0.09),
          SHOE)


def build_arm(b, side):
    """Bratul intins inainte spre volan; originea in umar. `side` = -1 stanga."""
    # bratul (o singura piesa, usor coborat)
    b.box((0.0, 0.24, -0.03), (0.15, 0.48, 0.15), SHIRT, rotation=rx(8.0))
    # mana
    b.box((0.0, 0.50, -0.08), (0.13, 0.12, 0.13), SKIN)


def build_leg(b, side):
    """Coapsa inainte + gamba in jos + pantof; originea in sold."""
    b.box((0.0, 0.20, 0.0), (0.19, 0.42, 0.17), PANTS)
    b.box((0.0, 0.38, -0.20), (0.17, 0.17, 0.40), PANTS)
    b.box((0.0, 0.43, -0.42), (0.18, 0.28, 0.10), SHOE)


def part(name, build_fn, location, ao=AO_PART, bevel=0.02, *args):
    """O piesa: geometrie LOCALA (centrata in articulatie), `finish` fara
    mutarea originii, apoi obiectul e pus la locul lui in ansamblu."""
    b = Builder()
    build_fn(b, *args)
    obj = b.to_object(name)
    stats = finish(obj, bevel=bevel, ao=ao, origin=None)
    obj.location = Vector(location)
    print("  %-18s %5d tris  AO %.2f..%.2f" % (name, stats["tris"],
                                               stats["ao_min"], stats["ao_max"]))
    return obj


if __name__ == "__main__":
    clear_built()

    # ---------------- buggy ----------------
    print("Toy_Buggy:")
    bb = Builder()
    build_buggy_body(bb)
    body = bb.to_object("Body")
    st = finish(body, bevel=0.03, ao=AO_BODY, origin=None)
    print("  %-18s %5d tris  AO %.2f..%.2f" % ("Body", st["tris"],
                                               st["ao_min"], st["ao_max"]))
    wheels = []
    for name, x, y in (("Wheel_Front_Left", WHEEL_X, WHEEL_Y_FRONT),
                       ("Wheel_Front_Right", -WHEEL_X, WHEEL_Y_FRONT),
                       ("Wheel_Rear_Left", WHEEL_X, WHEEL_Y_REAR),
                       ("Wheel_Rear_Right", -WHEEL_X, WHEEL_Y_REAR)):
        wheels.append(part(name, build_wheel, (x, y, WHEEL_R),
                           ao=dict(samples=8, dist=0.5, gradient="none", floor=0.5),
                           bevel=0.02))
    buggy = [body] + wheels
    bpy.context.view_layer.update()
    print("  gabarit: %.2f lung x %.2f lat x %.2f inalt"
          % (TUB_L + 1.2, 2 * WHEEL_X + WHEEL_W, SEAT_Z + 0.95))
    print("  scaun (Blender): y=%.2f z=%.2f  -> Godot driver_seat=(0, %.2f, %.2f)"
          % (SEAT_Y, SEAT_Z, SEAT_Z, SEAT_Y))
    print("GLB:   %s (%d B)" % export_glb(buggy, "vehicles/toy_buggy.glb"))

    # ---------------- sofer ----------------
    print("Toy_Driver:")
    driver = [
        part("Hips", build_hips, (0.0, 0.0, 0.0)),
        part("Torso", build_torso, (0.0, 0.0, HIP_H)),
        part("Head", build_head, (0.0, 0.0, NECK_Z)),
        part("Arm_L", build_arm, (-SHOULDER[0], SHOULDER[1], SHOULDER[2]),
             AO_PART, 0.02, -1),
        part("Arm_R", build_arm, (SHOULDER[0], SHOULDER[1], SHOULDER[2]),
             AO_PART, 0.02, 1),
        part("Leg_L", build_leg, (-HIP_JOINT[0], HIP_JOINT[1], HIP_JOINT[2]),
             AO_PART, 0.02, -1),
        part("Leg_R", build_leg, (HIP_JOINT[0], HIP_JOINT[1], HIP_JOINT[2]),
             AO_PART, 0.02, 1),
    ]
    print("GLB:   %s (%d B)" % export_glb(driver, "vehicles/toy_driver.glb"))

    # ---------------- preview ----------------
    g = dict(globals())
    exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                           "preview.py")).read(), g)
    # soferul asezat in buggy, ca sa se vada proportiile impreuna
    for o in driver:
        o.location = Vector((o.location.x, -o.location.y + SEAT_Y,
                             o.location.z + SEAT_Z))
        o.rotation_euler = (0.0, 0.0, math.pi)  # fata buggy-ului e -Y
    out = os.path.join(PROJECT, "snapshots", "toy_buggy_preview.png")
    g["shot"](buggy + driver, out, azimuth=35.0, elevation=16.0)
    out2 = os.path.join(PROJECT, "snapshots", "toy_buggy_preview_front.png")
    g["shot"](buggy + driver, out2, azimuth=200.0, elevation=12.0)
    print("PREVIEW: %s" % out)
