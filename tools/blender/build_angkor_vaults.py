"""Angkor -- val 2, grupul B: bolta galeriei prabusite, blocul dominoului, sprijinul
restauratorilor (kit angkor_kit.md §1.5).

  angkor/kit/vault_intact.glb         modul L = 4,0 m: bolta in consola, intreaga
  angkor/kit/vault_broken.glb         acelasi modul prabusit, acoperisul DESCHIS
  angkor/props/fallen_block.glb       blocul sculptat care cade in dominou
  angkor/props/restoration_prop.glb   sprijin de lemn sub un perete inclinat

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_vaults.py
`ANK_ONLY=<intact|broken|block|prop>` reface doar o piesa.

Axe: X latime, Y de-a lungul drumului (modulul are y in [-2, 2]), Z sus. Originea:
baza, pe axa drumului (`anchor=(0, 0)`). Sculptura e SIMPLIFICATA (decizia
dezvoltatorului, kit §1.1): rozeta blocului e geometrie blocata, nu desen fin.

LISTA DE ELEMENTE, scrisa INAINTE de geometrie:

vault_intact (decuparea: bolta in arc din blocuri; contractul zice consola, nu arc
roman):
  1. Doi pereti groși de 0,9 m (x 3,40..4,30), inalti de 3,4 m, cu randuri de
     blocuri pe fetele interioara si exterioara; fetele de capat ±2,0 sunt PLANE
     (modulul se lanteste). Soclu exterior scund.
  2. Patru randuri de consola (cate 0,8 m inaltime) care se apropie de axa cu 0,75 m
     pe rand: fata interioara la x 2,65 / 1,90 / 1,15 / 0,40; marginea exterioara
     se trage si ea in trepte (4,30 / 3,90 / 3,50 / 3,10).
  3. Piatra de cheie: placa plata (|x| <= 1,3) la cota 6,6..7,4. Golul interior:
     6,68 m pana la 3,4 m inaltime (peretii), 6,6 m inaltime libera la cheie.
  4. Lichen pe treptele exterioare si pe capac; dare sub marginile randurilor.

vault_broken: aceiasi pereti, dar taiati pe lungime in bucati de inaltimi diferite;
  deasupra cotei 3,4 bucata mai inalta pastreaza randurile de consola DOAR cu
  profilul exterior in trepte (fata interioara taiata la 3,40: sectiune curata, nu
  consola care atarna deasupra drumului). In |x| < 3,3 NU e nimic peste 3,4 m, deci
  blocul care cade de la 6 m, la |x| <= 2, nu atinge nimic. Moloz doar la |x| >= 3,3
  (in afara peretelui si pe golurile lui). Blocuri rasturnate pe creste.

fallen_block: cub de gresie 2,5 m (anvelopa `boulder_roller` x 0,5), colturi sparte
  in fatete mari, o fata (+Y) cu panou: rama inalta + rozeta cu 8+8 petale.

restoration_prop: perete de blocuri (6 randuri) inclinat spre +Y, sprijinit pe 2
  popi in diagonala cu talpa pe un prag scurt, cu doua scanduri-brau pe fata
  peretelui si o contravantuire in X; pene la picioare.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")
ANK_WOOD = 9          # WOOD_WEATHERED
ANK_WOOD_DARK = 28    # LOG_DARK


# --- ajutoare (copiate din build_angkor_gates_w.py, care e script, nu modul) ----

def bx(b, x0, x1, y0, y1, z0, z1, slot=ANK_STONE):
    x0, x1 = min(x0, x1), max(x0, x1)
    y0, y1 = min(y0, y1), max(y0, y1)
    b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
          (x1 - x0, y1 - y0, z1 - z0), slot)


def wall_faces(b, x0, x1, y0, y1, z0, z1, faces, ch=0.8, bw=1.3, proud=0.06,
               gap=0.04, seed=0, slot=ANK_STONE):
    """Randuri de blocuri in relief pe fetele alese (`+y -y +x -x`): corpul ramane
    la cota nominala, blocurile ies `proud` in afara ei."""
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


def chunk(b, c, size, rnd, jit=0.12, yaw=None, tilt=8.0, slot=ANK_STONE):
    """Bloc spart: invelitoare a unui paralelipiped cu colturile mutate cu `jit`
    din latura, rotit cu yaw aleator si inclinare mica. FATETE mari, nu bile."""
    sx, sy, sz = size
    yw = math.radians(yaw if yaw is not None else rnd() * 360.0)
    rot = (Matrix.Rotation(yw, 3, "Z")
           @ Matrix.Rotation(math.radians((rnd() - 0.5) * 2 * tilt), 3, "X")
           @ Matrix.Rotation(math.radians((rnd() - 0.5) * 2 * tilt), 3, "Y"))
    pts = []
    for a in (-1, 1):
        for bb in (-1, 1):
            for cc in (-1, 1):
                p = Vector((a * sx * 0.5 * (1 + (rnd() - 0.5) * 2 * jit),
                            bb * sy * 0.5 * (1 + (rnd() - 0.5) * 2 * jit),
                            cc * sz * 0.5 * (1 + (rnd() - 0.5) * 2 * jit)))
                pts.append(Vector(c) + rot @ p)
    hull(b, pts, slot)


# =============================================================================
# 1-2. bolta: intacta si prabusita
# =============================================================================

HL = 2.0                              # jumatate din lungimea modulului (L = 4,0)
W_IN, W_OUT = 3.40, 4.30              # fata interioara / exterioara a peretelui
Z_WALL = 3.4                          # sus la perete; peste el incep randurile de consola
CR_H = 0.8
CR_IN = [2.65, 1.90, 1.15, 0.40]      # fata interioara pe rand (se apropie de axa)
CR_OUT = [4.30, 3.90, 3.50, 3.10]     # marginea exterioara pe rand
Z_CAP = Z_WALL + 4 * CR_H             # 6,6: fata de jos a pietrei de cheie = inaltimea libera
CAP_H, CAP_HALF = 0.8, 1.3
TOP_V = Z_CAP + CAP_H                 # 7,4

AO_VAULT = dict(samples=16, dist=1.4, gradient="vertical", low=0.62, high=1.0,
                power=0.85, floor=0.30, strength=1.3, z_range=(0.0, TOP_V))


def _streaks_vault(G, rnd, broken):
    """Dare scurte: sub marginea fiecarui rand (fata interioara si exterioara).
    Pe fata interioara placa de relief ajunge la x = 3,34; dara iese 2,5 cm: >= 3,315."""
    for sx in (-1, 1):
        yaw_in = 90.0 if sx > 0 else 270.0
        yaw_out = 270.0 if sx > 0 else 90.0
        for _ in range(3):
            y = -1.7 + 3.4 * rnd()
            streak(G, (sx * (W_IN - 0.06), y, Z_WALL - 0.02), yaw_in,
                   0.16 + 0.1 * rnd(), 0.8 + 0.9 * rnd(), 0.025, ANK_STREAK)
        if not broken:
            for k in (0, 1, 2):
                y = -1.6 + 3.2 * rnd()
                streak(G, (sx * (CR_IN[k] - 0.06), y, Z_WALL + (k + 1) * CR_H - 0.02), yaw_in,
                       0.18 + 0.1 * rnd(), 0.4 + 0.3 * rnd(), 0.025, ANK_STREAK)
            for k in (1, 2, 3):
                y = -1.6 + 3.2 * rnd()
                streak(G, (sx * (CR_OUT[k] + 0.06), y, Z_WALL + (k + 1) * CR_H - 0.02), yaw_out,
                       0.18 + 0.1 * rnd(), 0.4 + 0.3 * rnd(), 0.025, ANK_STREAK)
        for _ in range(3):
            y = -1.7 + 3.4 * rnd()
            streak(G, (sx * (W_OUT + 0.06), y, 2.4 + 1.0 * rnd()), yaw_out,
                   0.18 + 0.1 * rnd(), 0.8 + 0.8 * rnd(), 0.025, ANK_STREAK)


def build_vault(broken):
    S, L, G = Builder(), Builder(), Builder()
    sites = []
    rnd = lcg(91 if broken else 77)

    def side(sx):
        """interval (x_a, x_b) crescator pentru marginile a, b pe partea sx."""
        return lambda a, b: (min(sx * a, sx * b), max(sx * a, sx * b))

    for sx in (-1, 1):
        X = side(sx)
        inner = "-x" if sx > 0 else "+x"
        outer = "+x" if sx > 0 else "-x"
        # soclu exterior scund
        x0, x1 = X(W_OUT, W_OUT + 0.30)
        bx(S, x0, x1, -HL, HL, 0.0, 0.45)
        sites.append((min(x0, x1) + 0.02, max(x0, x1) - 0.02, -HL + 0.2, HL - 0.2, 0.45))

        if not broken:
            x0, x1 = X(W_IN, W_OUT)
            bx(S, x0, x1, -HL, HL, 0.0, Z_WALL)
            wall_faces(S, x0, x1, -HL, HL, 0.0, Z_WALL, [inner, outer], ch=0.85, bw=1.3, seed=5 + sx)
            for k in range(4):
                za = Z_WALL + k * CR_H
                x0, x1 = X(CR_IN[k], CR_OUT[k])
                bx(S, x0, x1, -HL, HL, za, za + CR_H)
                wall_faces(S, x0, x1, -HL, HL, za, za + CR_H, [inner, outer], ch=CR_H, bw=1.2,
                           seed=11 + 3 * k + sx)
                if k < 3:
                    ox0, ox1 = X(CR_OUT[k + 1], CR_OUT[k])
                    sites.append((min(ox0, ox1) + 0.02, max(ox0, ox1) - 0.02, -HL + 0.2, HL - 0.2, za + CR_H))
                else:
                    ox0, ox1 = X(CAP_HALF, CR_OUT[3])
                    sites.append((min(ox0, ox1) + 0.02, max(ox0, ox1) - 0.02, -HL + 0.2, HL - 0.2, za + CR_H))
        elif sx < 0:
            # -X: SEMI-BOLTA ramasa. Peretele plin + randuri de consola pe bucati (cate
            # randuri a pastrat fiecare); ultimul rand al fiecarei bucati e scurtat (margine
            # zimtata), cu un bloc inclinat pe el. Nimic nu trece de x = +0,2.
            x0, x1 = X(W_IN, W_OUT)
            bx(S, x0, x1, -HL, HL, 0.0, Z_WALL)
            wall_faces(S, x0, x1, -HL, HL, 0.0, Z_WALL, [inner, outer], ch=0.85, bw=1.3, seed=5 + sx)
            for (ya, yb, n, trim) in ((-2.0, -0.8, 4, 0.0), (-0.8, 0.5, 3, 0.35), (0.5, 2.0, 2, 0.3)):
                for k in range(n):
                    za = Z_WALL + k * CR_H
                    xin = CR_IN[k] + (trim if k == n - 1 else 0.0)
                    x0, x1 = X(xin, CR_OUT[k])
                    bx(S, x0, x1, ya, yb, za, za + CR_H)
                    wall_faces(S, x0, x1, ya, yb, za, za + CR_H, [inner, outer], ch=CR_H, bw=1.2,
                               seed=41 + 3 * k + int(ya * 5))
                    if k < 3:
                        ox0, ox1 = X(CR_OUT[k + 1], CR_OUT[k])
                        sites.append((min(ox0, ox1) + 0.02, max(ox0, ox1) - 0.02, ya + 0.1, yb - 0.1, za + CR_H))
                top_k = n - 1
                ztop = Z_WALL + n * CR_H
                xin_top = CR_IN[top_k] + trim
                if n == 4:
                    # placa de cheie pe jumatate: de la -1,3 pana la +0,2 (nu mai departe)
                    bx(S, -CAP_HALF, 0.2, ya, yb, Z_CAP, TOP_V)
                    wall_faces(S, -CAP_HALF, 0.2, ya, yb, Z_CAP, TOP_V, ["+x", "-x"], ch=CAP_H, bw=1.2, seed=97)
                    sites.append((-CAP_HALF + 0.02, 0.2 - 0.02, ya + 0.1, yb - 0.1, TOP_V))
                    ztop = TOP_V
                    xin_top = -0.5
                # blocuri inclinate pe marginea zimtata
                cy = (ya + yb) * 0.5
                s_ = 0.5 + 0.15 * rnd()
                chunk(S, (-(abs(xin_top) + 0.55), cy, ztop + s_ * 0.4), (s_ * 1.2, s_, s_ * 0.8), rnd, tilt=16.0)
        else:
            # +X: peretele rupt jos (varf zimtat la 3-4,5 m); randurile de consola sunt taiate
            # la fata interioara (x = 3,40), deci nimic nu atarna peste drum.
            for (ya, yb, h) in [(-2.0, -0.9, 4.2), (-0.9, 0.3, 3.0), (0.3, 1.2, 4.0), (1.2, 2.0, 3.4)]:
                x0, x1 = X(W_IN, W_OUT)
                zb = min(h, Z_WALL)
                bx(S, x0, x1, ya, yb, 0.0, zb)
                wall_faces(S, x0, x1, ya, yb, 0.0, zb, [inner, outer], ch=0.85, bw=1.3, seed=21 + int(ya * 5))
                top = zb
                if h > Z_WALL + 0.01:
                    x0, x1 = X(W_IN, CR_OUT[0])
                    bx(S, x0, x1, ya, yb, Z_WALL, h)
                    wall_faces(S, x0, x1, ya, yb, Z_WALL, h, [inner, outer], ch=h - Z_WALL, bw=1.2,
                               seed=31 + int(ya * 5))
                    top = h
                sites.append((min(X(W_IN, W_OUT)) + 0.05, max(X(W_IN, W_OUT)) - 0.05, ya + 0.1, yb - 0.1, top))
                if (yb - ya) > 0.85:
                    s_ = 0.45 + 0.2 * rnd()
                    chunk(S, (3.95 + 0.25 * rnd(), (ya + yb) * 0.5, top + s_ * 0.4), (s_ * 1.3, s_, s_ * 0.8),
                          rnd, tilt=14.0)
        if not broken:
            continue
        # --- moloz (doar la |x| >= 3,4) ---
        if sx > 0:
            # movila de blocuri de acoperis cazute, pe EXTERIORUL peretelui +X, pana la ~2 m
            for (z_lo, nb, xr, sz) in ((0.0, 9, (4.5, 7.0), (0.85, 1.0)),
                                       (0.9, 6, (4.5, 6.0), (0.75, 0.95)),
                                       (1.6, 3, (4.5, 5.3), (0.6, 0.8))):
                for i in range(nb):
                    s_ = sz[0] + (sz[1] - sz[0]) * rnd()
                    cx = xr[0] + (xr[1] - xr[0]) * rnd()
                    cy = -0.9 + 1.8 * (i + rnd() * 0.6) / nb
                    chunk(S, (cx, max(-0.95, min(0.95, cy)), z_lo + s_ * 0.5), (s_, s_ * (0.8 + 0.3 * rnd()), s_ * 0.8),
                          rnd, tilt=14.0)
            for i in range(10):
                s_ = 0.22 + 0.2 * rnd()
                chunk(S, (4.5 + 3.4 * rnd(), -1.3 + 2.6 * rnd(), s_ * 0.4), (s_, s_, s_ * 0.8), rnd, tilt=20.0)
            # placa de consola cazuta, sprijinita de movila
            chunk(S, (5.1, 0.3, 2.35), (1.5, 0.6, 0.5), rnd, jit=0.06, yaw=92.0, tilt=10.0)
            # pe golul scund al peretelui: moloz in grosimea lui (x >= 3,9)
            for _ in range(5):
                s_ = 0.3 + 0.2 * rnd()
                chunk(S, (4.0 + 0.55 * rnd(), -0.9 + 1.2 * rnd(), 3.0 + s_ * 0.4), (s_, s_, s_ * 0.8), rnd, tilt=18.0)
        else:
            for i in range(7):
                s_ = 0.3 + 0.35 * rnd()
                chunk(S, (-(4.6 + 1.8 * rnd()), -1.0 + 2.0 * rnd(), s_ * 0.45), (s_, s_, s_ * 0.8), rnd, tilt=16.0)
            # blocuri cazute pe semi-bolta: pe capul randului 3 (z 6,6) si pe treapta randului 2
            chunk(S, (-2.3, -1.3, Z_CAP + 0.3), (0.65, 0.55, 0.5), rnd, tilt=12.0)
            chunk(S, (-3.3, -1.45, Z_WALL + 3 * CR_H + 0.22), (0.4, 0.4, 0.4), rnd, tilt=14.0)

    if not broken:
        # piatra de cheie: placa plata care inchide golul ramas intre ultimele randuri
        bx(S, -CAP_HALF, CAP_HALF, -HL, HL, Z_CAP, TOP_V)
        wall_faces(S, -CAP_HALF, CAP_HALF, -HL, HL, Z_CAP, TOP_V, ["+x", "-x"], ch=CAP_H, bw=1.2, seed=97)
        sites.append((-CAP_HALF + 0.02, CAP_HALF - 0.02, -HL + 0.2, HL - 0.2, TOP_V))
        scatter_lichen(L, sites, 16, 16, seed=19)
    else:
        scatter_lichen(L, sites, 12, 18, seed=23)
    _streaks_vault(G, lcg(33 if broken else 29), broken)
    return [S.to_object("Vault_Stone"), L.to_object("Vault_Lichen"), G.to_object("Vault_Streak")]


# =============================================================================
# 3. fallen_block
# =============================================================================

BLK_H = 1.25                          # jumatate din 2,5 m: anvelopa boulder_roller x 0,5
BLK_REL = 0.14                        # cat iese relieful din corp pe fata +Y

AO_BLOCK = dict(samples=16, dist=1.0, gradient="vertical", low=0.66, high=1.0,
                power=0.85, floor=0.34, strength=1.2, z_range=(0.0, 2.5))


def build_block():
    S, L = Builder(), Builder()
    h = BLK_H
    hy = h - BLK_REL                     # corpul se opreste cu BLK_REL inaintea planului +Y
    # corp: cub cu colturile sparte in fatete mari (cate o taietura pe colt, adancimi diferite)
    chips = {(-1, -1, -1): 0.28, (1, -1, -1): 0.20, (-1, 1, -1): 0.24, (1, 1, -1): 0.34,
             (-1, -1, 1): 0.30, (1, -1, 1): 0.62, (-1, 1, 1): 0.20, (1, 1, 1): 0.48}
    pts = []
    for (sx, sy, sz), c in chips.items():
        ex, ey, ez = h, (hy if sy > 0 else h), h
        pts += [Vector((sx * (ex - c), sy * ey, sz * ez)),
                Vector((sx * ex, sy * (ey - c), sz * ez)),
                Vector((sx * ex, sy * ey, sz * (ez - c)))]
    hull(S, pts, ANK_STONE)
    # rama inalta (patru benzi) in jurul panoului, pe fata +Y
    y0, y1 = hy - 0.02, h
    ym = (y0 + y1) * 0.5
    fo, fi = 0.98, 0.76                    # jumatatea exterioara / interioara a ramei
    bx(S, -fo, fo, y0, y1, fi, fo)
    bx(S, -fo, fo, y0, y1, -fo, -fi)
    bx(S, -fo, -fi, y0, y1, -fi, fi)
    bx(S, fi, fo, y0, y1, -fi, fi)
    # boss central + rozeta: 8 petale mari si 8 mici intre ele, in relief
    S.frustum((0.0, hy + 0.05, 0.0), 0.20, 0.15, 0.12, ANK_STONE, segments=12, axis="Y")
    for ring, (r0, rm, r1, wd, hh, off) in enumerate(((0.22, 0.48, 0.72, 0.17, 0.115, 0.0),
                                                       (0.40, 0.58, 0.74, 0.10, 0.085, 0.5))):
        for k in range(8):
            a = 2.0 * math.pi * (k + off) / 8.0
            ca, sa = math.cos(a), math.sin(a)
            tx, tz = -sa, ca
            pts = []
            for rr, w_, yy in ((r0, wd * 0.45, 0.04), (rm, wd, hh), (r1, wd * 0.2, 0.05)):
                for sgn in (-1, 1):
                    pts.append(Vector((ca * rr + tx * sgn * w_, hy - 0.02, sa * rr + tz * sgn * w_)))
                    pts.append(Vector((ca * rr + tx * sgn * w_ * 0.5, hy + yy, sa * rr + tz * sgn * w_ * 0.5)))
            hull(S, pts, ANK_STONE)
    # lichen pe fata de sus (z = +h) si pe o fata laterala jos
    spots = [(0.35, -0.30, 0.34), (-0.55, 0.35, 0.28), (0.10, 0.60, 0.22), (-0.30, -0.65, 0.24)]
    for i, (px, py, r) in enumerate(spots):
        slot = ANK_LICHEN_GREEN if i % 2 else ANK_LICHEN_ORANGE
        lichen_spot(L, (px, py, h), r, r * 0.7, 0.028, slot, yaw_deg=25.0 * i, seed=40 + i)
    return [S.to_object("Block_Stone"), L.to_object("Block_Lichen")]


# =============================================================================
# 4. restoration_prop
# =============================================================================

AO_PROP = dict(samples=16, dist=1.0, gradient="vertical", low=0.62, high=1.0,
               power=0.85, floor=0.30, strength=1.3, z_range=(0.0, 3.0))
LEAN_PER_COURSE = 0.075


def build_prop():
    S, W, L = Builder(), Builder(), Builder()
    rnd = lcg(131)
    courses, ch, depth = 7, 0.42, 0.62

    def front_y(z):
        """planul din fata al peretelui inclinat (spre +Y) la cota z."""
        return depth * 0.5 + LEAN_PER_COURSE * (z / ch) ** 1.1

    # peretele: randuri de blocuri care se inclina progresiv spre +Y
    for c in range(courses):
        z0 = c * ch
        zc = z0 + ch * 0.5
        lean = LEAN_PER_COURSE * (c + 0.5) ** 1.1
        n = 3 if c % 2 else 4
        wtot = 2.6
        edges = [-wtot * 0.5 + wtot * i / n for i in range(n + 1)]
        if c % 2:
            edges = [-wtot * 0.5, -wtot * 0.5 + wtot * 0.5 / 3.0 * 1.0] + edges[1:-1] + [wtot * 0.5]
        edges = sorted(set(round(e, 3) for e in edges))
        for ua, ub in zip(edges[:-1], edges[1:]):
            if c == courses - 1 and ua > 0.2:
                continue                 # ultimul rand: spart, doar jumatate
            if ub - ua < 0.2:
                continue
            chunk(S, ((ua + ub) * 0.5, lean, zc), (ub - ua - 0.05, depth, ch - 0.04), rnd,
                  jit=0.05, yaw=(rnd() - 0.5) * 10.0, tilt=2.0)
    # un bloc cazut si moloz la picior (in spatele peretelui, pe -Y)
    chunk(S, (-0.95, -0.85, 0.28), (0.7, 0.55, 0.5), rnd, tilt=14.0)
    chunk(S, (0.35, -0.95, 0.17), (0.4, 0.35, 0.32), rnd, tilt=18.0)
    chunk(S, (1.25, -0.7, 0.2), (0.5, 0.45, 0.38), rnd, tilt=16.0)

    # lemnul: doi popi in diagonala, cu talpa la y = +1,85
    z_top = 2.0
    for sx in (-0.8, 0.8):
        foot = Vector((sx, 1.85, 0.16))
        head = Vector((sx, front_y(z_top) + 0.10, z_top))
        W.beam(foot, head, (0.22, 0.20), ANK_WOOD)
        # capul popului: o cutie scurta care intra in perete (bloc de reazem)
        W.box((sx, front_y(z_top) + 0.08, z_top + 0.05), (0.32, 0.20, 0.30), ANK_WOOD_DARK)
    # pragul de talpa si penele
    W.box((0.0, 1.85, 0.08), (2.5, 0.40, 0.16), ANK_WOOD_DARK)
    for sx in (-0.8, 0.8):
        W.box((sx, 1.52, 0.17), (0.34, 0.20, 0.09), ANK_WOOD_DARK)
    # doua scanduri-brau orizontale pe fata peretelui
    for z in (0.95, 1.95):
        W.box((0.0, front_y(z) + 0.09, z), (3.0, 0.13, 0.26), ANK_WOOD)
    # contravantuire in X intre popi (sub brau), din lemn umbrit
    W.beam(Vector((-0.8, 1.62, 0.45)), Vector((0.8, front_y(1.4) + 0.14, 1.45)), (0.12, 0.10), ANK_WOOD_DARK)
    W.beam(Vector((0.8, 1.62, 0.45)), Vector((-0.8, front_y(1.4) + 0.14, 1.45)), (0.12, 0.10), ANK_WOOD_DARK)
    # un stalp vertical scurt la capatul peretelui, ca sa se citeasca „schela”
    W.box((-1.45, front_y(1.2) + 0.12, 1.25), (0.18, 0.18, 2.5), ANK_WOOD)

    # lichen pe fete de sus ale blocurilor din perete (aproximat: creasta ultimului rand)
    top_z = courses * ch
    for i, (px, r) in enumerate(((-0.8, 0.2), (-0.1, 0.18))):
        slot = ANK_LICHEN_GREEN if i else ANK_LICHEN_ORANGE
        lichen_spot(L, (px, LEAN_PER_COURSE * 6.0 ** 1.1 - 0.08, top_z - ch * 0.0), r, r * 0.6, 0.028, slot, seed=70 + i)
    return [S.to_object("Prop_Stone"), W.to_object("Prop_Wood"), L.to_object("Prop_Lichen")]


# =============================================================================
# emisii
# =============================================================================

def emit_vault(broken):
    objs = build_vault(broken)
    emit_angkor(objs, "kit/vault_%s.glb" % ("broken" if broken else "intact"), AO_VAULT, bevel=0.0,
                bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0, anchor=(0.0, 0.0))
    clear_built()


def emit_block():
    objs = build_block()
    emit_angkor(objs, "props/fallen_block.glb", AO_BLOCK, bevel=0.0,
                bevels={"_Lichen": 0.0}, smooth_angle=45.0, anchor=(0.0, 0.0))
    clear_built()


def emit_prop():
    objs = build_prop()
    emit_angkor(objs, "props/restoration_prop.glb", AO_PROP, bevel=0.0,
                bevels={"_Lichen": 0.0}, smooth_angle=50.0)
    clear_built()


if not ONLY or ONLY == "intact":
    emit_vault(False)
if not ONLY or ONLY == "broken":
    emit_vault(True)
if not ONLY or ONLY == "block":
    emit_block()
if not ONLY or ONLY == "prop":
    emit_prop()
report_angkor()
