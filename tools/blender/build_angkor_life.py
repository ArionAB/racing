"""Angkor -- val 3, grupul C: viata si micile piese (brief docs/asset_briefs/angkor_kit.md
§1.4-§1.6).

  angkor/structures/srah_srang_landing.glb  debarcader de laterita ~14 x 8 m, trepte 1,5 m
  angkor/vehicles/tuk_tuk.glb               DOUA radacini: Moto + Remorca (BumpProp: <= 2 m)
  angkor/animals/monk_standing.glb          calugar in picioare, 1,7 m, roba sofran
  angkor/props/laterite_block.glb           bloc de laterita poroasa, cavitati reale
  angkor/props/rubble_pile.glb              gramada de moloz de gresie, ~2 m
  angkor/props/numbered_block.glb           bloc cu O cifra pictata (singurul marcaj din kit)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_life.py
ANK_ONLY=<landing|tuk|monk|laterite|rubble|numbered> reface doar piesa respectiva.

Axe (Blender): X latime, Y inainte (+Y = -Z in Godot), Z sus.
DECIZIA DEZVOLTATORULUI (6 nov 2026): tot ce e sculptural e SIMPLIFICAT (lei, naga, calugar =
volume lizibile din hull-uri, nu sculptura). Fara marci, fara numere pe vehicul.

TUK-TUK: doua obiecte-radacina goale `Moto` si `Remorca`, fiecare cu noduri mesh copil. Piesele
sunt modelate in jurul propriului centru (translatia e pe radacina, scala/rotatia identice), ca
integrarea sa le poata impacheta fiecare intr-un BumpProp (limita din scenes/props/bump_prop.gd:
2,0 m in plan, 1,8 m inaltime). Remorca are 1,98 x 1,42 x 1,78: sub ambele plafoane.
"""

import math
import os
import bmesh
import bpy
from mathutils import Vector, Matrix, Euler

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")

S = ANK_STONE
LAT = LARCH_RUST          # 27
PAINT = PAINTED           # 11 (PAINTED_METAL: vopsea stinsa)
WOODW = WOOD              # 9 (WOOD_WEATHERED)
BLK = VOLCANIC_BLACK      # 20
ROOF = TILE_TERRACOTTA    # 23
ROBE = LAVA_ORANGE        # 30
SKIN = TILE_TERRACOTTA    # 23: nu exista slot de piele; terracota calda citeste ca ten (nota in inventar)
DIGIT = CORAL_SAND        # 19


def want(k):
    return not ONLY or ONLY == k


def rot_z(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


def rot_e(rx, ry, rz):
    return Euler((math.radians(rx), math.radians(ry), math.radians(rz)), "XYZ").to_matrix()


def face_blocks(b, cx, cy, yaw, width, z0, z1, courses, block_w, proud=0.04, gap=0.03,
                slot=LAT, seed=0, u_off=0.0):
    """Randuri de blocuri in relief pe O fata verticala. Fata e in planul care trece prin
    (cx, cy), cu normala exterioara la `yaw` (0 = +Y, 180 = -Y, -90 = +X, 90 = -X); se intinde
    `width` pe orizontala, centrata (plus `u_off`), de la z0 la z1."""
    rnd = lcg(seed + 5)
    fr = Frame((cx, cy, 0.0), yaw)
    rot = rot_z(yaw)
    ch = (z1 - z0) / courses
    n = max(1, int(round(width / block_w)))
    for c in range(courses):
        za, zb = z0 + c * ch + gap * 0.5, z0 + (c + 1) * ch - gap * 0.5
        edges = [-width / 2 + width * i / n for i in range(n + 1)]
        if c % 2 and n > 1:
            edges = [edges[0]] + [e + width / (2 * n) for e in edges[1:-1]] + [edges[-1]]
        edges = [e + ((rnd() - 0.5) * 0.14 * block_w if 0 < i < len(edges) - 1 else 0.0)
                 for i, e in enumerate(edges)]
        for ua, ub in zip(edges[:-1], edges[1:]):
            ua2, ub2 = ua + gap * 0.5, ub - gap * 0.5
            if ub2 - ua2 < 0.08:
                continue
            ctr = fr.p((ua2 + ub2) * 0.5 + u_off, proud * 0.5 - 0.005, (za + zb) * 0.5)
            b.box(ctr, (ub2 - ua2, proud + 0.01, zb - za), slot, rotation=rot)


def ring(rx, ry, z, n=10, cx=0.0, cy=0.0, rot=0.0):
    pts = []
    for k in range(n):
        a = 2.0 * math.pi * (k + rot) / n
        pts.append(Vector((cx + rx * math.cos(a), cy + ry * math.sin(a), z)))
    return pts


def emit_at(objs, path, ao, place=(0.0, 0.0, 0.0), bevels=None, bevel=0.02, smooth_angle=45.0):
    """Ca `emit_angkor`, dar cu offsetul de origine EXPLICIT (debarcaderul are originea la
    cota platformei, nu la talpa): ansamblul se muta O DATA cu `place`."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    off = Vector(place)
    total, per_node = 0, {}
    for o in objs:
        for v in o.data.vertices:
            v.co += off
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        st = finish(o, bevel=bw, bevel_angle=30.0, ao=ao, origin=None, smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "angkor/" + path)
    ANK_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    print("   %s: x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f" % (path, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    clear_built()
    return total


# ============================================================================
# 1. DEBARCADERUL SRAH SRANG
# ============================================================================
# Platforma x -7..7, y -1..4 (sus, z=0); aripi x +-3..7 pana la y=-4; scara centrala x -3..3
# coboara spre -Y (spre apa) 6 trepte de 0,25 = 1,5 m. Corpurile merg pana la z=-1,7 (sub apa).

L_BOT = -1.7
L_STEPS = 6
L_RISE = 0.25
L_TREAD = 0.5
L_Y_STEP0 = -1.0           # unde incepe scara (marginea platformei)
L_WING_X = 3.0


def lion(b, cx, cy, z0, yaw, s=1.0):
    """Leu de gresie SIMPLIFICAT, sezand, cu fata spre `yaw` (0 = +Y). Volume mari: sezut,
    piept, doua labe din fata, coama-disc octogonala, bot-bloc, urechi. ~1,1 m inaltime la s=1."""
    fr = Frame((cx, cy, 0.0), yaw)
    rot = fr.rot

    def P(u, w, z):
        return fr.p(u * s, w * s, z0 + z * s)

    # sezut (sezand pe sold): doua cocoase + trunchi
    for sg in (-1, 1):
        ellipsoid(b, P(sg * 0.20, -0.16, 0.26), (0.17 * s, 0.25 * s, 0.25 * s), S, rot, 9, 6)
    hull(b, [P(sg * u, w, z) for sg in (-1, 1) for (u, w, z) in
             ((0.22, -0.40, 0.04), (0.24, -0.40, 0.42), (0.20, 0.10, 0.06), (0.17, 0.12, 0.80),
              (0.19, -0.30, 0.62))], S)
    # labe din fata (drepte) + labe
    for sg in (-1, 1):
        b.box(P(sg * 0.12, 0.17, 0.27), (0.12 * s, 0.13 * s, 0.54 * s), S, rotation=rot)
        b.box(P(sg * 0.12, 0.26, 0.04), (0.14 * s, 0.26 * s, 0.08 * s), S, rotation=rot)
    # gat + coama (disc octogonal) + bot
    hull(b, [P(sg * 0.14, w, z) for sg in (-1, 1) for (w, z) in ((0.04, 0.70), (0.20, 0.74), (0.10, 0.98))], S)
    disc = []
    for k in range(8):
        a = 2.0 * math.pi * (k + 0.5) / 8
        for w in (0.02, 0.26):
            disc.append(P(0.34 * math.cos(a), w, 0.98 + 0.34 * math.sin(a)))
    hull(b, disc, S)
    # bot (cutie scurta) + nas + sprancene (bara) -- forme mari, putin adanci
    b.box(P(0.0, 0.34, 0.90), (0.22 * s, 0.16 * s, 0.14 * s), S, rotation=rot)
    b.box(P(0.0, 0.41, 0.95), (0.12 * s, 0.05 * s, 0.07 * s), S, rotation=rot)
    b.box(P(0.0, 0.31, 1.07), (0.34 * s, 0.07 * s, 0.05 * s), S, rotation=rot)
    # coada pe spate
    b.box(P(0.0, -0.44, 0.26), (0.07 * s, 0.07 * s, 0.34 * s), S, rotation=rot)


def naga_fan(b, cx, cy, z0, yaw, s=1.0):
    """Capat de naga mic: evantai de cinci glugi (cobra) pe butuc scurt, cu fata spre `yaw`.
    Vocabularul lui `naga_head` la scara mica: placa de evantai + capete-bloc cu pana + ochi."""
    fr = Frame((cx, cy, 0.0), yaw)
    rot = fr.rot

    def P(u, w, z):
        return fr.p(u * s, w * s, z0 + z * s)

    b.frustum(P(0.0, 0.0, 0.10), 0.20 * s, 0.15 * s, 0.20 * s, S, segments=10)          # butuc
    hull(b, [P(u, w, z) for (u, w, z) in
             ((-0.30, 0.0, 0.18), (0.30, 0.0, 0.18), (-0.34, 0.06, 0.5), (0.34, 0.06, 0.5),
              (-0.20, 0.05, 0.78), (0.20, 0.05, 0.78))], S)                            # placa
    for k in range(5):
        ang = math.radians((k - 2) * 30.0)
        u, h = 0.22 * math.sin(ang) * 1.5, 0.80 + 0.12 * math.cos(ang)
        w0 = 0.08 + 0.04 * math.cos(ang)
        # gluga: pana lata cu varful in sus
        hull(b, [P(u - 0.11, w0, h - 0.30), P(u + 0.11, w0, h - 0.30), P(u - 0.07, w0 + 0.10, h - 0.06),
                 P(u + 0.07, w0 + 0.10, h - 0.06), P(u, w0 + 0.04, h + 0.10), P(u, w0 - 0.02, h + 0.04)], S)
        for sg in (-1, 1):
            b.box(P(u + sg * 0.035, w0 + 0.115, h - 0.10), (0.03 * s, 0.025 * s, 0.03 * s), S, rotation=rot)


def build_landing():
    lt, st, li = Builder(), Builder(), Builder()
    rnd = lcg(137)

    # --- corpul: platforma + aripi (coboara pana la L_BOT) ---
    def body(x0, x1, y0, y1, ztop=0.0):
        lt.box(((x0 + x1) / 2, (y0 + y1) / 2, (ztop + L_BOT) / 2), (x1 - x0, y1 - y0, ztop - L_BOT), LAT)

    body(-7.0 + 0.04, 7.0 - 0.04, -1.0, 4.0 - 0.04)
    body(-7.0 + 0.04, -L_WING_X, -4.0 + 0.04, -1.0)
    body(L_WING_X, 7.0 - 0.04, -4.0 + 0.04, -1.0)
    # fete cu blocuri: spate, laturi, fronturile aripilor, fetele dinspre scara
    face_blocks(lt, 0.0, 4.0 - 0.04, 0, 14.0, L_BOT + 0.1, 0.0, 3, 1.6, seed=1)
    for sx, yaw in ((1, -90), (-1, 90)):
        face_blocks(lt, sx * (7.0 - 0.04), 0.0, yaw, 8.0, L_BOT + 0.1, 0.0, 3, 1.5, seed=2 + sx)
        face_blocks(lt, sx * 5.0, -4.0 + 0.04, 180, 4.0, L_BOT + 0.1, 0.0, 3, 1.4, seed=4 + sx)
        face_blocks(lt, sx * L_WING_X, -2.5, 90 * sx, 3.0, L_BOT + 0.1, 0.0, 3, 1.2, seed=6 + sx)
    # lespezi pe platforma: dale 1,0 x 0,7 ridicate cu 2,5 cm (varful ramane in 0 +- 0,05)
    for yi in range(7):
        y0 = -0.95 + yi * 0.7
        if y0 + 0.65 > 3.95:
            break
        x = -6.9
        idx = 0
        while x < 6.9:
            w = (1.15 if (yi + idx) % 3 else 0.85) + 0.1 * (rnd() - 0.5)
            w = min(w, 6.9 - x)
            if w > 0.15:
                # aripile (x<-3 sau x>3) merg pana la y=-4; platforma centrala doar de la -1
                lt.box((x + w / 2, y0 + 0.325, 0.012), (w - 0.04, 0.65, 0.05), LAT)
            x += w
            idx += 1
    for sx in (-1, 1):
        for yi in range(4):
            y0 = -3.9 + yi * 0.72
            x = L_WING_X + 0.1
            idx = 0
            while x < 6.9:
                w = min((1.2 if (yi + idx) % 2 else 0.9), 6.9 - x)
                if w > 0.15:
                    xc = sx * (x + w / 2)
                    lt.box((xc, y0 + 0.33, 0.012), (w - 0.04, 0.66, 0.05), LAT)
                x += w
                idx += 1

    # --- scara: 6 trepte, fiecare corp pana jos; dala de treapta + blocuri pe contratrepte ---
    sw = 2 * L_WING_X - 0.04
    for i in range(L_STEPS):
        ztop = -L_RISE * (i + 1)
        ya, yb = L_Y_STEP0 - L_TREAD * (i + 1), L_Y_STEP0 - L_TREAD * i
        lt.box((0.0, (ya + yb) / 2, (ztop - 0.04 + L_BOT) / 2), (sw, yb - ya, ztop - 0.04 - L_BOT), LAT)
        lt.box((0.0, (ya + yb) / 2, ztop - 0.02), (sw, yb - ya - 0.03, 0.04), LAT)
        z_lo = -L_RISE * (i + 2) if i < L_STEPS - 1 else L_BOT + 0.1
        face_blocks(lt, 0.0, ya, 180, sw, z_lo, ztop - 0.04, 1, 1.5, proud=0.035, seed=20 + i)

    # --- soclurile leilor (laterita) cu capac de gresie ---
    for sx in (-1, 1):
        px, py = sx * 4.2, -3.05
        ph = 0.90
        lt.box((px, py, ph / 2), (1.86, 1.86, ph), LAT)
        for yaw in (0, 90, 180, -90):
            o = rot_z(yaw) @ Vector((0, 0.93, 0))
            face_blocks(lt, px + o.x, py + o.y, yaw, 1.86, 0.02, ph - 0.02, 3, 0.9,
                        seed=30 + yaw // 90 + (3 if sx > 0 else 0))
        st.box((px, py, ph + 0.05), (2.06, 2.06, 0.10), S)
        lion(st, px, py, ph + 0.10, 180.0, 1.45)
        # --- capul naga de la capat + corpul pe marginea platformei ---
        nx, ny = sx * 6.2, -3.1
        lt.box((nx, ny, 0.30), (1.16, 1.16, 0.60), LAT)
        for yaw in (180, -90 * sx):
            fr = Frame((nx, ny, 0.0), yaw)
            o = rot_z(yaw) @ Vector((0, 0.58, 0))
            face_blocks(lt, nx + o.x, ny + o.y, yaw, 1.16, 0.02, 0.58, 2, 0.6, proud=0.03, seed=40 + sx)
        st.box((nx, ny, 0.63), (1.28, 1.28, 0.06), S)
        naga_fan(st, nx, ny, 0.66, 180.0, 1.5)
        # corp: zid jos + sarpe pe el, de la capat inapoi pe +Y, pana la y = 1,3
        wx = sx * 6.55
        st.box((wx, -0.9, 0.14), (0.40, 4.6, 0.28), S)
        path = []
        for k in range(24):
            t = k / 23.0
            y = -3.1 + 4.5 * t
            path.append(Vector((wx, y, 0.40 + 0.05 * math.sin(2 * math.pi * 1.5 * t))))
        st.sweep(path, 0.12, S, segments=8, dome_end=True, cap_start=True)

    # --- lichen: pete mici pe orizontale (sub 3% din arie), verde + putin portocaliu ---
    spots = [(-5.2, 2.6, 0.04, "g"), (-2.0, 3.3, 0.04, "g"), (1.5, 0.7, 0.04, "g"), (5.0, 2.8, 0.04, "g"),
             (-6.0, -1.2, 0.04, "g"), (3.8, -3.6, 0.04, "g"), (-4.5, -3.4, 0.04, "g"), (6.2, 0.4, 0.04, "o"),
             (-1.2, -1.2, -0.25, "g"), (1.6, -2.2, -0.75, "g"), (-0.8, -3.3, -1.25, "g"),
             (-4.2, -3.05, 1.0, "g"), (4.1, -2.9, 1.0, "g"), (-6.55, -1.5, 0.52, "g"), (6.55, 0.2, 0.52, "o")]
    for (x, y, z, k) in spots:
        ru = 0.12 + 0.12 * rnd()
        lichen_spot(li, (x, y, z), ru, ru * (0.7 + 0.5 * rnd()), 0.025,
                    ANK_LICHEN_GREEN if k == "g" else ANK_LICHEN_ORANGE, yaw_deg=360 * rnd(), seed=int(rnd() * 999))
    return [lt.to_object("Landing_Laterite"), st.to_object("Landing_Stone"), li.to_object("Landing_Lichen")]


# ============================================================================
# 2. TUK-TUK: Moto + Remorca (doua radacini)
# ============================================================================

def wheel(b, x, y, z, r, depth, hub_slot_b=None):
    b.cylinder((x, y, z), r, depth, BLK, segments=14, axis="X")


def build_moto():
    """Motocicleta: 1,9 m lungime (Y 0..1,9), ~0,7 m latime (ghidonul), inainte spre +Y."""
    pa, bk = Builder(), Builder()
    # roti: r = 0,30
    for yc in (0.31, 1.59):
        bk.cylinder((0.0, yc, 0.30), 0.30, 0.10, BLK, segments=14, axis="X")
        pa.cylinder((0.0, yc, 0.30), 0.12, 0.13, PAINT, segments=10, axis="X")
    # cadru: teava principala + motor + rezervor + sa
    pa.beam((0.0, 0.40, 0.42), (0.0, 1.38, 0.84), 0.07, PAINT)
    bk.box((0.0, 0.80, 0.38), (0.20, 0.34, 0.26), BLK)
    hull(pa, [(sg * u, y, z) for sg in (-1, 1) for (u, y, z) in
              ((0.14, 0.92, 0.78), (0.12, 1.32, 0.82), (0.13, 0.92, 1.02), (0.10, 1.30, 1.00))], PAINT)
    hull(bk, [(sg * u, y, z) for sg in (-1, 1) for (u, y, z) in
              ((0.15, 0.22, 0.80), (0.15, 0.90, 0.82), (0.12, 0.22, 0.90), (0.12, 0.90, 0.92))], BLK)
    pa.box((0.0, 0.60, 0.66), (0.16, 0.66, 0.22), PAINT)      # suportul sasiului sub sa
    pa.beam((0.0, 0.31, 0.30), (0.0, 0.40, 0.70), 0.06, PAINT)
    # aparatori: spate (peste roata) si fata
    hull(pa, [(sg * 0.07, y, z) for sg in (-1, 1) for (y, z) in
              ((0.06, 0.52), (0.06, 0.56), (0.30, 0.64), (0.30, 0.68), (0.56, 0.52), (0.56, 0.56))], PAINT)
    hull(pa, [(sg * 0.07, y, z) for sg in (-1, 1) for (y, z) in
              ((1.30, 0.58), (1.30, 0.62), (1.60, 0.64), (1.60, 0.68), (1.88, 0.42), (1.88, 0.46))], PAINT)
    # furca, ghidon, far
    for sg in (-1, 1):
        bk.beam((sg * 0.08, 1.59, 0.30), (sg * 0.07, 1.40, 0.98), 0.045, BLK)
        bk.box((sg * 0.35, 1.38, 1.02), (0.10, 0.05, 0.05), BLK)
    bk.beam((-0.33, 1.38, 1.02), (0.33, 1.38, 1.02), 0.04, BLK)
    pa.frustum((0.0, 1.50, 0.92), 0.10, 0.075, 0.14, PAINT, segments=10, axis="Y")
    # esapament + scarite
    bk.beam((0.15, 1.00, 0.24), (0.17, 0.10, 0.36), 0.07, BLK)
    for sg in (-1, 1):
        bk.box((sg * 0.18, 0.80, 0.30), (0.12, 0.10, 0.04), BLK)
    # carligul de remorca: bara scurta + bila pe la y = 0,0
    bk.beam((0.0, 0.34, 0.40), (0.0, 0.03, 0.40), 0.06, BLK)
    bk.cylinder((0.0, 0.03, 0.43), 0.035, 0.07, BLK, segments=8)
    return {"Paint": pa, "Black": bk}


def build_trailer():
    """Remorca: 1,98 m in plan (Y -1,98..0), 1,42 m latime (cu roti), 1,78 m inaltime cu
    acoperisul. Bara de tractare ajunge la y = 0 (se intalneste cu carligul motocicletei)."""
    pa, rf, wd, bk = Builder(), Builder(), Builder(), Builder()
    y0, y1 = -1.94, -0.56            # corpul (podeaua)
    yc = (y0 + y1) / 2
    ax = -1.45                       # axa rotilor
    # roti + butuc + osie
    for sg in (-1, 1):
        bk.cylinder((sg * 0.64, ax, 0.30), 0.30, 0.12, BLK, segments=14, axis="X")
        pa.cylinder((sg * 0.64, ax, 0.30), 0.11, 0.14, PAINT, segments=10, axis="X")
        hull(pa, [(sg * x, y, z) for x in (0.58, 0.70) for (y, z) in
                  ((ax - 0.34, 0.50), (ax - 0.26, 0.64), (ax + 0.26, 0.64), (ax + 0.34, 0.50))], PAINT)  # aparatoare
    bk.beam((-0.58, ax, 0.30), (0.58, ax, 0.30), 0.06, BLK)
    # sasiu + podea de lemn + parapet jos
    for sg in (-1, 1):
        pa.beam((sg * 0.50, y0, 0.34), (sg * 0.50, y1 + 0.02, 0.34), 0.07, PAINT)
        pa.box((sg * 0.57, yc, 0.49), (0.03, y1 - y0, 0.20), PAINT)
    pa.box((0.0, y0 + 0.015, 0.49), (1.18, 0.03, 0.20), PAINT)
    pa.box((0.0, y1 - 0.015, 0.49), (1.18, 0.03, 0.20), PAINT)
    wd.box((0.0, yc, 0.395), (1.14, y1 - y0, 0.05), WOODW)
    # banci lungi, fata in fata, cu spatar jos
    for sg in (-1, 1):
        wd.box((sg * 0.40, yc, 0.60), (0.27, y1 - y0 - 0.16, 0.36), WOODW)
        wd.box((sg * 0.545, yc, 0.92), (0.05, y1 - y0 - 0.16, 0.30), WOODW)
    # stalpi: 6 (3 perechi) pana sub acoperis
    for yp in (y0 + 0.04, yc, y1 - 0.04):
        for sg in (-1, 1):
            pa.box((sg * 0.57, yp, 1.02), (0.055, 0.055, 1.24), PAINT)
    # grinzi longitudinale sub acoperis
    for sg in (-1, 1):
        pa.beam((sg * 0.57, y0 + 0.02, 1.62), (sg * 0.57, y1 - 0.02, 1.62), 0.05, PAINT)
    # acoperisul: butoi curbat (felii convexe), grosime 0,06, streasina 0,72 jum. latime
    ry0, ry1 = -1.96, -0.50
    n = 8
    xs = [-0.72 + 1.44 * i / n for i in range(n + 1)]

    def zt(x):
        return 1.64 + 0.14 * (1.0 - (x / 0.72) ** 2)

    for xa, xb in zip(xs[:-1], xs[1:]):
        hull(rf, [(x, y, z) for x in (xa, xb) for y in (ry0, ry1) for z in (zt(x), zt(x) - 0.06)], ROOF)
    # bara de tractare: doua brate in A catre carlig (y = 0) + traversa
    for sg in (-1, 1):
        pa.beam((sg * 0.46, y1, 0.37), (sg * 0.02, -0.015, 0.40), 0.05, PAINT)
    pa.beam((0.0, y1, 0.37), (0.0, -0.015, 0.40), 0.05, PAINT)
    pa.box((0.0, -0.30, 0.385), (0.5, 0.04, 0.04), PAINT)
    return {"Paint": pa, "Roof": rf, "Wood": wd, "Black": bk}


def emit_tuk(path="vehicles/tuk_tuk.glb"):
    ao = dict(samples=24, dist=0.35, gradient="vertical", low=0.66, high=1.0, power=0.9,
              floor=0.34, strength=1.2, z_range=(0.0, 1.8))
    roots, all_objs = [], []
    total, per_node, dims_all = 0, {}, []
    for root, groups in (("Moto", build_moto()), ("Remorca", build_trailer())):
        meshes = [bld.to_object("%s_%s" % (root, suf)) for suf, bld in groups.items()]
        xs = [v.co.x for o in meshes for v in o.data.vertices]
        ys = [v.co.y for o in meshes for v in o.data.vertices]
        cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
        for o in meshes:
            for v in o.data.vertices:
                v.co.x -= cx
                v.co.y -= cy
            st = finish(o, bevel=0.008, bevel_angle=30.0, ao=ao, origin=None, smooth_angle=50.0)
            total += st["tris"]
            per_node[o.name] = st["tris"]
        e = bpy.data.objects.new(root, None)
        bpy.context.collection.objects.link(e)
        e.location = (cx, cy, 0.0)
        for o in meshes:
            o.parent = e
        bpy.context.view_layer.update()
        roots.append(e)
        all_objs += meshes
        zs = [v.co.z for o in meshes for v in o.data.vertices]
        xs = [v.co.x for o in meshes for v in o.data.vertices]
        ys = [v.co.y for o in meshes for v in o.data.vertices]
        print("   %s: %.3f x %.3f x %.3f  (centru y %.3f)" % (root, max(xs) - min(xs), max(ys) - min(ys),
                                                              max(zs) - min(zs), cy))
        dims_all.append((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(roots + all_objs, "angkor/" + path)
    d = Vector((max(a[0] for a in dims_all), sum(a[1] for a in dims_all), max(a[2] for a in dims_all)))
    ANK_RESULTS.append((path, total, d, per_node, sz / 1024.0))
    clear_built()
    for e in roots:
        bpy.data.objects.remove(e, do_unlink=True)


# ============================================================================
# 3. CALUGARUL
# ============================================================================

def build_monk():
    rb, sk = Builder(), Builder()
    rot0 = Matrix.Identity(3)
    # picioare goale
    for sg in (-1, 1):
        sk.box((sg * 0.075, 0.06, 0.03), (0.09, 0.22, 0.06), SKIN)
    # sarong: poale lungi, usor evazate la tiv
    hem = [ring(0.205, 0.155, 0.06), ring(0.195, 0.145, 0.22), ring(0.185, 0.135, 0.98)]
    for lo, hi in zip(hem[:-1], hem[1:]):
        hull(rb, lo + hi, ROBE)
    # cuta de fata a sarongului
    rb.box((0.0, 0.158, 0.48), (0.07, 0.03, 0.80), ROBE)
    # trunchi: roba pe stanga, umarul drept gol (piele), banda diagonala peste piept
    hull(sk, ring(0.185, 0.115, 0.96) + ring(0.225, 0.12, 1.40), SKIN)
    hull(rb, [Vector((x, y, z)) for (x, z) in ((-0.235, 1.43), (-0.02, 1.43), (-0.20, 1.00), (0.0, 1.00))
              for y in (-0.125, 0.135)], ROBE)
    hull(rb, [Vector((x, y, z)) for (x, z) in ((-0.225, 1.43), (-0.03, 1.43), (0.20, 1.00), (0.03, 1.00))
              for y in (0.105, 0.14)], ROBE)
    hull(rb, ring(0.19, 0.125, 0.94) + ring(0.195, 0.13, 1.02), ROBE)    # cingatoare
    # brate: stang in roba (maneca), drept gol; maini simple
    rb.beam((-0.235, 0.0, 1.38), (-0.255, 0.04, 0.90), (0.095, 0.095), ROBE)
    ellipsoid(rb, (-0.235, 0.0, 1.37), (0.075, 0.07, 0.07), ROBE, rot0, 8, 5)
    sk.beam((0.235, 0.0, 1.38), (0.255, 0.04, 0.90), (0.075, 0.075), SKIN)
    ellipsoid(sk, (0.235, 0.0, 1.37), (0.065, 0.065, 0.065), SKIN, rot0, 8, 5)
    sk.box((-0.258, 0.045, 0.85), (0.07, 0.05, 0.12), SKIN)
    sk.box((0.258, 0.045, 0.85), (0.07, 0.05, 0.12), SKIN)
    # gat + cap ras (elipsoid) + urechi + nas
    sk.cylinder((0.0, 0.0, 1.45), 0.05, 0.14, SKIN, segments=8)
    ellipsoid(sk, (0.0, 0.01, 1.585), (0.085, 0.100, 0.115), SKIN, rot0, 10, 7)
    for sg in (-1, 1):
        ellipsoid(sk, (sg * 0.088, 0.0, 1.575), (0.015, 0.03, 0.04), SKIN, rot0, 6, 4)
    hull(sk, [Vector(p) for p in ((-0.016, 0.085, 1.60), (0.016, 0.085, 1.60), (-0.02, 0.095, 1.55),
                                   (0.02, 0.095, 1.55), (0.0, 0.123, 1.545))], SKIN)
    return [rb.to_object("Monk_Robe"), sk.to_object("Monk_Skin")]


# ============================================================================
# 4. BLOCUL DE LATERITA (porii = cavitati reale + AO)
# ============================================================================

def build_laterite_block():
    b = Builder()
    sx, sy, sz = 1.0, 0.60, 0.52
    res = bmesh.ops.create_cube(b.bm, size=1.0, matrix=Matrix.Diagonal(Vector((sx, sy, sz, 1.0))))
    bmesh.ops.subdivide_edges(b.bm, edges=list(b.bm.edges), cuts=27, use_grid_fill=True)
    rnd = lcg(211)
    # cavitatile: (axa fetei, centrul pe fata, raza, adancime)
    pits = []
    faces = [((0, 0, 1), (sx, sy)), ((0, 0, -1), (sx, sy)), ((1, 0, 0), (sy, sz)), ((-1, 0, 0), (sy, sz)),
             ((0, 1, 0), (sx, sz)), ((0, -1, 0), (sx, sz))]
    for n, (wa, wb) in faces:
        count = 17 if abs(n[1]) == 1 or abs(n[0]) == 1 else 11
        for _ in range(count):
            ua, ub = (rnd() - 0.5) * (wa - 0.12), (rnd() - 0.5) * (wb - 0.12)
            r = 0.035 + 0.03 * rnd()
            d = 0.03 + 0.04 * rnd()
            nv = Vector(n)
            # punct pe fata
            if n[2] != 0:
                c = Vector((ua, ub, n[2] * sz / 2))
            elif n[0] != 0:
                c = Vector((n[0] * sx / 2, ua, ub))
            else:
                c = Vector((ua, n[1] * sy / 2, ub))
            pits.append((nv, c, r, d))
    for v in b.bm.verts:
        disp = Vector((0.0, 0.0, 0.0))
        for (nv, c, r, d) in pits:
            rel = v.co - c
            if abs(rel.dot(nv)) > 0.012:
                continue
            dist = (rel - nv * rel.dot(nv)).length
            if dist < r:
                t = min(1.0, 2.2 * (1.0 - (dist / r) ** 2))
                disp -= nv * d * t
        v.co += disp
    b.bm.verts.ensure_lookup_table()
    bmesh.ops.recalc_face_normals(b.bm, faces=b.bm.faces[:])
    for f in b.bm.faces:
        f[b.slot] = LAT
    return [b.to_object("Block_Laterite")]


# ============================================================================
# 5. MOLOZUL
# ============================================================================

def rough_block(b, center, size, yaw, tilt=(0.0, 0.0), jitter=0.16, slot=S, seed=0):
    """Bloc de gresie cu fatete mari: cutia cu cele opt colturi mutate (+-jitter), rotita."""
    rnd = lcg(seed + 300)
    m = rot_e(tilt[0], tilt[1], yaw)
    pts = []
    for ix in (-1, 1):
        for iy in (-1, 1):
            for iz in (-1, 1):
                p = Vector((ix * size[0] / 2 * (1 - jitter * rnd()), iy * size[1] / 2 * (1 - jitter * rnd()),
                            iz * size[2] / 2 * (1 - jitter * 0.8 * rnd())))
                pts.append(Vector(center) + m @ p)
    hull(b, pts, slot)
    return Vector(center) + m @ Vector((0, 0, size[2] / 2))


def build_rubble():
    st, li = Builder(), Builder()
    rnd = lcg(317)
    spec = [  # centru, marime, yaw, tilt
        ((-0.50, 0.05, 0.22), (0.85, 0.65, 0.46), 20, (0, 0)),
        ((0.45, -0.25, 0.20), (0.80, 0.60, 0.42), -25, (0, 0)),
        ((0.50, 0.55, 0.18), (0.60, 0.50, 0.38), 50, (0, 0)),
        ((-0.30, -0.62, 0.15), (0.60, 0.45, 0.32), -10, (0, 0)),
        ((-0.12, 0.58, 0.20), (0.55, 0.50, 0.42), 70, (0, 0)),
        ((-0.98, -0.22, 0.13), (0.50, 0.40, 0.27), 35, (0, 0)),
        ((0.92, 0.10, 0.12), (0.45, 0.40, 0.25), 15, (0, 0)),
        ((-0.18, 0.00, 0.62), (0.72, 0.56, 0.44), 35, (7, -5)),
        ((0.40, 0.22, 0.58), (0.56, 0.50, 0.42), -40, (-6, 5)),
        ((0.03, 0.12, 0.93), (0.50, 0.45, 0.38), 10, (5, 8)),
    ]
    tops = []
    for i, (c, s_, yaw, tl) in enumerate(spec):
        tops.append(rough_block(st, c, s_, yaw, tl, seed=i))
    # fragmente cioplite: un tambur de coloana cu trei inele culcat, un buiandrug cu creasta
    # de lotusi, un fragment de cornisa cu doua canelurii
    d0 = Vector((0.80, -0.68, 0.20))
    st.cylinder(d0, 0.20, 0.52, S, segments=12, axis="X")
    for dx in (-0.20, 0.0, 0.20):
        st.cylinder(d0 + Vector((dx, 0, 0)), 0.225, 0.07, S, segments=12, axis="X")
    rot = rot_z(25)
    st.box((-0.86, 0.62, 0.15), (0.80, 0.30, 0.30), S, rotation=rot)
    for k in range(4):
        o = rot @ Vector((-0.27 + 0.18 * k, 0.0, 0.0))
        st.box((-0.86 + o.x, 0.62 + o.y, 0.34), (0.12, 0.20, 0.10), S, rotation=rot)
        st.box((-0.86 + o.x, 0.62 + o.y, 0.41), (0.06, 0.12, 0.06), S, rotation=rot)
    st.box((0.05, -0.95, 0.09), (0.50, 0.26, 0.18), S, rotation=rot_z(-35))
    for k in range(2):
        o = rot_z(-35) @ Vector((-0.12 + 0.24 * k, 0.0, 0.0))
        st.box((0.05 + o.x, -0.95 + o.y, 0.19), (0.07, 0.30, 0.04), S, rotation=rot_z(-35))
    st.box((1.12, 0.62, 0.07), (0.26, 0.20, 0.14), S, rotation=rot_z(40))
    st.box((-1.25, -0.6, 0.06), (0.20, 0.16, 0.12), S, rotation=rot_z(-20))
    # lichen pe varfurile blocurilor
    for i in (0, 1, 3, 4, 7, 9):
        t = tops[i]
        ru = 0.09 + 0.07 * rnd()
        lichen_spot(li, (t.x + 0.05 * (rnd() - 0.5), t.y + 0.05 * (rnd() - 0.5), t.z - 0.03), ru,
                    ru * 0.8, 0.02, ANK_LICHEN_GREEN if i != 4 else ANK_LICHEN_ORANGE,
                    yaw_deg=360 * rnd(), seed=i * 7)
    objs = [st.to_object("Rubble_Stone"), li.to_object("Rubble_Lichen")]
    for o in objs:
        for v in o.data.vertices:
            v.co *= 0.80
    return objs


# ============================================================================
# 6. BLOCUL CU CIFRA
# ============================================================================

def build_numbered():
    st, pt, li = Builder(), Builder(), Builder()
    sx, sy, sz = 0.80, 0.56, 0.56
    proud = 0.035
    st.box((0.0, 0.0, sz / 2), (sx - 2 * proud + 0.02, sy - 2 * proud + 0.02, sz), S)
    for yaw, wdt, d in ((0, sx, sy / 2), (180, sx, sy / 2), (90, sy, sx / 2), (-90, sy, sx / 2)):
        o = rot_z(yaw) @ Vector((0, d - proud, 0))
        face_blocks(st, o.x, o.y, yaw, wdt - 2 * proud, 0.0, sz, 2, wdt / 2 - proud, proud=proud, seed=60 + yaw)
    # blocurile se opresc si pe capac: placa de sus (cu rosturi)
    st.box((0.0, 0.0, sz + 0.004), (sx - 2 * proud, sy - 2 * proud, 0.012), S)
    # cifra 7 (raised 3 cm), centrata pe fata +Y (fata bogata), jumatatea de sus a blocului
    # +Y vazut din fata: +X e in STANGA privitorului, deci conturul lui `7` e oglindit pe X
    outline = [(0.15, 0.22), (0.15, 0.15), (-0.06, 0.15), (0.095, -0.22), (0.0, -0.22),
               (-0.15, 0.15), (-0.15, 0.22)]
    pt.prism(outline, 0.04, DIGIT, center=(0.0, sy / 2 + 0.01, sz * 0.5 + 0.0))
    # lichen la baza fetei si pe varf, discret
    rnd = lcg(71)
    for (x, y, z) in ((-0.25, -0.1, sz + 0.012), (0.28, 0.12, sz + 0.012), (0.05, 0.2, sz + 0.012)):
        lichen_spot(li, (x, y, z), 0.07 + 0.04 * rnd(), 0.06, 0.008, ANK_LICHEN_GREEN, yaw_deg=360 * rnd(), seed=int(rnd() * 99))
    return [st.to_object("Block_Stone"), pt.to_object("Block_Paint"), li.to_object("Block_Lichen")]


# ============================================================================

if want("landing"):
    ao = dict(samples=24, dist=0.8, gradient="vertical", low=0.58, high=1.0, power=0.85,
              floor=0.30, strength=1.3, z_range=(-1.75, 3.0))
    emit_at(build_landing(), "structures/srah_srang_landing.glb", ao, place=(0.0, 0.0, 0.0),
            bevels={"_Lichen": 0.0}, bevel=0.015)
if want("tuk"):
    emit_tuk()
if want("monk"):
    ao = dict(samples=24, dist=0.25, gradient="vertical", low=0.70, high=1.0, power=0.9,
              floor=0.35, strength=1.1, z_range=(0.0, 1.7))
    emit_angkor(build_monk(), "animals/monk_standing.glb", ao, bevel=0.0, smooth_angle=55.0)
    clear_built()
if want("laterite"):
    ao = dict(samples=32, dist=0.25, gradient="vertical", low=0.78, high=1.0, power=0.9,
              floor=0.12, strength=2.4, z_range=(0.0, 0.6))
    emit_angkor(build_laterite_block(), "props/laterite_block.glb", ao, bevel=0.0, smooth_angle=60.0)
    clear_built()
if want("rubble"):
    ao = dict(samples=24, dist=0.5, gradient="vertical", low=0.62, high=1.0, power=0.85,
              floor=0.30, strength=1.3, z_range=(0.0, 1.1))
    emit_angkor(build_rubble(), "props/rubble_pile.glb", ao, bevel=0.0, bevels={"_Lichen": 0.0}, smooth_angle=None)
    clear_built()
if want("numbered"):
    ao = dict(samples=24, dist=0.3, gradient="vertical", low=0.70, high=1.0, power=0.9,
              floor=0.32, strength=1.2, z_range=(0.0, 0.6))
    emit_angkor(build_numbered(), "props/numbered_block.glb", ao, bevel=0.006, bevels={"_Lichen": 0.0, "_Paint": 0.0},
                smooth_angle=40.0)
    clear_built()
report_angkor()
