"""fence_ranch.glb — module de gard de ranch pentru marginile drumului.
Brief: docs/asset_briefs/fence_ranch.md · issue #148

Trei module, copii directi ai radacinii, exportate la origine:
  Fence_A  intreg
  Fence_B  obosit (stalpi inclinati, lisa de sus lasata)
  Fence_C  rupt (un stalp, o lisa franta, una cazuta)

Toate au 4.0 m pe X, cu stalpii la x = +-1.9, ca modulele puse la pas de 4 m
sa se atinga cap la cap. Fata gardului priveste spre +Y in Blender (= -Z in
Godot).
"""

import math
from mathutils import Matrix

SPAN = 1.9          # x-ul stalpilor
POST_T = 0.14       # sectiunea stalpului
POST_H = 1.15
RAIL_W = 0.16       # inaltimea lisei (cat de „lata" se vede din fata)
RAIL_T = 0.06       # grosimea ei
RAIL_LOW = 0.62
RAIL_HIGH = 1.00

TILT = 7.0          # Fence_B


def tilt(builder, deg, axis):
    rot = Matrix.Rotation(math.radians(deg), 3, axis)
    for v in builder.bm.verts:
        v.co = rot @ v.co


def post(b, x, h=POST_H):
    return b.box(center=(x, 0.0, h * 0.5), size=(POST_T, POST_T, h), slot=WOOD)


def rail(b, z, x0=-SPAN, x1=SPAN, drop=0.0):
    """Lisa orizontala intre doi stalpi. `drop` lasa capatul din dreapta mai jos.

    Se face din `beam` (nu din `box`) tocmai pentru `drop`: grinda dintre doua
    puncte se inclina singura, pe cand o cutie ar fi trebuit rotita de mana si
    ar fi iesit cu capetele in aer."""
    return b.beam((x0, 0.0, z), (x1, 0.0, z - drop), (RAIL_T, RAIL_W), WOOD)


def build_whole():
    b = Builder()
    post(b, -SPAN)
    post(b, SPAN)
    rail(b, RAIL_LOW)
    rail(b, RAIL_HIGH)
    return b


clear_built("Fence")
built = []

# ------------------------------------------------------------------ Fence_A
built.append(("Fence_A", build_whole()))

# ------------------------------------------------------------------ Fence_B
# Obosit: stalpii INCLINATI IN LATERAL, adica rotatie in jurul axei LUNGI (X).
#
# Prima incercare inclina pe Y — ceea ce pentru un obiect de 4 m inseamna sa-l
# ridici ca pe un balansoar: un capat urca 4 * sin(7°) = 49 cm, si `finish`
# coboara apoi tot gardul pana atinge solul, deci iesea 1.62 m inaltime in loc
# de 1.15. Un gard obosit se apleaca in lateral, nu se cocoseaza pe lungime.
# Restul de inclinare pe Y ramane MIC (1.5°), doar cat sa nu fie perfect drept.
b = Builder()
post(b, -SPAN)
post(b, SPAN)
rail(b, RAIL_LOW)
rail(b, RAIL_HIGH, drop=0.08)
tilt(b, TILT, "X")
tilt(b, 1.5, "Y")
built.append(("Fence_B", b))

# ------------------------------------------------------------------ Fence_C
# Rupt: un singur stalp, lisa de jos franta la ~60%, lisa de sus cazuta si
# sprijinita oblic de stalpul ramas. Ruptura e o fata oblica, nu geometrie
# zdrentuita — la 40 m diferenta nu se vede, dar bugetul o simte.
b = Builder()
post(b, -SPAN)
rail(b, RAIL_LOW, x1=SPAN * 0.2)
# Cazuta: de la varful stalpului ramas pana pe pamant, spre capatul lipsa.
b.beam((-SPAN + 0.1, 0.0, 0.92), (SPAN * 0.75, 0.0, RAIL_W * 0.5),
       (RAIL_T, RAIL_W), WOOD)
built.append(("Fence_C", b))

# ------------------------------------------------------------------ finisaj
objs = []
for name, b in built:
    obj = b.to_object(name)
    stats = finish(
        obj,
        bevel=0.02, bevel_angle=30.0,   # clasa "prop" din style_bible §3
        ao=dict(samples=24, dist=1.2, gradient="vertical",
                low=0.55, high=1.00, power=1.0, floor=0.30),
    )
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    print("%-9s %3d tris | lungime=%.2f m | inaltime=%.2f m | AO %.2f..%.2f"
          % (name, stats["tris"], max(xs) - min(xs), max(zs) - min(zs),
             stats["ao_min"], stats["ao_max"]))
    objs.append(obj)

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "structures/fence_ranch.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "fence_ranch.blend"))
for i, o in enumerate(objs):
    o.location = (i * 4.5, 0.0, 0.0)
