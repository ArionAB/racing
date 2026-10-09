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
               power=0.8, floor=0.32, z_range=(0.0, 14.5))


def build_ryukyu_gate():
    """Poarta Shureimon (`ryukyu_gate`), peste drum. Revizia 4 (ierarhie din decupare).

    LISTA DE ELEMENTE (din decuparea `okinawa_assets_v1/ryukyu_gate.png` si din
    contractul §1.1; scrisa INAINTE de geometrie, rev. 4 o corecteaza dupa
    verdictul coordonatorului):
      a) 8 stalpi rosii: 4 pe fiecare parte, doua randuri (fata/spate) de cate doi
         (interior + exterior), pe 4 socluri de calcar (cate unul pe pereche)
      b) ACOPERIS CENTRAL (etajul de sus): bloc INALT si relativ scurt (~70% din
         latime), streasina la ~9,6 m, coama la ~13 m, panta abrupta, coama scurta,
         streasini curbate vizibil in sus la colturi
      c) ACOPERISURI LATERALE (etajul 2): cate unul pe parte, MARI (~6,2 m lat,
         ~5,6 m adanc), streasina la ~7 m, se suprapun sub streasina celui central;
         trec spre interior peste |x| < 7,2 DOAR deasupra cotei ~6,85 m (golul cere
         liber pana la 6,0 m)
      d) olane: canale dese de nervuri in relief IN CULOAREA OLANELOR (perpendiculare
         pe streasina, ~0,4 m); ALBUL doar pe coama, pe muchiile de colt (hip) si pe
         bordura streasinii (Gate_Mortar)
      e) DOUA grinzi orizontale rosii peste drum (jos la 6,2 m = contractul, sus la
         ~8,1 m) cu PANOU intre ele: rama rosie, fond auriu (Gate_Gold), GOL, FARA
         TEXT; vizibil din 3/4 fata (streasina centrala e inalta)
      f) console in trepte AURII sub streasinile fiecarui stalp
      g) ornamente aurii: 2 pe coama de sus (contractul) + cate unul mai mic pe
         fiecare coama laterala (2), ca pe decupare
      h) NU intra: asfaltul, tufele de la soclu (fara vegetatie lipita)

    Golul: stalpii interiori la x = +-7,85 (r 0,5), soclurile incep la |x| = 7,2;
    peste gol exista doar grinzile (>= 6,2 m), panoul, acoperisul de sus si
    streasinile laterale (>= 6,85 m).

    Cote: ~23,5 m lat (X), ~14 m inalt, ~5,6 m adanc (Y); h/l ~0,6.
    Noduri: Gate_Lacquer (KERB_RED 7), Gate_Roof (TILE_TERRACOTTA 23),
    Gate_Mortar (FOAM_WHITE 22), Gate_Limestone (MARBLE_GREY 29),
    Gate_Gold (CAR_YELLOW 16).
    """
    lac, roofb, mort, lime, gold = Builder(), Builder(), Builder(), Builder(), Builder()

    ROW = 1.55            # randurile de stalpi pe Y: +-1,55
    X_IN, X_OUT = 7.85, 9.05
    R_PIL = 0.5
    PLINTH_H = 1.3
    B1_Z0, B1_Z1 = 6.2, 6.9        # grinda de jos (contract: >= 6,2 m)
    B2_Z0, B2_Z1 = 8.1, 8.8        # grinda de sus

    # --- etajul de sus: acoperisul central ----------------------------------
    up = HipRoof(0.0, 0.0, hu=8.6, hv=2.75, z0=9.7, rise=3.4, swap=False,
                 lift=1.0, th=0.2, curve=1.5, tile_step=0.2, tile_amp=0.09)
    up.R = up.hu - up.hv * 1.1
    up.build(roofb, mort, seams=False)
    # --- etajul 2: acoperisurile laterale (mari, la ~7 m) ---------------------
    sides = []
    for sx in (-1, 1):
        sd = HipRoof(sx * 8.6, 0.0, hu=3.1, hv=2.8, z0=7.0, rise=2.0, swap=False,
                     lift=0.8, th=0.16, curve=1.45, tile_step=0.2, tile_amp=0.09)
        sd.R = 0.0
        sd.build(roofb, mort, seams=False)
        sides.append(sd)

    # --- socluri de calcar + stalpi + console aurii --------------------------
    for sx in (-1, 1):
        sd = sides[0 if sx < 0 else 1]
        for sy in (-1, 1):
            stone_plinth(lime, sx * 8.55, sy * ROW, 1.35, 0.85, PLINTH_H)
            for xp, roof, top_cap in ((X_IN, up, True), (X_OUT, sd, False)):
                x, y = sx * xp, sy * ROW
                z_top = roof.z(x, y) - roof.th - 0.18 * 3 - 0.12
                lacquer_pillar(lac, x, y, PLINTH_H, z_top, R_PIL)
                bracket(gold, x, y, z_top, 0.8 if top_cap else 0.6, slot=OK_GOLD)
        # al doilea nivel de console sub streasina laterala, la stalpul interior
        # (stalpul interior trece prin acoperisul lateral)
        for sy in (-1, 1):
            z_s = sd.z(sx * X_IN, sy * ROW) - sd.th - 0.18 * 3 - 0.12
            bracket(gold, sx * X_IN, sy * ROW, z_s - 0.02, 0.8, slot=OK_GOLD)

    # --- grinzile si panoul ---------------------------------------------------
    for sy in (-1, 1):
        for (z0, z1) in ((B1_Z0, B1_Z1), (B2_Z0, B2_Z1)):
            lac.box((0.0, sy * ROW, (z0 + z1) * 0.5),
                    (2 * X_IN + 0.9, 0.55, z1 - z0), OK_LACQUER)
        for sx in (-1, 1):
            # grinda interior-exterior, doar in afara golului
            lac.box((sx * (X_IN + X_OUT) * 0.5, sy * ROW, 5.2),
                    (X_OUT - X_IN + 0.9, 0.42, 0.45), OK_LACQUER)
    for sx in (-1, 1):
        for xp, zb, hb in ((X_IN, 6.55, 0.7), (X_IN, 8.45, 0.7), (X_OUT, 5.2, 0.45)):
            lac.box((sx * xp, 0.0, zb), (0.42, 2 * ROW + 0.5, hb), OK_LACQUER)

    # panou: rama rosie, fond auriu, GOL, fara text (intre cele doua grinzi)
    PZ0, PZ1 = B1_Z1, B2_Z0
    PW = X_IN - 0.45
    for sy in (-1, 1):
        # plansa pe fiecare fata, in planul grinzilor (vizibila din 3/4)
        yp = sy * (ROW + 0.05)
        gold.box((0.0, yp, (PZ0 + PZ1) * 0.5), (2 * PW, 0.16, PZ1 - PZ0), OK_GOLD)
        lac.box((0.0, yp, PZ0 + 0.14), (2 * PW + 0.3, 0.34, 0.28), OK_LACQUER)
        lac.box((0.0, yp, PZ1 - 0.14), (2 * PW + 0.3, 0.34, 0.28), OK_LACQUER)
        for sx in (-1, 1):
            lac.box((sx * PW, yp, (PZ0 + PZ1) * 0.5), (0.28, 0.34, PZ1 - PZ0), OK_LACQUER)

    # --- ornamente aurii pe coame ---------------------------------------------
    for sx in (-1, 1):
        gold_finial(gold, sx * up.R, 0.0, up.ridge_z + 0.12, 1.4)
        sd = sides[0 if sx < 0 else 1]
        gold_finial(gold, sd.cx, 0.0, sd.ridge_z + 0.10, 0.9)

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
