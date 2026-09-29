"""Jodhpur -- traficul, val 4a (brief §1.5, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/vehicles/tuktuk.glb   autoricsa jucabila (contract `Car`)

**Contractul de cod** (`scenes/cars/car.gd:2431-2470`, `_build_visual` si
`_update_wheels`), inghetat in geometrie:

  * botul spre **-Y in Blender** (= +Z in Godot); `tuktuk.tres` pastreaza
    `model_rotation_deg = 180`, deci in joc botul ajunge pe -Z, directia de
    mers a lui `Car`. `car.gd` decide stanga/dreapta rotii dupa semnul lui
    `position.x` PRESUPUNAND rotatia de 180: stanga masinii = +X aici;
  * originea radacinii la sol, centrata (bbox-ul ansamblului);
  * rotile sunt noduri SEPARATE, copii directi ai radacinii, cu originea in
    CENTRUL OSIEI si baza identitate: `_update_wheels` compune
    `Basis(RIGHT, spin)` peste baza originala, deci osia trebuie sa fie axa X
    a nodului (cilindru pe X), iar roata din fata vireaza in jurul Y-ului ei;
  * `Wheel_Front` (numele contine "front" -> vireaza), `Wheel_Rear_L`
    (+X), `Wheel_Rear_R` (-X), toate cu centrul la z = 0,22 = raza:
    `car.gd` citeste raza din `position.y` al PRIMEI roti gasite;
  * coliziunea NU e modelul: e cutia `body_length` x `body_width` din .tres.

**Decuparile** (`docs/track_briefs/img/jodhpur_assets_v1/tuktuk_a.png`,
`tuktuk_b.png`). Brief-ul spune ca ambele sunt din fata; **nu e asa**:
`tuktuk_a` e 3/4 fata-stanga, `tuktuk_b` e 3/4 SPATE-stanga (se vad
stopurile, geamul din spate si ambele roti din spate). Deci spatele urmeaza
planșa (brief §0.1: planșa castiga), nu o fotografie generica: panou din
spate inchis, geam dreptunghiular in galben, stopuri, bara galbena jos. Fara
prelata ruloata -- nu apare pe niciuna din decupari.
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile (brief §0.4 si §1.5).
BODY = LOG_DARK          # caroseria neagra (Tuktuk_Body)
YELLOW = CAR_YELLOW      # acoperisul si cowl-ul galben (excepie declarata)
GLASS = VOLCANIC_BLACK   # parbrizul, geamul din spate
SEAT = VOLCANIC_BLACK    # perne (mai inchise decat caroseria, ca pe decupare)
TIRE = VOLCANIC_BLACK
METAL = PAINTED          # butucii, ghidonul
AMBER = LAVA_ORANGE      # semnalizatoare, catadioptrul lateral
TAIL = CAR_RED           # stopurile

AO_CAR = dict(samples=16, dist=1.0, gradient="vertical",
              low=0.62, high=1.00, power=0.85, floor=0.30)
AO_WHEEL = dict(samples=12, dist=0.4, gradient="vertical",
                low=0.80, high=1.00, power=0.85, floor=0.45)

# --- Cotele (Blender: X latime, Y lungime cu botul spre -Y, Z sus) ----------
TT_L, TT_W, TT_H = 2.6, 1.4, 1.8
WHEEL_R = 0.22
FRONT_Y = -1.00            # osia din fata (roata iese putin in fata botului)
REAR_Y = 0.84              # osia din spate
REAR_X = 0.55              # ecartamentul spate (+-), sub caroserie
ROOF_HW = 0.68             # acoperisul e partea cea mai lata
BODY_HW = 0.66
FLOOR_Z = 0.42             # podeaua cabinei
BELT_Z = 0.95              # linia galben / negru pe sferturile din spate
ROOF_Z0, ROOF_Z1 = 1.52, 1.80
REAR_FACE_Y = 1.28
CAB_BACK_Y = 0.55          # stalpul din spate al golului lateral
COWL_BACK_Y = -0.74        # stalpul A (spatele cowl-ului)


# ---------------------------------------------------------------------------
# helperi de forma: loft din sectiuni + dreptunghi rotunjit
# ---------------------------------------------------------------------------

def _loft(b, sections, slot, cap_start=True, cap_end=True):
    """Suprafata prin sectiuni inchise (liste de puncte 3D cu acelasi numar),
    cu capace ngon. Sectiunile merg de la botul spre spate (+Y)."""
    rings = [[b.bm.verts.new(Vector(p)) for p in sec] for sec in sections]
    faces = []
    n = len(rings[0])
    for r0, r1 in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            faces.append(b.bm.faces.new((r0[i], r0[j], r1[j], r1[i])))
    if cap_start:
        faces.append(b.bm.faces.new(tuple(reversed(rings[0]))))
    if cap_end:
        faces.append(b.bm.faces.new(tuple(rings[-1])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _rrect(hw, z0, z1, r_top, r_bot=0.0, n=3):
    """Dreptunghi rotunjit in planul (x, z), sens trigonometric vazut din +Y:
    colturile de sus cu raza r_top (n segmente), cele de jos cu r_bot. Numarul
    de puncte e fix (4 * (n + 1)) pentru orice raze, ca sa se poata lofta."""
    pts = []
    corners = ((hw, z0, r_bot, -90.0), (hw, z1, r_top, 0.0),
               (-hw, z1, r_top, 90.0), (-hw, z0, r_bot, 180.0))
    for cx, cz, r, a0 in corners:
        ox = cx - math.copysign(r, cx)
        oz = cz - r if cz == z1 else cz + r
        for k in range(n + 1):
            a = math.radians(a0 + 90.0 * k / n)
            pts.append((ox + r * math.cos(a), oz + r * math.sin(a)))
    return pts


def _sec(y, prof):
    return [(x, y, z) for x, z in prof]


def _hsec(z, plan):
    return [(x, y, z) for x, y in plan]


def _plan_rear(hw, r_rear=0.16, r_front=0.02):
    """Planul sfertului din spate (x, y): colturile din spate rotunjite."""
    return _rrect(hw, CAB_BACK_Y, REAR_FACE_Y, r_rear, r_front, n=3)


def _arc_band(b, center, r_in, r_out, width, a0, a1, slot, n=7):
    """Aripa de roata: banda in arc in planul YZ, in jurul osiei X prin
    `center`, de la unghiul a0 la a1 (grade; 0 = spre -Y/bot, 90 = sus)."""
    cx, cy, cz = center
    hw = width * 0.5
    secs = []
    for k in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * k / n)
        dy, dz = -math.cos(a), math.sin(a)
        secs.append([(cx - hw, cy + dy * r_in, cz + dz * r_in),
                     (cx + hw, cy + dy * r_in, cz + dz * r_in),
                     (cx + hw, cy + dy * r_out, cz + dz * r_out),
                     (cx - hw, cy + dy * r_out, cz + dz * r_out)])
    return _loft(b, secs, slot)


def _wheel(name, center, width):
    """Roata cu osia pe X, construita IN JURUL ORIGINII (pivotul = centrul
    osiei se pune dupa finish, cu set_origin_at)."""
    b = Builder()
    b.cylinder((0.0, 0.0, 0.0), WHEEL_R, width, TIRE, segments=16, axis="X")
    b.cylinder((0.0, 0.0, 0.0), WHEEL_R * 0.52, width + 0.02, METAL,
               segments=10, axis="X")
    obj = b.to_object(name)
    for v in obj.data.vertices:
        v.co += Vector(center)
    return obj


# ---------------------------------------------------------------------------
# tuk-tuk
# ---------------------------------------------------------------------------

def build_tuktuk():
    """Tuk-tuk (autoricsa), 2,6 x 1,4 x 1,8 m, botul spre -Y.

    Lista de elemente, de pe decupari (scrisa inainte de modelare):
      tuktuk_a (3/4 fata-stanga):
        1. acoperis galben, un volum rotunjit pe toate muchiile, cea mai lata
           parte a vehiculului, iese putin peste parbriz;
        2. parbriz mare, inchis la culoare, cu stalpi A galbeni;
        3. cowl galben sub parbriz, care coboara pe fata pana la faruri;
        4. botul negru sub cowl, mai ingust decat cabina, cu 3 lumini: una
           centrala (galbena) si doua semnalizatoare portocalii la colturi;
        5. O roata in fata, sub bot, cu aripa neagra deasupra si furca;
        6. oglinda mica pe stalpul A;
        7. golul lateral mare, fara usa, de la stalpul A la sfertul din spate,
           cu un stalp subtire la mijloc (dupa scaunul soferului);
        8. prin gol: scaunul soferului (in fata) si bancheta din spate, negre,
           cu spatar; ghidonul in spatele parbrizului;
        9. sfertul din spate inchis: negru jos, galben sus (linia la ~0,95 m);
       10. podeaua/pragul negru sub gol.
      tuktuk_b (3/4 SPATE-stanga):
       11. panoul din spate: galben sus cu UN geam dreptunghiular, negru jos;
       12. 2 stopuri rosii-portocalii la colturile de jos ale spatelui;
       13. bara galbena jos, la mijloc (fara numar, regula 0.8);
       14. catadioptru portocaliu pe latura, la linia galben/negru;
       15. 2 roti in spate, sub caroserie, cu aripi.
    """
    body = Builder()
    roof = Builder()

    # 1. acoperisul: loft cu sectiune rotunjita sus, capetele racordate
    prof = lambda hw, z0, z1, r: _rrect(hw, z0, z1, r, 0.0, n=4)
    roof_secs = [
        # botul acoperisului se rotunjeste in jos peste parbriz, ca pe decupare
        _sec(-1.06, prof(ROOF_HW - 0.14, ROOF_Z0 + 0.04, ROOF_Z1 - 0.14, 0.06)),
        _sec(-1.03, prof(ROOF_HW - 0.06, ROOF_Z0 + 0.01, ROOF_Z1 - 0.06, 0.14)),
        _sec(-0.97, prof(ROOF_HW - 0.02, ROOF_Z0, ROOF_Z1 - 0.015, 0.20)),
        _sec(-0.88, prof(ROOF_HW, ROOF_Z0, ROOF_Z1, 0.22)),
        _sec(REAR_FACE_Y - 0.10, prof(ROOF_HW, ROOF_Z0, ROOF_Z1, 0.22)),
        _sec(REAR_FACE_Y - 0.03, prof(ROOF_HW - 0.03, ROOF_Z0, ROOF_Z1 - 0.02, 0.20)),
        _sec(REAR_FACE_Y, prof(ROOF_HW - 0.09, ROOF_Z0, ROOF_Z1 - 0.07, 0.14)),
    ]
    _loft(roof, roof_secs, YELLOW)

    # 9/11. sfertul din spate, jumatatea galbena (de la centura la acoperis)
    #     loft pe VERTICALA, cu colturile din spate rotunjite in plan (spatele
    #     decuparii b e rotund, nu o cutie)
    _loft(roof, [_hsec(z, _plan_rear(hw)) for z, hw in
                 ((BELT_Z, BODY_HW), (ROOF_Z0 + 0.02, ROOF_HW))], YELLOW)
    # 2. stalpii A, galbeni, putin inclinati (baza in fata)
    for sx in (-1.0, 1.0):
        roof.beam((sx * (BODY_HW - 0.04), -0.97, 0.88), (sx * (ROOF_HW - 0.07), -0.90, ROOF_Z0 + 0.02),
                  (0.08, 0.08), YELLOW)

    # 11. geamul din spate (un singur dreptunghi)
    body.box((0.0, REAR_FACE_Y + 0.006, 1.26), (0.78, 0.02, 0.34), GLASS)

    # 2. parbrizul, inchis, intre stalpii A
    body.beam((0.0, -0.98, 0.90), (0.0, -0.91, ROOF_Z0), (1.14, 0.03), GLASS,
              up=(0.0, 1.0, 0.0))

    # 3-4. botul: cowl galben peste botul negru, ambele ingustate spre fata
    nose_lo = [(-1.20, 0.36, 0.40), (-1.14, 0.46, 0.36), (-1.02, 0.56, 0.34),
               (COWL_BACK_Y, BODY_HW, 0.32)]
    secs = [_sec(y, _rrect(hw, z0, 0.68, 0.06, 0.08, n=2)) for y, hw, z0 in nose_lo]
    _loft(body, secs, BODY)
    #     cowl-ul galben, bombat: sectiunea rotunjita sus, varful coboara spre bot
    cowl = [(-1.15, 0.40, 0.82, 0.08), (-1.10, 0.50, 0.87, 0.12),
            (-1.00, 0.58, 0.90, 0.14), (COWL_BACK_Y, BODY_HW, 0.91, 0.14)]
    secs = [_sec(y, _rrect(hw, 0.68, zt, r, 0.0, n=3)) for y, hw, zt, r in cowl]
    _loft(body, secs, YELLOW)
    # lumini: far central rotund + 2 semnalizatoare
    body.cylinder((0.0, -1.205, 0.58), 0.075, 0.03, YELLOW, segments=10, axis="Y")
    for sx in (-1.0, 1.0):
        body.cylinder((sx * 0.30, -1.20, 0.60), 0.045, 0.03, AMBER, segments=8, axis="Y")

    # 5. aripa si furca rotii din fata
    _arc_band(body, (0.0, FRONT_Y, WHEEL_R), WHEEL_R + 0.04, WHEEL_R + 0.08, 0.20,
              25.0, 150.0, BODY)
    for sx in (-1.0, 1.0):
        body.beam((sx * 0.085, FRONT_Y, WHEEL_R), (sx * 0.085, FRONT_Y + 0.10, 0.52),
                  (0.035, 0.05), BODY)

    # 6. oglinzile pe stalpii A
    for sx in (-1.0, 1.0):
        body.beam((sx * (BODY_HW - 0.02), -0.93, 1.28), (sx * (ROOF_HW + 0.00), -0.95, 1.34),
                  (0.02, 0.02), BODY)
        body.box((sx * (ROOF_HW + 0.005), -0.95, 1.37), (0.02, 0.07, 0.10), BODY)

    # 10. podeaua cabinei, de la cowl la sfertul din spate
    body.box((0.0, (COWL_BACK_Y + CAB_BACK_Y) * 0.5, (0.30 + FLOOR_Z) * 0.5),
             (BODY_HW * 2.0 - 0.06, CAB_BACK_Y - COWL_BACK_Y, FLOOR_Z - 0.30), BODY)

    # 9/11/15. sfertul din spate, jumatatea neagra: peste roti pe toata
    # latimea, iar intre roti coboara pana la podea (rotile raman la vedere)
    _loft(body, [_hsec(z, _plan_rear(hw)) for z, hw in
                 ((0.54, BODY_HW - 0.02), (BELT_Z, BODY_HW))], BODY)
    body.box((0.0, (CAB_BACK_Y + REAR_FACE_Y) * 0.5, (0.30 + 0.54) * 0.5),
             ((REAR_X - 0.10) * 2.0, REAR_FACE_Y - CAB_BACK_Y, 0.24), BODY)
    for sx in (-1.0, 1.0):
        _arc_band(body, (sx * REAR_X, REAR_Y, WHEEL_R), WHEEL_R + 0.03, WHEEL_R + 0.07,
                  0.20, 5.0, 175.0, BODY)

    # 12. stopurile, 13. bara galbena
    for sx in (-1.0, 1.0):
        body.box((sx * 0.44, REAR_FACE_Y + 0.012, 0.72), (0.10, 0.03, 0.16), TAIL)
    body.box((0.0, REAR_FACE_Y + 0.02, 0.40), (0.56, 0.05, 0.08), YELLOW)
    # 14. catadioptrul lateral, pe linia galben/negru
    for sx in (-1.0, 1.0):
        body.box((sx * (BODY_HW + 0.006), 1.02, BELT_Z - 0.04), (0.02, 0.30, 0.05), AMBER)

    # 7. stalpii golului lateral: cel de la mijloc (dupa scaunul soferului)
    for sx in (-1.0, 1.0):
        body.box((sx * (BODY_HW - 0.03), -0.18, (FLOOR_Z + ROOF_Z0) * 0.5),
                 (0.05, 0.05, ROOF_Z0 - FLOOR_Z), BODY)

    # 8. scaunul soferului, ghidonul, bancheta din spate
    body.box((0.0, -0.44, 0.54), (0.44, 0.34, 0.24), BODY)               # soclul
    body.box((0.0, -0.44, 0.71), (0.50, 0.38, 0.10), SEAT)               # perna
    body.box((0.0, -0.26, 0.92), (0.50, 0.08, 0.34), SEAT)               # spatar
    body.beam((0.0, -0.74, 0.82), (0.0, -0.66, 1.04), (0.05, 0.05), METAL)  # coloana
    body.beam((-0.30, -0.64, 1.06), (0.30, -0.64, 1.06), (0.035, 0.035), METAL)
    body.box((0.0, 0.26, 0.55), (BODY_HW * 2.0 - 0.10, 0.44, 0.26), BODY)  # soclul banchetei
    body.box((0.0, 0.26, 0.73), (BODY_HW * 2.0 - 0.14, 0.48, 0.10), SEAT)
    body.box((0.0, CAB_BACK_Y - 0.05, 1.02), (BODY_HW * 2.0 - 0.14, 0.09, 0.46), SEAT)

    body_obj = body.to_object("Tuktuk_Body")
    roof_obj = roof.to_object("Tuktuk_Roof")
    wheels = [
        (_wheel("Wheel_Front", (0.0, FRONT_Y, WHEEL_R), 0.12), (0.0, FRONT_Y, WHEEL_R)),
        (_wheel("Wheel_Rear_L", (REAR_X, REAR_Y, WHEEL_R), 0.14), (REAR_X, REAR_Y, WHEEL_R)),
        (_wheel("Wheel_Rear_R", (-REAR_X, REAR_Y, WHEEL_R), 0.14), (-REAR_X, REAR_Y, WHEEL_R)),
    ]
    return body_obj, roof_obj, wheels


def emit_car(body_objs, wheels, path, budget=None):
    """Ca `emit` din celelalte build-uri Jodhpur (offsetul de origine O DATA pe
    ansamblu), plus pivotul rotilor: dupa finish, fiecare roata isi muta
    originea in centrul osiei (set_origin_at), deci nodul exportat are
    `translation` = centrul osiei si baza identitate."""
    objs = list(body_objs) + [w for w, _ in wheels]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs)))
    total = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        is_wheel = o.name.startswith("Wheel_")
        st = finish(o, bevel=0.0 if is_wheel else 0.015, bevel_angle=30.0,
                    ao=AO_WHEEL if is_wheel else AO_CAR, origin=None,
                    smooth_angle=40.0)
        for v in o.data.vertices:
            v.co += place
        total += st["tris"]
        ao_lo, ao_hi = min(ao_lo, st["ao_min"]), max(ao_hi, st["ao_max"])
    for w, c in wheels:
        set_origin_at(w, Vector(c) + place)
    bpy.context.view_layer.update()
    _, sz = export_glb(objs, "jodhpur/" + path)
    results.append((path, total, sz / 1024.0, ao_lo, ao_hi, budget, place))
    return objs


clear_built()
results = []

tt_body, tt_roof, tt_wheels = build_tuktuk()
tt = emit_car([tt_body, tt_roof], tt_wheels, "vehicles/tuktuk.glb", budget=4000)

print()
for path, tris, kb, ao_lo, ao_hi, budget, place in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f  offset ansamblu (%.3f, %.3f, %.3f)"
          % (path, tris, flag, kb, ao_lo, ao_hi, place.x, place.y, place.z))
for o in tt:
    lo = [min((o.matrix_world @ v.co)[k] for v in o.data.vertices) for k in range(3)]
    hi = [max((o.matrix_world @ v.co)[k] for v in o.data.vertices) for k in range(3)]
    print("  %-14s loc (%.3f, %.3f, %.3f)  X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f"
          % (o.name, o.location.x, o.location.y, o.location.z,
             lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))

save_blend(tt, "jodhpur_vehicles.blend")
