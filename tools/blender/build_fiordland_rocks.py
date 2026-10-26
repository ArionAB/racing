"""Fiordland — Stancile-hero (brief §1.1, val 1 din docs/asset_briefs/fiordland_kit.md).

  fiordland/rocks/stirling_ledge.glb   perete + surplomb + nisa (StirlingFalls)
  fiordland/rocks/torrent_chute.glb    jgheab de torent (TorrentCycle)
  fiordland/rocks/chasm_rock.glb       lespede cu marmite (Chasm)
  fiordland/rocks/guard_rock.glb       bolovan de cornisa
  fiordland/rocks/scree_slab.glb       placa de grohotis

CINCI piese. Fara apa (regula 0.7): perdelele, spray-ul si bazinele le face
`WaterfallVisual`/`TorrentCycle` in cod. `stirling_ledge` e prima si cea mai
importanta — planul ChatGPT a ratat-o (bloc plin, fara surplomb) — si e
judecata de aproape, prin perdea, deci primeste cel mai mult grijaj.

AXE: drumul trece pe Y Blender, "dreapta in sensul de mers" e +X Blender.
La stirling_ledge si torrent_chute peretele/masa de stanca stau pe +X
(dreapta drumului), fata utila spre -X.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_rocks.py
"""

import math
from mathutils import Vector

# Sloturile legale pe Fiordland (brief §0.4). ROCK_DARK si ROCK_LIGHT
# INTERZISE (gneisul iese maro pe ROCK_DARK, memoria rock-dark-nu-pe-bazalt).
GNEISS = MARBLE_GREY          # gneis in lumina: pereti, stanci, bolovani
WET_STREAK = VOLCANIC_BLACK   # dungi ude, umbra din nise, fundul jgheabului
MOSS = TROPICAL_GREEN         # muschi pe piatra
SCREE = SAND_SHADOW           # pietris, grohotis

AO_WALL = dict(samples=18, dist=10.0, gradient="vertical",
               low=0.40, high=1.00, power=0.85, floor=0.14)
AO_SMALL = dict(samples=22, dist=3.0, gradient="vertical",
                low=0.46, high=1.00, power=0.90, floor=0.18)


# --- stirling_ledge ------------------------------------------------------
#
# Contract (brief §1.1): perete 40 m lung (Y) x 10 m adanc (+X) x 30 m inalt.
# Nisa concava 30 m lungime, 4 m adancime in perete, 7 m inaltime libera.
# Surplombul cu buza la +14.0 m, iesit 9 m spre -X din fata peretelui
# (3 m de prag + 6 m de perdea). Noduri: Wall, Overhang, Shelf, Moss.
# Origine assembly (fata peretelui e planul X=0, centrat pe Y).
SL_WALL_LEN = 40.0
SL_WALL_DEEP = 10.0
SL_WALL_H = 30.0
SL_NICHE_LEN = 30.0
SL_NICHE_DEPTH = 4.0
SL_NICHE_CLEAR = 7.0          # inaltime libera in nisa, deasupra Shelf
SL_LIP_Z = 14.0                # buza surplombului (contract WaterfallHazard)
SL_LIP_OUT = 9.0                # cat iese surplombul spre -X din fata peretelui
SL_SHELF_W = 3.0                # latimea pragului (Shelf)


# Marja de adancime lasata masei din spate (`_rock_x`) fata de fatetele
# frontale ale peretelui — stanca reala nu are o fata perfect plana, deci
# masa care o sustine trebuie sa fie putin mai groasa decat X=0 exact.
SL_FACE_JITTER = 2.4


def _rock_x(b, center, size, slot, seed, segments=7, rings=4, taper=0.16,
            squash=0.88, flat_top=True, strata_slots=None):
    """`Builder.rock(wall_axis="y")`, dar cu fata VERTICALA pe -X in loc de
    -Y — exact reteta din `build_cliff_wall.py` (aceeasi piesa dovedita,
    deja in productie pe alta pista), doar rotita 90 grade.

    `rock(wall_axis="y")` accepta un singur sens hardcodat (`sa < 0.0`,
    adica -Y) — dio_lib.py e fisier COMUN mai multor piste, deci nu i se
    adauga o a doua axa doar pentru asta. In schimb: se construieste normal
    (fata la -Y), apoi se ROTESTE rezultatul -90 grade in jurul lui Z, care
    duce -Y -> -X. `center`/`size` primite aici sunt deja in spatiul NOSTRU
    (X=adancime, Y=lungime); se convertesc inainte de apel.
    """
    cx, cy, cz = center
    sx, sy, sz = size
    # Post-rotatia aplicata mai jos e (x,y) -> (y, -x) [-90 grade in jurul Z].
    # Ca REZULTATUL final sa cada la (cx, cy), coordonatele DINAINTE de
    # rotatie trebuie sa fie inversul acelei transformari:
    #   final = (rock_y, -rock_x) = (cx, cy)  =>  rock_y = cx, rock_x = -cy
    rock_center = (-cy, cx, cz)
    rock_size = (sy, sx, sz)
    faces = b.rock(rock_center, rock_size, slot, seed=seed, segments=segments,
                   rings=rings, taper=taper, squash=squash, flat_top=flat_top,
                   wall_axis="y", strata_slots=strata_slots)
    # rotatie -90 grade in jurul Z: (x,y) -> (y, -x). Se aplica DOAR
    # varfurilor noi (fetele intoarse contin toate varfurile lor).
    #
    # DOUA bug-uri gasite aici, pe rand:
    #  1. `v.index` intr-un bmesh proaspat nu e actualizat automat.
    #  2. `id(v)` NU e o cheie stabila: accesarile repetate ale lui
    #     `f.verts` pot intoarce wrapper-e Python noi pentru ACELASI
    #     BMVert, cu `id()` diferit de fiecare data (masurat: 42 varfuri
    #     reale in bmesh, dar 154 "id-uri unice" din iterarea fetelor) —
    #     deci `seen` nu prindea duplicate si sfarsea prin a roti UNELE
    #     varfuri de mai multe ori (sau deloc), lasand un amestec de
    #     coordonate rotite si nerotite (exact peretele de 40 m pe X).
    # Fix: `bm.verts.index_update()` + cheie pe `.index` (int stabil dupa
    # actualizare), plus rotatia se aplica direct pe `b.bm.verts` (toate
    # varfurile bmesh-ului CURENT), nu pe cele adunate din `f.verts`.
    b.bm.verts.index_update()
    touched = set()
    for f in faces:
        for v in f.verts:
            touched.add(v.index)
    for v in b.bm.verts:
        if v.index in touched:
            x, y, z = v.co.x, v.co.y, v.co.z
            v.co.x, v.co.y = y, -x
    return faces


def _wall_body(b):
    """Masa principala a peretelui: COMPUS din mai multe mase `rock()`
    (reteta din `build_cliff_wall.py`, deja verificata pe alta pista), nu
    o grila proprie cu jitter per-varf.

    Prima si a doua incercare (grila cu jitter independent per varf, apoi
    grila cu deviatie per coloana/rand) au esuat in feluri diferite: prima
    a dat tepi ascutiti (jitter necorelat intre coloane vecine), a doua a
    dat un perete care citea "neted/panza" (facetele, desi flat-shaded
    explicit, aveau unghiuri prea apropiate intre vecine ca sa se vada ca
    plane distincte). `rock()` insusi rezolva exact problema asta — e
    functia pe care restul codebase-ului o foloseste pentru orice faleza
    (`build_cliff_wall.py`, `build_mine_portal.py`, `build_baikal_forest.py`)
    — deci se refoloseste direct, in loc sa se reinventeze perturbatia.

    Coama zimtata (3-6 m) vine din COMPOZITIE: mai multe mase `rock()` de
    inaltimi diferite, asezate cap la cap pe lungime — exact `build_saddle`/
    `build_notch` din cliff_wall.py. Nisa (30 m lungime, 4 m adancime,
    tavan la SL_NICHE_CLEAR) ramane GOL real: masa centrala incepe de la
    SL_NICHE_CLEAR in sus (doar deasupra nisei), iar cele doua mase de
    capat coboara pana la sol.
    """
    faces = []
    hl = SL_NICHE_LEN * 0.5
    end_len = (SL_WALL_LEN - SL_NICHE_LEN) * 0.5  # lungimea unei mase de capat

    strata = (WET_STREAK, GNEISS, GNEISS, GNEISS)

    # --- cele doua mase de capat: FULL inaltime (0 -> coama), flancheaza
    # nisa. Fiecare e usor diferita ca inaltime/seed, ca sa nu fie oglinda.
    end_h_l = SL_WALL_H - 1.5
    end_h_r = SL_WALL_H + 2.0
    # `wall_axis="y"` NU taperuieste fata verticala (-Y a lui rock(), care
    # devine -X-ul nostru dupa rotatie) — dar jitter-ul de `col_dev`/
    # `ring_dev` tot poate umfla marginea cu pana la ~12% peste nominal.
    # Masurat direct pe GLB: cu factorul vechi (1.06) varfuri de la capatul
    # de masa intrau 2.5 m in golul nisei. 0.88 (nu 1.06) lasa suficienta
    # marja ca umflarea maxima sa ramana INAINTE de guard_hl.
    faces += _rock_x(b, (SL_WALL_DEEP * 0.5, -SL_WALL_LEN * 0.5 + end_len * 0.5,
                        -0.4),
                     (SL_WALL_DEEP + SL_FACE_JITTER, end_len * 0.88,
                      end_h_l + 0.4),
                     GNEISS, seed=4401, segments=12, rings=10, taper=0.15,
                     squash=0.90, strata_slots=strata)
    faces += _rock_x(b, (SL_WALL_DEEP * 0.5, SL_WALL_LEN * 0.5 - end_len * 0.5,
                        -0.4),
                     (SL_WALL_DEEP + SL_FACE_JITTER, end_len * 0.88,
                      end_h_r + 0.4),
                     GNEISS, seed=4409, segments=12, rings=10, taper=0.15,
                     squash=0.90, strata_slots=strata)

    # --- masa centrala, DOAR deasupra nisei (de la SL_NICHE_CLEAR in sus).
    # Doua bucati usor inegale (ca `build_saddle`), ca sa iasa o coama in
    # trepte (3-6 m diferenta) pe langa niste dintre cele doua mase.
    #
    # NU se sincronizeaza cu "-0.4/+0.4" (tiparul din cliff_wall.py, unde
    # masa sta pe SOL si un mic ingropaj sub 0 nu se vede): aici baza
    # trebuie sa fie EXACT la SL_NICHE_CLEAR, fiindca dedesubt e golul
    # liber al nisei (contract: >=5 m liber, tinta 7 m). Un `rock()` cu
    # `rings` multe si `taper` mic tot are o usoara curbura sub inelul de
    # baza (verificat pe GLB: varfuri pana la 3.9 m in loc de 7.0), deci
    # baza porneste cu o MARJA (+0.6 m peste SL_NICHE_CLEAR), nu chiar pe
    # linie — mai buna o umbra de piatra care intra putin in perete decat
    # o piatra care atarna in golul de trecere.
    mid_h_total = SL_WALL_H - SL_NICHE_CLEAR - 0.6
    mid1_len = SL_NICHE_LEN * 0.56
    mid2_len = SL_NICHE_LEN * 0.50   # se suprapun putin, ca sa nu ramana rost
    mid1_h = mid_h_total * 0.80
    mid2_h = mid_h_total * 0.95
    faces += _rock_x(b, (SL_WALL_DEEP * 0.5, -hl + mid1_len * 0.42,
                        SL_NICHE_CLEAR + 0.6),
                     (SL_WALL_DEEP + SL_FACE_JITTER, mid1_len, mid1_h),
                     GNEISS, seed=4421, segments=12, rings=9, taper=0.16,
                     squash=0.88, strata_slots=strata)
    faces += _rock_x(b, (SL_WALL_DEEP * 0.5, hl - mid2_len * 0.44,
                        SL_NICHE_CLEAR + 0.6),
                     (SL_WALL_DEEP + SL_FACE_JITTER, mid2_len, mid2_h),
                     GNEISS, seed=4433, segments=12, rings=9, taper=0.16,
                     squash=0.88, strata_slots=strata)

    front_faces = [f for f in faces if f.is_valid]
    # muschi pe fetele aproape orizontale de sus (coama), cost redus prin
    # retag (zero triunghiuri) — brief: Moss pe coama zimtata
    b.retag(front_faces, MOSS, where=lambda c, n: n.z > 0.55 and c.z > SL_WALL_H * 0.7)

    # GARDA: nicio piesa a peretelui n-are voie sa intre in golul liber al
    # nisei (Z(inaltime) in [0, SL_NICHE_CLEAR]). Se verifica aici, in
    # build, nu doar vizual — un `rock()` cu baza curbata poate aluneca sub
    # cota ceruta fara sa fie evident in preview.
    #
    # Marja de 0.2 m pe Y: masele de capat se suprapun DELIBERAT cu ~0.15 m
    # peste marginea nisei (`end_len*1.06`), ca sa nu ramana rost intre ele
    # si nisa — acolo e peretele SOLID de la capatul nisei, nu interiorul
    # ei. Golul de verificat e portiunea STRICT interioara.
    guard_hl = hl - 0.2
    intrusions = [v.co.z for f in front_faces for v in f.verts
                  if -guard_hl <= v.co.y <= guard_hl
                  and v.co.z < SL_NICHE_CLEAR - 0.01]
    if intrusions:
        raise RuntimeError(
            "wall intra in golul nisei: %d varfuri sub SL_NICHE_CLEAR "
            "(cel mai jos la Z=%.2f, cerut >=%.2f)"
            % (len(intrusions), min(intrusions), SL_NICHE_CLEAR))

    return faces, front_faces


def _niche(b):
    """Nisa concava sapata in fata peretelui: 30 m lungime, 4 m adancime,
    tavan la 7 m liber deasupra Shelf (care sta la Z=0, nod SEPARAT — vezi
    `_shelf`). Se construieste ca un gol REAL (nu doar retag): fara volum
    scobit, surplombul de mai sus ar pluti fara nimic dedesubt.

    Revizuire coordonator (wave 1 review): fundul nisei era o placa plana
    intunecata ("garaj cu doi stalpi in profil"). Acum e o fata SCOBITA
    concava, in 3 fatete pe adancime (0 -> 2.2 -> 3.4 -> 4.0 m), care
    citeste ca roca erodata, nu ca panou. Nu exista NICIUN stalp/nod vertical
    in interiorul nisei — golul de 30x4x7 m ramane complet liber (traseul
    uscat al pragului).

    Fete SEPARATE de Shelf: pana la #C2 aceasta functie si `_shelf` foloseau
    acelasi Builder, deci un Shelf construit intr-un obiect propriu (kitul
    de trei noduri din `_build_pieces`) mostenea si peretii nisei — Shelf
    iesea 4 m lat in loc de 3 (X 0..4 in loc de 0..3), verificat pe GLB, nu
    presupus. Acum fiecare functie ADAUGA doar fetele ei in `b`.
    """
    hl = SL_NICHE_LEN * 0.5
    depth = SL_NICHE_DEPTH
    clear_top = SL_SHELF_TOP + SL_NICHE_CLEAR  # tavanul nisei
    rand = _lcg(4455)

    faces = []
    n = 8
    top_rows = []
    for i in range(n + 1):
        t = i / n
        y = -hl + SL_NICHE_LEN * t
        top_rows.append(y)

    # Profilul CONCAV al fundului nisei, in 3 fatete (nu un panou plan):
    # de la buza (X=0) inapoi spre X=depth, scobit — mijlocul e mai adanc
    # decat capetele, ca o scobitura reala erodata de apa.
    def bowl_x(y):
        # 0 la capete, 1 la mijloc (Y=0): profil concav pe lungime
        f = 1.0 - (abs(y) / hl) ** 1.4
        return depth * (0.55 + 0.45 * f)

    # tavanul: usor inclinat spre spate (nu perfect orizontal) — brief:
    # tavanul surplombului "se inclina in sus spre spate"
    tf = []
    inner = [b.bm.verts.new((bowl_x(y) + 0.4, y, clear_top + 0.6)) for y in top_rows]
    outer = [b.bm.verts.new((0.0, y, clear_top)) for y in top_rows]
    for i in range(n):
        tf.append(b.bm.faces.new(
            (outer[i], outer[i + 1], inner[i + 1], inner[i])))
    for f in tf:
        f[b.slot] = WET_STREAK
    faces += tf

    # Fundul scobit: DOUA benzi pe verticala (Shelf -> mijloc -> tavan),
    # fiecare urmarind `bowl_x(y)` — asa iese concavitatea PE LUNGIME, iar
    # cu doua randuri pe inaltime iese si o usoara curbura pe verticala
    # (perete care se apleaca spre interior sus, nu o placa dreapta).
    mid_z = (SL_SHELF_TOP + clear_top) * 0.5
    back = []
    lo = [b.bm.verts.new((bowl_x(y) * 0.85, y, SL_SHELF_TOP)) for y in top_rows]
    mid = [b.bm.verts.new((bowl_x(y), y, mid_z)) for y in top_rows]
    hi = [b.bm.verts.new((bowl_x(y) + 0.4, y, clear_top + 0.6)) for y in top_rows]
    for i in range(n):
        f1 = b.bm.faces.new((lo[i], lo[i + 1], mid[i + 1], mid[i]))
        f2 = b.bm.faces.new((mid[i], mid[i + 1], hi[i + 1], hi[i]))
        back += [f1, f2]
    for f in back:
        f[b.slot] = WET_STREAK
    faces += back

    # Peretii laterali ai nisei (capetele, pe Y): inchid golul — urmeaza
    # bowl_x la capat (aproape 0, fateta ingusta), nu o muchie dreapta.
    for sy, y0 in ((-1.0, -hl), (1.0, hl)):
        bx = bowl_x(y0)
        side = b.bm.faces.new((
            b.bm.verts.new((0.0, y0, SL_SHELF_TOP)),
            b.bm.verts.new((bx, y0, SL_SHELF_TOP)),
            b.bm.verts.new((bx + 0.4, y0, clear_top + 0.6)),
            b.bm.verts.new((0.0, y0, clear_top)),
        )) if sy > 0 else b.bm.faces.new((
            b.bm.verts.new((bx, y0, SL_SHELF_TOP)),
            b.bm.verts.new((0.0, y0, SL_SHELF_TOP)),
            b.bm.verts.new((0.0, y0, clear_top)),
            b.bm.verts.new((bx + 0.4, y0, clear_top + 0.6)),
        ))
        side[b.slot] = GNEISS
        faces.append(side)

    return faces


def _shelf(b):
    """Shelf: nod separat, prag uscat sub surplomb, fata de sus la Z=0.
    3 m latime (SL_SHELF_W), 30 m lungime (lungimea nisei)."""
    hl = SL_NICHE_LEN * 0.5
    shelf_faces = []
    sn = 6
    rows = []
    for i in range(sn + 1):
        t = i / sn
        y = -hl + SL_NICHE_LEN * t
        rows.append(y)
    outer_s = [b.bm.verts.new((0.0, y, SL_SHELF_TOP)) for y in rows]
    inner_s = [b.bm.verts.new((SL_SHELF_W, y, SL_SHELF_TOP)) for y in rows]
    for i in range(sn):
        shelf_faces.append(b.bm.faces.new(
            (outer_s[i], outer_s[i + 1], inner_s[i + 1], inner_s[i])))
    for f in shelf_faces:
        f[b.slot] = GNEISS
    b.retag(shelf_faces, MOSS, where=lambda c, n: c.y < -hl * 0.2)

    # grosime pentru Shelf (placa subtire, nu foaie fara volum). NU coboara
    # sub SL_SHELF_TOP: `emit()` aseaza ansamblul (Wall+Overhang+Shelf) pe cel
    # mai jos punct COMUN, iar contractul cere buza surplombului la exact
    # +14.0 m fata de acel punct — un Shelf care coboara sub 0 ar ridica tot
    # ansamblul si ar impinge buza la 14.0+adancime (asta a iesit prima data:
    # buza masurata la 14.4 in loc de 14.0, din cei 0.4 m de grosime veche).
    # Muchia de jos ramane la Wall's baza (Z=0), deci grosimea vine dintr-o
    # coborare infinitezimala (2 cm) care nu strica in practica cota de
    # contract, dar da placii un volum real (nu o foaie fara grosime).
    drop = [b.bm.verts.new((0.0, y, SL_SHELF_TOP - 0.02)) for y in rows]
    for i in range(sn):
        f = b.bm.faces.new((drop[i], drop[i + 1], outer_s[i + 1], outer_s[i]))
        f[b.slot] = WET_STREAK
        shelf_faces.append(f)

    return shelf_faces


SL_SHELF_TOP = 0.0  # cota fetei de sus a Shelf (originea assembly, brief)


def _overhang(b):
    """Surplombul: PANA de stanca (nu placa dreptunghiulara), continua cu
    masa peretelui, fara rost vizibil.

    Revizuire coordonator (wave 1 review): era "o scandura plata lipita pe
    fata" (o banca). Acum:
      - profil in PANA: subtire la buza (~2 m), ingrosandu-se spre perete
        (~7 m) — se citeste in sectiune (fiordland_stirling_profile.png)
      - fata de DEDESUBT se inclina in SUS spre nisa (continua tavanul
        nisei din `_niche()`, nu ramane orizontala)
      - muchia din fata (buza) e NEREGULATA in plan: fiecare "rand" pe Y
        are propriul iesire pe X (+-1 m), nu o linie dreapta
      - radacina (x=0..SL_WALL_DEEP*0.4) se CONTOPESTE cu peretele: nu
        exista o muchie verticala neta la x=0, fetele urca in panta pana
        se pierd in masa din spate (fara rost vizibil)

    Buza (cota cea mai joasa a muchiei din fata) ramane la exact SL_LIP_Z:
    aici cade apa (contract WaterfallHazard).
    """
    hl = SL_NICHE_LEN * 0.5
    z = SL_LIP_Z
    n = 8
    rand = _lcg(4477)
    rows = []
    for i in range(n + 1):
        t = i / n
        y = -hl + SL_NICHE_LEN * t
        rows.append(y)

    # muchia din fata: neregulata pe Y (+-1 m), dar cota Z ramane FIXA la
    # SL_LIP_Z (buza e definita ca cea mai joasa cota a muchiei — un rand
    # care iese mai mult pe X nu coboara si pe Z, apa oricum cade de pe
    # toata lungimea, la aceeasi inaltime)
    lip_out = [SL_LIP_OUT + (rand() - 0.5) * 2.0 for _ in rows]
    lip_thick = 2.0          # grosimea panei LA BUZA (brief: ~2 m)
    root_thick = 7.0         # grosimea unde se imbina cu peretele (brief 6-8)

    faces = []
    under_pts, top_pts, root_lo_pts, root_hi_pts = [], [], [], []
    for i, y in enumerate(rows):
        out_x = -lip_out[i]
        under_pts.append(b.bm.verts.new((out_x, y, z)))
        top_pts.append(b.bm.verts.new((out_x, y, z + lip_thick)))
        # radacina: mult mai groasa, si capacul de sus se ridica (pana
        # spre peretele care continua in sus) — fara rost, fata de sus a
        # panei e chiar tavanul care urca spre `_niche()`'s tavan
        root_lo_pts.append(b.bm.verts.new((SL_WALL_DEEP * 0.35, y, z - 0.4)))
        root_hi_pts.append(b.bm.verts.new((SL_WALL_DEEP * 0.35, y, z + root_thick)))

    # fata de dedesubt: de la buza (subtire) URCAND spre radacina — panta,
    # nu placa orizontala. Aceasta e fata "se vede din masina, sub perdea".
    under = []
    for i in range(n):
        f = b.bm.faces.new((under_pts[i], under_pts[i + 1],
                            root_lo_pts[i + 1], root_lo_pts[i]))
        f[b.slot] = WET_STREAK
        under.append(f)
    faces += under

    # fata de sus: de la buza pana la radacina, ingrosandu-se — capacul
    # panei, continuu cu platoul/masa din spate (muschi pe ea, coordonator)
    top = []
    for i in range(n):
        f = b.bm.faces.new((root_hi_pts[i], root_hi_pts[i + 1],
                            top_pts[i + 1], top_pts[i]))
        f[b.slot] = MOSS
        top.append(f)
    faces += top

    # muchia din fata (buza propriu-zisa): verticala mica intre under si
    # top, la cota SL_LIP_Z fixa (nu urmeaza jitter-ul lui out_x pe Z)
    lip_edge = []
    for i in range(n):
        f = b.bm.faces.new((under_pts[i], under_pts[i + 1],
                            top_pts[i + 1], top_pts[i]))
        f[b.slot] = GNEISS
        lip_edge.append(f)
    faces += lip_edge

    # capetele (Y) ale panei: inchid volumul la cele doua margini
    for sy, (u, r_lo, r_hi, t) in (
            (-1.0, (under_pts[0], root_lo_pts[0], root_hi_pts[0], top_pts[0])),
            (1.0, (under_pts[-1], root_lo_pts[-1], root_hi_pts[-1], top_pts[-1]))):
        verts = [u, r_lo, r_hi, t]
        f = b.bm.faces.new(verts) if sy > 0 else b.bm.faces.new(list(reversed(verts)))
        f[b.slot] = GNEISS
        faces.append(f)

    return faces


def _build_pieces():
    """stirling_ledge se exporta ca TREI obiecte (Wall include nisa,
    Overhang, Shelf) — trei Builder-e separate, ca sa iasa trei noduri
    curate fara sa despartim un bmesh unic dupa fapt."""
    bw = Builder()
    wall_faces, wall_front_faces = _wall_body(bw)
    niche_faces = _niche(bw)
    wall_obj = bw.to_object("Wall")

    bo = Builder()
    overhang_faces = _overhang(bo)
    overhang_obj = bo.to_object("Overhang")

    bs = Builder()
    shelf_faces = _shelf(bs)
    shelf_obj = bs.to_object("Shelf")

    return wall_obj, overhang_obj, shelf_obj


# --- torrent_chute ---------------------------------------------------------
#
# Contract: masa de stanca 24 m lunga (Y) x 8 m adanca (+X) x 16 m inalta;
# jgheabul are gura de 20 m latime pe Y, buza la +14.0 m, iesita 3 m spre -X
# peste marginea benzii. Deasupra buzei: cuveta 6x4 m goala, fund
# VOLCANIC_BLACK. Origine base_axis (fata dinspre banda, centrata pe gura).
TC_LEN = 24.0
TC_DEEP = 8.0
TC_H = 16.0
TC_MOUTH_W = 20.0
TC_LIP_Z = 14.0
TC_LIP_OUT = 3.0


def build_torrent_chute():
    b = Builder()
    hl = TC_LEN * 0.5
    hm = TC_MOUTH_W * 0.5

    faces = []
    # Masa principala: bloc cu fata dinspre banda (-X) usor scobita la
    # mijloc (gura jgheabului).
    rock_faces = list(b.box((TC_DEEP * 0.5, 0.0, TC_H * 0.5),
                            (TC_DEEP, TC_LEN, TC_H), GNEISS))
    faces += rock_faces
    b.retag(rock_faces, GNEISS, where=None)

    # Albia (jgheabul): un canal concav sapat in fata, de la baza pana la
    # buza (TC_LIP_Z), latime TC_MOUTH_W. Fundul jgheabului = VOLCANIC_BLACK.
    n = 5
    rows = []
    for i in range(n + 1):
        t = i / n
        y = -hm + TC_MOUTH_W * t
        rows.append(y)
    bed = []
    lo = [b.bm.verts.new((0.0, y, 0.0)) for y in rows]
    hi = [b.bm.verts.new((TC_DEEP * 0.35, y, TC_LIP_Z)) for y in rows]
    for i in range(n):
        f = b.bm.faces.new((lo[i], lo[i + 1], hi[i + 1], hi[i]))
        f[b.slot] = WET_STREAK
        bed.append(f)
    faces += bed
    # malurile jgheabului (laterale, GNEISS)
    for sy, y0 in ((-1.0, rows[0]), (1.0, rows[-1])):
        m0 = Vector((0.0, y0, 0.0))
        m1 = Vector((TC_DEEP * 0.35, y0, TC_LIP_Z))
        m2 = Vector((TC_DEEP * 0.9, y0, TC_LIP_Z))
        m3 = Vector((TC_DEEP * 0.9, y0, 0.0))
        vs = [b.bm.verts.new(m0), b.bm.verts.new(m1),
              b.bm.verts.new(m2), b.bm.verts.new(m3)]
        f = b.bm.faces.new(vs) if sy > 0 else b.bm.faces.new(list(reversed(vs)))
        f[b.slot] = GNEISS
        faces.append(f)

    # Buza jgheabului: iese TC_LIP_OUT spre -X peste banda, la cota TC_LIP_Z.
    lip_x = -TC_LIP_OUT
    root = [b.bm.verts.new((TC_DEEP * 0.35, y, TC_LIP_Z)) for y in rows]
    tip = [b.bm.verts.new((lip_x, y, TC_LIP_Z)) for y in rows]
    tip_top = [b.bm.verts.new((lip_x, y, TC_LIP_Z + 1.0)) for y in rows]
    root_top = [b.bm.verts.new((TC_DEEP * 0.35, y, TC_LIP_Z + 1.0)) for y in rows]
    lip_faces = []
    for i in range(n):
        f = b.bm.faces.new((root[i], root[i + 1], tip[i + 1], tip[i]))  # dedesubt
        f[b.slot] = WET_STREAK
        lip_faces.append(f)
        f2 = b.bm.faces.new((tip[i], tip[i + 1], tip_top[i + 1], tip_top[i]))  # muchie
        f2[b.slot] = GNEISS
        lip_faces.append(f2)
        f3 = b.bm.faces.new((tip_top[i], tip_top[i + 1], root_top[i + 1], root_top[i]))
        f3[b.slot] = GNEISS
        lip_faces.append(f3)
    faces += lip_faces

    # Cuveta suspendata deasupra buzei: 6x4 m, goala, fund VOLCANIC_BLACK.
    basin = list(b.box((TC_DEEP * 0.55, 0.0, TC_LIP_Z + 1.6),
                       (4.0, 6.0, 0.6), WET_STREAK))
    faces += basin
    basin_rim = list(b.box((TC_DEEP * 0.55, 0.0, TC_LIP_Z + 1.95),
                           (4.3, 6.3, 0.15), GNEISS))
    faces += basin_rim

    # muschi pe margini
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.6 and c.z > TC_LIP_Z + 1.5)

    obj = b.to_object("Rock")
    return obj


# --- vocabular de stanca fatetata (v2, grupa A) -------------------------------
#
# `rock()`/`boulder()` dau elipsoizi cu raza perturbata: iese "o pita". Planseta
# cere FETE PLANE MARI, in unghiuri diferite. Reteta: invelitoarea convexa a
# unui nor de puncte (bmesh convex_hull), cu triunghiurile coplanare topite la
# loc in ngon-uri (dissolve_limit) -> piatra cu fete late, ca o piatra sparta.
import bmesh as _bmesh


def _hull(b, pts, slot, dissolve_deg=4.0):
    """Piatra fatetata din `pts` (liste de (x,y,z)). Intoarce setul de fete."""
    verts = [b.bm.verts.new(p) for p in pts]
    res = _bmesh.ops.convex_hull(b.bm, input=verts)
    dead = list({g for g in res["geom_interior"] + res["geom_unused"]
                 if isinstance(g, _bmesh.types.BMVert)})
    if dead:
        _bmesh.ops.delete(b.bm, geom=dead, context="VERTS")
    alive = [v for v in verts if v.is_valid]
    edges = list({e for v in alive for e in v.link_edges})
    _bmesh.ops.dissolve_limit(b.bm, angle_limit=math.radians(dissolve_deg),
                              verts=alive, edges=edges)
    alive = [v for v in alive if v.is_valid]
    faces = {f for v in alive for f in v.link_faces}
    for f in faces:
        f[b.slot] = slot
    return faces


def _stone_pts(rand, center, size, n=9, base_cut=0.55, spread=0.30):
    """Nor de `n` puncte pe un elipsoid (raza 1-spread..1) cu baza taiata plat
    (z >= -base_cut * semiaxa): piatra stand pe sol, cu o talpa plata.
    `center` e centrul elipsoidului, `size` diametrele (x, y, z)."""
    cx, cy, cz = center
    sx, sy, sz = size
    pts = []
    while len(pts) < n:
        x, y, z = rand() * 2 - 1, rand() * 2 - 1, rand() * 2 - 1
        d = math.sqrt(x * x + y * y + z * z)
        if d < 0.3 or d > 1.0:
            continue
        k = (1.0 - spread * rand()) / d
        x, y, z = x * k, y * k, max(z * k, -base_cut)
        pts.append((cx + x * sx * 0.5, cy + y * sy * 0.5, cz + z * sz * 0.5))
    return pts


def _ring_pts(rand, cx, cy, z, rx, ry, n, jit=0.12, rot=0.0):
    pts = []
    for i in range(n):
        a = rot + 2 * math.pi * (i + (rand() - 0.5) * 0.35) / n
        k = 1.0 + (rand() * 2 - 1) * jit
        pts.append((cx + math.cos(a) * rx * k, cy + math.sin(a) * ry * k, z))
    return pts


def _hexa(b, bot, top, slot):
    """Bloc din 8 varfuri: `bot`/`top` = 4 colturi (ordine ciclica)."""
    vb = [b.bm.verts.new(p) for p in bot]
    vt = [b.bm.verts.new(p) for p in top]
    fs = [b.bm.faces.new(tuple(reversed(vb))), b.bm.faces.new(tuple(vt))]
    for i in range(4):
        j = (i + 1) % 4
        fs.append(b.bm.faces.new((vb[i], vb[j], vt[j], vt[i])))
    for f in fs:
        f[b.slot] = slot
    return fs


# --- chasm_rock --------------------------------------------------------------
#
# Contract: 6.0 x 2.5 x 4.72 (Godot X x Y x Z) = 6.0 x 4.72 x 2.5 Blender.
# v2 (verdict coordonator): O SINGURA lespede monolitica. Corp = miez prismatic
# cu contur neregulat (suprafata de sus continua) + coloane de flanc de
# inaltimi diferite care coboara spre fata (-Y), plus 2 marmite TAIATE in fata
# de sus (boolean DIFFERENCE cu prisme cu contur in 3 lobi), cu pereti
# verticali inchisi la culoare. Nicio coroana peste suprafata de sus.
def _outline(rand, n, rx, ry, jit=0.08, rot=0.0):
    pts = []
    for i in range(n):
        a = rot + 2 * math.pi * (i + (rand() - 0.5) * 0.3) / n
        k = 1.0 + (rand() * 2 - 1) * jit
        pts.append((math.cos(a) * rx * k, math.sin(a) * ry * k))
    return pts


def _prism_xy(b, pts, z0, ztop, slot):
    """Prisma verticala din contur 2D (ngon sus/jos). `ztop(x,y)` -> cota sus."""
    vb = [b.bm.verts.new((x, y, z0)) for x, y in pts]
    vt = [b.bm.verts.new((x, y, ztop(x, y))) for x, y in pts]
    fs = [b.bm.faces.new(tuple(reversed(vb))), b.bm.faces.new(tuple(vt))]
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        fs.append(b.bm.faces.new((vb[i], vb[j], vt[j], vt[i])))
    for f in fs:
        f[b.slot] = slot
    return fs


def _round_stone(b, rand, c, size, slot):
    """Piatra GHEMUITA rotunjit-poliedrica (fara varfuri/piramide): 3 inele
    (5 jos, 5 la mijloc rotit, 3 sus). `size` = diametre (x, y, z)."""
    cx, cy, cz = c
    sx, sy, sz = size
    pts = []
    for z, n, r, rot in ((0.0, 5, 0.90, 0.0), (0.5, 5, 1.0, 0.63), (0.88, 3, 0.45, 0.3)):
        for i in range(n):
            a = rot + 2 * math.pi * i / n + (rand() - 0.5) * 0.35
            k = r * (0.88 + rand() * 0.24)
            pts.append((cx + math.cos(a) * k * sx * 0.5,
                        cy + math.sin(a) * k * sy * 0.5,
                        cz + z * sz * (0.9 + rand() * 0.2)))
    return _hull(b, pts, slot, 7.0)


def build_chasm_rock():
    import bpy as _bpy
    rand = _lcg(4501)
    n = 14
    outer = _outline(rand, n, 2.70, 2.15, 0.11, rot=0.1)
    core = [(x * 0.80, y * 0.80) for x, y in outer]
    z_core = 2.42

    # miezul: suprafata de sus continua (usor inclinata spre fata)
    bc = Builder()
    _prism_xy(bc, core, 0.0, lambda x, y: z_core + 0.07 * y - 0.10 * abs(x + 0.3), GNEISS)
    core_obj = bc.to_object("ChasmCore")

    # cele doua marmite: prisme cu contur in 3 lobi, taiate de sus
    bk = Builder()
    for (cx, cy, r, phi) in ((0.30, -0.35, 1.00, 0.4), (-1.25, 0.75, 0.72, 1.9)):
        pts = []
        for i in range(12):
            a = 2 * math.pi * i / 12
            k = 1.0 + 0.28 * math.cos(3 * a + phi) + (rand() - 0.5) * 0.08
            pts.append((cx + math.cos(a) * r * k, cy + math.sin(a) * r * k))
        _prism_xy(bk, pts, 0.85, lambda x, y: 3.2, WET_STREAK)
    cut_obj = bk.to_object("ChasmCut")
    mod = core_obj.modifiers.new("pits", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.object = cut_obj
    for o in list(_bpy.context.view_layer.objects):
        o.select_set(False)
    _bpy.context.view_layer.objects.active = core_obj
    core_obj.select_set(True)
    _bpy.ops.object.modifier_apply(modifier="pits")
    cm = cut_obj.data
    _bpy.data.objects.remove(cut_obj, do_unlink=True)
    _bpy.data.meshes.remove(cm)

    # coloanele de flanc: inaltimi diferite, mai joase spre fata (-Y)
    b = Builder()
    for k in range(n):
        j = (k + 1) % n
        ym = (outer[k][1] + outer[j][1]) * 0.5 / 2.15
        h = 1.60 + 0.65 * ym + (rand() - 0.5) * 0.9
        h = max(0.9, min(2.40, h))
        ok, oj = outer[k], outer[j]
        ck, cj = core[k], core[j]
        s = 0.86
        bot = [(ok[0], ok[1], 0.0), (oj[0], oj[1], 0.0),
               (cj[0], cj[1], 0.0), (ck[0], ck[1], 0.0)]
        top = [(ok[0] * s, ok[1] * s, h), (oj[0] * s, oj[1] * s, h),
               (cj[0], cj[1], h), (ck[0], ck[1], h)]
        _hexa(b, bot, top, GNEISS)
    # 3 blocuri ghemuite la baza, acelasi limbaj fatetat
    for (ang, sz) in ((205, (1.5, 1.2, 0.85)), (300, (1.6, 1.2, 0.75)), (15, (1.3, 1.1, 0.8))):
        a = math.radians(ang)
        _round_stone(b, rand, (math.cos(a) * 2.55, math.sin(a) * 2.0, 0.0), sz, GNEISS)
    obj = b.to_object("Rock")
    _bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    core_obj.select_set(True)
    _bpy.context.view_layer.objects.active = obj
    _bpy.ops.object.join()
    return obj


# --- guard_rock --------------------------------------------------------------
#
# v2: bloc inalt din ~10 plane mari: fata mare in fata, creasta verticala
# unde se intalnesc doua fete, plan de sus inclinat. Muschi in PETE (nu capac):
# pe planul de sus (jumatate) si pe flancurile joase / in crapatura.
def build_guard_rock():
    b = Builder()
    pts = [(-0.52, -0.26, 0.0), (0.18, -0.34, 0.0), (0.56, -0.06, 0.0),
           (0.40, 0.30, 0.0), (-0.30, 0.32, 0.0), (-0.56, 0.04, 0.0),
           # creasta verticala in fata (doua puncte unul peste altul)
           (0.00, -0.35, 0.10), (-0.02, -0.28, 0.66),
           (-0.50, -0.20, 0.40), (0.50, -0.22, 0.34),
           # planul de sus, inclinat spre dreapta
           (-0.38, -0.02, 0.80), (0.05, -0.10, 0.76), (0.30, 0.10, 0.60), (-0.10, 0.22, 0.74)]
    _hull(b, pts, GNEISS, 12.0)
    geom = list(b.bm.verts) + list(b.bm.edges) + list(b.bm.faces)
    _bmesh.ops.bisect_plane(b.bm, geom=geom, plane_co=(0, 0, 0.2), plane_no=(0, 0, 1))
    geom = list(b.bm.verts) + list(b.bm.edges) + list(b.bm.faces)
    _bmesh.ops.bisect_plane(b.bm, geom=geom, plane_co=(0.12, 0, 0), plane_no=(1, 0, 0))
    for f in b.bm.faces:
        c = f.calc_center_median()
        moss = (c.z > 0.62 and c.x > 0.12) or \
               (c.z < 0.2 and c.y > -0.15 and (c.x > 0.2 or c.x < -0.32)) or \
               (c.z < 0.45 and -0.12 < c.x < 0.06 and c.y < -0.1)
        f[b.slot] = MOSS if moss else GNEISS
    return b.to_object("Rock")


# --- scree_slab --------------------------------------------------------------
#
# v2: O SINGURA movila (varf usor spre spate, +Y) dintr-un mesh fatetat cu
# fete plane mari in 2 griuri (MARBLE_GREY + VOLCANIC_BLACK), cu o fusta de
# blocuri ghemuite la baza si un inel de ~28 pietre rotunjit-poliedrice
# imprastiate. FARA SAND_SHADOW. Y max 1.5.
def build_scree_slab():
    b = Builder()
    rand = _lcg(4701)
    # movila = grila de inaltimi (triunghiuri plane, flat-shaded): varf spre
    # spate (+Y), zgomot de cota si de pozitie -> multe fatete plane de marimi
    # si inclinari diferite, in 2 griuri
    nx, ny = 10, 16
    ax, ay = 2.05, 3.35
    grid = {}
    patch = {(a, c): rand() < 0.42 for a in range(nx) for c in range(ny)}
    for j in range(ny + 1):
        for i in range(nx + 1):
            x = (i / nx * 2 - 1) * ax + (rand() - 0.5) * 0.22
            y = (j / ny * 2 - 1) * ay + (rand() - 0.5) * 0.28
            yy = (y - 0.45) / ay          # varful deplasat spre +Y
            r = math.sqrt((x / ax) ** 2 + yy * yy)
            z = 1.62 * max(0.0, 1.0 - r) ** 1.1 * (0.85 + rand() * 0.3)
            if r < 0.85:
                z += (rand() - 0.5) * 0.14
            grid[(i, j)] = b.bm.verts.new((x, y, max(z, 0.0)))
    for j in range(ny):
        for i in range(nx):
            q = [grid[(i, j)], grid[(i + 1, j)], grid[(i + 1, j + 1)], grid[(i, j + 1)]]
            if all(v.co.z <= 0.0 for v in q):
                continue
            for tri in ((q[0], q[1], q[2]), (q[0], q[2], q[3])) if (i + j) % 2 else                        ((q[0], q[1], q[3]), (q[1], q[2], q[3])):
                f = b.bm.faces.new(tri)
                f[b.slot] = VOLCANIC_BLACK if patch[(i // 2 * 2, j // 2 * 2)] else GNEISS
    # fusta: blocuri ghemuite la baza movilei
    for i in range(5):
        a = 2 * math.pi * (i + rand() * 0.5) / 5
        s = 0.7 + rand() * 0.4
        _round_stone(b, rand, (math.cos(a) * 1.85, math.sin(a) * 3.05, 0.0),
                     (s * 1.2, s * 1.0, s * 0.7), GNEISS if rand() < 0.65 else VOLCANIC_BLACK)
    # inelul de pietre pe sol (ghemuite), pana la marginile 5 x 8
    placed = 0
    tries = 0
    while placed < 22 and tries < 600:
        tries += 1
        a = rand() * 2 * math.pi
        k = 1.12 + rand() * 0.45
        x = math.cos(a) * 2.38 * k * 0.92
        y = math.sin(a) * 3.92 * k * 0.92
        if abs(x) > 2.3 or abs(y) > 3.8:
            continue
        s = 0.28 + rand() * 0.42
        _round_stone(b, rand, (x, y, 0.0), (s * 1.3, s * 1.1, s * 0.75),
                     GNEISS if rand() < 0.7 else VOLCANIC_BLACK)
        placed += 1
    return b.to_object("Rock")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def _force_flat(obj):
    """Forteaza shading FLAT explicit (fiecare fateta cu normala ei),
    DUPA finish(). `smooth_angle=None` in `apply_smooth` (dio_lib.py) doar
    SARE peste pasul de netezire, fara sa garanteze explicit ca poligoanele
    raman flat — asta o face direct."""
    import bpy as _bpy
    for o in list(_bpy.context.view_layer.objects):
        o.select_set(False)
    obj.select_set(True)
    _bpy.context.view_layer.objects.active = obj
    _bpy.ops.object.mode_set(mode="OBJECT")
    try:
        _bpy.ops.mesh.customdata_custom_splitnormals_clear()
    except RuntimeError:
        pass
    _bpy.ops.object.shade_flat()
    for poly in obj.data.polygons:
        poly.use_smooth = False
    for edge in obj.data.edges:
        edge.use_edge_sharp = True


def emit(objs, path, ao, origin="base", bevel=0.05, smooth_angle=45.0,
         budget=None, force_flat=False):
    """finish() pe fiecare nod + un singur export.

    Pentru piese pe MAI MULTE noduri (stirling_ledge: Wall/Overhang/Shelf),
    asezarea se face pe ANSAMBLU, nu per nod (memoria `finish-recentreaza-
    fiecare-nod-separat` / tiparul `inca_house_a` din kitul Machu Picchu):
    offsetul se calculeaza O DATA pe bbox-ul comun, `finish` primeste
    `origin=None` pe fiecare nod (nu muta nimic), iar translatia comuna se
    aplica dupa aceea la toate. Altfel Overhang si Shelf, care NU ating solul
    prin constructie, ar fi recoborate individual la Z=0 si ansamblul s-ar
    desface — exact bug-ul gasit la prima rulare aici (Overhang raporta
    bbox 0..1.8 in loc de 14.0..15.8).

    `force_flat=True` suprascrie shading-ul DUPA finish() — vezi
    `_force_flat`.
    """
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        center_xy = origin != "base_axis"
        place = Vector((
            -(min(xs) + max(xs)) * 0.5 if center_xy else 0.0,
            -(min(ys) + max(ys)) * 0.5 if center_xy else 0.0,
            -min(zs)))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, ao=ao, origin=(origin if solo else None),
                    smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        if force_flat:
            _force_flat(o)
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "fiordland/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return total_tris


# stirling_ledge: TREI noduri (Wall, Overhang, Shelf), origine ASSEMBLY —
# fata peretelui e planul X=0, dar Overhang si Shelf ies/coboara relativ la
# ea, deci finish() pe fiecare separat le-ar re-centra independent si le-ar
# desface (aceeasi capcana ca la Machu Picchu inca_house_a). `emit()` de mai
# sus rezolva asta cu un offset comun.
wall_obj, overhang_obj, shelf_obj = _build_pieces()
# smooth_angle=None (nu 24, nu implicitul 55): la 24 grade tot netezea —
# grila de coloane/randuri are unghiuri intre fatete vecine adesea SUB 24
# (tranzitiile din col_dev/row_dev sunt line, ca sa nu iasa tepi), deci
# pragul nu prindea nimic si peretele iesea "val de panza" in loc de stanca.
# `smooth_angle=None` e reteta zidurilor din kitul Machu Picchu
# (`CHAIN_BEVEL`, build_machupicchu_citadel.py): fatetat complet, FARA
# nicio netezire — fiecare quad al grilei ramane un plan distinct, lumina
# sare in trepte intre ele. Exact "flat-shaded facets like the MP pieces"
# din revizuirea coordonatorului.
emit([wall_obj, overhang_obj, shelf_obj], "rocks/stirling_ledge.glb", AO_WALL,
     origin="base_axis", bevel=0.06, smooth_angle=None, budget=3000,
     force_flat=True)

torrent_obj = build_torrent_chute()
emit(torrent_obj, "rocks/torrent_chute.glb", AO_WALL,
     origin="base_axis", bevel=0.08, smooth_angle=40.0, budget=1500)
chasm_obj = build_chasm_rock()
emit(chasm_obj, "rocks/chasm_rock.glb", AO_SMALL,
     bevel=0.04, budget=1500, force_flat=True)
guard_obj = build_guard_rock()
emit(guard_obj, "rocks/guard_rock.glb", AO_SMALL,
     bevel=0.012, budget=200, force_flat=True)
scree_obj = build_scree_slab()
emit(scree_obj, "rocks/scree_slab.glb", AO_SMALL,
     bevel=0.012, budget=3300, force_flat=True)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-34s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL rocks: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([wall_obj, overhang_obj, shelf_obj, torrent_obj, chasm_obj,
            guard_obj, scree_obj], "fiordland_rocks.blend")
