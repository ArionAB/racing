# Genereaza traseul Fiordland (Track16) din waypoints cu fillet-uri de arc --
# schela copiata din gen_serengeti_route.py (pas uniform 12 m, viraje > 90 de
# grade esantionate pe arc, statistici ca ProbeLayout).
#
#   python tools/gen_fiordland_route.py [scenes/tracks/Track16.tscn]
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = -x, gz = -y (rotatie
# de 180 de grade, NU oglindire).
import math
import sys

# (x, y, fillet_r, cota, eticheta). Cotele din brief paragraf 2: chei 0,
# cornisa +30, Stirling +32, Chasm +15, portal est (cel mai inalt) +45,
# portal vest +27, baza coborarii +3, bazinul Bowen -4, mare 0.
WPTS_RAW = [
    (0,     0,   26, 0.0,  "A start chei"),
    (20,    86,  26, 0.0,  "A iesire chei"),

    (40,    150, 32, 7.0,  "B urcare 1"),
    (86,    215, 36, 14.0, "B S1 apex spre mare vest"),
    (48,    270, 36, 21.0, "B S1 iesire"),
    (78,    325, 38, 26.0, "B S2 apex spre perete est"),
    (122,   368, 32, 30.0, "B S2 iesire concav spre perete"),

    (128,   420, 28, 31.5, "C intrare Stirling"),
    (131,   458, 22, 32.0, "C sub perdea"),
    (123,   496, 26, 31.0, "C iesire Stirling"),

    (86,    540, 30, 27.0, "D intrare padure"),
    (26,    568, 26, 22.0, "D curba padure 1"),
    (-24,   544, 24, 18.0, "D curba padure 2"),
    (-48,   500, 20, 16.0, "D podetul Chasm"),
    (-38,   458, 24, 15.0, "D iesire Chasm"),

    (-70,   424, 26, 19.5, "E intrare zona avalansa"),
    (-122,  404, 28, 26.0, "E S avalansa apex"),
    (-166,  360, 28, 32.5, "E spre portal"),
    (-172,  296, 26, 39.5, "E aproape de portal"),
    (-146,  244, 22, 45.0, "E portal est linie oprire"),
    (-146,  164, 16, 36.0, "E in tunel 1"),
    (-146,  84,  16, 27.0, "E portal vest"),

    (-136,  8,   32, 21.0, "F iesire portal fiordul in fata"),
    (-100,  -58, 32, 15.0, "F curba 1"),
    (-98,   -128, 30, 8.5, "F cicatricea avalansei"),
    (-64,   -184, 28, 4.0, "F curba 2"),

    (-12,   -206, 22, 3.0,  "G intrare kicker"),
    (24,    -215, 17, -2.0, "G kicker peste bazin"),
    (58,    -206, 22, 1.0,  "G aterizare pietris"),

    (100,   -180, 30, 0.5,  "H iesire din G"),
    (70,    -116, 30, 0.2,  "H malul 1"),
    (40,    -56,  30, 0.0,  "H malul 2 spre chei"),
]
# Scalare uniforma in plan (X, Y hartii) ca lungimea totala sa intre in
# fereastra ProbeLayout 1.950-2.250 m, fara sa schimbe cotele (elevatia nu se
# scaleaza) si fara sa strice raportul lungime tunel / lungimi vecine — s-a
# masurat ca micile alungiri locale nu urcau lungimea totala suficient
# (fillet-urile absorbeau castigul), deci se scaleaza tot planul.
SCALE = 1.08
WPTS = [(round(x * SCALE, 2), round(y * SCALE, 2), round(r * SCALE, 2), e, lbl)
        for x, y, r, e, lbl in WPTS_RAW]


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
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime: {total:.0f} m")

frac = {}
for i, w in enumerate(WPTS):
    for j, p in enumerate(pts):
        if p[2] == i:
            frac[w[4]] = cum[j] / total
            break

def signed_area(seq):
    a = 0.0
    for i in range(len(seq)):
        x0, y0 = seq[i][0], seq[i][1]
        x1, y1 = seq[(i + 1) % len(seq)][0], seq[(i + 1) % len(seq)][1]
        a += x0 * y1 - x1 * y0
    return a / 2.0
print(f"aria cu semn (harta): {signed_area(pts):+.0f}")

rs = resample(pts, elevs, 12.0)
min_r, min_r_at = 1e9, 0
max_slope, max_slope_at = 0, 0
for i in range(len(rs)):
    a, b, c = rs[i - 1], rs[i], rs[(i + 1) % len(rs)]
    r = circumradius(a, b, c)
    if r < min_r:
        min_r, min_r_at = r, i * 12.0 / total
    d = math.hypot(c[0] - b[0], c[1] - b[1])
    sl = abs(c[2] - b[2]) / max(1e-6, d)
    if sl > max_slope:
        max_slope, max_slope_at = sl, i * 12.0 / total
print(f"raza minima: {min_r:.1f} m la frac {min_r_at:.3f}  (prag >= 14 m)")
print(f"panta maxima: {max_slope*100:.1f}% la frac {max_slope_at:.3f}  (prag < 13%)")

def section_slopes(name, f0, f1):
    sl = []
    for i in range(len(rs)):
        f = i * 12.0 / total
        if f0 <= f <= f1:
            b, c = rs[i], rs[(i + 1) % len(rs)]
            d = math.hypot(c[0] - b[0], c[1] - b[1])
            sl.append((c[2] - b[2]) / max(1e-6, d))
    if sl:
        print(f"{name} {f0:.3f}-{f1:.3f}: panta medie {100*sum(sl)/len(sl):+.1f}%  varf {100*max(sl, key=abs):+.1f}%")

section_slopes("cornisa B", frac["A iesire chei"], frac["B S2 iesire concav spre perete"])
section_slopes("coborare Chasm D", frac["C iesire Stirling"], frac["D iesire Chasm"])
section_slopes("urcare la portal E", frac["D iesire Chasm"], frac["E portal est linie oprire"])
section_slopes("tunel E", frac["E portal est linie oprire"], frac["E portal vest"])
section_slopes("coborare F", frac["E portal vest"], frac["F curba 2"])

min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 31, len(rs)):
        if len(rs) - (j - i) <= 30:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        if d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima XZ: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f}  (prag >= 13 = 2*half_width)")

def wpt_xy(name):
    return next((w[0], w[1]) for w in WPTS if w[4] == name)
ew = wpt_xy("E portal vest")
fo = wpt_xy("F iesire portal fiordul in fata")
print(f"distanta E portal vest <-> F iesire portal: {math.hypot(ew[0]-fo[0], ew[1]-fo[1]):.1f} m (prag >= 20 m)")

mean_elev = sum(elevs) / len(elevs)
print(f"cota medie sosea: {mean_elev:.1f} m")

print("\nfractii waypoint:")
for w in WPTS:
    print(f"  {frac[w[4]]:.3f}  {w[4]}  (cota {w[3]:.1f})")

def godot(p, e):
    return (-p[0], e, -p[1])

def r3(x):
    return round(x, 3)

if len(sys.argv) > 1:
    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]

    ravines = [
        (r3(frac["A start chei"]), r3(frac["C intrare Stirling"] + 0.006), 30, -1, "mare A-B-C"),
        (r3(frac["D intrare padure"] - 0.01), r3(frac["D iesire Chasm"] + 0.01), 8, 1, "raul D"),
        (r3(frac["G intrare kicker"] - 0.006), r3(frac["G aterizare pietris"] + 0.006), 6, -1, "bazinul Bowen G"),
        (r3(frac["H iesire din G"] - 0.004), r3(0.999), 30, -1, "mare H"),
    ]
    RAVINE_FLOOR = [(0, -30.0), (1, 7.0), (2, -8.0), (3, -30.0)]
    RAVINE_WIDTH = [(0, 220), (1, 25), (2, 22), (3, 220)]
    wet = [(r3(frac["E portal est linie oprire"] - 0.002), r3(frac["E portal vest"] + 0.004))]
    # Segmente CONTIGUE, fara suprapunere (Track avertizeaza si castiga
    # primul daca se suprapun — memoria zero-repuneri-ascunde-blocajul e
    # despre alt gen de garda tacuta, dar acelasi principiu: o suprapunere
    # nedeclarata iese verde din prima citire si gresita la a doua).
    bridge_lo = r3(frac["D podetul Chasm"] - 0.006)
    bridge_hi = r3(frac["D podetul Chasm"] + 0.012)
    width_segments = [
        (r3(frac["A start chei"]), r3(frac["A iesire chei"]), 8.0),
        (r3(frac["A iesire chei"]), r3(frac["C intrare Stirling"]), 6.0),
        (r3(frac["C intrare Stirling"]), r3(frac["C iesire Stirling"]), 6.0),
        (r3(frac["D intrare padure"]), bridge_lo, 6.5),
        (bridge_lo, bridge_hi, 5.5),
        (bridge_hi, r3(frac["E portal est linie oprire"]), 6.5),
        (r3(frac["E portal est linie oprire"]), r3(frac["E portal vest"]), 3.5),
        (r3(frac["E portal vest"]), r3(frac["F curba 2"]), 7.0),
        (r3(frac["G intrare kicker"]), r3(frac["G aterizare pietris"]), 6.0),
        (r3(frac["H iesire din G"]), r3(0.999), 8.0),
    ]
    step_ranges = [(bridge_lo, bridge_hi)]

    rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d, _ in ravines)
    fl_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_FLOOR)
    rw_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_WIDTH)
    wet_txt = ", ".join(f"Vector2({a}, {b})" for a, b in wet)
    w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in width_segments)
    step_txt = ", ".join(f"Vector2({a}, {b})" for a, b in step_ranges)

    ew_g = godot(wpt_xy("E portal est linie oprire"), 45.0)
    ewv_g = godot(wpt_xy("E portal vest"), 27.0)
    tunnel_peak = ((ew_g[0] + ewv_g[0]) / 2.0, (ew_g[2] + ewv_g[2]) / 2.0)
    b_apex = wpt_xy("B S1 apex spre mare vest")
    mitre_map = (b_apex[0] - 190.0, b_apex[1] + 10.0)
    mitre_g = godot(mitre_map, 60.0)

    peaks_txt = f"""
[node name="MasivTunel" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {round(tunnel_peak[0], 2)}, 70.0, {round(tunnel_peak[1], 2)})
gizmo_extents = 90.0
script = ExtResource("2_peak")
radius_m = 90.0

[node name="MitrePeak" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {round(mitre_g[0], 2)}, {round(mitre_g[1], 2)}, {round(mitre_g[2], 2)})
gizmo_extents = 55.0
script = ExtResource("2_peak")
radius_m = 55.0
"""

    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://da4os4mcgj643" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]

[sub_resource type="Curve3D" id="Curve3D_fiordland"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[node name="Track16" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Fiordland"
custom_theme = "fiordland"
custom_half_width = 6.5
custom_road_surface = "asphalt"
custom_gate_model = "none"
custom_wet_ranges = Array[Vector2]([{wet_txt}])
custom_step_ranges = Array[Vector2]([{step_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([0, 3])
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_ravine_widths = Array[Vector2]([{rw_txt}])
custom_width_segments = Array[Vector3]([{w_txt}])
terrain_pad_m = 220.0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_fiordland")

[node name="Peaks" type="Node3D" parent="."]
{peaks_txt}"""
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
