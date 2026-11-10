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
import os
import sys
from collections import defaultdict


def pct(a, q):
    if not a:
        return 0.0
    a = sorted(a)
    k = min(len(a) - 1, max(0, int(round(q * (len(a) - 1)))))
    return a[k]


def med(a):
    return pct(a, 0.5)


def solo_table(solo):
    """SFSOLO_JSON: o linie pe (scena, ziduri); fiecare rezultat = o trecere a
    unei masini din garaj (pentru pro / wide: cea mai buna din baleiaj)."""
    print("\nSOLO (garajul, o trecere pe masina; delta = scurtatura - ocolul AI, aceeasi masina)")
    print("  scena            ziduri   | pilot | treceri ok/tot | t med [min-max]      | delta med [min..max] | off med | perete | resp | blocaj | contrasens")
    for (scene, walls) in sorted(solo):
        res = solo[(scene, walls)]
        ocol = {r["ci"]: r["t"] for r in res if r["pilot"] == "ai" and r["route"] == 0 and r["done"]}
        if ocol:
            ts = list(ocol.values())
            print("  %-16s %-8s | ocol  | %3d/%-3d        | %5.2f [%5.2f-%5.2f]  |" % (
                scene, walls, len(ts), len(ts), med(ts), min(ts), max(ts)))
        for pilot in ("ai", "pro", "wide", "line"):
            rs = [r for r in res if r["pilot"] == pilot and r["route"] == 1]
            if not rs:
                continue
            ok = [r for r in rs if r["done"] and r["route_used"] == 1]
            ts = [r["t"] for r in ok]
            ds = [r["t"] - ocol[r["ci"]] for r in ok if r["ci"] in ocol]
            print("  %-16s %-8s | %-5s | %3d/%-3d        | %5.2f [%5.2f-%5.2f]  | %+5.2f [%+5.2f..%+5.2f] | %5.2f   | %6d | %4d | %6d | %5.2f s" % (
                scene, walls, pilot, len(ok), len(rs), med(ts), min(ts) if ts else 0, max(ts) if ts else 0,
                med(ds), min(ds) if ds else 0, max(ds) if ds else 0,
                med([r["off"] for r in rs]), sum(r["walls"] for r in rs), sum(r["resp"] for r in rs),
                sum(r["stuck"] for r in rs), sum(r["wrong"] for r in rs)))
            if pilot == "pro":
                print("  %-16s %-8s |       | viteza in ace aleasa (m/s): %s" % (
                    "", "", " ".join("%s:%g" % (r["car"].split()[0], r["alat"]) for r in rs)))


def main(paths):
    solo = {}
    for p in paths:
        with open(p, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("SFSOLO_JSON "):
                    d = json.loads(line[len("SFSOLO_JSON "):])
                    w = "fara" if d["walls"][0] < 0 else "%g/%g" % (d["walls"][0], d["walls"][1])
                    solo[(d["scene"].replace("SondaSfSerp", "").replace(".tscn", ""), w)] = d["results"]
    if solo:
        solo_table(solo)
    runs = defaultdict(list)
    for p in paths:
        with open(p, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("SFSERP_JSON "):
                    d = json.loads(line[len("SFSERP_JSON "):])
                    # eticheta din numele logului (race_<scena>_<ziduri>_sN.log) daca
                    # exista: primele rulari n-aveau cheia "walls" in JSON
                    base = os.path.basename(p)
                    if base.startswith("race_") and "_s" in base:
                        tag = base[len("race_"):base.rindex("_s")]
                    else:
                        w = d.get("walls", [-1, 0])
                        tag = d["scene"] + ("" if w[0] < 0 else " ziduri %g/%g" % (w[0], w[1]))
                    runs[tag].append(d)
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
