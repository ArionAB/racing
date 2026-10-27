"""Fiordland — Cheiul si satul (brief §1.3, val 4 din
docs/asset_briefs/fiordland_kit.md; refacut v2 dupa
docs/asset_briefs/fiordland_kit_v2.md, grupa C).

  fiordland/structures/wharf.glb              cheiul de start
  fiordland/buildings/cafe_shed.glb           cafeneaua
  fiordland/buildings/lodge.glb               lodge-ul de langa pista de avioane
  fiordland/structures/heli_pad.glb           heliportul
  fiordland/props/luggage_container.glb       container de 20 ft
  fiordland/props/road_sign_blank.glb         panou verde gol
  fiordland/props/traffic_light_pole.glb      stalp de semafor (FARA lampi)
  fiordland/props/snow_pole.glb               jalon de zapada

REGULI CARE SE APLICA LA TOATE:
  - traffic_light_pole: DOAR stalpul si carcasa (NU se reface in v2).
  - cladirile (cafe_shed, lodge): doua niveluri, balcon, geamuri CALDE
    (SAND_LIGHT 0 ca CULOARE, nu emisie — brief v2 §0.4). Noduri House_Wall +
    House_Roof (piesele pe clase se sparg la export in obiecte cu un singur
    material). Fata (usa, balconul) e +Y in Blender = -Z in Godot.
  - heli_pad: cercul si H-ul sunt GEOMETRIE joasa (relief 5 cm), nu textura.
  - wharf: capete PLANE la y = +-10 m, ca sa se inlantuie. Slotul 21 e remapat
    pe MARBLE_GREY in joc: NU se foloseste pe chei.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_village.py
"""

import math
import bmesh
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (brief §0.4). ROCK_DARK/ROCK_LIGHT interzise.
GNEISS = MARBLE_GREY
WET_STREAK = VOLCANIC_BLACK
WOOD_SLOT = WOOD
METAL = ASPHALT_EDGE          # gri cald mediu: tabla, stalpi de metal
METAL_DARK = ASPHALT          # gri inchis: nervuri, balamale
MOSS = TROPICAL_GREEN
ROOF = ASPHALT_EDGE
SNOW = FOAM_WHITE
POLE_TIP = KERB_RED
WARM = SAND_LIGHT             # geam cald (culoare, nu emisie)

AO_STRUCT = dict(samples=20, dist=3.5, gradient="vertical",
                 low=0.46, high=1.00, power=0.88, floor=0.17)
AO_HOUSE = dict(samples=22, dist=5.0, gradient="vertical",
                low=0.44, high=1.00, power=0.88, floor=0.16)
AO_SMALL = dict(samples=18, dist=1.6, gradient="vertical",
                low=0.48, high=1.00, power=0.90, floor=0.20)


def _xform(b, faces, rot3=None, trans=(0.0, 0.0, 0.0)):
    """Roteste (in jurul originii) apoi muta fetele unei primitive — pentru
    `corrugate`, care nu primeste rotatie."""
    vs = list({v for f in faces for v in f.verts})
    if rot3 is not None:
        bmesh.ops.rotate(b.bm, verts=vs, cent=(0.0, 0.0, 0.0), matrix=rot3)
    bmesh.ops.translate(b.bm, verts=vs, vec=trans)
    return faces


class Local:
    """Cadru local: +Y local = spre exteriorul peretelui, originea pe suprafata
    peretelui, la z=0. Rotatia e in jurul lui Z. Toate cutiile se dau in
    coordonate locale (x = de-a lungul peretelui, y = spre afara, z = sus)."""

    def __init__(self, b, origin, rot):
        self.b, self.o, self.R = b, Vector(origin), rot

    def box(self, c, size, slot):
        w = self.o + self.R @ Vector(c)
        return self.b.box((w.x, w.y, w.z), size, slot, rotation=self.R)


# --- wharf -------------------------------------------------------------------
#
# Zid de chei din blocuri de piatra in 4 asize decalate, cu rosturi adanci
# (miez negru, blocurile ies 12-18 cm), coronament din lespezi, punte de piatra
# intre ele si babale de lemn cu capac. Capete PLANE la y = +-10.
WH_HL = 10.0          # semi-lungime (Blender Y)
WH_CORE = 1.95        # semi-latime miez
WH_H = 1.92           # inaltimea zidului: puntea iese la ~2,12 m, cota v1 (2,0 + coronament)
WH_ROW_H = (0.55, 0.42, 0.55, 0.40)   # inaltimi de rand diferite, suma = WH_H


def _chamfer_block(b, x0, x1, ya, yb, za, zb, side, slot, ch=0.045):
    """Bloc de zidarie: baza (spre miez) dreptunghi plin, fata exterioara mai
    mica cu `ch` pe y si z — ca o fateta tesita, tot 12 triunghiuri."""
    def X(x):
        return x * side
    base = [(x0, ya, za), (x0, yb, za), (x0, yb, zb), (x0, ya, zb)]
    face = [(x1, ya + ch, za + ch), (x1, yb - ch, za + ch),
            (x1, yb - ch, zb - ch), (x1, ya + ch, zb - ch)]
    vb = [b.bm.verts.new((X(x), y, z)) for x, y, z in base]
    vf = [b.bm.verts.new((X(x), y, z)) for x, y, z in face]
    quads = [(vb[3], vb[2], vb[1], vb[0]), (vf[0], vf[1], vf[2], vf[3])]
    for i in range(4):
        j = (i + 1) % 4
        quads.append((vb[i], vb[j], vf[j], vf[i]))
    for q in quads:
        f = b.bm.faces.new(q)
        f[b.slot] = slot


def _course_face(b, side, rand):
    """Asize pe o fata lunga (side = +1 -> +X, -1 -> -X): inaltimi de rand
    diferite, blocuri de lungimi diferite, iesite 2-6 cm unul fata de altul."""
    z0 = 0.0
    for r, rh in enumerate(WH_ROW_H):
        y = -WH_HL
        length = 0.6 + rand() * 0.4 if r % 2 == 0 else 1.3 + rand() * 0.6
        while y < WH_HL - 1e-4:
            y1 = min(y + length, WH_HL)
            if WH_HL - y1 < 0.6:
                y1 = WH_HL
            ya = y + (0.0 if y <= -WH_HL + 1e-4 else 0.03)
            yb = y1 - (0.0 if y1 >= WH_HL - 1e-4 else 0.03)
            out = 0.10 + rand() * 0.10
            u = rand()
            slot = GNEISS if u < 0.34 else (ASPHALT_EDGE if u < 0.78 else VOLCANIC_BLACK)
            ja, jb = (rand() - 0.5) * 0.05, (rand() - 0.5) * 0.05
            _chamfer_block(b, WH_CORE - 0.02, WH_CORE + out, ya, yb,
                           z0 + 0.025 + ja, z0 + rh - 0.025 + jb, side, slot)
            y = y1
            length = 0.7 + rand() * 1.4
        z0 += rh


def build_wharf():
    b = Builder()
    rand = _lcg(7101)
    b.box((0.0, 0.0, WH_H * 0.5), (WH_CORE * 2, WH_HL * 2, WH_H), VOLCANIC_BLACK)
    _course_face(b, +1, rand)
    _course_face(b, -1, rand)

    # puntea: lespede de piatra gri-bej inchis, cu rosturi transversale
    deck_top = WH_H + 0.10
    b.box((0.0, 0.0, WH_H + 0.05), (3.5, WH_HL * 2, 0.10), ASPHALT_EDGE)
    for k in range(1, 6):
        y = -WH_HL + k * (WH_HL * 2 / 6.0)
        b.box((0.0, y, deck_top + 0.004), (3.5, 0.03, 0.02), VOLCANIC_BLACK)

    # coronament: lespezi late pe ambele margini
    for side in (+1, -1):
        y = -WH_HL
        while y < WH_HL - 1e-4:
            ln = 1.25 + rand() * 0.6
            y1 = min(y + ln, WH_HL)
            if WH_HL - y1 < 0.8:
                y1 = WH_HL
            ya = y + (0.0 if y <= -WH_HL + 1e-4 else 0.03)
            yb = y1 - (0.0 if y1 >= WH_HL - 1e-4 else 0.03)
            u = rand()
            slot = GNEISS if u < 0.5 else CONCRETE
            b.box((side * 1.98, (ya + yb) * 0.5, WH_H + 0.10), (0.56, yb - ya, 0.20), slot)
            y = y1

    # 6 babale GROASE (r 0.27), ~0.9 m peste punte, capat taiat: 3 piloti pe
    # fata +X (urca de jos pana peste coronament) si 3 babale pe marginea -X
    top = WH_H + 0.10 + 0.95
    posts = [(+1, -8.6, top), (+1, 0.4, top), (+1, 8.2, top),
             (-1, -5.0, top), (-1, 3.8, top), (-1, 9.0, top)]
    for side, y, t in posts:
        if side > 0:
            cx, z0 = 2.20, 0.10
        else:
            cx, z0 = -1.95, WH_H + 0.20
        h = t - z0
        b.cylinder((cx, y, z0 + h * 0.5), 0.27, h, WOOD_SLOT, segments=8, axis="Z")
        cap = b.cylinder((cx, y, t + 0.03), 0.31, 0.10, WOOD_SLOT, segments=8, axis="Z")
        b.retag(cap, WARM, where="up")
    return b.to_object("Wharf")


# --- cafe_shed / lodge ---------------------------------------------------------
#
# Cabana din busteni inchisi (LOG_DARK) pe doua niveluri, acoperis in doua ape
# de tabla gri cu nervuri, coama pe lungime (X), balcon continuu la etaj cu
# balustrada, geamuri calde cu rama si montant, usi cu geam, trepte la intrare.
# Fata = +Y local (-Z in Godot). Acoperisul coboara cu aceeasi panta si peste
# streasina, deci frontoanele de capat ating placa fara gol de cer.
LOG_PITCH = 0.46


def _logs(l, width, height, t, slot=LOG_DARK):
    """Busteni orizontali stivuiti, alternativ iesiti 2.5 cm (da linia de
    umbra intre ei)."""
    n = max(2, int(round(height / LOG_PITCH)))
    rh = height / n
    for i in range(n):
        off = 0.025 if i % 2 else 0.0
        l.box((0.0, (off - t) * 0.5, rh * (i + 0.5)), (width, t + off, rh), slot)


def _window(l, cx, cz, w, h, mull=1, sill=True):
    """Geam cald cu rama (placa de lemn mai mare), montanti si pervaz."""
    l.box((cx, 0.035, cz), (w + 0.20, 0.11, h + 0.20), LOG_DARK)
    l.box((cx, 0.11, cz), (w, 0.04, h), WARM)
    for i in range(mull):
        x = cx - w * 0.5 + w * (i + 1) / (mull + 1)
        l.box((x, 0.14, cz), (0.055, 0.05, h), WOOD_SLOT)
    if h > 1.0:
        l.box((cx, 0.14, cz + h * 0.08), (w, 0.05, 0.05), WOOD_SLOT)
    if sill:
        l.box((cx, 0.12, cz - h * 0.5 - 0.13), (w + 0.34, 0.22, 0.07), LOG_DARK)


def _door(l, cx, w, h):
    """Usa: toc de lemn, canat inchis cu geam cald sus."""
    l.box((cx, 0.04, h * 0.5 + 0.05), (w + 0.22, 0.12, h + 0.10), LOG_DARK)
    l.box((cx, 0.10, h * 0.5), (w, 0.06, h), LOG_DARK)
    l.box((cx, 0.14, h * 0.70), (w * 0.52, 0.04, h * 0.30), WARM)


def _steps(l, cx, w):
    l.box((cx, 0.20, 0.08), (w + 0.2, 0.40, 0.16), WOOD_SLOT)
    l.box((cx, 0.45, 0.16), (w + 0.45, 0.50, 0.32), WOOD_SLOT)


def _tri_gable(b, x, t, hd, z0, rise, slot):
    """Frontonul de capat: triunghi in planul YZ, extrudat pe X cu grosimea t."""
    xa, xb = x - t * 0.5, x + t * 0.5
    A = [b.bm.verts.new((xa, -hd, z0)), b.bm.verts.new((xa, hd, z0)),
         b.bm.verts.new((xa, 0.0, z0 + rise))]
    B = [b.bm.verts.new((xb, -hd, z0)), b.bm.verts.new((xb, hd, z0)),
         b.bm.verts.new((xb, 0.0, z0 + rise))]
    fs = [b.bm.faces.new(tuple(A)), b.bm.faces.new(tuple(reversed(B)))]
    for i in range(3):
        j = (i + 1) % 3
        fs.append(b.bm.faces.new((A[i], A[j], B[j], B[i])))
    for f in fs:
        f[b.slot] = slot
    return fs


def _chalet_walls(c):
    W, D, h1, h2 = c["W"], c["D"], c["h1"], c["h2"]
    hw, hd = W * 0.5, D * 0.5
    Hw = h1 + h2
    t = 0.26
    b = Builder()
    I = Matrix.Identity(3)
    Rz = lambda deg: Matrix.Rotation(math.radians(deg), 3, "Z")
    front = Local(b, (0, hd, 0), I)
    back = Local(b, (0, -hd, 0), Rz(180))
    right = Local(b, (hw, 0, 0), Rz(-90))
    left = Local(b, (-hw, 0, 0), Rz(90))

    # pereti din busteni
    _logs(front, W, Hw, t)
    _logs(back, W, Hw, t)
    _logs(right, D - 2 * t, Hw, t)
    _logs(left, D - 2 * t, Hw, t)
    # frontoane (triunghi plin, in planul peretelui de capat)
    for sx in (-1.0, 1.0):
        _tri_gable(b, sx * (hw - t * 0.5), t, hd, Hw, c["rise"], LOG_DARK)

    # coltare groase, deschise la culoare — ies 4 cm din fata
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (hw - 0.13), sy * (hd - 0.13), Hw * 0.5), (0.34, 0.34, Hw), LOG_DARK)
    # brau de etaj pe toate cele patru laturi
    for L, ln in ((front, W), (back, W), (right, D - 0.5), (left, D - 0.5)):
        L.box((0.0, 0.05, h1), (ln, 0.12, 0.24), LOG_DARK)

    # geamuri pe fata, spate, capete
    for cx, w, kind in c["front_ground"]:
        if kind == "door":
            _door(front, cx, w, c["door_h"])
            if c.get("steps", True):
                _steps(front, cx, w)
        else:
            _window(front, cx, c["wz1"], w, c["wh"], mull=2 if w > 1.4 else 1)
    for cx, w in c["front_upper"]:
        _window(front, cx, h1 + c["wz2"], w, c["wh"], mull=1, sill=False)
    for cx, w in c["back_ground"]:
        _window(back, cx, c["wz1"], w, c["wh"], mull=1)
    for cx, w in c["back_upper"]:
        _window(back, cx, h1 + c["wz2"], w, c["wh"], mull=1, sill=False)
    for L in (right, left):
        for cy in c["end_ground"]:
            _window(L, cy, c["wz1"], 0.9, c["wh"], mull=1)
        for cy in c["end_upper"]:
            _window(L, cy, h1 + c["wz2"], 0.9, c["wh"], mull=1, sill=False)
        # fereastra mica de pod, in fronton
        _window(L, 0.0, Hw + c["rise"] * 0.30, 0.55, 0.55, mull=0, sill=False)

    # balcon continuu la etaj: placa + balustrada + stalpi de sprijin
    pr = c["balcony"]
    slab_z = h1 - 0.02
    b.box((0.0, hd + pr * 0.5, slab_z), (W - 0.1, pr, 0.18), WOOD_SLOT)
    ry = hd + pr - 0.07
    zb = slab_z + 0.09
    for k in range(int(W / c["post_step"]) + 1):
        x = -hw + 0.18 + k * (W - 0.36) / int(W / c["post_step"])
        b.box((x, ry, zb + 0.47), (0.10, 0.10, 0.94), WOOD_SLOT)
    b.box((0.0, ry, zb + 0.94), (W - 0.1, 0.12, 0.09), WOOD_SLOT)
    b.box((0.0, ry, zb + 0.50), (W - 0.1, 0.07, 0.07), WOOD_SLOT)
    # capetele balconului (colt): stalpi de capat ies pana la sol
    for x in c["porch_posts"]:
        b.box((x, hd + pr - 0.14, slab_z * 0.5), (0.20, 0.20, slab_z), WOOD_SLOT)
    return b.to_object("House_Wall")


def _chalet_roof(c):
    W, D, h1, h2 = c["W"], c["D"], c["h1"], c["h2"]
    hw, hd = W * 0.5, D * 0.5
    Hw = h1 + h2
    rise = c["rise"]
    slope = rise / hd
    X0 = hw + c["ov_x"]
    th = 0.16
    b = Builder()
    ridge_z = Hw + rise
    for s, ov in ((1.0, c["ov_f"]), (-1.0, c["ov_b"])):
        ye = s * (hd + ov)
        ze = Hw - ov * slope
        bot = [b.bm.verts.new((-X0, 0.0, ridge_z)), b.bm.verts.new((X0, 0.0, ridge_z)),
               b.bm.verts.new((X0, ye, ze)), b.bm.verts.new((-X0, ye, ze))]
        top = [b.bm.verts.new((-X0, 0.0, ridge_z + th)), b.bm.verts.new((X0, 0.0, ridge_z + th)),
               b.bm.verts.new((X0, ye, ze + th)), b.bm.verts.new((-X0, ye, ze + th))]
        fs = [b.bm.faces.new(tuple(top) if s > 0 else tuple(reversed(top))),
              b.bm.faces.new(tuple(reversed(bot)) if s > 0 else tuple(bot)),
              b.bm.faces.new((top[0], top[1], bot[1], bot[0])),
              b.bm.faces.new((top[2], top[3], bot[3], bot[2])),
              b.bm.faces.new((top[1], top[2], bot[2], bot[1])),
              b.bm.faces.new((top[3], top[0], bot[0], bot[3]))]
        for f in fs:
            f[b.slot] = ROOF
        b.retag(fs, WET_STREAK, where="down")
        # nervuri de tabla, de la coama la streasina
        n = int(round((2 * X0 - 0.4) / c["rib_pitch"]))
        for k in range(n + 1):
            x = -X0 + 0.2 + k * (2 * X0 - 0.4) / n
            b.beam((x, s * 0.10, ridge_z + th + 0.03 - slope * 0.10),
                   (x, ye * 0.985, ze + th + 0.03 + slope * abs(ye) * 0.015),
                   (0.07, 0.05), METAL_DARK)
    # coama: capac lung
    b.box((0.0, 0.0, ridge_z + th + 0.03), (2 * X0 + 0.1, 0.40, 0.10), METAL_DARK)
    return b.to_object("House_Roof")


CAFE = dict(
    W=5.0, D=3.8, h1=2.5, h2=2.3, rise=1.35, ov_x=0.4, ov_f=0.7, ov_b=0.4,
    rib_pitch=0.70, balcony=0.6, post_step=0.9, porch_posts=(-2.3, -0.3, 2.3),
    door_h=2.0, wh=1.05, wz1=1.30, wz2=1.25,
    front_ground=[(-1.45, 1.5, "win"), (1.25, 1.0, "door")],
    front_upper=[(-1.7, 0.8), (-0.1, 0.8), (1.5, 0.8)],
    back_ground=[(-1.2, 0.9), (1.2, 0.9)],
    back_upper=[(-1.2, 0.8), (1.2, 0.8)],
    end_ground=[-0.9, 0.9], end_upper=[-0.9, 0.9],
)

LODGE = dict(
    W=16.0, D=6.2, h1=2.75, h2=2.65, rise=2.1, ov_x=0.55, ov_f=1.05, ov_b=0.85,
    rib_pitch=0.65, balcony=0.75, post_step=1.0,
    porch_posts=(-7.7, -5.1, -2.6, 0.9, 3.1, 5.2, 7.7),
    door_h=2.15, wh=1.25, wz1=1.45, wz2=1.35,
    front_ground=[(-6.2, 1.4, "win"), (-3.9, 1.0, "win"), (-0.6, 1.2, "door"),
                  (2.0, 1.7, "win"), (4.2, 1.0, "win"), (6.4, 1.1, "door")],
    front_upper=[(-6.65 + 1.9 * i, 0.95) for i in range(8)],
    back_ground=[(-6.0, 1.0), (-3.0, 1.0), (0.0, 1.0), (3.0, 1.0), (6.0, 1.0)],
    back_upper=[(-6.0, 0.9), (-3.6, 0.9), (-1.2, 0.9), (1.2, 0.9), (3.6, 0.9), (6.0, 0.9)],
    end_ground=[-1.5, 1.5], end_upper=[-1.5, 1.5],
)


def build_cafe_shed():
    return _chalet_walls(CAFE), _chalet_roof(CAFE)


def build_lodge():
    return _chalet_walls(LODGE), _chalet_roof(LODGE)


# --- heli_pad ------------------------------------------------------------------
#
# Tambur din blocuri de piatra pe margine (2 randuri decalate), platforma
# intunecata, inel alb si H alb in relief de 5 cm. Y total 0.35 (<= 0.4).
HP_R = 6.0


def _annulus(b, r0, r1, z0, z1, segs, slot):
    """Inel plin (fara fund): capac sus + perete exterior + perete interior."""
    o0, o1, i0, i1 = [], [], [], []
    for i in range(segs):
        a = 2.0 * math.pi * i / segs
        c, s = math.cos(a), math.sin(a)
        o0.append(b.bm.verts.new((c * r1, s * r1, z0)))
        o1.append(b.bm.verts.new((c * r1, s * r1, z1)))
        i0.append(b.bm.verts.new((c * r0, s * r0, z0)))
        i1.append(b.bm.verts.new((c * r0, s * r0, z1)))
    fs = []
    for i in range(segs):
        j = (i + 1) % segs
        fs.append(b.bm.faces.new((i1[i], o1[i], o1[j], i1[j])))     # sus
        fs.append(b.bm.faces.new((o0[i], o0[j], o1[j], o1[i])))     # exterior
        fs.append(b.bm.faces.new((i0[j], i0[i], i1[i], i1[j])))     # interior
    for f in fs:
        f[b.slot] = slot
    return fs


def build_heli_pad():
    b = Builder()
    rand = _lcg(7401)
    # miez + platforma
    b.cylinder((0.0, 0.0, 0.10), 5.5, 0.20, VOLCANIC_BLACK, segments=24, axis="Z")
    b.cylinder((0.0, 0.0, 0.29), 5.45, 0.10, METAL_DARK, segments=28, axis="Z")
    # tamburul: 2 randuri de blocuri, al doilea decalat cu jumatate de bloc
    n = 26
    row_h = 0.19
    r_c, rad = 5.68, 0.64
    arc = 2.0 * math.pi * r_c / n
    for row in range(2):
        for k in range(n):
            a = 2.0 * math.pi * (k + 0.5 * row) / n
            u = rand()
            slot = ASPHALT_EDGE if u < 0.5 else (GNEISS if u < 0.75 else VOLCANIC_BLACK)
            rot = Matrix.Rotation(a, 3, "Z")
            b.box((math.cos(a) * r_c, math.sin(a) * r_c, row_h * (row + 0.5)),
                  (rad + (rand() - 0.5) * 0.06, arc * 0.93, row_h - 0.012), slot, rotation=rot)
    # inelul alb si H-ul, in relief
    ztop = 0.34
    _annulus(b, 4.50, 4.88, ztop, ztop + 0.05, 32, SNOW)
    for sx in (-1.0, 1.0):
        b.box((sx * 1.15, 0.0, ztop + 0.025), (0.62, 3.6, 0.05), SNOW)
    b.box((0.0, 0.0, ztop + 0.025), (1.7, 0.55, 0.05), SNOW)
    return b.to_object("HeliPad")


# --- luggage_container -----------------------------------------------------------
#
# Container de 20 ft: miez gri, laterale si acoperis din tabla ondulata (nervuri
# verticale pe laturi), rama de colt cu stalpi si sine, usi duble cu tije de
# inchidere si balamale pe ambele capete.
def build_luggage_container():
    b = Builder()
    L, W, H = 6.1, 2.4, 2.6
    hl, hw = L * 0.5, W * 0.5
    b.box((0.0, 0.0, 1.30), (2.2, 5.9, 2.4), METAL)
    # laterale ondulate (nervuri spre exterior, ies pana la +-1.2)
    for sgn in (+1.0, -1.0):
        f = b.corrugate((0.0, 0.0, 0.0), (5.6, 0.05, 2.2), METAL, ribs=10, depth=0.06)
        _xform(b, f, Matrix.Rotation(math.radians(-90.0 * sgn), 3, "Z"),
               (sgn * (hw - 0.085), 0.0, 1.30))
    # acoperis ondulat: nervuri pe lungime
    f = b.corrugate((0.0, 0.0, 0.0), (2.0, 0.05, 5.6), METAL, ribs=4, depth=0.06)
    _xform(b, f, Matrix.Rotation(math.radians(90.0), 3, "X"), (0.0, 0.0, H - 0.085))
    # rama: stalpi de colt + sine sus/jos pe laturi si capete
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (hw - 0.085), sy * (hl - 0.085), H * 0.5), (0.17, 0.17, H), METAL_DARK)
        for z in (0.07, H - 0.07):
            b.box((sx * (hw - 0.065), 0.0, z), (0.13, L - 0.34, 0.14), METAL_DARK)
    for sy in (-1.0, 1.0):
        for z in (0.07, H - 0.07):
            b.box((0.0, sy * (hl - 0.065), z), (W - 0.34, 0.13, 0.14), METAL_DARK)
        # usi duble, retrase in rama
        for sx in (-1.0, 1.0):
            b.box((sx * 0.55, sy * (hl - 0.10), H * 0.5), (1.08, 0.06, H - 0.28), METAL)
            # tije de inchidere (2 per canat) cu clema
            for dx in (0.25, 0.62):
                b.box((sx * dx, sy * (hl - 0.05), H * 0.5), (0.05, 0.05, H - 0.34), METAL_DARK)
            # balamale
            for zz in (0.45, H * 0.5, H - 0.45):
                b.box((sx * 1.04, sy * (hl - 0.07), zz), (0.07, 0.09, 0.16), METAL_DARK)
        b.box((0.0, sy * (hl - 0.06), H * 0.5), (0.10, 0.05, 0.4), METAL_DARK)  # maner
    return b.to_object("Container")


# --- road_sign_blank -------------------------------------------------------------
#
# Panou verde dreptunghiular cu bordura alba si rama groasa gri pe 2 stalpi
# cilindrici de metal gri. FARA text/glif.
def build_road_sign_blank():
    b = Builder()
    pz = 2.0                                   # centrul panoului (1.5 .. 2.5)
    b.box((0.0, -0.045, pz), (1.62, 0.04, 1.02), METAL_DARK)      # spatele
    b.box((0.0, 0.0, pz), (1.66, 0.07, 1.06), SNOW)               # rama groasa alba
    b.box((0.0, 0.025, pz), (1.52, 0.07, 0.92), MOSS)             # campul verde
    for sx in (-1.0, 1.0):
        x = sx * 0.55
        b.cylinder((x, -0.095, 1.15), 0.09, 2.30, METAL, segments=8, axis="Z")
        for zz in (1.62, 2.38):
            b.box((x, -0.075, zz), (0.16, 0.05, 0.09), METAL_DARK)   # coliere
    return b.to_object("RoadSign")


# --- traffic_light_pole -----------------------------------------------------
#
# Contract: stalp 5.5 m + brat 2.5 m + carcasa 0.5x0.4x1.2 m. DOAR stalp +
# carcasa. 2 alveole GOALE VOLCANIC_BLACK, 0.3 m diametru, la 0.35 m distanta
# pe verticala. Lampile le pune HazardLamp la integrare.
TP_POLE_H = 5.5
TP_ARM_LEN = 2.5
TP_BOX = (0.5, 0.4, 1.2)


def build_traffic_light_pole():
    """segments=6 pe stalp si alveole (nu 10): dupa bevel piesa iesea 436/250
    — un stalp subtire vazut de la distanta pe marginea drumului n-are nevoie
    de rotunjime fina."""
    b = Builder()
    b.cylinder((0.0, 0.0, TP_POLE_H * 0.5), 0.11, TP_POLE_H, CONCRETE,
              segments=6, axis="Z")
    # bratul orizontal, spre +Y (peste banda)
    arm_z = TP_POLE_H - 0.35
    b.beam((0.0, 0.0, arm_z), (0.0, TP_ARM_LEN, arm_z), 0.08, CONCRETE)
    # carcasa, agatata sub capatul bratului
    box_center = (0.0, TP_ARM_LEN - TP_BOX[1] * 0.5 - 0.05, arm_z - TP_BOX[2] * 0.5 - 0.06)
    b.box(box_center, TP_BOX, PAINTED)
    # 2 alveole goale, VOLCANIC_BLACK, 0.3 m diametru, distantate 0.35 m pe Z
    hole_r = 0.15
    cy = box_center[1]
    for i, dz in enumerate((0.35 * 0.5, -0.35 * 0.5)):
        cz = box_center[2] + dz
        b.cylinder((0.0, cy - TP_BOX[1] * 0.5 - 0.01, cz), hole_r, 0.03,
                  WET_STREAK, segments=6, axis="Y")
    return b.to_object("TrafficPole")


# --- snow_pole -----------------------------------------------------------------
#
# Contract: 2.0 m, 0.06 m diametru. Benzi alternante alb / rosu pe toata
# inaltimea (de jos in sus: alb, rosu, alb, rosu — ca pe plansa).
def build_snow_pole():
    b = Builder()
    R = 0.03
    bands = [(0.25, SNOW), (0.55, POLE_TIP), (0.50, SNOW), (0.70, POLE_TIP)]
    z = 0.0
    for h, slot in bands:
        b.cylinder((0.0, 0.0, z + h * 0.5), R, h, slot, segments=6, axis="Z")
        z += h
    return b.to_object("SnowPole")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def _darken_slot(obj, slot, k):
    """Inmulteste culoarea de vertex (AO) a fetelor de pe `slot` cu k: un verde
    de panou de drum mai inchis decat orice slot verde existent, fara slot nou."""
    me = obj.data
    uv = me.uv_layers.active.data
    ca = me.color_attributes.active_color
    u0 = slot_u(slot)
    seen = set()
    for poly in me.polygons:
        if abs(uv[poly.loop_indices[0]].uv.x - u0) < 1e-4:
            seen.update(poly.vertices)
    for vi in seen:
        c = ca.data[vi].color
        ca.data[vi].color = (c[0] * k, c[1] * k, c[2] * k, c[3])


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, no_collision=False, bevel_angle=30.0, darken=None):
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=(origin if solo else None), smooth_angle=smooth_angle)
        if darken:
            _darken_slot(o, darken[0], darken[1])
        if not solo:
            for v in o.data.vertices:
                v.co += place
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "fiordland/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return total_tris


wharf_obj = build_wharf()
# fara bevel: sute de blocuri ar multiplica triunghiurile; rosturile adanci
# (miez negru) dau muchia. bevel_angle e irelevant la 0.
emit(wharf_obj, "structures/wharf.glb", AO_STRUCT, origin="base_axis",
     bevel=0.0, budget=2300)

# cafe_shed INAINTE de lodge: Blender numeste al doilea House_Wall "House_Wall.001"
cafe_wall, cafe_roof = build_cafe_shed()
emit([cafe_wall, cafe_roof], "buildings/cafe_shed.glb", AO_HOUSE,
     bevel=0.0, budget=2000)

lodge_wall, lodge_roof = build_lodge()
emit([lodge_wall, lodge_roof], "buildings/lodge.glb", AO_HOUSE,
     bevel=0.0, budget=3600)

heli_obj = build_heli_pad()
emit(heli_obj, "structures/heli_pad.glb", AO_STRUCT, bevel=0.0, budget=1100)

container_obj = build_luggage_container()
emit(container_obj, "props/luggage_container.glb", AO_SMALL, bevel=0.0, budget=900)

sign_obj = build_road_sign_blank()
emit(sign_obj, "props/road_sign_blank.glb", AO_SMALL, bevel=0.0, budget=250,
     darken=(MOSS, 0.38))

pole_obj = build_traffic_light_pole()
emit(pole_obj, "props/traffic_light_pole.glb", AO_SMALL, bevel=0.008,
     bevel_angle=65.0, budget=250)

snow_obj = build_snow_pole()
emit(snow_obj, "props/snow_pole.glb", AO_SMALL, bevel=0.0, budget=100)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL village: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([wharf_obj, cafe_wall, cafe_roof, lodge_wall, lodge_roof, heli_obj,
            container_obj, sign_obj, pole_obj, snow_obj],
           "fiordland_village.blend")
