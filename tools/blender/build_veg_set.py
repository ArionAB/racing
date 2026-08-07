"""Set de vegetatie dupa foaia de referinta cu cinci piese, un GLB fiecare:

  Tropical_Shrub    2.3 x 2.3 x 1.5 m   plants/tropical_shrub.glb
  Flowers_Orange    1.5 x 1.5 x 0.8 m   flowers/flowers_orange.glb
  Flowers_White     1.5 x 1.5 x 0.6 m   flowers/flowers_white.glb
  Grass_Tuft_Large  1.8 x 1.8 x 1.2 m   plants/grass_tuft_large.glb
  Grass_Tuft_Small  0.9 x 0.9 x 0.6 m   plants/grass_tuft_small.glb

Soclul de lemn din foaia de referinta e prezentarea pack-ului, nu se modeleaza.

Retetele vin din piesele care exista deja si arata bine:
  - frunzis = bulgari `boulder()` (lectia hibiscus/banyan: `rock()` inchide cu
    capac plat si bulgarii ies conici);
  - florile = discuri turtite scoase DINCOLO de suprafata frunzisului
    (build_hibiscus.py: pe raza tufei le inghite frunzisul si nu se vede una);
  - iarba = `blade()` cu grosime, arcuita (build_sugar_cane.py): un plan simplu
    dispare la backface culling cand il vezi din spate.

Culori din paleta, fara texturi de clasa — sub 2.3 m textura nu se citeste
(style_bible §4, aceeasi regula ca hibiscus/marker_post/scatter):
  - portocaliu = TILE_TERRACOTTA (23): RUST_METAL e maro-noroi, KERB_RED e
    rosu curat, accentele de masina (14-16) sunt interzise in decor;
  - alb = FOAM_WHITE (22); verde = TROPICAL_GREEN/CACTUS_GREEN;
  - smocul mic = DRY_VEGETATION, ca in referinta (galbui, pe jumatate uscat).

Buget: filler de presarat — tinta <=700 tris per piesa.
"""

import math
from mathutils import Vector


def foliage_mound(b, w, h, clumps, seed, slot_a=TROPICAL_GREEN,
                  slot_b=CACTUS_GREEN):
    """Movila de bulgari verzi, mai lata decat inalta (reteta hibiscus).

    Fata de reteta originala, bulgarii stau PE SOL (centrul la ~0.3 din
    propria marime), nu suspendati la o fractie din inaltimea tufei: prima
    rulare i-a lasat plutind, cu gauri de lumina dedesubt. Varful il da un
    bulgare central mai mare, coborat cat sa atinga si el pamantul vizual.
    """
    rnd = _lcg(seed)
    size0 = w * 0.62
    b.boulder((0.0, 0.0, h - size0 * 0.40),
              (size0, size0 * 0.94, size0 * 0.84), slot_a,
              seed=seed, segments=7, rings=4, deviation=0.15)
    for k in range(clumps):
        a = 2.0 * math.pi * k / clumps + rnd() * 0.5
        r = w * 0.30 * (0.70 + rnd() * 0.50)
        size = w * 0.46 * (0.85 + rnd() * 0.25)
        z = size * 0.30 + rnd() * h * 0.16
        b.boulder((math.cos(a) * r, math.sin(a) * r, z),
                  (size, size * 0.94, size * 0.80),
                  slot_b if k % 2 else slot_a,
                  seed=seed + k * 11, segments=7, rings=4, deviation=0.16)


def flower_heads(b, w, h, count, slot, head, seed):
    """Discuri turtite pe calota movilei, iesite din frunzis.

    Distributia are bias spre VARF (elev ~ rnd^0.55): florile cauta soarele,
    si de sus le vede si camera de joc. Distribuite uniform pe elevatie, prima
    rulare le-a insirat intr-un inel ecuatorial, ca niste nasturi pe burta.
    """
    rnd = _lcg(seed)
    for k in range(count):
        a = 2.0 * math.pi * k / count + rnd() * 0.7
        # pragul de jos tine capetele pe calota: la elevatie ~0 un cap cu raza
        # marita iese din frunzis la nivelul solului si pluteste langa tufa
        elev = 0.22 + 0.78 * rnd() ** 0.55
        r = w * 0.58 * math.cos(elev * math.pi * 0.5) * (0.88 + rnd() * 0.18)
        z = h * (0.42 + elev * 0.62)
        b.boulder((math.cos(a) * r, math.sin(a) * r, z),
                  (head, head, head * 0.46), slot,
                  seed=seed + k * 17, segments=5, rings=2, deviation=0.10)


def blades(b, w, h, count, seed, slots, spread=0.30, z0=0.0):
    """Smoc: lame care pleaca dintr-un disc central, urca si cad in arc.

    Latimea maxima e la mijlocul lamei, varful se inchide la 0 (muchie-cutit,
    nu capac care sclipeste — aceeasi decizie ca frunza de trestie).
    `z0` ridica baza lamelor: la tufa, lamele pornesc din coroana, altfel
    strabat frunzisul si dedesubt se vad ca niste bete.
    """
    rnd = _lcg(seed)
    for k in range(count):
        a = 2.0 * math.pi * k / count + rnd() * 0.9
        d = Vector((math.cos(a), math.sin(a), 0.0))
        base = d * (w * spread * math.sqrt(rnd())) + Vector((0, 0, z0))
        length = h * (0.68 + rnd() * 0.38)
        reach = w * 0.5 - base.xy.length       # cat mai are pana la marginea cotei
        lean = min(reach, length * (0.30 + rnd() * 0.32))
        path, widths = [], []
        for i in range(4):
            t = i / 3.0
            # urca aproape vertical, apoi varful cade in afara
            path.append(base + d * (lean * t ** 1.7)
                        + Vector((0, 0, length * math.sin(t * 1.35))))
            widths.append(0.0 if i == 3
                          else w * 0.075 * math.sin(math.pi * (0.18 + t * 0.55)))
        b.blade(path, widths, w * 0.016, slots[k % len(slots)], up=d.cross(Vector((0, 0, 1))))


AO_VEG = dict(samples=20, dist=1.4, gradient="vertical",
              low=0.46, high=1.0, power=0.7, floor=0.16)

clear_built("Veg_")
built = []


def make(name, fname, build_fn):
    b = Builder()
    build_fn(b)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.0, ao=AO_VEG)
    built.append((obj, fname))
    d = obj.dimensions
    print("%-18s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))


# Tufa tropicala: movila de bulgari + lame rasfirate care ies DIN coroana —
# ele dau silueta "zburlita" din referinta, altfel e o movila de hibiscus.
def tropical_shrub(b):
    foliage_mound(b, 2.15, 1.42, 9, seed=101)
    blades(b, 2.3, 0.80, 12, seed=113,
           slots=(TROPICAL_GREEN, CACTUS_GREEN), spread=0.30, z0=0.62)


# Flori: movila mai jos si mai plata decat tufa; capetele de floare mai mari
# la portocaliu (galbenele: ghem de petale) decat la alb (stelute rare).
def flowers_orange(b):
    foliage_mound(b, 1.26, 0.60, 7, seed=131)
    flower_heads(b, 1.26, 0.62, 16, TILE_TERRACOTTA, head=0.30, seed=137)


def flowers_white(b):
    foliage_mound(b, 1.24, 0.46, 7, seed=151)
    # capete putin mai mari si mai iesite decat formula comuna: FOAM_WHITE
    # inmultit cu AO-ul se stinge repede, iar sub 20 cm discul dispare de tot
    flower_heads(b, 1.32, 0.50, 13, FOAM_WHITE, head=0.24, seed=157)


def grass_large(b):
    blades(b, 1.8, 1.15, 22, seed=171, slots=(TROPICAL_GREEN, CACTUS_GREEN))


def grass_small(b):
    blades(b, 0.9, 0.58, 13, seed=191,
           slots=(DRY_VEGETATION, CACTUS_GREEN, DRY_VEGETATION), spread=0.36)


make("Veg_Tropical_Shrub", "plants/tropical_shrub.glb", tropical_shrub)
make("Veg_Flowers_Orange", "flowers/flowers_orange.glb", flowers_orange)
make("Veg_Flowers_White", "flowers/flowers_white.glb", flowers_white)
make("Veg_Grass_Tuft_Large", "plants/grass_tuft_large.glb", grass_large)
make("Veg_Grass_Tuft_Small", "plants/grass_tuft_small.glb", grass_small)

for obj, fname in built:
    obj.location = (0.0, 0.0, 0.0)
    print("GLB:  %s (%d B)" % export_glb([obj], fname))
print("BLEND: %s (%d B)" % save_blend([o for o, _ in built], "veg_set.blend"))

x = 0.0
for obj, _ in built:
    obj.location = (x, 0.0, 0.0)
    x += max(obj.dimensions.x, 1.5) * 1.4
