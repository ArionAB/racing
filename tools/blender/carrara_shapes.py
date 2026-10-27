"""Vocabular de forme pentru kitul Carrara (Track23).

Contract: docs/asset_briefs/carrara_kit.md. Pe tiparul transfagarasan_shapes.py
(il incarca cu exec: `ring_stack`, `_hull`, `Builder`-ul din dio_lib). Pilotul
(`quarry_truck`) a scris DOAR ce foloseste camionul; restul vocabularului din
kit §2 (bolovan spart, senila, brat zabrelit, arc de bolari, acoperis de tigla)
vine cu piesele care il cer, nu pe nevazute.

FOLOSITE (pilot):
  cut_marble_block   bloc de marmura taiat drept, spart in DOUA noduri-builder:
                     partea in lumina (`*_Marble`, CORAL_SAND 19) si baza de
                     patina (`*_MarbleBase`, MARBLE_GREY 29), regula 8 din kit.
  tilted_box         cutie rotita pe X si/sau Z (placi inclinate: parbriz,
                     pereti de bena, cilindri hidraulici).
  wheel_crr          roata de camion: anvelopa cu crampoane + janta.
  emit_crr           finish pe fiecare nod cu offsetul de origine calculat O DATA
                     pe ansamblu + export in assets/models/carrara/<cale>.

Axe: X latime, Y lungime (botul spre +Y in Blender = -Z in Godot), Z sus.
Se incarca cu exec, dupa dio_lib.
"""

import math
import os
from mathutils import Vector, Matrix

_here_crr = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_crr, "transfagarasan_shapes.py"), encoding="utf-8").read())

# --- sloturile pe roluri (kit §0, tabelul de sloturi) ------------------------
CRR_PAINT = DRY_VEGETATION       # 13: vopseaua utilajelor, galben-spalacit
CRR_RUST = RUST_METAL = RUST     # 10: rugina utilajelor
CRR_BLACK = VOLCANIC_BLACK       # 20: cauciucuri, geamuri, hidraulica
CRR_MARBLE = CORAL_SAND          # 19: marmura in lumina (*_Marble)
CRR_MARBLE_BASE = MARBLE_GREY    # 29: patina bazei (*_MarbleBase)
CRR_DUST = SAND_SHADOW           # 2: praful de pe utilaje, pete mici

CRR_RESULTS = []


def tilted_box(b, center, size, slot, rot_x=0.0, rot_z=0.0, rot_y=0.0):
    """Cutie rotita (grade): intai pe X (inclinare fata-spate), apoi pe Y, apoi
    pe Z (virare), in jurul centrului ei."""
    rot = (Matrix.Rotation(math.radians(rot_z), 3, "Z")
           @ Matrix.Rotation(math.radians(rot_y), 3, "Y")
           @ Matrix.Rotation(math.radians(rot_x), 3, "X"))
    b.box(center, size, slot, rotation=rot)


def cut_marble_block(marble, base, center_xy, size, z0=0.0, yaw_deg=0.0,
                     base_frac=1.0 / 3.0, chip=0.0, chip_corner=(1, 1)):
    """Bloc de marmura TAIAT CU FIR: fete drepte, muchii vii (fara teșire
    rotunda), doua tonuri ca NODURI SEPARATE (kit §0 regula 8).

    marble / base  Builder-ele nodurilor `*_Marble` si `*_MarbleBase`
    center_xy      (x, y) al centrului amprentei
    size           (lx, ly, lz) in metri
    z0             cota talpii
    yaw_deg        rotatia pe verticala
    base_frac      cat din inaltime e patina (treimea de jos)
    chip           cat cade un colt de sus (un colt SPART in plan inclinat, nu
                   zgomot): 0 = cutie perfecta; chip_corner = (sx, sy) colțul

    Partea de sus se construieste ca invelitoare convexa din 8 puncte (un colt
    coborat da o fatetă mare, taiata drept); baza e o cutie. Cele doua se
    ating pe un plan la z0 + base_frac*lz, deci fara goluri."""
    lx, ly, lz = size
    cx, cy = center_xy
    zb = z0 + lz * base_frac
    zt = z0 + lz
    rot = Matrix.Rotation(math.radians(yaw_deg), 3, "Z")

    def corner(sx, sy, z):
        p = rot @ Vector((sx * lx * 0.5, sy * ly * 0.5, 0.0))
        return Vector((cx + p.x, cy + p.y, z))

    base_pts = [corner(sx, sy, z) for sx in (-1, 1) for sy in (-1, 1) for z in (z0, zb)]
    _hull(base, base_pts, CRR_MARBLE_BASE)
    top_pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for z in (zb, zt):
                zz = z
                if z == zt and chip > 0 and (sx, sy) == tuple(chip_corner):
                    zz = zt - chip
                top_pts.append(corner(sx, sy, zz))
    _hull(marble, top_pts, CRR_MARBLE)


def wheel_crr(tyre, hub, cap, cx, cy, cz, radius, width, side, hub_slot=CRR_PAINT,
              seg=16, lugs=16, outer=True):
    """Roata de camion pe axa X: anvelopa (cilindru, `seg` laturi) cu `lugs`
    crampoane scurte pe banda de rulare (ies 4 cm) si, daca `outer`, janta (disc
    de vopsea in `hub`, capac de rugina in `cap`) iesita pe fata exterioara.
    `side` = +1 / -1 (partea masinii)."""
    tyre.cylinder((cx, cy, cz), radius, width, CRR_BLACK, segments=seg, axis="X")
    for k in range(lugs):
        a = 2.0 * math.pi * (k + 0.5) / lugs
        py = cy + math.cos(a) * (radius + 0.005)
        pz = cz + math.sin(a) * (radius + 0.005)
        rot = Matrix.Rotation(a, 3, "X")   # y local -> radial
        tyre.box((cx, py, pz), (width * 0.98, 0.07, 0.19), CRR_BLACK, rotation=rot)
    if outer:
        xo = cx + side * (width * 0.5)
        hub.cylinder((xo, cy, cz), radius * 0.50, 0.05, hub_slot, segments=10, axis="X")
        cap.cylinder((xo + side * 0.03, cy, cz), radius * 0.20, 0.05, CRR_RUST,
                     segments=8, axis="X")


def emit_crr(objs, path, ao, bevels=None, bevel=0.03, smooth_angle=40.0,
             bevel_angle=30.0, center_y=True):
    """Finish pe fiecare nod + export in assets/models/carrara/<path>.

    Offsetul de origine se calculeaza O DATA pe ansamblu (memoria finish-
    recentreaza-fiecare-nod-separat): amprenta centrata pe X si Y (bbox-ul
    tuturor nodurilor), talpa ansamblului la Z = 0. `bevels` = {sufix: latime}
    suprascrie `bevel` pe nodurile cu acel sufix (marmura: 0, muchii vii)."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    place = Vector((-(min(xs) + max(xs)) * 0.5,
                    -(min(ys) + max(ys)) * 0.5 if center_y else 0.0,
                    -min(zs)))
    total, per_node = 0, {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao, origin=None,
                    smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "carrara/" + path)
    CRR_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    return total


def report_crr():
    print()
    for path, tris, dims, per_node, kb in CRR_RESULTS:
        print("%-44s tris=%6d  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)
