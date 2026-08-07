"""megakit_plants.glb — vegetatie de desert din Stylized Nature MegaKit
(Quaternius, CC0).

Ce lipsea: desert_scatter.glb are cinci piese sub 40 de triunghiuri (tufe
turtite, pietricele, un smoc), construite cand bugetul era "cat mai putin".
Sunt corecte ca filler, dar n-au nicio SILUETA — la 30 m in fata masinii
dispar in nisip, si banda lipita de drum ramane goala. Foaia de referinta a
kitului (Preview_3.jpg) arata ce lipseste de fapt: smocuri INALTE de iarba
uscata care rup linia solului, evantaie verzi joase, si copaci morti ca
accent vertical.

Sloturi de paleta (kitul are propriile lui texturi; noi le aruncam si punem
UV-uri colapsate pe atlas, ca orice alt prop):
  Tuft_*    Grass_*        -> DRY_VEGETATION
  Scrub_A   Bush_Common    -> DRY_VEGETATION
  Fan_*     Fern/Plant_1   -> CACTUS_GREEN
  Rosette_A Plant_7_Big    -> DRY_VEGETATION
  Dead_*    DeadTree_2/4   -> WOOD_WEATHERED

Numele de nod sunt CONTRACT, nu eticheta: `tools/probe_decor.gd` atribuie
fiecare mesh unui GLB dupa prefixul numelui de varianta, iar `bush_` era deja
luat de desert_scatter.glb. Doua biblioteci cu acelasi `Bush_A` inseamna o
garda care raporteaza costul in dreptul fisierului gresit — de aici `Scrub_A`
in loc de `Bush_A`.

DOUA FAMILII DE GEOMETRIE, si distinctia conteaza la instantiere:

  - Frunzisul (Tuft/Bush/Fan/Mat) e din FOI DESCHISE — masurat dupa sudura:
    32-80% muchii de contur. Cu backface culling, o frunza dintr-un singur
    strat dispare cand treci pe langa ea. Se instantiaza cu
    `Palette.foliage_material()` (acelasi atlas, cull dezactivat), NU cu
    materialul lumii. Alternativa era Solidify: dubleaza triunghiurile
    exact pe piesele cele mai numeroase de pe pista, ca sa economiseasca UN
    material pe toata lumea. Nu merita.
  - Copacii morti sunt corpuri INCHISE (3% contur, doar varfurile de creanga),
    deci merg pe materialul obisnuit al lumii.

Vertex colors: kitul aduce un COLOR_0 care coboara la 0.0 la baza tulpinii —
o masca de vant, nu AO. Cu `vertex_color_use_as_albedo`, bazele ar fi iesit
negre. `finish()` sterge toate atributele de culoare si coace AO-ul nostru.

Rulare (Blender, namespace comun cu dio_lib):
    g = {"__name__": "__main__", "__file__": r"<repo>/tools/blender/dio_lib.py"}
    exec(open(r"<repo>/tools/blender/dio_lib.py").read(), g)
    exec(open(r"<repo>/tools/blender/build_megakit_plants.py").read(), g)
"""

import bmesh
import bpy
import os

KIT = r"D:/GameDev/downloaded assets/Stylized Nature MegaKit[Standard]/glTF"


def _thin_islands(me, keep, seed=0):
    """Sterge o parte din FIRELE unui smoc, pastrand fractia `keep`.

    Alternativa la Decimate pentru geometria din foi separate. Un smoc de iarba
    din kit e o gramada de fire independente: Decimate ar simplifica fiecare
    fir in parte, adica ar strica exact lucrul care se vede (conturul lamelei),
    ca sa castige nimic. Sterse INTREGI, firele ramase arata identic si smocul
    isi pastreaza silueta — doar ca e mai rar. Masurat: Grass_Wispy_Tall trece
    de la 622 la ~340 de triunghiuri, iar diferenta nu se distinge de la
    inaltimea camerei de joc.

    Selectia e determinista (indexul insulei modulo pasul), nu aleatoare:
    build-ul trebuie sa dea acelasi rezultat la fiecare rulare.
    """
    if keep is None or keep >= 0.999:
        return
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.verts.ensure_lookup_table()

    # Componente conexe, parcurse in ordinea indicilor de vertex: acelasi mesh
    # da mereu aceeasi impartire.
    seen = set()
    islands = []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, comp = [v], []
        seen.add(v.index)
        while stack:
            cur = stack.pop()
            comp.append(cur)
            for e in cur.link_edges:
                other = e.other_vert(cur)
                if other.index not in seen:
                    seen.add(other.index)
                    stack.append(other)
        islands.append(comp)

    step = max(int(round(1.0 / max(1.0 - keep, 1e-6))), 2)
    doomed = []
    for i, comp in enumerate(islands):
        if (i + seed) % step == 0:
            doomed.extend(comp)
    if doomed and len(doomed) < len(bm.verts):
        bmesh.ops.delete(bm, geom=doomed, context="VERTS")
    bm.to_mesh(me)
    bm.free()

# (nume in GLB, sursa din kit, slot, inaltime tinta in metri, decimare)
#
# Inaltimea tinta NU e cea din kit. Smocurile lui sunt desenate pentru o pajiste
# vazuta de aproape (1.3-1.9 m); style_bible §2 cere obiectele cu 10-20% peste
# scara reala, dar un smoc de iarba de 1.9 m langa o masina de 1.5 m citeste ca
# stuf, nu ca desert. Copacii morti fac drumul invers: 11.5-12.8 m in kit, adusi
# la ~8.5, unde raman cel mai inalt lucru de langa sosea fara sa concureze cu
# falezele de 14 m.
#
# `decimate` (raport de colaps) doar pe copaci: 6557 si 5702 de triunghiuri
# pentru o silueta de crengi goale, iar astea sunt singurele piese din biblioteca
# destul de mari cat sa conteze in garda.
#
# 0.50 e un PRAG, gasit prin randare, nu un compromis ales din ochi. Ce se
# pierde pana acolo e SECTIUNEA crengilor subtiri, nu conturul lor — de la 20 m,
# distanta de la care se vad de fapt, un copac mort e oricum o silueta pe cer.
# Sub prag insa colapsul ataca TRUNCHIUL, care e singura suprafata continua din
# tot mesh-ul: la 0.30 baza s-a desfacut in fasii, iar coroana a ramas cu
# crengi rupte in aer. Daca vreodata trebuie taiat mai mult de aici, taie
# INSTANTE (probabilitatile din track_decor), nu triunghiuri.
#
# Frunzisul NU se colapseaza: e din foi separate, nu dintr-o suprafata continua,
# deci Decimate nu are ce simplifica — desface frunzele in cioburi.
#
# `thin` (fractia de FIRE pastrate) e echivalentul lui `decimate` pentru
# geometria din foi separate — vezi `_thin_islands`. Doar piesele dese o
# primesc: un smoc de iarba desenat pentru o pajiste vazuta de aproape are mai
# multe fire decat are nevoie unul de langa sosea, iar in banda lipita de drum
# se instantiaza de zeci de ori.
#
# (nume in GLB, sursa din kit, slot, inaltime tinta, decimare, rarire)
PLANTS = [
    # --- Frunzis: foi deschise, se instantiaza cu foliage_material ------------
    ("Tuft_A", "Grass_Common_Short", DRY_VEGETATION, 1.05, None, None),
    ("Tuft_B", "Grass_Common_Tall", DRY_VEGETATION, 1.45, None, 0.75),
    ("Tuft_C", "Grass_Wispy_Short", DRY_VEGETATION, 0.85, None, 0.55),
    ("Tuft_D", "Grass_Wispy_Tall", DRY_VEGETATION, 1.30, None, 0.55),
    ("Scrub_A", "Bush_Common", DRY_VEGETATION, 1.40, None, 0.60),
    ("Fan_A", "Fern_1", CACTUS_GREEN, 0.80, None, None),
    ("Fan_B", "Plant_1_Big", CACTUS_GREEN, 1.90, None, None),
    ("Fan_C", "Plant_1", CACTUS_GREEN, 0.90, None, None),
    ("Rosette_A", "Plant_7_Big", DRY_VEGETATION, 0.28, None, None),

    # --- Corpuri inchise: materialul obisnuit al lumii ------------------------
    ("Dead_A", "DeadTree_2", WOOD, 8.4, 0.50, None),
    ("Dead_B", "DeadTree_4", WOOD, 9.2, 0.50, None),
]

# AO mai bland decat pe stanci. Frunzisul e o masa de foi subtiri: raycast-ul
# gaseste ocluzie in aproape orice directie (fiecare frunza vede alta frunza),
# deci cu `low` de stanca toata tufa iesea o pata inchisa. `low` mare + `floor`
# mare tine gradientul acolo unde chiar se citeste — baza in umbra, varful in
# soare.
AO_LEAF = dict(samples=16, dist=0.8, gradient="vertical",
               low=0.62, high=1.00, power=0.8, floor=0.34, strength=0.55)
AO_TREE = dict(samples=20, dist=2.5, gradient="vertical",
               low=0.50, high=1.00, power=0.9, floor=0.20)


def _import(src):
    if src not in bpy.data.objects:
        bpy.ops.import_scene.gltf(filepath=os.path.join(KIT, src + ".gltf"))
    return bpy.data.objects[src]


def _prepare(name, src, slot, height, decimate, thin):
    """Copie a sursei, scalata pe inaltime, etichetata pe un singur slot."""
    orig = _import(src)
    me = orig.data.copy()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    # Normalele custom de la import ar bate peste apply_smooth.
    if hasattr(me, "free_normals_split"):
        me.free_normals_split()

    _thin_islands(me, thin)

    if decimate:
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = decimate
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)

    zs = [v.co.z for v in me.vertices]
    span = max(max(zs) - min(zs), 1e-6)
    s = height / span
    me.transform(Matrix.Diagonal(Vector((s, s, s, 1.0))))

    attr = me.attributes.new(name="slot", type="INT", domain="FACE")
    for poly in me.polygons:
        attr.data[poly.index].value = slot
    return obj


for prefix in ("Tuft_", "Scrub_", "Fan_", "Rosette_", "Dead_"):
    clear_built(prefix)

built = []
total = 0
for (name, src, slot, height, decimate, thin) in PLANTS:
    obj = _prepare(name, src, slot, height, decimate, thin)
    tree = name.startswith("Dead_")
    stats = finish(obj, bevel=0.0, ao=AO_TREE if tree else AO_LEAF,
                   # Copacul e asimetric (coroana cade intr-o parte); centrat pe
                   # bbox, trunchiul ar iesi de sub origine si l-am planta pe
                   # langa punctul cerut de sampler.
                   origin="base_axis" if tree else "base")
    total += stats["tris"]
    built.append(obj)
    print("%-8s %-18s h=%5.2f m | %5d tris | AO %.2f..%.2f"
          % (name, src, height, stats["tris"], stats["ao_min"],
             stats["ao_max"]))

print("\nTOTAL: %d tris in biblioteca" % total)

for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(built, "plants/megakit_plants.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "megakit_plants.blend"))

x = 0.0
for o in built:
    o.location = (x, 0.0, 0.0)
    x += max(o.dimensions.x, 1.2) * 1.4
