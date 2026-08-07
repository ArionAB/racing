"""canyon_rocks.glb — biblioteca de stanci de canion, in trei clase de marime.

De ce exista, cand aveam deja rock_cluster.glb: aveam CINCI siluete pe toata
pista (doua mici, doua medii, una mare), si toate cinci sunt elipsoizi netezi.
Plus mesa procedurala din track_decor, care era literalmente trei cutii
suprapuse pe materialul de paleta — fara textura de roca, fara moloz, cu
muchii perfect drepte. De la camera de joc, tot ce e stanca in desert citea la
fel: o movila.

Foile de referinta ale canionului cer altceva, si diferenta e o singura
proprietate: **treapta**. Lespezi suprapuse cu buza vizibila intre ele, fiecare
mai ingusta decat cea de dedesubt, cu moloz la baza. Buza se citeste de la
100 m, cand granulatia texturii s-a topit in mipmap — fara ea, o stanca de 8 m
si una de 1 m arata identic, doar la scari diferite.

  Canyon_L1..L4   6-10 m   banda din spate, siluete dominante
  Canyon_M1..M6   2-5 m    banda de mijloc
  Canyon_S1..S8   0.5-2 m  banda lipita de drum si sateliti

Toate primesc `Palette.rock_material()` la instantiere — clasa de roca
triplanara in spatiul lumii, aceeasi cu falezele, deci straturile curg continuu
de la o stanca la faleza din spatele ei (style_bible §4).

Buget: astea se REPETA. Costul real nu e in fisier, e in cate instante intra pe
pista — de aia clasa S, cea mai numeroasa, are cele mai putine laturi si bevel
zero. Vezi nota de la BEVEL mai jos.
"""

import math

# `strata_slots` da benzi de valoare BLOCATE DE GEOMETRIE, la scara de treapta.
# Se pastreaza desi clasa de roca e triplanara si nu citeste UV-uri: e sursa de
# adevar a formei, si fallback-ul daca stancile se intorc vreodata pe atlas.
STRATA = (ROCK_LIGHT, ROCK_DARK, ROCK_LIGHT, SAND_SHADOW)

# Bevel-ul scade cu marimea, si nu din zgarcenie: style_bible §3 cere 0.15
# pentru stanci, dar aia e cifra pentru bolovani mari. Pe o piatra de 80 cm o
# banda de 15 cm e o cincime din obiect — arata umflata SI dubleaza
# triunghiurile, fiindca bevel-ul adauga geometrie la fiecare muchie, iar o
# stiva in trepte are de trei ori mai multe muchii decat un elipsoid.
BEVEL_L = 0.15
BEVEL_M = 0.07
BEVEL_S = 0.0

# `taper` pe CLASA, si e cea mai importanta cifra din tabel dupa dimensiune.
#
# Mesa vrea pereti aproape verticali (0.06): asa se citesc treptele. Sub ~2 m
# aceeasi valoare da o cutie — o treapta joasa, verticala, cu 5 laturi si fara
# bevel chiar E o cutie, si asa a si aratat in prima rulare: pietrele de langa
# drum pareau lazi de carton aruncate pe nisip. Clasa mica are nevoie de corp
# rotunjit, nu de trepte.
TAPER_L = 0.07
TAPER_M = 0.13
TAPER_S = 0.30

# (nume, marime XYZ, trepte, laturi, lip, lean, moloz, bevel, taper, seed)
#
# Marimile sunt cele din foaia de referinta. Proportiile difera intentionat
# intre variante: cateva sunt late si joase (mesa), cateva inalte si inguste
# (turn erodat) — daca toate au acelasi raport, varietatea de silueta dispare
# chiar daca dimensiunile difera.
ROCKS = [
    # --- LARGE 6-10 m: se vad de departe, deci cele mai multe trepte ---------
    ("Canyon_L1", (7.6, 6.8, 7.2), 4, 8, 0.17, 0.10, 9, BEVEL_L, TAPER_L, 11),
    # lata si joasa: mesa clasica, capac mare si plat
    ("Canyon_L2", (10.4, 8.6, 6.2), 3, 8, 0.20, 0.08, 10, BEVEL_L, TAPER_L, 29),
    # Cea mai INALTA, dar nu si cea mai subtire. Prima versiune era 5.4 x 5.0 x
    # 9.8 cu lip 0.12 si a iesit un cos de fabrica: la raportul ala treptele nu
    # se mai citesc, iar silueta devine un con. Latita si cu retragere mai mare,
    # ramane cel mai vertical accent din familie fara sa iasa din geologie.
    ("Canyon_L3", (6.8, 6.0, 8.8), 4, 8, 0.19, 0.13, 9, BEVEL_L, TAPER_L, 47),
    ("Canyon_L4", (8.8, 7.4, 8.4), 4, 8, 0.16, 0.16, 10, BEVEL_L, TAPER_L, 67),

    # --- MEDIUM 2-5 m -------------------------------------------------------
    ("Canyon_M1", (4.2, 3.6, 3.8), 3, 7, 0.18, 0.11, 6, BEVEL_M, TAPER_M, 83),
    ("Canyon_M2", (3.0, 2.8, 4.6), 4, 6, 0.14, 0.15, 5, BEVEL_M, TAPER_M, 101),
    ("Canyon_M3", (5.0, 4.4, 2.6), 2, 7, 0.22, 0.09, 7, BEVEL_M, TAPER_M, 119),
    ("Canyon_M4", (3.6, 3.2, 3.2), 3, 6, 0.17, 0.13, 5, BEVEL_M, TAPER_M, 139),
    ("Canyon_M5", (4.6, 3.8, 4.8), 3, 7, 0.15, 0.12, 6, BEVEL_M, TAPER_M, 157),
    ("Canyon_M6", (2.6, 2.4, 2.2), 2, 6, 0.20, 0.10, 4, BEVEL_M, TAPER_M, 173),

    # --- SMALL 0.5-2 m: cele mai numeroase, deci cele mai ieftine -----------
    # Sase laturi, nu patru-cinci: cu taper mare, a sasea latura e diferenta
    # dintre bolovan si zar. Costa 12-16 triunghiuri pe piatra.
    ("Canyon_S1", (1.8, 1.5, 1.4), 2, 6, 0.20, 0.12, 4, BEVEL_S, TAPER_S, 191),
    ("Canyon_S2", (1.2, 1.1, 1.8), 2, 6, 0.16, 0.14, 3, BEVEL_S, TAPER_S, 211),
    ("Canyon_S3", (2.0, 1.7, 0.9), 1, 6, 0.20, 0.00, 5, BEVEL_S, 0.22, 233),
    ("Canyon_S4", (1.4, 1.2, 1.1), 2, 6, 0.18, 0.10, 3, BEVEL_S, TAPER_S, 251),
    ("Canyon_S5", (0.9, 0.8, 0.7), 1, 6, 0.20, 0.00, 3, BEVEL_S, 0.38, 269),
    ("Canyon_S6", (1.6, 1.4, 1.9), 2, 6, 0.15, 0.16, 4, BEVEL_S, TAPER_S, 293),
    ("Canyon_S7", (1.1, 0.9, 0.6), 1, 6, 0.20, 0.00, 3, BEVEL_S, 0.38, 311),
    ("Canyon_S8", (0.7, 0.6, 0.5), 1, 5, 0.20, 0.00, 2, BEVEL_S, 0.40, 331),
]

AO_BIG = dict(samples=24, dist=3.0, gradient="vertical",
              low=0.42, high=1.00, power=0.85, floor=0.12)
AO_SMALL = dict(samples=18, dist=1.4, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.14)

clear_built("Canyon_")

built = []
per_class = {"L": [0, 0], "M": [0, 0], "S": [0, 0]}  # [instante, tris]
for (name, size, tiers, seg, lip, lean, rubble, bevel, taper, seed) in ROCKS:
    b = Builder()
    b.mesa((0.0, 0.0, 0.0), size, ROCK_LIGHT, seed=seed, tiers=tiers,
           segments=seg, lip=lip, lean=lean, rubble=rubble,
           rubble_slot=ROCK_DARK, strata_slots=STRATA, taper=taper)
    obj = b.to_object(name)
    cls = name[7]
    stats = finish(obj, bevel=bevel, bevel_angle=30.0,
                   ao=AO_BIG if cls in "LM" else AO_SMALL, origin="base")
    per_class[cls][0] += 1
    per_class[cls][1] += stats["tris"]
    built.append(obj)
    print("%-11s %5.1f x %4.1f x %4.1f m | %d trepte | %4d tris | AO %.2f..%.2f"
          % (name, size[0], size[1], size[2], tiers, stats["tris"],
             stats["ao_min"], stats["ao_max"]))

print()
# Garda de fante: o stiva de lespezi e exact geometria in care o cota gresita
# lasa aer intre trepte, iar prin aer se vede in interiorul stancii.
report_slits(built, "canyon_rocks")
print()
for cls in "LMS":
    n, t = per_class[cls]
    print("  clasa %s: %2d variante, %5d tris (medie %d)" % (cls, n, t, t / n))
print("TOTAL: %d tris in biblioteca" % sum(v[1] for v in per_class.values()))

# Exportate una langa alta, ca sa se vada toate in Blender; instanta din joc
# anuleaza offsetul (track_decor._pick_from_glb).
x = 0.0
for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(built, "rocks/canyon_rocks.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "canyon_rocks.blend"))
for o in built:
    o.location = (x, 0.0, 0.0)
    x += max(o.dimensions.x, 2.0) * 1.3
