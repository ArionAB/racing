"""butte.glb — 5 siluete pentru orizont. Brief: docs/asset_briefs/butte.md

Inlocuiesc cele 12 sfere turtite care tineau loc de dealuri de fundal. Se vad de
la 150-350 m, deci conteaza DOAR silueta: zero detaliu, buget <= 420 tris (10x3 smooth, issue #94).

Sunt reperele care te orienteaza pe pista (style_bible §7: landmark dominant la
4-6 secunde), asa ca fiecare are o forma distincta — trebuie sa poti spune "sunt
langa cea inalta si ingusta", nu sa vezi un sir de movile identice.

Sloturi: rock_dark (baza) -> rock_light (mijloc) -> sand_light (varf).
Gradientul vertical + AO dau perspectiva atmosferica coapta, gratis.
"""

import bpy


def butte(name, w, d, h, seed, tiers=2, taper=0.30):
    """Formatiune cu varf plat, construita din 1-2 trepte suprapuse.

    Treptele sunt semnatura de mesa: un singur volum ar da o movila. Fiecare
    treapta e mai ingusta si mai deschisa la culoare — de sus bate soarele.
    """
    b = Builder()
    # baza, in roca inchisa
    b.rock((0.0, 0.0, 0.0), (w, d, h * 0.62), ROCK_DARK,
           seed=seed, segments=10, rings=3, flat_top=True, taper=taper)
    # corpul, in roca deschisa, retras putin
    b.rock((0.0, 0.0, h * 0.50), (w * 0.82, d * 0.80, h * 0.42), ROCK_LIGHT,
           seed=seed + 101, segments=10, rings=3, flat_top=True, taper=taper * 0.7)
    if tiers > 1:
        # coama de nisip pe varf: linia care se citeste pe cer
        b.rock((0.0, 0.0, h * 0.86), (w * 0.60, d * 0.58, h * 0.18), SAND_LIGHT,
               seed=seed + 211, segments=7, rings=1, flat_top=True, taper=0.2)
    obj = b.to_object(name)
    stats = finish(
        obj,
        # Bevel zero: la 150 m+ o banda de 15 cm e sub un pixel, dar ar adauga
        # geometrie la fiecare muchie a unei piese care exista DOAR ca silueta.
        bevel=0.0,
        # 62°: pragul familiei de roca (vezi apply_smooth) — topeste fatetele
        # late, pastreaza buza de mesa. Silueta pe cer ramane low-poly.
        smooth_angle=62.0,
        # AO puternic jos: intuneca baza si sugereaza distanta (perspectiva
        # atmosferica), fara ceata suplimentara si fara cost de runtime.
        ao=dict(samples=20, dist=6.0, gradient="vertical",
                low=0.38, high=1.0, power=0.85, floor=0.26),
    )
    return obj, stats


# (nume, latime, adancime, inaltime, seed, trepte, taper)
# Inaltimile cresc cu distanta la care se aseaza in Godot: cele apropiate joase,
# cele departate inalte — asa apare perspectiva.
BUTTES = [
    ("Butte_A", 34.0, 28.0, 25.0, 17, 2, 0.34),   # apropiat, indesat
    ("Butte_B", 26.0, 24.0, 40.0, 37, 2, 0.30),   # mediu
    ("Butte_C", 22.0, 20.0, 60.0, 57, 2, 0.26),   # departat, turn
    ("Mesa_A", 62.0, 34.0, 18.0, 77, 1, 0.18),    # lata si joasa
    ("Mesa_B", 78.0, 40.0, 15.0, 97, 1, 0.15),    # si mai lata
]

clear_built("Butte_")
clear_built("Mesa_")
built = []
for i, (name, w, d, h, seed, tiers, tp) in enumerate(BUTTES):
    obj, stats = butte(name, w, d, h, seed, tiers, tp)
    obj.location = (i * 95.0, 0.0, 0.0)
    built.append(obj)
    print("%-9s %5.1f x %5.1f x %5.1f m -> %3d tris | AO %.2f..%.2f"
          % (name, w, d, h, stats["tris"], stats["ao_min"], stats["ao_max"]))

print("TOTAL: %d tris (10x3 smooth; era ~900 la 6x2 flat)" % sum(tri_count(o) for o in built))

for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "butte.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "butte.blend"))
for i, o in enumerate(built):
    o.location = (i * 95.0, 0.0, 0.0)
