"""Kyoto -- Fundalul (brief docs/asset_briefs/kyoto_kit.md §1.11).

  kyoto/rocks/kyoto_horizon.glb
      Higashiyama_A   deal jos cu padure de toamna, ~200 x 45 x 30 m
      Higashiyama_B   alt deal, silueta diferita (doua varfuri), 200 x 45 x 30 m
      Arashiyama_A    munte verde, mai inalt, ~220 x 70 x 55 m
      FarRoofs_A      banda de acoperisuri gri, ~150 x 12 x 10 m

UN SINGUR fisier (conventia Fiordland/Jodhpur). Consumatorul e
`Track._build_horizon` (scenes/tracks/track.gd): ia fiecare nod DUPA NUME EXACT,
copil direct al radacinii, il recentreaza, il ingroapa ~4 m sub teren, ii da yaw
si il scaleaza pe inel, ii stinge umbra aruncata. Deci: fiecare nod e un VOLUM
INCHIS lizibil din orice azimut, originea la baza, nimic important sub z = 4.
Axe: X lungime, Y adancime, Z inaltime (cotele din contract sunt L x A x I).

Culori (zero sloturi noi, zero sloturi de masina): verde-inchis de cedru
`TROPICAL_GREEN`, rosu `KERB_RED`, rosu-portocaliu `LAVA_ORANGE`, auriu-chihlimbar
`SAND_MID`, ruginiu `LARCH_RUST`; muntele pe `TROPICAL_GREEN`/`CACTUS_GREEN`;
acoperisurile pe `ASPHALT`/`ASPHALT_EDGE`. Fara clasa (`horizon_class: ""`).
Fara Turnul Kyoto, fara cladiri moderne, fara text.

Lista de elemente (inainte de geometrie), din decuparile `horizon_*.png`:

  Higashiyama_A (decupare): 8-9 cupole rotunde de padure lipite pe un soclu verde
    inchis; de la stanga: o cupola verde mica, una portocalie, una VERDE mare,
    cea mai inalta (centru-stanga) rosu-portocalie cu aur la poale, apoi rosu,
    auriu, si in dreapta masa cea mai larga, cu crestet verde si flancuri
    rosii/aurii. Culoarea e pe petice (o cupola = o culoare), golurile dintre
    cupole sunt verde-inchis.
  Higashiyama_B (decupare): silueta cu VARFURI, nu cupole: un varf ascutit rosu
    in stanga (cel mai inalt), sa, un al doilea varf auriu-rosu in dreapta, cupole
    portocalii si verzi la poale, flanc verde in centru.
  Arashiyama_A (decupare): un munte FATETAT verde, varf principal la stanga de
    centru, creasta secundara mai joasa in dreapta, umeri la capete; jos, un rand
    de tufe rotunde de padure. (Muntele albastru-pal din spate si apa nu se
    modeleaza: sunt ceata si teren.)
  FarRoofs_A (decupare): rand dublu de case cu acoperisuri in patru ape gri si
    pereti inchisi, cu cateva tufe/copaci verzi rotunzi printre ele.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_horizon.py
"""

import math
import bmesh
from mathutils import Vector

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

CEDAR = TROPICAL_GREEN        # verdele-inchis de cedru
GREEN_B = CACTUS_GREEN        # verde mai galbui (munte)
RED = KERB_RED
ORANGE = LAVA_ORANGE
GOLD = SAND_MID
RUST = LARCH_RUST

ROOF_DARK = ASPHALT           # #4B4B4D
ROOF_GREY = ASPHALT_EDGE      # #696765
WALL_DARK = LOG_DARK
WALL_LIGHT = SAND_MID

BURY = 4.0

AO_HILL = dict(samples=12, dist=30.0, gradient="vertical",
               low=0.55, high=1.00, power=0.85, floor=0.25)
AO_MOUNT = dict(samples=12, dist=40.0, gradient="vertical",
                low=0.50, high=1.00, power=0.85, floor=0.22)
AO_ROOFS = dict(samples=12, dist=5.0, gradient="vertical",
                low=0.55, high=1.00, power=0.85, floor=0.25)


def _smooth(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


# --- relief: grila inchisa cu fete triunghiulare, culoare pe petice --------------

def build_relief(name, seed, L, D, H, seeds, mode, nx, ny, base_frac=0.0,
                 default_slot=None, paint=None, extra=None, thresh=0.18):
    """Volum inchis dintr-o grila nx x ny: suprafata = `base` + suma de cupole
    (`mode="sum"`) sau maximul unor conuri (`mode="max"`, creste si sei de munte);
    perimetrul coboara la z = 0 si e inchis cu un capac, deci nu exista goluri.
    `seeds`: (x, y, raza_x, inaltime, exponent, culori) cu culori = lista de
    (slot, pondere). Fiecare triunghi ia culoarea semintei dominante in centrul
    lui (cu varianta aleatoare dupa ponderi); unde nicio samanta nu domina, slotul
    implicit (verdele-inchis). Varfurile interioare sunt zgaltaite in plan si pe Z
    ca fetele sa iasa mari si neregulate (fatete, nu suprafata neteda)."""
    b = Builder()
    rnd = _lcg(seed)
    ry_ratio = (D * 0.5) / (L * 0.5)
    cell_x, cell_y = L / nx, D / ny
    default_slot = CEDAR if default_slot is None else default_slot

    def bumps(x, y):
        vals = []
        for (sx, sy, rx, h, ex, cols) in seeds:
            ry = rx * (0.55 if mode == "sum" else 0.62)
            d = math.hypot((x - sx) / rx, (y - sy) / ry)
            if mode == "sum":
                v = h * (max(0.0, 1.0 - d * d) ** ex)
            else:
                v = h * max(0.0, 1.0 - d) ** ex
            vals.append(v)
        return vals

    def height(x, y):
        vals = bumps(x, y)
        base = base_frac * H * max(0.0, 1.0 - (abs(x) / (L * 0.5)) ** 2)
        if mode == "sum":
            z = base + sum(vals)
        else:
            z = max(base, max(vals))
        v = abs(y) / (D * 0.5)
        prof = max(0.0, 1.0 - v ** 2.2) ** 0.8
        end = _smooth((L * 0.5 - abs(x)) / (L * 0.16))
        return z * prof * (0.25 + 0.75 * end) if mode == "sum" else \
            z * prof * (0.1 + 0.9 * end)

    # plasa de varfuri (x, y jitter doar in interior), z din camp + zgomot
    grid = {}
    for i in range(nx + 1):
        for j in range(ny + 1):
            x = -L * 0.5 + L * i / nx
            y = -D * 0.5 + D * j / ny
            edge = i in (0, nx) or j in (0, ny)
            if not edge:
                x += (rnd() - 0.5) * cell_x * 0.55
                y += (rnd() - 0.5) * cell_y * 0.55
            z = 0.0 if edge else height(x, y)
            if not edge and z > 1.0:
                z += (rnd() - 0.5) * (1.6 if mode == 'sum' else 5.0)
            grid[(i, j)] = (x, y, max(0.0, z))
    zmax = max(p[2] for p in grid.values())
    sc = H / zmax
    verts = {}
    for k, (x, y, z) in grid.items():
        verts[k] = b.bm.verts.new((x, y, z * sc))

    def pick(cols):
        tot = sum(w for _, w in cols)
        r = rnd() * tot
        for s, w in cols:
            r -= w
            if r <= 0.0:
                return s
        return cols[-1][0]

    faces = []
    for i in range(nx):
        for j in range(ny):
            quad = (verts[(i, j)], verts[(i + 1, j)],
                    verts[(i + 1, j + 1)], verts[(i, j + 1)])
            if (i + j + int(rnd() * 2)) % 2 == 0:
                tris = ((quad[0], quad[1], quad[2]), (quad[0], quad[2], quad[3]))
            else:
                tris = ((quad[0], quad[1], quad[3]), (quad[1], quad[2], quad[3]))
            for t in tris:
                f = b.bm.faces.new(t)
                faces.append(f)
    # capacul de jos (perimetrul, in sens invers)
    ring = [verts[(i, 0)] for i in range(nx + 1)] + \
           [verts[(nx, j)] for j in range(1, ny + 1)] + \
           [verts[(i, ny)] for i in range(nx - 1, -1, -1)] + \
           [verts[(0, j)] for j in range(ny - 1, 0, -1)]
    cap = b.bm.faces.new(list(reversed(ring)))
    cap[b.slot] = default_slot

    # culoarea pe petice
    for f in faces:
        c = f.calc_center_median()
        vals = bumps(c.x, c.y)
        k = max(range(len(vals)), key=lambda q: vals[q])
        if paint is not None:
            f[b.slot] = paint(c, f, rnd)
        elif vals[k] < thresh * seeds[k][3]:
            f[b.slot] = default_slot
        else:
            f[b.slot] = pick(seeds[k][5])
    if extra is not None:
        extra(b)
    return b.to_object(name)


# --- Higashiyama_A / Higashiyama_B --------------------------------------------

def _env(pts, x):
    """Interpolare liniara pe (x, valoare)."""
    if x <= pts[0][0]:
        return pts[0][1]
    for (x0, v0), (x1, v1) in zip(pts, pts[1:]):
        if x <= x1:
            return v0 + (v1 - v0) * (x - x0) / (x1 - x0)
    return pts[-1][1]


def _hill_seeds(seed, env, palette, step, rx_lo, rx_hi, ex, ylim=8.0):
    """Cupole de padure insirate pe X: inaltimea urmeaza anvelopa `env`, culoarea
    ciclica din `palette` (lista de liste de (slot, pondere))."""
    rnd = _lcg(seed)
    out = []
    x = -96.0
    k = 0
    while x < 98.0:
        h = _env(env, x) * (0.78 + 0.22 * rnd())
        rx = max(rx_lo + (rx_hi - rx_lo) * rnd(), 0.95 * h)
        out.append((x, (rnd() - 0.5) * 2.0 * ylim, rx, h, ex,
                    palette[k % len(palette)]))
        x += step * (0.85 + 0.3 * rnd())
        k += 1
    return out


def build_higashiyama_a():
    """Higashiyama_A, 200 x 45 x 30 m: ~15 cupole rotunde de padure de toamna,
    LIPITE (pas ~13 m, raza 11-16 m), cu vai verde-inchis intre ele, ca pe
    decupare: stanga cupole verzi/portocalii mici, varful cel mai inalt
    rosu-portocaliu (centru-stanga), rosu, auriu, masa din dreapta cu crestet
    verde si flancuri rosii/aurii. Dominanta: rosu/portocaliu/auriu."""
    G = [(CEDAR, 0.9), (GREEN_B, 0.1)]
    O = [(ORANGE, 0.7), (RED, 0.15), (GOLD, 0.15)]
    R = [(RED, 0.75), (ORANGE, 0.25)]
    Y = [(GOLD, 0.75), (ORANGE, 0.25)]
    palette = [G, O, O, G, O, R, Y, R, R, G, Y, R, G, G, R, O, Y, R]
    env = [(-100, 8), (-80, 16), (-55, 17), (-30, 21), (-14, 31), (4, 24),
           (24, 17), (44, 24), (60, 27), (78, 20), (92, 14), (100, 7)]
    seeds = _hill_seeds(2201, env, palette, 11.5, 10.0, 14.5, 1.2)
    return build_relief("Higashiyama_A", 2201, 200.0, 45.0, 30.0, seeds, "sum",
                        64, 14, base_frac=0.08, thresh=0.05)


def build_higashiyama_b():
    """Higashiyama_B, 200 x 45 x 30 m: padure de toamna cu SILUETA DE VARFURI:
    un varf rosu ascutit la stanga (cel mai inalt, cu flancul stang verde), sa,
    al doilea varf auriu-rosu la dreapta, conifere verzi in centru, tufe
    portocalii la poale. Doua conuri mari (exponent 1) peste un sir de cupole
    mici, deci conturul are dinti, nu mamelone netede ca la A."""
    G = [(CEDAR, 0.9), (RUST, 0.1)]
    O = [(ORANGE, 0.75), (GOLD, 0.25)]
    R = [(RED, 0.7), (ORANGE, 0.3)]
    Y = [(GOLD, 0.6), (ORANGE, 0.25), (RED, 0.15)]
    palette = [G, G, O, G, R, O, G, G, Y, O, R, G, Y, O]
    env = [(-100, 6), (-85, 10), (-62, 14), (-40, 12), (-20, 13), (0, 14),
           (22, 12), (40, 15), (62, 12), (85, 9), (100, 6)]
    small = _hill_seeds(2273, env, palette, 11.0, 8.5, 12.0, 1.3, ylim=9.0)
    peaks = [
        (-60.0, 0.0, 34.0, 30.0, 1.05,
         [(RED, 0.55), (ORANGE, 0.25), (RUST, 0.1), (CEDAR, 0.1)]),
        (-80.0, -3.0, 26.0, 17.0, 1.1, [(CEDAR, 0.8), (RUST, 0.2)]),
        (42.0, 0.0, 30.0, 26.0, 1.05,
         [(GOLD, 0.4), (ORANGE, 0.3), (RED, 0.3)]),
        (66.0, -3.0, 20.0, 16.0, 1.1, [(RED, 0.7), (ORANGE, 0.3)]),
    ]
    return build_relief("Higashiyama_B", 2273, 200.0, 45.0, 30.0,
                        peaks + small, "sum", 64, 14, base_frac=0.10,
                        thresh=0.05)


# --- Arashiyama_A -------------------------------------------------------------

def build_arashiyama_a():
    """Arashiyama_A, 220 x 70 x 55 m: munte FATETAT verde (maximul unor conuri:
    creste si sei, nu clopot), varful principal la stanga de centru (55 m),
    creasta secundara mai joasa la dreapta (42 m), umeri la capete (30-36 m) si
    un spur in fata. Petice mari verde-inchis / verde galbui, ca versantii
    din decupare; la poale, un rand de tufe rotunde de padure (`Higashiyama`-ul
    n-are asa ceva, aici ele sunt in decupare)."""
    seeds = [
        (-38.0, 0.0, 74.0, 55.0, 0.95, []),
        (-104.0, -4.0, 50.0, 30.0, 1.0, []),
        (46.0, 4.0, 62.0, 42.0, 0.95, []),
        (98.0, 0.0, 40.0, 36.0, 1.0, []),
        (8.0, -14.0, 36.0, 28.0, 1.0, []),
        (-66.0, 16.0, 30.0, 26.0, 1.0, []),
        (-12.0, 12.0, 26.0, 30.0, 1.0, []),
        (74.0, -12.0, 28.0, 30.0, 1.0, []),
        (22.0, 14.0, 24.0, 22.0, 1.0, []),
        (-90.0, 12.0, 24.0, 20.0, 1.0, []),
    ]
    # semintele de culoare: 16 petice mari
    prnd = _lcg(2313)
    patches = [((prnd() - 0.5) * 230.0, (prnd() - 0.5) * 70.0,
                CEDAR if prnd() < 0.6 else GREEN_B) for _ in range(22)]

    def paint(c, f, r):
        best, slot = 1e9, CEDAR
        for (px, py, s) in patches:
            d = math.hypot(c.x - px, (c.y - py) * 2.2)
            if d < best:
                best, slot = d, s
        if c.z < BURY + 3.0:
            return CEDAR                  # poalele raman verde-inchis
        return slot

    def foot_trees(b):
        # tufele rotunde de la poale, pe ambele parti (volum inchis din orice unghi)
        trnd = _lcg(2331)
        for k in range(26):
            px = -102.0 + k * 8.2 + (trnd() - 0.5) * 6.0
            side = 1.0 if k % 2 == 0 else -1.0
            py = side * (17.0 + trnd() * 8.0)
            r = 6.5 + trnd() * 3.0
            leaf_blob(b, (px, py, r * 0.8 * 1.1 + 0.4), r, r, r * 0.8, CEDAR if k % 3 else GREEN_B,
                      subdiv=1, jag=0.32, seed=300 + k)

    return build_relief("Arashiyama_A", 2309, 220.0, 70.0, 55.0, seeds, "max",
                        56, 16, base_frac=0.0, paint=paint, extra=foot_trees)


# --- FarRoofs_A ---------------------------------------------------------------

def _hip(b, cx, cy, ze, hx, hy, rise, slot):
    """Acoperis simplu in patru ape: streasina dreptunghiulara la `ze`, creasta
    pe axa lunga. 8 triunghiuri (+2 pentru fundul inchis)."""
    e = [b.bm.verts.new(p) for p in (
        (cx - hx, cy - hy, ze), (cx + hx, cy - hy, ze),
        (cx + hx, cy + hy, ze), (cx - hx, cy + hy, ze))]
    rh = max(hx - hy, 0.0) if hx >= hy else 0.0
    rv = max(hy - hx, 0.0) if hy > hx else 0.0
    if hx >= hy:
        r0 = b.bm.verts.new((cx - rh, cy, ze + rise))
        r1 = b.bm.verts.new((cx + rh, cy, ze + rise))
        quads = [(e[0], e[1], r1, r0), (e[2], e[3], r0, r1)]
        tris = [(e[1], e[2], r1), (e[3], e[0], r0)]
    else:
        r0 = b.bm.verts.new((cx, cy - rv, ze + rise))
        r1 = b.bm.verts.new((cx, cy + rv, ze + rise))
        quads = [(e[1], e[2], r1, r0), (e[3], e[0], r0, r1)]
        tris = [(e[0], e[1], r0), (e[2], e[3], r1)]
    fs = []
    for q in quads:
        fs.append(b.bm.faces.new(q))
    for t in tris:
        fs.append(b.bm.faces.new(t))
    fs.append(b.bm.faces.new((e[3], e[2], e[1], e[0])))     # fundul
    for f in fs:
        f[b.slot] = slot


def build_far_roofs():
    """FarRoofs_A, 150 x 12 x 10 m: DOUA RANDURI de case spate in spate (volum
    inchis din orice azimut), fiecare o cutie de perete intunecat (1,5-2,5 m
    vizibili peste cei 4 ingropati) sub un acoperis in patru ape gri
    (ASPHALT / ASPHALT_EDGE) cu streasina iesita; latimi 9-15 m, cateva case cu
    etaj (acoperis pana la ~9,5 m), si tufe mari de padure (~1 din 4 locuri) in loc de casa, ca pe decupare. Fara ferestre: la 200+ m sunt sub un pixel."""
    rnd = _lcg(2417)
    b = Builder()
    half = 75.0
    for side in (-1.0, 1.0):
        x = -half
        while x < half - 0.1:
            w = 9.0 + rnd() * 6.0
            if half - (x + w) < 7.0:
                w = half - x
            d = 5.5 + rnd() * 0.5
            if x > -half + 12.0 and x + w < half - 12.0 and rnd() < 0.24:
                # in loc de casa: o tufa mare de padure (ca cedrii de pe decupare)
                leaf_blob(b, (x + w * 0.5, side * 2.2, 5.2), w * 0.55, 3.7, 4.0,
                          CEDAR if rnd() < 0.6 else GREEN_B, subdiv=1, jag=0.22,
                          seed=int(x * 7) % 997 + 11)
                x += w
                continue
            y0, y1 = (0.0, d) if side > 0 else (-d, 0.0)
            two = rnd() < 0.22
            wall_top = BURY + (3.0 if two else 0.7 + rnd() * 0.7)
            wslot = WALL_DARK if rnd() < 0.7 else WALL_LIGHT
            b.box(((x + x + w) * 0.5, (y0 + y1) * 0.5, wall_top * 0.5),
                  (w, y1 - y0, wall_top), wslot)
            rise = 3.4 + rnd() * 1.2
            rise = min(rise, 9.6 - wall_top)
            _hip(b, x + w * 0.5, (y0 + y1) * 0.5, wall_top,
                 w * 0.5 + 0.7, (y1 - y0) * 0.5 + 0.7, rise,
                 ROOF_DARK if rnd() < 0.55 else ROOF_GREY)
            x += w
    return b.to_object("FarRoofs_A")


# --- emit ---------------------------------------------------------------------

clear_built()
results = []


def emit_node(obj, ao, smooth_angle):
    st = finish(obj, bevel=0.0, ao=ao, origin="base", smooth_angle=smooth_angle)
    results.append((obj.name, st["tris"]))
    return obj


hig_a = emit_node(build_higashiyama_a(), AO_HILL, None)
hig_b = emit_node(build_higashiyama_b(), AO_HILL, None)
ara_a = emit_node(build_arashiyama_a(), AO_MOUNT, None)
roofs = emit_node(build_far_roofs(), AO_ROOFS, 30.0)

built = [hig_a, hig_b, ara_a, roofs]
_, sz = export_glb(built, "kyoto/rocks/kyoto_horizon.glb")
print("export: kyoto/rocks/kyoto_horizon.glb (%.0f KB)" % (sz / 1024.0))

total = 0
print()
for name, tris in results:
    o = bpy.data.objects[name]
    xs_ = [v.co.x for v in o.data.vertices]
    ys_ = [v.co.y for v in o.data.vertices]
    zs_ = [v.co.z for v in o.data.vertices]
    total += tris
    print("%-16s tris=%5d  %.1f x %.1f x %.1f m" % (
        name, tris, max(xs_) - min(xs_), max(ys_) - min(ys_), max(zs_) - min(zs_)))
print("TOTAL horizon: %d tris" % total)

hig_b.location.x = 300.0
ara_a.location.x = 600.0
roofs.location.x = 900.0
save_blend(built, "kyoto_horizon.blend")
