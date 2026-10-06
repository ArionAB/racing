"""Randari de control pentru calul animat (Walk/Idle), din GLB-ul EXPORTAT.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_monument_horse.py -- horse_bay

Importa `animals/<nume>.glb`, pastreaza armatura + mesh-ul skinnuit (ascunde
`Pose_Stand`, poza statica), seteaza actiunea si cadrul, randeaza. Scrie in
docs/track_briefs/img/monument_cai/:
  <nume>_walk_f01.png ... (profil, 4 cadre din ciclul Walk: 0, 1/4, 1/2, 3/4)
  <nume>_walk_3q_f01.png  (3/4 din fata, aceleasi cadre)
  <nume>_idle_f*.png
si afiseaza un tabel numeric al talpilor (acelasi ciclu): pozitia talpii fata de
corp, plus pozitia in "lume" (corpul avanseaza cu WALK_STRIDE_SPEED) -- in stance
trebuie sa ramana pe loc si la z~sol.

Randarea ruleaza pe GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
"""
import bpy
import math
import os
import sys
from mathutils import Vector

# reutilizam _render/_per_slot_tint din preview_monument (fara argumente nu
# ruleaza nimic, doar afiseaza docstring-ul)
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "preview_monument.py")).read())

OUT = os.path.join(PROJ, "docs", "track_briefs", "img", "monument_cai")
os.makedirs(OUT, exist_ok=True)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
name = args[0] if args else "horse_bay"
path = os.path.join(MODELS_DIR, "animals", name + ".glb")

_clear()
# fps ca in joc (glTF are timpi in secunde; importul le converteste cu fps-ul scenei)
bpy.context.scene.render.fps = 30
bpy.ops.import_scene.gltf(filepath=path)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
skinned = [o for o in meshes if o.parent == arm]
static = [o for o in meshes if o not in skinned]
print("armatura:", arm.name, "| oase:", len(arm.data.bones),
      "| mesh skinnuit:", [o.name for o in skinned], "| static:", [o.name for o in static])
print("actiuni:", sorted(a.name for a in bpy.data.actions))
for o in skinned:
    _fix_ao_layer_name(o)
    _per_slot_tint(o)
for o in static:
    o.hide_render = True
    o.hide_viewport = True

# podea simpla: o dala la z=0, ca sa se vada daca talpile ating solul
me = bpy.data.meshes.new("PreviewGround")
floor = bpy.data.objects.new("PreviewGround", me)
bpy.context.scene.collection.objects.link(floor)
import bmesh
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=2.0)
bm.to_mesh(me)
bm.free()
mat = bpy.data.materials.new("PreviewGroundMat")
mat.use_nodes = True
mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.55, 0.45, 0.32, 1)
me.materials.append(mat)


def set_frame(action_name, frame):
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = bpy.data.actions[action_name]
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()


# podeaua: ~3,2 x 2,4 m (include-o in incadrare, e mica)
me.transform(__import__("mathutils").Matrix.Diagonal((0.6, 0.8, 1.0, 1.0)))

action_frames = {"Walk": [1, 7, 13, 19], "Idle": [1, 31, 61]}
for act, frames in action_frames.items():
    for fr in frames:
        set_frame(act, fr)
        for o in bpy.data.objects:
            if o.type == "MESH":
                o.hide_render = o not in skinned and o is not floor
        # incadrare: caii + podeaua
        _render(skinned + [floor], os.path.join(OUT, "%s_%s_f%02d.png" % (name, act.lower(), fr)),
                azimuth=0.0, elevation=6.0, lens=70.0, margin=1.12,
                res_height=520, aspect=1.45)
        if act == "Walk":
            _render(skinned + [floor], os.path.join(OUT, "%s_%s_3q_f%02d.png" % (name, act.lower(), fr)),
                    azimuth=40.0, elevation=12.0, lens=70.0, margin=1.12,
                    res_height=520, aspect=1.45)

# --- talpile: varfurile de jos ale copitelor, din mesh-ul EVALUAT (skinnuit) --
# (oasele importate din glTF isi pierd coada reala, deci masuram geometria.)
print("\n== talpi (varfuri de copita, mesh evaluat); corpul avanseaza 1.5 m/s ==")
sk = skinned[0]
rest = [v.co.copy() for v in sk.data.vertices]
legs = {"F_L": (1, -1), "F_R": (1, 1), "H_L": (-1, -1), "H_R": (-1, 1)}
sel = {}
for l, (fy, sx) in legs.items():
    sel[l] = [i for i, c in enumerate(rest)
              if c.z < 0.03 and (c.y > 0) == (fy > 0) and (c.x > 0) == (sx > 0)]
FPS = bpy.context.scene.render.fps
NF = 24
rows = {l: [] for l in legs}
for k in range(2 * NF):                       # doua cicluri, ca stance-ul sa nu fie taiat la bucla
    fr = k % NF + 1
    set_frame("Walk", fr)
    ev = sk.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = ev.to_mesh()
    t = k / FPS
    for l in legs:
        pts = [sk.matrix_world @ mesh.vertices[i].co for i in sel[l]]
        y = sum(p.y for p in pts) / len(pts)
        z = min(p.z for p in pts)
        rows[l].append((k, y + 1.5 * t, z))
    ev.to_mesh_clear()
TOL = 0.03
for l in legs:
    zs = [r[2] for r in rows[l]]
    zmin = min(zs)
    best = []
    run = []
    for r in rows[l]:
        if r[2] < zmin + TOL:
            run.append(r)
        else:
            if len(run) > len(best):
                best = run
            run = []
    if len(run) > len(best):
        best = run
    ys = [r[1] for r in best]
    print("%s  copita z min/max: %.3f / %.3f | cel mai lung sprijin: %d cadre din %d (<min+3cm)"
          " | y-lume min/max: %.3f / %.3f (alunecare %.3f m)"
          % (l, zmin, max(zs), len(best), NF, min(ys), max(ys), max(ys) - min(ys)))
    print("     z pe cadre:", " ".join("%.0f" % (r[2] * 100) for r in rows[l][:NF]))
