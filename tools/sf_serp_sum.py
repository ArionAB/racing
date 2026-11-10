#!/usr/bin/env python3
"""Aduna iesirile `SFSERP_JSON {...}` ale ProbeSfSerp --mode=race (sonda 1b San
Francisco, serpentinele) intr-un tabel pe scena x ruta.

  python tools/sf_serp_sum.py <fisier.log> [<fisier.log> ...]

Pe fiecare scena: cate seed-uri, apoi pe ruta 0 (ocolul) si ruta 1
(scurtatura): treceri, neterminate, timpul pe segment (mediana, p10-p90),
offroad mediu pe trecere, cate treceri au avut contrasens > 0,5 s, marsarier,
[blocaj] in segment, repuneri in segment, perete. Plus [blocaj] / repunerile
de pe restul buclei.
"""
import json
import sys
from collections import defaultdict


def pct(a, q):
    if not a:
        return 0.0
    a = sorted(a)
    k = min(len(a) - 1, max(0, int(round(q * (len(a) - 1)))))
    return a[k]


def main(paths):
    runs = defaultdict(list)
    for p in paths:
        with open(p, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("SFSERP_JSON "):
                    d = json.loads(line[len("SFSERP_JSON "):])
                    runs[d["scene"]].append(d)
    for scene in sorted(runs):
        rs = runs[scene]
        seeds = sorted({r["seed"] for r in rs})
        print("\n%s — %d rulari, seed-uri %s, ai_shortcut_chance %.2f" % (
            scene, len(rs), ",".join(str(s) for s in seeds), rs[0]["chance"]))
        print("  ruta | treceri | neterm | t med [p10-p90]        | off/trecere | contrasens>0.5s | mars>0.5s | blocaj seg | resp seg | perete")
        for route in (0, 1):
            ps = [p for r in rs for p in r["passes"] if p["route"] == route]
            if not ps:
                print("  %4d | %7d |" % (route, 0))
                continue
            ts = [p["t"] for p in ps if p["done"]]
            inc = sum(1 for p in ps if not p["done"])
            off = sum(p["off"] for p in ps) / len(ps)
            wrong = sum(1 for p in ps if p["wrong"] > 0.5)
            rev = sum(1 for p in ps if p["rev"] > 0.5)
            st = sum(p["stuck"] for p in ps)
            rp = sum(p["resp"] for p in ps)
            wl = sum(p["walls"] for p in ps)
            print("  %4d | %7d | %6d | %5.2f [%5.2f-%5.2f]      | %6.2f s    | %15d | %9d | %10d | %8d | %d" % (
                route, len(ps), inc, pct(ts, 0.5), pct(ts, 0.1), pct(ts, 0.9), off, wrong, rev, st, rp, wl))
        out_st = sum(1 for r in rs for e in r["stuck"] if not e["in_seg"])
        out_rp = sum(1 for r in rs for e in r["respawns"] if not e["in_seg"])
        print("  restul buclei: [blocaj] %d, repuneri %d" % (out_st, out_rp))
        seg_events = [e for r in rs for e in r["stuck"] if e["in_seg"]]
        for e in seg_events[:12]:
            print("    [blocaj] seg t=%.1f %s ruta %d poz %s v %.1f atinge %s" % (
                e["t"], e["car"], e["route"], e["pos"], e["v"], e["touch"] or "-"))
        for r in rs:
            for e in r["respawns"]:
                if e["in_seg"]:
                    print("    [repunere] seg seed %d t=%.1f %s ruta %d -> %s" % (
                        r["seed"], e["t"], e["car"], e["route"], e["pos"]))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
