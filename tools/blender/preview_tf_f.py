"""Randari de control pentru grupa tf-f (vehicule de decor + ciobanescul) --
peste `preview_transfagarasan.py`, fara sa-l modifice (tiparul preview_tf_a.py).

Moduri (argumentele dupa al doilea `--`):
  --compare <nume>   decupare | randare din GLB (harnasul, cu camerele de aici)
  --views <nume>     4 azimuturi
  --ab               parked_car_a | parked_car_b alaturi (3/4 si profil)
                     -> img/transfagarasan_fidelity/parked_car_ab.png
  --lineup           a, b si masina implicita a jucatorului (open_roadster.glb,
                     Muscle) pe acelasi sol, plus cutia carcasei din Car.tscn
                     (2,2 x 1,0 x 3,8, talpa la +0,25) -> parked_cars_vs_game.png
  --herd             ciobanescul printre 6 oi (`monumentvalley/animals/sheep.glb`,
                     nodul Pose_Walk, cel pe care il ia HerdHazard), la scara, cu
                     masina jucatorului in fata camerei de joc: camera la 12,5 m
                     in spate si 10 m sus, tinta la 5 m in fata si 0,4 m sus, fov
                     VERTICAL 68 (chase_camera.gd) -> sheepdog_herd.png (cadrul de
                     joc + o decupare marita din acelasi unghi)

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_tf_f.py -- --compare parked_car_a

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import math
import os
import re
import sys

_argv_keep = sys.argv
sys.argv = ["preview_transfagarasan.py"]
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "preview_transfagarasan.py"), encoding="utf-8").read())
sys.argv = _argv_keep

from mathutils import Vector  # noqa: E402

# Decuparile au fata spre DREAPTA-jos (camera spre +X, putin din fata).
SPECS.update({
    "parked_car_a": {"camera": {"azimuth": 38.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "parked_car_b": {"camera": {"azimuth": 38.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "motorbike": {"camera": {"azimuth": 22.0, "elevation": 12.0, "lens": 70.0, "margin": 1.06}},
    "sheepdog": {"camera": {"azimuth": 18.0, "elevation": 10.0, "lens": 70.0, "margin": 1.06}},
})

GAME_CAR = os.path.join(PROJ, "assets", "models", "vehicles", "open_roadster.glb")
SHEEP = os.path.join(PROJ, "assets", "models", "monumentvalley", "animals", "sheep.glb")


def _import_path(path, offset=(0.0, 0.0, 0.0), yaw_deg=0.0, keep=None):
    """Importa un GLB din afara kitului (culoarea pe slot, ca harnasul) si muta
    radacinile. `keep` = sufixe de noduri pastrate (restul hide_render)."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = []
    for o in new:
        if o.type != "MESH":
            continue
        base = re.sub(r"\.\d{3}$", "", o.name)
        if keep and not any(base.endswith(k) for k in keep):
            o.hide_render = True
            continue
        _fix_ao_layer_name(o)
        _per_slot_tint(o)
        meshes.append(o)
    for o in new:
        if o.parent is None:
            o.rotation_mode = "XYZ"
            o.rotation_euler = (o.rotation_euler.x, o.rotation_euler.y,
                                o.rotation_euler.z + math.radians(yaw_deg))
            o.location = o.location + Vector(offset)
    bpy.context.view_layer.update()
    return meshes


def _import_kit(name, offset=(0.0, 0.0, 0.0), yaw_deg=0.0):
    return _import_path(_find_glb(name), offset, yaw_deg)


def _white_ao(me):
    """Materialul plat al harnasului inmulteste cu stratul de vertex color `AO`;
    o plasa fara strat iese neagra, deci i se da un AO alb."""
    att = me.color_attributes.new("AO", "FLOAT_COLOR", "CORNER")
    for d in att.data:
        d.color = (1.0, 1.0, 1.0, 1.0)


def _box(name, center, size, hex_color, wire=False):
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
    if wire:
        mod = o.modifiers.new("Wire", "WIREFRAME")
        mod.thickness = 0.03
    return o


def _ground(size, hex_color="#9AA08A", center=(0.0, 0.0)):
    me = bpy.data.meshes.new("PreviewGround")
    h = size * 0.5
    cx, cy = center
    me.from_pydata([(cx - h, cy - h, 0), (cx + h, cy - h, 0), (cx + h, cy + h, 0), (cx - h, cy + h, 0)],
                   [], [(0, 1, 2, 3)])
    me.update()
    _white_ao(me)
    o = bpy.data.objects.new("PreviewGround", me)
    bpy.context.collection.objects.link(o)
    me.materials.append(_flat_material(hex_color))
    return o


def ab(res_height=760):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import_kit("parked_car_a", (-1.6, 0.0, 0.0))
    meshes += _import_kit("parked_car_b", (1.6, 0.0, 0.0))
    outs = []
    for az, el, tag in ((38.0, 20.0, "34"), (0.0, 4.0, "side"), (90.0, 8.0, "front"), (270.0, 8.0, "back")):
        p = os.path.join(FID_DIR, "_ab_%s.png" % tag)
        _render(meshes, p, azimuth=az, elevation=el, lens=60.0, margin=1.06,
                res_height=res_height, aspect=1.5)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "parked_car_ab.png")])
    for p in outs:
        os.remove(p)


def lineup(res_height=760):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import_kit("parked_car_a", (-2.8, 0.0, 0.0))
    meshes += _import_kit("parked_car_b", (0.0, 0.0, 0.0))
    # open_roadster: glTF, deci -Z Godot = +Y Blender dupa import; fata spre +Y
    meshes += _import_path(GAME_CAR, (2.8, 0.0, 0.0))
    # carcasa din Car.tscn (car.gd:482): 2,2 x 1,0 x 3,8, talpa la +0,25
    meshes.append(_box("GaugeCarTscn", (5.6, 0.0, 0.75), (2.2, 3.8, 1.0), "#3A3A3A", wire=True))
    # carcasa efectiva a Muscle (apply_data: 0,9 x 2,00 ; 0,85 x 4,37)
    meshes.append(_box("GaugeMuscle", (2.8, 0.0, 0.75), (1.80, 3.7145, 1.0), "#C03030", wire=True))
    meshes.append(_ground(1.0, "#B0B0A8", (0.0, 0.0)))
    g = meshes[-1]
    g.scale = (16.0, 7.0, 1.0)
    g.location = (1.4, 0.0, 0.0)
    bpy.context.view_layer.update()
    outs = []
    # 3/4, din fata (latimile alaturi) si de sus (lungimi + latimi, cu cutiile)
    for az, el, tag in ((60.0, 24.0, "34"), (90.0, 6.0, "front"), (90.0, 88.0, "top")):
        p = os.path.join(FID_DIR, "_lineup_%s.png" % tag)
        _render(meshes, p, azimuth=az, elevation=el, lens=50.0, margin=1.04,
                res_height=res_height, aspect=1.6)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "parked_cars_vs_game.png")])
    for p in outs:
        os.remove(p)


def _game_camera(res=(1280, 720)):
    """Camera de joc fata de o masina la origine cu fata spre +Y."""
    scene = bpy.context.scene
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(68.0)
    cam.data.clip_start = 0.1
    cam.data.clip_end = 500.0
    cam.location = Vector((0.0, -12.5, 10.0))
    look = (Vector((0.0, 5.0, 0.4)) - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    return cam


def herd(res=(1280, 720)):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import_path(GAME_CAR, (0.0, 0.0, 0.0))
    # turma traverseaza drumul (curgerea pe X), la ~9 m in fata masinii;
    # spacing 1,4 m ca pe Track21 (HerdHazard: spacing = 1.4)
    sheep_spots = [(-2.6, 8.6, 95), (-1.0, 9.6, 80), (0.6, 8.4, 100), (2.2, 9.4, 85),
                   (-2.0, 10.9, 92), (1.4, 11.0, 88)]
    for (x, y, yaw) in sheep_spots:
        meshes += _import_path(SHEEP, (x, y, 0.0), yaw, keep=("Pose_Walk",))
    meshes += _import_kit("sheepdog", (-0.4, 11.3, 0.0), 90.0)
    ground = _ground(80.0, "#7E8E5A", (0.0, 10.0))
    road = _box("PreviewRoad", (0.0, 10.0, -0.004), (14.0, 60.0, 0.006), "#6A6866")
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in meshes + [ground, road]
    # lumina: aceeasi ca harnasul (o randare de proba pune soarele + fundalul)
    tmp = os.path.join(FID_DIR, "_herd_tmp.png")
    _render(meshes, tmp, azimuth=-90.0, elevation=40.0, res_height=360, aspect=1.6)
    ground.hide_render = False
    road.hide_render = False
    scene.render.film_transparent = False
    _game_camera(res)
    full = os.path.join(FID_DIR, "_herd_game.png")
    scene.render.filepath = full
    bpy.ops.render.render(write_still=True)
    # decuparea marita: acelasi unghi (camera pe aceeasi dreapta, mai aproape)
    cam = scene.camera
    tgt = Vector((0.0, 9.9, 0.5))
    d = (cam.location - tgt).normalized()
    cam.location = tgt + d * 7.0
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    zoom = os.path.join(FID_DIR, "_herd_zoom.png")
    scene.render.filepath = zoom
    bpy.ops.render.render(write_still=True)
    _compose(["--montage", ",".join([full, zoom]), "--out", os.path.join(FID_DIR, "sheepdog_herd.png")])
    for p in (tmp, full, zoom):
        try:
            os.remove(p)
        except OSError:
            pass


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--ab" in args:
    ab()
elif "--lineup" in args:
    lineup()
elif "--herd" in args:
    herd()
else:
    print(__doc__)
