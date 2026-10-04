"""Monument Valley -- vehicule si oameni (brief docs/asset_briefs/monumentvalley_kit.md §1.6).

  monumentvalley/vehicles/pickup_old.glb     pickup ruginit anii '50, 5,2 x 2,0 x 1,9 m
  monumentvalley/vehicles/tour_truck.glb     4x4 albastru cu banchete deschise si cadru, 5,5 x 2,2 x 2,6 m
  monumentvalley/props/tourist_group.glb     4 turisti (1,6-1,8 m), 2 cu aparate foto ridicate, rucsaci

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_vehicles.py

Fara embleme, numere, text sau marci (brief §0 pct. 9). Masinile au botul spre
+Y (= -Z in Godot). Roti cu 10 segmente. Originea: centrul amprentei pe XY,
baza (talpa rotilor / pantofii) pe Z=0.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "monument_shapes.py")).read())
exec(open(os.path.join(_here, "monument_pen.py")).read())

HOLE = VOLCANIC_BLACK
TIMBER_OLD = LOG_DARK

clear_built()
AO_VEH = dict(samples=16, dist=0.9, gradient="vertical",
              low=0.62, high=1.0, power=0.8, floor=0.30)


def rect(x0, x1, y0, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def wheel(wb, cx, cy, r, wid, tire, hub):
    """Roata: cauciuc cu 10 segmente + janta mai ingusta, iesita pe ambele fete."""
    P = Pen(wb)
    P.tube((cx - wid / 2, cy, r), (cx + wid / 2, cy, r), r, r, tire, seg=10)
    P.tube((cx - wid / 2 - 0.015, cy, r), (cx + wid / 2 + 0.015, cy, r), r * 0.5, r * 0.5, hub, seg=10)


def fender_arch(pen, cx, cy, r, wid, slot):
    """Bomba rotunda de aripa deasupra rotii (cilindru pe X, 10 segmente)."""
    ix = cx * 0.88                                   # putin spre interior: cauciucul ramane vizibil pe exterior
    pen.tube((ix - wid / 2, cy, r * 1.2), (ix + wid / 2, cy, r * 1.2), r * 1.15, r * 1.15, slot, seg=10)


# ---------------------------------------------------------------------------
# 1. pickup_old
# ---------------------------------------------------------------------------

def build_pickup_old():
    """`pickup_old.png`. Lista de elemente (numarata pe decupare):
    - CAPOTA lunga si rotunjita, aripi bombate (4 bombe rotunde peste roti),
      grila de fata cu bara de protectie lata, 2 faruri rotunde;
    - CABINA mica, rotunjita, trapezoidala: parbriz inclinat, geam lateral,
      luneta spate; 4 roti cu janta (10 segmente), prag lateral;
    - CAROSERIE de camioneta deschisa: 2 pereti laterali, haion, podea
      (decupare: bena goala, interior bej);
    - RUGINA: tot corpul pe RUST; geamuri VOLCANIC_BLACK; bare/grila CONCRETE.
    Fara embleme. Noduri: Pickup_Body, Pickup_Glass, Pickup_Trim, Pickup_Wheels.
    """
    bd, gl, tr, wh = Builder(), Builder(), Builder(), Builder()
    B, G, T = Pen(bd), Pen(gl), Pen(tr)
    r = 0.42
    wy = (1.55, -1.55)
    # sasiu ascuns + capota
    T.box((0, 0, 0.55), (1.7, 5.0, 0.2), TIMBER_OLD)
    B.loft(chamfer(rect(-0.95, 0.95, 0.85, 2.5), 0.32), 0.6,
           chamfer(rect(-0.8, 0.8, 0.95, 2.38), 0.28), 1.22, RUST)
    # cabina (trapez cu fata inclinata)
    B.loft(chamfer(rect(-0.86, 0.86, -0.95, 0.9), 0.22), 0.6,
           chamfer(rect(-0.74, 0.74, -0.7, 0.45), 0.2), 1.9, RUST)
    # bena: podea, pereti laterali, haion, perete fata
    B.box((0, -1.78, 0.62), (1.84, 1.6, 0.1), SAND_MID)
    for sx in (-1, 1):
        B.box((sx * 0.9, -1.78, 0.95), (0.14, 1.65, 0.62), RUST)
    B.box((0, -2.5, 0.92), (1.9, 0.1, 0.6), RUST)
    B.box((0, -0.98, 1.0), (1.8, 0.1, 0.7), RUST)
    for cy in wy:
        for sx in (-1, 1):
            fender_arch(B, sx * 0.9, cy, r, 0.22, RUST)
    # geamuri
    G.box((0, 0.6, 1.55), (1.22, 0.05, 0.52), HOLE, rot=Matrix.Rotation(0.34, 3, "X"))
    for sx in (-1, 1):
        G.box((sx * 0.79, -0.08, 1.52), (0.05, 0.95, 0.44), HOLE)
    G.box((0, -0.77, 1.6), (0.95, 0.05, 0.36), HOLE, rot=Matrix.Rotation(0.2, 3, "X"))
    # grila, bara, faruri, praguri
    T.box((0, 2.52, 0.95), (0.8, 0.06, 0.42), CONCRETE)
    T.box((0, 2.56, 0.62), (1.9, 0.14, 0.18), CONCRETE)
    T.box((0, -2.55, 0.62), (1.7, 0.1, 0.16), CONCRETE)
    for sx in (-1, 1):
        T.tube((sx * 0.68, 2.46, 1.0), (sx * 0.68, 2.58, 1.0), 0.13, 0.13, CONCRETE, seg=10)
        T.box((sx * 0.92, 0.0, 0.55), (0.1, 1.9, 0.08), TIMBER_OLD)
    for cy in wy:
        for sx in (-1, 1):
            wheel(wh, sx * 0.88, cy, r, 0.26, HOLE, CONCRETE)
    return [bd.to_object("Pickup_Body"), gl.to_object("Pickup_Glass"),
            tr.to_object("Pickup_Trim"), wh.to_object("Pickup_Wheels")]


# ---------------------------------------------------------------------------
# 2. tour_truck
# ---------------------------------------------------------------------------

def build_tour_truck():
    """`tour_truck.png`. Lista de elemente (numarata pe decupare):
    - CAPOTA dreapta cu aripi bombate, grila neagra, 2 faruri rotunde, bara
      de protectie masiva, 4 roti mari cu janta (10 segmente);
    - CAROSERIE albastra: cabina cu parbriz inclinat, portiere pana la mijloc,
      bena lunga pana la 5,5 m; fara embleme, fara numar;
    - CADRU DE BARE (negru) peste bancheta deschisa: 6 stalpi (3 pe parte),
      2 sine de acoperis pe lungime, 3 traverse (decupare: ~3 arcuri);
    - BANCHETE: 3 randuri x 2 locuri, scaune in tonuri de lemn/caramel
      (decupare: 3 randuri cu spatare inalte);
    Noduri: Truck_Body (CAR_BLUE), Truck_Glass, Truck_Trim, Truck_Seats, Truck_Wheels.
    """
    bd, gl, tr, st, wh = Builder(), Builder(), Builder(), Builder(), Builder()
    B, G, T, S = Pen(bd), Pen(gl), Pen(tr), Pen(st)
    r = 0.5
    wy = (1.75, -1.65)
    T.box((0, 0, 0.62), (1.8, 5.3, 0.22), TIMBER_OLD)                       # sasiu
    B.loft(chamfer(rect(-1.0, 1.0, 0.75, 2.7), 0.28), 0.7,
           chamfer(rect(-0.88, 0.88, 0.85, 2.58), 0.22), 1.42, CAR_BLUE)    # capota
    for sx in (-1, 1):
        B.box((sx * 0.96, -1.0, 1.07), (0.14, 3.5, 0.82), CAR_BLUE)         # pereti caroserie
    B.box((0, 0.62, 1.08), (1.9, 0.3, 0.8), CAR_BLUE)                       # torpedo
    B.box((0, -2.62, 1.0), (2.0, 0.14, 0.7), CAR_BLUE)                       # haion
    B.box((0, -0.9, 0.7), (1.9, 3.6, 0.1), TIMBER_OLD)                      # podea
    for cy in wy:
        for sx in (-1, 1):
            fender_arch(B, sx * 1.0, cy, r, 0.24, CAR_BLUE)
    # parbriz
    G.box((0, 0.74, 1.88), (1.8, 0.05, 0.66), HOLE, rot=Matrix.Rotation(0.32, 3, "X"))
    # cadru de bare
    for yy in (0.72, -0.85, -2.0, -2.62):
        for sx in (-1, 1):
            T.tube((sx * 0.97, yy, 1.45), (sx * 0.97, yy, 2.55), 0.05, 0.05, HOLE, seg=6)
        T.tube((-0.97, yy, 2.55), (0.97, yy, 2.55), 0.045, 0.045, HOLE, seg=6)
    for sx in (-1, 1):
        T.tube((sx * 0.97, 0.72, 2.55), (sx * 0.97, -2.62, 2.55), 0.05, 0.05, HOLE, seg=6)
    # bara, grila, faruri
    T.box((0, 2.64, 0.68), (2.1, 0.18, 0.24), CONCRETE)
    T.box((0, 2.62, 1.05), (1.1, 0.08, 0.42), HOLE)
    for sx in (-1, 1):
        T.tube((sx * 0.75, 2.58, 1.28), (sx * 0.75, 2.66, 1.28), 0.13, 0.13, CONCRETE, seg=10)
    T.box((0, -2.7, 0.68), (1.9, 0.12, 0.2), CONCRETE)
    # banchete: 3 randuri x 2 locuri
    for yy in (0.1, -1.05, -2.1):
        for sx in (-1, 1):
            S.box((sx * 0.5, yy, 0.92), (0.8, 0.58, 0.3), WOOD)
            S.box((sx * 0.5, yy - 0.3, 1.36), (0.78, 0.14, 0.78), WOOD)
    for cy in wy:
        for sx in (-1, 1):
            wheel(wh, sx * 0.97, cy, r, 0.28, HOLE, CONCRETE)
    return [bd.to_object("Truck_Body"), gl.to_object("Truck_Glass"), tr.to_object("Truck_Trim"),
            st.to_object("Truck_Seats"), wh.to_object("Truck_Wheels")]


# ---------------------------------------------------------------------------
# 3. tourist_group
# ---------------------------------------------------------------------------

def person(pens, x, y, yaw, h, shirt, pants, hat, camera, pack, shorts=False, ponytail=False,
           brim=0.0, hat_slot=None):
    """Un turist low-poly, cu fata spre +Y local; `h` = inaltimea totala fara
    palarie, `pens` = (haine, piele, accesorii); fara fata detaliata."""
    cl, sk, gr = pens
    M = at(x, y, 0.0, yaw)
    C, K, A = Pen(cl.b, M), Pen(sk.b, M), Pen(gr.b, M)
    s = h / 1.75

    def v(*p):
        return tuple(c * s for c in p)

    top = 0.62 if shorts else 0.08
    for sx in (-1, 1):
        A.box(v(sx * 0.1, 0.05, 0.04), v(0.11, 0.28, 0.08), HOLE)                    # pantofi
        C.tube(v(sx * 0.1, 0, 0.9), v(sx * 0.1, 0, top), 0.11 * s, 0.085 * s, pants, seg=6)
        if shorts:
            K.tube(v(sx * 0.1, 0, top), v(sx * 0.1, 0, 0.08), 0.075 * s, 0.06 * s, CORAL_SAND, seg=6)
    C.box(v(0, 0, 1.17), v(0.44, 0.25, 0.58), shirt)                                  # trunchi
    K.tube(v(0, 0, 1.44), v(0, 0, 1.55), 0.045 * s, 0.045 * s, CORAL_SAND, seg=6)     # gat
    K.ball(v(0, 0.0, 1.63), 0.12 * s, CORAL_SAND, seg=8, rings=6, scale=(1.0, 1.1, 1.15))
    for sx in (-1, 1):
        sh = v(sx * 0.25, 0, 1.4)
        if camera:                                      # coate ridicate, mainile la fata
            el = v(sx * 0.27, 0.16, 1.28)
            hand = v(sx * 0.07, 0.32, 1.55)
        else:
            el = v(sx * 0.27, 0.02, 1.15)
            hand = v(sx * 0.25, 0.08, 0.9)
        C.tube(sh, el, 0.07 * s, 0.06 * s, shirt, seg=6)
        K.tube(el, hand, 0.055 * s, 0.045 * s, CORAL_SAND, seg=6)
    if camera:
        A.box(v(0, 0.36, 1.56), v(0.18, 0.11, 0.11), HOLE)
        A.tube(v(0, 0.41, 1.56), v(0, 0.5, 1.56), 0.045 * s, 0.045 * s, HOLE, seg=8)
    # palarie / sapca
    hz = 1.68 * s
    if brim > 0:                                       # palarie cu boruri late
        C.tube((0, 0, hz + 0.05), (0, 0, hz + 0.075), brim, brim, hat_slot or hat, seg=10)
        C.tube((0, 0, hz + 0.075), (0, 0, hz + 0.16), 0.11, 0.095, hat, seg=10)
    else:                                              # sapca
        C.ball((0, -0.005, hz + 0.04), 0.112, hat, seg=8, rings=4, scale=(1.0, 1.05, 0.78))
        C.box((0, 0.13, hz + 0.0), (0.16, 0.14, 0.025), hat)
    if ponytail:
        A.tube(v(0, -0.1, 1.68), v(0, -0.14, 1.2), 0.06 * s, 0.045 * s, TIMBER_OLD, seg=6)
    if pack:                                           # rucsac
        A.box(v(0, -0.2, 1.17), v(0.32 if pack == 1 else 0.24, 0.17, 0.44 if pack == 1 else 0.3), HOLE)
        A.box(v(0, -0.3, 1.05), v(0.2, 0.05, 0.18), TIMBER_OLD)


def build_tourist_group():
    """`tourist_group.png`. Lista de elemente (numarata pe decupare, 4 oameni
    in rand, de la stanga la dreapta pe planșa):
    - 1: barbat cu aparat foto ridicat la fata, tricou albastru, pantaloni
      kaki, sapca rosie, rucsac mare negru pe spate;
    - 2: barbat in pantaloni scurti inchisi, tricou albastru, sapca rosie,
      rucsac negru, brate jos;
    - 3: femeie cu palarie de paie, tricou coral (CAR_RED), blugi (CAR_BLUE),
      par lung prins, rucsac mic;
    - 4: barbat cu aparat foto ridicat, tricou albastru, pantaloni kaki,
      palarie bej, rucsac mare.
    Inaltimi 1,58-1,75 m; fete fara detalii; fara marci. O singura piesa.
    Noduri: Tourist_Clothes (CAR_BLUE/CAR_RED/SAND_MID), Tourist_Skin
    (CORAL_SAND), Tourist_Gear (rucsaci, aparate, pantofi).
    """
    cl, sk, gr = Builder(), Builder(), Builder()
    pens = (Pen(cl), Pen(sk), Pen(gr))
    person(pens, 1.5, 0.05, 90.0, 1.74, CAR_BLUE, SAND_MID, CAR_RED, camera=True, pack=1)
    person(pens, 0.5, -0.05, 90.0, 1.70, CAR_BLUE, TIMBER_OLD, CAR_RED, camera=False, pack=1, shorts=True)
    person(pens, -0.5, 0.05, -90.0, 1.58, CAR_RED, CAR_BLUE, SAND_LIGHT, camera=False, pack=2,
           ponytail=True, brim=0.26)
    person(pens, -1.5, -0.05, -90.0, 1.72, CAR_BLUE, SAND_MID, SAND_MID, camera=True, pack=1,
           brim=0.2)
    return [cl.to_object("Tourist_Clothes"), sk.to_object("Tourist_Skin"), gr.to_object("Tourist_Gear")]


# ---------------------------------------------------------------------------
# rulare
# ---------------------------------------------------------------------------

PIECES = [
    ("vehicles/pickup_old.glb", build_pickup_old, dict(AO_VEH), 6000),
    ("vehicles/tour_truck.glb", build_tour_truck, dict(AO_VEH), 8000),
    ("props/tourist_group.glb", build_tourist_group, dict(AO_VEH, dist=0.4), 8000),
]

import sys as _sys
_only = None
if "--only" in _sys.argv:
    _only = _sys.argv[_sys.argv.index("--only") + 1].split(",")

for _path, _fn, _ao, _bud in PIECES:
    if _only and os.path.basename(_path)[:-4] not in _only:
        continue
    clear_built()
    emit(list(_fn()), _path, _ao, keep_xy=False, bevel=0.0, smooth_angle=None, budget=_bud)
report()
