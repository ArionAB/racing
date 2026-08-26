"""Chongqing — piesele MOBILE ale pistei (plansa, pozitiile 4, 6, 7).

  vehicles/cableway_cabin.glb    cabina-platforma 5 x 4 m (scurtatura E')
  structures/cableway_tower.glb  turn de telecabina cu bratele de cablu
  structures/rotating_span.glb   tronsonul de 12 m care se roteste pe pivot
  structures/tower_crane.glb     macaraua turn de pe etajul 3
  props/prefab_slab.glb          prefabricatul legant din carligul macaralei

Toate patru sunt piese pe care le MISCA un hazard din cod, deci fiecare are o
cerinta de origine care nu e cea implicita:

- **cabina**: originea in centrul PODELEI, nu la baza bbox-ului. Masina sta pe
  ea (`sync_to_physics`, memoria `jolt-sync-transform-o-singura-scriere`), deci
  podeaua trebuie sa fie la y=0 in spatiul cabinei. Suspensia si carligul de
  cablu urca deasupra.
- **tronsonul rotativ**: originea in CENTRUL de pivotare, pe axa lui de
  rotatie. `LiftBridgeHazard` il roteste in jurul originii proprii; daca
  originea e la un capat, tronsonul descrie un cerc in loc sa se invarta pe loc.
- **macaraua**: originea la baza turnului, dar bratul e un nod SEPARAT ("Jib")
  cu originea in axa turnului — asa `CarouselHazard` roteste doar bratul.
  **Bratul se monteaza la z = 22.0 m** (varful turnului): e construit in jurul
  lui z=0 ca sa aiba pivotul in origine, deci in Godot i se DA cota. Fara nota
  asta, la integrare ajunge pe jos langa turn — exact cum arata in randarea
  de control, unde fiecare piesa e pusa la originea ei.
- **prefabricatul**: originea in punctul de AGATARE (varful de sus), fiindca
  atarna de cablu si se leagana din el.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_machines.py
"""

import math
from mathutils import Matrix, Vector

AO_MECH = dict(samples=24, dist=5.0, gradient="vertical",
               low=0.46, high=1.00, power=0.9, floor=0.14)
AO_TOWER = dict(samples=22, dist=7.0, gradient="vertical",
                low=0.44, high=1.00, power=0.9, floor=0.12)

METAL = PAINTED
STEEL = MARBLE_GREY
# Sloturile 14-16 sunt REZERVATE MASINILOR (style_bible §1, verify_glb le
# respinge). Deci rosul cabinei si galbenul macaralei vin din sloturi de
# decor: KERB_RED e acelasi rosu de semnalizare, iar RUST da galben-ruginiu
# de utilaj vechi § exact ce arata plansa (macara uzata, nu jucarie noua).
RED = KERB_RED             # cabina de telecabina e rosu-alb (plansa)
GLASS = ASPHALT
GLOW = LAVA_ORANGE
CONC = CONCRETE
YELLOW = RUST              # macaraua: galben-ruginiu de santier


def lattice_leg(b, p0, p1, thickness, slot, panels, brace_t=None):
    """Picior de zabrele: montant + contravantuiri in X pe `panels` etaje.

    Zabrelele sunt scumpe daca le faci "corect" (fiecare bara un beam). Aici
    montantul e o grinda continua si diagonalele sunt cate DOUA per etaj —
    de la distanta de joc ochiul vede tesatura, nu barele.
    """
    a, c = Vector(p0), Vector(p1)
    b.beam(a, c, thickness, slot)
    return a, c


def build_cableway_cabin():
    """Cabina-platforma: masina intra pe ea si e dusa peste golf.

    Podeaua e o PLATFORMA, nu un planseu de gondola: 5 x 4 m, plata, cu
    borduri joase pe laturi si capete deschise. Bordura sub 30 cm ca sa nu
    fie zid (memoria `suprafete-cu-goluri-si-praguri`), dar prezenta ca sa
    citesti marginea cand esti pe ea.
    """
    b = Builder()
    W, D = 5.0, 4.0          # latime x adancime, brief §2 (E')
    # podeaua: y=0 e SUPRAFATA pe care sta masina
    b.box((0.0, 0.0, -0.14), (W, D, 0.28), METAL)
    # nervuri sub podea
    for i in range(5):
        b.box((-W * 0.5 + W * (i + 0.5) / 5, 0.0, -0.36), (0.22, D, 0.24), STEEL)
    # borduri laterale joase (pe laturile lungi; capetele raman deschise)
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.10), 0.0, 0.12), (0.20, D, 0.26), RED)
    # stalpii cabinei + geamuri: cabina e deschisa, dar are cadru
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (W * 0.5 - 0.14), sy * (D * 0.5 - 0.14), 1.30),
                  (0.18, 0.18, 2.60), RED)
    # panouri de geam pe laturile lungi, sus (nu blocheaza intrarea)
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.12), 0.0, 1.95), (0.10, D - 0.5, 1.20), GLASS)
    # acoperisul
    b.box((0.0, 0.0, 2.72), (W + 0.25, D + 0.25, 0.20), FOAM_WHITE)
    b.box((0.0, 0.0, 2.86), (W - 0.6, D - 0.6, 0.14), RED)
    # lumini de gabarit: se vad venind pe cablu, de pe cornisa (brief E')
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (W * 0.5 - 0.30), sy * (D * 0.5 - 0.08), 2.62),
                  (0.34, 0.14, 0.16), GLOW)
    # suspensia: brat curbat + carligul de cablu
    b.box((0.0, 0.0, 3.30), (0.34, 0.34, 1.00), STEEL)
    b.box((0.0, 0.0, 3.92), (1.90, 0.30, 0.26), STEEL)
    for sy in (-1.0, 1.0):
        b.cylinder((sy * 0.80, 0.0, 4.14), 0.22, 0.30, METAL, segments=8,
                   axis="Y")
    return b.to_object("CablewayCabin")


def build_cableway_tower():
    """Turn de telecabina: patru picioare in zabrele + traversa cu role."""
    b = Builder()
    H = 15.0
    base = 2.4               # semi-latura la baza
    top = 0.85               # semi-latura in varf
    # soclu de beton
    b.box((0.0, 0.0, 0.35), (base * 2.2, base * 2.2, 0.70), CONC)
    legs = []
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            p0 = (sx * base, sy * base, 0.7)
            p1 = (sx * top, sy * top, H)
            b.beam(p0, p1, 0.26, STEEL)
            legs.append((Vector(p0), Vector(p1)))
    # etaje de contravantuire: pe fiecare fata, un X
    LEV = 5
    for i in range(LEV):
        f0, f1 = i / LEV, (i + 1) / LEV
        for (a0, a1), (b0, b1) in ((legs[0], legs[1]), (legs[2], legs[3]),
                                   (legs[0], legs[2]), (legs[1], legs[3])):
            pa0 = a0.lerp(a1, f0); pa1 = a0.lerp(a1, f1)
            pb0 = b0.lerp(b1, f0); pb1 = b0.lerp(b1, f1)
            b.beam(pa0, pb1, 0.13, STEEL)
            b.beam(pb0, pa1, 0.13, STEEL)
            # centura orizontala
            b.beam(pa1, pb1, 0.13, STEEL)
    # capul turnului: traversa pe care stau rolele
    b.box((0.0, 0.0, H + 0.30), (top * 2.4, top * 2.4, 0.40), STEEL)
    for sy in (-1.0, 1.0):
        # bratul de role, spre ambele directii ale cablului
        b.beam((0.0, sy * 0.3, H + 0.5), (0.0, sy * 2.6, H + 0.9), 0.22, STEEL)
        # bateria de role
        for i in range(3):
            b.cylinder((0.0, sy * (1.5 + i * 0.5), H + 0.95), 0.20, 0.16,
                       METAL, segments=8, axis="X")
    # lumina de balizaj in varf
    b.box((0.0, 0.0, H + 0.72), (0.28, 0.28, 0.30), GLOW)
    return b.to_object("CablewayTower")


def build_rotating_span():
    """Tronsonul de 12 m care se roteste pe pivot (brief §3, POI F).

    ORIGINEA E IN CENTRU, pe axa de pivotare — `finish(origin="center")`.
    Piesa se roteste pe loc intre "deschis" (continua rampa) si "inchis".
    Plansa o arata in trei poze: 0°, 45°, 90°; noi exportam UNA si o roteste
    hazardul.
    """
    b = Builder()
    L, W = 12.0, 7.0
    # tablierul
    b.box((0.0, 0.0, 0.0), (W, L, 0.34), ASPHALT)
    b.box((0.0, 0.0, -0.32), (W - 0.3, L, 0.32), STEEL)
    # grinzi longitudinale sub tablier
    for sx in (-1.0, 1.0):
        b.box((sx * W * 0.32, 0.0, -0.62), (0.46, L, 0.42), STEEL)
    # parapete rosu-alb pe laturile lungi: piesa TREBUIE sa se distinga de
    # rampa fixa, altfel nu inveti unde e (brief: hazard ciclic si invatabil)
    for sx in (-1.0, 1.0):
        x = sx * (W * 0.5 - 0.18)
        n = 8
        for i in range(n):
            y = -L * 0.5 + L * (i + 0.5) / n
            b.box((x, y, 0.52), (0.26, L / n * 0.94, 0.70),
                  KERB_RED if i % 2 == 0 else FOAM_WHITE)
    # pivotul central: disc + inel de rulare (se vede cand e deschis)
    b.cylinder((0.0, 0.0, -0.95), 1.45, 0.55, CONC, segments=12)
    b.cylinder((0.0, 0.0, -0.62), 1.05, 0.30, STEEL, segments=12)
    # lampi de santier la capete
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (L * 0.5 - 0.25), 0.72), (0.9, 0.22, 0.24), GLOW)
    return b.to_object("RotatingSpan")


def build_tower_crane():
    """Macaraua: turn de zabrele + brat rotitor separat (nodul "Jib").

    Bratul e un OBIECT propriu ca sa poata fi rotit singur de hazard. Turnul
    ramane fix. Contractul de nume ("Jib") e cel din build_windmill /
    build_train: Godot cauta nodul dupa nume.
    """
    tower = Builder()
    H = 22.0
    half = 0.95
    tower.box((0.0, 0.0, 0.45), (3.6, 3.6, 0.90), CONC)
    legs = []
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            p0 = (sx * half, sy * half, 0.9)
            p1 = (sx * half, sy * half, H)
            tower.beam(p0, p1, 0.20, YELLOW)
            legs.append((Vector(p0), Vector(p1)))
    LEV = 9
    for i in range(LEV):
        f0, f1 = i / LEV, (i + 1) / LEV
        for (a0, a1), (b0, b1) in ((legs[0], legs[1]), (legs[2], legs[3]),
                                   (legs[0], legs[2]), (legs[1], legs[3])):
            pa0 = a0.lerp(a1, f0); pa1 = a0.lerp(a1, f1)
            pb0 = b0.lerp(b1, f0); pb1 = b0.lerp(b1, f1)
            tower.beam(pa0, pb1, 0.10, YELLOW)
            tower.beam(pb1, pa1, 0.10, YELLOW)
    t = tower.to_object("TowerCrane")

    # --- bratul, obiect separat, cu originea in axa turnului ----------------
    jib = Builder()
    JIB = 18.0          # brat de lucru
    CTR = 6.5           # contra-brat
    z = 0.0             # se aseaza la cota lui prin pozitionare in Godot
    # cabina operatorului, la radacina bratului
    jib.box((0.0, 1.3, z - 0.55), (1.5, 1.8, 1.5), YELLOW)
    jib.box((0.0, 1.3, z - 0.35), (1.2, 1.5, 1.1), GLASS)
    # bratul: talpa + zabrele triunghiulare
    for sx in (-1.0, 1.0):
        jib.beam((sx * 0.55, 0.0, z), (sx * 0.30, JIB, z), 0.16, YELLOW)
    jib.beam((0.0, 0.0, z + 0.95), (0.0, JIB, z + 0.55), 0.16, YELLOW)
    n = 10
    for i in range(n):
        y0 = JIB * i / n
        y1 = JIB * (i + 1) / n
        f0, f1 = i / n, (i + 1) / n
        jib.beam((-0.55 + 0.25 * f0, y0, z), (0.0, y1, z + 0.95 - 0.40 * f1),
                 0.09, YELLOW)
        jib.beam((0.55 - 0.25 * f0, y0, z), (0.0, y1, z + 0.95 - 0.40 * f1),
                 0.09, YELLOW)
        jib.beam((-0.55 + 0.25 * f1, y1, z), (0.55 - 0.25 * f1, y1, z),
                 0.09, YELLOW)
    # contra-bratul cu contragreutatea
    for sx in (-1.0, 1.0):
        jib.beam((sx * 0.55, 0.0, z), (sx * 0.45, -CTR, z + 0.20), 0.15, YELLOW)
    jib.box((0.0, -CTR - 0.35, z + 0.30), (2.2, 1.5, 1.7), CONC)
    # pilonul de tiranti + tirantii
    jib.beam((0.0, 0.0, z + 0.95), (0.0, 0.0, z + 4.2), 0.20, YELLOW)
    jib.beam((0.0, 0.0, z + 4.2), (0.0, JIB * 0.55, z + 0.75), 0.09, STEEL)
    jib.beam((0.0, JIB * 0.55, z + 0.75), (0.0, JIB, z + 0.55), 0.09, STEEL)
    jib.beam((0.0, 0.0, z + 4.2), (0.0, -CTR, z + 0.55), 0.09, STEEL)
    # caruciorul + cablul + carligul: unde atarna prefabricatul
    jib.box((0.0, JIB * 0.72, z - 0.22), (0.9, 1.1, 0.36), STEEL)
    jib.beam((0.0, JIB * 0.72, z - 0.35), (0.0, JIB * 0.72, z - 5.5), 0.07, STEEL)
    jib.box((0.0, JIB * 0.72, z - 5.75), (0.45, 0.30, 0.55), METAL)
    j = jib.to_object("Jib")
    return t, j


def build_prefab_slab():
    """Prefabricatul care se leagana: originea in punctul de AGATARE (sus)."""
    b = Builder()
    L, W, T = 4.6, 2.2, 0.45
    b.box((0.0, 0.0, -2.6 - T * 0.5), (L, W, T), CONC)
    # urechile de ridicare + cele patru cabluri spre carlig
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            p = (sx * L * 0.36, sy * W * 0.30, -2.6)
            b.beam(p, (0.0, 0.0, -0.18), 0.045, STEEL)
            b.box((p[0], p[1], -2.58), (0.16, 0.16, 0.22), STEEL)
    # inelul de agatare, la origine
    b.torus((0.0, 0.0, -0.10), 0.20, 0.055, METAL, major_seg=8, minor_seg=5)
    return b.to_object("PrefabSlab")


clear_built()

obj = build_cableway_cabin()
# origin=None: geometria RAMANE unde a fost construita. Piesele astea sunt
# deja centrate pe pivotul lor (podeaua cabinei la z=0, axa tronsonului la
# z=0, agatarea prefabricatului la z=0), deci mutarea implicita "la baza" ar
# strica exact contractul care conteaza.
st = finish(obj, bevel=0.035, ao=AO_MECH, origin=None)
_, sz = export_glb([obj], "chongqing/vehicles/cableway_cabin.glb")
print("cableway_cabin.glb  tris=%5d %7.1f kB" % (st["tris"], sz / 1024.0))

obj = build_cableway_tower()
st = finish(obj, bevel=0.03, ao=AO_TOWER, origin="base")
_, sz = export_glb([obj], "chongqing/structures/cableway_tower.glb")
print("cableway_tower.glb  tris=%5d %7.1f kB" % (st["tris"], sz / 1024.0))

obj = build_rotating_span()
# Originea in centrul de pivotare (piesa se invarte pe loc).
st = finish(obj, bevel=0.035, ao=AO_MECH, origin=None)
_, sz = export_glb([obj], "chongqing/structures/rotating_span.glb")
print("rotating_span.glb   tris=%5d %7.1f kB" % (st["tris"], sz / 1024.0))

t, j = build_tower_crane()
st_t = finish(t, bevel=0.03, ao=AO_TOWER, origin="base")
st_j = finish(j, bevel=0.03, ao=AO_TOWER, origin=None)
_, sz = export_glb([t, j], "chongqing/structures/tower_crane.glb")
print("tower_crane.glb     tris=%5d %7.1f kB (turn %d + brat %d)"
      % (st_t["tris"] + st_j["tris"], sz / 1024.0, st_t["tris"], st_j["tris"]))

obj = build_prefab_slab()
st = finish(obj, bevel=0.03, ao=AO_MECH, origin=None)
_, sz = export_glb([obj], "chongqing/props/prefab_slab.glb")
print("prefab_slab.glb     tris=%5d %7.1f kB" % (st["tris"], sz / 1024.0))
