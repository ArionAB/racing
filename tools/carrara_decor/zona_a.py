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
    # ---- 2. containerul-birou de la linia de start (valul 1).
    ('A_Container', 'buildings/office_container.glb', _F0, -16.0, 90.0, {'along': 8.0}),
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
    # Mijlocul curtii (13-25 m) intre utilaje: moloz si blocuri informe, ca bara sa nu aiba pete goale.
    ('A_Moloz1', 'rocks/rubble_pile_a.glb', _F0, -21.0, 30.0, {'along': 47.0}),
    ('A_Informe1', 'rocks/block_informe_a.glb', _F0, -21.5, 40.0, {'along': 24.0, 'scale': 1.3}),
    ('A_Informe2', 'rocks/block_informe_b.glb', _F0, -24.0, -15.0, {'along': 2.0, 'scale': 1.2}),
    # ---- nucleul de la 0.019 (valul 1, ce a ramas): rezervorul, forajul, gramada P1 (fara spatele ei, care
    # acoperea magazia) si coada lui P2. Pozitiile sunt fata de NF = 0.019 (x -108,7).
    ('A_Rezervor', 'props/fuel_tank.glb', 0.019, -25.8, 90.0, {'along': 15.5}),
    ('A_Foreza', 'vehicles/drill_rig.glb', 0.019, -20.2, 20.0, {'along': 16.0}),
    ('A_P1a', 'rocks/block_stack_b.glb', 0.019, -12.0, 3.0, {'along': 0.5, 'scale': 1.6}),
    ('A_P1b', 'rocks/block_stack_a.glb', 0.019, -12.2, -5.0, {'along': 4.2, 'scale': 1.5}),
    ('A_P1f', 'rocks/rubble_pile_b.glb', 0.019, -14.6, 0.0, {'along': 6.8}),
    ('A_P1g', 'rocks/block_informe_b.glb', 0.019, -10.9, -20.0, {'along': 6.9}),
    ('A_P2f', 'rocks/rubble_pile_a.glb', 0.019, -16.0, 0.0, {'along': 16.0}),
    ('A_P2g', 'rocks/block_informe_a.glb', 0.019, -11.2, 15.0, {'along': 25.6}),
    # Runda 2 (criticul orb r1: "blocurile stau intr-un singur zid continuu pe stanga, strada cu lazi, nu
    # curte"; lipsesc magazia, cisternele, verdele): gramada P2 si spatele lui P1 au disparut, biroul pe doua
    # niveluri la fel (prea multe containere), iar IN FATA gramezii P1 sta magazia cu acoperis de tabla si
    # cisternele albastre, cu turnul deasupra lor, in cadrul de la 0.01. Muzeul s-a mutat pe dreapta (ca in bara).
    # Magazia: doua containere lipite pe lung (6 x 5,2 m).
    # inlocuit la integrare cu tin_shed.glb (ambele piese devin una)
    ('A_SopronA', 'buildings/office_container.glb', _F0, -13.6, 90.0, {'along': 29.0}),
    ('A_SopronB', 'buildings/office_container.glb', _F0, -16.2, 90.0, {'along': 29.0}),
    ('A_CisternaC', 'props/water_tank.glb', _F0, -12.6, 0.0, {'along': 35.4}),
    ('A_CisternaD', 'props/water_tank.glb', _F0, -15.5, 0.0, {'along': 36.2}),
    # Verdele curtii: castani intre turn si birou si dupa magazie, ginestra la piciorul turnului.
    # inlocuit la integrare cu chestnut_tree.glb / ginestra cu flori (numele raman)
    ('A_Castan4', _BL + 'beech_tree_b.glb', _F0, -27.5, 50.0, {'along': 40.5, 'coliziune': 'trunk'}),
    ('A_Castan5', _BL + 'beech_tree_a.glb', _F0, -20.0, 160.0, {'along': 72.0, 'coliziune': 'trunk'}),
    ('A_Castan6', _BL + 'beech_tree_a.glb', _F0, -22.0, -70.0, {'along': 1.0, 'coliziune': 'trunk'}),
    ('A_Ginestra6', 'res://assets/models/stromboli/plants/ginestra_bush.glb', _F0, -19.0, 20.0, {'along': 38.0, 'scale': 1.3}),
    ('A_Ginestra7', 'res://assets/models/stromboli/plants/ginestra_bush.glb', _F0, -25.6, 120.0, {'along': 36.5, 'scale': 1.3}),
    # Dreapta: doi castani pe banca, dincolo de berma (fantome).
    ('A_Castan7', _BL + 'beech_tree_b.glb', _F0, 14.0, 10.0, {'along': 19.0, 'coliziune': 'none'}),
    ('A_Castan8', _BL + 'beech_tree_a.glb', _F0, 12.0, 200.0, {'along': 37.0, 'coliziune': 'none'}),
    # ---- 3. depozitul de blocuri mari (28-34 m): inchide orizontul gol din stanga, ca peretele din bara.
    ('A_D1', 'rocks/block_stack_b.glb', _F0, -30.0, 5.0, {'along': -10.0, 'scale': 2.0}),
    ('A_D2', 'rocks/marble_block_c.glb', _F0, -31.5, 86.0, {'along': -3.0, 'scale': 2.0}),
    ('A_D3', 'rocks/block_stack_a.glb', _F0, -29.0, -8.0, {'along': 5.0, 'scale': 2.0}),
    ('A_D4', 'rocks/block_stack_b.glb', _F0, -33.0, 12.0, {'along': 11.0, 'scale': 1.8}),
    ('A_D5', 'rocks/marble_block_c.glb', _F0, -30.0, 2.0, {'along': 19.0, 'scale': 1.8}),
    ('A_D6', 'rocks/block_stack_b.glb', _F0, -31.0, -4.0, {'along': 27.0, 'scale': 2.2}),
    ('A_D7', 'rocks/block_stack_a.glb', _F0, -28.5, 6.0, {'along': 34.0, 'scale': 1.8}),
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
    # Muzeul la scara mare pe banca din dreapta (in bara: roata si vagonetul la dreapta magaziei): roata de
    # fir 3,2 m si vagonetul cu bloc.
    ('A_MuzeuRoata', 'props/museum_set_wheel.glb', _F0, 11.6, -70.0, {'coliziune': 'none', 'along': 25.5, 'scale': 1.6}),
    ('A_MuzeuVagonet', 'props/museum_set_cart.glb', _F0, 10.6, 4.0, {'coliziune': 'none', 'along': 30.5, 'scale': 1.6}),
    ('A_RSa', 'rocks/block_stack_a.glb', _F0, 10.0, 6.0, {'coliziune': 'none', 'along': 41.0, 'scale': 1.3}),
    ('A_RSb', 'rocks/marble_block_c.glb', _F0, 10.6, 82.0, {'coliziune': 'none', 'along': 44.5}),
    ('A_RSc', 'rocks/block_informe_a.glb', _F0, 11.2, 30.0, {'coliziune': 'none', 'along': 47.5}),
    ('A_RTa', 'rocks/block_stack_b.glb', _F0, 10.0, -5.0, {'coliziune': 'none', 'along': 52.0, 'scale': 1.3}),
    ('A_RTb', 'rocks/marble_block_a.glb', _F0, 10.8, 15.0, {'coliziune': 'none', 'along': 55.5}),
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
    "A_G1a": 24.62, "A_G1b": 24.62, "A_G1c": 24.62, "A_Container": 24.62,
    "A_Tambur": 24.62, "A_Semn": 24.62, "A_ExcavatorDecor": 24.52, "A_ExcBloc": 24.62, "A_MuzeuRoata": 24.62,
    "A_MuzeuVagonet": 24.62, "A_Moloz1": 24.32, "A_Informe1": 24.52, "A_Informe2": 24.62,
    "A_D1": 24.72, "A_D2": 24.62, "A_D3": 24.62, "A_D4": 24.62, "A_D5": 24.52, "A_D6": 24.52, "A_D7": 24.42,
    "A_D8c": 24.32, "A_D9": 24.32, "A_D10": 24.22,
    "A_RGa": 24.72, "A_RGb": 24.62, "A_RGc": 24.62, "A_RMa": 24.62, "A_RMb": 24.62, "A_RLampa": 24.62,
    "A_RSanie": 24.60, "A_RSa": 24.62, "A_RSb": 24.62, "A_RSc": 24.62, "A_RTa": 24.62, "A_RTb": 24.62,
    # Runda 2, acelasi scan.
    "A_SopronA": 24.52, "A_SopronB": 24.52, "A_CisternaC": 24.52, "A_CisternaD": 24.52, "A_Castan4": 24.42, "A_Castan5": 24.32, "A_Castan6": 24.62, "A_Ginestra6": 24.52, "A_Ginestra7": 24.42, "A_Castan7": 24.22, "A_Castan8": 24.62,
    "A_Rezervor": 24.39, "A_Foreza": 24.37,
    "A_P1a": 24.62, "A_P1b": 24.61, "A_P1f": 24.56,
    "A_P1g": 24.62, 
    "A_P2f": 24.49, "A_P2g": 24.60, "A_R1a": 24.67, "A_R1b": 24.67, "A_R1c": 24.67, "A_R1d": 24.67,
    "A_R1e": 24.67, "A_R2a": 24.67, "A_R2b": 24.67, "A_R2c": 24.67, "A_R2d": 24.67,
    "A_Castan1": 14.12, "A_Castan2": 14.72, "A_Castan3": 15.62,
    "A_Ginestra1": 24.20, "A_Ginestra2": 23.35, "A_Ginestra3": 23.00, "A_Ginestra4": 21.65, "A_Ginestra5": 23.55,
}
