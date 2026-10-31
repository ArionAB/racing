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
    # Containerul-birou de la start (era pe main) si lampa de lucru inaintea excavatorului-hazard.
    ('A_Container', 'buildings/office_container.glb', 0.004, -13.0, 90.0),
    ('A_Lampa', 'props/work_lamp.glb', 0.046, 9.5, 180.0),
    # RUNDA 3 (criticul orb: "lipseste un NUCLEU DE LUCRU; fiecare obiect pluteste singur intr-un gol").
    # UN singur nucleu strans in stanga-mijlocul cadrului de la 0.01: x -113 .. -83 (27-57 m in fata camerei),
    # 10-27 m de ax. Toate pozitiile sunt fata de baza NF = 0.019 (x -108,7), cu 'along' in metri.
    # Centrul: biroul de santier pe doua niveluri (doi containeri suprapusi + unul alaturi, tabla vopsita
    # fara stratul de fibra: `office_container` pe `plain` in CLASSES_CARRARA).
    ('A_MagazieA', 'buildings/office_container.glb', 0.019, -21.5, 90.0, {'along': 9.0}),
    ('A_MagazieB', 'buildings/office_container.glb', 0.019, -21.5, 90.0, {'along': 9.0}),
    ('A_MagazieC', 'buildings/office_container.glb', 0.019, -24.6, 90.0, {'along': 9.0}),
    ('A_CisternaA', 'props/water_tank.glb', 0.019, -24.2, 0.0, {'along': 4.3}),
    ('A_CisternaB', 'props/water_tank.glb', 0.019, -26.8, 0.0, {'along': 4.0}),
    ('A_Rezervor', 'props/fuel_tank.glb', 0.019, -25.8, 90.0, {'along': 15.5}),
    ('A_Tambur', 'props/cable_reel.glb', 0.019, -18.3, 30.0, {'along': 12.6}),
    ('A_Semn', 'props/quarry_sign_b.glb', 0.019, -10.0, -90.0, {'along': -6.5}),
    # Excavatorul de decor (copia statica a modelului hazardului, fara script): in prim-planul nucleului,
    # cu bratul spre gramada P1. Vopseaua pe atlas (galben-spalacit), `*_Rust` pe clasa globala.
    ('A_ExcavatorDecor', 'vehicles/quarry_excavator.glb', 0.019, -18.5, -36.0, {'along': -4.0}),
    # Muzeul la scara mare intre P1 si birou: roata de fir 3,2 m si vagonetul cu bloc.
    ('A_MuzeuRoata', 'props/museum_set_wheel.glb', 0.019, -18.8, 60.0, {'along': 3.0, 'scale': 1.6}),
    ('A_MuzeuVagonet', 'props/museum_set_cart.glb', 0.019, -16.9, 8.0, {'along': 6.6, 'scale': 1.6}),
    # Masina de forat la capatul de est al biroului.
    ('A_Foreza', 'vehicles/drill_rig.glb', 0.019, -20.2, 20.0, {'along': 16.0}),
    # Doua gramezi mari pe marginea curtii (fata dinspre drum la ~10 m de ax): stive de 2-3 la 1,4-1,6.
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
    # Pe buza dinspre gol (dreapta, buza la 12,5 m): doua gramezi, doar DUPA 0.025. Panta lina 0.00-0.025
    # e dezvaluirea de la start si ramane libera.
    ('A_R1a', 'rocks/block_stack_b.glb', 0.03, 10.0, 3.0, {'along': 0.0, 'scale': 1.4}),
    ('A_R1b', 'rocks/block_stack_a.glb', 0.03, 9.9, -5.0, {'along': 3.3, 'scale': 1.2}),
    ('A_R1c', 'rocks/marble_block_c.glb', 0.03, 9.9, 90.0, {'along': -3.7, 'scale': 1.2}),
    ('A_R1d', 'rocks/marble_block_a.glb', 0.03, 10.9, 20.0, {'along': 1.4, 'scale': 1.1}),
    ('A_R1e', 'rocks/block_informe_b.glb', 0.03, 9.6, 35.0, {'along': 5.8, 'scale': 0.9}),
    # R2 sta in coada excavatorului (0.04): pe ProbeRace integrat (s14/32) o masina s-a intepenit intre
    # berma si A_R2a (lat 6.3). Dincolo de berma fizica piesele raman doar vizuale (fantome).
    ('A_R2a', 'rocks/block_stack_a.glb', 0.0415, 10.0, 6.0, {'coliziune': 'none', 'along': 0.0, 'scale': 1.4}),
    ('A_R2b', 'rocks/block_stack_b.glb', 0.0415, 9.9, -4.0, {'coliziune': 'none', 'along': -3.3, 'scale': 1.2}),
    ('A_R2c', 'rocks/marble_block_b.glb', 0.0415, 10.6, 15.0, {'coliziune': 'none', 'along': 3.0, 'scale': 1.1}),
    ('A_R2d', 'rocks/block_informe_b.glb', 0.0415, 9.7, -30.0, {'coliziune': 'none', 'along': -6.3}),
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
    "A_Container": 24.66, "A_Lampa": 24.67,
    # A_MagazieB = etajul: cota lui A_MagazieA + 2,60 (inaltimea containerului).
    "A_MagazieA": 24.37, "A_MagazieB": 26.97, "A_MagazieC": 24.37, "A_CisternaA": 24.42, "A_CisternaB": 24.42, "A_Rezervor": 24.39,
    "A_Tambur": 24.42, "A_Semn": 24.62, "A_ExcavatorDecor": 24.49, "A_MuzeuRoata": 24.48, "A_MuzeuVagonet": 24.52, "A_Foreza": 24.37,
    "A_P1a": 24.62, "A_P1b": 24.61, "A_P1c": 24.63, "A_P1d": 24.54, "A_P1e": 24.55, "A_P1f": 24.56,
    "A_P1g": 24.62, "A_P2a": 24.59, "A_P2b": 24.59, "A_P2c": 24.60, "A_P2d": 24.48, "A_P2e": 24.49,
    "A_P2f": 24.49, "A_P2g": 24.60, "A_R1a": 24.67, "A_R1b": 24.67, "A_R1c": 24.67, "A_R1d": 24.67,
    "A_R1e": 24.67, "A_R2a": 24.67, "A_R2b": 24.67, "A_R2c": 24.67, "A_R2d": 24.67,
    "A_Castan1": 20.17, "A_Castan2": 20.17, "A_Castan3": 20.17,
    "A_Ginestra1": 20.17, "A_Ginestra2": 20.17, "A_Ginestra3": 20.17, "A_Ginestra4": 20.17, "A_Ginestra5": 20.17,
}
