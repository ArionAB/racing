#!/usr/bin/env python3
"""Agrega loturile ProbeRace --sf de pe San Francisco (tools/sf_route_race.sh):
lantul, scurtatura fata de ocol, restul turului; [blocaj], repuneri, ejectari, lent / invers.

    python tools/sf_route_report.py <dir_cu_seedN.log> [<alt_dir> ...]

Zonele se iau din POZITIA evenimentului (harta: x est, y nord = -z Godot), dupa geometria din
tools/gen_sf_route.py: lantul pe x = 0 de la prima muchie (y 0) la terasa (y 264), furca la
y 300, serpentinele intre furca si strada de jos (y 454), ocolul la vest de ele.

Bucla B200 (implicita, podul rosu): zonele noi sunt podul (coridorul cu doua sensuri, x 234..506,
y 214..243), capul de pod (S-urile si virajele de la baza), balonul de pe malul celalalt, PRIMUL
VIRAJ dupa start (R30, de pe pod pe strada tramvaiului), urcarea (strada tramvaiului 1, x 144,
spre S), coltul de sus / coama, strada de intors spre pod (x 150). `SF_LAYOUT=vechi` pentru
loturile buclei vechi. Linia `--- PODUL` agrega observatorul podului (probe_sf_watch.gd).
"""
import glob
import os
import re
import statistics as st
import sys


LAYOUT = os.environ.get("SF_LAYOUT", "b200")


def zone(x, y):
    if LAYOUT == "b200":
        z = zone_b200(x, y)
        if z:
            return z
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


def zone_b200(x, y):
    """Zonele noi ale buclei B200 (None = zonele comune cu bucla veche: lant, serpentine...)."""
    # pontonul (pasul 6): cheiul de nord x 40..120 si apa de langa el (inainte de „spre pod”)
    if 28 <= x <= 136 and 446 <= y <= 500:
        return "ponton"
    if 230 <= x <= 510 and 205 <= y <= 252:
        return "pod"
    if x > 510 and 150 <= y <= 300:
        return "balon"
    if 165 <= x < 230 and 205 <= y <= 252:
        return "capul de pod"
    if 120 <= x < 185 and 165 <= y < 215:
        return "primul viraj"
    if 120 <= x <= 170 and -100 <= y < 165:
        return "urcare"
    if 95 <= x <= 175 and -150 <= y < -100:
        return "colt de sus"
    if 30 <= x < 120 and -150 <= y <= -110:
        return "coama"
    if x >= 105 and 240 < y <= 470:
        return "spre pod"
    return None


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
    bed_passes, wall_passes = [], []
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
        for m in re.finditer(r"^    \[sf poarta\] (.+?)\s+ruta=(\d) (-?[\d.]+)s( REPUSA)?( STRAT)?( FATADA)?$", txt, re.M):
            r = int(m.group(2))
            t = float(m.group(3))
            if r == 1 and not m.group(4) and t >= 0 and m.group(5):
                bed_passes.append(t)
            if r == 1 and not m.group(4) and t >= 0 and m.group(6):
                wall_passes.append(t)
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
    if passes[0]:
        for nm_, arr_ in (("blocul solid (STRAT)", bed_passes), ("o fatada", wall_passes)):
            if arr_:
                print(f"  serpentine cu {nm_} atins(a), fara repunere: {len(arr_)} treceri, timp med "
                      f"{st.median(arr_):.2f} s -> fata de ocol {st.median(passes[0]) - st.median(arr_):+.2f} s "
                      f"(pozitiv = tot castiga)")
            else:
                print(f"  serpentine cu {nm_} atins(a): 0 treceri")
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
    for zn in ("terasa/furca", "ocol", "strada de jos/chei", "ponton", "faleza", "urcare", "coama", "pod", "balon",
               "capul de pod", "primul viraj", "colt de sus", "spre pod", "rest"):
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
    print("\n--- PODUL (observatorul probe_sf_watch.gd, treceri prin coridorul cu doua sensuri)")
    pod = {"n": 0, "block": 0, "truck": 0, "cushion": 0, "cross": 0, "near": 0, "slow": 0, "resp": 0,
           "eject": 0, "narrow": [], "dur": [], "incomplete": 0, "side": {}}
    cross_rows, head_rows, summ = [], [], []
    for p in logs:
        txt = open(p, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"^    \[sf pod trecere\] (.+?) side=([+-]\d) t=([\d.]+) (-?[\d.]+)s v_in=([\d.]+) "
                             r"v_min=([\d.]+) bariera=(\d+) camion=(\d+) atenuator=(\d+) peste=(\d+) "
                             r"ingust=([\d.]+) camion_aproape=(\d) coada=(\d) complet=(\d) repus=(\d) ejectat=(\d)",
                             txt, re.M):
            pod["n"] += 1
            pod["block"] += int(m.group(7)) > 0
            pod["truck"] += int(m.group(8)) > 0
            pod["cushion"] += int(m.group(9)) > 0
            pod["cross"] += int(m.group(10))
            pod["narrow"].append(float(m.group(11)))
            pod["near"] += int(m.group(12))
            pod["slow"] += int(m.group(13))
            pod["incomplete"] += m.group(14) == "0"
            pod["resp"] += int(m.group(15))
            pod["eject"] += int(m.group(16))
            pod["side"][m.group(2)] = pod["side"].get(m.group(2), 0) + 1
            if m.group(14) == "1":
                pod["dur"].append(float(m.group(4)))
        for m in re.finditer(r"^    \[sf pod peste\] (.*)$", txt, re.M):
            cross_rows.append(os.path.basename(p) + " " + m.group(1))
        for m in re.finditer(r"^    \[sf frontal\] (.*coridor=(\d).*)$", txt, re.M):
            head_rows.append((m.group(2) == "1", os.path.basename(p) + " " + m.group(1)))
        for m in re.finditer(r"^=== SF pod: treceri.*contacte fara trecere \(bariera/camion/atenuator\) (\d+)/(\d+)/(\d+)",
                             txt, re.M):
            summ.append(tuple(int(g) for g in m.groups()))
    n = max(pod["n"], 1)
    if pod["n"]:
        print(f"  treceri {pod['n']} (pe sens: {pod['side']}), terminate {len(pod['dur'])}, durata med "
              f"{st.median(pod['dur']) if pod['dur'] else -1:.1f} s; repuse {pod['resp']}, ejectate {pod['eject']}")
        print(f"  cu contact: bariera {pod['block']} ({100.0 * pod['block'] / n:.1f}%), camion {pod['truck']} "
              f"({100.0 * pod['truck'] / n:.1f}%), atenuator {pod['cushion']} ({100.0 * pod['cushion'] / n:.1f}%)")
        print(f"  TRECERI PESTE DESPARTITOR: {pod['cross']}; frontale in coridor: "
              f"{sum(1 for c, _ in head_rows if c)} (oriunde {len(head_rows)})")
        print(f"  banda ingusta (< 10 m): {100.0 * st.mean(pod['narrow']):.0f}% din timpul pe pod; intalniri cu "
              f"camionul {pod['near']}, coada (sub 10 m/s) {pod['slow']} ({100.0 * pod['slow'] / max(pod['near'], 1):.1f}%)")
        if summ:
            print(f"  contacte in afara trecerilor (bariera/camion/atenuator): "
                  f"{sum(a for a, _, _ in summ)}/{sum(b for _, b, _ in summ)}/{sum(c for _, _, c in summ)}")
        for row in cross_rows[:10]:
            print("    peste: " + row)
        for c, row in head_rows[:12]:
            print("    frontal: " + row)

    # --- PASUL 6: pontonul si masinile parcate (probe_sf_watch.gd, _report_p6)
    pont_pass = pont_falls = 0
    fall_rows = []
    pk = {"n": 0, "hits": 0, "road": 0.0, "land": 0.0, "land_near": 0, "ej_near": 0}
    pk_rows = []
    pk_seeds = 0
    for p in logs:
        txt = open(p, encoding="utf-8", errors="replace").read()
        m = re.search(r"^=== SF ponton: treceri=(\d+) caderi=(\d+)", txt, re.M)
        if m:
            pont_pass += int(m.group(1))
            pont_falls += int(m.group(2))
        for m in re.finditer(r"^    \[sf cadere\] (.*)$", txt, re.M):
            fall_rows.append(os.path.basename(p) + " " + m.group(1))
        m = re.search(r"^=== SF parcate: piese=(\d+) urnite=(\d+) pe_carosabil=([\d.]+)s in_zona_de_aterizare=([\d.]+)s "
                      r"aterizari_langa_resturi=(\d+) ejectari_langa_resturi=(\d+)", txt, re.M)
        if m:
            pk_seeds += 1
            pk["n"] = int(m.group(1))
            pk["hits"] += int(m.group(2))
            pk["road"] += float(m.group(3))
            pk["land"] += float(m.group(4))
            pk["land_near"] += int(m.group(5))
            pk["ej_near"] += int(m.group(6))
        for m in re.finditer(r"^    \[sf parcata\] t=\s*([\d.]+)s (\S+) (.+?)\s+v=([\d.]+)$", txt, re.M):
            pk_rows.append((m.group(2), m.group(3).strip(), float(m.group(4))))
    if pont_pass or pk_seeds:
        print("\n--- PASUL 6")
    if pont_pass:
        print(f"  PONTON: {pont_pass} treceri, {pont_falls} caderi in golf ({100.0 * pont_falls / pont_pass:.2f}% "
              f"din treceri; {pont_falls / max(lap_n, 1):.3f} pe tur-masina, {lap_n} ture)")
        for row in fall_rows[:12]:
            print("    cadere: " + row)
    if pk_seeds:
        by_tag = {}
        by_car = {}
        for tag, car, v in pk_rows:
            by_tag[tag] = by_tag.get(tag, 0) + 1
            by_car[car] = by_car.get(car, 0) + 1
        print(f"  MASINI PARCATE: {pk['n']} piese; urnite {pk['hits']} in {pk_seeds} seed-uri "
              f"({pk['hits'] / max(lap_n, 1):.3f} pe tur-masina, {pk['hits'] / pk_seeds:.1f} pe cursa)")
        print(f"    pe strazi: {by_tag}; cine: {by_car}")
        vs = [v for _, _, v in pk_rows]
        if vs:
            print(f"    viteza celui care loveste: med {st.median(vs):.1f} m/s, max {max(vs):.1f}")
        print(f"    resturile pe carosabil: {pk['road']:.1f} s-piesa, din care {pk['land']:.1f} s in zona de "
              f"aterizare (primii 45 m dupa muchie); aterizari la < 8 m de o piesa urnita {pk['land_near']}, "
              f"ejectari langa una {pk['ej_near']}")

    # --- PASUL 8b / VALUL 2: casele, stalpii fara coliziune, mobilierul mic (probe_sf_watch.gd)
    case_f = case_b = 0
    v3c = {"pictate": 0, "placa": 0, "magazii": 0}
    v3_seeds = 0
    v3_present = set()
    case_rows = []
    pole_n = {}
    pole_rows = []
    mob = {"n": 0, "hits": 0, "road": 0.0, "land": 0.0, "lost": 0, "seeds": 0}
    mob_rows = []
    for p in logs:
        txt = open(p, encoding="utf-8", errors="replace").read()
        m = re.search(r"^=== SF case: contacte rand din fata (\d+), rand din spate (\d+)", txt, re.M)
        if m:
            case_f += int(m.group(1))
            case_b += int(m.group(2))
        m = re.search(r"^=== SF val3: contacte case pictate (\d+), placa turnanta (\d+), magazii (\d+); "
                      r"corpuri in scena: (.*)$", txt, re.M)
        if m:
            v3_seeds += 1
            v3c["pictate"] += int(m.group(1))
            v3c["placa"] += int(m.group(2))
            v3c["magazii"] += int(m.group(3))
            v3_present |= {x for x in m.group(4).split(",") if x}
        for m in re.finditer(r"^    \[sf casa\] (.*)$", txt, re.M):
            case_rows.append(os.path.basename(p) + " " + m.group(1))
        for m in re.finditer(r"^=== SF stalpi (\S+): (\d+) stalpi", txt, re.M):
            pole_n[m.group(1)] = int(m.group(2))
        for m in re.finditer(r"^    \[sf stalp\] t=\s*([\d.]+)s (\S+) #(\d+) (.+?)\s+v=([\d.]+) (\S+) poz=\((.*)\)$",
                             txt, re.M):
            pole_rows.append((m.group(2), int(m.group(3)), float(m.group(5)), m.group(6), m.group(7),
                              os.path.basename(p), m.group(4).strip()))
        m = re.search(r"^=== SF mobilier: piese=(\d+) urnite=(\d+) pe_carosabil=([\d.]+)s "
                      r"in_zona_de_aterizare=([\d.]+)s pierdute=(\d+)", txt, re.M)
        if m:
            mob["seeds"] += 1
            mob["n"] = int(m.group(1))
            mob["hits"] += int(m.group(2))
            mob["road"] += float(m.group(3))
            mob["land"] += float(m.group(4))
            mob["lost"] += int(m.group(5))
        for m in re.finditer(r"^    \[sf mobilier\] t=\s*([\d.]+)s (\S+) (.+?)\s+v=([\d.]+)$", txt, re.M):
            mob_rows.append((m.group(2), m.group(3).strip(), float(m.group(4))))
    print("\n--- CASELE SI VALUL 2")
    print(f"  CASE: contacte cu randul din fata {case_f}, cu randul din spate {case_b}")
    if v3_seeds:
        print(f"  VALUL 3 ({v3_seeds} seed-uri cu contor; corpuri in scena: {', '.join(sorted(v3_present)) or '-'}): "
              f"contacte case pictate {v3c['pictate']}, placa turnanta (ghereta + vagon) {v3c['placa']}, "
              f"magazii {v3c['magazii']}")
    else:
        print("  VALUL 3: fara contor in jurnale (lot dinaintea valului 3) — contactele cu corpurile noi sunt NEMASURATE")
    for row in case_rows[:10]:
        print("    casa: " + row)
    for fam in sorted(pole_n):
        rows = [r for r in pole_rows if r[0] == fam]
        vs = sorted(r[2] for r in rows)
        per_pole = {}
        for r in rows:
            per_pole[(r[1], r[4])] = per_pole.get((r[1], r[4]), 0) + 1
        air = sum(1 for r in rows if r[3] == "zbor")
        print(f"  STALPI {fam}: {pole_n[fam]} fara coliziune; treceri PRIN volum {len(rows)} "
              f"({len(rows) / max(lap_n, 1):.4f} pe tur-masina), in zbor {air}"
              + (f", v med {st.median(vs):.1f} max {max(vs):.1f} m/s" if vs else ""))
        for (k, pz), c in sorted(per_pole.items(), key=lambda kv: -kv[1])[:8]:
            vk = sorted(r[2] for r in rows if r[1] == k)
            print(f"    #{k} la ({pz}): {c} treceri, v med {st.median(vk):.1f} max {max(vk):.1f}")
    if mob["seeds"]:
        by_tag = {}
        for tag, car, v in mob_rows:
            by_tag[tag] = by_tag.get(tag, 0) + 1
        print(f"  MOBILIER MIC: {mob['n']} piese; urnite {mob['hits']} in {mob['seeds']} seed-uri "
              f"({mob['hits'] / mob['seeds']:.1f} pe cursa), pe zone {by_tag}; pe carosabil {mob['road']:.1f} "
              f"s-piesa, din care {mob['land']:.1f} s in zona de aterizare; pierdute (cazute din lume) {mob['lost']}")
        vs = [v for _, _, v in mob_rows]
        if vs:
            print(f"    viteza celui care loveste: med {st.median(vs):.1f} m/s, max {max(vs):.1f}")

    print("\n--- felii (v_med medie, % lent mediu, pereti total)")
    for k in sorted(buckets):
        v, sl, w = buckets[k]
        print(f"  {k}  {st.mean(v):5.1f} m/s  {st.mean(sl):5.1f}% lent  {w:3d} pereti")


if __name__ == "__main__":
    main()
