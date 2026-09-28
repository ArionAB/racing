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


# =============================================================================
# fort_wall_segment -- modul de zid inlantuibil
# =============================================================================
#
# Contract (brief §1.2): 12 m lung (Y) x 3 m gros x 14 m inalt, h/l 0,34.
# Decuparea arata un TRONSON intre doua turnuri -- turnurile sunt piesa
# separata (fort_wall_turret), de-aici modulul e DOAR peretele drept dintre
# ele. Lista de elemente (dupa Read fort_wall_segment.png), de jos in sus:
#
#   1. Soclu usor tesit la baza (banda ingusta, teasa spre exterior).
#   2. Zid drept, gros, cu linii de asize orizontale (TEXTURA, nu geometrie --
#      regula 0.5 -- vine din clasa red_sandstone la integrare).
#   3. Un rand de 3 guri de tragere dreptunghiulare inguste, la ~55-60% din
#      inaltime, distantate regulat (pe decupare: stanga, mijloc, dreapta).
#   4. O cornisa/parapet in consola aproape de varf (banda ingusta iesita),
#      cu o umbra clara dedesubt -- `chajja`/`balcony_band` liniar.
#   5. Creneluri DREPTUNGHIULARE, DESE, regulate pe toata lungimea sus, sub
#      forma de dinti patrati egali (numarate pe decupare: ~9-10 pe cei 12 m).
#
# Lungimea pe Y (capete PLANE la y=+-6, ca sa se inlantuie cap la cap sau
# langa turn), fata principala (guri de tragere, cornisa) spre +X.
WS_LEN = 12.0
WS_THICK = 3.0
WS_H = 14.0


def build_fort_wall_segment():
    b = Builder()
    faces = []
    hl = WS_LEN * 0.5
    ht = WS_THICK * 0.5

    # 1. soclu usor tesit (banda ingusta la baza, mai lata decat zidul)
    plinth_h = 0.6
    faces += list(b.box((0.0, 0.0, plinth_h * 0.5), (WS_THICK + 0.30, WS_LEN, plinth_h), STONE))

    # 2. zidul drept, gros -- corpul principal
    wall_h = WS_H - plinth_h - 1.1  # rezerva 1,1 pentru cornisa+creneluri
    faces += list(b.box((0.0, 0.0, plinth_h + wall_h * 0.5), (WS_THICK, WS_LEN, wall_h), STONE))
    wall_top_z = plinth_h + wall_h

    # 3. guri de tragere: 3, dreptunghiulare inguste, la ~57% din inaltimea
    # zidului, distantate regulat pe lungime (stanga/mijloc/dreapta), pe
    # fata +X (principala)
    slit_z = plinth_h + wall_h * 0.58
    for t in (-0.62, 0.0, 0.62):
        sy = t * hl
        faces += list(b.box((ht + 0.02, sy, slit_z), (0.10, 0.22, 0.9), STONE))

    # 4. cornisa in consola aproape de varf, pe fetele +X/-X (lungi)
    faces += list(chajja(b, (ht, 0.0, wall_top_z), WS_LEN + 0.4, WS_THICK + 0.35, STONE,
                         thickness=0.16, slope=0.5, rotation=ROT_YTOX))
    faces += list(chajja(b, (-ht, 0.0, wall_top_z), WS_LEN + 0.4, WS_THICK + 0.35, STONE,
                         thickness=0.16, slope=0.5, rotation=ROT_YTONX))
    parapet_base_z = wall_top_z + 0.16

    # parapetul plin de sub creneluri (banda continua pe toata lungimea)
    parapet_h = WS_H - parapet_base_z - 0.55
    faces += list(b.box((0.0, 0.0, parapet_base_z + parapet_h * 0.5),
                        (WS_THICK - 0.15, WS_LEN, parapet_h), STONE))
    crenel_z = parapet_base_z + parapet_h

    # 5. creneluri dreptunghiulare, dese, regulate -- ~9-10 pe cei 12 m.
    # Marite A DOUA OARA (0,55/0,55 -> 1,0/0,85 -> 1,4/1,0): la a doua
    # comparatie tot citeau subtiri fata de dintii grosi, apropiati de pe
    # decupare.
    faces += crenellation(b, (0.0, -hl, crenel_z), (0.0, hl, crenel_z), 1.4, STONE,
                          width=1.0, gap=0.35, style="rectangular")

    # capete plane (deja plane din constructia pe cutii -- nimic de adaugat)
    stone_obj = b.to_object("Wall_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    return stone_obj


# =============================================================================
# fort_wall_turret -- turnul patrat de la capatul tronsonului
# =============================================================================
#
# Contract (brief §1.2): 4,5 x 4,5 m, 17 m inalt -- piesa NOUA, desprinsa din
# fort_wall_segment (nu are decupare proprie in planta v1 -- brief-ul o descrie
# explicit ca "turnul patrat de la capetele tronsonului de pe decupare, piesa
# noua"). Lista de elemente (derivata din decuparea fort_wall_segment.png,
# unde turnurile de capat apar taiate de cadru), de jos in sus:
#
#   1. Soclu tesit la baza (ca zidul).
#   2. Corp patrat, drept, depaseste inaltimea zidului cu ~3 m.
#   3. 2 guri de tragere pe fata vizibila (+X, exterior).
#   4. Cornisa in consola pe toate 4 laturile.
#   5. Creneluri proprii, dreptunghiulare, pe tot perimetrul patrat.
WT_SIDE = 4.5
WT_H = 17.0


def build_fort_wall_turret():
    b = Builder()
    faces = []
    hs = WT_SIDE * 0.5

    plinth_h = 0.6
    faces += list(b.box((0.0, 0.0, plinth_h * 0.5), (WT_SIDE + 0.35, WT_SIDE + 0.35, plinth_h), STONE))

    wall_h = WT_H - plinth_h - 1.3
    faces += list(b.box((0.0, 0.0, plinth_h + wall_h * 0.5), (WT_SIDE, WT_SIDE, wall_h), STONE))
    wall_top_z = plinth_h + wall_h

    # 2 guri de tragere pe fata +X (exterior, principala)
    slit_z = plinth_h + wall_h * 0.62
    for sy in (-0.55, 0.55):
        faces += list(b.box((hs + 0.02, sy, slit_z), (0.10, 0.22, 0.85), STONE))

    # cornisa pe toate 4 laturi
    for nx, ny in ((0, 1), (1, 0), (0, -1), (-1, 0)):
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        cx, cy = nx * hs, ny * hs
        faces += list(chajja(b, (cx, cy, wall_top_z), WT_SIDE + 0.4, 0.35, STONE,
                             thickness=0.16, slope=0.5, rotation=rot))
    parapet_base_z = wall_top_z + 0.16
    parapet_h = WT_H - parapet_base_z - 0.55
    faces += list(b.box((0.0, 0.0, parapet_base_z + parapet_h * 0.5),
                        (WT_SIDE - 0.15, WT_SIDE - 0.15, parapet_h), STONE))
    crenel_z = parapet_base_z + parapet_h

    corners = [(-hs, -hs), (hs, -hs), (hs, hs), (-hs, hs), (-hs, -hs)]
    for i in range(4):
        p0 = (corners[i][0], corners[i][1], crenel_z)
        p1 = (corners[i + 1][0], corners[i + 1][1], crenel_z)
        faces += crenellation(b, p0, p1, 0.9, STONE, width=0.75, gap=0.42, style="rectangular")

    stone_obj = b.to_object("Turret_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    return stone_obj


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

    n_slits = 10
    for i in range(n_slits):
        a = 2.0 * math.pi * i / n_slits
        sx, sy = math.cos(a) * (r_slit + 0.05), math.sin(a) * (r_slit + 0.05)
        rot = Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(math.radians(90.0), 3, "X")
        faces += list(b.box((sx, sy, slit_z), (0.10, 0.85, 0.22), STONE, rotation=rot))

    # brau/cornisa aproape de varf
    faces += list(balcony_band(b, (0.0, 0.0, body_top_z), BA_R_TOP - 0.35, BA_R_TOP + 0.20,
                               0.28, STONE, segments=BA_SEG))
    parapet_base_z = body_top_z + 0.28
    parapet_h = BA_H - parapet_base_z - 0.55
    faces += list(b.frustum((0.0, 0.0, parapet_base_z + parapet_h * 0.5),
                            BA_R_TOP - 0.15, BA_R_TOP - 0.25, parapet_h, STONE,
                            segments=BA_SEG, axis="Z"))
    crenel_z = parapet_base_z + parapet_h

    # creneluri ROTUNJITE (distincte de zid: crenel_merlon style="rounded").
    # Marite A DOUA OARA (0,56 -> 1,0 -> 1,5 inaltime) -- la Ø16 m sus tot
    # citeau subtiri la a doua comparatie. Numar redus (16->13) ca sa ramana
    # loc intre ele odata cu latimea marita.
    n_merlon = 13
    for i in range(n_merlon):
        a = 2.0 * math.pi * (i + 0.5) / n_merlon
        gx, gy = math.cos(a) * (BA_R_TOP - 0.6), math.sin(a) * (BA_R_TOP - 0.6)
        rot = Matrix.Rotation(a, 3, "Z")
        faces += list(crenel_merlon(b, (gx, gy, crenel_z + 0.75), 1.5, STONE,
                                    width=1.3, depth=0.8, style="rounded", rotation=rot))

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


def _gate_doors(b, center, gap_w, door_h, wall_t, slot, stud_slot, open_angle_deg=75.0):
    """Doua canaturi batute cu tepi (3x5), balamalate la ambrazura, deschise
    la `open_angle_deg` -- stau LIPITE de ambrazura (in afara golului de
    7,0 m), niciodata proiectate in interiorul lui (brief: canaturile deschise
    NU intra in gol). Golul e de-a lungul Y (latimea 7 m), portalul strabate
    peretele pe X, deci canaturile se rotesc/deschid in planul XY, balamaua
    pe muchia exterioara (langa perete, pe Y)."""
    cx, cy, cz = center
    leaf_w = gap_w * 0.5 - 0.05
    leaf_t = 0.14
    faces = []
    for side in (-1.0, 1.0):
        hinge_y = cy + side * gap_w * 0.5
        # balamaua e pe muchia exterioara; canatul se deschide spre EXTERIOR
        # (spre camera/afara, +X), asezat aproape paralel cu peretele (planul YZ)
        ang = math.radians(open_angle_deg) * (-side)
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

    tower_r = 3.0
    # distanta intre AXELE turnurilor: trebuie sa lase loc pentru (a) golul
    # portii (GATE_GAP_W=7,0), (b) grosimea picioarelor arcului de-o parte si
    # de alta, SI (c) un guler de perete plin intre picioarele arcului si
    # coloana turnului (altfel panoul arcului `center_span` iese mai ingust
    # decat golul insusi -- bug gasit la primul --compare: turnurile erau
    # aproape lipite si arcul disparea comprimat intr-o fasie). Tinta:
    # center_span (mai jos) >= GATE_GAP_W * 1.7, cu turnurile inca in
    # anvelopa de 26 m totala a contractului.
    tower_gap = GATE_GAP_W + tower_r * 2.0 + 3.0

    # 1. turnurile rotunde, cate unul la fiecare capat (de-a lungul Y)
    for side in (-1.0, 1.0):
        ty = side * tower_gap * 0.5
        plinth_h = 0.7
        faces += list(b.frustum((0.0, ty, plinth_h * 0.5), tower_r + 0.3, tower_r + 0.05,
                                plinth_h, STONE, segments=16, axis="Z"))
        body_h = tower_h - plinth_h - 1.1
        faces += list(b.frustum((0.0, ty, plinth_h + body_h * 0.5), tower_r, tower_r - 0.4,
                                body_h, STONE, segments=16, axis="Z"))
        body_top_z = plinth_h + body_h
        # brau median
        faces += list(balcony_band(b, (0.0, ty, plinth_h + body_h * 0.45), tower_r - 0.5,
                                   tower_r - 0.15, 0.18, STONE, segments=16))
        # guri de tragere, 2 pe fata exterioara (spre +X, catre camera)
        slit_r = tower_r - 0.35
        for sa, sz in ((0.35, 0.40), (-0.35, 0.62)):
            a = sa
            gx, gy = math.cos(a) * slit_r, ty + math.sin(a) * slit_r
            rot = Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(math.radians(90.0), 3, "X")
            faces += list(b.box((gx, gy, plinth_h + body_h * sz), (0.09, 0.7, 0.20), STONE,
                                rotation=rot))
        # creneluri DREPTUNGHIULARE pe turn (ca pe decupare -- acelasi stil
        # ca zidul, nu rotunjit ca bastionul; marite fata de prima incercare,
        # care abia se vedea ca "pegs" la scara unui turn de 3 m raza)
        n_m = 9
        for i in range(n_m):
            a = 2.0 * math.pi * (i + 0.5) / n_m
            gx, gy = math.cos(a) * (tower_r - 0.45), ty + math.sin(a) * (tower_r - 0.45)
            rot = Matrix.Rotation(a, 3, "Z")
            faces += list(crenel_merlon(b, (gx, gy, body_top_z + 0.5), 1.0, STONE,
                                        width=0.85, depth=0.55, style="rectangular", rotation=rot))

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
    arch_h = min(wall_top_z * 0.72, tower_h - 3.0)
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

    # parapet crenelat continuu deasupra bentii centrale, la aceeasi cota ca
    # varful turnurilor (fara acoperi -- doar intre turnuri, nu peste ele).
    # Merloane marite (ca la turnuri) -- 0,5 m abia se vedea la scara unei
    # benzi late de peste 10 m.
    par_h = 0.7
    faces += list(b.box((0.0, 0.0, wall_top_z + par_h * 0.5), (wall_t - 0.2, center_span, par_h), STONE))
    faces += crenellation(b, (0.0, -center_span * 0.5, wall_top_z + par_h), (0.0, center_span * 0.5, wall_top_z + par_h),
                          1.0, STONE, width=0.85, gap=0.55, style="rectangular")

    # 5. Fateh: chhatri centrat deasupra cheii arcului
    if chhatri_over_arch:
        res_c = chhatri(b, b, (0.0, 0.0, wall_top_z + par_h + 0.5), 6, 0.9, 1.1, STONE, STONE,
                        col_r=0.13, dome_radius=0.55, arch_style="round", chajja_out=0.32,
                        segments_dome=10)
        faces += res_c["stone"]

    # canaturile portii -- Builder SEPARAT (door_slot difera de STONE)
    bdoor = Builder()
    door_faces = _gate_doors(bdoor, (wall_t * 0.5 - 0.05, 0.0, 0.0), GATE_GAP_W - 0.15,
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
wall_stone = build_fort_wall_segment()
emit([wall_stone], "structures/fort_wall_segment.glb", AO_STONE, bevel=0.03, budget=6000)

# fort_wall_turret
turret_stone = build_fort_wall_turret()
emit([turret_stone], "structures/fort_wall_turret.glb", AO_STONE, bevel=0.03, budget=5500)

# fort_bastion
bastion_stone = build_fort_bastion()
emit([bastion_stone], "structures/fort_bastion.glb", AO_STONE, bevel=0.03, budget=9000)

# fort_gate_jai -- CEL MAI INALT (16 m turnuri), prioritate (contractul golului)
jai_stone, jai_doors, jai_arch_h, jai_pier_h = _build_gate(16.0, DOOR_WOOD, False, "GateJai")
emit([jai_stone, jai_doors], "structures/fort_gate_jai.glb", AO_STONE, origin="assembly",
     bevel=0.03, budget=9500)
print()
print("MASURATOARE POARTA JAI (brief §1.2, contract gol):")
print("  gol latime libera (proiectie pe plan, pana la 2,0 m):", GATE_GAP_W, "m  (contract 7,0 m)")
print("  cheia arcului (varf arc fata de sol):", round(jai_arch_h, 2), "m  (contract >= 9,0 m)")
print("  canaturile deschise stau LIPITE de ambrazura, in afara golului")
print()

# fort_gate_fateh -- chhatri peste arc
fateh_stone, fateh_doors, fateh_arch_h, fateh_pier_h = _build_gate(14.0, DOOR_WOOD, True, "GateFateh")
emit([fateh_stone, fateh_doors], "structures/fort_gate_fateh.glb", AO_STONE, origin="assembly",
     bevel=0.03, budget=10000)

# fort_gate_loha -- cea mai joasa, canaturi de fier
loha_stone, loha_doors, loha_arch_h, loha_pier_h = _build_gate(12.5, DOOR_IRON, False, "GateLoha")
emit([loha_stone, loha_doors], "structures/fort_gate_loha.glb", AO_STONE, origin="assembly",
     bevel=0.03, budget=9000)


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


def build_palace_facade_a():
    b = Builder()
    faces = []
    hl = PA_LEN * 0.5
    hd = PA_DEPTH * 0.5

    floor_h = 4.2
    n_floors = 3
    base_h = floor_h * n_floors
    # corp principal: 2 etaje pline + al 3-lea etaj simplu, cu corpul central
    # (mijlocul, ~9 m) mai inalt cu un etaj de chhatri. Lungimea pe Y,
    # adancimea pe X.
    faces += list(b.box((0.0, 0.0, base_h * 0.5), (PA_DEPTH, PA_LEN, base_h), STONE))

    # jali retrase: fete cu grila 3x4 gauri, pe fata +X, intre proiectiile
    # de jharokha -- 6 panouri distribuite pe lungime (evitand centrul, unde
    # sta balconul mare). REVIZUIRE (gasita la primul --compare): grila era
    # 0,20 m adancime pe un panou de 6 m adancime totala a cladirii -- practic
    # invizibila la scara asta. Marita adancimea recesului si dimensiunea
    # golurilor.
    jali_x = hd + 0.001
    jali_positions = [-hl * 0.78, -hl * 0.55, -hl * 0.32, hl * 0.32, hl * 0.55, hl * 0.78]
    for jy in jali_positions:
        panel_w, panel_h = 2.6, 2.8
        panel_cz = floor_h * 0.55
        cols, rows = 3, 4
        cell_w, cell_h = panel_w / cols, panel_h / rows
        for cxi in range(cols):
            for ryi in range(rows):
                hy = jy + (cxi - (cols - 1) * 0.5) * cell_w
                hz = panel_cz + (ryi - (rows - 1) * 0.5) * cell_h
                faces += list(b.box((jali_x - 0.35, hy, hz), (0.65, cell_w * 0.68, cell_h * 0.68), STONE))

    # jharokha: balcoane in consola cu acoperis curbat (bangla, aproximat cu
    # frustum aplatizat), pe parter si etaj 1, la pozitiile ramase (langa
    # jali, alternand) -- 4 proiectii vizibile, pe fata +X. REVIZUIRE: iesirea
    # (0,35 m) si volumul (0,7 m adancime) erau prea mici ca sa citeasca drept
    # "balcon in consola" la scara de 40 m lungime/14 m inaltime -- marite
    # substantial (iesire ~1,3 m, volum mai gros).
    for jy in (-hl * 0.66, -hl * 0.20, hl * 0.20, hl * 0.66):
        for fl in (0, 1):
            jz = floor_h * (fl + 0.55)
            faces += list(b.box((hd + 0.75, jy, jz), (1.5, 1.9, 1.7), STONE))
            faces += list(balustrade(b, (hd + 1.45, jy - 0.9, jz - 0.6),
                                     (hd + 1.45, jy + 0.9, jz - 0.6), 0.6, STONE,
                                     merlon_w=0.16, merlon_gap=0.12))
            # acoperis curbat bangla: frustum jos si lat, ca o cupola turtita
            faces += list(b.frustum((hd + 0.75, jy, jz + 0.95), 1.15, 0.18, 0.6, STONE,
                                    segments=10, axis="Z"))

    # corp central: mai inalt SI mai proeminent (iese in fata pe +X, nu doar
    # in sus) -- REVIZUIRE: initial centrat pe adancime (doar PA_DEPTH+0.6),
    # deci nu proiecta deloc spre camera; acum are propria iesire pe +X, ca
    # pavilionul central de pe decupare.
    center_w = 8.5
    center_extra_h = floor_h * 0.9
    center_out = 1.6
    faces += list(b.box((center_out * 0.5, 0.0, base_h + center_extra_h * 0.5),
                        (PA_DEPTH + center_out, center_w, center_extra_h), STONE))
    # arcada deschisa a balconului central, 2 niveluri, pe fata +X (acum in
    # fata corpului central, care iese peste restul fatadei)
    center_front_x = hd + center_out
    for lvl in range(2):
        lz = floor_h * (lvl + 0.5)
        res = arcade(b, b, (center_front_x + 0.5, -center_w * 0.42, lz - floor_h * 0.45),
                    (center_front_x + 0.5, center_w * 0.42, lz - floor_h * 0.45), 4, floor_h * 0.72,
                    floor_h * 0.14, 0.22, 0.30, STONE, STONE, style="round", glass=False,
                    base_z=0.0)
        faces += res["stone"]
        faces += list(balustrade(b, (center_front_x + 0.65, -center_w * 0.42, lz + floor_h * 0.12),
                                 (center_front_x + 0.65, center_w * 0.42, lz + floor_h * 0.12), 0.5, STONE,
                                 merlon_w=0.16, merlon_gap=0.12))

    # doua turnuri subtiri cu chhatri mici, aproape de colturi -- REVIZUIRE:
    # initial centrate pe adancime (X=0), acum proiectate spre +X (fata
    # camerei), ca doua turnuri de colt vizibile, nu ascunse in spatele
    # propriei umbre.
    tower_out = 0.9
    for ty in (-hl + 3.0, hl - 3.0):
        tower_top = base_h + 1.6
        faces += list(b.box((tower_out * 0.5, ty, tower_top * 0.5), (1.6 + tower_out, 1.6, tower_top), STONE))
        res_t = chhatri(b, b, (tower_out, ty, tower_top), 6, 0.65, 0.7, STONE, STONE,
                        col_r=0.09, dome_radius=0.4, arch_style="round", chajja_out=0.22,
                        segments_dome=8)
        faces += res_t["stone"]

    # parapet simplu pe restul fatadei (etaj 3 simplificat)
    faces += list(b.box((0.0, 0.0, base_h + 0.35), (PA_DEPTH - 0.4, PA_LEN - center_w - 4.0, 0.7), STONE))

    stone_obj = b.to_object("Palace_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    return stone_obj


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


def build_palace_facade_b():
    b = Builder()
    faces = []
    hl = PB_LEN * 0.5
    hd = PB_DEPTH * 0.5

    floor_h = 4.2
    ground_h = floor_h
    upper_h = floor_h

    # corp principal -- lungimea pe Y, adancimea pe X
    base_h = ground_h + upper_h
    faces += list(b.box((0.0, 0.0, base_h * 0.5), (PB_DEPTH, PB_LEN, base_h), STONE))

    # 1. arcada deschisa la parter, pe toata latimea, fata +X
    res = arcade(b, b, (hd + 0.001, -hl + 1.5, 0.0), (hd + 0.001, hl - 1.5, 0.0), 10,
                ground_h * 0.78, ground_h * 0.12, 0.30, 0.30, STONE, STONE,
                style="round", glass=False, base_z=0.0)
    faces += res["stone"]

    # 2. ferestre in arc regulate pe etajul 1, fata +X
    n_win = 9
    for i in range(n_win):
        wy = -hl + 2.5 + i * ((PB_LEN - 5.0) / (n_win - 1))
        res_w = arch_opening(b, b, (hd, wy, ground_h + upper_h * 0.5), 1.1, 2.2, 0.9, 0.35,
                             STONE, STONE, style="round", glass=False, reveal=0.12,
                             panel_w=2.0, panel_h=upper_h * 0.95, rotation=ROT_YTOX)
        faces += res_w["stone"]

    # 3. parapet crenelat pe toata linia acoperisului
    faces += crenellation(b, (0.0, -hl + 0.5, base_h), (0.0, hl - 0.5, base_h),
                          0.6, STONE, width=0.5, gap=0.45, style="rectangular")

    # 4. pavilion central: bloc mai inalt + balcon + cupola mare pana la 19 m
    center_w = 7.0
    center_top = base_h + 3.0
    faces += list(b.box((0.0, 0.0, center_top * 0.5), (PB_DEPTH + 0.6, center_w, center_top), STONE))
    faces += list(b.box((hd + 0.4, 0.0, base_h + 0.9), (0.6, 2.2, 1.2), STONE))
    faces += list(balustrade(b, (hd + 0.7, -1.1, base_h + 0.35), (hd + 0.7, 1.1, base_h + 0.35),
                             0.5, STONE, merlon_w=0.16, merlon_gap=0.12))
    dome_r = min(center_w * 0.5, PB_DOME_TOP - center_top) * 0.85
    faces += dome(b, (0.0, 0.0, center_top), dome_r, STONE, drum_h=dome_r * 0.3,
                  profile="hemisphere", segments=16, ribs=10, lotus_ring=True,
                  finial=True, finial_h=min(dome_r * 0.6, PB_DOME_TOP - center_top - dome_r * 1.3 - dome_r * 0.3))

    # 5. doua chhatri mici, langa pavilionul central
    for cy in (-center_w * 0.5 - 1.6, center_w * 0.5 + 1.6):
        res_c = chhatri(b, b, (0.0, cy, base_h + 0.3), 6, 0.7, 0.9, STONE, STONE,
                        col_r=0.10, dome_radius=0.42, arch_style="round", chajja_out=0.24,
                        segments_dome=8)
        faces += res_c["stone"]

    # 6. turnuri de colt cu cupolite mici
    for ty in (-hl + 2.2, hl - 2.2):
        tower_top = base_h + 1.4
        faces += list(b.box((0.0, ty, tower_top * 0.5), (1.7, 1.7, tower_top), STONE))
        faces += dome(b, (0.0, ty, tower_top), 0.9, STONE, drum_h=0.25,
                      profile="hemisphere", segments=12, ribs=8, lotus_ring=True,
                      finial=True, finial_h=0.5)

    stone_obj = b.to_object("Palace_Stone")
    for f in faces:
        if f.is_valid:
            f[b.slot] = STONE
    return stone_obj


pa_stone = build_palace_facade_a()
emit([pa_stone], "structures/palace_facade_a.glb", AO_STONE, bevel=0.035, budget=16000)
# ambele fatade folosesc acelasi nume de nod ("Palace_Stone", contract §1.2)
# -- daca obiectul din facade_a ramane in scena, Blender redenumeste al
# doilea "Palace_Stone.001" la crearea lui, iar acel nume NU se potriveste
# cu cheia din COMPARE_SPECS["palace_facade_b"] (bug gasit la primul
# --compare: piesa iesea complet gri/netintata, cazuta pe atlas_material()
# implicit). Sterge obiectul dupa export, inainte de al doilea build.
pa_mesh = pa_stone.data
bpy.data.objects.remove(pa_stone, do_unlink=True)
bpy.data.meshes.remove(pa_mesh)

pb_stone = build_palace_facade_b()
emit([pb_stone], "structures/palace_facade_b.glb", AO_STONE, bevel=0.035, budget=17000)


# =============================================================================
# rampart_cannon
# =============================================================================
#
# Contract (brief §1.2): teava 3,2 m, total 3,6 x 1,6 x 1,5, h/l 0,42.
# Lista de elemente (dupa Read rampart_cannon.png), de jos in sus / spate-fata:
#
#   1. Afet de lemn: doua obraze/console laterale, cu o platforma orizontala.
#   2. DOUA roti cu spite (8 spite fiecare, geometrie), montate pe axul de
#      sub teava.
#   3. Teava metalica intunecata (VOLCANIC_BLACK), cu 2-3 inele in relief si
#      gura evazata -- usor ridicata (~10 deg) pe afet. Teava priveste spre
#      +X (fata principala catre camera).
CN_BARREL_LEN = 3.2


def build_rampart_cannon():
    b = Builder()
    bw = Builder()
    faces = []
    wood_faces = []

    tilt = math.radians(10.0)

    # 3. teava: cilindru principal + 2 inele + gura evazata (con), inclinata
    # in planul XZ (lungimea pe X, spre camera)
    barrel_r = 0.16
    barrel_c0 = Vector((0.0, 0.0, 0.85))
    barrel_axis = Vector((math.cos(tilt), 0.0, math.sin(tilt)))
    barrel_c = barrel_c0 + barrel_axis * (CN_BARREL_LEN * 0.5 - 0.3)
    faces += list(b.cylinder((barrel_c.x, barrel_c.y, barrel_c.z), barrel_r, CN_BARREL_LEN,
                             CANNON_METAL, segments=14, axis="X"))
    # inelele: 2, ca frustum-uri usor mai late, distantate pe lungimea tevii
    for t_ring in (0.25, 0.62):
        ring_c = barrel_c0 + barrel_axis * (CN_BARREL_LEN * (t_ring - 0.5) + CN_BARREL_LEN * 0.2)
        faces += list(b.frustum((ring_c.x, ring_c.y, ring_c.z), barrel_r * 1.22, barrel_r * 1.22,
                                0.10, CANNON_METAL, segments=14, axis="X"))
    # gura evazata la capatul din fata
    muzzle_c = barrel_c0 + barrel_axis * (CN_BARREL_LEN - 0.05)
    faces += list(b.frustum((muzzle_c.x, muzzle_c.y, muzzle_c.z), barrel_r * 1.35, barrel_r * 1.05,
                            0.16, CANNON_METAL, segments=14, axis="X"))

    # 1. afet de lemn: doua console laterale (pe Y, de o parte si de alta a
    # tevii) + platforma
    axle_z = 0.55
    axle_y = 0.62
    for sy in (-axle_y, axle_y):
        wood_faces += list(bw.box((0.0, sy, axle_z * 0.5 + 0.05), (1.5, 0.14, axle_z + 0.1), CANNON_WOOD))
    wood_faces += list(bw.box((0.0, 0.0, axle_z + 0.18), (0.9, axle_y * 2 + 0.14, 0.16), CANNON_WOOD))

    # 2. doua roti cu spite (8 spite fiecare), pe axul Y. REVIZUIRE (gasita
    # la primul --compare): un disc solid plin + spite deasupra citea ca o
    # rondela plata (spitele coplanare, invizibile). A DOUA REVIZUIRE:
    # incercarea de janta-inel din cutii tangente (Matrix.Rotation pe Y)
    # a iesit ca o roata dintata/alternanta, geometrie stricata -- semnul
    # sau referinta unghiului pentru `rotation` pe cutii tangente nu se
    # comporta simplu (memoria semnul-rotatiilor-in-builder). Revenire la
    # ce functioneaza sigur: disc SUBTIRE (janta) + disc si mai subtire
    # decalat (butuc central, contrastant prin proeminenta) + spite ca bare
    # DREPTE prin centru (nu tangente) -- 4 bare complete care trec prin
    # butuc (8 "spite" vizuale, cate 2 pe fiecare bara), profil scazut ca sa
    # nu domine discul, dar clar vizibile ca relief pe fata janta.
    wheel_r = 0.55
    wheel_thick = 0.10
    for sy in (-axle_y - 0.12, axle_y + 0.12):
        # janta (discul propriu-zis)
        wood_faces += list(bw.cylinder((0.0, sy, wheel_r), wheel_r, wheel_thick,
                                       CANNON_WOOD, segments=16, axis="Y"))
        # butucul central, usor proeminent pe ambele fete
        wood_faces += list(bw.cylinder((0.0, sy, wheel_r), wheel_r * 0.16, wheel_thick * 1.6,
                                       CANNON_WOOD, segments=10, axis="Y"))
        # 4 bare drepte prin centru (8 spite vizuale), usor in relief pe fata
        # discului (+/-Y fata de planul jantei) -- se vad ca dungi radiale
        n_bars = 4
        for i in range(n_bars):
            a = math.pi * i / n_bars
            rot = Matrix.Rotation(a, 3, "Y")
            for face_sign in (-1.0, 1.0):
                bar_y = sy + face_sign * (wheel_thick * 0.5 + 0.012)
                wood_faces += list(bw.box((0.0, bar_y, wheel_r), (wheel_r * 1.82, 0.02, 0.07),
                                          CANNON_WOOD, rotation=rot))

    stone_obj = b.to_object("Cannon_Metal")
    for f in faces:
        if f.is_valid:
            f[b.slot] = CANNON_METAL
    wood_obj = bw.to_object("Cannon_Wood")
    for f in wood_faces:
        if f.is_valid:
            f[bw.slot] = CANNON_WOOD
    return stone_obj, wood_obj


cannon_metal, cannon_wood = build_rampart_cannon()
emit([cannon_metal, cannon_wood], "props/rampart_cannon.glb", AO_PROP, origin="assembly",
     bevel=0.015, budget=3300)


print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-42s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL cetate (val 2a): %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (wall_stone, turret_stone, bastion_stone,
                        jai_stone, jai_doors, fateh_stone, fateh_doors,
                        loha_stone, loha_doors, pb_stone,
                        cannon_metal, cannon_wood) if o is not None],
          "jodhpur_fort.blend")
