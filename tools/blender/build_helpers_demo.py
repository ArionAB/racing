"""Planșă de probă pentru ajutoarele din dio_lib (#A1).

Instantiaza fiecare ajutor o data, il trece prin `finish()` si raporteaza
triunghiurile INAINTE si DUPA bevel — a doua cifra e cea care conteaza la buget,
iar raportul dintre ele e ce nu se vede din docstring-uri.

NU e un asset. Exportul merge intr-un fisier temporar cu prefix `_`, care nu se
comite in assets/models — scopul lui e o captura in PR.

Rulare (Blender MCP):
    P = r"<repo>/tools/blender"
    g = {"__name__": "__main__", "__file__": P + "/dio_lib.py"}
    exec(open(P + "/dio_lib.py").read(), g)
    exec(open(P + "/build_helpers_demo.py").read(), g)
"""

import math
import os

clear_built("Helper")

# Fiecare ajutor pe standul lui, la 4 m distanta, ca sa se poata citi separat in
# captura. Numaratoarea per ajutor se face construind fiecare intr-un Builder
# propriu; planta finala le aduna pe toate intr-un singur obiect.
STANDS = []


def stand(name, fn):
    """Construieste ajutorul singur, ii numara triunghiurile, il retine."""
    solo = Builder()
    fn(solo, 0.0)
    tris = sum(len(f.verts) - 2 for f in solo.bm.faces)
    solo.bm.free()
    STANDS.append((name, fn, tris))


# --------------------------------------------------------------- repetitie
stand("pickets", lambda b, x: b.pickets(
    p1=(x - 1.4, 0.0, 0.0), p2=(x + 1.4, 0.0, 0.0), count_or_step=6,
    size=(0.16, 0.10, 1.10), slot=WOOD, tilt_jitter=5.0, seed=3))

stand("railing", lambda b, x: b.railing(
    p1=(x - 1.6, 0.0, 0.0), p2=(x + 1.6, 0.0, 0.0), height=1.10,
    post_step=0.80, post_t=0.10, rail_t=0.08, slot=RUST, rails=2))

stand("ladder", lambda b, x: b.ladder(
    base=(x, 0.0, 0.0), top=(x, 0.0, 3.20), width=0.60,
    rung_step=0.40, rail_t=0.06, rung_r=0.04, slot=RUST))

# --------------------------------------------------------------- primitive
stand("frustum", lambda b, x: b.frustum(
    center=(x, 0.0, 1.40), r_bottom=0.45, r_top=0.18, depth=2.80,
    slot=CONCRETE, segments=8))

# axis="Y" il aseaza in picioare, ca un cerc de rezervor vazut din fata; asa se
# citeste ca inel, nu ca o pata plutind (un torus culcat, vazut de sus, e un disc)
stand("torus", lambda b, x: b.torus(
    center=(x, 0.0, 0.97), major_r=0.85, minor_r=0.12, slot=RUST,
    major_seg=8, minor_seg=6, axis="Y"))

stand("corrugate", lambda b, x: b.corrugate(
    center=(x, 0.0, 1.20), size=(2.60, 0.10, 2.40), slot=RUST,
    ribs=5, depth=0.07))

# --------------------------------------------------------------- compozit
def _window_wall(b, x):
    """Fereastra are sens doar intr-un perete — altfel nu se vede ce rezolva."""
    faces = b.box(center=(x, 0.0, 1.30), size=(2.40, 0.30, 2.60), slot=WOOD)
    faces |= b.window(center=(x, 0.16, 1.45), w=1.50, h=1.20, frame_t=0.12,
                      depth=0.16, glass_slot=ASPHALT, frame_slot=CONCRETE,
                      mullions=(1, 1))
    return faces


stand("window (+perete)", _window_wall)

# --------------------------------------------------------------- retag
def _retag_demo(b, x):
    """retag() n-are geometrie proprie: aceleasi trei cutii, alta repartitie de
    sloturi. Tot ce se vede aici peste "trei cutii maro" costa ZERO triunghiuri.

    Fetele de sus decolorate (style_bible §4: "fetele de sus decolorate +10%
    valoare"), spatele in umbra, si un singur registru pe fata in alta culoare —
    exact tiparul cu care ecranul de drive-in isi rupe peretele de 190 m²."""
    faces = set()
    for k in range(3):
        f = b.box(center=(x, 0.0, 0.35 + k * 0.70), size=(1.70, 1.10, 0.66),
                  slot=SAND_MID)
        b.retag(f, SAND_LIGHT, where="up")
        b.retag(f, SAND_SHADOW, where=lambda c, n: n.y < -0.5)
        if k == 1:
            b.retag(f, KERB_RED, where=lambda c, n: n.y > 0.5)
        faces |= f
    return faces


stand("retag (0 tris in plus)", _retag_demo)


# --------------------------------------------------------------- planta finala
b = Builder()
PITCH = 3.60
x0 = PITCH * (len(STANDS) - 1) * 0.5
# ordinea e inversata pe X: camera priveste dinspre +Y (fata ferestrei), deci
# +X cade in stanga ecranului. Asa standurile se citesc in ordinea din lista.
for i, (name, fn, _tris) in enumerate(STANDS):
    fn(b, x0 - i * PITCH)
# o dala sub tot, ca AO-ul sa aiba de ce sa se agate
b.box(center=(0.0, 0.0, -0.09), size=(PITCH * len(STANDS), 3.0, 0.18), slot=CONCRETE)

obj = b.to_object("HelpersDemo")
stats = finish(obj, bevel=0.05, bevel_angle=30.0,
               ao=dict(samples=32, dist=2.5, gradient="vertical",
                       low=0.62, high=1.00, power=1.0, floor=0.35))

# Numaratoarea per ajutor, dupa bevel: reconstruiesc fiecare stand singur si il
# trec prin acelasi `finish`, fiindca bevel-ul nu e liniar in numarul de piese —
# el adauga geometrie PER MUCHIE, deci raportul difera mult intre ajutoare.
print("")
print("%-24s %8s %8s %6s" % ("ajutor", "brut", "cu bevel", "x"))
print("-" * 50)
for name, fn, raw in STANDS:
    clear_built("HelperSolo")
    solo = Builder()
    fn(solo, 0.0)
    o = solo.to_object("HelperSolo")
    s = finish(o, bevel=0.05, bevel_angle=30.0,
               ao=dict(samples=8, dist=2.0, gradient="none"))
    print("%-24s %8d %8d %5.1f" % (name, raw, s["tris"], s["tris"] / max(raw, 1)))
    bpy.data.objects.remove(o, do_unlink=True)
print("-" * 50)
print("%-24s %8s %8d" % ("planta completa", "", stats["tris"]))
print("AO %.2f..%.2f" % (stats["ao_min"], stats["ao_max"]))

# Fisier temporar, NU asset: prefixul `_` il tine in afara lotului.
path, size = export_glb([obj], "_helpers_demo.glb")
print("GLB temporar: %s (%d B) — nu se comite" % (path, size))
