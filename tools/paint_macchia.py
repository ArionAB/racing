"""Picteaza SURSA texturii de clasa `macchia` (frunzisul mediteranean).

Rulare (din radacina repo-ului, Python 3 + Pillow + numpy):
    python tools/paint_macchia.py
Iesire: assets/textures/classes/src/macchia_src.png (1024x1024, tileabila)
Apoi:   godot --headless --path . --script res://tools/process_class_textures.gd
        (gradarea spre TROPICAL_GREEN, 512x512, in assets/textures/classes/)

PENTRU CE EXISTA: pe Stromboli TOT frunzisul statea pe atlas, adica pe o
singura culoare plata per slot — masurat cu o sonda pe GLB-uri (vezi tabelul
din PR): din 9 piese de planta/arbore, doar cele 3 TRUNCHIURI aveau clasa
(`bark`), iar toate coroanele, tufele, paletele de prickly pear si trestia
cadeau pe atlas. Pe captura de sofer (snapshots/stromboli_sofer.png) tufa de
ginestra iesea un BLOB GALBEN uniform langa un teren cu textura fotografica —
exact diagnosticul din memoria „fidelitate vizuala": problema nu e poligonajul,
sunt culorile plate.

DE CE PICTATA SI NU FOTOGRAFIATA: acelasi motiv ca la `pine_needles`
(tools/paint_pine_needles.py) — o fotografie de tufa are ADANCIME (frunze
peste frunze, gauri spre interior), iar proiectata triplanar pe un volum neted
citeste ca tapet. Referinta (Beach Buggy Racing 2) foloseste tuse scurte de
frunza in cateva valori pe un fond intunecat: o textura care SUGEREAZA frunzis,
fara sa pretinda relief.

CE E ALTFEL FATA DE ACE, si de ce nu se putea reutiliza `pine_needles`:
  - frunza de macchia e LATA si scurta (mirt, lentisc, caper), nu un ac de
    1-2 cm. Tusele sunt elipse, nu linii — la scara de joc o linie subtire
    citeste iarba, o pata lata citeste frunza.
  - frunzele stau in BUCHETE la capat de lastar, nu in spic pe ambele parti
    ale unei ramurele. Deci: un lastar scurt, si 3-6 frunze imprastiate in
    evantai la capatul lui.
  - familia de culoare e mai USCATA si mai argintie (verde-masliniu cu praf),
    nu verdele rece si saturat al bradului. Tufele de pe un con vulcanic stau
    in soare si praf vulcanic.

Media de luminanta e tinuta in jurul ancorei TROPICAL_GREEN ca gradarea sa nu
trebuiasca sa ridice sau sa coboare (regula „ratie fata de ancora" din memoria
texturilor de clasa).
"""

import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "textures", "classes", "src",
                   "macchia_src.png")

W = H = 1024
SEED = 11

# Familia de culoare (RGB 0..255). Gradarea trage totul spre TROPICAL_GREEN,
# deci nuantele astea sunt DIRECTIA (umbra din interiorul tufei, frunza la
# soare), nu valoarea finala. Fata de brad: mai putin saturate si mai calde —
# frunzisul mediteranean e prafuit, nu smarald.
BG_DARK = (34, 43, 27)
LEAF_DARK = (60, 78, 45)
LEAF_MID = (102, 124, 68)
LEAF_LIGHT = (152, 168, 100)
# Cateva frunze intoarse cu dosul argintiu (mirt, maslin salbatic): pata care
# opreste tufa sa fie o masa uniforma de verde.
LEAF_SILVER = (166, 172, 138)


def _wrap_ellipse(draw, cx, cy, rx, ry, ang, fill):
    """Frunza (elipsa rotita) desenata si in copiile de tiling.

    Pillow nu deseneaza elipse rotite, deci frunza e un poligon de 10 laturi —
    destul la 1024, si mai ieftin decat o masca per frunza.
    """
    ca, sa = math.cos(ang), math.sin(ang)
    base = []
    for i in range(10):
        t = math.tau * i / 10.0
        px, py = rx * math.cos(t), ry * math.sin(t)
        base.append((px * ca - py * sa, px * sa + py * ca))
    xs = [0]
    ys = [0]
    m = max(rx, ry) + 4
    if cx < m:
        xs.append(W)
    if cx > W - m:
        xs.append(-W)
    if cy < m:
        ys.append(H)
    if cy > H - m:
        ys.append(-H)
    for dx in xs:
        for dy in ys:
            draw.polygon([(cx + dx + px, cy + dy + py) for px, py in base],
                         fill=fill)


def _wrap_line(draw, p0, p1, fill, width):
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


def _clump_mask(rng):
    """Pete moi de densitate, tileabile: suma de gaussiene periodice.

    Aceeasi mecanica ca la brazi, dar cu raze mai MICI (50-110 fata de 70-150):
    o tufa de macchia e o gramada de buchete de 20-30 cm, nu ramuri de un metru.
    Corectia de gradient de frecventa joasa ramane — fara ea o jumatate de dala
    iese mai deschisa si pe un volum care se repeta devine banda.
    """
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    acc = np.zeros((H, W), np.float32)
    for _ in range(110):
        cx, cy = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(50, 110)
        dx = np.abs(xx - cx)
        dx = np.minimum(dx, W - dx)
        dy = np.abs(yy - cy)
        dy = np.minimum(dy, H - dy)
        acc += np.exp(-(dx * dx + dy * dy) / (2 * r * r))
    acc -= acc.mean(axis=1, keepdims=True) - acc.mean()
    acc -= acc.mean(axis=0, keepdims=True) - acc.mean()
    acc -= acc.min()
    acc /= max(acc.max(), 1e-6)
    return acc


def _mix(c, k):
    return tuple(int(max(0, min(255, v * k))) for v in c)


def paint():
    rng = random.Random(SEED)
    nrng = np.random.default_rng(SEED)

    # 1. fondul: umbra din interiorul tufei, cu zgomot fin (nu culoare plata).
    noise = nrng.normal(0.0, 0.08, (H, W, 1)).astype(np.float32)
    bg = np.array(BG_DARK, np.float32)[None, None, :] * (1.0 + noise)
    img = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(img)

    clumps = _clump_mask(rng)
    twig_col = _mix(BG_DARK, 1.35)

    # 2. buchetele. Trei straturi de la umbra la lumina, tot mai putine: cele
    # din spate stau in interiorul tufei, cele din fata prind soarele. Asa
    # apare grosimea fara geometrie (acelasi rationament ca la ace).
    layers = (
        # culoare, nr buchete, lungime lastar, raza frunzei (min,max), masca
        (LEAF_DARK, 1500, (26, 52), (7.0, 12.0), 0.30),
        (LEAF_MID, 1150, (22, 46), (6.5, 11.0), 0.70),
        (LEAF_LIGHT, 700, (18, 40), (6.0, 10.0), 1.0),
    )
    for color, count, (amin, amax), (rmin, rmax), clump_w in layers:
        placed = 0
        while placed < count:
            x = rng.uniform(0, W)
            y = rng.uniform(0, H)
            keep = (1.0 - clump_w) + clump_w * clumps[int(y) % H, int(x) % W]
            if rng.random() > keep:
                continue
            placed += 1
            alen = rng.uniform(amin, amax)
            aang = rng.uniform(0.0, math.tau)
            ax, ay = math.cos(aang), math.sin(aang)
            # lastarul: scurt, vizibil doar pe alocuri printre frunze
            _wrap_line(draw, (x, y), (x + ax * alen, y + ay * alen),
                       twig_col, 2)
            # frunzele: evantai la CAPATUL lastarului, nu in spic pe el
            tipx, tipy = x + ax * alen, y + ay * alen
            for _ in range(rng.randint(3, 6)):
                spread = rng.uniform(-1.0, 1.0)
                lang = aang + spread * 0.9
                # frunza pleaca din capat, putin imprastiata
                d = rng.uniform(0.0, 0.42) * alen
                lx = tipx + math.cos(lang) * d
                ly = tipy + math.sin(lang) * d
                ry = rng.uniform(rmin, rmax)
                # lata, dar nu rotunda: raportul face frunza, nu bulina
                rx = ry * rng.uniform(0.42, 0.62)
                k = 1.0 + rng.uniform(-0.16, 0.16)
                c = list(_mix(color, k))
                if color is LEAF_LIGHT:
                    c[2] = int(c[2] * 0.88)   # lumina calda
                elif color is LEAF_DARK:
                    c[2] = int(min(255, c[2] * 1.10))  # umbra rece
                _wrap_ellipse(draw, lx, ly, rx, ry, lang, tuple(c))

    # 3. dosul argintiu al catorva frunze. Putine (5% din stratul luminat):
    # destule cat sa rupa masa de verde, prea putine cat sa para bruma.
    for _ in range(260):
        x = rng.uniform(0, W)
        y = rng.uniform(0, H)
        if rng.random() > clumps[int(y) % H, int(x) % W]:
            continue
        ry = rng.uniform(5.5, 9.0)
        _wrap_ellipse(draw, x, y, ry * rng.uniform(0.42, 0.60), ry,
                      rng.uniform(0, math.tau),
                      _mix(LEAF_SILVER, 1.0 + rng.uniform(-0.10, 0.10)))

    # 4. anti-aliasing usor: la 512 (dupa resize in pipeline) tusele mici ar
    # sclipi altfel.
    img = img.filter(ImageFilter.GaussianBlur(0.6))

    arr = np.asarray(img).astype(np.float32)
    lum = arr @ np.array([0.299, 0.587, 0.114], np.float32)
    print("luminanta medie %.1f (ancora TROPICAL_GREEN), sigma %.1f"
          % (lum.mean(), lum.std()))
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
