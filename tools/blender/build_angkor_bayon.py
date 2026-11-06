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
}

AO_BAYON = dict(samples=28, dist=0.7, gradient="vertical", low=0.60, high=1.0,
                power=0.85, floor=0.30, strength=1.35, z_range=(0.0, TOP_Z))


def build_tower(name, spec):
    stone, lichen, streaks = Builder(), Builder(), Builder()
    rnd = lcg(spec["seed"])
    ledges = []       # (z suprafata, jum. exterioara, jum. interioara)
    streak_sites = [] # (z sus, jum. perete, n)

    # --- 1. baza: piramida in trepte, 3,0 m la treapta de jos ---------------------
    stepped_base(stone, BASE_STEPS)
    for (z0, z1, half), nxt in zip(BASE_STEPS, BASE_STEPS[1:] + [(1.5, 1.5, SHAFT_HALF)]):
        ledges.append((z1, half, nxt[2]))

    # --- 2. fusul ingust cu randuri de blocuri --------------------------------------
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
    for i, (th, half, ch) in enumerate(spec["tiers"]):
        z0 = z
        z = tier(stone, z0, z0 + th, half, ch)
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
