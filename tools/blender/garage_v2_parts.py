"""Primitive de forma si previzualizare comune garajului v2 (masinile refacute
dupa foile de concept, docs/asset_briefs/garaj_prompturi_chatgpt.md §5).

Se incarca DUPA toy_driver_parts.py, in aceleasi globale:
    HERE = os.path.dirname(os.path.abspath(__file__))
    exec(open(os.path.join(HERE, "toy_driver_parts.py")).read())
    exec(open(os.path.join(HERE, "garage_v2_parts.py")).read())

Ce e aici si de ce:
  loft / mirror_poly   corpuri din sectiuni (x, z) la cote y — silueta din foaie,
                       nu cutii stivuite
  tube / rod           tuburi rotunde orientate oriunde (cusca, bare, brate)
  toy_wheel_fn         anvelopa de revolutie cu umeri rotunzi + disc de jenta
  preview_sheet        3/4 cu figurina + lateral/fata/sus ORTOGRAFIC la aceeasi
                       scara, pentru compare_concept.py

Lectii de la buggy (primul vehicul):
  - figurina are 1.25 m de la sezut la varful castii si picioarele coboara
    0.41 m sub sezut: orice acoperis/arc trece peste casca, iar sezutul nu
    coboara sub podea + 0.41 (pantofii ar iesi prin fundul masinii);
  - corpul cu tuburi se exporta cu `bevel_angle=65`: tuburile cu 6-8 laturi
    au fete la 45-60° si s-ar tesi (de 3x mai multe triunghiuri); rotunjimea
    lor o da shade smooth.
"""

import math
import os
from mathutils import Matrix, Vector

TUBE_R = 0.045


def loft(b, sections, slot):
    """Solid inchis din sectiuni (x, z) la cote y date, toate cu acelasi numar
    de puncte, in aceeasi ordine. Capetele se inchid cu poligonul sectiunii,
    triangulat (sectiunile in U sunt concave)."""
    rings = []
    verts = []
    for y, poly in sections:
        ring = [b.bm.verts.new((x, y, z)) for x, z in poly]
        rings.append(ring)
        verts.extend(ring)
    n = len(rings[0])
    for lo, hi in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    caps = [b.bm.faces.new(tuple(reversed(rings[0]))), b.bm.faces.new(tuple(rings[-1]))]
    bmesh.ops.triangulate(b.bm, faces=caps, quad_method="BEAUTY", ngon_method="BEAUTY")
    return b._tag(verts, slot)


def mirror_poly(right):
    """Poligon simetric: `right` merge pe partea +X de sus in jos; intoarce
    conturul inchis (dreapta in jos, apoi stanga in sus)."""
    return list(right) + [(-x, z) for x, z in reversed(right)]


def u_section(hw, zt, zb, zf, wall=0.14):
    """Sectiunea in U a unei cuve deschise (perete exterior fatetat, perete
    interior drept, podea la zf). Pentru loft: zb < zf < zt."""
    zm = zb + 0.45 * (zt - zb)
    right = [(hw - wall, zt), (hw - 0.05, zt), (hw, zt - 0.07),
             (hw - 0.02, zm), (hw - 0.20, zb)]
    poly = right + [(-x, z) for x, z in reversed(right)]
    return poly + [(-(hw - wall), zf), (hw - wall, zf)]


def _fillet(pts, r):
    """Racordeaza colturile unei polilinii: fiecare colt interior devine trei
    puncte pe o parabola, ca inelele tubului sa nu se strice in cot."""
    pts = [Vector(p) for p in pts]
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        p, a, c = pts[i], pts[i - 1], pts[i + 1]
        da, dc = (a - p), (c - p)
        f = min(r, da.length * 0.45, dc.length * 0.45)
        pa = p + da.normalized() * f
        pc = p + dc.normalized() * f
        out += [pa, pa * 0.25 + p * 0.5 + pc * 0.25, pc]
    out.append(pts[-1])
    return out


def tube(b, pts, slot=None, r=TUBE_R, fillet=0.12, segments=8):
    """Tub rotund pe o polilinie, cu coturi racordate."""
    return b.sweep(_fillet(pts, fillet), r, VOLCANIC_BLACK if slot is None else slot,
                   segments=segments, dome_end=False, cap_start=True)


def rod(b, p1, p2, r, slot, segments=8):
    """Cilindru orientat intre doua puncte (Builder.cylinder stie doar axe)."""
    return b.sweep([p1, p2], r, slot, segments=segments, dome_end=False, cap_start=True)


def toy_wheel_fn(radius, width, segments=20, hub_frac=0.60):
    """Anvelopa de revolutie in jurul lui X, cu umeri rotunzi (shade smooth ii
    netezeste), plus discul de jenta plat, putin retras. Se potriveste cu
    `wheel_spec["wheel_factory"]` din toy_driver_parts.vehicle_wheels."""
    hw = width * 0.5
    prof = [(0.62, -0.92), (0.86, -1.0), (0.97, -0.82), (1.0, -0.42),
            (1.0, 0.42), (0.97, 0.82), (0.86, 1.0), (0.62, 0.92)]

    def build(b):
        rings = []
        verts = []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ca, sa = math.cos(a), math.sin(a)
            ring = [b.bm.verts.new((x * hw, r * radius * ca, r * radius * sa))
                    for r, x in prof]
            rings.append(ring)
            verts.extend(ring)
        n = len(prof)
        for k in range(segments):
            lo, hi = rings[k], rings[(k + 1) % segments]
            for i in range(n):
                j = (i + 1) % n
                b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        b._tag(verts, TIRE)
        b.cylinder((0.0, 0.0, 0.0), radius * hub_frac, width * 0.88, RIM,
                   segments=16, axis="X")
    return build


def steering_wheel(b, seat, slot=None, col_base=None):
    """Volanul acolo unde ajung mainile figurinei: y = sezut - 0.48,
    z = sezut + 0.52, pe axa x a soferului. `col_base` = unde intra coloana in
    bord (implicit 0.34 m in fata volanului si 0.16 mai jos)."""
    slot = VOLCANIC_BLACK if slot is None else slot
    x, y, z = seat
    top = (x, y - 0.48, z + 0.52)
    base = col_base or (x, y - 0.82, z + 0.36)
    b.beam(base, top, 0.05, slot)
    b.torus(top, 0.24, 0.035, slot, major_seg=12, minor_seg=5, axis="Y")


# =============================================================================
# Previzualizare
# =============================================================================
def preview_driver(shirt):
    """Aceeasi figurina ca build_driver, dar fara export: un build de masina nu
    are voie sa rescrie GLB-urile de sofer pe care le incarca jocul."""
    return [
        part("Hips", build_hips, (0.0, 0.0, 0.0)),
        part("Torso", build_torso, (0.0, 0.0, HIP_H), AO_PART, 0.02, shirt),
        part("Head", build_head, (0.0, 0.0, NECK_Z), AO_PART, 0.02, shirt),
        part("Arm_L", build_arm, (-SHOULDER[0], SHOULDER[1], SHOULDER[2]),
             AO_PART, 0.02, shirt),
        part("Arm_R", build_arm, (SHOULDER[0], SHOULDER[1], SHOULDER[2]),
             AO_PART, 0.02, shirt),
        part("Leg_L", build_leg, (-HIP_JOINT[0], HIP_JOINT[1], HIP_JOINT[2])),
        part("Leg_R", build_leg, (HIP_JOINT[0], HIP_JOINT[1], HIP_JOINT[2])),
    ]


def ortho(path, view, scale=6.4, cz=1.0, res=(640, 480)):
    """Vedere ortografica la scara fixa (aceeasi pentru lateral/fata/sus, ca in
    foaie). Camera separata: `shot` refoloseste PreviewCam in perspectiva."""
    scene = bpy.context.scene
    cam = bpy.data.objects.get("OrthoCam")
    if cam is None:
        data = bpy.data.cameras.new("OrthoCam")
        data.type = "ORTHO"
        cam = bpy.data.objects.new("OrthoCam", data)
        scene.collection.objects.link(cam)
    cam.data.ortho_scale = scale
    if view == "side":       # din stanga (+X), fata in stanga imaginii
        cam.location = (15.0, 0.0, cz)
        cam.rotation_euler = (math.pi / 2, 0.0, math.pi / 2)
    elif view == "front":    # din fata (-Y)
        cam.location = (0.0, -15.0, cz)
        cam.rotation_euler = (math.pi / 2, 0.0, 0.0)
    else:                    # de sus, fata in stanga
        cam.location = (0.0, 0.0, 15.0)
        cam.rotation_euler = (0.0, 0.0, math.pi / 2)
    prev = scene.camera
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    scene.camera = prev
    return path


def preview_sheet(name, objs, seat, shirt=None, length=4.2):
    """Scrie snapshots/garaj_v2/<name>_{hero,side,front,top}.png, dupa export.
    Scara ortografica = 1.2 x lungimea, aceeasi pe toate trei vederile.
    Apoi: python tools/blender/compare_concept.py <name> <foaia>.jpeg"""
    g = dict(globals())
    exec(open(os.path.join(HERE_PARTS, "preview.py")).read(), g)
    out_dir = os.path.join(PROJECT, "snapshots", "garaj_v2")
    os.makedirs(out_dir, exist_ok=True)
    driver = preview_driver(CAR_BLUE if shirt is None else shirt)
    seat_driver(driver, seat)
    g["shot"](objs + driver, os.path.join(out_dir, "%s_hero.png" % name),
              azimuth=-52.0, elevation=13.0, margin=1.3)
    for o in driver:
        o.hide_render = True
    ground = bpy.data.objects.get("PreviewGround")
    scale = max(4.4, length * 1.2)
    for view in ("side", "front", "top"):
        if ground is not None:
            ground.hide_render = view == "top"
        ortho(os.path.join(out_dir, "%s_%s.png" % (name, view)), view,
              scale=scale, cz=scale * 0.19)
    print("PREVIEW: %s/%s_*.png" % (out_dir, name))
