"""hibiscus_bush.glb — tufa de hibiscus cu flori rosii (HIBISCUS_BUSH, 1.0 m).

Referinta: assets/okinawa_inspiration/, randul BEACH CLUTTER. Singurul punct de
ROSU natural din decorul insulei — de aia merita un asset propriu si nu un tufis
verde oarecare: pata de culoare e ce citeste ochiul la 30 m, nu forma frunzei.

REFACUT in #208, aceeasi diagnoza ca tot setul de vegetatie: versiunea 1 era
o movila de bulgari cu buline — literalmente "sfere verzi cu puncte rosii".
Acum bulgarii raman doar miezul de masa, silueta o dau frunzele cu pliu in V
(dio_lib.leaf_vfold, reteta frondei de palmier), iar gradientul de culoare pe
verticala (dio_lib.tint_gradient, dupa finish() — bake_ao sterge culorile
scrise inainte) ii da baza intunecata si varfurile luminoase din referinta.

Ramane pe atlasul de paleta, fara textura de clasa, si asta e regula, nu o
scutire: sub 1 m textura nu se citeste (style_bible §4, alaturi de marker_post
si scatter). Florile folosesc KERB_RED, nu accentele de masina (14-16), care
sunt rezervate si ies magenta in decor.

Buget: filler, se instantiaza in tufe de cate 3-5 -> tinta <= 900 tris.
"""

import math

W = 1.30          # latimea tufei
H = 0.95


def foliage(b, seed=23):
    """Miez de bulgari + coroana de frunze care da silueta."""
    rnd = _lcg(seed)
    # Miezul: 4 bulgari care umplu tufa dinauntru, pe sol.
    size0 = W * 0.52
    b.boulder((0.0, 0.0, H - size0 * 0.45),
              (size0, size0 * 0.94, size0 * 0.80), TROPICAL_GREEN,
              seed=seed, segments=7, rings=4, deviation=0.15)
    for k in range(3):
        a = 2.0 * math.pi * k / 3.0 + rnd() * 0.5
        r = W * 0.24 * (0.75 + rnd() * 0.4)
        size = W * 0.40 * (0.85 + rnd() * 0.2)
        b.boulder((math.cos(a) * r, math.sin(a) * r, size * 0.32),
                  (size, size * 0.94, size * 0.80),
                  CACTUS_GREEN if k % 2 else TROPICAL_GREEN,
                  seed=seed + k * 11, segments=7, rings=4, deviation=0.16)
    # Coroana: frunze pe unghiul de aur, pornite dinauntrul miezului.
    # 4 statii si lungime tinuta in gabaritul de ~1.4 m — vezi leaf_crown
    # din build_veg_set pentru amandoua lectiile.
    for k in range(9):
        az = (k * 137.5) % 360.0 + rnd() * 14.0
        a = math.radians(az)
        r = W * (0.12 + 0.10 * rnd())
        leaf_vfold(b, (math.cos(a) * r, math.sin(a) * r,
                       H * (0.34 + rnd() * 0.28)), az,
                   W * 0.38 * (0.8 + rnd() * 0.30),
                   W * 0.17 * (0.85 + rnd() * 0.3),
                   H * (0.30 + rnd() * 0.20),
                   CACTUS_GREEN if k % 3 == 2 else TROPICAL_GREEN,
                   fold_deg=20.0 + rnd() * 12.0, stations=4, thick=W * 0.012)


def flowers(b, seed=71):
    """Flori: discuri mici turtite, asezate pe FATA exterioara a tufei.

    Raza e aproape cea a tufei, deci fiecare floare iese putin din frunzis —
    lectia versiunii 1: la 0.47 din latime le inghitea frunzisul si din
    unsprezece se vedea UNA.
    """
    rnd = _lcg(seed)
    for k in range(8):
        a = 2.0 * math.pi * k / 8.0 + rnd() * 0.7
        elev = 0.15 + rnd() * 0.75          # 0 = pe ecuator, 1 = in varf
        r = W * 0.60 * math.cos(elev * math.pi * 0.5) * (0.88 + rnd() * 0.18)
        z = H * (0.32 + elev * 0.66)
        b.boulder((math.cos(a) * r, math.sin(a) * r, z), (0.28, 0.28, 0.13),
                  KERB_RED, seed=seed + k * 17, segments=5, rings=2,
                  deviation=0.10)


clear_built("Hibiscus")

b = Builder()
foliage(b)
flowers(b)
obj = b.to_object("Hibiscus")
stats = finish(
    obj,
    bevel=0.0,   # ca la cactus: numai suprafete de revolutie si lame, nimic de tesit
    ao=dict(samples=24, dist=1.4, gradient="vertical",
            low=0.46, high=1.0, power=0.7, floor=0.16),
)
tint_gradient(obj, (0.52, 0.60, 0.50), (1.0, 1.0, 0.90))
d = obj.dimensions
print("Hibiscus  %d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
      % (stats["tris"], stats["ao_min"], stats["ao_max"], d.x, d.y, d.z))
print("GLB:  %s (%d B)" % export_glb([obj], "plants/hibiscus_bush.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "hibiscus_bush.blend"))
