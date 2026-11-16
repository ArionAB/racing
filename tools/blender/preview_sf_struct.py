"""Randari de control pentru structurile San Francisco (valul 3) -- din GLB-urile EXPORTATE,
fiecare fata pe culoarea slotului ei din atlas x AO.

Functiile de material/camera sunt copiate din `preview_sf_street.py` (fisierele de preview sunt
per pista, nu se importa unul pe altul). Pacla temei se APROXIMEAZA in material: culoarea finala =
amestec intre suprafata luminata si culoarea paclei (0,86 / 0,855 / 0,84), cu factorul
`0,55 * clamp((d - 170) / (360 - 170)) ^ 1,4`, d = distanta de la camera (cheile `fog_begin`,
`fog_end`, `fog_curve`, `fog_max` ale temei `sanfrancisco`). Nu e formula exacta din Godot; e
suficient ca sa se judece cat din silueta ramane la 250-350 m. Cerul (sky_top -> sky_horizon) se
pune dupa, in compose_sf_struct.py, sub randarea transparenta. Soarele: FFD2A0, 28 de grade, din
spatele camerei, deviat 12 grade (tema).

Moduri (argumentele dupa al doilea `--`):
  --compare=<p,..>   decupare | randare: turntable, shed, stair, lions
                     -> docs/asset_briefs/img/sf_fidelity/sf_<piesa>.png
  --horizon-row      decuparea `sf_horizon.png` deasupra randarii celor 5 noduri in rand
                     -> sf_horizon_row.png
  --island-views     insula 3/4 si din lateral + silueta pura -> sf_island_light.png
  --gc-turntable     camera de joc; placa la 25 m in lateral, cu cutia vagonului (2,5 x 3,2 x 8,5)
                     pe sine -> sf_turntable_gamecam.png
  --gc-sheds         cheiul: 4 magazii pe latura apei la 14 m de ax, apa la -3, pluta cu lei pe
                     apa, inaintea primei magazii -> sf_pier_sheds_gamecam.png
  --gc-island        insula pe apa, de la 280 m si de la 120 m, cu pacla -> sf_island_gamecam.png
  --horizon-ring     cele 5 variante pe un arc la ~300-345 m (dealurile in fata oraselor), apa in
                     fata, camera de joc + o panorama orizontala -> sf_horizon_ring.png
  --all

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_struct.py -- --all

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
    "turntable": "structures/sf_turntable.glb",
    "shed": "structures/sf_pier_shed.glb",
    "shed_short": "structures/sf_pier_shed_short.glb",
    "island": "structures/sf_island_light.glb",
    "horizon": "structures/sf_horizon.glb",
    "stair": "props/sf_stair_lane.glb",
    "lions": "animals/sf_sea_lions.glb",
}
COMPARE = {
    "turntable": ("sf_turntable.png", dict(azimuth=-140.0, elevation=30.0, lens=55.0)),
    "shed": ("sf_pier_shed.png", dict(azimuth=62.0, elevation=16.0, lens=55.0)),
    "stair": ("sf_stair_lane.png", dict(azimuth=118.0, elevation=24.0, lens=55.0)),
    "lions": ("sf_sea_lions.png", dict(azimuth=-80.0, elevation=20.0, lens=60.0)),
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

GC_HEIGHT, GC_DIST, GC_PITCH, GC_FOV = 10.0, 12.5, 29.0, 68.0
GC_RES = (1920, 1080)
FOG_RGB = (0.86, 0.855, 0.84)
FOG_BEGIN, FOG_END, FOG_CURVE, FOG_MAX = 170.0, 360.0, 1.4, 0.55
SUN_HEX = "FFD2A0"
AMBIENT_HEX = "BCCCE8"


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _hex_lin(h):
    h = h.lstrip("#")
    return tuple(_srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


FOG = False                 # comutat de scenele de joc


def _fog_mix(nt, shader_out, out_node):
    """shader -> amestec cu emisia de culoarea paclei, dupa distanta de la camera."""
    cam = nt.nodes.new("ShaderNodeCameraData")
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.clamp = True
    mr.inputs["From Min"].default_value = FOG_BEGIN
    mr.inputs["From Max"].default_value = FOG_END
    mr.inputs["To Min"].default_value = 0.0
    mr.inputs["To Max"].default_value = 1.0
    nt.links.new(cam.outputs["View Distance"], mr.inputs["Value"])
    pw = nt.nodes.new("ShaderNodeMath")
    pw.operation = "POWER"
    pw.inputs[1].default_value = FOG_CURVE
    nt.links.new(mr.outputs["Result"], pw.inputs[0])
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = FOG_MAX
    nt.links.new(pw.outputs[0], mul.inputs[0])
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = tuple(_srgb_to_linear(c) for c in FOG_RGB) + (1.0,)
    em.inputs["Strength"].default_value = 1.0
    mix = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(mul.outputs[0], mix.inputs[0])
    nt.links.new(shader_out, mix.inputs[1])
    nt.links.new(em.outputs["Emission"], mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out_node.inputs["Surface"])


def _flat_material(hex_color):
    name = ("KFlatF_" if FOG else "KFlat_") + hex_color.lstrip("#")
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
    if FOG:
        _fog_mix(nt, bsdf.outputs["BSDF"], out)
    else:
        nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def _plain_material(name, hex_color, rough=1.0):
    name = ("F_" if FOG else "") + name
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    out = nt.nodes.get("Material Output")
    bsdf.inputs["Base Color"].default_value = _hex_lin(hex_color) + (1.0,)
    bsdf.inputs["Roughness"].default_value = rough
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    if FOG:
        _fog_mix(nt, bsdf.outputs["BSDF"], out)
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


def _import(piece):
    path = os.path.join(MODELS, *GLB[piece].split("/"))
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
        _per_slot_tint(o)
        o.rotation_mode = "XYZ"
        out[o.name.split(".")[0]] = o
    for o in new:
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
    return out


def _copy(src, loc, yaw, scale=1.0):
    o = src.copy()
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_mode = "XYZ"
    o.rotation_euler = (0.0, 0.0, yaw)
    o.scale = (scale, scale, scale)
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
    cam.data.clip_end = 5000.0
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
        place(2000.0)
        lo_s, hi_s = 0.1, 2000.0
        for _ in range(50):
            mid = (lo_s + hi_s) * 0.5
            cam.data.ortho_scale = mid
            bpy.context.view_layer.update()
            if extent() * margin > 1.0:
                lo_s = mid
            else:
                hi_s = mid
        cam.data.ortho_scale = hi_s
    else:
        lo_d, hi_d = 0.5, 6000.0
        for _ in range(50):
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
    script = os.path.join(HERE_P, "compose_sf_struct.py")
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


# ------------------------------------------------------------------ comparatiile
def compare(piece):
    global FOG
    FOG = False
    os.makedirs(FID_DIR, exist_ok=True)
    crop, cam = COMPARE[piece]
    _clear()
    nodes = _import(piece)
    objs = list(nodes.values())
    tmp = os.path.join(FID_DIR, "_r_%s.png" % piece)
    _render(objs, tmp, res_height=700, aspect=1.6, margin=1.06, **cam)
    _compose(["--compare", "--crop", os.path.join(CROPS, crop), "--render", tmp,
              "--out", os.path.join(FID_DIR, "sf_%s.png" % {"shed": "pier_shed", "stair": "stair_lane",
                                                            "lions": "sea_lions"}.get(piece, piece)),
              "--height", "520"])
    _rm(tmp)


def horizon_row():
    global FOG
    FOG = False
    _clear()
    nodes = _import("horizon")
    order = ["City_A", "Hill_A", "Hill_B", "City_B", "Hill_C"]
    # dealurile in rand in fata (y 0), orasele in spatele lor (y +140)
    x = -380.0
    objs = []
    for name in ("Hill_A", "Hill_B", "Hill_C"):
        o = nodes[name]
        lo, hi = _bounds([o])
        o.location = (x - lo.x, 0.0, 0.0)
        x += (hi.x - lo.x) + 10.0
        objs.append(o)
    nodes["City_A"].location = (-200.0, 150.0, 0.0)
    nodes["City_B"].location = (150.0, 160.0, 0.0)
    objs += [nodes["City_A"], nodes["City_B"]]
    tmp = os.path.join(FID_DIR, "_r_hz_row.png")
    _render(objs, tmp, azimuth=-90.0, elevation=6.0, lens=50.0, res_height=420, aspect=4.6, margin=1.02,
            sun_elev=30.0, sun_az_off=35.0)
    tmp2 = os.path.join(FID_DIR, "_r_hz_row_flat.png")
    _compose(["--stack", os.path.join(CROPS, "sf_horizon.png") + "," + tmp,
              "--labels", "decuparea sf_horizon.png,randarea: Hill_A Hill_B Hill_C in fata / City_A City_B in spate",
              "--out", os.path.join(FID_DIR, "sf_horizon_row.png")])
    _rm(tmp, tmp2)


def island_views():
    global FOG
    FOG = False
    _clear()
    nodes = _import("island")
    objs = list(nodes.values())
    a = os.path.join(FID_DIR, "_r_is_a.png")
    s = os.path.join(FID_DIR, "_r_is_s.png")
    s2 = os.path.join(FID_DIR, "_r_is_sil.png")
    _render(objs, a, azimuth=-60.0, elevation=14.0, lens=60.0, res_height=520, aspect=1.9)
    _render(objs, s, azimuth=-90.0, elevation=1.0, lens=80.0, res_height=360, aspect=2.6)
    _compose(["--silhouette", s, "--out", s2])
    _compose(["--stack", ",".join((a, s, s2)), "--labels",
              "3/4 (farul la est = +X),din lateral (de la sud),silueta pura din lateral",
              "--out", os.path.join(FID_DIR, "sf_island_light.png")])
    _rm(a, s, s2)


# ------------------------------------------------------------------ scenele de joc
def _box(name, loc, size, hexc, rough=1.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    o.data.materials.append(_plain_material(name, hexc, rough))
    return o


def _gc_render(path, road_z=0.0, pitch=GC_PITCH, fov=GC_FOV, res=GC_RES, sun_yaw=-12.0):
    """Camera de joc: 10 m peste drum, 12,5 m in spate, privind spre +Y."""
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = False
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    el, yaw = math.radians(28.0), math.radians(sun_yaw)
    d = Vector((math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el)))
    _sun("GCSun", d, 3.4, color=_hex_lin(SUN_HEX), angle_deg=1.5)
    _world(AMBIENT_HEX, 0.45)
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.file_format = "PNG"
    cam = _cam()
    cam.data.type = "PERSP"
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(fov)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 380.0 if pitch > 0.5 else 2000.0
    cam.location = Vector((0.0, -GC_DIST, road_z + GC_HEIGHT))
    cam.rotation_euler = (math.radians(90.0 - pitch), 0.0, 0.0)
    bpy.context.view_layer.update()
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    # linia orizontului in pixeli (pentru cer)
    hy = res[1] * 0.5 - math.tan(math.radians(pitch)) / math.tan(math.radians(fov * 0.5)) * res[1] * 0.5
    return cam, int(round(hy))


def _screen_box(cam, objs, res=GC_RES):
    scene = bpy.context.scene
    xs, ys = [], []
    for o in objs:
        for c in o.bound_box:
            v = world_to_camera_view(scene, cam, o.matrix_world @ Vector(c))
            xs.append(v.x)
            ys.append(1.0 - v.y)
    W, H = res
    return "%.1f,%.1f,%.1f,%.1f" % (max(0, min(xs)) * W, max(0, min(ys)) * H,
                                    min(1, max(xs)) * W, min(1, max(ys)) * H)


def _road(y0, y1, z=0.0, half=7.0):
    _box("GCRoad", (0.0, (y0 + y1) * 0.5, z - 0.05), (2 * half, y1 - y0, 0.1), "3E3E42")
    for k in range(int((y1 - y0) / 10.0)):
        _box("GCMark", (0.0, y0 + 5.0 + k * 10.0, z + 0.005), (0.15, 3.0, 0.01), "D8D4C8")


def gc_turntable():
    global FOG
    FOG = True
    _clear()
    tt = _import("turntable")
    _road(-20.0, 330.0)
    _box("GCGround", (0.0, 150.0, -0.11), (600.0, 600.0, 0.1), "B9A45E")
    for sx in (-1, 1):
        _box("GCWalk", (sx * 9.0, 150.0, 0.06), (4.0, 340.0, 0.12), "B9B3A8")
    loc = Vector((25.0, 28.0, 0.0))
    placed = [_copy(o, loc, 0.0) for o in tt.values()]
    for o in tt.values():
        bpy.data.objects.remove(o, do_unlink=True)
    car = _box("GCCableCar", (loc.x, loc.y, 0.10 + 1.6), (2.5, 8.5, 3.2), "BB3522")
    _box("GCPlayer", (0.0, 0.0, 0.65), (1.9, 4.2, 1.3), "2C82E8")
    p = os.path.join(FID_DIR, "_gc_tt.png")
    cam, hy = _gc_render(p)
    box = _screen_box(cam, placed + [car])
    sp = os.path.join(FID_DIR, "_gc_tt_sky.png")
    _compose(["--sky", p, "--horizon-y", str(hy), "--out", sp])
    _compose(["--gamecam", sp, "--boxes", box, "--labels", "placa turnanta la 25 m in lateral, ~45 m in fata",
              "--out", os.path.join(FID_DIR, "sf_turntable_gamecam.png")])
    _rm(p, sp)


def gc_sheds():
    global FOG
    FOG = True
    _clear()
    long_ = _import("shed")["PierShed"]
    short = _import("shed_short")["PierShed_Short"]
    lions = _import("lions")["SeaLions"]
    _road(-20.0, 330.0, half=6.0)
    # cheiul: trotuar pana la x -14, apa (-3) dincolo
    _box("GCQuay", (-10.0, 150.0, -0.06), (8.0, 340.0, 0.12), "B9B3A8")
    _box("GCLand", (60.0, 150.0, -0.11), (108.0, 600.0, 0.1), "B9A45E")
    _box("GCQuayWall", (-14.0, 150.0, -1.6), (0.4, 340.0, 3.2), "8E8A84")
    _box("GCWater", (-300.0, 150.0, -3.0), (572.0, 800.0, 0.02), "2E5F6B", rough=0.3)
    placed = []
    for y, src, hl in ((18.0, long_, 10.0), (42.0, short, 6.0), (62.0, long_, 10.0), (86.0, short, 6.0)):
        cx = -14.0 - (hl + 1.0)
        placed.append(_copy(src, Vector((cx, y, 0.0)), math.radians(-90.0)))
    raft = _copy(lions, Vector((-19.0, 4.0, -3.0)), math.radians(15.0))
    for o in (long_, short, lions):
        bpy.data.objects.remove(o, do_unlink=True)
    _box("GCPlayer", (0.0, 0.0, 0.65), (1.9, 4.2, 1.3), "2C82E8")
    p = os.path.join(FID_DIR, "_gc_sh.png")
    cam, hy = _gc_render(p)
    boxes = [_screen_box(cam, [placed[0]]), _screen_box(cam, [raft])]
    sp = os.path.join(FID_DIR, "_gc_sh_sky.png")
    _compose(["--sky", p, "--horizon-y", str(hy), "--out", sp])
    _compose(["--gamecam", sp, "--boxes", ";".join(boxes),
              "--labels", "prima magazie (18 m in fata),pluta cu lei (~25 m; pe apa la -3)",
              "--out", os.path.join(FID_DIR, "sf_pier_sheds_gamecam.png")])
    _rm(p, sp)


def gc_island():
    global FOG
    FOG = True
    outs = []
    labels = []
    for dist in (280.0, 120.0):
        _clear()
        isl = _import("island")
        road_z = 5.0
        _box("GCQuay", (0.0, -5.0, road_z - 0.5), (60.0, 50.0, 1.0), "B9B3A8")
        _road(-25.0, 20.0, z=road_z)
        _box("GCWater", (0.0, 500.0, 0.0), (2000.0, 1200.0, 0.02), "2E5F6B", rough=0.3)
        placed = [_copy(o, Vector((0.0, dist - GC_DIST, 0.0)), 0.0) for o in isl.values()]
        for o in isl.values():
            bpy.data.objects.remove(o, do_unlink=True)
        p = os.path.join(FID_DIR, "_gc_is_%d.png" % dist)
        cam, hy = _gc_render(p, road_z=road_z)
        box = _screen_box(cam, placed)
        sp = os.path.join(FID_DIR, "_gc_is_%d_sky.png" % dist)
        _compose(["--sky", p, "--horizon-y", str(hy), "--out", sp])
        o2 = os.path.join(FID_DIR, "_gc_is_%d_c.png" % dist)
        _compose(["--gamecam", sp, "--boxes", box, "--labels", "insula la %d m" % dist, "--out", o2])
        outs.append(o2)
        labels.append("insula la %d m de camera; drumul la +5; pacla aproximata" % dist)
        _rm(p, sp)
    _compose(["--stack", ",".join(outs), "--labels", ",".join(labels),
              "--out", os.path.join(FID_DIR, "sf_island_gamecam.png")])
    _rm(*outs)


# (nod, azimut fata de directia de privire (+ = stanga), raza de la camera)
RING = [("City_A", 16.0, 345.0), ("City_B", -18.0, 340.0),
        ("Hill_A", -26.0, 300.0), ("Hill_B", 4.0, 295.0), ("Hill_C", 33.0, 305.0)]


def horizon_ring():
    global FOG
    FOG = True
    outs, labels = [], []
    for mode in ("game", "pano"):
        _clear()
        nodes = _import("horizon")
        road_z = 3.0
        _box("GCQuay", (0.0, -5.0, road_z - 0.5), (80.0, 50.0, 1.0), "B9B3A8")
        _road(-25.0, 20.0, z=road_z)
        _box("GCWater", (0.0, 600.0, 0.0), (3000.0, 1400.0, 0.02), "2E5F6B", rough=0.3)
        cam_xy = Vector((0.0, -GC_DIST))
        for name, az, r in RING:
            a = math.radians(90.0 + az)
            pos = Vector((cam_xy.x + math.cos(a) * r, cam_xy.y + math.sin(a) * r, -4.0))
            o = nodes[name]
            o.location = pos
            o.rotation_mode = "XYZ"
            o.rotation_euler = (0.0, 0.0, a - math.radians(90.0))
        p = os.path.join(FID_DIR, "_gc_hz_%s.png" % mode)
        if mode == "game":
            cam, hy = _gc_render(p, road_z=road_z)
        else:
            cam, hy = _gc_render(p, road_z=road_z, pitch=0.0, fov=40.0, res=(2400, 900))
        sp = os.path.join(FID_DIR, "_gc_hz_%s_sky.png" % mode)
        _compose(["--sky", p, "--horizon-y", str(hy), "--out", sp])
        outs.append(sp)
        labels.append("camera de joc (pitch 29; FOV 68); inelul la 295-345 m" if mode == "game"
                      else "panorama orizontala (FOV vertical 40) - aceeasi asezare")
        _rm(p)
    _compose(["--stack", ",".join(outs), "--labels", ",".join(labels),
              "--out", os.path.join(FID_DIR, "sf_horizon_ring.png")])
    _rm(*outs)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
todo = []
for a in args:
    if a.startswith("--compare="):
        todo += a.split("=", 1)[1].split(",")
if "--all" in args:
    todo = list(COMPARE)
for piece in todo:
    compare(piece)
if "--horizon-row" in args or "--all" in args:
    horizon_row()
if "--island-views" in args or "--all" in args:
    island_views()
if "--gc-turntable" in args or "--all" in args:
    gc_turntable()
if "--gc-sheds" in args or "--all" in args:
    gc_sheds()
if "--gc-island" in args or "--all" in args:
    gc_island()
if "--horizon-ring" in args or "--all" in args:
    horizon_ring()
if not args:
    print(__doc__)
