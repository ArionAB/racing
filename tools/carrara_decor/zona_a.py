# Decorul POI-ului A pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("A_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.

# Coridorul de blocuri pe ambele parti, containerul, rezervorul, lampa. Coridorul din stanga se opreste
# inainte de iesirea camionului 1 (x > -50, lat -7 .. -34).
ITEMS = [
    ("A_StivaS1", "rocks/block_stack_b.glb", 0.012, -9.0, 3.0),
    ("A_BlocS2", "rocks/marble_block_c.glb", 0.018, -8.6, -4.0),
    ("A_StivaS3", "rocks/block_stack_a.glb", 0.024, -9.2, 5.0),
    ("A_StivaS4", "rocks/block_stack_b.glb", 0.031, -9.0, -2.0),
    ("A_BlocS5", "rocks/marble_block_b.glb", 0.036, -8.5, 7.0),
    ("A_StivaS6", "rocks/block_stack_a.glb", 0.042, -9.1, -5.0),
    ("A_StivaD1", "rocks/block_stack_a.glb", 0.014, 9.2, -3.0),
    ("A_StivaD2", "rocks/block_stack_b.glb", 0.021, 9.4, 4.0),
    ("A_BlocD3", "rocks/marble_block_c.glb", 0.027, 9.0, 2.0),
    ("A_StivaD4", "rocks/block_stack_b.glb", 0.034, 9.4, -6.0),
    ("A_StivaD5", "rocks/block_stack_a.glb", 0.040, 9.2, 3.0),
    ("A_Container", "buildings/office_container.glb", 0.004, -13.0, 90.0),
    ("A_Rezervor", "props/fuel_tank.glb", 0.0085, -12.5, 0.0),
    ("A_Lampa", "props/work_lamp.glb", 0.046, 9.5, 180.0),
    # ---- Runda 1 a gauntlet-ului (carrara_poi_gauntlet.md, contractul A). Platoul din stanga e PLAN
    # (+24,3..24,7 pana la -40 m, scanat cu `--scan=0,0.06,0.005,-40,40,4`), deci locuirea piazzale-ului
    # sta acolo, in spatele coridorului: turnul de piatra, magazia cu tabla, colțul de muzeu, cisternele
    # albastre. Totul la x < -50 (frac <= 0.041) si la >= 10 m de asfalt: grila si plutonul nu le ating.
    # Turnul de piatra patrat: casa de piatra a satului (tf_stone + ok_roof, deja pe pista: 0 materiale),
    # la 0,8 ca sa citeasca a cabana de cariera, nu a casa de sat.
    ("A_Turn", "buildings/colonnata_house_b.glb", 0.022, -27.0, -90.0, {"scale": 0.8}),
    # Magazia joasa: doua containere-birou cap la cap in lungul drumului (12 m, pereti bej, tabla gri), ca in
    # decupaj. Incercate in runda: stana (gardul de 14 x 10 m citea a tarc; din 0.03 se vedea doar gardul) si
    # baraca minerului (lemn maro + tabla ruginita, +2 materiale pe pista). Containerul are 0 materiale noi.
    ("A_MagazieA", "buildings/office_container.glb", 0.0295, -20.0, 90.0),
    ("A_MagazieB", "buildings/office_container.glb", 0.0325, -20.0, 90.0, {"along": 0.2}),
    # Coltul de muzeu in aer liber (Cava Museo Fantiscritti, brief §1): vagonetul cu bloc, roata de fir pe
    # suport (fata rotii spre drum), sania veche.
    ("A_MuzeuSanie", "props/museum_set_sled.glb", 0.0345, -17.5, 15.0, {"scale": 1.25}),
    ("A_MuzeuVagonet", "props/museum_set_cart.glb", 0.038, -16.0, 0.0, {"scale": 1.25}),
    ("A_MuzeuRoata", "props/museum_set_wheel.glb", 0.041, -17.0, 0.0, {"scale": 1.25}),
    # Rezervoarele albastre (in decupaj langa portalul Marmifera, care e IN SPATELE liniei de start).
    ("A_CisternaA", "props/water_tank.glb", 0.0140, -15.5, 0.0),
    ("A_CisternaB", "props/water_tank.glb", 0.0165, -18.0, 0.0),
    # Blocuri raslete pe platou, langa magazie.
    ("A_BlocP1", "rocks/marble_block_c.glb", 0.027, -16.0, 12.0),
    # Marginea dinspre gol: inca doua piese pe buza (lat 12,5), doar DUPA 0.025, unde e fata verticala:
    # pe 0.00-0.02 panta lina din dreapta e dezvaluirea de la start si ramane libera.
    ("A_BlocD6", "rocks/marble_block_c.glb", 0.0305, 11.0, 90.0),
    ("A_StivaD7", "rocks/block_stack_a.glb", 0.0435, 10.9, 8.0),
    # Liziera verde-galbena sub platou (dreapta). Castanii stau SUB fata de 10 m (baza +14..15), deci doar
    # coroana trece de buza; trunchi ca si coliziune (coroana nu e perete pentru masina care cade).
    ("A_Castan1", "res://assets/models/transfagarasan/plants/beech_tree_a.glb", 0.028, 21.0, 30.0,
     {"coliziune": "trunk"}),
    ("A_Castan2", "res://assets/models/transfagarasan/plants/beech_tree_b.glb", 0.036, 23.0, -40.0,
     {"coliziune": "trunk"}),
    ("A_Castan3", "res://assets/models/transfagarasan/plants/beech_tree_a.glb", 0.045, 21.0, 110.0,
     {"coliziune": "trunk"}),
    # Ginestra pe panta lina 0.00-0.02 (joasa: nu acopera vederea spre balti).
    ("A_Ginestra1", "res://assets/models/stromboli/plants/ginestra_bush.glb", 0.004, 17.0, 0.0, {"scale": 1.3}),
    ("A_Ginestra2", "res://assets/models/stromboli/plants/ginestra_bush.glb", 0.009, 19.0, 70.0, {"scale": 1.3}),
    ("A_Ginestra3", "res://assets/models/stromboli/plants/ginestra_bush.glb", 0.0135, 17.5, 140.0, {"scale": 1.3}),
    ("A_Ginestra4", "res://assets/models/stromboli/plants/ginestra_bush.glb", 0.0185, 18.0, 210.0, {"scale": 1.3}),
    ("A_Ginestra5", "res://assets/models/stromboli/plants/ginestra_bush.glb", 0.0055, 21.0, 280.0, {"scale": 1.3}),
]

KIT_Y = {
    "A_StivaS1": 24.65, "A_BlocS2": 24.64, "A_StivaS3": 24.63, "A_StivaS4": 24.62, "A_BlocS5": 24.63,
    "A_StivaS6": 24.62, "A_StivaD1": 24.67, "A_StivaD2": 24.67, "A_BlocD3": 24.67, "A_StivaD4": 24.67,
    "A_StivaD5": 24.67, "A_Container": 24.66, "A_Rezervor": 24.65, "A_Lampa": 24.67,
}
# Runda 1: cote din `--decor` (piesele cu mai multe noduri) si din `--under --scan=0,0.048,0.001,...` pe pas de
# 1 m (piesele coapte intr-un singur buffer nu apar in `--decor`). Castanii: terenul sub TRUNCHI (coroana
# acopera fata). Ginestra pe panta: minimul de sub tufa.
KIT_Y.update({
    "A_Turn": 24.42, "A_MagazieA": 24.37, "A_MagazieB": 24.37, "A_MuzeuSanie": 24.43, "A_MuzeuVagonet": 24.49, "A_MuzeuRoata": 24.45,
    "A_CisternaA": 24.55, "A_CisternaB": 24.47, "A_BlocP1": 24.49, "A_BlocD6": 24.67, "A_StivaD7": 24.67,
    "A_Castan1": 14.12, "A_Castan2": 14.72, "A_Castan3": 15.62,
    "A_Ginestra1": 24.20, "A_Ginestra2": 23.35, "A_Ginestra3": 23.00, "A_Ginestra4": 21.65, "A_Ginestra5": 23.55,
})
