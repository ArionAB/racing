#!/usr/bin/env python3
"""Tabelul de frustum al pistei Ha Long (Track22): ce se vede DE UNDE, pe patru axe.

Briefingul (§2.1) il cerea "inainte de decor" si nu s-a facut niciodata. Lipsa
lui a costat exact ce prezice memoria `reperul-se-vede-pe-patru-axe`: verdictul
la volan a fost **"belvedere nu am stiut unde este"**, desi garda de azimut din
`gen_halong_route.py` raporta turnurile de fundal "in cadru pe 7/10 puncte".
Amandoua sunt adevarate, si de-aia tabelul asta exista: garda veche masura DOUA
axe (azimut si distanta), pe repere date ca puncte **2D** -- fara cota, deci
fara verticala, si fara nicio notiune de ocluzie. Un reper poate fi perfect "in
cadru" pe azimut si totusi sa nu se vada: taiat de marginea de sus a cadrului,
sau ascuns de propriul relief al insulei.

A patra axa e cea care conteaza aici. Belvederea nu trebuie sa arate un OBIECT
(briful e explicit: "dezvaluirea pistei nu e un obiect, e adancimea"), ci sa
fie un LOC din care privesti IN JOS peste golf. Asta se masoara ca unghi de
cadere spre apa, nu ca prezenta a turnurilor in cadru.

  python tools/halong_frustum_table.py
  python tools/halong_frustum_table.py --sabotaj   # coboara drumul la cota 0

Parametrii sunt ai CAMEREI DE JOC din `scenes/race/chase_camera.gd` (memoria
`verifica-cu-parametrii-lui`), nu ai unui ochi ideal: 10 m sus, 12,5 m in spate,
FOV 68 vertical, tinta la 5 m in fata si 0,4 m sus. Consecinta masurata mai jos:
marginea de sus a cadrului e la numai +5,25 grade peste orizontala, deci de pe
un drum la +26 m un turn de 60 m la 250 m distanta NU intra intreg in cadru --
si tocmai de aia dezvaluirea trebuie sa fie in jos, nu in sus.
"""

import math
import re
import sys

CAM_UP = 10.0
CAM_BACK = 12.5
LOOK_AHEAD = 5.0
LOOK_HEIGHT = 0.4
FOV_V = 68.0
HALF_HFOV = 50.0        # grade, 16:9
FOG_END = 340.0         # tema "halong" din track.gd
FAR_PLANE = 380.0
SEA_Y = -5.99           # custom_sea_level_offset din Track22.tscn

PITCH_DEG = math.degrees(math.atan((CAM_UP - LOOK_HEIGHT) / (CAM_BACK + LOOK_AHEAD)))
TOP_EDGE_DEG = FOV_V * 0.5 - PITCH_DEG
BOTTOM_EDGE_DEG = -(FOV_V * 0.5 + PITCH_DEG)

SABOTAJ = "--sabotaj" in sys.argv
TSCN = "scenes/tracks/Track22.tscn"

# Reperele, acum in 3D. Cota conteaza: fara ea verticala nu se poate masura, si
# exact de-aia garda veche nu putea sa vada defectul.
#
# ATENTIE LA SEMNUL LUI Z. Reperele din `gen_halong_route.py` sunt in
# coordonatele SCHITEI (x, y), iar schita se transforma in scena prin
# `(p[0], cota, -p[1])` -- linia 565 a generatorului: **z-ul se inverseaza**.
# Prima versiune a tabelului a copiat cifrele din schita fara sa inverseze si a
# raportat 0/14, 0/12, 0/12 "in cadru", la distante de 400-640 m in loc de
# 238-291. Trei zerouri perfecte dintr-o data si distante care nu seamana cu
# cele ale gardii vechi = sonda masoara in alta parte, nu defect descoperit
# (memoria `multimesh-masuratoare-moarta`). Aici reperele sunt deja in
# coordonate de SCENA, deci se compara direct cu Curve3D_main.
TURNURI = (360.0, 40.0, 170.0)      # sirul de fundal (est), varfuri la ~40 m
GROTA = (-174.0, 10.0, 253.0)       # gura grotei
SAT = (-366.0, 2.0, -280.0)         # satul plutitor (pe apa)


def read_curve(path):
    with open(path, encoding="utf-8") as fh:
        txt = fh.read()
    m = re.search(r'\[sub_resource type="Curve3D" id="Curve3D_main"\][^\[]*?'
                  r'"points":\s*PackedVector3Array\(([^)]*)\)', txt)
    if not m:
        sys.exit("nu gasesc Curve3D_main in %s" % path)
    nums = [float(x) for x in m.group(1).split(",") if x.strip()]
    if len(nums) % 9:
        sys.exit("curba nu e in tripleti in/out/pos")
    return [(nums[i + 6], nums[i + 7], nums[i + 8]) for i in range(0, len(nums), 9)]


def read_peaks(path):
    """Varfurile (centru 3D + raza), pentru ocluzie si pentru cota insulei."""
    with open(path, encoding="utf-8") as fh:
        txt = fh.read()
    out = []
    for m in re.finditer(r'\[node name="([^"]+)" type="Marker3D" parent="Peaks"\]\s*'
                         r'transform = Transform3D\(([^)]*)\)'
                         r'(?:\s*[a-z_]+ = [^\n]*)*?\s*radius_m = ([0-9.]+)', txt):
        tr = [float(x) for x in m.group(2).split(",")]
        out.append((m.group(1), (tr[9], tr[10], tr[11]), float(m.group(3))))
    return out


def fracs(pts):
    n = len(pts)
    seg = [math.hypot(pts[(i + 1) % n][0] - pts[i][0],
                      pts[(i + 1) % n][2] - pts[i][2]) for i in range(n)]
    total = sum(seg)
    out, acc = [], 0.0
    for i in range(n):
        out.append(acc / total)
        acc += seg[i]
    return out, total


def cam_at(pts, i):
    """Camera de joc la punctul i: 10 m peste drum, 12,5 m in spate pe tangenta."""
    n = len(pts)
    p = pts[i]
    nxt = pts[(i + 1) % n]
    dx, dz = nxt[0] - p[0], nxt[2] - p[2]
    d = math.hypot(dx, dz) or 1.0
    fwd = (dx / d, dz / d)
    y = p[1] if not SABOTAJ else 0.0
    return (p[0] - fwd[0] * CAM_BACK, y + CAM_UP, p[2] - fwd[1] * CAM_BACK), fwd


def axes(cam, fwd, target):
    """Cele patru axe, pentru un reper: distanta, azimut, verticala (ocluzia separat)."""
    dx, dz = target[0] - cam[0], target[2] - cam[2]
    dist = math.hypot(dx, dz)
    az = math.degrees(math.atan2(dx * fwd[1] - dz * fwd[0], dx * fwd[0] + dz * fwd[1]))
    elev = math.degrees(math.atan2(target[1] - cam[1], max(dist, 0.01)))
    return dist, az, elev


def occluded(cam, target, peaks, step=8.0):
    """Linia de vedere trece peste varfuri? Conul fiecarui varf, esantionat."""
    dx, dy, dz = target[0] - cam[0], target[1] - cam[1], target[2] - cam[2]
    d = math.hypot(dx, dz)
    if d <= 0:
        return None
    s = step
    while s < d:
        t = s / d
        x, y, z = cam[0] + dx * t, cam[1] + dy * t, cam[2] + dz * t
        for name, c, r in peaks:
            rr = math.hypot(x - c[0], z - c[2])
            if rr < r:
                # con: cota scade liniar de la varf la baza razei
                top = c[1] * (1.0 - rr / r)
                if y < top:
                    return name
        s += step
    return None


pts = read_curve(TSCN)
peaks = read_peaks(TSCN)
fr, total = fracs(pts)
n = len(pts)

print("pista Ha Long (Track22): %d puncte de control, %.0f m" % (n, total))
print("camera de joc: %.1f m sus, %.1f m spate, FOV %.0f -> inclinata %.1f grade in jos"
      % (CAM_UP, CAM_BACK, FOV_V, PITCH_DEG))
print("  marginea de SUS a cadrului:  %+.2f grade" % TOP_EDGE_DEG)
print("  marginea de JOS a cadrului:  %+.2f grade" % BOTTOM_EDGE_DEG)
print("  => un reper se vede INTREG doar intre aceste doua unghiuri")
if SABOTAJ:
    print("  [SABOTAJ] drumul coborat la cota 0: belvederea nu mai e belvedere")

fails = []


def window(f0, f1):
    return [i for i in range(n) if f0 <= fr[i] <= f1]


# --- 1. Belvederea: se priveste IN JOS peste apa? ----------------------------
#
# Axa care decide. Un punct inalt de pe care NU vezi apa in jos nu e belvedere,
# e doar un drum pe deal -- si asa a fost trait: "nu am stiut unde este".
# Masor unghiul de cadere de la camera la suprafata apei din fata, pe direcţia
# de mers, si pe cate puncte din fereastra apa intra in cadru.
print("\n=== 1. BELVEDEREA: privirea IN JOS peste golf (0.42-0.52) ===")
print("  %-6s %-7s %-9s %-9s %s" % ("frac", "cota", "cadere", "apa_in_jos", "ce se vede"))
belv = window(0.42, 0.52)
caderi = []
for i in belv:
    (cam, fwd) = cam_at(pts, i)
    # cat de jos e apa, privind inainte: unghiul spre punctul de apa de la 150 m
    ahead = (cam[0] + fwd[0] * 150.0, SEA_Y, cam[2] + fwd[1] * 150.0)
    _, _, elev_apa = axes(cam, fwd, ahead)
    # apa se vede in jos doar daca unghiul e peste marginea de JOS a cadrului
    vede_apa = elev_apa > BOTTOM_EDGE_DEG
    caderi.append((fr[i], pts[i][1], elev_apa, vede_apa))
    if i in belv[:3] or i in belv[-3:]:
        print("  %-6.3f %-7.1f %-9.1f %-9s %s"
              % (fr[i], pts[i][1], elev_apa, "da" if vede_apa else "NU",
                 "apa in jos" if vede_apa else "doar inainte"))
cota_max = max(c[1] for c in caderi)
cadere_max = min(c[2] for c in caderi)   # cel mai NEGATIV = cea mai mare cadere
k_apa = sum(1 for c in caderi if c[3])
print("  cota maxima pe fereastra: %.1f m" % cota_max)
print("  cea mai mare cadere spre apa: %.1f grade" % cadere_max)
print("  apa vizibila in jos pe %d/%d puncte" % (k_apa, len(caderi)))
# Contractul: o belvedere cere COTA (>= 20 m peste mare) si CADERE vizibila.
if cota_max - SEA_Y < 20.0:
    fails.append("belvederea e la numai %.1f m peste mare: nu e un punct inalt"
                 % (cota_max - SEA_Y))
if k_apa < 0.6 * len(caderi):
    fails.append("apa se vede in jos pe doar %d/%d puncte din fereastra de "
                 "belvedere: nu se priveste peste golf" % (k_apa, len(caderi)))

# --- 2. Reperele pe patru axe ------------------------------------------------
# Varful care CONTINE fiecare reper, exceptat de la ocluzie (vezi nota de mai
# jos, la filtrul de ocluzie).
own = {"turnul cu grota, de pe pontoane": "TurnGrota"}
print("\n=== 2. REPERELE PE PATRU AXE (nu doar azimut) ===")
for label, (f0, f1), target, thr in (
        ("turnurile de fundal, de pe belvedere", (0.44, 0.52), TURNURI, 0.60),
        ("turnul cu grota, de pe pontoane", (0.15, 0.22), GROTA, 0.80),
        ("satul plutitor, de pe coasta", (0.90, 0.97), SAT, 0.80)):
    idx = window(f0, f1)
    in_cadru = 0
    intreg = 0
    occ = {}
    dmin, dmax = 1e9, 0.0
    for i in idx:
        (cam, fwd) = cam_at(pts, i)
        dist, az, elev = axes(cam, fwd, target)
        dmin, dmax = min(dmin, dist), max(dmax, dist)
        vizibil = abs(az) <= HALF_HFOV and dist <= FOG_END
        if vizibil:
            o = occluded(cam, target, peaks)
            # Turnul care CONTINE reperul nu il ocludeaza: gura unei grote e in
            # stanca ei, deci linia de vedere intra prin conul propriu prin
            # construcţie. Prima versiune raporta "grota ascunsa de TurnGrota
            # 12/12" -- o tautologie, nu un defect (memoria
            # `garda-circulara-propria-functie`: o sonda care isi masoara
            # propriul subiect da acelasi raspuns oricum e lumea).
            if o and o != own.get(label):
                occ[o] = occ.get(o, 0) + 1
                vizibil = False
        if vizibil:
            in_cadru += 1
            if BOTTOM_EDGE_DEG <= elev <= TOP_EDGE_DEG:
                intreg += 1
    print("  %s:" % label)
    print("    in cadru %d/%d (%.0f%%, prag %.0f%%), intreg %d/%d, distanta %.0f-%.0f m"
          % (in_cadru, len(idx), 100 * in_cadru / len(idx), 100 * thr,
             intreg, len(idx), dmin, dmax))
    if occ:
        print("    ascuns de relief: %s"
              % ", ".join("%s x%d" % (k, v) for k, v in sorted(occ.items())))
    if in_cadru / len(idx) < thr:
        fails.append("%s: in cadru pe doar %.0f%% (prag %.0f%%)"
                     % (label, 100 * in_cadru / len(idx), 100 * thr))

print()
if fails:
    print("PICAT:")
    for f in fails:
        print("  - %s" % f)
    sys.exit(1)
print("TOATE CONTRACTELE DE FRUSTUM TREC")
