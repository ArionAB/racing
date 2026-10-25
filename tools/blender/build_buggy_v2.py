"""Buggy v2 — primul vehicul al garajului v2, modelat dupa foaia de concept
docs/asset_briefs/img/vehicles/concept_buggy_v2.jpeg (prompturile si
metoda: docs/asset_briefs/garaj_prompturi_chatgpt.md §2.1 si §5).

  Buggy   vehicles/buggy_v2.glb
          Body + 2 lampi + 4 roti ca noduri separate (contractul din
          toy_driver_parts.py). NU inlocuieste toy_buggy.glb: .tres-ul se muta
          pe fisierul nou intr-un commit separat, dupa ce modelul s-a vazut in
          garaj.

Ce aduce fata de v1 (cutii + grinzi): silueta din foaie. Cuva e un LOFT de
sectiuni (in plan hexagonala, ingusta la bot, lata la cockpit), capota alba e o
pana care urca spre cockpit, rollcage-ul e din tuburi rotunde cu coturi
racordate, anvelopele sunt de revolutie cu umeri rotunzi.

Cotele vin din tabelul de contract (3.7 x 2.1, roata 0.42 x 0.36 — fizica
identica cu v1), formele din pixelii foii (vederile ortografice). Singura
abatere: arcul e mai inalt decat 1.5 m din prompt, fiindca figurina reala are
1.25 m de la sezut la varful castii (prompt-ul presupunea 1.1) si foaia o
arata SUB acoperisul cusii.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_buggy_v2.py
Verificare (avertismentul de roata tangenta la sol e asteptat, vezi
build_toy_buggy.py):
    python tools/blender/verify_glb.py assets/models/vehicles/buggy_v2.glb 5000 --origin=assembly
Plansa de comparatie cu foaia (dupa rulare):
    python tools/blender/compare_concept.py buggy_v2 concept_buggy_v2.jpeg
"""

import math
import os
from mathutils import Matrix, Vector

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "toy_driver_parts.py")).read())

PAINT = CAR_YELLOW
HOOD = FOAM_WHITE
DARK = VOLCANIC_BLACK         # cusca, bara, sasiu, motor (nu ROCK_DARK: iese rugina)
SEAT_SLOT = LOG_DARK

# --- contract (garaj_prompturi_chatgpt.md, randul 1) ------------------------
WHEEL_R = 0.42
WHEEL_W = 0.42                 # foaia le arata late; latimea e doar vizuala
HALF_TRACK = 0.84              # 2.1 peste roti: 0.84 + 0.21
Y_FRONT = -1.30                # ampatament 2.66, din foaie (fata = -Y)
Y_REAR = 1.36
SEAT = (0.0, 0.18, 0.48)       # sezutul figurinei; picioarele coboara 0.41 sub el
TOP = 1.82                     # axa tubului de acoperis: casca + 9 cm
TUBE = 0.045                   # raza tuburilor de cusca


# =============================================================================
# Primitive de forma (locale garajului v2)
# =============================================================================
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


def tube(b, pts, slot=None, r=TUBE, fillet=0.12):
    """Tub rotund (8 laturi) pe o polilinie, cu coturi racordate."""
    return b.sweep(_fillet(pts, fillet), r, DARK if slot is None else slot,
                   segments=8, dome_end=False, cap_start=True)


def rod(b, p1, p2, r, slot, segments=8):
    """Cilindru orientat intre doua puncte (Builder.cylinder stie doar axe)."""
    return b.sweep([p1, p2], r, slot, segments=segments, dome_end=False, cap_start=True)


def toy_wheel_fn(radius, width, segments=20, hub_frac=0.60):
    """Anvelopa de revolutie in jurul lui X, cu umeri rotunzi (profilul de mai
    jos, shade smooth il netezeste), plus discul de jenta plat, putin retras."""
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


# =============================================================================
# Corpul
# =============================================================================
def tub(b):
    """Cuva deschisa: sectiune in U (perete exterior fatetat, perete interior
    drept, podea). In plan hexagonala, ca in vederea de sus a foii."""
    # (y, jumatate de latime sus, z sus, z jos, z podea)
    st = [(-1.07, 0.56, 0.86, 0.58, 0.66),
          (-0.88, 0.63, 0.90, 0.40, 0.46),
          (-0.60, 0.70, 0.93, 0.30, 0.38),
          (-0.05, 0.75, 0.93, 0.30, 0.38),
          (0.70, 0.64, 0.93, 0.30, 0.38),
          (0.96, 0.58, 0.93, 0.76, 0.84)]
    secs = []
    for y, hw, zt, zb, zf in st:
        zm = zb + 0.45 * (zt - zb)
        wall = 0.14
        right = [(hw - wall, zt), (hw - 0.05, zt), (hw, zt - 0.07),
                 (hw - 0.02, zm), (hw - 0.20, zb)]
        poly = right + [(-x, z) for x, z in reversed(right)]
        poly += [(-(hw - wall), zf), (hw - wall, zf)]
        secs.append((y, poly))
    loft(b, secs, PAINT)


def nose(b):
    """Botul galben si capota alba-pana deasupra lui."""
    yel = []
    for y, hw, zb, zt in ((-1.72, 0.36, 0.44, 0.70), (-1.45, 0.46, 0.40, 0.76),
                          (-1.05, 0.58, 0.36, 0.84), (-0.58, 0.66, 0.36, 0.90)):
        yel.append((y, mirror_poly([(hw - 0.08, zt), (hw, zt - 0.08),
                                    (hw, zb + 0.10), (hw - 0.12, zb)])))
    loft(b, yel, PAINT)
    wht = []
    for y, hw, zb, zt in ((-1.75, 0.34, 0.60, 0.74), (-1.45, 0.43, 0.70, 0.84),
                          (-1.05, 0.55, 0.78, 0.93), (-0.62, 0.63, 0.84, 1.00)):
        wht.append((y, mirror_poly([(hw - 0.10, zt), (hw, zt - 0.06),
                                    (hw + 0.01, zb)])))
    loft(b, wht, HOOD)
    # buza din fata cockpitului (bordul), peste capatul capotei
    b.box((0.0, -0.55, 0.93), (1.10, 0.14, 0.16), PAINT)


def lights_and_guard(b):
    """Farurile rotunde pe o bara, bara de protectie in U sub ele."""
    for sx in (-1, 1):
        x = sx * 0.32
        lamp_head_round((x, -1.775, 0.66), 0.12, 0.08, segments=10)
        b.cylinder((x, -1.755, 0.66), 0.145, 0.07, DARK, segments=10, axis="Y")
        tube(b, [(x, -1.74, 0.66), (x * 0.9, -1.60, 0.62)])
    tube(b, [(0.32, -1.74, 0.66), (-0.32, -1.74, 0.66)], r=0.04)
    tube(b, [(0.40, -1.62, 0.50), (0.44, -1.82, 0.50), (0.44, -1.82, 0.28),
             (-0.44, -1.82, 0.28), (-0.44, -1.82, 0.50), (-0.40, -1.62, 0.50)],
         fillet=0.10)


def cage(b):
    """Cusca: doi stalpi inclinati din bord pana la acoperis, arcul principal
    in spatele scaunului, apoi bratele care coboara peste motor la stopuri."""
    for sx in (-1, 1):
        # acoperisul se arcuieste in hexagon (vederea de sus a foii)
        tube(b, [(sx * 0.62, -0.60, 0.93), (sx * 0.48, -0.10, TOP),
                 (sx * 0.60, 0.33, TOP), (sx * 0.50, 0.75, TOP), (sx * 0.46, 1.66, 1.00),
                 (sx * 0.46, 1.70, 0.46)], fillet=0.16)
        # sasiul de jos: de sub cuva pana la stalpii din spate
        tube(b, [(sx * 0.40, 0.92, 0.42), (sx * 0.46, 1.70, 0.46)], r=0.04)
    tube(b, [(0.54, 0.80, 0.93), (0.50, 0.75, TOP), (-0.50, 0.75, TOP),
             (-0.54, 0.80, 0.93)], fillet=0.16)
    tube(b, [(0.48, -0.10, TOP), (-0.48, -0.10, TOP)])
    tube(b, [(0.46, 1.66, 1.00), (-0.46, 1.66, 1.00)])
    tube(b, [(0.46, 1.70, 0.46), (-0.46, 1.70, 0.46)])
    # diagonala din arcul principal: singura bara care rupe dreptunghiul
    tube(b, [(0.50, 0.77, 1.70), (-0.52, 0.80, 1.00)], r=0.04)
    for sx in (-1, 1):
        lamp_tail((sx * 0.46, 1.735, 0.84), (0.11, 0.05, 0.20))


def suspension(b):
    """Brate in A si amortizoare cu arc, la vedere (memorabile in foaie).
    Tuburi cu 6 laturi, nu 8: suspensia era 40% din corp (2096 tri) si de la
    12 m nu se vede diferenta."""
    for y0, inner in ((Y_FRONT, 0.48), (Y_REAR, 0.44)):
        for sx in (-1, 1):
            hub = Vector((sx * (HALF_TRACK - WHEEL_W * 0.5 - 0.04), y0, WHEEL_R))
            b.box(tuple(hub), (0.08, 0.16, 0.26), DARK)
            for dz, zin in ((0.10, 0.62), (-0.08, 0.40)):
                end = hub + Vector((0.0, 0.0, dz))
                for dy in (-0.16, 0.16):
                    rod(b, (sx * inner, y0 + dy, zin), tuple(end), 0.035, DARK, 6)
            top = Vector((sx * (inner + 0.02), y0 + 0.06, 0.88))
            bot = hub + Vector((-sx * 0.05, 0.0, 0.08))
            rod(b, tuple(top), tuple(bot), 0.035, DARK, 6)
            axis = (bot - top)
            for t in (0.25, 0.45, 0.65):
                c = top + axis * t
                rod(b, tuple(c - axis.normalized() * 0.03),
                    tuple(c + axis.normalized() * 0.03), 0.075, DARK, 6)


def seat_and_wheel(b):
    sx_, sy, sz = SEAT
    b.box((0.0, sy + 0.02, sz - 0.05), (0.58, 0.56, 0.10), SEAT_SLOT)
    b.box((0.0, sy + 0.32, sz + 0.36), (0.58, 0.12, 0.76), SEAT_SLOT, rotation=rx(-12.0))
    for s in (-1, 1):
        b.box((s * 0.30, sy + 0.16, sz + 0.12), (0.08, 0.40, 0.30), SEAT_SLOT)
    # volanul: mainile figurinei ajung la y = sezut - 0.52, z = sezut + 0.5
    col_top = (0.0, sy - 0.48, sz + 0.52)
    b.beam((0.0, -0.52, 0.86), col_top, 0.05, DARK)
    b.torus(col_top, 0.24, 0.035, DARK, major_seg=12, minor_seg=5, axis="Y")


def engine(b):
    """Motorul la vedere in spatele scaunului, pe o tava galbena, cu teava
    groasa spre spate."""
    b.box((0.0, 1.25, 0.52), (0.90, 0.80, 0.18), PAINT)
    b.box((0.0, 1.12, 0.82), (0.80, 0.62, 0.40), DARK)
    for sx in (-1, 1):
        b.box((sx * 0.19, 1.12, 1.11), (0.30, 0.56, 0.20), DARK, rotation=ry(sx * 12.0))
    rod(b, (0.12, 1.36, 0.98), (0.12, 1.80, 1.04), 0.10, DARK, segments=12)
    rod(b, (0.12, 1.76, 1.035), (0.12, 1.85, 1.045), 0.125, DARK, segments=12)


def buggy(b):
    tub(b)
    nose(b)
    lights_and_guard(b)
    cage(b)
    suspension(b)
    seat_and_wheel(b)
    engine(b)


# =============================================================================
# Previzualizare: figurina neexportata + vederi ortografice ca in foaie
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


def ortho(path, view, scale=4.4, res=(640, 480)):
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
    cz = 0.85
    if view == "side":       # din stanga (+X), fata in stanga imaginii
        cam.location = (12.0, 0.0, cz)
        cam.rotation_euler = (math.pi / 2, 0.0, math.pi / 2)
    elif view == "front":    # din fata (-Y)
        cam.location = (0.0, -12.0, cz)
        cam.rotation_euler = (math.pi / 2, 0.0, 0.0)
    else:                    # de sus, fata in stanga
        cam.location = (0.0, 0.0, 12.0)
        cam.rotation_euler = (0.0, 0.0, math.pi / 2)
    prev = scene.camera
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    scene.camera = prev
    return path


if __name__ == "__main__":
    clear_built()
    objs = export_vehicle(
        "Buggy", buggy,
        dict(radius=WHEEL_R, width=WHEEL_W, half_track=HALF_TRACK,
             y_front=Y_FRONT, y_rear=Y_REAR,
             wheel_fn=toy_wheel_fn(WHEEL_R, WHEEL_W), wheel_bevel=0.0),
        "vehicles/buggy_v2.glb", SEAT, bevel=0.03, bevel_angle=65.0)

    g = dict(globals())
    exec(open(os.path.join(HERE_PARTS, "preview.py")).read(), g)
    out_dir = os.path.join(PROJECT, "snapshots", "garaj_v2")
    os.makedirs(out_dir, exist_ok=True)
    driver = preview_driver(CAR_BLUE)
    seat_driver(driver, SEAT)
    g["shot"](objs + driver, os.path.join(out_dir, "buggy_v2_hero.png"),
              azimuth=-52.0, elevation=13.0, margin=1.3)
    for o in driver:
        o.hide_render = True
    ground = bpy.data.objects.get("PreviewGround")
    for view in ("side", "front", "top"):
        if ground is not None:
            ground.hide_render = view == "top"
        ortho(os.path.join(out_dir, "buggy_v2_%s.png" % view), view)
    print("PREVIEW: %s/buggy_v2_*.png" % out_dir)
