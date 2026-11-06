"""Randari pentru FUNDALUL Angkor (`effects/angkor_horizon.glb`), din GLB-ul exportat.

Un nod = o piesa de inel, deci `preview_angkor.py --compare` (care ar suprapune toate
nodurile in origine) nu merge aici. Moduri (dupa al doilea `--`):

  --row    nodurile intinse intr-un rand, vazute din fata, sub decuparea de referinta
           -> docs/asset_briefs/img/angkor_fidelity/angkor_horizon_row.png
  --ring   nodurile AȘEZATE CA `Track._build_horizon`: pozitie centroid + (cos a, sin a) * d
           (conventia Godot: cos pe X, sin pe Z; est = +X = unghi 0, nord = -Z), `ground_y - 4
           + dy`, scala inelului, rotatie Y, fara umbra aruncata. Camera in centru la 10 m:
             * `_game`: camera de joc (fov vertical 68, inclinata ~28,7 grade in jos, ca
               ChaseCamera) -- ce vede jucatorul cu adevarat;
             * `_pano`: camera orizontala, fov orizontal 110 grade -- ca sa se citeasca toata banda.
           Spre EST si spre VEST, plus varianta `_dy` cu norii cobo­rati. Soarele: ~24 grade din
           VSV (soare in spate spre est, contra-lumina spre vest). Ceata aproximata la 42% peste
           piesa (fog_begin 120 / fog_end 280, curba 1,5, max 0,7 la ~230 m), cer degradat
           sky_top -> sky_horizon din tema `angkor`.
           -> angkor_horizon_ring_<est|vest>_<game|pano>[_dy].png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor_horizon.py -- --ring
RANDAREA RULEAZA PE GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
"""
import math
import os
import re
import sys

exec(open(os.path.join(os.path.dirname(__file__), "preview_angkor.py"), encoding="utf-8").read())

SKY_TOP = (0x3B, 0x35, 0x50)
SKY_HOR = (0x9C, 0x82, 0x96)
FOG = (0x85, 0x7A, 0x88)
GROUND = (0x36, 0x3A, 0x26)      # hill/ground_tint inchis, deja topit in ceata la departare

# (nod, unghi_deg, raza, scala, dy) -- propunerea de inele pentru tema `angkor`
RING = [
    ("StormBand_A", -20.0, 245.0, 1.0, 0.0),
    ("StormBand_B", 22.0, 240.0, 1.0, 0.0),
    ("KulenRidge", -52.0, 240.0, 1.0, 0.0),
    ("Paddies_W", 180.0, 235.0, 1.0, 0.0),
    ("Canopy_A", 35.0, 232.0, 1.0, 0.0),
    ("Canopy_B", 68.0, 232.0, 1.0, 0.0),
    ("Canopy_C", 102.0, 232.0, 1.0, 0.0),
    ("Canopy_A", 138.0, 232.0, 1.0, 0.0),
    ("Canopy_B", 152.0, 250.0, 1.0, 0.0),
    ("Canopy_C", 212.0, 232.0, 1.0, 0.0),
    ("Canopy_A", 244.0, 232.0, 1.0, 0.0),
    ("Canopy_B", 278.0, 232.0, 1.0, 0.0),
    ("Canopy_C", 310.0, 232.0, 1.0, 0.0),
    ("Canopy_A", 334.0, 232.0, 1.0, 0.0),
]

OUT = FID_DIR
HIDE_PREFIX = "@@"
GLB = os.path.join(ALL_MODELS, "angkor", "effects", "angkor_horizon.glb")


def _holdout(obj):
    me = obj.data
    me.materials.clear()
    mat = bpy.data.materials.new("Hold")
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    h = nt.nodes.new("ShaderNodeHoldout")
    nt.links.new(h.outputs[0], out.inputs["Surface"])
    me.materials.append(mat)


def _import_nodes():
    _clear()
    meshes = _import_path(GLB)
    by = {}
    for o in meshes:
        by[re.sub(r"\.\d{3}$", "", o.name)] = o
    return by


def _ground():
    bpy.ops.mesh.primitive_plane_add(size=1400.0, location=(0, 0, 0))
    g = bpy.context.active_object
    _holdout(g)
    return g


def _place_copy(src, name_suffix, angle_deg, dist, scale, dy, yaw=None):
    """Duplicat al nodului, asezat ca Track._build_horizon (Godot -> Blender: z_b = -z_g)."""
    o = src.copy()
    o.data = src.data
    o["orig"] = False
    o.hide_render = False
    o.hide_viewport = False
    bpy.context.scene.collection.objects.link(o)
    a = math.radians(angle_deg)
    o.location = (math.cos(a) * dist, -math.sin(a) * dist, -4.0 + dy)
    # tangenta la cerc: t = PI/2 - angle (comentariul din track.gd); Blender: rot_z = +yaw
    o.rotation_euler = (0.0, 0.0, (math.pi * 0.5 - a) if yaw is None else yaw)
    o.scale = (scale, scale, scale)
    return o


def _py(*args):
    import subprocess
    script = os.path.join(os.path.dirname(__file__), "compose_angkor_horizon.py")
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + [str(x) for x in args], capture_output=True, text=True)
            if r.returncode == 0:
                return True
            print("compose a esuat:", r.stderr.strip())
        except FileNotFoundError:
            continue
    return False


def _sky_composite(render_path, out_path, horizon_frac):
    _py("sky", render_path, out_path, horizon_frac)


def _render_cam(path, az_deg, game, res=(1920, 1080)):
    scene = bpy.context.scene
    cam = bpy.data.objects.get("RingCam")
    if cam is None:
        cam = bpy.data.objects.new("RingCam", bpy.data.cameras.new("RingCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cd = cam.data
    cd.clip_start, cd.clip_end = 0.5, 3000.0
    if game:
        cd.sensor_fit = "VERTICAL"
        cd.sensor_height = 24.0
        cd.lens = 12.0 / math.tan(math.radians(34.0))
        pitch = -math.degrees(math.atan2(9.6, 17.5))
        vfov = 68.0
    else:
        cd.sensor_fit = "HORIZONTAL"
        cd.sensor_width = 36.0
        cd.lens = 18.0 / math.tan(math.radians(55.0))
        pitch = 0.0
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(55.0)) * res[1] / res[0]))
    scene.render.resolution_x, scene.render.resolution_y = res
    cam.location = (0.0, 0.0, 10.0)
    a, p = math.radians(az_deg), math.radians(pitch)
    d = Vector((math.cos(a) * math.cos(p), math.sin(a) * math.cos(p), math.sin(p)))
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    # soarele din VSV la 24 grade: propagare spre ENE
    el = math.radians(24.0)
    _sun("RSun", Vector((math.cos(math.radians(22.5)) * math.cos(el),
                         math.sin(math.radians(22.5)) * math.cos(el), -math.sin(el))), 3.0,
         color=(1.0, 0.77, 0.54))
    world = scene.world or bpy.data.worlds.new("RW")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.45, 0.42, 0.6, 1.0)
        bg.inputs[1].default_value = 0.8
    scene.view_settings.view_transform = "Standard"
    _engine(scene)
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.file_format = "PNG"
    scene.render.resolution_percentage = 100
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o.name.startswith(HIDE_PREFIX) or o.get("orig", False)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    # orizontul in cadru: tan(-pitch)/tan(vfov/2) peste centru
    hor = 0.5 - 0.5 * math.tan(-p) / math.tan(math.radians(vfov / 2.0))
    return hor


def ring():
    os.makedirs(OUT, exist_ok=True)
    for variant, dy_storm in (("", 0.0), ("_dy", -34.0)):
        by = _import_nodes()
        placed = []
        for (name, ang, dist, sc, dy) in RING:
            if name not in by:
                continue
            ddy = dy + (dy_storm if name.startswith("StormBand") else 0.0)
            placed.append(_place_copy(by[name], name, ang, dist, sc, ddy))
        for o in by.values():
            o["orig"] = True
            o.hide_render = True
            o.hide_viewport = True
        _ground()
        for tag, az in (("est", 0.0), ("vest", 180.0), ("nordest", 38.0)):
            for kind in ("game", "pano"):
                if variant and kind == "game" and tag != "est":
                    continue
                if variant and tag == "nordest":
                    continue
                if tag == "nordest" and kind == "game":
                    continue
                raw = os.path.join(OUT, "_raw_ring.png")
                hor = _render_cam(raw, az, kind == "game",
                                  res=(1920, 1080) if kind == "game" else (2400, 760))
                out = os.path.join(OUT, "angkor_horizon_ring_%s_%s%s.png" % (tag, kind, variant))
                _sky_composite(raw, out, hor)
                print("scris", out)
        try:
            os.remove(os.path.join(OUT, "_raw_ring.png"))
        except OSError:
            pass


def row():
    os.makedirs(OUT, exist_ok=True)
    by = _import_nodes()
    order = ["Paddies_W", "Canopy_A", "Canopy_B", "Canopy_C", "KulenRidge", "StormBand_A", "StormBand_B"]
    x = 0.0
    objs = []
    for n in order:
        o = by[n]
        o.scale = (0.2, 0.2, 0.2)
        w = o.dimensions.x * 0.2
        o.location.x = x + w * 0.5
        o.location.y = 0.0
        o.location.z = 0.0
        x += w + 6.0
        objs.append(o)
    bpy.context.view_layer.update()
    raw = os.path.join(OUT, "_raw_row.png")
    _render(objs, raw, azimuth=-90.0, elevation=3.0, lens=40.0, margin=1.04, res_height=420,
            aspect=7.5, sun_elev=30.0, sun_az_off=60.0)
    p = os.path.join(OUT, "angkor_horizon_row.png")
    _py("row", raw, p, _find_crop("angkor_horizon"))
    os.remove(raw)
    print("scris", p)


_a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--row" in _a:
    row()
if "--ring" in _a:
    ring()
