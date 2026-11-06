"""Cadre de control pentru grupul B, val 2 (bolta): lantul intact | prabusit | intact,
vazut de camera de joc. `preview_angkor.py` ramane neatins (doar SPECS adaugate);
acest script ii refoloseste functiile.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor_w2b.py -- --chain

Trei cadre (drumul merge spre +Y, 6 m latime, asfalt plat):
  a  camera de joc standard (10 m sus, 12,5 m in spate), lantul la 30 m
  b  la fel, la 14 m (aproape de gura)
  d  vedere oblica de sus a lantului
  c  camera coborata sub tavan (3,2 m sus, 6 m in spate) la 10 m: ce face
     `CameraZone` cu tavanul declarat; AICI se vede ce vede soferul
-> docs/asset_briefs/img/angkor_fidelity/vault_chain_gamecam.png
"""
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_saved = sys.argv
sys.argv = [_saved[0], "--", "--none"]
exec(open(os.path.join(_here, "preview_angkor.py"), encoding="utf-8").read())
sys.argv = _saved


def chain():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = []
    for i, nm in enumerate(("vault_intact", "vault_broken", "vault_intact")):
        path = _find_glb(nm)
        meshes += _import_path(path, offset=(0.0, 4.0 * i, 0.0))
    for o in meshes:
        o.hide_render = False
    scene = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=600.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.active_object
    ground.data.materials.append(_plain_material("GCGround", "#6E7A4A"))
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.0, 0.0, 0.01))
    road = bpy.context.active_object
    road.scale = (6.0, 600.0, 1.0)
    road.data.materials.append(_plain_material("GCRoad", "#4B4B4D"))

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

    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 380.0

    outs = []
    # (eticheta, distanta pana la lant, inaltime camera, distanta in spate, look ahead)
    for tag, ahead, h, back, look in (("a", 30.0, GC_HEIGHT, GC_DIST, GC_LOOK_AHEAD),
                                      ("b", 14.0, GC_HEIGHT, GC_DIST, GC_LOOK_AHEAD),
                                      ("c", 10.0, 3.2, 6.0, 8.0)):
        car = Vector((0.0, -2.0 - ahead, 0.0))
        cam.location = car + Vector((0.0, -back, h))
        target = car + Vector((0.0, look, GC_LOOK_HEIGHT if h > 5 else 2.0))
        cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()
        p = os.path.join(FID_DIR, "_vc_%s.png" % tag)
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        outs.append(p)
    # d: vedere oblica de sus, ca sa se citeasca lantul intact | prabusit | intact
    cam.location = Vector((13.0, -9.0, 8.0))
    target = Vector((0.0, 4.0, 2.5))
    cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    p = os.path.join(FID_DIR, "_vc_d.png")
    scene.render.filepath = p
    bpy.ops.render.render(write_still=True)
    outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "vault_chain_gamecam.png")])
    _rm(*outs)


if "--chain" in (sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []):
    chain()
