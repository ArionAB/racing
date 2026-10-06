"""Kyoto -- portile torii ale tunelului E' (brief kyoto.md §2.0, §3, §5.2, §5.6).

  kyoto/structures/torii_senbon.glb   o poarta pentru MultiMesh (pas 1,2 m)
  kyoto/structures/torii_large.glb    poarta mare de la gura tunelului
  kyoto/trees/cedar_dark.glb          PLACEHOLDER: cedrul peretelui de padure

Fara inscriptii (brief §8). Axele Blender: X = latimea portii (peste drum),
Y = adancimea (in lungul drumului), Z = sus. Piesa e simetrica in Y, deci
sensul de mers nu conteaza.

Cotele (MASURATE ca gol, nu declarate):
  senbon  gol liber 6,4 m intre fetele interioare ale stalpilor la baza,
          5,2 m liber sub `nuki`, stalpi de 0,7 m (=> latime exterioara 7,8 m
          la baza; brief-ul zicea ~6,8, dar 6,4 + 2 x 0,35 nu incape in 6,8:
          culoarul de 6,4 e contractul, latimea exterioara rezulta din el).
          Pasul 1,2 m cu adancimea 0,7 lasa un gol de 0,5 m < stalpul de 0,7.
  large   gol liber 7,4 m, 6,6 m liber sub `nuki`.

Culori: stalpi LAVA_ORANGE 30, grinda de sus `kasagi` LOG_DARK 28 cu capetele
ridicate (un contur in XZ extrudat pe Y), `nuki` LAVA_ORANGE, baze negre
VOLCANIC_BLACK 20.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_torii.py
"""

import math

POST = LAVA_ORANGE
BEAM = LOG_DARK
BASE = VOLCANIC_BLACK
LEAF = TROPICAL_GREEN
TRUNK = LOG_DARK

AO_GATE = dict(samples=20, dist=1.2, gradient="vertical",
               low=0.62, high=1.00, power=0.9, floor=0.40)
AO_CEDAR = dict(samples=16, dist=2.0, gradient="vertical",
                low=0.28, high=0.80, power=1.1, floor=0.20)


def build_gate(name, clear, nuki_clear, post_r, depth, kasagi_t, lift, over):
    """O poarta torii. `clear` = golul liber dintre fetele interioare ale
    stalpilor, `nuki_clear` = inaltimea libera sub nuki."""
    b = Builder()
    px = clear * 0.5 + post_r          # axa stalpului
    # Stalpul are un pic de conicitate (mai gros la baza), cu fata INTERIOARA
    # verticala nu e posibila pe un con, deci centrul se muta cu diferenta de
    # raza: golul la baza ramane `clear`.
    r_bot, r_top = post_r, post_r * 0.86
    h_post = nuki_clear + 0.45 + kasagi_t * 0.2
    base_h = post_r * 1.1
    for s in (-1.0, 1.0):
        b.frustum((s * px, 0.0, base_h + (h_post - base_h) * 0.5),
                  r_bot, r_top, h_post - base_h, POST, segments=8)
        # baza neagra, ceva mai lata decat stalpul
        b.frustum((s * px, 0.0, base_h * 0.5), r_bot * 1.18, r_bot * 1.12,
                  base_h, BASE, segments=8)
    # nuki: a doua grinda, trece prin stalpi si iese putin
    nuki_t = kasagi_t * 0.62
    nuki_w = (px + post_r) * 2.0 + over * 0.6
    b.box((0.0, 0.0, nuki_clear + nuki_t * 0.5), (nuki_w, depth * 0.62, nuki_t), POST)
    # kasagi: contur in XZ cu capetele ridicate, extrudat pe Y
    z0 = nuki_clear + nuki_t + 0.04
    hw = px + post_r + over
    k = kasagi_t
    outline = [
        (-hw, z0 + lift), (-hw * 0.74, z0 + lift * 0.18), (-hw * 0.42, z0),
        (hw * 0.42, z0), (hw * 0.74, z0 + lift * 0.18), (hw, z0 + lift),
        (hw, z0 + lift + k), (hw * 0.74, z0 + lift * 0.18 + k),
        (hw * 0.42, z0 + k), (-hw * 0.42, z0 + k),
        (-hw * 0.74, z0 + lift * 0.18 + k), (-hw, z0 + lift + k),
    ]
    # CCW pe X-Z privit din +Y: ordinea de mai sus e sus-dreapta -> jos-stanga
    # inversat; prism() recalculeaza oricum normalele la to_object.
    b.prism(outline, depth, BEAM)
    # sipca de sub kasagi (shimaki) nu se face: ar fi o a treia grinda in 1,2 m.
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.03, ao=AO_GATE, origin="base")
    return obj, stats


def build_cedar(name):
    b = Builder()
    b.frustum((0, 0, 1.2), 0.32, 0.22, 2.4, TRUNK, segments=6)
    z = 1.6
    tiers = [(2.5, 0.9, 4.2), (2.0, 0.7, 3.9), (1.5, 0.5, 3.5), (1.0, 0.25, 3.0)]
    for rb, rt, h in tiers:
        b.frustum((0, 0, z + h * 0.5), rb, rt * 0.25, h, LEAF, segments=7)
        z += h * 0.62
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.0, ao=AO_CEDAR, origin="base")
    return obj, stats


if __name__ == "__main__":
    clear_built()
    sen, s1 = build_gate("Torii_Senbon", 6.4, 5.2, 0.35, 0.70, 0.30, 0.22, 0.45)
    print("Torii_Senbon %d tris AO %.2f..%.2f" % (s1["tris"], s1["ao_min"], s1["ao_max"]))
    print("export:", export_glb([sen], "kyoto/structures/torii_senbon.glb"))
    lar, s2 = build_gate("Torii_Large", 7.4, 6.6, 0.55, 1.30, 0.50, 0.40, 0.70)
    # poarta mare: mutata pe 3 niveluri e inutil; doar scara lui nuki/kasagi.
    print("Torii_Large %d tris AO %.2f..%.2f" % (s2["tris"], s2["ao_min"], s2["ao_max"]))
    print("export:", export_glb([lar], "kyoto/structures/torii_large.glb"))
    ced, s3 = build_cedar("Cedar_Dark")
    print("Cedar_Dark %d tris AO %.2f..%.2f" % (s3["tris"], s3["ao_min"], s3["ao_max"]))
    print("export:", export_glb([ced], "kyoto/trees/cedar_dark.glb"))
