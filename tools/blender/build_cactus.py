"""cactus.glb — 2-3 variante de saguaro. Brief: docs/asset_briefs/cactus.md

Buget: <= 180 triunghiuri per cactus. Un singur slot de paleta (cactus_green).
AO: jumatatea de jos net mai inchisa (style_bible §4, vegetatie).
"""

import math
import bpy
from mathutils import Matrix

TRUNK_SIDES = 8
ARM_SIDES = 6


def trunk_profile(h, r=0.26):
    """Coloana cu bulge la mijloc si varf in dom (nu con ascutit)."""
    return [
        (r * 0.92, 0.00),
        (r * 1.08, h * 0.20),   # bulge
        (r * 0.98, h * 0.62),
        (r * 0.80, h * 0.88),   # umar
        (r * 0.46, h * 0.968),  # dom
        (0.0,      h),          # apex
    ]


def add_arm(b, angle_deg, z_start, out=0.60, rise=0.85, r=0.145):
    """Cotul clasic de saguaro: iese orizontal din trunchi, apoi urca."""
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)

    def p(dist, z):
        return (ca * dist, sa * dist, z)

    path = [
        p(0.10, z_start),              # inauntrul trunchiului (se intrepatrund)
        p(out, z_start + 0.10),        # cotul
        p(out + 0.02, z_start + rise),  # coloana verticala
    ]
    return b.sweep(path, r, CACTUS_GREEN, segments=ARM_SIDES,
                   dome_end=True, cap_start=True, dome_rings=1)


def build(name, height, arms):
    b = Builder()
    b.revolve(trunk_profile(height), CACTUS_GREEN, segments=TRUNK_SIDES)
    for angle, frac in arms:
        add_arm(b, angle, height * frac)
    obj = b.to_object(name)
    stats = finish(
        obj,
        # Fara bevel, deliberat: cactusul e o suprafata de revolutie, nu are muchii
        # dure de rotunjit. Singura muchie ascutita e rama de la baza, ingropata in
        # nisip. Bevel-ul o triplica bugetul de triunghiuri fara castig vizual.
        bevel=0.0,
        # tranzitie agresiva in treimea de jos: power < 1 urca repede
        ao=dict(samples=24, dist=1.6, gradient="vertical",
                low=0.50, high=0.95, power=0.6, floor=0.32),
    )
    return obj, stats


CACTI = [
    ("Cactus_A", 4.40, [(20.0, 0.42), (205.0, 0.56)]),  # doua brate
    ("Cactus_B", 3.50, [(115.0, 0.48)]),                # un brat
    ("Cactus_C", 2.85, []),                             # fara brate
]

clear_built("Cactus_")
built = []
for i, (name, h, arms) in enumerate(CACTI):
    obj, stats = build(name, h, arms)
    obj.location = (i * 2.6, 0.0, 0.0)  # doar pentru vizualizare in viewport
    built.append(obj)
    print("%-10s h=%.2f brate=%d -> %4d tris | AO %.2f..%.2f"
          % (name, h, len(arms), stats["tris"], stats["ao_min"], stats["ao_max"]))

print("TOTAL tris:", sum(tri_count(o) for o in built))

# La export fiecare cactus pleaca din origine (le instantiem individual in Godot);
# decalajul de mai sus a fost doar ca sa nu se suprapuna in viewport.
for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "cactus.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "cactus.blend"))
for i, o in enumerate(built):
    o.location = (i * 2.6, 0.0, 0.0)
