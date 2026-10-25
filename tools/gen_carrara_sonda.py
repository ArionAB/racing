#!/usr/bin/env python3
"""Genereaza tools/SondaCarrara.tscn: pista SINTETICA a sondelor tehnice Carrara
(brief docs/track_briefs/carrara.md §7 pasul 1 (a) si (b)). NU e Track23.

Ce modeleaza (POI B si POI A din brief, fara decor):
  - coborarea pe 3 terase drepte de 120 m (7 m latime), unite de 2 ace de par
    (raza axei 15 m, 6 m latime, 9 m de coborare pe ~79 m = 11.4%), apoi un
    tur de intoarcere care inchide bucla (urca 18 m, 1.7%);
  - pe tura de intoarcere o dreapta de 400 m cu 10 m latime pentru cupa
    excavatorului (POI A).
  - doua camioane (BusHazard, camionul Kamaz) pe ACEEASI curba, phase 0.0 /
    0.5, care urca terasele IN SENS INVERS cursei, pe banda STANGA a cursei.

Doua trepte (curba camionului se deriva din axa REALA coapta de Track, nu din
geometria analitica: Catmull-Rom strange arcele):

  python tools/gen_carrara_sonda.py            # treapta 1: ruta + excavator
  godot ... res://tools/ProbeCarrara.tscn -- --dump-route
  python tools/gen_carrara_sonda.py            # treapta 2: + camioanele

Treapta 2 citeste tools/data/carrara_sonda/route.csv (x,y,z,half_width,frac,
per punct copt) si scrie si fractiile reale ale terasele/acelor.
"""
import csv
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(ROOT, "tools", "data", "carrara_sonda", "route.csv")
OUT = os.path.join(ROOT, "tools", "SondaCarrara.tscn")

STEP = 12.0          # pas pe drepte (memoria viraje-stranse: pas 12 m)
HW_TERRACE = 3.5     # 7 m
HW_HAIRPIN = 3.0     # 6 m
HW_EXC = 5.0         # 10 m (POI A)
R_HAIRPIN = float(os.environ.get("R_HAIRPIN", "16.0"))
ARC_PTS = int(os.environ.get("ARC_PTS", "4"))   # puncte pe arc incl. capetele
LEAD = float(os.environ.get("LEAD", "24.0"))
Y_TOP = 18.0

# --- ruta (turtle) ------------------------------------------------------


class Turtle:
    def __init__(self):
        self.x, self.z, self.y = 0.0, 0.0, Y_TOP
        self.th = 0.0  # 0 = +X; dreapta (spre +Z) = theta creste
        self.pts = [(0.0, Y_TOP, 0.0)]
        self.marks = []  # (nume, index_punct_start, index_punct_end)

    def straight(self, length, dy=0.0):
        n = max(1, int(math.ceil(length / STEP)))
        for k in range(1, n + 1):
            t = k / n
            self.pts.append((self.x + math.cos(self.th) * length * t,
                             self.y + dy * t,
                             self.z + math.sin(self.th) * length * t))
        self.x += math.cos(self.th) * length
        self.z += math.sin(self.th) * length
        self.y += dy

    def arc(self, radius, angle_deg, right, dy=0.0, npts=ARC_PTS):
        sgn = 1.0 if right else -1.0
        # centrul: perpendicular pe directia curenta, pe partea virajului
        cx = self.x + math.cos(self.th + sgn * math.pi / 2) * radius
        cz = self.z + math.sin(self.th + sgn * math.pi / 2) * radius
        a0 = math.atan2(self.z - cz, self.x - cx)
        total = math.radians(angle_deg) * sgn
        for k in range(1, npts):
            t = k / (npts - 1)
            a = a0 + total * t
            self.pts.append((cx + math.cos(a) * radius,
                             self.y + dy * t,
                             cz + math.sin(a) * radius))
        a1 = a0 + total
        self.x = cx + math.cos(a1) * radius
        self.z = cz + math.sin(a1) * radius
        self.y += dy
        self.th += total


def build_route():
    t = Turtle()
    seg = {}
    # T1
    i0 = len(t.pts) - 1
    t.straight(120.0)
    seg["T1"] = (i0, len(t.pts) - 1)
    # H1: ac la dreapta, 9 m jos pe ~79 m
    arc_len = math.pi * R_HAIRPIN
    tot = LEAD * 2 + arc_len
    i0 = len(t.pts) - 1
    t.straight(LEAD, -9.0 * LEAD / tot)
    t.arc(R_HAIRPIN, 180.0, True, -9.0 * arc_len / tot)
    t.straight(LEAD, -9.0 * LEAD / tot)
    seg["H1"] = (i0, len(t.pts) - 1)
    i0 = len(t.pts) - 1
    t.straight(120.0)
    seg["T2"] = (i0, len(t.pts) - 1)
    i0 = len(t.pts) - 1
    t.straight(LEAD, -9.0 * LEAD / tot)
    t.arc(R_HAIRPIN, 180.0, False, -9.0 * arc_len / tot)
    t.straight(LEAD, -9.0 * LEAD / tot)
    seg["H2"] = (i0, len(t.pts) - 1)
    i0 = len(t.pts) - 1
    t.straight(120.0)
    seg["T3"] = (i0, len(t.pts) - 1)
    # tura de intoarcere: 18 m sus pe restul lungimii (calculata dupa)
    ret_start = len(t.pts) - 1
    ret_y0 = t.y
    R = 40.0
    t.straight(40.0)
    t.arc(R, 90.0, False)           # spre -Z (nord)
    t.straight(4.0 * R_HAIRPIN + 40.0)
    t.arc(R, 90.0, False)           # spre -X
    i_exc0 = len(t.pts) - 1
    t.straight(400.0)               # dreapta excavatorului
    seg["EXC"] = (i_exc0, len(t.pts) - 1)
    t.arc(R, 90.0, False)           # spre +Z
    t.straight(40.0)
    t.arc(R, 90.0, False)           # spre +X, pe z = 0
    t.straight(240.0 - 0.0)         # pana la (0,0)
    # urcarea: liniar pe distanta, pe tot turul de intoarcere
    pts = t.pts
    ret = pts[ret_start:]
    d = [0.0]
    for a, b in zip(ret, ret[1:]):
        d.append(d[-1] + math.hypot(b[0] - a[0], b[2] - a[2]))
    total = d[-1]
    climb = Y_TOP - ret_y0
    for k in range(len(ret)):
        x, y, z = ret[k]
        pts[ret_start + k] = (x, ret_y0 + climb * d[k] / total, z)
    seg["RET"] = (ret_start, len(pts) - 1)
    # ultimul punct = primul (bucla inchisa): il scoatem
    last = pts[-1]
    assert abs(last[0]) < 0.5 and abs(last[2]) < 0.5, last
    pts.pop()
    return pts, seg


# --- text .tscn ---------------------------------------------------------


def vec(v):
    return "Vector3(%.3f, %.3f, %.3f)" % v


def curve_data(points, closed):
    flat = []
    for p in points:
        flat += [0, 0, 0, 0, 0, 0, p[0], p[1], p[2]]
    pts = ", ".join(("%.3f" % v).rstrip("0").rstrip(".") if "." in ("%.3f" % v) else "%d" % v
                    for v in flat)
    tilts = ", ".join("0" for _ in points)
    return ("closed = true\n" if closed else "") + (
        '_data = {\n"points": PackedVector3Array(%s),\n"tilts": PackedFloat32Array(%s)\n}\n'
        "point_count = %d\n" % (pts, tilts, len(points)))


def load_csv():
    if not os.path.exists(CSV):
        return None
    rows = []
    with open(CSV, newline="") as f:
        for r in csv.DictReader(f):
            rows.append((float(r["x"]), float(r["y"]), float(r["z"]),
                         float(r["half_width"]), float(r["frac"])))
    return rows


def nearest_frac(rows, x, z):
    best, bf = 1e18, 0.0
    for (rx, ry, rz, hw, fr) in rows:
        d = (rx - x) ** 2 + (rz - z) ** 2
        if d < best:
            best, bf = d, fr
    return bf


# --- camioanele ----------------------------------------------------------

TRUCK_SPEED = 8.0
TRUCK_PERIOD = 110.0   # brief §3: bucla camioanelor ~110 s
TRUCK_LANE = 0.5       # centrul camionului la 0.5 * half_width de axa, pe STANGA cursei


def truck_curve(rows, seg_fr):
    """Curba camionului: axa REALA coapta (rows), parcursa INVERS, decalata pe
    stanga cursei; deschisa la ambele capete (BusHazard o parcurge o singura
    data, apoi se ascunde â€” vezi bus_hazard.gd `_advance`)."""
    f_start = seg_fr["T3"][1]       # capatul de jos al T3
    n = len(rows)
    ia = min(range(n), key=lambda i: abs(rows[i][4] - f_start))
    pts = []
    last = None
    for i in range(ia, -1, -1):     # de la jos inapoi spre punctul 0, invers cursei
        x, y, z, hw, fr = rows[i]
        j = min(i + 1, n - 1)
        k = max(i - 1, 0)
        dx = rows[j][0] - rows[k][0]
        dz = rows[j][2] - rows[k][2]
        L = math.hypot(dx, dz)
        dx, dz = dx / L, dz / L           # directia CURSEI
        # dreapta cursei = dir x UP: dir=(1,0) in (x,z) -> +Z = (-dz, dx)
        rx, rz = -dz, dx
        lane = -TRUCK_LANE * hw           # stanga cursei = negativ
        px, pz = x + rx * lane, z + rz * lane
        if last is not None and math.hypot(px - last[0], pz - last[2]) < 5.0:
            continue
        pts.append((px, y, pz))
        last = pts[-1]
    x0, y0, z0 = pts[0]
    # intrare din afara drumului (nord-est de capatul T3, in interiorul buclei)
    entry = [(x0 + 45.0, y0, z0 - 22.0), (x0 + 22.0, y0, z0 - 7.0)]
    xe, ye, ze = pts[-1]
    # iesire pe dreapta camionului (nord), dincolo de inceputul T1
    exit_ = [(xe - 8.0, ye, ze - 7.0), (xe - 16.0, ye, ze - 20.0), (xe - 18.0, ye, ze - 34.0)]
    return entry + pts + exit_


def curve_len(pts):
    return sum(math.hypot(b[0] - a[0], b[2] - a[2]) for a, b in zip(pts, pts[1:]))


def main():
    pts, seg = build_route()
    rows = load_csv()
    exts = [
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
        '[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="2_marker"]',
        '[ext_resource type="Script" path="res://scenes/hazards/bus_hazard.gd" id="3_bus"]',
        '[ext_resource type="PackedScene" path="res://assets/models/baikal/vehicles/kamaz_truck.glb" id="4_kamaz"]',
    ]
    subs = ['[sub_resource type="Curve3D" id="Curve3D_route"]\n' + curve_data(pts, True)]
    fr = {}
    props = []
    props.append('custom_name = "Sonda Carrara"')
    props.append('custom_theme = "desert"')
    props.append('custom_world_seed_name = "sonda_carrara"')
    props.append("custom_half_width = %.1f" % HW_TERRACE)
    props.append('custom_gate_model = "none"')
    meta = []
    truck_nodes = []
    if rows:
        for name, (a, b) in seg.items():
            xa, _, za = pts[a]
            xb, _, zb = pts[min(b, len(pts) - 1)]
            fr[name] = (nearest_frac(rows, xa, za), nearest_frac(rows, xb, zb))
        fr["T1"] = (0.0, fr["T1"][1])
        print("fractii reale:", {k: (round(v[0], 4), round(v[1], 4)) for k, v in fr.items()})
        pinch = [(fr["H1"][0], fr["H1"][1], HW_HAIRPIN), (fr["H2"][0], fr["H2"][1], HW_HAIRPIN)]
        props.append("custom_width_pinches = Array[Vector3]([%s])" % ", ".join(
            "Vector3(%.4f, %.4f, %.1f)" % p for p in pinch))
        props.append("custom_width_segments = Array[Vector3]([Vector3(%.4f, %.4f, %.1f)])" % (
            fr["EXC"][0] + 0.004, fr["EXC"][1] - 0.004, HW_EXC))
        if os.environ.get("NO_TERRAIN") != "1":
            # golul pe partea in cadere a fiecarei terase + exteriorul acelor
            # (cornise de 9 m, ca terasa de dedesubt), peretele pe partea
            # dinspre deal (debleu).
            rav = [
                (fr["T1"][0] + 0.002, fr["T1"][1], 9, 1),
                (fr["T2"][0], fr["T2"][1], 9, -1),
                (fr["T3"][0], fr["T3"][1], 9, 1),
            ]
            if os.environ.get("RAV_HAIRPIN", "1") == "1":
                rav += [(fr["H1"][0], fr["H1"][1], 9, -1),
                        (fr["H2"][0], fr["H2"][1], 9, 1)]
            props.append("custom_ravines = Array[Vector4]([%s])" % ", ".join(
                "Vector4(%.4f, %.4f, %d, %d)" % r for r in rav))
            props.append("custom_cornice_ravines = Array[int]([%s])" % ", ".join(
                str(i) for i in range(len(rav))))
            props.append("custom_ravine_widths = Array[Vector2]([%s])" % ", ".join(
                "Vector2(%d, 14)" % i for i in range(len(rav))))
            cut = [
                (fr["T1"][0] + 0.002, fr["T1"][1], Y_TOP + 8.0, -1),
                (fr["T2"][0], fr["T2"][1], Y_TOP - 9.0 + 8.0, 1),
                (fr["T3"][0], fr["T3"][1], Y_TOP - 18.0 + 8.0, -1),
            ]
            props.append("custom_cuttings = Array[Vector4]([%s])" % ", ".join(
                "Vector4(%.4f, %.4f, %.1f, %d)" % c for c in cut))
        hint = os.environ.get("HINT")
        cor = []
        if hint:
            # "tine interiorul" (brief par.3): culoar impus pe banda DREAPTA a cursei
            # (lat +HINT * hw) pe ace + 20 m inainte/dupa
            ext = 0.012
            if os.environ.get("HINT_ALL") == "1":
                # tot coborasul: un singur culoar de la linia de start pana la
                # capatul T3 (terasele, nu doar acele)
                cor.append((0.0, fr["T3"][1] + ext, float(hint)))
            else:
                cor += [(fr[z][0] - ext, fr[z][1] + ext, float(hint)) for z in ("H1", "H2")]
        if os.environ.get("HINT_EXC"):
            # excavator: banda libera (stanga, linie negativa) pe dreapta de 400 m
            cor.append((fr["EXC"][0] - 0.01, fr["EXC"][1], float(os.environ["HINT_EXC"])))
        if cor:
            props.append("custom_lane_corridors = Array[Vector3]([%s])" % ", ".join(
                "Vector3(%.4f, %.4f, %.2f)" % c for c in cor))
        zones = ", ".join('"%s": Vector2(%.4f, %.4f)' % (k, v[0], v[1])
                          for k, v in fr.items() if k != "RET")
        meta.append("metadata/zones = {%s}" % zones)
        tc = truck_curve(rows, fr)
        tl = curve_len(tc)
        travel = tl / TRUCK_SPEED
        # defazaj de o jumatate de ciclu intre cele doua camioane, in secunde
        phase_b = (TRUCK_PERIOD * 0.5 * TRUCK_SPEED) / tl
        print("curba camion: %d puncte, %.1f m, %.1f s la %.1f m/s, perioada %.0f s, phase B %.3f" % (
            len(tc), tl, travel, TRUCK_SPEED, TRUCK_PERIOD, phase_b))
        assert phase_b < 1.0, "perioada prea mare pentru lungimea curbei"
        subs.append('[sub_resource type="Curve3D" id="Curve3D_truck"]\n' + curve_data(tc, False))
        for nm, ph in (("CamionA", 0.0), ("CamionB", phase_b)):
            truck_nodes += [
                '[node name="%s" type="Path3D" parent="Hazarduri"]' % nm,
                'script = ExtResource("3_bus")',
                'curve = SubResource("Curve3D_truck")',
                'speed = %.1f' % TRUCK_SPEED,
                'period = %.1f' % TRUCK_PERIOD,
                'phase = %.4f' % ph,
                'nose_side = 1',
                'nose_angle_deg = 20.0',
                'apex_outer_m = %s' % os.environ.get("APEX", "1.0"),
                'apex_radius_m = 15.0',
                'shove = 3.0',
                'side_accel = 8.0',
                'model = ExtResource("4_kamaz")',
                'model_yaw = %s' % os.environ.get("TRUCK_YAW", "0"),
                '']

    scene = ['[gd_scene format=3]', '']
    scene += exts
    scene += ['']
    for sub in subs:
        scene += [sub, '']
    scene += ['[node name="SondaCarrara" type="Node3D"]', 'script = ExtResource("1_track")']
    scene += props
    scene += meta
    scene += ['', '[node name="Path" type="Path3D" parent="."]', 'curve = SubResource("Curve3D_route")', '']
    scene += ['[node name="Hazarduri" type="Node3D" parent="."]', '']
    a, b = seg["EXC"]
    mid = pts[(a + b) // 2]
    scene += ['[node name="Excavator" type="Marker3D" parent="Hazarduri"]',
              'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)' % mid,
              'script = ExtResource("2_marker")', 'kind = 7', '']
    scene += truck_nodes
    out = os.environ.get("OUT", OUT)
    open(out, "w", newline="\n").write("\n".join(scene) + "\n")
    print("scris", out, "puncte:", len(pts))


if __name__ == "__main__":
    main()
