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
    """Creasta lunga si ingusta: profil dreptunghiular in plan (X=lungime,
    Y=adancime), cu pereti VERTICALI pe ambele laturi lungi (+-Y) si capete
    inchise pe X — deci un volum complet, citit corect din orice yaw.

    Construita din INELE pe lungime (COLS coloane), fiecare cu propriul
    profil in sectiune (creasta + doua taluzuri), cusute intre ele — acelasi
    tipar ca `gorge_far_wall`, dar profilul de sectiune e acum SIMETRIC (doua
    fete abrupte), nu concav-cu-spate-plat."""
    b = Builder()
    rnd = _lcg(seed)
    COLS = 22
    half_len = FW_LEN * 0.5
    half_d = FW_DEPTH * 0.5

    # creasta neregulata pe lungime: variatie mare (in metri), ca la Machu
    # Picchu — sub asta silueta se pierde inainte sa ajunga pe ecran.
    crest_h = []
    for i in range(COLS):
        t = i / (COLS - 1.0)
        f = (0.78 + 0.14 * math.sin(t * 5.1 + seed * 0.01)
             + 0.08 * math.sin(t * 11.3 + 1.7)) * (0.93 + rnd() * 0.14)
        crest_h.append(FW_H * max(0.55, min(1.0, f)))
    for _pass in range(2):
        sm = list(crest_h)
        for i in range(1, COLS - 1):
            crest_h[i] = (sm[i - 1] + 2.0 * sm[i] + sm[i + 1]) * 0.25
    # capetele coboara spre 0: creasta se pierde in umerii de la capat, ca
    # volumul sa se inchida curat (nu un zid cu capat taiat drept la inaltime
    # maxima)
    crest_h[0] *= 0.35
    crest_h[-1] *= 0.35
    crest_h[1] *= 0.65
    crest_h[-2] *= 0.65

    # retragerea taluzului: cat se ingusteaza fiecare coloana spre creasta
    # (simetric pe +-Y), per coloana, ca fetele sa nu fie plane perfecte
    batter = [half_d * (0.30 + rnd() * 0.20) for _ in range(COLS)]

    xs = [-half_len + FW_LEN * i / (COLS - 1.0) for i in range(COLS)]

    # profil de sectiune, per coloana: talpa (+-half_d), un rand la mijloc
    # (taluz), creasta (0, crest_h) — o pana simetrica, nu un dreptunghi cu
    # muchii verticale (silueta de creasta, nu de cladire).
    cols = []
    for i, x in enumerate(xs):
        h = crest_h[i]
        bd = batter[i]
        y_mid = half_d - bd * 0.55
        z_mid = h * 0.42
        cols.append([
            Vector((x, -half_d, 0.0)),
            Vector((x, -y_mid, z_mid)),
            Vector((x, 0.0, h)),
            Vector((x, y_mid, z_mid)),
            Vector((x, half_d, 0.0)),
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
    # talpa: inchide dedesubt (Y intre -half_d si +half_d la Z=0), ca sa nu
    # se vada prin volum de jos
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
    thread_x = [-half_len + FW_LEN * 0.32, -half_len + FW_LEN * 0.68]
    thread_w = 1.5
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

    # umar lateral, ca la Machu Picchu — o masa lipita pe flanc, silueta care
    # rupe conturul de con perfect
    sh_z = SR_H * SHOULDER
    b.rock((SR_BASE * 0.20, -SR_BASE * 0.08, sh_z * 0.5),
          (SR_BASE * 0.30, SR_BASE * 0.26, sh_z * 0.8), GNEISS,
          seed=seed + 100, segments=6, rings=3, taper=0.22, flat_top=True,
          strata_slots=(GNEISS, FOREST, GNEISS))

    # mase de padure pe flancurile joase, cateva, mari (silueta, nu detaliu)
    for k in range(5):
        a = 2.0 * math.pi * k / 5 + rnd() * 0.7
        t = 0.14 + rnd() * 0.22
        z = SR_H * t
        if t < SHOULDER:
            u = t / SHOULDER
            rs = 1.0 - 0.32 * (u ** 1.25)
        else:
            u = (t - SHOULDER) / max(1.0 - SHOULDER, 1e-6)
            rs = 0.68 * (1.0 - 0.90 * (u ** 1.05))
        r = rs * SR_BASE * 0.5 * 0.84
        s = 16.0 + rnd() * 10.0
        b.boulder((math.cos(a) * r + lean_x * (t ** 1.7),
                  math.sin(a) * r + lean_y * (t ** 2.1), z),
                 (s, s * 0.86, s * 0.44),
                 FOREST if k % 3 else FOREST_DARK,
                 seed=seed + 200 + k, segments=5, rings=2, deviation=0.18)

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
