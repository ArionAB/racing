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

# nucleul fetelor si marimea lor
FACE_H = 2.2
CORE_HALF = ENV_HALF - 0.01 - FACE_DEPTH * FACE_H     # varful nasului la 1,49
Z_CHIN = 3.0
Z_FACE_TOP = 6.1

BASE_STEPS = [(0.0, 0.5, 1.50), (0.5, 1.0, 1.38), (1.0, 1.5, 1.27)]

# etajele: (inaltimea corpului, jumatate-latimea, inaltimea cornisei, frontoane+finialuri)
VARIANTE = {
    "a": dict(tiers=[(0.42, 1.12, 0.10, True), (0.38, 0.92, 0.09, True), (0.34, 0.72, 0.08, True),
                     (0.26, 0.52, 0.06, False)],
              lotus_r=0.36, petals=8, ruin=None, seed=11),
}

AO_BAYON = dict(samples=28, dist=0.7, gradient="vertical", low=0.60, high=1.0,
                power=0.85, floor=0.30, strength=1.35, z_range=(0.0, TOP_Z))


def build_tower(name, spec):
    stone, lichen, streaks = Builder(), Builder(), Builder()
    rnd = lcg(spec["seed"])
    ledges = []       # (z suprafata, jum. exterioara, jum. interioara, fara_fete)
    streak_sites = [] # (z sus, jum. perete, latura dinspre care se vede, u_min, u_max)

    # --- 1. baza -----------------------------------------------------------------
    stepped_base(stone, BASE_STEPS)
    for (z0, z1, half), nxt in zip(BASE_STEPS, BASE_STEPS[1:] + [(1.5, 1.5, 1.15)]):
        ledges.append((z1, half, nxt[2], False))

    # --- 2. soclul cu randuri de blocuri --------------------------------------------
    stone_box(stone, 0, 0, 1.5, 2.7, 1.11)
    block_courses(stone, 1.15, 1.5, 2.7, 3, 0.8, proud=0.04, seed=5)
    streak_sites.append((2.7, 1.15, 0.0, 0.9))

    # --- 3. cornisa gatului -----------------------------------------------------------
    stone_box(stone, 0, 0, 2.7, 2.85, 1.28)
    stone_box(stone, 0, 0, 2.85, Z_CHIN, 1.38)
    ledges.append((Z_CHIN, 1.38, CORE_HALF, True))

    # --- 4. treimea de mijloc: nucleu, 4 fete, 4 pilastri ----------------------------------
    stone_box(stone, 0, 0, Z_CHIN, Z_FACE_TOP, CORE_HALF)
    pil_c, pil_h = 1.32, 0.15
    for sx in (-1, 1):
        for sy in (-1, 1):
            stone_box(stone, sx * pil_c, sy * pil_c, Z_CHIN, Z_FACE_TOP - 0.10, pil_h)
            stone_box(stone, sx * pil_c, sy * pil_c, Z_FACE_TOP - 0.10, Z_FACE_TOP, pil_h + 0.0)
    face_top = 0.0
    for k in range(4):
        fr = Frame((0.0, 0.0, 0.0), 90.0 * k)
        face_top = face_relief(stone, fr.p(0.0, CORE_HALF, Z_CHIN), 90.0 * k, FACE_H)
    streak_sites.append((Z_FACE_TOP, pil_c + pil_h, 0.0, 0.0, "pilastri"))

    # --- 5. cornisa de sus a fetelor ---------------------------------------------------
    stone_box(stone, 0, 0, Z_FACE_TOP, Z_FACE_TOP + 0.10, 1.32)
    stone_box(stone, 0, 0, Z_FACE_TOP + 0.10, Z_FACE_TOP + 0.22, 1.42)
    z = Z_FACE_TOP + 0.22
    ledges.append((z, 1.42, spec["tiers"][0][1], False))

    # --- 6. etajele ---------------------------------------------------------------------
    for i, (th, half, ch, orn) in enumerate(spec["tiers"]):
        z0 = z
        z = tier(stone, z0, z0 + th, half, ch, gables=orn, corner_finials=orn)
        streak_sites.append((z0 + th, half, 0.0, 0.0))
        nxt = spec["tiers"][i + 1][1] if i + 1 < len(spec["tiers"]) else 0.40
        ledges.append((z, half + 0.10, nxt + 0.06, False))

    # --- 7. bobocul de lotus ----------------------------------------------------------------
    last_half = spec["tiers"][-1][1]
    height = TOP_Z - z
    assert height > 0.45, "etajele lasa prea putin pentru boboc: %.2f" % height
    lotus_bud(stone, 0, 0, z, height, spec["lotus_r"], petals=spec["petals"], segments=14)

    # --- 8. lichen: pete mici pe orizontale ----------------------------------------------------
    tot_len = sum(l[1] for l in ledges)
    n_orange, n_green = 44, 16
    spots = ["o"] * n_orange + ["g"] * n_green
    # amesteca determinist
    for i in range(len(spots) - 1, 0, -1):
        j = int(rnd() * (i + 1))
        spots[i], spots[j] = spots[j], spots[i]
    for si, kind in enumerate(spots):
        # alege pervazul proportional cu lungimea lui
        r = rnd() * tot_len
        acc = 0.0
        led = ledges[-1]
        for l in ledges:
            acc += l[1]
            if r <= acc:
                led = l
                break
        zs, outer, inner, keep_face = led
        wid = outer - inner
        if wid < 0.07:
            continue
        side = int(rnd() * 4)
        lim = outer - 0.12
        u = (rnd() * 2 - 1) * lim
        if keep_face and abs(u) < 0.62:
            u = math.copysign(0.62 + rnd() * (lim - 0.62), u if u != 0 else 1.0)
        rw = min(wid * 0.40, 0.09 + 0.14 * rnd())   # 0,40 * 1,12 (zgomotul) < 0,5: ramane in ledge
        ru = min(0.40, rw * (1.6 + 1.8 * rnd()), lim - abs(u) + 0.02)
        wc = inner + wid * 0.5
        fr = Frame((0, 0, 0), 90.0 * side)
        pt = fr.p(u, wc, zs)
        slot = ANK_LICHEN_ORANGE if kind == "o" else ANK_LICHEN_GREEN
        if kind == "g":
            ru, rw = ru * 1.15, rw * 1.1
        lichen_spot(lichen, (pt.x, pt.y, pt.z), ru, rw, 0.028, slot, yaw_deg=90.0 * side, seed=si)

    # --- 9. dare negre sub cornise -----------------------------------------------------------------
    for site in streak_sites:
        z_top, half = site[0], site[1]
        if len(site) == 5:           # pilastri: patru colturi, doua fete fiecare
            for sx in (-1, 1):
                for sy in (-1, 1):
                    for (ox, oy, yaw) in ((sx * (pil_c + pil_h), sy * pil_c, 270 if sx > 0 else 90),
                                          (sx * pil_c, sy * (pil_c + pil_h), 0 if sy > 0 else 180)):
                        w = 0.10 + 0.08 * rnd()
                        ln = 0.35 + 0.45 * rnd()
                        off = (rnd() - 0.5) * 0.18
                        fr = Frame((ox, oy, 0), yaw)
                        p = fr.p(off, 0.0, 0.0)
                        streak(streaks, (p.x, p.y, Z_FACE_TOP - 0.10), yaw, w, ln, 0.03, ANK_STREAK)
            continue
        for k in range(4):
            fr = Frame((0, 0, 0), 90.0 * k)
            n = 5 if half > 1.0 else 3
            for _ in range(n):
                span = half * 0.80
                u = (rnd() * 2 - 1) * span
                w = 0.09 + 0.09 * rnd()
                ln = min(0.25 + 0.45 * rnd(), 0.7 * (0.9 if half < 1.0 else 1.3))
                p = fr.p(u, half, 0.0)
                streak(streaks, (p.x, p.y, z_top - 0.02), 90.0 * k, w, ln, 0.03, ANK_STREAK)

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
