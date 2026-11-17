"""Randari de control pentru vegetatia San Francisco (val 2) -- din GLB-urile EXPORTATE,
fiecare nod colorat cum il coloreaza jocul:

  *_Trunk, Hydrangea, Garden_Body   atlas: culoarea slotului x AO, luminat (cu umbre)
  *_Core                            Palette.core_material: slot x AO(x CORE_SHADE) x 0,46,
                                    NELUMINAT
  *_Leaves                          assets/shaders/leaf_cards.gdshader, EMULAT: fiecare card
                                    e refacut din GLB (centrul = VERTEX - t1*UV2.x - t2*UV2.y,
                                    t1 = sus x NORMAL), intors spre camera (offsetul in planul
                                    ecranului, rotit cu UV.y), taiat daca normala masei e
                                    intoarsa de la camera (back_cull -0,25), decupat in
                                    punctele shaderului (portat pe textura: aceeasi functie
                                    hash/dot_tone, doua straturi), culoarea = COLOR x
                                    (1 - 0,22 x ton), lambert pe normala masei, FARA umbre
                                    primite si FARA umbra aruncata (ca in joc)
  *_Crown                           ascunsa (WorldProp o ascunde pe arborii pusi ca nod);
                                    apare doar pe randul „de departe" al siluetelor

Moduri (argumentele dupa al doilea `--`):
  --compare       decupare | randare, pe fiecare piesa -> sf_<piesa>.png
  --views         chiparosii din patru unghiuri -> sf_cypress_views.png
  --silhouettes   cei trei chiparosi in negru, din lateral, cu o cutie de masina de 4,2 m;
                  randul de sus infatisarea de aproape, cel de jos cea de departe (Crown)
                  -> sf_cypress_silhouettes.png
  --gamecam       camera de joc peste un drum: palc de 9 chiparosi la 40-120 m pe stanga,
                  arbori de strada din 12 in 12 m pe dreapta, un strat de hortensii si o
                  gradinita langa drum -> sf_plants_gamecam.png
  --all           toate

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_plants.py -- --all

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import bpy
import bmesh
import math
import os
import subprocess
import sys
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view

HERE_P = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE_P)
from verify_glb import load_glb, read_accessor  # noqa: E402

PROJ = os.path.dirname(os.path.dirname(HERE_P))
MODELS = os.path.join(PROJ, "assets", "models", "sanfrancisco")
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "sf_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "sf_fidelity")

PIECES = {
    "sf_cypress_a": "plants/sf_cypress_a.glb",
    "sf_cypress_b": "plants/sf_cypress_b.glb",
    "sf_cypress_c": "plants/sf_cypress_c.glb",
    "sf_street_tree": "plants/sf_street_tree.glb",
    "sf_hydrangea": "plants/sf_hydrangea.glb",
    "sf_hydrangea_blue": "plants/sf_hydrangea_blue.glb",
    "sf_front_garden": "props/sf_front_garden.glb",
}

PALETTE_HEX = [
    "E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
    "BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
    "E54839", "2C82E8", "F2D03C",
    "54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
    "7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
    "E8622D", "D2A0BE",
]
SLOTS_N = 32
CORE_UNLIT_GAIN = 0.46          # Palette.CORE_UNLIT_GAIN

# leaf_cards.gdshader (uniformele implicite)
GRID_MIN, GRID_MAX, FILL, R_MIN, R_MAX, BACK_CULL, SHADE = 4.0, 6.0, 0.88, 0.17, 0.44, -0.25, 0.22
CARD_VARIANTS = 10
TEX_N = 96

# camera de joc (scenes/race/chase_camera.gd)
GC_HEIGHT, GC_DIST, GC_FOV = 10.0, 12.5, 68.0
GC_LOOK_AHEAD, GC_LOOK_HEIGHT = 5.0, 0.4
GC_RES = (1920, 1080)

LIGHT = {}      # lumina scenei curente, pentru cardurile emulate (vezi _set_light)


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _hex_lin(h):
    h = h.lstrip("#")
    return tuple(_srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


# --- materiale ------------------------------------------------------------------

def _new_mat(name):
    mat = bpy.data.materials.get(name)
    if mat is not None:
        bpy.data.materials.remove(mat)
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    return mat, nt


def _flat_material(hex_color):
    """Atlas: slot x AO, Principled mat (lumina si umbrele scenei)."""
    name = "PFlat_" + hex_color
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat, nt = _new_mat(name)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    vcol = nt.nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "AO"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.inputs[6].default_value = _hex_lin(hex_color) + (1.0,)
    nt.links.new(mix.inputs[7], vcol.outputs["Color"])
    nt.links.new(bsdf.inputs["Base Color"], mix.outputs[2])
    return mat


def _core_material(hex_color):
    """Palette.core_material: slot x culoarea de varf x 0,46, NELUMINAT."""
    name = "PCore_" + hex_color
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat, nt = _new_mat(name)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    vcol = nt.nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "AO"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    c = _hex_lin(hex_color)
    mix.inputs[6].default_value = tuple(v * CORE_UNLIT_GAIN for v in c) + (1.0,)
    nt.links.new(mix.inputs[7], vcol.outputs["Color"])
    nt.links.new(em.inputs["Color"], mix.outputs[2])
    em.inputs["Strength"].default_value = 1.0
    nt.links.new(out.inputs["Surface"], em.outputs["Emission"])
    return mat


def _black_material():
    name = "PBlack"
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat, nt = _new_mat(name)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (0.0, 0.0, 0.0, 1.0)
    nt.links.new(out.inputs["Surface"], em.outputs["Emission"])
    return mat


def _plain_material(name, hex_color):
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = _hex_lin(hex_color) + (1.0,)
    bsdf.inputs["Roughness"].default_value = 1.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    return mat


# --- textura punctelor (port din leaf_cards.gdshader) ------------------------------

def _fract(x):
    return x - math.floor(x)


def _hash12(px, py):
    a, b, c = _fract(px * 0.1031), _fract(py * 0.1031), _fract(px * 0.1031)
    d = a * (b + 33.33) + b * (c + 33.33) + c * (a + 33.33)
    a, b, c = a + d, b + d, c + d
    return _fract((a + b) * c)


def _dot_tone(gx, gy, sx, sy, cells):
    fx, fy = _fract(gx), _fract(gy)
    flx, fly = math.floor(gx), math.floor(gy)
    h = _hash12(flx + sx, fly + sy)
    ccx, ccy = (flx + 0.5) / cells - 0.5, (fly + 0.5) / cells - 0.5
    if h > FILL or ccx * ccx + ccy * ccy > 0.13 + 0.10 * _fract(h * 29.7):
        return -1.0
    r = R_MIN + (R_MAX - R_MIN) * _fract(h * 17.31)
    cx = 0.5 + (_fract(h * 113.7) - 0.5) * 2.0 * (0.5 - r)
    cy = 0.5 + (_fract(h * 541.3) - 0.5) * 2.0 * (0.5 - r)
    if math.hypot(fx - cx, fy - cy) > r:
        return -1.0
    return _fract(h * 7919.0)


def _card_textures():
    """CARD_VARIANTS texturi de puncte (RGB = 1 - 0,22 x ton, A = punct sau gol), fiecare cu
    alta samanta si alt numar de celule, ca in shader (samanta = floor(UV * 251))."""
    imgs = []
    for k in range(CARD_VARIANTS):
        name = "PCardDots_%d" % k
        img = bpy.data.images.get(name)
        if img is not None:
            imgs.append(img)
            continue
        u = _fract(0.137 + k * 0.6180339)
        v = _fract(0.71 + k * 0.4142135)
        sx, sy = math.floor(u * 251.0), math.floor(v * 251.0)
        cells = GRID_MIN + (GRID_MAX - GRID_MIN) * _fract(u * 13.7)
        img = bpy.data.images.new(name, TEX_N, TEX_N, alpha=True, float_buffer=False)
        img.colorspace_settings.name = "Non-Color"
        px = [0.0] * (TEX_N * TEX_N * 4)
        for j in range(TEX_N):
            for i in range(TEX_N):
                gx = (i + 0.5) / TEX_N * cells
                gy = (j + 0.5) / TEX_N * cells
                gx2 = gx + 0.28 * math.sin(gy * 1.9 + sx)
                gy2 = gy + 0.28 * math.sin(gx * 1.9 + sy)
                t = _dot_tone(gx2, gy2, sx, sy, cells)
                if t < 0.0:
                    t = _dot_tone(gx2 * 0.83 + 0.37, gy2 * 0.83 + 0.61, sx + 57.0, sy + 113.0,
                                  cells * 0.83)
                o = (j * TEX_N + i) * 4
                if t >= 0.0:
                    g = 1.0 - SHADE * t
                    px[o:o + 4] = [g, g, g, 1.0]
        img.pixels = px
        imgs.append(img)
    return imgs


def _card_materials(silhouette=False):
    """Un material per varianta de textura. Emisie = COLOR x textura x (ambient + soare x
    max(0, N.L)): lambert pe normala masei, fara umbre primite (shaderul are
    `shadows_disabled`). Golurile dintre puncte sunt transparente."""
    imgs = _card_textures()
    mats = []
    for k, img in enumerate(imgs):
        mat, nt = _new_mat("PCards_%d_%s" % (k, "sil" if silhouette else "col"))
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Linear"
        uvn = nt.nodes.new("ShaderNodeUVMap")
        uvn.uv_map = "CardUV"
        nt.links.new(tex.inputs["Vector"], uvn.outputs["UV"])
        mixs = nt.nodes.new("ShaderNodeMixShader")
        transp = nt.nodes.new("ShaderNodeBsdfTransparent")
        em = nt.nodes.new("ShaderNodeEmission")
        gt = nt.nodes.new("ShaderNodeMath")
        gt.operation = "GREATER_THAN"
        gt.inputs[1].default_value = 0.5
        nt.links.new(gt.inputs[0], tex.outputs["Alpha"])
        nt.links.new(mixs.inputs["Fac"], gt.outputs["Value"])
        nt.links.new(mixs.inputs[1], transp.outputs["BSDF"])
        nt.links.new(mixs.inputs[2], em.outputs["Emission"])
        nt.links.new(out.inputs["Surface"], mixs.outputs["Shader"])
        if silhouette:
            em.inputs["Color"].default_value = (0.0, 0.0, 0.0, 1.0)
        else:
            attr = nt.nodes.new("ShaderNodeAttribute")
            attr.attribute_name = "CardCol"
            base = nt.nodes.new("ShaderNodeMix")
            base.data_type = "RGBA"
            base.blend_type = "MULTIPLY"
            base.inputs["Factor"].default_value = 1.0
            nt.links.new(base.inputs[6], attr.outputs["Color"])
            nt.links.new(base.inputs[7], tex.outputs["Color"])
            geo = nt.nodes.new("ShaderNodeNewGeometry")
            dp = nt.nodes.new("ShaderNodeVectorMath")
            dp.operation = "DOT_PRODUCT"
            dp.inputs[1].default_value = LIGHT["to_sun"]
            nt.links.new(dp.inputs[0], geo.outputs["Normal"])
            mx = nt.nodes.new("ShaderNodeMath")
            mx.operation = "MAXIMUM"
            mx.inputs[1].default_value = 0.0
            nt.links.new(mx.inputs[0], dp.outputs["Value"])
            sun = nt.nodes.new("ShaderNodeMix")
            sun.data_type = "RGBA"
            sun.blend_type = "MULTIPLY"
            sun.inputs["Factor"].default_value = 1.0
            sun.inputs[6].default_value = tuple(LIGHT["sun"]) + (1.0,)
            comb = nt.nodes.new("ShaderNodeCombineColor")
            nt.links.new(comb.inputs[0], mx.outputs["Value"])
            nt.links.new(comb.inputs[1], mx.outputs["Value"])
            nt.links.new(comb.inputs[2], mx.outputs["Value"])
            nt.links.new(sun.inputs[7], comb.outputs["Color"])
            add = nt.nodes.new("ShaderNodeMix")
            add.data_type = "RGBA"
            add.blend_type = "ADD"
            add.inputs["Factor"].default_value = 1.0
            add.inputs[6].default_value = tuple(LIGHT["amb"]) + (1.0,)
            nt.links.new(add.inputs[7], sun.outputs[2])
            lit = nt.nodes.new("ShaderNodeMix")
            lit.data_type = "RGBA"
            lit.blend_type = "MULTIPLY"
            lit.inputs["Factor"].default_value = 1.0
            nt.links.new(lit.inputs[6], base.outputs[2])
            nt.links.new(lit.inputs[7], add.outputs[2])
            nt.links.new(em.inputs["Color"], lit.outputs[2])
        mats.append(mat)
    return mats


# --- incarcare ----------------------------------------------------------------------

def _clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)


def _slot_of_poly(me, uv, poly):
    u = uv.data[poly.loop_indices[0]].uv[0]
    return max(0, min(SLOTS_N - 1, int(math.floor(u * SLOTS_N))))


def _tint(obj, kind):
    me = obj.data
    uv = me.uv_layers[0]
    me.materials.clear()
    idx = {}
    for poly in me.polygons:
        slot = _slot_of_poly(me, uv, poly)
        if slot not in idx:
            idx[slot] = len(me.materials)
            hx = PALETTE_HEX[slot]
            me.materials.append(_core_material(hx) if kind == "core" else _flat_material(hx))
        poly.material_index = idx[slot]


def _parse_cards(path, node_name):
    """Cardurile nodului `*_Leaves`, citite direct din GLB (coordonate Godot), intoarse in
    coordonate Blender: (centru, normala masei, hw, hh, culoare, samanta)."""
    g, blob = load_glb(path)[:2]
    for n in g["nodes"]:
        if n.get("name") != node_name or "mesh" not in n:
            continue
        cards = {}
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            a = prim["attributes"]
            P = read_accessor(g, blob, a["POSITION"])
            N = read_accessor(g, blob, a["NORMAL"])
            U0 = read_accessor(g, blob, a["TEXCOORD_0"])
            U1 = read_accessor(g, blob, a["TEXCOORD_1"])
            C = read_accessor(g, blob, a["COLOR_0"])
            acc = g["accessors"][a["COLOR_0"]]
            div = {5121: 255.0, 5123: 65535.0}.get(acc["componentType"], 1.0)
            for i in range(len(P)):
                nv = Vector(N[i]).normalized()
                t1 = Vector((0.0, 1.0, 0.0)).cross(nv).normalized()
                t2 = nv.cross(t1)
                c = Vector(P[i]) - t1 * U1[i][0] - t2 * U1[i][1]
                key = (round(U0[i][0], 6), round(U0[i][1], 6))
                d = cards.setdefault(key, {"c": Vector(), "n": nv, "k": 0, "hw": 0.0, "hh": 0.0,
                                           "col": tuple(C[i][j] / div for j in range(3))})
                d["c"] += c
                d["k"] += 1
                d["hw"] = max(d["hw"], abs(U1[i][0]))
                d["hh"] = max(d["hh"], abs(U1[i][1]))
        out = []
        for (u, v), d in cards.items():
            cg = d["c"] / d["k"]
            ng = d["n"]
            out.append((Vector((cg.x, -cg.z, cg.y)), Vector((ng.x, -ng.z, ng.y)),
                        d["hw"], d["hh"], d["col"], (u, v)))
        return out
    return []


def _load(key):
    """Importa piesa o data. Intoarce {"objs": [obiecte randabile], "proxy": Leaves (doar
    pentru incadrare), "crown": Crown, "cards": [...]}."""
    path = os.path.join(MODELS, *PIECES[key].split("/"))
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    out = {"objs": [], "proxy": None, "crown": None, "cards": None, "key": key}
    for o in new:
        if o.type != "MESH":
            continue
        attrs = o.data.attributes
        if "AO" not in attrs and "Color" in attrs:
            attrs["Color"].name = "AO"
        o.rotation_mode = "XYZ"
        nm = o.name.split(".")[0]
        o["pkey"] = key
        if nm.endswith("_Leaves"):
            out["proxy"] = o
            o.hide_render = True
            out["cards"] = _parse_cards(path, nm)
        elif nm.endswith("_Crown"):
            _tint(o, "flat")
            out["crown"] = o
            o.hide_render = True
        elif nm.endswith("_Core"):
            _tint(o, "core")
            out["objs"].append(o)
        else:
            _tint(o, "flat")
            out["objs"].append(o)
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    return out


def _instance(piece, loc, yaw=0.0, far=False):
    """Copii (date partajate) ale obiectelor randabile, puse la loc/yaw. Intoarce
    (obiecte, matricea instantei). far=True: Crown in loc de miez + carduri."""
    M = Matrix.Translation(Vector(loc)) @ Matrix.Rotation(yaw, 4, "Z")
    src = list(piece["objs"])
    if far:
        src = [o for o in src if not o.name.split(".")[0].endswith("_Core")]
        if piece["crown"] is not None:
            src.append(piece["crown"])
    objs = []
    for o in src:
        c = o.copy()
        bpy.context.scene.collection.objects.link(c)
        c.matrix_world = M
        c.hide_render = False
        c["inst"] = True
        objs.append(c)
    return objs, M


def _cards_object(items, cam, silhouette=False, name="PCards"):
    """items: [(cards, M)]. Construieste cardurile intoarse spre `cam`, in coordonate de
    lume, cu normala masei ca normala de umbrire (ca in shader)."""
    bpy.context.view_layer.update()
    cm = cam.matrix_world
    cam_pos = cm.to_translation()
    R = (cm.to_3x3() @ Vector((1.0, 0.0, 0.0))).normalized()
    U = (cm.to_3x3() @ Vector((0.0, 1.0, 0.0))).normalized()
    ortho = cam.data.type == "ORTHO"
    fwd = (cm.to_3x3() @ Vector((0.0, 0.0, -1.0))).normalized()
    bm = bmesh.new()
    col_l = bm.loops.layers.color.new("CardColL")
    uv_l = bm.loops.layers.uv.new("CardUV")
    normals = []
    colors = []
    for cards, M in items:
        R3 = M.to_3x3()
        for (c, n, hw, hh, col, seed) in cards:
            cw = M @ c
            nw = (R3 @ n).normalized()
            to_cam = -fwd if ortho else (cam_pos - cw).normalized()
            if nw.dot(to_cam) < BACK_CULL:
                continue
            a = seed[1] * 2.0 * math.pi
            ca, sa = math.cos(a), math.sin(a)
            var = int(_fract(seed[0] * 7.31 + seed[1] * 3.17) * CARD_VARIANTS) % CARD_VARIANTS
            vs = []
            for (sx, sy) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                ox, oy = hw * sx, hh * sy
                rx, ry = ca * ox - sa * oy, sa * ox + ca * oy
                vs.append(bm.verts.new(cw + R * rx + U * ry))
                normals.append(nw)
            f = bm.faces.new(vs)
            f.material_index = var
            for lp, (sx, sy) in zip(f.loops, ((-1, -1), (1, -1), (1, 1), (-1, 1))):
                lp[uv_l].uv = ((sx + 1) * 0.5, (sy + 1) * 0.5)
                lp[col_l] = (col[0], col[1], col[2], 1.0)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    # culoarea pe varf (atribut de punct) -- shaderul de previzualizare citeste "CardCol"
    lc = me.color_attributes.get("CardColL")
    pc = me.color_attributes.new(name="CardCol", type="FLOAT_COLOR", domain="POINT")
    for lp in me.loops:
        pc.data[lp.vertex_index].color = lc.data[lp.index].color
    me.color_attributes.remove(me.color_attributes.get("CardColL"))
    me.normals_split_custom_set_from_vertices(normals)
    for m in _card_materials(silhouette):
        me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    ob.visible_shadow = False
    ob["inst"] = True
    return ob


# --- scena, camera, lumina ---------------------------------------------------------

def _engine(scene):
    ids = [x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in ids else "BLENDER_EEVEE_NEXT"


def _set_light(sun_dir_from, sun_energy, sun_rgb, sky_hex, sky_strength, fill=None):
    """Soarele si cerul scenei; aceleasi valori ajung in cardurile emulate (LIGHT):
    un difuz alb sub soarele de putere E intoarce E/pi, sub cerul uniform W x s intoarce W x s."""
    scene = bpy.context.scene
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)

    def sun(name, d, e, rgb, angle=2.0):
        data = bpy.data.lights.new(name, type="SUN")
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        data.energy = e
        data.color = rgb
        data.angle = math.radians(angle)
        data.specular_factor = 0.0
        obj.rotation_euler = Vector(d).normalized().to_track_quat("-Z", "Y").to_euler()
        return obj

    d = Vector(sun_dir_from).normalized()
    sun("PSun", d, sun_energy, sun_rgb)
    to_sun = -d
    sunc = Vector(sun_rgb) * (sun_energy / math.pi)
    amb = Vector(_hex_lin(sky_hex)) * sky_strength
    if fill is not None:
        fd, fe = fill
        sun("PFill", fd, fe, (1.0, 1.0, 1.0)).data.use_shadow = False
        fdv = -Vector(fd).normalized()
        # umplerea e aproape frontala: o aproximam in ambient pe fata spre ea (medie 0,5)
        amb = amb + Vector((1.0, 1.0, 1.0)) * (fe / math.pi) * 0.5
    world = scene.world or bpy.data.worlds.new("PWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin(sky_hex) + (1.0,)
        bg.inputs[1].default_value = sky_strength
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_percentage = 100
    LIGHT.clear()
    LIGHT.update({"to_sun": tuple(to_sun), "sun": tuple(sunc), "amb": tuple(amb)})


def _dir_from(az_deg, elev_deg):
    """Directia in care CURGE lumina, pentru un soare aflat la azimutul/elevatia date."""
    a, e = math.radians(az_deg), math.radians(elev_deg)
    return (-math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), -math.sin(e))


def _cam():
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _corners(objs):
    return [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]


def _frame(frame_objs, azimuth, elevation, lens, margin, res_height, aspect, ortho=False):
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    corners = _corners(frame_objs)
    lo = Vector([min(p[i] for p in corners) for i in range(3)])
    hi = Vector([max(p[i] for p in corners) for i in range(3)])
    center = (lo + hi) * 0.5
    scene.render.resolution_x, scene.render.resolution_y = int(res_height * aspect), res_height
    cam = _cam()
    cam.data.sensor_fit = "AUTO"
    cam.data.type = "ORTHO" if ortho else "PERSP"
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 3000.0
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))

    def place(d):
        cam.location = center + dirv * d
        look = (center - cam.location).normalized()
        up = "Y" if abs(look.z) < 0.99 else "X"
        cam.rotation_euler = look.to_track_quat("-Z", up).to_euler()
        bpy.context.view_layer.update()

    def ext():
        vs = [world_to_camera_view(scene, cam, p) for p in corners]
        ex = max(max(v.x for v in vs) - 0.5, 0.5 - min(v.x for v in vs)) * 2
        ey = max(max(v.y for v in vs) - 0.5, 0.5 - min(v.y for v in vs)) * 2
        return max(ex, ey) * margin

    if ortho:
        place(200.0)
        lo_s, hi_s = 0.1, 200.0
        for _ in range(40):
            mid = (lo_s + hi_s) * 0.5
            cam.data.ortho_scale = mid
            bpy.context.view_layer.update()
            if ext() > 1.0:
                lo_s = mid
            else:
                hi_s = mid
        cam.data.ortho_scale = hi_s
    else:
        lo_d, hi_d = 1.0, 5000.0
        for _ in range(40):
            mid = (lo_d + hi_d) * 0.5
            place(mid)
            if ext() > 1.0:
                lo_d = mid
            else:
                hi_d = mid
        place(hi_d)
    return cam


def _shot(path, transparent=True):
    scene = bpy.context.scene
    scene.render.film_transparent = transparent
    scene.render.image_settings.color_mode = "RGBA" if transparent else "RGB"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def _only(visible):
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in visible


def _drop_instances():
    for o in list(bpy.data.objects):
        if o.get("inst"):
            me = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if me is not None and me.users == 0 and me.name.startswith("PCards"):
                bpy.data.meshes.remove(me)


def _compose(args):
    script = os.path.join(HERE_P, "compose_sf_plants.py")
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + args, capture_output=True, text=True)
            if r.returncode == 0:
                print(r.stdout.strip())
                return True
            print("compose a esuat:", r.stderr.strip())
        except FileNotFoundError:
            continue
    return False


def _rm(*paths):
    for p in paths:
        try:
            os.remove(p)
        except OSError:
            pass


def _studio(azimuth):
    """Lumina de studio pentru comparatii: soare din fata-stanga sus, cer gri deschis."""
    _set_light(_dir_from(azimuth + 35.0, 42.0), 3.2, (1.0, 0.97, 0.92), "CCCCCC", 0.62,
               fill=(_dir_from(azimuth - 100.0, 35.0), 0.8))


def _piece_shot(key, out, azimuth, elevation, lens=50.0, aspect=1.2, res_height=820,
                margin=1.10, extra=()):
    _clear()
    p = _load(key)
    objs, M = _instance(p, (0.0, 0.0, 0.0))
    frame = objs + ([p["proxy"]] if p["proxy"] is not None else [])
    _studio(azimuth)
    cam = _frame(frame, azimuth, elevation, lens, margin, res_height, aspect)
    vis = list(objs)
    if p["cards"]:
        vis.append(_cards_object([(p["cards"], M)], cam))
    _only(vis + list(extra))
    return _shot(out)


# --- moduri ------------------------------------------------------------------------

def compare(only_cypress=False):
    """`--cypress` in plus: doar comparatiile chiparosilor (restul pieselor a fost acceptat)."""
    os.makedirs(FID_DIR, exist_ok=True)
    jobs = [
        ("sf_cypress_a", "sf_cypress_a", dict(azimuth=-82.0, elevation=8.0, aspect=1.5)),
        ("sf_cypress_b", "sf_cypress_b", dict(azimuth=-85.0, elevation=8.0, aspect=1.6)),
        ("sf_cypress_c", "sf_cypress_c", dict(azimuth=-82.0, elevation=8.0, aspect=1.4)),
        ("sf_street_tree", "sf_street_tree", dict(azimuth=-70.0, elevation=10.0, aspect=1.0)),
    ]
    if only_cypress:
        jobs = jobs[:3]
    for key, crop, cam in jobs:
        tmp = os.path.join(FID_DIR, "_r_%s.png" % key)
        _piece_shot(key, tmp, **cam)
        _compose(["--compare", "--crop", os.path.join(CROPS, crop + ".png"), "--render", tmp,
                  "--out", os.path.join(FID_DIR, key + ".png"), "--height", "700"])
        _rm(tmp)
    if only_cypress:
        return
    # hortensia: roz, albastra (3/4 ca decuparea) si cum se vede de la 10 m de sus
    tmps = []
    for key in ("sf_hydrangea", "sf_hydrangea_blue"):
        t = os.path.join(FID_DIR, "_r_%s.png" % key)
        _piece_shot(key, t, azimuth=-70.0, elevation=24.0, aspect=1.55, res_height=520)
        tmps.append(t)
    _clear()
    pa, pb = _load("sf_hydrangea"), _load("sf_hydrangea_blue")
    objs = []
    for k in range(6):
        src = pa if k % 3 != 1 else pb
        o, _ = _instance(src, (k * 1.05 - 2.6, (k % 2) * 0.5, 0.0), yaw=k * 1.3)
        objs += o
    t = os.path.join(FID_DIR, "_r_hyd_top.png")
    _studio(-70.0)
    cam = _cam()
    cam.data.type = "PERSP"
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    # camera de joc (10 m sus), tufele la ~15 m in plan; cadrul 1920x1080 TAIAT in jurul
    # tufelor (pixeli nativi, apoi marit la inaltimea plansei)
    scene = bpy.context.scene
    cam.location = Vector((0.0, -15.0, GC_HEIGHT))
    cam.rotation_euler = (Vector((0.0, -15.0 + GC_DIST + GC_LOOK_AHEAD, GC_LOOK_HEIGHT))
                          - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = GC_RES
    bpy.context.view_layer.update()
    vs = [world_to_camera_view(scene, cam, p) for p in _corners(objs)]
    scene.render.use_border = True
    scene.render.use_crop_to_border = True
    scene.render.border_min_x = max(0.0, min(v.x for v in vs) - 0.01)
    scene.render.border_max_x = min(1.0, max(v.x for v in vs) + 0.01)
    scene.render.border_min_y = max(0.0, min(v.y for v in vs) - 0.02)
    scene.render.border_max_y = min(1.0, max(v.y for v in vs) + 0.02)
    _only(objs)
    _shot(t)
    scene.render.use_border = False
    scene.render.use_crop_to_border = False
    tmps.append(t)
    m = os.path.join(FID_DIR, "_r_hyd_m.png")
    _compose(["--grid", ",".join(tmps), "--cols", "3", "--cell-h", "520",
              "--labels", "roz (sf_hydrangea),albastra (sf_hydrangea_blue),"
                          "6 tufe din camera de joc la ~18 m (pixeli nativi, marit)",
              "--out", m])
    _compose(["--compare", "--crop", os.path.join(CROPS, "sf_hydrangea.png"), "--render", m,
              "--out", os.path.join(FID_DIR, "sf_hydrangea.png"), "--height", "520"])
    _rm(m, *tmps)
    # gradinita: privita dinspre casa (ca decuparea) si dinspre strada
    t1 = os.path.join(FID_DIR, "_r_g1.png")
    t2 = os.path.join(FID_DIR, "_r_g2.png")
    _piece_shot("sf_front_garden", t1, azimuth=-112.0, elevation=34.0, aspect=1.7, res_height=520)
    _piece_shot("sf_front_garden", t2, azimuth=68.0, elevation=30.0, aspect=1.7, res_height=520)
    m = os.path.join(FID_DIR, "_r_g_m.png")
    _compose(["--grid", t1 + "," + t2, "--cols", "1",
              "--labels", "dinspre casa (unghiul decuparii),dinspre strada (Godot -Z)", "--out", m])
    _compose(["--compare", "--crop", os.path.join(CROPS, "sf_front_garden.png"), "--render", m,
              "--out", os.path.join(FID_DIR, "sf_front_garden.png"), "--height", "760"])
    _rm(t1, t2, m)


def views():
    os.makedirs(FID_DIR, exist_ok=True)
    outs, labels = [], []
    shots = [("lateral (vantul spre dreapta)", -90.0, 4.0), ("din capatul din vant (-X)", 180.0, 6.0),
             ("3/4 din spate", 125.0, 22.0), ("de sus", -90.0, 89.0)]
    for key in ("sf_cypress_a", "sf_cypress_b", "sf_cypress_c"):
        for lab, az, el in shots:
            p = os.path.join(FID_DIR, "_v_%s_%d.png" % (key, len(outs)))
            _piece_shot(key, p, azimuth=az, elevation=el, aspect=1.15, res_height=520)
            outs.append(p)
            labels.append("%s %s" % (key[-1], lab))
    _compose(["--grid", ",".join(outs), "--cols", "4", "--cell-h", "520", "--labels", ",".join(labels),
              "--out", os.path.join(FID_DIR, "sf_cypress_views.png")])
    _rm(*outs)


def silhouettes():
    os.makedirs(FID_DIR, exist_ok=True)
    rows = []
    for far in (False, True):
        _clear()
        pieces = [_load(k) for k in ("sf_cypress_a", "sf_cypress_b", "sf_cypress_c")]
        black = _black_material()
        items, frame, vis = [], [], []
        x = 0.0
        for k, p in enumerate(pieces):
            objs, M = _instance(p, (x, 0.0, 0.0), far=far)
            for o in objs:
                o.data = o.data.copy()
                o.data.materials.clear()
                o.data.materials.append(black)
                for poly in o.data.polygons:
                    poly.material_index = 0
            vis += objs
            frame += objs
            if p["proxy"] is not None:      # cardurile ies din cutia trunchiului: incadreaza-le
                px = p["proxy"].copy()
                bpy.context.scene.collection.objects.link(px)
                px.matrix_world = M
                px["inst"] = True
                frame.append(px)
            if not far and p["cards"]:
                items.append((p["cards"], M))
            # cutia de masina de 4,2 m, langa trunchi, pe sol
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x - 4.6, -3.0, 0.7))
            car = bpy.context.active_object
            car.scale = (4.2, 1.8, 1.4)
            car.data.materials.append(black)
            car["inst"] = True
            vis.append(car)
            frame.append(car)
            x += 14.5
        _set_light(_dir_from(-60.0, 40.0), 1.0, (1.0, 1.0, 1.0), "FFFFFF", 1.0)
        cam = _frame(frame, -90.0, 2.0, 200.0, 1.04, 520, 3.2)
        if items:
            vis.append(_cards_object(items, cam, silhouette=True, name="PCardsSil"))
        _only(vis)
        p = os.path.join(FID_DIR, "_sil_%d.png" % int(far))
        _shot(p, transparent=False)
        rows.append(p)
    _compose(["--grid", ",".join(rows), "--cols", "1",
              "--labels", "de aproape (trunchi + miez + carduri) -- a | b | c -- cutia = masina de 4,2 m,"
                          "de departe (trunchi + Crown; doar in MeshForest)",
              "--out", os.path.join(FID_DIR, "sf_cypress_silhouettes.png")])
    _rm(*rows)


def _box(name, loc, size, hexc, rot=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    o.rotation_euler = (0.0, 0.0, rot)
    o.data.materials.append(_plain_material("PPlain_" + hexc, hexc))
    o["inst"] = True
    return o


def gamecam():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    scene = bpy.context.scene
    P = {k: _load(k) for k in PIECES}
    env = []
    # drumul (x -5..5) spre +Y, trotuarul din dreapta, parcul din stanga
    env.append(_box("GRoad", (0.0, 120.0, -0.1), (10.0, 320.0, 0.2), "55565A"))
    for k in range(40):
        env.append(_box("GMark", (0.0, -10.0 + k * 8.0, 0.005), (0.15, 3.0, 0.01), "D8D4C8"))
    env.append(_box("GWalkR", (6.75, 120.0, 0.0), (3.5, 320.0, 0.24), "B8B2A6"))
    env.append(_box("GWalkL", (-6.0, 120.0, 0.0), (2.0, 320.0, 0.24), "B8B2A6"))
    env.append(_box("GPark", (-90.0, 120.0, -0.05), (166.0, 320.0, 0.2), "6F8A47"))
    env.append(_box("GYards", (60.0, 120.0, -0.05), (100.0, 320.0, 0.2), "8F9A6A"))
    # stratul de hortensii: zid jos de caramida langa trotuarul stang
    env.append(_box("GBed", (-7.9, 36.0, 0.2), (1.6, 28.0, 0.4), "9A4A36"))
    # casele din dreapta (fatade pastel), retrase dupa gradinite
    pastels = ["E9DCC0", "D9A9B4", "9FB6C9", "A9CBB2", "E8D48F"]
    for k in range(22):
        y = -6.0 + k * 7.0
        env.append(_box("GHouse", (17.5, y + 3.5, 4.8), (12.0, 6.9, 9.6), pastels[k % 5]))
    objs = list(env)
    items = []

    def put(key, loc, yaw=0.0):
        o, M = _instance(P[key], loc, yaw)
        objs.extend(o)
        if P[key]["cards"]:
            items.append((P[key]["cards"], M))
        return o

    # palcul de chiparosi: 40-120 m in fata, pe stanga, toti aplecati spre +X (acelasi vant)
    grove = [("a", -15, 42), ("b", -27, 50), ("c", -19, 62), ("a", -35, 70), ("c", -14, 82),
             ("b", -28, 90), ("a", -41, 98), ("c", -21, 108), ("b", -32, 118)]
    near_cyp = None
    for k, (v, x, y) in enumerate(grove):
        o = put("sf_cypress_" + v, (x, y, 0.0), yaw=math.radians((-8, 5, -3, 9, -6, 2, 7, -4, 4)[k]))
        if near_cyp is None:
            near_cyp = o
    # arborii de strada: din 12 in 12 m pe trotuarul din dreapta
    street = []
    for k in range(13):
        street.append(put("sf_street_tree", (6.9, 6.0 + 12.0 * k, 0.12), yaw=k * 1.1))
    # hortensiile: doua randuri pe strat
    hyd = []
    for k in range(26):
        key = "sf_hydrangea" if (k * 7) % 3 else "sf_hydrangea_blue"
        hyd += put(key, (-8.25 + 0.75 * (k % 2), 23.0 + k * 1.02, 0.4), yaw=k * 2.1)
    # gradinita langa drum, pe stanga (fara arbori de strada care s-o acopere), inaintea
    # stratului de hortensii; strada ei (Godot -Z = Blender +Y local) spre drum: yaw -90
    garden = put("sf_front_garden", (-8.6, 14.0, 0.12), yaw=math.radians(-90.0))
    # masina jucatorului
    car = _box("GCar", (0.0, 0.0, 0.7), (1.9, 4.2, 1.4), "2C82E8")
    objs.append(car)

    # soarele de dupa-amiaza tarzie, din spatele camerei, putin din dreapta
    el, yaw = math.radians(24.0), math.radians(-30.0)
    d = (math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el))
    _set_light(d, 3.4, _hex_lin("FFE2BE"), "A9C3D6", 0.60)
    scene.render.resolution_x, scene.render.resolution_y = GC_RES
    cam = _cam()
    cam.data.type = "PERSP"
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 600.0
    carp = Vector((0.0, 0.0, 0.0))
    cam.location = carp + Vector((0.0, -GC_DIST, GC_HEIGHT))
    target = carp + Vector((0.0, GC_LOOK_AHEAD, GC_LOOK_HEIGHT))
    cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    cards = _cards_object(items, cam)
    objs.append(cards)
    _only(objs)

    def box_of(group, pad=0.0):
        xs, ys = [], []
        for o in group:
            for c in o.bound_box:
                v = world_to_camera_view(scene, cam, o.matrix_world @ Vector(c))
                if v.z > 0:
                    xs.append(v.x)
                    ys.append(1.0 - v.y)
        W, H = GC_RES
        return "%.1f,%.1f,%.1f,%.1f" % (max(min(xs), 0) * W, max(min(ys), 0) * H,
                                        min(max(xs), 1) * W, min(max(ys), 1) * H)

    boxes = [box_of(near_cyp), box_of(street[1] + street[2]), box_of(garden), box_of(hyd[:24])]
    labels = ["chiparos la 42 m (x3)", "arbori de strada la 18-30 m (x3)", "gradinita la 14 m (x3)",
              "hortensiile (x3)"]
    frame = os.path.join(FID_DIR, "_gc.png")
    _shot(frame, transparent=False)
    _compose(["--gamecam", frame, "--boxes", ";".join(boxes), "--labels", ",".join(labels),
              "--out", os.path.join(FID_DIR, "sf_plants_gamecam.png")])
    _rm(frame)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args or "--all" in args:
    compare(only_cypress="--cypress" in args)
if "--views" in args or "--all" in args:
    views()
if "--silhouettes" in args or "--all" in args:
    silhouettes()
if "--gamecam" in args or "--all" in args:
    gamecam()
if not args:
    print(__doc__)
