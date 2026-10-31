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
    ('G_CastanL03', _P + 'chestnut_tree_a.glb', 0.784, -17.0, 250.0, {'coliziune': 'trunk'}),
    ('G_CastanL04', _P + 'chestnut_tree_b.glb', 0.791, -19.0, 60.0, {'coliziune': 'trunk'}),
    ('G_CastanL05', _P + 'chestnut_tree_a.glb', 0.808, -17.0, 300.0, {'coliziune': 'trunk'}),
    ('G_CastanL06', _P + 'chestnut_tree_b.glb', 0.816, -16.0, 10.0, {'coliziune': 'trunk'}),
    ('G_CastanL07', _P + 'chestnut_tree_a.glb', 0.825, -17.5, 200.0, {'coliziune': 'trunk'}),
    ('G_CastanL08', _P + 'chestnut_tree_b.glb', 0.834, -16.5, 95.0, {'coliziune': 'trunk'}),
    ('G_CastanL09', _P + 'chestnut_tree_a.glb', 0.843, -17.0, 330.0, {'coliziune': 'trunk'}),
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
    ('G_Biserica', _B + 'colonnata_church.glb', 0.862, -50.0, -70.0),
    ('G_CasaA1', _B + 'colonnata_house_a.glb', 0.852, -40.0, -20.0),
    ('G_CasaB1', _B + 'colonnata_house_b.glb', 0.847, -52.0, 10.0),
    ('G_CasaC1', _B + 'colonnata_house_c.glb', 0.857, -64.0, -40.0),
    ('G_CasaB2', _B + 'colonnata_house_b.glb', 0.870, -40.0, -95.0),
    ('G_CasaA2', _B + 'colonnata_house_a.glb', 0.874, -55.0, -110.0),
    ('G_CasaC2', _B + 'colonnata_house_c.glb', 0.866, -70.0, -80.0),
    ('G_CasaA3', _B + 'colonnata_house_a.glb', 0.879, -42.0, -140.0),
    # ---- 5. exteriorul coltului SV: in fata camerei pe dreapta E-V
    ('G_CasaSV1', _B + 'colonnata_house_c.glb', 0.797, -38.0, 60.0),
    ('G_CasaSV2', _B + 'colonnata_house_b.glb', 0.801, -50.0, 80.0),
    ('G_TurnSV', _B + 'stone_tower.glb', 0.792, -52.0, 30.0),
]

KIT_Y = {
    "G_Turn": 41.02,
    "G_CisternaA": 41.29,
    "G_CisternaB": 41.25,
    "G_Bloc1": 40.9,
    "G_Bloc2": 40.67,
    "G_Bloc3": 40.5,
    "G_CastanL01": 39.41,
    "G_CastanL03": 37.81,
    "G_CastanL04": 37.32,
    "G_CastanL05": 36.22,
    "G_CastanL06": 35.61,
    "G_CastanL07": 35.07,
    "G_CastanL08": 34.35,
    "G_CastanL09": 33.64,
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
    "G_Biserica": 31.36,
    "G_CasaA1": 31.5,
    "G_CasaB1": 30.98,
    "G_CasaC1": 30.87,
    "G_CasaB2": 32.42,
    "G_CasaA2": 33.55,
    "G_CasaC2": 31.93,
    "G_CasaA3": 32.8,
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

FOREST = (
    [dict(label='lizza %d' % k, kind='disc', center=c, radius=8.0, claim=True)
     for k, c in enumerate(_LIZZA)]
    + [dict(label='camion2 %d' % k, kind='disc', center=c, radius=8.0, claim=True)
       for k, c in enumerate(_CAMION2)]
    + [
        # Satul: nimic din padure in curtea bisericii si intre case (rezervare fara specii).
        dict(label='sat S2', kind='disc', center=(-338.0, -18.0), radius=26.0, claim=True),
        dict(label='sat SV', kind='disc', center=(-360.0, 124.0), radius=24.0, claim=True),
        # Ginestra galbena pe margini (ambele parti), apoi castanii.
        dict(label='ginestra margini', kind='ring', frac_from=0.728, frac_to=0.925, side=0,
             lat_min=7.5, lat_max=13.0, spacing=3.6, edge_clear_m=2.5, shadow_m=0.0,
             species=('ginestra_fiorita',), weights=(1.0,), scale_min=1.2, scale_max=1.8, seed=71),
        dict(label='castani stanga', kind='ring', frac_from=0.728, frac_to=0.925, side=-1,
             lat_min=15.0, lat_max=140.0, spacing=8.5, edge_clear_m=12.0, shadow_m=30.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=0.85, scale_max=1.2, seed=72),
        dict(label='castani coama', kind='ring', frac_from=0.738, frac_to=0.838, side=1,
             lat_min=30.0, lat_max=80.0, spacing=9.0, edge_clear_m=24.0, shadow_m=0.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=0.9, scale_max=1.25, seed=73),
        dict(label='castani dreapta S', kind='ring', frac_from=0.843, frac_to=0.905, side=1,
             lat_min=15.0, lat_max=100.0, spacing=8.5, edge_clear_m=12.0, shadow_m=30.0,
             species=('chestnut_tree_a', 'chestnut_tree_b'), weights=(0.5, 0.5),
             scale_min=0.85, scale_max=1.2, seed=74),
        # Ginestra printre castani (sub coroane se pierde, in luminisuri iese galbena).
        dict(label='ginestra versant', kind='ring', frac_from=0.728, frac_to=0.925, side=-1,
             lat_min=13.0, lat_max=60.0, spacing=5.5, edge_clear_m=8.0, shadow_m=0.0,
             species=('ginestra_fiorita',), weights=(1.0,), scale_min=1.2, scale_max=1.9, seed=75),
    ]
)
