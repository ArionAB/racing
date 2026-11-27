"""Banda de orizont a cerului Kyoto (Track18) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/kyoto_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa:
dealurile impadurite care inconjoara bazinul Kyoto la sfarsitul lui noiembrie —
Higashiyama spre EST (cupole joase, rotunde, „ca un om culcat sub plapuma”, cu
Hiei-zan in spate, spre NE), Kitayama spre NORD (creste suprapuse de cedri,
inchise la culoare), Arashiyama / Nishiyama spre VEST (mai abrupte, cele mai
colorate) si spre SUD bazinul orasului, cu acoperisuri joase de kawara, pana la
dealurile joase de la Fushimi si Otokoyama. Padurea e AMESTECATA: cedri si
chiparosi verde-inchis, intre ei artari carmin / rosu-portocaliu / ruginii si
cate un ginkgo auriu, coroana cu coroana. Pe coaste, cateva pagode si
acoperisuri de templu mici, razlete. In vai, ceata joasa, calda. Cerul ramane
TRANSPARENT: gradientul lui il deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Ha Long / Monument Valley / Machu Picchu. Ce e specific aici:

  * IMBINAREA e ceata joasa din vai. Kyoto e pista de USCAT, iar ceata jocului
    e pacla calda a dupa-amiezii (`fog` E9D6BC, fog_max 0,85 la fog_end 340 m):
    marginea terenului real iese pe linia orizontului ca o fasie de pacla
    (233, 220, 198). Picioarele dealurilor din banda stau in ceata joasa de
    aceeasi culoare (`MIST`, K * exp(-z/H), tot mai deasa spre orizont), deci
    fasia continua in ceata din vai si dealurile ies curate din ea (ceata
    sta jos). Aproape (sub 1 km, vazut doar de sus, de pe scena) ceata e pe
    jumatate: acolo se vad campurile olive si acoperisurile orasului.
    `below` = randul de jos; `fog` ramane pacla temei (vezi tema).
  * Padurea se coloreaza COROANA CU COROANA, in shader: celulele unui Voronoi
    de ~6,5 m (`CROWN_M`) in coordonate de lume sunt arbori; culoarea aleatoare a celulei
    alege specia (artar vs cedru) dupa atributul `autumn` din fiecare varf
    (cat de rosie e coasta aici) si apoi tenta din paleta kitului. Asa citeste
    ca padurea punctata din joc, nu ca pete de camuflaj.
  * Planul 0 (`NEAR_GIANTS`): opt umeri de deal APROPIATI (0,64-0,82 km),
    pusi de mana pe directiile in care priveste camera pe portiunile lungi
    (sonda pe Track18.baked), care urca 3-9 grade si dau scara (lectia MV, #763).

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste fundul bazinului, in origine; u = 0,5 priveste spre
    NORD (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in
    shader (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "kyoto" (`sun_rotation_deg` (-22, -45, 0), acelasi in
    Track18.tscn: busola 225, SV, 22 de grade), `sun_color` FFD8A8, energia 1,0;
    ambientul B4C8E6 la 0,35;
  * HAZE = `sky_horizon` din tema (F2E2C2): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_sky_band.py [-- --test]
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
# Ochiul peste fundul bazinului. Camera de joc sta la ~10 m peste drum, iar drumul
# urca pe coasta Higashiyama (scena Kiyomizu, Tsutenkyo): fata de terenul de la
# 340 m camera e cu 3-30 m mai sus, de obicei 10-25 (sonda pe Track18.baked). Cu
# 20 m, -7,5 grade cade pe sol la ~150 m, adica SUB terenul jocului: banda
# incepe acolo unde se termina el, oricat de sus ar fi camera.
CAM_Z = 20.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "kyoto_horizon_band_test.png" if TEST
                   else "kyoto_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB, din tema "kyoto" si brief §1 / §4) ---------------------------
HAZE = "F2E2C2"          # = sky_horizon din tema: departarea intra in cer
# Ceata joasa din vai = pacla jocului (`fog` E9D6BC): la marginea de jos a benzii
# terenul cetos al jocului intra in ea fara dunga.
MIST = "F0DCC2"
# Coroanele: albedo, nu culoarea pe ecran. Artarii din paleta kitului (brief §1:
# carmin BB3522, rosu-portocaliu E54839, ruginiu A8683A, ginkgo F2D03C), putin
# trase spre brun, fiindca o coroana intreaga are umbra proprie si golurile
# dintre frunze (folosite ca atare: haze-ul le inchide deja); cedrii / chiparosii hinoki verde-inchis, cu un oliv (zelkova
# care se ingalbeneste) printre ei.
MAPLE = [(0.00, "BB3522"), (0.34, "D8492F"), (0.60, "A8683A"), (0.93, "E2B43A")]
CEDAR = [(0.00, "22381F"), (0.40, "2B4426"), (0.70, "37502C"), (0.90, "56602F")]
# Solul bazinului (unde nu e padure): miriste de orez, gradini, curti.
FIELD = ["8E9058", "848750", "969060"]
# Kawara (ASPHALT_EDGE #696765 din kit), var alb, lemn de machiya, vermilion.
ROOF = "5E5D5C"
ROOF_DARK = "4C4B4C"
WALL = "B9B6AC"
WOOD = "4A3526"
VERMILION = "D85A2C"
SUN_COLOR = "FFD8A8"
# Godot inmulteste energia luminii cu pi (alb lambertian perpendicular = energia);
# Cycles nu. Deci taria Cycles = pi x energia temei (masurat pe MV, #761).
SUN_STRENGTH = math.pi * 1.0
AMBIENT = "B4C8E6"
AMBIENT_ENERGY = 0.35
SUN_ROT = (-22.0, -45.0)                   # sun_rotation_deg (x, y) din tema
# Umplere din partea opusa soarelui (busola 45): lumina intoarsa de bazinul
# cetos. Fara ea coastele din contre-jour (spre SV, soarele in spate) ies negre.
FILL_COLOR = "E9D6BC"
FILL_AZ, FILL_STRENGTH = 45.0, 0.9

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului incolo; F0 = cat a spalat deja ceata jocului la fog_end. Pacla de
# toamna peste un oras: mai groasa decat aerul de desert al MV.
HAZE_D0, HAZE_D, HAZE_F0 = 340.0, 9000.0, 0.16
HAZE_MAX = 0.80
# Ceata joasa: K * exp(-z / H) * f(d). f creste cu distanta de la MIST_NEAR (la
# MIST_R0) la 1 (la MIST_R1). Linia de orizont a jocului e deja o fasie de ceata:
# marginea terenului (umarul exterior, la 340-380 m) iese pe captura (230, 217,
# 194), adica fog_max din `fog`. Picioarele dealurilor din banda stau deci in
# ceata de ACEEASI culoare, ca fasia aceea sa continue in banda in loc sa fie o
# dunga alba intre teren si dealuri (v5, ceata subtiata, o arata ca dunga).
# Aproape (sub 1 km, vazut doar de sus, de pe scena) ceata e pe jumatate.
MIST_H, MIST_K = 18.0, 0.92
MIST_R0, MIST_R1, MIST_NEAR = 300.0, 1600.0, 0.50

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
    """Inaltimea (peste fundul bazinului) care sta la `theta_deg` peste ochi la d."""
    return CAM_Z + d * math.tan(math.radians(theta_deg))


# --- Dealurile ---------------------------------------------------------------------
#
# Fiecare deal: (x, y, h, R, a, b, autumn, plane, rot, ecc). Cupola:
# z = h (1 - s^a)^b, s = r / R; a 1,6-2,4 = varf rotund (Higashiyama), b > 1 =
# picior lung, concav. `autumn` = cat de rosie e padurea pe el (0 = cedri).
#
# Planul 0, pus de mana: (azimut busola, distanta, unghi varf peste ochi, R/h,
# autumn). Azimuturile vin din sonda pe Track18.baked (camera de joc), vezi tema.
# Directiile camerei pe portiunile lungi (sonda): N 0-19 (startul spre pagoda
# Yasaka 0,00-0,07 si finalul 0,81-0,99), E 84-90 (urcarea 0,09-0,25), S 150-210
# (scena, Tsutenkyo, Inari 0,26-0,52), V/SV 208-290 (coborarea si bambusul
# 0,53-0,74), NV 287-348 (0,75-0,80). Uriasii stau la 10-15 grade de axe; sudul
# (150-215) ramane DESCHIS: acolo e bazinul cu orasul, vazut de pe scena.
NEAR_GIANTS = [
    (33.0, 760.0, 6.5, 2.4, 0.40),    # N-NE: Higashiyama de nord, dreapta finalului
    (70.0, 680.0, 7.5, 2.4, 0.50),    # urcarea spre E, stanga
    (103.0, 640.0, 8.5, 2.3, 0.50),   # urcarea spre E, dreapta
    (136.0, 720.0, 7.0, 2.4, 0.45),   # Inari-yama: stanga dreptelor spre S
    (226.0, 800.0, 7.5, 2.0, 0.60),   # Arashiyama: SV, dreapta lui 0,66-0,71
    (268.0, 720.0, 8.0, 2.0, 0.60),   # V, intre axele coborarii
    (312.0, 780.0, 6.5, 2.3, 0.35),   # NV, intre 297 si 332
    (352.0, 820.0, 6.0, 2.5, 0.30),   # N: Kitayama, stanga startului / finalului
]

# Poalele: o creasta joasa si lunga la 0,85-1,3 km, in spatele uriasilor si in
# golurile dintre ei, pe tot conturul cu dealuri (N, E, V). Fara ea, printre
# uriasi se vedea fundul plat al bazinului pana la orizont, adica o fasie alba de
# ceata intre terenul jocului si dealuri (v4, 0,88). Spre S lipseste: acolo e
# bazinul cu orasul, care chiar se vede pana departe de pe scena.
FOOT = (850.0, 1300.0, 1.4, 3.4, 4.0, 8.0, 3.0, 4.2, 1.8, 2.6, 0.45)

# Sectoarele lumii (busola): (az_min, az_max, nume, planuri). Fiecare plan:
# (d_min, d_max, theta_min, theta_max, pas de azimut min/max, R/h min/max,
#  forma a min/max, autumn).
REGIONS = [
    # Higashiyama: lant de cupole joase, aproape, rosii pe poale; Hiei-zan in spate.
    (20.0, 150.0, "higashiyama", [
        FOOT,
        (1000.0, 1800.0, 4.0, 7.0, 6.0, 11.0, 2.2, 3.0, 1.8, 2.6, 0.45),
        (2200.0, 3800.0, 3.4, 5.6, 6.0, 12.0, 2.4, 3.2, 1.7, 2.4, 0.35),
        (5000.0, 9000.0, 3.0, 5.0, 7.0, 14.0, 2.6, 3.6, 1.5, 2.2, 0.20),
    ]),
    # Kitayama: creste suprapuse de cedri (sugi), inchise; poalele mai rosii.
    (290.0, 380.0, "kitayama", [
        FOOT,
        (1100.0, 2000.0, 3.6, 6.0, 6.0, 12.0, 2.4, 3.2, 1.6, 2.2, 0.28),
        (2500.0, 4500.0, 3.4, 5.6, 5.0, 10.0, 2.4, 3.2, 1.4, 2.0, 0.15),
        (5500.0, 9000.0, 3.2, 5.2, 5.0, 10.0, 2.6, 3.4, 1.4, 2.0, 0.08),
        (10000.0, 15000.0, 3.0, 4.6, 5.0, 10.0, 2.8, 3.6, 1.4, 2.0, 0.05),
    ]),
    # Arashiyama / Nishiyama: mai abrupte, cele mai colorate; Atago spre NV.
    (215.0, 290.0, "arashiyama", [
        FOOT,
        (1000.0, 1900.0, 4.0, 7.5, 6.0, 11.0, 1.7, 2.4, 1.5, 2.0, 0.60),
        (2300.0, 4200.0, 3.6, 6.0, 6.0, 12.0, 1.9, 2.6, 1.5, 2.0, 0.40),
        (6000.0, 11000.0, 3.2, 5.2, 6.0, 12.0, 2.2, 3.0, 1.4, 2.0, 0.15),
    ]),
    # Sudul: bazinul cu orasul; departe doar dealurile joase de la Fushimi /
    # Otokoyama, abia peste orizont.
    (150.0, 215.0, "bazin", [
        (9000.0, 16000.0, 1.6, 2.8, 7.0, 14.0, 3.0, 4.2, 1.6, 2.4, 0.20),
    ]),
]
# Hiei-zan: cel mai inalt deal al bazinului (848 m), la NE, departe, albastrui.
HIEI = (40.0, 8000.0, 6.0, 2.6)

# Pagode (busola, distanta, inaltime m, vermilion?) si temple (busola, distanta,
# latime m): mici, razlete, pe poalele coastelor. NU pe directiile reperelor 3D
# reale ale pistei (pagoda Yasaka, pagoda Koyasu, Kinkaku-ji) — completat dupa sonda.
PAGODAS = [
    (78.0, 1500.0, 40.0, True),
    (128.0, 2100.0, 44.0, False),
    (197.0, 3400.0, 55.0, False),     # To-ji, in oras, cea mai inalta din Japonia
    (262.0, 1700.0, 32.0, True),
    (318.0, 1900.0, 30.0, False),
]
TEMPLES = [
    (52.0, 1250.0, 34.0), (92.0, 1100.0, 40.0), (110.0, 1700.0, 30.0),
    (140.0, 1300.0, 36.0), (238.0, 1500.0, 32.0), (275.0, 1300.0, 28.0),
    (300.0, 1600.0, 30.0), (342.0, 1400.0, 34.0), (20.0, 1800.0, 30.0),
    (168.0, 2600.0, 46.0), (205.0, 2200.0, 38.0),
]
# Orasul: sectorul de sud al bazinului (si poalele dintre dealuri), case joase.
CITY_AZ = (115.0, 250.0)
CITY_R = (420.0, 7000.0)


def polar(az_deg, d):
    a = math.radians(az_deg)
    return math.sin(a) * d, math.cos(a) * d      # Blender: x est, y nord


def region_of(az):
    a = az % 360.0
    for a0, a1, name, planes in REGIONS:
        if a0 <= a < a1 or a0 <= a + 360.0 < a1:
            return name
    return None


def hill(hills, rng, x, y, h, R, a, b, autumn, plane, sats=(1, 2)):
    """Un deal principal + 1-2 umeri lipiti de el. Elipsa e intinsa de-a
    CURMEZISUL privirii (tangent la cercul din jurul camerei), iar umerii stau
    tot pe tangenta: asa iese o CREASTA lunga, cum e Higashiyama, nu o movila
    rotunda pusa singura („gumdrop”, prima randare)."""
    tang = math.atan2(-x, y)                 # directia tangenta, in radiani
    rot = tang + rng.uniform(-0.35, 0.35)
    ecc = rng.uniform(0.40, 0.65)
    hills.append((x, y, h, R, a, b, autumn, plane, rot, ecc))
    for _ in range(rng.randint(*sats)):
        ang = tang + rng.choice((0.0, math.pi)) + rng.uniform(-0.5, 0.5)
        off = R * rng.uniform(0.45, 0.85)
        f = rng.uniform(0.55, 0.85)
        hills.append((x + math.cos(ang) * off, y + math.sin(ang) * off, h * f,
                      R * f * rng.uniform(0.85, 1.1), a * rng.uniform(0.9, 1.1),
                      b, autumn, plane, tang + rng.uniform(-0.5, 0.5),
                      rng.uniform(0.40, 0.75)))


def make_hills(rng):
    hills = []
    for az, d, th, rk, aut in NEAR_GIANTS:
        x, y = polar(az, d)
        h = h_for(d, th)
        hill(hills, rng, x, y, h, h * rk, 2.0, 1.6, aut, 0)
    for a0, a1, name, planes in REGIONS:
        for pi_, (d0, d1, t0, t1, s0, s1, r0, r1, f0, f1, aut) in enumerate(planes):
            az = a0 + rng.uniform(0.0, s0)
            while az < a1:
                d = rng.uniform(d0, d1)
                th = rng.uniform(t0, t1)
                h = h_for(d, th)
                x, y = polar(az % 360.0, d)
                hill(hills, rng, x, y, h, h * rng.uniform(r0, r1),
                     rng.uniform(f0, f1), rng.uniform(1.2, 1.7), aut, pi_ + 1)
                az += rng.uniform(s0, s1)
    az, d, th, rk = HIEI
    x, y = polar(az, d)
    hill(hills, rng, x, y, h_for(d, th), h_for(d, th) * rk, 1.8, 1.5, 0.12, 4, sats=(2, 3))
    return hills


# --- Scena -----------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node):
    """surface -> amestec cu HAZE dupa distanta si cu MIST dupa inaltime (ceata
    joasa, de la marginea de jos a benzii incolo)."""
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
    # culoarea voalului: MIST unde domina ceata joasa, HAZE in rest
    share = math_node("DIVIDE", mist, math_node("MAXIMUM", fac, vb=1e-4))
    share = math_node("MINIMUM", share, vb=1.0)
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(HAZE)
    cmix.inputs[7].default_value = srgb(MIST)
    L.new(share, cmix.inputs[0])
    em = n.new("ShaderNodeEmission")
    L.new(cmix.outputs[2], em.inputs["Color"])
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
    """Culoarea de baza e in vertex color (sol, cladiri); unde atributul `canopy`
    e 1, padurea se coloreaza coroana cu coroana: celula Voronoi (~9 m) = un
    arbore; R-ul aleator al celulei < `autumn` -> artar (tenta din MAPLE dupa G),
    altfel cedru (tenta din CEDAR dupa B). Distanta F1 da rotunjimea coroanei
    (centru luminat, margine inchisa)."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    can = n.new("ShaderNodeAttribute")
    can.attribute_name = "canopy"
    can.attribute_type = "GEOMETRY"
    aut = n.new("ShaderNodeAttribute")
    aut.attribute_name = "autumn"
    aut.attribute_type = "GEOMETRY"
    tc = n.new("ShaderNodeTexCoord")
    vor = n.new("ShaderNodeTexVoronoi")
    vor.feature = "F1"
    vor.inputs["Scale"].default_value = 1.0 / CROWN_M
    vor.inputs["Randomness"].default_value = 0.9
    L.new(tc.outputs["Object"], vor.inputs["Vector"])
    sc = n.new("ShaderNodeSeparateColor")
    L.new(vor.outputs["Color"], sc.inputs[0])
    maple = const_ramp(n, MAPLE)
    L.new(sc.outputs[1], maple.inputs["Fac"])
    cedar = const_ramp(n, CEDAR)
    L.new(sc.outputs[2], cedar.inputs["Fac"])
    is_maple = n.new("ShaderNodeMath")
    is_maple.operation = "LESS_THAN"
    L.new(sc.outputs[0], is_maple.inputs[0])
    L.new(aut.outputs["Fac"], is_maple.inputs[1])
    tree = n.new("ShaderNodeMix")
    tree.data_type = "RGBA"
    L.new(is_maple.outputs[0], tree.inputs[0])
    L.new(cedar.outputs["Color"], tree.inputs[6])
    L.new(maple.outputs["Color"], tree.inputs[7])
    # coroana: centrul luminat, marginea inchisa (distanta F1 0 -> 0,75)
    cr = n.new("ShaderNodeMapRange")
    cr.inputs["From Min"].default_value = 0.0
    cr.inputs["From Max"].default_value = 0.75
    cr.inputs["To Min"].default_value = 1.15
    cr.inputs["To Max"].default_value = 0.55
    L.new(vor.outputs["Distance"], cr.inputs["Value"])
    shade = n.new("ShaderNodeMix")
    shade.data_type = "RGBA"
    shade.blend_type = "MULTIPLY"
    shade.inputs[0].default_value = 1.0
    L.new(tree.outputs[2], shade.inputs[6])
    cv = n.new("ShaderNodeCombineColor")
    for i in range(3):
        L.new(cr.outputs["Result"], cv.inputs[i])
    L.new(cv.outputs[0], shade.inputs[7])
    # tonul mare al coastei (umezeala, ravene) din vertex color, ca multiplicator
    tone = n.new("ShaderNodeMix")
    tone.data_type = "RGBA"
    tone.blend_type = "MULTIPLY"
    tone.inputs[0].default_value = 1.0
    L.new(shade.outputs[2], tone.inputs[6])
    L.new(at.outputs["Color"], tone.inputs[7])
    albedo = n.new("ShaderNodeMix")
    albedo.data_type = "RGBA"
    L.new(can.outputs["Fac"], albedo.inputs[0])
    L.new(at.outputs["Color"], albedo.inputs[6])
    L.new(tone.outputs[2], albedo.inputs[7])
    # relieful coroanei: o calota pe fiecare celula (bump), ca soarele de 22 de
    # grade sa lumineze partea de SV a fiecarui arbore si sa umbreasca restul
    hgt = n.new("ShaderNodeMath")
    hgt.operation = "MULTIPLY"
    L.new(vor.outputs["Distance"], hgt.inputs[0])
    L.new(can.outputs["Fac"], hgt.inputs[1])
    bump = n.new("ShaderNodeBump")
    bump.invert = True
    bump.inputs["Strength"].default_value = 0.9
    bump.inputs["Distance"].default_value = CROWN_M * 0.6
    L.new(hgt.outputs[0], bump.inputs["Height"])
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(albedo.outputs[2], bsdf.inputs["Color"])
    L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


# --- Relieful: camp de inaltimi polar ------------------------------------------

CROWN_M = 6.5           # latimea unei coroane (celula Voronoi), m
N_AZ = 1024 if TEST else 4096
N_R = 140 if TEST else 460
R0, R1 = 130.0, 22000.0
FLOOR_Z = 0.0            # fundul bazinului


def heights(px, py, hills):
    z = np.full(px.shape, FLOOR_Z, dtype=np.float64)
    autumn = np.full(px.shape, 0.4)
    hm = np.full(px.shape, 1.0)
    for i, (x0, y0, h, R, pa, pb, aut, pl, rot, ecc) in enumerate(hills):
        m = (np.abs(px - x0) < R * 1.3) & (np.abs(py - y0) < R * 1.3)
        if not m.any():
            continue
        qx, qy = px[m], py[m]
        dx, dy = qx - x0, qy - y0
        ex = dx * math.cos(rot) + dy * math.sin(rot)
        ey = (-dx * math.sin(rot) + dy * math.cos(rot)) / ecc
        r = np.hypot(ex, ey)
        ang = np.arctan2(dy, dx)
        lobe = (vnoise(np.cos(ang) * 2.5 + i * 7.1, np.sin(ang) * 2.5, 1.0, 900 + i) - 0.5)
        rr = r / (R * (1.0 + 0.30 * lobe))
        s = np.clip(rr, 0.0, 1.0)
        zk = FLOOR_Z + (h - FLOOR_Z) * np.power(1.0 - np.power(s, pa), pb)
        # ravene pe flancuri: silueta usor ondulata, nu palarie
        jag = fbm(qx, qy, R * 0.5, 2000 + i, octaves=3, ridged=True)
        zk = zk + (jag - 0.45) * 0.12 * (h - FLOOR_Z) * np.sqrt(np.clip(1.0 - s, 0.0, 1.0)) * s * 2.0
        better = zk > z[m]
        z[m] = np.where(better, zk, z[m])
        autumn[m] = np.where(better, aut, autumn[m])
        hm[m] = np.where(better, h, hm[m])
    # ravene fine (zgomot ridged), proportional cu cota
    rid = fbm(px, py, 140.0, 18, octaves=4, ridged=True)
    z += (rid - 0.45) * 0.10 * np.maximum(z - FLOOR_Z, 0.0)
    # linia coroanelor: muchia unui deal impadurit nu e neteda (cotul 4-6 m al
    # arborilor), altfel silueta citeste a plastic
    tops = fbm(px, py, 14.0, 23, octaves=2)
    z += (tops - 0.5) * 7.0 * smoothstep(6.0, 20.0, z - FLOOR_Z)
    return z, autumn, hm


def lin(hx):
    return np.array(srgb(hx)[:3])


def build_land(hills):
    az = np.linspace(0.0, math.tau, N_AZ, endpoint=False)
    rr = R0 * np.power(R1 / R0, np.linspace(0.0, 1.0, N_R))
    A, Rg = np.meshgrid(az, rr)                     # (N_R, N_AZ)
    px = np.sin(A) * Rg
    py = np.cos(A) * Rg
    z, autumn, hm = heights(px, py, hills)
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

    hrel = np.clip((z - FLOOR_Z) / np.maximum(hm - FLOOR_Z, 1.0), 0.0, 1.2)
    # padurea incepe putin peste fundul bazinului (poalele sunt gradini, sate)
    canopy = smoothstep(4.0, 14.0, z - FLOOR_Z)
    # tonul mare al coastei: ravenele mai inchise, crestele putin mai luminate
    gully = smoothstep(0.55, 0.85, fbm(px, py, 150.0, 15, octaves=4, ridged=True))
    tone = 0.80 + 0.20 * gully + 0.08 * (fbm(px, py, 90.0, 71, octaves=2) - 0.5)
    # artarii coboara pe poale si pe ravene; crestele sunt mai mult cedru
    # Artarii stau in PLCURI (gradini de templu, vai umede), cedrii in arborete
    # intinse: fara petice, coasta iesea „cu buline” uniforme (prima randare).
    aut = autumn * (1.3 - 0.6 * smoothstep(0.35, 0.95, hrel))
    grove = smoothstep(0.42, 0.62, fbm(px, py, 180.0, 41, octaves=3))
    aut = aut * (0.25 + 1.5 * grove)
    aut = np.clip(aut * (0.85 + 0.3 * (1.0 - gully)), 0.0, 0.92)
    # solul bazinului: miriste / gradini pe petice
    fi = np.clip((fbm(px, py, 160.0, 7, octaves=2) * len(FIELD)).astype(int), 0, len(FIELD) - 1)
    fpal = np.array([lin(c) for c in FIELD])
    ground = fpal[fi]
    tone3 = np.repeat(tone[..., None], 3, axis=-1)
    col = ground * (1.0 - canopy)[..., None] + tone3 * canopy[..., None]
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((nverts, 1))], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    at = me.attributes.new("canopy", "FLOAT", "POINT")
    at.data.foreach_set("value", canopy.astype(np.float32).ravel())
    at2 = me.attributes.new("autumn", "FLOAT", "POINT")
    at2.data.foreach_set("value", aut.astype(np.float32).ravel())
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d, %d fete, %d dealuri; artar mediu pe coaste %.2f" % (
        N_R, N_AZ, nf, len(hills), float(aut[canopy > 0.5].mean())))
    return ob


def ground_z(x, y, hills):
    z, _, _ = heights(np.array([[x]]), np.array([[y]]), hills)
    return float(z[0, 0])


# --- Cladiri (o singura plasa, culoare pe varf, atribute canopy/autumn = 0) -----

class Builder:
    def __init__(self):
        self.verts, self.faces, self.cols = [], [], []

    def _q(self, pts, col):
        b = len(self.verts)
        self.verts.extend(pts)
        self.cols.extend([col] * len(pts))
        return b

    def box(self, cx, cy, z0, sx, sy, h, rot, col):
        c, s = math.cos(rot), math.sin(rot)
        pts = []
        for dz in (0.0, h):
            for ux, uy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                lx, ly = ux * sx * 0.5, uy * sy * 0.5
                pts.append((cx + lx * c - ly * s, cy + lx * s + ly * c, z0 + dz))
        b = self._q(pts, col)
        for k in range(4):
            k1 = (k + 1) % 4
            self.faces.append((b + k, b + k1, b + 4 + k1, b + 4 + k))
        self.faces.append((b + 4, b + 5, b + 6, b + 7))

    def roof(self, cx, cy, z0, sx, sy, h, rot, col, ridge=0.35, under=None):
        """Acoperis in patru ape (irimoya simplificat): talpa sx x sy, coama
        de `ridge` din lungime; `under` = culoarea streasinii vazute de jos."""
        c, s = math.cos(rot), math.sin(rot)

        def P(lx, ly, z):
            return (cx + lx * c - ly * s, cy + lx * s + ly * c, z)
        hx, hy = sx * 0.5, sy * 0.5
        rx = hx * ridge
        pts = [P(-hx, -hy, z0), P(hx, -hy, z0), P(hx, hy, z0), P(-hx, hy, z0),
               P(-rx, 0.0, z0 + h), P(rx, 0.0, z0 + h)]
        b = self._q(pts, col)
        self.faces += [(b + 0, b + 1, b + 5, b + 4), (b + 2, b + 3, b + 4, b + 5),
                       (b + 1, b + 2, b + 5), (b + 3, b + 0, b + 4)]
        if under is not None:
            ub = self._q([P(-hx, -hy, z0 - 0.4), P(hx, -hy, z0 - 0.4),
                          P(hx, hy, z0 - 0.4), P(-hx, hy, z0 - 0.4)], under)
            self.faces.append((ub + 3, ub + 2, ub + 1, ub + 0))

    def pagoda(self, cx, cy, z0, height, vermilion, rot):
        """Cinci etaje: corp care se ingusteaza, streasina lata si subtire la
        fiecare etaj, turla (sorin) sus. Proportiile pagodei Yasaka."""
        body = srgb(VERMILION)[:3] if vermilion else srgb(WOOD)[:3]
        roof = srgb(ROOF_DARK)[:3]
        tiers = 5
        spire = height * 0.22
        th = (height - spire) / tiers
        w0 = height * 0.24
        z = z0
        self.box(cx, cy, z, w0 * 1.2, w0 * 1.2, th * 0.35, rot, srgb(WALL)[:3])  # soclu
        z += th * 0.35
        for t in range(tiers):
            w = w0 * (1.0 - 0.08 * t)
            self.box(cx, cy, z, w, w, th * 0.62, rot, body)
            z += th * 0.62
            self.roof(cx, cy, z, w * 1.9, w * 1.9, th * 0.30, rot, roof, ridge=0.08,
                      under=srgb(WOOD)[:3])
            z += th * 0.30 * 0.55
        self.box(cx, cy, z, w0 * 0.07, w0 * 0.07, spire, rot, srgb("3A3633")[:3])

    def temple(self, cx, cy, z0, width, rot):
        """Sala de templu: soclu de piatra, pereti albi/lemn, acoperis mare."""
        d = width * 0.7
        wall_h = width * 0.22
        self.box(cx, cy, z0 - 3.0, width * 1.05, d * 1.05, 4.0, rot, srgb("A9A49A")[:3])
        self.box(cx, cy, z0 + 1.0, width, d, wall_h, rot, srgb(WALL)[:3])
        self.roof(cx, cy, z0 + 1.0 + wall_h, width * 1.3, d * 1.35, width * 0.32, rot,
                  srgb(ROOF)[:3], ridge=0.55, under=srgb(WOOD)[:3])

    def house(self, cx, cy, z0, sx, sy, h, rot, wall, roof):
        self.box(cx, cy, z0, sx, sy, h, rot, wall)
        self.roof(cx, cy, z0 + h, sx * 1.12, sy * 1.15, sy * 0.32, rot, roof, ridge=0.6)

    def finish(self, name):
        me = bpy.data.meshes.new(name)
        me.from_pydata(self.verts, [], self.faces)
        me.update()
        n = len(self.verts)
        rgba = np.concatenate([np.array(self.cols), np.ones((n, 1))], axis=1)
        ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
        for nm in ("canopy", "autumn"):
            at = me.attributes.new(nm, "FLOAT", "POINT")
            at.data.foreach_set("value", np.zeros(n, dtype=np.float32))
        ob = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(ob)
        return ob


def build_town(hills, rng, mat):
    b = Builder()
    for az, d, hgt, verm in PAGODAS:
        x, y = polar(az, d)
        b.pagoda(x, y, ground_z(x, y, hills), hgt, verm, rng.uniform(0, math.pi / 2))
    for az, d, wdt in TEMPLES:
        x, y = polar(az, d)
        b.temple(x, y, ground_z(x, y, hills), wdt, rng.uniform(0, math.pi))
    # Orasul: grila veche de strazi (aliniata N-S) in sectorul de sud; casele
    # joase de lemn (machiya) cu kawara, cateva mai mari (temple de cartier).
    nh = 0
    roofs = [srgb(ROOF)[:3], srgb(ROOF_DARK)[:3], srgb("6B6966")[:3]]
    walls = [srgb(WALL)[:3], srgb(WOOD)[:3], srgb("8C7F6C")[:3], srgb("B9B2A3")[:3]]
    a0, a1 = CITY_AZ
    r0, r1 = CITY_R
    cand = []
    for _ in range(26000 if not TEST else 4000):
        u = rng.uniform(0.0, 1.0)
        d = r0 * math.pow(r1 / r0, u)
        az = rng.uniform(a0, a1)
        # marginea sectorului se destrama (sate pe poale), nu e taiata drept
        edge = min(az - a0, a1 - az)
        if edge < 25.0 and rng.uniform(0.0, 1.0) > edge / 25.0:
            continue
        cand.append(polar(az, d))
    cx = np.array([[c[0] for c in cand]])
    cy = np.array([[c[1] for c in cand]])
    zgs, _, _ = heights(cx, cy, hills)
    for (x, y), zg in zip(cand, zgs[0]):
        zg = float(zg)
        if zg > FLOOR_Z + 6.0:
            continue                     # nu pe coaste: acolo e padure
        # pe grila de strazi: pas de 14 m, strazi de 6 m
        gx, gy = round(x / 14.0) * 14.0, round(y / 14.0) * 14.0
        big = rng.uniform(0.0, 1.0) < 0.04
        sx = rng.uniform(16.0, 26.0) if big else rng.uniform(7.0, 11.0)
        sy = rng.uniform(12.0, 18.0) if big else rng.uniform(6.0, 9.0)
        hh = rng.uniform(7.0, 10.0) if big else rng.uniform(4.0, 7.5)
        rot = (math.pi / 2.0) * rng.randint(0, 1)
        b.house(gx, gy, zg, sx, sy, hh, rot, walls[rng.randint(0, len(walls) - 1)],
                roofs[rng.randint(0, len(roofs) - 1)])
        nh += 1
    ob = b.finish("BandTown")
    ob.data.materials.append(mat)
    print("banda: %d pagode, %d temple, %d case" % (len(PAGODAS), len(TEMPLES), nh))


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
    sc.cycles.transparent_max_bounces = 8
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
    sun.rotation_euler = (-sun_dir_blender()).to_track_quat("-Z", "Y").to_euler()

    from mathutils import Vector
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
    """Cuburi emisive pe punctele cardinale, la 800 m: rosu E, verde N, albastru V."""
    for name, (x, y), col in (("E", (800, 0), (1, 0, 0, 1)), ("N", (0, 800), (0, 1, 0, 1)),
                              ("V", (-800, 0), (0, 0, 1, 1))):
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
rng = random.Random(18)
hills = make_hills(rng)
setup_render()
land = build_land(hills)
build_town(hills, random.Random(181), land.data.materials[0])
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
