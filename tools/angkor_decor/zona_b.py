# Decorul POI-ului B pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
#
# B = PRIN TEMPLU (19 nov 2026). Pana atunci soseaua cotea spre nord pe gazon, la 55 m de turnuri, si tot
# decorul zonei (calea procesionala, terasele, molozul de pe gazon, lotusii santului de nord) era asezat pe
# acel drum; a fost rescris de la zero. Templul insusi (navele, sala, sanctuarul) e `angkor_wat_drive.glb`,
# pus de generator; aici ramane doar ce sta IN JURUL lui.
#
# FRAC_BASE = 2: fractiile de mai jos sunt pe traseul NOU (207 puncte de control, 12 m fiecare:
# frac = s / 12 / 207, cu s = metri pe axa de la start). Generatorul nu le mai traduce.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni]) — formatul din celelalte fisiere de zona:
#   "world" (x, z) Godot absolut (z = -y de pe harta), yaw absolut (0 = -Z al piesei spre nord)
#   "y" cota absoluta, "scale", "coliziune" ("hull" / "mesh" / "trunk" / "none"), "scufundat"
# SMOKE: (frac, lateral, dy) surse de fum de tamaie (un singur emitator pe pista).
import math
import random

FRAC_BASE = 2

N_CTRL = 207
CTRL_STEP = 12.0
WATER_Y = 0.5
G_LAWN = 3.62            # gazonul incintei (teren minim ~3,65), masurat la gauntlet
TEMPLE_HALF = 52.0       # fatadele masivului
MOAT_IN, MOAT_OUT = 66.0, 104.0


def fr(s):
    """Fractia pe INDEX la s metri pe axa de la start (calea de vest: x = -240 + s)."""
    return s / CTRL_STEP / N_CTRL


def _w(name, glb, x, y, yaw, gy=G_LAWN, **opt):
    """Piesa pe harta (x est, y nord), yaw absolut, fara coliziune implicit."""
    return (name, glb, 0.0, 0.0, yaw, dict({"coliziune": "none", "world": (x, -y), "y": gy}, **opt))


ITEMS = []
SMOKE = []
_rng = random.Random(1911)

# 1) Curtea de vest (intre gopura de la x -97,5 si fatada de la x -52). Soseaua se largeste aici de la 9 la
#    13 m si e marginita de aripile portalului (din model, pe corpul tubului) de la x -66. Tot ce e aici sta
#    la >= 12 m de axa: plutonul din turul 1 trece pe aici gramada.
#    Altare cu tamaie de o parte si de alta a portalului (tiparul Bayonului, zona_e): bloc de gresie +
#    lespede de laterita, fumul la 1,1 m peste drum.
for k, side in enumerate((-1.0, 1.0)):
    ax, ay = -57.0, side * 12.5
    ITEMS.append(_w(f"B_Altar{k}", "props/fallen_block.glb", ax, ay, 90.0, gy=G_LAWN + 0.02, scale=0.4))
    ITEMS.append(_w(f"B_AltarJar{k}", "props/laterite_block.glb", ax, ay, 90.0, gy=G_LAWN + 0.95, scale=0.6))
    # lateral + = dreapta sensului; pe calea de vest (spre est) dreapta e sudul
    SMOKE.append((fr(240.0 + ax), -ay, 1.3))

#    Calugari in sofran pe treptele curtii, departe de banda, privind spre drum.
for k, (x, y, yw) in enumerate(((-58.5, 15.5, 200.0), (-60.0, 17.0, 170.0), (-59.0, -16.0, 20.0),
                                (-74.0, 24.0, 180.0), (-76.0, -26.0, 0.0))):
    ITEMS.append(_w(f"B_Calugar{k}", "animals/monk_standing.glb", x, y, yw, scale=1.25))

#    Blocuri de restaurare pe gazon (jos, fara corp), la marginea curtii.
_court = [(-88.0, 30.0), (-80.0, 36.0), (-70.0, 40.0), (-86.0, -32.0), (-76.0, -38.0), (-66.0, -34.0),
          (-92.0, 44.0), (-94.0, -46.0)]
for k, (x, y) in enumerate(_court):
    glb = ("props/numbered_block.glb", "props/rubble_pile.glb", "props/laterite_block.glb")[k % 3]
    ITEMS.append(_w(f"B_Curte{k}", glb, x, y, _rng.random() * 360.0, scale=round(1.0 + _rng.random() * 0.5, 2),
                    scufundat=True))
ITEMS.append(_w("B_Restaurare0", "props/restoration_prop.glb", -56.5, 30.0, 90.0, coliziune="hull"))

# 2) Santul de nord, pe ambele parti ale caii de nord (x = 0): lotusi si nuferi in derive, ca la A. Apa
#    (la 0,5) NU incepe la piciorul caii: rapa are umeri lati, iar malul e la 16-25 m de axa. Linia malului
#    de mai jos e cea masurata la gauntlet pe calea veche (x = -56), mutata pe y: santul e generat la fel
#    fata de drum (rapa 1, aceleasi latimi), deci profilul e acelasi.
BANK = [(76.0, 24.0), (79.7, 17.5), (83.3, 16.0), (86.9, 16.0), (90.6, 18.0), (94.2, 25.0), (96.6, 40.0)]
Y0, Y1 = 77.0, 95.5


def _bank(y):
    y = min(max(y, BANK[0][0]), BANK[-1][0])
    for (ya, la), (yb, lb) in zip(BANK, BANK[1:]):
        if ya <= y <= yb:
            return la + (lb - la) * (y - ya) / (yb - ya)
    return BANK[-1][1]


for side, tag in ((-1.0, "V"), (1.0, "E")):
    n = 0
    for k in range(10):
        yc = Y0 + (Y1 - Y0) * (k + _rng.random() * 0.8) / 10.0
        dist = 2.5 + (_rng.random() ** 1.5) * 14.0
        for j in range(_rng.randint(6, 10)):
            a = _rng.random() * 2 * math.pi
            r = (2.5 + _rng.random() * 2.5) * math.sqrt(_rng.random())
            y = yc + r * math.cos(a)
            if not (Y0 - 1.2 <= y <= Y1 + 1.2):
                continue
            x = side * (_bank(y) + max(2.0, dist + r * math.sin(a)))
            flower = _rng.random() < 0.42
            sc = (1.4 + _rng.random()) if flower else (1.8 + _rng.random() * 1.6)
            ITEMS.append(_w(f"B_Lot{tag}{n}", "plants/lotus_cluster.glb" if flower else "plants/water_lily_pads.glb",
                            x, y, _rng.random() * 360.0, gy=WATER_Y, scale=round(sc, 2)))
            n += 1

# 3) Curtea de vest e GAZON, nu jungla: luminisul templului (disc r 78 in origine, jungla.py) se opreste la
#    x -78, iar intre el si gopura (x -97,5) subarboretul si trunchiurile cresteau pana in balustrada. Doua
#    discuri pe axa lasa curtea libera pana la ~30 m de drum; mai departe jungla ramane rama portii.
#    (center = (x, z) Godot, z = -y.)
FOREST = [
    dict(label='curtea de vest N', kind='disc', center=(-90.0, -15.0), radius=21.0, claim=True),
    dict(label='curtea de vest S', kind='disc', center=(-90.0, 15.0), radius=21.0, claim=True),
]

KIT_Y = {}
