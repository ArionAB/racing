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


def _wall_body(b):
    """Masa principala a peretelui: bloc de 40 x 10 x 30 cu fata verticala
    spre -X (spre drum), platou plat in varf, CU UN GOL real pentru nisa
    (nu doar fete suprapuse peste o masa plina — fara boolean in pipeline,
    o "nisa" facuta ca fete desenate in fata unui bloc solid ramane invizibila,
    ingropata in interiorul blocului: exact bug-ul gasit la prima randare,
    unde profilul nu arata nicio adancitura).

    Fata frontala se construieste in DOUA benzi orizontale (sub si peste
    nisa) plus doua benzi laterale (stanga/dreapta nisei), care ocolesc
    fereastra X<~0.3, Z in [0, SL_NICHE_CLEAR], Y in [-hl, hl] — acolo
    tavanul/peretele/lateralele nisei (din `_niche()`) sunt SINGURELE
    suprafete, la adancimea reala SL_NICHE_DEPTH.
    """
    hl = SL_NICHE_LEN * 0.5
    rand = _lcg(4401)

    def front_band(y0, y1, z0, z1, ny, nz):
        """O banda din fata peretelui (X~0), intre y0..y1 si z0..z1."""
        grid = []
        for iz in range(nz + 1):
            tz = iz / nz
            z = z0 + (z1 - z0) * tz
            row = []
            for iy in range(ny + 1):
                ty = iy / ny
                y = y0 + (y1 - y0) * ty
                x_face = (rand() - 0.5) * 0.5
                row.append(b.bm.verts.new((x_face, y, z)))
            grid.append(row)
        fs = []
        for iz in range(nz):
            for iy in range(ny):
                fs.append(b.bm.faces.new(
                    (grid[iz][iy], grid[iz][iy + 1],
                     grid[iz + 1][iy + 1], grid[iz + 1][iy])))
        return fs

    faces = []
    front_faces = []
    # sub nisa: fasia de la baza (Z 0) pana la tavanul nisei nu exista sub
    # 0 (nisa porneste chiar de la sol), deci banda de "sub" e goala —
    # nisa se deschide direct la baza peretelui, ca un portic.
    # deasupra nisei: de la SL_NICHE_CLEAR pana in varf, pe toata lungimea
    front_faces += front_band(-SL_WALL_LEN * 0.5, SL_WALL_LEN * 0.5,
                              SL_NICHE_CLEAR, SL_WALL_H, 10, 4)
    # stanga si dreapta nisei, pe inaltimea nisei (0..SL_NICHE_CLEAR)
    front_faces += front_band(-SL_WALL_LEN * 0.5, -hl, 0.0, SL_NICHE_CLEAR, 3, 3)
    front_faces += front_band(hl, SL_WALL_LEN * 0.5, 0.0, SL_NICHE_CLEAR, 3, 3)
    faces += front_faces
    for f in front_faces:
        f[b.slot] = GNEISS

    # benzi orizontale de valoare (roca stratificata), zero triunghiuri
    b.retag(front_faces, WET_STREAK,
            where=lambda c, n: 0.16 * SL_WALL_H < c.z < 0.24 * SL_WALL_H)
    b.retag(front_faces, GNEISS,
            where=lambda c, n: 0.52 * SL_WALL_H < c.z < 0.62 * SL_WALL_H
            and c.z >= 0.24 * SL_WALL_H)

    # masa din spate: DOUA blocuri care ocolesc golul nisei —
    #   (1) blocul de deasupra nisei (Z de la NICHE_CLEAR pana la varf)
    #   (2) blocul din spatele nisei (X de la SL_NICHE_DEPTH pana la capat),
    #       care leaga si portiunea de sub/langa nisa cu cea de deasupra
    mass_faces = []
    mass_faces += list(b.box(
        (SL_WALL_DEEP * 0.5 + 0.1, 0.0, (SL_NICHE_CLEAR + SL_WALL_H) * 0.5),
        (SL_WALL_DEEP, SL_WALL_LEN, SL_WALL_H - SL_NICHE_CLEAR), GNEISS))
    back_x0 = SL_NICHE_DEPTH
    back_w = SL_WALL_DEEP - SL_NICHE_DEPTH + 0.2
    mass_faces += list(b.box(
        (back_x0 + back_w * 0.5, 0.0, SL_NICHE_CLEAR * 0.5),
        (back_w, SL_WALL_LEN, SL_NICHE_CLEAR), GNEISS))
    faces += mass_faces

    # platoul de sus: capac plat (fagii se pun la integrare, nu aici)
    top = b.box((SL_WALL_DEEP * 0.5, 0.0, SL_WALL_H + 0.15),
               (SL_WALL_DEEP + 1.0, SL_WALL_LEN + 1.0, 0.3), GNEISS)
    faces += list(top)
    b.retag(top, MOSS, where="up")

    return faces


def _niche(b):
    """Nisa concava sapata in fata peretelui: 30 m lungime, 4 m adancime,
    tavan la 7 m liber deasupra Shelf (care sta la Z=0, nod SEPARAT — vezi
    `_shelf`). Se construieste ca un gol REAL (nu doar retag): fara volum
    scobit, surplombul de mai sus ar pluti fara nimic dedesubt.

    Fete SEPARATE de Shelf: pana la #C2 aceasta functie si `_shelf` foloseau
    acelasi Builder, deci un Shelf construit intr-un obiect propriu (kitul
    de trei noduri din `_build_pieces`) mostenea si peretii nisei — Shelf
    iesea 4 m lat in loc de 3 (X 0..4 in loc de 0..3), verificat pe GLB, nu
    presupus. Acum fiecare functie ADAUGA doar fetele ei in `b`.
    """
    hl = SL_NICHE_LEN * 0.5
    depth = SL_NICHE_DEPTH
    clear_top = SL_SHELF_TOP + SL_NICHE_CLEAR  # tavanul nisei

    faces = []
    # Tavanul nisei: placa orizontala intre fata peretelui (X=0) si adancimea
    # nisei (X=depth), la cota clear_top. Fata de dedesubt (spre Shelf) e
    # cea vizibila -> umbra adanca.
    n = 6
    top_rows = []
    for i in range(n + 1):
        t = i / n
        y = -hl + SL_NICHE_LEN * t
        top_rows.append(y)
    tf = []
    inner = [b.bm.verts.new((depth, y, clear_top)) for y in top_rows]
    outer = [b.bm.verts.new((0.0, y, clear_top)) for y in top_rows]
    for i in range(n):
        tf.append(b.bm.faces.new(
            (outer[i], outer[i + 1], inner[i + 1], inner[i])))
    for f in tf:
        f[b.slot] = WET_STREAK
    faces += tf

    # Peretele din fundul nisei (la X=depth), de la Shelf pana la tavan:
    # ce se vede cand privesti spre stanca, sub surplomb.
    back = []
    lo = [b.bm.verts.new((depth, y, SL_SHELF_TOP)) for y in top_rows]
    hi = [b.bm.verts.new((depth, y, clear_top)) for y in top_rows]
    for i in range(n):
        back.append(b.bm.faces.new((lo[i], lo[i + 1], hi[i + 1], hi[i])))
    for f in back:
        f[b.slot] = WET_STREAK
    faces += back

    # Peretii laterali ai nisei (capetele, pe Y): inchid golul.
    for sy, y0 in ((-1.0, -hl), (1.0, hl)):
        side = b.bm.faces.new((
            b.bm.verts.new((0.0, y0, SL_SHELF_TOP)),
            b.bm.verts.new((depth, y0, SL_SHELF_TOP)),
            b.bm.verts.new((depth, y0, clear_top)),
            b.bm.verts.new((0.0, y0, clear_top)),
        )) if sy > 0 else b.bm.faces.new((
            b.bm.verts.new((depth, y0, SL_SHELF_TOP)),
            b.bm.verts.new((0.0, y0, SL_SHELF_TOP)),
            b.bm.verts.new((0.0, y0, clear_top)),
            b.bm.verts.new((depth, y0, clear_top)),
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
    """Surplombul: placa ce iese SL_LIP_OUT spre -X din fata peretelui,
    cu buza (fata din fata, cea vizibila de sub ea) la exact SL_LIP_Z.
    Deasupra buzei, o cuveta mica (marginea lacului suspendat) — aici doar
    silueta, apa o face codul."""
    hl = SL_NICHE_LEN * 0.5
    z = SL_LIP_Z
    thick = 1.8
    out_x = -SL_LIP_OUT
    n = 6
    rows = []
    for i in range(n + 1):
        t = i / n
        y = -hl + SL_NICHE_LEN * t
        rows.append(y)

    faces = []
    # fata de dedesubt (underside) — cea care se vede din masina, sub perdea
    under = [b.bm.verts.new((out_x, y, z)) for y in rows]
    root_lo = [b.bm.verts.new((0.0, y, z)) for y in rows]
    for i in range(n):
        f = b.bm.faces.new((under[i], under[i + 1], root_lo[i + 1], root_lo[i]))
        f[b.slot] = WET_STREAK
        faces.append(f)

    # fata de sus (capacul surplombului, spre platoul de sus)
    top = [b.bm.verts.new((out_x, y, z + thick)) for y in rows]
    root_hi = [b.bm.verts.new((0.0, y, z + thick)) for y in rows]
    for i in range(n):
        f = b.bm.faces.new((root_hi[i], root_hi[i + 1], top[i + 1], top[i]))
        f[b.slot] = GNEISS
        faces.append(f)

    # muchia din fata (buza propriu-zisa, verticala mica intre under si top)
    lip_edge = []
    for i in range(n):
        f = b.bm.faces.new((under[i], under[i + 1], top[i + 1], top[i]))
        f[b.slot] = GNEISS
        lip_edge.append(f)
    faces += lip_edge

    # capetele (Y) ale surplombului
    for sy, y0 in ((-1.0, rows[0]), (1.0, rows[-1])):
        u = Vector((out_x, y0, z))
        r = Vector((0.0, y0, z))
        t = Vector((0.0, y0, z + thick))
        o = Vector((out_x, y0, z + thick))
        verts = [b.bm.verts.new(u), b.bm.verts.new(r),
                 b.bm.verts.new(t), b.bm.verts.new(o)]
        f = b.bm.faces.new(verts) if sy > 0 else b.bm.faces.new(list(reversed(verts)))
        f[b.slot] = GNEISS
        faces.append(f)

    return faces


def _wet_streaks(b, wall_faces):
    """Dungi verticale ude: fete retag-uite VOLCANIC_BLACK in benzi de
    0.5-1.5 m care coboara de pe buza, nu pete. Determinist din seed."""
    rand = _lcg(4433)
    hl = SL_NICHE_LEN * 0.5
    bands = []
    y = -hl - 3.0
    while y < hl + 3.0:
        w = 0.5 + rand() * 1.0
        bands.append((y, y + w))
        y += w + 1.2 + rand() * 2.0

    def in_band(c):
        for lo, hi in bands:
            if lo <= c.y <= hi:
                return True
        return False

    b.retag(wall_faces, WET_STREAK,
            where=lambda c, n: in_band(c) and c.z < SL_LIP_Z and c.x < 0.6)


def _build_pieces():
    """stirling_ledge se exporta ca TREI obiecte (Wall include nisa,
    Overhang, Shelf) — trei Builder-e separate, ca sa iasa trei noduri
    curate fara sa despartim un bmesh unic dupa fapt."""
    bw = Builder()
    wall_faces = _wall_body(bw)
    niche_faces = _niche(bw)
    _wet_streaks(bw, wall_faces + niche_faces)
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


# --- chasm_rock --------------------------------------------------------------
#
# Contract: 6 x 4 x 2.5 m. Lespede rotunjita cu 2-3 marmite (0.8-1.5 m
# diametru, 0.6-1.0 m adancime), fundul gropilor VOLCANIC_BLACK, restul
# MARBLE_GREY cu muschi pe muchia de sus.
def build_chasm_rock():
    b = Builder()
    faces = list(b.rock((0.0, 0.0, 0.0), (6.0, 4.0, 2.5 / Builder.FLAT_TOP_FRAC),
                        GNEISS, seed=4501, segments=8, rings=3, taper=0.22,
                        flat_top=True, squash=0.92))
    top_z = Builder.flat_top_z(0.0, 2.5 / Builder.FLAT_TOP_FRAC)
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.55 and c.z > top_z * 0.75)

    rand = _lcg(4511)
    holes = 3
    for k in range(holes):
        a = math.radians(40.0 + k * 110.0 + rand() * 30.0)
        r = 1.6 + rand() * 0.7
        cx = math.cos(a) * r
        cy = math.sin(a) * r
        rad = 0.4 + rand() * 0.35
        depth = 0.35 + rand() * 0.25
        pit = b.cylinder((cx, cy, top_z - depth * 0.5), rad, depth,
                         WET_STREAK, segments=8, axis="Z")
        b.retag(pit, WET_STREAK)
    return b.to_object("Rock")


# --- guard_rock ----------------------------------------------------------
#
# Contract: 1.2 x 0.8 x 0.6 m. Bolovan scund de cornisa. MARBLE_GREY,
# muschi sus.
def build_guard_rock():
    b = Builder()
    faces = list(b.boulder((0.0, 0.0, 0.0), (1.2, 0.8, 0.6),
                           GNEISS, seed=4601, segments=6, rings=2,
                           deviation=0.16))
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.5 and c.z > 0.05)
    return b.to_object("Rock")


# --- scree_slab ------------------------------------------------------------
#
# Contract: 8 x 5 x 1.2 m. Placa de grohotis pe panta: pietre mici pe o
# panta JOASA, nu con (planul a desenat gramada gresit). SAND_SHADOW +
# MARBLE_GREY.
def build_scree_slab():
    b = Builder()
    faces = []
    # baza plina, joasa (panta lina, nu con)
    base = list(b.box((0.0, 0.0, 0.3), (8.0, 5.0, 0.6), SCREE))
    faces += base
    b.retag(base, GNEISS, where="up")

    rand = _lcg(4701)
    n_stones = 3
    for i in range(n_stones):
        x = (rand() - 0.5) * 7.2
        y = (rand() - 0.5) * 4.2
        s = 0.25 + rand() * 0.35
        z = 0.55 + s * 0.3
        b.boulder((x, y, z), (s * 1.4, s * 1.2, s * 0.9),
                  SCREE if i % 2 == 0 else GNEISS,
                  seed=4720 + i, segments=5, rings=2, deviation=0.14)
    return b.to_object("Rock")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.05, smooth_angle=45.0,
         budget=None):
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
emit([wall_obj, overhang_obj, shelf_obj], "rocks/stirling_ledge.glb", AO_WALL,
     origin="base_axis", bevel=0.08, smooth_angle=35.0, budget=3000)

torrent_obj = build_torrent_chute()
emit(torrent_obj, "rocks/torrent_chute.glb", AO_WALL,
     origin="base_axis", bevel=0.08, smooth_angle=40.0, budget=1500)
chasm_obj = build_chasm_rock()
emit(chasm_obj, "rocks/chasm_rock.glb", AO_SMALL,
     bevel=0.05, budget=600)
guard_obj = build_guard_rock()
emit(guard_obj, "rocks/guard_rock.glb", AO_SMALL,
     bevel=0.015, budget=80)
scree_obj = build_scree_slab()
emit(scree_obj, "rocks/scree_slab.glb", AO_SMALL,
     bevel=0.05, budget=300)

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
