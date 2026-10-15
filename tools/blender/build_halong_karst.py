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
HL_ROCK = ROCK_LIGHT        # 3: calcar in soare
HL_ROCK_DARK = ROCK_DARK    # 4: nisa de val, umbra, roca uda
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
            budget=None, bevel_angle=30.0, bevels=None, flat_ao=False):
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
        if flat_ao:
            _split_all_edges(o)
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        if flat_ao:
            _flatten_ao(o)
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


def karst_body(spec):
    """Corpul unui turn, din profilul de carst. `spec`:
      seed, h (inaltime), r_mid (raza la mijloc), ratio (y/x), seg, jag,
      lean / lean_from / lean_to (inclinare pe +X), prof (implicit
      KARST_PROFILE), twin (fractia de inaltime de la care creasta se
      desface in doua), tufts (cate ciorchini de tufe).
    Returneaza (obiect_roca, obiect_tufe, cota_varfului)."""
    sd = spec["seed"]
    H, RM = spec["h"], spec["r_mid"]
    ratio = spec.get("ratio", 0.88)
    lean = spec.get("lean", 0.0)
    lf = spec.get("lean_from", 0.25) * H
    lt = spec.get("lean_to", 0.95) * H
    prof = spec.get("prof", KARST_PROFILE)

    rock, scrub = Builder(), Builder()
    rings = []
    for (zf, rf) in prof:
        z = zf * H
        t = max(0.0, min(1.0, (z - lf) / max(lt - lf, 1e-6))) if lean else 0.0
        t = t * t * (3.0 - 2.0 * t)
        rings.append((z, rf * RM, rf * RM * ratio, lean * t, 0.0))
    # `jag` mare: peretele de carst e fatetat vertical, nu neted. Zgomotul e pe
    # COLOANA (continuu pe verticala in `ring_points`), deci iese ca dungi —
    # exact runnels-urile verticale cerute de brief, fara textura.
    pts, cents = ring_points(rings, spec.get("seg", 13), sd, spec.get("jag", 0.13))
    # Banda de nisa, pe ROCK_DARK: roca uda, in umbra surplombei. Se opreste la
    # 0,13 din inaltime, adica exact sub buza de unde peretele iese in consola.
    nz = (0.0, 0.13 * H)
    faceted_shell(rock, pts, HL_ROCK,
                  lambda k, z: HL_ROCK_DARK if nz[0] <= z <= nz[1] else HL_ROCK)

    rnd = _ok_rand(sd + 7)
    top_z = H
    r_top = prof[-1][1] * RM

    # Creasta dubla: doua caciuli de roca pe varf, despartite de o saua.
    twin = spec.get("twin")
    tops = [(lean, 0.0)]
    if twin:
        d = r_top * 0.55
        tops = [(lean - d, 0.0), (lean + d * 0.9, 0.0)]
        for i, (cx, cy) in enumerate(tops):
            s = r_top * (0.62 + 0.12 * i)
            chunk(rock, (cx, cy, top_z - s * 0.25), (s, s * ratio, s * 0.85),
                  sd * 41 + i, HL_ROCK, seg=7, nr=3, jag=0.18)

    # Tufele de pe creasta: ciorchini, nu o piele continua (brief: "rounded
    # green scrub on top"). Se revarsa putin peste buza, ca marginea sa nu fie
    # un cerc perfect.
    tn = spec.get("tufts", 9)
    for i in range(tn):
        a = 2.0 * math.pi * (i + rnd() * 0.5) / tn
        base = tops[i % len(tops)]
        rho = r_top * (0.20 + 0.72 * rnd())
        s = r_top * (0.26 + 0.16 * rnd())
        chunk(scrub, (base[0] + math.cos(a) * rho,
                      base[1] + math.sin(a) * rho * ratio,
                      top_z + s * 0.35 + (rnd() - 0.5) * r_top * 0.12),
              (s, s * 0.92, s * 0.52), sd * 53 + i, HL_SCRUB, seg=6, nr=2, jag=0.26)
    # Cateva tufe agatate pe perete, in treimea de sus: rup verticala si spun
    # ca peretele e roca vie, nu un cilindru.
    for i in range(spec.get("wall_tufts", 4)):
        a = 2.0 * math.pi * rnd()
        zf = 0.52 + 0.34 * rnd()
        z = zf * H
        rr = _prof_r(prof, zf) * RM
        t = max(0.0, min(1.0, (z - lf) / max(lt - lf, 1e-6))) if lean else 0.0
        t = t * t * (3.0 - 2.0 * t)
        s = RM * (0.12 + 0.07 * rnd())
        chunk(scrub, (lean * t + math.cos(a) * rr * 0.98,
                      math.sin(a) * rr * ratio * 0.98, z),
              (s, s * 0.9, s * 0.6), sd * 59 + i, HL_SCRUB, seg=5, nr=2, jag=0.3)

    return to_obj_nr(rock, "Tower_Rock"), to_obj_nr(scrub, "Tower_Scrub"), top_z


def _prof_r(prof, zf):
    """Raza (fractie) la fractia de inaltime `zf`, liniar intre nodurile
    profilului."""
    for i in range(len(prof) - 1):
        a, b = prof[i], prof[i + 1]
        if a[0] <= zf <= b[0]:
            t = (zf - a[0]) / max(b[0] - a[0], 1e-9)
            return a[1] + (b[1] - a[1]) * t
    return prof[-1][1]


def build_karst_tower_a():
    """Turn zvelt, vertical. h 55 m, raza la mijloc 16 m -> h/r = 3,44.

    Cel mai apropiat de arhetipul din fotografii: un bloc vertical cu o singura
    creasta, nisa clara de jur imprejur.
    """
    rock, scrub, top = karst_body(dict(seed=71, h=55.0, r_mid=16.0,
                                       ratio=0.86, seg=13, jag=0.13, tufts=10,
                                       wall_tufts=5))
    return [rock, scrub], top


def build_karst_tower_b():
    """Turn lat, creasta dubla. h 45 m, raza la mijloc 16 m -> h/r = 2,81.

    Piesa care rupe ritmul intr-un sir de turnuri zvelte. Plansa de inventar o
    desena mai indesata decat cota (h/r 2,26 masurat): cifra din brief castiga,
    si de-aia `r_mid` e tot 16 si nu mai mult.
    """
    rock, scrub, top = karst_body(dict(seed=72, h=45.0, r_mid=16.0,
                                       ratio=0.94, seg=14, jag=0.15, tufts=11,
                                       wall_tufts=4, twin=True))
    return [rock, scrub], top


def build_karst_tower_c():
    """Turn inclinat, o fata in consola. h 65 m, raza la mijloc 18 m -> 3,61.

    Inclinarea e pe +X, intre 0,25 si 0,95 din inaltime, deci baza ramane
    verticala: nisa trebuie sa se citeasca pe toata circumferinta, altfel
    turnul pare doar cazut intr-o parte.
    """
    # NISA PROPRIE, mai adanca decat a celorlalte (0,56 in loc de 0,62).
    # `jag` e zgomot MULTIPLICATIV pe raza, deci umfla valorile mici in termeni
    # relativi mai mult decat pe cele mari: masurat pe prima versiune, nisa
    # iesea 11,82 m fata de 11,16 teoretic (+6%), iar mijlocul 16,30 fata de
    # 18,00 (-9%). Impreuna duceau raportul la 0,73, peste pragul de 0,70 —
    # desi forma era corecta. Nisa mai adanca readuce raportul in contract fara
    # sa scada `jag`, care e ce da peretelui dungile verticale.
    prof_c = [(z, 0.52 if z in (0.055, 0.075) else r) for z, r in KARST_PROFILE]
    rock, scrub, top = karst_body(dict(seed=73, h=65.0, r_mid=18.0,
                                       ratio=0.82, seg=13, jag=0.14, tufts=9,
                                       wall_tufts=6, prof=prof_c,
                                       lean=7.0, lean_from=0.25, lean_to=0.95))
    return [rock, scrub], top


def build_karst_stack_a():
    """Stanca izolata, 15 m. Aceeasi lege de forma la alta scara: `r_mid` 5,2 m
    da h/r = 2,88. Mai putine fatete (vazuta de aproape, dar mica)."""
    # 4 ciorchini, nu 6, si fara tufe de perete: la 15 m vegetatia se citeste
    # ca o pata verde pe creasta, nu ca ciorchini separati, iar corpul singur
    # (seg 10 x 13 benzi) ocupa deja ~260 din cele 400 de triunghiuri. Prima
    # versiune iesea 492, cu 184 doar vegetatie.
    # r_mid 4,6 (nu 5,2): dupa rescrierea profilului talpa e mai lata si `jag`
    # 0,17 umfla raza masurata, asa ca h/r iesea 2,42 — sub pragul de 2,50.
    # Contractul din brief cere >= 2,50; la h 15 m asta inseamna r <= 6,0, dar
    # cu zgomotul masurat raza efectiva urca, deci cea declarata coboara.
    rock, scrub, top = karst_body(dict(seed=74, h=15.0, r_mid=4.6,
                                       ratio=0.84, seg=10, jag=0.17, tufts=4,
                                       wall_tufts=0))
    return [rock, scrub], top


def build_karst_stack_b():
    """Stanca izolata, 9 m. `r_mid` 3.0 -> h/r = 3,00. Alta siluet\u0103 prin seed
    si prin raportul y/x, nu prin alt profil: legea formei e aceeasi."""
    # Acelasi motiv ca la stack_a: 3 ciorchini si fara tufe de perete.
    rock, scrub, top = karst_body(dict(seed=75, h=9.0, r_mid=3.0,
                                       ratio=0.72, seg=9, jag=0.19, tufts=3,
                                       wall_tufts=0))
    return [rock, scrub], top


def build_shore_boulder():
    """Bolovan rotunjit de mal, 2,5 m. NU e un turn: n-are nisa de val si nici
    n-ar trebui (de-aia `verify_halong.sh` nu-l trece prin garda de silueta).
    Un singur nod, fara vegetatie."""
    # `chunk` primeste DIAMETRELE elipsoidului, iar varful real iese ~0,75 din
    # semi-inaltime (vezi antetul lui): o prima versiune cu size z = 1,1 a dat
    # 1,3 m in loc de 2,5. Pentru 2,5 m inaltime totala, cu centrul la 1,05,
    # diametrul pe z e 2,9.
    b = Builder()
    chunk(b, (0.0, 0.0, 1.05), (3.2, 2.8, 2.9), 76, HL_ROCK, seg=7, nr=3, jag=0.22)
    chunk(b, (1.1, 0.5, 0.45), (1.6, 1.4, 1.2), 77, HL_ROCK, seg=6, nr=2, jag=0.26)
    return [to_obj_nr(b, "Boulder_Rock")], 2.5


PIECES = {
    "karst_tower_a": (build_karst_tower_a, "rocks/karst_tower_a.glb", 900),
    "karst_tower_b": (build_karst_tower_b, "rocks/karst_tower_b.glb", 900),
    "karst_tower_c": (build_karst_tower_c, "rocks/karst_tower_c.glb", 1000),
    "karst_stack_a": (build_karst_stack_a, "rocks/karst_stack_a.glb", 400),
    "karst_stack_b": (build_karst_stack_b, "rocks/karst_stack_b.glb", 400),
    "shore_boulder": (build_shore_boulder, "rocks/shore_boulder.glb", 150),
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
    objs, top = fn()
    # `keep_xy=True`: turnurile se aseaza pe pozitii alese in scena, iar
    # centrarea pe XY ar muta axa fata de inclinare (la `karst_tower_c` baza
    # n-ar mai fi sub centrul bbox-ului). Originea la baza ramane.
    emit_hl(objs, path, _ao(top + 0.5), keep_xy=True, bevel=0.0,
            budget=budget, flat_ao=True)
    _drop(objs)
report_hl()
