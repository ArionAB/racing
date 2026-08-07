"""rock_small/medium/large.glb — trei bolovani de sine statatori, dupa foaia
de referinta cu cele trei clase de marime:

  Rock_Small    1.5 x 1.5 x 0.9 m (vizibil)
  Rock_Medium   3.0 x 3.0 x 1.8 m
  Rock_Large    6.0 x 4.5 x 3.0 m

De ce fisiere SEPARATE, cand canyon_rocks.glb e o biblioteca: astea sunt piese
de asezat individual (una per apel), nu o familie trasa la sort de
_pick_from_glb. Un GLB per marime lasa instanta de gameplay sa refere exact
piesa dorita, fara conventie de nume in interiorul unui container.

De ce icosfera si nu `rock()`/`boulder()`: `rock()` construieste inele de la
baza in sus, deci raza scade monoton si silueta iese movila/capita, iar
`boulder()` (elipsoid lat-long) are poli — cu shading flat, polul ciupit se
citeste ca varf de ghinda. Ambele iteratii au aratat exact asa. Foaia de
referinta arata fatete triunghiulare mari, uniforme pe toata calota — aia e o
icosfera subdivizata O DATA (80 de fete, fara poli), cu vertecsii perturbati
determinist si scalata pe cote. Bolovanii au si BURTA: raza maxima deasupra
liniei solului, deci corpul inchis se INGROAPA partial — aceeasi regula ca la
molozul de mesa: "o piatra asezata pe nisip se vede ca asezata, una infipta se
vede ca desprinsa din stanca".

Ingroparea e copta in geometrie: baza vizuala e la z=0, iar ~18% din corp
coboara sub 0. Godot aseaza propul cu global_position direct pe sol si burta
iese natural peste linia terenului, fara nicio compensare la instantiere.
Cotele cerute sunt cele VIZIBILE — corpul se construieste mai inalt cu 1/0.82.

Shading FLAT (smooth_angle=None): referinta arata fatete dure, nu blob neted —
clasa "fatetat 30%" din style_bible §3. In joc materialul e inlocuit de clasa
triplanara de roca; sloturile de paleta raman sursa de adevar / fallback.
"""

# Gradientul vertical, nu sferic: pietrele astea NU se rostogolesc (pentru aia
# exista boulder_roller.glb), stau infipte — baza intunecata e corecta.
AO_BIG = dict(samples=24, dist=3.0, gradient="vertical",
              low=0.42, high=1.00, power=0.85, floor=0.12)
AO_SMALL = dict(samples=18, dist=1.4, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.14)

BURY = 0.18  # fractia din inaltimea corpului care intra sub z=0

# (nume, fisier, marime vizibila XYZ, deviation, ao, seed)
#
# Deviation scade cu marimea: pe 6 m aceeasi perturbatie relativa inseamna
# adancituri de jumatate de metru, si style_bible interzice zimtat/concav.
# Toate la subdiviziune 1 (80 de fete): pe 1.5 m fatetele au ~25 cm, pe 6 m
# ~1 m — exact scara din foaia de referinta. Fara bevel: fetele sunt deja
# triunghiuri late cu unghiuri mici intre ele, banda de bevel ar dubla
# geometria fara sa se vada.
ROCKS = [
    ("Rock_Small",  "rocks/rock_small.glb",  (1.5, 1.5, 0.9), 0.16, AO_SMALL, 419),
    ("Rock_Medium", "rocks/rock_medium.glb", (3.0, 3.0, 1.8), 0.13, AO_BIG, 433),
    ("Rock_Large",  "rocks/rock_large.glb",  (6.0, 4.5, 3.0), 0.11, AO_BIG, 449),
]

clear_built("Rock_")

built = []
for (name, fname, size, dev, ao, seed) in ROCKS:
    sx, sy, sz = size
    sz_full = sz / (1.0 - BURY)
    b = Builder()
    # subdivisions e in termeni bmesh: 1 = icosaedrul brut (20 de fete),
    # 2 = 80 de fete — scara de fatete din foaia de referinta
    res = bmesh.ops.create_icosphere(b.bm, subdivisions=2, radius=0.5)
    rand = _lcg(seed)
    # perturbatie radiala per vertex, deterministe din seed; icosfera nu are
    # poli, deci nu exista directie privilegiata care sa se ciupeasca
    for v in res["verts"]:
        v.co *= 1.0 + (rand() * 2.0 - 1.0) * dev
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz_full
    faces = b._tag(res["verts"], ROCK_LIGHT)
    # banda de jos mai inchisa: fallback-ul de atlas pastreaza senzatia de
    # umezeala/umbra la contactul cu solul (in joc: clasa triplanara de roca)
    b.retag(faces, ROCK_DARK, where=lambda c, n: c.z < -sz_full * 0.18)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.0, ao=ao, origin="base", smooth_angle=None)
    # baza vizuala la z=0: tot ce e sub linia asta e partea infipta in teren
    for v in obj.data.vertices:
        v.co.z -= sz_full * BURY
    built.append((obj, fname))
    print("%-12s %4.1f x %4.1f x %4.1f m vizibil | %4d tris | AO %.2f..%.2f"
          % (name, sx, sy, sz, stats["tris"], stats["ao_min"], stats["ao_max"]))

# Fiecare piatra in GLB-ul ei; sursa .blend le tine impreuna.
for obj, fname in built:
    obj.location = (0.0, 0.0, 0.0)
    print("GLB:   %s (%d B)" % export_glb([obj], fname))
print("BLEND: %s (%d B)" % save_blend([o for o, _ in built], "rock_set.blend"))

# Una langa alta in scena, ca sa se compare siluetele dintr-o privire.
x = 0.0
for obj, _ in built:
    obj.location = (x, 0.0, 0.0)
    x += max(obj.dimensions.x, 2.0) * 1.3
