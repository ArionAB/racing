"""Randari de control pentru kitul Monument Valley -- din GLB-urile EXPORTATE.

Pe tiparul `preview_jodhpur.py`, mai scurt. Cubul implicit si tot ce nu e
piesa primeste `hide_render` (memoria blender-preview-cub-implicit).

Moduri (rulate prin run_build.py, argumentele dupa al doilea `--`):

  --compare <nume>   decupare (stanga) | randare din GLB (dreapta), aceeasi
                     inaltime in pixeli, fundal #C8C8C8, lumina de zi neutra,
                     culoare REALA: fiecare fata pe culoarea slotului ei din
                     atlas (recuperat din UV), nodurile cu clasa pe hex-ul
                     clasei. -> docs/asset_briefs/img/monumentvalley_fidelity/<nume>.png
  --views <nume>     4 azimuturi ale piesei (control propriu, nu livrabil)
                     -> docs/asset_briefs/img/monumentvalley_fidelity/<nume>_views.png
  --solo <nume>      doar randarea (piese fara decupare)
  --sheet <val>      aduna comparatiile valului intr-o planșa
                     -> docs/asset_briefs/img/monumentvalley_fidelity_val<val>.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_monument.py -- --compare west_mitten

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock` (daca
esueaza, alt proces randeaza), dupa, `rmdir`.
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
MODELS_DIR = os.path.join(PROJ, "assets", "models", "monumentvalley")
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "monument_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "monumentvalley_fidelity")

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

# Clasa mv_sandstone (tinta in joc), doar pentru preview: nodurile *_Rock.
CLASS_HEX = {"mv_sandstone": "#B8552E"}

# Pe nume de nod: orice nod care se termina in _Rock primeste clasa (vezi _import).
ROCK_CLASS = "mv_sandstone"

# categorie, tente per nod, camera. Azimutul: camera la (cos a, sin a); fata
# piesei e +Y (azimut 90 = din fata). Degetul West Mitten e pe -X, deci in
# 3/4 din fata (azimut < 90, camera spre +X) apare pe dreapta, ca pe decupare.
SPECS = {
    "west_mitten": {"category": "rocks",
                    "camera": {"azimuth": 82.0, "elevation": 14.0, "lens": 70.0, "margin": 1.08}},
    # East Mitten: degetul e pe +X, deci pe decupare (dreapta) camera e din spate
    # (azimut 262: dreapta = +X)
    "east_mitten": {"category": "rocks",
                    "camera": {"azimuth": 262.0, "elevation": 14.0, "lens": 70.0, "margin": 1.08}},
    "merrick_butte": {"category": "rocks",
                      "camera": {"azimuth": 82.0, "elevation": 14.0, "lens": 70.0, "margin": 1.08}},
    # peretele de masa: fata (+X) spre camera, usor din lateral
    "mesa_wall_module": {"category": "rocks",
                         "camera": {"azimuth": 22.0, "elevation": 12.0, "lens": 70.0, "margin": 1.08},
                         "chain_axis": "y", "chain_step": 12.0,
                         "chain_camera": {"azimuth": 28.0, "elevation": 12.0, "lens": 60.0}},
    "sandstone_arch": {"category": "rocks",
                       "camera": {"azimuth": 70.0, "elevation": 9.0, "lens": 60.0, "margin": 1.08}},
    "sagebrush": {"category": "plants", "camera": {"azimuth": 90.0, "elevation": 12.0, "lens": 85.0, "margin": 1.15}},
    "juniper": {"category": "plants", "camera": {"azimuth": 90.0, "elevation": 8.0, "lens": 85.0, "margin": 1.12}},
    "yucca": {"category": "plants", "camera": {"azimuth": 90.0, "elevation": 12.0, "lens": 85.0, "margin": 1.15}},
    "rabbitbrush": {"category": "plants", "camera": {"azimuth": 90.0, "elevation": 12.0, "lens": 85.0, "margin": 1.15}},
    "tumbleweed": {"category": "plants", "camera": {"azimuth": 90.0, "elevation": 12.0, "lens": 85.0, "margin": 1.15}},
}


exec(open(os.path.join(HERE_P, "preview_specs_f.py")).read())   # mv-f

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


def _import(spec, name):
    path = os.path.join(MODELS_DIR, spec["category"], spec.get("glb", name) + ".glb")
    if not os.path.exists(path):
        print("LIPSA GLB:", path)
        return []
    reps, step = spec.get("repeat", (1, 0.0))
    meshes = []
    for _i in range(reps):
        bpy.ops.import_scene.gltf(filepath=path)
        got = [o for o in bpy.context.selected_objects if o.type in ("MESH", "EMPTY")]
        for o in got:
            if o.parent is None:
                o.location.y += (_i - (reps - 1) / 2.0) * step
        meshes += [o for o in got if o.type == "MESH"]
    only = spec.get("only")
    if only:                       # GLB cu mai multe noduri: pastreaza unul
        for o in list(meshes):
            if o.name.split(".")[0] != only:
                bpy.data.objects.remove(o, do_unlink=True)
                meshes.remove(o)
    bpy.context.view_layer.update()
    if spec.get("spread"):         # GLB cu siluete separate, toate la origine: le asezam in rand
        order = spec["spread"]
        meshes.sort(key=lambda o: order.index(o.name.split(".")[0])
                    if o.name.split(".")[0] in order else 99)
        x = 0.0
        for o in meshes:
            lo, hi = _bounds([o])
            o.location.x += x - lo.x
            x += (hi.x - lo.x) + spec.get("spread_gap", 25.0)
        bpy.context.view_layer.update()
    import re
    for o in meshes:
        _fix_ao_layer_name(o)
        base = re.sub(r"\.\d{3}$", "", o.name)
        cls = spec.get("tints", {}).get(base) or (ROCK_CLASS if base.endswith("_Rock") else None)
        _per_slot_tint(o, CLASS_HEX.get(cls, cls) if cls else None)
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


def _render(objs, path, azimuth=125.0, elevation=14.0, lens=85.0, margin=1.1,
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
    corners = []
    for o in objs:
        for c in o.bound_box:
            corners.append(o.matrix_world @ Vector(c))

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
    # centreaza silueta in cadru (centrul bbox nu e centrul vizual)
    place(hi_d)
    xs, ys = [], []
    for p in corners:
        v = world_to_camera_view(scene, cam, p)
        xs.append(v.x); ys.append(v.y)
    # (pastram centrul bbox: cadrul e simetric prin constructie)

    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    sdata = bpy.data.lights.new("KSun", type="SUN")
    sun = bpy.data.objects.new("KSun", sdata)
    scene.collection.objects.link(sun)
    sdata.energy = 2.6
    sdata.angle = math.radians(4.0)
    sdata.specular_factor = 0.0
    # soarele deasupra camerei, usor lateral
    sa = azimuth + 25.0
    sun.rotation_euler = (math.radians(58.0), 0.0, math.radians(sa + 90.0))
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
        bg.inputs[0].default_value = (0.8, 0.8, 0.8, 1.0)   # doar ambient; fundalul CFCFCF il pune compose
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
    script = os.path.join(HERE_P, "compose_monument.py")
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + args, capture_output=True, text=True)
            if r.returncode == 0:
                print(r.stdout.strip())
                return True
            print("compose_monument a esuat:", r.stderr.strip())
        except FileNotFoundError:
            continue
    return False


def _camera_for(spec):
    c = dict(azimuth=125.0, elevation=14.0, lens=85.0, margin=1.1)
    c.update(spec.get("camera", {}))
    return c


def compare(name, res_height=900):
    spec = SPECS[name]
    os.makedirs(FID_DIR, exist_ok=True)
    crop = os.path.join(CROPS, spec.get("crop", name) + ".png")
    if not os.path.exists(crop):
        print("LIPSA decupare:", crop)
        return
    _clear()
    meshes = _import(spec, name)
    if not meshes:
        return
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    aspect = max(0.5, min(8.0, cw / float(ch)))
    _render(meshes, tmp, res_height=res_height, aspect=aspect, **_camera_for(spec))
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])


def views(name, res_height=700):
    spec = SPECS[name]
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(spec, name)
    if not meshes:
        return
    outs = []
    for az in (35.0, 125.0, 215.0, 305.0):
        cam = _camera_for(spec)
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(meshes, p, res_height=res_height, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out",
              os.path.join(FID_DIR, name + "_views.png")])


def solo(name, res_height=900):
    spec = SPECS[name]
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(spec, name)
    if meshes:
        _render(meshes, os.path.join(FID_DIR, name + ".png"), res_height=res_height,
                **_camera_for(spec))


def chain(name, n=3, step=6.0, res_height=800):
    """n module alaturate pe X (capetele trebuie sa se imbine) -> <nume>_chain.png"""
    spec = SPECS[name]
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    allm = []
    axis = spec.get("chain_axis", "x")
    step = spec.get("chain_step", step)
    for i in range(n):
        ms = _import(spec, name)
        for o in ms:
            setattr(o.location, axis, getattr(o.location, axis) + (i - (n - 1) / 2.0) * step)
        allm += ms
    bpy.context.view_layer.update()
    cam = dict(_camera_for(spec))
    cam.update(spec.get("chain_camera", {}))
    _render(allm, os.path.join(FID_DIR, name + "_chain.png"), res_height=res_height,
            aspect=1.5, **cam)


exec(open(os.path.join(HERE_P, "preview_specs_c.py")).read())   # mv-c
exec(open(os.path.join(HERE_P, "preview_specs_d.py")).read())   # mv-d
exec(open(os.path.join(HERE_P, "preview_specs_e.py")).read())   # mv-e

argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--chain" in args:
    chain(args[args.index("--chain") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--solo" in args:
    solo(args[args.index("--solo") + 1])
elif "--sheet" in args:
    val = args[args.index("--sheet") + 1]
    names = args[args.index("--sheet") + 2].split(",")
    _compose(["--sheet", val, "--fid-dir", FID_DIR, "--names", ",".join(names),
              "--out", os.path.join(PROJ, "docs", "asset_briefs", "img",
                                    "monumentvalley_fidelity_val%s.png" % val)])
else:
    print(__doc__)
