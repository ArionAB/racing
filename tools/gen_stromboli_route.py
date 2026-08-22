# Genereaza traseul Stromboli (Track11) din waypoints cu fillet-uri de arc.
#
#   python tools/gen_stromboli_route.py [scenes/tracks/Track11.tscn]
#
# Coordonate de harta: x est, y nord (metri). Godot: gx=(x-300)*S, gz=-(y-240)*S.
# Iese: PackedVector3Array + tilts + point_count pentru .tscn, plus statistici
# (lungime, raza minima, panta maxima, separare minima, fractii per waypoint).
#
# ATENTIE: scriptul a fost SCHELA de generare initiala (PR-ul care a creat
# Track11). Dupa merge, sursa de adevar e Path3D-ul din Track11.tscn, editabil
# vizual (TrackFromPath) — rularea scriptului peste scena REGENEREAZA TOT si
# sterge orice ajustare de mana. Lectiile incorporate, platite cu ProbeLayout:
#   - puncte de control la PAS UNIFORM (12 m): un segment de 100 m langa arce
#     de 6 m face tangentele Catmull-Rom sa explodeze (raza 1.3 m masurata);
#   - acele de par sunt U-uri din 3 waypoints (in/apex/out), nu un varf;
#   - mid-urile scurtaturii stau egal distantate, cu profil liniar de cota,
#     si SUB bifurcatie, ca sa nu se agate de coborarea din amonte.
import math

S = 1.04  # scara hartii -> lume (aduce bucla la ~2.0 km)

# (x, y, fillet_r, elev_anchor sau None, eticheta)
WPTS = [
    (300, 240, 30, 8.0,  "A start sat"),
    (240, 262, 35, 5.0,  "iesire sat"),
    (150, 252, 40, 3.5,  "B plaja"),
    (80,  218, 30, 4.0,  "capat plaja / baza urcarii"),
    (95,  192, 20, None, "intrare serpentine"),
    (160, 192, 16, None, "U1 in"),
    (177, 174, 16, None, "U1 apex"),
    (160, 156, 16, None, "U1 out"),
    (78,  156, 16, None, "U2 in"),
    (61,  138, 16, None, "U2 apex"),
    (78,  120, 16, None, "U2 out"),
    (160, 120, 16, None, "U3 in"),
    (177, 102, 16, None, "U3 apex"),
    (160, 84,  16, None, "U3 out"),
    (78,  84,  16, None, "U4 in"),
    (61,  66,  16, None, "U4 apex"),
    (78,  48,  16, None, "U4 out"),
    (215, 48,  16, None, "U5 in (acul buzei)"),
    (233, 35,  16, None, "U5 apex"),
    (215, 22,  16, None, "U5 out"),
    (195, 24,  16, 60.0, "D buza N (intrare)"),
    (174, 18.4,16, None, "buza 120"),
    (158.6, 3, 16, None, "buza 150"),
    (153, -18, 16, 61.0, "buza V (varf)"),
    (160.6,-42.1,18, 58.0, "iesire buza"),
    (98,  -56, 16, None, "E zig 1"),
    (155, -102,16, None, "E zig 2"),
    (92,  -130,16, None, "E zig 3"),
    (146, -162,16, None, "E zig 4"),
    (80,  -178,20, 22.0, "F bifurcatie (desprindere)"),
    (48,  -212,25, 15.0, "ocol vest"),
    (105, -250,30, 7.0,  "ocol jos"),
    (166, -216,20, 8.0,  "F' rejoin"),
    (208, -236,16, 6.0,  "G Ginostra"),
    (252, -222,25, 8.0,  "iesire Ginostra"),
    (310, -165,40, 10.0, "coasta SE"),
    (338, -85, 45, 12.0, "coasta E"),
    (345, -5,  45, 14.0, "coasta NE"),
    (334, 68,  45, 13.0, "H fumarole"),
    (320, 140, 45, 11.0, "coasta N"),
    (308, 200, 40, 9.0,  "intrare sat"),
]

# scurtatura de lava: (x, y, elev) — mid-urile stau SUB cota bifurcatiei si
# spre sud, ca primul punct sa se agate de ramura de DUPA bifurcatie (ocol),
# nu de coborarea din amonte (ProbeLayout: atasare la elev 23 -> 51% panta).
# mid-uri EGAL distantate pe coarda, cu profil liniar de cota de la racordul
# de sus (~21 m) la cel de jos (~8 m): pasul inegal + saltul de cota la primul
# segment faceau Catmull-Rom sa iasa la 29% (masurat).
BRANCH_MID = [(91, -196, 17.8), (111, -205.5, 14.6), (131, -215, 11.4)]
CRATER = (195, -18)

def v(a, b):
    return (b[0] - a[0], b[1] - a[1])

def norm(a):
    l = math.hypot(*a)
    return (a[0] / l, a[1] / l)

def fillet_loop(wpts):
    """Inlocuieste fiecare varf cu un arc tangent la cele doua laturi."""
    n = len(wpts)
    pts = []           # (x, y, idx_varf sau None)
    for i in range(n):
        p_prev = wpts[(i - 1) % n][:2]
        p = wpts[i][:2]
        p_next = wpts[(i + 1) % n][:2]
        r = wpts[i][2]
        d1, d2 = norm(v(p, p_prev)), norm(v(p, p_next))
        cosang = max(-1.0, min(1.0, d1[0] * d2[0] + d1[1] * d2[1]))
        ang = math.acos(cosang)          # unghiul intern al varfului
        turn = math.pi - ang             # cat se schimba directia
        if turn < math.radians(8):       # aproape drept: pastram varful
            pts.append((p[0], p[1], i))
            continue
        t = r / math.tan(ang / 2.0)      # distanta varf -> punct de tangenta
        lim1 = math.hypot(*v(p, p_prev)) * 0.5
        lim2 = math.hypot(*v(p, p_next)) * 0.5
        if t > min(lim1, lim2):
            t = min(lim1, lim2)
            r = t * math.tan(ang / 2.0)  # raza reala, redusa de laturi scurte
        t1 = (p[0] + d1[0] * t, p[1] + d1[1] * t)
        t2 = (p[0] + d2[0] * t, p[1] + d2[1] * t)
        # centrul: pe bisectoare, la distanta r de fiecare latura
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
    # dedupe: cand fillet-ul consuma exact jumatate din latura, arcele vecine
    # se ating si punctul dublat face CUSP in Catmull-Rom (raza 1.3 m masurata)
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
    """Cote: interpolare pe lungime intre ancorele waypoint-urilor."""
    cum = cum_lengths(pts)
    total = cum[-1]
    # pozitia (lungimea) fiecarui waypoint ancorat = primul punct marcat cu idx
    anchors = []  # (lungime, elev)
    for i, w in enumerate(WPTS):
        if w[3] is None:
            continue
        for j, p in enumerate(pts):
            if p[2] == i:
                anchors.append((cum[j], w[3]))
                break
    anchors.sort()
    # inchidem bucla: prima ancora se repeta la capat
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

# Puncte de control la PAS UNIFORM: un segment de 100 m langa arce de 6 m
# face tangentele Catmull-Rom (uniforme pe pozitii, in Track) sa explodeze —
# raza 1.3 m masurata de ProbeLayout. Memoria "viraje-stranse-puncte-pe-arc":
# esantioneaza arcul SI echilibreaza distantele.
CTRL_STEP = 12.0
ctrl = resample(pts, elevs, CTRL_STEP)
if math.hypot(ctrl[0][0] - ctrl[-1][0], ctrl[0][1] - ctrl[-1][1]) < CTRL_STEP * 0.5:
    ctrl.pop()
# pastram etichetele waypoint-urilor pe cel mai apropiat punct uniform
ctrl_tag = [None] * len(ctrl)
for j, p in enumerate(pts):
    if p[2] is None:
        continue
    best, bd = 0, 1e9
    for k, q in enumerate(ctrl):
        d = math.hypot(q[0] - p[0], q[1] - p[1])
        if d < bd:
            best, bd = k, d
    ctrl_tag[best] = p[2]
pts = [(q[0], q[1], ctrl_tag[k]) for k, q in enumerate(ctrl)]
elevs = [q[2] for q in ctrl]
cum = cum_lengths(pts)
total = cum[-1]
print(f"puncte de control: {len(pts)} (pas {CTRL_STEP} m)   lungime harta: {total:.0f} m   lume: {total*S:.0f} m")

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

# separare minima intre puncte ne-vecine (sar 30 de esantioane, ca sonda)
min_sep, min_sep_at = 1e9, (0, 0)
for i in range(len(rs)):
    for j in range(i + 31, len(rs)):
        if len(rs) - (j - i) <= 30:
            continue
        d = math.hypot(rs[j][0] - rs[i][0], rs[j][1] - rs[i][1]) * S
        if d < min_sep:
            min_sep, min_sep_at = d, (i * 12.0 / total, j * 12.0 / total)
print(f"separare minima: {min_sep:.1f} m intre frac {min_sep_at[0]:.3f} si {min_sep_at[1]:.3f}  (prag >= 14)")

mean_elev = sum(elevs) / len(elevs)
print(f"cota medie sosea: {mean_elev:.1f} -> sea_level_offset = {-mean_elev:.2f}")

# fractiile waypoint-urilor etichetate
print("\nfractii waypoint:")
for i, w in enumerate(WPTS):
    for j, p in enumerate(pts):
        if p[2] == i:
            print(f"  {cum[j]/total:.3f}  {w[4]}")
            break

# --- curba pentru .tscn (godot) ---
def godot(p, e):
    return ((p[0] - 300) * S, e, -(p[1] - 240) * S)

vals = []
for j, p in enumerate(pts):
    g = godot(p, elevs[j])
    vals += [0, 0, 0, 0, 0, 0, round(g[0], 2), round(g[1], 2), round(g[2], 2)]
print(f"\npoint_count = {len(pts)}")
print('"points": PackedVector3Array(' + ", ".join(str(x) for x in vals) + "),")
print('"tilts": PackedFloat32Array(' + ", ".join("0" for _ in pts) + ")")

print("\nbranch (godot, mijloc):")
for p in BRANCH_MID:
    g = godot(p, p[2])
    print(f"  {g[0]:.1f}, {g[1]:.1f}, {g[2]:.1f}")
g = godot(CRATER, 0)
print(f"\ncrater (godot): {g[0]:.1f}, _, {g[2]:.1f}")

# --- scrie Track11.tscn --------------------------------------------------------
import sys
if len(sys.argv) > 1:
    frac = {}
    for i, w in enumerate(WPTS):
        for j, p in enumerate(pts):
            if p[2] == i:
                frac[w[4]] = cum[j] / total
                break

    def pva(seq):
        return "PackedVector3Array(" + ", ".join(
            f"0, 0, 0, 0, 0, 0, {round(a, 2)}, {round(b, 2)}, {round(c, 2)}"
            for a, b, c in seq) + ")"

    main_pts = [godot(p, elevs[j]) for j, p in enumerate(pts)]
    branch_pts = [godot(p, p[2]) for p in BRANCH_MID]
    cg = godot(CRATER, 0)
    sea = round(-mean_elev, 2)
    rav = (round(frac["D buza N (intrare)"] - 0.004, 3),
           round(frac["iesire buza"] + 0.004, 3))
    widths = [
        (round(frac["iesire sat"], 3),
         round(frac["capat plaja / baza urcarii"], 3), 9.0),
        (round(frac["U5 out"] - 0.004, 3),
         round(frac["iesire buza"] + 0.006, 3), 6.5),
        (round(frac["G Ginostra"] - 0.014, 3),
         round(frac["G Ginostra"] + 0.014, 3), 6.0),
    ]
    wtxt = ", ".join(f"Vector3({a}, {b}, {c})" for a, b, c in widths)
    tscn = f"""[gd_scene format=3]

[ext_resource type="Script" uid="uid://bhkx6a1cg2py7" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" uid="uid://da4os4mcgj643" path="res://scenes/tracks/terrain_peak.gd" id="2_peak"]
[ext_resource type="Script" uid="uid://b82usw4sot3ep" path="res://scenes/tracks/track_branch.gd" id="3_branch"]

[sub_resource type="Curve3D" id="Curve3D_stromboli"]
_data = {{
"points": {pva(main_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in main_pts)})
}}
point_count = {len(main_pts)}

[sub_resource type="Curve3D" id="Curve3D_scurta"]
_data = {{
"points": {pva(branch_pts)},
"tilts": PackedFloat32Array({", ".join("0" for _ in branch_pts)})
}}
point_count = {len(branch_pts)}

[node name="Track11" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Stromboli"
custom_theme = "stromboli"
custom_road_surface = "dirt"
custom_sea_level_offset = {sea}
custom_ravines = Array[Vector4]([Vector4({rav[0]}, {rav[1]}, 14, -1)])
custom_cornice_ravines = Array[int]([0])
custom_width_segments = Array[Vector3]([{wtxt}])
sea_level_offset = {sea}

[node name="Path" type="Path3D" parent="."]
visible = false
curve = SubResource("Curve3D_stromboli")

[node name="Peaks" type="Node3D" parent="."]

[node name="CraterPeak" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cg[0]:.1f}, 68, {cg[2]:.1f})
gizmo_extents = 60.0
script = ExtResource("2_peak")
radius_m = 60.0

[node name="FlanculConului" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cg[0]:.1f}, 40, {cg[2]:.1f})
gizmo_extents = 155.0
script = ExtResource("2_peak")
radius_m = 155.0

[node name="DealulSatului" type="Marker3D" parent="Peaks"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 31.2, 16, 72.8)
gizmo_extents = 70.0
script = ExtResource("2_peak")
radius_m = 70.0

[node name="ScurtaturaLavei" type="Path3D" parent="."]
curve = SubResource("Curve3D_scurta")
script = ExtResource("3_branch")
branch_half_width = 3.0
label = "Scurtatura de lava"
"""
    with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
        f.write(tscn)
    print(f"\nscris: {sys.argv[1]}")
    print(f"ravina crater: {rav}   widths: {widths}")
