"""Banda de orizont a cerului Okinawa (Track20) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/okinawa_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa: marea
subtropicala (albastru adanc in larg, turcoaz pe recif la mal), insulele din larg
(Ie-jima cu conul Gusukuyama la NV, arhipelagul Kerama la V-SV), coasta impadurita
a insulei principale cu promontorii de calcar, cateva barci si feribotul; cerul
ramane TRANSPARENT, fiindca gradientul si norii lui ii deseneaza shaderul de cer
din joc (`scenes/tracks/sky_band.gdshader`). Banda e lipita de cer, deci sta la
infinit: nu intra in frustum, nu costa triunghiuri, nu o taie FAR_PLANE (380 m).

Reteta e cea de pe Ha Long (marea pictata intra in marea jocului) si Fiordland
(relieful e un camp de inaltimi POLAR, in numpy, nu obiecte asezate): fiecare
insula e o forma pe harta (elipsa cu tarm zdrentuit), iar inaltimea, faleza,
plaja, padurea si recife le da distanta pana la tarm. Marea e o grila polara
separata, colorata dupa aceeasi distanta: turcoaz deschis pe recif, albastru
adanc in larg. Primul plan (`NEAR`, 0,6-1,1 km) sunt promontorii si insule MARI,
puse de mana pe directiile camerei de joc (vezi tabelul de la `NEAR`), care dau
scara; restul (Kerama, Ie, coasta, muntii Yanbaru) e tot mai palid in aer.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste mare, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "okinawa" (`sun_rotation_deg` (-25, -70, 0), adica busola
    250, VSV, 25 de grade elevatie), `sun_color` (1.0, 0.90, 0.74), energia 1,5
    (mostenita din "island"); ambientul EADFC8 la 0,22;
  * HAZE = `sky_horizon` din tema (0.42, 0.64, 0.90): departarea se topeste exact
    in culoarea pe care o deseneaza cerul din joc in spatele benzii, deci
    marginea benzii nu se vede;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_okinawa_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import math
import os
import sys

import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Soseaua sta la +1,6 .. +30 m peste mare (`custom_sea_level_offset` -10,57 fata
# de media cotelor), camera la 10 m peste ea: ochiul e la ~12-40 m peste apa.
# 22 e mijlocul; la kilometri distanta diferenta e sub un grad.
CAM_Z = 22.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "okinawa_horizon_band_test.png" if TEST else "okinawa_horizon_band.png")


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


# --- Paleta (sRGB, ca in tema si in brief §1) -------------------------------------
HAZE = "6BA3E6"          # = sky_horizon din tema (0.42, 0.64, 0.90)
MIST = "A9CDEB"          # aerul jos peste mare (spray), mai palid decat cerul
SEA_DEEP = "1F5E8E"      # largul (brief: albastru adanc)
# Marea de langa banda = `below` din tema. NU e o culoare de pictor: e aleasa
# (in trei iteratii pe captura de la 0,54) ca pe ecran sa iasa exact apa jocului
# de la ~350 m: banda (50, 96, 158) langa apa 3D (49, 97, 158). Godot ridica mult
# saturatia si tonurile medii (filmic + saturatie 1,18), deci hexul pare inchis.
SEA_NEAR = "344F73"
REEF = "3FC1C0"          # turcoaz peste nisip
REEF_SHORE = "7FD6C2"    # langa mal, mai verde
FOAM = "EEF4F2"          # spuma de pe buza recifului
SAND = "EDE6D2"          # nisip coraligen
LIME_LIT = "BFB59E"      # calcar Ryukyu in soare (CFC6B0 iesea mai alb decat zidurile 3D)
LIME = "9C937E"
LIME_DARK = "8F8670"     # nise, umbra
LIME_NOTCH = "5E574A"    # nisa de la nivelul marii (roasa de valuri)
FOREST = ["2E5A2C", "3A6A30", "2A4F28", "45773A", "335F2E"]
FIELD = ["9CB34E", "7FA046", "B4B864", "6E9A40"]     # trestie, culturi (Ie-jima)
ROOF = ["EEEAE0", "D9D2C2", "EEEAE0", "B8452E", "E4DED0"]   # sate: var si olane
SUN_COLOR = "FFE6BD"     # Color(1.0, 0.90, 0.74) din tema
# Godot inmulteste energia luminii cu pi fata de Cycles (vezi Monument Valley):
# taria Cycles = pi x energia temei.
SUN_STRENGTH = math.pi * 1.5
AMBIENT = "EADFC8"
AMBIENT_ENERGY = 0.22
SUN_ROT = (-25.0, -70.0)                  # sun_rotation_deg (x, y) din tema

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), plafonata la
# HAZE_MAX. Aer de mare subtropicala: limpede, dar umed — Kerama si Ie la 3-5 km
# se vad verzi-albastrii, Kerama din spate aproape silueta, Yanbaru doar contur.
HAZE_D0, HAZE_D, HAZE_F0, HAZE_MAX = 380.0, 5200.0, 0.10, 0.88
MIST_H, MIST_K = 25.0, 0.30               # ceata joasa pe apa: K * exp(-z/H), departe
FWD_K = 1.6                               # aerul spre soare (vezi haze_wrap)
SEA_D0 = 800.0                            # marea incepe sa se spele abia de aici


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




# --- Harta: insulele, promontoriile, coasta ---------------------------------------
#
# Directiile camerei de joc (sonda temporara pe Track20.baked, ChaseCamera: 10 m
# sus, 12,5 m in spate, fov 68 vertical = ~100 grade pe orizontala la 16:9;
# marginea de sus a cadrului e la +5,3 grade peste orizont pe drum plat). Uscatul
# jocului se termina peste tot la ~400 m de centru; dincolo, in orice directie,
# e mare — deci banda poate avea forme mari oriunde de la ~0,6 km incolo.
#
#   portiunea                fractii      directia camerei   ochiul peste mare
#   portul A (start)         0,00-0,09    268-282            12 m
#   aleea B, coltul N        0,10-0,20    311-347, 6-9       13-16 m
#   urcarea C                0,21-0,33    26-62              17-34 m
#   culmea D (palatul)       0,34-0,46    63-108             35-40 m (punctul inalt)
#   capul si cornisa E       0,48-0,60    150-195            21-36 m
#   podul F                  0,61-0,73    136-172            16-19 m
#   insula G (tromba)        0,74-0,82    181-264            12-15 m
#   digul H (valul)          0,83-0,96    292-331            12 m
#
# Regulile plasarii (lectiile de pe Monument Valley): niciun urias pe axa unei
# drepte lungi (10-25 de grade lateral), primul plan DINCOLO de ~0,6 km (apa
# jocului se termina la 380 m, adica la -1,7 .. -6 grade sub orizont), si
# largul de la S-SE ramane deschis: acolo sta tromba vazuta de pe pod (~158) si
# de acolo vine hula pe dig. Inaltimile sunt alese in GRADE de la ochi:
# h = CAM_Z + d * tan(e).
#
# kind:
#   "headland" promontoriu / insula plata de calcar: faleza abrupta de jur
#              imprejur (cu nisa roasa de valuri la baza), varf plat impadurit
#   "hills"    insula inalta, impadurita, cu creste si faleza joasa (Kerama)
#   "plateau"  platou jos de calcar cu campuri; `cone` = conul Gusukuyama (Ie)
#   "coast"    coasta insulei principale: plaja, sate, dealuri impadurite
#   "range"    muntii din fund (Yanbaru), doar padure si aer


def isl(az, d, rx, ry, h, kind, rot=0.0, seed=0, **kw):
    """rx = semi-axa TANGENTIALA, ry = semi-axa RADIALA (metri); rot in grade."""
    a = math.radians(az)
    out = dict(cx=math.sin(a) * d, cy=math.cos(a) * d, rx=rx, ry=ry, h=h, kind=kind,
               rot=a + math.radians(rot), az=az, d=d, seed=seed)
    out.update(kw)
    return out


ISLANDS = [
    # --- planul 0: uriasii apropiati (0,9-1,15 km), 3,6-5,2 grade peste orizont ---
    # N1 — insula de calcar la VSV: de pe dreapta portului (268-282) in stanga,
    # la 30-45 de grade; de pe plaja G (248) la 10 grade. E in contre-jour
    # (soarele la 250), deci mai departe decat ceilalti: aerul o deschide.
    isl(238.0, 1150.0, 260.0, 170.0, 92.0, "headland", rot=8.0, seed=1),
    # N3 — capul de la N (ca Manzamo): de pe coltul N (6-9) in dreapta, de pe
    # urcare (26-31) in stanga; trece peste umarul dealului cu palatul.
    isl(19.0, 980.0, 300.0, 170.0, 104.0, "headland", rot=-14.0, seed=3),
    # N4 — insula impadurita de la ESE (ca Kouri/Sesoko), cu plaja si recif: de
    # pe culme (100-108) in dreapta, de pe pod (136-141) in stanga.
    isl(121.0, 1050.0, 330.0, 220.0, 118.0, "hills", seed=4, cliff=0.18),
    # N5 — insula de calcar de la SSV: de pe cornisa (177) si de pe insula G
    # (188-195) in dreapta; de pe plaja (230) in stanga.
    isl(212.0, 900.0, 170.0, 120.0, 78.0, "headland", rot=20.0, seed=5),
    # --- Kerama (V-SV, 2,3-7,6 km): insule inalte impadurite, creste zimtate ---
    isl(250.0, 3000.0, 700.0, 420.0, 210.0, "hills", seed=11, cliff=0.25),
    isl(226.0, 4300.0, 900.0, 520.0, 235.0, "hills", seed=12, cliff=0.22),
    isl(270.0, 4900.0, 650.0, 400.0, 190.0, "hills", seed=13, cliff=0.25),
    isl(205.0, 6400.0, 800.0, 450.0, 200.0, "hills", seed=14, cliff=0.2),
    isl(240.0, 7600.0, 1100.0, 600.0, 230.0, "hills", seed=15, cliff=0.2),
    isl(262.0, 2300.0, 160.0, 120.0, 70.0, "headland", seed=16),
    # --- Ie-jima (NV, ~3,4 km): platou jos cu campuri, conul in capatul de est ---
    # Conul la busola ~303: 12 grade in stanga dreptei digului (315), 9 in dreapta
    # celei de pe dig (294). `cone` = (u tangential, v radial, inaltime, raza).
    isl(312.0, 3400.0, 2100.0, 800.0, 58.0, "plateau", rot=4.0, seed=21,
        cone=(-540.0, 60.0, 240.0, 430.0)),
    # --- coasta insulei principale (NNV-E, 1,7-4,2 km) ---
    isl(352.0, 2600.0, 900.0, 500.0, 120.0, "coast", rot=-10.0, seed=31),
    isl(40.0, 3300.0, 1500.0, 700.0, 150.0, "coast", rot=6.0, seed=32),
    isl(78.0, 2400.0, 700.0, 400.0, 105.0, "coast", rot=-8.0, seed=33),
    isl(62.0, 1700.0, 210.0, 140.0, 82.0, "headland", rot=10.0, seed=34),
    isl(95.0, 4200.0, 1300.0, 600.0, 140.0, "coast", rot=0.0, seed=35),
    # --- Yanbaru: muntii din fund (N-NE, 12-15 km) ---
    isl(15.0, 12500.0, 5200.0, 2400.0, 480.0, "range", seed=41),
    isl(62.0, 13500.0, 3800.0, 2000.0, 430.0, "range", seed=42),
    isl(330.0, 14500.0, 3000.0, 1800.0, 360.0, "range", seed=43),
    # --- departe la S, o insula joasa abia citita, dincolo de tromba ---
    isl(176.0, 14000.0, 1200.0, 500.0, 90.0, "hills", seed=51, cliff=0.3),
]

# Stancile-ciuperca (notch rocks) din larg: turnuri de calcar roase la baza, cu
# boschet pe varf — ca piesele `notch_rock` din kit, la 0,65-0,9 km. Perechea de
# la 293-298 sta la 14-19 grade in dreapta dreptei de start (279) si in stanga
# conului lui Ie de pe dig; pe axa dreptei se citea ca un bloc alb la capatul
# drumului. (busola, distanta, inaltime, raza)
STACKS = [
    (293.0, 660.0, 36.0, 17.0), (298.0, 740.0, 24.0, 11.0),
    (200.0, 760.0, 34.0, 15.0), (224.0, 700.0, 26.0, 11.0),
    (130.0, 800.0, 28.0, 12.0), (99.0, 760.0, 38.0, 16.0), (106.0, 840.0, 22.0, 10.0),
    (338.0, 900.0, 30.0, 13.0), (52.0, 820.0, 26.0, 11.0),
]


def local_frame(px, py, isl_):
    """(u tangential, v radial) in sistemul insulei, rotit cu azimutul ei."""
    dx, dy = px - isl_["cx"], py - isl_["cy"]
    c, s = math.cos(isl_["rot"]), math.sin(isl_["rot"])
    u = dx * c - dy * s
    v = dx * s + dy * c
    return u, v


def shore_dist(px, py, isl_):
    """Distanta (metri, aproximativa) de la tarm spre interior; negativ = in mare.
    Tarmul e o elipsa cu golfuri si capuri (zgomot in coordonate de lume)."""
    u, v = local_frame(px, py, isl_)
    rx, ry = isl_["rx"], isl_["ry"]
    q = np.sqrt((u / rx) ** 2 + (v / ry) ** 2)
    sd = isl_["seed"]
    L = min(rx, ry)
    warp = (fbm(px, py, L * 0.9, 600 + sd, octaves=4) - 0.5) * 0.55
    warp += (fbm(px, py, L * 0.18, 700 + sd, octaves=3) - 0.5) * 0.18
    return (1.0 - q * (1.0 + warp)) * L


def island_height(px, py, isl_, sdm):
    """Inaltimea unei insule, din distanta pana la tarm `sdm`."""
    h = isl_["h"]
    k = isl_["kind"]
    sd = isl_["seed"]
    L = min(isl_["rx"], isl_["ry"])
    if k == "headland":
        # raft de stanca la nivelul marii, faleza de calcar aproape verticala
        # (`cliff` din inaltime: cum sunt insulitele Ryukyu, un brau crem de
        # piatra roasa), deasupra un dom de padure deasa
        cf = isl_.get("cliff", 0.26)
        shelf = 4.0 + 6.0 * fbm(px, py, 40.0, 800 + sd, octaves=2)
        # braul de piatra nu e un zid de jur imprejur: pe unele portiuni coboara
        # pana la o treapta de cativa metri, unde padurea ajunge la apa
        vary = smoothstep(0.25, 0.75, fbm(px, py, L * 0.45, 810 + sd, octaves=3))
        ch = np.maximum(5.0, h * cf * (0.25 + 1.0 * vary))
        cw = 0.22 * ch
        wall = smoothstep(shelf, shelf + cw, sdm) ** 0.7
        dome = smoothstep(shelf + cw, shelf + cw + L * 0.7, sdm) ** 0.65
        top = (h - ch) * (0.75 + 0.35 * fbm(px, py, L * 0.5, 820 + sd, octaves=3))
        z = 1.2 + (ch - 1.2) * wall + top * dome
    elif k == "hills":
        cliff = isl_.get("cliff", 0.2)
        s = np.clip(sdm / L, 0.0, 1.0)
        ridge = fbm(px, py, L * 0.7, 900 + sd, octaves=5, ridged=True)
        big = fbm(px, py, L * 1.4, 910 + sd, octaves=3)
        hills = h * (s ** 0.55) * (0.35 + 0.45 * ridge + 0.35 * big)
        base = h * cliff * smoothstep(3.0, 3.0 + h * cliff * 0.5, sdm)
        z = np.maximum(hills, base)
        # plaja in golfuri: unde zgomotul o cere, faleza joasa dispare
        beach = smoothstep(0.62, 0.72, fbm(px, py, L * 0.35, 930 + sd, octaves=2))
        z = z * (1.0 - beach * (1.0 - smoothstep(0.0, 40.0, sdm)))
    elif k == "plateau":
        # malul: o treapta joasa de calcar (6-12 m), apoi panta verde si lunga
        # pana la platou — de la 3 km se vede doar muchia, deci ea trebuie sa
        # fie verde, nu un zid alb
        step = (6.0 + 6.0 * fbm(px, py, 300.0, 940 + sd, octaves=2)) * smoothstep(2.0, 8.0, sdm)
        slope = h * smoothstep(8.0, 8.0 + 4.0 * h, sdm) ** 0.8
        z = np.maximum(step, slope)
        z = z * (0.92 + 0.16 * fbm(px, py, 700.0, 950 + sd, octaves=3))
        cone = isl_.get("cone")
        if cone is not None:
            cu, cv, ch, cr = cone
            u, v = local_frame(px, py, isl_)
            dc = np.sqrt((u - cu) ** 2 + (v - cv) ** 2)
            t = np.clip(1.0 - dc / cr, 0.0, 1.0)
            # con cu flancuri concave si varf stramt (Gusukuyama)
            zc = ch * t ** 1.6 * (0.92 + 0.08 * fbm(px, py, 90.0, 960 + sd, octaves=3))
            z = np.maximum(z, zc)
    elif k == "coast":
        beach_w = 18.0 + 30.0 * fbm(px, py, 300.0, 1000 + sd, octaves=2)
        rise = smoothstep(beach_w, beach_w + L * 0.5, sdm) ** 0.8
        hills = h * (0.45 + 0.55 * fbm(px, py, L * 0.6, 1010 + sd, octaves=5))
        z = 1.5 + (hills - 1.5) * rise
        # capuri de calcar: pe unele portiuni dealul cade direct in mare
        cape = smoothstep(0.64, 0.70, fbm(px, py, L * 0.5, 1020 + sd, octaves=2))
        z = np.maximum(z, cape * h * 0.30 * smoothstep(2.0, 2.0 + 0.10 * h, sdm))
    else:   # range
        s = np.clip(sdm / L, 0.0, 1.0)
        ridge = fbm(px, py, L * 0.5, 1100 + sd, octaves=5, ridged=True)
        z = h * (s ** 0.5) * (0.3 + 0.7 * ridge)
    return z


# --- Relieful: camp de inaltimi POLAR (ca pe Fiordland) -------------------------

N_AZ = 1024 if TEST else 4096
N_R = 140 if TEST else 440
R0, R1 = 450.0, 24000.0
SEA_FLOOR = -30.0


def eval_islands(px, py):
    """Pe fiecare punct: cota, insula castigatoare, distanta pana la cel mai
    apropiat tarm (maximul peste insule; negativ = in mare)."""
    z = np.full(px.shape, SEA_FLOOR)
    who = np.full(px.shape, -1, dtype=np.int32)
    sdm_best = np.full(px.shape, -1e9)
    for i, I in enumerate(ISLANDS):
        # cutia de incadrare: nu evalua zgomotul pe tot cercul
        ext = max(I["rx"], I["ry"]) * 1.7 + 400.0
        box = (np.abs(px - I["cx"]) < ext) & (np.abs(py - I["cy"]) < ext)
        if not box.any():
            continue
        bx, by = px[box], py[box]
        sdm = shore_dist(bx, by, I)
        zi = island_height(bx, by, I, sdm)
        zi = np.where(sdm > 0.0, zi, SEA_FLOOR)
        cur = z[box]
        better = zi > cur
        z[box] = np.where(better, zi, cur)
        who[box] = np.where(better, i, who[box])
        sdm_best[box] = np.maximum(sdm_best[box], sdm)
    return z, who, sdm_best


def polar_grid(n_az, n_r, r0, r1):
    az = np.linspace(0.0, math.tau, n_az, endpoint=False)
    rr = r0 * np.power(r1 / r0, np.linspace(0.0, 1.0, n_r))
    A, Rg = np.meshgrid(az, rr)                       # (n_r, n_az)
    return A, Rg, np.sin(A) * Rg, np.cos(A) * Rg


def grid_mesh(name, co, n_r, n_az):
    nverts = n_r * n_az
    ii, jj = np.meshgrid(np.arange(n_r - 1), np.arange(n_az), indexing="ij")
    j1 = (jj + 1) % n_az
    v0 = ii * n_az + jj
    v1 = ii * n_az + j1
    v2 = (ii + 1) * n_az + j1
    v3 = (ii + 1) * n_az + jj
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)   # normala in sus
    nf = (n_r - 1) * n_az
    me = bpy.data.meshes.new(name)
    me.vertices.add(nverts)
    me.vertices.foreach_set("co", co.astype(np.float32).ravel())
    me.loops.add(nf * 4)
    me.loops.foreach_set("vertex_index", quads.astype(np.int32))
    me.polygons.add(nf)
    me.polygons.foreach_set("loop_start", (np.arange(nf) * 4).astype(np.int32))
    me.polygons.foreach_set("loop_total", np.full(nf, 4, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    return me


def set_vcol(me, col):
    n = col.reshape(-1, 3).shape[0]
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((n, 1))], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())


# --- Materiale ------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def haze_wrap(nt, surface_socket, out_node, f0=None, d0=None):
    """surface -> amestec cu HAZE dupa distanta si cu MIST (aerul jos de pe mare)
    dupa inaltime; fac = 1 - (1 - F0) * exp(-(d - d0) / D), plafonat la HAZE_MAX."""
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
    x = math_node("SUBTRACT", d, vb=HAZE_D0 if d0 is None else d0)
    x = math_node("MAXIMUM", x, vb=0.0)
    # Spre soare aerul e mai gros la vedere (imprastiere inainte): insulele in
    # contre-jour ies mai palide, nu mai inchise decat cele luminate — altfel
    # adancimea se inverseaza fata de stancile 3D cetoase din fata (lectia de
    # pe Monument Valley). `FWD_K` = cat se lungeste drumul prin aer spre soare.
    sh = sun_dir_blender()
    sh.z = 0.0
    sh.normalize()
    rel = n.new("ShaderNodeVectorMath")
    rel.operation = "SUBTRACT"
    L.new(geo.outputs["Position"], rel.inputs[0])
    rel.inputs[1].default_value = (0.0, 0.0, CAM_Z)
    nrm = n.new("ShaderNodeVectorMath")
    nrm.operation = "NORMALIZE"
    L.new(rel.outputs[0], nrm.inputs[0])
    dot = n.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    L.new(nrm.outputs[0], dot.inputs[0])
    dot.inputs[1].default_value = (sh.x, sh.y, 0.0)
    fwd = math_node("MAXIMUM", dot.outputs["Value"], vb=0.0)
    fwd = math_node("POWER", fwd, vb=2.0)
    fwd = math_node("MULTIPLY", fwd, vb=FWD_K)
    fwd = math_node("ADD", fwd, vb=1.0)
    x = math_node("MULTIPLY", x, fwd)
    x = math_node("MULTIPLY", x, vb=-1.0 / HAZE_D)
    x = math_node("EXPONENT", x)
    keep_air = math_node("MULTIPLY", x, vb=1.0 - (HAZE_F0 if f0 is None else f0))
    keep_air = math_node("MAXIMUM", keep_air, vb=1.0 - HAZE_MAX)
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / MIST_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")                        # ceata doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 1200.0
    ramp.inputs["From Max"].default_value = 6000.0
    mist = math_node("MULTIPLY", z, ramp.outputs["Result"])
    mist = math_node("MULTIPLY", mist, vb=MIST_K)
    keep_mist = math_node("SUBTRACT", va=1.0, b=mist)
    keep = math_node("MULTIPLY", keep_air, keep_mist)
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(HAZE)
    cmix.inputs[7].default_value = srgb(MIST)
    L.new(mist, cmix.inputs[0])
    em = n.new("ShaderNodeEmission")
    L.new(cmix.outputs[2], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    mix = n.new("ShaderNodeMixShader")
    L.new(fac, mix.inputs[0])
    L.new(surface_socket, mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    L.new(mix.outputs[0], out_node.inputs["Surface"])


def vcol_lit_material(name, rough=0.85):
    """Culoarea in atributul `Col`, luminata de soare si ambient, spalata in aer."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    L.new(at.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def vcol_emit_material(name):
    """Marea: NEILUMINATA (ca la Ha Long / Fiordland), culoarea ei din vertex color."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    em = n.new("ShaderNodeEmission")
    L.new(at.outputs["Color"], em.inputs["Color"])
    # fara voal pe primul kilometru: marea jocului se spala spre CERUL din spatele
    # ei (`fog_aerial` 1.0), iar sub orizont cerul e chiar marea asta — daca ar fi
    # mai deschisa decat `below`, apa jocului s-ar termina intr-o dunga
    haze_wrap(nt, em.outputs[0], out, f0=0.0, d0=SEA_D0)
    return mat


def atlas_haze_material():
    mat, nt, out = new_material("BandAtlas")
    n, L = nt.nodes, nt.links
    tex = n.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS)
    tex.interpolation = "Closest"
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.8
    L.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


# --- Uscatul ------------------------------------------------------------------------

def build_land():
    A, Rg, px, py = polar_grid(N_AZ, N_R, R0, R1)
    z, who, sdm = eval_islands(px, py)
    # inelul interior coboara in apa: altfel marginea campului ar fi o streasina
    z = np.where(Rg < R0 + 60.0, np.minimum(z, SEA_FLOOR), z)
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    me = grid_mesh("BandLand", co, N_R, N_AZ)
    nrm = np.empty(N_R * N_AZ * 3, dtype=np.float32)
    me.vertex_normals.foreach_get("vector", nrm)
    nz = nrm.reshape(N_R, N_AZ, 3)[..., 2]

    hmax = np.array([I["h"] for I in ISLANDS] + [1.0])[who]
    kinds = np.array([I["kind"] for I in ISLANDS] + ["none"])[who]
    hfrac = np.clip(z / np.maximum(hmax, 1.0), 0.0, 1.3)

    # calcarul: dungi verticale de scurgere, nisa intunecata la nivelul marii
    streak = vnoise(px * 0.9 + py * 0.4, py * 0.9 - px * 0.4 + z * 0.02, 6.0, 41)
    streak = smoothstep(0.55, 0.9, streak)
    lit = smoothstep(0.15, 0.6, nz)
    rock = (lin(LIME)[None, None, :] * (1 - lit)[..., None]
            + lin(LIME_LIT)[None, None, :] * lit[..., None])
    rock = rock * (1 - 0.2 * streak)[..., None] + lin(LIME_DARK) * (0.2 * streak)[..., None]
    notch = smoothstep(9.0, 2.5, z) * smoothstep(0.75, 0.4, nz)
    rock = rock * (1 - notch)[..., None] + lin(LIME_NOTCH) * notch[..., None]

    # padurea: pe ce priveste in sus; pete de nuante (coroane in grup)
    fi = np.clip((fbm(px, py, 45.0, 71, octaves=2) * len(FOREST) * 1.25 - 0.6).astype(int),
                 0, len(FOREST) - 1)
    fcol = np.array([lin(c) for c in FOREST])[fi]
    flat = smoothstep(0.42, 0.68, nz)
    # pe faleza atarna verdeata (pandanus, liane): pete pe fetele mai putin
    # abrupte si sub buza de sus, ca braul de piatra sa nu fie un gard alb
    hang = smoothstep(0.45, 0.7, fbm(px, py + z * 1.5, 22.0, 75, octaves=3)) * smoothstep(-0.1, 0.35, nz)
    hang = np.maximum(hang, smoothstep(0.55, 0.9, hfrac) * 0.6)
    green = np.clip(flat + (1 - flat) * hang * 0.85, 0.0, 1.0)
    col = rock * (1 - green)[..., None] + fcol * green[..., None]

    # campurile de pe Ie (conul ramane impadurit)
    on_field = (kinds == "plateau") & (hfrac < 0.75)
    fld_i = np.clip((vnoise(px, py, 120.0, 81) * len(FIELD)).astype(int), 0, len(FIELD) - 1)
    fld = np.array([lin(c) for c in FIELD])[fld_i]
    hedge = smoothstep(0.42, 0.5, vnoise(px, py, 60.0, 83))
    wfield = flat * on_field * (1.0 - 0.5 * hedge)
    col = col * (1 - wfield)[..., None] + fld * wfield[..., None]
    # satele de pe coasta: pete de var si olane pe ce e jos si culcat
    village = (smoothstep(0.62, 0.70, fbm(px, py, 500.0, 91, octaves=2)) * (kinds == "coast")
               * smoothstep(60.0, 20.0, z) * flat)
    roof_i = np.clip((vnoise(px, py, 7.0, 93) * len(ROOF)).astype(int), 0, len(ROOF) - 1)
    roof = np.array([lin(c) for c in ROOF])[roof_i]
    vmask = village * smoothstep(0.35, 0.45, vnoise(px, py, 11.0, 95))
    col = col * (1 - vmask)[..., None] + roof * vmask[..., None]

    # plaja: jos, culcat, langa tarm
    beach = smoothstep(4.5, 1.8, z) * smoothstep(0.3, 0.6, nz)
    col = col * (1 - beach)[..., None] + lin(SAND) * beach[..., None]

    set_vcol(me, col)
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(vcol_lit_material("BandLand"))
    print("banda: relief %d x %d varfuri" % (N_R, N_AZ))
    for I in ISLANDS:
        print("banda: %-8s az %5.1f d %6.0f h %4.0f -> %.1f grade" % (
            I["kind"], I["az"], I["d"], I["h"], math.degrees(math.atan2(I["h"] - CAM_Z, I["d"]))))
    return px, py, z, nz, who, flat, Rg


# --- Marea ------------------------------------------------------------------------

def build_sea():
    """Grila polara la cota 0, colorata dupa distanta pana la cel mai apropiat
    tarm: turcoaz pe recif (mai verde langa mal), o dunga de spuma pe buza
    recifului, albastru adanc in larg; langa banda (0,4-1 km) culoarea pe care
    o are apa jocului spre marginea ei (SEA_NEAR)."""
    n_az, n_r = (512, 80) if TEST else (4096, 360)
    A, Rg, px, py = polar_grid(n_az, n_r, 30.0, 30000.0)
    _, who, sdm = eval_islands(px, py)
    # latimea recifului creste cu insula (recif de franjura, 60-200 m)
    rw_by = np.array([60.0 + 0.10 * min(I["rx"], I["ry"]) if I["kind"] != "range" else 0.0
                      for I in ISLANDS] + [80.0])
    # `who` e insula cu cota cea mai mare, care in mare e mereu -1: ia insula
    # cu tarmul cel mai apropiat prin a doua trecere (cutiile sunt mici)
    near_i = np.full(px.shape, len(ISLANDS))
    best = np.full(px.shape, -1e9)
    for i, I in enumerate(ISLANDS):
        ext = max(I["rx"], I["ry"]) * 1.7 + 400.0
        box = (np.abs(px - I["cx"]) < ext) & (np.abs(py - I["cy"]) < ext)
        if not box.any():
            continue
        s = shore_dist(px[box], py[box], I)
        upd = s > best[box]
        best[box] = np.where(upd, s, best[box])
        near_i[box] = np.where(upd, i, near_i[box])
    rw = rw_by[near_i] * (0.75 + 0.5 * fbm(px, py, 160.0, 301, octaves=3))
    rw = np.maximum(rw, 1.0)
    reef = smoothstep(-rw, -rw * 0.55, sdm) * (rw > 5.0)
    shore = smoothstep(-rw * 0.35, 0.0, sdm) * (rw > 5.0)
    foam = np.exp(-((sdm + rw * 0.95) / (5.0 + 0.004 * Rg)) ** 2) * 0.8 * (rw > 5.0)
    foam *= smoothstep(0.35, 0.6, fbm(px, py, 50.0, 303, octaves=2))
    # largul: langa banda SEA_NEAR, spre 3 km SEA_DEEP; pete lungi tangentiale
    near = smoothstep(2600.0, 600.0, Rg)
    base = (lin(SEA_DEEP)[None, None, :] * (1 - near)[..., None]
            + lin(SEA_NEAR)[None, None, :] * near[..., None])
    var = fbm(px * 0.5, py * 0.5, 220.0, 305, octaves=3) - 0.5
    base = base * (1.0 + 0.22 * var)[..., None]
    col = base * (1 - reef)[..., None] + lin(REEF) * reef[..., None]
    col = col * (1 - shore)[..., None] + lin(REEF_SHORE) * shore[..., None]
    col = col * (1 - foam)[..., None] + lin(FOAM) * foam[..., None]
    co = np.stack([px, py, np.zeros_like(px)], axis=-1).reshape(-1, 3)
    me = grid_mesh("BandSea", co, n_r, n_az)
    set_vcol(me, col)
    ob = bpy.data.objects.new("BandSea", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(vcol_emit_material("BandSea"))
    ob.visible_shadow = False


# --- Stancile-ciuperca --------------------------------------------------------------

def build_stacks(veg_pts):
    """Ca `tower()` de pe Ha Long, dar mai scund si cu nisa adanca: calcarul
    Ryukyu e ros la nivelul marii, iar boschetul de pe varf se revarsa."""
    import bmesh
    from mathutils import Vector, noise
    rng = np.random.default_rng(77)
    bm = bmesh.new()
    for az, d, h, r in STACKS:
        a = math.radians(az)
        cx, cy = math.sin(a) * d, math.cos(a) * d
        seed = float(rng.uniform(0, 100))
        segs, rings = 40, 22
        grid = []
        for i in range(rings + 1):
            t = i / rings
            zz = -3.0 + t * (h + 3.0)
            # ciuperca: gat ros (nisa) pana la ~30%, palaria lata sus, varf
            # aproape plat sub boschet
            prof = 0.42 + 0.58 * float(smoothstep(0.22, 0.62, t)) ** 1.5
            if t > 0.86:
                s2 = (t - 0.86) / 0.14
                prof *= math.sqrt(max(0.0, 1.0 - s2 * s2 * 0.75))
            ring = []
            for j in range(segs):
                ang = j / segs * math.tau
                ca_, sa_ = math.cos(ang), math.sin(ang)
                lobe = noise.noise(Vector((ca_ * 1.3 + seed, sa_ * 1.3, t * 2.0)))
                flute = noise.noise(Vector((ca_ * 6.0, sa_ * 6.0 + seed, t * h / 6.0)))
                rr = r * prof * (1.0 + 0.30 * lobe + 0.07 * flute)
                ring.append(bm.verts.new((cx + ca_ * rr, cy + sa_ * rr, zz)))
            grid.append(ring)
        top = bm.verts.new((cx, cy, h + 0.8))
        for i in range(rings):
            for j in range(segs):
                k = (j + 1) % segs
                bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j]))
        for j in range(segs):
            bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], top))
        # boschetul de pe varf
        # boschetul de pe varf trece peste buza: de departe stanca e o ciuperca
        # verde pe un picior de piatra, nu un bloc alb (de la 0,7 km un bloc
        # alb luminat se citea ca hotel la capatul drumului)
        for _ in range(int(r * r * 0.7)):
            ang = float(rng.uniform(0, math.tau))
            rad = r * 1.02 * math.sqrt(float(rng.uniform(0, 1)))
            veg_pts.append(((cx + math.cos(ang) * rad, cy + math.sin(ang) * rad,
                             h * (0.90 + 0.06 * float(rng.uniform()))), float(rng.uniform(2.6, 4.4))))
        print("banda: stanca az %.0f d %.0f h %.0f -> %.1f grade" % (
            az, d, h, math.degrees(math.atan2(h - CAM_Z, d))))
    me = bpy.data.meshes.new("BandStacks")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    zs = np.array([v.co.z for v in me.vertices])
    notch = smoothstep(7.0, 1.0, zs)
    col = lin(LIME)[None, :] * (1 - notch)[:, None] + lin(LIME_NOTCH)[None, :] * notch[:, None]
    set_vcol(me, col)
    ob = bpy.data.objects.new("BandStacks", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(vcol_lit_material("BandStacks", rough=0.95))


# --- Coroanele (doar pe primul plan: acolo padurea are silueta de coroane) -------

def scatter_crowns(px, py, z, nz, who, flat, Rg, veg_pts):
    rng = np.random.default_rng(99)
    near = (Rg < 1400.0) & (z > 6.0) & (flat > 0.6) & (who >= 0)
    idx = np.nonzero(near.ravel())[0]
    # densitate pe aria celulei: ~1 coroana la 45 m2
    r = Rg.ravel()[idx]
    cell = (math.tau * r / N_AZ) * (r * (math.log(R1 / R0) / (N_R - 1)))
    keep = rng.uniform(size=idx.size) < np.clip(cell / 45.0, 0.0, 1.0)
    idx = idx[keep]
    xs, ys, zs = px.ravel()[idx], py.ravel()[idx], z.ravel()[idx]
    sizes = rng.uniform(3.2, 6.0, size=idx.size)
    for k in range(idx.size):
        veg_pts.append(((float(xs[k]), float(ys[k]), float(zs[k] + sizes[k] * 0.25)),
                        float(sizes[k])))
    print("banda: %d coroane (cu boschetii stancilor)" % len(veg_pts))


def build_crowns(points):
    import bmesh
    from mathutils import Vector, noise
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    for v in bm.verts:
        k = 1.0 + 0.25 * noise.noise(v.co * 2.3)
        v.co = Vector((v.co.x * k, v.co.y * k, v.co.z * k * 0.7))
    me = bpy.data.meshes.new("BandCrown")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    crown = bpy.data.objects.new("BandCrown", me)
    bpy.context.collection.objects.link(crown)
    mat, nt, out = new_material("BandCrownMat")
    n, L = nt.nodes, nt.links
    oi = n.new("ShaderNodeObjectInfo")
    cr = n.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    els[0].position, els[0].color = 0.0, srgb(FOREST[2])
    els[1].position, els[1].color = 1.0, srgb(FOREST[3])
    for i, c in enumerate((FOREST[0], FOREST[4], FOREST[1])):
        e = els.new(0.25 + 0.25 * i)
        e.color = srgb(c)
    L.new(oi.outputs["Random"], cr.inputs["Fac"])
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    L.new(cr.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    crown.data.materials.append(mat)
    crown.hide_render = True
    crown.location = (0, 0, -500)

    rng = np.random.default_rng(5)
    pm = bpy.data.meshes.new("BandVegPts")
    pm.vertices.add(len(points))
    pm.vertices.foreach_set("co", [c for p, _ in points for c in p])
    sc = pm.attributes.new("vscale", "FLOAT_VECTOR", "POINT")
    sc.data.foreach_set("vector", [c for _, s in points
                                   for c in (s, s * float(rng.uniform(0.85, 1.15)), s * 0.9)])
    rt = pm.attributes.new("vrot", "FLOAT_VECTOR", "POINT")
    rt.data.foreach_set("vector", [c for _ in points
                                   for c in (0.0, 0.0, float(rng.uniform(0, math.tau)))])
    ob = bpy.data.objects.new("BandVeg", pm)
    bpy.context.collection.objects.link(ob)
    ng = bpy.data.node_groups.new("BandVegScatter", "GeometryNodeTree")
    ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    gi = ng.nodes.new("NodeGroupInput")
    go = ng.nodes.new("NodeGroupOutput")
    m2p = ng.nodes.new("GeometryNodeMeshToPoints")
    iop = ng.nodes.new("GeometryNodeInstanceOnPoints")
    oin = ng.nodes.new("GeometryNodeObjectInfo")
    oin.inputs["Object"].default_value = crown
    a_sc = ng.nodes.new("GeometryNodeInputNamedAttribute")
    a_sc.data_type = "FLOAT_VECTOR"
    a_sc.inputs["Name"].default_value = "vscale"
    a_rt = ng.nodes.new("GeometryNodeInputNamedAttribute")
    a_rt.data_type = "FLOAT_VECTOR"
    a_rt.inputs["Name"].default_value = "vrot"
    L = ng.links
    L.new(gi.outputs[0], m2p.inputs["Mesh"])
    L.new(m2p.outputs["Points"], iop.inputs["Points"])
    L.new(oin.outputs["Geometry"], iop.inputs["Instance"])
    L.new(a_sc.outputs["Attribute"], iop.inputs["Scale"])
    L.new(a_rt.outputs["Attribute"], iop.inputs["Rotation"])
    L.new(iop.outputs["Instances"], go.inputs[0])
    mod = ob.modifiers.new("Scatter", "NODES")
    mod.node_group = ng


# --- Barcile (din kitul pistei) ------------------------------------------------------

BOATS = [
    # (fisier, busola, distanta, cap fata de tangenta (grade))
    ("okinawa/vehicles/island_ferry.glb", 166.0, 1500.0, 15.0),
    ("okinawa/vehicles/fishing_boat.glb", 198.0, 620.0, 70.0),
    ("okinawa/vehicles/fishing_boat.glb", 262.0, 900.0, -40.0),
    ("okinawa/vehicles/fishing_boat.glb", 84.0, 700.0, 120.0),
    ("okinawa/vehicles/fishing_boat.glb", 330.0, 1300.0, 10.0),
    ("okinawa/vehicles/coastal_freighter.glb", 150.0, 5200.0, -5.0),
    ("okinawa/vehicles/coastal_freighter.glb", 288.0, 7000.0, 8.0),
]


def import_joined(path):
    before = set(o.name for o in bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o.name not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        o.data.materials.clear()
    names = [o.name for o in new]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for nm in names:
        o = bpy.data.objects.get(nm)
        if o is not None and o != ob:
            bpy.data.objects.remove(o, do_unlink=True)
    return ob


def build_boats():
    mat = atlas_haze_material()
    proto = {}
    for fn, az, d, head in BOATS:
        path = os.path.join(MODELS, *fn.split("/"))
        if not os.path.exists(path):
            print("LIPSA: " + path)
            continue
        if fn not in proto:
            o = import_joined(path)
            o.data.materials.append(mat)
            proto[fn] = o
        else:
            o = proto[fn].copy()
            bpy.context.collection.objects.link(o)
        a = math.radians(az)
        o.location = (math.sin(a) * d, math.cos(a) * d, -0.3)
        # capul e relativ la tangenta cercului; la 1 km sensul exact nu se citeste
        o.rotation_euler = (0.0, 0.0, -a + math.radians(90.0 + head))


# --- Lumina, camera ----------------------------------------------------------------

def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    from mathutils import Vector
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
    cd.clip_end = 60000.0
    cam = bpy.data.objects.new("BandCam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, 0.0, CAM_Z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # priveste spre +Y (nord)
    sc.camera = cam

    ld = bpy.data.lights.new("BandSun", "SUN")
    ld.energy = SUN_STRENGTH
    ld.color = srgb(SUN_COLOR)[:3]
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
build_sea()
land = build_land()
veg = []
build_stacks(veg)
if not TEST:
    scatter_crowns(*land, veg)
if veg:
    build_crowns(veg)
build_boats()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
