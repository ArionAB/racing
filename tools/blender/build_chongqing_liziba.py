"""Chongqing — blocul Liziba si monorailul care trece prin el (pozitiile 2 si 3).

  buildings/liziba_block.glb   blocul traversat: hol de 7 m x 90 m + fatade
  vehicles/monorail_train.glb  3 vagoane de ~9 m, faruri emisive

POI-ul G din brief: drumul intra IN bloc (nivelul 8 e "parterul" nostru),
strabate un hol cu stalpi, si la mijloc monorailul taie holul la nivel.

Doua lucruri care decid daca holul se citeste:

1. **Holul e un TUNEL cu tavan scurt, si tavanul e tot ce vezi.** Camera
   priveste 63° in jos si 5° in sus (brief §2.0): din masina, in hol, vezi
   podeaua, stalpii si burta plafonului. Deci detaliul se pune ACOLO — grinzi
   transversale, lampi de neon intre ele, cutii postale pe stalpi — nu pe
   fatada de deasupra, care iese din cadru.
2. **Blocul e o COAJA, nu un solid.** Se traverseaza pe dinauntru, deci
   peretii laterali au grosime si fata interioara. Fatada exterioara primeste
   ferestre aprinse doar pe primele doua niveluri de deasupra holului: mai sus
   nu se vede (acelasi frustum).

Monorailul e piesa mobila: `TrainHazard` il plimba pe un Path3D. Originea lui
e in CENTRUL trenului, pe sina — asa se aseaza pe traseu fara offset.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_liziba.py
"""

import math
from mathutils import Matrix, Vector

AO_BUILD = dict(samples=26, dist=8.0, gradient="vertical",
                low=0.40, high=1.00, power=0.9, floor=0.10)
AO_TRAIN = dict(samples=24, dist=4.0, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.18)

CONC = CONCRETE
CONC2 = MARBLE_GREY        # a doua valoare de beton: rupe fatada in benzi
GLOW = LAVA_ORANGE         # ferestre aprinse / faruri / neoane
GLASS = ASPHALT            # geam de noapte: slotul cel mai inchis
METAL = PAINTED
TRIM = RUST

# Blocul e o CLADIRE, nu un tunel de 90 m: drumul ii traverseaza ADANCIMEA
# (~26 m), nu lungimea. Plansa arata clar un bloc de locuinte de ~40 x 22 m cu
# holul taiat prin parter — prima versiune, cu hol de 90 m, iesea un zid.
HALL_W = 7.4               # latimea holului (brief: 7 m carosabil)
HALL_H = 5.6               # inaltimea libera: incape monorailul (3.2 + sina)
HALL_L = 26.0              # adancimea blocului = lungimea traversarii

BLOCK_W = 40.0             # latimea fatadei (perpendicular pe sensul de mers)
FLOORS = 5                 # etaje de locuinte peste hol
FLOOR_H = 3.1


def hall_bay(b, y, seed):
    """O travee de hol: doi stalpi + grinda transversala + lampa de tavan.

    Ritmul stalpilor e ce da VITEZA in tunel — la 90 km/h stalpii care trec
    pe langa geam sunt singurul indiciu ca te misti, fiindca peretii sunt netezi.
    """
    rand = _lcg(seed)
    for sx in (-1.0, 1.0):
        x = sx * (HALL_W * 0.5 - 0.34)
        # stalp cu soclu (soclul se loveste, deci se vede uzat)
        b.box((x, y, HALL_H * 0.5), (0.62, 0.62, HALL_H), CONC)
        b.box((x, y, 0.22), (0.78, 0.78, 0.44), CONC2)
        # banda reflectorizanta la 1 m: semnalizare in tunel
        b.box((x + sx * 0.02, y, 1.05), (0.66, 0.66, 0.16),
              KERB_RED if rand() > 0.5 else FOAM_WHITE)
    # grinda transversala sub plafon
    b.box((0.0, y, HALL_H - 0.26), (HALL_W + 0.6, 0.52, 0.52), CONC)
    # lampa de neon pe grinda — se vede in burta plafonului
    b.box((0.0, y + 0.34, HALL_H - 0.60), (2.2, 0.22, 0.14), GLOW)


def facade_floor(b, z, y_face, seed):
    """Un etaj de locuinte pe fatada dinspre `y_face` (+1 fata, -1 spate).

    Plansa arata identitatea blocului chinezesc de anii '90: o banda continua
    de BALCOANE inchise, nu ferestre razlete intr-un perete. Alternanta
    balcon-plin-balcon e ce rupe fatada; ferestrele aprinse doar punctueaza.
    """
    rand = _lcg(seed)
    sy = 1.0 if y_face > 0 else -1.0
    y = sy * (HALL_L * 0.5)
    bays = 10
    bw = BLOCK_W / bays
    for i in range(bays):
        x = -BLOCK_W * 0.5 + bw * (i + 0.5)
        # loggia: parapet plin + gol intunecat in spate
        b.box((x, y + sy * 0.42, z + 0.55), (bw - 0.22, 0.30, 1.10), CONC2)
        b.box((x, y + sy * 0.10, z + 1.55), (bw - 0.30, 0.24, 1.00), GLASS)
        # ferestre aprinse: ~55%
        if rand() > 0.45:
            b.box((x, y + sy * 0.06, z + 1.55), (bw - 0.80, 0.16, 0.90), GLOW)
        # montantul dintre travei
        b.box((x + bw * 0.5, y + sy * 0.30, z + FLOOR_H * 0.5),
              (0.20, 0.44, FLOOR_H), CONC)
    # centura orizontala intre etaje — umbra ei taie fatada in benzi
    b.box((0.0, y + sy * 0.36, z - 0.08), (BLOCK_W, 0.52, 0.26), CONC)


def build_liziba():
    b = Builder()
    half_l = HALL_L * 0.5
    half_w = BLOCK_W * 0.5

    # --- podeaua holului ----------------------------------------------------
    b.box((0.0, 0.0, -0.10), (HALL_W + 3.2, HALL_L, 0.20), ASPHALT)
    # trotuare inguste pe margini (bordura, nu zid: pragul lateral peste 0.3 m
    # ar fi perete — memoria `suprafete-cu-goluri-si-praguri`)
    for sx in (-1.0, 1.0):
        b.box((sx * (HALL_W * 0.5 + 1.05), 0.0, 0.07), (1.1, HALL_L, 0.14),
              CONC2)

    # --- parterul: doua corpuri pline, cu holul taiat intre ele -------------
    # Blocul se sprijina pe ele; intre ele trece drumul si monorailul.
    for sx in (-1.0, 1.0):
        x0 = sx * (HALL_W * 0.5 + 1.6)
        x1 = sx * half_w
        b.box(((x0 + x1) * 0.5, 0.0, HALL_H * 0.5),
              (abs(x1 - x0), HALL_L, HALL_H), CONC)
        # vitrine la parter pe fatada (magazine — plansa le are)
        rand = _lcg(51 + int(sx))
        for sy in (-1.0, 1.0):
            for i in range(3):
                xx = (x0 + x1) * 0.5 + (i - 1) * abs(x1 - x0) * 0.28
                if rand() > 0.35:
                    b.box((xx, sy * (half_l + 0.02), 1.9),
                          (abs(x1 - x0) * 0.22, 0.20, 2.2), GLOW)
                else:
                    b.box((xx, sy * (half_l + 0.02), 1.9),
                          (abs(x1 - x0) * 0.22, 0.20, 2.2), GLASS)

    # --- travee in hol: stalpi, grinzi, lampi -------------------------------
    n_bays = max(int(HALL_L / 6.0), 2)
    for i in range(n_bays):
        y = -half_l + HALL_L * (i + 0.5) / n_bays
        hall_bay(b, y, seed=31 + i * 5)

    # --- plafonul holului = planseul peste parter ---------------------------
    b.box((0.0, 0.0, HALL_H + 0.40), (BLOCK_W, HALL_L, 0.80), CONC)

    # --- etajele de locuinte ------------------------------------------------
    base = HALL_H + 0.80
    for f in range(FLOORS):
        z = base + f * FLOOR_H
        # corpul etajului
        b.box((0.0, 0.0, z + FLOOR_H * 0.5),
              (BLOCK_W, HALL_L - 1.4, FLOOR_H), CONC)
        for sy in (1.0, -1.0):
            facade_floor(b, z, sy, seed=71 + f * 11 + int(sy))
        # capetele blocului: casa scarii, o banda verticala mai inchisa
        for sx in (-1.0, 1.0):
            b.box((sx * (half_w - 0.30), 0.0, z + FLOOR_H * 0.5),
                  (0.60, HALL_L - 1.0, FLOOR_H), CONC2)

    # --- coronament: atic + cutii de scara pe acoperis ----------------------
    top = base + FLOORS * FLOOR_H
    b.box((0.0, 0.0, top + 0.30), (BLOCK_W + 0.6, HALL_L, 0.60), CONC2)
    for sx in (-1.0, 1.0):
        b.box((sx * half_w * 0.45, 0.0, top + 1.55), (5.0, 5.5, 2.5), CONC)
    # rezervoare de apa pe acoperis: silueta tipica de bloc chinezesc
    for i in range(4):
        b.cylinder((-half_w * 0.62 + i * 8.0, -4.0, top + 1.55), 0.75, 2.5,
                   TRIM, segments=8)

    # --- gura de intrare/iesire: portal marcat -----------------------------
    # Intrarea in bloc e o decizie de curse: trebuie sa se vada de departe.
    for sy in (-1.0, 1.0):
        y = sy * half_l
        b.box((0.0, y, HALL_H + 0.95), (HALL_W + 5.4, 0.9, 1.1), CONC2)
        # chevroane pe buiandrug
        for i in range(7):
            b.box((-HALL_W * 0.5 - 1.4 + i * 2.4, y + sy * 0.50, HALL_H + 0.95),
                  (1.5, 0.16, 0.75), KERB_RED if i % 2 == 0 else FOAM_WHITE)

    return b.to_object("LizibaBlock")


# --- monorail ---------------------------------------------------------------

CAR_L = 9.0
CAR_W = 2.9
CAR_H = 3.2


def monorail_car(b, y0, nose, seed):
    """Un vagon. `nose` = -1 capul din spate, +1 cel din fata, 0 vagon de mijloc.

    Trenul de Chongqing e un STRADDLE monorail: sta CALARE pe o grinda de
    beton, nu atarnat. Deci sub cutie e un sasiu care imbratiseaza grinda —
    silueta aia il deosebeste de un tramvai.
    """
    zc = CAR_H * 0.5 + 1.35
    # cutia
    b.box((0.0, y0, zc), (CAR_W, CAR_L - 0.35, CAR_H), FOAM_WHITE)
    # banda de culoare sub geamuri (plansa: verde inchis + alb)
    b.box((0.0, y0, zc - CAR_H * 0.5 + 0.42), (CAR_W + 0.04, CAR_L - 0.35, 0.62),
          TROPICAL_GREEN)
    # geamuri laterale
    n = 5
    for sx in (-1.0, 1.0):
        for i in range(n):
            yy = y0 - (CAR_L - 2.2) * 0.5 + (CAR_L - 2.2) * i / (n - 1)
            b.box((sx * (CAR_W * 0.5 - 0.03), yy, zc + 0.42),
                  (0.10, 1.15, 1.05), GLASS)
    # usi: doua pe parte, in alta valoare
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (CAR_W * 0.5 - 0.02), y0 + sy * 2.5, zc + 0.10),
                  (0.08, 1.25, 2.2), MARBLE_GREY)
    # sasiul care calareste grinda
    b.box((0.0, y0, 1.05), (CAR_W - 0.5, CAR_L - 0.9, 0.70), TRIM)
    b.box((0.0, y0, 0.55), (1.30, CAR_L - 1.6, 0.60), METAL)   # golul pentru grinda
    # acoperis usor bombat: doua placi
    for sx in (-1.0, 1.0):
        b.box((sx * CAR_W * 0.25, y0, zc + CAR_H * 0.5 + 0.06),
              (CAR_W * 0.52, CAR_L - 0.55, 0.16), MARBLE_GREY,
              rotation=Matrix.Rotation(sx * math.radians(-6.0), 3, "Y"))
    if nose != 0:
        y_end = y0 + nose * (CAR_L - 0.35) * 0.5
        # frontul: parbriz mare, inclinat
        b.box((0.0, y_end + nose * 0.10, zc + 0.55), (CAR_W - 0.42, 0.22, 1.45),
              GLASS, rotation=Matrix.Rotation(nose * math.radians(9.0), 3, "X"))
        # faruri emisive — telegraph-ul vizual al hazardului
        for sx in (-1.0, 1.0):
            b.box((sx * (CAR_W * 0.5 - 0.45), y_end + nose * 0.14, zc - 0.62),
                  (0.52, 0.16, 0.30), GLOW)
        # bara de protectie
        b.box((0.0, y_end + nose * 0.06, zc - CAR_H * 0.5 + 0.16),
              (CAR_W - 0.16, 0.20, 0.34), TRIM)


def build_monorail():
    b = Builder()
    for i, nose in enumerate((-1, 0, 1)):
        monorail_car(b, (i - 1) * CAR_L, nose, seed=41 + i)
    # Burdufurile dintre vagoane. Fara ele cele 35 cm de rost (corecte tehnic:
    # orice tren are jocul asta) citesc ca trei cutii nelegate care se plimba
    # in formatie — nu ca un tren. Burduful e o cutie mai ingusta si mai
    # inchisa, exact cat sa inchida rostul.
    for k in (-0.5, 0.5):
        b.box((0.0, k * CAR_L, CAR_H * 0.5 + 1.35),
              (CAR_W - 0.55, 0.42, CAR_H - 0.60), TRIM)
    return b.to_object("MonorailTrain")


clear_built()

obj = build_liziba()
st = finish(obj, bevel=0.045, ao=AO_BUILD, origin="base")
_, sz = export_glb([obj], "chongqing/buildings/liziba_block.glb")
print("liziba_block.glb    tris=%5d ao=%.2f..%.2f %7.1f kB"
      % (st["tris"], st["ao_min"], st["ao_max"], sz / 1024.0))

obj = build_monorail()
st = finish(obj, bevel=0.04, ao=AO_TRAIN, origin="base")
_, sz = export_glb([obj], "chongqing/vehicles/monorail_train.glb")
print("monorail_train.glb  tris=%5d ao=%.2f..%.2f %7.1f kB"
      % (st["tris"], st["ao_min"], st["ao_max"], sz / 1024.0))
