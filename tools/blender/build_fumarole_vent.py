"""Stromboli — fumarolele (brief docs/asset_briefs/stromboli_roadside.md, fisierul 1).

  FumaroleVent  stromboli/props/fumarole_vent.glb
                Fumarole_A / Fumarole_B / Fumarole_C

Conuri mici de pamant crustos cu gura deschisa si depuneri de sulf pe buza.
Aburul NU e aici — vine din particule in engine, impreuna cu `Area3D` de
albire (hazard-teatru).

Sulful e pe DRY_VEGETATION (13), oliv-galbui, nu pe un galben pur: accentele
saturate ale pistei raman lava si masinile. Decizia e a brief-ului si e
aceeasi logica prin care cenusa craterului a coborat pe un gri neutru.

Gura e panou intunecat RETRAS — dar aici retragerea chiar functioneaza, spre
deosebire de biserica: conul e un trunchi DESCHIS la varf (frustum fara capac
vizibil deasupra), deci panoul se vede prin gol, nu prin masa. Vezi
build_stromboli_church.py pentru cazul in care nu merge.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fumarole_vent.py
"""

import math
from mathutils import Matrix, Vector

# Gurile trebuie sa mearga spre 0.3 (brief), deci AO cu ocluzie reala pe
# distanta mica: interiorul palniei se auto-ocludeaza.
AO_FUM = dict(samples=26, dist=1.2, gradient="vertical",
              low=0.62, high=1.00, power=0.9, floor=0.28)

CRUST = MARBLE_GREY        # pamant gri-albicios ars
MOUTH = ASPHALT            # gol
SULFUR = DRY_VEGETATION    # oliv-galbui

# (nume, diametru_baza, inaltime, diametru_gura, seed)
VENTS = [
    ("Fumarole_A", 0.8, 0.40, 0.20, 7),
    ("Fumarole_B", 1.2, 0.60, 0.30, 19),
    ("Fumarole_C", 1.5, 0.80, 0.40, 31),
]


def build_vent(name, d_base, h, d_mouth, seed):
    b = Builder()
    rb, rm = d_base * 0.5, d_mouth * 0.5
    SEG = 9                       # fatete neregulate, nu con neted

    # UN SINGUR frustum, cu 7 laturi, si sulful prin `retag` — nu prin torus.
    #
    # Bugetul e 220 pe fumarola. Masurat, varianta "corecta" (doua etaje de con
    # + cilindru de gura + torus de sulf + 3 limbi) da 204 triunghiuri BRUTE,
    # adica ~590 dupa bevel: de doua ori si jumatate peste. Torusul singur
    # (9x4 = 72 brut) costa cat tot bugetul.
    #
    # Ce ramane, si de ce e destul: un trunchi de con e deja silueta ceruta
    # ("con mic de pamant crustos"), gura e capacul lui de sus re-etichetat pe
    # slotul intunecat, iar sulful e inelul de fete laterale de sub buza, tot
    # re-etichetat. Amandoua costa ZERO. La 0.4-0.8 m inaltime, langa drum,
    # asta e tot ce se poate citi oricum.
    SEG = 7
    cone = b.frustum((0.0, 0.0, h * 0.5), rb, rm * 1.45, h, CRUST,
                     segments=SEG)

    # gura: capacul de sus, pe slotul intunecat
    b.retag(cone, MOUTH, where="up")
    # sulful: inelul de fete laterale de sub buza (cele mai de sus fete "side")
    b.retag(cone, SULFUR,
            where=lambda c, n: abs(n.z) <= 0.5 and c.z > h * 0.72)

    # doua limbi de sulf care se scurg pe con — singura geometrie in plus,
    # fiindca scurgerea PE PANTA nu se poate obtine din re-etichetare (fetele
    # laterale sunt inele orizontale, nu fasii verticale).
    st = [(seed * 1103515245 + 12345) & 0x7FFFFFFF]

    def rnd():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)

    def cone_r(z):
        return rb + (rm * 1.45 - rb) * (z / h)

    for k in range(2):
        a = 2.0 * math.pi * (k + 0.25 + rnd() * 0.4) / 2.0
        z0, z1 = h * 0.74, h * (0.20 + 0.18 * rnd())
        p0 = (cone_r(z0) * math.cos(a), cone_r(z0) * math.sin(a), z0)
        p1 = (cone_r(z1) * math.cos(a), cone_r(z1) * math.sin(a), z1)
        b.beam(p0, p1, (d_base * 0.11, 0.03), SULFUR, up=(0, 0, 1))

    return b.to_object(name)


if __name__ == "__main__":
    clear_built()
    built = []
    for (name, d_base, h, d_mouth, seed) in VENTS:
        obj = build_vent(name, d_base, h, d_mouth, seed)
        stats = finish(obj, bevel=0.03, ao=AO_FUM, origin="base")
        print("%-12s %3d tris  Ø%.1f h%.1f  AO %.2f..%.2f"
              % (name, stats["tris"], d_base, h, stats["ao_min"], stats["ao_max"]))
        built.append(obj)

    total = sum(tri_count(o) for o in built)
    print("TOTAL        %3d tris  (buget 660)" % total)
    path, size = export_glb(built, "stromboli/props/fumarole_vent.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
