"""Banda de orizont a cerului Stromboli (Track11) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/stromboli_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa: Marea
Tireniana albastru-adanc pana la orizont, celelalte Insule Eoliene in larg si coasta
Siciliei / Calabriei foarte palida in fund; cerul ramane TRANSPARENT, fiindca
gradientul lui il deseneaza shaderul de cer din joc (`scenes/tracks/sky_band.gdshader`).
Banda e lipita de cer, deci sta la infinit: nu intra in frustum, nu costa
triunghiuri si nu e taiata de FAR_PLANE (380 m).

Ce NU e in banda, dinadins:
  * VULCANUL. Pista urca pe el (buza craterului la 60 m), deci conul e relief real
    in fiecare cadru; un al doilea Stromboli pictat ar fi o oglinda. Fumul lui e
    particule in joc.
  * STROMBOLICCHIO. E piesa 3D (`strombolicchio.glb`, ~200 m in larg, sub fog_end).

Ce e, de aproape spre departe (toate pozitiile in `ISLANDS` / `MAINLAND`):
  * planul APROPIAT (1,3-2,6 km): stancile din jurul Panareei — Basiluzzo (masa
    plata cu pereti), Dattilo, Lisca Bianca — si Panarea insasi, cu satul alb pe
    tarm. Ele dau SCARA: urca 3-6 grade, adica umplu fereastra pe care o vede
    camera de joc deasupra orizontului (~5 grade).
  * Salina cu cele DOUA conuri si saua dintre ele (4-5 km), verde.
  * Lipari (pereti albi de piatra ponce pe tarm, orasul), Vulcano (craterul
    trunchiat ocru-sulf), Filicudi si Alicudi — tot mai palide.
  * Capul Calabriei (Capo Vaticano / Tropea, cu orasul pe faleza) adus la 6 km,
    pe dreapta lungii drepte de pe coasta de est.
  * Coasta Calabriei si a Siciliei, cu Etna, la 24-34 km: aproape aer.
Distantele sunt de DIORAMA, nu de harta (Panarea e la 20 km in realitate, adica
un grad pe cer): ordinea si siluetele sunt cele adevarate, scara e cea care se
vede din camera de joc. Ordinea pe busola urmeaza geografia rotita la fel ca
pista (Strombolicchio, in realitate la NE de crater, e la N in Track11, deci
busola reala - 45 = busola jocului), apoi intinsa ca planul apropiat sa cada pe
directiile pe care priveste camera.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste mare, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "stromboli" (`sun_rotation_deg` (-46, 210, 0), adica
    busola 330, NNV, 46 de grade elevatie), `sun_color` (1.0, 0.98, 0.95),
    energia 0,95; ambientul 9FB0BF la 0,34;
  * HAZE = `sky_horizon` din tema: departarea se topeste exact in culoarea pe
    care o deseneaza cerul din joc in spatele benzii, deci marginea benzii nu
    se vede;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_stromboli_sky_band.py [-- --test]
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
# Soseaua sta la 1,5-60 m peste mare, camera de joc cu 10 m mai sus: ochiul e la
# ~12-70 m. 30 e mijlocul; la kilometri diferenta e sub un grad.
CAM_Z = 30.0
SAMPLES = 16 if TEST else 160
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "stromboli_horizon_band_test.png" if TEST else "stromboli_horizon_band.png")
RES = 0.35 if TEST else 1.0              # rezolutia plaselor de insula


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


# --- Paleta (sRGB, ca in tema) ------------------------------------------------
HAZE = "DBE3E0"          # = sky_horizon din tema (0.86, 0.89, 0.88)
MIST = "E2E7E5"          # foschia joasa de pe mare, departe: un pic mai alba
# Tireniana adanca la marginea de jos = apa jocului la FAR_PLANE, masurata pe
# ecran de pe buza craterului: (39, 52, 71) pe axa, (55-73, 68-89, 84-103) spre
# margini (apa jocului isi schimba luciul cu unghiul). Textura e MAI STINSA decat
# ecranul: Environment-ul jocului ridica saturatia (adjustment 1,18 + contrast +
# Filmic), iar cerul trece prin el ca orice altceva — (47, 74, 100) iesea
# (42, 91, 135), o dunga mai vie deasupra apei reale; (42, 59, 76) iesea
# (42, 70, 100), dar marea pictata devenea plumburie. Aici e mijlocul, iar
# departarea (SEA_FAR) aduce albastrul adanc inapoi.
SEA = "2D4358"
SEA_FAR = "3F6590"       # spre orizont marea prinde cerul (Fresnel), mai deschisa
# Tufarisul mediteranean (macchia): masliniu prafuit, nu verdele tropical.
MACCHIA = ["4B5634", "56603A", "414B2E", "62693F", "3A4429"]
TERRACE = "7B7A4C"       # terasele de capere/vita, mai palide
WOOD = "34452A"          # castanii de pe varfurile Salinei
SCRUB = "7A6C58"         # tufaris uscat, roca cu iarba arsa
ROCK = "5A524C"          # bazalt / andezit in lumina
ROCK_DARK = "34302E"     # pereti in umbra, dungi
TUFF = "8A6A56"          # tuf brun-rosiatic al falezelor
PUMICE = "E4E0D4"        # peretii de piatra ponce (Lipari, Porticello)
SULPHUR = "C7AE6C"       # craterul Vulcano: ocru-sulf
ASH = "8E8A84"           # cenusa / con gol
SAND = "403C3A"          # plaja neagra
HOUSE = "F1EDE4"         # casele albe eoliene
HOUSE_B = "E3D6BE"       # case ocru-palid
SUN_COLOR = "FFFAF2"     # Color(1.0, 0.98, 0.95)
# Godot inmulteste energia luminii cu pi (alb lambertian perpendicular = energia);
# Cycles nu. Deci taria Cycles = pi x energia temei (ca la Monument Valley).
SUN_STRENGTH = math.pi * 0.95
AMBIENT = "9FB0BF"
AMBIENT_ENERGY = 0.34
SUN_ROT = (-46.0, 210.0)                 # sun_rotation_deg (x, y) din tema

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), plafonat la
# HAZE_MAX. Aer limpede de toamna pe Mediterana: Salina (4-5 km) iese pe
# jumatate spalata, coasta de la 25 km aproape aer — dar nu de tot.
HAZE_D0, HAZE_D, HAZE_F0, HAZE_MAX = 300.0, 9000.0, 0.10, 0.86
MIST_H, MIST_K = 45.0, 0.25              # foschia joasa: K * exp(-z/H), doar departe


# --- Zgomot (numpy, in coordonate de lume) -----------------------------------------

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


# --- Insulele ----------------------------------------------------------------------
# Fiecare: busola (grade, N=0, E=90, in sistemul JOCULUI), distanta pana la centru
# (m), raza tarmului (m), conurile (dx, dy, inaltime, raza, exponent, trunchiere)
# in metri fata de centru (x spre dreapta privitorului, y in adancime), plus
# „caracterul": cat verde, falezele, satele, piatra ponce, craterul de sulf.
# Unghiul aparent al varfului = atan((h - CAM_Z) / d); fereastra camerei de joc
# e ~5 grade, deci planul apropiat urca 3-6, Salina 5-7 (iese din cadru), restul
# 1-3. Distantele se aleg pentru unghiul asta, nu dupa harta.
ISLANDS = [
    # --- planul apropiat: arhipelagul Panareei -------------------------------
    {"name": "Basiluzzo", "az": 0.0, "d": 1500.0, "coast": 230.0, "seed": 11,
     # masa plata de lava, pereti verticali, culturi pe platou (adevarat)
     "cones": [(0, 0, 125.0, 330.0, 0.6, 0.82), (-120, 60, 70.0, 200.0, 0.8, 1.0)],
     "cliff": 0.75, "stretch": (1.35, 0.8), "rot": 15.0, "tilt": 0.14,
     "green": 0.8, "tuff": 0.25, "villages": []},
    {"name": "Dattilo", "az": 0.0, "d": 1350.0, "coast": 55.0, "seed": 12,
     "cones": [(0, 0, 85.0, 80.0, 1.1, 1.0)], "cliff": 0.9,
     "green": 0.1, "tuff": 0.7, "villages": []},
    {"name": "LiscaBianca", "az": 0.0, "d": 1700.0, "coast": 60.0, "seed": 13,
     "cones": [(0, 0, 40.0, 90.0, 0.8, 1.0)], "cliff": 0.7,
     "green": 0.0, "tuff": 0.0, "pumice": 0.15, "villages": []},
    {"name": "Panarea", "az": 0.0, "d": 2600.0, "coast": 900.0, "seed": 14,
     "cones": [(-150, 120, 300.0, 1100.0, 1.25, 1.0), (380, -80, 190.0, 700.0, 1.4, 1.0)],
     "cliff": 0.55, "green": 0.6, "tuff": 0.35,
     # satul alb pe tarmul dinspre privitor (San Pietro / Ditella)
     "villages": [(-480, -760, 260.0), (120, -820, 180.0)]},
    # --- planul doi: Salina cu doua conuri -----------------------------------
    {"name": "Salina", "az": 0.0, "d": 5200.0, "coast": 1900.0, "seed": 21,
     "cones": [(-900, 150, 640.0, 1750.0, 1.2, 1.0), (950, 250, 580.0, 1600.0, 1.25, 1.0),
               (-1500, -500, 260.0, 900.0, 1.2, 1.0)],
     "cliff": 0.45, "green": 0.9, "wood": 0.6, "tuff": 0.3,
     "villages": [(-100, -1650, 380.0), (-1700, -900, 260.0), (1500, -1100, 240.0)]},
    # --- planul trei ------------------------------------------------------------
    {"name": "Lipari", "az": 0.0, "d": 8200.0, "coast": 2300.0, "seed": 31,
     "cones": [(-500, 300, 420.0, 2300.0, 1.2, 1.0), (900, -100, 330.0, 1500.0, 1.4, 1.0),
               (-1300, -400, 260.0, 1100.0, 1.3, 1.0)],
     "cliff": 0.5, "green": 0.55, "tuff": 0.3, "pumice": 0.6,
     "villages": [(400, -2150, 520.0), (-1500, -1700, 260.0)]},
    {"name": "Vulcano", "az": 0.0, "d": 11000.0, "coast": 1900.0, "seed": 41,
     # Gran Cratere: con trunchiat, ocru-sulf; Vulcanello jos in fata
     "cones": [(200, 100, 420.0, 1500.0, 1.1, 0.78), (-700, 600, 480.0, 1600.0, 1.2, 1.0),
               (900, -1300, 110.0, 500.0, 1.0, 0.85)],
     "cliff": 0.45, "green": 0.35, "tuff": 0.4, "sulphur": 1.0,
     "villages": [(600, -1700, 260.0)]},
    {"name": "Filicudi", "az": 0.0, "d": 6500.0, "coast": 1500.0, "seed": 51,
     "cones": [(-200, 100, 640.0, 1700.0, 1.3, 1.0), (700, -300, 300.0, 800.0, 1.2, 1.0)],
     "cliff": 0.5, "green": 0.6, "tuff": 0.35, "villages": [(300, -1400, 220.0)]},
    # Capo Vaticano / Tropea: capul Calabriei, pe falezele lui orasul
    {"name": "Capo", "az": 0.0, "d": 6000.0, "coast": 2400.0, "seed": 71,
     "cones": [(-600, 1500, 420.0, 3600.0, 1.0, 1.0), (1400, 900, 300.0, 2600.0, 1.1, 1.0)],
     "cliff": 0.8, "green": 0.75, "tuff": 0.6, "stretch": (1.6, 1.0),
     "villages": [(-900, -2200, 420.0), (900, -2000, 300.0)]},
    {"name": "Alicudi", "az": 0.0, "d": 11000.0, "coast": 1100.0, "seed": 52,
     "cones": [(0, 0, 640.0, 1250.0, 1.15, 1.0)], "cliff": 0.4, "green": 0.5,
     "tuff": 0.2, "villages": []},
]

# Busola fiecarei insule, dupa directiile in care priveste camera de joc. Masurate
# in joc, nu pe harta: o banda de proba cu NUANTA = busola (rosu N, verde E, cyan S,
# albastru V) lipita pe cer, si capturi --gamecam pe tot turul. Cerul se vede pe:
#   satul de start + serpentinele spre vest (0,04-0,20): busola 240-300
#   serpentinele spre est, plaja (0,40, 0,70): 40-110
#   buza craterului (0,46-0,54): 120-220 — camera la 60-70 m, cea mai larga vedere
#   coasta de est, dreapta lunga (0,80-0,99): 300-60, Strombolicchio 3D la ~310
#   coborarea pe Sciara (0,55-0,65): orizontul iese din cadru, se vede doar marea
AZ = {
    # planul apropiat, pe directiile buzei craterului si ale coborarii pe Sciara
    # (fractiile 0,46-0,63 privesc spre busola 154-258, camera la 30-70 m)
    "Basiluzzo": 205.0, "Dattilo": 183.0, "LiscaBianca": 170.0, "Panarea": 178.0,
    # Salina: saua dintre conuri pe axa coborarii (227-235), conurile de-o parte
    # si de alta
    "Salina": 231.0, "Lipari": 196.0, "Vulcano": 187.0,
    # satul de start (0,04-0,11) priveste spre 244-270, camera jos (12 m)
    "Filicudi": 262.0, "Alicudi": 282.0,
    # dreapta de pe coasta de est (0,81-0,99, busola 349-20) si plaja (45-90):
    # capul Calabriei adus aproape, cu orasul pe faleza
    "Capo": 42.0,
}

# Coasta mare: sectoare polare (busola de la, la; distanta; inaltimea crestei in
# grade peste ochi). Calabria la est, Sicilia (cu Etna) in spatele insulelor.
MAINLAND = [
    ("Calabria", 15.0, 150.0, 24000.0, 1.35, 61),
    ("Sicilia", 150.0, 250.0, 30000.0, 0.95, 62),
]
ETNA = (165.0, 34000.0, 2.3)             # busola, distanta, unghiul varfului


def island_heights(sp, X, Y):
    """Inaltimea pe grila locala (X spre dreapta, Y in adancime, metri)."""
    seed = sp["seed"]
    # insula alungita / rotita (Basiluzzo e o lespede, nu un tambur)
    sx, sy = sp.get("stretch", (1.0, 1.0))
    rot = math.radians(sp.get("rot", 0.0))
    Xr = (X * math.cos(rot) + Y * math.sin(rot)) / sx
    Yr = (-X * math.sin(rot) + Y * math.cos(rot)) / sy
    X, Y = Xr, Yr
    R = np.hypot(X, Y)
    ang = np.arctan2(Y, X)
    # tarmul: raza modulata pe unghi (golfuri, capuri) plus zimti mai fini
    wob = (fbm(np.cos(ang) * 3.0 + seed, np.sin(ang) * 3.0, 1.0, seed, octaves=4) - 0.5)
    wob = wob + 0.5 * (fbm(X, Y, sp["coast"] * 0.35, seed + 1, octaves=3) - 0.5)
    coast = sp["coast"] * (1.0 + 0.42 * wob)
    base = np.zeros_like(X)
    for (cx, cy, h, r, p, trunc) in sp["cones"]:
        d = np.hypot(X - cx, Y - cy)
        a = np.arctan2(Y - cy, X - cx)
        t = np.sqrt((d / r) ** 2 + 0.004)
        prof = np.clip(1.0 - t, 0.0, 1.0) ** p
        prof = np.minimum(prof, trunc) / trunc if trunc < 1.0 else prof
        # creasta rotunjita, nu ac: varful ia un capac
        prof = prof - 0.06 * smoothstep(0.75, 1.0, prof) * (prof - 0.75)
        # ravene radiale (conul vulcanic e brazdat de la varf spre mare)
        rav = fbm(a * r / 60.0 + seed * 7.0, d * 0.012, 1.0, seed + 3, octaves=3, ridged=True)
        prof = prof * (1.0 - 0.16 * rav * smoothstep(0.05, 0.4, prof) * (1.0 - smoothstep(0.85, 1.0, prof)))
        base = np.maximum(base, h * prof)
    # platou inclinat (masa de lava)
    base = base + sp.get("tilt", 0.0) * X
    # relief marunt: dealuri, contraforturi
    rs = max(30.0, min(260.0, sp["coast"] * 0.3))
    base = base + (fbm(X, Y, rs, seed + 5, octaves=4) - 0.5) * 0.14 * np.maximum(base, 10.0)
    # faleza: uscatul se opreste brusc la tarm (cu treapta de stanca), apoi fund
    # (latimea zonei de tarm: ingusta = perete; `cliff` 1 = faleza verticala)
    w = np.maximum(4.0, 0.06 * sp["coast"] * (1.0 - 0.8 * sp["cliff"]))
    land = smoothstep(coast + w, coast - w, R)
    # pe tarm uscatul nu coboara sub o treapta de stanca de cativa metri
    z_top = np.maximum(base, 3.0 + 12.0 * sp["cliff"])
    z = -20.0 + (z_top + 20.0) * land
    return z, land, coast


def island_mesh(sp, rng):
    az = math.radians(AZ[sp["name"]])
    d = sp["d"]
    cx, cy = math.sin(az) * d, math.cos(az) * d
    # axele locale: y in adancime (dinspre privitor), x spre dreapta
    ey = np.array([math.sin(az), math.cos(az)])
    ex = np.array([ey[1], -ey[0]])
    ext = sp["coast"] * 1.55 * max(sp.get("stretch", (1.0, 1.0)))
    # pas ~ jumatate de pixel la distanta insulei
    px_m = d * math.radians(360.0 / W) / RES
    step = max(1.2, min(px_m * 0.6, ext / 120.0))
    n = int(min(900, max(120, 2 * ext / step)))
    u = np.linspace(-ext, ext, n)
    X, Y = np.meshgrid(u, u)
    z, land, coast = island_heights(sp, X, Y)
    wx = cx + X * ex[0] + Y * ey[0]
    wy = cy + X * ex[1] + Y * ey[1]
    co = np.stack([wx, wy, z], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(n - 1), np.arange(n - 1), indexing="ij")
    v0 = ii * n + jj
    v1 = ii * n + jj + 1
    v2 = (ii + 1) * n + jj + 1
    v3 = (ii + 1) * n + jj
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)
    nf = (n - 1) * (n - 1)
    me = bpy.data.meshes.new("Band" + sp["name"])
    me.vertices.add(n * n)
    me.vertices.foreach_set("co", co.astype(np.float32).ravel())
    me.loops.add(nf * 4)
    me.loops.foreach_set("vertex_index", quads.astype(np.int32))
    me.polygons.add(nf)
    me.polygons.foreach_set("loop_start", (np.arange(nf) * 4).astype(np.int32))
    me.polygons.foreach_set("loop_total", np.full(nf, 4, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    # normalele pot iesi in jos (ordinea fetelor): le intoarcem dupa z
    nrm = np.empty(n * n * 3, dtype=np.float32)
    me.vertex_normals.foreach_get("vector", nrm)
    nrm = nrm.reshape(n, n, 3)
    if np.median(nrm[..., 2]) < 0:
        me.flip_normals()
        me.vertex_normals.foreach_get("vector", nrm)
        nrm = nrm.reshape(n, n, 3)
    nz = nrm[..., 2]
    col = island_colors(sp, X, Y, z, nz, wx, wy)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((n * n, 1))], axis=1)
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    me.polygons.foreach_set("use_smooth", np.ones(nf, dtype=bool))
    ob = bpy.data.objects.new("Band" + sp["name"], me)
    bpy.context.collection.objects.link(ob)
    top = float(z.max())
    print("banda: %-11s busola %5.1f d %6.0f varf %4.0f m -> %.2f grade, grila %d (pas %.1f m)" % (
        sp["name"], AZ[sp["name"]], d, top, math.degrees(math.atan((top - CAM_Z) / d)), n, step))
    return ob


def island_colors(sp, X, Y, z, nz, wx, wy):
    seed = sp["seed"]
    hmax = max(c[2] for c in sp["cones"])
    hf = np.clip(z / hmax, 0.0, 1.2)
    steep = smoothstep(0.80, 0.45, nz)          # 1 = perete
    # roca: bazalt cu dungi de tuf brun
    tuffy = sp.get("tuff", 0.3) * smoothstep(0.35, 0.65, fbm(wx, wy + z * 2.0, 90.0, seed + 30, octaves=3))
    rock = lin(ROCK) * (1 - tuffy)[..., None] + lin(TUFF) * tuffy[..., None]
    # straturi de lava (benzi orizontale ondulate) + cateva scurgeri, nu un cod de bare
    strata = vnoise(wx * 0.02 + wy * 0.02, z / 7.0 + 3.0 * fbm(wx, wy, 120.0, seed + 32, octaves=2), 1.0, seed + 31)
    strata = smoothstep(0.55, 0.8, strata)
    streak = smoothstep(0.62, 0.85, vnoise(wx * 0.9 + wy * 0.4, z * 0.02, 11.0, seed + 33))
    dark = np.clip(0.4 * strata + 0.25 * streak, 0.0, 0.6) * steep
    rock = rock * (1 - dark)[..., None] + lin(ROCK_DARK) * dark[..., None]
    # vegetatia: macchia pe ce nu e perete, mai rara sus; petice de culoare
    gi = np.clip((fbm(wx, wy, 70.0, seed + 40, octaves=2) * len(MACCHIA)).astype(int), 0, len(MACCHIA) - 1)
    veg = np.array([lin(c) for c in MACCHIA])[gi]
    terr = smoothstep(0.55, 0.75, fbm(wx, wy, 140.0, seed + 41, octaves=3)) * smoothstep(0.55, 0.15, hf)
    veg = veg * (1 - 0.6 * terr)[..., None] + lin(TERRACE) * (0.6 * terr)[..., None]
    wood = sp.get("wood", 0.0) * smoothstep(0.45, 0.7, hf)
    veg = veg * (1 - wood)[..., None] + lin(WOOD) * wood[..., None]
    gamt = sp.get("green", 0.5)
    vegw = gamt * (1 - steep) * smoothstep(0.3, 0.6, fbm(wx, wy, 120.0, seed + 42, octaves=3) + 0.25 * gamt)
    vegw = np.clip(vegw, 0.0, 1.0)
    # sus pe insulele seci: tufaris ars, nu verde
    scrub = (1 - gamt) * (1 - steep) * smoothstep(0.2, 0.7, hf)
    col = rock * (1 - vegw)[..., None] + veg * vegw[..., None]
    col = col * (1 - scrub * 0.7)[..., None] + lin(SCRUB) * (scrub * 0.7)[..., None]
    # piatra ponce: pereti albi pe o latura a tarmului (Lipari, Lisca Bianca)
    pum = sp.get("pumice", 0.0)
    if pum > 0:
        side = smoothstep(0.45, 0.7, fbm(wx, wy, 600.0, seed + 50, octaves=2))
        pz = pum * side * smoothstep(0.55, 0.25, hf) * (0.4 + 0.6 * steep)
        if sp["name"] == "LiscaBianca":
            pz = np.full_like(z, pum) * smoothstep(-2.0, 2.0, z)
        col = col * (1 - pz)[..., None] + lin(PUMICE) * pz[..., None]
    # sulf + cenusa pe craterul trunchiat (Vulcano)
    if sp.get("sulphur", 0.0) > 0:
        c0 = sp["cones"][0]
        dc = np.hypot(X - c0[0], Y - c0[1]) / c0[3]
        sul = smoothstep(0.38, 0.22, dc) * smoothstep(0.55, 0.85, fbm(wx, wy, 60.0, seed + 60, octaves=3) + 0.3)
        ash = smoothstep(0.5, 0.3, dc)
        col = col * (1 - ash * 0.8)[..., None] + lin(ASH) * (ash * 0.8)[..., None]
        col = col * (1 - sul)[..., None] + lin(SULPHUR) * sul[..., None]
    # plaja neagra / bolovanis la apa
    beach = smoothstep(4.0, 0.5, z) * (1 - steep * 0.6)
    col = col * (1 - beach)[..., None] + lin(SAND) * beach[..., None]
    # satele: case albe in ciorchini, pe pantele domoale de jos
    for (vx, vy, vr) in sp.get("villages", []):
        dv = np.hypot(X - vx, Y - vy)
        zone = smoothstep(vr, vr * 0.3, dv) * smoothstep(0.6, 0.85, nz) * smoothstep(1.0, 4.0, z)
        zone = zone * smoothstep(0.35 * hmax, 0.15 * hmax, z)
        cs = max(5.0, 0.0011 * sp["d"])          # o casa ~ doi pixeli
        cell = vnoise(wx, wy, cs, seed + 70)
        house = zone * smoothstep(0.60, 0.66, cell)
        side = zone * smoothstep(0.52, 0.58, cell) * (1 - house)   # latura in umbra
        tint = smoothstep(0.5, 0.8, vnoise(wx, wy, cs, seed + 71))
        hc = lin(HOUSE)[None, None, :] * (1 - tint)[..., None] + lin(HOUSE_B)[None, None, :] * tint[..., None]
        col = col * (1 - 0.5 * side)[..., None] + lin(ROCK) * (0.5 * side)[..., None]
        col = col * (1 - house)[..., None] + hc * house[..., None]
    return col


def mainland_mesh(name, az0, az1, dist, theta, seed):
    """Coasta mare: o fasie polara cu creasta la `theta` grade peste ochi."""
    naz = int((az1 - az0) / 360.0 * W * 0.6 * RES) + 8
    nr = 40
    az = np.radians(np.linspace(az0, az1, naz))
    rr = np.linspace(dist * 0.82, dist * 1.25, nr)
    A, Rg = np.meshgrid(az, rr)
    px, py = np.sin(A) * Rg, np.cos(A) * Rg
    hc = CAM_Z + dist * math.tan(math.radians(theta))
    big = fbm(px, py, dist * 0.20, seed, octaves=3)
    jag = fbm(px, py, dist * 0.04, seed + 9, octaves=4, ridged=True)
    crest = hc * (0.25 + 0.75 * big + 0.25 * jag)
    # capetele fasiei coboara in mare (nu se taie in perete)
    edge = np.minimum(np.degrees(A) - az0, az1 - np.degrees(A))
    crest = crest * smoothstep(0.0, 9.0, edge)
    t = np.clip((Rg - dist * 0.82) / (dist * 0.25), 0.0, 1.0)
    z = -30.0 + (crest + 30.0) * np.power(smoothstep(0.0, 1.0, t), 0.7)
    # Etna: con larg, peste fasia Siciliei
    if name == "Sicilia":
        ea, ed, eth = ETNA
        ex, ey = math.sin(math.radians(ea)) * ed, math.cos(math.radians(ea)) * ed
        de = np.hypot(px - ex, py - ey)
        eh = CAM_Z + ed * math.tan(math.radians(eth))
        cone = eh * np.clip(1.0 - np.sqrt((de / 9000.0) ** 2 + 0.003), 0.0, 1.0) ** 1.15
        z = np.maximum(z, cone)
    nverts = nr * naz
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(nr - 1), np.arange(naz - 1), indexing="ij")
    v0 = ii * naz + jj
    v1 = ii * naz + jj + 1
    v2 = (ii + 1) * naz + jj + 1
    v3 = (ii + 1) * naz + jj
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)
    nf = (nr - 1) * (naz - 1)
    me = bpy.data.meshes.new("Band" + name)
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
    if np.median(nrm.reshape(-1, 3)[:, 2]) < 0:
        me.flip_normals()
    gi = np.clip((fbm(px, py, 900.0, seed + 3, octaves=2) * 3).astype(int), 0, 2)
    pal = np.array([lin(MACCHIA[0]), lin(SCRUB), lin(ROCK)])
    col = pal[gi]
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((nverts, 1))], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    me.polygons.foreach_set("use_smooth", np.ones(nf, dtype=bool))
    ob = bpy.data.objects.new("Band" + name, me)
    bpy.context.collection.objects.link(ob)
    return ob


# --- Materiale ---------------------------------------------------------------------

def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def haze_wrap(nt, surface_socket, out_node, haze_k=1.0, f0=HAZE_F0):
    """surface -> amestec cu HAZE dupa distanta si cu MIST dupa inaltime."""
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
    if haze_k != 1.0:   # 1 - k * (1 - keep)
        keep_air = math_node("SUBTRACT", va=1.0, b=math_node("MULTIPLY", math_node("SUBTRACT", va=1.0, b=keep_air), vb=haze_k))
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / MIST_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")                        # foschia doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 2500.0
    ramp.inputs["From Max"].default_value = 12000.0
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


def land_material(name="BandLand"):
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    L.new(at.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def sea_material():
    """Marea e NEILUMINATA: culoarea apei jocului la ~300 m (adanca, aproape sub
    camera) care se deschide spre orizont (Fresnel: departe marea oglindeste
    cerul), spalata apoi de acelasi aer ca insulele. Jocul are apa lui pana la
    FAR_PLANE; banda incepe unde se termina ea."""
    mat, nt, out = new_material("BandSea")
    n, L = nt.nodes, nt.links
    cam = n.new("ShaderNodeCameraData")
    mr = n.new("ShaderNodeMapRange")
    L.new(cam.outputs["View Distance"], mr.inputs["Value"])
    mr.inputs["From Min"].default_value = 400.0
    mr.inputs["From Max"].default_value = 5000.0
    mr.interpolation_type = "SMOOTHSTEP"
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(SEA)
    cmix.inputs[7].default_value = srgb(SEA_FAR)
    L.new(mr.outputs["Result"], cmix.inputs[0])
    # valuri: o modulatie fina de luminanta, trasa pe orizontala
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
    k.inputs["To Min"].default_value = 0.92
    k.inputs["To Max"].default_value = 1.08
    em = n.new("ShaderNodeEmission")
    L.new(cmix.outputs[2], em.inputs["Color"])
    L.new(k.outputs["Result"], em.inputs["Strength"])
    # fara voalul de pornire (F0): la marginea de jos marea trebuie sa fie exact
    # apa jocului de la FAR_PLANE, nu o apa deja spalata
    haze_wrap(nt, em.outputs[0], out, f0=0.0)
    return mat


def atlas_haze_material():
    mat, nt, out = new_material("BandAtlas")
    n, L = nt.nodes, nt.links
    tex = n.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS)
    tex.interpolation = "Closest"
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.9
    L.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


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
    me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new("BandSea", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(sea_material())


def build_land(rng):
    mat = land_material()
    for sp in ISLANDS:
        ob = island_mesh(sp, rng)
        ob.data.materials.append(mat)
    for (name, a0, a1, dist, th, seed) in MAINLAND:
        ob = mainland_mesh(name, a0, a1, dist, th, seed)
        ob.data.materials.append(mat)


BOATS = [  # busola, distanta, cap (grade), model — pe golurile de mare deschisa
    (318.0, 1100.0, 110.0, "fishing_boat_large"),
    (8.0, 1500.0, 250.0, "fishing_boat_small"),
    (98.0, 900.0, 200.0, "fishing_boat_large"),
    (140.0, 1300.0, 40.0, "fishing_boat_small"),
    (296.0, 800.0, 300.0, "fishing_boat_small"),
]


def build_boats():
    mat = atlas_haze_material()
    cache = {}
    for (azd, d, yaw, model) in BOATS:
        if model not in cache:
            path = os.path.join(MODELS, "stromboli", "vehicles", model + ".glb")
            if not os.path.exists(path):
                print("LIPSA: " + path)
                continue
            before = set(o.name for o in bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=path)
            new = [o for o in bpy.data.objects if o.name not in before]
            new_names = [o.name for o in new]
            meshes = [o for o in new if o.type == "MESH"]
            bpy.ops.object.select_all(action="DESELECT")
            for o in meshes:
                o.select_set(True)
            bpy.context.view_layer.objects.active = meshes[0]
            if len(meshes) > 1:
                bpy.ops.object.join()
            boat = bpy.context.view_layer.objects.active
            bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
            for nm in new_names:
                ob = bpy.data.objects.get(nm)
                if ob is not None and ob != boat:
                    bpy.data.objects.remove(ob, do_unlink=True)
            boat.data.materials.clear()
            boat.data.materials.append(mat)
            boat.location = (0, 0, -900)
            cache[model] = boat
            o = boat
        else:
            o = cache[model].copy()
            bpy.context.collection.objects.link(o)
        a = math.radians(azd)
        o.location = (math.sin(a) * d, math.cos(a) * d, 0.0)
        o.rotation_euler = (0.0, 0.0, math.radians(yaw))


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
    sun.rotation_euler = (-sun_dir_blender()).to_track_quat("-Z", "Y").to_euler()

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
rng = np.random.default_rng(11)
setup_render()
build_sea()
build_land(rng)
build_boats()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
