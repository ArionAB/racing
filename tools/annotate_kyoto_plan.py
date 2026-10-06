# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Kyoto, Track18, GameState indexul 11):
# captura ORTOGRAFICA reala din Godot (snapshots/kyoto.png, rulata cu
# `Snapshot.tscn -- --track=11 --no-fog`, CU fereastra -- memoria
# `snapshot-nu-merge-headless`) cu legenda desenata peste ea, la scara.
# Reteta e cea din tools/annotate_jodhpur_plan.py: traseul, scurtatura si
# reperele se citesc DIRECT din scenes/tracks/Track18.tscn (memoria
# `diorama-din-geometria-reala`); reperele care nu au inca nod in scena
# (pagode, pavilion, sala) vin din constantele gardei de azimut din
# tools/gen_kyoto_route.py, marcate pe plan drept "pozitie planificata".
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), -Z (nord) in SUS pe ecran, +x (est) la dreapta.
# Rulare, din radacina repo-ului:
#   python tools/annotate_kyoto_plan.py [snapshot.png]
import math, os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "snapshots/kyoto.png"
tscn = open(ROOT + "scenes/tracks/Track18.tscn", encoding="utf-8").read()


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


main = catmull_rom(curve_points("Curve3D_kyoto"), True, 4)
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


# Tunelul de torii: TrackBranch drept intre entry_at / exit_at pe bucla.
entry = node_float("TunelTorii", "entry_at")
exit_ = node_float("TunelTorii", "exit_at")
tunnel = [at(entry), at(exit_)]


# Reperele fara nod in scena: constantele gardei din gen_kyoto_route.py (harta
# x est, y nord -> Godot gx = x, gz = -y).
src = open(ROOT + "tools/gen_kyoto_route.py", encoding="utf-8").read()


def const_xy(name):
    m = re.search(r"%s\s*=\s*\(([-0-9.]+),\s*([-0-9.]+)\)" % name, src)
    return (float(m.group(1)), 0.0, -float(m.group(2)))


PAGODA = const_xy("PAGODA_XY"); KOYASU = const_xy("KOYASU_XY"); KINKAKU = const_xy("KINKAKU_XY")

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


LEG_H = 300
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
VERM = (232, 98, 45, 255); WHITE = (245, 243, 238, 255); GOLD = (240, 190, 40, 255)
TEAL = (30, 110, 120, 255); VIOLET = (110, 70, 160, 255)


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
    if dx == "R":  # text terminat langa punct
        x0, y0 = x - tw - 14, y + dy
    else:
        x0, y0 = x + dx, y + dy
    dr.rectangle([x0 - 3, y0 - 1, x0 + tw + 3, y0 + 17], fill=(245, 243, 238, 205))
    dr.text((x0, y0), text, font=font, fill=col)


def ptf(frac, off=0.0):
    p = at(frac); s = side(frac)
    return gpx(p[0] + s[0] * off, p[2] + s[1] * off)


def band(f0, f1, col, w, steps=40):
    pts = [ptf(f0 + (f1 - f0) * i / steps) for i in range(steps + 1)]
    dr.line(pts, fill=col, width=w, joint="curve")


# --- traseul principal, subtire alb
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])], fill=(255, 255, 255, 110), width=3)

# --- tronsoane speciale, desenate peste drum
band(0.275, 0.303, VERM, 7)       # scena Kiyomizu (sectiune inaltata)
band(0.449, 0.466, VIOLET, 7)     # podul acoperit Tsuten-kyo
band(0.832, 0.894, TEAL, 7)       # podul Togetsukyo (peste rau)
t = [gpx(p[0], p[2]) for p in tunnel]
dashed_poly(t, VERM, 6, 5)

# --- dealurile (TerrainPeak) si dealul gradinii
for nm, txt, ldx, ldy in [("Inari", "MUNTELE INARI (+40 m)", 30, -96), ("Higashiyama", "VERSANTUL HIGASHIYAMA (+60 m)", 90, -70), ("DealGradina", "dealul gradinii (+24 m)", -60, 36)]:
    o = node_origin(nm); r = node_float(nm, "radius_m"); q = gpx(o[0], o[2])
    dr.ellipse([q[0] - r * k, q[1] - r * k, q[0] + r * k, q[1] + r * k], outline=INK, width=2)
    label(q[0], q[1], txt, dx=ldx, dy=ldy)


# --- repere
def marker(pos, txt, col, shape="tri", dx=12, dy=-8, font=None):
    q = gpx(pos[0], pos[2])
    if shape == "tri":
        dr.polygon([(q[0] - 9, q[1] + 8), (q[0], q[1] - 11), (q[0] + 9, q[1] + 8)], fill=col, outline=INK)
    else:
        dot(q[0], q[1], col, 7, ring=False)
    label(q[0], q[1], txt, font, dx=dx, dy=dy)


marker(PAGODA, "PAGODA YASAKA (24 m), pe axa startului", VERM, dx="R", dy=-8)
marker(KOYASU, "pagoda KOYASU (14 m), tinta saltului", VERM, dx=-250, dy=-4)
marker(KINKAKU, "PAVILIONUL DE AUR (poz. planificata), pe malul N al iazului", GOLD, dx=-150, dy=-40)
dar = node_origin("DarumaOtoshi"); marker(dar, "DARUMA-OTOSHI (exteriorul curbei, malul iazului)", HAZ, "dot", dx=-30, dy=62)
_q = gpx(dar[0], dar[2]); dr.line([(_q[0], _q[1] + 6), (_q[0] - 20, _q[1] + 62)], fill=HAZ, width=2)
jmp = node_origin("SaritaScena"); marker(jmp, "C2: SARITURA (gol ~20 m)", HAZ, "dot", dx=16, dy=-4)

# sala principala: fara nod in cod; stanga mersului pe scena (E), in dreptul puntii
p = at(0.288); s = side(0.288)
hall = gpx(p[0] - s[0] * 38, p[2] - s[1] * 38)
dr.rectangle([hall[0] - 26, hall[1] - 20, hall[0] + 26, hall[1] + 20], outline=INK, width=2)
label(hall[0], hall[1], "SALA KIYOMIZU (poz. aprox.)", dx=30, dy=-8)

# --- POI-urile (litere in cerc)
POI = [("A", 0.03, 18), ("B", 0.13, -18), ("C", 0.225, -18), ("C2", 0.305, 34), ("D", 0.39, 18),
       ("E", 0.53, -26), ("F", 0.612, -28), ("G", 0.745, 18), ("G2", 0.804, 18), ("H", 0.94, 18)]
for kk, f, off in POI:
    x, y = ptf(f, off)
    dr.ellipse([x - 15, y - 15, x + 15, y + 15], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- etichete scurte pe tronsoane
q = ptf(0.458); label(q[0], q[1], "pod acoperit TSUTEN-KYO (70 m)", dx="R", dy=-4, col=VIOLET)
q = ptf(0.285); label(q[0], q[1], "SCENA Kiyomizu (+32 m, spre S)", dx="R", dy=-34, col=VERM)
q = ptf(0.863); label(q[0], q[1], "pod TOGETSUKYO (150 m) peste rau", dx="R", dy=-4, col=TEAL)
mid = ((t[0][0] + t[1][0]) / 2, (t[0][1] + t[1][1]) / 2)
label(mid[0], mid[1], "E': tunel de torii (scurtatura)", dx=75, dy=-24, col=VERM)
q = gpx(cx - 30, cz - 70); label(q[0], q[1], "ORASUL VECHI (interiorul buclei)", F, dx=-120, dy=0)

# --- sensul, start, scara, soarele
for f in (0.07, 0.25, 0.40, 0.55, 0.66, 0.80, 0.90):
    p = at(f); tt = tangent(f); q = gpx(p[0], p[2])
    dr.polygon([(q[0] + tt[0] * 15, q[1] + tt[1] * 15), (q[0] - tt[1] * 7, q[1] + tt[0] * 7), (q[0] + tt[1] * 7, q[1] - tt[0] * 7)], fill=HAZ)
q = ptf(0.0); dr.line([(q[0] - 10, q[1]), (q[0] + 10, q[1])], fill=HAZ, width=5)
label(q[0], q[1], "START / SOSIRE (sens ORAR)", F, dx=14, dy=-8, col=HAZ)
sx, sy = 80, H - 40
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
# soarele: custom_sun_rotation_deg (-22,-45,0): lumina merge spre NE pe plan,
# deci soarele e in SV = jos-STANGA planului, 22 grade peste orizont.
label(W - 640, H - 60, "soarele: 22 grade, din jos-STANGA planului (SV)", dx=0, dy=0)
label(W - 640, H - 36, "SUS pe plan = NORD; sensul de mers: orar", dx=0, dy=0)

# --- legenda (banda de jos)
y0 = H + 12
dr.text((24, y0), "Kyoto in toamna (Track18) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A start pe Yasaka-dori, pagoda Yasaka in capatul strazii, pe axa",
        "B Sannenzaka: urcare cu doua S-uri, ocolul bazei pagodei, ceainarii",
        "C Kiyomizu-dera: poarta Niomon, sala, SCENA de lemn (portocaliu gros) pe stalpi",
        "C2 saritura de pe capatul scenei peste rapa de artari, spre pagoda Koyasu",
        "D valea de artari, apoi podul acoperit Tsuten-kyo (violet gros)"]
col2 = ["E Fushimi Inari: ac larg pe flancul muntelui; E' = tunelul de torii (portocaliu punctat)",
        "F gradina cu iaz si Pavilionul de Aur; DARUMA-OTOSHI pe malul iazului (turn de discuri)",
        "G padurea de bambus (doua S-uri); G2 pod de fier al trenului, deasupra drumului",
        "H podul Togetsukyo (turcoaz gros) peste rau, apoi dreapta finala spre pagoda",
        "Marcajele din cod: SARITURA, DARUMA, dealurile. Pavilion/sala/pagode: pozitii planificate"]
for i, tx in enumerate(col1):
    dr.text((24, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
for i, tx in enumerate(col2):
    dr.text((W // 2 + 10, y0 + 40 + i * 24), tx, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 24 + 12),
        "IGNORA: bilele verzi din fundal, petele negre (rapa/iaz/rau fara decor) si banda portocalie de langa D (placeholder) - arborii, casele si cladirile vin din assets",
        font=Fs, fill=HAZ)
dr.text((24, y0 + 40 + 6 * 24 + 12),
        "Culoarea uniforma a terenului e provizorie. Literele, sagetile si textul sunt LEGENDA: nu se deseneaza in diorama.",
        font=Fs, fill=HAZ)

out = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(ROOT + "docs/track_briefs/img/kyoto_plan", exist_ok=True)
out.save(ROOT + "docs/track_briefs/img/kyoto_plan/kyoto_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
