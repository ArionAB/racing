"""tetrapod.glb — spargatorul de val de beton (Okinawa, TETRAPOD_04, 3.5 m).

Referinta: assets/okinawa_inspiration/, randul TETRAPODS. Tetrapodul e piesa
care spune "coasta japoneza" mai tare decat orice altceva: dig de beton, patru
picioare tronconice dintr-un butuc central, unul in sus si trei sprijinite.

Geometrie: patru trunchiuri de con pe directiile unui tetraedru regulat, cu
varful in sus. Unghiul dintre picioare e 109.47°, nu o valoare aleasa de ochi —
cu orice altceva piesa nu mai sta pe trei picioare fara sa se legene, si se vede.

Clasa de material: `concrete` pe UV cubic (betonul e o suprafata mare si plata,
exact cazul in care culoarea plata din atlas citeste ca plastic).
Buget: piesa se instantiaza in siruri de-a lungul digului -> tinta <= 900 tris.
"""

import math
from mathutils import Vector

LEG_LEN = 2.25          # din butuc pana la talpa
R_HUB = 0.62            # raza la butuc
R_WAIST = 0.44          # cea mai subtire sectiune, la ~60% din picior
R_FOOT = 0.50           # talpa se largeste inapoi — asa arata un tetrapod real
SEGMENTS = 8            # sectiune octogonala: fatete late, fara detaliu inutil


def tetra_dirs():
    """Cele patru directii ale tetraedrului, cu un varf pe +Z.

    Picioarele de jos stau la z = -1/3 si raza sqrt(8)/3 — coordonatele exacte
    ale tetraedrului regulat inscris in sfera. Rotunjite "aproximativ", piesa
    se sprijina pe doua picioare si intra cu al treilea in nisip.
    """
    dirs = [Vector((0.0, 0.0, 1.0))]
    for k in range(3):
        a = math.radians(90.0 + k * 120.0)
        dirs.append(Vector((math.cos(a) * math.sqrt(8.0) / 3.0,
                            math.sin(a) * math.sqrt(8.0) / 3.0,
                            -1.0 / 3.0)))
    return dirs


def leg(b, direction, slot):
    """Un picior: butuc -> talie -> talpa. Statiile sunt dese la capete si rare
    la mijloc, ca bevel-ul sa aiba unde sa prinda muchia talpii."""
    d = direction.normalized()
    stations = [0.0, 0.22, 0.66, 0.93, 1.0]
    radii = [R_HUB, R_HUB * 0.82, R_WAIST, R_FOOT * 0.97, R_FOOT]
    path = [d * (LEG_LEN * s) for s in stations]
    # Primul punct porneste din centru: picioarele se intrepatrund in butuc si
    # devin un singur volum dupa bevel, fara sa fie nevoie de boolean.
    b.taper_sweep(path, radii, slot, segments=SEGMENTS,
                  cap_start=False, cap_end=True)


def build():
    b = Builder()
    # Butucul: o sfera turtita ar fi fost 4224 de triunghiuri (nota din
    # CLAUDE.md); un bolovan cu 8 segmente si 3 inele face acelasi lucru cu 48.
    b.rock((0, 0, 0), (R_HUB * 2.05, R_HUB * 2.05, R_HUB * 2.05), CONCRETE,
           seed=3, segments=SEGMENTS, rings=3, taper=0.9)
    for d in tetra_dirs():
        leg(b, d, CONCRETE)
    obj = b.to_object("Tetrapod_04")
    stats = finish(
        obj,
        bevel=0.05,
        # AO vertical pe TOATA piesa: partea de jos, prinsa intre picioare si
        # nisip, chiar sta la umbra permanent.
        ao=dict(samples=28, dist=2.0, gradient="vertical",
                low=0.52, high=1.0, power=0.85, floor=0.18),
    )
    # Beton: UV cubic la 1.5 m. Piesa are 3.5 m, deci tiparul prinde ~2.3
    # repetitii pe inaltime — destul cat sa nu se citeasca ca tapet.
    cube_uvs(obj, 1.5)
    return obj, stats


clear_built("Tetrapod_")
obj, stats = build()
size = obj.dimensions
print("Tetrapod_04  %d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
      % (stats["tris"], stats["ao_min"], stats["ao_max"],
         size.x, size.y, size.z))
print("GLB:  %s (%d B)" % export_glb([obj], "tetrapod.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "tetrapod.blend"))
