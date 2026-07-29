"""route66_sign.glb — scut US highway pe stalp. Brief: docs/asset_briefs/route66_sign.md

Buget: <= 250 triunghiuri. Cifrele "66" NU se modeleaza — silueta de scut plus
contrastul beton/asfalt fac citirea. Fata scutului spre -Z in Godot (= +Y Blender).
"""

POST_H = 2.80
POST_W = 0.12
SHIELD_Z = 2.40      # centrul scutului pe verticala
SHIELD_W = 0.90
SHIELD_H = 1.00
INSET = 0.86         # placa-fata, inset ~0.06 m pe latura


def shield_outline(width, height):
    """Silueta clasica de US route shield: umeri rotunjiti sus, talie stransa,
    baza usor ascutita. Tinut la 10 puncte — bugetul nu suporta mai mult, iar
    la viteza conteaza doar silueta."""
    half = [
        (0.00,  0.45),
        (0.24,  0.50),
        (0.45,  0.38),
        (0.40,  0.02),
        (0.24, -0.30),
        (0.00, -0.50),
    ]
    pts = list(half)
    for x, z in reversed(half[1:-1]):   # oglindire, fara sa dublam polii
        pts.append((-x, z))
    return [(x * width, z * height) for x, z in pts]


clear_built("Route66")
b = Builder()

# Stalp — chunky (brief: nu subtire). Metal RUGINIT, nu vopsit: brief-ul ofera
# ambele, iar albastrul rece al slotului painted_metal se citea ca un corp strain
# intre nisip si lemn (verificat in viewport).
b.box(center=(0.0, 0.0, POST_H * 0.5), size=(POST_W, POST_W, POST_H), slot=RUST)

outline = shield_outline(SHIELD_W, SHIELD_H)
inner = shield_outline(SHIELD_W * INSET, SHIELD_H * INSET)

# Placa-fundal = rama intunecata (asfalt: cea mai inchisa suprafata din lume)
b.prism(outline, 0.08, ASPHALT, center=(0.0, 0.09, SHIELD_Z))
# Placa-fata = campul deschis, in relief usor peste fundal
b.prism(inner, 0.05, CONCRETE, center=(0.0, 0.155, SHIELD_Z))

obj = b.to_object("Route66Sign")
stats = finish(
    obj,
    bevel=0.04, bevel_angle=55.0,   # 55° = prinde muchiile drepte, sare peste conturul scutului
    ao=dict(samples=24, dist=1.0, gradient="vertical",
            low=0.60, high=1.00, power=1.0, floor=0.35),
    # originea pe axa stalpului, nu pe centrul bbox-ului (scutul iese in fata pe Y)
    origin="base_axis",
)

print("Route66Sign -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("GLB:   %s (%d B)" % export_glb([obj], "route66_sign.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "route66_sign.blend"))
