"""Kitul alpin — STRUCTURILE (planşa "Swiss Alps — Alpine Switchback").

  CableCarPylon   structures/cable_car_pylon.glb   3 x 3 x ~18 m   <= 5000
  MountainTunnel  structures/mountain_tunnel.glb   18 x 15 x 12 m  <= 5000
  StreamBridge    structures/stream_bridge.glb     18 x 5 x 3 m    <= 1500
  JumpKicker      structures/jump_kicker.glb       8 x 4 x 1.5 m   <= 1500
  WoodenFence     structures/wooden_fence.glb      2 x 0.15 x 1.2  <= 300/varianta

Granitul alpin n-are slot propriu: CONCRETE (gri-bej deschis) + ASPHALT_EDGE
(gri mediu) + VOLCANIC_BLACK (umbra) fac impreuna piatra de munte. Golurile
(tunel, arcade) sunt spatiu INTRE mase, nu taieturi — lectia de la mine_portal.
"""

import math
from mathutils import Matrix, Vector

# Doua valori apropiate; banda VOLCANIC_BLACK iesea o dunga stridenta pe
# masa de stanca (vazut la prima randare a tunelului).
GRANITE_STRATA = (CONCRETE, ASPHALT_EDGE)


def rot_all(b, deg, axis="Z"):
    rot = Matrix.Rotation(math.radians(deg), 3, axis)
    for v in b.bm.verts:
        v.co = rot @ v.co


# ========================================================== CableCarPylon
# Turn zabrelit din grinzi, ingustat spre varf, cu traversa si doua rulouri
# de cablu sus. Otelul e PAINTED (#7692A8) — gri-albastru rece, citeste metal
# vopsit fara sa fure saturatie masinilor. Grinzile NU primesc bevel (sub
# pragul la care tesitura mai adauga ceva — nota de buget din mine_portal).

PYLON_H = 16.6
PYLON_BASE = 1.42     # jumatate de deschidere la sol -> amprenta ~3 x 3
PYLON_TOP = 0.55
PANELS = 5


def build_pylon():
    b = Builder()

    def half_at(z):
        return PYLON_BASE + (PYLON_TOP - PYLON_BASE) * (z / PYLON_H)

    # picioarele
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.beam((sx * PYLON_BASE, sy * PYLON_BASE, 0.0),
                   (sx * PYLON_TOP, sy * PYLON_TOP, PYLON_H), 0.20, PAINTED)
    # inele orizontale + cate o diagonala pe fata, cu sensul alternat pe nivel
    for k in range(1, PANELS + 1):
        z1 = PYLON_H * k / PANELS
        z0 = PYLON_H * (k - 1) / PANELS
        h1, h0 = half_at(z1), half_at(z0)
        corners1 = [(-h1, -h1), (h1, -h1), (h1, h1), (-h1, h1)]
        corners0 = [(-h0, -h0), (h0, -h0), (h0, h0), (-h0, h0)]
        for i in range(4):
            j = (i + 1) % 4
            b.beam((corners1[i][0], corners1[i][1], z1),
                   (corners1[j][0], corners1[j][1], z1), 0.11, PAINTED)
            if k % 2 == 0:
                a, cN = corners0[i], corners1[j]
            else:
                a, cN = corners0[j], corners1[i]
            b.beam((a[0], a[1], z0), (cN[0], cN[1], z1), 0.10, PAINTED)

    # traversa: grinda-cheson pe X, cu contrafise spre turn
    arm_z = PYLON_H + 0.45
    b.box((0.0, 0.0, arm_z), (4.5, 0.62, 0.55), PAINTED)
    for sx in (-1.0, 1.0):
        b.beam((sx * 1.9, 0.0, arm_z - 0.25), (sx * 0.4, 0.0, PYLON_H - 1.2),
               0.13, PAINTED)
        # bateriile de rulouri de la capete + bucata de cablu care trece
        b.box((sx * 2.05, 0.0, arm_z - 0.55), (0.8, 0.24, 0.5), VOLCANIC_BLACK)
        b.cylinder((sx * 2.05, 0.0, arm_z - 0.85), 0.3, 0.16, VOLCANIC_BLACK,
                   segments=8, axis="Y")
    # varf cu paratrasnet
    b.beam((0.0, 0.0, arm_z + 0.27), (0.0, 0.0, arm_z + 1.15), 0.06, PAINTED)
    return b


# ========================================================= MountainTunnel
# 18 x 15 x 12, strapuns pe Y (masina intra pe o fata, iese pe cealalta).
# Golul e spatiu intre mase: doi umeri de stanca, un capac deasupra, captuseala
# interioara si cate un portal de zidarie la fiecare gura. Deschiderea utila:
# 8 m latime x 5.5 m inaltime — doua masini una langa alta plus marja.

OPEN_W, OPEN_H = 8.0, 5.5
TUN_DEPTH = 14.2


def arch_outline(inner_hw, inner_top, outer_hw, outer_top, base=0.0):
    """Banda de portal: contur in XZ, deschis la baza (simplu conex)."""
    pts = [(-outer_hw, base), (-outer_hw, outer_top * 0.72),
           (-outer_hw * 0.72, outer_top), (outer_hw * 0.72, outer_top),
           (outer_hw, outer_top * 0.72), (outer_hw, base),
           (inner_hw, base), (inner_hw, inner_top * 0.76)]
    # arcul interior, dreapta -> stanga
    for i in range(1, 6):
        a = math.pi * i / 6.0
        pts.append((inner_hw * math.cos(a),
                    inner_top * 0.76 + inner_top * 0.24 * math.sin(a)))
    pts.append((-inner_hw, inner_top * 0.76))
    pts.append((-inner_hw, base))
    return pts


def flatten_faces_y(b, half_depth):
    """Reteaza fetele dinspre +/-Y ale maselor de stanca pe planele gurilor.
    Lectia de la mine_portal.flatten_back: fara taietura plana, portalul ori
    pluteste in fata stancii, ori e ingropat in ea — perturbatia de 30 cm nu
    lasa cale de mijloc."""
    for v in b.bm.verts:
        if v.co.y > half_depth:
            v.co.y = half_depth
        elif v.co.y < -half_depth:
            v.co.y = -half_depth


def build_tunnel():
    b = Builder()
    half = TUN_DEPTH * 0.5
    # umerii de stanca (flancurile) — adancime peste TUN_DEPTH, apoi retezati
    # plan la gurile tunelului, ca portalul sa aiba de ce sa se lipeasca
    for sx, seed in ((-1.0, 31), (1.0, 47)):
        b.rock((sx * 6.9, 0.0, 0.0), (5.4, TUN_DEPTH + 3.0, 10.5 / 0.82),
               CONCRETE, seed=seed, segments=7, rings=3, taper=0.22,
               squash=0.9, flat_top=True, strata_slots=GRANITE_STRATA)
    # capacul peste deschidere: mai INGUST decat marginea exterioara a
    # umerilor (8.6 < ~9.5), altfel coltul lui de jos iese prin flanc ca o
    # pana plutitoare — vazut la prima randare
    b.rock((0.0, 0.0, 5.6), (17.2, TUN_DEPTH + 3.0, 7.2 / 0.82), CONCRETE,
           seed=73, segments=8, rings=2, taper=0.34, squash=0.85,
           flat_top=True, strata_slots=GRANITE_STRATA)
    flatten_faces_y(b, half)
    # zapada pe crestetul masei de stanca
    all_faces = set(b.bm.faces)
    b.retag(all_faces, FOAM_WHITE,
            where=lambda c, n: n.z > 0.55 and c.z > 8.2)

    # captuseala interioara: peretii si tavanul culoarului. Gura intunecata E
    # efectul (mine_portal: slotul cel mai inchis citeste ca gol).
    b.box((-4.6, 0.0, 2.9), (1.0, TUN_DEPTH + 0.6, 5.8), ASPHALT_EDGE)
    b.box((4.6, 0.0, 2.9), (1.0, TUN_DEPTH + 0.6, 5.8), ASPHALT_EDGE)
    b.box((0.0, 0.0, 6.15), (10.2, TUN_DEPTH + 0.6, 1.3), ASPHALT)

    # portalurile de zidarie: intra 0.55 m in planul retezat al stancii,
    # deci fara fanta intre zidarie si munte
    outline = arch_outline(OPEN_W * 0.5, OPEN_H, OPEN_W * 0.5 + 1.5,
                           OPEN_H + 2.1)
    for sy in (-1.0, 1.0):
        faces = b.prism(outline, 1.1, CONCRETE,
                        center=(0.0, sy * half, 0.0))
        # intradosul arcului, in umbra
        b.retag(faces, VOLCANIC_BLACK,
                where=lambda c, n: n.z < -0.4 and c.z > 3.0)
    return b


# =========================================================== StreamBridge
# 18 x 5 x 3: pod de piatra cu trei arcade peste parau. Conturul e UN singur
# poligon (tablier sus, serpuit peste arcade jos), extrudat pe Y la latimea
# de 5 m; parapetii sunt cutii separate.

DECK_Z = 2.45
ARCH_SPAN = 4.0
ARCH_RISE = 1.65
PIERS = (-5.7, 0.0, 5.7)


def build_bridge():
    b = Builder()
    pts = [(-9.0, 0.0), (-9.0, DECK_Z), (9.0, DECK_Z), (9.0, 0.0)]
    # inapoi pe dedesubt, de la dreapta la stanga, peste fiecare arcada
    for cx in reversed(PIERS):
        pts.append((cx + ARCH_SPAN * 0.5, 0.0))
        for i in range(1, 6):
            a = math.pi * i / 6.0
            pts.append((cx + ARCH_SPAN * 0.5 * math.cos(a),
                        ARCH_RISE * math.sin(a)))
        pts.append((cx - ARCH_SPAN * 0.5, 0.0))
    faces = b.prism(pts, 5.0, CONCRETE)
    # intradosul arcadelor in umbra — adancimea se citeste din valoare.
    # |n.x| < 0.9 pastreaza fetele de CAPAT (|n.x| = 1) pe piatra deschisa:
    # prima randare le innegrea si podul parea ars la ambele capete.
    b.retag(faces, VOLCANIC_BLACK,
            where=lambda c, n: n.z < 0.1 and 0.2 < c.z < ARCH_RISE + 0.35
            and abs(n.y) < 0.6 and abs(n.x) < 0.9)
    # calea de rulare
    b.retag(faces, ASPHALT_EDGE, where=lambda c, n: n.z > 0.5)

    # parapeti plini de piatra, cu capace la capete
    for sy in (-1.0, 1.0):
        pf = b.box((0.0, sy * 2.3, DECK_Z + 0.45), (18.0, 0.4, 0.9),
                   CONCRETE)
        b.retag(pf, ASPHALT_EDGE, where="up")
        for sx in (-1.0, 1.0):
            b.box((sx * 8.75, sy * 2.3, DECK_Z + 0.55), (0.62, 0.55, 1.1),
                  ASPHALT_EDGE)
    return b


# ============================================================= JumpKicker
# 8 m latime, 4 m adancime, 1.5 m: kicker-ul e construit din 8 felii de pana
# alternand rosu/alb (dungile cer geometrie: retag nu poate dunga O fata), iar
# fata de rulare e re-etichetata gri — deci dungile raman pe flancuri si pe
# spatele vertical, exact ca pe plansa.

def build_kicker():
    b = Builder()
    profile = [(-2.0, 0.0), (-0.7, 0.38), (0.5, 0.95), (1.55, 1.5),
               (2.0, 1.5), (2.0, 0.0)]
    for i in range(8):
        y_c = -3.5 + i  # inainte de rotatie, "latimea" e pe Y
        slot = KERB_RED if i % 2 == 0 else FOAM_WHITE
        faces = b.prism(profile, 1.0, slot, center=(0.0, y_c, 0.0))
        b.retag(faces, ASPHALT_EDGE,
                where=lambda c, n: n.z > 0.45 and c.z > 0.05)
    rot_all(b, 90.0, "Z")   # slope pe +Y, latimea pe X
    return b


# ============================================================ WoodenFence
# Modul de 2 m, doua variante intr-un GLB (ca marker_post): A dreapta,
# B imbatranita — instantiate alternat, gardul nu mai citeste ca extrudat.

def build_fence(seed, jitter):
    b = Builder()
    b.pickets((-0.9, 0.0, 0.0), (0.9, 0.0, 0.0), 2, (0.14, 0.14, 1.2),
              WOOD, tilt_jitter=jitter, seed=seed)
    for z in (0.52, 0.98):
        dz = 0.0 if jitter == 0 else (0.05 if z > 0.7 else -0.03)
        b.beam((-1.02, 0.0, z), (1.02, 0.0, z + dz), (0.26, 0.07), WOOD)
    return b


# ------------------------------------------------------------------ build
AO_BIG = dict(samples=26, dist=7.0, gradient="vertical", low=0.45, high=1.0,
              power=0.85, floor=0.10)
AO_MID = dict(samples=24, dist=2.5, gradient="vertical", low=0.5, high=1.0,
              power=1.0, floor=0.14)

ASSETS = [
    ("CableCarPylon", build_pylon, "structures/cable_car_pylon.glb", 5000,
     0.0, AO_MID),
    ("MountainTunnel", build_tunnel, "structures/mountain_tunnel.glb", 5000,
     0.09, AO_BIG),
    # AO mai bland decat AO_MID: parapetii si tablierul se ocludeau reciproc
    # si tot podul iesea aproape negru pe partea din umbra
    ("StreamBridge", build_bridge, "structures/stream_bridge.glb", 1500,
     0.05, dict(samples=24, dist=1.8, gradient="vertical", low=0.62,
                high=1.0, power=1.0, floor=0.26)),
    ("JumpKicker", build_kicker, "structures/jump_kicker.glb", 1500,
     0.03, AO_MID),
]

built = []
for name, make, glb, budget, bevel, ao in ASSETS:
    clear_built(name)
    b = make()
    obj = b.to_object(name)
    stats = finish(obj, bevel=bevel, bevel_angle=40.0, ao=ao)
    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-16s %5d tris (buget %d) %s | %.1f x %.1f x %.1f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK" if stats["tris"] <= budget else "DEPASIT",
             dims[0], dims[1], dims[2], stats["ao_min"], stats["ao_max"]))
    print("GLB:   %s (%d B)" % export_glb([obj], glb))
    built.append(obj)

# gardul: doua variante, copii la origine in acelasi GLB
clear_built("Fence")
fence_objs = []
for name, seed, jitter in (("Fence_A", 3, 0.0), ("Fence_B", 11, 5.0)):
    b = build_fence(seed, jitter)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.02, bevel_angle=40.0,
                   ao=dict(samples=20, dist=1.0, gradient="vertical",
                           low=0.6, high=1.0, power=1.0, floor=0.3))
    print("%-16s %5d tris (buget 300) %s" % (name, stats["tris"],
          "OK" if stats["tris"] <= 300 else "DEPASIT"))
    obj.location = (0.0, 0.0, 0.0)
    fence_objs.append(obj)
print("GLB:   %s (%d B)" % export_glb(fence_objs, "structures/wooden_fence.glb"))
built.extend(fence_objs)

print("BLEND: %s (%d B)" % save_blend(built, "alpine_structures.blend"))
