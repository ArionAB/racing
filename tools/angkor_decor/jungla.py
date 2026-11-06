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
#
# Coordonate: discurile "center" sunt in Godot (x, z), z = -y de pe harta (nord = -Z).

FOREST_GLBS = {
    'tetrameles_a': 'plants/tetrameles_a.glb',
    'tetrameles_b': 'plants/tetrameles_b.glb',
    'dipterocarp': 'plants/dipterocarp.glb',
    'strangler_fig': 'plants/strangler_fig.glb',
    'sugar_palm': 'plants/sugar_palm.glb',
    'fern_cluster': 'res://assets/models/plants/fern_cluster.glb',
    'tropical_shrub': 'res://assets/models/plants/tropical_shrub.glb',
    'bamboo_clump': 'res://assets/models/halong/plants/bamboo_clump.glb',
}

_CANOPY = ('tetrameles_a', 'tetrameles_b', 'dipterocarp', 'strangler_fig')
_CANOPY_W = (0.26, 0.26, 0.46, 0.02)
# Etajul de mijloc: palmieri de zahar (14 m), tufe, bambus. Banianul (4 m) iese cu radacini in curcubeu pe sloturile Angkor: scos.
_MID = ('sugar_palm', 'tropical_shrub', 'bamboo_clump', 'strangler_fig')
_MID_W = (0.45, 0.30, 0.20, 0.05)
_UNDER = ('fern_cluster', 'tropical_shrub', 'sugar_palm', 'bamboo_clump')
_UNDER_W = (0.45, 0.35, 0.12, 0.08)

# Copacii kitului au 26-35 m inaltime si coroane de 19 m (AABB masurat): la scara 1 si pas 7 m, camera de joc
# (10 m sus) vedea doar trunchiuri si nicio coroana. Scara 0,55-1,0 si pas 9-13 m lasa lumina si monumentele.
FOREST = [
    # ---- luminisuri (claim, fara specii): primele, ca padurea sa le ocoleasca
    dict(label='incinta Angkor Wat', kind='disc', center=(0.0, 0.0), radius=78.0, claim=True),
    dict(label='platforma Bakheng', kind='disc', center=(-138.0, -210.0), radius=38.0, claim=True),
    dict(label='piata regala 1', kind='disc', center=(72.0, -400.0), radius=40.0, claim=True),
    dict(label='piata regala 2', kind='disc', center=(72.0, -330.0), radius=42.0, claim=True),
    dict(label='piata regala 3', kind='disc', center=(72.0, -260.0), radius=42.0, claim=True),
    dict(label='piata regala 4', kind='disc', center=(72.0, -195.0), radius=40.0, claim=True),
    dict(label='terasa Bayon 1', kind='disc', center=(-120.0, -437.0), radius=30.0, claim=True),
    dict(label='terasa Bayon 2', kind='disc', center=(-75.0, -437.0), radius=30.0, claim=True),
    dict(label='terasa Bayon 3', kind='disc', center=(-30.0, -437.0), radius=30.0, claim=True),

    # ---- coronamentul: pe toata pista, ambele parti, si in interiorul buclei
    dict(label='coronament aproape', kind='ring', frac_from=0.0, frac_to=1.0, side=0,
         lat_min=16.0, lat_max=55.0, spacing=8.0, edge_clear_m=10.0, shadow_m=20.0,
         species=_CANOPY, weights=_CANOPY_W, scale_min=0.55, scale_max=0.85, seed=101),
    dict(label='coronament mediu', kind='ring', frac_from=0.0, frac_to=1.0, side=0,
         lat_min=55.0, lat_max=120.0, spacing=10.0, edge_clear_m=10.0, shadow_m=0.0,
         species=_CANOPY, weights=_CANOPY_W, scale_min=0.7, scale_max=1.0, seed=102),
    dict(label='coronament departe', kind='ring', frac_from=0.0, frac_to=1.0, side=0,
         lat_min=120.0, lat_max=190.0, spacing=13.0, edge_clear_m=10.0, shadow_m=0.0,
         species=_CANOPY, weights=_CANOPY_W, scale_min=0.8, scale_max=1.1, seed=103),
    # ---- etajul de mijloc
    dict(label='etaj mijloc', kind='ring', frac_from=0.0, frac_to=1.0, side=0,
         lat_min=9.0, lat_max=45.0, spacing=6.5, edge_clear_m=4.0, shadow_m=0.0,
         species=_MID, weights=_MID_W, scale_min=1.0, scale_max=1.6, seed=105),
    # ---- subarboret la marginea drumului
    dict(label='subarboret margine', kind='ring', frac_from=0.0, frac_to=1.0, side=0,
         lat_min=6.0, lat_max=22.0, spacing=3.8, edge_clear_m=2.0, shadow_m=0.0,
         species=_UNDER, weights=_UNDER_W, scale_min=1.3, scale_max=2.2, seed=104),
]
