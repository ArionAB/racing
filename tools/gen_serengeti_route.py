# Genereaza traseul Serengeti / Ngorongoro (Track14) din waypoints cu
# fillet-uri de arc — schela de generare INITIALA, copiata din
# gen_chongqing_route.py (aceleasi lectii: pas uniform 12 m, virajele > 90 de
# grade esantionate pe arc, statistici ca ProbeLayout).
#
#   python tools/gen_serengeti_route.py [scenes/tracks/Track14.tscn]
#
# Coordonate de HARTA: x est, y nord (metri). Godot: gx = -x, gz = -y (rotatie
# de 180 de grade, NU oglindire — orientarea buclei se pastreaza).
#
# ORIENTAREA, derivata, nu ghicita (brief §2: craterul pe DREAPTA, in
# interiorul buclei). In Godot `dreapta = f x up = (-fz, fx)`: pe un cerc
# (R cos t, R sin t) in planul (x, z), cu t crescator, dreapta arata spre
# centru. Rotatia de 180 de grade pastreaza sensul, deci si pe harta bucla se
# parcurge cu t crescator, adica ANTIORAR cu nordul in sus, si craterul
# ramane pe STANGA in harta. (Pe harta: stanga; in joc: dreapta. Ambele sunt
# acelasi interior.)
#
# Dupa merge, sursa de adevar e Path3D-ul din Track14.tscn (TrackFromPath):
# rularea scriptului peste scena REGENEREAZA TOT, inclusiv nodurile de mana.
import math
import sys

# Centrul craterului (harta). Lacul Magadi sta aici, buza la ~120-160 m.
CRATER = (0.0, 60.0)

# (x, y, fillet_r, cota, eticheta). Cotele din brief §2: campie 0, buza 45,
# fundul craterului 2. Urcarea D si coborarea F se verifica la < 13% (media
# pistelor) — cifrele de mai jos sunt iterate cu statisticile scriptului.
WPTS = [
    (-230, -165, 30, 0.0,  "A start camp"),
    (-140, -165, 30, 0.0,  "B campie"),
    (-70,  -165, 30, 0.0,  "B traversarea turmei"),
    (25,   -165, 28, 0.0,  "C mal vest"),
    (75,   -165, 22, -1.5, "C vadul Mara"),
    (125,  -160, 24, 0.0,  "C mal est"),
    (170,  -130, 22, 3.0,  "D padurea in"),
    (215,  -76,  22, 11.0, "D S1"),
    (158,  -28,  22, 19.0, "D S2"),
    (214,  22,   22, 27.0, "D S3"),
    (170,  72,   22, 34.5, "D S4"),
    (154,  110,  22, 39.0, "D iesire padure"),
    (118,  150,  24, 45.0, "E buza NE (dezvaluire)"),
    (70,   172,  26, 45.0, "E buza S1 in"),
    (30,   162,  26, 45.0, "E buza S1 apex (spre crater)"),
    (-15,  186,  26, 45.0, "E buza S2"),
    (-62,  170,  26, 45.0, "E boma Maasai"),
    (-112, 150,  24, 45.0, "E buza NV"),
    # Serpentinele: acele de par sunt SEMICERCURI explicite (3 puncte, r 12),
    # nu un varf cu fillet — un fillet la 165 de grade consuma tot bratul si
    # scurteaza drumul (masurat: F la 16,8% medie, varf 27,9%). Bratele la
    # 30 m intre ele, r 15: Catmull-Rom strange arcul (r 12 a iesit 5,9 m in
    # ProbeLayout, sub half_width 7).
    (-150, 142,  15, 44.5, "F intrare"),
    (-178, 128,  15, 43.0, "F ac 1 apex"),
    (-165, 116,  15, 42.0, "F ac 1 out"),
    (-90,  116,  15, 35.0, "F ac 2 in"),
    (-75,  101,  15, 33.3, "F ac 2 apex"),
    (-90,  86,   15, 31.5, "F ac 2 out"),
    (-165, 86,   15, 24.5, "F ac 3 in"),
    (-180, 71,   15, 22.8, "F ac 3 apex"),
    (-165, 56,   15, 21.0, "F ac 3 out"),
    (-90,  56,   15, 14.0, "F ac 4 in"),
    (-75,  41,   15, 12.3, "F ac 4 apex"),
    (-90,  26,   15, 10.5, "F ac 4 out"),
    (-150, 26,   22, 5.5,  "F ultimul brat"),
    (-125, 0,    26, 3.0,  "F iesire pe fund"),
    (-50,  -4,   30, 2.0,  "G malul lacului"),
    (10,   -10,  30, 2.0,  "G elefanti / vartej"),
    (55,   -40,  28, 2.0,  "G campul de soda"),
    (40,   -85,  24, 2.0,  "G spre spartura"),
    (-10,  -115, 20, 1.0,  "H spartura Lerai"),
    (-80,  -128, 30, 0.0,  "H iesire in campie"),
    (-170, -112, 30, 0.0,  "A2 ocolul campului"),
    (-250, -125, 30, 0.0,  "A2 in spatele kopje-ului"),
    (-272, -165, 26, 0.0,  "A2 intoarcere spre linie"),
]

# Lacul Magadi: poligon in coordonate GODOT (gx = -x, gz = -y), in jurul
# centrului craterului, la >= 15 m de drumul de pe fund (G) ca sapatura
# lagunei sa nu atinga banda.
LAKE_R = 52.0
LAKE_C = (-CRATER[0], -CRATER[1] - 8.0)
LAGOON = [(round(LAKE_C[0] + LAKE_R * math.cos(a), 1),
           round(LAKE_C[1] + LAKE_R * 0.8 * math.sin(a), 1))
          for a in [i * math.tau / 16 for i in range(16)]]


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

# --- orientarea: craterul trebuie sa fie pe DREAPTA in Godot (= stanga in harta)
def signed_area(seq):
    a = 0.0
    for i in range(len(seq)):
        x0, y0 = seq[i][0], seq[i][1]
        x1, y1 = seq[(i + 1) % len(seq)][0], seq[(i + 1) % len(seq)][1]
        a += x0 * y1 - x1 * y0
    return a / 2.0
print(f"aria cu semn (harta): {signed_area(pts):+.0f}  (> 0 = antiorar pe harta = interior pe dreapta in joc)")

# --- statistici pe esantionare la 12 m (ca ProbeLayout) ---
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
print(f"raza minima: {min_r:.1f} m la frac {min_r_at:.3f}  (prag > 6.0 = half_width)")
print(f"panta maxima: {max_slope*100:.1f}% la frac {max_slope_at:.3f}  (prag 22%)")

def section_slopes(name, f0, f1):
    sl = []
    for i in range(len(rs)):
        f = i * 12.0 / total
        if f0 <= f <= f1:
            b, c = rs[i], rs[(i + 1) % len(rs)]
            d = math.hypot(c[0] - b[0], c[1] - b[1])
            sl.append((c[2] - b[2]) / max(1e-6, d))
    print(f"{name} {f0:.3f}-{f1:.3f}: panta medie {100*sum(sl)/len(sl):+.1f}%  varf {100*max(sl, key=abs):+.1f}%  (media < 13%)")

section_slopes("urcarea D", frac["C mal est"], frac["E buza NE (dezvaluire)"])
section_slopes("coborarea F", frac["F intrare"], frac["F iesire pe fund"])

# separare: perechi ne-vecine apropiate in XZ (acele de par din F)
min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 31, len(rs)):
        if len(rs) - (j - i) <= 30:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1])
        if d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima XZ: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f}  (prag >= 12 = 2*half_width)")

# distanta buzei fata de centrul craterului (cat de rotund e craterul)
for name in ["E buza NE (dezvaluire)", "E buza S2", "E buza NV", "F ac 3 apex"]:
    w = next(w for w in WPTS if w[4] == name)
    print(f"  {name}: {math.hypot(w[0]-CRATER[0], w[1]-CRATER[1]):.0f} m de centrul craterului")

mean_elev = sum(elevs) / len(elevs)
# Apa sub campie (0 m): la +1 m toata campia de sud iesea inundata in
# snapshot. La -0,5 raman ude doar vadul (drumul coboara la -1,5) si lacul.
WATER_Y = -0.5
sea = round(WATER_Y - mean_elev, 2)
LAGOON_DEPTH = round(mean_elev + 3.5, 1)
print(f"cota medie sosea: {mean_elev:.1f} -> sea_level_offset = {sea} (apa la {WATER_Y} m), lagoon_depth {LAGOON_DEPTH}")

print("\nfractii waypoint:")
for w in WPTS:
    print(f"  {frac[w[4]]:.3f}  {w[4]}")

def godot(p, e):
    return (-p[0], e, -p[1])

def r3(x):
    return round(x, 3)

# Rapa craterului sub buza (E), pe DREAPTA (interior), cornisa: cade pana la
# fundul craterului (podea absoluta 2 m), lata cat sa ajunga la lac.
ravines = [
    (r3(frac["E buza NE (dezvaluire)"] - 0.004), r3(frac["E buza NV"] + 0.004), 45, 1),
]
RAVINE_FLOOR = [(0, 2.0)]
# Latimea rapei = pana DINCOLO de lac (buza e la 127-148 m de centru): cu 120
# m craterul iesea un sant cu mal opus la jumatatea drumului, nu un bol.
RAVINE_WIDTH = [(0, 175)]
widths = [
    (r3(frac["A2 intoarcere spre linie"]), r3(frac["B campie"]), 9.0),
    (r3(frac["B campie"]), r3(frac["C mal vest"]), 10.0),
    (r3(frac["C mal vest"]), r3(frac["C mal est"]), 8.0),
    (r3(frac["D padurea in"]), r3(frac["E buza NE (dezvaluire)"]), 6.5),
    (r3(frac["E buza NE (dezvaluire)"]), r3(frac["E buza NV"]), 7.0),
    (r3(frac["E buza NV"]), r3(frac["F iesire pe fund"]), 6.0),
    (r3(frac["F iesire pe fund"]), r3(frac["H spartura Lerai"]), 9.0),
    (r3(frac["H spartura Lerai"]), r3(frac["H iesire in campie"]), 7.0),
]
wet = [(r3(frac["C vadul Mara"] - 0.008), r3(frac["C vadul Mara"] + 0.008))]
print(f"\nravines: {ravines}\nwidths: {widths}\nwet: {wet}")

if len(sys.argv) > 1:
    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]
    rav_txt = ", ".join(f"Vector4({a}, {b}, {c}, {d})" for a, b, c, d in ravines)
    w_txt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in widths)
    fl_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_FLOOR)
    rw_txt = ", ".join(f"Vector2({a}, {b})" for a, b in RAVINE_WIDTH)
    lag_txt = ", ".join(f"Vector2({a}, {b})" for a, b in LAGOON)
    wet_txt = ", ".join(f"Vector2({a}, {b})" for a, b in wet)
    # Dealurile buzei de sud (fara drum pe ele): craterul trebuie sa fie bol si
    # acolo unde nu trece traseul, altfel "spartura" H n-are din ce sa iasa.
    peaks = [
        ("BuzaSudEst", (75, -125), 44.0, 48.0),
        ("BuzaSudVest", (-95, -75), 44.0, 45.0),
    ]
    peak_txt = ""
    for name, (px, py), h, r in peaks:
        gx, gz = -px, -py
        peak_txt += f"""
[node name="{name}" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {gx}, {h}, {gz})
gizmo_extents = {r}
script = ExtResource("2_peak")
radius_m = {r}
"""
    def uid(path):
        with open(path + ".uid", encoding="utf-8") as f:
            return f.read().strip()
    uid_herd = uid("scenes/hazards/herd_hazard.gd")
    uid_hippo = uid("scenes/hazards/hippo_hazard.gd")
    uid_devil = uid("scenes/hazards/dust_devil_hazard.gd")

    def at(name):
        w = next(w for w in WPTS if w[4] == name)
        return godot(w, w[3])

    def xf(gp, y=None):
        y = gp[1] if y is None else y
        return f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {round(gp[0], 2)}, {round(y, 2)}, {round(gp[2], 2)})"

    # Hazardurile din brief §3, ca noduri editabile (fara HazardMarker: nu
    # sunt pe o fractie, au geometrie proprie). Drumul de la B merge spre
    # +x pe harta = -x in Godot; turma il taie pe axa z.
    herd_p = at("B traversarea turmei")
    hippo_p = at("C vadul Mara")
    devil_p = at("G campul de soda")
    hazards = f"""
[node name="Hazarduri" type="Node3D" parent="."]

[node name="RaulDeGnu" type="Node3D" parent="Hazarduri"]
transform = {xf(herd_p, 0.0)}
script = ExtResource("3_herd")
flow_dir = Vector3(0, 0, 1)
road_dir = Vector3(-1, 0, 0)
"""
    for k, (dx, dz, ph) in enumerate([(-6.0, -2.0, 0.0), (0.0, 2.5, 0.33), (6.0, -1.5, 0.66)]):
        hazards += f"""
[node name="Hipopotam{k + 1}" type="AnimatableBody3D" parent="Hazarduri"]
transform = {xf((hippo_p[0] + dx, hippo_p[1], hippo_p[2] + dz))}
script = ExtResource("4_hippo")
phase = {ph}
"""
    hazards += f"""
[node name="VartejDePraf" type="Node3D" parent="Hazarduri"]
transform = {xf(devil_p)}
script = ExtResource("5_devil")
amplitude = Vector2(14, 26)
"""
    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://da4os4mcgj643" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" uid="{uid_herd}" path="res://scenes/hazards/herd_hazard.gd" id="3_herd"]
[ext_resource type="Script" uid="{uid_hippo}" path="res://scenes/hazards/hippo_hazard.gd" id="4_hippo"]
[ext_resource type="Script" uid="{uid_devil}" path="res://scenes/hazards/dust_devil_hazard.gd" id="5_devil"]

[sub_resource type="Curve3D" id="Curve3D_serengeti"]
closed = true
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[node name="Track14" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Serengeti"
custom_theme = "serengeti"
custom_half_width = 6.5
custom_road_surface = "dirt"
custom_gate_model = "none"
custom_sea_level_offset = {sea}
custom_wet_ranges = Array[Vector2]([{wet_txt}])
custom_ravines = Array[Vector4]([{rav_txt}])
custom_cornice_ravines = Array[int]([0])
custom_ravine_floors = Array[Vector2]([{fl_txt}])
custom_ravine_widths = Array[Vector2]([{rw_txt}])
custom_width_segments = Array[Vector3]([{w_txt}])
custom_lagoon = Array[Vector2]([{lag_txt}])
sea_level_offset = {sea}
lagoon_depth = {LAGOON_DEPTH}
terrain_pad_m = 200.0

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_serengeti")

[node name="Peaks" type="Node3D" parent="."]
{peak_txt}{hazards}"""
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
