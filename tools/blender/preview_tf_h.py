"""Randari de control pentru grupa tf-h (ro_train + cable_cabin_large) -- peste
`preview_transfagarasan.py`, fara sa-l modifice (tiparul preview_tf_f.py).

Moduri (argumentele dupa al doilea `--`):
  --compare <nume>   decupare | randare din GLB (ro_train: vagonul langa
                     locomotiva, ca pe decupare; garnitura e asezata ca in
                     TrainHazard._build_model_consist: coada la x = 0, 1,2 m
                     intre piese, locomotiva la x maxim)
  --views <nume>     4 azimuturi
  --consist          garnitura intreaga ca in joc (3 vagoane + bagaje + loco),
                     3/4 si din lateral -> ro_train_consist.png
  --align            ro_train langa perurail_train.glb, aceeasi scara, cu sina
                     procedurala a hazardului (|y| = 0,45, varf la y = 0):
                     lateral (ortografic), din fata, de sus
                     -> ro_train_vs_perurail.png
  --scale            cabina mare langa gondola alpina a Track09 si langa masina
                     de joc (open_roadster), ortografic -> cable_cabin_scale.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_tf_h.py -- --compare ro_train

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

# Decuparile: ro_train cu locomotiva in stanga, vagonul in dreapta, privita de
# sus (~28 grade), din partea +Y a garniturii cu botul (+X) in stanga; cabina
# cu fata lunga spre camera si usor rotita, privita de sus ~14 grade.
SPECS.update({
    "ro_train": {"camera": {"azimuth": 62.0, "elevation": 26.0, "lens": 55.0, "margin": 1.06}},
    "cable_cabin_large": {"camera": {"azimuth": 52.0, "elevation": 12.0, "lens": 70.0, "margin": 1.06}},
})

PERURAIL = os.path.join(PROJ, "assets", "models", "machupicchu", "vehicles", "perurail_train.glb")
GONDOLA = os.path.join(PROJ, "assets", "models", "vehicles", "cable_car_gondola.glb")
GAME_CAR = os.path.join(PROJ, "assets", "models", "vehicles", "open_roadster.glb")
WAGON_GAP = 1.2   # train_hazard.gd: WAGON_GAP
RAIL_TOP = 0.28   # train_hazard.gd: RAIL_TOP (piesa sta cu baza pe el)


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


def _import_glb(path, keep=None):
    """Importeaza un GLB (culoarea pe slot) si intoarce {nume_nod: obiect}."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    out = {}
    for o in [o for o in bpy.data.objects if o not in before]:
        if o.type != "MESH":
            continue
        base = re.sub(r"\.\d{3}$", "", o.name)
        if keep and base not in keep:
            o.hide_render = True
            continue
        _fix_ao_layer_name(o)
        _per_slot_tint(o)
        out[base] = o
    bpy.context.view_layer.update()
    return out


def _lay_consist(nodes, order, x0=0.0, y=0.0, z=0.0):
    """Aseaza piesele ca TrainHazard: coada primei piese la x0, WAGON_GAP intre
    piese (masurat pe AABB-ul piesei), originea modelului ramane unde e in GLB.
    Intoarce (obiecte, lungime totala)."""
    objs, x = [], x0
    for i, name in enumerate(order):
        src = nodes[name]
        o = src if i == order.index(name) and src not in objs else src.copy()
        if o is not src:
            bpy.context.collection.objects.link(o)
        lo = min(c[0] for c in src.bound_box)
        hi = max(c[0] for c in src.bound_box)
        o.location = Vector((x - lo, y, z))
        objs.append(o)
        x += (hi - lo) + WAGON_GAP
    bpy.context.view_layer.update()
    return objs, x - WAGON_GAP - x0


def _rails(length, x0=0.0, y=0.0, z=0.0):
    """Sina procedurala a hazardului (varful la z), in cadrul modelului."""
    out = [_box("PreviewRail", (x0 + length * 0.5, y + s * 0.45, z - 0.08), (length + 6.0, 0.16, 0.16), "#4A4A4A")
           for s in (-1, 1)]
    n = int((length + 6.0) / 1.8)
    for i in range(n):
        out.append(_box("PreviewSleeper", (x0 - 3.0 + i * 1.8, y, z - 0.22), (0.8, 1.5, 0.12), "#7A6A55"))
    return out


# ro_train: vagon langa locomotiva (ca pe decupare); restul pieselor ascunse
_base_import = _import


def _import(name):
    if name != "ro_train":
        return _base_import(name)
    nodes = _import_glb(_find_glb("ro_train"))
    objs, _ = _lay_consist(nodes, ["Train_Wagon", "Train_Loco"])
    nodes["Train_Tender"].hide_render = True
    return objs


def _ortho(objs, path, azimuth, elevation, width_m, height_m, center, px_per_m=60):
    """Camera ortografica; lumina si fundalul vin de la o randare de proba mica."""
    scene = bpy.context.scene
    tmp = path + ".tmp.png"
    _render(objs, tmp, azimuth=azimuth, elevation=elevation, res_height=32, aspect=1.0)
    os.remove(tmp)
    cam = scene.camera
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(width_m, height_m)
    cam.data.sensor_fit = "AUTO"
    a, e = math.radians(azimuth), math.radians(elevation)
    dirv = Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e)))
    cam.location = Vector(center) + dirv * 200.0
    look = (Vector(center) - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x = int(width_m * px_per_m)
    scene.render.resolution_y = int(height_m * px_per_m)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    cam.data.type = "PERSP"
    return path


def align():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    pr = _import_glb(PERURAIL)
    me = _import_glb(_find_glb("ro_train"))
    order = ["Train_Wagon", "Train_Tender", "Train_Loco"]
    row_pr, len_pr = _lay_consist(pr, order, 0.0, 0.0, RAIL_TOP * 0.0 + 6.2)
    row_me, len_me = _lay_consist(me, order, 0.0, 0.0, 0.0)
    rails = _rails(len_pr, 0.0, 0.0, 6.2) + _rails(len_me, 0.0, 0.0, 0.0)
    allobj = row_pr + row_me + rails
    outs = []
    # 1) lateral, ortografic, din -Y: botul (+X) la dreapta; sus PeruRail, jos ro_train
    w = max(len_pr, len_me) + 8.0
    p = os.path.join(FID_DIR, "_al_side.png")
    _ortho(allobj, p, -90.0, 0.0, w, 12.4, (w * 0.5 - 4.0, 0.0, 4.6), px_per_m=40)
    outs.append(p)
    # 2) din fata: locomotivele, PeruRail la stanga (y = -3), ro_train la dreapta
    for o in row_pr + row_me:
        o.hide_render = not o.name.startswith("Train_Loco")
    lp = [o for o in row_pr if o.name.startswith("Train_Loco")][0]
    lm = [o for o in row_me if o.name.startswith("Train_Loco")][0]
    lp.location = Vector((0.0, -3.0, 0.0))
    lm.location = Vector((0.0, 3.0, 0.0))
    fr = _rails(1.0, -0.5, -3.0, 0.0)[:2] + _rails(1.0, -0.5, 3.0, 0.0)[:2]
    for r in rails:
        r.hide_render = True
    p = os.path.join(FID_DIR, "_al_front.png")
    _ortho([lp, lm] + fr, p, 0.0, 0.0, 12.0, 6.0, (0.0, 0.0, 2.4), px_per_m=70)
    outs.append(p)
    # 3) de sus: doua garnituri in randuri, sinele la |y| = 0,45
    for o in row_pr + row_me:
        o.hide_render = False
    for o in row_pr:
        o.location.y = -5.0
        o.location.z = 0.0
    for o in row_me:
        o.location.y = 5.0
    rails2 = _rails(len_pr, 0.0, -5.0, 0.0) + _rails(len_me, 0.0, 5.0, 0.0)
    p = os.path.join(FID_DIR, "_al_top.png")
    _ortho(row_pr + row_me + rails2, p, -90.0, 89.9, w, 13.0, (w * 0.5 - 4.0, 0.0, 0.0), px_per_m=40)
    outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "ro_train_vs_perurail.png")])
    for q in outs:
        os.remove(q)


def consist():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    nodes = _import_glb(_find_glb("ro_train"))
    objs, ln = _lay_consist(nodes, ["Train_Wagon", "Train_Wagon", "Train_Wagon", "Train_Tender", "Train_Loco"])
    rails = _rails(ln)
    outs = []
    p1 = os.path.join(FID_DIR, "_cs_34.png")
    _render(objs + rails, p1, azimuth=-62.0, elevation=22.0, lens=50.0, margin=1.06, res_height=520, aspect=2.6)
    outs.append(p1)
    p2 = os.path.join(FID_DIR, "_cs_side.png")
    _render(objs + rails, p2, azimuth=-90.0, elevation=2.0, lens=120.0, margin=1.04, res_height=380, aspect=4.4)
    outs.append(p2)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "ro_train_consist.png")])
    for q in outs:
        os.remove(q)


def scale():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    cab = _import_glb(_find_glb("cable_cabin_large"))
    gon = _import_glb(GONDOLA)
    car = _import_glb(GAME_CAR)
    # toate sunt la sol/linia cablului: cabina are originea la CABLU (varful), gondola
    # la baza (cablul la +4,0 m), masina la baza -> aliniem la linia cablului y = 7,5
    for o in cab.values():
        o.location = Vector((-6.5, 0.0, 7.5))
    for o in gon.values():
        o.location = Vector((0.0, 0.0, 7.5 - 4.01))
    for o in car.values():
        o.location = Vector((7.0, 0.0, 0.0))
    ground = _box("PreviewGround", (0.0, 0.0, -0.05), (30.0, 6.0, 0.1), "#9AA08A")
    cable = _box("PreviewCable", (0.0, 0.0, 7.5), (30.0, 0.06, 0.06), "#222222")
    allobj = list(cab.values()) + list(gon.values()) + list(car.values()) + [ground, cable]
    outs = []
    p1 = os.path.join(FID_DIR, "_sc_front.png")
    _ortho(allobj, p1, -90.0, 0.0, 22.0, 9.2, (0.0, 0.0, 4.0), px_per_m=60)
    outs.append(p1)
    p2 = os.path.join(FID_DIR, "_sc_side.png")
    _ortho(allobj, p2, 0.0, 0.0, 7.0, 9.2, (0.0, 0.0, 4.0), px_per_m=60)
    outs.append(p2)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, "cable_cabin_scale.png")])
    for q in outs:
        os.remove(q)


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--consist" in args:
    consist()
elif "--align" in args:
    align()
elif "--scale" in args:
    scale()
else:
    print(__doc__)
