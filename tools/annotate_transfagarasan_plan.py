# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Transfagarasan, Track21): captura
# ORTOGRAFICA reala din Godot (`Snapshot.tscn -- --track=21 --no-fog`, CU
# fereastra -- memoria `snapshot-nu-merge-headless`) cu legenda desenata peste
# ea, la scara. Copie de tools/annotate_okinawa_plan.py: traseul, latimile,
# rapele si hazardele (SemaforTunel, Avalansa, OileAcPaior, Tren, Urs,
# ParaulBalea, LacBalea) se citesc DIRECT din scenes/tracks/Track21.tscn
# (memoria `diorama-din-geometria-reala`); ce nu are inca nod (barajul,
# Prometeu, Poenari, cascada, stana, satul) e marcat drept "pozitie
# planificata", din reperele fixe ale brief-ului §2.1.
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), -Z (nord) in SUS pe ecran, +x (est) la dreapta.
# Scara si offsetul se POTRIVESC automat pe pixelii de asfalt (la Okinawa
# fereastra redimensionata a dat 0,877 din formula); scriptul tipareste cat
# din traseu cade pe asfalt, ca potrivirea sa se poata verifica.
# Rulare, din radacina repo-ului:
#   python tools/annotate_transfagarasan_plan.py [snapshot.png]
import math, os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "docs/track_briefs/img/transfagarasan_plan/plan_de_sus_nofog.png"
tscn = open(ROOT + "scenes/tracks/Track21.tscn", encoding="utf-8").read()


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
k0 = H / size
px = base.convert("RGB").load()


def is_asphalt(x, y):
    if not (0 <= x < W and 0 <= y < H):
        return False
    r, g, b = px[int(x), int(y)]
    return 70 <= r <= 150 and 65 <= g <= 145 and 80 <= b <= 165 and b >= g and abs(r - g) < 25


def hits(fit, ox, oy):
    k = k0 * fit
    pts = main[::2]
    return sum(1 for p in pts if is_asphalt(W / 2 + ox + (p[0] - cx) * k, H / 2 + oy + (p[2] - cz) * k)) / len(pts)


# Potrivirea: intai scara (offset 0), apoi offsetul pe scara gasita.
best = (hits(1.0, 0, 0), 1.0, 0, 0)
for i in range(-30, 31):
    f = 1.0 + i * 0.005
    h = hits(f, 0, 0)
    if h > best[0]:
        best = (h, f, 0, 0)
for ox in range(-12, 13, 2):
    for oy in range(-12, 13, 2):
        h = hits(best[1], ox, oy)
        if h > best[0]:
            best = (h, best[1], ox, oy)
PLAN_HIT, PLAN_FIT, OX, OY = best
k = k0 * PLAN_FIT


def gpx(x, z):
    return (W / 2 + OX + (x - cx) * k, H / 2 + OY + (z - cz) * k)


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
WHITE = (245, 243, 238, 255); SNOW = (235, 240, 245, 255); CONC = (184, 180, 170, 255)
DIRT = (150, 110, 70, 255); GREEN = (40, 90, 50, 255)


def label(x, y, text, font=None, dx=10, dy=-8, col=INK):
    font = font or Fs
    tw = dr.textlength(text, font=font)
    if dx == "R":  # text terminat langa punct
        x0, y0 = x - tw - 14, y + dy
    else:
        x0, y0 = x + dx, y + dy
    dr.rectangle([x0 - 3, y0 - 1, x0 + tw + 3, y0 + 17], fill=(245, 243, 238, 215))
    dr.text((x0, y0), text, font=font, fill=col)


def ptf(frac, off=0.0):
    p = at(frac); s = side(frac)
    return gpx(p[0] + s[0] * off, p[2] + s[1] * off)


def band(f0, f1, col, w, off=0.0, steps=40):
    pts = [ptf(f0 + (f1 - f0) * i / steps, off) for i in range(steps + 1)]
    dr.line(pts, fill=col, width=w, joint="curve")


def mark(pos, fill, txt, dx=14, dy=-8, r=9, col=HAZ, font=None):
    q = gpx(pos[0], pos[2])
    dr.ellipse([q[0] - r, q[1] - r, q[0] + r, q[1] + r], fill=fill, outline=col, width=3)
    label(q[0], q[1], txt, font or F, dx=dx, dy=dy, col=col)
    return q


def mapg(x, y):  # coordonate de HARTA din brief (x est, y nord) -> lume (x, z = -y)
    return gpx(x, -y)


# --- traseul principal
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])], fill=(255, 255, 255, 140), width=3)

# --- tronsoane speciale (fractiile din Track21.tscn)
band(0.078, 0.123, CONC, 11)              # B: coronamentul barajului (latime 6)
band(0.245, 0.317, SNOW, 9, 0)            # D: urcarea, peretii de zapada spre portal
band(0.317, 0.350, (90, 70, 55, 255), 13)  # E: tunelul Capra-Balea (latime 6)
for f0, f1, s, _ in re.findall(r"Vector4\(([0-9.]+), ([0-9.]+), (-?1|0), (\d)\)",
                               re.search(r"custom_parapets = Array\[Vector4\]\(\[([^\]]*)\]\)", tscn).group(1)):
    f0, f1, s = float(f0), float(f1), int(s)
    for sd in ((1, -1) if s == 0 else (s,)):
        band(f0, f1, (194, 49, 43, 255), 3, off=sd * 8.5, steps=12)  # parapetele alb-rosii
gap = ptf(0.493, 14)
label(gap[0], gap[1], "golul din parapet (poteca ciobanilor)", dx=12, dy=-8, col=DIRT)

# --- hazardele, la pozitia nodului
st = node_origin("SemaforTunel")
mark(st, (230, 60, 50, 255), "SEMAFORUL pe stalp,", dx=16, dy=-14)
q = gpx(st[0], st[2]); label(q[0], q[1], "utilajul iese din tunel pe rosu", F, dx=16, dy=8, col=HAZ)
mark(node_origin("Urs"), (110, 70, 40, 255), "URSUL: se ridica in doua labe, traverseaza", dx=16, dy=-8)
mark(node_origin("Avalansa"), SNOW, "AVALANSA: limba de zapada peste ramura intai", dx=16, dy=-34)
mark(node_origin("OileAcPaior"), WHITE, "OILE coboara peste ramura a treia", dx="R", dy=-8)
tr = node_origin("Tren"); q = mark(tr, (60, 60, 70, 255), "TRENUL: calea ferata taie drumul in diagonala", dx=16, dy=18)
# calea ferata: axa locala Z a nodului (bazele pe randuri, memoria tscn-transform-e-pe-randuri)
bv = [float(x) for x in re.search(r'\[node name="Tren"[^\n]*\n(?:[^\[\n][^\n]*\n)*?transform = Transform3D\(([^)]*)\)', tscn).group(1).split(",")]
rail = (bv[6], bv[8])
for sgn in (-1, 1):
    a = gpx(tr[0], tr[2]); b = gpx(tr[0] + rail[0] * 120 * sgn, tr[2] + rail[1] * 120 * sgn)
    dr.line([a, b], fill=(60, 60, 70, 255), width=3)
pb = node_origin("ParaulBalea")
mark(pb, (240, 150, 40, 255), "SARITURA peste paraul Balea (podetul luat de viitura)", dx=16, dy=12)
lb = node_origin("LacBalea")
mark(lb, (63, 111, 122, 255), "LACUL BALEA (glaciar), cabana pe mal", dx=18, dy=-8, col=BLUE)

# --- repere PLANIFICATE (brief §2.1, coordonate de harta), inca fara nod
for (x, y), txt, dx, dy, col in [
        ((150, -262), "Prometeu cu fulgerul, pe pinten", 14, 8, INK),
        ((-125, -215), "cetatea POENARI: ruina pe coltul de stanca", "R", -8, INK),
        ((-30, 290), "CASCADA in trepte, padure de molid", 14, 6, BLUE),
        ((240, 5), "stana cu tarc", 12, -8, INK),
        ((-60, -240), "satul (Arefu): case cu acoperis de tabla", 12, -30, INK),
        ((215, -150), "tunelurile scurte prin pinteni", 14, -8, INK)]:
    q = mapg(x, y)
    dr.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], fill=WHITE, outline=col, width=3)
    label(q[0], q[1], txt, dx=dx, dy=dy, col=col)
q = gpx(60, -60); label(q[0], q[1], "CREASTA FAGARASULUI (stanca, zapada)", F, dx=-150, dy=0)
q = gpx(110, 150); label(q[0], q[1], "lacul VIDRARU", F, dx=-60, dy=0, col=BLUE)
q = ptf(0.123); label(q[0], q[1], "BARAJUL-ARC: drumul pe coronament, haul de 40 m la sud", dx=14, dy=-36)
q = gpx(-235, -60); label(q[0], q[1], "OLTUL", F, dx=-30, dy=0, col=BLUE)

# --- POI-urile
POI = [("A", 0.02, -24), ("B", 0.10, 24), ("C", 0.19, 26), ("D", 0.28, 26), ("E", 0.335, -26),
       ("F", 0.47, 0), ("G", 0.66, 24), ("H", 0.84, -26)]
for kk, f, off in POI:
    x, y = ptf(f, off)
    dr.ellipse([x - 16, y - 16, x + 16, y + 16], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, start, scara, soarele
for f in (0.05, 0.16, 0.22, 0.30, 0.39, 0.44, 0.52, 0.58, 0.70, 0.78, 0.92):
    p = at(f); tt = tangent(f); q = gpx(p[0], p[2])
    dr.polygon([(q[0] + tt[0] * 15, q[1] + tt[1] * 15), (q[0] - tt[1] * 7, q[1] + tt[0] * 7), (q[0] + tt[1] * 7, q[1] - tt[0] * 7)], fill=HAZ)
q = ptf(0.0); dr.line([(q[0], q[1] - 10), (q[0], q[1] + 10)], fill=HAZ, width=5)
label(q[0], q[1], "START / SOSIRE (sens ANTIORAR)", F, dx=-150, dy=22, col=HAZ)
sx, sy = 40, H - 30
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
label(20, 14, "soarele: ~25 grade, din STANGA planului, putin spre sus (VNV)", dx=0, dy=0)
label(20, 38, "SUS pe plan = NORD; drumul URCA pe latura de est (dreapta) si COBOARA prin serpentine (sus)", dx=0, dy=0)

# --- legenda
y0 = H + 12
dr.text((24, y0), "Transfagarasan (Track21) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A START in valea Argesului (jos-stanga), satul; Poenari pe stanca in spate",
        "B urcare la BARAJ si drumul PE CORONAMENT (gri): lacul la stanga, haul la dreapta",
        "C malul lacului Vidraru (lacul la stanga), tuneluri scurte, URSUL",
        "D valea Caprei in zigzag peste linia padurii: stana, PERETI DE ZAPADA",
        "E TUNELUL (maro) prin creasta, iesirea la LACUL BALEA"]
col2 = ["F SERPENTINELE: patru ace de par stivuite, parapete alb-rosii (rosu)",
        "G padurea de molid, CASCADA, SARITURA peste parau",
        "H defileul OLTULUI: raul pe dreapta (vest), TRENUL la trecerea la nivel",
        "Creasta Fagarasului = muntele din MIJLOCUL buclei (pata gri, neclara)",
        "Linia alba subtire = drumul (asfalt); benzile colorate = tronsoanele speciale"]
for i, tx in enumerate(col1):
    dr.text((24, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
for i, tx in enumerate(col2):
    dr.text((W // 2 + 10, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 24 + 12),
        "IGNORA: muntii rotunzi albi de pe margine, iarba uniforma, tufele imprastiate, utilajul parcat (placeholder) - decorul vine din assets",
        font=Fs, fill=HAZ)
dr.text((24, y0 + 40 + 6 * 24 + 12),
        "Literele, sagetile, cercurile si textul sunt LEGENDA: nu se deseneaza in diorama.",
        font=Fs, fill=HAZ)

out = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(ROOT + "docs/track_briefs/img/transfagarasan_plan", exist_ok=True)
out.save(ROOT + "docs/track_briefs/img/transfagarasan_plan/transfagarasan_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "fit =", PLAN_FIT, "offset", OX, OY,
      "pe asfalt %.0f%%" % (PLAN_HIT * 100), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
