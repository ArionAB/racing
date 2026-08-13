"""Vaca ANIMATA — inlocuieste vaca procedurala din kitul alpin (props/cow.glb).

Sursa: Quaternius, "Ultimate Animated Animals" (CC0), vaca maro. Primul asset
cu SCHELET si animatii din proiect — de-aia nu trece prin Builder: geometria
vine gata facuta si skinnuita, treaba scriptului e s-o aduca la CONTRACTUL
diorama (docs/blender_export.md) fara sa strice skinning-ul:

  1. UV-urile colapsate pe centrul sloturilor de paleta, per material sursa —
     culorile Quaternius se traduc in sloturi existente, atlasul nu se atinge
     (regula kitului alpin: vezi kit-alpin-asseturi).
  2. Vertex colors "AO": gradient vertical bland, copt pe poza de repaus.
     Raycast-ul din bake_ao ar picta umbre care raman lipite de blana cand
     scheletul se misca — gradientul e singurul AO cinstit pe un mesh animat.
  3. Origine la baza, centrata XY; fata spre +Y in Blender (= -Z in Godot),
     conventia testoasei: Track._build_hazard roteste hazardul pe directia de
     maturare, deci vaca merge INCOTRO se uita.
  4. Export GLB cu animatiile pastrate ca actiuni separate (NLA stash).

Animatiile pastrate din cele 13 ale pack-ului: Idle, Eating (pascutul de pe
acostament), Walk si Gallop (la vitezele de maturare mari vaca chiar alearga).
MISCAREA PE DRUM nu e copta in animatie: SlidingHazard misca nodul si alege
animatia dupa viteza reala — root motion in GLB s-ar bate cap in cap cu el.

ROTATIA si SCARA raman pe NODUL armaturii (nu se aplica pe date): aplicate,
ar fi trebuit corectate si in fcurve-urile de pozitie ale oaselor, si orice
scapare acolo inseamna copite care patineaza. Nodul TRS din GLB e gratis.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_cow_animated.py
"""

import bpy
from mathutils import Vector

PACK = (r"D:\GameDev\downloaded assets"
        r"\Ultimate Animated Animals - July 2021-20260813T155229Z-1-001"
        r"\Ultimate Animated Animals - July 2021\glTF\Cow.gltf")

TARGET_LENGTH = 2.6   # m, bot-coada; vaca veche masura 2.9 si citea usor mare
KEEP_ACTIONS = ("Idle", "Eating", "Walk", "Gallop")

# Culorile sursei, traduse in sloturi (masurate din baseColorFactor):
#   Main       #865D2E maro blana    -> WOOD (#835C34, aproape identic)
#   Main_Light #B8A993 bej pete      -> CORAL_SAND (crem)
#   Hooves     #745931 copite        -> ROCK_DARK
#   Muzzle     #AF7550 bot roz-maro  -> TILE_TERRACOTTA (#C4784F)
#   Eye_Black/Eye_White              -> ASPHALT / FOAM_WHITE
#   Horns      #ACA174 corn          -> SAND_LIGHT (cornitele vacii vechi)
SLOT_BY_MAT = {
    "Main": WOOD,
    "Main_Light": CORAL_SAND,
    "Hooves": ROCK_DARK,
    "Muzzle": TILE_TERRACOTTA,
    "Eye_Black": ASPHALT,
    "Eye_White": FOAM_WHITE,
    "Horns": SAND_LIGHT,
}

AO_FLOOR = 0.78  # burta; 1.0 pe spinare — bland, sa nu murdareasca blana


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


def build():
    # Curatenie totala: scriptul e singurul stapan al scenei la rulare headless.
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)

    bpy.ops.import_scene.gltf(filepath=PACK)

    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    assert len(arms) == 1, "asteptam 1 armatura, am gasit %r" % [a.name for a in arms]
    arm = arms[0]
    # Fisierul sursa are si un Icosphere orfan (gunoi de autor, 42 de vertecsi,
    # fara material) — pastram doar mesh-ul skinnuit pe armatura.
    skinned = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm]
    assert len(skinned) == 1, "asteptam 1 mesh skinnuit: %r" % [o.name for o in skinned]
    mesh = skinned[0]
    for o in [o for o in bpy.data.objects if o.type == "MESH" and o is not mesh]:
        print("arunc obiectul strain din sursa:", o.name)
        bpy.data.objects.remove(o, do_unlink=True)
    arm.name, mesh.name = "Cow", "CowMesh"

    # -- Animatii: doar cele patru; restul (Death, Attack_*, ...) nu au rost
    # pe acostament si ar ingrasa GLB-ul degeaba.
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

    # NLA stash: exportatorul glTF ('ACTIONS') exporta actiunea activa plus
    # strip-urile stashuite — fara asta ar pleca doar una singura.
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = None
    for name in KEEP_ACTIONS:
        act = bpy.data.actions[name]
        track = arm.animation_data.nla_tracks.new()
        track.name = name
        track.mute = True
        track.strips.new(name, int(act.frame_range[0]), act)

    # -- Orientare + scara, pe NODUL armaturii (vezi antet). Intai masuram in
    # poza de repaus, cu transformul de import inca pe nod.
    lo, hi = _world_bbox([mesh])
    size = hi - lo
    length_axis = "Y" if size.y >= size.x else "X"
    length = getattr(size, length_axis.lower())
    print("bbox import: %.2f x %.2f x %.2f m, lungimea pe %s"
          % (size.x, size.y, size.z, length_axis))

    if length_axis == "X":
        # lungimea pe X -> intoarcem 90 de grade sa cada pe Y
        arm.rotation_euler.rotate_axis("Z", 1.5707963)
    # Incotro e capul: geometria de deasupra a 70% din inaltime (cap + gat).
    deps = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(deps)
    zs = [(mesh.matrix_world @ v.co) for v in ev.data.vertices]
    z_top = lo.z + size.z * 0.7
    head = [w for w in zs if w.z > z_top]
    assert head, "niciun vertex peste 70%% din inaltime — euristica de cap orbecaie"
    head_y = sum(w.y for w in head) / len(head)
    mid_y = (lo.y + hi.y) * 0.5
    if head_y < mid_y:
        arm.rotation_euler.rotate_axis("Z", 3.1415926)
        print("capul era spre -Y, am intors vaca")

    arm.scale *= TARGET_LENGTH / length
    bpy.context.view_layer.update()

    # Origine la baza: mutam nodul armaturii pana cand talpa e la z=0, centrat XY.
    lo, hi = _world_bbox([mesh])
    center = (lo + hi) * 0.5
    arm.location -= Vector((center.x, center.y, lo.z))
    bpy.context.view_layer.update()

    # -- UV-uri pe sloturi, per materialul sursa al fiecarei fete.
    me = mesh.data
    slot_of_index = {}
    for i, mat in enumerate(me.materials):
        base = mat.name.split(".")[0]
        assert base in SLOT_BY_MAT, "material sursa nemapat: %s" % mat.name
        slot_of_index[i] = SLOT_BY_MAT[base]
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        u = slot_u(slot_of_index[poly.material_index])
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)

    # -- AO: gradient vertical pe poza de repaus (vezi antet, punctul 2).
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

    # -- Un singur material: atlasul comun (inlocuit oricum la instantiere).
    me.materials.clear()
    me.materials.append(atlas_material())
    apply_smooth(mesh, 55.0)

    print("tris:", tri_count(mesh), "| animatii:", ", ".join(KEEP_ACTIONS),
          "| taiate:", ", ".join(dropped))
    lo, hi = _world_bbox([mesh])
    print("gabarit final: %.2f x %.2f x %.2f m (X lat, Y lung, Z inalt)"
          % (hi.x - lo.x, hi.y - lo.y, hi.z - lo.z))
    return arm, mesh


def export_animated(objects, filename):
    """export_glb din dio_lib, plus armatura: animatii ca actiuni separate,
    skinning pastrat. Ramane aici pana mai apare un al doilea asset animat."""
    import os
    path = os.path.join(MODELS, filename)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_texcoords=True,
        export_vertex_color="ACTIVE",
        export_materials="EXPORT",
        export_image_format="NONE",
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_cameras=False,
        export_lights=False,
        export_extras=False,
    )
    return path, os.path.getsize(path)


arm, mesh = build()
path, size = export_animated([arm, mesh], "props/cow.glb")
print("export: %s (%.0f KB)" % (path, size / 1024))
# save_blend, dar comprimat: fcurve-urile celor 4 animatii pe 42 de oase fac
# 11 MB necomprimat — de 10x peste orice alta sursa din assets/blender.
import os as _os
_blend = _os.path.join(BLENDS, "cow.blend")
bpy.data.libraries.write(_blend, {arm, mesh}, fake_user=True, compress=True)
print("sursa:  %s (%.0f KB)" % (_blend, _os.path.getsize(_blend) / 1024))
