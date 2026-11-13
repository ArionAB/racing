#!/usr/bin/env python3
"""Tabelul A/B al tramvaielor San Francisco (Track25, brief san_francisco.md §7 pasul 5), din
loturile ProbeRace --sf rulate cu tools/sf_route_race.sh.

    python tools/sf_tram_report.py <dir_baza> <eticheta>=<dir> [<eticheta>=<dir> ...]

<dir_baza> = lotul `--no-tram` (aceeasi pista, tramvaiele scoase inainte de start): din el vin
timpii de referinta pe masina (mediana) pentru PIERDEREA pe intalnire:
  - tramvaiul 1: timpul pe urcare (poarta de la baza -> 30 m pe latura de nord) minus mediana
    aceleiasi masini fara tramvai;
  - tramvaiul 2: timpul furca -> 70 m dupa gura, pe aceeasi ruta (ocol / serpentine), minus
    mediana aceleiasi masini pe aceeasi ruta fara tramvai.
Zgomotul se vede pe intalnirile FARA contact (martorul). Distributii pe seed-uri, nu o rulare
(memoria `proberace-nedeterminism`).
"""
import glob
import os
import re
import statistics as st
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sf_route_report import zone  # noqa: E402

TRAM1_LEN = 328.0
TRAM2_LEN = 128.0


def pct(a, q):
    if not a:
        return float("nan")
    a = sorted(a)
    return a[min(len(a) - 1, int(q * (len(a) - 1) + 0.5))]


def med(a):
    return st.median(a) if a else float("nan")


def load(d):
    runs = []
    for p in sorted(glob.glob(os.path.join(d, "seed*.log")),
                    key=lambda p: int(re.findall(r"seed(\d+)", p)[-1])):
        txt = open(p, encoding="utf-8", errors="replace").read()
        if "=== CURSA" not in txt:
            print("ATENTIE: %s fara raport" % p)
            continue
        r = {"name": os.path.basename(p), "blocaj": [], "resp": [], "ej": [], "enc": [],
             "ct": [], "climb": [], "p2": [], "gate": [], "lap": None}
        m = re.search(r"TUR global: (\d+) ture, minim ([\d.]+) s, mediu ([\d.]+) s", txt)
        if m:
            r["lap"] = (int(m.group(1)), float(m.group(2)), float(m.group(3)))
        for m in re.finditer(r"^\[blocaj\] t=\s*([\d.]+)s\s+(.+?)\s+frac=([\d.]+)\s+v=\s*([\d.]+).*?"
                             r"poz=\((-?\d+),(-?\d+),(-?\d+)\)\s+atinge: (.*)$", txt, re.M):
            x, z = float(m.group(5)), float(m.group(7))
            r["blocaj"].append((float(m.group(1)), m.group(2).strip(), zone(x, -z), (x, -z), m.group(8)))
        for m in re.finditer(r"^    \[sf repunere\] t=\s*([\d.]+)s (.+?)\s+zona=(\S+) "
                             r"poz=\((-?\d+),(-?[\d.]+),(-?\d+)\)", txt, re.M):
            x, z = float(m.group(4)), float(m.group(6))
            r["resp"].append((float(m.group(1)), m.group(2).strip(), zone(x, -z), (x, -z)))
        for m in re.finditer(r"^    \[sf ejectare\] t=\s*([\d.]+)s (.+?)\s+zona=(\S+) (\S+) ([\d.]+) "
                             r"poz=\((-?\d+),(-?[\d.]+),(-?\d+)\)", txt, re.M):
            x, z = float(m.group(6)), float(m.group(8))
            r["ej"].append((float(m.group(1)), m.group(2).strip(), zone(x, -z), m.group(4)))
        for m in re.finditer(r"^    \[sf tram enc\] (\d) (.+?) r=(\d) t=([\d.]+)\.\.([\d.]+) v_in=([\d.]+) "
                             r"v_min=([\d.]+) lat=(-?[\d.]+) contact=(\d) (\S+)$", txt, re.M):
            r["enc"].append({"tram": min(int(m.group(1)), 2), "car": m.group(2), "route": int(m.group(3)),
                             "t_in": float(m.group(4)), "t_out": float(m.group(5)),
                             "v_in": float(m.group(6)), "v_min": float(m.group(7)),
                             "lat": float(m.group(8)), "contact": m.group(9) == "1",
                             "reason": m.group(10)})
        for m in re.finditer(r"^    \[sf tram contact\] (\d) (.+?) r=(\d) t=([\d.]+) v=([\d.]+) "
                             r"rel_z=(-?[\d.]+) tram_d=([\d.]+) poz=\((-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\)",
                             txt, re.M):
            r["ct"].append({"tram": min(int(m.group(1)), 2), "car": m.group(2), "route": int(m.group(3)),
                            "t": float(m.group(4)), "v": float(m.group(5)), "rel_z": float(m.group(6)),
                            "tram_d": float(m.group(7)), "x": float(m.group(8)),
                            "y": -float(m.group(10))})
        for m in re.finditer(r"^    \[sf urcare\] (.+?) t=([\d.]+) (-?[\d.]+)s( REPUSA)?$", txt, re.M):
            r["climb"].append((m.group(1), float(m.group(2)), float(m.group(3)), bool(m.group(4))))
        for m in re.finditer(r"^    \[sf poarta2\] (.+?) ruta=(\d) t=([\d.]+) (-?[\d.]+)s( REPUSA)?$",
                             txt, re.M):
            r["p2"].append((m.group(1), int(m.group(2)), float(m.group(3)), float(m.group(4)),
                            bool(m.group(5))))
        for m in re.finditer(r"^    \[sf poarta\] (.+?)\s+ruta=(\d) (-?[\d.]+)s( REPUSA)?$", txt, re.M):
            r["gate"].append((int(m.group(2)), float(m.group(3)), bool(m.group(4))))
        runs.append(r)
    return runs


def baseline(runs):
    climb, p2 = {}, {}
    for r in runs:
        for car, _t, s, resp in r["climb"]:
            if s > 0 and not resp:
                climb.setdefault(car, []).append(s)
        for car, route, _t, s, resp in r["p2"]:
            if s > 0 and not resp:
                p2.setdefault((car, route), []).append(s)
    return ({k: med(v) for k, v in climb.items()}, {k: med(v) for k, v in p2.items()})


def ct_place(c):
    if c["tram"] == 1:
        if c["tram_d"] < 40.0:
            return "intrare"
        if c["x"] < -70.0:
            return "colt de sus"
        return "pe ax"
    # dupa pozitia masinii (harta): strada de jos are axul la y = 454
    if c["x"] < -100.0 or (c["x"] < -15.0 and c["y"] < 446.0):
        return "intrare"
    if (c["x"] > 30.0 and c["y"] < 446.0) or c["y"] > 458.0:
        return "iesire"     # runda 1: in dreapta dupa gura; runda 2: spre mal (stanga)
    if -10.0 <= c["x"] <= 25.0:
        return "gura"
    return "pe ax"


def loss_of(r, e, base):
    b_climb, b_p2 = base
    if e["tram"] == 1:
        for car, t, s, resp in r["climb"]:
            if car == e["car"] and s > 0 and not resp and t <= e["t_in"] <= t + s and car in b_climb:
                return s - b_climb[car]
        return None
    for car, route, t, s, resp in r["p2"]:
        if car == e["car"] and s > 0 and not resp and t <= e["t_in"] <= t + s \
                and (car, route) in b_p2:
            return s - b_p2[(car, route)]
    return None


def summarize(label, runs, base):
    n = len(runs)
    print("\n##### %s: %d seed-uri" % (label, n))
    laps = [r["lap"] for r in runs if r["lap"]]
    if laps:
        w = sum(a for a, _, _ in laps)
        print("  tur mediu %.2f s (minim %.2f), %d ture" % (
            sum(a * c for a, _, c in laps) / max(w, 1), min(b for _, b, _ in laps), w))
    bl = [len(r["blocaj"]) for r in runs]
    print("  [blocaj] total %d  pe seed: %s" % (sum(bl), " ".join(str(x) for x in bl)))
    zones = {}
    for r in runs:
        for b in r["blocaj"]:
            zones.setdefault(b[2], []).append(b)
    for zn, bs in sorted(zones.items()):
        print("    %-20s %d   %s" % (zn, len(bs), "; ".join(
            "t=%.0f %s (%.0f,%.0f) %s" % (b[0], b[1], b[3][0], b[3][1], b[4][:40])
            for b in bs[:3])))
    rs = [len(r["resp"]) for r in runs]
    rz = {}
    for r in runs:
        for x in r["resp"]:
            rz[x[2]] = rz.get(x[2], 0) + 1
    print("  repuneri total %d (%s)" % (sum(rs), ", ".join("%s %d" % kv for kv in sorted(rz.items()))))
    ez = {}
    for r in runs:
        for x in r["ej"]:
            ez[x[2]] = ez.get(x[2], 0) + 1
    print("  ejectari total %d (%s)" % (sum(len(r["ej"]) for r in runs),
                                       ", ".join("%s %d" % kv for kv in sorted(ez.items()))))
    for tram in (1, 2):
        enc = [(r, e) for r in runs for e in r["enc"] if e["tram"] == tram]
        cts = [c for r in runs for c in r["ct"] if c["tram"] == tram]
        if not enc and not cts:
            continue
        hit = [e for _, e in enc if e["contact"]]
        print("  --- tramvaiul %d: intalniri %d (%.1f / seed), cu contact %d = %.1f%%; contacte %d" % (
            tram, len(enc), len(enc) / max(n, 1), len(hit), 100.0 * len(hit) / max(len(enc), 1),
            len(cts)))
        left = sum(1 for _, e in enc if e["lat"] < 0)
        print("      depasiri pe STANGA lui %d, pe DREAPTA %d (%.0f%% stanga); terminate prin depasire %d" % (
            left, len(enc) - left, 100.0 * left / max(len(enc), 1),
            sum(1 for _, e in enc if e["reason"] == "depasit")))
        slow = [e for _, e in enc if e["v_min"] < 10.0]
        print("      coada (masina sub 10 m/s in intalnire): %d = %.1f%%" % (
            len(slow), 100.0 * len(slow) / max(len(enc), 1)))
        lap1 = [e for _, e in enc if e["t_in"] < 75.0]
        print("      intalniri in turul 1 (t < 75 s): %d, cu contact %d" % (
            len(lap1), sum(1 for e in lap1 if e["contact"])))
        if tram == 2:
            for route, nm in ((0, "ocol"), (1, "serpentine")):
                er = [e for _, e in enc if e["route"] == route]
                print("      intalniri venind de pe %s: %d, cu contact %d" % (
                    nm, len(er), sum(1 for e in er if e["contact"])))
        places = {}
        for c in cts:
            places[ct_place(c)] = places.get(ct_place(c), 0) + 1
        print("      contacte dupa loc: %s; din spate (rel_z > 3,5) %d, lateral %d; v med %.1f m/s" % (
            ", ".join("%s %d" % kv for kv in sorted(places.items())),
            sum(1 for c in cts if c["rel_z"] > 3.5), sum(1 for c in cts if abs(c["rel_z"]) <= 3.5),
            med([c["v"] for c in cts]) if cts else -1))
        losses = {"toate": [], "cu contact": [], "fara contact": []}
        for r, e in enc:
            ls = loss_of(r, e, base)
            if ls is None:
                continue
            losses["toate"].append(ls)
            losses["cu contact" if e["contact"] else "fara contact"].append(ls)
        for k, v in losses.items():
            if v:
                print("      pierdere / intalnire %-12s n=%4d  mediana %5.2f s  p90 %5.2f  max %5.2f  >2 s: %d" % (
                    k, len(v), med(v), pct(v, 0.9), max(v), sum(1 for x in v if x > 2.0)))
    # scurtatura vs ocol (poarta veche fork -> gura+20 si cea noua fork -> gura+70)
    for nm, key in (("furca -> gura + 20 m", "gate"), ("furca -> gura + 70 m", "p2")):
        ts = {0: [], 1: []}
        bad = {0: 0, 1: 0}
        for r in runs:
            for row in r[key]:
                route, s, resp = (row[0], row[1], row[2]) if key == "gate" else (row[1], row[3], row[4])
                if s > 0 and not resp:
                    ts[route].append(s)
                else:
                    bad[route] += 1
        if ts[0] and ts[1]:
            print("  %s: ocol %d treceri med %.2f (min %.2f), serpentine %d med %.2f (min %.2f) -> castig median %+.2f s, intre cele mai bune %+.2f s; repuse/neterminate %d / %d" % (
                nm, len(ts[0]), med(ts[0]), min(ts[0]), len(ts[1]), med(ts[1]), min(ts[1]),
                med(ts[0]) - med(ts[1]), min(ts[0]) - min(ts[1]), bad[0], bad[1]))
    # contact cu tramvaiul 2 pe trecerile prin serpentine (criteriul branch_gate, brief §2: > 30%)
    n1 = hit1 = 0
    for r in runs:
        for car, route, t, s, resp in r["p2"]:
            if route != 1 or s <= 0:
                continue
            n1 += 1
            if any(c["tram"] == 2 and c["car"] == car and t <= c["t"] <= t + s for c in r["ct"]):
                hit1 += 1
    if n1:
        print("  serpentine: %d treceri, %d cu contact cu tramvaiul 2 (%.1f%%; prag branch_gate 30%%)" % (
            n1, hit1, 100.0 * hit1 / n1))
    n_serp = sum(1 for r in runs for row in r["gate"] if row[0] == 1)
    bl_s = sum(1 for r in runs for b in r["blocaj"] if b[2] == "serpentine")
    rs_s = sum(1 for r in runs for x in r["resp"] if x[2] == "serpentine")
    if n_serp:
        print("  pe serpentine: [blocaj] %d (%.1f%% din %d treceri), repuneri %d (%.1f%%)" % (
            bl_s, 100.0 * bl_s / n_serp, n_serp, rs_s, 100.0 * rs_s / n_serp))
    ej_l = sum(1 for r in runs for x in r["ej"] if x[2] == "lant")
    print("  ejectari pe lant: %d" % ej_l)


def main():
    base_runs = load(sys.argv[1])
    base = baseline(base_runs)
    summarize("BAZA (fara tramvaie)", base_runs, base)
    for arg in sys.argv[2:]:
        label, d = arg.split("=", 1)
        summarize(label, load(d), base)


if __name__ == "__main__":
    main()
