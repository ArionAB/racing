import sys
from PIL import Image
names = sys.argv[2].split(",")
out = sys.argv[1]
H = 520
rows = [[], []]
for n in names:
    c = Image.open("docs/track_briefs/img/kyoto_assets_v1/%s.png" % n).convert("RGB")
    c = c.resize((int(c.width * H / c.height), H), Image.LANCZOS)
    r = Image.open("docs/asset_briefs/img/kyoto_fidelity/_render_%s.png" % n).convert("RGBA")
    bg = Image.new("RGBA", r.size, (207, 207, 207, 255)); r = Image.alpha_composite(bg, r).convert("RGB")
    r = r.resize((int(r.width * H / r.height), H), Image.LANCZOS)
    rows[0].append(c); rows[1].append(r)
w = max(sum(i.width for i in row) + 10 * (len(row) - 1) for row in rows)
img = Image.new("RGB", (w, 2 * H + 10), (207, 207, 207))
for k, row in enumerate(rows):
    x = 0
    for i in row:
        img.paste(i, (x, k * (H + 10))); x += i.width + 10
img.save(out); print(out)
