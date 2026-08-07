"""dino_bones.glb — schelet fosilizat partial dezgropat + trei oase izolate.
Brief: docs/asset_briefs/dino_bones.md · issue #B4

Inlocuieste `toy_dino.glb`, un dinozaur de PLASTIC din tema abandonata "lada de
nisip". Codul care il plaseaza (`track.gd:1325-1350`, `_dino_spots()`) e viu,
doar ca nicio pista nu-l cere momentan.

Patru obiecte, copii directi ai radacinii, toate exportate la origine:
  Dino_Skeleton  <= 600 tris
  Bone_A         femur          <= 40
  Bone_B         trei coaste    <= 40
  Bone_C         vertebra       <= 40

Botul priveste spre +Y in Blender (= -Z in Godot).


NOTA DE BUGET — de ce bevel 0
-----------------------------
Brieful cere bevel 0.04. Multiplicatorul bevel-ului, masurat de doua ori
(plansa de ajutoare din #46 si cele cinci variante de pilon din #B3), e **3.67x
constant** — nu depinde de latimea bevel-ului, fiindca segments=1 adauga mereu
aceeasi topologie: un cub de 12 triunghiuri iese cu 6 fete (12) + 12 quad-uri de
muchie (24) + 8 triunghiuri de colt = 44.

Cu bevel, bugetul brut util ar fi 600 / 3.67 = **163 de triunghiuri**, adica 13
cutii. Brieful cere 14 vertebre + 8 coaste + craniu + patru membre — peste 30 de
piese. Doar coloana singura ar depasi tot bugetul.

Fara bevel incape TOT brieful, cu coaste in doua segmente (arcuite, nu drepte),
si mai raman ~100 de triunghiuri nefolositi. Schimbul e evident aici, si nu e
acelasi cu cel de la poarta de start: acolo bevel-ul rotunjea grinzi de metal
vazute de la 30 m, aici testul din issue e o captura de la **80-100 m**, unde o
tesitura de 4 cm e sub-pixel. Un os fosilizat citeste bine fatetat; o schela nu.
"""

import math
from mathutils import Vector

BONE = SAND_LIGHT       # osul e mai DESCHIS decat nisipul — asta il face lizibil
DARK = SAND_SHADOW      # orbite, interiorul cutiei toracice

# --- Coloana ------------------------------------------------------------------
# (y, z) de la varful cozii spre bot. Coada COBOARA pana la z ~ 0: partea
# ingropata nu se modeleaza deloc. Daca ar cobori sub zero, `finish(origin=
# "base")` ar ridica tot scheletul si exact bucata care trebuie ascunsa in nisip
# ar iesi deasupra lui.
SPINE = [
    (-4.60, 0.06), (-3.90, 0.46), (-3.10, 1.06), (-2.30, 1.76),
    (-1.50, 2.46), (-0.70, 3.04), (0.00, 3.40), (0.75, 3.55),
    (1.50, 3.55), (2.20, 3.40), (2.75, 3.56), (3.15, 3.96),
    (3.45, 4.34), (3.72, 4.52),
]
# Latimea vertebrei: varful cozii -> trunchi. Brieful cere 0.10 -> 0.28; la
# testul de 80 m ceruta de issue silueta iesea la limita, iar issue-ul spune
# explicit ce sa fac atunci: "ingroasa oasele si scoate detalii — nu invers".
# Ingrosarea e gratuita in triunghiuri, deci nu concureaza cu nimic.
VERT_W = (0.14, 0.34)
VERT_TALL = 1.45        # vertebra e mai INALTA decat lata: brieful cere procese
                        # spinoase, iar raportul le sugereaza fara nicio piesa
                        # in plus

# Coastele NU se mai leaga de indici de vertebra, ci de pozitii pe lungimea
# toracelui (sold y=0 -> umar y=2.2). Cinci perechi in loc de patru: bugetul
# permitea, iar cu patru cusca ramanea rara si se citea ca patru bete, nu ca
# torace. Cele 48 de triunghiuri in plus sunt cea mai ieftina imbunatatire de
# silueta din tot fisierul.
RIB_Y = (0.15, 0.70, 1.25, 1.75, 2.20)
RIB_T = 0.18            # brieful cere minimum 0.12 — sub atat dispar la viteza

BEVEL = 0.0


def spine_z(y):
    """Inaltimea coloanei la o pozitie oarecare pe lungime, interpolata liniar.
    Coastele se agata de coloana, nu de vertebre — altfel numarul si pozitia lor
    ar depinde de cate vertebre am ales sa pun."""
    for (y0, z0), (y1, z1) in zip(SPINE, SPINE[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / max(y1 - y0, 1e-6)
            return z0 + (z1 - z0) * t
    return SPINE[-1][1] if y > SPINE[-1][0] else SPINE[0][1]


def spine_dir(i):
    a = Vector((0.0, SPINE[max(i - 1, 0)][0], SPINE[max(i - 1, 0)][1]))
    b = Vector((0.0, SPINE[min(i + 1, len(SPINE) - 1)][0], SPINE[min(i + 1, len(SPINE) - 1)][1]))
    d = b - a
    return d.normalized() if d.length > 1e-6 else Vector((0.0, 1.0, 0.0))


def build_skeleton():
    b = Builder()

    # --- vertebre: cate o cutie orientata pe tangenta locala -------------------
    # `beam` face exact asta — construieste o cutie intre doua puncte, deci
    # orientarea vine din geometrie, nu dintr-o matrice scrisa de mana.
    for i, (y, z) in enumerate(SPINE):
        t = i / (len(SPINE) - 1)
        w = VERT_W[0] + (VERT_W[1] - VERT_W[0]) * min(t * 1.6, 1.0)
        d = spine_dir(i)
        # 0.38 din pasul de ~0.8 m: vertebrele raman distincte, dar golul scade
        # sub jumatate. La 0.30 coada iesea o linie punctata — se citea ca urma,
        # nu ca sir de oase.
        half = 0.38 * d
        p = Vector((0.0, y, z))
        b.beam(p - half, p + half, (w, w * VERT_TALL), BONE)

    # --- cutia toracica: 8 coaste, cate 4 pe parte ----------------------------
    # Fiecare coasta are DOUA segmente. O coasta dreapta ar fi costat jumatate,
    # dar cutia toracica ar fi iesit un con — arcuirea e tot ce o face sa se
    # citeasca drept cusca de coaste si nu drept tepi.
    #
    # Coastele cad SI spre spate, nu doar in lateral. Prima versiune arcuia doar
    # in planul X-Z, iar din profil — unghiul din care se citeste orice terapod —
    # arcul ala se proiecteaza intr-o linie: ieseau patru stalpi verticali sub
    # coloana, ca picioarele unei mese. Inclinarea spre -Y le desface in evantai
    # exact pe silueta pe care o vezi din masina.
    for k, y in enumerate(RIB_Y):
        z = spine_z(y)
        spread = 1.0 - 0.11 * k          # coastele din fata, mai stranse
        for side in (-1.0, 1.0):
            top = Vector((side * 0.16, y, z - 0.10))
            mid = Vector((side * 1.02 * spread, y - 0.42, z - 1.00))
            low = Vector((side * 0.50 * spread, y - 1.00, z - 2.15))
            b.beam(top, mid, RIB_T, BONE)
            b.beam(mid, low, RIB_T * 0.9, BONE)

    # --- membrele posterioare -------------------------------------------------
    for side in (-1.0, 1.0):
        hip = Vector((side * 0.42, -0.10, 3.10))
        knee = Vector((side * 0.86, -0.62, 1.70))
        ankle = Vector((side * 0.90, -0.12, 0.52))
        toe = Vector((side * 0.94, 0.55, 0.12))
        b.beam(hip, knee, 0.30, BONE)     # femur
        b.beam(knee, ankle, 0.22, BONE)   # tibie
        b.beam(ankle, toe, 0.18, BONE)    # laba, fara degete separate

    # --- membrele anterioare, scurte ------------------------------------------
    for side in (-1.0, 1.0):
        b.beam(Vector((side * 0.34, 2.15, 3.05)),
               Vector((side * 0.58, 2.62, 2.30)), 0.15, BONE)

    # --- craniul --------------------------------------------------------------
    # Doua cutii suprapuse in loc de una: banda de jos primeste slotul inchis pe
    # fetele laterale si devine orbita. Brieful cere exact asta — "orbitele nu se
    # scobesc, se marcheaza cu un slot inchis pe doua fete" — si costa 12
    # triunghiuri, fata de 24 pentru doua cutii de orbita lipite deasupra.
    b.box((0.0, 4.20, 4.72), (0.70, 1.00, 0.40), BONE)             # bolta craniana
    orbit = b.box((0.0, 4.16, 4.34), (0.66, 0.78, 0.34), BONE)     # banda orbitelor
    b.retag(orbit, DARK, where=lambda c, n: abs(n.x) > 0.5)
    b.box((0.0, 4.98, 4.42), (0.48, 0.86, 0.42), BONE)             # bot
    b.box((0.0, 4.76, 4.02), (0.44, 1.20, 0.20), BONE)             # falca

    return b


def bone_a():
    """Femur, ~1.4 m: fus + doua capete ingrosate."""
    b = Builder()
    b.beam((0.0, 0.0, 0.10), (0.0, 0.12, 1.30), 0.15, BONE)
    b.box((0.0, 0.01, 0.13), (0.28, 0.26, 0.24), BONE)
    b.box((0.0, 0.13, 1.29), (0.25, 0.24, 0.22), BONE)
    return b


def bone_b():
    """Grup de trei coaste curbate, intrepatrunse — nu doar alaturate: trei arce
    care se ating citesc ca obiecte separate puse gramada, nu ca un grup."""
    b = Builder()
    for k, (dx, dy, sc) in enumerate(((0.0, 0.0, 1.0), (0.16, -0.12, 0.86),
                                      (-0.13, 0.14, 0.78))):
        b.beam((dx, dy, 0.06), (dx + 0.38 * sc, dy + 0.10, 0.62 * sc), 0.12, BONE)
    return b


def bone_c():
    """Vertebra izolata, ~0.5 m."""
    b = Builder()
    b.box((0.0, 0.0, 0.16), (0.30, 0.34, 0.32), BONE)
    b.box((0.0, 0.02, 0.40), (0.13, 0.22, 0.24), BONE)   # procesul spinos
    return b


clear_built("Dino_")
clear_built("Bone_")

PIECES = [("Dino_Skeleton", build_skeleton, 600),
          ("Bone_A", bone_a, 40), ("Bone_B", bone_b, 40), ("Bone_C", bone_c, 40)]

objs = []
for name, fn, budget in PIECES:
    obj = fn().to_object(name)
    stats = finish(
        obj,
        bevel=BEVEL,
        ao=dict(samples=28, dist=2.5, gradient="vertical",
                low=0.52, high=1.00, power=0.9, floor=0.30),
    )
    me = obj.data
    ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
           for a in range(3)]
    print("%-14s %3d tris (buget %3d) %s | %.2f x %.2f x %.2f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK    " if stats["tris"] <= budget else "DEPASIT",
             ext[0][1] - ext[0][0], ext[1][1] - ext[1][0], ext[2][1] - ext[2][0],
             stats["ao_min"], stats["ao_max"]))
    objs.append(obj)

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "props/dino_bones.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "dino_bones.blend"))
for i, o in enumerate(objs):
    o.location = (i * 6.0, 0.0, 0.0)
