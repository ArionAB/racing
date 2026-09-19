import sys, colorsys
from PIL import Image

def hsv_stats(px):
    if not px:
        return None
    rs = sum(p[0] for p in px)/len(px)
    gs = sum(p[1] for p in px)/len(px)
    bs = sum(p[2] for p in px)/len(px)
    h, s, v = colorsys.rgb_to_hsv(rs/255, gs/255, bs/255)
    return (rs, gs, bs, h*360, s, v, rs-bs, len(px))

def report(name, px):
    st = hsv_stats(px)
    if st is None:
        print("%-22s  (gol)" % name); return
    print("%-22s rgb(%3.0f,%3.0f,%3.0f)  H %5.1f  S %.2f  V %.2f  R-B %+5.1f  n=%d"
          % (name, st[0], st[1], st[2], st[3], st[4], st[5], st[6], st[7]))

def classify(img, box=None):
    im = img.convert("RGB")
    W, H = im.size
    if box:
        im = im.crop(box); W, H = im.size
    p = im.load()
    piatra, verde, apa, spuma, cer = [], [], [], [], []
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            r, g, b = p[x, y]
            h, s, v = colorsys.rgb_to_hsv(r/255, g/255, b/255)
            hd = h*360
            if v > 0.86 and s < 0.10:
                spuma.append((r, g, b))
            elif v > 0.80 and s < 0.16 and 180 < hd < 260:
                cer.append((r, g, b))
            elif 60 < hd < 160 and s > 0.14:
                verde.append((r, g, b))
            elif s < 0.20 and 0.15 < v < 0.72:
                apa.append((r, g, b))
            elif (hd < 60 or hd > 330) and s > 0.10 and v > 0.28:
                piatra.append((r, g, b))
    tot = W*H/4
    print("  acoperire: piatra %.1f%%  verde %.1f%%  apa %.1f%%  spuma %.1f%%  cer %.1f%%" % (
        100*len(piatra)/tot, 100*len(verde)/tot, 100*len(apa)/tot,
        100*len(spuma)/tot, 100*len(cer)/tot))
    report("  piatra", piatra)
    report("  verde", verde)
    report("  apa", apa)
    report("  spuma", spuma)

for path in sys.argv[1:]:
    print("== " + path.split("/")[-1].split("\\")[-1])
    classify(Image.open(path))
