"""Genereaza assets/textures/classes/autumn_foliage.png — frunzis de artar, NEUTRU.

Dala e gri pur (R=G=B): culoarea o dau TENTELE claselor (maple_crimson,
maple_orange, ginkgo_gold, leaf_litter din scripts/palette.gd), nu textura.
Fiindca `albedo_color` doar INMULTESTE, dala trebuie sa fie mai deschisa decat
cel mai deschis canal tinta (ginkgo R=242): de aceea media e ~215 si
CLASS_LIFT ridica ce mai lipseste.

Structura (de sus in jos): 3 straturi de frunze de artar lobate (adanc/mijloc/
lumina), cu goluri intunecate (zgomot periodic de frecventa joasa) si
palcuri luminate. Totul se infasoara (tileable): frunzele se deseneaza si cu
decalaje +-512, zgomotul vine din FFT.

Rulare:  python tools/gen_autumn_foliage.py
Seed fix: aceeasi imagine la fiecare rulare.
"""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

N = 512
TARGET_MEAN = 195.2   # media dalei v1, pe care sunt calculate tentele
# Umbra de contact a fiecarei frunze (lumina din stanga-sus a dalei).
SHADOW_STRENGTH = 0.55
SHADOW_GROW = 1.10
SHADOW_OFFSET = (3.0, 4.0)
rng = np.random.default_rng(1117)


def periodic_noise(sigma_px: float, seed: int) -> np.ndarray:
    """Zgomot periodic 0..1, filtrat gaussian in frecventa."""
    r = np.random.default_rng(seed)
    w = r.standard_normal((N, N))
    f = np.fft.fft2(w)
    fy = np.fft.fftfreq(N)[:, None]
    fx = np.fft.fftfreq(N)[None, :]
    g = np.exp(-2 * (math.pi * sigma_px) ** 2 * (fx * fx + fy * fy))
    out = np.real(np.fft.ifft2(f * g))
    out = (out - out.min()) / (out.max() - out.min())
    # intindere pe percentile: 0..1 util
    lo, hi = np.percentile(out, [2, 98])
    return np.clip((out - lo) / (hi - lo), 0, 1)


def leaf_mask(size: int = 128) -> Image.Image:
    """Frunza de artar (5 lobi, dinti fini), varful in sus, supraesantionata."""
    ss = 4
    S = size * ss
    img = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(img)
    cx, cy = S / 2, S * 0.56
    lobes = [(0.0, 0.44, 1.00), (-50.0, 0.40, 0.90), (50.0, 0.40, 0.90),
             (-102.0, 0.34, 0.66), (102.0, 0.34, 0.66)]
    pts = []
    for i in range(720):
        th = math.radians(i * 0.5 - 180.0)  # 0 = in sus, +- pi = in jos
        thd = math.degrees(th)
        r = 0.34
        for (a, w, h) in lobes:
            dd = (thd - a + 540) % 360 - 180
            r = max(r, 0.34 + (h * 0.90 - 0.34) * math.exp(-((math.radians(dd) / w) ** 2)))
        r *= 1.0 + 0.045 * math.sin(math.radians(thd) * 14.0)  # dinti
        # codita: jos, ingusta
        if abs(thd) > 160:
            r = max(r * 0.35, 0.22 if abs(thd) > 172 else r)
        x = cx + math.sin(th) * r * S * 0.5
        y = cy - math.cos(th) * r * S * 0.5
        pts.append((x, y))
    d.polygon(pts, fill=255)
    # codita
    d.line([(cx, cy + S * 0.10), (cx, cy + S * 0.40)], fill=255, width=ss * 2)
    return img.resize((size, size), Image.LANCZOS)


def leaf_shade(mask: Image.Image) -> np.ndarray:
    """Umbrire in frunza: nervuri intunecate, varfurile lobilor mai luminoase."""
    s = mask.size[0]
    yy, xx = np.mgrid[0:s, 0:s].astype(float)
    cx, cy = s / 2, s * 0.56
    dx, dy = (xx - cx) / s, (yy - cy) / s
    rr = np.hypot(dx, dy)
    ang = np.degrees(np.arctan2(dx, -dy))
    shade = 0.86 + 0.20 * np.clip(rr / 0.45, 0, 1)  # centrul mai inchis, varful lumina
    for a in (0, -48, 48, -100, 100):
        dd = np.abs((ang - a + 540) % 360 - 180)
        vein = np.exp(-((dd / 3.2) ** 2)) * np.clip(1 - rr / 0.5, 0, 1)
        shade -= 0.22 * vein
    return np.clip(shade, 0.5, 1.2)


BASE = leaf_mask(128)
SHADE = leaf_shade(BASE)


def stamp(canvas: np.ndarray, x: float, y: float, rot: float, scale: float,
          value: float, contrast: float = 1.0) -> None:
    """Lipeste o frunza cu valoarea `value` (0..255), infasurat."""
    size = max(6, int(128 * scale))
    m = BASE.rotate(rot, resample=Image.BICUBIC, expand=False).resize((size, size), Image.LANCZOS)
    sh = Image.fromarray((np.clip(SHADE, 0, 1.2) / 1.2 * 255).astype(np.uint8)).rotate(
        rot, resample=Image.BICUBIC).resize((size, size), Image.LANCZOS)
    ma = np.asarray(m).astype(float) / 255.0
    sha = (np.asarray(sh).astype(float) / 255.0) * 1.2
    sha = 1.0 + (sha - 1.0) * contrast
    val = np.clip(value * sha, 0, 255)
    for ox in (-N, 0, N):
        for oy in (-N, 0, N):
            x0, y0 = int(x - size / 2) + ox, int(y - size / 2) + oy
            if x0 >= N or y0 >= N or x0 + size <= 0 or y0 + size <= 0:
                continue
            sx0, sy0 = max(0, -x0), max(0, -y0)
            sx1, sy1 = min(size, N - x0), min(size, N - y0)
            dst = canvas[y0 + sy0:y0 + sy1, x0 + sx0:x0 + sx1]
            a = ma[sy0:sy1, sx0:sx1]
            dst[:] = dst * (1 - a) + val[sy0:sy1, sx0:sx1] * a


def shadow(canvas: np.ndarray, x: float, y: float, rot: float, scale: float,
           strength: float, dx: float, dy: float) -> None:
    """Umbra de contact a unei frunze pe straturile de dedesubt (multiplicativa)."""
    size = max(6, int(128 * scale))
    m = BASE.rotate(rot, resample=Image.BICUBIC).resize((size, size), Image.LANCZOS)
    ma = np.asarray(m).astype(float) / 255.0 * strength
    for ox in (-N, 0, N):
        for oy in (-N, 0, N):
            x0, y0 = int(x - size / 2 + dx) + ox, int(y - size / 2 + dy) + oy
            if x0 >= N or y0 >= N or x0 + size <= 0 or y0 + size <= 0:
                continue
            sx0, sy0 = max(0, -x0), max(0, -y0)
            sx1, sy1 = min(size, N - x0), min(size, N - y0)
            dst = canvas[y0 + sy0:y0 + sy1, x0 + sx0:x0 + sx1]
            dst[:] = dst * (1 - ma[sy0:sy1, sx0:sx1])


def main() -> None:
    gap_n = periodic_noise(20, 11)      # goluri (zone fara frunze)
    clump_n = periodic_noise(22, 12)    # palcuri luminate
    fine_n = periodic_noise(7, 13)      # variatie fina
    canvas = np.full((N, N), 22.0)      # fundul golurilor: umbra adanca

    layers = [
        # (numar, scara min/max, valoare baza, castig palcuri, prag goluri)
        (700, (0.32, 0.46), 150.0, 0.34, 0.09),
        (800, (0.28, 0.40), 200.0, 0.40, 0.13),
        (900, (0.24, 0.34), 246.0, 0.36, 0.20),
    ]
    for (count, (s0, s1), base, gain, thr) in layers:
        for _ in range(count):
            x, y = rng.uniform(0, N, 2)
            if gap_n[int(y), int(x)] < thr:
                continue  # gol
            c = clump_n[int(y), int(x)]
            fn = fine_n[int(y), int(x)]
            v = base * (1.00 + gain * (c - 0.5) * 0.9 + 0.12 * (fn - 0.5)) * rng.uniform(0.80, 1.06)
            rot, sc = rng.uniform(0, 360), rng.uniform(s0, s1)
            # umbra de contact pe frunzele de dedesubt: fara ea, trei straturi
            # aproape la fel de deschise se topesc intr-o pata si conturul
            # lobat nu se mai citeste din camera (decupajul de joc, oct 2026)
            shadow(canvas, x, y, rot, sc * SHADOW_GROW, SHADOW_STRENGTH,
                   SHADOW_OFFSET[0], SHADOW_OFFSET[1])
            stamp(canvas, x, y, rot, sc, min(v, 252.0), 1.0)

    # tonul final: usor desfocat sub-pixel, apoi normalizare a mediei
    img = Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.5))
    a = np.asarray(img).astype(float)
    # curba de ton: ridica mediul fara sa taie luminile (tenta doar inmulteste,
    # deci dala trebuie sa fie deschisa cat mai uniform, cu golurile ca singur intuneric)
    # Gamma rezolvata pe MEDIE: umbrele de contact coboara media, iar tentele
    # claselor (CLASS_TINT, CLASS_LIFT) sunt calculate pe media dalei. Curba o
    # readuce la TARGET_MEAN fara sa atinge tentele; contrastul frunza/umbra
    # ramane (umbrele sunt sub p10, luminile se strang spre alb).
    lo_g, hi_g = 0.2, 1.0
    for _ in range(40):
        g = 0.5 * (lo_g + hi_g)
        if (255.0 * (a / 255.0) ** g).mean() > TARGET_MEAN:
            lo_g = g
        else:
            hi_g = g
    a = 255.0 * (a / 255.0) ** g
    print("gamma %.3f" % g)
    print("medie %.1f  std %.1f  p1 %.0f p50 %.0f p99 %.0f  max %.0f" % (
        a.mean(), a.std(), *np.percentile(a, [1, 50, 99]), a.max()))
    rgb = np.stack([a, a, a], axis=-1).astype(np.uint8)
    Image.fromarray(rgb, "RGB").save("assets/textures/classes/autumn_foliage.png")


if __name__ == "__main__":
    main()
