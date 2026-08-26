# Genereaza traseul Chongqing (Track12) din waypoints cu fillet-uri de arc.
#
#   python tools/gen_chongqing_route.py [scenes/tracks/Track12.tscn]
#
# Coordonate de harta (artefactul "Chongqing Recon"): x est, y nord (metri).
# Godot: gx = -x*S (oglindit, vezi godot()), gz = -y*S. Iese: PackedVector3Array + tilts + point_count
# pentru .tscn, plus statistici (lungime, raza minima, panta maxima, pantele
# pe spirala F, fractii per waypoint).
#
# ATENTIE: schela de generare INITIALA (copiata din gen_stromboli_route.py).
# Dupa merge, sursa de adevar e Path3D-ul din Track12.tscn (TrackFromPath):
# rularea scriptului peste scena REGENEREAZA TOT.
#
# Lectii incorporate (platite pe Stromboli/Track09):
#   - puncte de control la PAS UNIFORM (12 m);
#   - virajele > 90 grade sunt esantionate pe arc (fillet), nu un varf;
#   - pista peste pista: etajele spiralei F stau la >= 14 m unul peste altul
#     (ROAD_ABOVE_TOLERANCE 12 m), iar tronsoanele in aer sunt
#     custom_overpass_ranges — terenul urmeaza doar etajul de jos.
import math
import sys

S = 1.0  # scara hartii -> lume (bucla din Recon are deja ~2.0 km)

# (x, y, fillet_r, cota, eticheta) — toate waypoint-urile sunt ancore de cota
# (brief §2 + Recon PTS). Sens: in harta CLOCKWISE (est pe nord, sud pe est),
# adica ANTIORAR in Godot (gz = -y); apa (est + sud) ramane pe DREAPTA.
# Runda 2: G urca 52 -> 65 (brief: 50 -> 65), nu 60 -> 64 ca in runda 1 —
# varful spiralei (F3 c/d/e) a coborat cu 3-6 m ca panta medie pe F sa
# ramana sub 13% si stiva F3 e / F etaj 2 sa ramana >= 14 m (49 - 28 = 21).
WPTS = [
    (-120, 200, 30, 65.0, "A start piata Kuixinglou"),
    (-50,  215, 30, 65.0, "A nod de trafic"),
    (40,   205, 30, 62.0, "B intrare scari"),
    (95,   175, 26, 57.0, "B S1"),
    (60,   135, 26, 50.5, "B S2"),
    (110,  105, 26, 43.5, "B S3 / iesire scari"),
    (160,  85,  28, 39.0, "C aleea hot-pot in"),
    (205,  72,  28, 36.5, "C aleea hot-pot out"),
    (245,  40,  28, 32.0, "D cornisa in"),
    (228,  -25, 30, 24.0, "D cornisa S1"),
    (262,  -85, 30, 16.0, "D cornisa S2"),
    (232,  -145,28, 10.0, "D cornisa out"),
    (185,  -190,28, 5.0,  "E chei in"),
    (90,   -205,30, 4.0,  "E chei / statia telecabinei"),
    (0,    -205,30, 4.0,  "E culoar de ceata"),
    (-60,  -200,30, 5.0,  "E pod in"),
    (-150, -190,28, 6.0,  "E pod out / F etaj 1 in"),
    (-205, -205,28, 8.0,  "F1 a"),
    (-262, -175,28, 14.0, "F1 b"),
    (-275, -115,28, 21.0, "F1 c (sub incrucisarea 2)"),
    (-238, -72, 26, 28.0, "F etaj 2 (sosire telecabina)"),
    (-190, -112,28, 35.0, "F3 a"),
    (-200, -200,28, 42.0, "F3 b (peste etajul 1)"),
    (-255, -235,28, 44.0, "F3 c"),
    (-300, -190,28, 46.5, "F3 d"),
    (-278, -118,28, 49.0, "F3 e (peste etajul 2)"),
    (-250, -40, 30, 52.0, "G Liziba in"),
    (-235, 10,  30, 56.5, "G monorail"),
    (-215, 60,  30, 60.5, "G Liziba out"),
    (-180, 130, 30, 64.0, "A2 pasarela"),
]

# Telecabina: banda in aer peste golf, de la statia de pe chei la etajul 2 al
# nodului. Doar MIJLOCUL (capetele se deriva). Profil de cota tinut SUS:
# terenul nu se sapa sub o banda `elevated`, deci banda trebuie sa stea
# deasupra lui pe tot drumul (masurat: la 22 m peste teren de ~25 m masinile
# se intepeneau in mal). Sosirea ocoleste pe la NORD de apexul etajului 2 si
# intra in tronsonul F2 (-238,-72)->(-190,-112) TANGENT (~25 grade), nu in T:
# o intrare la 90-125 de grade arunca AI-ul in gol si impinge masinile de pe
# drumul principal in rapa (ProbeRace: 35 repuneri). Primul mid sta la ~6 m
# de axa soselei: capatul se deriva ca piciorul PERPENDICULAREI, deci un prim
# mid departat face banda sa plece la 90 de grade (masurat: 5 repuneri la
# intrare); mid-ul 2 e cel care da directia de desprindere.
# Runda 2: capetele unei benzi `elevated` se racordeaza la MARGINEA soselei
# (Track._branch_end), nu la axa — bucata de banda de peste asfalt era un prag
# de 0.5 m (4 repuneri la intrare, seed 2). Primul mid sta deci DINCOLO de
# margine (drumul are 9 m jumatate pe chei): 12 m de axa, la cota drumului;
# ultimul la cota tablierului (30 m), nu sub el.
BRANCH_MID = [(28, -193, 4.0), (-35, -182, 9.5), (-95, -150, 19.0),
              (-145, -112, 30.0), (-175, -60, 32.5), (-238, -52, 31.2),
              (-222, -76, 30.0)]

def v(a, b):
    return (b[0] - a[0], b[1] - a[1])

def norm(a):
    l = math.hypot(*a)
    return (a[0] / l, a[1] / l)

def fillet_loop(wpts):
    n = len(wpts)
    pts = []
    for i in range(n):
        p_prev = wpts[(i - 1) % n][:2]
        p = wpts[i][:2]
        p_next = wpts[(i + 1) % n][:2]
        r = wpts[i][2]
        d1, d2 = norm(v(p, p_prev)), norm(v(p, p_next))
        cosang = max(-1.0, min(1.0, d1[0] * d2[0] + d1[1] * d2[1]))
        ang = math.acos(cosang)
        turn = math.pi - ang
        if turn < math.radians(8):
            pts.append((p[0], p[1], i))
            continue
        t = r / math.tan(ang / 2.0)
        lim1 = math.hypot(*v(p, p_prev)) * 0.5
        lim2 = math.hypot(*v(p, p_next)) * 0.5
        if t > min(lim1, lim2):
            t = min(lim1, lim2)
            r = t * math.tan(ang / 2.0)
        t1 = (p[0] + d1[0] * t, p[1] + d1[1] * t)
        t2 = (p[0] + d2[0] * t, p[1] + d2[1] * t)
        bis = norm((d1[0] + d2[0], d1[1] + d2[1]))
        dist_c = math.hypot(p[0] - t1[0], p[1] - t1[1])
        dist_c = math.sqrt(dist_c * dist_c + r * r)
        c = (p[0] + bis[0] * dist_c, p[1] + bis[1] * dist_c)
        a1 = math.atan2(t1[1] - c[1], t1[0] - c[0])
        a2 = math.atan2(t2[1] - c[1], t2[0] - c[0])
        sweep = a2 - a1
        while sweep > math.pi:
            sweep -= 2 * math.pi
        while sweep < -math.pi:
            sweep += 2 * math.pi
        steps = max(2, int(abs(sweep) / math.radians(22)) + 1)
        for k in range(steps + 1):
            a = a1 + sweep * k / steps
            pts.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a),
                        i if k == steps // 2 else None))
    out = []
    for p in pts:
        if out and math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) < 2.0:
            if p[2] is not None and out[-1][2] is None:
                out[-1] = (out[-1][0], out[-1][1], p[2])
            continue
        out.append(p)
    if len(out) > 1 and math.hypot(out[0][0] - out[-1][0],
                                   out[0][1] - out[-1][1]) < 2.0:
        out.pop()
    return out

def cum_lengths(pts):
    cum = [0.0]
    for i in range(1, len(pts) + 1):
        a, b = pts[i - 1], pts[i % len(pts)]
        cum.append(cum[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    return cum

def assign_elev(pts, wpts):
    cum = cum_lengths(pts)
    total = cum[-1]
    anchors = []
    for i, w in enumerate(wpts):
        if w[3] is None:
            continue
        for j, p in enumerate(pts):
            if p[2] == i:
                anchors.append((cum[j], w[3]))
                break
    anchors.sort()
    anchors.append((anchors[0][0] + total, anchors[0][1]))
    out = []
    for j, p in enumerate(pts):
        l = cum[j]
        if l < anchors[0][0]:
            l += total
        e = anchors[-1][1]
        for k in range(len(anchors) - 1):
            l0, e0 = anchors[k]
            l1, e1 = anchors[k + 1]
            if l0 <= l <= l1:
                f = (l - l0) / max(1e-6, l1 - l0)
                e = e0 + (e1 - e0) * f
                break
        out.append(e)
    return out, cum, total

def circumradius(a, b, c):
    ab = math.hypot(b[0] - a[0], b[1] - a[1])
    bc = math.hypot(c[0] - b[0], c[1] - b[1])
    ca = math.hypot(a[0] - c[0], a[1] - c[1])
    s = (ab + bc + ca) / 2
    area2 = max(1e-9, s * (s - ab) * (s - bc) * (s - ca))
    return ab * bc * ca / (4 * math.sqrt(area2))

def resample(pts, elevs, step):
    cum = cum_lengths(pts)
    total = cum[-1]
    out = []
    target, j = 0.0, 0
    while target < total:
        while cum[j + 1] < target:
            j += 1
        a, b = pts[j], pts[(j + 1) % len(pts)]
        f = (target - cum[j]) / max(1e-6, cum[j + 1] - cum[j])
        out.append((a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f,
                    elevs[j] + (elevs[(j + 1) % len(pts)] - elevs[j]) * f))
        target += step
    return out

pts = fillet_loop(WPTS)
elevs, cum, total = assign_elev(pts, WPTS)

CTRL_STEP = 12.0
ctrl = resample(pts, elevs, CTRL_STEP)
if math.hypot(ctrl[0][0] - ctrl[-1][0], ctrl[0][1] - ctrl[-1][1]) < CTRL_STEP * 0.5:
    ctrl.pop()
ctrl_tag = [None] * len(ctrl)
# Etichetele se lipesc de cel mai apropiat punct uniform in 3D, nu in XZ:
# la incrucisarile spiralei, punctul de deasupra e la 2 m in plan si la 34 m
# pe verticala — in XZ eticheta etajului 1 sarea pe etajul 3 (masurat).
for j, p in enumerate(pts):
    if p[2] is None:
        continue
    best, bd = 0, 1e9
    for k, q in enumerate(ctrl):
        d = math.hypot(q[0] - p[0], q[1] - p[1], q[2] - elevs[j])
        if d < bd:
            best, bd = k, d
    ctrl_tag[best] = p[2]
pts = [(q[0], q[1], ctrl_tag[k]) for k, q in enumerate(ctrl)]
elevs = [q[2] for q in ctrl]
cum = cum_lengths(pts)
total = cum[-1]
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime harta: {total:.0f} m   lume: {total*S:.0f} m")

frac = {}
for i, w in enumerate(WPTS):
    for j, p in enumerate(pts):
        if p[2] == i:
            frac[w[4]] = cum[j] / total
            break

# --- statistici pe esantionare la 12 m (ca ProbeLayout) ---
rs = resample(pts, elevs, 12.0)
min_r, min_r_at = 1e9, 0
max_slope, max_slope_at = 0, 0
for i in range(len(rs)):
    a, b, c = rs[i - 1], rs[i], rs[(i + 1) % len(rs)]
    r = circumradius(a, b, c) * S
    if r < min_r:
        min_r, min_r_at = r, i * 12.0 / total
    d = math.hypot(c[0] - b[0], c[1] - b[1]) * S
    sl = abs(c[2] - b[2]) / max(1e-6, d)
    if sl > max_slope:
        max_slope, max_slope_at = sl, i * 12.0 / total
print(f"raza minima (lume): {min_r:.1f} m la frac {min_r_at:.3f}  (prag > 7.0)")
print(f"panta maxima: {max_slope*100:.1f}% la frac {max_slope_at:.3f}  (prag 22%)")

# pantele pe spirala F (brief: media < 13%, varf < 16%)
f0, f1 = frac["E pod out / F etaj 1 in"], frac["G Liziba in"]
sl_f = []
for i in range(len(rs)):
    f = i * 12.0 / total
    if f0 <= f <= f1:
        b, c = rs[i], rs[(i + 1) % len(rs)]
        d = math.hypot(c[0] - b[0], c[1] - b[1]) * S
        sl_f.append((c[2] - b[2]) / max(1e-6, d))
print(f"spirala F {f0:.3f}-{f1:.3f}: panta medie {100*sum(sl_f)/len(sl_f):.1f}%  varf {100*max(sl_f):.1f}%")

# separare: perechi ne-vecine apropiate in XZ -> se cere separare VERTICALA
min_sep, min_sep_at = 1e9, (0, 0)
min_dy_stacked, min_dy_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 31, len(rs)):
        if len(rs) - (j - i) <= 30:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1]) * S
        dy = abs(rs[j][2] - rs[i][2])
        if d < 14.0:
            if dy < min_dy_stacked:
                min_dy_stacked, min_dy_at = dy, (i * 12.0 / total, j * 12.0 / total)
        elif d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima XZ (ne-stivuite): {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f}  (prag >= 14)")
print(f"separare verticala minima pe stiva (XZ < 14 m): {min_dy_stacked:.1f} m intre frac {min_dy_at[0]:.3f} si {min_dy_at[1]:.3f}  (prag >= 14)")

mean_elev = sum(elevs) / len(elevs)
WATER_Y = 3.0
sea = round(WATER_Y - mean_elev, 2)
print(f"cota medie sosea: {mean_elev:.1f} -> sea_level_offset = {sea} (apa la {WATER_Y} m)")

print("\nfractii waypoint:")
for w in WPTS:
    print(f"  {frac[w[4]]:.3f}  {w[4]}")

def godot(p, e):
    # OGLINDIT pe x fata de harta Recon: acolo POI-urile A->G merg ORAR (est pe
    # nord, sud pe est), deci apa ar fi iesit pe STANGA. Brieful cere antiorar
    # cu apa pe dreapta; oglindirea pastreaza tot restul (cote, lungimi, raze).
    return (-p[0] * S, e, -p[1] * S)

def r3(x):
    return round(x, 3)

# Pasajul tine pana dupa monorail: G e "etajul 8" (brief). NU pana la iesirea
# din bloc — cu pasajul pana la 0.927 punctele de la 0.93+ (62.5-65 m)
# trageau terenul PESTE tablierul de la 0.90-0.93 (captura: drum ingropat).
# Soseaua de la sol de dupa 0.898 isi sapa singura platoul.
overpass = (r3(frac["F3 a"] - 0.004),
            r3(frac["G monorail"] + 0.006))
# Cornisa D: adancimea (30 m) e doar ca sapatura sa ajunga SIGUR la podea si
# la capatul de sus (drum la 32 m); podeaua absoluta (RAVINE_FLOOR) e cheiul
# uscat de sub faleza, apa incepe dincolo de el (LAGOON).
ravines = [
    (r3(frac["D cornisa in"] - 0.006), r3(frac["E chei in"] - 0.008), 30, 1),
    # Podul peste golf: golul e DOAR pe dreapta (exteriorul buclei). Cu 0
    # (ambele parti) sapatura cobora si interiorul sub cota apei si drumul
    # iesea un dig cu apa pe ambele parti (runda 2, 88 de puncte ude in
    # interior pe 0.50-0.60). Brief §2: interiorul ramane uscat.
    (r3(frac["E pod in"] + 0.004), r3(frac["E pod out / F etaj 1 in"] + 0.012), 12, 1),
    (r3(frac["F1 a"] + 0.004), r3(frac["F etaj 2 (sosire telecabina)"] - 0.008), 10, -1),
]
widths = [
    (r3(frac["A2 pasarela"] + 0.004), r3(frac["A nod de trafic"] + 0.012), 9.0),
    (r3(frac["B intrare scari"]), r3(frac["B S3 / iesire scari"]), 8.0),
    (r3(frac["C aleea hot-pot in"]), r3(frac["C aleea hot-pot out"] + 0.006), 6.0),
    (r3(frac["E chei in"] + 0.004), r3(frac["E pod in"] + 0.006), 9.0),
]
# Podeaua cornisei D: WATER_Y + 3 (chei la ~6 m, uscat).
# Cornisa de la poalele spiralei F (rapa 2, pe stanga = interior) primeste
# aceeasi podea: drumul e la 12-15 m acolo si 10 m de sapatura ajungea la
# 2 m, sub apa (runda 2: apa la 15-20 m stanga pe 0.59).
RAVINE_FLOOR = [(0, WATER_Y + 3.0), (2, WATER_Y + 3.0)]
# APA: golful + cele doua rauri, pe SUD si EST in harta (godot: +z si -x).
# Poligon in coordonate GODOT. Cu banda de mal a temei (6 + 10 m) linia apei
# iese la ~3-5 m INAUNTRUL conturului (cu implicitul de atol, 25 + 45 m, apa
# iesea abia la 80 m de axa si terasa se topea de la 40 m — ProbeTerrace).
# Conturul URMEAZA cornisa D la ~55 m de axa (malul e abrupt: lagoon_band
# 6 + 10 m in tema), deci linia apei iese la ~50 m si terasa 14-50 m ramane
# uscata; pe chei (E, z=205) sta la z=235; ocoleste poalele spiralei F.
# Pe chei (E, x -110..55, axa la z=205, semilatime 9) conturul sta la z=222:
# linia apei la ~17 m de axa, cheiul uscat pe 8 m de la marginea asfaltului.
# Sub pod (x 75..150, axa la z 191-198) conturul urca la 6-9 m de margine,
# ca apa golfului sa fie chiar sub tablier, in continuarea rapei-viaduct.
LAGOON = [(-300, -45), (-283, 25), (-317, 85), (-287, 150), (-225, 235),
          (-110, 222), (55, 222), (75, 206), (150, 200), (185, 214),
          (230, 300), (330, 320), (900, 400), (900, 900),
          (-900, 900), (-900, -45)]
# Fundul lagunei: sub media soselei cu atat cat sa iasa la ~-6 m (apa la 3).
LAGOON_DEPTH = round(mean_elev + 6.0, 1)
print(f"\noverpass: {overpass}\nravines: {ravines}\nwidths: {widths}")
print(f"ravine_floors: {RAVINE_FLOOR}  lagoon_depth: {LAGOON_DEPTH}")

if len(sys.argv) > 1:
    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]
    branch_pts = [godot(p, p[2]) for p in BRANCH_MID]
    rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d in ravines)
    w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in widths)
    fl_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_FLOOR)
    lag_txt = ", ".join(f"Vector2({a}, {b})" for a, b in LAGOON)
    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://b82usw4sot3ep" path="res://scenes/tracks/track_branch.gd" id="3_branch"]

[sub_resource type="Curve3D" id="Curve3D_chongqing"]
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_telecabina"]
_data = {{
"points": {pva(branch_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in branch_pts)})
}}
point_count = {len(branch_pts)}

[node name="Track12" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Chongqing"
custom_theme = "chongqing"
custom_half_width = 7.0
custom_sea_level_offset = {sea}
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([0, 2])
custom_viaduct_ravines = Array[int]([1])
custom_overpass_ranges = Array[Vector2]([Vector2({overpass[0]}, {overpass[1]})])
custom_width_segments = Array[Vector3]([{w_txt}])
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_lagoon = Array[Vector2]([{lag_txt}])
sea_level_offset = {sea}
lagoon_depth = {LAGOON_DEPTH}

[node name="Path" type="Path3D" parent="."]
visible = false
curve = SubResource("Curve3D_chongqing")

[node name="Telecabina" type="Path3D" parent="."]
curve = SubResource("Curve3D_telecabina")
script = ExtResource("3_branch")
branch_half_width = 4.0
speed_factor = 0.85
elevated = true
label = "Telecabina"
surface = 1
tint = Color(0.62, 0.63, 0.66, 1)
"""
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
