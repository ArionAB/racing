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

# ---- MALUL BALTILOR, runda 3: GRAMEZI DE BLOCURI TAIATE (criticul r2: "blocurile sunt MICI si citesc
# gri-inchis / maro-ruginiu, ca niste cutii"; inelul r2 de 112 piese mici, 0.35-0.8, a iesit tocmai asa).
# Acum 2-4 gramezi pe fiecare balta (P1: 2, P2: 3, P3: 3, P5: 4, P4: 3), centrate pe punctele de MAL
# MASURATE (ProbeCarraraHmap --sample pe raze, plasa la cota apei +0.35) cele mai apropiate de drum (latura
# vazuta), la >= 9 m una de alta. Fiecare gramada: o piesa mare (block_stack_a/b la 0.75-1.0 sau
# marble_block_c la 1.0-1.2) cu 1.7 m spre mal, doua blocuri taiate (marble_block_a 1.0-1.4, marble_block_c
# 0.9-1.1) de o parte si de alta, si in 60% din cazuri moloz (rubble_pile_a 0.8-1.0) doar ca umplutura.
# Fara marble_block_b (dunga de vopsea portocalie citea "rugina" de la distanta). Samanta 31.
# Coliziune "none": cel mai apropiat mal e la lat +15 (P5), deci toate sunt la >= 10 m de asfalt.
# (x, z, glb, scale, yaw relativ, balta)
_GRAMEZI = [
    (88.5, 9.0, "rocks/block_stack_a.glb", 0.83, 25, "P1"),
    (90.6, 10.4, "rocks/marble_block_a.glb", 1.06, 70, "P1"),
    (85.8, 9.1, "rocks/marble_block_c.glb", 1.01, 85, "P1"),
    (92.2, 11.5, "rocks/rubble_pile_a.glb", 0.83, 20, "P1"),
    (98.0, 14.6, "rocks/marble_block_c.glb", 1.11, 285, "P1"),
    (100.4, 15.4, "rocks/marble_block_a.glb", 1.21, 130, "P1"),
    (95.4, 15.3, "rocks/marble_block_c.glb", 1.1, 55, "P1"),
    (93.8, 16.1, "rocks/rubble_pile_a.glb", 0.82, 255, "P1"),
    (156.0, 11.1, "rocks/block_stack_b.glb", 0.81, 155, "P2"),
    (158.1, 12.6, "rocks/marble_block_a.glb", 1.08, 135, "P2"),
    (153.3, 11.2, "rocks/marble_block_c.glb", 0.98, 350, "P2"),
    (159.7, 13.6, "rocks/rubble_pile_a.glb", 0.81, 30, "P2"),
    (166.9, 19.8, "rocks/block_stack_a.glb", 0.83, 240, "P2"),
    (166.9, 22.4, "rocks/marble_block_a.glb", 1.01, 335, "P2"),
    (165.1, 17.7, "rocks/marble_block_c.glb", 1.07, 135, "P2"),
    (163.9, 16.5, "rocks/rubble_pile_a.glb", 0.84, 275, "P2"),
    (145.3, 14.5, "rocks/marble_block_c.glb", 1.13, 140, "P2"),
    (147.9, 14.0, "rocks/marble_block_a.glb", 1.19, 165, "P2"),
    (143.5, 16.5, "rocks/marble_block_c.glb", 0.97, 210, "P2"),
    (149.7, 13.7, "rocks/rubble_pile_a.glb", 0.91, 305, "P2"),
    (182.4, 25.4, "rocks/marble_block_c.glb", 1.06, 135, "P3"),
    (183.8, 27.6, "rocks/marble_block_a.glb", 1.39, 60, "P3"),
    (179.9, 24.4, "rocks/marble_block_c.glb", 1.06, 195, "P3"),
    (184.9, 35.5, "rocks/block_stack_a.glb", 0.82, 120, "P3"),
    (184.7, 38.1, "rocks/marble_block_a.glb", 1.01, 235, "P3"),
    (183.5, 33.2, "rocks/marble_block_c.glb", 1.04, 60, "P3"),
    (184.6, 40.0, "rocks/rubble_pile_a.glb", 0.93, 180, "P3"),
    (184.3, 46.1, "rocks/block_stack_b.glb", 0.9, 125, "P3"),
    (182.3, 47.7, "rocks/marble_block_a.glb", 1.05, 125, "P3"),
    (184.9, 43.4, "rocks/marble_block_c.glb", 1.06, 280, "P3"),
    (214.7, 40.5, "rocks/block_stack_b.glb", 0.83, 75, "P5"),
    (215.5, 42.9, "rocks/marble_block_a.glb", 1.11, 75, "P5"),
    (212.5, 38.9, "rocks/marble_block_c.glb", 1.09, 125, "P5"),
    (205.0, 36.0, "rocks/block_stack_b.glb", 0.82, 315, "P5"),
    (207.4, 36.9, "rocks/marble_block_a.glb", 1.24, 325, "P5"),
    (202.4, 36.8, "rocks/marble_block_c.glb", 0.96, 235, "P5"),
    (200.8, 37.5, "rocks/rubble_pile_a.glb", 1.0, 310, "P5"),
    (214.8, 52.0, "rocks/marble_block_c.glb", 1.1, 315, "P5"),
    (213.1, 53.9, "rocks/marble_block_a.glb", 1.39, 15, "P5"),
    (215.1, 49.3, "rocks/marble_block_c.glb", 0.95, 300, "P5"),
    (215.0, 47.6, "rocks/rubble_pile_a.glb", 0.87, 5, "P5"),
    (196.5, 43.1, "rocks/block_stack_a.glb", 0.89, 25, "P5"),
    (198.5, 41.5, "rocks/marble_block_a.glb", 1.05, 30, "P5"),
    (195.9, 45.7, "rocks/marble_block_c.glb", 1.08, 130, "P5"),
    (199.9, 40.2, "rocks/rubble_pile_a.glb", 0.96, 190, "P5"),
    (250.9, 51.2, "rocks/marble_block_c.glb", 1.11, 325, "P4"),
    (252.7, 52.9, "rocks/marble_block_a.glb", 1.21, 320, "P4"),
    (248.2, 50.9, "rocks/marble_block_c.glb", 0.98, 335, "P4"),
    (254.2, 54.2, "rocks/rubble_pile_a.glb", 0.84, 295, "P4"),
    (240.7, 53.9, "rocks/block_stack_b.glb", 0.82, 85, "P4"),
    (243.3, 53.5, "rocks/marble_block_a.glb", 1.15, 330, "P4"),
    (238.9, 55.9, "rocks/marble_block_c.glb", 1.06, 120, "P4"),
    (255.9, 61.7, "rocks/block_stack_b.glb", 0.84, 105, "P4"),
    (255.4, 64.2, "rocks/marble_block_a.glb", 1.02, 75, "P4"),
    (254.8, 59.2, "rocks/marble_block_c.glb", 1.05, 130, "P4"),
]
ITEMS += [_world("C_Gramada%s_%02d" % (b_, k), g_, x_, z_, yaw_rel=float(y_), scale=sc_, coliziune="none")
          for k, (x_, z_, g_, sc_, y_, b_) in enumerate(_GRAMEZI)]

# ---- SIRUL DE BLOCURI CREM de pe marginea dreapta a drumului (criticul r2: "un sir continuu de cuburi crem
# pe marginea drumului"), in cadrul de la 0.36: intre drum si balta P5 (malul ei incepe la lat +15.3).
# Lat +13: e exteriorul cotului 2 (lectia C_Informe3, ejectare la 30 m/s la 8.5 m) -> >= 12.5 si fantoma,
# fiindca acolo o masina nu ajunge pe linie. Pas ~6 m (randurile coapte la >= 6 m), fara 0.350/0.353 unde
# sta deja C_Informe5 (0.352, lat 12.5, cu hull). Aliniate la drum: yaw 0/90 +- 4.
ITEMS += [
    ("C_Sir1", "rocks/marble_block_a.glb", 0.3462, 13.0, 3.0, {"scale": 1.2, "coliziune": "none"}),
    ("C_Sir2", "rocks/marble_block_c.glb", 0.3569, 13.0, 90.0, {"scale": 0.7, "coliziune": "none"}),
    ("C_Sir3", "rocks/marble_block_a.glb", 0.3607, 13.0, -4.0, {"scale": 1.1, "coliziune": "none"}),
    ("C_Sir4", "rocks/marble_block_c.glb", 0.3636, 13.0, 2.0, {"scale": 0.7, "coliziune": "none"}),
    ("C_Sir5", "rocks/marble_block_a.glb", 0.3675, 13.0, 86.0, {"scale": 1.25, "coliziune": "none"}),
    ("C_Sir6", "rocks/marble_block_c.glb", 0.3704, 13.0, 4.0, {"scale": 0.7, "coliziune": "none"}),
]

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
    # runda 3: stiva (marfa pregatita) in locul blocului mic de langa ferastrau
    _world("C_StivaTaietura", "rocks/block_stack_a.glb", 264.0, 52.5, yaw_rel=5.0, coliziune="none"),
    # runda 3: doua stive la peretele din fund, de o parte si de alta a conului (latimea lui e ~10 m pe x)
    _world("C_StivaFund1", "rocks/block_stack_b.glb", 211.0, 66.5, yaw_rel=-3.0, coliziune="none"),
    _world("C_StivaFund2", "rocks/block_stack_a.glb", 232.5, 67.0, yaw_rel=4.0, coliziune="none"),
    # blocuri taiate la piciorul peretelui din fund, langa conul lui
    _world("C_BlocPerete1", "rocks/marble_block_b.glb", 229.0, 68.5, yaw_rel=20.0, coliziune="none"),
    _world("C_BlocPerete2", "rocks/marble_block_a.glb", 215.5, 66.0, yaw_rel=-15.0, coliziune="none"),
    # la z 48 statea pe panta peretelui (3.1 -> 8.8 m pe 2.4 m) si `--decor` a dat cota -47.57 (raza pornea din
    # stanca): mutat la piciorul pantei, cota din ProbeCarraraHmap --sample (teren minim 2.9 - 0.03).
    _world("C_BlocPerete3", "rocks/marble_block_c.glb", 283.0, 45.8, yaw_rel=0.0, scale=0.8, coliziune="none"),
]

KIT_Y = {
    # Toate: terenul minim de sub amprenta (ProbeCarraraMontaj --decor, 9 puncte pe AABB) - 0.03. Ferastraul
    # inca -0.10 (talpa senilelor). INELELE stau calare pe mal: pe AABB-ul lor terenul minim e fundul baltii,
    # deci baza se ridica pana la max(teren minim - 0.03, apa 0.35 - un sfert din inaltimea piesei) ->
    # un sfert sub oglinda opaca, nimic deasupra apei in aer, iar partea de pe mal (teren >= 0.35) ramane
    # oricum peste baza.
    "C_Informe1": 1.05, "C_Informe2": 1.63, "C_Informe3": 1.39, "C_Informe4": 1.66,
    "C_Informe5": 1.59, "C_FerastrauLant": 1.51, "C_MolozTaietura": 1.73, "C_MarginePodea1": 0.9,
    "C_BlocPodea1": 0.58, "C_BlocPodea2": 1.67, "C_BlocPodea3": 1.67, "C_MolozPereteS1": 2.5,
    "C_MolozPereteS2": 2.54, "C_GramadaP1_00": 0.35, "C_GramadaP1_01": 0.4, "C_GramadaP1_02": 0.34,
    "C_GramadaP1_03": 0.45, "C_GramadaP1_04": 0.44, "C_GramadaP1_05": 0.38, "C_GramadaP1_06": 0.14,
    "C_GramadaP1_07": 0.05, "C_GramadaP2_08": 0.49, "C_GramadaP2_09": 0.36, "C_GramadaP2_10": 0.37,
    "C_GramadaP2_11": 0.6, "C_GramadaP2_12": 0.53, "C_GramadaP2_13": 0.54, "C_GramadaP2_14": 0.78,
    "C_GramadaP2_15": 0.85, "C_GramadaP2_16": 0.19, "C_GramadaP2_17": 0.31, "C_GramadaP2_18": 0.36,
    "C_GramadaP2_19": 0.02, "C_GramadaP3_20": 0.52, "C_GramadaP3_21": 0.41, "C_GramadaP3_22": 0.66,
    "C_GramadaP3_23": 0.57, "C_GramadaP3_24": 0.34, "C_GramadaP3_25": 0.08, "C_GramadaP3_26": 0.02,
    "C_GramadaP3_27": 0.55, "C_GramadaP3_28": 0.02, "C_GramadaP3_29": 0.27, "C_GramadaP5_30": 0.36,
    "C_GramadaP5_31": 0.35, "C_GramadaP5_32": 0.42, "C_GramadaP5_33": 0.45, "C_GramadaP5_34": 0.37,
    "C_GramadaP5_35": 0.16, "C_GramadaP5_36": -0.01, "C_GramadaP5_37": 0.26, "C_GramadaP5_38": -0.03,
    "C_GramadaP5_39": 0.23, "C_GramadaP5_40": 0.04, "C_GramadaP5_41": 0.53, "C_GramadaP5_42": 0.17,
    "C_GramadaP5_43": -0.03, "C_GramadaP5_44": 0.0, "C_GramadaP4_45": 0.32, "C_GramadaP4_46": 0.42,
    "C_GramadaP4_47": 0.44, "C_GramadaP4_48": 0.4, "C_GramadaP4_49": 0.5, "C_GramadaP4_50": 0.33,
    "C_GramadaP4_51": 0.11, "C_GramadaP4_52": 0.6, "C_GramadaP4_53": 0.45, "C_GramadaP4_54": -0.06,
    "C_Sir1": 1.59, "C_Sir2": 1.6, "C_Sir3": 1.54, "C_Sir4": 0.59,
    "C_Sir5": 1.17, "C_Sir6": 1.64, "C_ConPortal": 2.41, "C_ConTaietura": 1.57,
    "C_ConFund": 1.67, "C_ConCot1": 1.86, "C_BlocTaiat1": 1.48, "C_BlocTaiat2": 1.3,
    "C_StivaTaietura": 1.7, "C_StivaFund1": 1.67, "C_StivaFund2": 1.58, "C_BlocPerete1": 1.67,
    "C_BlocPerete2": 1.67, "C_BlocPerete3": 2.95,
    # lampile nu ies in `--decor` (AABB nul dupa coacerea DecorManual, ca A_Lampa): terenul minim din
    # ProbeCarraraHmap --sample pe 3x3 puncte ale amprentei (1.6 x 1.5 m), minus 3 cm.
    "C_LampaGalerieD": 3.4, "C_LampaGalerieS": 4.22,
}
