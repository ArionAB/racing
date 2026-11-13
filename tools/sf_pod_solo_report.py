#!/usr/bin/env python3
"""Tabelul SOLO al sondei 1d SF (podul rosu): JSON-urile ProbeSfPod --mode=solo
scrise de tools/sf_pod_solo.sh (masini x piloti x faze, un tur = trecerea pe DUS
si pe INTORS).

  python tools/sf_pod_solo_report.py <outdir>
"""
import glob
import json
import os
import statistics
import sys
from collections import defaultdict


def main():
    rows = defaultdict(lambda: {"runs": 0, "passes": 0, "bc": 0, "tc": 0, "cross": 0, "ej": 0,
                                "resp": 0, "vmin": [], "bv": [], "tv": [], "dur": []})
    for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.json"))):
        r = json.load(open(f))
        car = r["cars"][0]["car_name"]
        pilot = os.path.basename(f).split("_")[1]
        for key in ((car, pilot), ("TOATE", pilot)):
            d = rows[key]
            d["runs"] += 1
            d["cross"] += len(r["crossings"])
            d["ej"] += len(r["ejects"])
            d["resp"] += len(r["respawns"])
            for p in r["passes"]:
                d["passes"] += 1
                d["bc"] += p["block_contacts"]
                d["tc"] += p["truck_contacts"]
                if p["block_contacts"] or p["truck_contacts"]:
                    d["vmin"].append(p["v_min"])
                if "block_v" in p:
                    d["bv"].append(p["block_v"])
                if "truck_v" in p:
                    d["tv"].append(p["truck_v"])
    print("%-12s %-5s %4s %6s %8s %8s %8s %8s %8s %16s" % (
        "masina", "pilot", "rul", "trec", "bariera", "camion", "treceri", "ejectari", "repuneri",
        "v la contact/min"))
    for (car, pilot), d in sorted(rows.items(), key=lambda kv: (kv[0][0] == "TOATE", kv[0])):
        v_in = d["bv"] + d["tv"]
        print("%-12s %-5s %4d %6d %8d %8d %8d %8d %8d %8s / %s" % (
            car, pilot, d["runs"], d["passes"], d["bc"], d["tc"], d["cross"], d["ej"], d["resp"],
            "%.1f" % statistics.median(v_in) if v_in else "-",
            "%.1f" % statistics.median(d["vmin"]) if d["vmin"] else "-"))


if __name__ == "__main__":
    sys.exit(main())
