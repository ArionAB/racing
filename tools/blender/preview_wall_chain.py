"""Testul de INLANTUIRE a zidului (brief §3, pasul 2 al valului de cetate).

Importa `inca_wall_a.glb` de DOUA ori si aseaza a doua instanta la exact 4.0 m
pe X fata de prima — adica exact cum le pune pista cap la cap. Randeaza doua
cadre: unul de ansamblu si unul STRANS pe imbinare, fiindca un rost de 2 cm nu
se vede intr-un cadru care cuprinde 8 m de zid.

E verificare vizuala, nu aritmetica, si exista tocmai fiindca `verify_glb.py`
nu vede forma: el ar da VERDICT: OK si pe doua ziduri intre care cade o santura
de bevel de 16 cm.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_wall_chain.py
"""

import bpy
import os

PITCH = 4.0        # lungimea nominala a zidului `a` = pasul de asezare


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "preview.py")).read())

OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)
path = os.path.join(MODELS, "machupicchu", "structures", "inca_wall_a.glb")
if not os.path.exists(path):
    raise SystemExit("LIPSA: " + path)

_clear()
built = []
for k in range(2):
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    for o in objs:
        if o.parent is None:
            o.location.x = k * PITCH
    built += objs
bpy.context.view_layer.update()

# Cotele MASURATE ale unei instante: capetele trebuie sa cada la +-PITCH/2, ca
# a doua piesa (mutata cu exact PITCH) sa se lipeasca fara suprapunere si fara
# gol. Daca `x` nu iese simetric, originea nu e pe mijlocul zidului si
# inlantuirea la pas fix e imposibila indiferent cum arata capatul.
o = built[0]
lo = [min((o.matrix_world @ v.co)[i] for v in o.data.vertices) for i in range(3)]
hi = [max((o.matrix_world @ v.co)[i] for v in o.data.vertices) for i in range(3)]
print("instanta 1: x[%+.4f, %+.4f]  y[%+.4f, %+.4f]  z[%+.4f, %+.4f]"
      % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
print("lungime masurata pe X: %.4f m (nominal %.2f)" % (hi[0] - lo[0], PITCH))
print("ROST la imbinare: %+.4f m (pozitiv = gol, negativ = suprapunere)"
      % (PITCH - (hi[0] - lo[0])))

for ob in bpy.data.objects:
    if ob.type == "MESH":
        ob.hide_render = (ob not in built) and not ob.name.startswith("Preview")

shot(built, os.path.join(OUT, "machupicchu_wall_chain.png"),
     azimuth=38.0, elevation=16.0, res=(1600, 720))

# Cadru STRANS pe imbinare: camera pe rostul dintre piese, de aproape. Fara el
# rostul se pierde intre pixeli — 2 cm pe un cadru de 8 m inseamna 4 pixeli.
seam = bpy.data.objects.new("PreviewSeamTarget", None)
bpy.context.scene.collection.objects.link(seam)
seam.location = (PITCH * 0.5, 0.0, 1.6)


class _Fake:
    """Un obiect minimal cu bound_box, ca `shot` sa incadreze o CASETA in jurul
    rostului in loc de tot lotul. `shot` cere doar `bound_box` si
    `matrix_world`."""

    def __init__(self, center, half):
        self.name = "SeamBox"
        cx, cy, cz = center
        self.bound_box = [(cx + sx * half, cy + sy * half, cz + sz * half)
                          for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        self.matrix_world = seam.matrix_world.copy()
        self.matrix_world.identity()


shot([_Fake((PITCH * 0.5, 0.0, 1.4), 1.1)] + built,
     os.path.join(OUT, "machupicchu_wall_seam.png"),
     azimuth=25.0, elevation=8.0, res=(1400, 900), ground=False)
print("gata: machupicchu_wall_chain.png + machupicchu_wall_seam.png")
