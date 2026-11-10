"""Dala clasei `sf_clapboard` (San Francisco, brief §4): scandura orizontala suprapusa.

    python tools/gen_sf_clapboard.py

Scrie assets/textures/classes/sf_clapboard.png (512x512, NEUTRA, deschisa). Culoarea
nu vine din dala: cele cinci pasteluri sunt cinci tente (`Palette.CLASS_TINT`) pe
ACEEASI imagine, deci dala e alb-cald aproape neutru, iar tenta doar intuneca
(memoria `surfacetool-clamp-vertex-color`: tenta nu poate lumina).

Ce poarta dala: MUCHII DE FORMA, nu granulatie (memoria `muchii-de-forma-nu-granulatie`).
Fiecare scandura are o dunga de umbra sub buza scandurii de deasupra (suprapunerea,
"lap") si o fata care se deschide spre muchia de jos; plus rosturi verticale rare
(capete de scandura) si un fir de lemn foarte slab. La scara clasei (CLASS_TRIPLANAR_SCALE
0.25 => 4 m pe dala, 16 scanduri) o scandura are 25 cm: la 20 m de camera inca ~5 px.

Determinist (samanta fixa): rularea de doua ori da acelasi PNG.
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image

SIZE = 512
BOARDS = 16
SEED = 1873  # anul primului tramvai cu cablu
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "classes",
                   "sf_clapboard.png")

# Valori in sRGB 0..1. Fata scandurii e alb-cald aproape neutru (tentele fac culoarea).
FACE_TOP = 0.92      # imediat sub umbra buzei
FACE_BOTTOM = 0.99   # muchia de jos a scandurii, cea care prinde lumina
SHADOW = 0.55        # dunga de umbra de sub buza scandurii de deasupra
SHADOW_FRAC = 0.13   # cat din inaltimea scandurii e umbra
SOFT_FRAC = 0.06     # tranzitia umbra -> fata
WARM = np.array([1.0, 0.99, 0.97])  # alb-cald foarte slab, ca tentele sa nu vireze


def main() -> None:
    rng = np.random.default_rng(SEED)
    h = SIZE // BOARDS
    v = np.zeros((SIZE, SIZE), dtype=np.float64)
    ys = np.arange(SIZE)
    t = (ys % h) / float(h)  # 0 = sus (sub buza), 1 = jos (muchia scandurii)
    prof = FACE_TOP + (FACE_BOTTOM - FACE_TOP) * t
    sh = np.clip((t - SHADOW_FRAC) / SOFT_FRAC, 0.0, 1.0)
    prof = SHADOW + (prof - SHADOW) * sh
    # ultimul rand de pixeli al scandurii: muchia din fata, cea mai deschisa
    prof[(ys % h) == h - 1] = 1.0
    v[:, :] = prof[:, None]

    # Capete de scandura (rosturi verticale): unul-doua pe rand, decalate.
    for b in range(BOARDS):
        y0 = b * h
        n = int(rng.integers(1, 3))
        for _ in range(n):
            x = int(rng.integers(0, SIZE))
            y1 = y0 + int(SHADOW_FRAC * h)
            v[y1:y0 + h, x % SIZE] *= 0.72
            v[y1:y0 + h, (x + 1) % SIZE] *= 0.90

    # Variatie mica per scandura (vopsea care a imbatranit inegal).
    for b in range(BOARDS):
        v[b * h:(b + 1) * h, :] *= 1.0 - 0.03 * rng.random()

    # Fir de lemn foarte slab, orizontal (zgomot intins pe X): granulatie, nu forma.
    grain = rng.normal(0.0, 1.0, (SIZE, SIZE // 32))
    grain = np.repeat(grain, 32, axis=1)
    k = np.ones(7) / 7.0
    grain = np.apply_along_axis(lambda r: np.convolve(np.r_[r, r[:6]], k, "valid"), 1, grain)
    v *= 1.0 + 0.015 * grain

    rgb = np.clip(v[:, :, None] * WARM[None, None, :], 0.0, 1.0)
    img = Image.fromarray((rgb * 255.0 + 0.5).astype(np.uint8), "RGB")
    img.save(OUT)
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    print("scris %s  media sRGB %s  media liniara %s" % (
        os.path.normpath(OUT), rgb.reshape(-1, 3).mean(0).round(4),
        lin.reshape(-1, 3).mean(0).round(4)))


if __name__ == "__main__":
    main()
