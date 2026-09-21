#!/usr/bin/env python3
"""Garda de VIZIBILITATE a lui Mitre Peak de pe traseul Fiordland (Track16).

Citeste curba din `scenes/tracks/Track16.tscn` (cele 180 de puncte de control,
tripleti in/out/pos) si nodul `Peaks/MitrePeak` (transform + radius_m), apoi
verifica, punct cu punct, ce vede CAMERA DE JOC din varf — nu ce ar vedea un
ochi ideal si nu ce vede poza de masurare `Snapshot --driver` (aceea are ochiul
la 3,2 m si priveste aproape orizontal; pentru compozitie se foloseste
`--gamecam`). Parametrii sunt cei din `scenes/race/chase_camera.gd` (memoria
`verifica-cu-parametrii-lui`): 10 m sus, 12,5 m in spate, FOV 68 vertical,
tinta la 5 m in fata si 0,4 m sus -> inclinata 28,7 grade in jos, unghi tinut
CONSTANT si la viteza (`_pitch_tan`). Consecinte, ambele masurate aici:

  * VERTICAL: marginea de sus a cadrului e la +5,25 grade peste orizontala
    (+9,3 la FOV-ul de viteza maxima). La distanta d vezi in sus cel mult
    0,092*d peste CAMERA, adica `10 + 0,092*d` peste cota drumului. Cerul
    ocupa 7,7% din inaltimea ecranului. Un varf se vede INTREG numai daca
    intra in banda asta: la 200 m, cel mult 18 m peste camera; la 250 m, 23 m.
    „>= 30 m peste camera" SI „intreg" cer d >= 326 m, adica dincolo de
    fog_end (320) — cele doua nu pot fi cerute impreuna sub 250 m.
  * ORIZONTAL: jumatatea de cadru e ~50 grade la 16:9 (56 la 20:9). Un obiect
    la peste 50 de grade de directia de mers NU E IN CADRU, oricat de aproape
    si oricat de inalt. Brief-ul §2.0 verificase doar verticala.

De ce exista garda: dezvoltatorul a condus pista si nu a vazut varful DELOC.
Masurat pe starea din 21 sep 2026 (varf la 60 m, centru la (-311, -65)):
pe cornisa B varful e la 60-100 de grade STANGA de directia de mers (in
spate-lateral: B urca spre NV, golful e in SV), la 220-305 m, cu 24-50 m
peste camera — deci in afara cadrului si, unde ar intra, taiat de marginea de
sus; pe coborarea F e la 332-490 m — dincolo de `fog_end` si, pe prima
jumatate, dincolo de `ChaseCamera.FAR_PLANE` (380): nu se randeaza deloc —
si la 40-75 de grade dreapta (F coboara spre S/SE, golful e in SV). Domul real
mai e si RETEZAT de sapatura rapei 0 (latime 220 m): cota maxima masurata cu
`SvFiordVarf` e 51,7 m, nu 60 (centrul sta chiar pe muchia sapaturii).
Ceata si FAR_PLANE NU sunt parghii aici (brief §2.0: „fiordul se stramteaza
sau varful creste").

Contract (cod de iesire 1 daca pica) — rescris la 21 sep 2026 pe ce e
REALIZABIL cu camera de joc, dupa decizia dezvoltatorului „varful-insula in
golf" (nodul la (-250, 70, -200), raza 44, `island = true`):
  * A  (0,00-0,05): >= 50% din puncte cu varful IN CADRU pe azimut (|azimut|
    <= 50 grade, d <= fog_end) — ca PERETE (taiat de marginea de sus).
  * B1 (0,05-0,13): >= 90% din puncte in cadru (perete/flanc, la 120-250 m).
  * F1 (0,60-0,67): >= 60% in cadru si >= 40% INTREG (sub marginea de sus).
  * Baza varfului (centru - radius_m) la >= 40 m de ORICE punct al drumului.
  Ce NU se mai cere: „intreg de pe B2 si pe tot F" (B2, C si F2 privesc in
  lungul cornisei / spre G-H, golful le e lateral — nicio pozitie nu le
  serveste pe toate, verificat exhaustiv) si „>= 30 m peste camera si intreg
  sub 250 m" (imposibil geometric, vezi mai sus).
  Garda PICA pe starea veche (commit e882cc62: varf la (-311, 60, -65) —
  A 0/10 in cadru, B1 0/14, F1 0/13) si TRECE pe cea noua (A 6/10, B1
  14/14, F1 9/13 in cadru / 6/13 intreg). Verificare: `git show
  e882cc62:scenes/tracks/Track16.tscn > /tmp/old.tscn` si `--tscn /tmp/old.tscn`.
  Ce vede in plus, informativ: B2/C/F2 (lateral) si H.

Rulare (nu are nevoie de Godot):
    python tools/fiord_frustum_table.py [--tscn scenes/tracks/Track16.tscn]
                                        [--peak X,Y,Z --radius R] [--quiet]
`--peak/--radius` suprascriu nodul din scena, ca sa iterezi pozitia inainte
de a edita .tscn-ul si generatorul (`tools/gen_fiordland_route.py`).
"""
import argparse
import math
import re
import sys

CAM_UP = 10.0
CAM_BACK = 12.5
LOOK_AHEAD = 5.0
LOOK_HEIGHT = 0.4
FOV_V = 68.0
FOG_END_DRY = 320.0
FAR_PLANE = 380.0
HALF_HFOV = 50.0  # grade, 16:9 (20:9 -> 56)

MIN_BASE_CLEAR = 40.0
# (segment, fractia minima IN CADRU, fractia minima INTREG)
CONTRACT = {"A": (0.50, None), "B1": (0.90, None), "F1": (0.60, 0.40)}

PITCH_DEG = math.degrees(math.atan((CAM_UP - LOOK_HEIGHT) / (CAM_BACK + LOOK_AHEAD)))
TOP_EDGE_DEG = FOV_V * 0.5 - PITCH_DEG          # +5,25
FRUSTUM_SLOPE = math.tan(math.radians(TOP_EDGE_DEG))  # 0,092

SEGMENTS = {
    "A":  (0.00, 0.05),
    "B1": (0.05, 0.13),
    "B2": (0.13, 0.21),
    "C":  (0.21, 0.27),
    "F1": (0.60, 0.67),
    "F2": (0.67, 0.74),
    "H":  (0.86, 1.00),
}


def read_scene(path):
    with open(path, encoding="utf-8") as fh:
        txt = fh.read()
    m = re.search(r'"points":\s*PackedVector3Array\(([^)]*)\)', txt)
    if not m:
        sys.exit("nu gasesc PackedVector3Array cu punctele curbei in %s" % path)
    nums = [float(x) for x in m.group(1).split(",") if x.strip()]
    if len(nums) % 9 != 0:
        sys.exit("curba nu e in tripleti in/out/pos (%d numere)" % len(nums))
    pts = [(nums[i + 6], nums[i + 7], nums[i + 8]) for i in range(0, len(nums), 9)]
    pm = re.search(
        r'\[node name="MitrePeak"[^\]]*\]\s*'
        r'transform = Transform3D\(([^)]*)\)(?:\s*[a-z_]+ = [^\n]*)*?'
        r'\s*radius_m = ([0-9.]+)', txt)
    if not pm:
        sys.exit("nu gasesc nodul Peaks/MitrePeak cu transform + radius_m")
    tr = [float(x) for x in pm.group(1).split(",")]
    peak = (tr[9], tr[10], tr[11])  # originea e ultimul triplet (baza e pe randuri)
    radius = float(pm.group(2))
    return pts, peak, radius


def fracs_of(pts):
    """Fractia pe lungimea de coarda (bucla inchisa) la fiecare punct."""
    n = len(pts)
    seg = []
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        seg.append(math.hypot(b[0] - a[0], b[2] - a[2]))
    total = sum(seg)
    out, acc = [], 0.0
    for i in range(n):
        out.append(acc / total)
        acc += seg[i]
    return out, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tscn", default="scenes/tracks/Track16.tscn")
    ap.add_argument("--peak", help="x,y,z (simulare, suprascrie scena)")
    ap.add_argument("--radius", type=float, help="radius_m (simulare)")
    ap.add_argument("--quiet", action="store_true", help="doar verdictele")
    args = ap.parse_args()

    pts, peak, radius = read_scene(args.tscn)
    if args.peak:
        peak = tuple(float(x) for x in args.peak.split(","))
    if args.radius is not None:
        radius = args.radius
    fracs, total = fracs_of(pts)
    n = len(pts)
    print("Track16: %d puncte, %.0f m; MitrePeak centru=(%.2f, %.2f, %.2f) raza=%.0f"
          % (n, total, peak[0], peak[1], peak[2], radius))
    print("camera: +%.0f m, %.1f m in spate, inclinata %.1f grade; marginea de sus "
          "la %+.2f grade -> vezi cel mult %.3f*d peste camera (%.0f + %.3f*d peste drum); "
          "jumatate de cadru %.0f grade"
          % (CAM_UP, CAM_BACK, PITCH_DEG, TOP_EDGE_DEG, FRUSTUM_SLOPE, CAM_UP,
             FRUSTUM_SLOPE, HALF_HFOV))

    rows = []
    min_base = (1e9, None)
    for i in range(n):
        p = pts[i]
        q = pts[(i - 1) % n]
        tx, tz = p[0] - q[0], p[2] - q[2]
        tl = math.hypot(tx, tz) or 1.0
        tx, tz = tx / tl, tz / tl
        cam = (p[0] - tx * CAM_BACK, p[1] + CAM_UP, p[2] - tz * CAM_BACK)
        dx, dz = peak[0] - cam[0], peak[2] - cam[2]
        d_cam = math.hypot(dx, dz)
        d_road = math.hypot(peak[0] - p[0], peak[2] - p[2])
        d_base = d_road - radius
        over_cam = peak[1] - cam[1]
        ceiling_road = CAM_UP + FRUSTUM_SLOPE * d_cam   # peste cota drumului
        margin = ceiling_road - (over_cam + CAM_UP)      # > 0 = varful sub margine
        elev = math.degrees(math.atan2(over_cam, d_cam))
        yaw = math.degrees(math.acos(max(-1.0, min(1.0, (dx * tx + dz * tz) / d_cam))))
        if d_base < min_base[0]:
            min_base = (d_base, i)
        rows.append({"f": fracs[i], "d": d_cam, "db": d_base, "oc": over_cam,
                     "ce": ceiling_road, "mg": margin, "y": p[1], "el": elev, "yaw": yaw})

    if not args.quiet:
        print("\n  frac   d_cam  d_baza  varf>cam  plafon  marja   elev  azimut  y_drum   nota")
        for r in rows:
            tag = ""
            if r["d"] > FAR_PLANE:
                tag = "FAR_PLANE"
            elif r["d"] > FOG_END_DRY:
                tag = "dincolo de fog_end"
            elif r["yaw"] > HALF_HFOV:
                tag = "in afara cadrului (azimut)"
            elif r["mg"] < 0.0:
                tag = "taiat sus"
            print("  %.3f  %6.1f  %6.1f  %7.1f  %6.1f  %6.1f  %5.1f  %6.1f  %6.1f   %s"
                  % (r["f"], r["d"], r["db"], r["oc"], r["ce"], r["mg"], r["el"],
                     r["yaw"], r["y"], tag))

    failed = []
    print("\nVerdict per segment (in cadru = azimut <= %.0f si d <= fog_end; intreg = in "
          "cadru si varful sub marginea de sus; perete = taiat sus sau nevazut):" % HALF_HFOV)
    for name, (f0, f1) in SEGMENTS.items():
        sel = [r for r in rows if f0 <= r["f"] < f1]
        if not sel:
            continue
        k = len(sel)
        in_frame = [r for r in sel if r["yaw"] <= HALF_HFOV and r["d"] <= FOG_END_DRY]
        whole = [r for r in in_frame if r["mg"] >= 0.0]
        wall = [r for r in sel if r["mg"] < 0.0 or r["d"] > FOG_END_DRY or r["yaw"] > HALF_HFOV]
        line = ("  %-2s  d %3.0f-%3.0f m  azimut %3.0f-%3.0f  varf>cam %3.0f-%3.0f m  elev %+.1f..%+.1f"
                "  marja %+.0f..%+.0f m  | in cadru %d/%d  intreg %d/%d  perete %d/%d"
                % (name, min(r["d"] for r in sel), max(r["d"] for r in sel),
                   min(r["yaw"] for r in sel), max(r["yaw"] for r in sel),
                   min(r["oc"] for r in sel), max(r["oc"] for r in sel),
                   min(r["el"] for r in sel), max(r["el"] for r in sel),
                   min(r["mg"] for r in sel), max(r["mg"] for r in sel),
                   len(in_frame), k, len(whole), k, len(wall), k))
        if name in CONTRACT:
            need_frame, need_whole = CONTRACT[name]
            why = []
            if len(in_frame) < need_frame * k - 1e-9:
                why.append("in cadru %d/%d < %.0f%%" % (len(in_frame), k, need_frame * 100))
            if need_whole is not None and len(whole) < need_whole * k - 1e-9:
                why.append("intreg %d/%d < %.0f%%" % (len(whole), k, need_whole * 100))
            if name == "A" and len(wall) < k:
                why.append("varful intra intreg de pe chei (nu mai e perete)")
            print(line + ("  OK" if not why else "  PICA: " + ", ".join(why)))
            if why:
                failed.append(name)
        else:
            print(line + "  (informativ)")

    db, bi = min_base
    print("  baza varfului: cea mai apropiata sosea la %.1f m (frac %.3f)  %s"
          % (db, fracs[bi], "OK" if db >= MIN_BASE_CLEAR else "PICA: < %.0f m" % MIN_BASE_CLEAR))
    if db < MIN_BASE_CLEAR:
        failed.append("baza")

    if failed:
        print("\nPICA: %s" % ", ".join(failed))
        return 1
    print("\nTRECE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
