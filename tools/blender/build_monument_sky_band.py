"""Banda de orizont a cerului Monument Valley (Track19) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/monumentvalley_horizon_band.png`, o felie
equirectangulara de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15),
cu alfa: podisul rosu al vaii cu mese, butte-uri si ace de gresie la 0,5-15 km, si
campia pana la orizont prin golurile dintre ele, plus planul 0 (`NEAR_GIANTS`): cinci
mase mari si apropiate (0,56-0,78 km), puse de mana pe directiile camerei de joc, care
dau SCARA vaii; cerul ramane TRANSPARENT, fiindca
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
FILL_COLOR = "D9865A"    # nisipul rosu luminat, vazut ca sursa de lumina joasa
FILL_STRENGTH = 0.9
FILL_AZ = 70.0           # opus soarelui (250)

# Perspectiva aeriana: fac = 1 - (1 - F0) * exp(-(d - d0) / D), de la fog_end-ul
# jocului incolo. F0 = cat a spalat deja ceata jocului la fog_end.
HAZE_D0, HAZE_D, HAZE_F0 = 360.0, 8000.0, 0.15
# Uriasii apropiati (0,56-0,78 km): voalul lor e inmultit cu atat. Cu voalul
# intreg (~12% spre HAZE-ul pal) fetele lor din umbra ieseau spalate, cenusii,
# mai „departe” decat sunt; in joc ceata de la 360 m trage spre podeaua rosie
# (#7B5038), nu spre pal, deci un voal pal mare nu le leaga de prim-plan.
NEAR_HAZE_K = 0.6
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


def haze_wrap(nt, surface_socket, out_node, haze_k=1.0):
    """surface -> amestec cu HAZE dupa distanta si cu DUST dupa inaltime.
    `haze_k` < 1 slabeste tot voalul (uriasii apropiati, vezi NEAR_HAZE_K)."""
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
    fac = math_node("MULTIPLY", fac, vb=haze_k)
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


def rock_material(name="BandRock", strata_scale=0.035, varnish=0.45, scree_scale=0.12,
                  haze_k=1.0):
    """Gresie: straturi ORIZONTALE (benzi pe Z de lume, distorsionate), dungi
    verticale de lac de desert, grohotis rosu-brun la baza si calota palida sus.
    Zona vine din atributul `zone` pus pe varfuri: 0 grohotis, 1 perete, 2 calota.
    Uriasii apropiati (`build_near_giants`) au varianta lor, cu straturi mai dese
    si lac mai apasat: la 0,5-0,8 km un pixel al benzii e ~0,5 m. (Wave din
    Blender inmulteste scara cu 20: 0,035 = un strat la ~9 m; la 0,075 peretele
    apropiat iesea in dungi de 4 m, ca un raiat de catifea.)"""
    mat, nt, out = new_material(name)
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    # straturi: Wave pe Z
    wave = n.new("ShaderNodeTexWave")
    wave.wave_type = "BANDS"
    wave.bands_direction = "Z"
    wave.inputs["Scale"].default_value = strata_scale
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
    vr.inputs["To Max"].default_value = varnish
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
    wave2.inputs["Scale"].default_value = scree_scale
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
    haze_wrap(nt, bsdf.outputs[0], out, haze_k)
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


# --- Uriasii apropiati (planul 0) ---------------------------------------------------
#
# De ce exista: inainte de banda, inelele 3D puneau un masiv mare si APROPIAT in
# cadru (pe cornisa 0,52, in stanga). Banda singura avea doar mese mici si
# departate (h <= 10 + 0,09 d, adica ~5 grade abia la marginea de sus), deci
# valea isi pierdea SCARA (verdictul dezvoltatorului, 27 nov 2026: „adauga
# cateva mese mari”). Planul 0 sunt cinci mase puse DE MANA, nu aleatoriu, pe
# azimuturi masurate din camera de joc (sonda temporara pe Track19.baked,
# camera ChaseCamera: fov 68 vertical = ~100 grade pe orizontala la 16:9):
#
#   portiunea              fractii      directia camerei  sus in cadru
#   US-163 (spre est)      0,87-0,03    90                ~7 grade
#   coama + coborarea      0,05-0,24    180               1,6-5,5 grade
#   dreapta spre vest      0,26-0,46    262-275           ~6 grade
#   cornisa                0,48-0,59    330-15            ~6 grade
#   campia (0,64-0,70)     0,60-0,74    98-28             2-5 grade
#
# Regulile plasarii: niciun urias pe axa unei drepte lungi (altfel pare ca
# drumul duce in el / ca sta pe drum), deci 15-40 de grade lateral; nimic in
# spatele Mittens/Merrick reali (de pe coama sunt la 160-195 grade); golurile
# GAPS raman campie. Inaltimea e aleasa in GRADE din origine (camera la 10 m):
# h = 10 + d * tan(e). Cele inalte (e > 7) ies din cadru: asta da scara.
#
# Umbrele lor cad spre azimutul 70 (soarele e la 250): A si C le arunca
# lateral/in spate, D si E spre camera. Varful umbrei lor trebuie sa ramana
# dincolo de ~400 m (D la 680 m: ~450; E la 720 m: ~490), altfel ajunge la
# marginea de jos a benzii (~360 m, unde se lipeste terenul jocului) si
# deseneaza o dunga acolo. Nici mai departe de ~720 m: de la 700 m intra
# praful jos, iar pe fata din umbra (soarele e in spatele lor) praful + ceata
# le faceau masline-cenusii (masurat la 760/820 m).
#
# Fiecare: (azimut, distanta, [(dx_tangential, dr_radial, h, rx, ry, fel), ...])
# fel: "mesa" (perete lung, orientat tangential), "butte", "spire".
NEAR_GIANTS = [
    # A — cornisa 0,48-0,59, in stanga (unde era masivul 3D); se vede si pe
    # 0,75-0,80 (spre VNV) in dreapta. O masa lunga + un butte inalt la capatul
    # dinspre drum, care iese din cadru.
    ("A", 327.0, 640.0, [(-30.0, 0.0, 56.0, 105.0, 46.0, "mesa"),
                         (88.0, -25.0, 82.0, 34.0, 28.0, "butte"),
                         (-150.0, 30.0, 48.0, 9.0, 7.0, "spire")]),
    # B — US-163 in stanga (32 de grade de axa), cornisa in dreapta, campia 0,70.
    ("B", 57.0, 720.0, [(0.0, 0.0, 70.0, 62.0, 44.0, "butte"),
                        (-78.0, 30.0, 82.0, 10.0, 8.0, "spire"),
                        (70.0, 60.0, 52.0, 70.0, 30.0, "mesa")]),
    # C — US-163 in dreapta (20 de grade de axa): cel mai inalt, iese din cadru
    # (8,5 grade fata de ~7), cu un butte mai mic spre gol, departe de axa;
    # golul 118-150 ramane in dreapta lor.
    ("C", 108.0, 560.0, [(0.0, 0.0, 94.0, 48.0, 40.0, "butte"),
                         (62.0, 40.0, 60.0, 30.0, 24.0, "butte")]),
    # D — dreapta spre vest, in stanga (25-35 de grade de axa).
    ("D", 236.0, 680.0, [(0.0, 0.0, 76.0, 150.0, 58.0, "mesa"),
                         (175.0, 40.0, 54.0, 8.0, 7.0, "spire")]),
    # E — coama: in dreapta Mittens-urilor reale (la 25-35 de grade de ei),
    # iese din cadru pe coborare (sus e doar 1,6-2,4 grade).
    ("E", 211.0, 720.0, [(0.0, 0.0, 96.0, 58.0, 44.0, "butte"),
                         (-82.0, -20.0, 80.0, 11.0, 9.0, "spire")]),
]


def giant(bm, zone_layer, cx, cy, h, rx, ry, rng, kind, rot):
    """Ca `landform`, dar pentru planul 0, vazut de la 0,5-0,8 km (un pixel ~0,5 m):
    de doua ori mai multe segmente, perete pe trepte de 2,5 m cu coloane de
    diaclaza (doua frecvente), o polita (bench) la ~60% din inaltime, calota ca
    STRAT pe ultimii ~7% din perete (vazut din lateral, fata de sus nu se vede),
    grohotis cu rigole adanci si bolovani prabusiti pe el."""
    seed = rng.random() * 100.0
    segs = 160
    if kind == "spire":
        scree, taper, lobes, p = rng.uniform(0.2, 0.28), rng.uniform(0.3, 0.45), 0.10, 2.5
    elif kind == "mesa":
        scree, taper, lobes, p = 0.34, 0.03, 0.10, 5.0
    else:
        scree, taper, lobes, p = rng.uniform(0.36, 0.44), 0.05, 0.12, 3.5
    hs = h * scree
    skirt = hs * rng.uniform(1.5, 1.9)
    zs = [-4.0] + [hs * (i / 9.0) for i in range(1, 10)]
    n_wall = max(10, int((h - hs) / 2.5))
    zw = [hs + (h - hs) * (i / n_wall) for i in range(1, n_wall + 1)]
    bench_t = rng.uniform(0.52, 0.66)
    top_drop = rng.uniform(-0.02, 0.03) * h

    def r_wall(a, t):
        ca, sa = math.cos(a), math.sin(a)
        base = superellipse_r(a - rot, rx, ry, p)
        lobe = noise.noise(Vector((ca * 1.3 + seed, sa * 1.3, 0.0)))
        col = noise.noise(Vector((ca * 16.0, sa * 16.0 + seed, t * 0.5)))
        col2 = noise.noise(Vector((ca * 38.0 + seed, sa * 38.0, t * 0.8)))
        step = noise.noise(Vector((ca * 3.0, sa * 3.0, t * h / 6.0 + seed)))
        bench = 0.06 * smooth01(bench_t - 0.03, bench_t + 0.01, t) if kind != "spire" else 0.0
        return base * (1.0 + lobes * lobe + 0.06 * col + 0.025 * col2 + 0.02 * step
                       - bench) * (1.0 - taper * t)

    grid, zones = [], []
    for z in zs:
        s = max(0.0, z) / max(hs, 1e-3)
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            rw = r_wall(a, 0.0)
            gully = noise.noise(Vector((ca * 7.0 + seed, sa * 7.0, 1.7)))
            rib = noise.noise(Vector((ca * 22.0, sa * 22.0 + seed, 3.1)))
            out = skirt * (1.0 - s) ** 1.3 * (1.0 + 0.45 * gully + 0.12 * rib)
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
        zones.append(2.0 if (t > 0.93 and kind != "spire") else 1.0)
    top_ring = []
    for j in range(segs):
        v = grid[-1][j].co
        top_ring.append(bm.verts.new((cx + (v.x - cx) * 0.95, cy + (v.y - cy) * 0.95, v.z + 0.5)))
    grid.append(top_ring)
    zones.append(2.0)
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

    # bolovani prabusiti pe grohotis: blocuri din perete (zona perete, deci
    # culoarea stratului), mai multi si mai mari langa piciorul peretelui
    n_boulders = int(30 + 0.8 * (rx + ry)) if kind != "spire" else 6
    for _ in range(n_boulders):
        a = rng.uniform(0.0, math.tau)
        s = rng.random() ** 1.6                      # 0 = piciorul peretelui
        rw = r_wall(a, 0.0)
        out = skirt * (0.1 + 0.95 * s)
        z = hs * (1.0 - s) ** 1.3 * 0.9
        size = rng.uniform(1.0, 3.4) * (1.0 - 0.5 * s) * (h / 80.0) ** 0.5
        bx, by = cx + math.cos(a) * (rw + out), cy + math.sin(a) * (rw + out)
        res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=size)
        sx, sy, sz = rng.uniform(0.8, 1.5), rng.uniform(0.7, 1.3), rng.uniform(0.5, 0.9)
        ang = rng.uniform(0.0, math.tau)
        for v in res["verts"]:
            lx, ly, lz = v.co.x * sx, v.co.y * sy, v.co.z * sz
            v.co = Vector((bx + lx * math.cos(ang) - ly * math.sin(ang),
                           by + lx * math.sin(ang) + ly * math.cos(ang), z + lz))
            v[zone_layer] = 1.0


def build_near_giants():
    """Planul 0: vezi NEAR_GIANTS. Obiect si material separate (straturi mai dese,
    lac mai apasat), RNG propriu: planurile 1-4 raman bit cu bit cele de dinainte."""
    rng = random.Random(1963)
    bm = bmesh.new()
    zl = bm.verts.layers.float.new("zone")
    for name, az, d, parts in NEAR_GIANTS:
        a = math.radians(az)
        radial = Vector((math.sin(a), math.cos(a), 0.0))   # busola -> Blender XY
        tang = Vector((math.cos(a), -math.sin(a), 0.0))     # spre azimut crescator
        rot = -a                                            # axa lunga tangentiala
        for dx, dr, h, rx, ry, kind in parts:
            c = radial * (d + dr) + tang * dx
            giant(bm, zl, c.x, c.y, h, rx, ry, rng, kind, rot + rng.uniform(-0.12, 0.12))
            dd = c.length
            print("banda: urias %s %s az %.1f d %.0f h %.0f -> %.1f grade"
                  % (name, kind, (math.degrees(math.atan2(c.x, c.y)) % 360.0), dd, h,
                     math.degrees(math.atan2(h - CAM_Z, dd))))
    me = bpy.data.meshes.new("BandNearGiants")
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = False
    ob = bpy.data.objects.new("BandNearGiants", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(rock_material("BandRockNear", strata_scale=0.03,
                                           varnish=0.6, scree_scale=0.2,
                                           haze_k=NEAR_HAZE_K))
    print("banda: plan 0, %d fete" % len(me.polygons))


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

    # Lumina de umplere ORIZONTALA, calda, din partea opusa soarelui (busola 70):
    # in joc, ambientul vine din cerul temei, iar sub orizont cerul e banda insasi
    # (podeaua rosie) — deci fetele din umbra ale stancilor primesc o lumina
    # rosiatica din lateral. Fara ea, fetele umbrite ale uriasilor de pe coama
    # (D, E: soarele e in spatele lor) ieseau masline-cenusii (130, 96, 63) langa
    # stancile 3D rosii. Elevatia 0: pe podeaua plata nu cade nimic, deci
    # culoarea de la imbinare ramane cea masurata.
    fd = bpy.data.lights.new("BandFill", "SUN")
    fd.energy = FILL_STRENGTH
    fd.color = srgb(FILL_COLOR)[:3]
    fd.angle = math.radians(4.0)
    fill = bpy.data.objects.new("BandFill", fd)
    bpy.context.collection.objects.link(fill)
    fa = math.radians(FILL_AZ)
    fill.rotation_euler = (-Vector((math.sin(fa), math.cos(fa), 0.0))).to_track_quat("-Z", "Y").to_euler()

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
build_near_giants()
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
