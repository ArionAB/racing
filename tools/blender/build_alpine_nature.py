"""Kitul alpin — NATURA (planşa "Swiss Alps — Alpine Switchback").

  MountainPeak  rocks/mountain_peak.glb      100 x 80 x 80 m  <= 2000 (backdrop)
  AlpineShrub   plants/alpine_shrub.glb      1.5 x 1.5 x 1.2  <= 600
  FlowerCluster flowers/flower_cluster.glb   1.5 x 1.5 x 0.6  <= 600
  SnowPatch     scatter/snow_patch.glb       5 x 5 x 0.2      <= 200

Muntele e fundal: sta la sute de metri, dincolo de ceata partiala, deci
silueta si cele trei benzi de culoare (padure - granit - zapada) sunt tot
mesajul. Granit = CONCRETE/ASPHALT_EDGE/VOLCANIC_BLACK, zapada = FOAM_WHITE,
padurea de la poale = TROPICAL_GREEN. Fara bevel — la scara asta tesitura
nu se vede, doar plateste triunghiuri.
"""

import math

# Doar doua valori apropiate: banda neagra (VOLCANIC_BLACK) iesea o pata
# stridenta pe con, nu sedimentare — vazut la prima randare.
GRANITE_STRATA = (CONCRETE, ASPHALT_EDGE)

# ============================================================ MountainPeak
# Doua varfuri (principal + umar), ca silueta sa nu fie un con simetric.
# Benzile: sub ~12 m padure, mijloc granit, peste linia zapezii alb. Linia
# de zapada nu e dreapta — urmeaza fetele, pentru ca retag lucreaza pe fete
# intregi si treapta rezultata citeste ca limba de zapada, nu ca greseala.

SNOW_LINE = 38.0
TREE_LINE = 13.0


def build_peak():
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (92.0, 74.0, 80.0), CONCRETE, seed=41,
           segments=9, rings=6, taper=0.88, squash=0.94,
           strata_slots=GRANITE_STRATA)
    b.rock((30.0, -14.0, 0.0), (48.0, 42.0, 52.0), CONCRETE, seed=57,
           segments=8, rings=5, taper=0.82, squash=0.9,
           strata_slots=GRANITE_STRATA)
    b.rock((-32.0, 10.0, 0.0), (34.0, 30.0, 34.0), CONCRETE, seed=69,
           segments=7, rings=4, taper=0.78, squash=0.9,
           strata_slots=GRANITE_STRATA)
    all_faces = set(b.bm.faces)
    # ordinea conteaza: intai padurea (banda joasa), apoi zapada peste varf.
    # Linia zapezii e o cota unica: prima incercare o cobora pe umarul estic
    # dupa c.x si jumatate de munte iesea alba pana aproape de poale.
    b.retag(all_faces, TROPICAL_GREEN, where=lambda c, n: c.z < TREE_LINE)
    b.retag(all_faces, FOAM_WHITE, where=lambda c, n: c.z > SNOW_LINE)
    return b


# ============================================================= AlpineShrub
# Trei mase rotunjite intrepatrunse — jneapanul de altitudine e o perna, nu
# un copac. Gradientul de nuanta (baza umbrita) vine din tint_gradient, DUPA
# finish (bake_ao sterge atributele de culoare — ordinea e o constrangere).

def build_shrub():
    b = Builder()
    b.boulder((0.0, 0.05, 0.5), (1.25, 1.1, 0.95), TROPICAL_GREEN, seed=13,
              segments=7, rings=3, deviation=0.15)
    b.boulder((-0.4, -0.25, 0.38), (0.8, 0.75, 0.7), TROPICAL_GREEN, seed=27,
              segments=6, rings=3, deviation=0.17)
    b.boulder((0.42, -0.3, 0.35), (0.7, 0.65, 0.62), TROPICAL_GREEN, seed=35,
              segments=6, rings=3, deviation=0.17)
    return b


# =========================================================== FlowerCluster
# Smoc de pajiste inflorita: frunze pliate in V radial + cateva flori albe pe
# tulpini — silueta de "floare" vine din capul alb pe bat, nu din petale
# (la 1.5 m diametru, petalele ar fi zgomot de frecventa inalta).

def build_flowers():
    b = Builder()
    for i, (azim, length) in enumerate(((15.0, 0.55), (72.0, 0.48),
                                        (131.0, 0.58), (198.0, 0.5),
                                        (256.0, 0.56), (310.0, 0.46))):
        leaf_vfold(b, (0.0, 0.0, 0.02), azim, length, 0.16, 0.22,
                   CACTUS_GREEN, fold_deg=26.0, stations=4, droop=0.5)
    for (x, y, h, s, seed) in ((0.1, 0.12, 0.5, 0.11, 3),
                               (-0.28, -0.1, 0.42, 0.1, 7),
                               (0.3, -0.24, 0.38, 0.09, 11),
                               (-0.05, 0.32, 0.34, 0.09, 15),
                               (0.42, 0.18, 0.3, 0.08, 19)):
        b.frustum((x, y, h * 0.5), 0.016, 0.01, h, CACTUS_GREEN, segments=4)
        b.boulder((x, y, h + s * 0.4), (s * 1.5, s * 1.5, s), FOAM_WHITE,
                  seed=seed, segments=5, rings=2, deviation=0.1)
    return b


# =============================================================== SnowPatch
# Pata de zapada ramasa in umbra: clatita neregulata, joasa, cu marginea
# tesita de bevel. AO aproape plat — zapada nu are ce sa se auto-umbreasca.

def build_snow_patch():
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (5.0, 4.6, 0.26), FOAM_WHITE, seed=8,
           segments=11, rings=1, taper=0.55, squash=0.9, flat_top=True)
    b.rock((1.4, 1.2, 0.0), (2.2, 1.9, 0.2), FOAM_WHITE, seed=16,
           segments=7, rings=1, taper=0.5, squash=0.9, flat_top=True)
    return b


# ------------------------------------------------------------------ build
ASSETS = [
    ("MountainPeak", build_peak, "rocks/mountain_peak.glb", 2000, 0.0,
     dict(samples=24, dist=30.0, gradient="vertical", low=0.55, high=1.0,
          power=0.8, floor=0.2), 60.0),
    ("AlpineShrub", build_shrub, "plants/alpine_shrub.glb", 600, 0.0,
     dict(samples=20, dist=1.2, gradient="vertical", low=0.5, high=1.0,
          power=0.9, floor=0.2), 60.0),
    ("FlowerCluster", build_flowers, "flowers/flower_cluster.glb", 600, 0.0,
     dict(samples=16, dist=0.7, gradient="vertical", low=0.55, high=1.0,
          power=1.0, floor=0.3), 60.0),
    ("SnowPatch", build_snow_patch, "scatter/snow_patch.glb", 200, 0.05,
     dict(samples=14, dist=0.8, gradient="vertical", low=0.85, high=1.0,
          power=1.0, floor=0.55), 55.0),
]

built = []
for name, make, glb, budget, bevel, ao, smooth in ASSETS:
    clear_built(name)
    b = make()
    obj = b.to_object(name)
    stats = finish(obj, bevel=bevel, bevel_angle=40.0, ao=ao,
                   smooth_angle=smooth)
    if name == "AlpineShrub":
        # baza spre umbra rece, varfurile aproape de culoarea slotului
        tint_gradient(obj, base=(0.55, 0.62, 0.55), tip=(1.05, 1.0, 0.88))
    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-14s %5d tris (buget %d) %s | %.1f x %.1f x %.1f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK" if stats["tris"] <= budget else "DEPASIT",
             dims[0], dims[1], dims[2], stats["ao_min"], stats["ao_max"]))
    print("GLB:   %s (%d B)" % export_glb([obj], glb))
    built.append(obj)

print("BLEND: %s (%d B)" % save_blend(built, "alpine_nature.blend"))
