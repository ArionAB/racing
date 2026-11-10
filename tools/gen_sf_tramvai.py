#!/usr/bin/env python3
"""Genereaza tools/SondaSfTramvai*.tscn: strada SINTETICA a sondei 1c San
Francisco (brief docs/track_briefs/san_francisco.md §7 pasul 1c). NU e Track25.

Intrebarea: `BusHazard` (camioanele din Carrara, validate cu AI-ul dar IN SENS
INVERS) merge ca TRAMVAI IN SENSUL CURSEI, pe o urcare de 11,5%, pe axul unei
strazi de 14 m? Plutonul trece de el fara `[blocaj]`, contactul e moale, iar cu
`ai_reads_lane` stins aceeasi sonda trebuie sa pice.

Bucla (TrackFromPath cere bucla inchisa), sensul +X, punctul 0 la (0, 0, 0):
  - LEAD m plat (faleza, POI A), racord 24 m la ~5,7%;
  - URCAREA: CLIMB m la GRADE (implicit 290 m la 11,5%), racord 24 m;
  - TOP m plat, ac de 180 la dreapta (R 30), intoarcerea paralela la 60 m care
    coboara liniar inapoi la cota 0, alt ac de 180, dreapta de grila (72 m).

Tramvaiul (BusHazard, cutie placeholder de 2,5 x 3,0 x 8,5 m) intra pe ax
dintr-o strada laterala (pe DREAPTA cursei) la TRAM_S0 m de la piciorul urcarii
si iese pe o strada laterala tot pe dreapta la TRAM_S1 m. Intrarea si iesirea
sunt oblice (~30 de grade), ca AI-ul sa-l citeasca deja pe cand intra pe ax
(`_bus_line` cere ca directia corpului sa fie paralela cu drumul).

DE CE NU TOATA URCAREA: brief-ul cere ~4,5 m/s si ciclu ~41 s, dar 290 m la
4,5 m/s inseamna 64 s de mers — mai mult decat ciclul. `BusHazard._advance`
ascunde corpul `max(period - drum/viteza, 0.5)` s, deci cu toata urcarea ciclul
real ar fi ~65 s. Implicit: o portiune de ax care incape in 41 s (S0 80 m ->
S1 208 m, plus intrarea si iesirea), adica tramvaiul e pe strada ~38 s din 41.

  python tools/gen_sf_tramvai.py                       # SondaSfTramvai.tscn
  SUFIX=Sabotaj AI=0 python tools/gen_sf_tramvai.py    # ai_reads_lane stins
  SUFIX=Plin TRAM_S0=0 TRAM_S1=290 PERIOD=70 python ... # toata urcarea
  EXIT=front SUFIX=Fwd python tools/gen_sf_tramvai.py  # iese drept, la coltul din varf

Variabile: GRADE (0.115), CLIMB (290), LEAD (96), HW (7.0), TRAM_SPEED (4.5),
PERIOD (41), PHASE (0.0), TRAM_S0 (70), TRAM_S1 (220), AI (1 = ai_reads_lane +
ai_same_direction), SOFT (1 = soft_contact), PITCH (1 = pitch_to_ground),
TAIL (0 = coada plata; grade = `tail_angle_deg`, coada oblica),
BODY (latime,inaltime,lungime: 2.5,3.0,8.5), SUFIX.
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STEP = 12.0
GRADE = float(os.environ.get("GRADE", "0.115"))
CLIMB = float(os.environ.get("CLIMB", "290"))
LEAD = float(os.environ.get("LEAD", "96"))
EASE = 24.0           # racord jos si sus (jumatate din panta)
TOP = 36.0
GRID = 72.0
R_TURN = 30.0
HALF_WIDTH = float(os.environ.get("HW", "7.0"))

TRAM_SPEED = float(os.environ.get("TRAM_SPEED", "4.5"))
PERIOD = float(os.environ.get("PERIOD", "41"))
# Faza de start: tramvaiul porneste la incarcarea pistei, deci la verde a mers
# deja 3,6 s (countdown-ul). La 0.74 iese de pe ax la ~1,5 s dupa verde, se
# ascunde la ~6,2 s si reapare in strada laterala la ~8,8 s, cand coada
# plutonului din turul 1 a trecut de gura ei (masurat: plutonul trece intre 6,4
# si 8,5 s). PHASE=0 = plutonul strans il prinde pe ax in turul 1 (stres).
# Cu EXIT=front faza echivalenta e 0.66: tramvaiul ajunge la capatul curbei
# (30 m dupa colt) la ~9,5 s dupa verde si reapare in strada laterala la ~11,9 s,
# dupa ce coada plutonului a trecut de gura ei (x ~307).
PHASE = float(os.environ.get("PHASE", "0.66" if os.environ.get("EXIT") == "front" else "0.74"))
TRAM_S0 = float(os.environ.get("TRAM_S0", "80"))
TRAM_S1 = float(os.environ.get("TRAM_S1", "208"))
SIDE_LAT = 12.0       # cat de departe de ax incepe/se termina strada laterala
SIDE_RUN = 18.0       # pe cati metri (de-a lungul) intra/iese oblic
BODY = tuple(float(v) for v in os.environ.get("BODY", "2.5,3.0,8.5").split(","))
# Pe unde PARASESTE tramvaiul strada cursei:
#   side  = intra si iese pe strazi laterale din dreapta (v1). MASURAT: cand
#           vireaza spre iesire taie banda din dreapta si prinde masinile care il
#           depasesc pe acolo (16 seed-uri: contactele sunt toate la iesire);
#   front = intra din strada laterala din dreapta, dar iese DREPT INAINTE in
#           varful urcarii, unde cursa coteste la dreapta 90 de grade (cum merge
#           o linie de tramvai reala: drept, iar strada cursei se rupe din ea —
#           POI B din brief: „viraj la dreapta si inca ~145 m de urcare").
EXIT = os.environ.get("EXIT", "side")
EXIT_RUN = float(os.environ.get("EXIT_RUN", "30"))   # front: cat merge drept dupa colt
NORTH = 60.0          # front: dreapta dintre cele doua viraje de 90
if EXIT == "front":
    TOP = float(os.environ.get("TOP", "12"))
    TRAM_S1 = CLIMB + EASE + TOP
    TRAM_S0 = float(os.environ.get("TRAM_S0", "205"))


class Turtle:
    """0 = +X, dreapta (spre +Z) = theta creste (ca gen_sf_sonda.py)."""

    def __init__(self):
        self.x, self.z, self.y, self.th = 0.0, 0.0, 0.0, 0.0
        self.pts = [(0.0, 0.0, 0.0)]

    def straight(self, length, dy=0.0):
        n = max(1, int(round(length / STEP)))
        for k in range(1, n + 1):
            t = k / n
            self.pts.append((self.x + math.cos(self.th) * length * t,
                             self.y + dy * t,
                             self.z + math.sin(self.th) * length * t))
        self.x += math.cos(self.th) * length
        self.z += math.sin(self.th) * length
        self.y += dy

    def arc(self, radius, angle_deg, right, npts=5):
        sgn = 1.0 if right else -1.0
        cx = self.x + math.cos(self.th + sgn * math.pi / 2) * radius
        cz = self.z + math.sin(self.th + sgn * math.pi / 2) * radius
        a0 = math.atan2(self.z - cz, self.x - cx)
        total = math.radians(angle_deg) * sgn
        for k in range(1, npts):
            a = a0 + total * k / (npts - 1)
            self.pts.append((cx + math.cos(a) * radius, self.y, cz + math.sin(a) * radius))
        a1 = a0 + total
        self.x = cx + math.cos(a1) * radius
        self.z = cz + math.sin(a1) * radius
        self.th += total


def build():
    t = Turtle()
    t.straight(LEAD)
    x_foot = t.x + EASE                     # piciorul urcarii (inceputul pantei pline)
    y_ease = EASE * GRADE * 0.5
    t.straight(EASE, y_ease)
    y_foot = t.y
    t.straight(CLIMB, CLIMB * GRADE)
    t.straight(EASE, y_ease)
    t.straight(TOP)
    street_end = t.x
    y_top = t.y
    if EXIT == "front":
        t.arc(R_TURN, 90.0, True)
        t.straight(NORTH)
        t.arc(R_TURN, 90.0, True)
    else:
        t.arc(R_TURN, 180.0, True)
    a = len(t.pts) - 1
    t.straight(street_end + GRID)
    b = len(t.pts) - 1
    if EXIT == "front":
        t.arc(R_TURN, 90.0, True)
        t.straight(NORTH)
        t.arc(R_TURN, 90.0, True)
    else:
        t.arc(R_TURN, 180.0, True)
    t.straight(GRID)
    pts = t.pts
    n = b - a
    for k in range(n + 1):
        x, _, z = pts[a + k]
        pts[a + k] = (x, y_top * (1.0 - k / n), z)
    for k in range(b + 1, len(pts)):
        x, _, z = pts[k]
        pts[k] = (x, 0.0, z)
    last = pts.pop()
    assert abs(last[0]) < 0.5 and abs(last[2]) < 0.5, last
    return pts, x_foot, y_foot, y_top, street_end


def road_y(x, x_foot, y_foot):
    """Cota axului pe dreapta de start/urcare (z = 0), analitic."""
    x0 = x_foot - EASE
    if x <= x0:
        return 0.0
    if x <= x_foot:
        return (x - x0) * GRADE * 0.5
    x2 = x_foot + CLIMB
    if x <= x2:
        return y_foot + (x - x_foot) * GRADE
    if x <= x2 + EASE:
        return y_foot + CLIMB * GRADE + (x - x2) * GRADE * 0.5
    return y_foot + CLIMB * GRADE + EASE * GRADE * 0.5


def tram_curve(x_foot, y_foot):
    """Curba deschisa a tramvaiului: din strada laterala din dreapta (+Z), pe
    ax de la S0 la S1, inapoi in strada laterala din dreapta."""
    xa = x_foot + TRAM_S0
    xb = x_foot + TRAM_S1
    pts = []
    # intrare oblica: (xa - SIDE_RUN, +SIDE_LAT) -> (xa, 0)
    for k in range(0, 4):
        u = k / 3.0
        x = xa - SIDE_RUN * (1.0 - u)
        z = SIDE_LAT * (1.0 - u) ** 1.6
        pts.append((x, road_y(x, x_foot, y_foot), z))
    nseg = max(1, int(round((xb - xa) / STEP)))
    for k in range(1, nseg + 1):
        x = xa + (xb - xa) * k / nseg
        pts.append((x, road_y(x, x_foot, y_foot), 0.0))
    if EXIT == "front":
        # drept inainte, peste coltul unde cursa vireaza la dreapta
        for k in range(1, 4):
            x = xb + EXIT_RUN * k / 3.0
            pts.append((x, road_y(x, x_foot, y_foot), 0.0))
        return pts
    for k in range(1, 4):
        u = k / 3.0
        x = xb + SIDE_RUN * u
        z = SIDE_LAT * u ** 1.6
        pts.append((x, road_y(x, x_foot, y_foot), z))
    return pts


def curve_data(points, closed):
    flat = []
    for p in points:
        flat += [0, 0, 0, 0, 0, 0, p[0], p[1], p[2]]
    txt = ", ".join(("%.3f" % v).rstrip("0").rstrip(".") for v in flat)
    tilts = ", ".join("0" for _ in points)
    return (("closed = true\n" if closed else "") +
            '_data = {\n"points": PackedVector3Array(%s),\n'
            '"tilts": PackedFloat32Array(%s)\n}\npoint_count = %d\n' % (txt, tilts, len(points)))


def plen(pts, closed):
    seq = list(zip(pts, pts[1:] + (pts[:1] if closed else [])))
    return sum(math.dist(a, b) for a, b in seq)


def main():
    pts, x_foot, y_foot, y_top, street_end = build()
    total = plen(pts, True)
    tc = tram_curve(x_foot, y_foot)
    tl = plen(tc, False)
    travel = tl / TRAM_SPEED
    ai = os.environ.get("AI", "1") == "1"
    soft = os.environ.get("SOFT", "1") == "1"
    pitch = os.environ.get("PITCH", "1") == "1"
    suffix = os.environ.get("SUFIX", "")
    name = "SondaSfTramvai" + suffix
    # zonele pe fractie (lungimea poligonului; spline-ul scurteaza doar acele)
    f_foot = (x_foot - EASE) / total
    f_top = (x_foot + CLIMB + EASE) / total
    f_tram0 = (x_foot + TRAM_S0 - SIDE_RUN) / total
    f_tram1 = (x_foot + TRAM_S1 + (0.0 if EXIT == "front" else SIDE_RUN)) / total
    scene = [
        "[gd_scene format=3]", "",
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
        '[ext_resource type="Script" path="res://scenes/hazards/bus_hazard.gd" id="2_bus"]', "",
        '[sub_resource type="Curve3D" id="Curve3D_route"]\n' + curve_data(pts, True), "",
        '[sub_resource type="Curve3D" id="Curve3D_tram"]\n' + curve_data(tc, False), "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_track")',
        'custom_name = "Sonda SF tramvai%s"' % (" " + suffix if suffix else ""),
        'custom_theme = "desert"',
        'custom_world_seed_name = "sonda_sf_tramvai"',
        "custom_half_width = %.1f" % HALF_WIDTH,
        'custom_gate_model = "none"',
        'metadata/zones = {"A": Vector2(0.0, %.4f), "B": Vector2(%.4f, %.4f), "T": Vector2(%.4f, %.4f), "B2": Vector2(%.4f, %.4f)}' % (
            f_foot, f_foot, f_tram0, f_tram0, f_tram1, f_tram1, f_top),
        'metadata/zone_default = "RET"',
        "metadata/sf_tram = {\"exit\": \"%s\", \"grade\": %.3f, \"climb\": %.1f, \"x_foot\": %.2f, \"s0\": %.1f, \"s1\": %.1f, \"speed\": %.2f, \"period\": %.1f, \"phase\": %.4f}" % (
            EXIT, GRADE, CLIMB, x_foot, TRAM_S0, TRAM_S1, TRAM_SPEED, PERIOD, PHASE),
        "",
        '[node name="Path" type="Path3D" parent="."]',
        'curve = SubResource("Curve3D_route")', "",
        '[node name="Hazarduri" type="Node3D" parent="."]', "",
        '[node name="Tramvai" type="Path3D" parent="Hazarduri"]',
        'script = ExtResource("2_bus")',
        'curve = SubResource("Curve3D_tram")',
        "speed = %.2f" % TRAM_SPEED,
        "phase = %.4f" % PHASE,
        "period = %.1f" % PERIOD,
        "body_size = Vector3(%.2f, %.2f, %.2f)" % BODY,
        "nose_side = 1",
        "nose_angle_deg = 20.0",
        "tail_angle_deg = %s" % os.environ.get("TAIL", "0"),
        "apex_outer_m = 0.0",
        "shove = 3.0",
        "side_accel = 8.0",
        "ai_reads_lane = %s" % ("true" if ai else "false"),
        "ai_same_direction = %s" % ("true" if ai else "false"),
        "soft_contact = %s" % ("true" if soft else "false"),
        "pitch_to_ground = %s" % ("true" if pitch else "false"),
        "",
    ]
    out = os.path.join(ROOT, "tools", name + ".tscn")
    open(out, "w", newline="\n").write("\n".join(scene))
    print("scris %s: bucla %d puncte, %.0f m; urcare %.0f m la %.1f%% (+%.1f m, varf %.1f m); "
          "tramvai %.0f m de curba (ax %.0f -> %.0f m), %.1f s la %.1f m/s, perioada %.0f s "
          "(ascuns %.1f s), phase %.3f; zone A<%.3f B %.3f-%.3f T %.3f-%.3f B2 -%.3f" % (
              os.path.relpath(out, ROOT), len(pts), total, CLIMB, GRADE * 100, CLIMB * GRADE,
              y_top, tl, TRAM_S0, TRAM_S1, travel, TRAM_SPEED, PERIOD,
              max(PERIOD - travel, 0.5), PHASE, f_foot, f_foot, f_tram0, f_tram0, f_tram1, f_top))


if __name__ == "__main__":
    sys.exit(main())
