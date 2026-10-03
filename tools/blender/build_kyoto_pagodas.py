"""Kyoto -- pagodele (brief docs/asset_briefs/kyoto_kit.md §1.1).

  kyoto/structures/yasaka_pagoda.glb      pagoda Yasaka, 5 etaje, 24 m   (PILOT)
  (urmeaza: sanjunoto_pagoda, koyasu_pagoda)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_pagodas.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

# Sloturi (brief kyoto_kit §0.4)
TILE = VOLCANIC_BLACK      # tigla kawara, din atlas, nervuri in geometrie
BEAM = LOG_DARK            # grinzi, console, fateta streasinii
POST = WOOD                # stalpi, balustrade (brun-roscat pe planșa)
PLASTER = FOAM_WHITE       # panouri de var
DARK = VOLCANIC_BLACK      # goluri de fereastra
GOLD = CAR_YELLOW          # sorin (exceptie --allow-car-slots=Pagoda_Spire)
STONE = MARBLE_GREY        # soclul

AO_PAGODA = dict(samples=12, dist=3.5, gradient="vertical",
                 low=0.72, high=1.0, power=0.8, floor=0.30)

clear_built()


def _tier_walls(bb, bw, i, cx, cy, z0, z1, w, plaster, posts):
    """Corpul unui etaj: miez, stalpi, brauri, ferestre pe patru fete."""
    h = z1 - z0
    core_slot = BEAM if plaster else POST
    bb.box((cx, cy, z0 + h * 0.5), (2 * w, 2 * w, h), core_slot)
    # brau sus si jos (nuki) iesit 0.12
    for zz, hh in ((z0 + 0.12, 0.24), (z1 - 0.22, 0.44)):
        frame_ring(bb, cx, cy, zz - hh * 0.5, w + 0.12, w + 0.12, hh, 0.22, BEAM)
    # stalpi: 4 de colt + 2 pe latura
    pw = 0.30 if i else 0.36
    offs = [-w, -w / 3.0, w / 3.0, w]
    for sgn in (-1, 1):
        for o in offs:
            for (px, py) in ((cx + o, cy + sgn * w), (cx + sgn * w, cy + o)):
                bb.box((px, py, z0 + h * 0.5), (pw, pw, h), POST)
    if plaster:
        # panouri de var intre stalpi (parter), proeminente 3 cm
        for side in range(4):
            ang = side * math.pi / 2
            c, s_ = math.cos(ang), math.sin(ang)
            for o in (-2 * w / 3.0, 0.0, 2 * w / 3.0):
                lx, ly = o, w + 0.03
                bb.box((cx + lx * c - ly * s_, cy + lx * s_ + ly * c, z0 + h * 0.5),
                       ((w / 3.0 - 0.45) if side % 2 == 0 else 0.07,
                        0.07 if side % 2 == 0 else (w / 3.0 - 0.45), h * 0.84), PLASTER)
    # ferestre/goluri pe fiecare fata: 3 pe latura (la parter: 2 + usa)
    for side in range(4):
        ang = side * math.pi / 2
        c, s = math.cos(ang), math.sin(ang)
        for k, o in enumerate((-2 * w / 3.0, 0.0, 2 * w / 3.0)):
            lx, ly = o, w + 0.04     # in planul fetei locale +Y
            px = cx + lx * c - ly * s
            py = cy + lx * s + ly * c
            ww = w / 3.0 * 0.62
            wh = h * (0.55 if not plaster else 0.5)
            zc = z0 + h * (0.5 if not plaster else 0.55)
            if plaster and side == 0 and k == 1:
                wh = h * 0.72
                zc = z0 + wh * 0.5 + 0.1
                ww = w / 3.0 * 0.8
            sx = ww if side % 2 == 0 else 0.12
            sy = 0.12 if side % 2 == 0 else ww
            bw.box((px, py, zc), (sx, sy, wh), DARK)
            # montant central subtire (grila)
            bw.box((px, py, zc), (0.07 if side % 2 == 0 else 0.16,
                                  0.16 if side % 2 == 0 else 0.07, wh * 1.02), POST)


def build_yasaka_pagoda():
    """`yasaka_pagoda.png` -- lista de elemente (inainte de modelare):

    - 5 acoperisuri in patru ape, gri-inchis, cu colturile ridicate; latimea
      scade spre varf (raport streasini ~1 : .91 : .81 : .71 : .60).
    - Sub fiecare acoperis un brau de console (rand dublu, brun inchis) care
      iese mai mult decat peretele.
    - Peretii: 5 trupuri patrate; cel de jos e mai inalt, cu var alb + 3
      goluri pe fata si usa pe fata din fata (+Y); cele 4 de sus brun-roscat
      cu 3 ferestre/grile pe fiecare fata si balustrada joasa.
    - Soclu scund de piatra.
    - Varful: acoperisul de sus mai inalt (varf ascutit), apoi sorin aurit:
      bol rasturnat, sfera, stalp cu ~9 inele, flacara de apa; ~17% din
      inaltimea totala (spire).
    - Iese din contur: sorin, colturile acoperisurilor ridicate.
    Cote: 24 m total, streasina de jos 16 m latime.
    """
    roof = Builder()
    body = Builder()
    glow = Builder()      # goluri (DARK) -- nod separat, clasele nu le sterg
    spire = Builder()

    plinth_h = 0.55
    eave_hw = [6.0, 5.5, 4.95, 4.35, 3.65]
    wall_hw = [3.45, 3.15, 2.8, 2.45, 2.1]
    eave_z = [4.5, 7.6, 10.7, 13.8, 16.9]
    rise = [0.95, 0.95, 0.9, 0.9, 2.6]
    lift = [0.7, 0.65, 0.6, 0.55, 0.5]

    # soclu
    body.box((0, 0, plinth_h * 0.5), (2 * 4.6, 2 * 4.6, plinth_h), STONE)

    for i in range(5):
        base_z = plinth_h if i == 0 else eave_z[i - 1] + 0.85
        top_z = eave_z[i] - 0.15
        _tier_walls(body, glow, i, 0.0, 0.0, base_z, top_z, wall_hw[i],
                    plaster=(i == 0), posts=True)
        # console sub streasina: doua trepte
        w = wall_hw[i]
        frame_ring(body, 0, 0, eave_z[i] - 0.75, w + 0.45, w + 0.45, 0.32, 0.45, BEAM)
        frame_ring(body, 0, 0, eave_z[i] - 0.43, w + 0.85, w + 0.85, 0.28, 0.45, POST)
        # capete de console ("tokyo"): blocuri intunecate sub streasina
        cw = w + 0.5
        for sgn in (-1, 1):
            body.pickets((-cw, sgn * cw, eave_z[i] - 0.95), (cw, sgn * cw, eave_z[i] - 0.95),
                         0.95, (0.34, 0.34, 0.5), BEAM, endpoints=True)
            body.pickets((sgn * cw, -cw, eave_z[i] - 0.95), (sgn * cw, cw, eave_z[i] - 0.95),
                         0.95, (0.34, 0.34, 0.5), BEAM, endpoints=True)
        # balustrada joasa (etajele 2-5): pe o placa
        if i > 0:
            pw_ = w + 0.7
            body.box((0, 0, base_z + 0.05), (2 * pw_, 2 * pw_, 0.16), BEAM)
            for sgn in (-1, 1):
                body.railing((-pw_, sgn * pw_, base_z + 0.1),
                             (pw_, sgn * pw_, base_z + 0.1), 0.85, 1.4, 0.1, 0.09, POST, rails=1)
                body.railing((sgn * pw_, -pw_, base_z + 0.1),
                             (sgn * pw_, pw_, base_z + 0.1), 0.85, 1.4, 0.1, 0.09, POST, rails=1)
        hip_roof(roof, 0, 0, eave_z[i], eave_hw[i], eave_hw[i], rise[i], TILE,
                 lift=lift[i], thick=0.3, fascia_slot=BEAM, tile_step=0.85,
                 rib=0.05, swell=0.3)

    # sorin
    apex = eave_z[4] + rise[4]
    sp = spire
    sp.frustum((0, 0, apex + 0.22), 0.62, 0.42, 0.44, GOLD, segments=8)    # bol
    sp.frustum((0, 0, apex + 0.62), 0.34, 0.5, 0.36, GOLD, segments=8)
    sp.frustum((0, 0, apex + 0.98), 0.5, 0.0, 0.4, GOLD, segments=8)       # sfera/ou
    sp.cylinder((0, 0, apex + 2.6), 0.11, 4.0, GOLD, segments=6)           # stalp
    radii = [0.40 - 0.02 * k for k in range(9)]
    ring_stack(sp, 0, 0, apex + 1.55, radii, 0.26, 0.10, GOLD, segments=8)
    sp.frustum((0, 0, apex + 4.1), 0.26, 0.0, 0.7, GOLD, segments=6)       # flacara
    return (roof.to_object("Pagoda_Roof"), body.to_object("Pagoda_Body"),
            glow.to_object("Pagoda_Windows"), sp.to_object("Pagoda_Spire"))


if __name__ == "__main__" or True:
    r, b_, g_, s_ = build_yasaka_pagoda()
    emit([r, b_, g_, s_], "structures/yasaka_pagoda.glb", AO_PAGODA,
         bevel=0.0, smooth_angle=None, budget=9500)
    report()
