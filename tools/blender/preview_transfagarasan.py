"""Randari de control pentru kitul Transfagarasan -- din GLB-urile EXPORTATE.

Pe tiparul `preview_okinawa.py`. Cubul implicit si tot ce nu e piesa primesc
`hide_render` (memoria blender-preview-cub-implicit).

Moduri (rulate prin run_build.py, argumentele dupa al doilea `--`):

  --compare <nume>   decupare (stanga) | randare din GLB (dreapta), aceeasi
                     inaltime in pixeli, 3/4 din fata, fundal #C4C4C4, lumina
                     de zi neutra, culoare REALA: fiecare fata pe culoarea
                     slotului ei din atlas (recuperat din UV); nodurile
                     *_Snow pe #E8ECEE, *_Concrete pe #B8B4AA, *_Schist pe #7E8478
                     (tintele claselor). -> docs/asset_briefs/img/transfagarasan_fidelity/<nume>.png
  --views <nume>     4 azimuturi ale piesei -> <nume>_views.png
  --sheet <val> a,b  aduna comparatiile intr-o plansa
                     -> docs/asset_briefs/img/transfagarasan_fidelity_val<val>.png

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_transfagarasan.py -- --compare tunnel_portal_balea

Decuparile: docs/track_briefs/img/transfagarasan_assets_v1/<nume>.png. GLB-ul se
cauta in assets/models/transfagarasan/<categorie>/<nume>.glb (categoria se
gaseste singura). Compunerea de imagini cu PIL e in compose_transfagarasan.py.

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock` (daca
esueaza, alt proces randeaza), dupa, `rmdir`.
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
MODELS_DIR = os.path.join(PROJ, "assets", "models", "transfagarasan")
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "transfagarasan_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "transfagarasan_fidelity")

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

# tintele claselor (tinta in joc), doar pentru preview, pe sufixul nodului
CLASS_BY_SUFFIX = {"_Schist": "#7E8478", "_Snow": "#E8ECEE", "_Concrete": "#B8B4AA",
                   # tf-b: jneapanul e pe LOG_DARK 28 (maro) doar ca slot de
                   # rezerva; culoarea o da clasa pine_needles -> tinta brief §4
                   "_Needles": "#34503A"}

# camera: azimutul: camera la (cos a, sin a); fata piesei e +Y (azimut 90 =
# din fata). 3/4 din fata = azimut ~60 (camera spre +X), ca pe decupari.
SPECS = {
    # pilot: portalul se citeste din fata, putin dinspre +X (decuparea il arata
    # cu fata si flancul stang in imagine = camera spre +X)
    "tunnel_portal_balea": {"camera": {"azimuth": 62.0, "elevation": 14.0, "lens": 60.0, "margin": 1.08}},
    # tf-b: plantele joase sunt desenate de SUS pe plansa (~25-30 grade), nu la 18
    "jneapan_a": {"camera": {"elevation": 28.0}},
    "jneapan_b": {"camera": {"elevation": 28.0}},
    "bujor_de_munte": {"camera": {"elevation": 26.0}},
    "afin": {"camera": {"elevation": 24.0}},
}


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
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _find_glb(name):
    if os.path.isdir(MODELS_DIR):
        for cat in sorted(os.listdir(MODELS_DIR)):
            p = os.path.join(MODELS_DIR, cat, name + ".glb")
            if os.path.exists(p):
                return p
    return None


def _import(name):
    path = _find_glb(name)
    if path is None:
        print("LIPSA GLB:", name)
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    got = [o for o in bpy.context.selected_objects if o.type in ("MESH", "EMPTY")]
    meshes = [o for o in got if o.type == "MESH"]
    bpy.context.view_layer.update()
    for o in meshes:
        _fix_ao_layer_name(o)
        base = re.sub(r"\.\d{3}$", "", o.name)
        hexc = None
        for suf, h in CLASS_BY_SUFFIX.items():
            if base.endswith(suf):
                hexc = h
        _per_slot_tint(o, hexc)
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


def _render(objs, path, azimuth=58.0, elevation=18.0, lens=60.0, margin=1.1,
            res_height=900, aspect=0.8):
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
            xs.append(v.x); ys.append(v.y)
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
    sdata = bpy.data.lights.new("KSun", type="SUN")
    sun = bpy.data.objects.new("KSun", sdata)
    scene.collection.objects.link(sun)
    sdata.energy = 2.6
    sdata.angle = math.radians(4.0)
    sdata.specular_factor = 0.0
    sun.rotation_euler = (math.radians(58.0), 0.0, math.radians(azimuth + 25.0 + 90.0))
    fdata = bpy.data.lights.new("KFill", type="SUN")
    fill = bpy.data.objects.new("KFill", fdata)
    scene.collection.objects.link(fill)
    fdata.energy = 0.9
    fdata.specular_factor = 0.0
    fill.rotation_euler = (math.radians(70.0), 0.0, math.radians(azimuth - 70.0 + 90.0 + 180.0))

    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.8, 0.8, 0.8, 1.0)
        bg.inputs[1].default_value = 0.55
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [
        x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    ] else "BLENDER_EEVEE_NEXT"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    return path


def _compose(args):
    script = os.path.join(HERE_P, "compose_transfagarasan.py")
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + args, capture_output=True, text=True)
            if r.returncode == 0:
                print(r.stdout.strip())
                return True
            print("compose_transfagarasan a esuat:", r.stderr.strip())
        except FileNotFoundError:
            continue
    return False


def _camera_for(name):
    c = dict(azimuth=58.0, elevation=18.0, lens=60.0, margin=1.1)
    c.update(SPECS.get(name, {}).get("camera", {}))
    return c


def _backdrop(name):
    """Doar in preview: plan negru in spatele gurii (in joc tunelul continua in
    teren). Portalul: y = -12 (Blender), sub gura, ca fundalul gri sa nu se vada."""
    if name != "tunnel_portal_balea":
        return []
    me = bpy.data.meshes.new("PreviewBackdrop")
    vs = [(-9, -12, 0), (9, -12, 0), (9, -12, 10), (-9, -12, 10)]
    me.from_pydata(vs, [], [(0, 1, 2, 3)])
    me.update()
    o = bpy.data.objects.new("PreviewBackdrop", me)
    bpy.context.collection.objects.link(o)
    me.materials.append(_flat_material("#050505"))
    return [o]


def compare(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = os.path.join(CROPS, SPECS.get(name, {}).get("crop", name) + ".png")
    if not os.path.exists(crop):
        print("LIPSA decupare:", crop)
        return
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    meshes += _backdrop(name)
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    aspect = max(0.5, min(8.0, cw / float(ch)))
    _render(meshes, tmp, res_height=res_height, aspect=aspect, **_camera_for(name))
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])
    try:
        os.remove(tmp)
    except OSError:
        pass


def views(name, res_height=700):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    meshes += _backdrop(name)
    outs = []
    for az in (35.0, 125.0, 215.0, 305.0):
        cam = _camera_for(name)
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(meshes, p, res_height=res_height, aspect=1.4, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out",
              os.path.join(FID_DIR, name + "_views.png")])
    for p in outs:
        try:
            os.remove(p)
        except OSError:
            pass



argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--sheet" in args:
    val = args[args.index("--sheet") + 1]
    names = args[args.index("--sheet") + 2].split(",")
    _compose(["--sheet", val, "--fid-dir", FID_DIR, "--names", ",".join(names),
              "--out", os.path.join(PROJ, "docs", "asset_briefs", "img",
                                    "transfagarasan_fidelity_val%s.png" % val)])
else:
    print(__doc__)
