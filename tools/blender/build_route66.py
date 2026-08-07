"""route66_sign.glb — scut US highway pe stalp. Brief: docs/asset_briefs/route66_sign.md

Fata scutului spre -Z in Godot (= +Y Blender).

#D4 (valul 3) il imbogateste PE LOC. Nodul ramane `Route66Sign`; colizor nu are
(`"col": "none"` in `_LANDMARKS`), deci forma e libera — dar semnul e plasat cu
`gap: 3.5` de marginea asfaltului, asa ca nici gabaritul nu creste dramatic.

Ce s-a schimbat: pana acum comentariul de aici spunea ca "cifrele 66 NU se
modeleaza — silueta de scut plus contrastul beton/asfalt fac citirea". La 30 m
asta iesea un scut GOL, iar la 100 m o pata. Acum se modeleaza.
"""

import math
from mathutils import Matrix

POST_H = 2.80
POST_W = 0.12
SHIELD_Z = 2.40      # centrul scutului pe verticala
SHIELD_W = 0.90
SHIELD_H = 1.00
INSET = 0.86         # placa-fata, inset ~0.06 m pe latura


def shield_outline(width, height):
    """Silueta clasica de US route shield: umeri rotunjiti sus, talie stransa,
    baza usor ascutita. Tinut la 10 puncte — bugetul nu suporta mai mult, iar
    la viteza conteaza doar silueta."""
    half = [
        (0.00,  0.45),
        (0.24,  0.50),
        (0.45,  0.38),
        (0.40,  0.02),
        (0.24, -0.30),
        (0.00, -0.50),
    ]
    pts = list(half)
    for x, z in reversed(half[1:-1]):   # oglindire, fara sa dublam polii
        pts.append((-x, z))
    return [(x * width, z * height) for x, z in pts]


clear_built("Route66")
b = Builder()

# Stalp — chunky (brief: nu subtire). Metal RUGINIT, nu vopsit: brief-ul ofera
# ambele, iar albastrul rece al slotului painted_metal se citea ca un corp strain
# intre nisip si lemn (verificat in viewport).
b.box(center=(0.0, 0.0, POST_H * 0.5), size=(POST_W, POST_W, POST_H), slot=RUST)

outline = shield_outline(SHIELD_W, SHIELD_H)
inner = shield_outline(SHIELD_W * INSET, SHIELD_H * INSET)

# Placa-fundal = rama intunecata (asfalt: cea mai inchisa suprafata din lume)
b.prism(outline, 0.08, ASPHALT, center=(0.0, 0.09, SHIELD_Z))
# Placa-fata = campul deschis, in relief usor peste fundal
b.prism(inner, 0.05, CONCRETE, center=(0.0, 0.155, SHIELD_Z))

# ------------------------------------------------------------------- "66"
# Cifra se face din bare groase, in tiparul afisajului cu 7 segmente, NU dupa
# forma tipografica. `style_bible` §3 e explicit: la viteza conteaza silueta, iar
# un "6" corect tipografic are curburi care dispar la 30 m si lasa o pata. Cinci
# bare per cifra dau conturul inconfundabil: bara de sus, muchia stanga pe toata
# inaltimea, traversa din mijloc, bara de jos si muchia dreapta pe jumatatea
# de jos — adica exact bucla inchisa care distinge un 6 de un 5.
DIGIT_H = 0.56
DIGIT_W = 0.27
# Grosimea barei. La 0.075 pe o cifra de 0.30 insemna un sfert din latime, iar
# golurile ramase erau doua dreptunghiuri egale: cifra se citea a domino, nu a 6.
BAR = 0.052
DIGIT_Y = 0.184          # 4 mm in fata placii-fata: se ridica, nu se ingroapa
DIGIT_T = 0.045


def digit_six(cx, cz):
    w, h, t = DIGIT_W, DIGIT_H, BAR
    for center, size in (
            ((cx, cz + h * 0.5 - t * 0.5), (w, t)),              # sus
            ((cx - w * 0.5 + t * 0.5, cz), (t, h)),              # muchia stanga
            ((cx, cz), (w, t)),                                  # traversa
            ((cx, cz - h * 0.5 + t * 0.5), (w, t)),              # jos
            ((cx + w * 0.5 - t * 0.5, cz - h * 0.25), (t, h * 0.5)),  # dreapta jos
    ):
        b.box(center=(center[0], DIGIT_Y, center[1]),
              size=(size[0], DIGIT_T, size[1]), slot=ASPHALT)


digit_six(-0.155, SHIELD_Z - 0.03)
digit_six(0.155, SHIELD_Z - 0.03)

# ------------------------------------------------------- urme de gloante
# Brieful le cere prin `retag`, la zero triunghiuri. Nu se poate: placa-fata e un
# `prism`, deci fata ei din fata e UN SINGUR ngon — n-are ce sa fie re-etichetat
# pe bucati.
#
# Sunt discuri, nu cutii, si nu din pedanterie: prima versiune folosea cutii, iar
# una dintre ele a cazut chiar deasupra cifrelor si se citea ca un "+". Un disc
# cu 5 laturi costa 15 triunghiuri si nu poate fi confundat cu un caracter.
# Pozitiile sunt impinse spre marginile scutului, departe de campul cifrelor.
for hx, hz, r in ((-0.31, 0.33, 0.038), (0.30, -0.26, 0.033),
                  (0.33, 0.30, 0.028), (-0.20, -0.36, 0.030)):
    b.cylinder(center=(hx, 0.178, SHIELD_Z + hz), radius=r, depth=0.04,
               slot=ASPHALT, segments=5, axis="Y")

# ------------------------------------------------------------- inclinare
# Semnul era perfect vertical. Cateva grade spun "abandonat" fara niciun
# triunghi in plus. Rotatia se face in jurul ORIGINII, unde sta si baza
# stalpului, deci piciorul ramane infipt in sol dupa `finish(origin="base_axis")`.
for axis, deg in (("X", 3.6), ("Y", -2.2)):
    rot = Matrix.Rotation(math.radians(deg), 3, axis)
    for v in b.bm.verts:
        v.co = rot @ v.co

# Movilita erodata la baza, ca stalpul sa nu iasa dintr-un plan curat.
b.rock((0.0, 0.0, 0.0), (0.72, 0.62, 0.30), SAND_MID,
       seed=311, segments=6, rings=1, taper=0.5, squash=0.7)

obj = b.to_object("Route66Sign")
stats = finish(
    obj,
    bevel=0.04, bevel_angle=55.0,   # 55° = prinde muchiile drepte, sare peste conturul scutului
    ao=dict(samples=24, dist=1.0, gradient="vertical",
            low=0.60, high=1.00, power=1.0, floor=0.16),
    # originea pe axa stalpului, nu pe centrul bbox-ului (scutul iese in fata pe Y)
    origin="base_axis",
)

me = obj.data
ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
       for a in range(3)]
BEFORE_H = 2.90
print("Route66Sign -> %d tris | AO %.2f..%.2f" % (stats["tris"], stats["ao_min"], stats["ao_max"]))
print("inaltime %.3f m (inainte de #D4: %.2f) | latime %.2f | adancime %.2f"
      % (ext[2][1] - ext[2][0], BEFORE_H, ext[0][1] - ext[0][0], ext[1][1] - ext[1][0]))
print("GLB:   %s (%d B)" % export_glb([obj], "signs/route66_sign.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "route66_sign.blend"))
