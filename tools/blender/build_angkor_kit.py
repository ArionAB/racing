"""Angkor -- val 3, grupul B: kitul galeriei si al templului-munte (kit angkor_kit.md §1.5).

  angkor/kit/gallery_column.glb        stalp patrat 3,5 m, baza si capitel in trepte
  angkor/kit/gallery_roof.glb          modul de acoperis L = 4,0 m (Y), in consola, pantat
  angkor/kit/gallery_relief_wall.glb   zid L = 4,0 m (X), h 3,5, gros 0,6, procesiune de apsare pe +Y
  angkor/kit/gallery_corner.glb        colt 4,0 x 4,0: doi pereti in L + acoperis cu coama frant
  angkor/kit/bakheng_terrace_tier.glb  un etaj de terasa, L = 8,0 m (X), h 1,5, in trepte pe +Y
  angkor/kit/bakheng_shrine_tower.glb  turnulet-altar de caramida, ~4 m, 2,5 x 2,5
  angkor/kit/bakheng_side_stair.glb    scara abrupta si ingusta, h ~3,0, latime 2,0

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_kit.py
`ANK_ONLY=<column|roof|wall|corner|tier|shrine|stair>` reface doar o piesa.

Axe (Blender): X latime, Y de-a lungul lantului la acoperis, Z sus. Peretele de relief
si etajul de terasa se inlantuie pe X (fata bogata pe +Y, regula kit §0.4). Originea:
baza, pe axa modulului (`anchor=(0, 0)`).

SCULPTURA E SIMPLIFICATA (decizia dezvoltatorului, kit "Datorie deschisa"): apsarele sunt
siluete de blocuri (fusta trapez, bust, brate frante, tiara), nu portrete.

CONVENTIA DE REZEMARE (galeria): stalpii stau la capetele modulelor (pas 4,0 m), cu axa pe
planul de imbinare; acoperisul se aseaza cu baza (z = 0 a modulului) la 3,5 m, peste stalpi
(x = -1,5) si peste zidul de relief (x = +1,7, grosime 0,6 => x 1,4..2,0). Capetele
modulelor sunt PLANE (la +-2,0 exact), ca doua module sa se atinga fara rost vizibil.

LISTA DE ELEMENTE, scrisa INAINTE de geometrie (decuparile din angkor_assets_v1/):

gallery_column: 1. trei trepte de baza (jumatate-latime 0,25 / 0,225 / 0,20); 2. fus patrat
  de 0,30 imbracat in 7 randuri de blocuri decalate (suprafata 0,34); 3. capitel: doua inele,
  o evazare (hull) si abacul de 0,50; 4. lichen pe trepte si abac, dara sub capitel.
gallery_roof: 1. arhitrava plata (z 0..0,28, latime 4,0, blocuri pe fetele laterale);
  2. invelisul pantat convex (profil in 6 puncte, streasina 0,28, creasta 1,85); 3. nervuri
  de tigla curbata (4, la y = -1,5 / -0,5 / 0,5 / 1,5, deci pasul trece peste rost);
  4. antefixe pe streasina, doua laturi; 5. randul de blocuri al coamei (cap 2,0 m);
  6. lichen pe coama.
gallery_relief_wall: 1. corp: soclu (0..0,55), panou retras (0,55..3,05), corni\u0219a (3,05..3,5);
  2. blocuri in relief pe soclu, corni\u0219a si spate; 3. 5 apsare pe panou (pas 0,8; centrele la
  -1,6..1,6): fusta, bru, bust, brate frante, cap, tiara inalta; relief 0,11 m; 4. dare sub
  corni\u0219a, lichen pe ea.
gallery_corner: 1. peretele E si peretele N (L), fiecare cu fata de relief spre interior (4
  apsare pe fiecare, aceeasi faza ca modulul drept); 2. acoperisul: doua prisme care se
  intersecteaza (vale la SW) + coltul de cosar la NE (min al profilelor), coame care se
  intalnesc in centru; 3. cele doua capete deschise (S si V) au profilul modulului drept.
bakheng_terrace_tier: 1. trei randuri (z 0,5 fiecare), fata trage inapoi cu 0,35 pe rand,
  spatele drept (se lipeste de deal); 2. pe fata, blocuri in relief de grosime variata, cu
  cate un bloc cazut; 3. coronament de lespezi pe muchia fiecarui rand; 4. lichen mult.
bakheng_shrine_tower: 1. soclu in 2 trepte; 2. corp patrat de caramida pe 10 randuri; 3. usa
  oarba pe +Y (ramele si buiandrugul de gresie, panoul de gresie cu 3 bare) si nise oarbe pe
  celelalte 3 fete; 4. cornisa, 3 etaje de caramida in trepte sub placi, varf de gresie.
bakheng_side_stair: 1. 12 trepte (rampa 0,22, talpa 0,27), fiecare din 2-3 lespezi;
  2. doua obraji de ziduri cu coronament, treptati; 3. lichen pe trepte si coronament.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
# helperii gopurei (bx, wall_faces, scatter_lichen, scatter_streaks, gable, hull...):
# se incarca prefixul scriptului pana la prima constructie, nu se copiaza.
_gw = open(os.path.join(_here, "build_angkor_gates_w.py"), encoding="utf-8").read()
exec(_gw[:_gw.index("# 1. aw_west_gopura")].rsplit("\n# ====", 1)[0])

ONLY = os.environ.get("ANK_ONLY", "")
ANK_BRICK = 23        # TILE_TERRACOTTA

# --- cote comune -------------------------------------------------------------

HL = 2.0                      # jumatate din lungimea modulului
Z_BEAR = 3.5                  # cota de rezemare a acoperisului (varful stalpilor si al zidului)
ROOF_Z = 2.0                  # coama peste baza acoperisului
ARCH_H = 0.28                 # arhitrava
# profilul invelisului: (distanta de la coama pe latime, cota)
PROF = [(1.92, 0.28), (1.92, 0.55), (1.55, 0.95), (1.05, 1.35), (0.60, 1.70), (0.35, 1.85)]
CAP_HW = 0.42                 # jumatate din latimea blocurilor coamei
WALL_X = 1.7                  # axa zidului de relief in galerie
COL_X = -1.5                  # axa stalpilor


def ao(top, dist=0.8, low=0.62, floor=0.30):
    return dict(samples=20, dist=dist, gradient="vertical", low=low, high=1.0,
                power=0.85, floor=floor, strength=1.3, z_range=(0.0, top))


def clear_nodes(*objs):
    return [o for o in objs if o is not None]


# =============================================================================
# 1. gallery_column
# =============================================================================

def build_column():
    S, L, G = Builder(), Builder(), Builder()
    for (z0, z1, h) in ((0.0, 0.12, 0.25), (0.12, 0.22, 0.225), (0.22, 0.32, 0.20)):
        stone_box(S, 0.0, 0.0, z0, z1, h)
    z_lo, z_hi = 0.32, 3.18
    stone_box(S, 0.0, 0.0, z_lo, z_hi, 0.15)
    block_courses(S, 0.17, z_lo, z_hi, 7, 0.34, proud=0.02, gap=0.03, seed=7)
    # capitel: doua inele, evazare, abac
    stone_box(S, 0.0, 0.0, 3.18, 3.26, 0.19)
    stone_box(S, 0.0, 0.0, 3.26, 3.32, 0.22)
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            pts.append(Vector((sx * 0.20, sy * 0.20, 3.32)))
            pts.append(Vector((sx * 0.25, sy * 0.25, 3.42)))
    hull(S, pts, ANK_STONE)
    stone_box(S, 0.0, 0.0, 3.42, 3.50, 0.25)
    # lichen pe treptele bazei si pe abac
    rnd = lcg(5)
    for (cz, hh) in ((0.12, 0.25), (0.22, 0.225), (0.32, 0.20), (3.50, 0.25)):
        for k in range(2):
            ru = 0.07 + 0.03 * rnd()
            ang = rnd() * 6.28
            r = max(hh - 0.09, 0.02)
            lichen_spot(L, (math.cos(ang) * r * 0.8, math.sin(ang) * r * 0.8, cz), ru, ru * 0.7, 0.02,
                        ANK_LICHEN_ORANGE if (k == 0 and cz < 1) else ANK_LICHEN_GREEN, seed=int(cz * 100) + k)
    # dare scurte sub capitel, pe cele patru fete
    for (yaw, px, py) in ((0.0, 0.0, 0.17), (90.0, -0.17, 0.0), (180.0, 0.0, -0.17), (270.0, 0.17, 0.0)):
        streak(G, (px, py, 3.15), yaw, 0.07, 0.22 + 0.15 * rnd(), 0.012, ANK_STREAK)
    return [S.to_object("GalleryColumn_Stone"), L.to_object("GalleryColumn_Lichen"),
            G.to_object("GalleryColumn_Streak")]


# =============================================================================
# 2. gallery_roof (+ piesele de acoperis refolosite de colt)
# =============================================================================

def _rp(axis, cross, along, z):
    """Punct pe acoperis: `cross` = pe latime, `along` = de-a lungul prismei."""
    return Vector((cross, along, z)) if axis == "y" else Vector((along, cross, z))


def roof_prism(S, axis, a0, a1, zb):
    """Invelis pantat (hull) cu capetele PLANE la a0 / a1. Arhitrava dedesubt, cu blocuri pe
    cele doua fete laterale. Intoarce nimic; adauga in S."""
    pts = []
    for sgn in (-1, 1):
        for (hx, z) in PROF:
            for a in (a0, a1):
                pts.append(_rp(axis, sgn * hx, a, zb + z))
    hull(S, pts, ANK_STONE)
    # arhitrava: corp de 3,9 + blocuri pana la 4,0
    if axis == "y":
        bx(S, -1.95, 1.95, a0, a1, zb, zb + ARCH_H)
        wall_faces(S, -1.95, 1.95, a0 - 0.02, a1 + 0.02, zb, zb + ARCH_H, ["+x", "-x"], ch=ARCH_H, bw=1.0, seed=3)
    else:
        bx(S, a0, a1, -1.95, 1.95, zb, zb + ARCH_H)
        wall_faces(S, a0 - 0.02, a1 + 0.02, -1.95, 1.95, zb, zb + ARCH_H, ["+y", "-y"], ch=ARCH_H, bw=1.0, seed=4)


def roof_ridge(S, axis, a0, a1, zb, seed=1):
    """Randul de blocuri al coamei: capete la a0/a1 EXACT, rosturi de 4 cm intre ele."""
    n = max(1, int(round((a1 - a0) / 1.0)))
    ln = (a1 - a0) / n
    rnd = lcg(seed + 90)
    for i in range(n):
        lo = a0 + i * ln + (0.02 if i > 0 else 0.0)
        hi = a0 + (i + 1) * ln - (0.02 if i < n - 1 else 0.0)
        z1 = zb + ROOF_Z - 0.01 * rnd()
        if axis == "y":
            bx(S, -CAP_HW, CAP_HW, lo, hi, zb + 1.85, z1)
        else:
            bx(S, lo, hi, -CAP_HW, CAP_HW, zb + 1.85, z1)


def roof_ribs(S, axis, positions, zb, sides=(-1, 1)):
    """Nervuri de tigla curbata: pe fiecare pozitie, cate una pe panta, curgand de la coama la streasina."""
    for p in positions:
        for sgn in sides:
            for k in range(len(PROF) - 1):
                (xa, za), (xb, zc) = PROF[k], PROF[k + 1]
                dx, dz = xb - xa, zc - za
                ln = math.hypot(dx, dz)
                nx, nz = dz / ln, -dx / ln                  # normala exterioara (partea +)
                seg = []
                for (hx, zz) in ((xa, za), (xb, zc)):
                    for da in (-0.09, 0.09):
                        seg.append(_rp(axis, sgn * hx, p + da, zb + zz))
                        seg.append(_rp(axis, sgn * (hx + nx * 0.06), p + da, zb + zz + nz * 0.06))
                hull(S, seg, ANK_STONE)


def roof_antefixes(S, axis, positions, zb):
    for p in positions:
        for sgn in (-1, 1):
            c = _rp(axis, sgn * 1.89, p, zb + ARCH_H + 0.17)
            size = (0.16, 0.16, 0.34) if axis == "y" else (0.16, 0.16, 0.34)
            S.box(c, (0.16, 0.18, 0.34) if axis == "y" else (0.18, 0.16, 0.34), ANK_STONE)


def build_roof():
    S, L = Builder(), Builder()
    roof_prism(S, "y", -HL, HL, 0.0)
    roof_ridge(S, "y", -HL, HL, 0.0)
    pos = (-1.5, -0.5, 0.5, 1.5)
    roof_ribs(S, "y", pos, 0.0)
    roof_antefixes(S, "y", pos, 0.0)
    scatter_lichen(L, [(-0.34, 0.34, -1.7, 1.7, ROOF_Z)], 6, 10, seed=31)
    return [S.to_object("GalleryRoof_Stone"), L.to_object("GalleryRoof_Lichen")]


# =============================================================================
# 3. gallery_relief_wall (+ functia de perete cu relief, refolosita de colt)
# =============================================================================

WALL_H = 3.5
Z_PLINTH, Z_CORN = 0.55, 3.05
W_BODY_BACK, W_BODY_FRONT, W_PANEL, W_FRAME, W_FIG = -0.25, 0.25, 0.18, 0.30, 0.29


def lbox(b, fr, u0, u1, w0, w1, z0, z1, slot=ANK_STONE):
    """Cutie in cadrul local `fr` (u, w, z), rotita odata cu el."""
    c = fr.p((u0 + u1) * 0.5, (w0 + w1) * 0.5, (z0 + z1) * 0.5)
    b.box(c, (u1 - u0, w1 - w0, z1 - z0), slot, rotation=fr.rot)


def lhull(b, fr, pts, slot=ANK_STONE):
    hull(b, [fr.p(u, w, z) for (u, w, z) in pts], slot)


def lcourses(b, fr, u0, u1, w_plane, direction, z0, z1, ch, bw, proud=0.05, gap=0.04, seed=0, slot=ANK_STONE):
    """Randuri de blocuri pe fata (w = w_plane) a unui corp local, cu CAPETELE FLUSH la u0/u1
    (modulul se lanteste fara rost): blocurile ies `proud` in directia `direction` (+1/-1)."""
    rnd = lcg(seed + 53)
    rows = max(1, int(round((z1 - z0) / ch)))
    rh = (z1 - z0) / rows
    for r in range(rows):
        za, zb = z0 + r * rh + gap * 0.5, z0 + (r + 1) * rh - gap * 0.5
        cuts = [u0]
        u = u0 + bw * (0.45 if r % 2 else 1.0) * (0.85 + 0.3 * rnd())
        while u < u1 - 0.35 * bw:
            cuts.append(u)
            u += bw * (0.8 + 0.4 * rnd())
        cuts.append(u1)
        for i, (ua, ub) in enumerate(zip(cuts[:-1], cuts[1:])):
            ua = ua + (gap * 0.5 if i > 0 else 0.0)
            ub = ub - (gap * 0.5 if i < len(cuts) - 2 else 0.0)
            if ub - ua < 0.1:
                continue
            wa = w_plane - 0.01 * direction
            wb = w_plane + proud * direction
            lbox(b, fr, ua, ub, min(wa, wb), max(wa, wb), za, zb, slot)


def limb(b, fr, p1, p2, th, w0, w1):
    """Bat de bratul unui personaj: hull intre doua puncte (u, z), grosime `th` pe u, adancime w0..w1."""
    pts = []
    for (u, z) in (p1, p2):
        for du in (-th * 0.5, th * 0.5):
            for w in (w0, w1):
                pts.append((u + du, w, z))
    lhull(b, fr, pts)


def apsara(b, fr, c, variant):
    """Silueta blocata de apsara pe panou: fusta trapez, bru, bust, brate frante, cap, tiara."""
    w0, w1 = W_PANEL - 0.01, W_FIG
    z = 0.62
    lbox(b, fr, c - 0.14, c + 0.14, w0, W_PANEL + 0.07, z, z + 0.14)                     # picioare / talpa
    # fusta: trapez larg jos
    lhull(b, fr, [(c - 0.25, w0, z + 0.14), (c + 0.25, w0, z + 0.14), (c - 0.25, W_PANEL + 0.08, z + 0.14),
                  (c + 0.25, W_PANEL + 0.08, z + 0.14), (c - 0.17, w0, 1.56), (c + 0.17, w0, 1.56),
                  (c - 0.17, w1 - 0.01, 1.56), (c + 0.17, w1 - 0.01, 1.56)])
    lbox(b, fr, c - 0.14, c + 0.14, w0, w1, 1.56, 1.66)                                    # bru
    lhull(b, fr, [(c - 0.13, w0, 1.66), (c + 0.13, w0, 1.66), (c - 0.13, w1, 1.66), (c + 0.13, w1, 1.66),
                  (c - 0.17, w0, 2.14), (c + 0.17, w0, 2.14), (c - 0.17, w1, 2.14), (c + 0.17, w1, 2.14)])  # bust
    # brate frante: umar -> cot -> mana (varianta alterneaza mana sus / mana la piept)
    for sgn in (-1, 1):
        sh = (c + sgn * 0.17, 2.08)
        el = (c + sgn * 0.27, 1.86 if variant else 1.96)
        ha = (c + sgn * (0.25 if variant else 0.30), 2.42 if variant else 2.34)
        limb(b, fr, sh, el, 0.085, w0, w1 - 0.02)
        limb(b, fr, el, ha, 0.085, w0, w1 - 0.02)
    lbox(b, fr, c - 0.05, c + 0.05, w0, w1 - 0.04, 2.14, 2.26)                             # gat
    lbox(b, fr, c - 0.10, c + 0.10, w0, w1, 2.26, 2.52)                                    # cap
    lbox(b, fr, c - 0.04, c + 0.04, w1 - 0.01, w1 + 0.02, 2.34, 2.42)                      # nas (blocat)
    top = 2.97 if variant else 2.92
    for (hw, za, zb) in ((0.17, 2.52, 2.62), (0.12, 2.62, 2.76), (0.07, 2.76, top)):
        lbox(b, fr, c - hw, c + hw, w0, w1 - 0.03, za, zb)


def relief_wall(S, fr, u0, u1, fig_centers, seed):
    """Perete de WALL_H cu fata de relief pe +w. Capete plane la u0/u1, grosime 0,6 in zona cadrului."""
    lbox(S, fr, u0, u1, W_BODY_BACK, W_BODY_FRONT, 0.0, Z_PLINTH)
    lbox(S, fr, u0, u1, W_BODY_BACK, W_PANEL, Z_PLINTH, Z_CORN)
    lbox(S, fr, u0, u1, W_BODY_BACK, W_BODY_FRONT, Z_CORN, WALL_H)
    lcourses(S, fr, u0, u1, W_BODY_FRONT, 1, 0.0, Z_PLINTH, Z_PLINTH, 1.1, proud=0.05, seed=seed)
    lcourses(S, fr, u0, u1, W_BODY_FRONT, 1, Z_CORN, WALL_H - 0.08, WALL_H - 0.08 - Z_CORN, 1.2, proud=0.05, seed=seed + 1)
    lbox(S, fr, u0, u1, W_BODY_BACK, W_FRAME + 0.01, WALL_H - 0.08, WALL_H)                # cornisa de sus
    lcourses(S, fr, u0, u1, W_BODY_BACK, -1, 0.0, WALL_H - 0.08, 0.7, 1.2, proud=0.05, seed=seed + 2)
    # benzi de panou: prag si buza de sus
    lbox(S, fr, u0, u1, W_PANEL - 0.01, W_PANEL + 0.04, Z_PLINTH, Z_PLINTH + 0.06)
    lbox(S, fr, u0, u1, W_PANEL - 0.01, W_PANEL + 0.04, Z_CORN - 0.06, Z_CORN)
    for i, c in enumerate(fig_centers):
        apsara(S, fr, c, (i + seed) % 2)


def build_relief_wall():
    S, L, G = Builder(), Builder(), Builder()
    fr = Frame((0.0, 0.0, 0.0), 0.0)
    relief_wall(S, fr, -HL, HL, [-1.6, -0.8, 0.0, 0.8, 1.6], 2)
    scatter_lichen(L, [(-1.8, 1.8, -0.2, 0.2, WALL_H)], 6, 10, seed=41)
    rnd = lcg(47)
    for x in (-1.2, -0.4, 0.4, 1.2):                       # dare intre apsare, sub cornisa
        streak(G, (x + 0.05 * (rnd() - 0.5), W_PANEL + 0.03, Z_CORN - 0.02), 0.0, 0.08, 0.16 + 0.12 * rnd(), 0.012, ANK_STREAK)
    for x in (-1.5, -0.3, 0.9, 1.6):                       # dare pe fata cornisei
        streak(G, (x, W_FRAME + 0.0, WALL_H - 0.1), 0.0, 0.09, 0.18 + 0.1 * rnd(), 0.012, ANK_STREAK)
    return [S.to_object("GalleryRelief_Stone"), L.to_object("GalleryRelief_Lichen"),
            G.to_object("GalleryRelief_Streak")]


# =============================================================================
# 4. gallery_corner
# =============================================================================

def build_corner():
    S, L = Builder(), Builder()
    # peretele E (x 1,4..2,0), relief spre interior (-X): cadru cu yaw 90, u = +Y
    frE = Frame((WALL_X, 0.0, 0.0), 90.0)
    relief_wall(S, frE, -HL, HL, [-1.6, -0.8, 0.0, 0.8], 7)
    # peretele N (y 1,4..2,0), relief spre interior (-Y): yaw 180, u = -X; se opreste la x = 1,4
    frN = Frame((0.0, WALL_X, 0.0), 180.0)
    relief_wall(S, frN, -1.4, HL, [1.6, 0.8, 0.0, -0.8], 9)
    zb = Z_BEAR
    # acoperisul: prisma A (ridge x=0, y in [-2,0]), prisma B (ridge y=0, x in [-2,0]), colt de cosar la NE
    roof_prism(S, "y", -HL, 0.0, zb)
    roof_prism(S, "x", -HL, 0.0, zb)
    ts = [0.0] + [p[0] for p in PROF[::-1]]
    zs = {0.0: PROF[-1][1]}
    for (t, z) in PROF:
        zs[t] = z
    pts = []
    for ti in ts:
        for tj in ts:
            if ti > 1.9 or tj > 1.9:
                continue
            pts.append(Vector((ti, tj, zb + min(zs[ti], zs[tj]))))
            pts.append(Vector((ti, tj, zb + ARCH_H)))
    pts += [Vector((1.98, 1.98, zb + ARCH_H)), Vector((1.98, 0.0, zb + 0.55)), Vector((0.0, 1.98, zb + 0.55))]
    hull(S, pts, ANK_STONE)
    # arhitrava peste colt (patratul NE) si pe tot conturul NE
    bx(S, 0.0, 1.95, 0.0, 1.95, zb, zb + ARCH_H)
    wall_faces(S, 0.0, 1.95, 0.0, 1.95, zb, zb + ARCH_H, ["+x", "+y"], ch=ARCH_H, bw=1.0, seed=5)
    roof_ridge(S, "y", -HL, CAP_HW, zb, seed=2)
    roof_ridge(S, "x", -HL, CAP_HW, zb, seed=3)
    roof_ribs(S, "y", (-1.5, -0.5), zb, sides=(1,))          # SE: panta A
    roof_ribs(S, "x", (-1.5, -0.5), zb, sides=(1,))          # NV: panta B
    roof_antefixes(S, "y", (-1.5, -0.5), zb)
    scatter_lichen(L, [(-0.34, 0.34, -1.7, 0.3, zb + ROOF_Z), (-1.7, 0.3, -0.34, 0.34, zb + ROOF_Z),
                       (1.45, 1.95, -1.7, 1.2, Z_BEAR - 0.0001)], 6, 10, seed=53)
    return [S.to_object("GalleryCorner_Stone"), L.to_object("GalleryCorner_Lichen")]


# =============================================================================
# 5. bakheng_terrace_tier
# =============================================================================

TIER_L, TIER_BACK = 4.0, -2.0         # jumatate din lungime (X), spatele terasei (Y)
TIER_FRONT = [2.0, 1.65, 1.30]        # fata fiecarui rand (+Y), se trage inapoi cu 0,35


def build_tier():
    S, L, G = Builder(), Builder(), Builder()
    rnd = lcg(61)
    sites = []
    for c in range(3):
        z0, z1 = 0.5 * c, 0.5 * (c + 1)
        yf = TIER_FRONT[c]
        zt = z1 - (0.04 if c == 2 else 0.0)
        bx(S, -TIER_L, TIER_L, TIER_BACK, yf - 0.08, z0, zt)
        if c == 2:                                            # lespezi pe fata de sus
            yy = TIER_BACK
            while yy < yf - 0.08 - 1e-6:
                yn = min(yy + 0.85 + 0.2 * rnd(), yf - 0.08)
                if yf - 0.08 - yn < 0.4:
                    yn = yf - 0.08
                u = -TIER_L
                while u < TIER_L - 1e-6:
                    nu = min(u + 1.0 + 0.7 * rnd(), TIER_L)
                    if TIER_L - nu < 0.6:
                        nu = TIER_L
                    bx(S, u + (0.02 if u > -TIER_L + 1e-6 else 0.0), nu - (0.02 if nu < TIER_L - 1e-6 else 0.0),
                       yy + (0.02 if yy > TIER_BACK else 0.0), yn - (0.02 if yn < yf - 0.08 - 1e-6 else 0.0), zt, z1)
                    u = nu
                yy = yn
        for r in range(2):                                    # doua randuri de blocuri pe fata
            za, zb_ = z0 + r * 0.25 + 0.015, z0 + (r + 1) * 0.25 - 0.015
            u = -TIER_L
            first = True
            while u < TIER_L - 1e-6:
                ln = 0.9 + 0.7 * rnd() if not (r % 2 and first) else 0.45 + 0.3 * rnd()
                first = False
                nu = min(u + ln, TIER_L)
                if TIER_L - nu < 0.55:
                    nu = TIER_L
                ua = u + (0.02 if u > -TIER_L + 1e-6 else 0.0)
                ub = nu - (0.02 if nu < TIER_L - 1e-6 else 0.0)
                proud = 0.03 + 0.06 * rnd()
                # un bloc din sapte lipseste (rost adanc), la fiecare cate un loc
                if (ub - ua) > 0.5 and rnd() < 0.12 and ua > -TIER_L + 0.5 and ub < TIER_L - 0.5:
                    pass
                else:
                    bx(S, ua, ub, yf - 0.08 - 0.005, yf - 0.08 + proud, za, zb_)
                u = nu
        # coronament pe muchia randului: lespezi plate
        u = -TIER_L
        while u < TIER_L - 1e-6:
            ln = 1.1 + 0.6 * rnd()
            nu = min(u + ln, TIER_L)
            if TIER_L - nu < 0.6:
                nu = TIER_L
            ua = u + (0.02 if u > -TIER_L + 1e-6 else 0.0)
            ub = nu - (0.02 if nu < TIER_L - 1e-6 else 0.0)
            bx(S, ua, ub, yf - 0.20, yf + 0.04, z1 - 0.07, z1)
            u = nu
        # lichen pe treapta lasata liber de randul de deasupra
        y_next = TIER_FRONT[c + 1] if c < 2 else -1.6
        sites.append((-3.5, 3.5, y_next + 0.04, yf - 0.24, z1))
    scatter_lichen(L, sites, 14, 34, seed=67)
    rnd2 = lcg(71)
    for c in range(3):
        for k in range(4):
            x = -3.4 + 6.8 * (k + rnd2() * 0.6) / 4
            streak(G, (x, TIER_FRONT[c] - 0.04, 0.5 * (c + 1) - 0.08), 0.0, 0.12, 0.14 + 0.1 * rnd2(), 0.012, ANK_STREAK)
    return [S.to_object("BakhengTier_Stone"), L.to_object("BakhengTier_Lichen"),
            G.to_object("BakhengTier_Streak")]


# =============================================================================
# 6. bakheng_shrine_tower
# =============================================================================

def _niche(S, fr, hw, z0, z1, panel):
    """Rama de gresie a unei usi / nise oarbe pe fata w = 0.9 (caramida la 0,90)."""
    j = 0.11                                              # grosimea ramei in u
    for sgn in (-1, 1):
        lbox(S, fr, sgn * hw - j * 0.5 + 0.0, sgn * hw + j * 0.5, 0.88, 0.99, z0, z1 + 0.02)
    lbox(S, fr, -hw - j * 0.5, hw + j * 0.5, 0.88, 1.0, z1 + 0.02, z1 + 0.20)          # buiandrug
    lbox(S, fr, -hw - j * 0.5, hw + j * 0.5, 0.88, 1.0, z0 - 0.07, z0)                 # prag
    if panel:                                                                          # panoul usii
        lbox(S, fr, -hw + j * 0.5, hw - j * 0.5, 0.88, 0.93, z0, z1)
        for zz in (z0 + (z1 - z0) * 0.33, z0 + (z1 - z0) * 0.66):
            lbox(S, fr, -hw + j * 0.5, hw - j * 0.5, 0.92, 0.96, zz - 0.03, zz + 0.03)


def build_shrine():
    B, S, L, G = Builder(), Builder(), Builder(), Builder()
    # soclu in doua trepte (caramida)
    stepped_base(B, [(0.0, 0.25, 1.25), (0.25, 0.50, 1.10)], slot=ANK_BRICK, proud=0.04, block_w=0.4)
    # corp patrat de caramida, 10 randuri
    stone_box(B, 0.0, 0.0, 0.5, 2.4, 0.87, slot=ANK_BRICK)
    block_courses(B, 0.90, 0.5, 2.4, 10, 0.34, proud=0.03, gap=0.025, slot=ANK_BRICK, seed=3)
    # usa oarba pe +Y (k=0), nise pe celelalte fete
    _niche(S, Frame((0, 0, 0), 0.0), 0.30, 0.5, 1.62, True)
    for k in (1, 2, 3):
        _niche(S, Frame((0, 0, 0), 90.0 * k), 0.22, 0.95, 1.60, False)
    # cornisa si etajele in trepte
    stone_box(B, 0.0, 0.0, 2.4, 2.55, 1.02, slot=ANK_BRICK)
    stone_box(B, 0.0, 0.0, 2.55, 2.93, 0.74, slot=ANK_BRICK)
    block_courses(B, 0.78, 2.55, 2.93, 2, 0.34, proud=0.04, gap=0.025, slot=ANK_BRICK, seed=5)
    stone_box(B, 0.0, 0.0, 2.93, 3.05, 0.88, slot=ANK_BRICK)
    stone_box(B, 0.0, 0.0, 3.05, 3.38, 0.56, slot=ANK_BRICK)
    block_courses(B, 0.60, 3.05, 3.38, 2, 0.34, proud=0.04, gap=0.025, slot=ANK_BRICK, seed=6)
    stone_box(B, 0.0, 0.0, 3.38, 3.48, 0.70, slot=ANK_BRICK)
    stone_box(B, 0.0, 0.0, 3.48, 3.74, 0.36, slot=ANK_BRICK)
    block_courses(B, 0.40, 3.48, 3.74, 2, 0.3, proud=0.04, gap=0.025, slot=ANK_BRICK, seed=8)
    # placile cornisei si varful de gresie (trepte + boboc)
    stone_box(S, 0.0, 0.0, 3.74, 3.82, 0.50)
    lotus_bud(S, 0.0, 0.0, 3.82, 0.20, 0.30, ANK_STONE, petals=8, segments=12)
    # acroterii pe colturile cornisei
    for sx in (-1, 1):
        for sy in (-1, 1):
            S.box((sx * 0.96, sy * 0.96, 2.62), (0.12, 0.12, 0.14), ANK_STONE)
    scatter_lichen(L, [(-0.45, 0.45, -0.45, 0.45, 3.82), (-1.0, 1.0, 1.05, 1.2, 0.5), (-0.65, 0.65, -0.65, 0.65, 3.05)],
                   3, 8, seed=79)
    rnd = lcg(83)
    for (yaw, px, py) in ((0.0, 0.0, 0.93), (90.0, -0.93, 0.0), (180.0, 0.0, -0.93), (270.0, 0.93, 0.0)):
        streak(G, (px + 0.4 * (rnd() - 0.5), py, 2.38), yaw, 0.10, 0.25 + 0.15 * rnd(), 0.015, ANK_STREAK)
    return [B.to_object("BakhengShrine_Brick"), S.to_object("BakhengShrine_Stone"),
            L.to_object("BakhengShrine_Lichen"), G.to_object("BakhengShrine_Streak")]


# =============================================================================
# 7. bakheng_side_stair
# =============================================================================

ST_N, ST_RISE, ST_TREAD = 12, 0.22, 0.27
ST_Y0, ST_YB = 1.62, -1.82            # fata primei trepte (+Y) si spatele (la deal)
ST_TREAD_HW, ST_CHEEK = 0.6, 0.4      # latimea treptelor 1,2; obrajii 0,4 fiecare => 2,0


def build_stair():
    S, L, G = Builder(), Builder(), Builder()
    rnd = lcg(97)
    sites = []
    for i in range(ST_N):
        yf = ST_Y0 - i * ST_TREAD
        z0, z1 = i * ST_RISE, (i + 1) * ST_RISE
        n = 2 + (i % 2)
        cuts = [-ST_TREAD_HW + 2 * ST_TREAD_HW * k / n + (0.0 if k in (0, n) else (rnd() - 0.5) * 0.12) for k in range(n + 1)]
        for ua, ub in zip(cuts[:-1], cuts[1:]):
            dz = (rnd() - 0.5) * 0.02
            bx(S, ua + 0.015, ub - 0.015, ST_YB, yf + 0.02 * rnd(), z0, z1 + dz)
        sites.append((-0.5, 0.5, yf - ST_TREAD + 0.05, yf - 0.05, z1))
        # obrajii: bloc inferior + coronament mai lat
        ycell0 = ST_YB if i == ST_N - 1 else yf - ST_TREAD
        for sgn in (-1, 1):
            xa, xb = (ST_TREAD_HW, ST_TREAD_HW + ST_CHEEK) if sgn > 0 else (-ST_TREAD_HW - ST_CHEEK, -ST_TREAD_HW)
            ztop = z1 + 0.15
            zr = 0.0
            while zr < ztop - 1e-6:
                zn = min(zr + 0.30, ztop)
                if ztop - zn < 0.12:
                    zn = ztop
                bx(S, xa + 0.01, xb - 0.01, ycell0 + 0.01, yf - 0.005, zr + 0.01, zn - 0.01 if zn < ztop else zn)
                zr = zn
            bx(S, xa - 0.0, xb + 0.0, ycell0, yf + 0.02, ztop, ztop + 0.15)
            if i % 3 == 1:
                sites.append((min(xa, xb) + 0.03, max(xa, xb) - 0.03, ycell0 + 0.03, yf - 0.03, ztop + 0.15))
    # umplutura sub obraji (sub primul bloc) deja acoperita de blocurile inferioare; fete exterioare:
    scatter_lichen(L, sites, 8, 18, seed=101)
    for k in range(5):
        i = 2 + 2 * k
        sgn = 1 if k % 2 else -1
        streak(G, (sgn * (ST_TREAD_HW + ST_CHEEK), ST_Y0 - i * ST_TREAD - 0.15, (i + 1) * ST_RISE + 0.28),
               270.0 if sgn > 0 else 90.0, 0.12, 0.22 + 0.12 * rnd(), 0.012, ANK_STREAK)
    return [S.to_object("BakhengStair_Stone"), L.to_object("BakhengStair_Lichen"),
            G.to_object("BakhengStair_Streak")]


# =============================================================================
# emisii
# =============================================================================

def _emit(name, objs, ao_d, anchor=(0.0, 0.0), smooth=50.0):
    emit_angkor(objs, "kit/%s.glb" % name, ao_d, bevel=0.0,
                bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=smooth, anchor=anchor)
    clear_built()


if not ONLY or ONLY == "column":
    _emit("gallery_column", build_column(), ao(3.5, dist=0.5), smooth=45.0)
if not ONLY or ONLY == "roof":
    _emit("gallery_roof", build_roof(), ao(2.0, dist=0.7))
if not ONLY or ONLY == "wall":
    _emit("gallery_relief_wall", build_relief_wall(), ao(3.5, dist=0.4, low=0.58), smooth=50.0)
if not ONLY or ONLY == "corner":
    _emit("gallery_corner", build_corner(), ao(5.5, dist=0.8))
if not ONLY or ONLY == "tier":
    _emit("bakheng_terrace_tier", build_tier(), ao(1.5, dist=0.5, low=0.6))
if not ONLY or ONLY == "shrine":
    _emit("bakheng_shrine_tower", build_shrine(), ao(4.0, dist=0.5), smooth=45.0)
if not ONLY or ONLY == "stair":
    _emit("bakheng_side_stair", build_stair(), ao(3.0, dist=0.5, low=0.6))
report_angkor()
