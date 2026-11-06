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
_CANOPY_W = (0.17, 0.17, 0.64, 0.02)   # aproape: trunchiurile argintii se vad
_CANOPY_FAR_W = (0.06, 0.06, 0.87, 0.01)   # departe tetrameles = bete albe fara coroana vizibila: dipterocarp (coroana verde)
# Etajul de mijloc: palmieri de zahar (14 m la scara 1), tufe, bambus.
_MID = ('sugar_palm', 'tropical_shrub', 'bamboo_clump')
_MID_W = (0.30, 0.45, 0.25)
_UNDER = ('fern_cluster', 'tropical_shrub', 'bamboo_clump')
_UNDER_W = (0.55, 0.35, 0.10)

# Copacii kitului au 26-35 m inaltime si coroane de 19 m (AABB masurat): la scara 1 si pas 7 m, camera de joc
# (10 m sus) vedea doar trunchiuri si nicio coroana. Scara 0,55-1,0 si pas 8-13 m lasa lumina si monumentele.
# Bananul (4 m) iese cu radacini in curcubeu pe sloturile Angkor: scos. Palmierul de zahar la scara 1-1,6 era
# o morcov de 23 m: etajul de mijloc il tine la 0,55-0,9.
#
# APA: ferestrele de mai jos (fractii pe index) sunt rapele cu apa si santurile de langa ele. Acolo padurea are
# voie doar pe sol la cel mult 0,8 m sub cota soselei (malul), nu in albia santului (captura r1: palmieri in apa).
_WATER = [(0.000, 0.070), (0.088, 0.122), (0.308, 0.372), (0.758, 0.905)]


def _segments():
    out, cur = [], 0.0
    for a, b in _WATER:
        if a > cur:
            out.append((cur, a, 200.0))
        out.append((a, b, 0.8))
        cur = b
    if cur < 1.0:
        out.append((cur, 1.0, 200.0))
    return out


def _ring(label, **kw):
    return [dict(label='%s %.3f' % (label, a), kind='ring', frac_from=a, frac_to=b, side=0,
                 max_below_road_m=mb, **kw) for a, b, mb in _segments()]


FOREST = (
    [
        # ---- luminisuri (claim, fara specii): primele, ca padurea sa le ocoleasca
        dict(label='incinta Angkor Wat', kind='disc', center=(0.0, 0.0), radius=78.0, claim=True),
        dict(label='platforma Bakheng', kind='disc', center=(-138.0, -210.0), radius=38.0, claim=True),
        dict(label='piata regala 1', kind='disc', center=(72.0, -400.0), radius=30.0, claim=True),
        dict(label='piata regala 2', kind='disc', center=(72.0, -330.0), radius=30.0, claim=True),
        dict(label='piata regala 3', kind='disc', center=(72.0, -260.0), radius=30.0, claim=True),
        dict(label='piata regala 4', kind='disc', center=(72.0, -195.0), radius=30.0, claim=True),
        dict(label='terasa Bayon 1', kind='disc', center=(-120.0, -437.0), radius=22.0, claim=True),
        dict(label='terasa Bayon 2', kind='disc', center=(-75.0, -437.0), radius=22.0, claim=True),
        dict(label='terasa Bayon 3', kind='disc', center=(-30.0, -437.0), radius=22.0, claim=True),
    ]
    # ---- coronamentul: pe toata pista, ambele parti, si in interiorul buclei
    + _ring('coronament aproape', lat_min=16.0, lat_max=55.0, spacing=6.5, edge_clear_m=10.0, shadow_m=20.0,
            species=_CANOPY, weights=_CANOPY_W, scale_min=0.55, scale_max=0.85, seed=101)
    + _ring('coronament mediu', lat_min=55.0, lat_max=120.0, spacing=10.0, edge_clear_m=10.0, shadow_m=0.0,
            species=_CANOPY, weights=_CANOPY_FAR_W, scale_min=0.7, scale_max=1.0, seed=102)
    + _ring('coronament departe', lat_min=120.0, lat_max=190.0, spacing=13.0, edge_clear_m=10.0, shadow_m=0.0,
            species=_CANOPY, weights=_CANOPY_FAR_W, scale_min=0.8, scale_max=1.1, seed=103)
    # ---- etajul de mijloc
    + _ring('etaj mijloc', lat_min=9.0, lat_max=45.0, spacing=4.8, edge_clear_m=4.0, shadow_m=0.0,
            species=_MID, weights=_MID_W, scale_min=0.6, scale_max=1.0, seed=105)
    # ---- subarboret la marginea drumului
    + _ring('subarboret margine', lat_min=6.0, lat_max=30.0, spacing=3.4, edge_clear_m=2.0, shadow_m=0.0,
            species=_UNDER, weights=_UNDER_W, scale_min=1.3, scale_max=2.2, seed=104)
)
