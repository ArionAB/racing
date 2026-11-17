"""Vocabularul de forme al valului 3 San Francisco (structurile): exec-uit de
`build_sf_struct.py` DUPA dio_lib (globalele lui: Builder, bake_ao, sloturile).

Doar geometrie bruta, in coordonate Blender (X = latimea, Y = -Z Godot = FATA, Z = sus):
  box_mm        cutie data prin intervale (x0..x1, y0..y1, z0..z1)
  prism_xz      contur (x, z) extrudat pe Y (frontonul magaziei, profilul scarii)
  prism_yz      contur (y, z) extrudat pe X (zidurile scarii, profilul treptelor)
  annulus       inel gros (sector de inel) -- bordura placii, dunga galbena
  hull          invelitoarea convexa a unui nor de puncte (acoperis in patru ape, coroane)
  loft          tub cu sectiune ELIPTICA variabila pe un traseu (corpul leului de mare)
  move_verts    transforma varfurile create de un apel (pozitia unui leu pe pluta)
  ao_mul        inmulteste AO-ul copt cu o functie de pozitie
"""

import math
import bmesh
from mathutils import Matrix, Vector


def box_mm(b, x0, x1, y0, y1, z0, z1, slot, rot=None):
    return b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                 (x1 - x0, y1 - y0, z1 - z0), slot, rotation=rot)


def _prism(b, lo_pts, hi_pts, slot):
    lo = [b.bm.verts.new(p) for p in lo_pts]
    hi = [b.bm.verts.new(p) for p in hi_pts]
    n = len(lo)
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def prism_xz(b, outline, y0, y1, slot):
    """Contur (x, z) extrudat pe Y intre y0 si y1."""
    return _prism(b, [(x, y0, z) for x, z in outline], [(x, y1, z) for x, z in outline], slot)


def prism_yz(b, outline, x0, x1, slot):
    """Contur (y, z) extrudat pe X intre x0 si x1."""
    return _prism(b, [(x0, y, z) for y, z in outline], [(x1, y, z) for y, z in outline], slot)


def annulus(b, r0, r1, z0, z1, slot, seg=32, a0=0.0, a1=2.0 * math.pi, center=(0.0, 0.0),
            bottom=True):
    """Inel gros (sau sector de inel) intre razele r0 < r1, cotele z0 < z1."""
    full = abs((a1 - a0) - 2.0 * math.pi) < 1e-6
    n = seg if full else seg + 1
    cx, cy = center

    def ring(r, z):
        out = []
        for k in range(n):
            a = a0 + (a1 - a0) * k / seg
            out.append(b.bm.verts.new((cx + r * math.cos(a), cy + r * math.sin(a), z)))
        return out

    ib, ob, it, ot = ring(r0, z0), ring(r1, z0), ring(r0, z1), ring(r1, z1)
    m = seg
    for k in range(m):
        j = (k + 1) % n
        b.bm.faces.new((it[k], ot[k], ot[j], it[j]))            # sus
        b.bm.faces.new((ob[k], ob[j], ot[j], ot[k]))            # exterior
        b.bm.faces.new((ib[j], ib[k], it[k], it[j]))            # interior
        if bottom:
            b.bm.faces.new((ib[k], ib[j], ob[j], ob[k]))        # jos
    if not full:
        b.bm.faces.new((ib[0], ob[0], ot[0], it[0]))
        b.bm.faces.new((ib[-1], it[-1], ot[-1], ob[-1]))
    return b._tag(ib + ob + it + ot, slot)


def hull(b, pts, slot):
    """Invelitoarea convexa a `pts` (ca in angkor_shapes.hull)."""
    vs = [b.bm.verts.new(Vector(p)) for p in pts]
    bmesh.ops.remove_doubles(b.bm, verts=vs, dist=1e-4)
    vs = [v for v in vs if v.is_valid]
    res = bmesh.ops.convex_hull(b.bm, input=vs)
    junk = [g for g in set(res["geom_interior"]) | set(res["geom_unused"]) if g.is_valid]
    bmesh.ops.delete(b.bm, geom=junk, context="VERTS")
    faces = set()
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace) and f.is_valid:
            f[b.slot] = slot
            faces.add(f)
    return faces


def loft(b, path, radii, slot, side=(0, 1, 0), segments=8):
    """Tub cu sectiune ELIPTICA: `radii[i]` = (r_in_plan, r_lateral) sau 0 (varf).

    Traseul sta intr-un plan; `side` e normala planului (lateralul). Cadrul nu se
    rasuceste: r_in_plan e pe normala traseului IN plan (inaltimea corpului), r_lateral
    pe `side` (latimea). Asa un leu care se ridica in sus nu-si roteste sectiunea."""
    pts = [Vector(p) for p in path]
    frames = b._frames(pts, up=side)
    rings, new_verts = [], []
    for p, (_t, x, y), r in zip(pts, frames, radii):
        if not isinstance(r, (tuple, list)):
            if r <= 1e-5:
                v = b.bm.verts.new(p)
                rings.append([v])
                new_verts.append(v)
                continue
            r = (r, r)
        ring = []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ring.append(b.bm.verts.new(p + x * (r[0] * math.cos(a)) + y * (r[1] * math.sin(a))))
        rings.append(ring)
        new_verts.extend(ring)
    for lo, hi in zip(rings, rings[1:]):
        if len(lo) == 1:
            for i in range(segments):
                b.bm.faces.new((lo[0], hi[(i + 1) % segments], hi[i]))
        elif len(hi) == 1:
            for i in range(segments):
                b.bm.faces.new((lo[i], lo[(i + 1) % segments], hi[0]))
        else:
            for i in range(segments):
                j = (i + 1) % segments
                b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    if len(rings[0]) > 1:
        b.bm.faces.new(tuple(reversed(rings[0])))
    if len(rings[-1]) > 1:
        b.bm.faces.new(tuple(rings[-1]))
    return b._tag(new_verts, slot)


def move_verts(b, faces, mat):
    """Aplica `mat` (4x4) varfurilor fetelor date (o singura data pe varf)."""
    vs = set()
    for f in faces:
        vs.update(f.verts)
    for v in vs:
        v.co = mat @ v.co


def ao_mul(obj, fn):
    """AO *= fn(co) pe fiecare varf (fn intoarce un factor)."""
    ca = obj.data.color_attributes["AO"]
    for i, v in enumerate(obj.data.vertices):
        val = max(0.05, min(1.0, ca.data[i].color[0] * fn(v.co)))
        ca.data[i].color = (val, val, val, 1.0)


def ao_set_slots(obj, slots, val=1.0):
    """AO fix pe fetele unor sloturi (lumini: felinarul farului)."""
    uv = obj.data.uv_layers.active
    ca = obj.data.color_attributes["AO"]
    hit = set()
    for poly in obj.data.polygons:
        if int(uv.data[poly.loop_indices[0]].uv[0] * 32) in slots:
            hit.update(poly.vertices)
    for i in hit:
        ca.data[i].color = (val, val, val, 1.0)


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def hash01(a, b, seed=0):
    h = math.sin(a * 12.9898 + b * 78.233 + seed * 4.1) * 43758.5453
    return h - math.floor(h)
