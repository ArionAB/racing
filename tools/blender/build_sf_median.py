"""San Francisco (Track25), pasul 7: utilajul care muta despartitorul + blocul de beton.

Brief: docs/asset_briefs/sf_median_truck.md (§1-§9 = contractul). Referinte de
caracter si culoare: docs/track_briefs/img/sf_assets_v1/sf_median_truck.png si
sf_median_block.png. Unde decuparea si brief-ul nu se potrivesc pe STRUCTURA sau
COTE, castiga brief-ul (decuparea e un camion cu o cabina, rampa si caroserie bej;
blocul din decupare are laturi in panta New Jersey -- ambele respinse de brief).

  MedianTruck_Body  sanfrancisco/vehicles/sf_median_truck.glb   (un singur nod-mesh)
  MedianBlock       sanfrancisco/props/sf_median_block.glb      (un singur nod-mesh)

Axe (Blender): X = latimea, Y = lungimea (+Y Blender = -Z Godot), Z = sus.
Utilajul e simetric fata-spate; blocul are lungimea pe X.

LISTA DE ELEMENTE -- acceptarea se face element cu element pe lista asta.

Utilajul (gabarit 2,6 X x 3,2 sus x 10,0 lungime, de la z = 0):
  T1. Carcasa transportorului: cutie gri-albastra (slot 11) intre cabine,
      |y| < 3,2, z 1,18..2,70, latime 2,5.
  T2. Doua cabine de sofer, cate una la fiecare capat (|y| 3,2..5,0, z 1,15..3,0),
      profil cu parbriz inclinat; acoperis cu streasina si o cutie de climatizare
      (pana la 3,20).
  T3. Geamuri mari (slot 20): parbriz pe toata latimea, doua geamuri laterale pe
      fiecare parte a fiecarei cabine, geam spre carcasa.
  T4. Tunelul de dedesubt: gol 1,0 x 1,15 pe toata lungimea, pe axa; tavan
      intunecat (placa slot 20 la 1,15..1,18); pereti = placile interioare ale
      boghiurilor si ale caselor de capat.
  T5. Transportorul in S din tunel: 9 perechi de role ⌀ 0,5 m (8 laturi, slot 20)
      care prind gatul blocului, cu tamburi pana in tavan; perechile urmeaza un S
      bland. Vizibile din lateral prin golul dintre boghiuri.
  T6. 4 boghiuri (2 pe parte), in afara tunelului: cate 2 roti ⌀ 0,8 in tandem
      (8 roti), y 0..0,8, cu capace de butuc gri si aripa peste tandem.
  T7. Casele de capat (bara de protectie): doua blocuri sub fiecare cabina, de o
      parte si de alta a gurii tunelului, cu panouri de chevroane rosu-alb
      (sloturile 7 si 22) in relief de 0,02 m, ca geometrie.
  T8. Banda de chevroane pe fata fiecarei cabine, peste gura tunelului (V pe axa).
  T9. Faruri albe (slot 22) si grila intunecata la ambele capete.
  T10. Pe acoperisul carcasei: balustrada joasa si groasa (0,10 m, slot 20) pe
       ambele laturi + pasarela intunecata.
  T11. Lumina de avertizare rotunda (slot 30, singura piesa portocalie) pe un soclu,
       in mijlocul acoperisului.
  T12. Nervuri verticale si o bara de protectie intunecata pe laturile carcasei;
       cornisa sus.
  T13. Usa cabinei: rost si maner (slot 20).
  T14. Panouri diagonale rosu-alb pe laturile carcasei, langa fiecare cabina
       (4 bucati, ca dunga diagonala din decupare), in relief de 0,02.

Blocul (exact 3,00 X x 0,95 sus x 0,60 Y; <= 120 de triunghiuri):
  B1. Profil in T cu laturi VERTICALE: baza 0,60 pana la +0,70, gat 0,30
      (+0,70..+0,80), cap 0,45 (+0,80..+0,95). Slot 8 (concrete).
  B2. Tesituri de 0,05 pe muchiile lungi (sus la baza, sus la cap).
  B3. Cep pe capatul +X (limba centrala) si mufa pe capatul -X (doua urechi), ca
      doua blocuri la 3,0 m sa para legate; corpul se termina la +-1,42.
  B4. Reflector mic (0,15 x 0,10, relief 0,01, slot 22) pe fiecare fata laterala,
      pe cap (pe baza ar fi iesit din latimea de 0,60).
  B5. AO: 0,75 la baza -> 1,0 pe cap, gatul ~0,65.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_median.py
Verificare:
    python tools/blender/verify_glb.py assets/models/sanfrancisco/vehicles/sf_median_truck.glb 8000
    python tools/blender/verify_glb.py assets/models/sanfrancisco/props/sf_median_block.glb 120
Randari de control: preview_sf_median.py.
"""

import math
import bmesh
import bpy
from mathutils import Matrix, Vector

# ============================================================ cotele utilajului
HALF_W = 1.30          # gabarit: 2,6 m
SHELL = 1.25           # peretii cabinei si ai carcasei (aripile ies pana la 1,30)
HALF_L = 5.00          # gabarit: 10,0 m
FACE = 4.98            # fata cabinei; panourile in relief ies pana la 5,00
CAB_IN = 3.20          # cabina: |y| 3,2..5,0 (1,8 m)
TUN_HW = 0.50          # tunelul: 1,0 m latime
TUN_H = 1.15           # tunelul: 1,15 m inaltime
BODY_Z0 = 1.18         # sub ea, placa de tavan a tunelului (1,15..1,18)
BODY_TOP = 2.70
ROOF = 2.98
WHEEL_R, WHEEL_W, WHEEL_X = 0.40, 0.40, 0.98
AXLES = (3.05, 3.95)   # |y| rotilor in tandem (boghiul sub cabina)
BOGIE_Y0, BOGIE_Y1 = 2.55, 4.40
ROLL_Y = 2.40          # rolele: |y| <= 2,4 (in golul dintre boghiuri)
ROLL_STEP = 0.60
ROLL_R, ROLL_GRIP = 0.25, 0.43   # raza rolei; distanta centru rola - axa blocului
S_AMP = 0.08           # amplitudinea S-ului (vezi nota din roller_s)

DARK = VOLCANIC_BLACK
BODY = PAINTED
WHITE = FOAM_WHITE
RED = KERB_RED

AO_TRUCK = dict(samples=32, dist=2.0, gradient="vertical",
                low=0.60, high=1.00, power=1.0, floor=0.30)
AO_BLOCK = dict(samples=32, dist=0.6, gradient="vertical",
                low=0.75, high=1.00, power=1.0, floor=0.40)


# ============================================================ ajutoare
def prism_yz(b, outline, x0, x1, slot):
    """Prisma dintr-un contur (y, z) extrudat pe X intre x0 si x1 (profil lateral)."""
    lo = [b.bm.verts.new((x0, y, z)) for y, z in outline]
    hi = [b.bm.verts.new((x1, y, z)) for y, z in outline]
    n = len(outline)
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def box_mm(b, x0, x1, y0, y1, z0, z1, slot):
    """Cutie data prin min/max (mai usor de citit decat centru + marime)."""
    return b.box(((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                 (x1 - x0, y1 - y0, z1 - z0), slot)


def _clip(poly, a, c, keep_ge):
    """Sutherland-Hodgman pe semiplanul a.p >= c (sau <= c)."""
    out = []
    n = len(poly)
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        fp = a[0] * p[0] + a[1] * p[1] - c
        fq = a[0] * q[0] + a[1] * q[1] - c
        if not keep_ge:
            fp, fq = -fp, -fq
        if fp >= 0:
            out.append(p)
        if (fp >= 0) != (fq >= 0):
            t = fp / (fp - fq)
            out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return out


def chevrons(b, x0, x1, z0, z1, y_face, sign, stripe=0.15, v_center=None,
             side_x=None, slope=1.0):
    """Panou de chevroane rosu-alb, ca geometrie: fasii la 45 de grade, in relief
    de 0,02 m pe fata y_face (sign = +1 spre +Y, -1 spre -Y).

    v_center = x-ul axei unui V (fasiile se oglindesc fata de ea); None = toate
    fasiile inclinate la fel (`slope`). Panoul e taiat pe dreptunghi cu
    Sutherland-Hodgman. Cu `side_x`, panoul sta pe o fata LATERALA (x = side_x,
    relief spre `sign`), iar x0/x1 sunt capetele lui pe Y.
    """
    cy = y_face + sign * 0.01 if side_x is None else 0.0
    halves = []
    if v_center is None:
        halves.append(((x0, x1), slope, False))
    else:
        # fiecare jumatate taiata pe panou: un panou care nu contine axa V-ului
        # (casele de capat) are o singura jumatate
        if x1 > v_center:
            halves.append(((max(x0, v_center), x1), 1.0, False))
        if x0 < v_center:
            halves.append(((x0, min(x1, v_center)), -1.0, True))
    w = stripe * math.sqrt(2.0)
    for (ux0, ux1), slope, mirrored in halves:
        rect = [(ux0, z0), (ux1, z0), (ux1, z1), (ux0, z1)]
        # fasia k: k*w <= (x - xc) + slope*(z - z0) < (k+1)*w, cu xc = axa V-ului
        xc = v_center if v_center is not None else x0
        kmin = int(math.floor(((ux0 - xc) + min(0.0, slope * (z1 - z0))) / w)) - 1
        kmax = int(math.ceil(((ux1 - xc) + max(0.0, slope * (z1 - z0))) / w)) + 1
        for k in range(kmin, kmax):
            a = (1.0, slope)
            c0 = xc + slope * z0 + k * w
            poly = _clip(rect, a, c0, True)
            if len(poly) >= 3:
                poly = _clip(poly, a, c0 + w, False)
            if len(poly) < 3:
                continue
            area = 0.0
            for i in range(len(poly)):
                p, q = poly[i], poly[(i + 1) % len(poly)]
                area += p[0] * q[1] - q[0] * p[1]
            if abs(area) < 1e-5:
                continue
            slot = RED if (k % 2 == 0) else WHITE
            if side_x is None:
                b.prism(poly, 0.02, slot, center=(0.0, cy, 0.0))
            else:
                xs = sorted((side_x - sign * 0.005, side_x + sign * 0.02))
                prism_yz(b, poly, xs[0], xs[1], slot)


def roller_s(y):
    """Axa transportorului in S, in cadrul utilajului.

    Brief-ul cere un S "de la o margine a tunelului la cealalta". In joc insa
    blocurile trec prin utilaj aproape drept: camionul sta la centrul S-ului si e
    rotit dupa panta de acolo (`movable_median_hazard.gd`, `_truck_yaw`), iar
    abaterea randului fata de tangenta, pe +-5 m, e de doar +-0,06 m (din
    `offset_at`: 3,5 x (2 smoothstep - 1) pe 30 m). Un S de la perete la perete
    ar taia rolele prin blocuri, deci S-ul ramane bland: +-0,08 m."""
    t = max(0.0, min(1.0, (y + ROLL_Y) / (2.0 * ROLL_Y)))
    g = t * t * (3.0 - 2.0 * t)
    return S_AMP * (2.0 * g - 1.0)


# ============================================================ utilajul
def truck_main(b):
    """Tot ce primeste bevel 0,04 (corpuri, roti, aripi, balustrada)."""
    # T1 carcasa (intra 0,05 in cabine, ca sa nu ramana fata comuna)
    box_mm(b, -SHELL, SHELL, -CAB_IN - 0.05, CAB_IN + 0.05, BODY_Z0, BODY_TOP, BODY)
    # T12 cornisa, bara de protectie, nervuri
    box_mm(b, -1.28, 1.28, -CAB_IN, CAB_IN, BODY_TOP - 0.07, BODY_TOP + 0.02, BODY)
    for sx in (-1, 1):
        xs = sorted((sx * (SHELL - 0.02), sx * (SHELL + 0.035)))
        box_mm(b, xs[0], xs[1], -CAB_IN, CAB_IN, 1.24, 1.36, DARK)
        for y in (-2.4, -1.2, 0.0, 1.2, 2.4):
            x_in, x_out = sx * (SHELL - 0.02), sx * (SHELL + 0.03)
            box_mm(b, min(x_in, x_out), max(x_in, x_out), y - 0.05, y + 0.05,
                   1.36, BODY_TOP - 0.07, BODY)

    for sy in (-1, 1):
        # T2 cabina: profil lateral cu parbriz inclinat
        prof = [(CAB_IN, BODY_Z0 - 0.03), (FACE, BODY_Z0 - 0.03), (FACE, 2.25),
                (FACE - 0.18, ROOF), (CAB_IN, ROOF)]
        prism_yz(b, [(sy * y, z) for y, z in prof], -SHELL, SHELL, BODY)
        # acoperis cu streasina + cutia de climatizare
        box_mm(b, -1.27, 1.27, *sorted((sy * (CAB_IN - 0.04), sy * (FACE - 0.14))),
               ROOF - 0.01, ROOF + 0.12, BODY)
        box_mm(b, -0.50, 0.50, *sorted((sy * 3.55, sy * 4.35)), ROOF + 0.11, 3.20, BODY)

        # T7 casele de capat, de o parte si de alta a gurii tunelului
        for sx in (-1, 1):
            xs = sorted((sx * TUN_HW, sx * SHELL))
            box_mm(b, xs[0], xs[1], *sorted((sy * BOGIE_Y1, sy * FACE)), 0.28, BODY_Z0, BODY)

            # T6 boghiul: placa interioara (peretele tunelului), sasiu, aripa
            ys = sorted((sy * BOGIE_Y0, sy * BOGIE_Y1))
            xi = sorted((sx * TUN_HW, sx * 0.64))
            box_mm(b, xi[0], xi[1], ys[0], ys[1], 0.42, BODY_Z0, BODY)
            xc = sorted((sx * 0.64, sx * SHELL))
            box_mm(b, xc[0], xc[1], ys[0], ys[1], 0.98, BODY_Z0, BODY)
            fender = [(BOGIE_Y0 - 0.06, 0.70), (BOGIE_Y0 + 0.10, 0.98),
                      (BOGIE_Y1, 0.98), (BOGIE_Y1, 0.88), (BOGIE_Y0 + 0.18, 0.88)]
            xf = sorted((sx * 0.72, sx * HALF_W))
            prism_yz(b, [(sy * y, z) for y, z in fender], xf[0], xf[1], BODY)
            for ay in AXLES:
                c = (sx * WHEEL_X, sy * ay, WHEEL_R)
                b.cylinder(c, WHEEL_R, WHEEL_W, DARK, segments=12, axis="X")
                b.cylinder((sx * (WHEEL_X + WHEEL_W * 0.5 + 0.015), sy * ay, WHEEL_R),
                           0.20, 0.05, BODY, segments=8, axis="X")

    # T10 balustrada joasa si groasa pe ambele laturi + pasarela
    for sx in (-1, 1):
        x = sx * 1.10
        for y in (-2.95, -1.475, 0.0, 1.475, 2.95):
            box_mm(b, x - 0.05, x + 0.05, y - 0.05, y + 0.05, BODY_TOP, 3.00, DARK)
        box_mm(b, x - 0.05, x + 0.05, -3.0, 3.0, 2.92, 3.02, DARK)
        box_mm(b, x - 0.045, x + 0.045, -3.0, 3.0, 2.80, 2.86, DARK)
    for y0, y1 in ((-2.9, -0.45), (0.45, 2.9)):
        box_mm(b, -0.40, 0.40, y0, y1, BODY_TOP, BODY_TOP + 0.04, DARK)
    # T11 soclul luminii de avertizare
    box_mm(b, -0.30, 0.30, -0.30, 0.30, BODY_TOP, BODY_TOP + 0.12, DARK)


def truck_fine(b):
    """Piesele fara bevel: geamuri, chevroane, faruri, role, tavanul tunelului."""
    # T4 tavanul tunelului (intunecat), pe toata lungimea
    box_mm(b, -0.80, 0.80, -FACE, FACE, TUN_H, BODY_Z0, DARK)

    # T5 transportorul: perechi de role pe un S bland
    n = int(round(2 * ROLL_Y / ROLL_STEP)) + 1
    for i in range(n):
        y = -ROLL_Y + i * ROLL_STEP
        c = roller_s(y)
        for sx in (-1, 1):
            x = c + sx * ROLL_GRIP
            b.cylinder((x, y, 0.75), ROLL_R, 0.09, DARK, segments=8)
            b.cylinder((x, y, (0.795 + TUN_H) * 0.5), 0.13, TUN_H - 0.795, DARK, segments=8)

    rake = math.atan2(0.18, ROOF - 2.25)
    for sy in (-1, 1):
        # T3 parbrizul, pe planul inclinat
        mid = Vector((0.0, sy * (FACE - 0.09), (2.25 + ROOF) * 0.5))
        nrm = Vector((0.0, sy * math.cos(rake), math.sin(rake)))
        rot = Matrix.Rotation(-sy * rake, 3, "X")
        b.box(mid + nrm * 0.012, (2.16, 0.04, 0.60), DARK, rotation=rot)
        for sx in (-1, 1):
            # geamurile laterale (doua pe parte)
            for y0, y1 in ((3.40, 3.98), (4.08, 4.66)):
                xs = sorted((sx * (SHELL - 0.015), sx * (SHELL + 0.025)))
                box_mm(b, xs[0], xs[1], *sorted((sy * y0, sy * y1)), 2.30, 2.88, DARK)
            # T13 rostul usii si manerul
            xs = sorted((sx * (SHELL - 0.01), sx * (SHELL + 0.012)))
            box_mm(b, xs[0], xs[1], *sorted((sy * 3.30, sy * 3.34)), 1.30, 2.92, DARK)
            box_mm(b, xs[0], xs[1], *sorted((sy * 4.72, sy * 4.76)), 1.30, 2.24, DARK)
            xs = sorted((sx * (SHELL - 0.01), sx * (SHELL + 0.035)))
            box_mm(b, xs[0], xs[1], *sorted((sy * 3.42, sy * 3.60)), 2.08, 2.14, DARK)
            # T9 farurile
            xs = sorted((sx * 0.70, sx * 1.06))
            box_mm(b, xs[0], xs[1], *sorted((sy * (FACE - 0.01), sy * HALF_L)), 1.70, 1.94, WHITE)
            # T7 chevroanele caselor de capat (V pe axa utilajului)
            xs = sorted((sx * 0.56, sx * 1.20))
            chevrons(b, xs[0], xs[1], 0.34, 1.10, sy * FACE, sy, v_center=0.0)
        # geamul spre carcasa
        box_mm(b, -0.85, 0.85, *sorted((sy * (CAB_IN - 0.025), sy * (CAB_IN + 0.015))),
               2.76, 2.92, DARK)
        # T9 grila
        box_mm(b, -0.52, 0.52, *sorted((sy * (FACE - 0.01), sy * HALF_L)), 1.68, 1.96, DARK)
        # T8 banda de chevroane peste gura tunelului
        chevrons(b, -1.22, 1.22, 1.22, 1.60, sy * FACE, sy, v_center=0.0)
        # T14 panourile diagonale de pe laturile carcasei, langa cabine (ca in decupare)
        for sx in (-1, 1):
            ys = sorted((sy * 1.30, sy * 2.30))
            chevrons(b, ys[0], ys[1], 1.42, 2.40, None, sx, stripe=0.18,
                     side_x=sx * SHELL, slope=float(sy))

    # T11 lumina de avertizare (slotul 30, singura piesa portocalie)
    b.cylinder((0.0, 0.0, BODY_TOP + 0.12 + 0.14), 0.24, 0.28, LAVA_ORANGE, segments=8)
    b.frustum((0.0, 0.0, BODY_TOP + 0.40 + 0.05), 0.24, 0.12, 0.10, LAVA_ORANGE, segments=8)


def _prep(obj, bevel, bevel_angle, smooth):
    snap = snapshot_slots(obj)
    apply_bevel(obj, bevel, angle_deg=bevel_angle)
    apply_smooth(obj, smooth)
    assign_uvs(obj, snap)


def _join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


def build_truck():
    b = Builder()
    truck_main(b)
    main = b.to_object("MedianTruck_Body")
    _prep(main, 0.04, 40.0, 40.0)

    b = Builder()
    truck_fine(b)
    fine = b.to_object("MedianTruck_Fine")
    _prep(fine, 0.0, 40.0, 40.0)

    obj = _join([main, fine], "MedianTruck_Body")
    for a in ("slot",):
        if a in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes[a])
    set_origin_base(obj, center_xy=True)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    rng = bake_ao(obj, **AO_TRUCK)

    # AO tintit (brief §6): tunelul ~0,45 -- golul intunecat din care ies blocurile;
    # sub cabine si intre roti ~0,55.
    ca = obj.data.color_attributes["AO"]
    for i, v in enumerate(obj.data.vertices):
        x, y, z = v.co
        val = ca.data[i].color[0]
        if abs(x) <= 0.81 and z <= BODY_Z0 + 0.005:
            val = 0.45
        elif z < 0.95 and abs(x) > 0.81:
            val = min(val, 0.55 + 0.15 * (z / 0.95))
        ca.data[i].color = (val, val, val, 1.0)
    vals = [ca.data[i].color[0] for i in range(len(obj.data.vertices))]
    print("MedianTruck_Body: %d tris, AO %.3f..%.3f (brut %.3f..%.3f)"
          % (tri_count(obj), min(vals), max(vals), rng[0], rng[1]))
    return obj


# ============================================================ blocul
BLK_HALF = 1.50
BLK_BODY = 1.42
HEAD_INSET = 0.06


def block_profile():
    """Profilul in T (y, z), cu tesituri de 0,05: jumatatea dreapta + oglinda."""
    right = [(0.30, 0.0), (0.30, 0.65), (0.25, 0.70), (0.15, 0.70), (0.15, 0.80),
             (0.225, 0.80), (0.225, 0.90), (0.175, 0.95)]
    left = [(-y, z) for y, z in reversed(right)]
    return right + left


def build_block():
    b = Builder()
    # B1/B2 profilul in T extrudat pe X
    # Capul T-ului e cu HEAD_INSET mai scurt la fiecare capat: la fiecare imbinare
    # apare o crestatura vazuta de sus (ritmul randului, ca tesiturile de capat din
    # decupare), cu doar 2 triunghiuri pe capat. Capacul se sparge in doua poligoane
    # plane (baza+gat la +-1,42, capul la +-1,36) legate de o treapta la z = 0,80.
    prof = block_profile()
    n = len(prof)
    head = [i for i, (y, z) in enumerate(prof) if z >= 0.80 and abs(y) > 0.16]

    def ring(sx):
        out = []
        for i, (y, z) in enumerate(prof):
            x = sx * (BLK_BODY - (HEAD_INSET if i in head else 0.0))
            out.append(b.bm.verts.new((x, y, z)))
        return out

    lo, hi = ring(-1), ring(1)
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    low = [i for i in range(n) if i not in head]
    # capetele: [0..4] dreapta jos, [5..10] capul, [11..15] stanga jos (vezi profilul)
    for ring_v, flip in ((hi, False), (lo, True)):
        lower = [ring_v[i] for i in low]
        top = [ring_v[i] for i in head]
        step = [ring_v[4], ring_v[5], ring_v[10], ring_v[11]]
        for face in (lower, top, step):
            b.bm.faces.new(tuple(reversed(face)) if flip else tuple(face))
    b._tag(lo + hi, CONCRETE)
    # B3 cep (+X) si mufa (-X)
    box_mm(b, BLK_BODY, BLK_HALF, -0.07, 0.07, 0.12, 0.62, CONCRETE)
    for sy in (-1, 1):
        ys = sorted((sy * 0.09, sy * 0.23))
        box_mm(b, -BLK_HALF, -BLK_BODY, ys[0], ys[1], 0.12, 0.62, CONCRETE)
    # B4 reflectoarele, pe capul T-ului
    for sy in (-1, 1):
        ys = sorted((sy * 0.225, sy * 0.235))
        box_mm(b, -0.075, 0.075, ys[0], ys[1], 0.80, 0.90, WHITE)
    obj = b.to_object("MedianBlock")

    # fetele ascunse nu se platesc (bugetul e 120): talpa, spatele cepului/urechilor
    # lipit de corp, spatele reflectoarelor lipit de cap
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.normal_update()
    dead = []
    for f in bm.faces:
        c, nr = f.calc_center_median(), f.normal
        if nr.z < -0.99 and c.z < 1e-4:
            dead.append(f)
        elif abs(nr.x) > 0.99 and abs(abs(c.x) - BLK_BODY) < 1e-4 and nr.x * c.x < 0 \
                and abs(c.y) < 0.24 and c.z < 0.63:
            dead.append(f)
        elif abs(nr.y) > 0.99 and abs(abs(c.y) - 0.225) < 1e-4 and nr.y * c.y < 0:
            dead.append(f)
    bmesh.ops.delete(bm, geom=dead, context="FACES_ONLY")
    bm.to_mesh(obj.data)
    bm.free()

    # B5: fara bevel (doar tesiturile din profil), fatete ferme
    snap = snapshot_slots(obj)
    apply_smooth(obj, 30.0)
    assign_uvs(obj, snap)
    set_origin_base(obj, center_xy=True)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    bake_ao(obj, **AO_BLOCK)
    ca = obj.data.color_attributes["AO"]
    for i, v in enumerate(obj.data.vertices):
        x, y, z = v.co
        if 0.69 < z < 0.81 and abs(y) <= 0.155:
            ca.data[i].color = (0.65, 0.65, 0.65, 1.0)     # gatul T-ului
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    vals = [ca.data[i].color[0] for i in range(len(obj.data.vertices))]
    print("MedianBlock: %d tris, AO %.3f..%.3f" % (tri_count(obj), min(vals), max(vals)))
    return obj


def _aabb(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    # Godot: (x, z, -y)
    print("  AABB Godot %s: X %.3f..%.3f (%.3f)  Y %.3f..%.3f (%.3f)  Z %.3f..%.3f (%.3f)"
          % (obj.name, min(xs), max(xs), max(xs) - min(xs), min(zs), max(zs), max(zs) - min(zs),
             -max(ys), -min(ys), max(ys) - min(ys)))


if __name__ == "__main__":
    clear_built()
    truck = build_truck()
    _aabb(truck)
    print("export:", export_glb([truck], "sanfrancisco/vehicles/sf_median_truck.glb"))
    block = build_block()
    _aabb(block)
    print("export:", export_glb([block], "sanfrancisco/props/sf_median_block.glb"))
    print("blend:", save_blend([truck, block], "sf_median.blend"))
