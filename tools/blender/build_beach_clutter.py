"""beach_clutter.glb — viata de pe plaja si din port (Okinawa).

Referinta: assets/okinawa_inspiration/, randul BEACH CLUTTER. Cinci obiecte
intr-un singur fisier, dupa conventia de variante din docs/blender_export.md.
Nu sunt decor generic: fiecare spune ca AICI LUCREAZA CINEVA, iar asta e ce
lipseste unei plaje altfel goale.

  Fishing_Crate   0.60 m — lada de pescuit, scandura pe scandura
  Net_Floats      0.50 m — gramada de plute de plasa
  Awamori_Pot     0.90 m — oala de ceramica pentru awamori, cu franghie
  Bamboo_Rack     1.40 m — rastel de prajini de bambus (usca plasele)
  Driftwood_Log   0.70 m — busteanul spalat de mare

Toate raman pe atlasul de paleta: sub 1 m textura nu se citeste (style_bible
§4). Bevel mic (0.02) — sunt obiecte pe care treci pe langa la 2 m distanta,
deci muchia conteaza, dar sunt si multe.
"""

import math
from mathutils import Vector, Matrix

AO_SPEC = dict(samples=22, dist=1.2, gradient="vertical",
               low=0.48, high=1.0, power=0.75, floor=0.18)


def fishing_crate(b):
    """Lada din scandura, cu sipci vizibile si un colt rupt."""
    w, d, h = 0.58, 0.42, 0.36
    t = 0.035
    # Peretii din sipci orizontale, cu rost intre ele: o cutie plina ar fi fost
    # trei triunghiuri mai ieftina si ar fi aratat ca o cutie.
    for k in range(3):
        z = h * (0.14 + k * 0.34)
        for sy in (-1.0, 1.0):
            b.box((0.0, sy * (d * 0.5 - t * 0.5), z), (w, t, h * 0.24), WOOD)
        for sx in (-1.0, 1.0):
            b.box((sx * (w * 0.5 - t * 0.5), 0.0, z), (t, d, h * 0.24), WOOD)
    # Montantii de colt.
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (w * 0.5 - t), sy * (d * 0.5 - t), h * 0.5),
                  (t * 1.6, t * 1.6, h), WOOD)
    b.box((0.0, 0.0, t * 0.5), (w - t * 2, d - t * 2, t), WOOD)


def net_floats(b):
    """Plasa strinsa gramada, cu plute de pluta ivite din ea."""
    rnd = _lcg(19)
    # Masa plasei: doi bulgari turtiti, culoarea franghiei.
    for k in range(3):
        a = rnd() * math.tau
        r = rnd() * 0.16
        b.boulder((math.cos(a) * r, math.sin(a) * r, 0.13 + rnd() * 0.05),
                  (0.42 - k * 0.05, 0.38 - k * 0.05, 0.22), DRY_VEGETATION,
                  seed=19 + k * 7, segments=7, rings=3, deviation=0.20)
    # Plutele: bile mici de pluta, jumatate ingropate in plasa.
    for k in range(7):
        a = rnd() * math.tau
        r = 0.10 + rnd() * 0.16
        b.boulder((math.cos(a) * r, math.sin(a) * r, 0.16 + rnd() * 0.12),
                  (0.13, 0.13, 0.12), SAND_MID, seed=31 + k * 5,
                  segments=6, rings=3, deviation=0.08)


def awamori_pot(b):
    """Oala de awamori: profil de revolutie cu gat ingust si franghie."""
    b.revolve([(0.16, 0.0), (0.30, 0.14), (0.36, 0.38), (0.32, 0.58),
               (0.20, 0.74), (0.15, 0.84), (0.19, 0.90), (0.0, 0.90)],
              RUST, segments=10)
    # Franghia: doua inele in jurul umarului, si gatul infasurat.
    for z, r in ((0.52, 0.335), (0.68, 0.255)):
        b.torus((0, 0, z), r, 0.022, DRY_VEGETATION, major_seg=10, minor_seg=4)
    b.torus((0, 0, 0.86), 0.185, 0.020, DRY_VEGETATION, major_seg=10,
            minor_seg=4)


def bamboo_rack(b):
    """Rastel de prajini: doi A-uri si o traversa, cu prajini rezemate."""
    h = 1.36
    span = 0.62
    for sy in (-1.0, 1.0):
        y = sy * span * 0.5
        for sx in (-1.0, 1.0):
            b.taper_sweep([(sx * 0.30, y, 0.0), (sx * 0.05, y, h)],
                          [0.035, 0.028], WOOD, segments=5)
    b.taper_sweep([(0.0, -span * 0.5 - 0.08, h - 0.05),
                   (0.0, span * 0.5 + 0.08, h - 0.05)],
                  [0.030, 0.030], WOOD, segments=5)
    # Prajinile de bambus rezemate — verzi-galbui, nu maro de scandura.
    rnd = _lcg(43)
    for k in range(5):
        y = -span * 0.42 + span * 0.84 * (k / 4.0)
        b.taper_sweep([(0.34 + rnd() * 0.10, y, 0.0),
                       (-0.05, y + (rnd() - 0.5) * 0.06, h - 0.10)],
                      [0.026, 0.021], CACTUS_GREEN, segments=5)


def driftwood_log(b):
    """Bustean spalat de mare: cenusiu-pal, cu doua cioturi. Fratele mai mare al
    lui `Driftwood` din island_scatter — asta e prop de asezat cu mana."""
    b.taper_sweep([(-0.34, 0.0, 0.11), (-0.08, 0.05, 0.14),
                   (0.20, -0.03, 0.13), (0.36, 0.03, 0.09)],
                  [0.075, 0.105, 0.092, 0.0], DRY_VEGETATION, segments=7)
    b.taper_sweep([(-0.05, 0.03, 0.16), (0.03, 0.16, 0.32)],
                  [0.042, 0.0], DRY_VEGETATION, segments=5)
    b.taper_sweep([(0.16, -0.02, 0.16), (0.26, -0.15, 0.27)],
                  [0.034, 0.0], DRY_VEGETATION, segments=5)


PARTS = [
    ("Fishing_Crate", fishing_crate),
    ("Net_Floats", net_floats),
    ("Awamori_Pot", awamori_pot),
    ("Bamboo_Rack", bamboo_rack),
    ("Driftwood_Log", driftwood_log),
]

for name, _f in PARTS:
    clear_built(name)
built = []
for name, fill in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.02, ao=AO_SPEC)
    built.append(obj)
    d = obj.dimensions
    print("%-16s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "beach_clutter.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "beach_clutter.blend"))
for i, o in enumerate(built):
    o.location = (i * 1.4, 0.0, 0.0)
