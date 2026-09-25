"""Fiordland — Fundalul (brief §1.2, val 4 din
docs/asset_briefs/fiordland_kit.md).

  fiordland/rocks/fiordland_horizon.glb   FarWall_A, FarWall_B, SnowRidge_A, SnowRidge_B

UN SINGUR fisier, 4 noduri. Consumatorul e `Track._build_horizon` (scenes/
tracks/track.gd:4628): ia nodurile DUPA NUME (din `horizon_picks`), le asaza
pe inele la 150-300 m de centroid, le SCALEAZA 0.85-1.4x si le da un YAW
ALEATOR — deci fiecare nod trebuie sa fie un VOLUM INCHIS, lizibil din ORICE
azimut. "Flat-backed" nu merge (brief): o placa vazuta din spate da o
fatada goala.

FarWall_A/B: 180 x 45 x 70 m, creasta lunga si ingusta cu pereti ABRUPTI pe
AMBELE fete (nu doar una), benzi orizontale de padure (LOG_DARK/
TROPICAL_GREEN), fete de gneis MARBLE_GREY si 2 fire albe verticale
(FOAM_WHITE, 1.5 m late) pe fiecare fata lunga.

SnowRidge_A/B: ~90 m inalte, ~120 m baza, calota FOAM_WHITE pe treimea de
sus, apoi MARBLE_GREY, apoi padure la baza (trei etaje, memoria
`munte-flanc-nu-fundal`).

<= 5.000 tri TOTAL. FARA CloudBank (pânza billboard din cod).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_horizon.py
"""

import math
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (brief §0.4). ROCK_DARK/ROCK_LIGHT interzise.
GNEISS = MARBLE_GREY
WET_STREAK = VOLCANIC_BLACK
FOREST = TROPICAL_GREEN
FOREST_DARK = LOG_DARK
SNOW = FOAM_WHITE
SCREE = SAND_SHADOW

AO_WALL = dict(samples=12, dist=30.0, gradient="vertical",
              low=0.46, high=1.00, power=0.84, floor=0.18)
AO_RIDGE = dict(samples=12, dist=24.0, gradient="vertical",
                low=0.44, high=1.00, power=0.85, floor=0.16)


# --- FarWall_A / FarWall_B ----------------------------------------------------
#
# Contract: 180 x 45 x 70 m. VOLUM INCHIS (doua fete lungi abrupte, capete
# inchise) — nu o placa. Reteta: panza CUSUTA in jurul unui contur ingust si
# lung (ca gorge_far_wall de la Machu Picchu), dar cu DOUA fete verticale
# simetrice (nu o singura fata concava cu spate plat) — deci un profil
# aproape DREPTUNGHIULAR ingust vazut de sus (o creasta, nu un arc), cu
# creasta neregulata si taluzuri abrupte pe AMBELE laturi lungi.
FW_LEN = 180.0
FW_DEPTH = 45.0
# Contract 70 m. Masurat pe GLB, FW_H=70 direct dadea bbox 61-66 m (capetele
# coboara la 0.35x, deci varful mediu al crestei sta sub FW_H nominal) —
# ridicat proportional ca varful REAL sa cada pe ~70.
FW_H = 78.0


def _far_wall(seed, name):
    """Creasta lunga si ingusta, cu SECTIUNE VARIABILA pe toata lungimea —
    nu un profil triunghiular constant scalat doar in inaltime (defectul
    "Toblerone" semnalat de coordonator, val 4 revizuire): fiecare coloana
    isi are propria inaltime (40-70 m), propria latime de baza (30-55 m) si
    propriul taluz, iar cateva coloane impinse in afara pe fiecare parte
    (nu simetric) dau 2-3 pinteni/contraforturi vizibili in silueta. O parte
    e mai abrupta decat cealalta (batere diferita pe +Y fata de -Y), iar
    creasta e neregulata prin PERTURBATIE ADITIVA (LCG per coloana), nu
    printr-o suma de sinusoide periodice — asta era sursa dintelui de
    fierastrau regulat vizibil pe planta veche.

    Construita din INELE pe lungime (COLS coloane), cusute intre ele —
    acelasi tipar ca `gorge_far_wall`, dar profilul de sectiune e acum
    SIMETRIC pe doua fete abrupte (nu concav-cu-spate-plat), cu latimea de
    baza si taluzul variind independent de inaltime pe fiecare coloana."""
    b = Builder()
    rnd = _lcg(seed)
    COLS = 26
    half_len = FW_LEN * 0.5

    # --- inaltimea crestei: 40-70 m, perturbatie ADITIVA neperiodica (suma
    # de pasi random-walk, nu sinusoide) — o creasta reala nu repeta acelasi
    # interval la fiecare N coloane.
    h_lo, h_hi = 40.0, FW_H
    crest_h = [0.0] * COLS
    walk = (h_lo + h_hi) * 0.5
    for i in range(COLS):
        walk += (rnd() - 0.5) * 22.0
        walk = max(h_lo, min(h_hi, walk))
        crest_h[i] = walk
    for _pass in range(2):
        sm = list(crest_h)
        for i in range(1, COLS - 1):
            crest_h[i] = (sm[i - 1] + 2.0 * sm[i] + sm[i + 1]) * 0.25
    # capetele coboara, ca volumul sa se inchida curat
    crest_h[0] = h_lo * 0.5
    crest_h[-1] = h_lo * 0.5
    crest_h[1] = (crest_h[1] + h_lo) * 0.5
    crest_h[-2] = (crest_h[-2] + h_lo) * 0.5

    # --- latimea de baza: 30-55 m, INDEPENDENTA de inaltime (un varf inalt
    # nu inseamna neaparat o baza lata) — acelasi random-walk, seed diferit.
    w_lo, w_hi = 30.0, 55.0
    base_w = [0.0] * COLS
    walkw = (w_lo + w_hi) * 0.5
    for i in range(COLS):
        walkw += (rnd() - 0.5) * 14.0
        walkw = max(w_lo, min(w_hi, walkw))
        base_w[i] = walkw
    for _pass in range(2):
        sm = list(base_w)
        for i in range(1, COLS - 1):
            base_w[i] = (sm[i - 1] + 2.0 * sm[i] + sm[i + 1]) * 0.25

    # --- 2-3 pinteni pe FIECARE parte, la pozitii ALEATOARE (nu simetrice
    # intre cele doua fete): coloanele alese impinse in afara cu un bonus de
    # latime local, ca un contrafort vizibil in silueta de sus.
    def _spur_bonus(side_sign):
        bonus = [0.0] * COLS
        n_spurs = 2 + (1 if rnd() > 0.5 else 0)
        for _ in range(n_spurs):
            ci = int(2 + rnd() * (COLS - 4))
            amp = 8.0 + rnd() * 10.0
            width = 2 + int(rnd() * 2)
            for di in range(-width, width + 1):
                k = ci + di
                if 0 <= k < COLS:
                    falloff = max(0.0, 1.0 - abs(di) / (width + 1.0))
                    bonus[k] = max(bonus[k], amp * falloff)
        return bonus

    spur_plus = _spur_bonus(1.0)     # pinteni pe fata +Y
    spur_minus = _spur_bonus(-1.0)   # pinteni pe fata -Y, independenti

    # --- asimetrie: o parte mai abrupta decat cealalta (batere diferita)
    batter_plus_frac = 0.18 + rnd() * 0.10    # +Y: taluz mai INGUST (abrupt)
    batter_minus_frac = 0.34 + rnd() * 0.12   # -Y: taluz mai LARG (domol)

    xs = [-half_len + FW_LEN * i / (COLS - 1.0) for i in range(COLS)]

    # profil de sectiune, per coloana: talpa (variabila pe Y), un rand la
    # mijloc (taluz, ASIMETRIC intre +Y si -Y), creasta (0, crest_h) — deci
    # atat inaltimea CAT SI latimea/adancimea variaza independent coloana cu
    # coloana, plus pintenii impinsi in afara.
    cols = []
    for i, x in enumerate(xs):
        h = crest_h[i]
        hw = base_w[i] * 0.5
        y_plus = hw + spur_plus[i]     # talpa pe +Y, cu pinten
        y_minus = hw + spur_minus[i]   # talpa pe -Y, cu pinten propriu
        y_mid_plus = y_plus * (1.0 - batter_plus_frac)
        y_mid_minus = y_minus * (1.0 - batter_minus_frac)
        z_mid = h * (0.38 + rnd() * 0.08)
        cols.append([
            Vector((x, -y_minus, 0.0)),
            Vector((x, -y_mid_minus, z_mid)),
            Vector((x, 0.0, h)),
            Vector((x, y_mid_plus, z_mid)),
            Vector((x, y_plus, 0.0)),
        ])

    verts = [[b.bm.verts.new(p) for p in col] for col in cols]
    n_rows = len(cols[0])
    faces = []
    for i in range(COLS - 1):
        for r in range(n_rows - 1):
            f = b.bm.faces.new((verts[i][r], verts[i + 1][r],
                               verts[i + 1][r + 1], verts[i][r + 1]))
            f[b.slot] = GNEISS
            faces.append(f)
    # talpa: inchide dedesubt, urmarind latimea VARIABILA per coloana (nu un
    # dreptunghi fix) — ca sa nu se vada prin volum de jos si sa nu apara
    # trepte artificiale la talpa unde latimea sare intre coloane vecine.
    floor_faces = []
    for i in range(COLS - 1):
        f = b.bm.faces.new((verts[i][0], verts[i][-1],
                           verts[i + 1][-1], verts[i + 1][0]))
        f[b.slot] = GNEISS
        floor_faces.append(f)
    faces += floor_faces
    # capetele: inchid volumul pe X
    end0 = b.bm.faces.new(tuple(reversed(verts[0])))
    end1 = b.bm.faces.new(tuple(verts[-1]))
    end0[b.slot] = GNEISS
    end1[b.slot] = GNEISS
    faces += [end0, end1]

    # --- benzile orizontale de culoare, RETAG (zero triunghiuri) ---
    allf = [f for f in faces if f.is_valid]
    # poalele: pamant/pietris, sub 10%
    b.retag(allf, SCREE, where=lambda c, n: c.z < FW_H * 0.10)
    # padurea: banda larga, 10-55%
    b.retag(allf, FOREST, where=lambda c, n: FW_H * 0.10 <= c.z < FW_H * 0.55)
    # umbra de padure pe fetele care privesc "in jos" (aproape orizontale,
    # taluz lin) sau spre -Y
    b.retag(allf, FOREST_DARK,
           where=lambda c, n: (FW_H * 0.10 <= c.z < FW_H * 0.55
                               and (n.y < -0.3 or abs(n.z) > 0.5)))
    # creasta: gneis descoperit peste 55%
    b.retag(allf, GNEISS, where=lambda c, n: c.z >= FW_H * 0.55)

    # --- 2 fire albe verticale (FOAM_WHITE, 1.5 m late) pe FIECARE fata
    # lunga (+Y si -Y) — brief §1.2. Benzi verticale RETAG (zero triunghiuri),
    # pozitionate la 2 fractii de-a lungul lungimii, cate una pe fiecare fata.
    # LATIMEA benzii trebuie sa fie CEL PUTIN cat pasul dintre coloane
    # (FW_LEN/(COLS-1) ~= 7.2 m aici), altfel un prag de 1,5 m (litera
    # brief-ului) nu nimereste NICIODATA centrul vreunei fete — masurat
    # direct (0 fete retag-uite cu 1,5 m). Fata e unitatea cea mai fina pe
    # care banda o poate ocupa; brief-ul cere "1,5 m late" ca impresie
    # vizuala de la distanta prin ceata, nu ca toleranta geometrica exacta
    # pe o grila de 7 m.
    col_step = FW_LEN / (COLS - 1.0)
    thread_x = [-half_len + FW_LEN * 0.32, -half_len + FW_LEN * 0.68]
    thread_w = max(1.5, col_step * 1.3)
    for side in (-1.0, 1.0):
        for tx in thread_x:
            b.retag(allf, SNOW,
                   where=lambda c, n, tx=tx, side=side: (
                       abs(c.x - tx) < thread_w * 0.5
                       and n.y * side > 0.3
                       and FW_H * 0.06 < c.z < FW_H * 0.85))

    return b.to_object(name)


# --- SnowRidge_A / SnowRidge_B ------------------------------------------------
#
# Contract: ~90 m inalt, ~120 m baza. Calota FOAM_WHITE pe treimea de sus,
# apoi MARBLE_GREY, apoi padure la baza — trei etaje (memoria
# `munte-flanc-nu-fundal`). Varf ASCUTIT si aproape (con neregulat, umar
# lateral), origine la baza centrata.
# Contract ~90 m inalt, ~120 m baza. Masurat pe GLB: SR_H=84 -> bbox 84 m
# (aproape 1:1, apex-ul e chiar varful geometriei), SR_BASE=120 -> bbox
# ~105-106 m (rings-urile de sub umar nu ating raza nominala). Amandoua
# ridicate proportional.
SR_H = 90.0
SR_BASE = 137.0


def _snow_ridge(seed, name, lean_x=10.0, lean_y=4.0):
    b = Builder()
    rnd = _lcg(seed)
    segments, rings = 10, 7

    col_dev = [0.80 + rnd() * 0.22 for _ in range(segments)]
    col_dev2 = [0.86 + rnd() * 0.16 for _ in range(segments)]
    SHOULDER = 0.40

    rings_v = []
    for k in range(rings + 1):
        t = k / rings
        z = SR_H * t
        frac = t
        if frac < SHOULDER:
            u = frac / SHOULDER
            radius_scale = 1.0 - 0.32 * (u ** 1.25)
        else:
            u = (frac - SHOULDER) / max(1.0 - SHOULDER, 1e-6)
            radius_scale = 0.68 * (1.0 - 0.90 * (u ** 1.05))
        ring_dev = 0.92 + rnd() * 0.10
        lx = lean_x * (frac ** 1.7)
        ly = lean_y * (frac ** 2.1)
        ring = []
        for i in range(segments):
            a = 2.0 * math.pi * i / segments
            ca, sa = math.cos(a), math.sin(a)
            d = col_dev[i] * (1.0 - t) + col_dev2[i] * t
            r = radius_scale * ring_dev * d
            ring.append(b.bm.verts.new((lx + ca * r * SR_BASE * 0.5,
                                        ly + sa * r * SR_BASE * 0.5, z)))
        rings_v.append(ring)

    body = []
    for lo, hi in zip(rings_v, rings_v[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            body.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    base_face = b.bm.faces.new(tuple(reversed(rings_v[0])))
    apex = b.bm.verts.new((lean_x * 1.08, lean_y * 1.08, SR_H))
    tip = []
    for i in range(segments):
        j = (i + 1) % segments
        tip.append(b.bm.faces.new((rings_v[-1][i], rings_v[-1][j], apex)))

    for f in body + tip:
        f[b.slot] = GNEISS
    base_face[b.slot] = SCREE

    allf = body + tip
    # trei etaje: padure la poale, gneis la mijloc, calota alba peste 66%
    b.retag(allf, SCREE, where=lambda c, n: c.z < SR_H * 0.08)
    b.retag(allf, FOREST, where=lambda c, n: SR_H * 0.08 <= c.z < SR_H * 0.42)
    b.retag(allf, FOREST_DARK,
           where=lambda c, n: (SR_H * 0.08 <= c.z < SR_H * 0.42 and n.y < -0.35))
    b.retag(allf, GNEISS, where=lambda c, n: SR_H * 0.42 <= c.z < SR_H * 0.66)
    b.retag(allf, SNOW, where=lambda c, n: c.z >= SR_H * 0.66)

    # REVIZUIRE COORDONATOR (val 4, a doua trecere): umarul (`b.rock(...,
    # flat_top=True)`) si masele de padure pe flanc (`b.boulder()`) citeau ca
    # "cutii mici lipite pe con" in planta — la scara relativa a unui con de
    # 90 m, un `rock()`/`boulder()` de 20-30 m cu doar 5-6 segmente si
    # `flat_top` iese prea fatetat/dreptunghiular ca sa se confunde cu
    # geometria conului insusi, si se vede exact ca un corp strain lipit.
    # SCOASE complet: calota de zapada ramane retag PUR pe treimea de sus
    # (fara volum adaugat), exact contractul brief-ului. Silueta conului
    # (varf decalat, umar din PROFILUL inelelor, nu dintr-o masa separata)
    # ramane singura sursa de relief pe flanc.

    return b.to_object(name)


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(obj, path_or_none, ao, bevel=0.30, smooth_angle=26.0, origin="base_axis"):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin, smooth_angle=smooth_angle)
    results.append((obj.name, st["tris"], st["ao_min"], st["ao_max"]))
    return obj


far_a = emit(_far_wall(9101, "FarWall_A"), None, AO_WALL, bevel=0.35,
            smooth_angle=24.0)
far_b = emit(_far_wall(9202, "FarWall_B"), None, AO_WALL, bevel=0.35,
            smooth_angle=24.0)
ridge_a = emit(_snow_ridge(9301, "SnowRidge_A", lean_x=9.0, lean_y=3.0),
              None, AO_RIDGE, bevel=0.30, smooth_angle=26.0)
ridge_b = emit(_snow_ridge(9402, "SnowRidge_B", lean_x=-11.0, lean_y=5.0),
              None, AO_RIDGE, bevel=0.30, smooth_angle=26.0)

built = [far_a, far_b, ridge_a, ridge_b]
_, sz = export_glb(built, "fiordland/rocks/fiordland_horizon.glb")
print("export: fiordland/rocks/fiordland_horizon.glb (%.0f KB)" % (sz / 1024.0))

total = sum(t for _, t, _, _ in results)
print()
for name, tris, ao_lo, ao_hi in results:
    print("%-14s tris=%6d  AO %.2f..%.2f" % (name, tris, ao_lo, ao_hi))
flag = "OK" if total <= 5000 else "DEPASIT (buget 5000)"
print("TOTAL horizon: %d tris  %s" % (total, flag))

# separate in .blend, ca sa nu se suprapuna la editare
far_b.location.x = 300.0
ridge_a.location.x = 600.0
ridge_b.location.x = 900.0
save_blend(built, "fiordland_horizon.blend")
