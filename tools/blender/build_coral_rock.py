"""coral_rock.glb — stanci de calcar coraligen (Okinawa), doua marimi.

Referinta: assets/okinawa_inspiration/, randul CORAL ROCKS. Nu sunt bolovani:
sunt PLACI suprapuse cu streasina, ca un recif ridicat si erodat pe dedesubt.
Diferenta conteaza — un elipsoid perturbat citeste "desert", un teanc de placi
cu umbra sub fiecare citeste "coasta".

Doua variante in acelasi fisier (conventia din docs/blender_export.md):
  CoralRock_04 — 1.6 m, trei placi. Popular pe marginea drumului.
  CoralRock_06 — 2.6 m, cinci placi. Reper de silueta, pus mai rar.

Material: clasa `coral_rock`, TRIPLANAR in spatiul lumii — deci UV-urile raman
colapsate pe sloturi si placile vecine isi continua tiparul una in alta, exact
mecanica falezelor din canion. Stancile nu se misca, deci proiectia de lume e
cea corecta (style_bible §4).
"""

import math
from mathutils import Matrix

# Placile alterneaza intre bazalt si roca inchisa. Sub clasa triplanara culoarea
# vine din textura, dar sloturile raman corecte pentru fallback-ul procedural si
# pentru garda de sloturi din verify_glb.
STRATA = (VOLCANIC_BLACK, ROCK_DARK, VOLCANIC_BLACK)


def slab(b, center, size, seed, yaw=0.0):
    """O placa: pereti aproape verticali (taper mic) si capac plat.

    `taper` 0.08 in loc de 0.35: la valoarea implicita iese o movila, si tocmai
    muchia dreapta de sub capac face umbra care vinde streasina.
    """
    faces = b.rock(center, size, VOLCANIC_BLACK, seed=seed, segments=9,
                   rings=3, flat_top=True, taper=0.05, squash=0.98,
                   strata_slots=STRATA)
    if yaw:
        rot = Matrix.Rotation(math.radians(yaw), 4, "Z")
        pivot = Matrix.Translation(center) @ rot @ Matrix.Translation(
            (-center[0], -center[1], -center[2]))
        verts = set()
        for f in faces:
            verts.update(f.verts)
        for v in verts:
            v.co = pivot @ v.co
    return faces


# (x, y, z_centru, lungime, latime, inaltime, seed, yaw)
SHAPES = {
    "CoralRock_04": [
        (0.00, 0.00, 0.26, 2.90, 2.30, 0.62, 11, 0.0),
        (0.46, -0.34, 0.74, 2.35, 1.85, 0.50, 23, 22.0),
        (-0.30, 0.28, 1.18, 1.85, 1.45, 0.46, 31, -15.0),
        (0.34, 0.10, 1.54, 1.15, 0.90, 0.40, 43, 34.0),
    ],
    "CoralRock_06": [
        (0.00, 0.00, 0.32, 4.40, 3.50, 0.76, 47, 0.0),
        (0.68, -0.52, 0.92, 3.60, 2.85, 0.60, 53, 18.0),
        (-0.55, 0.48, 1.46, 2.95, 2.30, 0.56, 61, -24.0),
        (0.72, 0.44, 1.92, 2.25, 1.75, 0.50, 71, 12.0),
        (-0.28, -0.34, 2.32, 1.55, 1.20, 0.46, 83, -8.0),
        (0.30, 0.22, 2.66, 0.90, 0.72, 0.38, 97, 28.0),
    ],
}

# AO: `dist` mare (3 m) fiindca ce trebuie prins e umbra DINTRE placi, iar
# streasina de sus e la un metru de fata de dedesubt. Cu raza mica ies placi
# la fel de luminate si teancul se aplatizeaza intr-o singura masa.
AO_SPEC = dict(samples=32, dist=3.0, gradient="vertical",
               low=0.44, high=1.0, power=0.9, floor=0.14)

clear_built("CoralRock_")
built = []
for i, (name, slabs) in enumerate(SHAPES.items()):
    b = Builder()
    for (x, y, z, sx, sy, sz, seed, yaw) in slabs:
        slab(b, (x, y, z), (sx, sy, sz), seed, yaw)
    obj = b.to_object(name)
    # Bevel mic si prag de netezire jos (25° in loc de 55°): pe restul familiei
    # de stanci netezirea larga e ce le tine rotunjite, dar aici muchia dintre
    # placi E asset-ul. La 55° fatetele se topeau una in alta si teancul iesea
    # un bolovan de rau — verificat in preview inainte de a schimba cifra.
    stats = finish(obj, bevel=0.06, ao=AO_SPEC, smooth_angle=25.0)
    obj.location = (i * 6.0, 0.0, 0.0)
    built.append(obj)
    d = obj.dimensions
    print("%-14s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "coral_rock.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "coral_rock.blend"))
for i, o in enumerate(built):
    o.location = (i * 6.0, 0.0, 0.0)
