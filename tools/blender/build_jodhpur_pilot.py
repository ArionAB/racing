"""Jodhpur — Pilotul (brief §1.1, val 1 din docs/asset_briefs/jodhpur_kit.md).

  jodhpur/buildings/ghanta_ghar.glb    turnul cu ceas (reperul lui H.)
  jodhpur/buildings/blue_house_a.glb   casa albastra simpla, cu scara

Cele doua piese care valideaza harnasul de comparatie (`preview_jodhpur.py
--compare`) si cele doua clase de culoare (gresie ROCK_LIGHT -> red_sandstone,
perete albastru FOAM_WHITE -> blue_lime_light). Fidelitatea fata de decupare
e criteriul de acceptare (brief §0.1) — listele de elemente de mai jos s-au
scris dupa ce am deschis efectiv
docs/track_briefs/img/jodhpur_assets_v1/ghanta_ghar.png si blue_house_a.png.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_pilot.py
"""

import math
from mathutils import Vector

# Sloturile legale pe Jodhpur (brief §0.4).
STONE = ROCK_LIGHT       # gresia fortului/turnului -> clasa red_sandstone la integrare
WALL = FOAM_WHITE        # peretele albastru (alb x tenta blue_lime_light/indigo)
TRIM_WOOD = WOOD         # usi
DOOR_DARK = LOG_DARK     # usi inchise la culoare
GLOW = VOLCANIC_BLACK    # goluri de geam/cadran, ziua inchise
RAIL_WHITE = FOAM_WHITE  # balustrada, FARA tenta (nod separat de perete)

AO_TOWER = dict(samples=24, dist=6.0, gradient="vertical",
                low=0.42, high=1.00, power=0.85, floor=0.16)
AO_HOUSE = dict(samples=20, dist=4.0, gradient="vertical",
                low=0.46, high=1.00, power=0.88, floor=0.18)


# --- ghanta_ghar -------------------------------------------------------------
#
# Contract (brief §1.1): 22 m inalt, baza 7x7 m, h/l 2,17. Lista de elemente
# scrisa DUPA ce am deschis ghanta_ghar.png (brief §0.1 pasul 1), de jos in
# sus, asa cum se vede din 3/4 stanga-fata:
#
#   1. Soclu teseit: baza octogonala (colturile taiate), cu o poarta in arc
#      (gol inchis) vizibila pe fata din fata. 1 nivel.
#   2. O a doua banda de soclu, putin mai ingusta, tot cu arcade oarbe joase
#      pe fiecare fata (3 pe fata vizibila pe decupare) -> se citeste ca o
#      cornisa cu nise, nu ca etaj locuibil.
#   3. Fusul patrat: 2 ferestre inalte in arc (goluri VOLCANIC_BLACK), pe
#      FIECARE din cele 4 fete. Colturile fusului sunt usor tesite (fatete),
#      ca pe decupare.
#   4. Brau orizontal ingust, iesit in consola, desparte fusul de etajul
#      ceasului.
#   5. Etajul ceasului: 4 cadrane rotunde, cate UNUL pe fiecare fata (2
#      vizibile pe decupare, din unghiul 3/4) -> disc FOAM_WHITE, ace
#      VOLCANIC_BLACK, FARA cifre (regula 0.8), nod Clock_Glow.
#   6. Balcon pe console: o banda ingusta care iese peste etajul ceasului,
#      cu balustrada joasa (creneluri mici dese) si console vizibile dedesubt.
#   7. Lanterna: cupola mica sustinuta de o colonada de 4 arcade (una pe
#      fiecare fata), stalpi subtiri.
#   8. Cupola cu turla: cupola nervurata (bombata), cu un varf/spira subtire
#      deasupra.
#
# Nimic nu iese din contur lateral (nu are balcoane in afara siluetei) —
# turnul e simetric pe cele 4 fete, cotele 7x7 se pastreaza pe tot fusul.
TW_BASE = 7.0
TW_H = 22.0


def _tower_tier_octagon(b, cz, h, r, slot, chamfer=0.22, punches=None):
    """Un nivel cu colturi tesite: patrat 2r x 2r cu cele 4 colturi taiate,
    ca prisma pe 8 laturi. Foloseste `prism` pe un contur XZ nu se potriveste
    (prism extrudeaza pe Y, aici vrem o sectiune orizontala) -- construim
    direct cu doua inele de varfuri (jos/sus) pe un octogon neregulat.

    `punches`: {side_index: [(lat_center, half_w, z0, z1), ...]} -- pe laturile
    CARDINALE (0=+Y, 2=+X, 4=-Y, 6=-X, in ordinea din `pts`), latura solida
    (un singur quad) se inlocuieste cu un CADRU (stanga/dreapta/sus/jos) in
    jurul fiecarei taieturi, lasand un gol REAL in perete -- nu o cutie
    suprapusa (critica gasita: o cutie "retrasa" suprapusa peste fata plina nu
    se vede niciodata, fiindca fata plina originala ramane deasupra ei si
    acopera golul din exterior; masurat pe un test izolat, fara nicio
    schimbare vizibila)."""
    pts = [
        (r, r - chamfer), (r, -(r - chamfer)), (r - chamfer, -r),
        (-(r - chamfer), -r), (-r, -(r - chamfer)), (-r, r - chamfer),
        (-(r - chamfer), r), (r - chamfer, r),
    ]
    lo = [b.bm.verts.new((x, y, cz)) for x, y in pts]
    hi = [b.bm.verts.new((x, y, cz + h)) for x, y in pts]
    n = len(pts)
    faces = []
    punches = punches or {}
    for i in range(n):
        j = (i + 1) % n
        cuts = punches.get(i)
        if not cuts:
            f = b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
            f[b.slot] = slot
            faces.append(f)
            continue
        # latura cardinala cu taieturi: reconstruim ca fasii (stanga capat ->
        # [rama stanga, gol, rama dreapta, gol, ...] -> dreapta capat), pe axa
        # lui `lat` (proiectia punctului pe segmentul lo[i]->lo[j]).
        p0 = Vector(pts[i]); p1 = Vector(pts[j])
        seg = p1 - p0
        seg_len = seg.length
        seg_dir = seg / seg_len
        cuts_sorted = sorted(cuts, key=lambda c: c[0])
        lat_mid = seg_len * 0.5

        def vert_at(lat, z):
            p = p0 + seg_dir * (lat_mid + lat)
            return b.bm.verts.new((p.x, p.y, z))

        cursor = -lat_mid
        for lat_c, half_w, z0, z1 in cuts_sorted:
            l0, l1 = lat_c - half_w, lat_c + half_w
            if l0 > cursor + 1e-6:
                # rama solida de la cursor la l0, pe toata inaltimea
                a = vert_at(cursor, cz); c1 = vert_at(l0, cz)
                a2 = vert_at(cursor, cz + h); c2 = vert_at(l0, cz + h)
                f = b.bm.faces.new((a, c1, c2, a2)); f[b.slot] = slot
                faces.append(f)
            cursor = l1
        # ultima rama, de la ultimul cursor pana la capatul segmentului
        if cursor < lat_mid - 1e-6:
            a = vert_at(cursor, cz); c1 = vert_at(lat_mid, cz)
            a2 = vert_at(cursor, cz + h); c2 = vert_at(lat_mid, cz + h)
            f = b.bm.faces.new((a, c1, c2, a2)); f[b.slot] = slot
            faces.append(f)
        # benzile de sus/jos ale fiecarui gol (rama orizontala deasupra si
        # dedesubtul taieturii, pe toata latimea ei)
        for lat_c, half_w, z0, z1 in cuts_sorted:
            l0, l1 = lat_c - half_w, lat_c + half_w
            if z0 > cz + 1e-6:
                a = vert_at(l0, cz); c1 = vert_at(l1, cz)
                a2 = vert_at(l0, z0); c2 = vert_at(l1, z0)
                f = b.bm.faces.new((a, c1, c2, a2)); f[b.slot] = slot
                faces.append(f)
            if z1 < cz + h - 1e-6:
                a = vert_at(l0, z1); c1 = vert_at(l1, z1)
                a2 = vert_at(l0, cz + h); c2 = vert_at(l1, cz + h)
                f = b.bm.faces.new((a, c1, c2, a2)); f[b.slot] = slot
                faces.append(f)
    top = b.bm.faces.new(tuple(reversed(hi)))
    top[b.slot] = slot
    bot = b.bm.faces.new(tuple(lo))
    bot[b.slot] = slot
    faces += [top, bot]
    return faces, pts


# REVIZUIRE (critica pe `--compare ghanta_ghar`, prima trecere): silueta
# iesise h/l ~1.4 fata de 2,17 pe decupare (turn prea lat/scund), ferestrele
# fusului erau diagonale (bug de offset "along") in loc de 2 goluri verticale
# PARALELE, arcada soclului 2 era invizibila, balconul si colonada lanternei
# nu se citeau, iar cupola era un con drept, nu bombat. Geometria de mai jos e
# rescrisa dupa acea critica: raza scade in trepte mai mari fata de inaltime
# (turn mai subtire), ferestrele sunt doua cutii verticale distincte (NU
# offset diagonal), arcada e vizibil retrasa+inalta, balconul are o banda
# late + creneluri late, iar lanterna are stalpi GROSI intre arcade vizibile.
def build_ghanta_ghar():
    b = Builder()
    hb = TW_BASE * 0.5
    face_normals = [(0.0, 1.0), (1.0, 0.0), (0.0, -1.0), (-1.0, 0.0)]

    # REVIZUIRE (a doua critica, pe randarea CU tenta reala): ferestrele
    # ieseau ca dungi albe/deschise, nu goluri intunecate. Cauza: `Tower_Stone`
    # primeste la integrare un SINGUR material triplanar (clasa red_sandstone,
    # brief regula 6) -- orice geometrie GLOW ramasa IN bmesh-ul lui `b` e
    # texturata cu ACEEASI gresie, indiferent de slot-ul UV (triplanar ignora
    # UV-ul complet). Deci un gol "colorat prin slot" in `Tower_Stone` nu
    # citeste niciodata ca gol -- devine o dunga de gresie mai deschisa la
    # umbrire. Fix-ul: `Tower_Glow` e SINGURUL loc cu geometrie GLOW; `b`
    # primeste doar un CADRU (tot STONE, aceeasi textura -- se citeste din
    # umbrire/bevel, ca la un jgheab) in jurul locului, iar geamul intunecat
    # traieste RETRAS 0.15 m, doar in `bg`.
    bg = Builder()
    # side index in `_tower_tier_octagon.pts` pentru fiecare normala cardinala
    # (masurat direct pe lista de puncte -- 6=+Y, 0=+X, 2=-Y, 4=-X).
    SIDE_OF = {(0.0, 1.0): 6, (1.0, 0.0): 0, (0.0, -1.0): 2, (-1.0, 0.0): 4}

    def _glass_and_reveal_sides(punches_acc, nx, ny, lat_c, half_w, z0, z1,
                                wall_edge, depth, reveal_slot=STONE):
        """Adauga taietura in `punches_acc` (pentru `_tower_tier_octagon`) SI
        geometria de adancime: 4 pereti STONE ai firidei (stanga/dreapta/
        sus/jos, unind marginea golului din perete cu marginea firidei
        retrase) + placa GLOW la fundul firidei, in `bg`. Fara peretii
        firidei, gaura reala din perete s-ar vedea direct in golul din spate
        (fara umbra de adancime) sau ar lasa un gol intre marginea taieturii
        si geam."""
        side = SIDE_OF[(nx, ny)]
        punches_acc.setdefault(side, []).append((lat_c, half_w, z0, z1))
        along = (-ny, nx)
        half_h = (z1 - z0) * 0.5
        wz = (z0 + z1) * 0.5
        inner = wall_edge - depth

        def pt(lat, depth_t, z):
            r = wall_edge - depth_t
            return (nx * r + along[0] * lat, ny * r + along[1] * lat, z)

        # 4 pereti ai firidei (fasii subtiri STONE, intre marginea exterioara
        # a golului si marginea retrasa) -- stanga, dreapta, sus, jos.
        # ATENTIE la orientare: peretele din STANGA (l0) trebuie sa priveasca
        # spre +along (spre interiorul golului), cel din DREAPTA (l1) spre
        # -along -- ACEEASI ordine de varfuri pentru amandoua da normale
        # opuse (una din doua iese cu fata in interiorul turnului si devine
        # invizibila din exterior -- bug gasit prin inspectia normalelor
        # exportate, nu presupus). Acelasi motiv pentru jos/sus.
        l0, l1 = lat_c - half_w, lat_c + half_w
        for lat_e, flip in ((l0, False), (l1, True)):
            verts = (pt(lat_e, 0.0, z0), pt(lat_e, depth, z0),
                    pt(lat_e, depth, z1), pt(lat_e, 0.0, z1))
            if flip:
                verts = tuple(reversed(verts))
            side_wall = b.bm.faces.new([b.bm.verts.new(v) for v in verts])
            side_wall[b.slot] = reveal_slot
        for z_e, flip in ((z0, False), (z1, True)):
            verts = (pt(l0, 0.0, z_e), pt(l1, 0.0, z_e),
                    pt(l1, depth, z_e), pt(l0, depth, z_e))
            if flip:
                verts = tuple(reversed(verts))
            top_bot = b.bm.faces.new([b.bm.verts.new(v) for v in verts])
            top_bot[b.slot] = reveal_slot
        # placa GLOW la fundul firidei, putin mai ingusta (rama vizibila)
        glass_lat_margin = half_w * 0.18
        glass_c = pt(lat_c, depth - 0.02, wz)
        glass_s = ((2 * (half_w - glass_lat_margin)) if abs(ny) > 0.5 else 0.04,
                   (2 * (half_w - glass_lat_margin)) if abs(nx) > 0.5 else 0.04,
                   2 * half_h * 0.9)
        bg.box(glass_c, glass_s, GLOW)

    def _windows_on_faces(punches_acc, z0, h, half, w_frac=0.16, gap_frac=0.20,
                          h_frac=0.62, faces=face_normals, depth=0.16):
        """2 goluri verticale PARALELE cu fata: fiecare e deplasat doar
        DE-A LUNGUL fetei (`along`), niciodata spre normala -- asa raman
        drepte, nu diagonale."""
        wz0 = z0 + h * (1.0 - h_frac) * 0.5
        wz1 = wz0 + h * h_frac
        for nx, ny in faces:
            off = half * gap_frac
            for s in (-1.0, 1.0):
                half_w = half * w_frac * 0.5
                _glass_and_reveal_sides(punches_acc, nx, ny, s * off, half_w,
                                        wz0, wz1, half, depth)

    # 1. soclu teseit, nivel 1 (0 .. 1.9 m): baza larga, o poarta in arc pe fata
    socle1_h = 1.9
    p1 = {}
    door_z0, door_z1 = 0.06, 1.31
    _glass_and_reveal_sides(p1, 0.0, 1.0, 0.0, 0.7, door_z0, door_z1, hb, 0.3)
    faces1, _ = _tower_tier_octagon(b, 0.0, socle1_h, hb, STONE, chamfer=0.85, punches=p1)

    # 2. a doua banda de soclu (1.9..4.1): mai INGUSTA (pasul de raza conteaza
    # pentru silueta -- decupare: turnul se subtiaza vizibil intre soclu si
    # fus), cu 3 arcade oarbe ADANCI si INALTE pe fata, ca sa se citeasca la
    # unghiul de comparatie.
    socle2_h = 2.2
    hb2 = hb - 0.3   # mai lat decat incercarile anterioare (hb-0.9, hb-0.5):
                    # h/l masurat 2.63 apoi 2.55 fata de 2,17 tinta -- taperul
                    # dintre soclu si fus era inca prea agresiv
    p2 = {}
    niche_z0 = socle1_h + socle2_h * 0.17
    niche_z1 = socle1_h + socle2_h * 0.87
    for fx in (-1.55, 0.0, 1.55):
        _glass_and_reveal_sides(p2, 0.0, 1.0, fx, 0.42, niche_z0, niche_z1, hb2, 0.26)
    faces2, _ = _tower_tier_octagon(b, socle1_h, socle2_h, hb2, STONE, chamfer=0.55, punches=p2)

    # 3. fusul patrat: mult mai INGUST decat soclul (raportul e ce da inaltimea
    # perceputa), 2 ferestre inalte in arc, PARALELE, pe fiecare fata.
    shaft_z0 = socle1_h + socle2_h
    shaft_h = 7.3
    hs = hb2 - 0.25
    p3 = {}
    _windows_on_faces(p3, shaft_z0, shaft_h, hs, w_frac=0.30, gap_frac=0.30,
                      h_frac=0.66, depth=0.22)
    faces3, _ = _tower_tier_octagon(b, shaft_z0, shaft_h, hs, STONE, chamfer=0.32, punches=p3)

    # 4. brau orizontal, iesit in consola
    belt_z = shaft_z0 + shaft_h
    belt_h = 0.45
    faces4, _ = _tower_tier_octagon(b, belt_z, belt_h, hs + 0.30, STONE, chamfer=0.4)

    # 5. etajul ceasului: bloc mai ingust decat fusul, 4 cadrane (unul per fata)
    clock_z0 = belt_z + belt_h
    clock_h = 2.3
    hc = hs - 0.45
    faces5, _ = _tower_tier_octagon(b, clock_z0, clock_h, hc, STONE, chamfer=0.3)
    tower_stone_faces = faces1 + faces2 + faces3 + faces4 + faces5

    # cadrane: disc FOAM_WHITE + ace VOLCANIC_BLACK, in nod Clock_Glow
    bc = Builder()
    clock_r = 0.85
    clock_cz = clock_z0 + clock_h * 0.55
    for nx, ny in face_normals:
        cx = nx * (hc + 0.02)
        cy = ny * (hc + 0.02)
        axis = "X" if abs(nx) > 0.5 else "Y"
        bc.cylinder((cx, cy, clock_cz), clock_r, 0.08, WALL, segments=16, axis=axis)
        hand_c = (cx + nx * 0.09, cy + ny * 0.09, clock_cz)
        if abs(nx) > 0.5:
            bc.box(hand_c, (0.03, clock_r * 0.55, 0.12), GLOW)
            bc.box((hand_c[0], hand_c[1] + clock_r * 0.16, hand_c[2] + clock_r * 0.10),
                  (0.03, clock_r * 0.30, 0.12), GLOW)
        else:
            bc.box(hand_c, (clock_r * 0.55, 0.03, 0.12), GLOW)
            bc.box((hand_c[0] + clock_r * 0.16, hand_c[1], hand_c[2] + clock_r * 0.10),
                  (clock_r * 0.30, 0.03, 0.12), GLOW)

    # 6. balcon pe console: banda LATA iesita, parapet plin + creneluri LATE
    #    si vizibile (critica: primele creneluri erau prea mici ca sa se
    #    citeasca la distanta de comparatie)
    balc_z0 = clock_z0 + clock_h
    balc_h = 0.22
    faces6, _ = _tower_tier_octagon(b, balc_z0, balc_h, hc + 0.55, STONE, chamfer=0.42)
    rail_z0 = balc_z0 + balc_h
    rail_h = 0.62
    rail_r = hc + 0.34
    faces6b, _ = _tower_tier_octagon(b, rail_z0, rail_h * 0.45, rail_r, STONE, chamfer=0.4)
    tower_stone_faces += faces6 + faces6b
    # creneluri: dinti LATI (segments=12), alternand solid/gol pe un inel
    n_crenel = 12
    for i in range(n_crenel):
        a = 2.0 * math.pi * (i + 0.5) / n_crenel
        gx = math.cos(a) * rail_r
        gy = math.sin(a) * rail_r
        if i % 2 == 0:
            merlon = list(b.box((gx, gy, rail_z0 + rail_h * 0.72), (0.42, 0.42, rail_h * 0.5),
                                STONE))
            tower_stone_faces += merlon
    # console sub balcon: cutii triunghiulare vizibile, cate 2 pe fata
    for nx, ny in face_normals:
        along = (-ny, nx)
        for s in (-1.0, 1.0):
            cx = nx * hc * 0.85 + along[0] * s * hc * 0.5
            cy = ny * hc * 0.85 + along[1] * s * hc * 0.5
            console = list(b.box((cx, cy, balc_z0 - 0.14), (0.35, 0.35, 0.28), STONE))
            tower_stone_faces += console

    # 7. lanterna: colonada DESCHISA -- 4 stalpi GROSI (nu subtiri) la colturi
    #    plus 4 la mijlocul fiecarei fete, sustinand un arhitrav continuu, cu
    #    golul intre stalpi ca arcada vizibila (nu un cilindru plin cu gauri).
    lant_z0 = rail_z0 + rail_h
    lant_r = hc - 0.15
    lant_h = 1.75
    col_r = 0.22
    lant_positions = []
    for a_deg in range(0, 360, 45):
        a = math.radians(a_deg)
        lant_positions.append((math.cos(a) * lant_r, math.sin(a) * lant_r))
    for px, py in lant_positions:
        col = list(b.cylinder((px, py, lant_z0 + lant_h * 0.5), col_r, lant_h,
                              STONE, segments=8, axis="Z"))
        tower_stone_faces += col
    # soclu jos al lanternei (parapet mic intre stalpi, sub arcada) + arhitrav sus.
    # Intre ele NU se pune niciun cilindru plin: arcada e golul REAL dintre
    # coloane (colonada deschisa, brief "lanterna cu 4 arcade"), nu o gaura
    # colorata intr-un tambur solid -- acelasi motiv ca la ferestrele fusului
    # (Tower_Stone are un singur material la integrare, deci un slot GLOW
    # ramas in `b` nu s-ar citi niciodata ca gol).
    lant_base = list(b.cylinder((0.0, 0.0, lant_z0 + 0.18), lant_r + col_r, 0.36,
                                STONE, segments=16, axis="Z"))
    lant_top = list(b.cylinder((0.0, 0.0, lant_z0 + lant_h - 0.14), lant_r + col_r * 1.4,
                               0.28, STONE, segments=16, axis="Z"))
    tower_stone_faces += lant_base + lant_top
    # placa de fundal GLOW, in spatele colonadei (in `bg`, nu in `b`): fara ea,
    # cerul s-ar vedea prin arcada la randare -- pe piesa reala tavanul/nucleul
    # lanternei e mai inchis, nu transparent.
    for nx, ny in face_normals:
        bg.box((nx * lant_r * 0.35, ny * lant_r * 0.35,
               lant_z0 + 0.36 + (lant_h - 0.64) * 0.5),
              (0.7 if abs(ny) > 0.5 else 0.45, 0.45 if abs(ny) > 0.5 else 0.7,
               lant_h - 0.64), GLOW)

    # 8. cupola bombata cu turla: profil in 3 trepte (evazat -> bombat ->
    #    varf), mai lat decat lanterna (critica: prima versiune era un con
    #    drept, mai ingust decat lanterna -- citea ca o palnie, nu cupola).
    dome_z0 = lant_z0 + lant_h
    dome_r0 = lant_r + col_r * 1.6
    dome_r1 = dome_r0 * 1.08   # bombare: iese usor peste raza lanternei
    d0 = list(b.frustum((0.0, 0.0, dome_z0 + 0.14), dome_r0, dome_r1, 0.28,
                        STONE, segments=16, axis="Z"))
    d1 = list(b.frustum((0.0, 0.0, dome_z0 + 0.28 + 0.42), dome_r1, dome_r0 * 0.42, 0.84,
                        STONE, segments=16, axis="Z"))
    d2 = list(b.frustum((0.0, 0.0, dome_z0 + 0.28 + 0.84 + 0.35), dome_r0 * 0.42, 0.04, 0.7,
                        STONE, segments=16, axis="Z"))
    tower_stone_faces += d0 + d1 + d2
    spire = list(b.cylinder((0.0, 0.0, dome_z0 + 0.28 + 0.84 + 0.7 + 0.4), 0.045, 0.8,
                            STONE, segments=6, axis="Z"))
    tower_stone_faces += spire

    stone_obj = b.to_object("Tower_Stone")
    clock_obj = bc.to_object("Clock_Glow")
    # Tower_Glow: `bg` s-a umplut incremental in `_reveal`/lanterna, mai sus --
    # SINGURUL loc cu geometrie GLOW (brief regula 6/7): `Tower_Stone` are
    # firide STONE (geometrie, se citesc din AO/umbra), niciodata slot GLOW.
    glow_obj = bg.to_object("Tower_Glow")

    return stone_obj, clock_obj, glow_obj


# --- blue_house_a --------------------------------------------------------------
#
# Contract (brief §1.1): 6x6 m, 2 etaje, 6,5 m pana la parapet, h/l 0,95.
# Lista de elemente dupa deschiderea blue_house_a.png (brief §0.1 pasul 1):
#
#   1. Corp cubic (6x6, 2 etaje) cu parapet plat sus (nu acoperis in panta).
#   2. Usa in arc pe fata din fata-stanga (+Y/-X dupa unghiul de randare),
#      WOOD, cu un soclu/prag usor iesit dedesubt.
#   3. Doua ferestre cu obloane pe fata LATERALA (nu vizibile pe decupare
#      din acest unghi, dar cerute in brief) -- goluri inchise VOLCANIC_BLACK.
#   4. Scara exterioara pe latura DREAPTA, care urca in zigzag spre TERASA
#      din SPATE, cu balustrada alba (zigzag vizibil, trepte + rampe).
#   5. Cutie mica pe acoperis (casa scarii / camera), retrasa spre stanga-spate
#      pe decupare, un singur volum simplu cu parapet propriu.
# Nimic altceva nu iese din contur (fara rezervor vizibil in aceasta decupare).
HA_SIDE = 6.0
HA_WALL = 6.5


def build_blue_house_a():
    # REVIZUIRE (critica pe randarea CU tenta): h/l masurat 1,16 fata de 0,95
    # tinta (+22%) -- cutia de pe acoperis (2,6 x 2,4 x 1,9) se aduna la
    # inaltimea totala perceputa si ingusteaza raportul. Corpul principal e
    # cota de contract (6x6, 6,5 pana la parapet, brief §1.1), deci NU se
    # schimba -- se micsoreaza doar cutia de pe acoperis (mai joasa, mai
    # ingusta), ca pe decupare unde citeste ca o camera mica de scara, nu
    # un al doilea etaj.
    h_wall = 6.0            # pereti pana la ultimul planseu
    parapet_h = HA_WALL - h_wall
    hs = HA_SIDE * 0.5

    b = Builder()
    # 1. corp cubic plin
    walls = list(b.box((0.0, 0.0, h_wall * 0.5), (HA_SIDE, HA_SIDE, h_wall), WALL))
    # soclu usor iesit la baza (banda subtire, ca pe decupare)
    plinth = list(b.box((0.0, 0.0, 0.18), (HA_SIDE + 0.18, HA_SIDE + 0.18, 0.36), WALL))
    # parapet: banda subtire pe margine (gol la mijloc -- aici solid, simplu,
    # citeste ca parapet plin, cum e pe decupare)
    parapet_faces = list(b.box((0.0, 0.0, h_wall + parapet_h * 0.5),
                               (HA_SIDE, HA_SIDE, parapet_h), WALL))
    wall_faces = walls + plinth + parapet_faces

    # cutia mica pe acoperis: retrasa spre stanga-spate (-X, -Y in reperul
    # frontal, adica spre fata opusa intrarii)
    box_w, box_d, box_h = 2.2, 2.0, 1.4
    box_c = (-0.3, -0.4, HA_WALL + box_h * 0.5)
    roof_box = list(b.box(box_c, (box_w, box_d, box_h), WALL))
    wall_faces += roof_box
    # parapet propriu, subtire, pe cutia de pe acoperis
    roof_parapet = list(b.box((box_c[0], box_c[1], HA_WALL + box_h + 0.08),
                              (box_w, box_d, 0.16), WALL))
    wall_faces += roof_parapet

    wall_obj = b.to_object("House_Wall")

    # --- House_Trim: usa in arc + obloane + balustrada scarii ---------------
    bt = Builder()
    trim_faces = []
    # usa in arc pe fata din fata (+Y): un cadru dreptunghi cu varf rotunjit
    # aproximat printr-o cutie cu fateta de sus taiata (colt tesit simplu)
    door_w, door_h = 1.3, 2.4
    door_c = (-hs * 0.35, hs - 0.02, door_h * 0.5)
    trim_faces += list(bt.box(door_c, (door_w, 0.12, door_h), TRIM_WOOD))
    # varful in arc: o cutie mica ingusta deasupra, tesita (aproximeaza arcul)
    trim_faces += list(bt.box((door_c[0], door_c[1], door_h + 0.22),
                              (door_w * 0.7, 0.12, 0.44), TRIM_WOOD))

    # 2 ferestre cu obloane pe fata laterala (+X): obloanele WOOD, dechise
    # (aripioare usor iesite in lateral)
    win_z = h_wall * 0.58
    for wy in (-1.6, 1.2):
        shutter_l = list(bt.box((hs - 0.03, wy - 0.55, win_z), (0.08, 0.10, 1.1), TRIM_WOOD))
        shutter_r = list(bt.box((hs - 0.03, wy + 0.55, win_z), (0.08, 0.10, 1.1), TRIM_WOOD))
        trim_faces += shutter_l + shutter_r

    trim_obj = bt.to_object("House_Trim")

    # --- balustrada scarii: nod SEPARAT de perete (FOAM_WHITE fara tenta) ---
    br = Builder()
    rail_faces = []
    # scara pe latura DREAPTA (+X), urcand spre SPATE (-Y): 3 rampe in zigzag
    # (parter -> podest -> etaj 1 -> terasa), fiecare cu balustrada joasa.
    n_flights = 3
    flight_len = HA_SIDE * 0.85
    step_w = 1.0
    x_stair = hs + step_w * 0.5 + 0.05
    z0 = 0.0
    y0 = hs - 0.3
    dirs = [-1.0, 1.0, -1.0]  # zigzag: spre -Y, apoi +Y, apoi -Y (spre spate)
    for i in range(n_flights):
        z1 = z0 + HA_WALL / n_flights
        y1 = y0 + dirs[i] * flight_len / n_flights
        n_steps = 5
        for k in range(n_steps):
            t0 = k / n_steps
            t1 = (k + 1) / n_steps
            sy = y0 + (y1 - y0) * (t0 + t1) * 0.5
            sz = z0 + (z1 - z0) * (t0 + 0.5) / n_steps
            step = list(br.box((x_stair, sy, sz), (step_w, abs(y1 - y0) / n_steps * 0.95,
                                                    0.12), RAIL_WHITE))
            rail_faces += step
        # balustrada: doua bare orizontale de-a lungul rampei + stalpi la capete
        mid_y = (y0 + y1) * 0.5
        mid_z = (z0 + z1) * 0.5
        rail_len = abs(y1 - y0)
        top_rail = list(br.beam((x_stair + step_w * 0.5, y0, z0 + 0.9),
                                (x_stair + step_w * 0.5, y1, z1 + 0.9), 0.04, RAIL_WHITE))
        rail_faces += top_rail
        for post_t in (0.0, 0.5, 1.0):
            py = y0 + (y1 - y0) * post_t
            pz = z0 + (z1 - z0) * post_t
            post = list(br.beam((x_stair + step_w * 0.5, py, pz),
                                (x_stair + step_w * 0.5, py, pz + 0.9), 0.035, RAIL_WHITE))
            rail_faces += post
        y0, z0 = y1, z1
    rail_obj = br.to_object("House_Trim2")  # se combina cu trim mai jos

    return wall_obj, trim_obj, rail_obj


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Ca `emit` din build_fiordland_village.py: offsetul de origine se
    calculeaza O DATA pe ansamblu si se aplica identic tuturor nodurilor
    (brief regula 6), cu `finish(origin=None)` pe fiecare in parte."""
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
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


tower_stone, tower_clock, tower_glow = build_ghanta_ghar()
emit([tower_stone, tower_clock, tower_glow], "buildings/ghanta_ghar.glb",
     AO_TOWER, bevel=0.03, budget=5200)

house_wall, house_trim, house_rail = build_blue_house_a()
# House_Trim2 (balustrada) se topeste in House_Trim la export: acelasi
# material (WOOD pentru usa/obloane e diferit de FOAM_WHITE al balustradei,
# deci raman noduri separate: House_Wall, House_Trim, House_Rail). Brief-ul
# cere House_Wall/House_Trim/House_Glow -- balustrada e geometrie FOAM_WHITE
# fara tenta (regula: "nod separat de perete"), deci intra tot in House_Trim
# ca material distinct nu se poate (House_Trim e deja WOOD). O redenumim
# House_Glow2 nu are sens -- corect e un al 4-lea nod, House_Rail, in plus
# fata de cele 3 din brief (House_Wall/House_Trim/House_Glow), fiindca
# geometria lui e alt slot (FOAM_WHITE) decat usa/obloanele (WOOD).
house_rail.name = "House_Rail"
emit([house_wall, house_trim, house_rail], "buildings/blue_house_a.glb",
     AO_HOUSE, bevel=0.025, budget=1800)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL pilot: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([tower_stone, tower_clock, tower_glow, house_wall, house_trim, house_rail],
           "jodhpur_pilot.blend")
