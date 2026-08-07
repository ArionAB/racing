"""marker_post.glb — stalpi de delimitare a marginii de drum.
Brief: docs/asset_briefs/marker_post.md · issue #B1

Buget: <= 90 de triunghiuri PER VARIANTA, si e cel mai strans din tot proiectul.
Motivul e aritmetica, nu estetica: obiectul asta se instantiaza de 110 ori pe
Dunele, deci fiecare triunghi in plus costa 110. Popicele de bowling pe care le
inlocuieste au 196 fiecare — 21.560 in total, adica 31% din toata pista.

Trei variante, copii directi ai radacinii, exportate la origine:
  Marker_A  drept
  Marker_B  inclinat, lovit de o masina
  Marker_C  rupt la jumatate

Banda reflectorizanta se orienteaza spre +Y in Blender (= -Z in Godot).
"""

import math
from mathutils import Matrix

# Sectiunea e patrata, 0.14 x 0.14 m. `revolve` cu 4 laturi pune varfurile pe
# axe, deci raza e jumatate de DIAGONALA: 0.14 / sqrt(2).
POST_R = 0.14 / math.sqrt(2.0)
BAND_Z = 0.80                     # taietura de sub banda reflectorizanta
POST_TOP = 1.14                   # de unde incepe tesitura varfului
POST_TIP = 1.26                   # varful — brief: 1.1-1.3 m

BROKEN_SHAFT = 0.44
BROKEN_TIP = 0.62

TILT_DEG = 12.0                   # Marker_B


def spin45(builder):
    """Roteste geometria cu 45° in jurul lui Z.

    `revolve` cu segments=4 pune VARFURILE pe axe, deci fetele privesc pe
    diagonale. Banda reflectorizanta trebuie sa se uite drept spre drum (+Y),
    deci intoarcem tot cu 45° si abia dupa aia etichetam fetele."""
    rot = Matrix.Rotation(math.radians(45.0), 3, "Z")
    for v in builder.bm.verts:
        v.co = rot @ v.co


def tilt(builder, deg, axis="X"):
    rot = Matrix.Rotation(math.radians(deg), 3, axis)
    for v in builder.bm.verts:
        v.co = rot @ v.co


def build_post(broken=False):
    """Un stalp intr-un Builder propriu — variantele se exporta separat."""
    b = Builder()
    if broken:
        # Ruptura: apexul lui `revolve` inchide varful cu 4 triunghiuri, deci nu
        # ramane gaura, iar mutarea lui laterala (mai jos) transforma piramida
        # intr-o fata oblica. O ruptura "zdrentuita" ar cere de trei ori bugetul.
        faces = b.revolve(profile=[(POST_R, 0.0), (POST_R, BROKEN_SHAFT),
                                   (0.0, BROKEN_TIP)],
                          slot=WOOD, segments=4, cap_bottom=True)
    else:
        faces = b.revolve(profile=[(POST_R, 0.0), (POST_R, BAND_Z),
                                   (POST_R, POST_TOP), (0.0, POST_TIP)],
                          slot=WOOD, segments=4, cap_bottom=True)
    spin45(b)
    return b, faces


clear_built("Marker")
built = []

# --------------------------------------------------------------- Marker_A
b, faces = build_post()
# Banda: NU e geometrie separata, e fata dinspre drum a segmentului de sus, cu
# alt slot. Costa 0 triunghiuri (dio_lib.retag) fata de 2 pentru o taietura si
# ~30 pentru o placuta lipita.
b.retag(faces, KERB_RED, where=lambda c, n: n.y > 0.5 and c.z > BAND_Z)
built.append(("Marker_A", b))

# --------------------------------------------------------------- Marker_B
b, faces = build_post()
b.retag(faces, KERB_RED, where=lambda c, n: n.y > 0.5 and c.z > BAND_Z)
# Inclinat pe DOUA axe, nu pe una. Cu o singura axa, jumatate din unghiurile de
# camera il prind exact din directia inclinarii si stalpul pare drept — la 110
# instante inseamna ca varietatea dispare tocmai cand ai nevoie de ea.
# Baza ramane in pamant: `finish(origin="base")` coboara oricum punctul cel mai
# de jos la zero.
tilt(b, TILT_DEG, "X")
tilt(b, TILT_DEG * 0.7, "Y")
built.append(("Marker_B", b))

# --------------------------------------------------------------- Marker_C
b, faces = build_post(broken=True)
# Rupt = fara banda: si-a pierdut treimea de sus, adica exact partea vopsita.
# Apexul se muta lateral, deci varful devine o fata oblica, nu o piramida.
top = max(b.bm.verts, key=lambda v: v.co.z)
top.co.x += 0.055
top.co.y += 0.030
top.co.z -= 0.020
tilt(b, -4.0, "Y")
built.append(("Marker_C", b))

# ------------------------------------------------------------------ finisaj
objs = []
for name, b in built:
    obj = b.to_object(name)
    stats = finish(
        obj,
        bevel=0.02, bevel_angle=30.0,   # clasa "prop" din style_bible §3
        ao=dict(samples=24, dist=1.2, gradient="vertical",
                low=0.55, high=1.00, power=1.0, floor=0.32),
    )
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    half = max(max(xs) - min(xs), max(ys) - min(ys)) * 0.5
    print("%-9s %3d tris | h=%.3f m | jumatate latime=%.3f m | AO %.2f..%.2f"
          % (name, stats["tris"], max(zs) - min(zs), half,
             stats["ao_min"], stats["ao_max"]))
    objs.append(obj)

# Toate trei la origine: Godot le cauta ca fii directi si le aseaza el
# (blender_export.md, sectiunea despre GLB-uri cu variante).
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "signs/marker_post.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "marker_post.blend"))
for i, o in enumerate(objs):
    o.location = (i * 0.9, 0.0, 0.0)
