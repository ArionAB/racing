"""Kyoto -- pavilionul de aur (brief docs/asset_briefs/kyoto_kit.md §1.4).

  kyoto/structures/kinkakuji.glb    Kinkaku-ji, 3 etaje, ~14 m

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_kinkakuji.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

TILE = ASPHALT_EDGE  # gri neutru #696765, nu violetul #55535A
BEAM = LOG_DARK
WOODS = WOOD
GOLD = CAR_YELLOW
STONE = CONCRETE
BASE = MARBLE_GREY
DARK = LOG_DARK

AO_KIN = dict(samples=12, dist=3.5, gradient="vertical",
              low=0.72, high=1.0, power=0.8, floor=0.30)

clear_built()


def _rail(b, hx, hy, z, h, slot, step=0.9):
    """Balustrada dreptunghiulara: stalpi + doua lise pe cele patru laturi."""
    for a, c in (((-hx, -hy), (hx, -hy)), ((hx, -hy), (hx, hy)),
                 ((hx, hy), (-hx, hy)), ((-hx, hy), (-hx, -hy))):
        b.railing((a[0], a[1], z), (c[0], c[1], z), h, step, 0.16, 0.14, slot, rails=2)


def _phoenix(b, z):
    """Fenix mic pe coama: soclu, corp, gat, cap, doua aripi ridicate, coada."""
    b.frustum((0, 0, z + 0.15), 0.35, 0.22, 0.3, GOLD, segments=6)       # postament
    b.box((0, 0, z + 0.6), (0.5, 1.1, 0.5), GOLD)                       # corp
    b.box((0, 0.42, z + 0.95), (0.2, 0.2, 0.55), GOLD)                   # gat
    b.box((0, 0.5, z + 1.28), (0.22, 0.36, 0.2), GOLD)                   # cap
    b.box((0, 0.74, z + 1.26), (0.08, 0.2, 0.06), GOLD)                  # cioc
    for sx in (-1, 1):
        b.beam((sx * 0.14, 0.05, z + 0.72), (sx * 0.78, -0.1, z + 1.4), (0.07, 0.3), GOLD)
    b.beam((0, -0.4, z + 0.7), (0, -0.95, z + 1.5), (0.1, 0.3), GOLD)    # coada


def build_kinkakuji():
    """`kinkakuji.png` -- lista de elemente (inainte de modelare):

    - Platforma joasa de piatra gri, mai larga decat cladirea.
    - Etajul 1 (jos): lemn natural INCHIS, deschis, cu stalpi de lemn pe toate
      laturile (~7 pe fata lunga) si interior intunecat; deasupra o verandă
      (pardoseala iesita) cu balustrada.
    - Etajul 2: AUR, perete plin cu 3-4 ferestre mici intunecate pe fata si o
      balustrada aurie de jur imprejur (galeria); peste el un acoperis LARG,
      subtire, gri-inchis, cu colturi usor ridicate (cel mai lat element).
    - Etajul 3: AUR, mai mic (~60% din etajul 2), cu balustrada si ferestre;
      deasupra acoperisul de sus, piramida mare gri-inchis cu streasina curbata.
    - Pe coama: fenix aurit mic. Fara pini (se pun separat).
    Cote: ~14 m inalt, ~13 m lat (streasina etajului 2).
    """
    wood, gold, roof, win, stone = Builder(), Builder(), Builder(), Builder(), Builder()
    bh = 0.5
    stone.box((0, 0, bh * 0.5), (14.0, 11.4, bh), BASE)
    # --- etajul 1: lemn deschis
    z0, z1 = bh, 3.6
    h1 = z1 - z0
    hx1, hy1 = 5.6, 4.5
    wood.box((0, 0, z0 + h1 * 0.5), (2 * hx1 - 0.1, 2 * hy1 - 0.1, h1), BEAM)       # perete intunecat
    n = 7
    for k in range(n):
        x = -hx1 + 2 * hx1 * k / (n - 1)
        for sy in (-1, 1):
            wood.box((x, sy * hy1, z0 + h1 * 0.5), (0.4, 0.4, h1), WOODS)
    for k in range(1, 6):
        y = -hy1 + 2 * hy1 * k / 6
        for sx in (-1, 1):
            wood.box((sx * hx1, y, z0 + h1 * 0.5), (0.4, 0.4, h1), WOODS)
    # grinzi sus si jos, zabrele joase intre stalpi
    frame_ring(wood, 0, 0, z1 - 0.45, hx1 + 0.1, hy1 + 0.1, 0.45, 0.3, WOODS)
    frame_ring(wood, 0, 0, z0 + 0.15, hx1 + 0.05, hy1 + 0.05, 0.3, 0.25, WOODS)
    frame_ring(wood, 0, 0, z0 + 1.1, hx1 + 0.03, hy1 + 0.03, 0.14, 0.14, BEAM)
    # panouri de zabrele (mai deschise) intre stalpi, pe fetele lungi
    for k in range(n - 1):
        x = -hx1 + 2 * hx1 * (k + 0.5) / (n - 1)
        for sy in (-1, 1):
            wood.box((x, sy * (hy1 + 0.02), z0 + h1 * 0.52), (2 * hx1 / (n - 1) - 0.7, 0.08, h1 * 0.55), WOODS)
    # --- veranda etajului 2 (pardoseala iesita) + etajul 2 aur
    wood.box((0, 0, z1 + 0.15), (2 * hx1 + 1.6, 2 * hy1 + 1.6, 0.3), WOODS)
    z2 = z1 + 0.3
    z3 = 7.0
    h2 = z3 - z2
    hx2, hy2 = 4.9, 3.8
    gold.box((0, 0, z2 + h2 * 0.5), (2 * hx2, 2 * hy2, h2), GOLD)
    frame_ring(gold, 0, 0, z3 - 0.35, hx2 + 0.12, hy2 + 0.12, 0.35, 0.25, GOLD)
    frame_ring(gold, 0, 0, z2, hx2 + 0.1, hy2 + 0.1, 0.25, 0.2, GOLD)
    for sx in (-1, 1):
        for sy in (-1, 1):
            gold.box((sx * hx2, sy * hy2, z2 + h2 * 0.5), (0.4, 0.4, h2), GOLD)
    _rail(gold, hx1 + 0.55, hy1 + 0.55, z1 + 0.3, 0.95, GOLD)
    # ferestre etaj 2: 4 pe fata lunga, 3 pe cea scurta
    for (cnt, face_len, side) in ((4, 2 * hx2, 0), (4, 2 * hx2, 2), (3, 2 * hy2, 1), (3, 2 * hy2, 3)):
        for k in range(cnt):
            o = (-face_len / 2 + face_len * (k + 0.5) / cnt)
            half = hx2 if side % 2 == 0 else hy2
            ang = side * math.pi / 2
            lx, ly = o, half + 0.04
            px = lx * math.cos(ang) - ly * math.sin(ang)
            py = lx * math.sin(ang) + ly * math.cos(ang)
            sx_, sy_ = (0.7, 0.1) if side % 2 == 0 else (0.1, 0.7)
            win.box((px, py, z2 + h2 * 0.55), (sx_, sy_, 1.0), DARK)
    # --- acoperis 1, lat si subtire
    hip_roof(roof, 0, 0, z3, 6.6, 5.4, 1.0, TILE, ridge_half=1.0, lift=0.55,
             thick=0.22, fascia_slot=BEAM, tile_step=0.9, rib=0.05, swell=0.3)
    # --- etajul 3 aur, mai mic
    z4 = z3 + 0.8
    z5 = 9.9
    h3 = z5 - z4
    hx3, hy3 = 3.5, 2.7
    gold.box((0, 0, z4 + h3 * 0.5), (2 * hx3, 2 * hy3, h3), GOLD)
    gold.box((0, 0, z4 + 0.1), (2 * hx3 + 1.5, 2 * hy3 + 1.5, 0.25), GOLD)
    frame_ring(gold, 0, 0, z5 - 0.3, hx3 + 0.1, hy3 + 0.1, 0.3, 0.22, GOLD)
    for sx in (-1, 1):
        for sy in (-1, 1):
            gold.box((sx * hx3, sy * hy3, z4 + h3 * 0.5), (0.36, 0.36, h3), GOLD)
    _rail(gold, hx3 + 0.7, hy3 + 0.7, z4 + 0.22, 0.9, GOLD, step=0.8)
    for (cnt, face_len, side) in ((3, 2 * hx3, 0), (3, 2 * hx3, 2), (2, 2 * hy3, 1), (2, 2 * hy3, 3)):
        for k in range(cnt):
            o = (-face_len / 2 + face_len * (k + 0.5) / cnt)
            half = hx3 if side % 2 == 0 else hy3
            ang = side * math.pi / 2
            px = o * math.cos(ang) - (half + 0.04) * math.sin(ang)
            py = o * math.sin(ang) + (half + 0.04) * math.cos(ang)
            sx_, sy_ = (0.6, 0.1) if side % 2 == 0 else (0.1, 0.6)
            win.box((px, py, z4 + h3 * 0.55), (sx_, sy_, 0.85), DARK)
    # --- acoperis 2: piramida mare
    hip_roof(roof, 0, 0, z5, 5.3, 4.3, 2.2, TILE, ridge_half=0.5, lift=0.6,
             thick=0.22, fascia_slot=BEAM, tile_step=0.9, rib=0.05, swell=0.3)
    _phoenix(gold, z5 + 2.2 - 0.05)
    return (wood.to_object("Kin_Wood"), gold.to_object("Kin_Gold"),
            roof.to_object("Kin_Roof"), win.to_object("Kin_Windows"),
            stone.to_object("Kin_Stone"))


if __name__ == "__main__" or True:
    emit(list(build_kinkakuji()), "structures/kinkakuji.glb", AO_KIN,
         bevel=0.0, smooth_angle=None, budget=6000)
    report()
