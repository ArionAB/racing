"""Garda kitului de cariera Carrara (kit §1.5) -- citeste GLB-urile EXPORTATE.

    python tools/blender/measure_crr_kit.py

Pentru fiecare piesa din tabel, in coordonate Godot (X latime, Y sus, Z
lungime; Blender +Y = Godot -Z):
  - numele nodurilor-mesh (contractul cu integrarea: clasa se pune pe sufix);
  - cotele fata de tabelul din kit (intervale; blocurile la +-1 cm);
  - sloturile interzise: FOAM_WHITE 22 (nimic nu are voie sa para zapada,
    brief §4) si CAR_YELLOW 14-16 (accentele masinilor);
  - modulele inlantuibile (berma, conductele): lungimea exact 6 m si capetele
    IDENTICE -- capacul din planul z = -3 si cel din z = +3 au aceeasi arie si
    se acopera reciproc (toleranta 2 mm), deci doua module puse cap la cap nu
    lasa treapta. Garda a fost verificata pe sabotaj (vezi inventarul).
Iese cu 1 la prima abatere; tipareste tot.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb, read_accessor            # noqa: E402
from measure_carrara_truck import world_points             # noqa: E402

ROOT = os.path.join("assets", "models", "carrara")

# piesa: (cale, noduri, {axa: (min, max)} pe dimensiuni Godot, modul?)
B = 0.011
KIT = [
    ("rocks/marble_block_a.glb", ["Block_Marble", "Block_MarbleBase"],
     {"x": (1.5 - B, 1.5 + B), "y": (1.5 - B, 1.5 + B), "z": (1.5 - B, 1.5 + B)}, False),
    ("rocks/marble_block_b.glb", ["Block_Marble", "Block_MarbleBase", "Block_Paint"],
     {"x": (2.0 - B, 2.0 + B), "y": (2.0 - B, 2.0 + B), "z": (2.0 - B, 2.0 + B)}, False),
    ("rocks/marble_block_c.glb", ["Block_Marble", "Block_MarbleBase"],
     {"x": (3.0 - B, 3.0 + B), "y": (2.0 - B, 2.0 + B), "z": (2.0 - B, 2.0 + B)}, False),
    ("rocks/block_stack_a.glb", ["Stack_Marble", "Stack_MarbleBase"],
     {"x": (1.9, 2.4), "y": (2.6, 3.3), "z": (1.7, 2.3)}, False),
    ("rocks/block_stack_b.glb", ["Stack_Marble", "Stack_MarbleBase"],
     {"x": (1.9, 2.5), "y": (3.2, 4.0), "z": (1.7, 2.3)}, False),
    ("rocks/block_informe_b.glb", ["Informe_Marble", "Informe_MarbleBase"],
     {"x": (1.8, 2.5), "y": (1.2, 1.7), "z": (1.8, 2.5)}, False),
    ("rocks/rubble_pile_a.glb", ["Rubble_Marble", "Rubble_MarbleBase"],
     {"x": (3.5, 4.3), "y": (1.3, 1.65), "z": (3.5, 4.3)}, False),
    ("rocks/rubble_pile_b.glb", ["Rubble_Marble", "Rubble_MarbleBase"],
     {"x": (2.6, 3.3), "y": (1.05, 1.35), "z": (2.6, 3.3)}, False),
    ("structures/safety_berm.glb", ["Berm_Marble", "Berm_MarbleBase"],
     {"x": (1.3, 1.5), "y": (0.55, 0.66), "z": (5.999, 6.001)}, True),
    ("props/work_lamp.glb", ["Lamp_Body", "Lamp_Glow"],
     {"y": (2.85, 3.1)}, False),
    ("props/cable_reel.glb", ["Reel_Body"],
     {"x": (1.0, 1.15), "y": (1.6, 1.75), "z": (1.55, 1.65)}, False),
    ("props/water_tank.glb", ["WaterTank_Body"],
     {"x": (1.95, 2.15), "y": (2.9, 3.1), "z": (1.95, 2.15)}, False),
    ("props/fuel_tank.glb", ["FuelTank_Body"],
     {"x": (1.9, 2.1), "y": (2.3, 2.5), "z": (3.8, 4.1)}, False),
    ("buildings/office_container.glb", ["Office_Body"],
     {"x": (5.95, 6.05), "y": (2.55, 2.65), "z": (2.45, 2.95)}, False),
    ("props/quarry_sign_a.glb", ["Sign_Body"],
     {"x": (1.19, 1.21), "y": (1.75, 1.85)}, False),
    ("props/quarry_sign_b.glb", ["Sign_Body"],
     {"x": (1.19, 1.21), "y": (1.75, 1.85)}, False),
    ("props/pipe_run.glb", ["Pipe_Marble", "Pipe_Metal"],
     {"z": (5.999, 6.001)}, True),
]
FORBIDDEN = {22: "FOAM_WHITE", 14: "CAR_RED", 15: "CAR_BLUE", 16: "CAR_YELLOW"}


def slots_used(g, blob):
    out = set()
    for n in g["nodes"]:
        if "mesh" not in n:
            continue
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            if "TEXCOORD_0" not in prim["attributes"]:
                continue
            for uv in read_accessor(g, blob, prim["attributes"]["TEXCOORD_0"]):
                out.add(int(uv[0] * 32))
    return out


def cap_triangles(g, blob, z0, eps=1e-3):
    """Triunghiurile care stau intregi in planul z = z0 (capacul modulului),
    ca liste de (x, y). Nodurile sunt radacini fara transformare (garda de
    scala/rotatie din verify_carrara.sh), deci pozitiile brute sunt finale."""
    out = []
    for n in g["nodes"]:
        if "mesh" not in n:
            continue
        t = n.get("translation", [0, 0, 0])
        for prim in g["meshes"][n["mesh"]]["primitives"]:
            pos = read_accessor(g, blob, prim["attributes"]["POSITION"])
            idx = [i[0] for i in read_accessor(g, blob, prim["indices"])]
            for k in range(0, len(idx), 3):
                tri = [pos[idx[k + j]] for j in range(3)]
                tri = [(q[0] + t[0], q[1] + t[1], q[2] + t[2]) for q in tri]
                if all(abs(q[2] - z0) < eps for q in tri):
                    out.append([(q[0], q[1]) for q in tri])
    return out


def _area(tri):
    (ax, ay), (bx, by), (cx, cy) = tri
    return abs((bx - ax) * (cy - ay) - (cx - ax) * (by - ay)) * 0.5


def _inside(p, tri, tol):
    """p in triunghi, cu o marja `tol` (distanta pana la laturi)."""
    import math
    (ax, ay), (bx, by), (cx, cy) = tri
    d = []
    for (x0, y0), (x1, y1) in (((ax, ay), (bx, by)), ((bx, by), (cx, cy)), ((cx, cy), (ax, ay))):
        L = math.hypot(x1 - x0, y1 - y0) or 1e-9
        d.append(((x1 - x0) * (p[1] - y0) - (y1 - y0) * (p[0] - x0)) / L)
    return all(v >= -tol for v in d) or all(v <= tol for v in d)


def ends_match(g, blob, half=3.0, tol=0.002):
    """Capetele identice: aceeasi arie de capac la -3 si +3 (1%) si fiecare
    varf al unui capac cade pe capacul celuilalt (2 mm). Nu se cere aceeasi
    lista de varfuri: invelitoarea convexa poate pastra un varf coliniar pe o
    latura la un capat si nu la celalalt, fara nicio treapta vizibila."""
    lo, hi = cap_triangles(g, blob, -half), cap_triangles(g, blob, half)
    if not lo or not hi:
        return False, "capete fara capac (lo %d, hi %d triunghiuri)" % (len(lo), len(hi))
    a_lo, a_hi = sum(map(_area, lo)), sum(map(_area, hi))
    if abs(a_lo - a_hi) > 0.01 * max(a_lo, a_hi):
        return False, "arii diferite: %.4f / %.4f m2" % (a_lo, a_hi)
    for src, dst, tag in ((lo, hi, "-3 -> +3"), (hi, lo, "+3 -> -3")):
        for tri in src:
            for p in tri:
                if not any(_inside(p, t, tol) for t in dst):
                    return False, "varf %s nu cade pe capacul opus (%s)" % (p, tag)
    return True, "capace %.4f / %.4f m2, %d / %d triunghiuri, acoperire reciproca" % (
        a_lo, a_hi, len(lo), len(hi))


def main():
    fail = 0
    for rel, nodes, dims, module in KIT:
        path = os.path.join(ROOT, rel)
        name = os.path.basename(rel)
        if not os.path.exists(path):
            print("%-24s LIPSESTE" % name)
            fail = 1
            continue
        g, blob = load_glb(path)[:2]
        msgs = []
        got = sorted(n.get("name") for n in g["nodes"] if "mesh" in n)
        if got != sorted(nodes):
            msgs.append("noduri %s, cerute %s" % (got, sorted(nodes)))
        pts = [p for p, _ in world_points(g, blob)]
        ext = {}
        for k, ax in (("x", 0), ("y", 1), ("z", 2)):
            vals = [p[ax] for p in pts]
            ext[k] = max(vals) - min(vals)
        for k, (a, b) in dims.items():
            if not (a <= ext[k] <= b):
                msgs.append("%s = %.3f in afara [%.3f, %.3f]" % (k, ext[k], a, b))
        miny = min(p[1] for p in pts)
        if abs(miny) > 0.01:
            msgs.append("talpa la y = %.3f, nu 0" % miny)
        bad = slots_used(g, blob) & set(FORBIDDEN)
        if bad:
            msgs.append("sloturi interzise: %s" % [FORBIDDEN[s] for s in sorted(bad)])
        line = "%-24s %.2f x %.2f x %.2f m (X x Y x Z Godot)" % (name, ext["x"], ext["y"], ext["z"])
        if module:
            ok, why = ends_match(g, blob)
            line += "  capete: " + why
            if not ok:
                msgs.append("capete diferite")
        print(line)
        for m in msgs:
            print("   !! " + m)
        if msgs:
            fail = 1
    print("kit de cariera: %s" % ("OK" if not fail else "PROBLEME"))
    return fail


if __name__ == "__main__":
    sys.exit(main())
