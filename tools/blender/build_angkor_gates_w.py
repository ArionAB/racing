"""Angkor -- val 1, grupul B: porti prin care treci (kit angkor_kit.md §1.2).

  angkor/structures/aw_west_gopura.glb      galerie-poarta Angkor Wat, 52 m, 3 turnuri
  angkor/structures/ta_prohm_tree_gate.glb  poarta mica strans de un ficus urias

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_gates_w.py
`ANK_ONLY=<gopura|treegate>` reface doar o piesa.

Axe: X latime, Y adancime (drumul trece pe Y), Z sus. Originea: baza, la mijlocul
trecerii (`anchor=(0, 0)`: axa trecerii e x = 0, nu centrul bbox-ului).

LISTA DE ELEMENTE, scrisa INAINTE de geometrie (decuparile `aw_west_gopura.png`,
`ta_prohm_tree_gate.png`; corectura din kit §0: SCULPTURA SIMPLIFICATA, fara fete):

aw_west_gopura -- lungime 52 m (capatul scurt al intervalului 50-56), adancime
~10 m, turnul central 15,5 m:
  1. Blocul central (|x| 5,1..8,4): doua picioare de gresie cu randuri de blocuri,
     socluri in 2 trepte; INTRE ele trecerea: gol curat 10,2 m, inaltime libera
     9,0 m (nimic in |x| < 5,0 sub 9 m). Pilastri pe fetele +-Y.
  2. Bolta in consola DEASUPRA cotei 9,0 (3 trepte care se ingusteaza, 4,5 / 3,7 /
     2,8), apoi cornisa-capac. Deasupra, frontoane de placi suprapuse pe ambele
     fete (cadrul de arc din desen).
  3. Turnul central: 3 etaje octogonale care se ingusteaza + boboc de lotus, 15,5 m.
  4. Doua galerii (x 8,4..26), simetrice fata/spate: soclu in 2 trepte, zid interior
     cu blocuri, colonade de 4 stalpi pe FIECARE parte (stalpi cu baza si capitel),
     arhitrava, acoperis in consola din 5 trepte cu antefixe pe streasina, capete
     inchise.
  5. Doua turnuri de capat (x = +-17,3), 11,3 m: cate 3 etaje + boboc, cu un portic
     fata/spate (2 stalpi, trepte, fronton din placi).
  6. Lichen: pete mici pe orizontale (socluri, streasini, cornise); dare negre
     scurte sub cornise si sub acoperis. Nimic sculptural, nicio fata.

ta_prohm_tree_gate -- poarta de ~14 m, 7,8 m pana la varful gresiei, copacul 21 m:
  1. Poarta: 2 picioare (|x| 3,45..5,6) cu blocuri, buiandrug de la 5,6 m (gol
     curat 6,9 m, inaltime libera 5,6 m), cornisa si o placa de sus ruinata
     (jumatate mai joasa). Aripi joase de zid + stalpi rupti pe laturi; blocuri
     cazute pe laturile fata/spate, DOAR la |x| >= 4,4.
  2. Trunchiul pe acoperis: soclu de radacini care se evazeaza, trunchi, 4 ramuri,
     coronament = mase de elipsoizi pe atlas.
  3. Radacinile: putine si GROASE (10), tuburi cu raza variabila, spline: cate 2 mari
     pe fiecare colt (peste acoperis, pe fata cornisei si a piciorului, pana la sol)
     si cate una cascada peste buiandrug care se duce SPRE picior (sub 5,5 m stau
     doar la |x| >= 3,8: nicio radacina in gol), plus una pe fiecare lateral.
  4. Culori: gresie ROCK_LIGHT 3; radacini CORAL_SAND 19 cu AO cald; coronament
     TROPICAL_GREEN 21; lichen LAVA_ORANGE 30 / CACTUS_GREEN 12 (muschi mai mult:
     Ta Prohm e verde); dare VOLCANIC_BLACK 20.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")


# --- ajutoare ----------------------------------------------------------------

def bx(b, x0, x1, y0, y1, z0, z1, slot=ANK_STONE):
    """Cutie dintre doua colturi (ordinea capetelor nu conteaza)."""
    x0, x1 = min(x0, x1), max(x0, x1)
    y0, y1 = min(y0, y1), max(y0, y1)
    b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
          (x1 - x0, y1 - y0, z1 - z0), slot)


def wall_faces(b, x0, x1, y0, y1, z0, z1, faces, ch=0.8, bw=1.3, proud=0.05,
               gap=0.04, seed=0, slot=ANK_STONE):
    """Randuri de blocuri in relief pe fetele alese (`+y -y +x -x`) ale unui corp
    dreptunghiular x0..x1, y0..y1 (varianta dreptunghiulara a `block_courses`):
    corpul ramane la cota nominala, blocurile ies `proud` in afara ei."""
    rnd = lcg(seed + 53)
    rows = max(1, int(round((z1 - z0) / ch)))
    rh = (z1 - z0) / rows
    t = proud + 0.01
    for f in faces:
        if f in ("+y", "-y"):
            u0, u1 = x0, x1
            plane = y1 if f == "+y" else y0
        else:
            u0, u1 = y0, y1
            plane = x1 if f == "+x" else x0
        n = 1.0 if f[0] == "+" else -1.0
        off = n * (proud - 0.01) * 0.5
        for r in range(rows):
            za, zb = z0 + r * rh + gap * 0.5, z0 + (r + 1) * rh - gap * 0.5
            zc = (za + zb) * 0.5
            cuts = [u0]
            u = u0 + bw * (0.45 if r % 2 else 1.0) * (0.85 + 0.3 * rnd())
            while u < u1 - 0.35 * bw:
                cuts.append(u)
                u += bw * (0.8 + 0.4 * rnd())
            cuts.append(u1)
            for ua, ub in zip(cuts[:-1], cuts[1:]):
                ua, ub = ua + gap * 0.5, ub - gap * 0.5
                if ub - ua < 0.1:
                    continue
                uc = (ua + ub) * 0.5
                if f in ("+y", "-y"):
                    b.box((uc, plane + off, zc), (ub - ua, t, zb - za), slot)
                else:
                    b.box((plane + off, uc, zc), (t, ub - ua, zb - za), slot)


def column(b, cx, cy, z0, z1, w=0.6, slot=ANK_STONE):
    """Stalp patrat cu baza si capitel in trepte, fus octogonal."""
    h = w * 0.5
    bx(b, cx - h - 0.12, cx + h + 0.12, cy - h - 0.12, cy + h + 0.12, z0, z0 + 0.22, slot)
    bx(b, cx - h - 0.05, cx + h + 0.05, cy - h - 0.05, cy + h + 0.05, z0 + 0.22, z0 + 0.38, slot)
    oct_prism(b, cx, cy, z0 + 0.38, z1 - 0.38, h * 0.92, h * 0.28, slot)
    bx(b, cx - h - 0.05, cx + h + 0.05, cy - h - 0.05, cy + h + 0.05, z1 - 0.38, z1 - 0.22, slot)
    bx(b, cx - h - 0.16, cx + h + 0.16, cy - h - 0.16, cy + h + 0.16, z1 - 0.22, z1, slot)


def scatter_lichen(lichen, sites, n_orange, n_green, seed):
    """Pete pe dreptunghiuri orizontale `(x0, x1, y0, y1, z)`, alese pe arie."""
    rnd = lcg(seed)
    areas = [max((s[1] - s[0]) * (s[3] - s[2]), 1e-6) for s in sites]
    tot = sum(areas)
    kinds = ["o"] * n_orange + ["g"] * n_green
    for i in range(len(kinds) - 1, 0, -1):
        j = int(rnd() * (i + 1))
        kinds[i], kinds[j] = kinds[j], kinds[i]
    for i, kind in enumerate(kinds):
        r, acc, site = rnd() * tot, 0.0, sites[-1]
        for s, a in zip(sites, areas):
            acc += a
            if r <= acc:
                site = s
                break
        x0, x1, y0, y1, z = site
        w, d = x1 - x0, y1 - y0
        rw = min(d * 0.40, 0.09 + 0.14 * rnd())
        ru = min(w * 0.40, rw * (1.6 + 1.8 * rnd()), 0.5)
        if kind == "g":
            ru, rw = min(ru * 1.15, w * 0.42), min(rw * 1.1, d * 0.42)
        mx, my = ru * 1.15, rw * 1.15
        if w < 2 * mx or d < 2 * my:
            continue
        cx = x0 + mx + (w - 2 * mx) * rnd()
        cy = y0 + my + (d - 2 * my) * rnd()
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        lichen_spot(lichen, (cx, cy, z), ru, rw, 0.028, slot, yaw_deg=0.0, seed=seed + i)


def scatter_streaks(streaks, sites, seed):
    """Dare pe fete verticale: site = (x0, x1, y_plan, yaw, z_sus, n, lung_min, lung_max)."""
    rnd = lcg(seed)
    for (x0, x1, yp, yaw, z_top, n, lmin, lmax) in sites:
        for _ in range(n):
            x = x0 + (x1 - x0) * rnd()
            w = 0.16 + 0.10 * rnd()
            ln = lmin + (lmax - lmin) * rnd()
            streak(streaks, (x, yp, z_top - 0.02), yaw, w, ln, 0.025, ANK_STREAK)


def spline(pts, radii, sub=3):
    """Catmull-Rom pe puncte + raze interpolate liniar: radacini care curg."""
    P = [Vector(p) for p in pts]
    n = len(P)
    out, rr = [], []
    for i in range(n - 1):
        p0, p1, p2, p3 = P[max(i - 1, 0)], P[i], P[i + 1], P[min(i + 2, n - 1)]
        for k in range(sub):
            t = k / float(sub)
            a = 0.5 * ((p1 * 2.0) + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t * t
                       + (p3 - p0 + (p1 - p2) * 3.0) * t * t * t)
            out.append(a)
            rr.append(radii[i] * (1 - t) + radii[i + 1] * t)
    out.append(P[-1])
    rr.append(radii[-1])
    return out, rr


# =============================================================================
# 1. aw_west_gopura
# =============================================================================

GP_L = 26.0               # jumatate din lungime: 52 m
PH = 5.1                  # fata interioara a picioarelor: gol 10,2 m
BLK_X = 8.4               # fata exterioara a blocului central
LINTEL_Z = 9.0            # inaltimea libera: sub ea nimic in |x| < 5
TOP_G = 15.9

AO_GOPURA = dict(samples=16, dist=1.4, gradient="vertical", low=0.62, high=1.0,
                 power=0.85, floor=0.30, strength=1.3, z_range=(0.0, TOP_G))


def build_gopura():
    S, L, G = Builder(), Builder(), Builder()
    sites = []            # suprafete orizontale pentru lichen
    streak_sites = []

    def X(a, b, sx):
        return min(sx * a, sx * b), max(sx * a, sx * b)

    # --- 1. blocul central: picioare, bolta in consola ------------------------
    for sx in (-1, 1):
        x0, x1 = X(PH, 9.1, sx)
        bx(S, x0, x1, -5.0, 5.0, 0.0, 0.5)
        sites.append((x0, x1, 4.7, 5.0, 0.5))
        sites.append((x0, x1, -5.0, -4.7, 0.5))
        x0, x1 = X(PH, 8.8, sx)
        bx(S, x0, x1, -4.7, 4.7, 0.5, 1.0)
        x0, x1 = X(PH, BLK_X, sx)
        bx(S, x0, x1, -4.5, 4.5, 1.0, LINTEL_Z)
        inner = "-x" if sx > 0 else "+x"
        outer = "+x" if sx > 0 else "-x"
        wall_faces(S, x0, x1, -4.5, 4.5, 1.0, LINTEL_Z, ["+y", "-y", inner, outer],
                   ch=0.9, bw=1.4, seed=3 + sx)
        # pilastri pe fetele +-Y: unul langa gol, unul la colt
        for (a, b_) in ((PH, PH + 0.8), (BLK_X - 0.8, BLK_X)):
            px0, px1 = X(a, b_, sx)
            for sy in (-1, 1):
                for (pd, pz0, pz1, pw) in ((0.06, 1.0, LINTEL_Z - 0.4, 0.35), (0.14, LINTEL_Z - 0.4, LINTEL_Z, 0.45),
                                           (0.12, 1.0, 1.3, 0.40)):
                    # la pilastrul de langa gol umflatura nu iese spre axa (golul ramane >= 10,2)
                    lo, hi = px0 - pd, px1 + pd
                    if a == PH:
                        lo, hi = (px0, px1 + pd) if sx > 0 else (px0 - pd, px1)
                    bx(S, lo, hi, sy * 4.5, sy * (4.5 + pw), pz0, pz1)
        # bolta in consola, DEASUPRA golului
        for (za, zb, opening) in ((LINTEL_Z, LINTEL_Z + 0.6, 4.5), (LINTEL_Z + 0.6, LINTEL_Z + 1.2, 3.7),
                                  (LINTEL_Z + 1.2, LINTEL_Z + 1.8, 2.8)):
            cx0, cx1 = X(opening, BLK_X, sx)
            bx(S, cx0, cx1, -4.5, 4.5, za, zb)
            wall_faces(S, cx0, cx1, -4.5, 4.5, za, zb, ["+y", "-y"], ch=0.6, bw=1.3, seed=9 + int(za))
        for sy in (-1, 1):
            streak_sites.append((X(6.2, 7.3, sx)[0], X(6.2, 7.3, sx)[1], sy * 4.5,
                                 0.0 if sy > 0 else 180.0, LINTEL_Z + 1.78, 3, 0.4, 1.0))
    z_cor = LINTEL_Z + 1.8
    bx(S, -8.9, 8.9, -4.9, 4.9, z_cor, z_cor + 0.5)       # cornisa-capac
    z = z_cor + 0.5
    for sx in (-1, 1):
        for sy in (-1, 1):
            c = Vector((sx * 8.7, sy * 4.7, z))
            pts = [c + Vector((dx * 0.11, dy * 0.11, 0.0)) for dx in (-1, 1) for dy in (-1, 1)]
            pts += [c + Vector((dx * 0.07, dy * 0.07, 0.3)) for dx in (-1, 1) for dy in (-1, 1)]
            hull(S, pts, ANK_STONE)
    # frontoane de placi suprapuse, pe ambele fete (toate peste cota 9,0)
    for sy in (-1, 1):
        for (za, zb, hw) in ((LINTEL_Z, LINTEL_Z + 0.6, 5.3), (LINTEL_Z + 0.6, LINTEL_Z + 1.2, 4.4),
                             (LINTEL_Z + 1.2, LINTEL_Z + 1.8, 3.4)):
            bx(S, -hw, hw, sy * 4.5, sy * 4.95, za, zb)
    # ledge-uri pentru lichen pe cornisa-capac (in jurul etajului 1, 3,9 + 0,05)
    sites += [(-8.9, -4.05, -4.9, 4.9, z), (4.05, 8.9, -4.9, 4.9, z),
              (-4.05, 4.05, 4.1, 4.9, z), (-4.05, 4.05, -4.9, -4.1, z)]

    # --- 2. turnul central: 3 etaje + boboc -----------------------------------
    bx(S, -7.0, 7.0, -4.3, 4.3, z, z + 0.6)           # soclu in trepte sub turn
    bx(S, -5.6, 5.6, -4.1, 4.1, z + 0.6, z + 1.2)
    z += 1.2
    z = tier(S, z, z + 0.8, 3.7, 0.1)
    z = tier(S, z, z + 0.6, 2.9, 0.1)
    z = tier(S, z, z + 0.5, 2.2, 0.1)
    lotus_bud(S, 0, 0, z, TOP_G - z, 0.95, petals=8, segments=14)

    # --- 3. galeriile (x 8,4 .. 26), simetrice fata/spate ------------------------
    ROOF_N = 5
    for sx in (-1, 1):
        x0, x1 = X(BLK_X, GP_L, sx)
        bx(S, x0, x1, -5.0, 5.0, 0.0, 0.5)
        sites.append((x0 if sx > 0 else x0 + 0.4, x1 if sx < 0 else x1 - 0.4, 4.65, 5.0, 0.5))
        sites.append((x0 if sx > 0 else x0 + 0.4, x1 if sx < 0 else x1 - 0.4, -5.0, -4.65, 0.5))
        x0, x1 = X(BLK_X, GP_L - 0.3, sx)
        bx(S, x0, x1, -4.65, 4.65, 0.5, 1.0)
        # zidul interior
        x0, x1 = X(BLK_X, GP_L - 1.0, sx)
        bx(S, x0, x1, -1.3, 1.3, 1.0, 4.8)
        wall_faces(S, x0, x1, -1.3, 1.3, 1.0, 4.8, ["+y", "-y"], ch=0.95, bw=1.4, seed=21 + sx)
        # capatul inchis
        x0, x1 = X(GP_L - 1.0, GP_L - 0.4, sx)
        bx(S, x0, x1, -4.3, 4.3, 1.0, 4.8)
        wall_faces(S, x0, x1, -4.3, 4.3, 1.0, 4.8, ["+x" if sx > 0 else "-x"], ch=0.95, bw=1.4, seed=33 + sx)
        # colonade pe ambele parti, cu arhitrava
        for sy in (-1, 1):
            for cxp in (10.2, 12.9, 22.1, 24.4):
                column(S, sx * cxp, sy * 3.6, 1.0, 4.4)
            for cxp in (15.1, 19.5):                       # stalpii porticului
                column(S, sx * cxp, sy * 4.3, 1.0, 4.4, w=0.65)
            ax0, ax1 = X(BLK_X, GP_L - 0.5, sx)
            bx(S, ax0, ax1, sy * 3.2, sy * 4.0, 4.4, 4.8)
            streak_sites.append((ax0 + 0.4 if sx > 0 else ax0 + 0.4, ax1 - 0.4, sy * 4.0,
                                 0.0 if sy > 0 else 180.0, 4.78, 5, 0.2, 0.4))
            streak_sites.append((min(sx * 9.5, sx * 24.0), max(sx * 9.5, sx * 24.0), sy * 1.3,
                                 0.0 if sy > 0 else 180.0, 4.78, 9, 0.5, 1.3))
            # portic: trepte, buiandrug, fronton de placi
            px0, px1 = X(14.4, 20.2, sx)
            bx(S, px0, px1, sy * 4.9, sy * 5.5, 0.0, 0.5)
            bx(S, px0, px1, sy * 4.65, sy * 5.1, 0.5, 1.0)
            bx(S, *X(14.7, 19.9, sx), sy * 4.0, sy * 4.85, 4.4, 4.8)
            for (za, zb, hw) in ((4.8, 5.4, 2.6), (5.4, 6.0, 2.0), (6.0, 6.6, 1.4), (6.6, 7.0, 0.7)):
                bx(S, *X(17.3 - hw, 17.3 + hw, sx), sy * 4.3, sy * 4.8, za, zb)
            sites.append((px0 + 0.1, px1 - 0.1, min(sy * 5.1, sy * 5.5), max(sy * 5.1, sy * 5.5), 0.5))
        # acoperisul: 5 trepte in consola, capete in pas (se strang spre exterior)
        for i in range(ROOF_N):
            hy = 4.6 - 0.55 * i
            xe = GP_L - 0.2 - 0.55 * i
            z0 = 4.8 + 0.5 * i
            x0, x1 = X(BLK_X, xe, sx)
            bx(S, x0, x1, -hy, hy, z0, z0 + 0.5)
            if i + 1 < ROOF_N:
                hn = 4.6 - 0.55 * (i + 1)
                sx0, sx1 = X(BLK_X + 0.3, xe - 0.3, sx)
                sites.append((sx0, sx1, hn + 0.02, hy - 0.02, z0 + 0.5))
                sites.append((sx0, sx1, -hy + 0.02, -hn - 0.02, z0 + 0.5))
        # antefixe pe streasina: rand de piese mici pe prima treapta
        k = 0
        xv = BLK_X + 0.7
        while xv < GP_L - 0.9:
            for sy in (-1, 1):
                if abs(xv - 17.3) < 2.9:
                    continue
                c = (sx * xv, sy * 4.48, 5.3 + 0.16)
                S.box(c, (0.26, 0.16, 0.32), ANK_STONE)
            xv += 0.9
            k += 1
        # turnul de capat: 3 etaje + boboc, la x = 17,3, pe creasta (z 7,3)
        cx = sx * 17.3
        zt = tier(S, 7.3, 8.3, 2.5, 0.1, cx=cx, cy=0.0)
        zt = tier(S, zt, zt + 0.8, 2.0, 0.1, cx=cx, cy=0.0)
        zt = tier(S, zt, zt + 0.6, 1.5, 0.1, cx=cx, cy=0.0)
        lotus_bud(S, cx, 0.0, zt, 11.3 - zt, 0.75, petals=8, segments=14)

    scatter_lichen(L, sites, 70, 28, seed=17)
    scatter_streaks(G, streak_sites, seed=29)
    return [S.to_object("Gopura_Stone"), L.to_object("Gopura_Lichen"), G.to_object("Gopura_Streak")]


# =============================================================================
# 2. ta_prohm_tree_gate
# =============================================================================

TG_PH = 3.45              # fata interioara a picioarelor: gol 6,9 m
TG_LINTEL = 5.6           # inaltimea libera
TG_TOP = 21.4

AO_TREEGATE = dict(samples=16, dist=1.6, gradient="vertical", low=0.52, high=1.0,
                   power=0.9, floor=0.28, strength=1.3, z_range=(0.0, TG_TOP))


RF = 1.25                 # radacinile sunt GROASE


def build_treegate():
    S, L, G = Builder(), Builder(), Builder()
    R, C = Builder(), Builder()
    rnd = lcg(71)
    sites, streak_sites = [], []

    def X(a, b, sx):
        return min(sx * a, sx * b), max(sx * a, sx * b)

    # --- 1. poarta de gresie ----------------------------------------------------
    for sx in (-1, 1):
        x0, x1 = X(TG_PH, 7.0, sx)
        bx(S, x0, x1, -3.6, 3.6, 0.0, 0.35)
        sites.append((x0 + (0.0 if sx > 0 else 0.0), x1, 3.2, 3.6, 0.35))
        sites.append((x0, x1, -3.6, -3.2, 0.35))
        px0, px1 = X(TG_PH, 5.6, sx)
        bx(S, px0, px1, -3.2, 3.2, 0.35, TG_LINTEL)
        inner = "-x" if sx > 0 else "+x"
        outer = "+x" if sx > 0 else "-x"
        wall_faces(S, px0, px1, -3.2, 3.2, 0.35, TG_LINTEL, ["+y", "-y", inner, outer],
                   ch=0.75, bw=1.1, seed=5 + sx)
        # aripa de zid, ruinata: o jumatate mai inalta
        wx0, wx1 = X(5.6, 7.0, sx)
        bx(S, wx0, wx1, -2.2, 0.3, 0.35, 3.2)
        bx(S, wx0, wx1, 0.3, 2.2, 0.35, 2.2)
        wall_faces(S, wx0, wx1, -2.2, 0.3, 0.35, 3.2, [outer, "-y"], ch=0.75, bw=1.0, seed=13 + sx)
        wall_faces(S, wx0, wx1, 0.3, 2.2, 0.35, 2.2, [outer, "+y"], ch=0.75, bw=1.0, seed=17 + sx)
        sites.append((wx0 + 0.05, wx1 - 0.05, -2.1, 0.2, 3.2))
        sites.append((wx0 + 0.05, wx1 - 0.05, 0.4, 2.1, 2.2))
        # stalpi rupti pe lateral (in fata si in spate)
        column(S, sx * 6.3, -3.0, 0.35, 3.0 if sx < 0 else 2.4, w=0.62)
        column(S, sx * 6.3, 3.0, 0.35, 2.1 if sx < 0 else 3.2, w=0.62)
        for sy in (-1, 1):
            streak_sites.append((px0 + 0.3, px1 - 0.3, sy * 3.2, 0.0 if sy > 0 else 180.0, 5.55, 3, 0.4, 0.9))
    bx(S, -5.6, 5.6, -3.2, 3.2, TG_LINTEL, 6.5)
    wall_faces(S, -5.6, 5.6, -3.2, 3.2, TG_LINTEL, 6.5, ["+y", "-y"], ch=0.9, bw=1.5, seed=41)
    bx(S, -6.0, 6.0, -3.6, 3.6, 6.5, 7.1)
    bx(S, -4.6, 1.8, -2.6, 2.6, 7.1, 7.8)       # placa de sus, ruinata: stanga inalta,
    bx(S, 1.8, 4.6, -2.6, 2.6, 7.1, 7.45)       # dreapta mai joasa
    sites += [(-5.9, -4.7, -3.5, 3.5, 7.1), (4.7, 5.9, -3.5, 3.5, 7.1),
              (-4.6, 4.6, 2.7, 3.5, 7.1), (-4.6, 4.6, -3.5, -2.7, 7.1), (1.9, 4.5, -2.5, 2.5, 7.45)]
    for sy in (-1, 1):
        streak_sites.append((-5.0, 5.0, sy * 3.2, 0.0 if sy > 0 else 180.0, 6.48, 6, 0.4, 0.8))
    # blocuri cazute, doar la |x| >= 4,4, pe fasiile din fata si din spate
    for sx in (-1, 1):
        for sy in (-1, 1):
            for k in range(3):
                bxs = 0.55 + 0.55 * rnd()
                bys = 0.50 + 0.40 * rnd()
                bzs = 0.35 + 0.30 * rnd()
                cxp = 4.6 + 2.2 * rnd() + k * 0.15
                cyp = 3.95 + 0.7 * rnd()
                rot = Matrix.Rotation(math.radians(rnd() * 80 - 40), 3, "Z")
                S.box((sx * cxp, sy * cyp, bzs * 0.5), (bxs, bys, bzs), ANK_STONE, rotation=rot)
                sites.append((sx * cxp - bxs * 0.3 if sx > 0 else sx * cxp - bxs * 0.3, sx * cxp + bxs * 0.3,
                              sy * cyp - bys * 0.3, sy * cyp + bys * 0.3, bzs))

    # --- 2. trunchiul si ramurile --------------------------------------------------
    R.frustum((0.0, 0.0, 8.7), 3.0, 1.8, 2.2, ANK_ROOT, segments=12)
    trunk, tr = spline([(0.0, 0.0, 9.5), (0.1, 0.05, 10.9), (0.2, 0.1, 12.4), (0.3, 0.2, 14.2)],
                       [1.8, 1.55, 1.3, 1.05], sub=3)
    R.taper_sweep([tuple(p) for p in trunk], tr, ANK_ROOT, segments=10)
    limbs = [
        ([(0.3, 0.2, 13.9), (-1.0, 0.3, 15.4), (-2.6, 0.2, 16.8), (-3.8, 0.1, 18.0)], [1.0, 0.75, 0.5, 0.28]),
        ([(0.3, 0.2, 13.9), (1.4, -0.2, 15.2), (2.9, -0.5, 16.4), (4.4, -0.6, 17.5)], [1.0, 0.75, 0.5, 0.28]),
        ([(0.3, 0.2, 13.9), (0.3, 1.0, 15.6), (0.9, 1.6, 17.2), (1.2, 1.8, 18.8)], [0.95, 0.7, 0.48, 0.27]),
        ([(0.3, 0.2, 13.9), (0.0, -1.0, 15.5), (-0.9, -1.8, 17.0), (-1.2, -2.0, 18.3)], [0.9, 0.68, 0.46, 0.26]),
    ]
    for pts, rr_ in limbs:
        pp, rr2 = spline(pts, rr_, sub=3)
        R.taper_sweep([tuple(p) for p in pp], rr2, ANK_ROOT, segments=8)

    # --- 3. radacinile: putine, groase ---------------------------------------------
    def root(pts, radii, sx, sy, sub=3, rf=None):
        pp, rr2 = spline([(sx * p[0], sy * p[1], p[2]) for p in pts], [r * (RF if rf is None else rf) if r > 0.15 else r for r in radii], sub=sub)
        R.taper_sweep([tuple(p) for p in pp], rr2, ANK_ROOT, segments=8)

    for sy in (-1, 1):
        for sx in (-1, 1):
            # R1: din trunchi peste acoperis, pe fata cornisei si a piciorului, la sol
            root([(0.6, 0.5, 9.0), (1.6, 1.1, 8.55), (2.6, 2.0, 8.2), (3.3, 3.0, 7.7), (3.9, 3.7, 6.8),
                  (4.4, 3.65, 5.2), (4.9, 3.85, 3.2), (5.4, 4.5, 1.3), (6.1, 4.9, 0.35), (7.0, 5.2, 0.12)],
                 [0.75, 0.66, 0.6, 0.54, 0.5, 0.46, 0.42, 0.38, 0.28, 0.12], sx, sy)
            # R2: cascada peste buiandrug, care se duce SPRE picior (sub 5,5 m doar la |x| >= 3,8)
            root([(0.4, 0.7, 9.0), (0.5, 1.9, 8.3), (0.7, 3.1, 7.55),
                  (0.9, 3.85, 6.9), (1.5, 3.8, 6.4), (2.6, 3.78, 6.3), (3.6, 3.78, 6.2),
                  (4.2, 3.8, 5.3), (4.6, 3.95, 3.7), (5.0, 4.2, 1.8), (5.5, 4.7, 0.45), (6.6, 5.2, 0.12)],
                 [0.55, 0.5, 0.46, 0.42, 0.4, 0.38, 0.36, 0.34, 0.32, 0.28, 0.2, 0.1], sx, sy, rf=1.15)
            # R3: a doua cascada, mai subtire, intre R1 si R2 (acopera fata cornisei)
            root([(1.2, 0.9, 8.9), (1.6, 2.2, 8.1), (1.9, 3.3, 7.4), (2.3, 3.95, 6.85), (3.0, 3.9, 6.5),
                  (3.8, 3.85, 6.3), (4.4, 3.8, 5.4), (4.8, 3.75, 4.0), (5.2, 3.95, 2.3), (5.9, 4.4, 0.6),
                  (6.8, 4.9, 0.12)],
                 [0.4, 0.38, 0.36, 0.34, 0.33, 0.32, 0.3, 0.28, 0.26, 0.2, 0.1], sx, sy, rf=1.1)
    for sx in (-1, 1):
        # R5: pe lateral, peste cornisa, pe fata exterioara a piciorului si a aripii, la sol
        root([(0.9, 0.2, 9.0), (2.2, 0.4, 8.5), (3.6, 0.5, 8.0), (5.0, 0.5, 7.6), (6.3, 0.7, 6.9),
              (6.4, 0.8, 5.0), (6.6, 1.0, 3.7), (7.0, 1.3, 1.9), (7.7, 1.8, 0.5), (8.6, 2.2, 0.12)],
             [0.62, 0.56, 0.5, 0.48, 0.46, 0.42, 0.4, 0.36, 0.26, 0.1], sx, 1)

    # contraforturi pe trunchi: radacini care coboara pe fusul trunchiului (nu mai e con neted)
    for k in range(6):
        a = 2.0 * math.pi * (k + 0.3) / 6.0
        ca, sa = math.cos(a), math.sin(a)
        pts = [(ca * 0.5, sa * 0.5, 13.4), (ca * 1.15, sa * 1.15, 11.6), (ca * 1.95, sa * 1.95, 9.8),
               (ca * 2.7, sa * 2.7, 8.5)]
        pp, rr2 = spline(pts, [0.42, 0.55, 0.6, 0.4], sub=3)
        R.taper_sweep([tuple(p) for p in pp], rr2, ANK_ROOT, segments=8)
    # bolovani pe cornisa (ruina de sus)
    for k in range(9):
        sxk = -1 if k % 2 else 1
        bxs, bys, bzs = 0.6 + 0.5 * rnd(), 0.5 + 0.4 * rnd(), 0.4 + 0.3 * rnd()
        cxp, cyp = 3.2 + 2.4 * rnd(), (rnd() * 2 - 1) * 3.0
        rot = Matrix.Rotation(math.radians(rnd() * 90 - 45), 3, "Z")
        S.box((sxk * cxp, cyp, 7.1 + bzs * 0.5), (bxs, bys, bzs), ANK_STONE, rotation=rot)

    # --- 4. coronamentul: mase de elipsoizi ----------------------------------------
    ident = Matrix.Identity(3)
    masses = [(-3.8, 0.1, 18.4, 3.1, 2.9, 1.7), (4.4, -0.6, 17.9, 3.3, 3.0, 1.8), (1.2, 1.8, 19.3, 3.0, 2.8, 1.8),
              (-1.2, -2.0, 18.2, 2.8, 2.6, 1.6), (0.0, 0.3, 19.6, 3.3, 3.0, 1.7),
              (-2.0, 2.6, 17.4, 2.5, 2.3, 1.5), (3.0, 2.4, 17.6, 2.5, 2.3, 1.5),
              (-5.7, -1.0, 16.7, 2.3, 2.1, 1.3), (6.0, 0.6, 16.6, 2.4, 2.2, 1.3),
              (0.2, -3.8, 17.2, 2.4, 2.2, 1.3), (-1.0, 4.0, 17.3, 2.2, 2.0, 1.2),
              (3.4, -3.2, 17.0, 2.3, 2.1, 1.3), (-3.2, -3.4, 17.3, 2.2, 2.0, 1.2)]
    for (mx, my, mz, ru, rv, rz) in masses:
        for j in range(3):
            ox = (rnd() - 0.5) * ru * 0.9
            oy = (rnd() - 0.5) * rv * 0.9
            oz = (rnd() - 0.4) * rz * 0.8
            s = 0.62 + 0.22 * rnd()
            ellipsoid(C, (mx + ox, my + oy, mz + oz), (ru * s * 1.25, rv * s * 1.25, rz * s * 1.1),
                      ANK_CANOPY, ident, 10, 6)

    scatter_lichen(L, sites, 14, 40, seed=23)
    scatter_streaks(G, streak_sites, seed=31)
    return [S.to_object("TreeGate_Stone"), L.to_object("TreeGate_Lichen"), G.to_object("TreeGate_Streak"),
            R.to_object("TreeGate_Root"), C.to_object("TreeGate_Canopy")]


ANK_ROOT = CORAL_SAND         # 19: radacini si trunchi, AO cald
ANK_CANOPY = TROPICAL_GREEN   # 21: coronament


def emit_gopura():
    objs = build_gopura()
    emit_angkor(objs, "structures/aw_west_gopura.glb", AO_GOPURA, bevel=0.0,
                bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0, anchor=(0.0, 0.0))
    clear_built()


def emit_treegate():
    objs = build_treegate()
    emit_angkor(objs, "structures/ta_prohm_tree_gate.glb", AO_TREEGATE, bevel=0.0,
                bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=60.0, anchor=(0.0, 0.0),
                ao_tint={"_Root": (1.0, 1.3, 1.7)})
    clear_built()


if not ONLY or ONLY == "gopura":
    emit_gopura()
if not ONLY or ONLY == "treegate":
    emit_treegate()
report_angkor()
