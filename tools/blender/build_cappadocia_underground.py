"""Cappadocia — SUBTERAN: kitul de sali + usa de piatra (plansa, grupurile 2 si 3).

  cappadocia/structures/hall_column.glb          coloana sapata, 5.2 m
  cappadocia/structures/hall_arch.glb            arcada de sala, 8 m deschidere
  cappadocia/structures/hall_ceiling_module.glb  lespede de tavan, 12x12 m
  cappadocia/structures/hall_alcove.glb          alcova cu oale
  cappadocia/structures/church_arch.glb          arcada de biserica rupestra, cu fresce
  cappadocia/props/torch.glb                     torta de perete
  cappadocia/structures/millstone_door.glb       usa de piatra de moara, 3 m
  cappadocia/structures/millstone_slot.glb       lacasul din perete

**Sala e KIT, nu o piesa unica** (brief §5.2 o lasa explicit deschisa: "pot fi
kit de bucati"). Motivul e cota de tavan: brief §2.0 cere >= 15 m in sali,
fiindca `ChaseCamera` sta la 10 m si `_unclip` o impinge afara din pereti. O
sala turnata ca un singur GLB ar fixa si planul, si inaltimea, si forma — iar
cota de tavan e exact lucrul care se va ajusta dupa prima captura `--driver`.
Cu un kit, tavanul urca schimband o cota de instantiere, nu remodeland piesa.

Toate piesele sunt pe `ROCK_DARK` + AO puternic: brief §4 spune ca sub pamant
lumina vine din emisivele tortelor si din puturile de lumina, deci contrastul
il face AO-ul copt, nu soarele. `low=0.26` pe AO e mult mai jos decat pe
piesele de suprafata — asta e ce face sala sa para sapata, nu construita.

**Usa de piatra de moara** e singura piesa care se ROSTOGOLESTE, deci:
`origin="center"` + `bake_ao(gradient="spherical")` — regula din dio_lib
(un gradient vertical i-ar coace o umbra la baza care ajunge in varf dupa o
jumatate de rotatie). Aceeasi alegere ca la `boulder_roller`.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_underground.py
"""

import math
from mathutils import Matrix, Vector

# Sub pamant: AO adanc, fiindca el face toata modelarea de lumina (brief §4).
AO_CAVE = dict(samples=28, dist=6.0, gradient="vertical",
               low=0.26, high=1.00, power=0.95, floor=0.07)
AO_CEIL = dict(samples=20, dist=8.0, gradient="vertical",
               low=0.34, high=0.92, power=1.0, floor=0.10)
AO_TORCH = dict(samples=24, dist=1.6, gradient="vertical",
                low=0.44, high=1.00, power=0.9, floor=0.16)
# Piatra de moara: sferic, fiindca se rostogoleste (vezi docstring).
AO_MILL = dict(samples=30, dist=2.2, gradient="spherical",
               low=0.42, high=1.00, power=0.85, floor=0.16)

CAVE = ROCK_DARK
CAVE_LIT = SAND_SHADOW     # fetele care prind lumina de torta / de put
TUFF = CORAL_SAND
TUFF_MID = SAND_MID
STONE = ROCK_LIGHT         # piatra de moara: alta valoare decat peretele,
                           # ca sa se vada CA se misca
FRESCO_RED = TILE_TERRACOTTA
FRESCO_RUST = LARCH_RUST
FRESCO_DARK = VOLCANIC_BLACK
FLAME = LAVA_ORANGE
IRON = RUST
POT = RUST                 # lut ars (slotul se numeste RUST in dio_lib,
                           # rust_metal in palette.gd — acelasi index 10)


def chisel_band(b, faces, seed=0):
    """Urmele de dalta: variatie de VALOARE pe fetele existente, zero triunghiuri.

    Peretii reali din Derinkuyu sunt plini de urme de tarnacop, in siruri
    oblice. Nu le putem modela (ar fi zeci de mii de triunghiuri pe sala), dar
    putem sparge suprafata plata alternand doua sloturi apropiate ca valoare —
    la lumina de torta, exact asta se vede.
    """
    rand = _lcg(seed + 77)
    picked = [f for f in faces if rand() < 0.34]
    b.retag(picked, CAVE_LIT)


def build_hall_column():
    """Coloana sapata: NU e turnata, e ce a RAMAS din stanca dupa ce s-a sapat
    in jur. De aia se ingroasa la ambele capete (nu doar la baza, ca o coloana
    clasica): sus se contopeste cu tavanul, jos cu podeaua.
    """
    b = Builder()
    H = 5.2
    # fusul, cu profil de clepsidra usoara
    prof = [(0.86, 0.0), (0.66, 0.55), (0.58, 1.6), (0.55, 2.6),
            (0.58, 3.6), (0.68, 4.55), (0.92, H)]
    faces = b.revolve(prof, CAVE, segments=9)
    chisel_band(b, faces, seed=11)
    # soclul si capitelul: prisme scurte, muchii tesite
    b.box((0.0, 0.0, 0.17), (2.15, 2.15, 0.34), CAVE_LIT)
    b.box((0.0, 0.0, H - 0.19), (2.05, 2.05, 0.38), CAVE_LIT)
    b.box((0.0, 0.0, H + 0.12), (2.35, 2.35, 0.24), CAVE)
    return b.to_object("Hall_Column")


def build_hall_arch():
    """Arcada de sala: doi pilastri + bolta, 8 m deschidere libera.

    8 m fiindca drumul din subteran are 6-8 m (brief §2 POI F). Bolta e
    facuta din 9 lespezi in evantai — un arc "adevarat" ar fi cerut un
    `revolve` partial, dar lespezile citesc mai bine: se vad imbinarile, deci
    se vede ca e sapat de mana.
    """
    b = Builder()
    SPAN, PIER_H, PIER_W, D = 8.0, 4.6, 1.5, 2.4
    for sx in (-1.0, 1.0):
        x = sx * (SPAN * 0.5 + PIER_W * 0.5)
        f = b.box((x, 0.0, PIER_H * 0.5), (PIER_W, D, PIER_H), CAVE)
        chisel_band(b, f, seed=int(sx * 31))
        b.box((x, 0.0, PIER_H + 0.16), (PIER_W + 0.35, D + 0.35, 0.32), CAVE_LIT)

    # bolta: lespezi radiale intre cei doi pilastri
    R = SPAN * 0.5 + PIER_W * 0.5
    n = 9
    for k in range(n):
        a = math.pi * (k + 0.5) / n
        cz = PIER_H + 0.32
        px, pz = R * math.cos(a), R * math.sin(a) * 0.62
        rot = Matrix.Rotation(math.atan2(pz, px) - math.pi / 2, 3, "Y")
        b.box((px * 0.92, 0.0, cz + pz * 0.92), (1.35, D, 0.95),
              CAVE if k % 2 else CAVE_LIT, rotation=rot)
    return b.to_object("Hall_Arch")


def build_hall_ceiling_module():
    """Lespede de tavan 12x12 m, cu relief pe fata de JOS.

    E singura piesa din kit al carei detaliu e pe dedesubt: de la 10 m
    inaltime de camera, tavanul se vede "venind spre tine" (brief §2.0), deci
    fata utila e cea inferioara. Fata de sus e o placa plata — nimeni n-o vede.

    Relieful sunt boltile scobite ("valturi") intre nervuri, plus cateva
    stalactite scurte. Costa putin fiindca boltile sunt cutii coborate, nu
    scobituri reale.
    """
    b = Builder()
    S, T = 12.0, 0.9
    top = b.box((0.0, 0.0, T * 0.5), (S, S, T), CAVE)
    b.retag(top, CAVE_LIT, where="up")
    # nervurile: doua benzi incrucisate, mai groase decat placa
    for axis in (0, 1):
        for off in (-S * 0.25, S * 0.25):
            size = (S, 1.1, 0.55) if axis else (1.1, S, 0.55)
            c = (0.0, off, -0.25) if axis else (off, 0.0, -0.25)
            b.box(c, size, CAVE_LIT)
    # boltile dintre nervuri: patru cutii coborate putin, cu slot mai inchis
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * S * 0.25, sy * S * 0.25, -0.12), (S * 0.42, S * 0.42,
                                                          0.28), CAVE)
    # stalactite scurte: ancore vizuale care spun "tavanul e aproape"
    rand = _lcg(1201)
    for k in range(7):
        x = (rand() - 0.5) * S * 0.82
        y = (rand() - 0.5) * S * 0.82
        ln = 0.5 + rand() * 1.1
        b.taper_sweep([(x, y, -0.25), (x + (rand() - 0.5) * 0.3,
                                       y + (rand() - 0.5) * 0.3, -0.25 - ln)],
                      [0.24, 0.0], CAVE, segments=6, cap_start=True)
    return b.to_object("Hall_Ceiling_Module")


def build_hall_alcove():
    """Alcova cu oale: nisa sapata in perete, cu doua ulcioare.

    Piesa de umplut peretele intre coloane. Nisa e reala (o cutie de perete
    din care lipseste mijlocul), fiindca la 6-8 m de drum se vede ca e adanca.
    """
    b = Builder()
    W, H, D = 3.2, 3.0, 1.5
    NW, NH, ND = 1.9, 2.0, 1.0
    # cadrul de perete, spart in trei ca sa lase nisa
    side = (W - NW) * 0.5
    for sx in (-1.0, 1.0):
        b.box((sx * (NW * 0.5 + side * 0.5), 0.0, H * 0.5), (side, D, H), CAVE)
    b.box((0.0, 0.0, NH + (H - NH) * 0.5), (NW, D, H - NH), CAVE)
    # fundul nisei si arcul ei
    b.box((0.0, -D * 0.5 + (D - ND) * 0.5, NH * 0.5), (NW, D - ND, NH), CAVE_LIT)
    for i, (w, dz) in enumerate(((NW * 0.92, NH - 0.18), (NW * 0.72, NH + 0.12))):
        b.box((0.0, 0.05, dz), (w, ND * 0.9, 0.32), CAVE if i else CAVE_LIT)
    # polita + doua ulcioare
    b.box((0.0, -0.10, 0.92), (NW * 0.88, ND * 0.82, 0.14), CAVE_LIT)
    for (px, sc) in ((-0.42, 1.0), (0.40, 0.82)):
        b.revolve([(0.16 * sc, 0.0), (0.30 * sc, 0.22 * sc),
                   (0.26 * sc, 0.50 * sc), (0.13 * sc, 0.66 * sc),
                   (0.17 * sc, 0.74 * sc)], POT, segments=8,
                  origin=(px, -0.10, 0.99))
    return b.to_object("Hall_Alcove")


def build_church_arch():
    """Arcada de biserica rupestra: acelasi schelet ca `hall_arch`, dar cu
    ogiva si fresce abstracte pe intrados.

    Frescele sunt trei sloturi de culoare in benzi si medalioane — abstract
    deliberat: brief §5.2 zice "fresce abstracte", si un chip pictat din
    triunghiuri la scara de jucarie iese grotesc. Benzile insa citesc imediat
    ca "aici e ceva pictat, e altfel decat restul pesterii".
    """
    b = Builder()
    SPAN, PIER_H, PIER_W, D = 6.4, 4.2, 1.35, 2.2
    for sx in (-1.0, 1.0):
        x = sx * (SPAN * 0.5 + PIER_W * 0.5)
        f = b.box((x, 0.0, PIER_H * 0.5), (PIER_W, D, PIER_H), CAVE)
        chisel_band(b, f, seed=int(sx * 47))
        # banda pictata pe pilastru
        b.box((x, D * 0.5 + 0.04, PIER_H * 0.62), (PIER_W * 0.92, 0.10, 0.55),
              FRESCO_RED)
        b.box((x, D * 0.5 + 0.04, PIER_H * 0.40), (PIER_W * 0.92, 0.10, 0.26),
              FRESCO_RUST)
        b.box((x, 0.0, PIER_H + 0.15), (PIER_W + 0.30, D + 0.30, 0.30), CAVE_LIT)

    # ogiva: doua arce de cerc care se intalnesc intr-un varf
    R = SPAN * 0.5 + PIER_W * 0.5
    n = 7
    for sx in (-1.0, 1.0):
        for k in range(n):
            t = (k + 0.5) / n
            a = math.radians(90.0 * t)               # de la orizontal la vertical
            px = sx * R * math.cos(a)
            pz = PIER_H + 0.30 + R * 0.80 * math.sin(a)
            rot = Matrix.Rotation(-sx * a, 3, "Y")
            slot = FRESCO_RED if k == n - 2 else (CAVE if k % 2 else CAVE_LIT)
            b.box((px * 0.90, 0.0, pz * 0.98), (1.15, D, 0.85), slot,
                  rotation=rot)
    # cheia de bolta + medalionul pictat
    apex_z = PIER_H + 0.30 + R * 0.80
    b.box((0.0, 0.0, apex_z * 0.99), (1.5, D, 0.9), CAVE_LIT)
    b.cylinder((0.0, D * 0.5 + 0.06, apex_z * 0.82), 0.52, 0.12, FRESCO_RED,
               segments=9, axis="Y")
    b.cylinder((0.0, D * 0.5 + 0.10, apex_z * 0.82), 0.28, 0.12, FRESCO_DARK,
               segments=8, axis="Y")
    # crucea de sub medalion
    b.box((0.0, D * 0.5 + 0.08, apex_z * 0.62), (0.16, 0.10, 0.72), FRESCO_DARK)
    b.box((0.0, D * 0.5 + 0.08, apex_z * 0.66), (0.54, 0.10, 0.16), FRESCO_DARK)
    return b.to_object("Church_Arch")


def build_torch():
    """Torta de perete: consola de fier + cos + flacara.

    Flacara e geometrie pe `LAVA_ORANGE`, care la integrare primeste materialul
    emisiv al lavei (brief §4: "reuse shader de lava"). Deci forma trebuie sa
    fie corecta si STINSA — o limba de foc modelata din trei pene, nu o sfera
    portocalie care fara emisiv arata ca o portocala infipta in perete.
    """
    b = Builder()
    # consola prinsa in perete
    b.box((0.0, -0.06, 0.55), (0.34, 0.12, 1.10), IRON)
    b.beam((0.0, 0.0, 0.95), (0.0, 0.42, 1.22), 0.09, IRON)
    b.beam((0.0, 0.0, 0.55), (0.0, 0.40, 1.14), 0.07, IRON)
    # cosul: coroana de nuiele de fier
    b.frustum((0.0, 0.44, 1.34), 0.17, 0.27, 0.30, IRON, segments=8)
    for k in range(6):
        a = 2.0 * math.pi * k / 6.0
        b.beam((0.24 * math.cos(a), 0.44 + 0.24 * math.sin(a), 1.20),
               (0.29 * math.cos(a), 0.44 + 0.29 * math.sin(a), 1.52), 0.045, IRON)
    # flacara: trei pene de inaltimi diferite (silueta de foc, nu bila)
    for (dx, dy, h, r) in ((0.0, 0.0, 0.86, 0.19), (-0.10, 0.06, 0.58, 0.13),
                           (0.09, -0.05, 0.46, 0.11)):
        b.taper_sweep([(dx, 0.44 + dy, 1.46), (dx * 1.4, 0.44 + dy * 1.4,
                                               1.46 + h * 0.55),
                       (dx * 0.6, 0.44 + dy * 0.6, 1.46 + h)],
                      [r, r * 0.72, 0.0], FLAME, segments=6)
    return b.to_object("Torch")


def build_millstone_door():
    """Usa de piatra de moara: disc de 3 m diametru x 0.6 m grosime.

    Se ROSTOGOLESTE (SlidingHazard cu rotatie pe axa, brief §3), deci:
      - `origin="center"` — altfel se invarte in jurul unei origini de la baza
        si "sare" vizibil la fiecare rotatie;
      - AO sferic — un gradient vertical i-ar coace o umbra care ajunge sus
        dupa o jumatate de tura (regula din `bake_ao`).
    Discul e construit in planul XZ (fata pe Y), fiindca asa se rostogoleste
    pe axa Y: la fel ca roata morii din `build_windmill`.

    Gaura din mijloc e reala (asa arata piatra de moara si asa o recunosti),
    dar mica: 0.42 m raza. Prin ea NU se trece.
    """
    b = Builder()
    R, T, R_HOLE = 1.5, 0.60, 0.42
    segments = 16
    rand = _lcg(6607)
    # inelul: quad-uri intre gaura si margine, pe ambele fete + cant
    rings = {}
    for name, r in (("in", R_HOLE), ("out", R)):
        for side, y in (("f", T * 0.5), ("b", -T * 0.5)):
            ring = []
            for k in range(segments):
                a = 2.0 * math.pi * k / segments
                w = 1.0 + (rand() - 0.5) * 0.03 if name == "out" else 1.0
                ring.append(b.bm.verts.new((r * w * math.cos(a), y,
                                            r * w * math.sin(a))))
            rings[(name, side)] = ring
    faces_face, faces_rim, faces_hole = [], [], []
    for side, flip in (("f", False), ("b", True)):
        i_r, o_r = rings[("in", side)], rings[("out", side)]
        for k in range(segments):
            j = (k + 1) % segments
            quad = (i_r[k], o_r[k], o_r[j], i_r[j])
            faces_face.append(b.bm.faces.new(quad if flip else tuple(reversed(quad))))
    for k in range(segments):     # cantul exterior (pe el se rostogoleste)
        j = (k + 1) % segments
        faces_rim.append(b.bm.faces.new((rings[("out", "b")][k], rings[("out", "b")][j],
                                         rings[("out", "f")][j], rings[("out", "f")][k])))
    for k in range(segments):     # peretele gaurii
        j = (k + 1) % segments
        faces_hole.append(b.bm.faces.new((rings[("in", "f")][k], rings[("in", "f")][j],
                                          rings[("in", "b")][j], rings[("in", "b")][k])))
    for f in faces_face:
        f[b.slot] = STONE
    for f in faces_rim:
        f[b.slot] = ROCK_DARK
    for f in faces_hole:
        f[b.slot] = ROCK_DARK

    # relieful fetei: patru raze in cruce + inelul de margine. Ele sunt ce face
    # rotatia LIZIBILA — un disc neted care se rostogoleste pare ca sta pe loc.
    for side in (1.0, -1.0):
        for k in range(4):
            a = math.pi * k / 4.0 + math.pi / 8.0
            b.box((0.0, side * (T * 0.5 + 0.04), 0.0),
                  (R * 1.62, 0.10, 0.22), ROCK_DARK,
                  rotation=Matrix.Rotation(a, 3, "Y"))
    return b.to_object("Millstone_Door")


def build_millstone_slot():
    """Lacasul din perete in care sta piatra cand culoarul e DESCHIS.

    Fara el, piatra ar aparea din perete ca dintr-un buzunar invizibil. Piesa
    e un bloc de perete cu un jgheab vertical de 3.2 m latime si o sina de
    piatra la baza pe care se rostogoleste — sina e ce explica mecanica dintr-o
    privire.
    """
    b = Builder()
    W, H, D = 6.0, 5.4, 2.2
    GW, GH, GD = 3.25, 3.6, 0.95
    side = (W - GW) * 0.5
    for sx in (-1.0, 1.0):
        f = b.box((sx * (GW * 0.5 + side * 0.5), 0.0, H * 0.5), (side, D, H), CAVE)
        chisel_band(b, f, seed=int(sx * 71))
    b.box((0.0, 0.0, GH + (H - GH) * 0.5), (GW, D, H - GH), CAVE)
    # fundul jgheabului
    b.box((0.0, -D * 0.5 + (D - GD) * 0.5, GH * 0.5), (GW, D - GD, GH), CAVE_LIT)
    # sina de la baza: canal in podea, iese in fata din lacas
    b.box((0.0, D * 0.35, 0.12), (GW + 0.6, D * 1.7, 0.24), CAVE_LIT)
    for sx in (-1.0, 1.0):
        b.box((sx * (GW * 0.5 + 0.28), D * 0.35, 0.26), (0.30, D * 1.7, 0.52),
              ROCK_LIGHT)
    # buiandrugul iesit, ca sa se vada ca piatra intra SUB ceva
    b.box((0.0, D * 0.5 + 0.22, GH + 0.30), (GW + 1.2, 0.55, 0.70), CAVE_LIT)
    return b.to_object("Millstone_Slot")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.04):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


emit(build_hall_column(), "structures/hall_column.glb", AO_CAVE)
emit(build_hall_arch(), "structures/hall_arch.glb", AO_CAVE, bevel=0.05)
emit(build_hall_ceiling_module(), "structures/hall_ceiling_module.glb", AO_CEIL,
     bevel=0.05)
emit(build_hall_alcove(), "structures/hall_alcove.glb", AO_CAVE)
emit(build_church_arch(), "structures/church_arch.glb", AO_CAVE, bevel=0.045)
emit(build_torch(), "props/torch.glb", AO_TORCH, bevel=0.018)
emit(build_millstone_door(), "structures/millstone_door.glb", AO_MILL,
     origin="center", bevel=0.05)
emit(build_millstone_slot(), "structures/millstone_slot.glb", AO_CAVE)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL subteran: %d tris" % sum(t for _, t, _ in results))
