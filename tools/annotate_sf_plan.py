# Planul adnotat al pistei San Francisco (Track25, bucla B200) pentru diorama de referinta: captura
# ORTOGRAFICA reala din Godot (`tools/snapshot.gd --track=17`, snapshots/san francisco.png) cu stratul
# de adnotari desenat peste ea, la scara — reteta din `tools/annotate_angkor_plan.py` (memoria
# `diorama-din-geometria-reala`). Brief: docs/track_briefs/san_francisco.md §2 (B200), §7 pasul 2b, §9.
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z, extent_x / aspect) pe
# verticala, centrul = mijlocul bounds-ului punctelor coapte (+90 m margine), +z in jos pe ecran,
# +x la dreapta. Generatorul scrie coordonate Godot gx = x, gz = -y (harta: x est, y nord), deci
# captura are nordul SUS si estul la DREAPTA, fara oglindire. Verificat pe linia de start (vezi
# --check, care deseneaza doar crucile de control).
#
# Surse de adevar (nimic nu e tastat de mana, in afara de pozitiile etichetelor):
#   - punctele coapte: tools/data/sf_route_fracmap.tsv (x, z, frac pe index, frac pe lungime)
#   - geometria (reperele MK, muchiile, podul, tramvaiele, golful): tools/gen_sf_route.py rulat in
#     modul SF_ROUTE_DRY=1 (nu scrie nimic), citit prin runpy
#
# Captura de baza (pasul 4, 15 nov 2026), 1600 x 900, cu cadrul fortat la 780 m pe verticala (ca sa intre
# si golful de la N de chei si malul celalalt):
#   godot --path . --resolution 1600x900 res://tools/Snapshot.tscn -- --track=17 --size=780
# (CU FEREASTRA; `--track=17` tipareste „San Francisco (Track25)”). Copia ei e in
# docs/asset_briefs/img/sf_route/sf_top_ortho_b200.png (snapshots/ e in .gitignore).
#
#   python tools/annotate_sf_plan.py [--snap "snapshots/san francisco.png"] [--size 780] [--out plan.png] [--check]
import io
import math
import os
import runpy
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]


def arg(name, default):
    return args[args.index(name) + 1] if name in args else default


SNAP = arg("--snap", os.path.join(ROOT, "docs", "asset_briefs", "img", "sf_route", "sf_top_ortho_b200.png"))
SIZE = float(arg("--size", "780"))   # `--size` dat lui snapshot.gd; 0 = cadrul implicit (bounds + 90 m)
OUT = arg("--out", os.path.join(ROOT, "docs", "asset_briefs", "img", "sf_route", "sf_plan_adnotat.png"))
CHECK = "--check" in args
FRACMAP = os.path.join(ROOT, "tools", "data", "sf_route_fracmap.tsv")

# --- geometria, din generator (mod DRY: nu scrie scena, OBJ-ul sau planul)
os.environ["SF_ROUTE_DRY"] = "1"
_old = sys.stdout
sys.stdout = io.StringIO()
try:
    G = runpy.run_path(os.path.join(ROOT, "tools", "gen_sf_route.py"), run_name="__main__")
finally:
    sys.stdout = _old
MK = G["MK"]
PTS = G["PTS"]
ELEV = G["ELEV"]
LIPS = G["LIPS"]
AXIS_Y = G["AXIS_Y"]
X_D0, X_D1 = G["X_D0"], G["X_D1"]
DECK = G["DECK"]
LANE_Z = G["LANE_Z"]

# --- maparea pixel <-> lume (snapshot.gd)
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
k = H / (SIZE if SIZE > 100.0 else max(ext_z, ext_x / (W / H)))
S = W / 1280.0   # scara fonturilor si a liniilor fata de captura de 1280 px


def px(x, y):
    """Harta (x est, y nord) -> Godot (x, -y) -> pixel."""
    return (W / 2 + (x - cx) * k, H / 2 + (-y - cz) * k)


def font(name, size):
    try:
        return ImageFont.truetype("C:/Windows/Fonts/" + name, int(size * S))
    except Exception:
        return ImageFont.load_default()


F = font("arialbd.ttf", 17)
Fs = font("arial.ttf", 13)
Fb = font("arialbd.ttf", 24)
Fl = font("arialbd.ttf", 15)

INK = (30, 28, 26, 255)
RED = (187, 53, 34, 255)          # KERB_RED 7, podul
ORANGE = (240, 150, 40, 255)      # despartitorul mobil
TRAM = (128, 28, 40, 255)         # visiniul tramvaiului
WHITE = (252, 248, 238, 255)
BLUE = (40, 70, 120, 255)
PINK = (214, 156, 172, 255)
BRICK = (165, 78, 60, 255)

LEG_H = int(250 * S)
im = Image.new("RGBA", (W, H + LEG_H), (241, 236, 222, 255))
im.paste(base, (0, 0))
ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)


def lw(v):
    return max(1, int(round(v * S)))


def text_box(x, y, s, f=Fs, fill=INK, bg=(252, 248, 238, 215), anchor="la"):
    l, t, r, b = dr.textbbox((x, y), s, font=f, anchor=anchor)
    pad = lw(3)
    dr.rectangle([l - pad, t - pad, r + pad, b + pad], fill=bg)
    dr.text((x, y), s, font=f, fill=fill, anchor=anchor)


def poly(points, col, w=2, closed=False):
    p = [px(*q) for q in points]
    if closed:
        p.append(p[0])
    dr.line(p, fill=col, width=lw(w), joint="curve")


def dashed(points, col, w=2, dash=8):
    p = [px(*q) for q in points]
    for a, b in zip(p, p[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(L / (dash * S)))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1.0, (i + 1) / n)
            dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=lw(w))


def arrow(a, b, col, w=3, head=9):
    pa, pb = px(*a), px(*b)
    dr.line([pa, pb], fill=col, width=lw(w))
    ang = math.atan2(pb[1] - pa[1], pb[0] - pa[0])
    hd = head * S
    dr.polygon([pb, (pb[0] - hd * math.cos(ang - 0.45), pb[1] - hd * math.sin(ang - 0.45)),
                (pb[0] - hd * math.cos(ang + 0.45), pb[1] - hd * math.sin(ang + 0.45))], fill=col)


def cross(x, y, col):
    p = px(x, y)
    r = 7 * S
    dr.line([(p[0] - r, p[1]), (p[0] + r, p[1])], fill=col, width=lw(2))
    dr.line([(p[0], p[1] - r), (p[0], p[1] + r)], fill=col, width=lw(2))


if CHECK:
    # Crucile de control: linia de start (far1) si capetele tablierului, pe axele benzilor.
    for key in ("far1", "tab0", "tab1", "lant0", "furca", "NE"):
        cross(MK[key][2], MK[key][3], (255, 0, 255, 255))
    out = Image.alpha_composite(im, ov).convert("RGB").crop((0, 0, W, H))
    out.save(OUT.replace(".png", "_check.png"))
    print("check scris", out.size, "k =", round(k, 4), "px/m; centru Godot", round(cx, 1), round(cz, 1))
    sys.exit(0)

# =============================================================================================
# GOLFUL: poligonul `custom_lagoon` din generator, hasurat. In captura B200 apa se vede doar in
# stramtoarea de sub pod (si acolo taiata pe diagonala); la N de chei si intre strada de intors si
# stramtoare captura arata uscat. Constatat la pasul 4 (15 nov 2026) si raportat; pentru diorama
# conteaza poligonul declarat, deci il desenam.
# =============================================================================================
lag = Image.new("RGBA", im.size, (0, 0, 0, 0))
ld = ImageDraw.Draw(lag)
lp = [px(*q) for q in G["LAGOON"]]
ld.polygon(lp, fill=(46, 95, 107, 120))
step = int(14 * S)
for xx in range(-H, W + H, step):
    ld.line([(xx, 0), (xx + H, H)], fill=(220, 235, 240, 70), width=lw(1))
ld.line(lp + [lp[0]], fill=BLUE, width=lw(2))
mask = Image.new("L", im.size, 0)
ImageDraw.Draw(mask).polygon(lp, fill=255)
ImageDraw.Draw(mask).line(lp + [lp[0]], fill=255, width=lw(3))
mask.paste(0, (0, H, W, H + LEG_H))
ov.paste(lag, (0, 0), mask)

# =============================================================================================
# PODUL ROSU: tablierul de 200 m, parapetele, portalurile, despartitorul mobil, camionul, sensurile
# =============================================================================================
y0, y1 = AXIS_Y - 12.7, AXIS_Y + 12.7
poly([(X_D0 - 12, y0), (X_D1 + 12, y0)], RED, 3)
poly([(X_D0 - 12, y1), (X_D1 + 12, y1)], RED, 3)
for xt in (X_D0 + DECK * 0.25, X_D0 + DECK * 0.75):
    a, b = px(xt - 1.5, AXIS_Y + 16), px(xt + 1.5, AXIS_Y - 16)
    dr.rectangle([a[0] - 2 * S, a[1], b[0] + 2 * S, b[1]], fill=RED)
# despartitorul: fix pe paliere, mobil (S-ul camionului) pe tablier
dashed([(MK["pod0"][2], AXIS_Y), (X_D0, AXIS_Y)], (110, 110, 110, 255), 2, 4)
dashed([(X_D1, AXIS_Y), (MK["far0"][2], AXIS_Y)], (110, 110, 110, 255), 2, 4)
s_t = X_D0 + 120.0       # camionul desenat la 120 m pe tablier
pts = []
for i in range(0, 201, 4):
    s = X_D0 + i
    u = max(0.0, min(1.0, (s - s_t + 15.0) / 30.0))
    sm = u * u * (3 - 2 * u)
    taper = min(1.0, i / 30.0, (DECK - i) / 30.0)
    pts.append((s, AXIS_Y - 3.5 * taper * (2 * sm - 1)))
poly(pts, ORANGE, 3)
a, b = px(s_t - 5, AXIS_Y + 1.3), px(s_t + 5, AXIS_Y - 1.3)
dr.rectangle([a[0], a[1], b[0], b[1]], fill=(70, 70, 75, 255))
# sensurile: circulatie pe STANGA
arrow((X_D1 - 20, AXIS_Y - LANE_Z), (X_D1 - 80, AXIS_Y - LANE_Z), WHITE, 3)
arrow((X_D0 + 20, AXIS_Y + LANE_Z), (X_D0 + 80, AXIS_Y + LANE_Z), WHITE, 3)
text_box(*px(200, 196), "P  PODUL ROSU carosabil, +20\n"
         "tablier 200 m, portaluri de 45 m\n"
         "dus-intors, circulatie pe STANGA\n"
         "despartitor mobil (portocaliu) + camion", Fs)
text_box(*px(282, 330), "camionul care muta despartitorul\n(naveta de 110 m, ciclu 63 s)", Fs)
# linia de start si grila (pe banda spre oras, dupa intoarcerea-balon)
sx, sy = MK["far1"][2], MK["far1"][3]
a, b = px(sx - 1.2, sy + 9.8), px(sx + 1.2, sy - 9.8)
for j in range(6):
    yy = a[1] + (b[1] - a[1]) * j / 6
    dr.rectangle([a[0], yy, b[0], yy + (b[1] - a[1]) / 6], fill=(WHITE if j % 2 else INK))
text_box(*px(522, 205), "START / SOSIRE: grila pe banda\nspre oras, dupa intoarcerea-balon", Fl)
text_box(*px(530, 300), "intoarcerea-balon pe malul\ncelalalt (R40-R20-R40), +20", Fs)
text_box(*px(158, 330), "capul de pod (+20):\nzid moale in S", Fs)

# =============================================================================================
# LANTUL: patru muchii cu zebra si semafor
# =============================================================================================
for n, L in enumerate(LIPS, 1):
    x, y = PTS[L]
    a, b = px(x - 7.5, y), px(x + 7.5, y)
    dr.line([a, b], fill=WHITE, width=lw(5))
    dr.line([a, b], fill=INK, width=lw(1))
    text_box(*px(x - 11, y + 3), "muchia %d  %+.1f" % (n, ELEV[L]), Fs, anchor="ra")
arrow((14, 20), (14, 190), INK, 2)

# =============================================================================================
# TRAMVAIELE (curbele BusHazard, din generator)
# =============================================================================================
t1 = [(p[0], -p[2]) for p in G["TRAM1_G"]]
poly(t1, TRAM, 3)
text_box(*px(28, 178), "tramvaiul 1 intra", Fs)
text_box(*px(152, -176), "tramvaiul 1 iese drept inainte", Fs, anchor="la")
t2 = list(G["TRAM2_MAP"])
poly(t2, TRAM, 3)
text_box(*px(-66, 430), "tramvaiul 2 trece\nprin gura scurtaturii", Fs, anchor="ra")
q = px(MK["placa"][2], MK["placa"][3])
dr.ellipse([q[0] - 7 * S, q[1] - 7 * S, q[0] + 7 * S, q[1] + 7 * S], outline=TRAM, width=lw(3))
text_box(*px(-135, 450), "placa turnanta (decor)", Fs, anchor="ra")

# =============================================================================================
# SERPENTINELE (E'), cheiul (F), pontonul, golful, insula, soarele
# =============================================================================================
for hx, hy in G["hp_map"]:
    c = px(hx, hy)
    dr.ellipse([c[0] - 6 * S, c[1] - 6 * S, c[0] + 6 * S, c[1] + 6 * S], fill=PINK, outline=BRICK, width=lw(2))
# pontonul: pozitie de confirmat
pa, pb = px(-40, 466), px(90, 474)
for xx in range(int(pa[0]), int(pb[0]), max(2, int(6 * S))):
    dr.line([(xx, pa[1]), (xx, pb[1])], fill=(140, 105, 70, 255), width=lw(2))
text_box(*px(110, 482), "pontonul de scandura + lei de mare pe plute (pozitie de confirmat la pasul 6)", Fs, anchor="mb")
top_y = -(cz - H / 2 / k)            # y-ul de harta al marginii de sus
text_box(*px(-330, 520), "GOLFUL: apa rece, albastru-inchis", Fl, fill=BLUE)
text_box(*px(370, 70), "stramtoarea de sub pod", Fl, fill=BLUE, anchor="ma")
text_box(*px(370, -40), "(golf deschis spre S)", Fs, fill=BLUE, anchor="ma")
text_box(*px(560, 120), "malul celalalt:\ndealuri aurii uscate", Fl)
# insula cu far: la ~80 m de mal, in axul lantului, dincolo de marginea de sus a capturii
arrow((0, top_y - 60), (0, top_y - 6), BLUE, 3)
text_box(*px(8, top_y - 10), "insula cu far: in axul lantului, ~80 m de mal (dincolo de cadru)", Fs, fill=BLUE)
# soarele: 28 grade, din S-SV (azimutul 192), aliniat cu lantul, din spate
arrow((-215, -222), (-180, -140), (225, 150, 40, 255), 4, 14)
text_box(*px(-170, -165), "soarele: jos (28 grade),\ncald, din S-SV", Fs)

# =============================================================================================
# POI-urile (litere in cerc); descrierea e in legenda
# =============================================================================================
POI = [("P", 370, 262), ("B", 172, 30), ("C", 78, -108), ("D", -32, 108), ("E", -62, 345),
       ("E'", 58, 345), ("F", -160, 488), ("G", 172, 380)]
for kk, mx, my in POI:
    x, y = px(mx, my)
    r = 15 * S
    dr.ellipse([x - r, y - r, x + r, y + r], fill=WHITE, outline=RED, width=lw(3))
    dr.text((x, y), kk, font=F, fill=INK, anchor="mm")
text_box(*px(78, -148), "coama +53: parcul, casele pictate", Fs, anchor="ma")

# =============================================================================================
# nordul, scara, legenda
# =============================================================================================
nx, ny = 50 * S, 50 * S
dr.line([(nx, ny + 44 * S), (nx, ny)], fill=INK, width=lw(3))
dr.polygon([(nx - 8 * S, ny + 14 * S), (nx, ny - 2 * S), (nx + 8 * S, ny + 14 * S)], fill=INK)
dr.text((nx, ny + 48 * S), "N", font=F, fill=INK, anchor="ma")
sx0, sy0 = 30 * S, H - 30 * S
dr.rectangle([sx0 - 6 * S, sy0 - 26 * S, sx0 + 100 * k + 40 * S, sy0 + 10 * S], fill=(252, 248, 238, 215))
dr.line([(sx0, sy0), (sx0 + 100 * k, sy0)], fill=INK, width=lw(4))
dr.text((sx0, sy0 - 22 * S), "100 m", font=Fs, fill=INK)

ly = H + 12 * S
dr.text((24 * S, ly), "San Francisco (Track25, bucla B200) — planul REAL al pistei, vazut de sus din Godot, cu legenda",
        font=Fb, fill=INK)
col1 = ["P  podul rosu: start pe banda spre oras, tablier 200 m, portaluri, despartitor mobil + camion",
        "B  strada tramvaiului 1: urcare spre S (+20 -> +53), case lipite, tramvaiul pe ax",
        "C  coama +53: parcul cu chiparosi, sirul de case pictate, cotul spre N",
        "D  lantul: 4 intersectii plate = 4 sarituri spre N, zebra + semafor pe fiecare muchie"]
col2 = ["E  terasa +14,6 si furca; ocolul de 400 m pe bulevard, placa turnanta la colt",
        "E' scurtatura: strada cu serpentine de caramida (3 ace), hortensii; tramvaiul 2 in gura",
        "F  cheiul de nord (+3): magazii de chei, pontonul de scandura, lei de mare",
        "G  strada de intors spre pod (+3 -> +20), al doilea pasaj peste pod, balonul"]
for i, t in enumerate(col1):
    dr.text((24 * S, ly + 40 * S + i * 22 * S), t, font=Fs, fill=INK)
for i, t in enumerate(col2):
    dr.text((W * 0.52, ly + 40 * S + i * 22 * S), t, font=Fs, fill=INK)
notes = ["rosu = podul (parapete, portaluri)  ·  portocaliu = despartitorul mobil  ·  visiniu = tramvaiele  ·  "
         "alb pe drum = muchiile lantului  ·  roz = straturile de hortensii  ·  hasura albastra = golful",
         "nord sus, est la DREAPTA (orientarea lumii din Godot)  ·  culorile drumului si ale solului din captura sunt "
         "placeholder  ·  sensul de mers: orar (P -> B -> C -> D -> E -> F -> G -> P)",
         "golful = poligonul declarat in generator; captura arata apa doar in stramtoare (defect de randare la pasul 4, raportat)"]
for i, t in enumerate(notes):
    dr.text((24 * S, ly + 40 * S + 4 * 22 * S + 10 * S + i * 20 * S), t, font=Fs, fill=INK)

out = Image.alpha_composite(im, ov).convert("RGB")
out.save(OUT, optimize=True)
print("scris", OUT, out.size, "k =", round(k, 4), "px/m; centru Godot", round(cx, 1), round(cz, 1))
