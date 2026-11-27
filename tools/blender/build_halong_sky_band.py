"""Banda de orizont a cerului Ha Long (Track22) — randata, nu modelata pentru joc.

Ce iese: `assets/textures/sky/halong_horizon_band.png`, o felie equirectangulara
de 360 de grade pe azimut si 22,5 grade pe inaltime (-7,5 .. +15), cu alfa:
turnurile de carst departate, marea pana la orizont si cateva jonci; cerul ramane
TRANSPARENT, fiindca gradientul lui il deseneaza shaderul de cer din joc
(`scenes/tracks/sky_band.gdshader`). Banda e lipita de cer, deci sta la infinit:
nu intra in frustum, nu costa triunghiuri si nu e taiata de FAR_PLANE (380 m).

De ce randare si nu GLB-uri de orizont: turnurile din banda stau la 0,65-6,5 km.
Acolo nu mai exista paralaxa intre ele pe un circuit de 600 m, deci geometria
reala ar fi doar cost. In schimb randarea poate avea ce nu-si permite jocul:
mii de coroane de copaci pe creste, perspectiva aeriana pe fiecare plan si ceata
joasa intre baze (mùa nồm, brief §1.4) — exact ce face golful din referinta.

Contractul cu jocul (schimbi unul, schimbi si celalalt):
  * camera la 10 m peste mare, in origine; u = 0,5 priveste spre NORD
    (Godot -Z = Blender +Y), estul e la u = 0,75 — aceeasi formula ca in shader
    (`atan(x, -z) / TAU + 0.5`);
  * latitudinea -7,5 .. +15 grade, pixeli patrati (8192 x 512);
  * soarele din tema "halong" (`sun_rotation_deg` (-18, 70, 0), adica busola
    110, 18 grade elevatie), aceeasi culoare si energie, acelasi ambient;
  * HAZE = `sky_horizon` din tema: departarea se topeste exact in culoarea pe
    care o deseneaza cerul din joc in spatele benzii, deci marginea benzii nu
    se vede;
  * transformarea de vedere "Standard" (fara tonemap): tonemap-ul il aplica
    Godot, o singura data, peste cer si banda deodata.

Rulare (headless; `--test` = randare mica, cu marcaje pe punctele cardinale,
pentru verificarea orientarii):
    mkdir D:/GameDev/.render_lock && \
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_halong_sky_band.py [-- --test]
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
                   "halong_horizon_band_test.png" if TEST else "halong_horizon_band.png")


def srgb(hexstr, k=1.0):
    """Culoare sRGB hex -> liniar (intrarile de culoare din noduri sunt liniare)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        c = c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
        out.append(c * k)
    return (out[0], out[1], out[2], 1.0)


# --- Paleta (sRGB, ca in tema) ------------------------------------------------
HAZE = "DCE5E3"          # = sky_horizon din tema: departarea intra in cer
MIST = "E6ECEA"          # ceata joasa dintre baze, un pic mai alba decat aerul
SEA_NEAR = "3F9A92"      # marea la ~300 m: turcoaz-jad, se spala spre HAZE
ROCK_LIGHT = "C9C3B3"    # calcar in soare (MARBLE_GREY tras spre crem)
ROCK_DARK = "8E8A7F"
ROCK_STREAK = "6F6B62"   # dungile verticale de scurgere
MOSS = "5D7A3E"
VEG = ["2F5426", "3F6B2E", "4E7F33", "62903C", "3A5F2A"]
SUN_COLOR = "FFE3B8"     # Color(1.0, 0.89, 0.72) din tema
SUN_ENERGY = 1.35
AMBIENT = "D6CBB4"
AMBIENT_ENERGY = 0.34

HAZE_D0, HAZE_D = 300.0, 4200.0          # perspectiva aeriana: 1 - exp(-(d-d0)/D)
MIST_H, MIST_K = 20.0, 0.5                # ceata joasa: K * exp(-z/H)


# --- Scena ---------------------------------------------------------------------

def reset():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.node_groups):
        for b in list(coll):
            coll.remove(b)


def haze_wrap(nt, surface_socket, out_node):
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
    keep_air = x                                              # 1 - fac_aer
    z = math_node("MAXIMUM", sep.outputs[2], vb=0.0)
    z = math_node("MULTIPLY", z, vb=-1.0 / MIST_H)
    z = math_node("EXPONENT", z)
    ramp = n.new("ShaderNodeMapRange")                        # ceata doar departe
    L.new(d, ramp.inputs["Value"])
    ramp.inputs["From Min"].default_value = 400.0
    ramp.inputs["From Max"].default_value = 1200.0
    mist = math_node("MULTIPLY", z, ramp.outputs["Result"])
    mist = math_node("MULTIPLY", mist, vb=MIST_K)
    keep_mist = math_node("SUBTRACT", va=1.0, b=mist)
    keep = math_node("MULTIPLY", keep_air, keep_mist)
    fac = math_node("SUBTRACT", va=1.0, b=keep)
    # culoarea de amestec: HAZE sus, MIST jos, dupa ponderea cetii
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


def new_material(name):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    return mat, nt, out


def rock_material():
    mat, nt, out = new_material("BandRock")
    n, L = nt.nodes, nt.links
    tc = n.new("ShaderNodeTexCoord")
    mp = n.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.08, 0.08, 0.012)    # dungi VERTICALE
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = n.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 3.0
    nz.inputs["Detail"].default_value = 6.0
    L.new(mp.outputs[0], nz.inputs["Vector"])
    cr = n.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    els[0].position, els[0].color = 0.30, srgb(ROCK_STREAK)
    els[1].position, els[1].color = 0.62, srgb(ROCK_LIGHT)
    mid = els.new(0.45)
    mid.color = srgb(ROCK_DARK)
    L.new(nz.outputs["Fac"], cr.inputs["Fac"])
    # muschi pe fetele care privesc in sus (corniche), petic cu zgomot
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    L.new(geo.outputs["Normal"], sep.inputs[0])
    mr = n.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = 0.25
    mr.inputs["From Max"].default_value = 0.6
    L.new(sep.outputs[2], mr.inputs["Value"])
    cmix = n.new("ShaderNodeMix")
    cmix.data_type = "RGBA"
    L.new(mr.outputs["Result"], cmix.inputs[0])
    L.new(cr.outputs["Color"], cmix.inputs[6])
    cmix.inputs[7].default_value = srgb(MOSS)
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.92
    bsdf.inputs["Specular IOR Level"].default_value = 0.1
    L.new(cmix.outputs[2], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def veg_material():
    mat, nt, out = new_material("BandVeg")
    n, L = nt.nodes, nt.links
    oi = n.new("ShaderNodeObjectInfo")
    cr = n.new("ShaderNodeValToRGB")
    els = cr.color_ramp.elements
    els[0].position, els[0].color = 0.0, srgb(VEG[0])
    els[1].position, els[1].color = 1.0, srgb(VEG[3])
    for i, c in enumerate((VEG[1], VEG[4], VEG[2])):
        e = els.new(0.25 + 0.25 * i)
        e.color = srgb(c)
    L.new(oi.outputs["Random"], cr.inputs["Fac"])
    bsdf = n.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    L.new(cr.outputs["Color"], bsdf.inputs["Base Color"])
    haze_wrap(nt, bsdf.outputs[0], out)
    return mat


def sea_material():
    """Marea e NEILUMINATA: culoarea ei la ~300 m, spalata apoi de acelasi aer
    ca turnurile. Jocul are apa lui pana la 340 m; banda incepe unde se termina
    ea, deci aici conteaza doar cum se topeste in orizont."""
    mat, nt, out = new_material("BandSea")
    n, L = nt.nodes, nt.links
    em = n.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = srgb(SEA_NEAR)
    haze_wrap(nt, em.outputs[0], out)
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


# --- Turnul de carst -------------------------------------------------------------

def smooth01(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def tower(bm, cx, cy, h, r, rng, veg_pts):
    """Un turn: inele cu raza modulata (nisa la baza, burta, dom rotunjit) si
    zgomot pe unghi (lobi mari + caneluri verticale), apoi coroane pe ce priveste
    in sus. Varfurile intra direct in `bm`, in coordonate de lume."""
    seed = rng.random() * 100.0
    segs = 56
    rings = max(14, int(h / 3.0))
    bulge = rng.uniform(-0.04, 0.16)
    taper = rng.uniform(0.0, 0.28)
    dome = rng.uniform(0.14, 0.3)
    # Creasta: varful nu e o cupola, e o linie zimtata cu sei si doua-trei
    # varfuri (masivele late mai mult). Amplitudinea e o fractie din inaltime.
    crest = rng.uniform(0.10, 0.22) * (1.6 if r > 0.45 * h else 1.0)
    if rng.random() < 0.25:                   # con: se ingusteaza spre un ac
        taper, dome = rng.uniform(0.45, 0.65), rng.uniform(0.08, 0.16)
    notch = rng.uniform(0.72, 0.86)
    lean = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), 0.0)) * rng.uniform(0.0, 0.12) * h
    z0 = -6.0
    grid = []
    for i in range(rings + 1):
        t = i / rings
        z = z0 + t * (h - z0)
        prof = notch + (1.0 - notch) * smooth01(0.0, 0.09, t)
        prof *= 1.0 + bulge * math.sin(math.pi * t)
        prof *= 1.0 - taper * t
        if t > 1.0 - dome:
            s = (t - (1.0 - dome)) / dome
            prof *= math.sqrt(max(0.0, 1.0 - s * s * 0.97))
        c = Vector((cx, cy, 0.0)) + lean * (t * t)
        ring = []
        for j in range(segs):
            a = j / segs * math.tau
            ca, sa = math.cos(a), math.sin(a)
            lobe = noise.noise(Vector((ca * 1.2 + seed, sa * 1.2, t * h / (r * 2.2))))
            flute = noise.noise(Vector((ca * 7.0, sa * 7.0 + seed, t * h / 90.0)))
            ledge = noise.noise(Vector((ca * 2.5, sa * 2.5, t * h / 9.0 + seed)))
            rr = r * prof * (1.0 + 0.30 * lobe + 0.08 * flute + 0.05 * ledge)
            zz = z
            if t > 1.0 - dome * 1.6:
                s2 = (t - (1.0 - dome * 1.6)) / (dome * 1.6)
                peak = noise.noise(Vector((ca * 1.6, sa * 1.6, seed * 0.37)))
                zz = z + crest * h * s2 * peak
            ring.append(bm.verts.new((c.x + ca * rr, c.y + sa * rr, zz)))
        grid.append(ring)
    top = bm.verts.new((cx + lean.x, cy + lean.y, sum(v.co.z for v in grid[-1]) / segs + 0.5))
    faces = []
    for i in range(rings):
        for j in range(segs):
            k = (j + 1) % segs
            faces.append(bm.faces.new((grid[i][j], grid[i][k], grid[i + 1][k], grid[i + 1][j])))
    for j in range(segs):
        faces.append(bm.faces.new((grid[-1][j], grid[-1][(j + 1) % segs], top)))
    # coroane: densitate pe metru patrat, ponderata de cat priveste fata in sus
    for f in faces:
        f.normal_update()
        nz = f.normal.z
        cen = f.calc_center_median()
        t = (cen.z - z0) / (h - z0)
        if t < 0.1:
            continue
        w = smooth01(0.2, 0.65, nz) + 0.35 * smooth01(0.82, 0.96, t)
        patch = noise.noise(Vector((cen.x / 14.0, cen.y / 14.0, cen.z / 10.0 + seed)))
        if nz < 0.2 and patch > 0.25:
            w += 0.18                                        # agatatoare pe perete
        if w <= 0.01:
            continue
        expect = f.calc_area() * w / 9.0                     # ~1 coroana / 9 m2
        cnt = int(expect) + (1 if rng.random() < expect - int(expect) else 0)
        vs = [v.co for v in f.verts]
        for _ in range(cnt):
            a, b = rng.random(), rng.random()
            if a + b > 1.0:
                a, b = 1.0 - a, 1.0 - b
            p = vs[0] + (vs[1] - vs[0]) * a + (vs[2] - vs[0]) * b
            size = rng.uniform(1.8, 3.6) * (0.8 + 0.4 * min(1.0, h / 120.0))
            p = p + f.normal * size * 0.45
            veg_pts.append((p, size, rng.random() * math.tau))


def build_karsts(rng):
    """Trei planuri, grupate in ciorchini (golful nu e o padure uniforma de
    turnuri), cu GOLURI pe azimut unde se vede marea deschisa pana la orizont."""
    bm = bmesh.new()
    veg = []
    gaps = [(-20.0, 18.0), (95.0, 140.0), (200.0, 228.0)]    # grade, busola-ish

    def in_gap(az_deg):
        a = az_deg % 360.0
        return any(lo <= a <= hi or lo <= a - 360.0 <= hi for lo, hi in gaps)

    layers = [  # (d_min, d_max, ciorchini, turnuri/ciorchine, h_min, h_max)
        # Camera de joc tine orizontul in sfertul de sus al cadrului: deasupra
        # lui se vad ~5-6 grade. Inaltimile sunt alese ca majoritatea siluetelor
        # (creste cu coroane) sa intre intregi in fereastra asta; cateva turnuri
        # apropiate ies din cadru, si dau scara.
        (650.0, 1300.0, 9, (2, 5), 45.0, 115.0),
        (1300.0, 2800.0, 12, (3, 7), 60.0, 165.0),
        (2800.0, 6500.0, 14, (4, 9), 80.0, 230.0),
    ]
    n_towers = 0
    for li, (dmin, dmax, nclu, (kmin, kmax), hmin, hmax) in enumerate(layers):
        for _ in range(nclu):
            for _try in range(20):
                az = rng.uniform(0.0, 360.0)
                if li == 2 or not in_gap(az):
                    break
            dist = rng.uniform(dmin, dmax)
            spread = dist * rng.uniform(0.05, 0.12)
            for _k in range(rng.randint(kmin, kmax)):
                a = math.radians(az) + rng.uniform(-1, 1) * spread / dist
                d = dist + rng.uniform(-1, 1) * spread
                if li < 2 and in_gap(math.degrees(a)):
                    continue
                # Godot: busola -> directie; aici ne intereseaza doar sa fie
                # consecventa cu camera (u = 0,5 la +Y).
                x, y = math.sin(a) * d, math.cos(a) * d
                h = rng.uniform(hmin, hmax)
                # 40% masive late cu creste (insulele mari ale golfului), restul
                # stalpi: doar stalpi ieseau un sir de capsule identice.
                r = h * (rng.uniform(0.5, 0.95) if rng.random() < 0.4
                         else rng.uniform(0.22, 0.42))
                tower(bm, x, y, h, r, rng, veg)
                n_towers += 1
    me = bpy.data.meshes.new("BandKarsts")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("BandKarsts", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(rock_material())
    print("banda: %d turnuri, %d coroane" % (n_towers, len(veg)))
    return veg


def build_veg(points):
    # coroana: icosfera bosselata, turtita
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    for v in bm.verts:
        k = 1.0 + 0.25 * noise.noise(v.co * 2.3)
        v.co = Vector((v.co.x * k, v.co.y * k, v.co.z * k * 0.75))
    me = bpy.data.meshes.new("BandCrown")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    crown = bpy.data.objects.new("BandCrown", me)
    bpy.context.collection.objects.link(crown)
    crown.data.materials.append(veg_material())
    crown.hide_render = True
    crown.location = (0, 0, -500)

    pm = bpy.data.meshes.new("BandVegPts")
    pm.vertices.add(len(points))
    pm.vertices.foreach_set("co", [c for p, _, _ in points for c in p])
    sc = pm.attributes.new("vscale", "FLOAT_VECTOR", "POINT")
    sc.data.foreach_set("vector", [c for _, s, _ in points
                                   for c in (s, s * random.uniform(0.85, 1.15), s * 0.9)])
    rt = pm.attributes.new("vrot", "FLOAT_VECTOR", "POINT")
    rt.data.foreach_set("vector", [c for _, _, yaw in points for c in (0.0, 0.0, yaw)])
    ob = bpy.data.objects.new("BandVeg", pm)
    bpy.context.collection.objects.link(ob)

    ng = bpy.data.node_groups.new("BandVegScatter", "GeometryNodeTree")
    ng.interface.new_socket("Geometry", in_out="INPUT", socket_type="NodeSocketGeometry")
    ng.interface.new_socket("Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")
    gi = ng.nodes.new("NodeGroupInput")
    go = ng.nodes.new("NodeGroupOutput")
    m2p = ng.nodes.new("GeometryNodeMeshToPoints")
    iop = ng.nodes.new("GeometryNodeInstanceOnPoints")
    oi = ng.nodes.new("GeometryNodeObjectInfo")
    oi.inputs["Object"].default_value = crown
    a_sc = ng.nodes.new("GeometryNodeInputNamedAttribute")
    a_sc.data_type = "FLOAT_VECTOR"
    a_sc.inputs["Name"].default_value = "vscale"
    a_rt = ng.nodes.new("GeometryNodeInputNamedAttribute")
    a_rt.data_type = "FLOAT_VECTOR"
    a_rt.inputs["Name"].default_value = "vrot"
    L = ng.links
    L.new(gi.outputs[0], m2p.inputs["Mesh"])
    L.new(m2p.outputs["Points"], iop.inputs["Points"])
    L.new(oi.outputs["Geometry"], iop.inputs["Instance"])
    L.new(a_sc.outputs["Attribute"], iop.inputs["Scale"])
    L.new(a_rt.outputs["Attribute"], iop.inputs["Rotation"])
    L.new(iop.outputs["Instances"], go.inputs[0])
    mod = ob.modifiers.new("Scatter", "NODES")
    mod.node_group = ng


def build_sea():
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=30000.0)
    me = bpy.data.meshes.new("BandSea")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new("BandSea", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(sea_material())


def build_junks(rng):
    path = os.path.join(MODELS, "halong", "vehicles", "fishing_junk.glb")
    if not os.path.exists(path):
        print("LIPSA: " + path)
        return
    before = set(o.name for o in bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o.name not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        o.data.materials.clear()
    new_names = [o.name for o in new]
    # o singura piesa, cu transformarile aplicate, ca sa se poata copia
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    junk = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    for nm in new_names:
        o = bpy.data.objects.get(nm)
        if o is not None and o != junk:
            bpy.data.objects.remove(o, do_unlink=True)
    junk.data.materials.append(atlas_haze_material())
    spots = []
    for _ in range(7):
        a = rng.uniform(0.0, math.tau)
        d = rng.uniform(480.0, 1400.0)
        spots.append((math.sin(a) * d, math.cos(a) * d, rng.uniform(0.0, math.tau)))
    for i, (x, y, yaw) in enumerate(spots):
        o = junk if i == 0 else junk.copy()
        if i:
            bpy.context.collection.objects.link(o)
        o.location = (x, y, -0.4)
        o.rotation_euler = (0.0, 0.0, yaw)


def sun_dir_blender():
    """to_sun din tema Godot (Basis.from_euler YXZ, lumina pe -Z), in Blender."""
    rx, ry = math.radians(-18.0), math.radians(70.0)
    # Rx * (0,0,1) = (0, -sin rx, cos rx); apoi Ry
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
    cd.clip_end = 40000.0
    cam = bpy.data.objects.new("BandCam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0.0, 0.0, CAM_Z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # priveste spre +Y (nord)
    sc.camera = cam

    ld = bpy.data.lights.new("BandSun", "SUN")
    ld.energy = SUN_ENERGY
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
rng = random.Random(22)
random.seed(22)
setup_render()
build_sea()
veg = build_karsts(rng)
build_veg(veg)
build_junks(rng)
if TEST:
    test_markers()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.render.render(write_still=True)
print("banda: scris %s (%dx%d, lat %.1f..%.1f)" % (OUT, W, H, LAT_MIN, LAT_MAX))
