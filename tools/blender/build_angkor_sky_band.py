"""Banda de orizont a cerului Angkor (Track24) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/angkor_horizon_band.png`, o felie equirectangulara de
360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa: campia
Cambodgiei la amurg — marea de coronament a junglei (coroane de dipterocarpi ca
domuri, cu emergenti razleti), orezarii inundate care oglindesc cerul spre V, cu
palmieri de zahar pe diguri, barayul de vest (lac dreptunghiular) cu un prang mic pe
insula, dealurile Phnom Krom (SV) si Phnom Bok (NE) cu cate un prang mic in varf, si
creasta joasa, plata, a platoului Phnom Kulen la NE. Primul plan (`NEAR_GROVES`,
0,6-0,75 km) sunt palcuri de copaci URIASI pe movile, puse de mana pe directiile
camerei de joc: ei dau scara. Cerul ramane TRANSPARENT: gradientul lui il deseneaza
shaderul de cer din joc (`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Monument Valley / Serengeti (relieful e un camp de inaltimi POLAR,
numpy; copacii sunt GLB-urile kitului, `assets/models/angkor/plants/`, cu atlasul de
paleta al jocului). Doua lucruri sunt noi aici:

1. CERUL PE AZIMUT. Tema "angkor" are `sky_azimuth`: peste gradientul cer/orizont
   shaderul ADUNA o textura generata (`Track._azimuth_sky_texture`): piersica sub
   soare (V), vanat-violet in partea opusa (E). Deci aerul in care se topeste
   departarea nu e o culoare: e `HAZE(azimut)`, refacut aici cu ACEEASI formula
   (fara zgomotul de nor) intr-o imagine de 256 x 1, citita de fiecare material dupa
   busola punctului. Spre V coronamentul se spala in piersica, spre E in violet;
   orezariile oglindesc acelasi cer. Masurat pe captura: pe ecran piersica sta SUB
   soare (busola 247,5), desi textura generata o eticheteaza cu 180 de grade alaturi
   (conventia SKY_COORDS) — conteaza ce se vede.
2. CEATA JOCULUI. Jungla 3D a pistei intra la FAR_PLANE (380 m) cu `fog_max` 0,60 din
   ceata temei (`FOGC` 86727A): trunchiuri fantoma mov-cenusii. Tot ce e in banda
   poarta deci cel putin acelasi strat (`FOG_F0`), altfel un palc de la 700 m ar iesi
   mai saturat decat copacii reali de la 280 m (adancime inversata). Podeaua de sub
   380 m e ceata intreaga (`FOGC`), deci `below` = `fog` = 86727A: ceata temei ramane
   cea de amurg, mov, mai rece si mai palida decat solul (memoria
   `ceata-in-familia-solului`), si tot ea e podeaua benzii.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste campie, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "angkor" (`sun_rotation_deg` (-24, -67.5, 0), adica busola
    247,5, VSV, 24 de grade elevatie), `sun_color` FFC078, energia 1,75; ambientul
    9C97BC la 0,30;
  * HAZE(azimut) = `sky_horizon` A6788A + `sky_azimuth` (vezi `haze_table`);
  * FOGC = `fog` 86727A, FOG_F0 = `fog_max` 0,60;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Reperele 3D ale pistei NU se dubleaza: Angkor Wat sta spre E de pe grila (busola
65-115 ramane fara prang si fara palc), Bakhengul, uriasii, poarta si Bayonul sunt in
joc. Prangurile din banda sunt mici (0,2-0,6 grade) si la kilometri.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import bmesh
import math
import os
import random
import sys

import numpy as np
from mathutils import Vector, noise

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Ochiul: drumul sta la +3..+20 peste santuri, camera la 10 m peste drum (13-30 m), pe
# Bakheng +48. 30 m e DEASUPRA coronamentului (19-31 m): de la 16 m (prima randare) cea
# mai apropiata centura de padure, la 400 m, urca la 1,2 grade si ascunde tot ce e in
# spate — un zid, nu o „mare de jungla" (brief §0: turnurile ies dintr-o mare de
# jungla). Coronamentul e oricum peste trunchiurile-fantoma ale jocului.
CAM_Z = 30.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "angkor_horizon_band_test.png" if TEST
                   else "angkor_horizon_band.png")


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


def lin1(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


# --- Tema "angkor" (scenes/tracks/track.gd) -----------------------------------------
SKY_TOP = "2D2740"
SKY_HORIZON = "A6788A"
SKY_CURVE = 0.15                          # implicitul ProceduralSkyMaterial
# sky_azimuth (culorile sunt sRGB, ca Color() din tema)
AZ_SUN_COLOR = (1.0, 0.72, 0.46)
AZ_SUN_ALPHA, AZ_SUN_HEIGHT = 0.80, 0.50
AZ_AWAY_COLOR = (0.15, 0.09, 0.26)
AZ_AWAY_ALPHA, AZ_AWAY_HEIGHT = 0.90, 1.2
HAZE_ELEV = math.radians(0.7)             # aerul de la orizont, nu cerul de sus
FOGC = "86727A"                           # = fog din tema
FOG_F0 = 0.60                             # = fog_max din tema
SUN_ROT = (-24.0, -67.5)                  # sun_rotation_deg (x, y)
SUN_COLOR = "FFC078"
# Godot inmulteste energia luminii cu pi fata de Cycles (vezi Monument Valley):
# taria Cycles = pi x energia temei.
SUN_STRENGTH = math.pi * 1.75
AMBIENT = "9C97BC"
AMBIENT_ENERGY = 0.30

# --- Paleta (sRGB): kitul pistei ----------------------------------------------------
# Coronamentul: TROPICAL_GREEN 21 (3F7A3C) si vecinii lui; cateva coroane lime (frunza
# noua) si una-doua ruginii (dipterocarpi care-si schimba frunza).
CANOPY = ["3F7A3C", "386E38", "47823E", "2F6034", "35683A", "5A8C3A", "4A7A34"]
CANOPY_RARE = ["7E8A3C", "8A6A3A"]
CANOPY_DARK = "1E3A24"                    # golurile dintre coroane
PADDY_MUD = "5E6A3E"                      # orez verde-crud pe apa
PADDY_DIKE = "7A5E44"                     # digurile de laterita
BARAY_WATER = "3F5A52"                        # apa barayului (inchisa, oglinda)
KULEN_GREEN = "2E5232"                    # padurea de pe platou
HILL_ROCK = "8A7458"                      # gresie/laterita pe pante abrupte
STONE = "A8946E"                          # gresia prangurilor (ocru-gri)
STONE_DARK = "6A604E"                     # dare de muson / umbra de etaj
REFLECT = 0.85                            # cat din cer oglindeste apa la unghi razant

# Perspectiva aeriana: peste stratul de ceata al jocului (FOG_F0), aerul trage spre
# HAZE(azimut): fac = 1 - exp(-(d - d0) * fwd / D), plafonat la HAZE_MAX. Aer umed de
# muson: la 4 km pe jumatate, Kulenul de la 20 km o umbra.
HAZE_D0, HAZE_D, HAZE_MAX = 380.0, 4200.0, 0.84
FWD_K = 0.9                               # aerul spre soare (contre-jour mai spalat)
MIST_H, MIST_K = 22.0, 0.30               # ceata joasa de seara peste orezarii, departe


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


def az_window(A_deg, lo, hi, soft):
    """1 in sectorul [lo, hi] (grade busola, poate trece prin 0), topit pe `soft` grade."""
    c = (lo + hi) * 0.5
    half = ((hi - lo) % 360.0) * 0.5
    dd = np.abs((A_deg - c + 180.0) % 360.0 - 180.0)
    return smoothstep(half + soft, half, dd)


def crowns(x, y, cell, seed):
    """Coroane ca domuri: celule Voronoi pe o grila cu jitter. Intoarce (dom 0..1,
    id-ul celulei 0..1) — domul e 1 in centrul coroanei, 0 in golul dintre ele."""
    u, v = x / cell, y / cell
    iu, iv = np.floor(u), np.floor(v)
    best = np.full(u.shape, 9.0)
    bid = np.zeros(u.shape)
    for di in (-1.0, 0.0, 1.0):
        for dj in (-1.0, 0.0, 1.0):
            ci, cj = iu + di, iv + dj
            px = ci + 0.15 + 0.7 * _hash2(ci, cj, seed)
            py = cj + 0.15 + 0.7 * _hash2(ci, cj, seed + 7)
            dd = (u - px) ** 2 + (v - py) ** 2
            m = dd < best
            best = np.where(m, dd, best)
            bid = np.where(m, _hash2(ci, cj, seed + 13), bid)
    d = np.sqrt(best) / 0.62
    dome = np.sqrt(np.clip(1.0 - d * d, 0.0, 1.0))
    return dome, bid


# --- Cerul pe azimut (HAZE) --------------------------------------------------------

def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    rx, ry = math.radians(SUN_ROT[0]), math.radians(SUN_ROT[1])
    x, y, z = 0.0, -math.sin(rx), math.cos(rx)
    gx = x * math.cos(ry) + z * math.sin(ry)
    gz = -x * math.sin(ry) + z * math.cos(ry)
    g = Vector((gx, y, gz))                     # Godot: x est, y sus, z sud
    return Vector((g.x, -g.z, g.y)).normalized()  # Blender: x est, y nord, z sus


def sun_compass():
    s = sun_dir_blender()
    return math.degrees(math.atan2(s.x, s.y)) % 360.0


def haze_color(compass_deg, elev=HAZE_ELEV):
    """Cerul jocului la busola data, liniar: gradientul ProceduralSky + sky_azimuth
    ADUNAT (fara zgomotul de nor). Formula din `Track._azimuth_sky_texture`, cu
    piersica sub soare (asa iese pe ecran)."""
    c = 1.0 - (math.pi * 0.5 - elev) / (math.pi * 0.5)
    g = min(max(1.0 - (1.0 - c) ** (1.0 / SKY_CURVE), 0.0), 1.0)
    hor, top = lin(SKY_HORIZON), lin(SKY_TOP)
    sky = hor * (1.0 - g) + top * g
    rel = math.radians(compass_deg - sun_compass())
    x = (1.0 - math.cos(rel)) * 0.5                 # 0 sub soare, 1 opus
    t = min(max((x - 0.15) / 0.7, 0.0), 1.0)
    away_t = t * t * (3.0 - 2.0 * t)
    kw = math.exp(-elev / AZ_SUN_HEIGHT) * (1.0 - away_t)
    ka = (0.35 + 0.65 * math.exp(-elev / AZ_AWAY_HEIGHT)) * away_t
    col = [AZ_SUN_COLOR[i] * (1.0 - away_t) + AZ_AWAY_COLOR[i] * away_t for i in range(3)]
    a = min(max(AZ_SUN_ALPHA * kw + AZ_AWAY_ALPHA * ka, 0.0), 1.0)
    return [sky[i] + lin1(col[i]) * a for i in range(3)]


def haze_table():
    """Imagine 256 x 1, liniara: pixelul i = busola (i + 0,5) / 256 * 360."""
    n = 256
    img = bpy.data.images.new("HazeAz", n, 1, alpha=True, float_buffer=True)
    img.colorspace_settings.name = "Non-Color"
    px = []
    for i in range(n):
        c = haze_color((i + 0.5) / n * 360.0)
        px += [c[0], c[1], c[2], 1.0]
    img.pixels = px
    for cc in (0, 45, 90, 135, 180, 225, 247.5, 270, 315):
        h = haze_color(cc)
        print("banda: HAZE busola %5.1f -> %.3f %.3f %.3f" % (cc, h[0], h[1], h[2]))
    return img


HAZE_IMG = None


# --- Materiale ------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups, bpy.data.images):
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


def _math(n, L, op, a=None, b=None, va=None, vb=None):
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


def haze_node(nt):
    """HAZE(busola punctului fata de ochi): imaginea de 256 x 1 citita pe azimut."""
    n, L = nt.nodes, nt.links
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])
    at = _math(n, L, "ARCTAN2", sep.outputs[0], sep.outputs[1])      # busola, radiani
    u = _math(n, L, "DIVIDE", at, vb=math.tau)
    cmb = n.new("ShaderNodeCombineXYZ")
    L.new(u, cmb.inputs[0])
    cmb.inputs[1].default_value = 0.5
    tex = n.new("ShaderNodeTexImage")
    tex.image = HAZE_IMG
    tex.interpolation = "Linear"
    tex.extension = "REPEAT"
    L.new(cmb.outputs[0], tex.inputs["Vector"])
    return tex.outputs["Color"]


def haze_wrap(nt, surface_socket, out_node, k=1.0):
    """surface -> (1) ceata jocului: 1 sub 380 m (acolo e terenul real), FOG_F0
    dincolo de 470 m (cat au copacii reali la FAR_PLANE); (2) aerul spre HAZE(azimut)
    dupa distanta, mai gros spre soare, plus ceata joasa de seara departe.
    `k` < 1 slabeste aerul (palcurile apropiate)."""
    n = nt.nodes
    L = nt.links
    cam = n.new("ShaderNodeCameraData")
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])
    d = cam.outputs["View Distance"]

    fog = n.new("ShaderNodeMapRange")
    L.new(d, fog.inputs["Value"])
    fog.inputs["From Min"].default_value = HAZE_D0
    fog.inputs["From Max"].default_value = HAZE_D0 + 90.0
    fog.inputs["To Min"].default_value = 1.0
    fog.inputs["To Max"].default_value = FOG_F0
    em_fog = n.new("ShaderNodeEmission")
    em_fog.inputs["Color"].default_value = srgb(FOGC)
    m1 = n.new("ShaderNodeMixShader")
    L.new(fog.outputs["Result"], m1.inputs[0])
    L.new(surface_socket, m1.inputs[1])
    L.new(em_fog.outputs[0], m1.inputs[2])

    x = _math(n, L, "SUBTRACT", d, vb=HAZE_D0)
    x = _math(n, L, "MAXIMUM", x, vb=0.0)
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
    fwd = _math(n, L, "MAXIMUM", dot.outputs["Value"], vb=0.0)
    fwd = _math(n, L, "POWER", fwd, vb=2.0)
    fwd = _math(n, L, "MULTIPLY", fwd, vb=FWD_K)
    fwd = _math(n, L, "ADD", fwd, vb=1.0)
    x = _math(n, L, "MULTIPLY", x, fwd)
    x = _math(n, L, "MULTIPLY", x, vb=-1.0 / HAZE_D)
    x = _math(n, L, "EXPONENT", x)
    air = _math(n, L, "SUBTRACT", va=1.0, b=x)
    air = _math(n, L, "MINIMUM", air, vb=HAZE_MAX)
    air = _math(n, L, "MULTIPLY", air, vb=k)
    z = _math(n, L, "MAXIMUM", sep.outputs[2], vb=0.0)
    z = _math(n, L, "MULTIPLY", z, vb=-1.0 / MIST_H)
    z = _math(n, L, "EXPONENT", z)
    rmp = n.new("ShaderNodeMapRange")
    L.new(d, rmp.inputs["Value"])
    rmp.inputs["From Min"].default_value = 1200.0
    rmp.inputs["From Max"].default_value = 7000.0
    low = _math(n, L, "MULTIPLY", z, rmp.outputs["Result"])
    low = _math(n, L, "MULTIPLY", low, vb=MIST_K)
    keep = _math(n, L, "SUBTRACT", va=1.0, b=air)
    keep_low = _math(n, L, "SUBTRACT", va=1.0, b=low)
    keep = _math(n, L, "MULTIPLY", keep, keep_low)
    fac = _math(n, L, "SUBTRACT", va=1.0, b=keep)
    em_air = n.new("ShaderNodeEmission")
    L.new(haze_node(nt), em_air.inputs["Color"])
    m2 = n.new("ShaderNodeMixShader")
    L.new(fac, m2.inputs[0])
    L.new(m1.outputs[0], m2.inputs[1])
    L.new(em_air.outputs[0], m2.inputs[2])
    L.new(m2.outputs[0], out_node.inputs["Surface"])


def land_material():
    """Culoarea in `Col` (rgb), apa in alfa: apa = oglinda cerului HAZE(azimut) la
    unghi razant (orezariile si barayul lucesc piersica spre V, violet spre E)."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(at.outputs["Color"], bsdf.inputs["Color"])
    refl = n.new("ShaderNodeEmission")
    L.new(haze_node(nt), refl.inputs["Color"])
    refl.inputs["Strength"].default_value = REFLECT
    wet = n.new("ShaderNodeMixShader")
    L.new(at.outputs["Alpha"], wet.inputs[0])
    L.new(bsdf.outputs[0], wet.inputs[1])
    L.new(refl.outputs[0], wet.inputs[2])
    haze_wrap(nt, wet.outputs[0], out)
    return mat


def atlas_haze_material(name="BandAtlas", k=1.0):
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    tex = n.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ATLAS, check_existing=True)
    tex.interpolation = "Closest"
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Specular IOR Level"].default_value = 0.1
    L.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out, k)
    return mat


def vcol_lit_material(name, k=1.0):
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(at.outputs["Color"], bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out, k)
    return mat


# --- Directiile camerei de joc --------------------------------------------------------
#
# Masurate cu o sonda temporara pe Track24.baked (ChaseCamera: 10 m sus, 12,5 m in
# spate, fov 68 vertical = ~100 de grade pe orizontala la 16:9). Busola: 0 = N.
#
#   portiunea                              fractii      directia camerei   cer in cadru
#   calea de vest, spre Angkor Wat (3D)    0,00-0,08    90                 ~5-7 grade
#   urcarea pe Bakheng                     0,13-0,23    327-360, 280-257   ~9-10 grade
#   coborarea                              0,24-0,33    180 -> 270 -> 0    ~2 grade
#   calea uriasilor, spre N                0,30-0,39    0                  ~5 grade
#   spre Bayon, spre E                     0,41-0,50    90                 ~5-10 grade
#   terasa Elefantilor, spre S             0,55-0,62    180                ~5 grade
#   Ta Prohm (serpuit)                     0,64-0,78    116-270
#   malul de sud, spre V (in soare)        0,79-0,92    270                ~7 grade
#
# Soarele e la busola 247,5: privind spre V/SV formele sunt in contre-jour.
#
# Regulile plasarii (lectiile pilotului): niciun palc pe axa unei drepte lungi, ci
# la 15-35 de grade lateral; nimic intre 65 si 115 (Angkor Wat 3D de pe grila);
# primul plan DINCOLO de ~0,6 km; inaltimea aleasa in GRADE de la ochi.
#
# INALTIMEA (masurata pe capturi --gamecam, prima randare): jungla 3D a pistei pune
# trunchiuri-fantoma cetoase la 200-280 m pana la ~5-6 grade peste orizont (orizontul la
# y ~95 din 720, ~12,5 px pe grad). Palcurile de 3-5 grade din prima randare stateau
# toate IN SPATELE lor: diferenta fata de „inainte" era sub 0,5% din pixeli. Deci planul
# 0 urca la 7-8 grade: un phnom impadurit (movila de 34-48 m, ca dealurile-templu ale
# campiei) cu copaci uriasi pe el (tetrameles / dipterocarpi de 65-85 m), care ies pe
# cer deasupra fantomelor. Ceata lor e aceeasi (FOG_F0): se citesc prin SILUETA pe cerul
# piersica / violet, nu prin culoare.
#
# (nume, busola, distanta, movila m, raza movilei m, copaci, scara min, scara max, seed)
NEAR_GROVES = [
    # A — spre E in stanga (32 de grade de axa, la stanga templului), spre N in dreapta
    ("A", 56.0, 680.0, 44.0, 140.0, 15, 1.95, 2.35, 31),
    # B — spre E in dreapta (32 de grade), langa Ta Prohm
    ("B", 124.0, 650.0, 38.0, 130.0, 13, 1.90, 2.25, 32),
    # C — urcarea (327) in dreapta, calea uriasilor (0) in stanga
    ("C", 344.0, 680.0, 48.0, 150.0, 16, 2.00, 2.40, 33),
    # D — malul de sud (270) in dreapta (22 de grade), urcarea (327) in stanga; la 302
    # acoperea West Mebon (prangul de pe insula barayului)
    ("D", 292.0, 700.0, 42.0, 140.0, 14, 1.95, 2.30, 34),
    # E — malul de sud in stanga (32 de grade), in contre-jour (soarele la 247,5)
    ("E", 236.0, 690.0, 36.0, 130.0, 12, 1.90, 2.20, 35),
    # F — terasa Elefantilor (180) in dreapta
    ("F", 202.0, 620.0, 40.0, 130.0, 14, 1.95, 2.30, 36),
    # G — terasa Elefantilor in stanga, mai mic
    ("G", 158.0, 720.0, 34.0, 120.0, 11, 1.85, 2.15, 37),
]

# Sectorul DESCHIS: orezarii inundate cu palmieri de zahar, spre V-NV (unde e si
# barayul de vest). Dincolo de 6 km padurea revine in fasii.
OPEN_W = (226.0, 336.0)

# Barayul de vest: lac dreptunghiular E-V (real 8 x 2,1 km, la NV de Angkor Thom).
# Centrul la busola 306, 3,4 km; laturile in metri (E-V, N-S).
BARAY = dict(az=312.0, d=3400.0, lx=3600.0, ly=900.0)

# Dealurile (phnom): (busola, distanta, inaltime, raza)
PHNOM_KROM = (213.0, 5600.0, 140.0, 900.0)     # SV, langa Tonle Sap
PHNOM_BOK = (38.0, 9000.0, 210.0, 1200.0)      # NE
# Platoul Kulen: NE, lung, plat, cu escarpa; 18-26 km
KULEN = dict(lo=8.0, hi=74.0, r_in=17500.0, r_out=27000.0, h=470.0)

N_AZ = 1024 if TEST else 6144
N_R = 140 if TEST else 560
R0, R1 = 60.0, 40000.0


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


def set_vcol(me, col, alpha):
    n = col.reshape(-1, 3).shape[0]
    rgba = np.concatenate([col.reshape(-1, 3), alpha.reshape(-1, 1)], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())


def _at(az, d):
    a = math.radians(az)
    return math.sin(a) * d, math.cos(a) * d


def ground_height(px, py):
    """Solul (fara coronament): campia, movilele palcurilor, dealurile, Kulenul."""
    r = np.hypot(px, py)
    A = (np.degrees(np.arctan2(px, py)) + 360.0) % 360.0
    z = (fbm(px, py, 2400.0, 5, octaves=3) - 0.5) * 6.0 * smoothstep(1500.0, 5000.0, r)
    for name, az, d, mh, mr, *_ in NEAR_GROVES:
        cx, cy = _at(az, d)
        q = np.hypot(px - cx, py - cy) / mr
        z = z + mh * np.clip(1.0 - q * q, 0.0, 1.0) ** 1.5
    for az, d, h, rad in (PHNOM_KROM, PHNOM_BOK):
        cx, cy = _at(az, d)
        q = np.hypot(px - cx, py - cy) / rad
        bump = np.clip(1.0 - q, 0.0, 1.0)
        z = z + h * bump ** 1.2 * (0.85 + 0.15 * fbm(px, py, 300.0, 9, octaves=3))
    # Kulenul: platou cu escarpa, marginea zdrentuita
    kw = az_window(A, KULEN["lo"], KULEN["hi"], 6.0)
    edge = KULEN["r_in"] + 2500.0 * (fbm(px, py, 3000.0, 27, octaves=4) - 0.5)
    plat = smoothstep(edge, edge + 1600.0, r) * smoothstep(KULEN["r_out"] + 4000.0,
                                                           KULEN["r_out"], r)
    zk = KULEN["h"] * (0.88 + 0.12 * fbm(px, py, 2500.0, 29, octaves=3))
    z = np.maximum(z, kw * plat * zk)
    return z


def land_masks(px, py):
    """(padure 0..1, apa 0..1, orezarie 0..1, dig 0..1)"""
    r = np.hypot(px, py)
    A = (np.degrees(np.arctan2(px, py)) + 360.0) % 360.0
    big = fbm(px, py, 900.0, 41, octaves=4)
    # sectorul de V: orezarii de la ~450 m, insule de padure, fasii dincolo de 6 km
    w_open = az_window(A, OPEN_W[0], OPEN_W[1], 14.0)
    island = smoothstep(0.62, 0.70, big)
    belts = smoothstep(0.50, 0.62, fbm(px, py, 2600.0, 43, octaves=3)) * smoothstep(5000.0, 8000.0, r)
    forest_w = np.maximum(island, belts)
    # restul: jungla, cu luminisuri de orez dincolo de 1,5 km
    clear = smoothstep(0.34, 0.26, big) * smoothstep(1500.0, 2500.0, r)
    forest = (1.0 - w_open) * (1.0 - clear) + w_open * forest_w
    # palcurile apropiate stau mereu in padure
    for name, az, d, mh, mr, *_ in NEAR_GROVES:
        cx, cy = _at(az, d)
        q = np.hypot(px - cx, py - cy) / (mr * 1.4)
        forest = np.maximum(forest, smoothstep(1.0, 0.7, q))
    # Sub ~400 m e terenul jocului (si ceata lui): banda n-are nimic acolo, doar podea.
    forest = forest * smoothstep(395.0, 440.0, r)
    paddy = (1.0 - forest) * smoothstep(395.0, 440.0, r)
    # barayul
    ba = math.radians(BARAY["az"])
    bx, by = math.sin(ba) * BARAY["d"], math.cos(ba) * BARAY["d"]
    inb = smoothstep(BARAY["lx"] * 0.5, BARAY["lx"] * 0.5 - 40.0, np.abs(px - bx)) * \
        smoothstep(BARAY["ly"] * 0.5, BARAY["ly"] * 0.5 - 40.0, np.abs(py - by))
    # insula West Mebon, in mijloc
    isl = smoothstep(90.0, 60.0, np.hypot(px - bx, py - by))
    water = inb * (1.0 - isl)
    forest = forest * (1.0 - inb) + isl * 0.0
    paddy = paddy * (1.0 - inb)
    # digurile: grila de ~60 m, rotita usor pe petice
    gx = np.abs(((px + 13.0 * fbm(px, py, 400.0, 51, octaves=2)) / 58.0) % 1.0 - 0.5)
    gy = np.abs(((py + 13.0 * fbm(px, py, 400.0, 53, octaves=2)) / 46.0) % 1.0 - 0.5)
    dike = smoothstep(0.43, 0.48, np.maximum(gx, gy)) * paddy
    return forest, water, paddy, dike, isl


def build_land():
    A, Rg, px, py = polar_grid(N_AZ, N_R, R0, R1)
    zg = ground_height(px, py)
    forest, water, paddy, dike, isl = land_masks(px, py)
    # coronamentul: 20-27 m, coroane de ~13 m (dom 6 m) si emergenti mici
    dome, cid = crowns(px, py, 13.0, 61)
    base_h = 19.0 + 7.0 * fbm(px, py, 700.0, 63, octaves=3)
    can_h = base_h + 6.0 * dome + 4.0 * (cid - 0.5)
    # Kulenul si dealurile sunt impadurite, dar de la 5+ km coroanele sunt sub pixel
    # Inaltimea coronamentului urca pe primii ~250 m: o centura intreaga de 25 m chiar de
    # la 400 m iesea ca un ZID cu fata verticala (dungi de ceata sub orizont).
    zc = zg + forest * can_h * smoothstep(395.0, 640.0, Rg)
    zc = np.where(water > 0.5, np.minimum(zc, 0.2), zc)
    co = np.stack([px, py, zc], axis=-1).reshape(-1, 3)
    me = grid_mesh("BandLand", co, N_R, N_AZ)
    nrm = np.empty(N_R * N_AZ * 3, dtype=np.float32)
    me.vertex_normals.foreach_get("vector", nrm)
    nz = nrm.reshape(N_R, N_AZ, 3)[..., 2]

    # culoarea coronamentului: o nuanta per coroana, golurile intunecate
    pal = np.array([lin(c) for c in CANOPY])
    rare = np.array([lin(c) for c in CANOPY_RARE])
    k = np.minimum((cid * len(CANOPY)).astype(int), len(CANOPY) - 1)
    col = pal[k]
    r2 = _hash2(np.floor(px / 13.0), np.floor(py / 13.0), 71)
    use_r = (r2 > 0.965)[..., None]
    col = np.where(use_r, rare[(r2 * 100).astype(int) % len(rare)], col)
    gap = smoothstep(0.0, 0.55, dome)
    col = col * (0.45 + 0.55 * gap)[..., None] + lin(CANOPY_DARK) * (1.0 - gap)[..., None] * 0.45
    # platoul Kulen si dealurile: padure mai inchisa, stanca pe pante abrupte
    hi = smoothstep(60.0, 160.0, zg)
    col = col * (1 - hi)[..., None] + lin(KULEN_GREEN) * hi[..., None]
    steep = smoothstep(0.80, 0.55, nz) * smoothstep(40.0, 120.0, zg) * 0.6
    col = col * (1 - steep)[..., None] + lin(HILL_ROCK) * steep[..., None]
    # orezarii, diguri, baray
    pcol = lin(PADDY_MUD) * (1 - dike)[..., None] + lin(PADDY_DIKE) * dike[..., None]
    col = col * forest[..., None] + pcol * (1.0 - forest)[..., None]
    col = col * (1 - water)[..., None] + lin(BARAY_WATER) * water[..., None]
    wet = np.clip(paddy * (1.0 - dike) * 0.75 + water, 0.0, 1.0) * (1.0 - forest)
    wet = np.maximum(wet, water)
    set_vcol(me, col, wet)
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d varfuri" % (N_R, N_AZ))
    return forest, px, py, zg


def ground_at(x, y):
    return float(ground_height(np.array([x]), np.array([y]))[0])


def forest_at(x, y):
    f, *_ = land_masks(np.array([x]), np.array([y]))
    return float(f[0])


# --- Copacii (GLB-urile kitului) ------------------------------------------------------

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


def load_protos(files, mat):
    protos = []
    for fn in files:
        path = os.path.join(MODELS, *fn.split("/"))
        if not os.path.exists(path):
            print("LIPSA: " + path)
            continue
        o = import_joined(path)
        o.data.materials.append(mat)
        o.hide_render = True
        o.location = (0, 0, -1000)
        protos.append(o)
    return protos


def place(protos, rng, x, y, z, s, sz=1.0):
    p = protos[rng.randrange(len(protos))]
    o = p.copy()
    bpy.context.collection.objects.link(o)
    o.hide_render = False
    o.location = (x, y, z - 0.5)
    o.rotation_euler = (0.0, 0.0, rng.uniform(0.0, math.tau))
    o.scale = (s, s * rng.uniform(0.9, 1.1), s * sz)


def build_trees():
    mat = atlas_haze_material("BandTrees")
    big = load_protos(["angkor/plants/dipterocarp.glb", "angkor/plants/tetrameles_a.glb",
                       "angkor/plants/tetrameles_b.glb"], mat)
    palms = load_protos(["angkor/plants/sugar_palm.glb"], mat)
    if not big:
        return
    rng = random.Random(5)
    n_g = n_e = n_p = 0
    # 1. palcurile apropiate: copaci URIASI pe movila (dau scara)
    for name, az, d, mh, mr, cnt, s0, s1, seed in NEAR_GROVES:
        rg = random.Random(seed)
        cx, cy = _at(az, d)
        tops = []
        for i in range(cnt):
            a = rg.uniform(0.0, math.tau)
            q = (rg.random() ** 0.7) * mr * 0.75
            x, y = cx + math.cos(a) * q, cy + math.sin(a) * q
            s = rg.uniform(s0, s1) * (1.0 - 0.25 * q / mr)
            place(big, rg, x, y, ground_at(x, y), s, rg.uniform(0.95, 1.1))
            tops.append(ground_at(x, y) + 35.0 * s)
            n_g += 1
        e = math.degrees(math.atan2(max(tops) - CAM_Z, d))
        print("banda: palc %s busola %.0f d %.0f varf %.0f m -> %.1f grade" % (name, az, d, max(tops), e))
    # 2. emergenti razleti deasupra coronamentului (0,42-2,5 km), in padure
    tries = 0
    while n_e < (60 if TEST else 420) and tries < 20000:
        tries += 1
        az = rng.uniform(0.0, 360.0)
        d = 420.0 * (6.0 ** (rng.random() ** 0.9))
        x, y = _at(az, d)
        if forest_at(x, y) < 0.9:
            continue
        if any(math.hypot(x - _at(p[1], p[2])[0], y - _at(p[1], p[2])[1]) < 260.0 for p in PRANGS):
            continue
        place(big, rng, x, y, ground_at(x, y), rng.uniform(1.0, 1.3))
        n_e += 1
    # 3. palmierii de zahar: pe digurile orezariilor de la V, razleti si in siruri
    if palms:
        tries = 0
        while n_p < (80 if TEST else 900) and tries < 40000:
            tries += 1
            az = rng.uniform(OPEN_W[0] - 6.0, OPEN_W[1] + 6.0)
            d = 450.0 * (9.0 ** (rng.random() ** 1.1))
            x, y = _at(az, d)
            f = forest_at(x, y)
            if f > 0.3:
                continue
            row = rng.random() < 0.55
            k = rng.randint(3, 8) if row else 1
            ang = rng.choice([0.0, math.pi * 0.5]) + rng.uniform(-0.15, 0.15)
            for i in range(k):
                xx = x + math.cos(ang) * i * rng.uniform(9.0, 16.0)
                yy = y + math.sin(ang) * i * rng.uniform(9.0, 16.0)
                place(palms, rng, xx, yy, ground_at(xx, yy), rng.uniform(1.0, 1.45))
                n_p += 1
        # cativa si la marginea luminisurilor din jungla
        tries = 0
        while n_p < (100 if TEST else 1150) and tries < 40000:
            tries += 1
            az = rng.uniform(0.0, 360.0)
            d = rng.uniform(1500.0, 4500.0)
            x, y = _at(az, d)
            if not (0.05 < forest_at(x, y) < 0.5):
                continue
            place(palms, rng, x, y, ground_at(x, y), rng.uniform(1.0, 1.4))
            n_p += 1
    print("banda: %d uriasi in palcuri, %d emergenti, %d palmieri" % (n_g, n_e, n_p))


# --- Prangurile (turnuri-boboc de lotus), mici si departate ----------------------------

def prang(bm, col_layer, cx, cy, z0, h, rng):
    """Un prang khmer: soclu in trepte, celula patrata cu colturi in retrageri, apoi
    bobocul de lotus — etaje care se strang, cu o bordura la fiecare etaj, varf
    ascutit. Sectiunea e un patrat cu colturile retrase (cos 4a), nu un cerc."""
    segs = 48
    w = h * 0.30                                # semilatimea celulei
    prof = []                                   # (z relativ, raza, inchis?)
    prof += [(0.0, w * 1.55, 1), (h * 0.06, w * 1.55, 1), (h * 0.06, w * 1.35, 1),
             (h * 0.12, w * 1.35, 1), (h * 0.12, w * 1.15, 0), (h * 0.40, w * 1.05, 0)]
    tiers = 5
    zt = h * 0.40
    for i in range(tiers):
        t0 = i / tiers
        t1 = (i + 1) / tiers
        r0 = w * (1.08 - 0.12 * t0) * (1.0 - t0 ** 1.6)
        r1 = w * (1.0 - 0.12 * t1) * (1.0 - t1 ** 1.6)
        dz = h * 0.52 / tiers
        prof += [(zt, r0 * 1.08, 1), (zt + dz * 0.2, r0 * 1.08, 1),
                 (zt + dz * 0.25, r0 * 0.96, 0), (zt + dz, r1 * 1.0, 0)]
        zt += dz
    prof += [(h * 0.97, w * 0.05, 0), (h, 0.0, 0)]
    rot = rng.uniform(0.0, math.pi * 0.5)
    rings = []
    for (z, r, dark) in prof:
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            sq = 1.0 / max(abs(math.cos(a - rot)), abs(math.sin(a - rot))) ** 0.85
            red = 1.0 - 0.07 * max(0.0, math.cos(4.0 * (a - rot))) ** 8
            rr = max(r * min(sq, 1.35) * red, 0.0)
            v = bm.verts.new((cx + math.cos(a) * rr, cy + math.sin(a) * rr, z0 + z))
            ring.append((v, dark))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for j in range(segs):
            k = (j + 1) % segs
            f = bm.faces.new((rings[i][j][0], rings[i][k][0], rings[i + 1][k][0], rings[i + 1][j][0]))
            dk = rings[i][j][1]
            for lp in f.loops:
                lp[col_layer] = srgb(STONE_DARK) if dk else srgb(STONE)


def stepped_base(bm, col_layer, cx, cy, z0, half, tiers, tier_h):
    """Soclul in trepte al unui templu-munte (cutii suprapuse)."""
    z = z0
    for i in range(tiers):
        hw = half * (1.0 - 0.18 * i)
        res = bmesh.ops.create_cube(bm, size=1.0)
        for v in res["verts"]:
            v.co = Vector((cx + v.co.x * 2 * hw, cy + v.co.y * 2 * hw, z + (v.co.z + 0.5) * tier_h))
        for f in {f for v in res["verts"] for f in v.link_faces}:
            for lp in f.loops:
                lp[col_layer] = srgb(STONE if f.normal.z > 0.5 else STONE_DARK)
        z += tier_h
    return z


# (nume, busola, distanta, inaltimea prangului central, fel)
# Dimensionate pentru ecran: camera de joc are ~13 px pe grad, deci un prang trebuie sa
# iasa ~0,5-1 grad peste coronament ca sa se citeasca drept boboc, nu ca un pixel.
# Templele-munte reale (Ta Keo, Pre Rup) au 35-50 m; aici 40-48 m pe socluri de 12-16 m,
# la 2-3,5 km. Niciunul intre 65 si 115 (Angkor Wat 3D) si niciunul cu cinci turnuri.
PRANGS = [
    ("West Mebon", BARAY["az"], BARAY["d"], 48.0, "island"),
    ("Phnom Krom", PHNOM_KROM[0], PHNOM_KROM[1], 36.0, "hill"),
    ("insula din orezarii", 256.0, 2600.0, 48.0, "grove"),
    ("templu-munte N", 24.0, 2300.0, 50.0, "mountain"),
    ("templu-munte SE", 142.0, 2700.0, 48.0, "mountain"),
]


def build_prangs():
    rng = random.Random(9)
    bm = bmesh.new()
    cl = bm.loops.layers.float_color.new("Col")
    for name, az, d, h, kind in PRANGS:
        cx, cy = _at(az, d)
        z0 = ground_at(cx, cy)
        if kind == "island":
            z0 = 0.4
            top = stepped_base(bm, cl, cx, cy, z0, 22.0, 2, 3.0)
            prang(bm, cl, cx, cy, top, h, rng)
        elif kind == "hill":
            top = stepped_base(bm, cl, cx, cy, z0 - 2.0, 16.0, 3, 3.0)
            for dx in (-1.0, 0.0, 1.0):          # trei turnuri pe o terasa
                prang(bm, cl, cx + dx * h * 0.55, cy, top, h * (1.0 if dx == 0 else 0.8), rng)
        elif kind == "mountain":
            # templu-munte: piramida in trepte peste coronament, trei turnuri in linie
            top = stepped_base(bm, cl, cx, cy, z0, 40.0, 5, 6.0)
            for dx in (-1.0, 0.0, 1.0):
                prang(bm, cl, cx + dx * h * 0.42, cy, top, h * (1.0 if dx == 0 else 0.78), rng)
        else:
            top = stepped_base(bm, cl, cx, cy, z0, 14.0, 3, 4.0)
            prang(bm, cl, cx, cy, top, h, rng)
        e = math.degrees(math.atan2(top + h - CAM_Z, d))
        print("banda: prang %s busola %.0f d %.0f varf %.0f m -> %.2f grade" % (name, az, d, top + h, e))
    me = bpy.data.meshes.new("BandPrangs")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("BandPrangs", me)
    bpy.context.collection.objects.link(ob)
    # Aer 0,75: piatra luminata trebuie sa ramana un pic mai calda decat coronamentul din
    # jur, altfel bobocul se topeste in mov si nu se mai citeste.
    ob.data.materials.append(vcol_lit_material("BandStone", k=0.75))


# --- Randarea -----------------------------------------------------------------------

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
    print("banda: soarele la busola %.1f" % sun_compass())

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
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=60.0)
        me = bpy.data.meshes.new("Mk" + name)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new("Mk" + name, me)
        bpy.context.collection.objects.link(ob)
        ob.location = (x, y, 60)
        mat, nt, out = new_material("Mk" + name)
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = col
        nt.links.new(em.outputs[0], out.inputs["Surface"])
        ob.data.materials.append(mat)


reset()
random.seed(24)
HAZE_IMG = haze_table()
setup_render()
build_land()
build_trees()
build_prangs()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
