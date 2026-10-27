"""Lipeste q_<nume>_{0,90,180,270}.png (din `preview_fiordland_fidelity.py
--quad`) intr-un PNG 2x2: python tools/blender/tile_quad.py <dir> <nume>"""
import os
import sys
from PIL import Image

d, name = sys.argv[1], sys.argv[2]
parts = [os.path.join(d, "q_%s_%d.png" % (name, a)) for a in (0, 90, 180, 270)]
tiles = [Image.open(p).convert("RGB") for p in parts]
w, h = tiles[0].size
sheet = Image.new("RGB", (w * 2, h * 2))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % 2) * w, (i // 2) * h))
sheet.save(os.path.join(d, "quad_%s.png" % name))
for p in parts:
    os.remove(p)
