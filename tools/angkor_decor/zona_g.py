# Decorul POI-ului G pe Track24 (Angkor), citit de tools/gen_angkor_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/angkor_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track24.tscn
# se regenereaza (`python tools/gen_angkor_route.py scenes/tracks/Track24.tscn`), nu se editeaza de mana.
# Fractiile zonei (pe INDEX): 0.649-0.761.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("G_...")
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

# ---- POI G: Ta Prohm. Buclea principala ocoleste incinta pe dreapta (interiorul arcului e la DREAPTA
# sensului): zidul de incinta de laterita/gresie, fragmente de galerie, usi, ficusi si moloz stau la
# 11-40 m lateral, vizibile din drum. Scurtatura (x ~ 126, coridorul cu bolti) NU se atinge: tot ce e
# aici sta la >= 14 m de ea (arcul e la est de coarda). 1 m de drum = 1/2412 din frac.
S0 = 0.649
M = 1.0 / 2412.0
rnd = random.Random(649)

ITEMS = []
OFFS = {}        # nume -> decalaj fata de cota masurata (m): negativ = infipt in sol


def fr(s):
    return round(S0 + s * M, 5)


def add(nm, glb, s, lat, yaw, off=0.0, **opt):
    """Piesa la (s m de la inceputul zonei, lateral). off != 0 -> cota masurata + off (scufundat daca < 0)."""
    nm = "G_" + nm
    if off < 0:
        opt["scufundat"] = True
    if off:
        OFFS[nm] = off
    ITEMS.append((nm, glb, fr(s), round(lat, 2), round(yaw, 1), opt))


def grp(nm, s, lat, th, parts):
    """Compozitie: parts = [(glb, a, b, yaw_local, off, opt)] cu a inainte, b la dreapta, in cadrul rotit cu th."""
    c, sn = math.cos(math.radians(th)), math.sin(math.radians(th))
    for k, (glb, a, b, yw, off, opt) in enumerate(parts):
        add(f"{nm}{k}", glb, s + a * c + b * sn, lat + (-a * sn + b * c), th + yw, off, **opt)


WALL = "kit/gallery_relief_wall.glb"
CORNER = "kit/gallery_corner.glb"
COL = "kit/gallery_column.glb"
ROOF = "kit/gallery_roof.glb"
VAULT = "kit/vault_intact.glb"
VAULTB = "kit/vault_broken.glb"
RUB = "props/rubble_pile.glb"
BLK = "props/fallen_block.glb"
LAT = "props/laterite_block.glb"
NUM = "props/numbered_block.glb"
REST = "props/restoration_prop.glb"
FIG = "plants/strangler_fig.glb"
VINE = "plants/vine_strands.glb"
LOW = {"coliziune": "none"}

# 1) Zidul de incinta: placi de relief la 11,5 m, relieful spre drum. Goluri: in dreptul perdelei de liane
#    (s 50-68, ramane "zid verde"), o prabusire (s 104-116) si o usa (s 148-158). Placile se scufunda
#    diferit: zid in ruina, nu paravan.
# Latimea de la axa: ProbeRace (g_r1) a aratat ca AI-ul taie interiorul virajului strans pana la ~14 m de ax
# (127 repuneri la frac 0,658 dupa blocaje la 0,679, in zid la 11,5 m). Zidul sta dincolo de linia lui.
WALL_LAT = 18.0
GAPS = [(104, 114), (148, 158), (240, 248)]
s = 54.0
k = 0
while s < 264:
    if 178 <= s < 214:
        s += 4.0
        k += 1
        continue   # tronsonul de unde coridorul scurtaturii se reintoarce pe sosea: nimic cu corp
    if not any(a <= s <= b for a, b in GAPS):
        sink = rnd.choice((0.0, 0.0, -0.5, -1.0, -1.6, -2.2))
        add(f"Zid{k}", WALL, s, WALL_LAT + rnd.uniform(-0.3, 0.6), 90 + rnd.uniform(-5, 5), sink)
    s += 4.0
    k += 1


# 2) Usa de incinta (s 148-158): doi stalpi, buiandrug cazut, bolta sparta in spate.
grp("Usa", 153, WALL_LAT + 2.0, 0, [
    (COL, -2.6, 0, 0, 0, {}), (COL, 2.6, 0, 0, -1.2, {}),
    (ROOF, 2.0, 0.5, 0, -1.8, {}),
    (VAULTB, 0.0, 9.0, 90, 0, {}),
    (RUB, -4.0, 1.5, 30, 0, LOW), (RUB, 4.5, 2.0, -50, 0, LOW),
])

# 3) Fragmente de galerie, la 17-40 m de drum, la adancimi diferite. a = inainte, b = la dreapta.
G1 = lambda: [
    (CORNER, 0, 0, 90, 0, {}),
    (WALL, 4.0, 0.0, 90, -0.6, {}), (WALL, 8.0, 0.0, 90, -1.5, {}),
    (COL, 1.0, -3.0, 0, 0, {}), (COL, 4.0, -3.0, 0, 0, {}), (COL, 7.0, -3.0, 0, -1.8, {}),
    (ROOF, 2.5, -3.0, 0, 3.5, {}),
    (RUB, 11.0, -1.0, 20, 0, LOW), (BLK, 10.0, -4.0, 0, -0.3, {}),
]
grp("Gal0", 70, 24.0, 0, G1())
grp("Gal1", 94, 30.0, -8, G1())
grp("Gal2", 124, 28.0, 8, G1())
grp("Gal3", 150, 26.0, -6, G1())
grp("Gal4", 228, 24.0, 5, G1())

# Fragmente izolate: colturi pe jumatate ingropate, bolta sparta, placi cazute.
for k, (ss, ll, yw, glb, off) in enumerate([
        (66, 36.0, 20, CORNER, -1.4), (84, 40.0, -25, VAULTB, -0.6), (108, 38.0, 70, CORNER, -2.0),
        (118, 44.0, 0, VAULTB, 0), (140, 38.0, 35, CORNER, -1.0), (164, 34.0, -50, WALL, -1.0),
        (172, 34.0, 15, CORNER, -1.8), (76, 48.0, 0, VAULT, 0),
        (220, 36.0, 40, CORNER, -1.4)]):
    add(f"Frag{k}", glb, ss, ll, yw, off)

# 4) Ficusi sugrumatori: peste zid, in spatele lui, trei mari.
for k, (ss, ll, yw, sc) in enumerate([(74, 27.0, 90, 1.5), (100, 32.0, 90, 2.0), (134, 29.0, 90, 1.6), (166, 28.0, 90, 1.5), (222, 28.0, 90, 1.7)]):
    add(f"Ficus{k}", FIG, ss, ll, yw, 0, scale=sc)

# 5) Moloz si blocuri la poalele zidului si pe iarba (jos: fara coliziune).
for k in range(40):
    ss = 62 + k * 4.9 + rnd.uniform(-2, 2)
    ll = rnd.choice((9.5, 10.5, 13.5, 15.5, 20.0, 26.0))
    glb = rnd.choice((RUB, RUB, BLK, LAT, LAT, NUM))
    if 176 <= ss < 214:
        continue
    low = glb in (RUB, LAT, NUM)
    if not low:
        ll = max(ll, WALL_LAT + 1.0)
    add(f"Moloz{k}", glb, ss, ll, rnd.uniform(0, 360), -0.1 if glb == BLK else 0.0,
        **(LOW if low else {}))
add("Rest0", REST, 112, WALL_LAT + 4.0, 80, 0)
add("Rest1", REST, 160, WALL_LAT + 4.0, 100, 0)

# 6) Liane peste zid.
for k, ss in enumerate((58, 70, 90, 120, 138, 170, 218, 232, 258)):
    add(f"Liane{k}", VINE, ss, WALL_LAT + 0.4, 90, 2.9, **LOW)

KIT_Y = {}

# @@KITY
BASE = {'G_Zid0': 8.29, 'G_Zid1': 8.1, 'G_Zid2': 7.9, 'G_Zid3': 7.86, 'G_Zid4': 7.83, 'G_Zid5': 7.8, 'G_Zid6': 7.76, 'G_Zid7': 7.76, 'G_Zid8': 7.71, 'G_Zid9': 7.67, 'G_Zid10': 7.7, 'G_Zid11': 7.64, 'G_Zid12': 7.59, 'G_Zid16': 7.57, 'G_Zid17': 7.48, 'G_Zid18': 7.42, 'G_Zid19': 7.48, 'G_Zid20': 7.41, 'G_Zid21': 7.34, 'G_Zid22': 7.4, 'G_Zid23': 7.33, 'G_Zid27': 7.13, 'G_Zid28': 7.1, 'G_Zid29': 7.18, 'G_Zid30': 7.38, 'G_Zid40': 6.21, 'G_Zid41': 6.1, 'G_Zid42': 6.03, 'G_Zid43': 5.84, 'G_Zid44': 5.7, 'G_Zid45': 5.6, 'G_Zid46': 5.51, 'G_Zid49': 5.24, 'G_Zid50': 5.03, 'G_Zid51': 4.91, 'G_Zid52': 5.02, 'G_Usa0': 7.3, 'G_Usa1': 7.29, 'G_Usa2': 7.25, 'G_Usa3': 7.32, 'G_Usa4': 7.33, 'G_Usa5': 7.27, 'G_Gal00': 7.74, 'G_Gal01': 7.72, 'G_Gal02': 7.69, 'G_Gal03': 7.82, 'G_Gal04': 7.78, 'G_Gal05': 7.75, 'G_Gal06': 7.76, 'G_Gal07': 7.72, 'G_Gal08': 7.75, 'G_Gal10': 7.55, 'G_Gal11': 7.48, 'G_Gal12': 7.42, 'G_Gal13': 7.63, 'G_Gal14': 7.55, 'G_Gal15': 7.52, 'G_Gal16': 7.55, 'G_Gal17': 7.64, 'G_Gal18': 7.65, 'G_Gal20': 7.42, 'G_Gal21': 7.58, 'G_Gal22': 7.51, 'G_Gal23': 7.46, 'G_Gal24': 7.43, 'G_Gal25': 7.55, 'G_Gal26': 7.39, 'G_Gal27': 7.46, 'G_Gal28': 7.48, 'G_Gal30': 7.32, 'G_Gal31': 7.36, 'G_Gal32': 7.3, 'G_Gal33': 7.33, 'G_Gal34': 7.33, 'G_Gal35': 7.31, 'G_Gal36': 7.32, 'G_Gal37': 7.25, 'G_Gal38': 7.21, 'G_Gal40': 5.63, 'G_Gal41': 5.51, 'G_Gal42': 5.44, 'G_Gal43': 5.79, 'G_Gal44': 5.64, 'G_Gal45': 5.6, 'G_Gal46': 5.61, 'G_Gal47': 5.42, 'G_Gal48': 5.54, 'G_Frag0': 7.76, 'G_Frag1': 7.26, 'G_Frag2': 7.48, 'G_Frag3': 7.61, 'G_Frag4': 7.69, 'G_Frag5': 7.62, 'G_Frag6': 7.7, 'G_Frag7': 7.15, 'G_Frag8': 5.74, 'G_Ficus0': 7.55, 'G_Ficus1': 7.24, 'G_Ficus2': 7.33, 'G_Ficus3': 7.16, 'G_Ficus4': 5.61, 'G_Moloz0': 8.08, 'G_Moloz1': 7.85, 'G_Moloz2': 7.89, 'G_Moloz3': 7.82, 'G_Moloz4': 7.74, 'G_Moloz5': 7.79, 'G_Moloz6': 7.72, 'G_Moloz7': 7.68, 'G_Moloz8': 7.59, 'G_Moloz9': 7.7, 'G_Moloz10': 7.53, 'G_Moloz11': 7.59, 'G_Moloz12': 7.56, 'G_Moloz13': 7.48, 'G_Moloz14': 7.47, 'G_Moloz15': 7.41, 'G_Moloz16': 7.53, 'G_Moloz17': 7.37, 'G_Moloz18': 7.24, 'G_Moloz19': 7.21, 'G_Moloz20': 7.11, 'G_Moloz21': 7.08, 'G_Moloz22': 7.06, 'G_Moloz23': 7.06, 'G_Moloz31': 6.55, 'G_Moloz32': 6.34, 'G_Moloz33': 6.1, 'G_Moloz34': 5.97, 'G_Moloz35': 5.77, 'G_Moloz36': 5.47, 'G_Moloz37': 5.42, 'G_Moloz38': 5.42, 'G_Moloz39': 5.18, 'G_Rest0': 7.52, 'G_Rest1': 7.18, 'G_Liane0': 8.18, 'G_Liane1': 7.84, 'G_Liane2': 7.69, 'G_Liane3': 7.56, 'G_Liane4': 7.36, 'G_Liane5': 7.28, 'G_Liane6': 6.14, 'G_Liane7': 5.69, 'G_Liane8': 4.96}
for _n, _y in BASE.items():
    KIT_Y[_n] = round(_y + OFFS.get(_n, 0.0), 2)

# Luminis: jungla in masa nu ingroapa ruinele. Discul rezerva interiorul arcului (x 138-218, nu atinge
# coridorul scurtaturii de la x ~126) si pune doar subarboret mic (ferigi, tufe), ca in bara.
FOREST = [
    dict(label='Ta Prohm incinta %d' % k, kind='disc', at=(round(S0 + ss * M, 5), 30.0), radius=22.0, claim=True,
         species=('fern_cluster', 'tropical_shrub'), weights=(0.6, 0.4), spacing=4.5, edge_clear_m=3.0,
         shadow_m=0.0, scale_min=0.9, scale_max=1.5, seed=649 + k)
    for k, ss in enumerate((66, 96, 124, 152, 224, 250))
]
