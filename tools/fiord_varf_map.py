#!/usr/bin/env python3
"""Harta de sus a Fiordlandului din cotele REALE ale terenului, cu varful.

Consuma CSV-urile scrise de `res://tools/SvFiordVarfGrid.tscn` (ground_y pe
grila de 10 m + punctele coapte cu fractia lor) si deseneaza un PNG: apa
(albastru), uscat pe cote, drumul cu fractiile din 0,05 in 0,05, cercul
fiecarui varf cerut si razele de la 0,02 / 0,17 / 0,63 / 0,70 spre el.

    godot --headless --path . res://tools/SvFiordVarfGrid.tscn -- --out=DIR
    python tools/fiord_varf_map.py DIR harta.png [x,z,raza,eticheta ...]

A existat ca sa se vada dintr-o privire de ce Mitre Peak nu e in cadru:
golful e in SPATELE-stanga cornisei B (care urca spre NV) si in dreapta
coborarii F (care coboara spre S/SE). Vezi `fiord_frustum_table.py`.
"""
import sys
from PIL import Image, ImageDraw

d, out = sys.argv[1], sys.argv[2]
peaks = []
for a in sys.argv[3:]:
    x, z, r, lab = a.split(",")
    peaks.append((float(x), float(z), float(r), lab))
hdr = open(d + "/grid.csv").readline().strip("# \n").split()
meta = {k: float(v) for k, v in (h.split("=") for h in hdr)}
rows = [[float(v) for v in l.split(",")] for l in open(d + "/grid.csv") if not l.startswith("#")]
H, W = len(rows), len(rows[0])
cell, x0, z0, sea = meta["cell"], meta["x0"], meta["z0"], meta["sea_y"]
S = 7
img = Image.new("RGB", (W * S, H * S))
px = img.load()
for j, row in enumerate(rows):
    for i, y in enumerate(row):
        if y < sea:
            c = (30, 60, 110) if y < sea - 10 else (60, 110, 160)
        elif y < 25:
            c = (90, int(120 + (y + 2) / 27 * 60), 70)
        elif y < 60:
            g = int(150 + (y - 25) / 35 * 60)
            c = (g, g, g - 20)
        else:
            c = (255, 255, 255) if y > 85 else (230, 230, 240)
        for a in range(S):
            for b in range(S):
                px[i * S + a, j * S + b] = c
dr = ImageDraw.Draw(img)


def P(x, z):
    return ((x - x0) / cell * S, (z - z0) / cell * S)


bk = [tuple(float(v) for v in l.split(",")) for l in open(d + "/baked.csv")]
pts = [P(b[1], b[3]) for b in bk]
dr.line(pts + [pts[0]], fill=(0, 0, 0), width=3)
marks = [k / 100 for k in range(0, 100, 5)] + [0.13, 0.21, 0.74, 0.17, 0.63, 0.02]
for b in bk:
    f = b[0]
    if any(abs(f - m) < 0.00047 for m in marks):
        x, y = P(b[1], b[3])
        dr.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(255, 0, 0))
        dr.text((x + 6, y - 6), "%.2f y%.0f" % (f, b[2]), fill=(255, 255, 0))
for (x, z, r, lab) in peaks:
    cx, cy = P(x, z)
    rr = r / cell * S
    dr.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=(255, 0, 255), width=3)
    dr.text((cx + 4, cy + 4), lab, fill=(255, 0, 255))
    for f in (0.02, 0.17, 0.63, 0.70):
        b = min(bk, key=lambda b: abs(b[0] - f))
        dr.line([P(b[1], b[3]), (cx, cy)], fill=(255, 128, 0), width=1)
for gx in range(int(x0), int(x0 + W * cell), 100):
    x, _ = P(gx, 0)
    dr.line([(x, 0), (x, H * S)], fill=(80, 80, 80), width=1)
    dr.text((x + 2, 2), str(gx), fill=(200, 200, 200))
for gz in range(int(z0), int(z0 + H * cell), 100):
    _, y = P(0, gz)
    dr.line([(0, y), (W * S, y)], fill=(80, 80, 80), width=1)
    dr.text((2, y + 2), str(gz), fill=(200, 200, 200))
img.save(out)
print("scris", out, img.size)
