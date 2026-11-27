"""Banda de orizont a cerului Machu Picchu (Track15) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/machupicchu_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime
(-7,5 .. +15), cu alfa: Anzii peruani din jurul cetatii — varfuri abrupte, ca
niste capatani de zahar, acoperite de padure de nori pana sus, cu granit iesit pe
creste si pe fetele cele mai repezi; o MARE DE NORI in vaile de jos (valea
Urubamba), din care varfurile se ridica; benzi de nor agatate de flancuri; si
departe, spre sud si est, cordiliera cu zapada (Salcantay, Veronica). Cerul
ramane TRANSPARENT: gradientul si norii lui ii deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`).

Reteta e cea de pe Ha Long / Fiordland / Monument Valley. Ce e specific aici:

  * IMBINAREA e ceata. Tema e „norul care urca din defileu”: ceata jocului e
    alb-gri (`fog` 0.86, 0.87, 0.89) si la fog_end (300 m) terenul real e deja
    ~85% ceata. Deci sub orizont banda NU picteaza un sol, ci MAREA DE NORI:
    un plan alb la nivelul vailor care incepe la ~380 m (marginea de jos a
    benzii, -7,5 grade din CAM_Z) si e opac pana departe, apoi se rupe si lasa
    sa se vada fundul vailor intunecat. Terenul cetos al jocului intra in nor.
  * Relieful e un camp de inaltimi polar (ca la Fiordland), dar varfurile sunt
    CONURI individuale (`cone`) cu flancuri concave si varf ascutit — asa arata
    muntii din jurul cetatii (Huayna Picchu, Putucusi, Machu Picchu) — legate
    intre ele de creste cu sei. Fiecare plan e mai palid (perspectiva aeriana
    spre HAZE) si putin mai sus pe cer.
  * Planul 0 (`NEAR_GIANTS`): cativa uriasi APROPIATI (0,6-1 km), pusi de mana
    pe directiile in care priveste camera pe portiunile lungi, care ies din
    cadru si dau scara (lectia MV, #763). Nu in spatele lui Huayna Picchu real
    (relief al jocului, la NE de cetate) — acolo banda ramane joasa.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste marea de nori, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "machupicchu" (`sun_rotation_deg` (-40, 45, 0), acelasi in
    Track15.tscn: busola 135, SE, 40 de grade), `sun_color` (1.0, 0.95, 0.85),
    energia 1,35; ambientul B4C2D2 la 0,46;
  * HAZE = `sky_horizon` din tema (B9CFE3): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_sky_band.py [-- --test]
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
# Ochiul peste marea de nori. Pe creasta (cetatea, Poarta Soarelui) camera de joc
# sta la +35..+45 m peste cetate, iar valea (raul) e la -40: ~50 m peste nor e
# vederea de pe creasta, de unde se vede banda. Cu 50 m, -7,5 grade (marginea de
# jos a benzii) cade pe nor la 380 m = ChaseCamera.FAR_PLANE: acolo unde se
# termina terenul jocului incepe marea de nori pictata.
CAM_Z = 50.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "machupicchu_horizon_band_test.png" if TEST
                   else "machupicchu_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB, din tema / brief §4) -------------------------------------------
HAZE = "B9CFE3"          # = sky_horizon din tema: departarea intra in cer
# Norul: in familia cetii jocului (0.86, 0.87, 0.89) = DBDEE3, luminat de soare
# deasupra (un pic mai alb), cu umbra albastruie. Vezi `cloud_sea_material`.
CLOUD = "CACFD4"
CLOUD_SHADE = "A9B0B9"
MIST = "D6DCE3"          # ceata joasa din vai, pe picioarele muntilor
# Padurea de nori: verde inchis, putin albastrui (`hill_color` 0.20, 0.30, 0.22 =
# 334D38 si TROPICAL_GREEN / LOG_DARK din brief). Albedo, nu culoarea pe ecran.
FOREST = ["2F5A2C", "386633", "3F6E33", "2C5230", "27482A", "4A7438"]
FOREST_DEEP = "1C3020"   # ravenele
GRANITE = "8A8780"       # granit andin (MARBLE_GREY tras spre scarp_tint 4A4844)
GRANITE_DARK = "5A5853"
SNOW = "F3F5F7"
SNOW_SHADE = "B8C6D6"
VALLEY = "2B3F2E"        # fundul vailor, prin golurile norului
SUN_COLOR = (1.0, 0.95, 0.85)
# Godot inmulteste energia luminii cu pi (alb lambertian perpendicular = energia);
# Cycles nu. Deci taria Cycles = pi x energia temei (masurat pe MV, #761).
SUN_STRENGTH = math.pi * 1.35
AMBIENT = "B4C2D2"
AMBIENT_ENERGY = 0.46
SUN_ROT = (-40.0, 45.0)                    # sun_rotation_deg (x, y) din tema
FILL_AZ, FILL_STRENGTH = 315.0, 2.2

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului incolo; F0 = cat a spalat deja ceata jocului peretii de la 250-300 m.
# Aer de altitudine, dar umed (padure de nori): mai gros decat la MV.
HAZE_D0, HAZE_D, HAZE_F0 = 300.0, 9000.0, 0.10
HAZE_MAX = 0.75
MIST_H, MIST_K = 55.0, 0.40               # ceata joasa: K * exp(-z/H), doar departe
SNOW_GLOW = 0.8

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
    """Inaltimea (peste nor) care sta la `theta_deg` peste ochi, la distanta d."""
    return CAM_Z + d * math.tan(math.radians(theta_deg))


# --- Varfurile ---------------------------------------------------------------------
#
# Fiecare varf: (x, y, h, R, k, snow). Con cu flancuri concave: z = h (1 - s)^k,
# s = r / R. k 1,3-1,8 = capatana de zahar (flanc abrupt jos, varf ascutit);
# R/h 0,7-1,1 = flancuri de 45-55 de grade, ca muntii reali din jurul cetatii.
#
# Planul 0, pus de mana: (azimut busola, distanta, unghi varf peste ochi, R/h, k).
# Azimuturile vin din sonda pe Track15.baked (camera de joc reala), vezi tema.
NEAR_GIANTS = [
    (118.0, 750.0, 11.0, 0.85, 0),    # urcarea pe trepte (0,02-0,17, spre E), dreapta
    (142.0, 650.0, 8.0, 0.95, 0),     # Poarta Soarelui (0,17), raul spre E (0,70-0,90)
    (158.0, 820.0, 9.0, 0.9, 0),      # dreapta spre S (0,91-0,97), stanga
    (214.0, 700.0, 10.0, 0.85, 0),    # dreapta spre S, dreapta; golul 170-200 = Salcantay
    (248.0, 720.0, 10.5, 0.85, 0),    # valea spre V (0,53-0,62, 0,75, 0,84), stanga
    (293.0, 820.0, 9.5, 0.9, 0),      # valea spre V, dreapta
]

# Planurile departate: (d_min, d_max, theta_min, theta_max, pas de azimut min/max)
PLANES = [
    (1200.0, 2000.0, 4.0, 7.5, 7.0, 15.0),
    (2300.0, 3800.0, 3.6, 6.2, 6.0, 12.0),
    (4500.0, 7500.0, 3.4, 5.4, 5.0, 10.0),
    (8500.0, 12000.0, 3.0, 4.6, 4.0, 9.0),
]
# Cordiliera cu zapada: sectoare de azimut (busola) si distanta.
SNOW_SECTORS = [
    # Salcantay: aproape drept la sud, cel mai inalt (6271 m in realitate)
    (150.0, 205.0, 15000.0, 19000.0, 5.0, 6.6),
    # Veronica / Wakay Willka: spre est
    (75.0, 112.0, 16000.0, 21000.0, 4.0, 5.4),
]
# Sectoare in care NU pun varfuri apropiate (planul 0 si 1): in spatele reperelor
# reale ale jocului (Huayna Picchu la NE de cetate). Completat dupa sonda.
QUIET = [(325.0, 360.0), (0.0, 48.0)]


def in_quiet(az):
    a = az % 360.0
    return any(lo <= a <= hi for lo, hi in QUIET)


def polar(az_deg, d):
    a = math.radians(az_deg)
    return math.sin(a) * d, math.cos(a) * d      # Blender: x est, y nord


def massif(peaks, rng, x, y, h, R, snow, plane, sats=(1, 3)):
    """Un varf principal + 1-3 sateliti lipiti de el (umeri, varfuri gemene), cu
    forma si orientare proprie. Un con singur, simetric, citea „gramada de nisip”."""
    a = rng.uniform(1.2, 2.0)            # 1 = con; >1 = capatana rotunjita sus
    b = rng.uniform(0.9, 1.5)            # >1 = flanc concav, picior lung
    rot = rng.uniform(0.0, math.pi)
    ecc = rng.uniform(0.65, 1.0)
    peaks.append((x, y, h, R, a, b, snow, plane, rot, ecc))
    for _ in range(rng.randint(*sats)):
        ang = rng.uniform(0.0, math.tau)
        off = R * rng.uniform(0.35, 0.8)
        f = rng.uniform(0.55, 0.85)
        peaks.append((x + math.cos(ang) * off, y + math.sin(ang) * off, h * f,
                      R * f * rng.uniform(0.8, 1.1), rng.uniform(1.2, 1.9),
                      rng.uniform(0.9, 1.4), snow, plane, rng.uniform(0.0, math.pi),
                      rng.uniform(0.6, 1.0)))


def make_peaks(rng):
    peaks = []
    for az, d, th, rk, k in NEAR_GIANTS:
        x, y = polar(az, d)
        h = h_for(d, th)
        massif(peaks, rng, x, y, h, h * rk, 0, 0, sats=(1, 2))
    for pi_, (d0, d1, t0, t1, s0, s1) in enumerate(PLANES):
        az = rng.uniform(0.0, 360.0)
        end = az + 360.0
        while az < end:
            step = rng.uniform(s0, s1)
            a = az % 360.0
            if not (pi_ <= 1 and in_quiet(a)):
                d = rng.uniform(d0, d1)
                th = rng.uniform(t0, t1)
                h = h_for(d, th)
                x, y = polar(a, d)
                massif(peaks, rng, x, y, h, h * rng.uniform(0.6, 0.95), 0, pi_ + 1)
            az += step
    for a0, a1, d0, d1, t0, t1 in SNOW_SECTORS:
        az = a0
        while az < a1:
            d = rng.uniform(d0, d1)
            th = rng.uniform(t0, t1)
            if abs(az - 0.5 * (a0 + a1)) < 0.18 * (a1 - a0):
                th += 1.2                       # varful principal al masivului
            h = h_for(d, th)
            x, y = polar(az, d)
            massif(peaks, rng, x, y, h, h * rng.uniform(1.0, 1.5), 1, 5, sats=(1, 2))
            az += rng.uniform(3.0, 6.0)
    return peaks


# --- Scena -----------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node, alpha_socket=None, mist_k=MIST_K):
    """surface -> amestec cu HAZE dupa distanta si cu MIST dupa inaltime.
    Cu `alpha_socket`, rezultatul se amesteca la sfarsit cu Transparent (nori)."""
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
    ramp = n.new("ShaderNodeMapRange")                        # ceata doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 450.0
    ramp.inputs["From Max"].default_value = 1500.0
    mist = math_node("MULTIPLY", z, ramp.outputs["Result"])
    mist = math_node("MULTIPLY", mist, vb=mist_k)
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


def land_material():
    """Culoarea e in vertex color (padure / granit / zapada, calculate in
    `build_land`); materialul adauga coroanele padurii (zgomot de ~7 m in
    coordonate de lume, doar unde atributul `canopy` e 1), lumineaza si spala in
    aer. Zapada (alfa din Col) primeste o emisie mica, ca la Fiordland."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    can = n.new("ShaderNodeAttribute")
    can.attribute_name = "canopy"
    can.attribute_type = "GEOMETRY"
    tc = n.new("ShaderNodeTexCoord")
    vor = n.new("ShaderNodeTexVoronoi")
    vor.feature = "F1"
    vor.inputs["Scale"].default_value = 1.0 / 7.0
    L.new(tc.outputs["Object"], vor.inputs["Vector"])
    # coroana: centrul luminat, marginea inchisa (distanta F1 0 -> 0,5)
    cr = n.new("ShaderNodeMapRange")
    cr.inputs["From Min"].default_value = 0.0
    cr.inputs["From Max"].default_value = 0.75
    cr.inputs["To Min"].default_value = 1.18
    cr.inputs["To Max"].default_value = 0.62
    L.new(vor.outputs["Distance"], cr.inputs["Value"])
    k = n.new("ShaderNodeMix")                     # 1 unde nu e padure
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
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(mul.outputs[2], bsdf.inputs["Color"])
    em = n.new("ShaderNodeEmission")
    L.new(at.outputs["Color"], em.inputs["Color"])
    g = n.new("ShaderNodeMath")
    g.operation = "MULTIPLY"
    g.inputs[1].default_value = SNOW_GLOW
    L.new(at.outputs["Alpha"], g.inputs[0])
    L.new(g.outputs[0], em.inputs["Strength"])
    add = n.new("ShaderNodeAddShader")
    L.new(bsdf.outputs[0], add.inputs[0])
    L.new(em.outputs[0], add.inputs[1])
    haze_wrap(nt, add.outputs[0], out)
    return mat


def valley_material():
    """Fundul vailor, sub marea de nori: padure intunecata, NEILUMINATA de soare
    direct (e in umbra muntilor si sub nor), spalata de aceeasi ceata."""
    mat, nt, out = new_material("BandValley")
    n, L = nt.nodes, nt.links
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(VALLEY)
    em.inputs["Strength"].default_value = 0.55
    haze_wrap(nt, em.outputs[0], out)
    return mat


def cloud_sea_material():
    """Marea de nori: plan alb la nivelul vailor. Opac pana la ~1,4 km (acolo
    intra terenul cetos al jocului), apoi se rupe in petice prin care se vede
    fundul vailor. Luminat difuz (soarele de sus il face mai alb) + o emisie,
    ca in umbra sa nu iasa gri murdar. Relief de vata: zgomot in normala."""
    mat, nt, out = new_material("BandCloudSea")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / 900.0, 1.0 / 900.0, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 1.0
    nz.inputs["Detail"].default_value = 6.0
    nz.inputs["Roughness"].default_value = 0.62
    L.new(mp.outputs[0], nz.inputs["Vector"])
    # acoperirea scade cu distanta: 1 pana la 1,4 km, apoi pragul urca
    cam = n.new("ShaderNodeCameraData")
    dr = n.new("ShaderNodeMapRange")
    dr.inputs["From Min"].default_value = 1400.0
    dr.inputs["From Max"].default_value = 5000.0
    dr.inputs["To Min"].default_value = 0.0
    dr.inputs["To Max"].default_value = 0.56
    L.new(cam.outputs["View Distance"], dr.inputs["Value"])
    thr = n.new("ShaderNodeMath")
    thr.operation = "SUBTRACT"
    L.new(nz.outputs["Fac"], thr.inputs[0])
    L.new(dr.outputs["Result"], thr.inputs[1])
    cov = n.new("ShaderNodeMapRange")
    cov.inputs["From Min"].default_value = 0.0
    cov.inputs["From Max"].default_value = 0.08
    L.new(thr.outputs[0], cov.inputs["Value"])
    # aproape (sub 1,4 km) dr = 0 si Fac ~0,3-0,7 -> acoperire plina
    nz2 = n.new("ShaderNodeTexNoise")
    nz2.inputs["Scale"].default_value = 1.0 / 160.0
    nz2.inputs["Detail"].default_value = 4.0
    L.new(tc.outputs["Object"], nz2.inputs["Vector"])
    # NEILUMINAT (emisie), ca marea de la Ha Long: umbrele uriasilor pe nor
    # desenau dungi gri chiar la marginea de jos a benzii, unde se lipeste
    # ceata jocului. Relieful de vata vine din zgomot (umbra in vai de nor).
    vr = n.new("ShaderNodeValToRGB")
    els = vr.color_ramp.elements
    els[0].position, els[0].color = 0.35, srgb(CLOUD_SHADE)
    els[1].position, els[1].color = 0.68, srgb(CLOUD)
    L.new(nz2.outputs["Fac"], vr.inputs["Fac"])
    em = n.new("ShaderNodeEmission")
    L.new(vr.outputs["Color"], em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    add = em
    haze_wrap(nt, add.outputs[0], out, alpha_socket=cov.outputs["Result"], mist_k=0.0)
    return mat


def cloud_bank_material():
    """Benzile de nor agatate de flancuri (ca la Fiordland), trase pe orizontala,
    cu margini moi sus/jos si la capete."""
    mat, nt, out = new_material("BandCloudBank")
    n, L = nt.nodes, nt.links
    uv = n.new("ShaderNodeTexCoord")
    sepuv = n.new("ShaderNodeSeparateXYZ")
    L.new(uv.outputs["UV"], sepuv.inputs[0])
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0, 1.0, 2.4)
    L.new(uv.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 0.018
    nz.inputs["Detail"].default_value = 8.0
    nz.inputs["Roughness"].default_value = 0.66
    L.new(mp.outputs[0], nz.inputs["Vector"])
    cr = n.new("ShaderNodeMapRange")
    cr.inputs["From Min"].default_value = 0.44
    cr.inputs["From Max"].default_value = 0.64
    L.new(nz.outputs["Fac"], cr.inputs["Value"])

    def prof(sock, a, b):
        s1 = n.new("ShaderNodeMapRange")
        s1.interpolation_type = "SMOOTHSTEP"
        s1.inputs["From Min"].default_value = 0.0
        s1.inputs["From Max"].default_value = a
        L.new(sock, s1.inputs["Value"])
        s2 = n.new("ShaderNodeMapRange")
        s2.interpolation_type = "SMOOTHSTEP"
        s2.inputs["From Min"].default_value = 1.0
        s2.inputs["From Max"].default_value = b
        L.new(sock, s2.inputs["Value"])
        m = n.new("ShaderNodeMath")
        m.operation = "MULTIPLY"
        L.new(s1.outputs[0], m.inputs[0])
        L.new(s2.outputs[0], m.inputs[1])
        return m.outputs[0]
    pv = prof(sepuv.outputs[1], 0.5, 0.5)
    pu = prof(sepuv.outputs[0], 0.2, 0.8)
    a1 = n.new("ShaderNodeMath")
    a1.operation = "MULTIPLY"
    L.new(cr.outputs[0], a1.inputs[0])
    L.new(pv, a1.inputs[1])
    a2 = n.new("ShaderNodeMath")
    a2.operation = "MULTIPLY"
    L.new(a1.outputs[0], a2.inputs[0])
    L.new(pu, a2.inputs[1])
    a3 = n.new("ShaderNodeMath")
    a3.operation = "MULTIPLY"
    a3.inputs[1].default_value = 0.92
    L.new(a2.outputs[0], a3.inputs[0])
    df = n.new("ShaderNodeBsdfDiffuse")
    df.inputs["Color"].default_value = srgb(CLOUD)
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(CLOUD_SHADE)
    em.inputs["Strength"].default_value = 0.4
    add = n.new("ShaderNodeAddShader")
    L.new(df.outputs[0], add.inputs[0])
    L.new(em.outputs[0], add.inputs[1])
    haze_wrap(nt, add.outputs[0], out, alpha_socket=a3.outputs[0], mist_k=0.0)
    return mat


# --- Relieful: camp de inaltimi polar ------------------------------------------

N_AZ = 1024 if TEST else 4096
N_R = 140 if TEST else 420
R0, R1 = 420.0, 24000.0
FLOOR_Z = -45.0          # fundul vailor, sub nor


def heights(px, py, peaks, rng_seed=15):
    z = np.full(px.shape, FLOOR_Z, dtype=np.float64)
    hm = np.full(px.shape, 1.0)                  # inaltimea varfului dominant
    kid = np.full(px.shape, -1, dtype=np.int32)  # planul varfului dominant
    snowy = np.zeros(px.shape)
    sfrac = np.ones(px.shape)                    # r / R la varful dominant
    for i, (x0, y0, h, R, pa, pb, sn, pl, rot, ecc) in enumerate(peaks):
        # doar varfurile din jurul acestui varf (cutie), ca sa nu calculez tot
        m = (np.abs(px - x0) < R * 1.4) & (np.abs(py - y0) < R * 1.4)
        if not m.any():
            continue
        qx, qy = px[m], py[m]
        dx, dy = qx - x0, qy - y0
        # elipsa rotita: creasta alungita pe o directie
        ex = dx * math.cos(rot) + dy * math.sin(rot)
        ey = (-dx * math.sin(rot) + dy * math.cos(rot)) / ecc
        r = np.hypot(ex, ey)
        # contraforturi: raza „vazuta” variaza cu unghiul in jurul varfului
        ang = np.arctan2(dy, dx)
        lobe = (vnoise(np.cos(ang) * 3.0 + i * 7.1, np.sin(ang) * 3.0, 1.0, 900 + i) - 0.5)
        rib = (vnoise(np.cos(ang) * 8.0 + r / R * 2.0, np.sin(ang) * 8.0 + i * 3.3,
                      1.0, 1300 + i) - 0.5)
        rr = r / (R * (1.0 + 0.30 * lobe + 0.16 * rib))
        s = np.clip(rr, 0.0, 1.0)
        zk = FLOOR_Z + (h - FLOOR_Z) * np.power(1.0 - np.power(s, pa), pb)
        # muchii si ravene la scara varfului: silueta zimtata, nu palarie
        jag = fbm(qx, qy, R * 0.45, 2000 + i, octaves=3, ridged=True)
        zk = zk + (jag - 0.45) * 0.22 * (h - FLOOR_Z) * np.sqrt(np.clip(1.0 - s, 0.0, 1.0)) * s * 2.0
        better = zk > z[m]
        sub_z = np.where(better, zk, z[m])
        z[m] = sub_z
        hm[m] = np.where(better, h, hm[m])
        kid[m] = np.where(better, pl, kid[m])
        snowy[m] = np.where(better, float(sn), snowy[m])
        sfrac[m] = np.where(better, s, sfrac[m])
    # creste intre varfurile fiecarui plan: a doua trecere, mai joasa (sei),
    # facuta ca maxim cu un con mult mai lat si mai turtit al fiecarui varf
    for i, (x0, y0, h, R, pa, pb, sn, pl, rot, ecc) in enumerate(peaks):
        if pl == 0:
            continue                         # uriasii apropiati ies direct din nor
        R2 = R * 2.0
        m = (np.abs(px - x0) < R2) & (np.abs(py - y0) < R2)
        if not m.any():
            continue
        r = np.hypot(px[m] - x0, py[m] - y0)
        s = np.clip(r / R2, 0.0, 1.0)
        zk = FLOOR_Z + (0.34 * h - FLOOR_Z) * np.power(1.0 - s, 1.6)
        better = zk > z[m]
        z[m] = np.where(better, zk, z[m])
        kid[m] = np.where(better & (kid[m] < 0), pl, kid[m])
        hm[m] = np.where(better & (hm[m] < 2.0), h, hm[m])
    # ravene si muchii fine pe flancuri (zgomot ridged), proportional cu cota
    rid = fbm(px, py, 160.0, rng_seed, octaves=4, ridged=True)
    z += (rid - 0.45) * 0.10 * np.maximum(z - FLOOR_Z, 0.0)
    return z, hm, kid, snowy, sfrac


def build_land(peaks):
    az = np.linspace(0.0, math.tau, N_AZ, endpoint=False)
    rr = R0 * np.power(R1 / R0, np.linspace(0.0, 1.0, N_R))
    A, Rg = np.meshgrid(az, rr)                     # (N_R, N_AZ)
    px = np.sin(A) * Rg
    py = np.cos(A) * Rg
    z, hm, kid, snowy, sfrac = heights(px, py, peaks)
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

    def lin(hx):
        return np.array(srgb(hx)[:3])

    hrel = np.clip((z - FLOOR_Z) / np.maximum(hm - FLOOR_Z, 1.0), 0.0, 1.2)
    # padurea: tonuri pe petice mari (specii, umezeala), ravenele mai adanci
    fcol_i = np.clip((fbm(px, py, 120.0, 71, octaves=2) * len(FOREST)).astype(int), 0,
                     len(FOREST) - 1)
    fpal = np.array([lin(c) for c in FOREST])
    fcol = fpal[fcol_i]
    gully = smoothstep(0.55, 0.85, fbm(px, py, 160.0, 15, octaves=4, ridged=True))
    fcol = fcol * (1 - 0.45 * (1 - gully))[..., None] + lin(FOREST_DEEP) * (0.45 * (1 - gully))[..., None]
    # granitul: pe fetele cele mai repezi si pe muchiile de sub varf, in pete
    steep = smoothstep(0.50, 0.30, nz)
    crest = smoothstep(0.80, 0.93, hrel) * smoothstep(0.35, 0.7, fbm(px, py, 50.0, 31, octaves=3))
    slab = steep * smoothstep(0.45, 0.65, fbm(px, py + z * 0.6, 70.0, 37, octaves=3))
    rock_w = np.clip(np.maximum(crest, slab), 0.0, 1.0) * (1.0 - snowy)
    lit = smoothstep(0.3, 0.8, nz)
    rock = lin(GRANITE_DARK)[None, None, :] * (1 - lit)[..., None] + lin(GRANITE)[None, None, :] * lit[..., None]
    col = fcol * (1 - rock_w)[..., None] + rock * rock_w[..., None]
    canopy = 1.0 - rock_w
    # cordiliera: zapada peste ~55% din inaltime, pe ce priveste in sus, coborand
    # pe ravene; dedesubt granit gol (peste padure), apoi padure jos
    cap = 0.52 + 0.10 * (fbm(px, py, 400.0, 83, octaves=3) - 0.5)
    snow = smoothstep(cap, cap + 0.05, hrel) * smoothstep(-0.2, 0.3, nz) * snowy
    bare = smoothstep(0.30, 0.38, hrel) * snowy
    col = col * (1 - bare)[..., None] + rock * bare[..., None]
    canopy = canopy * (1 - bare)
    scol = lin(SNOW)[None, None, :] * lit[..., None] + lin(SNOW_SHADE)[None, None, :] * (1 - lit)[..., None]
    col = col * (1 - snow)[..., None] + scol * snow[..., None]
    print("banda: zapada pe %.1f%%, granit pe %.1f%% din varfuri" % (
        100.0 * (snow > 0.5).mean(), 100.0 * (rock_w > 0.5).mean()))
    rgba = np.concatenate([col.reshape(-1, 3), snow.reshape(-1, 1)], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    at = me.attributes.new("canopy", "FLOAT", "POINT")
    at.data.foreach_set("value", canopy.astype(np.float32).ravel())
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d varfuri, %d fete, %d munti" % (N_R, N_AZ, nf, len(peaks)))


def plane(name, z, mat, s=60000.0):
    me = bpy.data.meshes.new(name)
    me.from_pydata([(-s, -s, z), (s, -s, z), (s, s, z), (-s, s, z)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


def build_clouds(rng, peaks):
    """Benzi de nor JOS, agatate de flancurile varfurilor din planurile 0-2,
    la 25-55% din inaltime, putin in fata muntelui."""
    mat = cloud_bank_material()
    cands = [p for p in peaks if p[7] <= 2 and p[6] == 0]
    count = 0
    for k in range(min(70, len(cands))):
        x0, y0, h, R = cands[int(rng.integers(0, len(cands)))][:4]
        d = math.hypot(x0, y0)
        a_c = math.atan2(x0, y0)
        r = d - R * rng.uniform(0.35, 0.6)
        zc = FLOOR_Z + (h - FLOOR_Z) * rng.uniform(0.22, 0.5)
        th = (h - FLOOR_Z) * rng.uniform(0.06, 0.13)
        span = (R * rng.uniform(1.0, 2.2)) / r
        a0 = a_c - span * rng.uniform(0.3, 0.7)
        nseg = 64
        verts, faces = [], []
        for i in range(nseg + 1):
            a = a0 + span * i / nseg
            for vv in (0.0, 1.0):
                verts.append((math.sin(a) * r, math.cos(a) * r, zc - th + 2 * th * vv))
        for i in range(nseg):
            b = i * 2
            faces.append((b, b + 2, b + 3, b + 1))
        me = bpy.data.meshes.new("BandCloud%d" % k)
        me.from_pydata(verts, [], faces)
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                uvl.data[li].uv = ((vi // 2) / nseg, float(vi % 2))
        ob = bpy.data.objects.new("BandCloud%d" % k, me)
        bpy.context.collection.objects.link(ob)
        ob.data.materials.append(mat)
        ob.visible_shadow = False
        count += 1
    print("banda: %d benzi de nor" % count)


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

    # Lumina de umplere din marea de nori: alb-rece, din partea OPUSA soarelui
    # (busola 315), aproape orizontala (lumina intoarsa de nor si de cer). Fara ea, uriasii
    # din contre-jour (spre SE, cu soarele in spate) ieseau gri-negri, mai
    # inchisi decat stancile cetoase din fata (lectia MV).
    fd = bpy.data.lights.new("BandFill", "SUN")
    fd.energy = FILL_STRENGTH
    fd.color = srgb(CLOUD)[:3]
    fd.angle = math.radians(10.0)
    fill = bpy.data.objects.new("BandFill", fd)
    bpy.context.collection.objects.link(fill)
    from mathutils import Vector
    fa = math.radians(FILL_AZ)
    to_fill = Vector((math.sin(fa), math.cos(fa), 0.12)).normalized()
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
        vs = [(x + dx * s, y + dy * s, 90 + dz * s) for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
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
rng = np.random.default_rng(15)
import random as _random
peaks = make_peaks(_random.Random(15))
setup_render()
plane("BandValley", FLOOR_Z + 2.0, valley_material())
plane("BandCloudSea", 0.0, cloud_sea_material())
build_land(peaks)
build_clouds(rng, peaks)
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
