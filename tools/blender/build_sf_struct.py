"""San Francisco (Track25), valul 3: STRUCTURILE (placa turnanta, magaziile de chei, insula cu
far, fundalul, scara publica, leii de mare pe pluta).

Contract: docs/asset_briefs/sanfrancisco_inventory.md §5.1 (H4, H6), §5.4 (N1), §5.5 (F1, F2, T1),
§1.8 (fundalul: variantele = copii directi ai radacinii, alese dupa nume), §4 (distantele:
insula si fundalul sunt SILUETA, 170-360 m, in pacla). Regulile comune (atlas pe centre de slot,
AO copt, scara metrica, scala/rotatie aplicate, fara text/firme/sigle, nimic mai subtire de
0,08 m langa drum, fara sloturile 14-16 si 30) sunt cele din docs/asset_briefs/sf_cable_car.md
§5-§9. Decuparile de caracter: docs/track_briefs/img/sf_assets_v1/sf_<piesa>.png. Unde decuparea
si inventarul nu se potrivesc pe cote, castiga inventarul.

  structures/sf_turntable.glb        Turntable_Deck, Turntable_Booth    (H4)
  structures/sf_pier_shed.glb        PierShed                           (H6, 20 x 12 m)
  structures/sf_pier_shed_short.glb  PierShed_Short                     (H6, 12 x 12 m)
  structures/sf_island_light.glb     Island_Rock, Island_Light          (F1)
  structures/sf_horizon.glb          Hill_A, Hill_B, Hill_C, City_A, City_B  (F2)
  props/sf_stair_lane.glb            StairLane                          (N1)
  animals/sf_sea_lions.glb           SeaLions                           (T1, UN nod pentru FlockProp)

Axe (Blender): X = latimea, Y = -Z Godot (+Y Blender = FATA, -Z Godot), Z = sus. Toate piesele se
construiesc DIRECT in cadrul final (fara recentrare per nod: memoria
finish-recentreaza-fiecare-nod-separat), cu nodurile la identitate.

LISTA DE ELEMENTE -- acceptarea se face element cu element, pe randare langa decupare.

H4 -- placa turnanta (`sf_turntable.png`). Originea in centrul discului, la sol (Y 0).
  Nodul Turntable_Deck (NIMIC peste +0,12):
  T1. Bordura de piatra: inel de 24 de blocuri (r 4,55..5,00, 0..+0,12), alternand CONCRETE 8 /
      MARBLE_GREY 29, cu rosturi de 3 cm (blocurile se citesc separat, ca in decupare).
  T2. Fundul gropii, intunecat (VOLCANIC_BLACK 20): disc r 4,55, 0..+0,02; se vede in rostul
      dintre scanduri si bordura si intre scanduri.
  T3. Platforma de lemn: 16 scanduri (WOOD_WEATHERED 9, doua inlocuite in LOG_DARK 28) de-a
      curmezisul sinelor, taiate pe cerc (r 4,42), +0,02..+0,05: discul are fata la +0,05.
  T4. Dunga galbena de pe platforma (SAND_LIGHT 0): inel r 3,75..3,88, +0,05..+0,058.
  T5. Cele doua sine de-a lungul lui Z (Godot), ecartament 1,10 intre fetele interioare: capul
      PAINTED_METAL 11 (0,08 lat, pana la +0,10), talpa ASPHALT_EDGE 6 (0,15 lata, +0,05..+0,065),
      pe toata coarda discului.
  T6. Pivotul central (ASPHALT_EDGE 6): placa r 0,42, +0,05..+0,065, intre sine.
  Nodul Turntable_Booth (2 x 2 x 2,6 m, pe +X, in afara discului: x 5,35..7,35):
  B1. Soclu de beton (CONCRETE 8), 2,0 x 2,0, 0..+0,15.
  B2. Peretii de jos rosii (KERB_RED 7), 1,8 x 1,8, pana la +1,05.
  B3. Brau alb (FOAM_WHITE 22) la +1,05..+1,15.
  B4. Peretii de sus crem (CORAL_SAND 19) pana la +2,15, cu ferestre pe trei laturi (geam
      VOLCANIC_BLACK 20, rama si montant FOAM_WHITE 22).
  B5. Usa pe -X (spre disc): panou LOG_DARK 28 cu geam sus, rama alba.
  B6. Stalpii de colt albi (22), 0,12 x 0,12.
  B7. Cornisa alba (22), 1,96 x 1,96, +2,15..+2,25.
  B8. Acoperisul in patru ape rosu (KERB_RED 7): streasina 2,0 x 2,0 la +2,25..+2,32, varful la
      +2,60 (gabaritul gheretei = exact 2 x 2 x 2,6).

H6 -- magazia de chei (`sf_pier_shed.png`). Originea in centrul amprentei, la cota puntii (Y 0 =
fata de sus a puntii); frontonul arcuit pe -Z Godot (+Y Blender). Lunga: 20 m pe Z, scurta 12.
  S1. Corpul: contur de fronton (pereti de 5,4 m, arc de cerc pana la +8,8) extrudat pe lungime,
      12 m lat, WOOD_WEATHERED 9.
  S2. Scandurile verticale (sipci de 0,12 m, iesite 0,05, LARCH_RUST 27) pe ambele frontoane si
      pe laturi, la ~1 m, intrerupte la usa si la ferestre.
  S3. Acoperisul de tabla arcuit (PAINTED_METAL 11): coaja de 0,2 m, 12 segmente, cheia la +9,0,
      streasina iesita 0,3-0,4 m pe laturi si 0,45 m peste frontoane.
  S4. Ancadramentele albe (FOAM_WHITE 22): scandura de bordaj pe arcul ambelor frontoane,
      scandurile de colt, braul de streasina pe laturi.
  S5. Usa glisanta mare pe fronton: doua canate LOG_DARK 28 de 2,5 x 4,5 m, traversa si
      contrafise in Z albe (22), toc si buiandrug albi, sina de glisare intunecata (20) care
      continua pe o parte (usa culiseaza).
  S6. Fereastra din fronton (fata si spate): geam 20, rama si montant 22.
  S7. Ferestrele de pe laturi (4 pe latura la cea lunga, 2 la cea scurta): geam 20, rama 22.
  S8. Plinta intunecata (LOG_DARK 28), 0..+0,35, de jur imprejur.
  S9. Puntea de scanduri (WOOD_WEATHERED 9), 1 m de jur imprejurul magaziei, fata la Y 0, groasa
      0,15; grinda de bordura LOG_DARK 28 sub ea.
  S10. Pilonii (LOG_DARK 28), ⌀ 0,5, de sub punte pana la Y -6, pe perimetru, la <= 3,7 m;
       cei de colt si doi din fata urca la +1,0 ca stalpi de amarare (decuparea).
  S11. Cleste orizontal (LOG_DARK 28) la -2,2 pe exteriorul pilonilor.
  Fara firme, fara text.

F1 -- insula cu far (fara decupare; brief: stanca joasa si lunga, gri, cu far alb). Originea in
centrul stancii, la nivelul apei (Y 0); fusta pana la -3.
  I1. Stanca: grila polara (40 de laturi x 11 inele) pe un contur ondulat ~60 x 40 m; profil
      joas la vest (coada de ~+2,6, un umar de ~+5,7), sa la ~+4,9, urca la +10 la est.
  I2. Faleza: inelele exterioare cad abrupt pana la apa (+0,7 la r 0,94) si sub ea (-3).
  I3. Culorile: VOLCANIC_BLACK 20 pe faleza (banda continua a inelelor exterioare, r > 0,80) si
      pe banda uda de la apa,
      MARBLE_GREY 29 pe spinarea stancii, petice de iarba uscata DRY_VEGETATION 13 pe fetele plane
      de sus.
  I4. Bolovani la apa (9, MARBLE_GREY 29 / VOLCANIC_BLACK 20), pe jumatate in apa.
  Nodul Island_Light (farul, pe cota cea mai inalta, x +18):
  L1. Soclu rotund de beton (CONCRETE 8), r 2,6, ingropat 0,8.
  L2. Turnul alb (FOAM_WHITE 22), trunchi de con r 1,6 -> 1,15, 10,6 m.
  L3. Galeria intunecata (20) cu parapet inelar.
  L4. Felinarul (SAND_LIGHT 0, AO 1,0: e lumina), r 0,95, 1,75 m.
  L5. Capacul rosu conic (KERB_RED 7) si varful intunecat: farul are 15,0 m peste stanca.

F2 -- fundalul (`sf_horizon.png`). Fiecare nod centrat pe originea lui, la baza (Z min = 0), volum
inchis lizibil din orice azimut (inelul il roteste).
  Hill_A/B/C:
  D1. Corpul: camp de cocoase gaussiene rotunjite (maxim moale) pe o elipsa, grila de ~11 m,
      inchis cu poala si evantai la baza. A: 260 x 110 m, 45 m; B: 220 x 96 m, 34 m (doua
      cocoase); C: 300 x 120 m, 58 m.
  D2. Culorile: DRY_VEGETATION 13 (paiul uscat) pe tot corpul, SAND_LIGHT 0 (auriul deschis) pe
      crestele luminate de peste ~50 % din inaltime; limita urmeaza cota (o banda).
  D3. Aflorimente de granit gri (MARBLE_GREY 29): 2-3 grupuri de bolovani mari la poale si pe un
      flanc, pe jur imprejur.
  D4. 2-3 chiparosi aplecati de vant (trunchi LOG_DARK 28 inclinat, coroana TROPICAL_GREEN 21 in
      2-3 straturi plate impinse sub vant) + 2-3 tufe joase intunecate.
  City_A (230 x 60 m) / City_B (180 x 52 m):
  C1. Turnuri de 40-80 m, cutii CU ACOPERIS PLAT, unele in trepte (2-3 tronsoane, fiecare
      >= 0,55 din aria celui de dedesubt); NICIO piramida, nicio turla, niciun reper recognoscibil.
  C2. Cladiri joase (10-24 m) la baza, in fata si in spate, ca silueta sa nu stea pe un fir.
  C3. Mici volume tehnice (cutii) pe unele acoperisuri.
  C4. Culorile: PAINTED_METAL 11 (albastru-gri), CONCRETE 8, MARBLE_GREY 29, per volum.
  Fara pod.

N1 -- scara publica (`sf_stair_lane.png`). Originea in centrul muchiei din fata a palierului de
jos, la sol; urca spre +Z Godot (-Y Blender). Modul: 2,5 m lat, 5,0 m adancime, +3,0 m; urmatorul
modul se pune la (0, +3,0, +5,0) si palierul lui de jos continua palierul de sus al acestuia.
  N1. Palierul de jos (0..0,6 m, fata la +0,15) si palierul de sus (4,4..5,0 m, fata la +3,15).
  N2. 16 trepte de 0,1875 x 0,253, intre ziduri (2,0 m liber): fetele de calcare CONCRETE 8,
      contratreptele MARBLE_GREY 29; masa plina pana la sol.
  N3. Zidurile laterale pline de 0,25 m (CONCRETE 8), paralele cu panta, ~0,95 m peste trepte.
  N4. Copertina alba (FOAM_WHITE 22) pe ziduri, in trei bucati (plat jos, panta, plat sus).
  N5. Patru pile patrate albe (22) cu capac: doua jos, doua sus.

T1 -- leii de mare pe pluta (`sf_sea_lions.png`). UN nod `SeaLions`; originea in centrul plutei,
la apa (Y 0).
  P1. Pluta 4 x 3 m: 8 scanduri pe lungime (WOOD_WEATHERED 9, una LOG_DARK 28), fata la +0,30.
  P2. Trei grinzi transversale si doi busteni-plutitori (LOG_DARK 28), pe jumatate in apa.
  P3. Coltare de metal (RUST 10) si un stalp de amarare (28).
  Patru lei (SAND_SHADOW 2, unul ROCK_DARK 4), fiecare: corp eliptic pe o coloana curba (piept
  gros, gat LUNG, cap mic cu bot ascutit), inotatoarele din fata MARI proptite pe scanduri,
  cele din spate rasfirate inapoi, urechi ca doua umflaturi, ochi si nas VOLCANIC_BLACK 20:
  L1. unul ridicat sus pe inotatoare, cu botul in sus (decuparea, centru);
  L2. unul intins, dormind, cu capul pe scanduri;
  L3. unul pe jumatate ridicat, intors spre ceilalti;
  L4. un pui intins (0,7).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_struct.py [-- --only=turntable,shed,...]
  grupuri: turntable, shed, island, horizon, stair, lions
Verificare: tools/blender/measure_sf_struct.py (+ --selftest) si verify_glb.py pe fiecare.
Randari de control: preview_sf_struct.py.
"""

import math
import os
import sys
import bmesh
import bpy
from mathutils import Matrix, Vector

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "sf_struct_shapes.py"), encoding="utf-8").read())

WHITE = FOAM_WHITE          # 22
DARK = VOLCANIC_BLACK       # 20
STONE = MARBLE_GREY         # 29
CREAM = CORAL_SAND          # 19
RED = KERB_RED              # 7
STEEL = PAINTED             # 11
GRASS = DRY_VEGETATION      # 13


# ============================================================ lantul comun
def uv_from_slots(o):
    """UV pe centrul slotului, citit DIRECT din atributul de fata `slot`.

    Fara bevel topologia nu se schimba, deci nu e nevoie de `snapshot_slots` + `assign_uvs`
    (cel mai apropiat triunghi de centrul fetei). Ala gresea aici: centrul unei scanduri lungi
    a placii cadea exact sub talpa sinei (distanta 0 la ambele), iar scandura lua slotul talpii
    -- banda gri din mijlocul placii la prima randare."""
    me = o.data
    attr = me.attributes["slot"]
    uv = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        u = slot_u(int(attr.data[poly.index].value))
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)
    me.attributes.remove(attr)


def make(name, fn, ao, smooth=None):
    """Construieste in cadrul final (FARA recentrare), UV pe sloturi, AO copt."""
    b = Builder()
    fn(b)
    o = b.to_object(name)
    apply_smooth(o, smooth)
    uv_from_slots(o)
    o.data.materials.clear()
    o.data.materials.append(atlas_material())
    zs = [v.co.z for v in o.data.vertices]
    ao = dict(ao)
    ao.setdefault("z_range", (min(zs), max(zs)))
    bake_ao(o, **ao)
    return o


def report(o):
    xs = [v.co.x for v in o.data.vertices]
    ys = [v.co.y for v in o.data.vertices]
    zs = [v.co.z for v in o.data.vertices]
    print("  %-16s %6d tris  AABB Godot X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f"
          % (o.name, tri_count(o), min(xs), max(xs), min(zs), max(zs), -max(ys), -min(ys)))


def export(objs, rel, blend=None):
    for o in objs:
        report(o)
    print("export:", export_glb(objs, rel))
    if blend:
        print("blend:", save_blend(objs, blend))


# ============================================================ H4: placa turnanta
TT_R = 5.0
DECK_R = 4.42
GAUGE_IN = 0.55             # fata interioara a sinei (ecartament 1,10)
RAIL_W = 0.08
RAIL_TOP = 0.10


def tt_deck(b):
    # T1 bordura de piatra: 24 de blocuri cu rosturi
    n = 24
    gap = 0.03 / 4.8
    for k in range(n):
        a0 = 2 * math.pi * k / n + gap
        a1 = 2 * math.pi * (k + 1) / n - gap
        annulus(b, 4.55, TT_R, 0.0, 0.12, TILE_TERRACOTTA if k % 2 == 0 else ROCK_LIGHT, seg=1, a0=a0, a1=a1)
    # T2 fundul gropii
    b.cylinder((0, 0, 0.01), 4.55, 0.02, DARK, segments=24)
    # T3 scandurile, de-a curmezisul sinelor (lungi pe X), taiate pe cerc
    planks = 16
    pw = 2 * DECK_R / planks
    for k in range(planks):
        ya = -DECK_R + k * pw + 0.02
        yb = -DECK_R + (k + 1) * pw - 0.02
        ym = (ya + yb) * 0.5

        def xr(y):
            return math.sqrt(max(DECK_R * DECK_R - y * y, 0.04))
        outline = [(-xr(ya), ya), (xr(ya), ya), (xr(ym), ym), (xr(yb), yb), (-xr(yb), yb), (-xr(ym), ym)]
        slot = LARCH_RUST if k in (4, 11) else WOOD
        lo = [b.bm.verts.new((x, y, 0.02)) for x, y in outline]
        hi = [b.bm.verts.new((x, y, 0.05)) for x, y in outline]
        b.bm.faces.new(tuple(hi))
        b.bm.faces.new(tuple(reversed(lo)))
        for i in range(len(outline)):
            j = (i + 1) % len(outline)
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        b._tag(lo + hi, slot)
    # T4 dunga galbena
    annulus(b, 3.75, 3.88, 0.05, 0.058, SAND_LIGHT, seg=32, bottom=False)
    # T5 sinele (de-a lungul lui Y Blender = Z Godot)
    yr = math.sqrt(DECK_R ** 2 - (GAUGE_IN + RAIL_W) ** 2) - 0.02
    for s in (-1, 1):
        x0, x1 = sorted((s * GAUGE_IN, s * (GAUGE_IN + RAIL_W)))
        box_mm(b, x0, x1, -yr, yr, 0.065, RAIL_TOP, STEEL)
        xm = (x0 + x1) * 0.5
        box_mm(b, xm - 0.075, xm + 0.075, -yr, yr, 0.05, 0.065, ASPHALT_EDGE)
    # T6 pivotul
    b.cylinder((0, 0, 0.0575), 0.42, 0.015, ASPHALT_EDGE, segments=12)


BOOTH_X0, BOOTH_X1 = 5.15, 7.15


def _win_x(b, x, sgn, yc, w, z0, z1):
    """Fereastra pe o fata perpendiculara pe X (la x, iesind spre sgn)."""
    xs = sorted((x, x + sgn * 0.03))
    box_mm(b, xs[0], xs[1], yc - w / 2 - 0.07, yc + w / 2 + 0.07, z0 - 0.07, z1 + 0.07, WHITE)
    xs = sorted((x, x + sgn * 0.05))
    box_mm(b, xs[0], xs[1], yc - w / 2, yc + w / 2, z0, z1, DARK)
    xs = sorted((x, x + sgn * 0.07))
    box_mm(b, xs[0], xs[1], yc - 0.04, yc + 0.04, z0, z1, WHITE)


def _win_y(b, y, sgn, xc, w, z0, z1):
    ys = sorted((y, y + sgn * 0.03))
    box_mm(b, xc - w / 2 - 0.07, xc + w / 2 + 0.07, ys[0], ys[1], z0 - 0.07, z1 + 0.07, WHITE)
    ys = sorted((y, y + sgn * 0.05))
    box_mm(b, xc - w / 2, xc + w / 2, ys[0], ys[1], z0, z1, DARK)
    ys = sorted((y, y + sgn * 0.07))
    box_mm(b, xc - 0.04, xc + 0.04, ys[0], ys[1], z0, z1, WHITE)


def tt_booth(b):
    cx = (BOOTH_X0 + BOOTH_X1) * 0.5
    # B1 soclul
    box_mm(b, BOOTH_X0, BOOTH_X1, -1.0, 1.0, 0.0, 0.15, CONCRETE)
    w0, w1 = cx - 0.9, cx + 0.9
    # B2 peretii de jos rosii, B3 braul, B4 peretii de sus crem
    box_mm(b, w0, w1, -0.9, 0.9, 0.15, 1.05, RED)
    box_mm(b, w0 - 0.03, w1 + 0.03, -0.93, 0.93, 1.05, 1.15, WHITE)
    box_mm(b, w0, w1, -0.9, 0.9, 1.15, 2.15, CREAM)
    _win_x(b, w1, 1, 0.0, 1.2, 1.35, 2.0)
    _win_y(b, 0.9, 1, cx, 1.2, 1.35, 2.0)
    _win_y(b, -0.9, -1, cx, 1.2, 1.35, 2.0)
    # B5 usa pe -X: panou, geam sus, rama
    box_mm(b, w0 - 0.03, w0, 0.0, 0.84, 0.15, 2.05, WHITE)
    box_mm(b, w0 - 0.05, w0, 0.07, 0.77, 0.15, 1.98, LOG_DARK)
    box_mm(b, w0 - 0.07, w0, 0.17, 0.67, 1.35, 1.88, DARK)
    _win_x(b, w0, -1, -0.45, 0.55, 1.35, 2.0)
    # B6 stalpii de colt
    for sx in (w0, w1):
        for sy in (-0.9, 0.9):
            box_mm(b, sx - 0.06, sx + 0.06, sy - 0.06, sy + 0.06, 0.15, 2.15, WHITE)
    # B7 cornisa
    box_mm(b, cx - 0.98, cx + 0.98, -0.98, 0.98, 2.15, 2.25, WHITE)
    # B8 acoperisul in patru ape: streasina + piramida joasa (varful la 2,60)
    box_mm(b, BOOTH_X0, BOOTH_X1, -1.0, 1.0, 2.25, 2.32, RED)
    hull(b, [(BOOTH_X0, -1.0, 2.32), (BOOTH_X1, -1.0, 2.32), (BOOTH_X1, 1.0, 2.32),
             (BOOTH_X0, 1.0, 2.32), (cx, 0.0, 2.60)], RED)


def build_turntable():
    ao = dict(samples=24, dist=1.2, gradient="vertical", low=0.70, high=1.0, power=0.7, floor=0.40)
    deck = make("Turntable_Deck", tt_deck, dict(ao, low=0.85, dist=0.6, z_range=(0.0, 2.6)))
    booth = make("Turntable_Booth", tt_booth, dict(ao, z_range=(0.0, 2.6)))
    return [deck, booth]


# ============================================================ H6: magazia de chei
SH_W2 = 6.0                 # jumatatea latimii (12 m)
SH_EAVE = 5.4
SH_CROWN = 8.8              # cheia frontonului; acoperisul (0,2) o duce la +9,0
SH_ROOF_T = 0.20
# frontonul "arcuit" al decuparii: mansarda rotunjita, patru frante pe fiecare parte
SH_TOP = [(6.0, 5.4), (5.0, 7.0), (3.4, 8.15), (1.6, 8.66), (0.0, 8.8)]
SH_TOP = SH_TOP + [(-x, z) for x, z in reversed(SH_TOP[:-1])]       # de la +6 la -6
PILE_R = 0.25
PILE_BOT = -6.0
DECK_M = 1.0                # puntea iese 1 m pe laturi si in spate
DECK_FRONT = 2.5            # si 2,5 m in fata (platforma din decupare)
SH_WALL = SAND_MID          # 1: lemn de brad deschis (decuparea)
SH_BATTEN = WOOD            # 9: sipcile, mai inchise
SH_ROOF = ASPHALT_EDGE      # 6: tabla gri-inchis (decuparea)


def _gable_z(x):
    ax = abs(x)
    pts = SH_TOP[:5][::-1]                      # x crescator: 0 .. 6
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        if x0 <= ax <= x1:
            return z0 + (z1 - z0) * (ax - x0) / (x1 - x0)
    return SH_EAVE


def _offset(poly, d):
    """Polilinia (x, z), parcursa de la +x la -x pe sus, deplasata cu d pe normala
    exterioara, cu imbinari in unghi (miter)."""
    out = []
    n = len(poly)
    for i in range(n):
        segs = []
        if i > 0:
            segs.append((poly[i - 1], poly[i]))
        if i < n - 1:
            segs.append((poly[i], poly[i + 1]))
        nx = nz = 0.0
        for (xa, za), (xb, zb) in segs:
            tx, tz = xb - xa, zb - za
            ln = math.hypot(tx, tz)
            nx += tz / ln
            nz += -tx / ln
        ln = math.hypot(nx, nz)
        nx, nz = nx / ln, nz / ln
        (xa, za), (xb, zb) = segs[0]
        tx, tz = xb - xa, zb - za
        ln2 = math.hypot(tx, tz)
        cosh = abs((tz / ln2) * nx + (-tx / ln2) * nz)
        k = d / max(cosh, 0.5)
        out.append((poly[i][0] + nx * k, poly[i][1] + nz * k))
    return out


def _extend(poly, e):
    """Prelungeste capetele poliliniei cu `e` metri pe directia segmentelor de capat."""
    (x0, z0), (x1, z1) = poly[0], poly[1]
    ln = math.hypot(x0 - x1, z0 - z1)
    a = (x0 + (x0 - x1) / ln * e, z0 + (z0 - z1) / ln * e)
    (x0, z0), (x1, z1) = poly[-1], poly[-2]
    ln = math.hypot(x0 - x1, z0 - z1)
    c = (x0 + (x0 - x1) / ln * e, z0 + (z0 - z1) / ln * e)
    return [a] + poly[1:-1] + [c]


def shed_fn(L, n_side_win):
    hl = L * 0.5

    def fn(b):
        # S1 corpul: contur de fronton extrudat pe lungime
        outline = [(-SH_W2, 0.0), (SH_W2, 0.0)] + SH_TOP
        prism_xz(b, outline, -hl, hl, SH_WALL)
        # S3 acoperisul: coaja de 0,2 m peste fronton, streasina iesita 0,45 m
        inner = _extend(SH_TOP, 0.45)
        outer = _extend(_offset(SH_TOP, SH_ROOF_T), 0.45)
        prism_xz(b, outer + list(reversed(inner)), -hl - 0.45, hl + 0.45, SH_ROOF)
        # S4 bordajul alb pe conturul frontoanelor (fata si spate)
        bo = _offset(SH_TOP, 0.02)
        bi = _offset(SH_TOP, -0.30)
        for y0, y1 in ((hl, hl + 0.08), (-hl - 0.08, -hl)):
            prism_xz(b, bo + list(reversed(bi)), y0, y1, WHITE)
        # S4 scandurile de colt si braul de streasina
        for sx in (-1, 1):
            for sy in (-1, 1):
                box_mm(b, sx * SH_W2 - 0.11, sx * SH_W2 + 0.11, sy * hl - 0.11, sy * hl + 0.11,
                       0.0, SH_EAVE, WHITE)
            xs = sorted((sx * SH_W2, sx * (SH_W2 + 0.08)))
            box_mm(b, xs[0], xs[1], -hl, hl, SH_EAVE - 0.28, SH_EAVE, WHITE)
        # S8 plinta
        box_mm(b, -SH_W2 - 0.06, SH_W2 + 0.06, -hl - 0.06, hl + 0.06, 0.0, 0.35, LOG_DARK)
        # S5 usa glisanta pe fronton (+Y Blender = -Z Godot): doua canate cu scanduri verticale,
        # toc si buiandrug albi, sina de glisare care continua pe o parte
        y = hl
        box_mm(b, -2.8, 2.8, y, y + 0.10, 4.6, 4.85, WHITE)                     # buiandrug
        for sx in (-1, 1):
            xs = sorted((sx * 2.6, sx * 2.85))
            box_mm(b, xs[0], xs[1], y, y + 0.10, 0.0, 4.6, WHITE)                # tocul
            xa, xb = sorted((sx * 0.03, sx * 2.58))
            box_mm(b, xa, xb, y, y + 0.14, 0.05, 4.58, WOOD)                     # canatul
            for xv in (0.85, 1.7):
                box_mm(b, sx * xv - 0.05, sx * xv + 0.05, y + 0.14, y + 0.17, 0.10, 4.50, LOG_DARK)
        box_mm(b, -2.85, 5.6, y + 0.10, y + 0.28, 4.88, 5.06, DARK)               # sina de glisare
        # S6 fereastra din fronton (fata si spate)
        for sgn in (1, -1):
            _win_y(b, sgn * hl, sgn, 0.0, 1.6, 6.05, 7.05)
        # S7 ferestrele de pe laturi
        wys = [-6.0, -2.0, 2.0, 6.0] if n_side_win == 4 else [-2.5, 2.5]
        for sx in (-1, 1):
            for wy in wys:
                _win_x(b, sx * SH_W2, sx, wy, 1.3, 2.8, 3.7)
        # S2 sipcile verticale
        bt = 0.06

        def batten_y(face_y, sgn, x, z0, z1):
            if z1 - z0 > 0.2:
                ys = sorted((face_y, face_y + sgn * 0.05))
                box_mm(b, x - bt, x + bt, ys[0], ys[1], z0, z1, SH_BATTEN)

        for sgn in (1, -1):
            fy = sgn * hl
            for x in (-5.0, -4.0, -3.3, 3.3, 4.0, 5.0):
                batten_y(fy, sgn, x, 0.35, _gable_z(x) - 0.32)
            for x in (-2.0, -1.2, 1.2, 2.0):
                batten_y(fy, sgn, x, 5.06 if sgn > 0 else 0.35, _gable_z(x) - 0.32)
            batten_y(fy, sgn, 0.0, 5.06 if sgn > 0 else 0.35, 5.95)
            batten_y(fy, sgn, 0.0, 7.15, _gable_z(0.0) - 0.32)
        n_b = int(round((L - 1.2) / 1.0))
        for sx in (-1, 1):
            for k in range(n_b + 1):
                yy = -hl + 0.6 + k * (L - 1.2) / n_b
                if any(abs(yy - wy) < 0.85 for wy in wys):
                    continue
                xs = sorted((sx * SH_W2, sx * (SH_W2 + 0.05)))
                box_mm(b, xs[0], xs[1], yy - bt, yy + bt, 0.35, SH_EAVE - 0.28, SH_BATTEN)
        # S9 puntea + grinda de bordura (in fata, +Y Blender, platforma de 2,5 m)
        dx, y_front, y_back = SH_W2 + DECK_M, hl + DECK_FRONT, -hl - DECK_M
        box_mm(b, -dx, dx, y_back, y_front, -0.15, 0.0, WOOD)
        for sx in (-1, 1):
            xs = sorted((sx * (dx - 0.15), sx * (dx + 0.08)))
            box_mm(b, xs[0], xs[1], y_back - 0.08, y_front + 0.08, -0.50, -0.12, LOG_DARK)
        for yy, s in ((y_front, 1), (y_back, -1)):
            ys = sorted((yy - s * 0.15, yy + s * 0.08))
            box_mm(b, -dx, dx, ys[0], ys[1], -0.50, -0.12, LOG_DARK)
        # S10 pilonii pe perimetru (<= 3,7 m); cei de colt si doi din fata urca la +1,0
        px = dx - 0.25
        pf, pb = y_front - 0.25, y_back + 0.25
        piles = set()
        ny = max(2, int(math.ceil((pf - pb) / 3.7)))
        for k in range(ny + 1):
            yy = pb + (pf - pb) * k / ny
            for sx in (-1, 1):
                piles.add((round(sx * px, 3), round(yy, 3)))
        nx = max(2, int(math.ceil(2 * px / 3.7)))
        for k in range(nx + 1):
            xx = -px + 2 * px * k / nx
            for yy in (pf, pb):
                piles.add((round(xx, 3), round(yy, 3)))
        tall = {(round(sx * px, 3), round(yy, 3)) for sx in (-1, 1) for yy in (pf, pb)}
        front = sorted([p for p in piles if abs(p[1] - round(pf, 3)) < 1e-3 and abs(abs(p[0]) - px) > 0.1],
                       key=lambda p: abs(abs(p[0]) - 4.0))
        tall.update(front[:2])
        for (xx, yy) in sorted(piles):
            top = 1.0 if (xx, yy) in tall else -0.15
            b.cylinder((xx, yy, (PILE_BOT + top) * 0.5), PILE_R, top - PILE_BOT,
                       WOOD if top > 0 else LOG_DARK, segments=6)
            if top > 0:
                b.cylinder((xx, yy, top + 0.06), PILE_R + 0.04, 0.12, LOG_DARK, segments=6)
        # S11 clestele de la -2,2
        for sx in (-1, 1):
            xs = sorted((sx * (px + PILE_R), sx * (px + PILE_R + 0.22)))
            box_mm(b, xs[0], xs[1], pb, pf, -2.35, -2.05, LOG_DARK)
        for yy, s in ((pf, 1), (pb, -1)):
            ys = sorted((yy + s * PILE_R, yy + s * (PILE_R + 0.22)))
            box_mm(b, -px, px, ys[0], ys[1], -2.35, -2.05, LOG_DARK)
        print("    magazia %.0f m: %d piloni" % (L, len(piles)))
    return fn


def build_shed(L, name, n_win):
    o = make(name, shed_fn(L, n_win), dict(samples=20, dist=3.0, gradient="none", floor=0.30))

    def ramp(co):
        if co.z < 0.0:
            return 0.55 + 0.20 * (co.z - PILE_BOT) / -PILE_BOT
        return 0.80 + 0.20 * min(1.0, co.z / 9.0) ** 0.7
    ao_mul(o, ramp)
    return o


# ============================================================ F1: insula cu far
IS_EX, IS_EY = 30.0, 20.0
LH_X, LH_Y = 18.0, 1.0
RINGS = [0.0, 0.18, 0.34, 0.48, 0.60, 0.70, 0.78, 0.85, 0.90, 0.94, 0.975, 1.0]
IS_SEG = 40


def is_top(x, y):
    h = 2.6 + 7.4 * math.exp(-((x - 16.0) / 14.0) ** 2) + 3.0 * math.exp(-((x + 12.0) / 8.0) ** 2)
    h *= 1.0 - 0.10 * (y / IS_EY) ** 2
    return h


def is_ring_z(f, top, j):
    if f <= 0.72:
        return top
    table = {0.78: (0.86, 0.0), 0.85: (0.62, 0.0), 0.90: (0.34, 0.0), 0.94: (0.0, 0.7),
             0.975: (0.0, -0.9), 1.0: (0.0, -3.0)}
    s, a = table[f]
    return top * s + a + (j - 0.5) * (0.8 if 0.8 < f < 0.95 else 0.0)


def island_rock(b):
    rnd = _lcg(5150)
    rings = []
    for f in RINGS:
        if f == 0.0:
            rings.append([b.bm.verts.new((0.0, 0.0, is_top(0.0, 0.0)))])
            continue
        ring = []
        for k in range(IS_SEG):
            a = 2 * math.pi * k / IS_SEG
            rr = f * (1.0 + 0.07 * math.sin(3 * a + 0.7) + 0.05 * math.sin(5 * a + 2.0))
            if 0.0 < f < 1.0:
                rr *= 1.0 + (rnd() - 0.5) * 0.04
            x, y = rr * IS_EX * math.cos(a), rr * IS_EY * math.sin(a)
            z = is_ring_z(f, is_top(x, y), rnd())
            if 0.0 < f <= 0.72:
                z += (rnd() - 0.5) * 0.9
            ring.append(b.bm.verts.new((x, y, z)))
        rings.append(ring)
    faces = []
    for lo, hi in zip(rings, rings[1:]):
        for k in range(IS_SEG):
            j = (k + 1) % IS_SEG
            if len(lo) == 1:
                faces.append(b.bm.faces.new((lo[0], hi[k], hi[j])))
            else:
                faces.append(b.bm.faces.new((lo[k], lo[j], hi[j], hi[k])))
    faces.append(b.bm.faces.new(tuple(reversed(rings[-1]))))
    bmesh.ops.triangulate(b.bm, faces=[f for f in b.bm.faces if len(f.verts) > 4])
    bmesh.ops.recalc_face_normals(b.bm, faces=b.bm.faces[:])
    for f in b.bm.faces:
        c = f.calc_center_median()
        n = f.normal
        a = math.atan2(c.y / IS_EY, c.x / IS_EX)
        fr = math.hypot(c.x / IS_EX, c.y / IS_EY) / (1.0 + 0.07 * math.sin(3 * a + 0.7)
                                                      + 0.05 * math.sin(5 * a + 2.0))
        if c.z < 0.9 or fr > 0.80:
            s = DARK                                             # faleza (banda continua) si apa
        elif n.z > 0.86 and c.z > 3.0 and hash01(round(c.x / 9.0), round(c.y / 9.0), 7) < 0.40:
            s = GRASS
        else:
            s = STONE
        f[b.slot] = s
    # I4 bolovanii de la apa
    for k, (a_deg, sx, sy, sz, slot) in enumerate((
            (12, 6.0, 4.5, 4.0, STONE), (40, 4.2, 3.6, 3.0, DARK), (95, 5.0, 4.0, 3.4, STONE),
            (150, 3.6, 3.0, 2.6, DARK), (178, 4.8, 4.0, 3.2, STONE), (205, 3.4, 3.0, 2.4, STONE),
            (250, 5.4, 4.2, 3.6, DARK), (300, 4.0, 3.4, 2.8, STONE), (335, 5.6, 4.4, 4.2, STONE))):
        a = math.radians(a_deg)
        rr = 0.965 * (1.0 + 0.07 * math.sin(3 * a + 0.7) + 0.05 * math.sin(5 * a + 2.0))
        b.boulder((rr * IS_EX * math.cos(a), rr * IS_EY * math.sin(a), sz * 0.18), (sx, sy, sz), slot,
                  seed=300 + k * 11, segments=7, rings=3, deviation=0.14)


def island_light(b, zr):
    x, y = LH_X, LH_Y
    b.cylinder((x, y, zr - 0.1), 2.6, 1.4, CONCRETE, segments=12)                  # L1
    b.frustum((x, y, zr + 0.6 + 5.3), 1.6, 1.15, 10.6, WHITE, segments=12)         # L2
    b.cylinder((x, y, zr + 11.2 + 0.175), 1.75, 0.35, DARK, segments=12)            # L3
    annulus(b, 1.55, 1.75, zr + 11.55, zr + 12.25, DARK, seg=12, center=(x, y))
    b.cylinder((x, y, zr + 11.55 + 0.875), 0.95, 1.75, SAND_LIGHT, segments=12)     # L4
    b.frustum((x, y, zr + 13.3 + 0.6), 1.2, 0.2, 1.2, RED, segments=12)             # L5
    b.frustum((x, y, zr + 14.5 + 0.25), 0.22, 0.08, 0.5, DARK, segments=8)


def build_island():
    rock = make("Island_Rock", island_rock,
                dict(samples=16, dist=8.0, gradient="vertical", low=0.70, high=1.0, power=0.8,
                     floor=0.45), smooth=None)
    zr = max(v.co.z for v in rock.data.vertices
             if math.hypot(v.co.x - LH_X, v.co.y - LH_Y) < 3.0)
    light = make("Island_Light", lambda b: island_light(b, zr),
                 dict(samples=12, dist=2.0, gradient="vertical", low=0.85, high=1.0, power=0.8,
                      floor=0.5))
    ao_set_slots(light, (SAND_LIGHT,), 1.0)
    print("    farul: stanca sub el la +%.2f, varful la +%.2f (%.2f m peste stanca)"
          % (zr, zr + 15.0, 15.0))
    return [rock, light]


# ============================================================ F2: fundalul
HZ_CELL = 12.5
HZ_TOP = 56.0


def hill_field(L, W, humps, seed):
    def z(x, y):
        rho = math.sqrt((x / (L * 0.5)) ** 2 + (y / (W * 0.5)) ** 2)
        if rho >= 1.0:
            return 0.0
        s = 0.0
        for (hx, hy, H, sx, sy) in humps:
            s += (H * math.exp(-((x - hx) / sx) ** 2 - ((y - hy) / sy) ** 2)) ** 3
        h = s ** (1.0 / 3.0)
        h *= smoothstep(1.0, 0.68, rho)
        h *= 1.0 + 0.05 * math.sin(x * 0.045 + seed) * math.sin(y * 0.06 - seed)
        return max(0.0, h)
    return z


def _heightfield(b, L, W, zf, seed):
    nu = int(round(L / HZ_CELL))
    nv = int(round(W / HZ_CELL))
    cx, cy = L / nu, W / nv
    SQ = 0.16
    grid = {}
    for i in range(nu + 1):
        for j in range(nv + 1):
            u = -1.0 + 2.0 * i / nu
            v = -1.0 + 2.0 * j / nv
            border = i in (0, nu) or j in (0, nv)
            x = L * 0.5 * u * math.sqrt(max(0.0, 1.0 - v * v * SQ))
            y = W * 0.5 * v * math.sqrt(max(0.0, 1.0 - u * u * SQ))
            z = 0.6
            if not border:
                x += (hash01(i, j, seed) - 0.5) * 0.5 * cx
                y += (hash01(j, i, seed + 7) - 0.5) * 0.5 * cy
                z = max(0.6, zf(x, y))
            grid[(i, j)] = b.bm.verts.new((x, y, z))
    faces = []
    for i in range(nu):
        for j in range(nv):
            p00, p10, p11, p01 = grid[(i, j)], grid[(i + 1, j)], grid[(i + 1, j + 1)], grid[(i, j + 1)]
            if p00.co.z + p11.co.z >= p10.co.z + p01.co.z:
                faces += [b.bm.faces.new((p00, p10, p11)), b.bm.faces.new((p00, p11, p01))]
            else:
                faces += [b.bm.faces.new((p00, p10, p01)), b.bm.faces.new((p10, p11, p01))]
    loop = [grid[(i, 0)] for i in range(nu)] + [grid[(nu, j)] for j in range(nv)] \
        + [grid[(i, nv)] for i in range(nu, 0, -1)] + [grid[(0, j)] for j in range(nv, 0, -1)]
    bot = [b.bm.verts.new((v.co.x, v.co.y, 0.0)) for v in loop]
    n = len(loop)
    for k in range(n):
        faces.append(b.bm.faces.new((bot[k], bot[(k + 1) % n], loop[(k + 1) % n], loop[k])))
    c = b.bm.verts.new((0.0, 0.0, 0.0))
    for k in range(n):
        faces.append(b.bm.faces.new((bot[(k + 1) % n], bot[k], c)))
    return faces


def wind_tree(b, zf, x, y, h, lean_deg, seed):
    """Chiparos de Monterey aplecat de vant (decuparea `sf_horizon.png`, inventarul V1/§3.1):
    trunchi SCURT si gros, bifurcat, si o coroana DENSA din 5 pâlcuri suprapuse pe mai multe
    niveluri, impinse sub vant. NU disc plat pe trunchi subtire (silueta salcamului din
    Serengeti, pe care §3.1 o interzice)."""
    rnd = _lcg(seed)
    z0 = zf(x, y) - 1.0
    h = min(h, (HZ_TOP - z0) / 0.95)            # coroana nu trece de plafonul crestei
    dx, dy = math.cos(math.radians(lean_deg)), math.sin(math.radians(lean_deg))
    lx, ly = -dy, dx

    def at(off, lat, z):
        return (x + dx * off * h + lx * lat * h, y + dy * off * h + ly * lat * h, z0 + z * h)

    loft(b, [at(0, 0, 0), at(0.08, 0, 0.30), at(0.14, -0.06, 0.46)],
         [0.09 * h, 0.07 * h, 0.045 * h], LOG_DARK, side=(lx, ly, 0.0), segments=5)
    loft(b, [at(0.08, 0, 0.28), at(0.26, 0.07, 0.50)], [0.05 * h, 0.035 * h], LOG_DARK,
         side=(lx, ly, 0.0), segments=5)
    for (off, lat, z, rx, th) in ((0.10, -0.12, 0.52, 0.26, 0.20), (0.30, 0.10, 0.58, 0.30, 0.22),
                                  (0.48, -0.04, 0.64, 0.25, 0.19), (0.22, 0.00, 0.78, 0.24, 0.18),
                                  (0.02, 0.14, 0.68, 0.20, 0.17)):
        cx_, cy_, cz_ = at(off, lat, z)
        pts = []
        for i in range(7):
            a = 2 * math.pi * (i + rnd() * 0.3) / 7
            ca, sa = math.cos(a), math.sin(a)
            r = rx * h * (0.85 + 0.3 * rnd())
            px = cx_ + (ca * dx + sa * lx * 0.8) * r
            py = cy_ + (ca * dy + sa * ly * 0.8) * r
            pts.append((px, py, cz_ - th * h * 0.45))
            pts.append((cx_ + (px - cx_) * 0.65, cy_ + (py - cy_) * 0.65, cz_ + th * h * 0.55))
        hull(b, pts, TROPICAL_GREEN)


def shrub(b, zf, x, y, r, seed):
    rnd = _lcg(seed)
    z0 = zf(x, y) - 0.8
    pts = []
    for i in range(6):
        a = 2 * math.pi * (i + rnd() * 0.4) / 6
        pts.append((x + math.cos(a) * r, y + math.sin(a) * r * 0.8, z0))
        pts.append((x + math.cos(a + 0.5) * r * 0.6, y + math.sin(a + 0.5) * r * 0.5, z0 + r * (0.7 + 0.3 * rnd())))
    hull(b, pts, TROPICAL_GREEN)


def outcrop(b, zf, x, y, size, seed):
    rnd = _lcg(seed)
    for k in range(4):
        s = size * (1.0 - 0.18 * k) * (0.85 + 0.3 * rnd())
        ox = x + (rnd() - 0.5) * size * 1.1
        oy = y + (rnd() - 0.5) * size * 0.8
        z = zf(ox, oy)
        b.boulder((ox, oy, z + s * 0.12), (s, s * 0.8, s * 0.72), STONE, seed=seed + k * 13,
                  segments=6, rings=3, deviation=0.16)


def hill(name, L, W, humps, seed, outcrops, trees, shrubs):
    def fn(b):
        zf = hill_field(L, W, humps, seed)
        faces = _heightfield(b, L, W, zf, seed)
        hmax = max(h[2] for h in humps)
        bmesh.ops.recalc_face_normals(b.bm, faces=faces)
        for f in faces:
            c = f.calc_center_median()
            n = f.normal
            # D2: paiul uscat (13) pe tot, auriul deschis (0) doar pe crestele luminate, cu limita
            # urmand cota (o banda), nu petice la intamplare: petice pe fete de 12 m citeau camuflaj
            edge = 0.50 + 0.06 * math.sin(c.x * 0.03 + seed)
            lit = c.z > edge * hmax and n.z > 0.70
            f[b.slot] = SAND_LIGHT if lit else GRASS
        for (ax, ay, sz) in outcrops:
            outcrop(b, zf, ax * L * 0.5, ay * W * 0.5, sz * 1.6, seed + int(ax * 100) + 500)
        for k, (tx, ty, th, lean) in enumerate(trees):
            wind_tree(b, zf, tx * L * 0.5, ty * W * 0.5, th * 2.0, lean, seed + 40 + k)
        for k, (sx, sy, r) in enumerate(shrubs):
            shrub(b, zf, sx * L * 0.5, sy * W * 0.5, r, seed + 80 + k)
    return fn


def city(name, Wd, Dp, seed, n_towers, n_low):
    def fn(b):
        rnd = _lcg(seed)
        slots = (STEEL, STEEL, CONCRETE, STONE)
        # C2 cladirile joase: doua randuri (fata, spate) pe toata latimea
        for row in (-1, 1):
            x = -Wd * 0.5
            while x < Wd * 0.5 - 12.0:
                w = 18.0 + 16.0 * rnd()
                d = 14.0 + 10.0 * rnd()
                h = 8.0 + 9.0 * rnd()
                y = row * (Dp * 0.5 - d * 0.5 - 2.0 * rnd())
                box_mm(b, x, min(x + w, Wd * 0.5), y - d * 0.5, y + d * 0.5, 0.0, h,
                       CONCRETE if rnd() < 0.55 else STONE)
                x += w + 6.0 + 10.0 * rnd()
        # C1 turnurile: anvelopa de clopot (mai inalte spre mijloc), plat sus
        for k in range(n_towers):
            u = -0.88 + 1.76 * (k + 0.2 + 0.6 * rnd()) / n_towers
            xc = u * Wd * 0.5
            yc = (rnd() - 0.5) * Dp * 0.45
            env = 0.55 + 0.45 * math.exp(-(u / 0.45) ** 2)
            h = max(40.0, min(76.0, 80.0 * env * (0.82 + 0.18 * rnd())))   # + volumul tehnic <= 80
            w = 9.0 + 8.0 * rnd()
            d = 9.0 + 7.0 * rnd()
            slot = slots[int(rnd() * len(slots)) % len(slots)]
            tiers = 1 if rnd() < 0.55 else (2 if rnd() < 0.75 else 3)
            z = 0.0
            fr = [1.0] if tiers == 1 else ([0.68, 0.32] if tiers == 2 else [0.55, 0.28, 0.17])
            for t in range(tiers):
                k_ = 1.0 - 0.14 * t
                top = h if t == tiers - 1 else z + h * fr[t]
                box_mm(b, xc - w * k_ / 2, xc + w * k_ / 2, yc - d * k_ / 2, yc + d * k_ / 2,
                       z, top, slot)
                z = top
            if rnd() < 0.5:                                     # C3 volum tehnic pe acoperis
                kk = 1.0 - 0.14 * (tiers - 1)
                box_mm(b, xc - w * kk * 0.2, xc + w * kk * 0.2, yc - d * kk * 0.2, yc + d * kk * 0.2,
                       h, h + 3.5, CONCRETE)
    return fn


HZ_AO = dict(samples=10, dist=20.0, gradient="vertical", low=0.78, high=1.0, power=0.9, floor=0.55,
             strength=0.8)
CITY_AO = dict(samples=10, dist=14.0, gradient="vertical", low=0.70, high=1.0, power=0.9, floor=0.5,
               strength=0.7)


def build_horizon():
    pieces = [
        ("Hill_A", hill("Hill_A", 260.0, 110.0,
                        [(-62, 6, 45, 62, 42), (18, -8, 38, 52, 40), (84, 10, 30, 44, 38)], 3101,
                        outcrops=[(-0.62, -0.62, 15.0), (0.30, 0.72, 13.0), (0.78, -0.40, 12.0)],
                        trees=[(-0.20, -0.30, 15.0, 15.0), (0.48, 0.10, 13.0, 25.0)],
                        shrubs=[(-0.45, 0.30, 5.0), (0.10, -0.50, 4.5), (0.70, 0.25, 4.0)]), HZ_AO, 50.0),
        ("Hill_B", hill("Hill_B", 220.0, 96.0,
                        [(-46, -4, 34, 50, 36), (52, 6, 30, 46, 34)], 3202,
                        outcrops=[(-0.70, 0.50, 13.0), (0.15, -0.70, 14.0)],
                        trees=[(-0.40, 0.05, 14.0, 10.0), (0.40, -0.15, 12.0, 20.0),
                               (0.0, 0.40, 10.0, 15.0)],
                        shrubs=[(-0.15, -0.35, 4.5), (0.62, 0.40, 4.0)]), HZ_AO, 50.0),
        ("Hill_C", hill("Hill_C", 300.0, 120.0,
                        [(-30, 4, 55, 70, 46), (70, -10, 40, 56, 40), (-104, 8, 26, 40, 36)], 3303,
                        outcrops=[(-0.55, 0.65, 16.0), (0.55, 0.62, 14.0), (0.10, -0.70, 15.0)],
                        trees=[(0.30, -0.20, 15.0, 18.0), (-0.70, -0.25, 12.0, 12.0)],
                        shrubs=[(-0.30, -0.45, 5.0), (0.62, 0.05, 4.5), (-0.05, 0.42, 4.0)]), HZ_AO, 50.0),
        ("City_A", city("City_A", 230.0, 60.0, 4101, 20, 0), CITY_AO, None),
        ("City_B", city("City_B", 180.0, 52.0, 4202, 15, 0), CITY_AO, None),
    ]
    out = []
    for name, fn, ao, smooth in pieces:
        b = Builder()
        fn(b)
        o = b.to_object(name)
        set_origin_base(o, center_xy=True)
        apply_smooth(o, smooth)
        uv_from_slots(o)
        o.data.materials.clear()
        o.data.materials.append(atlas_material())
        zs = [v.co.z for v in o.data.vertices]
        bake_ao(o, **dict(ao, z_range=(0.0, max(zs))))
        out.append(o)
    return out


# ============================================================ N1: scara publica
ST_D, ST_H = 5.0, 3.0
ST_L0 = 0.15
ST_N = 16
ST_RISE = ST_H / ST_N
ST_TREAD = (ST_D - 1.2) / (ST_N - 1)
ST_IN, ST_OUT = 1.0, 1.25


def stair_fn(b):
    # N1 + N2: profilul (y, z) cu paliere si trepte, extrudat pe latimea libera
    pts = [(0.0, 0.0), (0.0, ST_L0)]
    y, z = -0.6, ST_L0
    for k in range(ST_N):
        pts.append((y, z))
        z += ST_RISE
        pts.append((y, z))
        y -= ST_TREAD
    pts += [(-ST_D, ST_L0 + ST_H), (-ST_D, 0.0)]
    faces = prism_yz(b, pts, -ST_IN, ST_IN, CONCRETE)
    for f in faces:
        f.normal_update()
        if abs(f.normal.y) > 0.9 and f.calc_center_median().z > 0.05 and f.calc_center_median().y < -0.01:
            f[b.slot] = STONE                                    # contratreptele
    # N3-N5: pe fiecare latura, soclu plin + banda de balustrada umbrita + stalpi + mana curenta,
    # intre doua pile patrate (jos si sus). Soclul are 0,25 m: zidul cerut >= 0,20.
    n0, n1 = ST_L0, ST_L0 + ST_H
    ya, yb = -0.6, -(ST_D - 0.6)
    for s in (-1, 1):
        xs = sorted((s * ST_IN, s * ST_OUT))
        prism_yz(b, [(ya, 0.0), (ya, n0 + 0.30), (yb, n1 + 0.30), (yb, 0.0)], xs[0], xs[1], CONCRETE)
        xi = sorted((s * (ST_IN + 0.05), s * (ST_OUT - 0.05)))
        prism_yz(b, [(ya, n0 + 0.29), (ya, n0 + 0.86), (yb, n1 + 0.86), (yb, n1 + 0.29)], xi[0], xi[1],
                 STONE)
        xc = s * (ST_IN + ST_OUT) * 0.5
        b.beam((xc, ya, n0 + 0.91), (xc, yb, n1 + 0.91), (0.25, 0.12), WHITE)
        for t in (0.25, 0.5, 0.75):
            yy = ya + (yb - ya) * t
            zz = n0 + (n1 - n0) * t
            box_mm(b, xs[0], xs[1], yy - 0.09, yy + 0.09, zz + 0.25, zz + 0.88, WHITE)
        xp = sorted((s * 0.92, s * ST_OUT))
        box_mm(b, xp[0], xp[1], -0.6, 0.0, 0.0, n0 + 1.25, WHITE)
        box_mm(b, xp[0], xp[1], -ST_D, yb, 0.0, n1 + 1.25, WHITE)


def build_stair():
    return make("StairLane", stair_fn, dict(samples=24, dist=1.2, gradient="vertical", low=0.80,
                                            high=1.0, power=0.8, floor=0.50, strength=0.6))


# ============================================================ T1: leii de mare pe pluta
RAFT_TOP = 0.30
BODY = SAND_SHADOW          # 2
FLIP = ROCK_DARK            # 4

# trasee locale (x inainte, z sus, puntea la z 0): (x, z, r_inaltime, r_latime) sau r 0 = varf
POSES = {
    "lying": dict(
        spine=[(-0.88, 0.05, 0, 0), (-0.72, 0.09, 0.08, 0.14), (-0.48, 0.15, 0.15, 0.27),
               (-0.18, 0.23, 0.23, 0.37), (0.12, 0.25, 0.25, 0.37), (0.38, 0.22, 0.21, 0.29),
               (0.55, 0.19, 0.165, 0.19), (0.67, 0.18, 0.165, 0.18), (0.80, 0.15, 0.11, 0.11),
               (0.89, 0.12, 0.065, 0.07), (0.94, 0.11, 0, 0)],
        front=[(0.22, 0.26, 0.10), (0.38, 0.48, 0.03), (0.52, 0.58, 0.03)],
        eye=(0.78, 0.09, 0.20), nose=(0.93, 0.11), ear=(0.66, 0.16, 0.23)),
    "rearing": dict(
        spine=[(-0.90, 0.05, 0, 0), (-0.74, 0.11, 0.10, 0.15), (-0.50, 0.20, 0.19, 0.29),
               (-0.22, 0.30, 0.27, 0.37), (0.02, 0.46, 0.30, 0.37), (0.14, 0.68, 0.27, 0.31),
               (0.20, 0.88, 0.21, 0.23), (0.23, 1.03, 0.18, 0.19), (0.27, 1.14, 0.19, 0.20),
               (0.37, 1.20, 0.14, 0.14), (0.47, 1.22, 0.085, 0.09), (0.54, 1.22, 0, 0)],
        front=[(0.10, 0.25, 0.42), (0.24, 0.40, 0.18), (0.36, 0.46, 0.03)],
        eye=(0.37, 0.11, 1.25), nose=(0.53, 1.22), ear=(0.25, 0.18, 1.22)),
    "half": dict(
        spine=[(-0.88, 0.05, 0, 0), (-0.72, 0.09, 0.08, 0.14), (-0.48, 0.15, 0.15, 0.27),
               (-0.18, 0.24, 0.24, 0.37), (0.08, 0.34, 0.27, 0.36), (0.24, 0.52, 0.23, 0.28),
               (0.32, 0.68, 0.18, 0.20), (0.37, 0.80, 0.18, 0.19), (0.48, 0.85, 0.12, 0.12),
               (0.58, 0.87, 0.07, 0.075), (0.64, 0.87, 0, 0)],
        front=[(0.16, 0.25, 0.30), (0.28, 0.42, 0.12), (0.40, 0.50, 0.03)],
        eye=(0.48, 0.10, 0.90), nose=(0.63, 0.87), ear=(0.36, 0.17, 0.86)),
}


def sea_lion(b, pose, pos, yaw_deg, scale, body_slot, flip_slot):
    p = POSES[pose]
    made = set()
    path = [(x, 0.0, z) for x, z, _a, _b in p["spine"]]
    radii = [(a, c) if a > 0 else 0 for _x, _z, a, c in p["spine"]]
    made |= loft(b, path, radii, body_slot, side=(0, 1, 0), segments=10)
    for s in (-1, 1):
        # inotatoarele din fata: MARI, late, proptite pe scanduri
        fp = [(x, s * y, z) for x, y, z in p["front"]]
        made |= b.blade(fp, [0.24, 0.32, 0.28], 0.09, flip_slot, up=(0.35, 0.0, 1.0))
        # cele din spate, rasfirate inapoi pe punte
        rp = [(-0.74, s * 0.06, 0.07), (-0.92, s * 0.20, 0.03), (-1.04, s * 0.30, 0.03)]
        made |= b.blade(rp, [0.12, 0.20, 0.22], 0.06, flip_slot, up=(0.0, 0.0, 1.0))
        # ochii si urechile: umflaturi mici, pe jumatate ingropate in cap
        ex, ey, ez = p["eye"]
        made |= b.box((ex, s * (ey - 0.02), ez), (0.06, 0.06, 0.06), DARK)
        ax, ay, az = p["ear"]
        made |= b.box((ax, s * ay, az), (0.07, 0.06, 0.08), flip_slot)
    nx, nz = p["nose"]
    made |= b.box((nx - 0.02, 0.0, nz), (0.07, 0.08, 0.07), DARK)
    mat = (Matrix.Translation(Vector((pos[0], pos[1], RAFT_TOP))) @
           Matrix.Rotation(math.radians(yaw_deg), 4, "Z") @ Matrix.Scale(scale, 4))
    move_verts(b, made, mat)


def lions_fn(b):
    # P1 scandurile (lungi pe X)
    for k in range(8):
        yc = -1.5 + 0.1875 + k * 0.375
        box_mm(b, -2.0, 2.0, yc - 0.17, yc + 0.17, 0.20, RAFT_TOP, WOOD if k == 5 else TILE_TERRACOTTA)
    # P2 grinzile transversale si plutitorii
    for x in (-1.7, 0.0, 1.7):
        box_mm(b, x - 0.12, x + 0.12, -1.45, 1.45, 0.04, 0.20, LOG_DARK)
    for y in (-0.85, 0.85):
        b.cylinder((0.0, y, -0.04), 0.29, 3.8, LOG_DARK, segments=8, axis="X")
    # P3 coltarele si stalpul de amarare
    for sx in (-1, 1):
        for sy in (-1, 1):
            box_mm(b, sx * 2.0 - 0.07, sx * 2.0 + 0.07, sy * 1.5 - 0.07, sy * 1.5 + 0.07, 0.08, 0.34,
                   RUST)
    b.cylinder((-1.84, 1.32, RAFT_TOP + 0.17), 0.10, 0.34, LOG_DARK, segments=8)
    # L1-L4
    sea_lion(b, "rearing", (-0.80, -0.60), 10.0, 1.0, BODY, FLIP)
    sea_lion(b, "lying", (0.45, 0.80), 0.0, 1.0, FLIP, DARK)
    sea_lion(b, "half", (1.00, -0.60), 200.0, 1.0, BODY, FLIP)
    sea_lion(b, "lying", (-1.30, 0.55), -25.0, 0.70, BODY, FLIP)


def build_lions():
    return make("SeaLions", lions_fn, dict(samples=24, dist=0.8, gradient="vertical", low=0.60,
                                           high=1.0, power=0.8, floor=0.35), smooth=50.0)


# ============================================================ main
def main():
    only = None
    for a in sys.argv:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))

    def want(k):
        return only is None or k in only

    clear_built()
    if want("turntable"):
        export(build_turntable(), "sanfrancisco/structures/sf_turntable.glb", "sf_turntable.blend")
    if want("shed"):
        export([build_shed(20.0, "PierShed", 4)], "sanfrancisco/structures/sf_pier_shed.glb",
               "sf_pier_shed.blend")
        export([build_shed(12.0, "PierShed_Short", 2)], "sanfrancisco/structures/sf_pier_shed_short.glb",
               "sf_pier_shed_short.blend")
    if want("island"):
        export(build_island(), "sanfrancisco/structures/sf_island_light.glb", "sf_island_light.blend")
    if want("horizon"):
        objs = build_horizon()
        export(objs, "sanfrancisco/structures/sf_horizon.glb")
        for i, o in enumerate(objs):
            o.location.x = i * 320.0
        print("blend:", save_blend(objs, "sf_horizon.blend"))
    if want("stair"):
        export([build_stair()], "sanfrancisco/props/sf_stair_lane.glb", "sf_stair_lane.blend")
    if want("lions"):
        export([build_lions()], "sanfrancisco/animals/sf_sea_lions.glb", "sf_sea_lions.blend")


main()
