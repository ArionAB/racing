"""Banda de orizont a cerului San Francisco (Track25) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/sanfrancisco_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15),
cu alfa: golful rece si albastru-inchis la ora aurie, dealurile orasului acoperite
de case victoriene pastel pe grila de strazi care urca drept peste ele, dealurile
goale auriu-verzi din Marin dincolo de golf (cu Mount Tamalpais departe, albastrui),
Angel Island verde-auriu in golf, East Bay (dealurile Berkeley / Oakland, maro-aurii,
cu orasul plat la poale) peste apa spre est, cateva veliere mici. Cerul ramane
TRANSPARENT: gradientul lui il deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`).

Ce NU e in banda, dinadins (sunt repere 3D ale pistei):
  * PODUL ROSU. E carosabil (Track25, `Pod`), deci nu se picteaza al doilea pod.
  * INSULA CU FAR (Alcatraz) din axul lantului, la ~80 m de tarm (`DecorManual/Insula`).
  * Tramvaiele, strada lantului, casele pictate, magaziile de chei, barcile pe bucle.
  * Ceata ca vreme (bancul de ceata de pe Golden Gate): decizia dezvoltatorului,
    „fara ceata” (doar pacla subtire de distanta a temei).

Reteta e cea de pe Ha Long / Monument Valley / Kyoto (camp de inaltimi polar in
numpy + o plasa de cladiri + marea ca plan emisiv, ca pe Stromboli). Specific aici:

  * ORASUL se coloreaza in SHADER, casa cu casa: o grila de strazi N-S / E-V
    (`STREET_PITCH`, aliniata ca strada lantului, care coboara spre nord) desparte
    cvartale, iar in cvartal celule de ~8 m sunt case, fiecare cu tenta ei din
    cele cinci pasteluri ale kitului (crem, roz, albastru-pudra, menta, unt) si
    cate un acoperis gri-inchis. Strazile urca drept peste dealuri, ca in oras.
    Aproape (< `TOWN_R`) casele sunt si GEOMETRIE (cutii cu acoperis), ca muchia
    dealului sa aiba silueta de case in trepte, nu de pajiste.
  * Planul 0 (`NEAR_GIANTS`): dealuri APROPIATE (0,58-0,85 km) pe directiile in
    care priveste camera pe portiunile lungi (sonda pe Track25.baked): dealuri de
    oras cu case la S/V, dealurile aurii ale malului celalalt la E. Spre N e golful:
    acolo planul apropiat e Angel Island si capul Marin.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste mare, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "sanfrancisco" (`sun_rotation_deg` (-28, -12, 0), acelasi in
    Track25.tscn: din S-SV, 28 de grade), `sun_color` FFD2A0, energia 1,25;
    ambientul BCCCE8 la 0,32;
  * HAZE = `sky_horizon` din tema (EAE2D2): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_sanfrancisco_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import math
import os
import random
import sys

import numpy as np
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Ochiul: soseaua sta la +3 (cheiul) .. +53 (coama), podul la +20, camera de joc cu
# ~10 m mai sus. 30 e mijlocul; la kilometri diferenta e sub un grad. -7,5 grade
# cade pe apa la ~230 m: banda incepe sub marginea lumii jocului.
CAM_Z = 30.0
SAMPLES = 16 if TEST else 160
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "sanfrancisco_horizon_band_test.png" if TEST
                   else "sanfrancisco_horizon_band.png")


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


# --- Paleta (sRGB, ca in tema / kit) -------------------------------------------
HAZE = "EAE2D2"          # = sky_horizon din tema
# Golful: apa rece si inchisa a jocului (SEA_DEEP, nu turcoaz). SEA = randul de jos
# (apa jocului la ~300 m, masurata pe captura), SEA_FAR = spre orizont marea prinde
# cerul (Fresnel) si se deschide.
SEA = "7E95A0"
SEA_FAR = "C4CBCA"
# Iarba uscata aurie a dealurilor (DRY_VEGETATION, `ground_tint` 0.80/0.70/0.45 al
# temei, `hill_color` 0.70/0.60/0.38) si verdele inchis al tufarisului / stejarilor
# de pe coastele de nord si din ravene (chaparral, Marin).
GOLD = ["C8AE58", "BBA14E", "D0B864", "AE9644"]
SCRUB = ["5E6A3C", "6B7444", "515E35", "77784A"]
OAK = "3F4E2E"           # stejari / eucalipti in ravene (mai inchis)
CYPRESS = "2E3F2A"       # chiparosii / padurea Presidio
ROCK = "8E7F6A"          # faleza de gresie a capului Marin
BEACH = "D8CBA8"
# Cele cinci pasteluri ale scandurii (kitul caselor, preview_sf_row.py PASTELS) +
# albul ancadramentelor si griul inchis al acoperisurilor (brief §5).
PASTELS = ["EFE3C2", "E8B7B0", "B4C6DA", "B9D6BE", "EDD68A"]
WHITE = "F2EEE6"
WINDOW = "3E4652"         # geamurile (inchise, reci)
ROOF = "585A5E"
ROOF_B = "6A6662"
STREET = "6E6C6A"        # asfaltul strazilor, vazut de departe (cu trotuarele)
PARK = "6F7C48"          # gazonul parcurilor de cartier
TOWER = ["D9D2C2", "BFC3C2", "A9B2B8", "CFC6B4"]   # turnuri generice, piatra / sticla
SAIL = "F4F1EA"
HULL = "E8E4DA"
SUN_COLOR = "FFD2A0"
# Godot inmulteste energia luminii cu pi (alb lambertian perpendicular = energia);
# Cycles nu. Deci taria Cycles = pi x energia temei (ca la Monument Valley).
SUN_STRENGTH = math.pi * 1.25
AMBIENT = "BCCCE8"
AMBIENT_ENERGY = 0.32
SUN_ROT = (-28.0, -12.0)                 # sun_rotation_deg (x, y) din tema
# Umplere din partea opusa soarelui: lumina intoarsa de golf / oras. Fara ea
# coastele din contre-jour (spre S, soarele in spate) ies negre.
FILL_COLOR = "E8E0D0"
FILL_AZ, FILL_STRENGTH = 10.0, 0.7

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului (360) incolo; F0 = cat a spalat deja pacla jocului acolo. Pacla temei e
# SUBTIRE (fog_max 0,40), seara limpede: Marin la 3 km iese clar, East Bay la 12 km
# pe jumatate in aer, Tamalpais albastrui.
HAZE_D0, HAZE_D, HAZE_F0 = 360.0, 11000.0, 0.12
HAZE_MAX = 0.80
# Fara ceata joasa (decizia „fara ceata”): doar o pacla subtire peste apa, departe.
MIST_H, MIST_K = 40.0, 0.18
MIST_R0, MIST_R1, MIST_NEAR = 2000.0, 12000.0, 0.0


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


def h_for(d, theta_deg):
    """Inaltimea (peste nivelul marii) care sta la `theta_deg` peste ochi la d."""
    return CAM_Z + d * math.tan(math.radians(theta_deg))


def polar(az_deg, d):
    a = math.radians(az_deg)
    return math.sin(a) * d, math.cos(a) * d      # Blender: x est, y nord


def angdiff(a, b):
    """Diferenta de azimut a - b, in (-180, 180]."""
    return (a - b + 180.0) % 360.0 - 180.0


# --- Geografia (busola JOCULUI: N = 0 = -Z Godot, E = 90 = +X) -------------------
#
# Pista e pe malul de nord al orasului (cheiul la N, golful la N si E, stramtoarea
# podului la E, malul celalalt cu dealuri aurii dincolo de pod). Banda pune in jur
# locul real, rotit ca pista: orasul pe dealuri la S si V, poarta spre ocean la NV
# (fara pod: podul e 3D, pe pista), Marin la N-NV peste golf, Angel Island la N-NE,
# East Bay la E peste golf, in spatele malului celalalt.
#
# Uscatul: (nume, az_min, az_max, tarmul [(az, r)], capatul [(az, r)], fel). Tarmul
# e la r_tarm (interpolat pe azimut, cu zimti), uscatul tine pana la r_capat
# (dincolo, apa). Intre 300 si 310 nu e nimic: poarta spre ocean (fara pod: podul
# rosu e 3D, pe pista).
LANDS = [
    # orasul: de la marginea lumii jocului pana la ocean (Ocean Beach, ~7 km la V);
    # la S-SV un golf de ~0,7 km in fata (stramtoarea de sub pod continua spre S:
    # de pe intoarcerea-balon privirea trece peste apa spre oras)
    ("oras", 124.0, 300.0,
     [(124.0, 0.0), (150.0, 0.0), (168.0, 650.0), (222.0, 760.0), (240.0, 0.0), (300.0, 0.0)],
     [(124.0, 20000.0), (230.0, 20000.0), (255.0, 8000.0), (300.0, 6000.0)], "city"),
    # malul celalalt al stramtorii (dealurile aurii ale intoarcerii-balon), apoi golf
    ("malul", 38.0, 134.0, [(38.0, 0.0), (134.0, 0.0)],
     [(38.0, 250.0), (58.0, 1100.0), (90.0, 1500.0), (134.0, 1700.0)], "gold"),
    # Marin: capul cu faleze la NV, Sausalito, Tiburon / Belvedere spre N
    ("marin", 310.0, 378.0,
     [(310.0, 2300.0), (322.0, 2400.0), (345.0, 2900.0), (378.0, 4000.0)],
     [(310.0, 40000.0), (378.0, 40000.0)], "marin"),
    # East Bay: Richmond, Berkeley, Oakland, peste golf
    ("eastbay", 18.0, 140.0, [(18.0, 9500.0), (80.0, 10500.0), (140.0, 11500.0)],
     [(18.0, 40000.0), (140.0, 40000.0)], "eastbay"),
]
# Insule (busola, distanta, raza x (tangent), raza y (radial), inaltime, fel)
ISLES = [
    ("angel", 24.0, 1900.0, 620.0, 430.0, 230.0, "angel"),
    ("yerba", 104.0, 5200.0, 420.0, 300.0, 110.0, "angel"),
]

# Planul 0, pus de mana: (azimut busola, distanta, unghi varf peste ochi, R/h, fel).
# Azimuturile vin din sonda pe Track25.baked (camera de joc), vezi tema. Directiile
# camerei pe portiunile lungi: V 270 (podul spre oras de la start 0,00-0,11, coama
# 0,28-0,31 la 63 m, terasa 0,50-0,53), N 0 (lantul 0,34-0,48, privit in jos: cerul
# abia se vede; 0,54-0,58 spre chei), E 90 (cheiul 0,60-0,69 la 13 m, podul spre
# larg 0,78-0,90), S 180 (urcarea 0,15-0,26 si 0,72-0,76, intre case: cer putin),
# intoarcerea-balon 0,92-0,98 (80, 217, 274). Uriasii stau la 10-16 grade de axe.
# Spre N e golful: acolo planul apropiat e Angel Island (ISLES) si capul Marin.
NEAR_GIANTS = [
    (256.0, 640.0, 6.0, 3.5, "city"),    # V, stanga podului / coamei
    (285.0, 720.0, 5.0, 3.6, "city"),    # V-NV, dreapta lor (spre Presidio)
    (162.0, 720.0, 5.0, 3.5, "city"),    # S, stanga urcarii
    (199.0, 1150.0, 4.5, 3.0, "city"),   # S-SV, dincolo de golful din fata balonului
    (238.0, 1200.0, 4.0, 3.2, "city"),   # (balonul priveste spre 217: centrul intre ei)
    # E: de pe chei podul 3D sta la 110-135, deci uriasii raman la stanga lui
    (72.0, 760.0, 4.8, 3.6, "gold"),     # E, stanga podului spre larg / a cheiului
    (99.0, 700.0, 5.2, 3.4, "gold"),     # E, dreapta lor
]

# Dealurile din planurile 1-3: (az_min, az_max, d_min, d_max, theta_min, theta_max,
# pas de azimut min/max, R/h min/max, fel).
HILL_BANDS = [
    # dealurile orasului (Pacific Heights, Nob, Twin Peaks...), tot mai joase spre ocean
    (145.0, 300.0, 1000.0, 2200.0, 2.0, 4.0, 9.0, 16.0, 3.0, 4.5, "city"),
    (140.0, 290.0, 2400.0, 5000.0, 1.0, 2.4, 10.0, 18.0, 3.5, 5.0, "city"),
    # malul celalalt, dealuri aurii joase in spatele uriasilor
    (54.0, 126.0, 900.0, 1300.0, 2.5, 4.0, 8.0, 14.0, 3.4, 4.4, "gold"),
    # capul Marin: dealuri goale si abrupte, cad in golf cu faleza
    (310.0, 345.0, 2900.0, 3800.0, 4.2, 5.8, 5.0, 8.0, 2.0, 2.6, "marin"),
    (340.0, 378.0, 4300.0, 6000.0, 2.6, 3.8, 6.0, 10.0, 2.4, 3.2, "marin"),
    (300.0, 380.0, 7000.0, 11000.0, 1.8, 3.0, 7.0, 12.0, 2.6, 3.6, "marin"),
    # East Bay: dealurile Berkeley / Oakland, maro-aurii, peste golf
    (18.0, 140.0, 12500.0, 16000.0, 1.3, 2.2, 6.0, 12.0, 3.5, 5.0, "eastbay"),
]
# Twin Peaks (doua varfuri ierboase) si Mount Tamalpais (albastrui, departe)
TWIN = [(218.0, 4600.0, 3.1, 2.2), (223.0, 4700.0, 3.0, 2.2)]
TAM = (334.0, 14500.0, 3.0, 4.2)
# Centrul: turnuri GENERICE, modeste (fara piramida, fara repere cu nume)
DOWNTOWN = (218.0, 2500.0, 9.0, 650.0)    # busola, distanta, latime (grade), adancime m
# Orasul geometric (cutii cu acoperis) pana la TOWN_R; dincolo il da shaderul.
TOWN_R = 2300.0
STREET_PITCH = (96.0, 128.0)              # pasul grilei: N-S, E-V (m)
STREET_W = 16.0
# Veliere: (busola, distanta, cap) pe golf, departe de reperele 3D
SAILS = [(338.0, 1500.0, 70.0), (8.0, 1100.0, 250.0), (44.0, 2600.0, 120.0),
         (318.0, 2300.0, 20.0), (58.0, 4200.0, 300.0), (352.0, 2800.0, 200.0)]


def hill(hills, rng, x, y, h, R, a, b, kind, sats=(1, 2)):
    """Un deal + 1-2 umeri lipiti de el, intinsi de-a CURMEZISUL privirii (o
    creasta lunga, nu o movila rotunda pusa singura)."""
    tang = math.atan2(-x, y)
    hills.append((x, y, h, R, a, b, kind, tang + rng.uniform(-0.35, 0.35),
                  rng.uniform(0.45, 0.70)))
    for _ in range(rng.randint(*sats)):
        ang = tang + rng.choice((0.0, math.pi)) + rng.uniform(-0.5, 0.5)
        off = R * rng.uniform(0.45, 0.85)
        f = rng.uniform(0.55, 0.85)
        hills.append((x + math.cos(ang) * off, y + math.sin(ang) * off, h * f,
                      R * f * rng.uniform(0.85, 1.1), a * rng.uniform(0.9, 1.1), b,
                      kind, tang + rng.uniform(-0.5, 0.5), rng.uniform(0.45, 0.8)))


def make_hills(rng):
    hills = []
    for az, d, th, rk, kind in NEAR_GIANTS:
        x, y = polar(az, d)
        h = h_for(d, th)
        hill(hills, rng, x, y, h, h * rk, 2.0, 1.5, kind)
    for (a0, a1, d0, d1, t0, t1, s0, s1, r0, r1, kind) in HILL_BANDS:
        az = a0 + rng.uniform(0.0, s0)
        while az < a1:
            d = rng.uniform(d0, d1)
            th = rng.uniform(t0, t1)
            h = h_for(d, th)
            x, y = polar(az % 360.0, d)
            hill(hills, rng, x, y, h, h * rng.uniform(r0, r1), rng.uniform(1.7, 2.4),
                 rng.uniform(1.2, 1.6), kind)
            az += rng.uniform(s0, s1)
    for az, d, th, rk in TWIN:
        x, y = polar(az, d)
        h = h_for(d, th)
        hills.append((x, y, h, h * rk, 1.6, 1.3, "twin", 0.0, 0.8))
    # insulele: un deal rotund cat insula (Angel: Mount Livermore, 240 m)
    for name, az, d, rx, ry, h, k in ISLES:
        x, y = polar(az, d)
        hills.append((x, y, h, max(rx, ry) * 0.95, 1.8, 1.3, k, math.atan2(-x, y),
                      ry / rx))
    az, d, th, rk = TAM
    x, y = polar(az, d)
    hill(hills, rng, x, y, h_for(d, th), h_for(d, th) * rk, 1.7, 1.4, "marin", sats=(2, 3))
    return hills


KINDS = {"city": 0, "gold": 1, "marin": 2, "eastbay": 3, "angel": 4, "twin": 5}


# --- Uscatul si relieful: camp de inaltimi polar -----------------------------------

N_AZ = 1024 if TEST else 4096
N_R = 140 if TEST else 480
R0, R1 = 200.0, 42000.0
SEA_Z = 0.0


def land_mask(px, py):
    """1 pe uscat, 0 pe apa; `kind` = felul uscatului (indice in KINDS)."""
    r = np.hypot(px, py)
    az = np.degrees(np.arctan2(px, py)) % 360.0
    land = np.zeros(px.shape)
    kind = np.zeros(px.shape, dtype=np.int32)
    wob = fbm(px, py, 700.0, 5, octaves=4) - 0.5
    for name, a0, a1, shore, far, k in LANDS:
        span = a1 - a0
        off = (az - a0) % 360.0
        inside = off <= span
        # capetele sectorului: tarm moale pe ~3 grade, nu taiat cu cutitul
        edge = np.minimum(off, span - off)
        soft = smoothstep(0.0, 3.0 if k == "marin" else 8.0, edge) * inside
        sa = np.array([p[0] - a0 for p in shore])
        rshore = np.interp(off, sa, np.array([p[1] for p in shore]))
        rshore = rshore * (1.0 + 0.18 * wob)
        fa = np.array([p[0] - a0 for p in far])
        rfar = np.interp(off, fa, np.array([p[1] for p in far])) * (1.0 + 0.10 * wob)
        # tarmul: abrupt doar la capul Marin (faleze); in rest dealurile coboara
        # domol in apa, pe ~300 m (altfel muchia taiata citea a mesa de desert)
        sw = 60.0 if k == "marin" else 300.0
        m = soft * smoothstep(rshore - sw, rshore + sw, r) * smoothstep(rfar + sw, rfar - sw, r)
        m = np.where(rshore < 1.0, soft * smoothstep(rfar + sw, rfar - sw, r), m)
        better = m > land
        land = np.where(better, m, land)
        kind = np.where(better, KINDS.get(k, 1), kind)
    for name, az0, d, rx, ry, h, k in ISLES:
        cx, cy = polar(az0, d)
        ey = np.array(polar(az0, 1.0))
        ex = np.array([ey[1], -ey[0]])
        lx = (px - cx) * ex[0] + (py - cy) * ex[1]
        ly = (px - cx) * ey[0] + (py - cy) * ey[1]
        ang = np.arctan2(ly, lx)
        rr = np.hypot(lx / rx, ly / ry) * (1.0 + 0.22 * (vnoise(np.cos(ang) * 3 + d, np.sin(ang) * 3, 1.0, 77) - 0.5))
        m = smoothstep(1.06, 0.94, rr)
        better = m > land
        land = np.where(better, m, land)
        kind = np.where(better, KINDS[k], kind)
    return land, kind


def heights(px, py, hills):
    land, kind = land_mask(px, py)
    # uscatul de baza: urca usor de la tarm (6 m) spre interior, cu valuri lungi
    r = np.hypot(px, py)
    base = 6.0 + 18.0 * fbm(px, py, 1800.0, 9, octaves=3)
    z = base.copy()
    hk = np.full(px.shape, -1, dtype=np.int32)
    hm = np.full(px.shape, 1.0)
    gul = np.zeros(px.shape)
    for i, (x0, y0, h, R, pa, pb, k, rot, ecc) in enumerate(hills):
        m = (np.abs(px - x0) < R * 1.3) & (np.abs(py - y0) < R * 1.3)
        if not m.any():
            continue
        qx, qy = px[m], py[m]
        dx, dy = qx - x0, qy - y0
        ex = dx * math.cos(rot) + dy * math.sin(rot)
        ey = (-dx * math.sin(rot) + dy * math.cos(rot)) / ecc
        rr = np.hypot(ex, ey)
        ang = np.arctan2(dy, dx)
        lobe = (vnoise(np.cos(ang) * 2.5 + i * 7.1, np.sin(ang) * 2.5, 1.0, 900 + i) - 0.5)
        s = np.clip(rr / (R * (1.0 + 0.30 * lobe)), 0.0, 1.0)
        zk = h * np.power(1.0 - np.power(s, pa), pb)
        jag = fbm(qx, qy, R * 0.5, 2000 + i, octaves=3, ridged=True)
        zk = zk + (jag - 0.45) * 0.10 * h * np.sqrt(np.clip(1.0 - s, 0.0, 1.0)) * s * 2.0
        # ravene RADIALE: de la creasta spre poale (pe dealurile goale din Marin
        # tufele si stejarii stau in firul lor, in dungi pe panta, nu in pete)
        arc = ang * R / 70.0
        gk = fbm(arc + i * 13.7, s * 3.0, 1.0, 3000 + i, octaves=3, ridged=True)
        gk = gk * smoothstep(0.12, 0.35, s) * smoothstep(1.0, 0.75, s)
        zk = zk * (1.0 - 0.035 * smoothstep(0.5, 0.9, gk))
        better = zk > z[m]
        z[m] = np.where(better, zk, z[m])
        hk[m] = np.where(better, KINDS.get(k, 1), hk[m])
        hm[m] = np.where(better, h, hm[m])
        gul[m] = np.where(better, gk, gul[m])
    # ravene fine pe dealurile goale (Marin, East Bay): zgomot ridged
    rid = fbm(px, py, 220.0, 18, octaves=4, ridged=True)
    z += (rid - 0.45) * 0.12 * np.maximum(z - 8.0, 0.0)
    # tarmul: uscatul coboara sub apa; la Marin cu faleza (tarm abrupt)
    pw = np.where(kind == KINDS["marin"], 0.5, 1.0)
    z = SEA_Z - 12.0 + (z + 12.0) * np.power(land, pw)
    kind = np.where(hk >= 0, np.where(land > 0.5, np.where(kind == KINDS["city"], hk, kind), kind), kind)
    # un deal de oras ramane oras; un deal auriu pe sectorul orasului e tot oras
    return z, land, kind, hm, gul


def build_land(hills):
    az = np.linspace(0.0, math.tau, N_AZ, endpoint=False)
    rr = R0 * np.power(R1 / R0, np.linspace(0.0, 1.0, N_R))
    A, Rg = np.meshgrid(az, rr)
    px = np.sin(A) * Rg
    py = np.cos(A) * Rg
    z, land, kind, hm, gul = heights(px, py, hills)
    nverts = N_R * N_AZ
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(N_R - 1), np.arange(N_AZ), indexing="ij")
    j1 = (jj + 1) % N_AZ
    quads = np.stack([ii * N_AZ + jj, ii * N_AZ + j1, (ii + 1) * N_AZ + j1,
                      (ii + 1) * N_AZ + jj], axis=-1).reshape(-1)
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
    # cat de mult priveste coasta spre nord (umbra, umezeala: chaparral verde)
    north = np.clip(nrm[..., 1], -1.0, 1.0)

    col = land_colors(px, py, z, nz, north, kind, gul)
    # orasul: unde uscatul e de oras si nu e prea abrupt (faleza) si nu e varf gol
    city = (kind == KINDS["city"]).astype(np.float64) * smoothstep(0.5, 0.9, land)
    city = city * smoothstep(0.55, 0.8, nz) * smoothstep(4.0, 9.0, z)
    # primele sute de metri sunt iarba aurie, ca terenul jocului la marginea lumii
    city = city * smoothstep(430.0, 650.0, np.hypot(px, py))
    # parcuri / crestele goale ale dealurilor de oras (Twin Peaks e tot iarba)
    bald = smoothstep(0.55, 0.75, fbm(px, py, 650.0, 61, octaves=3))
    city = city * (1.0 - 0.85 * bald * smoothstep(0.55, 0.95, z / np.maximum(hm, 1.0)))
    # orasele de pe malul opus (Sausalito, Tiburon, Berkeley / Oakland la poale)
    town = np.zeros_like(city)
    shore_low = smoothstep(90.0, 30.0, z) * smoothstep(4.0, 8.0, z) * smoothstep(0.55, 0.8, nz)
    for k, amt in (("eastbay", 0.95), ("marin", 0.55)):
        sel = (kind == KINDS[k]).astype(np.float64)
        patch = smoothstep(0.42, 0.62, fbm(px, py, 900.0, 66 + KINDS[k], octaves=3))
        town = np.maximum(town, sel * shore_low * patch * amt)
    city = np.maximum(city, town)
    # arborii (stejari, eucalipti, chiparosi, tufele de coyote brush): in ravene si
    # pe coastele de nord, in palcuri; Angel Island si Presidio impadurite pe poale
    rav = smoothstep(0.45, 0.85, gul)
    grove = smoothstep(0.55, 0.75, fbm(px, py, 300.0, 47, octaves=3))
    trees = np.clip(0.85 * rav + 0.10 * grove + 0.20 * smoothstep(0.0, 0.4, north), 0.0, 0.9)
    trees = 0.6 * trees
    angel = (kind == KINDS["angel"]).astype(np.float64)
    trees = np.maximum(trees, angel * smoothstep(170.0, 70.0, z) * 0.85)
    az_d = np.degrees(np.arctan2(px, py)) % 360.0
    rr = np.hypot(px, py)
    presidio = smoothstep(10.0, 6.0, np.abs((az_d - 293.0 + 180.0) % 360.0 - 180.0)) * smoothstep(1100.0, 1500.0, rr) * smoothstep(4500.0, 3800.0, rr)
    trees = np.maximum(trees, presidio * 0.9)
    trees = trees * smoothstep(3.0, 8.0, z) * (1.0 - city)
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((nverts, 1))], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    at = me.attributes.new("city", "FLOAT", "POINT")
    at.data.foreach_set("value", city.astype(np.float32).ravel())
    at = me.attributes.new("trees", "FLOAT", "POINT")
    at.data.foreach_set("value", trees.astype(np.float32).ravel())
    me.polygons.foreach_set("use_smooth", np.ones(nf, dtype=bool))
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    print("banda: relief %d x %d, %d fete, %d dealuri, oras %.1f%% din varfuri" % (
        N_R, N_AZ, nf, len(hills), 100.0 * float((city > 0.5).mean())))
    return ob


def land_colors(px, py, z, nz, north, kind, gul):
    steep = smoothstep(0.82, 0.50, nz)
    gi = np.clip((fbm(px, py, 420.0, 31, octaves=2) * len(GOLD)).astype(int), 0, len(GOLD) - 1)
    gold = np.array([lin(c) for c in GOLD])[gi]
    si = np.clip((fbm(px, py, 260.0, 32, octaves=2) * len(SCRUB)).astype(int), 0, len(SCRUB) - 1)
    scrub = np.array([lin(c) for c in SCRUB])[si]
    # chaparral pe coastele de nord si in ravene; iarba aurie pe cele de sud
    rav = smoothstep(0.40, 0.80, gul)
    green = np.clip(smoothstep(-0.05, 0.35, north) * 0.6 + 0.7 * rav, 0.0, 1.0)
    green = green * smoothstep(0.3, 0.6, fbm(px, py, 520.0, 33, octaves=3) + 0.2)
    col = gold * (1 - green)[..., None] + scrub * green[..., None]
    oak = rav * rav * 0.6
    col = col * (1 - oak)[..., None] + lin(OAK) * oak[..., None]
    # faleze (capul Marin, malul): gresie
    # faleza de gresie doar la capul Marin; in rest panta abrupta e iarba in umbra
    rk = steep * 0.8 * (kind == KINDS["marin"])
    col = col * (1 - rk)[..., None] + lin(ROCK) * rk[..., None]
    # plaja la apa
    beach = smoothstep(5.0, 1.5, z) * (1 - steep)
    col = col * (1 - beach)[..., None] + lin(BEACH) * beach[..., None]
    return col


# --- Materiale ---------------------------------------------------------------------

def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def haze_wrap(nt, surface_socket, out_node, f0=HAZE_F0):
    """surface -> amestec cu HAZE dupa distanta (si o pacla subtire peste apa, departe)."""
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
    keep_air = math_node("MULTIPLY", x, vb=1.0 - f0)
    keep_air = math_node("MAXIMUM", keep_air, vb=1.0 - HAZE_MAX)
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / MIST_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = MIST_R0
    ramp.inputs["From Max"].default_value = MIST_R1
    ramp.inputs["To Min"].default_value = MIST_NEAR
    mist = math_node("MULTIPLY", z, ramp.outputs["Result"])
    mist = math_node("MULTIPLY", mist, vb=MIST_K)
    keep_mist = math_node("SUBTRACT", va=1.0, b=mist)
    keep = math_node("MULTIPLY", keep_air, keep_mist)
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(HAZE)
    em.inputs["Strength"].default_value = 1.0
    mix = n.new("ShaderNodeMixShader")
    L.new(fac, mix.inputs[0])
    L.new(surface_socket, mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    L.new(mix.outputs[0], out_node.inputs["Surface"])


def const_ramp(n, stops):
    vr = n.new("ShaderNodeValToRGB")
    vr.color_ramp.interpolation = "CONSTANT"
    els = vr.color_ramp.elements
    while len(els) < len(stops):
        els.new(0.5)
    for el, (pos, hx) in zip(els, stops):
        el.position = pos
        el.color = srgb(hx)
    return vr


def land_material():
    """Baza = vertex color (iarba, tufaris, faleza). Unde atributul `city` e 1,
    orasul se picteaza in shader: grila de strazi (benzi de STREET_W la fiecare
    STREET_PITCH, in coordonate de lume) si, in cvartale, celule Voronoi de ~8 m =
    case, fiecare cu tenta ei din cele cinci pasteluri sau cu acoperisul gri.
    Distanta F1 da o margine mai inchisa fiecarei case (umbra dintre ele)."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    cty = n.new("ShaderNodeAttribute")
    cty.attribute_name = "city"
    cty.attribute_type = "GEOMETRY"
    tc = n.new("ShaderNodeTexCoord")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["Object"], sep.inputs[0])
    vor = n.new("ShaderNodeTexVoronoi")
    vor.feature = "F1"
    vor.inputs["Scale"].default_value = 1.0 / 8.0
    vor.inputs["Randomness"].default_value = 0.35
    L.new(tc.outputs["Object"], vor.inputs["Vector"])
    sc = n.new("ShaderNodeSeparateColor")
    L.new(vor.outputs["Color"], sc.inputs[0])
    stops = [(0.0, PASTELS[0]), (0.15, PASTELS[1]), (0.29, PASTELS[2]), (0.42, PASTELS[3]),
             (0.53, PASTELS[4]), (0.62, WHITE), (0.70, ROOF), (0.86, ROOF_B)]
    pal = const_ramp(n, stops)
    L.new(sc.outputs[0], pal.inputs["Fac"])
    cr = n.new("ShaderNodeMapRange")
    cr.inputs["From Min"].default_value = 0.25
    cr.inputs["From Max"].default_value = 0.75
    cr.inputs["To Min"].default_value = 1.0
    cr.inputs["To Max"].default_value = 0.62
    L.new(vor.outputs["Distance"], cr.inputs["Value"])
    shade = n.new("ShaderNodeMix")
    shade.data_type = "RGBA"
    shade.blend_type = "MULTIPLY"
    shade.inputs[0].default_value = 1.0
    L.new(pal.outputs["Color"], shade.inputs[6])
    cv = n.new("ShaderNodeCombineColor")
    for i in range(3):
        L.new(cr.outputs["Result"], cv.inputs[i])
    L.new(cv.outputs[0], shade.inputs[7])

    # strazile: |frac(x / P - 0.5) - 0.5| * P < W / 2, pe x si pe y
    def street_axis(sock, pitch):
        m1 = n.new("ShaderNodeMath")
        m1.operation = "DIVIDE"
        L.new(sock, m1.inputs[0])
        m1.inputs[1].default_value = pitch
        m2 = n.new("ShaderNodeMath")
        m2.operation = "PINGPONG"          # 0..0.5..0: distanta pana la cea mai apropiata strada
        L.new(m1.outputs[0], m2.inputs[0])
        m2.inputs[1].default_value = 0.5
        m3 = n.new("ShaderNodeMath")
        m3.operation = "LESS_THAN"
        L.new(m2.outputs[0], m3.inputs[0])
        m3.inputs[1].default_value = (STREET_W * 0.5) / pitch
        return m3.outputs[0]
    sx = street_axis(sep.outputs[0], STREET_PITCH[1])
    sy = street_axis(sep.outputs[1], STREET_PITCH[0])
    st = n.new("ShaderNodeMath")
    st.operation = "MAXIMUM"
    L.new(sx, st.inputs[0])
    L.new(sy, st.inputs[1])
    street = n.new("ShaderNodeMix")
    street.data_type = "RGBA"
    L.new(st.outputs[0], street.inputs[0])
    L.new(shade.outputs[2], street.inputs[6])
    street.inputs[7].default_value = srgb(STREET)
    # coroanele: celula Voronoi de ~7 m = un arbore, daca R-ul ei < `trees`
    trs = n.new("ShaderNodeAttribute")
    trs.attribute_name = "trees"
    trs.attribute_type = "GEOMETRY"
    tv = n.new("ShaderNodeTexVoronoi")
    tv.feature = "F1"
    tv.inputs["Scale"].default_value = 1.0 / 7.0
    tv.inputs["Randomness"].default_value = 0.9
    L.new(tc.outputs["Object"], tv.inputs["Vector"])
    tsc = n.new("ShaderNodeSeparateColor")
    L.new(tv.outputs["Color"], tsc.inputs[0])
    is_tree = n.new("ShaderNodeMath")
    is_tree.operation = "LESS_THAN"
    L.new(tsc.outputs[0], is_tree.inputs[0])
    L.new(trs.outputs["Fac"], is_tree.inputs[1])
    tpal = const_ramp(n, [(0.0, CYPRESS), (0.3, OAK), (0.55, SCRUB[2]), (0.8, SCRUB[0])])
    L.new(tsc.outputs[1], tpal.inputs["Fac"])
    tcr = n.new("ShaderNodeMapRange")
    tcr.inputs["From Min"].default_value = 0.0
    tcr.inputs["From Max"].default_value = 0.8
    tcr.inputs["To Min"].default_value = 1.15
    tcr.inputs["To Max"].default_value = 0.5
    L.new(tv.outputs["Distance"], tcr.inputs["Value"])
    tsh = n.new("ShaderNodeMix")
    tsh.data_type = "RGBA"
    tsh.blend_type = "MULTIPLY"
    tsh.inputs[0].default_value = 1.0
    L.new(tpal.outputs["Color"], tsh.inputs[6])
    tcv = n.new("ShaderNodeCombineColor")
    for i in range(3):
        L.new(tcr.outputs["Result"], tcv.inputs[i])
    L.new(tcv.outputs[0], tsh.inputs[7])
    base = n.new("ShaderNodeMix")
    base.data_type = "RGBA"
    L.new(is_tree.outputs[0], base.inputs[0])
    L.new(at.outputs["Color"], base.inputs[6])
    L.new(tsh.outputs[2], base.inputs[7])
    albedo = n.new("ShaderNodeMix")
    albedo.data_type = "RGBA"
    L.new(cty.outputs["Fac"], albedo.inputs[0])
    L.new(base.outputs[2], albedo.inputs[6])
    L.new(street.outputs[2], albedo.inputs[7])
    # relieful caselor: o calota pe celula, ca soarele sa le lumineze o latura
    hgt0 = n.new("ShaderNodeMath")
    hgt0.operation = "MULTIPLY"
    L.new(vor.outputs["Distance"], hgt0.inputs[0])
    L.new(cty.outputs["Fac"], hgt0.inputs[1])
    hgt1 = n.new("ShaderNodeMath")
    hgt1.operation = "MULTIPLY"
    L.new(tv.outputs["Distance"], hgt1.inputs[0])
    L.new(is_tree.outputs[0], hgt1.inputs[1])
    hgt = n.new("ShaderNodeMath")
    hgt.operation = "ADD"
    L.new(hgt0.outputs[0], hgt.inputs[0])
    L.new(hgt1.outputs[0], hgt.inputs[1])
    bump = n.new("ShaderNodeBump")
    bump.invert = True
    bump.inputs["Strength"].default_value = 0.6
    bump.inputs["Distance"].default_value = 4.0
    L.new(hgt.outputs[0], bump.inputs["Height"])
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(albedo.outputs[2], bsdf.inputs["Color"])
    L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def vcol_material(name="BandBuild"):
    """Culoarea pe varf; pe peretii caselor (atributul `facade`) o grila de
    ferestre: benzi verticale la 2,4 m si orizontale la 3,2 m (etajele), doar pe
    fetele verticale. Pe fatada N/S grila curge pe x, pe cea E/V pe y."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    fa = n.new("ShaderNodeAttribute")
    fa.attribute_name = "facade"
    fa.attribute_type = "GEOMETRY"
    geo = n.new("ShaderNodeNewGeometry")
    sp = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sp.inputs[0])
    sn = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Normal"], sn.inputs[0])

    def m(op, a, b=None, vb=None):
        nd = n.new("ShaderNodeMath")
        nd.operation = op
        L.new(a, nd.inputs[0])
        if b is not None:
            L.new(b, nd.inputs[1])
        elif vb is not None:
            nd.inputs[1].default_value = vb
        return nd.outputs[0]
    ny = m("ABSOLUTE", sn.outputs[1])
    nx = m("ABSOLUTE", sn.outputs[0])
    facing_ns = m("GREATER_THAN", ny, nx)
    mixa = n.new("ShaderNodeMix")
    mixa.data_type = "FLOAT"
    L.new(facing_ns, mixa.inputs[0])
    L.new(sp.outputs[1], mixa.inputs[2])
    L.new(sp.outputs[0], mixa.inputs[3])
    col_w = m("LESS_THAN", m("PINGPONG", m("DIVIDE", mixa.outputs[0], vb=2.4), vb=0.5), vb=0.18)
    row_w = m("LESS_THAN", m("PINGPONG", m("DIVIDE", sp.outputs[2], vb=3.2), vb=0.5), vb=0.2)
    vert = m("LESS_THAN", m("ABSOLUTE", sn.outputs[2]), vb=0.3)
    win = m("MULTIPLY", m("MULTIPLY", col_w, row_w), m("MULTIPLY", vert, fa.outputs["Fac"]))
    win = m("MULTIPLY", win, vb=0.85)
    wm = n.new("ShaderNodeMix")
    wm.data_type = "RGBA"
    L.new(win, wm.inputs[0])
    L.new(at.outputs["Color"], wm.inputs[6])
    wm.inputs[7].default_value = srgb(WINDOW)
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(wm.outputs[2], bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def sea_material():
    """Marea e NEILUMINATA: culoarea apei jocului la ~300 m, care se deschide spre
    orizont (Fresnel), spalata apoi de acelasi aer ca uscatul."""
    mat, nt, out = new_material("BandSea")
    n, L = nt.nodes, nt.links
    cam = n.new("ShaderNodeCameraData")
    mr = n.new("ShaderNodeMapRange")
    L.new(cam.outputs["View Distance"], mr.inputs["Value"])
    mr.inputs["From Min"].default_value = 350.0
    mr.inputs["From Max"].default_value = 3500.0
    mr.interpolation_type = "SMOOTHSTEP"
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(SEA)
    cmix.inputs[7].default_value = srgb(SEA_FAR)
    L.new(mr.outputs["Result"], cmix.inputs[0])
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.02, 0.06, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 3.0
    nz.inputs["Detail"].default_value = 4.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    k = n.new("ShaderNodeMapRange")
    L.new(nz.outputs["Fac"], k.inputs["Value"])
    k.inputs["To Min"].default_value = 0.94
    k.inputs["To Max"].default_value = 1.06
    em = n.new("ShaderNodeEmission")
    L.new(cmix.outputs[2], em.inputs["Color"])
    L.new(k.outputs["Result"], em.inputs["Strength"])
    haze_wrap(nt, em.outputs[0], out, f0=0.0)
    return mat


# --- Cladiri (o singura plasa, culoare pe varf) -------------------------------------

class Builder:
    def __init__(self):
        self.verts, self.faces, self.cols, self.fac = [], [], [], []

    def _q(self, pts, col, fac=0.0):
        b = len(self.verts)
        self.verts.extend(pts)
        self.cols.extend([col] * len(pts))
        self.fac.extend([fac] * len(pts))
        return b

    def box(self, cx, cy, z0, sx, sy, h, rot, col, top=None, fac=0.0):
        c, s = math.cos(rot), math.sin(rot)
        pts = []
        for dz in (0.0, h):
            for ux, uy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                lx, ly = ux * sx * 0.5, uy * sy * 0.5
                pts.append((cx + lx * c - ly * s, cy + lx * s + ly * c, z0 + dz))
        b = self._q(pts, col, fac)
        for k in range(4):
            k1 = (k + 1) % 4
            self.faces.append((b + k, b + k1, b + 4 + k1, b + 4 + k))
        if top is None:
            self.faces.append((b + 4, b + 5, b + 6, b + 7))
        else:
            tb = self._q(pts[4:], top)
            self.faces.append((tb, tb + 1, tb + 2, tb + 3))

    def gable(self, cx, cy, z0, sx, sy, h, rot, col):
        """Acoperis in doua ape, coama pe lungimea sy (spre strada)."""
        c, s = math.cos(rot), math.sin(rot)

        def P(lx, ly, z):
            return (cx + lx * c - ly * s, cy + lx * s + ly * c, z)
        hx, hy = sx * 0.5, sy * 0.5
        pts = [P(-hx, -hy, z0), P(hx, -hy, z0), P(hx, hy, z0), P(-hx, hy, z0),
               P(0.0, -hy, z0 + h), P(0.0, hy, z0 + h)]
        b = self._q(pts, col)
        self.faces += [(b + 0, b + 4, b + 5, b + 3), (b + 1, b + 2, b + 5, b + 4),
                       (b + 0, b + 1, b + 4), (b + 2, b + 3, b + 5)]

    def finish(self, name):
        me = bpy.data.meshes.new(name)
        me.from_pydata(self.verts, [], self.faces)
        me.update()
        n = len(self.verts)
        rgba = np.concatenate([np.array(self.cols), np.ones((n, 1))], axis=1)
        ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
        at = me.attributes.new("facade", "FLOAT", "POINT")
        at.data.foreach_set("value", np.array(self.fac, dtype=np.float32))
        ob = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(ob)
        return ob


def build_town(hills, rng):
    """Casele victoriene in randuri lipite pe fronturile cvartalelor, pana la
    TOWN_R: fiecare casa pe soclul ei, deci acoperisurile coboara in trepte cu
    strada. Fronturile sunt pe strazile E-V (casele cu fata spre N / S), ca in
    grila reala. Plus turnurile generice ale centrului."""
    b = Builder()
    pastels = [srgb(c)[:3] for c in PASTELS]
    roofs = [srgb(ROOF)[:3], srgb(ROOF_B)[:3], srgb("4E5054")[:3]]
    white = srgb(WHITE)[:3]
    pn, pe = STREET_PITCH
    cand = []
    lim = TOWN_R
    i0, i1 = int(-lim / pe) - 1, int(lim / pe) + 1
    j0, j1 = int(-lim / pn) - 1, int(lim / pn) + 1
    lot = 7.6
    for i in range(i0, i1 + 1):
        for j in range(j0, j1 + 1):
            # cvartalul [i*pe + W/2, (i+1)*pe - W/2] x [j*pn + W/2, (j+1)*pn - W/2]
            xa, xb = i * pe + STREET_W * 0.5, (i + 1) * pe - STREET_W * 0.5
            ya, yb = j * pn + STREET_W * 0.5, (j + 1) * pn - STREET_W * 0.5
            cxm, cym = (xa + xb) * 0.5, (ya + yb) * 0.5
            if math.hypot(cxm, cym) > lim or math.hypot(cxm, cym) < 330.0:
                continue
            depth = rng.uniform(13.0, 17.0)
            for (yf, face) in ((ya + depth * 0.5, -1), (yb - depth * 0.5, 1)):
                x = xa + rng.uniform(0.0, 2.0)
                while x + lot <= xb:
                    w = lot * rng.uniform(0.92, 1.12)
                    cand.append((x + w * 0.5, yf, w, depth, face))
                    x += w
            # capetele cvartalului (fronturile N-S), cate doua case
            for (xf, face) in ((xa + 7.0, 2), (xb - 7.0, 2)):
                for yy in (ya + depth + 5.0, yb - depth - 5.0):
                    if yb - ya > 2 * depth + 6.0:
                        cand.append((xf, yy, 14.0, lot, face))
    cx = np.array([[c[0] for c in cand]])
    cy = np.array([[c[1] for c in cand]])
    zgs, land, kinds, hms, _ = heights(cx, cy, hills)
    # aceeasi masca de oras ca in shader (fara pante de faleza si crestele goale)
    bald = smoothstep(0.55, 0.75, fbm(cx, cy, 650.0, 61, octaves=3))
    keep = (kinds == KINDS["city"]) & (land > 0.8) & (zgs > 6.0)
    keep &= ~((bald > 0.5) & (zgs / np.maximum(hms, 1.0) > 0.75))
    nh = 0
    for k, (x, y, w, dpt, face) in enumerate(cand):
        if not keep[0, k]:
            continue
        zg = float(zgs[0, k])
        # inaltimea: doua-trei etaje peste garaj, 8,5-12 m; soclul de beton coboara
        # sub teren (pe panta casa de jos sta mai jos: trepte)
        hh = rng.uniform(8.5, 12.0)
        wall = pastels[rng.randint(0, len(pastels) - 1)]
        if face == 2:
            b.box(x, y, zg - 3.0, w, dpt, hh + 3.0, 0.0, wall, top=roofs[rng.randint(0, 2)], fac=1.0)
        else:
            b.box(x, y, zg - 3.0, w - 0.25, dpt, hh + 3.0, 0.0, wall, top=roofs[rng.randint(0, 2)], fac=1.0)
            # cornisa alba spre strada (o fasie in capul fatadei)
            fy = y + face * dpt * 0.5
            b.box(x, fy, zg + hh - 0.9, w - 0.25, 0.8, 1.2, 0.0, white)
            if rng.random() < 0.35:
                b.gable(x, y, zg + hh, w - 0.4, dpt * 0.9, 2.6, 0.0, roofs[rng.randint(0, 2)])
        nh += 1
    # centrul: turnuri generice, modeste, piatra / sticla
    az0, d0, span, dep = DOWNTOWN
    nt = 0
    for _ in range(22):
        az = az0 + rng.uniform(-span * 0.5, span * 0.5)
        d = d0 + rng.uniform(-dep * 0.5, dep * 0.5)
        x, y = polar(az, d)
        x, y = round(x / 12.0) * 12.0, round(y / 12.0) * 12.0
        zg = float(heights(np.array([[x]]), np.array([[y]]), hills)[0][0, 0])
        core = 1.0 - min(1.0, abs(angdiff(az, az0)) / (span * 0.5))
        hh = rng.uniform(30.0, 55.0) + 70.0 * core * rng.uniform(0.3, 1.0)
        sx, sy = rng.uniform(22.0, 36.0), rng.uniform(22.0, 36.0)
        cc = srgb(TOWER[rng.randint(0, len(TOWER) - 1)])[:3]
        b.box(x, y, zg - 2.0, sx, sy, hh + 2.0, 0.0, cc, top=srgb("8A8A88")[:3], fac=1.0)
        if rng.random() < 0.5:
            b.box(x, y, zg + hh, sx * 0.7, sy * 0.7, rng.uniform(4.0, 10.0), 0.0, cc,
                  top=srgb("7E7E7C")[:3])
        nt += 1
    # veliere: corp alb, vela triunghiulara
    for az, d, yaw in SAILS:
        x, y = polar(az, d)
        rot = math.radians(yaw)
        b.box(x, y, 0.0, 3.0, 10.0, 1.4, rot, srgb(HULL)[:3])
        c, s = math.cos(rot), math.sin(rot)

        def P(lx, ly, z):
            return (x + lx * c - ly * s, y + lx * s + ly * c, z)
        vb = b._q([P(0.0, -4.0, 1.4), P(0.0, 3.0, 1.4), P(0.0, 2.6, 15.0)], srgb(SAIL)[:3])
        b.faces.append((vb, vb + 1, vb + 2))
        vb = b._q([P(0.05, 3.0, 1.4), P(0.05, -4.0, 1.4), P(0.05, 2.6, 15.0)], srgb(SAIL)[:3])
        b.faces.append((vb, vb + 1, vb + 2))
    ob = b.finish("BandTown")
    ob.data.materials.append(vcol_material())
    print("banda: %d case, %d turnuri, %d veliere" % (nh, nt, len(SAILS)))


# --- Scena -------------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def build_sea():
    me = bpy.data.meshes.new("BandSea")
    s = 60000.0
    me.from_pydata([(-s, -s, SEA_Z), (s, -s, SEA_Z), (s, s, SEA_Z), (-s, s, SEA_Z)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new("BandSea", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(sea_material())


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
    ld.color = srgb(SUN_COLOR)[:3]
    ld.angle = math.radians(0.6)
    sun = bpy.data.objects.new("BandSun", ld)
    bpy.context.collection.objects.link(sun)
    sd = sun_dir_blender()
    sun.rotation_euler = (-sd).to_track_quat("-Z", "Y").to_euler()
    print("banda: soarele spre busola %.0f, %.0f grade" % (
        math.degrees(math.atan2(sd.x, sd.y)) % 360.0, math.degrees(math.asin(sd.z))))

    fd = bpy.data.lights.new("BandFill", "SUN")
    fd.energy = FILL_STRENGTH
    fd.color = srgb(FILL_COLOR)[:3]
    fd.angle = math.radians(10.0)
    fill = bpy.data.objects.new("BandFill", fd)
    bpy.context.collection.objects.link(fill)
    fa = math.radians(FILL_AZ)
    to_fill = Vector((math.sin(fa), math.cos(fa), 0.15)).normalized()
    fill.rotation_euler = (-to_fill).to_track_quat("-Z", "Y").to_euler()

    world = bpy.data.worlds.new("BandWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = srgb(AMBIENT)
    bg.inputs["Strength"].default_value = AMBIENT_ENERGY
    sc.world = world


def test_markers():
    """Cuburi emisive pe punctele cardinale, la 800 m: rosu E, verde N, albastru V,
    galben S."""
    for name, (x, y), col in (("E", (800, 0), (1, 0, 0, 1)), ("N", (0, 800), (0, 1, 0, 1)),
                              ("V", (-800, 0), (0, 0, 1, 1)), ("S", (0, -800), (1, 1, 0, 1))):
        me = bpy.data.meshes.new("Mk" + name)
        s = 30.0
        vs = [(x + dx * s, y + dy * s, CAM_Z + 45 + dz * s) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
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
rng = random.Random(25)
hills = make_hills(rng)
setup_render()
build_sea()
land = build_land(hills)
land.data.materials.append(land_material())
build_town(hills, random.Random(251))
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
