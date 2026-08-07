"""train.glb — garnitura de tren pentru trecerea la nivel (TrainHazard).

Primul asset din proiect care NU e modelat procedural: geometria vine din
**Train Pack** de @Quaternius (CC0), vendorizat in
`assets/blender/vendor/train_pack/`. Regula "sursa reala e scriptul" ramane
respectata — scriptul asta e sursa, doar ca opereaza pe un OBJ importat in loc
sa construiasca dintr-un Builder. Ce face el, si de aia exista:

  1. **aduce modelul in paleta.** Pachetul vine cu materialele lui (Black, Grey,
     DarkWood...). Le mapeaza pe sloturi din palette_atlas si colapseaza UV-urile
     pe centrul slotului — contractul din docs/blender_export.md. Rezultat: zero
     materiale noi in garda, trenul se randeaza cu acelasi material ca tot restul
     lumii (`Palette.apply_world_material`).
  2. **coace AO in vertex colors**, ca orice prop din proiect.
  3. **intoarce piesele cu botul pe +X.** In pachet locomotiva priveste spre -X
     (varful de plug la x=-4.5, cabina la +3.5), iar `TrainHazard` deplaseaza
     garnitura spre +X local. Fara rotatia asta trenul ar traversa cu spatele.

Contract cu Godot (`scenes/hazards/train_hazard.gd`):
  - trei noduri de radacina in GLB: `Train_Loco`, `Train_Tender`, `Train_Wagon`
  - lungimea fiecarei piese pe X, botul spre +X, baza rotilor la y=0
  - originea in centrul XY, ca hazardul sa aseze piesele dupa AABB masurat

Rulare (Blender, namespace comun cu dio_lib — vezi assets/blender/README.md):
    g = {"__name__": "__main__",
         "__file__": r"<repo>/tools/blender/dio_lib.py"}
    exec(open(r"<repo>/tools/blender/dio_lib.py").read(), g)
    exec(open(r"<repo>/tools/blender/build_train.py").read(), g)
"""

import bpy
import math
import os

VENDOR = os.path.join(PROJECT, "assets", "blender", "vendor", "train_pack")

# --- Materialele pachetului -> sloturi de paleta -----------------------------
#
# Locomotiva e negru-carbune in referinta. ASPHALT (5) e cel mai inchis slot din
# paleta si, prin regula de citire din style_bible §1, nimic din scena n-are voie
# sa fie mai inchis decat asfaltul — deci exact acolo se opreste si trenul.
# ASPHALT_EDGE (6) e cu un ton mai deschis: cazanul si acoperisul cabinei.
#
# Vagonul de lemn: cadrul si sipcile au nevoie de DOUA maro-uri care se despart
# la 60 km/h. Paleta desertului are un singur slot de lemn (9), asa ca al doilea
# vine din familia de roca — ROCK_DARK (4, #67421F) e cel mai inchis maro
# disponibil. Nu e un abuz de semantica, e alegerea culorii: sloturile sunt
# culori, iar textura de suprafata o aduce oricum stratul de detaliu comun.
#
# Rama metalica a vagonului: PAINTED (11, #7692A8), decis prin A/B in cadru de
# joc, nu din tabel. Prima varianta o punea pe CONCRETE (8, #C8BDA9), adica fix
# luminanta nisipului — vagoanele se topeau in fundal si trenul se citea doar
# prin locomotiva neagra. Gri-albastrul e singura racoare din paleta desertului
# si desparte garnitura de tot ce e in jurul ei, cu saturatie 0.29 (sub pragul
# de 0.45-0.60 al mediului din style_bible §1), deci nu intra in competitie cu
# masinile. Acoperisul ramane deschis — vezi `roof_apart`.
def roof_apart(obj, cut=0.78, slot=CONCRETE):
    """Ridica acoperisul vagonului intr-un slot deschis, separat de rama.

    In pachet, rama metalica si acoperisul sunt acelasi material (`Grey`), deci
    orice mapare simpla le da aceeasi culoare. Masurat pe geometrie, cele doua
    se despart curat pe inaltime: acoperisul sta la 0.8-1.0 din inaltimea
    vagonului, stalpii se opresc la 0.7. Taietura la 0.78 nu e ghicita.

    De ce merita cei zece randuri: pe garnitura toata dintr-o culoare, vagonul
    citea ca o cutie. Cu acoperis deschis peste rama vopsita si lemn intre ele,
    silueta are trei trepte de luminanta — se vede DE DEPARTE ca e un tren, care
    e exact ce trebuie sa faca avertizarea gimmick-ului.
    """
    me = obj.data
    zs = [v.co.z for v in me.vertices]
    z_lo, z_hi = min(zs), max(zs)
    line = z_lo + (z_hi - z_lo) * cut
    attr = me.attributes["slot"]
    moved = 0
    for poly in me.polygons:
        center = sum((me.vertices[i].co.z for i in poly.vertices),
                     0.0) / len(poly.vertices)
        if center >= line and attr.data[poly.index].value == PAINTED:
            attr.data[poly.index].value = slot
            moved += 1
    return moved


UNITS = [
    {
        "src": "Locomotive_Front",
        "name": "Train_Loco",
        "slots": {"Black": ASPHALT, "Grey": ASPHALT_EDGE},
    },
    {
        "src": "Locomotive_CoalTender",
        "name": "Train_Tender",
        "slots": {"Black": ASPHALT, "Grey": ASPHALT_EDGE},
    },
    {
        "src": "Locomotive_Wagon",
        "name": "Train_Wagon",
        "slots": {"Black": ASPHALT, "Grey": PAINTED,
                  "DarkWood": ROCK_DARK, "LightWood": WOOD},
        "refine": roof_apart,
    },
]

# AO-ul unui vehicul nu e cel al unei cladiri: n-are fundatie, deci gradientul
# vertical trebuie sa fie bland (0.62, nu 0.40) — altfel rotile si sasiul intra
# in negru si silueta se rupe in doua. `dist` mic: ocluzia care conteaza aici e
# cea locala (sub streasina cabinei, intre roti), nu cea de gabarit.
AO = dict(samples=24, dist=1.6, gradient="vertical",
          low=0.62, high=1.0, power=0.9, floor=0.22)


def import_unit(src):
    """Importa un OBJ din pachet si intoarce UN singur obiect, cu
    transformarile aplicate si botul intors spre +X."""
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=os.path.join(VENDOR, src + ".obj"),
                          forward_axis="NEGATIVE_Z", up_axis="Y")
    parts = [o for o in bpy.data.objects if o not in before]
    bpy.ops.object.select_all(action="DESELECT")
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    # Importatorul lasa conversia de axe ca rotatie de OBIECT; o coacem in mesh,
    # altfel slotul, AO-ul si masuratorile ar lucra pe alte coordonate decat
    # exportul.
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.rotation_euler = (0.0, 0.0, math.pi)
    bpy.ops.object.transform_apply(rotation=True)
    return obj


def tag_slots(obj, slots):
    """Scrie slotul de paleta al fiecarei fete, dupa materialul din pachet.

    Numele materialelor primesc sufix la al doilea import in aceeasi sesiune
    (`Black.001`), deci se compara pe radacina.
    """
    me = obj.data
    by_index = []
    for mat in me.materials:
        base = (mat.name if mat else "").split(".")[0]
        if base not in slots:
            raise KeyError("material nemapat in %s: %s" % (obj.name, base))
        by_index.append(slots[base])
    attr = me.attributes.get("slot") or me.attributes.new("slot", "INT", "FACE")
    for poly in me.polygons:
        attr.data[poly.index].value = by_index[poly.material_index]


def build(unit):
    obj = import_unit(unit["src"])
    tag_slots(obj, unit["slots"])
    if "refine" in unit:
        unit["refine"](obj)
    # bevel=0: pachetul vine deja cu muchii lucrate, iar un bevel peste el ar
    # umfla triunghiurile fara sa se vada nimic. Restul lantului (UV pe sloturi,
    # smooth pe unghi, AO) e identic cu al assets-urilor proprii.
    stats = finish(obj, bevel=0.0, ao=AO, origin="base")
    obj.name = unit["name"]
    obj.data.name = unit["name"]
    me = obj.data
    size = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-14s %5d tris | %.2f x %.2f x %.2f m | AO %.2f..%.2f"
          % (obj.name, stats["tris"], size[0], size[1], size[2],
             stats["ao_min"], stats["ao_max"]))
    return obj, stats["tris"]


clear_built("Train_")
clear_built("SRC_")
built, tris = [], {}
for unit in UNITS:
    obj, count = build(unit)
    built.append(obj)
    tris[unit["name"]] = count

# Cifra care conteaza pentru bugetul pistei nu e suma pieselor din GLB, ci
# garnitura asa cum o instantiaza hazardul: locomotiva + tender + WAGON_COUNT
# vagoane (train_hazard.gd).
WAGONS = 3
consist = tris["Train_Loco"] + tris["Train_Tender"] + WAGONS * tris["Train_Wagon"]
print("garnitura (loco + tender + %d vagoane): %d triunghiuri" % (WAGONS, consist))
print("GLB:   %s (%d B)" % export_glb(built, "vehicles/train.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "train.blend"))
