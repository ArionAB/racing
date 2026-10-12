"""Okinawa v2 -- satul si portul (brief docs/asset_briefs/okinawa_kit_v2.md §1.4), ok-d.

  okinawa/buildings/ryukyu_house_a.glb     casa Ryukyu, 4 ape, curte 14 x 12  (PIESA-EROU)
  okinawa/buildings/ryukyu_house_b.glb     doua corpuri in L, curte 16 x 12
  okinawa/buildings/ryukyu_house_c.glb     casa mica, acoperis abrupt, curte 11 x 10 cu colt taiat
  okinawa/buildings/concrete_house_a.glb   cub de beton alb, doua niveluri, rezervor
  okinawa/buildings/concrete_house_b.glb   un nivel, tencuiala pastel, doua rezervoare
  okinawa/structures/harbour_quay.glb      modul de chei 12 m, originea la linia apei
  okinawa/structures/bus_stop_shelter.glb  refugiu cu acoperis de olane
  okinawa/props/vending_machine.glb        automat alb, fara text
  okinawa/props/convex_mirror.glb          oglinda convexa de curba
  okinawa/props/fishing_net_rack.glb       suport de plase

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_okinawa_village.py

OK_ONLY=<piesa> reface doar piesa respectiva. Fara text, cifre sau logo-uri
(regula 9). FATA = +Y in Blender (= -Z in Godot): intrarea curtii, prispa si
usile; se MASOARA pe GLB (tools/blender/measure_front.py), nu se presupune.
Fara vegetatie lipita pe cladiri/ziduri (corectura de coordonator): tufele si
palmierii de pe plansa se pun separat la integrare.

Originea: casele = centrul curtii pe XY, baza la Z=0 (`--origin=assembly`);
cheiul = linia apei la Z=0 (`--origin=waterline`).
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


def _drop(objs):
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)


def _ao(top, dist=2.2, low=0.6, floor=0.3):
    return dict(samples=16, dist=dist, gradient="vertical", low=low, high=1.0,
                power=0.8, floor=floor, z_range=(0.0, top))


# ---------------------------------------------------------------------------
# curtea Ryukyu: zid de corali jur-imprejur, intrare fara poarta, hinpun
# ---------------------------------------------------------------------------

def _offset_poly(poly, off):
    """Poligon CCW deplasat spre interior cu `off` (intersectia dreptelor
    deplasate). Linia centrala a zidului sta la `off` = grosime/2 in interior,
    deci caseta curtii ramane exact cea din contract."""
    n = len(poly)
    lines = []
    for i in range(n):
        a = Vector(poly[i])
        c = Vector(poly[(i + 1) % n])
        d = (c - a).normalized()
        nrm = Vector((-d.y, d.x))
        lines.append((a + nrm * off, d))
    pts = []
    for i in range(n):
        p1, d1 = lines[i - 1]
        p2, d2 = lines[i]
        den = d1.x * d2.y - d1.y * d2.x
        s = ((p2.x - p1.x) * d2.y - (p2.y - p1.y) * d2.x) / den
        pts.append(p1 + d1 * s)
    return pts


def yard_walls(cr, poly, gap, height=1.35, thick=0.8, seed=11, pillar=0.85,
               pillar_h=1.8):
    """Zidul curtii pe poligonul CCW `poly`. `gap` = (index_latura, (x, y)
    centrul golului, latime): intrarea FARA POARTA, flancata de doi stalpi de
    corali mai inalti. Restul laturilor: zid continuu din pietre rotunjite."""
    pts = _offset_poly(poly, thick * 0.5)
    n = len(pts)
    gi, gc, gw = gap
    for i in range(n):
        a, c = pts[i], pts[(i + 1) % n]
        d = c - a
        L = d.length
        d.normalize()
        if i == gi:
            t = (Vector(gc) - a).dot(d)
            g0, g1 = t - gw * 0.5, t + gw * 0.5
            coral_wall_segment(cr, a, a + d * (g0 - pillar), height, thick, 5,
                               seed + i, stone_len=0.5, ext0=thick * 0.5)
            coral_wall_segment(cr, a + d * (g0 - pillar), a + d * g0, pillar_h, pillar,
                               7, seed + 40 + i, stone_len=0.4)
            coral_wall_segment(cr, a + d * g1, a + d * (g1 + pillar), pillar_h, pillar,
                               7, seed + 50 + i, stone_len=0.4)
            coral_wall_segment(cr, a + d * (g1 + pillar), c, height, thick, 5,
                               seed + 20 + i, stone_len=0.5, ext1=thick * 0.5)
        else:
            coral_wall_segment(cr, a, c, height, thick, 5, seed + i, stone_len=0.5,
                               ext0=thick * 0.5, ext1=thick * 0.5)


def hinpun(cr, cx, cy, along, length=3.0, height=1.6, thick=0.6, seed=70):
    """Paravanul *hinpun*: zid scurt, liber, intre intrare si usa (contract:
    3 x 1,6 m). `along` = 'x' sau 'y' (directia lungimii)."""
    if along == "x":
        p0, p1 = (cx - length * 0.5, cy), (cx + length * 0.5, cy)
    else:
        p0, p1 = (cx, cy - length * 0.5), (cx, cy + length * 0.5)
    coral_wall_segment(cr, p0, p1, height, thick, 6, seed, stone_len=0.45)


# ---------------------------------------------------------------------------
# casa Ryukyu
# ---------------------------------------------------------------------------

def _roof_z_under(roofs, x, y):
    zs = []
    for r in roofs:
        u, v = r.to_local(x, y)
        if abs(u) <= r.hu + 1e-3 and abs(v) <= r.hv + 1e-3:
            zs.append(r.z(x, y) - r.th - 0.03)
    return min(zs) if zs else None


def _opening(wd, side, c, w, z0, z1, slot_glass=LOG_DARK, frame=0.07):
    """Gol (usa/fereastra) pe peretele `side` ('+Y','-Y','+X','-X'), centrat pe
    `c` = (x, y) pe suprafata peretelui: placa inchisa la culoare + rama de
    lemn. Iese 4 cm din tencuiala."""
    h = z1 - z0
    zc = 0.5 * (z0 + z1)
    horiz = side in ("+Y", "-Y")
    sgn = 1.0 if side[0] == "+" else -1.0
    dx = (w, 0.08, h) if horiz else (0.08, w, h)
    off = (0.0, sgn * 0.02) if horiz else (sgn * 0.02, 0.0)
    wd.box((c[0] + off[0], c[1] + off[1], zc), dx, slot_glass)
    f = frame
    pos = ((0.0, 0.0, h * 0.5 - f * 0.5), (0.0, 0.0, -h * 0.5 + f * 0.5))
    for dz in (pos[0][2], pos[1][2]):
        size = (w + 2 * f, 0.12, f) if horiz else (0.12, w + 2 * f, f)
        wd.box((c[0] + off[0], c[1] + off[1], zc + dz), size, WOOD)
    for s in (-1, 1):
        size = (f, 0.12, h) if horiz else (0.12, f, h)
        px = c[0] + off[0] + (s * (w * 0.5 + f * 0.5) if horiz else 0.0)
        py = c[1] + off[1] + (0.0 if horiz else s * (w * 0.5 + f * 0.5))
        wd.box((px, py, zc), size, WOOD)


def _ryukyu_parts():
    return dict(rb=Builder(), mb=Builder(), pl=Builder(), wd=Builder(), cr=Builder(),
                sh=Builder())


def _mk_roof(P, spec):
    r = HipRoof(spec["cx"], spec["cy"], spec["hu"], spec["hv"], spec["z0"], spec["rise"],
                R=spec["R"], swap=spec.get("swap", False), lift=spec.get("lift", 0.3),
                th=0.17, curve=spec.get("curve", 1.0), tile_step=spec.get("step", 0.2),
                tile_amp=0.1)
    r.build(P["rb"], P["mb"], seams=False)
    return r


def _house_walls(P, roofs, rect, skip=(), thick=0.3):
    x0, x1, y0, y1 = rect
    sides = {"-Y": ((x0, y0), (x1, y0)), "+X": ((x1, y0), (x1, y1)),
             "+Y": ((x1, y1), (x0, y1)), "-X": ((x0, y1), (x0, y0))}
    for k, (a, c) in sides.items():
        if k in skip:
            continue
        wall_under_roof(P["pl"], a, c, roofs, FOAM_WHITE, thick=thick, top_max=2.7)


def _veranda(P, roofs, x0, x1, y_wall, depth, posts=None):
    """Prispa pe +Y: podea de lemn la 0,3 m, stalpi de lemn, grinda sub streasina."""
    wd = P["wd"]
    wd.box(((x0 + x1) * 0.5, y_wall + depth * 0.5, 0.15), (x1 - x0, depth, 0.3), WOOD)
    n = posts if posts else max(2, int(round((x1 - x0) / 1.7)) + 1)
    yp = y_wall + depth - 0.18
    tops = []
    for i in range(n):
        x = x0 + 0.2 + (x1 - x0 - 0.4) * i / (n - 1)
        zt = _roof_z_under(roofs, x, yp)
        if zt is None:
            continue
        wd.box((x, yp, (0.3 + zt) * 0.5), (0.2, 0.2, zt - 0.3), WOOD)
        wd.box((x, yp, 0.36), (0.3, 0.3, 0.12), LOG_DARK)   # piatra de sprijin
        tops.append((x, yp, zt))
    for a, c in zip(tops, tops[1:]):
        wd.beam((a[0], a[1], a[2] - 0.13), (c[0], c[1], c[2] - 0.13), (0.2, 0.26), LOG_DARK)


def _ridge_top(r):
    return r.ridge_z + r.tile_amp + 0.12 + 0.17


def build_ryukyu_house(key):
    """Casa Ryukyu. LISTA DE ELEMENTE (decuparile `ryukyu_house_{a,b,c}.png` +
    corecturile de coordonator din kit v2: SHISA pe coama, mortar in relief,
    hinpun, variante distincte, fara vegetatie lipita):

    a) casa 8 x 7 m (acoperis cu streasini), curte 14 x 12 m, varf ~5 m:
       - acoperis in 4 ape de olane cu nervuri in relief, streasini usor
         ridicate la colturi, coama scurta;
       - mortar alb IN RELIEF (`House_Mortar`): coama, 4 muchii de colt, bordura
         streasinii si ~30 de rosturi de la streasina la coama;
       - SHISA de teracota (0,6 m) pe varful coamei, cu fata spre +Y
         (`House_Shisa`) -- in locul manerului rosu de pe plansa;
       - pereti de tencuiala (`House_Plaster`), usi glisante inchise la culoare
         pe +Y, doua ferestre pe laturi, una in spate;
       - prispa pe +Y: podea de lemn, 5 stalpi de lemn sub streasina lata;
       - zid de corali (pietre rotunjite, asize mici) jur-imprejur, intrare FARA
         POARTA pe +Y flancata de doi stalpi de corali;
       - paravan HINPUN: zid liber 3 x 1,6 m, la 2 m in spatele intrarii;
       - fara tufe, palmieri, flori (se pun separat la integrare).
    b) doua corpuri in L (casa principala 10 m + anexa mai joasa pe flanc, cu
       acoperis perpendicular), curte 16 x 12, intrarea decalata spre stanga.
    c) casa mica 6 x 6 m, acoperis mai abrupt (panta + curbura mai mica), curte
       11 x 10 cu COLTUL taiat, intrarea pe latura +X (hinpun paralel cu ea).
    Noduri: House_Roof (TILE 23), House_Mortar (FOAM_WHITE 22), House_Wood (WOOD 9 /
    LOG_DARK 28), House_Coral (CORAL_SAND 19), House_Plaster (FOAM_WHITE 22),
    House_Shisa (TILE 23).
    """
    P = _ryukyu_parts()
    rb, mb, pl, wd, cr, sh = P["rb"], P["mb"], P["pl"], P["wd"], P["cr"], P["sh"]
    roofs = []
    if key == "a":
        roofs = [_mk_roof(P, dict(cx=0.0, cy=-1.0, hu=4.0, hv=3.5, z0=2.2, rise=1.95,
                                  R=0.8, lift=0.2))]
        _house_walls(P, roofs, (-3.0, 3.0, -3.4, 1.3))
        _veranda(P, roofs, -3.4, 3.4, 1.3, 1.25)
        wy = 1.3 + 0.15
        for i in range(3):
            _opening(wd, "+Y", (-2.05 + 2.05 * i, wy), 1.6, 0.4, 2.0)
        for sx, sy in ((1, -1.4), (-1, -1.4)):
            _opening(wd, "+X" if sx > 0 else "-X", (sx * 3.15, sy), 1.2, 0.8, 1.9)
        for x in (-1.4, 1.4):
            _opening(wd, "-Y", (x, -3.4 - 0.15), 1.0, 0.9, 1.9)
        poly = [(-7, -6), (7, -6), (7, 6), (-7, 6)]
        yard_walls(cr, poly, (2, (0.0, 6.0), 2.2))
        hinpun(cr, 0.0, 4.0, "x")
        shisa_roof = roofs[0]
    elif key == "b":
        main = _mk_roof(P, dict(cx=-2.25, cy=-1.5, hu=5.25, hv=3.5, z0=2.3, rise=2.2,
                                R=2.0, lift=0.2))
        ann = _mk_roof(P, dict(cx=4.8, cy=0.6, hu=3.0, hv=2.2, z0=2.1, rise=1.45,
                               R=0.9, lift=0.2, swap=True))
        roofs = [main, ann]
        _house_walls(P, roofs, (-6.5, 2.0, -4.0, 0.9))
        _house_walls(P, roofs, (2.0, 6.4, -1.6, 2.7), skip=("-X",))
        _veranda(P, [main], -6.4, 1.9, 0.9, 1.1)
        wy = 0.9 + 0.15
        for i in range(4):
            _opening(wd, "+Y", (-5.4 + 2.2 * i, wy), 1.6, 0.4, 2.0)
        _opening(wd, "+Y", (4.2, 2.7 + 0.15), 1.6, 0.4, 2.0)
        _opening(wd, "+X", (6.4 + 0.15, 0.5), 1.2, 0.8, 1.9)
        _opening(wd, "-X", (-6.5 - 0.15, -1.6), 1.2, 0.8, 1.9)
        for x in (-4.5, -1.5):
            _opening(wd, "-Y", (x, -4.0 - 0.15), 1.0, 0.9, 1.9)
        poly = [(-8, -6), (8, -6), (8, 6), (-8, 6)]
        yard_walls(cr, poly, (2, (-3.2, 6.0), 2.2), seed=21)
        hinpun(cr, -3.2, 4.1, "x", seed=71)
        shisa_roof = main
    else:
        roofs = [_mk_roof(P, dict(cx=-0.5, cy=-0.7, hu=3.0, hv=3.0, z0=1.9, rise=1.75,
                                  R=0.45, lift=0.15))]
        _house_walls(P, roofs, (-2.45, 1.45, -2.7, 1.2))
        _veranda(P, roofs, -2.6, 1.6, 1.2, 1.05, posts=4)
        wy = 1.2 + 0.15
        for i in range(2):
            _opening(wd, "+Y", (-1.5 + 2.2 * i, wy), 1.4, 0.4, 1.95)
        _opening(wd, "+X", (1.45 + 0.15, -0.8), 1.1, 0.8, 1.8)
        _opening(wd, "-X", (-2.45 - 0.15, -0.8), 1.1, 0.8, 1.8)
        _opening(wd, "-Y", (-0.5, -2.7 - 0.15), 1.1, 0.9, 1.8)
        # curtea 11 x 10 cu coltul (-X, +Y) taiat; intrarea pe latura +X
        poly = [(-5.5, -5.0), (5.5, -5.0), (5.5, 5.0), (-3.0, 5.0), (-5.5, 2.5)]
        yard_walls(cr, poly, (1, (5.5, 1.6), 2.0), seed=31)
        hinpun(cr, 3.4, 1.6, "y", seed=72)
        shisa_roof = roofs[0]

    sx, sy = shisa_roof.cx, shisa_roof.cy
    shisa_lion(sh, sx, sy, _ridge_top(shisa_roof) - 0.02, 1.0)
    top = max(_ridge_top(r) for r in roofs) + 0.62
    objs = [rb.to_object("House_Roof"), mb.to_object("House_Mortar"),
            pl.to_object("House_Plaster"), wd.to_object("House_Wood"),
            cr.to_object("House_Coral"), sh.to_object("House_Shisa")]
    return objs, top


def _emit_house(key, budget):
    objs, top = build_ryukyu_house(key)
    emit_ok_nodes(objs, "buildings/ryukyu_house_%s.glb" % key, _ao(top + 0.3, 2.4),
                  flat_suffixes=("_Coral",), keep_xy=True, bevel=0.0, smooth_angle=48.0,
                  budget=budget)
    _drop(objs)


for _k, _bud in (("a", 24000), ("b", 32000), ("c", 22000)):
    if _want("ryukyu_house_" + _k):
        _emit_house(_k, _bud)


# ---------------------------------------------------------------------------
# casele de beton
# ---------------------------------------------------------------------------

def _tank(cn, x, y, z, r=0.8, h=1.8, legs=0.7):
    """Rezervor cilindric de apa (segments 10) pe 4 picioare, cu doua cercuri
    si capac usor bombat. Baza picioarelor la `z`."""
    for sx in (-1, 1):
        for sy in (-1, 1):
            cn.box((x + sx * r * 0.62, y + sy * r * 0.62, z + legs * 0.5), (0.14, 0.14, legs), CONCRETE)
    cn.box((x, y, z + legs + 0.05), (r * 2.0, r * 2.0, 0.1), CONCRETE)
    cn.cylinder((x, y, z + legs + 0.1 + h * 0.5), r, h, CONCRETE, segments=10)
    cn.frustum((x, y, z + legs + 0.1 + h + 0.1), r * 0.97, r * 0.55, 0.2, CONCRETE, segments=10)
    cn.cylinder((x, y, z + legs + 0.1 + h + 0.28), 0.14, 0.16, CONCRETE, segments=6)
    for zz in (0.3, 0.75):
        cn.torus((x, y, z + legs + 0.1 + h * zz), r, 0.045, CONCRETE, major_seg=10, minor_seg=4)


def _shutter_window(wd, side, c, w, z0, z1):
    """Fereastra cu jaluzele ca forma: gol inchis + 5 lamele de lemn."""
    _opening(wd, side, c, w, z0, z1)
    horiz = side in ("+Y", "-Y")
    sgn = 1.0 if side[0] == "+" else -1.0
    for k in range(5):
        zz = z0 + (z1 - z0) * (k + 0.5) / 5
        size = (w, 0.09, 0.05) if horiz else (0.09, w, 0.05)
        pos = (c[0], c[1] + sgn * 0.06, zz) if horiz else (c[0] + sgn * 0.06, c[1], zz)
        wd.box(pos, size, WOOD)


def _parapet(pl, cn, W, D, H, ph, slot, thick=0.25):
    """Parapet (4 pereti de tencuiala) + coronament de beton subtire deasupra."""
    for sy in (-1, 1):
        pl.box((0, sy * (D * 0.5 - thick * 0.5), H + ph * 0.5), (W, thick, ph), slot)
    for sx in (-1, 1):
        pl.box((sx * (W * 0.5 - thick * 0.5), 0, H + ph * 0.5), (thick, D - 2 * thick, ph), slot)
    for sy in (-1, 1):
        cn.box((0, sy * (D * 0.5 - thick * 0.5), H + ph + 0.04), (W + 0.12, thick + 0.12, 0.08), CONCRETE)
    for sx in (-1, 1):
        cn.box((sx * (W * 0.5 - thick * 0.5), 0, H + ph + 0.04), (thick + 0.12, D - 2 * thick, 0.08), CONCRETE)


def build_concrete_house(key):
    """Casa de beton. LISTA DE ELEMENTE (decuparile `concrete_house_{a,b}.png`,
    kit §1.4; planșa le arata cu palmieri si tufe lipite: NU se modeleaza):
    a) cub alb 9 x 8 m, 6,5 m, DOUA niveluri (banda de planseu la 3,2 m);
       acoperis plat cu parapet (tencuiala) + coronament de beton; rezervor
       cilindric Ø1,6 x 1,8 m (10 segmente) pe 4 picioare pe acoperis; scara
       exterioara de beton pe flancul +X, cu palier si balustrada; usa de lemn +
       fereastra cu jaluzele la parter si 3 la etaj pe +Y; sarma de rufe pe
       acoperis (2 stalpi + 4 rufe).
    b) un nivel 8 x 7 m, 4 m, tencuiala PASTEL (FLAMINGO_PINK 31), parapet gros,
       doua rezervoare (Ø1,4 si Ø1,1) pe acoperis, usa + 2 ferestre pe +Y.
    Noduri: Concrete_Plaster (FOAM_WHITE 22 / FLAMINGO_PINK 31), Concrete_Concrete
    (CONCRETE 8: rezervoare, coronament, scara), Concrete_Wood (WOOD 9, LOG_DARK 28,
    rufele)."""
    pl, cn, wd = Builder(), Builder(), Builder()
    if key == "a":
        W, D, H, slot = 9.0, 8.0, 6.05, FOAM_WHITE
        pl.box((0, 0, H * 0.5), (W, D, H), slot)
        pl.box((0, 0, 3.2), (W + 0.16, D + 0.16, 0.16), slot)
        _parapet(pl, cn, W, D, H, 0.45, slot)
        y = D * 0.5 + 0.0
        _opening(wd, "+Y", (-2.4, y), 1.3, 0.1, 2.3)
        wd.box((-2.4, y + 0.05, 1.2), (1.1, 0.06, 2.0), WOOD)
        _shutter_window(wd, "+Y", (1.2, y), 1.5, 0.9, 2.2)
        for x in (-2.7, 0.0, 2.7):
            _shutter_window(wd, "+Y", (x, y), 1.4, 3.9, 5.3)
        for sx in (-1, 1):
            for yy in (-1.8, 1.8):
                side = "+X" if sx > 0 else "-X"
                _shutter_window(wd, side, (sx * W * 0.5, yy), 1.3, 0.9, 2.2)
                _shutter_window(wd, side, (sx * W * 0.5, yy), 1.3, 3.9, 5.3)
        _tank(cn, -2.6, -1.8, H + 0.1)
        # scara exterioara pe +X (urca spre +Y), palier la 3,2 m
        stair_wedge(cn, W * 0.5 + 0.05, W * 0.5 + 1.15, -3.6, 0.7, 3.2, 17, CONCRETE)
        cn.box((W * 0.5 + 0.6, 1.5, 3.1), (1.2, 1.6, 0.2), CONCRETE)
        cn.box((W * 0.5 + 0.6, 1.5, 1.55), (0.3, 0.3, 3.1), CONCRETE)
        cn.beam((W * 0.5 + 1.1, -3.6, 1.0), (W * 0.5 + 1.1, 0.7, 4.2), (0.07, 0.07), CONCRETE)
        cn.box((W * 0.5 + 1.1, 1.5, 3.7), (0.07, 1.6, 0.07), CONCRETE)
        zr = H + 0.5
        for x in (1.0, 3.8):
            wd.box((x, 2.2, zr + 0.5), (0.1, 0.1, 1.4), WOOD)
        wd.beam((1.0, 2.2, zr + 1.15), (3.8, 2.2, zr + 1.15), (0.03, 0.03), LOG_DARK)
        for xx, sl in ((1.45, REEF_SHALLOW), (2.1, FOAM_WHITE), (2.75, SAND_LIGHT), (3.35, KERB_RED)):
            wd.box((xx, 2.2, zr + 0.75), (0.45, 0.03, 0.75), sl)
        top = H + 0.1 + 0.7 + 0.1 + 1.8 + 0.5
    else:
        W, D, H, slot = 8.0, 7.0, 3.6, FLAMINGO_PINK
        pl.box((0, 0, H * 0.5), (W, D, H), slot)
        _parapet(pl, cn, W, D, H, 0.4, slot, thick=0.35)
        y = D * 0.5
        _opening(wd, "+Y", (-2.2, y), 1.2, 0.1, 2.3)
        wd.box((-2.2, y + 0.05, 1.2), (1.0, 0.06, 2.0), WOOD)
        for x in (0.5, 2.6):
            _shutter_window(wd, "+Y", (x, y), 1.3, 1.0, 2.5)
        for sx in (-1, 1):
            _shutter_window(wd, "+X" if sx > 0 else "-X", (sx * W * 0.5, 0.5), 1.2, 1.0, 2.5)
        _tank(cn, 1.8, -1.2, H + 0.1, r=0.7, h=1.6, legs=0.6)
        _tank(cn, -1.6, -2.0, H + 0.1, r=0.55, h=1.3, legs=0.5)
        cn.box((-2.2, 1.6, H + 0.1 + 0.3), (0.5, 0.5, 0.6), CONCRETE)
        top = H + 0.1 + 0.6 + 0.1 + 1.6 + 0.4
    objs = [pl.to_object("Concrete_Plaster"), cn.to_object("Concrete_Concrete"),
            wd.to_object("Concrete_Wood")]
    return objs, top


for _k, _bud in (("a", 6000), ("b", 5000)):
    if _want("concrete_house_" + _k):
        objs, top = build_concrete_house(_k)
        emit_ok_nodes(objs, "buildings/concrete_house_%s.glb" % _k, _ao(top, 2.4),
                      keep_xy=True, bevel=0.0, smooth_angle=None, budget=_bud)
        _drop(objs)


# ---------------------------------------------------------------------------
# cheiul, refugiul, props
# ---------------------------------------------------------------------------

def build_quay():
    """Modul de chei, RUNDA 2 (un singur bloc continuu). LISTA DE ELEMENTE
    (decuparea `harbour_quay.png`, kit §1.4):
    a) UN bloc de beton 6 x 12 m, 2,2 m peste apa + 1,5 m sub (Z = 0 la linia apei);
       apa pe -X, uscatul pe +X; capete plane identice la y = +-6;
    b) scara SAPATA in fata dinspre apa (-X): nisa de 1,8 m latime (x -3..-1,2),
       y -2,5..3,5, 8 trepte care urca de-a lungul fetei (paralel cu ea), primele
       3 sub apa; ultima treapta la cota platformei;
    c) 3 babale de beton pe muchia de sus (y = -4,8 / -3,0 / 4,5);
    d) 5 anvelope de acostare atarnate pe fata verticala -X, la ~1 m sub muchie
       (z = 1,2), in afara scarii;
    e) fata -X din blocuri mari in relief (asize de 0,9-1,0 m, 1,4-2,6 m lungime,
       0,08 m iesite), umbrire plata.
    Noduri: Quay_Concrete (CONCRETE 8), Quay_Rubber (VOLCANIC_BLACK 20)."""
    cn, rb = Builder(), Builder()
    zt, zb = 2.2, -1.5
    xw = -3.0
    xs = -1.2
    y0, y1 = -2.5, 3.5
    # corp: spatele (x >= xs) pe toata lungimea + doua fasii de fata (-X) la capete
    cn.box(((xs + 3.0) * 0.5, 0.0, (zt + zb) * 0.5), (3.0 - xs, 12.0, zt - zb), CONCRETE)
    cn.box(((xw + xs) * 0.5, (-6.0 + y0) * 0.5, (zt + zb) * 0.5), (xs - xw, y0 + 6.0, zt - zb), CONCRETE)
    cn.box(((xw + xs) * 0.5, (y1 + 6.0) * 0.5, (zt + zb) * 0.5), (xs - xw, 6.0 - y1, zt - zb), CONCRETE)
    stair_wedge(cn, xw, xs, y0, y1, zt, 8, CONCRETE, z_lo=zb)
    # blocuri mari in relief pe fata -X, in afara scarii
    rnd = _ok_rand(61)
    for (ya, yb) in ((-6.0, y0), (y1, 6.0)):
        for zi, (za, zbk) in enumerate(((zb, -0.55), (-0.55, 0.4), (0.4, 1.3), (1.3, zt))):
            y = ya + (0.0 if zi % 2 == 0 else -0.5 - rnd() * 0.3)
            y = max(y, ya)
            while y < yb - 0.05:
                w = 1.4 + rnd() * 1.2
                y2 = min(yb, y + w)
                if yb - y2 < 0.8:
                    y2 = yb
                cn.box((xw - 0.02, (y + y2) * 0.5, (za + zbk) * 0.5),
                       (0.1, y2 - y - 0.07, zbk - za - 0.07), CONCRETE)
                y = y2
    # babale pe muchia de sus (pe fasiile de fata, nu deasupra scarii)
    for yb in (-4.8, -3.0, 4.5):
        cn.cylinder((xw + 0.55, yb, zt + 0.3), 0.26, 0.6, CONCRETE, segments=8)
        cn.frustum((xw + 0.55, yb, zt + 0.66), 0.34, 0.26, 0.14, CONCRETE, segments=8)
    # anvelope pe fata verticala, ~1 m sub muchie
    for yy in (-5.0, -3.6, 4.2, 5.2, 2.2 + 3.6 - 0.0 if False else 4.7):
        pass
    for yy in (-5.2, -3.8, 4.1, 5.3):
        rb.torus((xw - 0.16, yy, 1.2), 0.38, 0.14, VOLCANIC_BLACK, major_seg=10, minor_seg=5, axis="X")
    return [cn.to_object("Quay_Concrete"), rb.to_object("Quay_Rubber")]


if _want("harbour_quay"):
    objs = build_quay()
    emit_ok_nodes(objs, "structures/harbour_quay.glb",
                  dict(samples=16, dist=1.8, gradient="vertical", low=0.6, high=1.0,
                       power=0.8, floor=0.35, z_range=(-1.5, 2.8)),
                  flat_suffixes=("_Concrete",), keep_xy=True, keep_z=True, bevel=0.0,
                  smooth_angle=None, budget=2500)
    _drop(objs)


def build_shelter():
    """Refugiu de autobuz, RUNDA 2. LISTA DE ELEMENTE (decuparea
    `bus_stop_shelter.png`):
    a) acoperis simplu in DOUA APE (`gable_roof`), 4,1 x 2,1 m, streasina dreapta,
       olane dese in relief (canale pe panta, perioada 0,5 m); alb DOAR pe coama si
       pe cele doua capete ale coamei;
    b) 4 stalpi de lemn (2 in fata, 2 in spate) + grinda de lemn sub streasina;
    c) perete din spate de corali (asize ca la `coral_stone_wall`) + doua ziduri
       joase de corali pe laturi (1 m, ca jardinierele, fara plante);
    d) banca de lemn de 2,2 m pe doua picioare; placa de beton de 0,12 m;
       FARA tablita, FARA orar.
    Noduri: Shelter_Roof, Shelter_Mortar (coama), Shelter_Wood, Shelter_Coral,
    Shelter_Concrete."""
    rb, mb, wd, cr, cn = Builder(), Builder(), Builder(), Builder(), Builder()
    z0, rise, th = 2.35, 0.55, 0.13
    gable_roof(rb, mb, 2.05, 1.05, z0, rise, th=th, step=0.2, amp=0.12)
    cn.box((0, 0, 0.06), (4.0, 2.0, 0.12), CONCRETE)

    def zroof(y):
        return z0 + rise * (1.0 - abs(y) / 1.05) - th - 0.03

    for x in (-1.8, 1.8):
        for y in (-0.7, 0.75):
            zt = zroof(y)
            wd.box((x, y, (0.12 + zt) * 0.5), (0.18, 0.18, zt - 0.12), WOOD)
    for y in (-0.7, 0.75):
        wd.beam((-1.9, y, zroof(y) - 0.12), (1.9, y, zroof(y) - 0.12), (0.16, 0.2), LOG_DARK)
    coral_wall_segment(cr, (-1.8, -0.72), (1.8, -0.72), 2.2, 0.4, 7, seed=5, stone_len=0.5)
    for sx in (-1, 1):
        coral_wall_segment(cr, (sx * 1.8, -0.5), (sx * 1.8, 0.7), 1.0, 0.4, 4, seed=6 + sx, stone_len=0.5)
    wd.box((0.0, -0.35, 0.5), (2.2, 0.42, 0.07), WOOD)
    wd.box((0.0, -0.45, 0.8), (2.2, 0.05, 0.4), WOOD)
    for x in (-0.9, 0.9):
        wd.box((x, -0.35, 0.25), (0.08, 0.36, 0.5), LOG_DARK)
    return [rb.to_object("Shelter_Roof"), mb.to_object("Shelter_Mortar"), wd.to_object("Shelter_Wood"),
            cr.to_object("Shelter_Coral"), cn.to_object("Shelter_Concrete")]


if _want("bus_stop_shelter"):
    objs = build_shelter()
    emit_ok_nodes(objs, "structures/bus_stop_shelter.glb", _ao(3.0, 1.6),
                  flat_suffixes=("_Coral",), keep_xy=True, bevel=0.0, smooth_angle=48.0, budget=8000)
    _drop(objs)


def build_vending():
    """Automat. LISTA DE ELEMENTE (decuparea `vending_machine.png`; corectura:
    FARA text/logo; contractul cere vitrina cu sticle, decuparea e un panou gol):
    a) corp alb 1,0 x 0,8 x 1,8 m (inaltime 1,8) pe 4 picioare mici; fata pe +Y;
    b) vitrina inchisa la culoare in partea de sus a fetei (0,72 x 0,95 m) cu
       2 rafturi si 8 'sticle' (cilindri 6 segmente, doua culori) -- abatere
       declarata fata de decupare;
    c) fanta de jos (gol) + 3 butoane (dreptunghiuri); usa = rama usor iesita.
    Noduri: Vending_Plaster (FOAM_WHITE), Vending_Glass (VOLCANIC_BLACK + sticle)."""
    pl, gl = Builder(), Builder()
    W, D, H = 1.0, 0.8, 1.8
    pl.box((0, 0, 0.08 + (H - 0.08) * 0.5), (W, D, H - 0.08), FOAM_WHITE)
    for sx in (-1, 1):
        for sy in (-1, 1):
            pl.box((sx * 0.4, sy * 0.3, 0.04), (0.12, 0.12, 0.08), FOAM_WHITE)
    yf = D * 0.5
    pl.box((0, yf + 0.015, 1.15), (W - 0.08, 0.03, 1.4), FOAM_WHITE)
    gl.box((-0.06, yf + 0.04, 1.28), (0.72, 0.03, 0.95), VOLCANIC_BLACK)
    for zz in (1.1, 1.45):
        pl.box((-0.06, yf + 0.06, zz - 0.02), (0.72, 0.1, 0.03), FOAM_WHITE)
    for r, zz in enumerate((1.1, 1.45)):
        for k in range(4):
            x = -0.32 + 0.2 * k
            gl.cylinder((x, yf + 0.06, zz + 0.12), 0.045, 0.24, REEF_SHALLOW if (k + r) % 2 else SAND_LIGHT, segments=6)
            gl.cylinder((x, yf + 0.06, zz + 0.26), 0.025, 0.05, ICE_TURQUOISE, segments=6)
    gl.box((-0.06, yf + 0.03, 0.42), (0.6, 0.04, 0.16), VOLCANIC_BLACK)
    for k in range(3):
        gl.box((0.4, yf + 0.04, 1.5 - 0.14 * k), (0.07, 0.03, 0.1), VOLCANIC_BLACK)
    return [pl.to_object("Vending_Plaster"), gl.to_object("Vending_Glass")]


if _want("vending_machine"):
    objs = build_vending()
    emit_ok_nodes(objs, "props/vending_machine.glb", _ao(1.9, 0.8, 0.8, 0.55),
                  keep_xy=True, bevel=0.0, smooth_angle=None, budget=1500)
    _drop(objs)


def build_mirror():
    """Oglinda convexa. LISTA DE ELEMENTE (decuparea `convex_mirror.png`):
    a) stalp portocaliu 3 m (8 segmente) pe talpa joasa;
    b) brat scurt in varf, rama Ø 0,86 m (12 segmente) inclinata 12 grade in jos,
       cu fata spre +Y, portocalie;
    c) oglinda bombata (calota) Ø 0,8 m ICE_TURQUOISE in fata ramei.
    Noduri: Mirror_Frame (LAVA_ORANGE 30), Mirror_Glass (ICE_TURQUOISE 24)."""
    fr, gl = Builder(), Builder()
    fr.frustum((0, 0, 0.06), 0.22, 0.22, 0.12, LAVA_ORANGE, segments=8)
    fr.frustum((0, 0, 1.5), 0.055, 0.045, 3.0, LAVA_ORANGE, segments=8)
    tilt = math.radians(12.0)
    c = Vector((0.0, 0.34, 2.72))
    n = Vector((0.0, math.cos(tilt), -math.sin(tilt)))
    fr.beam((0, 0, 2.7), (0, 0.2, 2.72), (0.07, 0.07), LAVA_ORANGE)
    rot = Matrix.Rotation(math.radians(-90.0) + tilt, 4, "X")
    res = bmesh.ops.create_cone(fr.bm, cap_ends=True, cap_tris=False, segments=12,
                                radius1=0.43, radius2=0.43, depth=0.1,
                                matrix=Matrix.Translation(c) @ rot)
    fr._tag(res["verts"], LAVA_ORANGE)
    res = bmesh.ops.create_cone(gl.bm, cap_ends=True, cap_tris=False, segments=12,
                                radius1=0.4, radius2=0.28, depth=0.08,
                                matrix=Matrix.Translation(c + n * 0.08) @ rot)
    gl._tag(res["verts"], ICE_TURQUOISE)
    return [fr.to_object("Mirror_Frame"), gl.to_object("Mirror_Glass")]


if _want("convex_mirror"):
    objs = build_mirror()
    emit_ok_nodes(objs, "props/convex_mirror.glb", _ao(3.2, 0.8, 0.8, 0.6),
                  keep_xy=True, bevel=0.0, smooth_angle=None, budget=1500)
    _drop(objs)


def build_net_rack():
    """Suport de plase. LISTA DE ELEMENTE (decuparea `fishing_net_rack.png`):
    a) 2 capre in A (cate 2 picioare inclinate) la x = +-1,6, ~2 m inaltime;
    b) bara orizontala de lemn la 1,85 m, 4 m lunga, + 2 traverse joase;
    c) 3 plase atarnate (saci fatetati, 2 ICE_DEEP, 1 REEF_SHALLOW) de lungimi
       diferite (1,0-1,3 m);
    d) 9 flotoare (ICE_TURQUOISE / SAND_LIGHT, sfere 6 x 4) la gura plaselor.
    Noduri: Rack_Wood (WOOD 9), Rack_Net (plase + flotoare)."""
    wd, nt = Builder(), Builder()
    for sx in (-1, 1):
        for sy in (-1, 1):
            wd.beam((sx * 1.6, sy * 0.55, 0.0), (sx * 1.6, sy * 0.05, 1.95), (0.09, 0.09), WOOD)
        wd.beam((sx * 1.6, -0.3, 0.45), (sx * 1.6, 0.3, 0.45), (0.07, 0.07), WOOD)
    wd.beam((-2.0, 0.0, 1.85), (2.0, 0.0, 1.85), (0.13, 0.13), WOOD)
    specs = ((-1.05, 0.85, 1.3, ICE_DEEP), (0.1, 1.1, 1.05, ICE_DEEP), (1.2, 0.8, 1.2, REEF_SHALLOW))
    for xc, w, hn, sl in specs:
        top = 1.8
        rr = [(top - 0.02, w * 0.30, 0.07, xc, 0.0), (top - hn * 0.3, w * 0.48, 0.16, xc, 0.0),
              (top - hn * 0.7, w * 0.40, 0.14, xc, 0.0), (top - hn, w * 0.10, 0.05, xc, 0.0)]
        rr = [(z, rx, ry, cx, cy) for z, rx, ry, cx, cy in reversed(rr)]
        pts, _ = ring_points(rr, 7, int(abs(xc) * 10) + 40, 0.12)
        faceted_shell(nt, pts, sl, cap_top=True, cap_bottom=True)
        for k in range(3):
            a = (k + 0.5) / 3 * 2 * math.pi
            ellipsoid(nt, (xc + math.cos(a) * w * 0.28, math.sin(a) * 0.08, top + 0.02),
                      (0.07, 0.07, 0.06), ICE_TURQUOISE if k % 2 == 0 else SAND_LIGHT, 6, 4)
    return [wd.to_object("Rack_Wood"), nt.to_object("Rack_Net")]


if _want("fishing_net_rack"):
    objs = build_net_rack()
    emit_ok_nodes(objs, "props/fishing_net_rack.glb", _ao(2.0, 1.0, 0.7, 0.45),
                  keep_xy=True, bevel=0.0, smooth_angle=None, budget=1500)
    _drop(objs)

report_ok()
