"""Plansa de control pentru kitul Fiordland — randata DIN GLB-urile exportate.

Ca `preview_machupicchu.py`: importa fisierele, nu reconstruieste piesele,
deci verifica ce a ajuns in GLB (origine, orientare, AO, sloturi). Cubul
implicit si tot ce nu e in lista primesc `hide_render` (memoria
`blender-preview-cub-implicit`).

FIECARE plansa are in cadru o cutie de referinta 4.0 x 1.8 x 1.5 m (masina),
brief §0.8: planul ChatGPT a aratat cat de usor scapa scara pe piesele astea.
Cutia sta pe teren la (0,0,0) langa lot, DOAR pentru grupele care nu au deja
propriul asezaj explicit (stirling_ledge o pune pe Shelf).

Piesele inca neexportate se raporteaza cu "LIPSA:" si se sare peste — kitul
se construieste in valuri (brief §3). La scrierea asta doar valul 1
(stancile-hero) exista.

Rulare (headless, toate grupurile):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_fiordland.py
Plansele ies in docs/asset_briefs/img/fiordland_<grup>.png.
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector

# (categorie, piese, step). `step` e distanta minima intre piese pe rand.
#
# stirling_ledge (40 m lung) si torrent_chute (24 m) domina orice rand in
# care intra impreuna cu piesele mici (0.6-6 m) — cadrul se retrage sa
# incapa totul si bolovanii mici ajung cateva zeci de pixeli. Doua randuri
# separate, ca la `preview_machupicchu.py` (hero/small).
GROUPS = {
    "rocks": ("rocks", ["stirling_ledge", "torrent_chute", "chasm_rock",
                        "guard_rock", "scree_slab"], 14.0),
    "rocks_small": ("rocks", ["chasm_rock", "guard_rock", "scree_slab"], 4.0),
}

REF_CAR = (4.0, 1.8, 1.5)  # lungime (Y Blender) x latime (X) x inaltime (Z)


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    rel = name if not category else os.path.join(category, name)
    path = os.path.join(models_dir, "fiordland", rel + ".glb")
    if not os.path.exists(path):
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.selected_objects if o.type in ("MESH", "ARMATURE")]


def _make_ref_car(name="RefCar"):
    """Cutie de referinta 4.0 x 1.8 x 1.5 m (lungime/latime/inaltime),
    originea la baza, centrata pe latime — exact cum sta o masina pe drum.
    E DELIBERAT o cutie simpla (brief: 'reference_car' nu se genereaza, e doar
    scara de pe planta) — un galben aprins ca sa nu se confunde cu stanca."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    obj.scale = (REF_CAR[0], REF_CAR[1], REF_CAR[2])
    obj.location = (0.0, 0.0, REF_CAR[2] * 0.5)
    bpy.context.view_layer.update()
    # aplica scara/pozitia in geometrie ca bound_box-ul din shot() sa fie corect
    mat = obj.matrix_world.copy()
    for v in obj.data.vertices:
        v.co = mat @ v.co
    obj.matrix_world.identity()

    mcar = bpy.data.materials.get("RefCarYellow")
    if mcar is None:
        mcar = bpy.data.materials.new("RefCarYellow")
        mcar.use_nodes = True
        bsdf = mcar.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (1.0, 0.82, 0.05, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.5
    obj.data.materials.clear()
    obj.data.materials.append(mcar)
    return obj


def sheet(group, path, models_dir=None, azimuth=180.0 - 32.0, elevation=13.0,
          res=(1600, 720), place_car=True):
    # azimuth implicit spre 148 grade (nu 32): stirling_ledge are fata utila
    # spre -X (brief: "fata peretelui e planul X=0"), deci o camera care
    # priveste dinspre +X cade in spatele/interiorul masei de 10 m si
    # randeaza fix partea care nu conteaza. Vezi acelasi bug rezolvat in
    # `stirling_elevation_sheet`.
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

    if place_car:
        car = _make_ref_car()
        # cutia sta langa PRIMA piesa a lotului (originea, X=0), nu in
        # centrul intregului rand — altfel pe un rand de 5 stanci dispare
        # intre ele si nu mai serveste ca reper de scara
        car.location.x = -3.5
        built.append(car)

    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1
    shot(built, path, azimuth=azimuth, elevation=elevation, res=res)
    return [(o.name, len(o.data.polygons)) for o in built]


def stirling_elevation_sheet(path, res=(1600, 900)):
    """Vedere de profil (camera priveste de-a lungul Y) a stirling_ledge, cu
    cutia de referinta STAND PE Shelf, sub surplomb — exact scenariul din
    brief: 'o masina pe suspensie... nu trebuie sa taie roca'. Include si un
    reper orizontal la +14 m (marcaj galben) si o vedere 3/4.
    """
    _clear()
    objs = _import("rocks", "stirling_ledge", MODELS)
    if not objs:
        print("LIPSA: stirling_ledge (profil)")
        return

    # cutia de referinta pe Shelf: centrata pe latimea lui (X in [0,3]),
    # undeva de-a lungul nisei (Y=0), fata din spate lipita de Wall
    car = _make_ref_car()
    car.location = (1.5, 0.0, 0.0)
    bpy.context.view_layer.update()

    # marcaj orizontal la Z=+14.0 m: o bara subtire galbena care se intinde
    # peste toata latimea surplombului, la cota exacta a buzei — se vede daca
    # coincide cu muchia inferioara a Overhang-ului
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    me = bpy.data.meshes.new("LipMarker")
    bm.to_mesh(me)
    bm.free()
    marker = bpy.data.objects.new("LipMarker", me)
    bpy.context.collection.objects.link(marker)
    marker.scale = (9.5, 0.15, 0.15)
    marker.location = (-4.5, 0.0, 14.0)
    bpy.context.view_layer.update()
    mat = marker.matrix_world.copy()
    for v in marker.data.vertices:
        v.co = mat @ v.co
    marker.matrix_world.identity()
    mmark = bpy.data.materials.get("LipMarkerRed")
    if mmark is None:
        mmark = bpy.data.materials.new("LipMarkerRed")
        mmark.use_nodes = True
        bsdf = mmark.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (1.0, 0.05, 0.05, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.3
    marker.data.materials.clear()
    marker.data.materials.append(mmark)

    built = [o for o in objs if o.type == "MESH"] + [car, marker]
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")

    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1
    bpy.context.scene.camera = cam

    base, ext = os.path.splitext(path)

    # --- vedere de profil (sectiune X-Z) ---
    # `shot()` incadreaza dupa bbox-ul TUTUROR obiectelor date, iar Wall are
    # 40 m lungime pe Y — o dimensiune irelevanta pentru o camera care
    # priveste DE-A LUNGUL lui Y, dar pe care formula generica o baga in
    # calculul de distanta oricum, deci camera se retragea mult prea departe
    # si nisa/surplombul ieseau niste dungi subtiri (asta a iesit prima data).
    # Aici camera se pozitioneaza manual, incadrand doar planul X-Z (10 m
    # adancime x 32 m inaltime), care e ce se vede REAL de-a lungul lui Y.
    # O vedere de profil PURA (azimuth=90 exact) da o silueta plata: adancimea
    # nisei nu se citeste din umbrire, doar din contur — si conturul, la
    # rezolutia asta, se pierde intr-o linie. Un azimut mic (12 grade) tine
    # cititul de "profil" (X-Z domina cadrul) dar lasa lumina sa cada oblic pe
    # fata nisei, deci adancimea de 4 m se vede din UMBRA, nu doar din contur.
    center = Vector((0.5, 0.0, 16.0))
    cam.data.lens = 32.0
    sensor = cam.data.sensor_width
    hfov = 2.0 * math.atan(sensor / (2.0 * cam.data.lens))
    aspect = res[0] / float(res[1])
    vfov = 2.0 * math.atan(math.tan(hfov / 2.0) / aspect)
    half_w, half_h = 11.5, 17.0  # X: -10.5..1 (perete+surplomb), Z: 0..32
    dist = 1.15 * max(half_w / math.tan(hfov / 2.0), half_h / math.tan(vfov / 2.0))
    # azimuth aproape de 180 grade: camera sta spre -X (partea drumului),
    # privind spre +X (spre masa peretelui). Cu un azimut spre 0 grade,
    # camera cade IN interiorul masei de stanca (X 0..10.5) si randeaza
    # negru/gol din interior — exact ce a iesit prima data.
    a = math.radians(180.0 - 12.0)
    cam.location = center + Vector((math.cos(a), math.sin(a), 0.0)) * dist
    look = (center - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    _light(bpy.context.scene)
    _world(bpy.context.scene)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT" if hasattr(
        bpy.types, "RenderEngineEeveeNext") or "BLENDER_EEVEE_NEXT" in [
        e.identifier for e in
        bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    ] else "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.filepath = base + "_profile" + ext
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    print("profil salvat:", scene.render.filepath)

    # --- vedere 3/4 ---
    # Acelasi motiv ca la profil: `shot()` auto-fit ar incadra toti cei 40 m
    # de perete si ar face surplombul un detaliu minuscul. Camera se
    # pozitioneaza manual, centrata pe portiunea cu nisa (Y in jur de 0),
    # nu pe tot ansamblul.
    center3q = Vector((-1.0, 0.0, 14.0))
    cam.data.lens = 30.0
    hfov = 2.0 * math.atan(sensor / (2.0 * cam.data.lens))
    vfov = 2.0 * math.atan(math.tan(hfov / 2.0) / aspect)
    half_w3, half_h3 = 20.0, 19.0
    dist3 = 1.05 * max(half_w3 / math.tan(hfov / 2.0), half_h3 / math.tan(vfov / 2.0))
    # acelasi motiv ca la profil: azimutul trebuie sa puna camera spre -X
    # (partea drumului), nu spre interiorul masei de stanca.
    a = math.radians(180.0 - 38.0)
    e = math.radians(16.0)
    cam.location = center3q + Vector(
        (math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * dist3
    look3 = (center3q - cam.location).normalized()
    cam.rotation_euler = look3.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = base + "_3q" + ext
    bpy.ops.render.render(write_still=True)
    print("3/4 salvat:", scene.render.filepath)


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)
for g in GROUPS:
    print("plansa", g, sheet(g, os.path.join(OUT, "fiordland_%s.png" % g)))
stirling_elevation_sheet(os.path.join(OUT, "fiordland_stirling.png"))
