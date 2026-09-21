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
## Bucla e desenata ca un OVAL inclinat, nu ca un "acolo si inapoi" lung si
## subtire: primul plan (spike de ~845 m pe axa Y a hartii) a lovit peretele
## invizibil al lumii (Track._build_world_bounds, half_extent 420 m fata de
## centroidul traseului) — masurat cu sonda ad-hoc tools/sv_fiord_kicker.gd:
## masina se opreste in zidul de granita la (x=-13, z=229), la 0,6 m de
## bordul nordic calculat din centroid. Reforma: cornisa/Stirling merg spre
## NORD-EST, padurea/tunelul se INTORC spre NORD-VEST fara sa mai urce in Y
## mult peste C, iar coborarea/kickerul revin spre SUD prin vest — un oval
## inclinat de-a curmezisul, nu o tepusa. Lungimea vine din curbe, nu din
## intindere pe o singura axa.
WPTS_RAW = [
    (0,     0,   34, 0.0,  "A start chei"),
    (36,    100, 26, 0.0,  "A iesire chei"),

    (78,    158, 30, 7.0,  "B urcare 1"),
    (144,   204, 34, 14.0, "B S1 apex spre mare vest"),
    (192,   260, 32, 21.0, "B S1 iesire"),
    (250,   298, 36, 26.0, "B S2 apex spre perete est"),
    (312,   312, 30, 30.0, "B S2 iesire concav spre perete"),

    (372,   326, 26, 31.5, "C intrare Stirling"),
    (416,   350, 22, 32.0, "C sub perdea"),
    (452,   384, 24, 31.0, "C iesire Stirling"),

    (486,   434, 28, 27.0, "D intrare padure"),
    (500,   492, 24, 22.0, "D curba padure 1"),
    (476,   544, 22, 18.0, "D podetul Chasm"),
    (426,   568, 20, 16.0, "D iesire Chasm"),
    (368,   558, 24, 17.0, "D spre panta"),

    (312,   538, 24, 19.5, "E intrare zona avalansa"),
    (254,   552, 26, 26.0, "E S avalansa apex"),
    (196,   538, 24, 32.5, "E spre portal"),
    (146,   500, 24, 39.5, "E aproape de portal"),
    (112,   458, 20, 45.0, "E portal est linie oprire"),
    (100,   386, 15, 36.0, "E in tunel 1"),
    (100,   306, 15, 27.0, "E portal vest"),

    (54,    262, 30, 21.0, "F iesire portal fiordul in fata"),
    (-6,    236, 30, 15.0, "F curba 1"),
    (-56,   198, 28, 8.5,  "F cicatricea avalansei"),
    (-84,   146, 26, 4.0,  "F curba 2"),

    (-92,   90,  22, 3.0,  "G intrare kicker"),
    (-78,   40,  17, -2.0, "G kicker peste bazin"),
    (-42,   8,   22, 1.0,  "G aterizare pietris"),

    (-2,    -30, 28, 0.5,  "H iesire din G"),
    # S-ul final (H1: 113 grade, H2: 87 grade — amandoua peste 90, esantionate
    # cu puncte pe arc, nu un singur varf de fillet: un fillet simplu aici
    # dadea raza 15,8 m masurata de ProbeLayout la frac ~0.97 si o felie cu
    # 36% timp lent (peste pragul de 10% din brief) chiar inainte de linie.
    (14,    -52, 30, 0.35, "H malul 1 intrare"),
    (34,    -74, 34, 0.25, "H malul 1 apex"),
    (56,    -66, 30, 0.15, "H malul 1 iesire"),
    (68,    -40, 34, 0.05, "H malul 2 apex"),
    (60,    -14, 30, 0.0,  "H malul 2 spre chei"),
]
# Scalare uniforma in plan: dupa reforma din oval (v. nota de mai sus),
# marginile fata de peretele invizibil al lumii (Track._build_world_bounds,
# half_extent 420 m fata de centroid) au ramas confortabile (masurat: cea mai
# stransa la 347 m), deci se poate creste usor lungimea totala spre fereastra
# ProbeLayout 1.950-2.250 m fara sa se riste zidul din nou.
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

# sea_level_offset: Track.sea_y = mean_road_y() + sea_level_offset, si e
# ACEEASI cota pentru toata harta (safety-net-ul global din
# Track._build_sea_respawn e o cutie de 2400x2400 m intre sea_y-1,2 si
# sea_y-60, indiferent unde esti pe traseu). Implicitul -7.0 e calibrat pentru
# piste cu cota medie mult peste cota joasa; aici cota medie (18 m) e trasa in
# sus de portal (+45), dar F coboara pana la ~10-12 m si H la ~0-0,5 m — cu
# -7.0, sea_y iesea 11,1 m, adica FIX in banda joasa a coborarii F (10-12,4 m,
# marja sub 1 m) — masurat cu un [repunere] reproductibil 100% la acelasi
# punct (frac 0.794-0.799), pe orice seed, cu 0/1/8 masini. Nu era teren
# ingropat (ProbeBuried verde, terenul insusi era corect) si nu era o rapa
# declarata acolo — era cutia de mare, care nu stie de geometria locala.
# Cerem sea_y usor SUB 0 (marea la cota absoluta ~-2, brief-ul zice cheiul la
# 0 m si marea "la fel"): -2 in loc de 0 pastreaza citirea vizuala (cheiul
# ramane practic la nivelul marii) si da malului H (cel mai jos punct
# nesubmers, 0-0,5 m) o marja de 2,8-3,3 m fata de cutia de siguranta
# (sea_y - 1,2), nu doar 1,2-1,7 m.
SEA_LEVEL_TARGET_ABS = -2.0
sea_offset = round(SEA_LEVEL_TARGET_ABS - mean_elev, 2)
print(f"sea_level_offset ales: {sea_offset} (tinta mare absoluta {SEA_LEVEL_TARGET_ABS} m)")

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
    # Mitre Peak: peste fiord, in directia MARII (ravine 0, side=-1) fata de
    # cornisa B, la ~220 m — NU un offset fix pe axa X ca in v1 (calibrat pe
    # orientarea veche "spike lung pe Y", a supravietuit reformei in oval si a
    # ajuns sa cada la 3,4 m de sosea, in sectiunea F, complet neinrudita cu
    # cornisa. Directia marii se deriva din tangenta drumului la "B S1 apex"
    # (perpendiculara, verificata empiric cu tools/sv_frac_dump.gd: ground_y
    # scade la offsetul NEGATIV al lui TrackRoute.side_at aici, deci marea e
    # in directia opusa lui side_at). Clearance verificat: 220 m fata de
    # ORICE punct al soselei (nu doar de B), pentru un varf de raza 55 m.
    b_apex = wpt_xy("B S1 apex spre mare vest")
    b_idx = None
    for j, p in enumerate(pts):
        if p[2] == [w[4] for w in WPTS].index("B S1 apex spre mare vest"):
            b_idx = j
            break
    pa = pts[b_idx - 1]
    pc = pts[(b_idx + 1) % len(pts)]
    tdx, tdy = pc[0] - pa[0], pc[1] - pa[1]
    tlen = math.hypot(tdx, tdy)
    tdx, tdy = tdx / tlen, tdy / tlen
    # side_at (Godot, "dreapta") = tangent.cross(UP) in lume Godot; in coordonate
    # de HARTA (x_map=-x_godot, y_map=-z_godot) cu tangenta (tdx,tdy) pe harta,
    # directia "dreapta Godot" corespunde la (-tdy, tdx) pe harta. Verificat cu
    # tools/sv_frac_dump.gd la B apex: offsetul NEGATIV pe side_at Godot are
    # ground_y jos (marea), deci marea e la (tdy, -tdx) pe harta (opusul lui
    # "dreapta").
    sea_dir = (tdy, -tdx)
    MITRE_DIST_M = 220.0
    mitre_map = (b_apex[0] + sea_dir[0] * MITRE_DIST_M,
                 b_apex[1] + sea_dir[1] * MITRE_DIST_M)
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
custom_sea_level_offset = {sea_offset}
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
