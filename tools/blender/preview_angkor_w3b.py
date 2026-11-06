"""Ansambluri de control pentru grupul B, val 3: galeria (colt + 3 travee) si coltul Bakheng
(3 etaje in trepte, scara, turnulet). `preview_angkor.py` ramane neatins; i se refoloseste
functiile.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor_w3b.py -- --gallery
    ... -- preview_angkor_w3b.py -- --bakheng

Galeria: coltul in origine, bratul A spre -Y (3 travee de 4 m: zid de relief pe x = +1,7
rotit 90 grade, stalpi pe x = -1,5 la imbinari, acoperis la cota 3,5), bratul B spre -X
(1 travee). Stalpii colturii (la -1,5/-2,0 si -2,0/-1,5) sunt cei de la capetele bratelor.
-> docs/asset_briefs/img/angkor_fidelity/gallery_assembly.png / bakheng_assembly.png
"""
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_saved = sys.argv
sys.argv = [_saved[0], "--", "--none"]
exec(open(os.path.join(_here, "preview_angkor.py"), encoding="utf-8").read())
sys.argv = _saved


def _put(name, loc, yaw=0.0):
    path = _find_glb(name)
    meshes = _import_path(path)
    for o in meshes:
        o.hide_render = False
        if o.parent is None:
            o.rotation_euler = (0.0, 0.0, math.radians(yaw))
            o.location = Vector(loc)
    bpy.context.view_layer.update()
    return meshes


def _stage(ground_hex="#6E7A4A"):
    scene = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=600.0, location=(0.0, 0.0, -0.02))
    bpy.context.active_object.data.materials.append(_plain_material("GCGround", ground_hex))
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    el, yaw = math.radians(GC_SUN_ELEV + 14), math.radians(GC_SUN_YAW + 40)
    d = Vector((math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el)))
    _sun("GCSun", d, 3.4, color=_hex_lin("FFC48A"), angle_deg=1.5)
    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin("9C8296") + (1.0,)
        bg.inputs[1].default_value = 0.4
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.file_format = "PNG"
    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.clip_start = 0.3
    cam.data.clip_end = 380.0
    return scene, cam


def _shot(scene, cam, loc, target, fov, res, path):
    cam.data.angle = math.radians(fov)
    cam.location = Vector(loc)
    cam.rotation_euler = (Vector(target) - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.context.view_layer.update()
    bpy.ops.render.render(write_still=True)
    return path


def gallery():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    _put("gallery_corner", (0, 0, 0))
    for i in range(3):
        yc = -4.0 - 4.0 * i
        _put("gallery_relief_wall", (1.7, yc, 0), 90.0)
        _put("gallery_roof", (0, yc, 3.5))
    for yc in (-2.0, -6.0, -10.0, -14.0):
        _put("gallery_column", (-1.5, yc, 0))
    # bratul B, o travee spre -X
    _put("gallery_relief_wall", (-4.0, 1.7, 0), 180.0)
    _put("gallery_roof", (-4.0, 0, 3.5), 90.0)
    for xc in (-2.0, -6.0):
        _put("gallery_column", (xc, -1.5, 0))
    scene, cam = _stage()
    outs = []
    outs.append(_shot(scene, cam, (-13.0, 3.0, 7.5), (-1.0, -5.0, 2.2), 45, (1600, 900), os.path.join(FID_DIR, "_ga1.png")))
    outs.append(_shot(scene, cam, (-9.0, -22.0, 3.0), (-1.5, -8.0, 2.4), 55, (1600, 900), os.path.join(FID_DIR, "_ga2.png")))
    car = Vector((-5.5, -24.0, 0.0))
    outs.append(_shot(scene, cam, car + Vector((0, -GC_DIST, GC_HEIGHT)), car + Vector((0, GC_LOOK_AHEAD + 10, GC_LOOK_HEIGHT)),
                      GC_FOV, (1600, 900), os.path.join(FID_DIR, "_ga3.png")))
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "gallery_assembly.png")])
    _rm(*outs)


def bakheng():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    for c in range(3):
        _put("bakheng_terrace_tier", (0.0, -0.9 * c, 1.5 * c))
    _put("bakheng_shrine_tower", (0.0, -2.2, 4.5))
    _put("bakheng_side_stair", (5.6, -0.5, 0.0))
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -9.0, 3.0))
    hill = bpy.context.active_object
    hill.scale = (40.0, 10.0, 6.0)
    hill.data.materials.append(_plain_material("Hill", "#4F6B3A"))
    scene, cam = _stage()
    outs = []
    outs.append(_shot(scene, cam, (13.0, 14.0, 7.0), (0.0, -2.0, 2.3), 42, (1600, 900), os.path.join(FID_DIR, "_ba1.png")))
    outs.append(_shot(scene, cam, (-12.0, 12.0, 4.0), (0.0, -2.0, 2.8), 45, (1600, 900), os.path.join(FID_DIR, "_ba2.png")))
    car = Vector((0.0, 28.0, 0.0))       # masina merge spre -Y, spre deal
    outs.append(_shot(scene, cam, car + Vector((0, GC_DIST, GC_HEIGHT)), car + Vector((0, -GC_LOOK_AHEAD, GC_LOOK_HEIGHT)),
                      GC_FOV, (1600, 900), os.path.join(FID_DIR, "_ba3.png")))
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "bakheng_assembly.png")])
    _rm(*outs)


_a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--gallery" in _a:
    gallery()
if "--bakheng" in _a:
    bakheng()
