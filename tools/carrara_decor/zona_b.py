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
# Runda 3 (criticul orb, al doilea): "o cariera lucreaza prin ordine". Blocurile taiate stau DREPT (yaw la axa
# drumului, +-3 grade), in SIRURI regulate (pas si scara constante pe segment) pe marginea drumului si pe buza
# fiecarui banc; molozul (rubble_pile, block_informe) iese din siruri si ramane doar la piciorul lui F1 si in
# jurul utilajelor; langa fiecare grup de lucru, stive ordonate de 2-3 blocuri (marfa de transport).
# Sirurile sunt FANTOME ("coliziune": "none", decizia 2 din runda 2): se vad, nu au corp. Sirurile cu hull din
# runda 1 (buza bancurilor, muchia rampelor) au intrat in sirurile regulate, deci au iesit si din fizica.
# Sirurile se genereaza din axa coapta (tools/data/carrara_baked.csv): pas pe lungime de arc, cu "along"
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
    # grup de lucru 1 (T1 dreapta): masina de fir + mosor + bloc proaspat taiat + stiva
    ("B_T1_Mosor", "props/cable_reel.glb", 0.0685, 8.6, 30.0),
    ("B_T1_Sarma", SAW, 0.0715, 9.9, -150.0, _spin(0.0)),
    ("B_T1_Taiat", "rocks/marble_block_c.glb", 0.0755, 10.6, 90.0),
    ("B_T1_Stiva", "rocks/block_stack_b.glb", 0.0785, 10.9, 0.0),
    # grup de lucru 2 (T1 stanga, camp plat, la > 9 m de banda camionului): forajul + mosor + bloc taiat + stive
    ("B_T1_Foraj", "vehicles/drill_rig.glb", 0.0805, -14.5, 90.0),
    ("B_T1_Mosor2", "props/cable_reel.glb", 0.0775, -11.8, -25.0),
    ("B_T1_Taiat2", "rocks/marble_block_c.glb", 0.0850, -15.5, 90.0),
    ("B_T1_Stiva2", "rocks/block_stack_b.glb", 0.0840, -12.3, 0.0),
    ("B_T1_Stiva3", "rocks/block_stack_a.glb", 0.0868, -12.4, 0.0),
    # ---- ac1: berme doar la varf, pe EXTERIOR (stanga), panta (-X) spre drum = yaw 180
    ("B_Ac1_Berma1", "structures/safety_berm.glb", 0.101, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Berma2", "structures/safety_berm.glb", 0.105, -10.0, 180.0, {"tilt": True}),
    ("B_Ac1_Berma3", "structures/safety_berm.glb", 0.109, -10.0, 180.0, {"tilt": True}),
    # grup de lucru 3 (exteriorul acului 1, dincolo de berme; camionul trece pe interior)
    ("B_Ac1_Sarma", SAW, 0.1050, -16.0, 150.0, _spin(300.0)),
    ("B_Ac1_Taiat", "rocks/marble_block_c.glb", 0.1015, -16.5, 0.0),
    ("B_Ac1_Stiva", "rocks/block_stack_a.glb", 0.1020, -19.5, 0.0),
    # grup de lucru 4 (T2 dreapta, de la 0.1595: pana acolo camionul e pe banda dreapta)
    ("B_T2_Mosor", "props/cable_reel.glb", 0.1625, 9.6, 15.0),
    ("B_T2_Moloz", "rocks/rubble_pile_b.glb", 0.1595, 12.2, 40.0),
    ("B_T2_Sarma2", SAW, 0.165, 10.3, -150.0, _spin(240.0)),
    ("B_T2_Stiva", "rocks/block_stack_b.glb", 0.1690, 11.4, 0.0),
    ("B_T2_Stiva2", "rocks/block_stack_a.glb", 0.1715, 11.4, 0.0),
    # ---- ac2: berme la varf, pe EXTERIOR (dreapta), panta spre drum = yaw 0
    ("B_Ac2_Berma1", "structures/safety_berm.glb", 0.193, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Berma2", "structures/safety_berm.glb", 0.197, 10.0, 0.0, {"tilt": True}),
    ("B_Ac2_Berma3", "structures/safety_berm.glb", 0.201, 10.0, 0.0, {"tilt": True}),
    # grup de lucru 5 (exteriorul acului 2, dincolo de berme): cabluri + bloc taiat
    ("B_Ac2_Teava", "props/pipe_run.glb", 0.1965, 13.8, 0.0),
    ("B_Ac2_Mosor", "props/cable_reel.glb", 0.2005, 13.5, 40.0),
    ("B_Ac2_Taiat", "rocks/marble_block_c.glb", 0.1975, 16.2, 90.0),
    # grup de lucru 6 (T3 dreapta): masina de fir + mosor + bloc taiat + stive
    ("B_T3_Mosor", "props/cable_reel.glb", 0.2385, 8.4, -30.0),
    ("B_T3_Sarma", SAW, 0.241, 9.9, -150.0, _spin(60.0)),
    ("B_T3_Taiat", "rocks/marble_block_c.glb", 0.2445, 10.8, 90.0),
    ("B_T3_Stiva", "rocks/block_stack_b.glb", 0.2475, 11.0, 0.0),
    ("B_T3_Stiva2", "rocks/block_stack_a.glb", 0.2500, 11.0, 0.0),
]

# Jumatatea de gabarit (in lung, lateral; m, la scara 1) a pieselor fixe, ca sirurile sa le ocoleasca.
_HALF = {"wire_saw": (3.2, 2.5), "drill_rig": (1.9, 3.1), "cable_reel": (1.0, 1.0), "marble_block_c": (1.7, 1.7),
         "safety_berm": (3.1, 0.8), "pipe_run": (3.1, 0.5), "block_stack_a": (1.3, 1.3),
         "block_stack_b": (1.3, 1.3), "rubble_pile_b": (1.6, 1.6)}

# Sirurile: (prefix, frac0, frac1, lateral, glb, scala, pas). Pas si scara CONSTANTE pe segment, yaw 0 +-3.
# Marginea drumului: dincolo de berma din cod (+-6) la 7.8; pe partea camionului la 8.8 (generatorul cere > 6 m
# de banda lui). Buza bancurilor: blocuri ceva mai mari, pas mai lung. Interiorul acelor ramane gol.
_A = "rocks/marble_block_a.glb"
_B = "rocks/marble_block_b.glb"
_SIRURI = [
    ("B_ST1D", 0.0585, 0.0860, 7.8, _A, 0.85, 3.3),    # T1, marginea dreapta (dupa berma)
    ("B_ST1E", 0.0862, 0.0935, 8.8, _A, 0.85, 3.3),    # T1, capatul: camionul trece pe banda dreapta
    ("B_ST1M", 0.0585, 0.0935, 11.0, _B, 0.70, 4.4),   # T1, buza bancului (sus pe F1)
    ("B_ST1S", 0.0610, 0.0935, -8.8, _A, 0.85, 3.3),   # T1, marginea stanga
    ("B_SA1", 0.0945, 0.1180, -7.9, _A, 0.85, 3.6),    # ac1, exteriorul
    ("B_SR1M", 0.1185, 0.1450, -10.0, _B, 0.70, 4.4),  # rampa ac1, muchia din stanga (fara berma)
    ("B_ST2S", 0.1455, 0.1770, -8.4, _A, 0.85, 3.3),   # T2, marginea stanga (dupa berma)
    ("B_ST2M", 0.1455, 0.1770, -10.8, _B, 0.70, 4.4),  # T2, buza bancului
    ("B_ST2D", 0.1455, 0.1770, 8.8, _A, 0.85, 3.3),    # T2, marginea dreapta (platou)
    ("B_SA2", 0.1780, 0.2080, 7.9, _A, 0.85, 3.6),     # ac2, exteriorul
    ("B_SR2M", 0.2085, 0.2320, 10.2, _B, 0.70, 4.4),   # rampa ac2, muchia din dreapta (fara berma)
    ("B_ST3D", 0.2325, 0.2660, 7.8, _A, 0.85, 3.3),    # T3, marginea dreapta (dupa berma)
    ("B_ST3M", 0.2325, 0.2660, 11.1, _B, 0.70, 4.4),   # T3, buza bancului
    ("B_ST3S", 0.2325, 0.2660, -8.8, _A, 0.85, 3.3),   # T3, marginea stanga
]
# Molozul de la piciorul peretelui F1 (in PlasaA, sub 1.5 m, fantoma; decizia 4 din runda 2) si molozul de lucru
# din jurul utilajelor: singurul loc unde ramane variatie (yaw liber, scara variabila).
_MOLOZ = [("rocks/rubble_pile_a.glb", 0.70, 1.00, 3), ("rocks/rubble_pile_b.glb", 0.80, 1.20, 3),
          ("rocks/block_informe_b.glb", 0.50, 0.80, 2)]
_MOLOZ_LINII = [("B_MF1", 0.1470, 0.1760, 20.8, 0.6, 5.5, 8.0)]
_MOLOZ_LUCRU = [  # (nume, frac, lateral, glb, scala, yaw)
    ("B_ML_T1", 0.0665, 10.6, "rocks/rubble_pile_b.glb", 0.6, 25.0),
    ("B_ML_T1S", 0.0822, -16.8, "rocks/rubble_pile_a.glb", 0.6, -30.0),
    ("B_ML_Ac1", 0.1075, -19.0, "rocks/rubble_pile_b.glb", 0.7, 60.0),
    ("B_ML_T3", 0.2525, 10.4, "rocks/rubble_pile_b.glb", 0.6, -20.0),
]
# Piese scoase dupa masuratoare (teren in panta sub amprenta: blocul s-ar fi ingropat pe o latura).
_SKIP = {"B_ST1M15", "B_ST1M16", "B_ST1M17", "B_SA113", "B_SA114", "B_SA26", "B_SA27"}


def _siruri():
    rng = _random.Random(2310)
    fixed = []
    for it in FIX:
        o = it[5] if len(it) > 5 else {}
        st = it[1].split("/")[-1].replace(".glb", "")
        hl, hw = _HALF.get(st, (1.4, 1.4))
        k = o.get("scale", 1.0)
        fixed.append((_s_of(it[2], o.get("along", 0.0)), it[3], hl * k + 0.6, hw * k + 0.6))
    for nm, fr, lat, glb, k, yaw in _MOLOZ_LUCRU:
        fixed.append((_s_of(fr), lat, 1.6 * k + 0.6, 1.6 * k + 0.6))
    out = []
    for pre, f0, f1, lat, glb, k, pas in _SIRURI:
        s, s1, n = _s_of(f0), _s_of(f1), 0
        while s < s1:
            n += 1
            nm = f"{pre}{n}"
            yaw = round(rng.uniform(-3.0, 3.0), 1)
            if nm not in _SKIP and not any(abs(s - fs) < fl and abs(lat - fla) < fw for fs, fla, fl, fw in fixed):
                fr, al = _at(s)
                out.append((nm, glb, fr, lat, yaw, dict(GHOST, scale=k, along=al)))
            s += pas
    for pre, f0, f1, lat0, jit, p0, p1 in _MOLOZ_LINII:
        s, s1, n = _s_of(f0), _s_of(f1), 0
        wsum = sum(c[3] for c in _MOLOZ)
        while s < s1:
            r, acc, c = rng.uniform(0, wsum), 0.0, _MOLOZ[0]
            for c in _MOLOZ:
                acc += c[3]
                if r <= acc:
                    break
            lat = lat0 + rng.uniform(-jit, jit)
            k = round(rng.uniform(c[1], c[2]), 2)
            yaw = round(rng.uniform(-180.0, 180.0), 1)
            n += 1
            fr, al = _at(s)
            out.append((f"{pre}{n}", c[0], fr, round(lat, 2), yaw, dict(GHOST, scale=k, along=al)))
            s += rng.uniform(p0, p1)
    for nm, fr, lat, glb, k, yaw in _MOLOZ_LUCRU:
        out.append((nm, glb, fr, lat, yaw, dict(GHOST, scale=k)))
    return out


ITEMS = FIX + _siruri()

KIT_Y = {
    "B_T1_Sarma": 24.67, "B_T1_Taiat": 24.6, "B_T1_Stiva": 24.43, "B_T1_Foraj": 24.02, "B_T1_Taiat2": 23.52,
    "B_T1_Stiva2": 23.74, "B_T1_Stiva3": 23.37, "B_Ac1_Berma1": 21.72, "B_Ac1_Berma2": 20.97, "B_Ac1_Berma3": 19.99,
    "B_Ac1_Sarma": 20.38, "B_Ac1_Taiat": 21.29, "B_Ac1_Stiva": 21.27, "B_T2_Moloz": 15.67, "B_T2_Sarma2": 15.61,
    "B_T2_Stiva": 15.39, "B_T2_Stiva2": 15.19, "B_Ac2_Berma1": 12.41, "B_Ac2_Berma2": 11.78, "B_Ac2_Berma3": 11.16,
    "B_Ac2_Teava": 11.76, "B_Ac2_Taiat": 11.71, "B_T3_Sarma": 6.67, "B_T3_Taiat": 6.67, "B_T3_Stiva": 6.67,
    "B_T3_Stiva2": 6.67, "B_ST1D1": 24.67, "B_ST1D2": 24.67, "B_ST1D3": 24.67, "B_ST1D4": 24.67,
    "B_ST1D5": 24.67, "B_ST1D6": 24.67, "B_ST1D7": 24.67, "B_ST1D11": 24.65, "B_ST1D12": 24.6,
    "B_ST1D13": 24.56, "B_ST1D14": 24.45, "B_ST1D15": 24.32, "B_ST1D16": 24.13, "B_ST1D17": 23.87,
    "B_ST1D18": 23.62, "B_ST1E1": 23.44, "B_ST1E2": 23.16, "B_ST1E3": 22.92, "B_ST1E4": 22.7,
    "B_ST1E5": 22.54, "B_ST1M1": 24.67, "B_ST1M2": 24.67, "B_ST1M3": 24.67, "B_ST1M4": 24.67,
    "B_ST1M6": 24.67, "B_ST1M10": 24.55, "B_ST1M11": 24.36, "B_ST1M12": 24.1, "B_ST1M13": 23.69,
    "B_ST1M14": 23.31, "B_ST1S1": 24.63, "B_ST1S2": 24.63, "B_ST1S3": 24.62, "B_ST1S4": 24.62,
    "B_ST1S5": 24.62, "B_ST1S6": 24.62, "B_ST1S7": 24.61, "B_ST1S8": 24.61, "B_ST1S9": 24.6,
    "B_ST1S10": 24.55, "B_ST1S11": 24.5, "B_ST1S12": 24.4, "B_ST1S13": 24.31, "B_ST1S14": 24.16,
    "B_ST1S15": 23.96, "B_ST1S16": 23.73, "B_ST1S17": 23.53, "B_ST1S18": 23.33, "B_ST1S19": 23.15,
    "B_ST1S20": 22.94, "B_ST1S21": 22.67, "B_SA11": 22.47, "B_SA12": 22.23, "B_SA13": 21.96,
    "B_SA14": 21.74, "B_SA15": 21.45, "B_SA16": 21.29, "B_SA17": 21.01, "B_SA18": 20.76,
    "B_SA19": 20.4, "B_SA110": 20.08, "B_SA111": 19.76, "B_SA112": 19.52, "B_SR1M1": 18.08,
    "B_SR1M2": 17.93, "B_SR1M3": 17.66, "B_SR1M4": 17.43, "B_SR1M5": 17.37, "B_SR1M6": 17.24,
    "B_SR1M7": 17.17, "B_SR1M8": 16.99, "B_SR1M9": 16.73, "B_SR1M10": 16.47, "B_SR1M11": 16.2,
    "B_SR1M12": 15.97, "B_SR1M13": 15.76, "B_ST2S1": 15.74, "B_ST2S2": 15.71, "B_ST2S3": 15.67,
    "B_ST2S4": 15.67, "B_ST2S5": 15.67, "B_ST2S6": 15.67, "B_ST2S7": 15.67, "B_ST2S8": 15.67,
    "B_ST2S9": 15.67, "B_ST2S10": 15.67, "B_ST2S11": 15.66, "B_ST2S12": 15.66, "B_ST2S13": 15.64,
    "B_ST2S14": 15.62, "B_ST2S15": 15.58, "B_ST2S16": 15.42, "B_ST2S17": 15.26, "B_ST2S18": 15.06,
    "B_ST2S19": 14.84, "B_ST2S20": 14.59, "B_ST2S21": 14.38, "B_ST2M1": 15.74, "B_ST2M2": 15.69,
    "B_ST2M3": 15.67, "B_ST2M4": 15.67, "B_ST2M5": 15.67, "B_ST2M6": 15.67, "B_ST2M7": 15.67,
    "B_ST2M8": 15.67, "B_ST2M9": 15.66, "B_ST2M10": 15.64, "B_ST2M11": 15.61, "B_ST2M12": 15.48,
    "B_ST2M13": 15.26, "B_ST2M14": 14.99, "B_ST2M15": 14.67, "B_ST2M16": 14.37, "B_ST2D1": 15.74,
    "B_ST2D2": 15.71, "B_ST2D3": 15.67, "B_ST2D4": 15.67, "B_ST2D5": 15.67, "B_ST2D6": 15.67,
    "B_ST2D7": 15.67, "B_ST2D8": 15.67, "B_ST2D9": 15.67, "B_ST2D10": 15.67, "B_ST2D11": 15.66,
    "B_ST2D15": 15.58, "B_ST2D16": 15.42, "B_ST2D17": 15.26, "B_ST2D18": 15.06, "B_ST2D19": 14.85,
    "B_ST2D20": 14.66, "B_ST2D21": 14.43, "B_SA21": 14.21, "B_SA22": 13.9, "B_SA23": 13.67,
    "B_SA24": 13.46, "B_SA25": 13.27, "B_SA28": 12.61, "B_SA29": 12.39, "B_SA210": 12.11,
    "B_SA211": 11.87, "B_SA212": 11.6, "B_SA213": 11.37, "B_SA214": 11.07, "B_SA215": 10.86,
    "B_SA216": 10.56, "B_SA217": 10.34, "B_SA218": 10.1, "B_SR2M1": 10.01, "B_SR2M2": 9.69,
    "B_SR2M3": 9.38, "B_SR2M4": 9.13, "B_SR2M5": 8.82, "B_SR2M6": 8.52, "B_SR2M7": 8.22,
    "B_SR2M8": 7.93, "B_SR2M9": 7.64, "B_SR2M10": 7.37, "B_SR2M11": 7.11, "B_ST3D1": 6.88,
    "B_ST3D2": 6.79, "B_ST3D3": 6.75, "B_ST3D4": 6.71, "B_ST3D8": 6.67, "B_ST3D9": 6.67,
    "B_ST3D10": 6.67, "B_ST3D11": 6.67, "B_ST3D12": 6.67, "B_ST3D13": 6.67, "B_ST3D14": 6.67,
    "B_ST3D15": 6.67, "B_ST3D16": 6.67, "B_ST3D17": 6.65, "B_ST3D18": 6.64, "B_ST3D19": 6.59,
    "B_ST3D20": 6.54, "B_ST3D21": 6.46, "B_ST3D22": 6.35, "B_ST3M1": 6.88, "B_ST3M2": 6.77,
    "B_ST3M3": 6.72, "B_ST3M4": 6.69, "B_ST3M6": 6.67, "B_ST3M9": 6.67, "B_ST3M11": 6.67,
    "B_ST3M12": 6.67, "B_ST3M13": 6.65, "B_ST3M14": 6.62, "B_ST3M15": 6.56, "B_ST3M16": 6.47,
    "B_ST3S1": 6.88, "B_ST3S2": 6.79, "B_ST3S3": 6.74, "B_ST3S4": 6.71, "B_ST3S5": 6.69,
    "B_ST3S6": 6.67, "B_ST3S7": 6.67, "B_ST3S8": 6.67, "B_ST3S9": 6.67, "B_ST3S10": 6.67,
    "B_ST3S11": 6.67, "B_ST3S12": 6.67, "B_ST3S13": 6.67, "B_ST3S14": 6.67, "B_ST3S15": 6.67,
    "B_ST3S16": 6.67, "B_ST3S17": 6.65, "B_ST3S18": 6.64, "B_ST3S19": 6.58, "B_ST3S20": 6.53,
    "B_ST3S21": 6.48, "B_ST3S22": 6.44, "B_MF11": 15.7, "B_MF12": 15.67, "B_MF13": 15.67,
    "B_MF14": 15.67, "B_MF15": 15.66, "B_MF16": 15.64, "B_MF17": 15.5, "B_MF18": 15.17,
    "B_MF19": 14.72, "B_ML_T1": -47.57, "B_ML_T1S": 23.82, "B_ML_Ac1": 19.27, "B_ML_T3": -47.57,
    # mosoarele nu apar in --decor (mesh-ul lor intra in coacerea DecorManual): cota din --scan, teren plat
    "B_T1_Mosor": 24.67, "B_T2_Mosor": 15.67, "B_T1_Mosor2": 24.37, "B_Ac2_Mosor": 11.07, "B_T3_Mosor": 6.67,
}
