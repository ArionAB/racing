"""Randari de control pentru kitul podului rosu -- din GLB-urile EXPORTATE.

Pe tiparul `preview_angkor.py`: fiecare fata pe culoarea slotului ei din atlas
(recuperat din UV) x AO-ul copt; cubul implicit si tot ce nu e piesa primesc
`hide_render` (memoria blender-preview-cub-implicit). Materialele au
backface culling: o fata intoarsa apare ca GAURA, nu trece neobservata.

Moduri (prin run_build.py, argumentele dupa al doilea `--`):

  --compare <piesa>   decupare (stanga) | randare (dreapta), 3/4 ca pe decupare
                      -> docs/asset_briefs/img/sf_fidelity/sf_bridge_<piesa>.png
                      Piesele late (doua parti la +-12..16 m) se arata pe O
                      parte (Z Godot > 0), ca decuparea; GLB-ul ramane intreg.
  --assembled         podul asamblat EXACT ca in joc (ASSEMBLY, aceleasi
                      transformari ca tools/gen_sf_route.py `_pod_piece`), cu
                      asfaltul (Y 0, |Z| <= 16) si apa (Y -20):
                        sf_bridge_assembled_grid.png  camera de pe grila: 10 m
                            peste drum, 123 m inaintea primului turn, pe ax,
                            29 de grade in jos, FOV vertical 68
                        sf_bridge_assembled_deck.png  de pe tablier, 60 m inaintea
                            turnului de E (treci pe sub traversa de jos)
                        sf_bridge_assembled_side.png  elevatie de pe mal
                            (ortografica), silueta
                        sf_bridge_assembled_34.png    3/4 de sus, de pe mal

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_bridge.py -- --compare tower

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock` (daca esueaza,
alt proces randeaza), dupa `rmdir`.
"""

import bpy
import math
import os
import re
import subprocess
import sys
from mathutils import Matrix, Vector
from bpy_extras.object_utils import world_to_camera_view

HERE_P = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE_P))
MODELS_DIR = os.path.join(PROJ, "assets", "models", "sanfrancisco", "structures")
CROP_DIR = os.path.join(PROJ, "docs", "track_briefs", "img", "sf_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "sf_fidelity")

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

# camera per piesa (azimut ca in preview_angkor: camera la (cos a, sin a) in
# Blender; Blender +Y = Godot -Z). `half`: doar partea Z Godot > 0.
SPECS = {
    "tower": dict(azimuth=22.0, elevation=8.0, lens=60.0, margin=1.06, aspect=1.0),
    "deck_8": dict(azimuth=-52.0, elevation=22.0, lens=60.0, margin=1.08, aspect=1.9, half=True),
    "parapet_8": dict(azimuth=58.0, elevation=16.0, lens=60.0, margin=1.08, aspect=1.9, half=True),
    "walkway_8": dict(azimuth=58.0, elevation=26.0, lens=60.0, margin=1.08, aspect=1.8, half=True),
    "flares": dict(azimuth=150.0, elevation=24.0, lens=60.0, margin=1.08, aspect=1.6, half=True),
    "cable_main": dict(azimuth=-62.0, elevation=10.0, lens=60.0, margin=1.06, aspect=1.4, half=True),
    "cable_side": dict(azimuth=-62.0, elevation=10.0, lens=60.0, margin=1.06, aspect=0.9, half=True),
    "anchor": dict(azimuth=-38.0, elevation=16.0, lens=60.0, margin=1.08, aspect=1.2, half=True),
    "lamp": dict(azimuth=40.0, elevation=8.0, lens=70.0, margin=1.06, aspect=0.45),
}

# Ansamblul, in cadrul podului (X_D0 = capatul de V al tablierului, Y = fata
# carosabilului, Z = ax). Acelasi lucru ca gen_sf_route.py `_pod_piece`:
# (piesa, x, flip (180 de grade in jurul lui Y), z, y)
DECK = 200.0
ASSEMBLY = (
    [("tower", DECK * 0.25, False, 0.0, 0.0), ("tower", DECK * 0.75, False, 0.0, 0.0)]
    + [("deck_8", 8.0 * k, False, 0.0, 0.0) for k in range(int(round(DECK / 8.0)))]
    + [("parapet_8", -12.0 + 8.0 * k, False, 0.0, 0.0) for k in range(int(round((DECK + 24.0) / 8.0)))]
    + [("walkway_8", -12.0 + 8.0 * k, False, 0.0, 0.0) for k in range(int(round((DECK + 24.0) / 8.0)))]
    + [("flares", -12.0, False, 0.0, 0.0), ("flares", DECK + 12.0, True, 0.0, 0.0)]
    + [("cable_main", DECK * 0.25, False, 0.0, 0.0)]
    + [("cable_side", DECK * 0.25, False, 0.0, 0.0), ("cable_side", DECK * 0.75, True, 0.0, 0.0)]
    + [("anchor", 0.0, False, 0.0, 0.0), ("anchor", DECK, True, 0.0, 0.0)]
    + [("lamp", float(xl), False, side * 13.6, 0.20)
       for xl in range(16, int(DECK), 24) for side in (-1, 1)]
)

GC_FOV, GC_PITCH, GC_H = 68.0, 29.0, 10.0
GC_RES = (1920, 1080)


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _hex_lin(h):
    h = h.lstrip("#")
    return tuple(_srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def _flat_material(hex_color):
    name = "SFFlat_" + hex_color.lstrip("#")
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.use_backface_culling = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.9
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.05
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


def _plain_material(name, hex_color, rough=1.0):
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = _hex_lin(hex_color) + (1.0,)
    bsdf.inputs["Roughness"].default_value = rough
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


def _fix_ao_layer_name(obj):
    attrs = obj.data.attributes
    if "AO" not in attrs and "Color" in attrs:
        attrs["Color"].name = "AO"


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(name):
    path = os.path.join(MODELS_DIR, "sf_bridge_%s.glb" % name)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        _fix_ao_layer_name(o)
        _per_slot_tint(o)
    return meshes


def _keep_half(obj):
    """Sterge varfurile cu Z Godot < -0,5 (Blender y > 0,5): doar partea +Z."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    dead = [v for v in bm.verts if (obj.matrix_world @ v.co).y > 0.5]
    bmesh.ops.delete(bm, geom=dead, context="VERTS")
    bm.to_mesh(obj.data)
    bm.free()


def _bounds(objs):
    lo = Vector((1e9,) * 3)
    hi = Vector((-1e9,) * 3)
    for o in objs:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    return lo, hi


def _engine(scene):
    ids = [x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in ids else "BLENDER_EEVEE_NEXT"


def _sun(name, direction, energy, color=(1.0, 1.0, 1.0), angle_deg=2.0):
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
    world = scene.world or bpy.data.worlds.new("SFWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin(hex_color) + (1.0,)
        bg.inputs[1].default_value = strength
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"


def _camera(scene):
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _render_fit(objs, path, azimuth, elevation, lens, margin, aspect, res_height=900, **_):
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in objs
    bpy.context.view_layer.update()
    lo, hi = _bounds(objs)
    center = (lo + hi) * 0.5
    cam = _camera(scene)
    cam.data.type = "PERSP"
    cam.data.sensor_fit = "AUTO"
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 3000.0
    scene.render.resolution_x, scene.render.resolution_y = int(res_height * aspect), res_height
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
    corners = [o.matrix_world @ v.co for o in objs for v in o.data.vertices][::7]
    corners += [Vector((x, y, z)) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]

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

    lo_d, hi_d = 1.0, 6000.0
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
    _sun("SSun", _lit_dir(azimuth + 40.0, 40.0), 3.0, color=_hex_lin("FFE6C8"))
    _sun("SFill", _lit_dir(azimuth - 100.0, 35.0), 0.8)
    _world(scene, "CCCCCC", 0.55)
    _engine(scene)
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def _compose(args):
    script = os.path.join(HERE_P, "compose_sf_bridge.py")
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


def compare(name):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    spec = SPECS[name]
    if spec.get("half"):
        for o in meshes:
            _keep_half(o)
    tmp = os.path.join(FID_DIR, "_render_sf_bridge_%s.png" % name)
    _render_fit(meshes, tmp, **spec)
    crop = os.path.join(CROP_DIR, "sf_bridge_%s.png" % name)
    out = os.path.join(FID_DIR, "sf_bridge_%s.png" % name)
    _compose(["--compare", crop, "--render", tmp, "--out", out, "--height", "900"])
    try:
        os.remove(tmp)
    except OSError:
        pass


# --- ansamblul ----------------------------------------------------------------

def _gp(x, y, z):
    return Vector((x, -z, y))


def build_assembly():
    _clear()
    lib = {}
    for name in sorted({a[0] for a in ASSEMBLY}):
        lib[name] = _import(name)
        for o in lib[name]:
            o.hide_render = True
            o.hide_viewport = True
    placed = []
    for name, x, flip, z, y in ASSEMBLY:
        for src in lib[name]:
            o = src.copy()           # mesh partajat (instanta, ca in joc)
            bpy.context.scene.collection.objects.link(o)
            o.hide_render = False
            o.hide_viewport = False
            o.matrix_world = (Matrix.Translation(_gp(x, y, z))
                              @ Matrix.Rotation(math.pi if flip else 0.0, 4, "Z"))
            placed.append(o)
    # asfaltul (Y 0, |Z| <= 16) pe tablier si paliere, apa la -20
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=_gp(100.0, -0.005, 0.0))
    road = bpy.context.active_object
    road.name = "SFRoad"
    road.scale = (DECK + 2 * 36.0 + 200.0, 32.0, 1.0)
    road.data.materials.append(_plain_material("SFRoad", "#4B4B4D", 0.95))
    bpy.ops.mesh.primitive_plane_add(size=4000.0, location=_gp(100.0, -20.0, 0.0))
    water = bpy.context.active_object
    water.name = "SFWater"
    water.data.materials.append(_plain_material("SFWater", "#2E5F6B", 0.35))
    bpy.context.view_layer.update()
    return placed + [road, water]


def _gamecam_shot(path, cam_pos_g, look_dir_g, fov=GC_FOV, res=GC_RES):
    scene = bpy.context.scene
    cam = _camera(scene)
    cam.data.type = "PERSP"
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(fov)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 1500.0
    cam.location = _gp(*cam_pos_g)
    d = _gp(*look_dir_g)
    cam.rotation_euler = d.normalized().to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("randare:", path)


def assembled():
    os.makedirs(FID_DIR, exist_ok=True)
    scene = bpy.context.scene
    build_assembly()
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    # soare cald de dupa-amiaza, din spatele-stanga camerei de pe grila
    _sun("ASun", _lit_dir(200.0, 34.0), 3.6, color=_hex_lin("FFE2BC"), angle_deg=1.0)
    _world(scene, "A9C6DE", 0.85)
    _engine(scene)
    try:
        scene.eevee.use_shadows = True
    except AttributeError:
        pass
    p = math.radians(GC_PITCH)
    look = (math.cos(p), -math.sin(p), 0.0)
    _gamecam_shot(os.path.join(FID_DIR, "sf_bridge_assembled_grid.png"),
                  (DECK * 0.25 - 123.0, GC_H, 0.0), look)
    _gamecam_shot(os.path.join(FID_DIR, "sf_bridge_assembled_deck.png"),
                  (DECK * 0.75 - 60.0, GC_H, 0.0), look)
    # 3/4 de sus, de pe mal (sud-vest), toata silueta
    _gamecam_shot(os.path.join(FID_DIR, "sf_bridge_assembled_34.png"),
                  (-90.0, 70.0, -170.0), (190.0, -70.0, 170.0), fov=40.0)
    # elevatia de pe mal: ortografica, din -Z Godot
    cam = _camera(scene)
    cam.data.type = "ORTHO"
    cam.data.sensor_fit = "HORIZONTAL"
    cam.data.ortho_scale = 270.0
    cam.data.clip_start = 1.0
    cam.data.clip_end = 2000.0
    cam.location = _gp(100.0, 10.0, -600.0)
    cam.rotation_euler = _gp(0.0, 0.0, 1.0).to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = 2400, 820
    scene.render.filepath = os.path.join(FID_DIR, "sf_bridge_assembled_side.png")
    bpy.ops.render.render(write_still=True)
    print("randare:", scene.render.filepath)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    for nm in args[args.index("--compare") + 1].split(","):
        compare(nm)
elif "--assembled" in args:
    assembled()
else:
    print(__doc__)
