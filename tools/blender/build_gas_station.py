"""gas_station.glb — benzinarie de sosea. Brief: docs/asset_briefs/gas_station.md

Buget: <= 1800 triunghiuri. Piesa "hero": silueta mare, zero detaliu fin.
Fata cu pompele spre -Z in Godot (= +Y in Blender).
"""

import math
from mathutils import Matrix

SLAB_T = 0.20
WALL_TOP = 3.20
ROOF_PITCH = math.radians(18.0)   # style_bible §3: panta 18°, regula de coerenta

BLD_X, BLD_Y = -1.30, -1.00       # centrul cladirii pe dala
BLD_W, BLD_D = 5.00, 4.00
OVERHANG = 0.30

# Panta de 18° peste jumatatea de adancime + streasina da coama la ~3.95 m.
# (Brief-ul spune "coama la ~4.6 m", dar asta ar cere 35° si ar rupe regula de
# panta din style bible. Am pastrat panta; nota in raport.)
ROOF_HALF = BLD_D * 0.5 + OVERHANG
ROOF_RISE = ROOF_HALF * math.tan(ROOF_PITCH)
RIDGE_Z = WALL_TOP + ROOF_RISE
SLOPE_LEN = ROOF_HALF / math.cos(ROOF_PITCH)

CANOPY_X, CANOPY_Y = 0.50, 1.80
CANOPY_W, CANOPY_D = 4.50, 2.80
CANOPY_Z = 3.60


def star_outline(radius, inner=0.42, points=5):
    """Stea simpla pentru accentul de langa panou. Contur 2D in planul XZ."""
    pts = []
    for i in range(points * 2):
        a = math.radians(-90.0 + i * (360.0 / (points * 2)))
        r = radius if i % 2 == 0 else radius * inner
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


clear_built("GasStation")
b = Builder()

# --------------------------------------------------------------- fundatie
b.box(center=(0.0, 0.0, SLAB_T * 0.5), size=(8.0, 6.0, SLAB_T), slot=CONCRETE)

# --------------------------------------------------------------- cladire
b.box(center=(BLD_X, BLD_Y, (SLAB_T + WALL_TOP) * 0.5),
      size=(BLD_W, BLD_D, WALL_TOP - SLAB_T), slot=WOOD)

# Acoperis in doua ape, coama pe X, cu streasina
for sign in (+1, -1):
    b.box(center=(BLD_X, BLD_Y + sign * ROOF_HALF * 0.5, WALL_TOP + ROOF_RISE * 0.5),
          size=(BLD_W + 2 * OVERHANG, SLOPE_LEN, 0.16), slot=RUST,
          rotation=Matrix.Rotation(-sign * ROOF_PITCH, 3, "X"))
b.box(center=(BLD_X, BLD_Y, RIDGE_Z), size=(BLD_W + 2 * OVERHANG, 0.22, 0.14), slot=RUST)

# Usa + doua ferestre: placi intunecate lipite de peretele din fata (+Y).
# "Golul" e slotul de asfalt — cea mai inchisa suprafata din lume.
FRONT_Y = BLD_Y + BLD_D * 0.5
b.box(center=(BLD_X - 1.30, FRONT_Y - 0.02, SLAB_T + 1.05), size=(0.90, 0.12, 2.10), slot=ASPHALT)
b.box(center=(BLD_X + 0.10, FRONT_Y - 0.02, SLAB_T + 1.90), size=(1.40, 0.12, 1.20), slot=ASPHALT)
b.box(center=(BLD_X + 1.70, FRONT_Y - 0.02, SLAB_T + 1.90), size=(1.00, 0.12, 1.20), slot=ASPHALT)

# --------------------------------------------------------------- copertina
b.box(center=(CANOPY_X, CANOPY_Y, CANOPY_Z), size=(CANOPY_W, CANOPY_D, 0.22), slot=RUST)
# fascia: dunga de accent pe muchia din fata, ca sa se citeasca copertina de departe
b.box(center=(CANOPY_X, CANOPY_Y + CANOPY_D * 0.5, CANOPY_Z - 0.16),
      size=(CANOPY_W, 0.14, 0.20), slot=KERB_RED)
for dx in (-1.90, 1.90):
    b.box(center=(CANOPY_X + dx, CANOPY_Y + CANOPY_D * 0.5 - 0.30,
                  (SLAB_T + CANOPY_Z) * 0.5),
          size=(0.26, 0.26, CANOPY_Z - SLAB_T), slot=WOOD)

# --------------------------------------------------------------- pompe
b.box(center=(CANOPY_X, CANOPY_Y, SLAB_T + 0.075), size=(2.80, 0.90, 0.15), slot=CONCRETE)
for dx in (-0.90, 0.90):
    px = CANOPY_X + dx
    base = SLAB_T + 0.15
    b.box(center=(px, CANOPY_Y, base + 0.60), size=(0.60, 0.40, 1.20), slot=CONCRETE)
    b.box(center=(px, CANOPY_Y, base + 1.26), size=(0.62, 0.42, 0.12), slot=PAINTED)
    # ciocul: bloc scurt, NU tub subtire (se pierde la viteza)
    b.box(center=(px, CANOPY_Y + 0.30, base + 0.95), size=(0.16, 0.22, 0.16), slot=PAINTED)

# --------------------------------------------------------------- panou "GAS STATION"
PANEL_Z = RIDGE_Z + 0.55
for dx in (-0.85, 0.85):
    b.box(center=(BLD_X + dx, FRONT_Y - 0.35, RIDGE_Z - 0.10),
          size=(0.12, 0.12, 1.00), slot=PAINTED)
b.box(center=(BLD_X, FRONT_Y - 0.40, PANEL_Z), size=(2.60, 0.12, 0.86), slot=KERB_RED)
b.box(center=(BLD_X, FRONT_Y - 0.30, PANEL_Z), size=(2.40, 0.10, 0.70), slot=CONCRETE)

# Stea de accent. NU galben: sloturile 14-16 sunt rezervate masinilor (style_bible §1).
b.prism(star_outline(0.42), 0.12, KERB_RED, center=(BLD_X + 1.90, FRONT_Y - 0.35, PANEL_Z + 0.10))

obj = b.to_object("GasStation")
stats = finish(
    obj,
    bevel=0.08, bevel_angle=30.0,
    ao=dict(samples=32, dist=3.5, gradient="vertical",
            low=0.55, high=1.00, power=1.0, floor=0.30),
)

print("GasStation -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("coama la %.2f m (panta %.0f°)" % (RIDGE_Z, math.degrees(ROOF_PITCH)))
print("GLB:   %s (%d B)" % export_glb([obj], "gas_station.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "gas_station.blend"))
