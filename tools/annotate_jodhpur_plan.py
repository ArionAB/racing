# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Jodhpur, Track17): captura ORTOGRAFICA
# reala din Godot (snapshots/jodhpur.png, rulata cu
# `Snapshot.tscn -- --track=17 --no-fog --dusk=0`, CU fereastra — memoria
# `snapshot-nu-merge-headless`) cu legenda desenata peste ea, la scara.
# Reteta e cea din tools/annotate_fiordland_plan.py: traseul, ulicioara si
# reperele se citesc DIRECT din scenes/tracks/Track17.tscn (memoria
# `diorama-din-geometria-reala`).
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), +z in jos pe ecran, +x la dreapta. Rulare, din
# radacina repo-ului:
#   python tools/annotate_jodhpur_plan.py [snapshot.png]
import math, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "snapshots/jodhpur.png"
tscn = open(ROOT + "scenes/tracks/Track17.tscn", encoding="utf-8").read()


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


main = catmull_rom(curve_points("Curve3D_jodhpur"), True)
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


def side(frac):  # dreapta sensului de mers, in planul xz
    tx, tz = tangent(frac)
    return (-tz, tx)


# Ulicioara: capetele NU sunt desenate in curba (TrackBranch), se iau de pe
# bucla la entry_at / exit_at; punctele din mijloc sunt ale curbei.
entry = node_float("AlleyShortcut", "entry_at")
exit_ = node_float("AlleyShortcut", "exit_at")
alley = [at(entry)] + curve_points("Curve3D_alley") + [at(exit_)]
alley = catmull_rom(alley, False, 8)

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


LEG_H = 270
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
INDIGO = (70, 100, 190, 255); WHITE = (245, 243, 238, 255); MARIGOLD = (240, 160, 30, 255)


def dashed_poly(pts, col, dash=7, w=2):
    for a, b in zip(pts, pts[1:]):
        Lg = math.hypot(b[0] - a[0], b[1] - a[1]); m = max(1, int(Lg / dash))
        for i in range(0, m, 2):
            t0, t1 = i / m, min(1, (i + 1) / m)
            dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=w)


def dot(x, y, fill, r=6, ring=True):
    dr.ellipse([x - r, y - r, x + r, y + r], fill=fill, outline=HAZ if ring else INK, width=2 if ring else 1)


def label(x, y, text, font=None, dx=10, dy=-8, col=INK):
    font = font or Fs
    tw = dr.textlength(text, font=font)
    x0, y0 = x + dx, y + dy
    dr.rectangle([x0 - 3, y0 - 1, x0 + tw + 3, y0 + 17], fill=(245, 243, 238, 190))
    dr.text((x0, y0), text, font=font, fill=col)


def ptf(frac, off=0.0):
    p = at(frac); s = side(frac)
    return gpx(p[0] + s[0] * off, p[2] + s[1] * off)


# --- traseul principal si ulicioara
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])], fill=(255, 255, 255, 90), width=3)
dashed_poly([gpx(p[0], p[2]) for p in alley], INDIGO, 6, 4)
mid = gpx(alley[len(alley) // 2][0], alley[len(alley) // 2][2])
label(mid[0], mid[1], "ulicioara (scurtatura, 6,4 m intre ziduri albastre)", dx=-150, dy=22)

# --- vaca: la gura reala a ulicioarei, ~30 m dupa furca (CowGate.mouth_dist_m)
mouth_d = node_float("CowGate", "mouth_dist_m")
acc, cow = 0.0, alley[0]
for a, b in zip(alley, alley[1:]):
    acc += math.dist(a, b)
    if acc >= mouth_d:
        cow = b
        break
c = gpx(cow[0], cow[2])
dot(c[0], c[1], WHITE, 8)
label(c[0], c[1], "VACA zebu + poarta in arc de 4 m: culcata = ulicioara inchisa", dx=12, dy=-30)

# --- fortul (TerrainPeak) si fantana (TerrainHollow)
o = node_origin("FortRock"); r = node_float("FortRock", "radius_m"); g = gpx(o[0], o[2])
dr.ellipse([g[0] - r * k, g[1] - r * k, g[0] + r * k, g[1] + r * k], outline=INK, width=2)
dr.polygon([(g[0] - 10, g[1] + 9), (g[0], g[1] - 10), (g[0] + 10, g[1] + 9)], fill=(190, 90, 70, 255), outline=INK)
label(g[0], g[1], "STANCA FORTULUI (+60 m), ziduri de gresie rosie", F, dx=-90, dy=r * k * 0.62)
o = node_origin("FountainHollow"); r = node_float("FountainHollow", "radius_m"); g = gpx(o[0], o[2])
dr.ellipse([g[0] - r * k, g[1] - r * k, g[0] + r * k, g[1] + r * k], outline=INK, width=2)
label(g[0], g[1], "FANTANA IN TREPTE (groapa -9 m, apa verde la fund)", dx=-120, dy=r * k * 0.35)

# --- lacul Devkund si saritura G2 (custom_ravines 0.86-0.91)
p = ptf(0.855); label(p[0], p[1], "G2: SARITURA peste golful lacului Devkund", dx=14, dy=6)
p = ptf(0.885, -45); label(p[0], p[1], "lacul Devkund + cenotaful alb", dx=-40, dy=-40, col=BLUE)

# --- turnul cu ceas (A, pe axa dreptei H) si orasul albastru
p = ptf(0.975, -30); dot(p[0], p[1], MARIGOLD, 8)
label(p[0], p[1], "turnul cu ceas (22 m), in capatul dreptei H", dx=12, dy=-6)
q = gpx(cx - 60, cz + 30)
label(q[0], q[1], "ORASUL ALBASTRU umple interiorul buclei", F, dx=-120, dy=0, col=INDIGO)

# --- POI-urile (litere in cerc)
POI = [("A", 0.02), ("B", 0.11), ("C", 0.23), ("D", 0.30), ("E", 0.52), ("F", 0.64), ("G", 0.77), ("G2", 0.855), ("H", 0.93)]
for kk, f in POI:
    x, y = ptf(f, 16)
    dr.ellipse([x - 15, y - 15, x + 15, y + 15], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, nordul, scara, soarele
p = at(0.06); t = tangent(0.06); q = gpx(p[0], p[2])
dr.polygon([(q[0] + t[0] * 18, q[1] + t[1] * 18), (q[0] - t[1] * 8, q[1] + t[0] * 8), (q[0] + t[1] * 8, q[1] - t[0] * 8)], fill=HAZ)
label(q[0], q[1], "sens de mers", F, dx=-60, dy=-36)
p = ptf(0.0); dr.line([(p[0], p[1] - 10), (p[0], p[1] + 10)], fill=HAZ, width=4)
label(p[0], p[1], "START / SOSIRE", dx=-60, dy=14)
# Fara sageata de nord: busola din brief e oglindita fata de axele lumii
# (brief: H „spre est", pe plan merge spre STANGA), deci pe plan se scrie
# doar stanga/dreapta, ca ChatGPT sa nu primeasca doua orientari.
sx, sy = 80, H - 40
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
# soarele: tema jodhpur, sun_rotation_deg (-8, 90, 0): lumina merge spre -X,
# deci vine din +X = din DREAPTA planului, jos pe cer (8 grade, apus).
label(W - 470, 16, "soarele: foarte jos (8 grade, apus), din DREAPTA planului", dx=0, dy=0)

# --- legenda (banda de jos)
y0 = H + 12
dr.text((24, y0), "Jodhpur de Diwali (Track17) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A start sub turnul cu ceas, pe caldaram, rangoli pe grila, arcada portii pietei",
        "B bazarul Sardar: tarabe cu copertine, fasii de textile peste strada, sfori de becuri",
        "C fantana in trepte: coboara pe rampa, ac de par la fund, urca pe rampa opusa",
        "D orasul albastru: ulite cu case cub albastre; furca ulicioarei si vaca in gura ei"]
col2 = ["E portile fortului: zigzag pe fata stancii, 3 porti cu tepi, fiecare dupa un ac in unghi drept",
        "F bastionul: fatada palatului la 10-18 m, apoi acul lat pe varf, orasul la picioare",
        "G coborarea pe stanca goala de riolit roz-brun, spre lac si cenotaf; G2 saritura",
        "H dreapta lunga inapoi spre start, turnul cu ceas in capat, tuk-tuk-uri, candele"]
for i, t in enumerate(col1): dr.text((24, y0 + 40 + i * 24), t, font=Fs, fill=INK)
for i, t in enumerate(col2): dr.text((W // 2 + 10, y0 + 40 + i * 24), t, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 24 + 10),
        "indigo punctat = ulicioara (scurtatura)   ·   cercuri negre = stanca fortului si groapa fantanii   ·   vedere reala de sus din Godot, la scara",
        font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 24 + 10),
        "IGNORA: bilele portocalii de pe margini (fundal provizoriu) si culoarea uniforma a terenului - casele, zidurile si stanca vin din assets",
        font=Fs, fill=HAZ)

out = Image.alpha_composite(im, ov).convert("RGB")
out.save(ROOT + "docs/track_briefs/img/jodhpur_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
