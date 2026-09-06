"""Serengeti — OAMENII SI FUNDALUL (plansa serengeti_assets_v1, randurile 7, 10, 11).

  serengeti/buildings/maasai_boma.glb       4 colibe + gard de spini + un Maasai cu sulita
  serengeti/props/ankole_horns.glb          coarne Ankole (se pun pe props/cow.glb)
  serengeti/props/safari_tent.glb           cort de panza cu prelata
  serengeti/props/land_rover.glb            Land Rover verde de safari, cu acoperis ridicat
  serengeti/props/campfire.glb              cerc de pietre + flacara (emisiv LAVA_ORANGE)
  serengeti/props/safari_balloon_landed.glb balon aterizat: panza intinsa + cos (decor)
  serengeti/rocks/lengai.glb                Ol Doinyo Lengai, silueta la 290-300 m
  serengeti/rocks/crater_far_wall.glb       peretele opus al craterului, la 200 m

**Rosul Maasai e CAR_RED, prin exceptie declarata** (ca baloanele din
Cappadocia, brief §4): atlasul n-are alt rosu saturat, iar shuka e unul din
cele trei accente saturate ale pistei. `verify_serengeti.sh` il trece cu
`--allow-car-slots=Maasai_Boma`. La fel panza balonului (CAR_YELLOW).

**Cotele de fundal sunt legate** (memoria `efecte-de-fundal-cote-legate`):
inel < fog_end (300) < FAR_PLANE (380). Lengai e ULTIMUL lucru vizibil;
peretele opus sta la 200 m, in ceata dar cu silueta.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_serengeti_camp.py
"""

import math
from mathutils import Matrix, Vector

AO_PROP = dict(samples=26, dist=2.2, gradient="vertical",
               low=0.46, high=1.00, power=0.9, floor=0.17)
AO_HOUSE = dict(samples=24, dist=6.0, gradient="vertical",
                low=0.40, high=1.00, power=0.88, floor=0.13)
AO_FAR = dict(samples=8, dist=25.0, gradient="vertical",
              low=0.52, high=1.00, power=0.75, floor=0.24)

MUD = SAND_SHADOW
THATCH = DRY_VEGETATION
THORN = LOG_DARK
SHUKA = CAR_RED
SKIN = ROCK_DARK
HORN = SAND_LIGHT
CANVAS = CORAL_SAND
CANVAS_SH = SAND_MID
ROVER = CACTUS_GREEN
ROVER_DK = ROCK_DARK
STONE = ROCK_LIGHT
FLAME = LAVA_ORANGE
ENVELOPE = CAR_YELLOW
ENVELOPE_B = TROPICAL_GREEN
WICKER = WOOD


def _hut(b, cx, cy, r, h, seed):
    """Coliba Maasai (inkajijik): cilindru scund de lut cu acoperis conic de
    paie, usa joasa spre centrul boma-ului."""
    b.cylinder((cx, cy, h * 0.5), r, h, MUD, segments=8)
    b.revolve([(r * 1.15, h - 0.05), (r * 0.6, h + r * 0.55), (0.0, h + r * 0.95)], THATCH,
              segments=8, origin=(cx, cy, 0.0))
    a = math.atan2(-cy, -cx)
    b.box((cx + math.cos(a) * r * 0.95, cy + math.sin(a) * r * 0.95, 0.55), (0.25, 0.7, 1.1),
          ROCK_DARK, rotation=Matrix.Rotation(a, 3, "Z"))


def build_boma():
    b = Builder()
    R = 7.5
    for k in range(4):
        a = 2.0 * math.pi * k / 4 + 0.4
        _hut(b, math.cos(a) * 4.2, math.sin(a) * 4.2, 1.9 + 0.2 * (k % 2), 1.7, 71 + k)
    # gardul de spini: inel de tepi incrucisati
    rnd = _lcg(83)
    n = 40
    for k in range(n):
        a = 2.0 * math.pi * k / n
        if 0.25 < (k / n) < 0.32:
            continue  # poarta
        cx, cy = math.cos(a) * R, math.sin(a) * R
        for j in range(3):
            aa = a + (rnd() - 0.5) * 0.5
            tip = Vector((cx + math.cos(aa) * (rnd() - 0.5) * 1.2, cy + math.sin(aa) * (rnd() - 0.5) * 1.2,
                          0.9 + rnd() * 0.7))
            base = Vector((cx + (rnd() - 0.5) * 0.6, cy + (rnd() - 0.5) * 0.6, 0.0))
            b.taper_sweep([base, tip], [0.06, 0.01], THORN, segments=4)
        b.box((cx, cy, 0.45), (0.9, 0.9, 0.9), THORN, rotation=Matrix.Rotation(a + rnd(), 3, "Z"))
    # Maasai-ul: la poarta, cu sulita
    px, py = math.cos(2.0 * math.pi * 0.285) * (R + 1.2), math.sin(2.0 * math.pi * 0.285) * (R + 1.2)
    b.cylinder((px, py, 0.45), 0.12, 0.9, SKIN, segments=6)
    b.revolve([(0.30, 0.85), (0.34, 1.35), (0.22, 1.62)], SHUKA, segments=7, origin=(px, py, 0.0))
    b.boulder((px, py, 1.78), (0.24, 0.24, 0.26), SKIN, seed=91, segments=6, rings=3, deviation=0.04)
    b.beam((px + 0.35, py, 0.0), (px + 0.35, py, 2.3), 0.03, THORN)
    b.box((px + 0.35, py, 2.35), (0.06, 0.02, 0.28), HORN)
    return b.to_object("Maasai_Boma")


def build_ankole_horns():
    """Coarne de 1,2 m deschidere pe un soclu mic, cu originea la baza — se
    parenteaza pe capul vacii (props/cow.glb) in Godot."""
    b = Builder()
    b.box((0.0, 0.0, 0.06), (0.30, 0.14, 0.12), SAND_SHADOW)
    for sx in (-1.0, 1.0):
        b.taper_sweep([Vector((sx * 0.08, 0.0, 0.1)), Vector((sx * 0.30, -0.02, 0.32)),
                       Vector((sx * 0.52, 0.02, 0.62)), Vector((sx * 0.58, 0.08, 0.90))],
                      [0.07, 0.06, 0.04, 0.01], HORN, segments=6)
    return b.to_object("Ankole_Horns")


def build_tent():
    b = Builder()
    W, D, H = 3.6, 4.4, 2.4
    # peretii verticali + acoperis in doua ape (prisma pe Y)
    b.box((0.0, 0.0, 0.7), (W, D, 1.4), CANVAS)
    b.prism([(-W * 0.5 - 0.05, 1.35), (0.0, H), (W * 0.5 + 0.05, 1.35)], D + 0.3, CANVAS_SH,
            center=(0.0, 0.0, 0.0))
    # prelata (fly sheet) mai sus, pe stalpi
    b.prism([(-W * 0.5 - 0.7, 1.9), (0.0, H + 0.45), (W * 0.5 + 0.7, 1.9)], D + 1.2, CANVAS,
            center=(0.0, 0.0, 0.0))
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.beam((sx * (W * 0.5 + 0.7), sy * (D * 0.5 + 0.6), 0.0),
                   (sx * (W * 0.5 + 0.7), sy * (D * 0.5 + 0.6), 1.9), 0.04, LOG_DARK)
    b.box((0.0, D * 0.5 + 0.02, 0.9), (1.0, 0.06, 1.7), SAND_SHADOW)
    return b.to_object("Safari_Tent")


def build_land_rover():
    """Land Rover de safari: cutie + cabina + acoperis ridicat, roti mari. E
    decor, nu masina din garaj — proportii de jucarie, dar sloturi de decor."""
    b = Builder()
    L, W = 4.2, 2.0
    b.box((0.0, 0.0, 0.85), (W, L, 0.7), ROVER)
    b.box((0.0, 0.3, 1.5), (W * 0.96, L * 0.62, 0.65), ROVER)
    b.box((0.0, 0.3, 1.9), (W * 0.9, L * 0.55, 0.16), ROVER_DK)   # acoperisul ridicat
    b.box((0.0, 0.3, 2.05), (W * 0.8, L * 0.45, 0.14), CANVAS)
    b.box((0.0, L * 0.5 - 0.35, 0.95), (W * 0.9, 0.7, 0.5), ROVER_DK)  # capota
    for sx in (-1.0, 1.0):
        for y in (1.35, -1.35):
            b.cylinder((sx * (W * 0.5 + 0.05), y, 0.42), 0.42, 0.32, ROVER_DK, segments=8, axis="X")
    b.box((0.0, -L * 0.5 - 0.15, 1.0), (0.55, 0.3, 0.55), ROVER_DK)  # roata de rezerva
    for sx in (-0.55, 0.55):
        b.box((sx, L * 0.5 + 0.02, 0.85), (0.22, 0.05, 0.22), FOAM_WHITE)  # faruri
    return b.to_object("Land_Rover")


def build_campfire():
    b = Builder()
    rnd = _lcg(131)
    for k in range(9):
        a = 2.0 * math.pi * k / 9
        b.boulder((math.cos(a) * 0.62, math.sin(a) * 0.62, 0.12), (0.26, 0.22, 0.2), STONE,
                  seed=140 + k, segments=6, rings=3, deviation=0.1)
    for k in range(3):
        a = k * 1.05
        b.beam((math.cos(a) * 0.35, math.sin(a) * 0.35, 0.05), (-math.cos(a) * 0.35, -math.sin(a) * 0.35, 0.18),
               0.07, LOG_DARK)
    b.revolve([(0.28, 0.12), (0.18, 0.45), (0.06, 0.72), (0.0, 0.85)], FLAME, segments=6)
    return b.to_object("Campfire")


def build_balloon_landed():
    """Balon de safari aterizat: panza dezumflata intinsa pe pamant (bulgare
    foarte turtit, 12 x 8 m) cu dungi, cosul de rachita rasturnat langa ea."""
    b = Builder()
    b.boulder((0.0, 0.0, 0.55), (12.0, 8.0, 1.2), ENVELOPE, seed=151, segments=9, rings=4,
              deviation=0.12)
    for k in range(3):
        b.boulder((-3.5 + k * 3.5, 0.0, 0.62), (2.2, 8.4, 1.25), ENVELOPE_B, seed=160 + k,
                  segments=7, rings=3, deviation=0.1)
    b.taper_sweep([Vector((6.0, 0.0, 0.3)), Vector((8.5, 0.5, 0.2))], [0.5, 0.15], ENVELOPE, segments=6)
    b.box((9.8, 1.2, 0.7), (1.5, 1.5, 1.4), WICKER, rotation=Matrix.Rotation(math.radians(20.0), 3, "Y"))
    return b.to_object("Safari_Balloon_Landed")


def build_lengai():
    """Ol Doinyo Lengai: con abrupt (35°) de 180 m cu varful alb de natrocarbonatit.
    Silueta pura (brief §5.4), 24 de segmente pentru un contur fara zimti la
    290 m (aritmetica din build_cappadocia_horizon)."""
    b = Builder()
    H = 180.0
    faces = b.revolve([(150.0, 0.0), (95.0, H * 0.35), (48.0, H * 0.72), (18.0, H * 0.94), (0.0, H)],
                      MARBLE_GREY, segments=24)
    b.retag(faces, FOAM_WHITE, where=lambda c, n: c.z > H * 0.74)
    b.retag(faces, SAND_SHADOW, where=lambda c, n: c.z < H * 0.30)
    return b.to_object("Lengai")


def build_far_wall():
    """Peretele opus al craterului: arc de 200 m de trepte de granit cu padure
    ca bulgari pe creasta. Silueta la 200 m — trepte late, fara detaliu."""
    b = Builder()
    rnd = _lcg(171)
    n = 9
    for k in range(n):
        a = math.radians(-50.0 + 100.0 * k / (n - 1))
        x, y = math.sin(a) * 120.0, -math.cos(a) * 120.0 + 120.0
        h = 38.0 + rnd() * 10.0
        b.mesa((x, y, 0.0), (26.0, 24.0, h), ROCK_LIGHT, seed=180 + k, tiers=3, segments=7,
               lip=0.1, lean=0.05, rubble=0, strata_slots=(ROCK_LIGHT, MARBLE_GREY, ROCK_DARK))
        for j in range(3):
            b.boulder((x + (rnd() - 0.5) * 16.0, y + (rnd() - 0.5) * 10.0, h + 2.0),
                      (9.0, 8.0, 5.0), TROPICAL_GREEN if j % 2 else CACTUS_GREEN,
                      seed=200 + k * 3 + j, segments=6, rings=3, deviation=0.12)
    return b.to_object("Crater_Far_Wall")


clear_built()
results = []


def emit(obj, path, ao, origin="base", bevel=0.03):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "serengeti/" + path)
    results.append((path, st["tris"], sz / 1024.0))


emit(build_boma(), "buildings/maasai_boma.glb", AO_HOUSE, bevel=0.03)
emit(build_ankole_horns(), "props/ankole_horns.glb", AO_PROP, bevel=0.008)
emit(build_tent(), "props/safari_tent.glb", AO_PROP, bevel=0.02)
emit(build_land_rover(), "props/land_rover.glb", AO_PROP, bevel=0.03)
emit(build_campfire(), "props/campfire.glb", AO_PROP, bevel=0.01)
emit(build_balloon_landed(), "props/safari_balloon_landed.glb", AO_PROP, bevel=0.04)
emit(build_lengai(), "rocks/lengai.glb", AO_FAR, origin="base_axis", bevel=0.5)
emit(build_far_wall(), "rocks/crater_far_wall.glb", AO_FAR, origin="base_axis", bevel=0.3)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL oameni+fundal: %d tris" % sum(t for _, t, _ in results))
