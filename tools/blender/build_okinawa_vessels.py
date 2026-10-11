"""Okinawa v2 -- vapoare si barci (brief docs/asset_briefs/okinawa_kit_v2.md §1.5).

  okinawa/vehicles/island_ferry.glb        FERIBOTUL podului ridicator (contract de cod)
  okinawa/vehicles/coastal_freighter.glb   vas de coasta cu punte deschisa (decor static)
  okinawa/vehicles/fishing_boat.glb        barca de pescuit

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_okinawa_vessels.py

Variabila OK_ONLY=<piesa> reface doar piesa respectiva.

CONVENTII (toate trei piesele):
  - ORIGINEA LA LINIA APEI (`verify_glb --origin=waterline`): z=0 e apa, coca
    coboara sub ea cu pescajul. `LiftBridgeHazard.ship_draft = 0` o cere asa.
  - PROVA PE +Y Blender (= -Z Godot, `ship_bow_neg_z = true`). Prova = capatul
    ASCUTIT al conturului; se masoara pe GLB, nu se presupune (vezi
    measure_okinawa_vessels.py).
  - FERIBOTUL: un nod-radacina `Island_Ferry` cu copiii reali `Ferry_Hull`,
    `Ferry_Plaster`, `Ferry_Stripe`, `Ferry_Glass` (codul extrage nodul dupa
    nume). VARFUL (catargul) la 11,0 +- 0,5 m peste linia apei: traveea
    (LIFT_HEIGHT 5 m peste asfaltul de la +8,5 m) trebuie sa se ridice ca sa
    treaca vaporul, dar vaporul trebuie sa incapa dedesubt.
  - Fara text, cifre, nume sau logo-uri pe vase (corectura de coordonator).

Vocabularul de forme: coca = loft intre contururi in plan (aceleasi N puncte,
prova ascutita), peste care vin cabinele ca prisme (`loft`), geamurile ca
cutii in banda, balustrade (`Builder.railing`). Nodurile sunt `to_obj` (fara
recalc de normale: fetele din `loft` au vertecsi proprii).
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

# ---------------------------------------------------------------------------
# coca: contururi in plan, interpolate pe inaltime
# ---------------------------------------------------------------------------

# profilul in plan, de la pupa la prova: (t pe lungime, fractia din semilatime).
# Functia latimii e CONCAVA => conturul e convex (loft-ul cere asta). Prova se
# termina intr-un punct (f=0): capatul ascutit e prova.
HULL_PROF = [(0.0, 0.94), (0.18, 1.0), (0.5, 1.0), (0.72, 0.9), (0.88, 0.6), (1.0, 0.0)]


class Hull:
    """Coca din niveluri (z, y_pupa, y_prova, kw): `kw` = fractia din semilatimea
    maxima W la nivelul respectiv. `plan(z)` interpoleaza liniar parametrii
    intre niveluri, deci contururile intermediare cad EXACT pe fetele loft-ului."""

    def __init__(self, W, levels, prof=HULL_PROF):
        self.W, self.levels, self.prof = W, levels, prof

    def params(self, z):
        lv = self.levels
        if z <= lv[0][0]:
            return lv[0][1:]
        for a, b in zip(lv, lv[1:]):
            if z <= b[0] + 1e-9:
                t = (z - a[0]) / (b[0] - a[0])
                return tuple(a[i] + (b[i] - a[i]) * t for i in (1, 2, 3))
        return lv[-1][1:]

    def plan(self, z, dx=0.0, kwm=1.0, dy=0.0):
        """Contur ANTIORAR (de sus), pupa -> prova pe dreapta, apoi stanga. `dx`
        iese lateral (benzi proeminente), `kwm` inmulteste latimea, `dy` iese in
        prova."""
        ys, yb, kw = self.params(z)
        right = []
        for t, f in self.prof:
            x = f * self.W * kw * kwm + (dx if f > 0 else 0.0)
            y = ys + t * (yb - ys) + (dy if f == 0 else 0.0)
            right.append((x, y))
        left = [(-x, y) for x, y in reversed(right[:-1])]
        return right + left

    def zs(self):
        return [lv[0] for lv in self.levels]


def loft_open(b, bot, z0, top, z1, slot, cap_bottom=False, cap_top=False):
    """Prisma intre doua contururi antiorare; capacele sunt optionale (cand
    corpul sta peste altul, capacele ar fi doar fete ascunse)."""
    n = len(bot)
    for i in range(n):
        j = (i + 1) % n
        _face(b, [(bot[i][0], bot[i][1], z0), (bot[j][0], bot[j][1], z0),
                  (top[j][0], top[j][1], z1), (top[i][0], top[i][1], z1)], slot)
    if cap_top:
        _face(b, [(p[0], p[1], z1) for p in top], slot)
    if cap_bottom:
        _face(b, [(p[0], p[1], z0) for p in reversed(bot)], slot)


def ring_wall(b, outer, inner, z0, z1, slot):
    """Parapet: perete cu grosime, deschis in mijloc. Fata exterioara spre
    afara, cea interioara spre interior, sus un inel plat."""
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        _face(b, [(outer[i][0], outer[i][1], z0), (outer[j][0], outer[j][1], z0),
                  (outer[j][0], outer[j][1], z1), (outer[i][0], outer[i][1], z1)], slot)
        _face(b, [(inner[j][0], inner[j][1], z0), (inner[i][0], inner[i][1], z0),
                  (inner[i][0], inner[i][1], z1), (inner[j][0], inner[j][1], z1)], slot)
        _face(b, [(outer[i][0], outer[i][1], z1), (outer[j][0], outer[j][1], z1),
                  (inner[j][0], inner[j][1], z1), (inner[i][0], inner[i][1], z1)], slot)


def hull_body(b, hull, slot_of_seg, cap_top=True):
    """Coca plina, pe nivelurile ei; `slot_of_seg(i)` = slotul segmentului i."""
    zs = hull.zs()
    for i in range(len(zs) - 1):
        loft_open(b, hull.plan(zs[i]), zs[i], hull.plan(zs[i + 1]), zs[i + 1],
                  slot_of_seg(i), cap_bottom=(i == 0), cap_top=(cap_top and i == len(zs) - 2))


def lip(poly, d):
    """Conturul retras cu -d (adica iesit cu d): streasina cabinei."""
    return inset_convex(poly, -d)


def window_row_x(b, x, ys, z, ln, h, slot, depth=0.08):
    """Geamuri in banda pe un perete cu normala pe X (la x), centrele `ys`."""
    for y in ys:
        b.box((x, y, z), (depth, ln, h), slot)


def window_row_y(b, y, xs, z, ln, h, slot, depth=0.08):
    """Geamuri pe un perete cu normala pe Y (la y), centrele `xs`."""
    for x in xs:
        b.box((x, y, z), (ln, depth, h), slot)


def cabin(b, poly, z0, z1, slot, lip_d=0.12, lip_h=0.14):
    """Cabina = prisma verticala + streasina (lip) la capat; intoarce cota de sus."""
    loft(b, poly, z0, poly, z1, slot, cap_bottom=False)
    big = lip(poly, lip_d)
    loft(b, big, z1, big, z1 + lip_h, slot, cap_bottom=False)
    return z1 + lip_h


# ---------------------------------------------------------------------------
# 1. FERIBOTUL
# ---------------------------------------------------------------------------

FERRY_HULL = Hull(4.0, [(-2.0, -12.4, 9.0, 0.42), (-1.1, -13.5, 11.8, 0.78),
                        (0.0, -13.9, 13.3, 0.96), (1.0, -13.95, 13.7, 0.98), (2.5, -14.0, 14.0, 0.99)])
FERRY_TIP = 11.0       # contract: varful catargului peste linia apei


def build_ferry():
    """`island_ferry` (decuparea `island_ferry.png`) -- LISTA DE ELEMENTE,
    scrisa inainte de primul vertex:

    COCA (nod `Ferry_Hull`, CAR_BLUE 15): 28 m lung, 8 m latime, pescaj 2 m
      (z -2,0 .. +1,5), 4 niveluri / 3 fete in inaltime; pupa dreapta
      (oglinda), prova ASCUTITA pe +Y cu stem ridicat (cap de cala mai scurt
      pe fund: y 9,0 la chila, y 14,0 la punte). Fundul ingust (42% din
      latime), burta rotunjita in doua trepte.
    DUNGA (`Ferry_Stripe`, KERB_RED 7): o centura rosie, 0,4 m inalta, usor
      iesita din coca, pe tot conturul, la capul coastei (z 0,92..1,32).
    BORDUL (`Ferry_Plaster`, FOAM_WHITE 22): placa de punte 0,45 m (z 1,5..1,95)
      care iese in rama alba deasupra dungii (ca pe desen).
    PUNTEA 1: cabina lunga (-11,4..+8,0 m), 2,7 m (z 1,95..4,65), nasul tesit
      in prova; 8 ferestre in banda pe fiecare bord + 2 in fata.
    PUNTEA 2: salonul de sus (-9,6..+1,6 m), 2,2 m (z 4,8..7,0), 6 ferestre pe
      bord + 2 in fata; acoperisul lui = puntea deschisa, cu BALUSTRADA
      (rectangulara, 0,9 m), si balustrada pe acoperisul puntii 1 in jurul lui.
    COMANDA IN FATA: timoneria (y 2,6..6,4; 2,6 m, z 4,8..7,4), ferestre in
      fata (2) si pe laturi (2+2), streasina.
    COSUL: tronconic (8 laturi) pe salon, albastru (`Ferry_Hull`), cu bandă
      rosie la varf (`Ferry_Stripe`).
    CATARGUL: pe timonerie, 3,2 m, cu bara de radar + vergă; lampa de varf.
      VARFUL LA 11,0 m peste linia apei (contract §1.5).
    FERESTRELE: `Ferry_Glass` (VOLCANIC_BLACK 20), cutii retrase 4 cm.
    Fara text/nume/numar.
    """
    H = FERRY_HULL
    bh, bp, bs, bg = Builder(), Builder(), Builder(), Builder()

    # coca albastra + dunga rosie
    hull_body(bh, H, lambda i: CAR_BLUE)
    loft_open(bs, H.plan(1.9, dx=0.05), 1.9, H.plan(2.3, dx=0.05, dy=0.04), 2.3, KERB_RED)

    # bordul alb: placa de punte
    loft_open(bp, H.plan(2.5, kwm=1.0 / 0.99), 2.5, H.plan(2.95, kwm=0.99), 2.95,
              FOAM_WHITE, cap_top=True)

    # puntea 1: cabina lunga cu nasul tesit
    M = [(3.2, -11.4), (3.2, 3.0), (2.8, 6.0), (1.7, 8.0),
         (-1.7, 8.0), (-2.8, 6.0), (-3.2, 3.0), (-3.2, -11.4)]
    roof1 = cabin(bp, M, 2.95, 5.35, FOAM_WHITE)               # 4,79
    # puntea 2: salonul de sus
    S = [(2.85, -9.6), (2.85, 0.2), (2.3, 1.6), (-2.3, 1.6), (-2.85, 0.2), (-2.85, -9.6)]
    roof2 = cabin(bp, S, roof1, roof1 + 2.0, FOAM_WHITE)         # 7,13
    # timoneria in fata
    Wh = [(2.3, 2.6), (2.3, 5.2), (1.5, 6.4), (-1.5, 6.4), (-2.3, 5.2), (-2.3, 2.6)]
    roof3 = cabin(bp, Wh, roof1, roof1 + 2.6, FOAM_WHITE)        # 7,53

    # cosul: tronconic albastru + banda rosie
    fy = -4.6
    bh.frustum((0.0, fy, roof2 + 1.2), 0.85, 0.70, 2.4, CAR_BLUE, segments=8)
    bs.frustum((0.0, fy, roof2 + 2.12), 0.80, 0.735, 0.5, KERB_RED, segments=8)

    # catargul: pe timonerie, varful la 11,0
    mx, my = 0.0, 4.4
    m0, m1 = roof3, FERRY_TIP - 0.25
    bp.frustum((mx, my, (m0 + m1) * 0.5), 0.13, 0.08, m1 - m0, FOAM_WHITE, segments=6)
    bp.cylinder((mx, my, FERRY_TIP - 0.125), 0.10, 0.25, FOAM_WHITE, segments=6)
    bp.box((mx, my, FERRY_TIP - 0.85), (2.3, 0.12, 0.12), FOAM_WHITE)          # verga
    bp.box((mx, my, FERRY_TIP - 1.9), (1.2, 0.14, 0.14), FOAM_WHITE)           # radar
    bp.box((mx, my, FERRY_TIP - 1.65), (0.1, 0.1, 0.5), FOAM_WHITE)

    # balustrade: pe acoperisul puntii 1 (in jurul salonului) si pe salon
    for sx in (-1, 1):
        bp.railing((sx * 3.1, -11.2, roof1), (sx * 3.1, 2.3, roof1), 0.9, 1.5, 0.1, 0.07, FOAM_WHITE, rails=2)
        bp.railing((sx * 2.78, -9.5, roof2), (sx * 2.78, 0.1, roof2), 0.9, 1.6, 0.1, 0.07, FOAM_WHITE, rails=2)
    bp.railing((-3.1, -11.2, roof1), (3.1, -11.2, roof1), 0.9, 1.55, 0.1, 0.07, FOAM_WHITE, rails=2)
    bp.railing((-2.78, -9.5, roof2), (2.78, -9.5, roof2), 0.9, 1.4, 0.1, 0.07, FOAM_WHITE, rails=2)

    # accesorii pe puntea 1 in prova: cabestan + bita (siluete mici)
    bp.box((0.0, 10.4, 3.25), (1.4, 1.3, 0.6), FOAM_WHITE)
    bp.cylinder((0.0, 11.8, 3.3), 0.28, 0.7, FOAM_WHITE, segments=6)

    # ferestre
    ys1 = [-10.0 + 1.75 * k for k in range(8)]
    for sx in (-1, 1):
        window_row_x(bg, sx * 3.2, ys1, 3.9, 1.35, 0.95, VOLCANIC_BLACK)
        window_row_x(bg, sx * 2.85, [-9.0 + 1.6 * k for k in range(6)], roof1 + 1.0, 1.2, 1.05, VOLCANIC_BLACK)
        window_row_x(bg, sx * 2.3, [3.5, 4.7], roof1 + 1.5, 1.0, 0.95, VOLCANIC_BLACK)
    window_row_y(bg, 8.0, [-0.7, 0.7], 3.9, 0.9, 0.95, VOLCANIC_BLACK)
    window_row_y(bg, 1.6, [-1.15, 1.15], roof1 + 1.0, 1.5, 1.05, VOLCANIC_BLACK)
    window_row_y(bg, 6.4, [-0.75, 0.75], roof1 + 1.5, 1.3, 0.95, VOLCANIC_BLACK)

    return [to_obj(bh, "Ferry_Hull"), to_obj(bp, "Ferry_Plaster"),
            to_obj(bs, "Ferry_Stripe"), to_obj(bg, "Ferry_Glass")]


# ---------------------------------------------------------------------------
# 2. VASUL DE COASTA
# ---------------------------------------------------------------------------

FREIGHTER_HULL = Hull(4.0, [(-2.3, -14.5, 12.5, 0.55), (-1.3, -16.3, 15.0, 0.90),
                            (0.0, -16.9, 16.3, 1.0), (0.5, -16.95, 16.5, 1.0),
                            (2.0, -17.0, 17.0, 1.0)])


def build_freighter():
    """`coastal_freighter` (decuparea `coastal_freighter.png` + corectura:
    PUNTE DESCHISA, nu portcontainer) -- LISTA DE ELEMENTE:

    COCA (`Freighter_Hull`): 34 m lung, 8 m latime, pescaj 2,3 m; doua culori:
      sub linia plutirii (z < 0,5) ROSU (KERB_RED 7), deasupra ALBASTRU
      (CAR_BLUE 15, `--allow-car-slots=Freighter_Hull`); prova ascutita pe +Y,
      stem inalt, fund plat.
    PARAPETUL (`Freighter_Plaster`, FOAM_WHITE): inel alb 0,65 m pe tot bordul
      (z 2,0..2,65) -- rama alba de pe desen.
    PUNTEA (`Freighter_Deck`, RUST 10): placa pe toata coca; 4 pereti joasi
      (0,5 m) in jurul gurii de magazie din prova (y 2..12); 3 LADE mici
      (lemn / nisip / beton) + 2 PALETI in magazie; punte deschisa, fara stive.
    CABINA pe PUPA (`Freighter_Plaster`): doua nivele (z 2,25..4,8 si
      4,8..6,7, y -15,0..-8,5), 6+3 ferestre pe bord, timonerie cu geamuri in
      fata.
    COSUL (`Freighter_Hull`, albastru) in spatele timoneriei.
    CATARGUL-RADAR pe timonerie (z ~12 m, vergă + bara de radar); CATARG DE
      PROVA (alb, 2 verge) la y 13,2.
    MACARAUA DE PUNTE: stalp + brat inclinat peste magazie, pe tribord.
    FERESTRE `Freighter_Glass` (VOLCANIC_BLACK 20). Fara text/numar.
    """
    H = FREIGHTER_HULL
    bh, bd, bp, bg = Builder(), Builder(), Builder(), Builder()

    hull_body(bh, H, lambda i: KERB_RED if i < 3 else CAR_BLUE)
    # parapet
    ring_wall(bp, H.plan(2.0), H.plan(2.0, kwm=0.93), 2.0, 2.65, FOAM_WHITE)
    # puntea
    loft_open(bd, H.plan(2.0, kwm=0.95), 2.0, H.plan(2.25, kwm=0.95), 2.25, RUST, cap_top=True)
    # magazia: 4 pereti joasi + lazi
    for sx in (-1, 1):
        bd.box((sx * 2.4, 7.0, 2.5), (0.2, 10.0, 0.5), RUST)
    bd.box((0.0, 2.0, 2.5), (4.6, 0.2, 0.5), RUST)
    bd.box((0.0, 12.0, 2.5), (4.6, 0.2, 0.5), RUST)
    bd.box((-0.9, 9.6, 3.0), (1.5, 1.7, 1.2), WOOD)
    bd.box((0.9, 6.4, 2.95), (1.6, 1.5, 1.1), CONCRETE)
    bd.box((-0.7, 4.0, 2.85), (1.4, 1.4, 0.9), SAND_MID)
    bd.box((1.0, 10.0, 2.5), (1.1, 1.1, 0.25), WOOD)
    bd.box((-0.6, 7.2, 2.5), (1.1, 1.1, 0.25), WOOD)

    # cabina pe pupa
    C1 = [(3.3, -15.0), (3.3, -9.3), (2.9, -8.5), (-2.9, -8.5), (-3.3, -9.3), (-3.3, -15.0)]
    roof1 = cabin(bp, C1, 2.25, 4.8, FOAM_WHITE)                 # 4,94
    C2 = [(2.7, -14.2), (2.7, -10.8), (2.2, -9.8), (-2.2, -9.8), (-2.7, -10.8), (-2.7, -14.2)]
    roof2 = cabin(bp, C2, roof1, roof1 + 1.9, FOAM_WHITE)         # 6,98
    # cosul
    bh.frustum((0.0, -13.1, roof1 + 1.4), 0.8, 0.65, 2.8, CAR_BLUE, segments=8)
    # catarg-radar pe timonerie
    cx, cy = 0.0, -11.6
    bp.frustum((cx, cy, (roof2 + 11.4) * 0.5), 0.15, 0.10, 11.4 - roof2, FOAM_WHITE, segments=6)
    bp.box((cx, cy, 11.7), (1.7, 0.14, 0.25), FOAM_WHITE)
    bp.box((cx, cy, 11.4 + 0.1), (0.2, 0.2, 0.3), FOAM_WHITE)
    bp.cylinder((cx, cy, 11.9), 0.08, 0.3, FOAM_WHITE, segments=6)
    bp.box((cx, cy, 10.2), (2.2, 0.1, 0.1), FOAM_WHITE)
    # catarg de prova
    fx, fy = 0.0, 13.2
    bp.frustum((fx, fy, (2.25 + 8.8) * 0.5), 0.17, 0.09, 8.8 - 2.25, FOAM_WHITE, segments=6)
    bp.box((fx, fy, 7.4), (2.3, 0.1, 0.1), FOAM_WHITE)
    bp.box((fx, fy, 8.1), (1.4, 0.1, 0.1), FOAM_WHITE)
    bp.box((fx, fy, 8.85), (0.25, 0.25, 0.25), FOAM_WHITE)
    # macaraua de punte, pe tribord, peste magazie
    bp.box((2.7, -5.0, 4.4), (0.8, 0.8, 4.3), FOAM_WHITE)
    bp.box((2.7, -5.0, 2.55), (1.6, 1.6, 0.6), FOAM_WHITE)
    bp.beam((2.7, -5.0, 6.2), (2.0, 3.8, 7.6), 0.34, FOAM_WHITE)
    bp.beam((2.7, -5.0, 6.7), (2.7, -8.2, 5.6), 0.12, FOAM_WHITE)
    # castelul prova
    bp.box((0.0, 14.6, 2.9), (1.8, 1.5, 0.9), FOAM_WHITE)

    # ferestre
    for sx in (-1, 1):
        window_row_x(bg, sx * 3.3, [-14.0 + 1.5 * k for k in range(4)], 3.65, 1.1, 0.9, VOLCANIC_BLACK)
        window_row_x(bg, sx * 2.7, [-13.2 + 1.2 * k for k in range(3)], roof1 + 1.0, 0.9, 0.8, VOLCANIC_BLACK)
    window_row_y(bg, -8.5, [-1.6, 0.0, 1.6], 3.65, 1.0, 0.9, VOLCANIC_BLACK)
    window_row_y(bg, -9.8, [-1.4, 0.0, 1.4], roof1 + 1.0, 1.0, 0.8, VOLCANIC_BLACK)

    return [to_obj(bh, "Freighter_Hull"), to_obj(bd, "Freighter_Deck"),
            to_obj(bp, "Freighter_Plaster"), to_obj(bg, "Freighter_Glass")]


# ---------------------------------------------------------------------------
# 3. BARCA DE PESCUIT
# ---------------------------------------------------------------------------

BOAT_HULL = Hull(1.4, [(-0.9, -3.2, 2.8, 0.50), (-0.4, -4.2, 3.9, 0.85),
                       (0.0, -4.4, 4.3, 0.97), (0.95, -4.5, 4.5, 1.0)])


def build_boat():
    """`fishing_boat` (decuparea `fishing_boat.png`) -- LISTA DE ELEMENTE:

    COCA (`Boat_Hull`, FOAM_WHITE 22): 9 m lung, 2,8 m latime, pescaj 0,9 m,
      prova ascutita pe +Y, bord inalt (parapet alb 0,4 m, grosime 0,2 m).
    DUNGA (`Boat_Stripe`, CAR_BLUE 15): o centura albastra 0,5 m pe tot bordul,
      sub linia plutirii-sus (z -0,3..0,2).
    CABINA IN FATA (alba): y 0,2..2,6, 2,25 m inalta (z 0,95..3,0) + streasina,
      acoperisul la 3,2 m peste apa; geamuri `Boat_Glass`: 2 in fata, 2 pe bord.
    CATARG mic in spatele cabinei (y -0,7, pana la 4,4 m) cu o verga.
    PICUL de la pupa: stalp + brat lateral (macaraua de plasa), tribord.
    PUNTEA din spate: 2 lazi albe + capac de magazie.
    """
    H = BOAT_HULL
    bh, bs, bg = Builder(), Builder(), Builder()

    hull_body(bh, H, lambda i: FOAM_WHITE)
    ring_wall(bh, H.plan(0.95), H.plan(0.95, kwm=0.86), 0.95, 1.35, FOAM_WHITE)
    loft_open(bs, H.plan(-0.5, dx=0.04), -0.5, H.plan(0.4, dx=0.04, dy=0.03), 0.4, CAR_BLUE)

    K = [(1.0, 0.2), (1.0, 2.0), (0.7, 2.6), (-0.7, 2.6), (-1.0, 2.0), (-1.0, 0.2)]
    roof = cabin(bh, K, 0.95, 3.0, FOAM_WHITE, lip_d=0.10, lip_h=0.2)        # 3,2
    # catarg + verga
    bh.frustum((0.0, -0.8, (1.0 + 4.4) * 0.5), 0.09, 0.06, 3.4, FOAM_WHITE, segments=6)
    bh.box((0.0, -0.8, 3.7), (1.7, 0.08, 0.08), FOAM_WHITE)
    bh.box((0.0, -0.8, 4.35), (0.2, 0.2, 0.2), FOAM_WHITE)
    # picul de la pupa
    bh.frustum((0.9, -3.5, 1.9), 0.09, 0.07, 1.9, FOAM_WHITE, segments=6)
    bh.beam((0.9, -3.5, 2.8), (1.35, -3.5, 2.55), 0.12, FOAM_WHITE)
    # punte: lazi, capac
    bh.box((-0.4, -2.6, 1.2), (0.7, 0.7, 0.5), FOAM_WHITE)
    bh.box((0.4, -1.9, 1.15), (0.6, 0.6, 0.4), FOAM_WHITE)
    bh.box((0.0, -3.4, 1.05), (1.1, 0.8, 0.2), FOAM_WHITE)

    window_row_y(bg, 2.6, [-0.33, 0.33], 2.1, 0.5, 0.7, VOLCANIC_BLACK, depth=0.07)
    for sx in (-1, 1):
        window_row_x(bg, sx * 1.0, [1.0, 1.8], 2.1, 0.55, 0.7, VOLCANIC_BLACK, depth=0.07)

    return [to_obj(bh, "Boat_Hull"), to_obj(bs, "Boat_Stripe"), to_obj(bg, "Boat_Glass")]


# ---------------------------------------------------------------------------
# rulare
# ---------------------------------------------------------------------------

ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


def _drop(objs):
    for o in objs:
        bpy.data.objects.remove(o, do_unlink=True)


if _want("island_ferry"):
    objs = build_ferry()
    emit_ok_placed(objs, "vehicles/island_ferry.glb",
                   dict(samples=14, dist=3.0, gradient="vertical", low=0.6, high=1.0,
                        power=0.8, floor=0.3, z_range=(-2.0, 11.0)),
                   root="Island_Ferry", bevel=0.0, smooth_angle=None, budget=6000)
    _drop(objs)

if _want("coastal_freighter"):
    objs = build_freighter()
    emit_ok_placed(objs, "vehicles/coastal_freighter.glb",
                   dict(samples=14, dist=3.0, gradient="vertical", low=0.6, high=1.0,
                        power=0.8, floor=0.3, z_range=(-2.3, 12.0)),
                   bevel=0.0, smooth_angle=None, budget=6000)
    _drop(objs)

if _want("fishing_boat"):
    objs = build_boat()
    emit_ok_placed(objs, "vehicles/fishing_boat.glb",
                   dict(samples=14, dist=1.5, gradient="vertical", low=0.6, high=1.0,
                        power=0.8, floor=0.3, z_range=(-0.9, 4.4)),
                   bevel=0.0, smooth_angle=None, budget=4000)
    _drop(objs)

report_ok()
