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

Azi se construieste DOAR pilotul `sf_row_b_canted` (brief §9), in doua fisiere:
`sf_row_b_canted.glb` (garajul pe +X) si `sf_row_b_canted_m.glb` (pre-oglindit:
garajul pe -X, aceleasi doua noduri, transformari identitate; vezi `MIRRORED`).
Celelalte sase case se adauga ca intrari in `HOUSES` din aceleasi piese
(sf_row_shapes.py): vezi `build_house` si notele de la `HOUSES`.

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
"""

import os
import math

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "sf_row_shapes.py")).read())

CATEGORY = "sanfrancisco/buildings/"

# Casele kitului. Pilotul e singura intrare activa; restul se adauga aici cand
# pilotul e acceptat (brief §9). Ce ar cere fiecare:
#   sf_row_b_square   : bay="square" (bay_outline deja il stie), restul identic.
#   sf_row_a_canted/_square : roof="cornice_flat" — de scris `flat_cornice_roof`
#       (cornisa grea 0,7 x 0,45 cu console peste +9,6, acoperis plat ascuns),
#       ferestre cu "sprancene" (hood arcuit: `window(hood=...)` primeste o forma).
#   sf_row_c_canted/_square : roof="false_front" — atic drept pana la +10,8 in
#       fata acoperisului in panta; montanti verticali albi pe fatada (stick).
#   sf_row_corner_turret : alt gabarit (9 x 12, doua fatade) — `stone_base` si
#       `upper_walls` primesc latimea ca parametru; turnulet octogonal nou.
HOUSES = {
    "sf_row_b_canted": dict(bay_kind="canted", roof="gable"),
}

# Varianta PRE-OGLINDITA a fiecarei case (`<nume>_m.glb`: garajul pe -X, intrarea pe
# +X), din aceeasi geometrie (`mirror_house`). Pusa pe False, scriptul face doar
# varianta de baza.
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


def build_house(name, bay_kind="canted", roof="gable", st=None):
    st = st or STYLE
    h = House(name)
    clap = st["ground"] == "clapboard"
    # parter + fusta
    stone_base(h, niche=(NICHE_X, 1.4, 2.95), garage=(GARAGE_X, 2.6, 2.4),
               ground=st["ground"])
    garage_door(h, gx=GARAGE_X)
    entry_niche(h, nx=NICHE_X)
    belt_course(h, ht=st["belt_h"])
    z_belt = LEVEL + st["belt_h"]
    z_corn0 = st["frieze"][0] if st["frieze"] else st["cornice"][0]
    corner_boards(h, z_belt, z_corn0, w=st["corner_w"])
    # bovindoul
    fw = st["frame_w"]
    outline = bay_outline(bay_kind, BAY_XC, proj=0.8)
    bay(h, outline, z_slab=st["bay_slab"], z_mid=st["bay_mid"], z_corn=st["bay_corn"],
        post_w=st["bay_post_w"], fw=fw, corn_ao_row=clap)
    # peretii de scandura (+ frontoanele daca acoperisul e in doua ape)
    apex = 12.6
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
        hx = gw * 0.5 + fw + 0.075      # cornisa trece 0,075 de rame (v1: +-0,55)
        wall_box(h.trim, V(0, YF, 0), XP, YP, WIN_PAIR[0] - hx, WIN_PAIR[1] + hx,
                 0.0, 0.18, z0 + ht, z0 + ht + st["pair_hood_h"], S_WHITE)
    # cornisa + acoperis
    eave_cornice(h, z_frieze=st["frieze"], z_corn=st["cornice"],
                 modillions=(-3.15, -2.55, -1.95, -1.35))
    if roof == "gable":
        gable_roof(h, apex=apex, verge_h=st["verge_h"], band_part=st["gable_band_part"])
    else:
        raise NotImplementedError(roof + ": de construit dupa acceptarea pilotului")
    back_face(h)
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


for _name, _cfg in HOUSES.items():
    for _suffix in (("", "_m") if MIRRORED else ("",)):
        clear_built("Row_")
        _h = build_house(_name, **_cfg)
        if _suffix:
            mirror_house(_h)
        _wall, _trim, _ao = finish_house(
            _h, wall_ao=STYLE["wall_ao"],
            wall_z=(0.0 if STYLE["ground"] == "clapboard" else LEVEL, 12.45))
        report(_wall, _trim, _ao)
        _path, _size = export_glb([_wall, _trim], CATEGORY + _name + _suffix + ".glb")
        print("EXPORT", _path, _size)
        _bp, _bs = save_blend([_wall, _trim], _name + _suffix + ".blend")
        print("BLEND", _bp, _bs)
