"""megakit_rocks.glb — formatiuni de stanca ROTUNJITA, compuse din Stylized
Nature MegaKit (Quaternius, CC0).

De ce inca o biblioteca de stanci, cand exista canyon_rocks.glb: alea sunt
stive de lespezi cu buza — sedimentar erodat in trepte. Foaia de referinta a
kitului (Preview_3.jpg) arata celalalt limbaj de forma din acelasi peisaj:
mase de gresie ROTUNJITE, cu fatete late si muchii moi, fara nicio treapta.
Un canion real le are pe amandoua, si tocmai alternanta lor e ce opreste
pista sa citeasca drept "un mesh reciclat de 200 de ori" — cu o singura
familie de silueta, varietatea de dimensiune nu se mai vede de la 60 km/h.

Sursa: Rock_Medium_1/2/3 din kit, TREI mesh-uri de ~3 m. Singure n-ar fi
schimbat nimic (aveam deja cinci elipsoizi in rock_cluster.glb). Ce le face
formatiuni e compunerea de aici: mai multe copii scalate si infipte una in
alta, dupa aceeasi mecanica de trepte/lean/moloz din `Builder.mesa`, doar ca
peste geometrie desenata in loc de inele generate.

Ce NU aducem din kit: texturile lui (Rocks_Diffuse.png & co). Contractul
proiectului e materiale de CLASA, iar aici clasa exista deja —
`Palette.rock_material()`, triplanara in spatiul lumii. Deci UV-urile sursei
sunt irelevante (le suprascriem oricum pe sloturi, ca fallback) si straturile
de roca curg continuu din formatiunea asta in faleza de langa ea. Zero
materiale noi in garda.

Vertex colors: kitul aduce un COLOR_0 propriu care coboara la 0.0 la baza —
o masca de vant, nu AO. Cu `vertex_color_use_as_albedo` din materialele
noastre ar fi vopsit bazele in negru. `finish()` sterge toate atributele de
culoare si coace AO-ul nostru in locul lor.

  Kit_L1..L4   6-9 m    banda din spate, siluete dominante
  Kit_M1..M6   2-5 m    banda de mijloc
  Kit_S1..S6   0.6-2 m  banda lipita de drum si sateliti

Rulare (Blender, namespace comun cu dio_lib):
    g = {"__name__": "__main__", "__file__": r"<repo>/tools/blender/dio_lib.py"}
    exec(open(r"<repo>/tools/blender/dio_lib.py").read(), g)
    exec(open(r"<repo>/tools/blender/build_megakit_rocks.py").read(), g)
"""

import bpy
import math
import os
from mathutils import Matrix, Vector

KIT = r"D:/GameDev/downloaded assets/Stylized Nature MegaKit[Standard]/glTF"
SOURCES = ["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"]
# Molozul NU se face din bolovanii mari scalati in jos: la 30 cm ar costa tot
# 244-522 de triunghiuri bucata, adica mai mult decat treapta pe care o
# imbraca (masurat: clasa M sarise la ~1900 tris, din care 1500 erau moloz).
# Pietricelele kitului sunt aceeasi familie de forma la 48-104 triunghiuri.
RUBBLE_SOURCES = ["Pebble_Square_3", "Pebble_Square_4", "Pebble_Square_6"]

# Benzi de valoare blocate de geometrie, ca la canyon_rocks. Clasa de roca e
# triplanara si nu citeste UV-uri, deci astea nu se vad azi — se pastreaza
# fiindca sunt sursa de adevar a formei si singurul fallback daca stancile se
# intorc vreodata pe atlas.
STRATA = (ROCK_LIGHT, ROCK_DARK, ROCK_LIGHT, SAND_SHADOW)
STRATA_BAND = 0.85  # metri per banda de valoare


def _load_sources(names):
    """Importa mesh-urile sursa o singura data si le intoarce ca date de mesh.

    Obiectele importate raman in scena pana la finalul rularii (le curata
    `clear_built`); copiile lucreaza pe `mesh.copy()`, deci sursa nu se atinge.
    """
    out = []
    for name in names:
        if name not in bpy.data.objects:
            bpy.ops.import_scene.gltf(filepath=os.path.join(KIT, name + ".gltf"))
        obj = bpy.data.objects[name]
        # Normalele custom de la import ar bate peste apply_smooth si ar tine
        # fatetele plate exact acolo unde vrem sa curga lumina.
        if hasattr(obj.data, "free_normals_split"):
            obj.data.free_normals_split()
        obj.hide_set(True)
        out.append(obj)
    return out


def _decimated(src, ratio):
    """Varianta colapsata a unei surse, cache-uita pe (sursa, raport).

    Sursele kitului sunt desenate pentru un obiect de 3 m vazut de aproape:
    244-522 de triunghiuri bucata. Puse la scara clasei S (sub 2 m), asta
    inseamna 342 de triunghiuri pentru o piatra pe care `canyon_rocks.glb` o
    face cu 76 — de 4.4 ori mai scump pe EXACT piesa cea mai instantiata de pe
    pista (banda lipita de drum, plus toti satelitii). Masurat: prima integrare
    a urcat Dunele cu 119.000 de triunghiuri si a scos Stramtoarea din prag.
    Colapsul se face pe SURSA, nu pe formatiunea gata unita: altfel pietricelele
    de moloz (48-104 triunghiuri) s-ar transforma in cioburi.
    """
    if ratio is None or ratio >= 0.999:
        return src
    key = "%s@%.2f" % (src.name, ratio)
    if key in bpy.data.objects:
        return bpy.data.objects[key]
    me = src.data.copy()
    obj = bpy.data.objects.new(key, me)
    bpy.context.collection.objects.link(obj)
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = ratio
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.hide_set(True)
    return obj


def _piece(src, center, size, rot_z):
    """O copie a unui mesh sursa, scalata ca bbox-ul ei sa fie exact `size`.

    Scalarea e pe cote, nu uniforma: asa aceeasi piatra da si o masa lata si
    joasa, si un bloc inalt. Sursa are 3 m, deci pana la clasa L factorul urca
    la ~2.5 — fatetele si ele, ceea ce e chiar efectul cautat (o gresie de 8 m
    are fatete de metri, nu de decimetri).
    """
    me = src.data.copy()
    obj = bpy.data.objects.new("Piece", me)
    bpy.context.collection.objects.link(obj)

    lo = Vector((min(v.co.x for v in me.vertices),
                 min(v.co.y for v in me.vertices),
                 min(v.co.z for v in me.vertices)))
    hi = Vector((max(v.co.x for v in me.vertices),
                 max(v.co.y for v in me.vertices),
                 max(v.co.z for v in me.vertices)))
    span = Vector((max(hi.x - lo.x, 1e-6), max(hi.y - lo.y, 1e-6),
                   max(hi.z - lo.z, 1e-6)))
    mid = (lo + hi) * 0.5

    # centrat in XY pe bbox, asezat cu BAZA pe center.z
    m = (Matrix.Translation(Vector((center[0], center[1], center[2])))
         @ Matrix.Rotation(rot_z, 4, "Z")
         @ Matrix.Diagonal(Vector((size[0] / span.x, size[1] / span.y,
                                   size[2] / span.z)).to_4d())
         @ Matrix.Translation(Vector((-mid.x, -mid.y, -lo.z))))
    me.transform(m)
    return obj


def _join(pieces, name):
    """Uneste piesele intr-un singur obiect. Fetele interne raman inauntru — nu
    se vad niciodata si nu merita costul unui boolean (aceeasi alegere ca la
    `Builder.mesa`)."""
    bpy.ops.object.select_all(action="DESELECT")
    for p in pieces:
        p.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    if len(pieces) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


def _tag_strata(obj):
    """Scrie atributul de fata `slot` in benzi orizontale.

    `snapshot_slots` il citeste ca sa colapseze UV-urile; fara el TOATA
    geometria ar cadea pe slotul 0 (nisip in soare), adica exact culoarea
    gresita daca materialul de clasa e vreodata scos.
    """
    me = obj.data
    attr = me.attributes.get("slot")
    if attr is None:
        attr = me.attributes.new(name="slot", type="INT", domain="FACE")
    z_lo = min(v.co.z for v in me.vertices)
    for poly in me.polygons:
        band = int((poly.center.z - z_lo) / STRATA_BAND)
        attr.data[poly.index].value = STRATA[band % len(STRATA)]


def formation(name, size, srcs, pebbles, tiers=1, seed=0, lip=0.16, lean=0.14,
              overlap=0.34, rubble=0, rubble_scale=0.22, decimate=None):
    """O masa de gresie din `tiers` bolovani suprapusi, plus moloz la baza.

    `overlap` (fractie din inaltimea treptei) e cifra critica si nu e cosmetica:
    sursele sunt movile ROTUNJITE, deci doua asezate cap la cap se ating intr-un
    punct si lasa o fanta prin care se vede interiorul (fete backface, deci
    culled — arata ca o crapatura in stanca). Sub ~0.30 apar fante; peste ~0.45
    treapta de sus dispare in cea de jos si silueta redevine o movila.

    `rubble` ascunde linia unde formatiunea intra in nisip — altfel e o elipsa
    perfecta si tradeaza obiectul ca lipit peste teren.
    """
    rand = _lcg(seed)
    sx, sy, sz = size
    pieces = []

    tier_h_eff = (sz + (tiers - 1) * sz / tiers * overlap) / float(tiers)
    ox, oy, top = 0.0, 0.0, 0.0
    for k in range(tiers):
        shrink = 1.0 - lip * k
        h = tier_h_eff * (0.84 + rand() * 0.32)
        base = 0.0 if k == 0 else top - h * overlap
        src = _decimated(srcs[int(rand() * len(srcs)) % len(srcs)], decimate)
        pieces.append(_piece(src, (ox, oy, base),
                             (sx * shrink, sy * shrink, h),
                             rand() * math.tau))
        top = base + h
        # Decalajul se ACUMULEAZA: stiva se apleaca intr-o directie in loc sa
        # serpuiasca, deci citeste ca erodata de un vant care bate mereu din
        # aceeasi parte.
        ox += (rand() - 0.5) * sx * lean
        oy += (rand() - 0.5) * sy * lean

    for i in range(rubble):
        a = math.tau * (i + rand() * 0.6) / max(rubble, 1)
        r = rubble_scale * (0.6 + rand() * 0.8)
        src = pebbles[int(rand() * len(pebbles)) % len(pebbles)]
        # Pe CONTURUL bazei, nu in jurul ei: pietrele trebuie sa atinga stanca,
        # altfel par imprastiate langa ea.
        pieces.append(_piece(
            src,
            (math.cos(a) * sx * 0.5 * (1.0 + rand() * 0.18),
             math.sin(a) * sy * 0.5 * (1.0 + rand() * 0.18),
             -sz * r * 0.30),  # ingropat pe ~o treime: desprins din stanca,
                               # nu asezat langa ea
            (sx * r, sy * r, sz * r * 0.7),
            rand() * math.tau))

    obj = _join(pieces, name)
    _tag_strata(obj)
    return obj


# `lip` — cat se retrage fiecare treapta fata de cea de sub ea. E cifra care
# decide daca iese PERETE sau PIRAMIDA, si sursele impun o valoare mai mica
# decat la canyon_rocks: alea sunt lespezi cu pereti verticali, deci retragerea
# lor e vizibila ca treapta; astea sunt movile care se ingusteaza deja singure
# spre varf. Peste ~0.12 cele doua ingustari se aduna si formatiunea devine un
# con. La 0.08 treptele de sus raman late si masa citeste ca bloc.
LIP_L = 0.08
LIP_M = 0.12

# Colapsul pe CLASA, calibrat pe biblioteca cu care se amesteca (vezi
# `_decimated` pentru de ce). Tinta nu e "cat de putin se poate", ci PARITATE cu
# canyon_rocks la aceeasi marime — altfel amestecul celor doua familii nu mai e
# o alegere de aspect, ci un impozit ascuns pe fiecare slot de decor:
#   canyon_S 40-88 tris  -> kit S la 0.32 iese ~110
#   canyon_M 312-500     -> kit M la 0.55 iese ~520
#   canyon_L 704-784     -> kit L la 0.70 iese ~880
# Clasa L pierde cel mai putin fiindca acolo silueta chiar se vede: e singura
# care umple cadrul. Clasa S se colapseaza cel mai agresiv fiindca la 1 m, pe
# langa masina, nu se distinge o fateta de doua.
DEC_L = 0.70
DEC_M = 0.55
DEC_S = 0.32

# (nume, marime XYZ, trepte, moloz, lip, colaps, seed)
#
# Proportiile difera intentionat intre variante: cateva late si joase (masa de
# gresie asezata), cateva inalte si inguste (bloc ramas in picioare). Cu acelasi
# raport peste tot, varietatea de dimensiune nu se mai vede.
#
# Fara flat_top nicaieri, si asta e diferenta de familie fata de canyon_rocks:
# alea sunt mese cu capac plat, astea sunt mase rotunjite. Amestecate pe aceeasi
# pista citesc ca geologie; fiecare singura, ca tipar.
ROCKS = [
    # --- LARGE 6-9 m ---------------------------------------------------------
    ("Kit_L1", (8.4, 7.2, 7.0), 3, 5, LIP_L, DEC_L, 11),
    ("Kit_L2", (11.0, 8.4, 5.8), 2, 7, LIP_L, DEC_L, 29),  # lata si joasa: umar
    ("Kit_L3", (6.0, 5.4, 8.6), 4, 5, LIP_L, DEC_L, 47),   # bloc in picioare
    ("Kit_L4", (9.2, 8.0, 6.6), 3, 6, LIP_L, DEC_L, 67),

    # --- MEDIUM 2-5 m --------------------------------------------------------
    ("Kit_M1", (4.4, 3.8, 3.6), 2, 4, LIP_M, DEC_M, 83),
    ("Kit_M2", (3.2, 2.9, 4.8), 3, 3, LIP_M, DEC_M, 101),
    ("Kit_M3", (5.2, 4.6, 2.4), 1, 5, LIP_M, DEC_M, 119),
    ("Kit_M4", (3.8, 3.4, 3.0), 2, 3, LIP_M, DEC_M, 139),
    ("Kit_M5", (4.8, 4.0, 4.6), 2, 4, LIP_M, DEC_M, 157),
    ("Kit_M6", (2.8, 2.5, 2.2), 1, 3, LIP_M, DEC_M, 173),

    # --- SMALL 0.6-2 m -------------------------------------------------------
    #
    # Astea sunt cele mai numeroase de pe pista, deci o piesa in plus se
    # inmulteste cu zeci. Fara moloz si dintr-un singur bolovan: la 1 m,
    # pietricelele de la baza sunt sub un pixel.
    ("Kit_S1", (2.1, 1.8, 1.7), 1, 0, LIP_M, DEC_S, 191),
    ("Kit_S2", (1.6, 1.5, 2.0), 1, 0, LIP_M, DEC_S, 211),
    ("Kit_S3", (2.4, 2.0, 1.2), 1, 0, LIP_M, DEC_S, 233),
    ("Kit_S4", (1.3, 1.1, 1.0), 1, 0, LIP_M, DEC_S, 251),
    ("Kit_S5", (1.8, 1.7, 1.5), 1, 0, LIP_M, DEC_S, 271),
    ("Kit_S6", (0.9, 0.8, 0.7), 1, 0, LIP_M, DEC_S, 293),
]

# Bevel ZERO peste tot: sursele au deja muchii modelate, iar un bevel peste ele
# ar adauga geometrie la fiecare muchie a unei mase de 350 de triunghiuri fara
# sa schimbe silueta. apply_smooth (din finish) face toata treaba de aici.
AO_BIG = dict(samples=24, dist=3.0, gradient="vertical",
              low=0.42, high=1.00, power=0.85, floor=0.12)
AO_SMALL = dict(samples=18, dist=1.4, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.14)

srcs = _load_sources(SOURCES)
pebbles = _load_sources(RUBBLE_SOURCES)
clear_built("Kit_")
clear_built("Piece")

built = []
per_class = {"L": [0, 0], "M": [0, 0], "S": [0, 0]}
for (name, size, tiers, rubble, lip, dec, seed) in ROCKS:
    obj = formation(name, size, srcs, pebbles, tiers=tiers, seed=seed,
                    rubble=rubble, lip=lip, decimate=dec)
    cls = name[4]
    stats = finish(obj, bevel=0.0, ao=AO_BIG if cls in "LM" else AO_SMALL,
                   origin="base")
    per_class[cls][0] += 1
    per_class[cls][1] += stats["tris"]
    built.append(obj)
    print("%-8s %5.1f x %4.1f x %4.1f m | %d trepte + %d moloz | %4d tris"
          " | AO %.2f..%.2f"
          % (name, size[0], size[1], size[2], tiers, rubble, stats["tris"],
             stats["ao_min"], stats["ao_max"]))

print()
report_slits(built, "megakit_rocks")
print()
for cls in "LMS":
    n, t = per_class[cls]
    print("  clasa %s: %2d variante, %5d tris (medie %d)" % (cls, n, t, t / n))
print("TOTAL: %d tris in biblioteca" % sum(v[1] for v in per_class.values()))

for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(built, "megakit_rocks.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "megakit_rocks.blend"))

# Asezate una langa alta doar pentru inspectie in Blender; instanta din joc
# anuleaza offsetul (TrackDecor.pick_from_glb).
x = 0.0
for o in built:
    o.location = (x, 0.0, 0.0)
    x += max(o.dimensions.x, 2.0) * 1.3
