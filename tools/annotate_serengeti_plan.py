# Planul de referinta pentru ChatGPT: captura ORTOGRAFICA reala din Godot
# (snapshots/serengeti.png, tools/snapshot.gd --track=7) cu stratul de
# adnotari din Serengeti Recon desenat peste ea, la scara.
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), +z in jos pe ecran, +x la dreapta. Verificat pe
# linia de start (Godot (230, 165) -> px (970, 646), masurat in captura).
import json, math
from PIL import Image, ImageDraw, ImageFont

ROOT = "D:/GameDev/wt-serengeti/"
SCR = "C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/0dd689e2-275f-4198-86c9-c3f13042b5bf/scratchpad/"
d = json.load(open(SCR + "route14.json"))
gx = [-p[0] for p in d["route"]]; gz = [-p[1] for p in d["route"]]
bmin = (min(gx), min(gz)); bmax = (max(gx), max(gz))
cx, cz = (bmin[0] + bmax[0]) / 2, (bmin[1] + bmax[1]) / 2
ext_x, ext_z = bmax[0] - bmin[0] + 90, bmax[1] - bmin[1] + 90
W, H = 1280, 720
size = max(ext_z, ext_x / (W / H))
k = H / size

def px(mx, my):  # harta (x est, y nord) -> Godot (-x, -y) -> pixel
    return (W / 2 + (-mx - cx) * k, H / 2 + (-my - cz) * k)

base = Image.open(ROOT + "snapshots/serengeti.png").convert("RGBA")
LEG_H = 215
im = Image.new("RGBA", (W, H + LEG_H), (239, 231, 208, 255))
im.paste(base, (0, 0))
ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
dr = ImageDraw.Draw(ov)
try:
    F = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
    Fs = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
    Fb = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 26)
except Exception:
    F = Fs = Fb = ImageFont.load_default()

INK = (35, 32, 28, 255); RED = (180, 70, 43, 255); HAZ = (224, 69, 58, 255); PINK = (232, 108, 149, 255)
WHITE = (251, 247, 234, 255); STORM = (74, 68, 96, 255)

def dashed_rect(x0, y0, x1, y1, col, dash=6, w=2):
    pts = [(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)]
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        L = math.hypot(bx - ax, by - ay); n = max(1, int(L / dash))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1, (i + 1) / n)
            dr.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0), (ax + (bx - ax) * t1, ay + (by - ay) * t1)], fill=col, width=w)

# --- culoarul turmei (24 m pe drum, curgere N -> S) + sageti
cxp, cyp = px(-70, -165)
hw = 12 * k; hl = 49 * k
band = Image.new("RGBA", im.size, (0, 0, 0, 0)); bd = ImageDraw.Draw(band)
bd.rectangle([cxp - hw, cyp - hl, cxp + hw, cyp + hl], fill=(60, 45, 35, 70))
for yy in range(int(cyp - hl), int(cyp + hl), 9):
    bd.line([(cxp - hw, yy), (cxp + hw, yy + 8)], fill=(60, 45, 35, 120), width=1)
ov.alpha_composite(band)
for sgn in (-1, 1):
    ax = cxp + sgn * 6
    dr.line([(ax, cyp - hl + 6), (ax, cyp + hl - 6)], fill=INK, width=2)
    dr.polygon([(ax - 5, cyp + hl - 14), (ax, cyp + hl - 4), (ax + 5, cyp + hl - 14)], fill=INK)
dr.text((cxp + hw + 6, cyp - hl), "turma traverseaza\n(pulsuri, N -> S)", font=Fs, fill=INK)

# --- vadul, hipopotamii, kopje-kicker
fx, fy = px(75, -165)
dr.text((fx - 20, fy - 34), "vadul Mara", font=Fs, fill=INK)
for mx, my in [(70, -168), (75, -163), (80, -167)]:
    x, y = px(mx, my); dr.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(90, 85, 86, 255), outline=HAZ, width=2)
x, y = px(40, -138); dr.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(184, 180, 172, 255), outline=HAZ, width=2)
dr.text((x - 60, y - 26), "kopje-kicker", font=Fs, fill=INK)

# --- elefantii, vartejul (Lissajous), cireada, bolovanii, boma, leul
for mx, my in [(-20, -16), (35, -30), (10, -52)]:
    x, y = px(mx, my); dr.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(138, 133, 128, 255), outline=HAZ, width=2)
pts = []
for i in range(101):
    t = i / 100; pts.append(px(55 + 14 * math.sin(2 * math.pi * 3 * t), -40 + 26 * math.sin(2 * math.pi * 2 * t + 1.2)))
for a, b in zip(pts[::2], pts[1::2]): dr.line([a, b], fill=(120, 100, 60, 255), width=1)
x, y = px(55, -40); dr.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(201, 181, 138, 255), outline=HAZ, width=2)
dr.text((x + 10, y - 8), "vartej de praf", font=Fs, fill=INK)
x, y = px(-62, 170); dr.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(122, 90, 58, 255), outline=HAZ, width=2)
x, y = px(-62, 182); dr.ellipse([x - 9, y - 9, x + 9, y + 9], fill=(122, 90, 58, 255), outline=INK, width=1)
dr.text((x + 12, y - 8), "boma Maasai + cireada", font=Fs, fill=INK)
x, y = px(-100, 105); dr.ellipse([x - 5, y - 5, x + 5, y + 5], fill=(143, 138, 130, 255), outline=HAZ, width=2)
dr.text((x + 8, y - 18), "bolovani", font=Fs, fill=INK)
x, y = px(-250, -138); dr.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(184, 180, 172, 255), outline=INK, width=1)
dr.text((x - 40, y - 28), "kopje + leu", font=Fs, fill=INK)

# --- lacul: bordura de flamingi
lag = [px(x, y) for x, y in d["lagoon"]]
for a, b in zip(lag, lag[1:] + lag[:1]):
    L = math.hypot(b[0] - a[0], b[1] - a[1]); n = max(2, int(L / 6))
    for i in range(0, n, 2):
        t0, t1 = i / n, min(1, (i + 1) / n)
        dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0), (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=PINK, width=3)
lx, ly = px(d["crater"][0], d["crater"][1])
dr.text((lx - 52, ly + 48 * k), "lacul Magadi (flamingi)", font=Fs, fill=INK)
dr.text((lx - 70, ly - 20), "fundul craterului 2 m", font=Fs, fill=INK)

# --- loturi (aceleasi ca in Recon)
LOTS = [(-235, -150, 60, 36, "A"), (-70, -165, 40, 120, "B"), (75, -165, 40, 30, "C"), (190, -25, 80, 200, "D"),
        (30, 172, 240, 40, "E"), (-128, 80, 110, 110, "F"), (10, -25, 110, 60, "G"), (-10, -115, 24, 44, "H")]
for x0, y0, w, h, kk in LOTS:
    a = px(x0 - w / 2, y0 + h / 2); b = px(x0 + w / 2, y0 - h / 2)
    dashed_rect(min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]), (35, 32, 28, 170), 6, 1)

# --- POI-urile (litere in cerc)
POI = [("A", -230, -165, "start: campul de safari"), ("B", -70, -165, "raul de gnu"), ("C", 75, -165, "vadul Mara + hipopotami"),
       ("D", 190, -25, "padurea de ceata, urcarea"), ("E", 30, 172, "buza craterului"), ("F", -128, 80, "serpentinele Seneto"),
       ("G", 10, -14, "fundul craterului: elefanti, vartej"), ("H", -10, -115, "spartura Lerai")]
for kk, mx, my, _ in POI:
    x, y = px(mx, my)
    dr.ellipse([x - 14, y - 14, x + 14, y + 14], fill=WHITE, outline=RED, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, nordul, scara, furtuna
x, y = px(-150, -190)
dr.text((x - 60, y - 4), "<- sens de mers (spre B)", font=F, fill=INK)
nx, ny = 60, 60
dr.line([(nx, ny + 40), (nx, ny)], fill=INK, width=3); dr.polygon([(nx - 7, ny + 12), (nx, ny - 2), (nx + 7, ny + 12)], fill=INK)
dr.text((nx - 6, ny + 44), "N", font=F, fill=INK)
sx, sy = 40, H - 40
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
dr.rectangle([0, 0, W, 8], fill=STORM); dr.text((W / 2 - 150, 14), "frontul de furtuna la orizont (nord)", font=Fs, fill=STORM)
dr.text((W - 330, H - 60), "soarele din SV, jos, sub nori", font=Fs, fill=INK)

# --- legenda (banda de jos)
y0 = H + 12
dr.text((24, y0), "Serengeti / Ngorongoro (Track14) — planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A start: campul de safari sub kopje cu leu", "B raul de gnu: culoarul taie drumul, pulsuri N->S", "C vadul Mara: 3 hipopotami; kopje-kicker sare raul",
        "D padurea de ceata: urcarea 0 -> 45 m (11%)"]
col2 = ["E buza craterului: lacul roz 43 m mai jos, pe dreapta; boma + cireada", "F serpentinele Seneto: 45 -> 3 m, bolovani",
        "G fundul craterului: 3 elefanti, vartej de praf, crusta de soda", "H spartura Lerai: tunel deschis in granit, iesire in campie"]
for i, t in enumerate(col1): dr.text((24, y0 + 40 + i * 24), t, font=Fs, fill=INK)
for i, t in enumerate(col2): dr.text((560, y0 + 40 + i * 24), t, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 24 + 8), "cerc rosu = hazard   ·   linie roz = flamingi   ·   dreptunghi punctat = lot de assets   ·   sensul de mers: A -> B -> C ... craterul mereu pe dreapta masinii   ·   nord sus, est la stanga (orientarea lumii din Godot)", font=Fs, fill=INK)

out = Image.alpha_composite(im, ov).convert("RGB")
out.save(ROOT + "docs/track_briefs/img/serengeti_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1))
