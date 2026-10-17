"""Serengeti — ANIMALELE (plansa serengeti_assets_v1, randurile 1-4 + crocodilul).

  serengeti/animals/wildebeest.glb   gnu STATIC pentru MultiMesh-ul turmei (galopul e in shader)
  serengeti/animals/zebra.glb        zebra STATICA, acelasi rol
  serengeti/animals/elephant.glb     elefant cu SCHELET in cod: Walk, Trumpet
  serengeti/animals/hippo_back.glb   spinarea + capul hipopotamului (mesh rigid, urca pe ceas)
  serengeti/animals/crocodile.glb    crocodil pe mal, 4 m, static

**Gnu-ul si zebra NU au schelet in GLB, si asta e decizia din brief §3:** turma
e un MultiMesh de 120-200 de instante, iar galopul se face in vertex shader
(picioarele sub y = 0,55 m se leagana, corpul salta) cu faza per instanta.
200 de AnimationPlayer-e ar fi fost exact costul pe care CLAUDE.md il interzice
pe mobil. Sursele sunt insa animate (Quaternius, CC0): taurul din „Ultimate
Animated Animals" devine gnu (silueta e aproape gata: greaban inalt, cap jos,
coarne), zebra vine din „Farm Animal Pack". Le luam in poza de repaus,
DECIMATE la ~700 tri (memoria `decimare-mesh-importat`: intai `remove_doubles`,
altfel raman gauri), UV-urile pe sloturi dupa materialul sursa, AO ca gradient.

**Contractul cu shader-ul turmei (HerdHazard._herd_material):** origine la
sol, fata spre -Z in Godot (= +Y in Blender), picioarele SUB 0,55 m. Aici se
masoara si se tipareste inaltimea la care se termina picioarele (burta).

**Elefantul e singurul rig nou**, facut in cod peste Builder (reteta testoasei,
PR #282): fiecare piesa e o insula, oasele se pun pe insule dupa pozitie,
greutatea rigida (un elefant de jucarie nu se indoaie). Doua actiuni:
Walk (mers, 1,5 s) si Trumpet (telegraful din brief §3: urechile se desfac,
trompa sus, 1,5 s inainte sa intre in banda).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_serengeti_animals.py
"""

import bpy
import bmesh
import math
from mathutils import Matrix, Vector

# Pachetele stau sub `downloaded assets\Animals\` din oct 2026 (reorganizare pe
# categorii); drumurile vechi, direct sub `downloaded assets\`, nu mai exista.
PACKS = r"D:\GameDev\downloaded assets\Animals"
PACK_ULTIMATE = PACKS + r"\Ultimate Animated Animals - July 2021\glTF\Bull.gltf"
PACK_HIPPO = PACKS + r"\low_poly_hippo\low_poly_hippo.glb"
PACK_FARM = PACKS + r"\Farm Animal Pack-glb\Zebra.glb"
PACK_ELEPHANT = (PACKS + r"\191 animals pack\assets\models"
                  r"\african-elephant_ba7f1b66-218e-4b28-8e8c-2cbf68512f04"
                  r"\african-elephant-character-low-poly_2K_ff8635e6-1c58-49ae-b3cd-e608613f8b46.blend")

AO_ANIMAL = dict(samples=20, dist=2.0, gradient="vertical",
                 low=0.46, high=1.00, power=0.9, floor=0.18)
AO_BIG = dict(samples=20, dist=3.5, gradient="vertical",
              low=0.44, high=1.00, power=0.9, floor=0.16)

GNU_SLOTS = {"Main": LOG_DARK, "Main_Light": ROCK_DARK, "Hooves": ROCK_DARK,
             "Muzzle": VOLCANIC_BLACK, "Eye_Black": ASPHALT, "Eye_White": FOAM_WHITE,
             "Horns": SAND_LIGHT}
ZEBRA_SLOTS = {"Black": VOLCANIC_BLACK, "White": FOAM_WHITE}
GREY = MARBLE_GREY
GREY_SH = SAND_SHADOW
IVORY = FOAM_WHITE
HIPPO = ROCK_DARK
HIPPO_PINK = TILE_TERRACOTTA
## Lungimea spinarii din contractul cu HippoHazard (vezi build_hippo). Sursa e
## de 10 m — un hipopotam adevarat are ~3,5 m, dar aici cifra care conteaza e
## gabaritul pe care hazardul il asaza in vad, nu realismul zoologic.
HIPPO_LENGTH = 4.8
CROC = CACTUS_GREEN
CROC_BELLY = SAND_SHADOW


# --------------------------------------------------------------- importuri statice

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


def _wipe():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)


def import_static(path, name, slots, target_length, target_tris, ao_floor=0.78):
    """Sursa animata -> mesh STATIC in poza de repaus, decimat, pe sloturi."""
    _wipe()
    bpy.ops.import_scene.gltf(filepath=path)
    arms = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    assert len(arms) == 1, "asteptam 1 armatura: %r" % [a.name for a in arms]
    arm = arms[0]
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm]
    assert meshes, "niciun mesh skinnuit"
    mesh = meshes[0]
    for o in [o for o in bpy.data.objects if o.type == "MESH" and o is not mesh]:
        bpy.data.objects.remove(o, do_unlink=True)

    # incotro e capul: din oase, in spatiul lumii (lectia vacii)
    def bone_pos(prefix):
        for b in arm.data.bones:
            if b.name.startswith(prefix):
                return arm.matrix_world @ b.head_local
        raise AssertionError("os lipsa: %s*" % prefix)
    head_w, tail_w = bone_pos("Head"), bone_pos("Tail")

    # poza de repaus: scoatem skinning-ul, pastram transformul de lume
    mw = mesh.matrix_world.copy()
    for m in list(mesh.modifiers):
        mesh.modifiers.remove(m)
    mesh.parent = None
    mesh.matrix_world = mw
    bpy.data.objects.remove(arm, do_unlink=True)
    mesh.name = name
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # orientare: lungimea pe Y, capul spre +Y (= -Z in Godot, vezi antetul).
    #
    # ATENTIE, rotatia asta NU poate corecta un 180. `ang` iese din
    # `atan2(d.y, d.x)`, iar pe pack-ul Ultimate vectorul coada->cap e chiar
    # (0, -6.28): ang = -180 grade, si atunci `-ang` si `+ang` sunt ACEEASI
    # rotatie. Deci pentru sursele deja aliniate pe Y linia de mai jos e un
    # no-op, si capul ramane pe partea pe care l-a adus pack-ul. Corectia de
    # sens se face mai jos, DUPA ce stim unde au cazut piesele de cap.
    d = head_w - tail_w
    ang = math.atan2(d.y, d.x) - math.pi * 0.5
    mesh.rotation_euler = (0.0, 0.0, -ang)
    bpy.ops.object.transform_apply(rotation=True)
    lo, hi = _world_bbox([mesh])
    length = hi.y - lo.y
    s = target_length / length
    mesh.scale = (s, s, s)
    bpy.ops.object.transform_apply(scale=True)
    lo, hi = _world_bbox([mesh])
    mesh.location -= Vector(((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, lo.z))
    bpy.ops.object.transform_apply(location=True)

    # sudare + decimare (memoria `decimare-mesh-importat`)
    me = mesh.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.002)
    bm.to_mesh(me)
    bm.free()
    before = tri_count(mesh)
    ratio = min(1.0, target_tris / float(max(before, 1)))
    if ratio < 0.98:
        mod = mesh.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # SENSUL, pe GEOMETRIA finala si pe SLOTURILE de cap.
    #
    # De ce nu pe oase: `head_w`/`tail_w` se citesc INAINTE de rotatie si de
    # `transform_apply`, deci nu mai descriu mesh-ul de la finalul functiei.
    # Masurat: vectorul lor rotit iesea +6.28 (deci "cap pe +Y"), in timp ce
    # coarnele mesh-ului cadeau la y=-0.93. Iar rotatia de mai sus nu poate
    # repara un 180 (ang = -180 => -ang == +ang), deci sursele deja aliniate pe
    # Y treceau neatinse, cu capul in partea in care le-a adus pack-ul.
    # Sloturile de cap sunt singurul martor care nu minte: coarnele si ochii
    # exista DOAR in cap (o euristica de "masa sus" cade pe coada, capcana
    # documentata in build_cow_animated.py).
    # Martorul e MATERIALUL SURSEI, nu UV-ul: UV-urile pe sloturi se scriu abia
    # mai jos (dupa blocul asta), deci aici `uv_layers.active` e inca None —
    # prima varianta a crapat exact asa. Materialele sunt insa intacte pana la
    # `me.materials.clear()`, si numele lor e cheia din `slots`.
    # SE CITESTE `v.co` BRUT, NU `matrix_world @ v.co`. Masurat cu o sonda pe
    # un cub: dupa `rotation_euler = pi` SI dupa `transform_apply(rotation)`,
    # `matrix_world @ co` intoarce tot valoarea VECHE (+2.000 la toate cele trei
    # citiri), in timp ce `co` brut se schimba exact la transform_apply
    # (0.000 -> +2.000). `transform_apply` COACE rotatia in varfuri si lasa
    # matricea identitate — deci martorul e geometria, nu matricea.
    # Fara asta, corectia de mai jos se masura pe o valoare invechita: se
    # intorcea cand nu trebuia si raporta -0.957 acolo unde geometria avea
    # -0.935 (doua runde pierdute pe un 180 care se plimba).
    head_mats = {i for i, mat in enumerate(mesh.data.materials)
                 if mat.name.split(".")[0]
                 in ("Horns", "Eye_Black", "Eye_White", "Muzzle")}
    me_o = mesh.data
    ys, cnt = 0.0, 0
    if head_mats:
        for poly in me_o.polygons:
            if poly.material_index not in head_mats:
                continue
            for li in poly.loop_indices:
                ys += me_o.vertices[me_o.loops[li].vertex_index].co.y
                cnt += 1
    else:
        # ZEBRA: n-are slot doar-de-cap (doar Black/White), deci martorul e
        # GATUL — varfurile cele mai INALTE. La zebra gatul chiar e punctul
        # cel mai de sus (masurat: ymax 1.53 la cap fata de 1.10 la crupa),
        # spre deosebire de vaca, unde coada e mai sus decat capul. Fara
        # ramura asta, `head_mats` iesea gol si zebra NU primea corectia —
        # gnu-ul se repara, zebra ramanea cu spatele.
        zs = [v.co.z for v in me_o.vertices]
        z_top = max(zs) - (max(zs) - min(zs)) * 0.12
        for v in me_o.vertices:
            if v.co.z >= z_top:
                ys += v.co.y
                cnt += 1
    # Corectia e COMUNA celor doua masuratori (gnu pe sloturi, zebra pe gat).
    # Prima varianta o lasase din greseala in ramura `else`, deci gnu-ul masura
    # si nu se mai intorcea niciodata — trecuse o data la +0.933 si a recazut la
    # -0.933 la editarea urmatoare, fara ca nimic din logica sa se schimbe.
    if cnt and ys / cnt < 0.0:
        # SE ROTESC VARFURILE, nu obiectul. `bpy.ops.object.transform_apply`
        # intoarce {'FINISHED'} si NU schimba nimic in modul asta
        # (--background --factory-startup): masurat pe acest mesh, cu
        # context garantat (active=W, selected, mode=OBJECT), coarnele au
        # ramas la y=-0.929 inainte si dupa apel, cu rotation_euler revenit
        # la zero. Rotind direct `v.co`, aceleasi coarne trec la +0.929.
        # Cinci runde de "intors semnul" au dat cifre identice la trei
        # zecimale exact din cauza asta (memoria `sonda-masura-alt-obiect`:
        # cifra identica la bit inseamna mecanism neconectat).
        rot = Matrix.Rotation(math.pi, 4, "Z")
        for v in me_o.vertices:
            v.co = rot @ v.co
        me_o.update()
        print("  orientare: capul era spre -Y (y=%+.3f), am intors varfurile cu pi"
              % (ys / cnt))
    print("  %s: %d -> %d tris (sursa %s)" % (name, before, tri_count(mesh), path.split("\\")[-1]))

    # UV-uri pe sloturi dupa materialul sursa
    slot_of_index = {}
    for i, mat in enumerate(me.materials):
        base = mat.name.split(".")[0]
        assert base in slots, "material sursa nemapat: %s" % mat.name
        slot_of_index[i] = slots[base]
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        u = slot_u(slot_of_index.get(poly.material_index, LOG_DARK))
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)
    # AO gradient vertical (fara raycast: mesh-ul e o blana, nu o stanca)
    for layer in list(me.color_attributes):
        me.color_attributes.remove(layer)
    ao = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="CORNER")
    lo, hi = _world_bbox([mesh])
    for poly in me.polygons:
        for li in poly.loop_indices:
            z = me.vertices[me.loops[li].vertex_index].co.z
            t = max(0.0, min(1.0, (z - lo.z) / max(hi.z - lo.z, 1e-6)))
            v = ao_floor + (1.0 - ao_floor) * t
            ao.data[li].color = (v, v, v, 1.0)
    me.color_attributes.active_color = ao
    me.materials.clear()
    me.materials.append(atlas_material())
    apply_smooth(mesh, 55.0)
    # linia burtii: pana unde ajung picioarele (contractul shader-ului, 0,55 m)
    # contractul shader-ului: cat din geometrie sta sub 0,55 m (= "picioare")
    below = sum(1 for v in me.vertices if v.co.z < 0.55)
    print("  gabarit %.2f x %.2f x %.2f m; %d%% din varfuri sub 0,55 m (leganate de shader)"
          % (hi.x - lo.x, hi.y - lo.y, hi.z - lo.z, 100 * below // max(len(me.vertices), 1)))
    return mesh


def gnu_extras():
    """Ce ii lipseste taurului ca sa fie gnu: barba, coama pe greaban, coada cu
    smoc. Se lipesc (join) pe mesh-ul importat."""
    b = Builder()
    b.box((0.0, 0.62, 0.72), (0.14, 0.34, 0.16), ROCK_DARK)         # barba sub gat
    b.box((0.0, 0.05, 1.30), (0.10, 0.85, 0.12), VOLCANIC_BLACK)     # coama
    b.taper_sweep([Vector((0, -1.05, 0.95)), Vector((0, -1.25, 0.55)), Vector((0.05, -1.3, 0.32))],
                  [0.03, 0.03, 0.06], VOLCANIC_BLACK, segments=4)
    return b.to_object("Gnu_Extras")


def build_wildebeest():
    mesh = import_static(PACK_ULTIMATE, "Wildebeest", GNU_SLOTS, 2.4, 720)
    extra = gnu_extras()
    finish(extra, bevel=0.01, ao=AO_ANIMAL, origin="base_axis")
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    extra.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.join()
    return mesh


def build_zebra():
    return import_static(PACK_FARM, "Zebra", ZEBRA_SLOTS, 2.0, 680)


# --------------------------------------------------------------------- elefantul

def elephant_mesh():
    """Geometria elefantului: mesh IMPORTAT (pachetul "191 animals pack",
    low-poly, Z-up ca Blender, capul deja pe +Y), nu Builder.

    Inlocuieste boulder-ele procedurale (silueta veche citea a bolovan pe
    picioare, nu a elefant — acelasi verdict care a scos hipopotamul din
    `rock`/`boulder`, vezi build_hippo). Sursa e un mesh STATIC fara schelet
    (1143 verts, 2272 tri, un singur material cu textura bitmap 2K) — rig-ul
    ramane cel din `elephant_rig`, scris peste geometria asta prin clasificare
    pe pozitie (nu pe insule Builder: mesh-ul e continuu, sudat la export).
    """
    _wipe()
    with bpy.data.libraries.load(PACK_ELEPHANT, link=False) as (data_from, data_to):
        data_to.objects = [n for n in data_from.objects]
    for o in data_to.objects:
        if o is not None:
            bpy.context.collection.objects.link(o)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    assert len(meshes) == 1, "asteptam 1 mesh: %r" % [m.name for m in meshes]
    mesh = meshes[0]
    mesh.name = "Elephant_Mesh"
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    for m in list(mesh.modifiers):
        mesh.modifiers.remove(m)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Sensul NU vine gata: sursa are capul pe -Y. Prima varianta presupunea
    # "+Y, asimetric spre +Y" si elefantul-hazard mergea cu spatele (#502);
    # se corecteaza mai jos, dupa scara, pe un martor masurat (trompa).
    me = mesh.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.002)
    bm.to_mesh(me)
    bm.free()
    before = tri_count(mesh)
    target_tris = 1100
    ratio = min(1.0, target_tris / float(max(before, 1)))
    if ratio < 0.98:
        mod = mesh.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier=mod.name)
    print("  elephant import: %d -> %d tris" % (before, tri_count(mesh)))

    # Scara: pastram gabaritul vechi (lungime bot-coada ~6,35 m, masurata pe
    # boulder-ele inlocuite) ca sa nu schimbam contractul cu Track14 (spatiere
    # in DecorManual, coliziunea din world_prop).
    lo, hi = _world_bbox([mesh])
    target_length = 6.2
    s = target_length / (hi.y - lo.y)
    mesh.scale = (s, s, s)
    bpy.ops.object.transform_apply(scale=True)
    lo, hi = _world_bbox([mesh])
    mesh.location -= Vector(((lo.x + hi.x) * 0.5, 0.0, lo.z))
    bpy.ops.object.transform_apply(location=True)

    # Sensul: capul pe +Y (= -Z in Godot, contractul pe care SlidingHazard il
    # roteste spre directia de mers). Martorul e TROMPA: la capatul cu capul,
    # geometria de langa axa (|x| < 0.35) coboara pana la sol; la capatul cu
    # coada, cea mai joasa e coada, pe la jumatatea inaltimii. Masurat pe
    # GLB-ul vechi: 0.26 m la un capat, 1.53 m la celalalt. Prima varianta
    # presupunea capul pe +Y fara sa masoare, si elefantul-hazard mergea cu
    # spatele (#502); clasificarea pe oase de mai jos (Trunk pe +Y) punea
    # fildesul si trompa pe crupa.
    #
    # Matricea obiectului se coace intai in varfuri: `transform_apply` e un
    # no-op in --background (nota din `import_static`), iar de aici incolo
    # sloturile si oasele citesc `v.co` brut.
    me.transform(mesh.matrix_world)
    mesh.matrix_world = Matrix.Identity(4)
    ys = [v.co.y for v in me.vertices]
    y_lo, y_hi = min(ys), max(ys)
    end = (y_hi - y_lo) * 0.10
    axis = [v.co for v in me.vertices if abs(v.co.x) < 0.35]
    z_neg = min(c.z for c in axis if c.y <= y_lo + end)
    z_pos = min(c.z for c in axis if c.y >= y_hi - end)
    flip = z_neg < z_pos
    print("  elephant: cel mai jos langa axa %.2f m la -Y, %.2f m la +Y -> capul pe %s"
          % (z_neg, z_pos, "-Y, intors cu pi" if flip else "+Y"))
    # Originea la MIJLOCUL lungimii, nu la capatul sursei: SlidingHazard isi
    # centreaza cutia de coliziune pe origine (`shape.position` doar pe Y), iar
    # un mesh decalat cu 0,9 m lasa corpul in afara cutiei.
    m = Matrix.Translation(Vector((0.0, -(y_lo + y_hi) * 0.5, 0.0)))
    if flip:
        m = Matrix.Rotation(math.pi, 4, "Z") @ m
    me.transform(m)
    me.update()
    zs = [v.co.z for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    head_z = min(v.co.z for v in me.vertices
                 if abs(v.co.x) < 0.35 and v.co.y >= max(ys) - end)
    assert head_z < 0.5 * (max(zs) - min(zs)), (
        "elephant: trompa nu e pe +Y dupa corectie (z min la +Y = %.2f)" % head_z)

    # Sloturi de paleta: fildesii se iau din TEXTURA sursei (fetele deschise),
    # labele sunt jos SI laterale (|x|>0.35) — restul ramane pe GREY.
    #
    # Fildesii NU se pot lua pe pozitie. Prima varianta ii cauta "aproape de
    # axa X=0, in ultimii 18% pe +Y" — dar fildesii ies LATERAL (|x| 0.33-0.47,
    # la 40-53% din inaltime), iar langa axa, in fata, sta trompa care atarna.
    # Cu sensul gresit regula picta crupa; cu sensul corect ar fi pictat
    # trompa. Pe textura insa fildesul e singura zona deschisa (luminanta
    # 0.74-0.80 fata de mediana 0.36), deci pragul la 0.6 nu are ce prinde
    # altceva.
    tex = None
    for mat in me.materials:
        if mat and mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    tex = node.image
    assert tex is not None, "elephant: sursa n-are textura de baza"
    tw, th = tex.size
    tpx = tex.pixels[:]
    src_uv = me.uv_layers.active.data
    ivory_polys = set()
    for poly in me.polygons:
        u = sum(src_uv[li].uv[0] for li in poly.loop_indices) / poly.loop_total
        v = sum(src_uv[li].uv[1] for li in poly.loop_indices) / poly.loop_total
        i = (int((v % 1.0) * th) * tw + int((u % 1.0) * tw)) * 4
        if 0.30 * tpx[i] + 0.59 * tpx[i + 1] + 0.11 * tpx[i + 2] > 0.6:
            ivory_polys.add(poly.index)
    print("  elephant: %d fete de fildes din textura" % len(ivory_polys))
    assert 10 <= len(ivory_polys) <= 120, "elephant: fildes nerecunoscut (%d fete)" % len(ivory_polys)
    #
    # Prima varianta punea GREY_SH pe orice fata sub un prag de Z absolut,
    # fara sa ceara si lateralitate: pe langa labe a prins si burta/coada, la
    # aceeasi inaltime joasa dar aproape de axa X=0, si a iesit o banda
    # zimtata pe tot spatele in preview (masurat: 90 de fete GREY_SH cu x
    # intre -0.09 si +0.09 la y intre -1.6 si +3.35 — adica linia de mijloc a
    # corpului, nu labele).
    lo, hi = _world_bbox([mesh])
    z_low = lo.z + (hi.z - lo.z) * 0.12    # sub genunchi = labe
    # UV-uri pe sloturi, scrise direct (fara `finish()`: mesh-ul se articuleaza
    # pe schelet, deci nu trece prin bevel/bake_ao — vezi nota din antet si
    # reteta vacii in `asset-animat-pipeline`).
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        cx = sum(me.vertices[me.loops[li].vertex_index].co.x for li in poly.loop_indices) / len(poly.loop_indices)
        cz = sum(me.vertices[me.loops[li].vertex_index].co.z for li in poly.loop_indices) / len(poly.loop_indices)
        if poly.index in ivory_polys:
            slot = IVORY
        elif cz < z_low and abs(cx) > 0.35:
            slot = GREY_SH
        else:
            slot = GREY
        u = slot_u(slot)
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)

    # AO gradient vertical (fara raycast — mesh-ul o sa se articuleze pe
    # schelet, un AO copt ar ramane lipit de blana cand oasele se misca).
    for layer in list(me.color_attributes):
        me.color_attributes.remove(layer)
    ao = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="CORNER")
    lo, hi = _world_bbox([mesh])
    for poly in me.polygons:
        for li in poly.loop_indices:
            z = me.vertices[me.loops[li].vertex_index].co.z
            t = max(0.0, min(1.0, (z - lo.z) / max(hi.z - lo.z, 1e-6)))
            v = 0.42 + (1.0 - 0.42) * t
            ao.data[li].color = (v, v, v, 1.0)
    me.color_attributes.active_color = ao
    me.materials.clear()
    me.materials.append(atlas_material())
    apply_smooth(mesh, 55.0)
    print("  elephant gabarit: %.2f x %.2f x %.2f m" % (hi.x - lo.x, hi.y - lo.y, hi.z - lo.z))
    return mesh


def elephant_rig(obj):
    """Schelet peste mesh-ul IMPORTAT (sudat, o singura insula) — spre
    deosebire de reteta testoasei, aici `mesh_islands` nu ajuta (nu exista
    piese separate de Builder). Fiecare VERTEX e clasificat direct pe
    pozitia lui in bbox-ul mesh-ului (masurat dupa scalare/origine din
    `elephant_mesh`: X centrat in [-2.0, 2.0], Y in [-3.1, 3.1] cu coada pe
    -Y si trompa pe +Y, Z de la baza 0 pana la varful capului ~4.6 m).
    Greutatea ramane RIGIDA (un elefant de jucarie nu se indoaie): fiecare
    vertex cade intr-un singur os, fara ramp intre zone — mesh-ul continuu nu
    are muchia naturala de insula care sa ascunda o tranzitie brusca, si o
    tranzitie vazuta e mai putin rea decat un poligon rupt intre doua oase.
    """
    me = obj.data
    lo, hi = _world_bbox([obj])
    sy, sz = hi.y - lo.y, hi.z - lo.z
    y_tail, y_headstart, y_trunk = lo.y + sy * 0.12, lo.y + sy * 0.62, lo.y + sy * 0.84
    z_knee = lo.z + sz * 0.34
    x_ear = 0.55
    # Trompa ATARNA (sursa importata), nu iese inainte ca la elefantul vechi din
    # Builder: masurat pe varfurile de langa axa, la 86-94% din lungime, de la
    # sol pana la ~50% din inaltime. Se imparte deci pe INALTIME, nu pe Y, iar
    # oasele ei stau verticale pe Y-ul masurat al trompei.
    z_trunk1, z_trunk2 = lo.z + sz * 0.48, lo.z + sz * 0.25
    x_trunk = 0.30
    tip = [v.co.y for v in me.vertices
           if abs(v.co.x) < x_trunk and v.co.y >= y_trunk and v.co.z < z_trunk2]
    assert tip, "elephant: niciun varf de trompa sub %.2f m" % z_trunk2
    y_tr = sum(tip) / len(tip)
    # Fildesii (sloturile IVORY, alese din textura in `elephant_mesh`) stau la
    # aceeasi inaltime cu radacina trompei si pe jumatate sub |x| < 0.35: fara
    # exceptia asta s-ar fi legat de trompa si s-ar fi ridicat cu ea.
    uvd = me.uv_layers.active.data
    ivory_verts = set()
    for poly in me.polygons:
        if int(round(uvd[poly.loop_indices[0]].uv[0] * SLOTS - 0.5)) == IVORY:
            ivory_verts.update(poly.vertices)

    bones = [
        dict(name="Body", head=(0, lo.y + sy * 0.30, lo.z + sz * 0.55),
             tail=(0, lo.y + sy * 0.62, lo.z + sz * 0.55)),
        dict(name="Head", head=(0, y_headstart, lo.z + sz * 0.62),
             tail=(0, y_trunk, lo.z + sz * 0.55), parent="Body"),
        dict(name="Trunk1", head=(0, y_tr, z_trunk1),
             tail=(0, y_tr, z_trunk2), parent="Head"),
        dict(name="Trunk2", head=(0, y_tr, z_trunk2),
             tail=(0, y_tr, lo.z + sz * 0.02), parent="Trunk1"),
        dict(name="Tail", head=(0, lo.y + sy * 0.05, lo.z + sz * 0.55),
             tail=(0, lo.y, lo.z + sz * 0.22), parent="Body"),
    ]
    for sx, side in ((-1.0, "L"), (1.0, "R")):
        bones.append(dict(name="Ear" + side, head=(sx * 0.5, y_headstart + sy * 0.06, lo.z + sz * 0.68),
                          tail=(sx * x_ear * 3.2, y_headstart, lo.z + sz * 0.48), parent="Head"))
        bones.append(dict(name="LegF" + side, head=(sx * 0.75, lo.y + sy * 0.58, z_knee + sz * 0.10),
                          tail=(sx * 0.75, lo.y + sy * 0.58, lo.z), parent="Body"))
        bones.append(dict(name="LegR" + side, head=(sx * 0.75, lo.y + sy * 0.18, z_knee + sz * 0.10),
                          tail=(sx * 0.75, lo.y + sy * 0.18, lo.z), parent="Body"))
    arm = make_armature("Elephant", bones, mesh=obj)

    # Picioarele NU se recunosc doar pe |x| lateral: piciorul din fata e mai
    # aproape de axa centrala decat cel din spate (masurat: x intre 0.1 si
    # 0.9 la orice z, de la laba pana la umar), deci un prag fix de |x| il
    # taia pe la mijloc — jumatatea cu |x| mic cadea pe Trunk/Head si se
    # smucea cu -55 grade la Trumpet, rupta vizibil de restul labei.
    #
    # Fereastra corecta e pe Y: picioarele ocupa DOUA clustere Y departate
    # care nu se suprapun cu NIMIC altceva sub genunchi la acelasi Y (corpul
    # central e intre ele). Masurat cu capul pe +Y (#502), in fractii de
    # lungime: spate [0.10, 0.25], fata [0.50, 0.65], iar dincolo de 0.85
    # sub genunchi e doar trompa — fereastra din fata se opreste la 0.75 ca
    # varful trompei sa nu devina picior. (Ferestrele vechi, [0.12, 0.50] si
    # [0.58, 0.90], fusesera masurate pe mesh-ul intors.) In fereastra de Y a
    # unui picior, tot ce e sub genunchi apartine piciorului — deci testul e
    # pe Y dintai, cu Z doar ca sa desparta laba (jos) de umar (sus, Body).
    y_back_lo, y_back_hi = lo.y + sy * 0.09, lo.y + sy * 0.35
    y_front_lo, y_front_hi = lo.y + sy * 0.42, lo.y + sy * 0.75

    def leg_at(y_lo, y_hi, prefix):
        def test(x, y, z):
            if not (y_lo <= y <= y_hi):
                return None
            if z >= z_knee:
                return None  # umarul/soldul: ramane Body
            return prefix + ("L" if x < 0 else "R")
        return test

    leg_tests = [leg_at(y_back_lo, y_back_hi, "LegR"), leg_at(y_front_lo, y_front_hi, "LegF")]

    def classify(co, idx):
        x, y, z = co.x, co.y, co.z
        for test in leg_tests:
            name = test(x, y, z)
            if name:
                return name
        # Trompa e ingusta (aproape de X=0) — fara conditia asta, umarul lat
        # din fata (|x| mare, y in zona trompei) intra pe Trunk1/Trunk2.
        if abs(x) < x_trunk and y >= y_trunk and idx not in ivory_verts:
            if z < z_trunk2:
                return "Trunk2"
            if z < z_trunk1:
                return "Trunk1"
        if y >= y_headstart:
            if abs(x) > x_ear and z > lo.z + sz * 0.40:
                return "EarL" if x < 0 else "EarR"
            # Capul e la fel de ingust ca urechea (x_ear): geometria mai
            # lata din aceeasi banda de Y e umar/corp care se largeste spre
            # picior, nu cap — ramasa pe Head se smucea cu Trumpet (masurat:
            # x pana la 1.16 la z=1.7-1.9, in plina zona de tranzitie umar).
            if abs(x) < x_ear:
                return "Head"
        if y <= y_tail and abs(x) < 0.35:
            return "Tail"
        return "Body"

    counts = {}
    for v in me.vertices:
        name = classify(v.co, v.index)
        counts[name] = counts.get(name, 0) + 1
        weight_ramp(obj, [v.index], name, "Body", (lambda c: 1.0) if name != "Body" else None,
                    0.0, 0.5 if name != "Body" else 1.0)
    expect = {"Body", "Head", "Trunk1", "Trunk2", "Tail", "EarL", "EarR",
              "LegFL", "LegFR", "LegRL", "LegRR"}
    assert set(counts) == expect, "piese nerecunoscute/lipsa: %r" % counts
    print("  varfuri pe oase:", counts)
    return arm


def _rot(x=0.0, y=0.0, z=0.0):
    return (Matrix.Rotation(math.radians(z), 3, "Z")
            @ Matrix.Rotation(math.radians(y), 3, "Y")
            @ Matrix.Rotation(math.radians(x), 3, "X"))


def _key(arm, frame, pose):
    for name, ops in pose.items():
        pb = arm.pose.bones[name]
        if not isinstance(ops, list):
            ops = [ops]
        for kind, val in ops:
            if kind == "rot":
                pose_rotate(pb, val)
                pb.keyframe_insert("rotation_quaternion", frame=frame)
            else:
                pose_move(pb, val)
                pb.keyframe_insert("location", frame=frame)


def elephant_animate(arm):
    scene = bpy.context.scene
    scene.render.fps = 24
    if arm.animation_data is None:
        arm.animation_data_create()
    # WALK, 36 de cadre = 1,5 s: perechi diagonale, corpul salta putin, trompa
    # si urechile leagana in contratimp.
    walk = bpy.data.actions.new("Walk")
    arm.animation_data.action = walk
    for k, t in enumerate((0.0, 0.25, 0.5, 0.75, 1.0)):
        frame = 1 + int(t * 36)
        s = math.sin(t * 2 * math.pi)
        c = math.cos(t * 2 * math.pi)
        pose = {
            "LegFL": ("rot", _rot(x=14.0 * s)), "LegRR": ("rot", _rot(x=14.0 * s)),
            "LegFR": ("rot", _rot(x=-14.0 * s)), "LegRL": ("rot", _rot(x=-14.0 * s)),
            "Body": [("move", Vector((0, 0, 0.04 * abs(c)))), ("rot", _rot(z=2.0 * s))],
            "Head": ("rot", _rot(x=2.0 * c, z=-3.0 * s)),
            "Trunk1": ("rot", _rot(x=6.0 * c)), "Trunk2": ("rot", _rot(x=8.0 * c)),
            "EarL": ("rot", _rot(y=6.0 * s)), "EarR": ("rot", _rot(y=-6.0 * s)),
            "Tail": ("rot", _rot(z=10.0 * s)),
        }
        _key(arm, frame, pose)
    # TRUMPET, 36 de cadre: capul sus, trompa ridicata, urechile desfacute, apoi revine.
    # `pose_rotate` lucreaza pe axele armaturii: in jurul lui +X, un unghi
    # POZITIV duce spre +Y (in fata) ce atarna si ridica ce sta in fata.
    # Semnele erau negative cat timp capul fusese de fapt pe -Y (#502).
    tr = bpy.data.actions.new("Trumpet")
    arm.animation_data.action = tr
    for frame, amt in ((1, 0.0), (10, 1.0), (24, 1.0), (37, 0.0)):
        pose = {
            "Head": ("rot", _rot(x=14.0 * amt)),
            "Trunk1": ("rot", _rot(x=55.0 * amt)), "Trunk2": ("rot", _rot(x=45.0 * amt)),
            "EarL": ("rot", _rot(y=32.0 * amt, z=10.0 * amt)), "EarR": ("rot", _rot(y=-32.0 * amt, z=-10.0 * amt)),
            "Body": [("move", Vector((0, 0, 0.0))), ("rot", _rot(x=2.0 * amt))],
            "LegFL": ("rot", _rot()), "LegFR": ("rot", _rot()), "LegRL": ("rot", _rot()), "LegRR": ("rot", _rot()),
            "Tail": ("rot", _rot(x=8.0 * amt)),
        }
        _key(arm, frame, pose)
    stash_actions(arm, ("Walk", "Trumpet"))
    for pb in arm.pose.bones:
        pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
        pb.location = (0.0, 0.0, 0.0)


def build_elephant():
    obj = elephant_mesh()
    arm = elephant_rig(obj)
    elephant_animate(arm)
    bpy.context.view_layer.update()
    d = obj.dimensions
    print("  elephant: %d tris, %.2f lat x %.2f lung x %.2f inalt" % (tri_count(obj), d.x, d.y, d.z))
    return arm, obj


# ------------------------------------------------------------- hipopotam, crocodil

def build_hippo():
    """Hipopotam INTREG, importat (low_poly_hippo.glb, Sketchfab, 378 tri).

    Inlocuieste spinarea procedurala din `rock`/`boulder` (PR #376). Motivul e
    verdictul de la volan notat in `HippoHazard`: „hipopotamii arata ca niste
    bolovani" — si chiar erau, literal, trei `rock` si sase `boulder` din
    acelasi generator care face stancile de kopje. Nicio reglare de slot nu
    putea repara o SILUETA de bolovan (memoria `silueta-inainte-de-umbrire`:
    masoara profilul inainte de lumina); diferenta o face un mesh cu bot,
    urechi si crupa de hipopotam.

    **Numele fisierului ramane `hippo_back.glb` si gabaritul ramane cel vechi**
    (2,5 x 4,8 x 1,35 m, origine la baza), fiindca HippoHazard asaza modelul cu
    VARFUL spinarii la `rest_top` si coboara restul sub albie. Din apa se vede
    tot ce e deasupra liniei apei — spinarea, capul; picioarele stau sub albie,
    exact ca la un hipopotam adevarat in vad. Deci mecanica (ciclu, coliziune
    elipsoidala, rise_m) NU se schimba: assetul e pur vizual.

    Sursa e Z-up ca Blender, dar cu capul pe -Y si de 10 m lungime. Aici se
    intoarce pe +Y (= -Z in Godot, contractul din antet) si se scaleaza la
    lungimea ceruta. Fara `import_static`: aia presupune o armatura (assert
    len(arms) == 1), iar modelul asta n-are schelet.
    """
    _wipe()
    bpy.ops.import_scene.gltf(filepath=PACK_HIPPO)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    assert len(meshes) == 1, "asteptam 1 mesh: %r" % [m.name for m in meshes]
    mesh = meshes[0]
    mesh.name = "Hippo_Back"
    bpy.context.view_layer.objects.active = mesh
    mesh.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Sensul: capul pe +Y. Martorul e BOTUL — varfurile cele mai departate pe
    # Y, la inaltime mica (botul unui hipopotam sta jos, sub linia spinarii),
    # fata de crupa care e masiva si inalta. Masurat pe sursa: capul la
    # y = -5.09, coada la y = +4.95. Se rotesc VARFURILE, nu obiectul —
    # `transform_apply` e un no-op in --background (nota lunga din
    # `import_static`, cinci runde pierdute pe ea).
    me = mesh.data
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    z_lo = min(zs) + (max(zs) - min(zs)) * 0.55   # sub linia spinarii
    snout = [v.co.y for v in me.vertices if v.co.z < z_lo]
    # Capul e capatul cu masa JOASA cea mai departata de centru.
    y_head = min(snout) if abs(min(snout)) > abs(max(snout)) else max(snout)
    if y_head < 0.0:
        rot = Matrix.Rotation(math.pi, 4, "Z")
        for v in me.vertices:
            v.co = rot @ v.co
        me.update()
        print("  hipopotam: capul era spre -Y, am intors varfurile cu pi")

    # Scara pe LUNGIME (Y), ca gabaritul sa iasa cel din contract. Se scriu
    # varfurile direct, din acelasi motiv ca rotatia de mai sus.
    lo, hi = _world_bbox([mesh])
    s = HIPPO_LENGTH / (hi.y - lo.y)
    for v in me.vertices:
        v.co *= s
    me.update()

    # Textura sursei se arunca: culoarea vine din atlas, nu per asset
    # (CLAUDE.md). Fetele se pun pe UN SINGUR slot, prin atributul `slot` —
    # NU prin UV-uri. `finish()` face bevel si abia apoi scrie UV-urile din
    # `snapshot_slots`, deci UV-uri puse aici ar fi oricum suprascrise, iar
    # banda de bevel n-ar sti ce culoare sa ia.
    #
    # DE CE UN SINGUR SLOT, fara accentul cald de pe bot. Vechea spinare avea
    # botul pe HIPPO_PINK (KERB_RED), si prima varianta de aici l-a pastrat, pe
    # ultimii 12% spre cap. Masurat pe captura de la nivelul drumului (vad,
    # ochi la 1,3 m, hipopotamii SUS): botul iesea rgb(147,65,27) fata de corp
    # rgb(95,67,45) — cu 55% mai mult rosu si vizibil mai cald, adica se citea
    # ca o RANA, nu ca piele. Pe bolovanul vechi mergea fiindca era o movila
    # mica si rotunda; pe un bot adevarat, intors spre camera, aceeasi culoare
    # ocupa o fata plata si sare in ochi. Slotul de accent ramane definit
    # (HIPPO_PINK) ca sa fie clar ca lipsa lui e o alegere, nu o scapare.
    attr = me.attributes.get("slot") or me.attributes.new(
        name="slot", type="INT", domain="FACE")
    for poly in me.polygons:
        attr.data[poly.index].value = HIPPO
    me.materials.clear()
    me.materials.append(atlas_material())
    lo, hi = _world_bbox([mesh])
    print("  hipopotam: %d tris, %.2f lat x %.2f lung x %.2f inalt (slot unic)"
          % (tri_count(mesh), hi.x - lo.x, hi.y - lo.y, hi.z - lo.z))
    return mesh


def build_crocodile():
    b = Builder()
    b.taper_sweep([Vector((0, -2.0, 0.22)), Vector((0, -1.0, 0.3)), Vector((0, 0.4, 0.34)), Vector((0, 1.1, 0.3))],
                  [0.05, 0.22, 0.34, 0.28], CROC, segments=7)
    b.box((0.0, 0.2, 0.18), (0.62, 2.0, 0.18), CROC_BELLY)
    # bot lung, plat
    b.taper_sweep([Vector((0, 1.05, 0.3)), Vector((0, 1.7, 0.27)), Vector((0, 2.05, 0.24))],
                  [0.26, 0.2, 0.12], CROC, segments=5)
    for sx in (-0.18, 0.18):
        b.boulder((sx, 1.05, 0.5), (0.14, 0.14, 0.14), CROC_BELLY, seed=701, segments=5, rings=3, deviation=0.04)
    for sx in (-1.0, 1.0):
        for y in (0.7, -0.5):
            b.beam((sx * 0.3, y, 0.25), (sx * 0.62, y - 0.15, 0.1), 0.09, CROC)
            b.box((sx * 0.7, y - 0.2, 0.06), (0.22, 0.26, 0.1), CROC)
    # creste pe spate
    for k in range(7):
        b.box((0.0, -1.5 + k * 0.4, 0.5 + (0.05 if k > 2 else 0.0)), (0.12, 0.2, 0.14), ROCK_DARK)
    return b.to_object("Crocodile")



# --------------------------------------------------------------- garda de sens

## Capul TREBUIE sa iasa pe +Y in Blender (= -Z in Godot, verificat cu un marker
## exportat: Blender +Y -> Godot -Z). Se masoara pe SLOTURILE care exista doar
## in cap, nu pe masa de sus: la gnu coada e ridicata aproape cat greabanul,
## deci orice euristica de "masa sus" cade pe coada (capcana documentata si in
## build_cow_animated.py). Sloturi de cap: coarne (SAND_LIGHT) si ochi
## (ASPHALT / FOAM_WHITE) la gnu; la zebra nu exista slot doar-de-cap, deci se
## verifica pe BOT (VOLCANIC_BLACK sub mediana) — vezi apelul.
def assert_head_plus_y(obj, head_slots, label):
    me = obj.data
    uv = me.uv_layers.active.data
    ys, n = 0.0, 0
    for poly in me.polygons:
        slot = int(round(uv[poly.loop_indices[0]].uv[0] * SLOTS - 0.5))
        if slot not in head_slots:
            continue
        for li in poly.loop_indices:
            # `co` brut, nu `matrix_world @ co` — vezi nota din import_static:
            # matricea nu se actualizeaza nici dupa transform_apply.
            ys += me.vertices[me.loops[li].vertex_index].co.y
            n += 1
    assert n, "%s: niciun varf pe sloturile de cap %s" % (label, head_slots)
    y = ys / n
    print("  %s: piesele de cap la y=%+.3f (trebuie > 0)" % (label, y))
    assert y > 0.0, ("%s: capul a iesit pe -Y (deci +Z in Godot, turma merge cu "
                     "spatele): y=%.3f" % (label, y))


results = []


def emit(obj, path, ao, origin="base", bevel=0.02, objs=None):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb(objs or [obj], "serengeti/" + path)
    results.append((path, st["tris"], sz / 1024.0))


clear_built()
gnu = build_wildebeest()
assert_head_plus_y(gnu, {SAND_LIGHT, ASPHALT}, "wildebeest")
_, sz = export_glb([gnu], "serengeti/animals/wildebeest.glb")
results.append(("animals/wildebeest.glb", tri_count(gnu), sz / 1024.0))
zeb = build_zebra()
# Zebra n-are slot doar-de-cap: are doar alb si negru. Capul se recunoaste pe
# GATUL ridicat — varfurile cele mai INALTE ale zebrei sunt coama/gat, si ele
# stau spre cap.
_zme = zeb.data
# `co` brut (vezi nota din import_static): matrix_world nu reflecta rotatiile
# deja coapte in varfuri.
_ztop = [v.co for v in _zme.vertices]
_zz = max(v.z for v in _ztop)
_zhead = [v for v in _ztop if v.z >= _zz - 0.25]
_zy = sum(v.y for v in _zhead) / len(_zhead)
print("  zebra: gatul (varfuri sus) la y=%+.3f (trebuie > 0)" % _zy)
assert _zy > 0.0, "zebra: capul a iesit pe -Y (deci +Z in Godot): y=%.3f" % _zy
_, sz = export_glb([zeb], "serengeti/animals/zebra.glb")
results.append(("animals/zebra.glb", tri_count(zeb), sz / 1024.0))

_wipe()
arm, ele = build_elephant()
_, sz = export_glb([arm, ele], "serengeti/animals/elephant.glb", animations=True)
results.append(("animals/elephant.glb", tri_count(ele), sz / 1024.0))
save_blend([arm, ele], "elephant.blend", compress=True)

clear_built()
emit(build_hippo(), "animals/hippo_back.glb", AO_BIG, bevel=0.03)
emit(build_crocodile(), "animals/crocodile.glb", AO_ANIMAL, bevel=0.012)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL animale: %d tris" % sum(t for _, t, _ in results))
