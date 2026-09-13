"""Picteaza SURSA texturii de clasa `acacia_canopy` (coroana acaciilor-umbrela
si a rudelor lor de savana: fever_tree, fig_tree, euphorbia).

Rulare (din radacina repo-ului, Python 3 + Pillow + numpy):
    python tools/paint_acacia_canopy.py
Iesire: assets/textures/classes/src/acacia_canopy_src.png (1024x1024, tileabila)
Apoi:   godot --headless --path . --script res://tools/process_class_textures.gd
        (gradarea spre CACTUS_GREEN, 512x512, in assets/textures/classes/)

PENTRU CE EXISTA (Serengeti, lotul FRUNZISULUI, sep 2026): masurat cu
tools/probe_slots.gd, toata coroana zonei POI D (206 smochini, 64 acacii-febra,
98 tufe, 19 euforbii — comentariul din probe_slots.gd) sta pe aceeasi pereche
de sloturi de atlas, 12 (CACTUS_GREEN) si 21 (TROPICAL_GREEN). Fara nicio
textura, toata adancimea padurii citeste UN SINGUR SMARALD plat.

DE CE NU `macchia` (respins, masurat): macchia e desenata pentru tufe
mediteraneene cu frunza LATA (mirt, lentisc, caper) in buchete de 20-30 cm,
la scara acelor ei (CLASS_TRIPLANAR_SCALE 1.4 = o repetitie la 71 cm) —
calibrata pentru tufe de 0.6-2.5 m. O coroana de acacia-umbrela are 7-10 m si
frunza COMPUSA PENATA, foliole de sub 1 cm, tinuta intr-un PLATOU orizontal
neted (vezi docs/asset_briefs/img/serengeti_plants.png — lobi rotunzi, umflati,
fara tusa de frunza individuala vizibila la distanta de camera). Frunza lata
in evantai a macchiei, proiectata pe un platou de 8-10 m, ar iesi fie ca o
pata uniforma (daca se pastreaza scara 1.4 — o singura repetitie n-ar incapea
in disc), fie ca petice de frunze URIASE de 1 m (daca se scaleaza in jos ca sa
incapa mai multe repetitii) — pe niciuna din cele doua axe macchia nu descrie
o frunza compusa fina.

DE CE NU `pine_needles` (respins, acelasi motiv ca in prompt): acul de brad e
o tusa LINIARA in spic pe o ramurica; foliola de acacia e un PUNCT, nu o
linie, si sta in evantai pe o umbrela, nu in fisic pe o creanga verticala.
Un ac de 1-2 cm proiectat ca ac tot ar citi conifer, nu savana.

CE E DIFERIT AICI: nu tusa de frunza (nici linie, nici elipsa lata), ci un
NOR de puncte rotunde, minuscule, suprapuse in ciorchini moi — asta e ce
ramane dintr-o frunza compusa pinnata cand fiecare foliola e sub un pixel la
distanta de joc (10-25 m): nu conturul unei frunze, ci DENSITATEA lor, care
citeste ca lob rotunjit umflat cu variatie de valoare in interior, exact
silueta din referinta. Tehnica de clustering (`_clump_mask`, gaussiene
periodice) e imprumutata de la macchia; dab-urile sunt cercuri de 1.5-3.5 px
(la 1024), nu elipse de 6-12 px orientate pe un ax.

Familia de culoare e OLIV, nu verde de brocoli: gradarea trage spre
CACTUS_GREEN (slotul pe care coroana ATERIZEAZA deja, dupa
`SLOT_REMAP_BY_MODEL` din world_prop.gd — acolo 13 si 21 sunt deja mutate pe
12 pentru cele trei acacii-umbrela). Media de luminanta e tinuta aproape de
ancora, ca gradarea sa nu trebuiasca sa ridice sau sa coboare mult (regula
„ratie fata de ancora" din memoria texturilor de clasa).
"""

import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "textures", "classes", "src",
                    "acacia_canopy_src.png")

W = H = 1024
SEED = 17

# Familia de culoare (RGB 0..255). Gradarea trage totul spre CACTUS_GREEN
# (#5B7C34), deci nuantele astea sunt DIRECTIA (umbra din interiorul coroanei,
# foliola la soare), nu valoarea finala. Oliv-prafuit, ca vegetatia de savana
# uscata — nu verdele rece si saturat al unei paduri tropicale.
BG_DARK = (32, 40, 20)
LEAF_DARK = (52, 66, 30)
LEAF_MID = (86, 106, 46)
LEAF_LIGHT = (134, 148, 70)


def _clump_mask(rng):
    """Pete moi de densitate, tileabile: suma de gaussiene periodice.

    Aceeasi mecanica structurala ca macchia/pine_needles, cu raze INTRE cele
    doua (60-130): un lob de coroana e mai mare decat un buchet de macchia,
    dar coroana intreaga e facuta din mai multi asemenea lobi umflati (vezi
    referinta), nu dintr-o singura masa uniforma.
    """
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    acc = np.zeros((H, W), np.float32)
    for _ in range(70):
        cx, cy = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.uniform(60, 130)
        dx = np.abs(xx - cx)
        dx = np.minimum(dx, W - dx)
        dy = np.abs(yy - cy)
        dy = np.minimum(dy, H - dy)
        acc += np.exp(-(dx * dx + dy * dy) / (2 * r * r))
    # scoate gradientul de frecventa foarte joasa, ca la brazi/macchia: fara
    # asta o jumatate de dala iese mai deschisa, si pe un platou care se
    # repeta de 1-2 ori pe coroana asta devine o banda vizibila.
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

    # 1. fondul: umbra dintre foliole, cu zgomot fin (nu culoare plata).
    noise = nrng.normal(0.0, 0.08, (H, W, 1)).astype(np.float32)
    bg = np.array(BG_DARK, np.float32)[None, None, :] * (1.0 + noise)
    img = Image.fromarray(np.clip(bg, 0, 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(img)

    clumps = _clump_mask(rng)

    # 2. foliolele: PUNCTE rotunde mici, nu tuse orientate. O frunza compusa
    # pinnata de acacia are zeci de foliole pe fiecare rahis — la distanta de
    # joc niciuna nu se citeste individual, doar DENSITATEA lor. Trei
    # straturi de la umbra la lumina, ca la macchia/ace, dar fara ax si fara
    # orientare: un dab e un cerc, nu o elipsa pe o directie.
    #
    # Runda 1 (r 1.2-2.6, ~12000 dab-uri) a iesit ca ZGOMOT FIN pe fond
    # aproape negru — masurat, luminanta medie 43.7 (ratie 0.41 fata de
    # ancora, sub oricare din pine_needles/macchia la 0.86) si vizual pe
    # sursa exporta un cer instelat, nu o coroana. Cauza: dab-urile erau prea
    # MICI si prea RARE fata de fondul lor — la o rezolutie de 1024 px o rază
    # de 1.5 px ocupa sub 0.002% din suprafata, deci acoperirea totala a celor
    # trei straturi ramanea sub 15% chiar in zona densa a unui lob.
    # Runda 2: raze duble (2.4-5.0) si de trei ori mai multe dab-uri — tinta e
    # acoperire ~55-70% in centrul unui lob, ca peticele sa se suprapuna si sa
    # formeze o suprafata continua cu variatie, nu puncte izolate pe negru.
    layers = (
        # culoare, nr dab-uri, raza (min,max), cat conteaza masca de lob
        (LEAF_DARK, 15000, (2.6, 5.0), 0.30),
        (LEAF_MID, 13000, (2.4, 4.6), 0.70),
        (LEAF_LIGHT, 9000, (2.2, 4.2), 1.0),
    )
    for color, count, (rmin, rmax), clump_w in layers:
        placed = 0
        attempts = 0
        while placed < count and attempts < count * 4:
            attempts += 1
            x = rng.uniform(0, W)
            y = rng.uniform(0, H)
            keep = (1.0 - clump_w) + clump_w * clumps[int(y) % H, int(x) % W]
            if rng.random() > keep:
                continue
            placed += 1
            r = rng.uniform(rmin, rmax)
            k = 1.0 + rng.uniform(-0.16, 0.16)
            c = list(_mix(color, k))
            if color is LEAF_LIGHT:
                c[2] = int(c[2] * 0.88)   # lumina calda
            elif color is LEAF_DARK:
                c[2] = int(min(255, c[2] * 1.12))  # umbra rece
            # wrap simplu (dab-urile sunt mici, marginea rareori conteaza,
            # dar tratam oricum ca la macchia/ace ca sa ramana tileabila)
            for dx in ((0, W) if x < r else (0,) if x < W - r else (0, -W)):
                for dy in ((0, H) if y < r else (0,) if y < H - r else (0, -H)):
                    draw.ellipse(
                        [x + dx - r, y + dy - r, x + dx + r, y + dy + r],
                        fill=tuple(c))

    # 3. umbra intre lobi: NU gauri discrete (runda 1 le desena ca cercuri
    # negre solide si iesea gaurit, ca un branza cu ochiuri) — o intunecare
    # CONTINUA acolo unde masca de lob e joasa, aplicata pe toata imaginea.
    # Asa marginile dintre lobi se ingusteaza treptat, ca umbra reala dintre
    # doua umbrele de frunzis, nu ca o gaura decupata.
    arr_pre = np.asarray(img).astype(np.float32)
    shadow = 1.0 - 0.55 * np.clip(1.0 - clumps * 1.8, 0.0, 1.0)[:, :, None]
    arr_pre *= shadow
    img = Image.fromarray(np.clip(arr_pre, 0, 255).astype(np.uint8), "RGB")

    # 4. anti-aliasing usor: la 512 (dupa resize in pipeline) dab-urile de
    # 2-5 px ar sclipi altfel — putin mai mult decat la macchia, fiindca
    # dab-urile sunt mai mici si mai numeroase.
    img = img.filter(ImageFilter.GaussianBlur(0.9))

    arr = np.asarray(img).astype(np.float32)
    lum = arr @ np.array([0.299, 0.587, 0.114], np.float32)
    print("luminanta medie %.1f (ancora CACTUS_GREEN ~106), sigma %.1f"
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
