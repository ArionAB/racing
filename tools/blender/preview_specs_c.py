# Camere de comparatie pentru grupa mv-c (drum, gard, semne). Se incarca cu
# exec din preview_monument.py si completeaza SPECS (fara sa atinga dictul
# comun, ca sa nu intre in conflict cu celelalte grupe).
SPECS.update({
    "cattle_guard": {"category": "props",
                     "camera": {"azimuth": 62.0, "elevation": 24.0, "lens": 60.0, "margin": 1.05}},
    "open_range_sign": {"category": "props",
                        "camera": {"azimuth": 95.0, "elevation": 6.0, "lens": 70.0, "margin": 1.08}},
    "telegraph_pole": {"category": "structures",
                       "camera": {"azimuth": 90.0, "elevation": 4.0, "lens": 70.0, "margin": 1.08}},
    "wire_fence": {"category": "structures",
                   "camera": {"azimuth": 30.0, "elevation": 12.0, "lens": 60.0, "margin": 1.08}},
    "windmill_pump": {"category": "structures",
                      "camera": {"azimuth": 60.0, "elevation": 14.0, "lens": 60.0, "margin": 1.08}},
    "water_tower": {"category": "structures",
                    "camera": {"azimuth": 50.0, "elevation": 10.0, "lens": 60.0, "margin": 1.08}},
    "corral": {"category": "structures",
               "camera": {"azimuth": 60.0, "elevation": 28.0, "lens": 55.0, "margin": 1.05}},
    "shade_ramada": {"category": "structures",
                     "camera": {"azimuth": 70.0, "elevation": 12.0, "lens": 50.0, "margin": 1.05}},
})
