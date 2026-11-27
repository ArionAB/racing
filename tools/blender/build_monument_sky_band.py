"""Banda de orizont a cerului Monument Valley (Track19) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/monumentvalley_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15),
cu alfa: podisul rosu al vaii cu mese, butte-uri si ace de gresie la 0,5-15 km, si
campia pana la orizont prin golurile dintre ele; cerul ramane TRANSPARENT, fiindca
gradientul lui il deseneaza shaderul de cer din joc (`scenes/tracks/sky_band.gdshader`).
Reteta e cea de pe Ha Long (`build_halong_sky_band.py`); aici e prima pista de USCAT.

Diferenta fata de Ha Long, si problema centrala a pistei: acolo marea pictata intra
in marea jocului (doua suprafete plate, aceeasi culoare). Aici terenul real (nisip
rosu, cu decor, intrat in ceata spre fog_end 360 m) trebuie sa se lege de PODEAUA
pictata a benzii fara dunga. De aceea podeaua NU e o culoare de pictor: e acelasi
albedo ca terenul jocului (`FLOOR_ALBEDO`, masurat pe captura), luminat de ACELASI
soare si ambient (`SUN_STRENGTH` / `AMBIENT`, cu factorul pi intre conventiile de
lumina ale lui Godot si Cycles), deci la marginea de jos banda are culoarea pe care
o are nisipul jocului. Perspectiva aeriana a benzii pleaca de la ceata pe care o
are deja jocul la fog_end (`HAZE_F0`), nu de la zero: altfel o masa de la 700 m ar
iesi mai saturata decat Mittens-urile de la 300 m.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la 10 m peste campie, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "monumentvalley" (`sun_rotation_deg` (-18, -70, 0), adica
    busola 250, VSV, 18 grade elevatie), `sun_color` FFD2A0, energia 1,0;
    ambientul A9BEDD la 0,30;
  * HAZE = `sky_horizon` din tema (F1D3AA): departarea se topeste exact in
    culoarea pe care o deseneaza cerul din joc in spatele benzii, deci marginea
    benzii nu se vede;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 20; done
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_monument_sky_band.py [-- --test]
    rmdir D:/GameDev/.render_lock
"""

import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, noise

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
TEST = "--test" in ARGS

W, H = (1024, 64) if TEST else (8192, 512)
LAT_MIN, LAT_MAX = -7.5, 15.0            # grade; (LAT_MAX - LAT_MIN) / 360 = H / W
CAM_Z = 10.0
SAMPLES = 16 if TEST else 128
OUT = os.path.join(PROJECT, "assets", "textures", "sky",
                   "monumentvalley_horizon_band_test.png" if TEST
                   else "monumentvalley_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB, ca in tema si in brief §4) -----------------------------------
HAZE = "F1D3AA"          # = sky_horizon din tema: departarea intra in cer
DUST = "E9C29C"          # praful jos de pe podea, un pic mai rosu decat aerul
# Podeaua: ALBEDO-ul nisipului din joc, nu culoarea lui pe ecran (lumina o pune
# soarele de mai jos, acelasi ca in joc). Masurat pe captura, vezi docstring.
FLOOR_ALBEDO = "B68261"
FLOOR_DARK = "A06A4C"    # petice de salvie/ienupar si umbre de dune
FLOOR_LIGHT = "C79670"   # albiile palide
ROCK = "B8552E"          # peretele de gresie (mv_sandstone)
ROCK_LIGHT = "D27448"    # strat aprins
ROCK_DARK = "93452A"     # strat inchis
ROCK_VARNISH = "6E3524"  # dungile verticale de „lac de desert"
SCREE = "8A4A33"         # grohotisul de sist Organ Rock
SCREE_B = "9C5A3C"
CAP = "B9A08C"           # calota palida
SUN_COLOR = "FFD2A0"
# Godot inmulteste energia luminii cu pi (alb lambertian perpendicular = energia);
# Cycles nu (alb = taria / pi). Deci taria Cycles = pi x energia temei.
SUN_STRENGTH = math.pi * 1.0
AMBIENT = "A9BEDD"
AMBIENT_ENERGY = 0.30

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului incolo. F0 = cat a spalat deja ceata jocului la fog_end.
HAZE_D0, HAZE_D, HAZE_F0 = 360.0, 8000.0, 0.15
DUST_H, DUST_K = 18.0, 0.45               # praful jos: K * exp(-z/H), doar departe
SUN_ROT = (-18.0, -70.0)                  # sun_rotation_deg (x, y) din tema


# --- Scena ---------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node):
    """surface -> amestec cu HAZE dupa distanta si cu DUST dupa inaltime."""
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
    # F0 intra treptat pe primii 600 m de dupa fog_end: la marginea de jos a
    # benzii podeaua are exact culoarea nisipului din joc, fara voal.
    f0 = math_node("SUBTRACT", d, vb=HAZE_D0)
    f0 = math_node("MULTIPLY", f0, vb=1.0 / 600.0)
    f0 = math_node("MINIMUM", f0, vb=1.0)
    f0 = math_node("MAXIMUM", f0, vb=0.0)
    f0 = math_node("MULTIPLY", f0, vb=-HAZE_F0)
    f0 = math_node("ADD", f0, vb=1.0)
    keep_air = math_node("MULTIPLY", x, f0)                   # 1 - fac_aer
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / DUST_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")                        # praful doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 700.0
    ramp.inputs["From Max"].default_value = 4000.0
    dust = math_node("MULTIPLY", z, ramp.outputs["Result"])
    dust = math_node("MULTIPLY", dust, vb=DUST_K)
    keep_dust = math_node("SUBTRACT", va=1.0, b=dust)
    keep = math_node("MULTIPLY", keep_air, keep_dust)
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    cmix.inputs[6].default_value = srgb(HAZE)
    cmix.inputs[7].default_value = srgb(DUST)
    L.new(dust, cmix.inputs[0])
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


def ramp(n, stops):
    cr = n.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    els[0].position, els[0].color = stops[0][0], srgb(stops[0][1])
    els[1].position, els[1].color = stops[-1][0], srgb(stops[-1][1])
    for pos, col in stops[1:-1]:
        e = els.new(pos)
        e.color = srgb(col)
    return cr


def rock_material():
    """Gresie: straturi ORIZONTALE (benzi pe Z de lume, distorsionate), dungi
    verticale de lac de desert, grohotis rosu-brun la baza si calota palida sus.
    Zona vine din atributul `zone` pus pe varfuri: 0 grohotis, 1 perete, 2 calota."""
    mat, nt, out = new_material("BandRock")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    # straturi: Wave pe Z
    wave = n.new("ShaderNodeTexWave")
    wave.wave_type = "BANDS"
    wave.bands_direction = "Z"
    wave.inputs["Scale"].default_value = 0.035
    wave.inputs["Distortion"].default_value = 3.0
    wave.inputs["Detail"].default_value = 2.0
    wave.inputs["Detail Scale"].default_value = 0.6
    L.new(tc.outputs["Object"], wave.inputs["Vector"])
    strata = ramp(n, [(0.0, ROCK_DARK), (0.35, ROCK), (0.7, ROCK_LIGHT), (1.0, ROCK)])
    L.new(wave.outputs["Fac"], strata.inputs["Fac"])
    # lac de desert: zgomot alungit pe verticala
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.25, 0.25, 0.02)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 3.0
    nz.inputs["Detail"].default_value = 4.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    vr = n.new("ShaderNodeMapRange")
    vr.inputs["From Min"].default_value = 0.55
    vr.inputs["From Max"].default_value = 0.75
    vr.inputs["To Max"].default_value = 0.45
    L.new(nz.outputs["Fac"], vr.inputs["Value"])
    wall = n.new("ShaderNodeMix")
    wall.data_type = "RGBA"
    L.new(vr.outputs["Result"], wall.inputs[0])
    L.new(strata.outputs["Color"], wall.inputs[6])
    wall.inputs[7].default_value = srgb(ROCK_VARNISH)
    # grohotis: dungi orizontale fine
    wave2 = n.new("ShaderNodeTexWave")
    wave2.wave_type = "BANDS"
    wave2.bands_direction = "Z"
    wave2.inputs["Scale"].default_value = 0.12
    wave2.inputs["Distortion"].default_value = 6.0
    L.new(tc.outputs["Object"], wave2.inputs["Vector"])
    scree = ramp(n, [(0.0, SCREE), (1.0, SCREE_B)])
    L.new(wave2.outputs["Fac"], scree.inputs["Fac"])
    # zona
    attr = n.new("ShaderNodeAttribute")
    attr.attribute_type = "GEOMETRY"
    attr.attribute_name = "zone"
    z_wall = n.new("ShaderNodeMapRange")
    z_wall.inputs["From Min"].default_value = 0.55
    z_wall.inputs["From Max"].default_value = 0.95
    L.new(attr.outputs["Fac"], z_wall.inputs["Value"])
    z_cap = n.new("ShaderNodeMapRange")
    z_cap.inputs["From Min"].default_value = 1.5
    z_cap.inputs["From Max"].default_value = 1.9
    L.new(attr.outputs["Fac"], z_cap.inputs["Value"])
    m1 = n.new("ShaderNodeMix")
    m1.data_type = "RGBA"
    L.new(z_wall.outputs["Result"], m1.inputs[0])
    L.new(scree.outputs["Color"], m1.inputs[6])
    L.new(wall.outputs[2], m1.inputs[7])
    m2 = n.new("ShaderNodeMix")
    m2.data_type = "RGBA"
    L.new(z_cap.outputs["Result"], m2.inputs[0])
    L.new(m1.outputs[2], m2.inputs[6])
    m2.inputs[7].default_value = srgb(CAP)
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    bsdf.inputs["Specular IOR Level"].default_value = 0.05
    L.new(m2.outputs[2], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def floor_material():
    """Campia: albedo-ul nisipului din joc, luminat de acelasi soare; petice mari
    mai inchise (salvie, umbre de dune) si albii palide, alungite pe X ca sa
    citeasca orizontal la unghiuri razante."""
    mat, nt, out = new_material("BandFloor")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / 90.0, 1.0 / 90.0, 1.0)
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 1.0
    nz.inputs["Detail"].default_value = 5.0
    nz.inputs["Roughness"].default_value = 0.6
    L.new(mp.outputs[0], nz.inputs["Vector"])
    cr = ramp(n, [(0.30, FLOOR_DARK), (0.47, FLOOR_ALBEDO), (0.56, FLOOR_ALBEDO),
                  (0.72, FLOOR_LIGHT)])
    L.new(nz.outputs["Fac"], cr.inputs["Fac"])
    bsdf = n.new("ShaderNodeBsdfDiffuse")
    bsdf.inputs["Roughness"].default_value = 0.0
    L.new(cr.outputs["Color"], bsdf.inputs["Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


# --- Formele de gresie ------------------------------------------------------------

def smooth01(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def superellipse_r(a, rx, ry, p=4.0):
    c, s = abs(math.cos(a)) / rx, abs(math.sin(a)) / ry
    return (c ** p + s ** p) ** (-1.0 / p)


def landform(bm, zone_layer, cx, cy, h, rx, ry, rng, scree=0.32, taper=0.04,
             lobes=0.16, p=4.0, rot=None):
    """O masa / un butte / un ac: grohotis evazat la baza (panta ~35 grade, cu
    rigole), perete aproape vertical cu coloane si trepte de strat, varf PLAT.
    `zone` pe varfuri: 0 grohotis, 1 perete, 2 calota."""
    seed = rng.random() * 100.0
    if rot is None:
        rot = rng.uniform(0.0, math.tau)
    segs = 72
    hs = h * scree
    r_mean = 0.5 * (rx + ry)
    skirt = hs * rng.uniform(1.4, 2.1)
    zs = [-4.0] + [hs * (i / 5.0) for i in range(1, 6)]               # grohotis
    n_wall = max(6, int((h - hs) / 6.0))
    zw = [hs + (h - hs) * (i / n_wall) for i in range(1, n_wall + 1)]  # perete
    top_drop = rng.uniform(-0.03, 0.05) * h

    def r_wall(a, t):
        ca, sa = math.cos(a), math.sin(a)
        base = superellipse_r(a - rot, rx, ry, p)
        lobe = noise.noise(Vector((ca * 1.3 + seed, sa * 1.3, 0.0)))
        col = noise.noise(Vector((ca * 9.0, sa * 9.0 + seed, t * 0.6)))
        step = noise.noise(Vector((ca * 3.0, sa * 3.0, t * h / 7.0 + seed)))
        return base * (1.0 + lobes * lobe + 0.05 * col + 0.025 * step) * (1.0 - taper * t)

    grid = []
    zones = []
    for z in zs:
        s = max(0.0, z) / max(hs, 1e-3)                    # 0 jos, 1 la piciorul peretelui
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            rw = r_wall(a, 0.0)
            gully = noise.noise(Vector((ca * 6.0 + seed, sa * 6.0, 1.7)))
            out = skirt * (1.0 - s) ** 1.35 * (1.0 + 0.35 * gully)
            ring.append(bm.verts.new((cx + ca * (rw + out), cy + sa * (rw + out), z)))
        grid.append(ring)
        zones.append(0.0)
    for k, z in enumerate(zw):
        t = (z - hs) / (h - hs)
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            rw = r_wall(a, t)
            zz = z + (top_drop * noise.noise(Vector((ca, sa, seed))) if k == len(zw) - 1 else 0.0)
            ring.append(bm.verts.new((cx + ca * rw, cy + sa * rw, zz)))
        grid.append(ring)
        zones.append(1.0)
    # calota: o buza ingusta spre interior, apoi centrul
    top_ring = []
    for j in range(segs):
        v = grid[-1][j].co
        top_ring.append(bm.verts.new((cx + (v.x - cx) * 0.94, cy + (v.y - cy) * 0.94, v.z + 0.4)))
    grid.append(top_ring)
    zones.append(2.0)
    zones[-2] = 1.0
    top = bm.verts.new((cx, cy, sum(v.co.z for v in top_ring) / segs + 0.6))
    for ring, zv in zip(grid, zones):
        for v in ring:
            v[zone_layer] = zv
    top[zone_layer] = 2.0
    for i in range(len(grid) - 1):
        for j in range(segs):
            k = (j + 1) % segs
            bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j]))
    for j in range(segs):
        bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], top))
    return r_mean + skirt


def spire(bm, zone_layer, cx, cy, h, r, rng):
    """Ac de gresie: perete ingust, ingustat spre varf, pe un con de grohotis."""
    return landform(bm, zone_layer, cx, cy, h, r, r * rng.uniform(0.6, 1.0), rng,
                    scree=rng.uniform(0.18, 0.28), taper=rng.uniform(0.25, 0.45),
                    lobes=0.10, p=2.5)


GAPS = [(8.0, 40.0), (118.0, 150.0), (292.0, 318.0)]        # grade, busola


def in_gap(az_deg):
    a = az_deg % 360.0
    return any(lo <= a <= hi for lo, hi in GAPS)


def build_landforms(rng):
    """Patru planuri: butte-uri si ace aproape (0,5-1,4 km), mese si butte-uri
    medii (1,4-3,5 km), mese lungi (3,5-8 km) si buza podisului departat (8-15 km),
    aproape continua. Golurile de pe azimut (GAPS) raman goale pe toata adancimea:
    acolo campia merge pana la orizont.

    Inaltimile sunt pentru fereastra camerei de joc (~5-6 grade peste orizont):
    h <= 10 + 0,09 d pentru aproape toate; cateva ace apropiate ies din cadru si
    dau scara."""
    bm = bmesh.new()
    zl = bm.verts.layers.float.new("zone")
    count = 0

    def place(d_min, d_max, n, make):
        nonlocal count
        placed = 0
        tries = 0
        while placed < n and tries < n * 40:
            tries += 1
            az = rng.uniform(0.0, 360.0)
            if in_gap(az):
                continue
            d = rng.uniform(d_min, d_max)
            a = math.radians(az)
            # Godot: busola (0 = nord = Blender +Y, 90 = est = +X)
            x, y = math.sin(a) * d, math.cos(a) * d
            make(x, y, d)
            placed += 1
            count += 1

    # 1. aproape: butte-uri mici si ace, in ciorchini
    def near(x, y, d):
        h = rng.uniform(16.0, min(45.0, 6.0 + 0.034 * d))
        if rng.random() < 0.35:
            spire(bm, zl, x, y, h * rng.uniform(1.0, 1.25), h * rng.uniform(0.10, 0.18), rng)
        else:
            r = h * rng.uniform(0.45, 0.9)
            landform(bm, zl, x, y, h, r, r * rng.uniform(0.5, 0.9), rng,
                     scree=rng.uniform(0.36, 0.5))
            if rng.random() < 0.4:      # un ac lipit, ca degetul lui Mitten
                a = rng.uniform(0, math.tau)
                spire(bm, zl, x + math.cos(a) * r * 1.3, y + math.sin(a) * r * 1.3,
                      h * rng.uniform(0.7, 1.0), h * 0.09, rng)
    place(550.0, 1400.0, 22, near)

    # 2. mediu: mese si butte-uri mai mari
    def mid(x, y, d):
        h = rng.uniform(36.0, min(110.0, 0.032 * d))
        if rng.random() < 0.55:
            r = h * rng.uniform(1.2, 3.2)                     # masa lata
            landform(bm, zl, x, y, h, r, r * rng.uniform(0.25, 0.5), rng, scree=0.36)
        else:
            r = h * rng.uniform(0.5, 1.0)
            landform(bm, zl, x, y, h, r, r * rng.uniform(0.5, 0.9), rng,
                     scree=rng.uniform(0.36, 0.5))
        if rng.random() < 0.3:
            a = rng.uniform(0, math.tau)
            spire(bm, zl, x + math.cos(a) * h * 1.8, y + math.sin(a) * h * 1.8,
                  h * rng.uniform(0.6, 0.9), h * 0.1, rng)
    place(1400.0, 3500.0, 28, mid)

    # 3. mese lungi departate
    def far(x, y, d):
        h = rng.uniform(70.0, min(200.0, 0.026 * d))
        r = h * rng.uniform(2.5, 7.0)
        landform(bm, zl, x, y, h, r, r * rng.uniform(0.12, 0.3), rng, scree=0.4, lobes=0.22)
    place(3500.0, 8000.0, 22, far)

    # 4. buza podisului: segmente lungi, aproape continue, orientate tangential
    az = 0.0
    while az < 360.0:
        step = rng.uniform(6.0, 14.0)
        mid_az = az + step * 0.5
        if not in_gap(mid_az) and not in_gap(az) and not in_gap(az + step):
            d = rng.uniform(9000.0, 15000.0)
            a = math.radians(mid_az)
            x, y = math.sin(a) * d, math.cos(a) * d
            half = math.radians(step) * d * 0.55
            h = rng.uniform(90.0, 220.0)
            # superelipsa orientata TANGENTIAL: rx de-a lungul arcului de cerc
            landform(bm, zl, x, y, h, half, h * rng.uniform(1.5, 3.0), rng,
                     scree=0.42, lobes=0.12, taper=0.02,
                     rot=-a + rng.uniform(-0.1, 0.1))
            count += 1
        az += step + (rng.uniform(1.0, 6.0) if rng.random() < 0.5 else 0.0)

    me = bpy.data.meshes.new("BandLandforms")
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = False
    ob = bpy.data.objects.new("BandLandforms", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(rock_material())
    print("banda: %d forme de relief, %d fete" % (count, len(me.polygons)))


def build_floor():
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=40000.0)
    me = bpy.data.meshes.new("BandFloor")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("BandFloor", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(floor_material())


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
rng = random.Random(19)
random.seed(19)
setup_render()
build_floor()
build_landforms(rng)
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
