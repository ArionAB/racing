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
#
# RUNDA "grila" (decizia dezvoltatorului, 31 oct 2026): decorul are voie LANGA grila de start si pe
# dreapta (baltile sunt oricum la 250-300 m, in ceata). Valul 1 iesise pe (c) cu "curtea goala, totul
# intr-un rand departat": pe un platou plat de ~80 m, cu prim-planul si dreapta tinute libere, orice
# cantitate de decor ramanea mica pe atata bej. Acum curtea se intinde pe TOT drumul vazut de la grila
# (x -170 .. -60, adica `along` -22 .. +88 fata de linia de start, frac 0), pe trei planuri:
#   1. marginea curtii, la 4-6 m de asfalt pe stanga (gramezi si utilaje solide, convexe, cu goluri de
#      cel putin o masina intre ele: nicio buzunar in care sa se intepeneasca plutonul);
#   2. curtea propriu-zisa la 13-25 m (turnul, magazia, excavatorul, muzeul, biroul pe doua niveluri);
#   3. depozitul de blocuri mari la 28-34 m, care inchide orizontul gol din stanga ca peretele carierei
#      din bara.
# Pe dreapta, cordonul de blocuri pe banca dintre berma din cod (lat 5,3-7,4) si buza: FANTOME
# (`coliziune: none`), fiindca dincolo de berma o piesa solida face buzunarul care a prins o masina pe
# ProbeRace in valul 1 (A_R2a, s14).
# Pozitiile in lung sunt `along` fata de linia de start (frac 0, x -148): drumul e drept de la tunel
# (x -199) pana la iesirea coridorului (x -27), deci un `along` negativ cade pe grila, nu pe alt tronson.

_F0 = 0.0  # linia de start
_BL = 'res://assets/models/transfagarasan/plants/'

ITEMS = [
    # ---- 1. langa grila, la piciorul falezei portalului Marmifera: cisternele albastre (bara: langa portal)
    ('A_CisternaA', 'props/water_tank.glb', _F0, -14.5, 0.0, {'along': -18.0}),
    ('A_CisternaB', 'props/water_tank.glb', _F0, -17.4, 0.0, {'along': -16.6}),
    ('A_RezervorG', 'props/fuel_tank.glb', _F0, -16.0, 90.0, {'along': -12.6}),
    # Gramada de la linia de start, pe marginea curtii (fata dinspre drum la ~8,7 m de ax).
    ('A_G1a', 'rocks/block_stack_b.glb', _F0, -10.6, 4.0, {'along': -1.5, 'scale': 1.2}),
    ('A_G1b', 'rocks/marble_block_b.glb', _F0, -10.1, 12.0, {'along': 1.9}),
    ('A_G1c', 'rocks/marble_block_a.glb', _F0, -12.6, -20.0, {'along': 2.4}),
    ('A_G0', 'rocks/marble_block_c.glb', _F0, -10.0, 88.0, {'along': -22.0}),
    # ---- 2. magazia joasa cu acoperis de tabla: doua containere lipite pe lung (6 x 5,2 m).
    # inlocuit la integrare cu tin_shed.glb (ambele piese devin una)
    ('A_SopronA', 'buildings/office_container.glb', _F0, -15.6, 90.0, {'along': 8.0}),
    ('A_SopronB', 'buildings/office_container.glb', _F0, -18.2, 90.0, {'along': 8.0}),
    ('A_Tambur', 'props/cable_reel.glb', _F0, -12.4, 30.0, {'along': 12.6}),
    ('A_Semn', 'props/quarry_sign_b.glb', _F0, -8.6, -90.0, {'along': 4.6}),
    # Excavatorul de decor (copia statica a hazardului, fara script) incarca un bloc de pe marginea curtii.
    ('A_ExcavatorDecor', 'vehicles/quarry_excavator.glb', _F0, -15.5, -55.0, {'along': 19.0}),
    ('A_ExcBloc', 'rocks/marble_block_b.glb', _F0, -10.2, 18.0, {'along': 23.4}),
    # Turnul de piatra patrat al curtii, in spatele muzeului (reperul inalt din mijlocul cadrului de la
    # 0.01). Inlocuitor: stiva de trei blocuri la 2,2x (5,1 x 7,9 x 4,7 m), piatra crem pe paleta.
    # `colonnata_house_b` a fost incercata intai: acoperisul rosu si zidaria gri-albastra (casa nu are
    # inca maparea de clase pe Carrara) ieseau din paleta barei.
    # inlocuit la integrare cu stone_tower.glb
    ('A_Turn', 'rocks/block_stack_b.glb', _F0, -21.5, 2.0, {'along': 33.0, 'scale': 2.2}),
    # Muzeul la scara mare: roata de fir 3,2 m si vagonetul cu bloc, la marginea curtii.
    ('A_MuzeuRoata', 'props/museum_set_wheel.glb', _F0, -16.0, 70.0, {'along': 28.0, 'scale': 1.6}),
    ('A_MuzeuVagonet', 'props/museum_set_cart.glb', _F0, -11.2, 6.0, {'along': 31.5, 'scale': 1.6}),
    # Mijlocul curtii (13-25 m) intre utilaje: moloz si blocuri informe, ca bara sa nu aiba pete goale.
    ('A_Moloz1', 'rocks/rubble_pile_a.glb', _F0, -23.0, 30.0, {'along': 15.0}),
    ('A_Informe1', 'rocks/block_informe_a.glb', _F0, -21.5, 40.0, {'along': 24.0, 'scale': 1.3}),
    ('A_Informe2', 'rocks/block_informe_b.glb', _F0, -24.0, -15.0, {'along': 2.0, 'scale': 1.2}),
    # ---- nucleul de la 0.019 (valul 1, pastrat): biroul pe doua niveluri, cisternele, forajul si gramezile
    # P1/P2. Pozitiile sunt fata de NF = 0.019 (x -108,7).
    ('A_MagazieA', 'buildings/office_container.glb', 0.019, -21.5, 90.0, {'along': 9.0}),
    ('A_MagazieB', 'buildings/office_container.glb', 0.019, -21.5, 90.0, {'along': 9.0}),
    ('A_MagazieC', 'buildings/office_container.glb', 0.019, -24.6, 90.0, {'along': 9.0}),
    ('A_Rezervor', 'props/fuel_tank.glb', 0.019, -25.8, 90.0, {'along': 15.5}),
    ('A_Foreza', 'vehicles/drill_rig.glb', 0.019, -20.2, 20.0, {'along': 16.0}),
    ('A_P1a', 'rocks/block_stack_b.glb', 0.019, -12.0, 3.0, {'along': 0.5, 'scale': 1.6}),
    ('A_P1b', 'rocks/block_stack_a.glb', 0.019, -12.2, -5.0, {'along': 4.2, 'scale': 1.5}),
    ('A_P1c', 'rocks/marble_block_c.glb', 0.019, -12.0, 90.0, {'along': -3.6, 'scale': 1.5}),
    ('A_P1d', 'rocks/block_stack_b.glb', 0.019, -15.6, 10.0, {'along': 2.0, 'scale': 1.4}),
    ('A_P1e', 'rocks/block_informe_a.glb', 0.019, -15.6, 30.0, {'along': -1.5}),
    ('A_P1f', 'rocks/rubble_pile_b.glb', 0.019, -14.6, 0.0, {'along': 6.8}),
    ('A_P1g', 'rocks/block_informe_b.glb', 0.019, -10.9, -20.0, {'along': 6.9}),
    ('A_P2a', 'rocks/block_stack_a.glb', 0.019, -12.2, 4.0, {'along': 18.5, 'scale': 1.6}),
    ('A_P2b', 'rocks/block_stack_b.glb', 0.019, -12.0, -6.0, {'along': 22.2, 'scale': 1.5}),
    ('A_P2c', 'rocks/marble_block_c.glb', 0.019, -12.0, 90.0, {'along': 14.9, 'scale': 1.5}),
    ('A_P2d', 'rocks/block_stack_a.glb', 0.019, -15.7, 12.0, {'along': 20.3, 'scale': 1.4}),
    ('A_P2e', 'rocks/marble_block_b.glb', 0.019, -15.4, 20.0, {'along': 24.6, 'scale': 1.3}),
    ('A_P2f', 'rocks/rubble_pile_a.glb', 0.019, -16.0, 0.0, {'along': 16.0}),
    ('A_P2g', 'rocks/block_informe_a.glb', 0.019, -11.2, 15.0, {'along': 25.6}),
    # ---- 3. depozitul de blocuri mari (28-34 m): inchide orizontul gol din stanga, ca peretele din bara.
    ('A_D1', 'rocks/block_stack_b.glb', _F0, -30.0, 5.0, {'along': -10.0, 'scale': 2.0}),
    ('A_D2', 'rocks/marble_block_c.glb', _F0, -31.5, 86.0, {'along': -3.0, 'scale': 2.0}),
    ('A_D3', 'rocks/block_stack_a.glb', _F0, -29.0, -8.0, {'along': 5.0, 'scale': 2.0}),
    ('A_D4', 'rocks/block_stack_b.glb', _F0, -33.0, 12.0, {'along': 11.0, 'scale': 1.8}),
    ('A_D5', 'rocks/marble_block_c.glb', _F0, -30.0, 2.0, {'along': 19.0, 'scale': 1.8}),
    ('A_D6', 'rocks/block_stack_b.glb', _F0, -31.0, -4.0, {'along': 27.0, 'scale': 2.2}),
    ('A_D7', 'rocks/block_stack_a.glb', _F0, -28.5, 6.0, {'along': 34.0, 'scale': 1.8}),
    ('A_D8', 'rocks/marble_block_c.glb', _F0, -33.0, 90.0, {'along': 42.0, 'scale': 2.0}),
    ('A_D8b', 'rocks/block_stack_b.glb', _F0, -30.5, -10.0, {'along': 51.0, 'scale': 2.2}),
    ('A_D8c', 'rocks/block_stack_a.glb', _F0, -33.5, 8.0, {'along': 60.0, 'scale': 2.0}),
    ('A_D9', 'rocks/block_stack_b.glb', _F0, -30.0, 3.0, {'along': 70.0, 'scale': 2.0}),
    ('A_D10', 'rocks/block_stack_a.glb', _F0, -33.0, -6.0, {'along': 77.0, 'scale': 2.0}),
    # ---- dreapta: cordonul de blocuri pe banca dintre berma si buza (FANTOME, dincolo de berma).
    ('A_RGa', 'rocks/block_stack_a.glb', _F0, 10.0, 4.0, {'coliziune': 'none', 'along': -17.0, 'scale': 1.2}),
    ('A_RGb', 'rocks/marble_block_c.glb', _F0, 10.4, 88.0, {'coliziune': 'none', 'along': -13.2}),
    ('A_RGc', 'rocks/marble_block_a.glb', _F0, 12.0, 25.0, {'coliziune': 'none', 'along': -10.8}),
    ('A_RMa', 'rocks/block_stack_b.glb', _F0, 10.0, -3.0, {'coliziune': 'none', 'along': 2.0, 'scale': 1.3}),
    ('A_RMb', 'rocks/marble_block_b.glb', _F0, 10.5, 10.0, {'coliziune': 'none', 'along': 5.6}),
    ('A_RLampa', 'props/work_lamp.glb', _F0, 9.2, 200.0, {'coliziune': 'none', 'along': 9.0}),
    ('A_RSanie', 'props/museum_set_sled.glb', _F0, 10.8, 80.0, {'coliziune': 'none', 'along': 15.0, 'scale': 1.4}),
    ('A_RSa', 'rocks/block_stack_a.glb', _F0, 10.0, 6.0, {'coliziune': 'none', 'along': 22.0, 'scale': 1.3}),
    ('A_RSb', 'rocks/marble_block_c.glb', _F0, 10.6, 82.0, {'coliziune': 'none', 'along': 26.0}),
    ('A_RSc', 'rocks/block_informe_a.glb', _F0, 11.2, 30.0, {'coliziune': 'none', 'along': 29.5}),
    ('A_RTa', 'rocks/block_stack_b.glb', _F0, 10.0, -5.0, {'coliziune': 'none', 'along': 44.0, 'scale': 1.3}),
    ('A_RTb', 'rocks/marble_block_a.glb', _F0, 10.8, 15.0, {'coliziune': 'none', 'along': 47.5}),
    # Lampa de lucru inaintea excavatorului-hazard (valul 1).
    ('A_Lampa', 'props/work_lamp.glb', 0.046, 9.5, 180.0),
    # Valul 1: gramezile R1 (solide, fara incident pe ProbeRace) si R2 (fantome, coada excavatorului).
    ('A_R1a', 'rocks/block_stack_b.glb', 0.03, 10.0, 3.0, {'along': 0.0, 'scale': 1.4}),
    ('A_R1b', 'rocks/block_stack_a.glb', 0.03, 9.9, -5.0, {'along': 3.3, 'scale': 1.2}),
    ('A_R1c', 'rocks/marble_block_c.glb', 0.03, 9.9, 90.0, {'along': -3.7, 'scale': 1.2}),
    ('A_R1d', 'rocks/marble_block_a.glb', 0.03, 10.9, 20.0, {'along': 1.4, 'scale': 1.1}),
    ('A_R1e', 'rocks/block_informe_b.glb', 0.03, 9.6, 35.0, {'along': 5.8, 'scale': 0.9}),
    ('A_R2a', 'rocks/block_stack_a.glb', 0.0415, 10.0, 6.0, {'coliziune': 'none', 'along': 0.0, 'scale': 1.4}),
    ('A_R2b', 'rocks/block_stack_b.glb', 0.0415, 9.9, -4.0, {'coliziune': 'none', 'along': -3.3, 'scale': 1.2}),
    ('A_R2c', 'rocks/marble_block_b.glb', 0.0415, 10.6, 15.0, {'coliziune': 'none', 'along': 3.0, 'scale': 1.1}),
    ('A_R2d', 'rocks/block_informe_b.glb', 0.0415, 9.7, -30.0, {'coliziune': 'none', 'along': -6.3}),
    # Liziera verde-galbena sub platou (dreapta): castanii SUB fata de 10 m, doar coroana trece de buza;
    # ginestra pe panta lina de la start.
    ('A_Castan1', _BL + 'beech_tree_a.glb', 0.028, 21.0, 30.0, {'coliziune': 'trunk'}),
    ('A_Castan2', _BL + 'beech_tree_b.glb', 0.036, 23.0, -40.0, {'coliziune': 'trunk'}),
    ('A_Castan3', _BL + 'beech_tree_a.glb', 0.055, 22.0, 110.0, {'coliziune': 'trunk'}),
    ('A_Ginestra1', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.004, 17.0, 0.0, {'scale': 1.3}),
    ('A_Ginestra2', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.009, 19.0, 70.0, {'scale': 1.3}),
    ('A_Ginestra3', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.0135, 17.5, 140.0, {'scale': 1.3}),
    ('A_Ginestra4', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.0185, 18.0, 210.0, {'scale': 1.3}),
    ('A_Ginestra5', 'res://assets/models/stromboli/plants/ginestra_bush.glb', 0.0055, 21.0, 280.0, {'scale': 1.3}),
]

# Cotele: terenul minim de sub amprenta - 3 cm, din `ProbeCarraraMontaj -- --decor` (piesele cu mai multe
# noduri) si din `--under --scan` (piesele coapte intr-un singur buffer nu apar in `--decor`).
# Castanii: terenul sub TRUNCHI (coroana acopera fata). Ginestra pe panta: minimul de sub tufa.
KIT_Y = {
    "A_Lampa": 24.67,
    # Runda "grila": din `--under --scan` pe platou (pas 2 m lateral, 0,0025 in lung), minimul de sub
    # amprenta - 8 cm (scanul e rotunjit la 0,1 m).
    "A_CisternaA": 24.72, "A_CisternaB": 24.72, "A_RezervorG": 24.72, "A_Turn": 24.42, "A_G0": 24.82,
    "A_G1a": 24.62, "A_G1b": 24.62, "A_G1c": 24.62, "A_SopronA": 24.62, "A_SopronB": 24.62,
    "A_Tambur": 24.62, "A_Semn": 24.62, "A_ExcavatorDecor": 24.52, "A_ExcBloc": 24.62, "A_MuzeuRoata": 24.52,
    "A_MuzeuVagonet": 24.52, "A_Moloz1": 24.52, "A_Informe1": 24.52, "A_Informe2": 24.62,
    "A_D1": 24.72, "A_D2": 24.62, "A_D3": 24.62, "A_D4": 24.62, "A_D5": 24.52, "A_D6": 24.52, "A_D7": 24.42,
    "A_D8": 24.42, "A_D8b": 24.32, "A_D8c": 24.32, "A_D9": 24.32, "A_D10": 24.22,
    "A_RGa": 24.72, "A_RGb": 24.62, "A_RGc": 24.62, "A_RMa": 24.62, "A_RMb": 24.62, "A_RLampa": 24.62,
    "A_RSanie": 24.60, "A_RSa": 24.62, "A_RSb": 24.62, "A_RSc": 24.62, "A_RTa": 24.62, "A_RTb": 24.62,
    # A_MagazieB = etajul: cota lui A_MagazieA + 2,60 (inaltimea containerului).
    "A_MagazieA": 24.37, "A_MagazieB": 26.97, "A_MagazieC": 24.37, "A_Rezervor": 24.39, "A_Foreza": 24.37,
    "A_P1a": 24.62, "A_P1b": 24.61, "A_P1c": 24.63, "A_P1d": 24.54, "A_P1e": 24.55, "A_P1f": 24.56,
    "A_P1g": 24.62, "A_P2a": 24.59, "A_P2b": 24.59, "A_P2c": 24.60, "A_P2d": 24.48, "A_P2e": 24.49,
    "A_P2f": 24.49, "A_P2g": 24.60, "A_R1a": 24.67, "A_R1b": 24.67, "A_R1c": 24.67, "A_R1d": 24.67,
    "A_R1e": 24.67, "A_R2a": 24.67, "A_R2b": 24.67, "A_R2c": 24.67, "A_R2d": 24.67,
    "A_Castan1": 14.12, "A_Castan2": 14.72, "A_Castan3": 15.62,
    "A_Ginestra1": 24.20, "A_Ginestra2": 23.35, "A_Ginestra3": 23.00, "A_Ginestra4": 21.65, "A_Ginestra5": 23.55,
}
