# Camere de comparatie pentru grupa mv-f (stanci mici, grohotis, fundal). Se
# incarca cu exec din preview_monument.py si completeaza SPECS.
_CAM = dict(elevation=14.0, lens=70.0, margin=1.08)
SPECS.update({
    "butte_small_a": {"category": "rocks", "camera": dict(azimuth=75.0, **_CAM)},
    "butte_small_b": {"category": "rocks", "camera": dict(azimuth=70.0, **_CAM)},
    "butte_small_c": {"category": "rocks", "camera": dict(azimuth=80.0, **_CAM)},
    "rock_fin": {"category": "rocks", "camera": dict(azimuth=60.0, **_CAM)},
    "hoodoo": {"category": "rocks", "camera": dict(azimuth=80.0, **_CAM)},
    "talus_boulders_a": {"category": "rocks",
                         "camera": dict(azimuth=80.0, elevation=18.0, lens=70.0, margin=1.08)},
    "talus_boulders_b": {"category": "rocks",
                         "camera": dict(azimuth=80.0, elevation=18.0, lens=70.0, margin=1.08)},
    # fundalul: toate nodurile in rand (in GLB sunt la origine), clasa mv_sandstone pe fiecare
    "horizon_mesas": {"category": "rocks",
                      "spread": ["FarMesa_A", "EagleMesa_A", "FarMesa_B", "BrighamsTomb_A",
                                 "Stagecoach_A", "KingOnThrone_A", "Spires_A"],
                      "tints": {n: "mv_sandstone" for n in
                                ("EagleMesa_A", "BrighamsTomb_A", "Stagecoach_A",
                                 "KingOnThrone_A", "Spires_A", "FarMesa_A", "FarMesa_B")},
                      "camera": dict(azimuth=90.0, elevation=3.0, lens=40.0, margin=1.04)},
})

# o silueta pe imagine (pentru control; GLB-ul are 7 noduri la origine)
for _n in ("EagleMesa_A", "BrighamsTomb_A", "Stagecoach_A", "KingOnThrone_A", "Spires_A",
           "FarMesa_A", "FarMesa_B"):
    SPECS["hz_" + _n] = {"category": "rocks", "glb": "horizon_mesas", "only": _n,
                         "tints": {_n: "mv_sandstone"},
                         "camera": dict(azimuth=60.0, elevation=4.0, lens=50.0, margin=1.08)}
