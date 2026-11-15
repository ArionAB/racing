#!/usr/bin/env python3
"""Agrega JSON-urile ProbeSfPod --mode=race (sonda 1d SF, podul rosu cu
despartitor mobil) intr-un tabel per configuratie.

  python tools/sf_pod_report.py <dir_baza> <eticheta>=<dir> [<eticheta>=<dir> ...]

<dir_baza> = rularile `--config=fix` (bariera fixa la axa, fara camion): din ele
vine timpul de referinta al unei TRECERI PESTE POD, per masina si per sens
(mediana). PIERDEREA unei treceri = timpul ei minus referinta. Distributii pe
seed-uri (memoria proberace-nedeterminism), nu o rulare.

TRECERE = o masina pe tablier, de la un capat la celalalt (ProbeSfPod).
"""
import glob
import json
import os
import statistics
import sys
from collections import defaultdict


def load(d):
    runs = []
    for f in sorted(glob.glob(os.path.join(d, "s*.json"))):
        try:
            runs.append(json.load(open(f)))
        except Exception as e:  # noqa: BLE001
            print("  (sar %s: %s)" % (f, e))
    return runs


def pct(vs, q):
    vs = sorted(vs)
    return vs[int(q * (len(vs) - 1))] if vs else float("nan")


def dur(p):
    return p["t_out"] - p["t_in"]


def good(p):
    return p["t_out"] > 0 and p["complete"] and not p["respawn"]


def baseline(runs):
    acc = defaultdict(list)
    for r in runs:
        for p in r["passes"]:
            if good(p) and p["t_in"] > 15.0:
                acc[(p["car_name"], p["side"])].append(dur(p))
    return {k: statistics.median(v) for k, v in acc.items()}


def line(label, vals, unit=""):
    if not vals:
        return "  %-34s -" % label
    return "  %-34s med %5.2f%s  p90 %5.2f  max %5.2f  (n=%d)" % (
        label, statistics.median(vals), unit, pct(vals, 0.9), max(vals), len(vals))


def report(label, runs, base):
    n = len(runs)
    secs = runs[0]["seconds"] if runs else 0
    print("\n##### %s: %d seed-uri x %.0f s, scena %s" % (
        label, n, secs, os.path.basename(runs[0]["scene"]) if runs else "?"))
    passes = [p for r in runs for p in r["passes"]]
    laps = [b - a for r in runs for c in r["cars"]
            for a, b in zip([0.0] + c["laps_t"], c["laps_t"])][0:]
    laps_clean = [b - a for r in runs for c in r["cars"]
                  for a, b in zip(c["laps_t"], c["laps_t"][1:])]
    print("  tururi %d, tur mediu (fara primul) %.1f s, minim %.1f s" % (
        len(laps), statistics.mean(laps_clean) if laps_clean else -1, min(laps_clean) if laps_clean else -1))
    bl = [len(r["blocaj"]) for r in runs]
    bl_deck = sum(1 for r in runs for b in r["blocaj"] if b["on_deck"])
    rs = [len(r["respawns"]) for r in runs]
    rs_deck = sum(1 for r in runs for b in r["respawns"] if b["on_deck"] or -2 < b["s"] < 302)
    ej = [len(r["ejects"]) for r in runs]
    cr = [len(r["crossings"]) for r in runs]
    ho = [sum(1 for h in r["headon"] if h.get("corridor", True)) for r in runs]
    ho_out = sum(1 for r in runs for h in r["headon"] if not h.get("corridor", True))
    print("  treceri peste pod            %5d (%.1f / seed), complete %d" % (
        len(passes), len(passes) / max(n, 1), sum(1 for p in passes if good(p))))
    print("  [blocaj]                     %5d (pe tablier %d)   pe seed: %s" % (
        sum(bl), bl_deck, " ".join(map(str, bl))))
    print("  repuneri                     %5d (pe/de pe tablier %d)   pe seed: %s" % (
        sum(rs), rs_deck, " ".join(map(str, rs))))
    print("  ejectari (sofer)             %5d   pe seed: %s" % (sum(ej), " ".join(map(str, ej))))
    print("  TRECERI PESTE DESPARTITOR    %5d   pe seed: %s" % (sum(cr), " ".join(map(str, cr))))
    print("  ciocniri FRONTALE pe coridor %5d   (in afara lui, in baloane: %d)" % (sum(ho), ho_out))
    pb = [p for p in passes if p["block_contacts"] > 0]
    pt = [p for p in passes if p["truck_contacts"] > 0]
    print("  treceri cu contact BARIERA   %5d = %.1f%% (contacte %d, cadre %d; v la primul contact med %.1f m/s)" % (
        len(pb), 100.0 * len(pb) / max(len(passes), 1), sum(p["block_contacts"] for p in passes),
        sum(p["block_frames"] for p in passes),
        statistics.median([p["block_v"] for p in pb if "block_v" in p]) if pb else -1))
    print("  treceri cu contact CAMION    %5d = %.1f%% (contacte %d)" % (
        len(pt), 100.0 * len(pt) / max(len(passes), 1), sum(p["truck_contacts"] for p in passes)))
    near = [p for p in passes if p["truck_near"]]
    slow = [p for p in near if p["truck_slow"]]
    print("  intalniri cu camionul        %5d, sub 10 m/s langa el (coada) %d = %.1f%%" % (
        len(near), len(slow), 100.0 * len(slow) / max(len(near), 1)))
    nn = sum(p.get("narrow_n", 0) for p in passes)
    nt = sum(p["n"] for p in passes)
    wavg = [p["w_sum"] / p["n"] for p in passes if p["n"] > 0]
    print("  banda INGUSTA (< 10 m)       %.1f%% din timpul pe tablier; latimea medie a benzii %.1f m" % (
        100.0 * nn / max(nt, 1), statistics.mean(wavg) if wavg else -1))
    ov = [o for r in runs for o in r["overtakes"]]
    ovn = [o for o in ov if o["narrow"]]
    print("  depasiri pe tablier          %5d (%.1f / seed), in banda ingusta %d = %.1f%%" % (
        len(ov), len(ov) / max(n, 1), len(ovn), 100.0 * len(ovn) / max(len(ov), 1)))
    losses, losses_c, losses_t = [], [], []
    for p in passes:
        if not good(p) or p["t_in"] <= 15.0:
            continue
        b = base.get((p["car_name"], p["side"]))
        if b is None:
            continue
        loss = dur(p) - b
        losses.append(loss)
        if p["block_contacts"] > 0:
            losses_c.append(loss)
        if p["truck_contacts"] > 0:
            losses_t.append(loss)
    print(line("pierdere / trecere (toate)", losses, " s"))
    print(line("pierdere / trecere cu bariera", losses_c, " s"))
    print(line("pierdere / trecere cu camion", losses_t, " s"))
    tick = [r["tick_us_med"] for r in runs]
    tick99 = [r["tick_us_p99"] for r in runs]
    print("  cost hazard / tick: median %d us, p99 %d us; blocuri mutate max %d" % (
        statistics.median(tick), max(tick99), max(r["moved_max"] for r in runs)))
    for r in runs:
        for b in r["blocaj"]:
            print("    [blocaj] seed %d t=%.1f %s s=%.1f z=%.1f pod=%s v=%.1f camion@%.0fm contact_acum %.1fs atinge %s" % (
                r["seed"], b["t"], b["name"], b["s"], b["z"], b["on_deck"], b["v"], b["truck_d"],
                b["since_contact"], b["touching"]))
        for b in r["respawns"]:
            print("    [repunere] seed %d t=%.1f %s s=%.1f z=%.1f y=%.1f v=%.1f contact_acum %.1fs" % (
                r["seed"], b["t"], b["name"], b["s"], b["z"], b["y"], b["v"], b["since_contact"]))
        for b in r["ejects"]:
            print("    [ejectare] seed %d t=%.1f %s %s dv=%.1f s=%.1f z=%.1f" % (
                r["seed"], b["t"], b["name"], b["cause"], b["value"], b["s"], b["z"]))
        for b in r["crossings"]:
            print("    [trecere] seed %d t=%.1f %s s=%.1f z=%.2f bariera %.2f v=%.1f" % (
                r["seed"], b["t"], b["name"], b["s"], b["z"], b["offset"], b["v"]))
        for b in r["headon"]:
            print("    [frontal] seed %d t=%.1f %s x %s s=%.1f z=%.1f" % (
                r["seed"], b["t"], b["a"], b["b"], b["s"], b["z"]))


def main():
    base_runs = load(sys.argv[1])
    base = baseline(base_runs)
    report("BAZA fix", base_runs, base)
    for arg in sys.argv[2:]:
        label, d = arg.split("=", 1)
        report(label, load(d), base)


if __name__ == "__main__":
    sys.exit(main())
