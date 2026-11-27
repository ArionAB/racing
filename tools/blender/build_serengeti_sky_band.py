"""Banda de orizont a cerului Serengeti (Track14) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/serengeti_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa: campia
fara sfarsit (iarba aurie, petice de oliv, acacii-umbrela razlete pana la orizont),
kopje-urile de granit (gramezi de bolovani rotunjiti pe un spinare de stanca),
dealurile joase ale podisului craterelor la E, cu un vulcan departat si stilizat
(con lat, cu calota de zapada) care NU domina, si doua-trei perdele de ploaie sub
furtuna de la V; cerul ramane TRANSPARENT, fiindca gradientul lui il deseneaza
shaderul de cer din joc (`scenes/tracks/sky_band.gdshader`). Banda e lipita de
cer, deci sta la infinit: nu intra in frustum, nu costa triunghiuri, nu o taie
FAR_PLANE (380 m).

Reteta e cea de pe Ha Long / Monument Valley / Okinawa: relieful e un camp de
inaltimi POLAR (numpy), kopje-urile sunt obiecte construite din bolovani, acaciile
sunt GLB-urile kitului pistei (`assets/models/serengeti/plants/acacia_umbrella_*`),
cu atlasul de paleta al jocului. Primul plan (`NEAR_KOPJES`, 0,6-0,8 km) sunt
kopje-uri MARI, puse de mana pe directiile camerei de joc, care dau scara.

Problema centrala a pistei: ceata jocului e aproape STINSA (`fog_max` 0,20, vezi
tema — decizia rundei 3: departarea isi pastreaza saturatia si muchiile), deci
terenul real se termina la FAR_PLANE (380 m) cu 80% din culoarea lui luminata.
Podeaua benzii trebuie sa continue exact acel auriu: albedo-ul ierbii (`GRASS`)
luminat de ACELASI soare si ambient (`SUN_STRENGTH` / `AMBIENT`, factorul pi intre
conventiile Godot si Cycles), plus cei 20% de ceata calda a jocului (`FOGC`,
`FOG_F0`). Abia de la fog_end incolo aerul trage spre HAZE (= cerul temei), adica
spre violet-griul furtunii: campia se intuneca spre orizont sub cerul de furtuna.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste campie, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din `custom_sun_rotation_deg` al pistei (Track14.tscn: (-35, 340, 0),
    adica busola 200, SSV, 35 de grade elevatie) — NU cel din tema (-35, 135),
    pe care scena il suprascrie; `sun_color` (1.0, 0.90, 0.72), energia 1,95;
    ambientul C9A98A la 0,55;
  * HAZE = `sky_horizon` din tema (645458): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * FOGC = `fog` din tema (0.58, 0.51, 0.38), FOG_F0 = `fog_max` (0,20);
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_serengeti_sky_band.py [-- --test]
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
# Ochiul: 10 m peste campie pe dreptele din campie (0,00-0,15 si 0,84-0,96), 40-55 m
# pe buza craterului. 12 e campia; la kilometri diferenta e sub un grad.
CAM_Z = 12.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "serengeti_horizon_band_test.png" if TEST
                   else "serengeti_horizon_band.png")


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


# --- Paleta (sRGB) ------------------------------------------------------------------
HAZE = "645458"          # = sky_horizon din tema: departarea intra in cer
HAZE_LOW = "6E5C55"      # aerul jos, praf cald sub furtuna (un pic mai cald decat cerul)
FOGC = "948261"          # = fog din tema (0.58, 0.51, 0.38)
FOG_F0 = 0.20            # = fog_max din tema: cata ceata are terenul jocului la 370 m
# Iarba: ALBEDO-ul campiei jocului (lumina o pune soarele de mai jos). Calibrat pe
# captura --gamecam: marginea de jos a benzii = iarba jocului la FAR_PLANE.
GRASS = "829257"
GRASS_DRY = "949E5F"     # pai deschis
GRASS_OLIVE = "6E7A3F"   # petice de iarba mai verde / umbra de nori
GRASS_BURN = "7A6A45"    # pete de pamant gol, termitiere
HIGH_GREEN = "5E6B36"    # podisul craterelor: padure de munte, iarba verde
HIGH_ROCK = "746A5E"
VOLC = "6E625A"          # conul vulcanic, cenusa
SNOW = "EEECE6"
# Granitul: ALBEDO albastrui, ca tenta clasei `granite` din joc (0.52, 0.578, 0.70):
# soarele cald, ambientul cald si cei 20% de ceata calda il aduc pe ecran la GRI
# NEUTRU, cat kopje-urile 3D. Cu albedo gri (8A8A8C) iesea bej-crem (145,117,80)
# langa granitul 3D gri; masurat pe captura, s-a corectat pe canale.
GRANITE = "687CB2"
GRANITE_LIGHT = "8196CC"
GRANITE_DARK = "48567C"
GRANITE_STREAK = "2A3150"  # dungile negre de apa de pe bolovani
LICHEN = "8E8A78"        # licheni ocru-stins pe fetele de sus (putini: granitul jocului e gri)
SHRUB = ["4D5A28", "5B6A2E", "434E24"]   # tufe in crapaturile kopje-urilor
RAIN = "4A3F45"          # perdeaua de ploaie: mai inchisa decat cerul
SUN_COLOR = "FFE6B8"     # Color(1.0, 0.90, 0.72) din tema
# Godot inmulteste energia luminii cu pi fata de Cycles (vezi Monument Valley):
# taria Cycles = pi x energia temei.
SUN_STRENGTH = math.pi * 1.95
AMBIENT = "C9A98A"
AMBIENT_ENERGY = 0.55
SUN_ROT = (-35.0, 340.0)                  # custom_sun_rotation_deg (x, y) din Track14.tscn

# Perspectiva aeriana: fac = 1 - exp(-(d - d0) * fwd / D), plafonata la HAZE_MAX,
# peste stratul de ceata al jocului (FOG_F0). Aer de furtuna: kopje-urile de la
# 3 km sunt deja pe jumatate in violet, podisul de la 15 km aproape silueta.
HAZE_D0, HAZE_D, HAZE_MAX = 370.0, 7500.0, 0.86
LOW_H, LOW_K = 60.0, 0.35                 # aerul jos (praf): K * exp(-z/H), departe
FWD_K = 0.8                               # aerul spre soare (vezi haze_wrap)


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


# --- Directiile camerei de joc --------------------------------------------------------
#
# Masurate cu o sonda temporara pe Track14.baked (ChaseCamera: 10 m sus, fov 68
# vertical = ~100 de grade pe orizontala la 16:9). Busola: 0 = N (-Z in Godot).
#
#   portiunea                       fractii      directia camerei   cer in cadru
#   dreapta campiei B (turma)       0,00-0,15    270                ~4 grade
#   urcarea prin padurea de ceata   0,17-0,36    300-45 (serpuit)   padure, putin
#   buza craterului (ochiul 55 m)   0,36-0,50    60-112             ~8 grade + podea
#   serpentinele (40 -> 5 m)        0,52-0,70    270 / 90 alternativ
#   fundul craterului               0,72-0,78    265
#   cotul spre S                    0,79-0,83    190-137 (spre soare)
#   dreapta de intoarcere           0,84-0,96    80-120
#
# Soarele e la busola 200: privind spre S-SV formele sunt in contre-jour.
#
# Regulile plasarii (lectiile pilotului): niciun urias pe axa unei drepte lungi
# (270 si 80-100 raman libere: acolo campia merge pana la orizont), ci la 15-35
# de grade lateral; primul plan DINCOLO de ~0,6 km; inaltimea aleasa in GRADE de
# la ochi: h = CAM_Z + d * tan(e). Cele de 6-8 grade ies din cadru pe dreapta
# campiei (acolo se vad ~4 grade): asta da scara.
#
# (azimut, distanta, elevatie in grade, latime / inaltime, seed)
NEAR_KOPJES = [
    # A — dreapta campiei (270), in stanga (24 de grade de axa); si fundul craterului
    ("A", 246.0, 640.0, 6.2, 2.6, 11),
    # B — dreapta campiei, in dreapta (22 de grade de axa), mai jos si mai lung
    ("B", 292.0, 760.0, 4.4, 3.4, 12),
    # C — mic, langa B, spre N: rupe linia, nu e pe axa
    ("C", 318.0, 700.0, 2.6, 2.2, 13),
    # D — dreapta de intoarcere (80-100) si buza (60-112), in stanga
    ("D", 58.0, 700.0, 5.0, 2.8, 14),
    # E — buza si dreapta de intoarcere, in dreapta; cel mai inalt, iese din cadru
    ("E", 128.0, 620.0, 7.0, 2.2, 15),
    # F — cotul spre S (0,79-0,83), in contre-jour; la 32 de grade de soare
    ("F", 166.0, 780.0, 3.8, 3.0, 16),
    # G — urcarea spre N (in spatele padurii, se vede printre trunchiuri)
    ("G", 16.0, 720.0, 4.2, 2.6, 17),
]

# Sectoarele in care campia ramane GOALA pana la orizont (doar acacii mici):
# axele dreptelor lungi. Kopje-urile medii nu cad aici.
OPEN_AXES = [(262.0, 278.0), (82.0, 100.0)]


def in_open(az):
    a = az % 360.0
    return any(lo <= a <= hi for lo, hi in OPEN_AXES)


# --- Relieful: campul de inaltimi polar -------------------------------------------------

N_AZ = 1024 if TEST else 4096
N_R = 120 if TEST else 380
R0, R1 = 80.0, 60000.0

# Vulcanul departat (stilizat, „Kibo" lat cu zapada), in sectorul podisului; NU pe
# axa dreptei de intoarcere (80-100), ci la ~35 de grade in stanga ei si in fata
# buzei (60-112): se vede, dar mic (~2 grade), in aer.
VOLCANO = dict(az=48.0, d=42000.0, h=1500.0, r=9000.0, crater=0.16)


def terrain_height(px, py):
    r = np.hypot(px, py)
    A = (np.degrees(np.arctan2(px, py)) + 360.0) % 360.0
    # campia: plata pana la ~0,9 km, apoi valuri lungi tot mai ample
    amp = 6.0 * smoothstep(900.0, 3000.0, r) + 30.0 * smoothstep(3000.0, 12000.0, r)
    z = (fbm(px, py, 1600.0, 5, octaves=4) - 0.45) * 2.0 * amp
    # podisul craterelor la E (35-150): dealuri inalte, impadurite, la 9-30 km
    hi_w = az_window(A, 35.0, 150.0, 25.0) * smoothstep(8000.0, 14000.0, r)
    ridge = fbm(px, py, 5200.0, 21, octaves=5, ridged=True)
    z = z + hi_w * (120.0 + 520.0 * ridge)
    # dealurile joase de la NV si S (Gol, Naabi): 150-300 m la 15-25 km
    lo_w = (az_window(A, 300.0, 350.0, 20.0) + az_window(A, 160.0, 215.0, 20.0)) \
        * smoothstep(12000.0, 18000.0, r)
    z = z + lo_w * (60.0 + 220.0 * fbm(px, py, 4200.0, 31, octaves=4))
    # vulcanul
    va = math.radians(VOLCANO["az"])
    vx, vy = math.sin(va) * VOLCANO["d"], math.cos(va) * VOLCANO["d"]
    vr = np.hypot(px - vx, py - vy) / VOLCANO["r"]
    cone = np.clip(1.0 - vr, 0.0, 1.0) ** 1.35
    top = 1.0 - VOLCANO["crater"]
    cone = np.minimum(cone, top + 0.03 * (cone - top))          # varf plat (Kibo)
    gully = fbm(px, py, 900.0, 41, octaves=3, ridged=True)
    z = np.maximum(z, VOLCANO["h"] * cone * (1.0 - 0.06 * gully * (vr < 1.0)))
    return z, r, A


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


def haze_wrap(nt, surface_socket, out_node, k=1.0):
    """surface -> (1) ceata jocului (FOGC, FOG_F0: ce are terenul real la FAR_PLANE),
    (2) aerul de furtuna spre HAZE dupa distanta, cu praf cald jos (HAZE_LOW).
    `k` < 1 slabeste aerul (kopje-urile apropiate)."""
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
    # Spre soare aerul e mai gros la vedere (imprastiere inainte): formele in
    # contre-jour ies mai spalate, nu mai inchise decat cele luminate (lectia
    # de pe Monument Valley: adancimea nu are voie sa se inverseze).
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
    air = math_node("SUBTRACT", va=1.0, b=x)
    air = math_node("MINIMUM", air, vb=HAZE_MAX)
    air = math_node("MULTIPLY", air, vb=k)
    # praful jos: doar departe, doar aproape de sol
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / LOW_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 900.0
    ramp.inputs["From Max"].default_value = 6000.0
    low = math_node("MULTIPLY", z, ramp.outputs["Result"])
    low = math_node("MULTIPLY", low, vb=LOW_K)
    # culoarea aerului: HAZE, cu praf cald jos
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(HAZE)
    cmix.inputs[7].default_value = srgb(HAZE_LOW)
    L.new(low, cmix.inputs[0])
    em_air = n.new("ShaderNodeEmission")
    L.new(cmix.outputs[2], em_air.inputs["Color"])
    em_fog = n.new("ShaderNodeEmission")
    em_fog.inputs["Color"].default_value = srgb(FOGC)
    # (1) ceata jocului, constanta: dincolo de 370 m terenul real are exact FOG_F0
    m1 = n.new("ShaderNodeMixShader")
    m1.inputs[0].default_value = FOG_F0
    L.new(surface_socket, m1.inputs[1])
    L.new(em_fog.outputs[0], m1.inputs[2])
    # (2) aerul (+ praful, adunat ca opacitate)
    keep = math_node("SUBTRACT", va=1.0, b=air)
    keep_low = math_node("SUBTRACT", va=1.0, b=low)
    keep = math_node("MULTIPLY", keep, keep_low)
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    m2 = n.new("ShaderNodeMixShader")
    L.new(fac, m2.inputs[0])
    L.new(m1.outputs[0], m2.inputs[1])
    L.new(em_air.outputs[0], m2.inputs[2])
    L.new(m2.outputs[0], out_node.inputs["Surface"])


def vcol_lit_material(name, rough=0.95):
    """Culoarea in atributul `Col`, luminata de soare si ambient, spalata in aer."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(at.outputs["Color"], bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
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


def ramp(n, stops):
    cr = n.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    els[0].position, els[0].color = stops[0][0], srgb(stops[0][1])
    els[1].position, els[1].color = stops[-1][0], srgb(stops[-1][1])
    for pos, col in stops[1:-1]:
        e = els.new(pos)
        e.color = srgb(col)
    return cr


def granite_material(name="BandGranite", k=1.0):
    """Granitul kopje-urilor: gri neutru cu pete mai deschise/inchise (zgomot pe
    obiect), DUNGI NEGRE verticale de apa pe flancuri (semnul kopje-ului real),
    licheni ocru doar pe fetele care privesc in sus, tufe din `Col` (vertex color,
    alfa = cat de mult e tufa)."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 0.08
    nz.inputs["Detail"].default_value = 6.0
    nz.inputs["Roughness"].default_value = 0.6
    L.new(tc.outputs["Object"], nz.inputs["Vector"])
    base = ramp(n, [(0.30, GRANITE_DARK), (0.48, GRANITE), (0.62, GRANITE_LIGHT)])
    L.new(nz.outputs["Fac"], base.inputs["Fac"])
    # dungi verticale: zgomot alungit pe Z
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.35, 0.35, 0.025)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz2 = n.new("ShaderNodeTexNoise")
    nz2.inputs["Scale"].default_value = 2.5
    nz2.inputs["Detail"].default_value = 3.0
    L.new(mp.outputs[0], nz2.inputs["Vector"])
    st = n.new("ShaderNodeMapRange")
    st.inputs["From Min"].default_value = 0.58
    st.inputs["From Max"].default_value = 0.74
    st.inputs["To Max"].default_value = 0.75
    L.new(nz2.outputs["Fac"], st.inputs["Value"])
    # dungile doar pe flancuri (normala orizontala)
    geo = n.new("ShaderNodeNewGeometry")
    sepn = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Normal"], sepn.inputs[0])
    side = n.new("ShaderNodeMapRange")
    side.inputs["From Min"].default_value = 0.75
    side.inputs["From Max"].default_value = 0.25
    L.new(sepn.outputs[2], side.inputs["Value"])
    stm = n.new("ShaderNodeMath")
    stm.operation = "MULTIPLY"
    L.new(st.outputs["Result"], stm.inputs[0])
    L.new(side.outputs["Result"], stm.inputs[1])
    m1 = n.new("ShaderNodeMix")
    m1.data_type = "RGBA"
    L.new(stm.outputs[0], m1.inputs[0])
    L.new(base.outputs["Color"], m1.inputs[6])
    m1.inputs[7].default_value = srgb(GRANITE_STREAK)
    # licheni pe ce priveste in sus
    up = n.new("ShaderNodeMapRange")
    up.inputs["From Min"].default_value = 0.55
    up.inputs["From Max"].default_value = 0.9
    L.new(sepn.outputs[2], up.inputs["Value"])
    nz3 = n.new("ShaderNodeTexNoise")
    nz3.inputs["Scale"].default_value = 0.4
    L.new(tc.outputs["Object"], nz3.inputs["Vector"])
    lm = n.new("ShaderNodeMapRange")
    lm.inputs["From Min"].default_value = 0.55
    lm.inputs["From Max"].default_value = 0.7
    lm.inputs["To Max"].default_value = 0.3
    L.new(nz3.outputs["Fac"], lm.inputs["Value"])
    lmu = n.new("ShaderNodeMath")
    lmu.operation = "MULTIPLY"
    L.new(lm.outputs["Result"], lmu.inputs[0])
    L.new(up.outputs["Result"], lmu.inputs[1])
    m2 = n.new("ShaderNodeMix")
    m2.data_type = "RGBA"
    L.new(lmu.outputs[0], m2.inputs[0])
    L.new(m1.outputs[2], m2.inputs[6])
    m2.inputs[7].default_value = srgb(LICHEN)
    # tufele / iarba de la baza, din vertex color (alfa = greutatea)
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    m3 = n.new("ShaderNodeMix")
    m3.data_type = "RGBA"
    L.new(at.outputs["Alpha"], m3.inputs[0])
    L.new(m2.outputs[2], m3.inputs[6])
    L.new(at.outputs["Color"], m3.inputs[7])
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Specular IOR Level"].default_value = 0.12
    L.new(m3.outputs[2], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out, k)
    return mat


# --- Campia si dealurile ------------------------------------------------------------

def build_land():
    A, Rg, px, py = polar_grid(N_AZ, N_R, R0, R1)
    z, r, Ad = terrain_height(px, py)
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    me = grid_mesh("BandLand", co, N_R, N_AZ)
    nrm = np.empty(N_R * N_AZ * 3, dtype=np.float32)
    me.vertex_normals.foreach_get("vector", nrm)
    nz = nrm.reshape(N_R, N_AZ, 3)[..., 2]

    # iarba: pete mari (umbra de nori, iarba verde dupa ploaie), pai deschis,
    # pamant gol rar; alungite pe azimut ca sa citeasca orizontal la unghi razant
    big = fbm(px, py, 700.0, 51, octaves=4)
    mid = fbm(px * 0.6, py * 0.6, 90.0, 53, octaves=3)
    col = np.broadcast_to(lin(GRASS), px.shape + (3,)).copy()
    w_dry = smoothstep(0.55, 0.72, big)
    col = col * (1 - w_dry)[..., None] + lin(GRASS_DRY) * w_dry[..., None]
    w_ol = smoothstep(0.42, 0.28, big) * 0.85
    col = col * (1 - w_ol)[..., None] + lin(GRASS_OLIVE) * w_ol[..., None]
    w_burn = smoothstep(0.70, 0.82, mid) * 0.7
    col = col * (1 - w_burn)[..., None] + lin(GRASS_BURN) * w_burn[..., None]
    # podisul: verde de munte cu stanca pe pante
    hi = smoothstep(80.0, 260.0, z) * (Rg > 6000.0)
    col = col * (1 - hi)[..., None] + lin(HIGH_GREEN) * hi[..., None]
    steep = smoothstep(0.85, 0.6, nz) * hi
    col = col * (1 - steep)[..., None] + lin(HIGH_ROCK) * steep[..., None]
    # vulcanul: cenusa, zapada pe varf (dungi pe rigole)
    va = math.radians(VOLCANO["az"])
    vx, vy = math.sin(va) * VOLCANO["d"], math.cos(va) * VOLCANO["d"]
    vr = np.hypot(px - vx, py - vy) / VOLCANO["r"]
    on_v = smoothstep(1.0, 0.75, vr) * smoothstep(300.0, 600.0, z)
    col = col * (1 - on_v)[..., None] + lin(VOLC) * on_v[..., None]
    snow_line = VOLCANO["h"] * (0.80 + 0.06 * (fbm(px, py, 700.0, 61, octaves=3) - 0.5) * 2.0)
    snow = smoothstep(snow_line - 40.0, snow_line + 20.0, z) * (vr < 1.0)
    col = col * (1 - snow)[..., None] + lin(SNOW) * snow[..., None]

    set_vcol(me, col)
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(vcol_lit_material("BandLand"))
    print("banda: relief %d x %d varfuri" % (N_R, N_AZ))
    return z


def ground_at(x, y):
    z, _, _ = terrain_height(np.array([x]), np.array([y]))
    return float(z[0])


# --- Kopje-urile -------------------------------------------------------------------

def boulder(bm, col_layer, c, sx, sy, sz, rot, rng, subdiv=3, shrub=0.0):
    """Un bolovan de granit: icosfera turtita, cu umflaturi lente si o baza plata
    (sta pe ceva, nu pluteste). `shrub` = probabilitatea de tufa la baza (vertex color)."""
    res = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    seed = rng.random() * 50.0
    ca, sa = math.cos(rot), math.sin(rot)
    tint = SHRUB[rng.randrange(len(SHRUB))]
    tl = srgb(tint)
    for v in res["verts"]:
        p = v.co.copy()
        k = 1.0 + 0.16 * noise.noise(p * 1.4 + Vector((seed, 0, 0))) \
            + 0.05 * noise.noise(p * 4.0 + Vector((0, seed, 0)))
        p *= k
        if p.z < -0.55:                                   # talpa plata
            p.z = -0.55 + (p.z + 0.55) * 0.25
        lx, ly, lz = p.x * sx, p.y * sy, p.z * sz
        v.co = Vector((c.x + lx * ca - ly * sa, c.y + lx * sa + ly * ca, c.z + lz))
        a = 0.0
        if shrub > 0.0 and p.z < -0.2:
            a = shrub * max(0.0, min(1.0, 0.5 + 1.6 * noise.noise(p * 3.0 + Vector((seed, seed, 0)))))
        for loop in v.link_loops:
            loop[col_layer] = (tl[0], tl[1], tl[2], a)


def kopje(bm, col_layer, cx, cy, h, aspect, rng, near=True):
    """Un kopje: o spinare de granit (dom turtit, lat de `aspect` ori inaltimea) cu
    bolovani mari rotunjiti asezati pe ea si stivuiti in turnuri (tor-uri), plus
    blocuri prabusite la baza. Inaltimea totala ~h."""
    gz = ground_at(cx, cy) if not near else 0.0
    wdt = h * aspect
    rot = rng.uniform(0.0, math.tau)
    sub = 3 if near else 2
    # spinarea: 1-2 domuri late si joase
    n_dome = rng.choice((1, 2, 2))
    domes = []
    for i in range(n_dome):
        off = (i - (n_dome - 1) * 0.5) * wdt * 0.42
        c = Vector((cx + math.cos(rot) * off, cy + math.sin(rot) * off, gz - h * 0.08))
        sx = wdt * rng.uniform(0.32, 0.45)
        sy = sx * rng.uniform(0.5, 0.8)
        sz = h * rng.uniform(0.42, 0.55)
        boulder(bm, col_layer, c, sx, sy, sz, rot + rng.uniform(-0.3, 0.3), rng, sub + 1,
                shrub=0.7)
        domes.append((c, sx, sy, sz))
    # bolovanii mari pe spinare, unii stivuiti in turnuri
    n_b = int(rng.uniform(9, 16) if near else rng.uniform(4, 8))
    for _ in range(n_b):
        c0, sx, sy, sz = domes[rng.randrange(len(domes))]
        ang = rng.uniform(0.0, math.tau)
        rr = rng.random() ** 0.7 * 0.75
        lx, ly = math.cos(ang) * sx * rr, math.sin(ang) * sy * rr
        # cota pe dom (elipsoid)
        q = max(0.0, 1.0 - rr * rr)
        top = c0.z + sz * math.sqrt(q) * 0.92
        s = h * rng.uniform(0.13, 0.26)
        pos = Vector((c0.x + lx * math.cos(rot) - ly * math.sin(rot),
                      c0.y + lx * math.sin(rot) + ly * math.cos(rot), top + s * 0.35))
        stack = 1 + (rng.random() < 0.45) + (rng.random() < 0.2)
        for k in range(stack):
            bs = s * rng.uniform(0.7, 1.15) * (0.85 ** k)
            sxb, syb, szb = bs * rng.uniform(0.9, 1.4), bs * rng.uniform(0.8, 1.2), bs * rng.uniform(0.6, 0.95)
            boulder(bm, col_layer, pos, sxb, syb, szb, rng.uniform(0, math.tau), rng, sub,
                    shrub=0.35 if k == 0 else 0.0)
            pos = pos + Vector((rng.uniform(-0.2, 0.2) * bs, rng.uniform(-0.2, 0.2) * bs,
                                szb * 0.55 + bs * 0.45 * 0.85))
    # blocuri prabusite la baza
    n_f = int(rng.uniform(6, 12) if near else rng.uniform(2, 4))
    for _ in range(n_f):
        c0, sx, sy, sz = domes[rng.randrange(len(domes))]
        ang = rng.uniform(0.0, math.tau)
        rr = rng.uniform(0.95, 1.35)
        lx, ly = math.cos(ang) * sx * rr, math.sin(ang) * sy * rr
        bs = h * rng.uniform(0.05, 0.12)
        pos = Vector((c0.x + lx * math.cos(rot) - ly * math.sin(rot),
                      c0.y + lx * math.sin(rot) + ly * math.cos(rot), gz + bs * 0.3))
        boulder(bm, col_layer, pos, bs * rng.uniform(1.0, 1.5), bs, bs * rng.uniform(0.6, 0.9),
                rng.uniform(0, math.tau), rng, 2, shrub=0.6)
    return wdt


def build_kopjes(tree_pts):
    """Planul 0 (NEAR_KOPJES) si kopje-urile medii (1-6 km). Acaciile din jurul
    lor intra in `tree_pts`."""
    rng = random.Random(1914)
    objs = []
    for near in (True, False):
        bm = bmesh.new()
        cl = bm.loops.layers.float_color.new("Col")
        if near:
            for name, az, d, e, aspect, seed in NEAR_KOPJES:
                r2 = random.Random(seed)
                a = math.radians(az)
                cx, cy = math.sin(a) * d, math.cos(a) * d
                h = CAM_Z + d * math.tan(math.radians(e))
                wdt = kopje(bm, cl, cx, cy, h, aspect, r2, near=True)
                print("banda: kopje %s az %.0f d %.0f h %.0f lat %.0f -> %.1f grade"
                      % (name, az, d, h, wdt, e))
                for _ in range(r2.randint(4, 9)):
                    ang = r2.uniform(0, math.tau)
                    rr = wdt * r2.uniform(0.45, 1.1)
                    tree_pts.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr,
                                     r2.uniform(1.0, 1.5)))
        else:
            placed = 0
            tries = 0
            while placed < 46 and tries < 2000:
                tries += 1
                az = rng.uniform(0.0, 360.0)
                if in_open(az):
                    continue
                d = 1100.0 * (6.0 ** rng.random())        # 1,1-6,6 km, mai multe aproape
                a = math.radians(az)
                cx, cy = math.sin(a) * d, math.cos(a) * d
                # nu in spatele / langa uriasii apropiati
                if any(abs((az - k[1] + 180.0) % 360.0 - 180.0) < 9.0 and d < 2600.0
                       for k in NEAR_KOPJES):
                    continue
                e = rng.uniform(0.35, 1.6) * (1.0 if d < 3000.0 else 0.7)
                h = 8.0 + d * math.tan(math.radians(e))
                h = min(h, 70.0)
                kopje(bm, cl, cx, cy, h, rng.uniform(1.8, 4.0), rng, near=False)
                placed += 1
                for _ in range(rng.randint(1, 4)):
                    ang = rng.uniform(0, math.tau)
                    rr = h * rng.uniform(1.5, 3.5)
                    tree_pts.append((cx + math.cos(ang) * rr, cy + math.sin(ang) * rr,
                                     rng.uniform(1.0, 1.4)))
            print("banda: %d kopje-uri medii" % placed)
        me = bpy.data.meshes.new("BandKopjes" + ("Near" if near else "Mid"))
        bm.to_mesh(me)
        bm.free()
        for p in me.polygons:
            p.use_smooth = True
        ob = bpy.data.objects.new(me.name, me)
        bpy.context.collection.objects.link(ob)
        ob.data.materials.append(granite_material("Granite" + ("Near" if near else "Mid"),
                                                  k=0.75 if near else 1.0))
        objs.append(ob)
        print("banda: %s %d fete" % (me.name, len(me.polygons)))
    return objs


# --- Acaciile (GLB-urile kitului) ------------------------------------------------------

ACACIAS = ["serengeti/plants/acacia_umbrella_a.glb",
           "serengeti/plants/acacia_umbrella_b.glb",
           "serengeti/plants/acacia_umbrella_c.glb"]


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


def scatter_plain_trees(tree_pts):
    """Acacii razlete pe campie: rare aproape, mai dese (in grupuri) departe, ca
    linia orizontului sa fie punctata de umbrele mici — imaginea Serengeti. Pe
    axele dreptelor (OPEN_AXES) raman doar cele departate si mici."""
    rng = random.Random(77)
    n = 0
    while n < 520:
        az = rng.uniform(0.0, 360.0)
        d = 420.0 * (16.0 ** (rng.random() ** 0.8))      # 0,42-6,7 km
        if in_open(az) and d < 2500.0:
            continue
        a = math.radians(az)
        cx, cy = math.sin(a) * d, math.cos(a) * d
        grp = 1 if rng.random() < 0.6 else rng.randint(2, 5)
        for _ in range(grp):
            ox, oy = rng.gauss(0, 25.0), rng.gauss(0, 25.0)
            tree_pts.append((cx + ox, cy + oy, rng.uniform(0.9, 1.35)))
            n += 1


def build_trees(tree_pts):
    mat = atlas_haze_material("BandAcacia")
    protos = []
    for fn in ACACIAS:
        path = os.path.join(MODELS, *fn.split("/"))
        if not os.path.exists(path):
            print("LIPSA: " + path)
            continue
        o = import_joined(path)
        o.data.materials.append(mat)
        o.hide_render = True
        o.location = (0, 0, -1000)
        protos.append(o)
    if not protos:
        return
    rng = random.Random(3)
    for x, y, s in tree_pts:
        p = protos[rng.randrange(len(protos))]
        o = p.copy()
        bpy.context.collection.objects.link(o)
        o.hide_render = False
        r = math.hypot(x, y)
        o.location = (x, y, (ground_at(x, y) if r > 900.0 else 0.0) - 0.3)
        o.rotation_euler = (0.0, 0.0, rng.uniform(0.0, math.tau))
        o.scale = (s, s * rng.uniform(0.9, 1.1), s * rng.uniform(0.85, 1.05))
    print("banda: %d acacii" % len(tree_pts))


# --- Perdelele de ploaie ------------------------------------------------------------
#
# Brief §8: „furtuna e la orizont, tot turul, ca fundal". Perdelele stau sub
# norul de la V, in fata pe dreapta campiei, departe (20-26 km). NU pe azimuturile
# kopje-urilor apropiate: in spatele unei forme apropiate perdela citea a fum
# iesit din stanca (prima randare, la A 246 si B 292).
# (azimut, distanta, latime in grade, inaltime m)
RAIN_SHAFTS = [(270.0, 20000.0, 8.0, 2000.0), (222.0, 24000.0, 5.0, 1700.0),
               (338.0, 26000.0, 5.0, 1700.0)]


def build_rain():
    mat, nt, out = new_material("BandRain")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    # dungi verticale fine, putin inclinate (vant)
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (60.0, 1.0, 1.5)
    mp.inputs["Rotation"].default_value = (0.0, 0.0, 0.0)
    L.new(tc.outputs["UV"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 1.0
    nz.inputs["Detail"].default_value = 2.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    nz2 = n.new("ShaderNodeTexNoise")
    nz2.inputs["Scale"].default_value = 3.0
    L.new(tc.outputs["UV"], nz2.inputs["Vector"])
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["UV"], sep.inputs[0])
    # profilul: plina sus (norul), se raleste spre sol; margini laterale moi
    vert = n.new("ShaderNodeMapRange")
    vert.inputs["From Min"].default_value = 0.0
    vert.inputs["From Max"].default_value = 0.85
    vert.inputs["To Min"].default_value = 0.35
    vert.inputs["To Max"].default_value = 1.0
    L.new(sep.outputs[1], vert.inputs["Value"])
    edge = n.new("ShaderNodeMath")
    edge.operation = "PINGPONG"
    L.new(sep.outputs[0], edge.inputs[0])
    edge.inputs[1].default_value = 0.5
    edge2 = n.new("ShaderNodeMapRange")
    edge2.inputs["From Min"].default_value = 0.0
    edge2.inputs["From Max"].default_value = 0.22
    L.new(edge.outputs[0], edge2.inputs["Value"])
    lum = n.new("ShaderNodeMapRange")
    lum.inputs["From Min"].default_value = 0.35
    lum.inputs["From Max"].default_value = 0.65
    lum.inputs["To Min"].default_value = 0.45
    lum.inputs["To Max"].default_value = 1.0
    L.new(nz.outputs["Fac"], lum.inputs["Value"])
    a = n.new("ShaderNodeMath")
    a.operation = "MULTIPLY"
    L.new(vert.outputs["Result"], a.inputs[0])
    L.new(edge2.outputs["Result"], a.inputs[1])
    a2 = n.new("ShaderNodeMath")
    a2.operation = "MULTIPLY"
    L.new(a.outputs[0], a2.inputs[0])
    L.new(lum.outputs["Result"], a2.inputs[1])
    a3 = n.new("ShaderNodeMath")
    a3.operation = "MULTIPLY"
    L.new(a2.outputs[0], a3.inputs[0])
    a3.inputs[1].default_value = 0.55
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(RAIN)
    tr = n.new("ShaderNodeBsdfTransparent")
    mix = n.new("ShaderNodeMixShader")
    L.new(a3.outputs[0], mix.inputs[0])
    L.new(tr.outputs[0], mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    L.new(mix.outputs[0], out.inputs["Surface"])

    for az, d, wdeg, h in RAIN_SHAFTS:
        segs = 16
        half = math.radians(wdeg) * 0.5
        a0 = math.radians(az)
        verts, faces, uvs = [], [], []
        for i in range(segs + 1):
            t = i / segs
            ang = a0 - half + 2 * half * t
            for zz, v in ((-20.0, 0.0), (h, 1.0)):
                # vantul inclina perdeaua: sus e mai spre N
                lean = (v * 0.25) * half
                verts.append((math.sin(ang + lean) * d, math.cos(ang + lean) * d, zz))
        for i in range(segs):
            b = i * 2
            faces.append((b, b + 2, b + 3, b + 1))
        me = bpy.data.meshes.new("BandRain")
        me.from_pydata(verts, [], faces)
        uv = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                uv.data[li].uv = ((vi // 2) / segs, 1.0 - (vi % 2))
        ob = bpy.data.objects.new("BandRain", me)
        bpy.context.collection.objects.link(ob)
        ob.data.materials.append(mat)
        ob.visible_shadow = False
    print("banda: %d perdele de ploaie" % len(RAIN_SHAFTS))


# --- Lumina, camera ----------------------------------------------------------------

def sun_dir_blender():
    """to_sun din unghiul Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
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
    sc.cycles.transparent_max_bounces = 12
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
build_land()
trees = []
build_kopjes(trees)
scatter_plain_trees(trees)
build_trees(trees)
build_rain()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
