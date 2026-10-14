# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Ha Long, Track22): captura
# ORTOGRAFICA reala din Godot (`Snapshot.tscn -- --track=22 --no-fog`, CU
# fereastra -- memoria `snapshot-nu-merge-headless`) cu legenda desenata peste
# ea, la scara. Copie de tools/annotate_transfagarasan_plan.py: traseul,
# latimile, rapele si hazardele (Ponton1-7, JoncaCanal, MaimutePerete, Maree,
# BandaDeJos, CameraGrota) se citesc DIRECT din scenes/tracks/Track22.tscn
# (memoria `diorama-din-geometria-reala`); ce nu are inca nod (satul plutitor,
# fermele de pesti, turnurile de calcar, belvederea, plaja) e marcat drept
# "pozitie planificata", din reperele fixe ale brief-ului §2.1.
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), -Z (nord) in SUS pe ecran, +x (est) la dreapta.
# Scara si offsetul se POTRIVESC automat pe pixelii de asfalt (la Okinawa
# fereastra redimensionata a dat 0,877 din formula); scriptul tipareste cat
# din traseu cade pe asfalt, ca potrivirea sa se poata verifica.
# Rulare, din radacina repo-ului:
#   python tools/annotate_halong_plan.py [snapshot.png]
import math, os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "docs/track_briefs/img/halong_plan/plan_de_sus_nofog.png"
tscn = open(ROOT + "scenes/tracks/Track22.tscn", encoding="utf-8").read()


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


# --- culori proprii Ha Long
JADE = (74, 122, 107, 255)      # apa de golf, verde-jad opac (brief §1)
LIME = (168, 164, 154, 255)     # calcar in soare
BAMBOO = (138, 126, 108, 255)   # lemnul pontoanelor
DRUM = (46, 111, 168, 255)      # butoaiele albastre de flotor (accentul pistei)

# --- traseul principal
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])],
        fill=(255, 255, 255, 140), width=3)

# --- tronsoanele de ponton, citite din NODURI (nu din fractii scrise de mana)
pont_mid = []
for i in range(1, 8):
    nm = "Ponton%d" % i
    try:
        o = node_origin(nm)
    except Exception:
        continue
    pont_mid.append(o)
    # tablierul: segmentul near_end -> far_end, local fata de nod
    blk = tscn[tscn.index('[node name="%s"' % nm):]
    blk = blk[:blk.index("\n[node ") if "\n[node " in blk else len(blk)]
    ne = re.search(r"near_end = Vector3\(([^)]*)\)", blk)
    fe = re.search(r"far_end = Vector3\(([^)]*)\)", blk)
    if ne and fe:
        a = [float(v) for v in ne.group(1).split(",")]
        b = [float(v) for v in fe.group(1).split(",")]
        p0 = gpx(o[0] + a[0], o[2] + a[2])
        p1 = gpx(o[0] + b[0], o[2] + b[2])
        dr.line([p0, p1], fill=BAMBOO, width=11)
        dr.line([p0, p1], fill=DRUM, width=3)
if pont_mid:
    q = gpx(pont_mid[0][0], pont_mid[0][2])
    label(q[0], q[1], "DRUMUL DE PONTOANE: 7 tronsoane care se LEAGANA", F,
          dx=-470, dy=-34, col=INK)
    q2 = gpx(pont_mid[3][0], pont_mid[3][2])
    label(q2[0], q2[1], "(bambus + butoaie albastre; insulite de piatra intre ele)", Fs,
          dx=-430, dy=8, col=INK)

# --- grota: tronsonul de 6 m prin baza unui turn (CameraZone da intervalul)
try:
    cz_blk = tscn[tscn.index('[node name="CameraGrota"'):]
    f0 = float(re.search(r"frac_from = ([0-9.]+)", cz_blk).group(1))
    f1 = float(re.search(r"frac_to = ([0-9.]+)", cz_blk).group(1))
    band(f0, f1, (70, 62, 58, 255), 13)
    q = ptf((f0 + f1) * 0.5, -22)
    label(q[0], q[1], "GROTA MARINA: drumul trece SUB un turn de calcar (~70 m)",
          F, dx=16, dy=-8, col=INK)
except Exception:
    pass

# --- banda de jos (scurtatura de maree), din curba nodului
try:
    bd = tscn[tscn.index('[node name="BandaDeJos"'):]
    bo = [float(v) for v in re.search(r"transform = Transform3D\(([^)]*)\)", bd).group(1).split(",")][9:12]
    bres = re.search(r'curve = SubResource\("([^"]+)"\)', bd).group(1)
    bpts = curve_points(bres)
    poly = [gpx(bo[0] + p[0], bo[2] + p[2]) for p in bpts]
    dr.line(poly, fill=(226, 196, 120, 255), width=9)
    label(poly[len(poly) // 2][0], poly[len(poly) // 2][1],
          "BANDA DE JOS: scurtatura (-33%) peste gura golfului,", F, dx=14, dy=-30, col=DIRT)
    label(poly[len(poly) // 2][0], poly[len(poly) // 2][1],
          "SUB APA la maree inalta", F, dx=14, dy=-6, col=BLUE)
except Exception:
    pass

# --- hazardele, la pozitia nodului
try:
    mark(node_origin("JoncaCanal"), (168, 80, 58, 255),
         "JONCA cu vela roşie traverseaza canalul", dx=16, dy=-8)
except Exception:
    pass
try:
    mark(node_origin("MaimutePerete"), (150, 110, 70, 255),
         "MAIMUTELE sar din peretele de calcar", dx=16, dy=12)
except Exception:
    pass
try:
    mr = node_origin("Maree")
    mark(mr, JADE, "MAREEA: ciclu de 80 s, inchide banda de jos", dx=16, dy=-28, col=BLUE)
except Exception:
    pass

# --- turnurile de calcar care EXISTA ca relief (Peaks)
for nm, txt, dx, dy in (("TurnGrota", "turnul cu GROTA", 14, -8),
                        ("TurnVest", "turn de calcar", 14, -8),
                        ("TurnSud", "turn de calcar", 14, -8),
                        ("TurnNord", "turn de calcar", 14, -8),
                        ("Insula", "INSULA: urcarea, belvederea, plaja", 14, -8)):
    try:
        o = node_origin(nm)
        q = gpx(o[0], o[2])
        dr.ellipse([q[0] - 6, q[1] - 6, q[0] + 6, q[1] + 6], fill=LIME, outline=INK, width=2)
        label(q[0], q[1], txt, Fs, dx=dx, dy=dy, col=INK)
    except Exception:
        pass

# --- repere PLANIFICATE (brief §2.1, coordonate de harta), inca fara nod
for (x, y), txt, dx, dy, col in [
        ((-366, 280), "SATUL PLUTITOR: case pe plute, ferme de pesti, barci-cos", 14, -8, INK),
        ((152, -224), "BELVEDEREA: golful intreg, turnurile in STRATURI de ceata", "R", -8, INK),
        ((212, 112), "PLAJA din caldare (nisip lent)", 14, 8, INK),
        ((430, -150), "sirul de TURNURI DE FUNDAL (3 planuri de adancime)", "R", 0, INK),
        ((38, 199), "podetul de PLUTE peste canal", 12, -26, INK)]:
    q = mapg(x, y)
    dr.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], fill=WHITE, outline=col, width=3)
    label(q[0], q[1], txt, dx=dx, dy=dy, col=col)

# --- POI-urile (fractiile din brief §2)
POI = [("A", 0.01, -26), ("B", 0.15, -26), ("C", 0.30, -26), ("D", 0.47, 26),
       ("E", 0.65, 26), ("F", 0.81, 26), ("G", 0.91, -26)]
for kk, f, off in POI:
    x, y = ptf(f, off)
    dr.ellipse([x - 16, y - 16, x + 16, y + 16], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F)
    dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, start, scara, soarele
for f in (0.05, 0.12, 0.20, 0.28, 0.36, 0.45, 0.54, 0.62, 0.70, 0.78, 0.86, 0.95):
    p = at(f); tt = tangent(f); q = gpx(p[0], p[2])
    dr.polygon([(q[0] + tt[0] * 15, q[1] + tt[1] * 15),
                (q[0] - tt[1] * 7, q[1] + tt[0] * 7),
                (q[0] + tt[1] * 7, q[1] - tt[0] * 7)], fill=HAZ)
q = ptf(0.0)
dr.line([(q[0], q[1] - 10), (q[0], q[1] + 10)], fill=HAZ, width=5)
label(q[0], q[1], "START / SOSIRE (sens ANTIORAR)", F, dx=-150, dy=22, col=HAZ)
sx, sy = 40, H - 30
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
label(20, 14, "soarele: ~30 grade, din DREAPTA planului (ESE), dimineata tarzie", dx=0, dy=0)
label(20, 38, "SUS pe plan = NORD. Apa e VERDE-JAD OPACA, nu turcoaz transparent (nu e Okinawa)", dx=0, dy=0)

# --- legenda
y0 = H + 12
dr.text((24, y0), "Ha Long (Track22) - planul REAL al pistei, vazut de sus din Godot, cu legenda",
        font=Fb, fill=INK)
col1 = ["A START pe cheiul de piatra al satului plutitor (nord-vest)",
        "B DRUMUL DE PONTOANE: 7 tronsoane care se leagana sub masa masinii",
        "C digul de piatra printre turnuri, apoi GROTA sub un turn intreg",
        "D urcarea pe insula printre ficusi, BELVEDEREA cu golful in straturi"]
col2 = ["E coborarea in doua ace de par, PLAJA din caldare (nisip lent)",
        "F canalul: podetul de plute, JONCA il taie",
        "G drumul de coasta sapat in perete, MAIMUTELE, BANDA DE JOS (galben)",
        "Turnurile de calcar = pete gri deschis; apa = verde-jad OPAC"]
for i, tx in enumerate(col1):
    dr.text((24, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
for i, tx in enumerate(col2):
    dr.text((W // 2 + 10, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 24 + 12),
        "IGNORA: stancile si cheiurile imprastiate (placeholder din kitul Okinawa), iarba uniforma - decorul vine din assets",
        font=Fs, fill=HAZ)
dr.text((24, y0 + 40 + 5 * 24 + 12),
        "Literele, sagetile, cercurile si textul sunt LEGENDA: nu se deseneaza in diorama.",
        font=Fs, fill=HAZ)

out = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(ROOT + "docs/track_briefs/img/halong_plan", exist_ok=True)
out.save(ROOT + "docs/track_briefs/img/halong_plan/halong_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "fit =", PLAN_FIT, "offset", OX, OY,
      "pe asfalt %.0f%%" % (PLAN_HIT * 100), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
