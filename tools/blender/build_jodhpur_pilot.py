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
# Contract (brief §1.1): 22 m inalt, baza 7x7 m. **REVIZUIRE v3** (runda 3 --
# criticul orb + verdictul sefului au respins v2: banda dubla de arce la baza
# era INVENTATA, arcele erau ascutite in loc de rotunjite, cupola era
# fatetata/onion in loc de emisfera nervurata, cadranele iesisera gri fara
# contrast). Lista de elemente REscrisa dupa re-citirea crop-ului
# (ghanta_ghar.png) + notele sefului (care au prioritate fata de critic pe
# doua puncte: arcele de la baza sunt ROTUNJITE nu ascutite, cupola e
# EMISFERA NERVURATA nu bulb/con), de jos in sus:
#
#   1. Soclu in trepte (stepped_plinth), 2 nivele -- ~4,5% din inaltime.
#   2. Tier 1, CEL MAI LAT (~25% din inaltime): UN SINGUR arc mare cu cap
#      ROTUNJIT pe fiecare fata, ~50% din latimea fetei, ~70% din inaltimea
#      tier-ului, intunecat inauntru. NU banda dubla mica+mare -- un tier,
#      un arc.
#   3. Cornisa + balustrada joasa, iesita usor in consola (~2,3%).
#   4. Tier 2 (~15%), usor mai ingust: O SINGURA fereastra mica cu arc
#      rotunjit pe fiecare fata, intunecata. NU 3 lansete inalte ascutite.
#   5. Cornisa (~1,8%).
#   6. Tier 3, etajul ceasului (~17%): un cadran pe fiecare fata, disc ALB
#      curat, rama subtire inchisa, ace inchise, FARA cifre.
#   7. Galerie iesita in consola cu balustrada / parapet crenelat pe
#      console, MAI LATA decat etajul ceasului (~3,6%).
#   8. Chhatri deschis: coloane cu arce ROTUNJITE, clar deschis (interior
#      intunecat/strapuns), cu o chajja LATA si subtire (~15,5%).
#   9. Cupola EMISFERICA NERVURATA (nu onion, nu con fatetat), cam la fel de
#      lata ca chhatri-ul, finial SCURT (<=10% din inaltimea totala)
#      (~15,5%).
#
# Silueta de ansamblu: stiva continua, usor conica, nu un fus ingust pe o
# baza lata (criticul: raportul latime_baza/latime_etaj_ceas masurat pe
# decupare ~1,27 -- tinta explicita mai jos, nu doar aproximare).
# Nimic nu iese lateral din contur (turnul e simetric pe cele 4 fete).
TW_BASE = 7.0
TW_H = 22.0


# Buget de inaltime v3, calculat explicit ca sa insumeze EXACT TW_H=22,0 m
# (nu "ce ramane" alocat cupolei ca in v2, care satura si rata cota) --
# fiecare tier ia o fractie fixa din 22,0 m, cupola/finial-ul e ULTIMUL si
# ia diferenta exacta pana la 22,0.
_TW_PLINTH_H = 1.00      # 4,5%
_TW_T1_H = 5.50          # 25,0% -- tier 1, cel mai lat, un arc mare
_TW_CORNICE1_H = 0.50    # 2,3%
_TW_T2_H = 3.30          # 15,0% -- tier 2, un arc mic
_TW_CORNICE2_H = 0.40    # 1,8%
_TW_CLOCK_H = 3.70       # 16,8%
_TW_GALLERY_H = 0.80     # 3,6%
_TW_CHHATRI_H = 3.40     # 15,5%
# restul (dome+finial) = 22,0 - suma de mai sus = 3,40 (15,5%)


def build_ghanta_ghar():
    b = Builder()
    bg = Builder()

    z = 0.0

    # 1. soclu in trepte, 2 nivele (nu 3 -- lista v3 cere "2 trepte")
    plinth_levels = [(TW_BASE, TW_BASE, _TW_PLINTH_H * 0.6),
                     (TW_BASE - 0.6, TW_BASE - 0.6, _TW_PLINTH_H * 0.4)]
    stone_faces = list(stepped_plinth(b, (0.0, 0.0, z), plinth_levels, STONE))
    for w, d, h in plinth_levels:
        z += h
    plinth_top_hw = (TW_BASE - 0.6) * 0.5

    # IMPORTANT: niciun tier de mai jos nu mai pune o cutie PLINA pe toata
    # fata inainte de arch_opening -- o cutie plina si un panou perforat in
    # acelasi loc z-fighteaza (cioburi in randare). `arch_opening` isi
    # construieste SINGUR panoul complet al fetei. Un miez de cutie mic
    # (mai ingust decat fetele) ramane doar pentru colturile dintre fete,
    # retras cu grosimea peretelui, ca sa nu coplaneze cu panourile.
    face_normals = [(0.0, 1.0), (1.0, 0.0), (0.0, -1.0), (-1.0, 0.0)]

    def _tier_core(hw, h, zc, inset):
        core_hw = hw - inset
        return list(b.box((0.0, 0.0, zc + h * 0.5), (core_hw * 2, core_hw * 2, h), STONE))

    # 2. tier 1, CEL MAI LAT: UN singur arc cu cap ROTUNJIT pe fiecare fata,
    # ~50% din latimea fetei, ~70% din inaltimea tier-ului (lista v3 pas 2 --
    # NU banda dubla mica+mare, care era inventata in v2).
    tier1_h = _TW_T1_H
    tier1_hw = plinth_top_hw - 0.05
    tier1_wall_t = 0.35
    stone_faces += _tier_core(tier1_hw, tier1_h, z, tier1_wall_t)
    panel_r1 = tier1_hw - tier1_wall_t * 0.5
    t1_opening_w = tier1_hw * 2 * 0.50   # ~50% din latimea fetei
    t1_opening_h = tier1_h * 0.70        # ~70% din inaltimea tier-ului
    for nx, ny in face_normals:
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        res = arch_opening(b, bg, (nx * panel_r1, ny * panel_r1, z), t1_opening_w,
                           t1_opening_h, t1_opening_h * 0.55, tier1_wall_t, STONE, GLOW,
                           style="round", rotation=rot, glass=True, reveal=0.18,
                           panel_w=tier1_hw * 2, panel_h=tier1_h)
        stone_faces += res["stone"]
    z += tier1_h

    # 3. cornisa + balustrada joasa, iesita usor in consola
    stone_faces += list(balcony_band(b, (0.0, 0.0, z), tier1_hw - 0.35, tier1_hw + 0.12,
                                     _TW_CORNICE1_H * 0.5, STONE, segments=16))
    stone_faces += list(balustrade(b, (-(tier1_hw - 0.4), tier1_hw - 0.3, z + _TW_CORNICE1_H * 0.5),
                                   (tier1_hw - 0.4, tier1_hw - 0.3, z + _TW_CORNICE1_H * 0.5),
                                   _TW_CORNICE1_H * 0.5, STONE, merlon_w=0.16, merlon_gap=0.12))
    z += _TW_CORNICE1_H

    # 4. tier 2, mai ingust: O SINGURA fereastra mica cu arc ROTUNJIT pe
    # fiecare fata (lista v3 pas 4 -- NU 3 lansete ascutite, care erau
    # inventate in v2).
    tier2_h = _TW_T2_H
    tier2_hw = tier1_hw - 0.45
    tier2_wall_t = 0.30
    stone_faces += _tier_core(tier2_hw, tier2_h, z, tier2_wall_t)
    panel_r2 = tier2_hw - tier2_wall_t * 0.5
    t2_opening_w = tier2_hw * 2 * 0.32
    t2_opening_h = tier2_h * 0.55
    for nx, ny in face_normals:
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        res = arch_opening(b, bg, (nx * panel_r2, ny * panel_r2, z), t2_opening_w,
                           t2_opening_h, t2_opening_h * 0.55, tier2_wall_t, STONE, GLOW,
                           style="round", rotation=rot, glass=True, reveal=0.12,
                           panel_w=tier2_hw * 2, panel_h=tier2_h)
        stone_faces += res["stone"]
    z += tier2_h

    # 5. cornisa
    stone_faces += list(balcony_band(b, (0.0, 0.0, z), tier2_hw - 0.25, tier2_hw + 0.10,
                                     _TW_CORNICE2_H, STONE, segments=16))
    z += _TW_CORNICE2_H

    # 6. etajul ceasului: bloc mai ingust decat tier 2, 4 cadrane (unul per
    # fata), disc ALB curat + rama subtire + ace, in Clock_Glow
    clock_h = _TW_CLOCK_H
    clock_hw = tier2_hw - 0.35
    stone_faces += list(b.box((0.0, 0.0, z + clock_h * 0.5),
                              (clock_hw * 2, clock_hw * 2, clock_h), STONE))
    bc = Builder()
    clock_r = 0.82
    clock_cz = z + clock_h * 0.55
    for nx, ny in face_normals:
        cx = nx * (clock_hw + 0.02)
        cy = ny * (clock_hw + 0.02)
        axis = "X" if abs(nx) > 0.5 else "Y"
        # rama subtire inchisa (GLOW), apoi discul alb usor mai mic deasupra
        # -- contrastul rama-intunecata / disc-alb e ce lipsea in v2 (discul
        # gri fara margine citea ca nisa goala, nu ca ceas).
        bc.cylinder((cx, cy, clock_cz), clock_r, 0.06, GLOW, segments=16, axis=axis)
        bc.cylinder((cx + nx * 0.02, cy + ny * 0.02, clock_cz), clock_r * 0.86, 0.08,
                   WALL, segments=16, axis=axis)
        hand_c = (cx + nx * 0.11, cy + ny * 0.11, clock_cz)
        if abs(nx) > 0.5:
            bc.box(hand_c, (0.03, clock_r * 0.50, 0.10), GLOW)
            bc.box((hand_c[0], hand_c[1] + clock_r * 0.14, hand_c[2] + clock_r * 0.09),
                  (0.03, clock_r * 0.28, 0.10), GLOW)
        else:
            bc.box(hand_c, (clock_r * 0.50, 0.03, 0.10), GLOW)
            bc.box((hand_c[0] + clock_r * 0.14, hand_c[1], hand_c[2] + clock_r * 0.09),
                  (clock_r * 0.28, 0.03, 0.10), GLOW)
    z += clock_h

    # 7. galerie iesita in consola, MAI LATA decat etajul ceasului, cu
    # parapet crenelat pe console vizibile (lista v3 pas 7).
    gal_r = clock_hw * 1.15   # explicit mai lata decat clock_hw
    stone_faces += list(balcony_band(b, (0.0, 0.0, z), clock_hw + 0.1, gal_r,
                                     _TW_GALLERY_H * 0.4, STONE, segments=16,
                                     crenellated=True, merlon_count=16,
                                     merlon_h=_TW_GALLERY_H * 0.55))
    for nx, ny in face_normals:
        along = (-ny, nx)
        for s in (-1.0, 1.0):
            cx = nx * clock_hw * 0.9 + along[0] * s * clock_hw * 0.55
            cy = ny * clock_hw * 0.9 + along[1] * s * clock_hw * 0.55
            stone_faces += list(b.box((cx, cy, z - 0.12), (0.32, 0.32, 0.24), STONE))
    z += _TW_GALLERY_H

    # 8. chhatri: pavilion deschis cu 8 coloane, arce ROTUNJITE (nu cusped/
    # pointed -- lista v3 pas 8), chajja lata.
    lant_r = clock_hw - 0.10
    lant_col_h = _TW_CHHATRI_H * 0.72
    res = chhatri(b, bg, (0.0, 0.0, z), 8, lant_r, lant_col_h, STONE, GLOW,
                 col_r=0.15, dome_radius=lant_r * 0.5, arch_style="round",
                 chajja_out=0.45, segments_dome=12)
    stone_faces += res["stone"]
    z += _TW_CHHATRI_H

    # 9. cupola PRINCIPALA: EMISFERA NERVURATA (nu onion/con fatetat --
    # nota sefului are prioritate fata de critic pe acest punct), cam la
    # fel de lata ca chhatri-ul, finial SCURT. Inaltimea ramasa e EXACT
    # 22,0 - z (bugetul de mai sus a fost calculat sa insumeze 22,0 fara sa
    # se bazeze pe cupola sa umple diferenta).
    #
    # O emisfera reala (profil de sfert de cerc) are inaltimea cupolei
    # insesi EGALA cu raza -- `dome_r` controleaza deci simultan latimea
    # (cam cat chhatri-ul) SI inaltimea corpului cupolei. Tamburul (`drum_h`)
    # si inelul lotus (fix +0.12 in `dome()`) se aduna PESTE `dome_r`,
    # finial-ul PESTE tot -- deci rezolvam `dome_r`/`drum_h`/`finial_h` ca
    # sa insumeze `remaining`, cu latimea (dome_r) tinta aproape de `lant_r`
    # (latimea chhatri-ului) mai degraba decat calculata independent.
    remaining = TW_H - z
    LOTUS_H = 0.12  # constanta din `dome()` (lotus_ring=True adauga fix 0.12)
    finial_h = min(remaining * 0.22, TW_H * 0.10)  # finial <= 10% din 22,0 m
    drum_h = remaining * 0.10
    dome_r = remaining - finial_h - drum_h - LOTUS_H
    stone_faces += dome(b, (0.0, 0.0, z), dome_r, STONE, drum_h=drum_h,
                        profile="hemisphere", segments=16, ribs=12,
                        lotus_ring=True, finial=True, finial_h=finial_h)

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
# **REVIZUIRE v3** (runda 3 -- criticul orb + sef au respins v2: usa lipsea
# complet din randarea de comparatie fiindca statea pe fata +Y, iar scara
# statea pe fata +X -- DOUA fete diferite, in loc de UNA SINGURA ca pe
# decupare; scara arata ca zabrele/linii subtiri, nu masa solida; pe fata
# laterala stanga aparea o structura fara corespondent). Lista RE-scrisa
# dupa notele sefului. **A DOUA REVIZUIRE, in aceeasi runda:** un test cu un
# cub colorat pe fete (randat cu camera EXACTA din `compare()`) a aratat ca
# fata DOMINANTA in cadru e +X (nu +Y cum presupusesem) -- usa+scara mutate
# de pe +Y pe +X, ferestrele de pe -X pe -Y:
#
#   1. Corp cubic (6x6, 2 etaje) cu parapet plat sus, cu CORNISA proeminenta
#      (chajja) la marginea de sus -- iese vizibil peste perete, cu umbra.
#   2. Usa dreptunghiulara de lemn (WOOD, maro), in JUMATATEA STANGA a fetei
#      +X (fata dominanta catre camera), cu prag/treapta mica in fata.
#   3. Scara SOLIDA, masa plina cu obraz/dedesubt COLORAT (albastru, nu
#      alb), pe TREIMEA DREAPTA a ACELEIASI fete +X -- urca de la colt
#      (dreapta-jos) spre stanga-sus, atinge parapetul terasei la ~2/3 din
#      latimea fetei. Trepte cu nosing alb + balustrada subtire alba.
#   4. Ferestrele cu obloane (contract §1.1) raman, dar pe fata din SPATE
#      (-Y), departe de camera de comparatie -- nu au corespondent vizibil
#      in decupare oricum (decuparea arata doar fata din fata).
#   5. Cutie mica pe acoperis (casa scarii), retrasa spre spate, cu parapet
#      propriu.
HA_SIDE = 6.0
HA_WALL = 6.5


def build_blue_house_a():
    h_wall = 6.0            # pereti pana la ultimul planseu
    parapet_h = HA_WALL - h_wall
    hs = HA_SIDE * 0.5

    b = Builder()
    bg = Builder()
    wall_faces = []
    WALL_T = 0.5   # grosimea peretelui cu usa, pe fata +X

    # REVIZUIRE runda 3 (a doua parte): un cub de test cu fete colorate
    # distinct, randat cu EXACT camera din `compare()`, a aratat ca fata
    # DOMINANTA in cadru (cea mare, din stanga) e +X, iar +Y e fata
    # INGUSTA din dreapta -- invers fata de ce presupusesem la usa/scara pe
    # +Y (care iesea aproape invizibila, pe fasia subtire din dreapta).
    # Usa+scara se muta acum pe +X (fata dominanta), ferestrele pe -Y
    # (fata ascunsa).
    #
    # 1. corp cubic: miezul e RETRAS cu WALL_T doar pe fata +X (usa+scara)
    # fata de HA_SIDE, ca panoul `arch_opening` de mai jos sa se lipeasca
    # flush de miez, nu sa-l suprapuna (acelasi bug/fix ca la ghanta_ghar).
    # Ferestrele (pe -Y) au nevoie de acelasi tratament pe -Y.
    core_hw_x = hs - WALL_T * 0.5   # limita pe X (fata +X, usa)
    core_hw_y = hs - WALL_T * 0.5   # limita pe Y (fata -Y, ferestrele)
    wall_faces += list(b.box((0.0, 0.0, h_wall * 0.5),
                             (core_hw_x * 2, core_hw_y * 2, h_wall), WALL))
    # placi late pe -X si +Y (fara goluri), care aduc peretele inapoi la
    # HA_SIDE -- fiecare placa umple exact banda dintre miez si exterior.
    band_x = hs - core_hw_x
    band_y = hs - core_hw_y
    wall_faces += list(b.box((-(hs - band_x * 0.5), 0.0, h_wall * 0.5),
                             (band_x, core_hw_y * 2, h_wall), WALL))
    wall_faces += list(b.box((0.0, (hs - band_y * 0.5), h_wall * 0.5),
                             (HA_SIDE, band_y, h_wall), WALL))
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

    # 2. usa DREPTUNGHIULARA (nu arc -- decuparea arata un canat drept, nu
    # curbat), pe JUMATATEA STANGA a fetei +X (fata dominanta catre camera),
    # cu prag mic in fata. `arch_opening(style="round", pier_h=door_h)` cu
    # `rise` aproape 0 aproximeaza un dreptunghi pur (rise minim garantat de
    # `_arch_profile`), pastrand acelasi mecanism de gol real + firida.
    # Rotatia duce +Y local (fata implicita a `arch_opening`) pe +X global.
    door_rot = Matrix.Rotation(math.radians(-90.0), 3, "Z")
    door_w, door_h = 1.3, 2.4
    door_y = -hs * 0.62   # jumatatea STANGA a fetei, mai spre colt -- lasa
    # loc clar intre usa si scara (care ajunge pana la Y=-1,0), sa nu se
    # suprapuna vizual in randare (critica runda 3: usa aproape ascunsa de
    # scara)
    res_door = arch_opening(b, bg, (hs, door_y, 0.0), door_w, door_h,
                            door_h * 0.94, WALL_T, WALL, TRIM_WOOD, style="round",
                            rotation=door_rot, glass=True, reveal=0.10, glass_depth=0.08,
                            panel_w=2.2, panel_h=door_h * 1.4)
    wall_faces += res_door["stone"]
    # placa usii insasi intra in bg (foloseste GLOW-slotul ca sa stea in
    # firida), dar trebuie WOOD nu VOLCANIC_BLACK: rescriem slotul fetelor
    # abia create, in Builder-ul `bg`.
    for f in res_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    # prag/treapta mica in fata usii
    wall_faces += list(b.box((hs + 0.18, door_y, 0.06), (0.36, door_w + 0.3, 0.12), WALL))

    # 3. ferestrele cu obloane (contract §1.1), mutate pe fata din SPATE
    # (-Y, ascunsa de camera in comparatia de fidelitate).
    #
    # REVIZUIRE runda 3: geamul ferestrelor (VOLCANIC_BLACK) se scria in
    # `bg`, ACELASI Builder ca usa (WOOD) -- desi codul nu retinea
    # `res_w["glass"]` intr-o variabila, faptul ca `arch_opening` primeste
    # `bg` ca parametru il umple oricum ca efect secundar. `House_Trim`
    # (exportat din `bg`) ajungea sa amestece usa (WOOD) cu geamurile
    # ferestrelor (VOLCANIC_BLACK) in ACELASI nod -- bbox-ul lui sarea pe
    # toata adancimea casei, iar tenta flat de comparatie (un singur hex
    # per nod) picta gresit fie usa, fie geamul. Geamurile merg acum
    # intr-un Builder SEPARAT (`bglow`), pastrand contractul de brief
    # (House_Wall/House_Trim/House_Glow -- vezi export mai jos).
    bglow = Builder()
    win_z = h_wall * 0.58
    win_rot = Matrix.Rotation(math.radians(180.0), 3, "Z")
    for wx in (-1.6, 1.2):
        res_w = arch_opening(b, bglow, (wx, -hs, win_z - h_wall * 0.5), 0.75, 1.15,
                             0.35, WALL_T, WALL, GLOW, style="round", rotation=win_rot,
                             glass=True, reveal=0.10, panel_w=1.6, panel_h=1.7,
                             panel_z0=-0.4)
        wall_faces += res_w["stone"]
        shutter_y = -hs - WALL_T * 0.5 - 0.03
        shutter_l = list(b.box((wx - 0.55, shutter_y, win_z), (0.10, 0.08, 1.1), TRIM_WOOD))
        shutter_r = list(b.box((wx + 0.55, shutter_y, win_z), (0.10, 0.08, 1.1), TRIM_WOOD))
        wall_faces += shutter_l + shutter_r

    # cutia mica pe acoperis (casa scarii): retrasa spre spate
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
    # rama e piatra/tencuiala casei. Doar placa usii e WOOD, in `bg` (acum
    # NUMAI usa, dupa despartirea geamurilor in `bglow` -- vezi runda 3).
    trim_obj = bg.to_object("House_Trim")
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))

    # --- scara solida, PE ACEEASI FATA +X ca usa (v3) -----------------------
    #
    # REVIZUIRE v3: criticul + seful au aratat ca v2 punea scara pe o fata
    # DIFERITA de usa -- decuparea arata AMBELE pe aceeasi fata (usa in
    # jumatatea stanga, scara in treimea dreapta). Usa e la `door_y =
    # -0,45*hs` (negativ) -- scara trebuie sa fie in partea OPUSA (Y
    # pozitiv), lipita de fata +X, urcand de la coltul +Y (dreapta, vazuta
    # din fata) spre STANGA (Y negativ), atingand parapetul la ~2/3 din
    # latime. Obrazul (cheek) e colorat ALBASTRU (WALL, ca peretele), nu
    # alb -- doar treptele (nosing) si balustrada raman albe.
    br = Builder()
    rail_faces = []
    stair_w = 0.70
    stair_x = hs + stair_w * 0.5 + 0.05   # lipita de peretele +X, iese usor in fata
    y_start = hs - 0.05                    # coltul din dreapta (vazut din fata +X)
    y_end = hs - HA_SIDE * 0.667           # atinge parapetul la ~2/3 din latime
    start = (stair_x, y_start, 0.0)
    end = (stair_x, y_end, HA_WALL)
    stair_faces = solid_stair(br, start, end, stair_w, WALL, tread_slot=WALL,
                              nosing=True, nosing_slot=RAIL_WHITE, cheek=True,
                              cheek_slot=WALL, step_h=0.22)
    rail_faces += stair_faces
    # balustrada pe console, de-a lungul crestei scarii -- acelasi traseu
    # (Y, nu X) ca `stair_faces`, usor mai in fata (+X) ca sa stea pe
    # muchia exterioara a treptelor, nu in mijlocul lor.
    rail_x = stair_x + stair_w * 0.5 + 0.05
    rail_faces += railing_on_brackets(br, (rail_x, y_start, 0.80),
                                      (rail_x, y_end, HA_WALL + 0.80),
                                      0.70, RAIL_WHITE, bracket_step=0.8)
    # sloturile sunt deja corecte: `solid_stair(tread_slot=WALL, ...)` a
    # scris WALL pe trepte/obraji, `railing_on_brackets(..., RAIL_WHITE)` a
    # scris RAIL_WHITE pe balustrada -- nu se rescrie nimic aici.
    rail_obj = br.to_object("House_Rail")

    return wall_obj, trim_obj, rail_obj, glow_obj


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
     AO_TOWER, bevel=0.03, budget=8600)

house_wall, house_trim, house_rail, house_glow = build_blue_house_a()
emit([house_wall, house_trim, house_rail, house_glow], "buildings/blue_house_a.glb",
     AO_HOUSE, bevel=0.025, budget=5300)  # 5117 masurat, val3 (House_Glow nou)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL pilot: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (tower_stone, tower_clock, tower_glow, house_wall,
                        house_trim, house_rail, house_glow) if o is not None],
          "jodhpur_pilot.blend")
