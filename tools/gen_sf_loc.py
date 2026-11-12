#!/usr/bin/env python3
"""Genereaza tools/SfLoc.tscn: STRADA SINTETICA a testului de loc San Francisco
(docs/track_briefs/san_francisco.md §7 pasul 0). NU e Track25 si nu intra in
GameState.TRACK_SCENES: se captureaza cu `tools/Snapshot.tscn -- --scene=...`.

    python tools/gen_sf_loc.py

Geometria (nord = -Z, est = +X, conventia temei):
  - strada coboara spre NORD pe x = 0: platou de sus (y 26, z 96..24), MUCHIA 1
    la z = 24, blocul lantului (profilul `plan28s` din gen_sf_sonda.py: 28% pe
    doi pasi de 12 m, apoi racord), intersectia plata de 24 m, MUCHIA 2 la
    z = -48, al doilea bloc, apoi o coborare blanda pana la chei (y 3,2);
  - cheiul merge spre est de-a lungul golfului (z = -168), intoarcerea urca pe
    x = 180 inapoi la platou, iar latura de sud (z = 120) inchide bucla;
  - GOLFUL e poligonul `custom_lagoon` de la nord de chei (z -178..-285), cu apa
    la ~1,2 m (`custom_sea_level_offset` calculat din media soselei).

Pas uniform de 12 m pe drepte (memoria spline-ului: pasul mixt il supraincarca),
arce de raza 24 m cu pas de 30 de grade (12,6 m).
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "tools", "SfLoc.tscn")

Y_TOP = 26.0
BLOCK = [0.0, -3.4, -6.8, -8.8, -9.6]  # plan28s: bloc de 48 m, cadere 9,6 m
Y_QUAY = 3.2
SEA_Y = 1.2
R = 24.0


def arc(cx, cz, y, a0, a1, steps=3):
    """Puncte pe arc (fara capete), unghiuri in grade, (x, z) = c + R (cos, sin)."""
    pts = []
    for i in range(1, steps):
        a = math.radians(a0 + (a1 - a0) * i / steps)
        pts.append((cx + R * math.cos(a), y, cz + R * math.sin(a)))
    return pts


def route():
    p = []
    # platoul de sus: z 96 .. 24 (MUCHIA 1 = ultimul punct plat)
    for z in range(96, 23, -12):
        p.append((0.0, Y_TOP, float(z)))
    y1 = Y_TOP
    # blocul 1: z 12 .. -24
    for i in range(1, len(BLOCK)):
        p.append((0.0, y1 + BLOCK[i], 24.0 - 12.0 * i))
    y2 = y1 + BLOCK[-1]
    # intersectia plata: -36, -48 (MUCHIA 2)
    p.append((0.0, y2, -36.0))
    p.append((0.0, y2, -48.0))
    for i in range(1, len(BLOCK)):
        p.append((0.0, y2 + BLOCK[i], -48.0 - 12.0 * i))
    y3 = y2 + BLOCK[-1]
    # coborarea blanda spre chei: -108 .. -144
    for z, y in ((-108.0, 5.6), (-120.0, 4.4), (-132.0, 3.6), (-144.0, Y_QUAY)):
        p.append((0.0, y, z))
    assert abs(y3 - 6.8) < 1e-6
    # viraj spre est (centru 24, -144), 180 -> 270
    p += arc(24.0, -144.0, Y_QUAY, 180.0, 270.0)
    # cheiul: z = -168, x 24 .. 156
    for x in range(24, 157, 12):
        p.append((float(x), Y_QUAY, -168.0))
    # viraj spre sud (centru 156, -144), 270 -> 360
    p += arc(156.0, -144.0, Y_QUAY, 270.0, 360.0)
    # intoarcerea: x = 180, z -144 .. 96, urca liniar la platou
    zs = list(range(-144, 97, 12))
    for z in zs:
        t = (z + 144.0) / 240.0
        p.append((180.0, Y_QUAY + (Y_TOP - Y_QUAY) * t, float(z)))
    # viraj spre vest (centru 156, 96), 0 -> 90
    p += arc(156.0, 96.0, Y_TOP, 0.0, 90.0)
    # latura de sud: z = 120, x 156 .. 24
    for x in range(156, 23, -12):
        p.append((float(x), Y_TOP, 120.0))
    # viraj spre nord (centru 24, 96), 90 -> 180; se inchide in (0, 26, 96)
    p += arc(24.0, 96.0, Y_TOP, 90.0, 180.0)
    return p


def mean_y(pts):
    tot = 0.0
    acc = 0.0
    n = len(pts)
    for i in range(n):
        a = pts[i]
        b = pts[(i + 1) % n]
        seg = math.dist(a, b)
        tot += seg
        acc += seg * 0.5 * (a[1] + b[1])
    return acc / tot, tot


def lagoon():
    # Golful: de la 10 m nord de axa cheiului (z -178) pana la tarmul din Marin (z -285).
    return [(-420.0, -178.0), (420.0, -178.0), (420.0, -285.0), (-420.0, -285.0)]


def main():
    pts = route()
    my, length = mean_y(pts)
    data = ", ".join("0, 0, 0, 0, 0, 0, %g, %g, %g" % (x, y, z) for (x, y, z) in pts)
    tilts = ", ".join("0" for _ in pts)
    lag = ", ".join("Vector2(%g, %g)" % q for q in lagoon())
    # media pe care o foloseste sampler-ul se citeste din joc (`mean_road_y`); asta e estimarea
    off = SEA_Y - my
    txt = f"""[gd_scene format=3]

[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]
[ext_resource type="Script" path="res://tools/sf_loc_decor.gd" id="2_decor"]

[sub_resource type="Curve3D" id="Curve3D_sfloc"]
closed = true
_data = {{
"points": PackedVector3Array({data}),
"tilts": PackedFloat32Array({tilts})
}}
point_count = {len(pts)}

[node name="SfLoc" type="Node3D"]
script = ExtResource("1_track")
custom_name = "Strada test"
custom_theme = "sanfrancisco"
custom_world_seed_name = "sf_loc"
custom_half_width = 7.0
custom_gate_model = "none"
custom_sea_level_offset = {off:.3f}
custom_lagoon = Array[Vector2]([{lag}])
traffic_count = 0
level_shoulder_zones = Array[Vector3]([Vector3(0.0, 0.27, 4.0)])

[node name="Path" type="Path3D" parent="."]
curve = SubResource("Curve3D_sfloc")

[node name="SfDecor" type="Node3D" parent="."]
script = ExtResource("2_decor")
"""
    with open(OUT, "w", newline="\n", encoding="utf-8") as f:
        f.write(txt)
    print("scris %s: %d puncte, %.0f m, media soselei %.2f m, offset mare %.3f"
          % (os.path.relpath(OUT, ROOT), len(pts), length, my, off))


if __name__ == "__main__":
    main()
