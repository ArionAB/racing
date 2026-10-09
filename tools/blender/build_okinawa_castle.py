"""Okinawa v2 -- castelul (brief docs/asset_briefs/okinawa_kit_v2.md §1.1).

  okinawa/structures/ryukyu_gate.glb          poarta de tip Shureimon, peste drum  (PILOT)
  okinawa/buildings/ryukyu_palace.glb         palatul, pe platforma de calcar     (val 1, ok-a)
  okinawa/structures/gusuku_wall_curve.glb    modul de zid pe arc, R 20 si R 40   (val 1, ok-a)
  okinawa/structures/gusuku_wall_straight.glb modulul de zid drept                (val 1, ok-a)
  okinawa/structures/gusuku_arch_gate.glb     zid cu poarta boltita               (val 1, ok-a)

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



AO_PALACE = dict(samples=16, dist=2.6, gradient="vertical", low=0.60, high=1.0,
                 power=0.8, floor=0.30, z_range=(0.0, 16.5))
AO_WALL = dict(samples=16, dist=2.4, gradient="vertical", low=0.58, high=1.0,
               power=0.8, floor=0.30, z_range=(0.0, 8.5))


def _window(b_, cx_, cy_, nrm, w_, h_, z0_, along):
    """Fereastra: gol intunecat (LOG_DARK) cu rama si 3 montanti de lemn."""
    zc = z0_ + h_ * 0.5
    sz = (w_, 0.14, h_) if along == "x" else (0.14, w_, h_)
    b_.box((cx_, cy_, zc), sz, LOG_DARK)
    for fz in (z0_ + 0.05, z0_ + h_ - 0.05):
        sz2 = (w_ + 0.2, 0.2, 0.12) if along == "x" else (0.2, w_ + 0.2, 0.12)
        b_.box((cx_, cy_, fz), sz2, WOOD)
    for k in (-1, 0, 1):
        off = k * w_ * 0.28
        if along == "x":
            b_.box((cx_ + off, cy_ + nrm * 0.04, zc), (0.1, 0.2, h_), WOOD)
        else:
            b_.box((cx_ + nrm * 0.04, cy_ + off, zc), (0.2, 0.1, h_), WOOD)


def build_ryukyu_palace():
    """Palatul regal (`ryukyu_palace`), pe platforma de calcar cu scara pe +Y.

    LISTA DE ELEMENTE (din decuparea `okinawa_assets_v1/ryukyu_palace.png` si
    din contractul §1.1; scrisa INAINTE de geometrie):
      a) platforma de calcar: 32 x 15,4 m, 2,5 m inalta, 3 asize cu talus, colturi
         tesite, placa de capat; parapet jos pe trei laturi + fata (cu gol pentru scara)
      b) scara frontala pe +Y: 9 trepte, 6 m latime, 2 obraji laterali in panta
         (calcar), urca spre usa centrala
      c) etajul de jos (sala): pereti rosii 29,4 x 9,1 m, pana sub olane, cu usa
         centrala dubla (lemn), 4 ferestre pe fiecare parte a fatadei, usa de capat
         pe fiecare latura si ferestre pe laterale
      d) 12 coloane rosii pe fata (6 pe parte: golul central +-2,6 m, apoi din
         2,6 in 2,6 m, plus coloana de colt), pe socluri mici de calcar, cu console
         in trepte si grinda intre ele
      e) acoperisul de jos: in patru ape, MARE (31,2 x 12,8 m), streasina la 7,0 m,
         colturi ridicate, olane cu nervuri in relief, coama + muchii + bordura ALBE
      f) frontonul curbat (karahafu) peste intrarea centrala: 7,6 m latime, margine
         in S, panou rosu sub curba, bordura alba, ornament auriu pe varf
      g) etajul de sus: pereti rosii 17,6 x 7,2 m, 5 ferestre pe fata, 7 coloane
         pe fata si 2 de colt; sub acoperis pana la fata de jos a olanelor
      h) acoperisul de sus: patru ape, 22,8 x 11,2 m, streasina 11,3 m, coama
         la ~14,4 m (lunga: ~12,7 m), colturi ridicate
      i) 2 dragoni aurii (CAR_YELLOW) pe capetele coamei de sus, ~1,5 m inalti,
         cu capul spre exterior
      j) NU intra: tufele de pe platforma si de pe ziduri (decupare), cele doua
         pavilioane mici de la capete, copacii; nimic cu text

    Cote tinta: ~32 x ~18 m amprenta (scara inclusa), ~16 m inaltime totala
    (dragonii), h/l ~0,5. Noduri: Palace_Lacquer (KERB_RED 7), Palace_Roof
    (TILE_TERRACOTTA 23), Palace_Mortar (FOAM_WHITE 22), Palace_Limestone
    (MARBLE_GREY 29), Palace_Gold (CAR_YELLOW 16), Palace_Wood (WOOD 9 + LOG_DARK 28).
    Fata = +Y (scara).
    """
    lac, roofb, mort, lime, gold, wood = (Builder(), Builder(), Builder(),
                                          Builder(), Builder(), Builder())
    CY = -3.0
    PX, PY0, PY1, PH = 16.0, -9.6, 5.8, 2.5

    # --- a) platforma + parapet
    outline = chamfer([(-PX, PY0), (PX, PY0), (PX, PY1), (-PX, PY1)], 0.9)
    banded_prism(lime, outline, 0.0, PH, courses=3, batter=0.05)
    px, py_b, py_f = 15.15, -8.95, 5.05
    pz0, ph = PH, 0.8
    segs = [((-px, py_b), (px, py_b)), ((-px, py_b), (-px, py_f)),
            ((px, py_b), (px, py_f)), ((-px, py_f), (-3.85, py_f)),
            ((3.85, py_f), (px, py_f))]
    for (p0, p1) in segs:
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        L = math.hypot(dx, dy)
        cx_, cy_ = (p0[0] + p1[0]) * 0.5, (p0[1] + p1[1]) * 0.5
        sx_, sy_ = (L, 0.36) if abs(dx) > abs(dy) else (0.36, L)
        lime.box((cx_, cy_, pz0 + ph * 0.5), (sx_, sy_, ph), OK_LIMESTONE)
        sx2, sy2 = (L + 0.1, 0.5) if abs(dx) > abs(dy) else (0.5, L + 0.1)
        lime.box((cx_, cy_, pz0 + ph + 0.07), (sx2, sy2, 0.14), OK_LIMESTONE)
        n_p = max(1, int(round(L / 4.2)))
        for k in range(n_p + 1):
            t = k / n_p
            lime.box((p0[0] + dx * t, p0[1] + dy * t, pz0 + ph * 0.5 + 0.12),
                     (0.62, 0.62, ph + 0.24), OK_LIMESTONE)

    # --- b) scara frontala
    N_ST, RUN, RISE, SW = 9, 0.3, 0.25, 6.0
    for k in range(1, N_ST + 1):
        ya = PY1 - 0.15 if k == 1 else PY1 + RUN * (k - 1)
        yb = PY1 + RUN * k
        top = PH - RISE * k
        lime.box((0.0, (ya + yb) * 0.5, top * 0.5), (SW, yb - ya, top), OK_LIMESTONE)
    y_end = PY1 + RUN * N_ST
    for sx in (-1, 1):
        x0, x1 = sorted((sx * SW * 0.5, sx * (SW * 0.5 + 0.7)))
        prism_yz(lime, [(PY1 - 0.15, 0.0), (y_end + 0.2, 0.0), (y_end + 0.2, 0.62),
                        (PY1 - 0.15, 3.42)], x0, x1, OK_LIMESTONE)

    # --- acoperisurile
    low = HipRoof(0.0, CY, hu=15.6, hv=6.4, z0=6.3, rise=1.7, lift=0.8, th=0.2,
                  curve=1.4, tile_step=0.32, tile_amp=0.07)
    low.build(roofb, mort, seams=False)
    up = HipRoof(0.0, CY, hu=11.4, hv=5.6, z0=11.0, rise=3.4, lift=0.9, th=0.2,
                 curve=1.4, tile_step=0.32, tile_amp=0.07)
    up.R = 4.2
    up.build(roofb, mort, seams=False)

    # --- c) etajul de jos: pereti pana sub olane
    WX = 14.7
    Y_F, Y_R = 1.5, -7.6
    wall_to_roof(lac, low, "x", Y_F, -WX, WX, PH, 0.5)
    wall_to_roof(lac, low, "x", Y_R, -WX, WX, PH, 0.5)
    for sx in (-1, 1):
        wall_to_roof(lac, low, "y", sx * WX, Y_R, Y_F, PH, 0.5)
    yf = Y_F + 0.27
    wood.box((0.0, yf, PH + 1.65), (3.1, 0.14, 3.3), LOG_DARK)
    for sx in (-1, 1):
        wood.box((sx * 0.74, yf + 0.07, PH + 1.6), (1.36, 0.12, 3.15), WOOD)
        wood.box((sx * 0.74, yf + 0.14, PH + 2.5), (1.2, 0.08, 0.12), LOG_DARK)
        wood.box((sx * 0.74, yf + 0.14, PH + 0.9), (1.2, 0.08, 0.12), LOG_DARK)
    wood.box((0.0, yf + 0.04, PH + 3.42), (3.5, 0.22, 0.26), WOOD)
    for sx in (-1, 1):
        for xw in (3.9, 6.5, 9.1, 11.7):
            _window(wood, sx * xw, yf, 1.0, 1.9, 2.2, PH + 0.9, "x")
        wood.box((sx * 13.85, yf, PH + 1.5), (1.3, 0.14, 3.0), LOG_DARK)
        wood.box((sx * 13.85, yf + 0.07, PH + 1.45), (1.1, 0.12, 2.8), WOOD)
        for yw in (-1.8, -4.8):
            _window(wood, sx * (WX + 0.27), yw, sx, 1.8, 2.0, PH + 1.0, "y")

    # --- d) coloanele de pe fata
    COL_X = [2.6, 5.2, 7.8, 10.4, 13.0, 14.8]
    YC = 2.6
    for sx in (-1, 1):
        for xc in COL_X:
            x = sx * xc
            stone_plinth(lime, x, YC, 0.5, 0.5, 0.36, z0=PH, flare=0.08)
            z_top = low.z(x, YC) - low.th - 0.18 * 3 - 0.12
            lacquer_pillar(lac, x, YC, PH + 0.36, z_top, 0.34, seg=10)
            bracket(lac, x, YC, z_top, 0.52)
    xs_all = sorted([sx * xc for sx in (-1, 1) for xc in COL_X])
    for a, c in zip(xs_all, xs_all[1:]):
        zt = low.z((a + c) * 0.5, YC) - low.th - 0.18 * 3 - 0.12
        lac.box(((a + c) * 0.5, YC, zt - 0.22), (c - a - 0.6, 0.4, 0.34), OK_LACQUER)

    # --- f) frontonul curbat peste intrare
    apex = karahafu(roofb, mort, lac, 0.0, 3.4, -1.0, 6.4, 3.8, 1.9)
    gold_finial(gold, apex[0], apex[1] - 0.2, apex[2], 0.9)

    # --- g) etajul de sus
    UWX = 8.8
    UY_F, UY_R = CY + 3.6, CY - 3.6
    zb_up = 7.2
    wall_to_roof(lac, up, "x", UY_F, -UWX, UWX, zb_up, 0.5)
    wall_to_roof(lac, up, "x", UY_R, -UWX, UWX, zb_up, 0.5)
    for sx in (-1, 1):
        wall_to_roof(lac, up, "y", sx * UWX, UY_R, UY_F, zb_up, 0.5)
    uyf = UY_F + 0.27
    for xw in (-6.6, -3.3, 0.0, 3.3, 6.6):
        _window(wood, xw, uyf, 1.0, 1.9, 1.9, 8.9, "x")
    for sx in (-1, 1):
        for yw in (CY - 1.6, CY + 1.6):
            _window(wood, sx * (UWX + 0.27), yw, sx, 1.7, 1.9, 8.9, "y")
    for xp in [-8.8 + 17.6 * k / 6 for k in range(7)]:
        z_top = up.z(xp, UY_F + 0.45) - up.th - 0.18 * 3 - 0.12
        lacquer_pillar(lac, xp, UY_F + 0.45, 7.7, z_top, 0.27, seg=10)
        bracket(lac, xp, UY_F + 0.45, z_top, 0.44)
    for sx in (-1, 1):
        lacquer_pillar(lac, sx * UWX, UY_R, 7.4, up.z(sx * UWX, UY_R) - up.th - 0.2, 0.3, seg=10)

    # --- i) dragonii de coama
    for sx in (-1, 1):
        gold_dragon(gold, sx * up.R, CY, up.ridge_z + 0.06, s=1.0, d=sx)

    return [to_obj(lac, "Palace_Lacquer"), to_obj(roofb, "Palace_Roof"),
            to_obj(mort, "Palace_Mortar"), to_obj(lime, "Palace_Limestone"),
            to_obj(gold, "Palace_Gold"), to_obj(wood, "Palace_Wood")]


def build_gusuku_wall_curve():
    """Modulul de zid gusuku pe arc (`gusuku_wall_curve`), doua raze in acelasi GLB.

    LISTA DE ELEMENTE (din decuparea `okinawa_assets_v1/gusuku_wall_curve.png` si
    din contractul §1.1; fara tufele de pe creasta si de la baza):
      a) corp de calcar CURB pe arc: coarda 16 m, raza 20 m (`Wall_A_Limestone`)
         si 40 m (`Wall_B_Limestone`), doua radacini in acelasi GLB (B mutat cu +10 m
         pe X ca sa nu se suprapuna; originea fiecaruia = mijlocul corzii, baza la 0)
      b) 8 m inalt, 2,5 m gros la baza, 1,6 m la creasta; fata exterioara (convexa,
         +X) cu talus ~5,4 deg, cea interioara aproape verticala (1,1 deg)
      c) 4 asize vizibile ca forma (2,3 / 2,0 / 1,75 / 1,4 m), fiecare cu rost
         orizontal adanc si bombare usoara; rosturi verticale alternate, ~3-4 m
      d) creasta rotunjita (semielipsa), fara creneluri drepte, ondulata cu 12 cm pe
         lungime (zero la capete)
      e) capete PLANE, perpendiculare pe tangenta, cu sectiune identica (inlantuibile)
    Fara vegetatie. Nod per radacina: `Wall_A_Limestone`, `Wall_B_Limestone`.
    """
    objs = []
    for tag, R, xoff, seed in (("A", 20.0, 0.0, 11), ("B", 40.0, 10.0, 23)):
        b = Builder()
        info = gusuku_wall(b, "arc", R=R, chord=16.0, seed=seed)
        o = to_obj(b, "Wall_%s_Limestone" % tag)
        o.location = (xoff, 0.0, 0.0)
        objs.append(o)
        print("curve", tag, info)
    return objs


def build_gusuku_wall_straight():
    """Modulul drept (`gusuku_wall_straight`): 12 m pe Y, aceeasi sectiune.

    LISTA DE ELEMENTE (din decuparea `gusuku_wall_straight.png`): corp de calcar
    drept 12 m x 8 m, aceeasi sectiune ca la modulul curb (2,5 -> 1,6 m, talus
    ~5,4 deg pe fata +X, 4 asize cu rost si bombare, creasta rotunjita ondulata),
    capete plane identice cu ale modulului curb. Fara vegetatie. `Wall_Limestone`.
    """
    b = Builder()
    gusuku_wall(b, "straight", length=12.0, seed=5)
    return [to_obj(b, "Wall_Limestone")]


ARCH_Y_HALF = 2.0          # semilatimea boltii (raza interioara a bolțarilor)
ARCH_Z_SPRING = 2.5        # linia de nastere
ARCH_CUT = 2.05            # raza taieturii (bolțarii ies 5 cm in deschidere)


def build_gusuku_arch_gate():
    """Poarta boltita (`gusuku_arch_gate`): modul de zid cu bolta de piatra.

    LISTA DE ELEMENTE (din decuparea `gusuku_arch_gate.png` si din contractul §1.1):
      a) modul de zid drept 14 m x 8 m (aceeasi sectiune gusuku, +X = fata exterioara)
      b) deschidere boltita: 4 m latime, 4,5 m inalta (semicerc r 2,05 pe linia
         de nastere de 2,5 m), taiata prin grosimea zidului (axa X)
      c) 11 bolțari in semicerc, cu cheia de bolta mai inalta, adancimea
         urmeaza talusul, ies 14 cm pe fiecare fata
      d) sambure: 3 blocuri de piatra pe fiecare parte, sub linia de nastere
      e) canat de lemn din doua aripi: una inchisa (scanduri verticale, 2 bare de fier),
         cealalta intredeschisa ~40 deg spre interior (-X, spre platforma palatului)
      f) fara vegetatie (tufele de pe decupare), fara dalajul din fata
    Noduri: `Arch_Limestone`, `Arch_Wood`.
    """
    b = Builder()
    gusuku_wall(b, "straight", length=14.0, seed=31)
    wall = to_obj(b, "Arch_Wall_tmp")
    # --- taietura
    cb = Builder()
    pts = [(-ARCH_CUT, -0.6), (ARCH_CUT, -0.6)]
    nseg = 24
    for k in range(nseg + 1):
        th = math.pi * k / nseg
        pts.append((ARCH_CUT * math.cos(th), ARCH_Z_SPRING + ARCH_CUT * math.sin(th)))
    lo, hi = [], []
    for (y, z) in pts:
        lo.append(cb.bm.verts.new((-3.0, y, z)))
        hi.append(cb.bm.verts.new((3.0, y, z)))
    n = len(pts)
    made = []
    for i in range(n):
        j = (i + 1) % n
        made.append(cb.bm.faces.new([lo[i], lo[j], hi[j], hi[i]]))
    made.append(cb.bm.faces.new(lo))
    made.append(cb.bm.faces.new(list(reversed(hi))))
    bmesh.ops.recalc_face_normals(cb.bm, faces=made)
    cutter = to_obj(cb, "Arch_Cutter_tmp")
    bpy.context.view_layer.objects.active = wall
    mod = wall.modifiers.new("Cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cutter
    mod.solver = "EXACT"
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    # --- reia plasa ca Builder si adauga bolta
    bm2 = bmesh.new()
    bm2.from_mesh(wall.data)
    b2 = Builder.__new__(Builder)
    b2.bm = bm2
    lay = bm2.faces.layers.int.get("slot") or bm2.faces.layers.int.new("slot")
    b2.slot = lay
    for f in bm2.faces:
        f[lay] = OK_LIMESTONE
    bpy.data.objects.remove(wall, do_unlink=True)
    arch_blocks(b2, 0.0, ARCH_Z_SPRING, ARCH_Y_HALF, ARCH_Y_HALF + 0.85, 11)
    # --- canatul
    wd = Builder()
    XD = -0.15
    TH = 0.14

    def leaf(hinge_y, sgn, ang):
        """Aripa cu balama la y=hinge_y, intinsa spre `sgn` pe Y; `ang` = deschidere (Z)."""
        rot = Matrix.Rotation(ang, 3, "Z")
        nb = 6
        wb = (ARCH_Y_HALF - 0.04) / nb
        for j in range(nb):
            yl = sgn * (wb * (j + 0.5))
            y_close = hinge_y + yl
            hb = ARCH_Z_SPRING + math.sqrt(max(ARCH_CUT ** 2 - y_close ** 2, 0.04)) - 0.12
            cl = Vector((0.0, yl, hb * 0.5))
            cw = rot @ cl
            wd.box((XD + cw.x, hinge_y + cw.y, cw.z), (TH, wb * 0.94, hb), WOOD, rotation=rot)
        for zb_ in (0.8, 2.3):
            cl = Vector((0.0, sgn * (ARCH_Y_HALF - 0.04) * 0.5, zb_))
            cw = rot @ cl
            wd.box((XD + cw.x, hinge_y + cw.y, cw.z), (TH + 0.05, ARCH_Y_HALF - 0.1, 0.16),
                   LOG_DARK, rotation=rot)
    leaf(-ARCH_Y_HALF + 0.02, +1, 0.0)
    leaf(+ARCH_Y_HALF - 0.02, -1, -math.radians(40.0))
    bmesh.ops.recalc_face_normals(b2.bm, faces=b2.bm.faces[:])
    return [to_obj(b2, "Arch_Limestone"), to_obj(wd, "Arch_Wood")]


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


def _recalc(objs):
    for o in objs:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bm.to_mesh(o.data)
        bm.free()


if _want("ryukyu_palace"):
    objs = build_ryukyu_palace()
    _recalc(objs)
    emit_ok(objs, "buildings/ryukyu_palace.glb", AO_PALACE, keep_xy=False, bevel=0.0,
            smooth_angle=48.0, budget=None)

if _want("gusuku_wall_curve"):
    objs = build_gusuku_wall_curve()
    emit_ok(objs, "structures/gusuku_wall_curve.glb", AO_WALL, keep_xy=True, bevel=0.0,
            smooth_angle=40.0, budget=None)

if _want("gusuku_wall_straight"):
    objs = build_gusuku_wall_straight()
    emit_ok(objs, "structures/gusuku_wall_straight.glb", AO_WALL, keep_xy=True, bevel=0.0,
            smooth_angle=40.0, budget=None)

if _want("gusuku_arch_gate"):
    objs = build_gusuku_arch_gate()
    _recalc(objs)
    emit_ok(objs, "structures/gusuku_arch_gate.glb", AO_WALL, keep_xy=True, bevel=0.0,
            smooth_angle=40.0, budget=None)

report_ok()
