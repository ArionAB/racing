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


# A2 (runda 2): fara copac singur — fagii in rand pe taluzul dintre cele doua drumuri (treapta
# terenului de la est de gradoni, ~4 m pe ~5 m); masivul TerrainPeak e fundalul gradonilor, camion x2, excavator, conuri de moloz la baza peretilor.
PEAK = ("MasivSpate", 40.0, 45.0, -95.0, 90.0)   # nume, x, y(cota varf), z, raza
PROPS2 = [
    ("Camion_parcat", "baikal/vehicles/kamaz_truck.glb", 113.0, 26.0, 90.0, 1.0, "truck"),
    ("Camion_2", "baikal/vehicles/kamaz_truck.glb", 125.0, 27.0, 88.0, 1.0, "truck2"),
    ("Excavator", "vehicles/rusted_digger.glb", 74.0, 37.0, 160.0, 1.0, "digger"),
    ("Con_1", "transfagarasan/rocks/scree_cone.glb", 16.0, 27.4, 0.0, 0.5, "cone1"),
    ("Con_2", "transfagarasan/rocks/scree_cone.glb", 44.0, 27.4, 180.0, 0.55, "cone2"),
    ("Con_3", "transfagarasan/rocks/scree_cone.glb", 26.0, 5.6, 180.0, 0.5, "cone3"),
    ("Con_4", "transfagarasan/rocks/scree_cone.glb", 60.0, 5.6, 0.0, 0.55, "cone4"),
    ("Fag_1", "transfagarasan/plants/beech_tree_a.glb", 98.0, -0.5, 20.0, 1.0, "fag1"),
    ("Fag_2", "transfagarasan/plants/beech_tree_b.glb", 104.0, 0.2, 80.0, 1.1, "fag2"),
    ("Fag_3", "transfagarasan/plants/beech_tree_a.glb", 110.0, -0.6, 140.0, 0.9, "fag3"),
    ("Fag_4", "transfagarasan/plants/beech_tree_b.glb", 117.0, 0.0, 200.0, 1.0, "fag4"),
    ("Fag_5", "transfagarasan/plants/beech_tree_a.glb", 124.0, -0.4, 260.0, 1.1, "fag5"),
    ("Fag_6", "transfagarasan/plants/beech_tree_b.glb", 131.0, 0.3, 320.0, 1.0, "fag6"),
    ("Fag_7", "transfagarasan/plants/beech_tree_a.glb", 137.0, -0.5, 40.0, 1.0, "fag7"),
    ("Ginestra_1", "stromboli/plants/ginestra_bush.glb", 101.0, -2.8, 10.0, 1.4, "gin3"),
    ("Ginestra_2", "stromboli/plants/ginestra_bush.glb", 114.0, -2.6, 100.0, 1.4, "gin4"),
    ("Ginestra_3", "stromboli/plants/ginestra_bush.glb", 128.0, -2.8, 200.0, 1.4, "gin5"),
    ("Ginestra_4", "stromboli/plants/ginestra_bush.glb", 124.0, 32.0, 200.0, 1.4, "gin1"),
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


def scene(theme, marble_class, label, ground, pts, ys, a2=False):
    ext = [
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
        '[ext_resource type="Script" path="res://scenes/tracks/carrara_mostra.gd" id="2_mostra"]',
        '[ext_resource type="Script" path="res://scenes/props/world_prop.gd" id="3_prop"]',
    ]
    props = PROPS2 if a2 else PROPS
    if a2:
        ext.append('[ext_resource type="Script" path="res://scenes/tracks/terrain_peak.gd" id="4_peak"]')
    glbs = {}
    for _, glb, *_r in props:
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
    if a2:
        out.append("stripes = true")
        out.append("block_grid = true")
        out.append("grid_y = %g" % ground.get("cubes", 0.0))
    out.append("")
    if a2:
        nm, px, py, pz, pr = PEAK
        out.append('[node name="Peaks" type="Node3D" parent="."]')
        out.append("")
        out.append('[node name="%s" type="Marker3D" parent="Peaks"]' % nm)
        out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.2f, %.2f, %.2f)" % (px, py, pz))
        out.append("gizmo_extents = %g" % pr)
        out.append('script = ExtResource("4_peak")')
        out.append("radius_m = %g" % pr)
        out.append("")
    out.append('[node name="DecorManual" type="Node3D" parent="."]')
    out.append('script = ExtResource("3_prop")')
    for name, glb, x, z, yaw, sc, key in props:
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
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        ground = json.load(open(sys.argv[1]))
    pts = build_path()
    ys, total = heights(pts)
    print("puncte: %d, lungime ~%.0f m" % (len(pts), total))
    if "--a2" in sys.argv:
        sys.argv.remove("--a2")
        if len(sys.argv) > 1:
            ground = json.load(open(sys.argv[1]))
        with open("scenes/tracks/Track23MostraA2.tscn", "w", encoding="utf-8", newline="\n") as f:
            f.write(scene("carrara2", "carrara_marble", "Mostra Carrara A2", ground, pts, ys, True))
        print("scris scenes/tracks/Track23MostraA2.tscn")
        return
    for fname, theme, cls, label in (
            ("scenes/tracks/Track23Mostra.tscn", "carrara", "carrara_marble", "Mostra Carrara A"),
            ("scenes/tracks/Track23MostraB.tscn", "carrara_real", "carrara_marble_real",
             "Mostra Carrara B")):
        with open(fname, "w", encoding="utf-8", newline="\n") as f:
            f.write(scene(theme, cls, label, ground, pts, ys))
        print("scris", fname)


if __name__ == "__main__":
    main()
