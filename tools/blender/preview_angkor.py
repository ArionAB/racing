"""Randari de control pentru kitul Angkor -- din GLB-urile EXPORTATE.

Pe tiparul `preview_carrara.py` (kit §0 regula 9). Cubul implicit si tot ce nu
e piesa primesc `hide_render` (memoria blender-preview-cub-implicit).

Moduri (rulate prin run_build.py, argumentele dupa al doilea `--`):

  --compare <nume>   decupare (stanga) | randare din GLB (dreapta), aceeasi
                     inaltime in pixeli, 3/4 din fata, fundal #C4C4C4, culoare
                     REALA: fiecare fata pe culoarea slotului ei din atlas
                     (recuperat din UV); nodurile *_Stone pe tinta clasei
                     `angkor_sandstone` (vezi STONE_HEX). Lumina de zi, din
                     lateral, ca sa se vada relieful.
                     -> docs/asset_briefs/img/angkor_fidelity/<nume>.png
  --views <nume>     4 azimuturi ale piesei -> <nume>_views.png
  --gamecam <nume>   piesa asa cum o vede CAMERA DE JOC: camera la 10 m
                     inaltime si 12,5 m in spatele unui punct aflat la 30 m
                     inaintea piesei, fov vertical 68 grade, privind 5 m
                     inainte de punct la 0,4 m (ChaseCamera: LOOK_AHEAD,
                     LOOK_HEIGHT), soare la 24 grade din spatele camerei
                     (brief angkor.md §4: pe calea de vest mergi spre est cu
                     soarele in spate), baza ingropata 1 m sub terasa (kit
                     §1.1). Doua cadre: turnul pe axa drumului si turnul cu 4 m
                     in dreapta (se vad doua fete). Fiecare cadru e 1920x1080
                     si apare alaturi de decuparea lui la pixeli nativi, de 3x.
                     -> <nume>_gamecam.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor.py -- --compare bayon_face_tower_a

Decuparile: docs/track_briefs/img/angkor_assets_v1/<nume>.png. GLB-ul se cauta
in assets/models/angkor/<categorie>/<nume>.glb. Compunerea de imagini cu PIL e
in compose_angkor.py (Python de sistem; Blender nu are PIL).

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock` (daca esueaza,
alt proces randeaza), dupa, `rmdir`.
"""

import bpy
import math
import os
import re
import subprocess
import sys
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

HERE_P = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE_P))
ALL_MODELS = os.path.join(PROJ, "assets", "models")
MODELS_DIR = os.path.join(ALL_MODELS, "angkor")
CROP_DIRS = [os.path.join(PROJ, "docs", "track_briefs", "img", "angkor_assets_v1")]
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "angkor_fidelity")

# hex-ul sloturilor, identic cu scripts/palette.gd
PALETTE_HEX = [
    "E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
    "BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
    "E54839", "2C82E8", "F2D03C",
    "54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
    "7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
    "E8622D", "D2A0BE",
]
SLOTS_N = 32

# GRESIA, tinta in joc: clasa `angkor_sandstone` = dala `alpine_granite.png` x
# tenta (1,0, 0,86, 0,66) (scripts/palette.gd:744 si :1107). Derivata, nu
# ghicita: media dalei in spatiu LINIAR e (0,4167, 0,3652, 0,2771) (din PNG, cu
# PIL); x tenta = (0,4167, 0,3140, 0,1829) liniar = #AD9877 in sRGB. (Daca tenta
# s-ar aplica direct in sRGB ar iesi #A68660, mai inchis; materialul Godot
# inmulteste in liniar, deci #AD9877.) Palette.gd o numeste provizorie: se
# recalibreaza pe captura pistei.
STONE_HEX = "#AD9877"
CLASS_BY_SUFFIX = {"_Stone": STONE_HEX}

SPECS = {
    "bayon_face_tower_a": {"camera": {"azimuth": 62.0, "elevation": 9.0, "lens": 70.0, "margin": 1.06}},
}

# camera de joc (scenes/race/chase_camera.gd: DEFAULT_HEIGHT/DISTANCE/BASE_FOV/
# LOOK_AHEAD/LOOK_HEIGHT), soarele de la 24 grade (brief angkor.md §4)
GC_HEIGHT, GC_DIST, GC_FOV = 10.0, 12.5, 68.0
GC_LOOK_AHEAD, GC_LOOK_HEIGHT = 5.0, 0.4
GC_PIECE_AHEAD = 30.0          # piesa e la 30 m inaintea punctului (masinii)
GC_BURY = 1.0                  # baza ingropata 1 m sub terasa
GC_SUN_ELEV, GC_SUN_YAW = 24.0, 18.0
GC_RES = (1920, 1080)


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _hex_lin(h):
    h = h.lstrip("#")
    return tuple(_srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def _flat_material(hex_color):
    name = "KFlat_" + hex_color.lstrip("#")
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    r, g, b = _hex_lin(hex_color)
    vcol = nt.nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "AO"
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.inputs[6].default_value = (r, g, b, 1.0)
    nt.links.new(mix.inputs[7], vcol.outputs["Color"])
    nt.links.new(bsdf.inputs["Base Color"], mix.outputs[2])
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


def _per_slot_tint(obj, override_hex=None):
    """Fiecare fata pe culoarea slotului ei (din UV.x colapsat pe centrul
    slotului); `override_hex` (clasa) inlocuieste toate culorile nodului."""
    me = obj.data
    if override_hex:
        me.materials.clear()
        me.materials.append(_flat_material(override_hex))
        return
    uv = me.uv_layers.active
    me.materials.clear()
    if uv is None:
        me.materials.append(_flat_material("#CCCCCC"))
        return
    idx = {}
    for poly in me.polygons:
        u = uv.data[poly.loop_indices[0]].uv[0]
        slot = max(0, min(SLOTS_N - 1, int(math.floor(u * SLOTS_N))))
        if slot not in idx:
            idx[slot] = len(me.materials)
            me.materials.append(_flat_material("#" + PALETTE_HEX[slot]))
        poly.material_index = idx[slot]


def _fix_ao_layer_name(obj):
    attrs = obj.data.attributes
    if "AO" in attrs:
        return
    if "Color" in attrs:
        attrs["Color"].name = "AO"


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)


def _find_glb(name):
    if os.path.isdir(MODELS_DIR):
        for cat in sorted(os.listdir(MODELS_DIR)):
            p = os.path.join(MODELS_DIR, cat, name + ".glb")
            if os.path.exists(p):
                return p
    return None


def _find_crop(name):
    fname = SPECS.get(name, {}).get("crop", name) + ".png"
    for d in CROP_DIRS:
        p = os.path.join(d, fname)
        if os.path.exists(p):
            return p
    return None


def _import_path(path, offset=(0.0, 0.0, 0.0)):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None:
            o.location = o.location + Vector(offset)
    bpy.context.view_layer.update()
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        _fix_ao_layer_name(o)
        base = re.sub(r"\.\d{3}$", "", o.name)
        hexc = None
        for suf, h in CLASS_BY_SUFFIX.items():
            if base.endswith(suf):
                hexc = h
        _per_slot_tint(o, hexc)
    return meshes


def _import(name):
    path = _find_glb(name)
    if path is None:
        print("LIPSA GLB:", name)
        return []
    return _import_path(path)


def _bounds(objs):
    lo = Vector((1e9,) * 3)
    hi = Vector((-1e9,) * 3)
    for o in objs:
        for c in o.bound_box:
            p = o.matrix_world @ Vector(c)
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    return lo, hi


def _engine(scene):
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [
        x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    ] else "BLENDER_EEVEE_NEXT"


def _sun(name, direction, energy, color=(1.0, 1.0, 1.0), angle_deg=3.0):
    """Soare care LUMINEAZA in directia `direction` (vector de propagare)."""
    data = bpy.data.lights.new(name, type="SUN")
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    data.energy = energy
    data.color = color
    data.angle = math.radians(angle_deg)
    data.specular_factor = 0.0
    obj.rotation_euler = Vector(direction).normalized().to_track_quat("-Z", "Y").to_euler()
    return obj


def _lit_dir(az_deg, elev_deg):
    """Vectorul de propagare al luminii venite din azimutul `az_deg`, elevatia
    `elev_deg` (azimut ca la camera: (cos a, sin a))."""
    a, e = math.radians(az_deg), math.radians(elev_deg)
    return Vector((-math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), -math.sin(e)))


def _render(objs, path, azimuth=58.0, elevation=18.0, lens=60.0, margin=1.1,
            res_height=900, aspect=0.8, sun_elev=42.0, sun_az_off=45.0):
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in objs
    bpy.context.view_layer.update()
    lo, hi = _bounds(objs)
    center = (lo + hi) * 0.5
    res = (int(res_height * aspect), res_height)

    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "AUTO"
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 2000.0
    scene.render.resolution_x, scene.render.resolution_y = res
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
    corners = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]

    def place(d):
        cam.location = center + dirv * d
        look = (center - cam.location).normalized()
        cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()

    def extent(d):
        place(d)
        xs, ys = [], []
        for p in corners:
            v = world_to_camera_view(scene, cam, p)
            xs.append(v.x)
            ys.append(v.y)
        return max(max(xs) - 0.5, 0.5 - min(xs)) * 2, max(max(ys) - 0.5, 0.5 - min(ys)) * 2

    lo_d, hi_d = 1.0, 4000.0
    for _ in range(40):
        mid = (lo_d + hi_d) * 0.5
        ex, ey = extent(mid)
        if max(ex, ey) * margin > 1.0:
            lo_d = mid
        else:
            hi_d = mid
    place(hi_d)

    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    _sun("KSun", _lit_dir(azimuth + sun_az_off, sun_elev), 2.6)
    _sun("KFill", _lit_dir(azimuth - 100.0, 40.0), 0.9)

    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.8, 0.8, 0.8, 1.0)
        bg.inputs[1].default_value = 0.55
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    return path


def _compose(args):
    script = os.path.join(HERE_P, "compose_angkor.py")
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


def _camera_for(name):
    c = dict(azimuth=62.0, elevation=4.0, lens=70.0, margin=1.06)
    c.update(SPECS.get(name, {}).get("camera", {}))
    return c


def _rm(*paths):
    for p in paths:
        try:
            os.remove(p)
        except OSError:
            pass


def compare(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = _find_crop(name)
    if crop is None:
        print("LIPSA decupare:", name)
        return
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    aspect = max(0.3, min(8.0, cw / float(ch)))
    _render(meshes, tmp, res_height=res_height, aspect=aspect, **_camera_for(name))
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])
    _rm(tmp)


def views(name, res_height=800):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    outs = []
    for az in (62.0, 152.0, 242.0, 332.0):
        cam = _camera_for(name)
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(meshes, p, res_height=res_height, aspect=0.6, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out",
              os.path.join(FID_DIR, name + "_views.png")])
    _rm(*outs)


def gamecam(name):
    """Camera de joc: vezi antetul. Doua cadre, apoi compunere cu decupari."""
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    scene = bpy.context.scene
    for o in meshes:
        o.location = o.location + Vector((0.0, 0.0, -GC_BURY))
        o.hide_render = False
    bpy.context.view_layer.update()

    # terasa: un plan mare la cota 0 (acopera baza ingropata)
    bpy.ops.mesh.primitive_plane_add(size=600.0, location=(0.0, -150.0, 0.0))
    ground = bpy.context.active_object
    ground.name = "GCGround"
    ground.data.materials.append(_plain_material("GCGround", "#8E8578"))

    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    el, yaw = math.radians(GC_SUN_ELEV), math.radians(GC_SUN_YAW)
    # drumul merge spre +Y; soarele e in spatele camerei (lumineaza spre +Y)
    d = Vector((math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el)))
    _sun("GCSun", d, 3.4, color=_hex_lin("FFC48A"), angle_deg=1.5)
    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin("9C8296") + (1.0,)
        bg.inputs[1].default_value = 0.34
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = GC_RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.file_format = "PNG"

    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 380.0

    frames, boxes = [], []
    for tag, car_x in (("a", 0.0), ("b", -4.0)):
        car = Vector((car_x, -GC_PIECE_AHEAD, 0.0))
        cam.location = car + Vector((0.0, -GC_DIST, GC_HEIGHT))
        target = car + Vector((0.0, GC_LOOK_AHEAD, GC_LOOK_HEIGHT))
        cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()
        xs, ys = [], []
        for o in meshes:
            for c in o.bound_box:
                v = world_to_camera_view(scene, cam, o.matrix_world @ Vector(c))
                xs.append(v.x)
                ys.append(1.0 - v.y)
        W, Hh = GC_RES
        box = (min(xs) * W, min(ys) * Hh, max(xs) * W, max(ys) * Hh)
        p = os.path.join(FID_DIR, "_gc_%s_%s.png" % (name, tag))
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        frames.append(p)
        boxes.append("%.1f,%.1f,%.1f,%.1f" % box)
    _compose(["--gamecam", ",".join(frames), "--boxes", ";".join(boxes), "--out",
              os.path.join(FID_DIR, name + "_gamecam.png")])
    _rm(*frames)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--gamecam" in args:
    gamecam(args[args.index("--gamecam") + 1])
else:
    print(__doc__)
