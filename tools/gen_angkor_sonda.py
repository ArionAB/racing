#!/usr/bin/env python3
"""Genereaza tools/SondaAngkor*.tscn: pista SINTETICA a sondelor tehnice Angkor
(brief docs/track_briefs/angkor.md §7 pasul 1). NU e Track24.

Patru laturi de dreptunghi, fiecare cu o mecanica din brief, fara decor:
  latura 1 (spre +X)  POARTA DE SUD: doi piloni lasa o deschidere de 7 m pe un drum
                      de 9 m, iar ELEFANTUL traverseaza piata la 22 m dupa poarta (D);
  latura 2 (spre +Z)  BAYON: drum de 14 m cu 3 turnuri de 3 x 3 m pe carosabil (E);
  latura 3 (spre -X)  TERASA ELEFANTILOR: rampa la +10 m, coama de 110 m, creasta
                      care cade la +5 — SARITURA Regelui Lepros (F);
  latura 4 (spre -Z)  TA PROHM: drumul principal ocoleste in arc (~150 m), ramura
                      dreapta (6 m, ~110 m) trece prin galerie, cu DOMINOUL de 3
                      blocuri si radacina-rampa la iesire (G).

Variante (o scena per varianta, comparate pe DISTRIBUTII de 16 seed-uri):
  SondaAngkor.tscn       toate hazardurile
  SondaAngkorGol.tscn    aceeasi geometrie, FARA elefant si FARA domino (martorul)

    python tools/gen_angkor_sonda.py
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HW = 4.5            # drum de 9 m
HW_BAYON = 7.0      # 14 m pe terasa Bayonului
HW_BRANCH = 3.0     # galeria de 6 m
R_CORNER = 30.0
STEP = 12.0

# Cote (m)
Y0 = 0.0
Y_TERRACE = 10.0
Y_LAND = 5.0

# Pozitii-cheie
GATE_X = 180.0          # pilonii portii pe latura 1
ELEPHANT_X = 202.0      # traversarea elefantului
X_RIGHT = 330.0         # latura 2
Z_FAR = 260.0           # latura 3
X_LEFT = -30.0          # latura 4 (ramura)
BULGE_X = -78.0         # drumul principal ocoleste incinta
BAYON_TOWERS = [        # (z pe latura 2, offset lateral fata de axa spre +X)
    (95.0, -3.2), (130.0, 3.0), (165.0, -2.6),
]
DOMINO_Z = [175.0, 150.0, 125.0]   # blocurile, in ordinea caderii (spre masina)
DOMINO_DT = 1.2


def arc(cx, cz, r, a0, a1, n, y):
    return [(cx + r * math.cos(a0 + (a1 - a0) * k / (n - 1)), y,
             cz + r * math.sin(a0 + (a1 - a0) * k / (n - 1))) for k in range(n)]


def line(x0, z0, x1, z1, y0, y1, include_start=False):
    L = math.hypot(x1 - x0, z1 - z0)
    n = max(1, int(math.ceil(L / STEP)))
    pts = []
    for k in range(0 if include_start else 1, n + 1):
        t = k / n
        pts.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, z0 + (z1 - z0) * t))
    return pts


def route():
    P = [(0.0, Y0, 0.0)]
    # latura 1: start -> poarta -> piata -> colt
    P += line(0, 0, X_RIGHT - R_CORNER, 0, Y0, Y0)
    P += arc(X_RIGHT - R_CORNER, R_CORNER, R_CORNER, -math.pi / 2, 0.0, 4, Y0)[1:]
    # latura 2: Bayon (drept, z 30 -> 230)
    P += line(X_RIGHT, R_CORNER, X_RIGHT, Z_FAR - R_CORNER, Y0, Y0)
    P += arc(X_RIGHT - R_CORNER, Z_FAR - R_CORNER, R_CORNER, 0.0, math.pi / 2, 4, Y0)[1:]
    # latura 3: rampa x 300 -> 210 (Y0 -> +10), coama 210 -> 96, creasta, aterizare la +5,
    # coborare spre colt.
    x = X_RIGHT - R_CORNER
    P += line(x, Z_FAR, 210, Z_FAR, Y0, Y_TERRACE)
    P += line(210, Z_FAR, 96, Z_FAR, Y_TERRACE, Y_TERRACE)
    # Creasta: un singur punct la 12 m, 4.5 m mai jos (37%): Catmull-Rom o rotunjeste,
    # dar la viteza de cursa masina pleaca de pe ea.
    P.append((84.0, Y_LAND + 0.5, Z_FAR))
    P += line(84, Z_FAR, 30, Z_FAR, Y_LAND, Y_LAND)
    P += line(30, Z_FAR, X_LEFT + R_CORNER, Z_FAR, Y_LAND, Y0)
    P += arc(X_LEFT + R_CORNER, Z_FAR - R_CORNER, R_CORNER, math.pi / 2, math.pi, 4, Y0)[1:]
    # latura 4: drumul principal ocoleste incinta (arc spre -X), ramura e dreapta.
    z_top = Z_FAR - R_CORNER   # 230
    P += line(X_LEFT, z_top, X_LEFT, 205, Y0, Y0)
    # ocolul: un semicerc aplatizat intre z 205 si z 55, varful la BULGE_X
    for k in range(1, 12):
        t = k / 12.0
        z = 205.0 - 150.0 * t
        xx = X_LEFT + (BULGE_X - X_LEFT) * math.sin(math.pi * t)
        P.append((xx, Y0, z))
    P += line(X_LEFT, 55, X_LEFT, R_CORNER, Y0, Y0)
    P += arc(X_LEFT + R_CORNER, R_CORNER, R_CORNER, math.pi, 1.5 * math.pi, 4, Y0)[1:-1]
    return P


def branch():
    """Mijlocul ramurii (capetele se lipesc singure de bucla, la < 25 m). Radacina-rampa:
    o cocoasa de 1.2 m la 18 m inainte de iesire."""
    pts = []
    z = 196.0
    while z > 66.0:
        y = Y0
        if 76.0 <= z <= 84.0:
            y = 1.2 * (1.0 - abs(z - 80.0) / 4.0)
        pts.append((X_LEFT, y, z))
        z -= 10.0
    return pts


def curve_res(rid, pts, closed):
    flat = []
    for x, y, z in pts:
        flat += ["0", "0", "0", "0", "0", "0", f"{x:.3f}", f"{y:.3f}", f"{z:.3f}"]
    return (f'[sub_resource type="Curve3D" id="{rid}"]\n'
            + ("closed = true\n" if closed else "")
            + "_data = {\n"
            f'"points": PackedVector3Array({", ".join(flat)}),\n'
            f'"tilts": PackedFloat32Array({", ".join(["0"] * len(pts))})\n}}\n'
            f"point_count = {len(pts)}\n")


def frac_of(pts, pred):
    """Fractiile (pe lungimea poligonalei, aproape de Catmull-Rom) ale punctelor care
    satisfac `pred`: (min, max)."""
    n = len(pts)
    seg = [math.dist((pts[i][0], pts[i][2]), (pts[(i + 1) % n][0], pts[(i + 1) % n][2]))
           for i in range(n)]
    tot = sum(seg)
    acc, hits = 0.0, []
    for i in range(n):
        if pred(pts[i]):
            hits.append(acc / tot)
        acc += seg[i]
    return (min(hits), max(hits)) if hits else None


def frac_at(pts, x, z):
    """Fractia celui mai apropiat punct al poligonalei de (x, z), interpolata pe segment."""
    n = len(pts)
    seg = [math.dist((pts[i][0], pts[i][2]), (pts[(i + 1) % n][0], pts[(i + 1) % n][2]))
           for i in range(n)]
    tot = sum(seg)
    best, acc, bestf = 1e9, 0.0, 0.0
    for i in range(n):
        ax, az = pts[i][0], pts[i][2]
        bx, bz = pts[(i + 1) % n][0], pts[(i + 1) % n][2]
        dx, dz = bx - ax, bz - az
        t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / max(1e-9, dx * dx + dz * dz)))
        d = math.hypot(ax + t * dx - x, az + t * dz - z)
        if d < best:
            best, bestf = d, (acc + t * seg[i]) / tot
        acc += seg[i]
    return bestf


def box_shape(sid, size):
    return (f'[sub_resource type="BoxShape3D" id="{sid}"]\n'
            f"size = Vector3({size[0]}, {size[1]}, {size[2]})\n")


def scene(with_hazards, name, corridors=False, flip=1.0, towers=None, ai_mode="none"):
    towers = towers if towers is not None else BAYON_TOWERS
    P = route()
    lines = ["[gd_scene format=3]", "",
             '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
             '[ext_resource type="Script" path="res://scenes/tracks/track_branch.gd" id="2_branch"]',
             '[ext_resource type="Script" path="res://scenes/hazards/rim_boulder_hazard.gd" id="3_rim"]',
             '[ext_resource type="Script" path="res://scenes/tracks/hazard_marker.gd" id="4_hzm"]',
             '[ext_resource type="PackedScene" path="res://assets/models/serengeti/animals/elephant.glb" id="5_eleph"]',
             ""]
    lines.append(curve_res("Curve3D_main", P, True))
    lines.append(curve_res("Curve3D_branch", branch(), False))
    lines.append(box_shape("Box_pilon", (6.0, 12.0, 8.0)))
    lines.append(box_shape("Box_turn", (3.0, 9.0, 3.0)))
    bay = (frac_at(P, X_RIGHT, 60.0), frac_at(P, X_RIGHT, 200.0))
    gate = (frac_at(P, GATE_X - 8.0, 0.0), frac_at(P, GATE_X + 8.0, 0.0))
    lines += [f'[node name="{name}" type="Node3D"]',
              'script = ExtResource("1_track")',
              f'custom_name = "{name}"',
              'custom_theme = "angkor"',
              'custom_world_seed_name = "angkor_sonda"',
              f"custom_half_width = {HW}",
              'custom_gate_model = "none"',
              "custom_dirt_ranges = Array[Vector2]([Vector2(0, 1)])",
              f"custom_width_segments = Array[Vector3]([Vector3({bay[0]:.4f}, {bay[1]:.4f}, {HW_BAYON})])",
              f"custom_width_pinches = Array[Vector3]([Vector3({gate[0]:.4f}, {gate[1]:.4f}, 3.5)])",
              "traffic_count = 0"]
    if corridors:
        # Slalomul Bayonului: fiecare turn are culoarul pe partea LIBERA (semn + = dreapta
        # soselei, Track.lane_forced_at). Pe latura 2 se merge spre +Z, deci dreapta = -X:
        # un turn cu offset negativ in X sta pe DREAPTA si se trece pe stanga (-).
        segs = []
        for zt, off in towers:
            fc = frac_at(P, X_RIGHT, zt)
            side = (-0.45 if off < 0 else 0.45) * flip
            segs.append(f"Vector3({fc - 0.014:.4f}, {fc + 0.012:.4f}, {side})")
        lines.append(f"custom_lane_corridors = Array[Vector3]([{', '.join(segs)}])")
    if ai_mode == "chain":
        # Culoare INLANTUITE: fiecare incepe imediat dupa turnul precedent (primul, cu ~60 m
        # inainte), fiindca AI-ul citeste culoarul la indexul CURENT (ai_controller.gd:500).
        segs = []
        prev = frac_at(P, X_RIGHT, towers[0][0] - 60.0)
        for zt, off in towers:
            fc = frac_at(P, X_RIGHT, zt)
            side = -0.45 if off < 0 else 0.45
            segs.append(f"Vector3({prev:.4f}, {fc + 0.004:.4f}, {side})")
            prev = fc + 0.004
        lines.append(f"custom_lane_corridors = Array[Vector3]([{', '.join(segs)}])")
    elif ai_mode == "bias":
        # Tiparul stalpilor Carrara (#640): obstacole langa axa, trecere pe AMBELE parti, podea
        # de linie pe tot sectorul (Track.lane_floor_at) — pilotul ramane pe malul lui.
        a = frac_at(P, X_RIGHT, towers[0][0] - 45.0)
        b = frac_at(P, X_RIGHT, towers[-1][0] + 8.0)
        lines.append(f"custom_lane_bias = Array[Vector3]([Vector3({a:.4f}, {b:.4f}, 0.62)])")
    lines.append("")
    lines += ['[node name="Path" type="Path3D" parent="."]',
              'curve = SubResource("Curve3D_main")', ""]
    lines += ['[node name="Galeria" type="Path3D" parent="."]',
              'curve = SubResource("Curve3D_branch")',
              'script = ExtResource("2_branch")',
              f"branch_half_width = {HW_BRANCH}",
              'label = "Galeria Ta Prohm"',
              "speed_factor = 0.85",
              "bumpiness = 0.08", ""]
    # Pilonii portii: corpuri statice de o parte si de alta a deschiderii de 7 m.
    lines += ['[node name="Obstacole" type="StaticBody3D" parent="."]', ""]
    # Cutia are 8 m pe Z (jumatate 4): centrul la 3,5 + 4 lasa EXACT 7 m intre piloni.
    for i, zc in enumerate((3.5 + 4.0, -(3.5 + 4.0))):
        lines += [f'[node name="Pilon{i}" type="CollisionShape3D" parent="Obstacole"]',
                  f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {GATE_X}, 6, {zc})",
                  'shape = SubResource("Box_pilon")', ""]
    for i, (zt, off) in enumerate(towers):
        lines += [f'[node name="Turn{i}" type="CollisionShape3D" parent="Obstacole"]',
                  f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {X_RIGHT + off}, 4.5, {zt})",
                  'shape = SubResource("Box_turn")', ""]
    lines += ['[node name="Hazarduri" type="Node3D" parent="."]', ""]
    if with_hazards:
        # Dominoul: rim_offset/height pe minimul clasei (blocul pleaca din marginea boltii).
        # +X local spre peretele de pe care cade: aici zidul e spre -X (exteriorul ramurii).
        for i, zd in enumerate(DOMINO_Z):
            lines += [f'[node name="Domino{i}" type="Node3D" parent="Hazarduri"]',
                      f"transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, {X_LEFT}, 0, {zd})",
                      'script = ExtResource("3_rim")',
                      "period = 11.0",
                      f"start_clock = {i * DOMINO_DT:.1f}",
                      "rim_offset = 2.0",
                      "rim_height = 6.0",
                      "crush_seconds = 3.0",
                      "invert_steer = false", ""]
        lines += ELEPHANT_NODE
    return "\n".join(lines)


# Elefantul (tiparul G_Elefant din Track14): SlidingHazard TRAVERSARE prin HazardMarker, in
# piata de DUPA poarta. sweep_speed 3 m/s -> ciclul ~23 s pe 9 m (2 x (5 + 1,2 + perioada/2));
# la 1,5 m/s ar fi ~34 s. `ai_yields`: AI-ul il vede prin CROSSING_GROUP (incetineste la
# 14 m/s si ocoleste pe partea libera, nu se opreste) — aceeasi informatie ca jucatorul.
ELEPHANT_NODE: list = [
    '[node name="Elefant" type="Marker3D" parent="Hazarduri"]',
    f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {ELEPHANT_X}, 0, 0)",
    'script = ExtResource("4_hzm")',
    'model = ExtResource("5_eleph")',
    'model_classes = {\n"Elephant_Mesh_Accente": "tri:elephant_hide"\n}',
    "face_travel = true",
    "follow_ground = true",
    "motion = 1",
    "sweep_speed = 3.0",
    "ai_yields = true", ""]


if __name__ == "__main__":
    for hz, fn, nm, cor in ((True, "SondaAngkor.tscn", "SondaAngkor", False),
                            (True, "SondaAngkorCor.tscn", "SondaAngkorCor", True),
                            (True, "SondaAngkorCorInv.tscn", "SondaAngkorCorInv", "inv"),
                            (True, "SondaAngkorLant.tscn", "SondaAngkorLant", "lant"),
                            (True, "SondaAngkorAxa.tscn", "SondaAngkorAxa", "axa"),
                            (False, "SondaAngkorGol.tscn", "SondaAngkorGol", False)):
        with open(os.path.join(ROOT, "tools", fn), "w", encoding="utf-8", newline="\n") as f:
            if cor == "lant":
                f.write(scene(hz, nm, False, 1.0, [(100.0, -3.2), (170.0, 3.0)], "chain"))
            elif cor == "axa":
                f.write(scene(hz, nm, False, 1.0, [(95.0, -1.0), (135.0, 1.0), (175.0, -1.0)], "bias"))
            else:
                f.write(scene(hz, nm, bool(cor), -1.0 if cor == "inv" else 1.0))
    P = route()
    L = sum(math.dist((a[0], a[2]), (b[0], b[2])) for a, b in zip(P, P[1:] + P[:1]))
    print(f"puncte {len(P)}, lungime ~{L:.0f} m")
    for nm, (x, z) in (("poarta", (GATE_X, 0.0)), ("elefant", (ELEPHANT_X, 0.0)),
                       ("bayon 60", (X_RIGHT, 60.0)), ("bayon 200", (X_RIGHT, 200.0)),
                       ("creasta", (84.0, Z_FAR)), ("ramura intrare", (X_LEFT, 205.0)),
                       ("ramura iesire", (X_LEFT, 55.0))):
        print(f"  {nm:15s} frac {frac_at(P, x, z):.3f}")
    for i, (zt, off) in enumerate(BAYON_TOWERS):
        print(f"  turn{i} frac {frac_at(P, X_RIGHT, zt):.3f} offset {off}")
