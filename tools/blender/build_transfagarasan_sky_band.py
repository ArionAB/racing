"""Banda de orizont a cerului Transfagarasan (Track21) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/transfagarasan_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime
(-7,5 .. +15), cu alfa: Muntii Fagarasului care continua creasta din mijlocul
buclei. Creasta principala (sist cenusiu-verzui, zimtata, cu caldari glaciare si
petice de zapada de iulie) merge spre EST si spre VEST; spre SUD coboara
culmile impadurite ale Argesului, cu marea de nori in vaile din E/SE; spre NORD
valea se deschide intre doi pinteni spre campia Tarii Fagarasului. Pe toate,
etajele muntelui: molid inchis jos, pajiste alpina verde-galbuie sus, sist si
zapada pe creste. Cerul ramane TRANSPARENT: gradientul lui il deseneaza shaderul
de cer din joc (`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Fiordland (`build_fiordland_sky_band.py`): un camp de
inaltimi POLAR (nu obiecte asezate), cu planuri de creste tot mai palide, plus
planul 0 (`NEAR_GIANTS`, lectia de pe Monument Valley): masive mari si
apropiate (0,6-1,0 km), puse de mana pe directiile in care priveste camera de
joc pe portiunile lungi, care dau SCARA.

Problema centrala, ca pe Monument Valley (uscat): IMBINAREA dintre terenul real
(intra in ceata spre fog_end 370 m) si poalele pictate ale benzii. Aici solul
nu e o culoare: e padure, pajiste, sist. De aceea legatura nu se face pe
culoarea solului, ci pe AER: fundul vailor din banda sta intr-o pacla de
inversiune (`VALLEY_*`, dupa cota) de culoarea cetii jocului, deci terenul care
se pierde in ceata la 370 m continua in vaile pictate, iar muntii urca din pacla
curati, cu contrast. Departarea (`HAZE_*`, dupa distanta) se topeste in
`HAZE` = `sky_horizon` din tema = `fog`, aceeasi culoare. In joc, `below` =
aceeasi pacla.

Un camp polar are o capcana a lui: tot ce variaza doar pe azimut (zimtii
crestei, pragurile etajelor masurate fata de creasta zimtata) coboara pe toata
fata ca o coloana de lumina sau de culoare — „perdele" verticale. De aceea
zimtii stau doar in partea de sus a fetei, etajele se masoara fata de creasta
NETEZITA, iar fetele primesc relief in coordonate de lume.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste nivelul de referinta, in origine; u = 0,5 priveste
    spre NORD (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca
    in shader (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "transfagarasan" (`sun_rotation_deg` (-25, -110, 0), adica
    busola 290, VNV, 25 de grade elevatie), `sun_color` (1, 0.85, 0.66), energia
    1,1; ambientul B8CCE0 la 0,30;
  * HAZE = `sky_horizon` din tema (0.86, 0.88, 0.90): departarea se topeste in
    culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_transfagarasan_sky_band.py [-- --test]
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
# Camera de joc sta la 10 m peste sosea, iar soseaua urca de la 0 (valea Argesului)
# la 43 m (portalul tunelului): ochiul e la 10-53 m peste cota 0. 30 e mijlocul;
# la kilometri distanta diferenta e sub un grad.
CAM_Z = 30.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "transfagarasan_horizon_band_test.png" if TEST
                   else "transfagarasan_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB) ----------------------------------------------------------------
# Albedo-uri, nu culori pe ecran: lumina o pune soarele de mai jos, acelasi ca in
# joc. Tintele pe ecran sunt cele din brief §1 (sist #7E8478, pajiste #7D9A4E,
# molid #23392B, zapada #E8ECEE / umbra #B5C3D3); albedo-urile sunt
# precompensate pentru soarele cald, ca in tema (`terrain_ground_tint`,
# `scarp_tint`), si verificate pe captura.
# AERUL: o singura culoare, = `fog` = `sky_horizon` din tema (0.72, 0.83, 0.94).
# Inainte de banda, `fog_sky_affect` 1 facea tot cerul vizibil din camera de joc
# exact culoarea asta (masurat pe captura: (220, 238, 254) pe ecran); cu banda
# cerul isi arata gradientul, iar orizontul lui ramane acelasi albastru-pal.
HAZE = "B8D4F0"          # departarea se topeste in cerul de la orizont
FOG_SEEN = "B8D4F0"      # ceata jocului la fog_end (aceeasi culoare)
SCHIST = "616C66"        # sist in lumina
SCHIST_DARK = "454E49"   # fisuri, fete in umbra
SCREE = "8E948C"         # conuri de grohotis, mai deschise
MEADOW = ["6E9A45", "7FA24C", "8FA552", "6A8E44"]   # pajiste alpina, verde-galbui
MEADOW_DRY = "A3A35E"    # pajiste arsa pe culmile sudice
JNEAPAN = "34503A"       # jneapan: verde inchis albastrui, in petice
SPRUCE = ["1F3527", "243C2C", "2A4431", "1C3024"]   # molid
BEECH = ["4E7A34", "5A8638", "4A7231"]              # fag (Arges, jos)
SNOW = "F1F4F6"
SNOW_SHADE = "C4D2E2"    # zapada in umbra: albastruie (brief §1)
CLOUD = "F4F6F8"         # marea de nori
SUN_COLOR = "FFD9A8"
# Godot inmulteste energia luminii cu pi fata de Cycles (vezi build_monument_sky_band.py)
SUN_STRENGTH = math.pi * 1.1
AMBIENT = "B8CCE0"
AMBIENT_ENERGY = 0.30
SUN_ROT = (-25.0, -110.0)                  # sun_rotation_deg (x, y) din tema

# Perspectiva aeriana, doua straturi:
#   * aerul pe DISTANTA: fac(d) = 1 - (1 - F0) * exp(-(d - d0) / D), plafonat la
#     HAZE_MAX; culoarea merge de la FOG_SEEN (aproape) la HAZE (departe);
#   * pacla din VAI (inversiune de dupa-amiaza): VALLEY_K * exp(-(z - VALLEY_Z) / H),
#     doar de la ~400 m incolo. Ea face IMBINAREA: terenul jocului intra in ceata
#     (fog_end 370 m) aproape de cota vailor, deci fundul vailor din banda trebuie
#     sa aiba aceeasi culoare de ceata; muntii care urca din pacla raman curati,
#     cu contrast, ca sa dea scara (planul 0).
HAZE_D0, HAZE_D = 370.0, 10500.0
HAZE_F0 = 0.08
HAZE_MAX = 0.82
HAZE_C0, HAZE_C1 = 900.0, 9000.0
VALLEY_Z, VALLEY_H, VALLEY_K = -30.0, 34.0, 0.86
SNOW_GLOW = 0.30                           # zapada din umbra ramane alba (cer difuz)


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


def az_bump(az_deg, center, half, soft):
    """1 in sectorul [center - half, center + half] (busola), 0 in afara, margine moale."""
    d = np.abs(((az_deg - center + 180.0) % 360.0) - 180.0)
    return smoothstep(half + soft, half - soft, d)


# --- Scena -----------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node, alpha_socket=None, haze_k=1.0, valley=True):
    """surface -> amestec cu aerul dupa distanta (vezi HAZE_*).
    Cu `alpha_socket`, rezultatul se amesteca la sfarsit cu Transparent (nori)."""
    n = nt.nodes
    L = nt.links
    cam = n.new("ShaderNodeCameraData")

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
    keep = math_node("MULTIPLY", x, vb=1.0 - HAZE_F0)
    keep = math_node("MAXIMUM", keep, vb=1.0 - HAZE_MAX)
    # pacla din vai: dupa cota de lume, intrata treptat intre 380 si 700 m
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])
    vz = math_node("SUBTRACT", sep.outputs[2], vb=VALLEY_Z)
    vz = math_node("MAXIMUM", vz, vb=0.0)
    vz = math_node("MULTIPLY", vz, vb=-1.0 / VALLEY_H)
    vz = math_node("EXPONENT", vz)
    vr = n.new("ShaderNodeMapRange")
    vr.interpolation_type = "SMOOTHSTEP"
    L.new(d, vr.inputs["Value"])
    vr.inputs["From Min"].default_value = 300.0
    vr.inputs["From Max"].default_value = 460.0
    # ...si numai in vaile apropiate: campia de la 5-15 km (nord) e mult mai jos
    # decat VALLEY_Z, iar pacla plina ar fi facut-o o mare
    vf = n.new("ShaderNodeMapRange")
    vf.interpolation_type = "SMOOTHSTEP"
    L.new(d, vf.inputs["Value"])
    vf.inputs["From Min"].default_value = 2500.0
    vf.inputs["From Max"].default_value = 7000.0
    vf.inputs["To Min"].default_value = 1.0
    vf.inputs["To Max"].default_value = 0.0
    vfac = math_node("MULTIPLY", vz, vr.outputs["Result"])
    vfac = math_node("MULTIPLY", vfac, vf.outputs["Result"])
    vfac = math_node("MULTIPLY", vfac, vb=VALLEY_K if valley else 0.0)
    if valley:
        # atributul `vk` (0..1) de pe relief: campia de la nord (mult sub VALLEY_Z)
        # primeste doar o parte din pacla, altfel citea a mare
        vka = n.new("ShaderNodeAttribute")
        vka.attribute_type = "GEOMETRY"
        vka.attribute_name = "vk"
        vfac = math_node("MULTIPLY", vfac, vka.outputs["Fac"])
    keep = math_node("MULTIPLY", keep, math_node("SUBTRACT", va=1.0, b=vfac))
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    fac = math_node("MULTIPLY", fac, vb=haze_k)
    # culoarea aerului: FOG_SEEN aproape -> HAZE departe
    cr = n.new("ShaderNodeMapRange")
    cr.interpolation_type = "SMOOTHSTEP"
    L.new(d, cr.inputs["Value"])
    cr.inputs["From Min"].default_value = HAZE_C0
    cr.inputs["From Max"].default_value = HAZE_C1
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(FOG_SEEN)
    cmix.inputs[7].default_value = srgb(HAZE)
    L.new(cr.outputs["Result"], cmix.inputs[0])
    em = n.new("ShaderNodeEmission")
    L.new(cmix.outputs[2], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    mix = n.new("ShaderNodeMixShader")
    L.new(fac, mix.inputs[0])
    L.new(surface_socket, mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    last = mix.outputs[0]
    if alpha_socket is not None:
        tr = n.new("ShaderNodeBsdfTransparent")
        m2 = n.new("ShaderNodeMixShader")
        L.new(alpha_socket, m2.inputs[0])
        L.new(tr.outputs[0], m2.inputs[1])
        L.new(last, m2.inputs[2])
        last = m2.outputs[0]
    L.new(last, out_node.inputs["Surface"])


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def land_material(name="BandLand", haze_k=1.0):
    """Culoarea e in vertex color (padure / pajiste / sist / zapada, calculate in
    `color_land`); materialul doar o lumineaza si o spala in aer. Alfa din
    atributul Col = cat e zapada (primeste o emisie mica: zapada din umbra ramane
    alb-albastruie de la cerul difuz, nu gri)."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
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
    haze_wrap(nt, add.outputs[0], out, haze_k=haze_k)
    return mat


def cloud_material():
    """Marea de nori: alb luminat de soare + o emisie mica (in umbra nu iese gri
    murdar); alfa din atributul `cov` (marginile marii, golurile)."""
    mat, nt, out = new_material("BandCloud")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_type = "GEOMETRY"
    at.attribute_name = "cov"
    df = n.new("ShaderNodeBsdfDiffuse")
    df.inputs["Color"].default_value = srgb(CLOUD)
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(CLOUD)
    em.inputs["Strength"].default_value = 0.22
    add = n.new("ShaderNodeAddShader")
    L.new(df.outputs[0], add.inputs[0])
    L.new(em.outputs[0], add.inputs[1])
    haze_wrap(nt, add.outputs[0], out, alpha_socket=at.outputs["Fac"], valley=False)
    return mat


# --- Relieful: camp de inaltimi polar ------------------------------------------

N_AZ = 1024 if TEST else 4096
N_R = 160 if TEST else 640
R0, R1 = 430.0, 32000.0

# Planurile de creste: (distanta crestei, unghiul mediu al crestei peste ochi,
# grade, pe creasta principala). Pe sectoare unghiul se inmulteste cu `amp_*`
# (vezi `sector_amp`). Ca pe Fiordland: fiecare plan e o creasta cu vale in
# spate, cu sei si goluri pe azimut prin care se vede planul urmator, fiecare
# mai palid si putin mai sus pe cer.
LAYERS = [
    (1150.0, 3.6), (1800.0, 4.3), (2900.0, 4.8), (4600.0, 5.1),
    (7400.0, 5.3), (12000.0, 5.2), (20000.0, 4.4),
]


def sector_amp(azd, k):
    """Cat din unghiul planului k ramane pe azimutul azd (busola, grade).

    Creasta principala E-V: plina. Sudul (Argesul): culmi impadurite mai joase,
    rotunde; in fund (SE) masivul Iezer-Papusa mai sus. Nordul: valea Balii se
    deschide intre doi pinteni (NV si NE), iar prin gol se vede campia; doar
    ultimul plan (dealurile Transilvaniei) trece pe acolo, jos."""
    main = np.maximum(az_bump(azd, 90.0, 38.0, 22.0), az_bump(azd, 268.0, 38.0, 22.0))
    south = az_bump(azd, 182.0, 40.0, 20.0)
    north = az_bump(azd, 0.0, 44.0, 18.0)
    spurs = np.maximum(az_bump(azd, 318.0, 16.0, 10.0), az_bump(azd, 44.0, 16.0, 10.0))
    if k <= 1:
        s_amp = 0.62
    elif k <= 3:
        s_amp = 0.72
    else:
        s_amp = 0.85 + 0.15 * az_bump(azd, 140.0, 25.0, 15.0)
    if k <= 2:
        n_amp = 0.10 + 0.55 * spurs
    elif k <= 4:
        n_amp = 0.0
    elif k == 5:
        n_amp = 0.0
    else:
        n_amp = 0.22
    rest = np.clip(1.0 - main - south - north, 0.0, 1.0)
    return main * 1.0 + south * s_amp + north * n_amp + rest * 0.82


def floor_height(azd, r):
    """Fundul vailor: la sud si pe creasta, vai la ~-30 m; spre nord campia
    coboara (Tara Fagarasului e cu ~1500 m mai jos decat creasta)."""
    north = az_bump(azd, 0.0, 50.0, 25.0)
    base = -28.0 - 10.0 * smoothstep(800.0, 4000.0, r)
    plain = -40.0 - 70.0 * smoothstep(1200.0, 9000.0, r)
    # dealuri joase si largi pe campie (altfel, plata si palida, citea a mare)
    a = np.radians(azd)
    hx, hy = np.sin(a) * r, np.cos(a) * r
    plain = plain + (fbm(hx, hy, 1400.0, 77, octaves=3) - 0.45) * 46.0 * smoothstep(1800.0, 4000.0, r)
    return base * (1.0 - north) + plain * north


# Planul 0: masive mari si apropiate, puse de mana pe directiile camerei de joc
# (unghiurile drumului din Track21.tscn, camera ChaseCamera ~100 de grade pe
# orizontala la 16:9):
#
#   portiunea                     fractii      directia camerei
#   startul, spre baraj           0,00-0,13    75-95  (E)
#   urcarea D pe latura de est    0,15-0,36    345-50 (N, NNE)
#   serpentinele F                0,37-0,57    270-300 / 40-90 (V / E)
#   dreapta lunga de nord         0,57-0,69    258-277 (V)
#   defileul Oltului H            0,76-0,93    176-187 (S)
#   intoarcerea la start          0,94-1,00    118-160 (SE)
#
# Niciunul pe axa unei drepte lungi (15-35 de grade lateral), niciunul in
# spatele barajului (E de la start) sau al Poenarilor. Unghiul varfului e ales
# din origine: h = CAM_Z + d * tan(e). Cele de 7-9 grade ies din cadru: asta
# da scara.
# (azimut, distanta, unghiul varfului, semilatimea pe azimut in grade, adancime m)
NEAR_GIANTS = [
    ("A", 112.0, 820.0, 8.2, 13.0, 420.0),   # start: dreapta barajului, Iezer spre SE
    ("B", 62.0, 950.0, 7.4, 11.0, 420.0),    # start stanga / urcarea D dreapta
    ("C", 22.0, 1000.0, 5.4, 10.0, 380.0),    # pintenul NE, peste valea Balii
    ("D", 318.0, 900.0, 7.6, 10.0, 420.0),   # pintenul NV: urcarea D stanga, serpentinele
    ("E", 246.0, 780.0, 8.6, 12.0, 450.0),   # Negoiu: dreapta lunga de nord, stanga
    ("F", 292.0, 1050.0, 7.2, 9.0, 420.0),   # creasta V, dreapta dreptei de nord
    ("G", 205.0, 900.0, 6.2, 12.0, 400.0),   # Oltul: culme impadurita in dreapta
    ("H", 160.0, 950.0, 5.6, 12.0, 400.0),   # Oltul: culme impadurita in stanga
]


def heights(px, py, r):
    azd = (np.degrees(np.arctan2(px, py)) + 360.0) % 360.0
    floor = floor_height(azd, r)
    z = floor.copy()
    crest_h = np.full(px.shape, 1.0)        # inaltimea crestei planului castigator
    kid = np.full(px.shape, -1, dtype=np.int32)
    # directia (vector unitar): zgomotul crestelor se citeste pe cercul crestei,
    # deci depinde doar de azimut — fete curate sub o creasta, nu tepi izolati
    ux, uy = px / r, py / r
    for k, (dk, th) in enumerate(LAYERS):
        cx, cy = ux * dk, uy * dk
        amp = sector_amp(azd, k)
        fl = floor_height(azd, np.full(px.shape, dk))
        # inaltimea PESTE fundul vaii; amp 0 = fara creasta (campia), nu un deal
        # la cota ochiului
        hrel = (CAM_Z + dk * math.tan(math.radians(th)) - fl) * amp
        big = fbm(cx, cy, dk * 0.45, 100 + k, octaves=3)
        jag = fbm(cx, cy, dk * 0.06, 200 + k, octaves=4, ridged=True)
        # creasta principala e zimtata; culmile sudice si campia sunt rotunde
        main = np.maximum(az_bump(azd, 90.0, 40.0, 20.0), az_bump(azd, 268.0, 40.0, 20.0))
        jag_k = 0.25 + 0.45 * main
        crest = fl + hrel * (0.45 + 0.55 * big + jag_k * jag)
        if k > 0:
            gap = smoothstep(0.36, 0.28, fbm(cx, cy, dk * 0.6, 300 + k, octaves=2))
            crest = fl + (crest - fl) * (1.0 - 0.6 * gap)
        # pinteni si ravene: fata coboara mai departe spre camera pe pinteni,
        # mai scurt in ravene (variatie pe azimut, in coordonate de lume)
        spur = fbm(cx, cy, dk * 0.14, 400 + k, octaves=2, ridged=True)
        wf = dk * (0.16 + 0.10 * spur)
        wb = dk * 0.28
        t = np.where(r < dk, 1.0 - (dk - r) / wf, 1.0 - (r - dk) / wb)
        t = np.clip(t, 0.0, 1.0)
        prof = np.power(t, 0.85)
        # zimtii stau doar sus: fata de dedesubt urmeaza creasta NETEZITA (altfel
        # fiecare zimte cobora pana jos ca o coloana de lumina/umbra)
        cs = fl + hrel * (0.55 + 0.55 * big)
        if k > 0:
            cs = fl + (cs - fl) * (1.0 - 0.6 * gap)
        top = np.power(t, 2.5)
        ck = cs + (crest - cs) * top
        zk = floor + np.maximum(ck - floor, 0.0) * prof
        better = zk > z
        # etajele (padure / pajiste / sist) se masoara fata de creasta NETEZITA:
        # cu zimtii in ea, pragurile sareau de la o coloana de azimut la alta si
        # fetele ieseau in dungi verticale
        crest_h = np.where(better, np.maximum(hrel * (0.55 + 0.55 * big), 1.0), crest_h)
        kid = np.where(better, k, kid)
        z = np.maximum(z, zk)
    # planul 0: uriasii
    grng = np.random.default_rng(1966)
    for gi, (name, gaz, gd, gel, ghalf, gdepth) in enumerate(NEAR_GIANTS):
        hc = CAM_Z + gd * math.tan(math.radians(gel))
        daz = ((azd - gaz + 180.0) % 360.0) - 180.0
        u = daz / ghalf
        # silueta pe azimut: NU o cupola — un sir de varfuri piramidale (sist
        # zimtat), cel mai inalt aproape de mijloc, umerii coborand in trepte
        shape = np.zeros(px.shape)
        n_pk = 6
        for p in range(n_pk):
            c = (-0.15 + 0.3 * grng.random()) if p == 0 else grng.uniform(-0.9, 0.9)
            hp = 1.0 if p == 0 else grng.uniform(0.5, 0.82)
            wp = grng.uniform(0.5, 0.7) if p == 0 else grng.uniform(0.28, 0.48)
            tri = np.clip(1.0 - np.abs(u - c) / wp, 0.0, 1.0)
            shape = np.maximum(shape, hp * np.power(tri, 1.0))
        # sei intre varfuri: creasta nu cade la fund intre ele
        shape = np.maximum(shape, 0.5 * np.clip(1.0 - np.abs(u) / 1.05, 0.0, 1.0))
        shape = shape * smoothstep(1.25, 0.9, np.abs(u))
        cx, cy = ux * gd, uy * gd
        jag = fbm(cx, cy, 60.0, 500 + gi, octaves=5, ridged=True)
        fl = floor_height(azd, np.full(px.shape, gd))
        # inaltimea peste fundul vaii, zero in afara siluetei (nu un platou)
        crest = fl + (hc - fl) * shape * (0.74 + 0.36 * jag)
        cs = fl + (hc - fl) * shape * 0.92
        # muchii (pinteni) care coboara spre camera si vaiugi intre ele: nu fete
        # plane de piramida
        spur = fbm(cx, cy, 120.0, 540 + gi, octaves=3, ridged=True)
        wf = gdepth * (0.5 + 0.3 * spur)
        wb = gdepth
        t = np.where(r < gd, 1.0 - (gd - r) / wf, 1.0 - (r - gd) / wb)
        t = np.clip(t, 0.0, 1.0)
        prof = np.power(t, 0.75 + 0.6 * (1.0 - spur))
        ck = cs + (crest - cs) * np.power(t, 2.5)
        zg = floor + np.maximum(ck - floor, 0.0) * prof
        better = zg > z
        crest_h = np.where(better, np.maximum((hc - fl) * np.maximum(shape, 0.35), 1.0), crest_h)
        kid = np.where(better, 100 + gi, kid)
        z = np.maximum(z, zg)
    # inelul interior coboara la fundul vaii: altfel marginea campului ar fi o
    # streasina sub care se vede dosul reliefului
    z = floor + (z - floor) * smoothstep(R0, R0 + 120.0, r)
    # contraforturi si ravene pe fete (zgomot fin, mai tare pe creasta principala)
    # contraforturi, umeri si ravene pe fete (zgomot in coordonate de lume, deci
    # variaza si pe panta, nu doar pe azimut: fara „perdele" verticale)
    rel_h = np.maximum(z - floor, 0.0)
    z += (fbm(px, py, 0.035 * r + 60.0, 29, octaves=4) - 0.5) * 0.30 * rel_h
    # pe uriasi: rigole si coaste fine (sist), proportionale cu inaltimea
    gmask = (kid >= 100).astype(np.float64)
    z += (fbm(px, py, 28.0, 31, octaves=3, ridged=True) - 0.45) * 0.10 * np.maximum(z - floor, 0.0) * gmask
    return z, floor, crest_h, kid, azd


def build_land():
    az = np.linspace(0.0, math.tau, N_AZ, endpoint=False)
    rr = R0 * np.power(R1 / R0, np.linspace(0.0, 1.0, N_R))
    A, Rg = np.meshgrid(az, rr)                     # (N_R, N_AZ)
    px = np.sin(A) * Rg
    py = np.cos(A) * Rg
    z, floor, crest_h, kid, azd = heights(px, py, Rg)
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
    rgba = color_land(px, py, z, floor, crest_h, kid, azd, nrm, Rg)
    azd = (np.degrees(A) % 360.0)
    vk = 1.0 - 0.97 * az_bump(azd, 0.0, 44.0, 25.0) * smoothstep(1100.0, 2200.0, Rg)
    va = me.attributes.new("vk", "FLOAT", "POINT")
    va.data.foreach_set("value", vk.astype(np.float32).ravel())
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d varfuri, %d fete" % (N_R, N_AZ, nf))


def color_land(px, py, z, floor, crest_h, kid, azd, nrm, rr):
    """Etajele muntelui pe varf (liniar): fag jos la sud, molid, jneapan, pajiste
    alpina, sist pe fetele abrupte si pe creste, zapada in caldari si pe fetele
    umbrite de sub creasta; campia la nord in fasii de camp."""
    def lin(hx):
        return np.array(srgb(hx)[:3])

    nz = nrm[..., 2]
    # orientarea fetei fata de nord (zapada de iulie sta pe fetele nordice)
    north_face = smoothstep(-0.1, 0.5, nrm[..., 1])
    rel = np.clip((z - floor) / np.maximum(crest_h, 1.0), 0.0, 1.3)
    main = np.maximum(az_bump(azd, 90.0, 40.0, 22.0), az_bump(azd, 268.0, 40.0, 22.0))
    giant = (kid >= 100).astype(np.float64)
    south = az_bump(azd, 182.0, 42.0, 20.0)
    north = az_bump(azd, 0.0, 50.0, 25.0)

    def pick(pal, seed, scale):
        idx = np.clip((fbm(px, py, scale, seed, octaves=2) * 1.6 - 0.3) * len(pal),
                      0, len(pal) - 1).astype(int)
        return np.array([lin(c) for c in pal])[idx]

    spruce = pick(SPRUCE, 71, 70.0)
    beech = pick(BEECH, 73, 90.0)
    meadow = pick(MEADOW, 75, 160.0)
    # sist: lumina dupa normala, dungi de strat inclinate
    lit = smoothstep(0.25, 0.8, nz)
    rock = lin(SCHIST_DARK)[None, None, :] * (1 - lit)[..., None] + lin(SCHIST)[None, None, :] * lit[..., None]
    strata = smoothstep(0.55, 0.8, vnoise(px * 0.7 + z * 2.0, py * 0.7 - z * 1.2, 22.0, 41))
    rock = rock * (1 - 0.25 * strata)[..., None] + lin(SCHIST_DARK) * (0.25 * strata)[..., None]
    scree_w = smoothstep(0.45, 0.7, fbm(px, py, 90.0, 43, octaves=3)) * smoothstep(0.55, 0.8, nz)
    rock = rock * (1 - 0.5 * scree_w)[..., None] + lin(SCREE) * (0.5 * scree_w)[..., None]

    # padurea: pe creasta principala pana la ~40% din perete, la sud pana sus
    # (culmile Argesului sunt impadurite), cu limita zdrentuita
    rag = fbm(px, py, 60.0, 57, octaves=3)
    fline = (0.34 + 0.12 * (fbm(px, py, 400.0, 53, octaves=2) - 0.5) + 0.16 * (rag - 0.5)
             + 0.08 * smoothstep(0.4, 0.8, nz))
    fline = fline * (1.0 - south) + (0.82 + 0.12 * (rag - 0.5)) * south
    fline = fline * (1.0 - north) + 0.55 * north
    forest = smoothstep(fline + 0.04, fline - 0.04, rel)
    # fagul jos, doar la sud si pe culmile apropiate
    beech_w = smoothstep(0.30, 0.12, rel) * south
    trees = spruce * (1 - beech_w)[..., None] + beech * beech_w[..., None]
    # rariste de padure, petice de pajiste in ea
    clear = smoothstep(0.62, 0.72, fbm(px, py, 140.0, 59, octaves=3)) * 0.8
    forest = forest * (1 - clear)
    # jneapanul: petice inchise imediat peste linia padurii
    jn = smoothstep(fline - 0.02, fline + 0.05, rel) * smoothstep(fline + 0.22, fline + 0.10, rel)
    jn = jn * smoothstep(0.45, 0.6, fbm(px, py, 50.0, 61, octaves=3))
    # sistul iese pe fetele abrupte si pe ultimul sfert al crestei principale
    steep = smoothstep(0.74, 0.52, nz)
    high = smoothstep(0.72, 0.90, rel) * (0.25 + 0.75 * main)
    # pe planurile din fund (>= 4,6 km) creasta e iarba si aer, nu perete de sist
    # aprins: altfel lantul de la est citea a Alpi albi
    high = high * (1.0 - 0.75 * ((kid >= 3) & (kid < 100)))
    rock_w = np.clip(np.maximum(steep, high) * (1.0 - 0.55 * south), 0.0, 1.0)
    rock_w = rock_w * smoothstep(fline, fline + 0.12, rel)
    # pajiste uscata pe culmile sudice, sus
    meadow = meadow * (1 - (south * smoothstep(0.75, 1.0, rel) * 0.5))[..., None] \
        + lin(MEADOW_DRY) * (south * smoothstep(0.75, 1.0, rel) * 0.5)[..., None]
    col = meadow
    col = col * (1 - jn * 0.85)[..., None] + lin(JNEAPAN) * (jn * 0.85)[..., None]
    col = col * (1 - rock_w)[..., None] + rock * rock_w[..., None]
    col = col * (1 - forest)[..., None] + trees * forest[..., None]

    # campia la nord: fasii de camp (verzi + unul galben), palcuri de padure
    plain = north * smoothstep(2.0, 0.6, rel) * smoothstep(1500.0, 3500.0, rr)
    strip = vnoise(px * 0.9 + py * 0.25, py * 0.9 - px * 0.25, 260.0, 81)
    fields = np.where(strip[..., None] > 0.72, lin("B6AE5C")[None, None, :],
                      np.where(strip[..., None] > 0.45, lin("7FA24A")[None, None, :],
                               lin("6A9443")[None, None, :]))
    woods = smoothstep(0.52, 0.62, fbm(px, py, 700.0, 83, octaves=3))
    fields = fields * (1 - woods)[..., None] + lin(SPRUCE[2]) * woods[..., None]
    col = col * (1 - plain)[..., None] + fields * plain[..., None]

    # zapada de iulie: petice sus pe creasta principala, in caldari (concavitati
    # mici, fete culcate) si pe fetele nordice de sub creasta; niciodata pe sud
    cap = 0.74 - 0.12 * north_face + 0.10 * (fbm(px, py, 140.0, 85, octaves=3) - 0.5)
    snow = smoothstep(cap, cap + 0.05, rel)
    # petice, nu glazura: zgomot fin (caldari, viroage) si numai pe fete nu prea
    # abrupte (pe peretii verticali zapada nu sta)
    snow = snow * smoothstep(0.48, 0.66, fbm(px, py, 32.0, 87, octaves=4))
    snow = snow * smoothstep(0.35, 0.6, nz)
    snow = snow * (0.3 + 0.7 * north_face) * main * (1.0 - south)
    snow = snow * (1.0 - 0.4 * giant)
    snow = np.clip(snow * 1.3, 0.0, 1.0)
    slit = smoothstep(0.3, 0.75, nz) * (1.0 - 0.6 * north_face)
    scol = lin(SNOW)[None, None, :] * slit[..., None] + lin(SNOW_SHADE)[None, None, :] * (1 - slit)[..., None]
    col = col * (1 - snow)[..., None] + scol * snow[..., None]
    print("banda: zapada pe %.1f%%, padure %.1f%%, sist %.1f%% din varfuri" % (
        100.0 * (snow > 0.5).mean(), 100.0 * (forest > 0.5).mean(), 100.0 * (rock_w > 0.5).mean()))
    return np.concatenate([col.reshape(-1, 3), snow.reshape(-1, 1)], axis=1)


# --- Marea de nori ---------------------------------------------------------------

CLOUD_Z = -6.0           # varful norilor: sub cota drumului, in vai
CLOUD_SECTOR = (125.0, 55.0, 20.0)       # busola: centru, semilatime, margine


def build_clouds():
    """Marea de nori din vaile de E/SE (brief §1): un strat plat cu cocoase
    rotunde, cu goluri si cu marginea de sector moale; crestele ies din el."""
    n_az = 1024 if TEST else 3072
    n_r = 60 if TEST else 160
    az = np.linspace(0.0, math.tau, n_az, endpoint=False)
    rr = 1300.0 * np.power(26000.0 / 1300.0, np.linspace(0.0, 1.0, n_r))
    A, Rg = np.meshgrid(az, rr)
    px, py = np.sin(A) * Rg, np.cos(A) * Rg
    azd = np.degrees(A) % 360.0
    sect = az_bump(azd, *CLOUD_SECTOR)
    bil = fbm(px, py, 900.0, 91, octaves=4)
    puff = fbm(px, py, 220.0, 93, octaves=3)
    cov = smoothstep(0.40, 0.55, bil) * sect * smoothstep(1300.0, 2200.0, Rg)
    z = CLOUD_Z - 18.0 + 22.0 * cov * (0.55 + 0.45 * puff)
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    ii, jj = np.meshgrid(np.arange(n_r - 1), np.arange(n_az), indexing="ij")
    j1 = (jj + 1) % n_az
    quads = np.stack([ii * n_az + jj, ii * n_az + j1, (ii + 1) * n_az + j1,
                      (ii + 1) * n_az + jj], axis=-1).reshape(-1)
    nf = (n_r - 1) * n_az
    me = bpy.data.meshes.new("BandClouds")
    me.vertices.add(n_r * n_az)
    me.vertices.foreach_set("co", co.astype(np.float32).ravel())
    me.loops.add(nf * 4)
    me.loops.foreach_set("vertex_index", quads.astype(np.int32))
    me.polygons.add(nf)
    me.polygons.foreach_set("loop_start", (np.arange(nf) * 4).astype(np.int32))
    me.polygons.foreach_set("loop_total", np.full(nf, 4, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    for p in me.polygons:
        p.use_smooth = True
    attr = me.attributes.new("cov", "FLOAT", "POINT")
    attr.data.foreach_set("value", np.clip(cov * 1.1, 0.0, 1.0).astype(np.float32).ravel())
    ob = bpy.data.objects.new("BandClouds", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(cloud_material())
    ob.visible_shadow = False
    print("banda: marea de nori, %d fete" % nf)


# --- Lumina, camera ----------------------------------------------------------------

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
    sc.cycles.transparent_max_bounces = 16
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
    cd.clip_end = 80000.0
    cam = bpy.data.objects.new("BandCam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, 0.0, CAM_Z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # priveste spre +Y (nord)
    sc.camera = cam

    sd = sun_dir_blender()
    print("banda: soarele spre busola %.1f, elevatie %.1f" % (
        math.degrees(math.atan2(sd.x, sd.y)) % 360.0, math.degrees(math.asin(sd.z))))
    ld = bpy.data.lights.new("BandSun", "SUN")
    ld.energy = SUN_STRENGTH
    ld.color = srgb(SUN_COLOR)[:3]
    ld.angle = math.radians(0.6)
    sun = bpy.data.objects.new("BandSun", ld)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (-sd).to_track_quat("-Z", "Y").to_euler()

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
        vs = [(x + dx * s, y + dy * s, 60 + dz * s) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
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
build_land()
build_clouds()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
