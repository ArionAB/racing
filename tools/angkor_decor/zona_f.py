# Decorul POI-ului F pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.498-0.649.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("F_...")
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

import math
import random

# ---- POI F: piata regala + Terasa Elefantilor. Harta: coama la x 112, y 350->200 (Godot z -350 -> -200,
# drumul merge spre +Z); DREAPTA = vest (piata, cadere de 4 m), STANGA = est (curtea palatului).
# Piesele din generator (Terasa*, StalpTrompa*, TerasaCapat, RegeleLepros) nu se ating.
# Totul e pus cu "world": (x, z) Godot; yaw absolut (0 = -Z spre nord, 90 = spre vest, -90 = spre est).
# Reguli: nimic solid in piata sub coama (masinile cazute aterizeaza acolo); nimic cu corp la < 18 m de axa pe
# interiorul diagonalei piata->terasa (AI-ul taie pana la ~14 m); nimic pe zbor/aterizare (z > -215).
rnd = random.Random(498)
ITEMS = []
KIT_Y = {}
OFFS = {}        # nume -> decalaj fata de cota masurata (m)
LOW = {"coliziune": "none"}


def W(nm, glb, x, z, yaw, off=0.0, **opt):
    nm = "F_" + nm
    if off < 0:
        opt["scufundat"] = True
    if off:
        OFFS[nm] = off
    opt["world"] = (round(x, 2), round(z, 2))
    ITEMS.append((nm, glb, 0.55, 0.0, round(yaw, 1), opt))


TIER = "kit/bakheng_terrace_tier.glb"
TOWER = "kit/bakheng_shrine_tower.glb"
WALL = "kit/gallery_relief_wall.glb"
CORNER = "kit/gallery_corner.glb"
COL = "kit/gallery_column.glb"
ROOF = "kit/gallery_roof.glb"
VAULTB = "kit/vault_broken.glb"
RUB = "props/rubble_pile.glb"
BLK = "props/fallen_block.glb"
NUM = "props/numbered_block.glb"
MONK = "animals/monk_standing.glb"
TUK = "vehicles/tuk_tuk.glb"


def seg_dist(px, pz, ax, az, bx, bz):
    dx, dz = bx - ax, bz - az
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz)))
    return math.hypot(px - ax - t * dx, pz - az - t * dz)


def road_dist(x, z):
    """Distanta la axa drumului in F (diagonala + coama + capatul de E-rampa)."""
    return min(seg_dist(x, z, 22, -437, 52, -437), seg_dist(x, z, 52, -437, 112, -377),
               seg_dist(x, z, 112, -377, 112, -128))


# 1) Phimeanakas: templu in trepte pe stanga coamei, la ~55 m de axa. 3 etaje, turn central + 4 turnuri de
#    colt. Axa lunga a etajelor merge pe Z (paralela cu drumul). Cotele de la baza vin din masuratoare.
PH = (168.0, -285.0)
PH_Y = 17.24   # @@PHY cota terenului sub etajul 0
cum = 0.0
for k, sc in enumerate((4.0, 3.0, 2.2)):
    ITEMS.append(("F_Phim%d" % k, TIER, 0.55, 0.0, 90.0,
                  {"world": PH, "scale": sc, "y": round(PH_Y + cum, 2), "scufundat": k == 0}))
    cum += 1.528 * sc - 0.06
ITEMS.append(("F_PhimTurn", TOWER, 0.55, 0.0, 90.0, {"world": PH, "scale": 2.0, "y": round(PH_Y + cum, 2)}))
cum2 = 1.528 * 4.0 + 1.528 * 3.0 - 0.12
for k, (dx, dz) in enumerate([(-5.0, -9.0), (-5.0, 9.0), (5.0, -9.0), (5.0, 9.0)]):
    ITEMS.append(("F_PhimCol%d" % k, TOWER, 0.55, 0.0, 90.0,
                  {"world": (PH[0] + dx, PH[1] + dz), "scale": 0.9, "y": round(PH_Y + cum2, 2)}))

# 2) Zidul curtii palatului: placi de relief la 34 m de axa (x 146), relieful spre drum, cu goluri largi.
k = 0
z = -343.0
while z < -222:
    if not (-300 < z < -276 or -252 < z < -238):
        W("CurteZid%d" % k, WALL, 146.0 + rnd.uniform(-0.4, 0.4), z, 90 + rnd.uniform(-4, 4),
          rnd.choice((0.0, 0.0, -0.6, -1.2, -2.0)))
    z += 4.0
    k += 1

# Galerie prabusita in curtea palatului (la 44-52 m de axa) si fragmente izolate.
W("CurteCol0", COL, 158.0, -332.0, 0)
W("CurteCol1", COL, 158.0, -328.0, 0, -1.4)
W("CurteCol2", COL, 158.0, -324.0, 0)
W("CurteCol3", COL, 158.0, -320.0, 0, -2.0)
W("CurteRoof0", ROOF, 158.0, -330.0, 90, 3.4)
W("CurteRoof1", ROOF, 158.0, -322.0, 90, 3.0)
W("CurteCorner", CORNER, 158.0, -312.0, 90, -0.8)
W("CurteVault", VAULTB, 150.0, -262.0, 0, -0.4)
W("CurteFrag0", CORNER, 150.0, -347.0, 20, -1.6)
W("CurteFrag1", WALL, 190.0, -232.0, 90, -1.0)
W("CurteFrag2", WALL, 205.0, -240.0, 0, -1.4)
for k, (x, z, g, sc) in enumerate([(152, -300, RUB, 1.0), (151, -284, BLK, 0.7), (153, -270, RUB, 1.2),
                                   (160, -342, RUB, 1.0), (178, -325, BLK, 0.6), (186, -250, RUB, 1.0),
                                   (176, -258, BLK, 0.5), (143, -318, RUB, 1.0), (196, -300, RUB, 1.3)]):
    W("CurteMol%d" % k, g, x, z, rnd.uniform(0, 360), 0.0, scale=sc, coliziune="none")
for k, (x, z, yw) in enumerate([(150, -292, 90), (150.0, -290.6, 70), (156, -255, -90), (190, -340, 0)]):
    W("CurteCalugar%d" % k, MONK, x, z, yw, 0.0, coliziune="none")

# 3) Piata: blocuri joase, moloz, calugari, tuk-tuk. Tot ce e aproape de drum sau sub coama e `none`.
k = 0
tries = 0
while k < 34 and tries < 400:
    tries += 1
    x = rnd.uniform(46, 100)
    z = rnd.uniform(-424, -228)
    if road_dist(x, z) < 11.0 or math.hypot(x - 100, z + 210) < 8.0 or z > -224:
        continue
    g = rnd.choice((RUB, RUB, BLK, BLK, NUM))
    sc = rnd.uniform(0.35, 0.6) if g == BLK else rnd.uniform(0.8, 1.2)
    W("PiataBloc%d" % k, g, x, z, rnd.uniform(0, 360), -0.12 if g == BLK else 0.0, scale=sc, coliziune="none")
    k += 1
for k, (x, z) in enumerate([(84, -302), (68, -262), (60, -386), (88, -350), (76, -414)]):
    for j in range(2 + k % 2):
        W("Calugar%d_%d" % (k, j), MONK, x + 1.3 * j, z + 0.8 * j * (-1) ** j, rnd.uniform(0, 360), 0.0, coliziune="none")
W("TukTuk0", TUK, 62.0, -392.0, 25)
W("TukTuk1", TUK, 56.0, -270.0, -70)

# 4) Fragmente de incinta la marginea de vest a pietei (x ~ 36-44, la 70+ m de drum): placi, colturi,
#    stalpi, goluri.
k = 0
z = -378.0
while z < -236:
    if not (-340 < z < -320 or -290 < z < -280):
        W("IncintaZid%d" % k, WALL, 40.0 + rnd.uniform(-1, 1), z, -90 + rnd.uniform(-5, 5),
          rnd.choice((0.0, -0.5, -1.2, -0.5, -1.2)))
    z += 4.0
    k += 1
W("IncintaCol0", COL, 44.0, -338.0, 0)
W("IncintaCol1", COL, 44.0, -322.0, 0, -1.6)
W("IncintaCorner0", CORNER, 40.0, -384.0, -90, -0.8)
W("IncintaCorner1", CORNER, 40.0, -230.0, -90, -1.4)
W("IncintaVault", VAULTB, 38.0, -285.0, -90, -0.4)

# @@KITY (teren minim - 0,03, din ProbeCarraraMontaj; Phim* au cota explicita)
BASE = {'F_Phim0': 17.24, 'F_Phim1': 17.31, 'F_Phim2': 17.37, 'F_PhimTurn': 17.44, 'F_PhimCol0': 17.59, 'F_PhimCol1': 17.58, 'F_PhimCol2': 17.27, 'F_PhimCol3': 17.26, 'F_CurteZid0': 17.64, 'F_CurteZid1': 17.65, 'F_CurteZid2': 17.65, 'F_CurteZid3': 17.66, 'F_CurteZid4': 17.66, 'F_CurteZid5': 17.66, 'F_CurteZid6': 17.67, 'F_CurteZid7': 17.67, 'F_CurteZid8': 17.67, 'F_CurteZid9': 17.67, 'F_CurteZid10': 17.67, 'F_CurteZid17': 17.67, 'F_CurteZid18': 17.66, 'F_CurteZid19': 17.66, 'F_CurteZid20': 17.65, 'F_CurteZid21': 17.65, 'F_CurteZid22': 17.63, 'F_CurteZid27': 17.46, 'F_CurteZid28': 17.37, 'F_CurteZid29': 17.27, 'F_CurteZid30': 17.13, 'F_CurteCol0': 17.64, 'F_CurteCol1': 17.64, 'F_CurteCol2': 17.65, 'F_CurteCol3': 17.65, 'F_CurteRoof0': 17.64, 'F_CurteRoof1': 17.64, 'F_CurteCorner': 17.65, 'F_CurteVault': 17.64, 'F_CurteFrag0': 17.63, 'F_CurteFrag1': 15.85, 'F_CurteFrag2': 14.29, 'F_CurteMol0': 17.67, 'F_CurteMol1': 17.67, 'F_CurteMol2': 17.66, 'F_CurteMol3': 17.62, 'F_CurteMol4': 17.02, 'F_CurteMol5': 16.4, 'F_CurteMol6': 17.12, 'F_CurteMol7': 17.67, 'F_CurteMol8': 15.48, 'F_CurteCalugar0': 17.67, 'F_CurteCalugar1': 17.67, 'F_CurteCalugar2': 17.62, 'F_CurteCalugar3': 16.16, 'F_PiataBloc0': 14.7, 'F_PiataBloc1': 15.6, 'F_PiataBloc2': 13.97, 'F_PiataBloc3': 15.23, 'F_PiataBloc4': 15.04, 'F_PiataBloc5': 13.97, 'F_PiataBloc6': 13.97, 'F_PiataBloc7': 13.97, 'F_PiataBloc8': 14.37, 'F_PiataBloc9': 14.97, 'F_PiataBloc10': 14.61, 'F_PiataBloc11': 13.97, 'F_PiataBloc12': 13.97, 'F_PiataBloc13': 13.97, 'F_PiataBloc14': 15.32, 'F_PiataBloc15': 13.97, 'F_PiataBloc16': 15.58, 'F_PiataBloc17': 13.97, 'F_PiataBloc18': 13.98, 'F_PiataBloc19': 13.97, 'F_PiataBloc20': 13.97, 'F_PiataBloc21': 14.04, 'F_PiataBloc22': 13.97, 'F_PiataBloc23': 13.99, 'F_PiataBloc24': 14.78, 'F_PiataBloc25': 13.97, 'F_PiataBloc26': 13.97, 'F_PiataBloc27': 15.21, 'F_PiataBloc28': 14.33, 'F_PiataBloc29': 15.03, 'F_PiataBloc30': 13.97, 'F_PiataBloc31': 13.97, 'F_PiataBloc32': 14.91, 'F_PiataBloc33': 13.97, 'F_Calugar0_0': 13.97, 'F_Calugar0_1': 13.97, 'F_Calugar1_0': 13.97, 'F_Calugar1_1': 13.97, 'F_Calugar1_2': 13.97, 'F_Calugar2_0': 15.63, 'F_Calugar2_1': 15.65, 'F_Calugar3_0': 13.97, 'F_Calugar3_1': 13.97, 'F_Calugar3_2': 13.97, 'F_Calugar4_0': 15.51, 'F_Calugar4_1': 15.53, 'F_TukTuk0': 15.42, 'F_TukTuk1': 14.16, 'F_IncintaZid0': 15.18, 'F_IncintaZid1': 15.22, 'F_IncintaZid2': 15.28, 'F_IncintaZid3': 15.31, 'F_IncintaZid4': 15.34, 'F_IncintaZid5': 15.41, 'F_IncintaZid6': 15.47, 'F_IncintaZid7': 15.52, 'F_IncintaZid8': 15.58, 'F_IncintaZid9': 15.68, 'F_IncintaZid15': 16.17, 'F_IncintaZid16': 16.18, 'F_IncintaZid17': 16.19, 'F_IncintaZid18': 16.23, 'F_IncintaZid19': 16.2, 'F_IncintaZid20': 16.22, 'F_IncintaZid21': 16.24, 'F_IncintaZid22': 16.21, 'F_IncintaZid25': 16.24, 'F_IncintaZid26': 16.22, 'F_IncintaZid27': 16.23, 'F_IncintaZid28': 16.23, 'F_IncintaZid29': 16.21, 'F_IncintaZid30': 16.2, 'F_IncintaZid31': 16.17, 'F_IncintaZid32': 16.16, 'F_IncintaZid33': 16.1, 'F_IncintaZid34': 16.07, 'F_IncintaZid35': 15.99, 'F_IncintaCol0': 15.73, 'F_IncintaCol1': 15.95, 'F_IncintaCorner0': 14.97, 'F_IncintaCorner1': 15.81, 'F_IncintaVault': 16.24}
for _n, _y in BASE.items():
    KIT_Y[_n] = round(_y + OFFS.get(_n, 0.0), 2)

# Luminis: curtea palatului (platoul de est al coamei) ramane fara copaci inalti, ca Phimeanakas sa se vada
# de pe coama; doar subarboret mic in jurul lui. Piata are deja luminisurile din jungla.py.
FOREST = [
    dict(label='curtea Phimeanakas', kind='disc', center=(172.0, -285.0), radius=62.0, claim=True),
    dict(label='curtea Phimeanakas subarboret', kind='disc', center=(172.0, -285.0), radius=62.0,
         species=('fern_cluster', 'tropical_shrub'), weights=(0.6, 0.4), spacing=7.0, edge_clear_m=22.0,
         shadow_m=0.0, scale_min=0.9, scale_max=1.4, seed=498),
]
