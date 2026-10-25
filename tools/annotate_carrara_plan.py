# Planul adnotat al pistei Carrara (Track23) pentru dioram: captura ORTOGRAFICA reala din Godot
# (`tools/snapshot.gd --track=15`, snapshots/carrara.png) cu stratul de adnotari desenat peste ea,
# la scara — reteta din `tools/annotate_serengeti_plan.py` (memoria `diorama-din-geometria-reala`).
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z, extent_x / aspect) pe
# verticala, centrul = mijlocul bounds-ului punctelor coapte (+90 m margine), +z in jos pe ecran,
# +x la dreapta. VERIFICATA pe captura: linia de start (harta (-148, 105) -> px (374, 186)) cade pe
# patratelul de start din imagine, iar varful acului 1 si capatul tunelului D la fel.
#
# OGLINDIREA axei X (memoria spune "x oglindit, est la stanga") NU se aplica aici, si nu din
# neglijenta: la Serengeti / Machu Picchu datele de traseu erau pastrate in coordonate de HARTA cu
# gx = -x, deci hartile lor cereau `-mx`. La Carrara generatorul scrie direct coordonate Godot
# (gx = x, gz = -y; tools/gen_carrara_route.py, antetul), iar captura de sus are est la DREAPTA.
# Regula de fond a memoriei ramane: planul se deseneaza in ACEEASI orientare ca imaginea din joc.
#
# Surse de adevar (nimic nu e tastat de mana):
#   - punctele coapte ale traseului: tools/data/carrara_fracmap.tsv (x, z, frac pe index, frac pe lungime)
#   - platourile de banc (cote, fete): `custom_bench_patches` din scenes/tracks/Track23.tscn
#
# Rulare:
#   python tools/annotate_carrara_plan.py [--snap snapshots/carrara.png] [--out plan_adnotat.png]
import math
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]


def arg(name, default):
    if name in args:
        return args[args.index(name) + 1]
    return default


SNAP = arg("--snap", os.path.join(ROOT, "snapshots", "carrara.png"))
OUT = arg("--out", os.path.join(ROOT, "docs", "track_briefs", "img", "carrara_plan_adnotat.png"))
TSCN = os.path.join(ROOT, "scenes", "tracks", "Track23.tscn")
FRACMAP = os.path.join(ROOT, "tools", "data", "carrara_fracmap.tsv")

# ---- traseul copt: (gx, gz, frac index, frac lungime). Harta (x, y) = (gx, -gz).
fm = []
for line in open(FRACMAP, encoding="utf-8"):
    t = line.split()
    if len(t) == 4:
        fm.append(tuple(float(v) for v in t))
gx = [p[0] for p in fm]
gz = [p[1] for p in fm]
bmin = (min(gx), min(gz))
bmax = (max(gx), max(gz))
cx, cz = (bmin[0] + bmax[0]) / 2, (bmin[1] + bmax[1]) / 2
ext_x, ext_z = bmax[0] - bmin[0] + 90, bmax[1] - bmin[1] + 90

base = Image.open(SNAP).convert("RGBA")
W, H = base.size
size = max(ext_z, ext_x / (W / H))
k = H / size


def px(mx, my):
    """harta (x est, y nord) -> pixel (nord sus, est la dreapta, ca in captura)."""
    return (W / 2 + (mx - cx) * k, H / 2 + (-my - cz) * k)


LEG_H = 250
im = Image.new("RGBA", (W, H + LEG_H), (236, 230, 214, 255))
im.paste(base, (0, 0))
ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)
try:
    F = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
    Fm = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 13)
    Fs = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 13)
    Fb = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
except Exception:  # pragma: no cover
    F = Fm = Fs = Fb = ImageFont.load_default()

INK = (35, 32, 28, 255)
WHITE = (251, 247, 234, 255)
RUST = (170, 62, 38, 255)
FACE = (150, 40, 28, 255)
TEAL = (30, 130, 140, 255)
GOLD = (190, 140, 40, 255)


def dashed(pts, col, dash=7, w=3):
    for a, b in zip(pts, pts[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(L / dash))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1, (i + 1) / n)
            dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=w)


def label(x, y, text, font=Fm, fg=INK, bg=(255, 252, 240, 215), pad=3):
    w = dr.textlength(text, font=font)
    dr.rectangle([x - pad, y - pad, x + w + pad, y + 16 + pad], fill=bg)
    dr.text((x, y), text, font=font, fill=fg)


# ---- platourile de banc, citite din scena
txt = open(TSCN, encoding="utf-8").read()
m = re.search(r"custom_bench_patches = Array\[Dictionary\]\(\[(.*)\]\)\n", txt)
patches = []
for ent in re.finditer(
        r'\{ "lvl": PackedVector2Array\(([^)]*)\), "soft": Vector4\(([^)]*)\), "x0": ([-\d.]+), '
        r'"x1": ([-\d.]+), "z0": ([-\d.]+), "z1": ([-\d.]+) \}', m.group(1)):
    lv = [float(v) for v in ent.group(1).split(",")]
    lvl = list(zip(lv[0::2], lv[1::2]))
    soft = [float(v) for v in ent.group(2).split(",")]
    x0, x1, z0, z1 = (float(ent.group(i)) for i in (3, 4, 5, 6))
    patches.append(dict(lvl=lvl, soft=soft, x0=x0, x1=x1, z0=z0, z1=z1,
                        mean=sum(e for _x, e in lvl) / len(lvl)))

# podea (cota <= 3): panza teal translucida
for p in patches:
    if p["mean"] <= 3.0:
        a = px(p["x0"], -p["z0"])
        b = px(p["x1"], -p["z1"])
        dr.rectangle([a[0], a[1], b[0], b[1]], fill=(30, 130, 140, 70))
# muchiile DURE = fetele verticale (soft 0), cu hasuri spre latura joasa. O margine dura intre doua
# platouri de ACEEASI cota (ex. PitA / PitB) nu e o fata: se sare.
def patch_level_at(x, z):
    lv = None
    for q in patches:
        if q["x0"] <= x <= q["x1"] and q["z0"] <= z <= q["z1"]:
            lv = q["mean"]
    return lv


for p in patches:
    sw, se, sn, ss = p["soft"]
    zc = (p["z0"] + p["z1"]) / 2.0
    xc = (p["x0"] + p["x1"]) / 2.0
    edges = []
    if sn <= 0.0:
        edges.append((px(p["x0"], -p["z0"]), px(p["x1"], -p["z0"]), (xc, p["z0"] - 2.0)))
    if ss <= 0.0:
        edges.append((px(p["x0"], -p["z1"]), px(p["x1"], -p["z1"]), (xc, p["z1"] + 2.0)))
    if sw <= 0.0:
        edges.append((px(p["x0"], -p["z0"]), px(p["x0"], -p["z1"]), (p["x0"] - 2.0, zc)))
    if se <= 0.0:
        edges.append((px(p["x1"], -p["z0"]), px(p["x1"], -p["z1"]), (p["x1"] + 2.0, zc)))
    for a, b, probe_pt in edges:
        other = patch_level_at(*probe_pt)
        if other is not None and abs(other - p["mean"]) < 1.5:
            continue
        dr.line([a, b], fill=FACE, width=2)
# hasuri: pe fiecare treapta a scarii de pe E si pe fetele T1/T2/T3 (tick-uri scurte spre gol)
for p in patches:
    sw, se, sn, ss = p["soft"]
    if sn <= 0.0:
        a, b = px(p["x0"], -p["z0"]), px(p["x1"], -p["z0"])
        L = abs(b[0] - a[0])
        for i in range(int(L / 7)):
            xx = a[0] + i * 7
            dr.line([(xx, a[1]), (xx - 2, a[1] - 5)], fill=FACE, width=1)

# ---- drumul, colorat dupa cota
elev = {}
for i, (x, z, fi, fl) in enumerate(fm):
    pass
pts = [px(x, -z) for x, z, _fi, _fl in fm]
for a, b in zip(pts, pts[1:] + pts[:1]):
    dr.line([a, b], fill=(255, 255, 255, 255), width=5)

# tunelurile (dashed): D (len 0.400..0.592) si H (0.951..0.974)
def span(f0, f1):
    return [px(x, -z) for x, z, _fi, fl in fm if f0 <= fl <= f1]


dashed(span(0.400, 0.592), RUST, 8, 4)
dashed(span(0.951, 0.974), RUST, 8, 4)
tun_d = span(0.46, 0.46)

# podul F (len 0.706..0.721): linie groasa gri-caramida
bridge = span(0.706, 0.721)
if len(bridge) > 1:
    dr.line(bridge, fill=(150, 80, 55, 255), width=8)

# ---- etichete de cota (din platouri, nu de mana)
def lvl_at(name_pred):
    return [p for p in patches if name_pred(p)]


# T1 / T2 / T3: nivelurile drumurilor
label(*px(-128, 99), "T1  +25", Fm)
label(*px(-45, 74), "T2  +16", Fm)
label(*px(-45, 36), "T3  +7", Fm)
# scara de pe E: o eticheta per treapta, citita din platouri (E0 = bancul lui E, E1..E4 = trepte),
# alternand stanga/dreapta ca sa nu se suprapuna (8 m = ~13 px la scara capturii)
stair = sorted((p for p in patches if p["x1"] == 104.0), key=lambda p: p["z1"], reverse=True)
for i, p in enumerate(stair):
    ymid = -(p["z0"] + p["z1"]) / 2.0 if p["z0"] > -200 else -p["z1"] - 4.0
    ymid = -(0.5 * (p["z0"] + p["z1"]))
    nm = "E +%d" % round(p["mean"]) if i == 0 else "+%d" % round(p["mean"])
    label(*px(-228 if i % 2 == 0 else -176, ymid + 4), nm, Fm)
label(*px(-60, -25), "FUNDUL CARIEREI  +0.8", F, TEAL)
label(*px(150, -46), "balti marmettola (pasul 6)", Fs, TEAL)
dashed([px(130, -10), px(205, -10), px(205, -55), px(130, -55), px(130, -10)], TEAL, 6, 2)

# ---- POI-urile (cercuri cu litera)
POI = [
    ("A", -95, 105, "piazzale +25 (start, cupa)"),
    ("B", -40, 82, "gradonii: 3 terase + 2 ace"),
    ("C", 150, 28, "fundul: balti, derrick"),
    ("D", 330, -72, "galeria (tub) +2 -> +45"),
    ("E", 40, -112, "cariera de sus +45"),
    ("F", -150, -112, "Ponti di Vara +43"),
    ("G", -300, 0, "ravaneto +43 -> +27"),
    ("H", -228, 105, "tunelul Marmifera"),
]
for kk, mx, my, _t in POI:
    x, y = px(mx, my)
    dr.ellipse([x - 14, y - 14, x + 14, y + 14], fill=WHITE, outline=RUST, width=3)
    tw = dr.textlength(kk, font=F)
    dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# ---- sensul, nordul, scara
x, y = px(-60, 112)
dr.text((x, y - 24), "sens ORAR  ->", font=F, fill=INK)
nx, ny = 60, 60
dr.line([(nx, ny + 40), (nx, ny)], fill=INK, width=3)
dr.polygon([(nx - 7, ny + 12), (nx, ny - 2), (nx + 7, ny + 12)], fill=INK)
dr.text((nx - 6, ny + 44), "N", font=F, fill=INK)
sx, sy = 40, H - 36
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.line([(sx, sy - 6), (sx, sy + 6)], fill=INK, width=3)
dr.line([(sx + 100 * k, sy - 6), (sx + 100 * k, sy + 6)], fill=INK, width=3)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)

# ---- legenda
y0 = H + 10
dr.text((24, y0), "Carrara (Track23) — planul REAL al pistei, vazut de sus din Godot, cu treptele de gradon", font=Fb, fill=INK)
col1 = [
    "A piazzale-ul (+25): start, excavatorul pe stanga, blocuri stivuite",
    "B gradonii: T1 +25 -> T2 +16 -> T3 +7, fete verticale de 9 m, banc plat de 8 m",
    "C fundul carierei (+0.8): balti de marmettola, macaraua-derrick (pas urmator)",
    "D galeria Ravaccione (tub, linie intrerupta): urca 43 m prin masivul din est",
]
e_txt = " / ".join("+%d" % round(p["mean"]) for p in sorted((q for q in patches if q["x1"] == 104.0 and q["mean"] < 44.0 and q["mean"] > 8.0), key=lambda q: -q["mean"]))
col2 = [
    "E cariera de sus (+45): scara de 5 fete (" + e_txt + " / fund +0.8)",
    "F Ponti di Vara (+43), peste cheiul torentului   G ravaneto-ul (+43 -> +27)",
    "H tunelul Marmifera (tub, linie intrerupta) inapoi in piazzale",
    "linie rosie = FATA verticala (hasurile arata spre gol); panza teal = fundul",
]
for i, t in enumerate(col1):
    dr.text((24, y0 + 40 + i * 22), t, font=Fs, fill=INK)
for i, t in enumerate(col2):
    dr.text((650, y0 + 40 + i * 22), t, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 22 + 8),
        "nord sus, est la DREAPTA (orientarea capturii din joc; X nu e oglindit aici, vezi antetul scriptului)  ·  "
        "sensul de mers: A -> B -> C -> D -> E -> F -> G -> H, amfiteatrul mereu pe DREAPTA masinii", font=Fs, fill=INK)

out = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
out.save(OUT, optimize=True)
print("scris:", OUT, out.size)
