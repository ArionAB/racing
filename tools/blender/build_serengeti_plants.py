"""Serengeti — KITUL DE SAVANA, vegetatia (plansa serengeti_assets_v1, randul 8).

  serengeti/plants/acacia_umbrella_{a,b,c}.glb  acacii-umbrela 7 / 8,5 / 10 m
  serengeti/plants/fever_tree.glb               acacia galbena 10 m (buza, Lerai)
  serengeti/plants/fig_tree.glb                 smochin de padure de ceata, 14 m
  serengeti/plants/euphorbia.glb                candelabru 4 m
  serengeti/plants/baobab.glb                   silueta de 22 m (150+ m)
  serengeti/plants/dead_tree.glb                copac uscat 6 m
  serengeti/plants/flamingo.glb                 flamingo in picioare, 1,2 m
  serengeti/plants/flamingo_wings.glb           flamingo cu aripile desfacute (decolare)

**Acacia-umbrela e o SILUETA, nu un copac.** Ce o face recognoscibila de la
40 m e raportul coroanei: plata, lata cat inaltimea, asezata pe un trunchi
subtire care se desparte in 3-4 brate abia sub coroana. Coroana e din
bulgari (`boulder`) turtiti la 0,35 din latime — un elipsoid rotund ar fi
un stejar, si atunci lumea e alta (brief §0.1: „un copac-umbrela" e unul
dintre cele patru lucruri pe care jucatorul le recunoaste in 3 secunde).

Plafonul de inaltime e DERIVAT, nu ales (brief §2.0): la 20 m de banda
camera vede pana la 12 m, deci coroanele de 7-10 m se vad intregi cand te
apropii. Baobabul de 22 m e doar silueta la 150+ m si nu are voie langa drum.

Umbra e identitatea: `cast_shadow` ramane pornit pe acacii in Godot, deci
coroana trebuie sa fie un volum INCHIS (bulgari), nu placi — o placa lasa
umbra unei linii.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_serengeti_plants.py
"""

import math
from mathutils import Matrix, Vector

AO_TREE = dict(samples=16, dist=6.0, gradient="vertical",
               low=0.52, high=1.00, power=0.85, floor=0.22)
AO_BIG = dict(samples=10, dist=14.0, gradient="vertical",
              low=0.50, high=1.00, power=0.8, floor=0.22)
AO_SMALL = dict(samples=20, dist=1.2, gradient="vertical",
                low=0.54, high=1.00, power=0.9, floor=0.24)

BARK = WOOD
BARK_DARK = LOG_DARK
BARK_YELLOW = SAND_LIGHT       # fever tree: scoarta galben-verde
OLIVE = CACTUS_GREEN           # frunzis de acacie (oliv prafuit)
GREEN = TROPICAL_GREEN         # frunzis dens (smochin)
DRY = DRY_VEGETATION
LICHEN = FOAM_WHITE
# Flamingo: slotul 31 e NEON_PINK in scripts/palette.gd (Chongqing), exact
# rozul de flamingo; brief §4 il numeste explicit. dio_lib nu-l defineste.
FLAMINGO_PINK = 31
BEAK = VOLCANIC_BLACK
LEG = ROCK_DARK


def _crown_lumps(b, cz, radius, thickness, lumps, seed, slots, squash=0.36):
    """Coroana plata: un inel de bulgari turtiti + unul central, toti la aceeasi
    cota — asa iese suprafata de sus PLATA, semnatura umbrelei."""
    rnd = _lcg(seed)
    for k in range(lumps):
        a = 2.0 * math.pi * k / lumps + rnd() * 0.5
        r = 0.0 if k == 0 else radius * (0.52 + rnd() * 0.30)
        size = radius * (0.95 if k == 0 else 0.72 + rnd() * 0.25)
        z = cz - (0.0 if k == 0 else rnd() * thickness * 0.35)
        slot = slots[k % len(slots)]
        b.boulder((math.cos(a) * r, math.sin(a) * r, z),
                  (size, size * 0.9, size * squash), slot,
                  seed=seed + k * 11, segments=7, rings=3, deviation=0.14)


def build_acacia(variant):
    """Trei inaltimi, aceeasi silueta. Bratele pleaca dintr-un singur punct la
    ~60% din inaltime si se desfac in coroana — cum se vede o acacie de la
    distanta: un V larg pe un bat."""
    b = Builder()
    H = (7.0, 8.5, 10.0)[variant]
    R = H * 0.62
    rnd = _lcg(101 + variant * 37)
    split_z = H * 0.58
    lean = (rnd() - 0.5) * 0.8
    b.taper_sweep([(0.0, 0.0, 0.0), (lean * 0.3, 0.0, split_z * 0.5),
                   (lean, 0.0, split_z)],
                  [0.30 + variant * 0.03, 0.24, 0.19], BARK_DARK, segments=7)
    arms = 3 + variant % 2
    for k in range(arms):
        a = 2.0 * math.pi * k / arms + rnd() * 0.6
        d = Vector((math.cos(a), math.sin(a), 0.0))
        tip = d * (R * 0.55) + Vector((lean, 0.0, H * 0.86))
        b.taper_sweep([Vector((lean, 0.0, split_z - 0.1)),
                       d * (R * 0.22) + Vector((lean, 0.0, split_z + H * 0.12)),
                       tip],
                      [0.17, 0.12, 0.07], BARK_DARK, segments=5)
    _crown_lumps(b, H * 0.90, R, H * 0.22, 7 + variant, 211 + variant * 17,
                 (OLIVE, OLIVE, GREEN, OLIVE, DRY))
    return b.to_object("Acacia_Umbrella_" + "ABC"[variant])


def build_fever_tree():
    """Acacia galbena (Vachellia xanthophloea): scoarta galben-verde, coroana mai
    rara si mai inalta decat umbrela. Traieste langa apa — buza craterului si
    padurea Lerai — deci trunchiul palid e ce o deosebeste de la volan."""
    b = Builder()
    H = 10.0
    b.taper_sweep([(0.0, 0.0, 0.0), (0.15, 0.0, H * 0.45), (0.35, 0.1, H * 0.7)],
                  [0.34, 0.24, 0.16], BARK_YELLOW, segments=7)
    rnd = _lcg(307)
    for k in range(4):
        a = 2.0 * math.pi * k / 4 + rnd() * 0.5
        d = Vector((math.cos(a), math.sin(a), 0.0))
        b.taper_sweep([Vector((0.35, 0.1, H * 0.66)),
                       d * 1.6 + Vector((0.35, 0.1, H * 0.82)),
                       d * 3.0 + Vector((0.35, 0.1, H * 0.94))],
                      [0.13, 0.09, 0.05], BARK_YELLOW, segments=5)
    _crown_lumps(b, H * 0.93, 4.2, 2.0, 6, 331, (OLIVE, GREEN, OLIVE), squash=0.42)
    return b.to_object("Fever_Tree")


def build_fig_tree():
    """Smochinul padurii de ceata (POI D): coroana DENSA si inalta, trunchi
    gros cu contraforti, licheni care atarna. E inversul acaciei — volum, nu
    silueta — fiindca pe D drumul trece PRIN padure, la 3-4 m de trunchiuri."""
    b = Builder()
    H = 14.0
    b.taper_sweep([(0.0, 0.0, 0.0), (0.0, 0.0, 2.2), (0.2, 0.0, H * 0.5)],
                  [0.95, 0.70, 0.45], BARK, segments=9)
    rnd = _lcg(409)
    for k in range(5):
        a = 2.0 * math.pi * k / 5 + rnd() * 0.3
        d = Vector((math.cos(a), math.sin(a), 0.0))
        b.taper_sweep([d * 0.9 + Vector((0, 0, 0.0)), d * 0.9 + Vector((0, 0, 0.2)),
                       d * 0.55 + Vector((0, 0, 1.4))],
                      [0.32, 0.30, 0.18], BARK, segments=5)
        tip = d * 3.2 + Vector((0.2, 0.0, H * 0.72))
        b.taper_sweep([Vector((0.2, 0.0, H * 0.46)), d * 1.4 + Vector((0.2, 0.0, H * 0.6)), tip],
                      [0.30, 0.20, 0.10], BARK, segments=6)
    # coroana: doua etaje de bulgari, jos mai lati
    for (z, r, n, seed) in ((H * 0.66, 5.2, 7, 421), (H * 0.86, 3.6, 5, 443)):
        rnd2 = _lcg(seed)
        for k in range(n):
            a = 2.0 * math.pi * k / n + rnd2() * 0.5
            rr = 0.0 if k == 0 else r * (0.55 + rnd2() * 0.3)
            size = r * (0.9 if k == 0 else 0.62 + rnd2() * 0.3)
            b.boulder((math.cos(a) * rr, math.sin(a) * rr, z - rnd2() * 0.8),
                      (size, size * 0.95, size * 0.62),
                      GREEN if k % 3 else OLIVE, seed=seed + k * 7,
                      segments=7, rings=4, deviation=0.16)
    # lichenii: fire care atarna de sub coroana (identitatea padurii de ceata)
    rnd3 = _lcg(457)
    for k in range(9):
        a = 2.0 * math.pi * k / 9 + rnd3() * 0.4
        r = 2.0 + rnd3() * 2.5
        top = Vector((math.cos(a) * r, math.sin(a) * r, H * 0.60 - rnd3() * 1.0))
        ln = 1.2 + rnd3() * 1.6
        b.taper_sweep([top, top + Vector((0.1, 0.0, -ln * 0.5)), top + Vector((0.0, 0.1, -ln))],
                      [0.10, 0.07, 0.02], LICHEN, segments=4)
    return b.to_object("Fig_Tree")


def build_euphorbia():
    """Candelabrul: trunchi scurt si 8 brate care urca in cot, ca un sfesnic.
    Aceeasi reteta ca bratul de saguaro (`sweep` cu dom), la scara si numar
    de africa de est."""
    b = Builder()
    b.taper_sweep([(0, 0, 0.0), (0, 0, 0.9), (0, 0, 1.6)], [0.22, 0.20, 0.17],
                  BARK_DARK, segments=6)
    rnd = _lcg(503)
    for k in range(8):
        a = 2.0 * math.pi * k / 8 + rnd() * 0.3
        d = Vector((math.cos(a), math.sin(a), 0.0))
        r = 0.55 + rnd() * 0.45
        h = 2.6 + rnd() * 1.3
        b.sweep([Vector((0, 0, 1.45)), d * r * 0.7 + Vector((0, 0, 1.75)),
                 d * r + Vector((0, 0, 2.2)), d * r + Vector((0, 0, h))],
                0.11 + rnd() * 0.03, OLIVE, segments=5)
    b.sweep([Vector((0, 0, 1.5)), Vector((0, 0, 3.9))], 0.13, OLIVE, segments=5)
    return b.to_object("Euphorbia")


def build_baobab():
    """Baobabul: silueta de fundal (150+ m), deci doar profilul conteaza — un
    butoi care se ingusteaza brusc si cateva brate scurte, ca niste radacini
    in aer. Fara coroana: in sezonul scurt de ploi abia inmugureste."""
    b = Builder()
    H = 22.0
    b.taper_sweep([(0, 0, 0.0), (0, 0, 3.0), (0, 0, 9.0), (0, 0, 13.0), (0, 0, 15.0)],
                  [3.3, 3.1, 2.6, 1.9, 1.4], LARCH_RUST, segments=9)
    rnd = _lcg(601)
    for k in range(7):
        a = 2.0 * math.pi * k / 7 + rnd() * 0.4
        d = Vector((math.cos(a), math.sin(a), 0.0))
        ln = 3.5 + rnd() * 2.8
        b.taper_sweep([Vector((0, 0, 14.4)), d * (ln * 0.5) + Vector((0, 0, 16.5 + rnd())),
                       d * ln + Vector((0, 0, H - 4.0 + rnd() * 3.5))],
                      [0.9, 0.55, 0.12], LARCH_RUST, segments=5)
        # radacinile de aer de la capat: doua ramurele
        for j in range(2):
            aa = a + (j - 0.5) * 0.7
            dd = Vector((math.cos(aa), math.sin(aa), 0.0))
            base = d * ln + Vector((0, 0, H - 4.0))
            b.taper_sweep([base, base + dd * 1.2 + Vector((0, 0, 1.2))],
                          [0.14, 0.03], LARCH_RUST, segments=4)
    return b.to_object("Baobab")


def build_dead_tree():
    """Copac uscat de 6 m, pe malul raului: trunchi si trei crengi goale."""
    b = Builder()
    b.taper_sweep([(0, 0, 0), (0.1, 0, 2.2), (0.35, 0.1, 4.2)], [0.30, 0.22, 0.12],
                  BARK_DARK, segments=6)
    rnd = _lcg(701)
    for k, (z, ln) in enumerate(((2.0, 2.4), (3.1, 2.9), (4.0, 2.1))):
        a = 2.0 * math.pi * k / 3 + rnd() * 0.5
        d = Vector((math.cos(a), math.sin(a), 0.0))
        base = Vector((0.1 + z * 0.06, 0.0, z))
        b.taper_sweep([base, base + d * (ln * 0.5) + Vector((0, 0, ln * 0.45)),
                       base + d * ln + Vector((0, 0, ln * 0.9))],
                      [0.13, 0.08, 0.02], BARK_DARK, segments=4)
        b.taper_sweep([base + d * (ln * 0.5) + Vector((0, 0, ln * 0.45)),
                       base + d * (ln * 0.55) + Vector((0.4, -0.3, ln * 0.95))],
                      [0.06, 0.01], BARK_DARK, segments=4)
    return b.to_object("Dead_Tree")


def _flamingo(b, wings):
    """Flamingo de 1,2 m: corp-para pe doua picioare-bat, gat in S, cioc negru.
    Roz pe tot corpul; ce il face flamingo e S-ul gatului si picioarele lungi,
    deci alea primesc segmentele."""
    # picioare
    for sx in (-0.06, 0.06):
        b.beam((sx, 0.0, 0.0), (sx * 1.3, 0.02, 0.62), 0.022, LEG)
    # corp
    b.boulder((0.0, 0.0, 0.78), (0.30, 0.52, 0.30), FLAMINGO_PINK, seed=17,
              segments=7, rings=4, deviation=0.06)
    # gat in S, capul in fata (+Y)
    b.taper_sweep([Vector((0, 0.22, 0.82)), Vector((0, 0.32, 1.02)),
                   Vector((0, 0.24, 1.14)), Vector((0, 0.34, 1.22))],
                  [0.06, 0.05, 0.045, 0.05], FLAMINGO_PINK, segments=5)
    b.boulder((0.0, 0.36, 1.23), (0.10, 0.13, 0.09), FLAMINGO_PINK, seed=19,
              segments=6, rings=3, deviation=0.05)
    b.taper_sweep([Vector((0, 0.42, 1.21)), Vector((0, 0.50, 1.14))], [0.028, 0.008],
                  BEAK, segments=4)
    # coada: cateva pene ridicate
    b.box((0.0, -0.28, 0.86), (0.14, 0.12, 0.05), VOLCANIC_BLACK,
          rotation=Matrix.Rotation(math.radians(20.0), 3, "X"))
    if wings:
        for sx in (-1.0, 1.0):
            b.blade([Vector((sx * 0.12, 0.0, 0.86)), Vector((sx * 0.45, 0.05, 1.05)),
                     Vector((sx * 0.80, 0.02, 1.12))],
                    [0.18, 0.22, 0.10], 0.02, FLAMINGO_PINK, up=(0, 0, 1))
            b.box((sx * 0.62, 0.0, 1.10), (0.28, 0.10, 0.02), VOLCANIC_BLACK,
                  rotation=Matrix.Rotation(math.radians(sx * -14.0), 3, "Y"))
    else:
        for sx in (-1.0, 1.0):
            b.box((sx * 0.13, -0.04, 0.82), (0.05, 0.36, 0.16), FLAMINGO_PINK,
                  rotation=Matrix.Rotation(math.radians(sx * 8.0), 3, "Y"))


def build_flamingo(wings):
    b = Builder()
    _flamingo(b, wings)
    return b.to_object("Flamingo_Wings" if wings else "Flamingo")


clear_built()
results = []


def emit(obj, path, ao, origin="base", bevel=0.03):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "serengeti/" + path)
    results.append((path, st["tris"], sz / 1024.0))


for v in range(3):
    emit(build_acacia(v), "plants/acacia_umbrella_%s.glb" % "abc"[v], AO_TREE, bevel=0.03)
emit(build_fever_tree(), "plants/fever_tree.glb", AO_TREE, bevel=0.03)
emit(build_fig_tree(), "plants/fig_tree.glb", AO_TREE, bevel=0.04)
emit(build_euphorbia(), "plants/euphorbia.glb", AO_SMALL, bevel=0.02)
emit(build_baobab(), "plants/baobab.glb", AO_BIG, bevel=0.08)
emit(build_dead_tree(), "plants/dead_tree.glb", AO_SMALL, bevel=0.02)
emit(build_flamingo(False), "plants/flamingo.glb", AO_SMALL, bevel=0.006)
emit(build_flamingo(True), "plants/flamingo_wings.glb", AO_SMALL, bevel=0.006)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL plante: %d tris" % sum(t for _, t, _ in results))
