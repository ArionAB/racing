"""Plansa de control pentru kitul Ha Long — randata DIN GLB-urile exportate.

Ca `preview_machupicchu.py`: importa fisierele, nu reconstruieste piesele, deci
arata ce a ajuns efectiv in GLB (origine, orientare, AO, sloturi). Cubul
implicit si tot ce nu e in lista primesc `hide_render` (memoria
`blender-preview-cub-implicit`).

Piesele inca neexportate se raporteaza cu "LIPSA:" si se sare peste — plansa se
randeaza cu ce exista, fiindca kitul se construieste in trei valuri
(brief §3).

De ce exista, pe langa `verify_halong.sh`: verificarea numara (triunghiuri,
sloturi, origine) si masoara silueta pe felii, dar nu VEDE. Memoria
`harnasul-de-kit-nu-vede-forma-nici-culoarea`: verify masoara sloturi, plansa
arata silueta, si abia amandoua impreuna spun daca piesa e buna. Pe pista asta
conteaza in mod special la turnuri, unde contractul e o forma, nu o cifra.

Rulare (headless, toate grupurile):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_halong.py
Plansele ies in docs/asset_briefs/img/halong_<grup>.png.
"""

import bpy
import os

# (categorie, piese, step). `step` e distanta minima intre piese pe rand.
GROUPS = {
    # Turnurile au 45-65 m: cu pasul mic s-ar intersecta si silueta — tocmai
    # ce trebuie judecat aici — ar fi ilizibila.
    "karst": ("rocks", ["karst_tower_a", "karst_tower_b", "karst_tower_c"], 45.0),
    "stacks": ("rocks", ["karst_stack_a", "karst_stack_b", "shore_boulder"], 12.0),
    "grotto": ("structures", ["grotto_portal"], 22.0),
    "village": ("", ["buildings/floating_house_a", "buildings/floating_house_b",
                     "structures/fish_farm", "props/net_drying_rack",
                     "structures/stone_quay"], 11.0),
    "boats": ("vehicles", ["fishing_junk", "sampan_a", "basket_boat"], 10.0),
    "road": ("structures", ["coast_parapet", "stone_dike"], 9.0),
    "plants": ("plants", ["karst_ficus_a", "karst_ficus_b", "bamboo_clump",
                          "scrub_tuft"], 7.0),
    "belvedere": ("structures", ["belvedere_pavilion"], 8.0),
    # Macacul are 0,5 m. Pe orice plansa comuna ar iesi cativa pixeli si n-ar
    # putea fi judecat (aceeasi lectie ca grupul `small` de la Machu Picchu).
    "animals": ("animals", ["macaque"], 1.2),
    # Fundalul: 150-320 m latime. Pasul mare si clip_end-ul de 5 km din `sheet`
    # sunt ce face diferenta intre o plansa cu trei siluete si una goala.
    "background": ("rocks", ["karst_horizon_a", "karst_horizon_b",
                             "karst_horizon_c"], 260.0),
}

# Turnurile si fundalul se vad din LATERAL, aproape de orizontala: contractul
# lor e profilul (nisa de val, h/r), iar o camera de sus il turteste exact pe
# axa care conteaza. Restul piesei se judeca in 3/4, ca la celelalte kituri.
LOW_ANGLE = {"karst", "stacks", "grotto", "background"}


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    # Grupul `village` isi poarta categoria in numele piesei (piesele lui stau
    # in foldere diferite), deci `category` poate fi gol.
    rel = name if not category else os.path.join(category, name)
    path = os.path.join(models_dir, "halong", rel + ".glb")
    if not os.path.exists(path):
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.selected_objects if o.type in ("MESH", "ARMATURE")]


def sheet(group, path, models_dir=None, res=(1600, 720)):
    models_dir = models_dir or MODELS
    category, names, step = GROUPS[group]
    elevation = 6.0 if group in LOW_ANGLE else 13.0
    azimuth = 32.0
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
    # clip_end mare: fundalul are 320 m latime si se randeaza de departe.
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 5000.0
    cam.data.clip_start = 0.5
    shot(built, path, azimuth=azimuth, elevation=elevation, res=res)
    return [(o.name, len(o.data.polygons)) for o in built]


# `preview.py` aduce `shot` si `PROJECT`, dar NU si `MODELS` — acela vine din
# `dio_lib.py`. Prin `run_build.py` amandoua ajung oricum in globale, fiindca
# ruleaza cu globale partajate; le incarc explicit ca scriptul sa mearga si daca
# e rulat altfel (memoria `blender-mcp-exec-recipe`).
_HERE = os.path.dirname(os.path.abspath(__file__))
if "MODELS" not in dir():
    exec(compile(open(os.path.join(_HERE, "dio_lib.py")).read(), "dio_lib.py", "exec"))
exec(open(os.path.join(_HERE, "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)
for g in GROUPS:
    print("plansa", g, sheet(g, os.path.join(OUT, "halong_%s.png" % g)))
