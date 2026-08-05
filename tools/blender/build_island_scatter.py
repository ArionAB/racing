"""island_scatter.glb — maruntisurile de plaja (Okinawa), echivalentul
desert_scatter de pe Dunele.

NUMELE NODURILOR SUNT CONTRACT. `track_decor._add_island_scatter`
(`scenes/tracks/track_decor.gd:270`) alege din lista:

    Beach_Grass, Driftwood, Coral_Pebbles, Hibiscus

Orice alt nume => `_pick_from_glb` intoarce null, Godot cade tacut pe tufa
provizorie de sfere si nimeni nu observa pana la urmatorul screenshot.

SCARA E DICTATA DE APELANT, si asta e neintuitiv: piesele sunt instantiate cu
`scale = randf_range(1.4, 2.1)`. Deci se modeleaza la 0.35-0.55 m, ca in joc sa
iasa la 0.5-1.1 m. Modelate la marimea "corecta" ar fi iesit tufe de doi metri
pe banda lipita de drum.

BUGETUL E CEL CARE DICTEAZA FORMA AICI, si a fost masurat, nu presupus. Benzile
de decor pun ~560 de piese de scatter pe un tur de Okinawa. Prima versiune avea
Beach_Grass la 392 de triunghiuri si Hibiscus la 264: doar scatter-ul ajungea la
134 000, adica jumatate din bugetul pistei, pentru obiecte de sub un metru
vazute la 100 km/h. Tinta e acum **sub 130 tris bucata** (~70 000 pe tur), si de
aia iarba are 6 fire in loc de 14 si pietrele 4 in loc de 7.

Aceeasi lectie ca la tufele-sfera pe care le inlocuiesc — comentariul din
`_add_tropical_bush` o spune pentru placeholder-e; se aplica identic pentru
assets adevarate. Niciuna n-are bevel: sunt suprafete de revolutie si lamele,
unde bevel-ul tripleaza costul fara castig (ca la cactus).

Materiale: tot pe atlasul de paleta. Sub 1 m textura nu se citeste
(style_bible §4, regula pentru marker_post / scatter / prop-uri marunte).
"""

import math
from mathutils import Vector

AO_SPEC = dict(samples=20, dist=1.0, gradient="vertical",
               low=0.48, high=1.0, power=0.7, floor=0.18)


def beach_grass(b):
    """Smoc de iarba de plaja: lame inguste care ies in evantai din nisip.

    Lamele pornesc din puncte DIFERITE pe un cerc mic, nu toate din origine:
    un evantai perfect concurent citeste ca o floare, unul cu baza raspandita
    citeste ca un smoc care a crescut.
    """
    rnd = _lcg(37)
    for k in range(6):
        a = rnd() * math.tau
        base_r = rnd() * 0.07
        lean = 0.22 + rnd() * 0.30      # cat se apleaca varful in afara
        h = 0.34 + rnd() * 0.20
        d = Vector((math.cos(a), math.sin(a), 0.0))
        path = [d * base_r,
                d * (base_r + lean * 0.45) + Vector((0, 0, h * 0.70)),
                d * (base_r + lean) + Vector((0, 0, h * 0.98))]
        slot = TROPICAL_GREEN if k % 3 else DRY_VEGETATION
        b.blade(path, [0.036, 0.026, 0.0], 0.012, slot, up=(0, 0, 1))


def driftwood(b):
    """Buturuga adusa de apa: trunchi scurt, decolorat, cu doua cioturi.

    Culcata pe o parte, cu cioturile in sus — asa arata lemnul aruncat de
    valuri. Slotul e DRY_VEGETATION, nu WOOD: lemnul spalat de mare si ars de
    soare e cenusiu-pal, nu maro de scandura.
    """
    b.taper_sweep([(-0.24, 0.0, 0.075), (-0.05, 0.03, 0.09),
                   (0.16, -0.02, 0.085), (0.30, 0.02, 0.06)],
                  [0.055, 0.075, 0.065, 0.0], DRY_VEGETATION, segments=6)
    b.taper_sweep([(-0.03, 0.02, 0.10), (0.02, 0.10, 0.20)],
                  [0.030, 0.0], DRY_VEGETATION, segments=5)
    b.taper_sweep([(0.13, -0.01, 0.10), (0.20, -0.09, 0.17)],
                  [0.024, 0.0], DRY_VEGETATION, segments=5)


def coral_pebbles(b):
    """Gramajoara de pietre de corali. Trei marimi, ca sa nu citeasca a grila."""
    rnd = _lcg(53)
    for k in range(4):
        a = rnd() * math.tau
        r = rnd() * 0.20
        s = 0.07 + rnd() * 0.09
        slot = CORAL_SAND if k % 2 else VOLCANIC_BLACK
        b.rock((math.cos(a) * r, math.sin(a) * r, s * 0.30),
               (s * 2.2, s * 1.8, s * 1.05), slot, seed=53 + k * 7,
               segments=6, rings=2, flat_top=True, taper=0.25)


def hibiscus_small(b):
    """Hibiscus tanar. Versiunea de scatter a lui hibiscus_bush.glb, la 0.40 m
    in loc de 0.86 — ca sa supravietuiasca scalarii de 1.4-2.1 a apelantului
    fara sa devina un tufis de doi metri langa asfalt."""
    rnd = _lcg(29)
    for k in range(3):
        a = rnd() * math.tau
        r = 0.0 if k == 0 else 0.10 * (0.6 + rnd() * 0.7)
        s = 0.30 - r * 0.25 + rnd() * 0.08
        b.boulder((math.cos(a) * r, math.sin(a) * r, 0.16 + rnd() * 0.07),
                  (s, s * 0.94, s * 0.80),
                  TROPICAL_GREEN if k % 2 else CACTUS_GREEN,
                  seed=29 + k * 11, segments=5, rings=3, deviation=0.16)
    # Trei flori, nu patru: la scara asta (0.10 m inainte de scalarea de 1.4-2.1
    # a apelantului) o floare e trei pixeli, iar a patra nu adauga culoare, doar
    # cost.
    for k in range(3):
        a = rnd() * math.tau + 0.7
        r = 0.17 * (0.85 + rnd() * 0.25)
        b.boulder((math.cos(a) * r, math.sin(a) * r, 0.16 + rnd() * 0.14),
                  (0.10, 0.10, 0.05), KERB_RED, seed=71 + k * 13,
                  segments=4, rings=2, deviation=0.10)


PARTS = [
    ("Beach_Grass", beach_grass),
    ("Driftwood", driftwood),
    ("Coral_Pebbles", coral_pebbles),
    ("Hibiscus", hibiscus_small),
]

clear_built("Beach_Grass")
clear_built("Driftwood")
clear_built("Coral_Pebbles")
clear_built("Hibiscus")
built = []
for name, fill in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.0, ao=AO_SPEC)
    built.append(obj)
    d = obj.dimensions
    print("%-16s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "island_scatter.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "island_scatter.blend"))
for i, o in enumerate(built):
    o.location = (i * 1.2, 0.0, 0.0)
