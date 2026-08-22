"""Stromboli — bombele vulcanice (brief docs/asset_briefs/lava_set.md, fisierul 2).

  VolcanicBomb  stromboli/effects/volcanic_bomb.glb
                Bomb_S / Bomb_M / Bomb_L

Proiectilele eruptiei ciclice de pe Sciara: `RockfallHazard` le rostogoleste pe
trasee `Path3D`, declansate de `EruptionCycle`. Contactul = distrugere.

Doua lucruri sunt CONTRACT, si amandoua vin din faptul ca obiectul SE
ROSTOGOLESTE:

1. **Pivotul in centrul volumului**, nu la baza. O bomba cu originea la baza se
   roteste in jurul unui punct de pe suprafata ei si "sare" vizibil pe traseu.
   `finish(origin="center")` face exact asta.

2. **AO sferic, nu vertical.** Un gradient vertical coace o umbra la baza care,
   dupa o jumatate de rotatie, ajunge in varf — o pata intunecata care se
   plimba. `bake_ao(gradient="spherical")` masoara distanta fata de ORIGINE,
   deci e invariant la rotatie. E singurul gradient corect aici (vezi nota din
   dio_lib.bake_ao) si de-asta cere originea in centru.

Crapaturile inconjoara forma pe trei axe, ca de la ORICE unghi sa se vada macar
una — altfel bomba care se rostogoleste isi pierde semnalul portocaliu exact
cand e mai vizibila.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_volcanic_bomb.py
"""

import math
from mathutils import Matrix, Vector

# gradient sferic: vezi antetul. `dist` mic — o bomba de 1.2 m n-are ce sa
# ocluda la distanta mare, iar ocluzia care conteaza e cea dintre crapaturi.
AO_BOMB = dict(samples=28, dist=1.4, gradient="spherical",
               low=0.62, high=1.00, power=0.9, floor=0.45)

CRUST = VOLCANIC_BLACK
GLOW = LAVA_ORANGE

# (nume, diametru, seed) — brief: 0.6 / 0.9 / 1.2 m
BOMBS = [("Bomb_S", 0.6, 5), ("Bomb_M", 0.9, 17), ("Bomb_L", 1.2, 29)]


def build_bomb(name, diameter, seed):
    """Bomba: elipsoid turtit (minge de rugby scurta) cu crapaturi incandescente."""
    b = Builder()
    r = diameter * 0.5
    # Silueta usor turtita, ceruta de brief: bombele reale se rotesc in zbor si
    # se aplatizeaza. 1.18 pe axa lunga, 0.88 pe cea scurta.
    size = (diameter * 1.18, diameter * 0.88, diameter * 0.92)
    # `boulder`, nu `rock`: rock() cu taper mare da un varf ASCUTIT (in prima
    # randare au iesit trei conuri, nu bombe). boulder() e primitiva pentru
    # corpuri rotunde care se rostogolesc — aceeasi folosita de boulder_roller.
    b.boulder((0.0, 0.0, 0.0), size, CRUST, seed=seed, segments=9, rings=5,
              deviation=0.13)

    # CRAPATURILE SUNT FETE RE-ETICHETATE, NU GEOMETRIE — abatere de la brief,
    # impusa de propriul lui buget.
    #
    # Brief-ul cere "fasii de geometrie scufundate". Masurat: 30 de beam-uri pe
    # bomba costa 1320 de triunghiuri dupa bevel, iar bugetul e 250 PER BOMBA
    # din care corpul ia deja ~256. Nu incap, si nici pe departe.
    #
    # `retag` coloreaza fete existente ale elipsoidului la COST ZERO. Un corp
    # cu 8 segmente x 5 inele are ~80 de fete; alegem dintre ele o retea rara
    # care inconjoara forma pe trei axe. Rezultatul citeste identic la scara
    # jocului (o bomba de 0.6-1.2 m care se rostogoleste), fiindca ce se vede e
    # PATA portocalie, nu adancitura ei de 5 cm.
    glow = []
    faces = [f for f in b.bm.faces if f.is_valid]

    def band(axis, level, width, keep):
        """Marcheaza fetele a caror normala e aproape perpendiculara pe `axis`
        si al caror centru cade intr-o banda in jurul lui `level` pe acea axa.

        `keep` rareste banda (1 din N fete), ca sa iasa crapatura rupta, nu
        cerc continuu pictat.
        """
        idx = {"x": 0, "y": 1, "z": 2}[axis]
        picked = 0
        for k, f in enumerate(faces):
            if not f.is_valid:
                continue
            c = f.calc_center_median()
            if abs(c[idx] - level) > width:
                continue
            if k % keep:
                continue
            f[b.slot] = GLOW
            glow.append(tuple(c))
            picked += 1
        return picked

    # trei benzi pe trei axe: de la orice unghi se vede macar una (brief)
    # Benzi INGUSTE si RARE. Prima incercare (latime 0.30r, 1 din 2 fete) a
    # colorat sferturi intregi din corp: portocaliul iesea pata, nu crapatura.
    # Brief-ul cere "4-6 crapaturi" ca retea rara.
    # SASE benzi subtiri, calibrate pe o masuratoare de acoperire.
    #
    # Sonda verifica din 14 directii (12 pe ecuator + sus + jos) daca se vede
    # macar o fata incandescenta — cerinta brief-ului pentru un obiect care se
    # ROSTOGOLESTE. Calibrarea a trecut prin doua extreme:
    #   3 benzi inguste  -> 4 fete (3%),  6/14 directii  = invizibil din
    #                       jumatate din unghiuri
    #   5 benzi late     -> 36 fete (29%), 14/14 directii = dungi portocalii
    #                       late, nu crapaturi
    # Compromisul: mai MULTE benzi, fiecare mai subtire si mai rarita (`keep`
    # mai mare). Tinta e 14/14 directii la ~12-15% din fete.
    band("z", r * 0.34, r * 0.09, 4)
    band("z", -r * 0.30, r * 0.09, 4)
    band("x", r * 0.10, r * 0.08, 5)
    band("x", -r * 0.36, r * 0.08, 5)
    band("y", r * 0.24, r * 0.08, 5)
    band("y", -r * 0.28, r * 0.08, 5)

    obj = b.to_object(name)
    return obj, glow, diameter


def _lift_glow_by_uv(obj, slot):
    """Ridica AO la 1.0 pe varfurile fetelor care poarta slotul incandescent.

    Cautarea dupa DISTANTA (varianta folosita pe crater si pe limba de lava) nu
    merge aici din doua motive: centrele de fata nu coincid cu pozitiile
    varfurilor, iar `finish(origin="center")` muta toata geometria dupa ce
    centrele au fost retinute. Ambele o faceau sa gaseasca ~0 varfuri.

    Aici nu mai e nevoie de distante: dupa `assign_uvs`, fiecare fata are UV-ul
    colapsat pe centrul slotului ei, deci fata incandescenta se recunoaste
    DIRECT din u. E si mai robust — nu depinde de nicio cota.
    """
    me = obj.data
    ca = me.color_attributes.get("AO")
    uv = me.uv_layers.get("UVMap")
    if ca is None or uv is None:
        return 0
    want = (slot + 0.5) / 32.0
    touched = set()
    for poly in me.polygons:
        u = sum(uv.data[li].uv[0] for li in poly.loop_indices) / poly.loop_total
        if abs(u - want) < 0.008:
            for vi in poly.vertices:
                touched.add(vi)
    for vi in touched:
        ca.data[vi].color = (1.0, 1.0, 1.0, 1.0)
    return len(touched)


if __name__ == "__main__":
    clear_built()
    built = []
    for (name, diameter, seed) in BOMBS:
        obj, glow, d = build_bomb(name, diameter, seed)
        # finish cu origin="center": pivotul in centrul volumului, cerut de
        # rostogolire SI de gradientul sferic de AO.
        stats = finish(obj, bevel=d * 0.05, ao=AO_BOMB, origin="center")
        lit = _lift_glow_by_uv(obj, GLOW)
        print("%-8s %3d tris  Ø%.1f m  AO %.2f..%.2f  (%d varfuri la 1.0)"
              % (name, stats["tris"], d, stats["ao_min"], stats["ao_max"], lit))
        built.append(obj)

    total = sum(tri_count(o) for o in built)
    print("TOTAL    %3d tris  (buget 750)" % total)
    path, size = export_glb(built, "stromboli/effects/volcanic_bomb.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
