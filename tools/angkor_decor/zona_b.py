# Decorul POI-ului B pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.058-0.114.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("B_...")
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

ITEMS = [
]

KIT_Y = {
}

import math
import random

# ---- B: prin Angkor Wat ----------------------------------------------------------------------------------
# Geometria (harta, x spre E, y spre N; Godot z = -y): gopura de vest la x -97,5; arcul R30 cu centrul in
# (-86, 30) de la (-86, 0) la (-56, 30); apoi dreapta spre N la x = -56 pana la y 104. Templul in origine,
# +-32 m. Gazonul = luminisul junglei (disc r 78 la origine), plat la ~3,65-3,70 (masurat cu ProbeCarraraMontaj
# pe o grila de piese de proba). Santul de nord (apa la 0,5) intre frac ~0,1025 si ~0,111.
# Regula de 18 m: pe INTERIORUL arcului (la <= 12 m de centrul (-86, 30)) nimic cu corp; nimic nou in gopura.
# Tot ce e langa banda (< 10 m de margine) e fara coliziune; corpurile (terase) stau la >= 12 m.
M_PER_FRAC = 2406.0
WATER_Y = 0.5
G_LAWN = 3.62            # teren minim al gazonului - ~3 cm
G_GAL = 3.67             # in galerie (terenul 3,70)
AXIS_X = -56.0           # axa caii de nord

# Linia malului santului de nord (frac, lateral m de la axa pana la apa), din grila de proba (t_med < 0,5 + 1,5 m)
BANK = [(0.1025, 24.0), (0.1040, 17.5), (0.1055, 16.0), (0.1070, 16.0), (0.1085, 18.0), (0.1100, 25.0), (0.1110, 40.0)]
F0, F1 = 0.1030, 0.1105


def _bank(f):
    f = min(max(f, BANK[0][0]), BANK[-1][0])
    for (fa, la), (fb, lb) in zip(BANK, BANK[1:]):
        if fa <= f <= fb:
            return la + (lb - la) * (f - fa) / (fb - fa)
    return BANK[-1][1]


def _none(name, glb, f, lat, yaw, **opt):
    return (name, glb, f, lat, yaw, dict({"coliziune": "none"}, **opt))


def _w(name, glb, x, y, yaw, gy=G_LAWN, **opt):
    """Piesa pe harta (x, y harta), yaw absolut (0 = spre N, + = spre V), fara coliziune implicit."""
    return (name, glb, 0.0, 0.0, yaw, dict({"coliziune": "none", "world": (x, -y), "y": gy}, **opt))


ITEMS = []
_rng = random.Random(2458)

# 1) Calea procesionala a templului: doua balustrade naga joase (fara coliziune) pe y = +-3,2, de la x -58 la
#    capatul scarii (x -34), cu capete naga la templu. La >= 9 m de marginea exterioara a arcului.
BAL_X = [-56.0 + 4.0 * k for k in range(6)]
for side, tag in ((1, "N"), (-1, "S")):
    for k, x in enumerate(BAL_X):
        ITEMS.append(_w(f"B_Naga{tag}{k}", "kit/naga_balustrade.glb", x, side * 3.2, 90.0, gy=G_LAWN + 0.03))
    ITEMS.append(_w(f"B_NagaCap{tag}", "kit/naga_head.glb", -33.6, side * 3.2, 90.0, gy=G_LAWN + 0.03))

# 2) Macaci pe balustrade (teatru, statici): sus pe balustrada (baza + 1,03)
for k, (x, side, yw) in enumerate(((-54.0, 1, 40.0), (-49.5, -1, -30.0), (-45.0, 1, 100.0), (-41.0, -1, 20.0),
                                   (-37.0, 1, -50.0), (-52.0, -1, 150.0))):
    ITEMS.append(_w(f"B_Macac{k}", "res://assets/models/halong/animals/macaque.glb", x + 0.6, side * 3.2, yw,
                    gy=G_LAWN + 0.03 + 1.0, scale=1.9))

# 3) Calugari in sofran la scara templului, pe gazon in fata treptelor, departe de banda (>= 18 m)
for k, (x, y, yw) in enumerate(((-36.0, -5.5, 90.0), (-35.0, -2.0, 60.0), (-36.5, 1.5, 100.0), (-35.5, 5.0, 80.0),
                                (-44.0, 8.0, -90.0))):
    ITEMS.append(_w(f"B_Calugar{k}", "animals/monk_standing.glb", x, y, yw, scale=1.25))

# 4) Terase etajate pe dreapta (baze de turn, prea aproape ca sa incapa): trepte de gresie la x -38, dincolo de
#    10 m de banda; corp (hull) doar pe nivelul de jos
for k, y in enumerate((40.0, 48.0, 56.0)):
    ITEMS.append(("B_TerasaJos%d" % k, "kit/bakheng_terrace_tier.glb", 0.0, 0.0, 90.0,
                  {"world": (-38.0, -y), "y": G_LAWN, "scufundat": True}))
    ITEMS.append(_w(f"B_TerasaSus{k}", "kit/bakheng_terrace_tier.glb", -38.0, y, 90.0, gy=G_LAWN + 1.45, scale=0.7))
# (gopura de nord ocupa x -82..-30, y 62..74: restaurarea si blocul cazut stau la sud de ea)
ITEMS.append(_w("B_Restaurare0", "props/restoration_prop.glb", -46.0, 58.0, 20.0, coliziune="hull"))

# 5) Blocuri, moloz si blocuri numerotate pe gazon (jos, fara coliziune), in afara arcului si pe dreapta
_lawn_spots = [(-47.0, 10.0), (-44.0, 18.0), (-49.5, 26.0), (-46.0, 33.0), (-43.0, -9.0), (-50.0, -6.0),
               (-40.0, 24.0), (-47.0, 44.0), (-48.5, 52.0), (-45.0, 60.0), (-42.0, 32.0), (-46.0, -14.0),
               (-38.0, -12.0), (-40.5, 12.0), (-33.0, 17.0), (-34.0, -17.0)]
for k, (x, y) in enumerate(_lawn_spots):
    glb = ("props/rubble_pile.glb", "props/laterite_block.glb", "props/numbered_block.glb")[k % 3]
    ITEMS.append(_w(f"B_Gazon{k}", glb, x, y, _rng.random() * 360.0, scale=round(1.0 + _rng.random() * 0.5, 2),
                    scufundat=True))
for k, (x, y) in enumerate(((-31.0, 56.0), (-44.0, 40.0), (-35.0, -26.0))):
    ITEMS.append(_w(f"B_BlocCazut{k}", "props/fallen_block.glb", x, y, _rng.random() * 360.0, scale=0.8,
                    coliziune="hull", scufundat=True))

# 6) Moloz in culoarul galeriei (intre stalpi si zid), joase, la ~8 m de axa pe stanga
for k, y in enumerate((30.0, 38.0, 45.0, 53.0, 60.0)):
    ITEMS.append(_w(f"B_GalMoloz{k}", "props/rubble_pile.glb" if k % 2 == 0 else "props/numbered_block.glb",
                    -64.0 + _rng.random() * 0.8, y, _rng.random() * 360.0, gy=G_GAL, scale=1.1, scufundat=True))

# 7) Calea de nord: balustrada naga (cu coliziune, stil 3) si gopura de nord sunt in GENERATOR (`parapets`,
#    `GopuraNord`); aici raman doar lotusii pe apa ambelor bazine (tiparul lui A). Cota bazei dupa terenul medru
#    de sub umarul caii era 3,50 la intrare, 3,12 pe sant, 3,75 la iesire (masurat).
_f_bal0, _f_bal1 = 0.0995, 0.1148

for side, tag in ((-1, "L"), (1, "R")):
    n = 0
    for k in range(10):
        fc = F0 + (F1 - F0) * (k + _rng.random() * 0.8) / 10.0
        dist = 2.5 + (_rng.random() ** 1.5) * 14.0
        for j in range(_rng.randint(6, 10)):
            a = _rng.random() * 2 * math.pi
            r = (2.5 + _rng.random() * 2.5) * math.sqrt(_rng.random())
            f = fc + r * math.cos(a) / M_PER_FRAC
            if not (F0 - 0.0005 <= f <= F1 + 0.0005):
                continue
            lat = side * (_bank(f) + max(2.0, dist + r * math.sin(a)))
            flower = _rng.random() < 0.42
            sc = (1.4 + _rng.random()) if flower else (1.8 + _rng.random() * 1.6)
            ITEMS.append(_none(f"B_Lot{tag}{n}", "plants/lotus_cluster.glb" if flower else "plants/water_lily_pads.glb",
                               f, lat, _rng.random() * 360.0, scale=round(sc, 2), y=WATER_Y))
            n += 1

KIT_Y = {}
