# Decorul POI-ului D pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.318-0.403.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("D_...")
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
#     "child"      {"Nod": (x, y, z)}: muta un nod-copil al GLB-ului (tuk_tuk: {"Moto": (0, 0, -1.95)})
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `godot --headless --path . res://tools/ProbeCarraraMontaj.tscn -- --track=16 --decor`.
# FOREST: zone MeshForest (fantome, fara coliziune) — vezi jungla.py; FOREST_GLBS = stem -> glb.

# ---- POI D: calea uriasilor si Poarta de Sud. Poarta = frac 0,36288 (elefantul traverseaza la +22 m).
# 1 m de drum = 1/2412 din frac. `s` = metri fata de poarta (negativ = inainte de ea, pe calea uriasilor).
# Santul Angkor Thom (rapa 4) are apa la 11,0 (WATER_THOM), drumul e la 14,0.
G0 = 0.36288
M = 1.0 / 2412.0
WATER_Y = 11.0


def fr(s_):
    return round(G0 + s_ * M, 5)


ITEMS = []
KIT_Y = {}

# Bazinele cu lotusi: lotus si nuferi PE apa (cota 11,0), fara coliziune. Pozitiile (s fata de poarta, lateral,
# tip) vin din candidatii filtrati cu ProbeCarraraMontaj: doar unde terenul de sub amprenta e <= 10,7 (apa
# acopera tot). Apa incepe la ~15 m de axa (malul de langa drum e uscat) si tine pana la ~30 m.
LOTS = [
    (-94.1, 20.5, 1),
    (-93.8, 26.3, 0),
    (-91.4, 24.5, 0),
    (-90.5, 27.6, 0),
    (-88.6, -20.5, 1),
    (-88.4, -24.5, 1),
    (-87.8, 19.7, 1),
    (-87.8, 25.5, 0),
    (-85.4, -16.4, 0),
    (-85.3, -27.7, 0),
    (-85.1, 23.6, 0),
    (-84.9, -19.6, 0),
    (-84.5, -23.9, 0),
    (-84.4, 20.2, 0),
    (-82.5, -16.0, 1),
    (-82.2, -27.8, 1),
    (-81.9, 18.4, 0),
    (-81.3, 25.9, 0),
    (-79.1, 20.3, 0),
    (-78.6, -26.1, 1),
    (-78.5, -18.4, 1),
    (-78.3, 25.9, 1),
    (-78.2, -22.0, 1),
    (-76.3, 18.5, 0),
    (-75.7, -19.9, 1),
    (-75.7, -15.7, 1),
    (-75.5, -25.5, 0),
    (-75.4, 24.4, 1),
    (-73.3, -17.7, 1),
    (-73.2, 18.3, 1),
    (-73.0, -22.2, 1),
    (-73.0, 22.1, 1),
    (-70.8, 27.9, 1),
    (-70.4, 23.8, 1),
    (-70.2, 19.7, 1),
    (-70.2, -18.5, 0),
    (-69.5, -21.7, 0),
    (-67.7, 17.5, 1),
    (-67.1, -25.7, 1),
    (-66.7, -17.8, 1),
    (-66.6, 25.4, 1),
    (-64.7, 14.3, 0),
    (-64.3, -22.3, 0),
    (-63.6, -25.4, 0),
    (-63.3, 27.6, 1),
    (-63.3, 19.5, 1),
    (-63.3, 23.9, 1),
    (-61.5, -27.6, 0),
    (-61.4, -23.5, 0),
    (-61.0, -20.1, 0),
    (-61.0, -15.9, 0),
    (-60.9, 15.8, 0),
    (-60.8, 25.5, 1),
    (-58.3, 13.6, 0),
    (-58.2, -18.4, 0),
    (-58.2, 21.7, 0),
    (-58.1, 27.4, 1),
    (-57.7, -23.8, 1),
    (-57.5, 18.2, 0),
    (-57.2, -27.4, 1),
    (-55.2, 20.4, 0),
    (-54.9, -22.5, 1),
    (-54.9, -15.8, 0),
    (-54.4, 16.1, 0),
    (-54.3, 23.6, 0),
    (-52.8, -20.1, 1),
    (-52.7, 27.8, 1),
    (-52.6, -27.9, 1),
    (-51.9, -15.9, 1),
    (-51.8, 18.3, 0),
    (-51.6, -23.9, 1),
    (-51.5, 21.6, 0),
    (-51.3, 13.8, 0),
    (-49.7, -26.4, 1),
    (-49.3, -17.4, 1),
    (-48.8, 27.9, 0),
    (-48.7, -22.5, 1),
    (-48.3, 24.5, 0),
    (-46.5, 20.5, 1),
    (-46.5, 15.4, 1),
    (-46.2, -27.7, 1),
    (-46.1, -17.8, 0),
    (-45.8, 26.2, 0),
    (-43.8, 23.4, 0),
    (-43.5, 15.9, 0),
    (-43.4, -24.1, 0),
    (-43.3, -20.3, 0),
    (-43.1, -15.7, 0),
    (-42.3, 20.6, 0),
    (-40.6, -25.6, 0),
    (-40.5, -22.5, 0),
    (-40.3, 15.9, 1),
    (-39.8, -18.2, 0),
    (-39.6, 27.8, 1),
    (-39.4, 24.1, 1),
    (-37.8, -16.0, 0),
    (-37.0, 19.9, 0),
    (-36.9, -20.5, 0),
    (-36.8, 25.8, 1),
    (-36.5, -24.5, 0),
    (-34.5, -17.8, 0),
    (-34.4, -26.5, 0),
    (-33.8, 23.9, 1),
    (-33.6, -22.1, 0),
    (-31.2, 27.5, 0),
    (-31.0, 24.5, 0),
    (-31.0, 19.9, 0),
    (-30.7, -26.4, 1),
    (-30.4, -22.0, 1),
    (-30.4, -17.7, 1),
    (-28.2, -24.2, 1),
    (-28.0, 17.9, 0),
    (-27.8, 27.4, 1),
    (-27.3, 22.4, 0),
    (-27.2, -16.6, 1),
    (-25.5, -25.5, 1),
    (-25.1, 24.6, 0),
    (-25.1, 20.1, 0),
    (-24.8, -20.3, 0),
    (-22.5, 22.5, 0),
    (-21.9, -20.5, 1),
    (-21.5, -25.9, 0),
    (-19.6, 24.6, 0),
    (-19.1, 21.4, 1),
    (-18.9, -21.7, 1),
    (-9.4, 16.2, 1),
]
for k, (s_, lat, t) in enumerate(LOTS):
    glb = "plants/lotus_cluster.glb" if t == 0 else "plants/water_lily_pads.glb"
    ITEMS.append((f"D_Lot{k}", glb, fr(s_), lat, (k * 137) % 360, {"y": WATER_Y, "coliziune": "none", "scale": 1.35}))

# Zidul de incinta Angkor Thom de o parte si de alta a portii (19 m): blocuri de laterita (1,0 x 0,6 x 0,52
# la scara 1) la scara 2,6, trei randuri, rosturi decalate; scade spre capete (ruina). Incepe la 10 m de
# axa (poarta ocupa +-9,5), deci cel mai apropiat colt e la >= 5 m de asfalt (contract: >= 3 m).
BLK = 2.6
for side, sg in (("L", -1), ("R", 1)):
    for course in range(3):
        n = 13 - course * 3
        for k in range(n):
            lat = 10.4 + BLK * 0.5 + k * BLK + (BLK * 0.5 if course == 1 else 0.0)
            ITEMS.append((f"D_Zid{side}{course}_{k}", "props/laterite_block.glb", fr(0.0), sg * lat, 0,
                          {"scale": BLK, "dy": -0.4 + course * 0.58 * BLK}))

# Moloz la poalele portii si pe capetele zidului.
EXTRA = [
    ("D_MolozL", "props/rubble_pile.glb", -5.0, -11.5, 30, {}),
    ("D_MolozR", "props/rubble_pile.glb", -4.0, 12.0, -50, {}),
    ("D_BlocL", "props/fallen_block.glb", 7.0, -13.5, 20, {}),
    ("D_BlocR", "props/fallen_block.glb", 6.0, 14.5, 70, {}),
]
for nm, g, s_, lat, yw, o in EXTRA:
    ITEMS.append((nm, g, fr(s_), lat, yw, o))
