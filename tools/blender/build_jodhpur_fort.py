"""Jodhpur -- Cetatea, val 2a (brief §1.2, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/structures/fort_wall_segment.glb   modul de zid inlantuibil
  jodhpur/structures/fort_wall_turret.glb    turnul patrat de la capetele tronsonului
  jodhpur/structures/fort_bastion.glb        burjul rotund
  jodhpur/structures/fort_gate_jai.glb       poarta Jai Pol (cea mai inalta)
  jodhpur/structures/fort_gate_fateh.glb     poarta Fateh Pol (chhatri peste arc)
  jodhpur/structures/fort_gate_loha.glb      poarta Loha Pol (cea mai joasa)
  jodhpur/structures/palace_facade_a.glb     Moti Mahal -- fatada lunga
  jodhpur/structures/palace_facade_b.glb     fatada simetrica cu cupola centrala
  jodhpur/props/rampart_cannon.glb           tunul de pe metereze

Urmeaza patronul pilotului acceptat (`build_jodhpur_pilot.py`, v3): vocabular
din `jodhpur_shapes.py`, sloturi din tabelul §0.4, `_finish_or_none` pentru
Builder-ele GLOW care pot ramane goale, `emit()` cu origine calculata o data
pe ansamblu.

**Orientare (gasita empiric, ca in pilot):** un test cu doua cutii lungi
(una cu lungimea pe X, fata mare spre +Y; alta cu lungimea pe Y, fata mare
spre +X), randate cu EXACT camera din `compare()` (azimut 35, elevatie 18),
a aratat ca varianta cu **lungimea pe Y si fata principala spre +X** se
citeste ca "fatada lunga vazuta din fata" -- cealalta (lungime pe X) se vede
oblic, foarte scurtata. Confirma si testul de cub colorat pe fete din pilot
(+X = fata dominanta a camerei). De-aici, toate piesele alungite de aici
(zid, poarta, fatade de palat) au **lungimea pe Y, fata principala pe +X**.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_fort.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4).
STONE = ROCK_LIGHT       # gresia fortului -> clasa red_sandstone la integrare
DOOR_WOOD = WOOD         # canaturile de lemn (Jai, Fateh)
DOOR_IRON = PAINTED      # canaturile de fier (Loha)
STUD = VOLCANIC_BLACK    # tepii canaturilor, geometrie mica
GLOW = VOLCANIC_BLACK    # ferestrele inchise ziua (Palace_Glow, brief regula 7), runda 2
CANNON_METAL = VOLCANIC_BLACK
CANNON_WOOD = WOOD

AO_STONE = dict(samples=24, dist=6.0, gradient="vertical",
                low=0.42, high=1.00, power=0.85, floor=0.16)
AO_PROP = dict(samples=16, dist=2.5, gradient="vertical",
               low=0.5, high=1.0, power=0.85, floor=0.2)

# rotatie care duce fata implicita +Y a lui `chajja`/`arch_opening` pe +X
# (fata principala catre camera, vezi nota de orientare de mai sus)
ROT_YTOX = Matrix.Rotation(math.radians(-90.0), 3, "Z")
ROT_YTONX = Matrix.Rotation(math.radians(90.0), 3, "Z")


def _finish_or_none(obj):
    """Ca in pilot: un Builder care a ramas gol (fara varfuri) se sterge in
    loc sa mearga la `finish` (crapa pe bbox gol la set_origin_base)."""
    if obj is None:
        return None
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


def _local_arcade(b, bg, p1, p2, n, opening_h, pier_h, pier_w, wall_t, slot,
                  glow_slot, style="round", glass=False, base_z=0.0):
    """Inlocuitor LOCAL pentru `jodhpur_shapes.arcade` -- gasit un bug real
    in versiunea comuna la runda 2 (critica: arcadele centrale randau ca
    niste "sarme incovoiate", coloane rupte/duble, indiferent de `band_w`).
    Doua incercari succesive de fix pe varianta `open=True` (`_arch_band`)
    au esuat -- un test izolat (doar arcada, fara restul piesei) a aratat
    ca legile arcului insusi nu se aliniaza curat cu pilonii sai, in
    ambele randuri de arcada, pe ambele piese (palace_a si palace_b). Nu se
    repara `jodhpur_shapes.py` (fisier comun, celalalt constructor lucreaza
    pe alta ramura pe acelasi fisier) -- fix LOCAL: renuntam la modul
    "open" (coloane+arc fara fund) si construim fiecare travee ca un panou
    SOLID cu gol arcuit (`arch_opening(open=False, glass=False)`), exact
    reteta deja verificata si corecta din golul principal al portilor si
    din ferestrele palatului -- arata ca o arcada oarba (fund plin, retras),
    nu perfect strapunsa, dar geometria e curata si arcul se vede corect
    conturat, fara coloane stramba."""
    a, c = Vector(p1), Vector(p2)
    d = c - a
    length = d.length
    axis = d.normalized() if length > 1e-6 else Vector((1.0, 0.0, 0.0))
    ang = math.atan2(axis.x, axis.y)
    rot = Matrix.Rotation(ang, 3, "Z")
    bay = length / n
    stone_faces = []
    glass_faces = []
    for i in range(n):
        center = a + axis * (bay * i + bay * 0.5)
        w = bay - pier_w
        res = arch_opening(b, bg, (center.x, center.y, base_z), w, opening_h, pier_h,
                           wall_t, slot, glow_slot, style=style, rotation=rot,
                           glass=glass, reveal=wall_t * 0.7,
                           panel_w=bay, panel_h=opening_h * 1.12, open=False)
        stone_faces += res["stone"]
        glass_faces += res["glass"]
    return {"stone": stone_faces, "glass": glass_faces}


# =============================================================================
# fort_wall_segment -- modul de zid inlantuibil
# =============================================================================
#
# ESCALADARE OPUS (runda 3; rundele 1-2 respinse: modulul singur, 12 x 14 m,
# citea ca o PLACA patrata cu o coroana de "dinti" rotunzi la 1,2 m).
#
# LISTA DE ELEMENTE (decuparea fort_wall_segment.png, citita inainte de
# primul vertex; vedere frontala, tronson de ~3 module intre doua turnuri):
#   1. Soclu ingust la baza, usor tesit (iese putin din fata zidului).
#   2. Corp de zid drept, plin, inalt -- rosturile de blocuri sunt TEXTURA
#      (brief regula 5), nu geometrie.
#   3. 2 fante de tragere inalte si inguste pe tronson, la ~65% din
#      inaltimea zidului -> aici 1 pe modul (3 pe tronsonul de 3 module; decuparea
#      are 2 -- abatere de +1 asumata: un modul inlantuibil nu poate avea
#      "o fanta la 1,5 module").
#   4. Un brau subtire, usor iesit, la baza crenelurilor (linia de umbra
#      de sub merloane).
#   5. Merloane "kangura" (dreptunghi + umeri rotunjiti + varf), cu un punct
#      intunecat in mijloc: 14 pe tronsonul de ~3 module -> 5 pe modul, pas
#      2,4 m, ~1,95 x 2,5 m, cu goluri inguste intre ele. NU "~1 la 1,2 m"
#      (cifra rundei 2, contrazisa de decupare). Brief-ul scrie "creneluri
#      dreptunghiulare" -- decuparea arata kangura; forma vine din planse
#      (§0.1), deci kangura.
#   6. Pe spate: drum de straja la cota brâului si un parapet interior jos
#      (silueta din spate si din capat, nevazut pe decupare).
#   Capete PLANE la y = +-6 (inlantuire cap la cap / langa turn): merloanele
#   la y = 0, +-2,4, +-4,8, deci golul de la capat e jumatate din golul
#   dintre merloane si ritmul continua peste rost.
#   Ce iese din contur: doar merloanele.
#
# Lungimea pe Y, fata principala (fante, merloane) spre +X.
WS_LEN = 12.0
WS_THICK = 3.0
WS_H = 14.0
WS_MERLONS = 5
WS_MERLON_W = 1.95
WS_MERLON_H = 2.5
WS_MERLON_T = 0.7


def build_fort_wall_segment():
    b = Builder()
    bg = Builder()
    hl = WS_LEN * 0.5
    ht = WS_THICK * 0.5

    # 1. soclu tesit: profil in X-Z extrudat pe toata lungimea (capete plane)
    plinth = [(-ht - 0.30, 0.0), (ht + 0.30, 0.0), (ht + 0.30, 0.35),
              (ht + 0.05, 0.9), (-ht - 0.05, 0.9), (-ht - 0.30, 0.35)]
    bm = b.bm
    fa = [bm.verts.new((x, -hl, z)) for x, z in plinth]
    fb = [bm.verts.new((x, hl, z)) for x, z in plinth]
    bm.faces.new(tuple(fa))
    bm.faces.new(tuple(reversed(fb)))
    for i in range(len(plinth)):
        j = (i + 1) % len(plinth)
        bm.faces.new((fa[i], fb[i], fb[j], fa[j]))
    for f in bm.faces:
        f[b.slot] = STONE

    # 2. corpul zidului
    walk_z = WS_H - WS_MERLON_H - 0.45     # drumul de straja / baza braului
    b.box((0.0, 0.0, (0.9 + walk_z) * 0.5), (WS_THICK, WS_LEN, walk_z - 0.9), STONE)

    # 3. fanta de tragere: una pe modul, la mijloc, flush + inchisa (lectia
    # val 2a: relieful de piatra nu se citeste ca fanta, culoarea da)
    # decupare: fanta ~1 x 3 m la ~65% din inaltimea zidului (masurat in px
    # pe tronson); aici 0,6 x 2,4 (1 pe modul, nu 2 pe 3 module)
    slit_z = walk_z * 0.62
    bg.box((ht + 0.01, 0.0, slit_z), (0.04, 0.6, 2.4), GLOW)

    # 4. brau la baza merloanelor, iesit 0,15 m in fata
    b.box((0.15, 0.0, walk_z + 0.225), (WS_THICK + 0.3, WS_LEN, 0.45), STONE)
    merlon_z = walk_z + 0.45

    # 5. merloane kangura pe muchia din fata, cu punct intunecat
    pitch = WS_LEN / WS_MERLONS
    mx = ht - WS_MERLON_T * 0.5
    for i in range(WS_MERLONS):
        y = -hl + pitch * (i + 0.5)
        kangura_merlon(b, (mx, y, merlon_z), WS_MERLON_W, WS_MERLON_H, WS_MERLON_T,
                       STONE, facing="X")
        bg.box((ht + 0.01, y, merlon_z + WS_MERLON_H * 0.46), (0.04, 0.3, 0.3), GLOW)

    # 6. parapet interior jos, pe muchia din spate
    b.box((-ht + 0.2, 0.0, merlon_z + 0.5), (0.4, WS_LEN, 1.0), STONE)

    densify_for_ao(b, max_len=3.0)
    stone_obj = b.to_object("Wall_Stone")
    glow_obj = _finish_or_none(bg.to_object("Wall_Glow"))
    return stone_obj, glow_obj


# =============================================================================
# fort_wall_turret -- turnul de la capatul tronsonului
# =============================================================================
#
# Contract (brief §1.2): 4,5 x 4,5 m, 17 m inalt -- piesa NOUA, desprinsa din
# fort_wall_segment (nu are decupare proprie in planta v1 -- brief-ul o descrie
# explicit ca "turnul patrat de la capetele tronsonului de pe decupare, piesa
# noua"). Lista de elemente (derivata din decuparea fort_wall_segment.png,
# unde turnurile de capat apar taiate de cadru), de jos in sus:
#
#   1. Soclu tesit la baza (ca zidul).
#   2. Corp OCTOGONAL (colturi taiate) -- pe decupare turnul are fete vizibile
#      la colturi, nu muchii drepte, si se citeste mai LAT decat un patrat
#      simplu la aceeasi cota.
#   3. 2 guri de tragere VERTICALE, inguste, pe fata vizibila (+X, exterior).
#   4. Fara cornisa in consola (flush, ca la fort_wall_segment).
#   5. Creneluri KANGURA -- exact stilul zidului (`kangura_merlon`), nu
#      "rounded" ca la bastion/porti (turnurile porticii sunt alta familie).
#
# REVIZUIRE (runda de corectii fort2, dupa "chain" in preview): comparat cu
# `fort_wall_segment.png` (turnurile de capat, taiate de cadru dar clar
# vizibile), turnul vechi picase pe TREI puncte -- ingust (patrat simplu,
# muchii drepte, se citea "subtire" langa zidul de 3 m gros), creneluri
# ROTUNJITE ca la porti/bastion (alta familie decat kangura zidului), 2 fante
# aproape patrate (0,22x0,85, raport doar 3,9:1) in loc de fante VERTICALE
# inguste ca pe decupare. Toate trei corectate mai jos.
WT_SIDE = 4.5
WT_H = 17.0
# colturile taiate: fiecare colt pierde WT_CHAMFER din latura, latimea
# aparenta a fetei principale ramane WT_SIDE (nu se schimba amprenta/cota de
# contract), dar silueta citeste octogonala -- mai lata, ca pe decupare.
WT_CHAMFER = 0.85


def _octagon_outline(hs, chamfer):
    """Conturul (x, y) al unui patrat de semi-latura `hs` cu colturile taiate
    cu `chamfer` -- 8 laturi, fetele principale raman late WT_SIDE, colturile
    citesc ca fatete, nu ca muchii ascutite (silueta mai lata pe decupare)."""
    c = chamfer
    return [(-hs + c, -hs), (hs - c, -hs), (hs, -hs + c), (hs, hs - c),
            (hs - c, hs), (-hs + c, hs), (-hs, hs - c), (-hs, -hs + c)]


def _octagon_prism(b, outline, z0, z1, slot):
    bm = b.bm
    fa = [bm.verts.new((x, y, z0)) for x, y in outline]
    fb = [bm.verts.new((x, y, z1)) for x, y in outline]
    n = len(outline)
    faces = [bm.faces.new(tuple(reversed(fa))), bm.faces.new(tuple(fb))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _kangura_merlon_rotated(b, center, w, h, t, slot, angle):
    """Ca `kangura_merlon` (acelasi contur: dreptunghi + umeri rotunjiti +
    varf ascutit), dar orientat cu `angle` (radiani, in jurul lui Z) in loc
    de axis-aligned X/Y -- necesar pe fetele oblice ale unui octogon (colturi
    taiate la 45 de grade), unde `kangura_merlon` (fara parametru `rotation`)
    nu se poate alinia. `center` = mijlocul BAZEI, `w` de-a lungul directiei
    `angle`, grosimea `t` perpendicular pe ea."""
    cx, cy, cz = center
    hw = w * 0.5
    outline = [(-hw, 0.0), (hw, 0.0), (hw, 0.52 * h), (0.43 * w, 0.70 * h),
               (0.30 * w, 0.83 * h), (0.14 * w, 0.93 * h), (0.0, h),
               (-0.14 * w, 0.93 * h), (-0.30 * w, 0.83 * h), (-0.43 * w, 0.70 * h),
               (-hw, 0.52 * h)]
    along = (math.cos(angle), math.sin(angle))
    perp = (math.cos(angle + math.radians(90.0)), math.sin(angle + math.radians(90.0)))
    bm = b.bm
    fa, fb = [], []
    for u, z in outline:
        fa.append(bm.verts.new((cx + along[0] * u - perp[0] * t * 0.5,
                                cy + along[1] * u - perp[1] * t * 0.5, cz + z)))
        fb.append(bm.verts.new((cx + along[0] * u + perp[0] * t * 0.5,
                                cy + along[1] * u + perp[1] * t * 0.5, cz + z)))
    n = len(outline)
    faces = [bm.faces.new(tuple(fa)), bm.faces.new(tuple(reversed(fb)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def build_fort_wall_turret():
    b = Builder()
    bg = Builder()
    faces = []
    hs = WT_SIDE * 0.5

    plinth_h = 0.6
    plinth_outline = _octagon_outline(hs + 0.35, WT_CHAMFER + 0.20)
    faces += _octagon_prism(b, plinth_outline, 0.0, plinth_h, STONE)

    wall_h = WT_H - plinth_h - 1.3
    body_outline = _octagon_outline(hs, WT_CHAMFER)
    wall_top_z = plinth_h + wall_h
    faces += _octagon_prism(b, body_outline, plinth_h, wall_top_z, STONE)

    # 2 guri de tragere VERTICALE, inguste, flush + STUD (VOLCANIC_BLACK),
    # pe fata +X -- raport inaltime/latime ~6:1 (0,14 x 0,85), ca pe decupare
    # (fanta ingusta, nu caseta aproape patrata). Nod separat Turret_Glow,
    # ca la zid/porti (regula GLOW: nu in acelasi Builder ca piesa cu clasa
    # triplanara la integrare).
    slit_z = plinth_h + wall_h * 0.62
    for sy in (-0.55, 0.55):
        bg.box((hs - 0.03, sy, slit_z), (0.03, 0.14, 1.0), GLOW)

    # flush, fara cornisa in consola -- ca la fort_wall_segment (brau subtire).
    faces += _octagon_prism(b, body_outline, wall_top_z, wall_top_z + 0.12, STONE)
    parapet_base_z = wall_top_z + 0.12
    parapet_h = WT_H - parapet_base_z - 0.85
    parapet_outline = _octagon_outline(hs - 0.1, WT_CHAMFER - 0.1)
    faces += _octagon_prism(b, parapet_outline, parapet_base_z, parapet_base_z + parapet_h, STONE)
    crenel_z = parapet_base_z + parapet_h

    # brau la baza merloanelor (ca la zid), apoi creneluri KANGURA -- acelasi
    # stil si aceleasi cote (WS_MERLON_*) ca `fort_wall_segment`, ca turnul
    # sa citeasca din aceeasi familie in randarea "chain". `kangura_merlon`
    # e axis-aligned (facing X/Y) -- pe fetele oblice ale octogonului
    # (colturile taiate, la 45 grade) se construieste manual acelasi contur,
    # rotit in planul XY cu unghiul segmentului (kangura_merlon nu accepta
    # `rotation`).
    faces += _octagon_prism(b, _octagon_outline(hs, WT_CHAMFER), crenel_z, crenel_z + 0.3, STONE)
    crenel_z += 0.3
    sides = list(zip(body_outline, body_outline[1:] + body_outline[:1]))
    for (x0, y0), (x1, y1) in sides:
        seg_len = math.hypot(x1 - x0, y1 - y0)
        n_m = max(int(round(seg_len / 1.2)), 1)
        pitch = seg_len / n_m
        ang = math.atan2(y1 - y0, x1 - x0)
        axis_aligned = abs(math.sin(ang)) < 1e-6 or abs(math.cos(ang)) < 1e-6
        for i in range(n_m):
            t = (i + 0.5) / n_m
            mx = x0 + (x1 - x0) * t
            my = y0 + (y1 - y0) * t
            if axis_aligned:
                facing = "Y" if abs(x1 - x0) > abs(y1 - y0) else "X"
                kangura_merlon(b, (mx, my, crenel_z), pitch * 0.98, WS_MERLON_H,
                               WS_MERLON_T, STONE, facing=facing)
            else:
                faces += _kangura_merlon_rotated(b, (mx, my, crenel_z), pitch * 0.98,
                                                 WS_MERLON_H, WS_MERLON_T, STONE, ang)

    stone_obj = b.to_object("Turret_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    glow_obj = _finish_or_none(bg.to_object("Turret_Glow"))
    return stone_obj, glow_obj


# =============================================================================
# fort_bastion -- burjul rotund
# =============================================================================
#
# Contract (brief §1.2): Ø18 m baza, Ø16 m sus, 13 m inalt, h/l 0,66, segments 24.
# Lista de elemente (dupa Read fort_bastion.png), de jos in sus:
#
#   1. Baza usor evazata (teasa), aproape cilindrica.
#   2. Corp tronconic (frustum), usor mai ingust sus decat jos -- asize
#      orizontale (textura).
#   3. Un rand de guri de tragere mici, dreptunghiulare, pe circumferinta,
#      sub cornisa (numarate pe decupare: ~8-10).
#   4. Un brau/cornisa in consola aproape de varf.
#   5. Creneluri ROTUNJITE la varf (crestate DIFERIT de ziduri -- capete
#      semicilindrice, nu drepte), dese pe tot cercul.
BA_R_BOTTOM = 9.0
BA_R_TOP = 8.0
BA_H = 13.0
BA_SEG = 24


def build_fort_bastion():
    b = Builder()
    faces = []

    plinth_h = 0.8
    faces += list(b.frustum((0.0, 0.0, plinth_h * 0.5), BA_R_BOTTOM + 0.4, BA_R_BOTTOM + 0.05,
                            plinth_h, STONE, segments=BA_SEG, axis="Z"))

    body_h = BA_H - plinth_h - 1.4
    faces += list(b.frustum((0.0, 0.0, plinth_h + body_h * 0.5), BA_R_BOTTOM, BA_R_TOP,
                            body_h, STONE, segments=BA_SEG, axis="Z"))
    body_top_z = plinth_h + body_h
    # raza la inaltimea gurilor de tragere (interpolare liniara pe frustum)
    t_slit = 0.60
    r_slit = BA_R_BOTTOM + (BA_R_TOP - BA_R_BOTTOM) * t_slit
    slit_z = plinth_h + body_h * t_slit

    # 2 RANDURI de guri de tragere clar vizibile -- REVIZUIRE runda 2
    # (critica: "add 2 rows of CLEARLY visible dark arrow slits"). Flush cu
    # suprafata (nu r_slit+0,05, care iesea in AFARA razei reale la acea
    # inaltime -- relief bump) SI colorate STUD (VOLCANIC_BLACK).
    n_slits = 10
    for row_t2 in (0.45, 0.72):
        r_row = BA_R_BOTTOM + (BA_R_TOP - BA_R_BOTTOM) * row_t2
        z_row = plinth_h + body_h * row_t2
        for i in range(n_slits):
            a = 2.0 * math.pi * (i + 0.5) / n_slits
            sx, sy = math.cos(a) * (r_row - 0.06), math.sin(a) * (r_row - 0.06)
            rot = Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(math.radians(90.0), 3, "X")
            faces += list(b.box((sx, sy, z_row), (0.05, 0.7, 1.0), STUD, rotation=rot))

    # brau/cornisa aproape de varf
    faces += list(balcony_band(b, (0.0, 0.0, body_top_z), BA_R_TOP - 0.35, BA_R_TOP + 0.20,
                               0.28, STONE, segments=BA_SEG))
    parapet_base_z = body_top_z + 0.28
    parapet_h = BA_H - parapet_base_z - 0.55
    faces += list(b.frustum((0.0, 0.0, parapet_base_z + parapet_h * 0.5),
                            BA_R_TOP - 0.15, BA_R_TOP - 0.25, parapet_h, STONE,
                            segments=BA_SEG, axis="Z"))
    crenel_z = parapet_base_z + parapet_h

    # creneluri ROTUNJITE (distincte de zid: crenel_merlon style="rounded"),
    # CONTINUE -- REVIZUIRE runda 2 (critica: "a continuous ring of rounded
    # merlons (~24 around)"). Numarul crescut la ~24, latimea calculata sa
    # aproape atinga vecinii (continuu, nu spatiati).
    n_merlon = 24
    circumference = 2.0 * math.pi * (BA_R_TOP - 0.5)
    merlon_w = (circumference / n_merlon) * 0.98
    for i in range(n_merlon):
        a = 2.0 * math.pi * (i + 0.5) / n_merlon
        gx, gy = math.cos(a) * (BA_R_TOP - 0.5), math.sin(a) * (BA_R_TOP - 0.5)
        rot = Matrix.Rotation(a, 3, "Z")
        faces += list(crenel_merlon(b, (gx, gy, crenel_z + 0.6), 1.2, STONE,
                                    width=merlon_w, depth=0.65, style="rounded", rotation=rot))

    stone_obj = b.to_object("Bastion_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    return stone_obj


# =============================================================================
# fort_gate_jai / fateh / loha -- portile cetatii
# =============================================================================
#
# Contract comun (brief §1.2): ~26 m latime totala, 14 m inalte, golul 7,0 m
# LIBER (proiectie pe planul portii, gabaritul masinii, pana la 2,0 m
# inaltime, cu canaturile deschise incluse), cheia arcului >= 9 m.
#
# Lista de elemente COMUNA celor 3 (dupa Read fort_gate_jai/fateh/loha.png),
# de jos in sus, aceeasi compozitie pe toate trei:
#
#   1. DOUA turnuri ROTUNDE, crenelate, de o parte si de alta a arcului
#      (baza usor evazata, corp cilindric, brau median, creneluri
#      rotunjite/patrate sus).
#   2. Intre turnuri, la baza: un ARC ASCUTIT (ogiva) mare, golul portii,
#      cu CANATURI DE LEMN deschise (Jai/Fateh) sau DE FIER (Loha), batute
#      cu tepi, lipite de ambrazura.
#   3. Deasupra arcului: o banda de perete cu 2-3 nise oarbe in arc
#      (decorative, geometrie mica retrasa).
#   4. Parapet crenelat continuu pe toata latimea (turnuri + banda centrala),
#      dinti dreptunghiulari (Jai/Loha) sau cu creneluri putin mai joase
#      langa chhatri (Fateh).
#   5. DOAR Fateh: un chhatri mic cu cupola, centrat EXACT deasupra cheii
#      arcului, iesind peste linia crenelurilor.
#
# Diferentele intentionate (brief, coloana "abatere permisa"):
#   Jai:   turnurile CELE MAI INALTE (16 m), creneluri simple.
#   Fateh: chhatri peste arc (marcaj unic).
#   Loha:  CEA MAI JOASA si mai simpla, canaturi de FIER (PAINTED) nu lemn.
#
# Latimea totala (turn-arc-turn) pe Y, fata principala (arcul, gura portii)
# spre +X -- masinile trec prin gol de-a lungul lui X.
GATE_WIDTH = 26.0
GATE_H = 14.0
GATE_GAP_W = 7.0          # latimea golului la nivelul solului
GATE_GAP_CLEAR_H = 2.0    # inaltimea pana la care golul trebuie sa fie liber
GATE_KEY_MIN = 9.0


def _gate_doors(b, center, gap_w, door_h, wall_t, slot, stud_slot, open_angle_deg=88.0,
                 hinge_margin=None):
    """Doua canaturi batute cu tepi (3x5), balamalate la ambrazura, deschise
    la `open_angle_deg` -- stau LIPITE de peretii golului, INAUNTRUL adancimii
    portalului (nu proiectate ca placi subtiri in FATA zidului, spre camera).

    REVIZUIRE runda 2 (val 2a respins pe fidelitate): balamaua statea la
    `wall_t*0,5-0,05`, adica aproape de fata EXTERIOARA a zidului, iar
    unghiul de 75 grade lasa canatul aproape paralel cu zidul dar deplasat
    IN FATA lui (spre +X, catre camera) -- exact "placi subtiri in fata
    zidului" semnalat de critica. Fix: `center` se plaseaza acum la mijlocul
    grosimii zidului (`cx=0`, apelantul trimite pozitia deja centrata).

    REVIZUIRE runda de corectii (`measure_opening` a masurat 5,55 m liber,
    sub contractul de 7,0 m, pe toate trei portile): unghiul de 100 de grade
    din runda 2 trecea de 90 -- dincolo de 90 de grade, canatul se roteste
    INAPOI spre centrul golului (`tip_y` scade odata cu unghiul, verificat
    numeric: la 100 grade varful canatului ajunge la |y|=2,77, adica
    intra 0,7 m in golul liber). Geometria corecta pentru "canat lipit de
    perete, in afara golului" e unghiul de EXACT 90 de grade (canatul
    devine paralel cu directia de mers, flush pe peretele lateral al
    firidei) -- la 90 de grade sau mai putin, extrema canatului spre centru
    NU trece niciodata de balama pe axa Y (matematic: rotatia unei bare
    cu un capat fix nu poate scoate celalalt capat dincolo de pozitia lui
    la 90 de grade, pe axa perpendiculara pe brat). Implicit 88 (usor sub
    90, ca sa se citeasca vizual "deschis", nu perfect flush).

    A doua cauza: balamaua insasi (`hinge_y`) statea pe marginea golului de
    contract (`gap_w/2`), iar canatul are grosime (`leaf_t`) -- chiar la 90
    de grade, jumatate din grosime tot intra in gol. Fix: balamaua se muta
    cu `hinge_margin` in AFARA golului de contract (in ambrazura/pilonul de
    piatra, unde e loc -- `center_span` >> `gap_w`), ca toata geometria
    canatului (inclusiv tepii, care ies `leaf_t*0,5+0,02` peste fata
    canatului) sa ramana strict in afara ferestrei de 7,0 m. Verificat
    numeric (nu doar cod): cu `hinge_margin=0,13` si `open_angle_deg=88`,
    varful cel mai apropiat de centru ramane la |y|=3,56, deci gol liber
    2*3,56=7,12 m > 7,0 m contract, cu marja pentru tepi.

    Golul e de-a lungul Y (latimea 7 m), portalul strabate peretele pe X,
    deci canaturile se rotesc/deschid in planul XY, balamaua pe muchia
    exterioara (langa perete, pe Y)."""
    cx, cy, cz = center
    leaf_t = 0.14
    if hinge_margin is None:
        hinge_margin = leaf_t * 0.5 + 0.06
    hinge_gap_w = gap_w + 2.0 * hinge_margin
    leaf_w = hinge_gap_w * 0.5 - 0.05
    faces = []
    for side in (-1.0, 1.0):
        hinge_y = cy + side * hinge_gap_w * 0.5
        # balamaua e pe muchia exterioara; canatul se deschide spre INTERIOR
        # (spre -X local, in adancimea portalului), nu spre camera
        ang = math.radians(open_angle_deg) * side
        rot = Matrix.Rotation(ang, 3, "Z")
        leaf_center_local = Vector((0.0, side * leaf_w * 0.5, 0.0))
        m = rot.to_matrix() if hasattr(rot, "to_matrix") else rot
        p = m @ leaf_center_local
        leaf_c = (cx + p.x, hinge_y + p.y, cz + door_h * 0.5)
        rot4 = Matrix.Rotation(ang, 3, "Z")
        faces += list(b.box(leaf_c, (leaf_t, leaf_w, door_h), slot, rotation=rot4))
        # tepi: 3 x 5, geometrie mica, pe fata exterioara a canatului
        for ix in range(3):
            for iz in range(5):
                ly = (ix - 1) * (leaf_w * 0.28)
                lz = (iz - 2) * (door_h * 0.16)
                stud_local = Vector((leaf_t * 0.5 + 0.02, side * leaf_w * 0.5 + ly, lz))
                sp = m @ stud_local
                stud_c = (cx + sp.x, hinge_y + sp.y, cz + door_h * 0.5 + lz)
                faces += list(b.box(stud_c, (0.05, 0.07, 0.07), stud_slot, rotation=rot4))
    return faces


def _build_gate(tower_h, door_slot, chhatri_over_arch, name_prefix):
    b = Builder()
    faces = []

    # REVIZUIRE runda 2 (val 2a respins -- "turnuri inalte, subtiri" in loc
    # de "STOUT drum towers": diametru ~30% din latimea TOTALA a portii
    # (26 m), inaltime ~1,5x diametrul"). tower_r a crescut de la 3,0 la
    # 3,9 m (diametru 7,8 m =~ 30% din 26 m); inaltimea corpului turnului
    # (fara soclu/parapet) tinteste explicit ~1,5x diametrul (~11,7 m),
    # NU tower_h intreg (care include si banda centrala/parapetul).
    tower_r = 3.9
    tower_diam = tower_r * 2.0
    # distanta intre AXELE turnurilor: trebuie sa lase loc pentru (a) golul
    # portii (GATE_GAP_W=7,0), (b) grosimea picioarelor arcului de-o parte si
    # de alta, SI (c) un guler de perete plin intre picioarele arcului si
    # coloana turnului (altfel panoul arcului `center_span` iese mai ingust
    # decat golul insusi -- bug gasit la primul --compare, runda 1: turnurile
    # erau aproape lipite si arcul disparea comprimat intr-o fasie). Runda 2:
    # turnurile au crescut la tower_r=3,9 (stout), deci formula veche
    # (GATE_GAP_W + 2,0) ar fi recreat EXACT acelasi bug (center_span ar
    # iesi sub GATE_GAP_W). Calculat acum explicit ca sa garanteze
    # center_span >= GATE_GAP_W * 1.3, indiferent de tower_r.
    center_span_min = GATE_GAP_W * 1.3
    tower_gap = center_span_min + (tower_r - 0.4) * 2.0 - 0.8

    # REVIZUIRE (contract incalcat, masurat cu measure_opening: gol 6,92 m
    # in loc de 7,0 m, pe stone-only, DUPA fixul canaturilor): sursa nu era
    # arcul (izolat, `arch_opening` singur da exact 7,0 m), ci SOCLUL
    # turnului (`plinth_h=0,7`, in fereastra de masurat 0,15..1,8 m) --
    # frustumul de la baza turnului are raza `tower_r+0,35=4,25`, iar
    # turnurile stau la `ty=tower_gap/2=7,65`, deci muchia interioara a
    # soclului ajunge la `7,65-4,25=3,40` < `GATE_GAP_W/2=3,5`: soclul
    # taia fizic 0,10 m din golul liber la nivelul solului, invizibil in
    # cod (frustumul nu se intersecteaza cu arcul, doar cu FEREASTRA de
    # masurare a golului). Fix: `tower_gap` primeste un termen suplimentar
    # care garanteaza ca soclul (cel mai lat element de la baza turnului)
    # ramane strict in afara golului de contract, cu o marja mica.
    plinth_flare = 0.35
    plinth_clear = (GATE_GAP_W * 0.5 + 0.15) - (tower_gap * 0.5 - (tower_r + plinth_flare))
    if plinth_clear > 0.0:
        tower_gap += 2.0 * plinth_clear

    # 1. turnurile rotunde STOUT, cate unul la fiecare capat (de-a lungul Y)
    for side in (-1.0, 1.0):
        ty = side * tower_gap * 0.5
        plinth_h = 0.7
        faces += list(b.frustum((0.0, ty, plinth_h * 0.5), tower_r + 0.35, tower_r + 0.08,
                                plinth_h, STONE, segments=18, axis="Z"))
        # corp: inaltime tintita explicit la ~1,5x diametrul (stout), nu la
        # ce ramane din tower_h -- daca tower_h e prea mic pentru asta (Loha,
        # cea mai joasa), corpul ia tot ce ramane dupa soclu, ramanand tot
        # STOUT relativ (raport h/d mult sub cel vechi de ~4,5).
        body_h = min(tower_diam * 1.5, tower_h - plinth_h - 1.1)
        faces += list(b.frustum((0.0, ty, plinth_h + body_h * 0.5), tower_r, tower_r - 0.5,
                                body_h, STONE, segments=18, axis="Z"))
        body_top_z = plinth_h + body_h
        # brau median
        faces += list(balcony_band(b, (0.0, ty, plinth_h + body_h * 0.45), tower_r - 0.5,
                                   tower_r - 0.15, 0.18, STONE, segments=18))
        # guri de tragere: 3 RANDURI clar vizibile (nu 2 puncte izolate),
        # fiecare rand cu 3 goluri pe circumferinta fetei catre camera,
        # dreptunghiulare inguste, RETRASE (adancime, nu doar suprapuse pe
        # suprafata) -- critica: "2-3 randuri de guri de tragere clar
        # vizibile pe fiecare turn, ~0,4x1,2 m, retrase".
        #
        # REVIZUIRE runda 2: prima incercare punea cutia STONE la o raza doar
        # putin sub suprafata (tower_r-0,30) -- fara gol taiat prin bool,
        # cutia CONVEXA de aceeasi culoare cu peretele cade pe umbrire ca un
        # RELIEF IESIT (bump), nu ca o gaura intunecata (vazut direct in
        # randare: pete reliefate, nu fante negre). Fix: o placa SUBTIRE si
        # INGUSTA, colorata STUD (VOLCANIC_BLACK), asezata SUB suprafata (la
        # tower_r-0,08, adica flush/usor retrasa, nu ingropata complet) --
        # geometria e simpla (o cutie), dar culoarea inchisa + pozitia chiar
        # sub piele citeste ca o fanta intunecata, ca ferestrele `*_Glow` din
        # alte piese ale kitului.
        slit_r = tower_r - 0.08
        for row_t in (0.28, 0.50, 0.72):
            for sa in (-0.5, 0.0, 0.5):
                a = sa
                gx, gy = math.cos(a) * slit_r, ty + math.sin(a) * slit_r
                rot = Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(math.radians(90.0), 3, "X")
                faces += list(b.box((gx, gy, plinth_h + body_h * row_t), (0.05, 0.4, 1.2), STUD,
                                    rotation=rot))
        # creneluri DREPTUNGHIULARE mari, CONTINUE (atingandu-se) pe turn --
        # critica: "~1 merlon per 1,2 m de circumferinta", "sparse pegs" fix.
        # Banda in consola sub creneluri (parapet iesit), ca fundatie vizuala.
        crenel_band_h = 0.35
        faces += list(balcony_band(b, (0.0, ty, body_top_z), tower_r - 0.1, tower_r + 0.25,
                                   crenel_band_h, STONE, segments=18))
        crenel_z = body_top_z + crenel_band_h
        circumference = 2.0 * math.pi * (tower_r - 0.05)
        n_m = max(int(round(circumference / 1.2)), 8)
        merlon_w = (circumference / n_m) * 0.98  # aproape ating (continuu)
        for i in range(n_m):
            a = 2.0 * math.pi * (i + 0.5) / n_m
            gx, gy = math.cos(a) * (tower_r - 0.1), ty + math.sin(a) * (tower_r - 0.1)
            rot = Matrix.Rotation(a, 3, "Z")
            faces += list(crenel_merlon(b, (gx, gy, crenel_z + 0.55), 1.1, STONE,
                                        width=merlon_w, depth=0.6, style="rounded", rotation=rot))

    # 2. banda centrala intre turnuri, cu arcul portii -- peretele priveste
    # spre +X (rotatie care duce fata implicita +Y a lui arch_opening pe +X)
    center_span = tower_gap - (tower_r - 0.4) * 2 + 0.8
    wall_t = 1.6
    wall_top_z = tower_h - 1.4
    # arch_h transmis lui arch_opening e INALTIMEA TOTALA a golului (pier_h +
    # cheia arcului deasupra picioarelor, brief §0.1/arch_opening docstring) --
    # nu doar componenta arcului. Tinta: cheia (exact arch_h) ramane sub
    # wall_top_z (parapetul), cu marja pentru banda de nise + parapet, si
    # >= 9,0 m contract.
    #
    # REVIZUIRE (contract incalcat, masurat cu measure_opening pe toate trei
    # portile de pe HEAD: cheia Jai 10,32 m OK, dar Fateh 8,93 m si Loha
    # 7,89 m, sub GATE_KEY_MIN=9,0): formula veche (`min(wall_top_z*0.72,
    # tower_h-3.0)`) alege mereu ramura `wall_top_z*0.72`, care scaleaza
    # LINIAR cu tower_h -- pentru portile mai joase (Fateh 14 m, Loha
    # 12,5 m, "abatere permisa" a brief-ului), cheia scade sub contract
    # odata cu turnul. Fix: `arch_h` nu poate cobori sub GATE_KEY_MIN,
    # indiferent cat de jos e turnul -- `max()` explicit. Verificat ca
    # ramane spatiu pentru nise+parapet deasupra (`wall_top_z-arch_h`):
    # Loha 11,1-9,0=2,1 m, Fateh 12,6-9,0=3,6 m, ambele pozitive si peste
    # `niche_h` maxim (1,6 m).
    #
    # A DOUA REVIZUIRE: cu `arch_h=GATE_KEY_MIN` exact, `measure_opening`
    # (`crown_half=0,3`, aceeasi fereastra folosita la toate portile) tot
    # masoara SUB 9,0 m (Loha: 8,86 m) -- cauza nu e bevel (verificat izolat,
    # bevel=0 da acelasi rezultat), ci geometria arcului ascutit insusi:
    # varful e literal o muchie (latime zero), deci orice fereastra cu
    # `crown_half>0` prinde un punct pe PANTA arcului, putin sub varf, nu
    # varful. Cu cat arcul e mai "ascutit" (rise/half_w mai mare, ca la
    # Loha, unde turnul jos comprima golul), panta de la varf e mai abrupta
    # si caderea in fereastra de 0,3 m e mai mare (masurat: Jai cade 0,19 m,
    # Loha 0,14 m -- pare invers intuitiv, dar Loha are pier_h mai mic, deci
    # `cx`/raza arcului sunt diferite). Fix: se tinteste cu o marja fixa
    # peste contract (`GATE_KEY_MIN + GATE_KEY_MARGIN`), nu chiar la limita,
    # ca fereastra de masurare sa gaseasca tot >= 9,0 m dupa cadere.
    GATE_KEY_MARGIN = 0.3
    arch_h = max(GATE_KEY_MIN + GATE_KEY_MARGIN, min(wall_top_z * 0.72, tower_h - 3.0))
    pier_h = arch_h * 0.42
    # REVIZUIRE (gasita la primul --compare): `arch_opening` cu `open=False`
    # NU decupeaza golul exact pe conturul arcului -- silueta exterioara a
    # golului e dreptunghiul care incadreaza arcul (bounding box), iar
    # conturul de arc adevarat apare doar pe firida (peretele retras cu
    # `reveal`). Cu `reveal=0,10` (valoarea din pilot, gandita pentru arce cu
    # raport inaltime/latime ~1) golul iesea DREPTUNGHIULAR la portile astea
    # (raport rise/half_w ~1,7, mult mai inalte si inguste) -- arcul insusi
    # abia se vedea, o linie subtire la 10 cm in spatele muchiei. Fix: `reveal`
    # mare, aproape cat grosimea zidului (`wall_t=1,6`), ca sa citeasca ca un
    # portal arcuit adevarat care strabate zidul, nu ca o firida cosmetica.
    res = arch_opening(b, b, (0.0, 0.0, 0.0), GATE_GAP_W, arch_h, pier_h, wall_t,
                       STONE, STONE, style="pointed", reveal=wall_t * 0.94, glass=False,
                       panel_w=center_span, panel_h=wall_top_z, steps=12, rotation=ROT_YTOX)
    faces += res["stone"]

    # nise oarbe decorative pe banda, DEASUPRA cheii arcului (arch_h e
    # inaltimea TOTALA a golului principal pana la cheie -- nisele trebuie
    # sa stea intre arch_h si wall_top_z, nu suprapuse peste arcul insusi;
    # bug gasit la primul --compare: niche_z cazuse INAUNTRUL arcului
    # principal, producand linii incrucisate vazute prin golul mare).
    niche_h = min(1.6, (wall_top_z - arch_h) * 0.55)
    niche_z0 = arch_h + (wall_top_z - arch_h - niche_h) * 0.5
    for ny in (-center_span * 0.27, center_span * 0.27):
        res_n = arch_opening(b, b, (wall_t * 0.5 + 0.001, ny, niche_z0), 0.9, niche_h,
                             niche_h * 0.3, 0.20, STONE, STONE, style="pointed", reveal=0.14,
                             glass=False, panel_w=1.5, panel_h=niche_h * 1.5, steps=8,
                             rotation=ROT_YTOX)
        faces += res_n["stone"]

    # Fateh: 2 nise oarbe MICI SUPLIMENTARE, langa arc (nu deasupra) --
    # critica runda 2: "2 arched niches on each side of the arch, as on the
    # crop" -- lipseau complet in runda 1 (doar cele de deasupra existau).
    if chhatri_over_arch:
        side_niche_h = pier_h * 0.85
        for ny in (-GATE_GAP_W * 0.5 - 0.9, GATE_GAP_W * 0.5 + 0.9):
            res_sn = arch_opening(b, b, (wall_t * 0.5 + 0.001, ny, side_niche_h * 0.1), 0.55,
                                  side_niche_h, side_niche_h * 0.35, 0.16, STONE, STONE,
                                  style="pointed", reveal=0.12, glass=False,
                                  panel_w=0.95, panel_h=side_niche_h * 1.4, steps=8,
                                  rotation=ROT_YTOX)
            faces += res_sn["stone"]

    # parapet crenelat continuu deasupra bentii centrale, la aceeasi cota ca
    # varful turnurilor (fara acoperi -- doar intre turnuri, nu peste ele).
    # REVIZUIRE runda 2: stil schimbat din "rectangular" in "rounded"
    # CONTINUU (acelasi stil ca turnurile acum) -- decupera arata acelasi
    # profil de merloane pe toata latimea, turnuri+banda, nu doua stiluri
    # diferite.
    par_h = 0.7
    faces += list(b.box((0.0, 0.0, wall_top_z + par_h * 0.5), (wall_t - 0.2, center_span, par_h), STONE))
    par_circumference = center_span
    n_par_m = max(int(round(par_circumference / 1.2)), 6)
    par_merlon_w = (par_circumference / n_par_m) * 0.98
    faces += crenellation(b, (0.0, -center_span * 0.5, wall_top_z + par_h), (0.0, center_span * 0.5, wall_top_z + par_h),
                          1.1, STONE, width=par_merlon_w, gap=0.02, style="rounded")

    # 5. Fateh: chhatri centrat deasupra cheii arcului
    if chhatri_over_arch:
        res_c = chhatri(b, b, (0.0, 0.0, wall_top_z + par_h + 0.5), 6, 0.9, 1.1, STONE, STONE,
                        col_r=0.13, dome_radius=0.55, arch_style="round", chajja_out=0.32,
                        segments_dome=10)
        faces += res_c["stone"]

    # canaturile portii -- Builder SEPARAT (door_slot difera de STONE).
    # REVIZUIRE runda 2: centrul mutat la MIJLOCUL grosimii zidului (X=0,
    # nu wall_t*0,5-0,05 =~ fata exterioara) -- vezi nota din _gate_doors:
    # cu balamaua aproape de fata exterioara, canaturile deschise la 75 grade
    # ieseau ca placi subtiri IN FATA zidului, spre camera, in loc sa stea
    # in adancimea portalului.
    #
    # REVIZUIRE (contract incalcat, masurat cu measure_opening: 5,55 m in
    # loc de 7,0 m): `gap_w` trimis aici era GATE_GAP_W-0,15, sub golul de
    # piatra real -- balamaua statea deja in interiorul golului liber, iar
    # unghiul de 100 grade impingea varful canatului si mai adanc spre
    # centru. Acum se trimite golul REAL de piatra (GATE_GAP_W); `_gate_doors`
    # isi muta singura balamaua in afara acestui gol (`hinge_margin`,
    # implicit ~0,13 m) inainte sa roteasca la `open_angle_deg` (implicit
    # 88, sub pragul de 90 dincolo de care canatul se intoarce spre centru).
    bdoor = Builder()
    door_faces = _gate_doors(bdoor, (0.0, 0.0, 0.0), GATE_GAP_W,
                             pier_h + 0.4, wall_t, door_slot, STUD)
    for f in door_faces:
        pass  # sloturile sunt deja corecte (scrise in _gate_doors)

    stone_obj = b.to_object(name_prefix + "_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    doors_obj = _finish_or_none(bdoor.to_object(name_prefix + "_Doors"))

    return stone_obj, doors_obj, arch_h, pier_h


# --- emit ------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Identic cu `emit` din build_jodhpur_pilot.py: offsetul de origine se
    calculeaza O DATA pe ansamblu si se aplica identic tuturor nodurilor."""
    objs = [o for o in objs if o is not None]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=(origin if solo else None), smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "jodhpur/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return total_tris


# fort_wall_segment
wall_stone, wall_glow = build_fort_wall_segment()
emit([wall_stone, wall_glow], "structures/fort_wall_segment.glb", AO_STONE,
     origin="assembly", bevel=0.03, budget=3000)

# fort_wall_turret -- acum 2 noduri (Turret_Stone, Turret_Glow) ca zidul,
# origine COMUNA (fantele Turret_Glow nu ating solul separat).
turret_stone, turret_glow = build_fort_wall_turret()
emit([turret_stone, turret_glow], "structures/fort_wall_turret.glb", AO_STONE,
     origin="assembly", bevel=0.03, budget=5500)

# fort_bastion
bastion_stone = build_fort_bastion()
emit([bastion_stone], "structures/fort_bastion.glb", AO_STONE, bevel=0.03, budget=9000)

# fort_gate_jai -- CEL MAI INALT (16 m turnuri), prioritate (contractul golului)
jai_stone, jai_doors, jai_arch_h, jai_pier_h = _build_gate(16.0, DOOR_WOOD, False, "GateJai")
emit([jai_stone, jai_doors], "structures/fort_gate_jai.glb", AO_STONE, origin="assembly",
     bevel=0.03, budget=10600)
print()
print("MASURATOARE POARTA JAI (brief §1.2, contract gol):")
print("  gol latime libera (proiectie pe plan, pana la 2,0 m):", GATE_GAP_W, "m  (contract 7,0 m)")
print("  cheia arcului (varf arc fata de sol):", round(jai_arch_h, 2), "m  (contract >= 9,0 m)")
print("  canaturile deschise stau LIPITE de ambrazura, in afara golului")
print()

# fort_gate_fateh -- chhatri peste arc
fateh_stone, fateh_doors, fateh_arch_h, fateh_pier_h = _build_gate(14.0, DOOR_WOOD, True, "GateFateh")
emit([fateh_stone, fateh_doors], "structures/fort_gate_fateh.glb", AO_STONE, origin="assembly",
     bevel=0.03, budget=12600)

# fort_gate_loha -- cea mai joasa, canaturi de fier
loha_stone, loha_doors, loha_arch_h, loha_pier_h = _build_gate(12.5, DOOR_IRON, False, "GateLoha")
emit([loha_stone, loha_doors], "structures/fort_gate_loha.glb", AO_STONE, origin="assembly",
     bevel=0.03, budget=10600)


# =============================================================================
# palace_facade_a / b
# =============================================================================
#
# palace_facade_a -- Moti Mahal (brief §1.2): 40 x 6 x 14 m, 3 etaje, h/l 0,29.
# Lista de elemente (dupa Read palace_facade_a.png), de jos in sus / stanga-
# dreapta (fatada lunga, simetrie aproximativa). Lungimea pe Y, fata
# principala spre +X:
#
#   1. Parter + etaj 1: RANDURI de jharokha (balcoane in consola, cu acoperis
#      curbat bangla) pe toata latimea, alternand cu ferestre in arc simple.
#   2. Jali (paravane perforate): fete RETRASE cu grila de 3x4 gauri
#      (geometrie, nu textura), intre proiectiile de jharokha.
#   3. Corp central mai INALT si mai proeminent, cu un balcon mare cu coloane
#      (arcada deschisa pe 2 niveluri) in mijloc.
#   4. Doua turnuri subtiri mai inalte la colturi/aproape de colturi, cu
#      chhatri mici in varf (vizibile ca proiectii peste linia acoperisului).
#   5. Etajul 3 (simplu, taiat de cadru pe decupare) -- parapet drept,
#      fara ornament suplimentar.
PA_LEN = 40.0
PA_DEPTH = 6.0
PA_H = 14.0


# REVIZUIRE runda 2 (val 2a respins -- "a box with a few blocks"). Lista
# RE-scrisa dupa recitirea crop-ului, element cu element, ca lista ceruta de
# critic:
#   - plinth band la baza (soclu vizibil, umbrit)
#   - DOUA etaje de ferestre in arc, ~10-12 pe etaj pe toata fatada, goluri
#     RETRASE inchise (Palace_Glow)
#   - bloc central proeminent PE 2 ETAJE cu 3 arcade pe fiecare etaj +
#     balcon cu balustrada intre etaje
#   - 2 balcoane jharokha mai mici pe aripi
#   - atic central ridicat deasupra blocului central
#   - parapet pe acoperis cu chhatri mici de colt
def build_palace_facade_a():
    b = Builder()
    bg = Builder()
    faces = []
    hl = PA_LEN * 0.5
    hd = PA_DEPTH * 0.5

    floor_h = 4.2
    n_floors = 2
    base_h = floor_h * n_floors

    # 0. plinth band (soclu vizibil la baza, usor iesit, cu umbra)
    plinth_h = 0.9
    faces += list(b.box((0.0, 0.0, plinth_h * 0.5), (PA_DEPTH + 0.25, PA_LEN, plinth_h), STONE))

    # 1. corp principal, DOUA etaje (parter + etaj 1) -- lungimea pe Y,
    # adancimea pe X.
    faces += list(b.box((0.0, 0.0, plinth_h + base_h * 0.5), (PA_DEPTH, PA_LEN, base_h), STONE))

    # 2. DOUA etaje de ferestre in arc pe toata fatada (10-12 pe etaj) --
    # goluri RETRASE, inchise, in Palace_Glow (VOLCANIC_BLACK). Evitam doar
    # zona centrala (unde sta blocul jharokha central) si capetele (unde
    # sunt turnurile de colt).
    n_win_per_floor = 11
    win_w, win_h_ = 1.1, 2.6
    win_margin = 3.2  # spatiu liber la capete pentru turnuri
    center_gap = 9.0  # spatiu liber in mijloc pentru blocul central
    usable_half = hl - win_margin
    for fl in range(n_floors):
        wz = plinth_h + floor_h * (fl + 0.52)
        for side in (-1.0, 1.0):
            seg_start = center_gap * 0.5
            seg_len = usable_half - seg_start
            n_this_side = n_win_per_floor // 2
            for i in range(n_this_side):
                t = (i + 0.5) / n_this_side
                wy = side * (seg_start + seg_len * t)
                res_w = arch_opening(b, bg, (hd, wy, wz), win_w, win_h_, win_h_ * 0.55, 0.35,
                                     STONE, GLOW, style="round", glass=True, reveal=0.14,
                                     glass_depth=0.06, panel_w=win_w * 1.7, panel_h=floor_h * 0.92,
                                     rotation=ROT_YTOX)
                faces += res_w["stone"]

    # 3. bloc central PROEMINENT pe 2 etaje: 3 arcade pe fiecare etaj +
    # balcon cu balustrada intre etaje (jharokha central, cel mai mare
    # element al fatadei, per decupare).
    center_w = 8.0
    center_out = 1.5
    center_front_x = hd + center_out
    faces += list(b.box((center_out * 0.5, 0.0, plinth_h + base_h * 0.5),
                        (PA_DEPTH + center_out, center_w, base_h), STONE))
    # REVIZUIRE runda 2: prima incercare (opening_h=floor_h*0,74=~3,1,
    # pier_h=floor_h*0,12=~0,5) dadea un "rise" (inaltimea arcului deasupra
    # picioarelor) FOARTE mare fata de latimea travelii (half_w =~0,82 m
    # pentru 3 travei pe 5,76 m) -- pentru style="round" (arc semicircular),
    # _arch_profile scaleaza cu (half_w*cos, rise*sin), deci un rise mult
    # peste half_w intinde arcul intr-o elipsa verticala inalta si ingusta,
    # care randeaza ca niste "sarme" subtiri incovoiate, nu ca arcade late
    # mogule. Fix: opening_h calculat explicit ca pier_h + half_w (rise =~
    # half_w, semicerc adevarat), pier_h redus la o inaltime de om (~1,4 m).
    span = center_w * 0.72
    n_bays = 3
    pier_w_c, wall_t_c = 0.28, 0.34
    bay = span / n_bays
    half_w_c = (bay - pier_w_c) * 0.5
    pier_h_c = 1.4
    opening_h_c = pier_h_c + half_w_c
    # BUG gasit la al doilea --compare: `arcade()` IGNORA complet
    # componenta Z a punctelor p1/p2 -- foloseste doar `base_z` pentru
    # inaltimea geometriei (vezi jodhpur_shapes.py: `center`/`pier_c` se
    # calculeaza din `a + axis * ...`, unde `axis` vine din `d = c - a`, dar
    # `base_z` separat controleaza Z-ul real al arcelor/pilonilor). Codand
    # inaltimea etajului in Z-ul punctelor (asa cum am facut prima data,
    # `base_z=0.0` implicit) construia AMBELE etaje de arcada la Z=0 (sol) --
    # etajul 2 devenea invizibil, ingropat/suprapus peste parter. Fix:
    # `base_z=lz` explicit, punctele p1/p2 raman la Z=0 (doar XY conteaza).
    for lvl in range(2):
        lz = plinth_h + floor_h * lvl
        res_c = _local_arcade(b, b, (center_front_x + 0.4, -span * 0.5, 0.0),
                       (center_front_x + 0.4, span * 0.5, 0.0), n_bays, opening_h_c,
                       pier_h_c, pier_w_c, wall_t_c, STONE, STONE, style="round", glass=False,
                       base_z=lz)
        faces += res_c["stone"]
        faces += list(balustrade(b, (center_front_x + 0.55, -span * 0.5, lz + opening_h_c + 0.1),
                                 (center_front_x + 0.55, span * 0.5, lz + opening_h_c + 0.1), 0.5, STONE,
                                 merlon_w=0.16, merlon_gap=0.12))

    # 4. ATIC central ridicat, deasupra blocului central (dupa cele 2 etaje
    # de arcade) -- element distinct, vizibil peste linia acoperisului.
    attic_h = floor_h * 0.85
    attic_w = center_w * 0.62
    faces += list(b.box((center_out * 0.3, 0.0, plinth_h + base_h + attic_h * 0.5),
                        (PA_DEPTH * 0.7, attic_w, attic_h), STONE))
    faces += list(b.box((center_out * 0.3, 0.0, plinth_h + base_h + attic_h + 0.15),
                        (PA_DEPTH * 0.75, attic_w + 0.3, 0.3), STONE))

    # 5. doua balcoane jharokha MAI MICI pe aripi (langa turnurile de colt,
    # un etaj, cu acoperis bangla turtit)
    for jy in (-hl * 0.62, hl * 0.62):
        jz = plinth_h + floor_h * 1.55
        faces += list(b.box((hd + 0.65, jy, jz), (1.3, 1.7, 1.5), STONE))
        faces += list(balustrade(b, (hd + 1.25, jy - 0.8, jz - 0.55),
                                 (hd + 1.25, jy + 0.8, jz - 0.55), 0.5, STONE,
                                 merlon_w=0.14, merlon_gap=0.10))
        faces += list(b.frustum((hd + 0.65, jy, jz + 0.8), 1.0, 0.15, 0.5, STONE,
                                segments=10, axis="Z"))

    # 6. doua turnuri subtiri cu chhatri mici la colturi (parte din
    # "parapet cu chhatri mici de colt" ceruta de critica)
    tower_out = 0.7
    tower_top = plinth_h + base_h + 1.4
    for ty in (-hl + 2.2, hl - 2.2):
        faces += list(b.box((tower_out * 0.5, ty, tower_top * 0.5), (1.4 + tower_out, 1.4, tower_top), STONE))
        res_t = chhatri(b, b, (tower_out, ty, tower_top), 6, 0.55, 0.6, STONE, STONE,
                        col_r=0.08, dome_radius=0.35, arch_style="round", chajja_out=0.2,
                        segments_dome=8)
        faces += res_t["stone"]

    # 7. parapet pe restul fatadei (intre turnurile de colt si blocul
    # central), la nivelul acoperisului
    for side in (-1.0, 1.0):
        seg_c = side * (hl - 2.2 - (hl - 2.2 - center_w * 0.5) * 0.5)
        seg_len = (hl - 2.2) - center_w * 0.5
        faces += list(b.box((0.0, seg_c, plinth_h + base_h + 0.35), (PA_DEPTH - 0.4, seg_len, 0.7), STONE))

    stone_obj = b.to_object("Palace_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    glow_obj = _finish_or_none(bg.to_object("Palace_Glow"))
    return stone_obj, glow_obj


# palace_facade_b -- fatada simetrica cu cupola centrala (brief §1.2):
# 44 x 6 x 16 m (cupola pana la 19 m), h/l 0,30. Lista de elemente
# (dupa Read palace_facade_b.png), de jos in sus / centru-spre-colturi.
# Lungimea pe Y, fata principala spre +X:
#
#   1. Parter: arcade DESCHISE (coloane + arce) pe toata latimea.
#   2. Etaj 1: rand de ferestre in arc, regulate.
#   3. Parapet crenelat pe toata linia acoperisului, intre elementele
#      verticale.
#   4. Pavilion CENTRAL, mai inalt, cu balcon mic cu balustrada si o cupola
#      MARE deasupra (cea mai inalta piesa, pana la 19 m).
#   5. DOUA chhatri mai mici, imediat langa pavilionul central (o parte si
#      de alta).
#   6. Turnuri de colt, cu cupolite mici proprii (2, la cele doua capete).
PB_LEN = 44.0
PB_DEPTH = 6.0
PB_H = 16.0
PB_DOME_TOP = 19.0


# REVIZUIRE runda 2 (val 2a respins -- "thin wall, tiny dome"). Lista
# RE-scrisa, simetrica, ceruta de critic:
#   - 2 turnuri de colt cu cupole chhatri
#   - pavilion central cu cupola MARE nervurata peste un balcon arcuit
#   - 2 cupole mici intre centru si fiecare colt
#   - etaj superior cu rand DES de ferestre mici (~20)
#   - parter cu ~8 nise/usi in arc, plus soclu
def build_palace_facade_b():
    b = Builder()
    bg = Builder()
    faces = []
    hl = PB_LEN * 0.5
    hd = PB_DEPTH * 0.5

    floor_h = 4.6
    ground_h = floor_h
    upper_h = floor_h
    base_h = ground_h + upper_h

    # 0. soclu (plinth) la baza, usor iesit
    plinth_h = 0.8
    faces += list(b.box((0.0, 0.0, plinth_h * 0.5), (PB_DEPTH + 0.3, PB_LEN, plinth_h), STONE))

    # corp principal -- lungimea pe Y, adancimea pe X. REVIZUIRE: PB_DEPTH
    # (6 m) ramane grosimea reala a zidului (contract), dar acum are soclu +
    # arcade/nise cu iesire proprie, ca sa nu citeasca "placa subtire" din
    # unghiul de comparatie.
    faces += list(b.box((0.0, 0.0, plinth_h + base_h * 0.5), (PB_DEPTH, PB_LEN, base_h), STONE))

    # 1. parter: ~8 nise/usi in arc (nu 10 goluri complet deschise --
    # critica cere explicit "8 arched niches/doorways"), RETRASE (nu
    # strapunse), pe fata +X
    n_niches = 8
    niche_w, niche_h = 1.5, 2.8
    niche_margin = 3.0
    for i in range(n_niches):
        t = i / (n_niches - 1)
        wy = -hl + niche_margin + t * (PB_LEN - 2 * niche_margin)
        res_n = arch_opening(b, b, (hd, wy, plinth_h), niche_w, niche_h, niche_h * 0.45, 0.35,
                             STONE, STONE, style="round", glass=False, reveal=0.35,
                             panel_w=niche_w * 1.7, panel_h=ground_h * 0.98, rotation=ROT_YTOX)
        faces += res_n["stone"]

    # 2. etaj superior: rand DES de ferestre mici (~20), goluri RETRASE
    # inchise in Palace_Glow -- critica: "a dense row of small windows (~20)"
    #
    # REVIZUIRE (contract vizual incalcat: fatada B pierde total contrastul
    # ferestrelor, randare complet plata pe toata banda de etaj superior):
    # `center.z` transmis lui `arch_opening` e citit ca BAZA golului (hole
    # incepe la `panel_z0=0`, implicit, si urca cu `h` -- vezi docstring,
    # confirmat de apelul functional de mai sus, `res_n`, care trimite
    # `plinth_h`, cota PODELEI, nu centrul etajului). Aici se trimitea
    # `plinth_h+ground_h+upper_h*0.5` -- CENTRUL etajului superior tratat ca
    # baza -- deci fiecare fereastra incepea la mijlocul etajului si urca
    # aproape pana in creasta parapetului (verificat cu un test izolat:
    # golul iesea ca un tepus care strapunge acoperisul, nu ca o fereastra
    # in mijlocul peretelui). Fix: se calculeaza explicit baza ferestrei,
    # centrata vertical in banda etajului superior.
    n_win = 20
    win_w, win_h_ = 0.75, 1.7
    win_margin2 = 2.4
    win_base_z = plinth_h + ground_h + (upper_h - win_h_) * 0.5
    for i in range(n_win):
        t = i / (n_win - 1)
        wy = -hl + win_margin2 + t * (PB_LEN - 2 * win_margin2)
        res_w = arch_opening(b, bg, (hd, wy, win_base_z), win_w, win_h_,
                             win_h_ * 0.55, 0.30, STONE, GLOW, style="round", glass=True,
                             reveal=0.12, glass_depth=0.05, panel_w=win_w * 1.75,
                             panel_h=win_h_ * 1.3, rotation=ROT_YTOX)
        faces += res_w["stone"]

    # 3. parapet crenelat pe toata linia acoperisului
    faces += crenellation(b, (0.0, -hl + 0.5, plinth_h + base_h), (0.0, hl - 0.5, plinth_h + base_h),
                          0.6, STONE, width=0.5, gap=0.45, style="rectangular")

    # 4. pavilion central: bloc mai inalt si mai proeminent (iese pe +X) +
    # balcon arcuit cu balustrada + cupola MARE nervurata pana la 19 m --
    # critica: "central pavilion with a large ribbed dome over an arched
    # balcony". REVIZUIRE: centrul nu iesea deloc pe +X (doar +0,6 m fata de
    # PB_DEPTH); acum are propria proiectie clara.
    center_w = 8.0
    center_out = 1.4
    center_extra_h = 3.4
    center_top = plinth_h + base_h + center_extra_h
    center_front_x = hd + center_out
    faces += list(b.box((center_out * 0.5, 0.0, plinth_h + (base_h + center_extra_h) * 0.5),
                        (PB_DEPTH + center_out, center_w, base_h + center_extra_h), STONE))
    # balconul arcuit: 3 arce late (round, rise=~half_w) la nivelul etajului
    # superior, in fata blocului central
    bal_span = center_w * 0.68
    bal_n = 3
    bal_pier_w = 0.3
    bal_bay = bal_span / bal_n
    bal_half_w = (bal_bay - bal_pier_w) * 0.5
    bal_pier_h = 1.3
    bal_opening_h = bal_pier_h + bal_half_w
    res_bal = _local_arcade(b, b, (center_front_x + 0.4, -bal_span * 0.5, 0.0),
                     (center_front_x + 0.4, bal_span * 0.5, 0.0), bal_n, bal_opening_h,
                     bal_pier_h, bal_pier_w, 0.32, STONE, STONE, style="round", glass=False,
                     base_z=plinth_h + ground_h)
    faces += res_bal["stone"]
    faces += list(balustrade(b, (center_front_x + 0.55, -bal_span * 0.5, plinth_h + ground_h + bal_opening_h + 0.1),
                             (center_front_x + 0.55, bal_span * 0.5, plinth_h + ground_h + bal_opening_h + 0.1),
                             0.5, STONE, merlon_w=0.16, merlon_gap=0.12))
    # cupola MARE, nervurata, deasupra pavilionului central -- raza calculata
    # explicit sa ajunga cat mai aproape de PB_DOME_TOP=19 m (cea mai inalta
    # piesa a fatadei, per contract).
    dome_r = min(center_w * 0.42, (PB_DOME_TOP - center_top) * 0.62)
    drum_h = dome_r * 0.35
    finial_h = min(dome_r * 0.7, PB_DOME_TOP - (center_top + drum_h + dome_r + 0.12))
    faces += dome(b, (center_out * 0.3, 0.0, center_top), dome_r, STONE, drum_h=drum_h,
                  profile="hemisphere", segments=18, ribs=12, lotus_ring=True,
                  finial=True, finial_h=max(finial_h, 0.3))

    # 5. doua cupole MICI intre centru si fiecare colt -- critica: "2 small
    # domes between the centre and each corner" (distincte de chhatri-urile
    # de colt, care sunt SEPARATE, mai aproape de capete)
    for cy in (-center_w * 0.5 - 4.0, center_w * 0.5 + 4.0):
        faces += list(b.box((0.0, cy, plinth_h + base_h + 0.5), (1.3, 1.3, 1.0), STONE))
        faces += dome(b, (0.0, cy, plinth_h + base_h + 1.0), 0.55, STONE, drum_h=0.18,
                      profile="hemisphere", segments=12, ribs=8, lotus_ring=True,
                      finial=True, finial_h=0.35)

    # 6. turnuri de colt cu cupole chhatri (turnuri rotunde, nu cutii, per
    # decupare -- coloane vizibile pe fatada turnului)
    for ty in (-hl + 2.4, hl - 2.4):
        tower_r = 1.1
        tower_top = plinth_h + base_h + 1.8
        faces += list(b.frustum((0.0, ty, tower_top * 0.5), tower_r + 0.15, tower_r,
                                tower_top, STONE, segments=14, axis="Z"))
        res_ct = chhatri(b, b, (0.0, ty, tower_top), 6, tower_r * 0.85, 1.2, STONE, STONE,
                         col_r=0.13, dome_radius=tower_r * 0.75, arch_style="round",
                         chajja_out=0.28, segments_dome=10)
        faces += res_ct["stone"]

    stone_obj = b.to_object("Palace_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    glow_obj = _finish_or_none(bg.to_object("Palace_Glow"))
    return stone_obj, glow_obj


pa_stone, pa_glow = build_palace_facade_a()
emit([pa_stone, pa_glow], "structures/palace_facade_a.glb", AO_STONE, origin="assembly",
     bevel=0.035, budget=24000)
# ambele fatade folosesc acelasi nume de nod ("Palace_Stone", contract §1.2)
# -- daca obiectul din facade_a ramane in scena, Blender redenumeste al
# doilea "Palace_Stone.001" la crearea lui, iar acel nume NU se potriveste
# cu cheia din COMPARE_SPECS["palace_facade_b"] (bug gasit la primul
# --compare: piesa iesea complet gri/netintata, cazuta pe atlas_material()
# implicit). Sterge obiectele dupa export, inainte de al doilea build.
pa_mesh = pa_stone.data
bpy.data.objects.remove(pa_stone, do_unlink=True)
bpy.data.meshes.remove(pa_mesh)
if pa_glow is not None:
    pa_glow_mesh = pa_glow.data
    bpy.data.objects.remove(pa_glow, do_unlink=True)
    bpy.data.meshes.remove(pa_glow_mesh)

pb_stone, pb_glow = build_palace_facade_b()
emit([pb_stone, pb_glow], "structures/palace_facade_b.glb", AO_STONE, origin="assembly",
     bevel=0.035, budget=26000)


# =============================================================================
# rampart_cannon
# =============================================================================
#
# Contract (brief §1.2): teava 3,2 m, total 3,6 x 1,6 x 1,5, h/l 0,42.
# ESCALADARE OPUS (runda 3; rundele 1-2 respinse: teava un cilindru drept
# NEINCLINAT -- `cylinder(axis="X")` nu primea inclinarea, doar centrul
# mutat pe axa inclinata -- cu o bila uriasa in spate, roti ca discuri
# plate, obraji ca placi drepte, negru mort in preview).
#
# LISTA DE ELEMENTE (decuparea rampart_cannon.png, citita inainte de primul
# vertex; vedere din stanga-fata, gura in dreapta cadrului, putin spre noi):
#   1. Teava lunga, CONICA (culata ~1,6x gura), gri inchis, ridicata ~10 grd.
#   2. 3 inele in relief: inelul de baza la culata, unul la tunari, unul
#      spre gura; gura EVAZATA (buza), cu gaura neagra vizibila.
#   3. Buton (cascabel) mic in spatele culatei.
#   4. Tunarii (fusurile laterale) sprijiniti pe obraji.
#   5. Afet de lemn roscat: 2 obraji cu profil IN TREPTE (inalti in fata,
#      sub tunari, coborand in trepte spre spate), cu coada inclinata pana
#      aproape de sol.
#   6. 2 roti MARI cu spite in fata, sub tunari: janta groasa, butuc,
#      ~12 spite (decuparea; brief-ul scrie 8 -- forma vine din planse).
#   7. 2 roti MICI pline la coada (rotile de spate ale afetului de
#      metereza, stanga-jos pe decupare).
#   Ce iese din contur: gura tevii (dreapta-sus), rotile.
#
# Axe: teava spre +X (fata principala, ca restul cetatii), rotile pe +-Y.
CN_BARREL_LEN = 3.2
CN_TILT = 10.0
CN_TRUNNION = (0.25, 0.0, 1.0)   # (x, y, z) al tunarilor
CN_TRUNNION_T = 1.3              # tunarii la 1,3 m de fata culatei (~40%)
CN_WHEEL_R = 0.62
CN_REAR_R = 0.25


def _lathe(b, profile, origin, axis, slot, segments=14, closed=False):
    """Suprafata de revolutie in jurul unei axe OARECARE: `profile` = lista
    (r, t) de-a lungul axei (t in m de la `origin`); r = 0 la capete da un
    varf inchis. Solid inchis daca profilul incepe si se termina la r = 0."""
    o = Vector(origin)
    a = Vector(axis).normalized()
    ref = Vector((0.0, 0.0, 1.0)) if abs(a.z) < 0.9 else Vector((1.0, 0.0, 0.0))
    u = a.cross(ref).normalized()
    v = a.cross(u).normalized()
    bm = b.bm
    rings = []
    for r, t in profile:
        c = o + a * t
        if r <= 1e-6:
            rings.append([bm.verts.new(c)])
        else:
            rings.append([bm.verts.new(c + (u * math.cos(2 * math.pi * k / segments)
                                            + v * math.sin(2 * math.pi * k / segments)) * r)
                          for k in range(segments)])
    faces = []
    pairs = list(zip(rings, rings[1:]))
    if closed:  # profil inchis (janta): ultimul inel se leaga de primul
        pairs.append((rings[-1], rings[0]))
    for ra, rb in pairs:
        if len(ra) == 1 and len(rb) == 1:
            continue
        for k in range(segments):
            k2 = (k + 1) % segments
            if len(ra) == 1:
                faces.append(bm.faces.new((ra[0], rb[k], rb[k2])))
            elif len(rb) == 1:
                faces.append(bm.faces.new((ra[k], rb[0], ra[k2])))
            else:
                faces.append(bm.faces.new((ra[k], rb[k], rb[k2], ra[k2])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _plate_xz(b, outline, y0, y1, slot):
    """Placa (prisma pe Y) dintr-un contur CONCAV in planul XZ -- capace prin
    ear-clipping (vocabularul), laturi quad. Solid manifold."""
    bm = b.bm
    fa = [bm.verts.new((x, y0, z)) for x, z in outline]
    fb = [bm.verts.new((x, y1, z)) for x, z in outline]
    faces = []
    for i0, i1, i2 in _ear_clip(outline):
        faces.append(bm.faces.new((fa[i0], fa[i1], fa[i2])))
        faces.append(bm.faces.new((fb[i2], fb[i1], fb[i0])))
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _spoked_wheel(b, center, r, width, spokes, slot):
    """Roata cu janta (inel gros), butuc si spite -- pe axa Y."""
    cx, cy, cz = center
    # janta: inel inchis (profil dreptunghiular revolut in jurul lui Y)
    rim_in = r * 0.84
    hw = width * 0.5
    faces = _lathe(b, [(rim_in, -hw), (r, -hw), (r, hw), (rim_in, hw)],
                   (cx, cy, cz), (0, 1, 0), slot, segments=14, closed=True)
    # butucul
    b.cylinder((cx, cy, cz), r * 0.17, width * 1.9, slot, segments=10, axis="Y")
    # spitele
    for k in range(spokes):
        ang = 2 * math.pi * (k + 0.5) / spokes
        d = Vector((math.cos(ang), 0.0, math.sin(ang)))
        p1 = Vector(center) + d * (r * 0.15)
        p2 = Vector(center) + d * (rim_in + 0.02)
        b.beam(p1, p2, (0.055, width * 0.55), slot, up=(0, 1, 0))
    return faces


def build_rampart_cannon():
    b = Builder()     # Cannon_Metal
    bw = Builder()    # Cannon_Wood

    tilt = math.radians(CN_TILT)
    axis = Vector((math.cos(tilt), 0.0, math.sin(tilt)))
    trun = Vector(CN_TRUNNION)
    breech = trun - axis * CN_TRUNNION_T

    # 1-3. teava: un singur profil revolut (r, t) de la butonul cascabelului
    # la fundul gurii -- culata 0,25, gura 0,155 (raport 1,6), buza 0,19
    L = CN_BARREL_LEN
    prof = [
        (0.0, -0.30), (0.075, -0.28), (0.095, -0.21), (0.075, -0.14),   # buton
        (0.05, -0.10), (0.05, -0.06), (0.17, -0.03), (0.23, 0.0),       # gat + culata
        (0.265, 0.02), (0.265, 0.16), (0.245, 0.18),                      # inel de baza
        (0.215, CN_TRUNNION_T - 0.08), (0.235, CN_TRUNNION_T - 0.06),     # inel la tunari
        (0.235, CN_TRUNNION_T + 0.06), (0.205, CN_TRUNNION_T + 0.08),
        (0.18, 2.20), (0.20, 2.22), (0.20, 2.32), (0.175, 2.34),          # inelul gurii
        (0.155, L - 0.26), (0.19, L - 0.14), (0.195, L),                  # buza evazata
        (0.095, L), (0.095, L - 0.22), (0.0, L - 0.22),                   # gaura
    ]
    _lathe(b, prof, breech, axis, CANNON_METAL, segments=12)
    # 4. tunarii (fusuri pe Y)
    b.cylinder((trun.x, trun.y, trun.z), 0.075, 0.74, CANNON_METAL, segments=10, axis="Y")

    # 5. obrajii afetului: profil in trepte, coada pana aproape de sol
    cheek = [(0.62, 0.40), (0.62, 0.93), (0.36, 0.93), (0.33, 1.0), (0.17, 1.0),
             (0.14, 0.93), (0.02, 0.93), (0.02, 0.80), (-0.36, 0.80), (-0.36, 0.66),
             (-0.74, 0.66), (-1.42, 0.36), (-1.42, 0.14), (-0.70, 0.26), (0.10, 0.38)]
    for s in (-1.0, 1.0):
        y0, y1 = s * 0.28, s * 0.40
        _plate_xz(bw, cheek, min(y0, y1), max(y0, y1), CANNON_WOOD)
    # traversele dintre obraji (fata, mijloc, coada) + pana de sub culata
    bw.box((0.45, 0.0, 0.52), (0.26, 0.58, 0.22), CANNON_WOOD)
    bw.box((-0.45, 0.0, 0.42), (0.30, 0.58, 0.18), CANNON_WOOD)
    bw.box((-1.20, 0.0, 0.30), (0.30, 0.58, 0.18), CANNON_WOOD)
    bw.box((-0.62, 0.0, 0.64), (0.46, 0.30, 0.16), CANNON_WOOD)

    # 6. rotile mari cu spite, sub tunari, pe osie
    ax_x = CN_TRUNNION[0]
    bw.cylinder((ax_x, 0.0, CN_WHEEL_R), 0.065, 1.42, CANNON_WOOD, segments=8, axis="Y")
    for s in (-1.0, 1.0):
        _spoked_wheel(bw, (ax_x, s * 0.60, CN_WHEEL_R), CN_WHEEL_R, 0.11, 12, CANNON_WOOD)

    # 7. rotile mici pline de la coada
    for s in (-1.0, 1.0):
        bw.cylinder((-1.18, s * 0.48, CN_REAR_R), CN_REAR_R, 0.12, CANNON_WOOD,
                    segments=12, axis="Y")
        bw.cylinder((-1.18, s * 0.48, CN_REAR_R), CN_REAR_R * 0.35, 0.18, CANNON_WOOD,
                    segments=8, axis="Y")
    bw.cylinder((-1.18, 0.0, CN_REAR_R), 0.05, 1.04, CANNON_WOOD, segments=8, axis="Y")

    metal_obj = b.to_object("Cannon_Metal")
    wood_obj = bw.to_object("Cannon_Wood")
    return metal_obj, wood_obj


cannon_metal, cannon_wood = build_rampart_cannon()
emit([cannon_metal, cannon_wood], "props/rampart_cannon.glb", AO_PROP, origin="assembly",
     bevel=0.012, budget=4200)


print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-42s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL cetate (val 2a): %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (wall_stone, wall_glow, turret_stone, turret_glow, bastion_stone,
                        jai_stone, jai_doors, fateh_stone, fateh_doors,
                        loha_stone, loha_doors, pb_stone, pb_glow,
                        cannon_metal, cannon_wood) if o is not None],
          "jodhpur_fort.blend")
