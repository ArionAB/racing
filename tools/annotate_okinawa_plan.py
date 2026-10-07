# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Okinawa, Track20, GameState pozitia
# 13): captura ORTOGRAFICA reala din Godot (`Snapshot.tscn -- --track=20
# --no-fog`, CU fereastra -- memoria `snapshot-nu-merge-headless`) cu legenda
# desenata peste ea, la scara. Copie de tools/annotate_okinawa_plan.py:
# traseul, latimile, rapele si hazardele (PodMobil, Tromba, Val) se citesc
# DIRECT din scenes/tracks/Track20.tscn (memoria `diorama-din-geometria-reala`);
# ce nu are inca nod (palatul, farul, portul, stanca-inima) e marcat drept
# "pozitie planificata", din reperele fixe ale brief-ului §2.1.
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), -Z (nord) in SUS pe ecran, +x (est) la dreapta.
# Rulare, din radacina repo-ului:
#   python tools/annotate_okinawa_plan.py [snapshot.png]
import math, os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "docs/track_briefs/img/okinawa_plan/fundatie/05_plan_de_sus_nofog.png"
tscn = open(ROOT + "scenes/tracks/Track20.tscn", encoding="utf-8").read()


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


bmin = (min(p[0] for p in main), min(p[2] for p in main))
bmax = (max(p[0] for p in main), max(p[2] for p in main))
cx, cz = (bmin[0] + bmax[0]) / 2, (bmin[1] + bmax[1]) / 2
ext_x, ext_z = bmax[0] - bmin[0] + 90, bmax[1] - bmin[1] + 90
base = Image.open(snap).convert("RGBA")
W, H = base.size
size = max(ext_z, ext_x / (W / H))
# Captura fundatiei iese cu un cadru mai LARG decat formula din snapshot.gd
# (fereastra de captura nu era 1280x720 la randare, imaginea e redimensionata):
# scara MASURATA prin potrivire pe pixelii de asfalt = 0,877 din formula, offset
# ~0 (394/400 puncte ale traseului cad pe asfalt; fara corectie, ~60%). Pe o
# captura noua, cu fereastra exacta, se pune 1.0 si se verifica la fel.
PLAN_FIT = 0.877
k = H / size * PLAN_FIT


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



SAND = (222, 205, 160, 255); STONE = (150, 140, 120, 255); RED = (179, 38, 30, 255)
SEA = (25, 80, 130, 255)


def mapg(x, y):  # coordonate de HARTA din brief (x est, y nord) -> lume (x, z = -y)
    return gpx(x, -y)


# --- traseul principal
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])], fill=(255, 255, 255, 140), width=3)

# --- tronsoane speciale (fractiile din Track20.tscn)
band(0.103, 0.203, SAND, 9)               # B: aleea de nisip coraligen sub fukugi
band(0.333, 0.442, STONE, 9)              # D: zidurile curbe ale castelului
band(0.517, 0.61, VIOLET, 7, 0)           # E: cornisa, caderea in mare pe STANGA (est)
band(0.635, 0.70, (60, 60, 70, 255), 11)  # F: podul
band(0.835, 0.946, (120, 120, 120, 255), 9)  # H: digul

# --- podul ridicator + canalul cu vapoarele
pm = node_origin("PodMobil"); q = gpx(pm[0], pm[2])
dr.rectangle([q[0] - 9, q[1] - 9, q[0] + 9, q[1] + 9], fill=HAZ, outline=INK, width=2)
label(q[0], q[1], "TRAVEEA RIDICATOARE (gol 12 m)", F, dx=16, dy=-30, col=HAZ)
tt = tangent(0.669); nrm = (-tt[1], tt[0])
a0 = (q[0] - nrm[0] * 140 * k, q[1] - nrm[1] * 140 * k); a1 = (q[0] + nrm[0] * 140 * k, q[1] + nrm[1] * 140 * k)
dashed_poly([a1, a0], (255, 255, 255, 255), 10, 3)
dr.polygon([(a0[0], a0[1]), (a0[0] + 10, a0[1] - 4), (a0[0] + 4, a0[1] + 10)], fill=(255, 255, 255, 255))
label(a1[0], a1[1], "canalul: vapoarele vin din larg, trec PE SUB pod spre port", dx=10, dy=-4)

# --- tromba si valul
tr = node_origin("Tromba"); q = gpx(tr[0], tr[2])
dr.ellipse([q[0] - 9, q[1] - 9, q[0] + 9, q[1] + 9], fill=(90, 100, 120, 255), outline=HAZ, width=3)
label(q[0], q[1], "TROMBA de apa: iese din mare, traverseaza drumul de plaja", F, dx="R", dy=30, col=HAZ)
va = node_origin("Val"); q = gpx(va[0], va[2])
dr.ellipse([q[0] - 9, q[1] - 9, q[0] + 9, q[1] + 9], fill=(240, 250, 255, 255), outline=HAZ, width=3)
label(q[0], q[1], "VALUL: hula sparge peste dig, dinspre larg (SV)", F, dx="R", dy=-40, col=HAZ)

# --- repere PLANIFICATE (brief §2.1, coordonate de harta)
for (x, y), txt, dx, dy, col in [
        ((110, 285), "palatul ROSU + poarta rosie peste drum (culmea, +30 m)", 12, 4, RED),
        ((318, 170), "farul ALB pe capul de calcar", 14, -8, INK),
        ((132, -150), "PORTUL in coltul golfului: chei, barci de pescari", 12, 14, SEA),
        ((445, -300), "stanca-inima in apa", 12, -8, INK)]:
    q = mapg(x, y)
    dr.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], fill=WHITE, outline=col, width=3)
    label(q[0], q[1], txt, dx=dx, dy=dy, col=col)
q = ptf(0.30, 55); label(q[0], q[1], "trestie de zahar", dx=0, dy=0)
q = ptf(0.06, -40); label(q[0], q[1], "satul cu olane rosii", dx=-60, dy=0)

# --- POI-urile
POI = [("A", 0.02, 22), ("B", 0.15, -24), ("C", 0.27, -24), ("D", 0.39, -24), ("E", 0.55, -24),
       ("F", 0.66, 24), ("G", 0.76, -24), ("H", 0.89, 24)]
for kk, f, off in POI:
    x, y = ptf(f, off)
    dr.ellipse([x - 16, y - 16, x + 16, y + 16], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, start, scara, soarele
for f in (0.06, 0.15, 0.25, 0.36, 0.48, 0.58, 0.68, 0.79, 0.90):
    p = at(f); tt = tangent(f); q = gpx(p[0], p[2])
    dr.polygon([(q[0] + tt[0] * 15, q[1] + tt[1] * 15), (q[0] - tt[1] * 7, q[1] + tt[0] * 7), (q[0] + tt[1] * 7, q[1] - tt[0] * 7)], fill=HAZ)
q = ptf(0.0); dr.line([(q[0], q[1] - 10), (q[0], q[1] + 10)], fill=HAZ, width=5)
label(q[0], q[1], "START / SOSIRE (sens ORAR)", F, dx=-100, dy=-40, col=HAZ)
sx, sy = 40, H - 30
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
label(20, 14, "soarele: ~25 grade, din STANGA planului, putin spre jos (VSV)", dx=0, dy=0)
label(20, 38, "SUS pe plan = NORD; furtuna (taifunul) vine din DREAPTA-JOS (SE)", dx=0, dy=0)

# --- legenda
y0 = H + 12
dr.text((24, y0), "Okinawa (Track20) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A portul in coltul golfului, START spre VEST prin satul cu olane rosii",
        "B aleea de NISIP ALB (crem) sub tunelul de copaci fukugi, ziduri joase de corali",
        "C urcare prin trestie de zahar spre deal; castelul rosu in fata",
        "D zidurile CURBE de piatra ale castelului pe culme; POARTA rosie peste drum",
        "E cornisa pe faleza de calcar (violet): MAREA jos pe STANGA, farul alb"]
col2 = ["F coborare si PODUL lung, jos peste apa turcoaz; traveea din mijloc se RIDICA",
        "G insula mica: drumul de plaja, pandanus, stanca-inima; TROMBA de apa",
        "H DIGUL jos cu TETRAPOZI spre larg (stanga); golful turcoaz pe dreapta; VALUL",
        "Golful (turcoaz, in interior) e legat de larg DOAR prin canalul de sub pod",
        "Linia alba subtire = drumul (asfalt); benzile colorate = tronsoanele speciale"]
for i, tx in enumerate(col1):
    dr.text((24, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
for i, tx in enumerate(col2):
    dr.text((W // 2 + 10, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 24 + 12),
        "IGNORA: stancile gri de pe apa, tetrapozii maro si zidurile mici (placeholder), iarba uniforma, feriboturile albe - decorul vine din assets",
        font=Fs, fill=HAZ)
dr.text((24, y0 + 40 + 6 * 24 + 12),
        "Literele, sagetile, cercurile si textul sunt LEGENDA: nu se deseneaza in diorama.",
        font=Fs, fill=HAZ)

out = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(ROOT + "docs/track_briefs/img/okinawa_plan", exist_ok=True)
out.save(ROOT + "docs/track_briefs/img/okinawa_plan/okinawa_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
