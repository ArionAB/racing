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

ITEMS = [
    # Santierul de la start (era pe main): containerul-birou si rezervorul de motorina (rugina mata din
    # CLASSES_CARRARA, runda 2), lampa de lucru inaintea excavatorului.
    ('A_Container', 'buildings/office_container.glb', 0.004, -13.0, 90.0),
    ('A_Rezervor', 'props/fuel_tank.glb', 0.0085, -12.5, 0.0),
    ('A_Lampa', 'props/work_lamp.glb', 0.046, 9.5, 180.0),
    # RUNDA 2 (criticul orb: "camp gol presarat uniform cu cutii mici"): blocurile solitare echidistante ale
    # coridorului au iesit; marmura sta acum in GRAMEZI STRANSE de 6-8 piese, stive de 2-3 la scara 1,2-1,5,
    # blocuri informe cazute si moloz la picior, cu bej liber intre grupuri. Fata dinspre drum a gramezilor
    # ramane la ~9 m de ax (>= 3 m de asfalt), deci coridorul se citeste tot, dar in doua bucati.
    # Totul pe stanga la x < -50 (iesirea camionului 1).
    # Magazia: doua containere cap la cap, cu cele doua cisterne albastre la capatul dinspre start.
    ('A_MagazieA', 'buildings/office_container.glb', 0.0135, -25.0, 90.0),
    ('A_MagazieB', 'buildings/office_container.glb', 0.0135, -25.0, 90.0, {'along': 6.2}),
    ('A_CisternaA', 'props/water_tank.glb', 0.0135, -20.5, 0.0, {'along': -4.0}),
    ('A_CisternaB', 'props/water_tank.glb', 0.0135, -23.3, 0.0, {'along': -5.5}),
    # Gramada L1 (planul mijlociu stanga in cadrul de la 0.01).
    ('A_L1a', 'rocks/block_stack_b.glb', 0.02, -10.8, 4.0, {'along': 0.0, 'scale': 1.4}),
    ('A_L1b', 'rocks/block_stack_a.glb', 0.02, -11.0, -6.0, {'along': 3.3, 'scale': 1.3}),
    ('A_L1c', 'rocks/marble_block_c.glb', 0.02, -11.2, 90.0, {'along': -3.6, 'scale': 1.3}),
    ('A_L1d', 'rocks/block_stack_b.glb', 0.02, -14.4, 12.0, {'along': 1.0, 'scale': 1.2}),
    ('A_L1e', 'rocks/marble_block_a.glb', 0.02, -14.0, 25.0, {'along': -2.5, 'scale': 1.2}),
    ('A_L1f', 'rocks/block_informe_a.glb', 0.02, -14.6, 40.0, {'along': 4.6}),
    ('A_L1g', 'rocks/rubble_pile_b.glb', 0.02, -17.4, 0.0, {'along': -1.0}),
    ('A_L1h', 'rocks/block_informe_b.glb', 0.02, -9.8, -20.0, {'along': 5.9}),
    # Utilajele: coltul de muzeu la scara mare (roata de fir 3,2 m, vagonetul cu bloc) la piciorul gramezii L1,
    # pe partea dinspre start (in spatele ei nu se vedeau din 0.01), si masina de forat (utilajul mare de lucru)
    # la stanga lui L1, in afara umbrei ei din cadrul de la 0.01.
    ('A_Foreza', 'vehicles/drill_rig.glb', 0.027, -28.0, 30.0),
    ('A_MuzeuRoata', 'props/museum_set_wheel.glb', 0.0155, -14.0, 55.0, {'scale': 1.6}),
    ('A_MuzeuVagonet', 'props/museum_set_cart.glb', 0.0155, -16.5, 20.0, {'along': 3.5, 'scale': 1.6}),
    # Gramada L2.
    ('A_L2a', 'rocks/block_stack_a.glb', 0.035, -11.0, -3.0, {'along': 0.0, 'scale': 1.5}),
    ('A_L2b', 'rocks/block_stack_b.glb', 0.035, -11.0, 7.0, {'along': -3.4, 'scale': 1.3}),
    ('A_L2c', 'rocks/marble_block_c.glb', 0.035, -11.2, 90.0, {'along': 4.2, 'scale': 1.4}),
    ('A_L2d', 'rocks/block_stack_a.glb', 0.035, -14.4, 15.0, {'along': -1.5, 'scale': 1.2}),
    ('A_L2e', 'rocks/marble_block_b.glb', 0.035, -14.8, -20.0, {'along': 2.2, 'scale': 1.3}),
    ('A_L2f', 'rocks/rubble_pile_a.glb', 0.035, -14.6, 30.0, {'along': -5.8}),
    ('A_L2g', 'rocks/block_informe_b.glb', 0.035, -9.8, 50.0, {'along': 6.9}),
    # Gramada L3, depozitul din spate (marginea curtii, 27-33 m de ax).
    ('A_L3a', 'rocks/block_stack_b.glb', 0.041, -27.0, 3.0, {'along': 0.0, 'scale': 1.5}),
    ('A_L3b', 'rocks/block_stack_b.glb', 0.041, -27.5, -8.0, {'along': -3.6, 'scale': 1.3}),
    ('A_L3c', 'rocks/block_stack_a.glb', 0.041, -30.6, 10.0, {'along': 1.6, 'scale': 1.4}),
    ('A_L3d', 'rocks/marble_block_c.glb', 0.041, -30.9, 90.0, {'along': -2.2, 'scale': 1.4}),
    ('A_L3e', 'rocks/block_informe_a.glb', 0.041, -27.8, 20.0, {'along': 4.4}),
    ('A_L3f', 'rocks/rubble_pile_a.glb', 0.041, -29.4, 0.0, {'along': -6.6}),
    # Pe buza dinspre gol (dreapta, buza la 12,5 m): doua gramezi, doar DUPA 0.025. Panta lina 0.00-0.025
    # e dezvaluirea de la start si ramane libera (au iesit si stivele D1/D2 de pe main).
    ('A_R1a', 'rocks/block_stack_b.glb', 0.03, 10.0, 3.0, {'along': 0.0, 'scale': 1.4}),
    ('A_R1b', 'rocks/block_stack_a.glb', 0.03, 9.9, -5.0, {'along': 3.3, 'scale': 1.2}),
    ('A_R1c', 'rocks/marble_block_c.glb', 0.03, 9.9, 90.0, {'along': -3.7, 'scale': 1.2}),
    ('A_R1d', 'rocks/marble_block_a.glb', 0.03, 10.9, 20.0, {'along': 1.4, 'scale': 1.1}),
    ('A_R1e', 'rocks/block_informe_b.glb', 0.03, 9.6, 35.0, {'along': 5.8, 'scale': 0.9}),
    ('A_R2a', 'rocks/block_stack_a.glb', 0.0415, 10.0, 6.0, {'along': 0.0, 'scale': 1.4}),
    ('A_R2b', 'rocks/block_stack_b.glb', 0.0415, 9.9, -4.0, {'along': -3.3, 'scale': 1.2}),
    ('A_R2c', 'rocks/marble_block_b.glb', 0.0415, 10.6, 15.0, {'along': 3.0, 'scale': 1.1}),
    ('A_R2d', 'rocks/block_informe_b.glb', 0.0415, 9.7, -30.0, {'along': -6.3}),
    # Liziera verde-galbena sub platou (dreapta): castanii SUB fata de 10 m, doar coroana trece de buza;
    # ginestra pe panta lina de la start (joasa: nu acopera vederea spre balti).
    ('A_Castan1', 'res://assets/models/transfagarasan/plants/beech_tree_a.glb', 0.028, 21.0, 30.0, {'coliziune': 'trunk'}),
    ('A_Castan2', 'res://assets/models/transfagarasan/plants/beech_tree_b.glb', 0.036, 23.0, -40.0, {'coliziune': 'trunk'}),
    ('A_Castan3', 'res://assets/models/transfagarasan/plants/beech_tree_a.glb', 0.055, 22.0, 110.0, {'coliziune': 'trunk'}),
    ('A_Ginestra1', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.004, 17.0, 0.0, {'scale': 1.3}),
    ('A_Ginestra2', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.009, 19.0, 70.0, {'scale': 1.3}),
    ('A_Ginestra3', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.0135, 17.5, 140.0, {'scale': 1.3}),
    ('A_Ginestra4', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.0185, 18.0, 210.0, {'scale': 1.3}),
    ('A_Ginestra5', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.0055, 21.0, 280.0, {'scale': 1.3}),
]

# Cotele: terenul minim de sub amprenta - 3 cm, din `ProbeCarraraMontaj -- --decor` (piesele cu mai multe
# noduri) si din `--under --scan` pe pas de 1 m (piesele coapte intr-un singur buffer nu apar in `--decor`).
# Castanii: terenul sub TRUNCHI (coroana acopera fata). Ginestra pe panta: minimul de sub tufa.
KIT_Y = {
    "A_Container": 24.66, "A_Rezervor": 24.65, "A_Lampa": 24.67,
    "A_Castan1": 14.12, "A_Castan2": 14.72, "A_Castan3": 15.62,
    "A_L1a": 24.62, "A_L1b": 24.62, "A_L1c": 24.63, "A_L1d": 24.56, "A_L1e": 24.59, "A_L1f": 24.54, "A_L1g": 24.52,
    "A_L1h": 24.63, "A_Foreza": 24.37, "A_MuzeuRoata": 24.61, "A_MuzeuVagonet": 24.56, "A_L2a": 24.59, "A_L2b": 24.60, "A_L2c": 24.59,
    "A_L2d": 24.51, "A_L2e": 24.49, "A_L2f": 24.48, "A_L2g": 24.61, "A_L3a": 24.30, "A_L3b": 24.31, "A_L3c": 24.31,
    "A_L3d": 24.31, "A_L3e": 24.30, "A_L3f": 24.31, "A_MagazieA": 24.47, "A_MagazieB": 24.47, "A_CisternaA": 24.55, "A_CisternaB": 24.55,
    "A_R1a": 24.67, "A_R1b": 24.67, "A_R1c": 24.67, "A_R1d": 24.67, "A_R1e": 24.67, "A_R2a": 24.67, "A_R2b": 24.67,
    "A_R2c": 24.67, "A_R2d": 24.67,
    "A_Ginestra1": 24.20, "A_Ginestra2": 23.35, "A_Ginestra3": 23.00, "A_Ginestra4": 21.65, "A_Ginestra5": 23.55,
}
