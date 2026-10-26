"""Fiordland — inlocuire cruise_boat cu asset extern (caiacele kayak_a/b sunt
acum Builder, kit v2 grupa E, build_fiordland_vehicles.py; partea de canoe a fost scoasa)
(decizia dezvoltatorului, 26 sep 2026, docs/track_briefs/fiordland_stare_poi.md
decizia #2: vaporasul "cutie alba" trebuie sa citeasca vapor).

Surse externe (Sketchfab, CC-BY-4.0 — atribuire in assets/CREDITS.md):
    D:/GameDev/downloaded assets/Boats/cruise_ship_-_toofan.glb
        autor sec20ad002, 1622 tri, 3 materiale FLAT (fara textura).
    D:/GameDev/downloaded assets/Boats/canoe_-_low_poly.glb
        autor dannzjs, 6775 tri, 3 materiale (1 cu textura JPEG embedded,
        ARUNCATA — culoarea vine din atlasul de paleta, style_bible §4).

Pipeline (diferit de build_fiordland_vehicles.py: acolo geometria se
construieste cu Builder si sloturile se pun PE FETE la construire; aici
geometria vine gata facuta, deci sloturile se ataseaza per-MATERIAL, dupa
import, printr-un atribut "slot" pe fiecare fata — acelasi atribut pe care
`snapshot_slots`/`assign_uvs` il citesc mai departe, deci restul lantului
(`finish`) e neschimbat):

    import GLB -> aplica transform-urile nodurilor (bake) -> un singur mesh
    -> reorientare (axa lunga pe Blender +Y, care dupa export Y-up devine
       Godot -Z local, la fel ca vechiul cruise_boat/kayak — vezi nota AXIS)
    -> scalare la cota tinta -> origine (waterline / baza)
    -> atribut "slot" per fata, dupa materialul original
    -> assign_uvs (colapseaza UV pe centrul slotului din atlas)
    -> bake_ao -> material unic PaletteAtlas -> export GLB, ACELASI NUME
       (path identic => acelasi uid in .import => Track16.tscn ramane valid)

AXIS: gen_decor_fiord_a.gd masoara AABB-ul instantiat (dupa import Godot) si
comenteaza explicit "lungimea e pe local Z" pentru ambele modele vechi
(cruise_boat: 4,23 X x 5,5 Y x 13,97 Z; kayak: 0,58 X x 0,36 Y x 3,6 Z).
Godot importa GLB Y-up -> Z-forward direct (nicio conversie de axa in plus
fata de export_yup=True al lui Blender), deci "local Z in Godot" == "axa Y in
Blender la export" (Blender Z-up -> export Y-up muta Blender Y pe Godot Z).
Concluzie: dupa orientare, axa LUNGA a fiecarui obiect trebuie sa fie
Blender +Y, ca sa iasa Godot local Z ca inainte — transformurile existente
din Track16.tscn (yaw calculat din tangenta + PI/2, vezi comentariile din
gen_decor_fiord_a.gd) raman valide fara nicio schimbare.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_boats_reuse.py
"""

import bmesh
import math
import os
from mathutils import Matrix, Vector

SRC_DIR = r"D:/GameDev/downloaded assets/Boats"
SHIP_SRC = os.path.join(SRC_DIR, "cruise_ship_-_toofan.glb")
CANOE_SRC = os.path.join(SRC_DIR, "canoe_-_low_poly.glb")

# Sloturile legale pe Fiordland (aceleasi ca build_fiordland_vehicles.py).
BODY = FOAM_WHITE      # 22 — vaporase albe (brief: "doua vaporase albe legate")
DARK = VOLCANIC_BLACK  # 20 — geamuri / vopsea de opera moarta

AO_VEHICLE = dict(samples=22, dist=1.8, gradient="vertical",
                   low=0.60, high=1.0, power=0.9, floor=0.22)


def _import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [o for o in bpy.data.objects if o not in before]
    return imported


def _bake_transforms_to_single_mesh(objects, name):
    """Aplica transformurile de nod (parent chain) direct in coordonate de
    vertex, apoi uneste totul intr-un singur mesh. Materialele raman pe
    slotul lor de material-index — join pastreaza sloturile de material din
    fiecare obiect sursa."""
    meshes = [o for o in objects if o.type == "MESH"]
    bpy.context.view_layer.update()
    for o in meshes:
        # matrix_world contine deja tot lantul de parinti (translate/rotate/
        # scale) al fisierului Sketchfab — il "coacem" in geometrie ca sa
        # scapam de orice scara/rotatie ascunsa pe un nod parinte
        # (memoria scala-glb-neaplicata-la-radacina: verificam si aici ca
        # scara e 1.0 dupa bake, nu doar ca root-ul "arata" identitate).
        o.data.transform(o.matrix_world)
        o.matrix_world = Matrix.Identity(4)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    return obj


def _mesh_extent(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def _rotate_object_data(obj, euler_deg):
    """Roteste geometria (nu obiectul) cu unghiurile date, in jurul originii
    curente — folosit ca sa aducem axa lunga pe Blender +Y."""
    mat = (Matrix.Rotation(math.radians(euler_deg[2]), 4, "Z") @
           Matrix.Rotation(math.radians(euler_deg[1]), 4, "Y") @
           Matrix.Rotation(math.radians(euler_deg[0]), 4, "X"))
    obj.data.transform(mat)


def _scale_mesh(obj, factor):
    obj.data.transform(Matrix.Scale(factor, 4))


def _assign_slot_per_material(obj, slot_by_material_index):
    """Adauga atributul 'slot' (int, per fata) citit mai departe de
    snapshot_slots/assign_uvs — echivalentul, pentru geometrie importata, al
    slotului pus manual pe fiecare Builder.box()/prism() la constructie."""
    me = obj.data
    attr = me.attributes.get("slot")
    if attr is None:
        attr = me.attributes.new("slot", "INT", "FACE")
    for poly in me.polygons:
        attr.data[poly.index].value = slot_by_material_index.get(
            poly.material_index, 0)


def _drop_materials_keep_slot_map(obj, slot_by_material_index):
    """Retine maparea material_index -> slot INAINTE sa golim lista de
    materiale (assign_uvs/finish se asteapta la un singur material la
    final, ca in restul pipeline-ului)."""
    _assign_slot_per_material(obj, slot_by_material_index)


def process_ship():
    imported = _import_glb(SHIP_SRC)
    obj = _bake_transforms_to_single_mesh(imported, "CruiseShip")

    # Sloturile GLB (material_index in ordinea de import): 0=rosu, 1=aproape-alb,
    # 2=gri-inchis (vezi raportul de investigatie: color_15277357 rosu 184 tri,
    # color_16448250 alb 1114 tri, color_2829873 gri-inchis 324 tri). Brief:
    # "doua vaporase ALBE" (fara dunga rosie) -> rosul (vopsea de opera vie sub
    # linia de plutire pe multe vase reale) se topeste in DARK, nu ramane accent.
    _drop_materials_keep_slot_map(obj, {0: DARK, 1: BODY, 2: DARK})

    # Orientare: bbox brut (spatiu local, dupa bake) avea axa lunga pe X
    # (148 x 65.1 x 51, raport de investigatie). Vrem lungimea pe Blender +Y
    # (vezi nota AXIS din antet) -> rotatie de 90 pe Z aduce X pe Y.
    (x0, x1), (y0, y1), (z0, z1) = _mesh_extent(obj)
    ext = {"x": x1 - x0, "y": y1 - y0, "z": z1 - z0}
    long_axis = max(ext, key=ext.get)
    print("ship: extent brut X=%.3f Y=%.3f Z=%.3f, axa lunga=%s" %
          (ext["x"], ext["y"], ext["z"], long_axis))
    if long_axis == "x":
        _rotate_object_data(obj, (0.0, 0.0, 90.0))
    elif long_axis == "z":
        _rotate_object_data(obj, (90.0, 0.0, 0.0))
    # dupa rotatie, lungimea trebuie sa fie pe Y
    (x0, x1), (y0, y1), (z0, z1) = _mesh_extent(obj)
    ext = {"x": x1 - x0, "y": y1 - y0, "z": z1 - z0}
    print("ship: extent dupa rotatie X=%.3f Y=%.3f Z=%.3f" %
          (ext["x"], ext["y"], ext["z"]))
    assert ext["y"] >= ext["x"] and ext["y"] >= ext["z"], \
        "orientare gresita: lungimea tot nu e pe Y"

    # Scara: vechiul cruise_boat avea contract 14 x 4.5 x 5 m (lungime x latime
    # x inaltime), masurat instantiat 13.97 x 4.23 x 5.5 (X/Z inversate fata de
    # numerotarea Blender pentru ca modelul vechi avea deja lungimea pe local Z
    # Godot = Blender Y). Fiordul e navigabil de vase de croaziera de coasta
    # (Milford/Doubtful Sound): 14 m ramane cota tinta, nu se schimba fata de
    # asset-ul inlocuit — brief-ul si toate transformurile din
    # gen_decor_fiord_a.gd sunt calculate pe lungimea asta.
    TARGET_LEN = 14.0
    factor = TARGET_LEN / ext["y"]
    _scale_mesh(obj, factor)
    (x0, x1), (y0, y1), (z0, z1) = _mesh_extent(obj)
    ext = {"x": x1 - x0, "y": y1 - y0, "z": z1 - z0}
    print("ship: extent dupa scalare (m) X=%.3f Y=%.3f Z=%.3f" %
          (ext["x"], ext["y"], ext["z"]))

    # Origine la linia de plutire: vechiul cruise_boat avea carena coborand
    # 1,2 m sub origine (waterline la Blender/local Z=0), NU la baza — brief
    # + comentariul din build_fiordland_vehicles.py + gen_decor_fiord_a.gd
    # (`_sea_y`, fara compensare de origine la asezare). Modelul nou nu are
    # geometrie construita cu linia de plutire la Z=0, deci o fixam noi:
    # carena (partea de jos) trebuie sa fie la Z = -1.2 * factor_de_scara al
    # inaltimii totale fata de vechiul raport carena/inaltime (1.2/5.0=0.24),
    # aplicat pe inaltimea NOUA masurata (ext["z"]).
    DRAFT_FRACTION = 1.2 / 5.0
    draft = ext["z"] * DRAFT_FRACTION
    # centram XY (Blender X/Y=lat/lung -> nu conteaza fata de axa Godot dupa
    # rotatia din .tscn), coboram Z ca baza carenei sa fie la -draft
    dx = -(x0 + x1) * 0.5
    dy = -(y0 + y1) * 0.5  # centrat pe lungime (simetric prova/pupa e ok:
    # geometria navei nu e simetrica prova/pupa, dar orientarea finala vine
    # din yaw calculat in gen_decor_fiord_a.gd (paralel cu cheiul), deci un
    # centru geometric e suficient de bun — acelasi tratament ca vechiul
    # build (bbox center pe lungime, nu "centrul de greutate al carenei").
    dz = -z0 - draft
    for v in obj.data.vertices:
        v.co.x += dx
        v.co.y += dy
        v.co.z += dz
    (x0, x1), (y0, y1), (z0, z1) = _mesh_extent(obj)
    print("ship: bbox final dupa recentrare: X[%.3f,%.3f] Y[%.3f,%.3f] Z[%.3f,%.3f]"
          % (x0, x1, y0, y1, z0, z1))
    assert z0 < 0.0, "carena trebuie sa incalece Z=0 (linia de plutire)"

    snap = snapshot_slots(obj)
    apply_bevel(obj, 0.03, angle_deg=30.0)
    apply_smooth(obj, 34.0)
    assign_uvs(obj, snap)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    rng = bake_ao(obj, **AO_VEHICLE)
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    obj.name = "Boat"  # pastreaza numele de nod pe care il cauta
    # world_prop.gd:753 ("cruise_boat": {"Boat": Palette.PLAIN_PREFIX})

    tris = tri_count(obj)
    print("ship: %d tri (contract vechi 1500, buget informal, fara plafon)"
          % tris)
    print("ship: AO min/max %.3f/%.3f" % (rng[0], rng[1]))

    path, size = export_glb([obj], "fiordland/vehicles/cruise_boat.glb")
    print("export: %s (%.0f KB)" % (path, size / 1024.0))
    save_blend([obj], "fiordland_boat_v2.blend")
    return obj


clear_built()

ship = process_ship()

print("== gata: cruise_boat.glb inlocuit (caiacele sunt Builder, vezi build_fiordland_vehicles.py) ==")
