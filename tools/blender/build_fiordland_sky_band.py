"""Banda de orizont a cerului Fiordland (Track16) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/fiordland_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime
(-7,5 .. +15), cu alfa: peretii fiordului care se continua in straturi tot mai
palide, crestele cu zapada din spate, firele de cascada si norii agatati de
pereti, apa neagra-verde a fiordului pana departe; cerul ramane TRANSPARENT,
fiindca gradientul si norii lui ii deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`). Banda e lipita de cer, deci sta la
infinit: nu intra in frustum, nu costa triunghiuri, nu o taie FAR_PLANE (380 m).

De ce altfel decat la Ha Long: acolo golful e deschis si turnurile stau risipite
pe mare. Fiordul e un CULOAR: ~200 m intre maluri, pereti din apa. Muntele real
e aproape (relieful jocului, inelele de 170-300 m), deci banda nu deschide un
orizont, ci DUCE FIORDUL MAI DEPARTE: un camp de inaltimi polar (nu obiecte
asezate) cu doua brate de apa sapate in el — fiordul principal spre sud, cu
gura spre mare la capat, si un brat inchis spre est — iar restul azimutului e
perete peste perete, fiecare plan mai palid. Inaltimea creste cu distanta ca
crestele sa stea in fereastra camerei de joc (vezi `THETA`).

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste apa, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "fiordland" (`sun_rotation_deg` (-30, 200, 0): soarele
    sta la NORD-nord-vest, 30 de grade sus — emisfera sudica), aceeasi culoare
    (0.92, 0.95, 1.0) si energie 1,55, acelasi ambient A8B8C0 la 0,45;
  * HAZE = `sky_horizon` din tema (C7D2D8): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii, deci marginea
    benzii nu se vede;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    mkdir D:/GameDev/.render_lock && \
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_sky_band.py [-- --test]
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
# Camera de joc sta la 10 m peste sosea, iar soseaua la 0..45 m peste nivelul
# marii (`sea_level_offset` -19,6): ochiul e la ~30-65 m peste apa. 40 e
# mijlocul; la kilometri distanta diferenta e sub un grad.
CAM_Z = 40.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "fiordland_horizon_band_test.png" if TEST else "fiordland_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB, ca in tema / in pista) ---------------------------------------
HAZE = "C7D2D8"          # = sky_horizon din tema: departarea intra in cer
MIST = "D3DBDF"          # norii agatati de pereti: un pic mai albi decat aerul
WATER = "2D3638"         # apa fiordului: (45,54,56), cum iese in joc (tema, water_dim)
GNEISS_LIT = "777C7D"    # gneis ud in lumina (MARBLE_GREY tras spre gri-negru)
GNEISS = "51575A"
GNEISS_WET = "30363A"    # dungile ude, verticale
# fag + muschi: verde-negru, dar VERDE — relieful jocului e iarba si padure
# saturata (ground_tint iese ~(58,74,44)), deci peretele pictat nu poate fi gri
FOREST = ["22351D", "2B4223", "355029", "2E4824", "1D2D19"]
SNOW = "F3F6F8"
SNOW_SHADE = "BCCAD4"    # zapada in umbra (ICE_TURQUOISE stins)
FALL = "E4EAEC"          # firele de cascada
SUN_COLOR = (0.92, 0.95, 1.0)
SUN_ENERGY = 1.55
AMBIENT = "A8B8C0"
AMBIENT_ENERGY = 0.45

# Perspectiva aeriana: 1 - exp(-(d-d0)/D). Fiordul e UD, deci aerul e mai gros
# decat la Ha Long (4200): planul de la 1 km iese deja spalat, cel de la 5 km
# aproape cer — „pereti tot mai palizi in straturi". Ceata jocului (120 -> 320,
# fog_max 0,85) spala relieful real cam la fel de tare pe ultima suta de metri.
HAZE_D0, HAZE_D = 260.0, 3000.0
HAZE_MAX = 0.86
SNOW_GLOW = 0.55
MIST_H, MIST_K = 30.0, 0.35               # ceata joasa pe apa: K * exp(-z/H)

# Unghiul crestei deasupra ochiului, dupa distanta (grade). Camera de joc tine
# orizontul in sfertul de sus: deasupra lui se vad ~5-6 grade. Crestele stau
# in fereastra asta; doar varfurile cu zapada din fund o depasesc putin, si dau
# scara.
THETA_R = np.array([420.0, 900.0, 2000.0, 4500.0, 9000.0, 16000.0])
THETA_DEG = np.array([2.5, 3.0, 4.0, 4.8, 5.4, 5.6])   # pentru nori (crestele: LAYERS)


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


# --- Bratele fiordului (polilinii in metri, Blender: x est, y nord) -------------
# Golful din joc e la SUD de pista (planul adnotat), deci fiordul se continua
# spre sud, serpuit, cu gura spre mare la capat (apa pana la orizont). Bratul
# de est e inchis: un culoar de apa care se pierde intre pereti.
ARMS = [
    # (puncte, semilatime la inceput, semilatime la capat)
    ([(0, 0), (80, -700), (-260, -1500), (-120, -2400), (-520, -3400),
      (-300, -4600), (-800, -6200), (-700, -9000), (-900, -16000)], 170.0, 520.0),
    ([(150, -150), (900, -380), (1700, -250), (2500, -700), (3300, -560)], 120.0, 160.0),
    ([(-150, 150), (-700, 650), (-1300, 800), (-1900, 1350)], 110.0, 90.0),
]


def dist_to_arm(px, py, pts, w0, w1):
    """Distanta pana la axa bratului minus semilatimea locala (negativ = in apa)."""
    best = np.full(px.shape, 1e9)
    seglen = [math.hypot(pts[k + 1][0] - pts[k][0], pts[k + 1][1] - pts[k][1])
              for k in range(len(pts) - 1)]
    total = sum(seglen)
    acc = 0.0
    for k in range(len(pts) - 1):
        ax, ay = pts[k]
        bx, by = pts[k + 1]
        dx, dy = bx - ax, by - ay
        L2 = dx * dx + dy * dy
        t = np.clip(((px - ax) * dx + (py - ay) * dy) / L2, 0.0, 1.0)
        qx, qy = ax + t * dx, ay + t * dy
        d = np.hypot(px - qx, py - qy)
        s = (acc + t * seglen[k]) / total
        w = w0 + (w1 - w0) * s
        best = np.minimum(best, d - w)
        acc += seglen[k]
    return best


# --- Scena -----------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node, alpha_socket=None):
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
    keep_air = x                                              # 1 - fac_aer
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / MIST_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")                        # ceata doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 500.0
    ramp.inputs["From Max"].default_value = 1500.0
    mist = math_node("MULTIPLY", z, ramp.outputs["Result"])
    mist = math_node("MULTIPLY", mist, vb=MIST_K)
    keep_mist = math_node("SUBTRACT", va=1.0, b=mist)
    # plafon: si planul de la 10 km pastreaza ceva din el (zapada se vede ca
    # zapada, nu ca aer), altfel crestele din fund se topesc complet
    keep_air = math_node("MAXIMUM", keep_air, vb=1.0 - HAZE_MAX)
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
    """Culoarea e in vertex color (padure / gneis / zapada / cascade, calculate
    in `build_land`); materialul doar o lumineaza si o spala in aer."""
    mat, nt, out = new_material("BandLand")
    n, L = nt.nodes, nt.links
    at = n.new("ShaderNodeAttribute")
    at.attribute_name = "Col"
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.8
    bsdf.inputs["Specular IOR Level"].default_value = 0.2
    L.new(at.outputs["Color"], bsdf.inputs["Base Color"])
    # Zapada (alfa din atributul Col) primeste si o emisie: pe vreme acoperita
    # zapada din umbra ramane alba de la cerul difuz, iar la 3-5 km, in aerul
    # palid al fiordului, altfel s-ar topi in cer. Pe pista zapada (Mitre
    # Peak, crestele de fundal) e tot alb-curat.
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
    haze_wrap(nt, add.outputs[0], out)
    return mat


def water_material():
    """Apa e NEILUMINATA (ca marea de la Ha Long): culoarea ei din joc, spalata
    apoi de acelasi aer ca peretii. Peste ea, o oglinda slaba: fiordul linistit
    reflecta peretii, iar reflexia e ce leaga apa de munte."""
    mat, nt, out = new_material("BandWater")
    n, L = nt.nodes, nt.links
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(WATER)
    gl = n.new("ShaderNodeBsdfGlossy")
    gl.inputs["Roughness"].default_value = 0.08
    gl.inputs["Color"].default_value = (0.32, 0.34, 0.35, 1.0)
    add = n.new("ShaderNodeAddShader")
    L.new(em.outputs[0], add.inputs[0])
    L.new(gl.outputs[0], add.inputs[1])
    haze_wrap(nt, add.outputs[0], out)
    return mat


def cloud_material():
    mat, nt, out = new_material("BandCloud")
    n, L = nt.nodes, nt.links
    uv = n.new("ShaderNodeTexCoord")
    sepuv = n.new("ShaderNodeSeparateXYZ")
    L.new(uv.outputs["UV"], sepuv.inputs[0])
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0, 1.0, 2.2)        # trase pe orizontala
    L.new(uv.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 0.02
    nz.inputs["Detail"].default_value = 8.0
    nz.inputs["Roughness"].default_value = 0.68
    L.new(mp.outputs[0], nz.inputs["Vector"])
    cr = n.new("ShaderNodeMapRange")
    cr.inputs["From Min"].default_value = 0.46
    cr.inputs["From Max"].default_value = 0.66
    L.new(nz.outputs["Fac"], cr.inputs["Value"])
    # profil vertical: moale sus si jos (v 0..1); capete moi pe u
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
    pv = prof(sepuv.outputs[1], 0.45, 0.55)
    pu = prof(sepuv.outputs[0], 0.18, 0.82)
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
    a3.inputs[1].default_value = 0.95
    L.new(a2.outputs[0], a3.inputs[0])
    # norul e luminat (difuz, sun-ul il face mai alb pe partea dinspre soare)
    # plus o emisie mica, ca in umbra sa nu iasa gri murdar
    df = n.new("ShaderNodeBsdfDiffuse")
    df.inputs["Color"].default_value = srgb(MIST)
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(MIST)
    em.inputs["Strength"].default_value = 0.35
    add = n.new("ShaderNodeAddShader")
    L.new(df.outputs[0], add.inputs[0])
    L.new(em.outputs[0], add.inputs[1])
    haze_wrap(nt, add.outputs[0], out, alpha_socket=a3.outputs[0])
    mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else None
    return mat


# --- Relieful: camp de inaltimi polar ------------------------------------------

N_AZ = 1024 if TEST else 4096
N_R = 120 if TEST else 260
R0, R1 = 600.0, 16000.0


# Planurile de munte: (distanta crestei, unghiul mediu al crestei peste ochi).
# Un camp de inaltimi care creste monoton cu distanta e o PALNIE: din centru se
# vede o singura panta continua, fara straturi. Aici fiecare plan e o creasta
# cu vale in spate, cu sei si goluri pe azimut prin care se vede planul urmator,
# fiecare mai palid (perspectiva aeriana) si putin mai sus pe cer.
#
# Primul plan sta la ~0,9 km, nu mai aproape: apa jocului se termina la
# FAR_PLANE (380 m), adica la -4,5..-9 grade sub orizont dupa cat de sus e
# camera. Pana la piciorul primului perete (-3 grade) banda e deci APA, si apa
# jocului intra in apa pictata; un perete mai apropiat ar fi stat cu talpa
# taiata de marginea apei reale.
LAYERS = [
    (900.0, 3.3), (1300.0, 3.7), (2000.0, 4.1), (3100.0, 4.5),
    (4800.0, 4.9), (7500.0, 5.2), (11500.0, 5.4),
]


def heights(px, py, r):
    z = np.full(px.shape, -40.0)
    hm = np.ones(px.shape)
    kid = np.zeros(px.shape, dtype=np.int32)
    for k, (dk, th) in enumerate(LAYERS):
        hc = CAM_Z + dk * math.tan(math.radians(th))
        # creasta pe azimut: masive (zgomot lent) + varfuri zimtate (ridged);
        # scara proportionala cu distanta, ca unghiul aparent sa fie acelasi
        big = fbm(px, py, dk * 0.45, 100 + k, octaves=3)
        jag = fbm(px, py, dk * 0.08, 200 + k, octaves=5, ridged=True)
        crest = hc * (0.35 + 0.65 * big + 0.55 * jag)
        # golurile planului (nu primul): acolo se vede planul din spate
        if k > 0:
            gap = smoothstep(0.38, 0.30, fbm(px, py, dk * 0.6, 300 + k, octaves=2))
            crest = crest * (1.0 - 0.75 * gap)
        # profilul pe raza: fata spre camera abrupta, spatele mai lin
        wf = dk * 0.16
        wb = dk * 0.30
        t = np.where(r < dk, 1.0 - (dk - r) / wf, 1.0 - (r - dk) / wb)
        t = np.clip(t, 0.0, 1.0)
        prof = np.power(t, 0.8)
        zk = -40.0 + (crest + 40.0) * prof
        better = zk > z
        hm = np.where(better, crest, hm)
        kid = np.where(better, k, kid)
        z = np.maximum(z, zk)
    # bratele de apa: taie toate planurile; peretii lor sunt abrupti
    lat = np.full(px.shape, 1e9)
    for pts, w0, w1 in ARMS:
        lat = np.minimum(lat, dist_to_arm(px, py, pts, w0, w1))
    slope_w = np.maximum(40.0, 0.35 * hm)
    c = np.power(smoothstep(0.0, slope_w, lat), 0.6)
    # inelul interior coboara in apa: altfel marginea campului ar fi o streasina
    # sub care se vede dosul reliefului
    c = c * smoothstep(R0, R0 + 90.0, r)
    z = -25.0 + (z + 25.0) * c
    # contraforturi si ravene pe fete (zgomot fin)
    z += (fbm(px, py, 140.0, 29, octaves=3) - 0.5) * 0.16 * hm * c
    return z, hm, lat, kid


def build_land():
    az = np.linspace(0.0, math.tau, N_AZ, endpoint=False)
    rr = R0 * np.power(R1 / R0, np.linspace(0.0, 1.0, N_R))
    A, Rg = np.meshgrid(az, rr)                     # (N_R, N_AZ)
    px = np.sin(A) * Rg
    py = np.cos(A) * Rg
    z, hm, lat, kid = heights(px, py, Rg)
    nverts = N_R * N_AZ
    co = np.stack([px, py, z], axis=-1).reshape(-1, 3)
    # fete: (i, j) -> (i, j+1) -> (i+1, j+1) -> (i+1, j), cu inchidere pe azimut
    ii, jj = np.meshgrid(np.arange(N_R - 1), np.arange(N_AZ), indexing="ij")
    j1 = (jj + 1) % N_AZ
    v0 = ii * N_AZ + jj
    v1 = ii * N_AZ + j1
    v2 = (ii + 1) * N_AZ + j1
    v3 = (ii + 1) * N_AZ + jj
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)   # normala in sus (azimut = sens orar)
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

    # --- culoarea pe varf (liniar) ---
    def lin(hx):
        return np.array(srgb(hx)[:3])

    hfrac = np.clip(z / np.maximum(hm, 1.0), 0.0, 1.2)
    # gneis: dungi ude VERTICALE = zgomot pe azimut, aproape constant pe inaltime
    # in coordonate de LUME (pas ~9 m): dungile se strang cu distanta ca pe un
    # perete real; pe azimut ar fi iesit acelasi „cod de bare" pe toate planurile
    streak = vnoise(px + 0.37 * py, py - 0.37 * px + z * 0.004, 9.0, 41)
    streak = smoothstep(0.55, 0.85, streak)
    streak = streak * smoothstep(0.35, 0.65, fbm(px, py + z * 0.3, 260.0, 43, octaves=2))
    lit = smoothstep(0.2, 0.7, nz)
    rock = (lin(GNEISS)[None, None, :] * (1 - lit)[..., None]
            + lin(GNEISS_LIT)[None, None, :] * lit[..., None])
    rock = rock * (1 - streak * 0.5)[..., None] + lin(GNEISS_WET) * (streak * 0.5)[..., None]
    # padurea pe treimea de jos (urca mai sus pe fetele mai putin abrupte si in ravene)
    fn = fbm(px, py, 220.0, 53, octaves=3)
    # padurea urca pana la ~jumatate din perete (mai sus pe fetele mai culcate),
    # cu limita zdrentuita; deasupra, gneis gol si zapada
    rag = fbm(px, py, 45.0, 57, octaves=3)
    forest_line = 0.40 + 0.18 * fn + 0.16 * smoothstep(0.30, 0.75, nz) + 0.12 * (rag - 0.5)
    forest = smoothstep(forest_line + 0.03, forest_line - 0.03, hfrac)
    forest *= smoothstep(-0.25, 0.10, nz) * 0.3 + 0.7
    fcol_i = np.clip((fbm(px, py, 60.0, 71, octaves=2) * len(FOREST)).astype(int), 0, len(FOREST) - 1)
    fpal = np.array([lin(c) for c in FOREST])
    fcol = fpal[fcol_i]
    col = rock * (1 - forest)[..., None] + fcol * forest[..., None]
    # zapada: sus pe masivele din fund, pe ce priveste in sus; in umbra = albastrui
    # Pe CALOTE, relativ la creasta fiecarui plan, nu peste o cota fixa: cu
    # o cota fixa planurile din fund (sute de metri) ieseau albe de tot, o
    # fasie de vata lipita de nori. Primele doua planuri (peretii fiordului)
    # n-au zapada; de la al treilea in spate calota coboara tot mai mult.
    cap = np.choose(np.clip(kid, 0, 6), [9.0, 9.0, 0.80, 0.74, 0.68, 0.64, 0.62])
    cap = cap + 0.10 * (fbm(px, py, 120.0, 83, octaves=3) - 0.5)
    # pe azimut: lanturi intregi fara calota (gneis gol, in nori) intre cele
    # albe — altfel fundul benzii era aceeasi fasie de vata pe 360 de grade
    cap = cap + 0.45 * smoothstep(0.45, 0.62, vnoise(np.arctan2(px, py) * 4.0, kid * 3.1, 1.0, 89))
    snow = smoothstep(cap, cap + 0.06, hfrac) * smoothstep(-0.1, 0.25, nz)
    # in ravene coboara, pe fetele abrupte ramane doar in pete
    snow *= 0.45 + 0.55 * smoothstep(0.35, 0.6, fbm(px, py, 50.0, 87, octaves=3))
    scol = lin(SNOW)[None, None, :] * lit[..., None] + lin(SNOW_SHADE)[None, None, :] * (1 - lit)[..., None]
    col = col * (1 - snow)[..., None] + scol * snow[..., None]
    print("banda: zapada pe %.1f%% din varfuri (z>190: %.1f%%, nz med %.2f)" % (
        100.0 * (snow > 0.5).mean(), 100.0 * (z > 190).mean(), float(np.median(nz))))
    # firele de cascada: o coloana de azimut, pe fete abrupte, de sub creasta pana jos
    rngc = np.random.default_rng(7)
    fall = np.zeros_like(z)
    cols_fall = rngc.choice(N_AZ, size=150 if not TEST else 30, replace=False)
    for jc in cols_fall:
        r_lo = rngc.uniform(R0 + 60.0, 2400.0)
        r_hi = r_lo * rngc.uniform(1.05, 1.35)
        top = rngc.uniform(0.6, 0.92)
        sel_r = (rr >= r_lo) & (rr <= r_hi)
        for dj, k in ((0, 1.0), (1, 0.45)):
            j = (jc + dj) % N_AZ
            steep = smoothstep(0.85, 0.55, nz[:, j])
            band = smoothstep(top, top - 0.08, hfrac[:, j]) * smoothstep(0.02, 0.12, hfrac[:, j])
            fall[:, j] = np.maximum(fall[:, j], sel_r * steep * band * k)
    col = col * (1 - fall)[..., None] + lin(FALL) * fall[..., None]

    glow = np.maximum(snow, 0.6 * fall)          # cascadele sunt spuma: tot albe in umbra
    rgba = np.concatenate([col.reshape(-1, 3), glow.reshape(-1, 1)], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    ob = bpy.data.objects.new("BandLand", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(land_material())
    print("banda: relief %d x %d varfuri, %d fete" % (N_R, N_AZ, nf))
    return A, Rg, z, hm


def build_water():
    me = bpy.data.meshes.new("BandWater")
    s = 40000.0
    me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0)], [], [(0, 1, 2, 3)])
    ob = bpy.data.objects.new("BandWater", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(water_material())


def build_clouds(rng):
    """Benzi de nor JOS, agatate de pereti: fasii cilindrice la raza peretelui,
    la 30-60% din inaltimea lui (brief §5.4 `cloud_bank`)."""
    mat = cloud_material()
    count = 0
    for k in range(44):
        # pe fata unui plan de munte (putin in fata crestei), la mijlocul peretelui
        dk, thk = LAYERS[int(rng.integers(0, 4))]
        r = dk * rng.uniform(0.74, 0.84)
        hb = CAM_Z + dk * math.tan(math.radians(thk))
        zc = hb * rng.uniform(0.35, 0.70)
        th = hb * rng.uniform(0.10, 0.20)
        a0 = rng.uniform(0.0, math.tau)
        span = rng.uniform(math.radians(7.0), math.radians(26.0))
        nseg = 96
        verts, faces, uvs = [], [], []
        for i in range(nseg + 1):
            u = i / nseg
            a = a0 + span * u
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
    rx, ry = math.radians(-30.0), math.radians(200.0)
    x, y, z = 0.0, -math.sin(rx), math.cos(rx)
    gx = x * math.cos(ry) + z * math.sin(ry)
    gz = -x * math.sin(ry) + z * math.cos(ry)
    from mathutils import Vector
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
    cd.clip_end = 60000.0
    cam = bpy.data.objects.new("BandCam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, 0.0, CAM_Z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # priveste spre +Y (nord)
    sc.camera = cam

    ld = bpy.data.lights.new("BandSun", "SUN")
    ld.energy = SUN_ENERGY
    ld.color = SUN_COLOR
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
rng = np.random.default_rng(16)
setup_render()
build_water()
build_land()
build_clouds(rng)
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
