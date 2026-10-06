"""Aseaza randarea de grup (Blender) sub/langa randul din planșa de inventar.

    python tools/blender/compose_kyoto_group.py --render <png> --row y0,y1 --out <png>

`--row` sunt randurile de pixeli din inventar_v02.jpg (1024x1536).
"""
import argparse
import os

from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("--render")
ap.add_argument("--row")
ap.add_argument("--out")
a = ap.parse_args()
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
inv = Image.open(os.path.join(root, "docs", "track_briefs", "img", "kyoto_plan",
                              "inventar_v02.jpg")).convert("RGB")
y0, y1 = [int(v) for v in a.row.split(",")]
strip = inv.crop((0, y0, inv.width, y1))
ren = Image.open(a.render).convert("RGBA")
bg = Image.new("RGBA", ren.size, (207, 207, 207, 255))
ren = Image.alpha_composite(bg, ren).convert("RGB")
w = 1600
strip = strip.resize((w, int(strip.height * w / strip.width)))
ren = ren.resize((w, int(ren.height * w / ren.width)))
out = Image.new("RGB", (w, strip.height + ren.height + 10), (207, 207, 207))
out.paste(strip, (0, 0))
out.paste(ren, (0, strip.height + 10))
out.save(a.out)
print("plansa:", a.out)
