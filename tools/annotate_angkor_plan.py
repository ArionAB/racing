# Planul adnotat al pistei Angkor (Track24) pentru dioram: captura ORTOGRAFICA reala din Godot
# (`tools/snapshot.gd --track=16`, snapshots/angkor.png) cu stratul de adnotari desenat peste ea,
# la scara — reteta din `tools/annotate_carrara_plan.py` (memoria `diorama-din-geometria-reala`).
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z, extent_x / aspect) pe
# verticala, centrul = mijlocul bounds-ului punctelor coapte (+90 m margine), +z in jos pe ecran,
# +x la dreapta. Generatorul scrie direct coordonate Godot (gx = x, gz = -y), deci captura are
# nordul sus si estul la DREAPTA, fara oglindire.
#
# Surse de adevar (nimic nu e tastat de mana):
#   - punctele coapte: tools/data/angkor_fracmap.tsv (x, z, frac pe index, frac pe lungime)
#   - zonele POI, creasta declarata: `metadata/zones`, `metadata/jump_crests` din Track24.tscn
#   - hazardurile, machetele, ramura, piata regala: nodurile si proprietatile din Track24.tscn
#
#   python tools/annotate_angkor_plan.py [--snap snapshots/angkor.png] [--out plan.png]
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]


def arg(name, default):
    return args[args.index(name) + 1] if name in args else default


SNAP = arg("--snap", os.path.join(ROOT, "snapshots", "angkor.png"))
OUT = arg("--out", os.path.join(ROOT, "docs", "track_briefs", "img", "angkor_plan_adnotat.png"))
TSCN = os.path.join(ROOT, "scenes", "tracks", "Track24.tscn")
FRACMAP = os.path.join(ROOT, "tools", "data", "angkor_fracmap.tsv")

fm = []
for line in open(FRACMAP, encoding="utf-8"):
    t = line.split()
    if len(t) == 4:
        fm.append(tuple(float(v) for v in t))
gx = [p[0] for p in fm]
gz = [p[1] for p in fm]
cx, cz = (min(gx) + max(gx)) / 2, (min(gz) + max(gz)) / 2
ext_x, ext_z = max(gx) - min(gx) + 90, max(gz) - min(gz) + 90

base = Image.open(SNAP).convert("RGBA")
W, H = base.size
k = H / max(ext_z, ext_x / (W / H))


def px(x, z):
    """lume Godot (x, z) -> pixel."""
    return (W / 2 + (x - cx) * k, H / 2 + (z - cz) * k)


def at_idx(f):
    """punctul copt cel mai apropiat de fractia pe INDEX `f`."""
    return min(fm, key=lambda p: abs(p[2] - f))


tscn = open(TSCN, encoding="utf-8").read()
zones = {m.group(1): (float(m.group(2)), float(m.group(3))) for m in re.finditer(
    r'"(\w)": Vector2\(([0-9.]+), ([0-9.]+)\)', re.search(r"metadata/zones = \{[^\n]*", tscn).group(0))}
crest = [float(v) for v in re.search(r"jump_crests = \[Vector2\(([0-9.]+), ([0-9.]+)\)", tscn).groups()]


def node_pos(name):
    m = re.search(r'\[node name="%s"[^\]]*\]\ntransform = Transform3D\(([^)]*)\)' % name, tscn)
    v = [float(s) for s in m.group(1).split(",")]
    return v[9], v[10], v[11]


def node_box(name):
    x, y, z = node_pos(name)
    m = re.search(r'\[node name="%s"[^\]]*\]\n[^\[]*?size = Vector3\(([^)]*)\)' % name, tscn)
    sx, sy, sz = (float(s) for s in m.group(1).split(","))
    return x - sx / 2, z - sz / 2, x + sx / 2, z + sz / 2


branch = re.search(r'id="Curve3D_galeria"\]\n_data = \{\n"points": PackedVector3Array\(([^)]*)\)', tscn)
bv = [float(s) for s in branch.group(1).split(",")]
branch_pts = [(bv[i + 6], bv[i + 8]) for i in range(0, len(bv), 9)]
bench = re.search(r'"x0": ([-0-9.]+), "x1": ([-0-9.]+), "z0": ([-0-9.]+), "z1": ([-0-9.]+)', tscn)
bx0, bx1, bz0, bz1 = (float(v) for v in bench.groups())

LEG_H = 270
im = Image.new("RGBA", (W, H + LEG_H), (236, 230, 214, 255))
im.paste(base, (0, 0))
ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)
try:
    F = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
    Fm = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 13)
    Fs = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 13)
    Fb = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 22)
except Exception:  # pragma: no cover
    F = Fm = Fs = Fb = ImageFont.load_default()
INK = (30, 26, 22, 255)
RED = (176, 40, 30, 255)
ORANGE = (214, 120, 20, 255)
TEAL = (20, 110, 120, 255)
STONE = (120, 96, 70, 255)


def label(x, y, text, font=Fm, fg=INK, bg=(255, 252, 240, 215), pad=3):
    l, t, r, b = dr.textbbox((x, y), text, font=font)
    dr.rectangle([l - pad, t - pad, r + pad, b + pad], fill=bg)
    dr.text((x, y), text, font=font, fill=fg)


def segment(f0, f1, col, w=6):
    pts = [px(p[0], p[1]) for p in fm if f0 <= p[2] <= f1]
    if len(pts) > 1:
        dr.line(pts, fill=col, width=w)


# ---- piata regala (platoul de +14) si fata de 4 m a Terasei Elefantilor
a, b = px(bx0, bz0), px(bx1, bz1)
dr.rectangle([a[0], a[1], b[0], b[1]], outline=TEAL, width=2)
dr.line([(b[0], a[1]), (b[0], b[1])], fill=RED, width=4)
label(a[0] + 4, a[1] + 6, "piata\nregala\n+14", Fs, TEAL)

# ---- ramura: galeria Ta Prohm (scurtatura) si dominoul
gp = [px(x, z) for x, z in branch_pts]
for i in range(len(gp) - 1):
    if i % 2 == 0:
        dr.line([gp[i], gp[i + 1]], fill=STONE, width=4)
for i in range(3):
    x, _y, z = node_pos("Domino%d" % i)
    p = px(x, z)
    dr.rectangle([p[0] - 5, p[1] - 5, p[0] + 5, p[1] + 5], fill=RED)
p = px(*[node_pos("Domino1")[i] for i in (0, 2)])
label(p[0] + 12, p[1] - 30, "domino x3\n(galeria)", Fm, RED)

# ---- elefantul (traversare dupa poarta) si poarta
ex, _ey, ez = node_pos("ElefantPoarta")
p = px(ex, ez)
dr.line([(p[0] - 14, p[1]), (p[0] + 14, p[1])], fill=RED, width=4)
dr.ellipse([p[0] - 6, p[1] - 6, p[0] + 6, p[1] + 6], fill=RED)
label(p[0] + 16, p[1] - 8, "elefantul traverseaza", Fm, RED)
for n in ("Poarta_PilonV", "Poarta_PilonE", "Poarta_Turn"):
    x0, z0, x1, z1 = node_box(n)
    a, b = px(x0, z0), px(x1, z1)
    dr.rectangle([a[0], a[1], b[0], b[1]], outline=STONE, width=2)
x, _y, z = node_pos("Poarta_Turn")
p = px(x, z)
label(p[0] + 16, p[1] + 6, "Poarta de Sud (7 m)", Fs)

# ---- creasta Regelui Lepros (saritura)
segment(crest[0], crest[1], ORANGE, 9)
p = px(*at_idx(crest[0])[:2])
label(p[0] + 12, p[1] - 6, "SARITURA (muchia +18 -> +9)", Fm, ORANGE)

# ---- Angkor Wat (machetele: soclul si turnurile)
x0, z0, x1, z1 = node_box("AW_Soclu")
a, b = px(x0, z0), px(x1, z1)
label(b[0] + 6, a[1], "ANGKOR WAT\nturnuri 22-28 m", Fm)

# ---- POI: litera la mijlocul fiecarei zone
for key, (f0, f1) in sorted(zones.items()):
    x, z = at_idx((f0 + f1) / 2)[:2]
    q = px(x, z)
    dr.ellipse([q[0] - 14, q[1] - 14, q[0] + 14, q[1] + 14], fill=(255, 252, 240, 240), outline=RED, width=3)
    tw = dr.textlength(key, font=F)
    dr.text((q[0] - tw / 2, q[1] - 11), key, font=F, fill=INK)

# ---- start, sens, nord, scara
x, z = at_idx(0.0)[:2]
p = px(x, z)
label(p[0] - 30, p[1] + 14, "START ->", Fm)
dr.line([(60, 110), (60, 60)], fill=INK, width=3)
dr.polygon([(60, 52), (54, 66), (66, 66)], fill=INK)
dr.text((54, 116), "N", font=F, fill=INK)
sx, sy = 40, H - 30
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=3)
dr.text((sx, sy - 20), "100 m", font=Fs, fill=INK)
dr.text((W - 260, 16), "sens ORAR, jungla in interior", font=Fm, fill=INK)

# ---- legenda
y0 = H + 14
dr.text((24, y0), "Angkor (Track24) — planul REAL al pistei, vazut de sus din Godot", font=Fb, fill=INK)
left = [
    "A calea de vest (+3) peste santul de jad, START spre turnuri",
    "B gopura de vest, arcul prin galerie, calea de nord (+4)",
    "C Phnom Bakheng: urcare 11%, platforma +31, dezvaluirea spre AW",
    "D calea uriasilor (+14) peste santul Angkor Thom, Poarta de Sud",
]
right = [
    "E Bayonul: terasa de 14 m (+20), turnurile cu fete PE drum (pasul 6)",
    "F piata regala (+14), diagonala, Terasa Elefantilor (+18), SARITURA",
    "G Ta Prohm: ocolul incintei; scurtatura prin galerie (domino)",
    "H Srah Srang (stanga) si malul santului AW (dreapta), spre start",
]
for i, t in enumerate(left):
    dr.text((24, y0 + 40 + i * 22), t, font=Fs, fill=INK)
for i, t in enumerate(right):
    dr.text((W // 2 + 10, y0 + 40 + i * 22), t, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 22 + 12),
        "rosu = hazard (elefant, domino) si fata de 4 m a terasei · portocaliu = saritura · maro punctat = "
        "galeria-scurtatura · formele bej = MACHETE temporare (AW, poarta), nu decor",
        font=Fs, fill=INK)
dr.text((24, y0 + 40 + 5 * 22 + 12),
        "nord sus, est la DREAPTA (orientarea capturii din joc) · apa = santurile Angkor Wat / Angkor Thom si Srah Srang",
        font=Fs, fill=INK)

im = Image.alpha_composite(im, ov).convert("RGB")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
im.save(OUT)
print("plan adnotat:", OUT)
