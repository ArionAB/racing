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


SL_CAPS = []    # petice de muschi (x0, x1, y0, y1, z) pentru nodul Overhang
SL_BASE_Z = -0.4      # baza peretelui in coordonate de build (contract: Shelf la +0.4 in GLB)
SL_TOP_Z = 26.2       # coama (26.6 in GLB)
SL_BACK_X = 12.2


def _sl_crest(y):
    """Coama coboara in trepte mari dinspre -Y (26.2) spre +Y (~17.5)."""
    if y < -9.0:
        return 26.2
    if y < -1.0:
        return 23.4
    if y < 8.0:
        return 20.6
    return 17.6


def _column(b, rand, y0, y1, zb, zt, xf, slot, ridge=0.55, tier=None, back=SL_BACK_X,
            skew=0.9, lean_k=0.5):
    """Coloana prismatica fatetata: fata spre -X are o creasta, capul inclinat,
    marginile de sus decalate pe Y (muchii care nu sunt verticale). Cu `tier` =
    (z_treapta, retragere) fata se retrage deasupra treptei."""
    def hullpts(z0, z1, xfront, ridge_on):
        sk = (rand() - 0.5) * skew
        ym = (y0 + y1) * 0.5 + (rand() - 0.5) * (y1 - y0) * 0.25
        lean = (rand() - 0.3) * lean_k
        pts = [(xfront, y0, z0), (xfront, y1, z0),
               (xfront + lean, y0 + sk, z1), (xfront + lean, y1 + sk, z1),
               (back, y0, z0), (back, y1, z0), (back, y0 + sk, z1), (back, y1 + sk, z1)]
        if ridge_on:
            r = min(ridge * (0.5 + rand()), max(xfront + 1.2, 0.0))
            pts.append((xfront - r, ym, z0 + (z1 - z0) * (0.25 + rand() * 0.4)))
            pts.append((xfront - r * 0.6, ym + sk * 0.5, z1 - (z1 - z0) * 0.08))
        return pts
    if tier is None:
        return _hull(b, hullpts(zb, zt, xf, True), slot, 5.0)
    zs, ret = tier
    fs = _hull(b, hullpts(zb, zs, xf, True), slot, 5.0)
    fs |= _hull(b, hullpts(zs - 0.6, zt, xf + ret, True), slot, 5.0)
    return fs


def _wall_body(b):
    """v4: relief mare (clasa wet_gneiss sterge fatetele mici). Coama in 4 trepte
    spre +Y; masa de spate retrasa (x=3.6) + CONTRAFORTI ingusti care ies pana la
    x=-1.2, cu goluri adanci intre ei, la capete si deasupra surplombului;
    capetele in trepte pe Y; blocuri cazute la baza capetelor. Nisa ramane gol."""
    global SL_CAPS
    SL_CAPS = []
    rand = _lcg(5531)
    faces = set()
    hl = SL_NICHE_LEN * 0.5
    YL, YR = -20.2, 20.2

    def split(a, bnd, n, wmin):
        ws = [wmin + rand() for _ in range(n)]
        t = sum(ws)
        out, y = [], a
        for w in ws:
            out.append((y, y + (bnd - a) * w / t))
            y += (bnd - a) * w / t
        return out

    # --- masa de spate: capete pe toata inaltimea, mijloc doar deasupra nisei
    for (a, bnd) in ((YL, -hl), (hl, YR)):
        for (y0, y1) in split(a, bnd, 2, 0.8):
            zt = _sl_crest((y0 + y1) * 0.5) - 0.8 * rand()
            faces |= _column(b, rand, y0 - 0.1, y1 + 0.1, SL_BASE_Z, zt, 3.0 + rand() * 0.8,
                             GNEISS, tier=(11.0 + rand() * 4.0, 1.0 + rand()))
    mids = split(-hl, hl, 8, 0.7)
    for i, (y0, y1) in enumerate(mids):
        ym = (y0 + y1) * 0.5
        zt = _sl_crest(ym) - rand() * 1.8
        xf = 1.0 + rand() * 2.6
        faces |= _column(b, rand, y0 - (0.1 if i else 0.0), y1 + (0.1 if i < 7 else 0.0),
                         SL_NICHE_CLEAR + 0.05, zt, xf, GNEISS,
                         tier=(zt - 3.5 - rand() * 2.5, 0.8 + rand() * 0.8) if i % 2 == 0 else None)
        if i % 3 == 0:
            SL_CAPS.append((xf + 1.8, SL_BACK_X - 1.5, y0 + 0.4, y1 - 0.4, zt))

    # --- contraforti la capete (ies pana la x = -1.2, goluri de ~0.8 m intre ei)
    for sg in (-1.0, 1.0):
        y = 15.1
        k = 0
        while y < 19.9:
            w = 1.3 + rand() * 1.0
            y1 = min(y + w, 20.2)
            yc = sg * (y + y1) * 0.5
            zt = _sl_crest(yc) - (0.0 if (sg < 0 and k == 1) else 1.0 + rand() * 4.5)
            xf = (-0.9, 0.2, -0.4, 0.6)[k % 4]
            ya, yb = sorted((sg * y, sg * y1))
            # capetele se decaleaza pe Y (zimti in plan), nu o muchie dreapta
            ya += (rand() - 0.5) * 0.5
            faces |= _column(b, rand, ya, yb, SL_BASE_Z, zt, xf, GNEISS, ridge=0.7, back=5.5,
                             skew=1.6, lean_k=1.2,
                             tier=(zt * (0.55 + rand() * 0.2), 0.7 + rand() * 0.6) if zt > 14 else None)
            if zt > 15:
                SL_CAPS.append((xf + 0.2, xf + 2.8, ya + 0.15, yb - 0.15, zt))
            y = y1 + 0.5 + rand() * 0.6
            k += 1

    # --- contraforti deasupra surplombului (z 17..coama), peste nisa
    ups = ((-14.0, 2.4, 0.2), (-9.0, 2.0, 1.0), (-4.6, 2.8, -0.2), (0.4, 2.2, 0.8),
           (5.0, 2.4, 0.4), (10.0, 2.6, 1.2))
    for (yc, w, xf) in ups:
        zt = _sl_crest(yc) - rand() * 1.4
        if zt < 19.5:
            continue
        faces |= _column(b, rand, yc - w * 0.5, yc + w * 0.5, 16.8, zt, xf, GNEISS, ridge=0.6,
                         back=6.0, skew=1.4, lean_k=1.0)
        SL_CAPS.append((xf + 0.4, xf + 3.0, yc - w * 0.5 + 0.2, yc + w * 0.5 - 0.2, zt))

    # --- blocuri cazute la baza capetelor, in afara Shelf-ului (|Y| >= 15,2)
    for sg in (-1.0, 1.0):
        for n_st, (lo, hi, ylo, yhi) in ((5, (1.8, 3.0, 17.0, 19.6)), (6, (0.8, 1.7, 16.0, 20.6))):
            for _ in range(n_st):
                sx = lo + rand() * (hi - lo)
                y = sg * (ylo + rand() * (yhi - ylo))
                x = 0.9 + rand() * 3.6
                pts = _stone_pts(rand, (x, y, SL_BASE_Z + sx * 0.45), (sx * 1.2, sx * 1.1, sx),
                                 n=9, base_cut=0.5, spread=0.3)
                faces |= _hull(b, pts, GNEISS, 6.0)
    front_faces = [f for f in faces if f.is_valid]

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
    """Surplomb v3: PANA din 10 segmente-prisma fatetate (buza neregulata in
    plan, iesiri 8.4-10 m), sus MUSCHI, dedesubt gneis cu dungi ude. Buza
    (cota cea mai joasa) ramane la 13.6 in build = 14.0 in GLB (contract).
    Plus lespezile de muschi (SL_CAPS) de pe terasele si coama peretelui."""
    hl = SL_NICHE_LEN * 0.5
    rand = _lcg(5577)
    n = 10
    ys = [-hl + SL_NICHE_LEN * i / n for i in range(n + 1)]
    faces = set()
    for i in range(n):
        y0, y1 = ys[i] - (0.08 if i else 0.0), ys[i + 1] + (0.08 if i < n - 1 else 0.0)
        out = SL_LIP_OUT + 0.4 + (rand() - 0.5) * 2.2
        if i == 0 or i == n - 1:
            out = min(out, SL_LIP_OUT + 0.7)
        lt = 1.6 + rand() * 1.2
        ym = (y0 + y1) * 0.5
        rh = min(SL_LIP_Z + 7.0, _sl_crest(ym) - 0.6)
        sk = (rand() - 0.5) * 0.7
        pts = [(-out, y0, SL_LIP_Z), (-out, y1, SL_LIP_Z),
               (-out + 0.2, y0 + sk, SL_LIP_Z + lt), (-out + 0.2, y1 + sk, SL_LIP_Z + lt),
               (SL_WALL_DEEP * 0.35, y0, SL_LIP_Z - 0.4), (SL_WALL_DEEP * 0.35, y1, SL_LIP_Z - 0.4),
               (SL_WALL_DEEP * 0.35, y0, rh), (SL_WALL_DEEP * 0.35, y1, rh),
               (-out * 0.45, ym + sk, min(SL_LIP_Z + lt + 1.7 + rand() * 0.8, rh - 0.3)),
               (-out * 0.55, ym, SL_LIP_Z - 0.15)]
        fs = _hull(b, pts, GNEISS, 5.0)
        for f in fs:
            c = f.calc_center_median()
            if f.normal.z > 0.35:
                # muschi doar pe jumatatea dinspre perete + pete; fata din fata ramane gneis
                f[b.slot] = MOSS if (i in (2, 3, 6, 8) and c.x > -out * 0.2) else GNEISS
            elif f.normal.z < -0.3:
                f[b.slot] = WET_STREAK
            elif f.normal.x < -0.5 and i % 3 == 0:
                f[b.slot] = WET_STREAK      # dunga udata pe fata buzei
        faces |= fs
    # terase / coama cu muschi (lespezi subtiri cu margine neregulata)
    for (x0, x1, y0, y1, z) in SL_CAPS:
        if x1 <= x0 or y1 <= y0:
            continue
        w, d = (y1 - y0), (x1 - x0)
        j = lambda: (rand() - 0.5) * 0.5
        pts = [(x0 + j(), y0 + j(), z + 0.02), (x1 + j(), y0 + j(), z + 0.02),
               (x1 + j(), y1 + j(), z + 0.02), (x0 + j(), y1 + j(), z + 0.02),
               ((x0 + x1) * 0.5, y0 + 0.35 + j(), z + 0.02), ((x0 + x1) * 0.5, y1 - 0.35 + j(), z + 0.02)]
        pts2 = [(p[0], p[1], p[2] + 0.18 + rand() * 0.12) for p in pts]
        fs = _hull(b, pts + pts2, MOSS, 3.0)
        faces |= fs
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
    """v4 (contract relaxat: Z pana la ~34, Y pana la ~24): masiv cu PISC. Jgheab
    in V/U cu 7 trepte negre taiat in fata, contraforti laterali inalti de o
    parte si de alta (21-24 m langa jgheab, scazand spre margini), buza la +14
    (3 m peste banda), cuveta goala cu margine de blocuri, si DEASUPRA/in spatele
    ei un pisc neregulat din coloane de 18-24 m. Blocuri la picior."""
    b = Builder()
    rand = _lcg(6633)
    back = 11.0
    faces = set()

    def hw(z):
        return 5.0 + 5.0 * min(z, TC_LIP_Z) / TC_LIP_Z

    OUT = 17.0
    # --- contraforturi laterale: 4 coloane pe parte, inaltimi scazand spre exterior
    hts = {-1: (21.0, 17.5, 12.5, 8.0), 1: (23.4, 19.0, 14.0, 9.0)}
    for sg in (-1.0, 1.0):
        for j in range(4):
            ha = hts[int(sg)][j]
            xf = 0.0 + rand() * 1.8 + (0.0 if j < 2 else 0.8)
            lean = (rand() - 0.2) * 0.9
            fa, fb = j / 4.0, (j + 1) / 4.0 + (0.05 if j < 3 else 0.0)

            def ypos(z, f, sg=sg):
                return sg * (hw(z) + (OUT - hw(z)) * f)
            sk = (rand() - 0.5) * 1.6
            pts = []
            for z in (0.0, ha):
                for f in (fa, fb):
                    yy = ypos(z, f) + (sk if z else 0.0)
                    pts.append((xf + (lean if z else 0.0), yy, z))
                    pts.append((back, yy, z))
            r = 0.4 + rand() * 0.7
            pts.append((max(-0.8, xf - r), ypos(ha * 0.4, (fa + fb) * 0.5), ha * 0.4))
            pts.append((max(-0.8, xf - r * 0.6), ypos(ha * 0.92, (fa + fb) * 0.5) + sk * 0.5, ha * 0.92))
            fs = _hull(b, pts, GNEISS, 5.0)
            for f in fs:
                if f.normal.z > 0.5 and j >= 1:
                    f[b.slot] = MOSS if rand() < 0.75 else GNEISS
            faces |= fs

    # --- patul jgheabului: 7 trepte de piatra neagra, pana la spatele masivului
    nst = 7
    for i in range(nst):
        z = TC_LIP_Z * (i + 1) / nst
        x0 = 3.0 * i / (nst - 1) if i else 0.0
        w = hw(z) + 0.4
        jit = lambda: (rand() - 0.5) * 0.35
        pts = []
        for zz in (0.0, z):
            pts += [(x0 + jit(), -w, zz), (x0 + jit(), w, zz), (back, -w, zz), (back, w, zz)]
        pts += [(x0 - 0.15, jit() * 3, z - 0.2)]
        fs = _hull(b, pts, GNEISS, 5.0)
        for f in fs:
            if f.normal.z > 0.5:
                f[b.slot] = WET_STREAK
            elif f.normal.x < -0.5 and i % 2 == 0:
                f[b.slot] = WET_STREAK
        faces |= fs

    # --- buza: 3 segmente fatetate, 3 m peste banda (x = -3), la z = 14
    ys = (-10.0, -3.4, 3.2, 10.0)
    for k in range(3):
        y0, y1 = ys[k] - 0.05, ys[k + 1] + 0.05
        lo = TC_LIP_OUT + ((rand() - 0.5) * 0.5 if k == 1 else 0.0)
        lt = 1.3 + (rand() - 0.5) * 0.3
        sk = (rand() - 0.5) * 0.5
        pts = [(-lo, y0, TC_LIP_Z), (-lo, y1, TC_LIP_Z),
               (-lo + 0.2, y0 + sk, TC_LIP_Z + lt), (-lo + 0.2, y1 + sk, TC_LIP_Z + lt),
               (3.5, y0, TC_LIP_Z - 0.3), (3.5, y1, TC_LIP_Z - 0.3),
               (3.5, y0, TC_LIP_Z + lt), (3.5, y1, TC_LIP_Z + lt),
               (-lo * 0.4, (y0 + y1) * 0.5, TC_LIP_Z - 0.2)]
        fs = _hull(b, pts, GNEISS, 5.0)
        for f in fs:
            if f.normal.z < -0.3:
                f[b.slot] = WET_STREAK
        faces |= fs

    # --- umerii laterali ai cuvetei (terase joase cu muschi, langa cuveta)
    for (y0, y1, zt) in ((-9.4, -3.9, 16.6), (3.9, 9.4, 17.4)):
        pts = [(3.5, y0, TC_LIP_Z), (3.5, y1, TC_LIP_Z), (9.5, y0, TC_LIP_Z), (9.5, y1, TC_LIP_Z),
               (3.7, y0 + 0.3, zt), (3.7, y1 - 0.3, zt), (9.0, y0 + 0.6, zt + 0.8), (9.0, y1 - 0.6, zt + 0.8),
               (3.0, (y0 + y1) * 0.5, zt - 1.0)]
        fs = _hull(b, pts, GNEISS, 5.0)
        for f in fs:
            if f.normal.z > 0.5:
                f[b.slot] = MOSS
        faces |= fs

    # --- PISCUL: 6 coloane in spatele cuvetei, 18-24 m, neregulate in plan
    summit = ((-9.0, -5.8, 7.4, 20.5), (-6.2, -2.4, 8.4, 22.4), (-2.8, 1.2, 7.2, 24.0),
              (0.8, 4.4, 8.6, 21.8), (4.0, 7.4, 7.6, 19.6), (7.0, 10.0, 9.0, 17.8))
    for (y0, y1, xf, zt) in summit:
        sk = (rand() - 0.5) * 1.4
        pts = [(xf, y0, TC_LIP_Z), (xf, y1, TC_LIP_Z), (back, y0 - 0.5, TC_LIP_Z), (back, y1 + 0.5, TC_LIP_Z),
               (xf + 0.6, y0 + sk, zt), (xf + 0.6, y1 + sk, zt),
               (back - 1.2, y0 + 0.3, zt - 1.0), (back - 1.2, y1 - 0.3, zt - 1.0),
               (xf - 0.9, (y0 + y1) * 0.5, zt - 2.4), (xf - 0.3, (y0 + y1) * 0.5 + sk * 0.5, zt - 0.3)]
        fs = _hull(b, pts, GNEISS, 5.0)
        for f in fs:
            if f.normal.z > 0.6 and zt < 21:
                f[b.slot] = MOSS
        faces |= fs

    # --- cuveta suspendata: fund negru, margine de blocuri joase cu muschi
    faces |= set(b.box((5.3, 0.0, TC_LIP_Z + 1.55), (3.0, 6.0, 0.1), WET_STREAK))
    rim = (((5.3, -3.5), (3.2, 1.6, 0.5)), ((5.3, 3.5), (3.2, 1.6, 0.45)),
           ((3.5, 0.0), (1.0, 6.4, 0.4)))
    for (cx, cy), (sx, sy, sz) in rim:
        pts = _stone_pts(rand, (cx, cy, TC_LIP_Z + 1.5 + sz * 0.5), (sx, sy, sz * 1.8),
                         n=8, base_cut=0.5, spread=0.2)
        fs = _hull(b, pts, GNEISS, 6.0)
        for f in fs:
            if f.normal.z > 0.5:
                f[b.slot] = MOSS
        faces |= fs
    # --- blocuri la picior: in gura si la baza contraforturilor (x >= -1.2)
    spots = [(-0.6, -3.6, 1.4), (-0.9, -0.5, 1.1), (-0.4, 2.8, 1.5), (-0.8, 4.4, 1.0)]
    for sg in (-1.0, 1.0):
        for yy, sx, x in ((8.0, 2.4, 0.4), (11.0, 2.0, 0.8), (14.0, 2.6, 1.0), (16.0, 1.5, 1.6),
                          (9.5, 1.2, -0.5), (12.5, 1.4, -0.3)):
            spots.append((x, sg * yy, sx))
    for (cx, cy, sx) in spots:
        pts = _stone_pts(rand, (cx, cy, sx * 0.5), (sx * 1.2, sx * 1.1, sx),
                         n=9, base_cut=0.5, spread=0.3)
        faces |= _hull(b, pts, GNEISS, 6.0)
    return b.to_object("Rock")


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


def _round_stone(b, rand, c, size, slot, cnt=(5, 5, 3)):
    """Piatra GHEMUITA rotunjit-poliedrica (fara varfuri/piramide): 3 inele
    (5 jos, 5 la mijloc rotit, 3 sus). `size` = diametre (x, y, z)."""
    cx, cy, cz = c
    sx, sy, sz = size
    pts = []
    for z, n, r, rot in ((0.0, cnt[0], 0.90, 0.0), (0.5, cnt[1], 1.0, 0.63), (0.88, cnt[2], 0.45, 0.3)):
        for i in range(n):
            a = rot + 2 * math.pi * i / n + (rand() - 0.5) * 0.35
            k = r * (0.88 + rand() * 0.24)
            pts.append((cx + math.cos(a) * k * sx * 0.5,
                        cy + math.sin(a) * k * sy * 0.5,
                        cz + z * sz * (0.9 + rand() * 0.2)))
    return _hull(b, pts, slot, 7.0)


def _clip_poly(pts, axis, c, keep_ge):
    """Sutherland-Hodgman pe un semiplan axa >= c (sau <= c)."""
    def inside(p):
        return p[axis] >= c if keep_ge else p[axis] <= c
    out = []
    for i in range(len(pts)):
        p, q = pts[i], pts[(i + 1) % len(pts)]
        if inside(p):
            out.append(p)
        if inside(p) != inside(q):
            t = (c - p[axis]) / (q[axis] - p[axis])
            out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return out


def _normalize_xy(obj, sx, sy):
    """Scaleaza XY pe obiect ca bbox-ul sa fie (sx, sy) -- tine AABB-ul in contract."""
    vs = obj.data.vertices
    x0 = min(v.co.x for v in vs); x1 = max(v.co.x for v in vs)
    y0 = min(v.co.y for v in vs); y1 = max(v.co.y for v in vs)
    kx, ky = sx / (x1 - x0), sy / (y1 - y0)
    cx, cy = (x0 + x1) * 0.5, (y0 + y1) * 0.5
    for v in vs:
        v.co.x = (v.co.x - cx) * kx
        v.co.y = (v.co.y - cy) * ky


def _cutter_cyl(b, cx, cy, r, z0, z1, n=9):
    pts = [(cx + math.cos(2 * math.pi * i / n) * r, cy + math.sin(2 * math.pi * i / n) * r)
           for i in range(n)]
    _prism_xy(b, pts, z0, lambda x, y: z1, VOLCANIC_BLACK)


def build_chasm_rock(pits_on=True, name="Rock"):
    """v3 (constructor nou): siluet intai. Contur de sus lobat cu 3 intrande,
    baza ~1.2x mai larga (movila, nu tambur), coloane de latimi si inaltimi
    diferite impinse in/out, 3 lespezi la cote diferite despartite de crapaturi,
    2 marmite 3-lobate taiate adanc."""
    import bpy as _bpy
    rand = _lcg(4521)
    n = 18
    # unghiuri neuniforme -> coloane de latimi diferite
    ws = [0.55 + rand() * 1.0 for _ in range(n)]
    tot = sum(ws)
    angs, acc = [], 0.0
    for w in ws:
        angs.append(2 * math.pi * acc / tot + 0.2)
        acc += w
    notches = {2, 8, 13}
    top, base = [], []
    for i, a in enumerate(angs):
        k = 1.0 + (rand() * 2 - 1) * 0.16
        if i in notches:
            k *= 0.66
        elif (i - 1) in notches or (i + 1) % n in notches:
            k *= 0.9
        top.append((math.cos(a) * 2.35 * k, math.sin(a) * 1.85 * k))
        kb = 1.0 + (rand() * 2 - 1) * 0.07
        kk = k * kb * 1.22 * (1.15 if i in notches else 1.0)
        base.append((math.cos(a) * 2.35 * kk, math.sin(a) * 1.85 * kk))

    # --- lespezile de sus (3 cote) despartite de crapaturi
    outline = [(x * 0.9, y * 0.9) for x, y in top]
    gap = 0.07
    A = _clip_poly(outline, 1, 0.25 + gap, True)
    rest = _clip_poly(outline, 1, 0.25 - gap, False)
    B = _clip_poly(rest, 0, 1.0 - gap, False)
    C = _clip_poly(rest, 0, 1.0 + gap, True)
    slabs = [(A, 2.50), (B, 2.02), (C, 1.72)]
    bs = Builder()
    for poly, zt in slabs:
        _prism_xy(bs, poly, 0.0, lambda x, y, zt=zt: zt + 0.03 * x - 0.02 * y, GNEISS)
    slab_obj = bs.to_object("ChasmSlabs")
    pits = [(-0.35, -0.95, 1.02, 0.7, 0.55), (-1.05, 1.0, 0.68, 2.0, 1.05)]
    if not pits_on:
        pits = []
    for (px, py, r, phi, zfloor) in pits:
        for q in range(3):
            a = phi + q * 2 * math.pi / 3
            bk = Builder()
            _cutter_cyl(bk, px + math.cos(a) * 0.35 * r, py + math.sin(a) * 0.35 * r,
                        0.66 * r, zfloor, 3.4)
            cut = bk.to_object("ChasmCut")
            m = slab_obj.modifiers.new("pit", "BOOLEAN")
            m.operation = "DIFFERENCE"
            m.solver = "EXACT"
            m.object = cut
            with _bpy.context.temp_override(object=slab_obj, active_object=slab_obj):
                _bpy.ops.object.modifier_apply(modifier="pit")
            cm = cut.data
            _bpy.data.objects.remove(cut, do_unlink=True)
            _bpy.data.meshes.remove(cm)
    # culoare dupa pozitie: in jurul marmitelor, tot ce e sub cota lespezii = negru
    me = slab_obj.data
    attr = me.attributes["slot"]
    for poly in me.polygons:
        c = poly.center
        col = GNEISS
        for (px, py, r, phi, zfloor) in pits:
            if math.hypot(c.x - px, c.y - py) < 1.5 * r and c.z < 1.88:
                col = VOLCANIC_BLACK
        attr.data[poly.index].value = col

    # --- coloanele de flanc: prisme fatetate, impinse in/out, inaltimi diferite
    b = Builder()
    for k in range(n):
        j = (k + 1) % n
        mx = (top[k][0] + top[j][0]) * 0.5
        my = (top[k][1] + top[j][1]) * 0.5
        zs = 2.50 if my > 0.25 else (2.02 if mx < 1.0 else 1.72)
        h = zs - 0.15 - rand() * 0.55 + (0.12 if rand() < 0.25 else 0.0)
        h = max(0.95, min(2.5, h))
        a1 = angs[j] + (2 * math.pi if j == 0 else 0.0)
        am = (angs[k] + a1) * 0.5
        push = (rand() * 2 - 1) * 0.3
        ux, uy = math.cos(am), math.sin(am)
        pts = []
        for p in (base[k], base[j]):
            pts.append((p[0] + ux * push, p[1] + uy * push, 0.0))
        for p in (top[k], top[j]):
            pts.append((p[0] + ux * push, p[1] + uy * push, h))
        for p in (top[k], top[j]):
            pts.append((p[0] * 0.84, p[1] * 0.84, h))
        for p in (base[k], base[j]):
            pts.append((p[0] * 0.84, p[1] * 0.84, 0.0))
        _hull(b, pts, GNEISS, 6.0)
    # blocuri late la baza, acelasi limbaj
    for (ang, sz) in ((215, (1.5, 1.2, 0.9)), (292, (1.7, 1.2, 0.8)), (20, (1.3, 1.1, 0.85))):
        a = math.radians(ang)
        _round_stone(b, rand, (math.cos(a) * 2.7, math.sin(a) * 2.15, 0.0), sz, GNEISS)
    obj = b.to_object(name)
    with _bpy.context.temp_override(object=obj, active_object=obj,
                                    selected_objects=[obj, slab_obj],
                                    selected_editable_objects=[obj, slab_obj]):
        _bpy.ops.object.join()
    _normalize_xy(obj, 6.0, 4.72)
    # fata (marmita mare, treapta joasa) trebuie sa dea spre camera de joc/preview (+Y)
    for v in obj.data.vertices:
        v.co.y = -v.co.y
    obj.data.flip_normals()
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
# v3 (constructor nou): un con ABRUPT (11 segmente x 5 inele), varful deplasat
# spre spate (+Y), 3 rape coborand pe flanc, fete late plane, culoare PE FATA
# (MARBLE_GREY / gri mediu / negru doar in rape), fusta de blocuri ingropate si
# inel de pietre rotunjit-poliedrice. Y max 2.2 (contract schimbat, off-road).
def build_scree_slab():
    b = Builder()
    rand = _lcg(4733)
    nseg, nring = 11, 5
    rx, ry, H = 1.8, 3.1, 2.2
    peak = (0.15, 0.85)
    gullies = {1, 5, 8}
    rows = []
    for j in range(nring):
        t = j / nring
        rr = 1.0 - t
        h = H * (1.0 - rr ** 1.15)
        ring = []
        for i in range(nseg):
            a = 2 * math.pi * (i + (rand() - 0.5) * 0.3) / nseg
            k = 1.0 + (rand() * 2 - 1) * (0.10 if j < 2 else 0.06)
            g = 0.0
            if i in gullies and j >= 1:
                g = 0.30 * H * (0.35 + 0.65 * t)
                k *= 0.95
            cx = peak[0] * (1 - rr)
            cy = peak[1] * (1 - rr)
            z = max(0.0, h - g + ((rand() - 0.5) * 0.12 if j else 0.0))
            ring.append(b.bm.verts.new((cx + math.cos(a) * rx * rr * k,
                                         cy + math.sin(a) * ry * rr * k, z)))
        rows.append(ring)
    apex = b.bm.verts.new((peak[0], peak[1], H))

    def pick(i, j):
        if (i in gullies or (i + 1) % nseg in gullies) and rand() < 0.45 and j >= 1:
            return VOLCANIC_BLACK
        return ASPHALT_EDGE if rand() < 0.32 else MARBLE_GREY
    for j in range(nring - 1):
        for i in range(nseg):
            i2 = (i + 1) % nseg
            f = b.bm.faces.new((rows[j][i], rows[j][i2], rows[j + 1][i2], rows[j + 1][i]))
            f[b.slot] = pick(i, j)
    for i in range(nseg):
        i2 = (i + 1) % nseg
        f = b.bm.faces.new((rows[-1][i], rows[-1][i2], apex))
        f[b.slot] = pick(i, nring)
    # fusta: blocuri mari, pe jumatate ingropate la picior
    for i in range(9):
        a = 2 * math.pi * (i + rand() * 0.6) / 9
        s = 0.5 + rand() * 0.45
        _round_stone(b, rand, (math.cos(a) * rx * 1.0, math.sin(a) * ry * 1.0, -0.1),
                     (s * 1.2, s * 1.0, s * 0.85),
                     MARBLE_GREY if rand() < 0.7 else ASPHALT_EDGE)
    # inel de pietre scazute, 7-9 fete
    for _ in range(30):
        a = rand() * 2 * math.pi
        k = 1.10 + rand() * 0.30
        x = math.cos(a) * rx * k
        y = math.sin(a) * ry * k
        s = min(0.22 + rand() * rand() * 0.9, 0.6)
        _round_stone(b, rand, (x, y, -0.03), (s * 1.3, s * 1.1, s * 0.8),
                     MARBLE_GREY if rand() < 0.72 else ASPHALT_EDGE, cnt=(4, 4, 2))
    obj = b.to_object("Rock")
    _normalize_xy(obj, 5.0, 8.0)
    return obj


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
     origin="base_axis", bevel=0.06, smooth_angle=None, budget=4600,
     force_flat=True)

torrent_obj = build_torrent_chute()
emit(torrent_obj, "rocks/torrent_chute.glb", AO_WALL,
     origin="base_axis", bevel=0.07, smooth_angle=None, budget=3600, force_flat=True)
chasm_obj = build_chasm_rock()
emit(chasm_obj, "rocks/chasm_rock.glb", AO_SMALL,
     bevel=0.04, budget=2100, force_flat=True)
block_obj = build_chasm_rock(pits_on=False, name="Gneiss_Block")
emit(block_obj, "rocks/gneiss_block.glb", AO_SMALL,
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
            guard_obj, scree_obj, block_obj], "fiordland_rocks.blend")
