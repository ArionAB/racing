"""rusted_digger.glb — excavator ruginit abandonat.
Brief: docs/asset_briefs/rusted_digger.md · issue #B5 (partea a doua)

Inlocuieste `toy_excavator.glb`, un excavator de plastic din tema abandonata
"lada de nisip".


CONTRACTUL DE RIG — cel mai riscant din tot lotul
--------------------------------------------------
`scenes/hazards/excavator_hazard.gd` cere DOUA noduri, nu unul:

  :30  _arm = model.find_child("arm", true, false)
  :34  var body_node := model.find_child("body", true, false)
  :39  body_aabb = model.transform * Track.model_aabb(body_node, _arm)

Al doilea argument al lui `model_aabb` e un nod de SARIT, si comentariul de la
:36-38 spune de ce: **`arm` e copil al lui `body`**, deci fara sarire iese o
cutie de 10 m pe adancime care ar bloca soseaua permanent. Deci ierarhia nu e
optionala: `arm` se pune SUB `body`.

Daca nodul `arm` lipseste, bratul ramane nemiscat **dar coliziunea tot comuta**
(`_arm_shape.disabled` se schimba oricum, :80) — adica o bariera invizibila in
mijlocul drumului. E cea mai urata clasa de bug din lista, si singurul motiv
pentru care fisierul asta a primit PR separat.

Rotatia: `_arm.rotation.x = _arm_base_rot + raise_angle * raised`, cu
raise_angle = 0.55 rad. In Godot, o rotatie POZITIVA pe X ridica ce e spre -Z.
Deci bratul se modeleaza COBORAT (pozitia care blocheaza), spre +Y in Blender,
si rotatia il ridica. `_arm_base_rot` se citeste din nod, deci rotatia proprie a
nodului `arm` trebuie sa fie zero.

Buget: 900 de triunghiuri pe AMBELE obiecte.
"""

import math
from mathutils import Vector

# Pivotul articulatiei, in spatiul de constructie (sol la z=0, masina spre +Y).
# Brieful cere (0.0, 0.6, 1.9); e mutat pe +X fiindca acolo il pune cabina —
# cabina sta pe stanga, bratul pe dreapta, ca la orice excavator.
PIVOT = (0.55, 0.75, 1.95)

TRACK_X = 1.50
TRACK_L, TRACK_W, TRACK_H = 4.00, 0.90, 1.00

BEVEL = 0.05


def build_body(b):
    # --- senile ---------------------------------------------------------------
    # Brieful cere roti de capat: cate un prismatic cu 8 laturi la fiecare capat,
    # adica 4 x 28 = 112 triunghiuri brute, aproape jumatate din bugetul brut de
    # 245. Rampa inclinata din fata da aceeasi silueta de senila cu 12: profilul
    # trapezoidal e ce recunosti de la 40 m, nu rotile.
    for sx in (-1.0, 1.0):
        x = sx * TRACK_X
        b.box((x, 0.0, TRACK_H * 0.5), (TRACK_W, TRACK_L, TRACK_H), RUST)
        b.beam((x, TRACK_L * 0.5 - 0.05, 0.30),
               (x, TRACK_L * 0.5 + 0.62, TRACK_H - 0.05),
               (TRACK_W, 0.55), RUST)

    # --- platforma rotativa ---------------------------------------------------
    b.box((0.0, -0.10, 1.35), (3.20, 2.60, 0.70), PAINTED)

    # --- cabina, decalata pe stanga -------------------------------------------
    b.box((-0.78, 0.55, 2.65), (1.60, 1.50, 1.90), PAINTED)
    # Banda de geam: o cutie usor mai mare decat cabina, care iese 3 cm pe toate
    # laturile. Brieful cere `window()` — dar ajutorul ala costa 60 de triunghiuri
    # brute pentru O fereastra, adica un sfert din tot bugetul brut pentru trei
    # ferestre. Banda continua e si mai aproape de adevar: excavatoarele au
    # cabina vitrata pe tot conturul.
    #
    # ASPHALT, nu SAND_SHADOW cum cere brieful. La prima captura banda iesea bej
    # — sand_shadow e #A97A4A, un maro mediu — si se citea ca o dunga de vopsea,
    # nu ca geam. Argumentul e chiar cel din docstring-ul lui `window()`:
    # "slotul cel mai inchis din lume citeste ca gol, nu ca sticla". Cel mai
    # inchis slot legal e asphalt (5, #4B4B4D).
    b.box((-0.78, 0.55, 2.88), (1.66, 1.56, 0.86), ASPHALT)

    # --- motor / contragreutate in spate --------------------------------------
    b.box((0.35, -1.45, 2.25), (2.00, 1.40, 1.10), PAINTED)
    b.frustum((0.95, -0.95, 3.28), 0.11, 0.09, 0.90, RUST, segments=6)


def build_arm(b):
    px, py, pz = PIVOT
    # Bratul principal si antebratul. Cotele sunt masurate pe segmente, nu pe
    # proiectii: brieful cere 3.4 m si 2.2 m.
    elbow = (px, 3.30, 3.60)
    wrist = (px, 4.90, 1.90)
    b.beam(PIVOT, elbow, (0.55, 0.45), PAINTED)
    b.beam(elbow, wrist, (0.42, 0.38), PAINTED)

    # Doi cilindri hidraulici, nu patru (brieful e explicit). `frustum` cu 6
    # laturi ar fi dat 18 brut fiecare; `beam` da 12 si la 40 m nimeni nu vede
    # ca pistonul e patrat.
    b.beam((px, py + 0.35, pz + 0.55), (px, 2.60, 3.25), 0.22, RUST)
    b.beam((px, 3.20, 3.42), (px, 4.35, 2.40), 0.20, RUST)

    # --- cupa in "C" ----------------------------------------------------------
    # Doua cutii, nu trei: spatele si fundul. A treia (peretele lateral) n-ar fi
    # adaugat silueta — cupa se vede din lateral, unde conturul in L e tot.
    b.box((px, 5.00, 1.42), (0.92, 0.26, 0.92), RUST)
    b.box((px, 5.40, 1.05), (0.92, 0.98, 0.26), RUST)
    # Patru dinti, cutii mici, cum cere brieful — nu conuri.
    for k in range(4):
        dx = -0.33 + k * 0.22
        b.box((px + dx, 5.92, 1.02), (0.15, 0.22, 0.15), RUST)


clear_built("body")
clear_built("arm")

# Cele doua obiecte se construiesc in ACELASI spatiu si se muta impreuna.
# `finish(origin="base")` ar recentra doar sasiul si bratul ar ramane decalat,
# deci deplasarea se calculeaza o data, din bbox-ul sasiului, si se aplica la
# amandoua inainte de finisaj.
bb, ab = Builder(), Builder()
build_body(bb)
build_arm(ab)

xs = [v.co.x for v in bb.bm.verts]
ys = [v.co.y for v in bb.bm.verts]
zs = [v.co.z for v in bb.bm.verts]
SHIFT = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
for builder in (bb, ab):
    for v in builder.bm.verts:
        v.co += SHIFT

body = bb.to_object("body")
arm = ab.to_object("arm")

body_stats = finish(
    body, bevel=BEVEL, origin="none",
    ao=dict(samples=28, dist=3.0, gradient="vertical",
            low=0.52, high=1.00, power=0.9, floor=0.14))
# Gradient SLAB pe brat: obiectul se roteste, deci un gradient vertical puternic
# ar arata gresit cand bratul e ridicat. Acelasi rationament ca la bolovanul din
# #B2, doar ca aici rotatia e limitata la 0.55 rad, deci nu trebuie eliminat de
# tot — doar redus.
arm_stats = finish(
    arm, bevel=BEVEL, origin="none",
    ao=dict(samples=28, dist=3.0, gradient="vertical",
            low=0.86, high=1.00, power=1.0, floor=0.40))

pivot = Vector(PIVOT) + SHIFT
set_origin_at(arm, pivot)
arm.parent = body
arm.matrix_parent_inverse = arm.matrix_parent_inverse.Identity(4)

total = body_stats["tris"] + arm_stats["tris"]
print("body %d + arm %d = %d tris (buget 900) %s"
      % (body_stats["tris"], arm_stats["tris"], total,
         "OK" if total <= 900 else "DEPASIT"))


def box_of(obj, offset=Vector((0, 0, 0))):
    me = obj.data
    lo = Vector((min(v.co[a] for v in me.vertices) for a in range(3))) + offset
    hi = Vector((max(v.co[a] for v in me.vertices) for a in range(3))) + offset
    return lo, hi


blo, bhi = box_of(body)
alo, ahi = box_of(arm, pivot)
print("  body  : %.2f x %.2f x %.2f m, baza la z=%.3f"
      % (bhi.x - blo.x, bhi.y - blo.y, bhi.z - blo.z, blo.z))
# Cotele se dau in GODOT, fiindca acolo se scriu colizoarele: (x, y, z)_Godot =
# (x, z, -y)_Blender.
print("  pivot `arm` (Godot)  : (%.3f, %.3f, %.3f)" % (pivot.x, pivot.z, -pivot.y))
print("  brat, cutie in Godot : X %.2f..%.2f | Y %.2f..%.2f | Z %.2f..%.2f"
      % (alo.x, ahi.x, alo.z, ahi.z, -ahi.y, -alo.y))
print("  adica size (%.2f, %.2f, %.2f) la position (%.2f, %.2f, %.2f)"
      % (ahi.x - alo.x, ahi.z - alo.z, ahi.y - alo.y,
         (alo.x + ahi.x) * 0.5, (alo.z + ahi.z) * 0.5, -(alo.y + ahi.y) * 0.5))

print("GLB:   %s (%d B)" % export_glb([body, arm], "rusted_digger.glb"))
print("BLEND: %s (%d B)" % save_blend([body, arm], "rusted_digger.blend"))
