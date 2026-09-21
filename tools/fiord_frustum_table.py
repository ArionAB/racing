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
  Ce vede in plus, informativ: B2/C/F2 (lateral), H si F-iesire (0,69-0,74,
  dupa portalul de vest — vezi mai jos de ce conteaza).

OCLUZIA DE PROPRIUL RELIEF (a patra axa, adaugata 21 sep 2026 seara):
  frustumul nu stie de teren. Un punct e „intreg" numai daca, pe langa
  azimut si verticala, segmentul camera -> varf SI segmentul camera ->
  (varf - 0,5 * inaltimea vizibila a insulei, adica 72 m peste apa) trec la
  >= 2 m DEASUPRA terenului real, pe tot drumul pana la baza insulei
  (centru - raza; insula insasi nu se numara ocluzie). Terenul vine din
  GRILA `tools/data/fiord_varf_grid/grid.csv` (+ `baked.csv`), care e INPUT
  al gardii, nu se calculeaza aici: ground_y traieste in TrackSideSampler.
  Se regenereaza dupa ORICE schimbare de teren pe Track16 (traseu, rape,
  masive, sea_level_offset), altfel garda masoara relieful vechi:
      godot --headless --path . res://tools/SvFiordVarfGrid.tscn -- --track=16 \
            --out=tools/data/fiord_varf_grid
  Daca grila LIPSESTE sau nu se potriveste cu scena (prea putine puncte
  coapte fata de punctele de control), garda PICA cu mesaj, nu trece in
  tacere (memoria `garda-fara-linie-de-baza-iese-zero`).
  Contractul pe F1 e „>= 60% in cadru si >= 40% intreg SI neocluzat".

  STAREA CINSTITA (21 sep 2026): garda e ROSIE pe F1 si ramane asa, cu
  motiv. F1 (0,60-0,67) din brief e, pe pista MONTATA, coridorul tunelului:
  `SemaforTunel` sta la frac 0,612 si `tunnel_length` = 169 m, deci tunelul
  e 0,612-0,69, iar drumul trece la 8-70 m de centrul lui `MasivTunel`
  (raza 90, cota 70) pe 0,62-0,66. „Creasta de pe dreapta" care ascunde
  insula la 0,63-0,64 (teren 53 m la 50 m lateral, camera la 51; raman
  32 m din 72 vizibili la 0,63 si 1 m la 0,64) este chiar muntele
  tunelului. Tesirea ei la <= camera - 5 m pe 50 m lateral pe 0,62-0,65 ar
  insemna sa scoatem masivul de deasupra tunelului — o schimbare de
  gimmick, nu de teren, si cu portalul GLB + `CameraZone` montate, din
  0,62-0,65 oricum nu se va vedea nimic (esti sub munte). De aceea NU s-a
  aplicat nicio taiere. Cifrele cu ocluzia (grila din 21 sep): F1 in
  cadru 9/13, intreg geometric 6/13, dar NEOCLUZAT doar 1/13 (0,623);
  0,629-0,651 ocluzat de MasivTunel (degajare -0,1 / -4,8 / -6,6 / -3,4 /
  +1,0 m); 0,656-0,684 in cadru si liber (degajare 5-9 m), dar taiat de
  marginea de sus (perete/varf trunchiat, 33-42 de grade dreapta) — si tot
  in coridorul tunelului. DUPA portalul de vest (F-iesire 0,69-0,74) insula
  e la 194-228 m, dar la 87-138 de grade dreapta: drumul se intoarce spre
  G/H si golful ramane in spate. Deci „fiordul intreg in fata la iesirea
  din tunel" NU exista pe traseul actual pentru NICIUN punct de dupa
  portal; insula e castigata doar ca perete de pe chei si de pe prima
  jumatate a cornisei (A, B1). Decizia ramane a dezvoltatorului: fie
  coborarea F se redeseneaza spre golf (SV) — singura care da poza din
  brief —, fie contractul pe F1 se scoate si se accepta ca varful e al
  cornisei, nu al coborarii.

Rulare (nu are nevoie de Godot):
    python tools/fiord_frustum_table.py [--tscn scenes/tracks/Track16.tscn]
                                        [--peak X,Y,Z --radius R] [--quiet]
`--peak/--radius` suprascriu nodul din scena, ca sa iterezi pozitia inainte
de a edita .tscn-ul si generatorul (`tools/gen_fiordland_route.py`).
"""
import argparse
import math
import os
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
GRID_DIR = "tools/data/fiord_varf_grid"
LOS_CLEAR_M = 2.0       # degajarea minima a liniei de vedere peste teren
SEA_Y_DEFAULT = -1.96   # doar pentru inaltimea vizibila a insulei (varf - mare)
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
    "F-iesire": (0.69, 0.74),
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


class Grid:
    """ground_y pe grila de 10 m, scrisa de SvFiordVarfGrid; biliniar."""

    def __init__(self, path):
        with open(path, encoding="utf-8") as fh:
            hdr = fh.readline().strip("# \n").split()
            self.meta = {k: float(v) for k, v in (h.split("=") for h in hdr)}
            self.rows = [[float(v) for v in ln.split(",")] for ln in fh if ln.strip()]
        self.x0, self.z0, self.cell = self.meta["x0"], self.meta["z0"], self.meta["cell"]
        self.sea_y = self.meta.get("sea_y", SEA_Y_DEFAULT)

    def y(self, x, z):
        fx = (x - self.x0) / self.cell
        fz = (z - self.z0) / self.cell
        i = max(0, min(len(self.rows[0]) - 2, int(fx)))
        j = max(0, min(len(self.rows) - 2, int(fz)))
        tx, tz = fx - i, fz - j
        r0, r1 = self.rows[j], self.rows[j + 1]
        return (r0[i] * (1 - tx) + r0[i + 1] * tx) * (1 - tz) \
            + (r1[i] * (1 - tx) + r1[i + 1] * tx) * tz


def load_grid(grid_dir, n_control):
    """Grila + verificarea ca e a scenei curente. Lipsa/nepotrivire = PICA."""
    gpath = os.path.join(grid_dir, "grid.csv")
    bpath = os.path.join(grid_dir, "baked.csv")
    if not (os.path.isfile(gpath) and os.path.isfile(bpath)):
        print("PICA: lipseste grila de teren %s (grid.csv + baked.csv). Regenereaza:\n"
              "  godot --headless --path . res://tools/SvFiordVarfGrid.tscn -- --track=16 --out=%s"
              % (grid_dir, grid_dir))
        return None
    grid = Grid(gpath)
    with open(bpath, encoding="utf-8") as fh:
        baked = [tuple(float(v) for v in ln.split(",")) for ln in fh if ln.strip()]
    if len(baked) < 5 * n_control:
        print("PICA: baked.csv are %d puncte pentru %d puncte de control — grila e a altei "
              "piste sau a altui traseu; regenereaza." % (len(baked), n_control))
        return None
    return grid, baked


def los_clear(grid, cam, target, stop_dist, step=4.0):
    """Cea mai mica degajare (m) a segmentului cam->target peste teren,
    esantionat pe orizontala pana la stop_dist (baza insulei)."""
    dx, dz = target[0] - cam[0], target[2] - cam[2]
    d = math.hypot(dx, dz)
    if d <= 0.0:
        return 1e9
    worst = 1e9
    s_ = 6.0
    while s_ < min(stop_dist, d):
        t = s_ / d
        y_line = cam[1] + (target[1] - cam[1]) * t
        worst = min(worst, y_line - grid.y(cam[0] + dx * t, cam[2] + dz * t))
        s_ += step
    return worst


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
    ap.add_argument("--grid", default=GRID_DIR,
                    help="directorul cu grid.csv + baked.csv (SvFiordVarfGrid)")
    args = ap.parse_args()

    pts, peak, radius = read_scene(args.tscn)
    loaded = load_grid(args.grid, len(pts))
    if loaded is None:
        return 1
    grid, _baked = loaded
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
        # Ocluzia: doua segmente, varful si jumatatea inaltimii vizibile.
        vis_h = peak[1] - grid.sea_y
        stop = d_cam - radius
        clear_top = los_clear(grid, cam, (peak[0], peak[1], peak[2]), stop)
        clear_mid = los_clear(grid, cam, (peak[0], peak[1] - 0.5 * vis_h, peak[2]), stop)
        occluded = min(clear_top, clear_mid) < LOS_CLEAR_M
        rows.append({"f": fracs[i], "d": d_cam, "db": d_base, "oc": over_cam,
                     "ce": ceiling_road, "mg": margin, "y": p[1], "el": elev, "yaw": yaw,
                     "occ": occluded, "clr": min(clear_top, clear_mid)})

    if not args.quiet:
        print("\n  frac   d_cam  d_baza  varf>cam  plafon  marja   elev  azimut  y_drum  degaj   nota")
        for r in rows:
            tag = ""
            if r["occ"]:
                tag = "OCLUZAT de teren (degajare %.1f m)" % r["clr"]
            if r["d"] > FAR_PLANE:
                tag = "FAR_PLANE"
            elif r["d"] > FOG_END_DRY:
                tag = "dincolo de fog_end"
            elif r["yaw"] > HALF_HFOV:
                tag = "in afara cadrului (azimut)"
            elif r["mg"] < 0.0:
                tag = "taiat sus"
            print("  %.3f  %6.1f  %6.1f  %7.1f  %6.1f  %6.1f  %5.1f  %6.1f  %6.1f  %5.1f   %s"
                  % (r["f"], r["d"], r["db"], r["oc"], r["ce"], r["mg"], r["el"],
                     r["yaw"], r["y"], min(r["clr"], 99.9), tag))

    failed = []
    print("\nVerdict per segment (in cadru = azimut <= %.0f si d <= fog_end; intreg = in cadru, "
          "varful sub marginea de sus SI linia de vedere la >= %.0f m peste teren; "
          "perete = taiat sus sau nevazut):" % (HALF_HFOV, LOS_CLEAR_M))
    for name, (f0, f1) in SEGMENTS.items():
        sel = [r for r in rows if f0 <= r["f"] < f1]
        if not sel:
            continue
        k = len(sel)
        in_frame = [r for r in sel if r["yaw"] <= HALF_HFOV and r["d"] <= FOG_END_DRY]
        whole_geom = [r for r in in_frame if r["mg"] >= 0.0]
        whole = [r for r in whole_geom if not r["occ"]]
        occl = [r for r in in_frame if r["occ"]]
        wall = [r for r in sel if r["mg"] < 0.0 or r["d"] > FOG_END_DRY or r["yaw"] > HALF_HFOV]
        line = ("  %-8s  d %3.0f-%3.0f m  azimut %3.0f-%3.0f  varf>cam %3.0f-%3.0f m  elev %+.1f..%+.1f"
                "  marja %+.0f..%+.0f m  | in cadru %d/%d  intreg %d/%d (geometric %d, ocluzat %d)  perete %d/%d"
                % (name, min(r["d"] for r in sel), max(r["d"] for r in sel),
                   min(r["yaw"] for r in sel), max(r["yaw"] for r in sel),
                   min(r["oc"] for r in sel), max(r["oc"] for r in sel),
                   min(r["el"] for r in sel), max(r["el"] for r in sel),
                   min(r["mg"] for r in sel), max(r["mg"] for r in sel),
                   len(in_frame), k, len(whole), k, len(whole_geom), len(occl), len(wall), k))
        if name in CONTRACT:
            need_frame, need_whole = CONTRACT[name]
            why = []
            if len(in_frame) < need_frame * k - 1e-9:
                why.append("in cadru %d/%d < %.0f%%" % (len(in_frame), k, need_frame * 100))
            if need_whole is not None and len(whole) < need_whole * k - 1e-9:
                why.append("intreg+neocluzat %d/%d < %.0f%% (ocluzat de teren: %d)"
                           % (len(whole), k, need_whole * 100, len(occl)))
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
