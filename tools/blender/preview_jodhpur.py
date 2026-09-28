"""Planse de control pentru kitul Jodhpur — randate DIN GLB-urile exportate.

Ca `preview_fiordland.py`: importa fisierele, nu reconstruieste piesele, deci
verifica ce a ajuns in GLB (origine, orientare, AO, sloturi). Cubul implicit
si tot ce nu e in lista primesc `hide_render` (memoria
`blender-preview-cub-implicit`).

Trei moduri (brief §0.1 pasul 3, §2):
  1. planse de grup, cu cutia de referinta 4.0 x 1.8 x 1.5 m in cadru:
         blender --background --factory-startup --python tools/blender/run_build.py \
             -- preview_jodhpur.py -- --group pilot
  2. comparatie decupare <-> randare, per piesa (criteriul de fidelitate,
     brief §0.1): decupare in STANGA, randare a GLB-ului exportat in DREAPTA,
     aceeasi inaltime in pixeli, unghi ~3/4 stanga-fata (azimut 35, elevatie
     18), lumina de zi neutra, fundal #CFCFCF, culoare REALA (atlas_material +
     textura de clasa inmultita cu tenta, doar in preview):
         ... -- preview_jodhpur.py -- --compare ghanta_ghar
  3. planta valului: aduna comparatiile deja randate intr-o singura imagine:
         ... -- preview_jodhpur.py -- --sheet 1

Rulare (headless, fara argumente = randeaza toate grupele existente):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_jodhpur.py
"""

import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

REF_CAR = (4.0, 1.8, 1.5)  # lungime (Y Blender) x latime (X) x inaltime (Z)

# (categorie, piese, step) per val (brief §3). Doar valul 1 (pilotul) exista
# la scrierea asta -- restul se adauga pe masura ce valurile se livreaza.
GROUPS = {
    "pilot": ("buildings", ["ghanta_ghar", "blue_house_a"], 10.0),
}

# Tenta de preview per piesa/nod, pentru culoare REALA (brief §0.1 pasul 3,
# TASK C a instantei v2, extinsa in runda 3 dupa critica orbului + sef):
# FLAT hex * AO copt, fara textura de clasa proxy -- vezi `_apply_flat_tint`.
#
# REVIZUIRE runda 3: doar `Tower_Stone`/`House_Wall` aveau tenta declarata --
# restul nodurilor (Clock_Glow, Tower_Glow, House_Trim, House_Rail) cadeau pe
# `atlas_material()` implicit (textura de paleta UV-mapata simplu), care
# randeaza aproape alb/gri neutru pe fetele fara UV real -- exact bug-ul
# semnalat ("cupola/acoperisul ies gri/aproape alb"). ACUM fiecare nod din
# fiecare piesa are o tenta explicita:
#   - piatra turnului (orice nod STONE): #B8703F, gresie portocalie
#   - golurile GLOW pure (Tower_Glow): #2A2A2E, aproape negru -- ziua sunt
#     goluri inchise (brief regula 7), nu trebuie sa fie albe/pale
#   - `Clock_Glow` amesteca DOUA sloturi in acelasi nod (discul pe
#     FOAM_WHITE=22, acele pe VOLCANIC_BLACK=20) -- contract inghetat
#     (brief §1.1), nu se desparte in doua noduri doar pentru preview. Tenta
#     e un DICT {slot: hex}, aplicat per-fata prin `_apply_multi_flat_tint`
#     (recupereaza slotul din UV.x, colapsat pe centrul slotului).
#   - peretele/scara casei (House_Wall, House_Rail -- ambele pe slotul WALL):
#     #8FB0DC, albastru
#   - usa/obloanele (House_Trim, slot WOOD): #6B4A2E, maro lemn cald
COMPARE_SPECS = {
    "ghanta_ghar": {
        "category": "buildings",
        "tints": {
            "Tower_Stone": "#B8703F",
            "Clock_Glow": {FOAM_WHITE: "#F2F2F2", VOLCANIC_BLACK: "#2A2A2E"},
            "Tower_Glow": "#2A2A2E",
        },
    },
    "blue_house_a": {
        "category": "buildings",
        "tints": {
            "House_Wall": "#8FB0DC",
            "House_Rail": "#8FB0DC",
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
        },
    },
}


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    rel = name if not category else os.path.join(category, name)
    path = os.path.join(models_dir, "jodhpur", rel + ".glb")
    if not os.path.exists(path):
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.selected_objects if o.type in ("MESH", "ARMATURE")]


def _fix_ao_layer_name(obj):
    """Bug gasit prin masurare (nu presupus): `dio_lib.bake_ao` scrie AO-ul
    intr-un attribute numit "AO", dar exportul glTF are UN SINGUR slot de
    vertex color (COLOR_0) si Blender il RE-IMPORTA sub numele "Color", nu
    "AO". `apply_class`/`atlas_material` cauta explicit `layer_name = "AO"`
    (preview.py:123) -- pe o piesa importata dintr-un GLB, acel layer nu
    exista, ShaderNodeVertexColor citeste negru implicit, iar MULTIPLY cu
    negru scoate tot obiectul negru, indiferent de textura/tenta (exact ce s-a
    randat prima data pe ghanta_ghar: turnul intreg negru). `apply_class` nu
    e nicaieri altundeva apelat pe un mesh IMPORTAT (doar pe cele proaspat
    construite in acelasi build, unde attributul se numeste deja "AO"), deci
    fix-ul apartine aici, nu lui dio_lib."""
    attrs = obj.data.attributes
    if "AO" in attrs:
        return
    if "Color" in attrs:
        attrs["Color"].name = "AO"


def _make_ref_car(name="RefCar"):
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


def sheet(group, path, models_dir=None, azimuth=180.0 - 35.0, elevation=16.0,
          res=(1600, 720), place_car=True, margin=1.25):
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


# --- comparatie de fidelitate (brief §0.1 pasul 3) ----------------------------

def _apply_flat_tint(obj, hex_color):
    """Material de preview FLAT: culoare de baza = hex-ul tintei * AO copt,
    fara nicio textura de clasa proxy (TASK C, instanta v2 a kitului).

    Motivul schimbarii fata de v1 (`_apply_tint`, pastrata mai jos doar ca
    istoric/referinta daca vreun consumator vechi o mai cheama): proxy-urile
    de textura (`plaster.png`, `alpine_granite.png`) nu exista sub numele
    claselor reale ale pistei si aveau luminanta gresita (gri-brun mediu, nu
    aproape-alb), ceea ce a cerut o corectie de gamma fragila si tot ieseau
    desaturate sub AgX. `view_transform=Standard` (deja setat in
    `_neutral_shot`) plus un multiply DIRECT hex*AO da exact culoarea din
    tabelul de sloturi (brief §0.4), fara ghicit de gamma sau proxy gresit."""
    mat = _flat_material(hex_color)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def _apply_multi_flat_tint(obj, slot_tints):
    """Ca `_apply_flat_tint`, dar PE FATA, recuperand slotul din UV.x --
    pentru noduri care amesteca mai multe sloturi (ex. `Clock_Glow`: discul
    alb pe FOAM_WHITE si acele pe VOLCANIC_BLACK, in ACELASI nod -- contract
    inghetat, brief §1.1, nu se desparte in doua noduri doar pentru preview).

    Un singur `_apply_flat_tint` (un material FLAT pe tot obiectul) ar
    colora tot nodul cu o singura culoare, stergand contrastul disc/ace --
    exact bug-ul gasit runda 3 ("cadranele ies gri/pale, fara contrast").

    `slot_tints`: {slot_int: hex_color}. UV-urile sunt colapsate pe centrul
    slotului (`dio_lib.slot_u`), deci `round(u * SLOTS - 0.5)` recupereaza
    slotul exact, fara ambiguitate."""
    me = obj.data
    uv = me.uv_layers.active
    if uv is None:
        return
    mats = {}
    for slot, hexcol in slot_tints.items():
        mats[slot] = _flat_material(hexcol)
    obj.data.materials.clear()
    mat_index = {}
    for slot in slot_tints:
        mat_index[slot] = len(obj.data.materials)
        obj.data.materials.append(mats[slot])
    default_slot = next(iter(slot_tints))
    for poly in me.polygons:
        li = poly.loop_indices[0]
        u = uv.data[li].uv[0]
        slot = round(u * SLOTS - 0.5)
        poly.material_index = mat_index.get(slot, mat_index[default_slot])


def _srgb_to_linear(c):
    """sRGB [0,1] -> liniar, formula standard (IEC 61966-2-1).

    REVIZUIRE runda 3, cauza reala a desaturarii semnalate de critic (17%
    randat vs 35% nativ hex-ului, MASURAT chiar si izolat, cu AO fortat la
    1,0, fara alt multiply): `Base Color`-ul unui Principled BSDF asteapta
    valori LINIARE, dar codul punea direct `int(hex,16)/255` (adica
    fractia sRGB) in acel input. Blender interpreteaza acele numere ca
    liniare si le trece prin conversia liniar->afisaj (sRGB OETF) INCA O
    DATA la randare -- o dubla aplicare a curbei gamma, care comprima toate
    culorile spre mijlocul intervalului (desatureaza), indiferent de
    view_transform (Standard sau AgX -- ambele presupun input liniar).
    Fara aceasta conversie, orice tenta flat din acest fisier era gresita
    de la inceput, nu doar albastrul casei -- turnul (portocaliu, mai
    aproape de mijlocul intervalului) mascase bug-ul, fiind mai putin
    vizibil la ochi decat pe un albastru saturat."""
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def _flat_material(hex_color):
    """Materialul FLAT (hex * AO) folosit de `_apply_flat_tint` si
    `_apply_multi_flat_tint` -- extras ca sa nu se duplice graful de noduri."""
    name = "PreviewFlat_%s" % hex_color.lstrip("#")
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    r = _srgb_to_linear(int(hex_color[1:3], 16) / 255.0)
    gg = _srgb_to_linear(int(hex_color[3:5], 16) / 255.0)
    bcol = _srgb_to_linear(int(hex_color[5:7], 16) / 255.0)

    vcol = nt.nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "AO"
    ao_mix = nt.nodes.new("ShaderNodeMix")
    ao_mix.data_type = "RGBA"
    ao_mix.blend_type = "MULTIPLY"
    ao_mix.inputs["Factor"].default_value = 1.0
    ao_mix.inputs[6].default_value = (r, gg, bcol, 1.0)
    nt.links.new(ao_mix.inputs[7], vcol.outputs["Color"])
    nt.links.new(bsdf.inputs["Base Color"], ao_mix.outputs[2])
    return mat


def _import_for_compare(name, spec, models_dir):
    objs = _import(spec["category"], name, models_dir)
    meshes = [o for o in objs if o.type == "MESH"]
    for o in meshes:
        _fix_ao_layer_name(o)
        tint = spec.get("tints", {}).get(o.name)
        if isinstance(tint, dict):
            _apply_multi_flat_tint(o, tint)
        elif tint is not None:
            _apply_flat_tint(o, tint)
        else:
            atlas_material()  # forteaza materialul standard sa existe
            o.data.materials.clear()
            o.data.materials.append(atlas_material())
    return meshes


def compare(name, models_dir=None, res_height=900, out_dir=None):
    """Decupare (stanga) + randare din GLB exportat (dreapta), la aceeasi
    inaltime in pixeli (brief §0.1 pasul 3)."""
    models_dir = models_dir or MODELS
    out_dir = out_dir or os.path.join(PROJECT, "docs", "asset_briefs", "img",
                                      "jodhpur_fidelity")
    os.makedirs(out_dir, exist_ok=True)
    spec = COMPARE_SPECS.get(name)
    if spec is None:
        print("LIPSA specificatie compare pentru", name)
        return None

    crop_path = os.path.join(PROJECT, "docs", "track_briefs", "img",
                             "jodhpur_assets_v1", name + ".png")
    if not os.path.exists(crop_path):
        print("LIPSA decupare:", crop_path)
        return None

    _clear()
    meshes = _import_for_compare(name, spec, models_dir)
    if not meshes:
        print("LIPSA GLB pentru compare:", name)
        return None

    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in meshes) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1

    render_path = os.path.join(out_dir, "_render_" + name + ".png")
    # fundal gri deschis #CFCFCF, lumina de zi neutra (nu tema calda din
    # `_world`/`_light`: aici vrem sa se citeasca CULOAREA reala a piesei, nu
    # tenta calda de apus a temei) -- randam manual, fara `shot()`.
    _neutral_shot(meshes, render_path, azimuth=35.0, elevation=18.0,
                 res_height=res_height)

    # Blender-ul headless n-are PIL in Python-ul lui bundle-uit (masurat: nu
    # exista, si nu instalam pachete in interpretorul lui Blender). Stitch-ul
    # crop+randare si planta de val se fac cu Python-ul de SISTEM, intr-un
    # proces separat -- `compose_jodhpur.py`, apelat aici prin subprocess.
    out_path = os.path.join(out_dir, name + ".png")
    _run_compose(["--compare", name, "--crop", crop_path,
                 "--render", render_path, "--out", out_path,
                 "--height", str(res_height)])
    print("comparatie salvata (compose extern):", out_path)
    return out_path


def _run_compose(extra_args):
    import subprocess
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "compose_jodhpur.py")
    # Python de sistem, nu cel din Blender: incearca "python", apoi "py".
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + extra_args, capture_output=True, text=True)
            if r.returncode == 0:
                if r.stdout.strip():
                    print(r.stdout.strip())
                return True
            print("compose_jodhpur.py a esuat (%s):" % exe, r.stderr.strip())
        except FileNotFoundError:
            continue
    print("Nu am gasit python de sistem -- ruleaza manual:")
    print("    python tools/blender/compose_jodhpur.py", " ".join(extra_args))
    return False


def _neutral_shot(objects, path, azimuth, elevation, res_height, margin=1.2):
    """Ca `shot()`, dar cu lumina de zi NEUTRA si fundal #CFCFCF (brief §0.1
    pasul 3), nu tema calda de apus din `preview._light`/`_world`."""
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objects:
        for corner in o.bound_box:
            p = o.matrix_world @ Vector(corner)
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    center = (lo + hi) * 0.5
    ext = hi - lo
    res_x = int(res_height * 4 / 3)
    res = (res_x, res_height)

    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = 55.0
    sensor = cam.data.sensor_width
    aspect = res[0] / float(res[1])
    hfov = 2.0 * math.atan(sensor / (2.0 * cam.data.lens))
    vfov = 2.0 * math.atan(math.tan(hfov / 2.0) / aspect)
    width = math.hypot(ext.x, ext.y)
    dist = margin * max(width * 0.5 / math.tan(hfov / 2.0),
                        ext.z * 0.5 / math.tan(vfov / 2.0))
    a = math.radians(azimuth)
    e = math.radians(elevation)
    eye = center + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e),
                           math.sin(e))) * dist
    cam.location = eye
    look = (center - eye).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()

    # lumina de zi neutra: soare alb, sus, fara tenta calda
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)

    # REVIZUIRE runda 3 (nota sefului): lumina principala trebuie sa fie PE
    # PARTEA CAMEREI (azimut la <=40 grade de camera), altfel fetele vazute
    # de camera cad in umbra si citesc desaturat, indiferent cat de tare e
    # fill-ul. Masurat direct: cu `rotation_euler=(45,0,35)` (Z=azimutul
    # camerei, in grade, dar Euler-ul unui SUN nu se comporta ca un azimut
    # direct -- directia de iluminare rezultata e la ~90 grade de camera, nu
    # la 35), fata cu usa a casei albastre (+Y) cadea in umbra AMBELOR
    # lumini directionale. Rezolvat prin cautare numerica: pentru camera la
    # azimut=35/elevatie=18 (formula `_neutral_shot`), directia care
    # ILUMINEAZA exact partea camerei e `rotation_euler=(radians(65), 0,
    # radians(125))` (produsul scalar cu directia camerei = 0,99, verificat
    # cu Euler().to_matrix() @ (0,0,-1)) -- NU Z=azimut direct.
    sdata = bpy.data.lights.new("NeutralSun", type="SUN")
    sun = bpy.data.objects.new("NeutralSun", sdata)
    scene.collection.objects.link(sun)
    # REVIZUIRE: energiile de mai jos au fost coborate agresiv (pana la
    # 1,2/0,9) in timp ce cautam cauza desaturarii, presupunand supra-
    # expunere -- cauza REALA era conversia sRGB->liniar lipsa din
    # `_flat_material` (vezi `_srgb_to_linear`), nu lumina. Cu bug-ul de
    # culoare corectat, energii rezonabile (fata luminata direct, fara
    # supra-expunere pe alb la AO=1) sunt 2,4/1,0.
    sun.data.energy = 2.4
    sun.data.color = (1.0, 1.0, 1.0)
    sun.data.angle = math.radians(3.0)
    sun.data.specular_factor = 0.0
    sun.rotation_euler = (math.radians(65.0), 0.0, math.radians(125.0))

    # fill mai slab (soarele principal acopera acum fata camerei) -- doar ca
    # sa nu ramana complet negre fetele din umbra opusa.
    fill_data = bpy.data.lights.new("NeutralFill", type="SUN")
    fill = bpy.data.objects.new("NeutralFill", fill_data)
    scene.collection.objects.link(fill)
    fill.data.energy = 1.0
    fill.data.color = (1.0, 1.0, 1.0)
    fill.rotation_euler = (math.radians(90 - 55), 0.0, math.radians(35.0 + 180.0))

    world = scene.world or bpy.data.worlds.new("PreviewWorldNeutral")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.812, 0.812, 0.812, 1.0)  # #CFCFCF
        # Ambientul gri se amesteca aditiv cu fetele umbrite -- prea puternic
        # desatureaza (griul domina). Cu soarele acum aliniat pe fata camerei
        # (vezi mai sus) si bug-ul real de desaturare corectat
        # (`_srgb_to_linear`), 0,5 e suficient doar ca sa umple umbrele
        # adanci fara sa spele culoarea fetelor luminate.
        bg.inputs[1].default_value = 0.5

    # AgX (implicit in Blender 4/5) comprima si desatureaza puternic culorile
    # -- masurat direct: o tenta albastra `#8FB0DC` inmultita cu plaster.png
    # iesea gri neutru complet (176,176,176), nedistinctibil de netintat.
    # Comparatia cere "culoare REALA" (brief §0.1 pasul 3), deci view transform
    # Standard, ca hex-ul din tabel sa se vada asa cum a fost scris.
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0

    scene.render.engine = "BLENDER_EEVEE_NEXT" if hasattr(
        bpy.types, "RenderEngineEeveeNext") or "BLENDER_EEVEE_NEXT" in [
        e2.identifier for e2 in
        bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    ] else "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    return path


WAVE_PIECES = {1: ["ghanta_ghar", "blue_house_a"]}


def fidelity_sheet(wave, out_dir=None, names=None):
    """Aduna comparatiile deja randate ale valului intr-o singura imagine
    (brief §0.1 pasul 5). Delegat catre `compose_jodhpur.py` (Python de
    sistem, cu PIL) -- vezi motivul in `compare()`."""
    fid_dir = os.path.join(PROJECT, "docs", "asset_briefs", "img", "jodhpur_fidelity")
    out_dir = out_dir or os.path.join(PROJECT, "docs", "asset_briefs", "img")
    names = names or WAVE_PIECES.get(wave, [])
    out_path = os.path.join(out_dir, "jodhpur_fidelity_val%d.png" % wave)
    ok = _run_compose(["--sheet", str(wave), "--fid-dir", fid_dir,
                       "--names", ",".join(names), "--out", out_path])
    if ok:
        print("planta fidelitate val", wave, "salvata:", out_path)
        return out_path
    return None


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)

argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []

if "--compare" in args:
    idx = args.index("--compare")
    piece = args[idx + 1]
    compare(piece)
elif "--sheet" in args:
    idx = args.index("--sheet")
    wave = int(args[idx + 1])
    fidelity_sheet(wave)
elif "--group" in args:
    idx = args.index("--group")
    g = args[idx + 1]
    print("plansa", g, sheet(g, os.path.join(OUT, "jodhpur_%s.png" % g)))
else:
    for g in GROUPS:
        print("plansa", g, sheet(g, os.path.join(OUT, "jodhpur_%s.png" % g)))
