"""Randari de control pentru vagonul de cablu SF -- din GLB-ul EXPORTAT.

Pe tiparul `preview_angkor.py` (copiat ce trebuie, nimic partajat modificat).
Fiecare fata pe culoarea slotului ei din atlas (recuperat din UV) x AO-ul copt
(COLOR_0). Cubul implicit si tot ce nu e piesa primesc `hide_render`
(memoria blender-preview-cub-implicit).

Moduri (argumentele dupa al doilea `--`):
  --compare   decuparea (stanga) | randarea (dreapta), acelasi unghi 3/4 din
              fata-stanga ca in decupare, aceeasi inaltime in pixeli
              -> docs/asset_briefs/img/sf_fidelity/cable_car.png
  --views     4 azimuturi -> cable_car_views.png
  --gamecam   camera de joc (10 m sus, 12,5 m in spatele punctului de pe axa,
              privire in jos 29 grade, fov vertical 68), vagonul pe axa la 20 m
              si la 80 m in fata, mergand IN DEPARTARE (i se vede spatele);
              langa el o cutie de 4,2 m (masina de jucarie) pentru scara
              -> cable_car_gamecam.png
  --all       toate trei

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_cable_car.py -- --all

Compunerea cu PIL: compose_angkor.py (Python de sistem), apelat neschimbat.
RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import bpy
import math
import os
import subprocess
import sys
from mathutils import Vector, Euler
from bpy_extras.object_utils import world_to_camera_view

HERE_P = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE_P))
GLB_PATH = os.path.join(PROJ, "assets", "models", "sanfrancisco", "vehicles", "cable_car.glb")
CROP = os.path.join(PROJ, "docs", "track_briefs", "img", "sf_assets_v1", "cable_car.png")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "sf_fidelity")
NAME = "cable_car"

PALETTE_HEX = [
    "E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
    "BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
    "E54839", "2C82E8", "F2D03C",
    "54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
    "7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
    "E8622D", "D2A0BE",
]
SLOTS_N = 32

# decuparea: vagonul din fata-stanga, usor de sus, capatul din fata vizibil
CAMERA = dict(azimuth=152.0, elevation=14.0, lens=60.0, margin=1.04)

GC_HEIGHT, GC_DIST, GC_FOV, GC_PITCH = 10.0, 12.5, 68.0, 29.0
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


def _per_slot_tint(obj):
    me = obj.data
    uv = me.uv_layers.active
    me.materials.clear()
    idx = {}
    for poly in me.polygons:
        u = uv.data[poly.loop_indices[0]].uv[0]
        slot = max(0, min(SLOTS_N - 1, int(math.floor(u * SLOTS_N))))
        if slot not in idx:
            idx[slot] = len(me.materials)
            me.materials.append(_flat_material("#" + PALETTE_HEX[slot]))
        poly.material_index = idx[slot]


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import():
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=GLB_PATH)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        attrs = o.data.attributes
        if "AO" not in attrs and "Color" in attrs:
            attrs["Color"].name = "AO"
        _per_slot_tint(o)
    bpy.context.view_layer.update()
    return meshes


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
    ids = [x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in ids else "BLENDER_EEVEE_NEXT"


def _sun(name, direction, energy, color=(1.0, 1.0, 1.0), angle_deg=3.0):
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
    a, e = math.radians(az_deg), math.radians(elev_deg)
    return Vector((-math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), -math.sin(e)))


def _world(scene, hex_color, strength):
    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin(hex_color) + (1.0,)
        bg.inputs[1].default_value = strength
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"


def _camera():
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _render(objs, path, azimuth, elevation, lens, margin, res_height=900, aspect=0.8,
            sun_elev=42.0, sun_az_off=45.0):
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in objs
    bpy.context.view_layer.update()
    lo, hi = _bounds(objs)
    center = (lo + hi) * 0.5
    cam = _camera()
    cam.data.sensor_fit = "AUTO"
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 2000.0
    scene.render.resolution_x, scene.render.resolution_y = int(res_height * aspect), res_height
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
    corners = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]

    def place(d):
        cam.location = center + dirv * d
        cam.rotation_euler = (center - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
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
    _world(scene, "CCCCCC", 0.55)
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = path
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


def _rm(*paths):
    for p in paths:
        try:
            os.remove(p)
        except OSError:
            pass


def compare(res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import()
    tmp = os.path.join(FID_DIR, "_render_" + NAME + ".png")
    img = bpy.data.images.load(CROP)
    cw, ch = img.size
    bpy.data.images.remove(img)
    _render(meshes, tmp, res_height=res_height, aspect=cw / float(ch), **CAMERA)
    _compose(["--compare", NAME, "--crop", CROP, "--render", tmp, "--out",
              os.path.join(FID_DIR, NAME + ".png"), "--height", str(res_height)])
    _rm(tmp)


def views(res_height=700):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import()
    outs = []
    # fata-stanga (ca decuparea), spate-stanga, spate-dreapta, fata-dreapta
    for az in (152.0, 222.0, 312.0, 42.0):
        cam = dict(CAMERA)
        cam["azimuth"] = az
        cam["elevation"] = 20.0
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (NAME, int(az)))
        _render(meshes, p, res_height=res_height, aspect=1.25, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, NAME + "_views.png")])
    _rm(*outs)


def gamecam():
    """Vagonul in origine, fata pe +Y, merge spre +Y. Punctul masinii e pe axa,
    la `ahead` m in spatele centrului vagonului; camera la 12,5 m in spatele
    punctului si 10 m sus, inclinata 29 grade in jos."""
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import()
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in meshes
    for o in meshes:
        o.hide_render = False
    # drumul (asfalt) si masina de jucarie de 4,2 m pe banda alaturata
    bpy.ops.mesh.primitive_plane_add(size=600.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.active_object
    ground.name = "GCGround"
    # asfalt neutru: un fundal cald (v1, #6E6A66 sub soarele auriu) iesea maro
    # si ascundea contrastul vagonului rosu
    ground.data.materials.append(_plain_material("GCGround", "#5E5F63"))
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.9, -1.2, 0.65))
    car = bpy.context.active_object
    car.name = "GCToyCar"
    car.scale = (1.9, 4.2, 1.3)
    car.data.materials.append(_plain_material("GCToyCar", "#2C82E8"))
    bpy.context.view_layer.update()

    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    # soarele de ora aurie, jos, din spatele camerei si putin din stanga
    el, yaw = math.radians(26.0), math.radians(-25.0)
    d = Vector((math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el)))
    _sun("GCSun", d, 3.4, color=_hex_lin("FFC48A"), angle_deg=1.5)
    _world(scene, "9CA9BC", 0.45)
    scene.render.resolution_x, scene.render.resolution_y = GC_RES
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGB"

    cam = _camera()
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 600.0
    frames, boxes = [], []
    for ahead in (20.0, 80.0):
        point = Vector((0.0, -ahead, 0.0))
        cam.location = point + Vector((0.0, -GC_DIST, GC_HEIGHT))
        cam.rotation_euler = Euler((math.radians(90.0 - GC_PITCH), 0.0, 0.0))
        bpy.context.view_layer.update()
        xs, ys = [], []
        for o in meshes + [car]:
            for c in o.bound_box:
                v = world_to_camera_view(scene, cam, o.matrix_world @ Vector(c))
                xs.append(v.x)
                ys.append(1.0 - v.y)
        W, H = GC_RES
        boxes.append("%.1f,%.1f,%.1f,%.1f" % (min(xs) * W, min(ys) * H, max(xs) * W, max(ys) * H))
        p = os.path.join(FID_DIR, "_gc_%s_%d.png" % (NAME, int(ahead)))
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        frames.append(p)
    _compose(["--gamecam", ",".join(frames), "--boxes", ";".join(boxes), "--out",
              os.path.join(FID_DIR, NAME + "_gamecam.png")])
    _rm(*frames)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args or "--all" in args:
    compare()
if "--views" in args or "--all" in args:
    views()
if "--gamecam" in args or "--all" in args:
    gamecam()
if not args:
    print(__doc__)
