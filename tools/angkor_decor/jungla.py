# JUNGLA IN MASA pe Track24 (Angkor), citita de tools/gen_angkor_route.py DUPA fisierele de zona
# (luminisurile din zona_<x>.py — disc cu "claim": True si fara specii — scot padurea din piete/temple).
# Contractul: docs/track_briefs/angkor_poi_gauntlet.md, „J — Jungla in masa”.
#
# Totul aici e MeshForest (scenes/props/mesh_forest.gd): fantome, fara coliziune, in MultiMesh feliat.
# FOREST_GLBS: stem -> glb (relativ la res://assets/models/angkor/ sau res:// complet). Numele speciei
#   din FOREST = stem-ul fisierului.
# FOREST: lista de dict-uri, campurile MeshForestZone (scenes/props/mesh_forest_zone.gd):
#   "kind": "ring" (implicit; frac_from, frac_to pe INDEX, side 0/1/-1, lat_min, lat_max de la AXA)
#           sau "disc" ("center": (x, z) Godot sau "at": (frac, lateral), "radius")
#   "species", "weights", "spacing" (m), "edge_clear_m", "shadow_m", "view_m", "max_below_road_m",
#   "claim", "scale_min", "scale_max", "seed", "label"

FOREST_GLBS = {
}

FOREST = [
]
