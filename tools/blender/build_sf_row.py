"""Kitul casei de rand victoriene (San Francisco, K1) — sursa reproductibila.

Contract: docs/asset_briefs/sf_painted_row_kit.md (§1-§10). Referinta de
caracter si culoare: docs/track_briefs/img/sf_assets_v1/sf_row_b_canted.png
(si _a_canted, _c_canted, _b_square pentru ce e comun kitului). Unde decuparea
si brief-ul nu se potrivesc pe STRUCTURA sau COTE, castiga brief-ul.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_row.py
    python tools/blender/verify_glb.py \\
        assets/models/sanfrancisco/buildings/sf_row_b_canted.glb 2500 --origin=waterline
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/measure_sf_row_facade.py -- \\
        assets/models/sanfrancisco/buildings/sf_row_b_canted.glb

Se construiesc toate cele sapte case ale kitului (`HOUSES`), fiecare in doua
fisiere: `<nume>.glb` (garajul pe +X; la colt turnuletul pe (-X, -Z)) si
`<nume>_m.glb` (pre-oglindit: garajul pe -X, turnuletul pe (+X, -Z); aceleasi
doua noduri, transformari identitate; vezi `MIRRORED`). Doar unele case:

    ... --python tools/blender/run_build.py -- build_sf_row.py -- sf_row_a_canted

Pilotul `sf_row_b_canted` (lista de mai jos) e acceptat si iese byte-identic; cele
sase case noi au listele lor DUPA el (A, B patrat, C, colt), pe aceleasi reguli v2.

Pilotul v2 (`STYLE_V2`): casa se citeste PASTEL cu ancadramente albe. Cotele de
mai jos sunt ale v2; `STYLE_V1` reface exact pilotul v1 (parter de piatra,
benzi albe in fronton, rame 0,13, montanti 0,18 etc.). Masurat (elevatia de fata,
etaje + fronton, `measure_sf_row_facade.py`): v1 23 % pastel / 56 % alb, v2
45 % / 34 %.

Lista de elemente (acceptanta = lista asta, element cu element)
-------------------------------------------------------------------
 1. Amprenta 7,0 x 12,0 m; fatada la Godot Z = -6,0 (Blender +Y), spatele la
    +6,0; originea in centrul amprentei, la podeaua parterului (Y = 0).
 2. Fusta de beton (slot 8) de la 0 la -2,4, la fata peretilor, pe toate
    patru laturile; nu iese nici in fata, nici lateral.
 3. Parterul (0 -> 3,2) pe SCANDURA (Row_Wall), ca la casele din cod ale
    testului de loc; `ground="stone"` il readuce in piatra bej (slot 8), ca pe
    decupare.
 4. Usa de garaj pe +X (2,6 x 2,4), adancita 0,12, cu 4 panouri orizontale
    in relief (slot 9) si ancadrament alb pe trei laturi.
 5. Intrarea adancita pe -X: nisa de 1,4 x 1,0, interior log_dark (28), usa
    1,0 x 2,3 cu fereastra deasupra (sticla 20), rama alba.
 6. Scara de 7 trepte IN nisa, de la 0 la -2,1, prin fusta (slot 8).
    Decuparea arata scara pe trotuar: NU (brief §3.1).
 7. Pilastri + antablament alb in jurul nisei (ies 0,07).
 8. Braul alb la +3,2 (0,12 inalt, iese 0,06; v1 0,25).
 9. Scandurile albe de colt, verticale, late de 0,10 (v1 0,16), la marginile
    X +-3,5, de la brau la cornisa.
10. Peretii de scandura NETEZI (Row_Wall, slot 19): fatada (cu parterul),
    laturile ORBE, spatele, fetele bovindoului, frontoanele si benzile lor.
11. Bovindoul tesit pe +X, deasupra garajului, de la +3,3 la +9,35: fata de
    2,6, laturile la 45 de grade, iesit 0,9 in total (peretii la 0,8 +
    cornisa 0,1, ca AABB-ul sa se opreasca la Godot Z = -6,9).
12. Console albe sub bovindou (4, profil in trepte).
13. Talpa alba a bovindoului (0,15), braul dintre etaje pe bovindou (0,15),
    cornisa lui (9,12 -> 9,35, iesita 0,10). v1: 0,25 / 0,25 / 0,40.
14. Ferestrele bovindoului: 3 fete x 2 etaje; rama alba de 0,10 (v1 0,13) IN
    JURUL aceleiasi sticle, sticla adancita, traversa; fata din mijloc cu
    montant (doua ochiuri, ca pe decupare).
15. Montantii albi pe muchiile bovindoului, lati de 0,10 (v1 0,18).
16. Jumatatea -X a etajelor: doua ferestre inalte pe etaj (sticla 0,69 x 1,59,
    rama 0,10 -> 0,89 x 1,79; v1 0,95 x 1,85), pereche, cu glaf adancit,
    cornisa mica comuna (0,12; v1 0,18) si pervaz.
    (Decuparea arata una singura: castiga brief-ul.)
17. Cornisa principala (9,35 -> 9,6), iesita 0,35, fara depasire laterala, cu
    modilioane sub ea pe portiunea din afara bovindoului; fara friza (v1:
    friza alba 9,0 -> 9,3 + cornisa 9,3 -> 9,6).
18. Frontonul triunghiular spre strada (+9,6 -> +12,45), pe scandura.
19. Acoperis in doua ape, ardezie (20), coama pe Godot Z la +12,6, iesit
    0,4 in fata peste fronton, 0 lateral si in spate.
20. Bordura alba (verge) pe muchiile inclinate ale frontonului, lata de 0,26
    (v1 0,42).
21. Solzii frontonului: 4 benzi-pana in relief, PASTEL (Row_Wall), cu buza lor
    de umbra (v1: albe, pe atlas).
22. Fereastra mica in fronton, cu rama si pervaz.
23. Spatele: 6 ferestre plate (2 pe nivel) si banda de streasina alba.
24. Fara text, cifre, scara de incendiu, balustrade subtiri, ornamente sub
    0,08 m; fara felinar (optional in brief, lasat pentru dupa pilot).
25. Exact doua noduri: Row_Wall (doar slot 19, doar scandura) si Row_Trim
    (restul, pe sloturile din §5).
26. AO copt pe colturi: blând pe pereti (0,78 la podea -> 1,0 sus, ~0,7 DOAR
    sub bovindou, cornise, brau si benzile frontonului: ocluzia de deasupra,
    masurata la ~0,3 m inauntrul fetei; podea 0,68), nisa ~0,55, geamuri ~0,6,
    fusta 0,7 -> 0,85.
27. Varianta pre-oglindita `_m`: x -> -x si ordinea fetelor inversata inainte de
    bevel/UV/AO (`mirror_house`); jocul n-o mai oglindeste cu scale.x = -1.

sf_row_b_square (B, Queen Anne, bovindou PATRAT) — referinta sf_row_b_square.png
-------------------------------------------------------------------------------
 1-27 ca pilotul, cu exceptiile:
 B1. Bovindoul patrat (brief §3.2): 2,8 lat, laturile perpendiculare pe fatada,
     iesit 0,8 + cornisa 0,1 (AABB tot -6,9), de la x -0,25 la +2,55.
 B2. Ferestrele lui: fata de 2,8 cu o fereastra larga cu montant (sticla 2,0;
     decuparea arata doua ferestre lipite, cu stalp alb intre ele), laturile de
     0,8 cu cate o fereastra ingusta (sticla 0,30) intre montantii de colt.

sf_row_a_canted / sf_row_a_square (A, Italianate) — referinte sf_row_a_*.png
---------------------------------------------------------------------------
 1-16 ca pilotul (fusta, parter de scandura, garaj, nisa, scara in nisa, brau,
 scanduri de colt, perete neted, bovindou tesit/patrat cu console, talpa, brau
 intre etaje, montanti, ferestrele lui), plus:
 A1. Bovindoul FARA cornisa proprie: peretii lui urca pana la 10,05 (friza), iar
     cornisa grea a casei il inveleste (decuparea: cornisa trece peste bovindou).
 A2. "Sprancene" (cornise arcuite) peste cele doua ferestre inalte de pe -X (late
     0,97, arc de 0,18, groase 0,12, iesite 0,16); inlocuiesc cornisa mica comuna
     a perechii. Ferestrele bovindoului raman fara sprancene, ca pe decupare (si
     ca elevatia sa tina 45 % pastel); la tesit sunt mai inguste decat la pilot
     (`NARROW_CANTED_BAY_WINDOWS`).
 A3. Cornisa GREA (brief §3.2: 0,7 m peste +9,6, iesita 0,45): brau alb 9,6 ->
     9,7, friza pastel 9,7 -> 10,05 cu CONSOLE albe in volute (6-8 pe jumatatea
     -X, 1-2 pe +X) si blocuri mici pe fetele bovindoului, coroana alba 10,05 ->
     10,3 iesita 0,45 (peste bovindou 0,10, ca iesirea totala sa ramana 0,9), cu
     bevel.
 A4. Acoperis PLAT ascuns: placa de ardezie la 10,05, atice laterale si din spate
     pana la 10,3 (fata interioara pe scandura, capac de ardezie: de sus, intre
     case, nu fac linii albe). Varful casei: +10,3 (garda il cere exact).
 A5. Spatele cu banda de streasina la 9,75 -> 10,0; restul ca pilotul.
 Decuparea arata trepte pe trotuar si parterul de piatra: NU (brief §3.1, v2).

sf_row_c_canted / sf_row_c_square (C, Stick) — referinte sf_row_c_*.png
----------------------------------------------------------------------
 1-17 ca pilotul (inclusiv cornisa 9,35 -> 9,6 cu modilioane), plus:
 C1. MONTANTI verticali albi in relief (0,10 lati, iesiti 0,04) pe jumatatea -X:
     langa coltul de -X, intre cele doua ferestre ale perechii, intre pereche si
     bovindou, de la brau la cornisa; plus un "stick" orizontal la linia
     planseului (6,25 -> 6,37) pe aceeasi jumatate.
 C2. FATADA FALSA (brief §3.2): atic drept pe planul fatadei, peste cornisa, cu
     TREAPTA: marginile pana la 10,35, mijlocul (|x| < 1,5) pana la +10,8;
     peretele aticului pastel pe ambele fete, capace albe cu bevel iesite 0,10,
     montanti albi pe atic (+-2,5, +-1,45, 0) in continuarea stilului.
 C3. Acoperisul in doua ape ASCUNS in spatele aticului: coama la 10,65 (sub
     treapta de 10,8), streasina 9,6 la vecini, fara bordura, fara solzi, fara
     ferestruica; frontonul doar in spate (pastel).
 C4. Varful casei: +10,8 (garda il cere exact).
 Decuparea C arata fronton (acoperis vizibil): castiga brief-ul (fatada falsa);
 de pe decupare raman culoarea, montantii si bovindoul.

sf_row_corner_turret (colt, 9,0 x 12,0) — referinta sf_row_corner_turret.png
---------------------------------------------------------------------------
 T1. Amprenta 9,0 x 12,0 (X +-4,5), fatadele la Godot -Z (Blender +Y) si -X,
     pereti orbi pe +X si +Z; originea in centrul amprentei, la podea.
 T2. Fusta de beton -2,4 -> 0 pe toate laturile, la fata peretilor.
 T3. Parterul pe scandura; FARA garaj (decuparea nu are; brief §3.1 nu-l cere
     la colt). Pe -Z: nisa intrarii (1,4 x 1,0) cu scara de 7 trepte in nisa, pe
     jumatatea +X (x = 2,85), pilastri + antablament; o pereche de ferestre de
     parter (sticla 0,69 x 1,4, ancadrament iesit 0,06, fara pervaz: nimic sub
     +3,3 nu iese peste 8 cm). Pe -X: trei ferestre de parter la fel.
 T4. Braul alb la +3,2 pe ambele fatade; scandurile de colt la (+X, -Z) si
     (-X, +Z); coltul (-X, -Z) e al turnuletului.
 T5. TURNULETUL octogonal (diametru 3,2), cu doua varfuri pe planurile celor
     doua fatade (iese 0,87 din fiecare; fetele dinspre strada: cinci): consola
     in trunchi de piramida 3,3 -> 3,8, talpa alba 3,8 -> 3,95, brau 6,25 ->
     6,4, banda de cornisa 9,35 -> 9,6, montanti albi pe muchii, cate o
     fereastra pe fata si pe etaj; deasupra acoperisului (9,6 -> 12,2) toate opt
     fetele, cu ferestre; coroana alba 12,2 -> 12,5; acoperis conic (piramida
     octogonala netezita) 12,5 -> 14,62 si varf alb pana la +15,0.
 T6. Etajele pe -Z: doua perechi de ferestre inalte (x -1,0 si peste nisa),
     cornisa mica comuna; pe -X: trei ferestre inalte pe etaj, fiecare cu
     cornisa mica.
 T7. Cornisa principala 9,35 -> 9,6 iesita 0,35, cu modilioane, pe ambele
     fatade, pana in turnulet; fara depasire spre +X si spre spate.
 T8. Acoperis in patru ape, ardezie, coama pe Z la +12,3; turnuletul il
     strapunge pe colt.
 T9. Spatele: 9 ferestre plate si banda de streasina.
 T10. Doua noduri (Row_Wall doar scandura: peretii, peretii turnuletului;
     Row_Trim restul), AO dupa aceleasi reguli v2, bevel doar pe silueta.
 T11. `_m`: turnuletul pe (+X, -Z), a doua fatada pe +X.
 Decuparea arata turnuletul pe coltul din stanga privit din fata (+X): brief-ul
 il cere pe (-X, -Z) in fisierul de baza; `_m` e cel din decupare.
"""

import os
import math
import sys

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "sf_row_shapes.py")).read())

CATEGORY = "sanfrancisco/buildings/"

# Casele kitului (brief §3.2). Acoperisul alege familia, deci silueta de pe strada:
#   "gable"       B, Queen Anne: fronton ascutit pana la +12,6 (pilotul)
#   "italianate"  A: cornisa grea plata, acoperis plat ascuns, varful la +10,3
#   "false_front" C, Stick: atic drept cu treapta, varful la +10,8
# Coltul are constructorul lui (`build_corner`).
HOUSES = {
    "sf_row_a_canted": dict(bay_kind="canted", roof="italianate"),
    "sf_row_a_square": dict(bay_kind="square", roof="italianate"),
    "sf_row_b_canted": dict(bay_kind="canted", roof="gable"),
    "sf_row_b_square": dict(bay_kind="square", roof="gable"),
    "sf_row_c_canted": dict(bay_kind="canted", roof="false_front"),
    "sf_row_c_square": dict(bay_kind="square", roof="false_front"),
    "sf_row_corner_turret": dict(corner=True),
}
# Varful peretilor pentru gradientul AO de perete (0,78 la podea -> 1,0 sus).
WALL_TOP = {"gable": 12.45, "italianate": 10.3, "false_front": 10.8, "corner": 12.2}

MIRRORED = True

# Asezarea pe fatada (X, Blender = Godot). Bovindoul si garajul pe +X.
BAY_XC = 1.15        # centrul bovindoului: A = -0.95, D = +3.25 (tesit)
GARAGE_X = 1.3       # garajul intreg pe jumatatea +X (0.0 -> 2.6)
NICHE_X = -2.15      # nisa intrarii si perechea de ferestre de deasupra ei
WIN_PAIR = (-2.675, -1.625)   # centrele celor doua ferestre de pe -X

# STILUL = tot ce poate rasturna o decizie ulterioara, intr-un singur loc.
# STYLE_V1 reproduce pilotul v1 (commit 0f06b476); STYLE_V2 e pilotul v2: casa se
# citeste PASTEL cu ancadramente albe, nu ALBA cu accente pastel. Masurat pe v1:
# elevatia de fata (etaje + fronton) 56 % alb / 23 % pastel, iar in joc pastelul
# avea 17,5 % din pixelii caselor (casele din cod: 31 %).
# Sticla ramane identica intre stiluri: ramele se pun IN JURUL ei (`fw`), deci o
# rama mai subtire elibereaza perete, nu mareste geamul.
STYLE_V1 = dict(
    ground="stone",          # parterul 0..3,2: "stone" = piatra (slot 8, Row_Trim)
    gable_band_part="trim",  # benzile frontonului albe pe atlas
    wall_ao="v1",            # AO de perete cu ocluzie din toate directiile, podea 0,62
    belt_h=0.25,             # braul de la +3,2
    corner_w=0.16,           # scandurile de colt
    frame_w=0.13,            # ramele ferestrelor (fatada + bovindou)
    pair_hood_h=0.18,        # cornisa mica comuna peste perechea de ferestre
    bay_post_w=0.18,         # montantii albi de pe muchiile bovindoului
    bay_slab=(3.7, 3.95),    # talpa alba a bovindoului
    bay_mid=(6.2, 6.45),     # braul bovindoului dintre etaje
    bay_corn=(8.95, 9.35),   # cornisa bovindoului (sus fix la 9,35, brief §3.1)
    frieze=(9.0, 9.3),       # friza alba de sub cornisa principala (None = fara)
    cornice=(9.3, 9.6),      # cornisa principala (iesita 0,35)
    verge_h=0.42,            # bordura alba a frontonului
)
STYLE_V2 = dict(STYLE_V1)
STYLE_V2.update(
    ground="clapboard",      # parterul pe scandura, in Row_Wall (decizia v2 nr. 1)
    gable_band_part="wall",  # benzile frontonului pastel, cu buza lor (nr. 2)
    wall_ao="overhead",      # AO doar sub streasini, gradient 0,78 -> 1,0 (nr. 4)
    belt_h=0.12,             # (nr. 3: nimic sub 0,10 m)
    corner_w=0.10,
    frame_w=0.10,
    pair_hood_h=0.12,
    bay_post_w=0.10,
    bay_slab=(3.8, 3.95),
    bay_mid=(6.25, 6.40),
    bay_corn=(9.12, 9.35),   # buza 0,10 + coroana 0,13 (iesita 0,10, umbra ramane)
    frieze=None,
    cornice=(9.35, 9.6),
    verge_h=0.26,
)
STYLE = STYLE_V2

# Sticla (latime, z de jos, inaltime): identica in v1 si v2.
PAIR_GLASS = (0.69, ((4.23, 1.59), (6.88, 1.59)))


# Ferestrele bovindoului patrat: (latimea STICLEI, montanti) pe fiecare fata. Laturile
# lui au 0,8 (montantii albi de colt iau 0,1 la fiecare capat).
SQUARE_BAY_WINDOWS = [(0.30, 0), (2.0, 1), (0.30, 0)]
# Bovindoul tesit A si C: ferestre ceva mai inguste decat la pilot (0,49 / 1,74), ca
# elevatia sa treaca de prag fara fronton (masurat cu ale pilotului: A 43,9 % pastel,
# C 40,2 % / 38,2 % alb; cornisa grea si aticul nu aduc pastelul frontonului B).
NARROW_CANTED_BAY_WINDOWS = [(0.40, 0), (1.55, 1), (0.40, 0)]
# Consolele cornisei grele (A), pe portiunile de fatada din afara bovindoului.
A_CONSOLES = {"canted": (-3.35, -2.9, -2.45, -2.0, -1.55, -1.1, 3.4),
              "square": (-3.35, -2.93, -2.51, -2.09, -1.67, -1.25, -0.83, -0.41, 2.75,
                         3.35)}
# Montantii Stick (C) pe jumatatea -X: langa colt, intre ferestrele perechii,
# intre pereche si bovindou; pe atic.
C_STUDS = (-3.26, -2.15, -1.065)
C_PARAPET_STUDS = (-2.5, -1.45, 0.0, 1.45, 2.5)
C_APEX = 10.65          # coama acoperisului ascuns (sub treapta de 10,8)
# Cornisa grea (A): brau 9,6 -> 9,7, friza cu console 9,7 -> 10,05, coroana 10,05 ->
# 10,3 (0,7 m in total, brief §3.2). Prima varianta (coroana 10,0 -> 10,3, sprancene si
# pe bovindou, ferestrele pilotului) dadea elevatia tesitului 43,0 % pastel / 34,7 % alb.
A_CROWN = (10.05, 10.3)


def build_house(name, bay_kind="canted", roof="gable", st=None):
    st = st or STYLE
    h = House(name)
    clap = st["ground"] == "clapboard"
    ital = roof == "italianate"
    # parter + fusta
    stone_base(h, niche=(NICHE_X, 1.4, 2.95), garage=(GARAGE_X, 2.6, 2.4),
               ground=st["ground"])
    garage_door(h, gx=GARAGE_X)
    entry_niche(h, nx=NICHE_X)
    belt_course(h, ht=st["belt_h"])
    z_belt = LEVEL + st["belt_h"]
    z_corn0 = st["frieze"][0] if st["frieze"] else st["cornice"][0]
    corner_boards(h, z_belt, EAVE if ital else z_corn0, w=st["corner_w"])
    # bovindoul
    fw = st["frame_w"]
    outline = bay_outline(bay_kind, BAY_XC, proj=0.8)
    wins = SQUARE_BAY_WINDOWS if bay_kind == "square" else (
        None if roof == "gable" else NARROW_CANTED_BAY_WINDOWS)
    if ital:
        # peretii lui urca pana la friza; cornisa grea il inveleste (A1, A2)
        bay(h, outline, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=(A_CROWN[0],) * 2,
            post_w=st["bay_post_w"], fw=fw, corn_ao_row=clap, windows=wins,
            cornice=False, post_top=EAVE)
    else:
        bay(h, outline, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=st["bay_corn"],
            post_w=st["bay_post_w"], fw=fw, corn_ao_row=clap, windows=wins)
    # peretii de scandura (+ frontoanele daca acoperisul e in doua ape)
    apex = 12.6
    if ital:
        upper_walls(h, outline[0].x, outline[-1].x, side_z0=0.0,
                    rows=(LEVEL, LEVEL + 0.4, 9.1, EAVE, A_CROWN[0]), side_top=A_CROWN[1])
    elif roof == "false_front":
        upper_walls(h, outline[0].x, outline[-1].x, gable_apex=C_APEX - 0.15,
                    side_z0=0.0 if clap else None,
                    corn_z=None if st["frieze"] else st["cornice"][0],
                    gable_ends=(False, True))
    else:
        upper_walls(h, outline[0].x, outline[-1].x,
                    gable_apex=(apex - 0.15) if roof == "gable" else None,
                    side_z0=0.0 if clap else None,
                    corn_z=None if st["frieze"] else st["cornice"][0])
    # perechea de ferestre inalte pe -X, pe doua etaje
    gw, rows = PAIR_GLASS
    for gz, gh in rows:
        z0, ht = gz - fw, gh + 2 * fw
        for x in WIN_PAIR:
            window(h, V(x, YF, 0), XP, YP, z0, gw + 2 * fw, ht, fw=fw, proud=0.1,
                   hood=False, sill=True)
            if ital:
                arched_hood(h, V(x, YF, 0), XP, YP, gw + 2 * fw + 0.08, z0 + ht + 0.03,
                            0.18, 0.12, 0.16)
        if not ital:
            hx = gw * 0.5 + fw + 0.075      # cornisa trece 0,075 de rame (v1: +-0,55)
            wall_box(h.trim, V(0, YF, 0), XP, YP, WIN_PAIR[0] - hx, WIN_PAIR[1] + hx,
                     0.0, 0.18, z0 + ht, z0 + ht + st["pair_hood_h"], S_WHITE)
    # Stick: montantii verticali si "stick"-ul orizontal de la planseu (C1)
    if roof == "false_front":
        stick_studs(h, C_STUDS, z_belt, z_corn0)
        h.trim.box(V(-HX + st["corner_w"], YF, 6.25), V(outline[0].x, YF + 0.04, 6.37),
                   S_WHITE, skip=("-Y",))
    # cornisa + acoperis
    if ital:
        italianate_cornice(h, outline, z_bed=(EAVE, EAVE + 0.1), z_crown=A_CROWN,
                           consoles=A_CONSOLES[bay_kind])
        flat_roof(h, z_roof=A_CROWN[0], z_top=A_CROWN[1])
    else:
        eave_cornice(h, z_frieze=st["frieze"], z_corn=st["cornice"],
                     modillions=(-3.15, -2.55, -1.95, -1.35))
    if roof == "gable":
        gable_roof(h, apex=apex, verge_h=st["verge_h"], band_part=st["gable_band_part"])
    elif roof == "false_front":
        false_front(h, studs=C_PARAPET_STUDS)
        gable_roof(h, apex=C_APEX, over_front=-0.12, verge_h=None, bands=(),
                   gable_window=None)
    elif not ital:
        raise ValueError(roof)
    if ital:
        back_face(h, eave_band=(9.75, 10.0))
    else:
        back_face(h)
    return h


# --- Coltul -----------------------------------------------------------------------
CORNER_HX = 4.5
CORNER_NICHE_X = 2.85
CORNER_PAIRS = (-1.0, CORNER_NICHE_X)        # centrele perechilor de pe -Z
CORNER_SIDE_Y = (2.3, -0.5, -3.3)            # ferestrele de pe -X (Blender Y)
TURRET_R = 1.6


def _tall_window(h, c, u, n, z0, w, ht, fw, hood_h):
    window(h, c, u, n, z0, w, ht, fw=fw, proud=0.1, hood=False, sill=True)
    hx = w * 0.5 + 0.075
    wall_box(h.trim, c, u, n, -hx, hx, 0.0, 0.18, z0 + ht, z0 + ht + hood_h, S_WHITE)


def build_corner(name, st=None):
    st = st or STYLE
    hx = CORNER_HX
    h = House(name, hx=hx)
    fw = st["frame_w"]
    sx_t = -hx                                       # turnuletul pe (-X, -Z)
    s22 = TURRET_R * math.sin(math.radians(22.5))
    cx, cy = sx_t + s22, YF - s22                    # varfurile 0 si 5 pe cele doua fatade
    ring = octagon(cx, cy, TURRET_R)
    p0, p5 = ring[0], ring[5]
    # parter + fusta, fara garaj (T2, T3)
    stone_base(h, niche=(CORNER_NICHE_X, 1.4, 2.95), garage=None, ground=st["ground"])
    entry_niche(h, nx=CORNER_NICHE_X)
    belt_course(h, ht=st["belt_h"])
    z_belt = LEVEL + st["belt_h"]
    h.trim_bev.box(V(-hx - 0.06, YB, LEVEL), V(-hx, YF, z_belt), S_WHITE, skip=("+X",))
    corner_boards(h, z_belt, st["cornice"][0], w=st["corner_w"], sides=(1,))
    h.trim.box(V(-hx - 0.05, YBW, z_belt), V(-hx, YBW + st["corner_w"], st["cornice"][0]),
               S_WHITE, skip=("+X",))
    # peretii: fatada -Z (grila, golul turnuletului), +X orb, spatele
    upper_walls(h, -hx, p0.x, side_z0=0.0, corn_z=st["cornice"][0], sides=(1,))
    # fatada -X: grila proprie, cu golul turnuletului deasupra consolei
    rows = [0.0, LEVEL, LEVEL + 0.4, st["cornice"][0] - 0.5, st["cornice"][0], EAVE]
    o = V(-hx, 0, 0)
    for a, b in ((YBW, YBW + 0.3), (YBW + 0.3, p5.y - 0.3), (p5.y - 0.3, p5.y)):
        for c0, c1 in zip(rows[:-1], rows[1:]):
            h.wall.rect(o, YP, UP, a, b, c0, c1, S_WALL, -XP)
    for c0, c1 in ((0.0, LEVEL), (LEVEL, 3.95)):
        h.wall.rect(o, YP, UP, p5.y, YF, c0, c1, S_WALL, -XP)
    # turnuletul (T5)
    turret(h, cx, cy, V(sx_t, YF, 0), (("y", YF), ("x", -hx)), r=TURRET_R,
           top_win=(10.7, 1.05))
    # ferestrele
    gw, grows = PAIR_GLASS
    for xc in CORNER_PAIRS:
        xs = (xc - 0.525, xc + 0.525)
        for gz, gh in grows:
            z0, ht = gz - fw, gh + 2 * fw
            for x in xs:
                window(h, V(x, YF, 0), XP, YP, z0, gw + 2 * fw, ht, fw=fw, proud=0.1,
                       hood=False, sill=True)
            hx_ = gw * 0.5 + fw + 0.075
            wall_box(h.trim, V(0, YF, 0), XP, YP, xs[0] - hx_, xs[1] + hx_, 0.0, 0.18,
                     z0 + ht, z0 + ht + st["pair_hood_h"], S_WHITE)
    for x in (CORNER_PAIRS[0] - 0.525, CORNER_PAIRS[0] + 0.525):   # parterul -Z
        window(h, V(x, YF, 0), XP, YP, 0.8, gw + 2 * fw, 1.6, fw=fw, proud=0.06,
               hood=False, sill=False)
    for y in CORNER_SIDE_Y:
        c = V(-hx, y, 0)
        for gz, gh in grows:
            _tall_window(h, c, -YP, -XP, gz - fw, gw + 2 * fw, gh + 2 * fw, fw,
                         st["pair_hood_h"])
        window(h, c, -YP, -XP, 0.8, gw + 2 * fw, 1.6, fw=fw, proud=0.06, hood=False,
               sill=False)
    # cornisa pe ambele fatade, pana in turnulet (T7)
    zc = st["cornice"]
    eave_cornice(h, z_frieze=None, z_corn=zc, x0=p0.x,
                 modillions=(-1.9, -0.85, 0.2, 1.25, 2.3, 3.35, 4.25))
    h.trim_bev.box(V(-hx - 0.35, YB, zc[0]), V(-hx, p5.y, zc[1]), S_WHITE, skip=("+X",))
    for y in (3.25, 2.2, 1.15, 0.1, -0.95, -2.0, -3.05, -4.1, -5.15):
        h.trim.box(V(-hx - 0.29, y - 0.07, zc[0] - 0.16), V(-hx, y + 0.07, zc[0]), S_WHITE,
                   skip=("+X", "+Z"))
    hip_roof(h, -hx, hx, YB, YF, EAVE, 2.7)
    back_face(h, xs=(-2.6, 0.0, 2.6))
    return h


def report(wall, trim, ao):
    tw, tt = tri_count(wall), tri_count(trim)
    print("TRIS %s: Row_Wall=%d Row_Trim=%d total=%d" % (wall.name, tw, tt, tw + tt))
    for o in (wall, trim):
        xs = [v.co.x for v in o.data.vertices]
        ys = [v.co.y for v in o.data.vertices]
        zs = [v.co.z for v in o.data.vertices]
        # Godot: X = X, Y = Blender Z, Z = -Blender Y
        print("AABB Godot %-9s X[%.3f, %.3f] Y[%.3f, %.3f] Z[%.3f, %.3f]" % (
            o.name, min(xs), max(xs), min(zs), max(zs), -max(ys), -min(ys)))
    print("AO (min, medie, max):", ao)


_argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
_only = [a for a in _argv if a in HOUSES]
for _name, _cfg in HOUSES.items():
    if _only and _name not in _only:
        continue
    _top = WALL_TOP["corner" if _cfg.get("corner") else _cfg["roof"]]
    for _suffix in (("", "_m") if MIRRORED else ("",)):
        clear_built("Row_")
        _h = build_corner(_name) if _cfg.get("corner") else build_house(_name, **_cfg)
        if _suffix:
            mirror_house(_h)
        _wall, _trim, _ao = finish_house(
            _h, wall_ao=STYLE["wall_ao"],
            wall_z=(0.0 if STYLE["ground"] == "clapboard" else LEVEL, _top))
        report(_wall, _trim, _ao)
        _path, _size = export_glb([_wall, _trim], CATEGORY + _name + _suffix + ".glb")
        print("EXPORT", _path, _size)
        _bp, _bs = save_blend([_wall, _trim], _name + _suffix + ".blend")
        print("BLEND", _bp, _bs)
