"""Randari de control pentru kitul Okinawa v2 -- din GLB-urile EXPORTATE.

Pe tiparul `preview_monument.py`. Cubul implicit si tot ce nu e piesa primesc
`hide_render` (memoria blender-preview-cub-implicit).

Moduri (rulate prin run_build.py, argumentele dupa al doilea `--`):

  --compare <nume>   decupare (stanga) | randare din GLB (dreapta), aceeasi
                     inaltime in pixeli, 3/4 din fata, fundal #C8C8C8, lumina
                     de zi neutra, culoare REALA: fiecare fata pe culoarea
                     slotului ei din atlas (recuperat din UV); nodurile
                     *_Limestone pe #CFC6B0, *_Lacquer pe #B3261E (tintele
                     claselor). -> docs/asset_briefs/img/okinawa_fidelity/<nume>.png
  --views <nume>     4 azimuturi ale piesei -> <nume>_views.png
  --tunnel           (ok-c) 6 fukugi la 3,5 m pe doua siruri, vedere din axa
                     (1,5 m inaltime) | 3/4 de sus -> fukugi_tunnel.png
  --sheet <val> a,b  aduna comparatiile intr-o plansa
                     -> docs/asset_briefs/img/okinawa_fidelity_val<val>.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_okinawa.py -- --compare ryukyu_gate

Decuparile: docs/track_briefs/img/okinawa_assets_v1/<nume>.png. GLB-ul se
cauta in assets/models/okinawa/<categorie>/<nume>.glb (categoria se gaseste
singura). Compunerea de imagini cu PIL e in compose_monument.py (generica).

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
MODELS_DIR = os.path.join(PROJ, "assets", "models", "okinawa")
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "okinawa_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "okinawa_fidelity")

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
CLASS_BY_SUFFIX = {"_Limestone": "#CFC6B0", "_Lacquer": "#B3261E", "_Roof": "#B8452E"}

# camera: azimutul: camera la (cos a, sin a); fata piesei e +Y (azimut 90 =
# din fata). 3/4 din fata = azimut ~60 (camera spre +X), ca pe decupari.
SPECS = {
    "ryukyu_gate": {"camera": {"azimuth": 68.0, "elevation": 22.0, "lens": 60.0, "margin": 1.08}},
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


def _camera_for(name):
    c = dict(azimuth=58.0, elevation=18.0, lens=60.0, margin=1.1)
    c.update(SPECS.get(name, {}).get("camera", {}))
    return c


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


# --- ok-c: plantele (specs de camera + captura de tunel) ---------------------
# floarea bougainvillea: tinta magenta #C2378F (tenta de clasa la integrare)
CLASS_BY_SUFFIX["_Bloom"] = "#C2378F"
SPECS.update({
    "limestone_cliff_module_b": {"crop": "limestone_cliff_module"},
    "fukugi_tree_a": {"camera": {"azimuth": 58.0, "elevation": 10.0, "lens": 60.0, "margin": 1.08}},
    "fukugi_tree_b": {"camera": {"azimuth": 58.0, "elevation": 10.0, "lens": 60.0, "margin": 1.08}},
    "fukugi_tree_c": {"camera": {"azimuth": 58.0, "elevation": 10.0, "lens": 60.0, "margin": 1.08}},
    "ryukyu_pine": {"camera": {"azimuth": 80.0, "elevation": 12.0, "lens": 60.0, "margin": 1.08}},
    "cycad": {"camera": {"azimuth": 60.0, "elevation": 18.0, "lens": 60.0, "margin": 1.08}},
    "fan_palm": {"camera": {"azimuth": 60.0, "elevation": 10.0, "lens": 60.0, "margin": 1.08}},
    "bougainvillea": {"camera": {"azimuth": 75.0, "elevation": 20.0, "lens": 60.0, "margin": 1.08}},
})


def _scene_lights(azimuth=58.0):
    scene = bpy.context.scene
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
    scene.render.image_settings.file_format = "PNG"


def _render_cam(path, loc, target, lens, res):
    scene = bpy.context.scene
    cam = bpy.data.objects.get("TunnelCam")
    if cam is None:
        cam = bpy.data.objects.new("TunnelCam", bpy.data.cameras.new("TunnelCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = lens
    cam.data.clip_start = 0.1
    cam.data.clip_end = 500.0
    cam.location = Vector(loc)
    look = (Vector(target) - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def tunnel(res_height=760, spacing=3.5, row_x=4.0):
    """Captura de tunel (POI B): 6 fukugi (amestec a/b/c) la `spacing` m pe doua
    siruri la +-`row_x` m de axa, pe nisip alb. Doua vederi lipite: din axa, de
    la 1,5 m inaltime, spre interiorul aleii | 3/4 de sus. Trebuie sa citeasca
    PERETE continuu, nu sir de bile.
    -> docs/asset_briefs/img/okinawa_fidelity/fukugi_tunnel.png"""
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    protos = {v: _import("fukugi_tree_" + v) for v in "abc"}
    for ms in protos.values():
        for o in ms:
            o.hide_render = True
    rows = [(-row_x, "abc"), (row_x, "cab")]
    ys = [-spacing, 0.0, spacing]
    rnd = [0.3, 2.1, 4.0, 5.2, 1.1, 3.3]
    k = 0
    for x, order in rows:
        for y, v in zip(ys, order):
            for o in protos[v]:
                c = o.copy()
                bpy.context.collection.objects.link(c)
                c.hide_render = False
                c.location = (x, y, 0.0)
                c.rotation_euler = (0.0, 0.0, rnd[k])
            k += 1
    # nisipul alb al aleii
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.active_object
    ground.scale = (22.0, 40.0, 1.0)
    gm = bpy.data.materials.new("KSand")
    gm.diffuse_color = (0.80, 0.72, 0.55, 1.0)
    gm.use_nodes = True
    gb = gm.node_tree.nodes.get("Principled BSDF")
    gb.inputs["Base Color"].default_value = (0.80, 0.72, 0.55, 1.0)
    gb.inputs["Roughness"].default_value = 1.0
    ground.data.materials.append(gm)
    _scene_lights(58.0)
    res_a = (int(res_height * 1.35), res_height)
    res_b = (int(res_height * 0.9), res_height)
    a = os.path.join(FID_DIR, "_tunnel_axis.png")
    b = os.path.join(FID_DIR, "_tunnel_top.png")
    L = spacing * 1.0
    _render_cam(a, (0.0, -L * 2.6, 1.5), (0.0, L * 2.0, 3.2), 22.0, res_a)
    _render_cam(b, (9.5, -11.5, 8.5), (0.0, 0.0, 3.2), 34.0, res_b)
    _compose(["--montage", a + "," + b, "--out", os.path.join(FID_DIR, "fukugi_tunnel.png")])
    for p in (a, b):
        try:
            os.remove(p)
        except OSError:
            pass

def chain(name, n=3, step=None, res_height=700):
    """`n` copii ale modulului puse cap la cap pe Y (pas = extinderea pe Y a
    modulului sau `step`): arata daca modulele inlantuite dau un tipar repetat.
    `name` poate fi o lista separata prin virgula (a,b): piesele alterneaza
    (a-b-a-b). -> docs/asset_briefs/img/okinawa_fidelity/<primul nume>_chain.png"""
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    names = name.split(",")
    allm = []
    first = _import(names[0])
    if not first:
        return
    lo, hi = _bounds(first)
    L = step if step else (hi.y - lo.y)
    allm += first
    for i in range(1, n):
        ms = _import(names[i % len(names)])
        for o in ms:
            o.location.y += i * L
        allm += ms
    bpy.context.view_layer.update()
    out = os.path.join(FID_DIR, names[0] + "_chain.png")
    cam = _camera_for(names[0])
    cam["azimuth"] = 25.0
    _render(allm, out, res_height=res_height, aspect=2.4, **cam)
    print("lant:", out)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--chain" in args:
    i = args.index("--chain")
    chain(args[i + 1], int(args[i + 2]) if len(args) > i + 2 and args[i + 2].isdigit() else 3)
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--sheet" in args:
    val = args[args.index("--sheet") + 1]
    names = args[args.index("--sheet") + 2].split(",")
    _compose(["--sheet", val, "--fid-dir", FID_DIR, "--names", ",".join(names),
              "--out", os.path.join(PROJ, "docs", "asset_briefs", "img",
                                    "okinawa_fidelity_val%s.png" % val)])
elif "--tunnel" in args:
    tunnel()
else:
    print(__doc__)
