"""Randari de control pentru tf-g (fundalul Transfagarasan) -- peste
`preview_transfagarasan.py`, fara sa-l modifice (tiparul preview_tf_f.py).

Moduri (argumentele dupa al doilea `--`):
  --compare ridge|cloud|plain   decupare | randare din GLB (ridge = FagarasRidge_A,
                                cloud = CloudSea_A, plain = FagarasPlain_A)
                                -> img/transfagarasan_fidelity/<nume>.png
  --views ridge|cloud|plain     4 azimuturi; `ridge` = A, B, C in 3 randuri
  --game                        CAPTURA DE LA DISTANTA DE JOC: piesele la ~300 m de camera de
                                joc (10 m sus, 12,5 m in spate, tinta la 5 m in fata si 0,4 m
                                sus, fov vertical 68), culoare reala, cer deschis; 2 cadre
                                (est: creasta + nori; nord: campia) x (fara ceata | cu ceata
                                temei: fog_begin 140, fog_end 370, culoarea = sky_horizon)
                                -> horizon_game_300m.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_tf_g.py -- --compare ridge

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import math
import os
import re
import subprocess
import sys

_argv_keep = sys.argv
sys.argv = ["preview_transfagarasan.py"]
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "preview_transfagarasan.py"), encoding="utf-8").read())
sys.argv = _argv_keep

from mathutils import Vector  # noqa: E402

GLB = "transfagarasan_horizon"
# grup -> (noduri, decupare, camera)
GROUPS = {
    "ridge": (["FagarasRidge_A"], "fagaras_ridge",
              dict(azimuth=90.0, elevation=7.0, lens=50.0, margin=1.04)),
    "cloud": (["CloudSea_A"], "cloud_sea",
              dict(azimuth=90.0, elevation=22.0, lens=50.0, margin=1.04)),
    "plain": (["FagarasPlain_A"], "fagaras_plain",
              dict(azimuth=90.0, elevation=17.0, lens=50.0, margin=1.04)),
}


def _white_ao(me):
    att = me.color_attributes.new("AO", "FLOAT_COLOR", "CORNER")
    for d in att.data:
        d.color = (1.0, 1.0, 1.0, 1.0)


def _box(name, center, size, hex_color):
    me = bpy.data.meshes.new(name)
    cx, cy, cz = center
    sx, sy, sz = (s * 0.5 for s in size)
    vs = [(cx + x * sx, cy + y * sy, cz + z * sz) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    fs = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata(vs, [], fs)
    me.update()
    _white_ao(me)
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(_flat_material(hex_color))
    return o


def _by_name():
    out = {}
    for o in bpy.data.objects:
        if o.type == "MESH":
            out[re.sub(r"\.\d{3}$", "", o.name)] = o
    return out


def _load():
    _clear()
    meshes = _import(GLB)
    return {re.sub(r"\.\d{3}$", "", o.name): o for o in meshes}


def compare(group, res_height=900):
    names, crop_name, cam = GROUPS[group]
    os.makedirs(FID_DIR, exist_ok=True)
    crop = os.path.join(CROPS, crop_name + ".png")
    nodes = _load()
    sel = [nodes[n] for n in names]
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    tmp = os.path.join(FID_DIR, "_render_" + group + ".png")
    _render(sel, tmp, res_height=res_height, aspect=max(0.5, min(8.0, cw / float(ch))), **cam)
    _compose(["--compare", crop_name, "--crop", crop, "--render", tmp,
              "--out", os.path.join(FID_DIR, crop_name + ".png"), "--height", str(res_height)])
    try:
        os.remove(tmp)
    except OSError:
        pass


def views(group, res_height=620):
    names, crop_name, cam = GROUPS[group]
    os.makedirs(FID_DIR, exist_ok=True)
    nodes = _load()
    if group == "ridge":
        names = ["FagarasRidge_A", "FagarasRidge_B", "FagarasRidge_C"]
        azs = (90.0,)
        cam = dict(cam)
        rows = []
        for n in names:
            p = os.path.join(FID_DIR, "_v_%s.png" % n)
            _render([nodes[n]], p, res_height=res_height, aspect=2.6, **cam)
            rows.append(p)
            for az in (35.0, 215.0):
                c2 = dict(cam); c2["azimuth"] = az; c2["elevation"] = 14.0
                p2 = os.path.join(FID_DIR, "_v_%s_%d.png" % (n, int(az)))
                _render([nodes[n]], p2, res_height=res_height, aspect=2.6, **c2)
                rows.append(p2)
        _grid(rows, 3, os.path.join(FID_DIR, "fagaras_ridge_views.png"))
        return
    outs = []
    for az in (35.0, 125.0, 215.0, 305.0):
        c2 = dict(cam); c2["azimuth"] = az
        p = os.path.join(FID_DIR, "_v_%s_%d.png" % (group, int(az)))
        _render([nodes[names[0]]], p, res_height=res_height, aspect=2.2, **c2)
        outs.append(p)
    _grid(outs, 2, os.path.join(FID_DIR, crop_name + "_views.png"))


def _grid(paths, cols, out, labels=None, width=900):
    script = os.path.join(HERE_P, "compose_tf_g.py")
    flat = []
    for p in paths:
        flat.append(p)
    args = ["--grid", ",".join(flat), "--cols", str(cols), "--out", out, "--width", str(width)]
    if labels:
        args += ["--labels", ";".join(labels)]
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + args, capture_output=True, text=True)
            if r.returncode == 0:
                print(r.stdout.strip())
                break
            print("compose_tf_g a esuat:", r.stderr.strip())
        except FileNotFoundError:
            continue
    for p in paths:
        try:
            os.remove(p)
        except OSError:
            pass


# ---------------------------------------------------------------------------
# captura de la distanta de joc
# ---------------------------------------------------------------------------

FOG_HEX = "#DBE0E6"        # sky_horizon (0.86, 0.88, 0.90) al temei
SKY_TOP = (0.18, 0.44, 0.82)
SKY_HOR = (0.86, 0.88, 0.90)


def _fog_material(hex_color, fog_on):
    name = "KFog%d_%s" % (1 if fog_on else 0, hex_color.lstrip("#"))
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
    if not fog_on:
        nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
        return mat
    # ceata ca in Godot: se amesteca DUPA iluminare, liniar intre fog_begin si fog_end
    emi = nt.nodes.new("ShaderNodeEmission")
    fr, fg, fb = _hex_lin(FOG_HEX)
    emi.inputs["Color"].default_value = (fr, fg, fb, 1.0)
    emi.inputs["Strength"].default_value = 1.0
    cam = nt.nodes.new("ShaderNodeCameraData")
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = 140.0
    mr.inputs["From Max"].default_value = 370.0
    mr.inputs["To Min"].default_value = 0.0
    mr.inputs["To Max"].default_value = 1.0
    mr.clamp = True
    nt.links.new(mr.inputs["Value"], cam.outputs["View Distance"])
    ms = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(ms.inputs[0], mr.outputs["Result"])
    nt.links.new(ms.inputs[1], bsdf.outputs["BSDF"])
    nt.links.new(ms.inputs[2], emi.outputs["Emission"])
    nt.links.new(ms.outputs["Shader"], out.inputs["Surface"])
    return mat


def _refog(obj, fog_on):
    """Inlocuieste materialele plate ale harnasului cu varianta cu/fara ceata."""
    for i, m in enumerate(list(obj.data.materials)):
        hexc = "#" + m.name.split("_")[-1]
        obj.data.materials[i] = _fog_material(hexc, fog_on)


def _sky_world():
    scene = bpy.context.scene
    world = bpy.data.worlds.new("KSky")
    scene.world = world
    world.use_nodes = True
    nt = world.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    mr = nt.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value = 0.0
    mr.inputs["From Max"].default_value = 0.55
    mr.clamp = True
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.inputs[6].default_value = tuple(_srgb_to_linear(c) for c in SKY_HOR) + (1.0,)
    mix.inputs[7].default_value = tuple(_srgb_to_linear(c) for c in SKY_TOP) + (1.0,)
    nt.links.new(sep.inputs[0], tc.outputs["Generated"])
    nt.links.new(mr.inputs["Value"], sep.outputs["Z"])
    nt.links.new(mix.inputs["Factor"], mr.outputs["Result"])
    nt.links.new(bg.inputs["Color"], mix.outputs[2])
    bg.inputs["Strength"].default_value = 1.0
    nt.links.new(out.inputs["Surface"], bg.outputs["Background"])


def _lights():
    scene = bpy.context.scene
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    # soare de dupa-amiaza, cald (#FFD9A8), ~33 grade elevatie, dinspre stanga-fata (lumineaza fetele orientate spre camera)
    d = Vector((0.50, 0.62, -0.60)).normalized()
    sd = bpy.data.lights.new("KSun", type="SUN")
    sd.energy = 3.1
    sd.color = (1.0, 0.85, 0.66)
    sd.angle = math.radians(3.0)
    sd.specular_factor = 0.0
    so = bpy.data.objects.new("KSun", sd)
    scene.collection.objects.link(so)
    so.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    # ambient rece (#B8CCE0) ca al doilea soare slab, de sus
    fd = bpy.data.lights.new("KFill", type="SUN")
    fd.energy = 0.55
    fd.color = (0.72, 0.80, 0.88)
    fd.specular_factor = 0.0
    fo = bpy.data.objects.new("KFill", fd)
    scene.collection.objects.link(fo)
    fo.rotation_euler = Vector((-0.25, 0.35, -0.9)).normalized().to_track_quat("-Z", "Y").to_euler()


def _place(obj, x, y, z, yaw_deg=0.0, scale=1.0):
    obj.location = (x, y, z)
    obj.rotation_euler = (0.0, 0.0, math.radians(yaw_deg))
    obj.scale = (scale, scale, scale)


def _game_cam(res):
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(68.0)
    cam.data.clip_start = 0.1
    cam.data.clip_end = 380.0          # ChaseCamera.FAR_PLANE
    cam.location = Vector((0.0, -12.5, 10.0))
    look = (Vector((0.0, 5.0, 0.4)) - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res


def _plane(name, x0, x1, y0, y1, z, hex_color):
    me = bpy.data.meshes.new(name)
    me.from_pydata([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], [], [(0, 1, 2, 3)])
    me.update()
    att = me.color_attributes.new("AO", "FLOAT_COLOR", "CORNER")
    for d in att.data:
        d.color = (1.0, 1.0, 1.0, 1.0)
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(_flat_material(hex_color))
    return o


def game(res=(1280, 720)):
    os.makedirs(FID_DIR, exist_ok=True)
    scene = bpy.context.scene
    frames = []
    labels = []
    # (cadru, [(nod, x, y, z, yaw, scara)]): pozitiile sunt FATA DE MASINA (la origine, fata
    # spre +Y); `_build_horizon` pune nodul la ground_y - 4 si scaleaza 0,85-1,2 x inel.
    #   est   : creasta (A in centru, B stanga, C dreapta) la 300 m, baza la -4 m, scara 1,1;
    #           marea de nori in vai, SUB cota drumului (-26 m), la 330 m
    #   nord  : campia la 300 m, in vale (-30 m sub drum: se priveste de pe munte spre Tara
    #           Fagarasului), scara 1,0
    sets = {
        "est": [("FagarasRidge_A", 10, 300, -4, 0, 1.1), ("FagarasRidge_B", -230, 306, -4, 20, 1.1),
                ("FagarasRidge_C", 225, 298, -4, 170, 1.1), ("CloudSea_A", -95, 335, -26, 0, 1.0),
                ("CloudSea_B", 150, 330, -24, 200, 1.0)],
        "nord": [("FagarasPlain_A", 0, 300, -30, 0, 1.0)],
    }
    for frame, items in sets.items():
        for fog_on in (False, True):
            _clear()
            nodes = _load()
            keep = []
            for (n, x, y, z, yaw, sc) in items:
                _place(nodes[n], x, y, z, yaw, sc)
                keep.append(nodes[n])
            for n, o in nodes.items():
                if o not in keep:
                    o.hide_render = True
            # sol aproape (pajiste #7D9A4E), drumul de 14 m si o masina de talie
            ground = _plane("PreviewGround", -400, 400, -60, 40, 0.0, "#7D9A4E")
            road = _plane("PreviewRoad", -7, 7, -60, 40, 0.02, "#6A6866")
            car = _box("PreviewCar", (0.0, 0.0, 0.75), (2.2, 3.8, 1.0), "#C03030")
            for o in keep + [ground, road, car]:
                _refog(o, fog_on)
            for o in bpy.data.objects:
                if o.type == "MESH":
                    o.hide_render = o not in keep + [ground, road, car]
            _sky_world()
            _lights()
            _game_cam(res)
            scene.render.film_transparent = False
            scene.view_settings.view_transform = "Standard"
            scene.view_settings.look = "None"
            scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [
                x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
            ] else "BLENDER_EEVEE_NEXT"
            scene.render.resolution_percentage = 100
            scene.render.image_settings.file_format = "PNG"
            scene.render.image_settings.color_mode = "RGB"
            p = os.path.join(FID_DIR, "_game_%s_%d.png" % (frame, 1 if fog_on else 0))
            scene.render.filepath = p
            bpy.ops.render.render(write_still=True)
            frames.append(p)
            labels.append("%s, %s" % ("est: creasta + nori" if frame == "est" else "nord: campia",
                                      "cu ceata temei (fog 140-370)" if fog_on else "culoare reala, fara ceata"))
    _grid(frames, 2, os.path.join(FID_DIR, "horizon_game_300m.png"), labels, width=960)


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--game" in args:
    game()
else:
    print(__doc__)
