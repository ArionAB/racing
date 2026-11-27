"""Banda de orizont a cerului Jodhpur (Track17) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/jodhpur_horizon_band.png` (apusul, 8192 x 512) si,
cu `--night`, `assets/textures/sky/jodhpur_horizon_band_night.png` (noaptea de
Diwali, 4096 x 256): felii equirectangulare de 360 de grade pe azimut si 22,5
grade pe inaltime (-7,5 .. +15), cu alfa. Ce e in ele: dealurile stancoase de
riolit si gresie rosie din jurul orasului, cu zidul cetatii pe creste si casele
albastre urcand pe poale (Brahmpuri continua dincolo de bucla), deserul Thar plat
si prafos spre vest (in fata dreptei lungi H + A), lanturile aride departate spre nord si est, si
pe un deal jos la sud-est palatul cu cupola. Cerul ramane TRANSPARENT: gradientul
lui il deseneaza shaderul de cer din joc (`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Monument Valley / Cappadocia (pistele de USCAT). Ce e specific:

  * CEASUL DE LUMINA. Jodhpur e singura pista cu `DuskCycle`: cursa porneste la
    apus (soare 8 grade, portocaliu) si se termina noaptea (luna gri-lila, ceata
    inchisa, lampile aprinse). O singura felie nu poate fi si una si alta, deci
    se randeaza doua, cu aceeasi geometrie, la cheile de lumina dusk 0 si dusk 1
    din `dusk_cycle.gd`; shaderul le amesteca (`band_night_mix`). Noaptea,
    ferestrele caselor si candelele de pe ziduri sunt EMISIVE — orasul continua
    dincolo de ceata (brief §5.4), fara inelul de case 3D.
  * IMBINAREA. Ceata pistei e un fum albastru-gri RECE (#8898B8), ales ca orasul
    vazut de pe bastion sa ramana albastru (track.gd, tema "jodhpur") — nu se
    schimba. De aceea podeaua benzii e acoperita de ACELASI aer (`AIR` = ceata
    temei) cam cat e terenul jocului la FAR_PLANE (fog_max 0,85): la marginea de
    jos banda are culoarea terenului cetos, si `below` = acea culoare. Aerul e
    un strat JOS (praful de seara): relieful care urca din el iese tot mai curat,
    altfel dealurile apropiate ar disparea in aceeasi pata.
  * IMPRASTIEREA SPRE SOARE. In joc ceata ia culoarea soarelui spre soare
    (`fog_sun_scatter` 1,0 la dusk 0, lobul lui Godot: pow(max(dot(view, sun),
    0), 8)). Aerul benzii are acelasi lob, cu aceeasi formula, ca podeaua
    pictata sa fie la fel de aprinsa ca terenul cetos de sub ea spre soare.
  * REPERELE 3D NU SE DUBLEAZA: Mehrangarh (stanca + zidurile, in coltul de NV
    al buclei) si orasul albastru din interiorul buclei sunt ale jocului. Zidul
    din banda e zidul ORASULUI pe crestele din jur (cum urca in realitate pe
    dealurile din nord), fara palat; casele pictate sunt mici si departate.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste podeaua benzii, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati;
  * soarele din Track17.tscn (`custom_sun_rotation_deg` (-8, 90, 0)), cu aceeasi
    conversie ca Monument Valley / Cappadocia (`sun_dir_blender`): sursa iese la
    busola 90 (EST), 8 grade — verificat pe randarea `--test`, unde lobul de
    imprastiere cade pe marcajul rosu (E), si pe capturile din joc (pe dreapta
    spre vest fatadele dinspre camera sunt cele luminate). Comentariul din tema
    („vest") urmeaza conventia hartii din gen_*_route.py, nu busola jocului;
    culoarea/energia/ambientul/ceata din tema "jodhpur" (dusk 0)
    si din cheile de la 1 ale `DuskCycle` (noaptea: soare 1 grad, A4A0B4 x 0,30,
    ambient 8A8690 x 0,45, ceata 45424E);
  * HAZE = `sky_horizon` al fazei (FF7A38 apus / 4A2E44 noapte); AIR = `fog` al
    fazei;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii; `--night` = felia de noapte):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_sky_band.py [-- --night] [--test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import bmesh
import math
import os
import random
import sys

import numpy as np
from mathutils import Vector

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS
NIGHT = "--night" in ARGS

if TEST:
    W, H = 1024, 64
elif NIGHT:
    W, H = 4096, 256
else:
    W, H = 8192, 512
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
# Ochiul peste podeaua benzii. Masurat pe Track17.baked (sonda temporara): campia
# din jurul buclei e la cota ~12 a jocului (11-14 m la 380-600 m de centroid, pe
# toate azimuturile), iar bastionul F (+40, camera la ~47) e punctul cel mai
# inalt. Cota 0 a benzii = campia; camera benzii la 35 m peste ea, deci taietura
# terenului la FAR_PLANE (380 m) cade la -5,3 grade, exact unde incepe podeaua
# pictata vazuta de pe bastion (de unde se vede cel mai mult din banda). Din
# oras (drumul la 0-17, sub campie) marginea terenului de la 380 m e PESTE
# orizont si acopera podeaua: acolo se vad doar dealurile.
CAM_Z = 35.0
SAMPLES = 16 if TEST else (96 if NIGHT else 128)
_name = "jodhpur_horizon_band" + ("_night" if NIGHT else "") + ("_test" if TEST else "")
OUT = os.path.join(PROJECT, "assets", "textures", "sky", _name + ".png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Lumina, pe faze (tema "jodhpur" la dusk 0; cheile DuskCycle la dusk 1) -------
if not NIGHT:
    SUN_ROT = (-8.0, 90.0)
    SUN_COLOR, SUN_ENERGY = "FF9050", 0.85
    AMBIENT, AMBIENT_ENERGY = "C8C4D0", 0.50
    AIR = "8898B8"                         # = fog al temei
    HAZE = "FF7A38"                        # = sky_horizon al temei
    SCATTER = 1.0                          # = DuskCycle.KEY_FOG_SUN_SCATTER[0]
    WINDOW_K = 0.0                         # lampile: abia (0,15) -> stinse in banda
else:
    SUN_ROT = (-1.0, 90.0)
    SUN_COLOR, SUN_ENERGY = "A4A0B4", 0.30
    AMBIENT, AMBIENT_ENERGY = "8A8690", 0.45
    AIR = "45424E"
    HAZE = "4A2E44"
    SCATTER = 0.0
    WINDOW_K = 1.0
# Godot inmulteste energia luminii cu pi; Cycles nu. Taria Cycles = pi x energia.
SUN_STRENGTH = math.pi * SUN_ENERGY

# --- Paleta (ALBEDO, sRGB; aceleasi culori ca in kitul pistei, brief §4) --------
SAND = "C78E5E"          # nisipul campiei: ground_tint (0.78, 0.50, 0.30) x dala
SAND_DARK = "A87650"
SAND_LIGHT = "D6A273"
RHYOLITE = "9A6A5A"      # stanca de sub fort (clasa rhyolite)
RHYO_DARK = "7A5248"
SANDSTONE = "A5553A"     # gresia rosie a fortului (red_sandstone)
SANDSTONE_LIGHT = "C27552"
ROSE = "D4957A"          # gresia roz (rose_sandstone)
SHRUB = "6B6A3E"         # tufe uscate, euforbii (CACTUS_GREEN prafuit)
KHEJRI = "5E6338"
BLUE = "8FB0DC"          # varul albastru (blue_lime_light)
INDIGO = "4F6FB8"        # blue_lime_indigo
BEIGE = "D2AE80"         # casele bej / ocru (FarCity_A_Beige)
WHITE = "EEE8DF"         # marmura calda (cenotaf, altare)
TANK = "2A2624"          # rezervoarele negre de pe terase (LOG_DARK)
PALACE = "DDB98C"        # gresia bej a palatului cu cupola
LAMP = "FFB060"          # flacara candelelor / ferestrele de noapte (LAVA_ORANGE cald)

# Aerul (AIR): un strat JOS de praf. Pe podea (z ~ 0) e cat ceata jocului la
# FAR_PLANE; pe relieful care urca din el, mai putin (AIR_K_HIGH).
#   fac = (AIR_F0 + (AIR_MAX - AIR_F0) * (1 - exp(-(d - d0) / D))) * k(z)
AIR_D0, AIR_D, AIR_F0, AIR_MAX = 380.0, 2500.0, 0.80, 0.90
AIR_Z0, AIR_Z1, AIR_K_HIGH = 4.0, 40.0, 0.28
# Departarea (HAZE): de la HAZE_D0 incolo, spre orizontul cerului.
HAZE_D0, HAZE_D, HAZE_MAX = 1500.0, 3500.0, 0.92


# --- Scena ---------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


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


def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    rx, ry = math.radians(SUN_ROT[0]), math.radians(SUN_ROT[1])
    x, y, z = 0.0, -math.sin(rx), math.cos(rx)
    gx = x * math.cos(ry) + z * math.sin(ry)
    gz = -x * math.sin(ry) + z * math.cos(ry)
    g = Vector((gx, y, gz))                     # Godot: x est, y sus, z sud
    return Vector((g.x, -g.z, g.y)).normalized()  # Blender: x est, y nord, z sus


def air_color(n, L):
    """AIR + lobul de imprastiere spre soare, exact formula lui Godot:
    fog += sun_color * energy * pow(max(dot(view, to_sun), 0), 8) * scatter."""
    base = srgb(AIR)
    if SCATTER <= 0.0:
        rgb = n.new("ShaderNodeRGB")
        rgb.outputs[0].default_value = base
        return rgb.outputs[0]
    geo = n.new("ShaderNodeNewGeometry")
    sd = sun_dir_blender()
    dot = n.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    L.new(geo.outputs["Incoming"], dot.inputs[0])            # Incoming = -view
    dot.inputs[1].default_value = (-sd.x, -sd.y, -sd.z)
    w = _math(n, L, "MAXIMUM", dot.outputs["Value"], vb=0.0)
    w = _math(n, L, "POWER", w, vb=8.0)
    w = _math(n, L, "MULTIPLY", w, vb=SCATTER * SUN_ENERGY)
    sc = srgb(SUN_COLOR)
    vm = n.new("ShaderNodeVectorMath")
    vm.operation = "MULTIPLY_ADD"
    vm.inputs[1].default_value = sc[:3]
    vm.inputs[2].default_value = base[:3]
    comb = n.new("ShaderNodeCombineXYZ")
    for i in range(3):
        L.new(w, comb.inputs[i])
    L.new(comb.outputs[0], vm.inputs[0])
    return vm.outputs[0]


def haze_wrap(nt, surface_socket, out_node, k=1.0, k_far=1.0):
    """surface -> AIR (stratul jos de praf, cu lobul spre soare) -> HAZE."""
    n, L = nt.nodes, nt.links
    cam = n.new("ShaderNodeCameraData")
    d = cam.outputs["View Distance"]
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])
    x = _math(n, L, "SUBTRACT", d, vb=AIR_D0)
    x = _math(n, L, "MAXIMUM", x, vb=0.0)
    x = _math(n, L, "MULTIPLY", x, vb=-1.0 / AIR_D)
    x = _math(n, L, "EXPONENT", x)
    air = _math(n, L, "SUBTRACT", va=1.0, b=x)
    air = _math(n, L, "MULTIPLY", air, vb=AIR_MAX - AIR_F0)
    air = _math(n, L, "ADD", air, vb=AIR_F0)
    zk = n.new("ShaderNodeMapRange")                     # stratul jos: k(z)
    L.new(sep.outputs[2], zk.inputs["Value"])
    zk.inputs["From Min"].default_value = AIR_Z0
    zk.inputs["From Max"].default_value = AIR_Z1
    zk.inputs["To Min"].default_value = 1.0
    zk.inputs["To Max"].default_value = AIR_K_HIGH
    air = _math(n, L, "MULTIPLY", air, zk.outputs["Result"])
    air = _math(n, L, "MULTIPLY", air, vb=k)
    y = _math(n, L, "SUBTRACT", d, vb=HAZE_D0)
    y = _math(n, L, "MAXIMUM", y, vb=0.0)
    y = _math(n, L, "MULTIPLY", y, vb=-1.0 / HAZE_D)
    y = _math(n, L, "EXPONENT", y)
    far = _math(n, L, "SUBTRACT", va=1.0, b=y)
    far = _math(n, L, "MULTIPLY", far, vb=HAZE_MAX * k_far)
    em_air = n.new("ShaderNodeEmission")
    L.new(air_color(n, L), em_air.inputs["Color"])
    em_far = n.new("ShaderNodeEmission")
    em_far.inputs["Color"].default_value = srgb(HAZE)
    m1 = n.new("ShaderNodeMixShader")
    L.new(air, m1.inputs[0])
    L.new(surface_socket, m1.inputs[1])
    L.new(em_air.outputs[0], m1.inputs[2])
    m2 = n.new("ShaderNodeMixShader")
    L.new(far, m2.inputs[0])
    L.new(m1.outputs[0], m2.inputs[1])
    L.new(em_far.outputs[0], m2.inputs[2])
    L.new(m2.outputs[0], out_node.inputs["Surface"])


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def ramp(n, stops, interp="LINEAR"):
    cr = n.new("ShaderNodeValToRGB")
    cr.color_ramp.interpolation = interp
    els = cr.color_ramp.elements
    els[0].position, els[0].color = stops[0][0], srgb(stops[0][1])
    els[1].position, els[1].color = stops[-1][0], srgb(stops[-1][1])
    for pos, col in stops[1:-1]:
        e = els.new(pos)
        e.color = srgb(col)
    return cr


def mixc(n, L, fac, a, b):
    m = n.new("ShaderNodeMix")
    m.data_type = "RGBA"
    if isinstance(fac, float):
        m.inputs[0].default_value = fac
    else:
        L.new(fac, m.inputs[0])
    for idx, v in ((6, a), (7, b)):
        if isinstance(v, str):
            m.inputs[idx].default_value = srgb(v)
        else:
            L.new(v, m.inputs[idx])
    return m.outputs[2]


def land_material():
    """Terenul (podea + dealuri, o singura plasa): nisip pe plat, stanca pe panta.
    Stanca = petice de riolit roz-brun si gresie rosie (siroiri verticale), cu
    tufe uscate in petice inchise pe tot ce nu e perete."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    geo = n.new("ShaderNodeNewGeometry")
    sepn = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Normal"], sepn.inputs[0])
    # nisip: petice alungite pe orizontala
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / 140.0, 1.0 / 140.0, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 1.0
    nz.inputs["Detail"].default_value = 5.0
    nz.inputs["Roughness"].default_value = 0.6
    L.new(mp.outputs[0], nz.inputs["Vector"])
    sand = ramp(n, [(0.30, SAND_DARK), (0.47, SAND), (0.58, SAND), (0.72, SAND_LIGHT)])
    L.new(nz.outputs["Fac"], sand.inputs["Fac"])
    # stanca: petice de riolit / gresie rosie (zgomot alungit pe verticala, ca
    # siroirile), NU straturi orizontale dese: pe versanti citeau curbe de nivel.
    mp2 = n.new("ShaderNodeMapping")
    mp2.inputs["Scale"].default_value = (0.03, 0.03, 0.012)
    L.new(tc.outputs["Object"], mp2.inputs["Vector"])
    nzs = n.new("ShaderNodeTexNoise")
    nzs.inputs["Scale"].default_value = 1.0
    nzs.inputs["Detail"].default_value = 4.0
    nzs.inputs["Roughness"].default_value = 0.65
    L.new(mp2.outputs[0], nzs.inputs["Vector"])
    strata = ramp(n, [(0.30, RHYO_DARK), (0.45, RHYOLITE), (0.56, SANDSTONE),
                      (0.68, SANDSTONE_LIGHT)])
    L.new(nzs.outputs["Fac"], strata.inputs["Fac"])
    nz2 = n.new("ShaderNodeTexNoise")
    nz2.inputs["Scale"].default_value = 0.01
    nz2.inputs["Detail"].default_value = 3.0
    L.new(tc.outputs["Object"], nz2.inputs["Vector"])
    rk = n.new("ShaderNodeMapRange")
    rk.inputs["From Min"].default_value = 0.45
    rk.inputs["From Max"].default_value = 0.70
    rk.inputs["To Max"].default_value = 0.45
    L.new(nz2.outputs["Fac"], rk.inputs["Value"])
    rock = mixc(n, L, rk.outputs["Result"], strata.outputs["Color"], ROSE)
    # panta: normala z 0,93 (21 grade) -> 0,80 (37 grade) = nisip -> stanca
    sl = n.new("ShaderNodeMapRange")
    L.new(sepn.outputs[2], sl.inputs["Value"])
    sl.inputs["From Min"].default_value = 0.95
    sl.inputs["From Max"].default_value = 0.80
    base = mixc(n, L, sl.outputs["Result"], sand.outputs["Color"], rock)
    # tufe: pete mici inchise, rare pe stanca, mai dese pe poale
    vo = n.new("ShaderNodeTexVoronoi")
    vo.feature = "F1"
    vo.inputs["Scale"].default_value = 0.09
    vo.inputs["Randomness"].default_value = 1.0
    L.new(tc.outputs["Object"], vo.inputs["Vector"])
    sh = n.new("ShaderNodeMapRange")
    sh.inputs["From Min"].default_value = 0.18
    sh.inputs["From Max"].default_value = 0.10
    sh.inputs["To Max"].default_value = 0.85
    L.new(vo.outputs["Distance"], sh.inputs["Value"])
    nz3 = n.new("ShaderNodeTexNoise")
    nz3.inputs["Scale"].default_value = 0.004
    L.new(tc.outputs["Object"], nz3.inputs["Vector"])
    shm = _math(n, L, "MULTIPLY", sh.outputs["Result"], nz3.outputs["Fac"])
    base = mixc(n, L, shm, base, SHRUB)
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(base, bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def vcol_material(name, k=1.0, emissive_attr=False):
    """Material cu culoarea pe varfuri (atributul `Col`); `Glow` (0..1) pe varfuri
    = flacara / fereastra, emisiva doar noaptea (WINDOW_K)."""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    col = n.new("ShaderNodeAttribute")
    col.attribute_type = "GEOMETRY"
    col.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(col.outputs["Color"], bsdf.inputs["Color"])
    surf = bsdf.outputs[0]
    if emissive_attr and WINDOW_K > 0.0:
        gl = n.new("ShaderNodeAttribute")
        gl.attribute_type = "GEOMETRY"
        gl.attribute_name = "Glow"
        em = n.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = srgb(LAMP)
        em.inputs["Strength"].default_value = 6.0 * WINDOW_K
        add = n.new("ShaderNodeAddShader")
        L.new(surf, add.inputs[0])
        e2 = n.new("ShaderNodeMixShader")
        L.new(gl.outputs["Fac"], e2.inputs[0])
        tr = n.new("ShaderNodeHoldout")   # fara contributie cand Glow = 0
        L.new(tr.outputs[0], e2.inputs[1])
        L.new(em.outputs[0], e2.inputs[2])
        L.new(e2.outputs[0], add.inputs[1])
        surf = add.outputs[0]
        # luminile nu primesc voalul intreg: o flacara la 1 km tot se vede
        haze_wrap(nt, surf, out, k * 0.6, 0.7)
        return mat
    haze_wrap(nt, surf, out, k)
    return mat


# --- Zgomot vectorizat (numpy) ------------------------------------------------------

def _hash2(ix, iy, seed):
    h = (ix * 374761393 + iy * 668265263 + seed * 1442695041) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def vnoise(x, y, seed=0):
    """Value noise 2D, 0..1, neted (smoothstep)."""
    ix = np.floor(x).astype(np.int64)
    iy = np.floor(y).astype(np.int64)
    fx = x - ix
    fy = y - iy
    ux = fx * fx * (3 - 2 * fx)
    uy = fy * fy * (3 - 2 * fy)
    a = _hash2(ix, iy, seed)
    b = _hash2(ix + 1, iy, seed)
    c = _hash2(ix, iy + 1, seed)
    d = _hash2(ix + 1, iy + 1, seed)
    return a + (b - a) * ux + (c - a) * uy + (a - b - c + d) * ux * uy


def fbm(x, y, octaves=5, seed=0, lac=2.03, gain=0.5):
    s = np.zeros_like(x)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        s += amp * vnoise(x, y, seed + o * 17)
        norm += amp
        x, y = x * lac, y * lac
        amp *= gain
    return s / norm


def ridged(x, y, octaves=5, seed=0):
    s = np.zeros_like(x)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        v = 1.0 - np.abs(2.0 * vnoise(x, y, seed + o * 31) - 1.0)
        s += amp * v * v
        norm += amp
        x, y = x * 2.07, y * 2.07
        amp *= 0.5
    return s / norm


# --- Relieful (o functie de inaltime, evaluata pe o grila polara) ------------------

def polar(az_deg, d):
    a = math.radians(az_deg)
    return math.sin(a) * d, math.cos(a) * d          # busola -> Blender XY


# Planul 0 (NEAR_GIANTS): dealuri stancoase MARI si APROPIATE (0,55-0,85 km), puse
# de mana pe directiile camerei de joc. Directiile, masurate pe Track17.baked
# (sonda temporara; busola de mers, 0 = N, 90 = E):
#
#   portiunea                          fractii       directia     cota drumului
#   H + A, dreapta de intoarcere/start 0,91-0,06     262-275 (V)   0 (sub campie)
#   B, bazarul                         0,07-0,12     300-12        1-2
#   C, fantana (coborare / urcare)     0,13-0,26     68-90 / 270   0 -> -9 -> 0
#   D, orasul albastru, urcare         0,30-0,46     16-82         2 -> 17
#   E, portile (zigzag)                0,47-0,58     322-50        18 -> 37
#   F, bastionul                       0,59-0,69     97-218        38-40 (cel mai sus)
#   G, coborarea pe stanca             0,70-0,89     135-198 (S)   38 -> 0
#
# Mehrangarh (stanca + zidurile 3D) e la busola ~30-60 de pe D si din oras: nimic
# mare din banda nu sta pe directia aia. Regulile plasarii (lectiile MV): niciun
# urias pe axa unei drepte lungi (10-25 de grade lateral). Soarele e la busola
# 90 (vezi contractul): pe dreapta lunga spre vest (H + A) e in spate, deci A si
# B (Kaylana) sunt luminate din fata; D sta la 16 grade de soare, in contre-jour
# pe coborarea in fantana (C), cu lobul de imprastiere al cetii peste el. Inaltimea e in grade din camera benzii:
# e = atan((h - CAM_Z) / d); din oras (camera sub cota campiei) ies mai jos.
# Fiecare: (nume, azimut, distanta, inaltime, rx tangential, ry radial, zid, case)
# zid = zidul orasului pe creasta; case = cate case urca pe poale.
NEAR_GIANTS = [
    # B, F: dealurile de la Kaylana, de o parte si de alta a dreptei H + A
    # (axa 262-275); deserul ramane liber intre ele. F sta si intre bastion
    # (axa 214-218, la 22 de grade) si coborarea G (axa 175-198, in dreapta):
    # prima versiune il avea la 218, adica in parbriz pe bastion.
    ("B", 294.0, 760.0, 100.0, 240.0, 230.0, False, 6),
    ("F", 240.0, 720.0, 115.0, 260.0, 240.0, True, 14),
    # C: creasta din nord cu zidul orasului (Rao Jodha), larga: o vad B si E.
    ("C", 357.0, 820.0, 130.0, 360.0, 260.0, True, 60),
    # D: dealul de la est, cu Brahmpuri urcand pe el (C in dreapta, D in stanga).
    ("D", 106.0, 720.0, 105.0, 240.0, 230.0, True, 70),
    # E: coborarea G (axa 175-198) in stanga, palatul (140) in dreapta lui.
    ("E", 160.0, 680.0, 95.0, 200.0, 210.0, False, 30),
]
# Planul 1: dealuri medii (1-4 km), aceleasi campuri, generate.
# Lanturile departate (5-20 km): creste lungi, in sectoarele de relief.
# Sectoare (busola): vestul e deserul Thar, plat (ca in realitate, spre Pakistan).
THAR = (225.0, 315.0)
# Palatul cu cupola pe dealul lui jos (azimut, distanta), sau None.
PALACE_AT = (140.0, 1800.0)
PALACE_HILL = 55.0

HILLS = []      # completat de plan_hills()


def in_sector(az, lo, hi):
    a = az % 360.0
    return lo <= a <= hi


def plan_hills(rng):
    """Lista finala de dealuri: (cx, cy, h, rx, ry, rot, rough)."""
    out = []
    for name, az, d, h, rx, ry, wall, houses in NEAR_GIANTS:
        cx, cy = polar(az, d)
        out.append((cx, cy, h, rx, ry, -math.radians(az), 0.55))
    # dealul palatului
    if PALACE_AT is not None:
        cx, cy = polar(*PALACE_AT)
        out.append((cx, cy, PALACE_HILL, 420.0, 300.0, -math.radians(PALACE_AT[0]), 0.25))
    # planul 1: dealuri medii, nu in Thar
    n = 0
    tries = 0
    while n < 34 and tries < 2000:
        tries += 1
        az = rng.uniform(0.0, 360.0)
        if in_sector(az, *THAR):
            continue
        if PALACE_AT and abs(((az - PALACE_AT[0]) + 180) % 360 - 180) < 6:
            continue
        d = rng.uniform(1300.0, 4500.0)
        h = rng.uniform(45.0, min(150.0, 20.0 + 0.035 * d))
        rx = h * rng.uniform(3.0, 7.0)
        ry = h * rng.uniform(2.0, 3.5)
        cx, cy = polar(az, d)
        out.append((cx, cy, h, rx, ry, -math.radians(az) + rng.uniform(-0.5, 0.5), 0.5))
        n += 1
    # lanturile departate (Aravalli de jucarie): creste lungi tangentiale
    az = 0.0
    while az < 360.0:
        step = rng.uniform(8.0, 18.0)
        m = az + step * 0.5
        if not in_sector(m, THAR[0] - 10, THAR[1] + 10):
            d = rng.uniform(7000.0, 18000.0)
            cx, cy = polar(m, d)
            half = math.radians(step) * d * 0.7
            h = rng.uniform(180.0, 420.0)
            out.append((cx, cy, h, half, h * rng.uniform(3.0, 5.0),
                        -math.radians(m) + rng.uniform(-0.15, 0.15), 0.6))
        az += step + (rng.uniform(2.0, 7.0) if rng.random() < 0.4 else 0.0)
    return out


def height(x, y):
    """Inaltimea terenului benzii (numpy), cota 0 = campia."""
    d = np.hypot(x, y)
    az = (np.degrees(np.arctan2(x, y)) + 360.0) % 360.0
    # campia: valuri mici de praf si pietris
    h = 2.5 * (fbm(x / 160.0, y / 160.0, 4, 3) - 0.5)
    # Thar: dune joase, lungi, pe directia vantului (SV -> NE), doar departe
    thar = np.clip(1.0 - np.abs(((az - 270.0) + 180.0) % 360.0 - 180.0) / 60.0, 0.0, 1.0)
    dune_far = np.clip((d - 900.0) / 2500.0, 0.0, 1.0)
    du = (x * 0.6 + y * 0.8) / 260.0 + 2.0 * fbm(x / 900.0, y / 900.0, 3, 9)
    dunes = 7.0 * (0.5 + 0.5 * np.sin(du * math.tau)) ** 2 * fbm(x / 700.0, y / 700.0, 3, 5)
    h += thar * dune_far * dunes
    for hi, (cx, cy, hh, rx, ry, rot, rough) in enumerate(HILLS):
        R = max(rx, ry) * 1.7
        m = (np.abs(x - cx) < R) & (np.abs(y - cy) < R)
        if not m.any():
            continue
        xm, ym = x[m], y[m]
        dx, dy = xm - cx, ym - cy
        ca, sa = math.cos(rot), math.sin(rot)
        u = dx * ca - dy * sa
        v = dx * sa + dy * ca
        # Un MASIV, nu un con: 3-6 noduri de stanca de-a lungul crestei, de
        # inaltimi diferite (dealurile de riolit din jurul Jodhpurului sunt
        # creste noduroase, cu varfuri multiple si sei, nu movile).
        kr = random.Random(9000 + hi)
        warp = fbm(xm / (rx * 0.5), ym / (rx * 0.5), 3, 100 + hi) - 0.5
        base = np.zeros_like(u)
        for _ in range(kr.randint(3, 6)):
            ku = kr.uniform(-0.65, 0.65) * rx
            kv = kr.uniform(-0.25, 0.25) * ry
            kh = kr.uniform(0.5, 1.0)
            krx = rx * kr.uniform(0.45, 0.8)
            kry = ry * kr.uniform(0.55, 0.95)
            q = np.sqrt(((u - ku) / krx) ** 2 + ((v - kv) / kry) ** 2) + 0.35 * warp
            # bolta, nu con: varfurile ascutite citeau piramide
            base = np.maximum(base, kh * np.clip(1.0 - q * q, 0.0, 1.0) ** 1.6)
        # sa joasa care leaga nodurile (creasta continua)
        q0 = np.sqrt((u / rx) ** 2 + (v / ry) ** 2) + 0.3 * warp
        base = np.maximum(base, 0.42 * np.clip(1.0 - q0 * q0, 0.0, 1.0))
        # stanca: zgomot cu creste (blocuri, ravene) mare + mic
        crag = ridged(xm / (hh * 2.2), ym / (hh * 2.2), 5, 300 + hi)
        fine = ridged(xm / 18.0, ym / 18.0, 3, 500 + hi)
        prof = base * (1.0 - rough + rough * (0.45 + 0.75 * crag)) + 0.035 * fine * np.sqrt(base)
        t = hh * prof
        # lespezi: trepte de 6 m (riolitul se rupe in blocuri)
        step = np.floor(t / 6.0) * 6.0
        frac = (t - step) / 6.0
        # (doar un sfert: cu trepte intregi dealul citea zigurat)
        t = 0.75 * t + 0.25 * (step + 6.0 * np.clip((frac - 0.25) / 0.5, 0.0, 1.0))
        h[m] = np.maximum(h[m], t)
    return h


def build_land():
    """Grila polara: 3600 de pasi pe azimut, inele geometrice de la 380 m la 40 km."""
    n_az = 900 if TEST else 3600
    r0, r1 = 240.0, 40000.0   # sub -7,5 grade (266 m): banda plina pana jos
    ratio = 1.012 if TEST else 1.005
    rs = [r0]
    while rs[-1] < r1:
        rs.append(rs[-1] * ratio)
    rs = np.array(rs)
    n_r = len(rs)
    a = np.arange(n_az) / n_az * math.tau
    A, Rr = np.meshgrid(a, rs)                       # (n_r, n_az)
    X = np.sin(A) * Rr
    Y = np.cos(A) * Rr
    Z = height(X.ravel(), Y.ravel())
    verts = np.stack([X.ravel(), Y.ravel(), Z], axis=1).astype(np.float32)
    # quad-uri (i, j) -> (i, j+1), (i+1, j+1), (i+1, j); cusatura pe azimut inchisa
    ii, jj = np.meshgrid(np.arange(n_r - 1), np.arange(n_az), indexing="ij")
    jn = (jj + 1) % n_az
    v0 = ii * n_az + jj
    v1 = ii * n_az + jn
    v2 = (ii + 1) * n_az + jn
    v3 = (ii + 1) * n_az + jj
    quads = np.stack([v0, v3, v2, v1], axis=-1).reshape(-1, 4)
    me = bpy.data.meshes.new("BandLand")
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", verts.ravel())
    nq = len(quads)
    me.loops.add(nq * 4)
    me.loops.foreach_set("vertex_index", quads.ravel().astype(np.int32))
    me.polygons.add(nq)
    me.polygons.foreach_set("loop_start", (np.arange(nq) * 4).astype(np.int32))
    me.polygons.foreach_set("loop_total", np.full(nq, 4, dtype=np.int32))
    me.update(calc_edges=True)
    me.validate()
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: teren %d x %d = %d fete" % (n_r, n_az, nq))


def h_at(x, y):
    return float(height(np.array([x], dtype=np.float64), np.array([y], dtype=np.float64))[0])


# --- Case, zid, palat, copaci --------------------------------------------------------

class Mesh:
    def __init__(self):
        self.bm = bmesh.new()
        self.col = self.bm.verts.layers.float_color.new("Col")
        self.glow = self.bm.verts.layers.float.new("Glow")

    def box(self, cx, cy, z0, sx, sy, sz, ang, col, glow=0.0):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        c = srgb(col) if isinstance(col, str) else col
        ca, sa = math.cos(ang), math.sin(ang)
        for v in res["verts"]:
            lx, ly, lz = v.co.x * sx, v.co.y * sy, (v.co.z + 0.5) * sz
            v.co = Vector((cx + lx * ca - ly * sa, cy + lx * sa + ly * ca, z0 + lz))
            v[self.col] = c
            v[self.glow] = glow
        return res

    def cyl(self, cx, cy, z0, r, hgt, col, segs=12, glow=0.0):
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, segments=segs,
                                    radius1=r, radius2=r, depth=hgt)
        c = srgb(col)
        for v in res["verts"]:
            v.co = Vector((cx + v.co.x, cy + v.co.y, z0 + hgt * 0.5 + v.co.z))
            v[self.col] = c
            v[self.glow] = glow

    def dome(self, cx, cy, z0, r, col, segs=16):
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=8, radius=r)
        c = srgb(col)
        for v in res["verts"]:
            v.co = Vector((cx + v.co.x, cy + v.co.y, z0 + max(v.co.z, 0.0) * 1.15))
            v[self.col] = c
            v[self.glow] = 0.0

    def finish(self, name, mat):
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        for poly in me.polygons:
            poly.use_smooth = False
        ob = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(ob)
        ob.data.materials.append(mat)
        print("banda: %s, %d fete" % (name, len(me.polygons)))
        return ob


def house(M, x, y, rng, blue_bias=0.8):
    """O casa cub: 1-3 niveluri, var albastru (rar bej/alb), uneori cu rezervor
    negru pe terasa; noaptea, una-doua ferestre aprinse spre camera."""
    z = h_at(x, y)
    w = rng.uniform(5.0, 9.0)
    dd = rng.uniform(5.0, 9.0)
    lv = rng.choice((1, 2, 2, 2, 3))
    hh = 3.2 * lv + rng.uniform(0.0, 1.0)
    r = rng.random()
    if r < blue_bias * 0.72:
        col = BLUE
    elif r < blue_bias:
        col = INDIGO
    elif r < 0.95:
        col = BEIGE
    else:
        col = WHITE
    to_cam = math.atan2(-y, -x)
    ang = to_cam + rng.uniform(-0.5, 0.5)
    M.box(x, y, z - 3.0, w, dd, hh + 3.0, ang, col)
    if rng.random() < 0.35:
        M.cyl(x + rng.uniform(-1.5, 1.5), y + rng.uniform(-1.5, 1.5), z + hh, 0.9, 1.6, TANK, segs=6)
    # ferestre: cuburi mici pe fata spre camera (Glow = 1)
    if rng.random() < 0.75:
        fx, fy = math.cos(to_cam), math.sin(to_cam)
        off = 0.5 * max(w, dd) + 0.15
        for _ in range(rng.randint(1, 3)):
            t = rng.uniform(-0.35, 0.35) * w
            zz = z + rng.uniform(0.8, hh - 1.6)
            M.box(x + fx * off - fy * t, y + fy * off + fx * t, zz, 1.0, 0.3, 1.3,
                  to_cam + math.pi * 0.5, LAMP if WINDOW_K > 0 else "3A3A4A", glow=1.0)


def build_houses(M, rng):
    """Brahmpuri continua dincolo de bucla: CIORCHINI de case lipite (cartiere),
    nu case risipite. Pe poalele dealurilor apropiate (NEAR_GIANTS[...][7] case),
    orasul vechi albastru; pe campie, cartiere mai noi, jumatate bej-ocru."""
    count = 0

    def cluster(cx, cy, n, z_max, blue_bias):
        nonlocal count
        rad = 7.0 * math.sqrt(n) + 10.0
        for _ in range(n):
            a = rng.uniform(0.0, math.tau)
            r = rad * math.sqrt(rng.random())
            x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            if math.hypot(x, y) < 470.0 or h_at(x, y) > z_max:
                continue
            house(M, x, y, rng, blue_bias)
            count += 1

    for name, az, d, h, rx, ry, wall, houses in NEAR_GIANTS:
        left = houses
        while left > 0:
            n = min(left, rng.randint(12, 24))
            left -= n
            t = rng.uniform(-0.8, 0.8)
            rr = d - ry * rng.uniform(0.55, 1.05)
            a = math.radians(az) + t * (rx * 0.9) / d
            cluster(math.sin(a) * rr, math.cos(a) * rr, n, h * 0.5, 0.85)
    for _ in range(CITY_CLUSTERS):
        az = rng.uniform(0.0, 360.0)
        if not any(in_sector(az, lo, hi) for lo, hi in CITY_SECTORS):
            continue
        d = 520.0 + rng.random() ** 1.5 * 2800.0
        x, y = polar(az, d)
        cluster(x, y, rng.randint(6, 16), 25.0, 0.5)
    print("banda: %d case" % count)


CITY_SECTORS = [(0.0, 215.0), (320.0, 360.0)]
CITY_CLUSTERS = 70


def crest_line(az, d, rx, ry, n=40):
    """Creasta unui deal apropiat: pentru fiecare pozitie tangentiala, punctul cel
    mai inalt pe directia radiala."""
    a = math.radians(az)
    radial = Vector((math.sin(a), math.cos(a), 0.0))
    tang = Vector((math.cos(a), -math.sin(a), 0.0))
    pts = []
    for k in range(n + 1):
        t = -0.85 + 1.7 * k / n
        best = None
        for s in np.linspace(-0.8, 0.8, 33):
            p = radial * (d + s * ry) + tang * (t * rx)
            z = h_at(p.x, p.y)
            if best is None or z > best[2]:
                best = (p.x, p.y, z)
        pts.append(best)
    return pts


def build_walls(M, rng):
    """Zidul orasului pe crestele dealurilor apropiate: segmente de 7 m cu creneluri,
    bastioane rotunde la ~70 m; noaptea, candele pe coronament."""
    for name, az, d, h, rx, ry, wall, houses in NEAR_GIANTS:
        if not wall:
            continue
        pts = crest_line(az, d, rx, ry)
        # doar partea inalta a crestei (zidul coboara pana la poale doar rar)
        pts = [p for p in pts if p[2] > h * 0.45]
        acc = 0.0
        for p0, p1 in zip(pts[:-1], pts[1:]):
            dx, dy = p1[0] - p0[0], p1[1] - p0[1]
            L = math.hypot(dx, dy)
            if L < 1.0:
                continue
            ang = math.atan2(dy, dx)
            steps = max(1, int(L / 6.0))
            for s in range(steps):
                t0 = s / steps
                t1 = (s + 1) / steps
                x0, y0 = p0[0] + dx * t0, p0[1] + dy * t0
                x1, y1 = p0[0] + dx * t1, p0[1] + dy * t1
                zm = min(h_at(x0, y0), h_at(x1, y1))
                cx, cy = (x0 + x1) * 0.5, (y0 + y1) * 0.5
                seg = math.hypot(x1 - x0, y1 - y0)
                M.box(cx, cy, zm - 4.0, seg + 0.4, 3.2, 11.0, ang, SANDSTONE)
                # creneluri
                for m in range(int(seg / 2.4)):
                    tt = (m + 0.5) / max(1, int(seg / 2.4)) - 0.5
                    M.box(cx + math.cos(ang) * tt * seg, cy + math.sin(ang) * tt * seg,
                          zm + 7.0, 1.2, 3.2, 1.3, ang, SANDSTONE_LIGHT)
                if WINDOW_K > 0 and rng.random() < 0.6:
                    M.box(cx, cy, zm + 7.0, 0.5, 3.4, 0.5, ang, LAMP, glow=1.0)
                acc += seg
                if acc > 70.0:
                    acc = 0.0
                    M.cyl(cx, cy, zm - 4.0, 5.5, 14.0, SANDSTONE, segs=14)
                    for m in range(8):
                        aa = m / 8 * math.tau
                        M.box(cx + math.cos(aa) * 5.0, cy + math.sin(aa) * 5.0, zm + 10.0,
                              1.4, 1.4, 1.4, aa, SANDSTONE_LIGHT)


def build_palace(M):
    """Palatul cu cupola pe dealul lui (SE): corp lung pe doua niveluri, turn
    central cu cupola mare, aripi cu cupole mici; gresie bej."""
    if PALACE_AT is None:
        return
    az, d = PALACE_AT
    cx, cy = polar(az, d)
    z = h_at(cx, cy)
    to_cam = math.atan2(-cy, -cx)
    ang = to_cam + math.pi * 0.5                   # fatada lunga spre oras
    ca, sa = math.cos(ang), math.sin(ang)
    M.box(cx, cy, z - 3.0, 110.0, 45.0, 21.0, ang, PALACE)
    for s in (-1, 1):
        wx, wy = cx + ca * s * 42.0, cy + sa * s * 42.0
        M.box(wx, wy, z + 18.0, 18.0, 18.0, 8.0, ang, PALACE)
        M.dome(wx, wy, z + 26.0, 6.5, PALACE)
    M.cyl(cx, cy, z + 18.0, 15.0, 14.0, PALACE, segs=24)
    M.dome(cx, cy, z + 32.0, 14.0, PALACE, segs=24)
    M.cyl(cx, cy, z + 47.5, 1.2, 5.0, PALACE, segs=8)
    if WINDOW_K > 0:
        # palatul e luminat de Diwali: un sir de lampi pe cornisa
        for k in range(24):
            t = k / 23 - 0.5
            M.box(cx + ca * t * 108.0 - sa * 23.0, cy + sa * t * 108.0 + ca * 23.0, z + 17.5,
                  1.2, 0.4, 1.2, ang, LAMP, glow=1.0)
    print("banda: palat az %.0f d %.0f z %.0f -> %.1f grade"
          % (az, d, z, math.degrees(math.atan2(z + 50.0 - CAM_Z, d))))


def build_trees(M, rng):
    """Khejri si neem raspanditi pe campie (0,45-2,5 km), rari in Thar."""
    n = 0
    for _ in range(1400):
        az = rng.uniform(0.0, 360.0)
        d = 460.0 + rng.random() ** 1.6 * 2400.0
        if in_sector(az, *THAR) and rng.random() < 0.7:
            continue
        x, y = polar(az, d)
        z = h_at(x, y)
        if z > 30.0:
            continue
        hh = rng.uniform(4.0, 8.0)
        M.box(x, y, z - 0.5, 0.6, 0.6, hh * 0.6, 0.0, "4A3A2E")
        r = hh * rng.uniform(0.45, 0.65)
        res = bmesh.ops.create_icosphere(M.bm, subdivisions=1, radius=r)
        c = srgb(KHEJRI if rng.random() < 0.7 else SHRUB)
        for v in res["verts"]:
            v.co = Vector((x + v.co.x * 1.2, y + v.co.y * 1.2, z + hh * 0.7 + v.co.z * 0.6))
            v[M.col] = c
            v[M.glow] = 0.0
        n += 1
    print("banda: %d copaci" % n)


# --- Randarea --------------------------------------------------------------------

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
    cd.clip_end = 80000.0
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
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=60.0)
        me = bpy.data.meshes.new("Mk" + name)
        bm.to_mesh(me)
        bm.free()
        ob = bpy.data.objects.new("Mk" + name, me)
        bpy.context.collection.objects.link(ob)
        ob.location = (x, y, 40)
        mat, nt, out = new_material("Mk" + name)
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = col
        nt.links.new(em.outputs[0], out.inputs["Surface"])
        ob.data.materials.append(mat)


reset()
rng = random.Random(17)
random.seed(17)
HILLS[:] = plan_hills(random.Random(1717))
setup_render()
build_land()
M_city = Mesh()
build_houses(M_city, random.Random(170))
build_walls(M_city, random.Random(171))
build_palace(M_city)
M_city.finish("BandCity", vcol_material("BandCity", k=0.85, emissive_attr=True))
M_tree = Mesh()
build_trees(M_tree, random.Random(172))
M_tree.finish("BandTrees", vcol_material("BandTrees"))
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
