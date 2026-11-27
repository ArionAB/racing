"""Banda de orizont a cerului Chongqing (Track12) NOAPTEA — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/chongqing_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa:
megalopolisul de pe dealuri de la confluenta Yangtze cu Jialing — paduri de
turnuri pe straturi de deal, cu ferestre aprinse in benzi si ciorchini (calde si
reci), neon pe acoperisuri, poduri luminate peste rauri, raurile negre cu dare de
lumina, dealurile impadurite negre-albastrui departe si smogul luminat de jos.
Cerul ramane TRANSPARENT (gradientul il deseneaza shaderul din joc,
`scenes/tracks/sky_band.gdshader`), cu o singura exceptie voita: pacla calda de
deasupra orasului (vezi `build_glow`), cu alfa partial, care se aseaza peste
gradientul temei — orasul isi lumineaza smogul de jos, mai tare unde e mai dens.

De ce randare si nu GLB-uri: ce sta la 0,5-12 km nu are paralaxa pe un circuit de
900 m, iar jocul taie oricum la ChaseCamera.FAR_PLANE (380 m) si la ceata (250 m).
Randarea isi permite ce nu-si permite jocul: mii de turnuri cu ferestre emisive,
reflexiile lor in rau si perspectiva aeriana pe fiecare plan. Nota din tema
(„FARA oras pictat in cer", PR #365) e despre un strat de cer care incepea la
1,2 grade si era acoperit de geometrie; aici planul 0 (`NEAR`) urca 3-10 grade,
masurat pe camera de joc.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la CAM_Z peste apa, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * fara soare: „soarele" temei e o luna rece aproape verticala
    (`sun_rotation_deg` (-78, 200, 0), `sun_color` (0.78, 0.84, 1.0), 0,35),
    ambientul 66667A la 0,40; lumina vine din ferestre si neon (emisive);
  * HAZE = `sky_horizon` din tema (0.17, 0.18, 0.24): departarea se topeste exact
    in culoarea pe care o deseneaza cerul din joc in spatele benzii;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_chongqing_sky_band.py [-- --test]
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
# `--crop=u0,u1`: randare la rezolutia finala doar pe felia u0..u1 (iteratie rapida)
CROP = None
for _a in ARGS:
    if _a.startswith("--crop="):
        CROP = tuple(float(v) for v in _a[7:].split(","))

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
CAM_Z = 44.0
SAMPLES = 24 if TEST else 160
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "chongqing_horizon_band_test.png" if TEST else "chongqing_horizon_band.png")
if CROP:
    OUT = os.path.join(PROJECT, "assets", "textures", "sky", "chongqing_horizon_band_crop.png")


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


# --- Paleta (sRGB) ----------------------------------------------------------------
HAZE = "2B2E3D"          # = sky_horizon din tema (0.17, 0.18, 0.24)
SMOG = "4E4552"          # smogul jos, luminat de oras de dedesubt (cald-violet)
GLOW = "6B5560"          # pacla de deasupra orasului (build_glow)
FACADE = ["3A3936", "34363A", "403E3A", "2E3136", "3C3A3F"]   # beton de noapte
WIN_WARM = "FFC27A"      # ferestre calde (slotul GLOW al kitului)
WIN_PALE = "FFE2B0"
WIN_COOL = "BFD8FF"      # birouri, LED rece
NEON = ["FF3D8B", "35E0FF", "FF5A3C", "6A7BFF", "B44DFF", "3DFFB0"]
AVIATION = "FF2A1A"
HILL = ["141A1F", "182026", "1B2328", "12171C"]                # padure noaptea
WATER = "0C1116"
BRIDGE_LAMP = "FFB060"   # sodiu
BRIDGE_LED = "9FD0FF"
MOON_COLOR = "C7D6FF"    # Color(0.78, 0.84, 1.0) din tema
MOON_STRENGTH = math.pi * 0.35
AMBIENT = "66667A"
AMBIENT_ENERGY = 0.40
SUN_ROT = (-78.0, 200.0)                  # sun_rotation_deg (x, y) din tema

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), plafonata la HAZE_MAX.
HAZE_D0, HAZE_D, HAZE_F0, HAZE_MAX = 380.0, 2200.0, 0.18, 0.95
SMOG_H, SMOG_K = 90.0, 0.60               # smogul jos: K * exp(-z/H), departe
EMIT_KEEP = 0.85                          # cat din lumina ferestrelor strabate aerul in plus


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


def fbm(x, y, scale, seed, octaves=5):
    tot, amp, norm = 0.0, 1.0, 0.0
    for o in range(octaves):
        tot = tot + amp * vnoise(x, y, scale / (2.0 ** o), seed + 17 * o)
        norm += amp
        amp *= 0.5
    return tot / norm


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def compass(x, y):
    """Busola (grade, 0 = N, 90 = E) a unui punct Blender (x est, y nord)."""
    return np.degrees(np.arctan2(x, y)) % 360.0


def az_dist(a, b):
    d = np.abs((a - b + 180.0) % 360.0 - 180.0)
    return d


# --- Geografia (busola din origine; Blender x = est, y = nord) ---------------------
#
# Pista sta pe varful peninsulei, la confluenta. In joc (custom_lagoon,
# far_shore): apa la V, SV, S si SE pana la ~300 m, malul opus (o fasie de 45 m cu
# inelul de turnuri 3D turn41..57, la 350-420 m) pe V-S-SE; spre N si E uscatul
# pistei, cu orasul pe dealuri. In banda:
#   * raurile continua dincolo de malul opus doar pe culoare: Jialing in amonte
#     spre VNV, Yangtze in amonte spre SSV si in aval spre ESE; acolo privirea
#     merge pe apa pana departe, cu poduri luminate de-a curmezisul;
#   * in rest orasul urca pe dealuri in trepte (Nan'an peste Yangtze, Jiangbei
#     peste Jialing, Yuzhong in spate), tot mai rar spre muntii impaduriti:
#     Nanshan la SE (3-6 km, 450 m), Zhongliang la V (9-14 km), Tongluo la E.
#
# Fiecare rau: (busola, latime unghiulara la 1 km in grade, cat se ingusteaza).
RIVERS = [
    ("Jialing", 280.0, 26.0),
    ("Yangtze_amonte", 200.0, 24.0),
    ("Yangtze_aval", 100.0, 26.0),
]
SHORE_R0 = 470.0          # malul de dincolo (dupa fasia 3D a jocului)

# Munti: (busola, distanta, raza, inaltime, nume)
MOUNTAINS = [
    (138.0, 4200.0, 2600.0, 430.0, "Nanshan"),
    (168.0, 5200.0, 2200.0, 380.0, "Nanshan_sud"),
    (262.0, 11000.0, 4500.0, 620.0, "Zhongliang"),
    (300.0, 13000.0, 3800.0, 560.0, "Zhongliang_nord"),
    (70.0, 12000.0, 4200.0, 650.0, "Tongluo"),
    (25.0, 9000.0, 3200.0, 420.0, "Tieshanping"),
    (215.0, 8500.0, 3000.0, 400.0, "Huaying_sud"),
]


def river_mask(px, py):
    """1 pe apa, 0 pe uscat (cu malul moale pe ~60 m), din busola si distanta."""
    a = compass(px, py)
    r = np.hypot(px, py)
    m = np.zeros_like(px)
    for _, az, wdeg in RIVERS:
        # latimea fizica: ~ wdeg la 1 km, apoi raul se vede tot mai ingust
        half_m = math.radians(wdeg * 0.5) * 1000.0
        half_m = half_m * (0.75 + 0.25 * np.clip(r / 3000.0, 0.0, 2.5))
        meander = (fbm(r * 0.0, r, 2600.0, 31 + int(az)) - 0.5) * 300.0
        lat = np.radians(az_dist(a, az)) * r            # distanta laterala, metri
        side = np.sign(((a - az + 180.0) % 360.0) - 180.0)
        lat2 = np.abs(lat * side - meander * smoothstep(400.0, 2000.0, r))
        m = np.maximum(m, 1.0 - smoothstep(half_m - 50.0, half_m + 30.0, lat2))
    # aproape de origine (sub malul de dincolo) e apa doar pe V-S-SE (lagunea jocului)
    a_ok = ((a > 105.0) & (a < 295.0)).astype(float)
    near = 1.0 - smoothstep(SHORE_R0 - 40.0, SHORE_R0 + 40.0, r)
    m = np.maximum(m, near * a_ok)
    return np.clip(m, 0.0, 1.0)


def land_height(px, py):
    """Dealurile orasului: trepte de terasa de la mal in sus, plus muntii."""
    r = np.hypot(px, py)
    base = 18.0 + 120.0 * smoothstep(500.0, 5000.0, r)
    hills = (fbm(px, py, 1800.0, 7) - 0.45) * 220.0 * smoothstep(400.0, 2500.0, r)
    small = (fbm(px, py, 420.0, 11) - 0.5) * 50.0
    z = base + np.maximum(hills, -60.0) + small
    for az, d, rad, hh, _ in MOUNTAINS:
        cx, cy = math.sin(math.radians(az)) * d, math.cos(math.radians(az)) * d
        q = np.hypot(px - cx, py - cy) / rad
        ridge = fbm(px, py, rad * 0.45, 3 + int(az)) * 0.6 + 0.4
        z = np.maximum(z, hh * np.exp(-q * q * 1.6) * ridge + 20.0)
    return z


# --- Mesh din numpy ---------------------------------------------------------------

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
    quads = np.stack([v0, v1, v2, v3], axis=-1).reshape(-1)
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


def quads_mesh(name, verts, attrs):
    """Fete patrate independente (4 varfuri fiecare): `verts` (N*4, 3), atribute
    pe varf (N*4,) sau (N*4, 3)."""
    nv = verts.shape[0]
    nf = nv // 4
    me = bpy.data.meshes.new(name)
    me.vertices.add(nv)
    me.vertices.foreach_set("co", verts.astype(np.float32).ravel())
    me.loops.add(nv)
    me.loops.foreach_set("vertex_index", np.arange(nv, dtype=np.int32))
    me.polygons.add(nf)
    me.polygons.foreach_set("loop_start", (np.arange(nf) * 4).astype(np.int32))
    me.polygons.foreach_set("loop_total", np.full(nf, 4, dtype=np.int32))
    me.update(calc_edges=True)
    for key, val in attrs.items():
        if val.ndim == 1:
            at = me.attributes.new(key, "FLOAT", "POINT")
            at.data.foreach_set("value", val.astype(np.float32))
        else:
            at = me.attributes.new(key, "FLOAT_VECTOR", "POINT")
            at.data.foreach_set("vector", val.astype(np.float32).ravel())
    me.validate()
    return me


def link(name, me, mat):
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    return ob


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


class NB:
    """Ajutor mic pentru noduri de matematica."""

    def __init__(self, nt):
        self.n, self.L = nt.nodes, nt.links

    def m(self, op, a=None, b=None, va=None, vb=None, clamp=False):
        nd = self.n.new("ShaderNodeMath")
        nd.operation = op
        nd.use_clamp = clamp
        if a is not None:
            self.L.new(a, nd.inputs[0])
        elif va is not None:
            nd.inputs[0].default_value = va
        if b is not None:
            self.L.new(b, nd.inputs[1])
        elif vb is not None:
            nd.inputs[1].default_value = vb
        return nd.outputs[0]

    def attr(self, name):
        a = self.n.new("ShaderNodeAttribute")
        a.attribute_name = name
        return a

    def white(self, *vals):
        """Zgomot alb 3D pe (a, b, c) -> [0, 1)."""
        cmb = self.n.new("ShaderNodeCombineXYZ")
        for i, v in enumerate(vals):
            if isinstance(v, (int, float)):
                cmb.inputs[i].default_value = v
            else:
                self.L.new(v, cmb.inputs[i])
        wn = self.n.new("ShaderNodeTexWhiteNoise")
        wn.noise_dimensions = "3D"
        self.L.new(cmb.outputs[0], wn.inputs["Vector"])
        return wn.outputs["Value"]

    def mix_rgb(self, fac, a, b):
        mx = self.n.new("ShaderNodeMix")
        mx.data_type = "RGBA"
        self.L.new(fac, mx.inputs[0])
        for sock, v in ((6, a), (7, b)):
            if isinstance(v, tuple):
                mx.inputs[sock].default_value = v
            else:
                self.L.new(v, mx.inputs[sock])
        return mx.outputs[2]


def haze_wrap(nt, surface_socket, out_node, emit_socket=None, haze_k=1.0, d0=None):
    """surface -> amestec cu HAZE dupa distanta si cu SMOG (aerul jos, luminat de
    oras) dupa inaltime. Lumina ferestrelor (`emit_socket`) se adauga DUPA aer cu
    o ceata mai slaba: un punct aprins strabate pacla mai bine decat un perete
    intunecat (noaptea departarea e neagra, dar luminile tot se vad)."""
    b = NB(nt)
    n, L = b.n, b.L
    cam = n.new("ShaderNodeCameraData")
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Position"], sep.inputs[0])
    d = cam.outputs["View Distance"]
    x = b.m("SUBTRACT", d, vb=HAZE_D0 if d0 is None else d0)
    x = b.m("MAXIMUM", x, vb=0.0)
    x = b.m("MULTIPLY", x, vb=-haze_k / HAZE_D)
    x = b.m("EXPONENT", x)
    keep_air = b.m("MULTIPLY", x, vb=1.0 - HAZE_F0)
    keep_air = b.m("MAXIMUM", keep_air, vb=1.0 - HAZE_MAX)
    z = b.m("MAXIMUM", sep.outputs[2], vb=0.0)
    z = b.m("MULTIPLY", z, vb=-1.0 / SMOG_H)
    z = b.m("EXPONENT", z)
    rmp = n.new("ShaderNodeMapRange")
    L.new(d, rmp.inputs["Value"])
    rmp.inputs["From Min"].default_value = 500.0
    rmp.inputs["From Max"].default_value = 3000.0
    smog = b.m("MULTIPLY", z, rmp.outputs["Result"])
    smog = b.m("MULTIPLY", smog, vb=SMOG_K)
    keep_smog = b.m("SUBTRACT", va=1.0, b=smog)
    keep = b.m("MULTIPLY", keep_air, keep_smog)
    fac = b.m("SUBTRACT", va=1.0, b=keep)
    cmix = b.mix_rgb(smog, srgb(HAZE), srgb(SMOG))
    em = n.new("ShaderNodeEmission")
    L.new(cmix, em.inputs["Color"])
    em.inputs["Strength"].default_value = 1.0
    mix = n.new("ShaderNodeMixShader")
    L.new(fac, mix.inputs[0])
    L.new(surface_socket, mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    final = mix.outputs[0]
    if emit_socket is not None:
        # lumina proprie: atenuata cu keep^EMIT_KEEP (mai putin decat suprafata)
        ke = b.m("POWER", keep, vb=EMIT_KEEP)
        ems = n.new("ShaderNodeEmission")
        L.new(emit_socket, ems.inputs["Color"])
        L.new(ke, ems.inputs["Strength"])
        add = n.new("ShaderNodeAddShader")
        L.new(final, add.inputs[0])
        L.new(ems.outputs[0], add.inputs[1])
        final = add.outputs[0]
    L.new(final, out_node.inputs["Surface"])


def facade_material():
    """Turnurile: beton de noapte + ferestre emisive dupa atributele de fata.

    Atribute pe varf: `fu` (metri de-a lungul fatadei), `fz` (metri de la baza
    turnului), `tid` (aleator per turn), `roof` (1 pe acoperis), `lit` (cat de
    aprins e turnul, 0..1), `cool` (probabilitatea de ferestre reci).
    La 8192 px un pixel e 0,044 grade: o fereastra (1,6 x 3,2 m) e 2 px la 0,6 km
    si sub un pixel dincolo de 2 km — de aceea aprinderea e pe CIORCHINI (benzi
    de 2-4 etaje x 3-6 ferestre), nu fereastra cu fereastra: de departe raman
    benzi si pete calde, nu zgomot."""
    mat, nt, out = new_material("BandFacade")
    b = NB(nt)
    n, L = b.n, b.L
    fu = b.attr("fu").outputs["Fac"]
    fz = b.attr("fz").outputs["Fac"]
    tid = b.attr("tid").outputs["Fac"]
    roof = b.attr("roof").outputs["Fac"]
    litk = b.attr("lit").outputs["Fac"]
    coolk = b.attr("cool").outputs["Fac"]
    WW, FH = 1.7, 3.3
    col = b.m("FLOOR", b.m("DIVIDE", fu, vb=WW))
    row = b.m("FLOOR", b.m("DIVIDE", fz, vb=FH))
    cu = b.m("FRACT", b.m("DIVIDE", fu, vb=WW))
    cv = b.m("FRACT", b.m("DIVIDE", fz, vb=FH))
    # forma ferestrei: 70% din latime, 55% din inaltime
    sx = b.m("MULTIPLY", b.m("GREATER_THAN", cu, vb=0.15), b.m("LESS_THAN", cu, vb=0.85))
    sy = b.m("MULTIPLY", b.m("GREATER_THAN", cv, vb=0.25), b.m("LESS_THAN", cv, vb=0.80))
    shape = b.m("MULTIPLY", sx, sy)
    # ciorchine: 5 ferestre x 3 etaje
    ccol = b.m("FLOOR", b.m("DIVIDE", col, vb=5.0))
    crow = b.m("FLOOR", b.m("DIVIDE", row, vb=3.0))
    tseed = b.m("MULTIPLY", tid, vb=977.0)
    rc = b.white(ccol, crow, tseed)
    rw = b.white(col, row, b.m("ADD", tseed, vb=13.0))
    # pragul ciorchinelui scade cu cat turnul e mai aprins
    thr_c = b.m("SUBTRACT", va=0.96, b=b.m("MULTIPLY", litk, vb=0.32))
    on_c = b.m("GREATER_THAN", rc, thr_c)
    on_w = b.m("GREATER_THAN", rw, vb=0.30)
    # cateva ferestre izolate si in afara ciorchinilor
    lone = b.m("GREATER_THAN", rw, vb=0.982)
    on = b.m("MAXIMUM", b.m("MULTIPLY", on_c, on_w), lone)
    on = b.m("MULTIPLY", on, shape)
    on = b.m("MULTIPLY", on, b.m("SUBTRACT", va=1.0, b=roof))
    # parterul (primele 2 etaje) mai des aprins: magazine
    shop = b.m("LESS_THAN", fz, vb=7.0)
    shop = b.m("MULTIPLY", shop, b.m("GREATER_THAN", b.white(tseed, 3.0, 5.0), vb=0.6))
    shop = b.m("MULTIPLY", shop, b.m("GREATER_THAN", rc, vb=0.4))
    on = b.m("MAXIMUM", on, b.m("MULTIPLY", b.m("MULTIPLY", shop, sx),
                                      b.m("SUBTRACT", va=1.0, b=roof)))
    # culoarea: per ciorchine, cald / palid / rece
    rcol = b.white(ccol, crow, b.m("ADD", tseed, vb=71.0))
    is_cool = b.m("LESS_THAN", rcol, coolk)
    warm = b.mix_rgb(b.white(col, row, b.m("ADD", tseed, vb=5.0)), srgb(WIN_WARM), srgb(WIN_PALE))
    wcol = b.mix_rgb(is_cool, warm, srgb(WIN_COOL))
    # luminozitatea variaza putin pe fereastra
    var = b.m("ADD", b.m("MULTIPLY", rw, vb=0.6), vb=0.7)
    strength = b.m("MULTIPLY", b.m("MULTIPLY", on, var), vb=1.5)
    emc = n.new("ShaderNodeVectorMath")
    emc.operation = "SCALE"
    L.new(wcol, emc.inputs[0])
    L.new(strength, emc.inputs["Scale"])
    # betonul: tenta per turn
    cr = n.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    els[0].position, els[0].color = 0.0, srgb(FACADE[0])
    els[1].position, els[1].color = 1.0, srgb(FACADE[4])
    for i, c in enumerate(FACADE[1:4]):
        e = els.new(0.25 + 0.25 * i)
        e.color = srgb(c)
    L.new(tid, cr.inputs["Fac"])
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.7
    bsdf.inputs["Specular IOR Level"].default_value = 0.2
    L.new(cr.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out, emit_socket=emc.outputs[0])
    return mat


def emit_material(name, hexcol, strength):
    """Neon, LED, lampi: emisie pura (culoarea in atributul `ecol` daca exista)."""
    mat, nt, out = new_material(name)
    b = NB(nt)
    n, L = b.n, b.L
    ec = b.attr("ecol")
    k = b.attr("ek").outputs["Fac"]
    emc = n.new("ShaderNodeVectorMath")
    emc.operation = "SCALE"
    if hexcol is None:
        L.new(ec.outputs["Vector"], emc.inputs[0])
    else:
        emc.inputs[0].default_value = srgb(hexcol)[:3]
    L.new(b.m("MULTIPLY", k, vb=strength), emc.inputs["Scale"])
    dark = n.new("ShaderNodeBsdfDiffuse")
    dark.inputs["Color"].default_value = (0.01, 0.01, 0.012, 1.0)
    haze_wrap(nt, dark.outputs[0], out, emit_socket=emc.outputs[0])
    return mat


def hill_material():
    mat, nt, out = new_material("BandHill")
    b = NB(nt)
    n, L = b.n, b.L
    at = b.attr("Col")
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    bsdf.inputs["Specular IOR Level"].default_value = 0.05
    L.new(at.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def water_material():
    """Raul noaptea: aproape negru, lucios, cu valuri mici — reflecta chiar
    ferestrele si podurile din banda (Cycles), deci darele de lumina vin singure,
    alungite pe verticala de unghiul razant."""
    mat, nt, out = new_material("BandWater")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.05, 0.05, 0.05)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 6.0
    nz.inputs["Detail"].default_value = 4.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    bump = n.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.25
    bump.inputs["Distance"].default_value = 0.6
    L.new(nz.outputs["Fac"], bump.inputs["Height"])
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = srgb(WATER)
    bsdf.inputs["Roughness"].default_value = 0.10
    bsdf.inputs["Specular IOR Level"].default_value = 0.5
    L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


# --- Teren (dealuri) si apa ---------------------------------------------------------

def build_land():
    n_az, n_r = 2880, 260
    A, Rg, px, py = polar_grid(n_az, n_r, 200.0, 22000.0)
    rm = river_mask(px, py)
    zl = land_height(px, py)
    # pe apa terenul coboara sub nivel (malul are cheiuri: urca repede)
    zl = np.maximum(zl, 8.0)                      # uscatul nu coboara sub apa
    z = zl * (1.0 - smoothstep(0.35, 0.75, rm)) - 8.0 * smoothstep(0.5, 0.9, rm)
    z = np.where(rm > 0.5, np.minimum(z, -3.0), z)
    co = np.stack([px, py, z], axis=-1)
    me = grid_mesh("BandLand", co, n_r, n_az)
    # culoarea: padure neagra-albastruie, cu pete
    v = fbm(px, py, 900.0, 5)
    cols = np.stack([lin(c) for c in HILL])
    idx = np.clip((v * len(HILL)).astype(int), 0, len(HILL) - 1)
    col = cols[idx]
    rgba = np.concatenate([col.reshape(-1, 3), np.ones((col.size // 3, 1))], axis=1)
    ca = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    ca.data.foreach_set("color", rgba.astype(np.float32).ravel())
    for p in me.polygons:
        p.use_smooth = True
    link("BandLand", me, hill_material())
    return px, py, z, rm


def build_water():
    me = bpy.data.meshes.new("BandWater")
    s = 30000.0
    me.from_pydata([(-s, -s, 0.0), (s, -s, 0.0), (s, s, 0.0), (-s, s, 0.0)], [], [(0, 1, 2, 3)])
    link("BandWater", me, water_material())


# --- Turnurile ----------------------------------------------------------------------

class Boxes:
    """Acumulator de cutii (fara fata de jos) cu atributele fatadei."""

    def __init__(self):
        self.v, self.fu, self.fz, self.tid, self.roof, self.lit, self.cool = [], [], [], [], [], [], []

    def add(self, cx, cy, z0, w, d, h, rot, tid, lit, cool, zbase=None):
        """Cutie centrata in (cx, cy), de la z0 la z0 + h, rotita cu `rot` (rad).
        `zbase` = cota de la care se numara etajele (pentru tronsoanele de sus)."""
        zb = z0 if zbase is None else zbase
        c, s = math.cos(rot), math.sin(rot)
        ex = np.array([c, s, 0.0])
        ey = np.array([-s, c, 0.0])
        ctr = np.array([cx, cy, 0.0])
        hw, hd = w * 0.5, d * 0.5
        corners = [ctr - ex * hw - ey * hd, ctr + ex * hw - ey * hd,
                   ctr + ex * hw + ey * hd, ctr - ex * hw + ey * hd]
        z1 = z0 + h
        lens = [w, d, w, d]
        u0 = 0.0
        for k in range(4):
            a, bb = corners[k], corners[(k + 1) % 4]
            quad = [a + [0, 0, z0], bb + [0, 0, z0], bb + [0, 0, z1], a + [0, 0, z1]]
            self.v.extend(quad)
            ln = lens[k]
            self.fu.extend([u0, u0 + ln, u0 + ln, u0])
            self.fz.extend([z0 - zb, z0 - zb, z1 - zb, z1 - zb])
            self.roof.extend([0.0] * 4)
            u0 += ln + 3.0
        self.v.extend([corners[0] + [0, 0, z1], corners[1] + [0, 0, z1],
                       corners[2] + [0, 0, z1], corners[3] + [0, 0, z1]])
        self.fu.extend([0.0] * 4)
        self.fz.extend([0.0] * 4)
        self.roof.extend([1.0] * 4)
        self.tid.extend([tid] * 20)
        self.lit.extend([lit] * 20)
        self.cool.extend([cool] * 20)

    def build(self, name, mat):
        if not self.v:
            return None
        me = quads_mesh(name, np.array(self.v, dtype=np.float64), {
            "fu": np.array(self.fu), "fz": np.array(self.fz), "tid": np.array(self.tid),
            "roof": np.array(self.roof), "lit": np.array(self.lit), "cool": np.array(self.cool)})
        return link(name, me, mat)


class Emitters:
    """Cutii emisive mici (neon, LED de coronament, balizaj, lampi de pod)."""

    def __init__(self):
        self.v, self.col, self.k = [], [], []

    def box(self, cx, cy, z0, w, d, h, rot, hexcol, k=1.0):
        c, s = math.cos(rot), math.sin(rot)
        ex = np.array([c, s, 0.0])
        ey = np.array([-s, c, 0.0])
        ctr = np.array([cx, cy, 0.0])
        hw, hd = w * 0.5, d * 0.5
        cs = [ctr - ex * hw - ey * hd, ctr + ex * hw - ey * hd,
              ctr + ex * hw + ey * hd, ctr - ex * hw + ey * hd]
        z1 = z0 + h
        for kk in range(4):
            a, bb = cs[kk], cs[(kk + 1) % 4]
            self.v.extend([a + [0, 0, z0], bb + [0, 0, z0], bb + [0, 0, z1], a + [0, 0, z1]])
        self.v.extend([cs[0] + [0, 0, z1], cs[1] + [0, 0, z1], cs[2] + [0, 0, z1], cs[3] + [0, 0, z1]])
        col = lin(hexcol)
        self.col.extend([col] * 20)
        self.k.extend([k] * 20)

    def build(self, name, strength):
        if not self.v:
            return None
        me = quads_mesh(name, np.array(self.v, dtype=np.float64),
                        {"ecol": np.array(self.col), "ek": np.array(self.k)})
        return link(name, me, emit_material(name, None, strength))


def tower(B, E, rng, cx, cy, zg, h, w, d, rot, lit, cool, neon_p=0.10, crown_p=0.07):
    """Un turn: corp + 0-2 tronsoane retrase, uneori coronament LED, neon pe
    acoperis, lumina de balizaj rosie pe cele inalte."""
    tid = rng.random()
    kind = rng.random()
    z = zg - 4.0
    if kind < 0.45 or h < 50.0:
        B.add(cx, cy, z, w, d, h + 4.0, rot, tid, lit, cool)
        top, tw, td = z + h + 4.0, w, d
    else:
        # corp + retrageri
        h1 = h * rng.uniform(0.55, 0.75)
        B.add(cx, cy, z, w, d, h1 + 4.0, rot, tid, lit, cool)
        w2, d2 = w * rng.uniform(0.6, 0.85), d * rng.uniform(0.6, 0.85)
        h2 = h - h1
        B.add(cx, cy, z + h1 + 4.0, w2, d2, h2, rot, tid, lit, cool, zbase=z)
        top, tw, td = z + h + 4.0, w2, d2
        if kind > 0.85:                      # ac / antena
            E.box(cx, cy, top, 1.2, 1.2, h * 0.12, rot, "2A2A30", 0.0)
            E.box(cx, cy, top + h * 0.12, 1.6, 1.6, 1.6, rot, AVIATION, 1.0)
    r = rng.random()
    if r < crown_p:
        # coronament LED: o banda colorata pe toate patru fetele, sus
        # brief §0.1: „5% neon", NU cyberpunk — majoritatea coronamentelor sunt
        # LED alb-rece, doar unele colorate
        col = NEON[rng.randrange(len(NEON))] if rng.random() < 0.35 else WIN_COOL
        bh = rng.uniform(2.0, 4.5)
        E.box(cx, cy, top - bh - 1.0, tw + 0.6, td + 0.6, bh, rot, col, rng.uniform(0.7, 1.1))
        if rng.random() < 0.5:
            E.box(cx, cy, top - bh * 3.0 - 2.0, tw + 0.6, td + 0.6, bh * 0.5, rot, col, 0.7)
    elif r < crown_p + neon_p:
        # firma de neon pe acoperis: o placa ingusta, pe una din fete
        col = NEON[rng.randrange(len(NEON))]
        side = rng.choice((-1.0, 1.0))
        c, s = math.cos(rot), math.sin(rot)
        ox, oy = -s * td * 0.5 * side, c * td * 0.5 * side
        E.box(cx + ox, cy + oy, top + 0.5, tw * rng.uniform(0.5, 0.9), 0.6,
              rng.uniform(3.0, 6.0), rot, col, rng.uniform(0.8, 1.2))
    if h > 90.0 and kind <= 0.85:
        E.box(cx, cy, top, 1.6, 1.6, 1.6, rot, AVIATION, 0.9)


def build_city(rng, land):
    """Orasul pe dealuri: densitate mare pe primii 3 km, rara spre munti, zero pe
    apa si pe pantele mari. Plus planul 0 (NEAR), pus de mana."""
    px, py, z, rm = land
    B = Boxes()
    E = Emitters()
    n_t = 0
    # esantionare pe o grila carteziana deasa, cu densitate dupa distanta
    for ring_r0, ring_r1, cell, hmin, hmax, p0 in (
            (SHORE_R0 + 30.0, 1200.0, 34.0, 22.0, 80.0, 0.36),
            (1200.0, 2600.0, 42.0, 30.0, 125.0, 0.36),
            (2600.0, 5000.0, 60.0, 30.0, 105.0, 0.30),
            (5000.0, 9000.0, 95.0, 25.0, 70.0, 0.16)):
        g = np.arange(-ring_r1, ring_r1, cell)
        X, Y = np.meshgrid(g, g)
        X = X + (np.vectorize(lambda _: rng.uniform(-0.4, 0.4))(X)) * cell
        Y = Y + (np.vectorize(lambda _: rng.uniform(-0.4, 0.4))(Y)) * cell
        R = np.hypot(X, Y)
        sel = (R >= ring_r0) & (R < ring_r1)
        X, Y = X[sel], Y[sel]
        R = R[sel]
        wm = river_mask(X, Y)
        zg = land_height(X, Y)
        # panta: diferenta pe 40 m
        zx = land_height(X + 40.0, Y)
        slope = np.abs(zx - zg) / 40.0
        dens = fbm(X, Y, 1400.0, 21)                 # cartiere dense / goluri
        ok = (wm < 0.05) & (slope < 0.45) & (zg < 330.0)
        for i in np.nonzero(ok)[0]:
            p = p0 * smoothstep(0.30, 0.62, dens[i]) * (1.0 - smoothstep(180.0, 330.0, zg[i]))
            if rng.random() > p:
                continue
            # turnurile inalte stau in ciorchini (centrele de cartier)
            tall = dens[i] > 0.6 and rng.random() < 0.55
            h = rng.uniform(hmin, hmax if tall else hmin + (hmax - hmin) * 0.45)
            w = rng.uniform(16.0, 30.0)
            dd = w * rng.uniform(0.7, 1.3)
            rot = math.radians(rng.choice((0.0, 15.0, 30.0, 45.0, 60.0, 75.0)) + rng.uniform(-6, 6))
            lit = rng.uniform(0.35, 1.0)
            cool = rng.uniform(0.1, 0.5)
            tower(B, E, rng, X[i], Y[i], zg[i], h, w, dd, rot, lit, cool)
            n_t += 1
    n_near = build_near(B, E, rng)
    n_l = hill_lights(E, rng)
    print("banda: %d lumini pe dealuri" % n_l)
    B.build("BandTowers", facade_material())
    E.build("BandNeon", 3.2)
    print("banda: %d turnuri + %d in planul 0" % (n_t, n_near))


def hill_lights(E, rng):
    """Dealurile impadurite de departe sunt negre pe cer negru: ce le face sa se
    citeasca sunt satele si drumurile de pe ele — puncte de sodiu rare, in
    ciorchini, si cateva siruri pe curbele de nivel (serpentine)."""
    n = 0
    g = np.arange(-15000.0, 15000.0, 70.0)
    X, Y = np.meshgrid(g, g)
    X = X.ravel() + np.array([rng.uniform(-30, 30) for _ in range(X.size)])
    Y = Y.ravel() + np.array([rng.uniform(-30, 30) for _ in range(Y.size)])
    R = np.hypot(X, Y)
    sel = (R > 2600.0) & (R < 15000.0)
    X, Y, R = X[sel], Y[sel], R[sel]
    zg = land_height(X, Y)
    wm = river_mask(X, Y)
    vill = fbm(X, Y, 1100.0, 41)
    ok = (wm < 0.05) & (zg > 120.0)
    for i in np.nonzero(ok)[0]:
        if rng.random() > 0.20 * smoothstep(0.55, 0.75, vill[i]):
            continue
        s_ = 5.0 + R[i] / 2500.0
        col = BRIDGE_LAMP if rng.random() < 0.7 else WIN_PALE
        E.box(X[i], Y[i], zg[i] + 2.0, s_, s_, s_, 0.0, col, rng.uniform(0.6, 1.0))
        n += 1
    return n


# Planul 0 (`NEAR`): turnuri MARI puse de mana, la 0,55-0,85 km, pe azimuturile pe
# care priveste camera de joc pe portiunile lungi (sonda temporara pe Track12.baked,
# vezi tabelul de mai jos), la 10-40 de grade de axa dreptelor.
# Fiecare: (busola, distanta, cota terenului, [(dx_tangential, dr_radial, h, w, d), ...])
#   portiunea                fractii     directia camerei   sus in cadru
#   dreapta de sus spre V    0,96-0,07   264-320            3,8-5,7 grade
#   coborarea spre VSV       0,15-0,21   245-253            1-4 grade
#   malul de V, spre S       0,22-0,31   153-209            4,2-4,9 grade
#   cheiul de S, spre E      0,43-0,53   84-106             5,5-6,8 grade
#   urcarea N -> NV          0,54-0,62   60 -> 297          ~10 grade
#   spre V (sus)             0,63-0,67   252                8 grade
#   spre SV                  0,68-0,71   213                7 grade
#   pasajul, spre E          0,72-0,79   89-105             7 grade
#   urcarea spre NNV         0,80-0,95   320-351            7-9 grade
#
# Culoarele de rau stau CHIAR pe axele lungi (V 280, SSV 200, E 100): privirea
# merge pe apa pana departe, intre doua ciorchini de turnuri. Uriasii stau la
# 20-40 de grade de axe. Inaltimea e aleasa in GRADE din origine (camera la
# CAM_Z): h = CAM_Z - cota + d * tan(e); 4-9 grade, cate unul iese din cadru.
NEAR = [
    ("A", 233.0, 640.0, [(0.0, 0.0, 120.0, 34.0, 28.0), (-62.0, 30.0, 92.0, 26.0, 26.0),
                         (55.0, -20.0, 76.0, 30.0, 22.0), (112.0, 40.0, 102.0, 24.0, 24.0)]),
    ("B", 314.0, 700.0, [(0.0, 0.0, 132.0, 30.0, 30.0), (-72.0, 20.0, 96.0, 36.0, 24.0),
                         (62.0, 40.0, 84.0, 26.0, 26.0)]),
    ("C", 14.0, 720.0, [(0.0, 0.0, 112.0, 32.0, 26.0), (-66.0, 30.0, 88.0, 26.0, 26.0),
                        (72.0, 10.0, 140.0, 28.0, 28.0)]),
    ("D", 60.0, 660.0, [(0.0, 0.0, 124.0, 30.0, 30.0), (66.0, 25.0, 96.0, 34.0, 24.0),
                        (-60.0, 40.0, 80.0, 24.0, 24.0)]),
    ("E", 133.0, 620.0, [(0.0, 0.0, 116.0, 32.0, 28.0), (62.0, 30.0, 88.0, 26.0, 26.0),
                         (-56.0, 10.0, 100.0, 28.0, 24.0)]),
    ("G", 168.0, 760.0, [(0.0, 0.0, 108.0, 30.0, 30.0), (72.0, 30.0, 80.0, 28.0, 22.0)]),
]


def build_near(B, E, rng):
    n = 0
    for _name, az, dist, parts in NEAR:
        a = math.radians(az)
        rad = Vector((math.sin(a), math.cos(a), 0.0))
        tang = Vector((math.cos(a), -math.sin(a), 0.0))
        for dx, dr, h, w, d in parts:
            p = rad * (dist + dr) + tang * dx
            zg = float(land_height(np.array([p.x]), np.array([p.y]))[0])
            rot = -a + math.radians(rng.uniform(-10, 10))
            tower(B, E, rng, p.x, p.y, zg, h, w, d, rot, rng.uniform(0.55, 0.95),
                  rng.uniform(0.15, 0.45), neon_p=0.15, crown_p=0.25)
            n += 1
    return n


# --- Poduri ---------------------------------------------------------------------------

BRIDGES = [    # (busola, distanta, lungime, inaltime tablier, fel, culoare)
    (100.0, 1700.0, 720.0, 36.0, "cable", BRIDGE_LED),
    (280.0, 1350.0, 640.0, 32.0, "arch", BRIDGE_LAMP),
    (200.0, 2500.0, 860.0, 38.0, "cable", "FF7AB8"),
    (200.0, 1250.0, 620.0, 30.0, "girder", BRIDGE_LAMP),
]


def build_bridges(E):
    for az, dist, length, hz, kind, col in BRIDGES:
        a = math.radians(az)
        rad = np.array([math.sin(a), math.cos(a), 0.0])
        tang = np.array([math.cos(a), -math.sin(a), 0.0])
        ctr = rad * dist
        rot = math.atan2(tang[1], tang[0])
        nlamp = int(length / 24.0)
        for side in (-1.0, 1.0):
            for i in range(nlamp + 1):
                t = (i / nlamp - 0.5) * length
                p = ctr + tang * t + rad * side * 9.0
                E.box(p[0], p[1], hz + 1.0, 2.2, 2.2, 2.2, rot, BRIDGE_LAMP, 1.0)
        # tablierul: o banda subtire intunecata cu un fir de lumina dedesubt
        E.box(ctr[0], ctr[1], hz - 2.5, length, 20.0, 2.5, rot, "1A1C22", 0.0)
        E.box(ctr[0], ctr[1], hz - 3.2, length, 18.0, 0.7, rot, col, 0.55)
        if kind == "cable":
            for sgn in (-1.0, 1.0):
                pp = ctr + tang * sgn * length * 0.22
                ph = 120.0
                E.box(pp[0], pp[1], hz, 8.0, 22.0, ph, rot, "202228", 0.0)
                E.box(pp[0], pp[1], hz + ph - 8.0, 8.6, 22.6, 6.0, rot, col, 1.0)
                # hobanele: siruri de puncte LED de la varful pilonului la tablier
                for k in range(1, 9):
                    for dirn in (-1.0, 1.0):
                        anchor = pp + tang * dirn * (k * length * 0.032)
                        for j in range(1, 16):
                            f = j / 16.0
                            q = pp * (1.0 - f) + anchor * f
                            zz = (hz + ph - 6.0) * (1.0 - f) + (hz + 1.0) * f
                            E.box(q[0], q[1], zz, 1.3, 1.3, 1.3, rot, col, 0.7)
        elif kind == "arch":
            na = 40
            for i in range(na + 1):
                t = i / na
                x = (t - 0.5) * length * 0.8
                zz = hz + 4.0 + 110.0 * math.sin(math.pi * t)
                for side in (-1.0, 1.0):
                    p = ctr + tang * x + rad * side * 7.0
                    E.box(p[0], p[1], zz, 3.0, 3.0, 3.0, rot, col, 0.9)


# --- Pacla de deasupra orasului -----------------------------------------------------------

def build_glow():
    """Un cilindru departe (14 km), cu emisie + transparenta: alfa partial, deci
    in joc se aseaza PESTE gradientul temei. Mai tare jos si deasupra cartierelor
    dense, nul de la ~6 grade in sus. Turnurile il acopera, raurile si muntii il
    lasa sa se vada — exact pacla luminata de jos a unui oras pe dealuri."""
    R = 14000.0
    n = 720
    zs = [CAM_Z + R * math.tan(math.radians(e)) for e in (-1.0, 0.5, 2.0, 4.0, 7.0, 10.0)]
    alph = [0.75, 0.65, 0.45, 0.22, 0.06, 0.0]
    verts, faces, al = [], [], []
    for j in range(n):
        a = j / n * math.tau
        x, y = math.sin(a) * R, math.cos(a) * R
        # mai dens peste oras, mai slab spre munti / culoarele de rau
        az = math.degrees(a) % 360.0
        k = 1.0
        for _, raz, _w in RIVERS:
            k = min(k, 0.55 + 0.45 * min(1.0, abs((az - raz + 180.0) % 360.0 - 180.0) / 30.0))
        for zz, aa in zip(zs, alph):
            verts.append((x, y, zz))
            al.append(aa * k)
    for j in range(n):
        j1 = (j + 1) % n
        for i in range(len(zs) - 1):
            faces.append((j * len(zs) + i, j1 * len(zs) + i, j1 * len(zs) + i + 1, j * len(zs) + i + 1))
    me = bpy.data.meshes.new("BandGlow")
    me.from_pydata(verts, [], faces)
    at = me.attributes.new("ga", "FLOAT", "POINT")
    at.data.foreach_set("value", np.array(al, dtype=np.float32))
    mat, nt, out = new_material("BandGlow")
    b = NB(nt)
    n_, L = b.n, b.L
    ga = b.attr("ga").outputs["Fac"]
    em = n_.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(GLOW)
    em.inputs["Strength"].default_value = 1.0
    tr = n_.new("ShaderNodeBsdfTransparent")
    mix = n_.new("ShaderNodeMixShader")
    L.new(ga, mix.inputs[0])
    L.new(tr.outputs[0], mix.inputs[1])
    L.new(em.outputs[0], mix.inputs[2])
    L.new(mix.outputs[0], out.inputs["Surface"])
    ob = link("BandGlow", me, mat)
    ob.visible_shadow = False
    ob.visible_diffuse = False
    ob.visible_glossy = False


# --- Randare ---------------------------------------------------------------------------

def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    rx, ry = math.radians(SUN_ROT[0]), math.radians(SUN_ROT[1])
    x, y, z = 0.0, -math.sin(rx), math.cos(rx)
    gx = x * math.cos(ry) + z * math.sin(ry)
    gz = -x * math.sin(ry) + z * math.cos(ry)
    g = Vector((gx, y, gz))
    return Vector((g.x, -g.z, g.y)).normalized()


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
    except Exception as e:
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
    if CROP:
        sc.render.use_border = True
        sc.render.use_crop_to_border = True
        sc.render.border_min_x, sc.render.border_max_x = CROP
        sc.render.border_min_y, sc.render.border_max_y = 0.0, 1.0

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

    ld = bpy.data.lights.new("BandMoon", "SUN")
    ld.energy = MOON_STRENGTH
    ld.color = srgb(MOON_COLOR)[:3]
    ld.angle = math.radians(1.0)
    sun = bpy.data.objects.new("BandMoon", ld)
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
        me.from_pydata([(-s, -s, 0), (s, -s, 0), (s, s, 0), (-s, s, 0),
                        (-s, -s, 2 * s), (s, -s, 2 * s), (s, s, 2 * s), (-s, s, 2 * s)], [],
                       [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)])
        ob = bpy.data.objects.new("Mk" + name, me)
        bpy.context.collection.objects.link(ob)
        ob.location = (x, y, 60)
        mat, nt, out = new_material("Mk" + name)
        em = nt.nodes.new("ShaderNodeEmission")
        em.inputs["Color"].default_value = col
        em.inputs["Strength"].default_value = 3.0
        nt.links.new(em.outputs[0], out.inputs["Surface"])
        ob.data.materials.append(mat)


import random  # noqa: E402

reset()
rng = random.Random(12)
random.seed(12)
setup_render()
build_water()
land = build_land()
build_city(rng, land)
E2 = Emitters()
build_bridges(E2)
E2.build("BandBridges", 3.0)
build_glow()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
