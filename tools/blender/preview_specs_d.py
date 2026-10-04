# Camere de comparatie pentru grupa mv-d (cladiri, vehicule, oameni). Se
# incarca cu exec din preview_monument.py si completeaza SPECS (fara sa atinga
# dictul comun, ca sa nu intre in conflict cu celelalte grupe).
# Azimutul: fata piesei e +Y (azimut 90 = din fata); 3/4 din fata = 60 sau 120.
SPECS.update({
    "trading_post": {"category": "buildings",
                     "camera": {"azimuth": 62.0, "elevation": 22.0, "lens": 60.0, "margin": 1.06}},
    "homestead_house": {"category": "buildings",
                        "camera": {"azimuth": 38.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "hogan": {"category": "buildings",
              "camera": {"azimuth": 75.0, "elevation": 18.0, "lens": 60.0, "margin": 1.06}},
    "pickup_old": {"category": "vehicles",
                   "camera": {"azimuth": 52.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "tour_truck": {"category": "vehicles",
                   "camera": {"azimuth": 52.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "tourist_group": {"category": "props",
                      "camera": {"azimuth": 90.0, "elevation": 6.0, "lens": 70.0, "margin": 1.08}},
})
