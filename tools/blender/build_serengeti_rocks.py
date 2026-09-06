"""Serengeti — GRANIT SI PAMANT (plansa serengeti_assets_v1, randurile 5, 6, 9).

  serengeti/rocks/kopje_camp.glb          kopje-ul de start, 14 m, cu platou pentru leu
  serengeti/rocks/lion_kopje.glb          leul culcat (piesa separata: capul e os in Godot)
  serengeti/rocks/kopje_kicker.glb        kopje de 25 m cu fata-rampa de 8 m (sare raul)
  serengeti/rocks/crater_gap.glb          spartura Lerai: doua fete de granit, 40 m, 12 m intre ele
  serengeti/rocks/kopje_boulder_{a,b,c}.glb  bolovani de granit 2 / 4 / 6 m
  serengeti/rocks/termite_mound_{a,b}.glb    termitiere 1,5 / 3 m
  serengeti/rocks/carcass_vultures.glb    hoit cu trei vulturi PE PAMANT (frustum: in cer nu se vad)

**Kopje-ul de start are 14 m fiindca asa cere aritmetica, nu plansa.** Pe
plansa arata de ~6 m; brief §2 POI A: leul intra in cadru de la 43 m
(10 + 0,093·d = 14), adica exact pe cei 60 m dintre spartura si linie. La 6 m
s-ar vedea de langa el si n-ar mai fi recompensa turului.

**Rampa kicker-ului are varfuri PARTAJATE** (memoria
`suprafete-cu-goluri-si-praguri` + lectia hornului cazut din Cappadocia):
e o singura pana, nu placi — orice prag de peste 0,3 m pe o suprafata pe
care se conduce e un zid.

**Spartura e o piesa COMPUSA** (`--origin=assembly`): doua mase de granit
cu drumul intre ele, originea pe axa drumului (Y in Blender = -Z in Godot),
la baza. Latimea libera de 12 m e contract cu Track14 (drum de 7 m + umeri).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_serengeti_rocks.py
"""

import math
from mathutils import Matrix, Vector

AO_ROCK = dict(samples=24, dist=5.0, gradient="vertical",
               low=0.42, high=1.00, power=0.88, floor=0.14)
AO_BIG = dict(samples=14, dist=12.0, gradient="vertical",
              low=0.46, high=1.00, power=0.85, floor=0.16)
AO_SMALL = dict(samples=20, dist=1.5, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.20)

GRANITE = ROCK_LIGHT
GRANITE_SH = ROCK_DARK
GRANITE_PALE = MARBLE_GREY
STRATA = (ROCK_LIGHT, MARBLE_GREY, ROCK_LIGHT, ROCK_DARK)
LATERITE = TILE_TERRACOTTA
LATERITE_DK = LARCH_RUST
DRY = DRY_VEGETATION
BONE = FOAM_WHITE
VULTURE = LOG_DARK
LION = SAND_LIGHT
MANE = LARCH_RUST


def _boulder_pile(b, seed, count, spread, size_lo, size_hi, z_base=0.0, flat_top=False):
    rnd = _lcg(seed)
    for k in range(count):
        a = 2.0 * math.pi * k / count + rnd() * 0.9
        r = spread * (0.15 + rnd() * 0.85)
        s = size_lo + (size_hi - size_lo) * rnd()
        b.rock((math.cos(a) * r, math.sin(a) * r, z_base),
               (s, s * (0.8 + rnd() * 0.4), s * (0.55 + rnd() * 0.35)), GRANITE,
               seed=seed + k * 13, segments=7, rings=4, taper=0.35,
               flat_top=flat_top, strata_slots=STRATA)


def build_kopje_camp():
    """Gramada de granit de 14 m cu un platou in varf. Trei etaje de bolovani,
    tot mai mici; cel din varf e taiat plat (`flat_top`) — polita leului."""
    b = Builder()
    _boulder_pile(b, 811, 7, 6.0, 5.0, 7.5, 0.0)
    _boulder_pile(b, 823, 5, 3.6, 4.0, 6.0, 4.6)
    b.rock((0.4, -0.3, 9.2), (7.0, 6.2, 4.9), GRANITE, seed=857, segments=8, rings=4,
           taper=0.30, flat_top=True, strata_slots=STRATA)
    # tufe in crapaturi
    rnd = _lcg(877)
    for k in range(6):
        a = rnd() * 6.3
        r = 4.5 + rnd() * 2.5
        b.boulder((math.cos(a) * r, math.sin(a) * r, 1.2 + rnd() * 5.0),
                  (1.1, 1.0, 0.7), DRY, seed=900 + k, segments=6, rings=3, deviation=0.1)
    return b.to_object("Kopje_Camp")


def build_lion():
    """Leul culcat, 2,4 m bot-coada: corp, labe intinse in fata, cap cu coama.
    Capul e o INSULA separata (bulgare) ca in Godot sa poata fi intors dupa
    lider — brief §3 „look_at pe un os de cap"; fara schelet aici, Godot ia
    mesh-ul de cap dupa nume daca e nevoie de un nod separat mai tarziu."""
    b = Builder()
    b.boulder((0.0, -0.2, 0.55), (0.95, 1.7, 0.8), LION, seed=31, segments=8, rings=4,
              deviation=0.06)
    for sx in (-0.28, 0.28):
        b.taper_sweep([Vector((sx, 0.35, 0.28)), Vector((sx, 1.05, 0.2))], [0.16, 0.13],
                      LION, segments=5)
    b.boulder((0.0, 0.72, 0.98), (0.62, 0.62, 0.58), LION, seed=37, segments=7, rings=4,
              deviation=0.05)
    # coama: inel de bulgari in jurul capului
    rnd = _lcg(41)
    for k in range(7):
        a = 2.0 * math.pi * k / 7
        b.boulder((math.cos(a) * 0.36, 0.55 + (0.1 if k % 2 else 0.0), 0.98 + math.sin(a) * 0.32),
                  (0.34, 0.30, 0.34), MANE, seed=50 + k, segments=6, rings=3, deviation=0.1)
    b.taper_sweep([Vector((0.0, 1.02, 0.95)), Vector((0.0, 1.16, 0.90))], [0.10, 0.05],
                  ROCK_DARK, segments=4)
    b.taper_sweep([Vector((0.0, -1.0, 0.55)), Vector((0.3, -1.5, 0.35)), Vector((0.5, -1.7, 0.4))],
                  [0.06, 0.04, 0.07], LION, segments=4)
    return b.to_object("Lion_Kopje")


def build_kopje_kicker():
    """25 m de granit, cu fata dinspre drum taiata ca rampa: pana de 8 m
    lungime, 6 m lata, 2,8 m inaltime (panta ~19°), restul bolovani."""
    b = Builder()
    L, W, H = 8.0, 6.0, 2.8
    # rampa: prisma in planul YZ extrudata pe X (fata spre +Y = spre drum)
    outline = [(0.0, 0.0), (L, 0.0), (L, H), (0.0, 0.0)]
    # prism ia conturul in XZ si extrudeaza pe Y: construim pe X si rotim
    b.prism([(0.0, 0.0), (0.0, H), (-L, 0.0)], W, GRANITE, center=(0.0, W * 0.5, 0.0))
    _ = outline
    # masa de granit din spatele rampei si pe laturi
    rnd = _lcg(911)
    for k in range(9):
        x = -4.0 - rnd() * 9.0
        y = (rnd() - 0.5) * 11.0
        s = 4.0 + rnd() * 4.5
        b.rock((x, y, 0.0), (s, s * 0.85, s * (0.55 + rnd() * 0.3)), GRANITE, seed=930 + k,
               segments=7, rings=4, taper=0.3, strata_slots=STRATA)
    for k in range(4):
        y = -8.0 + k * 5.3
        b.rock((1.5 + rnd() * 1.5, y, 0.0), (3.0, 2.6, 1.6), GRANITE, seed=960 + k,
               segments=6, rings=3, taper=0.35, strata_slots=STRATA)
    return b.to_object("Kopje_Kicker")


def build_crater_gap():
    """Doua fete de granit de 40 m, cu 12 m liber intre ele; drumul trece pe Y.
    Fiecare fata e un sir de `mesa`-uri (trepte) cu iarba pe creasta."""
    b = Builder()
    rnd = _lcg(1201)
    for sx in (-1.0, 1.0):
        for k in range(6):
            y = -17.5 + k * 7.0 + (rnd() - 0.5) * 2.0
            depth = 8.0 + rnd() * 4.0
            h = 11.0 + rnd() * 4.0
            cx = sx * (6.0 + depth * 0.5)
            # `rock` cu varf plat si taper mic = perete de granit cu fatete
            # late; `mesa` (trepte) iesea un sir de butoaie hexagonale.
            b.rock((cx, y, 0.0), (depth, 9.5, h), GRANITE, seed=1220 + k + int(sx * 10),
                   segments=8, rings=5, taper=0.18, flat_top=True, strata_slots=STRATA)
            # iarba pe capacul REAL (flat_top reteaza varful sub `h`)
            top = Builder.flat_top_z(0.0, h)
            b.boulder((cx + (rnd() - 0.5) * 2.0, y + (rnd() - 0.5) * 3.0, top - 0.2),
                      (4.0, 4.5, 1.6), DRY, seed=1260 + k, segments=6, rings=3, deviation=0.12)
            # bolovani cazuti la picior, pe partea drumului
            b.rock((sx * (5.2 + rnd() * 0.8), y + (rnd() - 0.5) * 4.0, 0.0), (1.6, 1.4, 1.0),
                   GRANITE_SH, seed=1300 + k, segments=6, rings=3, taper=0.4)
    return b.to_object("Crater_Gap")


def build_boulder(variant):
    b = Builder()
    s = (2.0, 4.0, 6.0)[variant]
    b.rock((0.0, 0.0, 0.0), (s, s * 0.85, s * 0.72), GRANITE, seed=1301 + variant * 7,
           segments=8, rings=4, taper=0.4, strata_slots=STRATA)
    return b.to_object("Kopje_Boulder_" + "ABC"[variant])


def build_termite_mound(variant):
    """Termitiera: turn de pamant rosu cu creste — revolve cu profil noduros,
    plus 2-3 turnulete lipite."""
    b = Builder()
    H = (1.5, 3.0)[variant]
    rnd = _lcg(1401 + variant)
    prof = []
    for i in range(7):
        t = i / 6.0
        r = (0.55 * H) * (1.0 - t) ** 0.7 * (0.85 + rnd() * 0.3) + 0.03
        prof.append((r, H * t))
    faces = b.revolve(prof, LATERITE, segments=7)
    b.retag(faces, LATERITE_DK, where=lambda c, n: c.z < H * 0.25)
    for k in range(2 + variant):
        a = 2.0 * math.pi * k / (2 + variant) + 0.6
        r = 0.32 * H
        h = H * (0.45 + rnd() * 0.3)
        b.revolve([(0.22 * H * 0.5, 0.0), (0.16 * H * 0.5, h * 0.6), (0.0, h)], LATERITE,
                  segments=6, origin=(math.cos(a) * r, math.sin(a) * r, 0.0))
    return b.to_object("Termite_Mound_" + "AB"[variant])


def build_carcass_vultures():
    """Hoit + trei vulturi: cusca toracica din arce de os pe un pat de pamant,
    pasarile stau PE el (decor, brief §8: vulturii nu zboara, nu s-ar vedea)."""
    b = Builder()
    b.boulder((0.0, 0.0, 0.12), (3.2, 1.6, 0.35), SAND_SHADOW, seed=1501, segments=7,
              rings=3, deviation=0.1)
    b.beam((-1.2, 0.0, 0.2), (1.2, 0.0, 0.25), 0.09, BONE)
    for k in range(6):
        x = -0.9 + k * 0.36
        pts = [Vector((x, 0.0, 0.2))]
        for j in range(1, 5):
            t = j / 4.0
            pts.append(Vector((x, 0.62 * math.sin(t * math.pi), 0.2 + 0.7 * math.sin(t * math.pi * 0.5))))
        b.sweep(pts, 0.035, BONE, segments=4, dome_end=False)
    b.boulder((1.55, 0.1, 0.25), (0.6, 0.4, 0.35), BONE, seed=1511, segments=6, rings=3,
              deviation=0.08)
    for k, (x, y, rot) in enumerate(((-0.9, 0.5, 30.0), (0.4, -0.55, -120.0), (1.1, 0.6, 80.0))):
        rm = Matrix.Rotation(math.radians(rot), 3, "Z")
        # vultur: corp negru, gat golas roz, cioc
        b.boulder((x, y, 0.62), (0.42, 0.70, 0.40), VULTURE, seed=1520 + k, segments=6,
                  rings=3, deviation=0.06)
        head = Vector((x, y, 0.62)) + rm @ Vector((0.0, 0.42, 0.22))
        b.taper_sweep([Vector((x, y, 0.75)), head], [0.06, 0.05], TILE_TERRACOTTA, segments=4)
        b.boulder(tuple(head), (0.14, 0.16, 0.13), VULTURE, seed=1530 + k, segments=5, rings=3,
                  deviation=0.05)
        b.taper_sweep([head + rm @ Vector((0, 0.07, 0)), head + rm @ Vector((0, 0.17, -0.03))],
                      [0.03, 0.008], SAND_LIGHT, segments=4)
        for sx in (-0.1, 0.1):
            b.beam(tuple(Vector((x, y, 0.42)) + rm @ Vector((sx, 0, 0))),
                   tuple(Vector((x, y, 0.42)) + rm @ Vector((sx * 1.4, 0.05, -0.2))), 0.02, SAND_LIGHT)
    return b.to_object("Carcass_Vultures")


clear_built()
results = []


def emit(obj, path, ao, origin="base", bevel=0.05):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "serengeti/" + path)
    results.append((path, st["tris"], sz / 1024.0))


emit(build_kopje_camp(), "rocks/kopje_camp.glb", AO_BIG, bevel=0.08)
emit(build_lion(), "rocks/lion_kopje.glb", AO_SMALL, bevel=0.015)
emit(build_kopje_kicker(), "rocks/kopje_kicker.glb", AO_BIG, origin="base_axis", bevel=0.06)
emit(build_crater_gap(), "rocks/crater_gap.glb", AO_BIG, origin="base_axis", bevel=0.08)
for v in range(3):
    emit(build_boulder(v), "rocks/kopje_boulder_%s.glb" % "abc"[v], AO_ROCK, bevel=0.05)
for v in range(2):
    emit(build_termite_mound(v), "rocks/termite_mound_%s.glb" % "ab"[v], AO_SMALL, bevel=0.02)
emit(build_carcass_vultures(), "rocks/carcass_vultures.glb", AO_SMALL, bevel=0.012)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL granit+pamant: %d tris" % sum(t for _, t, _ in results))
