# Decorul POI-ului C pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("C_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.

import csv as _csv
import math as _math
import os as _os

# Coordonate de LUME -> (frac, lateral, along) in conventia generatorului (`road_pt`: randul copt cu fractia
# cea mai apropiata, directia din vecinii i-1 / i+1, +X = dreapta). Inelele baltilor si grupul de la perete
# se scriu in lume (x, z Godot), fiindca le da conturul apei / piciorul peretelui, nu drumul.
_ROWS = [tuple(map(float, r.values())) for r in _csv.DictReader(open(
    _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "data", "carrara_baked.csv"),
    encoding="utf-8"))]


def _w(x, z, lo=0.28, hi=0.41):
    i = min((k for k in range(len(_ROWS)) if lo <= _ROWS[k][4] <= hi),
            key=lambda k: (_ROWS[k][0] - x) ** 2 + (_ROWS[k][2] - z) ** 2)
    j, k = min(i + 1, len(_ROWS) - 1), max(i - 1, 0)
    dx, dz = _ROWS[j][0] - _ROWS[k][0], _ROWS[j][2] - _ROWS[k][2]
    l_ = _math.hypot(dx, dz)
    fx, fz = dx / l_, dz / l_
    ox, oz = x - _ROWS[i][0], z - _ROWS[i][2]
    return _ROWS[i][4], ox * -fz + oz * fx, ox * fx + oz * fz, _math.degrees(_math.atan2(fz, fx))


def _world(name, glb, x, z, yaw_world=None, yaw_rel=0.0, **opt):
    """Piesa la (x, z) in lume. `yaw_world`: directia (grade, atan2(z, x)) in care sa arate -Z al piesei;
    altfel `yaw_rel` fata de drum. Optiunile merg ca in ITEMS (scale, coliziune, ...)."""
    fr, lat, along, head = _w(x, z)
    yaw = (head - yaw_world) if yaw_world is not None else yaw_rel
    opt["along"] = round(along, 2)
    return (name, glb, fr, round(lat, 2), round(yaw, 1), opt)


# Blocuri informe pe margini; totul sta la > 15 m de turnul derrick-ului (raza sarcinii 13 m).
ITEMS = [
    # Pe dreapta podeaua e plata (1.1-1.7) pana la 13 m; pe stanga peretele ravenei urca de la -10 m.
    # Blocurile stau la 12.5 m pe dreapta: la 8.5 m, C_Informe3 (0.375, iesirea din cotul 2 la
    # stanga, exteriorul e DREAPTA) a dat o ejectare-perete la 30 m/s pe ProbeRace (s5, ambele serii).
    # Pe stanga doar unde e INTERIORUL cotului (0.370, cotul 2); exteriorul cotului 1 (0.345) ramane gol.
    ("C_Informe1", "rocks/block_informe_a.glb", 0.298, 12.5, 20.0),
    ("C_Informe2", "rocks/block_informe_b.glb", 0.338, 12.5, -35.0),
    ("C_Informe3", "rocks/block_informe_a.glb", 0.375, 12.5, 50.0),
    ("C_Informe4", "rocks/block_informe_b.glb", 0.370, -8.8, 10.0),
    ("C_Informe5", "rocks/block_informe_b.glb", 0.352, 12.5, 50.0),

    # Ferastraul-lant pe senile (brief par.2 C: "taie la perete"): pe podeaua de +1.70 dintre balta P4 si
    # coltul peretelui de S (fata N-S de la x ~266-270, masurata cu ProbeCarraraHmap --sample). Lama e pe -Z
    # (Z -6.27 .. -2.18, inventarul crr-d), deci yaw 0 o duce spre E, in fata: corpul x 257.8-262.3, varful
    # lamei la x 266.3, unde peretele e deja la +6 (lama sta la +1.7 .. +3.3) -> ~1.3 m de lama in marmura.
    # Lat +20: departe de linia de cursa si de iesirea cotului 2. Cota: talpa senilelor e la +0.10 peste
    # origine (AABB masurat), deci KIT_Y = terenul minim - 0.03 - 0.10.
    # "along" 1.5: originea iese la x 259.0 pe indexul lui 0.3849 (nu 260), iar fara el doar ultimii 0.3 m ai
    # lamei atingeau piciorul peretelui (teren 2.6 la x 265, ProbeCarraraHmap --sample); cu 1.5 varful e la
    # x 266.7, unde peretele e la +7.6 -> ~1.5 m de lama in marmura.
    ("C_FerastrauLant", "vehicles/chain_saw_crawler.glb", 0.3849, 20.0, 0.0, {"along": 1.5}),
    # Moloz la piciorul taieturii, intre ferastrau si peretele de S (lat +14, peste pragul de 12.5).
    ("C_MolozTaietura", "rocks/rubble_pile_b.glb", 0.3878, 14.0, 30.0),

    # Gura galeriei cu lumini: doua lampi de santier de o parte si de alta a portalului (fata la x 290.1),
    # cu 3 m in fata lui, intoarse spre masinile care vin. Runda 2: lat +-11.5 (erau +-9), lipite de peretii
    # de langa rama, in afara gabaritului de intrare: ProbeRace r1 a dat o ejectare neexplicata in gura
    # portalului (0.398), iar lampile erau singura piesa noua din jur -> variabila scoasa din calcul.
    ("C_LampaGalerieD", "props/work_lamp.glb", 0.3985, 11.5, 180.0, {"along": -1.3}),
    ("C_LampaGalerieS", "props/work_lamp.glb", 0.3985, -11.5, 180.0, {"along": -1.3}),

    # Blocuri razlete pe podea (diorama: cuburi crem imprastiate intre balti).
    # Sirul de blocuri pe marginea dinspre balti a dreptei de sub derrick (diorama: cuburile de langa drum),
    # la lat +13.5 / +14 (pragul de 12.5 al lui C) si la > 15 m de turnul derrick-ului (generatorul verifica).
    ("C_MarginePodea1", "rocks/marble_block_c.glb", 0.3046, 13.5, 4.0),
    # (al doilea bloc, la 0.321 / lat +14, a scos o ejectare la 28 m/s pe ProbeRace s13: e interiorul de
    # dinaintea cotului 1, unde masinile taie peste podea. Scos.)
    ("C_BlocPodea1", "rocks/marble_block_b.glb", 0.3085, 24.0, 12.0),
    ("C_BlocPodea2", "rocks/marble_block_c.glb", 0.3714, 33.8, -30.0),
    ("C_BlocPodea3", "rocks/marble_block_a.glb", 0.3694, 30.3, 40.0),
    # Moloz la piciorul peretelui de N al dreptei spre portal (stanga, dupa iesirea din cotul 2).
    ("C_MolozPereteS1", "rocks/rubble_pile_a.glb", 0.3810, -11.0, 0.0),
    ("C_MolozPereteS2", "rocks/rubble_pile_b.glb", 0.3880, -10.5, 60.0),
]

# ---- RUNDA 2: INELELE DE CALCIT ale baltilor (criticul orb, runda 1: "malurile GOALE, apa se opreste cu o
# muchie taiata drept direct in praf"). Conturul apei e masurat, nu desenat: ProbeCarraraHmap --sample pe 24
# de raze din centrul fiecarei scobituri, la pas de 1 m, iar punctul de mal e unde plasa randata trece de
# cota apei (+0.35). Punctele se rarescu la 2.4-2.5 m (P1, nevazuta din cadrele lui C, la 3.6 m), iar piesa
# iese spre exterior cu 0-0.7 m, deci sta CALARE pe muchia poligonala a apei (grila de 7.92 m) si o acopera.
# Amestec neregulat (aleator cu samanta 23): moloz crem mic (rubble_pile_a/b la 0.5-0.9) si blocuri taiate
# mici (marble_block_a/b/c la 0.4-0.7), yaw aleator. Coliziune "none": toate sunt la >= 9 m de asfalt, deci
# nu schimba nici ProbeRace, nici repunerea din balta. Cota: vezi KIT_Y (formula pentru malul in panta).
# (x, z, glb, scale, yaw relativ, balta)
_INEL = [
    (84.0, 40.0, "rocks/marble_block_b.glb", 0.53, 50, "P1"),
    (76.6, 38.8, "rocks/rubble_pile_a.glb", 0.59, 225, "P1"),
    (73.2, 36.8, "rocks/rubble_pile_b.glb", 0.71, 140, "P1"),
    (69.4, 34.4, "rocks/marble_block_b.glb", 0.42, 315, "P1"),
    (68.0, 30.2, "rocks/rubble_pile_b.glb", 0.72, 225, "P1"),
    (67.8, 26.0, "rocks/rubble_pile_b.glb", 0.56, 235, "P1"),
    (69.2, 22.0, "rocks/rubble_pile_b.glb", 0.79, 230, "P1"),
    (72.1, 19.2, "rocks/marble_block_a.glb", 0.69, 180, "P1"),
    (77.8, 15.2, "rocks/rubble_pile_a.glb", 0.52, 300, "P1"),
    (80.5, 12.9, "rocks/rubble_pile_a.glb", 0.7, 100, "P1"),
    (84.0, 10.4, "rocks/rubble_pile_b.glb", 0.66, 330, "P1"),
    (88.1, 10.5, "rocks/rubble_pile_b.glb", 0.58, 20, "P1"),
    (90.0, 15.6, "rocks/marble_block_b.glb", 0.44, 210, "P1"),
    (93.9, 16.1, "rocks/marble_block_b.glb", 0.48, 290, "P1"),
    (99.8, 16.5, "rocks/rubble_pile_b.glb", 0.59, 75, "P1"),
    (113.0, 33.0, "rocks/marble_block_a.glb", 0.47, 345, "P1"),
    (110.5, 36.4, "rocks/rubble_pile_b.glb", 0.53, 245, "P1"),
    (107.3, 42.3, "rocks/marble_block_c.glb", 0.41, 265, "P1"),
    (101.3, 45.2, "rocks/rubble_pile_b.glb", 0.63, 5, "P1"),
    (98.0, 47.4, "rocks/marble_block_a.glb", 0.68, 340, "P1"),
    (94.1, 47.5, "rocks/rubble_pile_a.glb", 0.52, 10, "P1"),
    (90.2, 46.6, "rocks/rubble_pile_a.glb", 0.55, 45, "P1"),
    (84.9, 46.1, "rocks/rubble_pile_b.glb", 0.73, 290, "P1"),
    (105.8, 19.4, "rocks/rubble_pile_b.glb", 0.59, 335, "P1"),
    (107.1, 23.9, "rocks/rubble_pile_b.glb", 0.67, 150, "P1"),
    (113.0, 24.3, "rocks/rubble_pile_a.glb", 0.73, 280, "P1"),
    (114.3, 28.7, "rocks/rubble_pile_b.glb", 0.62, 105, "P1"),
    (166.1, 26.0, "rocks/rubble_pile_b.glb", 0.62, 150, "P2"),
    (154.9, 37.0, "rocks/rubble_pile_a.glb", 0.57, 355, "P2"),
    (152.0, 37.2, "rocks/rubble_pile_b.glb", 0.65, 15, "P2"),
    (149.1, 36.9, "rocks/rubble_pile_a.glb", 0.64, 275, "P2"),
    (145.9, 36.6, "rocks/marble_block_c.glb", 0.41, 355, "P2"),
    (141.1, 36.9, "rocks/rubble_pile_b.glb", 0.86, 300, "P2"),
    (140.6, 32.6, "rocks/marble_block_c.glb", 0.43, 215, "P2"),
    (140.8, 29.0, "rocks/marble_block_a.glb", 0.44, 255, "P2"),
    (140.7, 26.0, "rocks/rubble_pile_b.glb", 0.55, 285, "P2"),
    (140.6, 22.9, "rocks/marble_block_c.glb", 0.44, 175, "P2"),
    (142.5, 20.5, "rocks/rubble_pile_b.glb", 0.66, 355, "P2"),
    (144.3, 18.3, "rocks/rubble_pile_b.glb", 0.58, 55, "P2"),
    (146.1, 15.8, "rocks/rubble_pile_b.glb", 0.86, 240, "P2"),
    (148.9, 14.3, "rocks/rubble_pile_b.glb", 0.68, 185, "P2"),
    (152.0, 13.2, "rocks/rubble_pile_a.glb", 0.7, 175, "P2"),
    (155.7, 12.1, "rocks/rubble_pile_a.glb", 0.6, 265, "P2"),
    (157.9, 15.8, "rocks/rubble_pile_b.glb", 0.73, 160, "P2"),
    (159.7, 18.3, "rocks/rubble_pile_b.glb", 0.62, 165, "P2"),
    (162.7, 19.8, "rocks/rubble_pile_b.glb", 0.68, 295, "P2"),
    (166.0, 22.3, "rocks/rubble_pile_b.glb", 0.82, 0, "P2"),
    (184.6, 39.0, "rocks/rubble_pile_b.glb", 0.85, 155, "P3"),
    (184.0, 42.2, "rocks/rubble_pile_b.glb", 0.64, 260, "P3"),
    (183.3, 45.5, "rocks/rubble_pile_b.glb", 0.68, 90, "P3"),
    (181.6, 48.6, "rocks/marble_block_a.glb", 0.45, 325, "P3"),
    (178.9, 51.0, "rocks/rubble_pile_b.glb", 0.59, 50, "P3"),
    (175.5, 52.1, "rocks/rubble_pile_b.glb", 0.68, 25, "P3"),
    (172.0, 52.6, "rocks/marble_block_b.glb", 0.43, 10, "P3"),
    (169.5, 48.4, "rocks/rubble_pile_b.glb", 0.78, 185, "P3"),
    (166.9, 47.8, "rocks/rubble_pile_b.glb", 0.67, 30, "P3"),
    (163.5, 47.5, "rocks/rubble_pile_b.glb", 0.68, 205, "P3"),
    (160.4, 45.7, "rocks/rubble_pile_a.glb", 0.54, 135, "P3"),
    (157.3, 43.0, "rocks/rubble_pile_a.glb", 0.58, 140, "P3"),
    (157.2, 39.3, "rocks/marble_block_a.glb", 0.53, 230, "P3"),
    (168.6, 26.4, "rocks/rubble_pile_b.glb", 0.75, 195, "P3"),
    (172.0, 26.1, "rocks/rubble_pile_b.glb", 0.79, 80, "P3"),
    (175.5, 26.2, "rocks/marble_block_c.glb", 0.43, 25, "P3"),
    (179.3, 26.5, "rocks/rubble_pile_a.glb", 0.55, 340, "P3"),
    (182.6, 28.4, "rocks/rubble_pile_a.glb", 0.61, 25, "P3"),
    (183.0, 32.7, "rocks/rubble_pile_a.glb", 0.71, 265, "P3"),
    (183.5, 35.9, "rocks/marble_block_c.glb", 0.4, 185, "P3"),
    (214.6, 48.0, "rocks/rubble_pile_b.glb", 0.84, 315, "P5"),
    (213.8, 53.1, "rocks/rubble_pile_b.glb", 0.69, 270, "P5"),
    (213.1, 56.1, "rocks/rubble_pile_b.glb", 0.7, 120, "P5"),
    (210.8, 58.1, "rocks/rubble_pile_a.glb", 0.52, 0, "P5"),
    (207.9, 59.1, "rocks/rubble_pile_a.glb", 0.51, 20, "P5"),
    (205.0, 59.2, "rocks/rubble_pile_a.glb", 0.74, 170, "P5"),
    (201.8, 59.8, "rocks/rubble_pile_b.glb", 0.89, 325, "P5"),
    (198.3, 59.7, "rocks/marble_block_a.glb", 0.68, 270, "P5"),
    (197.0, 56.0, "rocks/rubble_pile_b.glb", 0.77, 195, "P5"),
    (196.6, 52.8, "rocks/rubble_pile_b.glb", 0.73, 130, "P5"),
    (196.0, 50.4, "rocks/rubble_pile_b.glb", 0.67, 195, "P5"),
    (196.7, 45.8, "rocks/rubble_pile_b.glb", 0.72, 345, "P5"),
    (198.4, 41.4, "rocks/rubble_pile_b.glb", 0.6, 10, "P5"),
    (199.8, 39.0, "rocks/rubble_pile_b.glb", 0.74, 355, "P5"),
    (202.2, 37.3, "rocks/rubble_pile_b.glb", 0.78, 70, "P5"),
    (205.0, 37.2, "rocks/rubble_pile_a.glb", 0.56, 50, "P5"),
    (207.7, 37.8, "rocks/marble_block_c.glb", 0.4, 305, "P5"),
    (210.3, 38.8, "rocks/rubble_pile_b.glb", 0.65, 170, "P5"),
    (212.5, 40.5, "rocks/rubble_pile_a.glb", 0.66, 0, "P5"),
    (215.0, 42.2, "rocks/rubble_pile_b.glb", 0.81, 45, "P5"),
    (215.0, 45.3, "rocks/rubble_pile_b.glb", 0.84, 310, "P5"),
    (254.4, 63.0, "rocks/rubble_pile_b.glb", 0.54, 0, "P4"),
    (254.3, 67.8, "rocks/rubble_pile_a.glb", 0.51, 265, "P4"),
    (253.1, 70.1, "rocks/rubble_pile_b.glb", 0.54, 5, "P4"),
    (250.7, 71.2, "rocks/rubble_pile_b.glb", 0.65, 265, "P4"),
    (248.3, 71.6, "rocks/rubble_pile_a.glb", 0.61, 180, "P4"),
    (243.7, 71.5, "rocks/rubble_pile_b.glb", 0.75, 130, "P4"),
    (238.7, 70.3, "rocks/marble_block_a.glb", 0.43, 100, "P4"),
    (236.7, 68.4, "rocks/rubble_pile_b.glb", 0.79, 270, "P4"),
    (235.5, 65.8, "rocks/rubble_pile_b.glb", 0.61, 340, "P4"),
    (235.6, 63.0, "rocks/rubble_pile_b.glb", 0.77, 130, "P4"),
    (237.0, 60.6, "rocks/rubble_pile_b.glb", 0.76, 80, "P4"),
    (239.9, 56.9, "rocks/rubble_pile_a.glb", 0.52, 320, "P4"),
    (243.7, 54.4, "rocks/rubble_pile_a.glb", 0.7, 155, "P4"),
    (248.7, 52.8, "rocks/rubble_pile_b.glb", 0.63, 135, "P4"),
    (251.3, 53.7, "rocks/rubble_pile_b.glb", 0.57, 20, "P4"),
    (252.8, 56.2, "rocks/marble_block_c.glb", 0.41, 80, "P4"),
    (254.5, 58.1, "rocks/rubble_pile_b.glb", 0.75, 20, "P4"),
]
ITEMS += [_world("C_Inel%s_%02d" % (b_, k), g_, x_, z_, yaw_rel=float(y_), scale=sc_, coliziune="none")
          for k, (x_, z_, g_, sc_, y_, b_) in enumerate(_INEL)]

# ---- RUNDA 2: PICIORUL PERETILOR (criticul: "podeaua se lipeste curat de perete") si GRUPUL DE LUCRU al
# ferastraului ("un punct pierdut in fund"). Conurile de grohotis (`scree_cone`, Transfagarasan, pe
# carrara_marble in CLASSES_CARRARA, jumatate de con cu latura +Z PLANA) au latura plana lipita de perete:
# -Z (yaw_world) arata DINSPRE perete spre podea. Blocurile taiate langa ferastrau = ce a taiat el.
# Coliziune "none" peste tot (cel mai apropiat, conul de la portal, e la 3.5 m de asfalt si nu are corp).
ITEMS += [
    # peretele de S, la E de ferastrau (fata E-V de la z ~48, x >= 272), langa lampa din dreapta
    _world("C_ConPortal", "res://assets/models/transfagarasan/rocks/scree_cone.glb", 276.0, 46.0, yaw_world=-90.0,
           scale=0.6, coliziune="none"),
    # coltul N-S de langa varful lamei (x ~266-268, z 57-65): conul de la taietura
    _world("C_ConTaietura", "res://assets/models/transfagarasan/rocks/scree_cone.glb", 263.0, 61.5, yaw_world=180.0,
           scale=0.6, coliziune="none"),
    # peretele de S din fundul cadrului 0.36 (z ~70, x 176-264)
    _world("C_ConFund", "res://assets/models/transfagarasan/rocks/scree_cone.glb", 222.0, 67.5, yaw_world=-90.0,
           scale=0.75, coliziune="none"),
    # peretele din fata cadrului 0.33 (exteriorul cotului 1, fata la x ~209-214): fara corp, deci fara efect pe linie
    _world("C_ConCot1", "res://assets/models/transfagarasan/rocks/scree_cone.glb", 207.5, 2.5, yaw_world=180.0,
           scale=0.6, coliziune="none"),
    # blocurile taiate de ferastrau, intre el si balta P4
    _world("C_BlocTaiat1", "rocks/marble_block_c.glb", 259.5, 60.8, yaw_rel=2.0, coliziune="none"),
    _world("C_BlocTaiat2", "rocks/marble_block_b.glb", 257.5, 64.5, yaw_rel=-8.0, coliziune="none"),
    _world("C_BlocTaiat3", "rocks/marble_block_a.glb", 263.0, 52.5, yaw_rel=12.0, coliziune="none"),
    # blocuri taiate la piciorul peretelui din fund, langa conul lui
    _world("C_BlocPerete1", "rocks/marble_block_b.glb", 229.0, 68.5, yaw_rel=20.0, coliziune="none"),
    _world("C_BlocPerete2", "rocks/marble_block_a.glb", 215.5, 66.0, yaw_rel=-15.0, coliziune="none"),
    _world("C_BlocPerete3", "rocks/marble_block_c.glb", 282.5, 48.0, yaw_rel=0.0, scale=0.8, coliziune="none"),
]

KIT_Y = {
    # Toate: terenul minim de sub amprenta (ProbeCarraraMontaj --decor, 9 puncte pe AABB) - 0.03. Ferastraul
    # inca -0.10 (talpa senilelor). INELELE stau calare pe mal: pe AABB-ul lor terenul minim e fundul baltii,
    # deci baza se ridica pana la max(teren minim - 0.03, apa 0.35 - jumatate din inaltimea piesei) ->
    # jumatate sub oglinda opaca, nimic deasupra apei in aer, iar partea de pe mal (teren >= 0.35) ramane
    # oricum peste baza.
    "C_Informe1": 1.05, "C_Informe2": 1.63, "C_Informe3": 1.39, "C_Informe4": 1.66,
    "C_Informe5": 1.59, "C_FerastrauLant": 1.51, "C_MolozTaietura": 1.73, "C_MarginePodea1": 0.9,
    "C_BlocPodea1": 0.58, "C_BlocPodea2": 1.67, "C_BlocPodea3": 1.67, "C_MolozPereteS1": 2.5,
    "C_MolozPereteS2": 2.54, "C_InelP1_00": 0.28, "C_InelP1_01": -0.07, "C_InelP1_02": 0.25,
    "C_InelP1_03": 0.32, "C_InelP1_04": 0.19, "C_InelP1_05": 0.26, "C_InelP1_06": 0.03,
    "C_InelP1_07": 0.26, "C_InelP1_08": 0.17, "C_InelP1_09": 0.21, "C_InelP1_10": 0.27,
    "C_InelP1_11": 0.28, "C_InelP1_12": 0.27, "C_InelP1_13": 0.21, "C_InelP1_14": 0.26,
    "C_InelP1_15": 0.3, "C_InelP1_16": 0.2, "C_InelP1_17": 0.3, "C_InelP1_18": 0.06,
    "C_InelP1_19": 0.36, "C_InelP1_20": 0.28, "C_InelP1_21": 0.16, "C_InelP1_22": 0.2,
    "C_InelP1_23": 0.24, "C_InelP1_24": 0.12, "C_InelP1_25": 0.12, "C_InelP1_26": 0.27,
    "C_InelP2_27": 0.23, "C_InelP2_28": -0.06, "C_InelP2_29": 0.05, "C_InelP2_30": -0.11,
    "C_InelP2_31": 0.15, "C_InelP2_32": -0.12, "C_InelP2_33": 0.3, "C_InelP2_34": 0.27,
    "C_InelP2_35": 0.07, "C_InelP2_36": 0.22, "C_InelP2_37": -0.05, "C_InelP2_38": 0.0,
    "C_InelP2_39": -0.17, "C_InelP2_40": 0.17, "C_InelP2_41": -0.07, "C_InelP2_42": 0.16,
    "C_InelP2_43": -0.06, "C_InelP2_44": -0.02, "C_InelP2_45": 0.1, "C_InelP2_46": 0.12,
    "C_InelP3_47": 0.09, "C_InelP3_48": 0.05, "C_InelP3_49": 0.03, "C_InelP3_50": 0.34,
    "C_InelP3_51": -0.0, "C_InelP3_52": 0.12, "C_InelP3_53": 0.4, "C_InelP3_54": -0.12,
    "C_InelP3_55": -0.05, "C_InelP3_56": -0.06, "C_InelP3_57": -0.03, "C_InelP3_58": -0.03,
    "C_InelP3_59": 0.13, "C_InelP3_60": -0.1, "C_InelP3_61": -0.12, "C_InelP3_62": 0.15,
    "C_InelP3_63": -0.05, "C_InelP3_64": -0.09, "C_InelP3_65": -0.16, "C_InelP3_66": 0.14,
    "C_InelP5_67": -0.15, "C_InelP5_68": 0.17, "C_InelP5_69": 0.05, "C_InelP5_70": -0.02,
    "C_InelP5_71": 0.1, "C_InelP5_72": -0.18, "C_InelP5_73": -0.04, "C_InelP5_74": 0.23,
    "C_InelP5_75": -0.03, "C_InelP5_76": -0.02, "C_InelP5_77": -0.01, "C_InelP5_78": -0.08,
    "C_InelP5_79": 0.1, "C_InelP5_80": -0.08, "C_InelP5_81": 0.07, "C_InelP5_82": 0.2,
    "C_InelP5_83": 0.35, "C_InelP5_84": 0.1, "C_InelP5_85": -0.13, "C_InelP5_86": 0.01,
    "C_InelP5_87": 0.05, "C_InelP4_88": 0.05, "C_InelP4_89": 0.05, "C_InelP4_90": 0.16,
    "C_InelP4_91": -0.04, "C_InelP4_92": -0.09, "C_InelP4_93": -0.1, "C_InelP4_94": 0.31,
    "C_InelP4_95": -0.12, "C_InelP4_96": 0.13, "C_InelP4_97": -0.05, "C_InelP4_98": -0.11,
    "C_InelP4_99": -0.02, "C_InelP4_100": -0.15, "C_InelP4_101": 0.07, "C_InelP4_102": 0.12,
    "C_InelP4_103": 0.22, "C_InelP4_104": 0.01, "C_ConPortal": 2.41, "C_ConTaietura": 1.57,
    "C_ConFund": 1.67, "C_ConCot1": 1.86, "C_BlocTaiat1": 1.48, "C_BlocTaiat2": 1.3,
    "C_BlocTaiat3": 1.7, "C_BlocPerete1": 1.67, "C_BlocPerete2": 1.67, "C_BlocPerete3": -47.57,
    # lampile nu ies in `--decor` (AABB nul dupa coacerea DecorManual, ca A_Lampa): terenul minim din
    # ProbeCarraraHmap --sample pe 3x3 puncte ale amprentei (1.6 x 1.5 m), minus 3 cm.
    "C_LampaGalerieD": 3.4, "C_LampaGalerieS": 4.22,
}
