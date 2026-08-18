"""Picteaza SURSA texturii de clasa `ice` (gheata Baikalului).

Rulare (din radacina repo-ului, Python 3 + Pillow + numpy):
    python tools/paint_ice.py
Iesire: assets/textures/classes/src/ice_src.png (1024x1024, tileabila)
Apoi:   godot --headless --path . --script res://tools/process_class_textures.gd
        (gradarea spre REEF_SHALLOW, 512x512, in assets/textures/classes/)

DE CE PICTATA: nu exista o scanare buna de gheata de lac cu bule de metan, iar
referinta (docs/track_briefs/baikal.md §1, dioramele generate) e limpede
despre ce citeste ca „Baikal" de la 10-30 m: un plan turcoaz cu o RETEA de
crapaturi negre si BULE albe inghetate in straturi. Textura sugereaza astea
trei lucruri, fara relief.

Ce contine, si de ce fiecare strat:
  - fond turcoaz cu variatie joasa (pete de 1-2 m): gheata nu e o culoare,
    e apa vazuta prin grosimi diferite; petele dau ochiului ceva de citit
    intre crapaturi.
  - reteaua de crapaturi: muchiile unui Voronoi cu centre jitterate, PE TOR
    (distanta se masoara cu wrap), deci dala se repeta fara cusatura. Doua
    scari: crapaturi mari (celule ~1.5 m) mai late si mai inchise, crapaturi
    fine (celule ~0.4 m) subtiri si palide — o singura scara citeste ca
    faianta.
  - bulele de metan: discuri albe semitransparente in 3 straturi de marime,
    grupate in coloane (in realitate se stivuiesc pe verticala si de sus se
    vad ca ciorchini): pete mici concentrate, nu confetti uniform.
  - un „inghet" alb foarte slab la crapaturi (o dilatare palida in jurul
    liniei): crapatura reala are muchii albe, si fara ele linia neagra pare
    desenata cu markerul.

Grading-ul din process_class_textures trage totul spre REEF_SHALLOW pastrand
luminanta, deci contrastul crapaturi/bule/fond de aici e ce ramane.
"""
from __future__ import annotations

import os
import numpy as np
from PIL import Image, ImageFilter

SIZE = 1024
SEED = 1642
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "textures", "classes", "src", "ice_src.png")


def torus_voronoi_edges(size: int, cells: int, rng: np.random.Generator,
                        jitter: float = 0.9) -> np.ndarray:
    """Distanta pana la cea mai apropiata muchie Voronoi (F2 - F1), pe tor.

    Centrele stau pe o grila `cells` x `cells` cu jitter; pentru fiecare pixel
    ne uitam la cele 3x3 celule vecine, cu wrap, deci rezultatul e tileabil.
    """
    cell = size / cells
    centers = np.zeros((cells, cells, 2), dtype=np.float64)
    for cy in range(cells):
        for cx in range(cells):
            centers[cy, cx] = ((cx + 0.5 + rng.uniform(-jitter, jitter) * 0.5) * cell,
                               (cy + 0.5 + rng.uniform(-jitter, jitter) * 0.5) * cell)
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64)
    f1 = np.full((size, size), np.inf)
    f2 = np.full((size, size), np.inf)
    gx = np.floor(xs / cell).astype(int)
    gy = np.floor(ys / cell).astype(int)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cx = (gx + dx) % cells
            cy = (gy + dy) % cells
            c = centers[cy, cx]
            ddx = xs - c[..., 0]
            ddy = ys - c[..., 1]
            # wrap: cel mai scurt drum pe tor
            ddx = (ddx + size / 2) % size - size / 2
            ddy = (ddy + size / 2) % size - size / 2
            d = np.sqrt(ddx * ddx + ddy * ddy)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            f1 = np.where(closer, d, f1)
    return f2 - f1


def tile_noise(size: int, period: int, rng: np.random.Generator) -> np.ndarray:
    """Zgomot neted tileabil: valori aleatoare pe o grila `period`, upsample
    bilinear cu wrap. 0..1."""
    g = rng.random((period, period))
    big = np.zeros((size, size))
    ys, xs = np.mgrid[0:size, 0:size]
    fx = xs * period / size
    fy = ys * period / size
    x0 = np.floor(fx).astype(int) % period
    y0 = np.floor(fy).astype(int) % period
    x1 = (x0 + 1) % period
    y1 = (y0 + 1) % period
    tx = fx - np.floor(fx)
    ty = fy - np.floor(fy)
    tx = tx * tx * (3 - 2 * tx)
    ty = ty * ty * (3 - 2 * ty)
    big = (g[y0, x0] * (1 - tx) * (1 - ty) + g[y0, x1] * tx * (1 - ty)
           + g[y1, x0] * (1 - tx) * ty + g[y1, x1] * tx * ty)
    return big


def main() -> None:
    rng = np.random.default_rng(SEED)
    # --- fond turcoaz cu pete
    # Pastel, nu piscina: prima varianta (0.42/0.72/0.74 -> 0.66/0.86/0.87)
    # a iesit turcoaz saturat pe tot lacul, ca apa de bazin. Gheata de lac e
    # aproape alba cu o tenta rece; culoarea vine din adancime (vertex color).
    base_lo = np.array([0.66, 0.82, 0.84])
    base_hi = np.array([0.84, 0.92, 0.93])
    n1 = tile_noise(SIZE, 6, rng)
    n2 = tile_noise(SIZE, 17, rng)
    mix = np.clip(0.55 * n1 + 0.45 * n2, 0, 1)[..., None]
    img = base_lo * (1 - mix) + base_hi * mix

    # --- crapaturi: doua scari
    d_big = torus_voronoi_edges(SIZE, 5, rng, jitter=1.0)
    d_fine = torus_voronoi_edges(SIZE, 22, rng)
    # Latimea crapaturilor mari VARIAZA de-a lungul lor (3-7 px, dupa un
    # zgomot lent), iar cele fine apar doar pe petice (~45% din suprafata):
    # cu latime constanta si retea fina peste tot, dala citea ca faianta.
    n_w = tile_noise(SIZE, 9, rng)
    n_f = tile_noise(SIZE, 5, rng)
    width_big = 3.0 + 4.0 * n_w
    crack_big = np.clip(1.0 - d_big / width_big, 0, 1) ** 1.6
    fine_mask = np.clip((n_f - 0.50) / 0.25, 0, 1)
    crack_fine = np.clip(1.0 - d_fine / 1.5, 0, 1) ** 1.4 * fine_mask
    # Crapaturi LUNGI si drepte, prin toata dala (cu wrap): semnatura
    # Baikalului sunt liniile de kilometri, reinghetate, care taie campul de
    # celule. Cateva, la unghiuri diferite, cu latime mica.
    ys_l, xs_l = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
    long_lines = np.zeros((SIZE, SIZE))
    for _ in range(5):
        ang = rng.uniform(0, np.pi)
        nx, ny = -np.sin(ang), np.cos(ang)      # normala la linie
        c0 = rng.uniform(0, SIZE)
        # distanta semnata pana la linie, cu wrap pe directia normalei
        dist = (xs_l * nx + ys_l * ny - c0)
        period = SIZE * max(abs(nx), abs(ny))   # dupa cat se repeta pe tor
        dist = (dist + period / 2) % period - period / 2
        w = rng.uniform(1.6, 3.2)
        long_lines = np.maximum(long_lines, np.clip(1.0 - np.abs(dist) / w, 0, 1) ** 1.3)
    crack_big = np.maximum(crack_big, long_lines)
    # inghetul alb din jurul crapaturilor mari
    frost = np.clip(1.0 - d_big / 22.0, 0, 1) ** 2.2 * 0.22
    img = img + frost[..., None] * (np.array([1.0, 1.0, 1.0]) - img)
    dark = np.array([0.06, 0.13, 0.17])
    img = img * (1 - crack_big[..., None] * 0.92) + dark * crack_big[..., None] * 0.92
    img = img * (1 - crack_fine[..., None] * 0.35) + dark * crack_fine[..., None] * 0.35

    # --- bulele de metan: ciorchini de discuri albe, in 3 marimi
    bub = np.zeros((SIZE, SIZE))
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
    clusters = 60
    for _ in range(clusters):
        cx, cy = rng.uniform(0, SIZE, 2)
        count = int(rng.integers(3, 9))
        for _ in range(count):
            r = float(rng.choice([3.0, 5.0, 8.0], p=[0.5, 0.35, 0.15])) * rng.uniform(0.8, 1.3)
            ox, oy = rng.normal(0, 14.0, 2)
            bx = (cx + ox) % SIZE
            by = (cy + oy) % SIZE
            ddx = (xs - bx + SIZE / 2) % SIZE - SIZE / 2
            ddy = (ys - by + SIZE / 2) % SIZE - SIZE / 2
            dd = np.sqrt(ddx * ddx + ddy * ddy)
            disc = np.clip(1.0 - (dd - r + 1.0) / 1.5, 0, 1)
            # inel: mijlocul putin mai transparent decat marginea
            ring = disc * (0.65 + 0.35 * np.clip(dd / max(r, 1e-3), 0, 1))
            bub = np.maximum(bub, ring * rng.uniform(0.55, 0.9))
    white = np.array([0.95, 0.98, 0.98])
    img = img * (1 - bub[..., None] * 0.85) + white * bub[..., None] * 0.85

    out = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    im = Image.fromarray(out, "RGB").filter(ImageFilter.GaussianBlur(0.4))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    im.save(OUT)
    print("scris", OUT, im.size)


if __name__ == "__main__":
    main()
