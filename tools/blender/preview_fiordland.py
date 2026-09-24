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
#
# Revizuire coordonator (wave 1 review): "guard_rock intersects the
# reference box" si "I can't see chasm_rock at all" — pasul de 4.0 m de la
# prima versiune era mai mic decat piesele insesi (chasm_rock e 6 m lat),
# deci se suprapuneau, iar cutia de referinta unica (langa PRIMA piesa) cadea
# peste guard_rock. `sheet()` a fost rescris sa puna cate o cutie de
# referinta LANGA FIECARE piesa (nu una singura pentru tot randul) si sa
# calculeze pasul din latimea REALA a piesei + latimea cutiei, cu marja.
GROUPS = {
    "rocks": ("rocks", ["stirling_ledge", "torrent_chute", "chasm_rock",
                        "guard_rock", "scree_slab"], 14.0),
    "rocks_small": ("rocks", ["chasm_rock", "guard_rock", "scree_slab"], 3.0),
    # padurea (val 2, brief §1.4): fagii au randul lor dedicat (beech_sheet,
    # mai jos, cu marcaj de inaltime om), aici doar restul valului.
    "forest": ("plants", ["beech_dead", "rata_tree", "tussock_clump"], 4.0),
    "forest_props": ("props", ["stump", "driftwood"], 2.5),
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
          res=(1600, 720), place_car=True, margin=1.25):
    # azimuth implicit spre 148 grade (nu 32): stirling_ledge are fata utila
    # spre -X (brief: "fata peretelui e planul X=0"), deci o camera care
    # priveste dinspre +X cade in spatele/interiorul masei de 10 m si
    # randeaza fix partea care nu conteaza. Vezi acelasi bug rezolvat in
    # `stirling_elevation_sheet`.
    #
    # Revizuire coordonator (wave 1 review): fiecare piesa isi primeste ACUM
    # propria cutie de referinta, asezata LANGA ea (nu in fata primei piese
    # din rand), iar pasul dintre piese se calculeaza din latimea REALA
    # (dimensions.y, lungimea pe Blender Y — axa pe care se insira piesele)
    # plus latimea cutiei plus o marja — nu un `step` fix care putea fi mai
    # mic decat piesa (chasm_rock 6 m lat, pas vechi 4 m -> se suprapuneau).
    models_dir = models_dir or MODELS
    category, names, step = GROUPS[group]
    _clear()
    built = []
    y = 0.0
    for n in names:
        objs = _import(category, n, models_dir)
        if not objs:
            print("LIPSA:", n)
            continue
        roots = [o for o in objs if o.parent is None]
        meshes = [o for o in objs if o.type == "MESH"]
        if not meshes:
            continue
        # latimea reala a piesei pe axa de insirare (Blender Y — lungimea ei
        # "de-a lungul drumului"), luata DIN GEOMETRIE, nu presupusa
        span_y = max(max(o.dimensions.y for o in meshes), 0.5)
        half = span_y * 0.5
        for o in roots:
            o.location.y += y + half
        bpy.context.view_layer.update()
        piece_center_y = y + half
        y += span_y + max(step, 2.0)
        built += meshes

        if place_car:
            car = _make_ref_car()
            # cutia sta LANGA piesa (pe X, in afara ei), nu peste ea si nu
            # in fata primei piese din rand — fiecare piesa isi are reperul.
            # X-ul cutiei: jumatate din latimea piesei (dimensions.x) plus
            # jumatate din latimea cutiei plus o marja, ca sa nu se atinga.
            piece_span_x = max(max(o.dimensions.x for o in meshes), 0.5)
            car.location = (-(piece_span_x * 0.5 + REF_CAR[1] * 0.5 + 1.5),
                            piece_center_y, 0.0)
            built.append(car)

    if not built:
        print("plansa", group, "SARITA (niciun GLB exportat inca)")
        return []

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
    shot(built, path, azimuth=azimuth, elevation=elevation, res=res, margin=margin)
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


def _make_person(x, y):
    """Marcaj de inaltime om: 1.75 m, cilindru simplu albastru, la (x,y),
    baza pe sol. Reper de scara langa fagi — brief §0.8/§1.4 cere sa se poata
    judeca golul dintre etaje, iar cutia de masina (1.5 m inalt) nu da acelasi
    reper vertical ca o siluetă umana."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=8,
                          radius1=0.24, radius2=0.20, depth=1.75)
    me = bpy.data.meshes.new("PersonMarker")
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new("PersonMarker", me)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, y, 0.875)
    bpy.context.view_layer.update()
    mat = obj.matrix_world.copy()
    for v in obj.data.vertices:
        v.co = mat @ v.co
    obj.matrix_world.identity()
    mp = bpy.data.materials.get("PersonBlue")
    if mp is None:
        mp = bpy.data.materials.new("PersonBlue")
        mp.use_nodes = True
        bsdf = mp.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (0.15, 0.35, 0.95, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.6
    obj.data.materials.clear()
    obj.data.materials.append(mp)
    return obj


def beech_sheet(path, models_dir=None, res=(1900, 900)):
    """Fagii (a/b/c) unul langa altul, vedere LATERALA (nu 3/4): brief §1.4
    cere sa se judece SILUETA — goluri intre etaje, nu bila plina. O vedere
    de profil pura ar aplatiza umbrirea, deci elevatia ramane joasa (10°) ca
    sa cada lumina rasant si sa scoata treptele coroanei.

    Fiecare fag isi are cutia de referinta (4x1.8x1.5) si un marcaj de om
    (1.75 m) LANGA el, nu suprapuse peste coroana — ca sa nu ascunda golurile
    pe care exact planta asta trebuie sa le arate.
    """
    models_dir = models_dir or MODELS
    _clear()
    built = []
    y = 0.0
    names = ["beech_a", "beech_b", "beech_c"]
    for n in names:
        objs = _import("plants", n, models_dir)
        if not objs:
            print("LIPSA:", n)
            continue
        roots = [o for o in objs if o.parent is None]
        meshes = [o for o in objs if o.type == "MESH"]
        if not meshes:
            continue
        span_y = max(max(o.dimensions.y for o in meshes), 2.0)
        half = span_y * 0.5
        for o in roots:
            o.location.y += y + half
        bpy.context.view_layer.update()
        piece_center_y = y + half
        y += span_y + 5.0
        built += meshes

        car = _make_ref_car()
        piece_span_x = max(max(o.dimensions.x for o in meshes), 0.5)
        car.location = (-(piece_span_x * 0.5 + REF_CAR[1] * 0.5 + 1.2),
                        piece_center_y - 1.0, 0.0)
        built.append(car)
        person = _make_person(piece_span_x * 0.5 + 1.0, piece_center_y - 1.0)
        built.append(person)

    if not built:
        print("plansa beech SARITA (niciun GLB exportat inca)")
        return []

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
    # Piesele sunt insirate pe Y (randul). Camera trebuie sa priveasca DE-A
    # LUNGUL LUI X (azimut ~0), nu de-a lungul lui Y — un azimut aproape de
    # 90 (cum era prima versiune) se uita PE randul de fagi si ii suprapune
    # pe toti intr-o singura silueta stivuita (bug gasit chiar in aceasta
    # planta: cei 3 fagi ieseau ca un singur "pagodon"). azimuth=8 (aproape
    # de profil pur, dar cu un pic de unghi ca lumina sa cada oblic pe
    # etaje) e vederea LATERALA reala.
    shot(built, path, azimuth=8.0, elevation=10.0, res=res, margin=1.15)

    # A DOUA vedere (cerinta coordonator, val 2): unghiul CAMEREI DE JOC —
    # chase cam la 10 m sus, priveste in jos la ~29° (memoria
    # `verifica-cu-parametrii-lui`: un ochi la 2,6 m da verdict fals, camera
    # reala e sus si inclinata). `elevation` in `shot()` e unghiul camerei
    # DEASUPRA orizontului tintei — 29° reproduce exact panta de privire a
    # chase cam-ului, nu doar "o vedere de sus oarecare".
    base, ext = os.path.splitext(path)
    shot(built, base + "_chasecam" + ext, azimuth=8.0, elevation=29.0,
        res=res, margin=1.15)
    return [(o.name, len(o.data.polygons)) for o in built]


def rata_sheet(path, models_dir=None, res=(1300, 1100)):
    """rata_tree singur — vedere laterala + chase cam, cu cutia de referinta
    si marcajul de om alaturi. Cerinta coordonator (a doua revizuire): rata
    trebuie verificata izolat, nu doar in planul comun cu restul padurii,
    ca sa se vada clar daca mai citeste ca acacie (silueta interzisa) sau
    ca tufa rotunjita."""
    models_dir = models_dir or MODELS
    _clear()
    objs = _import("plants", "rata_tree", models_dir)
    if not objs:
        print("LIPSA: rata_tree")
        return []
    meshes = [o for o in objs if o.type == "MESH"]
    car = _make_ref_car()
    span_x = max(max(o.dimensions.x for o in meshes), 0.5)
    car.location = (-(span_x * 0.5 + REF_CAR[1] * 0.5 + 1.2), -1.0, 0.0)
    person = _make_person(span_x * 0.5 + 1.0, -1.0)
    built = meshes + [car, person]
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
    shot(built, path, azimuth=15.0, elevation=10.0, res=res, margin=1.2)
    base, ext = os.path.splitext(path)
    # chase cam: aceeasi conventie ca la fag (elevation=29, unghiul camerei
    # de joc) — cerinta explicita a coordonatorului, "chase-cam view of
    # rata alone"
    shot(built, base + "_chasecam" + ext, azimuth=15.0, elevation=29.0,
        res=res, margin=1.2)
    return [(o.name, len(o.data.polygons)) for o in built]


def bridge_rail_sheet(path, models_dir=None, res=(1700, 700)):
    """chasm_bridge_rail: doua noduri (Rail_L/Rail_R) la X=+-5.8, langa
    cutia de referinta asezata PE tablia imaginara (Y=0), ca sa se vada
    ecartamentul fata de masina."""
    models_dir = models_dir or MODELS
    _clear()
    objs = _import("structures", "chasm_bridge_rail", models_dir)
    if not objs:
        print("LIPSA: chasm_bridge_rail")
        return []
    meshes = [o for o in objs if o.type == "MESH"]
    car = _make_ref_car()
    car.location = (0.0, 0.0, 0.0)
    built = meshes + [car]
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
    shot(built, path, azimuth=25.0, elevation=16.0, res=res, margin=1.2)
    return [(o.name, len(o.data.polygons)) for o in built]


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)
for g in GROUPS:
    if g == "rocks_small":
        # elevatie mica (7 grade, nu 13): la elevatia standard camera vede
        # mai ales fata de SUS a placilor (scree_slab e SAND_SHADOW, cam
        # aceeasi valoare ca podeaua de nisip din preview — se camufla). O
        # elevatie joasa aduce mai mult din fetele LATERALE (GNEISS,
        # distincte de nisip) in cadru. `margin` mai mic incadreaza mai
        # aproape — coordonator: "frame the small pieces closer".
        print("plansa", g, sheet(g, os.path.join(OUT, "fiordland_%s.png" % g),
                                 elevation=7.0, res=(1600, 800), margin=1.05))
    else:
        print("plansa", g, sheet(g, os.path.join(OUT, "fiordland_%s.png" % g)))
stirling_elevation_sheet(os.path.join(OUT, "fiordland_stirling.png"))
print("plansa beech", beech_sheet(os.path.join(OUT, "fiordland_beech.png")))
print("plansa rata", rata_sheet(os.path.join(OUT, "fiordland_rata.png")))
print("plansa bridge_rail", bridge_rail_sheet(
    os.path.join(OUT, "fiordland_bridge_rail.png")))
