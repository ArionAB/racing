# Rezumatul unei serii ProbeRace pe Carrara: python3 tools/carrara_race_sum.py <outdir>
import glob
import os
import re
import sys

d = sys.argv[1]
tot_resp = tot_ej = tot_blk = 0
rows = []
for f in sorted(glob.glob(os.path.join(d, "s*.log")), key=lambda p: int(re.findall(r"s(\d+)\.log", p)[0])):
    t = open(f, encoding="utf-8", errors="replace").read()
    seed = int(re.findall(r"s(\d+)\.log", f)[0])
    m = re.search(r"repuneri totale: (\d+)", t)
    e = re.search(r"ejectari: (\d+)", t)
    resp = int(m.group(1)) if m else -1
    ej = int(e.group(1)) if e else -1
    blk = re.findall(r"\[blocaj\][^\n]*", t)
    rsp = re.findall(r"\[(?:repunere|ejectare)\][^\n]*", t)
    tur = re.search(r"TUR global: (\d+) ture, minim ([\d.]+) s, mediu ([\d.]+) s", t)
    rows.append((seed, resp, ej, blk, rsp, tur.groups() if tur else None))
    tot_resp += max(resp, 0)
    tot_ej += max(ej, 0)
    tot_blk += len(blk)
for seed, resp, ej, blk, rsp, tur in rows:
    print(f"seed {seed:2d}: repuneri {resp}  ejectari {ej}  [blocaj] {len(blk)}  tur {tur}")
    for b in blk:
        print("      ", b[:230])
    for r in rsp:
        print("      ", r[:200])
print(f"TOTAL {len(rows)} seed-uri: repuneri {tot_resp}, ejectari {tot_ej}, [blocaj] {tot_blk}")
