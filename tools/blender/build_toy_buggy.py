"""Buggy-ul deschis — prima masina a garajului deschis (prototipul sofer +
ragdoll). Figurina de sofer si contractul rotilor stau in toy_driver_parts.py
(comune cu build_open_garage.py, care face restul garajului).

  Toy_Buggy   vehicles/toy_buggy.glb
              Body + 4 roti ca noduri separate (Wheel_Front_Left, ...)

De ce piese rigide si nu un schelet skinnuit pentru sofer: figurina e o
JUCARIE, adica are membre din bucati — exact ce cere un ragdoll din corpuri
rigide legate cu articulatii. Acelasi GLB hraneste si soferul asezat (piesele
se rotesc procedural din umar/gat/sold) si ragdoll-ul (fiecare piesa devine
un RigidBody3D). Fara skinning, fara PhysicalBone, fara animatii coapte.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_toy_buggy.py

Verificare (ambele cu `--origin=assembly`; doua avertismente sunt ASTEPTATE):
    python tools/blender/verify_glb.py assets/models/vehicles/toy_buggy.glb 3000 --origin=assembly
    python tools/blender/verify_glb.py assets/models/vehicles/toy_driver.glb 1200 --origin=assembly
  - vehicul: „cel mai jos punct e la Y=0.011" — rotile sunt cilindri cu 14
    fete, tangenta la sol nu e un vertex; 1 cm nu se vede.
  - sofer: „slot 14 (car_red) ILEGAL in decor" — soferul NU e decor, e parte
    din masina, deci accentul de masina e chiar slotul corect; si „ansamblul
    nu atinge solul" — originea e pe SEZUT prin contract, picioarele atarna
    sub ea.
"""

import math
import os
from mathutils import Matrix, Vector

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "toy_driver_parts.py")).read())

BUGGY_PAINT = CAR_YELLOW      # caroseria: accent de masina, nu culoare de decor
BUGGY_CAGE = VOLCANIC_BLACK   # rollcage + bara: negru, nu ROCK_DARK (iese rugina)
BUGGY_SEAT = LOG_DARK
BUGGY_TRIM = FOAM_WHITE       # capota/numere

WHEEL_R = 0.42
WHEEL_W = 0.36
WHEEL_X = 0.86                 # semi-ecartament (centrul rotii)
WHEEL_Y_FRONT = -1.05          # fata e -Y
WHEEL_Y_REAR = 1.05
TUB_W, TUB_L, TUB_H = 1.38, 2.5, 0.42
TUB_Z0 = 0.34                  # talpa cuvei (garda la sol)
SEAT_Z = TUB_Z0 + 0.30         # unde se aseaza soldurile soferului
SEAT_Y = 0.22                  # putin spre spate fata de centrul cuvei
SEAT = (0.0, SEAT_Y, SEAT_Z)


def build_buggy_body(b):
    """Cuva, capota inclinata, cutia motorului, rollcage, bare, volan, scaun."""
    z_mid = TUB_Z0 + TUB_H * 0.5
    b.box((0.0, 0.0, z_mid), (TUB_W, TUB_L, TUB_H), BUGGY_PAINT)
    b.box((0.0, 0.0, TUB_Z0 + 0.04), (TUB_W + 0.36, TUB_L - 0.3, 0.08), BUGGY_CAGE)
    b.box((0.0, -1.42, TUB_Z0 + 0.36), (TUB_W - 0.1, 0.62, 0.16), BUGGY_PAINT,
          rotation=rx(-14.0))
    b.box((0.0, -1.78, TUB_Z0 + 0.22), (TUB_W + 0.1, 0.10, 0.12), BUGGY_CAGE)
    for sx in (-1, 1):
        b.box((sx * 0.42, -1.70, TUB_Z0 + 0.40), (0.20, 0.08, 0.16), BUGGY_TRIM)
    # faruri pe placutele albe din bot (fata e -Y) si stopuri pe spatele cuvei:
    # obiecte separate (`Buggy_Lamp_Head` / `_Lamp_Tail`), ca jocul sa le
    # aprinda. Fata lor iese ~8 mm in fata suprafetei din spate.
    for sx in (-1, 1):
        lamp_head((sx * 0.42, -1.733, TUB_Z0 + 0.40), (0.14, 0.03, 0.10))
        lamp_tail((sx * 0.50, TUB_L * 0.5 - 0.007, TUB_Z0 + 0.26), (0.20, 0.03, 0.10))
    b.box((0.0, -1.20, TUB_Z0 + TUB_H + 0.005), (0.44, 0.34, 0.02), BUGGY_TRIM)
    b.box((0.0, 1.05, TUB_Z0 + TUB_H + 0.12), (TUB_W - 0.30, 0.62, 0.36), BUGGY_CAGE)
    b.box((0.0, 1.05, TUB_Z0 + TUB_H + 0.34), (0.5, 0.36, 0.12), RIM)
    b.box((0.0, 1.62, TUB_Z0 + 0.22), (TUB_W + 0.1, 0.10, 0.12), BUGGY_CAGE)
    b.box((0.0, SEAT_Y, SEAT_Z - 0.05), (0.62, 0.56, 0.10), BUGGY_SEAT)
    b.box((0.0, SEAT_Y + 0.30, SEAT_Z + 0.32), (0.62, 0.10, 0.66), BUGGY_SEAT,
          rotation=rx(-8.0))
    col_base = (0.0, SEAT_Y - 0.62, TUB_Z0 + TUB_H)
    col_top = (0.0, SEAT_Y - 0.50, SEAT_Z + 0.46)
    b.beam(col_base, col_top, 0.05, BUGGY_CAGE)
    b.torus(col_top, 0.19, 0.03, BUGGY_CAGE, major_seg=10, minor_seg=5, axis="Y")
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
        b.beam((sx * (TUB_W * 0.5 - 0.16), SEAT_Y - 0.55, top_z),
               (sx * (TUB_W * 0.5 - 0.10), -1.15, TUB_Z0 + TUB_H + 0.02),
               cage_t * 0.8, BUGGY_CAGE)
    for sy in (WHEEL_Y_FRONT, WHEEL_Y_REAR):
        for sx in (-1, 1):
            b.beam((sx * (TUB_W * 0.5 + 0.05), sy, TUB_Z0 + 0.10),
                   (sx * (WHEEL_X - 0.20), sy, WHEEL_R), 0.05, RIM)


if __name__ == "__main__":
    clear_built()
    buggy = export_vehicle(
        "Buggy", build_buggy_body,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=WHEEL_X,
             y_front=WHEEL_Y_FRONT, y_rear=WHEEL_Y_REAR),
        "vehicles/toy_buggy.glb", SEAT)
    # Figurina buggy-ului (tricou albastru pe caroserie galbena); GLB-ul e
    # exportat si de build_open_garage.py, identic.
    driver = build_driver(CAR_BLUE, "vehicles/toy_driver_blue.glb")

    g = dict(globals())
    exec(open(os.path.join(HERE_PARTS, "preview.py")).read(), g)
    seat_driver(driver, SEAT)
    out = os.path.join(PROJECT, "snapshots", "toy_buggy_preview.png")
    g["shot"](buggy + driver, out, azimuth=35.0, elevation=16.0)
    g["shot"](buggy + driver, os.path.join(PROJECT, "snapshots", "toy_buggy_preview_front.png"),
              azimuth=200.0, elevation=12.0)
    print("PREVIEW: %s" % out)
