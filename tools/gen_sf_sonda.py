#!/usr/bin/env python3
"""Genereaza tools/SondaSf*.tscn: strada SINTETICA de test pentru San Francisco
(brief docs/track_briefs/san_francisco.md, pasul 1). NU e Track25.

Intrebarea la care raspunde: o strada care coboara un deal in TREPTE (bloc
abrupt, intersectie plata, bloc abrupt...) da un LANT de sarituri pe fizica
intreaga, pentru toate masinile din garaj, fara ejectari? Si cu ce profil de
bloc. Precedentul e creasta Regelui Lepros de pe Angkor (o singura saritura,
`tools/gen_angkor_route.py` CREST_PROFILE); aici sunt N la rand, iar viteza
creste de la una la alta.

Bucla (TrackFromPath cere bucla inchisa):
  - punctul 0 la (0, Y_TOP, 0), sensul +X; grila sta in spatele lui, pe dreapta
    plata de 72 m cu care se inchide bucla;
  - elan plat RUNUP, apoi N blocuri: MUCHIA (ultimul punct plat), profilul
    blocului din 12 in 12 m, apoi intersectia plata FLAT pana la muchia
    urmatoare; dupa ultimul bloc, o iesire plata RUNOUT;
  - ac de 180 la dreapta (R 30), intoarcerea paralela la 60 m care urca
    liniar inapoi la Y_TOP, alt ac de 180, dreapta de grila.

Variante (PROFIL=...), toate cu pas de control uniform de 12 m (pasul mixt
supraincarca spline-ul — angkor.md, tabelul crestei):
  angkor   [0,-4.4,-6.6,-7.8,-8.4,-8.6]  profilul validat pe Track24 (37% apoi 18->2%)
  scurt    [0,-4.4,-6.6,-7.8,-8.4]       acelasi, fara ultimul pas (bloc de 48 m)
  abrupt   [0,-4.4,-7.6,-9.4,-10.2,-10.4] muchie 37%, apoi 27->15->7->2%
  plan28   [0,-3.4,-6.8,-10.2,-12.2,-13.0] bloc de panta CONSTANTA 28% + racord (strada "reala")
  plan20   [0,-2.4,-4.8,-7.2,-8.6,-9.2]   bloc de panta constanta 20% + racord
  plan24   [0,-2.9,-5.8,-8.7,-10.5,-11.1] bloc de panta constanta 24% + racord
  plan32   [0,-3.8,-7.6,-11.4,-13.6,-14.4] bloc de panta constanta 32% + racord
  plan28s  [0,-3.4,-6.8,-8.8,-9.6]        28% pe doar doi pasi + racord (bloc de 48 m)
  plan28l  [0,-3.4,-6.8,-10.2,-13.6,-15.6,-16.4] 28% pe patru pasi + racord (bloc de 72 m)

  python tools/gen_sf_sonda.py                 # toate variantele
  PROFIL=angkor BLOCURI=4 FLAT=24 python tools/gen_sf_sonda.py

Scrie si metadatele citite de tools/probe_sf_crest.gd: `sf_lips` (pozitia
fiecarei muchii), `sf_block_len`, `sf_profile`, si `jump_crests` (ferestre pe
fractie, exceptia numita a ProbeLayout).
"""
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STEP = 12.0
PROFILES = {
    "angkor": [0.0, -4.4, -6.6, -7.8, -8.4, -8.6],
    "scurt": [0.0, -4.4, -6.6, -7.8, -8.4],
    "abrupt": [0.0, -4.4, -7.6, -9.4, -10.2, -10.4],
    "plan28": [0.0, -3.4, -6.8, -10.2, -12.2, -13.0],
    "plan20": [0.0, -2.4, -4.8, -7.2, -8.6, -9.2],
    "plan24": [0.0, -2.9, -5.8, -8.7, -10.5, -11.1],
    "plan32": [0.0, -3.8, -7.6, -11.4, -13.6, -14.4],
    "plan28s": [0.0, -3.4, -6.8, -8.8, -9.6],
    "plan28l": [0.0, -3.4, -6.8, -10.2, -13.6, -15.6, -16.4],
}
RUNUP = float(os.environ.get("RUNUP", "120"))     # elan plat pana la prima muchie
RUNOUT = float(os.environ.get("RUNOUT", "84"))    # iesire plata dupa ultimul bloc
GRID = 72.0                                       # dreapta de grila (inchide bucla)
R_TURN = 30.0
Y_BOTTOM = 6.0
HALF_WIDTH = float(os.environ.get("HW", "7.0"))


class Turtle:
    """Ca in gen_carrara_sonda.py: 0 = +X, dreapta (spre +Z) = theta creste."""

    def __init__(self, y):
        self.x, self.z, self.y, self.th = 0.0, 0.0, y, 0.0
        self.pts = [(0.0, y, 0.0)]

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

    def step_to(self, dy_abs):
        """Un pas de 12 m pana la cota absoluta data (profilul blocului)."""
        self.x += math.cos(self.th) * STEP
        self.z += math.sin(self.th) * STEP
        self.y = dy_abs
        self.pts.append((self.x, self.y, self.z))

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


def build(profile, blocks, flat):
    drop = -profile[-1]
    y_top = Y_BOTTOM + drop * blocks
    t = Turtle(y_top)
    t.straight(RUNUP)
    lips = []
    for b in range(blocks):
        lips.append((t.x, t.y, t.z))
        base = t.y
        for dy in profile[1:]:
            t.step_to(base + dy)
        t.straight(flat if b < blocks - 1 else RUNOUT)
    street_end = t.x
    ret_start = len(t.pts) - 1
    t.arc(R_TURN, 180.0, True)
    climb_a = len(t.pts) - 1
    t.straight(street_end + GRID)
    climb_b = len(t.pts) - 1
    t.arc(R_TURN, 180.0, True)
    t.straight(GRID)
    pts = t.pts
    # urcarea: liniara pe dreapta de intoarcere
    n = climb_b - climb_a
    for k in range(n + 1):
        x, _, z = pts[climb_a + k]
        pts[climb_a + k] = (x, Y_BOTTOM + (y_top - Y_BOTTOM) * k / n, z)
    for k in range(climb_b + 1, len(pts)):
        x, _, z = pts[k]
        pts[k] = (x, y_top, z)
    last = pts[-1]
    assert abs(last[0]) < 0.5 and abs(last[2]) < 0.5, last
    pts.pop()
    return pts, lips, y_top, ret_start


def curve_data(points):
    flat = []
    for p in points:
        flat += [0, 0, 0, 0, 0, 0, p[0], p[1], p[2]]
    txt = ", ".join(("%.3f" % v).rstrip("0").rstrip(".") for v in flat)
    tilts = ", ".join("0" for _ in points)
    return ('closed = true\n_data = {\n"points": PackedVector3Array(%s),\n'
            '"tilts": PackedFloat32Array(%s)\n}\npoint_count = %d\n' % (txt, tilts, len(points)))


def write(name, profile, blocks, flat):
    pts, lips, y_top, _ = build(profile, blocks, flat)
    cum = [0.0]
    for a, b in zip(pts, pts[1:] + pts[:1]):
        cum.append(cum[-1] + math.dist(a, b))
    total = cum[-1]
    block_len = STEP * (len(profile) - 1)
    # ferestrele de creasta: de la 6 m inaintea muchiei pana la capatul profilului
    wins = []
    for lip in lips:
        k = min(range(len(pts)), key=lambda i: math.dist(pts[i], lip))
        wins.append(((cum[k] - 6.0) / total, (cum[k] + block_len + 6.0) / total))
    tag = "".join(w.capitalize() for w in name.split("_"))
    out = os.path.join(ROOT, "tools", "SondaSf%s.tscn" % tag)
    scene = [
        "[gd_scene format=3]", "",
        '[ext_resource type="Script" path="res://scenes/tracks/track_from_path.gd" id="1_track"]', "",
        '[sub_resource type="Curve3D" id="Curve3D_route"]\n' + curve_data(pts), "",
        '[node name="SondaSf%s" type="Node3D"]' % tag,
        'script = ExtResource("1_track")',
        'custom_name = "Sonda SF %s"' % name,
        'custom_theme = "desert"',
        'custom_world_seed_name = "sonda_sf"',
        "custom_half_width = %.1f" % HALF_WIDTH,
        'custom_gate_model = "none"',
        "metadata/jump_crests = [%s]" % ", ".join("Vector2(%.4f, %.4f)" % w for w in wins),
        "metadata/sf_lips = [%s]" % ", ".join("Vector3(%.3f, %.3f, %.3f)" % l for l in lips),
        "metadata/sf_block_len = %.1f" % block_len,
        "metadata/sf_flat = %.1f" % flat,
        "metadata/sf_profile = [%s]" % ", ".join("%.2f" % v for v in profile),
        "",
        '[node name="Path" type="Path3D" parent="."]',
        'curve = SubResource("Curve3D_route")', "",
    ]
    open(out, "w", newline="\n").write("\n".join(scene))
    grades = ["%.0f%%" % (100.0 * (a - b) / STEP) for a, b in zip(profile, profile[1:])]
    print("scris %s: %d puncte, %.0f m, %d blocuri x (%.0f m profil [%s] + %.0f m plat), "
          "cadere %.1f m, intoarcere %.1f%%" % (
              os.path.relpath(out, ROOT), len(pts), total, blocks, block_len, " ".join(grades),
              flat, y_top - Y_BOTTOM,
              100.0 * (y_top - Y_BOTTOM) / (RUNUP + blocks * block_len + (blocks - 1) * flat + RUNOUT + GRID)))


def main():
    blocks = int(os.environ.get("BLOCURI", "4"))
    flat = float(os.environ.get("FLAT", "24"))
    only = os.environ.get("PROFIL")
    for name, profile in PROFILES.items():
        if only and name != only:
            continue
        suffix = os.environ.get("SUFIX", "")
        write(name + suffix, profile, blocks, flat)


if __name__ == "__main__":
    sys.exit(main())
