# Decorul POI-ului E pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.403-0.498.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("E_...")
#   glb      relativ la res://assets/models/angkor/ ("kit/naga_head.glb") sau cale res:// completa (reuse)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, + = spre STANGA, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale:
#     "along"      m inainte pe axa fata de frac (negativ = inapoi)
#     "scale"      uniform
#     "y"          cota ABSOLUTA; altfel KIT_Y[nume]; altfel cota drumului + "dy" (implicit -0,3)
#     "dy"         decalaj fata de cota drumului in punctul de pe axa
#     "world"      (x, z) in Godot, absolut: ignora frac/lateral; yaw devine absolut (0 = -Z al piesei spre nord, -Z)
#     "coliziune"  "hull" (implicit in world_prop) / "mesh" / "trunk" / "none"
#     "anchor"     (x, y, z) local = metadata/ancora_sol pentru probe_manual (piese cu originea in aer)
#     "scufundat"  True: infipta prin proiect (probe_manual o iarta daca varful iese din teren)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `godot --headless --path . res://tools/ProbeCarraraMontaj.tscn -- --track=16 --decor`.
# FOREST: zone MeshForest (fantome, fara coliziune) — vezi jungla.py; FOREST_GLBS = stem -> glb.

# ---- POI E: Bayonul. Terasa de 14 m (cota 20) are 95 m: "E terasa V" = frac 0,4268, 1 m de drum =
# 1/2412 din frac. Turnurile de pe drum (3, la s 15/48/81) si culoarul AI raman din generator.
T0 = 0.4268
M = 1.0 / 2412.0


def fr(s):
    return round(T0 + s * M, 5)


ITEMS = []
KIT_Y = {}

# Padurea de turnuri: doua randuri pe fiecare parte. Randul 1 la 15-19 m (corpul de 3 m ramane la
# >= 6 m de asfaltul de 7 m: ProbeLaneClear), randul 2 la 25-34 m, mai mare, pentru adancime.
TOWER_GLBS = ["structures/bayon_face_tower_a.glb", "structures/bayon_face_tower_b.glb",
              "structures/bayon_face_tower_c.glb"]
# (s, lateral, scara, yaw)
TOWERS = [
    (-22, -17.0, 1.0, 20), (6, -14.0, 1.0, -15), (32, -16.5, 1.1, 35), (60, -13.5, 1.0, 5),
    (88, -16.0, 1.1, -25), (114, -19.0, 1.0, 10),
    (-10, 15.0, 1.0, -30), (24, 14.0, 1.1, 10), (42, 17.5, 1.0, 30), (72, 13.5, 1.0, -10),
    (100, 16.5, 1.1, 25), (128, 19.0, 1.0, -20),
    (-4, -30.0, 1.4, 40), (20, -34.0, 1.3, 10), (46, -29.0, 1.4, -10), (78, -32.0, 1.4, 15), (104, -30.0, 1.3, 35),
    (6, 31.0, 1.4, -35), (36, 29.0, 1.3, 5), (62, 33.0, 1.4, 20), (90, 29.0, 1.4, 0), (118, 31.0, 1.3, -25),
]
for k, (s_, lat, sc, yw) in enumerate(TOWERS):
    ITEMS.append((f"E_Turn{k}", TOWER_GLBS[k % 3], fr(s_), lat, yw, {"scale": sc}))

# Zidul terasei: placi de relief (4 m) pe ambele margini, relieful spre drum.
WALL_LAT = 22.0
for side, lat, yw in (("L", -WALL_LAT, -90), ("R", WALL_LAT, 90)):
    for k in range(34):
        s_ = -26 + k * 4.0 + 2.0
        ITEMS.append((f"E_Zid{side}{k}", "kit/gallery_relief_wall.glb", fr(s_), lat, yw, {}))

# Moloz la poalele turnurilor, doi calugari pe terasa (coliziune scoasa la cei mici de pe margine).
EXTRA = [
    ("E_Moloz0", "props/rubble_pile.glb", 8, -10.5, 30, {}),
    ("E_Moloz1", "props/rubble_pile.glb", 66, 10.5, -40, {}),
    ("E_Bloc0", "props/fallen_block.glb", 36, -11.0, 20, {}),
    ("E_Bloc1", "props/fallen_block.glb", 92, 11.5, 60, {}),
    ("E_Calugar0", "animals/monk_standing.glb", 26, 10.0, 90, {"coliziune": "none"}),
    ("E_Calugar1", "animals/monk_standing.glb", 76, -10.0, -90, {"coliziune": "none"}),
]
for nm, g, s_, lat, yw, o in EXTRA:
    ITEMS.append((nm, g, fr(s_), lat, yw, o))

# @@KITY (scris din ProbeCarraraMontaj: teren minim - 0,03)
KIT_Y.update({'E_Turn0': 17.37, 'E_Turn1': 19.43, 'E_Turn2': 19.63, 'E_Turn3': 19.64, 'E_Turn4': 19.1, 'E_Turn5': 16.95, 'E_Turn6': 18.51, 'E_Turn7': 19.62, 'E_Turn8': 19.64, 'E_Turn9': 19.58, 'E_Turn10': 18.23, 'E_Turn11': 15.54, 'E_Turn12': 18.5, 'E_Turn13': 19.39, 'E_Turn14': 19.61, 'E_Turn15': 19.16, 'E_Turn16': 17.68, 'E_Turn17': 18.99, 'E_Turn18': 19.59, 'E_Turn19': 19.49, 'E_Turn20': 18.68, 'E_Turn21': 16.37, 'E_ZidL0': 17.2, 'E_ZidL1': 17.51, 'E_ZidL2': 17.81, 'E_ZidL3': 18.21, 'E_ZidL4': 18.47, 'E_ZidL5': 18.7, 'E_ZidL6': 18.98, 'E_ZidL7': 19.12, 'E_ZidL8': 19.26, 'E_ZidL9': 19.38, 'E_ZidL10': 19.46, 'E_ZidL11': 19.5, 'E_ZidL12': 19.56, 'E_ZidL13': 19.58, 'E_ZidL14': 19.61, 'E_ZidL15': 19.62, 'E_ZidL16': 19.63, 'E_ZidL17': 19.63, 'E_ZidL18': 19.63, 'E_ZidL19': 19.62, 'E_ZidL20': 19.61, 'E_ZidL21': 19.58, 'E_ZidL22': 19.54, 'E_ZidL23': 19.51, 'E_ZidL24': 19.42, 'E_ZidL25': 19.36, 'E_ZidL26': 19.25, 'E_ZidL27': 19.09, 'E_ZidL28': 18.91, 'E_ZidL29': 18.73, 'E_ZidL30': 18.38, 'E_ZidL31': 18.13, 'E_ZidL32': 17.83, 'E_ZidL33': 17.38, 'E_ZidR0': 17.2, 'E_ZidR1': 17.53, 'E_ZidR2': 17.83, 'E_ZidR3': 18.24, 'E_ZidR4': 18.5, 'E_ZidR5': 18.72, 'E_ZidR6': 19.0, 'E_ZidR7': 19.13, 'E_ZidR8': 19.26, 'E_ZidR9': 19.37, 'E_ZidR10': 19.46, 'E_ZidR11': 19.5, 'E_ZidR12': 19.56, 'E_ZidR13': 19.58, 'E_ZidR14': 19.61, 'E_ZidR15': 19.62, 'E_ZidR16': 19.63, 'E_ZidR17': 19.63, 'E_ZidR18': 19.63, 'E_ZidR19': 19.62, 'E_ZidR20': 19.61, 'E_ZidR21': 19.58, 'E_ZidR22': 19.56, 'E_ZidR23': 19.52, 'E_ZidR24': 19.45, 'E_ZidR25': 19.38, 'E_ZidR26': 19.29, 'E_ZidR27': 19.11, 'E_ZidR28': 18.93, 'E_ZidR29': 18.75, 'E_ZidR30': 18.38, 'E_ZidR31': 18.13, 'E_ZidR32': 17.8, 'E_ZidR33': 17.37, 'E_Moloz0': 19.61, 'E_Moloz1': 19.65, 'E_Bloc0': 19.66, 'E_Bloc1': 19.12, 'E_Calugar0': 19.66, 'E_Calugar1': 19.64})
