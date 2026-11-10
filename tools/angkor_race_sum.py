"""Rezumatul A/B ProbeRace Angkor: python -I tools/angkor_race_sum.py <dir_A> <dir_B> [<nume_A> <nume_B>]"""
import glob
import os
import re
import statistics as st
import sys


def parse(path):
    t = open(path, encoding="utf-8", errors="replace").read()
    d = {}
    m = re.search(r"TUR global: (\d+) ture, minim ([\d.]+) s, mediu ([\d.]+) s", t)
    if m:
        d["ture"], d["tur_min"], d["tur_med"] = int(m[1]), float(m[2]), float(m[3])
    m = re.search(r"repuneri totale: (\d+)", t)
    d["repuneri"] = int(m[1]) if m else None
    m = re.search(r"ejectari: (\d+) \(perete (\d+), aterizare (\d+)\)", t)
    d["ejectari"] = int(m[1]) if m else None
    d["blocaje"] = len(re.findall(r"^\[blocaj\]", t, re.M))
    d["blocaje_E"] = len([x for x in re.findall(r"^\[blocaj\].*?frac=([\d.]+)", t, re.M)
                          if 0.40 <= float(x) <= 0.50])
    d["blocaje_A"] = len([x for x in re.findall(r"^\[blocaj\].*?frac=([\d.]+)", t, re.M)
                          if float(x) <= 0.08])
    m = re.search(r"galerie: treceri=(\d+) striviri_galerie=(\d+)", t)
    if m:
        d["gal_treceri"], d["gal_striviri"] = int(m[1]), int(m[2])
    m = re.search(r"creasta: zboruri=(\d+) airtime_med=([\d.]+)s", t)
    if m:
        d["zboruri"], d["airtime"] = int(m[1]), float(m[2])
    m = re.search(r"elefant: secunde_oprit_in_piata=([\d.]+)", t)
    if m:
        d["elefant_s"] = float(m[1])
    m = re.search(r"perdea: treceri=(\d+) iesire/intrare med=([-\d.]+) min=([-\d.]+) sub_98%=(\d+) "
                  r"rafale=(\d+) declansari=(\d+)", t)
    if m:
        d["perdea_treceri"], d["perdea_med"], d["perdea_min"] = int(m[1]), float(m[2]), float(m[3])
        d["perdea_sub98"], d["perdea_rafale"] = int(m[4]), int(m[5])
    # pereti pe felia E (0.40-0.50)
    pw = 0
    for a, n in re.findall(r"^\s+(0\.4[05])-0\.\d\d\s+[\d.]+ m/s\s+[\d.]+% lent\s+(\d+) pereti", t, re.M):
        pw += int(n)
    d["pereti_E"] = pw
    d["offroad_max"] = None
    m = re.search(r"cel mai mult in afara soselei: ([\d.]+)%", t)
    if m:
        d["offroad_max"] = float(m[1])
    d["erori"] = len(re.findall(r"SCRIPT ERROR", t))
    return d


def summarize(dirp):
    rows = [parse(p) for p in sorted(glob.glob(os.path.join(dirp, "seed*.log")))]
    return [r for r in rows if "tur_med" in r]


def col(rows, k):
    return [r[k] for r in rows if r.get(k) is not None]


def fmt(v):
    return f"{v:.2f}" if isinstance(v, float) else str(v)


A, B = sys.argv[1], sys.argv[2]
na = sys.argv[3] if len(sys.argv) > 3 else "A"
nb = sys.argv[4] if len(sys.argv) > 4 else "B"
ra, rb = summarize(A), summarize(B)
print(f"seed-uri: {na} {len(ra)}, {nb} {len(rb)}")
keys = ["tur_min", "tur_med", "repuneri", "ejectari", "blocaje", "blocaje_A", "blocaje_E", "pereti_E",
        "gal_treceri", "gal_striviri", "zboruri", "airtime", "elefant_s", "perdea_treceri",
        "perdea_med", "perdea_min", "perdea_sub98", "perdea_rafale", "erori"]
print(f"{'metrica':16s} | {na:>28s} | {nb:>28s}")
for k in keys:
    out = []
    for rows in (ra, rb):
        c = col(rows, k)
        if not c:
            out.append("-")
            continue
        out.append(f"sum {fmt(sum(c)) if not isinstance(c[0], float) else '':>4s} med {fmt(st.median(c))} [{fmt(min(c))}..{fmt(max(c))}]")
    print(f"{k:16s} | {out[0]:>28s} | {out[1]:>28s}")
gs_a, gs_b = sum(col(ra, "gal_striviri")), sum(col(rb, "gal_striviri"))
gt_a, gt_b = sum(col(ra, "gal_treceri")), sum(col(rb, "gal_treceri"))
print(f"domino: {na} {gs_a}/{gt_a} = {100 * gs_a / max(1, gt_a):.1f}%   {nb} {gs_b}/{gt_b} = {100 * gs_b / max(1, gt_b):.1f}%")
