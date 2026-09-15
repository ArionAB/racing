"""Machu Picchu — ANIMALE (plansa de inventar, randul 6).

  machupicchu/animals/llama.glb     lama alba   (FOAM_WHITE)
  machupicchu/animals/llama_b.glb   lama bej    (SAND_MID)
  machupicchu/animals/llama_c.glb   lama maro   (LOG_DARK)
  machupicchu/animals/condor.glb    condor asezat pe stanca (STATIC, vezi mai jos)

LAMELE: import, nu Builder (memoria `asset-animat-pipeline`). Sursa e alpaca
Quaternius din "Ultimate Animated Animals" (CC0, animata), iar reteta e cea a
vacii (`build_cow_animated.py`), pas cu pas:

  1. se pastreaza DOAR mesh-ul parentat pe armatura (sursa are si gunoi de autor)
  2. `remove_doubles` INAINTE de `Decimate` — memoria `decimare-mesh-importat`:
     pe un mesh importat varfurile sunt despicate pe muchiile de UV/normala, si
     decimarea pe ele rupe mesh-ul in loc sa-l simplifice
  3. UV-urile colapsate pe centrul sloturilor, per material sursa
  4. AO doar gradient vertical (raycast-ul ar picta umbre care raman lipite de
     blana cand scheletul se misca)
  5. NLA stash cu `mute=True`, `export_glb(..., animations=True)`
  6. rotatia si scara raman pe NODUL armaturii, nu se aplica pe date

CONTRACTUL CARE CONTEAZA CEL MAI MULT sunt numele actiunilor. `SlidingHazard`
le cauta EXACT (`sliding_hazard.gd:103-105`), iar la `:371` face `return` daca
lipseste un clip numit fix `Walk` — adica **fara `Walk` tot rig-ul e ignorat in
tacere**, lama ramane teapana si nimic nu semnaleaza eroarea. De-aia cele patru
nume se verifica si dupa export, din FISIER (`verify_llama_actions.py`).

Cele TREI lame sunt trei exporturi din ACELASI build: se schimba doar slotul
blanii intre ele (`_recolor`), restul (schelet, animatii, greutati) e identic.

CONDORUL: STATIC, deliberat. Brief-ul §1.4 cere rig cu actiunile `Open`/`Close`,
dar **nimic din `scenes/` nu le declanseaza** — am cautat: `Open`/`Close` n-au
niciun consumator, iar `Area3D`-ul la 25 m care le-ar porni e cod de integrare
si nu e scris. Un rig fara declansator e cost fara efect, si mai ales e cost pe
care integrarea l-ar gasi gata-facut dar nefolosibil (poza de repaus a unui rig
neconsumat ramane oricum cea din fisier). Deci: model asezat, aripile STRANSE,
ca pe plansa (randul 6, stanga). Aripile raman insule de mesh separate, ca
rig-ul de mai tarziu sa aiba de ce sa se lege fara sa retaie geometria.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_animals.py
"""

import bpy
import math
from mathutils import Matrix, Vector

PACK = (r"D:\GameDev\downloaded assets"
        r"\Ultimate Animated Animals - July 2021-20260813T155229Z-1-001"
        r"\Ultimate Animated Animals - July 2021\glTF\Alpaca.gltf")

# Cote de contract (brief §1.4): 1.7 m la cap, 1.1 la greaban, 1.4 lung.
# Se tinteste LUNGIMEA, fiindca ea e cota pe care alpaca sursa o are corecta
# proportional; inaltimea iese din ea si se RAPORTEAZA (vezi build()).
TARGET_LENGTH = 1.4
KEEP_ACTIONS = ("Idle", "Eating", "Walk", "Gallop")
TRI_BUDGET = 400

# Materialele sursei -> sloturi. Blana (`Main`) e parametru, restul e fix.
#   Main       blana                 -> slotul variantei
#   Main_Light burta/gat mai deschis -> tot slotul variantei (o lama e de o
#              culoare; doua sloturi de blana ar face-o patata, iar pe plansa
#              cele trei lame sunt fiecare monocrome)
#   Main_Dark  copite/detalii inchise-> ROCK_DARK
#   Hooves     copite                -> ROCK_DARK
#   Muzzle     botul                 -> ROCK_DARK (brief: "botul si copitele")
#   Eyes_Black / Eyes_White          -> ROCK_DARK / FOAM_WHITE
FLEECE_MATS = ("Main", "Main_Light")
FIXED_MATS = {
    "Main_Dark": ROCK_DARK,
    "Hooves": ROCK_DARK,
    "Muzzle": ROCK_DARK,
    "Eyes_Black": ROCK_DARK,
    "Eyes_White": FOAM_WHITE,
}

VARIANTS = [
    ("llama.glb", FOAM_WHITE, "alba"),
    ("llama_b.glb", SAND_MID, "bej"),
    ("llama_c.glb", LOG_DARK, "maro"),
]

AO_FLOOR = 0.78  # burta; 1.0 pe spinare — bland, ca la vaca


def _world_bbox(objects):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    deps = bpy.context.evaluated_depsgraph_get()
    for o in objects:
        for corner in o.evaluated_get(deps).bound_box:
            w = o.matrix_world @ Vector(corner)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def _decimate_to(mesh, budget):
    """`remove_doubles` apoi `Decimate` pana sub buget.

    ORDINEA E CONTRACTUL (memoria `decimare-mesh-importat`): pe mesh-ul
    importat varfurile sunt despicate pe muchiile de UV si de normala, deci
    colapsul de muchii al decimarii lucreaza pe o topologie care arata gaurita
    si rupe piesa. Sudura le reuneste intai.

    Se decimeaza pe mesh-ul SKINNUIT: `Decimate` pastreaza vertex groups prin
    interpolare, deci greutatile supravietuiesc. Se aplica INAINTE de orice
    masuratoare de cote, ca bbox-ul raportat sa fie al geometriei livrate.
    """
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh

    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=1e-4)
    bpy.ops.object.mode_set(mode="OBJECT")
    welded = tri_count(mesh)

    ratio = 1.0
    if welded > budget:
        # Ratia e pe triunghiurile de DUPA sudura, nu pe cele din fisier:
        # sudura singura scoate deja o parte, iar o ratie calculata pe cifra
        # bruta ar decima de doua ori mai mult decat trebuie.
        ratio = float(budget) / float(welded)
        mod = mesh.modifiers.new("Decimate", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = ratio
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return welded, ratio


def build():
    """Importa alpaca, o aduce la contract, intoarce (armatura, mesh).

    Nu exporta nimic: cele trei variante se obtin recolorand mesh-ul intre
    exporturi (`_recolor`), ca scheletul si animatiile sa fie bit-identice.
    """
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)

    bpy.ops.import_scene.gltf(filepath=PACK)

    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    assert len(arms) == 1, "asteptam 1 armatura, am gasit %r" % [a.name for a in arms]
    arm = arms[0]
    skinned = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm]
    assert len(skinned) == 1, "asteptam 1 mesh skinnuit: %r" % [o.name for o in skinned]
    mesh = skinned[0]
    for o in [o for o in bpy.data.objects if o.type == "MESH" and o is not mesh]:
        print("arunc obiectul strain din sursa:", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
    arm.name, mesh.name = "Llama", "LlamaMesh"
    arm.data.name = "LlamaArmature"
    mesh.data.name = "LlamaMesh"

    # -- Animatii: exact cele patru cerute de SlidingHazard.
    dropped = []
    for a in list(bpy.data.actions):
        base = a.name.split(".")[0]
        if base in KEEP_ACTIONS:
            a.name = base
            a.use_fake_user = True
        else:
            dropped.append(a.name)
            bpy.data.actions.remove(a)
    have = sorted(a.name for a in bpy.data.actions)
    assert have == sorted(KEEP_ACTIONS), "animatii lipsa: %r" % have
    stash_actions(arm, KEEP_ACTIONS)

    # -- Decimare la buget (sudura intai). Inainte de masuratori.
    raw = tri_count(mesh)
    welded, ratio = _decimate_to(mesh, TRI_BUDGET)
    print("tris: sursa %d -> sudat %d -> decimat %d (ratio %.3f)"
          % (raw, welded, tri_count(mesh), ratio))

    # -- Orientare + scara, pe NODUL armaturii.
    lo, hi = _world_bbox([mesh])
    size = hi - lo
    length_axis = "Y" if size.y >= size.x else "X"
    length = getattr(size, length_axis.lower())
    print("bbox import: %.2f x %.2f x %.2f m, lungimea pe %s"
          % (size.x, size.y, size.z, length_axis))

    arm.rotation_mode = "XYZ"
    if length_axis == "X":
        arm.rotation_euler.rotate_axis("Z", math.pi * 0.5)

    # Incotro e capul: din OASE, nu din geometrie (nota din build_cow_animated:
    # la patrupedele astea coada e adesea ridicata mai sus decat capul, deci
    # euristica "masa de sus" cade pe coada).
    def bone_y_basis(prefix):
        for b in arm.data.bones:
            if b.name.startswith(prefix):
                return (arm.matrix_basis @ b.head_local).y
        raise AssertionError("os lipsa: %s*" % prefix)

    if bone_y_basis("Head") < bone_y_basis("Tail"):
        arm.rotation_euler.rotate_axis("Z", math.pi)
        print("capul era spre -Y, am intors lama")

    # A doua jumatate a garzii (lectia vacii): se verifica pe geometria care
    # CHIAR se exporta, prin transformul armaturii dupa update, nu pe
    # `matrix_basis` inainte de el.
    def bone_y_world(prefix):
        for b in arm.data.bones:
            if b.name.startswith(prefix):
                return (arm.matrix_world @ b.head_local).y
        raise AssertionError("os lipsa: %s*" % prefix)

    bpy.context.view_layer.update()
    assert bone_y_world("Head") > bone_y_world("Tail"), (
        "capul spre -Y (deci +Z in Godot): cap %.3f <= coada %.3f"
        % (bone_y_world("Head"), bone_y_world("Tail")))

    arm.scale *= TARGET_LENGTH / length
    bpy.context.view_layer.update()

    # Origine la sol, centrata XY.
    lo, hi = _world_bbox([mesh])
    center = (lo + hi) * 0.5
    arm.location -= Vector((center.x, center.y, lo.z))
    bpy.context.view_layer.update()

    # -- AO: gradient vertical pe poza de repaus.
    me = mesh.data
    lo, hi = _world_bbox([mesh])
    for layer in list(me.color_attributes):
        me.color_attributes.remove(layer)
    ao = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="CORNER")
    z0, z1 = lo.z, hi.z
    for poly in me.polygons:
        for li in poly.loop_indices:
            w = mesh.matrix_world @ me.vertices[me.loops[li].vertex_index].co
            t = max(0.0, min(1.0, (w.z - z0) / max(z1 - z0, 1e-6)))
            v = AO_FLOOR + (1.0 - AO_FLOOR) * t
            ao.data[li].color = (v, v, v, 1.0)
    me.color_attributes.active_color = ao

    # Materialul sursei per fata se retine ACUM, inainte sa golim lista:
    # `_recolor` are nevoie de el la fiecare varianta.
    mat_of_poly = {}
    for poly in me.polygons:
        mat = me.materials[poly.material_index] if me.materials else None
        mat_of_poly[poly.index] = (mat.name.split(".")[0] if mat else "")
    for name in set(mat_of_poly.values()):
        assert name in FLEECE_MATS or name in FIXED_MATS, \
            "material sursa nemapat: %s" % name

    me.materials.clear()
    me.materials.append(atlas_material())
    apply_smooth(mesh, 55.0)

    size = hi - lo
    print("gabarit final: %.2f lat x %.2f lung x %.2f inalt (m)"
          % (size.x, size.y, size.z))
    return arm, mesh, mat_of_poly


def _recolor(mesh, mat_of_poly, fleece_slot):
    """Rescrie UV-urile pe sloturi: blana primeste `fleece_slot`, restul e fix.

    Se reface stratul de UV de fiecare data (nu se editeaza in loc): e mai
    ieftin decat sa tinem minte ce fata a fost atinsa, si garanteaza ca nu
    ramane nimic dintr-o varianta precedenta.
    """
    me = mesh.data
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        src = mat_of_poly[poly.index]
        slot = fleece_slot if src in FLEECE_MATS else FIXED_MATS[src]
        u = slot_u(slot)
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)


# --- condor ------------------------------------------------------------------
#
# STATIC (vezi antetul). Asezat, 1.2 m inalt TOTAL de la baza stancii, pe o
# stanca de 1.5 x 1.2 x 0.8. Aripile stranse pe langa corp.
#
# Aripile sunt insule de mesh SEPARATE (fiecare din `box`/`prism` propriu, fara
# sa atinga corpul): daca integrarea decide mai tarziu sa-l animeze,
# `mesh_islands` le da direct, fara sa retaie geometria.

CD_ROCK = (1.5, 1.2, 0.8)     # stanca: X lat, Y adanc, Z inalt
CD_BODY_H = 1.2 - CD_ROCK[2]  # corpul, de la varful stancii in sus: 0.4 m
CD_TOTAL = 1.2                # contract: cota totala de la baza stancii


def build_condor():
    b = Builder()
    rock_h = CD_ROCK[2]

    # --- stanca: `rock()` cu putine segmente, ca sa aiba fatete de granit ---
    st = b.rock((0.0, 0.0, 0.0), (CD_ROCK[0], CD_ROCK[1], rock_h),
                ROCK_LIGHT, seed=9910, segments=6, rings=3, taper=0.30,
                flat_top=True)
    top_z = Builder.flat_top_z(0.0, rock_h)
    # fetele dinspre nord stau in umbra
    b.retag(st, ROCK_DARK, where=lambda c, n: n.y < -0.45)

    # --- corpul: un ovoid turtit, asezat pe stanca ---
    # `revolve` cu profil propriu: corpul unei pasari asezate e o para culcata,
    # nu o sfera. Profilul urca repede si se strange spre coada.
    #
    # Prima intrare are raza NENULA deliberat: `revolve` trateaza raza 0 ca apex
    # si IESE din bucla (`break`), deci un profil care incepe cu (0.0, 0.0) ar
    # produce un singur varf si nicio fata. Baza se inchide cu `cap_bottom`.
    #
    # `segments=9` (nu 8): pe plansa corpul cu 8 segmente citea octogonal —
    # muchia din fata cadea exact pe silueta si pasarea parea taiata din cutii.
    # Cu 9 muchia verticala nu mai cade pe contur.
    body_h = CD_BODY_H
    prof = [(0.11, 0.0), (0.16, 0.05), (0.21, 0.16), (0.19, 0.28),
            (0.12, 0.36), (0.0, body_h)]
    body = b.revolve(prof, VOLCANIC_BLACK, segments=9,
                     origin=(0.0, 0.0, top_z))
    # coada: o pana lata care iese in spate (-Y), usor in jos
    tail = b.prism([(-0.10, 0.0), (0.10, 0.0), (0.07, -0.34), (-0.07, -0.34)],
                   0.05, VOLCANIC_BLACK,
                   center=(0.0, -0.16, top_z + body_h * 0.42))
    b.retag(tail, VOLCANIC_BLACK)

    # --- gulerul alb: inelul de puf de la baza gatului (semnatura condorului) ---
    # Un tor ar fi scump; un frustum scurt si lat da exact banda alba vazuta din
    # profil, cu 3*segments triunghiuri.
    b.frustum((0.0, 0.06, top_z + body_h * 0.72), 0.13, 0.10, 0.07,
              FOAM_WHITE, segments=8)

    # --- capul + ciocul ---
    head_z = top_z + body_h * 0.92
    head = b.revolve([(0.045, 0.0), (0.075, 0.03), (0.08, 0.08), (0.0, 0.14)],
                     KERB_RED, segments=7, origin=(0.0, 0.085, head_z))
    b.retag(head, KERB_RED)
    # ciocul: con scurt spre +Y (inainte), SAND_LIGHT
    b.frustum((0.0, 0.16, head_z + 0.05), 0.035, 0.008, 0.10,
              SAND_LIGHT, segments=6, axis="Y")

    # --- aripile STRANSE: pene pliate pe flanc, insule separate ---
    #
    # PRIMA VERSIUNE ERA GRESITA SI SE VEDEA PE PLANSA: doua cutii lipite
    # lateral la 0.19 m de axa, cu corpul de raza 0.21 — adica aripile ieseau
    # DIN corp ca doua sertare trase. Pasarea citea ca un teanc de cutii, nu ca
    # o pasare. Cifrele treceau (verify nu vede forma); plansa nu.
    #
    # Aripa stransa a unei pasari asezate NU e o placa lipita pe flanc: e un
    # profil care URMEAZA curbura corpului, incepe sus langa umar, se ingusteaza
    # si coboara spre coada. Deci se construieste ca `prism` cu contur in XZ
    # (silueta aripii vazuta din lateral), extrudat SUBTIRE pe Y si asezat pe
    # raza corpului la cota umarului — nu langa ea.
    shoulder_z = top_z + body_h * 0.62
    for sy in (-1.0, 1.0):
        # Conturul aripii in planul XZ al `prism`, apoi rotit 90° ca sa cada pe
        # flancul corpului: umar lat sus-fata, varf ascutit jos-spate.
        outline = [(0.13, 0.10), (0.05, 0.16), (-0.16, 0.05),
                   (-0.21, -0.10), (-0.05, -0.06), (0.11, -0.02)]
        wing = b.prism(outline, 0.035, VOLCANIC_BLACK,
                       center=(0.0, sy * 0.155, shoulder_z))
        b.retag(wing, VOLCANIC_BLACK)

    # --- ghearele pe buza stancii: doua lopatele mici SAND_LIGHT ---
    for sx in (-1.0, 1.0):
        b.box((sx * 0.07, 0.10, top_z + 0.02), (0.06, 0.13, 0.04), SAND_LIGHT)

    return b.to_object("Condor")


# --- emit --------------------------------------------------------------------

results = []

# 1) Lamele: un singur build, trei exporturi cu blana recolorata.
arm, mesh, mat_of_poly = build()
for filename, fleece, label in VARIANTS:
    _recolor(mesh, mat_of_poly, fleece)
    path, size = export_glb([arm, mesh], "machupicchu/animals/" + filename,
                            animations=True)
    results.append((filename, tri_count(mesh), size / 1024.0,
                    "blana %s" % label))
    print("export: %s (%.0f KB, blana %s)" % (path, size / 1024.0, label))

# Sursa .blend COMPRIMATA (animata): ultima varianta exportata e cea salvata.
path, size = save_blend([arm, mesh], "machupicchu_llama.blend", compress=True)
print("sursa:  %s (%.0f KB)" % (path, size / 1024.0))

# 2) Condorul: static.
AO_CONDOR = dict(samples=20, dist=1.6, gradient="vertical",
                 low=0.46, high=1.00, power=0.90, floor=0.20)
condor = build_condor()
st = finish(condor, bevel=0.012, ao=AO_CONDOR, origin="base_axis",
            smooth_angle=42.0)
path, size = export_glb([condor], "machupicchu/animals/condor.glb")
results.append(("condor.glb", st["tris"], size / 1024.0,
                "static (rig amanat: Open/Close n-au consumator)"))
print("export: %s (%.0f KB)" % (path, size / 1024.0))
save_blend([condor], "machupicchu_condor.blend")

print()
for name, tris, kb, note in results:
    print("%-16s tris=%5d %8.1f kB  %s" % (name, tris, kb, note))
