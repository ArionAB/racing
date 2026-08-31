"""Panorama de oras pentru cerul Chongqing (`sky_cover` din tema).

    python tools/paint_sky_city.py

De ce e pictata si nu construita: brief-ul §2.0 masoara ca `ChaseCamera` vede
~5 grade deasupra orizontalei, deci dintr-un zgarie-nori de 100 m asezat langa
drum jucatorul ar vedea un perete de 12-15 m si atat. Orasul de fundal exista
doar ca sa dea ADANCIME la orizont, iar acolo un strat pictat costa zero draw
calls si zero triunghiuri.

Doua lucruri au fost masurate si amandoua au schimbat desenul:

1. `sky_cover` se ADUNA peste gradientul de cer. Deci un turn NU poate fi mai
   inchis decat cerul. Prima varianta desena corpuri de cladire (valoare 20-46)
   si iesea confetti: corpurile ADAUGAU lumina, deci turnurile erau mai
   deschise decat cerul si nu se citea nicio silueta. Acum se deseneaza doar
   LUMINA lor — ferestre plus haloul de ceata din jur — iar cladirea e cerul
   gol dintre ferestre, adica exact silueta inchisa din referinta, gratis.

2. Scara e UNGHIULARA, nu in metri. ProceduralSkyMaterial mapeaza textura pe o
   semisfera: v = 0.5 e orizontul, v = 0 e ZENITUL, deci 256 px = 90 grade.
   A doua varianta desena turnuri de 30-196 px = 11-69 GRADE de elevatie, adica
   zgarie-nori care acopereau doua treimi din bolta si „urcau pe cer" in loc sa
   stea la orizont. Un turn real la 1-3 km subintinde 3-12 grade.
"""
from PIL import Image, ImageDraw, ImageFilter
import os
import random

W, H = 2048, 512
HORIZON = H // 2
DEG = HORIZON / 90.0          # pixeli per grad de elevatie


def deg(x):
    return int(x * DEG)


def paint(out_path):
    rnd = random.Random(7)
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    halo = Image.new("RGB", (W, H), (0, 0, 0))
    hd = ImageDraw.Draw(halo)

    # Trei planuri de adancime. Latimea e tot unghiulara (2048 px = 360 grade,
    # deci ~40 px = 7 grade, cat un cvartal la 1-2 km). Turnurile sunt multe si
    # late dinadins: un oras e CONTINUU la orizont, iar varianta rara iesea
    # cateva blocuri izolate cu goluri intre ele.
    towers = []
    planes = [
        (150, 1.2, 3.5, 22, 52, 8),    # fund, aproape topit in ceata
        (95, 2.5, 6.5, 30, 70, 13),    # mijloc
        (55, 4.5, 10.0, 40, 92, 18),   # fata: cele care se citesc
    ]
    for plane, (count, dmin, dmax, wmin, wmax, hv) in enumerate(planes):
        for _ in range(count):
            bh = deg(rnd.uniform(dmin, dmax))
            bw = rnd.randint(wmin, wmax)
            x = rnd.randint(-60, W)
            top = HORIZON - bh
            towers.append((x, top, bw, bh, plane))
            # HALOUL da MASA: un dreptunghi difuz care spune „aici e o cladire"
            # chiar si acolo unde ferestrele sunt rare.
            hd.rectangle([x - 2, top - 2, x + bw + 2, HORIZON],
                         fill=(hv, int(hv * 0.86), int(hv * 0.62)))
    halo = halo.filter(ImageFilter.GaussianBlur(5))

    for (x, top, bw, bh, plane) in towers:
        if bw < 14 or bh < 9:
            continue
        win = [44, 84, 132][plane]
        dens = [0.26, 0.36, 0.44][plane]
        wx = x + 2
        while wx < x + bw - 2:
            wy = top + 4
            while wy < HORIZON - 3:
                if rnd.random() < dens:
                    w = rnd.random()
                    d.rectangle(
                        [wx, wy, wx + 1, wy + 2],
                        fill=(min(255, int(win * (0.95 + 0.18 * w))),
                              min(255, int(win * (0.70 + 0.16 * w))),
                              min(255, int(win * 0.40))))
                wy += 6
            wx += 5

    img = img.filter(ImageFilter.GaussianBlur(0.4))
    px = img.load()
    hpx = halo.load()
    for y in range(H):
        for x in range(W):
            r, g, b = px[x, y]
            hr, hg, hb = hpx[x, y]
            px[x, y] = (min(255, r + hr), min(255, g + hg), min(255, b + hb))

    # Ceata. Stinge spre linia orizontului si taie complet sub ea — o taietura
    # brusca exact pe HORIZON lasa o banda gri vizibila (masurat pe captura).
    soft = deg(4)
    band = deg(13)
    for y in range(H):
        if y > HORIZON:
            f = 0.0
        elif y > HORIZON - soft:
            f = (HORIZON - y) / float(soft) * 0.55
        else:
            t = max(0.0, min(1.0, (y - (HORIZON - band)) / float(band)))
            f = 1.0 - 0.45 * t * t
        for x in range(W):
            r, g, b = px[x, y]
            if r or g or b:
                px[x, y] = (int(r * f), int(g * f), int(b * f))

    img.save(out_path)
    return os.path.getsize(out_path) / 1024.0


if __name__ == "__main__":
    out = os.path.join("assets", "textures", "sky_city_chongqing.png")
    print("scris %s (%.0f KB)" % (out, paint(out)))
