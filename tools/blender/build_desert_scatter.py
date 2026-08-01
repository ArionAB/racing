"""desert_scatter.glb — filler pentru banda lipita de drum.
Brief: docs/asset_briefs/desert_scatter.md

Piesele astea se aseaza la 1.5-4 m de asfalt, FARA coliziune: treci prin ele.
Rolul lor e sa dea senzatia de ingustime a canionului, nu sa te opreasca.

CEL MAI IMPORTANT BUGET DIN TOT PLANUL: ~115 instante pe pista, deci fiecare
triunghi in plus se inmulteste cu 115. Buget <= 40 tris fiecare, <= 200 total.
Zero bevel peste tot — la marimea asta nu se vede, dar s-ar plati de 115 ori.

Sloturi: dry_vegetation (tufe, smocuri), rock_light / sand_shadow (pietricele).
"""

import bpy


def bush(name, w, h, seed, slot=None):
    """Tufa uscata: o masa neregulata, turtita. Fara frunze — la 60 km/h ar fi
    zgomot vizual, si ar costa de 115 ori."""
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (w, w * 0.85, h),
           DRY_VEGETATION if slot is None else slot,
           seed=seed, segments=5, rings=2, taper=0.55, squash=0.7)
    obj = b.to_object(name)
    stats = finish(
        obj, bevel=0.0,
        # Jumatatea de jos net mai inchisa (style_bible §4, vegetatie): fara
        # gradientul asta tufele par lipite pe nisip, nu crescute din el.
        ao=dict(samples=16, dist=1.0, gradient="vertical",
                low=0.45, high=1.0, power=0.6, floor=0.30),
    )
    return obj, stats


def pebbles(name, pieces, seed_base):
    """Grup de pietricele plate. Sub 30 cm — sugereaza sfaramatura de la baza
    falezei."""
    b = Builder()
    for i, (off, size) in enumerate(pieces):
        b.rock(off, size, ROCK_LIGHT if i % 2 == 0 else SAND_SHADOW,
               seed=seed_base + i * 37, segments=4, rings=1,
               taper=0.5, squash=0.6)
    obj = b.to_object(name)
    stats = finish(
        obj, bevel=0.0,
        ao=dict(samples=12, dist=0.6, gradient="vertical",
                low=0.55, high=1.0, power=0.8, floor=0.35),
    )
    return obj, stats


def grass_tuft(name, seed):
    """Smoc de iarba uscata: cateva lame late, nu fire. Trei prisme inclinate
    citesc ca smoc de la distanta si costa 24 de triunghiuri."""
    b = Builder()
    import math
    from mathutils import Euler
    for i, (ang, tilt, h) in enumerate([(10, 12, 0.55), (135, -9, 0.42),
                                        (255, 7, 0.48)]):
        a = math.radians(ang)
        b.box((math.cos(a) * 0.08, math.sin(a) * 0.08, h * 0.5),
              (0.16, 0.03, h), DRY_VEGETATION,
              rotation=Euler((math.radians(tilt), 0.0, a), "XYZ"))
    obj = b.to_object(name)
    stats = finish(
        obj, bevel=0.0,
        ao=dict(samples=12, dist=0.8, gradient="vertical",
                low=0.40, high=1.0, power=0.5, floor=0.28),
    )
    return obj, stats


clear_built("Bush_")
clear_built("Pebbles_")
clear_built("Grass_")

built = []
specs = []

for name, w, h, seed in [("Bush_A", 0.95, 0.62, 13), ("Bush_B", 0.68, 0.48, 31)]:
    obj, st = bush(name, w, h, seed)
    specs.append((name, st))
    built.append(obj)

for name, pcs, sb in [
    ("Pebbles_A", [((0.0, 0.0, 0.0), (0.34, 0.28, 0.16)),
                   ((0.26, 0.14, 0.0), (0.20, 0.18, 0.11))], 53),
    ("Pebbles_B", [((0.0, 0.0, 0.0), (0.42, 0.30, 0.13)),
                   ((-0.22, 0.18, 0.0), (0.18, 0.16, 0.09)),
                   ((0.20, -0.16, 0.0), (0.15, 0.14, 0.08))], 73),
]:
    obj, st = pebbles(name, pcs, sb)
    specs.append((name, st))
    built.append(obj)

obj, st = grass_tuft("Grass_Tuft", 97)
specs.append(("Grass_Tuft", st))
built.append(obj)

for i, o in enumerate(built):
    o.location = (i * 2.0, 0.0, 0.0)
for name, st in specs:
    print("%-12s %3d tris | AO %.2f..%.2f"
          % (name, st["tris"], st["ao_min"], st["ao_max"]))
print("TOTAL: %d tris (buget 200)" % sum(tri_count(o) for o in built))

for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "desert_scatter.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "desert_scatter.blend"))
for i, o in enumerate(built):
    o.location = (i * 2.0, 0.0, 0.0)
