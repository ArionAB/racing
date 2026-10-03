"""Kyoto -- templele (brief docs/asset_briefs/kyoto_kit.md §1.7).

  kyoto/structures/votive_torii_cluster.glb   sir de 7 torii descrescatoare
  kyoto/props/kitsune_statue_a.glb, _b.glb    vulpi pe soclu de piatra
  kyoto/props/stone_lantern_a.glb, _b.glb     torō inalt / scund
  kyoto/props/yukimi_lantern.glb              felinar scund pe trei picioare
  kyoto/structures/small_shrine.glb           altarel vermilion
  kyoto/props/ema_rack.glb                    cadru cu placute goale
  kyoto/structures/bell_tower.glb             clopotnita deschisa
  kyoto/props/chozuya.glb                     bazin de purificare sub acoperis
  kyoto/structures/cyclopean_wall.glb         modul de zid ciclopic de 8 m

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_shrine.py

Decizii (coordonator): unde contractul contrazice decuparea castiga decuparea
(exceptie: cote de gabarit/gol); tigla gri = ASPHALT_EDGE 6; lemn deschis
(WOOD) vs inchis (LOG_DARK).
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

# Sloturi (brief kyoto_kit §0.4 + corecturile coordonatorului)
VERM = LAVA_ORANGE         # vermilion sacru
BLACK = ASPHALT            # negru/gri-carbune din decupari (kasagi, baze)
TILE = ASPHALT_EDGE        # tigla gri (VOLCANIC_BLACK iese violet)
DARKW = LOG_DARK           # lemn inchis
LIGHTW = WOOD              # lemn deschis
STONE = CONCRETE           # piatra bej
STONE2 = MARBLE_GREY       # piatra gri deschis
BRONZE = TROPICAL_GREEN    # clopot de bronz patinat
MOSS = TROPICAL_GREEN

AO_SOFT = dict(samples=12, dist=2.5, gradient="vertical", low=0.78, high=1.0,
               power=0.8, floor=0.35)
AO_BIG = dict(samples=12, dist=3.5, gradient="vertical", low=0.72, high=1.0,
              power=0.8, floor=0.30)

clear_built()


# ---------------------------------------------------------------------------
# ajutoare locale (nu merg in kyoto_shapes.py: fisier partajat)
# ---------------------------------------------------------------------------

def extrude_x(b, outline_yz, x0, x1, slot):
    """Poligon in planul YZ (lista (y, z), orice sens) extrudat pe X."""
    bm = b.bm
    L = [bm.verts.new((x0, y, z)) for y, z in outline_yz]
    R = [bm.verts.new((x1, y, z)) for y, z in outline_yz]
    n = len(outline_yz)
    bm.faces.new(L)
    bm.faces.new(list(reversed(R)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((L[i], L[j], R[j], R[i]))
    return b._tag(L + R, slot)


def sq_frustum(b, z0, h, w0, w1, slot, cx=0.0, cy=0.0):
    """Trunchi de piramida patrata (semi-laturi w0 jos, w1 sus), aliniat pe axe."""
    bm = b.bm
    lo = [bm.verts.new((cx + sx * w0, cy + sy * w0, z0)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    hi = [bm.verts.new((cx + sx * w1, cy + sy * w1, z0 + h)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def curved_slab(b, cx, cy, zb, hw, thick, lift, depth, slot, n=9, power=2.2,
                end_cut=0.0):
    """Placa curbata in XZ (kasagi): mijlocul jos, capetele ridicate cu `lift`,
    grosime `thick`, adancime `depth` pe Y. Fata de sus si cea de jos curbate."""
    top, bot = [], []
    for i in range(n + 1):
        t = -1.0 + 2.0 * i / n
        z = zb + lift * abs(t) ** power
        bot.append((cx + t * hw, z))
        top.append((cx + t * hw, z + thick))
    outline = bot + list(reversed(top))
    return b.prism(outline, depth, slot, center=(0.0, cy, 0.0))


def poly_block(b, c, rx, rz, depth, slot, n=6, seed=0, slope=0.0, round_f=0.82,
               jit=0.16, facing=1):
    """Bloc poligonal de piatra (pentru zid ciclopic): contur de `n` varfuri cu
    raza jitterata in planul XZ al fetei, extrudat pe Y cu fata din fata
    teșita (inel mijlociu mai mare, fata mai mica). `slope` inclina fata
    (taluz): y se deplaseaza cu slope*dz fata de centru; `facing` = +1/-1 =
    pe ce parte a lui Y priveste fata."""
    rnd = _lcg(seed)
    cx, cy, cz = c
    ang0 = rnd() * 6.283
    pts = []
    for i in range(n):
        a = ang0 + 2 * math.pi * i / n + (rnd() - 0.5) * 0.35
        k = 1.0 - jit + rnd() * jit
        pts.append((math.cos(a) * rx * k, math.sin(a) * rz * k))
    bm = b.bm

    def ring(scale, y):
        out = []
        for (px, pz) in pts:
            out.append(bm.verts.new((cx + px * scale, cy + facing * y + slope * pz * scale,
                                     cz + pz * scale)))
        return out

    back = ring(1.0, -depth)
    mid = ring(1.0, 0.0)
    front = ring(round_f, depth * 0.35)
    for lo, hi in ((back, mid), (mid, front)):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    return b._tag(back + mid + front, slot)


# ---------------------------------------------------------------------------
# votive_torii_cluster
# ---------------------------------------------------------------------------

def _torii(bw, bk, cx, cy, h):
    """Un torii de inaltime `h` (sirul se aseaza spre -X)."""
    w = 0.215 * h
    r_b, r_t = 0.068 * h, 0.056 * h
    base_h = 0.13 * h
    top_p = 0.885 * h
    for s in (-1, 1):
        x = cx + s * w
        bw.frustum((x, cy, base_h + (top_p - base_h) * 0.5), r_b * 0.97, r_t,
                   top_p - base_h, VERM, segments=8)
        bk.frustum((x, cy, base_h * 0.5), r_b * 1.12, r_b * 1.03, base_h, BLACK,
                   segments=8)
    bw.box((cx, cy, 0.855 * h), (2 * 0.33 * h, 0.085 * h, 0.065 * h), VERM)
    bw.box((cx, cy, 0.725 * h), (2 * 0.375 * h, 0.065 * h, 0.05 * h), VERM)
    bw.box((cx, cy, 0.79 * h), (0.055 * h, 0.05 * h, 0.14 * h), VERM)
    for sg in (-1, 1):
        bw.box((cx + sg * 0.115 * h, cy, 0.79 * h), (0.04 * h, 0.05 * h, 0.14 * h), VERM)
        bw.box((cx + sg * (w + r_b * 0.95), cy, 0.725 * h),
               (0.032 * h, 0.075 * h, 0.105 * h), VERM)
    curved_slab(bk, cx, cy, 0.89 * h, 0.48 * h, 0.075 * h, 0.05 * h,
                0.125 * h, BLACK, n=10, power=2.4)


def build_votive_torii_cluster():
    """`votive_torii_cluster.png` -- lista de elemente (inainte de modelare):

    - 7 porti torii (decuparea arata 7, contractul zice 6: castiga decuparea)
      in sir, descrescatoare de la ~4.2 m la ~1.3 m, fiecare in fata
      (deschiderea spre +Y), sirul se retrage spre dreapta.
    - fiecare: 2 stalpi rotunzi, vermilion, usor conici, cu baza NEAGRA
      (~13% din inaltime); doua traverse (shimaki sub kasagi, nuki jos) care
      ies dincolo de stalpi; un stalp scurt central intre ele (gakuzuka);
      kasagi NEGRU curbat cu capete ridicate, mai lat decat portile.
    - culori: vermilion (LAVA_ORANGE) + negru/gri-carbune (ASPHALT).
    Iese din contur: kasagi-ul peste stalpi. Cote: poarta mare 4.2 m.
    """
    bw = Builder()
    bk = Builder()
    heights = [4.2, 3.3, 2.7, 2.25, 1.85, 1.5, 1.25]
    x = 0.0
    prev_w = None
    for k, h in enumerate(heights):
        wk = 0.94 * h                       # latimea kasagi
        if prev_w is not None:
            x -= 0.5 * (prev_w + wk) * 0.66
        _torii(bw, bk, x, -0.12 * k, h)
        prev_w = wk
    return (bw.to_object("Torii_Wood"), bk.to_object("Torii_Black"))


# ---------------------------------------------------------------------------
# torō (felinar de piatra)
# ---------------------------------------------------------------------------

def _toro(b, bwin, spec):
    """Felinar de piatra in 6 piese, dupa `spec` (latimi = semi-laturi)."""
    z = 0.0
    for (hw, hh) in spec["base"]:
        if hh > 0.3:        # bloc tronconic (soclu inalt, ca pe decupare)
            sq_frustum(b, z, hh, hw, hw * 0.74, STONE)
        else:
            b.box((0, 0, z + hh * 0.5), (2 * hw, 2 * hw, hh), STONE)
        z += hh
    sh, shw0, shw1 = spec["shaft_h"], spec["shaft_w"][0], spec["shaft_w"][1]
    sq_frustum(b, z, sh, shw0, shw1, STONE)
    z += sh
    pw, ph = spec["plat"]
    b.box((0, 0, z + 0.05), (2 * pw * 0.78, 2 * pw * 0.78, 0.10), STONE)       # guler
    z += 0.10
    b.box((0, 0, z + ph * 0.5), (2 * pw, 2 * pw, ph), STONE2)
    z += ph
    fw, fh = spec["fire"]
    b.box((0, 0, z + fh * 0.5), (2 * fw, 2 * fw, fh), STONE)
    for (sx, sy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):      # ferestre intunecate
        dx = fw + 0.004
        sz = (0.012, fw * 1.0, fh * 0.55) if sx else (fw * 1.0, 0.012, fh * 0.55)
        bwin.box((sx * dx, sy * dx, z + fh * 0.5), sz, BLACK)
    z += fh
    b.box((0, 0, z + 0.035), (2 * fw * 1.12, 2 * fw * 1.12, 0.07), STONE2)
    z += 0.07
    rhw, rrise, rlift = spec["roof"]
    hip_roof(b, 0, 0, z, rhw, rhw, rrise, STONE2, lift=rlift, thick=0.10,
             tile_step=rhw, rib=0.0, sag=1.0, swell=0.02)
    z += rrise
    hr = spec["hoju"]
    b.frustum((0, 0, z + hr * 0.45), hr * 0.9, hr * 0.7, hr * 0.8, STONE2, segments=8)
    b.revolve([(hr * 0.2, 0.0), (hr * 1.1, hr * 0.5), (hr * 1.2, hr * 1.1),
               (hr * 0.8, hr * 1.9), (0.0, hr * 2.2)], STONE2, segments=8,
              origin=(0, 0, z + hr * 0.7))


def build_stone_lantern_a():
    """`stone_lantern_a.png` -- lista de elemente:
    - 6 piese suprapuse, de jos: soclu in 2 trepte patrate (late, groase);
      fus lung patrat, gros, se subtiaza; platforma lata; cutie PLINA cu
      ferestre intunecate pe fiecare latura; acoperis patrat cu colturile
      usor ridicate; bulb rotund (hoju).
    - inalt si zvelt (~2.4 m, acoperis ~1.2 m lat); culoare bej-gri.
    """
    b, bw = Builder(), Builder()
    spec = dict(base=[(0.47, 0.20), (0.38, 0.20)], shaft_h=0.62,
                shaft_w=(0.27, 0.19), plat=(0.37, 0.10), fire=(0.26, 0.36),
                roof=(0.62, 0.40, 0.05), hoju=0.11)
    _toro(b, bw, spec)
    return (b.to_object("Lantern_Stone"), bw.to_object("Lantern_Window"))


def build_stone_lantern_b():
    """`stone_lantern_b.png` -- ca _a dar mai scund si mai lat: soclu mare in
    2 trepte (bloc plin), fus SCURT, cutie cu foc mare, acoperis lat; ~1.7 m."""
    b, bw = Builder(), Builder()
    spec = dict(base=[(0.50, 0.14), (0.42, 0.34)], shaft_h=0.14,
                shaft_w=(0.26, 0.24), plat=(0.40, 0.10), fire=(0.30, 0.36),
                roof=(0.62, 0.34, 0.05), hoju=0.105)
    _toro(b, bw, spec)
    return (b.to_object("Lantern_Stone"), bw.to_object("Lantern_Window"))


def build_yukimi_lantern():
    """`yukimi_lantern.png` -- lista de elemente:
    - bloc de baza patrat cu ARCADA deschisa in fata (doi pilastri + buiandrug
      + colturi tesite), pe o placa joasa;
    - talie (platforma scurta), cutie cu foc cu ferestre intunecate,
    - acoperis LAT patrat, jos, cu colturile usor ridicate; bulb pe varf.
    ~1.3 m inaltime, acoperis ~1.0 m lat.
    """
    b, bw = Builder(), Builder()
    b.box((0, 0, 0.05), (1.00, 0.84, 0.10), STONE)
    z = 0.10
    hw, hd, hh = 0.40, 0.34, 0.36
    for s in (-1, 1):
        b.box((s * (hw - 0.11), 0, z + hh * 0.5), (0.22, 2 * hd, hh), STONE)
    b.box((0, -hd + 0.07, z + hh * 0.5), (2 * hw, 0.14, hh), STONE)
    b.box((0, 0, z + hh - 0.05), (2 * hw, 2 * hd, 0.10), STONE)
    bw.box((0, hd - 0.12, z + 0.14), (0.40, 0.2, 0.26), BLACK)
    z += hh
    b.box((0, 0, z + 0.05), (0.66, 0.66, 0.10), STONE2)
    z += 0.10
    b.box((0, 0, z + 0.12), (0.46, 0.46, 0.24), STONE)
    for (sx, sy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        d = 0.23 + 0.004
        bw.box((sx * d, sy * d, z + 0.12), (0.012, 0.22, 0.14) if sx else (0.22, 0.012, 0.14), BLACK)
    z += 0.24
    b.box((0, 0, z + 0.03), (0.60, 0.60, 0.06), STONE2)
    z += 0.06
    hip_roof(b, 0, 0, z, 0.52, 0.52, 0.27, STONE2, lift=0.04, thick=0.09,
             tile_step=0.52, rib=0.0, sag=1.0, swell=0.02)
    z += 0.27
    b.revolve([(0.04, 0.0), (0.10, 0.06), (0.11, 0.14), (0.07, 0.22), (0.0, 0.25)],
              STONE2, segments=8, origin=(0, 0, z))
    return (b.to_object("Lantern_Stone"), bw.to_object("Lantern_Window"))


# ---------------------------------------------------------------------------
# kitsune
# ---------------------------------------------------------------------------

def _plinth(bs, w):
    """Soclu de piatra: placa, treapta, bloc din 2 asize cu rosturi, capac.
    Bloc plin, lat (decuparea): ~0.72 m inaltime."""
    z = 0.0
    for (ww, hh, sl) in ((1.00, 0.13, STONE), (0.90, 0.07, STONE)):
        bs.box((0, 0, z + hh * 0.5), (w * ww, w * ww * 0.88, hh), sl)
        z += hh
    for (ww, hh) in ((0.80, 0.22), (0.79, 0.20)):
        bs.box((0, 0, z + hh * 0.5), (w * ww, w * ww * 0.88, hh), STONE)
        z += hh
    bs.box((0, 0, z + 0.05), (w * 0.84, w * 0.84 * 0.88, 0.10), STONE2)
    return z + 0.10


def _rot_z(b, deg):
    R = Matrix.Rotation(math.radians(deg), 3, "Z")
    for v in b.bm.verts:
        v.co = R @ v.co


def _fox(bf, bb, z0, pose):
    """Vulpe sezand (fata spre +Y inainte de rotatia de poza). pose: tail_side."""
    ts = pose["tail_side"]
    W = FOAM_WHITE
    # corp: para mare (sezut), usor inclinat in fata
    body = [(0.0, -0.22, z0 + 0.10), (0.0, -0.15, z0 + 0.34),
            (0.0, -0.02, z0 + 0.64), (0.0, 0.08, z0 + 0.86)]
    bf.taper_sweep(body, [0.34, 0.32, 0.24, 0.15], W, segments=8)
    for s in (-1, 1):                                        # solduri
        bf.frustum((s * 0.20, -0.08, z0 + 0.20), 0.17, 0.12, 0.40, W, segments=6)
        # picior fata (subtire) si lab
        bf.taper_sweep([(s * 0.10, 0.14, z0 + 0.62), (s * 0.10, 0.19, z0 + 0.32),
                        (s * 0.10, 0.21, z0 + 0.02)], [0.068, 0.052, 0.058], W, segments=6)
        bf.box((s * 0.10, 0.26, z0 + 0.025), (0.12, 0.18, 0.05), W)
    # gat + cap (bot lung, urechi inalte)
    hy, hz = 0.14, z0 + 1.00
    bf.taper_sweep([(0, 0.10, z0 + 0.80), (0, 0.13, z0 + 0.95)], [0.13, 0.11], W, segments=8)
    bf.box((0, hy, hz), (0.27, 0.24, 0.22), W)
    bf.taper_sweep([(0, hy + 0.08, hz - 0.02), (0, hy + 0.28, hz - 0.06)], [0.085, 0.04], W,
                   segments=6)
    bf.box((0, hy + 0.30, hz - 0.05), (0.05, 0.05, 0.05), BLACK)           # nas
    for s in (-1, 1):
        bf.box((s * 0.085, hy + 0.12, hz + 0.04), (0.03, 0.03, 0.03), BLACK)  # ochi
        bf.frustum((s * 0.085, hy - 0.02, hz + 0.20), 0.07, 0.0, 0.24, W, segments=4)
    # coada mare, curbata in sus, groasa
    tail = [(0.0, -0.22, z0 + 0.10), (ts * 0.26, -0.42, z0 + 0.14), (ts * 0.46, -0.46, z0 + 0.38),
            (ts * 0.44, -0.34, z0 + 0.64), (ts * 0.32, -0.24, z0 + 0.92)]
    bf.taper_sweep(tail, [0.10, 0.17, 0.19, 0.14, 0.0], W, segments=6)
    # bavetă rosie: gulerul larg + triunghi pe piept
    bb.frustum((0, 0.12, z0 + 0.88), 0.27, 0.19, 0.22, CAR_RED, segments=8)
    bm = bb.bm
    cyp = 0.19
    vs = [bm.verts.new((-0.24, cyp + 0.04, z0 + 0.90)), bm.verts.new((0.24, cyp + 0.04, z0 + 0.90)),
          bm.verts.new((0.0, cyp + 0.08, z0 + 0.54)),
          bm.verts.new((-0.19, cyp - 0.06, z0 + 0.88)), bm.verts.new((0.19, cyp - 0.06, z0 + 0.88)),
          bm.verts.new((0.0, cyp - 0.02, z0 + 0.58))]
    bm.faces.new((vs[0], vs[2], vs[1]))
    bm.faces.new((vs[3], vs[4], vs[5]))
    for (i, j, k, l) in ((0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)):
        bm.faces.new((vs[i], vs[j], vs[k], vs[l]))
    bb._tag(vs, CAR_RED)


def _build_kitsune(pose):
    bf, bb, bs = Builder(), Builder(), Builder()
    z0 = _plinth(bs, 1.30)
    _fox(bf, bb, z0, pose)
    _rot_z(bf, pose["yaw"])
    _rot_z(bb, pose["yaw"])
    return (bf.to_object("Fox_Body"), bb.to_object("Fox_Bib"), bs.to_object("Fox_Stone"))


def build_kitsune_statue_a():
    """`kitsune_statue_a.png` -- lista de elemente:
    - soclu de piatra bej in 5 straturi (placa, treapta, 3 asize cu rosturi,
      capac), larg (~1.25 m la baza) si ~0.72 m inalt;
    - vulpe ALBA sezand, cap ridicat cu 2 urechi ascutite, bot lung, coada
      mare ridicata in stanga, doua picioare fata pe soclu;
    - BAVETA ROSIE (CAR_RED) la gat, triunghi pe piept;
    - cap intors usor spre stanga; ~1.9 m total.
    """
    return _build_kitsune(dict(yaw=42.0, tail_side=1))


def build_kitsune_statue_b():
    """`kitsune_statue_b.png` -- ca _a, dar vulpea e mai inclinata/rasucita:
    capul intors spre dreapta, coada pe partea DREAPTA (poza oglindita)."""
    return _build_kitsune(dict(yaw=-44.0, tail_side=-1))


# ---------------------------------------------------------------------------
# gable roof (chozuya / ema_rack)
# ---------------------------------------------------------------------------

def gable_roof(b, cx, cy, ze, hx, hy, rise, slot, fascia_slot, lift=0.0, thick=0.12,
               rib_step=0.34, rib=0.04, sag=1.4, ridge_cap=True, fill_slot=None,
               fill_inset=0.25):
    """Acoperis in doua ape cu creasta pe X, streasina concava; nervuri de tigla
    pe panta; capac de creasta. Capetele (frontoanele) sunt deschise sub tigla."""
    prof = []
    N = 6
    for i in range(N + 1):
        t = i / N                       # 0 streasina, 1 creasta
        y = hy * (1 - t)
        zt = ze + rise * (t ** (1.0 / sag)) * 0 + rise * (1.0 - (1.0 - t) ** sag) + lift * (1 - t) ** 2
        prof.append((y, zt))
    top = [(-y, z) for (y, z) in prof] + [(y, z) for (y, z) in reversed(prof[:-1])]
    # top: de la y=-hy (streasina) la creasta apoi y=+hy; fata de jos
    outline = [(cy + y, z) for (y, z) in top]
    bot = [(cy + y, z - thick) for (y, z) in reversed(top)]
    # grosime pe tot conturul (bucla): sus + jos
    outline = outline + [(y, z) for (y, z) in bot]
    extrude_x(b, outline, cx - hx, cx + hx, slot)
    # fateta streasinii (cap de lemn): o placa fina in capete, fascia
    for sgn in (-1, 1):
        b.box((cx + sgn * hx, cy, ze + rise * 0.35), (0.10, 2 * hy * 0.85, 0.06), fascia_slot)
    # nervuri de tigla pe fiecare versant
    nx = max(int(round(2 * hx / rib_step)), 2)
    for k in range(nx + 1):
        x = cx - hx + 2 * hx * k / nx
        for sgn in (-1, 1):
            p0 = (x, cy + sgn * hy, prof[0][1] + rib * 0.5)
            p1 = (x, cy + sgn * prof[-2][0], prof[-2][1] + rib * 0.5)
            b.beam(p0, p1, (rib, rib), slot)
    if fill_slot is not None:                 # frontoane umplute (lemn)
        tri = [(cy - hy * 0.85, ze - thick), (cy + hy * 0.85, ze - thick),
               (cy, ze + rise - thick - 0.03)]
        for sgn in (-1, 1):
            xx = cx + sgn * (hx - fill_inset)
            extrude_x(b, tri, xx - 0.05, xx + 0.05, fill_slot)
    if ridge_cap:
        b.box((cx, cy, ze + rise + 0.05), (2 * hx + 0.1, 0.20, 0.12), fascia_slot)
        for sgn in (-1, 1):
            b.box((cx + sgn * (hx + 0.05), cy, ze + rise + 0.12), (0.10, 0.22, 0.20), fascia_slot)


# ---------------------------------------------------------------------------
# small_shrine
# ---------------------------------------------------------------------------

def build_small_shrine():
    """`small_shrine.png` -- lista de elemente:
    - soclu de piatra inalt (~1.0 m), 2 randuri de pietre mari, mai larg
      decat corpul, cu capac deschis;
    - corp vermilion deschis: 4 stalpi de colt + intermediari, grinda
      groasa la mijloc, jos o BANDA de panou gri-albastrui (sticla), sus
      panouri luminoase cu grile pe fata, ferestre pe laturi;
    - acoperis mare gri in doua ape, creasta pe lungime, streasina curbata
      cu colturile ridicate, FRONTOANE vermilion la capete, ornamente rotunde
      la capetele crestei;
    - proportie: acoperis ~38% din inaltime, soclu ~30%.
    Cote: 3 x 2.6 x 3.4 m.
    """
    bw, br, bs = Builder(), Builder(), Builder()
    bh = 0.92
    bs.box((0, 0, bh * 0.5 - 0.02), (2.0, 1.8, bh - 0.04), STONE)
    rnd = _lcg(7)
    for ri, (z0, rh) in enumerate([(0.0, 0.46), (0.46, 0.46)]):
        for (axis, sgn) in (("x", 1), ("x", -1), ("y", 1), ("y", -1)):
            L = 2.0 if axis == "x" else 1.8
            ws = [0.8 + rnd() * 0.5 for _ in range(3 if ri == 0 else 4)]
            tot = sum(ws)
            xx = -L / 2
            for w in ws:
                ww = w / tot * L
                zz = z0 + rh * 0.5
                sl = STONE if rnd() > 0.3 else STONE2
                if axis == "x":
                    bs.box((xx + ww * 0.5, sgn * 0.93, zz), (ww - 0.05, 0.14, rh - 0.05), sl)
                else:
                    bs.box((sgn * 1.03, (xx + ww * 0.5) * 0.9, zz), (0.14, ww * 0.9 - 0.05, rh - 0.05), sl)
                xx += ww
    bs.box((0, 0, bh + 0.04), (2.2, 2.0, 0.08), FOAM_WHITE)
    zf = bh + 0.08
    hx, hy = 0.80, 0.68
    bhz = 1.0
    bw.box((0, 0, zf + 0.04), (2 * hx + 0.3, 2 * hy + 0.3, 0.08), DARKW)
    for sx in (-1, 1):
        for sy in (-1, 1):
            bw.box((sx * hx, sy * hy, zf + bhz * 0.5), (0.15, 0.15, bhz), VERM)
    for sx in (-0.33, 0.33):
        bw.box((sx * hx * 2 * 0.5, hy, zf + bhz * 0.5), (0.10, 0.10, bhz), VERM)
        bw.box((sx * hx * 2 * 0.5, -hy, zf + bhz * 0.5), (0.10, 0.10, bhz), VERM)
    bw.box((hx, 0, zf + bhz * 0.5), (0.10, 0.10, bhz), VERM)
    bw.box((-hx, 0, zf + bhz * 0.5), (0.10, 0.10, bhz), VERM)
    for zz, th in ((zf + bhz - 0.05, 0.16), (zf + 0.48, 0.12), (zf + 0.12, 0.10)):
        frame_ring(bw, 0, 0, zz, hx + 0.04, hy + 0.04, th, 0.14, VERM)
    zlo0, zlo1 = zf + 0.14, zf + 0.46
    zup0, zup1 = zf + 0.62, zf + bhz - 0.07
    for (px, py, sx_, sy_) in ((0, hy, 2 * hx - 0.1, 0.05), (0, -hy, 2 * hx - 0.1, 0.05),
                               (hx, 0, 0.05, 2 * hy - 0.1), (-hx, 0, 0.05, 2 * hy - 0.1)):
        bw.box((px, py, (zlo0 + zlo1) * 0.5), (sx_, sy_, zlo1 - zlo0), PAINTED)
        bw.box((px, py, (zup0 + zup1) * 0.5), (sx_, sy_, zup1 - zup0), FOAM_WHITE)
        if sy_ == 0.05:
            for mx in (-0.27, 0.27):
                bw.box((mx, py * 1.02, (zup0 + zup1) * 0.5), (0.05, 0.06, zup1 - zup0), VERM)
    ze = zf + bhz + 0.14
    gable_roof(br, 0, 0, ze, 1.55, 1.38, 1.22, TILE, DARKW, lift=0.46, thick=0.16,
               rib_step=0.40, rib=0.035, sag=1.5, ridge_cap=False, fill_slot=VERM,
               fill_inset=0.28)
    br.box((0, 0, ze + 1.22 + 0.04), (3.0, 0.24, 0.16), DARKW)
    for sx in (-1, 1):
        br.frustum((sx * 1.55, 0, ze + 1.30), 0.15, 0.12, 0.26, DARKW, segments=8, axis="Y")
    return (bw.to_object("Shrine_Wood"), br.to_object("Shrine_Roof"),
            bs.to_object("Shrine_Stone"))


def np_sign(v):
    return 1.0 if v >= 0 else -1.0


# ---------------------------------------------------------------------------
# ema_rack
# ---------------------------------------------------------------------------

def build_ema_rack():
    """`ema_rack.png` -- lista de elemente:
    - cadru de lemn brun: 2 stalpi inalti, fiecare pe un picior lat (talpa)
      care iese in fata si in spate; grinda sus;
    - acoperis mic, gri-inchis, usor in doua ape, iesit peste stalpi;
    - 4 randuri de sipci orizontale intunecate, pe fiecare atarna 6 PLACUTE
      goale (bej-portocalii, in forma de casuta/pentagon), fara text;
    - 2 fete cu placute (placutele se vad din ambele parti).
    Cote: 3.2 x 0.5 (talpa 1.0) x 2.4 m.
    """
    bw, bd, br, bp = Builder(), Builder(), Builder(), Builder()
    hx = 1.45
    for s in (-1, 1):
        bw.box((s * hx, 0, 1.05), (0.20, 0.26, 2.1), LIGHTW)                    # stalp
        bw.box((s * hx, 0, 0.07), (0.30, 0.78, 0.14), DARKW)                     # talpa
        bw.box((s * hx, 0, 0.17), (0.20, 0.30, 0.07), DARKW)
    bw.box((0, 0, 2.06), (2 * hx + 0.1, 0.16, 0.14), DARKW)                     # grinda sus
    bw.box((0, 0, 0.45), (2 * hx, 0.10, 0.07), DARKW)                            # grinda jos
    rows = [1.84, 1.52, 1.20, 0.88]
    cols = 6
    pitch = (2 * hx - 0.5) / cols
    rnd = _lcg(3)
    for r, zr in enumerate(rows):
        bd.box((0, 0, zr), (2 * hx, 0.07, 0.05), DARKW)                         # sipca
        for c in range(cols):
            x = -hx + 0.25 + pitch * (c + 0.5)
            for side in (-1, 1):
                w, h = 0.35, 0.34 + (rnd() - 0.5) * 0.04
                sl = SAND_MID if rnd() > 0.28 else SAND_LIGHT
                bp.prism([(-w / 2, 0), (w / 2, 0), (w / 2, h * 0.72), (0, h), (-w / 2, h * 0.72)],
                         0.03, sl, center=(x + (rnd() - 0.5) * 0.03, side * 0.075,
                                           zr - h - 0.04 + (0.0)))
    # acoperis scund (streasina larga), creasta pe X
    gable_roof(br, 0, 0, 2.14, hx + 0.25, 0.36, 0.14, TILE, DARKW, lift=0.04,
               thick=0.07, rib_step=0.45, rib=0.012, sag=1.0, ridge_cap=False)
    return (bw.to_object("Ema_Wood"), bd.to_object("Ema_Rails"), br.to_object("Ema_Roof"),
            bp.to_object("Ema_Plaques"))


# ---------------------------------------------------------------------------
# bell_tower
# ---------------------------------------------------------------------------

def build_bell_tower():
    """`bell_tower.png` -- lista de elemente:
    - pavilion deschis pe 4 stalpi de lemn brun INCLINATI spre interior, pe
      talpi de piatra; traverse joase si grinzi inchise sus;
    - acoperis mare gri in DOUA APE (creasta pe X), streasina curbata cu
      capetele ridicate, ornament rotund la capetele crestei; frontoane
      deschise cu ferme de lemn (doua capriori, popi central, tirant);
    - CLOPOT de bronz verde mare (~1.9 m lat), butoi cu umar, 3 benzi,
      atarnat de grinda centrala.
    Cote: ~6 m inaltime.
    """
    bw, bk, br, bs, bb = Builder(), Builder(), Builder(), Builder(), Builder()
    for sx in (-1, 1):
        for sy in (-1, 1):
            bs.box((sx * 2.25, sy * 2.25, 0.10), (0.66, 0.66, 0.20), STONE)
            bw.beam((sx * 2.25, sy * 2.25, 0.2), (sx * 1.82, sy * 1.82, 3.85), 0.32, LIGHTW)
    for zz in (0.85, 3.68):
        px = 2.25 + (1.82 - 2.25) * (zz / 3.85)
        for s_ in (-1, 1):
            tgt = bw if zz < 2 else bk
            slot = LIGHTW if zz < 2 else DARKW
            tgt.box((0, s_ * px, zz), (2 * px, 0.20, 0.22), slot)
            tgt.box((s_ * px, 0, zz), (0.20, 2 * px, 0.22), slot)
    bk.box((0, 0, 3.70), (0.30, 3.7, 0.24), DARKW)
    bk.box((0, 0, 3.84), (4.2, 0.26, 0.20), DARKW)
    prof = [(0.98, 0.0), (0.95, 0.12), (0.88, 0.5), (0.84, 1.2), (0.78, 1.75),
            (0.62, 2.05), (0.30, 2.28), (0.0, 2.32)]
    prof = [(r, z * 0.88) for r, z in prof]
    zb = 0.95
    bb.revolve(prof, BRONZE, segments=10, origin=(0, 0, zb))
    for zr, rr in ((0.26, 0.97), (0.84, 0.89), (1.36, 0.83)):
        bb.frustum((0, 0, zb + zr), rr, rr, 0.09, CACTUS_GREEN, segments=10)
    bb.cylinder((0, 0, zb + 2.3), 0.10, 0.70, BRONZE, segments=6)
    ze = 3.90
    gable_roof(br, 0, 0, ze, 3.25, 2.75, 1.85, TILE, DARKW, lift=0.50, thick=0.22,
               rib_step=0.45, rib=0.045, sag=1.6, ridge_cap=False, fill_slot=None)
    br.box((0, 0, ze + 1.85 + 0.06), (6.5, 0.30, 0.20), DARKW)
    for sx in (-1, 1):
        br.frustum((sx * 3.25, 0, ze + 1.98), 0.20, 0.17, 0.36, DARKW, segments=8, axis="Y")
        xx = sx * 2.2
        for sy in (-1, 1):
            bk.beam((xx, sy * 1.9, ze - 0.05), (xx, sy * 0.15, ze + 1.55), 0.17, DARKW)
        bk.box((xx, 0, ze + 0.65), (0.18, 0.18, 1.9), DARKW)
        bk.box((xx, 0, ze + 0.12), (0.2, 3.9, 0.2), DARKW)
    return (bw.to_object("Bell_Wood"), bk.to_object("Bell_Beams"), br.to_object("Bell_Roof"),
            bb.to_object("Bell_Bronze"), bs.to_object("Bell_Stone"))


# ---------------------------------------------------------------------------
# chozuya
# ---------------------------------------------------------------------------

def build_chozuya():
    """`chozuya.png` -- lista de elemente:
    - acoperis mare in doua ape, gri-inchis, creasta pe lungime (X) cu cap
      gros, frontoane umplute cu lemn; nervuri de tigla pe panta;
    - 4 stalpi GROSI de lemn brun pe talpi de piatra, grinzi inchise sus;
    - bazin de piatra gri, lung si jos, pe placa; interior intunecat;
    - 3 CAUSE (hishaku) de bambus asezate in diagonala pe bazin.
    Cote: 3.2 x 2.2 x 2.8 m.
    """
    bw, bk, br, bs, bl = Builder(), Builder(), Builder(), Builder(), Builder()
    px, py = 1.30, 0.85
    for sx in (-1, 1):
        for sy in (-1, 1):
            bs.box((sx * px, sy * py, 0.08), (0.42, 0.42, 0.16), STONE)
            bw.box((sx * px, sy * py, 1.12), (0.25, 0.25, 2.00), LIGHTW)
    for s in (-1, 1):
        bk.box((0, s * py, 2.03), (2 * px + 0.5, 0.20, 0.26), DARKW)
        bk.box((s * px, 0, 2.03), (0.22, 2 * py, 0.26), DARKW)
        bk.box((0, s * py, 1.70), (2 * px, 0.12, 0.14), DARKW)
    gable_roof(br, 0, 0, 2.12, 1.62, 1.18, 0.92, TILE, DARKW, lift=0.16, thick=0.16,
               rib_step=0.30, rib=0.04, sag=1.5, fill_slot=DARKW, fill_inset=0.3)
    bs.box((0, 0.1, 0.06), (2.55, 1.15, 0.12), STONE)
    zb = 0.12
    frame_ring(bs, 0, 0.1, zb, 1.05, 0.46, 0.46, 0.16, STONE2)
    bs.box((0, 0.1, zb + 0.08), (1.8, 0.7, 0.08), STONE2)
    for k, x in enumerate((-0.55, 0.0, 0.55)):
        z0 = zb + 0.46
        bl.beam((x + 0.05, 0.1 - 0.30, z0 + 0.04), (x - 0.62, 0.1 + 0.05, z0 + 0.55), 0.05, SAND_MID)
        bl.frustum((x + 0.12, 0.1 - 0.33, z0 + 0.03), 0.075, 0.06, 0.09, SAND_MID, segments=6)
    return (bw.to_object("Choz_Wood"), bk.to_object("Choz_Beams"), br.to_object("Choz_Roof"),
            bs.to_object("Choz_Stone"), bl.to_object("Choz_Ladles"))


# ---------------------------------------------------------------------------
# cyclopean_wall
# ---------------------------------------------------------------------------

def build_cyclopean_wall():
    """`cyclopean_wall.png` -- lista de elemente:
    - zid taluzat lung de 8 m, ~4 m inalt, 2.5 m la baza si ~1.2 sus; capete
      PLANE la x = +-4 (se inlantuie), miez inchis la culoare (rosturi/capat);
    - 4 randuri de pietre poligonale MARI, rotunjite, aproape lipite (rosturi
      subtiri), pe ambele fete; sus un rand de lespezi dreptunghiulare;
    - MUSCHI (nod separat Cyc_Moss) in rosturi, mai mult la baza.
    """
    bs, bm_ = Builder(), Builder()
    L, H = 8.0, 4.0
    yb, yt = 1.25, 0.60
    slope = (yt - yb) / H
    extrude_x(bs, [(-yb, 0.0), (yb, 0.0), (yt, H - 0.2), (-yt, H - 0.2)], -L / 2, L / 2, ASPHALT_EDGE)
    rnd = _lcg(11)
    row_h = [0.98, 0.94, 0.90, 0.84]
    z = 0.0
    moss_spots = []
    for ri, rh in enumerate(row_h):
        zc = z + rh * 0.5
        y_plane = yb + slope * zc
        for side in (1, -1):
            x = -L / 2
            wl = []
            while x < L / 2 - 0.3:
                w = 1.25 + rnd() * 0.75
                w = min(w, L / 2 - x)
                if L / 2 - (x + w) < 0.9:
                    w = L / 2 - x
                wl.append(w)
                x += w
            x = -L / 2
            for si, w in enumerate(wl):
                hz = rh * (0.98 + rnd() * 0.06)
                sl = STONE if rnd() > 0.3 else STONE2
                poly_block(bs, (x + w * 0.5, side * (y_plane - 0.08), zc + (rnd() - 0.5) * 0.05),
                           min(w * 0.5 * 1.12, L / 2 - abs(x + w * 0.5)), hz * 0.5 * 1.14, 0.34, sl, n=7 if rnd() > 0.4 else 8,
                           seed=ri * 100 + si * 2 + (side > 0), slope=slope * side,
                           round_f=0.90, jit=0.05, facing=side)
                if side == 1 and rnd() < 0.95 - ri * 0.1:
                    moss_spots.append((x + w, z + 0.15 + rnd() * 0.3, y_plane))
                x += w
        z += rh
    nc = 5
    cw = L / nc
    for k in range(nc):
        bs.box((-L / 2 + cw * (k + 0.5), 0, H - 0.17), (cw - 0.06, 2 * yt + 0.06, 0.46), STONE2)
    mrnd = _lcg(5)
    for (mx, mz, yp) in moss_spots:
        r = 0.30 + mrnd() * 0.20
        mx = max(-L / 2 + r, min(L / 2 - r, mx))
        mz = max(mz, r * 0.8 + 0.03)
        for side in (1, -1):
            if side == 1 or mrnd() < 0.5:
                poly_block(bm_, (mx, side * (yp + 0.02), mz), r, r * 0.8, 0.14, MOSS, n=7,
                           seed=int(mx * 100) + side, slope=slope * side, round_f=0.8, facing=side)
    return (bs.to_object("Cyc_Stone"), bm_.to_object("Cyc_Moss"))


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def go(objs, path, ao, budget):
    emit(objs, path, ao, bevel=0.0, smooth_angle=None, budget=budget)
    for o in objs:                       # nume de noduri unice in GLB (fara .001)
        bpy.data.objects.remove(o, do_unlink=True)


if __name__ == "__main__" or True:
    go(build_votive_torii_cluster(), "structures/votive_torii_cluster.glb", AO_BIG, 4500)
    go(build_stone_lantern_a(), "props/stone_lantern_a.glb", AO_SOFT, 900)
    go(build_stone_lantern_b(), "props/stone_lantern_b.glb", AO_SOFT, 900)
    go(build_yukimi_lantern(), "props/yukimi_lantern.glb", AO_SOFT, 900)
    go(build_kitsune_statue_a(), "props/kitsune_statue_a.glb", AO_SOFT, 1400)
    go(build_kitsune_statue_b(), "props/kitsune_statue_b.glb", AO_SOFT, 1400)
    go(build_small_shrine(), "structures/small_shrine.glb", AO_BIG, 3500)
    go(build_ema_rack(), "props/ema_rack.glb", AO_SOFT, 1800)
    go(build_bell_tower(), "structures/bell_tower.glb", AO_BIG, 2500)
    go(build_chozuya(), "props/chozuya.glb", AO_BIG, 2000)
    go(build_cyclopean_wall(), "structures/cyclopean_wall.glb", AO_BIG, 6000)
    report()
