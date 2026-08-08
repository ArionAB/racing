"""Set de vegetatie dupa foaia de referinta cu cinci piese, un GLB fiecare:

  Tropical_Shrub    2.3 x 2.3 x 1.5 m   plants/tropical_shrub.glb
  Flowers_Orange    1.5 x 1.5 x 0.8 m   flowers/flowers_orange.glb
  Flowers_White     1.5 x 1.5 x 0.6 m   flowers/flowers_white.glb
  Grass_Tuft_Large  1.8 x 1.8 x 1.2 m   plants/grass_tuft_large.glb
  Grass_Tuft_Small  0.9 x 0.9 x 0.6 m   plants/grass_tuft_small.glb

REFACUT in #208. Versiunea 1 era "sfere verzi cu buline": movile de bulgari
cu discuri pe calota. Comparatia cu referinta a aratat ca distanta nu e in
poligoane, ci in trei lucruri pe care low-poly-ul referintei le are si al
nostru nu le avea:

  1. SILUETA — frunze cu pliu in V si margini care ies din contur (reteta
     frondei de palmier: doua `blade()`-uri pe aceeasi cale, rotite in
     jurul nervurii cu +/-FOLD, `side_bias` +/-1). O frunza plata citeste
     a scandura vopsita verde; pliul ii da volum de la 40 m.
  2. GRADIENT DE CULOARE in vertex colors (baza inchisa-rece, varfuri
     calde-luminoase), inmultit PESTE AO-ul copt, dupa `finish()` —
     `bake_ao` sterge orice atribut de culoare scris inainte, deci ordinea
     nu e o preferinta, e o constrangere.
  3. AO care ancoreaza baza — era deja, ramane.

Bulgarii NU dispar: raman miezul de masa al tufelor (umplu golurile dintre
frunze dinauntru), doar ca nu mai sunt si silueta.

Lamele/frunzele raman VOLUME INCHISE (`blade()` cu grosime + capace):
materialul de lume e CULL_BACK, o foaie simpla dispare vazuta din spate.

Culori din paleta, fara texturi de clasa — sub 2.3 m textura nu se citeste
(style_bible §4, aceeasi regula ca hibiscus/marker_post/scatter):
  - portocaliu = TILE_TERRACOTTA (23): RUST_METAL e maro-noroi, KERB_RED e
    rosu curat, accentele de masina (14-16) sunt interzise in decor;
  - alb = FOAM_WHITE (22); verde = TROPICAL_GREEN/CACTUS_GREEN;
  - smocul mic = DRY_VEGETATION, ca in referinta (galbui, pe jumatate uscat).

Buget: filler de presarat — tinta <=900 tris per piesa (pragul din
verify_glb; instantele sunt multe, deci conteaza numarul lor, nu piesa).
"""

import math
from mathutils import Vector

GOLDEN_DEG = 137.5


def leaf_crown(b, w, h, count, seed, slots, z0, length_f=0.40, width_f=0.16):
    """Coroana de frunze in jurul miezului, pe unghiul de aur.

    Unghiul de aur (137.5°, lectia rozetei de pandanus) in loc de cerc
    impartit egal: cercul egal citeste a umbrela de plaja.
    4 statii per frunza, nu 5: a cincea costa 16 tris/frunza pentru o
    curbura pe care n-o citeste nimeni sub un metru (lectia frondei: 7 nu 9).
    `length_f` tine varfurile IN cota `w` — prima rulare cu 0.52 a scos
    tufa de 2.15 m la 3.6 m si scenografia ar fi plasat-o dupa alt gabarit.
    """
    rnd = _lcg(seed)
    for k in range(count):
        az = (k * GOLDEN_DEG) % 360.0 + rnd() * 14.0
        a = math.radians(az)
        r = w * (0.14 + 0.10 * rnd())
        z = z0 * (0.75 + rnd() * 0.5)
        leaf_vfold(b, (math.cos(a) * r, math.sin(a) * r, z), az,
             w * length_f * (0.82 + rnd() * 0.30),
             w * width_f * (0.85 + rnd() * 0.3),
             h * (0.30 + rnd() * 0.22), slots[k % len(slots)],
             fold_deg=20.0 + rnd() * 12.0, stations=4, thick=w * 0.012)


def core_mound(b, w, h, clumps, seed, slot_a=TROPICAL_GREEN,
               slot_b=CACTUS_GREEN):
    """Miezul de masa: putini bulgari, PE SOL, care umplu tufa dinauntru.

    Nu mai e silueta (aia e a frunzelor acum), deci sta cu ~15% mai strans
    decat vechea movila — frunzele pornesc dinauntrul lui, nu de pe el.
    """
    rnd = _lcg(seed)
    size0 = w * 0.55
    b.boulder((0.0, 0.0, h - size0 * 0.42),
              (size0, size0 * 0.94, size0 * 0.82), slot_a,
              seed=seed, segments=7, rings=4, deviation=0.15)
    for k in range(clumps):
        a = 2.0 * math.pi * k / clumps + rnd() * 0.5
        r = w * 0.24 * (0.70 + rnd() * 0.50)
        size = w * 0.40 * (0.85 + rnd() * 0.25)
        b.boulder((math.cos(a) * r, math.sin(a) * r, size * 0.30),
                  (size, size * 0.94, size * 0.80),
                  slot_b if k % 2 else slot_a,
                  seed=seed + k * 11, segments=7, rings=4, deviation=0.16)


def flower_heads(b, w, h, count, slot, head, seed):
    """Discuri turtite pe calota, iesite din frunzis, cu bias spre varf."""
    rnd = _lcg(seed)
    for k in range(count):
        a = 2.0 * math.pi * k / count + rnd() * 0.7
        elev = 0.22 + 0.78 * rnd() ** 0.55
        r = w * 0.52 * math.cos(elev * math.pi * 0.5) * (0.88 + rnd() * 0.18)
        z = h * (0.42 + elev * 0.62)
        b.boulder((math.cos(a) * r, math.sin(a) * r, z),
                  (head, head, head * 0.46), slot,
                  seed=seed + k * 17, segments=4, rings=2, deviation=0.10)


def blades(b, w, h, count, seed, slots, spread=0.30, z0=0.0):
    """Smoc: lame care pleaca dintr-un disc central, urca si cad in arc.

    Fata de v1: azimutul merge pe unghiul de aur (nu cerc egal + zar), iar
    arcul variaza per lama (unele aproape drepte, unele cazute) — un smoc
    cu toate firele la acelasi arc citeste a evantai stantat.
    """
    rnd = _lcg(seed)
    for k in range(count):
        az = (k * GOLDEN_DEG) % 360.0 + rnd() * 20.0
        a = math.radians(az)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        base = d * (w * spread * math.sqrt(rnd())) + Vector((0, 0, z0))
        length = h * (0.62 + rnd() * 0.46)
        reach = w * 0.5 - base.xy.length
        arc = 0.24 + rnd() * 0.55            # variatia de arc per lama
        lean = min(reach, length * arc)
        path, widths = [], []
        for i in range(4):
            t = i / 3.0
            path.append(base + d * (lean * t ** 1.7)
                        + Vector((0, 0, length * math.sin(t * (1.15 + arc * 0.5)))))
            widths.append(0.0 if i == 3
                          else w * 0.070 * math.sin(math.pi * (0.18 + t * 0.55)))
        b.blade(path, widths, w * 0.015, slots[k % len(slots)],
                up=d.cross(Vector((0, 0, 1))))


AO_VEG = dict(samples=20, dist=1.4, gradient="vertical",
              low=0.46, high=1.0, power=0.7, floor=0.16)
# Baza rece-inchisa, varfuri aproape de slot, usor spre galben.
TINT_LUSH = ((0.52, 0.60, 0.50), (1.0, 1.0, 0.90))
TINT_DRY = ((0.58, 0.60, 0.46), (1.0, 1.0, 0.78))

clear_built("Veg_")
built = []


def make(name, fname, build_fn, tint=TINT_LUSH):
    b = Builder()
    build_fn(b)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.0, ao=AO_VEG)
    tint_gradient(obj, tint[0], tint[1])
    built.append((obj, fname))
    d = obj.dimensions
    print("%-18s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))


# Tufa tropicala: miez + coroana de frunze late + cateva lame zburlite.
def tropical_shrub(b):
    core_mound(b, 2.0, 1.30, 3, seed=101)
    leaf_crown(b, 2.2, 1.35, 10, seed=107,
               slots=(TROPICAL_GREEN, CACTUS_GREEN), z0=0.72)
    blades(b, 2.3, 0.85, 4, seed=113,
           slots=(TROPICAL_GREEN, CACTUS_GREEN), spread=0.28, z0=0.55)


# Flori: rozeta joasa de frunze + capete pe calota. Miezul ramane mic, doar
# cat sa umple mijlocul rozetei.
def flowers_orange(b):
    core_mound(b, 1.05, 0.50, 2, seed=131)
    leaf_crown(b, 1.35, 0.55, 8, seed=133,
               slots=(TROPICAL_GREEN, CACTUS_GREEN), z0=0.16,
               length_f=0.36, width_f=0.20)
    flower_heads(b, 1.26, 0.62, 12, TILE_TERRACOTTA, head=0.26, seed=137)


def flowers_white(b):
    core_mound(b, 1.00, 0.40, 2, seed=151)
    leaf_crown(b, 1.30, 0.45, 8, seed=153,
               slots=(TROPICAL_GREEN, CACTUS_GREEN), z0=0.14,
               length_f=0.35, width_f=0.20)
    # capete putin mai mari decat formula comuna: FOAM_WHITE inmultit cu
    # AO-ul se stinge repede, iar sub 20 cm discul dispare de tot
    flower_heads(b, 1.30, 0.48, 11, FOAM_WHITE, head=0.23, seed=157)


def grass_large(b):
    blades(b, 1.8, 1.15, 24, seed=171, slots=(TROPICAL_GREEN, CACTUS_GREEN))


def grass_small(b):
    blades(b, 0.9, 0.58, 15, seed=191,
           slots=(DRY_VEGETATION, CACTUS_GREEN, DRY_VEGETATION), spread=0.36)


make("Veg_Tropical_Shrub", "plants/tropical_shrub.glb", tropical_shrub)
make("Veg_Flowers_Orange", "flowers/flowers_orange.glb", flowers_orange)
make("Veg_Flowers_White", "flowers/flowers_white.glb", flowers_white)
make("Veg_Grass_Tuft_Large", "plants/grass_tuft_large.glb", grass_large)
make("Veg_Grass_Tuft_Small", "plants/grass_tuft_small.glb", grass_small,
     tint=TINT_DRY)

for obj, fname in built:
    obj.location = (0.0, 0.0, 0.0)
    print("GLB:  %s (%d B)" % export_glb([obj], fname))
print("BLEND: %s (%d B)" % save_blend([o for o, _ in built], "veg_set.blend"))

x = 0.0
for obj, _ in built:
    obj.location = (x, 0.0, 0.0)
    x += max(obj.dimensions.x, 1.5) * 1.4
