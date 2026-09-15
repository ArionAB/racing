"""Plansa de control pentru kitul Machu Picchu — randata DIN GLB-urile exportate.

Ca `preview_serengeti.py`: importa fisierele, nu reconstruieste piesele, deci
verifica ce a ajuns in GLB (origine, orientare, AO, sloturi). Cubul implicit si
tot ce nu e in lista primesc `hide_render` (memoria
`blender-preview-cub-implicit`).

Piesele inca neexportate se raporteaza cu "LIPSA:" si se sare peste — plansa se
randeaza cu ce exista, fiindca kitul se construieste in patru valuri.

Rulare (headless, toate grupurile):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_machupicchu.py
Plansele ies in docs/asset_briefs/img/machupicchu_<grup>.png.
"""

import bpy
import os

# (categorie, piese, step). `step` e distanta minima intre piese pe rand: pe
# fundal e mare fiindca peretele defileului are 200 m si muntele 150 m baza.
GROUPS = {
    "hero": ("", ["rocks/huayna_picchu", "structures/inti_punku",
                  "structures/main_gate", "structures/inca_bridge_ledge"], 40.0),
    "sacred": ("structures", ["sun_temple", "intihuatana", "three_windows"], 12.0),
    "citadel": ("structures", ["inca_wall_a", "inca_wall_b", "inca_wall_c",
                               "inca_stair_a", "inca_stair_b", "fountain_basin",
                               "water_channel", "trail_marker", "rope_rail"], 7.0),
    "buildings": ("buildings", ["inca_house_a", "inca_house_b", "guardhouse"], 9.0),
    "forest": ("plants", ["polylepis_a", "polylepis_b", "tree_fern", "bromeliad",
                          "orchid_cluster", "bamboo_clump"], 6.0),
    "rocks": ("rocks", ["moss_boulder_a", "moss_boulder_b", "moss_boulder_c"], 5.0),
    "camp": ("props", ["tent_a", "tent_b", "backpack_pile"], 3.0),
    "animals": ("animals", ["llama", "llama_b", "llama_c", "condor"], 2.5),
    "vehicles": ("vehicles", ["consettur_bus", "perurail_train"], 12.0),
    "background": ("rocks", ["gorge_far_wall", "machu_picchu_mountain"], 220.0),
}


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    # Grupul `hero` isi poarta categoria in numele piesei (piesele lui stau in
    # foldere diferite), deci `category` poate fi gol.
    rel = name if not category else os.path.join(category, name)
    path = os.path.join(models_dir, "machupicchu", rel + ".glb")
    if not os.path.exists(path):
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.selected_objects if o.type in ("MESH", "ARMATURE")]


def sheet(group, path, models_dir=None, azimuth=32.0, elevation=13.0, res=(1600, 720)):
    models_dir = models_dir or MODELS
    category, names, step = GROUPS[group]
    _clear()
    built, x = [], 0.0
    for n in names:
        objs = _import(category, n, models_dir)
        if not objs:
            print("LIPSA:", n)
            continue
        roots = [o for o in objs if o.parent is None]
        for o in roots:
            o.location.x += x
        bpy.context.view_layer.update()
        meshes = [o for o in objs if o.type == "MESH"]
        if not meshes:
            continue
        w = max(max(o.dimensions.x for o in meshes), 1.0)
        x += max(step, w * 1.25)
        built += meshes
    if not built:
        print("plansa", group, "SARITA (niciun GLB exportat inca)")
        return []
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    # `shot` refoloseste PreviewCam daca exista: o cream noi, cu clip_end de
    # 5 km — cu cei 100 m impliciti plansa de fundal (peretele defileului la
    # 200 m, muntele la 150+) ar iesi goala.
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 5000.0
    cam.data.clip_start = 0.5
    shot(built, path, azimuth=azimuth, elevation=elevation, res=res)
    return [(o.name, len(o.data.polygons)) for o in built]


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)
for g in GROUPS:
    print("plansa", g, sheet(g, os.path.join(OUT, "machupicchu_%s.png" % g)))
