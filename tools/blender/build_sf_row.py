"""Kitul casei de rand victoriene (San Francisco, K1) — sursa reproductibila.

Contract: docs/asset_briefs/sf_painted_row_kit.md (§1-§10). Referinta de
caracter si culoare: docs/track_briefs/img/sf_assets_v1/sf_row_b_canted.png
(si _a_canted, _c_canted, _b_square pentru ce e comun kitului). Unde decuparea
si brief-ul nu se potrivesc pe STRUCTURA sau COTE, castiga brief-ul.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_row.py
    python tools/blender/verify_glb.py \\
        assets/models/sanfrancisco/buildings/sf_row_b_canted.glb 2500 --front=-Z

Azi se construieste DOAR pilotul `sf_row_b_canted` (brief §9). Celelalte sase
case se adauga ca intrari in `HOUSES` din aceleasi piese (sf_row_shapes.py):
vezi `build_house` si notele de la `HOUSES`.

Lista de elemente (acceptanta = lista asta, element cu element)
-------------------------------------------------------------------
 1. Amprenta 7,0 x 12,0 m; fatada la Godot Z = -6,0 (Blender +Y), spatele la
    +6,0; originea in centrul amprentei, la podeaua parterului (Y = 0).
 2. Fusta de beton (slot 8) de la 0 la -2,4, la fata peretilor, pe toate
    patru laturile; nu iese nici in fata, nici lateral.
 3. Parterul (0 -> 3,2) in piatra bej (slot 8), ca pe decupare: soclul
    garajului face corp comun cu fusta.
 4. Usa de garaj pe +X (2,6 x 2,4), adancita 0,12, cu 4 panouri orizontale
    in relief (slot 9) si ancadrament alb pe trei laturi.
 5. Intrarea adancita pe -X: nisa de 1,4 x 1,0, interior log_dark (28), usa
    1,0 x 2,3 cu fereastra deasupra (sticla 20), rama alba.
 6. Scara de 7 trepte IN nisa, de la 0 la -2,1, prin fusta (slot 8).
    Decuparea arata scara pe trotuar: NU (brief §3.1).
 7. Pilastri + antablament alb in jurul nisei (ies 0,07).
 8. Braul alb la +3,2 (0,25 inalt, iese 0,06).
 9. Scandurile albe de colt, verticale, la X +-3,42, de la brau la friza.
10. Peretii de scandura NETEZI (Row_Wall, slot 19): fatada etajelor,
    laturile ORBE, spatele, fetele bovindoului, frontoanele.
11. Bovindoul tesit pe +X, deasupra garajului, de la +3,3 la +9,35: fata de
    2,6, laturile la 45 de grade, iesit 0,9 in total (peretii la 0,8 +
    cornisa 0,1, ca AABB-ul sa se opreasca la Godot Z = -6,9).
12. Console albe sub bovindou (4, profil in trepte).
13. Talpa alba a bovindoului, braul dintre etaje pe bovindou, cornisa lui.
14. Ferestrele bovindoului: 3 fete x 2 etaje; rama alba, sticla adancita,
    traversa; fata din mijloc cu montant (doua ochiuri, ca pe decupare).
15. Montantii albi pe muchiile bovindoului.
16. Jumatatea -X a etajelor: doua ferestre inalte (0,95 x 1,85) pe etaj,
    pereche, cu rama, glaf adancit, cornisa mica comuna si pervaz.
    (Decuparea arata una singura: castiga brief-ul.)
17. Friza + cornisa principala (9,0 -> 9,6), iesita 0,35, fara depasire
    laterala, cu modilioane sub ea pe portiunea din afara bovindoului.
18. Frontonul triunghiular spre strada (+9,6 -> +12,45), pe scandura.
19. Acoperis in doua ape, ardezie (20), coama pe Godot Z la +12,6, iesit
    0,4 in fata peste fronton, 0 lateral si in spate.
20. Bordura alba (verge) pe muchiile inclinate ale frontonului.
21. Solzii frontonului: 4 benzi-pana in relief.
22. Fereastra mica in fronton, cu rama si pervaz.
23. Spatele: 6 ferestre plate (2 pe nivel) si banda de streasina alba.
24. Fara text, cifre, scara de incendiu, balustrade subtiri, ornamente sub
    0,08 m; fara felinar (optional in brief, lasat pentru dupa pilot).
25. Exact doua noduri: Row_Wall (doar slot 19, doar scandura) si Row_Trim
    (restul, pe sloturile din §5).
26. AO copt pe colturi: blând pe pereti (0,78 jos -> 1,0 sus, ~0,7 sub
    bovindou si cornisa), nisa ~0,55, geamuri ~0,6, fusta 0,7 -> 0,85.
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

# Asezarea pe fatada (X, Blender = Godot). Bovindoul si garajul pe +X.
BAY_XC = 1.15        # centrul bovindoului: A = -0.95, D = +3.25 (tesit)
GARAGE_X = 1.3       # garajul intreg pe jumatatea +X (0.0 -> 2.6)
NICHE_X = -2.15      # nisa intrarii si perechea de ferestre de deasupra ei
WIN_PAIR = (-2.675, -1.625)   # doua ferestre de 0,95, cu 0,10 intre ele


def build_house(name, bay_kind="canted", roof="gable"):
    h = House(name)
    # parter + fusta
    stone_base(h, niche=(NICHE_X, 1.4, 2.95), garage=(GARAGE_X, 2.6, 2.4))
    garage_door(h, gx=GARAGE_X)
    entry_niche(h, nx=NICHE_X)
    belt_course(h)
    corner_boards(h, 3.45, 9.0)
    # bovindoul
    outline = bay_outline(bay_kind, BAY_XC, proj=0.8)
    bay(h, outline)
    # peretii de scandura (+ frontoanele daca acoperisul e in doua ape)
    apex = 12.6
    upper_walls(h, outline[0].x, outline[-1].x,
                gable_apex=(apex - 0.15) if roof == "gable" else None)
    # perechea de ferestre inalte pe -X, pe doua etaje
    for z0 in (4.1, 6.75):
        for x in WIN_PAIR:
            window(h, V(x, YF, 0), XP, YP, z0, 0.95, 1.85, fw=0.13, proud=0.1,
                   hood=False, sill=True)
        wall_box(h.trim, V(0, YF, 0), XP, YP, WIN_PAIR[0] - 0.55, WIN_PAIR[1] + 0.55,
                 0.0, 0.18, z0 + 1.85, z0 + 1.85 + 0.18, S_WHITE)
    # cornisa + acoperis
    eave_cornice(h, modillions=(-3.15, -2.55, -1.95, -1.35))
    if roof == "gable":
        gable_roof(h, apex=apex)
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
    clear_built("Row_")
    _h = build_house(_name, **_cfg)
    _wall, _trim, _ao = finish_house(_h)
    report(_wall, _trim, _ao)
    _path, _size = export_glb([_wall, _trim], CATEGORY + _name + ".glb")
    print("EXPORT", _path, _size)
    _bp, _bs = save_blend([_wall, _trim], _name + ".blend")
    print("BLEND", _bp, _bs)
