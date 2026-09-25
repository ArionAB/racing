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
    # vehiculele (val 3, brief §1.6): coach + plane + boat domina cadrul
    # (7-14 m) fata de caiace (3.6 m) — randuri separate, acelasi motiv ca
    # rocks/rocks_small.
    "vehicles": ("vehicles", ["coach_fiordland", "bush_plane", "cruise_boat"], 10.0),
    # satul (val 4, brief §1.3): wharf (20 m) domina langa piesele mici —
    # randuri separate, acelasi motiv ca rocks/rocks_small.
    "village": ("structures", ["wharf", "heli_pad"], 8.0),
    "village_small": ("props", ["luggage_container", "road_sign_blank",
                                "traffic_light_pole", "snow_pole"], 3.0),
}
# caiacele (props/kayak_a, kayak_b) NU intra in GROUPS/sheet(): revizuire
# coordonator (val 3) — cutia de referinta generica din `sheet()` (asezata la
# jumatate din latimea PIESEI plus jumatate din latimea CUTIEI) cade prea
# aproape de un obiect de doar 0.58 m latime si, din unghiul standard, o
# ACOPERA in perspectiva (masurat pe fiordland_vehicles_small.png: caiacul
# aproape disparea dupa cutie). `kayak_sheet()` mai jos pune cutia clar LANGA
# fiecare caiac, decalata si pe Y (nu doar pe X), ca sa nu se suprapuna din
# nicio combinatie plauzibila de azimut.
# avalansa (val 3, brief §1.5) NU intra in GROUPS/sheet(): tree_avalanche.glb
# e UN SINGUR fisier cu 4 noduri Boulder_A..D, toate exportate la ACELASI
# pivot de lume (0,0,0) — corect pentru contractul de joc (hazardul le
# repozitioneaza pe fiecare in parte, vezi BOULDERS in avalanche_hazard.gd),
# dar `sheet()` le-ar insira ca pe O SINGURA piesa si le-ar suprapune total
# in randare (masurat: primul preview arata un singur bolovan vizibil, restul
# ascunse dedesubt). `avalanche_sheet()` mai jos le desparte manual pe Y
# DOAR pentru planta, fara sa atinga GLB-ul.

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


def avalanche_sheet(path, models_dir=None, res=(1900, 800)):
    """Cele 4 tangle-uri (Boulder_A..D) insirate manual pe Y, fiecare cu
    propria cutie de referinta — GLB-ul le tine pe toate la pivotul de lume
    (0,0,0), contractul corect pentru hazard (fiecare nod e repozitionat
    separat de `_place_shards`), dar gresit pentru o planta care trebuie sa
    le arate pe toate patru distinct."""
    models_dir = models_dir or MODELS
    _clear()
    objs = _import("effects", "tree_avalanche", models_dir)
    if not objs:
        print("LIPSA: tree_avalanche")
        return []
    meshes = {o.name: o for o in objs if o.type == "MESH"}
    order = ["Boulder_A", "Boulder_B", "Boulder_C", "Boulder_D"]
    built = []
    y = 0.0
    step = 3.4
    for name in order:
        o = meshes.get(name)
        if o is None:
            print("LIPSA nod:", name)
            continue
        span_y = max(o.dimensions.y, 0.5)
        half = span_y * 0.5
        o.location.y += y + half
        bpy.context.view_layer.update()
        piece_center_y = y + half
        y += span_y + step
        built.append(o)

        car = _make_ref_car()
        piece_span_x = max(o.dimensions.x, 0.5)
        car.location = (-(piece_span_x * 0.5 + REF_CAR[1] * 0.5 + 1.2),
                        piece_center_y, 0.0)
        built.append(car)

    if not built:
        print("plansa avalanche SARITA (niciun nod gasit)")
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
    shot(built, path, azimuth=20.0, elevation=16.0, res=res, margin=1.2)
    return [(o.name, len(o.data.polygons)) for o in built if o.type == "MESH"]


def animals_sheet(path, models_dir=None, res=(1900, 900)):
    """kea (Idle=stransa + Open=intinsa, doua exemplare langa altul) +
    penguin_tawaki, fiecare cu cutia de referinta si un marcaj de om, ca
    scara si pozele sa se judece direct."""
    models_dir = models_dir or MODELS
    _clear()
    built = []
    x = 0.0

    # kea, doua exemplare: unul in poza Idle (cadrul 0 al NLA "Idle" —
    # aripile stranse), unul in poza Open la ultimul cadru (aripile intinse).
    for pose_name, frame_kind in (("Idle", "start"), ("Open", "end")):
        objs = _import("animals", "kea", models_dir)
        if not objs:
            print("LIPSA: kea")
            break
        arm = next((o for o in objs if o.type == "ARMATURE"), None)
        mesh = next((o for o in objs if o.type == "MESH"), None)
        if arm is None or mesh is None:
            print("LIPSA armatura/mesh in kea.glb")
            continue
        act = bpy.data.actions.get(pose_name)
        if act is not None:
            if arm.animation_data is None:
                arm.animation_data_create()
            for t in list(arm.animation_data.nla_tracks):
                t.mute = True
            arm.animation_data.action = act
            # Blender 5.x (Action layered): asignarea actiunii NU leaga
            # automat slotul cand actiunea are deja un slot dintr-o sesiune
            # anterioara (cazul de aici — actiunea vine din GLB, cu slotul ei
            # propriu) — fara asta poza ramane la bind pose (identitate),
            # masurat direct (memoria din build_fiordland_animals.py).
            if arm.animation_data.action_slot is None and act.slots:
                arm.animation_data.action_slot = act.slots[0]
            frame = act.frame_range[0] if frame_kind == "start" else act.frame_range[1]
            bpy.context.scene.frame_set(int(frame))
        bpy.context.view_layer.update()
        roots = [o for o in objs if o.parent is None]
        span_x = max(mesh.dimensions.x, 0.3)
        for o in roots:
            o.location.x += x + span_x * 0.5
        bpy.context.view_layer.update()
        piece_x = x + span_x * 0.5
        # pas mare intre piese (nu 1.0): animalele sunt 0.5-0.75 m, iar
        # cutia de referinta e 4 m LUNGA — asezata prea aproape (pas vechi de
        # 1.0 m) o cutie ajungea sa acopere tot cadrul si animalul disparea
        # in spatele ei (masurat pe fiordland_animals.png: doar doua cutii
        # galbene vizibile). Pasul intre piese trebuie sa lase loc cutiei
        # PE LATIME (1.8 m), nu doar pe lungime.
        x += span_x + 3.0
        built.append(mesh)

        # Cutia de referinta ramane NEROTITA (lungimea ei de 4 m pe axa Y,
        # ca la toate celelalte plansa) si asezata CLAR in spatele animalului
        # (offset mare pe Y), nu alaturi pe X — la un animal de sub 1 m,
        # orice offset mic pe X tot suprapune cutia peste el in perspectiva.
        car = _make_ref_car()
        car.location = (piece_x, -4.0, 0.0)
        built.append(car)

    x += 1.5
    objs = _import("animals", "penguin_tawaki", models_dir)
    if objs:
        meshes = [o for o in objs if o.type == "MESH"]
        span_x = max(max(o.dimensions.x for o in meshes), 0.3)
        for o in [o for o in objs if o.parent is None]:
            o.location.x += x + span_x * 0.5
        bpy.context.view_layer.update()
        piece_x = x + span_x * 0.5
        built += meshes
        car = _make_ref_car()
        car.location = (piece_x, -4.0, 0.0)
        built.append(car)
    else:
        print("LIPSA: penguin_tawaki")

    if not built:
        print("plansa animals SARITA (niciun GLB exportat inca)")
        return []

    for o in bpy.data.objects:
        if o.type in ("MESH", "ARMATURE"):
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1
    shot(built, path, azimuth=25.0, elevation=14.0, res=res, margin=1.3)
    return [(o.name, len(o.data.polygons)) for o in built if o.type == "MESH"]


def _make_scale_bar(length=0.5, name="ScaleBar"):
    """Bara de scara de 0.5 m: un cilindru subtire orizontal, PE SOL, cu
    doua bilute la capete — reper de scara pentru piese mici (kea, pinguin),
    unde cutia de 4 m de masina domina cadrul si ascunde piesa (revizuire
    coordonator: "animals sheet is unjudgeable", val 4 a doua trecere)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=True, segments=8,
                          radius1=0.025, radius2=0.025, depth=length)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    # cilindrul std e pe Z; il culcam pe Y (orizontal, pe sol)
    obj.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    obj.location = (0.0, 0.0, 0.025)
    bpy.context.view_layer.update()
    mat = obj.matrix_world.copy()
    for v in obj.data.vertices:
        v.co = mat @ v.co
    obj.matrix_world.identity()
    mbar = bpy.data.materials.get("ScaleBarYellow")
    if mbar is None:
        mbar = bpy.data.materials.new("ScaleBarYellow")
        mbar.use_nodes = True
        bsdf = mbar.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (1.0, 0.82, 0.05, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.5
    obj.data.materials.clear()
    obj.data.materials.append(mbar)
    return obj


def _animal_close_shot(out_path, category, name, action_name=None,
                       frame_kind=None, res=(900, 800), azimuth=20.0,
                       elevation=12.0):
    """O SINGURA piesa, incadrata STRANS (~2 m latime de cadru — cutia de
    masina de 4 m disparea complet piesa, revizuire coordonator val 4 a
    doua trecere), cu bara de scara de 0.5 m langa ea, din 3/4 fata.

    Fisier separat per piesa (nu insirate pe un rand): un cadru comun ar
    trebui sa incapa toate trei, ceea ce e exact problema de scara semnalata
    ("specks") — un `margin` mic pe UN SINGUR obiect e singurul mod sa
    ocupe cadrul cu adevarat."""
    _clear()
    objs = _import(category, name, MODELS)
    if not objs:
        print("LIPSA:", name)
        return None
    arm = next((o for o in objs if o.type == "ARMATURE"), None)
    mesh = next((o for o in objs if o.type == "MESH"), None)
    if arm is not None and action_name is not None:
        act = bpy.data.actions.get(action_name)
        if act is not None:
            if arm.animation_data is None:
                arm.animation_data_create()
            for t in list(arm.animation_data.nla_tracks):
                t.mute = True
            arm.animation_data.action = act
            if arm.animation_data.action_slot is None and act.slots:
                arm.animation_data.action_slot = act.slots[0]
            frame = (act.frame_range[0] if frame_kind == "start"
                     else act.frame_range[1])
            bpy.context.scene.frame_set(int(frame))
    bpy.context.view_layer.update()
    meshes = [o for o in objs if o.type == "MESH"]
    span_x = max(max(o.dimensions.x for o in meshes), 0.3) if meshes else 0.5

    # bara de scara LIPITA de piesa (0.2 m distanta, nu 0.5 m): un decalaj
    # mare largeste bbox-ul combinat pe care `shot()` il incadreaza si
    # departeaza camera exact ca o a doua piesa — masurat pe prima incercare
    # (0.5 m offset), piesele tot ocupau doar ~1/3 din cadru.
    bar = _make_scale_bar()
    bar.location = (0.0, -(span_x * 0.5 + 0.2), 0.0)

    built = meshes + [bar]
    for o in bpy.data.objects:
        if o.type in ("MESH", "ARMATURE"):
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1
    # azimut mic (3/4 fata, cerinta coordonator), margin STRANS (0.95, sub
    # 1.0 — `shot()` foloseste margin ca multiplicator peste distanta minima,
    # deci sub 1.0 apropie camera peste cadrul "exact") ca piesa sa umple
    # cadrul, nu doar o treime din el.
    shot(built, out_path, azimuth=azimuth, elevation=elevation, res=res,
        margin=1.05)
    return [(o.name, len(o.data.polygons)) for o in meshes]


def animals_close_sheet(path, models_dir=None, res=(900, 800)):
    """3 fisiere separate (kea Idle, kea Open, penguin), fiecare incadrat
    strans (~2 m latime), cu bara de scara de 0.5 m — vezi `_animal_close_shot`.
    `path` da baza numelui; se scriu `<path>_kea_idle.png`,
    `<path>_kea_open.png`, `<path>_penguin.png`."""
    base, ext = os.path.splitext(path)
    results = {}
    r = _animal_close_shot(base + "_kea_idle" + ext, "animals", "kea",
                           action_name="Idle", frame_kind="start", res=res)
    if r:
        results["kea_idle"] = r
    # aripile deschise se intind pe X: un azimut aproape frontal le arata
    # aproape din profil (edge-on), aproape invizibile in spatele corpului —
    # revizuire coordonator ("looks like only one wing"). azimut ~55 grade
    # (mai lateral) arata anvergura clar, fara sa piarda cititul 3/4.
    r = _animal_close_shot(base + "_kea_open" + ext, "animals", "kea",
                           action_name="Open", frame_kind="end", res=res,
                           azimuth=55.0, elevation=18.0)
    if r:
        results["kea_open"] = r
    # penguin: fata (burta+sprancene) e spre +Y Blender — azimut care
    # priveste dinspre +Y arata fata, nu spatele (cerinta coordonator:
    # "confirm the penguin's yellow brows are visible in the close-up")
    # penguin: fata (burta+sprancene+cioc) e spre +Y Blender. Camera la
    # azimut ~90 grade sta pe partea +Y (`shot()`: eye = center + (cos a,
    # sin a, ...) * dist), deci priveste DINSPRE +Y spre -Y — exact fata
    # piesei, nu spatele (masurat gresit prima data la 200 grade).
    r = _animal_close_shot(base + "_penguin" + ext, "animals", "penguin_tawaki",
                           res=res, azimuth=110.0, elevation=14.0)
    if r:
        results["penguin"] = r
    return results


def horizon_sheet(path, models_dir=None, res=(1900, 1000)):
    """Cele 4 noduri de orizont, fiecare randat din 2-3 azimuturi diferite —
    jocul le da un yaw ALEATOR (`Track._build_horizon`), deci planta trebuie
    sa arate ca fiecare nod citeste corect din orice unghi, nu doar din cel
    "bun". Layout: 4 randuri (cate un nod), 3 coloane (yaw 0/120/240) pe
    fiecare rand."""
    models_dir = models_dir or MODELS
    node_names = ["FarWall_A", "FarWall_B", "SnowRidge_A", "SnowRidge_B"]
    yaws = [0.0, 120.0, 240.0]

    built = []
    _clear()
    path_obj = os.path.join(models_dir, "fiordland", "rocks",
                            "fiordland_horizon.glb")
    if not os.path.exists(path_obj):
        print("LIPSA: fiordland_horizon")
        return []
    bpy.ops.import_scene.gltf(filepath=path_obj)
    imported = {o.name: o for o in bpy.context.selected_objects
               if o.type == "MESH"}
    missing = [n for n in node_names if n not in imported]
    if missing:
        print("LIPSA noduri in fiordland_horizon.glb:", missing)

    row_step = 130.0
    col_step = 130.0
    for row, name in enumerate(node_names):
        src = imported.get(name)
        if src is None:
            continue
        span_x = max(src.dimensions.x, 20.0)
        for col, yaw in enumerate(yaws):
            # duplica mesh-ul (link_duplicate) ca fiecare copie sa aiba
            # propriul yaw, fara sa afecteze originalul
            dup = src.copy()
            dup.data = src.data.copy()
            bpy.context.collection.objects.link(dup)
            dup.location = (col * col_step, -row * row_step, 0.0)
            dup.rotation_euler = (0.0, 0.0, math.radians(yaw))
            bpy.context.view_layer.update()
            mat = dup.matrix_world.copy()
            for v in dup.data.vertices:
                v.co = mat @ v.co
            dup.matrix_world.identity()
            dup.name = "%s_yaw%d" % (name, int(yaw))
            built.append(dup)
        # cutia de referinta o singura data per rand, langa prima coloana
        car = _make_ref_car()
        car.location = (-(span_x * 0.5 + REF_CAR[1] * 0.5 + 4.0), -row * row_step, 0.0)
        built.append(car)

    # sterge originalele neduplicate (raman doar copiile pozitionate)
    for o in list(imported.values()):
        bpy.data.objects.remove(o, do_unlink=True)

    if not built:
        print("plansa horizon SARITA (niciun nod gasit)")
        return []

    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 2000.0
    cam.data.clip_start = 0.1
    shot(built, path, azimuth=200.0, elevation=18.0, res=res, margin=1.15)
    return [(o.name, len(o.data.polygons)) for o in built if o.type == "MESH"]


def buildings_sheet(path, models_dir=None, res=(1900, 800)):
    """cafe_shed + lodge, unul langa altul (doua noduri fiecare, House_Wall +
    House_Roof) — verifica FARA ferestre luminate si acoperisul asezat pe
    pereti (nu plutind), brief §1.3."""
    models_dir = models_dir or MODELS
    _clear()
    built = []
    y = 0.0
    for cat, name in (("buildings", "cafe_shed"), ("buildings", "lodge")):
        objs = _import(cat, name, models_dir)
        if not objs:
            print("LIPSA:", name)
            continue
        meshes = [o for o in objs if o.type == "MESH"]
        roots = [o for o in objs if o.parent is None]
        span_y = max(max(o.dimensions.y for o in meshes), 2.0)
        half = span_y * 0.5
        for o in roots:
            o.location.y += y + half
        bpy.context.view_layer.update()
        piece_center_y = y + half
        y += span_y + 6.0
        built += meshes

        car = _make_ref_car()
        piece_span_x = max(max(o.dimensions.x for o in meshes), 0.5)
        car.location = (-(piece_span_x * 0.5 + REF_CAR[1] * 0.5 + 1.5),
                        piece_center_y, 0.0)
        built.append(car)

    if not built:
        print("plansa buildings SARITA (niciun GLB exportat inca)")
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
    shot(built, path, azimuth=30.0, elevation=13.0, res=res, margin=1.2)
    return [(o.name, len(o.data.polygons)) for o in built]


def kayak_sheet(path, models_dir=None, res=(1900, 700)):
    """kayak_a + kayak_b, fiecare cu cutia de referinta CLAR langa el —
    decalata atat pe X (in afara latimii caiacului) cat si pe Y (in spate),
    ca sa nu-l acopere in perspectiva (revizuire coordonator: cutia genericA
    din sheet() cadea aproape peste caiacul de 0.58 m latime)."""
    models_dir = models_dir or MODELS
    _clear()
    built = []
    y = 0.0
    for cat, name in (("props", "kayak_a"), ("props", "kayak_b")):
        objs = _import(cat, name, models_dir)
        if not objs:
            print("LIPSA:", name)
            continue
        meshes = [o for o in objs if o.type == "MESH"]
        roots = [o for o in objs if o.parent is None]
        span_y = max(max(o.dimensions.y for o in meshes), 0.5)
        half = span_y * 0.5
        for o in roots:
            o.location.y += y + half
        bpy.context.view_layer.update()
        piece_center_y = y + half
        y += span_y + 3.5
        built += meshes

        car = _make_ref_car()
        piece_span_x = max(max(o.dimensions.x for o in meshes), 0.5)
        # DOAR pe X, decalaj mare — un decalaj SI pe Y (incercarea 1) trage
        # cutia inapoi spre randul PRECEDENT cand piesele sunt deja insirate
        # pe Y (masurat: cutia caiacului B cadea peste coada caiacului A, in
        # golul dintre ele). Pe X singur, cutia ramane clar in dreptul
        # centrului piesei ei, fara sa intre in raza vreunei alte piese.
        car.location = (-(piece_span_x * 0.5 + REF_CAR[1] * 0.5 + 2.2),
                        piece_center_y, 0.0)
        built.append(car)

    if not built:
        print("plansa kayaks SARITA (niciun GLB exportat inca)")
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
    # azimuth 55 (nu 148, mostenit din sheet()): 148 e tuning-ul pentru
    # stirling_ledge (fata utila spre -X) si privea aproape DE-A LUNGUL
    # randului de caiace, punand cutia in perspectiva peste coada piesei
    # urmatoare. Un azimut mai aproape de lateral (55) arata clar caiacul SI
    # cutia lui, una langa alta, fara sa se suprapuna in cadru.
    shot(built, path, azimuth=55.0, elevation=13.0, res=res, margin=1.2)
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
print("plansa avalanche", avalanche_sheet(
    os.path.join(OUT, "fiordland_avalanche.png")))
print("plansa vehicles_small", kayak_sheet(
    os.path.join(OUT, "fiordland_vehicles_small.png")))
print("plansa buildings", buildings_sheet(
    os.path.join(OUT, "fiordland_buildings.png")))
print("plansa animals", animals_sheet(
    os.path.join(OUT, "fiordland_animals.png")))
print("plansa animals_close", animals_close_sheet(
    os.path.join(OUT, "fiordland_animals_close.png")))
print("plansa horizon", horizon_sheet(
    os.path.join(OUT, "fiordland_horizon.png")))
