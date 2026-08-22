"""Stromboli, kit de flanc — vegetatia (brief slope_kit, piesele 2-6).

Cinci fisiere, construite de acelasi script fiindca impart aceleasi decizii de
cost. Fiecare se exporta SEPARAT, cu nodurile lui:

  fig_tree.glb       Fig_Trunk / Fig_Canopy
  prickly_pear.glb   Prickly_A / Prickly_B
  caper_bush.glb     Caper_Bush
  ginestra_bush.glb  Ginestra_A / Ginestra_B
  cane_clump.glb     Cane_Clump

**BEVEL 0 PE FRUNZIS.** Regula kitului, gasita pe maslin: o coroana de 5
volume trece de la 210 la 684 de triunghiuri daca primeste bevel, pentru o
tesitura pe care n-o vede nimeni intr-o masa de frunze. Bugetele astea sunt de
BANDA (piesele se planteaza cu sutele, memoria `vegetatie-cost-pe-pas`), deci
economia se inmulteste cu sute. Bevelul ramane pe lemn si pe roca.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_slope_plants.py
"""

import math
from mathutils import Matrix, Vector

AO_PLANT = dict(samples=16, dist=2.0, gradient="vertical",
                low=0.55, high=1.00, power=0.9, floor=0.32)

TRUNK = WOOD
OLIVE_LEAF = DRY_VEGETATION      # argintiu / oliv
GREEN = TROPICAL_GREEN           # verde saturat: smochin, opuntia, capere
FRUIT = TILE_TERRACOTTA          # fructele opuntiei


def _lcg(seed):
    st = [seed & 0x7FFFFFFF]

    def nxt():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return nxt


def _finish_all(objs, budget, label, wood_bevel=0.03):
    total = 0
    for obj in objs:
        # bevel doar pe lemn/roca; frunzisul primeste 0 (vezi antet)
        woody = any(k in obj.name for k in ("Trunk", "Wall", "Slab", "Rock"))
        stats = finish(obj, bevel=wood_bevel if woody else 0.0,
                       ao=AO_PLANT, origin=None)
        print("  %-18s %3d tris" % (obj.name, stats["tris"]))
        total += stats["tris"]
    print("  TOTAL              %3d tris  (buget %d)" % (total, budget))
    return total


# ============================================================ 2. smochinul
def build_fig():
    """Trunchi scurt ramificat jos, coroana LATA (Ø 6 m) si joasa."""
    rnd = _lcg(41)
    b = Builder()
    # trunchi scurt, care se desface in trei brate de la 1.2 m
    b.taper_sweep([(0, 0, 0), (0.06, 0.03, 0.7), (0.0, -0.04, 1.3)],
                  [0.26, 0.23, 0.19], TRUNK, segments=6)
    for k in range(3):
        a = 2.0 * math.pi * k / 3.0 + 0.4
        b.taper_sweep([(0.0, -0.04, 1.25),
                       (0.5 * math.cos(a), 0.5 * math.sin(a), 1.9),
                       (0.95 * math.cos(a), 0.95 * math.sin(a), 2.5)],
                      [0.15, 0.11, 0.07], TRUNK, segments=5)
    trunk = b.to_object("Fig_Trunk")

    # coroana lata si joasa: 4 volume mari, turtite
    b = Builder()
    for k in range(4):
        a = 2.0 * math.pi * k / 4.0 + rnd() * 0.6
        rr = 1.35 * (0.45 + 0.55 * rnd())
        b.boulder((rr * math.cos(a), rr * math.sin(a), 3.2 + (rnd() - 0.5) * 0.5),
                  (3.0, 3.0, 1.5), GREEN, seed=41 + k * 13,
                  segments=7, rings=3, deviation=0.14)
    canopy = b.to_object("Fig_Canopy")
    return [trunk, canopy]


# ============================================================ 3. opuntia
def _paddle(b, base, azim, tilt, length, width, seed):
    """O paleta de opuntia: elipsoid TURTIT, cu grosime reala (0.08)."""
    a = math.radians(azim)
    t = math.radians(tilt)
    d = Vector((math.cos(a) * math.sin(t), math.sin(a) * math.sin(t),
                math.cos(t)))
    c = Vector(base) + d * (length * 0.5)
    rot = Matrix.Rotation(a, 3, "Z") @ Matrix.Rotation(t, 3, "Y")
    b.boulder(tuple(c), (width, 0.10, length), GREEN, seed=seed,
              segments=6, rings=3, deviation=0.05)
    return tuple(Vector(base) + d * length)


def build_prickly():
    """Opuntia: palete inlantuite. Varianta mare 2.5 m, mica 1.5 m."""
    out = []
    for (name, height, npad, seed) in (("Prickly_A", 2.5, 9, 61),
                                       ("Prickly_B", 1.5, 5, 83)):
        rnd = _lcg(seed)
        b = Builder()
        # lantul de palete: fiecare creste din varful uneia precedente
        tips = [(0.0, 0.0, 0.0)]
        for k in range(npad):
            base = tips[int(rnd() * len(tips) * 0.85)]
            azim = rnd() * 360.0
            tilt = 12.0 + rnd() * 34.0
            ln = height * (0.26 + 0.12 * rnd())
            wd = ln * (0.62 + 0.2 * rnd())
            tip = _paddle(b, base, azim, tilt, ln, wd, seed + k * 7)
            tips.append(tip)
        # fructe pe muchiile de sus ale ultimelor palete
        for tip in tips[-3:]:
            b.boulder((tip[0], tip[1], tip[2] + 0.04), (0.11, 0.11, 0.15),
                      FRUIT, seed=seed + 200, segments=6, rings=3,
                      deviation=0.05)
        out.append(b.to_object(name))
    return out


# ============================================================ 4. caperele
def build_caper():
    """Tufa revarsata: emisfera neregulata turtita, 0.8 m inaltime, Ø 1.2."""
    b = Builder()
    b.boulder((0.0, 0.0, 0.34), (1.2, 1.15, 0.72), OLIVE_LEAF, seed=97,
              segments=8, rings=3, deviation=0.17)
    # doua revarsari laterale, mai mici
    for (dx, dy, sd) in ((0.42, -0.18, 101), (-0.36, 0.30, 103)):
        b.boulder((dx, dy, 0.20), (0.55, 0.5, 0.34), OLIVE_LEAF, seed=sd,
                  segments=6, rings=2, deviation=0.14)
    return [b.to_object("Caper_Bush")]


# ============================================================ 5. ginestra
def build_ginestra():
    """Matura de tulpini verticale cu varfuri oliv."""
    out = []
    # Mai multe tulpini (18/12) si mai GROASE (0.075): la 13 tije de 0.055
    # tufa iesea un manunchi de sulite razlete, nu o matura. O ginestra e
    # DEASA — de-asta se si numeste matura.
    for (name, height, ntige, seed) in (("Ginestra_A", 2.0, 18, 131),
                                        ("Ginestra_B", 1.5, 12, 149)):
        rnd = _lcg(seed)
        b = Builder()
        for k in range(ntige):
            a = 2.0 * math.pi * k / ntige + rnd() * 0.4
            rr = (0.10 + 0.30 * rnd()) * height * 0.34
            h = height * (0.70 + 0.30 * rnd())
            lean = 0.16 * height * rnd()
            p0 = (rr * math.cos(a), rr * math.sin(a), 0.0)
            p1 = (p0[0] + lean * math.cos(a), p0[1] + lean * math.sin(a), h)
            b.beam(p0, p1, 0.075, GREEN)
            # varful oliv: o bucata scurta pe slot separat (NU galben saturat)
            p2 = (p1[0] + lean * 0.28 * math.cos(a),
                  p1[1] + lean * 0.28 * math.sin(a), h + height * 0.13)
            b.beam(p1, p2, 0.068, OLIVE_LEAF)
        out.append(b.to_object(name))
    return out


# ============================================================ 6. trestia
def build_cane():
    """Palc de trestie: 9 tije aplecate in ACEEASI directie (vantul)."""
    rnd = _lcg(173)
    b = Builder()
    WIND = math.radians(24.0)      # directia vantului, comuna tuturor tijelor
    for k in range(9):
        a = rnd() * 2.0 * math.pi
        rr = 0.42 * rnd()
        h = 3.0 * (0.72 + 0.28 * rnd())
        p0 = (rr * math.cos(a), rr * math.sin(a), 0.0)
        # aplecarea e pe aceeasi directie pentru toate: asta citeste "vant",
        # nu "tufa dezordonata"
        lean = math.sin(WIND) * h * 0.42
        p1 = (p0[0] + lean, p0[1] + lean * 0.22, h)
        b.beam(p0, p1, 0.055, GREEN)
        # Frunzele sunt PANGLICI CARE CAD pe langa tija, nu scanduri
        # orizontale. A doua versiune le punea ca box-uri rotite doar pe Z:
        # ieseau planse de schela infipte in bete. O frunza de trestie pleaca
        # de pe tija si se apleaca in jos — deci se roteste si pe Y, cu 55-70
        # de grade, si e SUBTIRE (0.04) si INGUSTA (0.10).
        for f in (0.42, 0.62, 0.82):
            fz = h * f
            fx = p0[0] + lean * f
            fy = p0[1] + lean * 0.22 * f
            ang = rnd() * 2.0 * math.pi
            droop = math.radians(58.0 + rnd() * 16.0)
            rot = (Matrix.Rotation(ang, 3, "Z")
                   @ Matrix.Rotation(droop, 3, "Y"))
            # centrul frunzei, la jumatatea ei, in directia (ang) si in jos
            ln = 0.58
            cx = fx + math.cos(ang) * ln * 0.5 * math.sin(droop)
            cy = fy + math.sin(ang) * ln * 0.5 * math.sin(droop)
            cz = fz - ln * 0.5 * math.cos(droop) * 0.55
            b.box((cx, cy, cz), (ln, 0.10, 0.04), GREEN, rotation=rot)
    return [b.to_object("Cane_Clump")]


if __name__ == "__main__":
    jobs = [
        (build_fig, "stromboli/trees/fig_tree.glb", 500),
        (build_prickly, "stromboli/plants/prickly_pear.glb", 600),
        (build_caper, "stromboli/plants/caper_bush.glb", 200),
        (build_ginestra, "stromboli/plants/ginestra_bush.glb", 400),
        (build_cane, "stromboli/plants/cane_clump.glb", 350),
    ]
    for (fn, rel, budget) in jobs:
        clear_built()
        objs = fn()
        print(rel)
        _finish_all(objs, budget, rel)
        export_glb(objs, rel)
