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
    # casele de capat (pasul 8c): fatada familiei pe -Z, latura -X finisata (`end_side`)
    "sf_row_end_a": dict(bay_kind="canted", roof="italianate", end=True),
    "sf_row_end_b": dict(bay_kind="canted", roof="gable", end=True),
    "sf_row_end_c": dict(bay_kind="canted", roof="false_front", end=True),
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


def build_house(name, bay_kind="canted", roof="gable", st=None, end=False):
    st = st or STYLE
    h = House(name)
    clap = st["ground"] == "clapboard"
    ital = roof == "italianate"
    # casa de capat: latura -X e fatada a doua (`end_side`), nu perete orb
    sides = (1,) if end else (-1, 1)
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
                    rows=(LEVEL, LEVEL + 0.4, 9.1, EAVE, A_CROWN[0]), side_top=A_CROWN[1],
                    sides=sides)
    elif roof == "false_front":
        upper_walls(h, outline[0].x, outline[-1].x, gable_apex=C_APEX - 0.15,
                    side_z0=0.0 if clap else None,
                    corn_z=None if st["frieze"] else st["cornice"][0],
                    gable_ends=(False, True), sides=sides)
    else:
        upper_walls(h, outline[0].x, outline[-1].x,
                    gable_apex=(apex - 0.15) if roof == "gable" else None,
                    side_z0=0.0 if clap else None,
                    corn_z=None if st["frieze"] else st["cornice"][0], sides=sides)
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
    if end:
        end_side(h, roof, st)
    return h


# --- Casele de capat (pasul 8c) -------------------------------------------------------
# Latura -X e o fatada a doua, mai linistita (fara bovindou, usa, garaj); `_m` o are pe +X.
# Ferestrele laterale (Blender Y): trei pe etaj, cu spatele casei (ultimii ~4 m: scara,
# bucataria) lasat plin; fereastra mica de parter intre a doua si a treia.
END_SIDE_Y = (3.75, 1.05, -1.65)
END_GROUND_Y = -0.3
END_MODILLIONS = tuple(5.6 - 1.2 * k for k in range(10))          # 5,6 .. -5,2
END_A_CONSOLES = tuple(5.45 - 0.95 * k for k in range(12))         # 5,45 .. -5,0
# Iesirile peste planul laturii, peste +9,0 (garda le cere exact): A coroana grea 0,45;
# B cornisa intoarsa 0,35; C cornisa intoarsa 0,35 (capacul aticului intors iese 0,10).
END_OVERHANG = {"italianate": 0.45, "gable": 0.35, "false_front": 0.35}


def end_side(h, roof, st):
    """Fatada laterala a casei de capat (pe -X), pe familia casei:
      A  ferestre cu sprancene arcuite; cornisa grea intoarsa (brau, console, coroana
         0,45) pe toata adancimea; zidul urca la +10,3 (ca aticul);
      B  ferestre cu cornisa mica; cornisa principala intoarsa (0,35, modilioane) si
         bordura alba pe muchia laterala a acoperisului;
      C  ca B, plus fatada falsa intoarsa 1,5 m pe latura (paravanul se opreste, iar
         acoperisul in panta se vede in spatele lui); bordura doar in spatele paravanului."""
    fw = st["frame_w"]
    z_belt = LEVEL + st["belt_h"]
    if roof == "italianate":
        rows = (0.0, LEVEL, LEVEL + 0.4, 9.1, EAVE, A_CROWN[0], A_CROWN[1])

        def hood(c, w, z_top):
            arched_hood(h, c, -YP, -XP, w + 0.08, z_top + 0.03, 0.18, 0.12, 0.16)
        board_top = EAVE
    else:
        zc = st["cornice"][0]
        rows = (0.0, LEVEL, LEVEL + 0.4, zc - 0.5, zc, EAVE)

        def hood(c, w, z_top):
            hx = w * 0.5 + 0.075
            wall_box(h.trim, c, -YP, -XP, -hx, hx, 0.0, 0.18, z_top, z_top + st["pair_hood_h"],
                     S_WHITE)
        board_top = zc
    side_facade(h, rows, END_SIDE_Y, PAIR_GLASS, fw, hood, z_belt, board_top, END_GROUND_Y,
                belt_h=st["belt_h"])
    if roof == "italianate":
        side_italianate_cornice(h, z_bed=(EAVE, EAVE + 0.1), z_crown=A_CROWN,
                                proud=END_OVERHANG[roof], consoles=END_A_CONSOLES)
        return
    side_eave_cornice(h, z_corn=st["cornice"], proud=END_OVERHANG[roof],
                      modillions=END_MODILLIONS)
    if roof == "gable":
        side_roof_fascia(h, EAVE, EAVE + 0.18, YB, YF + 0.4)
    else:
        side_false_front_return(h, back=1.5)
        side_roof_fascia(h, EAVE, EAVE + 0.18, YB, YF - 1.5)


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


# --- Casele pictate (K2, pasul 8c) ------------------------------------------------------
# Sase case BOGATE din acelasi vocabular, pe amprenta kitului (7,0 x 12,0, fatada la
# Godot Z = -6,0, podeaua la 0, fusta la -2,4, laturile oarbe: stau in rand), fiecare cu
# o combinatie DIFERITA de elemente-semnatura (T = turnulet cu acoperis conic, G2 = doua
# frontoane spre strada, TB = bovindou-turn care urca peste streasina, P = pridvor cu
# coloane, D = lucarna):
#   a  {T, P}       turnulet octogonal pe +X (din bovindou, de la +3,3) cu "palarie de
#                   vrajitoare" pana la +14,5; fronton pe -X; pridvor cu balcon pe -X
#   b  {G2, P}      doua frontoane egale, fiecare peste un bovindou (tesit +X, patrat -X);
#                   pridvor cu acoperis plat sub bovindoul de pe -X
#   c  {TB, P}      fronton mare pe +X peste bovindoul tesit; TURN PATRAT pe -X care urca
#                   1,9 m peste streasina, cu acoperis piramidal; pridvor cu fronton
#   d  {T, D}      acoperis in patru ape cu LUCARNA mare in mijloc; turnulet SUSPENDAT
#                   (de la +6,0, pe console) pe coltul -X; bovindou patrat pe +X; cos de fum;
#                   fara pridvor (intrarea in nisa, ca la kit)
#   e  {G2, TB, P}  bovindoul patrat de pe +X URCA IN FRONTON (frontonul pe fruntea lui, cu
#                   0,8 m in fata fatadei) + fronton mic, retras, pe -X; pridvor cu fronton;
#                   cos de fum
#   f  {T, D, P}    SIMETRICA: turnulet octogonal in mijloc, acoperis in doua ape cu coama
#                   paralela cu strada si doua lucarne pe apa din fata; pridvor central
# Doua tonuri fara cod nou: corpul e `Row_Wall` (slot 19, tentat pe instanta ca orice casa
# a kitului), iar ACCENTUL e un slot de atlas in `Row_Trim`, pe cateva elemente tari
# (benzile frontoanelor, panourile dintre etajele bovindourilor, coloanele pridvorului,
# coroana si varful turnurilor); restul ancadramentelor raman albe.
LADY_ACCENT = {"a": 31, "b": 11, "c": 12, "d": 1, "e": 10, "f": 25}
LADY_TOP = 12.45                      # varful peretilor pentru gradientul AO
SIN22 = math.sin(math.radians(22.5))
COS22 = math.cos(math.radians(22.5))


LADY_FRIEZE = (8.85, 9.35)            # friza de ACCENT de sub cornisa principala


def _lady_common(h, st, nx, holes, ground_xs, cornice_segs, acc):
    """Parterul (fusta, scandura, nisa intrarii cu scara in nisa, ferestre fara pervaz),
    braul, scandurile de colt, peretii cu goluri, friza de accent si cornisa principala pe
    segmente, spatele: tot ce au in comun cele sase case. Friza (8,85 -> 9,35, iesita
    0,025, intre scandurile de colt, pe portiunile de perete dintre bovindouri si turnuri)
    e banda colorata de sub cornisa a caselor pictate (decuparile a, b, d)."""
    fw = st["frame_w"]
    stone_base(h, niche=(nx, 1.4, 2.95), garage=None, ground=st["ground"])
    entry_niche(h, nx=nx)
    belt_course(h, ht=st["belt_h"])
    z_belt = LEVEL + st["belt_h"]
    corner_boards(h, z_belt, st["cornice"][0], w=st["corner_w"])
    lady_walls(h, holes)
    ground_windows(h, ground_xs, fw)
    lim = HX - st["corner_w"]
    cuts = sorted((a, b) for a, b, _z in holes)
    x = -lim
    for a, b in cuts + [(lim, lim)]:
        if a - x > 0.2:
            wall_box(h.trim, V(0, YF, 0), XP, YP, x, min(a, lim), 0.0, 0.025, LADY_FRIEZE[0],
                     LADY_FRIEZE[1], acc)
        x = max(x, b)
    for x0, x1 in cornice_segs:
        n = int((x1 - x0) / 0.6)
        mods = [x0 + 0.3 + 0.6 * k for k in range(n)] if n else []
        eave_cornice(h, z_frieze=None, z_corn=st["cornice"], x0=x0, x1=x1, modillions=mods)
    back_face(h)
    return fw, z_belt


def _turret_accent(h, m, acc, z_low, z_mid, z_crown):
    accent(h, m, acc, zr=(0.0, z_low))           # consola + talpa
    accent(h, m, acc, zr=(z_mid[0] - 0.05, z_mid[1] + 0.05))
    accent(h, m, acc, zr=(z_crown - 0.01, 30.0))  # coroana + varful
    accent(h, m, acc, tall=2.5)                  # montantii de pe muchiile dinspre strada


def _bay_accent(h, outline, st, acc, m):
    """Panourile dintre etaje, braul si montantii de pe muchiile bovindoului in culoarea de
    accent."""
    accent(h, m, acc, tall=2.5)
    spandrels(h, outline, 5.97, 6.73, acc)
    accent(h, m, acc, zr=(st["bay_mid"][0] - 0.05, st["bay_mid"][1] + 0.05))


def build_lady_a(h, st, acc):
    r, cx = 1.6, 1.88
    cy = YF - r * SIN22
    ring = octagon(cx, cy, r)
    tx0, tx1 = ring[3].x, ring[0].x
    nx = -1.95
    _lady_common(h, st, nx, [(tx0, tx1, 3.95)], (1.3, 2.45), [(-HX, tx0), (tx1, HX)], acc)
    m = mark(h)
    turret(h, cx, cy, V(cx, YF, 0), (("y", YF), ("y", YF)), r=r, outward=3, z_top=11.6,
           z_crown=(11.6, 11.85), cone_top=14.0, finial_top=14.5, top_win=(10.0, 1.05))
    _turret_accent(h, m, acc, 4.0, (6.25, 6.4), 11.6)
    pair_windows(h, (-2.55, -1.45))
    cross_gable(h, (-HX + tx0) * 0.5, tx0 + HX, 12.2, over=0.45, depth=3.4,
                bands=(9.72, 10.05, 11.42), band_slot=acc, window_at=(10.4, 0.7),
                finial_slot=acc)
    hip_roof(h, -HX, HX, YB, YF, EAVE, 3.0)
    porch(h, -3.4, -0.45, posts=(-3.28, -2.65, -1.25, -0.57), post_slot=acc, kind="balcony",
          accent_slot=acc, opening=(-2.55, -1.35))


def build_lady_b(h, st, acc):
    nx = -1.75
    ob = bay_outline("canted", 1.75, proj=0.8, front=1.6)
    os_ = bay_outline("square", -1.75, proj=0.8, width_sq=2.6)
    _lady_common(h, st, nx, [(ob[0].x, ob[-1].x, 3.95), (os_[0].x, os_[-1].x, 3.95)],
                 (1.15, 2.3), [(-HX, HX)], acc)
    fw = st["frame_w"]
    for o, wins in ((ob, [(0.34, 0), (1.05, 1), (0.34, 0)]),
                    (os_, [(0.26, 0), (1.45, 1), (0.26, 0)])):
        m = mark(h)
        bay(h, o, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=st["bay_corn"],
            post_w=st["bay_post_w"], fw=fw, corn_ao_row=True, windows=wins)
        _bay_accent(h, o, st, acc, m)
    for xc in (-1.75, 1.75):
        cross_gable(h, xc, 3.5, 12.4, over=0.45, depth=3.3, bands=(9.72, 10.05, 11.6),
                    band_slot=acc, window_at=(10.45, 0.7), finial_slot=acc)
    hip_roof(h, -HX, HX, YB, YF, EAVE, 3.2)
    porch(h, -3.4, -0.1, posts=(-3.28, -2.45, -1.05, -0.22), post_slot=acc, kind="flat",
          accent_slot=acc, opening=(-2.35, -1.15))


def build_lady_c(h, st, acc):
    nx = -2.05
    oc = bay_outline("canted", 1.45, proj=0.8, front=2.0)
    ot = bay_outline("square", -2.05, proj=0.8, width_sq=2.5)
    _lady_common(h, st, nx, [(oc[0].x, oc[-1].x, 3.95), (ot[0].x, ot[-1].x, 3.95)],
                 (1.0, 2.2), [(-HX, ot[0].x), (ot[-1].x, HX)], acc)
    fw = st["frame_w"]
    m = mark(h)
    bay(h, oc, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=st["bay_corn"],
        post_w=st["bay_post_w"], fw=fw, corn_ao_row=True,
        windows=[(0.36, 0), (1.35, 1), (0.36, 0)])
    _bay_accent(h, oc, st, acc, m)
    # turnul patrat: bovindoul (3,3 -> 9,6) + turnul peste streasina
    m = mark(h)
    bay(h, ot, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=(EAVE, EAVE),
        post_w=st["bay_post_w"], fw=fw, windows=[(0.26, 0), (1.30, 1), (0.26, 0)],
        cornice=False, post_top=EAVE - 0.25)
    _bay_accent(h, ot, st, acc, m)
    bay_band(h, ot, 0.06, st["cornice"][0], st["cornice"][1])
    m = mark(h)
    tower_top(h, ot[0].x, ot[-1].x, YF - 1.2, YF + 0.8, EAVE, 11.5, (11.5, 11.72), 13.9, acc,
              win=(9.95, 1.1, 0.6))
    cross_gable(h, 1.45, 4.1, 12.7, over=0.45, depth=3.8, bands=(9.72, 10.05, 10.38, 12.0),
                band_slot=acc, window_at=(10.75, 0.75), finial_slot=acc)
    hip_roof(h, -HX, HX, YB, YF, EAVE, 3.1)
    porch(h, -3.4, -0.65, posts=(-3.28, -2.75, -1.35, -0.77), post_slot=acc, kind="pediment",
          ped_apex=3.72, z_beam=(2.4, 2.6), z_roof=(2.6, 2.82), opening=(-2.65, -1.45))


def build_lady_d(h, st, acc):
    nx = -2.15
    r = 1.15
    cx = -HX + r * COS22 + 0.15        # banda de cornisa alunecata pe fatada iese 0,141
    cy = YF - r * SIN22
    ring = octagon(cx, cy, r)
    tx0, tx1 = ring[3].x, ring[0].x
    osq = bay_outline("square", 1.5, proj=0.8, width_sq=2.8)
    _lady_common(h, st, nx, [(tx0, tx1, 6.5), (osq[0].x, osq[-1].x, 3.95)], (0.85, 2.15),
                 [(-HX, tx0), (tx1, HX)], acc)
    fw = st["frame_w"]
    m = mark(h)
    bay(h, osq, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=st["bay_corn"],
        post_w=st["bay_post_w"], fw=fw, corn_ao_row=True,
        windows=[(0.28, 0), (1.55, 1), (0.28, 0)])
    _bay_accent(h, osq, st, acc, m)
    # turnuletul suspendat (de la +6,0) pe coltul -X
    m = mark(h)
    turret(h, cx, cy, V(cx, YF, 0), (("y", YF), ("y", YF)), r=r, outward=3, z_cons=6.0,
           z_slab=(6.35, 6.5), z_mid=(8.62, 8.72), z_top=11.3, z_crown=(11.3, 11.52),
           cone_top=14.1, finial_top=14.5, win_rows=((6.88, 1.59),), top_win=(9.9, 1.0),
           glass_w=0.4)
    _turret_accent(h, m, acc, 6.52, (8.62, 8.72), 11.3)
    # sub turnulet: o pereche la etajul 1; intre turnulet si bovindou: cate o fereastra
    pair_windows(h, (-2.85, -1.85), rows=((4.23, 1.59),))
    pair_windows(h, (-0.57,), glass=(0.55, PAIR_GLASS[1]), rows=((4.23, 1.59),))
    hip_roof(h, -HX, HX, YB, YF, EAVE, 2.8)
    dormer(h, V(0.55, 5.5, 0), XP, YP, 2.1, 9.85, 10.95, 11.75, 2.4, win=(0.75, 0.75),
           finial_slot=acc)
    chimney(h, 2.3, -1.6, 10.0, 12.45, wx=0.6, wy=0.45)


def build_lady_e(h, st, acc):
    nx = -1.9
    osq = bay_outline("square", 1.6, proj=0.8, width_sq=2.8)
    _lady_common(h, st, nx, [(osq[0].x, osq[-1].x, 3.95)], (1.15, 2.3),
                 [(-HX, osq[0].x), (osq[-1].x, HX)], acc)
    fw = st["frame_w"]
    m = mark(h)
    bay(h, osq, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=(EAVE, EAVE),
        post_w=st["bay_post_w"], fw=fw, windows=SQUARE_BAY_WINDOWS, cornice=False,
        post_top=9.2)
    _bay_accent(h, osq, st, acc, m)
    m = mark(h)
    bay_band(h, osq, 0.05, 9.2, EAVE)               # friza bovindoului, sub fronton
    accent(h, m, acc)
    # frontonul pe fruntea bovindoului (Blender Y = 6,8) + frontonul mic, retras, pe -X
    cross_gable(h, 1.6, 2.8, 12.3, y_face=YF + 0.8, over=0.28, depth=3.9, eave_over=0.15,
                bands=(9.72, 10.05, 11.75), band_slot=acc, window_at=(10.4, 0.75),
                finial_slot=acc)
    cross_gable(h, -1.85, 3.3, 11.6, over=0.40, depth=2.5, bands=(9.72, 10.95),
                band_slot=acc, window_at=(10.12, 0.6), finial_slot=acc, finial_h=0.75)
    pair_windows(h, (-2.6, -1.5))
    hip_roof(h, -HX, HX, YB, YF, EAVE, 3.3)
    porch(h, -3.4, -0.4, posts=(-3.28, -2.5, -1.3, -0.52), post_slot=acc, kind="pediment",
          ped_apex=3.85, opening=(-2.4, -1.4))
    chimney(h, -2.4, -1.5, 10.6, 13.4)


def build_lady_f(h, st, acc):
    r = 1.5
    cy = YF - r * SIN22
    ring = octagon(0.0, cy, r)
    tx0, tx1 = ring[3].x, ring[0].x
    _lady_common(h, st, 0.0, [(tx0, tx1, 3.95)], (-2.55, 2.55), [(-HX, tx0), (tx1, HX)], acc)
    m = mark(h)
    turret(h, 0.0, cy, V(0.0, YF, 0), (("y", YF), ("y", YF)), r=r, outward=3, z_top=11.9,
           z_crown=(11.9, 12.15), cone_top=14.1, finial_top=14.5, top_win=(10.25, 1.1))
    _turret_accent(h, m, acc, 4.0, (6.25, 6.4), 11.9)
    pair_windows(h, (-2.55,))
    pair_windows(h, (2.55,))
    side_gable_roof(h, y_ridge=0.0, apex=12.6, over_front=0.35)
    for xc in (-2.4, 2.4):
        dormer(h, V(xc, 5.45, 0), XP, YP, 1.5, 9.75, 10.8, 11.45, 3.2, win=(0.6, 0.7),
               finial_slot=acc)
    porch(h, -1.55, 1.55, posts=(-1.43, -0.72, 0.72, 1.43), post_slot=acc, kind="flat",
          accent_slot=acc, opening=(-0.62, 0.62))


LADIES = {"sf_painted_lady_%s" % k: (k, fn) for k, fn in (
    ("a", build_lady_a), ("b", build_lady_b), ("c", build_lady_c), ("d", build_lady_d),
    ("e", build_lady_e), ("f", build_lady_f))}


def build_lady(name, st=None):
    st = st or STYLE
    key, fn = LADIES[name]
    h = House(name)
    fn(h, st, LADY_ACCENT[key])
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
_only = [a for a in _argv if a in HOUSES or a in LADIES]
for _name, _cfg in list(HOUSES.items()) + [(k, dict(lady=True)) for k in LADIES]:
    if _only and _name not in _only:
        continue
    if _cfg.get("lady"):
        _top = LADY_TOP
    else:
        _top = WALL_TOP["corner" if _cfg.get("corner") else _cfg["roof"]]
    for _suffix in (("", "_m") if MIRRORED else ("",)):
        clear_built("Row_")
        if _cfg.get("lady"):
            _h = build_lady(_name)
        elif _cfg.get("corner"):
            _h = build_corner(_name)
        else:
            _h = build_house(_name, **_cfg)
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
