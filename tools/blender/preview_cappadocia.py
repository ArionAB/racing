"""Plansa de control pentru kitul Cappadocia — randata DIN GLB-urile exportate.

Ca `preview_chongqing.py`: importa fisierele, nu reconstruieste piesele. Asa
verifica ce a ajuns efectiv in GLB (origine, orientare, AO, sloturi), nu ce
credem ca am construit.

Doua capcane, ambele platite deja:
  - cubul implicit de 2 m din `--factory-startup` intra in cadru si arata ca o
    "fata alba" pe orice piesa mica (memoria `blender-preview-cub-implicit`);
    de-aia `hide_render` pe tot ce nu e in lista.
  - `hollow_rock` e goala pe dinauntru si tocmai interiorul conteaza (pe el se
    conduce). O randare din exterior arata un con si nimic altceva, deci pentru
    ea exista `--cut`: jumatatea dinspre camera se ascunde cu un boolean de
    preview, ca sa se vada spirala. E doar pentru CADRU; GLB-ul ramane intreg.

Rulare (prin MCP sau run_build), cu grupul ca argument in `GROUP`:
    exec(open(P + "/preview_cappadocia.py").read(), g)
    sheet("tuff", OUT + "/cap_tuff.png")
"""

import bpy
import math
import os

GROUPS = {
    "tuff": ("rocks", ["chimney_a", "chimney_b", "chimney_c", "chimney_d",
                       "chimney_mushroom", "chimney_triple",
                       "cliff_band_module", "rock_church_facade"], 11.0),
    "hero": ("structures", ["twin_chimney_gate", "cave_entrance",
                            "vent_shaft"], 22.0),
    "hollow": ("structures", ["hollow_rock"], 0.0),
    "hall": ("structures", ["hall_column", "hall_arch", "hall_ceiling_module",
                            "hall_alcove", "church_arch", "millstone_slot",
                            "millstone_door"], 7.0),
    "balloon": ("props", ["balloon_envelope_a", "balloon_envelope_b",
                          "balloon_envelope_c", "balloon_basket",
                          "balloon_landed", "balloon_tether"], 14.0),
    "chimney_states": ("rocks", ["cracked_chimney_a", "cracked_chimney_b",
                                 "cracked_chimney_c"], 18.0),
    "village": ("buildings", ["cave_house_a", "cave_house_b", "cave_house_c",
                              "dovecote", "farmhouse"], 12.0),
    "props": ("props", ["torch", "pottery_cart", "pot_stack", "carpet_terrace",
                        "chevron_post"], 4.5),
    "veg": ("plants", ["poplar_a", "poplar_b", "vine_row", "shrub_dry",
                       "pigeon"], 5.0),
    "background": ("rocks", ["uchisar_castle", "erciyes", "balloon_far"], 90.0),
}


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    path = os.path.join(models_dir, "cappadocia", category, name + ".glb")
    if not os.path.exists(path):
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.selected_objects if o.type == "MESH"]


def _cut_half(obj):
    """Taie jumatatea dinspre camera cu un boolean, ca sa se vada interiorul.

    Doar pentru randare. Se aplica pe o COPIE a mesh-ului (obj.data e deja
    proaspat importat), deci nu atinge GLB-ul de pe disc.
    """
    dims = obj.dimensions
    cutter_mesh = bpy.data.meshes.new("PreviewCutter")
    bm_mod = obj.modifiers.new("PreviewCut", "BOOLEAN")
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(cutter_mesh)
    bm.free()
    cutter = bpy.data.objects.new("PreviewCutter", cutter_mesh)
    bpy.context.collection.objects.link(cutter)
    s = max(dims) * 1.6
    cutter.scale = (s, s * 0.5, s)
    # jumatatea dinspre camera (azimut implicit vine din -Y +X); taiem -Y
    cutter.location = (obj.location.x, obj.location.y - s * 0.25,
                       obj.location.z + dims.z * 0.5)
    cutter.hide_render = True
    bm_mod.object = cutter
    bm_mod.operation = "DIFFERENCE"
    return cutter


def sheet(group, path, models_dir=None, azimuth=32.0, elevation=13.0,
          res=(1600, 720), cut=False, driver=False):
    models_dir = models_dir or MODELS
    category, names, step = GROUPS[group]
    _clear()
    built, x = [], 0.0
    for n in names:
        objs = _import(category, n, models_dir)
        if not objs:
            print("LIPSA:", n)
            continue
        for o in objs:
            o.location.x += x
        # pasul se ia din latimea reala a piesei, nu dintr-o constanta: altfel
        # `cliff_band_module` (20 m) intra peste hornurile de 4 m
        bpy.context.view_layer.update()
        w = max(max(o.dimensions.x for o in objs), 1.0)
        x += max(step, w * 1.25)
        built += objs
    if cut:
        for o in built:
            _cut_half(o)
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    shot(built, path, azimuth=azimuth, elevation=elevation, res=res,
         driver=driver)
    return [(o.name, len(o.data.polygons)) for o in built]
