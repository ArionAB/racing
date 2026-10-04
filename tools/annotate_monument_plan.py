# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Monument Valley, Track19, GameState
# pozitia 12): captura ORTOGRAFICA reala din Godot (snapshots/<nume>.png,
# rulata cu `Snapshot.tscn -- --track=19 --no-fog`, CU fereastra -- memoria
# `snapshot-nu-merge-headless`) cu legenda desenata peste ea, la scara.
# Reteta e cea din tools/annotate_kyoto_plan.py: traseul, scurtatura,
# monolitii si hazardele se citesc DIRECT din scenes/tracks/Track19.tscn
# (memoria `diorama-din-geometria-reala`); ce nu are inca nod (postul de
# negot, drumul haboob-ului) e marcat drept "pozitie planificata".
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), -Z (nord) in SUS pe ecran, +x (est) la dreapta.
# Rulare, din radacina repo-ului:
#   python tools/annotate_monument_plan.py [snapshot.png]
import math, os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "snapshots/monument_valley.png"
tscn = open(ROOT + "scenes/tracks/Track19.tscn", encoding="utf-8").read()


def curve_points(res_id):
    blk = tscn[tscn.index('id="%s"' % res_id):]
    arr = re.search(r'"points": PackedVector3Array\(([^)]*)\)', blk).group(1)
    v = [float(x) for x in arr.split(",")]
    v = [v[i:i + 9] for i in range(0, len(v), 9)]
    return [(p[6], p[7], p[8]) for p in v]


def node_origin(name):
    m = re.search(r'\[node name="%s"[^\n]*\n(?:[^\[\n][^\n]*\n)*?transform = Transform3D\(([^)]*)\)' % name, tscn)
    v = [float(x) for x in m.group(1).split(",")]
    return (v[9], v[10], v[11])


def node_float(name, key):
    return float(re.search(r'name="%s"[^\n]*\n(?:[^\[\n][^\n]*\n)*?%s = ([0-9.\-]+)' % (name, key), tscn).group(1))


def catmull_rom(pts, closed=True, steps=12):
    out = []
    n = len(pts)
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if closed else pts[max(i - 1, 0)]
        p1 = pts[i]
        p2 = pts[(i + 1) % n] if closed else pts[min(i + 1, n - 1)]
        p3 = pts[(i + 2) % n] if closed else pts[min(i + 2, n - 1)]
        for s in range(steps):
            t = s / steps
            q = []
            for k in range(3):
                a, b, c, d = p0[k], p1[k], p2[k], p3[k]
                q.append(0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t ** 3))
            out.append(tuple(q))
    if not closed:
        out.append(pts[-1])
    return out


main = catmull_rom(curve_points("Curve3D_main"), True, 4)
n = len(main)
seg = [math.dist(main[i], main[(i + 1) % n]) for i in range(n)]
L = sum(seg)
cum = [0.0]
for x in seg:
    cum.append(cum[-1] + x)


def at(frac):
    d = (frac % 1.0) * L
    for i in range(n):
        if cum[i + 1] >= d:
            t = (d - cum[i]) / max(seg[i], 1e-6)
            a, b = main[i], main[(i + 1) % n]
            return tuple(a[k] + (b[k] - a[k]) * t for k in range(3))
    return main[-1]


def tangent(frac):
    a, b = at(frac - 0.002), at(frac + 0.002)
    v = (b[0] - a[0], b[2] - a[2])
    l = math.hypot(*v) or 1.0
    return (v[0] / l, v[1] / l)


def side(frac):  # dreapta sensului de mers, in planul xz (-Z sus pe ecran)
    tx, tz = tangent(frac)
    return (-tz, tx)


# Curba ramurii are doar punctele INTERIOARE; ramura pleaca de pe bucla la
# entry_at si revine la exit_at (TrackBranch).
shortcut = catmull_rom([at(node_float("Dunele", "entry_at"))]
    + curve_points("Curve3D_dunele") + [at(node_float("Dunele", "exit_at"))], False, 6)

bmin = (min(p[0] for p in main), min(p[2] for p in main))
bmax = (max(p[0] for p in main), max(p[2] for p in main))
cx, cz = (bmin[0] + bmax[0]) / 2, (bmin[1] + bmax[1]) / 2
ext_x, ext_z = bmax[0] - bmin[0] + 90, bmax[1] - bmin[1] + 90
base = Image.open(snap).convert("RGBA")
W, H = base.size
size = max(ext_z, ext_x / (W / H))
k = H / size


def gpx(x, z):
    return (W / 2 + (x - cx) * k, H / 2 + (z - cz) * k)


LEG_H = 330
im = Image.new("RGBA", (W, H + LEG_H), (233, 230, 222, 255))
im.paste(base, (0, 0))
ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)
try:
    F = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
    Fs = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
    Fb = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
except Exception:
    F = Fs = Fb = ImageFont.load_default()

INK = (31, 36, 32, 255); BLUE = (42, 95, 158, 255); HAZ = (214, 69, 58, 255)
WHITE = (245, 243, 238, 255); OCHRE = (168, 103, 62, 255); ROCK = (120, 45, 25, 255)
VIOLET = (110, 70, 160, 255); TEAL = (30, 110, 120, 255); ORANGE = (232, 120, 30, 255)


def dashed_poly(pts, col, dash=7, w=2):
    for a, b in zip(pts, pts[1:]):
        Lg = math.hypot(b[0] - a[0], b[1] - a[1]); m = max(1, int(Lg / dash))
        for i in range(0, m, 2):
            t0, t1 = i / m, min(1, (i + 1) / m)
            dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=w)


def label(x, y, text, font=None, dx=10, dy=-8, col=INK):
    font = font or Fs
    tw = dr.textlength(text, font=font)
    if dx == "R":  # text terminat langa punct
        x0, y0 = x - tw - 14, y + dy
    else:
        x0, y0 = x + dx, y + dy
    dr.rectangle([x0 - 3, y0 - 1, x0 + tw + 3, y0 + 17], fill=(245, 243, 238, 205))
    dr.text((x0, y0), text, font=font, fill=col)


def ptf(frac, off=0.0):
    p = at(frac); s = side(frac)
    return gpx(p[0] + s[0] * off, p[2] + s[1] * off)


def band(f0, f1, col, w, off=0.0, steps=40):
    pts = [ptf(f0 + (f1 - f0) * i / steps, off) for i in range(steps + 1)]
    dr.line(pts, fill=col, width=w, joint="curve")


def dot(pos, col, txt, dx=12, dy=-8, r=7):
    q = gpx(pos[0], pos[2])
    dr.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=col, outline=INK, width=2)
    label(q[0], q[1], txt, dx=dx, dy=dy)


# --- traseul principal, subtire alb; asfaltul (A, B, H) vs pamant (C-G)
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])], fill=(255, 255, 255, 110), width=3)
band(0.86, 1.0, (40, 40, 48, 255), 5); band(0.0, 0.137, (40, 40, 48, 255), 5)

# --- tronsoane speciale
band(0.33, 0.42, ROCK, 9)                  # defileul (pereti de 12 m)
band(0.47, 0.60, VIOLET, 7)                # cornisa: caderea e pe DREAPTA (est)
dashed_poly([gpx(p[0], p[2]) for p in shortcut], ORANGE, 6, 5)

# --- monolitii (TerrainPeak + turnul placeholder)
for nm, txt, ldx, ldy in [("WestMitten", "WEST MITTEN (45 m)", "R", -8),
                          ("EastMitten", "EAST MITTEN (42 m)", 34, 16),
                          ("Merrick", "MERRICK BUTTE (38 m)", 34, -8)]:
    o = node_origin(nm); r = node_float(nm, "radius_m"); q = gpx(o[0], o[2])
    dr.ellipse([q[0] - r * k, q[1] - r * k, q[0] + r * k, q[1] + r * k], fill=(120, 45, 25, 120), outline=INK, width=2)
    label(q[0] - (34 if ldx == "R" else 0), q[1], txt, F, dx=ldx, dy=ldy, col=ROCK)

# --- escarpa platoului de start
esc = node_origin("EscarpaA"); q = gpx(esc[0], esc[2])
label(q[0], q[1], "buza platoului (+12 m): ascunde valea pana la coama", dx=-120, dy=18)

# --- hazarde si repere din scena
for nm in ("CalC1", "CalC2", "CalG1", "CalG2"):
    q = gpx(*node_origin(nm)[0::2])
    dr.ellipse([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], fill=(90, 60, 40, 255), outline=HAZ, width=2)
q = gpx(*node_origin("CalC1")[0::2]); label(q[0], q[1], "cai in libertate (traverseaza)", dx=16, dy=-4)
q = gpx(*node_origin("CalG1")[0::2]); label(q[0], q[1], "cai in libertate", dx=16, dy=-4)
for nm, txt in (("BolovanD", "bolovan din grohotis"), ("BolovanE", "bolovan din peretele defileului")):
    q = gpx(*node_origin(nm)[0::2])
    dr.polygon([(q[0] - 8, q[1] + 7), (q[0], q[1] - 9), (q[0] + 8, q[1] + 7)], fill=ROCK, outline=HAZ)
    label(q[0], q[1], txt, dx="R", dy=8)
dot(node_origin("VartejG"), OCHRE, "vartej de praf", dx=12, dy=-8, r=6)
dot(node_origin("AlbiaG2"), TEAL, "G2: saritura peste albia SECATA (gol 8 m)", dx="R", dy=-4, r=6)

# --- arcul de gresie
q = ptf(0.434); dr.arc([q[0] - 16, q[1] - 16, q[0] + 16, q[1] + 16], 180, 360, fill=ROCK, width=5)
label(q[0], q[1], "ARC de gresie peste drum", dx=20, dy=10, col=ROCK)

# --- startul: turnul de apa, moara, postul de negot (planificat)
q = ptf(0.02, -30); label(q[0], q[1], "postul de negot, turnul de apa, moara (stanga startului)", dx=-60, dy=-40)

# --- haboob-ul: drumul PLANIFICAT, dinspre vest peste G spre est
g0, g1 = ptf(0.70, 0), ptf(0.70, 0)
a0 = (g0[0] - 230 * k, g0[1] + 10 * k); a1 = (g0[0] + 70 * k, g0[1] - 25 * k)
dashed_poly([a0, a1], OCHRE, 10, 4)
dr.polygon([(a1[0] + 10, a1[1] - 2), (a1[0] - 6, a1[1] - 10), (a1[0] - 4, a1[1] + 8)], fill=OCHRE)
label(a0[0], a0[1], "HABOOB (zid de praf 50 m), drum planificat: vine dinspre VEST, traverseaza G", dx=0, dy=-26, col=OCHRE)

# --- POI-urile (litere in cerc)
POI = [("A", 0.015, 18), ("B", 0.085, -20), ("C", 0.17, -20), ("D", 0.24, -22), ("E", 0.37, 20),
       ("E'", 0.434, -22), ("F", 0.53, -22), ("G", 0.70, 20), ("G2", 0.838, -22), ("H", 0.93, 20)]
for kk, f, off in POI:
    x, y = ptf(f, off)
    dr.ellipse([x - 16, y - 16, x + 16, y + 16], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)
mid = shortcut[len(shortcut) // 2]; q = gpx(mid[0], mid[2])
dr.ellipse([q[0] - 16, q[1] - 16, q[0] + 16, q[1] + 16], fill=WHITE, outline=ORANGE, width=3)
tw = dr.textlength("G'", font=F); dr.text((q[0] - tw / 2, q[1] - 11), "G'", font=F, fill=INK)

# --- sensul, start, scara, soarele
for f in (0.05, 0.12, 0.27, 0.40, 0.50, 0.58, 0.66, 0.78, 0.90):
    p = at(f); tt = tangent(f); q = gpx(p[0], p[2])
    dr.polygon([(q[0] + tt[0] * 15, q[1] + tt[1] * 15), (q[0] - tt[1] * 7, q[1] + tt[0] * 7), (q[0] + tt[1] * 7, q[1] - tt[0] * 7)], fill=HAZ)
q = ptf(0.0); dr.line([(q[0], q[1] - 10), (q[0], q[1] + 10)], fill=HAZ, width=5)
label(q[0], q[1], "START / SOSIRE (sens ORAR)", F, dx=-120, dy=-40, col=HAZ)
sx, sy = 80, H - 40
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
# soarele: custom_sun_rotation_deg (-18,-70,0) = din VSV, 18 grade peste orizont.
label(60, H - 110, "soarele: 18 grade, din STANGA planului, putin spre jos (VSV)", dx=0, dy=0)
label(60, H - 86, "SUS pe plan = NORD; sensul de mers: orar", dx=0, dy=0)

# --- legenda (banda de jos)
y0 = H + 12
dr.text((24, y0), "Monument Valley (Track19) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A start pe platou (+12 m), asfalt, postul de negot; viraj spre SUD pe buza platoului",
        "B COAMA: valea se deschide, Mittens in capatul dreptei US-163; coborare pe asfalt",
        "C grila pentru vite, apoi drum de PAMANT ROSU (Valley Drive) drept spre Mittens; cai",
        "D POARTA intre West Mitten (dreapta) si East Mitten (stanga), apoi viraj spre VEST",
        "E trecatoarea dintre mese (rosu-inchis gros): defileu cu pereti de 12 m; E' arcul"]
col2 = ["F cornisa Artist's Point (violet): drum pe buza mesei, caderea in vale pe DREAPTA",
        "G campia deschisa: S-uri largi pe nisip rosu, cai, vartej; HABOOB-ul trece pe aici",
        "G' scurtatura 'Dunele' (portocaliu punctat) peste dunele rosii de la Sand Springs",
        "G2 saritura peste albia secata; H asfalt din nou, urcare spre platou, soarele in spate",
        "Asfaltul = linia gri inchis (A, B, H); restul buclei e pamant rosu"]
for i, tx in enumerate(col1):
    dr.text((24, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
for i, tx in enumerate(col2):
    dr.text((W // 2 + 10, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 24 + 12),
        "IGNORA: turnurile palide si cutiile de stanca (placeholder), culoarea uniforma a terenului si golurile de decor - monolitii, mesele, vegetatia si constructiile vin din assets",
        font=Fs, fill=HAZ)
dr.text((24, y0 + 40 + 6 * 24 + 12),
        "Literele, sagetile, cercurile si textul sunt LEGENDA: nu se deseneaza in diorama.",
        font=Fs, fill=HAZ)

out = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(ROOT + "docs/track_briefs/img/monument_plan", exist_ok=True)
out.save(ROOT + "docs/track_briefs/img/monument_plan/monument_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
