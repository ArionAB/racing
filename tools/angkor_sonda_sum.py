#!/usr/bin/env python3
"""Agrega log-urile ProbeRace --angkor (16 seed-uri) per varianta: blocaje pe zone,
repuneri, striviri in galerie / treceri, airtime pe creasta, secunde oprite la elefant.

    python tools/angkor_sonda_sum.py <dir_varianta> [<dir_varianta> ...]
"""
import glob, os, re, statistics as st, sys

ZONES = [("poarta", 0.125, 0.155), ("elefant", 0.155, 0.19), ("bayon", 0.30, 0.43),
         ("creasta", 0.64, 0.70), ("galerie/ocol", 0.78, 0.95)]


def zone(f):
    for n, a, b in ZONES:
        if a <= f <= b:
            return n
    return "altundeva"


for d in sys.argv[1:]:
    logs = sorted(glob.glob(os.path.join(d, "s*.log")))
    blk = {}
    rz, ez = {}, {}
    resp, passes, crush, air, stop, slow_laps, fast_laps = [], 0, 0, [], [], [], []
    for p in logs:
        t = open(p, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\[blocaj\].*?frac=([0-9.]+)", t):
            z = zone(float(m.group(1)))
            blk[z] = blk.get(z, 0) + 1
        for m in re.finditer(r"\[repunere\].*?frac=([0-9.]+)", t):
            z = zone(float(m.group(1)))
            rz[z] = rz.get(z, 0) + 1
        for m in re.finditer(r"\[ejectare\].*?frac=([0-9.]+)", t):
            z = zone(float(m.group(1)))
            ez[z] = ez.get(z, 0) + 1
        m = re.search(r"--- repuneri totale: (\d+)", t)
        if m:
            resp.append(int(m.group(1)))
        m = re.search(r"=== ANGKOR galerie: treceri=(\d+) striviri_galerie=(\d+)", t)
        if m:
            passes += int(m.group(1)); crush += int(m.group(2))
        for m in re.finditer(r"\[zbor\] .*?ruta=0 frac=([0-9.]+) ([0-9.]+)s", t):
            if 0.64 <= float(m.group(1)) <= 0.70:
                air.append(float(m.group(2)))
        m = re.search(r"secunde_oprit_in_piata=([0-9.]+)", t)
        if m:
            stop.append(float(m.group(1)))
        m = re.search(r"cel mai rapid ([0-9.]+) tururi, cel mai lent ([0-9.]+)", t)
        if m:
            fast_laps.append(float(m.group(1))); slow_laps.append(float(m.group(2)))
    print(f"== {os.path.basename(d.rstrip('/'))}: {len(logs)} seed-uri")
    print(f"   blocaje pe zone: {dict(sorted(blk.items()))}  (total {sum(blk.values())})")
    print(f"   repuneri pe zone: {dict(sorted(rz.items()))} · ejectari pe zone: {dict(sorted(ez.items()))}")
    print(f"   repuneri: total {sum(resp)}, pe seed med {st.median(resp) if resp else '-'} max {max(resp) if resp else '-'}")
    if passes:
        print(f"   galerie: {passes} treceri, {crush} striviri = {100 * crush / passes:.0f}%")
    if air:
        print(f"   creasta: {len(air)} zboruri, airtime med {st.median(air):.2f}s min {min(air):.2f} max {max(air):.2f}")
    if stop:
        print(f"   elefant: secunde oprite in piata / seed med {st.median(stop):.1f} max {max(stop):.1f}")
    if fast_laps:
        print(f"   tururi in 150 s: cel mai rapid med {st.median(fast_laps):.2f}, cel mai lent med {st.median(slow_laps):.2f}")
