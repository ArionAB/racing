"""Stromboli, kit de sat — bougainvillea (brief village_kit, piesa 13).

  Bougainvillea  stromboli/props/bougainvillea.glb
                 Bougainvillea_A / Bougainvillea_B

Floarea DOMINA, frunzisul e putin (brief). E singurul magenta din sat si
contrapunctul varului alb — de-asta foloseste CAR_RED (14), slot de masina,
abatere constienta de tip "panglici serge": sub 1 m2 pe cadru, dar semnalul
care face ulita sa nu fie doar alb pe negru.

Doua variante:
  `Bougainvillea_A` — tufa pe panou de zid 2 x 2 m (panoul e doar ghidaj, NU
                      se exporta: geometria e doar planta)
  `Bougainvillea_B` — arcada de 3 m, peste o poarta

Masele de flori sunt PLACI INTERSECTATE, nu petale: 3-4 per tufa, rotite intre
ele. La 5-20 m o placa texturata cu magenta plin citeste ca masa de flori;
petalele individuale ar costa de o suta de ori mai mult pentru acelasi efect.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_bougainvillea.py
"""

import math
from mathutils import Matrix, Vector

AO_PLANT = dict(samples=18, dist=1.6, gradient="vertical",
                low=0.68, high=1.00, power=0.9, floor=0.40)

FLOWER = CAR_RED           # magenta-rosu, accent (vezi antet)
LEAF = TROPICAL_GREEN
BRANCH = WOOD


def _lcg(seed):
    st = [seed & 0x7FFFFFFF]

    def nxt():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return nxt


def _mass(b, center, size, seed, slot=FLOWER, plates=3):
    """Masa de flori: bulgari organici suprapusi, NU placi intersectate.

    A treia versiune, si schimbarea e de metoda, nu de cote.
    
    Brief-ul cere "placi intersectate" — reteta clasica de foliaj, dar ea
    presupune o TEXTURA CU ALFA care decupeaza conturul frunzisului. Pipeline-ul
    nostru n-are alfa: UV-urile se colapseaza pe un singur texel din atlas, deci
    o placa e un dreptunghi PLIN. Rezultatul, vazut in doua randari la rand:
    intai cuburi plutitoare, apoi cartoane pe betisoare.
    
    `boulder` da o masa convexa neregulata — exact ce citeste ca tufa la 5-20 m,
    la cost comparabil. E aceeasi primitiva pe care o folosesc gramada de plase
    si muscatele din ghivece, deci vegetatia kitului ramane o familie.
    """
    rnd = _lcg(seed)
    cx, cy, cz = center
    for k in range(plates):
        f = 0.62 + 0.38 * rnd()
        b.boulder((cx + (rnd() - 0.5) * size[0] * 0.45,
                   cy + (rnd() - 0.5) * size[1] * 0.5,
                   cz + (rnd() - 0.5) * size[2] * 0.45),
                  (size[0] * f, size[1] * (0.8 + 0.4 * rnd()), size[2] * f),
                  slot, seed=seed + k * 13, segments=7, rings=3,
                  deviation=0.16)


def build_bush():
    """Tufa pe zid: masa de flori care se catara pe un panou de 2 x 2 m."""
    b = Builder()
    # ramuri: doua tulpini care urca pe zid
    for (x0, x1) in ((-0.55, -0.25), (0.35, 0.6)):
        b.beam((x0, 0.06, 0.0), (x1, 0.10, 1.55), 0.06, BRANCH)
    # frunzis putin, jos
    _mass(b, (0.0, 0.14, 0.55), (0.9, 0.30, 0.55), seed=13, slot=LEAF,
          plates=2)
    # masele de flori, sus si lateral — floarea domina
    _mass(b, (-0.35, 0.16, 1.30), (1.0, 0.34, 0.75), seed=29, plates=4)
    _mass(b, (0.50, 0.16, 1.05), (0.85, 0.32, 0.65), seed=47, plates=3)
    return b.to_object("Bougainvillea_A")


def build_arch():
    """Arcada de 3 m: flori pe o bolta peste poarta."""
    b = Builder()
    span, rise = 3.0, 2.4
    # arcul de ramuri: sase segmente pe un semicerc turtit
    pts = []
    for i in range(7):
        t = i / 6.0
        a = math.pi * t
        pts.append((-span * 0.5 * math.cos(a), 0.0,
                    rise * math.sin(a) ** 0.75))
    for i in range(6):
        b.beam(pts[i], pts[i + 1], 0.07, BRANCH)
    # masele de flori pe arc
    for i, (px, py, pz) in enumerate(pts):
        if i in (0, 6):
            continue
        _mass(b, (px, py, pz + 0.12), (0.8, 0.34, 0.55),
              seed=101 + i * 17, plates=3)
    # putin frunzis la baze
    for sx in (-1, 1):
        _mass(b, (sx * span * 0.5, 0.0, 0.5), (0.5, 0.3, 0.7),
              seed=200 + (sx > 0), slot=LEAF, plates=2)
    return b.to_object("Bougainvillea_B")


if __name__ == "__main__":
    clear_built()
    bush = build_bush()
    arch = build_arch()
    total = 0
    for obj in (bush, arch):
        stats = finish(obj, bevel=0.015, ao=AO_PLANT, origin="base")
        print("%-18s %3d tris" % (obj.name, stats["tris"]))
        total += stats["tris"]
    print("TOTAL              %3d tris  (buget 700)" % total)
    path, size = export_glb([bush, arch], "stromboli/props/bougainvillea.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
