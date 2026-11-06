"""Angkor -- turnurile Bayonului (brief docs/asset_briefs/angkor_kit.md §1.1).

  angkor/structures/bayon_face_tower_a.glb   pilot: 4 etaje, boboc de lotus
  angkor/structures/bayon_face_tower_b.glb   (val 1) 3 etaje, alt boboc -- doar parametri
  angkor/structures/bayon_face_tower_c.glb   (val 1) ruinat -- `ruin` in VARIANTE

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_angkor_bayon.py
Variabila de mediu ANK_ONLY=<a|b|c> reface doar piesa respectiva (b/c apar in
val 1: aici exista deja ca parametri, nu sunt livrate in pilot).

Axe: X latime, Y adancime, Z sus; fete pe ±X si ±Y (fata bogata pe +Y = -Z in
Godot). Originea pe centrul amprentei, la baza (offset calculat O DATA pe
ansamblu). Cutia contractului: 3,0 x 9,0 x 3,0 m, nimic in afara patratului.

LISTA DE ELEMENTE (decuparea `bayon_face_tower_a.png` + planșa c; corectura
din kit §1.1: TURN, nu cap -- scrisa INAINTE de geometrie):
  1. Baza in 3 trepte (0-1,5 m): 1,50 / 1,38 / 1,27 jumatate-latime, cate 0,5 m.
  2. Soclul (1,5-2,7 m): corp cu 1,15, doua cornise-nervura (la 1,95 si 2,35)
     ca sa citeasca „randuri de blocuri”; sub cornisa gresia are dare negre.
  3. Cornisa gatului (2,7-3,0 m): doua randuri, 1,28 si 1,38 -- pervazul pe care
     „stau” fetele (aici sunt petele de lichen/muschi de pe desen).
  4. TREIMEA DE MIJLOC (3,0-6,1 m): nucleu patrat de 1,19 jumatate-latime, cu
     PATRU FETE (+Y, -X, -Y, +X), fiecare ~2,2 m de la sprancene la barbie, ochi
     inchisi, nas lat, buze pline, zambet, urechi cu lobi lungi, diadema cu
     nervuri si fronton (`face_relief`). Intre fete, 4 pilastri de colt (0,4 m).
     Nasul iese 0,30 m din plan: varful la 1,49 (sub patratul de 1,5).
  5. Cornisa de sus a fetelor (6,1-6,32 m): doua randuri, 1,32 / 1,42, cu dare.
  6. 4 etaje care se ingusteaza (jum. 1,12 / 0,92 / 0,72 / 0,52 m), fiecare cu
     doua nervuri pe latura, stalpi de colt, cornisa, FRONTON in mijlocul
     laturii si finial piramidal in fiecare colt (cum are desenul).
  7. Varful: boboc de lotus (inel de baza, nucleu de revolutie cu 14 laturi,
     8 petale exterioare + 8 interioare, finial), pana la 9,0 m exact.
  8. Culori (kit §0, tabel): gresie ROCK_LIGHT 3 in `Bayon_Stone`; lichen
     portocaliu LAVA_ORANGE 30 (~44 pete mici pe orizontale) si verde
     CACTUS_GREEN 12 (~16 tufe) in `Bayon_Lichen`, sub 3% din arie; dare negre
     VOLCANIC_BLACK 20 in `Bayon_Streak`, doar pe jumatatea de sus a peretilor
     verticali, sub cornise. AO copt in vertex colors. Fara ROCK_DARK, fara alb,
     fara texturi proprii, fara urna de pe frunte (brief angkor.md §8).
  9. Segmente: boboc 14, finial 8; nimic altceva rotund.
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "angkor_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("ANK_ONLY", "")

ENV_HALF = 1.5          # patratul contractului: +-1,5 m
TOP_Z = 9.0             # inaltimea contractului

# fetele (runda 4, corectura coordonatorului): ~3,0 m sprancene-barbie, blocul
# fetelor = latimea turnului, FARA nisa si FARA pilastri
FACE_H = 3.0
CORE_HALF = ENV_HALF - 0.01 - FACE_DEPTH * FACE_H     # varful nasului la 1,49
Z_CHIN = 3.0
Z_FACE_TOP = 6.6
SHAFT_HALF = 1.20       # fusul dintre baza si fete (~2,4 m): fetele sunt UMFLATURA

BASE_STEPS = [(0.0, 0.5, 1.50), (0.5, 1.0, 1.40), (1.0, 1.5, 1.30)]

# etajele: (inaltimea corpului, jumatate-latimea, inaltimea cornisei)
VARIANTE = {
    "a": dict(tiers=[(0.36, 1.12, 0.05), (0.33, 0.92, 0.05), (0.31, 0.72, 0.05), (0.27, 0.54, 0.05)],
              lotus_r=0.36, petals=8, ruin=None, seed=11),
    # b (val 1): 3 etaje mai groase, bobocul mai lat si mai scund cu 10 petale
    "b": dict(tiers=[(0.50, 1.12, 0.06), (0.46, 0.88, 0.06), (0.42, 0.64, 0.06)],
              lotus_r=0.43, petals=10, ruin=None, seed=23),
    # c (val 1): ca a, ruinat -- colt de sus prabusit (etajele 3 si 4), nisa sparta
    # in fus (fata +Y), baza cu coltul (-X,+Y) darimat si blocuri cazute IN patrat
    "c": dict(tiers=[(0.36, 1.12, 0.05), (0.33, 0.92, 0.05), (0.31, 0.72, 0.05), (0.27, 0.54, 0.05)],
              lotus_r=0.36, petals=8, seed=37,
              ruin=dict(top_corner=(1, 1), base_corner=(-1, 1), niche_face=0,
                        niche_u=(0.05, 0.70), niche_z=(1.90, 2.30))),
}

AO_BAYON = dict(samples=28, dist=0.7, gradient="vertical", low=0.60, high=1.0,
                power=0.85, floor=0.30, strength=1.35, z_range=(0.0, TOP_Z))


def _clip_corner(p, corner, d):
    """Taie colturile `corner` = (sx, sy) cu planul vertical sx*x + sy*y = d (proiecteaza
    punctele de dincolo pe plan, pe diagonala): colt de baza darimat."""
    sx, sy = corner
    s = sx * p.x + sy * p.y
    if s > d:
        k = (s - d) * 0.5
        return Vector((p.x - sx * k, p.y - sy * k, p.z))
    return p


def broken_step(b, z0, z1, half, corner, d):
    """Treapta de baza (cutie) cu un colt taiat pe diagonala (hull pe 8 puncte)."""
    pts = [Vector((sx * half, sy * half, z)) for sx in (-1, 1) for sy in (-1, 1) for z in (z0, z1)]
    hull(b, [_clip_corner(p, corner, d) for p in pts], ANK_STONE)


def make_warp(corner, half, z_break, pull, keep=0.25):
    """Colt prabusit: punctele din coltul `corner` de deasupra cotei `z_break` coboara
    (raman `keep` din inaltimea de peste `z_break`) si se trag spre axa cu `pull` m."""
    sx, sy = corner

    def warp(p):
        if p.x * sx > 0.5 * half and p.y * sy > 0.5 * half and p.z > z_break:
            return Vector((p.x - sx * pull, p.y - sy * pull, z_break + (p.z - z_break) * keep))
        return p
    return warp


def rubble(b, corner, d_cut, rnd):
    """Blocuri cazute, LIPITE de baza, in triunghiul ramas gol la colt, TOATE in
    patratul de 3 m (verificat aici: nimic dincolo de 1,49; garda masoara din fisier)."""
    sx, sy = corner
    placed = []
    tries = 0
    while len(placed) < 11 and tries < 900:
        tries += 1
        s = d_cut + 0.15 + rnd() * 1.1               # departare pe diagonala, de la planul taierii
        a = (rnd() * 2 - 1) * (3.0 - s - 0.28)       # pozitia de-a lungul muchiei
        if abs(a) < 0.0 and False:
            continue
        x = sx * (s + a) * 0.5
        y = sy * (s - a) * 0.5
        sz = (0.42 + 0.26 * rnd(), 0.42 + 0.26 * rnd(), 0.32 + 0.20 * rnd())
        rot = (Matrix.Rotation(math.radians(rnd() * 90), 3, "Z")
               @ Matrix.Rotation(math.radians((rnd() - 0.5) * 24), 3, "X")
               @ Matrix.Rotation(math.radians((rnd() - 0.5) * 24), 3, "Y"))
        corners = [rot @ Vector((cx * sz[0] / 2, cy * sz[1] / 2, cz * sz[2] / 2))
                   for cx in (-1, 1) for cy in (-1, 1) for cz in (-1, 1)]
        zmin = min(c.z for c in corners)
        c0 = Vector((x, y, -zmin))
        stacked = len(placed) >= 7
        if stacked:
            c0.z += 0.38
        pts = [c0 + c for c in corners]
        if any(abs(p.x) > 1.485 or abs(p.y) > 1.485 for p in pts):
            continue
        # nu intra in treapta 0 (taiata) nici in baza de sus: dincolo de planul taierii
        if any(sx * p.x + sy * p.y < d_cut + 0.04 for p in pts):
            continue
        if any((c0 - q).length < 0.62 for (q, st) in placed if st == stacked):
            continue
        placed.append((c0, stacked))
        b.box(c0, sz, ANK_STONE, rotation=rot)
    return len(placed)


def _base_skip(k, ua, ub, half, corner, cut):
    """True daca blocul din fata k (u in ua..ub) ar atarna peste coltul taiat."""
    fr = Frame((0.0, 0.0, 0.0), 90.0 * k)
    sx, sy = corner
    for u in (ua, ub):
        p = fr.p(u, half, 0.0)
        if sx * p.x + sy * p.y > cut + 0.10:
            return True
    return False


def shaft_with_niche(b, ruin):
    """Fusul (1,5-2,7 m) cu o nisa SPARTA pe fata `niche_face`: miezul se opreste cu
    0,32 m mai in spate pe acea latura, iar un cadru de 4 placi (stanga, dreapta, jos,
    sus) inchide restul fetei, lasand fereastra niche_u x niche_z GOALA (adancime
    0,32 m). Blocurile din fereastra lipsesc (skip)."""
    h = SHAFT_HALF - 0.04
    dep = 0.32
    z0, z1 = 1.5, 2.7
    nk = ruin["niche_face"]
    u0, u1 = ruin["niche_u"]
    nz0, nz1 = ruin["niche_z"]
    fr = Frame((0, 0, 0), 90.0 * nk)

    def rect(ua, wa, ub, wb, za, zb):
        pa, pb = fr.p(ua, wa, 0.0), fr.p(ub, wb, 0.0)
        b.box(((pa.x + pb.x) * 0.5, (pa.y + pb.y) * 0.5, (za + zb) * 0.5),
              (abs(pb.x - pa.x), abs(pb.y - pa.y), zb - za), ANK_STONE)
    rect(-h, -h, h, h - dep, z0, z1)                 # miez retras pe fata nisei
    rect(-h, h - dep, u0, h, z0, z1)                 # cadru: stanga
    rect(u1, h - dep, h, h, z0, z1)                  # dreapta
    rect(u0, h - dep, u1, h, z0, nz0)                # jos
    rect(u0, h - dep, u1, h, nz1, z1)                # sus

    def skip(k, c, ua, ub):
        return k == nk and c == 1 and ub > u0 and ua < u1
    block_courses(b, SHAFT_HALF, z0, z1, 3, 0.8, proud=0.04, seed=5, skip=skip)


def _in_ruin(pt, ruin):
    """Pete de lichen nu stau in aer: nu in coltul de baza darimat, nu in coltul de sus."""
    sx, sy = ruin["base_corner"]
    if pt.z < 1.6 and sx * pt.x + sy * pt.y > 1.15:
        return True
    tx, ty = ruin["top_corner"]
    return pt.z > 7.1 and pt.x * tx > 0.2 and pt.y * ty > 0.2


def build_tower(name, spec):
    stone, lichen, streaks = Builder(), Builder(), Builder()
    rnd = lcg(spec["seed"])
    ledges = []       # (z suprafata, jum. exterioara, jum. interioara)
    streak_sites = [] # (z sus, jum. perete, n)

    # --- 1. baza: piramida in trepte, 3,0 m la treapta de jos ---------------------
    ruin = spec.get("ruin")
    if ruin:
        # baza ruinata: coltul (-X,+Y) darimat pe treptele 0 si 1, blocuri cazute in golul lasat
        bc = ruin["base_corner"]
        cuts = [0.95, 1.70, None]
        for i, (z0, z1, half) in enumerate(BASE_STEPS):
            if cuts[i] is None:
                stone_box(stone, 0, 0, z0, z1, half - 0.04)
                skip = None
            else:
                broken_step(stone, z0, z1, half - 0.04, bc, cuts[i] - 0.04)
                # blocurile din fata nu urca pe colt: sar cele din ultima treime spre colt
                skip = (lambda cut: lambda k, c, ua, ub: _base_skip(k, ua, ub, half, bc, cut))(cuts[i])
            block_courses(stone, half, z0, z1, 1, 0.95, proud=0.04, seed=i, skip=skip)
        rubble(stone, bc, cuts[0], lcg(spec["seed"] + 3))
    else:
        stepped_base(stone, BASE_STEPS)
    for (z0, z1, half), nxt in zip(BASE_STEPS, BASE_STEPS[1:] + [(1.5, 1.5, SHAFT_HALF)]):
        ledges.append((z1, half, nxt[2]))

    # --- 2. fusul ingust cu randuri de blocuri --------------------------------------
    if ruin:
        shaft_with_niche(stone, ruin)
    else:
        stone_box(stone, 0, 0, 1.5, 2.7, SHAFT_HALF - 0.04)
        block_courses(stone, SHAFT_HALF, 1.5, 2.7, 3, 0.8, proud=0.04, seed=5)
    streak_sites.append((2.7, SHAFT_HALF, 10))

    # --- 3. cornisa gatului ---------------------------------------------------------------
    stone_box(stone, 0, 0, 2.7, 2.85, 1.30)
    stone_box(stone, 0, 0, 2.85, Z_CHIN, 1.36)

    # --- 4. blocul fetelor: patru fete, latimea turnului, urechile la colturi ------------
    stone_box(stone, 0, 0, Z_CHIN, Z_FACE_TOP, CORE_HALF)
    for k in range(4):
        fr = Frame((0.0, 0.0, 0.0), 90.0 * k)
        face_relief(stone, fr.p(0.0, CORE_HALF, Z_CHIN), 90.0 * k, FACE_H)

    # --- 5. capacul blocului fetelor (subtire) -------------------------------------------
    stone_box(stone, 0, 0, Z_FACE_TOP, Z_FACE_TOP + 0.08, 1.31)
    z = Z_FACE_TOP + 0.08
    ledges.append((z, 1.31, spec["tiers"][0][1] + 0.05))

    # --- 6. etajele: un con din randuri ---------------------------------------------------
    n_t = len(spec["tiers"])
    for i, (th, half, ch) in enumerate(spec["tiers"]):
        z0 = z
        warp = fskip = None
        if ruin and i >= n_t - 2:
            tc = ruin["top_corner"]
            # etajul 3: colt rupt la jumatate; etajul 4: rupt de la baza lui
            warp = make_warp(tc, half, z0, 0.85 * half, keep=0.0)
            fskip = (lambda tc_: lambda sx, sy: (sx, sy) == tc_)(tc)
        z = tier(stone, z0, z0 + th, half, ch, warp=warp, finial_skip=fskip)
        if i < 2:
            streak_sites.append((z0 + th, half * 0.96, 4))
        nxt = spec["tiers"][i + 1][1] if i + 1 < len(spec["tiers"]) else 0.42
        ledges.append((z, half + 0.05, nxt))

    # --- 7. bobocul de lotus ----------------------------------------------------------------
    height = TOP_Z - z
    assert height > 0.45, "etajele lasa prea putin pentru boboc: %.2f" % height
    lotus_bud(stone, 0, 0, z, height, spec["lotus_r"], petals=spec["petals"], segments=14)

    # --- 8. lichen: pete mici pe orizontale ----------------------------------------------------
    tot_len = sum(l[1] for l in ledges)
    n_orange, n_green = 44, 16
    spots = ["o"] * n_orange + ["g"] * n_green
    for i in range(len(spots) - 1, 0, -1):
        j = int(rnd() * (i + 1))
        spots[i], spots[j] = spots[j], spots[i]
    for si, kind in enumerate(spots):
        r = rnd() * tot_len
        acc = 0.0
        led = ledges[-1]
        for l in ledges:
            acc += l[1]
            if r <= acc:
                led = l
                break
        zs, outer, inner = led
        wid = outer - inner
        if wid < 0.07:
            continue
        side = int(rnd() * 4)
        lim = outer - max(0.12, 0.2 * outer)
        u = (rnd() * 2 - 1) * lim
        rw = min(wid * 0.40, 0.09 + 0.14 * rnd())   # 0,40 * 1,12 (zgomotul) < 0,5: ramane in ledge
        ru = min(0.40, rw * (1.6 + 1.8 * rnd()), lim - abs(u) + 0.02)
        wc = inner + wid * 0.5
        fr = Frame((0, 0, 0), 90.0 * side)
        pt = fr.p(u, wc, zs)
        if ruin and _in_ruin(pt, ruin):
            continue
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        if kind == "g":
            ru, rw = ru * 1.15, rw * 1.1
        lichen_spot(lichen, (pt.x, pt.y, pt.z), ru, rw, 0.028, slot, yaw_deg=90.0 * side, seed=si)

    # --- 9. dare: putine, scurte, se subtiaza, doar sub cornisele mari --------------------------
    for (z_top, half, n) in streak_sites:
        for k in range(4):
            fr = Frame((0, 0, 0), 90.0 * k)
            cnt = n // 4 + (1 if k < n % 4 else 0)
            for _ in range(cnt):
                u = (rnd() * 2 - 1) * half * 0.6
                w = 0.18 + 0.10 * rnd()
                ln = 0.35 + 0.35 * rnd()
                p = fr.p(u, half, 0.0)
                streak(streaks, (p.x, p.y, z_top - 0.02), 90.0 * k, w, ln, 0.025, ANK_STREAK)

    objs = [stone.to_object(name + "_Stone"),
            lichen.to_object(name + "_Lichen"),
            streaks.to_object(name + "_Streak")]
    return objs


def emit(letter):
    spec = VARIANTE[letter]
    objs = build_tower("Bayon", spec)
    emit_angkor(objs, "structures/bayon_face_tower_%s.glb" % letter, AO_BAYON,
                bevel=0.0, bevels={"_Lichen": 0.0, "_Streak": 0.0}, smooth_angle=55.0)
    clear_built()


for _l in VARIANTE:
    if not ONLY or ONLY == _l:
        emit(_l)
report_angkor()
