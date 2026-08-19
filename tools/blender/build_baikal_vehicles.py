"""Baikal — hovercraft, tren, pilon si poarta de start (planşa, pozitiile 7-10).

  HovercraftKhivus  vehicles/hovercraft_khivus.glb
                    Khivus_Skirt / Khivus_Hull / Khivus_Cabin / Khivus_Fan
  BaikalTrain       vehicles/train_baikal.glb
                    Baikal_Loco / Baikal_Carriage_A / Baikal_Carriage_B
  PowerPylon        structures/power_pylon_soviet.glb   Pylon_Soviet
  LogStartGate      structures/start_gate_logs.glb      StartGate_Logs

Orientarea e CONTRACT, nu preferinta:
  - hovercraftul si trenul merg pe PathMover / TrainHazard, care deplaseaza
    piesa spre +X local (vezi build_train.py, scenes/hazards/train_hazard.gd),
    deci botul ambelor priveste spre +X in Blender.
  - poarta de start se vede din masina la pornire: fata ei e spre +Y (= -Z in
    Godot), ca la toate cladirile.

Trenul de aici NU inlocuieste `vehicles/train.glb` (garnitura de desert, din
pachetul Quaternius): e o garnitura sovietica verde, proprie pistei Baikal,
si iese din Builder ca restul kitului.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_vehicles.py
"""

import math
from mathutils import Matrix, Vector

AO_VEHICLE = dict(samples=26, dist=4.0, gradient="vertical",
                  low=0.48, high=1.00, power=0.9, floor=0.15)
AO_STEEL = dict(samples=22, dist=6.0, gradient="vertical",
                low=0.50, high=1.00, power=0.85, floor=0.20)
AO_WOOD = dict(samples=24, dist=4.0, gradient="vertical",
               low=0.45, high=1.00, power=0.9, floor=0.14)

GLASS = ASPHALT      # slotul cel mai inchis = golul geamului (regula proiectului)

# Dunga si farul garniturii folosesc DRY_VEGETATION (13, #AF9F4E), nu
# CAR_YELLOW (16). Prima versiune lua galbenul pur de masina si `verify_glb` a
# semnalat-o corect: 14-16 sunt rezervate masinilor (style_bible §1), ca ele sa
# ramana cele mai saturate obiecte din cadru. Un tren de 38 m cu dunga pe toata
# lungimea nu e un accent, e o suprafata mare — exact cazul pe care regula il
# apara. Ocrul palid e si mai aproape de livreaua sovietica reala, decolorata.
#
# Panglicile serge SUNT o exceptie asumata la aceeasi regula (vezi
# build_baikal_shaman.py si nota din scripts/palette.gd): acolo e vorba de
# fasii de 60-90 cm care semnaleaza VANTUL, adica o mecanica. Diferenta dintre
# cele doua cazuri e suprafata, nu principiul.


# ============================================================ Hovercraft Khivus
# 9 x 3.5 x 3 m. Fusta neagra gonflata, cabina alb-portocalie cu geamuri,
# elice carenata in spate cu grila. Botul spre +X.

def build_hovercraft():
    clear_built()

    # --- fusta gonflata ----------------------------------------------------
    # Nu o cutie: fusta e un tor turtit care iese in afara cocii pe tot conturul.
    # Silueta ei (bureletul care se umfla la sol) e ce face ambarcatiunea sa
    # citeasca drept hovercraft si nu barca.
    b = Builder()
    # `torus` e circular; fusta reala e ovala (mai lunga decat lata). O
    # obtinem construind inelul si scalandu-i varfurile pe X dupa aceea —
    # primitiva ramane simpla, iar forma iese corecta.
    ring = b.torus((0.0, 0.0, 0.42), major_r=2.8, minor_r=0.46,
                   slot=VOLCANIC_BLACK, major_seg=14, minor_seg=6)
    for v in {v for f in ring for v in f.verts}:
        v.co.x *= 1.52
    # inchiderea de dedesubt, ca sa nu se vada prin inelul torului
    b.box((0.0, 0.0, 0.34), (8.2, 3.0, 0.42), VOLCANIC_BLACK)
    skirt = b.to_object("Khivus_Skirt")
    finish(skirt, bevel=0.04, ao=AO_VEHICLE, origin=None)

    # --- coca ---------------------------------------------------------------
    b = Builder()
    # platforma, cu prova ascutita spre +X
    hull = [(4.5, 0.0), (3.4, 1.45), (-3.6, 1.45), (-4.2, 1.05),
            (-4.2, -1.05), (-3.6, -1.45), (3.4, -1.45)]
    b.prism([(x, y) for x, y in hull], 0.62, FOAM_WHITE,
            center=(0.0, 0.0, 1.02))
    # banda portocalie de bordaj — accentul saturat cerut de brief
    b.prism([(x * 1.01, y * 1.03) for x, y in hull], 0.20, KERB_RED,
            center=(0.0, 0.0, 0.80))
    hull_o = b.to_object("Khivus_Hull")
    finish(hull_o, bevel=0.03, ao=AO_VEHICLE, origin=None)

    # --- cabina -------------------------------------------------------------
    b = Builder()
    # corp de cabina cu parbriz inclinat: peretele din fata e o placa rotita,
    # nu verticala — inclinarea e ce da senzatia de viteza pe o piesa statica.
    b.box((0.55, 0.0, 2.00), (4.6, 2.5, 1.35), FOAM_WHITE)
    b.box((2.95, 0.0, 1.98), (0.9, 2.4, 1.30), FOAM_WHITE,
          rotation=Matrix.Rotation(math.radians(-24.0), 3, "Y"))
    # acoperisul, usor bombat
    b.box((0.55, 0.0, 2.70), (4.3, 2.3, 0.16), KERB_RED)
    # geamuri: parbriz + trei laterale pe fiecare parte
    b.box((3.12, 0.0, 2.10), (0.10, 2.05, 0.80), GLASS,
          rotation=Matrix.Rotation(math.radians(-24.0), 3, "Y"))
    for sy in (-1, 1):
        for i in range(3):
            b.box((1.55 - i * 1.25, sy * 1.27, 2.12), (0.95, 0.09, 0.66), GLASS)
    # usa
    b.box((-0.55, 1.27, 1.70), (0.85, 0.10, 1.85), KERB_RED)
    cabin = b.to_object("Khivus_Cabin")
    finish(cabin, bevel=0.03, ao=AO_VEHICLE, origin=None)

    # --- elicea carenata din spate -----------------------------------------
    b = Builder()
    duct_x = -3.95
    # inelul de carenaj
    b.torus((duct_x, 0.0, 2.15), major_r=1.28, minor_r=0.17, slot=FOAM_WHITE,
            major_seg=12, minor_seg=5, axis="X")
    # butucul + 6 pale
    b.cylinder((duct_x, 0.0, 2.15), 0.22, 0.42, VOLCANIC_BLACK, segments=8,
               axis="X")
    for i in range(6):
        a = math.radians(i * 60.0)
        b.box((duct_x, math.cos(a) * 0.62, 2.15 + math.sin(a) * 0.62),
              (0.07, 1.05, 0.20), PAINTED,
              rotation=Matrix.Rotation(a, 3, "X")
                       @ Matrix.Rotation(math.radians(22.0), 3, "Y"))
    # grila de protectie: 5 bare verticale peste gura de aspiratie
    for i in range(5):
        yy = -0.95 + i * 0.475
        b.box((duct_x - 0.28, yy, 2.15), (0.06, 0.06, 2.3), RUST)
    # deriva/carma dubla, in spatele elicei
    for sy in (-1, 1):
        b.box((duct_x - 0.55, sy * 0.85, 2.15), (0.5, 0.08, 1.9), KERB_RED)
    fan = b.to_object("Khivus_Fan")
    finish(fan, bevel=0.02, ao=AO_VEHICLE, origin=None)

    objs = [skirt, hull_o, cabin, fan]
    _drop_to_zero(objs)
    print("HovercraftKhivus: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "vehicles/hovercraft_khivus.glb")
    save_blend(objs, "baikal_hovercraft.blend")
    return objs


def _drop_to_zero(objs):
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box)
             for o in objs)
    for o in objs:
        o.location.z -= lo


# ============================================================ Trenul
# Locomotiva M62 (14 m, bot rotund, far galben) + 2 vagoane verzi de 12 m cu
# dunga galbena. Botul spre +X, baza rotilor la z=0 — contractul TrainHazard.

RAIL_GAUGE = 1.52
BOGIE_R = 0.52


def _bogie(b, x, slot=VOLCANIC_BLACK):
    """Boghiu: sasiu + doua osii. La distanta de joc rotile sunt siluete, deci
    cilindri cu 8 segmente — nu 32."""
    b.box((x, 0.0, BOGIE_R + 0.30), (2.6, 2.0, 0.42), slot)
    for dx in (-0.85, 0.85):
        for sy in (-1, 1):
            b.cylinder((x + dx, sy * RAIL_GAUGE * 0.5, BOGIE_R), BOGIE_R, 0.16,
                       slot, segments=8, axis="Y")


def build_train():
    clear_built()
    objs = []

    # --- locomotiva ---------------------------------------------------------
    b = Builder()
    L = 14.0
    floor_z = BOGIE_R + 0.55
    body_h = 2.55
    # sasiul
    b.box((0.0, 0.0, floor_z - 0.18), (L, 2.9, 0.36), VOLCANIC_BLACK)
    # capota lunga + cabina inalta (silueta M62: cabina retrasa spre spate)
    b.box((-0.6, 0.0, floor_z + body_h * 0.5), (L - 2.6, 2.85, body_h),
          TROPICAL_GREEN)
    b.box((-4.6, 0.0, floor_z + body_h + 0.42), (3.4, 2.85, 0.84),
          TROPICAL_GREEN)
    # BOTUL ROTUND — semnatura M62. Prova tesita din trei placi rotite, nu o
    # cutie: cu fata plata locomotiva citeste ca un container pe roti.
    b.box((L * 0.5 - 1.35, 0.0, floor_z + body_h * 0.5),
          (1.5, 2.85, body_h * 0.96), TROPICAL_GREEN,
          rotation=Matrix.Rotation(math.radians(9.0), 3, "Y"))
    b.box((L * 0.5 - 0.42, 0.0, floor_z + body_h * 0.80),
          (1.1, 2.6, body_h * 0.44), TROPICAL_GREEN,
          rotation=Matrix.Rotation(math.radians(30.0), 3, "Y"))
    # dunga galbena de bordaj
    b.box((-0.6, 0.0, floor_z + 0.55), (L - 2.4, 2.92, 0.30), DRY_VEGETATION)
    # geamurile cabinei
    b.box((-3.15, 0.0, floor_z + body_h + 0.55), (0.12, 2.5, 0.62), GLASS)
    for sy in (-1, 1):
        b.box((-4.7, sy * 1.44, floor_z + body_h + 0.55), (1.9, 0.10, 0.62),
              GLASS)
    # farul galben, in bot
    b.cylinder((L * 0.5 - 0.15, 0.0, floor_z + body_h * 0.86), 0.26, 0.22,
               DRY_VEGETATION, segments=8, axis="X")
    # gheata pe acoperis (brief)
    _roof_ice(b, x0=-6.4, x1=5.4, z=floor_z + body_h + 0.86, half_w=1.35,
              seed=505)
    _bogie(b, -4.4)
    _bogie(b, 4.4)
    loco = b.to_object("Baikal_Loco")
    finish(loco, bevel=0.04, ao=AO_VEHICLE, origin=None)
    objs.append(loco)

    # --- doua vagoane -------------------------------------------------------
    for k in range(2):
        b = Builder()
        C = 12.0
        cf = BOGIE_R + 0.55
        ch = 2.75
        b.box((0.0, 0.0, cf - 0.18), (C, 2.8, 0.36), VOLCANIC_BLACK)
        b.box((0.0, 0.0, cf + ch * 0.5), (C, 2.8, ch), TROPICAL_GREEN)
        # acoperis usor bombat, mai deschis
        b.box((0.0, 0.0, cf + ch + 0.10), (C - 0.3, 2.6, 0.22), ASPHALT_EDGE)
        # Dunga galbena SUB ferestre, nu peste ele. La aceeasi cota (prima
        # versiune avea dunga la 1.75 si geamurile la 1.95, deci se
        # suprapuneau pe 15 cm) geamurile taiau dunga si iesea o linie
        # intrerupta — vizibil in randarea de control ca un sir de liniute.
        b.box((0.0, 0.0, cf + 1.28), (C, 2.86, 0.26), DRY_VEGETATION)
        # ferestre: 8 pe fiecare parte, deasupra dungii
        for sy in (-1, 1):
            for i in range(8):
                b.box((-C * 0.5 + 1.1 + i * 1.42, sy * 1.41, cf + 2.05),
                      (0.86, 0.09, 0.78), GLASS)
        # usile de capat
        for dx in (-C * 0.5 + 0.35, C * 0.5 - 0.35):
            b.box((dx, 0.0, cf + 1.15), (0.10, 1.15, 2.10), ASPHALT_EDGE)
        _roof_ice(b, x0=-C * 0.5 + 0.6, x1=C * 0.5 - 0.6, z=cf + ch + 0.24,
                  half_w=1.25, seed=800 + k * 61)
        _bogie(b, -C * 0.5 + 2.2)
        _bogie(b, C * 0.5 - 2.2)
        obj = b.to_object("Baikal_Carriage_%s" % "AB"[k])
        finish(obj, bevel=0.04, ao=AO_VEHICLE, origin=None)
        # asezate in linie, ca planşa; pista le repozitioneaza oricum
        obj.location.x = -(L * 0.5 + 1.0 + C * (k + 0.5) + k * 1.0)
        objs.append(obj)

    _drop_to_zero(objs)
    print("BaikalTrain: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "vehicles/train_baikal.glb")
    save_blend(objs, "baikal_train.blend")
    return objs


def _roof_ice(b, x0, x1, z, half_w, seed):
    """Petice de gheata pe acoperis: placi joase, neregulate."""
    rand = _lcg(seed)
    n = max(int((x1 - x0) / 1.6), 2)
    for i in range(n):
        if rand() > 0.72:
            continue
        x = x0 + (x1 - x0) * (i + 0.5) / n
        b.box((x, (rand() - 0.5) * half_w * 0.9, z + 0.05),
              (0.8 + rand() * 1.0, half_w * (0.5 + rand() * 0.8), 0.10),
              FOAM_WHITE)


# ============================================================ Pilonul sovietic
# 25 m, zabrele ruginite cu izolatori. Piesa e inalta si subtire: se vede pe
# creasta, in contre-jour, deci conteaza SILUETA, nu detaliul.

def build_pylon():
    clear_built()
    b = Builder()
    H = 25.0
    base_half, top_half = 3.1, 0.85

    def half_at(z):
        """Latimea se ingusteaza liniar cu inaltimea — trunchi de piramida."""
        return base_half + (top_half - base_half) * (z / H)

    # cei 4 montanti
    legs = ((-1, -1), (-1, 1), (1, -1), (1, 1))
    steps = 10
    for sx, sy in legs:
        for i in range(steps):
            z0, z1 = H * i / steps, H * (i + 1) / steps
            p0 = (sx * half_at(z0), sy * half_at(z0), z0)
            p1 = (sx * half_at(z1), sy * half_at(z1), z1)
            b.beam(p0, p1, 0.17, RUST)
    # diagonalele de zabrea, pe cele 4 fete — alternante, ca la pilonii reali
    for i in range(steps):
        z0, z1 = H * i / steps, H * (i + 1) / steps
        h0, h1 = half_at(z0), half_at(z1)
        for face in range(4):
            # colturile fetei curente
            c = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            ax, ay = c[face]
            bx, by = c[(face + 1) % 4]
            up = i % 2 == 0
            if up:
                p0 = (ax * h0, ay * h0, z0)
                p1 = (bx * h1, by * h1, z1)
            else:
                p0 = (bx * h0, by * h0, z0)
                p1 = (ax * h1, ay * h1, z1)
            b.beam(p0, p1, 0.10, RUST)
        # traversa orizontala la fiecare etaj
        for face in range(4):
            c = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
            ax, ay = c[face]
            bx, by = c[(face + 1) % 4]
            b.beam((ax * h1, ay * h1, z1), (bx * h1, by * h1, z1), 0.09, RUST)

    # cele doua console cu izolatori
    for k, (z, arm) in enumerate(((H * 0.72, 4.6), (H * 0.90, 3.6))):
        for sx in (-1, 1):
            tip = (sx * arm, 0.0, z + 0.9)
            b.beam((sx * half_at(z), 0.0, z), tip, 0.13, RUST)
            b.beam((sx * half_at(z + 1.8), 0.0, z + 1.8), tip, 0.10, RUST)
            # izolatorul: 4 discuri
            for d in range(4):
                b.cylinder((tip[0], 0.0, tip[2] - 0.18 - d * 0.16), 0.15, 0.10,
                           FOAM_WHITE, segments=6)
    # varful cu paratrasnet
    b.beam((0.0, 0.0, H), (0.0, 0.0, H + 1.4), 0.08, RUST)

    obj = b.to_object("Pylon_Soviet")
    finish(obj, bevel=0.02, ao=AO_STEEL, origin="base")
    print("PowerPylon: %d tris" % tri_count(obj))
    export_glb([obj], "structures/power_pylon_soviet.glb")
    save_blend([obj], "baikal_power_pylon.blend")
    return [obj]


# ============================================================ Poarta de start
# 10 m deschidere, bustean rotund, panou de lemn, stegulete inghetate.
# Fata spre +Y (soferul o vede din fata la pornire).

def build_start_gate():
    clear_built()
    b = Builder()
    span, H = 10.0, 5.4
    post_r = 0.34

    for sx in (-1, 1):
        x = sx * span * 0.5
        # stalpul: bustean usor conic, ingropat
        b.frustum((x, 0.0, H * 0.5 - 0.2), post_r * 1.15, post_r * 0.92,
                  H + 0.4, WOOD, segments=8)
        # doua contrafise, in fata si in spate
        for sy in (-1, 1):
            b.beam((x, sy * 1.75, 0.05), (x, sy * 0.34, H * 0.62), 0.20, WOOD)
        # capac de zapada pe varful stalpului
        b.cylinder((x, 0.0, H + 0.22), post_r * 1.05, 0.16, FOAM_WHITE,
                   segments=8)

    # traversa de sus: bustean orizontal, cu capetele iesite
    b.beam((-span * 0.5 - 0.7, 0.0, H - 0.35), (span * 0.5 + 0.7, 0.0, H - 0.35),
           0.40, WOOD)
    # a doua traversa, mai jos — intre ele sta panoul
    b.beam((-span * 0.5, 0.0, H - 2.05), (span * 0.5, 0.0, H - 2.05), 0.28, WOOD)
    # panoul de lemn
    b.box((0.0, 0.0, H - 1.2), (span - 1.4, 0.16, 1.3), LOG_DARK)
    # tabla de sah pe panou: 2 randuri x 14, alb/negru alternant. Linia de
    # start e conventie de gen — se citeste instantaneu si nu cere text.
    cols, rows = 14, 2
    cw = (span - 1.7) / cols
    ch = 0.42
    for r in range(rows):
        for c in range(cols):
            slot = FOAM_WHITE if (r + c) % 2 == 0 else VOLCANIC_BLACK
            # y POZITIV: fata de prezentare a portii e spre +Y (= -Z in Godot).
            # Prima versiune punea patratele la y=-0.11, adica pe spatele
            # panoului — poarta iesea cu tabla de sah invizibila din masina,
            # exact lucrul pentru care exista poarta.
            b.box((-(span - 1.7) * 0.5 + cw * (c + 0.5), 0.11,
                   H - 1.2 + (0.5 - r) * ch),
                  (cw * 0.98, 0.06, ch * 0.98), slot)
    # zapada pe traversa de sus
    b.box((0.0, 0.0, H - 0.12), (span + 1.2, 0.34, 0.13), FOAM_WHITE)

    # steagulete inghetate atarnate de traversa de jos: TEPENE, nu fluturand —
    # brief-ul le cere "inghetate", si asta si distinge poarta asta de una
    # tropicala. Sunt placi rigide, usor rotite, nu fasii curbate ca la serge.
    rand = _lcg(1919)
    for i in range(9):
        x = -span * 0.5 + 0.9 + i * ((span - 1.8) / 8.0)
        # KERB_RED / PAINTED, nu CAR_RED / CAR_BLUE: sloturile 14-16 raman ale
        # masinilor (style_bible §1). Un steag de 30x62 cm e mic, dar sunt noua
        # pe poarta, chiar in dreptul grilei de start — adica exact acolo unde
        # ochiul cauta masinile. Rosul de bordura si albastrul de metal vopsit
        # dau acelasi semnal fara sa concureze.
        slot = (PAINTED, FOAM_WHITE, KERB_RED)[i % 3]
        b.box((x, 0.0, H - 2.42), (0.30, 0.03, 0.62), slot,
              rotation=Matrix.Rotation(math.radians((rand() - 0.5) * 26.0),
                                       3, "Y"))

    obj = b.to_object("StartGate_Logs")
    finish(obj, bevel=0.03, ao=AO_WOOD, origin="base")
    print("LogStartGate: %d tris" % tri_count(obj))
    export_glb([obj], "structures/start_gate_logs.glb")
    save_blend([obj], "baikal_start_gate.blend")
    return [obj]


if __name__ == "__main__":
    build_hovercraft()
    build_train()
    build_pylon()
    build_start_gate()
