# Decorul POI-ului H pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.761-1.000.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])  — formatul complet e in zona_a.py.
# KIT_Y: cotele MASURATE (teren minim de sub amprenta - 3 cm), din
#   `godot --headless --path . res://tools/ProbeCarraraMontaj.tscn -- --track=16 --decor --no-batch`.
# FOREST: zone MeshForest (fantome, fara coliziune) — vezi jungla.py; FOREST_GLBS = stem -> glb.

import math
import random

# ---- H: Srah Srang (bazinul regal) si malul de sud al santului -----------------------------------------
# MASURAT cu ProbeCarraraMontaj (grile de lotusi de proba, terenul minim de sub amprenta):
#  * apa = 0,5 (WATER_SRAH = WATER_AW). Bazinul Srah Srang: dreptunghi plat de apa pe fundul de -1,8,
#    mal la x 14..85, z 127..173,5 (Godot, SUD de drum = +z); debarcaderul (x 43-57, z 118,5-126,6) e pe
#    malul de nord. Drumul e la z = 112 (frac 0,796..0,935 pe index, spre V).
#  * santul de sud (DREAPTA drumului): frac 0,78..0,89, apa de la lat ~ +11 pana la ~ +50; fundul -2,3.
#    Malul de la drum: lat 10 -> terenul 0,5..0,9; lat 15 -> -0,9 (deci lotusi de la lat 17).
#    Dupa frac 0,895 santul se termina (nu mai e apa pe dreapta).
#  * pe STANGA drumului (V de x = 20) terenul nu are coliziune sub sonda: cotele de acolo vin din
#    drum (dy), verificate pe captura.
WATER_Y = 0.5
M_PER_FRAC = 2406.0


def _place(name, glb, f, lat, yaw, **opt):
    return (name, glb, f, lat, yaw, dict({"coliziune": "none"}, **opt))


def _wplace(name, glb, x, z, yaw, **opt):
    return (name, glb, 0.0, 0.0, yaw, dict({"coliziune": "none", "world": (float(x), float(z))}, **opt))


ITEMS = []
_rng = random.Random(7610)


def _drift(tag, n_prefix, center, pieces, rad, place_fn):
    """Un petic de lotusi: centru (a, b), `pieces` piese in raza `rad`; place_fn(a, b) -> (a, b) sau None."""
    n = 0
    for j in range(pieces):
        ang = _rng.random() * 2 * math.pi
        r = rad * math.sqrt(_rng.random())
        pos = place_fn(center[0] + r * math.cos(ang), center[1] + r * math.sin(ang))
        if pos is None:
            continue
        flower = _rng.random() < 0.42
        sc = (1.4 + _rng.random() * 1.0) if flower else (1.8 + _rng.random() * 1.6)
        yield (f"{n_prefix}{n}", "plants/lotus_cluster.glb" if flower else "plants/water_lily_pads.glb",
               pos, _rng.random() * 360.0, round(sc, 2))
        n += 1


# 1) Lotusi in Srah Srang: petice (drifts) pe apa bazinului; intre petice, apa libera ca sa se vada oglinda.
#    Nimic la z < 131 (treptele debarcaderului coboara in apa pe x 43..57).
_basin_centers = [(28, 140), (36, 160), (50, 148), (62, 138), (68, 158), (47, 166), (74, 148), (24, 152)]
_k = 0
for ci, c in enumerate(_basin_centers):
    for nm, glb, pos, yaw, sc in _drift("H_BasinLot", f"H_Basin{ci}_", c, _rng.randint(7, 11), 4.5 + _rng.random() * 2.0,
                                       lambda a, b: (a, b) if 21 <= a <= 78 and 132 <= b <= 169 else None):
        ITEMS.append(_wplace(nm, glb, pos[0], pos[1], yaw, scale=sc, y=WATER_Y))

# 2) Pervaz de gresie pe linia malului bazinului: bazin ZIDIT, nu lac. Placi `kit/gallery_relief_wall` (4 m)
#    turtite pe verticala (`sy`) si puse cap la cap — cordon continuu de piatra, nu caramizi de laterita
#    cu goluri (criticii A si H: „caramizi rosii”). Scufundate pe jumatate, fara corp. Debarcaderul
#    (x 41..59) taie malul de nord.
_BX0, _BX1, _BZ0, _BZ1 = 14.0, 84.5, 127.0, 173.0
_KL = 4.0
_KSY = 0.15
# Fluxul aleatoriu al vechiului pervaz (pas 2,2 m, ~8% goluri, jitter de yaw) se consuma EXACT ca inainte:
# piesele de dupa (lotusi, palmieri, cotele lor masurate) sunt trase din acelasi `_rng` si nu trebuie sa se mute.
_KS = 2.2
for edge in ("N", "W", "E"):
    if edge in ("N", "S"):
        _n_old = int((_BX1 - _BX0) / _KS)
        _pts_old = [(_BX0 + 1 + i * _KS, _BZ0 if edge == "N" else _BZ1) for i in range(_n_old)]
    else:
        _pts_old = [(_BX0 if edge == "W" else _BX1, _BZ0 + 1 + i * _KS) for i in range(int((_BZ1 - _BZ0) / _KS))]
    for (x, z) in _pts_old:
        if edge == "N" and 40.0 <= x <= 60.0:
            continue
        if edge == "S" and x > 76.0:
            continue
        if _rng.random() < 0.08:
            continue
        _rng.random()
_kn = 0
for edge in ("N", "W", "E"):
    if edge == "N":
        spans = [(_BX0, 40.0), (60.0, _BX1)]       # fara debarcader (x 40..60)
    elif edge == "S":
        spans = [(_BX0, 76.0)]
    else:
        spans = [(_BZ0, _BZ1)]
    for (c0, c1) in spans:
        c = c0 + _KL / 2
        while c + _KL / 2 <= c1 + 0.5:
            if edge in ("N", "S"):
                x, z, yaw = c, (_BZ0 if edge == "N" else _BZ1), 0.0
            else:
                x, z, yaw = (_BX0 if edge == "W" else _BX1), c, 90.0
            ITEMS.append(_wplace(f"H_BKerb{_kn}", "kit/gallery_relief_wall.glb", x, z, yaw,
                                 y=WATER_Y + 0.02, sy=_KSY, scufundat=True))
            _kn += 1
            c += _KL

# 3) Lotusi pe santul de sud (dreapta drumului): petice pe frac 0,785..0,888, lat +17..+46.
for k in range(14):
    fc = 0.786 + (0.888 - 0.786) * (k + _rng.random() * 0.8) / 14.0
    dist = 17.0 + (_rng.random() ** 1.4) * 26.0
    rad = 3.0 + _rng.random() * 3.0
    n = 0
    for j in range(_rng.randint(5, 9)):
        ang = _rng.random() * 2 * math.pi
        r = rad * math.sqrt(_rng.random())
        f = fc + r * math.cos(ang) / M_PER_FRAC
        lat = min(47.0, max(17.0, dist + r * math.sin(ang)))
        if not (0.783 <= f <= 0.889):
            continue
        flower = _rng.random() < 0.42
        sc = (1.4 + _rng.random() * 1.0) if flower else (1.8 + _rng.random() * 1.6)
        ITEMS.append(_place(f"H_MoatLot{k}_{n}", "plants/lotus_cluster.glb" if flower else "plants/water_lily_pads.glb",
                            f, lat, _rng.random() * 360.0, scale=round(sc, 2), y=WATER_Y))
        n += 1

# 4) Palmieri de zahar pe STANGA drumului (in afara virajului de la colt: lat <= -14, nimic pe dreapta/interior),
#    printre cei 6 din generator (PalmierH0..5, lat ~ -14). Trunchi cu coliziune la >= 14 m de axa.
for k, f in enumerate((0.822, 0.838, 0.853, 0.869, 0.884, 0.899, 0.914, 0.927)):
    ITEMS.append(_place(f"H_Palm{k}", "plants/sugar_palm.glb", f + (_rng.random() - 0.5) * 0.004,
                        -(16.0 + _rng.random() * 12.0), _rng.random() * 360.0,
                        scale=round(1.0 + _rng.random() * 0.25, 2), dy=-0.1, coliziune="trunk"))

# 5) Palmieri pe malurile bazinului (V, E si S), cota din ProbeCarraraMontaj.
_basin_palms = [(8, 138), (9, 150), (10, 162), (10, 172), (90, 142), (91, 156)]
for k, (x, z) in enumerate(_basin_palms):
    ITEMS.append(_wplace(f"H_BPalm{k}", "plants/sugar_palm.glb", x, z, _rng.random() * 360.0,
                         scale=round(1.0 + _rng.random() * 0.25, 2), coliziune="trunk"))

# 6) Tuk-tuk-uri pe debarcader, intre cei doi lei (originea platformei y = 2,0; x 43..57, z 118,5..126,6).
for k, x in enumerate((46.2, 50.0, 53.8)):
    ITEMS.append(_wplace(f"H_TukL{k}", "vehicles/tuk_tuk.glb", x, 122.0, 90.0, y=2.0, coliziune="none", child={"Moto": (0, 0, -1.95)}))

KIT_Y = {
    "H_BPalm0": 1.06,
    "H_BPalm1": 0.92,
    "H_BPalm2": 0.64,
    "H_BPalm3": 0.97,
    "H_BPalm4": 1.02,
    "H_BPalm5": 1.68,
}
