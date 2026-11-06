# Decorul POI-ului A pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.000-0.058.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("A_...")
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

import math
import random

# ---- A: calea de vest peste santul Angkor Wat --------------------------------------------------------------
# Apa santului: WATER_AW = 0,5 (generator). Linia malului (terenul trece prin 0,5), MASURATA cu
# ProbeCarraraMontaj pe o grila de lotusi de proba, pe stanga/dreapta: (frac, lateral m, valoare absoluta).
# Santul e apa de la ~0,019 la ~0,054; inainte si dupa e uscat (grila de start, gopura).
WATER_Y = 0.5
BANK_L = [(0.020, 14.3), (0.024, 12.3), (0.028, 12.2), (0.032, 12.0), (0.036, 12.0), (0.040, 12.2),
          (0.044, 12.3), (0.048, 12.9), (0.052, 15.4)]
BANK_R = [(0.020, 16.3), (0.024, 13.5), (0.028, 12.0), (0.032, 9.2), (0.036, 8.8), (0.040, 9.6),
          (0.044, 11.2), (0.048, 14.2), (0.052, 15.7)]
M_PER_FRAC = 2406.0     # lungimea turului; 0,01 pe index ~ 24 m pe axa (dreapta, fara viraje pe A)
F0, F1 = 0.0205, 0.0525


def _bank(tab, f):
    f = min(max(f, tab[0][0]), tab[-1][0])
    for (fa, la), (fb, lb) in zip(tab, tab[1:]):
        if fa <= f <= fb:
            return la + (lb - la) * (f - fa) / (fb - fa)
    return tab[-1][1]


def _place(name, glb, f, lat, yaw, **opt):
    return (name, glb, f, lat, yaw, dict({"coliziune": "none"}, **opt))


SKIP_KERB = {("R", 35)}      # pe dreapta, la ~0,036 malul se strange la 9 m si taluzul ingroapta blocul (probe_manual)
ITEMS = []
_rng = random.Random(2406)

# 1) Lotusi si nuferi: petice (drifts) pe toata apa vizibila din cale, pe fiecare mal.
#    Fiecare petic = centru (frac, lateral de la mal) + 7-13 piese in raza ~4-6 m; intre petice, piese singure.
for side, tab, tag in ((-1, BANK_L, "L"), (1, BANK_R, "R")):
    n = 0
    for k in range(21):
        fc = F0 + (F1 - F0) * (k + _rng.random() * 0.8) / 21.0
        dist = 3.5 + (_rng.random() ** 1.6) * 28.0                     # metri de la mal spre larg
        pieces = _rng.randint(7, 13)
        rad = 3.0 + _rng.random() * 3.0
        for j in range(pieces):
            a = _rng.random() * 2 * math.pi
            r = rad * math.sqrt(_rng.random())
            al = r * math.cos(a)                              # m pe axa
            dl = dist + r * math.sin(a)
            f = fc + al / M_PER_FRAC
            if not (F0 - 0.001 <= f <= F1 + 0.001):
                continue
            lat = side * (_bank(tab, f) + max(2.6, dl))
            flower = _rng.random() < 0.42
            sc = (1.4 + _rng.random() * 1.0) if flower else (1.8 + _rng.random() * 1.6)
            ITEMS.append(_place(f"A_Lot{tag}{n}", "plants/lotus_cluster.glb" if flower else "plants/water_lily_pads.glb",
                                f, lat, _rng.random() * 360.0, scale=round(sc, 2), y=WATER_Y))
            n += 1

# 2) Pervaz de piatra pe linia malului (laterita, un rand, intrerupt): santul citeste ca bazin cu margine
#    zidita. `scufundat`: jumatate din bloc intra in mal; fara corp (coliziune none).
for side, tab, tag in ((-1, BANK_L, "L"), (1, BANK_R, "R")):
    m = F0 * M_PER_FRAC
    n = 0
    while m < F1 * M_PER_FRAC:
        f = m / M_PER_FRAC
        if _rng.random() > 0.07 and (tag, n) not in SKIP_KERB:                              # ~7% goluri (blocuri cazute in apa)
            ITEMS.append(_place(f"A_Kerb{tag}{n}", "props/laterite_block.glb", f, side * (_bank(tab, f) + 0.35),
                                90.0 + (_rng.random() - 0.5) * 5.0, y=WATER_Y + 0.02, scale=1.5, scufundat=True))
        n += 1
        m += 1.58

KIT_Y = {
    "A_RubL0": 2.06,
    "A_RubL1": 1.96,
    "A_RubL2": 2.11,
    "A_RubL3": 2.24,
    "A_RubL4": 2.49,
    "A_RubR0": 1.58,
    "A_RubR1": 1.54,
    "A_RubR2": 0.71,
    "A_RubR3": 1.61,
    "A_RubR4": 2.22,
}

# 3) Moloz si blocuri cazute la baza balustradei, DINCOLO de ea (lateral 7,0-8,2): nu intra in banda drumului.
#    Doar pe 0,027-0,054, rar. Cota din ProbeCarraraMontaj (teren minim - 3 cm), in KIT_Y.
for side, tag in ((-1, "L"), (1, "R")):
    for k, f in enumerate((0.0275, 0.0330, 0.0385, 0.0440, 0.0495)):
        f += (_rng.random() - 0.5) * 0.002
        nm = f"A_Rub{tag}{k}"
        ITEMS.append(_place(nm, "props/rubble_pile.glb" if k % 2 == 0 else "props/fallen_block.glb", f,
                            side * (7.0 + _rng.random() * 1.2), _rng.random() * 360.0,
                            scale=round(0.9 + _rng.random() * 0.3, 2) if k % 2 == 0 else 0.45))
