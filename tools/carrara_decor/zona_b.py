# Decorul POI-ului B pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("B_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.

# Geometria masurata (ProbeCarraraMontaj --scan, 31 oct 2026), lateral + = dreapta sensului:
#   T1 0.058-0.093 (+25, spre E): berma din cod la +6, bancul +7.5..+12.5, buza la +13 (jos: platoul lui T2);
#       stanga plata (+24.3) pana departe.
#   ac1 0.094-0.118 (dreapta): interiorul = dreapta, NIMIC acolo; exteriorul = stanga.
#   rampa 0.118-0.145 (spre V): stanga cade la -12 (fara berma, fara plasa), dreapta = platoul T2.
#   T2 0.145-0.168 (+16, spre V): berma la -6, bancul -7.5..-11, buza la -12; dreapta plata pana la
#       peretele F1 de la +21..+24. PlasaA ocupa +13.5..+25 (banda de cadere de pe T1): decorul sta sub +13.
#   ac2 0.178-0.208 (stanga): interiorul = stanga, NIMIC acolo; exteriorul = dreapta.
#   rampa 0.208-0.232 (spre E): dreapta cade la +13 spre fund (0.5); stanga = platoul T3.
#   T3 0.232-0.266 (+7, spre E): berma la +6, bancul +7.5..+12.5, buza la +13; stanga plata pana la
#       peretele F2 de la -26. PlasaT2 ocupa -14..-25.5 pana la x -6 (frac 0.247): dupa ea, piciorul
#       peretelui e liber.
# Camionul 1 (spre noi): banda stanga pe T1, T2 (dupa 0.160) si T3; banda dreapta pe ac1 si rampa lui.
# Decorul sta pe partea opusa, sau la >= 8 m de banda lui (generatorul marcheaza sub 6 m).
# Masinile de fir: yaw -150 pe dreapta (+150 pe stanga) ca fata volantului (axa X) sa se vada din camera
# de joc; pe peretele F2 yaw +90, firul (-Z) spre perete. Volantul se invarte (windmill.gd pe `Blades`).
SAW = "vehicles/wire_saw.glb"
# Runda 2 (criticul orb): "cordonul" — sir CONTINUU si neregulat de blocuri mici si bolovani crem pe ambele
# margini ale drumului si pe buza fiecarui banc, in locul blocurilor solitare din plin camp. Piesele de cordon
# sunt FANTOME ("coliziune": "none", decizia 2 a coordonatorului): se vad, nu au corp, nu schimba cursa.
# Raman cu hull doar sirurile masurate in runda 1 (buza bancurilor, muchia rampelor fara berma) si utilajele.
# Cordonul se genereaza aici din axa coapta (tools/data/carrara_baked.csv): pas pe lungime de arc, cu "along"
# pentru restul de sub un punct coapt (frac pe INDEX e cuantizata la ~2 m, pasul ar sari).
import csv as _csv
import math as _m
import os as _os
import random as _random

_BAKED = _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "data", "carrara_baked.csv")
_PTS = [tuple(map(float, r.values())) for r in _csv.DictReader(open(_BAKED, encoding="utf-8"))]
_CUM = [0.0]
for _a, _b in zip(_PTS, _PTS[1:]):
    _CUM.append(_CUM[-1] + _m.hypot(_b[0] - _a[0], _b[2] - _a[2]))


def _idx(fr):
    return min(range(len(_PTS)), key=lambda i: abs(_PTS[i][4] - fr))


def _s_of(fr, along=0.0):
    """Lungimea de arc (m) a punctului coapt cel mai apropiat de `fr`, plus `along`."""
    return _CUM[_idx(fr)] + along


def _at(s):
    """(frac exacta a punctului coapt, along) pentru lungimea de arc `s`."""
    i = min(range(len(_CUM)), key=lambda k: abs(_CUM[k] - s))
    return _PTS[i][4], round(s - _CUM[i], 2)


def _spin(phase):
    return {"spin": {"axis": (1, 0, 0), "rpm": 30, "phase": phase}}


GHOST = {"coliziune": "none"}

FIX = [
    # ---- T1: buza bancului din dreapta (sirul cu hull din runda 1)
    ("B_T1_Rand1", "rocks/marble_block_b.glb", 0.061, 11.0, 8.0),
    ("B_T1_Rand2", "rocks/block_stack_a.glb", 0.066, 10.8, -5.0),
    ("B_T1_Rand3", "rocks/block_informe_b.glb", 0.080, 10.3, 20.0),
    ("B_T1_Rand4", "rocks/marble_block_a.glb", 0.0835, 11.2, -12.0),
    ("B_T1_Rand5", "rocks/block_stack_b.glb", 0.088, 10.8, 6.0),
    ("B_T1_Rand6", "rocks/marble_block_a.glb", 0.0585, 11.2, 14.0, {"scale": 0.8}),
    ("B_T1_Rand7", "rocks/marble_block_b.glb", 0.0635, 11.3, -9.0, {"scale": 0.7}),
    ("B_T1_Rand8", "rocks/marble_block_a.glb", 0.0780, 11.3, 5.0, {"scale": 0.9}),
    ("B_T1_Rand9", "rocks/marble_block_b.glb", 0.0858, 10.9, 18.0, {"scale": 0.75}),
    ("B_T1_Rand10", "rocks/marble_block_a.glb", 0.0905, 10.6, -6.0, {"scale": 0.8}),
    # grup de lucru 1 (T1 dreapta): masina de fir + mosor + bloc proaspat taiat
    ("B_T1_Mosor", "props/cable_reel.glb", 0.0685, 8.6, 30.0),
    ("B_T1_Sarma", SAW, 0.0715, 9.9, -150.0, _spin(0.0)),
    ("B_T1_Taiat", "rocks/marble_block_c.glb", 0.0755, 10.6, 90.0),
    # grup de lucru 2 (T1 stanga, camp plat, la > 9 m de banda camionului): forajul + mosor + bloc taiat
    ("B_T1_Foraj", "vehicles/drill_rig.glb", 0.0805, -14.5, 90.0),
    ("B_T1_Mosor2", "props/cable_reel.glb", 0.0775, -11.8, -25.0),
    ("B_T1_Taiat2", "rocks/marble_block_c.glb", 0.0850, -15.5, 75.0),
    # ---- ac1: berme doar la varf, pe EXTERIOR (stanga), panta (-X) spre drum = yaw 180
    ("B_Ac1_Berma1", "structures/safety_berm.glb", 0.101, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Berma2", "structures/safety_berm.glb", 0.105, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Berma3", "structures/safety_berm.glb", 0.109, -10.0, 180.0, {"tilt": True}),
    # grup de lucru 3 (exteriorul acului 1, dincolo de berme; camionul trece pe interior)
    ("B_Ac1_Sarma", SAW, 0.1050, -16.0, 150.0, _spin(300.0)),
    ("B_Ac1_Taiat", "rocks/marble_block_c.glb", 0.1015, -16.5, 20.0),
    # ---- rampa ac1 -> T2: muchia din stanga (fara berma), sirul cu hull din runda 1
    ("B_R1_Rand1", "rocks/marble_block_b.glb", 0.124, -9.8, 6.0),
    ("B_R1_Rand2", "rocks/marble_block_a.glb", 0.131, -9.9, -9.0),
    ("B_R1_Rand3", "rocks/block_informe_b.glb", 0.138, -9.8, 25.0),
    ("B_R1_Rand4", "rocks/marble_block_a.glb", 0.1275, -10.0, 12.0, {"scale": 0.8}),
    ("B_R1_Rand5", "rocks/marble_block_b.glb", 0.1345, -10.0, -5.0, {"scale": 0.75}),
    ("B_R1_Rand6", "rocks/marble_block_a.glb", 0.1415, -10.1, 20.0, {"scale": 0.9}),
    # ---- T2: buza bancului din stanga (hull, runda 1)
    ("B_T2_R1", "rocks/marble_block_b.glb", 0.148, -10.0, 5.0),
    ("B_T2_R2", "rocks/block_stack_a.glb", 0.154, -10.0, -8.0),
    ("B_T2_R3", "rocks/marble_block_a.glb", 0.159, -10.2, 10.0),
    ("B_T2_R4", "rocks/block_informe_b.glb", 0.164, -10.0, 30.0),
    ("B_T2_R5", "rocks/marble_block_b.glb", 0.170, -10.2, -4.0),
    ("B_T2_R6", "rocks/marble_block_a.glb", 0.1455, -10.3, -14.0, {"scale": 0.8}),
    ("B_T2_R7", "rocks/marble_block_b.glb", 0.1510, -10.2, 8.0, {"scale": 0.7}),
    ("B_T2_R8", "rocks/marble_block_a.glb", 0.1563, -10.3, 3.0, {"scale": 0.9}),
    ("B_T2_R9", "rocks/marble_block_b.glb", 0.1615, -10.2, -10.0, {"scale": 0.75}),
    ("B_T2_R10", "rocks/marble_block_a.glb", 0.1672, -10.3, 16.0, {"scale": 0.8}),
    # grup de lucru 4 (T2 dreapta, de la 0.1595: pana acolo camionul e pe banda dreapta)
    ("B_T2_Mosor", "props/cable_reel.glb", 0.1625, 9.6, 15.0),
    ("B_T2_Moloz", "rocks/rubble_pile_b.glb", 0.1595, 12.2, 40.0),
    ("B_T2_Sarma2", SAW, 0.165, 10.3, -150.0, _spin(240.0)),
    ("B_T2_Taiat2", "rocks/block_informe_a.glb", 0.1685, 11.3, 25.0),
    # ---- ac2: berme la varf, pe EXTERIOR (dreapta), panta spre drum = yaw 0
    ("B_Ac2_Berma1", "structures/safety_berm.glb", 0.193, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Berma2", "structures/safety_berm.glb", 0.197, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Berma3", "structures/safety_berm.glb", 0.201, 10.0, 0.0, {"tilt": True}),
    # grup de lucru 5 (exteriorul acului 2, dincolo de berme): cabluri + bloc taiat
    ("B_Ac2_Teava", "props/pipe_run.glb", 0.1965, 13.8, 0.0),
    ("B_Ac2_Mosor", "props/cable_reel.glb", 0.2005, 13.5, 40.0),
    ("B_Ac2_Taiat", "rocks/marble_block_c.glb", 0.1925, 14.0, 80.0),
    # ---- rampa ac2 -> T3: muchia din dreapta (fara berma), sirul cu hull din runda 1
    ("B_R2_Rand1", "rocks/marble_block_b.glb", 0.212, 10.0, -6.0),
    ("B_R2_Rand2", "rocks/block_informe_b.glb", 0.220, 10.0, 15.0),
    ("B_R2_Rand3", "rocks/marble_block_a.glb", 0.227, 10.2, 4.0),
    ("B_R2_Rand4", "rocks/marble_block_a.glb", 0.2160, 10.2, 9.0, {"scale": 0.8}),
    ("B_R2_Rand5", "rocks/marble_block_b.glb", 0.2235, 10.1, -12.0, {"scale": 0.75}),
    ("B_R2_Rand6", "rocks/marble_block_a.glb", 0.2300, 10.3, 2.0, {"scale": 0.9}),
    # ---- T3: buza bancului din dreapta (hull, runda 1) + grup de lucru 6
    ("B_T3_R1", "rocks/block_stack_b.glb", 0.234, 10.8, -4.0),
    ("B_T3_Mosor", "props/cable_reel.glb", 0.2385, 8.4, -30.0),
    ("B_T3_Sarma", SAW, 0.241, 9.9, -150.0, _spin(60.0)),
    ("B_T3_Taiat", "rocks/marble_block_c.glb", 0.2445, 10.8, 90.0),
    ("B_T3_R2", "rocks/marble_block_a.glb", 0.250, 11.2, 7.0),
    ("B_T3_R3", "rocks/block_informe_b.glb", 0.255, 10.8, -20.0),
    ("B_T3_R4", "rocks/marble_block_b.glb", 0.260, 11.0, 5.0),
    ("B_T3_R5", "rocks/block_stack_a.glb", 0.264, 10.8, -7.0),
    ("B_T3_R6", "rocks/marble_block_a.glb", 0.2365, 11.2, 10.0, {"scale": 0.8}),
    ("B_T3_R7", "rocks/marble_block_b.glb", 0.2475, 11.1, -8.0, {"scale": 0.7}),
    ("B_T3_R8", "rocks/marble_block_a.glb", 0.2528, 11.3, 15.0, {"scale": 0.9}),
    ("B_T3_R10", "rocks/marble_block_a.glb", 0.2620, 11.2, 20.0, {"scale": 0.8}),
]

# Jumatatea de gabarit (in lung, lateral; m, la scara 1) a pieselor fixe, ca cordonul sa le ocoleasca.
_HALF = {"wire_saw": (3.2, 2.5), "drill_rig": (1.9, 3.1), "cable_reel": (1.0, 1.0), "marble_block_c": (1.7, 1.7),
         "safety_berm": (3.1, 0.8), "pipe_run": (3.1, 0.5), "block_informe_a": (1.6, 1.6)}

# Paleta cordonului: (glb, scala min, scala max, pondere). Bolovani si blocuri mici, NU stive.
_CORDON = [("rocks/marble_block_a.glb", 0.40, 0.70, 4), ("rocks/marble_block_b.glb", 0.35, 0.60, 3),
           ("rocks/marble_block_c.glb", 0.35, 0.50, 2), ("rocks/block_informe_b.glb", 0.40, 0.65, 3),
           ("rocks/block_informe_a.glb", 0.30, 0.40, 1), ("rocks/rubble_pile_b.glb", 0.45, 0.70, 3),
           ("rocks/rubble_pile_a.glb", 0.35, 0.50, 2)]
# Pe buza bancurilor doar piese mici: una care trece de buza ar lua cota platoului de dedesubt.
_MIC = [("rocks/marble_block_a.glb", 0.40, 0.65, 4), ("rocks/marble_block_b.glb", 0.35, 0.55, 3),
        ("rocks/block_informe_b.glb", 0.40, 0.60, 3), ("rocks/rubble_pile_b.glb", 0.40, 0.55, 2)]
# Molozul de la piciorul peretilor: sub 1,5 m (decizia 4), in volumul plasei, fantoma.
_MOLOZ = [("rocks/rubble_pile_a.glb", 0.70, 1.00, 3), ("rocks/rubble_pile_b.glb", 0.80, 1.20, 3),
          ("rocks/marble_block_a.glb", 0.50, 0.80, 2), ("rocks/block_informe_b.glb", 0.50, 0.80, 2)]

# Liniile de cordon: (prefix, frac0, frac1, lateral, jitter lateral, pas min, pas max, paleta).
# Marginile drumului: dincolo de berma din cod (+-6), la 7.8; pe partea camionului la 8.8 (generatorul cere > 6 m
# de banda lui, chiar daca piesele sunt fantome). Interiorul acelor ramane gol (linia de cursa si scaparea AI-ului, contractul B).
_LINII = [
    ("B_CT1D", 0.0585, 0.0860, 7.8, 0.35, 2.8, 4.0, _CORDON),   # T1, marginea dreapta (dupa berma)
    ("B_CT1E", 0.0862, 0.0935, 8.8, 0.25, 2.8, 4.0, _CORDON),   # T1, capatul: camionul trece pe banda dreapta
    ("B_CT1M", 0.0585, 0.0935, 11.0, 0.25, 2.8, 4.2, _MIC),     # T1, buza bancului (sus pe F1)
    ("B_CT1S", 0.0610, 0.0935, -8.8, 0.35, 3.2, 4.8, _CORDON),  # T1, marginea stanga (camp plat)
    ("B_CA1", 0.0945, 0.1180, -7.9, 0.30, 3.3, 4.4, _CORDON),   # ac1, exteriorul
    ("B_CR1M", 0.1185, 0.1450, -10.1, 0.25, 2.8, 4.0, _MIC),    # rampa ac1, muchia din stanga (printre hull)
    ("B_CT2S", 0.1455, 0.1770, -8.8, 0.30, 2.8, 4.0, _CORDON),  # T2, marginea stanga (dupa berma)
    ("B_CT2M", 0.1455, 0.1770, -10.6, 0.20, 3.0, 4.4, _MIC),    # T2, buza bancului
    ("B_CT2D", 0.1455, 0.1770, 8.8, 0.35, 3.2, 4.8, _CORDON),   # T2, marginea dreapta (platou)
    ("B_CA2", 0.1780, 0.2080, 7.9, 0.30, 3.3, 4.4, _CORDON),    # ac2, exteriorul
    ("B_CR2M", 0.2085, 0.2320, 10.9, 0.20, 2.8, 4.0, _MIC),     # rampa ac2, muchia din dreapta (printre hull)
    ("B_CT3D", 0.2325, 0.2660, 7.8, 0.35, 2.8, 4.0, _CORDON),   # T3, marginea dreapta (dupa berma)
    ("B_CT3M", 0.2325, 0.2660, 11.1, 0.20, 3.0, 4.4, _MIC),     # T3, buza bancului
    ("B_CT3S", 0.2325, 0.2660, -8.8, 0.35, 3.2, 4.8, _CORDON),  # T3, marginea stanga (platou)
    ("B_MF1", 0.1470, 0.1760, 20.2, 0.6, 5.5, 8.0, _MOLOZ),     # piciorul lui F1 (in PlasaA)
]


def _cordon():
    rng = _random.Random(2310)
    fixed = []
    for it in FIX:
        o = it[5] if len(it) > 5 else {}
        st = it[1].split("/")[-1].replace(".glb", "")
        hl, hw = _HALF.get(st, (1.4, 1.4))
        k = o.get("scale", 1.0)
        fixed.append((_s_of(it[2], o.get("along", 0.0)), it[3], hl * k + 0.4, hw * k + 0.4))
    out = []
    for pre, f0, f1, lat0, jit, p0, p1, pal in _LINII:
        s, s1, n = _s_of(f0), _s_of(f1), 0
        wsum = sum(c[3] for c in pal)
        while s < s1:
            r, acc, c = rng.uniform(0, wsum), 0.0, pal[0]
            for c in pal:
                acc += c[3]
                if r <= acc:
                    break
            lat = lat0 + rng.uniform(-jit, jit)
            k = round(rng.uniform(c[1], c[2]), 2)
            yaw = round(rng.uniform(-40.0, 40.0) + (90.0 if rng.random() < 0.3 else 0.0), 1)
            if not any(abs(s - fs) < fl and abs(lat - fla) < fw for fs, fla, fl, fw in fixed):
                fr, al = _at(s)
                n += 1
                out.append((f"{pre}{n}", c[0], fr, round(lat, 2), yaw, dict(GHOST, scale=k, along=al)))
            s += rng.uniform(p0, p1)
    return out


ITEMS = FIX + _cordon()

KIT_Y = {
    "B_T1_Rand1": 24.67, "B_T1_Rand2": 24.67, "B_T1_Rand3": 24.23, "B_T1_Rand4": 23.77, "B_T1_Rand5": 22.82,
    "B_T1_Rand6": 24.67, "B_T1_Rand7": 24.67, "B_T1_Rand8": 24.44, "B_T1_Rand9": 23.21, "B_T1_Rand10": 22.51,
    "B_T1_Sarma": 24.67, "B_T1_Taiat": 24.6, "B_T1_Foraj": 24.02, "B_T1_Taiat2": 23.51, "B_Ac1_Berma1": 21.72,
    "B_Ac1_Berma2": 20.97, "B_Ac1_Berma3": 19.99, "B_Ac1_Sarma": 20.38, "B_Ac1_Taiat": 21.28, "B_R1_Rand1": 17.6,
    "B_R1_Rand2": 17.21, "B_R1_Rand3": 16.38, "B_R1_Rand4": 17.36, "B_R1_Rand5": 16.91, "B_R1_Rand6": 16.11,
    "B_T2_R1": 15.67, "B_T2_R2": 15.67, "B_T2_R3": 15.67, "B_T2_R4": 15.64, "B_T2_R5": 15.32,
    "B_T2_R6": 15.74, "B_T2_R7": 15.67, "B_T2_R8": 15.67, "B_T2_R9": 15.66, "B_T2_R10": 15.58,
    "B_T2_Moloz": 15.67, "B_T2_Sarma2": 15.61, "B_T2_Taiat2": 15.45, "B_Ac2_Berma1": 12.41, "B_Ac2_Berma2": 11.78,
    "B_Ac2_Berma3": 11.16, "B_Ac2_Teava": 11.76, "B_Ac2_Taiat": 12.6, "B_R2_Rand1": 9.55, "B_R2_Rand2": 8.47,
    "B_R2_Rand3": 7.47, "B_R2_Rand4": 9.09, "B_R2_Rand5": 7.97, "B_R2_Rand6": 7.07, "B_T3_R1": 6.78,
    "B_T3_Sarma": 6.67, "B_T3_Taiat": 6.67, "B_T3_R2": 6.67, "B_T3_R3": 6.67, "B_T3_R4": 6.6,
    "B_T3_R5": 6.45, "B_T3_R6": 6.71, "B_T3_R7": 6.67, "B_T3_R8": 6.67, "B_T3_R10": 6.55,
    "B_CT1D1": 24.67, "B_CT1D2": 24.67, "B_CT1D3": 24.67, "B_CT1D4": 24.67, "B_CT1D5": 24.67,
    "B_CT1D6": 24.67, "B_CT1D7": 24.67, "B_CT1D8": 24.62, "B_CT1D9": 24.58, "B_CT1D10": 24.49,
    "B_CT1D11": 24.33, "B_CT1D12": 24.17, "B_CT1D13": 23.87, "B_CT1D14": 23.63, "B_CT1E1": 23.4,
    "B_CT1E2": 23.16, "B_CT1E3": 22.95, "B_CT1E4": 22.67, "B_CT1E5": 22.51, "B_CT1M1": 24.67,
    "B_CT1M2": 24.67, "B_CT1M3": 24.67, "B_CT1M4": 24.67, "B_CT1M5": 24.67, "B_CT1M6": 23.68,
    "B_CT1M7": 23.39, "B_CT1M8": 22.65, "B_CT1M9": 22.5, "B_CT1M10": 22.37, "B_CT1S1": 24.63,
    "B_CT1S2": 24.62, "B_CT1S3": 24.62, "B_CT1S4": 24.61, "B_CT1S5": 24.62, "B_CT1S6": 24.62,
    "B_CT1S7": 24.62, "B_CT1S8": 24.57, "B_CT1S9": 24.5, "B_CT1S10": 24.39, "B_CT1S11": 24.22,
    "B_CT1S12": 24.0, "B_CT1S13": 23.67, "B_CT1S14": 23.45, "B_CT1S15": 23.22, "B_CT1S16": 22.96,
    "B_CT1S17": 22.67, "B_CA11": 22.48, "B_CA12": 22.24, "B_CA13": 21.96, "B_CA14": 21.75,
    "B_CA15": 21.45, "B_CA16": 21.17, "B_CA17": 20.9, "B_CA18": 20.65, "B_CA19": 20.3,
    "B_CA110": 20.0, "B_CA111": 19.69, "B_CA112": 19.44, "B_CA113": 18.84, "B_CR1M1": 18.03,
    "B_CR1M2": 17.99, "B_CR1M3": 17.78, "B_CR1M4": 17.37, "B_CR1M5": 17.31, "B_CR1M6": 17.16,
    "B_CR1M7": 16.74, "B_CR1M8": 16.3, "B_CR1M9": 15.96, "B_CR1M10": 15.79, "B_CT2S1": 15.75,
    "B_CT2S2": 15.71, "B_CT2S3": 15.67, "B_CT2S4": 15.67, "B_CT2S5": 15.67, "B_CT2S6": 15.66,
    "B_CT2S7": 15.61, "B_CT2S8": 15.21, "B_CT2S9": 14.96, "B_CT2S10": 14.75, "B_CT2S11": 14.5,
    "B_CT2M1": 15.7, "B_CT2M2": 15.67, "B_CT2M3": 15.67, "B_CT2M4": 15.67, "B_CT2M5": 15.62,
    "B_CT2M6": 15.42, "B_CT2M7": 14.89, "B_CT2M8": 14.72, "B_CT2M9": 14.47, "B_CT2D1": 15.75,
    "B_CT2D2": 15.7, "B_CT2D3": 15.67, "B_CT2D4": 15.67, "B_CT2D5": 15.67, "B_CT2D6": 15.67,
    "B_CT2D7": 15.67, "B_CT2D8": 15.67, "B_CT2D9": 15.67, "B_CT2D10": 15.5, "B_CT2D11": 15.34,
    "B_CT2D12": 15.13, "B_CT2D13": 14.89, "B_CT2D14": 14.6, "B_CA21": 14.21, "B_CA22": 13.86,
    "B_CA23": 13.64, "B_CA24": 13.42, "B_CA25": 13.17, "B_CA26": 12.93, "B_CA27": 12.72,
    "B_CA28": 12.53, "B_CA29": 12.27, "B_CA210": 12.02, "B_CA211": 11.73, "B_CA212": 11.44,
    "B_CA213": 11.13, "B_CA214": 10.85, "B_CA215": 10.53, "B_CA216": 10.22, "B_CR2M1": 10.03,
    "B_CR2M2": 9.75, "B_CR2M3": 9.31, "B_CR2M4": 8.88, "B_CR2M5": 8.66, "B_CR2M6": 8.17,
    "B_CR2M7": 7.67, "B_CR2M8": 7.25, "B_CT3D1": 6.87, "B_CT3D2": 6.78, "B_CT3D3": 6.73,
    "B_CT3D4": 6.7, "B_CT3D5": 6.67, "B_CT3D6": 6.67, "B_CT3D7": 6.67, "B_CT3D8": 6.67,
    "B_CT3D9": 6.67, "B_CT3D10": 6.67, "B_CT3D11": 6.67, "B_CT3D12": 6.67, "B_CT3D13": 6.66,
    "B_CT3D14": 6.65, "B_CT3D15": 6.63, "B_CT3D16": 6.58, "B_CT3D17": 6.52, "B_CT3D18": 6.43,
    "B_CT3D19": 6.35, "B_CT3M1": 6.88, "B_CT3M2": 6.73, "B_CT3M3": 6.67, "B_CT3M4": 6.67,
    "B_CT3M5": 6.67, "B_CT3M6": 6.66, "B_CT3M7": 6.64, "B_CT3M8": 6.37, "B_CT3S1": 6.89,
    "B_CT3S2": 6.78, "B_CT3S3": 6.73, "B_CT3S4": 6.7, "B_CT3S5": 6.67, "B_CT3S6": 6.67,
    "B_CT3S7": 6.67, "B_CT3S8": 6.67, "B_CT3S9": 6.67, "B_CT3S10": 6.67, "B_CT3S11": 6.67,
    "B_CT3S12": 6.67, "B_CT3S13": 6.67, "B_CT3S14": 6.65, "B_CT3S15": 6.61, "B_CT3S16": 6.56,
    "B_CT3S17": 6.5, "B_CT3S18": 6.45, "B_MF11": 15.71, "B_MF12": 15.67, "B_MF13": 15.67,
    "B_MF14": 15.67, "B_MF15": 15.67, "B_MF16": 15.66, "B_MF17": 15.6, "B_MF18": 15.39,
    "B_MF19": 15.0, "B_MF110": 14.59,
    # mosoarele nu apar in --decor (mesh-ul lor intra in coacerea DecorManual): cota din --scan, teren plat
    "B_T1_Mosor": 24.67, "B_T2_Mosor": 15.67,
    "B_T1_Mosor2": 24.37, "B_Ac2_Mosor": 11.07, "B_T3_Mosor": 6.67,
}
