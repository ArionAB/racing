"""village_house.glb — EXPERIMENT: casa de sat de la marginea drumului (Okinawa).

Tinta: imaginea de referinta ROADSIDE / VILLAGE_HOUSE (4.0m) — casa cu
tencuiala deschisa, acoperis de olane in doua ape cu coame albe, grinzi de
lemn, zid scund de piatra si o limba de nisip la baza.

Ce REPRODUCE pipeline-ul nostru din referinta: forma, schema de culori
(sloturile existente: TILE_TERRACOTTA, CONCRETE, WOOD, SAND_LIGHT),
AO copt, variatia per element (pietre individuale in zid, randuri de olane,
coame). Ce NU poate reproduce: murdaria si gradientele pictate de mana din
referinta — aia e munca de textura, nu de geometrie (vezi discutia din
upgrade-ul grafic, val 4).

Buget: hero, o instanta pe pista -> 1000-5000 tris (style_bible §3).
"""

import math
import bpy

HOUSE_W = 4.0    # latimea corpului (referinta: 4.0 m)
HOUSE_D = 3.2
WALL_H = 2.1
ROOF_H = 1.5
ROOF_OVER = 0.65   # streasina dincolo de pereti


def stone_ring(b, seed):
    """Zidul scund de piatra: pietre INDIVIDUALE, nu un box continuu.

    Fiecare piatra are dimensiunea si asezarea ei — exact ce vinde 'fiecare
    piatra e citibila' din referinta, la nivel de geometrie.
    """
    state = seed

    def rand():
        nonlocal state
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        return state / 0x7FFFFFFF

    rx, ry = 3.6, 3.0          # jumatati de dreptunghi al zidului
    gap_half = 1.1             # gol la intrare, pe fata (-Y)
    per = []
    # Parametrizare pe perimetru, DEASA: pietrele trebuie sa se atinga —
    # cu spatiere mare, zidul citea ca niste cuburi imprastiate pe nisip.
    steps = 46
    for i in range(steps):
        t = i / steps
        # ocolim dreptunghiul
        p = t * 4.0
        if p < 1.0:
            x, y = -rx + p * 2 * rx, -ry
        elif p < 2.0:
            x, y = rx, -ry + (p - 1.0) * 2 * ry
        elif p < 3.0:
            x, y = rx - (p - 2.0) * 2 * rx, ry
        else:
            x, y = -rx, ry - (p - 3.0) * 2 * ry
        if abs(x) < gap_half and y < -ry + 0.2:
            continue  # poarta
        per.append((x, y))
    for (x, y) in per:
        # mai LATE decat pasul (~0.57 m) => se suprapun usor, ca un zid sec
        w = 0.62 + rand() * 0.16
        h = 0.38 + rand() * 0.14
        d = 0.40 + rand() * 0.10
        lean = (rand() - 0.5) * 0.08
        b.box((x + (rand() - 0.5) * 0.05, y + (rand() - 0.5) * 0.05,
               h * 0.5),
              (w, d, h), CONCRETE,
              rotation=Matrix.Rotation(lean, 3, "Z"))
        # al doilea rand, decalat o jumatate de piatra, ca zidaria reala
        if rand() < 0.85:
            b.box((x + (rand() - 0.5) * 0.10, y + (rand() - 0.5) * 0.10,
                   h + 0.15), (w * 0.82, d * 0.9, 0.32), CONCRETE,
                  rotation=Matrix.Rotation((rand() - 0.5) * 0.1, 3, "Z"))


def house_body(b):
    # corpul tencuit
    b.box((0.0, 0.15, WALL_H * 0.5), (HOUSE_W, HOUSE_D, WALL_H), CONCRETE)
    # soclu de piatra
    b.box((0.0, 0.15, 0.09), (HOUSE_W + 0.14, HOUSE_D + 0.14, 0.18), ROCK_LIGHT)
    # grinzi de colt + montantii verandei
    for sx in (-1.0, 1.0):
        b.beam((sx * (HOUSE_W / 2 - 0.06), 0.15 - HOUSE_D / 2 + 0.02, 0.0),
               (sx * (HOUSE_W / 2 - 0.06), 0.15 - HOUSE_D / 2 + 0.02, WALL_H),
               0.12, WOOD)
        b.beam((sx * (HOUSE_W / 2 - 0.06), 0.15 + HOUSE_D / 2 - 0.02, 0.0),
               (sx * (HOUSE_W / 2 - 0.06), 0.15 + HOUSE_D / 2 - 0.02, WALL_H),
               0.12, WOOD)
    # usa in fata (-Y), incastrata + toc
    b.box((0.0, 0.15 - HOUSE_D / 2 - 0.02, 0.95), (0.86, 0.10, 1.7),
          WOOD)
    # ferestre cu obloane de lemn
    for wx in (-1.25, 1.25):
        b.box((wx, 0.15 - HOUSE_D / 2 - 0.02, 1.15), (0.6, 0.08, 0.62),
              WOOD)
    # fereastra laterala
    b.box((HOUSE_W / 2 + 0.02, 0.15, 1.2), (0.08, 0.7, 0.6), WOOD)
    # treapta de intrare
    b.box((0.0, 0.15 - HOUSE_D / 2 - 0.35, 0.09), (1.3, 0.6, 0.18), CONCRETE)


def roof(b):
    """Acoperis in 4 ape: UN SINGUR mesh construit pe fete (nu placi rotite),
    cu randuri de olane asezate PE panta si coame albe pe muchii.

    Prima varianta folosea cate 3 placi `box` rotite per apa: pozitionarea lor
    pe panta diverga si acoperisul iesea un morman de placi plutitoare — fix
    aspectul "Minecraft" pe care il vanam. Fetele construite explicit intre
    streasina si coama nu pot diverge: geometria E panta.
    """
    base_w = HOUSE_W + ROOF_OVER * 2
    base_d = HOUSE_D + ROOF_OVER * 2
    cy = 0.15
    ridge_len = HOUSE_W - HOUSE_D * 0.55
    eave_z = WALL_H
    top_z = WALL_H + ROOF_H
    # colturile streasinii si capetele coamei
    c_fl = (-base_w / 2, cy - base_d / 2, eave_z)
    c_fr = (base_w / 2, cy - base_d / 2, eave_z)
    c_bl = (-base_w / 2, cy + base_d / 2, eave_z)
    c_br = (base_w / 2, cy + base_d / 2, eave_z)
    r_l = (-ridge_len / 2, cy, top_z)
    r_r = (ridge_len / 2, cy, top_z)
    verts = {}
    for key, p in [("fl", c_fl), ("fr", c_fr), ("bl", c_bl), ("br", c_br),
                   ("rl", r_l), ("rr", r_r)]:
        verts[key] = b.bm.verts.new(p)
    faces = [
        b.bm.faces.new((verts["fl"], verts["fr"], verts["rr"], verts["rl"])),
        b.bm.faces.new((verts["br"], verts["bl"], verts["rl"], verts["rr"])),
        b.bm.faces.new((verts["bl"], verts["fl"], verts["rl"])),
        b.bm.faces.new((verts["fr"], verts["br"], verts["rr"])),
    ]
    new_verts = list(verts.values())
    for f in faces:
        f[b.slot] = TILE_TERRACOTTA
    b._tag(new_verts, TILE_TERRACOTTA)
    # streasina inchisa pe dedesubt (soffit de lemn), sa nu se vada in pod
    b.box((0.0, cy, eave_z - 0.05), (base_w, base_d, 0.10), WOOD)
    # Randurile de olane: bare subtiri PARALELE cu streasina, asezate pe
    # panta si impinse putin in afara pe normala — muchiile lor + bevel-ul
    # prind lumina si vand "cursurile de tigla" la costul a catorva bare.
    courses = 4
    for c in range(1, courses):
        t = c / courses
        # fata (-Y) si spatele (+Y)
        for sy in (-1.0, 1.0):
            ex0 = lerp(-base_w / 2, -ridge_len / 2, t)
            ex1 = lerp(base_w / 2, ridge_len / 2, t)
            ey = cy + sy * lerp(base_d / 2, 0.0, t)
            ez = lerp(eave_z, top_z, t)
            b.beam((ex0, ey + sy * 0.05, ez + 0.045),
                   (ex1, ey + sy * 0.05, ez + 0.045),
                   (0.07, 0.055), TILE_TERRACOTTA)
        # apele laterale
        for sx in (-1.0, 1.0):
            sy0 = cy - lerp(base_d / 2, 0.0, t)
            sy1 = cy + lerp(base_d / 2, 0.0, t)
            ex = sx * lerp(base_w / 2, ridge_len / 2, t)
            ez = lerp(eave_z, top_z, t)
            b.beam((ex + sx * 0.05, sy0, ez + 0.045),
                   (ex + sx * 0.05, sy1, ez + 0.045),
                   (0.07, 0.055), TILE_TERRACOTTA)
    # Coamele ALBE (semnatura referintei): coama principala + 4 muchii de apa.
    b.beam((-ridge_len / 2 - 0.08, cy, top_z + 0.06),
           (ridge_len / 2 + 0.08, cy, top_z + 0.06), (0.20, 0.15), CONCRETE)
    for rx, corner in [(r_l, c_fl), (r_l, c_bl), (r_r, c_fr), (r_r, c_br)]:
        b.beam((rx[0], rx[1], rx[2] + 0.05),
               (corner[0], corner[1], corner[2] + 0.05),
               (0.13, 0.11), CONCRETE)


def lerp(a, t_b, t):
    return a + (t_b - a) * t


def sand_pad(b):
    b.rock((0.0, 0.0, -0.42), (8.6, 7.4, 0.55), SAND_LIGHT,
           seed=7, segments=10, rings=1, flat_top=True, taper=0.2)


def palm(b):
    """Un palmier mic in colt — silueta care rupe dreptunghiurile."""
    b.beam((2.9, 2.3, 0.0), (3.15, 2.5, 2.3), (0.18, 0.16), WOOD)
    for k in range(6):
        a = k / 6.0 * math.tau
        # frunze LATE, cu varful cazut — la bare subtiri nu se vedeau deloc
        tip = (3.15 + math.cos(a) * 1.35, 2.5 + math.sin(a) * 1.35, 1.85)
        b.beam((3.15, 2.5, 2.35), tip, (0.55, 0.06), TROPICAL_GREEN)


def wood_bits(b):
    """Lemnaria: usa, obloane, grinzi — separata de corp ca sa ramana pe
    atlasul de paleta cand corpul primeste textura de tencuiala."""
    b.box((0.0, 0.15 - HOUSE_D / 2 - 0.02, 0.95), (0.86, 0.10, 1.7), WOOD)
    for wx in (-1.25, 1.25):
        b.box((wx, 0.15 - HOUSE_D / 2 - 0.02, 1.15), (0.6, 0.08, 0.62), WOOD)
    b.box((HOUSE_W / 2 + 0.02, 0.15, 1.2), (0.08, 0.7, 0.6), WOOD)
    for sx in (-1.0, 1.0):
        b.beam((sx * (HOUSE_W / 2 - 0.06), 0.15 - HOUSE_D / 2 + 0.02, 0.0),
               (sx * (HOUSE_W / 2 - 0.06), 0.15 - HOUSE_D / 2 + 0.02, WALL_H),
               0.12, WOOD)
        b.beam((sx * (HOUSE_W / 2 - 0.06), 0.15 + HOUSE_D / 2 - 0.02, 0.0),
               (sx * (HOUSE_W / 2 - 0.06), 0.15 + HOUSE_D / 2 - 0.02, WALL_H),
               0.12, WOOD)
    palm(b)


def plaster_body(b):
    """Corpul tencuit + soclu + treapta — partea care primeste clasa plaster."""
    b.box((0.0, 0.15, WALL_H * 0.5), (HOUSE_W, HOUSE_D, WALL_H), CONCRETE)
    b.box((0.0, 0.15, 0.09), (HOUSE_W + 0.14, HOUSE_D + 0.14, 0.18),
          ROCK_LIGHT)
    b.box((0.0, 0.15 - HOUSE_D / 2 - 0.35, 0.09), (1.3, 0.6, 0.18), CONCRETE)


# `cube_uvs` a fost definit aici cat timp pilotul era singurul consumator; de la
# al doilea asset pe clase (moara, #129) sta in dio_lib, langa assign_uvs.

AO_SPEC = dict(samples=28, dist=2.2, gradient="vertical",
               low=0.45, high=1.0, power=0.8, floor=0.15)

# (nume nod, functie, bevel, marime UV cub sau None = ramane pe atlas)
# Numele sunt CONTRACTUL cu Godot: Track mapeaza prefixele House_Roof/
# House_Plaster/House_Stone pe clasele de material; restul cad pe atlas.
PARTS = [
    ("House_Sand", sand_pad, 0.03, None),
    ("House_Stone", lambda b: stone_ring(b, 91), 0.05, 1.4),
    ("House_Plaster", plaster_body, 0.04, 2.2),
    ("House_Wood", wood_bits, 0.03, None),
    ("House_Roof", roof, 0.04, 2.6),
]

clear_built("House_")
built = []
total = 0
for name, fill, bevel, uv_size in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, ao=AO_SPEC, origin="base_axis")
    # finish() muta baza piesei la z=0 (corect pentru assets de sine
    # statatoare); aici piesele sunt UN ansamblu, deci cota se restaureaza.
    obj.location.z = min_z
    if uv_size is not None:
        cube_uvs(obj, uv_size)
    total += stats["tris"]
    built.append(obj)
    print("%-14s %4d tris  AO %.2f..%.2f  uv=%s"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             "cub %.1f" % uv_size if uv_size else "atlas"))

print("TOTAL: %d tris (buget hero 1000-5000)" % total)
print("GLB:  %s (%d B)" % export_glb(built, "village_house.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "village_house.blend"))
