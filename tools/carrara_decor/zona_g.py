# Decorul POI-ului G pe Track23 (Carrara), citit de tools/gen_carrara_route.py.
# Un fisier per POI ca constructorii din gauntlet sa lucreze in paralel fara conflicte
# (docs/track_briefs/carrara_poi_gauntlet.md). Generatorul ramane sursa de adevar: Track23.tscn
# se regenereaza, nu se editeaza de mana.
#
# ITEMS: (nume, glb, frac pe INDEX, lateral, yaw[, optiuni])
#   nume     unic pe TOATA pista, prefixat cu litera zonei ("G_...")
#   glb      relativ la res://assets/models/carrara/ sau cale res:// completa (reuse din alte kituri)
#   lateral  metri la DREAPTA sensului de cursa (negativ = stanga), fata de axa drumului
#   yaw      grade, relativ la directia drumului (-Z al piesei spre inainte la 0)
#   optiuni  dict, toate optionale: "along" (m inainte), "scale" (uniform), "tilt" (urmeaza panta
#            drumului in lung), "coliziune" ("hull" implicit / "mesh" / "trunk" / "none"), "y" (cota
#            absoluta, altfel KIT_Y sau cota drumului - 0.3)
# KIT_Y: cotele MASURATE (terenul minim de sub amprenta - 3 cm), din
#   `ProbeCarraraMontaj.tscn -- --decor`. O piesa fara cota masurata sta la cota drumului - 0.3.
#
# FOREST / FOREST_GLBS (doar G, 31 oct 2026): padurea in masa, in MultiMesh feliat (MeshForest, blocul
# "G: PADUREA IN MASA" din generator). Fiecare intrare e o zona MeshForestZone:
#   kind "ring" (fasie in lungul drumului: frac_from/frac_to pe INDEX, side +1 dreapta / -1 stanga / 0
#   ambele, lat_min/lat_max de la AXA) sau "disc" (center = (x, z) de lume, radius). `claim` rezerva
#   suprafata pentru zonele de DUPA (o zona fara specii doar rezerva). Restul cheilor ca in
#   scenes/props/mesh_forest_zone.gd. Toti arborii din FOREST sunt fantome; cota vine din teren la rulare.
#
# POI G — ravaneto-ul si Colonnata (frac 0,714-0,911; brief par.2 randul G). Ce citeste „vara":
#   - versantul din STANGA (sud pe dreapta E-V, vest pe S-uri) e padure deasa de castani cu ginestra
#     galbena pe margini (FOREST), cu primul rand solid in ITEMS (trunchi, `coliziune: trunk`);
#   - satul pe INTERIORUL lui S2 (virajul la stanga de la 0,864, buzunarul dintre bratele 0,83-0,85 si
#     0,87-0,89, ~40-60 m de asfalt): biserica cu clopotnita + case de piatra cu tigla. Se vede din
#     tot S-ul (0,82-0,89), ca in bara, unde satul sta in interiorul serpentinelor;
#   - doua case si turnul la iesirea din coltul SV (exteriorul virajului, pe stanga): in fata camerei
#     pe toata dreapta E-V (0,74-0,79);
#   - pe DREAPTA, peste buza ravaneto-ului (+55, la ~28 m de ax), coama de castani; molozul ramane gol,
#     crem, cu ginestra doar la piciorul lui;
#   - jgheabul saniei (via di lizza) si platforma ei de oprire (stanga, s +16) raman LIBERE: discuri
#     `claim` fara specii pe tot traseul.

_P = 'plants/'
_B = 'buildings/'

ITEMS = [
    # ---- 1. sus, la iesirea de pe pod (bara: turnul patrat si cisternele albastre, sirul de blocuri)
    ('G_Turn', _B + 'stone_tower.glb', 0.736, -21.0, 15.0),
    ('G_CisternaA', 'props/water_tank.glb', 0.733, -16.0, 0.0),
    ('G_CisternaB', 'props/water_tank.glb', 0.7335, -18.6, 0.0, {'along': 1.2}),
    ('G_Bloc1', 'rocks/marble_block_a.glb', 0.739, -10.5, 8.0),
    ('G_Bloc2', 'rocks/marble_block_b.glb', 0.742, -10.6, -5.0),
    ('G_Bloc3', 'rocks/marble_block_c.glb', 0.745, -10.4, 12.0),

    # ---- 2. primul rand de castani pe STANGA, solizi (trunchi). Lipsesc 0,745-0,758 (intrarea camionului 2
    # vine pe stanga, in diagonala, din (-239, 144)) si 0,762-0,780 (platforma saniei).
    ('G_CastanL01', _P + 'chestnut_tree_a.glb', 0.7605, -19.0, 20.0, {'coliziune': 'trunk'}),
    ('G_CastanL05', _P + 'chestnut_tree_a.glb', 0.808, -17.0, 300.0, {'coliziune': 'trunk'}),
    ('G_CastanL06', _P + 'chestnut_tree_b.glb', 0.816, -16.0, 10.0, {'coliziune': 'trunk'}),
    ('G_CastanL07', _P + 'chestnut_tree_a.glb', 0.825, -17.5, 200.0, {'coliziune': 'trunk'}),
    ('G_CastanL08', _P + 'chestnut_tree_b.glb', 0.834, -16.5, 95.0, {'coliziune': 'trunk'}),
    ('G_CastanL10', _P + 'chestnut_tree_b.glb', 0.876, -17.0, 170.0, {'coliziune': 'trunk'}),
    ('G_CastanL11', _P + 'chestnut_tree_a.glb', 0.884, -16.0, 40.0, {'coliziune': 'trunk'}),
    ('G_CastanL12', _P + 'chestnut_tree_b.glb', 0.893, -18.0, 270.0, {'coliziune': 'trunk'}),
    ('G_CastanL13', _P + 'chestnut_tree_a.glb', 0.902, -17.0, 120.0, {'coliziune': 'trunk'}),
    ('G_CastanL14', _P + 'chestnut_tree_b.glb', 0.910, -18.0, 220.0, {'coliziune': 'trunk'}),
    # ---- 3. primul rand pe DREAPTA, dupa capatul ravaneto-ului (0,838): exteriorul lui S2, interiorul lui S3
    ('G_CastanR01', _P + 'chestnut_tree_a.glb', 0.849, 17.0, 80.0, {'coliziune': 'trunk'}),
    ('G_CastanR02', _P + 'chestnut_tree_b.glb', 0.857, 18.0, 190.0, {'coliziune': 'trunk'}),
    ('G_CastanR03', _P + 'chestnut_tree_a.glb', 0.866, 17.0, 310.0, {'coliziune': 'trunk'}),
    ('G_CastanR04', _P + 'chestnut_tree_b.glb', 0.875, 16.5, 30.0, {'coliziune': 'trunk'}),
    ('G_CastanR05', _P + 'chestnut_tree_a.glb', 0.884, 18.0, 150.0, {'coliziune': 'trunk'}),
    ('G_CastanR06', _P + 'chestnut_tree_b.glb', 0.893, 17.0, 260.0, {'coliziune': 'trunk'}),

    # ---- 4. COLONNATA, in buzunarul din interiorul lui S2 (0,864). Biserica cu usa spre drum, casele
    # in doua randuri pe panta care urca spre vest.
    # Biserica la 1,25x: clopotnita de 17,5 m trece de coroanele castanilor (10-14 m) si se vede din S1.
    ('G_Biserica', _B + 'colonnata_church.glb', 0.862, -50.0, -70.0, {'scale': 1.25}),
    ('G_CasaA1', _B + 'colonnata_house_a.glb', 0.852, -40.0, -20.0),
    ('G_CasaB1', _B + 'colonnata_house_b.glb', 0.847, -52.0, 10.0),
    ('G_CasaC1', _B + 'colonnata_house_c.glb', 0.857, -57.0, -40.0),
    ('G_CasaB2', _B + 'colonnata_house_b.glb', 0.870, -40.0, -95.0),
    ('G_CasaA2', _B + 'colonnata_house_a.glb', 0.874, -55.0, -110.0),
    ('G_CasaC2', _B + 'colonnata_house_c.glb', 0.867, -58.0, -80.0),
    ('G_CasaA3', _B + 'colonnata_house_a.glb', 0.879, -42.0, -140.0),
    # ---- 3b. RUNDA 2 (criticul r1: „nicio marmura in cadru, blocuri si moloz pe marginile drumului si pe panta
    # din dreapta"). Grupuri de blocuri taiate si gramezi de moloz pe marginea din STANGA (lat -9,5..-11, la
    # 5-6,5 m de asfalt; solide, hull) si pe dreapta dupa ravaneto; moloz si blocuri informe urcand pe PANTA
    # ravaneto-ului (umarul se termina la lat 9,5, peretele urca 0,86 m/m pana la buza de la ~28 m), dupa
    # jgheabul saniei (0,772-0,836). Pe panta: fantome (masina nu urca acolo; un corp ar face treapta).
    ('G_MargL1a', 'rocks/marble_block_c.glb', 0.795, -10.5, 14.0),
    ('G_MargL1b', 'rocks/rubble_pile_b.glb', 0.797, -11.5, 40.0),
    ('G_MargL2a', 'rocks/block_stack_a.glb', 0.812, -10.0, -8.0),
    ('G_MargL2b', 'rocks/marble_block_a.glb', 0.814, -10.2, 20.0),
    ('G_MargL3a', 'rocks/rubble_pile_a.glb', 0.829, -11.5, 0.0),
    ('G_MargL3b', 'rocks/marble_block_b.glb', 0.8315, -10.0, -12.0),
    ('G_MargL4a', 'rocks/marble_block_c.glb', 0.874, -10.0, 5.0),
    ('G_MargL4b', 'rocks/block_informe_b.glb', 0.877, -10.5, 60.0),
    ('G_MargL5a', 'rocks/block_stack_b.glb', 0.891, -10.2, 12.0),
    ('G_MargL5b', 'rocks/rubble_pile_b.glb', 0.894, -11.5, 100.0),
    ('G_MargL6a', 'rocks/marble_block_b.glb', 0.906, -10.0, -6.0),
    ('G_MargR1a', 'rocks/marble_block_c.glb', 0.847, 10.0, 8.0),
    ('G_MargR1b', 'rocks/rubble_pile_a.glb', 0.8495, 11.5, 30.0),
    ('G_MargR2a', 'rocks/block_stack_a.glb', 0.869, 10.2, -10.0),
    ('G_MargR2b', 'rocks/marble_block_a.glb', 0.871, 10.0, 15.0),
    ('G_MargR3a', 'rocks/marble_block_b.glb', 0.888, 10.0, 4.0),
    ('G_MargR3b', 'rocks/rubble_pile_b.glb', 0.890, 11.5, 70.0),
    ('G_Panta1', 'rocks/rubble_pile_a.glb', 0.777, 14.0, 20.0, {'coliziune': 'none', 'scale': 1.4}),
    ('G_Panta2', 'rocks/block_informe_a.glb', 0.786, 19.0, 50.0, {'coliziune': 'none'}),
    ('G_Panta3', 'rocks/rubble_pile_b.glb', 0.795, 15.0, 110.0, {'coliziune': 'none', 'scale': 1.5}),
    ('G_Panta4', 'rocks/block_informe_b.glb', 0.804, 22.0, 10.0, {'coliziune': 'none', 'scale': 1.3}),
    ('G_Panta5', 'rocks/rubble_pile_a.glb', 0.814, 13.5, 200.0, {'coliziune': 'none', 'scale': 1.3}),
    ('G_Panta6', 'rocks/marble_block_c.glb', 0.822, 18.0, 33.0, {'coliziune': 'none'}),
    ('G_Panta7', 'rocks/rubble_pile_b.glb', 0.830, 14.5, 300.0, {'coliziune': 'none', 'scale': 1.4}),
    # ---- 4b. zidul de blocuri al satului, pe interiorul lui S2 (bara: blocuri pe marginea drumului)
    ('G_BlocSat1', 'rocks/marble_block_b.glb', 0.852, -11.0, 6.0),
    ('G_BlocSat2', 'rocks/marble_block_a.glb', 0.855, -11.2, -4.0),
    ('G_BlocSat3', 'rocks/marble_block_c.glb', 0.858, -11.0, 10.0),
    ('G_BlocSat4', 'rocks/marble_block_a.glb', 0.861, -11.3, -7.0),
    # ---- 5. exteriorul coltului SV: in fata camerei pe dreapta E-V
    # (L03/L04, primul rand de la 0,784-0,791, ascundeau casele: scosi; in locul lor, luminis cu ginestra)
    ('G_CasaSV1', _B + 'colonnata_house_c.glb', 0.797, -38.0, 60.0),
    ('G_CasaSV2', _B + 'colonnata_house_b.glb', 0.801, -50.0, 80.0),
    ('G_TurnSV', _B + 'stone_tower.glb', 0.792, -52.0, 30.0),
]

KIT_Y = {
    # pe panta ravaneto-ului (0,86 m/m): terenul sub ORIGINE - 1,9 m (probe_manual cere < 2 m sub teren); marginea
    # din vale, cea vazuta de pe drum, ramane la cel mult ~0,5 m peste moloz
    "G_Panta1": 40.36,
    "G_Panta2": 43.91,
    "G_Panta3": 39.99,
    "G_Panta4": 45.32,
    "G_Panta5": 37.41,
    "G_Panta6": 40.75,
    "G_Panta7": 36.25,
    "G_Turn": 41.02,
    "G_CisternaA": 41.29,
    "G_CisternaB": 41.25,
    "G_Bloc1": 40.9,
    "G_Bloc2": 40.67,
    "G_Bloc3": 40.5,
    "G_CastanL01": 39.41,
    "G_CastanL05": 36.22,
    "G_CastanL06": 35.61,
    "G_CastanL07": 35.07,
    "G_CastanL08": 34.35,
    "G_CastanL10": 31.86,
    "G_CastanL11": 31.29,
    "G_CastanL12": 30.63,
    "G_CastanL13": 29.87,
    "G_CastanL14": 29.36,
    "G_CastanR01": 33.62,
    "G_CastanR02": 32.9,
    "G_CastanR03": 32.29,
    "G_CastanR04": 31.19,
    "G_CastanR05": 30.45,
    "G_CastanR06": 30.18,
    "G_Biserica": 31.19,
    "G_CasaA1": 31.5,
    "G_CasaB1": 30.98,
    "G_CasaC1": 31.06,
    "G_CasaB2": 32.42,
    "G_CasaA2": 33.55,
    "G_CasaC2": 32.16,
    "G_CasaA3": 32.8,
    "G_MargL1a": 37.09,
    "G_MargL1b": 36.99,
    "G_MargL2a": 35.94,
    "G_MargL2b": 35.84,
    "G_MargL3a": 34.78,
    "G_MargL3b": 34.65,
    "G_MargL4a": 31.75,
    "G_MargL4b": 31.59,
    "G_MargL5a": 30.69,
    "G_MargL5b": 30.47,
    "G_MargL6a": 29.65,
    "G_MargR1a": 33.58,
    "G_MargR1b": 33.47,
    "G_MargR2a": 32.08,
    "G_MargR2b": 31.97,
    "G_MargR3a": 30.71,
    "G_MargR3b": 30.52,
    "G_BlocSat1": 33.2,
    "G_BlocSat2": 33.06,
    "G_BlocSat3": 32.86,
    "G_BlocSat4": 32.69,
    "G_CasaSV1": 36.92,
    "G_CasaSV2": 36.41,
    "G_TurnSV": 37.03,
}

# ---- padurea in masa ---------------------------------------------------------------------------------
FOREST_GLBS = {
    'chestnut_tree_a': _P + 'chestnut_tree_a.glb',
    'chestnut_tree_b': _P + 'chestnut_tree_b.glb',
    'ginestra_fiorita': _P + 'ginestra_fiorita.glb',
}

# Jgheabul saniei (coordonate de lume din generator: varf s -56.84 .. stop s +16, plus sania): liber.
_LIZZA = [(-222.96, 75.46), (-229.3, 80.8), (-235.7, 86.2), (-242.09, 91.52), (-248.7, 97.1),
          (-255.3, 102.6), (-261.90, 108.14), (-271.10, 115.86), (-278.76, 122.28), (-283.4, 126.2)]

# Intrarea camionului 2 (Camion2Pod, din `truck_curve`: din afara drumului, pe stanga, in diagonala spre x -214).
_CAMION2 = [(-217.0, 118.0), (-222.0, 124.0), (-227.0, 130.0), (-233.0, 137.0), (-239.0, 144.0), (-245.0, 151.0)]

# Petele de ginestra (frac, lateral, raza): GRAMEZI galbene, nu un sir uniform. In bara galbenul e in
# mase cat o coroana intre castani; o tufa de 2-3 m citeste doar in grup. Fiecare pata isi rezerva
# discul (`claim`), deci castanii o ocolesc si ramane luminis galben vazut de pe drum.
_GINESTRA = [
    # stanga, dreapta E-V (versantul de sud)
    (0.733, -24.0, 8.0), (0.745, -40.0, 9.0), (0.762, -16.0, 5.0), (0.770, -36.0, 7.0), (0.778, -20.0, 6.0), (0.787, -40.0, 9.0),
    # stanga, coborarea N-S si S-urile (vest)
    (0.806, -24.0, 8.0), (0.816, -48.0, 10.0), (0.826, -22.0, 7.0), (0.893, -24.0, 8.0), (0.905, -42.0, 9.0),
    (0.884, -45.0, 8.0),
    # dreapta, dupa ravaneto (exteriorul lui S2, interiorul lui S3)
    (0.851, 22.0, 8.0), (0.862, 40.0, 9.0), (0.874, 22.0, 7.0), (0.890, 34.0, 8.0),
    # pe coama de peste moloz si la piciorul lui (umarul de 5 m dintre asfalt si perete)
    (0.740, 36.0, 6.0), (0.792, 40.0, 8.0), (0.808, 34.0, 6.0), (0.752, 10.0, 3.5), (0.788, 10.0, 3.5),
    (0.803, 10.0, 3.5), (0.818, 10.0, 3.5), (0.832, 10.0, 3.5),
]

# Luminisurile din fata satelor: ginestra in loc de castani pe linia de vedere de pe drum spre biserica
# (din S1, 0,82-0,86) si spre casele de la coltul SV (de pe dreapta E-V). Coordonate de lume (x, z, raza).
_LUMINIS = [(-328.0, 8.0, 12.0), (-313.0, -12.0, 10.0), (-342.0, 119.0, 12.0), (-325.0, 119.0, 8.0)]

# Blocurile de pe margine isi rezerva locul: ginestra din banda nu creste prin ele.
_PIESE_MARGINE = [it for it in ITEMS if it[0].startswith(('G_Marg', 'G_Bloc'))]

FOREST = (
    [dict(label='loc %s' % it[0], kind='disc', at=(it[2], it[3]), radius=2.6, claim=True) for it in _PIESE_MARGINE]
    + [dict(label='lizza %d' % k, kind='disc', center=c, radius=8.0 if k >= len(_LIZZA) - 2 else 6.5, claim=True)
     for k, c in enumerate(_LIZZA)]
    + [dict(label='camion2 %d' % k, kind='disc', center=c, radius=5.5, claim=True)
       for k, c in enumerate(_CAMION2)]
    + [
        # Satul: nimic din padure in curtea bisericii si intre case (rezervare fara specii).
        dict(label='sat S2', kind='disc', center=(-338.0, -18.0), radius=26.0, claim=True),
        dict(label='sat SV', kind='disc', center=(-360.0, 124.0), radius=24.0, claim=True),
    ]
    + [dict(label='luminis %d' % k, kind='disc', center=(x, z), radius=r, claim=True, spacing=2.6,
            edge_clear_m=3.0, shadow_m=0.0, species=('ginestra_fiorita',), weights=(1.0,),
            scale_min=1.1, scale_max=1.6, seed=50 + k)
       for k, (x, z, r) in enumerate(_LUMINIS)]
    + [dict(label='ginestra pata %d' % k, kind='disc', at=(f, l), radius=r, claim=True, spacing=2.3,
            edge_clear_m=3.0, shadow_m=0.0, species=('ginestra_fiorita',), weights=(1.0,),
            scale_min=1.1, scale_max=1.7, seed=60 + k)
       for k, (f, l, r) in enumerate(_GINESTRA)]
    + [
        # Castanii: coronament inchis (pas 7 m, coroana de 10-13 m). Trunchiurile la >= 9 m de asfalt,
        # coroanele ajung la ~3 m de margine, niciodata pe banda.
        dict(label='castani stanga', kind='ring', frac_from=0.728, frac_to=0.925, side=-1,
             lat_min=13.0, lat_max=60.0, spacing=6.5, edge_clear_m=9.0, shadow_m=30.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=0.9, scale_max=1.35, seed=72),
        # Dincolo de 60 m (ceata incepe la 120): mai rar si fara umbra. Pana la 100 m, nu 140: ProbePerf
        # --mobile, varful de 1,57M triunghiuri la 0,70 (G vazut de pe pod) venea din padure.
        dict(label='castani stanga departe', kind='ring', frac_from=0.728, frac_to=0.925, side=-1,
             lat_min=60.0, lat_max=100.0, spacing=8.0, edge_clear_m=9.0, shadow_m=0.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=1.0, scale_max=1.4, seed=79),
        dict(label='castani coama', kind='ring', frac_from=0.738, frac_to=0.838, side=1,
             lat_min=27.0, lat_max=85.0, spacing=7.5, edge_clear_m=22.0, shadow_m=0.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=0.9, scale_max=1.3, seed=73),
        dict(label='castani dreapta S', kind='ring', frac_from=0.843, frac_to=0.905, side=1,
             lat_min=13.0, lat_max=100.0, spacing=6.5, edge_clear_m=9.0, shadow_m=30.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=0.9, scale_max=1.35, seed=74),
        # RUNDA 2: banda de langa drum (criticul r1: „umerii drumului goi, crange amestecate dese pe ambele
        # parti"). Castani tineri (0,45-0,65x: coroana de ~4-8 m) la 5-7 m de asfalt si ginestra deasa
        # intre ei, pe stanga de-a lungul lui G si pe dreapta doar dupa ravaneto (molozul ramane gol).
        dict(label='castani tineri stanga', kind='ring', frac_from=0.728, frac_to=0.925, side=-1,
             lat_min=10.0, lat_max=15.0, spacing=6.0, edge_clear_m=5.0, shadow_m=20.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.4, 0.6),
             scale_min=0.45, scale_max=0.65, seed=76),
        dict(label='castani tineri dreapta', kind='ring', frac_from=0.843, frac_to=0.925, side=1,
             lat_min=10.0, lat_max=15.0, spacing=6.0, edge_clear_m=5.0, shadow_m=20.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.4, 0.6),
             scale_min=0.45, scale_max=0.65, seed=77),
        dict(label='ginestra banda stanga', kind='ring', frac_from=0.728, frac_to=0.925, side=-1,
             lat_min=7.0, lat_max=13.0, spacing=2.8, edge_clear_m=2.5, shadow_m=0.0,
             species=('ginestra_fiorita',), weights=(1.0,), scale_min=1.0, scale_max=1.6, seed=71),
        dict(label='ginestra banda dreapta', kind='ring', frac_from=0.843, frac_to=0.925, side=1,
             lat_min=7.0, lat_max=13.0, spacing=2.8, edge_clear_m=2.5, shadow_m=0.0,
             species=('ginestra_fiorita',), weights=(1.0,), scale_min=1.0, scale_max=1.6, seed=78),
    ]
)
