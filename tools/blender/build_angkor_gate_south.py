"""Angkor -- Poarta de Sud, turnul cu fete (brief docs/asset_briefs/angkor_kit.md §1.2).

  angkor/structures/south_gate_face_tower.glb   (val 1)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_gate_south.py

Axe: X latime (19 m), Y adancime (8 m; drumul merge pe Y prin poarta), Z sus. Fata
bogata pe +Y (= -Z in Godot). Originea: baza, la mijlocul golului (offset calculat o
singura data pe ansamblu in `emit_angkor`).

LISTA DE ELEMENTE (decuparea `south_gate_face_tower.png`; scrisa INAINTE de geometrie):
  1. DOUA ARIPI de gresie (x 3,75..9,5 si oglinda), cate 5,75 m lat., 3,5 m jumatate-
     adancime, 0..9,6 m inaltime, in randuri de blocuri in relief pe toti peretii;
     la picior un soclu scund (0,4 m) cu jumatate-adancime 4,0 m. Peretele dinspre gol
     (juga) e plan, la |x| = 3,75 m: NIMIC din el nu intra in ±3,6 m.
  2. UN SINGUR GOL: latime libera 7,5 m (cerinta >= 7,2 m), inaltime libera 8,4 m
     (cerinta >= 8 m), PE TOATA adancimea de 7 m. Fara capiteluri, fara praguri, fara
     placi pe jos: drumul e al pistei. Buiandrugul (8,4..9,6 m) leaga aripile.
  3. Rama in trepte a golului (arcul in trepte, ca RELIEF pe fetele +Y/-Y): doua
     pilastri-trepte pe fiecare latura, doua grinzi-trepte deasupra buiandrugului,
     toate la |x| >= 3,75 sau la z >= 8,4: tot in afara golului.
  4. ELEFANTI in relief pe fata exterioara a aripilor (+Y si -Y, 4 in total), siluete
     blocate (corp, cap, ureche, trompa pana la sol, picioare, colti, coada), ridicati
     0,42 m din perete, cu fata spre exterior, NICIODATA in gol.
  5. Cornisa (9,6..10,0 m) pe toata latimea; bucati de parapet cazute pe aripi.
  6. TURNUL peste gol (10,0 m in sus): fus cu blocuri (10,0..11,4), cornisa gatului,
     blocul fetelor cu PATRU FETE simplificate (runda 6) la H = 4,6 m (11,8..17,3 m),
     capac, 4 etaje care se ingusteaza, boboc de lotus; varful la ~22 m.
  7. Culori (kit §0): gresie ROCK_LIGHT 3 in `Gate_Stone`; lichen portocaliu LAVA_ORANGE
     30 si verde CACTUS_GREEN 12 in `Gate_Lichen` (sub 3% din arie); dare VOLCANIC_BLACK
     20 in `Gate_Streak`. AO copt in vertex colors. Fara texturi proprii, fara urna.
  8. Segmente: boboc 14, finial 8; restul cutii/invelitori convexe.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

# --- cotele (m) ---------------------------------------------------------------------
JAMB = 3.75             # |x| al jugii: golul liber = 2 * JAMB = 7,5 m
X_OUT = 9.5             # capatul aripii: latime totala 19,0
WALL_Y = 3.5            # fata peretilor aripii (jumatate-adancime)
PLINTH_Y = 3.6         # soclul iese 0,1 m din perete (nu e prag pentru masini)          # soclul: adancime totala 8,0
Z_PLINTH = 0.4
Z_UNDER = 8.4           # fata de jos a buiandrugului = inaltimea libera
Z_WALL = 9.6
Z_BODY = 10.0           # sus pe cornisa
PROUD = 0.04
ELE_H = 1.1             # elefantul: ~4,1 m lung, ~3,3 m la crestet
# aripile in trepte: (x interior, x exterior, cota de sus a cornisei)
SECTIONS = [(JAMB, 5.25, 10.0), (5.25, 7.4, 7.6), (7.4, X_OUT, 5.0)]

# turnul (scalat din cel al Bayonului: H 3,0 -> 4,6)
FACE_H = 6.0
HX_FACE, HY_FACE = 3.9, 3.0          # blocul fetelor: 7,8 x 6,0 m in plan (fetele +-Y pe latura de 7,8)
BASE1 = (Z_BODY, 10.8, 5.25, 3.4)    # baza turnului: (z0, z1, jum. X, jum. Y), pe juge si aripa interioara
BASE2 = (10.8, 11.4, 4.55, 3.2)
Z_CHIN = 11.4
Z_FACE_TOP = Z_CHIN + 1.2 * FACE_H            # 18,6
TIERS = [(0.60, 2.70, 0.08), (0.56, 2.20, 0.08), (0.52, 1.70, 0.08), (0.46, 1.20, 0.08)]
LOTUS_R = 0.70
TOP_Z = 22.7

AO_GATE = dict(samples=28, dist=1.1, gradient="vertical", low=0.60, high=1.0,
               power=0.85, floor=0.30, strength=1.35, z_range=(0.0, TOP_Z))


def wall_blocks(b, fr, u0, u1, z0, z1, courses, bw, proud=PROUD, gap=0.035, seed=0):
    """Blocuri in relief pe un perete plan: `fr` are originea pe fata peretelui (w = 0 e
    fata, w < 0 in perete), u de-a lungul fetei intre u0 si u1. Ca `block_courses`,
    pentru pereti dreptunghiulari."""
    rnd = lcg(seed + 31)
    ch = (z1 - z0) / courses
    L = u1 - u0
    n = max(2, int(round(L / bw)))
    rot = fr.rot
    for c in range(courses):
        za, zb = z0 + c * ch + gap * 0.5, z0 + (c + 1) * ch - gap * 0.5
        edges = [u0 + L * i / n for i in range(n + 1)]
        if c % 2:
            edges = [u0] + [e + L / (2 * n) for e in edges[:-1]] + [u1]
        edges = [e + (rnd() - 0.5) * 0.12 * bw if 0 < i < len(edges) - 1 else e
                 for i, e in enumerate(edges)]
        for ua, ub in zip(edges[:-1], edges[1:]):
            if ub - ua < 0.1:
                continue
            ua, ub = ua + gap * 0.5, ub - gap * 0.5
            ctr = fr.p((ua + ub) * 0.5, -proud * 0.5 - 0.005, (za + zb) * 0.5)
            b.box(ctr, (ub - ua, proud + 0.01, zb - za), ANK_STONE, rotation=rot)


def rect_box(b, x0, x1, y0, y1, z0, z1):
    b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), (x1 - x0, y1 - y0, z1 - z0), ANK_STONE)


def rect_tower(b, z0, z1, hx, hy, courses, bw, seed=0):
    """Corp dreptunghiular (hx x hy) cu blocuri in relief pe cele patru fete."""
    rect_box(b, -hx + PROUD, hx - PROUD, -hy + PROUD, hy - PROUD, z0, z1)
    wall_blocks(b, Frame((0, hy, 0), 0.0), -hx, hx, z0, z1, courses, bw, seed=seed)
    wall_blocks(b, Frame((0, -hy, 0), 180.0), -hx, hx, z0, z1, courses, bw, seed=seed + 1)
    wall_blocks(b, Frame((hx, 0, 0), 270.0), -hy, hy, z0, z1, courses, bw, seed=seed + 2)
    wall_blocks(b, Frame((-hx, 0, 0), 90.0), -hy, hy, z0, z1, courses, bw, seed=seed + 3)


# --- elefantul in relief ------------------------------------------------------------
def elephant(b, fr, dirn, h=1.0):
    """Siluta blocata a unui elefant in relief, in cadrul `fr` (origine pe fata
    peretelui, la talpa; u de-a lungul fetei, w in afara). `dirn` = +1 sau -1: sensul lui
    u in care priveste elefantul. Coordonate locale (s inainte, t sus, w afara) in m;
    inaltime ~3,0 m la crestet, trompa pana la t = 0, relief maxim 0,42 m."""
    def P(s, t, w):
        return fr.p(dirn * s * h, w, t * h)

    def hl(pts):
        hull(b, [P(*q) for q in pts], ANK_STONE)

    # corp: bloc cu spatele rotunjit (invelitoare)
    hl([(-1.40, 1.20, 0.0), (-1.40, 1.20, 0.26), (-1.40, 2.25, 0.0), (-1.40, 2.25, 0.26),
        (0.95, 1.20, 0.0), (0.95, 1.20, 0.26), (0.95, 2.30, 0.0), (0.95, 2.30, 0.26),
        (-1.10, 2.50, 0.0), (-1.10, 2.50, 0.30), (0.55, 2.55, 0.0), (0.55, 2.55, 0.32),
        (-0.30, 2.65, 0.0), (-0.30, 2.65, 0.34),
        (-1.20, 1.80, 0.40), (0.80, 1.80, 0.40), (-0.2, 2.40, 0.40), (-0.2, 1.4, 0.38)])
    # picioare: doua in fata (mai ridicate), doua in spate (mai putin), blocuri
    for (s0, s1, wv) in ((0.45, 0.95, 0.34), (-0.05, 0.38, 0.22), (-0.90, -0.50, 0.22), (-1.40, -0.92, 0.34)):
        hl([(s0, 0.0, 0.0), (s0, 0.0, wv), (s1, 0.0, 0.0), (s1, 0.0, wv),
            (s0, 1.30, 0.0), (s0, 1.30, wv), (s1, 1.30, 0.0), (s1, 1.30, wv)])
    # cap: doua boltiri (frunte), maxilar mai ingust
    hl([(0.78, 1.55, 0.0), (0.78, 2.95, 0.0), (1.70, 1.55, 0.0), (1.62, 2.65, 0.0),
        (0.90, 2.62, 0.40), (1.30, 2.95, 0.34), (1.62, 2.25, 0.30), (1.00, 1.75, 0.34),
        (0.92, 2.95, 0.30)])
    # ureche: romb rotunjit, ridicat peste cap
    hl([(0.52, 2.15, 0.30), (0.78, 2.70, 0.30), (1.06, 2.15, 0.30), (0.78, 1.55, 0.30),
        (0.64, 2.15, 0.44), (0.78, 2.50, 0.44), (0.96, 2.15, 0.44), (0.78, 1.72, 0.44)])
    # trompa: lant de segmente pana la sol (t = 0)
    chain = [(1.64, 2.15, 0.34, 0.54), (1.82, 1.55, 0.31, 0.46), (1.95, 0.90, 0.28, 0.38),
             (2.00, 0.30, 0.25, 0.30), (2.02, 0.0, 0.22, 0.24)]
    for (sa, ta, wa, la), (sb, tb, wb, lb) in zip(chain[:-1], chain[1:]):
        hl([(sa - la * 0.5, ta, 0.0), (sa + la * 0.5, ta, 0.0), (sa - la * 0.5, ta, wa), (sa + la * 0.5, ta, wa),
            (sb - lb * 0.5, tb, 0.0), (sb + lb * 0.5, tb, 0.0), (sb - lb * 0.5, tb, wb), (sb + lb * 0.5, tb, wb)])
    # colt scurt, curbat
    hl([(1.40, 1.75, 0.28), (1.52, 1.78, 0.34), (2.02, 1.38, 0.30), (2.08, 1.32, 0.34),
        (1.40, 1.68, 0.34), (1.95, 1.30, 0.28)])
    # coada
    hl([(-1.40, 2.25, 0.0), (-1.46, 2.25, 0.10), (-1.58, 1.50, 0.0), (-1.62, 1.50, 0.08),
        (-1.40, 2.15, 0.10)])


def build_gate():
    stone, lichen, streaks = Builder(), Builder(), Builder()
    rnd = lcg(53)
    sites = []          # (z, cx, cy, hx, hy)  suprafete orizontale pentru lichen
    streak_sites = []   # (Frame pe fata, u0, u1, z_sus, n)

    # --- 1-2. aripile in TREPTE (inalte langa gol, coboara spre exterior), socluri -------------
    for sx in (1, -1):
        rect_box(stone, min(sx * JAMB, sx * X_OUT), max(sx * JAMB, sx * X_OUT), -PLINTH_Y, PLINTH_Y, 0.0, Z_PLINTH)
        for i, (xa, xb, zt) in enumerate(SECTIONS):
            last = i == len(SECTIONS) - 1
            zw = zt - 0.4
            cr = max(2, int(round((zw - Z_PLINTH) / 1.05)))
            ca = xa + (PROUD if i == 0 else 0.0)
            cb = xb - (PROUD if last else 0.0)
            rect_box(stone, min(sx * ca, sx * cb), max(sx * ca, sx * cb), -WALL_Y + PROUD, WALL_Y - PROUD,
                     Z_PLINTH, zw - 0.02)
            if sx == 1:
                f_front = (Frame((0, WALL_Y, 0), 0.0), xa, xb)
                f_back = (Frame((0, -WALL_Y, 0), 180.0), -xb, -xa)
            else:
                f_front = (Frame((0, WALL_Y, 0), 0.0), -xb, -xa)
                f_back = (Frame((0, -WALL_Y, 0), 180.0), xa, xb)
            wall_blocks(stone, f_front[0], f_front[1], f_front[2], Z_PLINTH, zw, cr, 1.15, seed=1 + sx + i)
            wall_blocks(stone, f_back[0], f_back[1], f_back[2], Z_PLINTH, zw, cr, 1.15, seed=3 + sx + i)
            if i == 0:   # juga: plana, la |x| = JAMB, pana la buiandrug
                fj = Frame((sx * JAMB, 0, 0), 90.0 if sx == 1 else 270.0)
                wall_blocks(stone, fj, -WALL_Y, WALL_Y, Z_PLINTH, Z_UNDER, 8, 1.2, seed=7 + sx)
            if last:     # capatul exterior
                fo = Frame((sx * X_OUT, 0, 0), 270.0 if sx == 1 else 90.0)
                wall_blocks(stone, fo, -WALL_Y, WALL_Y, Z_PLINTH, zw, cr, 1.2, seed=5 + sx)
            else:        # fata treptei, spre exterior, intre cornisa de dedesubt si a ei
                zn = SECTIONS[i + 1][2]
                if zw - zn > 0.3:
                    fs = Frame((sx * (xb + PROUD), 0, 0), 270.0 if sx == 1 else 90.0)
                    wall_blocks(stone, fs, -WALL_Y, WALL_Y, zn, zw, max(1, int(round((zw - zn) / 1.05))), 1.2, seed=11 + i)
            # cornisa treptei + bucati de parapet cazute
            rect_box(stone, min(sx * xa, sx * xb), max(sx * xa, sx * xb), -3.8, 3.8, zw, zt)
            sites.append((zt, sx * (xa + xb) * 0.5, 0.0, (xb - xa) * 0.5, 3.5))
            for _ in range(3 if i < 2 else 2):
                x = sx * (xa + 0.9 + (xb - xa - 1.8) * rnd())
                y = (rnd() * 2 - 1) * 2.7
                sz = (0.8 + 0.5 * rnd(), 0.8 + 0.5 * rnd(), 0.4 + 0.6 * rnd())
                rot = Matrix.Rotation(math.radians((rnd() - 0.5) * 26), 3, "Z")
                stone.box((x, y, zt + sz[2] * 0.5 - 0.02), sz, ANK_STONE, rotation=rot)
        # elefanti (x1,2): pe +Y si -Y, fata spre exterior; silueta s in [-1,62 .. 2,08] * ELE_H
        x0 = sx * (7.15 - 0.255)
        elephant(stone, Frame((x0, WALL_Y, 0.0), 0.0), sx, ELE_H)
        elephant(stone, Frame((x0, -WALL_Y, 0.0), 180.0), -sx, ELE_H)

    # --- 3. rama in trepte (relief), numai in afara golului ------------------------------
    for fy, outward in ((WALL_Y, 1), (-WALL_Y, -1)):
        def ybox(x0, x1, pr, z0, z1):
            if outward > 0:
                rect_box(stone, x0, x1, fy - 0.02, fy + pr, z0, z1)
            else:
                rect_box(stone, x0, x1, fy - pr, fy + 0.02, z0, z1)
        # trei trepte de pilastri (relief 0,10 / 0,22 / 0,34 m), de la sol; toate la |x| >= JAMB
        for sx in (1, -1):
            for wd, pr, zt in ((1.00, 0.10, 8.9), (0.65, 0.22, 8.7), (0.30, 0.34, 8.5)):
                xa, xb = sorted((sx * JAMB, sx * (JAMB + wd)))
                ybox(xa, xb, pr, 0.0, zt)
        # grinzi in trepte deasupra golului, cu fata de jos la Z_UNDER sau mai sus
        for wd, pr, zt in ((1.00, 0.10, 9.0), (0.65, 0.22, 8.8), (0.30, 0.34, 8.6)):
            ybox(-(JAMB + wd), JAMB + wd, pr, Z_UNDER, zt)
        # console: bucati in trepte pe cornisa, doar in afara golului
        for sx in (1, -1):
            for wd, pr, z0_, zt in ((1.15, 0.16, 9.0, 9.3), (0.80, 0.28, 9.0, 9.2)):
                xa, xb = sorted((sx * JAMB, sx * (JAMB + wd)))
                ybox(xa, xb, pr, z0_, zt)

    # --- buiandrugul + cornisa + parapet --------------------------------------------------
    rect_box(stone, -JAMB - 0.04, JAMB + 0.04, -WALL_Y + PROUD, WALL_Y - PROUD, Z_UNDER, Z_WALL - 0.02)
    wall_blocks(stone, Frame((0, WALL_Y, 0), 0.0), -JAMB, JAMB, Z_UNDER + 0.8, Z_WALL, 1, 2.5, seed=21)
    wall_blocks(stone, Frame((0, -WALL_Y, 0), 180.0), -JAMB, JAMB, Z_UNDER + 0.8, Z_WALL, 1, 2.5, seed=22)
    rect_box(stone, -JAMB, JAMB, -3.8, 3.8, Z_WALL, Z_BODY)
    sites.append((Z_BODY, 0.0, 0.0, JAMB, 3.5))

    # --- 6. turnul: baza larga (10,5 m) direct pe juge, blocul fetelor 7,8 x 6,0, etaje, boboc ----
    tower_ledges = []
    for (za, zb, hx, hy) in (BASE1, BASE2):
        rect_tower(stone, za, zb, hx, hy, 1, 1.4, seed=int(za))
        streak_sites.append(("rect", zb, hx, hy, 8))
    rect_box(stone, -HX_FACE, HX_FACE, -HY_FACE, HY_FACE, Z_CHIN, Z_FACE_TOP)
    for k in range(4):
        fr = Frame((0.0, 0.0, 0.0), 90.0 * k)
        face_relief(stone, fr.p(0.0, HY_FACE if k % 2 == 0 else HX_FACE, Z_CHIN), 90.0 * k, FACE_H)
    rect_box(stone, -HX_FACE - 0.05, HX_FACE + 0.05, -HY_FACE - 0.05, HY_FACE + 0.05, Z_FACE_TOP, Z_FACE_TOP + 0.14)
    z = Z_FACE_TOP + 0.14
    tower_ledges.append((z, 2.95, TIERS[0][1] + 0.08))
    n_t = len(TIERS)
    for i, (th, half, ch) in enumerate(TIERS):
        z0 = z
        z = tier(stone, z0, z0 + th, half, ch)
        if i < 2:
            streak_sites.append(("tower", z0 + th, half * 0.96, 4))
        nxt = TIERS[i + 1][1] if i + 1 < n_t else 0.62
        tower_ledges.append((z, half + 0.08, nxt))
    height = TOP_Z - z
    assert height > 1.0, "etajele lasa prea putin pentru boboc: %.2f" % height
    lotus_bud(stone, 0, 0, z, height, LOTUS_R, petals=8, segments=14)

    # --- 7. lichen ----------------------------------------------------------------------------
    n_orange, n_green = 70, 26
    spots = ["o"] * n_orange + ["g"] * n_green
    for i in range(len(spots) - 1, 0, -1):
        j = int(rnd() * (i + 1))
        spots[i], spots[j] = spots[j], spots[i]
    tot_len = sum(l[1] for l in tower_ledges)
    for si, kind in enumerate(spots):
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        sc = 1.8
        if rnd() < 0.45:
            # pe tabla cornisei aripilor (departe de parapet: ramane pe tabla libera)
            side = 1 if rnd() < 0.5 else -1
            xa_, xb_, zt_ = SECTIONS[int(rnd() * len(SECTIONS))]
            x = side * (xa_ + 0.4 + rnd() * (xb_ - xa_ - 0.8))
            y = (rnd() * 2 - 1) * 3.2
            r = 0.14 + 0.16 * rnd()
            lichen_spot(lichen, (x, y, zt_), r * 1.3, r, 0.032, slot, yaw_deg=rnd() * 360.0, seed=si)
        else:
            rr = rnd() * tot_len
            acc = 0.0
            led = tower_ledges[-1]
            for l in tower_ledges:
                acc += l[1]
                if rr <= acc:
                    led = l
                    break
            zs, outer, inner = led
            wid = outer - inner
            if wid < 0.07:
                continue
            side = int(rnd() * 4)
            lim = outer - max(0.15, 0.2 * outer)
            u = (rnd() * 2 - 1) * lim
            rw = min(wid * 0.40, 0.10 + 0.16 * rnd())
            ru = min(0.5, rw * (1.6 + 1.8 * rnd()), lim - abs(u) + 0.02)
            wc = inner + wid * 0.5
            fr = Frame((0, 0, 0), 90.0 * side)
            pt = fr.p(u, wc, zs)
            if kind == "g":
                ru, rw = ru * 1.15, rw * 1.1
            lichen_spot(lichen, (pt.x, pt.y, pt.z), ru, rw, 0.032, slot, yaw_deg=90.0 * side, seed=si)

    # --- 8. dare: sub cornisa aripilor si a gatului turnului --------------------------------------
    for sx in (1, -1):
        for (fy, yaw) in ((WALL_Y, 0.0), (-WALL_Y, 180.0)):
            fr = Frame((0, fy, 0), yaw)
            for (xa_, xb_, zt_) in SECTIONS:
                for _ in range(3):
                    xu = sx * (xa_ + 0.3 + (xb_ - xa_ - 0.6) * rnd())
                    u = xu if yaw == 0.0 else -xu
                    streak(streaks, (fr.p(u, 0.0, 0.0).x, fy, zt_ - 0.42), yaw,
                           0.30 + 0.20 * rnd(), 0.8 + 0.9 * rnd(), 0.03, ANK_STREAK)
    for site in streak_sites:
        if site[0] == "rect":
            _, z_top, hx, hy, n = site
            for k in range(4):
                fr = Frame((0, 0, 0), 90.0 * k)
                hu, hw = (hx, hy) if k % 2 == 0 else (hy, hx)
                for _ in range(n // 4):
                    u = (rnd() * 2 - 1) * hu * 0.8
                    p = fr.p(u, hw, 0.0)
                    streak(streaks, (p.x, p.y, z_top - 0.02), 90.0 * k, 0.30 + 0.18 * rnd(),
                           0.5 + 0.4 * rnd(), 0.03, ANK_STREAK)
            continue
        _, z_top, half, n = site
        for k in range(4):
            fr = Frame((0, 0, 0), 90.0 * k)
            cnt = n // 4 + (1 if k < n % 4 else 0)
            for _ in range(cnt):
                u = (rnd() * 2 - 1) * half * 0.6
                p = fr.p(u, half, 0.0)
                streak(streaks, (p.x, p.y, z_top - 0.02), 90.0 * k, 0.30 + 0.16 * rnd(),
                       0.55 + 0.55 * rnd(), 0.03, ANK_STREAK)

    return [stone.to_object("Gate_Stone"), lichen.to_object("Gate_Lichen"),
            streaks.to_object("Gate_Streak")]


objs = build_gate()
emit_angkor(objs, "structures/south_gate_face_tower.glb", AO_GATE,
            bevel=0.0, bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0)
clear_built()
report_angkor()
