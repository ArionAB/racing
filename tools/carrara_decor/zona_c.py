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
# muchie taiata drept direct in praf"). Conturul apei e masurat, nu desenat: ProbeCarraraHmap --sample pe 48
# de raze (P1: 24) din centrul fiecarei scobituri, la pas de 1 m, iar punctul de mal e unde plasa randata trece de
# cota apei (+0.35). Punctele se rarescu la 1.8-1.9 m (P1, nevazuta din cadrele lui C, la 6 m), iar piesa
# iese spre exterior cu 0.4-1.3 m, deci sta CALARE pe muchia poligonala a apei (grila de 7.92 m) si o acopera.
# Amestec neregulat (aleator cu samanta 23): moloz crem (rubble_pile_a/b la 0.75-1.15) si blocuri taiate
# mici (marble_block_a/b/c la 0.35-0.8; ~2/3 din piese, fiindca fetele lor de sus citesc CREM, iar
# molozul la scara mica citea gri-brun in capturile v1 ale rundei 2), yaw aleator. Coliziune "none": toate sunt la >= 9 m de asfalt, deci
# nu schimba nici ProbeRace, nici repunerea din balta. Cota: vezi KIT_Y (formula pentru malul in panta).
# (x, z, glb, scale, yaw relativ, balta)
_INEL = [
    (84.0, 40.6, "rocks/marble_block_a.glb", 0.48, 50, "P1"),
    (76.4, 39.2, "rocks/rubble_pile_a.glb", 0.86, 225, "P1"),
    (69.3, 34.5, "rocks/rubble_pile_a.glb", 0.88, 140, "P1"),
    (67.4, 26.0, "rocks/marble_block_a.glb", 0.37, 315, "P1"),
    (71.8, 19.0, "rocks/marble_block_a.glb", 0.72, 225, "P1"),
    (77.5, 14.7, "rocks/rubble_pile_a.glb", 0.76, 235, "P1"),
    (84.0, 9.5, "rocks/marble_block_b.glb", 0.69, 230, "P1"),
    (90.3, 15.2, "rocks/marble_block_a.glb", 0.5, 180, "P1"),
    (99.9, 15.9, "rocks/rubble_pile_a.glb", 0.78, 300, "P1"),
    (113.1, 33.0, "rocks/marble_block_a.glb", 0.74, 100, "P1"),
    (110.1, 40.0, "rocks/rubble_pile_b.glb", 0.91, 330, "P1"),
    (104.0, 43.4, "rocks/rubble_pile_b.glb", 0.83, 20, "P1"),
    (98.0, 47.7, "rocks/marble_block_a.glb", 0.39, 210, "P1"),
    (90.3, 46.4, "rocks/marble_block_a.glb", 0.43, 290, "P1"),
    (105.9, 19.2, "rocks/rubble_pile_a.glb", 0.78, 75, "P1"),
    (113.7, 23.9, "rocks/marble_block_a.glb", 0.39, 345, "P1"),
    (166.0, 26.0, "rocks/marble_block_c.glb", 0.47, 245, "P2"),
    (156.4, 36.7, "rocks/marble_block_a.glb", 0.36, 265, "P2"),
    (157.5, 39.2, "rocks/rubble_pile_b.glb", 0.88, 5, "P2"),
    (153.6, 38.1, "rocks/marble_block_c.glb", 0.59, 340, "P2"),
    (150.5, 37.9, "rocks/marble_block_a.glb", 0.53, 10, "P2"),
    (147.2, 37.7, "rocks/marble_block_a.glb", 0.56, 45, "P2"),
    (143.6, 37.0, "rocks/marble_block_b.glb", 0.64, 290, "P2"),
    (140.6, 37.4, "rocks/rubble_pile_a.glb", 0.78, 335, "P2"),
    (140.4, 34.9, "rocks/marble_block_b.glb", 0.59, 150, "P2"),
    (140.6, 32.6, "rocks/marble_block_a.glb", 0.77, 280, "P2"),
    (140.0, 29.3, "rocks/marble_block_b.glb", 0.55, 105, "P2"),
    (139.7, 26.0, "rocks/marble_block_b.glb", 0.55, 150, "P2"),
    (140.2, 22.8, "rocks/marble_block_a.glb", 0.59, 355, "P2"),
    (142.0, 20.2, "rocks/rubble_pile_b.glb", 0.9, 15, "P2"),
    (143.7, 17.7, "rocks/marble_block_a.glb", 0.67, 275, "P2"),
    (145.9, 15.4, "rocks/marble_block_a.glb", 0.36, 355, "P2"),
    (148.8, 13.8, "rocks/rubble_pile_b.glb", 1.11, 300, "P2"),
    (152.0, 12.5, "rocks/marble_block_a.glb", 0.39, 215, "P2"),
    (155.7, 12.0, "rocks/marble_block_c.glb", 0.47, 255, "P2"),
    (157.9, 15.8, "rocks/marble_block_b.glb", 0.49, 285, "P2"),
    (160.2, 17.8, "rocks/marble_block_a.glb", 0.41, 175, "P2"),
    (162.9, 19.7, "rocks/marble_block_b.glb", 0.58, 355, "P2"),
    (165.8, 20.3, "rocks/marble_block_a.glb", 0.58, 55, "P2"),
    (165.9, 22.3, "rocks/rubble_pile_b.glb", 1.11, 240, "P2"),
    (185.1, 39.0, "rocks/marble_block_b.glb", 0.6, 185, "P3"),
    (184.5, 42.3, "rocks/marble_block_a.glb", 0.74, 175, "P3"),
    (183.9, 45.8, "rocks/marble_block_a.glb", 0.62, 265, "P3"),
    (182.1, 49.1, "rocks/marble_block_b.glb", 0.64, 160, "P3"),
    (179.2, 51.5, "rocks/marble_block_b.glb", 0.55, 165, "P3"),
    (175.8, 52.9, "rocks/rubble_pile_b.glb", 0.93, 295, "P3"),
    (172.0, 53.2, "rocks/rubble_pile_a.glb", 0.98, 0, "P3"),
    (169.2, 49.4, "rocks/rubble_pile_a.glb", 1.01, 155, "P3"),
    (166.6, 48.4, "rocks/marble_block_b.glb", 0.57, 260, "P3"),
    (163.1, 47.9, "rocks/rubble_pile_a.glb", 0.86, 90, "P3"),
    (161.2, 47.3, "rocks/marble_block_c.glb", 0.48, 325, "P3"),
    (157.9, 44.8, "rocks/marble_block_b.glb", 0.52, 50, "P3"),
    (156.5, 43.2, "rocks/marble_block_b.glb", 0.6, 25, "P3"),
    (155.9, 41.2, "rocks/marble_block_a.glb", 0.38, 10, "P3"),
    (167.0, 26.9, "rocks/marble_block_b.glb", 0.68, 185, "P3"),
    (170.2, 25.5, "rocks/marble_block_b.glb", 0.59, 30, "P3"),
    (173.8, 25.3, "rocks/marble_block_b.glb", 0.6, 205, "P3"),
    (177.3, 26.3, "rocks/marble_block_a.glb", 0.55, 135, "P3"),
    (179.4, 26.2, "rocks/marble_block_a.glb", 0.6, 140, "P3"),
    (181.9, 26.0, "rocks/marble_block_a.glb", 0.42, 230, "P3"),
    (183.2, 27.8, "rocks/rubble_pile_a.glb", 0.92, 195, "P3"),
    (183.2, 30.4, "rocks/marble_block_b.glb", 0.69, 80, "P3"),
    (183.4, 32.4, "rocks/marble_block_a.glb", 0.4, 25, "P3"),
    (184.1, 35.7, "rocks/marble_block_a.glb", 0.56, 340, "P3"),
    (214.8, 48.0, "rocks/rubble_pile_a.glb", 0.88, 25, "P5"),
    (214.2, 50.4, "rocks/marble_block_a.glb", 0.75, 265, "P5"),
    (213.9, 53.1, "rocks/marble_block_a.glb", 0.36, 185, "P5"),
    (213.2, 56.2, "rocks/rubble_pile_b.glb", 1.09, 315, "P5"),
    (211.2, 58.8, "rocks/marble_block_a.glb", 0.69, 270, "P5"),
    (208.2, 59.9, "rocks/rubble_pile_a.glb", 0.88, 120, "P5"),
    (205.0, 59.9, "rocks/marble_block_a.glb", 0.52, 0, "P5"),
    (201.8, 60.1, "rocks/marble_block_a.glb", 0.52, 20, "P5"),
    (198.0, 60.1, "rocks/marble_block_a.glb", 0.78, 170, "P5"),
    (196.5, 56.5, "rocks/rubble_pile_b.glb", 1.14, 325, "P5"),
    (196.0, 53.2, "rocks/marble_block_c.glb", 0.59, 270, "P5"),
    (195.6, 50.5, "rocks/rubble_pile_b.glb", 1.02, 195, "P5"),
    (195.7, 48.0, "rocks/rubble_pile_b.glb", 0.98, 130, "P5"),
    (196.1, 45.6, "rocks/rubble_pile_a.glb", 0.85, 195, "P5"),
    (197.4, 43.6, "rocks/rubble_pile_a.glb", 0.9, 345, "P5"),
    (198.0, 41.0, "rocks/marble_block_b.glb", 0.53, 10, "P5"),
    (199.6, 38.6, "rocks/marble_block_b.glb", 0.65, 355, "P5"),
    (202.1, 36.9, "rocks/marble_block_b.glb", 0.69, 70, "P5"),
    (205.0, 36.7, "rocks/rubble_pile_a.glb", 0.83, 50, "P5"),
    (207.9, 37.3, "rocks/marble_block_a.glb", 0.36, 305, "P5"),
    (210.6, 38.3, "rocks/marble_block_b.glb", 0.58, 170, "P5"),
    (212.9, 40.1, "rocks/marble_block_a.glb", 0.69, 0, "P5"),
    (215.5, 41.9, "rocks/rubble_pile_a.glb", 0.97, 45, "P5"),
    (215.5, 45.2, "rocks/rubble_pile_b.glb", 1.09, 310, "P5"),
    (254.8, 63.0, "rocks/marble_block_b.glb", 0.49, 0, "P4"),
    (255.1, 65.5, "rocks/marble_block_a.glb", 0.51, 265, "P4"),
    (254.9, 68.1, "rocks/marble_block_b.glb", 0.48, 5, "P4"),
    (253.3, 70.3, "rocks/marble_block_b.glb", 0.58, 265, "P4"),
    (250.8, 71.4, "rocks/marble_block_a.glb", 0.64, 180, "P4"),
    (248.5, 72.6, "rocks/marble_block_b.glb", 0.66, 130, "P4"),
    (246.0, 72.0, "rocks/marble_block_a.glb", 0.37, 100, "P4"),
    (243.7, 71.6, "rocks/marble_block_b.glb", 0.69, 270, "P4"),
    (241.0, 71.7, "rocks/rubble_pile_a.glb", 0.8, 340, "P4"),
    (238.2, 70.8, "rocks/marble_block_b.glb", 0.67, 130, "P4"),
    (235.8, 68.9, "rocks/rubble_pile_a.glb", 0.93, 80, "P4"),
    (235.6, 65.8, "rocks/marble_block_a.glb", 0.52, 320, "P4"),
    (235.3, 63.0, "rocks/marble_block_a.glb", 0.74, 155, "P4"),
    (237.0, 60.6, "rocks/marble_block_b.glb", 0.56, 135, "P4"),
    (238.4, 58.6, "rocks/marble_block_b.glb", 0.51, 20, "P4"),
    (239.4, 56.4, "rocks/marble_block_a.glb", 0.36, 80, "P4"),
    (241.1, 54.5, "rocks/rubble_pile_b.glb", 1.0, 20, "P4"),
    (243.5, 53.6, "rocks/marble_block_a.glb", 0.52, 165, "P4"),
    (246.0, 53.2, "rocks/rubble_pile_a.glb", 0.96, 215, "P4"),
    (248.9, 52.2, "rocks/marble_block_c.glb", 0.59, 65, "P4"),
    (251.7, 53.2, "rocks/marble_block_b.glb", 0.54, 10, "P4"),
    (252.1, 55.2, "rocks/marble_block_a.glb", 0.49, 15, "P4"),
    (253.7, 57.1, "rocks/marble_block_a.glb", 0.4, 90, "P4"),
    (254.6, 59.5, "rocks/marble_block_c.glb", 0.57, 210, "P4"),
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
    "C_MolozPereteS2": 2.54, "C_InelP1_00": 0.31, "C_InelP1_01": -0.08, "C_InelP1_02": 0.23,
    "C_InelP1_03": 0.41, "C_InelP1_04": 0.3, "C_InelP1_05": 0.14, "C_InelP1_06": 0.33,
    "C_InelP1_07": 0.41, "C_InelP1_08": 0.14, "C_InelP1_09": 0.27, "C_InelP1_10": 0.28,
    "C_InelP1_11": 0.0, "C_InelP1_12": 0.47, "C_InelP1_13": 0.33, "C_InelP1_14": 0.19,
    "C_InelP1_15": 0.36, "C_InelP2_16": 0.29, "C_InelP2_17": 0.39, "C_InelP2_18": -0.02,
    "C_InelP2_19": 0.51, "C_InelP2_20": 0.66, "C_InelP2_21": 0.67, "C_InelP2_22": 0.26,
    "C_InelP2_23": -0.02, "C_InelP2_24": 0.36, "C_InelP2_25": 0.32, "C_InelP2_26": 0.53,
    "C_InelP2_27": 0.55, "C_InelP2_28": 0.48, "C_InelP2_29": -0.03, "C_InelP2_30": 0.55,
    "C_InelP2_31": 0.42, "C_InelP2_32": -0.02, "C_InelP2_33": 0.5, "C_InelP2_34": 0.36,
    "C_InelP2_35": 0.3, "C_InelP2_36": 0.51, "C_InelP2_37": 0.29, "C_InelP2_38": 0.34,
    "C_InelP2_39": 0.0, "C_InelP3_40": 0.49, "C_InelP3_41": 0.44, "C_InelP3_42": 0.57,
    "C_InelP3_43": 0.44, "C_InelP3_44": 0.31, "C_InelP3_45": 0.26, "C_InelP3_46": -0.08,
    "C_InelP3_47": -0.16, "C_InelP3_48": -0.05, "C_InelP3_49": -0.08, "C_InelP3_50": 0.36,
    "C_InelP3_51": 0.31, "C_InelP3_52": 0.42, "C_InelP3_53": 0.67, "C_InelP3_54": 0.07,
    "C_InelP3_55": 0.46, "C_InelP3_56": 0.54, "C_InelP3_57": 0.32, "C_InelP3_58": 0.38,
    "C_InelP3_59": 0.51, "C_InelP3_60": -0.11, "C_InelP3_61": 0.26, "C_InelP3_62": 0.47,
    "C_InelP3_63": 0.44, "C_InelP5_64": -0.09, "C_InelP5_65": 0.27, "C_InelP5_66": 0.45,
    "C_InelP5_67": -0.11, "C_InelP5_68": 0.5, "C_InelP5_69": 0.2, "C_InelP5_70": 0.5,
    "C_InelP5_71": 0.45, "C_InelP5_72": 0.34, "C_InelP5_73": -0.02, "C_InelP5_74": 0.23,
    "C_InelP5_75": -0.08, "C_InelP5_76": 0.03, "C_InelP5_77": -0.08, "C_InelP5_78": -0.1,
    "C_InelP5_79": 0.48, "C_InelP5_80": 0.17, "C_InelP5_81": 0.26, "C_InelP5_82": 0.18,
    "C_InelP5_83": 0.47, "C_InelP5_84": 0.34, "C_InelP5_85": 0.37, "C_InelP5_86": -0.06,
    "C_InelP5_87": 0.14, "C_InelP4_88": 0.34, "C_InelP4_89": 0.55, "C_InelP4_90": 0.58,
    "C_InelP4_91": 0.34, "C_InelP4_92": 0.23, "C_InelP4_93": 0.5, "C_InelP4_94": 0.58,
    "C_InelP4_95": 0.24, "C_InelP4_96": -0.05, "C_InelP4_97": 0.32, "C_InelP4_98": -0.12,
    "C_InelP4_99": 0.33, "C_InelP4_100": 0.38, "C_InelP4_101": 0.14, "C_InelP4_102": 0.22,
    "C_InelP4_103": 0.62, "C_InelP4_104": 0.08, "C_InelP4_105": 0.47, "C_InelP4_106": -0.13,
    "C_InelP4_107": 0.29, "C_InelP4_108": 0.3, "C_InelP4_109": 0.33, "C_InelP4_110": 0.34,
    "C_InelP4_111": 0.19, "C_ConPortal": 2.41, "C_ConTaietura": 1.57, "C_ConFund": 1.67,
    "C_ConCot1": 1.86, "C_BlocTaiat1": 1.48, "C_BlocTaiat2": 1.3, "C_BlocTaiat3": 1.7,
    "C_BlocPerete1": 1.67, "C_BlocPerete2": 1.67, "C_BlocPerete3": -47.57,
    # lampile nu ies in `--decor` (AABB nul dupa coacerea DecorManual, ca A_Lampa): terenul minim din
    # ProbeCarraraHmap --sample pe 3x3 puncte ale amprentei (1.6 x 1.5 m), minus 3 cm.
    "C_LampaGalerieD": 3.4, "C_LampaGalerieS": 4.22,
}
