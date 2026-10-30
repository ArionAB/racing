"""Carrara -- kitul de cariera (brief docs/asset_briefs/carrara_kit.md §1.5).

  carrara/rocks/marble_block_a.glb, _b, _c   blocuri taiate (1,5 / 2 / 3x2x2 m)
  carrara/rocks/block_stack_a.glb, _b        stive de 2 si 3 blocuri
  carrara/rocks/block_informe_b.glb          bucata sparta, turtita (2 m)
  carrara/rocks/rubble_pile_a.glb, _b        gramezi de moloz unghiular
  carrara/structures/safety_berm.glb         modul de berma 6 m, inlantuibil
  carrara/props/work_lamp.glb                trepied cu doua reflectoare
  carrara/props/cable_reel.glb               tambur de cablu
  carrara/props/water_tank.glb               rezervor vertical pe picioare
  carrara/props/fuel_tank.glb                rezervor orizontal de motorina
  carrara/buildings/office_container.glb     container de santier
  carrara/props/quarry_sign_a.glb, _b        semne cu pictograma (fara text)
  carrara/props/pipe_run.glb                 modul de conducte 6 m, inlantuibil

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_kit.py
Variabila de mediu CRR_ONLY=<piesa>[,<piesa>] reface doar piesele respective.

Axe: X latime, Y lungime (fata spre +Y in Blender = -Z in Godot), Z sus.
Originea pe centrul amprentei, la sol (offset calculat O DATA pe ansamblu).

Ajutoarele noi (in fisierul asta, nu in carrara_shapes.py):
  open_box         cutie cu fete alese (fara fata comuna dintre *_Marble si
                   *_MarbleBase: 10 + 10 triunghiuri in loc de 12 + 12)
  split_block      bloc taiat cu fir in doua noduri, pe open_box
  chip_pts         punctele unei cutii cu colturi SPARTE plan (fatete mari)
  hull_two_tone    invelitoare convexa taiata plan la o cota: sub ea pe
                   *_MarbleBase, peste ea pe *_Marble
  emit_kit         ca emit_crr, plus offset dat explicit si z_range-ul AO pe
                   ansamblu
"""

import math
import os
import random
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "carrara_shapes.py"), encoding="utf-8").read())

ONLY = [s for s in os.environ.get("CRR_ONLY", "").split(",") if s]


def _want(name):
    return not ONLY or name in ONLY


# ---------------------------------------------------------------------------
# ajutoare
# ---------------------------------------------------------------------------

def open_box(b, center, size, slot, yaw_deg=0.0, drop=(), rot=None):
    """Cutie (centru, dimensiuni) cu fetele din `drop` omise ('top', 'bottom').
    Infasurarea e scrisa explicit spre exterior (cutia deschisa nu e un solid
    inchis, deci recalc_face_normals nu trebuie sa ghiceasca)."""
    cx, cy, cz = center
    lx, ly, lz = size
    r = rot if rot is not None else Matrix.Rotation(math.radians(yaw_deg), 3, "Z")
    v = {}
    for ix in (0, 1):
        for iy in (0, 1):
            for iz in (0, 1):
                p = r @ Vector(((ix - 0.5) * lx, (iy - 0.5) * ly, (iz - 0.5) * lz))
                v[(ix, iy, iz)] = b.bm.verts.new((cx + p.x, cy + p.y, cz + p.z))
    faces = {
        "bottom": ((0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)),
        "top": ((0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)),
        "-x": ((0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)),
        "+x": ((1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)),
        "-y": ((0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)),
        "+y": ((0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)),
    }
    for k, idx in faces.items():
        if k in drop:
            continue
        f = b.bm.faces.new([v[i] for i in idx])
        f[b.slot] = slot


def split_block(marble, base, center_xy, size, z0=0.0, yaw_deg=0.0, base_frac=1.0 / 3.0):
    """Bloc taiat cu fir pe doua noduri (kit §0 regula 8), fara fata comuna:
    baza (MARBLE_GREY) = 5 fete, partea in lumina (CORAL_SAND) = 5 fete.
    20 de triunghiuri pe bloc; muchii vii."""
    lx, ly, lz = size
    zb = lz * base_frac
    open_box(base, (center_xy[0], center_xy[1], z0 + zb * 0.5), (lx, ly, zb),
             CRR_MARBLE_BASE, yaw_deg, drop=("top",))
    open_box(marble, (center_xy[0], center_xy[1], z0 + zb + (lz - zb) * 0.5),
             (lx, ly, lz - zb), CRR_MARBLE, yaw_deg, drop=("bottom",))


def chip_pts(size, rnd, chips=4, lo=0.18, hi=0.42, corners=None, rot=None,
             center=(0.0, 0.0, 0.0)):
    """Punctele unei cutii `size` cu `chips` colturi SPARTE: coltul e inlocuit
    de trei puncte pe cele trei muchii ale lui, la o fractiune aleatoare din
    latura respectiva -> o fateta mare, plana, triunghiulara (spartura, nu
    zgomot). `corners` alege explicit colturile (lista de (sx, sy, sz))."""
    lx, ly, lz = size
    allc = [(sx, sy, sz) for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
    chosen = set(corners) if corners is not None else set(rnd.sample(allc, chips))
    r = rot if rot is not None else Matrix.Identity(3)
    c0 = Vector(center)
    pts = []
    for (sx, sy, sz) in allc:
        c = Vector((sx * lx * 0.5, sy * ly * 0.5, sz * lz * 0.5))
        if (sx, sy, sz) in chosen:
            sg = (sx, sy, sz)
            for ax in range(3):
                p = c.copy()
                p[ax] -= sg[ax] * (lo + (hi - lo) * rnd.random()) * size[ax]
                pts.append(r @ p + c0)
        else:
            pts.append(r @ c + c0)
    return pts


def _swap_yz(pts):
    return [Vector((p[0], p[2], p[1])) for p in pts]


def clip_z(pts, z_lo, z_hi):
    """Politopul conv(pts) taiat plan la z_lo <= z <= z_hi (refoloseste
    _clip_hull_pts, care taie pe Y, prin schimbarea axelor)."""
    return _swap_yz(_clip_hull_pts(_swap_yz(pts), z_lo, z_hi))


def _solid(pts):
    if len(pts) < 4:
        return False
    for ax in range(3):
        vals = [p[ax] for p in pts]
        if max(vals) - min(vals) < 1e-3:
            return False
    return True


def hull_two_tone(marble, base, pts, z_cut, ground=True):
    """Hull taiat la sol (z >= 0) si spart la `z_cut`: partea de jos pe
    *_MarbleBase (patina), cea de sus pe *_Marble. Planul comun nu se vede
    (cele doua jumatati se ating exact)."""
    pts = [Vector(p) for p in pts]
    if ground:
        pts = clip_z(pts, 0.0, 1e6)
    lo = clip_z(pts, -1e6, z_cut)
    hi = clip_z(pts, z_cut, 1e6)
    if _solid(lo) and base is not None:
        _hull(base, lo, CRR_MARBLE_BASE)
    if _solid(hi):
        _hull(marble, hi, CRR_MARBLE)


def rand_rot(rnd, tilt_deg=25.0):
    return (Matrix.Rotation(math.radians(rnd.uniform(0, 360)), 3, "Z")
            @ Matrix.Rotation(math.radians(rnd.uniform(-tilt_deg, tilt_deg)), 3, "X")
            @ Matrix.Rotation(math.radians(rnd.uniform(-tilt_deg, tilt_deg)), 3, "Y"))


def emit_kit(objs, path, ao, place=None, bevel=0.0, bevels=None, smooth_angle=40.0,
             bevel_angle=30.0, center_y=True):
    """Finish pe fiecare nod + export in assets/models/carrara/<path>.

    Offsetul de origine se calculeaza O DATA pe ansamblu (bbox-ul tuturor
    nodurilor: centrat pe X/Y, talpa la Z = 0), sau se da explicit cu `place`
    (piesele construite deja pe origine, la care o parte iesita -- treptele
    containerului, scara rezervorului -- ar muta originea de pe amprenta).
    Gradientul vertical al AO-ului se intinde pe inaltimea ANSAMBLULUI, nu a
    fiecarui nod (bake_ao, `z_range`)."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    if place is None:
        place = Vector((-(min(xs) + max(xs)) * 0.5,
                        -(min(ys) + max(ys)) * 0.5 if center_y else 0.0,
                        -min(zs)))
    place = Vector(place)
    ao = dict(ao)
    # cota de jos cu o marja: un -1e-17 din rotatii ar da t < 0, iar t ** power
    # iese numar complex in bake_ao
    ao.setdefault("z_range", (min(zs) + place.z - 1e-4, max(zs) + place.z))
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
    print("  bbox %s: X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f" %
          (path, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    return total


AO_BLOCK = dict(samples=12, dist=1.0, gradient="vertical", low=0.80, high=1.0,
                power=0.9, floor=0.5)
AO_ROCK = dict(samples=20, dist=0.9, gradient="vertical", low=0.66, high=1.0,
               power=0.8, floor=0.40)
AO_PROP = dict(samples=20, dist=0.8, gradient="vertical", low=0.70, high=1.0,
               power=0.8, floor=0.40)
BLOCK_BEVELS = {"_Marble": 0.0, "_MarbleBase": 0.0, "_Paint": 0.0}


# ---------------------------------------------------------------------------
# marble_block_a / _b / _c
# ---------------------------------------------------------------------------

def build_marble_block(size, paint=False):
    """LISTA DE ELEMENTE (decuparile `marble_block_a/b/c.png`, scrisa INAINTE de
    geometrie):

     1. Un singur bloc paralelipipedic, fete taiate drept, muchii VII (fara
        tesire): `_a` cub de 1,5 m, `_b` cub de 2 m, `_c` 3 x 2 x 2 m (X x Y x Z;
        pe decupare `_c` pare tot cub -- cotele din tabel bat planșa).
     2. Dungile orizontale de fir si venele de pe decupari NU sunt geometrie
        (kit §0 regula 7): le da clasa `carrara_marble` (dala rotita, dungi
        orizontale).
     3. Doua tonuri ca noduri separate (regula 8): treimea de jos pe
        MARBLE_GREY (`Block_MarbleBase`), restul pe CORAL_SAND (`Block_Marble`).
        Fata comuna dintre noduri NU se construieste: 10 + 10 = 20 de
        triunghiuri, nu 12 (abatere declarata in inventar: 12 triunghiuri
        si doua noduri nu se pot avea simultan).
     4. `_b`: o dunga de vopsea de 10 cm (`Block_Paint`, LAVA_ORANGE 30),
        verticala, pe fata +Y, in relief de 1 cm (0,14 m^2). Pe decupare nu se
        vede vopsea: elementul vine din tabelul de kit.
     5. Ce iese din contur: nimic (doar dunga, 1 cm).
    """
    marble, base, paint_b = Builder(), Builder(), Builder()
    lx, ly, lz = size
    split_block(marble, base, (0.0, 0.0), size)
    if paint:
        # dunga verticala, pe fata +Y, decalata spre dreapta; nu atinge muchiile
        paint_b.box((lx * 0.22, ly * 0.5 + 0.005, lz * 0.52), (0.10, 0.01, lz * 0.70),
                    LAVA_ORANGE)
    out = [marble.to_object("Block_Marble"), base.to_object("Block_MarbleBase")]
    if paint:
        out.append(paint_b.to_object("Block_Paint"))
    else:
        paint_b.bm.free()
    return out


# ---------------------------------------------------------------------------
# block_stack_a / _b
# ---------------------------------------------------------------------------

def build_block_stack(levels):
    """LISTA DE ELEMENTE (decuparile `block_stack_a/b.png`):

     1. `_a`: 2 blocuri, `_b`: 3 blocuri, unul PESTE altul (pe decupari stiva e
        verticala, nu alaturata), fiecare un paralelipiped separat (mase
        distincte, nu un prism): rostul dintre ele se vede ca umbra.
     2. Blocurile sunt lespezi de ~2 m lungime, mai joase decat late (pe
        decupari h/l ~1,25 pe toata stiva): 2,0-2,2 m x 1,7-2,0 m x 1,1-1,5 m;
        la `_b` cel de jos e cel mai mare, cel de sus cel mai mic.
     3. Fiecare bloc decalat 0,1-0,3 m fata de cel de dedesubt si rotit +-5 grade.
     4. Doua tonuri (regula 8): blocul de JOS are treimea de jos pe
        MARBLE_GREY (`Stack_MarbleBase`); restul blocurilor sunt intregi pe
        CORAL_SAND (`Stack_Marble`) -- patina vine de la sol, nu de la rost.
     5. Fara vene / dungi in geometrie (clasa).
    """
    marble, base = Builder(), Builder()
    z = 0.0
    for i, (size, off, yaw) in enumerate(levels):
        if i == 0:
            split_block(marble, base, off, size, z0=z, yaw_deg=yaw)
        else:
            open_box(marble, (off[0], off[1], z + size[2] * 0.5), size, CRR_MARBLE, yaw)
        z += size[2]
    return [marble.to_object("Stack_Marble"), base.to_object("Stack_MarbleBase")]


# ---------------------------------------------------------------------------
# block_informe_b
# ---------------------------------------------------------------------------

def build_block_informe_b():
    """LISTA DE ELEMENTE (decuparea `block_informe_b.png`; runda 2: runda 1 iesise
    o lespede cu capac tesit, decuparea e un BULGARE ingramadit, mai inalt la
    mijloc; runda 3: runda 2 tot lespede -- baza era o prisma dreapta, iar
    umflaturile prea joase, deci masa centrala urca si baza se sparge si ea):

     1. O bucata sparta de marmura, ~2,1 m in plan, TURTITA (~1,4 m; `_a` are
        3 m in toate directiile). Pe decupare h/l ~0,77 in 3/4.
     2. Masa principala: cutie 1,9 x 1,75 x 0,75 cu TOATE cele 8 colturi
        sparte (20-45% din latura): nici sus, nici la sol nu ramane o muchie
        dreapta de bloc. (Fata plana taiata drept e contractul lui `_a`, nu al
        lui `_b`: aici renunt la ea, decuparea n-o are.)
     3. 4 umflaturi sparte ingramadite peste ea: una centrala mare care da
        varful (~1,5 m), una la stanga, una in fata-dreapta, una in spate,
        fiecare cu 5-6 colturi sparte: cresta neregulata si concavitatile
        dintre mase de pe decupare (aici 5 mase convexe).
     4. Fara zgomot fin, fara bulgari rotunzi, umbrire PLATA (fatetele se vad).
     5. Doua tonuri: sub 0,22 m pe MARBLE_GREY (`Informe_MarbleBase`), peste pe
        CORAL_SAND (`Informe_Marble`), taiat plan prin toate masele.
    """
    marble, base = Builder(), Builder()
    rnd = random.Random(23)
    zc = 0.22
    main = chip_pts((1.9, 1.75, 0.75), rnd, chips=8, lo=0.20, hi=0.45,
                    center=(0.0, 0.0, 0.375))
    hull_two_tone(marble, base, main, zc)
    for size, ang, tilt, c in (((1.30, 1.15, 1.00), 20, (8, 6), (0.05, 0.05, 0.98)),
                               ((0.90, 1.00, 0.75), -25, (-14, 10), (-0.62, -0.10, 0.62)),
                               ((0.80, 0.75, 0.60), 35, (12, -8), (0.62, -0.50, 0.50)),
                               ((0.80, 0.70, 0.60), -10, (-8, 12), (0.35, 0.62, 0.55))):
        rot = (Matrix.Rotation(math.radians(ang), 3, "Z")
               @ Matrix.Rotation(math.radians(tilt[0]), 3, "X")
               @ Matrix.Rotation(math.radians(tilt[1]), 3, "Y"))
        pts = chip_pts(size, rnd, chips=rnd.choice((5, 6)), lo=0.22, hi=0.48, rot=rot, center=c)
        hull_two_tone(marble, base, pts, zc)
    return [marble.to_object("Informe_Marble"), base.to_object("Informe_MarbleBase")]


# ---------------------------------------------------------------------------
# rubble_pile_a / _b
# ---------------------------------------------------------------------------

def _mound_h(r, rings):
    """Inaltimea movilei (profil liniar pe portiuni) la raza r."""
    for (r0, z0), (r1, z1) in zip(rings, rings[1:]):
        if r0 >= r >= r1:
            t = (r0 - r) / max(r0 - r1, 1e-6)
            return z0 + (z1 - z0) * t
    return rings[-1][1] if r < rings[-1][0] else 0.0


def build_rubble_pile(seed, radius, height, counts):
    """LISTA DE ELEMENTE (decuparile `rubble_pile_a/b.png`; runda 2: in runda 1
    miezul se vedea ca o movila neteda cu cativa bolovani pe ea -- decuparea e
    numai fragmente, cu goluri intunecate intre ele; runda 3: flancul de jos
    inca arata miezul gri, deci miezul scade si inelele de jos cresc):

     1. Un miez de movila fatetat (con trunchiat, 10 laturi), MIC si ascuns sub
        fragmente, tot pe MARBLE_GREY (`Rubble_MarbleBase`): ce se vede din el
        se citeste ca golurile umbrite dintre bucati (patina, regula 8).
     2. FRAGMENTE UNGHIULARE pe CORAL_SAND (`Rubble_Marble`), fiecare o cutie
        cu 4-6 colturi sparte plan, rotita aleator (fatete mari, nu bulgari):
        - 2 mari in varf;
        - un inel interior de bucati mari, unul exterior de medii;
        - un inel de bucati mici la poala, pe sol.
        `_a` (O 4 m, 1,5 m): 2 + 6 + 9 + 8 = 25 de fragmente; `_b` (O 3 m,
        1,2 m): 2 + 5 + 8 + 7 = 22 (tabelul: 15-25).
     3. Umbrire PLATA (fatetele se vad). Coliziune `none` la integrare.
    """
    marble, base = Builder(), Builder()
    rnd = random.Random(seed)
    R, H = radius, height
    rings = [(R * 0.72, 0.0), (R * 0.45, H * 0.40), (R * 0.15, H * 0.58)]
    pts = []
    for k, (rr, zz) in enumerate(rings):
        for i in range(10):
            a = 2 * math.pi * (i + rnd.uniform(-0.3, 0.3) + 0.5 * k) / 10
            r = rr * rnd.uniform(0.88, 1.06)
            pts.append(Vector((r * math.cos(a), r * math.sin(a), zz)))
    _hull(base, clip_z(pts, 0.0, 1e6), CRR_MARBLE_BASE)
    k = R / 2.0
    tiers = [  # (rmin, rmax, s_lo, s_hi): razele in fractiuni de R, marimile scalate cu R / 2
        (0.0, 0.10 * R, 0.75 * k, 0.95 * k),
        (0.25 * R, 0.42 * R, 0.60 * k, 0.80 * k),
        (0.52 * R, 0.70 * R, 0.55 * k, 0.75 * k),
        (0.78 * R, 0.92 * R, 0.35 * k, 0.50 * k),
    ]
    for (rmin, rmax, slo, shi), n in zip(tiers, counts):
        off = rnd.uniform(0, 2 * math.pi)
        for i in range(n):
            a = off + 2 * math.pi * (i + rnd.uniform(-0.3, 0.3)) / n
            r = rnd.uniform(rmin, rmax)
            sz = rnd.uniform(slo, shi)
            size = (sz * rnd.uniform(0.85, 1.2), sz * rnd.uniform(0.75, 1.05), sz * rnd.uniform(0.7, 0.95))
            c = (r * math.cos(a), r * math.sin(a), _mound_h(r, rings) + size[2] * 0.15)
            p = chip_pts(size, rnd, chips=rnd.choice((4, 5, 6)), lo=0.18, hi=0.42,
                         rot=rand_rot(rnd, 25.0), center=c)
            p = clip_z(p, 0.0, 1e6)
            if _solid(p):
                _hull(marble, p, CRR_MARBLE)
    return [marble.to_object("Rubble_Marble"), base.to_object("Rubble_MarbleBase")]


# ---------------------------------------------------------------------------
# safety_berm
# ---------------------------------------------------------------------------

def build_safety_berm():
    """LISTA DE ELEMENTE (decuparea `safety_berm.png` + dioramă: blocurile
    insirate pe marginea teraselor; contract: modul 6 m pe Y, 0,6 m inalt,
    1,4 m lat, in panta spre drum -X, abrupt spre gol +X):

     1. Miez de moloz (`Berm_MarbleBase`, MARBLE_GREY): prisma extrudata pe
        toata lungimea, profil in panta lunga spre -X si cadere abrupta spre +X
        (x -0,70..0,66, varful 0,34 m la x 0,15).
     2. Randul din spate (+X): 9 blocuri (0,55-0,8 m lungime, ~0,5 m adanci,
        0,38-0,42 m inalte) asezate pe miez, fata dinspre gol aproape
        verticala, varful la ~0,6 m. 5 colturi sparte din 8 (runda 2: in runda 1
        erau lespezi aproape plate; decuparea are bolovani-bloc grosi),
        rotiri +-6 grade, rosturi de 6 cm.
     3. Randul din mijloc (spre drum, -X): 11 blocuri mai mici (0,4-0,6 m,
        0,30-0,34 m inalte), mai jos, aplecate 12 grade spre drum -> panta.
     4. Randul de la piciorul pantei (-X): 9 bucati de 0,3-0,5 m, 0,2-0,26 m
        inalte, aplecate 14 grade, cu rosturi largi (miezul gri se vede printre
        ele ca umbra).
     5. Blocurile pe CORAL_SAND (`Berm_Marble`). Pe decupare sunt bolovani
        rotunjiti cu flori galbene: florile NU (corectura: fara vegetatie lipita),
        iar regula 7 cere blocuri taiate/sparte, nu bulgari.
     6. Capete identice la +-3 m: rosturile sunt periodice pe 6 m si orice bloc
        care trece de un capat e taiat plan si reapare taiat la celalalt
        (`_emit_periodic_hull`) -> modulele se inlantuie fara cusatura.
    """
    marble, base = Builder(), Builder()
    L = 6.0
    rnd = random.Random(31)
    prof = [(-0.70, 0.0), (0.66, 0.0), (0.52, 0.30), (0.15, 0.34), (-0.38, 0.20)]
    extrude_xz(base, prof, -L * 0.5, L * 0.5, CRR_MARBLE_BASE)

    def row(n, wmin, wmax, xc, depth, hlo, hhi, z0, tilt_y, chips, slot_b, slot, gap=0.05):
        joints = _periodic_joints(rnd, L, n, wmin, wmax)
        for a, b in zip(joints, joints[1:]):
            yc = (a + b) * 0.5
            size = ((depth * rnd.uniform(0.85, 1.1)), (b - a) - gap, rnd.uniform(hlo, hhi))
            rot = (Matrix.Rotation(math.radians(rnd.uniform(-6, 6)), 3, "Z")
                   @ Matrix.Rotation(math.radians(tilt_y), 3, "Y"))
            c = (xc + rnd.uniform(-0.04, 0.04), yc, z0 + size[2] * 0.5)
            p = chip_pts(size, rnd, chips=chips, lo=0.15, hi=0.32, rot=rot, center=c)
            _emit_periodic_hull(slot_b, p, L, slot)

    row(9, 0.55, 0.80, 0.24, 0.50, 0.38, 0.42, 0.17, 0.0, 5, marble, CRR_MARBLE, gap=0.06)
    row(11, 0.40, 0.60, -0.20, 0.42, 0.30, 0.34, 0.03, -12.0, 5, marble, CRR_MARBLE, gap=0.06)
    row(9, 0.30, 0.50, -0.52, 0.26, 0.20, 0.26, 0.0, -14.0, 5, marble, CRR_MARBLE, gap=0.14)
    return [marble.to_object("Berm_Marble"), base.to_object("Berm_MarbleBase")]


# ---------------------------------------------------------------------------
# work_lamp
# ---------------------------------------------------------------------------

def build_work_lamp():
    """LISTA DE ELEMENTE (decuparea `work_lamp.png`):

     1. Trepied: 3 picioare (2 in fata la +-X, 1 in spate pe -Y), din butucul
        de la 1,40 m pana la sol pe o raza de 0,85 m; talpi negre mici. (Runda
        2: butucul urca de la 1,05 la 1,40 -- pe decupare picioarele ocupa
        jumatatea de jos, catargul e scurt.)
     2. 3 contravantuiri scurte intre catarg (0,80 m) si picioare.
     3. Catargul vertical (cilindru, 8 laturi) de la 0,75 m la 2,55 m, cu
        manson negru la butuc.
     4. Bara transversala (T) de 1,0 m pe X, sus.
     5. 2 reflectoare: carcase negre dreptunghiulare (0,46 x 0,18 x 0,36 m),
        fiecare pe o furca (2 brate), cu sticla pe +Y (`Lamp_Glow`,
        SAND_LIGHT 0) si un maner sus.
     6. Cablul negru: coboara pe catarg si pleaca pe sol spre spate.
     7. Culori: vopseaua trepiedului DRY_VEGETATION 13 (galben-spalacit, NU
        galbenul planșei), carcasele, talpile, cablul VOLCANIC_BLACK 20.
     8. Ce iese din contur: nimic; inaltimea totala ~3,0 m.
    """
    body, glow = Builder(), Builder()
    hub = Vector((0.0, 0.0, 1.40))
    feet = []
    for deg in (30.0, 150.0, 270.0):
        a = math.radians(deg)
        f = Vector((0.85 * math.cos(a), 0.85 * math.sin(a), 0.035))
        feet.append(f)
        body.beam(hub, f, 0.07, CRR_PAINT)
        body.box((f.x, f.y, 0.03), (0.13, 0.13, 0.06), CRR_BLACK)
        mid = hub.lerp(f, 0.55)
        body.beam(Vector((0, 0, 0.80)), mid, 0.035, CRR_PAINT)
    body.cylinder((0.0, 0.0, 1.65), 0.045, 1.80, CRR_PAINT, segments=8)       # catarg 0,75..2,55
    body.cylinder((0.0, 0.0, 1.40), 0.08, 0.16, CRR_BLACK, segments=8)        # manson
    body.beam((-0.58, 0.0, 2.55), (0.58, 0.0, 2.55), 0.055, CRR_PAINT)         # T
    body.cylinder((0.0, 0.0, 2.58), 0.05, 0.08, CRR_BLACK, segments=8)
    for sx in (-1, 1):
        x = sx * 0.31
        body.box((x, 0.0, 2.77), (0.46, 0.18, 0.36), CRR_BLACK)                # carcasa
        body.box((x, -0.11, 2.77), (0.34, 0.05, 0.24), CRR_BLACK)              # radiator spate
        for dx in (-0.255, 0.255):
            body.beam((x + dx, 0.0, 2.55), (x + dx, 0.0, 2.80), 0.03, CRR_PAINT)  # furca
        body.beam((x - 0.10, 0.0, 2.96), (x + 0.10, 0.0, 2.96), 0.03, CRR_BLACK)  # maner
        body.beam((x - 0.10, 0.0, 2.93), (x - 0.10, 0.0, 2.97), 0.03, CRR_BLACK)
        body.beam((x + 0.10, 0.0, 2.93), (x + 0.10, 0.0, 2.97), 0.03, CRR_BLACK)
        glow.box((x, 0.095, 2.77), (0.38, 0.02, 0.28), SAND_LIGHT)            # sticla
    # cablul
    body.beam((0.05, -0.05, 2.45), (0.05, -0.05, 1.15), 0.022, CRR_BLACK)
    body.beam((0.05, -0.05, 1.15), (0.25, -0.55, 0.02), 0.022, CRR_BLACK)
    body.beam((0.25, -0.55, 0.02), (0.55, -1.05, 0.02), 0.022, CRR_BLACK)
    return [body.to_object("Lamp_Body"), glow.to_object("Lamp_Glow")]


# ---------------------------------------------------------------------------
# cable_reel
# ---------------------------------------------------------------------------

def build_cable_reel():
    """LISTA DE ELEMENTE (decuparea `cable_reel.png`):

     1. Doua flanse de lemn (discuri O 1,6 m, 16 laturi), axa pe X, la 1 m
        distanta (fete exterioare la x = +-0,5).
     2. Pe fata exterioara a fiecarei flanse: 6 spite in relief (3 cm,
        LOG_DARK 28, lemnul umbrit) de la butuc la margine.
     3. Butucul de rugina (O 0,26 m) care iese 6 cm prin ambele flanse.
     4. Tamburul cu cablul NEGRU infasurat (O 1,2 m, VOLCANIC_BLACK) cu 6
        spire in relief (inele de 7 cm) -- infasurarea se citeste ca dungi.
     5. Leaganul de lemn pe sol: 2 talpi pe Y sub flanse, 2 traverse pe X si
        4 pene care tin tamburul.
     6. Culori: lemn WOOD_WEATHERED 9, umbrit LOG_DARK 28, cablu 20, butuc 10.
        Ce iese din contur: nimic; inaltimea totala ~1,7 m (cu leaganul).
    """
    b = Builder()
    zc = 0.10 + 0.80
    for sx in (-1, 1):
        b.cylinder((sx * 0.465, 0.0, zc), 0.80, 0.07, WOOD, segments=16, axis="X")
        for k in range(6):
            a = 2 * math.pi * (k + 0.25) / 6
            rot = Matrix.Rotation(a, 3, "X")
            c = Vector((sx * 0.515, 0.45 * math.cos(a), zc + 0.45 * math.sin(a)))
            b.box(c, (0.03, 0.62, 0.07), LOG_DARK, rotation=rot)
        b.box((sx * 0.42, 0.0, 0.05), (0.16, 1.25, 0.10), WOOD)               # talpi
        for sy in (-1, 1):
            b.box((sx * 0.42, sy * 0.33, 0.17), (0.16, 0.20, 0.14), LOG_DARK)  # pene
    for sy in (-1, 1):
        b.box((0.0, sy * 0.52, 0.04), (1.10, 0.14, 0.08), LOG_DARK)           # traverse
    b.cylinder((0.0, 0.0, zc), 0.13, 1.12, CRR_RUST, segments=10, axis="X")    # butuc
    b.cylinder((0.0, 0.0, zc), 0.60, 0.86, CRR_BLACK, segments=16, axis="X")   # cablul
    for k in range(6):
        x = -0.36 + k * 0.144
        b.cylinder((x, 0.0, zc), 0.625, 0.07, CRR_BLACK, segments=16, axis="X")
    return [b.to_object("Reel_Body")]


# ---------------------------------------------------------------------------
# water_tank
# ---------------------------------------------------------------------------

def build_water_tank():
    """LISTA DE ELEMENTE (decuparea `water_tank.png`; corectura: PAINTED_METAL,
    nu albastrul saturat al planșei):

     1. Corpul: cilindru vertical O 2,0 m (14 laturi), fund conic spre o gura
        de golire, capac conic sus cu gura de vizitare (gat + capac). Runda 2:
        cilindrul coboara la 0,85 m (pe decupare corpul ocupa ~3/4 din
        inaltime, picioarele sunt scurte).
     2. 2 cercuri de intarire in relief pe cilindru (ca dungile de pe decupare)
        + cusatura de la umarul conului.
     3. 4 picioare de RUGINA (decuparea: maro), aproape verticale, lipite de
        peretele cilindrului, cu talpi; 4 contravantuiri orizontale jos.
     4. Teava de golire neagra din varful conului de jos, cu vana.
     5. Culori: corp + cercuri PAINTED_METAL 11 (#7692A8, gri-albastrui),
        picioare RUST_METAL 10, teava VOLCANIC_BLACK 20.
     6. Inaltimea totala 3,0 m; fara scara (decuparea nu are).
    """
    b = Builder()
    prof = [(0.22, 0.55), (1.0, 0.85), (1.0, 2.62), (0.34, 2.86), (0.26, 2.86),
            (0.26, 2.95), (0.32, 2.95), (0.32, 3.0), (0.0, 3.0)]
    b.revolve(prof, PAINTED, segments=14)
    # cercurile: revolve cu ACEEASI faza ca peretele (un cilindru din create_cone
    # are alta faza si iese in zigzag peste muchiile corpului -- runda 1)
    for z, dz, dr in ((1.45, 0.03, 0.03), (2.05, 0.03, 0.03), (2.62, 0.02, 0.02)):
        b.revolve([(1.0, z - dz), (1.0 + dr, z - dz), (1.0 + dr, z + dz), (1.0, z + dz)],
                  PAINTED, segments=14, cap_bottom=False)
    legs = []
    for k in range(4):
        a = math.radians(45 + 90 * k)
        top = Vector((0.97 * math.cos(a), 0.97 * math.sin(a), 1.00))
        bot = Vector((1.00 * math.cos(a), 1.00 * math.sin(a), 0.0))
        legs.append((top, bot))
        b.beam(top, bot, 0.09, CRR_RUST)
        b.box((bot.x, bot.y, 0.02), (0.22, 0.22, 0.04), CRR_RUST)
    for k in range(4):
        p = legs[k][0].lerp(legs[k][1], 0.72)
        q = legs[(k + 1) % 4][0].lerp(legs[(k + 1) % 4][1], 0.72)
        b.beam(p, q, 0.05, CRR_RUST)
    b.cylinder((0.0, 0.0, 0.42), 0.06, 0.30, CRR_BLACK, segments=8)
    b.cylinder((0.0, 0.0, 0.34), 0.10, 0.06, CRR_BLACK, segments=8)
    return [b.to_object("WaterTank_Body")]


# ---------------------------------------------------------------------------
# fuel_tank
# ---------------------------------------------------------------------------

def build_fuel_tank():
    """LISTA DE ELEMENTE (decuparea `fuel_tank.png`):

     1. Corpul: cilindru ORIZONTAL pe Y (O 1,8 m, 3,6 m, 14 laturi), cu
        capete bombate (trunchi de con scurt) -> ~3,9 m.
     2. 2 cercuri de intarire in relief (y +-0,9).
     3. 2 sei de sustinere (talpa + inima) la y +-1,15.
     4. Gura de umplere sus (gat larg + buza, gura neagra), varful la ~2,4 m.
     5. Scara pe flancul -X (cel din 3/4, ca pe decupare), langa capatul +Y,
        de la sol la creasta.
        (Pe decupare: o scara pe capat si o balustrada curba deasupra; aici o
        singura scara si fara balustrada, ca inaltimea sa ramana 2,4 m din
        tabel -- abatere declarata.)
     6. Culori: tot RUST_METAL 10 (ruginit, cerut), pete de praf SAND_SHADOW 2
        -- scoase in runda 2: pe tambur se citeau ca scanduri --, gura
        VOLCANIC_BLACK 20.
    """
    b = Builder()
    zc = 1.35
    b.cylinder((0.0, 0.0, zc), 0.90, 3.60, CRR_RUST, segments=14, axis="Y")
    b.frustum((0.0, 1.87, zc), 0.90, 0.70, 0.14, CRR_RUST, segments=14, axis="Y")
    b.frustum((0.0, -1.87, zc), 0.70, 0.90, 0.14, CRR_RUST, segments=14, axis="Y")
    for y in (-0.9, 0.9):
        b.cylinder((0.0, y, zc), 0.925, 0.07, CRR_RUST, segments=14, axis="Y")
    for y in (-1.15, 1.15):
        b.box((0.0, y, 0.06), (1.60, 0.40, 0.12), CRR_RUST)
        b.box((0.0, y, 0.33), (1.20, 0.26, 0.44), CRR_RUST)
    b.cylinder((0.0, -0.9, 2.30), 0.30, 0.18, CRR_RUST, segments=12)          # gat
    b.cylinder((0.0, -0.9, 2.40), 0.33, 0.04, CRR_RUST, segments=12)          # buza
    b.cylinder((0.0, -0.9, 2.40), 0.22, 0.045, CRR_BLACK, segments=12)        # gura
    # scara pe flancul -X (cel vazut din 3/4, ca pe decupare), sprijinita pe tambur
    b.ladder((-1.08, 1.10, 0.03), (-0.50, 1.10, 2.18), 0.46, 0.30, 0.05, 0.035, CRR_RUST,
             side=(0.0, 1.0, 0.0))
    return [b.to_object("FuelTank_Body")]


# ---------------------------------------------------------------------------
# office_container
# ---------------------------------------------------------------------------

def build_office_container():
    """LISTA DE ELEMENTE (decuparea `office_container.png`):

     1. Cutia de 6,0 (X) x 2,5 (Y) x 2,6 (Z) m: pereti CONCRETE 8 cu nervuri
        verticale in relief (pas 0,45 m, 4 cm), rama ASPHALT_EDGE 6: 4 stalpi
        de colt, grinzi sus si jos pe tot conturul, acoperis plat cu buza.
     2. Fata bogata pe +Y (lunga): 2 ferestre (1,1 x 0,9 m, rama + geam
        VOLCANIC_BLACK + un montant), o usa (0,9 x 2,0 m) intre ele, spre
        dreapta, cu rama inchisa si maner -- ordinea de pe decupare:
        perete gol, fereastra, usa, fereastra.
     3. Capatul -X: o fereastra mica (0,7 x 0,7 m).
     4. Treptele metalice in fata usii: o treapta + 2 vange, VOLCANIC_BLACK.
     5. Doua traverse de lemn sub container (WOOD_WEATHERED 9), cum sta pe
        santier.
     6. Fara text / marcaje. Originea pe centrul amprentei cutiei (treptele
        ies ~0,35 m pe +Y si nu muta originea).
    """
    b = Builder()
    X, Y = 6.0, 2.5
    z_sl, z_fr0 = 0.15, 0.15          # traverse 0..0.15, rama de jos de la 0.15
    z_w0, z_w1 = 0.28, 2.47          # peretii
    z_top = 2.60
    hx, hy = X * 0.5, Y * 0.5
    t = 0.16
    for sx in (-1, 1):
        b.box((sx * 2.2, 0.0, z_sl * 0.5), (0.22, Y + 0.1, z_sl), WOOD)       # traverse
    b.box((0.0, 0.0, (z_w0 + z_w1) * 0.5), (X - 0.2, Y - 0.2, z_w1 - z_w0), CONCRETE)
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((sx * (hx - t / 2), sy * (hy - t / 2), (z_fr0 + z_top) * 0.5),
                  (t, t, z_top - z_fr0), ASPHALT_EDGE)
    for zc, zh in (((z_fr0 + z_w0) * 0.5, z_w0 - z_fr0), ((z_w1 + z_top) * 0.5, z_top - z_w1)):
        for sy in (-1, 1):
            b.box((0.0, sy * (hy - t / 2), zc), (X, t, zh), ASPHALT_EDGE)
        for sx in (-1, 1):
            b.box((sx * (hx - t / 2), 0.0, zc), (t, Y, zh), ASPHALT_EDGE)
    b.box((0.0, 0.0, z_top - 0.05), (X - 0.2, Y - 0.2, 0.06), CONCRETE)       # acoperis
    yf = hy - 0.10                    # fata peretelui +Y
    # golurile de pe +Y (x0, x1)
    win_x = (-0.6, 2.15)
    door_x = 1.0
    holes = [(x - 0.62, x + 0.62) for x in win_x] + [(door_x - 0.52, door_x + 0.52)]
    zr = (z_w0 + z_w1) * 0.5
    hr = z_w1 - z_w0 - 0.04
    x = -hx + t + 0.30
    while x < hx - t - 0.1:
        for sy in (-1, 1):
            if sy > 0 and any(a <= x <= bb for a, bb in holes):
                continue
            b.box((x, sy * (yf + 0.02), zr), (0.12, 0.04, hr), CONCRETE)
        x += 0.45
    y = -hy + t + 0.30
    while y < hy - t - 0.1:
        for sx in (-1, 1):
            if sx < 0 and abs(y) < 0.45:
                y_skip = True
            else:
                y_skip = False
            if not y_skip:
                b.box((sx * (hx - 0.08), y, zr), (0.04, 0.12, hr), CONCRETE)
        y += 0.45
    for wx in win_x:
        b.window((wx, yf + 0.03, 1.55), 1.10, 0.90, 0.07, 0.08, CRR_BLACK, ASPHALT_EDGE,
                 mullions=(1, 0))
    # usa
    b.box((door_x, yf + 0.02, z_w0 + 1.0), (0.86, 0.04, 2.0), CONCRETE)
    for dx in (-0.47, 0.47):
        b.box((door_x + dx, yf + 0.04, z_w0 + 1.02), (0.08, 0.08, 2.04), ASPHALT_EDGE)
    b.box((door_x, yf + 0.04, z_w0 + 2.04), (1.02, 0.08, 0.08), ASPHALT_EDGE)
    b.box((door_x + 0.30, yf + 0.07, z_w0 + 1.0), (0.12, 0.05, 0.04), CRR_BLACK)
    # fereastra de pe capatul -X
    b.window((-(hx - 0.075), 0.0, 1.6), 0.70, 0.70, 0.07, 0.06, CRR_BLACK, ASPHALT_EDGE,
             rotation=Matrix.Rotation(math.radians(90), 3, "Z"))
    # treptele
    for dx in (-0.48, 0.48):
        b.beam((door_x + dx, hy + 0.0, z_w0 - 0.02), (door_x + dx, hy + 0.36, 0.03), 0.05, CRR_BLACK)
    b.box((door_x, hy + 0.20, 0.15), (0.96, 0.30, 0.04), CRR_BLACK)
    return [b.to_object("Office_Body")]


# ---------------------------------------------------------------------------
# quarry_sign_a / _b
# ---------------------------------------------------------------------------

SIGN_W, SIGN_H, SIGN_Z0 = 1.2, 0.8, 1.0
SIGN_T = 0.04


def _sign_frame(b):
    """Panoul (camp DRY_VEGETATION 13, rama neagra) pe doi stalpi de rugina de
    1,8 m. Intoarce cota fetei din fata (+Y) a campului."""
    zc = SIGN_Z0 + SIGN_H * 0.5
    b.box((0.0, 0.0, zc), (SIGN_W, SIGN_T, SIGN_H), CRR_PAINT)
    yb = SIGN_T * 0.5 + 0.005                  # rama: 1 cm in relief
    bw = 0.035
    b.box((0.0, yb, SIGN_Z0 + SIGN_H - bw * 0.5), (SIGN_W, 0.01, bw), CRR_BLACK)
    b.box((0.0, yb, SIGN_Z0 + bw * 0.5), (SIGN_W, 0.01, bw), CRR_BLACK)
    for sx in (-1, 1):
        b.box((sx * (SIGN_W - bw) * 0.5, yb, zc), (bw, 0.01, SIGN_H), CRR_BLACK)
    for sx in (-1, 1):
        b.cylinder((sx * 0.40, -(SIGN_T * 0.5 + 0.04), 0.90), 0.04, 1.80, CRR_RUST, segments=8)
        b.box((sx * 0.40, -(SIGN_T * 0.5 + 0.04), 0.03), (0.16, 0.16, 0.06), CRR_BLACK)
        for z in (SIGN_Z0 + 0.15, SIGN_Z0 + SIGN_H - 0.15):
            b.box((sx * 0.40, -(SIGN_T * 0.5 + 0.015), z), (0.10, 0.03, 0.06), CRR_RUST)
    return SIGN_T * 0.5


def _relief_quad(b, quad_xz, y0, depth, slot):
    """Placa convexa (contur XZ) in relief pe fata +Y, intre y0 + 2 mm si
    y0 + 2 mm + depth. Cei 2 mm NU sunt estetici: `assign_uvs` cauta slotul
    fetei dupa CEA MAI APROPIATA fata originala de centrul ei, deci o fata din
    spate a reliefului coplanara cu campul ii fura campului culoarea (runda 1:
    panoul `_b` iesise negru, cubul galben)."""
    outline = list(quad_xz)
    yc = y0 + 0.002 + depth * 0.5
    b.prism(outline, depth, slot, center=(0.0, yc, 0.0))


def build_quarry_sign_a():
    """LISTA DE ELEMENTE (decuparea `quarry_sign_a.png`):

     1. Panou dreptunghiular 1,2 x 0,8 m (landscape), camp DRY_VEGETATION 13
        (galben-spalacit, NU CAR_YELLOW 16 al planșei), rama neagra subtire.
     2. 3 chevroni negri spre DREAPTA privitorului (-X: privit din fata +Y,
        dreapta e -X; runda 1 ii avea invers), in relief 1,5 cm, fiecare din doua
        brate (paralelograme). Tabelul spune „chevron dublu”; decuparea are 3
        -- planșa e sursa formei, abaterea se noteaza.
     3. 2 stalpi de rugina (O 8 cm) de 1,8 m, in spatele panoului, cu talpi
        negre si 2 bride pe fiecare stalp.
     4. Fara text, cifre, logo-uri. Fata desenata pe +Y.
    """
    b = Builder()
    yf = _sign_frame(b)
    zt, zm, zb = SIGN_Z0 + SIGN_H - 0.09, SIGN_Z0 + SIGN_H * 0.5, SIGN_Z0 + 0.09
    # varful chevronului spre -X: privit din fata (+Y), -X e DREAPTA privitorului
    w, d = -0.15, -0.20
    for x0 in (0.46, 0.14, -0.18):
        _relief_quad(b, [(x0, zt), (x0 + d, zm), (x0 + d + w, zm), (x0 + w, zt)], yf, 0.015, CRR_BLACK)
        _relief_quad(b, [(x0 + d, zm), (x0, zb), (x0 + w, zb), (x0 + d + w, zm)], yf, 0.015, CRR_BLACK)
    return [b.to_object("Sign_Body")]


def build_quarry_sign_b():
    """LISTA DE ELEMENTE (decuparea `quarry_sign_b.png`):

     1. Acelasi panou si aceiasi stalpi ca `_a` (1,2 x 0,8 m pe tabel; pe
        decupare panoul e aproape patrat -- cotele din tabel castiga).
     2. Pictograma BLOCULUI SUSPENDAT, neagra, in relief 1,5 cm:
        - carligul sus (o bara verticala scurta + un inel patrat);
        - 2 cabluri in V de la carlig la colturile de sus ale blocului;
        - blocul desenat in 3/4: un hexagon negru plin;
        - muchiile vizibile ale cubului (Y-ul din mijloc) ca linii de culoarea
          campului, 0,5 cm peste negru -> blocul se citeste cub, ca pe decupare.
     3. Fara text. Fata desenata pe +Y.
    """
    b = Builder()
    yf = _sign_frame(b)
    dep = 0.015
    # carlig: bara + inel
    _relief_quad(b, [(-0.015, 1.735), (-0.015, 1.665), (0.015, 1.665), (0.015, 1.735)], yf, dep, CRR_BLACK)
    for (x0, z0, x1, z1) in ((-0.05, 1.60, 0.05, 1.62), (-0.05, 1.66, 0.05, 1.68),
                             (-0.05, 1.60, -0.03, 1.68), (0.03, 1.60, 0.05, 1.68)):
        _relief_quad(b, [(x0, z1), (x0, z0), (x1, z0), (x1, z1)], yf, dep, CRR_BLACK)
    # blocul in 3/4: hexagon plin (capac romb + doua fete)
    cx, top = 0.0, 1.38
    hw, ht, hs = 0.22, 0.075, 0.20           # semilatime, jumatatea capacului, inaltimea fetei
    hexa = [(cx, top + ht), (cx - hw, top), (cx - hw, top - hs), (cx, top - ht - hs),
            (cx + hw, top - hs), (cx + hw, top)]
    _relief_quad(b, hexa, yf, dep, CRR_BLACK)
    # cablurile in V, de la carlig la colturile de sus ale blocului
    for sx in (-1, 1):
        p0 = Vector((0.0, 1.60))
        p1 = Vector((sx * hw * 0.92, top + 0.01))
        dv = (p1 - p0).normalized()
        n = Vector((-dv.y, dv.x)) * 0.012
        _relief_quad(b, [(v.x, v.y) for v in (p0 + n, p0 - n, p1 - n, p1 + n)], yf, dep, CRR_BLACK)
    # muchiile vizibile ale cubului (Y-ul), pe culoarea campului, 0,5 cm peste negru
    yl = yf + 0.002 + dep
    lw = 0.014
    c_front = Vector((cx, top - ht))
    lines = [(Vector((cx - hw + 0.01, top)), c_front), (c_front, Vector((cx + hw - 0.01, top))),
             (c_front, Vector((cx, top - ht - hs + 0.01)))]
    for p0, p1 in lines:
        dv = (p1 - p0).normalized()
        n = Vector((-dv.y, dv.x)) * lw * 0.5
        _relief_quad(b, [(v.x, v.y) for v in (p0 + n, p0 - n, p1 - n, p1 + n)], yl, 0.005, CRR_PAINT)
    return [b.to_object("Sign_Body")]


# ---------------------------------------------------------------------------
# pipe_run
# ---------------------------------------------------------------------------

def build_pipe_run():
    """LISTA DE ELEMENTE (decuparea `pipe_run.png`; modul 6 m pe Y; runda 2: pe
    decupare conductele sunt UNA PESTE ALTA, nu alaturate cum le pusese runda 1):

     1. 2 conducte O 0,4 m (12 laturi), suprapuse vertical (axe la z 0,80 si
        1,25, rost de 5 cm), pe toata lungimea modulului, de la y -3 la +3
        (capetele se lipesc la inlantuire).
     2. 2 flanse (O 0,54 m, 5 cm) la fiecare capat al fiecarei conducte, in
        modul: la inlantuire se intalnesc doua flanse = imbinarea.
     3. 3 suporti de marmura (0,8 x 0,6 x 0,6 m) la y -2, 0, +2 -> pas de 2 m
        pastrat si intre module.
     4. Pe fiecare suport: o colier de rugina pe fiecare conducta (inel de
        8 cm) si doua chingi verticale, una pe fiecare parte, de la bloc pana
        peste conducta de sus -- ca pe decupare.
     5. Noduri: `Pipe_Metal` (conducte PAINTED_METAL 11 + coliere RUST_METAL
        10, pe atlas) si `Pipe_Marble` (suportii, CORAL_SAND 19, clasa la
        integrare). Suportii au 0,6 m: fara nod `*_MarbleBase` (tabelul cere
        doar cele doua noduri).
    """
    metal, marble = Builder(), Builder()
    L = 6.0
    r = 0.20
    for zc in (0.80, 1.25):
        metal.cylinder((0.0, 0.0, zc), r, L, PAINTED, segments=12, axis="Y")
        for sy in (-1, 1):
            metal.cylinder((0.0, sy * (L * 0.5 - 0.025), zc), 0.27, 0.05, PAINTED, segments=12, axis="Y")
        for y in (-2.0, 0.0, 2.0):
            metal.cylinder((0.0, y, zc), 0.225, 0.08, CRR_RUST, segments=12, axis="Y")
    for y in (-2.0, 0.0, 2.0):
        for dx in (-0.235, 0.235):
            metal.box((dx, y, 0.94), (0.05, 0.08, 0.68), CRR_RUST)
        metal.box((0.0, y, 1.47), (0.52, 0.08, 0.05), CRR_RUST)
        open_box(marble, (0.0, y, 0.30), (0.80, 0.60, 0.60), CRR_MARBLE)
    return [metal.to_object("Pipe_Metal"), marble.to_object("Pipe_Marble")]


# ---------------------------------------------------------------------------

clear_built()
if _want("marble_block_a"):
    emit_kit(build_marble_block((1.5, 1.5, 1.5)), "rocks/marble_block_a.glb", AO_BLOCK,
             bevels=BLOCK_BEVELS)
    clear_built()
if _want("marble_block_b"):
    emit_kit(build_marble_block((2.0, 2.0, 2.0), paint=True), "rocks/marble_block_b.glb",
             AO_BLOCK, bevels=BLOCK_BEVELS, place=(0.0, 0.0, 0.0))
    clear_built()
if _want("marble_block_c"):
    emit_kit(build_marble_block((3.0, 2.0, 2.0)), "rocks/marble_block_c.glb", AO_BLOCK,
             bevels=BLOCK_BEVELS)
    clear_built()
if _want("block_stack_a"):
    emit_kit(build_block_stack([((2.0, 1.8, 1.5), (0.0, 0.0), 0.0),
                                ((1.95, 1.75, 1.45), (0.18, -0.12), 4.0)]),
             "rocks/block_stack_a.glb", AO_BLOCK, bevels=BLOCK_BEVELS)
    clear_built()
if _want("block_stack_b"):
    emit_kit(build_block_stack([((2.3, 2.1, 1.3), (0.0, 0.0), 0.0),
                                ((2.0, 1.85, 1.2), (-0.12, 0.10), -3.0),
                                ((1.85, 1.7, 1.1), (0.06, -0.14), 4.5)]),
             "rocks/block_stack_b.glb", AO_BLOCK, bevels=BLOCK_BEVELS)
    clear_built()
if _want("block_informe_b"):
    emit_kit(build_block_informe_b(), "rocks/block_informe_b.glb", AO_ROCK,
             smooth_angle=None)
    clear_built()
if _want("rubble_pile_a"):
    emit_kit(build_rubble_pile(41, 2.0, 1.5, (2, 6, 9, 8)), "rocks/rubble_pile_a.glb",
             AO_ROCK, smooth_angle=None)
    clear_built()
if _want("rubble_pile_b"):
    emit_kit(build_rubble_pile(57, 1.5, 1.2, (2, 5, 8, 7)), "rocks/rubble_pile_b.glb",
             AO_ROCK, smooth_angle=None)
    clear_built()
if _want("safety_berm"):
    emit_kit(build_safety_berm(), "structures/safety_berm.glb", AO_ROCK, smooth_angle=None)
    clear_built()
if _want("work_lamp"):
    emit_kit(build_work_lamp(), "props/work_lamp.glb", AO_PROP, bevel=0.01,
             bevels={"_Glow": 0.0})
    clear_built()
if _want("cable_reel"):
    emit_kit(build_cable_reel(), "props/cable_reel.glb", AO_PROP, bevel=0.012)
    clear_built()
if _want("water_tank"):
    emit_kit(build_water_tank(), "props/water_tank.glb", AO_PROP, bevel=0.015)
    clear_built()
if _want("fuel_tank"):
    emit_kit(build_fuel_tank(), "props/fuel_tank.glb", AO_PROP, bevel=0.015,
             place=(0.0, 0.0, 0.0))
    clear_built()
if _want("office_container"):
    emit_kit(build_office_container(), "buildings/office_container.glb", AO_PROP,
             bevel=0.015, place=(0.0, 0.0, 0.0))
    clear_built()
if _want("quarry_sign_a"):
    emit_kit(build_quarry_sign_a(), "props/quarry_sign_a.glb", AO_PROP, bevel=0.0,
             place=None)
    clear_built()
if _want("quarry_sign_b"):
    emit_kit(build_quarry_sign_b(), "props/quarry_sign_b.glb", AO_PROP, bevel=0.0)
    clear_built()
if _want("pipe_run"):
    emit_kit(build_pipe_run(), "props/pipe_run.glb", AO_PROP, bevel=0.0)
    clear_built()
report_crr()
