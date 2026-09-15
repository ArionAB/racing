"""Sonda de OCLUZIE pentru scara: treptele lipsesc, sau sunt doar ascunse?

Randeaza `inca_stair_a.glb` din trei unghiuri, ca sa separe cele doua ipoteze
care dau aceeasi imagine pe plansa de grup ("o pana neteda"):

  1. treptele nu exista / s-au topit in rampa (problema de geometrie)
  2. treptele exista, dar obrajii de zid le ocluzeaza din unghiul jos al plansei
     (problema de compozitie a piesei)

Unghiurile:
  `_slope`  din fata pantei, elevatie mica — vederea in care se conduce
  `_top`    de sus (elevatie 55°) — daca treptele apar AICI dar nu in `_slope`,
            ipoteza 2 e confirmata
  `_side`   din lateral, unde profilul treptelor se vede in silueta

E o sonda de unica folosinta, nu o plansa de livrare: raspunde la o intrebare
si dispare din fluxul normal (nu e in `preview_machupicchu.py`).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_stair_check.py
"""

import bpy
import os

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "preview.py")).read())

OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)
path = os.path.join(MODELS, "machupicchu", "structures", "inca_stair_a.glb")
if not os.path.exists(path):
    raise SystemExit("LIPSA: " + path)


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def load():
    _clear()
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    bpy.context.view_layer.update()
    for ob in bpy.data.objects:
        if ob.type == "MESH":
            ob.hide_render = (ob not in objs) and not ob.name.startswith("Preview")
    return objs


# Scara urca spre +Y. Azimutul 90° priveste DE-A LUNGUL pantei din fata ei;
# elevatia mica e vederea din masina, cea in care piesa se judeca.
for tag, azim, elev in (("slope", 90.0, 12.0),
                        ("top", 90.0, 55.0),
                        ("side", 0.0, 18.0)):
    built = load()
    shot(built, os.path.join(OUT, "machupicchu_stair_%s.png" % tag),
         azimuth=azim, elevation=elev, res=(1200, 800))
    print("randat:", tag)

# Cotele profilului, ca sa stim CE ar trebui sa se vada: inaltimea parapetului
# obrazului peste linia calcai e exact cifra pe care coordonatorul o banuieste
# (0.55 m). O masuram pe geometria exportata, nu din cod.
built = load()
o = built[0]
ys = [(o.matrix_world @ v.co) for v in o.data.vertices]
x_in = [p for p in ys if abs(p.x) < 1.0]      # corpul scarii (latime 2.0)
x_out = [p for p in ys if abs(p.x) > 1.05]    # obrajii
if x_in and x_out:
    print("corp scara: z max = %.3f" % max(p.z for p in x_in))
    print("obraji:     z max = %.3f" % max(p.z for p in x_out))
    print("parapet peste corp: %.3f m"
          % (max(p.z for p in x_out) - max(p.z for p in x_in)))
