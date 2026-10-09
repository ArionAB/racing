"""Okinawa v2 -- castelul (brief docs/asset_briefs/okinawa_kit_v2.md §1.1).

  okinawa/structures/ryukyu_gate.glb   poarta de tip Shureimon, peste drum  (PILOT)

(palatul si zidurile gusuku vin in valul 1, in acelasi fisier)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_okinawa_castle.py

Fara text, cifre sau logo-uri (regula 9). Fata = +Y in Blender (= -Z in Godot).
Originea: centrul amprentei pe XY, baza pe Z=0 (`--origin=assembly`).
Variabila de mediu OK_ONLY=<piesa> reface doar piesa respectiva.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "okinawa_shapes.py")).read())

clear_built()

AO_GATE = dict(samples=16, dist=2.2, gradient="vertical", low=0.62, high=1.0,
               power=0.8, floor=0.32, z_range=(0.0, 11.4))


def build_ryukyu_gate():
    """Poarta Shureimon (`ryukyu_gate`), peste drum.

    LISTA DE ELEMENTE (scrisa din decuparea `okinawa_assets_v1/ryukyu_gate.png`
    si din contractul §1.1, INAINTE de primul vertex). Cotele sunt contract;
    numerele vin din decupare unde contractul tace.

    Pe decupare (3/4 din fata, drumul trece prin mijloc):
      a) 8 stalpi rosii: 4 pe fiecare parte, in doua randuri (fata/spate) de
         cate doi (interior + exterior), deci pe decupare par grupati "doi cate
         doi"; fiecare pereche pe un soclu de piatra comun  -> 4 socluri
      b) ACOPERIS CENTRAL (treapta de sus): un singur acoperis in patru ape,
         coama lunga, streasina curbata in sus la colturi; coame de colt albe
         si coama principala alba; olane rosii
      c) ACOPERISURI LATERALE (treapta de jos): cate unul pe fiecare parte,
         peste grupul de stalpi, in patru ape, cu coama pe Y; aceleasi coame albe
      d) grinda rosie transversala peste drum (buiandrugul), apoi PANOU
         orizontal (rosu, in rama, GOL, FARA TEXT) intre buiandrug si streasina
         de sus; sub streasina, console in trepte la capul fiecarui stalp
      e) ornamente aurii: 2 pe coama de sus (la capete) -- contractul; pe
         decupare mai sunt cate unul pe fiecare coama laterala (2, mai mici) si
         un medalion pe panou (cate unul pe fata, 2)
      f) socluri de piatra (calcar) la baza stalpilor, 4 buc, talpa evazata
      g) NU intra: asfaltul din decupare, tufele de la soclu (regula
         "fara vegetatie lipita")

    Corecturi de contract fata de decupare: golul liber peste drum (stalpii
    din decupare par la +-4,5 m, dar contractul cere +-7,0 m): stalpii interiori
    stau la x = +-7,85, soclurile incep la |x| = 7,2; buiandrugul, panoul si
    acoperisul de sus sunt SINGURELE elemente peste gol, toate >= 6,2 m.

    Cote tinta: ~20,4 m lat (X), ~11,2 m inalt, ~5,2 m adanc (Y); h/l ~0,55.
    Noduri: Gate_Lacquer (KERB_RED 7), Gate_Roof (TILE_TERRACOTTA 23),
    Gate_Mortar (FOAM_WHITE 22), Gate_Limestone (MARBLE_GREY 29),
    Gate_Gold (CAR_YELLOW 16).
    """
    lac, roofb, mort, lime, gold = Builder(), Builder(), Builder(), Builder(), Builder()

    ROW = 1.55            # randurile de stalpi pe Y: +-1,55
    X_IN, X_OUT = 7.85, 9.05
    R_PIL = 0.5
    PLINTH_H = 1.3
    LINTEL_Z0, LINTEL_Z1 = 6.2, 6.9

    # --- treapta de sus: acoperisul central --------------------------------
    up = HipRoof(0.0, 0.0, hu=9.3, hv=2.6, z0=7.6, rise=2.3, swap=False,
                 lift=0.75, th=0.18)
    up.build(roofb, mort)
    # --- treapta de jos: acoperisurile laterale -----------------------------
    sides = []
    for sx in (-1, 1):
        sd = HipRoof(sx * 8.85, 0.0, hu=2.6, hv=1.4, z0=4.0, rise=1.7, swap=True,
                     lift=0.8, th=0.15)
        sd.build(roofb, mort)
        sides.append(sd)

    # --- socluri de calcar + stalpi ----------------------------------------
    for sx in (-1, 1):
        sd = sides[0 if sx < 0 else 1]
        for sy in (-1, 1):
            stone_plinth(lime, sx * 8.55, sy * ROW, 1.35, 0.85, PLINTH_H)
            for xp, roof, top_cap in ((X_IN, up, True), (X_OUT, sd, False)):
                x, y = sx * xp, sy * ROW
                # stalpul urca pana sub consolele care sustin placa acoperisului
                z_roof = roof.z(x, y) - roof.th
                z_top = z_roof - 0.18 * 3 - 0.12
                lacquer_pillar(lac, x, y, PLINTH_H, z_top, R_PIL)
                bracket(lac, x, y, z_top, 0.8 if top_cap else 0.6)

    # --- buiandrugul si grinzile ----------------------------------------------
    for sy in (-1, 1):
        # buiandrug peste drum, doar intre stalpii interiori (golul >= 6,2 m)
        lac.box((0.0, sy * ROW, (LINTEL_Z0 + LINTEL_Z1) * 0.5),
                (2 * X_IN + 0.9, 0.55, LINTEL_Z1 - LINTEL_Z0), OK_LACQUER)
        for sx in (-1, 1):
            # grinda interior-exterior, doar in afara golului
            lac.box((sx * (X_IN + X_OUT) * 0.5, sy * ROW, 3.3),
                    (X_OUT - X_IN + 0.9, 0.42, 0.45), OK_LACQUER)
    for sx in (-1, 1):
        for xp in (X_IN, X_OUT):
            # grinda pe adancime, intre randul din fata si cel din spate
            zb = 6.55 if xp == X_IN else 3.3
            lac.box((sx * xp, 0.0, zb), (0.42, 2 * ROW + 0.5, 0.45 if xp == X_OUT else 0.7),
                    OK_LACQUER)

    # --- panoul gol sub acoperisul de sus ------------------------------------
    PZ0, PZ1 = 6.9, 8.0
    lac.box((0.0, 0.0, 7.45), (2 * X_IN - 0.5, 0.20, PZ1 - PZ0), OK_LACQUER)
    lac.box((0.0, 0.0, PZ1 + 0.12), (2 * X_IN + 0.9, 0.42, 0.24), OK_LACQUER)
    for sy in (-1, 1):
        # rama proeminenta in jurul panoului
        lac.box((0.0, sy * 0.14, PZ1 - 0.06), (2 * X_IN - 0.6, 0.10, 0.14), OK_LACQUER)
        lac.box((0.0, sy * 0.14, PZ0 + 0.06), (2 * X_IN - 0.6, 0.10, 0.14), OK_LACQUER)
        for sx in (-1, 1):
            lac.box((sx * (X_IN - 0.4), sy * 0.14, 7.45), (0.14, 0.10, PZ1 - PZ0), OK_LACQUER)
        # medalion auriu in centrul panoului (cate unul pe fata)
        gold.frustum((0.0, sy * 0.21, 7.45), 0.5, 0.5, 0.10, OK_GOLD, segments=12, axis="Y")
        gold.frustum((0.0, sy * 0.26, 7.45), 0.26, 0.26, 0.10, OK_GOLD, segments=12, axis="Y")

    # --- ornamente aurii pe coame ---------------------------------------------
    for sx in (-1, 1):
        gold_finial(gold, sx * up.R, 0.0, up.ridge_z + 0.12, 1.4)
        sd = sides[0 if sx < 0 else 1]
        for sy in (-1, 1):
            gold_finial(gold, sd.cx, sy * sd.R, sd.ridge_z + 0.10, 0.9)

    objs = [to_obj(lac, "Gate_Lacquer"), to_obj(roofb, "Gate_Roof"),
            to_obj(mort, "Gate_Mortar"), to_obj(lime, "Gate_Limestone"),
            to_obj(gold, "Gate_Gold")]
    return objs


ONLY = os.environ.get("OK_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


if _want("ryukyu_gate"):
    objs = build_ryukyu_gate()
    # fetele din build sunt construite cu infasurare proprie (grila acoperisului,
    # loft): normalele se recalculeaza pe nod, ca la Builder.to_object
    for o in objs:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bm.to_mesh(o.data)
        bm.free()
    emit_ok(objs, "structures/ryukyu_gate.glb", AO_GATE, keep_xy=False, bevel=0.0,
            smooth_angle=48.0, budget=None)

report_ok()
