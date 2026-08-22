"""Stromboli, kit de flanc — maslinul (brief slope_kit, piesa 1).

  OliveTree  stromboli/trees/olive_tree.glb
             Olive_Trunk_A / Olive_Canopy_A / Olive_Trunk_B / Olive_Canopy_B

Doua variante, 5 si 7 m. Trunchi RASUCIT gros (identitatea maslinului: doua
torsiuni vizibile), coroana turtita argintiu-verde din 4-5 volume.

**Bugetele kitului de flanc sunt de BANDA STATISTICA, nu de hero.** Piesele
astea se planteaza in benzi de sute de instante, deci fiecare triunghi se
inmulteste cu sute (memoria `vegetatie-cost-pe-pas`). Spre deosebire de kitul
de sat, aici bugetele se RESPECTA.

Trunchiul rasucit se face din `taper_sweep` pe o cale in spirala — nu din
cilindri suprapusi, care ar da un burlan.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_olive_tree.py
"""

import math
from mathutils import Matrix, Vector

AO_TREE = dict(samples=16, dist=2.4, gradient="vertical",
               low=0.55, high=1.00, power=0.9, floor=0.32)

TRUNK = WOOD
LEAF = DRY_VEGETATION      # argintiu-verde (brief: u = 0.421875 -> slot 13)


def _lcg(seed):
    st = [seed & 0x7FFFFFFF]

    def nxt():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return nxt


def build_olive(name_t, name_c, height, seed):
    """Un maslin: trunchi rasucit + coroana din volume turtite."""
    rnd = _lcg(seed)
    trunk_h = height * 0.42

    # --- trunchiul: cale in spirala, cu doua torsiuni ----------------------
    b = Builder()
    path, radii = [], []
    steps = 6
    for i in range(steps + 1):
        t = i / float(steps)
        # doua torsiuni pe inaltime: sin de 2 perioade, cu amplitudine care
        # scade spre varf (baza se rasuceste mai tare)
        sway = 0.20 * math.sin(t * math.pi * 2.2) * (1.0 - t * 0.45)
        path.append((sway, 0.13 * math.sin(t * math.pi * 1.6), trunk_h * t))
        radii.append(height * 0.058 * (1.0 - 0.52 * t))
    b.taper_sweep(path, radii, TRUNK, segments=6)
    trunk = b.to_object(name_t)

    # --- coroana: 4-5 volume TURTITE ---------------------------------------
    b = Builder()
    cz = trunk_h + height * 0.16
    spread = height * 0.30
    for k in range(5):
        a = 2.0 * math.pi * k / 5.0 + rnd() * 0.5
        rr = spread * (0.30 + 0.55 * rnd())
        size = height * (0.20 + 0.12 * rnd())
        b.boulder((rr * math.cos(a), rr * math.sin(a),
                   cz + (rnd() - 0.5) * height * 0.10),
                  (size * 1.5, size * 1.5, size * 0.78), LEAF,
                  seed=seed + k * 17, segments=7, rings=3, deviation=0.13)
    canopy = b.to_object(name_c)
    return trunk, canopy


if __name__ == "__main__":
    clear_built()
    built = []
    for (nt, nc, h, seed) in (("Olive_Trunk_A", "Olive_Canopy_A", 5.0, 7),
                              ("Olive_Trunk_B", "Olive_Canopy_B", 7.0, 29)):
        t, c = build_olive(nt, nc, h, seed)
        built += [t, c]

    # BEVEL 0 PE COROANE. Frunzisul n-are muchii de aratat, iar bevelul
    # tripleaza costul: o coroana de 5 volume trece de la 210 la 684 de
    # triunghiuri pentru o tesitura pe care nimeni n-o vede intr-o masa de
    # frunze. Pe trunchi ramane, acolo silueta chiar conteaza.
    #
    # Bugetele kitului asta sunt de BANDA: piesele se planteaza cu sutele,
    # deci 474 de triunghiuri economisiti per copac inseamna zeci de mii pe
    # serpentina.
    total = 0
    for obj in built:
        bev = 0.03 if "Trunk" in obj.name else 0.0
        stats = finish(obj, bevel=bev, ao=AO_TREE, origin=None)
        print("%-18s %3d tris" % (obj.name, stats["tris"]))
        total += stats["tris"]
    print("TOTAL              %3d tris  (buget 900)" % total)
    path, size = export_glb(built, "stromboli/trees/olive_tree.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
