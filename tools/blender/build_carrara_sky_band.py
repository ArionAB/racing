"""Banda de orizont a cerului Carrara (Track23) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/carrara_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa: Alpii
Apuani deasupra Carrarei — creste abrupte de calcar cu CARIERE DE MARMURA taiate in
trepte pe flancuri (fete crem geometrice, gradoni, halde de moloz — ravaneti — pe
pante), paduri de castan jos, iar spre sud valea care coboara spre campia litorala si
Marea Ligurica (coasta Versiliei spre SE, promontoriul de la Punta Bianca spre V).
Cerul ramane TRANSPARENT: gradientul lui il deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Ha Long / Fiordland / Monument Valley / Machu Picchu. Ce e
specific aici:

  * MARMURA din banda e aceeasi ca a kitului 3D (clasa `carrara_marble`, brief §4):
    crem-auriu la soare, gri-albastrui in umbra, NU alb ars (regula v0.2 a pistei:
    „nimic alb-pur in cadru”). Albedo-ul fetelor (`MARBLE`) e ales ca, sub soarele
    temei, fata luminata sa iasa ~(228, 196, 159) inainte de aer — ce da clasa pe
    cuburile de proba. Departarea o face mai palida (spre HAZE), nu mai alba.
  * Carierele sunt TERASARE reale ale campului de inaltimi (`quarry` mai jos):
    inaltimea e cuantizata in trepte pe un petic al flancului, deci gradonii au
    fete aproape verticale (luminate de soare sau in umbra, ca in joc) si praguri
    plate. Sub fiecare cariera curge un ravaneto (dare palide de moloz pe panta).
  * IMBINAREA cu terenul jocului: ca pe MV, podeaua benzii la marginea de jos e
    praful bej al carierei (`FLOOR`), luminat de acelasi soare; `fog` = `below` =
    culoarea acelui rand, deci terenul cetos al jocului intra in banda fara dunga.
  * Spre sud (deschiderea amfiteatrului, unde sta si soarele) valea coboara: marea
    se vede ca o fasie sub orizont, peste umarul vaii, cu campia si orasul jos.
  * Planul 0 (`NEAR_GIANTS`): masive APROPIATE (0,55-0,85 km) cu cariere pe flanc,
    puse de mana pe directiile in care priveste camera pe portiunile lungi (sonda pe
    Track23.baked), la 10-15 grade de axa dreptelor, nu in spatele masivelor 3D reale
    ale pistei (MasivGalerie la E, MasivMarmifera la VNV).

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste podea (cota medie a soselei), in origine; u = 0,5 priveste
    spre NORD (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in
    shader (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din Track23.tscn (`custom_sun_rotation_deg` (-22, -10, 0): busola 190,
    22 de grade elevatie — NU (-22, 30) din tema, pe care pista il suprascrie),
    `sun_color` FFD2A0, energia 1,25; ambientul BCCCE8 la 0,42;
  * HAZE = `sky_horizon` din tema (EDE6D8): departarea se topeste exact in culoarea
    pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica Godot,
    o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_carrara_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import math
import os
import random
import sys

import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Ochiul peste podea (cota medie a soselei, 24,85 m = podeaua plata a jocului,
# `dune_scale` 0). Sonda pe Track23.baked: pe cariera de sus (0,60-0,76, de unde se
# vede cel mai mult cer) ochiul sta la +30 m peste medie, la start (0,00-0,08) la
# +10, pe bucla de vest (0,77-0,95) la +13..+24. Cu 30 m, podeaua de la 380 m cade
# la -4,5 grade — cat vede in jos camera de pe cariera de sus prin marginea terenului.
CAM_Z = 30.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "carrara_horizon_band_test.png" if TEST
                   else "carrara_horizon_band.png")


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


# --- Paleta (sRGB; albedo, nu culoarea pe ecran — lumina o pune soarele temei) ----
HAZE = "EDE6D8"          # = sky_horizon din tema: departarea intra in cer
MIST = "E6DCCB"          # aerul jos din vale si de pe mare, cald (vara, Versilia)
# Podeaua: praful carierei (pietrisul jocului x ground_tint). ALBEDO, nu culoarea pe
# ecran: tenta e rece-verzuie ca in tema (0.94, 0.97, 0.79), fiindca soarele #FFD2A0
# o incalzeste. Sub lumina temei iese ~(175, 166, 145) in textura, cat terenul jocului.
FLOOR = "D4D9C4"
FLOOR_B = "C6C9B2"
# Marmura taiata (carrara_marble): crem, nu alb; umbra o face ambientul albastrui.
MARBLE = "E2D6C2"
MARBLE_B = "D2C6B0"      # dungile de fir, patina
RUST = "A8683A"          # LARCH_RUST: darele de rugina de sub gradoni
TREAD = "B9AF9A"         # pragurile gradonilor: praf de marmura
SCREE = "CFC7B8"         # ravaneto: moloz crem-gri (brief: NU alb ca un ghetar)
SCREE_B = "BDB4A4"
LIMESTONE = "A39B8D"     # calcarul crestelor neexploatate, crem-gri
LIMESTONE_DARK = "7A7468"
# Padurea de castani (tf_beech #5E8A3A, verde cald) si macchia mai jos.
FOREST = ["56783A", "60843F", "5A7C3E", "516E37", "668647", "5A7A3C"]
FOREST_DEEP = "34502A"
GINESTRA = "C9B040"      # galbenul ginestrei pe muchiile neexploatate (rar)
OLIVE = "7E865A"         # maslini si culturi pe dealurile joase ale vaii
TOWN = ["D9C7A6", "C9A27E", "B8704E", "E3D5BC", "A89880"]   # tencuieli, tigla
SAND = "E3D3B0"          # plaja Versiliei
SEA = "2E6A94"           # Marea Ligurica, albastru adanc
SEA_NEAR = "3C7596"
SUN_COLOR = "FFD2A0"
# Godot inmulteste energia luminii cu pi (alb lambertian perpendicular = energia);
# Cycles nu. Deci taria Cycles = pi x energia temei (masurat pe MV, #761).
SUN_STRENGTH = math.pi * 1.25
AMBIENT = "BCCCE8"
AMBIENT_ENERGY = 0.42
SUN_ROT = (-22.0, -10.0)                   # custom_sun_rotation_deg (x, y) din Track23
FILL_COLOR = "D9CBB0"    # lumina intoarsa de marmura si praf, din partea opusa soarelui
FILL_AZ, FILL_STRENGTH = 10.0, 1.4

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului incolo. Vara pe coasta: aer cald si umed, deci mai gros spre mare.
HAZE_D0, HAZE_D, HAZE_F0 = 380.0, 8000.0, 0.22
HAZE_MAX = 0.86
# Planul 0: voal INTREG. Cu 0,7 (ca pe MV) uriasii ieseau mai saturati decat masivele
# 3D cetoase din fata lor (MasivGalerie la 0,02 si 0,25): adancime inversata.
NEAR_HAZE_K = 1.0
SEA_HAZE_K = 0.45                        # marea: altfel iese o fasie alba, nu mare
MIST_H, MIST_K = 120.0, 0.30             # aerul jos din vale: K * exp(-(z - z0)/H)
MIST_Z0 = -445.0

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
    """Inaltimea (peste podea) care sta la `theta_deg` peste ochi, la distanta d."""
    return CAM_Z + d * math.tan(math.radians(theta_deg))


def polar(az_deg, d):
    a = math.radians(az_deg)
    return math.sin(a) * d, math.cos(a) * d      # Blender: x est, y nord


def ang_dist(a, b):
    return np.abs((a - b + 180.0) % 360.0 - 180.0)


# --- Geografia ---------------------------------------------------------------------
#
# Valea spre mare: sectorul de azimut (busola) in care terenul coboara spre coasta.
# Soarele (190) sta deasupra lui, ca in realitate (carierele Fantiscritti se deschid
# spre SV, spre Carrara si mare).
# Masurat: camera nu priveste NICIODATA spre S (140-220 nu intra in cadru cu cer),
# ci spre E (40-140) si V (220-320). Marea sta deci spre SV-V, unde e si in
# realitate fata de Fantiscritti: de pe cariera de sus (0,60-0,76, spre V) valea se
# deschide intre doua flancuri spre campie si mare. Soarele (190) e in stanga ei.
SEA_AZ, SEA_HALF, SEA_EDGE = 246.0, 30.0, 14.0
VALLEY_L = 1100.0                         # cat de repede coboara valea spre campie
COAST_R = 5200.0                          # linia tarmului (variaza cu azimutul)
PLAIN_Z = -405.0                          # campia litorala (cota fata de podea)
SEA_Z = -445.0

# Planul 0, pus de mana: (azimut busola, distanta, unghi varf peste ochi, R/h,
# cariera: (azimut relativ de pe flanc, cota relativa 0..1, latime, inaltime) sau None).
#
#   portiunea                fractii      directia camerei  ochi peste podea
#   start, piazzale -> E     0,00-0,08    90                +10 m
#   fundul carierei -> E     0,21-0,31    90                -8..-13 (doar peste +1..+5)
#   cariera de sus -> V      0,60-0,76    270               +30 m (cer 19/19)
#   bucla de vest -> N/NV    0,77-0,92    285-60            +13..+24
#
# Reperele 3D reale: MasivGalerie (E, 112-140 din cadrele spre E) si MasivMarmifera
# (290-318 de pe cariera de sus, ~26 de pe bucla de vest). Acolo planul 0 lipseste.
NEAR_GIANTS = [
    # spre E: stanga axei (28 de grade), cu cariera pe fata
    (62.0, 680.0, 8.5, 1.1, (0.15, 0.42, 0.42, 0.2)),
    # spre E/NE: marginea din stanga a cadrelor spre E, dreapta pe bucla de vest
    (36.0, 780.0, 7.0, 1.2, (-0.2, 0.45, 0.4, 0.18)),
    # spre N: de pe bucla de vest, in stanga Marmiferei reale
    (350.0, 720.0, 8.0, 1.15, (0.0, 0.4, 0.45, 0.2)),
    # spre V: cele doua flancuri ale vaii; marea intre ele (Brugiana in stanga)
    (222.0, 640.0, 7.5, 1.1, (0.25, 0.42, 0.42, 0.2)),
    (287.0, 700.0, 7.0, 1.15, (-0.25, 0.38, 0.38, 0.18)),
]

# Planurile departate: (d_min, d_max, theta_min, theta_max, pas de azimut min/max,
# probabilitatea de cariera pe varf)
PLANES = [
    (1300.0, 2200.0, 5.0, 8.0, 8.0, 15.0, 0.75),
    (2600.0, 4200.0, 4.6, 7.0, 6.0, 12.0, 0.6),
    (5000.0, 8000.0, 4.2, 6.2, 5.0, 10.0, 0.35),
    (10000.0, 16000.0, 3.0, 4.6, 4.0, 9.0, 0.0),
]
# Sectoare fara varfuri apropiate (planul 0 si 1): in spatele masivelor 3D reale.
QUIET = [(112.0, 140.0), (288.0, 318.0)]


def in_quiet(az):
    a = az % 360.0
    return any(lo <= a <= hi for lo, hi in QUIET)


def sea_weight(az):
    """1 in sectorul vaii/marii, 0 pe munte; margini moi."""
    d = ang_dist(az, SEA_AZ)
    return 1.0 - smoothstep(SEA_HALF - SEA_EDGE, SEA_HALF, d)


def make_peaks(rng):
    """Varfuri: (x, y, h, R, a, b, rot, ecc, plane, quarry) — quarry = None sau
    (cx, cy, cz, rx, rz, step) in lume: petic de flanc terasat."""
    peaks = []

    def massif(x, y, h, R, plane, qprob, sats=(1, 3), quarry=None):
        # Apuanii: creste ascutite si alungite, nu capite de fan. Flanc concav
        # (a mic, b mare), axa lunga aproape TANGENTIALA (creasta vazuta din lat).
        a = rng.uniform(1.0, 1.5)
        b = rng.uniform(1.1, 1.6)
        rot = -math.atan2(x, y) + rng.uniform(-0.5, 0.5)
        ecc = rng.uniform(0.4, 0.65)
        if quarry is None and rng.random() < qprob:
            # pe fata dinspre camera, la 35-65% din inaltime
            d = math.hypot(x, y)
            ux, uy = -x / d, -y / d
            off = R * rng.uniform(0.35, 0.55)
            tx, ty = -uy, ux
            lat = R * rng.uniform(-0.3, 0.3)
            quarry = (x + ux * off + tx * lat, y + uy * off + ty * lat,
                      h * rng.uniform(0.35, 0.55), R * rng.uniform(0.15, 0.26),
                      h * rng.uniform(0.12, 0.2), max(8.0, d * 0.006))
        peaks.append((x, y, h, R, a, b, rot, ecc, plane, quarry))
        for _ in range(rng.randint(*sats)):
            ang = rng.uniform(0.0, math.tau)
            off = R * rng.uniform(0.35, 0.85)
            f = rng.uniform(0.55, 0.85)
            peaks.append((x + math.cos(ang) * off, y + math.sin(ang) * off, h * f,
                          R * f * rng.uniform(0.8, 1.1), rng.uniform(1.0, 1.6),
                          rng.uniform(1.2, 1.8), rng.uniform(0.0, math.pi),
                          rng.uniform(0.45, 0.9), plane, None))

    for az, d, th, rk, q in NEAR_GIANTS:
        x, y = polar(az, d)
        h = h_for(d, th)
        R = h * rk
        quarry = None
        if q is not None:
            qa, qz, qw, qh = q
            # petic pe fata dinspre camera: azimutul relativ in radiani de flanc
            qd = d - R * (1.0 - qz) * 0.9
            qx, qy = polar(az + math.degrees(qa * R / d), qd)
            quarry = (qx, qy, h * qz, R * qw, h * qh, 12.0)
        massif(x, y, h, R, 0, 0.0, sats=(1, 2), quarry=quarry)
    for pi_, (d0, d1, t0, t1, s0, s1, qp) in enumerate(PLANES):
        az = rng.uniform(0.0, 360.0)
        end = az + 360.0
        while az < end:
            step = rng.uniform(s0, s1)
            a = az % 360.0
            sw = float(sea_weight(np.array([a]))[0])
            if not (pi_ <= 1 and in_quiet(a)) and sw < 0.5:
                d = rng.uniform(d0, d1)
                th = rng.uniform(t0, t1) * (1.0 - 0.5 * sw)
                h = h_for(d, th)
                x, y = polar(a, d)
                # masive LATE (R/h 1,1-1,6), cu 0-2 sateliti: un lant de munte,
                # nu un sir de ace (prima randare citea carst, Guilin)
                massif(x, y, h, h * rng.uniform(1.1, 1.6), pi_ + 1, qp, sats=(0, 2))
            az += step
    # Coasta: dealurile joase ale vaii (stanga/dreapta), promontoriul de la Punta
    # Bianca spre V si muntii Versiliei care coboara spre mare spre SE.
    # (azimut, distanta, unghi varf, R / inaltimea peste campie)
    for az, d, th, rk in ((224.0, 2400.0, 1.6, 2.2), (270.0, 2700.0, 1.4, 2.4),
                          (283.0, 10500.0, 0.9, 3.0), (292.0, 14500.0, 1.2, 2.6),
                          (205.0, 12000.0, 2.2, 1.8), (196.0, 16000.0, 2.6, 1.6)):
        x, y = polar(az, d)
        h = h_for(d, th)
        massif(x, y, h, max(300.0, (h - PLAIN_Z) * rk * 0.5), 3, 0.0, sats=(1, 2))
    return peaks


# --- Relieful: camp de inaltimi polar ------------------------------------------

N_AZ = 1024 if TEST else 4096
R0, R_NEAR, R1 = 150.0, 1600.0, 40000.0
N_NEAR = 120 if TEST else 480            # inele dese pana la R_NEAR (gradonii)
N_FAR = 90 if TEST else 300


def base_z(px, py, az, r):
    """Podeaua: 0 pe munte (podeaua plata a jocului); in sectorul vaii coboara spre
    campie si tarm."""
    sw = sea_weight(az)
    # profil CONCAV vazut din ochi (unghiul de sub orizont scade cu distanta), ca sa
    # nu existe o buza care sa ascunda campia si marea: 13 grade la 0,5 km, 4 la 6 km
    t = 1.0 - np.exp(-np.maximum(r - R0, 0.0) / VALLEY_L)
    drop = PLAIN_Z * t
    # tarmul: dincolo de linia coastei terenul intra sub apa
    coast = COAST_R * (1.0 + 0.10 * (vnoise(np.cos(np.radians(az)) * 4.0,
                                          np.sin(np.radians(az)) * 4.0, 1.0, 77) - 0.5))
    under = smoothstep(coast, coast + 500.0, r) * 60.0
    undul = (fbm(px, py, 900.0, 5, octaves=3) - 0.5) * 50.0 * smoothstep(500.0, 1800.0, r)
    return sw * (drop - under) + undul * (1.0 - 0.9 * sw)


def heights(px, py, az, r, peaks):
    z = base_z(px, py, az, r)
    floor = z.copy()
    hm = np.full(px.shape, 1.0)
    kid = np.full(px.shape, -1, dtype=np.int32)
    quarry = np.zeros(px.shape)
    for i, (x0, y0, h, R, pa, pb, rot, ecc, pl, q) in enumerate(peaks):
        m = (np.abs(px - x0) < R * 1.4) & (np.abs(py - y0) < R * 1.4)
        if not m.any():
            continue
        qx, qy = px[m], py[m]
        dx, dy = qx - x0, qy - y0
        ex = dx * math.cos(rot) + dy * math.sin(rot)
        ey = (-dx * math.sin(rot) + dy * math.cos(rot)) / ecc
        rr0 = np.hypot(ex, ey)
        ang = np.arctan2(dy, dx)
        lobe = vnoise(np.cos(ang) * 3.0 + i * 7.1, np.sin(ang) * 3.0, 1.0, 900 + i) - 0.5
        rib = vnoise(np.cos(ang) * 9.0 + rr0 / R * 2.0, np.sin(ang) * 9.0 + i * 3.3,
                     1.0, 1300 + i) - 0.5
        s = np.clip(rr0 / (R * (1.0 + 0.30 * lobe + 0.18 * rib)), 0.0, 1.0)
        base = floor[m]
        zk = base + (h - base) * np.power(1.0 - np.power(s, pa), pb)
        # Apuanii: creste zimtate de calcar, nu cocoase
        jag = fbm(qx, qy, R * 0.40, 2000 + i, octaves=3, ridged=True)
        zk = zk + (jag - 0.45) * 0.36 * (h - base) * np.sqrt(np.clip(1.0 - s, 0.0, 1.0)) * s * 2.0
        better = zk > z[m]
        z[m] = np.where(better, zk, z[m])
        hm[m] = np.where(better, h, hm[m])
        kid[m] = np.where(better, pl, kid[m])
    # creste intre varfurile fiecarui plan (sei): un con lat si turtit al fiecarui
    # varf, ca masivul sa fie un lant de creste, nu turnuri izolate (carst)
    for i, (x0, y0, h, R, pa, pb, rot, ecc, pl, q) in enumerate(peaks):
        if pl == 0:
            continue
        R2 = R * 2.2
        m = (np.abs(px - x0) < R2) & (np.abs(py - y0) < R2)
        if not m.any():
            continue
        rr2 = np.hypot(px[m] - x0, py[m] - y0)
        s2 = np.clip(rr2 / R2, 0.0, 1.0)
        base = floor[m]
        zk = base + (0.45 * (h - base)) * np.power(1.0 - s2, 1.5)
        better = zk > z[m]
        z[m] = np.where(better, zk, z[m])
        hm[m] = np.where(better & (kid[m] < 0), h, hm[m])
        kid[m] = np.where(better & (kid[m] < 0), pl, kid[m])
    # ravene si muchii fine pe flancuri, proportional cu cota peste podea
    rid = fbm(px, py, 140.0, 15, octaves=4, ridged=True)
    z += (rid - 0.45) * 0.10 * np.maximum(z - floor, 0.0)
    # CARIERELE: inaltimea cuantizata in trepte pe peticul fiecarei cariere
    for i, p in enumerate(peaks):
        q = p[9]
        if q is None:
            continue
        cx, cy, cz, rx, rz, step = q
        m = (np.abs(px - cx) < rx * 1.6) & (np.abs(py - cy) < rx * 1.6)
        if not m.any():
            continue
        dx, dy = px[m] - cx, py[m] - cy
        # forma: elipsa pe orizontala (tangential) si pe cota
        d0 = math.hypot(cx, cy)
        tx, ty = -cy / d0, cx / d0
        lat = dx * tx + dy * ty
        zz = z[m]
        # contur UNGHIULAR (superelipsa, putere 5) cu margine dura si zimtata pe
        # trepte: o cariera e o taietura, nu o pata
        edge = (vnoise(lat, np.floor(zz / step), rx * 0.35, 3100 + i) - 0.5) * 0.35
        e = (np.abs(lat / rx) ** 5 + np.abs((zz - cz) / rz) ** 5) ** 0.2 + edge
        w = 1.0 - smoothstep(0.93, 1.0, e)
        t = zz / step
        fi = np.floor(t)
        fr = t - fi
        zq = step * (fi + smoothstep(0.72, 1.0, fr))
        z[m] = zz * (1.0 - w) + zq * w
        quarry[m] = np.maximum(quarry[m], w)
    return z, floor, hm, kid, quarry


def ring_radii():
    near = np.linspace(R0, R_NEAR, N_NEAR, endpoint=False)
    far = R_NEAR * np.power(R1 / R_NEAR, np.linspace(0.0, 1.0, N_FAR))
    return np.concatenate([near, far])


def build_land(peaks):
    az = np.linspace(0.0, 360.0, N_AZ, endpoint=False)
    rr = ring_radii()
    n_r = rr.size
    A, Rg = np.meshgrid(az, rr)                     # (N_R, N_AZ)
    px = np.sin(np.radians(A)) * Rg
    py = np.cos(np.radians(A)) * Rg
    z, floor, hm, kid, quarry = heights(px, py, A, Rg, peaks)
    nverts = n_r * N_AZ
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(n_r - 1), np.arange(N_AZ), indexing="ij")
    j1 = (jj + 1) % N_AZ
    v0 = ii * N_AZ + jj
    v1 = ii * N_AZ + j1
    v2 = (ii + 1) * N_AZ + j1
    v3 = (ii + 1) * N_AZ + jj
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)
    nf = (n_r - 1) * N_AZ
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
    nrm = nrm.reshape(n_r, N_AZ, 3)
    nz = nrm[..., 2]

    rel = np.maximum(z - floor, 0.0)
    hrel = np.clip(rel / np.maximum(hm - floor, 1.0), 0.0, 1.2)
    sw = sea_weight(A)
    # 1. podeaua: praful carierei aproape, apoi padure/macchia in vale
    near = 1.0 - smoothstep(420.0, 850.0, Rg)
    fl = smoothstep(0.35, 0.65, fbm(px, py, 70.0, 3, octaves=3))
    floor_col = lin(FLOOR_B)[None, None, :] * (1 - fl)[..., None] + lin(FLOOR)[None, None, :] * fl[..., None]
    fcol_i = np.clip((fbm(px, py, 140.0, 71, octaves=2) * len(FOREST)).astype(int), 0,
                     len(FOREST) - 1)
    fpal = np.array([lin(c) for c in FOREST])
    fcol = fpal[fcol_i]
    gully = smoothstep(0.55, 0.85, fbm(px, py, 150.0, 15, octaves=4, ridged=True))
    fcol = fcol * (1 - 0.40 * (1 - gully))[..., None] + lin(FOREST_DEEP) * (0.40 * (1 - gully))[..., None]
    # dealurile joase ale vaii: maslini si culturi printre petice de padure
    low = smoothstep(-80.0, -260.0, z) * sw
    oli = smoothstep(0.45, 0.6, fbm(px, py, 220.0, 41, octaves=3)) * low
    fcol = fcol * (1 - oli)[..., None] + lin(OLIVE) * oli[..., None]
    col = fcol.copy()
    canopy = np.ones(z.shape)
    # 2. calcarul: pe fetele repezi si sus pe creste (Apuanii sunt goi deasupra
    # padurii), in pete; umbra o face lumina
    steep = smoothstep(0.50, 0.30, nz)
    crest = smoothstep(0.58, 0.8, hrel + 0.15 * (fbm(px, py, 90.0, 31, octaves=3) - 0.5))
    rock_w = np.clip(np.maximum(crest, steep * 0.9), 0.0, 1.0) * smoothstep(5.0, 30.0, rel)
    rk = smoothstep(0.3, 0.7, fbm(px, py + z * 0.7, 40.0, 37, octaves=3))
    rock = lin(LIMESTONE_DARK)[None, None, :] * (1 - rk)[..., None] + lin(LIMESTONE)[None, None, :] * rk[..., None]
    col = col * (1 - rock_w)[..., None] + rock * rock_w[..., None]
    canopy *= (1 - rock_w)
    # ginestra: galben rar pe muchiile de la marginea padurii
    gin = smoothstep(0.72, 0.8, fbm(px, py, 30.0, 53, octaves=2)) * rock_w * (1 - rock_w) * 3.0
    gin = np.clip(gin, 0.0, 1.0) * 0.6
    col = col * (1 - gin)[..., None] + lin(GINESTRA) * gin[..., None]
    # 3. ravaneti: sub fiecare cariera, dare palide care coboara pe panta (spre
    # camera, adica spre raza mai mica), mai late jos
    rav = np.zeros(z.shape)
    for p in peaks:
        q = p[9]
        if q is None:
            continue
        cx, cy, cz, rx, rz, step = q
        d0 = math.hypot(cx, cy)
        m = (np.abs(px - cx) < rx * 3.0) & (np.abs(py - cy) < rx * 3.0)
        if not m.any():
            continue
        tx, ty = -cy / d0, cx / d0
        lat = (px[m] - cx) * tx + (py[m] - cy) * ty
        below = np.clip((cz - rz * 0.8 - z[m]) / max(cz, 1.0), 0.0, 1.0)
        width = rx * (0.7 + 2.2 * below)
        streak = fbm(lat * 5.0 / (1.0 + 2.0 * below), z[m] * 0.08, 40.0, 61, octaves=2)
        fan = (1.0 - smoothstep(0.5, 1.0, np.abs(lat) / width)) * smoothstep(0.0, 0.04, below) \
            * (1.0 - smoothstep(0.35, 0.8, below)) * smoothstep(0.42, 0.62, streak) * 0.85
        rav[m] = np.maximum(rav[m], fan)
    rav *= (1.0 - quarry)
    rs = smoothstep(0.3, 0.7, fbm(px, py, 25.0, 67, octaves=2))
    scree = lin(SCREE_B)[None, None, :] * (1 - rs)[..., None] + lin(SCREE)[None, None, :] * rs[..., None]
    col = col * (1 - rav)[..., None] + scree * rav[..., None]
    canopy *= (1 - rav)
    # 4. oras (Carrara in vale) si campia urbana a Versiliei, apoi plaja
    # campia: pinete si culturi (verde), orasele in petice (Carrara in vale,
    # Marina si Versilia pe tarm) — nu o pata palida continua
    plain = smoothstep(-330.0, -395.0, z) * sw
    pine = smoothstep(0.4, 0.55, fbm(px, py, 350.0, 97, octaves=3)) * plain
    col = col * (1 - pine)[..., None] + lin(FOREST_DEEP) * pine[..., None]
    town_w = smoothstep(-280.0, -390.0, z) * sw * smoothstep(2600.0, 3600.0, Rg)
    tpal = np.array([lin(c) for c in TOWN])
    ti = np.clip((vnoise(px, py, 22.0, 91) * len(TOWN)).astype(int), 0, len(TOWN) - 1)
    green = smoothstep(0.55, 0.7, fbm(px, py, 160.0, 93, octaves=3))
    tcol = tpal[ti] * (1 - green)[..., None] + lin(OLIVE) * green[..., None]
    town_w *= smoothstep(0.5, 0.62, fbm(px, py, 700.0, 95, octaves=3)) * (1 - pine)
    col = col * (1 - town_w)[..., None] + tcol * town_w[..., None]
    canopy *= (1 - town_w)
    beach = smoothstep(SEA_Z + 16.0, SEA_Z + 8.0, z) * sw
    col = col * (1 - beach)[..., None] + lin(SAND) * beach[..., None]
    canopy *= (1 - beach)
    # 5. podeaua apropiata (imbinarea cu jocul): praful carierei peste tot
    fw = near * (1.0 - smoothstep(4.0, 25.0, rel))
    col = col * (1 - fw)[..., None] + floor_col * fw[..., None]
    canopy *= (1 - fw)
    print("banda: cariere pe %.2f%%, ravaneti %.2f%%, calcar %.1f%% din teren" % (
        100.0 * (quarry > 0.5).mean(), 100.0 * (rav > 0.5).mean(), 100.0 * (rock_w > 0.5).mean()))
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((nverts, 1))], axis=1)
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    at = me.attributes.new("canopy", "FLOAT", "POINT")
    at.data.foreach_set("value", canopy.astype(np.float32).ravel())
    aq = me.attributes.new("quarry", "FLOAT", "POINT")
    aq.data.foreach_set("value", quarry.astype(np.float32).ravel())
    ak = me.attributes.new("near", "FLOAT", "POINT")
    ak.data.foreach_set("value", (kid == 0).astype(np.float32).ravel())
    # gradonii: fete PLATE (marginea dintre prag si fata trebuie sa fie taiata)
    qf = quarry.reshape(-1)
    pq = np.maximum.reduce([qf[quads.reshape(-1, 4)[:, k]] for k in range(4)])
    me.polygons.foreach_set("use_smooth", (pq < 0.3).astype(bool))
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d, %d fete, %d varfuri" % (n_r, N_AZ, nf, len(peaks)))


# --- Scena -----------------------------------------------------------------------

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


def haze_wrap(nt, surface_socket, out_node, near_socket=None, haze_k=1.0):
    """surface -> amestec cu HAZE dupa distanta si cu MIST jos (vale, mare).
    F0 intra treptat pe primii 600 m de dupa d0: la marginea de jos a benzii podeaua
    are exact culoarea prafului din joc, fara voal (imbinarea, ca pe MV). Cu
    `near_socket` (1 pe planul 0) voalul se inmulteste cu NEAR_HAZE_K."""
    n = nt.nodes
    L = nt.links
    cam = n.new("ShaderNodeCameraData")
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])

    def mn(op, a=None, b=None, va=None, vb=None):
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
    x = mn("SUBTRACT", d, vb=HAZE_D0)
    x = mn("MAXIMUM", x, vb=0.0)
    x = mn("MULTIPLY", x, vb=-1.0 / HAZE_D)
    x = mn("EXPONENT", x)
    f0 = mn("SUBTRACT", d, vb=HAZE_D0)
    f0 = mn("MULTIPLY", f0, vb=1.0 / 600.0)
    f0 = mn("MINIMUM", f0, vb=1.0)
    f0 = mn("MAXIMUM", f0, vb=0.0)
    f0 = mn("MULTIPLY", f0, vb=-HAZE_F0)
    f0 = mn("ADD", f0, vb=1.0)
    keep_air = mn("MULTIPLY", x, f0)
    keep_air = mn("MAXIMUM", keep_air, vb=1.0 - HAZE_MAX)
    z = mn("SUBTRACT", sep.outputs[2], vb=MIST_Z0)
    z = mn("MAXIMUM", z, vb=0.0)
    z = mn("MULTIPLY", z, vb=-1.0 / MIST_H)
    z = mn("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")                        # aerul jos doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 1500.0
    ramp.inputs["From Max"].default_value = 6000.0
    mist = mn("MULTIPLY", z, ramp.outputs["Result"])
    mist = mn("MULTIPLY", mist, vb=MIST_K)
    keep_mist = mn("SUBTRACT", va=1.0, b=mist)
    keep = mn("MULTIPLY", keep_air, keep_mist)
    fac = mn("SUBTRACT", va=1.0, b=keep)
    if haze_k != 1.0:
        fac = mn("MULTIPLY", fac, vb=haze_k)
    if near_socket is not None:
        k = mn("MULTIPLY", near_socket, vb=NEAR_HAZE_K - 1.0)
        k = mn("ADD", k, vb=1.0)
        fac = mn("MULTIPLY", fac, k)
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


def land_material():
    """Culoarea e in vertex color; materialul adauga:
      * coroanele padurii (voronoi ~7 m in lume, doar unde `canopy` e 1);
      * GRADONII (unde `quarry` e 1): fata abrupta = marmura crem cu dungi
        orizontale de fir (~0,7 m nu se vad la kilometri; aici benzi la ~2 m) si
        dare de rugina sub muchie; pragul plat = praf de marmura."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    can = n.new("ShaderNodeAttribute")
    can.attribute_name = "canopy"
    can.attribute_type = "GEOMETRY"
    qa = n.new("ShaderNodeAttribute")
    qa.attribute_name = "quarry"
    qa.attribute_type = "GEOMETRY"
    na = n.new("ShaderNodeAttribute")
    na.attribute_name = "near"
    na.attribute_type = "GEOMETRY"
    tc = n.new("ShaderNodeTexCoord")
    vor = n.new("ShaderNodeTexVoronoi")
    vor.feature = "F1"
    vor.inputs["Scale"].default_value = 1.0 / 7.0
    L.new(tc.outputs["Object"], vor.inputs["Vector"])
    cr = n.new("ShaderNodeMapRange")
    cr.inputs["From Min"].default_value = 0.0
    cr.inputs["From Max"].default_value = 0.75
    cr.inputs["To Min"].default_value = 1.15
    cr.inputs["To Max"].default_value = 0.65
    L.new(vor.outputs["Distance"], cr.inputs["Value"])
    k = n.new("ShaderNodeMix")
    k.data_type = "FLOAT"
    L.new(can.outputs["Fac"], k.inputs[0])
    k.inputs[2].default_value = 1.0
    L.new(cr.outputs["Result"], k.inputs[3])
    mul = n.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs[0].default_value = 1.0
    L.new(at.outputs["Color"], mul.inputs[6])
    cv = n.new("ShaderNodeCombineColor")
    for i in range(3):
        L.new(k.outputs[0], cv.inputs[i])
    L.new(cv.outputs[0], mul.inputs[7])
    # --- gradonii
    geo = n.new("ShaderNodeNewGeometry")
    sepn = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["True Normal"], sepn.inputs[0])
    face = n.new("ShaderNodeMapRange")                 # 1 pe fata abrupta
    face.inputs["From Min"].default_value = 0.75
    face.inputs["From Max"].default_value = 0.55
    L.new(sepn.outputs[2], face.inputs["Value"])
    wave = n.new("ShaderNodeTexWave")
    wave.wave_type = "BANDS"
    wave.bands_direction = "Z"
    wave.inputs["Scale"].default_value = 0.025         # Wave x20: o banda la ~2 m
    wave.inputs["Distortion"].default_value = 0.6
    L.new(tc.outputs["Object"], wave.inputs["Vector"])
    strip = n.new("ShaderNodeValToRGB")
    els = strip.color_ramp.elements
    els[0].position, els[0].color = 0.35, srgb(MARBLE_B)
    els[1].position, els[1].color = 0.65, srgb(MARBLE)
    L.new(wave.outputs["Fac"], strip.inputs["Fac"])
    # dare de rugina: zgomot alungit pe verticala, rar
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.5, 0.5, 0.04)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nzr = n.new("ShaderNodeTexNoise")
    nzr.inputs["Scale"].default_value = 1.2
    nzr.inputs["Detail"].default_value = 3.0
    L.new(mp.outputs[0], nzr.inputs["Vector"])
    rr = n.new("ShaderNodeMapRange")
    rr.inputs["From Min"].default_value = 0.64
    rr.inputs["From Max"].default_value = 0.76
    rr.inputs["To Max"].default_value = 0.55
    L.new(nzr.outputs["Fac"], rr.inputs["Value"])
    rmix = n.new("ShaderNodeMix")
    rmix.data_type = "RGBA"
    L.new(rr.outputs["Result"], rmix.inputs[0])
    L.new(strip.outputs["Color"], rmix.inputs[6])
    rmix.inputs[7].default_value = srgb(RUST)
    fmix = n.new("ShaderNodeMix")                      # fata / prag
    fmix.data_type = "RGBA"
    L.new(face.outputs["Result"], fmix.inputs[0])
    fmix.inputs[6].default_value = srgb(TREAD)
    L.new(rmix.outputs[2], fmix.inputs[7])
    qw = n.new("ShaderNodeMapRange")
    qw.inputs["From Min"].default_value = 0.35
    qw.inputs["From Max"].default_value = 0.7
    L.new(qa.outputs["Fac"], qw.inputs["Value"])
    qmix = n.new("ShaderNodeMix")
    qmix.data_type = "RGBA"
    L.new(qw.outputs["Result"], qmix.inputs[0])
    L.new(mul.outputs[2], qmix.inputs[6])
    L.new(fmix.outputs[2], qmix.inputs[7])
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(qmix.outputs[2], bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out, near_socket=na.outputs["Fac"])
    return mat


def sea_material():
    """Marea Ligurica: albastru adanc, mai palid spre larg (Fresnel = cerul cald
    reflectat la unghi razant), luminat doar de aer — fara sclipiri: reflexia
    soarelui (22 de grade) cade la -22 de grade, sub banda."""
    mat, nt, out = new_material("BandSea")
    n, L = nt.nodes, nt.links
    cam = n.new("ShaderNodeCameraData")
    dr = n.new("ShaderNodeMapRange")
    dr.inputs["From Min"].default_value = 7000.0
    dr.inputs["From Max"].default_value = 30000.0
    L.new(cam.outputs["View Distance"], dr.inputs["Value"])
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / 1800.0, 1.0 / 400.0, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 1.0
    nz.inputs["Detail"].default_value = 3.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    vr = n.new("ShaderNodeValToRGB")
    els = vr.color_ramp.elements
    els[0].position, els[0].color = 0.35, srgb(SEA)
    els[1].position, els[1].color = 0.65, srgb(SEA_NEAR)
    L.new(nz.outputs["Fac"], vr.inputs["Fac"])
    sheen = n.new("ShaderNodeMix")
    sheen.data_type = "RGBA"
    L.new(dr.outputs["Result"], sheen.inputs[0])
    L.new(vr.outputs["Color"], sheen.inputs[6])
    sheen.inputs[7].default_value = srgb("6F93B5")
    em = n.new("ShaderNodeEmission")
    L.new(sheen.outputs[2], em.inputs["Color"])
    em.inputs["Strength"].default_value = 0.85
    haze_wrap(nt, em.outputs[0], out, haze_k=SEA_HAZE_K)
    return mat


def plane(name, z, mat, s=80000.0):
    me = bpy.data.meshes.new(name)
    me.from_pydata([(-s, -s, z), (s, -s, z), (s, s, z), (-s, s, z)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


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
    from mathutils import Vector
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
    cd.clip_end = 120000.0
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
    print("banda: soarele la busola %.1f, elevatie %.1f" % (
        math.degrees(math.atan2(sd.x, sd.y)) % 360.0, math.degrees(math.asin(sd.z))))

    # Lumina de umplere ORIZONTALA, calda-palida, din partea opusa soarelui (busola
    # 10): in joc ambientul vine din cerul temei, iar sub orizont cerul e banda insasi
    # (marmura, praf). Fara ea, flancurile in contre-jour spre S ieseau mai inchise
    # decat stanca 3D cetoasa din fata (lectia MV).
    fd = bpy.data.lights.new("BandFill", "SUN")
    fd.energy = FILL_STRENGTH
    fd.color = srgb(FILL_COLOR)[:3]
    fd.angle = math.radians(6.0)
    fill = bpy.data.objects.new("BandFill", fd)
    bpy.context.collection.objects.link(fill)
    fa = math.radians(FILL_AZ)
    fill.rotation_euler = (-Vector((math.sin(fa), math.cos(fa), 0.05)).normalized()
                           ).to_track_quat("-Z", "Y").to_euler()

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
        vs = [(x + dx * s, y + dy * s, CAM_Z + 40 + dz * s) for dx in (-1, 1) for dy in (-1, 1)
              for dz in (-1, 1)]
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
peaks = make_peaks(random.Random(23))
setup_render()
plane("BandSea", SEA_Z, sea_material())
build_land(peaks)
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
