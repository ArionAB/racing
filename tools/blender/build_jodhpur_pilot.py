"""Jodhpur -- Pilotul, v2 (brief §1.1, val 1 din docs/asset_briefs/jodhpur_kit.md).

  jodhpur/buildings/ghanta_ghar.glb    turnul cu ceas (reperul lui H.)
  jodhpur/buildings/blue_house_a.glb   casa albastra simpla, cu scara

**REVIZUIRE v2:** v1 (commit c5dfeaa5) a fost RESPINSA pe fidelitate
(jodhpur_fidelity_val1.png) -- fante dreptunghiulare in loc de arcade, fara
balustrade, acoperis piramidal in loc de cupola pe turn; trepte plutitoare in
loc de masa solida la casa. Cauza: nu exista vocabular pentru forme
indo-saracenice. Rescris complet cu `jodhpur_shapes.py` (TASK A a acestei
instante): arch_opening, dome, chhatri, balustrade, chajja, crenellation,
solid_stair. Listele de elemente de mai jos s-au rescris DUPA ce am deschis
din nou (Read) ghanta_ghar.png si blue_house_a.png -- brief §0.1 pasul 1.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_pilot.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

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


def _finish_or_none(obj):
    """Un Builder GLOW poate ramane gol (arcade/chhatri fara geam nu scrie
    nimic in `bg`) -- daca n-are varfuri, il stergem in loc sa-l trimitem la
    `finish` (care crapa pe bbox gol la set_origin_base, vezi
    jodhpur_shapes_sheet -- acelasi bug, alt loc)."""
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


# --- ghanta_ghar -------------------------------------------------------------
#
# Contract (brief §1.1): 22 m inalt, baza 7x7 m, h/l 2,17. Lista de elemente
# scrisa DUPA ce am redeschis ghanta_ghar.png (brief §0.1 pasul 1), de jos in
# sus, cum se vede din 3/4 stanga-fata (planul H., turnul din Jodhpur):
#
#   1. Soclu in trepte (stepped_plinth): 2-3 nivele care se ingusteaza, cel
#      mai de jos cel mai lat.
#   2. Primul tier, cu UN gol mare in arc pe fiecare fata (arch_opening,
#      stil "pointed"), vizibil pe fata din fata ca poarta intunecata mare.
#   3. Al doilea tier (banda de cornisa): mai ingust, cu 3 nise oarbe in arc
#      pe fata vizibila (arcade in relief, fara geam -- `arch_opening` cu
#      reveal mic).
#   4. Fusul patrat: 2 ferestre inalte in arc pe FIECARE fata (arch_opening,
#      geam VOLCANIC_BLACK retras).
#   5. Etajul ceasului: 4 cadrane rotunde (unul per fata), disc FOAM_WHITE,
#      ace VOLCANIC_BLACK, FARA cifre.
#   6. Balcon pe console, cu balustrada/creneluri mici dese (balcony_band
#      crenellated=True), console vizibile dedesubt (railing_on_brackets/
#      console proprii).
#   7. Chhatri (pavilion deschis): colonada de arcade PE STALPI DESCHISI
#      (nu cilindru plin cu gauri), cu chajja proeminenta deasupra arcelor.
#   8. Cupola nervurata (ribbed dome, profil "onion") cu finial (kalash)
#      deasupra.
#
# Nimic nu iese lateral din contur (turnul e simetric pe cele 4 fete).
TW_BASE = 7.0
TW_H = 22.0


def build_ghanta_ghar():
    b = Builder()
    bg = Builder()
    hb = TW_BASE * 0.5

    z = 0.0

    # 1. soclu in trepte: 3 nivele, cel de jos cel mai lat -- inaltimea
    # totala a soclului e bugetata explicit ca sa lase loc restului turnului
    # pana la 22 m.
    plinth_levels = [(TW_BASE, TW_BASE, 0.55), (TW_BASE - 0.5, TW_BASE - 0.5, 0.45),
                     (TW_BASE - 0.9, TW_BASE - 0.9, 0.35)]
    stone_faces = list(stepped_plinth(b, (0.0, 0.0, z), plinth_levels, STONE))
    for w, d, h in plinth_levels:
        z += h
    plinth_top_hw = (TW_BASE - 0.9) * 0.5

    # IMPORTANT: niciun tier de mai jos nu mai pune o cutie PLINA pe toata
    # fata inainte de arch_opening -- critica pe prima randare a acestui val
    # a aratat exact bug-ul documentat in capul lui `arch_opening`: o cutie
    # plina si panoul perforat ocupand acelasi spatiu z-fighteaza (fetele se
    # amesteca la randare, arata ca cioburi/fulgere in loc de arc curat).
    # `arch_opening` isi construieste SINGUR panoul complet al fetei (are
    # `panel_w`/`panel_h`) -- e singura sursa de perete pe fetele cu goluri.
    # Un miez de cutie mic (mai ingust decat fetele) ramane doar pentru
    # colturile dintre fete si pentru masa care leaga tavanul/podeaua
    # tier-ului, INSA retras cu grosimea peretelui, ca sa nu coplaneze cu
    # panourile.
    face_normals = [(0.0, 1.0), (1.0, 0.0), (0.0, -1.0), (-1.0, 0.0)]

    def _tier_core(hw, h, zc, inset):
        """Miezul de colt: o cutie mai INGUSTA (retrasa cu `inset` fata de
        `hw`), care umple doar interiorul tier-ului -- panourile perforate
        (construite separat, per fata) acopera exteriorul si se lipesc de
        acest miez fara sa-l suprapuna."""
        core_hw = hw - inset
        return list(b.box((0.0, 0.0, zc + h * 0.5), (core_hw * 2, core_hw * 2, h), STONE))

    # 2. primul tier: gol mare in arc pe fiecare fata (4 fete -- brief cere
    # "vizibil pe fata din fata", dar simetria pe 4 fete e mai robusta la
    # orice unghi de joc, ca la fus/cadrane)
    tier1_h = 2.3
    tier1_hw = plinth_top_hw - 0.05
    tier1_wall_t = 0.35
    stone_faces += _tier_core(tier1_hw, tier1_h, z, tier1_wall_t)
    # centrul panoului se retrage cu wall_t/2 fata de `tier1_hw`, ca fata lui
    # DIN SPATE (la -wall_t/2 fata de centru) sa cada EXACT pe fata
    # exterioara a miezului (la tier1_hw - tier1_wall_t) -- fara gol, fara
    # suprapunere.
    panel_r1 = tier1_hw - tier1_wall_t * 0.5
    for nx, ny in face_normals:
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        res = arch_opening(b, bg, (nx * panel_r1, ny * panel_r1, z), 1.9, tier1_h * 0.88,
                           tier1_h * 0.30, tier1_wall_t, STONE, GLOW, style="pointed",
                           rotation=rot, glass=True, reveal=0.16,
                           panel_w=tier1_hw * 2, panel_h=tier1_h)
        stone_faces += res["stone"]
    z += tier1_h

    # 3. a doua banda de soclu: mai INGUSTA, cu 3 nise oarbe in arc pe
    # fiecare fata (glass=True cu reveal mic -- se citesc ca firide oarbe,
    # nu ca ferestre adanci)
    tier2_h = 1.9
    tier2_hw = tier1_hw - 0.35
    tier2_wall_t = 0.30
    stone_faces += _tier_core(tier2_hw, tier2_h, z, tier2_wall_t)
    panel_r2 = tier2_hw - tier2_wall_t * 0.5
    for nx, ny in face_normals:
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        along_x, along_y = -ny, nx
        bay = tier2_hw * 2 / 3.0
        panel_frac = 0.92   # REVIZUIRE: panourile ADIACENTE la latime plina
        # (bay) se atingeau muchie-la-muchie -- bevel-ul crea cusaturi de
        # z-fight (cioburi in randare). Panoul e strict mai ingust decat
        # celula lui (`bay`); golul dintre panouri se umple cu un PILASTRU
        # subtire, plin -- citeste ca mullion intre nise, nu ca defect.
        for k in (-1, 0, 1):
            cx = nx * panel_r2 + along_x * (k * bay)
            cy = ny * panel_r2 + along_y * (k * bay)
            res = arch_opening(b, bg, (cx, cy, z), bay * 0.62, tier2_h * 0.72,
                               tier2_h * 0.22, tier2_wall_t, STONE, GLOW, style="pointed",
                               rotation=rot, glass=True, reveal=0.10,
                               panel_w=bay * panel_frac, panel_h=tier2_h)
            stone_faces += res["stone"]
        # pilastri de umplutura, intre celule (la k=-0.5 si k=+0.5) -- cutie
        # ROTITA cu `rot` (aceeasi orientare ca panourile), ca latimea ei sa
        # cada de-a lungul `along`, nu pe X/Y globale (evita conditiile pe
        # semnul lui nx/ny, care erau fragile).
        pier_w = bay * (1.0 - panel_frac) + 0.06
        for k in (-0.5, 0.5):
            cx = nx * panel_r2 + along_x * (k * bay)
            cy = ny * panel_r2 + along_y * (k * bay)
            stone_faces += list(b.box((cx, cy, z + tier2_h * 0.5),
                                      (pier_w, tier2_wall_t, tier2_h), STONE,
                                      rotation=rot))
    z += tier2_h

    # 4. fusul patrat: mai INGUST decat soclul (raportul da inaltimea
    # perceputa), 2 ferestre inalte in arc pe fiecare fata
    shaft_h = 7.2
    shaft_hw = tier2_hw - 0.55
    shaft_wall_t = 0.30
    stone_faces += _tier_core(shaft_hw, shaft_h, z, shaft_wall_t)
    panel_r4 = shaft_hw - shaft_wall_t * 0.5
    for nx, ny in face_normals:
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        along_x, along_y = -ny, nx
        # 2 ferestre pe fiecare fata, IN 2 CELULE EGALE fara suprapunere
        # (bug gasit la prima randare: panourile de 0.95*bay cu bay =
        # shaft_hw se suprapuneau in mijlocul fetei, z-fight -> cioburi) --
        # fiecare celula are latimea shaft_hw (jumatate din fata), panoul ei
        # e strict mai ingust decat celula.
        cell = shaft_hw
        panel_frac4 = 0.92
        for s in (-1.0, 1.0):
            off = cell * 0.5
            cx = nx * panel_r4 + along_x * s * off
            cy = ny * panel_r4 + along_y * s * off
            res = arch_opening(b, bg, (cx, cy, z + shaft_h * 0.08), shaft_hw * 0.42,
                               shaft_h * 0.68, shaft_h * 0.40, shaft_wall_t, STONE, GLOW,
                               style="pointed", rotation=rot, glass=True, reveal=0.14,
                               panel_w=cell * panel_frac4, panel_h=shaft_h * 0.78)
            stone_faces += res["stone"]
        # pilastru central intre cele 2 celule -- umple golul de la panourile
        # mai inguste decat celula (acelasi motiv ca la tier2: evita cusatura
        # de bevel intre panouri adiacente lipite muchie-la-muchie)
        pier_w4 = cell * (1.0 - panel_frac4) + 0.06
        stone_faces += list(b.box((nx * panel_r4, ny * panel_r4, z + shaft_h * 0.5),
                                  (pier_w4, shaft_wall_t, shaft_h), STONE, rotation=rot))
    z += shaft_h

    # brau orizontal, iesit in consola, intre fus si etajul ceasului -- banda
    # circulara (aproximeaza cornisa pe tot perimetrul patrat), nu `chajja`
    # (aia e o singura fatada, ar acoperi doar o latura)
    belt_h = 0.35
    stone_faces += list(balcony_band(b, (0.0, 0.0, z), shaft_hw + 0.1,
                                     shaft_hw + 0.55, belt_h, STONE, segments=16))
    z += belt_h

    # 5. etajul ceasului: bloc mai ingust decat fusul, 4 cadrane (unul per
    # fata), disc + ace in Clock_Glow
    clock_h = 2.2
    clock_hw = shaft_hw - 0.35
    stone_faces += list(b.box((0.0, 0.0, z + clock_h * 0.5),
                              (clock_hw * 2, clock_hw * 2, clock_h), STONE))
    bc = Builder()
    clock_r = 0.82
    clock_cz = z + clock_h * 0.55
    for nx, ny in face_normals:
        cx = nx * (clock_hw + 0.02)
        cy = ny * (clock_hw + 0.02)
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
    z += clock_h

    # 6. balcon pe console: banda crenelata iesita in consola + console
    # triunghiulare vizibile dedesubt
    balc_r = clock_hw * 1.02
    stone_faces += list(balcony_band(b, (0.0, 0.0, z), balc_r, balc_r + 0.55, 0.22, STONE,
                                     segments=16, crenellated=True, merlon_count=16,
                                     merlon_h=0.30))
    for nx, ny in face_normals:
        along = (-ny, nx)
        for s in (-1.0, 1.0):
            cx = nx * clock_hw * 0.9 + along[0] * s * clock_hw * 0.55
            cy = ny * clock_hw * 0.9 + along[1] * s * clock_hw * 0.55
            stone_faces += list(b.box((cx, cy, z - 0.12), (0.32, 0.32, 0.24), STONE))
    z += 0.55  # inaltimea balconului + crenelurilor pana la lanterna

    # 7. chhatri: pavilion deschis cu 8 coloane, arce cusped, chajja, cupola
    # mica + finial propriu (mic, doar decorativ -- cupola PRINCIPALA a
    # turnului e pasul 8, mai mare, deasupra chhatri-ului)
    lant_r = clock_hw - 0.20
    lant_col_h = 1.65
    res = chhatri(b, bg, (0.0, 0.0, z), 8, lant_r, lant_col_h, STONE, GLOW,
                 col_r=0.16, dome_radius=lant_r * 0.55, arch_style="cusped",
                 chajja_out=0.32, segments_dome=12)
    stone_faces += res["stone"]
    z += lant_col_h + 0.35  # pana deasupra chajja-ului chhatri-ului

    # 8. cupola PRINCIPALA, nervurata, cu finial -- inaltimea ramasa pana la
    # 22 m se aloca aici (kalash-ul e varful turnului).
    #
    # REVIZUIRE: `dome()` nu consuma exact `remaining` -- profilul "onion"
    # (varf la radius*1.08 peste baza), inelul lotus (+0.12) si tamburul
    # (`drum_h*0.6`) impreuna dau mai putin decat suma bugetata, iar turnul
    # iesea 21.29 m masurat vs 22.0 m contract (-3,2%). Marind factorul aici
    # la 1.06 a adus doar 21.41 m (-2,7%) -- cupola satureaza (nervurile si
    # tamburul cresc sublinear cu `finial_h`), deci diferenta ramasa e
    # documentata onest in inventar, nu ascunsa printr-un factor tot mai mare
    # fara sa inteleg formula exacta.
    remaining = (TW_H - z) * 1.06
    dome_r = lant_r * 0.85
    finial_h = remaining * 0.42
    drum_h = max(remaining * 0.12, 0.3)
    stone_faces += dome(b, (0.0, 0.0, z), dome_r, STONE, drum_h=drum_h * 0.6,
                        profile="onion", segments=16, ribs=12, lotus_ring=True,
                        finial=True, finial_h=finial_h)

    stone_obj = b.to_object("Tower_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = STONE
    # cadrane -> Clock_Glow
    clock_obj = bc.to_object("Clock_Glow")
    glow_obj = _finish_or_none(bg.to_object("Tower_Glow"))

    return stone_obj, clock_obj, glow_obj


# --- blue_house_a --------------------------------------------------------------
#
# Contract (brief §1.1): 6x6 m, 2 etaje, 6,5 m pana la parapet, h/l 0,95.
# Lista de elemente dupa RE-deschiderea blue_house_a.png (brief §0.1 pasul 1):
#
#   1. Corp cubic (6x6, 2 etaje) cu parapet plat sus, cu CORNISA proeminenta
#      (chajja) la marginea de sus -- iese vizibil peste perete, cu umbra.
#   2. Usa in arc pe fata din fata-stanga (+Y local), WOOD, cu prag usor
#      iesit dedesubt.
#   3. Doua ferestre cu obloane pe fata LATERALA (+X) -- goluri inchise.
#   4. Scara exterioara SOLIDA pe latura DREAPTA (+X), care urca in trepte
#      pline (nu treptele plutitoare din v1) spre TERASA din spate, cu
#      balustrada alba pe console.
#   5. Cutie mica pe acoperis (casa scarii), retrasa spre stanga-spate, cu
#      parapet propriu.
HA_SIDE = 6.0
HA_WALL = 6.5


def build_blue_house_a():
    h_wall = 6.0            # pereti pana la ultimul planseu
    parapet_h = HA_WALL - h_wall
    hs = HA_SIDE * 0.5

    b = Builder()
    bg = Builder()
    wall_faces = []
    WALL_T = 0.5   # grosimea peretilor cu goluri (usa/ferestre) -- vezi nota de mai jos

    # 1. corp cubic: miezul e RETRAS cu WALL_T pe fetele +Y (usa) si +X
    # (ferestre) fata de HA_SIDE, ca panourile `arch_opening` de mai jos sa
    # se lipeasca flush de miez, nu sa-l suprapuna (acelasi bug/fix ca la
    # ghanta_ghar: o cutie plina si un panou perforat in acelasi loc
    # z-fighteaza). Pe fetele FARA gol (-Y, -X), miezul ramane plin pana la
    # HA_SIDE -- acolo nu exista panou separat.
    core_hw = hs - WALL_T * 0.5   # doar pe +Y/+X conteaza; cutia ramane simetrica
    # cutia miez, usor mai ingusta pe toate laturile decat HA_SIDE -- restul
    # de perete (pe fetele -Y/-X, fara goluri) se inchide cu placi late mai
    # jos, ca sa nu ramana gol vizibil intre miez si exterior.
    wall_faces += list(b.box((0.0, 0.0, h_wall * 0.5), (core_hw * 2, core_hw * 2, h_wall), WALL))
    # placi late pe -Y si -X (fara goluri), care aduc peretele inapoi la
    # HA_SIDE -- fiecare placa umple exact banda dintre miez si exterior.
    band = hs - core_hw
    wall_faces += list(b.box((0.0, -(hs - band * 0.5), h_wall * 0.5),
                             (core_hw * 2, band, h_wall), WALL))
    wall_faces += list(b.box((-(hs - band * 0.5), 0.0, h_wall * 0.5),
                             (band, HA_SIDE, h_wall), WALL))
    wall_faces += list(b.box((0.0, 0.0, 0.18), (HA_SIDE + 0.18, HA_SIDE + 0.18, 0.36), WALL))
    wall_faces += list(b.box((0.0, 0.0, h_wall + parapet_h * 0.5),
                             (HA_SIDE, HA_SIDE, parapet_h), WALL))
    # cornisa (chajja) proeminenta la marginea de sus a parapetului -- pe
    # cele 4 laturi, ca sa citeasca din orice unghi
    cornice_z = h_wall + parapet_h
    for nx, ny, w, d in ((0, 1, HA_SIDE + 0.6, 0.5), (0, -1, HA_SIDE + 0.6, 0.5),
                        (1, 0, HA_SIDE + 0.6, 0.5), (-1, 0, HA_SIDE + 0.6, 0.5)):
        ang = math.atan2(-nx, ny)
        cx, cy = nx * hs, ny * hs
        rot = Matrix.Rotation(ang, 3, "Z")
        wall_faces += list(chajja(b, (cx, cy, cornice_z), w, d, WALL,
                                  thickness=0.12, slope=0.45, rotation=rot))

    # usa in arc, pe fata din fata (+Y): gol real, WOOD in firida (usa
    # foloseste `arch_opening` cu slot WALL pentru rama de piatra, dar
    # placa "geamului" e de fapt UȘA -- WOOD, nu GLOW -- deci apelam
    # direct fara sa trecem prin glow_slot standard)
    door_w, door_h = 1.3, 2.3
    res_door = arch_opening(b, bg, (0.0, hs, 0.0), door_w, door_h,
                            door_h * 0.55, WALL_T, WALL, TRIM_WOOD, style="round",
                            rotation=None, glass=True, reveal=0.10, glass_depth=0.08,
                            panel_w=2.6, panel_h=door_h * 1.5)
    wall_faces += res_door["stone"]
    # placa usii insasi intra in bg (foloseste GLOW-slotul ca sa stea in
    # firida), dar trebuie WOOD nu VOLCANIC_BLACK: rescriem slotul fetelor
    # abia create, in Builder-ul `bg`.
    for f in res_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD

    # 2 ferestre cu obloane pe fata laterala (+X): goluri inchise (GLOW),
    # cu obloane WOOD suprapuse (geometrie mica, nu afecteaza citirea de
    # gol -- obloanele stau LANGA gol, nu peste el)
    win_z = h_wall * 0.58
    for wy in (-1.6, 1.2):
        rot = Matrix.Rotation(math.radians(90.0), 3, "Z")
        res_w = arch_opening(b, bg, (hs, wy, win_z - h_wall * 0.5), 0.75, 1.15,
                             0.35, WALL_T, WALL, GLOW, style="round", rotation=rot,
                             glass=True, reveal=0.10, panel_w=1.6, panel_h=1.7,
                             panel_z0=-0.4)
        wall_faces += res_w["stone"]
        shutter_x = hs + WALL_T * 0.5 + 0.03
        shutter_l = list(b.box((shutter_x, wy - 0.55, win_z), (0.08, 0.10, 1.1), TRIM_WOOD))
        shutter_r = list(b.box((shutter_x, wy + 0.55, win_z), (0.08, 0.10, 1.1), TRIM_WOOD))
        wall_faces += shutter_l + shutter_r

    # cutia mica pe acoperis (casa scarii): retrasa spre stanga-spate
    box_w, box_d, box_h = 2.2, 2.0, 1.4
    box_c = (-0.3, -0.4, HA_WALL + box_h * 0.5)
    wall_faces += list(b.box(box_c, (box_w, box_d, box_h), WALL))
    wall_faces += list(b.box((box_c[0], box_c[1], HA_WALL + box_h + 0.08),
                             (box_w, box_d, 0.16), WALL))

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL

    # House_Trim: rama usii + obloanele au ramas STONE-slotate (WALL, de
    # fapt) fiindca `arch_opening` le-a construit direct in `b` -- corect,
    # rama e piatra/tencuiala casei. Doar placa usii + obloanele sunt WOOD,
    # si obloanele au fost adaugate direct in `b` mai sus (acelasi motiv:
    # sunt un accent mic pe peretele WALL). Recitim `bg` (care are usa,
    # WOOD) ca House_Trim propriu-zis, plus ferestrele (GLOW ramas in bg
    # pentru geamurile laterale).
    trim_obj = bg.to_object("House_Trim")

    # --- scara solida pe latura DREAPTA, in trepte pline, urcand spre spate
    #
    # REVIZUIRE: prima incercare intindea scara pe toata adancimea casei
    # (5.4 m rulaj pentru 6.5 m urcare) -- prea LUNGA si prea LINA, domina
    # cadrul (randarea aratea o rampa uriasa, nu o scara laterala compacta ca
    # pe decupare). Pe decupare, scara ocupa aprox JUMATATE din adancimea
    # casei si e vizibil mai ABRUPTA. Rulaj scurtat la ~55% din HA_SIDE.
    # A DOUA REVIZUIRE (dupa randarea cu rulaj scurtat): footprint-ul scarii
    # nu era mare (1.3 m latime), dar cheek-ul (obrazul plin, diagonal, pe
    # toata inaltimea de 6.5 m) taia cadrul din fata-centru spre spate,
    # ascunzand usa -- domina COMPOZITIA, nu spatiul. Fix: scara mai
    # INGUSTA (width 0.75 nu 1.1, cheek mai subtire) si TRASA MAI SPRE
    # DREAPTA (stair_x mai mare), ca diagonala ei sa cada langa marginea
    # dreapta a casei, nu peste mijlocul fatadei cu usa.
    br = Builder()
    rail_faces = []
    stair_x = hs + 0.75
    stair_run = HA_SIDE * 0.42
    stair_w = 0.75
    start = (stair_x, hs - 0.15, 0.0)
    end = (stair_x, hs - 0.15 - stair_run, HA_WALL)
    stair_faces = solid_stair(br, start, end, stair_w, WALL, tread_slot=WALL,
                              nosing=True, nosing_slot=RAIL_WHITE, cheek=True,
                              cheek_slot=WALL, step_h=0.22)
    rail_faces += stair_faces
    # balustrada pe console, de-a lungul crestei scarii (aproximata printr-un
    # singur segment inclinat p1->p2 -- railing_on_brackets accepta orice
    # segment, nu doar orizontal, fiindca `beam`/`pickets` lucreaza in 3D) --
    # acelasi rulaj scurtat ca `stair_faces`, altfel balustrada iese mai
    # lunga decat scara pe care sta.
    rail_faces += railing_on_brackets(br, (stair_x + stair_w * 0.5 + 0.05, hs - 0.15, 0.80),
                                      (stair_x + stair_w * 0.5 + 0.05, hs - 0.15 - stair_run,
                                       HA_WALL + 0.80),
                                      0.70, RAIL_WHITE, bracket_step=0.8)
    # sloturile sunt deja corecte: `solid_stair(tread_slot=WALL, ...)` a
    # scris WALL pe trepte/obraji, `railing_on_brackets(..., RAIL_WHITE)` a
    # scris RAIL_WHITE pe balustrada -- nu se rescrie nimic aici.
    rail_obj = br.to_object("House_Rail")

    return wall_obj, trim_obj, rail_obj


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Ca `emit` din build_fiordland_village.py: offsetul de origine se
    calculeaza O DATA pe ansamblu si se aplica identic tuturor nodurilor
    (brief regula 6), cu `finish(origin=None)` pe fiecare in parte."""
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


tower_stone, tower_clock, tower_glow = build_ghanta_ghar()
emit([tower_stone, tower_clock, tower_glow], "buildings/ghanta_ghar.glb",
     AO_TOWER, bevel=0.03, budget=10500)

house_wall, house_trim, house_rail = build_blue_house_a()
emit([house_wall, house_trim, house_rail], "buildings/blue_house_a.glb",
     AO_HOUSE, bevel=0.025, budget=5300)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL pilot: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (tower_stone, tower_clock, tower_glow, house_wall,
                        house_trim, house_rail) if o is not None],
          "jodhpur_pilot.blend")
