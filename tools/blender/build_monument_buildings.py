"""Monument Valley -- cladiri (brief docs/asset_briefs/monumentvalley_kit.md §1.5).

  monumentvalley/buildings/trading_post.glb      post de negot din piatra, 12 x 9 m, prispa pe +Y
  monumentvalley/buildings/homestead_house.glb   casa de scanduri in doua ape, 7 x 9 m, prispa pe +Y
  monumentvalley/buildings/hogan.glb             hogan cu EXACT 8 laturi, diametru 7 m, usa spre +Y

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_buildings.py

Fara firma, text sau cifre (brief §0 pct. 9). Fata bogata = +Y in Blender
(= -Z in Godot); se MASOARA pe GLB cu tools/blender/measure_front_glb.py.
Originea: centrul amprentei pe XY, baza pe Z=0.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "monument_shapes.py")).read())
exec(open(os.path.join(_here, "monument_pen.py")).read())

STONE, STONE_LT = SAND_MID, SAND_LIGHT         # piatra (1) / piatra deschisa (0): comparatia a cerut tonul palid
TIMBER, TIMBER_OLD = WOOD, LOG_DARK            # lemn (9) / lemn umbrit (28)
ROOF_TIN = ASPHALT_EDGE                        # acoperis de tabla/carton (6)
HOLE = VOLCANIC_BLACK                          # goluri (20)

clear_built()
AO_BLD = dict(samples=16, dist=1.6, gradient="vertical",
              low=0.62, high=1.0, power=0.8, floor=0.30)


def opening_pair(ph, pw, cx, cz, w, h, y, bars=True, frame=0.12, dark=None, fslot=None):
    """Gol (fereastra/usa) pe un perete a carui fata locala e la `y` (+Y spre
    exterior): panoul intunecat pe `ph` (nodul de goluri), rama de lemn pe 4
    laturi si (optional) un montant pe `pw`."""
    dark = HOLE if dark is None else dark
    fs = TIMBER if fslot is None else fslot
    ph.box((cx, y + 0.03, cz), (w, 0.08, h), dark)
    pw.box((cx, y + 0.07, cz + h / 2 + frame / 2), (w + 2 * frame, 0.14, frame), fs)
    pw.box((cx, y + 0.07, cz - h / 2 - frame / 2), (w + 2 * frame, 0.14, frame), fs)
    for sx in (-1, 1):
        pw.box((cx + sx * (w / 2 + frame / 2), y + 0.07, cz), (frame, 0.14, h + 2 * frame), fs)
    if bars:
        pw.box((cx, y + 0.09, cz), (0.07, 0.12, h), fs)


def side_pens(bh, bw, y, x_face, yaw):
    """Doua penite (goluri, lemn) pentru un perete lateral: local +Y = spre
    exterior (+X pentru yaw=-90, -X pentru yaw=+90), `y` = pozitia pe perete."""
    M = at(0, y, 0.0, yaw) @ Matrix.Translation((0, x_face, 0))
    return Pen(bh, M), Pen(bw, M)


def stone_stack(pen, cx, cy, size, z0, z1, course, slots):
    """Cos de piatra: randuri de ~`course` m pe doua sloturi alternante, fiecare
    rand putin iesit in cruce, ca zidaria sa citeasca din umbra."""
    n = max(1, int(round((z1 - z0) / course)))
    ch = (z1 - z0) / n
    for k in range(n):
        o = 0.05 if k % 2 else 0.0
        pen.box((cx, cy, z0 + ch * (k + 0.5)), (size + o, size + o, ch * 0.98), slots[k % 2])


# ---------------------------------------------------------------------------
# 1. trading_post
# ---------------------------------------------------------------------------

def build_trading_post():
    """`trading_post.png` (acoperis in patru ape, jos, tan: corectura coordonatorului
    fata de contractul initial, vezi kit §1.5). Lista de elemente (numarata pe decupare):
    - CORP: 1 volum de piatra deschisa 11,0 x 6,4 m (decupare: zid de blocuri
      mari), pe un soclu, cu pietre de colt alternante (7 randuri x 4 colturi);
    - ACOPERIS in PATRU APE, jos (pante ~20 grade), streasina de ~0,6 m, mijloc
      plat, tan (SAND_MID); acoperisul prispei il continua (lean-to);
    - PRISPA pe fata +Y: duscheata de lemn, 5 stalpi rotunzi (decupare: 5),
      grinda continua, 1 treapta in fata;
    - FATA: 1 usa la mijloc (intunecata, rama de lemn), 2 ferestre (cate una de
      o parte si de alta a usii), 1 fereastra pe fiecare perete lateral;
    - COS: 1 cos de piatra ~1,6 x 1,6 m, gros, felii pe ROCK_LIGHT/SAND_LIGHT,
      calota in 2 trepte si gura neagra, spate-stanga pe acoperis (decupare: central-spate).
    Fara firma si fara text. Noduri: Post_Stone, Post_Wood, Post_Roof, Post_Openings.
    """
    st, wd, rf, ho = Builder(), Builder(), Builder(), Builder()
    S, W_, R, H = Pen(st), Pen(wd), Pen(rf), Pen(ho)
    cy = -1.0                                      # centrul corpului pe Y (corp y -4.2..2.2)
    FW = 2.2                                       # fata corpului (spre +Y)
    S.box((0, cy, 0.15), (11.4, 6.8, 0.3), ROCK_LIGHT)                      # soclu
    S.box((0, cy, 0.3 + 2.075), (11.0, 6.4, 4.15), SAND_LIGHT)              # pereti
    for sx in (-1, 1):                                                      # pietre de colt
        for sy in (-1, 1):
            for k in range(7):
                S.box((sx * 5.48, cy + sy * 3.18, 0.6 + k * 0.6), (0.5, 0.5, 0.58),
                      ROCK_LIGHT if k % 2 == 0 else SAND_MID)
    # acoperis in patru ape: streasina (fascie) + panta ~20 grade + mijloc plat
    hx, hy = 5.5 + 0.6, 3.2 + 0.6
    R.loft(rect_(hx, hy), 4.36, rect_(hx, hy), 4.52, SAND_MID, cap_bottom=True)
    ix, iy = hx - 1.9, hy - 1.9
    R.loft(rect_(hx, hy), 4.52, rect_(ix, iy), 4.52 + 1.9 * math.tan(math.radians(20.0)),
           SAND_MID, cap_bottom=False)
    ztop = 4.52 + 1.9 * math.tan(math.radians(20.0))
    cx_, cy_ = -2.6, cy - 0.7
    stone_stack(S, cx_, cy_, 1.6, 4.7, 7.0, 0.4, (ROCK_LIGHT, SAND_LIGHT))
    S.box((cx_, cy_, 7.1), (1.95, 1.95, 0.2), SAND_LIGHT)                   # calota, treapta 1
    S.box((cx_, cy_, 7.28), (1.75, 1.75, 0.16), ROCK_LIGHT)                 # calota, treapta 2
    H.box((cx_, cy_, 7.37), (0.9, 0.9, 0.05), HOLE)
    W_.box((0, 3.1, 0.2), (11.4, 1.8, 0.4), TIMBER)                         # prispa y 2.2..4.0
    W_.box((0, 4.15, 0.1), (3.0, 0.3, 0.2), TIMBER_OLD)                     # treapta pana la y 4.3
    for px in (-5.2, -2.6, 0.0, 2.6, 5.2):
        W_.tube((px, 3.8, 0.4), (px, 3.8, 3.88), 0.15, 0.13, TIMBER, seg=8)
    W_.box((0, 3.8, 3.95), (11.4, 0.3, 0.26), TIMBER_OLD)
    R.box((0, 3.3, 4.12), (12.2, 2.3, 0.14), SAND_MID, rot=Matrix.Rotation(-0.13, 3, "X"))
    opening_pair(H, W_, 0.0, 1.6, 1.5, 2.4, FW, bars=False)                 # usa (fata +Y)
    for fx in (-3.4, 3.4):
        opening_pair(H, W_, fx, 2.0, 1.4, 1.4, FW, bars=True)               # 2 ferestre
    for yaw in (-90.0, 90.0):                                               # ferestre laterale
        ph, pw = side_pens(ho, wd, cy, 5.5, yaw)
        opening_pair(ph, pw, 0.0, 2.1, 1.3, 1.3, 0.0, bars=True)
    return [st.to_object("Post_Stone"), wd.to_object("Post_Wood"),
            rf.to_object("Post_Roof"), ho.to_object("Post_Openings")]


def rect_(hx, hy):
    """Dreptunghi centrat, antiorar (semi-latimi hx, hy)."""
    return [(-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)]


# ---------------------------------------------------------------------------
# 2. homestead_house
# ---------------------------------------------------------------------------

def build_homestead_house():
    """`homestead_house.png`. Lista de elemente (numarata pe decupare):
    - CORP: 1 casa de scanduri, 6,6 x 7,5 m, pereti 2,7 m, pe soclu de piatra
      scund; 6 randuri de scanduri orizontale (nervuri) pe fiecare perete;
    - ACOPERIS in 2 ape, coama de-a lungul lui Y la 5,5 m, 2 pante de tabla
      gri, capac de coama; fronton triunghiular pe fata +Y (si pe spate);
    - PRISPA MICA pe fata +Y: duscheata, 4 stalpi, acoperis lean-to jos;
    - FATA: 1 usa, 2 ferestre langa usa, 1 geam mic in fronton; PE LATURI:
      2 ferestre pe fiecare perete lung (decupare: 2 pe dreapta);
    - COS: 1 cos de piatra pe panta din dreapta, 2 sloturi, ~0,8 m grosime.
    Noduri: Home_Walls, Home_Stone, Home_Wood, Home_Roof, Home_Openings.
    """
    wl, sn, wd, rf, ho = Builder(), Builder(), Builder(), Builder(), Builder()
    L, S, W_, R, H = Pen(wl), Pen(sn), Pen(wd), Pen(rf), Pen(ho)
    cy = -0.75                                       # corp y -4.5..3.0
    S.box((0, cy, 0.15), (7.0, 7.8, 0.3), STONE)                          # soclu
    L.box((0, cy, 0.3 + 1.35), (6.6, 7.5, 2.7), CONCRETE)                 # pereti
    for k in range(6):                                                    # nervuri de scandura
        z = 0.65 + 0.42 * k
        for sx in (-1, 1):
            L.box((sx * 3.32, cy, z), (0.06, 7.5, 0.08), STONE_LT)
        for yy in (3.02, -4.52):
            L.box((0, yy, z), (6.6, 0.06, 0.08), STONE_LT)
    gable = [(-3.3, 3.0), (3.3, 3.0), (0.0, 5.25)]
    wl.prism(gable, 0.12, CONCRETE, center=(0, 3.0, 0))                   # fronton +Y
    wl.prism(gable, 0.12, CONCRETE, center=(0, -4.5, 0))                  # fronton spate
    th = math.atan2(2.5, 3.5)
    NS = 8                                                                # benzi de sindrila pe panta
    for sx in (-1, 1):                                                    # 2 ape
        for i in range(NS):
            t = (i + 0.5) / NS
            pc = (sx * 3.5 * (1 - t), cy, 2.9 + 2.5 * t)
            R.box(pc, (4.3 / NS * 1.04, 7.6, 0.14 if i % 2 == 0 else 0.17), WOOD if i % 2 == 0 else LOG_DARK,
                  rot=Matrix.Rotation(sx * th, 3, "Y"))
    W_.box((0, cy, 5.45), (0.3, 7.7, 0.18), TIMBER_OLD)                   # capac de coama
    stone_stack(S, 2.1, -2.6, 0.85, 3.3, 6.4, 0.38, (STONE, STONE_LT))    # cos
    S.box((2.1, -2.6, 6.5), (1.05, 1.05, 0.18), STONE_LT)
    H.box((2.1, -2.6, 6.6), (0.5, 0.5, 0.05), HOLE)
    W_.box((0, 3.75, 0.15), (5.2, 1.5, 0.3), TIMBER)                      # prispa y 3.0..4.5
    for px in (-2.4, -0.8, 0.8, 2.4):
        W_.tube((px, 4.35, 0.3), (px, 4.35, 2.62), 0.09, 0.08, TIMBER, seg=8)
    W_.box((0, 4.35, 2.68), (5.2, 0.2, 0.18), TIMBER_OLD)
    for i in range(4):                                                    # acoperis prispa, sindrila
        R.box((0, 3.15 + 0.4 * i, 2.9 - 0.08 * i + 0.0), (5.6, 0.42, 0.1), WOOD if i % 2 == 0 else LOG_DARK,
              rot=Matrix.Rotation(-0.2, 3, "X"))
    opening_pair(H, W_, 0.0, 1.4, 1.0, 2.2, 3.0, bars=False)              # usa
    for fx in (-2.0, 2.0):
        opening_pair(H, W_, fx, 1.7, 0.9, 1.1, 3.0, bars=True)            # 2 ferestre
    opening_pair(H, W_, 0.0, 3.9, 0.5, 0.6, 3.06, bars=False, frame=0.07) # geam in fronton
    for yaw in (-90.0, 90.0):
        for wy in (-1.5, -3.4):
            ph, pw = side_pens(ho, wd, wy, 3.3, yaw)
            opening_pair(ph, pw, 0.0, 1.7, 0.9, 1.1, 0.0, bars=True)
    return [wl.to_object("Home_Walls"), sn.to_object("Home_Stone"), wd.to_object("Home_Wood"),
            rf.to_object("Home_Roof"), ho.to_object("Home_Openings")]


# ---------------------------------------------------------------------------
# 3. hogan
# ---------------------------------------------------------------------------

HOG_A = 3.5                                      # apotema (diametru 7 m intre laturi)


def _oct_ring(apothem):
    """Octogon (8 puncte, antiorar), laturile spre axe (usa pe +Y)."""
    r = apothem / math.cos(math.radians(22.5))
    return [(r * math.cos(math.radians(22.5 + 45 * k)), r * math.sin(math.radians(22.5 + 45 * k)))
            for k in range(8)]


def build_hogan():
    """`hogan.png`. Lista de elemente (numarata pe decupare):
    - PERETI: EXACT 8 laturi (octogon), 7 randuri de bustean orizontal pe
      fiecare latura (decupare: ~7), capetele iesite la colturi, rand pe rand
      pe doua sloturi (WOOD / LOG_DARK), miez intunecat sub busteni;
    - ACOPERIS de pamant: dom turtit in 2 trepte (panta abrupta jos, plata sus),
      SAND_MID, streasina peste pereti;
    - GURA DE FUM: guler scund de lemn in varf + gaura neagra (decupare: horn
      de lemn in varf);
    - USA pe latura +Y: 1 panou intunecat cu rama groasa, o treapta de bustean;
      1 fereastra mica pe latura vecina (decupare: stanga usii).
    Locuinta: nimic decorat, fara vopsea, fara ornamente. Noduri: Hogan_Logs,
    Hogan_Roof, Hogan_Openings.
    """
    lg, rf, ho = Builder(), Builder(), Builder()
    G, R, H = Pen(lg), Pen(rf), Pen(ho)
    side = 2 * HOG_A * math.tan(math.radians(22.5))
    ring_in = _oct_ring(HOG_A - 0.18)
    G.loft(ring_in, 0.0, ring_in, 2.42, TIMBER_OLD)                          # miez
    rl = 0.17
    for i in range(7):
        z = 0.19 + 0.34 * i
        for k in range(8):
            ang = math.radians(90 + 45 * k)
            n = Vector((math.cos(ang), math.sin(ang), 0))
            t = Vector((-n.y, n.x, 0))
            c = n * (HOG_A - rl) + Vector((0, 0, z))
            half = side / 2 + 0.2 + (0.04 if (i + k) % 2 else 0.0)
            G.tube(c - t * half, c + t * half, rl, rl, TIMBER if (i + k) % 2 == 0 else TIMBER_OLD, seg=8)
    R.loft(_oct_ring(HOG_A + 0.15), 2.42, _oct_ring(2.5), 2.98, SAND_MID)    # panta jos
    R.loft(_oct_ring(2.5), 2.98, _oct_ring(0.8), 3.32, SAND_MID, cap_bottom=False)
    G.loft(_oct_ring(0.8), 3.32, _oct_ring(0.7), 3.48, TIMBER)               # guler
    H.loft(_oct_ring(0.5), 3.47, _oct_ring(0.5), 3.5, HOLE)                  # gaura de fum
    opening_pair(G, G, 0.0, 0.1 + 0.95, 1.0, 1.9, HOG_A + 0.02, bars=True, frame=0.14,
                 dark=TIMBER, fslot=TIMBER_OLD)                                    # usa +Y: scandura de lemn
    G.box((0, HOG_A + 0.22, 0.09), (1.4, 0.35, 0.18), TIMBER_OLD)             # treapta
    M = at(0, 0, 0.0, 45.0) @ Matrix.Translation((0, HOG_A + 0.02, 0))        # latura vecina
    opening_pair(Pen(ho, M), Pen(lg, M), 0.0, 1.35, 0.7, 0.7, 0.0, bars=True, frame=0.1)
    return [lg.to_object("Hogan_Logs"), rf.to_object("Hogan_Roof"), ho.to_object("Hogan_Openings")]


# ---------------------------------------------------------------------------
# rulare
# ---------------------------------------------------------------------------

PIECES = [
    ("buildings/trading_post.glb", build_trading_post, dict(AO_BLD, dist=2.0), 9000),
    ("buildings/homestead_house.glb", build_homestead_house, dict(AO_BLD, dist=1.8), 9000),
    ("buildings/hogan.glb", build_hogan, dict(AO_BLD, dist=1.4), 9000),
]

import sys as _sys
_only = None
if "--only" in _sys.argv:
    _only = _sys.argv[_sys.argv.index("--only") + 1].split(",")

for _path, _fn, _ao, _bud in PIECES:
    if _only and os.path.basename(_path)[:-4] not in _only:
        continue
    clear_built()
    emit(list(_fn()), _path, _ao, keep_xy=True, bevel=0.0, smooth_angle=None, budget=_bud)
report()
