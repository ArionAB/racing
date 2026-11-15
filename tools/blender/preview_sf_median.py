"""Randari de control pentru utilaj + bloc (San Francisco, pasul 7) -- din
GLB-urile EXPORTATE, fiecare fata pe culoarea slotului ei din atlas x AO.

Pe tiparul `preview_angkor.py` (functiile de material/camera sunt copiate de
acolo, nu importate: fisierele de preview sunt per pista). Cubul implicit si tot
ce nu e piesa primesc `hide_render` sau sunt sterse (memoria
blender-preview-cub-implicit).

Moduri (argumentele dupa al doilea `--`):
  --compare-truck   decupare | utilaj (cu 5 blocuri prin tunel), 3/4
                    -> docs/asset_briefs/img/sf_fidelity/sf_median_truck.png
  --compare-block   decupare | bloc, 3/4 -> sf_median_block.png
  --views           lateral, 3/4, din capat (in tunel), de sus; randul de blocuri
                    trece prin tunel -> sf_median_truck_views.png
  --gamecam         tablierul vazut de camera de joc: drum 24,4 m, parapete rosii
                    de 1,2 m la +-12,2, rand de blocuri cu S de 7 m pe 30 m, utilajul
                    peste S (rotit dupa panta, ca `_truck_yaw`), o cutie de masina
                    de 4,2 m; utilajul la 40 m si la 120 m -> sf_median_gamecam.png
  --all             toate de mai sus

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_median.py -- --all

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import bpy
import math
import os
import subprocess
import sys
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

HERE_P = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE_P))
MODELS = os.path.join(PROJ, "assets", "models", "sanfrancisco")
TRUCK_GLB = os.path.join(MODELS, "vehicles", "sf_median_truck.glb")
BLOCK_GLB = os.path.join(MODELS, "props", "sf_median_block.glb")
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "sf_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "sf_fidelity")

PALETTE_HEX = [
    "E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
    "BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
    "E54839", "2C82E8", "F2D03C",
    "54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
    "7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
    "E8622D", "D2A0BE",
]
SLOTS_N = 32

# camera de joc (scenes/race/chase_camera.gd)
GC_HEIGHT, GC_DIST, GC_FOV = 10.0, 12.5, 68.0
GC_LOOK_AHEAD, GC_LOOK_HEIGHT = 5.0, 0.4
GC_RES = (1920, 1080)
# despartitorul mobil (movable_median_hazard.gd: offset_m, transition_m, block_len)
OFFSET_M, TRANS_M, BLOCK_LEN = 3.5, 30.0, 3.0
DECK_HALF = 12.2
LANE_X = 4.35          # centrul benzii masinii: intre bariera (-3,5) si parapet (12,2)


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
        bpy.data.objects.remove(o, do_unlink=True)


def _import(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        attrs = o.data.attributes
        if "AO" not in attrs and "Color" in attrs:
            attrs["Color"].name = "AO"
        _per_slot_tint(o)
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    return meshes[0]


def _copy(src, loc, yaw):
    o = src.copy()
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_mode = "XYZ"      # importatorul glTF lasa QUATERNION: euler-ul ar fi ignorat
    o.rotation_euler = (0.0, 0.0, yaw)
    return o


def _block_row(block, ys, x_of=lambda y: 0.0, yaw_of=lambda y: 0.0):
    """Blocuri cap la cap pe Y (lungimea blocului = X local, rotit cu 90 de grade)."""
    out = []
    for y in ys:
        out.append(_copy(block, Vector((x_of(y), y, -0.05)), math.radians(90.0) + yaw_of(y)))
    return out


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


def _cam():
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _world(rgb_hex, strength):
    scene = bpy.context.scene
    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin(rgb_hex) + (1.0,)
        bg.inputs[1].default_value = strength
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_percentage = 100


def _render(objs, path, azimuth=35.0, elevation=16.0, lens=60.0, margin=1.08,
            res_height=800, aspect=1.4, sun_elev=42.0, sun_az_off=40.0, ortho=False,
            show=()):
    """`objs` = ce incadreaza camera; `show` = vizibile in plus, fara sa conteze
    la incadrare (randul de blocuri din vederea din capat)."""
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in objs and o not in show
    bpy.context.view_layer.update()
    lo, hi = _bounds(objs)
    center = (lo + hi) * 0.5
    scene.render.resolution_x, scene.render.resolution_y = int(res_height * aspect), res_height
    cam = _cam()
    cam.data.sensor_fit = "AUTO"
    cam.data.type = "ORTHO" if ortho else "PERSP"
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 2000.0
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
    corners = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]

    def place(d):
        cam.location = center + dirv * d
        look = (center - cam.location).normalized()
        up = "Y" if abs(look.z) < 0.99 else "X"
        cam.rotation_euler = look.to_track_quat("-Z", up).to_euler()
        bpy.context.view_layer.update()

    if ortho:
        place(60.0)
        lo_s, hi_s = 0.1, 100.0
        for _ in range(40):
            mid = (lo_s + hi_s) * 0.5
            cam.data.ortho_scale = mid
            bpy.context.view_layer.update()
            vs = [world_to_camera_view(scene, cam, p) for p in corners]
            ex = max(max(v.x for v in vs) - 0.5, 0.5 - min(v.x for v in vs)) * 2
            ey = max(max(v.y for v in vs) - 0.5, 0.5 - min(v.y for v in vs)) * 2
            if max(ex, ey) * margin > 1.0:
                lo_s = mid
            else:
                hi_s = mid
        cam.data.ortho_scale = hi_s
    else:
        lo_d, hi_d = 1.0, 4000.0
        for _ in range(40):
            mid = (lo_d + hi_d) * 0.5
            place(mid)
            vs = [world_to_camera_view(scene, cam, p) for p in corners]
            ex = max(max(v.x for v in vs) - 0.5, 0.5 - min(v.x for v in vs)) * 2
            ey = max(max(v.y for v in vs) - 0.5, 0.5 - min(v.y for v in vs)) * 2
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
    _world("CCCCCC", 0.55)
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def _compose(args):
    script = os.path.join(HERE_P, "compose_sf_median.py")
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


def _truck_with_row(n_each_side=3):
    _clear()
    truck = _import(TRUCK_GLB)
    block = _import(BLOCK_GLB)
    ys = [k * BLOCK_LEN for k in range(-n_each_side, n_each_side + 1)]
    row = _block_row(block, ys)
    block.hide_render = True
    bpy.data.objects.remove(block, do_unlink=True)
    return truck, row


def compare_truck():
    os.makedirs(FID_DIR, exist_ok=True)
    truck, row = _truck_with_row(2)
    tmp = os.path.join(FID_DIR, "_r_truck.png")
    _render([truck] + row, tmp, azimuth=38.0, elevation=16.0, lens=55.0, aspect=2.2,
            res_height=700)
    _compose(["--compare", "--crop", os.path.join(CROPS, "sf_median_truck.png"),
              "--render", tmp, "--out", os.path.join(FID_DIR, "sf_median_truck.png")])
    _rm(tmp)


def compare_block():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    block = _import(BLOCK_GLB)
    tmp = os.path.join(FID_DIR, "_r_block.png")
    _render([block], tmp, azimuth=-62.0, elevation=16.0, lens=60.0, aspect=1.55,
            res_height=600, margin=1.12)
    # al doilea cadru: trei blocuri cap la cap (imbinarea cep-mufa)
    b2 = _copy(block, Vector((3.0, 0.0, 0.0)), 0.0)
    b3 = _copy(block, Vector((-3.0, 0.0, 0.0)), 0.0)
    tmp2 = os.path.join(FID_DIR, "_r_block_row.png")
    _render([block, b2, b3], tmp2, azimuth=-58.0, elevation=22.0, lens=60.0, aspect=1.55,
            res_height=600, margin=1.06)
    tmpm = os.path.join(FID_DIR, "_r_block_m.png")
    _compose(["--grid", tmp + "," + tmp2, "--labels", "bloc,3 blocuri la 3,0 m", "--out", tmpm])
    _compose(["--compare", "--crop", os.path.join(CROPS, "sf_median_block.png"),
              "--render", tmpm, "--out", os.path.join(FID_DIR, "sf_median_block.png"),
              "--height", "500"])
    _rm(tmp, tmp2, tmpm)


def views():
    os.makedirs(FID_DIR, exist_ok=True)
    truck, row = _truck_with_row(3)
    objs = [truck] + row
    shots = [
        ("lateral", dict(azimuth=0.0, elevation=4.0, lens=70.0), [truck] + row[2:5]),
        ("3/4", dict(azimuth=35.0, elevation=24.0, lens=55.0), [truck] + row[2:5]),
        ("din capat (in tunel)", dict(azimuth=90.0, elevation=3.0, lens=70.0), [truck]),
        ("de sus", dict(azimuth=0.0, elevation=89.9, lens=60.0, ortho=True), [truck] + row[2:5]),
    ]
    outs, labels = [], []
    for k, (lab, cam, frame) in enumerate(shots):
        p = os.path.join(FID_DIR, "_v_%d.png" % k)
        # randul intreg e vizibil, dar cadrul se potriveste pe utilaj
        _render(frame, p, res_height=620, aspect=1.6, margin=1.06, show=objs, **cam)
        outs.append(p)
        labels.append(lab)
    _compose(["--grid", ",".join(outs), "--labels", ",".join(labels),
              "--out", os.path.join(FID_DIR, "sf_median_truck_views.png")])
    _rm(*outs)


def _smooth(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def _offset(s, st):
    return OFFSET_M * (2.0 * _smooth(st - TRANS_M * 0.5, st + TRANS_M * 0.5, s) - 1.0)


def _slope(s, st):
    h = 0.5
    return (_offset(s + h, st) - _offset(s - h, st)) / (2 * h)


def _gc_scene(st):
    _clear()
    truck = _import(TRUCK_GLB)
    block = _import(BLOCK_GLB)
    # blocuri de la 12 m in spatele masinii pana la 60 m dincolo de utilaj
    s0 = -12.0
    n = int((st + 60.0 - s0) / BLOCK_LEN)
    ys = [s0 + k * BLOCK_LEN for k in range(n)]
    # `_block_xform`: yaw = -atan(panta); in Blender lungimea blocului (X) pe directia
    # (panta, 1) a drumului
    row = _block_row(block, ys, x_of=lambda y: _offset(y, st),
                     yaw_of=lambda y: math.atan2(1.0, _slope(y, st)) - math.radians(90.0))
    bpy.data.objects.remove(block, do_unlink=True)
    truck.location = Vector((0.0, st, 0.0))
    truck.rotation_mode = "XYZ"
    truck.rotation_euler = (0.0, 0.0, -math.atan(_slope(st, st)))

    def box(name, loc, size, hexc):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
        o = bpy.context.active_object
        o.name = name
        o.scale = size
        o.data.materials.append(_plain_material(name, hexc))
        return o

    road = box("GCRoad", (0.0, 120.0, -0.15), (2 * DECK_HALF, 320.0, 0.3), "56565A")
    # benzile de marcaj (doar ca reper de scara)
    marks = []
    for sx in (-1, 1):
        for k in range(40):
            marks.append(box("GCMark", (sx * 8.0, -20.0 + k * 8.0, 0.005), (0.15, 3.0, 0.01), "D8D4C8"))
    para = [box("GCParapet", (sx * (DECK_HALF + 0.2), 120.0, 0.6), (0.4, 320.0, 1.2), "C0362C")
            for sx in (-1, 1)]
    ground = box("GCWater", (0.0, 120.0, -12.0), (900.0, 900.0, 0.2), "4E6E7E")
    car = box("GCCar", (LANE_X, 0.0, 0.6), (1.9, 4.2, 1.2), "2C82E8")
    return truck, row, [road, ground, car] + para + marks


def gamecam():
    os.makedirs(FID_DIR, exist_ok=True)
    frames, boxes, labels = [], [], []
    for st in (40.0, 120.0):
        truck, row, env = _gc_scene(st)
        scene = bpy.context.scene
        for o in bpy.data.objects:
            if o.type == "MESH":
                o.hide_render = False
        for o in list(bpy.data.objects):
            if o.type == "LIGHT":
                bpy.data.objects.remove(o, do_unlink=True)
        # soarele de dupa-amiaza, din spatele camerei, putin din dreapta
        el, yaw = math.radians(38.0), math.radians(-25.0)
        d = Vector((math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el)))
        _sun("GCSun", d, 3.2, color=_hex_lin("FFF0DC"), angle_deg=1.5)
        _world("A9C3D6", 0.55)
        scene.render.resolution_x, scene.render.resolution_y = GC_RES
        scene.render.film_transparent = False
        scene.render.image_settings.color_mode = "RGB"
        scene.render.image_settings.file_format = "PNG"
        cam = _cam()
        cam.data.type = "PERSP"
        cam.data.sensor_fit = "VERTICAL"
        cam.data.angle = math.radians(GC_FOV)
        cam.data.clip_start = 0.3
        cam.data.clip_end = 600.0
        car = Vector((LANE_X, 0.0, 0.0))
        cam.location = car + Vector((0.0, -GC_DIST, GC_HEIGHT))
        target = car + Vector((0.0, GC_LOOK_AHEAD, GC_LOOK_HEIGHT))
        cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()
        xs, ys = [], []
        for c in truck.bound_box:
            v = world_to_camera_view(scene, cam, truck.matrix_world @ Vector(c))
            xs.append(v.x)
            ys.append(1.0 - v.y)
        W, H = GC_RES
        boxes.append("%.1f,%.1f,%.1f,%.1f" % (min(xs) * W, min(ys) * H, max(xs) * W, max(ys) * H))
        p = os.path.join(FID_DIR, "_gc_%d.png" % int(st))
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        frames.append(p)
        labels.append("utilajul la %d m" % int(st))
    _compose(["--gamecam", ",".join(frames), "--boxes", ";".join(boxes),
              "--labels", ",".join(labels), "--out", os.path.join(FID_DIR, "sf_median_gamecam.png")])
    _rm(*frames)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare-truck" in args or "--all" in args:
    compare_truck()
if "--compare-block" in args or "--all" in args:
    compare_block()
if "--views" in args or "--all" in args:
    views()
if "--gamecam" in args or "--all" in args:
    gamecam()
if not args:
    print(__doc__)
