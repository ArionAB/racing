#!/usr/bin/env python3
"""Genereaza scenele TESTULUI DE MOSTRA CARRARA (docs/track_briefs/carrara.md §7 pasul 0):
Track23Mostra.tscn (varianta A, tema `carrara`) si Track23MostraB.tscn (varianta B, martorul,
tema `carrara_real`). Aceeasi geometrie; difera doar tema si clasa de marmura.

TEMPORAR — se scoate inainte de merge, odata cu `scenes/tracks/carrara_mostra.gd` si cele
doua intrari marcate din GameState.TRACK_SCENES.

Ruleaza din radacina proiectului:  python tools/gen_carrara_mostra.py [ground.json]
`ground.json` (optional) = {"truck": y, "tree1": y, ...} cotele terenului la props, masurate
cu tools/ProbeMostraTeren.tscn; fara el props stau pe y=0.

Plan (nord = -Z, sosea in sensul acelor de ceasornic, vazuta de sus):
  T1   y=7  : dreapta de SUS pe terasa gradonului 1, spre est (z=-12), x in [-80, 140]
  hairpin E : centru (140,2) R=14, coboara 7 -> 0 (descendenta ~7%)
  jos  y=0  : dreapta de JOS spre vest (z=+16), x in [140, -80], lipita de fata gradonului 1
  hairpin V : centru (-80,2) R=14, urca 0 -> 7 pe ~200 m (3,5%)
Gradonii (x in [0,80]) si zidul-contra (x in [0,60], z>26) sunt construiti de carrara_mostra.gd.
"""
import json
import math
import sys

R = 14.0
XE = 140.0   # centrul hairpin-ului de est
XW = -80.0   # centrul hairpin-ului de vest
ZT = -12.0   # axa dreptei de sus (T1)
ZB = 16.0    # axa dreptei de jos
ZM = (ZT + ZB) / 2.0   # linia de mijloc dintre cele doua drumuri (treapta terenului)
Y_TOP = 7.0


def arc(cx, cz, th0, th1, n):
    """n puncte pe arc, de la unghiul th0 la th1 (grade); x = cos, z = sin."""
    pts = []
    for i in range(n):
        t = math.radians(th0 + (th1 - th0) * i / (n - 1))
        pts.append((cx + R * math.cos(t), cz + R * math.sin(t)))
    return pts


def build_path():
    pts = []
    # T1 spre est: x = 0 .. 130 (pregatire inainte de arc)
    for x in (0.0, 40.0, 80.0, 110.0, 130.0):
        pts.append((x, ZT))
    pts += arc(XE, ZM, -90.0, 90.0, 4)           # hairpin E, 4 puncte pe arc
    # dreapta de jos spre vest
    for x in (130.0, 110.0, 70.0, 30.0, 0.0, -40.0, -70.0):
        pts.append((x, ZB))
    pts += arc(XW, ZM, 90.0, 270.0, 4)           # hairpin V
    for x in (-70.0, -40.0):
        pts.append((x, ZT))
    return pts


def heights(pts):
    """Cota y pe fiecare punct: 7 pe terasa pana la x=80, coboara liniar pana la capatul
    arcului de est, 0 pe dreapta de jos pana la x=0, urca liniar pana la start."""
    n = len(pts)
    s = [0.0]
    for i in range(1, n):
        s.append(s[-1] + math.dist(pts[i - 1], pts[i]))
    total = s[-1] + math.dist(pts[-1], pts[0])
    i_desc0 = next(i for i, p in enumerate(pts) if abs(p[0] - 80.0) < 1e-6 and p[1] == ZT)
    # primul punct al dreptei de jos dupa arcul est
    i_desc1 = next(i for i, p in enumerate(pts) if i > i_desc0 and p[1] == ZB and p[0] == 130.0)
    i_asc0 = next(i for i, p in enumerate(pts) if i > i_desc1 and p[1] == ZB and p[0] == 0.0)
    ys = []
    for i in range(n):
        if i <= i_desc0:
            y = Y_TOP
        elif i <= i_desc1:
            y = Y_TOP * (1.0 - (s[i] - s[i_desc0]) / (s[i_desc1] - s[i_desc0]))
        elif i <= i_asc0:
            y = 0.0
        else:
            y = Y_TOP * (s[i] - s[i_asc0]) / (total - s[i_asc0])
        ys.append(round(y, 3))
    return ys, total


# props: (nume, glb, x, z, yaw_grade, scara, cheie_cota)
PROPS = [
    ("Camion_parcat", "baikal/vehicles/kamaz_truck.glb", 113.0, 26.0, 90.0, 1.0, "truck"),
    ("Fag_A", "transfagarasan/plants/beech_tree_a.glb", 140.0, 2.0, 20.0, 1.0, "tree1"),
    ("Fag_B", "transfagarasan/plants/beech_tree_a.glb", -30.0, 34.0, 140.0, 1.0, "tree2"),
    ("Ginestra_A", "stromboli/plants/ginestra_bush.glb", 124.0, 32.0, 10.0, 1.4, "gin1"),
    ("Ginestra_B", "stromboli/plants/ginestra_bush.glb", -8.0, 28.0, 200.0, 1.4, "gin2"),
]


def curve_resource(pts, ys):
    data = []
    for (x, z), y in zip(pts, ys):
        data += [0, 0, 0, 0, 0, 0, x, y, z]
    flat = ", ".join(("%g" % v) for v in data)
    tilts = ", ".join("0" for _ in pts)
    return (
        '[sub_resource type="Curve3D" id="Curve3D_mostra"]\n'
        "closed = true\n"
        "_data = {\n"
        '"points": PackedVector3Array(%s),\n'
        '"tilts": PackedFloat32Array(%s)\n'
        "}\n"
        "point_count = %d\n" % (flat, tilts, len(pts))
    )


def scene(theme, marble_class, label, ground, pts, ys):
    ext = [
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
        '[ext_resource type="Script" path="res://scenes/tracks/carrara_mostra.gd" id="2_mostra"]',
        '[ext_resource type="Script" path="res://scenes/props/world_prop.gd" id="3_prop"]',
    ]
    glbs = {}
    for _, glb, *_r in PROPS:
        if glb not in glbs:
            glbs[glb] = "m%d_%s" % (len(glbs), glb.split("/")[-1].replace(".glb", ""))
            ext.append('[ext_resource type="PackedScene" path="res://assets/models/%s" id="%s"]'
                       % (glb, glbs[glb]))
    out = ["[gd_scene format=3]", ""] + ext + ["", curve_resource(pts, ys)]
    out.append('[node name="Track23" type="Node3D"]')
    out.append('script = ExtResource("1_track")')
    out.append('custom_name = "%s"' % label)
    out.append('custom_theme = "%s"' % theme)
    out.append('custom_world_seed_name = "carrara_mostra"')
    out.append("custom_half_width = 7.0")
    out.append('custom_gate_model = "none"')
    out.append("custom_dirt_ranges = Array[Vector2]([Vector2(0, 1)])")
    out.append("traffic_count = 0")
    out.append("")
    out.append('[node name="Path" type="Path3D" parent="."]')
    out.append('curve = SubResource("Curve3D_mostra")')
    out.append("")
    out.append('[node name="Mostra" type="Node3D" parent="."]')
    out.append('script = ExtResource("2_mostra")')
    out.append('marble_class = "%s"' % marble_class)
    out.append("pool_y = %g" % (ground.get("pool", 0.0) + 0.12))
    out.append("cube_y = %g" % ground.get("cubes", 0.0))
    out.append("")
    out.append('[node name="DecorManual" type="Node3D" parent="."]')
    out.append('script = ExtResource("3_prop")')
    for name, glb, x, z, yaw, sc, key in PROPS:
        c, s_ = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
        y = ground.get(key, 0.0)
        out.append("")
        out.append('[node name="%s" parent="DecorManual" instance=ExtResource("%s")]'
                   % (name, glbs[glb]))
        out.append("transform = Transform3D(%.5f, 0, %.5f, 0, %.3f, 0, %.5f, 0, %.5f, %.2f, %.3f, %.2f)"
                   % (c * sc, s_ * sc, sc, -s_ * sc, c * sc, x, y, z))
    return "\n".join(out) + "\n"


def main():
    ground = {}
    if len(sys.argv) > 1:
        ground = json.load(open(sys.argv[1]))
    pts = build_path()
    ys, total = heights(pts)
    print("puncte: %d, lungime ~%.0f m" % (len(pts), total))
    for fname, theme, cls, label in (
            ("scenes/tracks/Track23Mostra.tscn", "carrara", "carrara_marble", "Mostra Carrara A"),
            ("scenes/tracks/Track23MostraB.tscn", "carrara_real", "carrara_marble_real",
             "Mostra Carrara B")):
        with open(fname, "w", encoding="utf-8", newline="\n") as f:
            f.write(scene(theme, cls, label, ground, pts, ys))
        print("scris", fname)


if __name__ == "__main__":
    main()
