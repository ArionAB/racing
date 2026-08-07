"""hibiscus_bush.glb — tufa de hibiscus cu flori rosii (HIBISCUS_BUSH, 1.0 m).

Referinta: assets/okinawa_inspiration/, randul BEACH CLUTTER. Singurul punct de
ROSU natural din decorul insulei — de aia merita un asset propriu si nu un tufis
verde oarecare: pata de culoare e ce citeste ochiul la 30 m, nu forma frunzei.

Ramane pe atlasul de paleta, fara textura de clasa, si asta e regula, nu o
scutire: sub 1 m textura nu se citeste (style_bible §4, alaturi de marker_post
si scatter). Florile folosesc KERB_RED, nu accentele de masina (14-16), care
sunt rezervate si ies magenta in decor.

Buget: filler, se instantiaza in tufe de cate 3-5 -> tinta <= 500 tris.
"""

import math

CLUMPS = 7
FLOWERS = 11
W = 1.30          # latimea tufei
H = 0.95


def foliage(b, seed=23):
    """Bulgari verzi intr-o movila mai lata decat inalta."""
    rnd = _lcg(seed)
    for k in range(CLUMPS):
        a = 2.0 * math.pi * k / CLUMPS + rnd() * 0.5
        r = 0.0 if k == 0 else W * 0.29 * (0.55 + rnd() * 0.75)
        z = H * (0.62 if k == 0 else 0.34 + rnd() * 0.30)
        size = 0.72 - r * 0.16 + rnd() * 0.22
        # `boulder` si nu `rock`: rock inchide cu capac plat sus, deci bulgarii
        # de frunzis ieseau conici. Aceeasi lectie ca la coroana banyanului.
        b.boulder((math.cos(a) * r, math.sin(a) * r, z),
                  (size, size * 0.94, size * 0.80),
                  TROPICAL_GREEN if k % 2 else CACTUS_GREEN,
                  seed=seed + k * 11, segments=7, rings=4, deviation=0.16)


def flowers(b, seed=71):
    """Flori: discuri mici turtite, asezate pe FATA exterioara a tufei.

    Puse pe o sfera in jurul centrului, jumatate din ele ar fi ajuns inauntru,
    invizibile si platite degeaba. Raza e aproape cea a tufei, deci fiecare
    floare iese putin din frunzis — exact cat sa prinda lumina.
    """
    rnd = _lcg(seed)
    for k in range(FLOWERS):
        a = 2.0 * math.pi * k / FLOWERS + rnd() * 0.7
        elev = 0.15 + rnd() * 0.75          # 0 = pe ecuator, 1 = in varf
        # Raza e 0.60 din latime, nu 0.47: la prima incercare florile stateau
        # exact pe suprafata bulgarilor, deci le inghitea frunzisul si din
        # unsprezece se vedea UNA. O floare trebuie sa iasa din tufa.
        r = W * 0.60 * math.cos(elev * math.pi * 0.5) * (0.88 + rnd() * 0.18)
        z = H * (0.32 + elev * 0.66)
        b.boulder((math.cos(a) * r, math.sin(a) * r, z), (0.28, 0.28, 0.13),
                  KERB_RED, seed=seed + k * 17, segments=6, rings=3,
                  deviation=0.10)


clear_built("Hibiscus")

b = Builder()
foliage(b)
flowers(b)
obj = b.to_object("Hibiscus")
stats = finish(
    obj,
    bevel=0.0,   # ca la cactus: numai suprafete de revolutie, nimic de tesit
    ao=dict(samples=24, dist=1.4, gradient="vertical",
            low=0.46, high=1.0, power=0.7, floor=0.16),
)
d = obj.dimensions
print("Hibiscus  %d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
      % (stats["tris"], stats["ao_min"], stats["ao_max"], d.x, d.y, d.z))
print("GLB:  %s (%d B)" % export_glb([obj], "plants/hibiscus_bush.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "hibiscus_bush.blend"))
