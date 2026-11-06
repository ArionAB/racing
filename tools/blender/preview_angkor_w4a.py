"""Gaj de copaci Angkor (val 4, grupul A): un rand de 60 m de copaci amestecati, vazut de la
inaltimea camerei de joc (10 m sus, 12,5 m in spatele masinii, fov 68).

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_angkor_w4a.py -- --grove

Reutilizeaza functiile din preview_angkor.py (sursa pana la `argv = sys.argv`, ca sa nu ruleze
dispatch-ul ei). Doua cadre: camera de joc, apoi aceeasi privelişte de la 45 m in spate. Randarea
pe GPU: `mkdir D:/GameDev/.render_lock` inainte.
"""
import math
import os
import sys
import random

_here = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(_here, "preview_angkor.py"), encoding="utf-8").read()
_src = _src.split("argv = sys.argv")[0]
exec(compile(_src, "preview_angkor_head", "exec"), globals())

ROW = ["tetrameles_a", "sugar_palm", "dipterocarp", "sugar_palm", "tetrameles_b", "sugar_palm",
       "tetrameles_a", "dipterocarp", "sugar_palm"]


def grove():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    rnd = random.Random(7)
    meshes = []
    for side in (-1, 1):
        y = rnd.uniform(-2.0, 3.0)
        k = 0 if side < 0 else 4
        while y < 62.0:
            nm = ROW[k % len(ROW)]
            k += 1
            x = side * rnd.uniform(11.0, 17.0)
            before = set(bpy.data.objects)
            ms = _import_path(_find_glb(nm), offset=(x, y, 0.0))
            for o in ms:
                o.rotation_euler = (0.0, 0.0, 0.0)
            meshes += ms
            y += 8.0 + rnd.uniform(0.0, 5.0)
    bpy.context.view_layer.update()
    scene = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=800.0, location=(0.0, 100.0, 0.0))
    ground = bpy.context.active_object
    ground.data.materials.append(_plain_material("GCGrass", "#6F8F4A"))
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.0, 100.0, 0.02))
    road = bpy.context.active_object
    road.scale = (8.0, 800.0, 1.0)
    road.data.materials.append(_plain_material("GCRoad", "#8E8578"))
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    el, yaw = math.radians(GC_SUN_ELEV), math.radians(GC_SUN_YAW)
    d = Vector((math.sin(yaw) * math.cos(el), math.cos(yaw) * math.cos(el), -math.sin(el)))
    _sun("GCSun", d, 3.4, color=_hex_lin("FFC48A"), angle_deg=1.5)
    world = scene.world or bpy.data.worlds.new("KWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = _hex_lin("9C8296") + (1.0,)
        bg.inputs[1].default_value = 0.34
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    _engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = GC_RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.file_format = "PNG"
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 380.0
    outs = []
    for tag, back, fov in (("a", GC_DIST, GC_FOV), ("b", 45.0, 68.0), ("c", 70.0, 55.0)):
        car = Vector((0.0, 0.0, 0.0))
        cam.data.angle = math.radians(fov)
        cam.location = car + Vector((0.0, -back, GC_HEIGHT))
        target = car + Vector((0.0, GC_LOOK_AHEAD + 8.0 * (back > 20), GC_LOOK_HEIGHT + (6.0 if back > 20 else 0.0)))
        cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()
        p = os.path.join(FID_DIR, "_grove_%s.png" % tag)
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        outs.append(p)
    _compose(["--montage", ",".join(outs[:1]), "--out", os.path.join(FID_DIR, "angkor_trees_grove_gamecam.png")])
    _compose(["--montage", ",".join(outs[1:]), "--out", os.path.join(FID_DIR, "angkor_trees_grove_far.png")])
    _rm(*outs)


if "--grove" in sys.argv:
    grove()
