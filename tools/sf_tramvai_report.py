#!/usr/bin/env python3
"""Agrega JSON-urile ProbeCarrara rulate pe strada tramvaiului SF (sonda 1c,
tools/SondaSfTramvai*.tscn) intr-un tabel normal / sabotaj / faza.

  python tools/sf_tramvai_report.py <dir_base> <eticheta>=<dir> [<eticheta>=<dir> ...]

<dir_base> = rularile `--config=base` (aceeasi strada, tramvaiul scos): din
ele vine timpul de referinta pe bucati de 10 m, pentru pierderea pe intalnire
(functiile din tools/carrara_sonda_report.py). Distributii pe seed-uri (memoria
proberace-nedeterminism), nu o rulare.

INTALNIRE (definitia ProbeCarrara): tramvaiul vizibil, pe acelasi drum, in fata
masinii la 0-60 m; se inchide cand masina e cu 8 m in fata centrului lui. Partea
depasirii = semnul (lat masina - lat tramvai) la apropierea minima.
PIERDEREA = timpul real pe [intrare, iesire + 60 m] minus suma medianelor de
baza pentru aceeasi masina pe aceleasi bucati (zgomot ~ +-0,3 s; martorul e
pierderea pe intalnirile FARA contact).
"""
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from carrara_sonda_report import baseline, load, med, window_loss  # noqa: E402

NEAR_M = 30.0       # [blocaj]/repunere atribuibila: tramvaiul la < 30 m ...
CONTACT_S = 8.0     # ... sau contact cu el in ultimele 8 s


def attr(rec, d=NEAR_M, s=CONTACT_S):
    t = any(str(x).startswith("CAMION") for x in rec.get("touching", []))
    return t or rec.get("truck_d", 1e9) <= d or rec.get("since_contact", 1e9) <= s


def pct(vs, q):
    vs = sorted(vs)
    return vs[int(q * (len(vs) - 1))] if vs else float("nan")


def seeds_line(vals):
    return " ".join("%d" % v for v in vals)


def report(label, runs, base, L):
    n = len(runs)
    print("\n##### %s: %d seed-uri x %.0f s, scena %s" % (
        label, n, runs[0]["seconds"], os.path.basename(runs[0]["scene"])))
    bl = [len(r["blocaj"]) for r in runs]
    bla = [sum(1 for b in r["blocaj"] if attr(b)) for r in runs]
    rs = [len(r["respawns"]) for r in runs]
    rsa = [sum(1 for b in r["respawns"] if attr(b, 25.0, 12.0)) for r in runs]
    ej = [len(r.get("ejects", [])) for r in runs]
    ct = [len(r["contacts"]) for r in runs]
    print("  [blocaj] total        %4d   pe seed: %s" % (sum(bl), seeds_line(bl)))
    print("  [blocaj] la tramvai   %4d   pe seed: %s" % (sum(bla), seeds_line(bla)))
    print("  repuneri total        %4d   pe seed: %s" % (sum(rs), seeds_line(rs)))
    print("  repuneri la tramvai   %4d" % sum(rsa))
    print("  ejectari sofer        %4d   pe seed: %s" % (sum(ej), seeds_line(ej)))
    print("  contacte cu tramvaiul %4d   pe seed: %s" % (sum(ct), seeds_line(ct)))
    enc = []
    for r in runs:
        for e in r["encounters"]:
            if e["t_out"] < 0:
                continue
            e = dict(e)
            e["run"] = r
            enc.append(e)
    hit = [e for e in enc if e["contact"]]
    print("  intalniri             %4d   (%.1f / seed), cu contact %d = %.1f%%" % (
        len(enc), len(enc) / max(n, 1), len(hit), 100.0 * len(hit) / max(len(enc), 1)))
    left = sum(1 for e in enc if e["lat_min"] < e["tlat_min"])
    print("  depasiri pe STANGA %d, pe DREAPTA %d (%.0f%% stanga)" % (
        left, len(enc) - left, 100.0 * left / max(len(enc), 1)))
    slow = [e for e in enc if e["v_min"] < 10.0]
    print("  intalniri in care masina a coborat sub 10 m/s (coada in spatele lui): %d (%.1f%%)" % (
        len(slow), 100.0 * len(slow) / max(len(enc), 1)))
    lap1 = [e for e in enc if e["t_in"] < 20.0]
    print("  intalniri in turul 1 (t_in < 20 s): %d, cu contact %d" % (
        len(lap1), sum(1 for e in lap1 if e["contact"])))
    losses = {"toate": [], "cu contact": [], "fara contact": []}
    for e in enc:
        ls = window_loss(e["run"], e["car"], e["u_in"], e["u_out"] + 60.0, base, L)
        if ls is None:
            continue
        losses["toate"].append(ls)
        losses["cu contact" if e["contact"] else "fara contact"].append(ls)
    for k, v in losses.items():
        if v:
            print("  pierdere / intalnire %-12s n=%4d  mediana %5.2f s  p90 %5.2f  max %5.2f  >2 s: %d" % (
                k, len(v), med(v), pct(v, 0.9), max(v), sum(1 for x in v if x > 2.0)))
    allc = [c for r in runs for c in r["contacts"]]
    if allc:
        rear = sum(1 for c in allc if c["rel_z"] > 3.5)
        side = sum(1 for c in allc if abs(c["rel_z"]) <= 3.5)
        print("  contacte: din spate %d, din lateral %d, alte %d; v la intrare mediana %.1f, v minima mediana %.1f m/s" % (
            rear, side, len(allc) - rear - side, med([c["v_in"] for c in allc]),
            med([c["v_min"] for c in allc])))
    lent = [sum(c["slow_s"] for c in r["cars"]) for r in runs]
    print("  lent (<4 m/s) total pe seed: mediana %.1f s, max %.1f s" % (med(lent), max(lent)))
    for r in runs:
        for b in r["blocaj"]:
            print("    [blocaj] seed %d t=%.1f %s zona=%s v=%.1f lat=%.1f tramvai@%.0fm contact_acum %.1fs atinge %s" % (
                r["seed"], b["t"], b["name"], b["zone"], b["v"], b["lat"], b["truck_d"],
                b["since_contact"], b["touching"]))
        for b in r.get("ejects", []):
            print("    [ejectare] seed %d t=%.1f %s %s dv=%.1f zona=%s tramvai@%.0fm" % (
                r["seed"], b["t"], b["name"], b["cause"], b["value"], b["zone"], b["truck_d"]))
    return {"blocaj": sum(bl), "blocaj_t": sum(bla), "resp": sum(rs), "ej": sum(ej),
            "contacts": sum(ct), "enc": len(enc)}


def main():
    base_runs = load(sys.argv[1])
    base, L = baseline(base_runs)
    b_bl = [len(r["blocaj"]) for r in base_runs]
    b_rs = [len(r["respawns"]) for r in base_runs]
    print("##### BAZA (fara tramvai): %d seed-uri; [blocaj] %d (%s), repuneri %d, ejectari %d" % (
        len(base_runs), sum(b_bl), seeds_line(b_bl), sum(b_rs),
        sum(len(r.get("ejects", [])) for r in base_runs)))
    for arg in sys.argv[2:]:
        label, d = arg.split("=", 1)
        report(label, load(d), base, L)


if __name__ == "__main__":
    sys.exit(main())
