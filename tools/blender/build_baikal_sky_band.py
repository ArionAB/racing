"""Banda de orizont a cerului Baikal (Track10) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/baikal_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa:
lacul inghetat pana la orizont (zapada viscolita pe gheata turcoaz), malurile
cu dealuri de taiga inzapezita, falezele de marmura ale Olkhonului care intra in
gheata, Muntii Primorsky (mainland, spre vest) in planuri tot mai palide si,
peste larg, malul estic abia ghicit (Barguzin / Svyatoy Nos); cerul ramane
TRANSPARENT, fiindca gradientul lui il deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`). Banda e lipita de cer, deci sta la
infinit: nu intra in frustum, nu costa triunghiuri, nu o taie FAR_PLANE (380 m).

Geografia jocului, pe care o continua banda (masurata pe Track10.baked, vezi
`NEAR_GIANTS`): satul Khuzhir, padurea si viaductul sunt pe uscat, la VEST;
autostrada de gheata iese spre EST, pe lac. Deci banda pune uscatul (taiga,
apoi Primorsky cu zapada) pe semicercul de vest si larg deschis spre est, cu
capuri si insule de marmura (Olkhon) care rup linia gheții, si malul opus la
25-40 km, un fir albastru-pal.

Problema centrala, ca pe Monument Valley: IMBINAREA. Gheata jocului se termina
la FAR_PLANE (380 m), cetoasa (fog_end 330, fog_max 0,85), si intra in PODEAUA
pictata a benzii. Podeaua e deci aceeasi gheata cu zapada, luminata de acelasi
soare, voalata spre gheata cetoasa (ICE_HAZE), nu spre aerul roz al cerului;
`below` din tema = podeaua de la marginea de jos (B5C8CB). `fog` e cu ~10% mai
deschis (D0E3E6): aceeasi culoare iese pe ecran mai luminoasa prin cer decat prin
ceata — masurat pe capturi, vezi comentariul temei.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste gheata, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "baikal" (`sun_rotation_deg` (-24, 135, 0): busola 45,
    NE, 24 de grade sus), `sun_color` (1.0, 0.90, 0.78), energia 1,0; ambientul
    C4D2E6 la 0,32;
  * HAZE = `sky_horizon` din tema (F2E0DB): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import math
import os
import sys

import numpy as np
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Gheata e la cota 0 a benzii. In joc placa lacului sta la sea_level_offset
# (-7,05), soseaua de pe mal la 0..12,5 m, camera la 10 m peste ea: ochiul e la
# ~17-30 m peste gheata. 20 e mijlocul; la kilometri distanta diferenta e sub
# un grad.
CAM_Z = 20.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "baikal_horizon_band_test.png" if TEST else "baikal_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


def lin(hx):
    return np.array(srgb(hx)[:3])


# --- Paleta (sRGB, din kitul pistei: docs/track_briefs/baikal.md §4) -------------
HAZE = "F2E0DB"          # = sky_horizon din tema: departarea intra in cer
ICE_HAZE = "C9D3D6"      # gheata departata, cetoasa: aerul rece de deasupra lacului
HAZE_COOL = "AEBFCC"     # voalul aproape (sub ~2 km): rece, albastrui
HAZE_COOL_D = (1500.0, 9000.0)            # de la rece la HAZE, dupa distanta
SNOW = "EEF2F4"          # snow_white (FOAM_WHITE)
SNOW_DRIFT = "DCE6EC"    # zapada viscolita pe gheata, cu umbra de val
ICE = "7FC4C9"           # ice_turquoise: gheata goala, maturata de vant
ICE_DUSTED = "A6D5D8"    # gheata goala vazuta de departe: turcoazul jocului
                         # (~(170,203,198) pe captura la 150-250 m), pudrat
# taiga: larici + pini siberieni cu zapada pe ramuri, vazuti de la 1-10 km.
# Verde-negru, dar VERDE (pinii din kit), nu gri.
# (inchise si saturate: Godot afiseaza banda cu ~10% mai luminoasa decat PNG-ul,
#  iar la 0,7 km, cu voalul, padurea mai deschisa citea gri-camuflaj)
CONIFER = ["1C3322", "22392A", "274230", "1A2E20", "2C4832"]
LARCH = "8A5A38"         # larch_rust stins: laricii goi iarna
BIRCH = "8E8790"         # mesteacanul gol: gri-violaceu
MARBLE = "B8B4AC"        # marble_grey: faleza Olkhon
MARBLE_DARK = "77716B"
LICHEN = "9C5E40"        # licheni rosii pe fetele de sud
GRASS = "AF9F4E"         # dry grass: stepa Olkhonului iese prin zapada
SUN_COLOR = (1.0, 0.90, 0.78)
# Godot: energia 1,0 la soare = iradianta 1; Cycles: un Sun de 1 W/m^2 lumineaza
# o suprafata difuza cu 1/pi — factorul pi tine aceeasi conventie ca pe MV.
SUN_STRENGTH = math.pi * 1.0
AMBIENT = "C4D2E6"
AMBIENT_ENERGY = 0.32
SUN_ROT = (-24.0, 135.0)                  # sun_rotation_deg (x, y) din tema
SNOW_GLOW = 0.18                          # zapada din umbra nu iese gri-murdar

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului incolo (F0 = cat a spalat deja ceata jocului acolo). Aerul de iarna e
# uscat, dar tema e laptoasa (cer alb spre roz): planul de la 1 km iese putin
# voalat, Primorsky (8-15 km) albastru-pal, malul estic (30 km) aproape cer.
HAZE_D0, HAZE_D, HAZE_F0 = 330.0, 9000.0, 0.18
HAZE_MAX = 0.90
NEAR_HAZE_K = 0.75                        # planul 0 (0,55-0,85 km) mai limpede
# Ceata joasa pe gheata (viscol fin): K * exp(-z/H), doar departe
DRIFT_H, DRIFT_K = 25.0, 0.30


# --- Zgomot (numpy, in coordonate de lume: fara cusatura pe azimut) -------------

def _hash2(ix, iy, seed):
    n = (ix.astype(np.int64) * 374761393 + iy.astype(np.int64) * 668265263
         + seed * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def vnoise(x, y, scale, seed):
    u, v = x / scale, y / scale
    i, j = np.floor(u), np.floor(v)
    fu, fv = u - i, v - j
    fu = fu * fu * (3.0 - 2.0 * fu)
    fv = fv * fv * (3.0 - 2.0 * fv)
    a = _hash2(i, j, seed) * (1 - fu) + _hash2(i + 1, j, seed) * fu
    c = _hash2(i, j + 1, seed) * (1 - fu) + _hash2(i + 1, j + 1, seed) * fu
    return a * (1 - fv) + c * fv


def fbm(x, y, scale, seed, octaves=5, ridged=False):
    tot, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        n = vnoise(x, y, scale / (2.0 ** o), seed + 17 * o)
        if ridged:
            n = 1.0 - np.abs(2.0 * n - 1.0)
            n = n * n
        tot = tot + n * amp
        norm += amp
        amp *= 0.5
    return tot / norm


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def az_diff(a, b):
    """Diferenta de azimut in grade, in (-180, 180]."""
    return (a - b + 180.0) % 360.0 - 180.0


def sector(azd, lo, hi, soft):
    """1 in sectorul de busola [lo, hi] (in sensul acelor), topit pe `soft` grade."""
    mid = (lo + (((hi - lo) % 360.0) / 2.0)) % 360.0
    half = ((hi - lo) % 360.0) / 2.0
    d = np.abs(az_diff(azd, mid))
    return smoothstep(half + soft, half - soft, d)


# --- Geografia (busola: 0 N, 90 E; distante in metri) ---------------------------
#
# Planul 0, pus de mana pe azimuturile camerei de joc (sonda temporara pe
# Track10.baked, camera ChaseCamera: 10 m sus, 12,5 m in urma, fov 68 vertical,
# deci ~100 de grade pe orizontala la 16:9 si 5-6 grade de cer deasupra
# orizontului pe drum plat):
#
#   portiunea                       fractii      directia camerei  cer in cadru
#   ulita din Khuzhir (start)       0,00-0,07    92-100            ~5 grade
#   rampa spre gheata (Saman)       0,10-0,18    121-142           -1..2 (privesti in jos)
#   autostrada de gheata            0,19-0,28    92-128            ~5
#   larg, spre soare (contre-jour)  0,29-0,38    86-45             ~5
#   dreapta spre nord, pe gheata    0,43-0,50    336-354           ~5
#   iesirea de pe gheata, urcare    0,51-0,62    327-286           5-10
#   viaductul (cea mai lunga)       0,63-0,78    249-262           5-10
#   coborarea, padurea              0,79-0,94    232-306, 255-197  4,5-6,5
#   intoarcerea in sat              0,95-0,98    179-103           ~4,5
#
# Regulile plasarii: nimic pe axa unei drepte lungi (viaductul 257, nordul 345,
# ulita 95), deci 20-30 de grade lateral; NE-ul (45-86) ramane larg deschis —
# acolo e soarele, iar o forma mare ar iesi in contre-jour mai inchisa decat
# relieful 3D cetos din fata (lectia de pe Monument Valley); estul ramane lacul
# pana la orizont. Reperele 3D ale pistei (masivul tunelului, Stanca Samanului,
# capul grotei) stau toate sub 400 m, deci nu se suprapun cu banda.
#
# Fiecare: (nume, azimut, distanta, unghiul varfului peste ochi, raza/inaltime,
#           fel). fel: "taiga" = deal rotund cu padure; "cape" = cap de marmura
# cu faleza spre lac.
NEAR_GIANTS = [
    # (nume, azimut, distanta, unghi varf, semilungime pe azimut in grade,
    #  adancime radiala in m, fel)
    # A — viaductul in stanga (25 de grade de axa), padurea 0,88-0,92 in fata:
    # o creasta lunga de taiga, cu doua cocoase
    ("A", 230.0, 700.0, 7.0, 20.0, 420.0, "taiga"),
    # B — viaductul in dreapta (26), urcarea de pe gheata in stanga: cel mai
    # inalt, iese din cadru pe urcare (cerul ajunge la 10 grade acolo)
    ("B", 283.0, 640.0, 8.5, 17.0, 380.0, "taiga"),
    # C — dreapta spre nord in stanga, urcarea in dreapta
    ("C", 326.0, 780.0, 6.0, 18.0, 450.0, "taiga"),
    # D — cap de marmura (Olkhon) in dreapta dreptei spre nord, 30 de grade:
    # platou cu faleza spre lac, jos fata de dealuri
    ("D", 18.0, 720.0, 4.6, 13.0, 260.0, "cape"),
    # E — cap de marmura spre sud, in dreapta rampei de pe Saman (20-40 de grade)
    ("E", 166.0, 800.0, 4.2, 12.0, 260.0, "cape"),
]

# Muntii de pe continent (Primorsky), pe semicercul de vest: straturi de creste
# (distanta, unghiul mediu al crestei peste ochi). Golurile din straturi lasa sa
# se vada planul din spate, fiecare mai palid.
WEST_SECTOR = (195.0, 345.0, 25.0)        # busola lo, hi, topire
WEST_LAYERS = [
    (1100.0, 2.6), (1700.0, 3.2), (2700.0, 3.8), (4200.0, 4.4),
    (6500.0, 4.9), (10000.0, 5.3), (15000.0, 5.5),
]
# Malul estic, peste larg: un fir lung si jos (Barguzin / Svyatoy Nos).
EAST_SHORE = (20.0, 200.0, 20.0, 30000.0, 0.7, 2.4)   # lo, hi, topire, d, theta min/max
# Insule si capuri departate pe lac (Olkhon si insulele mici din Maloye More):
# (azimut, distanta, lungime pe azimut in grade, unghi varf, fel)
ISLANDS = [
    ("Ogoy", 112.0, 3200.0, 11.0, 1.3, "isl"),      # insula mica, lunga, in larg
    ("Boro", 146.0, 2100.0, 9.0, 1.0, "isl"),
    ("Khibin", 58.0, 5200.0, 13.0, 1.1, "isl"),     # spre soare: jos si departe
    ("Izhimei", 190.0, 2600.0, 20.0, 1.8, "isl"),  # malul de sud al golfului
]


def crest_h(d, theta_deg):
    return CAM_Z + d * math.tan(math.radians(theta_deg))


def heights(px, py, r, azd):
    """Inaltimea reliefului (gheata = 0), inaltimea locala a crestei (pentru
    fractia de inaltime), si tipul: 0 taiga continent, 1 mal estic, 2 insula/cap,
    3 planul 0."""
    z = np.full(px.shape, -6.0)
    hm = np.ones(px.shape)
    kind = np.zeros(px.shape, dtype=np.int32)

    def take(zk, crest, k):
        nonlocal z, hm, kind
        better = zk > z
        hm = np.where(better, crest, hm)
        kind = np.where(better, k, kind)
        z = np.maximum(z, zk)

    west = sector(azd, *WEST_SECTOR)
    for k, (dk, th) in enumerate(WEST_LAYERS):
        hc = crest_h(dk, th)
        big = fbm(px, py, dk * 0.45, 100 + k, octaves=3)
        jag = fbm(px, py, dk * 0.10, 200 + k, octaves=5, ridged=True)
        # muntii Baikalului sunt vechi si rotunjiti: mai putin zimtat decat fiordul
        crest = hc * (0.40 + 0.60 * big + 0.35 * jag)
        if k > 0:
            gap = smoothstep(0.38, 0.30, fbm(px, py, dk * 0.6, 300 + k, octaves=2))
            crest = crest * (1.0 - 0.7 * gap)
        crest = crest * west
        wf, wb = dk * 0.32, dk * 0.35
        t = np.where(r < dk, 1.0 - (dk - r) / wf, 1.0 - (r - dk) / wb)
        t = np.clip(t, 0.0, 1.0)
        prof = t * t * (3.0 - 2.0 * t)
        take(-6.0 + (crest + 6.0) * prof, crest, 0)

    lo, hi, soft, d0, th0, th1 = EAST_SHORE
    east = sector(azd, lo, hi, soft)
    dd = d0 * (1.0 + 0.25 * (fbm(px, py, 9000.0, 401, octaves=2) - 0.5))
    hc0, hc1 = crest_h(d0, th0), crest_h(d0, th1)
    crest = (hc0 + (hc1 - hc0) * smoothstep(0.3, 0.75, fbm(px, py, 6000.0, 402, octaves=3))) * east
    crest = crest * (0.55 + 0.75 * fbm(px, py, 2200.0, 403, octaves=5, ridged=True))
    t = np.where(r < dd, 1.0 - (dd - r) / (dd * 0.08), 1.0)
    t = np.clip(t, 0.0, 1.0)
    take(-6.0 + (crest + 6.0) * t * t * (3 - 2 * t), crest, 1)

    for i, (name, az0, d0, span, th, fel) in enumerate(ISLANDS):
        zz, cc = near_hill(px, py, az0, d0, th, span / 2.0, d0 * 0.07, "cape", 500 + 7 * i)
        take(zz, cc, 2)

    for i, (name, az0, d0, th, half, depth, fel) in enumerate(NEAR_GIANTS):
        zz, cc = near_hill(px, py, az0, d0, th, half, depth, fel, 700 + 11 * i)
        take(zz, cc, 3)

    # contraforturi si ravene pe fete (zgomot fin)
    z += (fbm(px, py, 160.0, 29, octaves=3) - 0.5) * 0.10 * hm * (z > 0)
    # ravene pe dealurile apropiate: spinarea lina citea ca plastic
    z -= fbm(px, py, 70.0, 31, octaves=3, ridged=True) * 0.12 * hm * (kind == 3) * (z > 0)
    return z, hm, kind


def near_hill(px, py, az0, d0, th, half_deg, depth, fel, seed):
    """Creasta lunga pe azimut (dealurile Baikalului sunt spinari, nu movile):
    inaltimea pe lungime are 2-3 cocoase din zgomot si coboara LIN spre capete
    (un capat abrupt citea ca o perdea atarnata), sectiunea e o cupola (taiga)
    sau un platou cu faleza (cap de marmura)."""
    hc = crest_h(d0, th)
    rr = np.sqrt(px * px + py * py)
    ang = np.radians(az_diff(np.degrees(np.arctan2(px, py)) % 360.0, az0))
    u = ang * d0                                        # metri pe lungime
    L = d0 * math.radians(half_deg)
    v = rr - d0 + 0.05 * depth * np.sin(u / L * 1.7 + seed)
    su = np.abs(u) / (L * (1.0 + 0.2 * (fbm(px, py, L * 0.6, seed, octaves=2) - 0.5)))
    taper = np.clip(1.0 - su * su, 0.0, 1.0) ** 1.4
    if fel == "cape":
        # capul: spinarea urca lin dinspre uscat (u < 0) si se rupe in faleza la
        # capatul dinspre larg (u > 0) — silueta de cap, nu de movila
        taper = np.where(u > 0.0, smoothstep(1.0, 0.86, su) * (1.0 - 0.25 * su),
                         np.clip(1.0 - su * su, 0.0, 1.0) ** 0.9)
    hump = fbm(u, np.full_like(u, float(seed)), L * 0.5, seed + 1, octaves=3)
    crest = hc * (0.55 + 0.6 * hump) * taper
    # marginea zdrentuita pe lungime: contraforturi si golfulete, nu un perete drept
    edge = 1.0 + 0.30 * (fbm(u, np.full_like(u, 3.0 * seed), depth * 0.6, seed + 5, octaves=3) - 0.5)
    sv = np.abs(v) / (depth * (0.7 + 0.3 * taper) * edge)
    if fel == "cape":
        # platou rotund sus, faleza abrupta pe ultima treime
        cross = np.where(sv < 0.7, 1.0 - 0.15 * (sv / 0.7) ** 2,
                         0.85 * smoothstep(1.0, 0.86, sv))
    else:
        cross = np.clip(1.0 - sv * sv, 0.0, 1.0) ** 1.3
    zz = -6.0 + (crest + 6.0) * cross
    return zz, np.full(px.shape, hc)


# --- Scena -----------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node, haze_k_socket=None, haze_k=1.0, haze_hex=HAZE):
    """surface -> amestec cu HAZE dupa distanta (de la fog_end-ul jocului) si cu
    viscolul jos dupa inaltime. `haze_k_socket` (0..1) inmulteste voalul per
    punct (planul 0 e mai limpede)."""
    n = nt.nodes
    L = nt.links
    cam = n.new("ShaderNodeCameraData")
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])

    def math_node(op, a=None, b=None, va=None, vb=None):
        m = n.new("ShaderNodeMath")
        m.operation = op
        if a is not None:
            L.new(a, m.inputs[0])
        elif va is not None:
            m.inputs[0].default_value = va
        if b is not None:
            L.new(b, m.inputs[1])
        elif vb is not None:
            m.inputs[1].default_value = vb
        return m.outputs[0]

    d = cam.outputs["View Distance"]
    x = math_node("SUBTRACT", d, vb=HAZE_D0)
    x = math_node("MAXIMUM", x, vb=0.0)
    x = math_node("MULTIPLY", x, vb=-1.0 / HAZE_D)
    x = math_node("EXPONENT", x)
    keep_air = math_node("MULTIPLY", x, vb=1.0 - HAZE_F0)
    keep_air = math_node("MAXIMUM", keep_air, vb=1.0 - HAZE_MAX)
    zz = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    zz = math_node("MULTIPLY", zz, vb=-1.0 / DRIFT_H)
    zz = math_node("EXPONENT", zz)
    ramp = n.new("ShaderNodeMapRange")                        # viscol doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 1200.0
    ramp.inputs["From Max"].default_value = 5000.0
    drift = math_node("MULTIPLY", zz, ramp.outputs["Result"])
    drift = math_node("MULTIPLY", drift, vb=DRIFT_K)
    keep = math_node("MULTIPLY", keep_air, math_node("SUBTRACT", va=1.0, b=drift))
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    if haze_k_socket is not None:
        fac = math_node("MULTIPLY", fac, haze_k_socket)
    elif haze_k != 1.0:
        fac = math_node("MULTIPLY", fac, vb=haze_k)
    # Culoarea voalului: rece aproape (aerul de deasupra gheții, in familia
    # cetii jocului), roz-palid departe (cerul de la orizont). Cu un singur
    # HAZE roz, padurea de la 0,7 km iesea gri-maronie, nu verde-negru.
    hmix = n.new("ShaderNodeMix")
    hmix.data_type = "RGBA"
    hr = n.new("ShaderNodeMapRange")
    hr.interpolation_type = "SMOOTHSTEP"
    L.new(d, hr.inputs["Value"])
    hr.inputs["From Min"].default_value = HAZE_COOL_D[0]
    hr.inputs["From Max"].default_value = HAZE_COOL_D[1]
    L.new(hr.outputs["Result"], hmix.inputs[0])
    hmix.inputs[6].default_value = srgb(HAZE_COOL if haze_hex == HAZE else haze_hex)
    hmix.inputs[7].default_value = srgb(haze_hex)
    em = n.new("ShaderNodeEmission")
    L.new(hmix.outputs[2], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    mix = n.new("ShaderNodeMixShader")
    L.new(fac, mix.inputs[0])
    L.new(surface_socket, mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    L.new(mix.outputs[0], out_node.inputs["Surface"])


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def land_material():
    """Culoarea in vertex color (Col: rgb + alfa = cat e zapada); atributul
    `HazeK` = voalul relativ (planul 0 mai limpede)."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    hk = n.new("ShaderNodeAttribute")
    hk.attribute_name = "HazeK"
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    L.new(at.outputs["Color"], bsdf.inputs["Color"])
    em = n.new("ShaderNodeEmission")
    L.new(at.outputs["Color"], em.inputs["Color"])
    k = n.new("ShaderNodeMath")
    k.operation = "MULTIPLY"
    k.inputs[1].default_value = SNOW_GLOW
    L.new(at.outputs["Alpha"], k.inputs[0])
    L.new(k.outputs[0], em.inputs["Strength"])
    add = n.new("ShaderNodeAddShader")
    L.new(bsdf.outputs[0], add.inputs[0])
    L.new(em.outputs[0], add.inputs[1])
    haze_wrap(nt, add.outputs[0], out, haze_k_socket=hk.outputs["Fac"])
    return mat


def floor_material():
    """Gheata cu zapada viscolita: dungi lungi pe directia vantului (din SE spre
    NV, ca in tema), gheata turcoaz maturata intre ele. Luminata de acelasi
    soare ca relieful, ca podeaua sa aiba culoarea gheții jocului."""
    mat, nt, out = new_material("BandFloor")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    # dungile: intinse pe directia vantului (busola 135 -> 315)
    # (doar 2:1 — mai lungi, din perspectiva camerei joase, ieseau raze care
    # converg spre ochi, ca un efect de viteza)
    mp.inputs["Rotation"].default_value = (0.0, 0.0, math.radians(45.0))
    mp.inputs["Scale"].default_value = (1.0, 2.0, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 0.004
    nz.inputs["Detail"].default_value = 6.0
    nz.inputs["Roughness"].default_value = 0.6
    L.new(mp.outputs[0], nz.inputs["Vector"])
    cr = n.new("ShaderNodeValToRGB")
    cr.color_ramp.elements[0].position = 0.42
    cr.color_ramp.elements[0].color = srgb(ICE_DUSTED)
    cr.color_ramp.elements[1].position = 0.56
    cr.color_ramp.elements[1].color = srgb(SNOW_DRIFT)
    L.new(nz.outputs["Fac"], cr.inputs["Fac"])
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    L.new(cr.outputs["Color"], bsdf.inputs["Color"])
    em = n.new("ShaderNodeEmission")
    L.new(cr.outputs["Color"], em.inputs["Color"])
    em.inputs["Strength"].default_value = SNOW_GLOW
    add = n.new("ShaderNodeAddShader")
    L.new(bsdf.outputs[0], add.inputs[0])
    L.new(em.outputs[0], add.inputs[1])
    # Podeaua se voaleaza spre gheata cetoasa (ICE_HAZE), nu spre aerul roz
    # al cerului: cu HAZE, gheata pictata de la 0,5-2 km iesea roz-alba, cu
    # ~25 de trepte peste gheata jocului de la fog_end (dunga pe captura de
    # pe larg, 0,35). Orizontul ramane linia dintre gheata palida si cer.
    haze_wrap(nt, add.outputs[0], out, haze_hex=ICE_HAZE)
    return mat


# --- Relieful: camp de inaltimi polar ------------------------------------------

N_AZ = 1024 if TEST else 4096
N_R = 140 if TEST else 560
R0, R1 = 480.0, 34000.0


def build_land():
    az = np.linspace(0.0, math.tau, N_AZ, endpoint=False)
    rr = R0 * np.power(R1 / R0, np.linspace(0.0, 1.0, N_R))
    A, Rg = np.meshgrid(az, rr)                     # (N_R, N_AZ)
    px = np.sin(A) * Rg
    py = np.cos(A) * Rg
    azd = np.degrees(A) % 360.0
    z, hm, kind = heights(px, py, Rg, azd)
    nverts = N_R * N_AZ
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(N_R - 1), np.arange(N_AZ), indexing="ij")
    j1 = (jj + 1) % N_AZ
    v0 = ii * N_AZ + jj
    v1 = ii * N_AZ + j1
    v2 = (ii + 1) * N_AZ + j1
    v3 = (ii + 1) * N_AZ + jj
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)
    nf = (N_R - 1) * N_AZ
    me = bpy.data.meshes.new("BandLand")
    me.vertices.add(nverts)
    me.vertices.foreach_set("co", co.astype(np.float32).ravel())
    me.loops.add(nf * 4)
    me.loops.foreach_set("vertex_index", quads.astype(np.int32))
    me.polygons.add(nf)
    me.polygons.foreach_set("loop_start", (np.arange(nf) * 4).astype(np.int32))
    me.polygons.foreach_set("loop_total", np.full(nf, 4, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    nrm = np.empty(nverts * 3, dtype=np.float32)
    me.vertex_normals.foreach_get("vector", nrm)
    nrm = nrm.reshape(N_R, N_AZ, 3)
    nz = nrm[..., 2]
    # orientarea fetei spre sud (pentru licheni si stepa): componenta -y
    south = -nrm[..., 1]

    hfrac = np.clip(z / np.maximum(hm, 1.0), 0.0, 1.2)
    # --- padurea: pe pantele lin-medii, nu pe creste golase si nu pe faleze
    fn = fbm(px, py, 260.0, 53, octaves=3)
    rag = fbm(px, py, 40.0, 57, octaves=3)
    tree_line = 0.62 + 0.20 * fn + 0.10 * (rag - 0.5)
    # dealurile de taiga apropiate sunt impadurite aproape pana sus (Baikalul
    # are munti vechi, rotunzi); doar calota ramane alba
    tree_line = tree_line + np.where(kind == 3, 0.22, 0.0)
    forest = smoothstep(tree_line + 0.04, tree_line - 0.04, hfrac)
    forest *= smoothstep(0.45, 0.70, nz)                        # nu pe faleze
    # poieni mari pe continent; pe dealurile apropiate doar luminisuri mici
    # (o poiana mare de zapada citea ca o gaura prin deal)
    forest *= smoothstep(0.30, 0.50, fbm(px, py, 900.0, 59, octaves=3) + 0.15 * (kind == 0)
                         + 0.35 * (kind == 3))
    forest *= smoothstep(0.0, 0.06, hfrac)                      # nu pe gheata
    # insulele (Olkhon) sunt mai mult stepa: padure doar in pete
    forest *= np.where(kind == 2, 0.6, 1.0)
    fcol_i = np.clip((vnoise(px, py, 24.0, 71) * len(CONIFER)).astype(int), 0, len(CONIFER) - 1)
    fpal = np.array([lin(c) for c in CONIFER])
    tree = fpal[fcol_i]
    # pete de larici ruginii si mesteceni gri in padure, jos
    decid = 0.7 * smoothstep(0.60, 0.70, fbm(px, py, 45.0, 73, octaves=3)) * smoothstep(0.5, 0.2, hfrac)
    birch = smoothstep(0.64, 0.72, fbm(px, py, 35.0, 79, octaves=3))
    tree = tree * (1 - decid)[..., None] + lin(LARCH) * decid[..., None]
    tree = tree * (1 - birch * 0.6)[..., None] + lin(BIRCH) * (birch * 0.6)[..., None]
    # zapada pe crengi si in poieni: padurea vazuta de departe e „sare si piper"
    speck = smoothstep(0.45, 0.75, vnoise(px, py, 22.0, 81))
    tree = tree * (1 - 0.25 * speck)[..., None] + lin(SNOW) * (0.25 * speck)[..., None]

    # --- stanca: pe fetele abrupte (falezele de marmura ale capurilor si insulelor)
    steep = smoothstep(0.62, 0.40, nz) * smoothstep(0.0, 0.05, hfrac)
    streak = 0.6 * smoothstep(0.5, 0.85, vnoise(px + 0.4 * py, py - 0.4 * px + z * 0.01, 16.0, 41))
    rock = lin(MARBLE)[None, None, :] * (1 - 0.55 * streak)[..., None] \
        + lin(MARBLE_DARK)[None, None, :] * (0.55 * streak)[..., None]
    lich = smoothstep(0.1, 0.5, south) * smoothstep(0.55, 0.75, fbm(px, py, 30.0, 47, octaves=3))
    rock = rock * (1 - 0.5 * lich)[..., None] + lin(LICHEN) * (0.5 * lich)[..., None]
    # insulele din larg: faleza mai inchisa (marmura uda, umbra), altfel la
    # 2-5 km, voalate, citeau a aisberguri albe
    rock = rock * np.where(kind == 2, 0.6, 1.0)[..., None]

    # --- zapada cu stepa care iese prin ea (iarba uscata pe fetele de sud, vant)
    grass = smoothstep(0.1, 0.6, south) * smoothstep(0.55, 0.72, fbm(px, py, 150.0, 61, octaves=3))
    grass *= smoothstep(0.0, 0.08, hfrac) * (0.5 + 0.5 * (kind == 2))
    snow = lin(SNOW)[None, None, :] * np.ones_like(z)[..., None]
    snow = snow * (1 - 0.45 * grass)[..., None] + lin(GRASS) * (0.45 * grass)[..., None]

    col = snow * (1 - forest)[..., None] + tree * forest[..., None]
    col = col * (1 - steep)[..., None] + rock * steep[..., None]
    snow_amt = (1 - forest) * (1 - steep)
    # piciorul reliefului (sub gheata): culoarea podelei, ca linia de mal sa fie
    # zapada pe gheata, nu o dunga
    print("banda: padure %.1f%%, stanca %.1f%% din varfurile de uscat" % (
        100.0 * (forest[z > 1] > 0.5).mean(), 100.0 * (steep[z > 1] > 0.5).mean()))

    haze_k = np.where(kind == 3, NEAR_HAZE_K, 1.0)
    rgba = np.concatenate([col.reshape(-1, 3), snow_amt.reshape(-1, 1)], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    hk = me.attributes.new("HazeK", "FLOAT", "POINT")
    hk.data.foreach_set("value", haze_k.astype(np.float32).ravel())
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d varfuri, %d fete" % (N_R, N_AZ, nf))


def build_floor():
    me = bpy.data.meshes.new("BandFloor")
    s = 60000.0
    me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new("BandFloor", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(floor_material())


def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    rx, ry = math.radians(SUN_ROT[0]), math.radians(SUN_ROT[1])
    x, y, z = 0.0, -math.sin(rx), math.cos(rx)
    gx = x * math.cos(ry) + z * math.sin(ry)
    gz = -x * math.sin(ry) + z * math.cos(ry)
    g = Vector((gx, y, gz))                     # Godot: x est, y sus, z sud
    return Vector((g.x, -g.z, g.y)).normalized()  # Blender: x est, y nord, z sus


def setup_render():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        prefs.compute_device_type = "OPTIX"
        prefs.get_devices()
        for dev in prefs.devices:
            dev.use = True
        sc.cycles.device = "GPU"
    except Exception as e:  # fara GPU merge si pe CPU, doar mai incet
        print("GPU indisponibil: %s" % e)
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 3
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.resolution_x = W
    sc.render.resolution_y = H
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    sc.render.filepath = OUT

    cd = bpy.data.cameras.new("BandCam")
    cd.type = "PANO"
    cd.panorama_type = "EQUIRECTANGULAR"
    cd.latitude_min = math.radians(LAT_MIN)
    cd.latitude_max = math.radians(LAT_MAX)
    cd.longitude_min = -math.pi
    cd.longitude_max = math.pi
    cd.clip_start = 1.0
    cd.clip_end = 90000.0
    cam = bpy.data.objects.new("BandCam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, 0.0, CAM_Z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # priveste spre +Y (nord)
    sc.camera = cam

    ld = bpy.data.lights.new("BandSun", "SUN")
    ld.energy = SUN_STRENGTH
    ld.color = SUN_COLOR
    ld.angle = math.radians(0.6)
    sun = bpy.data.objects.new("BandSun", ld)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (-sun_dir_blender()).to_track_quat("-Z", "Y").to_euler()

    world = bpy.data.worlds.new("BandWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = srgb(AMBIENT)
    bg.inputs["Strength"].default_value = AMBIENT_ENERGY
    sc.world = world


def test_markers():
    """Cuburi emisive pe punctele cardinale, la 800 m: rosu E, verde N, albastru V."""
    for name, (x, y), col in (("E", (800, 0), (1, 0, 0, 1)), ("N", (0, 800), (0, 1, 0, 1)),
                              ("V", (-800, 0), (0, 0, 1, 1))):
        me = bpy.data.meshes.new("Mk" + name)
        s = 30.0
        vs = [(x + dx * s, y + dy * s, 70 + dz * s) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
        fs = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        me.from_pydata(vs, [], fs)
        ob = bpy.data.objects.new("Mk" + name, me)
        bpy.context.collection.objects.link(ob)
        mat, nt, out = new_material("Mk" + name)
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = col
        em.inputs["Strength"].default_value = 3.0
        nt.links.new(em.outputs[0], out.inputs["Surface"])
        ob.data.materials.append(mat)


reset()
setup_render()
build_floor()
build_land()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
