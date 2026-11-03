"""Scenele testului de loc ANGKOR (docs/track_briefs/angkor.md §7 pasul 0) — TEMPORAR.

Scrie `scenes/tracks/Track24Mostra.tscn` (A: tema `angkor`, accente) si
`Track24MostraB.tscn` (B: tema `angkor_real`, martorul fara antidoturi). Aceeasi bucla,
aceeasi geometrie (`angkor_mostra.gd`), acelasi decor. Copacii se scriu la y = 0;
`angkor_mostra.gd` ii aseaza pe teren dupa ce exista.

    python tools/gen_angkor_mostra.py
"""
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Bucla (x, z), plata (y = 0). Startul merge spre est, spre templul din (200, 0).
PATH = [
    (0, 0), (40, 0), (80, 0), (110, 0), (122, -6), (127, -20), (128, -50), (124, -80),
    (112, -102), (90, -116), (60, -122), (30, -122), (5, -116), (-15, -104), (-26, -84),
    (-30, -60), (-29, -35), (-24, -16), (-14, -4),
]

MODELS = {
    "palm": "res://assets/models/okinawa/plants/fan_palm.glb",
    "banyan": "res://assets/models/trees/banyan.glb",
    "ficus_a": "res://assets/models/trees/banyan.glb",
    "ficus_b": "res://assets/models/okinawa/plants/fukugi_tree_a.glb",
    "fern": "res://assets/models/plants/fern_cluster.glb",
    "bamboo": "res://assets/models/halong/plants/bamboo_clump.glb",
    "shrub": "res://assets/models/plants/broadleaf_shrub.glb",
}

# Zone fara copaci: templul + santul de est, santurile caii, turnurile cu fete, zidul.
KEEP_OUT = [
    (130, 230, -60, 60),     # santul de est si templul
    (28, 114, -31, 31),      # santurile caii de acces
    (-50, -34, -38, -22),    # turnurile cu fete (Bayon), cate o caseta
    (94, 114, -94, -74),
    (-55, -39, -66, -50),
    (-21, -5, -58, -42),
    (-68, -52, -90, -74),
    (4, 96, -137, -131),     # zidul de incinta (pe linia lui)
]


def seg_dist(px, pz, a, b):
    ax, az = a
    bx, bz = b
    dx, dz = bx - ax, bz - az
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz)))
    cx, cz = ax + t * dx, az + t * dz
    return math.hypot(px - cx, pz - cz)


def road_dist(px, pz):
    n = len(PATH)
    return min(seg_dist(px, pz, PATH[i], PATH[(i + 1) % n]) for i in range(n))


def kept_out(x, z):
    return any(x0 <= x <= x1 and z0 <= z <= z1 for x0, x1, z0, z1 in KEEP_OUT)


def decor():
    rnd = random.Random(24)
    items = []
    # Mana: poarta-copac (ficusul mare in spatele gopurei) si palmierii de zahar la cale.
    items.append(("ficus_a", 50.0, -139.5, 20.0, 1.5, "Ficus_PoartaCopac"))
    for i, x in enumerate([18, 44, 70, 96]):
        for s in (-1, 1):
            items.append(("palm", x + rnd.uniform(-3, 3), s * 34.0 + rnd.uniform(-2, 2),
                          rnd.uniform(0, 360), rnd.uniform(1.1, 1.35), f"Palmier_{i}_{s}"))
    for s in (-1, 1):
        items.append(("palm", -8.0, s * 13.0, rnd.uniform(0, 360), 1.2, f"Palmier_start_{s}"))
    # Jungla: inel de copaci la 9-40 m de drum, dens pe latura de nord si de vest.
    weights = [("banyan", 5), ("ficus_a", 3), ("ficus_b", 1), ("bamboo", 3), ("fern", 4),
               ("shrub", 4)]
    pool = [k for k, w in weights for _ in range(w)]
    tries = 0
    count = 0
    while count < 280 and tries < 12000:
        tries += 1
        x = rnd.uniform(-90, 150)
        z = rnd.uniform(-175, 50)
        d = road_dist(x, z)
        if d < 7.5 or d > 38 or kept_out(x, z):
            continue
        # Bucla interioara (intre picioare) ramane mai rara: se vad turnurile peste ea.
        if -10 < x < 110 and -100 < z < -10 and rnd.random() < 0.3:
            continue
        kind = rnd.choice(pool)
        if kind in ("fern", "shrub") and d > 20:
            kind = rnd.choice(["ficus_a", "ficus_b", "banyan"])
        scale = rnd.uniform(1.3, 1.9) if kind not in ("fern", "shrub") else rnd.uniform(1.2, 2.0)
        items.append((kind, x, z, rnd.uniform(0, 360), scale, f"J_{kind}_{count}"))
        count += 1
    return items


def curve():
    pts = []
    for x, z in PATH:
        pts += ["0", "0", "0", "0", "0", "0", f"{x}", "0", f"{z}"]
    n = len(PATH)
    return ("[sub_resource type=\"Curve3D\" id=\"Curve3D_mostra\"]\nclosed = true\n_data = {\n"
            f"\"points\": PackedVector3Array({', '.join(pts)}),\n"
            f"\"tilts\": PackedFloat32Array({', '.join(['0'] * n)})\n}}\npoint_count = {n}\n")


def scene(variant):
    a = variant == "A"
    keys = list(MODELS)
    out = ["[gd_scene format=3]", "",
           '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]',
           '[ext_resource type="Script" path="res://scenes/tracks/angkor_mostra.gd" id="2_mostra"]',
           '[ext_resource type="Script" path="res://scenes/props/world_prop.gd" id="3_prop"]',
           '[ext_resource type="Script" path="res://scenes/hazards/rain_cycle.gd" id="4_rain"]']
    for k in keys:
        out.append(f'[ext_resource type="PackedScene" path="{MODELS[k]}" id="m_{k}"]')
    out += ["", curve(),
            '[node name="Track24" type="Node3D"]',
            'script = ExtResource("1_track")',
            f'custom_name = "Mostra Angkor {variant}"',
            f'custom_theme = "{"angkor" if a else "angkor_real"}"',
            'custom_world_seed_name = "angkor_mostra"',
            "custom_half_width = 4.5",
            'custom_gate_model = "none"',
            "custom_dirt_ranges = Array[Vector2]([Vector2(0, 1)])",
            "traffic_count = 0", "",
            '[node name="Path" type="Path3D" parent="."]',
            'curve = SubResource("Curve3D_mostra")', "",
            '[node name="Mostra" type="Node3D" parent="."]',
            'script = ExtResource("2_mostra")',
            f'stone_class = "{"angkor_sandstone" if a else "angkor_sandstone_real"}"',
            f"accents = {'true' if a else 'false'}", "",
            # Musonul: ceasul porneste in faza USCATA (start_clock 50 din 95); capturile de ploaie
            # il forteaza cu `snapshot --rain=1`.
            '[node name="Ploaie" type="Node" parent="."]',
            'script = ExtResource("4_rain")',
            "start_clock = 50.0", "",
            '[node name="DecorManual" type="Node3D" parent="."]',
            'script = ExtResource("3_prop")', ""]
    for kind, x, z, yaw, s, name in decor():
        r = math.radians(yaw)
        c, sn = math.cos(r) * s, math.sin(r) * s
        out += [f'[node name="{name}" parent="DecorManual" instance=ExtResource("m_{kind}")]',
                f"transform = Transform3D({c:.5f}, 0, {-sn:.5f}, 0, {s:.4f}, 0, "
                f"{sn:.5f}, 0, {c:.5f}, {x:.2f}, 0, {z:.2f})", ""]
    return "\n".join(out)


def fracs():
    """Lungimea cumulata a buclei (poligonala, aproximativ ca Catmull-Rom) pentru capturi."""
    n = len(PATH)
    segs = [math.dist(PATH[i], PATH[(i + 1) % n]) for i in range(n)]
    total = sum(segs)
    acc = 0.0
    print(f"lungime ~{total:.0f} m")
    for i in range(n):
        print(f"  P{i} {PATH[i]} frac {acc / total:.3f}")
        acc += segs[i]


if __name__ == "__main__":
    for v, fn in (("A", "Track24Mostra.tscn"), ("B", "Track24MostraB.tscn")):
        (ROOT / "scenes/tracks" / fn).write_text(scene(v), encoding="utf-8", newline="\n")
    fracs()
