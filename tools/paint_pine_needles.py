"""Picteaza SURSA texturii de clasa `pine_needles` (acele coniferelor).

Rulare (din radacina repo-ului, Python 3 + Pillow + numpy):
    python tools/paint_pine_needles.py
Iesire: assets/textures/classes/src/pine_needles_src.png (1024x1024, tileabila)
Apoi:   godot --headless --path . --script res://tools/process_class_textures.gd
        (gradarea spre CACTUS_GREEN, 512x512, in assets/textures/classes/)

DE CE PICTATA SI NU FOTOGRAFIATA: toate celelalte clase vin din scanari
PolyHaven, dar pentru coroana unui conifer o fotografie e alegerea gresita —
o poza de crengi de brad e o suprafata cu ADANCIME (crengi peste crengi,
gauri spre interior), iar proiectata triplanar pe un con neted citeste ca un
tapet lipit strimb. Referinta vizuala (Beach Buggy Racing 2, Reckless Racing 3)
foloseste exact ce facem aici: tuse scurte de ac, in trei valori, pe un fond
intunecat — o textura care SUGEREAZA acele, fara sa pretinda relief.

Ce contine, si de ce fiecare strat:
  - fond intunecat, verde-brun: umbra din interiorul coroanei, cea care se
    vede printre ace. Fara el textura e o pata deschisa si coroana pare
    turtita ca fetrul (diagnosticul din #222 pe tint_gradient, aici in textura).
  - masca de "smocuri" de frecventa joasa: densitatea acelor variaza in
    pete de ~15-25 cm, ca ramurile sa se citeasca la 20-30 m, cand acele
    individuale s-au topit deja in mipmap.
  - trei straturi de tuse (intunecat, mediu, deschis), tot mai putine si mai
    scurte spre stratul deschis: acele din spate stau in umbra, cele din fata
    prind lumina — asa apare "grosimea" fara geometrie.
  - tusele sunt grupate in RAMURELE (ax + ace in spic pe ambele parti), care
    atarna in jos-lateral. Prima incercare, cu ace singure la unghiuri
    aleatoare, a iesit gazon: fara spic, o tusa verde e iarba.

Textura e TILEABILA: fiecare tusa se deseneaza si in copiile de la ±W/±H
cand cade langa margine.

Media de luminanta e tinuta in jurul ancorei CACTUS_GREEN (~106/255) ca
gradarea sa nu trebuiasca sa ridice sau sa coboare (vezi regula "ratie fata de
ancora" din memoria texturilor de clasa).
"""

import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "textures", "classes", "src",
                   "pine_needles_src.png")

W = H = 1024
SEED = 7

# Familia de culoare (RGB 0..255). Gradarea trage totul spre CACTUS_GREEN
# (#5B7C34), deci nuantele astea sunt DIRECTIA (umbra rece, lumina calda), nu
# valoarea finala.
BG_DARK = (34, 46, 24)
NEEDLE_DARK = (58, 82, 38)
NEEDLE_MID = (96, 128, 56)
NEEDLE_LIGHT = (150, 178, 84)


def _wrap_line(draw, p0, p1, fill, width):
    """Linie desenata si in copiile de tiling, cand atinge marginea."""
    x0, y0 = p0
    x1, y1 = p1
    xs = [0]
    ys = [0]
    if min(x0, x1) < 40:
        xs.append(W)
    if max(x0, x1) > W - 40:
        xs.append(-W)
    if min(y0, y1) < 40:
        ys.append(H)
    if max(y0, y1) > H - 40:
        ys.append(-H)
    for dx in xs:
        for dy in ys:
            draw.line([(x0 + dx, y0 + dy), (x1 + dx, y1 + dy)],
                      fill=fill, width=width)


def _tuft_mask(rng):
    """Pete moi de densitate, tileabile: suma de gaussiene periodice."""
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    acc = np.zeros((H, W), np.float32)
    for _ in range(90):
        cx, cy = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(70, 150)
        # distanta periodica (tiling)
        dx = np.abs(xx - cx)
        dx = np.minimum(dx, W - dx)
        dy = np.abs(yy - cy)
        dy = np.minimum(dy, H - dy)
        acc += np.exp(-(dx * dx + dy * dy) / (2 * r * r))
    # scoate gradientul de frecventa foarte joasa (media pe linii/coloane):
    # cu blob-uri aleatoare, o jumatate iesea cu ~9% mai deschisa decat
    # cealalta, si pe un con care se repeta asta devine banda
    acc -= acc.mean(axis=1, keepdims=True) - acc.mean()
    acc -= acc.mean(axis=0, keepdims=True) - acc.mean()
    acc -= acc.min()
    acc /= max(acc.max(), 1e-6)
    return acc  # 0 = gol intre ramuri, 1 = smoc dens


def _mix(c, k):
    return tuple(int(max(0, min(255, v * k))) for v in c)


def paint():
    rng = random.Random(SEED)
    nrng = np.random.default_rng(SEED)

    # 1. fondul: intunecat, cu zgomot fin (nu o culoare plata)
    noise = nrng.normal(0.0, 0.08, (H, W, 1)).astype(np.float32)
    bg = np.array(BG_DARK, np.float32)[None, None, :] * (1.0 + noise)
    img = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(img)

    tufts = _tuft_mask(rng)

    # 2. ramurelele. O tusa de ac singura citeste ca IARBA (prima incercare a
    # iesit gazon): ce face un conifer conifer e ca acele stau in FISCURI pe o
    # ramurica, in spic. Deci desenam ramurele: un ax scurt, intunecat, cu ace
    # pe ambele parti, inclinate spre varful ramurelei. Trei straturi, de la
    # umbra la lumina; ramurelele atarna (axul indreptat in jos-lateral).
    layers = (
        # culoare ace, nr ramurele, lungime ax (min,max), lungime ac (min,max),
        # latime ac, cat conteaza masca de smoc
        (NEEDLE_DARK, 2600, (60, 110), (12, 20), 3, 0.30),
        (NEEDLE_MID, 2000, (50, 95), (11, 18), 2, 0.70),
        (NEEDLE_LIGHT, 850, (40, 80), (9, 15), 2, 1.0),
    )
    axis_col = _mix(BG_DARK, 1.15)
    for color, count, (amin, amax), (nmin, nmax), width, tuft_w in layers:
        placed = 0
        while placed < count:
            x = rng.uniform(0, W)
            y = rng.uniform(0, H)
            keep = (1.0 - tuft_w) + tuft_w * tufts[int(y) % H, int(x) % W]
            if rng.random() > keep:
                continue
            placed += 1
            alen = rng.uniform(amin, amax)
            # axul atarna: in jos, inclinat stanga sau dreapta
            side = 1.0 if rng.random() < 0.5 else -1.0
            aang = math.radians(90.0 + side * rng.uniform(15.0, 55.0))
            if rng.random() < 0.12:
                aang = rng.uniform(0, math.tau)
            ax, ay = math.cos(aang), math.sin(aang)
            _wrap_line(draw, (x, y), (x + ax * alen, y + ay * alen),
                       axis_col, 2)
            # acele: la pas de ~4.5 px, alternand partile, inclinate spre varf
            step = 4.5
            n = int(alen / step)
            for i in range(n):
                t = (i + 0.5) * step
                px, py = x + ax * t, y + ay * t
                s = 1.0 if i % 2 == 0 else -1.0
                # spre varf: unghi de 55..75 grade fata de ax
                off = math.radians(rng.uniform(55.0, 75.0)) * s
                nang = aang - off
                # acele scad usor spre varful ramurelei
                nlen = rng.uniform(nmin, nmax) * (1.0 - 0.35 * t / alen)
                k = 1.0 + rng.uniform(-0.14, 0.14)
                c = list(_mix(color, k))
                if color is NEEDLE_LIGHT:
                    c[2] = int(c[2] * 0.9)
                elif color is NEEDLE_DARK:
                    c[2] = int(min(255, c[2] * 1.12))
                _wrap_line(draw, (px, py),
                           (px + math.cos(nang) * nlen, py + math.sin(nang) * nlen),
                           tuple(c), width)

    # 3. anti-aliasing usor: la 512 (dupa resize in pipeline) tusele de 2 px
    # ar sclipi altfel
    img = img.filter(ImageFilter.GaussianBlur(0.6))

    arr = np.asarray(img).astype(np.float32)
    lum = arr @ np.array([0.299, 0.587, 0.114], np.float32)
    print("luminanta medie %.1f (ancora CACTUS_GREEN ~106), sigma %.1f"
          % (lum.mean(), lum.std()))
    # deviatia in-dala (8 px la 512 = 16 px aici), mediana — criteriul din
    # measure_texture_src
    tiles = lum.reshape(H // 16, 16, W // 16, 16).std(axis=(1, 3))
    print("in-dala (mediana): %.1f" % np.median(tiles))
    l, r = lum[:, :W // 2].mean(), lum[:, W // 2:].mean()
    t, b = lum[:H // 2].mean(), lum[H // 2:].mean()
    print("dezechilibru st/dr %.1f%%  sus/jos %.1f%%"
          % (abs(l - r) / lum.mean() * 100, abs(t - b) / lum.mean() * 100))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, optimize=True)
    print("scris", os.path.normpath(OUT))


if __name__ == "__main__":
    paint()
