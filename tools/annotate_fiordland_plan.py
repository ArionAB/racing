# -*- coding: utf-8 -*-
# Planul de referinta pentru ChatGPT (Fiordland, Track16): captura
# ORTOGRAFICA reala din Godot (snapshots/fiordland.png, rulata cu
# `Snapshot.tscn -- --track=16 --rain=0 --no-fog` — FARA --no-fog ceata scenei
# umple cadrul de la 400 m si nu se vede nimic) cu legenda desenata peste ea,
# la scara. Reteta e cea din tools/annotate_machu_plan.py, dar traseul si
# hazardele se citesc DIRECT din scenes/tracks/Track16.tscn (nu dintr-un
# JSON de ruta): pista e sursa de adevar, nu un plan de propunere (memoria
# `diorama-din-geometria-reala`).
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), +z in jos pe ecran, +x la dreapta (vedere reala de
# sus: nord sus). Rulare, din radacina repo-ului:
#   python tools/annotate_fiordland_plan.py [snapshot.png]
import math, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "./"
snap = sys.argv[1] if len(sys.argv) > 1 else ROOT + "snapshots/fiordland.png"
tscn = open(ROOT + "scenes/tracks/Track16.tscn", encoding="utf-8").read()


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
    """Aproximarea curbei coapte: Catmull-Rom uniform prin punctele de control
    (Track._build_curve foloseste tangente (next-prev)*0.22, suficient de
    apropiat ca sa se suprapuna pe asfaltul din captura)."""
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


main = catmull_rom(curve_points("Curve3D_fiordland"), True)
branch = catmull_rom(curve_points("Curve3D_scurtatura_chasm"), False)
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


def side(frac):  # dreapta sensului de mers, in planul xz (+y sus => dreapta = (tz, -tx))
    tx, tz = tangent(frac)
    return (-tz, tx)


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


LEG_H = 250
im = Image.new("RGBA", (W, H + LEG_H), (233, 230, 222, 255))
im.paste(base, (0, 0))
ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)
try:
    F = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
    Fs = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
    Fb = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 26)
except Exception:
    F = Fs = Fb = ImageFont.load_default()

INK = (31, 36, 32, 255); BLUE = (42, 95, 158, 255); HAZ = (214, 69, 58, 255)
STRAW = (217, 184, 92, 255); WHITE = (245, 243, 238, 255); SNOW = (250, 250, 252, 255)


def dashed_poly(pts, col, dash=7, w=2):
    for a, b in zip(pts, pts[1:]):
        Lg = math.hypot(b[0] - a[0], b[1] - a[1]); m = max(1, int(Lg / dash))
        for i in range(0, m, 2):
            t0, t1 = i / m, min(1, (i + 1) / m)
            dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=w)


def dot(x, y, fill, r=6, ring=True):
    dr.ellipse([x - r, y - r, x + r, y + r], fill=fill, outline=HAZ if ring else INK, width=2 if ring else 1)


def label(x, y, text, font=None, dx=10, dy=-8):
    dr.text((x + dx, y + dy), text, font=font or Fs, fill=INK)


def curtain(frac, length_m, width_m, col, text=None):
    """Perdea de apa peste drum: dreptunghi transversal, centrat pe axa."""
    p = at(frac); tx, tz = tangent(frac); sx, sz = side(frac)
    hl, hw = length_m / 2, width_m / 2
    corners = [(p[0] + tx * a + sx * b, p[2] + tz * a + sz * b) for a, b in
               ((-hl, -hw), (hl, -hw), (hl, hw), (-hl, hw))]
    pts = [gpx(*c) for c in corners]
    band = Image.new("RGBA", im.size, (0, 0, 0, 0)); bd = ImageDraw.Draw(band)
    bd.polygon(pts, fill=col + (150,), outline=HAZ)
    ov.alpha_composite(band)
    if text:
        label(pts[1][0], pts[1][1], text)


# --- traseul principal (sens de mers) si scurtatura
dr.line([gpx(p[0], p[2]) for p in main] + [gpx(main[0][0], main[0][2])], fill=(255, 255, 255, 90), width=3)
dashed_poly([gpx(p[0], p[2]) for p in branch], STRAW, 8, 4)
mid = gpx(branch[len(branch) // 2][0], branch[len(branch) // 2][2])
label(mid[0], mid[1], "drumul vechi din padure (scurtatura, 3,2 m)", dx=14, dy=34)

# --- Stirling (C): perdea de 30 m lungime x 6 m, forta reala
curtain(0.300, 30, 8, (250, 250, 250), "Stirling Falls: 45 m, cade PESTE drum, forta reala")
# --- cascadele de ploaie (5 fire false, doar in ploaie)
for f in (0.10, 0.172, 0.40, 0.718, 0.79):
    curtain(f, 20, 6, (200, 225, 245))
p = gpx(*[at(0.10)[i] for i in (0, 2)]); label(p[0], p[1], "x5 cascade de ploaie (teatru, doar in ploaie)", dx=14, dy=-4)
# --- torentul in pulsuri, la mijlocul benzii
bp = branch[len(branch) // 2]; t = gpx(bp[0], bp[2])
dr.rectangle([t[0] - 10 * k, t[1] - 4 * k, t[0] + 10 * k, t[1] + 4 * k], fill=(250, 250, 250, 200), outline=HAZ, width=2)
dot(t[0], t[1], (250, 250, 250, 255), 5)
label(t[0], t[1], "TORENTUL in pulsuri (7 s liniste / 3 s anunt / 4 s puls)", dx=14, dy=12)
# --- tunelul Homer: portal est la 0.612, 169 m; banda de autocar pe stanga
p0 = at(0.612); tube = []
d0 = cum[0]
f = 0.612
while True:
    tube.append(gpx(*[at(f)[i] for i in (0, 2)]))
    if (f - 0.612) * L >= 169: break
    f += 0.004
dr.line(tube, fill=(90, 90, 95, 230), width=int(9 * k) + 4)
dr.line(tube, fill=(240, 240, 240, 255), width=2)
dot(tube[0][0], tube[0][1], HAZ, 7); dot(tube[-1][0], tube[-1][1], (120, 120, 120, 255), 6, False)
label(tube[0][0], tube[0][1], "portal EST + semafor: rosu = autocarul e in tunel", dx=12, dy=-26)
label(tube[-1][0], tube[-1][1], "portal VEST (autocarul iese pe stanga)", dx=12, dy=6)
# --- avalansa F (cicatricea): marker la 0.751
p = gpx(*[at(0.751)[i] for i in (0, 2)]); dot(p[0], p[1], (120, 90, 50, 255), 8)
label(p[0], p[1], "avalansa de padure (90 s): trunchiuri + bolovani peste drum", dx=12, dy=-8)
# --- kickerul Bowen: gol 12 m la 0.857
curtain(0.857, 12, 14, (120, 190, 220), None)
p = gpx(*[at(0.857)[i] for i in (0, 2)]); label(p[0], p[1], "Bowen Falls: kicker de piatra peste bazin (saritura)", dx=14, dy=8)
# --- pista de avioane (H): paralela la 20 m pe dreapta, 0.83-0.95
strip = []
for f in [0.83 + i * 0.01 for i in range(13)]:
    p = at(f); s = side(f); strip.append(gpx(p[0] + s[0] * 20, p[2] + s[1] * 20))
dr.line(strip, fill=(150, 150, 150, 220), width=int(6 * k) + 2)
label(strip[6][0], strip[6][1], "pista de avioane (avionul aterizeaza paralel cu drumul)", dx=14, dy=24)
# --- cheiul (A) + pontonul, satul (H)
p = gpx(*[at(0.0)[i] for i in (0, 2)]); s = side(0.0)
q = gpx(at(0.0)[0] - s[0] * 18, at(0.0)[2] - s[1] * 18)
dr.rectangle([q[0] - 6 * k, q[1] - 6 * k, q[0] + 6 * k, q[1] + 6 * k], fill=(170, 165, 155, 255), outline=INK)
label(q[0], q[1], "cheiul: ponton, 2 vaporase, caiace, cafenea, pinguini", dx=-360, dy=14)
# --- Mitre Peak (insula) si masivul tunelului
for name, txt, col in (("MitrePeak", "MITRE PEAK: insula in golf, 70 m, calota alba, un fir de cascada", SNOW),
                       ("MasivTunel", "masivul tunelului (creasta de granit, 85 m)", (200, 196, 188, 255))):
    o = node_origin(name); r = float(re.search(r'name="%s"[^\n]*\n(?:[^\[\n][^\n]*\n)*?radius_m = ([0-9.]+)' % name, tscn).group(1))
    c = gpx(o[0], o[2])
    dr.ellipse([c[0] - r * k, c[1] - r * k, c[0] + r * k, c[1] + r * k], outline=INK, width=2)
    dr.polygon([(c[0] - 9, c[1] + 8), (c[0], c[1] - 9), (c[0] + 9, c[1] + 8)], fill=col, outline=INK)
    if name == "MitrePeak":
        label(c[0], c[1], txt, dx=-120, dy=r * k + 6)
    else:
        label(c[0], c[1], txt, dx=r * k + 6, dy=-8)
# --- fiordul: marea e pe STANGA sensului de mers pe cornisa (B) si pe mal (H)
for f, txt, off in ((0.08, "FIORDUL (marea, -30 m, fara parapet)", 55), (0.93, "FIORDUL", 40)):
    p = at(f); s = side(f); q = gpx(p[0] - s[0] * off, p[2] - s[1] * off)
    dr.text((q[0] - 60, q[1]), txt, font=F, fill=(20, 60, 90, 255))

# --- POI-urile (litere in cerc), pe axa, la mijlocul intervalului
POI = [("A", 0.02), ("B", 0.13), ("C", 0.24), ("D", 0.34), ("E", 0.53), ("F", 0.68), ("G", 0.78), ("H", 0.90)]
for kk, f in POI:
    p = at(f); s = side(f); x, y = gpx(p[0] + s[0] * 14, p[2] + s[1] * 14)
    dr.ellipse([x - 14, y - 14, x + 14, y + 14], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, nordul, scara, soarele
p = at(0.17); t = tangent(0.17); q = gpx(p[0], p[2])
dr.polygon([(q[0] + t[0] * 18, q[1] + t[1] * 18), (q[0] - t[1] * 8, q[1] + t[0] * 8), (q[0] + t[1] * 8, q[1] - t[0] * 8)], fill=HAZ)
label(q[0], q[1], "sens de mers ->", F, dx=-165, dy=-30)
nx, ny = 60, 60
dr.line([(nx, ny + 40), (nx, ny)], fill=INK, width=3); dr.polygon([(nx - 7, ny + 12), (nx, ny - 2), (nx + 7, ny + 12)], fill=INK)
dr.text((nx - 6, ny + 44), "N", font=F, fill=INK)
sx, sy = 40, H - 40
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
# soarele: theme sun_rotation_deg (-30, 200, 0) => lumina vine DIN (-0.30, +0.50, -0.81), adica din STANGA-SUS pe plan, 30 grade sus
dr.text((W - 470, 16), "soarele: rece, 30 grade sus, din STANGA-SUS pe plan, nori rupti", font=Fs, fill=INK)

# --- legenda (banda de jos)
y0 = H + 12
dr.text((24, y0), "Fiordland / Milford Sound (Track16) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A start pe chei: ponton, 2 vaporase, caiace, cafenea, pinguini; Mitre Peak peste apa",
        "B cornisa fiordului: drum taiat in gneis ud, marea pe STANGA la -30 m, foci pe stanca, rata rosie",
        "C Stirling Falls: 45 m, cade de pe surplomb PESTE drum; prin perdea sau pe pragul uscat din spate",
        "D Chasm: padure de fag cu muschi, podet de scanduri peste raul alb; furca scurtaturii + torentul"]
col2 = ["E urcarea prin grohotis (panouri chevron, jaloane) la portalul de beton cu galerie de avalansa",
        "F tunelul Homer (169 m, banda de autocar pe stanga) si coborarea prin cicatricea avalansei",
        "G Bowen Falls: kicker de piatra peste bazinul alb (saritura in spray)",
        "H malul: lodge, containere, heliport gol, pista de avioane paralela, inapoi la chei"]
for i, t in enumerate(col1): dr.text((24, y0 + 40 + i * 24), t, font=Fs, fill=INK)
for i, t in enumerate(col2): dr.text((640, y0 + 40 + i * 24), t, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 24 + 8),
        "alb = perdele de apa (cerc rosu = hazard)   ·   galben punctat = scurtatura   ·   gri = tunelul   ·   sens A -> B -> C, FIORDUL PE STANGA masinii   ·   nord sus (-z), +x la dreapta (vedere reala de sus din Godot)",
        font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 24 + 8),
        "cercurile mari = varfuri (TerrainPeak); turcoazul din captura = apa; drumul e asfalt UD; tot ce nu e apa, drum sau varf e teren placeholder (padurea si peretii vin din assets)",
        font=Fs, fill=INK)

out = Image.alpha_composite(im, ov).convert("RGB")
out.save(ROOT + "docs/track_briefs/img/fiordland_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1), "L =", round(L))
