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

# Reglaje MeshForest pentru PadureMasa (proprietati de export emise in .tscn; vezi scenes/props/mesh_forest.gd).
# Valorile sunt literale GDScript. Palmierul de zahar are evantaiul de fronde pe care generatorul de LOD nu-l
# simplifica (2330 -> 1502 triunghiuri si atat), iar etajul de mijloc e in cadru la orice distanta: i se rarasc
# frunzele pe treptele mediu (fiecare a 2-a) si grosier (fiecare a 3-a). Vezi docs/track_briefs/angkor_padure_cost.md.
FOREST_SETTINGS = {
    'frond_thin_species': 'PackedStringArray("sugar_palm")',
}

import random

_CANOPY = ('tetrameles_a', 'tetrameles_b', 'dipterocarp', 'strangler_fig')
_CANOPY_W = (0.20, 0.20, 0.57, 0.03)
_CANOPY_FAR_W = (0.06, 0.06, 0.87, 0.01)   # departe tetrameles = bete fara coroana vizibila: dipterocarp
# Etajul de mijloc (coroana la 2-12 m, in cadrul camerei de joc): palmieri de zahar, bambus, tufe.
_MID = ('sugar_palm', 'bamboo_clump', 'tropical_shrub')
_MID_W = (0.45, 0.30, 0.25)
_UNDER = ('tropical_shrub', 'fern_cluster', 'bamboo_clump')
_UNDER_W = (0.40, 0.45, 0.15)

# RUNDA 2 (4/4 critici orbi: „mesteceni albi in grila pe gazon”, coroane prea sus, liane = bete maro, tufe-varza).
#   - trunchiul (slot 19 CORAL_SAND, crem) e remapat pe gri-brun inchis in `world_prop.gd` (SLOT_REMAP_BY_THEME angkor);
#   - banda apropiata (lat < ~30 m) NU mai are copaci inalti: coroana lor (20-30 m) iesea din cadru si ramaneau doar
#     coloane. Coroanele inalte incep la 30 m (se vad in partea de sus a cadrului), iar langa drum sta etajul de 2-12 m;
#   - banda apropiata nu mai e grila: un inel rar + ciorchini (discuri) de palmieri/bambus/tufe, cu goluri intre ei;
#   - subarboretul: scara 0,8-1,3 (era 1,3-2,2), amestec de specii, frunzis oliv (slot 21 -> 12).
# Banianul (4 m) iese cu radacini in curcubeu pe sloturile Angkor: scos.
#
# APA: ferestrele de mai jos (fractii pe index) sunt rapele cu apa si santurile de langa ele. Acolo padurea are
# voie doar pe sol la cel mult 0,8 m sub cota soselei (malul), nu in albia santului.
_WATER = [(0.000, 0.070), (0.088, 0.122), (0.308, 0.372), (0.758, 0.905)]
_OPEN_SIGHT = (0.000, 0.062)   # calea de vest A: culoarul spre templu ramane deschis (vezi _clumps)


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


def _clumps(n=230, seed=7):
    """Ciorchini de etaj mijloc la 10-30 m de ax, pe o parte sau pe cealalta, cu goluri intre ei."""
    rnd = random.Random(seed)
    out = []
    for k in range(n):
        f = rnd.uniform(0.0, 1.0)
        if _OPEN_SIGHT[0] <= f <= _OPEN_SIGHT[1] and rnd.random() < 0.6:
            continue   # pe A, doar putine, ca templul sa se vada
        if any(a <= f <= b for a, b in _WATER):
            lat_ok = 1   # pe mal, max_below nu se poate pune pe disc: ramane prudent, doar spre exterior
            continue
        side = rnd.choice((-1.0, 1.0))
        lat = side * rnd.uniform(11.0, 30.0)
        out.append(dict(label='ciorchine %d' % k, kind='disc', at=(f, lat), radius=rnd.uniform(6.0, 12.0),
                        spacing=rnd.uniform(3.0, 4.2), edge_clear_m=4.0, shadow_m=0.0,
                        species=_MID, weights=_MID_W, scale_min=0.75, scale_max=1.25, seed=200 + k))
    return out


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
    # ---- coronamentul: copaci inalti de la 30 m inapoi, ca sa-si arate coroana in partea de sus a cadrului
    + _ring('coronament aproape', lat_min=30.0, lat_max=60.0, spacing=9.0, edge_clear_m=10.0, shadow_m=20.0,
            species=_CANOPY, weights=_CANOPY_W, scale_min=0.55, scale_max=0.85, seed=101)
    + _ring('coronament mediu', lat_min=60.0, lat_max=120.0, spacing=10.0, edge_clear_m=10.0, shadow_m=0.0,
            species=_CANOPY, weights=_CANOPY_FAR_W, scale_min=0.7, scale_max=1.0, seed=102)
    + _ring('coronament departe', lat_min=120.0, lat_max=190.0, spacing=13.0, edge_clear_m=10.0, shadow_m=0.0,
            species=_CANOPY, weights=_CANOPY_FAR_W, scale_min=0.8, scale_max=1.1, seed=103)
    # ---- etajul de mijloc: inel rar + ciorchini
    + _ring('etaj mijloc', lat_min=10.0, lat_max=34.0, spacing=8.0, edge_clear_m=4.0, shadow_m=0.0,
            species=_MID, weights=_MID_W, scale_min=0.75, scale_max=1.25, seed=105)
    + _clumps()
    # ---- subarboret care ascunde baza trunchiurilor
    + _ring('subarboret margine', lat_min=6.0, lat_max=26.0, spacing=2.9, edge_clear_m=2.0, shadow_m=0.0,
            species=_UNDER, weights=_UNDER_W, scale_min=0.9, scale_max=1.5, seed=104)
)
