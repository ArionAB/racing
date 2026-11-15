"""Randari de control pentru mobilierul de strada San Francisco (valul 2) -- din GLB-urile
EXPORTATE, fiecare fata pe culoarea slotului ei din atlas x AO.

Pe tiparul `preview_sf_median.py` (functiile de material/camera sunt copiate de acolo, nu
importate: fisierele de preview sunt per pista). Tot ce nu e piesa e sters la import (cubul
implicit, memoria blender-preview-cub-implicit).

Moduri (argumentele dupa al doilea `--`):
  --compare=<p1,p2,..>  decupare | randare, cate o imagine pe piesa:
                        mast, sedan, wagon, van, lamp, props, bollard, traps, bench, rack
                        -> docs/asset_briefs/img/sf_fidelity/sf_<piesa>.png
  --compare-all         toate de mai sus
  --cars                cele trei masini, aceeasi scara: lateral, 3/4 fata, 3/4 spate, sus
                        -> sf_parked_cars_views.png
  --gamecam             strada vazuta de camera de joc (10 m sus, 12,5 m in spate, 29 de grade
                        in jos, FOV vertical 68): drum de 14 m, stalpul de semafor pe trotuarul
                        din dreapta la 30 m si la 100 m, cele trei masini perpendiculare,
                        felinare la 25 m, randul de mobilier mic, cutia de 4,2 x 1,9 x 1,3 a
                        masinii de joc -> sf_street_gamecam.png (cadrul + decuparile marite
                        ale celor doua semafoare)
  --gamecam-tint        ca --gamecam, dar caroseriile recolorate cum o va face jocul
                        (slotul 11 -> 0 / 19, doar in randare) -> sf_street_gamecam_tint.png
  --all                 toate

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_street.py -- --all

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
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "sf_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "sf_fidelity")

GLB = {
    "mast": "props/sf_signal_mast.glb",
    "sedan": "vehicles/sf_parked_sedan.glb",
    "wagon": "vehicles/sf_parked_wagon.glb",
    "van": "vehicles/sf_parked_van.glb",
    "lamp": "props/sf_street_lamp.glb",
    "props": "props/sf_street_props.glb",
    "bollard": "props/sf_bollard.glb",
    "traps": "props/sf_crab_traps.glb",
    "bench": "props/sf_bench.glb",
    "rack": "props/sf_bike_rack.glb",
}
# piesa -> (decupare, iesire, camera, ordinea variantelor pe X la randare)
COMPARE = {
    "mast": ("sf_signal_mast.png", "sf_signal_mast.png", dict(azimuth=72.0, elevation=8.0, lens=50.0), None),
    "sedan": ("sf_parked_sedan.png", "sf_parked_sedan.png", dict(azimuth=62.0, elevation=16.0, lens=55.0), None),
    "wagon": ("sf_parked_wagon.png", "sf_parked_wagon.png", dict(azimuth=62.0, elevation=16.0, lens=55.0), None),
    "van": ("sf_parked_van.png", "sf_parked_van.png", dict(azimuth=62.0, elevation=14.0, lens=55.0), None),
    "lamp": ("sf_street_lamp.png", "sf_street_lamp.png", dict(azimuth=60.0, elevation=6.0, lens=60.0), None),
    "props": ("sf_street_props.png", "sf_street_props.png", dict(azimuth=80.0, elevation=12.0, lens=60.0),
              ["Cone", "TrashBin", "NewsBox", "Mailbox", "Hydrant"]),
    "bollard": ("sf_crab_traps.png", "sf_bollard.png", dict(azimuth=60.0, elevation=18.0, lens=60.0), None),
    "traps": ("sf_crab_traps.png", "sf_crab_traps.png", dict(azimuth=70.0, elevation=20.0, lens=60.0),
              ["Crate", "RopeCoil", "TrapStack"]),
    "bench": ("sf_bench.png", "sf_bench.png", dict(azimuth=68.0, elevation=16.0, lens=60.0), None),
    "rack": ("sf_bike_rack.png", "sf_bike_rack.png", dict(azimuth=62.0, elevation=18.0, lens=60.0), None),
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

# camera de joc (brief): 10 m sus, 12,5 m in spate, 29 de grade in jos, FOV vertical 68
GC_HEIGHT, GC_DIST, GC_PITCH, GC_FOV = 10.0, 12.5, 29.0, 68.0
GC_RES = (1920, 1080)
ROAD_HALF = 7.0


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


def _per_slot_tint(obj, remap=None):
    """Material plat pe slot. `remap` = {slot: slot} simuleaza recolorarea din joc."""
    me = obj.data
    uv = me.uv_layers.active
    me.materials.clear()
    idx = {}
    for poly in me.polygons:
        u = uv.data[poly.loop_indices[0]].uv[0]
        slot = max(0, min(SLOTS_N - 1, int(math.floor(u * SLOTS_N))))
        if remap:
            slot = remap.get(slot, slot)
        if slot not in idx:
            idx[slot] = len(me.materials)
            me.materials.append(_flat_material("#" + PALETTE_HEX[slot]))
        poly.material_index = idx[slot]


def _clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)


def _import(path, remap=None):
    """-> {nume nod: obiect}."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    out = {}
    for o in new:
        if o.type != "MESH":
            continue
        attrs = o.data.attributes
        if "AO" not in attrs and "Color" in attrs:
            attrs["Color"].name = "AO"
        _per_slot_tint(o, remap)
        o.rotation_mode = "XYZ"
        out[o.name.split(".")[0]] = o
    for o in new:
        if o.type != "MESH":
            # nodurile-mesh sunt radacini: obiectele goale (daca exista) pleaca
            bpy.data.objects.remove(o, do_unlink=True)
    return out


def _copy(src, loc, yaw):
    o = src.copy()
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_mode = "XYZ"
    o.rotation_euler = (0.0, 0.0, yaw)
    return o


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
            res_height=800, aspect=1.4, sun_elev=42.0, sun_az_off=40.0, ortho=False):
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in objs
    bpy.context.view_layer.update()
    lo, hi = _bounds(objs)
    center = (lo + hi) * 0.5
    scene.render.resolution_x, scene.render.resolution_y = int(res_height * aspect), res_height
    cam = _cam()
    cam.data.sensor_fit = "AUTO"
    cam.data.type = "ORTHO" if ortho else "PERSP"
    cam.data.lens = lens
    cam.data.clip_start = 0.05
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

    def extent():
        vs = [world_to_camera_view(scene, cam, p) for p in corners]
        ex = max(max(v.x for v in vs) - 0.5, 0.5 - min(v.x for v in vs)) * 2
        ey = max(max(v.y for v in vs) - 0.5, 0.5 - min(v.y for v in vs)) * 2
        return max(ex, ey)

    if ortho:
        place(60.0)
        lo_s, hi_s = 0.1, 100.0
        for _ in range(40):
            mid = (lo_s + hi_s) * 0.5
            cam.data.ortho_scale = mid
            bpy.context.view_layer.update()
            if extent() * margin > 1.0:
                lo_s = mid
            else:
                hi_s = mid
        cam.data.ortho_scale = hi_s
    else:
        lo_d, hi_d = 0.5, 4000.0
        for _ in range(40):
            mid = (lo_d + hi_d) * 0.5
            place(mid)
            if extent() * margin > 1.0:
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
    script = os.path.join(HERE_P, "compose_sf_street.py")
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


def _spread(nodes, order, gap=0.35):
    """Variantele stau toate in origine in fisier: la randare se insira pe X."""
    objs = [nodes[n] for n in order]
    x = 0.0
    for o in objs:
        lo, hi = _bounds([o])
        w = hi.x - lo.x
        o.location.x = x - lo.x
        x += w + gap
    shift = x * 0.5
    for o in objs:
        o.location.x -= shift
    return objs


def compare(piece):
    os.makedirs(FID_DIR, exist_ok=True)
    crop, out, cam, order = COMPARE[piece]
    _clear()
    nodes = _import(os.path.join(MODELS, *GLB[piece].split("/")))
    objs = _spread(nodes, order) if order else list(nodes.values())
    tmp = os.path.join(FID_DIR, "_r_%s.png" % piece)
    aspect = 2.4 if piece in ("props", "traps", "mast") else 1.5
    if piece == "lamp":
        aspect = 0.6
    _render(objs, tmp, res_height=700, aspect=aspect, margin=1.06, **cam)
    _compose(["--compare", "--crop", os.path.join(CROPS, crop), "--render", tmp,
              "--out", os.path.join(FID_DIR, out), "--height", "520"])
    _rm(tmp)


def cars_views():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    cars = []
    for k, piece in enumerate(("sedan", "wagon", "van")):
        o = list(_import(os.path.join(MODELS, *GLB[piece].split("/"))).values())[0]
        o.location.x = (k - 1) * 2.6
        cars.append(o)
    shots = [
        ("lateral (bot spre dreapta)", dict(azimuth=0.0, elevation=3.0, lens=70.0)),
        ("3/4 fata", dict(azimuth=55.0, elevation=18.0, lens=55.0)),
        ("3/4 spate", dict(azimuth=-125.0, elevation=18.0, lens=55.0)),
        ("de sus (bot sus)", dict(azimuth=-90.0, elevation=89.9, lens=60.0, ortho=True)),
    ]
    outs, labels = [], []
    for k, (lab, cam) in enumerate(shots):
        p = os.path.join(FID_DIR, "_cv_%d.png" % k)
        _render(cars, p, res_height=560, aspect=1.7, margin=1.05, **cam)
        outs.append(p)
        labels.append(lab)
    _compose(["--grid", ",".join(outs), "--labels", ",".join(labels),
              "--out", os.path.join(FID_DIR, "sf_parked_cars_views.png")])
    _rm(*outs)


def _box(name, loc, size, hexc):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    o.data.materials.append(_plain_material(name, hexc))
    return o


def _gc_scene(tint):
    _clear()

    def load(piece, remap=None):
        return _import(os.path.join(MODELS, *GLB[piece].split("/")), remap)

    mast = load("mast")["SignalMast"]
    lamp = load("lamp")["StreetLamp"]
    props = load("props")
    cars = [load(p, {11: s} if (tint and s is not None) else None)
            for p, s in (("sedan", None), ("wagon", 0), ("van", 19))]
    cars = [list(c.values())[0] for c in cars]
    placed = []
    # drumul, trotuarele, terenul
    _box("GCRoad", (0.0, 150.0, -0.05), (2 * ROAD_HALF, 340.0, 0.1), "4A4A4E")
    for sx in (-1, 1):
        _box("GCWalk", (sx * (ROAD_HALF + 2.25), 150.0, 0.06), (4.5, 340.0, 0.12), "B9B3A8")
        _box("GCKerb", (sx * (ROAD_HALF + 0.1), 150.0, 0.07), (0.2, 340.0, 0.14), "8E8A84")
        for k in range(30):
            _box("GCMark", (0.0, -10.0 + k * 10.0, 0.005), (0.15, 3.0, 0.01), "D8D4C8")
    _box("GCGround", (0.0, 150.0, -0.2), (400.0, 400.0, 0.1), "8A9A6A")
    # semafoarele: stalpul pe trotuarul din dreapta, bratul (-X) peste drum
    m1 = _copy(mast, Vector((ROAD_HALF + 1.5, 30.0, 0.0)), 0.0)
    m2 = _copy(mast, Vector((ROAD_HALF + 1.5, 100.0, 0.0)), 0.0)
    placed += [m1, m2]
    bpy.data.objects.remove(mast, do_unlink=True)
    # felinare la 25 m pe ambele trotuare
    for y in range(-25, 251, 25):
        for sx in (-1, 1):
            placed.append(_copy(lamp, Vector((sx * (ROAD_HALF + 0.8), y + (12.5 if sx < 0 else 0), 0.12)), 0.0))
    bpy.data.objects.remove(lamp, do_unlink=True)
    # masinile parcate perpendicular, pe stanga, botul spre drum (+X)
    for k, car in enumerate(cars):
        y = 16.5 + k * 3.0
        placed.append(_copy(car, Vector((-(ROAD_HALF + 0.3 + 1.85), y, 0.0)), math.radians(-90.0)))
        bpy.data.objects.remove(car, do_unlink=True)
    # randul de mobilier mic pe trotuarul din dreapta
    y = 10.0
    for name in ("Hydrant", "Mailbox", "NewsBox", "TrashBin", "Cone"):
        placed.append(_copy(props[name], Vector((ROAD_HALF + 0.9, y, 0.12)), math.radians(90.0)))
        y += 2.4
    for o in props.values():
        bpy.data.objects.remove(o, do_unlink=True)
    car = _box("GCCar", (0.0, 0.0, 0.65), (1.9, 4.2, 1.3), "2C82E8")
    return m1, m2


def gamecam(tint=False):
    os.makedirs(FID_DIR, exist_ok=True)
    m1, m2 = _gc_scene(tint)
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = False
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
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
    cam.location = Vector((0.0, -GC_DIST, GC_HEIGHT))
    cam.rotation_euler = (math.radians(90.0 - GC_PITCH), 0.0, 0.0)
    bpy.context.view_layer.update()
    boxes = []
    W, H = GC_RES
    for m in (m1, m2):
        xs, ys = [], []
        for c in m.bound_box:
            v = world_to_camera_view(scene, cam, m.matrix_world @ Vector(c))
            xs.append(v.x)
            ys.append(1.0 - v.y)
        boxes.append("%.1f,%.1f,%.1f,%.1f" % (min(xs) * W, min(ys) * H, max(xs) * W, max(ys) * H))
    p = os.path.join(FID_DIR, "_gc_street.png")
    scene.render.filepath = p
    bpy.ops.render.render(write_still=True)
    out = "sf_street_gamecam_tint.png" if tint else "sf_street_gamecam.png"
    _compose(["--gamecam", p, "--boxes", ";".join(boxes),
              "--labels", "semaforul la 30 m,semaforul la 100 m",
              "--out", os.path.join(FID_DIR, out)])
    _rm(p)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
todo = []
for a in args:
    if a.startswith("--compare="):
        todo += a.split("=", 1)[1].split(",")
if "--compare-all" in args or "--all" in args:
    todo = list(COMPARE)
for piece in todo:
    compare(piece)
if "--cars" in args or "--all" in args:
    cars_views()
if "--gamecam" in args or "--all" in args:
    gamecam(False)
if "--gamecam-tint" in args or "--all" in args:
    gamecam(True)
if not args:
    print(__doc__)
