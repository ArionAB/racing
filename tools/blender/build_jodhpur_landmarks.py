"""Jodhpur -- Piesele-reper (brief §1.3, val 2b din docs/asset_briefs/jodhpur_kit.md).

  jodhpur/structures/market_gate.glb              poarta pietei (peste grila de start)
  jodhpur/structures/stepwell_flight_module.glb    modul de trepte al fantanii
  jodhpur/structures/stepwell_corner.glb           colt interior al fantanii
  jodhpur/structures/stepwell_pavilion.glb         galeria de vest a fantanii
  jodhpur/structures/jaswant_thada.glb             cenotaful de marmura

Foloseste vocabularul din `jodhpur_shapes.py` (arch_opening, dome, chhatri,
balustrade, crenellation, solid_stair, stepped_plinth) -- vezi pilotul
(`build_jodhpur_pilot.py`) pentru pattern-ul complet (doi Builder-i, STONE +
GLOW separate, `emit()` cu origine pe ansamblu).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_landmarks.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4).
STONE = ROCK_LIGHT       # gresia fortului/portii -> clasa red_sandstone la integrare
WELL_STONE = SAND_MID    # gresia roz a fantanii -> clasa rose_sandstone
MARBLE = FOAM_WHITE      # marmura cenotafului (alb)
MARBLE_SHADE = MARBLE_GREY  # fetele umbrite ale marmurei
TRIM_WOOD = WOOD         # canaturile de lemn ale portii
GLOW = VOLCANIC_BLACK    # goluri de geam/tinta, ziua inchise
ROCK = ROCK_DARK         # bolovanii de la baza portii


def _finish_or_none(obj):
    """Un Builder GLOW poate ramane gol -- vezi build_jodhpur_pilot.py."""
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


# --- market_gate -----------------------------------------------------------
#
# ESCALADARE OPUS (runda 3; rundele 1-2 respinse: gol dreptunghiular in "T",
# culoare prea inchisa, arc citit ca dreptunghi). Cauzele au fost in
# VOCABULAR, nu in piesa, si s-au reparat acolo (`jodhpur_shapes.py`):
#   - `arch_opening(open=False)` umplea panoul din 4 dreptunghiuri pe
#     bounding-box-ul golului -> timpanele ramaneau goale, silueta golului
#     era dreptunghiulara. Acum panoul e o prisma manifold "dreptunghi minus
#     gol": golul E arcul, pe toata grosimea.
#   - `_arch_profile("pointed")` cu rise < half_w (arcul turtit de aici)
#     iesea in "M". Acum are ramura "drop arch" (centre sub nastere).
#   - masuratoarea golului: `measure_opening` (proiectia triunghiurilor pe
#     planul portii, pe ferestre de inaltime), nu AABB.
#
# LISTA DE ELEMENTE (decuparea market_gate.png, citita inainte de primul
# vertex; vedere aproape frontala, usor din stanga):
#   1. UN panou central de zid intre turnuri, cu UN gol mare in arc ASCUTIT
#      (nasterea la ~3/4 din cheie), deschis pana la sol.
#   2. Arhivolta: banda IN RELIEF pe conturul arcului, coborata pe
#      ambrazuri pana la sol (1 pe fiecare fata).
#   3. Alfiz: cadru dreptunghiular in relief in jurul arcului (2 pilastri +
#      1 banda sus) si 2 medalioane rotunde in timpane.
#   4. 2 canaturi de lemn DESCHISE, cate unul pe fiecare ambrazura, cu tepi
#      de fier (grila 4 x 7 pe fata vizibila).
#   5. Cornisa sub parapet, apoi merloane "kangura" (dreptunghi + umeri
#      rotunjiti + varf), 9 pe decupare, aproape lipite, fiecare cu un punct
#      intunecat. Aici 13 (arcada e 53% din latime, nu 30% -> parapetul se
#      lungeste, abaterea permisa din brief §1.3).
#   6. 2 turnuri patrate cu colturi tesite, cu soclu in 2 trepte si 1 fanta
#      de tragere pe fata.
#   7. Pe fiecare turn: balcon in consola cu parapet jos, apoi chhatri
#      DESCHIS cu 3 arcade pe latura, streasina, cupola pe inel de lotus,
#      finial.
#   8. La ambele capete, contraforti in trepte (o masa inalta lipita de
#      turn + o masa joasa in afara ei) -- silueta se evazeaza la sol.
#   Ce iese din contur: chhatri-urile (cupole + finial) si contrafortii.
#
# LAYOUT (X = latimea, fata spre -Y = spre camera de comparatie, simetric
# fata/spate). Canaturile deschise nu au voie in golul liber de 18,4 m, deci
# stau in afara lui: proiectia unui canat pe planul portii e
# L*sin(a) + t*cos(a), exact cat se vede din fata si exact cat ar ingusta
# golul. Golul fizic dintre ambrazuri e deci 18,4 + 2*2,08 = 22,6 m, iar
# latimea totala iese ~41 m in loc de 34 (turnurile isi pastreaza latimea,
# parapetul se lungeste -- abaterea permisa; inaltimea NU creste).
GATE_TOTAL_W = 34.0
GATE_H = 17.0
GATE_D = 6.0
GATE_GAP_W = 18.4     # golul LIBER (contract >=18.0), cu canaturile incluse
GATE_CROWN_MIN = 11.0  # cheia arcului, contract minim
GATE_CROWN_TARGET = 11.4

MG_LEAF_L = 5.0
MG_LEAF_T = 0.22
MG_LEAF_ANG = 22.0     # canatul fata de ambrazura (grade)
MG_OPEN_HW = GATE_GAP_W * 0.5 + (MG_LEAF_L * math.sin(math.radians(MG_LEAF_ANG))
                                 + MG_LEAF_T * math.cos(math.radians(MG_LEAF_ANG)))
MG_SPRING = 6.2        # nasterea arcului (decupare: ~0,75 din cheie; aici mai jos ca
                       # arcul turtit sa-si pastreze varful)
MG_POINT = 0.38        # varf clar (decupare: arc ascutit, nu segmental)
MG_WALL_T = 5.0
MG_PANEL_HW = MG_OPEN_HW + 1.5
MG_WALL_TOP = 13.0
MG_TOWER_W = 4.4
MG_TOWER_D = 6.0
MG_TOWER_CX = MG_PANEL_HW + MG_TOWER_W * 0.5


def _offset_contour(pts, d):
    """Deplaseaza conturul deschis al golului cu `d` spre EXTERIOR (normala
    stanga a sensului stanga-jos -> dreapta-jos); capetele raman verticale."""
    out = []
    n = len(pts)
    for i in range(n):
        x0, z0 = pts[max(i - 1, 0)]
        x1, z1 = pts[min(i + 1, n - 1)]
        tx, tz = x1 - x0, z1 - z0
        ln = math.hypot(tx, tz) or 1e-6
        nx, nz = -tz / ln, tx / ln
        x, z = pts[i]
        # normala stanga a sensului (urcare pe ambrazura stanga, arc spre
        # dreapta) arata SPRE EXTERIOR; ciorna o scadea si banda intra in gol
        # (masurat: cheia coborase la 11,06 m)
        out.append((x + nx * d, z + nz * d))
    out[0] = (pts[0][0] - d, pts[0][1])
    out[-1] = (pts[-1][0] + d, pts[-1][1])
    return out


def _ring_solid(b, inner, outer, y0, y1, slot):
    """Solid INCHIS (manifold) intre doua contururi deschise corespondente
    unu-la-unu, in planul XZ, extrudat pe Y intre y0 si y1 -- arhivolta."""
    bm = b.bm
    n = len(inner)
    fi = [bm.verts.new((x, y0, z)) for x, z in inner]
    fo = [bm.verts.new((x, y0, z)) for x, z in outer]
    bi = [bm.verts.new((x, y1, z)) for x, z in inner]
    bo = [bm.verts.new((x, y1, z)) for x, z in outer]
    faces = []
    for i in range(n - 1):
        j = i + 1
        faces.append(bm.faces.new((fi[i], fi[j], fo[j], fo[i])))
        faces.append(bm.faces.new((bi[i], bo[i], bo[j], bi[j])))
        faces.append(bm.faces.new((fi[i], bi[i], bi[j], fi[j])))
        faces.append(bm.faces.new((fo[i], fo[j], bo[j], bo[i])))
    faces.append(bm.faces.new((fi[0], fo[0], bo[0], bi[0])))
    faces.append(bm.faces.new((fi[-1], bi[-1], bo[-1], fo[-1])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _prism_z(b, outline_xy, z0, z1, slot, ring_step=None):
    """Prisma verticala dintr-un contur convex in planul XY. `ring_step`
    (m): inele intermediare pe laturi -- AO-ul e copt PE VARF, iar o fata de
    12 m cu varfuri doar sub balcon si la soclu (ambele umbrite) iesea
    intunecata pe toata inaltimea (masurat pe randare: 81,46,23 fata de
    156,94,52 pe panou)."""
    bm = b.bm
    n = len(outline_xy)
    k = max(1, int(math.ceil((z1 - z0) / ring_step))) if ring_step else 1
    rings = [[bm.verts.new((x, y, z0 + (z1 - z0) * r / k)) for x, y in outline_xy]
             for r in range(k + 1)]
    lo, hi = rings[0], rings[-1]
    faces = [bm.faces.new(tuple(reversed(lo))), bm.faces.new(tuple(hi))]
    for ra, rb in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((ra[i], ra[j], rb[j], rb[i])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _chamfer_rect(cx, cy, hw, hd, c):
    """Dreptunghi cu colturile tesite (octogon neregulat), sens trigonometric."""
    return [(cx - hw + c, cy - hd), (cx + hw - c, cy - hd), (cx + hw, cy - hd + c),
            (cx + hw, cy + hd - c), (cx + hw - c, cy + hd), (cx - hw + c, cy + hd),
            (cx - hw, cy + hd - c), (cx - hw, cy - hd + c)]


def _mg_kangura(b, bg, x, y, z, w, h, t, dot_side):
    """Merlon "kangura": dreptunghi + umeri rotunjiti + varf, prisma pe Y,
    cu un punct intunecat (GLOW) pe fata dinspre `dot_side` (-1/+1 pe Y)."""
    hw = w * 0.5
    outline = [(-hw, 0.0), (hw, 0.0), (hw, 0.52 * h), (0.43 * w, 0.70 * h),
               (0.30 * w, 0.83 * h), (0.14 * w, 0.93 * h), (0.0, h),
               (-0.14 * w, 0.93 * h), (-0.30 * w, 0.83 * h), (-0.43 * w, 0.70 * h),
               (-hw, 0.52 * h)]
    b.prism(outline, t, STONE, center=(x, y, z))
    bg.box((x, y + dot_side * (t * 0.5 + 0.01), z + 0.50 * h), (0.28, 0.03, 0.28), GLOW)


def _mg_chhatri(b, cx, cy, z0):
    """Chhatri patrat deschis: pe fiecare latura 3 arcade ascutite -- fiecare
    travee e un `arch_opening(open=False, glass=False)` (panou cu gol real,
    vocabularul reparat), pilonii sunt ambrazurile dintre goluri. Streasina,
    inel de lotus, cupola emisferica, finial. Intoarce cota varfului."""
    side = 3.4
    col_h = 1.55
    t = 0.26
    bays = 3
    bay = side / bays
    hs = side * 0.5
    rot90 = Matrix.Rotation(math.radians(90.0), 3, "Z")
    for i in range(bays):
        u = -hs + bay * (i + 0.5)
        for s in (-1.0, 1.0):
            # laturile fata/spate (planul XZ) si laturile stanga/dreapta
            arch_opening(b, None, (cx + u, cy + s * hs, z0), bay * 0.62, 1.22, 0.72, t,
                         STONE, GLOW, style="pointed", glass=False, steps=6,
                         panel_w=bay, panel_h=col_h)
            arch_opening(b, None, (cx + s * hs, cy + u, z0), bay * 0.62, 1.22, 0.72, t,
                         STONE, GLOW, style="pointed", glass=False, steps=6,
                         panel_w=bay, panel_h=col_h, rotation=rot90)
    # streasina (chajja) + placa
    b.box((cx, cy, z0 + col_h + 0.08), (side + 0.9, side + 0.9, 0.16), STONE)
    b.box((cx, cy, z0 + col_h + 0.21), (side + 0.35, side + 0.35, 0.10), STONE)
    dome_z = z0 + col_h + 0.26
    dome(b, (cx, cy, dome_z), 1.30, STONE, drum_h=0.0, profile="hemisphere",
         segments=12, lotus_ring=True, finial=True, finial_h=0.62)
    return dome_z + 0.12 + 1.30 + 0.62


def build_market_gate():
    b = Builder()
    bg = Builder()
    doorb = Builder()

    hw = MG_OPEN_HW
    yf, yb = -MG_WALL_T * 0.5, MG_WALL_T * 0.5

    # 1. panoul central cu golul in arc -- vocabularul reparat
    arch_opening(b, None, (0.0, 0.0, 0.0), 2.0 * hw, GATE_CROWN_TARGET, MG_SPRING,
                 MG_WALL_T, STONE, GLOW, style="pointed", glass=False, steps=16,
                 panel_w=2.0 * MG_PANEL_HW, panel_h=MG_WALL_TOP, point=MG_POINT)
    hole = arch_hole_contour("pointed", 2.0 * hw, GATE_CROWN_TARGET, MG_SPRING, 16,
                             point=MG_POINT)

    # 2. arhivolta in relief (0,5 m lata, iesita 0,22 m), fata si spate
    band = _offset_contour(hole, 0.5)
    for y0, y1 in ((yf - 0.22, yf), (yb, yb + 0.22)):
        _ring_solid(b, hole, band, y0, y1, STONE)

    # 3. alfiz (2 pilastri + banda sus, iesiti 0,3 m) + medalioane
    # decupare: pilastri lati, banda de sus mult sub cornisa, chiar peste
    # varful arhivoltei
    fr_x0, fr_x1 = hw + 0.6, hw + 1.35
    fr_top0, fr_top1 = MG_WALL_TOP - 1.05, MG_WALL_TOP - 0.5
    for y_c, sy in ((yf - 0.18, -1.0), (yb + 0.18, 1.0)):
        for s in (-1.0, 1.0):
            b.box((s * (fr_x0 + fr_x1) * 0.5, y_c, fr_top1 * 0.5),
                  (fr_x1 - fr_x0, 0.36, fr_top1), STONE)
        b.box((0.0, y_c, (fr_top0 + fr_top1) * 0.5),
              (2.0 * fr_x1, 0.36, fr_top1 - fr_top0), STONE)
        for s in (-1.0, 1.0):
            mx, mz = s * hw * 0.74, fr_top0 - 0.95
            b.cylinder((mx, y_c, mz), 0.62, 0.3, STONE, segments=12, axis="Y")
            b.cylinder((mx, y_c + sy * 0.18, mz), 0.40, 0.08, STONE, segments=12, axis="Y")

    # 5. cornisa + merloane kangura (fata si spate)
    b.box((0.0, 0.0, MG_WALL_TOP - 0.15), (2.0 * MG_PANEL_HW + 0.2, MG_WALL_T + 0.5, 0.3), STONE)
    n_m = 13
    m_w, m_h, m_t = 1.55, 2.0, 0.6
    span = 2.0 * MG_PANEL_HW - 0.4
    for i in range(n_m):
        x = -span * 0.5 + span * (i + 0.5) / n_m
        for yc, ds in ((yf + m_t * 0.5, -1.0), (yb - m_t * 0.5, 1.0)):
            _mg_kangura(b, bg, x, yc, MG_WALL_TOP, m_w, m_h, m_t, ds)

    # 6-7. turnurile
    top_z = 0.0
    for s in (-1.0, 1.0):
        cx = s * MG_TOWER_CX
        thw, thd = MG_TOWER_W * 0.5, MG_TOWER_D * 0.5
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.45, thd + 0.45, 0.9), 0.0, 0.8, STONE)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.22, thd + 0.22, 0.75), 0.8, 1.5, STONE)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw, thd, 0.6), 1.5, 12.2, STONE, ring_step=2.2)
        # brau sub balcon (decupare: linie de umbra sub consola)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.1, thd + 0.1, 0.65), 11.3, 11.55, STONE)
        # fanta de tragere (flush + inchisa -- lectia val 2a), fata si spate
        for sy in (-1.0, 1.0):
            bg.box((cx, sy * (thd + 0.01), 7.8), (0.4, 0.04, 1.5), GLOW)
        # balcon in consola: doua trepte + placa + parapet jos
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.2, thd + 0.2, 0.7), 12.2, 12.6, STONE)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.5, thd + 0.5, 0.85), 12.6, 13.1, STONE)
        bw_, bd_ = thw + 0.42, thd + 0.42
        for (px, py, sx, sy2) in ((cx, -bd_, 2 * bw_, 0.16), (cx, bd_, 2 * bw_, 0.16),
                                  (cx - bw_, 0.0, 0.16, 2 * bd_), (cx + bw_, 0.0, 0.16, 2 * bd_)):
            b.box((px, py, 13.1 + 0.25), (sx, sy2, 0.5), STONE)
        top_z = max(top_z, _mg_chhatri(b, cx, 0.0, 13.1))

    # 8. contrafortii in trepte (prisme cu profil tesit, extrudate pe Y)
    for s in (-1.0, 1.0):
        x_in = MG_TOWER_CX + MG_TOWER_W * 0.5 - 0.3
        tall = [(x_in, 0.0), (x_in + 2.0, 0.0), (x_in + 1.8, 4.4), (x_in + 1.2, 5.9),
                (x_in + 0.4, 6.5), (x_in, 6.5)]
        low = [(x_in + 1.7, 0.0), (x_in + 3.3, 0.0), (x_in + 3.1, 2.6), (x_in + 2.5, 3.5),
               (x_in + 1.7, 3.7)]
        for outline, depth in ((tall, 5.2), (low, 4.4)):
            pts = [(s * x, z) for x, z in outline]
            if s < 0:
                pts = list(reversed(pts))
            b.prism(pts, depth, STONE, center=(0.0, 0.0, 0.0))

    # 4. canaturile deschise, in golul fizic, in afara golului liber
    ang = math.radians(MG_LEAF_ANG)
    leaf_h = MG_SPRING + 0.4
    for s in (-1.0, 1.0):
        hinge = Vector((s * hw, yf + 0.18, 0.0))
        d = Vector((-s * math.sin(ang), math.cos(ang), 0.0))      # in trecere
        nrm = Vector((-s * math.cos(ang), -math.sin(ang), 0.0))   # spre ax/camera
        rot = Matrix(((nrm.x, d.x, 0.0), (nrm.y, d.y, 0.0), (0.0, 0.0, 1.0)))
        c = hinge + d * (MG_LEAF_L * 0.5) + nrm * (MG_LEAF_T * 0.5)
        doorb.box((c.x, c.y, leaf_h * 0.5), (MG_LEAF_T, MG_LEAF_L, leaf_h), TRIM_WOOD,
                  rotation=rot)
        face_c = c + nrm * (MG_LEAF_T * 0.5 + 0.03)
        for zb in (0.18, 0.5, 0.82):
            doorb.box((face_c.x, face_c.y, leaf_h * zb), (0.05, MG_LEAF_L * 0.96, 0.14),
                      GLOW, rotation=rot)
        for ix in range(4):
            for iz in range(7):
                p = face_c + d * ((ix - 1.5) * MG_LEAF_L * 0.22)
                doorb.box((p.x, p.y, leaf_h * (0.10 + 0.12 * iz)), (0.12, 0.16, 0.16),
                          GLOW, rotation=rot)

    densify_for_ao(b, max_len=2.5)
    stone_obj = b.to_object("Gate_Stone")
    door_obj = doorb.to_object("Gate_Doors")
    glow_obj = _finish_or_none(bg.to_object("Gate_Glow"))
    print("market_gate: varf chhatri z=%.2f m" % top_z)
    return stone_obj, door_obj, glow_obj, GATE_CROWN_TARGET


# --- stepwell_flight_module --------------------------------------------------
#
# Contract (brief §1.3): 12 m lat x 3 m inalt x 2,5 m adanc. Lista de
# elemente (decupare stepwell_flight_module.png): un perete lung, jos, cu
# TREI V-uri de trepte inversate taiate in profilul de sus -- fiecare V are
# un varf inalt (la 4 m distanta) si coboara pe ambele parti spre un punct
# jos intre V-uri consecutive. Rosturile de caramida sunt textura (nu
# geometrie -- regula 0.5); TREPTELE insele sunt geometrie (0,3 m pe treapta,
# brief regula 5). Capete PLANE la x=+-6, ca sa se inlantuie cu alt modul.
WELL_MOD_W = 12.0
WELL_MOD_H = 3.0
WELL_MOD_D = 2.5
WELL_STEP_H = 0.3


def _flight_steps(b, apex_x, base_x_left, base_x_right, apex_z, base_z,
                  wall_front_y, projection, slot):
    """Un singur V de trepte, de la baza (stanga, joasa) urcand spre varf
    (centru, inalt) si coborand la baza (dreapta, joasa).

    REVIZUIRE runda 2 (sef, FAIL): prima versiune facea fiecare treapta o
    cutie care se intindea pe TOATA adancimea modulului (`depth=WELL_MOD_D=
    2,5 m`) -- vazute din fata, ele citeau ca ARIPIOARE/COASTE perpendiculare
    pe perete, tepi care ies spre camera, nu ca trepte incrustate in fata
    zidului. Cerinta corecta (crop): un zid SOLID (fundal plin, pe toata
    adancimea, construit separat in `build_stepwell_flight_module`), iar pe
    FATA lui (+Y), treptele proiecteaza doar 0,3-0,6 m -- geometrie MICA,
    suprapusa pe suprafata zidului, nu structura care strapunge zidul.

    `wall_front_y`: coordonata Y a fetei din fata a zidului plin (treptele
    proiecteaza spre +Y de acolo). `projection`: cat ies treptele din fata
    zidului (0,3-0,6 m, creste usor cu inaltimea ca sa se vada palierele)."""
    faces = []
    half_run_l = apex_x - base_x_left
    half_run_r = base_x_right - apex_x
    n_l = max(int(round((apex_z - base_z) / WELL_STEP_H)), 1)
    n_r = max(int(round((apex_z - base_z) / WELL_STEP_H)), 1)
    step_t = WELL_STEP_H * 0.92  # grosimea verticala a fiecarei trepte (usor sub rise, ca sa se vada muchia)
    # panta stanga: urca de la base_x_left (jos) spre apex_x (sus)
    for k in range(n_l):
        x0 = base_x_left + half_run_l * (k / n_l)
        x1 = base_x_left + half_run_l * ((k + 1) / n_l)
        z_top = base_z + (apex_z - base_z) * ((k + 1) / n_l)
        proj = projection
        faces += list(b.box(((x0 + x1) * 0.5, wall_front_y + proj * 0.5, z_top - step_t * 0.5),
                            (x1 - x0 + 0.02, proj, step_t), slot))
    # panta dreapta: coboara de la apex_x (sus) spre base_x_right (jos)
    for k in range(n_r):
        x0 = apex_x + half_run_r * (k / n_r)
        x1 = apex_x + half_run_r * ((k + 1) / n_r)
        z_top = base_z + (apex_z - base_z) * (1.0 - k / n_r)
        proj = projection
        faces += list(b.box(((x0 + x1) * 0.5, wall_front_y + proj * 0.5, z_top - step_t * 0.5),
                            (x1 - x0 + 0.02, proj, step_t), slot))
    return faces


def build_stepwell_flight_module():
    """REVIZUIRE runda 2 (sef, FAIL -- "fins sticking out perpendicular to
    the wall"): rescris complet. Acum e un zid SOLID (12x3x2,5 m, plin pe
    toata adancimea) cu treptele ca RELIEF PROIECTAT pe fata din fata
    (+Y), nu structuri care strapung tot zidul."""
    b = Builder()
    stone_faces = []
    hw = WELL_MOD_W * 0.5
    hd = WELL_MOD_D * 0.5

    # trei V-uri pe 12 m -> 4 m per V. Varfurile la x = -4, 0, +4; punctele
    # joase (intre V-uri si la capete) la x = -6, -2, +2, +6.
    apexes = [-4.0, 0.0, 4.0]
    lows = [-6.0, -2.0, 2.0, 6.0]
    low_z = WELL_STEP_H * 1.0     # baza joasa, nu chiar 0 -- prag mic de soclu
    apex_z = WELL_MOD_H

    # zidul SOLID de fundal, pe toata amprenta (12 x 2,5 x 3 m) -- masa
    # plina care sustine reliefului treptelor, NU doar o placa subtire de
    # soclu. Fata din fata e la y=+hd; treptele proiecteaza de acolo spre +Y.
    stone_faces += list(b.box((0.0, 0.0, WELL_MOD_H * 0.5),
                              (WELL_MOD_W, WELL_MOD_D, WELL_MOD_H), WELL_STONE))

    wall_front_y = hd
    for i, apex_x in enumerate(apexes):
        base_l = lows[i]
        base_r = lows[i + 1]
        stone_faces += _flight_steps(b, apex_x, base_l, base_r, apex_z, low_z,
                                     wall_front_y, 0.45, WELL_STONE)

    # capete plane la x=+-6, ca sa se inlantuie -- deja acoperite de zidul
    # solid (fata plana pe toata inaltimea), coping (banda usor iesita) pe
    # muchia de sus, pe toata lungimea.
    stone_faces += list(b.box((0.0, 0.0, WELL_MOD_H + 0.06),
                              (WELL_MOD_W + 0.2, WELL_MOD_D + 0.1, 0.12), WELL_STONE))

    stone_obj = b.to_object("Well_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = WELL_STONE
    return stone_obj


# --- stepwell_corner ----------------------------------------------------------
#
# Contract (brief §1.3): 6x6x3 m. Lista de elemente (decupare
# stepwell_corner.png): colt INTERIOR in forma de L -- doua ziduri (fetele
# exterioare) care se intalnesc in unghi de 90 de grade; pe fiecare zid, un
# flux de trepte coboara spre INTERIOR, cele doua fluxuri se intalnesc in
# coltul interior (varful in colt, baza la capetele exterioare ale celor doua
# ziduri). Coronament plat (coping) pe muchia de sus a zidurilor.
WELL_CORNER_SIZE = 6.0


def build_stepwell_corner():
    b = Builder()
    stone_faces = []
    s = WELL_CORNER_SIZE
    apex_z = WELL_MOD_H
    low_z = WELL_STEP_H

    # colt interior la (0,0); ziduri de-a lungul +X (fata la y=0, plan XZ) si
    # +Y (fata la x=0, plan YZ). Pe decupare, cele doua scari coboara DINSPRE
    # colturile exterioare (sus, la marginea zidului) SPRE coltul interior
    # (jos) -- apex (inalt) la capatul exterior, baza (joasa) in colt.
    #
    # brat pe X: de la coltul interior (x=0, jos=low_z) urcand spre x=s
    # (capatul exterior, sus=apex_z). REVIZUIRE runda 2 (sef, "close, accept
    # cu o corectie"): explicit 10 trepte pe flux (nu doar rotunjire din
    # apex_z/WELL_STEP_H, care da 9) -- rise-ul per treapta scade usor
    # (0,27 m in loc de 0,3 m) ca sa incapa exact 10 in cei 2,7 m de urcare.
    n = 10
    for k in range(n):
        x0 = s * (k / n)
        x1 = s * ((k + 1) / n)
        z_top = low_z + (apex_z - low_z) * ((k + 1) / n)
        stone_faces += list(b.box(((x0 + x1) * 0.5, WELL_MOD_D * 0.5, (low_z + z_top) * 0.5),
                                  (x1 - x0 + 0.02, WELL_MOD_D, z_top - low_z), WELL_STONE))
    # brat pe Y: de la coltul interior (y=0, jos) urcand spre y=s (capat, sus)
    for k in range(n):
        y0 = s * (k / n)
        y1 = s * ((k + 1) / n)
        z_top = low_z + (apex_z - low_z) * ((k + 1) / n)
        stone_faces += list(b.box((WELL_MOD_D * 0.5, (y0 + y1) * 0.5, (low_z + z_top) * 0.5),
                                  (WELL_MOD_D, y1 - y0 + 0.02, z_top - low_z), WELL_STONE))
    # zid de fundal (exterior), sustine ambele brate -- doua placi in L,
    # pe toata inaltimea modulului, coronament plat pe muchia de sus.
    stone_faces += list(b.box((s * 0.5, s - 0.15, WELL_MOD_H * 0.5),
                              (s, 0.30, WELL_MOD_H), WELL_STONE))
    stone_faces += list(b.box((s - 0.15, s * 0.5, WELL_MOD_H * 0.5),
                              (0.30, s, WELL_MOD_H), WELL_STONE))
    # coping (banda subtire pe muchia de sus a fiecarui zid)
    stone_faces += list(b.box((s * 0.5, s - 0.15, WELL_MOD_H + 0.06),
                              (s + 0.3, 0.34, 0.12), WELL_STONE))
    stone_faces += list(b.box((s - 0.15, s * 0.5, WELL_MOD_H + 0.06),
                              (0.34, s + 0.3, 0.12), WELL_STONE))

    stone_obj = b.to_object("Well_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = WELL_STONE

    # REVIZUIRE: dupa `finish(origin="base")`, piesa se centreaza pe bbox --
    # zidurile (construite langa x=s/y=s) ajung pe partea +X/+Y, exact spre
    # camera `_neutral_shot` (azimut 35), care le arata ca doua fete PLINE,
    # blocand complet vederea spre interiorul in trepte (colt-ul, la x=y=0
    # inainte de centrare, ajunge pe partea -X/-Y, cu spatele la camera --
    # verificat vizual: prima randare arata doar doi pereti plini, FARA nicio
    # treapta). Fix: rotim 180° in jurul lui Z, ca interiorul deschis (unde
    # coboara treptele) sa ajunga cu fata spre camera.
    for v in stone_obj.data.vertices:
        v.co.x, v.co.y = -v.co.x, -v.co.y
    return stone_obj


# --- stepwell_pavilion ---------------------------------------------------------
#
# Contract (brief §1.3): 20x6 m, 2 etaje, 9 m + cupola centrala pana la 12 m.
#
# REVIZUIRE runda 2 (sef, FAIL -- "floating arches with no walls and a cube
# underneath: parts are detached"): lista de elemente RE-scrisa dupa o
# recitire atenta a decuparii (nu doar din memorie) -- pe crop e o cladire
# CONTINUA, cu UN singur etaj pe aripi (nu doua, cum presupusesem prima
# data):
#   1. Zid SOLID de fundal, plin, pe toata lungimea (20 m), jos (~1,5-2 m).
#   2. Podea/soclu la baza.
#   3. Aripi cu UN singur etaj: colonada de 4 arce ROTUNJITE pe coloane pe
#      fiecare parte, coloanele ating podeaua SI sustin acoperisul (nimic nu
#      pluteste).
#   4. Acoperis PLAT peste toata lungimea (aripi + centru), cu cornisa care
#      iese si un parapet scund pe muchie.
#   5. Chhatri mici la cele DOUA capete exterioare ale acoperisului.
#   6. Pavilion central, PROIECTAT in fata (+Y), pe DOUA etaje: parter cu
#      arc(uri) de intrare, etaj cu balcon (2 arce) intre soclu si cupola,
#      banda de balcon, chajja.
#   7. Cupola MARE nervurata pe tambur, cu finial, deasupra pavilionului
#      central.
# Simetric stanga-dreapta fata de centru.
WELL_PAV_W = 20.0
WELL_PAV_D = 6.0
WELL_PAV_H = 9.0
WELL_PAV_DOME_TOP = 12.0


def build_stepwell_pavilion():
    b = Builder()
    bg = Builder()
    stone_faces = []
    hw = WELL_PAV_W * 0.5

    # REVIZUIRE runda 2 (a doua trecere): fatada (verificata cu testul de
    # fete colorate) e pe +Y -- zidul de fundal trebuie sa stea in SPATE
    # (Y NEGATIV, departe de camera), iar arcada in FATA (Y catre +), altfel
    # zidul plin acopera complet arcada din vederea frontala (exact ce s-a
    # vazut: aripile ieseau ca pereti plini fara nicio arcada vizibila).
    wing_h = WELL_PAV_H * 0.62          # inaltimea aripilor (UN etaj, pana la cornisa)
    col_r = 0.28
    wall_y = -(WELL_PAV_D * 0.5 - 0.3)  # zidul de fundal, aproape de muchia din SPATE (-Y)
    col_y = WELL_PAV_D * 0.5 - col_r * 2  # coloanele arcadei, aproape de muchia din FATA (+Y)

    # 1. zid SOLID de fundal -- plin, pe toata lungimea, de la podea pana la
    # nivelul acoperisului (asta e ce "prinde" arcele -- fara el, coloanele
    # ar sta izolate in aer, exact defectul semnalat).
    stone_faces += list(b.box((0.0, wall_y, wing_h * 0.5),
                              (WELL_PAV_W, 0.35, wing_h), WELL_STONE))

    # 2. podea/soclu la baza, pe toata amprenta (aripi + iesirea centrala)
    slab_h = 0.25
    stone_faces += list(b.box((0.0, 0.0, -slab_h * 0.5), (WELL_PAV_W, WELL_PAV_D, slab_h), WELL_STONE))

    # 3. aripile: colonada de 4 arce rotunjite PE FIECARE parte, intre
    # capatul exterior si pavilionul central -- coloanele ating podeaua
    # (base_z=0) si urca pana la wing_h, unde le prinde cornisa/acoperisul.
    central_half_w = 3.2   # jumatate din latimea ocupata de pavilionul central pe fatada
    n_bays_wing = 4
    for side in (-1.0, 1.0):
        wing_x0 = side * central_half_w
        wing_x1 = side * hw
        res = arcade(b, bg, (wing_x0, col_y, 0.0), (wing_x1, col_y, 0.0), n_bays_wing,
                    wing_h * 0.78, wing_h * 0.10, col_r * 2, 0.55, WELL_STONE, GLOW,
                    style="round", glass=False, base_z=0.0)
        stone_faces += res["stone"]
        # coloanele arcadei (`arcade` foloseste `pier_w`=col_r*2 ca stalpi
        # dreptunghiulari intre arce) ajung la wing_h prin propriul
        # `opening_h+pier_h` -- verificam explicit ca acopera toata
        # inaltimea aripii pana la acoperis (arcada e construita sa
        # opening_h*1 + pier_h_frac*wing_h = wing_h aproximativ; ramane un
        # mic decalaj acoperit de cornisa de mai jos).

    # 4. acoperis PLAT peste toata lungimea (aripi + centru), cu cornisa
    # care iese, sprijinit DIRECT pe coloanele aripilor si pe zidul de
    # fundal -- nu o placa separata plutind deasupra.
    roof_z0 = wing_h
    roof_h = 0.22
    stone_faces += list(b.box((0.0, 0.0, roof_z0 + roof_h * 0.5), (WELL_PAV_W, WELL_PAV_D, roof_h), WELL_STONE))
    # cornisa proeminenta pe muchia frontala a acoperisului (chajja lunga)
    stone_faces += list(chajja(b, (0.0, WELL_PAV_D * 0.5, roof_z0 + roof_h), WELL_PAV_W, 0.5,
                               WELL_STONE, thickness=0.12, slope=0.4))
    # parapet scund pe acoperis
    stone_faces += list(balustrade(b, (-hw + 0.3, 0.0, roof_z0 + roof_h),
                                   (hw - 0.3, 0.0, roof_z0 + roof_h),
                                   0.45, WELL_STONE, merlon_w=0.18, merlon_gap=0.14))

    # 5. chhatri mici la cele DOUA capete exterioare ale acoperisului.
    for side in (-1.0, 1.0):
        cx = side * (hw - 0.6)
        res_ch = chhatri(b, bg, (cx, 0.0, roof_z0 + roof_h), 6, 0.55, 1.1,
                         WELL_STONE, GLOW, col_r=0.09, dome_radius=0.42,
                         arch_style="round", chajja_out=0.18, segments_dome=10)
        stone_faces += res_ch["stone"]

    # 6. pavilion central, PROIECTAT in fata (+Y), doua etaje -- corp SOLID
    # (nu doar coloane) care se conecteaza direct la zidul de fundal comun.
    cw = central_half_w * 2.0
    cy = 0.9   # iese in fata cu 0,9 m peste linia coloanelor aripilor
    floor1_h = WELL_PAV_H * 0.42
    stone_faces += list(b.box((0.0, cy * 0.5, floor1_h * 0.5),
                              (cw, WELL_PAV_D + cy, floor1_h), WELL_STONE))
    # arc de intrare la parter, pe fata din fata a pavilionului central
    res_door = arch_opening(b, bg, (0.0, cy + WELL_PAV_D * 0.5 - 0.05, 0.0), cw * 0.45, floor1_h * 0.92,
                            floor1_h * 0.5, 0.5, WELL_STONE, GLOW, style="round",
                            glass=True, panel_w=cw, panel_h=floor1_h)
    stone_faces += res_door["stone"]

    # balcon la etaj (banda + balustrada pe console) -- se sprijina pe
    # corpul parterului, nu pluteste.
    bal_z = floor1_h
    stone_faces += list(balcony_band(b, (0.0, cy * 0.5, bal_z), cw * 0.5 - 0.2, cw * 0.5 + 0.30,
                                     0.14, WELL_STONE, segments=12))
    stone_faces += list(balustrade(b, (-cw * 0.5 + 0.35, cy + WELL_PAV_D * 0.5 + 0.05, bal_z + 0.14),
                                   (cw * 0.5 - 0.35, cy + WELL_PAV_D * 0.5 + 0.05, bal_z + 0.14),
                                   0.5, WELL_STONE, merlon_w=0.16, merlon_gap=0.12))

    # etaj 2 al pavilionului central: 2 arce pe fatada (colonada deschisa cu
    # chajja), care se leaga in corpul zidului central, nu pluteste separat.
    upper_h = roof_z0 - bal_z - 0.14
    upper_z0 = bal_z + 0.14
    stone_faces += list(b.box((0.0, cy * 0.5, upper_z0 + upper_h * 0.5),
                              (cw, WELL_PAV_D + cy, upper_h), WELL_STONE))
    n_bays_upper = 2
    res_upper = arcade(b, bg, (-cw * 0.5 + 0.3, cy + WELL_PAV_D * 0.5 - 0.02, upper_z0),
                       (cw * 0.5 - 0.3, cy + WELL_PAV_D * 0.5 - 0.02, upper_z0),
                       n_bays_upper, upper_h * 0.75, upper_h * 0.15, 0.30, 0.5,
                       WELL_STONE, GLOW, style="round", glass=True, base_z=upper_z0)
    stone_faces += res_upper["stone"]
    dome_base_z = roof_z0 + 0.30
    stone_faces += list(chajja(b, (0.0, cy + WELL_PAV_D * 0.5, dome_base_z - 0.05), cw + 0.6, 0.4,
                               WELL_STONE, thickness=0.12, slope=0.4))

    # 7. cupola MARE nervurata pe tambur, cu finial, pana la 12 m total.
    remaining = WELL_PAV_DOME_TOP - dome_base_z
    drum_h = remaining * 0.26
    finial_h = remaining * 0.18
    dome_r = remaining - drum_h - finial_h - 0.12
    stone_faces += dome(b, (0.0, cy * 0.5, dome_base_z), dome_r, WELL_STONE, drum_h=drum_h,
                        drum_r=cw * 0.30, profile="hemisphere", segments=16, ribs=12,
                        lotus_ring=True, finial=True, finial_h=finial_h)

    stone_obj = b.to_object("Well_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = WELL_STONE
    glow_obj = _finish_or_none(bg.to_object("Well_Glow"))
    return stone_obj, glow_obj


# --- jaswant_thada ---------------------------------------------------------------
#
# Contract (brief §1.3): 30x20 m amprenta (cu scarile), 14 m inalt. Lista de
# elemente (decupare jaswant_thada.png), de jos in sus / centru spre colturi:
#   1. Soclu in TREPTE (podium), cu scara CENTRALA LATA care urca in fata
#      (spre camera).
#   2. Corpul central: pavilion DESCHIS pe coloane (arce vizibile, interior
#      intunecat), cu o cupola MARE bulboasa/nervurata pe tambur, finial in
#      varf.
#   3. 4 chhatri MICI la colturi (2 stanga, 2 dreapta, la distante diferite
#      fata de centru -- pe decupare par pe DOUA randuri de distanta: unul
#      mai aproape si mai mic langa centru, unul mai indepartat), fiecare pe
#      soclul lui propriu mic.
# Totul MARMURA alba (FOAM_WHITE), cu fetele umbrite / dedesubturile pe
# MARBLE_GREY.
THADA_W = 30.0
THADA_D = 20.0
THADA_H = 14.0


def build_jaswant_thada():
    b = Builder()
    bg = Builder()
    stone_faces = []

    # 1. soclu in trepte -- doua nivele, cel de sus mai ingust, urmat de
    # scara centrala lata care urca pe fata +Y (spre camera).
    plinth_levels = [(THADA_W * 0.72, THADA_D * 0.72, 0.9),
                     (THADA_W * 0.5, THADA_D * 0.5, 0.7)]
    stone_faces += list(stepped_plinth(b, (0.0, 0.0, 0.0), plinth_levels, MARBLE))
    plinth_h = sum(lvl[-1] for lvl in plinth_levels)
    plinth2_hw = THADA_W * 0.25
    plinth2_hd = THADA_D * 0.25

    # REVIZUIRE runda 2 (sef: "stair is odd"): `stair_start` avea Y=8,2 m,
    # dincolo de marginea soclului de jos (jumatate din THADA_D*0,72=7,2 m)
    # -- scara incepea in aer, dincolo de conturul soclului, nu chiar pe
    # muchia lui. Fix: porneste exact la marginea soclului INFERIOR (nivel
    # 1, cel mai lat), la z=0.
    plinth1_hd = THADA_D * 0.72 * 0.5
    stair_w = THADA_W * 0.22
    stair_start = (0.0, plinth1_hd, 0.0)
    stair_end = (0.0, plinth2_hd - 0.1, plinth_h)
    stone_faces += list(solid_stair(b, stair_start, stair_end, stair_w, MARBLE_SHADE,
                                    tread_slot=MARBLE, nosing=False, cheek=True,
                                    cheek_slot=MARBLE_SHADE, step_h=0.24))

    # 2. corp central deschis: coloane + arce + cupola mare
    body_r = min(THADA_W, THADA_D) * 0.20
    body_col_h = THADA_H * 0.38
    res_body = chhatri(b, bg, (0.0, 0.0, plinth_h), 10, body_r, body_col_h,
                       MARBLE, GLOW, col_r=0.22, dome_radius=body_r * 0.72,
                       arch_style="round", chajja_out=0.55, segments_dome=16)
    stone_faces += res_body["stone"]
    dome_base_z = plinth_h + body_col_h + 0.55  # +chajja/plafon din chhatri

    remaining = THADA_H - dome_base_z
    drum_h = remaining * 0.22
    finial_h = min(remaining * 0.16, THADA_H * 0.10)
    dome_r = remaining - drum_h - finial_h - 0.12
    stone_faces += dome(b, (0.0, 0.0, dome_base_z), dome_r, MARBLE, drum_h=drum_h,
                        drum_r=body_r * 0.55, profile="hemisphere", segments=18,
                        ribs=14, lotus_ring=True, finial=True, finial_h=finial_h)

    # 3. 4 chhatri la colturi -- REVIZUIRE runda 2 (sef, FAIL pe compozitie):
    # dupa recitirea decuparii, layout-ul REAL e:
    #   - 2 chhatri MEDII, LIPITE de corpul central, stanga si dreapta,
    #     usor in spate (nu la marginile amprentei) -- domul lor ajunge
    #     cam la 45-50% din inaltimea cupolei centrale.
    #   - 2 chhatri MICI, la colturile EXTERIOARE din FATA, pe soclul de
    #     jos (nu la aceeasi adancime ca cele medii) -- domul lor ajunge
    #     la ~30% din cupola centrala.
    # Runda 1 le pusese pe toate 4 pe acelasi rand, la distante mici intre
    # ele -- citeau "imprastiate" (scattered), nu grupate ca pe decupare.
    med_r = 2.0
    small_r = 1.2
    chhatri_specs = [
        (-THADA_W * 0.20, -THADA_D * 0.02, med_r, THADA_H * 0.44),    # mediu, stanga, langa centru
        (THADA_W * 0.20, -THADA_D * 0.02, med_r, THADA_H * 0.44),     # mediu, dreapta, langa centru
        (-THADA_W * 0.42, THADA_D * 0.16, small_r, THADA_H * 0.30),   # mic, colt exterior stanga-fata
        (THADA_W * 0.42, THADA_D * 0.16, small_r, THADA_H * 0.30),    # mic, colt exterior dreapta-fata
    ]
    for cx, cy, r, total_h in chhatri_specs:
        plinth_r = r * 1.5
        plinth_h2 = 0.5
        stone_faces += list(b.box((cx, cy, plinth_h2 * 0.5), (plinth_r * 2, plinth_r * 2, plinth_h2), MARBLE_SHADE))
        col_h_c = max(total_h - plinth_h2 - r * 1.6, 0.5)  # total_h minus soclu si overhead cupola (masurat ~r*1,6 la r mic)
        res_c = chhatri(b, bg, (cx, cy, plinth_h2), 8, r, col_h_c,
                        MARBLE, GLOW, col_r=0.10 * (r / small_r), dome_radius=r * 0.6,
                        arch_style="round", chajja_out=0.24, segments_dome=12)
        stone_faces += res_c["stone"]

    stone_obj = b.to_object("Thada_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = MARBLE
    glow_obj = _finish_or_none(bg.to_object("Thada_Glow"))
    return stone_obj, glow_obj


# --- emit ------------------------------------------------------------------

clear_built()
results = []


_emitted_objs = []  # toate obiectele exportate pana acum (pentru save_blend la final)


def _dename(name):
    """Strip sufixul Blender de coliziune de nume (`.001`, `.002`, ...)."""
    import re
    return re.sub(r"\.\d{3}$", "", name)


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Ca `emit` din build_jodhpur_pilot.py: offsetul de origine se
    calculeaza O DATA pe ansamblu si se aplica identic tuturor nodurilor.

    REVIZUIRE: mai multe piese din acest fisier refolosesc acelasi nume de
    nod intre ele (`Well_Stone` la toate cele 3 piese de fantana) -- Blender
    dezambiguizeaza automat in scena (`Well_Stone.001`, `.002`, ...), iar
    fara fix GLB-ul exportat avea nodul numit LITERAL "Well_Stone.002"
    (masurat cu verify_glb.py). Fiecare GLB e independent, deci contractul
    de nume per-piesa (brief §1.3) trebuie curat in FIECARE fisier. Fix: dupa
    export, obiectele deja exportate sunt REDENUMITE cu un prefix unic
    (`path`-ul lor), eliberand numele de baza pentru piesa urmatoare care-l
    cere din nou -- `save_blend` de la final nu depinde de nume, doar de
    identitatea obiectelor (pastrate in `_emitted_objs`)."""
    objs = [o for o in objs if o is not None]
    for o in objs:
        o.name = _dename(o.name)
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=(origin if solo else None), smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "jodhpur/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    _emitted_objs.extend(objs)
    # elibereaza numele de baza (Well_Stone etc.) pentru piesa URMATOARE --
    # vezi docstring-ul de mai sus. Prefixul e unic per `path`, deci nu
    # coliziune intre piesele deja exportate.
    tag = path.rsplit("/", 1)[-1].replace(".glb", "")
    for o in objs:
        o.name = "_exported_%s_%s" % (tag, o.name)
    return total_tris


AO_GATE = dict(samples=24, dist=6.0, gradient="vertical",
              low=0.42, high=1.00, power=0.85, floor=0.16)
AO_WELL = dict(samples=20, dist=4.0, gradient="vertical",
              low=0.46, high=1.00, power=0.88, floor=0.18)
AO_THADA = dict(samples=22, dist=5.0, gradient="vertical",
                low=0.50, high=1.00, power=0.85, floor=0.22)

gate_stone, gate_doors, gate_glow, gate_crown_z = build_market_gate()
emit([gate_stone, gate_doors, gate_glow], "structures/market_gate.glb",
     AO_GATE, origin="assembly", bevel=0.03, budget=21500)  # escaladare Opus: 21048 masurat -- panou manifold cu gol real, chhatri din 24 de arcade, densify_for_ao (~4400) ca AO-ul sa nu innegreasca fetele de 12 m
_mg_gaps, _mg_crown = measure_opening([gate_stone, gate_doors, gate_glow])
print("MASURATOARE market_gate (proiectie pe planul portii, toate nodurile, dupa emit):")
for (_z0, _z1), _g in sorted(_mg_gaps.items()):
    print("  gol liber y=%.2f..%.2f m: %.2f m  (contract >= 18.0)" % (_z0, _z1, _g))
print("  cheia arcului (|x|<=0,3 m): %.2f m  (contract >= 11.0)" % _mg_crown)

well_flight = build_stepwell_flight_module()
emit([well_flight], "structures/stepwell_flight_module.glb", AO_WELL,
     origin="base", bevel=0.02, budget=3600)

well_corner = build_stepwell_corner()
emit([well_corner], "structures/stepwell_corner.glb", AO_WELL,
     origin="base", bevel=0.02, budget=2400)

well_pav_stone, well_pav_glow = build_stepwell_pavilion()
emit([well_pav_stone, well_pav_glow], "structures/stepwell_pavilion.glb", AO_WELL,
     origin="assembly", bevel=0.025, budget=12000)  # runda 2: rescris complet (zid solid + aripi 1 etaj + acoperis + pavilion central 2 etaje), 11201 masurat

thada_stone, thada_glow = build_jaswant_thada()
emit([thada_stone, thada_glow], "structures/jaswant_thada.glb", AO_THADA,
     origin="assembly", bevel=0.025, budget=15000)  # 14552 masurat: corp central + cupola mare nervurata + 4 chhatri de colt

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-46s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL reperele: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (gate_stone, gate_doors, gate_glow, well_flight, well_corner,
                        well_pav_stone, well_pav_glow, thada_stone, thada_glow)
           if o is not None], "jodhpur_landmarks.blend")
