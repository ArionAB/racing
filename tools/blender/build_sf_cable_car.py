"""cable_car.glb — vagonul de tramvai cu cablu, pista San Francisco (Track25).

  CableCar_Body   sanfrancisco/vehicles/cable_car.glb   2.50 x 3.20 x 8.50 m

Contract: docs/asset_briefs/sf_cable_car.md §1-§9. Referinta de culoare si
caracter: docs/track_briefs/img/sf_assets_v1/cable_car.png (decuparea din
plansa). Unde decuparea si brief-ul nu se potrivesc pe STRUCTURA sau COTE,
castiga brief-ul: capete deschise cu banci longitudinale spre exterior, cabina
inchisa la mijloc, calatori pe scari IN gabarit, fara text/numere/sigle.

Axe (Blender): X = latimea (dreapta +X), Y = lungimea, FATA pe +Y (devine -Z
in Godot: exportatorul face (x, y, z) -> (x, z, -y)), Z = sus, roti la z = 0.

ELEMENTE (lista de acceptare, una cate una; cotele in m):
 1. Doua boghiuri scunde la 1,6 m de capete (y = +-2,65): cadru volcanic_black,
    cate 4 roti octogonale (8 laturi) de diametru 0,6, de la z = 0 la 0,6, cu un
    varf al octogonului jos (roata atinge planul z = 0 la ambele boghiuri).
 2. Fusta caroseriei kerb_red, z 0,25 -> 0,70, corp +-1,0, capetele platformei
    tesite in plan (fata rotunjita a vagoanelor vechi); rotile ies sub ea.
 3. Podeaua (puntea) log_dark la +0,76, pe toata lungimea.
 4. Scarile laterale (running boards) log_dark pe toata lungimea, la +0,45,
    de la x = 1,0 la 1,25 (marginea gabaritului), pe console volcanic_black.
 5. Capatul deschis din FATA (y 1,65 -> 4,25): fara pereti laterali; banca
    longitudinala spate-in-spate pe axa (spatar central + doua sezuturi spre
    exterior, log_dark) cu bara de alama rust_metal pe spatar; stalpi la colt
    si la mijloc (0,11 m, coral_sand ca in decupare); grinda de streasina.
 6. Capatul deschis din SPATE (y -1,65 -> -4,25), identic ca structura.
 7. Parapetul jos de 0,5 m la fiecare capat (kerb_red, mana curenta de alama
    rust_metal), urmand conturul tesit al platformei.
 8. Farul rotund la fata si al doilea far la spate (foam_white in carcasa
    rust_metal), plus tampon log_dark sub parapet.
 9. Cabina inchisa din mijloc (y +-1,65): perete de jos kerb_red cu panouri in
    relief, brau coral_sand, zona de ferestre coral_sand, tablia de sus
    (letter board) coral_sand.
10. Cate 3 ferestre pe fiecare parte, golul adancit 0,08 m (geam
    volcanic_black retras, nu gaura), cu capetele arcuite (coltare in arc).
11. Usa dubla pe fiecare parte a cabinei: rama coral_sand cu montant central,
    geamuri sus, foi kerb_red jos.
12. Peretii de capat ai cabinei (spre platforme): doua ferestre arcuite.
13. Acoperisul kerb_red de la +2,75, streasina +-1,05 peste capetele deschise,
    fascia coral_sand, capetele curbate in jos si rotunjite in plan (bombate).
14. Lanternoul (clerestory) ingust pe mijloc pana la +3,20: pereti coral_sand
    cu sir de ferestruici volcanic_black, capac kerb_red, capete inclinate.
15. Dreptunghiul de destinatie GOL (foam_white) pe grinda de capat, fata si
    spate. Fara text.
16. Clopotul rust_metal (diametru 0,25) pe acoperisul capatului din FATA.
17. Manerul de prindere (grip): parghie inalta de 1,2 m in capatul din fata,
    langa ax, pe o placa volcanic_black, cu maner de alama; langa ea o a doua
    parghie (frana), mai scurta.
18. 8 calatori in picioare pe scari (2 per capat per parte), lipiti de corp,
    inclinati spre interior, cu o mana pe stalp: figurine de jucarie (picioare,
    corp-capsula, cap-sfera cu 8 laturi, par/sapca), ~1,7 m.
19. 4 calatori asezati pe bancile exterioare (2 in fata, 2 in spate).
20. AO copt in COLOR_0: gradient vertical 0,6 -> 1,0 + ocluzie reala (sub
    streasina, sub banci, golurile ferestrelor, intre boghiuri).

Sloturi (doar cele din brief §5): kerb_red 7, coral_sand 19, log_dark 28,
volcanic_black 20, rust_metal 10, foam_white 22, painted_metal 11,
wood_weathered 9, sand_mid 1, sand_shadow 2. Abatere de culoare fata de tabelul
din §5, dupa decupare: stalpii si acoperisul (vezi raportul).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_sf_cable_car.py
Verificare:
    python tools/blender/verify_glb.py assets/models/sanfrancisco/vehicles/cable_car.glb 20000 --front=-Z
Randari de control: preview_sf_cable_car.py.
"""

import math
import bmesh
from mathutils import Matrix, Vector

NAME = "CableCar_Body"
GLB = "sanfrancisco/vehicles/cable_car.glb"

# --- cote (contract) ----------------------------------------------------------
HALF_L = 4.25          # lungimea 8,50
HALF_W = 1.25          # latimea 2,50 (marginea scarilor)
TOP_Z = 3.20           # varful lanternoului
BODY = 1.00            # jumatatea corpului (2,0 m)
CAB = 1.65             # jumatatea cabinei (3,3 m)
BOGIE_Y = HALF_L - 1.6
WHEEL_R = 0.30
FLOOR_Z = 0.76
SKIRT_Z0, SKIRT_Z1 = 0.25, 0.70
BOARD_Z0, BOARD_Z1 = 0.41, 0.49
ROOF_Z0 = 2.75
EAVE = 1.05
PLAT_END = 4.15        # capatul platformei (parapetul)
CHAMFER_Y = 3.85       # de unde se teseste platforma in plan
CHAMFER_X = 0.72
BELT_Z0, BELT_Z1 = 1.45, 1.55
WIN_Z1 = 2.45
GLASS_X = 0.92         # geamul retras 0,08 fata de peretele de la 1,0
POST = 0.11
POST_X = 0.94

# sloturi
RED, CREAM, WOOD_D, DARK = KERB_RED, CORAL_SAND, LOG_DARK, VOLCANIC_BLACK
BRASS, WHITE = RUST, FOAM_WHITE
CLOTH_A, CLOTH_B = PAINTED, WOOD
SKIN, HAIR = SAND_MID, SAND_SHADOW
# Acoperisul: decuparea il are rosu-visiniu; tabelul din brief §5 il pune pe
# coral_sand cu capetele kerb_red. DECIS LA INTEGRARE (coordonatorul, 15 nov 2026,
# pe cable_car_roof_ab.png): varianta din brief. Camera de joc vede vagonul de sus
# si din spate, deci acoperisul e cea mai mare suprafata din cadru: rosu peste
# caroseria rosie citea ca o pata dintr-o bucata; crem, cu lanternoul si capetele
# rosii, da cele doua tonuri ale vagonului si scoate lanternoul. `KERB_RED` aici
# reface varianta decuparii.
ROOF_SLOT = CORAL_SAND


# --- ajutoare locale ------------------------------------------------------------

def abox(b, x0, x1, y0, y1, z0, z1, slot, rot=None):
    """Cutie data prin extente (mai sigur decat centru + marime la oglindire)."""
    xa, xb = min(x0, x1), max(x0, x1)
    ya, yb = min(y0, y1), max(y0, y1)
    return b.box(((xa + xb) * 0.5, (ya + yb) * 0.5, (z0 + z1) * 0.5),
                 (xb - xa, yb - ya, z1 - z0), slot, rotation=rot)


def loft(b, stations, slot):
    """Sectiuni (y, [(x, z), ...]) cu acelasi numar de puncte -> solid inchis."""
    rings = []
    for y, poly in stations:
        rings.append([b.bm.verts.new((x, y, z)) for x, z in poly])
    n = len(rings[0])
    for lo, hi in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    b.bm.faces.new(tuple(reversed(rings[0])))
    b.bm.faces.new(tuple(rings[-1]))
    return b._tag([v for r in rings for v in r], slot)


def plan_prism(b, outline, z0, z1, slot):
    """Contur in plan (x, y) extrudat pe Z."""
    lo = [b.bm.verts.new((x, y, z0)) for x, y in outline]
    hi = [b.bm.verts.new((x, y, z1)) for x, y in outline]
    n = len(outline)
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def yz_prism(b, outline, x0, x1, slot):
    """Contur in planul (y, z) extrudat pe X (coltare de arc pe peretii laterali)."""
    lo = [b.bm.verts.new((x0, y, z)) for y, z in outline]
    hi = [b.bm.verts.new((x1, y, z)) for y, z in outline]
    n = len(outline)
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def xz_prism(b, outline, y0, y1, slot):
    """Contur in planul (x, z) extrudat pe Y (coltare pe peretii de capat)."""
    lo = [b.bm.verts.new((x, y0, z)) for x, z in outline]
    hi = [b.bm.verts.new((x, y1, z)) for x, z in outline]
    n = len(outline)
    b.bm.faces.new(tuple(hi))
    b.bm.faces.new(tuple(reversed(lo)))
    for i in range(n):
        j = (i + 1) % n
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    return b._tag(lo + hi, slot)


def arch_corners(r, a, c, ztop, steps=4):
    """Doua coltare de arc (contururi 2D) pentru un gol intre a si c, sus la
    ztop: umplu colturile de sus ale ferestrei, deci golul ramas are capul
    arcuit, ca in decupare."""
    out = []
    for side in (0, 1):
        pts = []
        if side == 0:      # coltul din stanga: centrul arcului la (a + r, ztop - r)
            cy = a + r
            pts.append((a, ztop))
            for k in range(steps + 1):
                t = math.pi - (math.pi * 0.5) * k / steps     # 180 -> 90 grade
                pts.append((cy + r * math.cos(t), ztop - r + r * math.sin(t)))
        else:
            cy = c - r
            pts.append((c, ztop))
            for k in range(steps + 1):
                t = (math.pi * 0.5) * k / steps                # 0 -> 90 grade
                pts.append((cy + r * math.cos(t), ztop - r + r * math.sin(t)))
        out.append(pts)
    return out


def oct_wheel(b, cx, cy, cz, r, width, slot):
    """Roata cu 8 laturi pe axa X, cu un VARF jos: atinge exact z = cz - r.
    (create_cone nu garanteaza faza octogonului, deci roata se scrie de mana.)"""
    rings = []
    for x in (cx - width * 0.5, cx + width * 0.5):
        ring = []
        for k in range(8):
            a = -math.pi * 0.5 + k * math.pi / 4.0
            ring.append(b.bm.verts.new((x, cy + r * math.cos(a), cz + r * math.sin(a))))
        rings.append(ring)
    lo, hi = rings
    for i in range(8):
        j = (i + 1) % 8
        b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    b.bm.faces.new(tuple(reversed(lo)))
    b.bm.faces.new(tuple(hi))
    return b._tag(lo + hi, slot)


def xform(faces, m):
    vs = {v for f in faces if f.is_valid for v in f.verts}
    for v in vs:
        v.co = m @ v.co
    return faces


def sphere(b, center, r, slot, seg=8):
    """Sfera cu 8 laturi (cap de figurina): inele la -60/-25/15/50 grade + apex."""
    prof = []
    for ang in (-62.0, -28.0, 10.0, 45.0, 72.0):
        a = math.radians(ang)
        prof.append((r * math.cos(a), r * math.sin(a)))
    prof.append((0.0, r))
    return b.revolve(prof, slot, segments=seg, origin=center, cap_bottom=True)


# --- piesele ----------------------------------------------------------------

def plat_outline(inset=0.0, end=PLAT_END):
    """Conturul platformei in plan (corp +-1,0, capete tesite)."""
    w = BODY - inset
    cx = CHAMFER_X - inset * 0.4
    e = end - inset
    cy = CHAMFER_Y
    return [(w, -cy), (w, cy), (cx, e), (-cx, e), (-w, cy), (-w, -cy), (-cx, -e), (cx, -e)]


def slice_y(b, faces, ys):
    """Taie fetele pe planuri y = const (doar ca AO-ul sa aiba varfuri pe
    lungime; fetele coplanare raman fara bevel)."""
    geom = list({v for f in faces for v in f.verts}) + list(
        {e for f in faces for e in f.edges}) + list(faces)
    for y in ys:
        res = bmesh.ops.bisect_plane(b.bm, geom=geom, plane_co=(0, y, 0),
                                     plane_no=(0, 1, 0))
        geom = list({g for g in res["geom"]} | set(geom))
        geom = [g for g in geom if g.is_valid]
    # fetele taiate isi pastreaza stratul `slot` (bisect copiaza datele fetei)
    return {g for g in geom if isinstance(g, bmesh.types.BMFace)}


def chassis(b):
    # 1. boghiurile
    for sy in (-1, 1):
        cy = sy * BOGIE_Y
        for sx in (-1, 1):
            # cadrul lateral al boghiului (se vede sub fusta)
            # (deasupra axei, ca roata sa ramana vizibila sub el)
            abox(b, sx * 0.88, sx * 0.97, cy - 0.66, cy + 0.66, 0.30, 0.40, DARK)
            for dy in (-0.45, 0.45):
                oct_wheel(b, sx * 0.79, cy + dy, WHEEL_R, WHEEL_R, 0.14, DARK)
                # cutia osiei, pe butucul rotii
                abox(b, sx * 0.86, sx * 0.97, cy + dy - 0.09, cy + dy + 0.09, 0.22, 0.40, DARK)
        abox(b, -0.88, 0.88, cy - 0.12, cy + 0.12, 0.14, 0.30, DARK)     # traversa

    # 2. fusta (solida): sus pe tot conturul, jos (pana la 0,25) doar in afara
    # boghiurilor — deasupra rotilor fusta se opreste la 0,38, deci roata e
    # ascunsa pe jumatate, nu de tot (decuparea arata boghiurile)
    arch_z = 0.38
    skirt = plan_prism(b, plat_outline(), arch_z, SKIRT_Z1, RED)
    slice_y(b, skirt, [k * 0.55 for k in range(-7, 8)])
    gap = BOGIE_Y - 0.78
    abox(b, -BODY, BODY, -gap, gap, SKIRT_Z0, arch_z + 0.01, RED)
    for s in (1, -1):
        y0 = BOGIE_Y + 0.78
        end = [(BODY, y0), (BODY, CHAMFER_Y), (CHAMFER_X, PLAT_END),
               (-CHAMFER_X, PLAT_END), (-BODY, CHAMFER_Y), (-BODY, y0)]
        plan_prism(b, [(x, s * y) for x, y in (end if s > 0 else reversed(end))],
                   SKIRT_Z0, arch_z + 0.01, RED)
    # 3. puntea: cant crem, ca platforma aurie din decupare
    deck = plan_prism(b, plat_outline(), SKIRT_Z1, FLOOR_Z, CREAM)
    slice_y(b, deck, [k * 0.55 for k in range(-7, 8)])
    b.retag(deck, WOOD_D, where="up")

    # 4. scarile laterale pe console
    for sx in (-1, 1):
        board = abox(b, sx * BODY, sx * HALF_W, -CHAMFER_Y, CHAMFER_Y, BOARD_Z0, BOARD_Z1, WOOD_D)
        slice_y(b, board, [k * 0.55 for k in range(-6, 7)])
        for y in (-3.40, -1.95, -0.65, 0.65, 1.95, 3.40):
            abox(b, sx * 0.98, sx * 1.16, y - 0.06, y + 0.06, 0.28, BOARD_Z0 + 0.01, DARK)


def roof_droop(y):
    t = max(0.0, (abs(y) - 3.30) / 0.95)
    return 0.16 * t * t


def roof_halfwidth(y):
    t = (abs(y) - 3.95) / 0.30
    if t <= 0.0:
        return EAVE
    t = min(t, 1.0)
    return 0.85 + 0.20 * math.sqrt(max(0.0, 1.0 - t * t))


def roof(b):
    # 13. acoperisul: sectiune cu streasina, fascia si panta spre lanternou
    sec = [(-EAVE, ROOF_Z0), (EAVE, ROOF_Z0), (EAVE, 2.83), (0.80, 2.885),
           (0.55, 2.92), (-0.55, 2.92), (-0.80, 2.885), (-EAVE, 2.83)]
    ys = [-4.25, -4.23, -4.19, -4.13, -4.05, -3.95, -3.80, -3.60, -3.40]
    ys += [round(-3.0 + 0.5 * k, 3) for k in range(13)]
    ys += [3.40, 3.60, 3.80, 3.95, 4.05, 4.13, 4.19, 4.23, 4.25]
    sts = []
    for y in ys:
        k = roof_halfwidth(y) / EAVE
        d = roof_droop(y)
        sts.append((y, [(x * k, z - d) for x, z in sec]))
    faces = loft(b, sts, ROOF_SLOT)
    if ROOF_SLOT != RED:
        b.retag(faces, RED, where=lambda c, n: abs(c.y) > 3.5)
    # fascia laterala si dedesubtul (tavanul platformelor) pe crem, ca in decupare
    b.retag(faces, CREAM, where=lambda c, n: abs(n.x) > 0.7 or n.z < -0.7)

    # 14. lanternoul
    csec = [(-0.46, 2.88), (0.46, 2.88), (0.46, 3.10), (0.54, 3.10), (0.54, 3.15),
            (0.22, TOP_Z), (-0.22, TOP_Z), (-0.54, 3.15), (-0.54, 3.10), (-0.46, 3.10)]
    cys = [-3.30, -3.15, -3.0] + [round(-2.5 + 0.5 * k, 3) for k in range(11)] + [3.0, 3.15, 3.30]
    csts = []
    for y in cys:
        f = 1.0 if abs(y) <= 3.0 else max(0.10, 1.0 - (abs(y) - 3.0) / 0.30 * 0.9)
        csts.append((y, [(x, 2.88 + (z - 2.88) * f) for x, z in csec]))
    cl = loft(b, csts, CREAM)
    b.retag(cl, RED, where=lambda c, n: n.z > 0.5)
    # ferestruicile lanternoului
    for sx in (-1, 1):
        for k in range(12):
            y = -2.75 + k * 0.50
            abox(b, sx * 0.455, sx * 0.478, y - 0.16, y + 0.16, 2.95, 3.06, DARK)

    # 16. clopotul pe acoperisul din fata (yoke + clopot)
    by = 3.55
    rz = 2.92 - roof_droop(by)
    abox(b, -0.05, 0.05, by - 0.05, by + 0.05, rz - 0.02, rz + 0.06, BRASS)
    prof = [(0.125, 0.0), (0.118, 0.035), (0.090, 0.09), (0.075, 0.14),
            (0.045, 0.175), (0.0, 0.19)]
    b.revolve(prof, BRASS, segments=10, origin=(0.0, by, rz + 0.04), cap_bottom=True)


def open_end(b, s):
    """Capatul deschis: s = +1 fata, -1 spate."""
    y_in = s * (CAB + 0.02)
    y_bench_end = s * 3.38
    # 5/6. banca spate-in-spate pe axa
    abox(b, -0.06, 0.06, y_in, y_bench_end, FLOOR_Z, 1.72, WOOD_D)               # spatarul
    abox(b, -0.055, 0.055, y_in, y_bench_end - s * 0.02, 1.70, 1.80, BRASS)       # bara de alama
    for sx in (-1, 1):
        abox(b, sx * 0.06, sx * 0.58, y_in, y_bench_end, 1.13, 1.21, WOOD_D)      # sezutul
        abox(b, sx * 0.06, sx * 0.50, y_in, y_bench_end - s * 0.04, FLOOR_Z, 1.13, DARK)  # soclul umbrit
        abox(b, sx * 0.06, sx * 0.58, y_bench_end - s * 0.04, y_bench_end, FLOOR_Z, 1.21, WOOD_D)  # capatul bancii

    # stalpii: mijloc + colt (cel de langa cabina e coltul cabinei)
    for sx in (-1, 1):
        for yp in (2.80, CHAMFER_Y):
            top = ROOF_Z0 - roof_droop(yp) + 0.03
            abox(b, sx * (POST_X - POST / 2), sx * (POST_X + POST / 2),
                 s * yp - POST / 2, s * yp + POST / 2, FLOOR_Z, top, CREAM)
        # grinda de streasina de-a lungul platformei
        abox(b, sx * (POST_X - 0.06), sx * (POST_X + 0.06), s * CAB, s * CHAMFER_Y,
             2.60, ROOF_Z0 + 0.02, CREAM)

    # grinda de capat cu dreptunghiul de destinatie (15)
    yh = s * CHAMFER_Y
    top = ROOF_Z0 - roof_droop(CHAMFER_Y) + 0.03
    abox(b, -POST_X, POST_X, yh - 0.05, yh + 0.05, 2.44, top, CREAM)
    abox(b, -0.40, 0.40, yh + s * 0.05, yh + s * 0.075, 2.48, 2.66, WHITE)

    # 7. parapetul pe conturul tesit + mana curenta
    pe = PLAT_END - 0.04
    abox(b, -CHAMFER_X + 0.02, CHAMFER_X - 0.02, s * (pe - 0.04), s * (pe + 0.04),
         FLOOR_Z, 1.24, RED)
    abox(b, -CHAMFER_X, CHAMFER_X, s * (pe - 0.05), s * (pe + 0.05), 1.22, 1.30, BRASS)
    ang = math.atan2(PLAT_END - CHAMFER_Y, BODY - CHAMFER_X)    # tesitura
    ln = math.hypot(PLAT_END - CHAMFER_Y, BODY - CHAMFER_X)
    for sx in (-1, 1):
        mx = sx * (BODY + CHAMFER_X) * 0.5 - sx * 0.035
        my = s * ((PLAT_END + CHAMFER_Y) * 0.5) - s * 0.035
        rot = Matrix.Rotation(-sx * s * ang, 3, "Z")
        b.box((mx, my, (FLOOR_Z + 1.24) * 0.5), (ln, 0.08, 1.24 - FLOOR_Z), RED, rotation=rot)
        b.box((mx, my, 1.26), (ln + 0.04, 0.10, 0.08), BRASS, rotation=rot)

    # 8. farul + tamponul
    yf = s * PLAT_END
    b.cylinder((0.0, yf + s * 0.035, 1.00), 0.13, 0.07, BRASS, segments=10, axis="Y")
    b.cylinder((0.0, yf + s * 0.075, 1.00), 0.10, 0.04, WHITE, segments=10, axis="Y")
    abox(b, -0.62, 0.62, yf - s * 0.02, yf + s * 0.06, 0.30, 0.46, WOOD_D)


def cabin(b):
    # 9. peretele de jos, braul, tablia de sus, miezul de geam (retras 0,08)
    lw = abox(b, -BODY, BODY, -CAB, CAB, FLOOR_Z - 0.02, BELT_Z0, RED)
    slice_y(b, lw, [k * 0.55 for k in range(-2, 3)])
    abox(b, -BODY - 0.02, BODY + 0.02, -CAB - 0.02, CAB + 0.02, BELT_Z0, BELT_Z1, CREAM)
    abox(b, -BODY, BODY, -CAB, CAB, WIN_Z1, ROOF_Z0 + 0.02, CREAM)
    abox(b, -GLASS_X, GLASS_X, -(CAB - 0.08), CAB - 0.08, BELT_Z1 - 0.01, WIN_Z1 + 0.01, DARK)
    # stalpii de colt ai cabinei
    for sx in (-1, 1):
        for sy in (-1, 1):
            abox(b, sx * 0.86, sx * BODY, sy * (CAB - 0.14), sy * (CAB + 0.02),
                 FLOOR_Z - 0.02, ROOF_Z0 + 0.02, CREAM)

    # 10/11. laterale: W W W | USA (y de la spate spre fata)
    W, P, D = 0.653, 0.10, 0.80
    y0 = -(CAB - 0.12)
    wins = []
    y = y0
    for _ in range(3):
        wins.append((y, y + W))
        y += W + P
    door = (wins[-1][1] + P, CAB - 0.12)       # (0,729 .. 1,53)
    for sx in (-1, 1):
        xo, xi = sx * BODY, sx * GLASS_X
        # montantii dintre ferestre si dintre fereastra si usa
        for a, c in ((wins[0][1], wins[1][0]), (wins[1][1], wins[2][0]),
                     (wins[2][1], door[0])):
            abox(b, xi, xo, a, c, BELT_Z1 - 0.01, WIN_Z1 + 0.01, CREAM)
        # capetele arcuite ale ferestrelor
        for a, c in wins:
            for pts in arch_corners(0.22, a, c, WIN_Z1 + 0.005):
                yz_prism(b, pts, min(xi, xo), max(xi, xo), CREAM)
            # panoul in relief de sub fereastra
            abox(b, xo, xo + sx * 0.025, a + 0.06, c - 0.06, 0.88, 1.37, RED)
        # usa dubla: montant central, traversa de sus, rama de jos in relief
        dm = (door[0] + door[1]) * 0.5
        abox(b, xi, xo, dm - 0.04, dm + 0.04, BELT_Z1 - 0.01, WIN_Z1 + 0.01, CREAM)
        abox(b, xi, xo, door[0], door[1], 2.33, WIN_Z1 + 0.01, CREAM)
        xr0, xr1 = xo, xo + sx * 0.03
        for a, c in ((door[0], door[0] + 0.08), (dm - 0.04, dm + 0.04), (door[1] - 0.08, door[1])):
            abox(b, xr0, xr1, a, c, 0.78, BELT_Z0, CREAM)
        abox(b, xr0, xr1, door[0], door[1], 0.78, 0.86, CREAM)
        for a, c in ((door[0] + 0.08, dm - 0.04), (dm + 0.04, door[1] - 0.08)):
            abox(b, xr0, xo + sx * 0.02, a + 0.04, c - 0.04, 0.92, 1.36, RED)

    # 12. peretii de capat: doua ferestre arcuite de o parte si de alta a spatarului
    for sy in (-1, 1):
        yo, yi = sy * CAB, sy * (CAB - 0.08)
        abox(b, -0.12, 0.12, yi, yo, BELT_Z1 - 0.01, WIN_Z1 + 0.01, CREAM)
        for a, c in ((-0.86, -0.12), (0.12, 0.86)):
            for pts in arch_corners(0.20, a, c, WIN_Z1 + 0.005):
                xz_prism(b, pts, min(yi, yo), max(yi, yo), CREAM)


def grip(b):
    # 17. parghia de prindere + frana, in capatul din fata, langa ax
    y = 3.70
    abox(b, -0.20, 0.20, y - 0.30, y + 0.30, FLOOR_Z, FLOOR_Z + 0.05, DARK)
    abox(b, -0.10, 0.10, y - 0.12, y + 0.12, FLOOR_Z, FLOOR_Z + 0.22, DARK)
    b.beam((0.0, y, FLOOR_Z + 0.10), (0.0, y + 0.10, FLOOR_Z + 1.20), 0.10, WOOD_D)
    b.beam((-0.16, y + 0.10, FLOOR_Z + 1.16), (0.16, y + 0.10, FLOOR_Z + 1.16), 0.09, BRASS)
    b.beam((0.30, y + 0.05, FLOOR_Z + 0.05), (0.30, y + 0.16, FLOOR_Z + 0.90), 0.09, WOOD_D)
    b.cylinder((0.30, y + 0.17, FLOOR_Z + 0.92), 0.06, 0.12, BRASS, segments=8, axis="Z")


# --- calatorii ------------------------------------------------------------------

# Camasile pe culorile vii din decupare (albastru, maro, crem); albul doar o
# data: alaturi de stalpii crem, figurinele albe se pierdeau in randarea v1.
SHIRTS = [CLOTH_A, CLOTH_B, CREAM, CLOTH_A, CLOTH_B, CLOTH_A, WHITE, CLOTH_B,
          CLOTH_A, CLOTH_B, CREAM, CLOTH_A]
PANTS = [DARK, CLOTH_A, CLOTH_B, CLOTH_B, DARK, DARK, CLOTH_A, DARK,
         CLOTH_B, CLOTH_A, DARK, CLOTH_B]
HATS = [CREAM, None, HAIR, None, CREAM, HAIR, None, CREAM, None, HAIR, CREAM, None]
HEAD_R = 0.18


def torso(b, z0, z1, slot, sx=0.78):
    """Corpul-capsula de figurina (eliptic: mai ingust pe X, in grosime)."""
    h = z1 - z0
    path = [(0, 0, z0 + h * t) for t in (0.0, 0.25, 0.6, 0.88, 1.0)]
    faces = b.taper_sweep(path, [0.15, 0.185, 0.195, 0.17, 0.08], slot, segments=8)
    return xform(faces, Matrix.Diagonal((sx, 1.0, 1.0, 1.0)))


def head(b, zc, idx):
    """Capul mare de jucarie (sfera cu 8 laturi, crestetul la zc) + par, sau
    palarie de pai / sapca (calota + bor lat, gros de 0,06)."""
    r = HEAD_R
    faces = sphere(b, (0.0, 0.0, zc - r), r, SKIN)
    hat = HATS[idx % len(HATS)]
    if hat is not None:
        faces |= b.revolve([(0.195, 0.0), (0.185, 0.07), (0.13, 0.14), (0.0, 0.17)],
                           hat, segments=8, origin=(0.0, 0.0, zc - 0.12))
        faces |= b.cylinder((0.0, 0.0, zc - 0.10), 0.27 if hat == CREAM else 0.21,
                            0.06, hat, segments=8)
    else:
        faces |= b.revolve([(0.192, 0.0), (0.175, 0.08), (0.10, 0.15), (0.0, 0.18)],
                           HAIR, segments=8, origin=(-0.03, 0.0, zc - 0.15))
    return faces


def standing(b, x, y, z, sx, idx, post):
    """Calator in picioare pe scara: fata spre exterior, inclinat spre corp,
    o mana pe stalpul `post` (x, y, z al punctului de prindere)."""
    fs = set()
    for dy in (-0.095, 0.095):
        fs |= abox(b, -0.08, 0.10, dy - 0.06, dy + 0.06, 0.0, 0.08, HAIR)         # pantofi
        fs |= b.cylinder((0.0, dy, 0.40), 0.08, 0.66, PANTS[idx], segments=8)     # picioare
    fs |= torso(b, 0.66, 1.34, SHIRTS[idx])
    fs |= head(b, 1.70, idx)
    # partea stalpului in coordonatele LOCALE ale figurinei (flip-ul neaga y)
    side = (1.0 if post[1] > y else -1.0) * sx
    # bratul liber, pe langa corp, pe partea opusa stalpului
    fs |= b.sweep([(0.0, -0.21 * side, 1.24), (0.02, -0.24 * side, 0.98),
                   (0.05, -0.21 * side, 0.80)], 0.065, SHIRTS[idx], segments=6)
    lean = Matrix.Rotation(math.radians(-7.0 * sx), 4, "Y")
    flip = Matrix.Rotation(0.0 if sx > 0 else math.pi, 4, "Z")
    m = Matrix.Translation((x, y, z)) @ lean @ flip
    xform(fs, m)
    # bratul de prindere, scris in coordonate de lume: umar -> stalp
    sh = m @ Vector((0.0, 0.19 * side, 1.24))
    hand = Vector(post)
    mid = sh.lerp(hand, 0.5) + Vector((sx * 0.02, 0.0, 0.06))
    b.sweep([sh, mid, hand], 0.065, SHIRTS[idx], segments=6, dome_end=True)
    b.revolve([(0.07, 0.0), (0.06, 0.06), (0.0, 0.09)], SKIN, segments=6,
              origin=(hand.x, hand.y, hand.z - 0.04))


def seated(b, x, y, sx, idx):
    """Calator asezat pe banca exterioara, cu fata spre exterior (sx)."""
    z = 1.21
    fs = set()
    for dy in (-0.10, 0.10):
        fs |= b.beam((0.0, dy, 0.09), (0.40, dy, 0.09), 0.16, PANTS[idx])        # coapse
        fs |= b.beam((0.42, dy, 0.10), (0.46, dy, -0.38), 0.15, PANTS[idx])      # gambe
        fs |= abox(b, 0.38, 0.62, dy - 0.06, dy + 0.06, -0.45, -0.37, HAIR)     # pantofi
    fs |= torso(b, 0.0, 0.66, SHIRTS[idx])
    fs |= head(b, 1.00, idx)
    for dy in (-0.21, 0.21):
        fs |= b.sweep([(0.0, dy, 0.56), (0.10, dy * 1.05, 0.33), (0.30, dy * 0.75, 0.22)],
                      0.065, SHIRTS[idx], segments=6)
    lean = Matrix.Rotation(math.radians(-6.0), 4, "Y")       # spre spatar
    flip = Matrix.Rotation(0.0 if sx > 0 else math.pi, 4, "Z")
    xform(fs, Matrix.Translation((x, y, z)) @ flip @ lean)


def passengers(b):
    idx = 0
    # 18. in picioare: (y, stalpul tinut)
    for s in (1, -1):
        for sx in (1, -1):
            for y_r, y_p in ((2.42, 2.80), (3.48, CHAMFER_Y)):
                post = (sx * (POST_X + 0.06), s * y_p - s * 0.07, 1.90)
                standing(b, sx * 1.11, s * y_r, BOARD_Z1, sx, idx, post)
                idx += 1
    # 19. asezati: doi in fata, doi in spate
    for sx, y in ((1, 2.95), (-1, 2.05), (1, -3.00), (-1, -2.10)):
        seated(b, sx * 0.27, y, sx, idx)
        idx += 1


def build_body():
    b = Builder()
    chassis(b)
    cabin(b)
    for s in (1, -1):
        open_end(b, s)
    roof(b)
    grip(b)
    return b


def build_riders():
    b = Builder()
    passengers(b)
    return b


def finish_joined(body, riders, bevel, bevel_angle, ao):
    """`finish()` din dio_lib, cu o singura diferenta: bevel-ul se aplica doar
    caroseriei. Pe figurine dubla triunghiurile (5,3k -> 10,6k) fara sa se
    vada, iar brief-ul §7 nu-l cere acolo. UV-urile se pun pe fiecare parte
    din propriul snapshot, apoi partile se unesc INAINTE de origine si AO,
    ca ocluzia dintre calatori si caroserie sa fie coapta impreuna."""
    snap_b = snapshot_slots(body)
    snap_r = snapshot_slots(riders)
    apply_bevel(body, bevel, segments=1, angle_deg=bevel_angle)
    assign_uvs(body, snap_b)
    assign_uvs(riders, snap_r)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    riders.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    apply_smooth(obj, 55.0)
    set_origin_base(obj, center_xy=True)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    rng = bake_ao(obj, **ao)
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    return obj, {"tris": tri_count(obj), "ao_min": round(rng[0], 3), "ao_max": round(rng[1], 3)}


# --- build ----------------------------------------------------------------------
AO = dict(samples=32, dist=1.2, gradient="vertical", low=0.60, high=1.0,
          power=1.0, floor=0.30)

clear_built(NAME)
clear_built("CableCar_Riders")
_body = build_body().to_object(NAME)
_riders = build_riders().to_object("CableCar_Riders")
obj, stats = finish_joined(_body, _riders, bevel=0.04, bevel_angle=50.0, ao=AO)
obj.name = NAME
obj.data.name = NAME
me = obj.data
lo = [min(v.co[i] for v in me.vertices) for i in range(3)]
hi = [max(v.co[i] for v in me.vertices) for i in range(3)]
print("%s %d tris | X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f | %.3f x %.3f x %.3f | AO %.2f..%.2f"
      % (NAME, stats["tris"], lo[0], hi[0], lo[1], hi[1], lo[2], hi[2],
         hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], stats["ao_min"], stats["ao_max"]))
print("GLB:   %s (%d B)" % export_glb([obj], GLB))
print("BLEND: %s (%d B)" % save_blend([obj], "sf_cable_car.blend"))
