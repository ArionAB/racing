"""Masuratori pe GLB-urile ok-a (castelul): sectiunile de capat ale zidurilor si
copia rotita a portii boltite pentru measure_gap.

  D:/Blender/blender.exe --background --factory-startup \
      --python tools/blender/run_build.py -- measure_okinawa_castle.py

1) Capete: pentru fiecare modul (drept, curb A, curb B) si fiecare capat (+/-),
   vertecsii din planul capatului (perpendicular pe tangenta) se compara cu cele 8
   puncte de sectiune ale miezului (din GUSUKU); se tipareste abaterea maxima.
2) `arch_rot.glb` (doar piatra, fara canat): poarta cu axa tunelului (X) rotita pe Y, ca
   `measure_gap.py` (directia de mers = Y) sa o poata citi; calea e in
   argumentele dupa al doilea `--` (implicit `arch_rot.glb` langa GLB).
"""
import bpy
import math
import os
import sys
from mathutils import Vector

HERE_P = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE_P))
MD = os.path.join(PROJ, "assets", "models", "okinawa", "structures")
exec(open(os.path.join(HERE_P, "okinawa_shapes.py")).read())


def _load(name):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(MD, name + ".glb"))
    return [o for o in bpy.context.selected_objects if o.type == "MESH"]


def _expected(spec=GUSUKU):
    h, zc, co = spec["h"], spec["z_crest"], spec["cap_over"]
    n_o0, n_i0 = gusuku_n(0.0, 1, spec), gusuku_n(0.0, -1, spec)
    n_oc, n_ic = gusuku_n(zc, 1, spec), gusuku_n(zc, -1, spec)
    return [(n_o0, 0.0), (n_oc, zc), (n_oc + co, zc), (n_oc + co, h),
            (n_ic - co, h), (n_ic - co, zc), (n_ic, zc), (n_i0, 0.0)]


def _end_check(label, obj, half, phi):
    exp = _expected()
    for sg in (-1, 1):
        ph = sg * phi
        E = Vector((0.0, sg * half, 0.0))
        T = Vector((-math.sin(ph), math.cos(ph), 0.0))
        N = Vector((math.cos(ph), math.sin(ph), 0.0))
        pts = []
        for v in obj.data.vertices:
            w = obj.matrix_world @ v.co
            d = w - E - Vector((obj.location.x, 0.0, 0.0)) * 0
            d = (w - obj.location) - E
            if abs(d.dot(T)) < 1e-3:
                pts.append((d.dot(N), w.z))
        worst = 0.0
        for (n, z) in exp:
            worst = max(worst, min(math.hypot(n - p[0], z - p[1]) for p in pts))
        print("CAPAT %-9s %s  vertecsi in plan %3d, abatere max fata de sectiunea de miez %.5f m"
              % (label, "+" if sg > 0 else "-", len(pts), worst))


straight = _load("gusuku_wall_straight")
_end_check("drept", straight[0], 6.0, 0.0)
curve = _load("gusuku_wall_curve")
for o in curve:
    R = 20.0 if "_A_" in o.name else 40.0
    _end_check("curb " + ("A" if R == 20.0 else "B"), o, 8.0, math.asin(8.0 / R))

# poarta boltita rotita (tunel pe Y)
objs = [o for o in _load("gusuku_arch_gate") if o.name.endswith("_Limestone")]  # canatul e decor, nu gol
for o in bpy.context.scene.objects:
    o.select_set(o in objs)
for o in objs:
    o.rotation_mode = "XYZ"
    o.rotation_euler = (0.0, 0.0, math.radians(90.0))
bpy.context.view_layer.update()
bpy.ops.object.select_all(action="DESELECT")
for o in objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = objs[0]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
args = sys.argv[sys.argv.index("--") + 2:] if sys.argv.count("--") > 1 else []
out = args[0] if args else os.path.join(MD, "..", "..", "..", "..", "arch_rot.glb")
out = os.path.abspath(out)
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True,
                          export_yup=True, export_apply=True)
print("poarta rotita:", out)
