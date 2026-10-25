#!/usr/bin/env python3
"""Agrega JSON-urile ProbeCarrara (16 seed-uri) in tabele cu/fara.

  python tools/carrara_sonda_report.py trucks <dir_base> <dir_trucks> [--terrain]
  python tools/carrara_sonda_report.py exc    <dir_base> <dir_exc>

Distributii pe seed-uri (memoria proberace-nedeterminism), nu o rulare.
Pierderea pe intalnire = timpul real pe fereastra [intrare, iesire + 60 m]
minus suma medianelor de baza (aceeasi masina, aceleasi bucati de 10 m, fara
hazard). Zgomotul acestei estimari ~ +-0.3 s: se raporteaza si mediana
pierderii pe ferestre FARA contact, ca martor.
"""
import glob
import json
import math
import os
import statistics as st
import sys
from collections import defaultdict

BUCKET = 10.0
BASE_K = 40


def load(d):
    runs = []
    for f in sorted(glob.glob(os.path.join(d, "s*.json")),
                    key=lambda p: int(os.path.basename(p)[1:-5])):
        runs.append(json.load(open(f)))
    return runs


def med(xs):
    return st.median(xs) if xs else float("nan")


def fmt(x, n=2):
    return "%.*f" % (n, x) if isinstance(x, float) and not math.isnan(x) else "-"


def tb_of(car):
    tb = {}
    for k, t in car["cross"]:
        tb.setdefault(k, t)
    return tb


def baseline(runs):
    """med[car_name][bucket_in_lap] = durata mediana a bucket-ului."""
    acc = defaultdict(lambda: defaultdict(list))
    L = runs[0]["len"]
    for r in runs:
        for c in r["cars"]:
            tb = tb_of(c)
            ks = sorted(tb)
            for k in ks:
                if k + 1 in tb:
                    u = (k - BASE_K) * BUCKET
                    if u < 0:
                        continue
                    b = int((u % L) // BUCKET)
                    acc[c["name"]][b].append(tb[k + 1] - tb[k])
    return {n: {b: med(v) for b, v in d.items()} for n, d in acc.items()}, L


def window_loss(run, car_idx, u0, u1, base, L):
    c = run["cars"][car_idx]
    tb = tb_of(c)
    k0 = int(math.floor(u0 / BUCKET)) + BASE_K
    k1 = int(math.floor(u1 / BUCKET)) + BASE_K
    if k0 not in tb or k1 not in tb or k1 <= k0:
        return None
    real = tb[k1] - tb[k0]
    exp = 0.0
    bm = base.get(c["name"], {})
    for k in range(k0, k1):
        u = (k - BASE_K) * BUCKET
        b = int((u % L) // BUCKET)
        if b not in bm:
            return None
        exp += bm[b]
    return real - exp


def lap_durations(c):
    laps = c["laps_t"]
    return [b - a for a, b in zip(laps, laps[1:])]


def is_heavy(c):
    return c["mass_factor"] >= 2.0


def is_light(c):
    return c["mass_factor"] <= 1.15


def truck_attr(rec, truck_d=30.0, contact_s=8.0):
    t = any(str(x).startswith("CAMION") for x in rec.get("touching", []))
    return t or rec.get("truck_d", 1e9) <= truck_d or rec.get("since_contact", 1e9) <= contact_s


def per_seed_line(label, vals):
    return "%-34s %s   total %s" % (label, " ".join("%3d" % v for v in vals), sum(vals))


def report_trucks(base_runs, tr_runs, terrain):
    base, L = baseline(base_runs)
    n = len(tr_runs)
    print("##### CAMIOANE: %d seed-uri trucks vs %d base, %.0f s, config=%s" % (
        n, len(base_runs), tr_runs[0]["seconds"], tr_runs[0]["label"] or "-"))
    print("seed:                              " + " ".join("%3d" % r["seed"] for r in tr_runs))
    for lab, runs in (("BASE", base_runs), ("CAMIOANE", tr_runs)):
        print(per_seed_line("[blocaj] total %s" % lab, [len(r["blocaj"]) for r in runs]))
    print(per_seed_line("[blocaj] atribuibile camioanelor", [
        sum(1 for b in r["blocaj"] if truck_attr(b)) for r in tr_runs]))
    for lab, runs in (("BASE", base_runs), ("CAMIOANE", tr_runs)):
        print(per_seed_line("repuneri total %s" % lab, [len(r["respawns"]) for r in runs]))
    print(per_seed_line("repuneri atribuibile camioanelor", [
        sum(1 for b in r["respawns"] if truck_attr(b, 25.0, 3.0)) for r in tr_runs]))
    print(per_seed_line("  din care cadere >3 m (margine)", [
        sum(1 for b in r["respawns"] if truck_attr(b, 25.0, 3.0) and b["drop_m"] > 3.0)
        for r in tr_runs]))
    for lab, runs in (("BASE", base_runs), ("CAMIOANE", tr_runs)):
        print(per_seed_line("ejectari sofer %s" % lab, [len(r.get("ejects", [])) for r in runs]))
    ej = [e for r in tr_runs for e in r.get("ejects", [])]
    if ej:
        near = [e for e in ej if e["truck_d"] <= 25.0]
        print("  ejectari: %d, din care cu camion < 25 m: %d; dv mediana %.1f m/s (prag eject_wall_dv 26)" % (
            len(ej), len(near), med([e["value"] for e in ej])))
        tot_rs = sum(len(r["respawns"]) for r in tr_runs)
        print("  repuneri care sunt ejectari (<3 s): %d din %d" % (
            sum(1 for r in tr_runs for x in r["respawns"] if x.get("eject")), tot_rs))
    for lab, runs in (("BASE", base_runs), ("CAMIOANE", tr_runs)):
        print("lent total (s) %-9s median %s  worst %s   inversare (s) median %s" % (
            lab, fmt(med([sum(c["slow_s"] for c in r["cars"]) for r in runs]), 1),
            fmt(max(sum(c["slow_s"] for c in r["cars"]) for r in runs), 1),
            fmt(med([sum(c["rev_s"] for c in r["cars"]) for r in runs]), 1)))
    # unde sunt blocajele / repunerile
    zc = defaultdict(int)
    for r in tr_runs:
        for b in r["blocaj"]:
            zc[("blocaj", b["zone"], truck_attr(b))] += 1
        for b in r["respawns"]:
            zc[("repunere", b["zone"], truck_attr(b, 25.0, 3.0))] += 1
    zb = defaultdict(int)
    for r in base_runs:
        for b in r["blocaj"]:
            zb[("blocaj", b["zone"], False)] += 1
        for b in r["respawns"]:
            zb[("repunere", b["zone"], False)] += 1
    print("\nUNDE (zona, atribuibil camion?) — CAMIOANE | BASE")
    for key in sorted(set(zc) | set(zb), key=str):
        print("  %-9s %-4s atribuibil=%-5s  %4d | %4d" % (key[0], key[1], key[2],
              zc.get(key, 0), zb.get(key, 0)))
    for r in tr_runs:
        for b in r["blocaj"]:
            if truck_attr(b):
                print("  [blocaj atribuibil] seed %d t=%.1f %s frac=%.3f zona=%s v=%.1f camion@%.0fm atinge %s" % (
                    r["seed"], b["t"], b["name"], b["frac"], b["zone"], b["v"],
                    b["truck_d"], b["touching"]))
    # contacte
    print("\nCONTACTE camion<->masina (evenimente, gol 0.5 s)")
    hp = [sum(1 for c in r["contacts"] if c["zone"] in ("H1", "H2")) for r in tr_runs]
    ts = [sum(1 for c in r["contacts"] if c["zone"] not in ("H1", "H2")) for r in tr_runs]
    print(per_seed_line("  in ac (H1/H2)", hp))
    print(per_seed_line("  pe terase/dreapta", ts))
    byz = defaultdict(int)
    for r in tr_runs:
        for c in r["contacts"]:
            byz[c["zone"]] += 1
    print("  pe zone:", dict(byz))
    allc = [c for r in tr_runs for c in r["contacts"]]
    if allc:
        print("  head-on: %d/%d   frontal(nas) mediana viteza la intrare %.1f m/s, minima in contact %.1f m/s (mediana)" % (
            sum(1 for c in allc if c["head_on"]), len(allc),
            med([c["v_in"] for c in allc]), med([c["v_min"] for c in allc])))
        print("  contacte cu v_min < 5 m/s: %d/%d" % (sum(1 for c in allc if c["v_min"] < 5.0), len(allc)))
    # intalniri
    allenc = []
    for r in tr_runs:
        for e in r["encounters"]:
            if e["t_out"] < 0:
                continue
            e = dict(e)
            e["seed"] = r["seed"]
            e["run"] = r
            allenc.append(e)
    print("\nINTALNIRI (camion < 60 m, vizibil): %d total, %.1f / seed" % (len(allenc), len(allenc) / max(n, 1)))
    ho = [e for e in allenc if e["head_on"]]
    print("  din care head-on la apropierea minima: %d" % len(ho))
    for zlab, zset in (("ac (H1/H2)", ("H1", "H2")), ("terasa/rest", None)):
        sel = [e for e in ho if (e["zone_min"] in zset if zset else e["zone_min"] not in ("H1", "H2"))]
        hit = [e for e in sel if e["contact"]]
        print("  intalniri %-12s: %4d, cu contact %4d = %.0f%%" % (zlab, len(sel), len(hit),
              100.0 * len(hit) / max(len(sel), 1)))
    for z in ("T1", "H1", "T2", "H2", "T3", "RET"):
        sel = [e for e in ho if e["zone_min"] == z]
        if sel:
            hit = [e for e in sel if e["contact"]]
            print("      zona %-3s: %4d intalniri, contact %3d (%.0f%%), lat masina mediana %.2f, lat camion %.2f" % (
                z, len(sel), len(hit), 100.0 * len(hit) / len(sel),
                med([e["lat_min"] for e in sel]), med([e["tlat_min"] for e in sel])))
    # pierderea pe intalnire
    losses = {"all": [], "contact": [], "free": []}
    byclass = {"heavy": [], "light": [], "mid": []}
    for e in ho:
        run = e["run"]
        ci = e["car"]
        ls = window_loss(run, ci, e["u_in"], e["u_out"] + 60.0, base, L)
        if ls is None:
            continue
        losses["all"].append(ls)
        losses["contact" if e["contact"] else "free"].append(ls)
        c = run["cars"][ci]
        byclass["heavy" if is_heavy(c) else "light" if is_light(c) else "mid"].append(ls)
        e["loss"] = ls
    print("\nPIERDEREA PE INTALNIRE (s) = fereastra [intrare, iesire+60 m] fata de mediana de baza")
    for k, v in losses.items():
        if v:
            vs = sorted(v)
            print("  %-8s n=%4d  mediana %6.2f  p90 %6.2f  worst %6.2f  >2 s: %d (%.0f%%)" % (
                k, len(v), med(v), vs[int(0.9 * (len(vs) - 1))], vs[-1],
                sum(1 for x in v if x > 2.0), 100.0 * sum(1 for x in v if x > 2.0) / len(v)))
    for k, v in byclass.items():
        if v:
            print("  clasa %-6s n=%4d  mediana %6.2f  worst %6.2f" % (k, len(v), med(v), max(v)))
    # per zona
    for z in ("T1", "H1", "T2", "H2", "T3", "RET"):
        v = [e["loss"] for e in ho if e.get("loss") is not None and e["zone_min"] == z and e["contact"]]
        if v:
            print("  cu contact, zona %-3s: n=%3d mediana %5.2f worst %5.2f" % (z, len(v), med(v), max(v)))
    # ture
    print("\nTIMP PE TUR (s), mediana pe seed-uri x ture 2+ (prima tura are grila)")
    print("  %-22s %-9s %8s %8s %8s %8s" % ("masina", "clasa", "base", "camioane", "delta", "worst+"))
    names = [c["name"] for c in base_runs[0]["cars"]]
    cls_d = defaultdict(list)
    for ci, nm in enumerate(names):
        bl = [d for r in base_runs for d in lap_durations(r["cars"][ci])]
        tl = [d for r in tr_runs for d in lap_durations(r["cars"][ci])]
        c0 = base_runs[0]["cars"][ci]
        cls = "heavy" if is_heavy(c0) else "light" if is_light(c0) else "mid"
        if bl and tl:
            wb = max(tl) - med(bl)
            print("  %-22s %-9s %8.2f %8.2f %+8.2f %+8.2f" % (nm, cls + "/%.1f" % c0["mass_factor"], med(bl), med(tl), med(tl) - med(bl), wb))
            cls_d[cls].append(med(tl) - med(bl))
    for k, v in cls_d.items():
        print("  clasa %-6s delta mediu pe masini: %+.2f s/tur" % (k, sum(v) / len(v)))
    # contact per masina
    cc = defaultdict(int)
    for r in tr_runs:
        for c in r["contacts"]:
            cc[c["name"]] += 1
    print("\nContacte pe masina (16 seed-uri):", dict(cc))
    # banda in ace
    hn = sum(r["hairpin"]["n"] for r in tr_runs)
    if hn:
        nr = sum(r["hairpin"]["n_right"] for r in tr_runs)
        ni = sum(r["hairpin"]["n_inside"] for r in tr_runs)
        print("\nIN AC cu camion < 60 m: %d tick-uri-masina; pe banda DREAPTA a cursei (lat>0): %.1f%%; pe interiorul geometric al acului: %.1f%%" % (
            hn, 100.0 * nr / hn, 100.0 * ni / hn))
        # pe ac
        for z in ("H1", "H2"):
            sel = [e for e in ho if e["zone_min"] == z]
            if sel:
                right = sum(1 for e in sel if e["lat_min"] > 0.0)
                print("   %s: %d intalniri, masina pe dreapta (lat>0) la apropiere: %.0f%%" % (z, len(sel), 100.0 * right / len(sel)))
    # adevarul hazardului
    print("\nPozitia corpului camionului fata de axa (media pe zone, cumulat):")
    agg = defaultdict(lambda: {"n": 0, "sum": 0.0, "lo": 1e9, "hi": -1e9, "inner": -1e9, "over": -1e9})
    for r in tr_runs:
        for z, s in r["truck_stats"].items():
            a = agg[z]
            a["n"] += s["n"]
            a["sum"] += s["sum"]
            a["lo"] = min(a["lo"], s["lo"])
            a["hi"] = max(a["hi"], s["hi"])
            a["inner"] = max(a["inner"], s["inner"])
            a["over"] = max(a["over"], s["outer_over"])
    for z, a in sorted(agg.items()):
        print("  %-4s n=%6d lat medie %6.2f [%.2f .. %.2f]  margine interioara max %+.2f  iesire peste asfalt max %+.2f" % (
            z, a["n"], a["sum"] / max(a["n"], 1), a["lo"], a["hi"], a["inner"], a["over"]))
    # defazaj intre camioane
    ev = tr_runs[0].get("truck_events", [])
    print("Evenimente camion (seed %d): %s" % (tr_runs[0]["seed"], ev))
    # zero masuratori
    if not allenc:
        print("VERDICT: PROBLEMA (zero intalniri masurate)")
        sys.exit(1)
    print("\nVERDICT-numere: blocaj atribuibil total %d (contract 0); pierdere mediana/intalnire cu contact %s s (contract <= 2); " % (
        sum(1 for r in tr_runs for b in r["blocaj"] if truck_attr(b)), fmt(med(losses["contact"]))))


def report_exc(base_runs, ex_runs):
    base, L = baseline(base_runs)
    n = len(ex_runs)
    print("##### EXCAVATOR: %d seed-uri exc vs %d base, %.0f s" % (n, len(base_runs), ex_runs[0]["seconds"]))
    lo, hi = ex_runs[0]["exc_lat"]
    print("brat lateral [%.2f, %.2f] (+ = dreapta cursei), distanta pe ruta %.1f m, brat coborat %.1f%% din timp" % (
        lo, hi, ex_runs[0]["exc_dist"], 100.0 * ex_runs[0]["exc_block_frac"]))
    print("seed:                              " + " ".join("%3d" % r["seed"] for r in ex_runs))
    for lab, runs in (("BASE", base_runs), ("EXC", ex_runs)):
        print(per_seed_line("[blocaj] total %s" % lab, [len(r["blocaj"]) for r in runs]))
    print(per_seed_line("[blocaj] la brat (exc<30 m)", [
        sum(1 for b in r["blocaj"] if b["exc_d"] <= 30.0 or "EXCAVATOR" in b["touching"]) for r in ex_runs]))
    for lab, runs in (("BASE", base_runs), ("EXC", ex_runs)):
        print(per_seed_line("repuneri %s" % lab, [len(r["respawns"]) for r in runs]))
    print(per_seed_line("repuneri la brat (exc<30 m)", [
        sum(1 for b in r["respawns"] if b["exc_d"] <= 30.0) for r in ex_runs]))
    for lab, runs in (("BASE", base_runs), ("EXC", ex_runs)):
        print("lent total (s) %-5s median %s worst %s" % (
            lab, fmt(med([sum(c["slow_s"] for c in r["cars"]) for r in runs]), 1),
            fmt(max(sum(c["slow_s"] for c in r["cars"]) for r in runs), 1)))
    # treceri
    passes = []
    for r in ex_runs:
        for ev in r["exc_events"]:
            if ev["kind"] == "pass" and ev["win"].get("passed"):
                w = ev["win"]
                w = dict(w)
                w["seed"] = r["seed"]
                w["car"] = ev["car"]
                w["name"] = ev["name"]
                w["run"] = r
                passes.append(w)
    print("\nTRECERI pe langa excavator: %d total (%.1f / masina / seed)" % (len(passes), len(passes) / max(n * 8, 1)))
    classes = defaultdict(list)
    for w in passes:
        inl = (lo - 1.1) <= w["lat_at_pass"] <= (hi + 1.1)
        blk = bool(w["blocking_min_d"] or w["blocking_at_pass"])
        w["inlane"] = inl
        w["blk"] = blk
        classes[("brat JOS" if blk else "brat SUS", "in banda bratului" if inl else "banda libera")].append(w)
        # pierdere
        w["loss"] = window_loss(w["run"], w["car"], w["u_pass"] - 60.0, w["u_pass"] + 60.0, base, L)
    print("%-10s %-18s %5s %8s %8s %8s %8s %8s" % ("brat", "banda", "n", "v_min med", "v_min p10", "loss med", "loss p90", "loss worst"))
    for key in sorted(classes):
        v = classes[key]
        vm = sorted(w["v_min"] for w in v)
        ls = sorted(w["loss"] for w in v if w["loss"] is not None)
        print("%-10s %-18s %5d %9.1f %9.1f %8s %8s %8s" % (
            key[0], key[1], len(v), med(vm), vm[int(0.1 * (len(vm) - 1))],
            fmt(med(ls)), fmt(ls[int(0.9 * (len(ls) - 1))] if ls else float("nan")),
            fmt(ls[-1] if ls else float("nan"))))
    # conectat?
    a = [w["v_min"] for w in classes.get(("brat JOS", "in banda bratului"), [])]
    b = [w["v_min"] for w in classes.get(("brat SUS", "in banda bratului"), [])]
    print("\nCONEXIUNE (coliziunea bratului blocheaza): v_min in banda bratului — brat JOS mediana %s m/s (n=%d) vs brat SUS %s m/s (n=%d)" % (
        fmt(med(a), 1), len(a), fmt(med(b), 1), len(b)))
    # contacte
    cts = [(r["seed"], ev) for r in ex_runs for ev in r["exc_events"] if ev["kind"] == "contact"]
    print("CONTACTE cu excavatorul: %d evenimente; cu brat JOS (blocking) %d; viteza la intrare mediana %s, v_min mediana %s" % (
        len(cts), sum(1 for _, e in cts if e["blocking"]),
        fmt(med([e["v_in"] for _, e in cts]), 1), fmt(med([e["v_min"] for _, e in cts]), 1)))
    print("  contacte cu arm_d<1 (la brat): %d ; la sasiu: %d" % (
        sum(1 for _, e in cts if e["arm_d"] < 1.0), sum(1 for _, e in cts if e["arm_d"] >= 1.0)))
    # opriti sub brat
    stopped = [w for w in passes if w["blk"] and w["v_min"] < 2.0]
    print("OPRITI sub/inaintea bratului (v_min<2 m/s cu brat jos): %d din %d treceri cu brat jos" % (
        len(stopped), sum(1 for w in passes if w["blk"])))
    # schimbari de banda
    sw = 0
    cand = 0
    for w in passes:
        if "lat_30" in w and "lat_10" in w and w["blk"]:
            was_in = (lo - 1.1) <= w["lat_30"] <= (hi + 1.1)
            now_in = (lo - 1.1) <= w["lat_10"] <= (hi + 1.1)
            cand += 1
            if was_in and not now_in:
                sw += 1
    print("Schimbari de banda inaintea bratului (in banda la -30 m, in afara la -10 m, brat jos): %d din %d" % (sw, cand))
    # fractia care alege banda libera
    free = sum(1 for w in passes if not w["inlane"])
    print("Treceri pe banda libera: %d/%d = %.0f%%" % (free, len(passes), 100.0 * free / max(len(passes), 1)))
    if not passes:
        print("VERDICT: PROBLEMA (zero treceri masurate)")
        sys.exit(1)


def main():
    kind = sys.argv[1]
    base = load(sys.argv[2])
    other = load(sys.argv[3])
    if not base or not other:
        print("VERDICT: PROBLEMA (director gol)")
        sys.exit(1)
    if kind == "trucks":
        report_trucks(base, other, "--terrain" in sys.argv)
    else:
        report_exc(base, other)


if __name__ == "__main__":
    main()
