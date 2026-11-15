"""San Francisco (Track25), valul 2: mobilierul de STRADA.

Contract: docs/asset_briefs/sanfrancisco_inventory.md §5.3 (randurile M1-M4, M6-M8; M5 si M9
nu se fac in valul asta), §4 (ce vede camera de joc), §1.7 (masinile parcate ca `BumpProp`).
Regulile comune (atlas pe centre de slot, AO copt, scara metrica, origine la baza, fara
text/sigle, nimic mai subtire de 0,08 m, fara sloturile 14-16 si 30) sunt cele din
docs/asset_briefs/sf_cable_car.md §5-§9. Referinte de caracter si culoare:
docs/track_briefs/img/sf_assets_v1/sf_<piesa>.png. Unde decuparea si inventarul nu se
potrivesc pe cote sau structura, castiga inventarul.

  SignalMast                    props/sf_signal_mast.glb     (M2, un nod)
  ParkedSedan / Wagon / Van     vehicles/sf_parked_*.glb     (M1, un nod fiecare)
  StreetLamp                    props/sf_street_lamp.glb     (M3, un nod)
  Hydrant, Mailbox, NewsBox, TrashBin, Cone
                                props/sf_street_props.glb    (M4, cinci noduri-radacina)
  Bollard                       props/sf_bollard.glb         (M7, un nod)
  TrapStack, Crate, RopeCoil    props/sf_crab_traps.glb      (M8, trei noduri-radacina)
  Bench / BikeRack              props/sf_bench.glb, sf_bike_rack.glb (M6)

Axe (Blender): X = latimea, Y = lungimea (+Y Blender = -Z Godot = FATA), Z = sus.
Variantele dintr-un fisier stau toate in origine (se suprapun): jocul arata cate una.

LISTA DE ELEMENTE -- acceptarea se face element cu element, pe randare langa decupare.

M2 -- stalpul de semafor (`SignalMast`), originea la baza stalpului, bratul spre -X:
  S1. Soclu tronconic intunecat (slot 20), 0..0,55 m, cu un inel de 0,1 m deasupra.
  S2. Stalpul (slot 11), ⌀ 0,35 la baza, usor conic, pana la +10,2.
  S3. Varf: capac + bila (slot 20) pana la +10,5 (decuparea: bila de pe stalp).
  S4. Bratul GROS, drept, de 8,0 m spre -X (0,22 x 0,22 m, slot 11), cu fundul la +9,24,
      plus capac la capat. Decuparea are un brat subtire curbat: respins de brief.
  S5. Tirantul de deasupra (contrafisa din decupare): bara de 0,12 m de la +10,05 pe stalp
      pana la x -5,0 pe brat, cu doi montanti verticali intre el si brat.
  S6. Contrafisa scurta de sub brat, langa stalp (in raza de 1,0 m a axei).
  S7. Colierul bratului pe stalp.
  S8. Capul semaforului atarnat sub brat la x -7,2: carcasa intunecata (slot 20), placa de
      fundal cu chenar alb (22, se citeste de departe), trei lentile pe FIECARE fata
      (rosu aprins sus = slot 7; celelalte doua stinse, slot 6) cu viziere; tija scurta pana
      la brat. Tot capul intre +8,0 si +9,2.
  S9. Nimic sub +8,0 dincolo de 1,0 m de axa stalpului (doar stalpul coboara).

M1 -- masinile parcate (ParkedSedan, ParkedWagon, ParkedVan); gabarit EXACT 1,90 x 3,70 in
plan, Y de la 0, inaltimea placeholderului (sedan 1,33, break 1,38, duba 1,61); botul pe +Y
Blender (-Z Godot). Vopseaua TOATA pe slotul 11 si nimic altceva pe 11 (jocul o recoloreaza).
  C1. Caroseria de jos: profil lateral extrudat (capota, aripi, portbagaj), cu decupaje de
      arc de roata; bevel 0,05.
  C2. Arcurile de roata: buza in relief (slot 11) la 0,90..0,95 si fundul nisei intunecat
      (slot 20), ca roata sa stea intr-o nisa, nu in tunel.
  C3. Patru roti ⌀ 0,70 (slot 20) cu capace (slot 8), atingand y = 0.
  C4. Habitaclul de sticla (slot 20) cu tumblehome (se ingusteaza spre acoperis).
  C5. Acoperisul (slot 11) si stalpii A, B, C (+ D la break) peste sticla: geamurile laterale
      se citesc ca ferestre separate.
  C6. Bare de protectie fata/spate (slot 8), cu intoarceri pe colturi.
  C7. Faruri rotunde (slot 22), grila (slot 20), stopuri (slot 7) pe spate.
  C8. Oglinzi laterale (slot 11) pana la marginea de 0,95.
  C9. Silueta per tip: sedan = trei volume (capota, cabina, portbagaj); break = acoperis lung
      pana in spate + portbagaj de acoperis (slot 28: doua lonjeroane si trei bare, 0,08 m);
      duba = un singur volum inalt, nas scurt, geamuri doar la cabina si pe usile din spate,
      banda de protectie laterala (slot 8).

M3 -- felinarul (`StreetLamp`), 5,5 m:
  L1. Baza tronconica cu inel (slot 11), 0..0,72.
  L2. Stalpul ⌀ 0,25, conic, pana la +4,6.
  L3. Colier sub felinar.
  L4. Felinarul (mare, ca in decupare): palnie de jos, geam alb pe patru laturi (slot 22),
      0,52 m, evazat in sus.
  L5. Capacul in patru ape cu streasina + bila in varf.

M4 -- mobilierul mic (cinci noduri, fiecare centrat pe originea lui, la baza):
  P1. Hydrant 0,8 m (slot 7): talpa, corp, flansa, dom, piulita de sus, doua stuturi laterale
      si stutul mare din fata.
  P2. Mailbox 1,3 m (slot 11, fara sigla): corp cu varf rotund, patru picioare (slot 20),
      clapeta de sus (slot 20). (Bara de jos din prima varianta a iesit: plafonul de 300.)
  P3. NewsBox 1,1 m: doua automate alaturate, galben (slot 0) si gri-albastru (slot 11), cu
      fereastra alba (slot 22), usa de jos si talpa (slot 20), caseta de monede sus.
  P4. TrashBin 1,0 m: cos tronconic gri (slot 6) cu opt nervuri si buza mai deschise
      (slot 29: santurile dintre nervuri raman mai inchise), capac intunecat (slot 20).
  P5. Cone 0,7 m: talpa patrata si con (slot 7) cu doua benzi albe (slot 22).

M7 -- `Bollard`, in cutia stalpului de joc 0,5 x 0,8 x 0,5:
  B1. Talpa patrata ruginita (slot 10). B2. Corp de revolutie (slot 20) cu gat si cap evazat.

M8 -- capcane de crabi si lazi (TrapStack, Crate, RopeCoil), fiecare <= 1,2 m:
  T1. TrapStack: doua capcane suprapuse (a doua rotita 12 grade): miez de plasa (slot 11),
      rama ruginie (slot 10) de 0,08 m: rama de sus, stalpii de colt, cate o bara verticala pe
      mijlocul laturilor lungi.
  T2. Crate: lada DESCHISA de scanduri noi (slot 1), sipci orizontale, rama de sus si
      cornierele in lemn inchis (slot 9).
  T3. RopeCoil: trei spire libere de franghie (slot 13, canepa), inclinate si decalate.

M6 -- banca si rastelul:
  N1. Bench: doua capete de fonta (slot 20) cu picior, cot si spatar, sase sipci de lemn
      (slot 9) de 0,08 m (trei sezut, trei spatar).
  N2. BikeRack: soclu de beton (slot 8) si trei arcuri in U intors (slot 29), teava ⌀ 0,09.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_street.py [-- --only=mast,cars,...]
  grupuri: mast, cars, lamp, props, bollard, traps, bench, rack
Verificare: tools/blender/measure_sf_street.py (+ --selftest) si verify_glb.py pe fiecare.
Randari de control: preview_sf_street.py.
"""

import math
import sys
import bmesh
import bpy
from mathutils import Matrix, Vector

DARK = VOLCANIC_BLACK      # 20
BODY = PAINTED             # 11 -- vopseaua masinilor (DOAR caroseria)
WHITE = FOAM_WHITE         # 22
RED = KERB_RED             # 7
BUMPER = CONCRETE          # 8
OFF_LENS = ASPHALT_EDGE    # 6
ROPE = DRY_VEGETATION      # 13 (franghia de canepa)


# ============================================================ ajutoare de geometrie
def box_mm(b, x0, x1, y0, y1, z0, z1, slot):
    return b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                 (x1 - x0, y1 - y0, z1 - z0), slot)


def prism_yz(b, outline, x0, x1, slot):
    """Prisma dintr-un contur (y, z) extrudat pe X intre x0 si x1 (profil lateral)."""
    return prism_yz_taper(b, outline, lambda z: x1, slot, x_lo=lambda z: x0)


def prism_yz_taper(b, outline, hw, slot, x_lo=None):
    """Contur (y, z) extrudat pe X intre -hw(z) si +hw(z). Cu hw LINIAR in z capacele raman
    plane (tumblehome-ul habitaclului)."""
    lo_f = x_lo or (lambda z: -hw(z))
    lo = [b.bm.verts.new((lo_f(z), y, z)) for y, z in outline]
    hi = [b.bm.verts.new((hw(z), y, z)) for y, z in outline]
    n = len(outline)
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def prism_band(b, outer, inner, x0, x1, slot):
    """Banda curba (buza arcului de roata): `outer` si `inner` = puncte (y, z) pereche,
    extrudate pe X. Capacele sunt QUAD-uri pe segment, nu un singur ngon concav: centrul
    unui ngon concav cade in afara lui, iar `assign_uvs` (fata cea mai apropiata de centru)
    i-ar da slotul vecinului (capacul rotii, la prima incercare)."""
    n = len(outer)
    lo_o = [b.bm.verts.new((x0, y, z)) for y, z in outer]
    hi_o = [b.bm.verts.new((x1, y, z)) for y, z in outer]
    lo_i = [b.bm.verts.new((x0, y, z)) for y, z in inner]
    hi_i = [b.bm.verts.new((x1, y, z)) for y, z in inner]
    for i in range(n - 1):
        b.bm.faces.new((hi_o[i], hi_o[i + 1], hi_i[i + 1], hi_i[i]))
        b.bm.faces.new((lo_i[i], lo_i[i + 1], lo_o[i + 1], lo_o[i]))
        b.bm.faces.new((lo_o[i], lo_o[i + 1], hi_o[i + 1], hi_o[i]))
        b.bm.faces.new((hi_i[i], hi_i[i + 1], lo_i[i + 1], lo_i[i]))
    for i in (0, n - 1):
        b.bm.faces.new((lo_o[i], hi_o[i], hi_i[i], lo_i[i]))
    return b._tag(lo_o + hi_o + lo_i + hi_i, slot)


def slab(b, pts, normal, t, slot, lift=0.0):
    """Placa subtire peste o suprafata: 4 puncte pe suprafata, ridicata pe normala cu
    `lift`, grosime `t` (geamurile dubei, pe planuri inclinate)."""
    n = Vector(normal).normalized()
    lo = [b.bm.verts.new(Vector(p) + n * lift) for p in pts]
    hi = [b.bm.verts.new(Vector(p) + n * (lift + t)) for p in pts]
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(4):
        j = (i + 1) % 4
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def arc_pts(cy, cz, r, a0, a1, n):
    """Puncte (y, z) pe un arc, de la unghiul a0 la a1 (grade), n+1 puncte."""
    out = []
    for k in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * k / n)
        out.append((cy + r * math.cos(a), cz + r * math.sin(a)))
    return out


def _prep(obj, bevel, bevel_angle, smooth, segments=1):
    snap = snapshot_slots(obj)
    apply_bevel(obj, bevel, segments=segments, angle_deg=bevel_angle)
    apply_smooth(obj, smooth)
    assign_uvs(obj, snap)


def _join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


def assemble(name, groups, ao, origin="base"):
    """groups = [(fn(b), bevel, bevel_angle, smooth_angle[, segments])]: fiecare grup isi
    primeste bevel-ul lui, apoi totul se uneste, originea se aseaza O DATA pe ansamblu
    (memoria finish-recentreaza-fiecare-nod-separat) si AO-ul se coace pe tot."""
    parts = []
    for k, g in enumerate(groups):
        fn, bev, ang, smooth = g[:4]
        seg = g[4] if len(g) > 4 else 1
        b = Builder()
        fn(b)
        if not b.bm.faces:
            b.bm.free()
            continue
        o = b.to_object("%s_part%d" % (name, k))
        _prep(o, bev, ang, smooth, seg)
        zs = [v.co.z for v in o.data.vertices]
        print("    %s: z %.4f..%.4f, %d tris" % (o.name, min(zs), max(zs), tri_count(o)))
        parts.append(o)
    obj = _join(parts, name)
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    if origin == "base":
        set_origin_base(obj, center_xy=True)
    elif origin == "base_axis":
        set_origin_base(obj, center_xy=False)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    rng = bake_ao(obj, **ao)
    return obj, rng


def _aabb(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    print("  %-12s %5d tris  AABB Godot X %.3f..%.3f (%.3f)  Y %.3f..%.3f (%.3f)  "
          "Z %.3f..%.3f (%.3f)"
          % (obj.name, tri_count(obj), min(xs), max(xs), max(xs) - min(xs), min(zs), max(zs),
             max(zs) - min(zs), -max(ys), -min(ys), max(ys) - min(ys)))


def _ao_override(obj, fn):
    """fn(co, val) -> val nou, pe stratul AO."""
    ca = obj.data.color_attributes["AO"]
    for i, v in enumerate(obj.data.vertices):
        val = fn(v.co, ca.data[i].color[0])
        ca.data[i].color = (val, val, val, 1.0)


# ============================================================ M2: stalpul de semafor
ARM_LEN = 8.0
ARM_T = 0.26
ARM_Z0 = 9.24            # fundul bratului
HEAD_X = -7.2
HEAD_Z0, HEAD_Z1 = 8.04, 9.16
POLE_TOP = 10.3


def mast_main(b):
    # S1 soclul (gros, ca in decupare) + inelele
    b.frustum((0, 0, 0.40), 0.34, 0.26, 0.80, DARK, segments=10)
    b.cylinder((0, 0, 0.86), 0.24, 0.12, DARK, segments=10)
    # S2 stalpul, conic: 0,175 -> 0,15
    b.frustum((0, 0, (0.80 + POLE_TOP) * 0.5), 0.175, 0.150, POLE_TOP - 0.80, BODY, segments=10)
    b.cylinder((0, 0, 3.0), 0.20, 0.12, DARK, segments=10)
    # S3 varful: inel + bila
    b.cylinder((0, 0, POLE_TOP + 0.05), 0.20, 0.10, DARK, segments=10)
    b.frustum((0, 0, POLE_TOP + 0.10 + 0.09), 0.10, 0.19, 0.18, DARK, segments=10)
    b.frustum((0, 0, POLE_TOP + 0.28 + 0.09), 0.19, 0.08, 0.18, DARK, segments=10)
    # S7 colierul bratului
    b.cylinder((0, 0, ARM_Z0 + ARM_T * 0.5), 0.21, 0.46, DARK, segments=10)
    # S4 bratul gros, drept, cu un colier la mijloc (ca in decupare) si capac la capat
    box_mm(b, -ARM_LEN, -0.10, -ARM_T * 0.5, ARM_T * 0.5, ARM_Z0, ARM_Z0 + ARM_T, BODY)
    box_mm(b, -4.15, -3.85, -0.17, 0.17, ARM_Z0 - 0.04, ARM_Z0 + ARM_T + 0.04, DARK)
    box_mm(b, -ARM_LEN - 0.04, -ARM_LEN + 0.10, -0.17, 0.17, ARM_Z0 - 0.04, ARM_Z0 + ARM_T + 0.04,
           DARK)
    # S5 tirantul de deasupra + montantii
    top = ARM_Z0 + ARM_T
    t0 = 10.10
    b.beam((-0.10, 0, t0), (-4.0, 0, top - 0.02), 0.13, BODY)
    for x in (-1.4, -2.7):
        zt = t0 + (top - 0.02 - t0) * ((-x - 0.10) / 3.9)
        b.beam((x, 0, top - 0.02), (x, 0, zt + 0.02), 0.10, BODY)
    # S6 contrafisa scurta de sub brat (in raza de 1 m)
    b.beam((-0.12, 0, 8.40), (-0.95, 0, ARM_Z0 + 0.02), 0.13, BODY)


def mast_head(b):
    x = HEAD_X
    # tija scurta pana la brat
    box_mm(b, x - 0.08, x + 0.08, -0.08, 0.08, HEAD_Z1 - 0.02, ARM_Z0 + 0.02, DARK)
    # placa de fundal: chenar alb (placa alba mai mare, subtire) + placa intunecata in fata
    box_mm(b, x - 0.50, x + 0.50, -0.05, 0.05, HEAD_Z0, HEAD_Z1, WHITE)
    box_mm(b, x - 0.41, x + 0.41, -0.08, 0.08, HEAD_Z0 + 0.09, HEAD_Z1 - 0.09, DARK)
    # carcasa
    box_mm(b, x - 0.27, x + 0.27, -0.21, 0.21, HEAD_Z0 + 0.03, HEAD_Z1 - 0.03, DARK)
    # trei lentile pe fiecare fata (+Y Blender = -Z Godot si invers) + viziere
    for sy in (-1, 1):
        for k, slot in enumerate((RED, OFF_LENS, OFF_LENS)):
            z = HEAD_Z1 - 0.03 - 0.20 - k * 0.335
            b.cylinder((x, sy * 0.225, z), 0.15, 0.04, slot, segments=12, axis="Y")
            ys = sorted((sy * 0.21, sy * 0.36))
            box_mm(b, x - 0.19, x + 0.19, ys[0], ys[1], z + 0.15, z + 0.23, DARK)


def build_mast():
    obj, rng = assemble("SignalMast", [
        (mast_main, 0.0, 40.0, 40.0),
        (mast_head, 0.0, 40.0, 40.0),
    ], dict(samples=32, dist=1.0, gradient="vertical", low=0.70, high=1.00, power=0.6,
            floor=0.35), origin="base_axis")
    return obj


# ============================================================ M1: masinile parcate
HW = 0.95                 # jumatatea latimii (1,90)
HL = 1.85                 # jumatatea lungimii (3,70)
SIDE = 0.90               # flancul caroseriei; buzele arcurilor si oglinzile ies la 0,95
SILL = 0.30
AX = 1.20                 # axele la +-1,20 (ampatament 2,40)
WR, WWID, WX = 0.35, 0.24, 0.79
WSEG = 14
WZ = WR * math.cos(math.pi / WSEG)   # 14-gonul sta pe o latura: latura de jos exact la y = 0
ARCH_R = 0.45


def lower_outline(front, rear):
    """Profilul de jos: talpa cu cele doua decupaje de arc, apoi `front` (de jos in sus,
    spre spate) si `rear` (de sus in jos)."""
    pts = [(-HL + 0.07, SILL)]
    pts += arc_pts(-AX, SILL, ARCH_R, 180, 0, 6)
    pts += arc_pts(AX, SILL, ARCH_R, 180, 0, 6)
    pts += [(HL - 0.07, SILL)] + front + rear
    return pts


def car_common(b, body_top_z):
    """Arcurile (buza + nisa), rotile, barele, farurile, stopurile."""
    for sy in (-1, 1):
        ay = sy * AX
        # C2 buza arcului, in relief la 0,90..0,95
        outer = arc_pts(ay, SILL, ARCH_R + 0.07, 180, 0, 6)
        inner = arc_pts(ay, SILL, ARCH_R, 180, 0, 6)
        for sx in (-1, 1):
            xs = sorted((sx * (SIDE - 0.01), sx * HW))
            prism_band(b, outer, inner, xs[0], xs[1], BODY)
        # fundul nisei: intunecat, intre roti (altfel arcul e un tunel prin masina)
        prism_yz(b, [(ay - ARCH_R + 0.01, SILL)] + arc_pts(ay, SILL, ARCH_R - 0.01, 180, 0, 6)[1:-1]
                 + [(ay + ARCH_R - 0.01, SILL)], -(WX - WWID * 0.5 - 0.01), WX - WWID * 0.5 - 0.01,
                 DARK)


def car_wheels(b):
    for sy in (-1, 1):
        for sx in (-1, 1):
            b.cylinder((sx * WX, sy * AX, WZ), WR, WWID, DARK, segments=WSEG, axis="X")


def car_hubs(b):
    for sy in (-1, 1):
        for sx in (-1, 1):
            b.cylinder((sx * (WX + WWID * 0.5 + 0.010), sy * AX, WZ), 0.17, 0.03, BUMPER,
                       segments=10, axis="X")
            b.cylinder((sx * (WX + WWID * 0.5 + 0.022), sy * AX, WZ), 0.07, 0.03, DARK,
                       segments=6, axis="X")


def car_bumpers(b, front_z=(0.24, 0.46), rear_z=(0.24, 0.46)):
    # C6: bara pe toata latimea + intoarcerile pe colturi
    for sy, (z0, z1) in ((1, front_z), (-1, rear_z)):
        ys = sorted((sy * (HL - 0.12), sy * HL))
        box_mm(b, -0.86, 0.86, ys[0], ys[1], z0, z1, BUMPER)
        for sx in (-1, 1):
            xs = sorted((sx * 0.70, sx * 0.93))
            ys2 = sorted((sy * (HL - 0.40), sy * (HL - 0.06)))
            box_mm(b, xs[0], xs[1], ys2[0], ys2[1], z0, z1, BUMPER)


def car_lights(b, face_y, lamp_z, tail_z, grille=(0.50, 0.70), tail_y=None):
    # C7 farurile rotunde, grila, stopurile
    for sx in (-1, 1):
        b.cylinder((sx * 0.62, face_y - 0.005, lamp_z), 0.105, 0.06, WHITE, segments=10, axis="Y")
    box_mm(b, -0.38, 0.38, face_y - 0.02, face_y + 0.03, grille[0], grille[1], DARK)
    ty = tail_y if tail_y is not None else -face_y
    for sx in (-1, 1):
        xs = sorted((sx * 0.54, sx * 0.84))
        box_mm(b, xs[0], xs[1], ty - 0.03, ty + 0.02, tail_z[0], tail_z[1], RED)


def car_mirrors(b, y, z):
    # C8: oglinda pe un picior scurt, pana la 0,95
    for sx in (-1, 1):
        xs = sorted((sx * 0.84, sx * HW))
        box_mm(b, xs[0], xs[1], y - 0.07, y + 0.07, z, z + 0.11, BODY)


def glasshouse(b, outline, hw_base, hw_top, z_base, z_top):
    k = (hw_base - hw_top) / (z_top - z_base)
    prism_yz_taper(b, outline, lambda z: hw_base - (z - z_base) * k, DARK)
    return lambda z: hw_base - (z - z_base) * k


def pillar(b, hw, p0, p1, t):
    """Stalp de caroserie pe flancul habitaclului: p0, p1 = (y, z), pe ambele parti."""
    for sx in (-1, 1):
        a = (sx * (hw(p0[1]) + 0.012), p0[0], p0[1])
        c = (sx * (hw(p1[1]) + 0.012), p1[0], p1[1])
        # cu up = +-X: latimea `t` cade in planul geamului, adancimea 0,07 pe normala lui
        b.beam(a, c, (t, 0.07), BODY, up=(sx, 0, 0))


# ---- sedanul (inaltimea placeholderului: 1,33)
def sedan_body(b):
    front = [(HL - 0.02, 0.60), (HL - 0.09, 0.78), (0.74, 0.86)]
    rear = [(-1.00, 0.86), (-HL + 0.12, 0.84), (-HL + 0.02, 0.62)]
    prism_yz(b, lower_outline(front, rear), -SIDE, SIDE, BODY)
    # acoperisul (C5)
    box_mm(b, -0.76, 0.76, -0.74, 0.36, 1.25, 1.33, BODY)


def sedan_fine(b):
    car_common(b, 0.86)
    # parbriz si luneta drepte, ca la jucarie (decuparea): habitaclu inalt si scurt
    hw = glasshouse(b, [(0.76, 0.84), (0.32, 1.27), (-0.70, 1.27), (-1.02, 0.84)],
                    0.86, 0.735, 0.84, 1.27)
    pillar(b, hw, (0.71, 0.86), (0.34, 1.26), 0.10)          # A
    pillar(b, hw, (-0.20, 0.86), (-0.22, 1.26), 0.11)        # B
    pillar(b, hw, (-0.93, 0.86), (-0.70, 1.26), 0.20)        # C (lat, de sedan)
    car_lights(b, HL - 0.03, 0.64, (0.62, 0.74))
    car_mirrors(b, 0.62, 0.88)
    car_hubs(b)


# ---- breakul (1,38, cu portbagajul de acoperis)
def wagon_body(b):
    front = [(HL - 0.02, 0.62), (HL - 0.08, 0.82), (0.78, 0.90)]
    rear = [(-HL + 0.09, 0.90), (-HL + 0.02, 0.84), (-HL + 0.01, 0.42)]
    prism_yz(b, lower_outline(front, rear), -SIDE, SIDE, BODY)
    box_mm(b, -0.77, 0.77, -1.70, 0.40, 1.22, 1.29, BODY)


def wagon_fine(b):
    car_common(b, 0.90)
    hw = glasshouse(b, [(0.80, 0.88), (0.36, 1.24), (-1.62, 1.24), (-1.72, 0.88)],
                    0.86, 0.745, 0.88, 1.24)
    pillar(b, hw, (0.76, 0.90), (0.38, 1.23), 0.10)          # A
    pillar(b, hw, (-0.30, 0.90), (-0.32, 1.23), 0.11)        # B
    pillar(b, hw, (-1.00, 0.90), (-1.00, 1.23), 0.10)        # C
    pillar(b, hw, (-1.70, 0.90), (-1.61, 1.23), 0.14)        # D
    car_lights(b, HL - 0.03, 0.66, (0.66, 0.80), grille=(0.52, 0.74))
    car_mirrors(b, 0.66, 0.92)
    car_hubs(b)
    # C9 portbagajul de acoperis (slot 28): picioare, doua lonjeroane, trei bare
    for sx in (-1, 1):
        x = sx * 0.62
        for y in (-1.50, 0.02):
            box_mm(b, x - 0.05, x + 0.05, y - 0.05, y + 0.05, 1.27, 1.31, LOG_DARK)
        box_mm(b, x - 0.04, x + 0.04, -1.58, 0.10, 1.30, 1.38, LOG_DARK)
    for y in (-1.30, -0.70, -0.10):
        box_mm(b, -0.58, 0.58, y - 0.04, y + 0.04, 1.30, 1.38, LOG_DARK)


# ---- duba (1,61: inaltimea placeholderului)
VAN_TOP = 1.61
VAN_HW0, VAN_HW1, VAN_Z0 = 0.90, 0.84, 0.93


def van_hw(z):
    return VAN_HW0 - (z - VAN_Z0) * (VAN_HW0 - VAN_HW1) / (VAN_TOP - VAN_Z0)


VAN_UPPER = [(1.46, VAN_Z0), (0.98, 1.54), (0.86, VAN_TOP), (-1.70, VAN_TOP), (-HL + 0.05, 1.53),
             (-HL + 0.03, VAN_Z0)]


def van_body(b):
    front = [(HL - 0.01, 0.62), (HL - 0.05, 0.86), (1.46, 0.95)]
    rear = [(-HL + 0.03, 0.95), (-HL + 0.01, 0.40)]
    prism_yz(b, lower_outline(front, rear), -SIDE, SIDE, BODY)
    prism_yz_taper(b, VAN_UPPER, van_hw, BODY)


def van_fine(b):
    car_common(b, 0.95)
    # parbrizul, pe panta (1,46; 0,93) -> (0,98; 1,54)
    p0, p1 = Vector((0.0, 1.46, VAN_Z0)), Vector((0.0, 0.98, 1.54))
    d = (p1 - p0)
    nrm = Vector((0.0, d.z, -d.y)).normalized()      # spre +Y si +Z
    if nrm.y < 0:
        nrm = -nrm
    pts = []
    for t, side in ((0.10, -1), (0.10, 1), (0.93, 1), (0.93, -1)):
        q = p0 + d * t
        pts.append(Vector((side * (van_hw(q.z) - 0.10), q.y, q.z)))
    slab(b, pts, nrm, 0.02, DARK, lift=0.0)
    # geamul usii cabinei, pe flancul inclinat (normala (1, 0, k))
    k = (VAN_HW0 - VAN_HW1) / (VAN_TOP - VAN_Z0)
    for sx in (-1, 1):
        n = Vector((sx * 1.0, 0.0, k)).normalized()
        quad = [(0.30, 1.02), (1.30, 1.02), (0.96, 1.46), (0.30, 1.46)]
        if sx < 0:
            quad = list(reversed(quad))
        slab(b, [Vector((sx * van_hw(z), y, z)) for y, z in quad], n, 0.02, DARK)
        # banda de protectie laterala (slot 8)
        xs = sorted((sx * (SIDE - 0.01), sx * 0.935))
        box_mm(b, xs[0], xs[1], -1.62, 1.50, 0.56, 0.66, BUMPER)
        # stalpul B (rostul usii culisante), in culoarea caroseriei, usor in relief
        xs = sorted((sx * (van_hw(1.2) - 0.005), sx * (van_hw(1.2) + 0.02)))
        box_mm(b, xs[0], xs[1], 0.18, 0.28, 0.95, 1.50, BODY)
    # geamurile usilor din spate
    for sx in (-1, 1):
        xs = sorted((sx * 0.08, sx * 0.66))
        box_mm(b, xs[0], xs[1], -HL + 0.015, -HL + 0.045, 1.08, 1.44, DARK)
    car_lights(b, HL - 0.03, 0.70, (0.70, 0.92), grille=(0.50, 0.76), tail_y=-HL + 0.03)
    car_mirrors(b, 1.28, 1.00)
    car_hubs(b)


AO_CAR = dict(samples=32, dist=1.0, gradient="vertical", low=0.62, high=1.00, power=0.8,
              floor=0.35)


def build_car(name, body_fn, fine_fn):
    obj, rng = assemble(name, [
        (body_fn, 0.05, 35.0, 35.0, 2),
        (car_wheels, 0.035, 40.0, 40.0),
        (car_bumpers, 0.035, 40.0, 40.0),
        (fine_fn, 0.0, 40.0, 40.0),
    ], AO_CAR)
    return obj


# ============================================================ M3: felinarul
def lamp_parts(b):
    b.frustum((0, 0, 0.30), 0.24, 0.17, 0.60, BODY, segments=10)            # L1
    b.cylinder((0, 0, 0.66), 0.18, 0.12, BODY, segments=10)
    b.frustum((0, 0, (0.72 + 4.45) * 0.5), 0.125, 0.10, 3.73, BODY, segments=8)   # L2
    b.cylinder((0, 0, 4.51), 0.15, 0.12, BODY, segments=8)                   # L3
    b.frustum((0, 0, 4.67), 0.10, 0.25, 0.20, BODY, segments=8)              # L4 palnia
    rot = Matrix.Rotation(math.radians(45.0), 4, "Z")

    def quad(z, r0, r1, h, slot):
        res = bmesh.ops.create_cone(b.bm, cap_ends=True, cap_tris=False, segments=4,
                                    radius1=r0, radius2=r1, depth=h,
                                    matrix=Matrix.Translation((0, 0, z)) @ rot)
        b._tag(res["verts"], slot)

    quad(4.77 + 0.26, 0.27, 0.35, 0.52, WHITE)        # geamul pe patru laturi, evazat
    quad(5.32, 0.40, 0.40, 0.06, BODY)                # rama de sus
    quad(5.40, 0.46, 0.08, 0.10, BODY)                # capacul in patru ape (L5)
    b.frustum((0, 0, 5.475), 0.06, 0.03, 0.05, BODY, segments=6)


def build_lamp():
    obj, rng = assemble("StreetLamp", [(lamp_parts, 0.0, 40.0, 40.0)],
                        dict(samples=32, dist=0.8, gradient="vertical", low=0.70, high=1.0,
                             power=0.6, floor=0.35))
    # geamul luminat nu primeste umbra de gradient (e sursa de lumina)
    _ao_override(obj, lambda co, v: max(v, 0.95) if 4.78 < co.z < 5.28 else v)
    return obj


# ============================================================ M4: mobilierul mic
def hydrant(b):
    b.cylinder((0, 0, 0.03), 0.17, 0.06, RED, segments=10)
    b.cylinder((0, 0, 0.32), 0.12, 0.52, RED, segments=10)
    b.cylinder((0, 0, 0.55), 0.15, 0.06, RED, segments=10)
    b.frustum((0, 0, 0.65), 0.13, 0.06, 0.14, RED, segments=10)
    b.cylinder((0, 0, 0.76), 0.045, 0.08, RED, segments=6)
    b.cylinder((0, 0, 0.42), 0.055, 0.40, RED, segments=8, axis="X")
    b.cylinder((0, 0.14, 0.40), 0.075, 0.12, RED, segments=8, axis="Y")


def mailbox(b):
    # P2: corp cu varf rotund (prisma pe Y din contur in XZ), picioare, clapeta
    r = 0.27
    outline = [(-r, 0.33), (r, 0.33)] + [(x, z + 1.03) for x, z in arc_pts(0, 0, r, 0, 180, 6)]
    b.prism(outline, 0.48, BODY)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box_mm(b, sx * 0.22 - 0.04, sx * 0.22 + 0.04, sy * 0.18 - 0.04, sy * 0.18 + 0.04,
                   0.0, 0.34, DARK)
    box_mm(b, -0.17, 0.17, 0.23, 0.27, 0.98, 1.12, DARK)


def newsbox(b):
    for sx, body, panel in ((-1, SAND_LIGHT, WHITE), (1, PAINTED, WHITE)):
        cx = sx * 0.235
        box_mm(b, cx - 0.19, cx + 0.19, -0.17, 0.17, 0.0, 0.08, DARK)            # talpa
        box_mm(b, cx - 0.21, cx + 0.21, -0.19, 0.19, 0.08, 0.92, body)           # corpul
        box_mm(b, cx - 0.15, cx + 0.15, -0.14, 0.14, 0.92, 1.10, body)           # caseta
        box_mm(b, cx - 0.13, cx + 0.13, 0.19, 0.22, 0.56, 0.82, panel)           # fereastra
        box_mm(b, cx - 0.15, cx + 0.15, 0.19, 0.21, 0.14, 0.44, DARK)            # usa de jos
        box_mm(b, cx - 0.10, cx + 0.10, 0.14, 0.17, 0.97, 1.05, DARK)            # fanta de monede


def trashbin(b):
    b.frustum((0, 0, 0.44), 0.25, 0.28, 0.88, OFF_LENS, segments=10)
    for k in range(8):
        a = 2 * math.pi * (k + 0.5) / 8
        r = 0.27
        rot = Matrix.Rotation(a, 3, "Z")
        b.box((r * math.cos(a), r * math.sin(a), 0.46), (0.08, 0.08, 0.76), MARBLE_GREY,
              rotation=rot)
    b.cylinder((0, 0, 0.90), 0.31, 0.08, MARBLE_GREY, segments=10)
    b.frustum((0, 0, 0.97), 0.27, 0.15, 0.06, DARK, segments=10)


def cone(b):
    box_mm(b, -0.21, 0.21, -0.21, 0.21, 0.0, 0.05, RED)
    b.frustum((0, 0, 0.375), 0.17, 0.04, 0.65, RED, segments=12)

    def r_at(z):
        return 0.17 + (0.04 - 0.17) * (z - 0.05) / 0.65

    for z0, z1 in ((0.26, 0.36), (0.46, 0.54)):
        b.frustum((0, 0, (z0 + z1) * 0.5), r_at(z0) + 0.008, r_at(z1) + 0.008, z1 - z0, WHITE,
                  segments=12)


def build_props():
    ao = dict(samples=32, dist=0.4, gradient="vertical", low=0.65, high=1.0, power=0.8,
              floor=0.35)
    out = []
    for name, fn, bev in (("Hydrant", hydrant, 0.0), ("Mailbox", mailbox, 0.02),
                          ("NewsBox", newsbox, 0.0), ("TrashBin", trashbin, 0.0),
                          ("Cone", cone, 0.0)):
        obj, rng = assemble(name, [(fn, bev, 40.0, 40.0)], ao)
        out.append(obj)
    return out


# ============================================================ M7: stalpul de amarare
def bollard(b):
    box_mm(b, -0.24, 0.24, -0.24, 0.24, 0.0, 0.06, RUST)
    prof = [(0.17, 0.06), (0.155, 0.52), (0.13, 0.60), (0.22, 0.67), (0.23, 0.75), (0.19, 0.80),
            (0.0, 0.80)]
    b.revolve(prof, DARK, segments=10, cap_bottom=True)


def build_bollard():
    obj, rng = assemble("Bollard", [(bollard, 0.0, 40.0, 35.0)],
                        dict(samples=32, dist=0.4, gradient="vertical", low=0.65, high=1.0,
                             power=0.8, floor=0.35))
    return obj


# ============================================================ M8: capcane si lazi
def _trap(b, c, L, W, H, yaw):
    """O capcana: miez de plasa (11) + rama ruginie (10) de 0,08 m."""
    rot = Matrix.Rotation(yaw, 3, "Z")
    cx, cy, cz = c

    def P(x, y, z):
        v = rot @ Vector((x, y, z))
        return (cx + v.x, cy + v.y, cz + v.z)

    t = 0.08
    b.box(P(0, 0, H * 0.5), (L - 0.06, W - 0.06, H - 0.04), PAINTED, rotation=rot)
    hl, hw = L * 0.5 - t * 0.5, W * 0.5 - t * 0.5
    # rama de sus (4 laturi)
    for sy in (-1, 1):
        b.box(P(0, sy * hw, H - t * 0.5), (L, t, t), RUST, rotation=rot)
    for sx in (-1, 1):
        b.box(P(sx * hl, 0, H - t * 0.5), (t, W - 2 * t, t), RUST, rotation=rot)
    # stalpii de colt
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box(P(sx * hl, sy * hw, (H - t) * 0.5), (t, t, H - t), RUST, rotation=rot)
    # o bara pe mijlocul fiecarei laturi lungi + talpa pe laturile lungi
    for sy in (-1, 1):
        b.box(P(0, sy * hw, (H - t) * 0.5), (t, t, H - t), RUST, rotation=rot)


def trapstack(b):
    _trap(b, (0, 0, 0), 1.00, 0.70, 0.44, 0.0)
    _trap(b, (0.04, -0.02, 0.44), 0.90, 0.62, 0.40, math.radians(12.0))


def crate(b):
    """Lada deschisa: scanduri deschise (slot 1, lemnul nou din decupare), sipci orizontale,
    rama de sus si cornierele in lemn inchis (slot 9)."""
    L, W, H = 0.80, 0.60, 0.52
    box_mm(b, -L / 2 + 0.03, L / 2 - 0.03, -W / 2 + 0.03, W / 2 - 0.03, 0.0, H - 0.10, SAND_MID)
    for z in (0.08, 0.26):
        box_mm(b, -L / 2 + 0.06, L / 2 - 0.06, -W / 2, W / 2, z, z + 0.12, SAND_MID)
        box_mm(b, -L / 2, L / 2, -W / 2 + 0.06, W / 2 - 0.06, z + 0.005, z + 0.115, SAND_MID)
    # rama de sus (lada e deschisa: se vede fundul, mai jos cu 0,10)
    for sy in (-1, 1):
        ys = sorted((sy * (W / 2 - 0.08), sy * W / 2))
        box_mm(b, -L / 2, L / 2, ys[0], ys[1], H - 0.10, H, WOOD)
    for sx in (-1, 1):
        xs = sorted((sx * (L / 2 - 0.08), sx * L / 2))
        box_mm(b, xs[0], xs[1], -W / 2 + 0.08, W / 2 - 0.08, H - 0.10, H, WOOD)
    for sx in (-1, 1):
        for sy in (-1, 1):
            xs = sorted((sx * (L / 2 - 0.085), sx * (L / 2 + 0.005)))
            ys = sorted((sy * (W / 2 - 0.085), sy * (W / 2 + 0.005)))
            box_mm(b, xs[0], xs[1], ys[0], ys[1], 0.0, H - 0.10, WOOD)


def ropecoil(b):
    """Trei spire libere, usor inclinate si decalate (nu un colac de cauciuc)."""
    for (cx, cy, cz), R, tilt, az in (((0.0, 0.0, 0.05), 0.30, 3.0, 0.0),
                                      ((0.05, 0.03, 0.12), 0.27, 9.0, 40.0),
                                      ((-0.04, 0.05, 0.19), 0.24, 14.0, 160.0)):
        faces = b.torus((0, 0, 0), R, 0.05, ROPE, major_seg=10, minor_seg=5)
        vs = list({v for f in faces for v in f.verts})
        m = (Matrix.Translation((cx, cy, cz)) @ Matrix.Rotation(math.radians(az), 4, "Z")
             @ Matrix.Rotation(math.radians(tilt), 4, "X"))
        bmesh.ops.transform(b.bm, matrix=m, verts=vs)


def build_traps():
    ao = dict(samples=32, dist=0.5, gradient="vertical", low=0.65, high=1.0, power=0.8,
              floor=0.35)
    out = []
    for name, fn in (("TrapStack", trapstack), ("Crate", crate), ("RopeCoil", ropecoil)):
        obj, rng = assemble(name, [(fn, 0.0, 40.0, 40.0)], ao)
        if name == "TrapStack":
            # miezul de plasa (slot 11) se citeste ca interior umbrit al custii, nu ca panou
            uv = obj.data.uv_layers.active
            ca = obj.data.color_attributes["AO"]
            core = set()
            for poly in obj.data.polygons:
                if int(uv.data[poly.loop_indices[0]].uv[0] * 32) == PAINTED:
                    core.update(poly.vertices)
            for i in core:
                v = min(ca.data[i].color[0], 0.38)
                ca.data[i].color = (v, v, v, 1.0)
        out.append(obj)
    return out


# ============================================================ M6: banca si rastelul
BENCH_END = [
    (0.30, 0.00), (0.30, 0.06), (0.22, 0.12), (0.22, 0.36), (0.31, 0.48), (0.31, 0.62),
    (0.22, 0.66), (-0.12, 0.62), (-0.20, 0.86), (-0.30, 0.86), (-0.24, 0.42), (-0.24, 0.10),
    (-0.30, 0.04), (-0.30, 0.00), (-0.14, 0.00), (-0.10, 0.24), (0.08, 0.24), (0.12, 0.00),
]


def bench_ends(b):
    for sx in (-1, 1):
        xs = sorted((sx * 0.80, sx * 0.90))
        prism_yz(b, BENCH_END, xs[0], xs[1], DARK)


def bench_slats(b):
    for y in (0.15, 0.01, -0.13):
        box_mm(b, -0.82, 0.82, y - 0.06, y + 0.06, 0.36, 0.44, WOOD)
    # spatarul, inclinat pe linia (-0,24; 0,44) -> (-0,30; 0,84)
    lean = math.atan2(0.06, 0.40)
    rot = Matrix.Rotation(lean, 3, "X")
    for z in (0.52, 0.66, 0.80):
        y = -0.24 - (z - 0.44) * 0.06 / 0.40 + 0.06
        b.box((0.0, y, z), (1.64, 0.08, 0.12), WOOD, rotation=rot)


def build_bench():
    obj, rng = assemble("Bench", [(bench_ends, 0.0, 40.0, 30.0), (bench_slats, 0.012, 40.0, 40.0)],
                        dict(samples=32, dist=0.5, gradient="vertical", low=0.65, high=1.0,
                             power=0.8, floor=0.35))
    return obj


def rack_base(b):
    box_mm(b, -0.72, 0.72, -0.21, 0.21, 0.0, 0.18, BUMPER)


def rack_hoops(b):
    r_bend, half = 0.16, 0.16
    for cx in (-0.45, 0.0, 0.45):
        path = [(cx - half, 0, 0.12), (cx - half, 0, 0.72)]
        for a in (150, 120, 90, 60, 30):
            t = math.radians(a)
            path.append((cx + r_bend * math.cos(t), 0, 0.72 + r_bend * math.sin(t)))
        path += [(cx + half, 0, 0.72), (cx + half, 0, 0.12)]
        b.sweep(path, 0.045, MARBLE_GREY, segments=6, dome_end=False, cap_start=False)


def build_rack():
    obj, rng = assemble("BikeRack", [(rack_base, 0.03, 40.0, 40.0), (rack_hoops, 0.0, 40.0, 50.0)],
                        dict(samples=32, dist=0.5, gradient="vertical", low=0.70, high=1.0,
                             power=0.8, floor=0.35))
    return obj


# ============================================================ export
def _export(objs, rel):
    for o in objs:
        _aabb(o)
    print("export:", export_glb(objs, rel))


def main():
    argv = sys.argv
    only = None
    for a in argv:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))

    def want(k):
        return only is None or k in only

    clear_built()
    keep = []
    if want("mast"):
        o = build_mast()
        _export([o], "sanfrancisco/props/sf_signal_mast.glb")
        keep.append(o)
    if want("cars"):
        for name, fn_b, fn_f, rel in (
                ("ParkedSedan", sedan_body, sedan_fine, "sf_parked_sedan.glb"),
                ("ParkedWagon", wagon_body, wagon_fine, "sf_parked_wagon.glb"),
                ("ParkedVan", van_body, van_fine, "sf_parked_van.glb")):
            o = build_car(name, fn_b, fn_f)
            _export([o], "sanfrancisco/vehicles/" + rel)
            keep.append(o)
    if want("lamp"):
        o = build_lamp()
        _export([o], "sanfrancisco/props/sf_street_lamp.glb")
        keep.append(o)
    if want("props"):
        objs = build_props()
        _export(objs, "sanfrancisco/props/sf_street_props.glb")
        keep += objs
    if want("bollard"):
        o = build_bollard()
        _export([o], "sanfrancisco/props/sf_bollard.glb")
        keep.append(o)
    if want("traps"):
        objs = build_traps()
        _export(objs, "sanfrancisco/props/sf_crab_traps.glb")
        keep += objs
    if want("bench"):
        o = build_bench()
        _export([o], "sanfrancisco/props/sf_bench.glb")
        keep.append(o)
    if want("rack"):
        o = build_rack()
        _export([o], "sanfrancisco/props/sf_bike_rack.glb")
        keep.append(o)
    if only is None:
        print("blend:", save_blend(keep, "sf_street.blend"))


if __name__ == "__main__":
    main()
