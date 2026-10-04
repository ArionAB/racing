"""Kyoto (Track18) -- carul de festival Gion Matsuri (yamaboko, tip naginata-boko),
hazardul mobil de la POI F (brief kyoto.md §3, decizia dezvoltatorului din 3 oct 2026:
daruma-otoshi, o jucarie, nu se potrivea jocului; „carul nu e in gradina in realitate,
il vreau acolo ca hazard").

  kyoto/vehicles/gion_boko.glb
      Body        carul, static: sasiu, caroserie lacuita cu tapiserii rosii/aurii/
                  bleumarin, platforma cu balustrada, sanctuar, doua acoperisuri in
                  doua ape cu coama aurie, felinare, catargul (shingi) cu inele,
                  traversa cu canafi si lancea aurie din varf
      Wheel_1..4  rotile (spite + janta + butuc); ORIGINEA = centrul osiei, axa pe Z
                  Godot. 1 = (+X,+Y), 2 = (+X,-Y), 3 = (-X,+Y), 4 = (-X,-Y) in Blender
      Puller_P1/P2  trasatorii de la capatul +X (unul pe fiecare flanc); origine = talpa
      Puller_N1/N2  trasatorii de la capatul -X
      Musicians   muzicantii si tobele de pe platforma (static, codul le leagana usor)

CONTRACTUL e scris in `scenes/hazards/gion_matsuri_hazard.gd` (daca difera, codul
castiga). Coordonate de model (Godot): originea = centrul carului LA SOL; axa lunga
(6 m) pe X, latimea (4 m) pe Z; +Y = sus. Carul e simetric fata de X (ambele capete au
echipa lor): codul nu-l roteste niciodata, doar leaga trasatorii de sensul de mers.
In Blender glTF face (x, y, z)_blender -> (x, z, -y)_godot; modelul e simetric in Y, deci
Wheel_1/2 si Puller_*1/2 difera doar prin flanc.

  - Nicio scala neaplicata pe radacina (memoria `scala-glb-neaplicata-la-radacina`).
  - Sloturi: fara CAR_* (verify_glb le marcheaza ILEGAL in decor). Doar atlasul:
    LOG_DARK (lac negru), KERB_RED (rosu), SEA_DEEP (bleumarin), SAND_LIGHT (auriu),
    WOOD (lemn), FOAM_WHITE (felinare, ciucuri de funie), SAND_MID (piele).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_kyoto_gion_boko.py
"""

import math
from mathutils import Vector, Matrix

# --- Sloturi -------------------------------------------------------------
LACQUER = LOG_DARK          # 28  lac negru
RED = KERB_RED              # 7
NAVY = SEA_DEEP             # 18
GOLD = SAND_LIGHT           # 0
TIMBER = WOOD               # 9
CREAM = FOAM_WHITE          # 22
SKIN = SAND_MID             # 1

# --- Cote (identice cu exporturile hazardului) -----------------------------
L_HALF = 3.0                # semilungimea caroseriei (X)
W_HALF = 1.9                # semilatimea caroseriei (Y)
WHEEL_R = 1.0
WHEEL_X = 1.9
WHEEL_Y = 2.35
AXLE_Z = 1.0
CHASSIS_TOP = 1.4
HULL_TOP = 3.7
DECK_TOP = 3.95
SHRINE1_TOP = 6.35
ROOF1_PEAK = 7.95
SHRINE2_BASE = 7.9
SHRINE2_TOP = 9.35
ROOF2_PEAK = 10.55
MAST_BASE = 10.4
MAST_TOP = 18.9
TOP_OF_SPEAR = 21.2
PULLER_Y = 3.35


def tri_yz(b, outline, thickness, slot, cx=0.0):
    """Prisma dintr-un contur 2D in planul YZ (pe Y, Z), extrudata pe X: umplutura
    frontoanelor unui acoperis cu coama pe X."""
    half = thickness * 0.5
    a, c = [], []
    for y, z in outline:
        a.append(b.bm.verts.new((cx - half, y, z)))
        c.append(b.bm.verts.new((cx + half, y, z)))
    n = len(outline)
    b.bm.faces.new(tuple(reversed(a)))
    b.bm.faces.new(tuple(c))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((a[i], c[i], c[j], a[j]))
    return b._tag(a + c, slot)


def gable_roof(b, half_len, peak, eave_z, eave_y, thick, slot, trim_slot, up_y=0.5,
               up_z=0.34):
    """Acoperis in doua ape cu coama pe X: doua placi inclinate, streasina cu muchia
    ridicata (curba japoneza, din doua segmente), coama aurie, frontoane umplute."""
    for sy in (-1.0, 1.0):
        b.beam((0.0, 0.0, peak), (0.0, sy * eave_y, eave_z), (half_len * 2.0, thick), slot)
        b.beam((0.0, sy * eave_y, eave_z), (0.0, sy * (eave_y + up_y), eave_z + up_z),
               (half_len * 2.0, thick * 0.9), slot)
        # muchia aurie a streasinii
        b.box((0.0, sy * (eave_y + up_y), eave_z + up_z), (half_len * 2.0 + 0.1, 0.16, 0.16),
              trim_slot)
    # coama
    b.box((0.0, 0.0, peak + 0.05), (half_len * 2.0 + 0.5, 0.42, 0.34), trim_slot)
    # frontoane: triunghiul de sub placi, putin retras
    inset = half_len - 0.12
    for sx in (-1.0, 1.0):
        tri_yz(b, [(-eave_y * 0.93, eave_z + 0.05), (eave_y * 0.93, eave_z + 0.05),
                   (0.0, peak - 0.18)], 0.2, LACQUER, cx=sx * inset)
        # ornament de frontoane (onigawara): un bloc aurit la coama
        b.box((sx * (half_len + 0.28), 0.0, peak + 0.15), (0.3, 0.5, 0.7), trim_slot)


def lantern(b, x, y, z):
    b.box((x, y, z + 0.38), (0.05, 0.05, 0.4), LACQUER)       # snur
    b.cylinder((x, y, z), 0.26, 0.5, CREAM, segments=8)
    b.cylinder((x, y, z + 0.27), 0.28, 0.08, RED, segments=8)
    b.cylinder((x, y, z - 0.27), 0.28, 0.08, RED, segments=8)


def build_body():
    b = Builder()
    # --- sasiu si osii ---
    b.box((0.0, 0.0, (AXLE_Z - 0.15 + CHASSIS_TOP) * 0.5),
          (2.0 * L_HALF, 2.0 * W_HALF - 0.2, CHASSIS_TOP - AXLE_Z + 0.15), TIMBER)
    for sx in (-1.0, 1.0):
        b.beam((sx * WHEEL_X, -WHEEL_Y - 0.3, AXLE_Z), (sx * WHEEL_X, WHEEL_Y + 0.3, AXLE_Z),
               (0.24, 0.24), LACQUER)
    # --- caroseria inferioara (lac negru) + tapiserii ---
    hull_h = HULL_TOP - CHASSIS_TOP
    hull_c = (CHASSIS_TOP + HULL_TOP) * 0.5
    b.box((0.0, 0.0, hull_c), (2.0 * L_HALF - 0.4, 2.0 * W_HALF, hull_h), LACQUER)
    for sy in (-1.0, 1.0):
        y = sy * (W_HALF + 0.04)
        # panoul rosu al tapiseriei
        b.box((0.0, y, hull_c), (5.0, 0.1, hull_h - 0.55), RED)
        # benzi bleumarin verticale si medalioane aurii pe rosu
        for x in (-2.0, 0.0, 2.0):
            b.box((x, y + sy * 0.02, hull_c), (0.55, 0.12, hull_h - 0.55), NAVY)
        for x in (-1.0, 1.0):
            b.cylinder((x, y + sy * 0.05, hull_c), 0.36, 0.1, GOLD, segments=8, axis="Y")
        # franjuri aurii sus si jos
        b.box((0.0, y + sy * 0.02, hull_c + (hull_h - 0.55) * 0.5 + 0.1), (5.2, 0.14, 0.16), GOLD)
        b.box((0.0, y + sy * 0.02, hull_c - (hull_h - 0.55) * 0.5 - 0.1), (5.2, 0.14, 0.16), GOLD)
    for sx in (-1.0, 1.0):
        x = sx * (L_HALF - 0.2 + 0.04)
        b.box((x, 0.0, hull_c), (0.1, 3.3, hull_h - 0.55), NAVY)
        b.cylinder((x + sx * 0.03, 0.0, hull_c), 0.55, 0.1, GOLD, segments=8, axis="X")
        b.box((x, 0.0, hull_c + (hull_h - 0.55) * 0.5 + 0.1), (0.14, 3.5, 0.16), GOLD)
        # funie groasa (shimenawa) infasurata pe capatul carului
        b.box((x + sx * 0.08, 0.0, CHASSIS_TOP + 0.3), (0.14, 3.7, 0.18), CREAM)
    # --- platforma + balustrada aurie ---
    b.box((0.0, 0.0, (HULL_TOP + DECK_TOP) * 0.5), (2.0 * L_HALF, 4.3, DECK_TOP - HULL_TOP), TIMBER)
    px, py = L_HALF - 0.1, 2.05
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * px, sy * py, DECK_TOP + 0.4), (0.18, 0.18, 0.8), GOLD)
    for sy in (-1.0, 1.0):
        b.beam((-px, sy * py, DECK_TOP + 0.78), (px, sy * py, DECK_TOP + 0.78), (0.14, 0.14), GOLD)
    for sx in (-1.0, 1.0):
        b.beam((sx * px, -py, DECK_TOP + 0.78), (sx * px, py, DECK_TOP + 0.78), (0.14, 0.14), GOLD)
    # --- sanctuarul de jos ---
    s1_h = SHRINE1_TOP - DECK_TOP
    s1_c = (DECK_TOP + SHRINE1_TOP) * 0.5
    b.box((0.0, 0.0, s1_c), (4.0, 3.0, s1_h), LACQUER)
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * 2.0, sy * 1.5, s1_c), (0.32, 0.32, s1_h + 0.1), RED)
    for sy in (-1.0, 1.0):
        # perdele rosii cu chenar auriu, cu doua dungi bleumarin
        b.box((0.0, sy * 1.53, s1_c - 0.1), (3.2, 0.08, s1_h - 0.7), RED)
        b.box((0.0, sy * 1.57, s1_c - 0.1), (0.45, 0.08, s1_h - 0.7), NAVY)
        b.box((0.0, sy * 1.55, s1_c + (s1_h - 0.7) * 0.5 - 0.1), (3.3, 0.12, 0.14), GOLD)
    for sx in (-1.0, 1.0):
        b.box((sx * 2.03, 0.0, s1_c - 0.1), (0.08, 2.4, s1_h - 0.7), RED)
        b.cylinder((sx * 2.07, 0.0, s1_c - 0.1), 0.42, 0.08, GOLD, segments=8, axis="X")
    # --- acoperisul 1 ---
    gable_roof(b, 3.3, ROOF1_PEAK, SHRINE1_TOP + 0.2, 3.1, 0.26, LACQUER, GOLD)
    # --- sanctuarul de sus + acoperisul 2 ---
    s2_h = SHRINE2_TOP - SHRINE2_BASE
    s2_c = (SHRINE2_BASE + SHRINE2_TOP) * 0.5
    b.box((0.0, 0.0, s2_c), (2.8, 2.0, s2_h), LACQUER)
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * 1.4, sy * 1.0, s2_c), (0.26, 0.26, s2_h + 0.1), RED)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * 1.03, s2_c), (2.0, 0.08, s2_h - 0.5), RED)
        b.box((0.0, sy * 1.07, s2_c), (0.35, 0.08, s2_h - 0.5), GOLD)
    gable_roof(b, 2.2, ROOF2_PEAK, SHRINE2_TOP + 0.15, 2.3, 0.22, LACQUER, GOLD,
               up_y=0.4, up_z=0.28)
    # --- felinare: colturile acoperisului 1 si ale platformei ---
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            lantern(b, sx * 3.0, sy * 3.55, SHRINE1_TOP - 0.3)
            lantern(b, sx * 2.1, sy * 2.2, DECK_TOP + 1.45)
    # --- catargul (shingi): se subtiaza, cu inele aurii si rosii, traversa cu ciucuri ---
    b.frustum((0.0, 0.0, (MAST_BASE + MAST_TOP) * 0.5), 0.42, 0.2, MAST_TOP - MAST_BASE,
              TIMBER, segments=8)
    for i, z in enumerate((11.6, 13.7, 15.8, 17.9)):
        r = 0.55 - 0.05 * i
        b.cylinder((0.0, 0.0, z), r, 0.3, GOLD if i % 2 == 0 else RED, segments=8)
    # traversa pe X (axa lunga a carului): se vede de-a lungul din sosea, nu din capat
    b.box((0.0, 0.0, 14.6), (3.8, 0.16, 0.16), GOLD)
    for sx in (-1.0, 1.0):
        b.box((sx * 1.8, 0.0, 13.75), (0.26, 0.26, 1.6), RED)          # ciucuri
        b.box((sx * 1.8, 0.0, 12.85), (0.36, 0.36, 0.3), GOLD)
    b.cylinder((0.0, 0.0, MAST_TOP + 0.12), 0.32, 0.26, GOLD, segments=8)   # soclul lancii
    # lancea (naginata/ho-boko): con auriu cu 4 laturi, prelung
    b.frustum((0.0, 0.0, MAST_TOP + 0.25 + (TOP_OF_SPEAR - MAST_TOP - 0.25) * 0.5), 0.34, 0.0,
              TOP_OF_SPEAR - MAST_TOP - 0.25, GOLD, segments=4)
    return b.to_object("Body")


def build_wheel(sy):
    b = Builder()
    b.torus((0.0, 0.0, 0.0), WHEEL_R - 0.14, 0.14, LACQUER, major_seg=14, minor_seg=4, axis="Y")
    b.cylinder((0.0, 0.0, 0.0), 0.28, 0.62, GOLD, segments=8, axis="Y")
    for k in range(4):
        a = math.pi * k / 4.0
        d = Vector((math.cos(a), 0.0, math.sin(a))) * (WHEEL_R - 0.12)
        b.beam(-d, d, (0.2, 0.18), TIMBER, up=(0, 1, 0))
    # disc de lemn plin, subtire, ca spitele sa nu fie goale la 40 m (roata de lemn)
    b.cylinder((0.0, 0.0, 0.0), WHEEL_R - 0.2, 0.1, TIMBER, segments=14, axis="Y")
    return b.to_object("Wheel")


def _figure(b, x, y, face_dir, robe, lean=0.0):
    """Siluet low-poly de om in picioare, cu talpa la z = 0."""
    b.frustum((x, y, 0.55), 0.3, 0.24, 1.1, robe, segments=8)                 # kimono
    b.frustum((x, y, 1.3), 0.26, 0.2, 0.4, NAVY if robe == RED else RED, segments=8)  # tors
    b.cylinder((x, y, 1.72), 0.17, 0.3, SKIN, segments=8)                       # cap
    b.cylinder((x, y, 1.92), 0.19, 0.1, CREAM, segments=8)                      # hachimaki
    # bratele intinse spre franghie
    b.beam((x, y, 1.35), (x + face_dir[0] * 0.55, y + face_dir[1] * 0.55, 1.25), (0.14, 0.14), SKIN)


def build_puller(sx, sy):
    b = Builder()
    # fata trasatorului: spre carul (-sy), cu mainile spre franghie
    _figure(b, 0.0, 0.0, (0.0, -sy), RED if sx > 0 else NAVY)
    # franghia: de la maini la osia carului, in loc de o linie lunga
    return b.to_object("Puller")


def build_musicians():
    b = Builder()
    for sx in (-1.0, 1.0):
        x = sx * 2.5
        # toba taiko (axa pe Y), pe un suport scund
        b.box((x, 0.0, DECK_TOP + 0.3), (0.9, 0.8, 0.6), TIMBER)
        b.cylinder((x, 0.0, DECK_TOP + 0.95), 0.5, 0.55, RED, segments=10, axis="Y")
        b.cylinder((x, 0.0, DECK_TOP + 0.95), 0.44, 0.62, CREAM, segments=10, axis="Y")
        # doi muzicanti sezuti, de-o parte si de alta a tobei
        for sy in (-1.0, 1.0):
            y = sy * 1.05
            b.frustum((x, y, DECK_TOP + 0.4), 0.34, 0.26, 0.8, NAVY if sy > 0 else RED, segments=8)
            b.cylinder((x, y, DECK_TOP + 0.98), 0.17, 0.3, SKIN, segments=8)
            b.cylinder((x, y, DECK_TOP + 1.18), 0.22, 0.1, LACQUER, segments=8)
    return b.to_object("Musicians")


clear_built()
body = build_body()
wheels = []
for j, (wx, wy) in enumerate(((1, 1), (1, -1), (-1, 1), (-1, -1))):
    w = build_wheel(wy)
    w.name = "Wheel_%d" % (j + 1)
    wheels.append((w, wx, wy))
pullers = []
for nm, sx, sy in (("Puller_P1", 1, 1), ("Puller_P2", 1, -1), ("Puller_N1", -1, 1),
                   ("Puller_N2", -1, -1)):
    p = build_puller(sx, sy)
    p.name = nm
    pullers.append((p, sx, sy))
musicians = build_musicians()


def _ao(z_lo, z_hi, low=0.62, dist=2.0, grad="vertical"):
    return dict(samples=24, dist=dist, gradient=grad, low=low, high=1.0,
                power=0.9, floor=0.3, z_range=(z_lo - 0.05, z_hi))


stats = {}
stats["Body"] = finish(body, bevel=0.04, ao=_ao(AXLE_Z - 0.2, TOP_OF_SPEAR, 0.55, 3.0),
                       origin=None, smooth_angle=None)
for w, wx, wy in wheels:
    stats[w.name] = finish(w, bevel=0.03, ao=dict(samples=16, dist=0.8, gradient="spherical",
                           floor=0.4), origin=None, smooth_angle=None)
for p, sx, sy in pullers:
    stats[p.name] = finish(p, bevel=0.02, ao=_ao(0.0, 2.0, 0.7, 0.9), origin=None,
                           smooth_angle=40.0)
stats["Musicians"] = finish(musicians, bevel=0.02, ao=_ao(DECK_TOP, DECK_TOP + 1.4, 0.7, 0.9),
                            origin=None, smooth_angle=40.0)

body.location = (0.0, 0.0, 0.0)
for w, wx, wy in wheels:
    w.location = (wx * WHEEL_X, wy * WHEEL_Y, AXLE_Z)
for p, sx, sy in pullers:
    p.location = (sx * 1.9, sy * PULLER_Y, 0.0)
musicians.location = (0.0, 0.0, 0.0)

objs = [body] + [w for w, _, _ in wheels] + [p for p, _, _ in pullers] + [musicians]
for o in objs:
    o.rotation_euler = (0.0, 0.0, 0.0)
path, size = export_glb(objs, "kyoto/vehicles/gion_boko.glb")
save_blend(objs, "kyoto_gion_boko.blend")
print("== gion_boko ==", path, "%.1f KB" % (size / 1024.0))
for k, v in stats.items():
    print("  %-10s tris=%d ao=[%.2f..%.2f]" % (k, v["tris"], v["ao_min"], v["ao_max"]))
print("  total tris:", sum(v["tris"] for v in stats.values()),
      "| inaltime totala %.1f m, caroserie %.1f x %.1f m" % (TOP_OF_SPEAR, 2 * L_HALF, 2 * W_HALF))
