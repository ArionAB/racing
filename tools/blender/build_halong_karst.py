"""Ha Long, valul 1 — turnurile de carst (brief docs/asset_briefs/halong_kit.md §1.1).

  halong/rocks/karst_tower_a.glb     turn zvelt, vertical, 55 m
  halong/rocks/karst_tower_b.glb     turn lat, creasta dubla, 45 m
  halong/rocks/karst_tower_c.glb     turn inclinat, o fata in consola, 65 m
  halong/rocks/karst_stack_a.glb     stanca-ciuperca izolata, 15 m
  halong/rocks/karst_stack_b.glb     idem, alta silueta, 9 m
  halong/rocks/shore_boulder.glb     bolovan rotunjit de mal, 2,5 m

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_halong_karst.py

Variabila HL_ONLY=<piesa> reface doar piesa respectiva.

CONTRACTUL, si de ce e o FORMA, nu o cifra de buget
---------------------------------------------------
Un turn de carst e **cel mai ingust la linia apei**: valurile i-au mancat o
nisa in baza, iar peretele de deasupra iese IN CONSOLA peste apa. Asta e
singurul lucru care face roca sa citeasca "Ha Long" si nu "deal tropical".
`verify_karst_profile.py` il masoara pe felii orizontale:

    nisa / mijloc <= 0,70  (tinta 0,62)      h / raza_mijloc >= 2,50

Profilul cerut de brief §1.1, ca fractie din raza de la mijloc:

    z=0,00  0,80   baza, in apa
    z=0,06  0,62   NISA DE VAL — cel mai ingust punct
    z=0,15  0,92   peretele iese inapoi peste nisa
    z=0,50  1,00   mijloc, perete aproape vertical
    z=0,85  0,90   sub creasta
    z=1,00  0,70   varf cu tufe

Istoricul, ca pragurile sa nu para arbitrare: la pasul 7 al pistei turnurile
aveau h/r = 0,57-0,74 si interiorul buclei citea ca o masa continua de uscat;
prima plansa de inventar desena turnuri care se LARGEAU spre baza (raport 1,76
in loc de 0,62) si a fost regenerata.

DIFERENTA FATA DE `notch_rock_*` din Okinawa (aceeasi roca, alta forma)
-----------------------------------------------------------------------
Acelea sunt CIUPERCI: gat subtire pe toata inaltimea si un cap lat deasupra,
deci cel mai ingust punct e la MIJLOC. Un turn Ha Long are strangerea DOAR la
baza, apoi perete care urca aproape vertical. Rulat prin garda de silueta,
`notch_rock_a` trece (0,66 / 4,59 — chiar forma cautata, dar la 9 m),
`notch_rock_b` pica pe h/r 1,17, `notch_rock_c` pe nisa 0,99.
Deci se refoloseste VOCABULARUL (`ring_points`, `faceted_shell`, `chunk`), nu
piesele: cap si fusta de bolovani NU exista aici — un turn intra curat in apa
(brief §1.1: "fara apron de bolovani la baza").

NODURI: `Tower_Rock` (ROCK_LIGHT 3, cu banda de nisa pe ROCK_DARK 4) si
`Tower_Scrub` (TROPICAL_GREEN 21). Doua noduri, fiindca la integrare roca
primeste clasa triplanara `karst_limestone` si vegetatia nu (brief §0.6).
Garda de silueta sare singura nodurile `*_Scrub` — vegetatia nu e silueta.
"""

import os
import math

_here_hl = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_hl, "okinawa_shapes.py")).read())

clear_built()


def to_obj_nr(b, name):
    """Builder -> obiect, cu normalele recalculate pe tot nodul."""
    return b.to_object(name)


def _ao(top):
    """AO pe gradient vertical, pe inaltimea piesei. Un turn de 55 m cere alt
    `z_range` decat un bolovan de 2,5 m, altfel gradientul cade tot in primul
    metru si restul peretelui iese plat."""
    return dict(samples=20, dist=3.0, gradient="vertical", low=0.45, high=1.0,
                power=0.8, floor=0.22, z_range=(0.0, top))


def _drop(objs):
    """Scoate nodurile dupa export, ca urmatoarea piesa sa-si pastreze numele
    (altfel Blender adauga .001, iar Godot cauta nodurile dupa nume)."""
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)


# --- sloturile pe roluri (halong_kit.md §0.4) --------------------------------
# SLOTURILE SE VERIFICA IN ATLAS, NU DUPA NUME. Prima versiune folosea
# ROCK_LIGHT (3) pentru calcar "in soare" — dar in atlas slotul 3 e #CE8D4A,
# saturatie 0,64: stanca de DESERT, portocalie. In joc turnurile ieseau
# portocaliu aprins (masurat pe captura de la volan: saturatie 0,82 fata de
# 0,08 tinta). Calcarul cenusiu e MARBLE_GREY 29 (#B6B2AA, saturatie 0,07),
# acelasi slot pe care il foloseste calcarul Ryukyu din Okinawa — aceeasi roca,
# aceeasi dala (verificat pe notch_rock_*: sloturile lor sunt 2, 12, 21, 29).
HL_ROCK = MARBLE_GREY       # 29: calcar cenusiu in soare
# BANDA UDA: SAND_SHADOW 2, nu ROCK_LIGHT 3.
#
# Aceeasi capcana ca la corpul turnului, lasata pe jumatate reparata. Corpul a
# trecut pe MARBLE_GREY 29 cand s-a vazut ca iese portocaliu, dar banda de nisa
# a ramas pe slotul 3 — care e **#CE8D4A, saturatie 0,64**, stanca de desert.
# In joc se vede ca un INEL PORTOCALIU de rugina la linia apei pe fiecare turn
# (captura POI C, frac 0,27). Sloturile se verifica in ATLAS, nu dupa nume:
# "ROCK_LIGHT" suna a calcar palid si e portocaliu aprins.
#
# SAND_SHADOW 2 e nisipul in umbra — gri-cald inchis, exact ce trebuie pentru
# roca uda sub surplomba, si e deja in lista de sloturi legale a pistei
# (brief §0.4, "lemn spalat de soare").
HL_ROCK_DARK = SAND_SHADOW   # 2: nisa de val, roca uda in umbra
HL_SCRUB = TROPICAL_GREEN   # 21: tufe de creasta

HL_RESULTS = []

# Profilul din brief §1.1: (fractie din inaltime, fractie din raza la mijloc).
#
# RESCRIS dupa prima plansa de preview. Cifrele treceau toate garzile
# (nisa/mijloc 0,58-0,65, h/r 2,84-3,99), dar randate aratau BUTOAIE: memoria
# `harnasul-de-kit-nu-vede-forma-nici-culoarea` — verify masoara doua rapoarte,
# plansa arata silueta, si abia impreuna spun daca piesa e buna.
#
# Doua defecte, amandoua in profil:
#  1. SURPLOMBA PREA LENTA — defectul principal, prins abia la a doua plansa.
#     Geometria avea nisa (raza 9,57 m la 2,8 m inaltime, masurat pe GLB), dar
#     peretele se deschidea inapoi pe 14 m de inaltime: panta 0,45, adica un
#     CON. O surplomba reala de carst iese peste apa pe 2-4 m de inaltime,
#     deci panta > 1,0 — aproape orizontala. Acum consola se face intre z
#     0,075 si 0,135, adica pe ~4% din inaltime (2,3 m pe un turn de 57 m):
#     panta ~2,9. Asta e ce se vede de la distanta, nu adancimea nisei.
#  2. PERETE UMFLAT. Raza crestea 0,92 -> 1,00 intre z 0,15 si 0,50, apoi
#     scadea — adica exact silueta unui butoi. Un perete de carst e DREPT:
#     acum ramane 0,99-1,00 pe toata inaltimea mijlocie si se retrage abia sub
#     creasta.
KARST_PROFILE = [
    (0.000, 0.88),   # talpa in apa
    (0.030, 0.68),
    (0.055, 0.58),   # NISA — cel mai ingust punct
    (0.075, 0.58),   # nisa tine pe o banda, nu un singur inel
    (0.095, 0.78),   #     (0.115, 0.94),   #  > CONSOLA: peretele iese peste nisa pe 4% din inaltime
    (0.135, 1.00),   # /
    (0.300, 1.00),
    (0.450, 1.00),   # perete DREPT pe toata inaltimea mijlocie
    (0.600, 1.00),
    (0.720, 0.99),
    (0.820, 0.96),
    (0.890, 0.90),
    (0.950, 0.80),
    (1.000, 0.62),
]


def emit_hl(objs, path, ao, keep_xy=False, bevel=0.0, smooth_angle=None,
            budget=None, bevel_angle=30.0, bevels=None, flat_ao=False, post=None):
    """Finish pe fiecare nod + export in assets/models/halong/<path>.

    Copie a lui `emit_ok`, cu categoria schimbata: offsetul de origine se
    calculeaza O DATA pe ansamblu (memoria `finish-recentreaza-fiecare-nod-
    separat` — altfel `finish` re-centreaza fiecare nod pe bbox-ul LUI si
    piesa se desface, ceea ce la un turn ar rupe tufele de pe varf)."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        # `flat_ao` poate fi si un tuplu de sufixe: doar nodurile acelea ies
        # plate (v2: vegetatia fatetata, ca restul frunzisului low-poly din
        # joc; roca neteda).
        flat = flat_ao if isinstance(flat_ao, bool) else o.name.endswith(tuple(flat_ao))
        if flat:
            _split_all_edges(o)
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=None if flat else smooth_angle)
        if flat:
            _flatten_ao(o)
        if post is not None:
            post(o)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "halong/" + path)
    HL_RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


# --- v2 (26 nov 2026): generatorul e in halong_karst_shapes.py, comun cu grota.
exec(open(os.path.join(_here_hl, "halong_karst_shapes.py"), encoding="utf-8").read())


def build_karst_tower_a():
    """Turn zvelt, vertical. h 55 m, raza la mijloc 16 m -> h/r = 3,44."""
    spec = dict(seed=71, h=55.0, r_mid=16.0, ratio=0.86, seg=64, rings=46,
                crest=0.10, crown=2.3, wall_veg=0.55)
    rock, veg, top = karst_body(spec)
    return [rock, veg], top, spec


def build_karst_tower_b():
    """Turn lat, creasta dubla. h 45 m, raza la mijloc 16 m -> h/r = 2,81."""
    spec = dict(seed=72, h=45.0, r_mid=16.0, ratio=0.94, seg=64, rings=40,
                crest=0.16, twin=0.55, crown=2.3, wall_veg=0.6)
    rock, veg, top = karst_body(spec)
    return [rock, veg], top, spec


def build_karst_tower_c():
    """Turn inclinat, o fata in consola. h 65 m, raza la mijloc 18 m -> 3,61.
    Nisa proprie, mai adanca (0,52): vezi istoricul v1 — zgomotul umfla
    valorile mici relativ mai mult."""
    prof_c = [(z, 0.52 if z in (0.055, 0.075) else r) for z, r in KARST_PROFILE]
    spec = dict(seed=73, h=65.0, r_mid=18.0, ratio=0.82, seg=64, rings=50,
                crest=0.09, prof=prof_c, lean=7.0, lean_from=0.25, lean_to=0.95,
                crown=2.4, wall_veg=0.5)
    rock, veg, top = karst_body(spec)
    return [rock, veg], top, spec


def build_karst_stack_a():
    """Stanca izolata, 15 m (in scena la scara ~2, deci ~30 m langa drum).
    Aceeasi lege de forma; r_mid 4,6 -> h/r >= 2,5 cu zgomot cu tot."""
    spec = dict(seed=74, h=15.0, r_mid=4.6, ratio=0.84, seg=48, rings=30,
                crest=0.12, crown=0.9, wall_veg=0.5)
    rock, veg, top = karst_body(spec)
    return [rock, veg], top, spec


def build_karst_stack_b():
    """Stanca izolata, 9 m. `r_mid` 3,0 -> h/r = 3,00."""
    spec = dict(seed=75, h=9.0, r_mid=3.0, ratio=0.72, seg=40, rings=26,
                crest=0.14, crown=0.6, wall_veg=0.45)
    rock, veg, top = karst_body(spec)
    return [rock, veg], top, spec


def build_shore_boulder():
    """Bolovan rotunjit de mal, 2,5 m. NU e turn: n-are nisa. V2: doua icosfere
    bosselate, netede (v1: elipsoizi fatetati de 7 coloane), cu dungi si
    muschi coapte ca pe turnuri."""
    b = Builder()
    for (c, sz, sd) in (((0.0, 0.0, 1.05), (1.65, 1.45, 1.30), 76),
                        ((1.15, 0.55, 0.45), (0.85, 0.75, 0.62), 77)):
        res = bmesh.ops.create_icosphere(b.bm, subdivisions=2, radius=1.0)
        ph = Vector((sd * 0.7, sd * 1.3, sd * 0.4))
        for v in res["verts"]:
            k = (1.0 + 0.16 * _mnoise.noise(v.co * 1.6 + ph)
                 + 0.05 * _mnoise.noise(v.co * 5.0 + ph))
            v.co = Vector((c[0] + v.co.x * sz[0] * k, c[1] + v.co.y * sz[1] * k,
                           c[2] + v.co.z * sz[2] * k))
        fs = set()
        for v in res["verts"]:
            fs.update(v.link_faces)
        for f in fs:
            f[b.slot] = HL_ROCK
    # talpa sub 0 turtita: bolovanul sta IN nisip, nu pe el
    for v in b.bm.verts:
        v.co.z = max(v.co.z, -0.25)
    return [to_obj_nr(b, "Boulder_Rock")], 2.5, dict(seed=76, h=2.5, r_mid=1.6)


PIECES = {
    "karst_tower_a": (build_karst_tower_a, "rocks/karst_tower_a.glb", 16000),
    "karst_tower_b": (build_karst_tower_b, "rocks/karst_tower_b.glb", 16000),
    "karst_tower_c": (build_karst_tower_c, "rocks/karst_tower_c.glb", 18000),
    "karst_stack_a": (build_karst_stack_a, "rocks/karst_stack_a.glb", 9000),
    "karst_stack_b": (build_karst_stack_b, "rocks/karst_stack_b.glb", 6000),
    "shore_boulder": (build_shore_boulder, "rocks/shore_boulder.glb", 400),
}


def report_hl():
    print("\n%-26s %7s %7s  %s" % ("piesa", "tris", "buget", "dimensiuni (m)"))
    for path, tris, dims, budget, per_node, kb in HL_RESULTS:
        flag = ""
        if budget and tris > budget:
            flag = "  !! PESTE BUGET"
        print("%-26s %7d %7s  %5.1f x %5.1f x %5.1f%s"
              % (os.path.basename(path), tris, budget or "-",
                 dims.x, dims.y, dims.z, flag))
        for n, t in per_node.items():
            print("    %-22s %7d" % (n, t))


ONLY = os.environ.get("HL_ONLY", "")
for name, (fn, path, budget) in PIECES.items():
    if ONLY and ONLY != name:
        continue
    objs, top, spec = fn()
    # `keep_xy=True`: turnurile se aseaza pe pozitii alese in scena, iar
    # centrarea pe XY ar muta axa fata de inclinare (la `karst_tower_c` baza
    # n-ar mai fi sub centrul bbox-ului). Originea la baza ramane.
    # V2: roca cu umbrire NETEDA (smooth_angle 62) — lobii si canelurile se
    # citesc prin lumina care curge. Vegetatia ramane PLATA: coroanele netede
    # ieseau "jeleuri" lucioase de aproape (captura de la frac 0,2).
    emit_hl(objs, path, _ao(top + 0.5), keep_xy=True, bevel=0.0,
            budget=budget, smooth_angle=62.0, flat_ao=("_Scrub",),
            post=lambda o, sp=spec: (tint_rock(o, sp["h"], sp["r_mid"], sp["seed"])
                                     if o.name.endswith("_Rock")
                                     else tint_veg(o, sp["r_mid"], sp["seed"])))
    if "_crowns" in spec:
        print("%s: %d coroane" % (name, spec["_crowns"]))
    _drop(objs)
report_hl()
