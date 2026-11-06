"""Randari pentru val 4, grupul B (vegetatia mica). `preview_angkor.py` ramane neatins (doar SPECS
adaugate); i se refoloseste codul prin exec.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor_w4b.py -- --compare vine_strands
    ... -- preview_angkor_w4b.py -- --views vine_strands
    ... -- preview_angkor_w4b.py -- --curtain [N_PE_RAND]

Suvitele din `vine_strands.glb` au TOATE originea in (0, 0, 0) (contract: radacini cu transformari
identitate), deci `--compare` / `--views` le desfac pe X (0,9 m) ca sa se vada una cate una.

`--curtain`: perdeaua de la POI G -- 4 randuri pe un drum de 13 m, suvitele atarnand de la 5,0 m cu
varfurile la 0,7-2,3 m peste asfalt (lungimea fiecarei suvite se scaleaza pe Z ca sa ajunga la
varful tras; factorul se tipareste), vazuta din camera de joc cu perdeaua la 40 m inaintea
masinii. Acopera si MASOARA: fractia din latimea drumului in care o coloana de pixeli prinde
macar o suvita (alfa > 0,25), pe doua benzi de inaltime (2,4-4,8 m: toate suvitele sunt acolo;
0,7-2,3 m: doar cele cu varful jos). N=15 pe rand = ~60 de suvite (cerinta imaginii); implicit se
randeaza SI varianta din cod (pasul 0,36 m = 36 pe rand).
-> docs/asset_briefs/img/angkor_fidelity/vine_curtain*.png
RANDAREA RULEAZA PE GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
"""
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_saved = sys.argv
sys.argv = [_saved[0], "--", "--none"]
exec(open(os.path.join(_here, "preview_angkor.py"), encoding="utf-8").read())
sys.argv = _saved

import random  # noqa: E402

SPREAD = 0.9


def _spread(meshes):
    ms = sorted(meshes, key=lambda o: o.name)
    for k, o in enumerate(ms):
        o.location = Vector(((k - (len(ms) - 1) * 0.5) * SPREAD, 0.0, 0.0))
    bpy.context.view_layer.update()


def _load(name):
    _clear()
    meshes = _import(name)
    if name == "vine_strands":
        _spread(meshes)
    return meshes


def compare_w4b(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = _find_crop(name)
    meshes = _load(name)
    if not meshes or crop is None:
        print("LIPSA piesa sau decupare:", name)
        return
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    _render(meshes, tmp, res_height=res_height, aspect=max(0.3, min(8.0, cw / float(ch))), **_camera_for(name))
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out, "--height", str(res_height)])
    _rm(tmp)


def views_w4b(name, res_height=800, azs=(62.0, 152.0, 242.0, 332.0)):
    os.makedirs(FID_DIR, exist_ok=True)
    meshes = _load(name)
    if not meshes:
        return
    outs = []
    for az in azs:
        cam = _camera_for(name)
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(meshes, p, res_height=res_height, aspect=SPECS.get(name, {}).get("views_aspect", 0.6), **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, name + "_views.png")])
    _rm(*outs)


def close_w4b(name, azimuth, elevation, tag, res_height=900, aspect=1.3, margin=1.05, lens=60.0):
    """O singura vedere de aproape -> <name>_<tag>.png."""
    os.makedirs(FID_DIR, exist_ok=True)
    meshes = _load(name)
    p = os.path.join(FID_DIR, "%s_%s.png" % (name, tag))
    _render(meshes, p, azimuth=azimuth, elevation=elevation, lens=lens, margin=margin,
            res_height=res_height, aspect=aspect)


# --- perdeaua -----------------------------------------------------------------

ROAD_W = 13.0
TOP_Z = 5.0
TIP_LO, TIP_HI = 0.7, 2.3
AHEAD = 40.0


def _strand_lengths(meshes):
    out = {}
    for o in meshes:
        zs = [(o.matrix_world @ Vector(c)).z for c in o.bound_box]
        out[o.name] = max(-min(zs), 0.5)
    return out


def curtain(per_row=15, rows=4, row_gap=1.1, tag="vine_curtain", seed=7):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import("vine_strands")
    for o in meshes:
        o.hide_render = True
    lengths = _strand_lengths(meshes)
    rnd = random.Random(seed)
    scene = bpy.context.scene

    inst = []
    factors = []
    spacing = ROAD_W / per_row
    for r in range(rows):
        yy = (r - (rows - 1) * 0.5) * row_gap
        shift = spacing * r / rows
        for k in range(per_row):
            x = -ROAD_W * 0.5 + shift + spacing * k + rnd.uniform(-0.08, 0.08)
            src = rnd.choice(meshes)
            tip = TIP_LO + rnd.random() * rnd.random() * (TIP_HI - TIP_LO)
            f = (TOP_Z - tip) / lengths[src.name]
            factors.append(f)
            o = bpy.data.objects.new("Inst", src.data)
            scene.collection.objects.link(o)
            o.location = Vector((x, yy + rnd.uniform(-0.2, 0.2), TOP_Z))
            o.rotation_euler = (0.0, 0.0, math.radians(rnd.uniform(0.0, 360.0)))
            o.scale = (1.0, 1.0, f)
            inst.append(o)
    print("%s: %d suvite, factor de scara Z %.2f..%.2f (medie %.2f)"
          % (tag, len(inst), min(factors), max(factors), sum(factors) / len(factors)))

    # creanga de sus, drumul, solul
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, TOP_Z + 0.25))
    beam = bpy.context.active_object
    beam.scale = (ROAD_W + 3.0, 0.5, 0.5)
    beam.data.materials.append(_plain_material("VBeam", "#B5A48A"))
    bpy.ops.mesh.primitive_plane_add(size=600.0, location=(0.0, -150.0, -0.02))
    bpy.context.active_object.data.materials.append(_plain_material("VGround", "#6E7A4A"))
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.0, -150.0, 0.0))
    road = bpy.context.active_object
    road.scale = (ROAD_W, 600.0, 1.0)
    road.data.materials.append(_plain_material("VRoad", "#5B5B5E"))
    # trunchiuri de sprijin la capete (ca sa se citeasca drept creanga unui copac)
    for sx in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=TOP_Z + 4.0,
                                            location=(sx * (ROAD_W * 0.5 + 1.6), 0.0, (TOP_Z + 4.0) * 0.5))
        bpy.context.active_object.data.materials.append(_plain_material("VBeam", "#B5A48A"))
    other = [o for o in bpy.data.objects if o.type == "MESH" and o not in inst and o not in meshes]

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
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.file_format = "PNG"

    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle = math.radians(GC_FOV)
    cam.data.clip_start = 0.3
    cam.data.clip_end = 380.0

    frames, boxes = [], []
    cars = (("a", 0.0), ("b", 3.0))
    cov_lines = []
    for ctag, car_x in cars:
        car = Vector((car_x, -AHEAD, 0.0))
        cam.location = car + Vector((0.0, -GC_DIST, GC_HEIGHT))
        target = car + Vector((0.0, GC_LOOK_AHEAD, GC_LOOK_HEIGHT))
        cam.rotation_euler = (target - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()
        bpy.context.view_layer.update()
        W, Hh = GC_RES
        xs, ys = [], []
        for o in inst:
            for c in o.bound_box:
                v = world_to_camera_view(scene, cam, o.matrix_world @ Vector(c))
                xs.append(v.x)
                ys.append(1.0 - v.y)
        boxes.append("%.1f,%.1f,%.1f,%.1f" % (min(xs) * W, min(ys) * Hh, max(xs) * W, max(ys) * Hh))
        p = os.path.join(FID_DIR, "_cur_%s_%s.png" % (tag, ctag))
        scene.render.film_transparent = False
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        frames.append(p)
        if ctag == "a":
            cov_lines.append(_coverage(scene, cam, inst, other, tag))
    _compose(["--gamecam", ",".join(frames), "--boxes", ";".join(boxes), "--out",
              os.path.join(FID_DIR, tag + ".png")])
    _rm(*frames)
    for line in cov_lines:
        print(line)


def _coverage(scene, cam, inst, other, tag):
    """Mascadin strand-uri (alfa) din camera masinii de pe axa -> fractia de latime de drum acoperita."""
    import numpy as np
    for o in other:
        o.hide_render = True
    scene.render.film_transparent = True
    p = os.path.join(FID_DIR, "_mask_%s.png" % tag)
    scene.render.filepath = p
    bpy.ops.render.render(write_still=True)
    for o in other:
        o.hide_render = False
    img = bpy.data.images.load(p)
    W, Hh = img.size
    a = np.array(img.pixels[:]).reshape(Hh, W, 4)[:, :, 3]     # rand 0 = jos
    bpy.data.images.remove(img)
    _rm(p)

    def px(x, z):
        v = world_to_camera_view(scene, cam, Vector((x, 0.0, z)))
        return v.x * W, v.y * Hh

    out = []
    for lab, (z0, z1) in (("2,4-4,8 m (toate suvitele)", (2.4, 4.8)), ("0,7-2,3 m (doar cele coborate)", (0.7, 2.3))):
        xl, ya = px(-ROAD_W * 0.5, z0)
        xr, yb = px(ROAD_W * 0.5, z0)
        _, yc = px(0.0, z1)
        r0, r1 = int(min(ya, yc)), int(max(ya, yc))
        c0, c1 = int(max(min(xl, xr), 0)), int(min(max(xl, xr), W - 1))
        band = a[max(r0, 0):min(r1, Hh - 1) + 1, c0:c1 + 1] > 0.25
        cols = band.any(axis=0)
        out.append("%s [%s]: coloane acoperite %.1f%%, arie %.1f%% (%d x %d px)"
                   % (tag, lab, 100.0 * cols.mean(), 100.0 * band.mean(), c1 - c0 + 1, r1 - r0 + 1))
    return "\n".join(out)


_a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in _a:
    compare_w4b(_a[_a.index("--compare") + 1])
elif "--views" in _a:
    views_w4b(_a[_a.index("--views") + 1])
elif "--close" in _a:
    i = _a.index("--close")
    close_w4b(_a[i + 1], float(_a[i + 2]), float(_a[i + 3]), _a[i + 4],
              aspect=float(_a[i + 5]) if len(_a) > i + 5 else 1.3)
elif "--curtain" in _a:
    i = _a.index("--curtain")
    n = int(_a[i + 1]) if len(_a) > i + 1 and _a[i + 1].isdigit() else None
    if n:
        curtain(per_row=n, tag="vine_curtain_%d" % (n * 4))
    else:
        curtain(per_row=15, tag="vine_curtain_60")
        curtain(per_row=36, tag="vine_curtain_144")
