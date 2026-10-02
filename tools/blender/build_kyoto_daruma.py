"""Kyoto (Track18) -- daruma-otoshi, hazardul-semnatura de la POI F (brief kyoto.md §3,
decizia dezvoltatorului din 3 oct 2026: tubul shishi-odoshi nu se citea).

  kyoto/props/daruma_otoshi.glb
      Base      placa de piatra pe care sta turnul (static)
      Disc_1..5 discurile, de jos in sus, culori saturate care alterneaza
      Head      capul de daruma: rosu, fata alba, ochi si sprancene negre
      Hammer    ciocanul (kizuchi): maciuca de lemn pe un brat, cu PIVOT la origine
      Frame     doi stalpi de lemn pe pietre + axa pivotului (static)

CONTRACTUL e scris in `scenes/hazards/daruma_otoshi_hazard.gd` (daca difera, codul
castiga). Coordonate de model (Godot): originea = axa turnului LA SOL; +X = spre
exterior, +Z = FATA (spre masina care vine), +Y = sus. In Blender glTF face
(x, y, z)_blender -> (x, z, -y)_godot: deci fata (+Z Godot) = -Y Blender, iar
ciocanul se balanseaza in planul XZ Blender, cu axa pivotului pe Y Blender.

  - Disc_j: originea la CENTRUL BAZEI lui, la z = BASE_H + (j-1) * DISC_H. Codul
    le coboara cu `position.y` si le creste cu `scale.y` (reconstructia), deci
    scala se aplica de jos in sus.
  - Head: originea la baza, la z = BASE_H + 5 * DISC_H.
  - Hammer: originea = axa pivotului, la (HAMMER_U, 0, PIVOT_Z). Atarna in jos;
    `rotation.z` Godot (+ = capul spre exterior). Capul maciucii, in repaus, e
    la HAMMER_U de axa turnului, exact pe inaltimea discului de jos.
  - Nicio scala neaplicata pe radacina (memoria `scala-glb-neaplicata-la-radacina`).
  - Sloturi: fara CAR_* (verify_glb le marcheaza ILEGAL in decor).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_daruma.py
"""

import math
from mathutils import Vector, Matrix

# --- Sloturi -------------------------------------------------------------
ORANGE = LAVA_ORANGE        # 30  disc 1
DEEP = SEA_DEEP             # 18  disc 2 (albastru-verde inchis)
GOLD = SAND_LIGHT           # 0   disc 3 (auriu)
GREEN = TROPICAL_GREEN      # 21  disc 4
TEAL = REEF_SHALLOW         # 17  disc 5 (turcoaz, langa capul rosu)
DISC_SLOTS = [ORANGE, DEEP, GOLD, GREEN, TEAL]
RED = KERB_RED              # 7   capul (CAR_RED 14 e rezervat masinilor)
FACE = FOAM_WHITE           # 22  fata
INK = LOG_DARK              # 28  ochi, sprancene, gura, legaturi
WOODC = WOOD                # 9
STONE = ROCK_LIGHT          # 3
STONE_D = CONCRETE          # 8

# --- Cote (identice cu exporturile hazardului) ---------------------------
R_DISC = 2.0
DISC_H = 1.3
BASE_H = 0.12
LEVELS = 5
HEAD_H = 2.7
HAMMER_U = 3.05             # axa pivotului, de la axa turnului (spre +X)
HAMMER_L = 5.02             # pivot -> centrul capului maciucii (talpa maciucii la z = 0)
R_MALLET = 0.95
MALLET_LEN = 2.8            # pe Y Blender (sensul de mers)
PIVOT_Z = 0.95 + HAMMER_L   # 5.97: maciuca in repaus are centrul la 0,95 m (talpa la sol)
POST_Y = 2.2                # stalpii, la +-Y Blender (de-o parte si de alta a maciucii)
SEG = 16
PIER = 3.0                  # adancimea pilonului de sub placa (si a picioarelor cadrului)


def build_base():
    b = Builder()
    # Pilon de piatra care coboara 3 m sub cota soselei: pe malul iazului turnul sta
    # pe stanca, nu plutește deasupra apei.
    b.cylinder((0.0, 0.0, (BASE_H - PIER) * 0.5), R_DISC + 0.55, BASE_H + PIER,
               STONE, segments=SEG)
    # inel mai ingust, de piatra mai inchisa, sub disc: placa pare asezata
    b.cylinder((0.0, 0.0, BASE_H * 0.5), R_DISC + 0.25, BASE_H + 0.02, STONE_D,
               segments=SEG)
    return b.to_object("Base")


def build_disc(slot):
    b = Builder()
    b.cylinder((0.0, 0.0, DISC_H * 0.5), R_DISC, DISC_H, slot, segments=SEG)
    return b.to_object("Disc")


def build_head():
    b = Builder()
    # Corpul: un ou de jucarie, mai lat jos, cu baza plata care sta pe Disc_5.
    profile = [(1.30, 0.0), (1.52, 0.30), (1.62, 0.95), (1.52, 1.65),
               (1.15, 2.25), (0.55, 2.62), (0.0, 2.72)]
    b.revolve(profile, RED, segments=SEG, cap_bottom=True)
    # Fata (pe -Y Blender = +Z Godot): placa alba, rotunda, putin iesita.
    fz = 1.45
    face_y = -1.50
    b.cylinder((0.0, face_y, fz), 0.98, 0.22, FACE, segments=SEG, axis="Y")
    # Ochii: negri, mari; sprancene groase, oblice (privire severa); gura.
    for sx in (-1.0, 1.0):
        b.cylinder((sx * 0.44, face_y - 0.13, fz + 0.12), 0.24, 0.10, INK,
                   segments=10, axis="Y")
        b.beam((sx * 0.80, face_y - 0.10, fz + 0.58),
               (sx * 0.20, face_y - 0.10, fz + 0.40), (0.14, 0.10), INK)
    b.box((0.0, face_y - 0.12, fz - 0.52), (0.62, 0.10, 0.12), INK)
    # Streasina de pe cap: o dunga rosie mai inchisa nu avem slot -> o banda neagra
    # subtire la baza capului il desparte de discuri (se citeste ca „gat").
    b.cylinder((0.0, 0.0, 0.07), 1.34, 0.14, INK, segments=SEG)
    return b.to_object("Head")


def build_hammer():
    """Originea = axa pivotului. Geometria atarna pe -Z Blender (in jos)."""
    b = Builder()
    # Bratul de lemn si maciuca (cilindru cu axa pe Y, doua inele de legatura).
    b.beam((0.0, 0.0, 0.25), (0.0, 0.0, -HAMMER_L + 0.3), (0.46, 0.46), WOODC)
    b.cylinder((0.0, 0.0, -HAMMER_L), R_MALLET, MALLET_LEN, WOODC,
               segments=SEG, axis="Y")
    for sy in (-1.0, 1.0):
        b.cylinder((0.0, sy * (MALLET_LEN * 0.5 - 0.22), -HAMMER_L),
                   R_MALLET + 0.07, 0.30, INK, segments=SEG, axis="Y")
    # Capete de lemn mai deschis pe fetele maciucii (se citeste ca lemn taiat).
    for sy in (-1.0, 1.0):
        b.cylinder((0.0, sy * (MALLET_LEN * 0.5 + 0.02), -HAMMER_L),
                   R_MALLET * 0.78, 0.06, SAND_LIGHT, segments=SEG, axis="Y")
    # Butucul pivotului: un cilindru scurt pe axa (Y), legat cu negru.
    b.cylinder((0.0, 0.0, 0.0), 0.30, 0.9, INK, segments=10, axis="Y")
    return b.to_object("Hammer")


def build_frame():
    b = Builder()
    px = HAMMER_U
    for sy in (-1.0, 1.0):
        y = sy * POST_Y
        # picior de piatra
        b.box((px, y, (0.35 - PIER) * 0.5), (1.5, 1.5, PIER + 0.35), STONE)
        # stalpul de lemn, din piatra pana deasupra pivotului
        b.box((px, y, (PIVOT_Z + 0.55) * 0.5 + 0.2), (0.80, 0.80, PIVOT_Z + 0.35), WOODC)
        # contrafisa spre exterior (+X): sprijin pentru zvacnetul loviturii
        b.beam((px, y, 0.4), (px + 2.1, y, 0.15), (0.44, 0.44), WOODC)
        b.beam((px + 2.1, y, 0.4), (px, y, PIVOT_Z * 0.78), (0.40, 0.40), WOODC)
        # cap rosu pe stalp (accent, citeste de departe)
        b.box((px, y, PIVOT_Z + 0.62), (1.08, 1.08, 0.30), RED)
        # lagarul (bloc de lemn deschis) in care intra axa
        b.box((px, y * 0.78, PIVOT_Z), (0.52, 0.34, 0.52), WOODC)
    # axa: bara pe Y, trece prin butucul ciocanului
    b.cylinder((px, 0.0, PIVOT_Z), 0.17, 2.0 * POST_Y + 0.6, INK, segments=8, axis="Y")
    return b.to_object("Frame")


clear_built()
base = build_base()
discs = [build_disc(s) for s in DISC_SLOTS]
head = build_head()
hammer = build_hammer()
frame = build_frame()
for j, d in enumerate(discs):
    d.name = "Disc_%d" % (j + 1)


def _ao(z_lo, z_hi, low=0.62, dist=1.6, grad="vertical"):
    return dict(samples=24, dist=dist, gradient=grad, low=low, high=1.0,
                power=0.9, floor=0.28, z_range=(z_lo - 0.05, z_hi))


stats = {}
stats["Base"] = finish(base, bevel=0.04, ao=_ao(-PIER, BASE_H, 0.7), origin=None,
                       smooth_angle=None)
for j, d in enumerate(discs):
    stats[d.name] = finish(d, bevel=0.06, bevel_segments=2, ao=_ao(0.0, DISC_H, 0.72),
                           origin=None, smooth_angle=40.0)
stats["Head"] = finish(head, bevel=0.03, ao=_ao(0.0, HEAD_H, 0.62), origin=None,
                       smooth_angle=40.0)
# Ciocanul se balanseaza: gradient vertical copt ar ajunge pe partea gresita.
stats["Hammer"] = finish(hammer, bevel=0.03, ao=dict(samples=24, dist=1.0,
                         gradient="none", floor=0.35), origin=None, smooth_angle=40.0)
stats["Frame"] = finish(frame, bevel=0.04, ao=_ao(-PIER, PIVOT_Z + 0.75, 0.55),
                        origin=None, smooth_angle=None)

base.location = (0.0, 0.0, 0.0)
for j, d in enumerate(discs):
    d.location = (0.0, 0.0, BASE_H + j * DISC_H)
head.location = (0.0, 0.0, BASE_H + LEVELS * DISC_H)
hammer.location = (HAMMER_U, 0.0, PIVOT_Z)
frame.location = (0.0, 0.0, 0.0)
# Ciocanul a fost modelat cu axa la (0,0,0) in coordonate locale; stalpii cadrului
# sunt modelati direct la x = HAMMER_U (cadrul sta la origine).
for o in [base, head, hammer, frame] + discs:
    o.rotation_euler = (0.0, 0.0, 0.0)

objs = [base] + discs + [head, hammer, frame]
path, size = export_glb(objs, "kyoto/props/daruma_otoshi.glb")
save_blend(objs, "kyoto_daruma_otoshi.blend")
print("== daruma_otoshi ==", path, "%.1f KB" % (size / 1024.0))
for k, v in stats.items():
    print("  %-8s tris=%d ao=[%.2f..%.2f]" % (k, v["tris"], v["ao_min"], v["ao_max"]))
print("  total tris:", sum(v["tris"] for v in stats.values()),
      "| turn %.2f m | pivot z=%.2f" % (BASE_H + LEVELS * DISC_H + HEAD_H, PIVOT_Z))
