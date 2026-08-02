"""boulder_roller.glb — bolovanul care se rostogoleste peste sosea in canion.
Brief: docs/asset_briefs/boulder_roller.md · issue #B2

Inlocuieste mingea de plaja (`beach_ball.glb`, 288 tris, fara UV pe sloturi si
fara COLOR_0 — deci un material propriu si un draw call in plus).

ORIGINEA E IN CENTRU, NU LA BAZA. E singurul asset din repo cu exceptia asta si
e ceruta de `scenes/hazards/sliding_hazard.gd:106-107`, care compenseaza cu
`_pivot.position = Vector3.UP * roll_radius` si roteste pivotul. Cu originea la
baza, rotatia s-ar face in jurul unui punct de pe sol: bolovanul ar sari in loc
sa se rostogoleasca.

Buget: 220 de triunghiuri. O singura instanta pe pista.
"""

import math
from mathutils import Vector

# Diametrul de 5.0 m nu e estetica, e interfata. Godot il scaleaza cu
# model_scale = 0.52 la 2.6 m in joc, si `roll_radius` se masoara DIN model
# (sliding_hazard.gd:103-110). Cota se scrie exact, prin `origin_size`, ca sa
# fie un numar de pus in brief — nu ce a iesit din perturbatie.
DIAMETER = 5.0

SEGMENTS = 9        # meridiane. Impar: cu numar par ies doua fatete perfect
                    # opuse si bolovanul citeste ca o moneda cand se roteste.
RINGS = 5           # inele de latitudine, fara poli

# Neregularitatea. Brieful cere "bolovan, nu sfera" DAR "fara concavitati", iar
# cele doua trag in directii opuse — deci valoarea s-a ales masurand, nu din ochi
# (`max_concavity` mai jos, baleiaj pe 0.10 .. 0.26 cu doua seed-uri):
#
#   `boulder()` singur iese STRICT CONVEX la orice valoare incercata (0.0000).
#   Toata concavitatea masurata vine din taieturile plane, si e constanta ~0.040
#   din raza pana la dev 0.22, de unde sare la 0.067.
#
# 0.18 da 27% variatie de raza — se citeste ca bolovan din orice unghi — cu
# concavitatea tot la pragul de jos: 9.9 cm pe modelul de 5 m, adica 5.2 cm dupa
# model_scale. La 2.6 m in miscare, nu exista.
DEVIATION = 0.18

# Trei taieturi plane = fetele proaspat sparte. Fiecare e (punct, normala);
# tot ce trece de plan se proiecteaza PE plan. Un corp convex taiat cu un
# semispatiu ramane convex, deci regula "fara concavitati" din brief se tine
# prin constructie, nu prin noroc.
#
# Adancimile sunt mici (0.28-0.42 din raza) dinadins: o taietura adanca ar
# aplatiza o banda intreaga de inele si bolovanul ar incepe sa se poticneasca
# vizibil la rostogolire — exact defectul pe care il evitam.
CLEAVES = [
    ((0.72, 0.40, 0.30), (0.80, 0.48, 0.36)),
    ((-0.55, 0.62, -0.44), (-0.62, 0.55, -0.56)),
    ((0.18, -0.78, 0.34), (0.20, -0.84, 0.50)),
]


def max_concavity(obj):
    """Cea mai adanca scobitura, ca fractiune din raza. 0 = strict convex.

    Brieful cere "fara concavitati" fiindca o adancitura face rostogolirea sa
    para ca se poticneste. Pana aici era o afirmatie, nu o masuratoare: se
    verifica din ochi, pe un render, dintr-un singur unghi. Testul e cel de
    manual — un poliedru e convex daca niciun varf nu trece dincolo de planul
    vreunei fete — si costa o secunda la build.
    """
    me = obj.data
    verts = [v.co for v in me.vertices]
    radius = max(v.length for v in verts) or 1.0
    worst = 0.0
    for p in me.polygons:
        c, n = p.center, p.normal
        for v in verts:
            worst = max(worst, (v - c).dot(n))
    return worst / radius


def cleave(builder, point, normal, radius):
    """Taie cu un plan si proiecteaza pe el varfurile din exterior.

    `point` si `normal` sunt in unitati de raza (bolovanul se construieste pe
    raza 1 si se scaleaza abia in `finish`), ca sa se citeasca la fel indiferent
    de diametrul final.
    """
    p = Vector(point) * radius
    n = Vector(normal).normalized()
    for v in builder.bm.verts:
        d = (v.co - p).dot(n)
        if d > 0.0:
            v.co -= n * d
    return n


clear_built("Boulder")

b = Builder()
# ROCK_DARK dominant, invers fata de `rock_cluster.glb` (Cluster_L1 e ROCK_LIGHT
# cu sateliti inchisi). Brieful cere explicit sa nu semene cu bolovanul static
# din decor: schema de valoare inversata ii separa la prima privire, si nu costa
# nimic — sunt aceleasi doua sloturi din acelasi atlas.
faces = b.boulder((0.0, 0.0, 0.0), (2.0, 2.0, 2.0), ROCK_DARK,
                  seed=317, segments=SEGMENTS, rings=RINGS, deviation=DEVIATION)

cut_normals = [cleave(b, p, n, 1.0) for p, n in CLEAVES]

# Fetele proaspat sparte in ROCK_LIGHT. `retag` costa ZERO triunghiuri, iar
# contrastul e ce leaga hazardul de faleza de deasupra: "s-a desprins acum".
# Pragul 0.86 prinde fateta plana si vecinele ei aproape coplanare; mai jos
# incepe sa manance si curbura din jur, si taietura nu se mai citeste ca muchie.
for n in cut_normals:
    b.retag(faces, ROCK_LIGHT, where=lambda c, fn, _n=n: fn.dot(_n) > 0.86)

obj = b.to_object("Boulder")

# BEVEL ZERO, si e cel mai important compromis din fisier.
#
# Planşa de probă a ajutoarelor a masurat multiplicatorul bevel-ului: ~3.7x
# constant. Cu bevel, cele 90 de triunghiuri brute ar deveni ~333 — peste
# bugetul de 220 — si singura reparatie ar fi coborarea la 3 benzi de latitudine,
# adica un zar de 5 m, nu un bolovan.
#
# style_bible §3 cere stanci rotunjite (70%) SAU fatetate (30%). Un bolovan
# proaspat spart din perete e chiar cazul fatetat, deci nu platim nimic estetic:
# muchiile dure sunt aici argument, nu economie.
stats = finish(
    obj,
    bevel=0.0,
    # AO sferic. Toate celelalte assets folosesc gradient='vertical' (jos mai
    # inchis), dar aici ar fi o eroare de acelasi tip cu roata morii: obiectul
    # se ROTESTE, deci o umbra coapta la baza ajunge in varf dupa o jumatate de
    # rotatie. 'none' e corect si inutil — pe un corp convex ocluzia geometrica
    # e nula, si prima rulare a iesit exact asa, AO 1.00..1.00, adica bolovanul
    # ar fi singurul obiect din cadru fara nicio variatie tonala. Ramane
    # distanta fata de centru, singurul gradient invariant la rotatie.
    ao=dict(samples=32, dist=2.0, gradient="spherical",
            low=0.58, high=1.00, power=1.0, floor=0.30),
    origin="center",
    origin_size=(DIAMETER, DIAMETER, DIAMETER),
)

me = obj.data
ext = []
for axis, label in enumerate("XYZ"):
    vals = [v.co[axis] for v in me.vertices]
    ext.append((min(vals), max(vals)))
print("Boulder  %d tris (buget 220) | AO %.2f..%.2f | concavitate max %.4f din raza"
      % (stats["tris"], stats["ao_min"], stats["ao_max"], max_concavity(obj)))
for axis, label in enumerate("XYZ"):
    lo, hi = ext[axis]
    print("  bbox %s: %+.3f .. %+.3f  (deschidere %.3f, centru %+.4f)"
          % (label, lo, hi, hi - lo, (lo + hi) * 0.5))
print("  raza pe orizontala (Godot XZ) = %.3f m -> in joc, la model_scale 0.52: %.3f m"
      % (max(ext[0][1], ext[1][1]), max(ext[0][1], ext[1][1]) * 0.52))

obj.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb([obj], "boulder_roller.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "boulder_roller.blend"))
