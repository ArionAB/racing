"""Plansa de control pentru kitul Serengeti — randata DIN GLB-urile exportate.

Ca `preview_cappadocia.py`: importa fisierele, nu reconstruieste piesele, deci
verifica ce a ajuns in GLB (origine, orientare, AO, sloturi). Cubul implicit
si tot ce nu e in lista primesc `hide_render` (memoria
`blender-preview-cub-implicit`).

Rulare (headless, toate grupurile):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_serengeti.py
Planșele ies in docs/asset_briefs/img/serengeti_<grup>.png.
"""

import bpy
import os

GROUPS = {
    "animals": ("animals", ["wildebeest", "zebra", "elephant", "hippo_back", "crocodile"], 4.0),
    "rocks": ("rocks", ["kopje_camp", "lion_kopje", "kopje_kicker", "kopje_boulder_a",
                        "kopje_boulder_b", "kopje_boulder_c", "termite_mound_a",
                        "termite_mound_b", "carcass_vultures"], 8.0),
    "gap": ("rocks", ["crater_gap"], 0.0),
    "plants": ("plants", ["acacia_umbrella_a", "acacia_umbrella_b", "acacia_umbrella_c",
                          "fever_tree", "fig_tree", "euphorbia", "baobab", "dead_tree"], 9.0),
    "birds": ("plants", ["flamingo", "flamingo_wings"], 1.6),
    "camp": ("props", ["safari_tent", "land_rover", "campfire", "safari_balloon_landed",
                       "ankole_horns"], 6.0),
    "boma": ("buildings", ["maasai_boma"], 0.0),
    "background": ("rocks", ["lengai", "crater_far_wall"], 200.0),
}


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    path = os.path.join(models_dir, "serengeti", category, name + ".glb")
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
        w = max(max(o.dimensions.x for o in meshes), 1.0)
        x += max(step, w * 1.25)
        built += meshes
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    # `shot` refoloseste PreviewCam daca exista: o cream noi, cu clip_end de
    # 5 km — cu cei 100 m impliciti planșa de fundal (Lengai, 300 m) iesea goala.
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
    print("plansa", g, sheet(g, os.path.join(OUT, "serengeti_%s.png" % g)))
