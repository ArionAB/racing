"""Carrara -- utilajele (brief docs/asset_briefs/carrara_kit.md §1.1, §1.2).

  carrara/vehicles/quarry_truck.glb   basculanta rigida cu 2 blocuri de marmura (pilot)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_machines.py
Variabila de mediu CRR_ONLY=<piesa> reface doar piesa respectiva.

Axe: X latime, Y lungime (botul spre +Y in Blender = -Z in Godot), Z sus.
Originea pe centrul amprentei, la sol (offset calculat O DATA pe ansamblu).
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "carrara_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("CRR_ONLY", "")


# ---------------------------------------------------------------------------
# quarry_truck
# ---------------------------------------------------------------------------

AO_TRUCK = dict(samples=20, dist=1.2, gradient="vertical", low=0.62, high=1.0,
                power=0.8, floor=0.38, z_range=(0.0, 3.4))

# cote (Blender, metri; botul +Y). Anvelopa Kamaz: 2,68 x 3,13 x 8,0 -- aici
# latimea totala ~2,83 (roti la x = +-1,36, capacele jantelor +5 cm), lungimea
# ~7,7, inaltimea ~3,38 (blocurile).
TK_R = 0.86                 # raza rotii (fara crampoane)
TK_CZ = 0.90                # centrul rotii: crampoanele (4 cm) ating solul
TK_Y_FRONT = 2.75           # axa fata (sub cabina, ca pe plansa)
TK_Y_REAR = -2.15           # axa spate (roti duble)
TK_FLOOR0 = 1.84            # fata de jos a podelei benei (peste varful rotii 1,805)
TK_FLOOR1 = 1.98            # fata de sus a podelei = cota blocurilor


def build_quarry_truck():
    """LISTA DE ELEMENTE (decuparea `quarry_truck.png` + `_b`, scrisa INAINTE de
    geometrie; corecturile din kit §1.1 suprascriu planșa unde se bat cap in cap;
    runda 2: planșa arata un camion SCURT cu roti uriase si cabina lipita de
    grila, fara capota lunga):

     1. Roti: 6 (planșa: 4 vizibile + perechea a doua din spate). 2 in fata,
        singure, si 4 in spate, DUBLE (doua anvelope alaturate pe fiecare parte,
        ca pe planșa). Raza 0,86 m (jucarie: mari fata de caroserie), 14 laturi,
        14 crampoane pe anvelopa; janta de vopsea cu capac de rugina pe fata
        exterioara. Fara a treia axa.
     2. Cabina: scurta, 1 corp lat (2,3 m) peste rotile din fata, cu sera
        inclinata (parbriz retras 27 grade), geam lateral, luneta, 2 oglinzi
        mici in contur, un evacuator. Fara capota lunga: grila neagra pe fata
        cabinei, cu 3 bare de vopsea.
     3. Bara de protectie de rugina in fata (1 corp), miez de radiator sub cabina.
     4. Bena: rigida, deschisa deasupra: podea + 2 pereti laterali evazati
        (6 grade) + perete din spate RIDICAT (cu 0,30 m peste laterale: „muchia
        din spate ridicata") + perete din fata inalt care continua peste cabina
        cu o COPERTINA inclinata, ca pe planșa.
     5. Nervuri: 5 pe fiecare latura a benei (rugina) + sina de rugina pe
        muchia de sus a laterale si a peretelui din spate.
     6. Sasiu: 2 longeroane inguste, axe negre, subsasiu de rugina sub bena,
        2 balamale de rugina in spate, 2 cilindri hidraulici (negri) sub bena.
     7. Blocuri: 2 blocuri de marmura (1,85 x 1,80 x 1,40 si 1,80 x 1,70 x 1,36),
        unul langa peretele din fata, celalalt in spatele lui, usor rotite
        (+2 / -3 grade), al doilea cu un colt de sus spart. Fiecare pe doua
        noduri: treimea de jos pe MARBLE_GREY (`Truck_MarbleBase`), restul pe
        CORAL_SAND (`Truck_Marble`). Pe planșa sunt 3-4 blocuri in stiva;
        corectura de kit cere 2.
     8. Ce iese din contur: nimic. Oglinzile si evacuatorul raman in latimea
        rotilor (2,83); nimic atarna.
     9. Culori: vopseaua pe DRY_VEGETATION (galben spalacit, NU galbenul planșei),
        rugina pe RUST_METAL, geamuri/anvelope/hidraulica/grila pe
        VOLCANIC_BLACK, pete de praf SAND_SHADOW pe flancul benei. Fara text,
        cifre, logo-uri.
    """
    body, rust, black = Builder(), Builder(), Builder()
    marble, mbase = Builder(), Builder()

    # --- 6. sasiu ------------------------------------------------------------
    for sx in (-1, 1):
        rust.box((sx * 0.30, 0.0, 1.25), (0.25, 7.0, 0.40), CRR_RUST)        # longeroane
        rust.box((sx * 0.30, -1.2, 1.65), (0.25, 4.6, 0.40), CRR_RUST)       # subsasiu
        rust.box((sx * 0.90, -3.55, 1.55), (0.42, 0.40, 0.34), CRR_RUST)     # balamale
        black.beam((sx * 0.42, 0.55, 1.15), (sx * 0.42, 0.05, 1.82), 0.15, CRR_BLACK)  # hidraulica
    for yw, rr in ((TK_Y_FRONT, 0.11), (TK_Y_REAR, 0.13)):
        black.cylinder((0.0, yw, TK_CZ), rr, 2.10, CRR_BLACK, segments=8, axis="X")  # axe

    # --- 1. roti --------------------------------------------------------------
    for sx in (-1, 1):
        wheel_crr(black, body, rust, sx * 1.085, TK_Y_FRONT, TK_CZ, TK_R, 0.55, sx)
        wheel_crr(black, body, rust, sx * 1.14, TK_Y_REAR, TK_CZ, TK_R, 0.44, sx)   # exterioara
        wheel_crr(black, body, rust, sx * 0.67, TK_Y_REAR, TK_CZ, TK_R, 0.44, sx, outer=False)

    # --- 4. bena ---------------------------------------------------------------
    y_f, y_b = 1.77, -3.70                      # capetele benei (fata / spate)
    bl = y_f - y_b
    yc = (y_f + y_b) * 0.5
    body.box((0.0, yc, (TK_FLOOR0 + TK_FLOOR1) * 0.5), (2.44, bl, TK_FLOOR1 - TK_FLOOR0), CRR_PAINT)
    for sx in (-1, 1):
        tilted_box(body, (sx * 1.18, yc, 2.315), (0.12, bl, 0.67), CRR_PAINT, rot_y=sx * 6.0)
        # --- 5. sina de sus + nervuri -------------------------------------
        rust.box((sx * 1.22, yc, 2.68), (0.22, bl, 0.10), CRR_RUST)
        for k in range(5):
            yr = y_b + 0.5 + k * (bl - 1.0) / 4.0
            tilted_box(rust, (sx * 1.27, yr, 2.30), (0.06, 0.15, 0.60), CRR_RUST, rot_y=sx * 6.0)
    body.box((0.0, y_b + 0.06, 2.465), (2.44, 0.12, 0.97), CRR_PAINT)          # spate ridicat
    rust.box((0.0, y_b + 0.06, 2.98), (2.56, 0.20, 0.10), CRR_RUST)
    body.box((0.0, y_f - 0.07, 2.515), (2.44, 0.14, 1.07), CRR_PAINT)          # perete fata
    # copertina peste cabina, usor lasata spre fata
    tilted_box(body, (0.0, 2.65, 3.20), (2.60, 1.90, 0.14), CRR_PAINT, rot_x=-3.0)
    rust.box((0.0, 3.58, 3.13), (2.60, 0.10, 0.14), CRR_RUST)
    for sx in (-1, 1):
        rust.box((sx * 0.95, 2.2, 3.06), (0.12, 0.12, 0.26), CRR_RUST)         # console

    # --- 2. cabina -------------------------------------------------------------
    body.box((0.0, 2.725, 2.19), (2.30, 1.65, 0.62), CRR_PAINT)                 # caroseria, peste roti
    body.box((0.0, 3.05, 1.665), (1.60, 1.00, 0.43), CRR_PAINT)                 # miez de radiator
    cab_pts = []
    for sx in (-1, 1):
        for (yy, zz) in ((1.90, 2.50), (3.35, 2.50), (3.10, 3.00), (1.90, 3.00)):
            cab_pts.append(Vector((sx * 1.02, yy, zz)))
    _hull(body, cab_pts, CRR_PAINT)                                             # sera
    slope = math.degrees(math.atan2(0.25, 0.50))
    glen = math.hypot(0.25, 0.50)
    tilted_box(black, (0.0, 3.225 + 0.02, 2.75), (1.80, 0.05, glen * 0.84), CRR_BLACK, rot_x=slope)
    for sx in (-1, 1):
        black.box((sx * 1.035, 2.55, 2.75), (0.05, 1.00, 0.34), CRR_BLACK)     # geam lateral
        rust.box((sx * 1.19, 3.30, 2.78), (0.07, 0.06, 0.18), CRR_RUST)        # brat oglinda
        black.box((sx * 1.25, 3.30, 2.82), (0.08, 0.14, 0.32), CRR_BLACK)      # oglinda
    black.box((0.0, 1.88, 2.75), (1.50, 0.05, 0.34), CRR_BLACK)                # luneta
    rust.cylinder((1.02, 1.835, 2.70), 0.06, 0.70, CRR_RUST, segments=8)        # evacuator

    # --- 3. grila, bara ---------------------------------------------------------
    black.box((0.0, 3.57, 2.17), (1.60, 0.06, 0.42), CRR_BLACK)                # grila
    for k in range(3):
        body.box((0.0, 3.605, 2.04 + k * 0.13), (1.64, 0.05, 0.04), CRR_PAINT)
    rust.box((0.0, 3.78, 1.55), (2.30, 0.40, 0.36), CRR_RUST)                  # bara

    # praf pe flancul benei (pete mici)
    for sx in (-1, 1):
        body.box((sx * 1.27, -1.5, 2.05), (0.02, 2.4, 0.20), CRR_DUST)

    # --- 7. blocurile ------------------------------------------------------------
    cut_marble_block(marble, mbase, (0.0, 0.70), (1.85, 1.80, 1.40), z0=TK_FLOOR1, yaw_deg=2.0)
    cut_marble_block(marble, mbase, (0.02, -1.45), (1.80, 1.70, 1.36), z0=TK_FLOOR1, yaw_deg=-3.0,
                     chip=0.28, chip_corner=(-1, -1))

    return [body.to_object("Truck_Body"), rust.to_object("Truck_Rust"),
            black.to_object("Truck_Black"), marble.to_object("Truck_Marble"),
            mbase.to_object("Truck_MarbleBase")]


clear_built()
if not ONLY or ONLY == "quarry_truck":
    emit_crr(build_quarry_truck(), "vehicles/quarry_truck.glb", AO_TRUCK,
             bevel=0.035, bevels={"_Marble": 0.0, "_MarbleBase": 0.0, "_Black": 0.03},
             smooth_angle=40.0)
    clear_built()
report_crr()
