"""Rezumatul A/B ProbeRace Ha Long (tools/halong_race_run.sh):
    python -I tools/halong_race_sum.py <dir_A> <dir_B> [<nume_A> <nume_B>]
Per seed: repuneri (si cate pe scurtatura de maree, frac 0.855-0.965), tururi,
tur minim/mediu, treceri pe banda secundara."""
import glob
import os
import re
import statistics as st
import sys

# Fereastra scurtaturii de maree pe bucla (intrare ~0.862, revenire ~0.960),
# cu o marja pentru racorduri.
LANE = (0.855, 0.965)


def parse(path):
    t = open(path, encoding="utf-8", errors="replace").read()
    d = {}
    m = re.search(r"TUR global: (\d+) ture, minim ([\d.]+) s, mediu ([\d.]+) s", t)
    if m:
        d["ture"], d["tur_min"], d["tur_med"] = int(m[1]), float(m[2]), float(m[3])
    m = re.search(r"repuneri totale: (\d+)", t)
    d["repuneri"] = int(m[1]) if m else None
    fr = [float(x) for x in re.findall(r"^\[repunere\].*?frac=([\d.]+)", t, re.M)]
    d["rep_banda"] = len([f for f in fr if LANE[0] <= f <= LANE[1]])
    m = re.search(r"banda secundara: (\d+) treceri", t)
    d["treceri"] = int(m[1]) if m else 0
    m = re.search(r"cel mai mult in afara soselei: ([\d.]+)%", t)
    d["offroad_max"] = float(m[1]) if m else None
    return d


def load(folder):
    out = {}
    for p in sorted(glob.glob(os.path.join(folder, "seed*.log")),
                    key=lambda s: int(re.findall(r"\d+", os.path.basename(s))[0])):
        out[int(re.findall(r"\d+", os.path.basename(p))[0])] = parse(p)
    return out


def main():
    a, b = load(sys.argv[1]), load(sys.argv[2])
    na = sys.argv[3] if len(sys.argv) > 3 else "A"
    nb = sys.argv[4] if len(sys.argv) > 4 else "B"
    keys = ["repuneri", "rep_banda", "ture", "tur_min", "tur_med", "treceri", "offroad_max"]
    print("seed | " + " | ".join("%s %s/%s" % (k, na, nb) for k in keys))
    for s in sorted(set(a) | set(b)):
        row = []
        for k in keys:
            va, vb = a.get(s, {}).get(k), b.get(s, {}).get(k)
            row.append("%s / %s" % (va, vb))
        print("%4d | %s" % (s, " | ".join(row)))
    for k in keys:
        va = [x[k] for x in a.values() if x.get(k) is not None]
        vb = [x[k] for x in b.values() if x.get(k) is not None]
        if va and vb:
            print("%-12s mediana %s: %.2f  %s: %.2f   suma %s: %.1f  %s: %.1f" % (
                k, na, st.median(va), nb, st.median(vb), na, sum(va), nb, sum(vb)))


main()
