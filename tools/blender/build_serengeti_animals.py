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

PACK_ULTIMATE = (r"D:\GameDev\downloaded assets"
                 r"\Ultimate Animated Animals - July 2021-20260813T155229Z-1-001"
                 r"\Ultimate Animated Animals - July 2021\glTF\Bull.gltf")
PACK_FARM = r"D:\GameDev\downloaded assets\Farm Animal Pack-glb\Zebra.glb"

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
    b = Builder()
    # corp
    b.boulder((0.0, 0.0, 2.15), (2.3, 3.7, 2.3), GREY, seed=501, segments=9, rings=5, deviation=0.05)
    # cap + frunte bombata
    b.boulder((0.0, 2.25, 2.55), (1.6, 1.6, 1.7), GREY, seed=507, segments=8, rings=4, deviation=0.05)
    # trompa in doua bucati (doua oase)
    b.taper_sweep([Vector((0, 2.95, 2.15)), Vector((0, 3.35, 1.55)), Vector((0, 3.45, 1.15))],
                  [0.30, 0.24, 0.20], GREY, segments=7)
    b.taper_sweep([Vector((0, 3.45, 1.15)), Vector((0, 3.40, 0.60)), Vector((0, 3.25, 0.12))],
                  [0.20, 0.16, 0.12], GREY, segments=6)
    # urechi: lamele mari, aproape verticale, in spatele ochilor
    for sx in (-1.0, 1.0):
        b.blade([Vector((sx * 0.72, 2.05, 2.75)), Vector((sx * 1.45, 1.95, 2.6)), Vector((sx * 1.7, 1.8, 1.9))],
                [0.9, 1.3, 0.6], 0.08, GREY_SH, up=(0, 0, 1))
    # fildesi
    for sx in (-1.0, 1.0):
        b.taper_sweep([Vector((sx * 0.38, 2.9, 1.85)), Vector((sx * 0.45, 3.6, 1.55)), Vector((sx * 0.42, 4.15, 1.75))],
                      [0.12, 0.09, 0.03], IVORY, segments=5)
    # picioare: coloane
    for sx in (-0.7, 0.7):
        for sy in (1.15, -1.2):
            b.cylinder((sx, sy, 0.78), 0.36 if sy > 0 else 0.33, 1.56, GREY, segments=7)
            b.cylinder((sx, sy, 0.10), 0.40 if sy > 0 else 0.37, 0.20, GREY_SH, segments=7)
    # coada
    b.taper_sweep([Vector((0, -1.85, 2.3)), Vector((0, -2.15, 1.6)), Vector((0, -2.2, 1.0))],
                  [0.07, 0.05, 0.08], GREY_SH, segments=4)
    return b.to_object("Elephant_Mesh")


def elephant_rig(obj, shift):
    def P(x, y, z):
        return Vector((x, y, z)) + shift
    bones = [
        dict(name="Body", head=P(0, -1.0, 2.15), tail=P(0, 1.0, 2.15)),
        dict(name="Head", head=P(0, 1.55, 2.5), tail=P(0, 2.9, 2.4), parent="Body"),
        dict(name="Trunk1", head=P(0, 2.95, 2.15), tail=P(0, 3.45, 1.15), parent="Head"),
        dict(name="Trunk2", head=P(0, 3.45, 1.15), tail=P(0, 3.25, 0.12), parent="Trunk1"),
        dict(name="Tail", head=P(0, -1.85, 2.3), tail=P(0, -2.2, 1.0), parent="Body"),
    ]
    for sx, side in ((-1.0, "L"), (1.0, "R")):
        bones.append(dict(name="Ear" + side, head=P(sx * 0.7, 2.05, 2.75), tail=P(sx * 1.7, 1.8, 1.9), parent="Head"))
        bones.append(dict(name="LegF" + side, head=P(sx * 0.7, 1.15, 1.6), tail=P(sx * 0.7, 1.15, 0.0), parent="Body"))
        bones.append(dict(name="LegR" + side, head=P(sx * 0.7, -1.2, 1.6), tail=P(sx * 0.7, -1.2, 0.0), parent="Body"))
    arm = make_armature("Elephant", bones, mesh=obj)
    counts = {}
    for island in mesh_islands(obj):
        lo, hi = island_bbox(obj, island)
        c = (lo + hi) * 0.5 - shift
        size = hi - lo
        if c.z < 1.7 and abs(c.y) < 1.6 and abs(c.x) > 0.3:
            name = "Leg" + ("F" if c.y > 0 else "R") + ("L" if c.x < 0 else "R")
        elif abs(c.x) > 0.7 and c.y > 1.4:
            name = "Ear" + ("L" if c.x < 0 else "R")
        elif c.y > 2.9 and c.z < 1.0:
            name = "Trunk2"
        elif c.y > 2.9 and abs(c.x) < 0.2 and c.z < 1.9:
            name = "Trunk1"
        elif c.y < -1.5:
            name = "Tail"
        elif c.y > 1.4:
            name = "Head"
        else:
            name = "Body"
        # greutate RIGIDA pe os (un elefant de jucarie nu se indoaie): value
        # constant 1 peste prag; `None` e permis doar cand osul e chiar radacina.
        if name == "Body":
            weight_ramp(obj, island, "Body", "Body", None, 0.0, 1.0)
        else:
            weight_ramp(obj, island, name, "Body", lambda co: 1.0, 0.0, 0.5)
        counts[name] = counts.get(name, 0) + 1
    expect = {"Body", "Head", "Trunk1", "Trunk2", "Tail", "EarL", "EarR",
              "LegFL", "LegFR", "LegRL", "LegRR"}
    assert set(counts) == expect, "piese nerecunoscute/lipsa: %r" % counts
    print("  insule pe oase:", counts)
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
    tr = bpy.data.actions.new("Trumpet")
    arm.animation_data.action = tr
    for frame, amt in ((1, 0.0), (10, 1.0), (24, 1.0), (37, 0.0)):
        pose = {
            "Head": ("rot", _rot(x=-14.0 * amt)),
            "Trunk1": ("rot", _rot(x=-55.0 * amt)), "Trunk2": ("rot", _rot(x=-45.0 * amt)),
            "EarL": ("rot", _rot(y=32.0 * amt, z=10.0 * amt)), "EarR": ("rot", _rot(y=-32.0 * amt, z=-10.0 * amt)),
            "Body": [("move", Vector((0, 0, 0.0))), ("rot", _rot(x=-2.0 * amt))],
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
    lo0, hi0 = island_bbox(obj, range(len(obj.data.vertices)))
    stats = finish(obj, bevel=0.03, origin="base", ao=AO_BIG)
    lo1, hi1 = island_bbox(obj, range(len(obj.data.vertices)))
    shift = Vector((((lo1 + hi1) - (lo0 + hi0)).x * 0.5, ((lo1 + hi1) - (lo0 + hi0)).y * 0.5, lo1.z - lo0.z))
    arm = elephant_rig(obj, shift)
    elephant_animate(arm)
    bpy.context.view_layer.update()
    d = obj.dimensions
    print("  elephant: %d tris, %.2f lat x %.2f lung x %.2f inalt" % (stats["tris"], d.x, d.y, d.z))
    return arm, obj


# ------------------------------------------------------------- hipopotam, crocodil

def build_hippo():
    """Spinare + cap, 4 x 2,5 m, 1,5 m inalt: `rock` cu capac plat jos (sta in
    apa), cap bombat cu ochi si urechi sus — ce iese primul din apa."""
    b = Builder()
    b.rock((0.0, -0.4, 0.0), (2.5, 3.2, 1.35), HIPPO, seed=601, segments=9, rings=4, taper=0.45)
    b.rock((0.0, 1.5, 0.0), (1.7, 1.9, 1.15), HIPPO, seed=607, segments=8, rings=4, taper=0.35)
    b.boulder((0.0, 2.35, 0.55), (1.3, 0.9, 0.75), HIPPO_PINK, seed=611, segments=7, rings=3, deviation=0.05)
    for sx in (-0.5, 0.5):
        b.boulder((sx, 1.05, 1.2), (0.22, 0.2, 0.24), HIPPO, seed=620, segments=5, rings=3, deviation=0.04)
        b.boulder((sx * 1.2, 1.55, 1.05), (0.26, 0.22, 0.2), HIPPO, seed=625, segments=5, rings=3, deviation=0.04)
        b.boulder((sx * 0.7, 2.7, 0.75), (0.16, 0.14, 0.14), HIPPO, seed=630, segments=5, rings=3, deviation=0.04)
    return b.to_object("Hippo_Back")


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
