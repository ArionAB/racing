# Camere de comparatie pentru grupa mv-e (animale). Se incarca cu exec din
# preview_monument.py si completeaza SPECS (fara sa atinga dictul comun).
# Capul calului e pe +Y; decuparile il arata spre DREAPTA, deci camera sta pe
# +X (azimut ~0) si putin in fata (azimut > 0). `only` alege poza din GLB
# (decuparile: murg in picioare, pinto la pas, negru in picioare).
SPECS.update({
    "horse_bay": {"category": "animals", "only": "Pose_Stand",
                  "camera": {"azimuth": 12.0, "elevation": 7.0, "lens": 70.0, "margin": 1.08}},
    "horse_pinto": {"category": "animals", "only": "Pose_Walk",
                    "camera": {"azimuth": 12.0, "elevation": 7.0, "lens": 70.0, "margin": 1.08}},
    "horse_black": {"category": "animals", "only": "Pose_Stand",
                    "camera": {"azimuth": 12.0, "elevation": 7.0, "lens": 70.0, "margin": 1.08}},
    "sheep": {"category": "animals", "only": "Pose_Stand",
              "camera": {"azimuth": 25.0, "elevation": 9.0, "lens": 70.0, "margin": 1.08}},
    "raven": {"category": "animals",
              "camera": {"azimuth": 50.0, "elevation": 8.0, "lens": 60.0, "margin": 1.08}},
})
