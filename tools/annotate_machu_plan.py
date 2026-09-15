# Planul de referinta pentru ChatGPT (Machu Picchu, Track15): captura
# ORTOGRAFICA reala din Godot (snapshots/machu picchu.png, rulata cu
# tools/snapshot.gd --track=8 --bus-at=30) cu stratul de adnotari din
# „Machu Picchu Recon" desenat peste ea, la scara. Reteta e cea din
# tools/annotate_serengeti_plan.py.
#
# Maparea pixel <-> lume e cea din snapshot.gd: cam.size = max(extent_z,
# extent_x / aspect) pe verticala, centrul = mijlocul bounds-ului punctelor
# coapte (+90 m margine), +z in jos pe ecran, +x la dreapta (vedere reala de
# sus: nord sus, est la stanga). Rulare:
#   python tools/annotate_machu_plan.py <route15.json> [snapshot.png]
import json, math, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = "D:/GameDev/ignition-spike/"
route_json = sys.argv[1]
snap = sys.argv[2] if len(sys.argv) > 2 else ROOT + "snapshots/machu picchu.png"
d = json.load(open(route_json))
# harta (x est, y nord) -> Godot (-x, -z)
gx = [-p[0] for p in d["route"]]; gz = [-p[1] for p in d["route"]]
bmin = (min(gx), min(gz)); bmax = (max(gx), max(gz))
cx, cz = (bmin[0] + bmax[0]) / 2, (bmin[1] + bmax[1]) / 2
ext_x, ext_z = bmax[0] - bmin[0] + 90, bmax[1] - bmin[1] + 90
base = Image.open(snap).convert("RGBA")
W, H = base.size
size = max(ext_z, ext_x / (W / H))
k = H / size

def px(mx, my):
    return (W / 2 + (-mx - cx) * k, H / 2 + (-my - cz) * k)

def gpx(x, z):  # direct din coordonate Godot
    return (W / 2 + (x - cx) * k, H / 2 + (z - cz) * k)

LEG_H = 230
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
STRAW = (217, 184, 92, 255); WHITE = (245, 243, 238, 255); RUST = (163, 74, 44, 255)

def dashed_rect(x0, y0, x1, y1, col, dash=6, w=2):
    pts = [(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)]
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        L = math.hypot(bx - ax, by - ay); n = max(1, int(L / dash))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1, (i + 1) / n)
            dr.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0), (ax + (bx - ax) * t1, ay + (by - ay) * t1)], fill=col, width=w)

def dashed_poly(pts, col, dash=7, w=2):
    for a, b in zip(pts, pts[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1]); n = max(1, int(L / dash))
        for i in range(0, n, 2):
            t0, t1 = i / n, min(1, (i + 1) / n)
            dr.line([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0), (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], fill=col, width=w)

def dot(x, y, fill, r=6, ring=True):
    dr.ellipse([x - r, y - r, x + r, y + r], fill=fill, outline=HAZ if ring else INK, width=2 if ring else 1)

# --- podul de franghie (E): tablier 35 m intre x=-3.4 si 30.8 la z=-155
a = gpx(-3.4, -155); b = gpx(30.8, -155)
dr.line([a, b], fill=STRAW, width=7); dr.line([a, b], fill=HAZ, width=2)
for x, z in ((-3.4, -155), (30.8, -155)):
    p = gpx(x, z); dr.rectangle([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], fill=(170, 165, 155, 255), outline=INK)
dr.text((b[0] + 8, b[1] - 30), "podul de franghie (se afunda)", font=Fs, fill=INK)

# --- barnele Podului Incas (H): gol de 4 m la (-140, 64)
p = gpx(-140, 63.9); dot(p[0], p[1], (120, 90, 50, 255), 6)
dr.text((p[0] + 34, p[1] - 8), "barnele lipsesc 6 s / 28 s", font=Fs, fill=INK)

# --- norul (B-C): culoar 40 x 18 m la (167, 107), pe directia x
p = gpx(166.9, 107.0)
band = Image.new("RGBA", im.size, (0, 0, 0, 0)); bd = ImageDraw.Draw(band)
bd.rectangle([p[0] - 20 * k, p[1] - 9 * k, p[0] + 20 * k, p[1] + 9 * k], fill=(245, 243, 238, 140), outline=(255, 255, 255, 220))
ov.alpha_composite(band)
dr.text((p[0] - 60, p[1] + 9 * k + 4), "norul urca din defileu", font=Fs, fill=INK)

# --- lamele (D): terasa a 5-a la (88, -191..-200)
for z in (-200.2, -197.0, -194.0, -191.0):
    p = gpx(88.0, z); dot(p[0], p[1], WHITE, 4)
p = gpx(88, -204); dr.text((p[0] - 30, p[1] - 22), "lame (traverseaza)", font=Fs, fill=INK)

# --- trenul (F): sina de 130 m pe x, la z=-205
a = gpx(-225, -205); b = gpx(-95, -205)
dr.line([a, b], fill=BLUE, width=3)
for t in range(0, 14):
    x = a[0] + (b[0] - a[0]) * t / 13; dr.line([(x, a[1] - 4), (x, a[1] + 4)], fill=BLUE, width=1)
dr.text((a[0], a[1] - 24), "trenul PeruRail pe mal (decor)", font=Fs, fill=INK)

# --- autobuzul (G): traseul lui pe serpentine
bus = [px(p[0], p[1]) for p in d["bus"]]
dashed_poly(bus, (230, 190, 40, 255), 7, 3)
p = bus[len(bus) // 2]; dot(p[0], p[1], (240, 200, 40, 255), 7)
dr.text((p[0] + 14, p[1] - 8), "autobuzul coboara", font=Fs, fill=INK)

# --- Huayna Picchu, Poarta Soarelui, condorul, Casa Paznicului
# varful e la (215, -265), la 45 m in afara cadrului ortografic: marcam directia
p = gpx(215, -265); p = (p[0], max(p[1], 26))
dr.polygon([(p[0] - 9, p[1] + 8), (p[0], p[1] - 8), (p[0] + 9, p[1] + 8)], fill=(200, 196, 188, 255), outline=INK)
dr.text((p[0] - 150, p[1] + 12), "Huayna Picchu (+30 m, decor) - 45 m mai la nord", font=Fs, fill=INK)
p = gpx(230.2, 61.2); dot(p[0], p[1], (200, 196, 188, 255), 6, False)
dr.text((p[0] + 12, p[1] - 8), "Poarta Soarelui + condor", font=Fs, fill=INK)
p = gpx(223.5, -150); dot(p[0], p[1], STRAW, 5, False)
dr.text((p[0] + 12, p[1] - 8), "Casa Paznicului (cadrul pozei)", font=Fs, fill=INK)

# --- loturi (dreptunghiuri punctate, in coordonate de harta)
LOTS = [(105, -150, 70, 40, "A"), (-108, -122, 220, 40, "B"), (-232, 20, 40, 300, "C"), (-90, 180, 130, 60, "D"),
        (-14, 155, 44, 24, "E"), (155, 170, 130, 50, "F"), (178, 75, 90, 150, "G"), (140, -60, 26, 150, "H")]
for x0, y0, w, h, kk in LOTS:
    a = px(x0 - w / 2, y0 + h / 2); b = px(x0 + w / 2, y0 - h / 2)
    dashed_rect(min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]), (31, 36, 32, 170), 6, 1)

# --- POI-urile (litere in cerc)
POI = [("A", 105, -150), ("B", -125, -115), ("C", -232, 60), ("D", -100, 195), ("E", -14, 140),
       ("F", 200, 178), ("G", 205, 75), ("H", 128, -64)]
for kk, mx, my in POI:
    x, y = px(mx, my)
    dr.ellipse([x - 14, y - 14, x + 14, y + 14], fill=WHITE, outline=BLUE, width=3)
    tw = dr.textlength(kk, font=F); dr.text((x - tw / 2, y - 11), kk, font=F, fill=INK)

# --- sensul, nordul, scara, soarele
x, y = px(20, -170)
dr.text((x - 90, y - 4), "sens de mers -> (spre B, urcarea pe trepte)", font=F, fill=INK)
nx, ny = 60, 60
dr.line([(nx, ny + 40), (nx, ny)], fill=INK, width=3); dr.polygon([(nx - 7, ny + 12), (nx, ny - 2), (nx + 7, ny + 12)], fill=INK)
dr.text((nx - 6, ny + 44), "N", font=F, fill=INK)
sx, sy = 40, H - 40
dr.line([(sx, sy), (sx + 100 * k, sy)], fill=INK, width=4)
dr.text((sx, sy - 22), "100 m", font=Fs, fill=INK)
dr.text((W - 300, H - 60), "soarele din SV, 40 grade sus, cer senin", font=Fs, fill=INK)

# --- legenda (banda de jos)
y0 = H + 12
dr.text((24, y0), "Machu Picchu (Track15) - planul REAL al pistei, vazut de sus din Godot, cu legenda", font=Fb, fill=INK)
col1 = ["A start: Piata Sacra, pavaj de granit intre ziduri (0 m)", "B Drumul Incas: trepte de piatra 0 -> 35 m, tunel, norul care urca",
        "C Poarta Soarelui + creasta: gol de ambele parti, cetatea sub tine, Huayna Picchu in fata",
        "D cascada de terase: 10 trepte de 2,5 m, rampe sau direct; lamele traverseaza"]
col2 = ["E podul de franghie: 35 m, se afunda si se leagana sub masa", "F malul raului: cel mai jos punct (-30 m), trenul pe mal",
        "G serpentinele Hiram Bingham: 4 ace, autobuzul coboara spre tine", "H cornisa Podului Incas: barnele lipsesc pe ciclu, poarta de 4 m"]
for i, t in enumerate(col1): dr.text((24, y0 + 40 + i * 24), t, font=Fs, fill=INK)
for i, t in enumerate(col2): dr.text((640, y0 + 40 + i * 24), t, font=Fs, fill=INK)
dr.text((24, y0 + 40 + 4 * 24 + 8), "cerc rosu = hazard   ·   galben punctat = traseul autobuzului   ·   dreptunghi punctat = lot de assets   ·   sens antiorar A -> B -> C, defileul pe DREAPTA masinii   ·   nord sus, est la stanga (Godot)", font=Fs, fill=INK)

out = Image.alpha_composite(im, ov).convert("RGB")
out.save(ROOT + "docs/track_briefs/img/machu_picchu_plan.png", optimize=True)
print("scris", out.size, "k =", round(k, 4), "centru", round(cx, 1), round(cz, 1))
