"""Picteaza SURSA texturii de clasa `fresco` (frescele bisericii rupestre din
orasul subteran al Cappadociei, POI F / Sala 2).

Rulare (din radacina repo-ului, Python 3 + Pillow + numpy):
    python tools/paint_fresco.py
Iesire: assets/textures/classes/src/fresco_src.png (1024x1024, tileabila)
Apoi:   godot --headless --path . --script res://tools/process_class_textures.gd
        (gradarea spre TILE_TERRACOTTA, 512x512, in assets/textures/classes/)

DE CE PICTATA si nu o fotografie: o fresca reala e figurativa. Brieful
(§2 POI F, §5.2) cere explicit "fresce ABSTRACTE", si prompt-ul de kit din §7
scrie negru pe alb "no readable words, frescoes are abstract shapes". O
fotografie de frescă bizantina pusa pe o piesa de 6 m latime, vazuta din masina
la 60 km/h, ar da fete umane deformate — grotesc la scara de jucarie, si in
plus e trade dress dintr-un loc real. Motivele geometrice bizantine (benzi,
medalioane, arcaturi oarbe, cruci in cerc) citesc "aici e ceva pictat, e altfel
decat piatra" din prima si nu cer nicio figura.

Ce contine, si de ce fiecare strat (motivele sunt cele din
`docs/track_briefs/img/v3_crops/F_underground.png`, unde peretele salii de jos
are panouri ocru cu forme rosii verticale si contur inchis):

  - fond de VAR pictat, neuniform: tencuiala peste care s-a pictat nu e o
    culoare, e o suprafata cu pete si cu zone unde varul s-a dus. Fara stratul
    asta orice motiv desenat deasupra arata ca un abtibild lipit pe piatra
    (memoria `patru-defecte-de-diorama`, defectul "deschideri-abtibild").
  - GRILA de panouri: frescele bizantine sunt registre inramate, nu un tapet
    continuu. Doua benzi orizontale de chenar impart dala in registre, si in
    fiecare registru stau motivele. Grila e pe TOR (modulo), deci dala se
    repeta fara cusatura.
  - medalioane (cercuri concentrice) si cruci inscrise: cele doua forme care
    citesc "bizantin" fara sa fie figuri. Culorile sunt cele trei ale paletei
    pe care le purta deja piesa in kit — TILE_TERRACOTTA (rosu de corp),
    LARCH_RUST (ocru ruginiu) si VOLCANIC_BLACK (conturul inchis) — ca textura
    sa aterizeze pe familia de culoare pe care arcada o avea deja.
  - arcaturi oarbe: siruri de arce mici pictate, motivul de sub cornisa din
    orice biserica rupestra. Ele dau RITM pe orizontala, adica exact ce
    lipseste unei benzi de culoare plata vazuta din mers.
  - COJIRE: pete in care pictura lipseste si se vede varul de dedesubt.
    Cappadocia are fresce de 1000 de ani; fara cojire, panoul arata proaspat
    vopsit. Petele sunt tot pe tor.

CALIBRARE (memoria `texturi-de-clasa-alegerea-sursei`): media si deviatia se
masoara fata de familia de clase existente, nu din ochi. Masurat pe dalele de
azi: alpine_granite 156.8/41.1, stone_wall 148.6/25.7, rock 103.7/26.7. Tinta
de aici e in mijlocul familiei ca medie si in capul de sus ca deviatie —
o fresca ARE mai mult contrast decat piatra, aia e chiar diferenta pe care o
aduce in cadru. Gradarea din process_class_textures pastreaza luminanta, deci
contrastul de aici e ce ramane pe ecran.
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageFilter

SIZE = 1024
SEED = 3117
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "textures", "classes", "src", "fresco_src.png")

# Culorile de pornire, luate din sloturile pe care piesa le purta deja in kit
# (build_cappadocia_underground.py: FRESCO_RED / FRESCO_RUST / FRESCO_DARK) plus
# varul de fond. Gradarea le va trage oricum spre ancora, dar raportul dintre
# ele — care e tot ce se vede la 10 m — se decide aici.
LIME = np.array([0.86, 0.80, 0.68])      # varul de fond, cald
LIME_DARK = np.array([0.70, 0.63, 0.51])  # var patat / umbrit
RED = np.array([0.77, 0.47, 0.31])       # TILE_TERRACOTTA #C4784F
RUST = np.array([0.66, 0.41, 0.23])      # LARCH_RUST #A8683A
DARK = np.array([0.33, 0.32, 0.35])      # VOLCANIC_BLACK #55535A


def _wrap_delta(xs: np.ndarray, x0: float) -> np.ndarray:
    """Distanta pe tor de la fiecare coordonata la `x0`."""
    return (xs - x0 + SIZE / 2) % SIZE - SIZE / 2


def _fbm(rng: np.random.Generator, size: int, octaves: int = 5) -> np.ndarray:
    """Zgomot fractal tileabil: se construieste din grile mici marite ciclic."""
    out = np.zeros((size, size), dtype=np.float64)
    amp = 1.0
    tot = 0.0
    for o in range(octaves):
        cells = 2 ** (o + 2)
        g = rng.random((cells, cells))
        # marire ciclica: se repeta prima linie/coloana la coada
        g = np.vstack([g, g[:1]])
        g = np.hstack([g, g[:, :1]])
        im = Image.fromarray((g * 255).astype(np.uint8)).resize(
            (size + 1, size + 1), Image.BICUBIC)
        out += amp * (np.asarray(im, dtype=np.float64)[:size, :size] / 255.0)
        tot += amp
        amp *= 0.5
    out /= tot
    return (out - out.min()) / max(out.max() - out.min(), 1e-6)


def _disc(xs: np.ndarray, ys: np.ndarray, cx: float, cy: float,
          r: float, soft: float = 1.5) -> np.ndarray:
    dx = _wrap_delta(xs, cx)
    dy = _wrap_delta(ys, cy)
    d = np.sqrt(dx * dx + dy * dy)
    return np.clip((r - d) / soft + 0.5, 0.0, 1.0)


def _ring(xs: np.ndarray, ys: np.ndarray, cx: float, cy: float,
          r: float, w: float) -> np.ndarray:
    dx = _wrap_delta(xs, cx)
    dy = _wrap_delta(ys, cy)
    d = np.sqrt(dx * dx + dy * dy)
    return np.clip((w * 0.5 - np.abs(d - r)) / 1.2 + 0.5, 0.0, 1.0)


def _band_y(ys: np.ndarray, y0: float, h: float) -> np.ndarray:
    dy = np.abs(_wrap_delta(ys, y0))
    return np.clip((h * 0.5 - dy) / 1.2 + 0.5, 0.0, 1.0)


def _band_x(xs: np.ndarray, x0: float, w: float) -> np.ndarray:
    dx = np.abs(_wrap_delta(xs, x0))
    return np.clip((w * 0.5 - dx) / 1.2 + 0.5, 0.0, 1.0)


def _over(img: np.ndarray, mask: np.ndarray, color: np.ndarray,
          alpha: float = 1.0) -> np.ndarray:
    m = (mask * alpha)[..., None]
    return img * (1.0 - m) + color * m


def main() -> None:
    rng = np.random.default_rng(SEED)
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)

    # --- 1. fondul de var, patat -------------------------------------------
    stain = _fbm(rng, SIZE, octaves=5)
    img = LIME * (1.0 - stain[..., None] * 0.45) + LIME_DARK * (stain[..., None] * 0.45)
    # granulatie fina de tencuiala
    grain = rng.normal(0.0, 0.022, (SIZE, SIZE))
    img = np.clip(img + grain[..., None], 0.0, 1.0)

    # --- 2. registrele: doua benzi orizontale de chenar ---------------------
    # Dala tine DOUA registre pe inaltime; la scara aleasa (vezi
    # CLASS_TRIPLANAR_SCALE) un registru masoara ~1.6 m, adica inaltimea unui
    # panou pictat real.
    for y0 in (0.0, SIZE * 0.5):
        img = _over(img, _band_y(ys, y0, 22.0), RUST, 0.85)
        img = _over(img, _band_y(ys, y0, 8.0), DARK, 0.75)
        # dintii de fierastrau ai chenarului: ritm marunt, foarte bizantin
        step = SIZE / 32.0
        for k in range(32):
            cx = (k + 0.5) * step
            img = _over(img, _disc(xs, ys, cx, y0 + 15.0, 4.0), RED, 0.8)

    # --- 3. arcaturi oarbe sub chenarul de sus -----------------------------
    # Un sir de arce mici pictate: semicercuri + montanti.
    for y0 in (0.0, SIZE * 0.5):
        base = y0 + 118.0
        n = 8
        step = SIZE / n
        for k in range(n):
            cx = (k + 0.5) * step
            arc = _ring(xs, ys, cx, base, step * 0.34, 6.0)
            # doar jumatatea de SUS a inelului e arc
            arc = arc * (_wrap_delta(ys, base) < 0.0)
            img = _over(img, arc, RUST, 0.75)
            img = _over(img, _band_x(xs, cx - step * 0.34, 6.0)
                        * _band_y(ys, base + 22.0, 44.0), RUST, 0.7)
            img = _over(img, _band_x(xs, cx + step * 0.34, 6.0)
                        * _band_y(ys, base + 22.0, 44.0), RUST, 0.7)

    # --- 4. medalioane si cruci inscrise, in mijlocul fiecarui registru ----
    for reg, y0 in enumerate((SIZE * 0.29, SIZE * 0.79)):
        n = 4
        step = SIZE / n
        for k in range(n):
            if rng.random() < 0.15:
                continue  # medalion pierdut: peretele nu e un tapet complet
            cx = ((k + 0.5) * step + (step * 0.5 if reg else 0.0)
                  + rng.uniform(-step * 0.06, step * 0.06))
            r = step * 0.30 * rng.uniform(0.80, 1.12)
            # discul de fond, ocru
            img = _over(img, _disc(xs, ys, cx, y0, r), RED, 0.55)
            # doua inele concentrice
            img = _over(img, _ring(xs, ys, cx, y0, r, 7.0), DARK, 0.8)
            img = _over(img, _ring(xs, ys, cx, y0, r * 0.72, 5.0), RUST, 0.85)
            if (k + reg) % 2 == 0:
                # cruce inscrisa: brate egale, capete usor latite
                arm = r * 0.52
                img = _over(img, _band_x(xs, cx, 13.0) * _band_y(ys, y0, arm * 2.0),
                            DARK, 0.85)
                img = _over(img, _band_y(ys, y0, 13.0) * _band_x(xs, cx, arm * 2.0),
                            DARK, 0.85)
            else:
                # rozeta: sase petale, tot abstracta
                for p in range(6):
                    a = math.tau * p / 6.0
                    px = cx + math.cos(a) * r * 0.42
                    py = y0 + math.sin(a) * r * 0.42
                    img = _over(img, _disc(xs, ys, px, py, r * 0.20), RUST, 0.8)
                img = _over(img, _disc(xs, ys, cx, y0, r * 0.16), DARK, 0.85)

    # --- 5. panouri verticale intre medalioane -----------------------------
    # Formele verticale rosii din referinta: dreptunghiuri inalte cu capat
    # rotunjit, adica silueta unei firide pictate. Abstract, fara figura.
    for reg, y0 in enumerate((SIZE * 0.29, SIZE * 0.79)):
        n = 4
        step = SIZE / n
        for k in range(n):
            cx = (k + 0.5) * step + (step * 0.5 if reg else 0.0) + step * 0.5
            w = step * 0.16 * rng.uniform(0.85, 1.15)
            h = step * 0.46
            body = _band_x(xs, cx, w) * _band_y(ys, y0 + h * 0.18, h)
            cap = _disc(xs, ys, cx, y0 + h * 0.18 - h * 0.5, w * 0.5)
            shape = np.clip(body + cap, 0.0, 1.0)
            col = RED if (k % 2 == 0) else RUST
            img = _over(img, shape, col, 0.7)
            # conturul inchis: forma minus forma erodata
            inner = _band_x(xs, cx, w - 8.0) * _band_y(ys, y0 + h * 0.18, h - 8.0)
            inner = np.clip(inner + _disc(xs, ys, cx, y0 + h * 0.18 - h * 0.5,
                                          w * 0.5 - 4.0), 0.0, 1.0)
            img = _over(img, np.clip(shape - inner, 0.0, 1.0), DARK, 0.75)

    # --- 6. cojirea: pictura lipseste pe alocuri, se vede varul ------------
    #
    # Cojirea e VAR EXPUS, deci mai DESCHISA si mai calda decat pictura. Prima
    # versiune folosea un fbm cu prag larg si iesea o pata gri difuza care citea
    # a FUM, nu a tencuiala cazuta — pe dala de 2x2 aratau ca niste umbre care
    # se plimba peste motive. Pragul e acum mai strans (pete mai mici, cu
    # margine) si culoarea e varul curat, nu varul umbrit.
    peel = _fbm(rng, SIZE, octaves=5)
    peel = np.clip((peel - 0.70) / 0.09, 0.0, 1.0)
    lime_bg = LIME * (1.0 + 0.06) - stain[..., None] * 0.10
    img = img * (1.0 - peel[..., None]) + np.clip(lime_bg, 0, 1) * peel[..., None]
    # muchia cojirii: o linie subtire mai inchisa, marginea tencuielii desprinse
    edge = np.clip(1.0 - np.abs(peel - 0.5) * 6.0, 0.0, 1.0) * (peel > 0.05)
    img = _over(img, edge, LIME_DARK, 0.45)
    # --- 7. funinginea tortelor, pe VERTICALA -----------------------------
    # Intr-o sala cu torte pe pereti, urma de fum urca in pana deasupra
    # fiecarei flacari. E singurul strat care are voie sa fie inchis si difuz,
    # si exista ca sa rupa regularitatea de tapet a registrelor.
    soot = _fbm(rng, SIZE, octaves=3)
    for _ in range(5):
        cx = rng.uniform(0, SIZE)
        cy = rng.uniform(0, SIZE)
        dx = _wrap_delta(xs, cx)
        dy = _wrap_delta(ys, cy)
        plume = np.clip(1.0 - np.abs(dx) / rng.uniform(26.0, 46.0), 0, 1)
        plume *= np.clip(1.0 - np.abs(dy + 60.0) / 120.0, 0, 1)
        img = _over(img, plume * soot * 0.55, DARK, 0.30)

    out = np.clip(img, 0.0, 1.0)
    lum = 0.2126 * out[..., 0] + 0.7152 * out[..., 1] + 0.0722 * out[..., 2]
    print("inainte de normalizare: media %.1f sigma %.2f"
          % (lum.mean() * 255.0, lum.std() * 255.0))

    im = Image.fromarray((out * 255).astype(np.uint8), "RGB")
    im = im.filter(ImageFilter.GaussianBlur(0.5))
    a = np.asarray(im, dtype=np.float64)
    lum = 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
    print("scris %s %s  media %.1f sigma %.2f"
          % (OUT, im.size, lum.mean(), lum.std()))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    im.save(OUT)


if __name__ == "__main__":
    main()
