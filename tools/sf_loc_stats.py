#!/usr/bin/env python3
"""Statisticile testului de loc San Francisco (brief §7 pasul 0), din iesirea sondei
`tools/ProbeSfLoc.tscn` (rulata CU fereastra si `--frames`):

    python tools/sf_loc_stats.py

Citeste snapshots/sf_loc_meas.json si perechile snapshots/sf_loc_meas_<k>_{cadru,id}.png.
In cadrul de identitate fetele de scandura au R = 30 + 45*pastel, G = 250 (cu fata spre
soare) / 0 (cu spatele), B = 128; restul e negru. Scoate:

  1. dV soare/umbra pe fatade: V (HSV, max(r,g,b)) median pe pixelii fetelor cu fata spre
     soare minus cel al fetelor cu spatele, pe toate cadrele (si per pastel). Tinta >= 0,28.
     Pixelii "spre soare" aflati in umbra aruncata raman in grupa lor (asa ii vede jocul).
  2. distanta dintre pasteluri DUPA remap (memoria `monocromia-se-masoara-dupa-remap`):
     (a) pe ALBEDO, adica dala reala x tenta clasei (ce pune jocul pe material);
     (b) pe CADRU, media Lab a pixelilor fetelor spre soare ale fiecarui pastel.
     dE2000 minim intre perechi; tinta >= 10 (perechea cea mai apropiata se distinge
     ca alta culoare, nu ca alta lumina pe aceeasi culoare).
  3. soarele pe carosabil si materialele, copiate din json.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SNAP = os.path.join(ROOT, "snapshots")
TEX = os.path.join(ROOT, "assets", "textures", "classes", "sf_clapboard.png")


def lin(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def srgb(l):
    l = np.clip(np.asarray(l, dtype=np.float64), 0.0, 1.0)
    return np.where(l <= 0.0031308, l * 12.92, 1.055 * l ** (1 / 2.4) - 0.055)


def lab(rgb):
    """sRGB 0..1 -> CIELAB (D65)."""
    l = lin(rgb)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = l @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > (6 / 29) ** 3, np.cbrt(xyz), xyz / (3 * (6 / 29) ** 2) + 4 / 29)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]),
                     200 * (f[..., 1] - f[..., 2])], -1)


def de2000(a, b):
    L1, a1, b1 = a
    L2, a2, b2 = b
    C1 = math.hypot(a1, b1)
    C2 = math.hypot(a2, b2)
    Cm = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(Cm ** 7 / (Cm ** 7 + 25 ** 7)))
    a1p, a2p = a1 * (1 + G), a2 * (1 + G)
    C1p, C2p = math.hypot(a1p, b1), math.hypot(a2p, b2)
    h1p = math.degrees(math.atan2(b1, a1p)) % 360
    h2p = math.degrees(math.atan2(b2, a2p)) % 360
    dLp = L2 - L1
    dCp = C2p - C1p
    dh = h2p - h1p
    if C1p * C2p == 0:
        dh = 0
    elif dh > 180:
        dh -= 360
    elif dh < -180:
        dh += 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dh / 2))
    Lpm = (L1 + L2) / 2
    Cpm = (C1p + C2p) / 2
    if C1p * C2p == 0:
        hpm = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hpm = (h1p + h2p) / 2
    elif h1p + h2p < 360:
        hpm = (h1p + h2p + 360) / 2
    else:
        hpm = (h1p + h2p - 360) / 2
    T = (1 - 0.17 * math.cos(math.radians(hpm - 30)) + 0.24 * math.cos(math.radians(2 * hpm))
         + 0.32 * math.cos(math.radians(3 * hpm + 6)) - 0.20 * math.cos(math.radians(4 * hpm - 63)))
    dth = 30 * math.exp(-(((hpm - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cpm ** 7 / (Cpm ** 7 + 25 ** 7))
    Sl = 1 + 0.015 * (Lpm - 50) ** 2 / math.sqrt(20 + (Lpm - 50) ** 2)
    Sc = 1 + 0.045 * Cpm
    Sh = 1 + 0.015 * Cpm * T
    Rt = -math.sin(math.radians(2 * dth)) * Rc
    return math.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2
                     + Rt * (dCp / Sc) * (dHp / Sh))


def pair_table(names, labs, title):
    print("  %s" % title)
    worst = (1e9, "")
    for i in range(len(names)):
        row = []
        for j in range(len(names)):
            if j <= i:
                row.append("      ")
                continue
            d = de2000(labs[i], labs[j])
            row.append("%6.1f" % d)
            if d < worst[0]:
                worst = (d, "%s-%s" % (names[i], names[j]))
        print("    %-9s %s" % (names[i], " ".join(row)))
    print("    %-9s %s" % ("", " ".join("%6s" % n[:6] for n in names)))
    print("    dE2000 minim: %.1f (%s)" % worst)
    return worst


def main():
    meas = json.load(open(os.path.join(SNAP, "sf_loc_meas.json"), encoding="utf-8"))
    names = meas["pastel_names"]
    tints = meas["tints"]
    classes = meas.get("pastel_classes", list(tints.keys()))
    out = {}
    print("=== Test de loc San Francisco: masuratori ===")
    print("soare: rotatie %s, spre soare %s" % (
        [round(v, 1) for v in meas["sun_rotation_deg"]], [round(v, 3) for v in meas["to_sun"]]))
    print("\n1. Soare pe carosabil (tinta >= 80% pe LANT)")
    for k, v in meas["sun_on_road"].items():
        print("    %-28s %5.1f%%   (umbra de case %.1f%%)" % (k, v["lit"] * 100, v["shadow_by_houses"] * 100))
    chain = meas["sun_on_road"]["LANT (z 24..-96)"]["lit"]
    out["sun_chain"] = chain

    # ---- 2a. albedo dupa remap: dala reala x tenta (liniar)
    tex = np.asarray(Image.open(TEX).convert("RGB")) / 255.0
    face = lin(tex)[tex.mean(2) > 0.8].mean(0)
    allm = lin(tex).reshape(-1, 3).mean(0)
    alb_face = []
    print("\n2a. Pastelurile DUPA remap, pe albedo (dala x tenta; fata de scandura / media cu rosturi)")
    for n, cls in zip(names, classes):
        t = lin(np.array(tints[cls]))
        f = srgb(face * t)
        a = srgb(allm * t)
        alb_face.append(lab(f))
        hx = "#%02X%02X%02X" % tuple(int(round(x * 255)) for x in f)
        print("    %-9s %-22s fata %s  media %s" % (n, cls, hx, (a * 255).round().astype(int)))
    w_alb = pair_table(names, alb_face, "dE2000 pe albedo:")
    out["de_albedo_min"] = w_alb[0]

    # ---- 1 + 2b. cadrele
    k = 0
    lit_v, shade_v = [], []
    per = {i: {"lit": [], "shade": [], "rgb": []} for i in range(len(names))}
    while True:
        fc = os.path.join(SNAP, "sf_loc_meas_%d_cadru.png" % k)
        fi = os.path.join(SNAP, "sf_loc_meas_%d_id.png" % k)
        if not (os.path.exists(fc) and os.path.exists(fi)):
            break
        img = np.asarray(Image.open(fc).convert("RGB")).astype(np.float64) / 255.0
        idm = np.asarray(Image.open(fi).convert("RGB")).astype(np.int32)
        clap = (np.abs(idm[..., 2] - 128) < 14)
        pidx = np.clip(np.round((idm[..., 0] - 30) / 45.0), 0, len(names) - 1).astype(int)
        islit = idm[..., 1] > 125
        v = img.max(2)
        for i in range(len(names)):
            m_l = clap & islit & (pidx == i)
            m_s = clap & (~islit) & (pidx == i)
            per[i]["lit"].append(v[m_l])
            per[i]["shade"].append(v[m_s])
            per[i]["rgb"].append(img[m_l])
        lit_v.append(v[clap & islit])
        shade_v.append(v[clap & ~islit])
        print("    cadrul %d: %d px fatada spre soare, %d px cu spatele" % (
            k, int((clap & islit).sum()), int((clap & ~islit).sum())))
        k += 1
    if k == 0:
        print("\n(fara cadre: ruleaza sonda CU fereastra si --frames)")
        return
    lv = np.concatenate(lit_v)
    sv = np.concatenate(shade_v)
    dv = float(np.median(lv) - np.median(sv))
    print("\n1b. dV soare/umbra pe fatade (tinta >= 0,28), %d cadre" % k)
    print("    toate: V spre soare %.3f (p25 %.3f), cu spatele %.3f (p75 %.3f)  -> dV %.3f"
          % (np.median(lv), np.percentile(lv, 25), np.median(sv), np.percentile(sv, 75), dv))
    out["dV"] = dv
    labs = []
    for i, n in enumerate(names):
        l = np.concatenate(per[i]["lit"])
        s = np.concatenate(per[i]["shade"])
        rgb = np.concatenate(per[i]["rgb"])
        mrgb = np.median(rgb, 0) if len(rgb) else np.zeros(3)
        labs.append(lab(mrgb))
        print("    %-9s V %.3f / %.3f -> dV %.3f   (%d / %d px)  lumina #%02X%02X%02X" % (
            n, np.median(l) if len(l) else 0, np.median(s) if len(s) else 0,
            (np.median(l) - np.median(s)) if len(l) and len(s) else 0, len(l), len(s),
            *[int(round(x * 255)) for x in mrgb]))
    print("\n2b. Pastelurile pe CADRU (mediana fetelor spre soare, dupa lumina)")
    w_fr = pair_table(names, labs, "dE2000 pe cadru:")
    out["de_frame_min"] = w_fr[0]
    print("\n3. Materiale unice in scena: %d" % meas["materials"])
    print("\nREZUMAT")
    print("    soare pe lant            %5.1f%%   tinta >= 80%%   %s" % (chain * 100, "PASS" if chain >= 0.8 else "FAIL"))
    print("    dV soare/umbra fatade    %5.3f    tinta >= 0,28  %s" % (dv, "PASS" if dv >= 0.28 else "FAIL"))
    print("    dE2000 min albedo        %5.1f    tinta >= 10    %s" % (w_alb[0], "PASS" if w_alb[0] >= 10 else "FAIL"))
    print("    dE2000 min cadru         %5.1f    tinta >= 10    %s" % (w_fr[0], "PASS" if w_fr[0] >= 10 else "FAIL"))
    print("    materiale                %5d    plafon 38      %s" % (meas["materials"], "PASS" if meas["materials"] <= 38 else "FAIL"))


if __name__ == "__main__":
    sys.exit(main())
