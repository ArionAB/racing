#!/usr/bin/env python3
"""Agrega loturile ProbeRace --sf de pe San Francisco (tools/sf_route_race.sh):
lantul, scurtatura fata de ocol, restul turului; [blocaj], repuneri, ejectari, lent / invers.

    python tools/sf_route_report.py <dir_cu_seedN.log> [<alt_dir> ...]

Zonele se iau din POZITIA evenimentului (harta: x est, y nord = -z Godot), dupa geometria din
tools/gen_sf_route.py: lantul pe x = 0 de la prima muchie (y 0) la terasa (y 264), furca la
y 300, serpentinele intre furca si strada de jos (y 454), ocolul la vest de ele.
"""
import glob
import os
import re
import statistics as st
import sys


def zone(x, y):
    if abs(x) < 12 and -20 <= y <= 270:
        return "lant"
    if abs(x) < 14 and 270 < y <= 312:
        return "terasa/furca"
    if -14 <= x <= 50 and 312 < y <= 447:
        return "serpentine"
    if x < -8 and 300 < y <= 462:
        return "ocol"
    if y > 440 and x >= -8:
        return "strada de jos/chei"
    if x > 200:
        return "faleza"
    if y < -140:
        return "urcare"
    return "coama"


def pct(a, q):
    if not a:
        return float("nan")
    a = sorted(a)
    return a[min(len(a) - 1, int(q * len(a)))]


def main():
    dirs = sys.argv[1:]
    logs = []
    for d in dirs:
        logs += sorted(glob.glob(os.path.join(d, "seed*.log")),
                       key=lambda p: int(re.findall(r"seed(\d+)", p)[0]))
    lap_means, lap_mins, lap_n = [], [], 0
    car_laps = []
    blocks, resps, ejects = [], [], []
    lent = invers = 0.0
    lip_v = {}
    flights = {}
    out_flights = []
    passes = {0: [], 1: []}
    pass_resp = {0: 0, 1: 0}
    pass_unfin = {0: 0, 1: 0}
    buckets = {}
    land_max = 0.0
    seeds_ok = 0
    for p in logs:
        txt = open(p, encoding="utf-8", errors="replace").read()
        if "=== CURSA" not in txt:
            print("ATENTIE: %s fara raport" % p)
            continue
        seeds_ok += 1
        m = re.search(r"TUR global: (\d+) ture, minim ([\d.]+) s, mediu ([\d.]+) s", txt)
        if m:
            lap_n += int(m.group(1))
            lap_mins.append(float(m.group(2)))
            lap_means.append((float(m.group(3)), int(m.group(1))))
        for m in re.finditer(r"^    (.+?)\s+(\d+)  min\s+([\d.]+)  med\s+([\d.]+)$", txt, re.M):
            if int(m.group(2)) > 0:
                car_laps.append((m.group(1).strip(), float(m.group(4)), float(m.group(3))))
        for m in re.finditer(r"^\[blocaj\] t=\s*([\d.]+)s\s+(.+?)\s+frac=([\d.]+)\s+v=\s*([\d.]+).*?poz=\((-?\d+),(-?\d+),(-?\d+)\)\s+atinge: (.*)$",
                             txt, re.M):
            x, z = float(m.group(5)), float(m.group(7))
            blocks.append((os.path.basename(p), float(m.group(1)), m.group(2).strip(), float(m.group(3)),
                           zone(x, -z), m.group(8)[:90], (x, -z)))
        for m in re.finditer(r"^\[repunere\] t=\s*([\d.]+)s\s+(.+?)\s+frac=([\d.]+)\s+poz=\((-?\d+),(-?\d+),(-?\d+)\)",
                             txt, re.M):
            pass
        for m in re.finditer(r"^    \[sf repunere\] t=\s*([\d.]+)s (.+?)\s+zona=(\S+) poz=\((-?\d+),(-?[\d.]+),(-?\d+)\)",
                             txt, re.M):
            x, z = float(m.group(4)), float(m.group(6))
            resps.append((os.path.basename(p), float(m.group(1)), m.group(2).strip(), zone(x, -z), (x, -z)))
        for m in re.finditer(r"^    \[sf ejectare\] t=\s*([\d.]+)s (.+?)\s+zona=(\S+) (\S+) ([\d.]+) poz=\((-?\d+),(-?[\d.]+),(-?\d+)\)",
                             txt, re.M):
            x, z = float(m.group(6)), float(m.group(8))
            ejects.append((os.path.basename(p), float(m.group(1)), m.group(2).strip(), zone(x, -z), m.group(4),
                           float(m.group(5)), (x, -z)))
        sec = txt.split("=== CURSA", 1)[1].split("--- ritm", 1)[0]
        for line in sec.splitlines()[2:]:
            mm = re.match(r"^(.+?)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)%\s+([\d.]+)s\s+([\d.]+)s", line)
            if mm:
                lent += float(mm.group(5))
                invers += float(mm.group(6))
        m = re.search(r"cea mai dura aterizare FARA ejectare: ([\d.]+)", txt)
        if m:
            land_max = max(land_max, float(m.group(1)))
        for m in re.finditer(r"^    \[sf muchie\] (\d) v=(.*)$", txt, re.M):
            vals = [float(v) for v in m.group(2).split(",") if v]
            lip_v.setdefault(int(m.group(1)), []).extend(vals)
        for m in re.finditer(r"^    \[sf zbor\] (\d) (.+?) air=([\d.]+) v0=([\d.]+) dist=(-?[\d.]+)$", txt, re.M):
            flights.setdefault(int(m.group(1)), []).append(
                (m.group(2), float(m.group(3)), float(m.group(4)), float(m.group(5))))
        for m in re.finditer(r"^    \[zbor in afara lantului\] (.+?)\s+ruta=(\d) frac=([\d.]+) ([\d.]+)s v0=([\d.]+)", txt, re.M):
            out_flights.append((m.group(1).strip(), int(m.group(2)), float(m.group(3)), float(m.group(4))))
        for m in re.finditer(r"^    \[sf poarta\] (.+?)\s+ruta=(\d) (-?[\d.]+)s( REPUSA)?$", txt, re.M):
            r = int(m.group(2))
            t = float(m.group(3))
            if m.group(4):
                pass_resp[r] += 1
            elif t < 0:
                pass_unfin[r] += 1
            else:
                passes[r].append(t)
        for m in re.finditer(r"^  (\d\.\d\d)-(\d\.\d\d)\s+([\d.]+) m/s\s+([\d.]+)% lent\s+(\d+) pereti", txt, re.M):
            b = buckets.setdefault(m.group(1), [[], [], 0])
            b[0].append(float(m.group(3)))
            b[1].append(float(m.group(4)))
            b[2] += int(m.group(5))

    print(f"=== San Francisco (Track25) — {seeds_ok} seed-uri x 8 masini")
    if lap_means:
        w = sum(n for _, n in lap_means)
        mean = sum(a * n for a, n in lap_means) / w
        print(f"TUR: {lap_n} ture, mediu {mean:.2f} s, minim {min(lap_mins):.2f} s "
              f"(tinta 76-78, fereastra 65-80)")
        per_car = {}
        for name, med, mn in car_laps:
            key = name.split("(")[-1].rstrip(")")
            per_car.setdefault(key, []).append(med)
        print("  tur mediu pe masina: " + ", ".join(
            f"{k} {st.mean(v):.1f}" for k, v in sorted(per_car.items(), key=lambda kv: st.mean(kv[1]))))
    print(f"lent total {lent:.0f} s, invers total {invers:.0f} s (toate masinile, toate seed-urile)")
    print(f"cea mai dura aterizare fara ejectare: {land_max:.1f} m/s")

    print("\n--- LANTUL")
    tot_f = 0
    for k in sorted(set(lip_v) | set(flights)):
        vs = lip_v.get(k, [])
        fl = flights.get(k, [])
        tot_f += len(fl)
        air = [f[1] for f in fl]
        dist = [f[3] for f in fl]
        beyond = sum(1 for d in dist if d > 48.0)
        print(f"  muchia {k}: treceri {len(vs)}, v med {st.median(vs) if vs else -1:.1f} "
              f"[p10 {pct(vs, 0.1):.1f}, min {min(vs) if vs else -1:.1f}] m/s | zboruri {len(fl)}, "
              f"airtime med {st.median(air) if air else -1:.2f} [min {min(air) if air else -1:.2f}, "
              f"max {max(air) if air else -1:.2f}] s | aterizare med {st.median(dist) if dist else -1:.0f} m, "
              f"max {max(dist) if dist else -1:.0f} m, dincolo de bloc {beyond}")
    by_car = {}
    for k, fl in flights.items():
        for name, air, v0, d in fl:
            by_car.setdefault(name, []).append(air)
    print("  airtime median pe masina: " + ", ".join(
        f"{n} {st.median(a):.2f}" for n, a in sorted(by_car.items(), key=lambda kv: st.median(kv[1]))))
    ej_chain = [e for e in ejects if e[3] == "lant"]
    rs_chain = [r for r in resps if r[3] == "lant"]
    bl_chain = [b for b in blocks if b[4] == "lant"]
    print(f"  incidente in lant: {len(ej_chain)} ejectari, {len(rs_chain)} repuneri, {len(bl_chain)} [blocaj] "
          f"in {tot_f} zboruri")
    print(f"  zboruri in afara lantului: {len(out_flights)}" + (
        "  " + "; ".join(f"{n} r{r} f{fr:.3f} {a:.2f}s" for n, r, fr, a in out_flights[:12]) if out_flights else ""))

    print("\n--- SCURTATURA (aceleasi porti: 12 m inaintea furcii -> 20 m dupa reintalnire)")
    for r, name in ((0, "ocol"), (1, "serpentine")):
        ts = passes[r]
        n = len(ts) + pass_resp[r] + pass_unfin[r]
        print(f"  ruta {r} ({name}): {n} treceri, curate {len(ts)}, repuse {pass_resp[r]}, "
              f"neterminate {pass_unfin[r]} | timp med {st.median(ts) if ts else -1:.2f} s, "
              f"p10 {pct(ts, 0.1):.2f}, min {min(ts) if ts else -1:.2f}, p90 {pct(ts, 0.9):.2f}")
    if passes[0] and passes[1]:
        print(f"  castig median (ocol - serpentine): {st.median(passes[0]) - st.median(passes[1]):+.2f} s; "
              f"cea mai buna vs cea mai buna: {min(passes[0]) - min(passes[1]):+.2f} s")
    n1 = len(passes[1]) + pass_resp[1] + pass_unfin[1]
    rs_serp = [r for r in resps if r[3] == "serpentine"]
    bl_serp = [b for b in blocks if b[4] == "serpentine"]
    ej_serp = [e for e in ejects if e[3] == "serpentine"]
    if n1:
        print(f"  pe serpentine: repuneri {len(rs_serp)} ({100.0 * len(rs_serp) / n1:.1f}% din treceri), "
              f"[blocaj] {len(bl_serp)} ({100.0 * len(bl_serp) / n1:.1f}%), ejectari {len(ej_serp)}")
    for e in ej_serp:
        print(f"    ejectare {e[0]} t={e[1]:.0f} {e[2]} {e[4]} {e[5]:.1f} la ({e[6][0]:.0f}, {e[6][1]:.0f})")
    for b in bl_serp:
        print(f"    [blocaj] {b[0]} t={b[1]:.0f} {b[2]} la ({b[6][0]:.0f}, {b[6][1]:.0f}) atinge {b[5]}")

    print("\n--- REST")
    for zn in ("terasa/furca", "ocol", "strada de jos/chei", "faleza", "urcare", "coama"):
        r_ = [r for r in resps if r[3] == zn]
        b_ = [b for b in blocks if b[4] == zn]
        e_ = [e for e in ejects if e[3] == zn]
        if r_ or b_ or e_:
            print(f"  {zn}: repuneri {len(r_)}, [blocaj] {len(b_)}, ejectari {len(e_)}")
            for b in b_[:6]:
                print(f"    [blocaj] {b[0]} t={b[1]:.0f} {b[2]} f{b[3]:.3f} la ({b[6][0]:.0f}, {b[6][1]:.0f}) "
                      f"atinge {b[5]}")
            for e in e_[:6]:
                print(f"    ejectare {e[0]} t={e[1]:.0f} {e[2]} {e[4]} {e[5]:.1f} la ({e[6][0]:.0f}, {e[6][1]:.0f})")
    print(f"  TOTAL: repuneri {len(resps)}, [blocaj] {len(blocks)}, ejectari {len(ejects)}")
    print("\n--- felii (v_med medie, % lent mediu, pereti total)")
    for k in sorted(buckets):
        v, sl, w = buckets[k]
        print(f"  {k}  {st.mean(v):5.1f} m/s  {st.mean(sl):5.1f}% lent  {w:3d} pereti")


if __name__ == "__main__":
    main()
