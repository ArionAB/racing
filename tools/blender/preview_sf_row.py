"""Randari de control pentru kitul casei de rand (San Francisco) — din GLB-ul
EXPORTAT, nu din scena de build.

Pe tiparul `preview_angkor.py`: fiecare fata pe culoarea slotului ei din atlas
(recuperat din UV) x AO; nodul `Row_Wall` primeste in schimb o TENTA PASTEL per
instanta, ca sa tina locul materialului de clasa din joc (scandura in cinci
pasteluri, brief §5). Cubul implicit si tot ce nu e piesa primesc
`hide_render` (memoria blender-preview-cub-implicit).

Moduri (prin run_build.py, argumentele dupa al doilea `--`):

  --compare <nume>  decupare (stanga) | randare (dreapta), 3/4 din fata ca pe
                    decupare, perete albastru-pal; casa pe un plan la cota
                    podelei (strada plata ingroapa fusta, brief §3.1)
                    -> docs/asset_briefs/img/sf_fidelity/<nume>.png
  --views <nume>    fata, 3/4 stanga, 3/4 dreapta, spate -> <nume>_views.png
  --row <nume>      pilotul din brief §9: 6 copii lipite (pas 7,0 m) pe o
                    strada in panta de 28 % (fiecare casa cu 1,96 m mai jos),
                    cinci pasteluri (unul repetat), fatadele la 10,5 m de axa
                    strazii, trotuar + carosabil in panta care taie fustele in
                    pana; camera de joc: 10 m deasupra strazii, 12,5 m in
                    spatele unui punct de pe axa, privind in jos la 29 de
                    grade, FOV vertical 68; soare jos (28 de grade), cald, din
                    fata-lateral; o cutie de 4,2 m (masina) pe strada. Doua
                    cadre: la vale si la deal -> <nume>_row_gamecam.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_sf_row.py -- --row sf_row_b_canted

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock` (daca esueaza,
alt proces randeaza), dupa, `rmdir`. Compunerea cu PIL e in compose_sf_row.py.
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
MODELS_DIR = os.path.join(PROJ, "assets", "models", "sanfrancisco", "buildings")
CROP_DIR = os.path.join(PROJ, "docs", "track_briefs", "img", "sf_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "sf_fidelity")

# hex-ul sloturilor, identic cu scripts/palette.gd (copiat din preview_angkor)
PALETTE_HEX = [
    "E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
    "BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
    "E54839", "2C82E8", "F2D03C",
    "54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
    "7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
    "E8622D", "D2A0BE",
]
SLOTS_N = 32

# cele cinci pasteluri ale scandurii (tinta de clasa; aproximative, din task)
PASTELS = {
    "cream": "#EFE3C2", "pink": "#E8B7B0", "blue": "#B4C6DA",
    "mint": "#B9D6BE", "butter": "#EDD68A",
}
ROW_ORDER = ["blue", "pink", "mint", "butter", "cream", "pink"]

# camera de joc (brief §2/§9)
GC_HEIGHT, GC_DIST, GC_PITCH, GC_FOV = 10.0, 12.5, 29.0, 68.0
GC_RES = (1920, 1080)
SLOPE = 0.28
PITCH_X = 7.0
FACADE_TO_AXIS = 10.5
YF = 6.0
CURB = 0.15
WALK_W = 3.0
# soarele: din fata-lateral, dinspre +X (vale); umbra bovindoului cade pe
# fatada spre -X, peste perechea de ferestre (brief §2: "fiecare bovindou isi
# arunca umbra pe fatada")
SUN_AZ = 45.0


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
    me = obj.data
    me.materials.clear()
    if override_hex:
        me.materials.append(_flat_material(override_hex))
        return
    uv = me.uv_layers.active
    if uv is None:
        me.materials.append(_flat_material("#FF00FF"))
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
    for n in ("Color", "Col", "COLOR_0"):
        if n in attrs:
            attrs[n].name = "AO"
            return


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)


def _glb(name):
    return os.path.join(MODELS_DIR, name + ".glb")


def _import(name, wall_hex, offset=(0.0, 0.0, 0.0)):
    """Importa GLB-ul; Row_Wall pe tenta `wall_hex`, restul pe sloturi."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=_glb(name))
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None:
            o.location = o.location + Vector(offset)
    bpy.context.view_layer.update()
    meshes = [o for o in new if o.type == "MESH"]
    for o in meshes:
        _fix_ao_layer_name(o)
        base = re.sub(r"\.\d{3}$", "", o.name)
        _per_slot_tint(o, wall_hex if base == "Row_Wall" else None)
    return meshes


def _engine(scene):
    ids = [x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in ids else "BLENDER_EEVEE_NEXT"


def _sun(name, direction, energy, color=(1.0, 1.0, 1.0), angle_deg=1.5):
    """Soare care LUMINEAZA in directia `direction` (vector de propagare)."""
    data = bpy.data.lights.new(name, type="SUN")
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    data.energy = energy
    data.color = color
    data.angle = math.radians(angle_deg)
    data.specular_factor = 0.0
    if hasattr(data, "use_shadow"):
        data.use_shadow = True
    obj.rotation_euler = Vector(direction).normalized().to_track_quat("-Z", "Y").to_euler()
    return obj


def _from_dir(az_deg, elev_deg):
    """Vectorul de propagare al luminii venite DIN azimutul `az_deg` (masurat de
    la +X spre +Y), elevatia `elev_deg`."""
    a, e = math.radians(az_deg), math.radians(elev_deg)
    return Vector((-math.cos(a) * math.cos(e), -math.sin(a) * math.cos(e), -math.sin(e)))


def _world(hex_color, strength):
    scene = bpy.context.scene
    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin(hex_color) + (1.0,)
        bg.inputs[1].default_value = strength


def _lights_off():
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)


def _cam():
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _hide_others(keep):
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in keep


def _quad_plane(name, pts, hex_color):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(p) for p in pts], [], [list(range(len(pts)))])
    me.update()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(_plain_material(name + "_m", hex_color))
    return obj


def _render_object(meshes, extra, path, azimuth, elevation, lens=60.0, margin=1.08,
                   res_height=900, aspect=0.8, frame_zmin=None):
    """3/4 cu incadrare automata (cautare binara pe distanta)."""
    scene = bpy.context.scene
    _hide_others(meshes + extra)
    bpy.context.view_layer.update()
    corners = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    if frame_zmin is not None:
        corners = [Vector((c.x, c.y, max(c.z, frame_zmin))) for c in corners]
    lo = Vector([min(c[i] for c in corners) for i in range(3)])
    hi = Vector([max(c[i] for c in corners) for i in range(3)])
    center = (lo + hi) * 0.5
    cam = _cam()
    cam.data.sensor_fit = "AUTO"
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 2000.0
    scene.render.resolution_x, scene.render.resolution_y = int(res_height * aspect), res_height
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))

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
    _lights_off()
    # soare de dupa-amiaza, lateral fata de camera, ca relieful sa arunce umbra
    _sun("KSun", _from_dir(azimuth + 40.0, 34.0), 3.0, color=_hex_lin("FFE7C8"))
    _sun("KFill", _from_dir(azimuth - 100.0, 40.0), 0.7)
    _world("CCCCCC", 0.55)
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
    script = os.path.join(HERE_P, "compose_sf_row.py")
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


def _ground_disc(z=0.0, hex_color="#BDBAB4", size=40.0):
    s = size
    return _quad_plane("PrevGround", [Vector((-s, -s, z)), Vector((s, -s, z)),
                                      Vector((s, s, z)), Vector((-s, s, z))], hex_color)


def compare(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    # varianta oglindita `_m` se pune langa decuparea casei de baza (la colt, `_m` are
    # turnuletul pe +X, ca decuparea)
    crop = os.path.join(CROP_DIR, re.sub(r"_m$", "", name) + ".png")
    _clear()
    meshes = _import(name, PASTELS["blue"])
    ground = _ground_disc()
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    # decuparea: fata + latura +X (garajul in stanga imaginii), usor de sus
    _render_object(meshes, [ground], tmp, azimuth=58.0, elevation=12.0, lens=60.0,
                   margin=1.06, res_height=res_height, aspect=cw / float(ch), frame_zmin=0.0)
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])
    _rm(tmp)


def views(name, res_height=800):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name, PASTELS["blue"])
    outs = []
    for tag, az, el in (("front", 90.0, 10.0), ("q3left", 132.0, 14.0),
                        ("q3right", 48.0, 14.0), ("back", 270.0, 14.0)):
        p = os.path.join(FID_DIR, "_view_%s_%s.png" % (name, tag))
        _render_object(meshes, [], p, azimuth=az, elevation=el, lens=60.0, margin=1.06,
                       res_height=res_height, aspect=0.75)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, name + "_views.png")])
    _rm(*outs)


def _street_h(x):
    """Cota axei/carosabilului: strada coboara spre +X cu 28 %."""
    return -SLOPE * x


def row(name, count=6):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    scene = bpy.context.scene
    houses = []
    for i in range(count):
        xc = PITCH_X * i
        # podeaua la cota trotuarului din capatul de SUS al casei (+ bordura)
        z = _street_h(xc - 3.5) + CURB
        houses += _import(name, PASTELS[ROW_ORDER[i % len(ROW_ORDER)]], offset=(xc, 0.0, z))
    axis_y = YF + FACADE_TO_AXIS
    x0, x1 = -60.0, 110.0
    walk_y0, walk_y1 = -8.0, YF + WALK_W
    road_y1 = axis_y + 7.5
    planes = [
        # trotuarul (continuat pe sub case: taie fustele in pana pe latura de vale)
        _quad_plane("PrevWalk", [Vector((x0, walk_y0, _street_h(x0) + CURB)),
                                 Vector((x1, walk_y0, _street_h(x1) + CURB)),
                                 Vector((x1, walk_y1, _street_h(x1) + CURB)),
                                 Vector((x0, walk_y1, _street_h(x0) + CURB))], "#B9B3A8"),
        # bordura
        _quad_plane("PrevCurb", [Vector((x0, walk_y1, _street_h(x0))),
                                 Vector((x1, walk_y1, _street_h(x1))),
                                 Vector((x1, walk_y1, _street_h(x1) + CURB)),
                                 Vector((x0, walk_y1, _street_h(x0) + CURB))], "#D8D2C6"),
        # carosabilul
        _quad_plane("PrevRoad", [Vector((x0, walk_y1, _street_h(x0))),
                                 Vector((x1, walk_y1, _street_h(x1))),
                                 Vector((x1, road_y1, _street_h(x1))),
                                 Vector((x0, road_y1, _street_h(x0)))], "#55555A"),
        # trotuarul de vizavi + teren
        _quad_plane("PrevFar", [Vector((x0, road_y1, _street_h(x0) + CURB)),
                                Vector((x1, road_y1, _street_h(x1) + CURB)),
                                Vector((x1, road_y1 + 40.0, _street_h(x1) + CURB)),
                                Vector((x0, road_y1 + 40.0, _street_h(x0) + CURB))], "#A9A397"),
    ]
    # masina-etalon: 4,2 x 1,9 x 1,3 m, pe axa, inclinata cu strada
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    car = bpy.context.active_object
    car.name = "PrevCar"
    car.scale = (4.2, 1.9, 1.3)
    car.data.materials.append(_plain_material("PrevCar_m", "#E54839"))
    planes.append(car)
    keep = houses + planes
    _hide_others(keep)

    _lights_off()
    # soare jos, cald, din fata-lateral: vine dinspre strada (+Y) si dinspre deal (-X)
    _sun("RowSun", _from_dir(SUN_AZ, 28.0), 3.6, color=_hex_lin("FFC890"), angle_deg=1.2)
    _world("9DB4C8", 0.45)
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = GC_RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.file_format = "PNG"
    cam = _cam()
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 600.0

    frames = []
    pitch = math.radians(GC_PITCH)
    for tag, px, sgn in (("vale", 2.0, 1.0), ("deal", PITCH_X * (count - 1) - 2.0, -1.0)):
        car.location = (px, axis_y - 1.8 * sgn, _street_h(px) + 0.65)
        car.rotation_euler = (0.0, math.atan(SLOPE), 0.0)
        cam.location = Vector((px - sgn * GC_DIST, axis_y, _street_h(px) + GC_HEIGHT))
        look = Vector((sgn * math.cos(pitch), 0.0, -math.sin(pitch)))
        cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()
        p = os.path.join(FID_DIR, "_row_%s_%s.png" % (name, tag))
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        frames.append(p)
    _compose(["--stack", ",".join(frames), "--labels",
              "la vale (camera spre +X), la deal (camera spre -X)",
              "--out", os.path.join(FID_DIR, name + "_row_gamecam.png")])
    _rm(*frames)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--row" in args:
    row(args[args.index("--row") + 1])
elif "--all" in args:
    _n = args[args.index("--all") + 1]
    compare(_n)
    views(_n)
    row(_n)
else:
    print(__doc__)
