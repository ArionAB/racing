"""Randari de control pentru ursul animat (brown_bear.glb) -- din GLB-ul EXPORTAT,
pe cadre de animatie. Separat de `preview_transfagarasan.py` (care randeaza
poza de repaus) ca sa nu intram in conflict cu ceilalti constructori; refoloseste
insa EXACT randarea lui (lumina, fundal, culoarea reala a sloturilor din UV),
incarcandu-i functiile fara blocul de argumente.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_tf_bear.py -- --all

Moduri (dupa al doilea `--`):
  --compare        brown_bear_walk.png <-> un cadru din Walk,
                   brown_bear_stand.png <-> ultimul cadru din Stand
                   -> docs/asset_briefs/img/transfagarasan_fidelity/brown_bear_{walk,stand}.png
  --frames         plansa de cadre: Idle (1), Walk (2), Stand (inceput, mijloc, capat)
                   -> .../brown_bear_frames.png
  --views          4 azimuturi pe poza finala din Stand -> .../brown_bear_stand_views.png
  --all            toate trei

Fiecare cadru se ingheata intr-un mesh static (`new_from_object` pe obiectul
evaluat), cu UV-urile si AO-ul lui, apoi se coloreaza pe sloturi: randarea vede
exact geometria deformata de schelet, nu poza de repaus.

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock`; dupa, `rmdir`.
"""

import bpy
import os
import subprocess
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(_HERE, "preview_transfagarasan.py"), encoding="utf-8").read()
_src = _src.split("\nargv = sys.argv")[0]
exec(compile(_src, "preview_transfagarasan.py", "exec"), globals())

GLB = os.path.join(MODELS_DIR, "animals", "brown_bear.glb")

# Camera pe decupari: `walk` e aproape din profil, dinspre dreapta ursului si
# putin din fata (capul in dreapta imaginii) -> camera spre +X, azimut mic.
# `stand` e aproape din fata, usor dinspre dreapta ursului.
CAM_WALK = dict(azimuth=45.0, elevation=11.0, lens=60.0, margin=1.06)
CAM_STAND = dict(azimuth=50.0, elevation=6.0, lens=60.0, margin=1.04)
CAM_SHEET = dict(azimuth=25.0, elevation=10.0, lens=60.0, margin=1.08)


def _load():
    _clear()
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    bpy.ops.import_scene.gltf(filepath=GLB)
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    mesh = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm][0]
    _fix_ao_layer_name(mesh)
    if arm.animation_data is None:
        arm.animation_data_create()
    for tr in list(arm.animation_data.nla_tracks):
        arm.animation_data.nla_tracks.remove(tr)
    print("actiuni importate:", [(a.name, tuple(a.frame_range)) for a in bpy.data.actions])
    return arm, mesh


def _action(name):
    for a in bpy.data.actions:
        if a.name == name or a.name.startswith(name + "_") or a.name.startswith(name + "."):
            return a
    raise KeyError(name)


def snapshot(arm, mesh, clip, frame_off, label):
    """Mesh static al cadrului `frame_off` (relativ la inceputul clipului;
    negativ = de la capat)."""
    act = _action(clip)
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and getattr(act, "slots", None):
        if arm.animation_data.action_slot is None:
            arm.animation_data.action_slot = act.slots[0]
    f0, f1 = act.frame_range
    frame = f0 + frame_off if frame_off >= 0 else f1 + 1 + frame_off
    bpy.context.scene.frame_set(int(round(frame)))
    deps = bpy.context.evaluated_depsgraph_get()
    deps.update()
    ev = mesh.evaluated_get(deps)
    me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=deps)
    snap = bpy.data.objects.new("Snap_" + label, me)
    bpy.context.collection.objects.link(snap)
    snap.matrix_world = mesh.matrix_world.copy()
    _fix_ao_layer_name(snap)
    _per_slot_tint(snap)
    zs = [(snap.matrix_world @ v.co).z for v in me.vertices]
    ys = [(snap.matrix_world @ v.co).y for v in me.vertices]
    print("cadru %-10s %s f%d: inalt %.2f m, baza %.3f, Y [%.2f, %.2f]"
          % (label, clip, frame, max(zs) - min(zs), min(zs), min(ys), max(ys)))
    return snap


def _python(code, args):
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, "-c", code] + args, capture_output=True, text=True)
            print(r.stdout.strip() or r.stderr.strip())
            return r.returncode == 0
        except FileNotFoundError:
            continue
    return False


_LABELED = r'''
import sys
from PIL import Image, ImageDraw
out, items = sys.argv[1], sys.argv[2:]
BG = (196, 196, 196)
ims = []
for it in items:
    path, label = it.split("|", 1)
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGBA", im.size, BG + (255,))
    ims.append((Image.alpha_composite(bg, im).convert("RGB"), label))
h = max(i.height for i, _ in ims) + 30
w = sum(i.width for i, _ in ims) + 8 * (len(ims) - 1)
img = Image.new("RGB", (w, h), (255, 255, 255))
d = ImageDraw.Draw(img)
x = 0
for i, label in ims:
    img.paste(i, (x, 30))
    d.text((x + 6, 8), label, fill=(150, 0, 0))
    x += i.width + 8
img.save(out)
print("plansa:", out)
'''


def compare_all(arm, mesh):
    os.makedirs(FID_DIR, exist_ok=True)
    for crop_name, clip, off, cam in (("brown_bear_walk", "Walk", 4, CAM_WALK),
                                      ("brown_bear_stand", "Stand", -1, CAM_STAND)):
        snap = snapshot(arm, mesh, clip, off, crop_name)
        crop = os.path.join(CROPS, crop_name + ".png")
        img = bpy.data.images.load(crop)
        cw, ch = img.size
        bpy.data.images.remove(img)
        tmp = os.path.join(FID_DIR, "_render_" + crop_name + ".png")
        _render([snap], tmp, res_height=900, aspect=max(0.5, min(8.0, cw / float(ch))), **cam)
        _compose(["--compare", crop_name, "--crop", crop, "--render", tmp,
                  "--out", os.path.join(FID_DIR, crop_name + ".png"), "--height", "900"])
        os.remove(tmp)


def frames_sheet(arm, mesh):
    os.makedirs(FID_DIR, exist_ok=True)
    shots = [("Idle", 0, "Idle f1"), ("Walk", 4, "Walk f5"), ("Walk", 11, "Walk f12"),
             ("Stand", 0, "Stand inceput"), ("Stand", 13, "Stand mijloc (f14)"),
             ("Stand", -1, "Stand capat")]
    items = []
    for k, (clip, off, label) in enumerate(shots):
        snap = snapshot(arm, mesh, clip, off, "sheet%d" % k)
        tmp = os.path.join(FID_DIR, "_frame_%d.png" % k)
        _render([snap], tmp, res_height=560, aspect=0.95, **CAM_SHEET)
        items.append(tmp + "|" + label)
    out = os.path.join(FID_DIR, "brown_bear_frames.png")
    _python(_LABELED, [out] + items)
    for it in items:
        os.remove(it.split("|")[0])


def stand_views(arm, mesh):
    os.makedirs(FID_DIR, exist_ok=True)
    snap = snapshot(arm, mesh, "Stand", -1, "views")
    items = []
    for az in (35.0, 125.0, 215.0, 305.0):
        cam = dict(CAM_STAND)
        cam["azimuth"] = az
        tmp = os.path.join(FID_DIR, "_view_bear_%d.png" % int(az))
        _render([snap], tmp, res_height=640, aspect=0.8, **cam)
        items.append(tmp + "|azimut %d" % int(az))
    out = os.path.join(FID_DIR, "brown_bear_stand_views.png")
    _python(_LABELED, [out] + items)
    for it in items:
        os.remove(it.split("|")[0])


_args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
_arm, _mesh = _load()
_mesh.hide_render = True
if "--compare" in _args or "--all" in _args:
    compare_all(_arm, _mesh)
if "--frames" in _args or "--all" in _args:
    frames_sheet(_arm, _mesh)
if "--views" in _args or "--all" in _args:
    stand_views(_arm, _mesh)
