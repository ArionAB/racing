"""Carrara -- utilajele (brief docs/asset_briefs/carrara_kit.md §1.1, §1.2).

  carrara/vehicles/quarry_truck.glb   basculanta rigida cu 2 blocuri de marmura (pilot)
  carrara/structures/derrick.glb      macaraua derrick (CraneHazard.crane_model), scara 1:0,7256
  carrara/props/marble_block_hooked.glb  blocul agatat (CraneHazard.slab_model)
  carrara/props/lizza_sled.glb        sania de lizzatura (RockfallHazard, roll_model=false)
  carrara/rocks/block_informe_a.glb   blocul informe care se rostogoleste (RockfallHazard)
  carrara/vehicles/quarry_excavator.glb  excavatorul cu furca (ExcavatorHazard, rigul rusted_digger)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_machines.py
Variabila de mediu CRR_ONLY=<piesa> reface doar piesa respectiva.

Axe: X latime, Y lungime (botul spre +Y in Blender = -Z in Godot), Z sus.
Originea pe centrul amprentei, la sol (offset calculat O DATA pe ansamblu).
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "carrara_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("CRR_ONLY", "")


# ---------------------------------------------------------------------------
# quarry_truck
# ---------------------------------------------------------------------------

AO_TRUCK = dict(samples=20, dist=1.2, gradient="vertical", low=0.62, high=1.0,
                power=0.8, floor=0.38, z_range=(0.0, 3.4))

# cote (Blender, metri; botul +Y). Anvelopa Kamaz: 2,68 x 3,13 x 8,0 -- aici
# latimea totala ~2,83 (roti la x = +-1,36, capacele jantelor +5 cm), lungimea
# ~7,7, inaltimea ~3,38 (blocurile).
TK_R = 0.86                 # raza rotii (fara crampoane)
TK_CZ = 0.90                # centrul rotii: crampoanele (4 cm) ating solul
TK_Y_FRONT = 2.75           # axa fata (sub cabina, ca pe plansa)
TK_Y_REAR = -2.15           # axa spate (roti duble)
TK_FLOOR0 = 1.84            # fata de jos a podelei benei (peste varful rotii 1,805)
TK_FLOOR1 = 1.98            # fata de sus a podelei = cota blocurilor


def build_quarry_truck():
    """LISTA DE ELEMENTE (decuparea `quarry_truck.png` + `_b`, scrisa INAINTE de
    geometrie; corecturile din kit §1.1 suprascriu planșa unde se bat cap in cap;
    runda 2: planșa arata un camion SCURT cu roti uriase si cabina lipita de
    grila, fara capota lunga):

     1. Roti: 6 (planșa: 4 vizibile + perechea a doua din spate). 2 in fata,
        singure, si 4 in spate, DUBLE (doua anvelope alaturate pe fiecare parte,
        ca pe planșa). Raza 0,86 m (jucarie: mari fata de caroserie), 14 laturi,
        14 crampoane pe anvelopa; janta de vopsea cu capac de rugina pe fata
        exterioara. Fara a treia axa.
     2. Cabina: scurta, 1 corp lat (2,3 m) peste rotile din fata, cu sera
        inclinata (parbriz retras 27 grade), geam lateral, luneta, 2 oglinzi
        mici in contur, un evacuator. Fara capota lunga: grila neagra pe fata
        cabinei, cu 3 bare de vopsea.
     3. Bara de protectie de rugina in fata (1 corp), miez de radiator sub cabina.
     4. Bena (runda 3): CAROSERIE PLINA de otel, nu platforma cu rame: podea +
        2 placi laterale inchise (evazate 6 grade) cu buza rulata sus + perete
        din spate RIDICAT (cu 0,40 m peste laterale: „muchia din spate
        ridicata"). Peretele din FATA e o pana care urca spre fata si se
        continua cu COPERTINA peste cabina, toate in `Truck_Body`; doua placi
        triunghiulare inchid copertina pe laterale. Fara sine deschise, fara
        stalpi.
     5. Nervuri: 4 pe fiecare placa laterala, verticale, in relief (7 cm).
     6. Sasiu: 2 longeroane inguste, axe negre, subsasiu de rugina sub bena,
        2 balamale de rugina in spate, 2 cilindri hidraulici (negri) sub bena.
     7. Blocuri: 2 blocuri de marmura (1,85 x 1,80 x 1,40 si 1,80 x 1,70 x 1,36),
        unul langa peretele din fata, celalalt in spatele lui, usor rotite
        (+2 / -3 grade), al doilea cu un colt de sus spart. Fiecare pe doua
        noduri: treimea de jos pe MARBLE_GREY (`Truck_MarbleBase`), restul pe
        CORAL_SAND (`Truck_Marble`). Pe planșa sunt 3-4 blocuri in stiva;
        corectura de kit cere 2.
     8. Ce iese din contur: nimic. Oglinzile si evacuatorul raman in latimea
        rotilor (2,83); nimic atarna.
     9. Culori: vopseaua pe DRY_VEGETATION (galben spalacit, NU galbenul planșei),
        rugina pe RUST_METAL, geamuri/anvelope/hidraulica/grila pe
        VOLCANIC_BLACK, pete de praf SAND_SHADOW pe flancul benei. Fara text,
        cifre, logo-uri.
    """
    body, rust, black = Builder(), Builder(), Builder()
    marble, mbase = Builder(), Builder()

    # --- 6. sasiu ------------------------------------------------------------
    for sx in (-1, 1):
        rust.box((sx * 0.30, 0.0, 1.25), (0.25, 7.0, 0.40), CRR_RUST)        # longeroane
        rust.box((sx * 0.30, -1.2, 1.65), (0.25, 4.6, 0.40), CRR_RUST)       # subsasiu
        rust.box((sx * 0.90, -3.55, 1.55), (0.42, 0.40, 0.34), CRR_RUST)     # balamale
        black.beam((sx * 0.42, 0.55, 1.15), (sx * 0.42, 0.05, 1.82), 0.15, CRR_BLACK)  # hidraulica
    for yw, rr in ((TK_Y_FRONT, 0.11), (TK_Y_REAR, 0.13)):
        black.cylinder((0.0, yw, TK_CZ), rr, 2.10, CRR_BLACK, segments=8, axis="X")  # axe

    # --- 1. roti --------------------------------------------------------------
    for sx in (-1, 1):
        wheel_crr(black, body, rust, sx * 1.085, TK_Y_FRONT, TK_CZ, TK_R, 0.55, sx)
        wheel_crr(black, body, rust, sx * 1.14, TK_Y_REAR, TK_CZ, TK_R, 0.44, sx)   # exterioara
        wheel_crr(black, body, rust, sx * 0.67, TK_Y_REAR, TK_CZ, TK_R, 0.44, sx, outer=False)

    # --- 4. bena: CAROSERIE PLINA de otel (placi inchise), copertina o continua -----
    y_f, y_b = 1.77, -3.70                      # capetele benei (fata / spate)
    bl = y_f - y_b
    yc = (y_f + y_b) * 0.5
    z_rim = 2.58                                # muchia de sus a laterale
    body.box((0.0, yc, (TK_FLOOR0 + TK_FLOOR1) * 0.5), (2.44, bl, TK_FLOOR1 - TK_FLOOR0), CRR_PAINT)
    zc_side = (TK_FLOOR0 + z_rim) * 0.5
    for sx in (-1, 1):
        tilted_box(body, (sx * 1.18, yc, zc_side), (0.14, bl, z_rim - TK_FLOOR0), CRR_PAINT, rot_y=sx * 6.0)
        body.box((sx * 1.215, yc, z_rim + 0.02), (0.24, bl, 0.12), CRR_PAINT)      # buza de sus, rulata
        # --- 5. 4 nervuri verticale in relief, pe placa plina ----------------
        for k in range(4):
            yr = y_b + 0.85 + k * (bl - 1.7) / 3.0
            tilted_box(body, (sx * 1.255, yr, zc_side), (0.07, 0.20, z_rim - TK_FLOOR0 - 0.06),
                       CRR_PAINT, rot_y=sx * 6.0)
        # placa triunghiulara de la cabina: inchide laterala sub copertina
        for xo in (1.12, 1.30):
            pass
        side = []
        for xx in (1.10, 1.30):
            for (yy, zz) in ((1.30, z_rim), (1.95, z_rim), (2.12, 3.17), (1.95, 3.17)):
                side.append(Vector((sx * xx, yy, zz)))
        _hull(body, side, CRR_PAINT)
    body.box((0.0, y_b + 0.07, 2.475), (2.44, 0.14, 0.99), CRR_PAINT)          # spate ridicat
    body.box((0.0, y_b + 0.07, 2.995), (2.60, 0.22, 0.12), CRR_PAINT)          # buza spate
    # peretele din fata: pana care urca SPRE FATA, continuata de copertina peste cabina
    wall = []
    for sx in (-1, 1):
        for (yy, zz) in ((1.55, TK_FLOOR1), (1.80, TK_FLOOR1), (2.12, 3.17), (1.87, 3.17)):
            wall.append(Vector((sx * 1.30, yy, zz)))
    _hull(body, wall, CRR_PAINT)
    canopy = []
    for sx in (-1, 1):
        for (yy, zz) in ((1.87, 3.17), (3.55, 3.10), (3.55, 2.97), (1.87, 3.03)):
            canopy.append(Vector((sx * 1.30, yy, zz)))
    _hull(body, canopy, CRR_PAINT)
    body.box((0.0, 3.52, 2.95), (2.60, 0.09, 0.20), CRR_PAINT)                 # buza copertinei

    # --- 2. cabina -------------------------------------------------------------
    body.box((0.0, 2.725, 2.19), (2.30, 1.65, 0.62), CRR_PAINT)                 # caroseria, peste roti
    body.box((0.0, 3.05, 1.665), (1.60, 1.00, 0.43), CRR_PAINT)                 # miez de radiator
    cab_pts = []
    for sx in (-1, 1):
        for (yy, zz) in ((1.90, 2.50), (3.35, 2.50), (3.10, 2.92), (1.90, 2.92)):
            cab_pts.append(Vector((sx * 1.02, yy, zz)))
    _hull(body, cab_pts, CRR_PAINT)                                             # sera
    slope = math.degrees(math.atan2(0.25, 0.42))
    glen = math.hypot(0.25, 0.42)
    tilted_box(black, (0.0, 3.225 + 0.02, 2.71), (1.80, 0.05, glen * 0.84), CRR_BLACK, rot_x=slope)
    for sx in (-1, 1):
        black.box((sx * 1.035, 2.55, 2.70), (0.05, 1.00, 0.28), CRR_BLACK)     # geam lateral
        rust.box((sx * 1.19, 3.30, 2.72), (0.07, 0.06, 0.18), CRR_RUST)        # brat oglinda
        black.box((sx * 1.25, 3.30, 2.76), (0.08, 0.14, 0.32), CRR_BLACK)      # oglinda
    black.box((0.0, 1.88, 2.70), (1.50, 0.05, 0.28), CRR_BLACK)                # luneta
    rust.cylinder((1.02, 1.835, 2.62), 0.06, 0.60, CRR_RUST, segments=8)        # evacuator

    # --- 3. grila, bara ---------------------------------------------------------
    black.box((0.0, 3.57, 2.17), (1.60, 0.06, 0.42), CRR_BLACK)                # grila
    for k in range(3):
        body.box((0.0, 3.605, 2.04 + k * 0.13), (1.64, 0.05, 0.04), CRR_PAINT)
    rust.box((0.0, 3.84, 1.55), (2.30, 0.28, 0.26), CRR_RUST)                  # bara

    # praf pe flancul benei (pete mici)
    for sx in (-1, 1):
        body.box((sx * 1.27, -1.5, 2.05), (0.02, 2.4, 0.20), CRR_DUST)

    # --- 7. blocurile ------------------------------------------------------------
    cut_marble_block(marble, mbase, (0.0, 0.70), (1.85, 1.80, 1.40), z0=TK_FLOOR1, yaw_deg=2.0)
    cut_marble_block(marble, mbase, (0.02, -1.45), (1.80, 1.70, 1.36), z0=TK_FLOOR1, yaw_deg=-3.0,
                     chip=0.28, chip_corner=(-1, -1))

    return [body.to_object("Truck_Body"), rust.to_object("Truck_Rust"),
            black.to_object("Truck_Black"), marble.to_object("Truck_Marble"),
            mbase.to_object("Truck_MarbleBase")]


# ---------------------------------------------------------------------------
# helpere crr-a: export FARA recentrare (originea e contract de cod)
# ---------------------------------------------------------------------------

def _world_dims(objs):
    pts = [o.matrix_world @ v.co for o in objs if o.type == "MESH" for v in o.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def emit_fixed(objs, path, aos, bevels=None, bevel=0.03, smooth_angle=40.0,
               extra=None):
    """Ca `emit_crr`, dar NU muta geometria: originea e pusa de build (balamaua
    bratului derrick-ului, carligul blocului, pivotul bratului excavatorului).
    `aos` = {nume nod: dict AO} (cheia "" e implicita). `extra` = noduri goale
    (ierarhia excavatorului) exportate impreuna cu mesh-urile."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    total, per_node = 0, {}
    for o in objs:
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        ao = aos.get(o.name, aos.get(""))
        st = finish(o, bevel=bw, ao=ao, origin=None, smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    lo, hi = _world_dims(objs)
    _, sz = export_glb(objs + list(extra or []), "carrara/" + path)
    CRR_RESULTS.append((path, total, hi - lo, per_node, sz / 1024.0))
    print("    %s: lume Blender X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f" %
          (path, lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))
    return total


def polyline_beam(b, pts, thick, slot, up=None):
    """Grinda pe o polilinie (carligul, furtunurile): o `beam` pe segment, cu
    un mic surplus la capete ca imbinarile sa nu lase fante."""
    for p, q in zip(pts[:-1], pts[1:]):
        p, q = Vector(p), Vector(q)
        tk = max(thick) if isinstance(thick, (tuple, list)) else thick
        d = (q - p).normalized() * (tk * 0.35)
        b.beam(p - d, q + d, thick, slot, up=up)


def taper_box(b, p0, p1, w0, h0, w1, h1, slot):
    """Grinda dreapta cu sectiune care se ingusteaza de la p0 (w0 x h0) la p1
    (w1 x h1); latimea pe X, inaltimea in planul vertical al axei."""
    p0, p1 = Vector(p0), Vector(p1)
    ax = (p1 - p0).normalized()
    side = Vector((1.0, 0.0, 0.0))
    upv = side.cross(ax).normalized() * -1.0
    if upv.z < 0:
        upv = -upv
    pts = []
    for c, w, h in ((p0, w0, h0), (p1, w1, h1)):
        for sx in (-1, 1):
            for sz in (-1, 1):
                pts.append(c + side * (sx * w * 0.5) + upv * (sz * h * 0.5))
    _hull(b, pts, slot)


def marble_box(marble, base, lo, hi, base_top=None, slot_m=None, slot_b=None):
    """Bloc de marmura axat pe axe, taiat drept (muchii vii), cu patina pana la
    `base_top` ca NOD separat (`*_MarbleBase`, kit regula 8). `base_top` None sau
    sub talpa: tot blocul e in lumina."""
    slot_m = CRR_MARBLE if slot_m is None else slot_m
    slot_b = CRR_MARBLE_BASE if slot_b is None else slot_b
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    if base_top is not None and base_top > z0 + 1e-3:
        zb = min(base_top, z1)
        base.box(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + zb) / 2),
                 (x1 - x0, y1 - y0, zb - z0), slot_b)
        z0 = zb
    if z1 > z0 + 1e-3:
        marble.box(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
                   (x1 - x0, y1 - y0, z1 - z0), slot_m)


# ---------------------------------------------------------------------------
# derrick  (CraneHazard.crane_model) -- scara de model 1 : 0,7256
# ---------------------------------------------------------------------------

DK_JIB_H = 22.05        # JIB_HEIGHT din crane_hazard.gd: varful catargului = pivotul
DK_REACH = 17.9         # 13 m in joc / 0,7256: carligul (hook_radius) si varful bratului
DK_HALF = 1.78          # MAST_SIDE / 2 = 1,8 pe X, cu 2 cm de rezerva pentru bevel
DK_X_B = 1.38           # axa picioarelor pe X, jos (+ jumatate de picior = 1,755)
DK_X_T = 0.55           # si sus
DK_Y_FRONT = 1.30       # piciorul din fata (+Y Blender = -Z Godot), jos
DK_Y_BACK = -7.40       # piciorul din spate, jos: A-frame-ul se deschide in LUNGUL drumului
DK_Y_T = 0.55           # ambele perechi sus, la +-0,55 de axa
DK_Z_LEG0 = 0.45        # picioarele pornesc de pe rama bazei
DK_Z_LEG1 = 21.20       # si intra in cap
DK_LEG_W = 0.75         # sectiunea piciorului (runda 3: planșa ~1/25 din inaltime)
DK_TIP_Z = 7.40         # cota rolei din varful bratului fata de balama (~22 grade)

AO_DK_MAST = dict(samples=16, dist=2.0, gradient="vertical", low=0.66, high=1.0,
                  power=0.6, floor=0.4, z_range=(0.0, DK_JIB_H))
AO_DK_JIB = dict(samples=16, dist=1.6, gradient="vertical", low=0.80, high=1.0,
                 power=0.8, floor=0.45, z_range=(-0.5, DK_TIP_Z + 1.0))


def _dk_leg(sx, front, z):
    """Punctul de pe axa piciorului (sx = -1/+1 pe X; front = True/False) la
    cota z."""
    t = (z - DK_Z_LEG0) / (DK_Z_LEG1 - DK_Z_LEG0)
    x = DK_X_B + (DK_X_T - DK_X_B) * t
    y0 = DK_Y_FRONT if front else DK_Y_BACK
    y1 = DK_Y_T if front else -DK_Y_T
    return Vector((sx * x, y0 + (y1 - y0) * t, z))


def build_derrick():
    """LISTA DE ELEMENTE (decuparea `derrick.png`, scrisa INAINTE de geometrie;
    corecturile kitului §1.1 suprascriu planșa: fara bloc, fara cablul sarcinii,
    cote din cod). Doua noduri RADACINA, cate un mesh fiecare (sonda
    `probe_carrara_derrick.gd` le cauta ca MeshInstance3D):

    `TowerCrane` (catargul, baza la Z=0, varful EXACT la 22,05 = JIB_HEIGHT):
     1. A-frame (runda 2): 4 PICIOARE de grinda patrata care converg in cap.
        Perechea din FATA aproape verticala (jos la Y +1,3), perechea din SPATE
        inclinata, cu talpa la Y -7,4 -- planșa: piciorul din fata drept,
        cele din spate deschise, adancimea bazei ~0,4 din inaltime. Pe X toate
        raman in +-1,8 m (MAST_SIDE): A-frame-ul se deschide in LUNGUL
        drumului (Godot +Z), nu spre el. In vedere din fata picioarele se
        strang de la +-1,5 la +-0,5 (trapez, ca pe planșa).
     2. Rama bazei: 2 talpi lungi pe Y (sub picioare) + 3 traverse pe X
        (fata, mijloc, spate), 4 papuci de lemn inchis (LOG_DARK) sub
        colturi -- "baza de barne".
     3. Legaturi: un brau orizontal la ~40% (4 grinzi) cu placi de imbinare
        (vopsea, ca pe planșa) la cele 4 colturi; contravantuiri in X pe cele doua fete
        LATERALE si pe fata din fata, in panoul de jos. Panoul de sus ramane
        deschis, ca pe planșa.
     4. Capul: bloc patrat 2,3 m in varf (20,7..22,05), placa de rugina sus.
     5. Troliul: tambur de rugina cu cablu negru infasurat, pe rama bazei
        intre picioarele din spate (planșa: cablurile coboara la baza).
     6. Pete de rugina: placi subtiri pe fata exterioara a catorva picioare
        (nu mansoane: runda 1 arata dungi de bariera).

    `Jib` (bratul, originea IN BALAMA = varful catargului, bratul pe +Y Blender =
    -Z Godot; codul il muta pe pivot si il roteste in jurul verticalei):
     7. Coroana de rotire: disc de rugina pe cap (Z 0..0,35), doua urechi de
        vopsea si boltul negru care tin piciorul bratului.
     8. Roata de cablu din cap (rugina), in spatele piciorului bratului.
     9. Bratul: grinda-cheson plina care se ingusteaza (1,30 x 1,40 la picior ->
        0,85 x 0,90 la varf), URCAND spre varf la ~22 grade (planșa ~25; varful
        nu urca mai mult fiindca trosa de sub el ar deveni un al doilea cablu).
        Brief-ul zice "zabrelit", planșa arata grinda plina: planșa. 2 placi
        de imbinare (vopsea) si pete de rugina pe flancuri.
    10. Capul bratului: doua flancuri (vopsea) si roata de cablu (rugina) cu
        axa la Y = 17,9 (raza efectiva 13 m in joc).
    11. Cablul de ridicare pe deasupra bratului, de la roata din cap la roata
        din varf (negru, subtire) -- pe planșa; se roteste cu bratul.
    12. Trosa: 2 fire de la roata din varf la mufla (negru), mufla de rugina si
        CARLIGUL de rugina (tija + incovoietura in J), cu talpa la Z -0,40:
        cablul desenat de cod porneste din Z 0 sub varf, deci iese din carlig.
    13. Ce iese din contur: pe X nimic peste 1,78 m de axa; pe Y Blender
        picioarele din spate pana la -7,85 (inafara colizorului 3,6 x 3,6 al
        codului, dar departe de drum); bratul pana la ~Y 18,3.
    14. Culori: vopsea DRY_VEGETATION, rugina RUST_METAL, cabluri/bolt
        VOLCANIC_BLACK, papuci LOG_DARK. Fara bloc, fara cablul sarcinii, fara
        cablurile de la varf la baza (le-ar rupe rotatia bratului), fara text.
    """
    mast, jib = Builder(), Builder()
    P, R, K, D = CRR_PAINT, CRR_RUST, CRR_BLACK, LOG_DARK
    W = DK_LEG_W

    # --- 2. baza ---------------------------------------------------------------
    zb, zc = 0.18, 0.30                          # talpa papucilor, inaltimea barnei
    y_lo, y_hi = DK_Y_BACK - 0.45, DK_Y_FRONT + 0.45
    for s in (-1, 1):
        mast.box((s * DK_X_B, (y_lo + y_hi) / 2, zb + zc / 2), (0.52, y_hi - y_lo, zc), P)
    for yy in (DK_Y_FRONT, (DK_Y_FRONT + DK_Y_BACK) / 2, DK_Y_BACK):
        mast.box((0.0, yy, zb + zc / 2 + 0.02), (2 * DK_X_B - 0.52, 0.46, zc - 0.04), P)
    for sx in (-1, 1):
        for yy in (DK_Y_FRONT, DK_Y_BACK):
            # 0,90 pe Y: papucul din fata se opreste la Y 1,75 (garda: <= 1,8)
            mast.box((sx * (DK_HALF - 0.33), yy, zb / 2), (0.66, 0.90, zb), D)

    # --- 1. picioarele ----------------------------------------------------------
    for sx in (-1, 1):
        for fr in (True, False):
            # up=(0,1,0): fetele piciorului raman paralele cu X (in romb, coltul
            # ar iesi din banda de +-1,8 m)
            mast.beam(_dk_leg(sx, fr, DK_Z_LEG0 - 0.05), _dk_leg(sx, fr, DK_Z_LEG1 + 0.2),
                      W, P, up=(0, 1, 0))

    # --- 3. braul si contravantuirile --------------------------------------------
    z_mid = 9.2
    for fr in (True, False):
        mast.beam(_dk_leg(-1, fr, z_mid), _dk_leg(1, fr, z_mid), 0.38, P)
    for sx in (-1, 1):
        mast.beam(_dk_leg(sx, True, z_mid), _dk_leg(sx, False, z_mid), 0.38, P, up=(1, 0, 0))
        for fr in (True, False):
            c = _dk_leg(sx, fr, z_mid)
            mast.box(tuple(c), (0.95, 0.95, 0.70), P)               # placa de imbinare
    z_lo = DK_Z_LEG0 + 0.30
    zt = z_mid - 0.25
    for sx in (-1, 1):                                           # fetele laterale
        mast.beam(_dk_leg(sx, True, z_lo), _dk_leg(sx, False, zt), 0.28, P, up=(1, 0, 0))
        mast.beam(_dk_leg(sx, False, z_lo), _dk_leg(sx, True, zt), 0.28, P, up=(1, 0, 0))
    mast.beam(_dk_leg(-1, True, z_lo), _dk_leg(1, True, zt), 0.28, P)     # fata din fata
    mast.beam(_dk_leg(1, True, z_lo), _dk_leg(-1, True, zt), 0.28, P)

    # --- 4. capul ----------------------------------------------------------------
    mast.box((0.0, 0.0, 21.30), (2.30, 2.30, 1.20), P)
    mast.box((0.0, 0.0, 21.975), (1.90, 1.90, 0.15), R)            # varful: 22,05

    # --- 5. troliul ---------------------------------------------------------------
    yw = DK_Y_BACK + 1.6
    mast.cylinder((0.0, yw, 0.95), 0.40, 1.80, R, segments=10, axis="X")
    mast.cylinder((0.0, yw, 0.95), 0.47, 1.30, K, segments=10, axis="X")
    for s in (-1, 1):
        mast.box((s * 1.0, yw, 0.75), (0.14, 0.80, 0.70), R)

    # --- 6. pete de rugina pe picioare (fata exterioara pe X) ------------------
    for sx, fr, z0, z1 in ((1, True, 2.6, 6.0), (-1, False, 12.0, 15.2),
                           (1, False, 15.8, 18.6), (-1, True, 4.0, 6.4)):
        p, q = _dk_leg(sx, fr, z0), _dk_leg(sx, fr, z1)
        off = Vector((sx * (W / 2 + 0.006), 0.0, 0.0))
        mast.beam(p + off, q + off, (0.02, W * 0.62), R, up=(0, 1, 0))

    # =============================== Jib =========================================
    # --- 7. coroana + urechi -------------------------------------------------------
    jib.cylinder((0.0, 0.0, 0.175), 0.85, 0.35, R, segments=12)
    for s in (-1, 1):
        jib.box((s * 0.73, 0.25, 1.00), (0.14, 1.15, 1.40), P)
    jib.cylinder((0.0, 0.35, 1.05), 0.14, 1.65, K, segments=8, axis="X")

    # --- 8. roata din cap -----------------------------------------------------------
    jib.cylinder((0.0, -0.35, 1.05), 0.58, 0.24, R, segments=12, axis="X")

    # --- 9. bratul -------------------------------------------------------------------
    sheave = Vector((0.0, DK_REACH, DK_TIP_Z))
    root = Vector((0.0, 0.35, 1.05))
    tip = Vector((0.0, DK_REACH - 0.40, DK_TIP_Z - 0.05))
    taper_box(jib, root, tip, 1.30, 1.40, 0.85, 0.90, P)
    ax = (tip - root).normalized()
    nrm = Vector((1, 0, 0)).cross(ax).normalized()
    if nrm.z < 0:
        nrm = -nrm

    def sec(f):
        return 1.30 + (0.85 - 1.30) * f, 1.40 + (0.90 - 1.40) * f

    for f, ln in ((0.30, 1.2), (0.64, 1.0)):                   # placi de imbinare
        c = root + (tip - root) * f
        ww, hh = sec(f)
        jib.beam(c - ax * ln / 2, c + ax * ln / 2, (ww + 0.08, hh + 0.08), P, up=tuple(nrm))
    for s, f0, f1, dz in ((1, 0.42, 0.58, 0.15), (1, 0.70, 0.86, -0.1),
                          (-1, 0.12, 0.24, -0.05), (-1, 0.47, 0.60, 0.12)):
        p = root + (tip - root) * f0
        q = root + (tip - root) * f1
        ww, hh = sec((f0 + f1) / 2)
        off = Vector((s * (ww / 2 + 0.006), 0.0, 0.0)) + nrm * dz
        jib.beam(p + off, q + off, (0.02, hh * 0.55), R, up=(1, 0, 0))

    # --- 10. capul bratului + roata ---------------------------------------------------
    for s in (-1, 1):
        jib.box((s * 0.48, DK_REACH - 0.05, DK_TIP_Z - 0.05), (0.14, 1.05, 1.30), P)
    jib.cylinder(tuple(sheave), 0.42, 0.32, R, segments=12, axis="X")
    jib.cylinder(tuple(sheave), 0.11, 0.94, K, segments=8, axis="X")

    # --- 11. cablul de pe brat ----------------------------------------------------------
    jib.beam(Vector((0.0, -0.35, 1.05 + 0.58)), sheave + Vector((0.0, -0.12, 0.42)), 0.09, K)

    # --- 12. trosa, mufla, carligul ------------------------------------------------------
    y = DK_REACH
    for s in (-1, 1):
        jib.beam((s * 0.13, y, sheave.z - 0.30), (s * 0.13, y, 1.30), 0.08, K)
    jib.box((0.0, y, 0.98), (0.44, 0.36, 0.70), R)                  # mufla
    jib.cylinder((0.0, y, 1.10), 0.26, 0.50, R, segments=10, axis="X")
    hook = [(0.0, y, 0.66), (0.0, y, 0.20)]
    cz, r = -0.11, 0.24
    for deg in (90, 135, 180, 225, 270, 315, 350, 20):
        a = math.radians(deg)
        hook.append((0.0, y - r * math.cos(a), cz + r * math.sin(a)))
    polyline_beam(jib, hook, 0.11, R, up=(1, 0, 0))

    return [jib.to_object("Jib"), mast.to_object("TowerCrane")]


# ---------------------------------------------------------------------------
# marble_block_hooked  (CraneHazard.slab_model)
# ---------------------------------------------------------------------------

MB_X, MB_Y, MB_Z = 4.6, 2.2, 2.99      # SLAB_SIZE (Godot X, Z, Y) -> Blender X, Y, Z
MB_TOP = -0.06                         # SLAB_TOP_OFFSET
MB_T = 0.035                           # grosimea chingii

AO_BLOCK = dict(samples=16, dist=1.2, gradient="vertical", low=0.80, high=1.0,
                power=0.7, floor=0.5, z_range=(-3.05, 0.0))


def build_marble_block_hooked():
    """LISTA DE ELEMENTE (decuparea `marble_block_hooked.png`, scrisa INAINTE de
    geometrie; contractul SLAB_SIZE suprascrie planșa la cote):

     1. Blocul: umple anvelopa 4,6 x 2,99 x 2,2 m (X x Y x Z Godot) de la Y
        -0,06 la -3,05 sub origine. Pe planșă se vede ca un pachet de dale:
        rosturi orizontale (3 randuri) si o rostura verticala pe fata lata,
        deci 6 blocuri (2 coloane x 3 randuri) cu rosturi de 4 cm, muchii vii.
        Planșa e aproape cub (l/h ~1); SLAB_SIZE da 4,6 / 2,99 = 1,54: abatere
        de proportie impusa de colizorul din cod.
        Unde sunt chingile (fata, spatele, talpa) blocul se retrage cu
        grosimea chingii, ca blocul + chingile sa umple anvelopa exact.
     2. Patina: randul de jos (treimea de jos) pe `Block_MarbleBase`.
     3. Chingile: DOUA chingi (0,22 m) de rugina, pe fata si pe spate la
        X +-1,15 (ca pe planșa: doua benzi verticale pe fata lata), pe sub
        talpa, iar sus urca in diagonala spre inel. Pe planșă se incruciseaza
        DEASUPRA blocului, in piramida spre carlig; contractul lasa doar 6 cm
        peste bloc (cablul codului porneste din origine), deci piramida e
        culcata pe fata de sus: patru fasii diagonale care se intalnesc in
        centru, adica „incrucisate" in vedere de sus. ABATERE de silueta.
     4. Inelul carligului: tor culcat pe fata de sus, cu varful exact la Y 0
        (punctul de agatare = originea), pe o placa de rugina. Rola si
        carligul de deasupra din planșă sunt ale derrick-ului / cablului.
     5. Marcajul de vopsea: o dunga de 10 cm LAVA_ORANGE pe capatul +X.
     6. Venele portocalii din planșă NU sunt geometrie (clasa carrara_marble).
    """
    marble, base, strap, paint = Builder(), Builder(), Builder(), Builder()
    t = MB_T
    hx, hy = MB_X / 2, MB_Y / 2
    z_bot, z_top = MB_TOP - MB_Z, MB_TOP
    zb_in = z_bot + t                    # blocul se retrage sub chingi
    yi = hy - t
    xi = hx                              # capetele +-X: fara chingi, blocul umple anvelopa
    gap = 0.04
    zr = [zb_in + (z_top - zb_in) * k / 3.0 for k in range(4)]    # 3 randuri
    for (x0, x1) in ((-xi, -gap / 2), (gap / 2, xi)):
        for k in range(3):
            z0 = zr[k] + (gap / 2 if k > 0 else 0.0)
            z1 = zr[k + 1] - (gap / 2 if k < 2 else 0.0)
            # randul de jos = patina (treimea de jos), restul in lumina
            marble_box(marble, base, (x0, -yi, z0), (x1, yi, z1),
                       base_top=(z1 + 0.01) if k == 0 else None)

    # --- 3. chingile ----------------------------------------------------------------
    w = 0.22
    xs = 1.15
    for sx in (-1, 1):
        strap.box((sx * xs, 0.0, z_bot + t / 2), (w, MB_Y, t), CRR_RUST)            # talpa
        for sy in (-1, 1):
            strap.box((sx * xs, sy * (hy - t / 2), (z_bot + z_top) / 2),
                      (w, t, MB_Z), CRR_RUST)                                       # fata/spate
            p = Vector((sx * xs, sy * (hy - 0.16), z_top + t / 2))
            q = Vector((0.0, 0.0, z_top + t / 2))
            strap.beam(p, q, (w, t), CRR_RUST, up=(0, 0, 1))                        # diagonala
    strap.box((0.0, 0.0, z_top + 0.01), (0.62, 0.62, 0.02), CRR_RUST)               # placa
    strap.torus((0.0, 0.0, -0.035 * math.sin(math.pi / 3)), 0.30, 0.035, CRR_RUST, major_seg=12, minor_seg=6)

    # --- 5. marcajul -----------------------------------------------------------------
    paint.box((hx - 0.004, 0.0, z_bot + MB_Z * 0.62), (0.012, 1.40, 0.10), LAVA_ORANGE)

    return [marble.to_object("Block_Marble"), base.to_object("Block_MarbleBase"),
            strap.to_object("Block_Strap"), paint.to_object("Block_Paint")]


# lizza_sled  (RockfallHazard, roll_model = false)
# ---------------------------------------------------------------------------

LZ_W, LZ_L = 2.4, 2.4       # amprenta (X, Y Blender) = cotele validate de probe_carrara_sled.
                            # Runda 2 a incercat 2,6 pe lungime (toleranta kitului): sfera a
                            # crescut la r 1,30 si sonda a picat „timp pierdut" (1,64 > 1,6 s).
LZ_SOLE = 0.40              # talpa: patina + traverse
LZ_BLOCK = 2.0              # blocul

AO_SLED = dict(samples=16, dist=0.9, gradient="vertical", low=0.62, high=1.0,
               power=0.7, floor=0.4, z_range=(0.0, 2.5))


def build_lizza_sled():
    """LISTA DE ELEMENTE (decuparea `lizza_sled.png`, scrisa INAINTE de
    geometrie; cotele din kit §1.1 / `probe_carrara_sled.gd` suprascriu planșa):

     1. Doua TALPI groase de barna pe Y (botul pe +Y Blender = -Z Godot =
        directia de mers), la X +-0,80, 0,42 lat, 0,25 inalt, lungi de 2,4 m,
        cu varful din fata RIDICAT la 0,60 m pe ultimii 0,50 m (runda 2 le
        lungise la 2,6 si a picat sonda sanii; vezi LZ_L). Planșa
        arata o sanie lunga (~2,5:1); contractul cere amprenta PATRATA
        2,4 x 2,4 (sfera de coliziune = max(X,Z)/2), deci sania e scurta:
        abatere de proportie impusa de cod.
     2. 5 TRAVERSE pe X peste talpi (0,30 x 0,15), cu capetele iesite peste
        talpi pana la +-1,2 (planșa: capetele ies in lateral, lungimi usor
        diferite). Talpa + traversele = 0,40 m.
     3. Coltare de fier (LOG_DARK) pe fata exterioara a talpilor, la fiecare
        traversa (planșa: legaturi metalice inchise la imbinari).
     4. Blocul: 2,0 m cub pe traverse, din 4 blocuri (2 coloane x 2 randuri,
        rosturi de 4 cm) ca pe planșa; patina pe treimea de jos
        (`Sled_MarbleBase`), restul `Sled_Marble`.
     5. FUNII groase (0,09 m) incrucisate: doua pe Y la X +-0,55 (urca pe fata,
        trec peste bloc, coboara pe spate pana la traverse) si una pe X la
        mijloc (urca pe laterale) -- se incruciseaza pe fata de sus. Pe planșa
        funia e canepa deschisa; aici LOG_DARK (lemnul „umbrit" din tabelul de
        sloturi), ca sa se citeasca pe marmura crem: abatere de nuanta.
     6. Ce iese din contur: nimic peste 2,4 x 2,4; inaltimea totala ~2,5 cu
        funiile de pe bloc.
    """
    wood, rope, marble, base = Builder(), Builder(), Builder(), Builder()
    W, D = WOOD, LOG_DARK
    hw, hl = LZ_W / 2, LZ_L / 2

    # --- 1. talpile (profil convex: varful din fata ridicat) -----------------
    for sx in (-1, 1):
        pts = []
        for dx in (-0.21, 0.21):
            for (yy, zz) in ((-hl, 0.0), (hl - 0.50, 0.0), (hl, 0.32), (hl, 0.60),
                             (hl - 0.32, 0.48), (-hl, 0.25)):
                pts.append(Vector((sx * 0.80 + dx, yy, zz)))
        _hull(wood, pts, W)

    # --- 2. traversele ----------------------------------------------------------
    for yy, ln in ((-0.98, 2.40), (-0.49, 2.28), (0.0, 2.40), (0.49, 2.32), (0.90, 2.40)):
        wood.box((0.0, yy, 0.315), (ln, 0.32, 0.17), W)
        # --- 3. coltarele -------------------------------------------------------
        for sx in (-1, 1):
            wood.box((sx * 1.025, yy, 0.17), (0.03, 0.36, 0.30), D)

    # --- 4. blocul --------------------------------------------------------------
    g = 0.04
    z0, z1 = LZ_SOLE, LZ_SOLE + LZ_BLOCK
    zm = (z0 + z1) / 2
    base_top = z0 + LZ_BLOCK / 3.0
    hb = LZ_BLOCK / 2
    for (x0, x1) in ((-hb, -g / 2), (g / 2, hb)):
        for (za, zb) in ((z0, zm - g / 2), (zm + g / 2, z1)):
            marble_box(marble, base, (x0, -hb, za), (x1, hb, zb), base_top=base_top)

    # --- 5. funiile ----------------------------------------------------------------
    t = 0.09
    zt = z1 + t / 2
    for sx in (-1, 1):
        x = sx * 0.55
        polyline_beam(rope, [(x, 1.16, 0.42), (x, hb + t / 2, z1 - 0.05), (x, hb, zt),
                             (x, -hb, zt), (x, -hb - t / 2, z1 - 0.05), (x, -1.16, 0.42)],
                      t, D, up=(1, 0, 0))
    polyline_beam(rope, [(1.16, 0.0, 0.42), (hb + t / 2, 0.0, z1 - 0.05), (hb, 0.0, zt + 0.02),
                         (-hb, 0.0, zt + 0.02), (-hb - t / 2, 0.0, z1 - 0.05), (-1.16, 0.0, 0.42)],
                  t, D, up=(0, 1, 0))

    return [wood.to_object("Sled_Wood"), rope.to_object("Sled_Rope"),
            marble.to_object("Sled_Marble"), base.to_object("Sled_MarbleBase")]


# ---------------------------------------------------------------------------
# block_informe_a  (RockfallHazard, rostogolire)
# ---------------------------------------------------------------------------

AO_INFORME = dict(samples=24, dist=1.2, gradient="none", floor=0.5)


def _clipped_box(lo, hi, cuts):
    """Varfurile unei cutii [lo, hi] taiate de plane: fiecare taietura e
    (normala, adancime) si retează coltul / muchia spre care arata normala cu
    `adancime` metri, masurat de la punctul cel mai departat al formei curente.
    Fete PLANE mari (fațete de spartura), nu zgomot. Intoarce punctele formei
    convexe ramase (invelitoarea lor = forma)."""
    import bmesh as _bm
    bm = _bm.new()
    c = (Vector(lo) + Vector(hi)) * 0.5
    s = Vector(hi) - Vector(lo)
    _bm.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(c) @ Matrix.Diagonal(s.to_4d()))
    for n, depth in cuts:
        n = Vector(n).normalized()
        far = max(n.dot(v.co) for v in bm.verts)
        _bm.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=1e-5,
                             plane_co=n * (far - depth), plane_no=n, clear_outer=True)
    pts = [v.co.copy() for v in bm.verts]
    bm.free()
    return pts


def build_block_informe_a():
    """LISTA DE ELEMENTE (decuparea `block_informe_a.png`, scrisa INAINTE de
    geometrie; runda 2 dupa ce runda 1 -- 3 mase convexe -- a iesit o „piine"
    neteda fata de planșa, care e un MANUNCHI de prisme sparte cu crapaturi):

     1. Masa: ~3 m pe fiecare directie, amprenta aproape PATRATA (X ~ Y
        Blender = X ~ Z Godot: raza sferei e max(X,Z)/2).
     2. Miezul: o cutie de 2,5 m (usor retezata) care umple interiorul, ca prin
        crapaturi sa se vada marmura, nu cer.
     3. Fragmentele: 3 x 3 coloane in plan (rosturi la pozitii aleatoare), pe
        2 randuri, 18 prisme cu 2-4 TESITURI DE COLT spre exterior (fațete de
        15-35% din latura) si decalate cu 2-7 cm intre ele:
        CRAPATURILE dintre ele sunt rosturile in V din planșă. Randul de sus are
        inaltimi diferite (varful in trepte, ca pe planșa).
     4. Fete TAIATE DREPT: talpa (nicio taietura cu normala in jos pe randul de
        jos), fata +X si fata -Y (fragmentele de pe acele laturi nu primesc
        taieturi spre ele) -- trei fete plane mari, cu rosturile vizibile.
     5. Un singur nod `Informe_Marble` (CORAL_SAND; clasa carrara_marble la
        integrare). Fara patina de baza: piesa se rostogoleste, o baza gri ar
        ajunge sus. Venele si dungile de fir din planșă vin din clasa.
    """
    import random
    rnd = random.Random(23)
    m = Builder()
    H = 3.0
    core = _clipped_box((-1.15, -1.10, 0.05), (1.15, 1.10, 2.25),
                        [((1, 1, 1), 0.3), ((-1, 1, 1), 0.3), ((-1, -1, 1), 0.3), ((1, -1, 1), 0.3)])
    _hull(m, core, CRR_MARBLE)
    xs = [-1.52, -0.55 + rnd.uniform(-0.12, 0.12), 0.50 + rnd.uniform(-0.12, 0.12), 1.52]
    ys = [-1.48, -0.50 + rnd.uniform(-0.12, 0.12), 0.48 + rnd.uniform(-0.12, 0.12), 1.48]
    for i in range(3):
        for j in range(3):
            z_split = 1.25 + rnd.uniform(-0.25, 0.25)
            z_tops = [z_split, H - rnd.uniform(0.0, 0.55) - (0.25 if (i, j) in ((0, 2), (2, 2)) else 0.0)]
            z_bots = [0.0, z_split]
            for k in range(2):
                g = rnd.uniform(0.02, 0.07)
                lo = Vector((xs[i] + g, ys[j] + g, z_bots[k] + (g if k else 0.0)))
                hi = Vector((xs[i + 1] - g, ys[j + 1] - g, z_tops[k] - g))
                # pe ce parte da fragmentul in afara
                ox = -1 if i == 0 else (1 if i == 2 else 0)
                oy = -1 if j == 0 else (1 if j == 2 else 0)
                oz = 1 if k == 1 else -1
                # runda 3: doar TESITURI DE COLT spre exterior (toate trei
                # componentele, adancimea <= 35% din latura cea mica): runda 2,
                # cu plane aproape paralele cu o fata, lasa aschii subtiri care
                # ieseau ca niste aripi din masa.
                dims = hi - lo
                dmin = min(dims.x, dims.y, dims.z)
                cuts = []
                for _ in range(rnd.randint(2, 4)):
                    nx = (ox if ox else rnd.choice((-1, 1))) * rnd.uniform(0.5, 1.0)
                    ny = (oy if oy else rnd.choice((-1, 1))) * rnd.uniform(0.5, 1.0)
                    nz = (oz if k == 1 else rnd.choice((0.4, 1.0))) * rnd.uniform(0.5, 1.0)
                    if ox == 1 and rnd.random() < 0.6:    # fata +X taiata cu fir
                        nx = -abs(nx)
                    if oy == -1 and rnd.random() < 0.6:   # fata -Y taiata cu fir
                        ny = abs(ny)
                    if k == 0:                            # talpa taiata cu fir
                        nz = abs(nz)
                    cuts.append(((nx, ny, nz), rnd.uniform(0.15, 0.35) * dmin))
                pts = _clipped_box(tuple(lo), tuple(hi), cuts)
                _hull(m, pts, CRR_MARBLE)
    return [m.to_object("Informe_Marble")]


# ---------------------------------------------------------------------------
# quarry_excavator  (ExcavatorHazard) -- rigul lui vehicles/rusted_digger.glb
# ---------------------------------------------------------------------------

# Cotele rigului, masurate pe rusted_digger.glb (Godot -> Blender: X=X, Y=-Z, Z=Y)
EX_BODY_X = 1.95                    # body: X -1,95..1,95
EX_BODY_Y = (-2.48, 2.45)           # body: Godot Z -2,45..2,48 -> Blender Y -2,48..2,45
EX_BODY_H = 3.73                    # body: Y 0..3,73
EX_PIVOT = (0.55, 0.42, 1.95)       # arm: pivotul in Blender (Godot (0,55; 1,95; -0,42))
# bratul COBORAT, in spatiul pivotului (Godot X 0,09..1,01, Y 0,92..3,76, Z -5,70..-0,32)
EX_ARM_HX = 0.46                    # X -0,46..0,46
EX_ARM_Y = (-0.10, 5.28)            # Y Blender local
EX_ARM_Z = (-1.03, 1.81)            # Z local
EX_TRACK_W = 0.75                   # latimea senilei
EX_TRACK_H = 0.95                   # inaltimea senilei

AO_EX_BODY = dict(samples=16, dist=1.0, gradient="vertical", low=0.62, high=1.0,
                  power=0.8, floor=0.38, z_range=(0.0, EX_BODY_H))
AO_EX_ARM = dict(samples=16, dist=0.8, gradient="vertical", low=0.62, high=1.0,
                 power=0.8, floor=0.4, z_range=(-EX_PIVOT[2], EX_BODY_H - EX_PIVOT[2] + 0.05))


def _track_belt(black, x, y0, y1, h, w, n_shoes=36):
    """Senila: zale (cutii) asezate pe perimetrul unui „stadion" in planul YZ
    (doua drepte + doua semicercuri), tangente la el; fiecare za iese 4 cm in
    afara (pintenul). Lungimea pe Y = y1 - y0, inaltimea h."""
    r = h / 2
    ca, cb = y0 + r, y1 - r                 # centrele semicercurilor
    straight = cb - ca
    per = 2 * straight + 2 * math.pi * r
    for k in range(n_shoes):
        s = per * (k + 0.5) / n_shoes
        if s < straight:                                        # jos, spre +Y
            p, a = Vector((x, ca + s, 0.065)), -math.pi / 2
        elif s < straight + math.pi * r:                        # fata
            t = (s - straight) / r
            a = -math.pi / 2 + t
            p = Vector((x, cb + (r - 0.08) * math.cos(a), r + (r - 0.08) * math.sin(a)))
        elif s < 2 * straight + math.pi * r:                    # sus, spre -Y
            p, a = Vector((x, cb - (s - straight - math.pi * r), h - 0.065)), math.pi / 2
        else:                                                   # spate
            t = (s - 2 * straight - math.pi * r) / r
            a = math.pi / 2 + t
            p = Vector((x, ca + (r - 0.08) * math.cos(a), r + (r - 0.08) * math.sin(a)))
        rot = Matrix.Rotation(a + math.pi / 2, 3, "X")
        black.box(tuple(p), (w, per / n_shoes * 0.86, 0.12), CRR_BLACK, rotation=rot)
    # banda interioara continua (sa nu se vada prin zale)
    pts = []
    for yy in (ca, cb):
        for k in range(9):
            a = math.pi * k / 8
            for dx in (-w * 0.45, w * 0.45):
                pts.append(Vector((x + dx, yy + (r - 0.12) * math.cos(a) * (1 if yy == cb else -1),
                                   r + (r - 0.12) * math.sin(a) * 1.0)))
                pts.append(Vector((x + dx, yy + (r - 0.12) * math.cos(a) * (1 if yy == cb else -1),
                                   r - (r - 0.12) * math.sin(a))))
    _hull(black, pts, CRR_BLACK)


def build_quarry_excavator():
    """LISTA DE ELEMENTE (decuparea `quarry_excavator.png` + `_b`, scrisa
    INAINTE de geometrie; corecturile kitului §1.1: FURCA nu cupa, rigul lui
    rusted_digger, culori 13 + 10 + 20). Ierarhia: `body` (nod gol) cu
    `Body_Paint`, `Body_Rust`, `Body_Black` si `arm` (nod gol pe pivot, COPIL
    al lui body) cu `Arm_Paint`, `Arm_Rust`, `Arm_Black`.

    body (AABB fara arm: X +-1,95, Y Blender -2,48..2,45, Z 0..3,73):
     1. Doua SENILE (0,75 lat, 0,95 inalt, toata lungimea de 4,93): 36 de zale
        negre cu pinten pe perimetru, banda interioara; pe fata exterioara roata
        de intindere (fata) si roata motoare (spate) de rugina si 4 role jos;
        cadrul senilei vopsit, cu pete de praf (SAND_SHADOW).
     2. Sasiul dintre senile (rugina) si coroana de rotire neagra.
     3. Platforma (casa): fusta ingusta (X +-1,45) sub corpul lat (X +-1,6),
        ca linie de umbra, cu grila motorului (3 lamele negre) pe flancuri; CONTRAGREUTATEA rotunjita in spate (planșa:
        spatele gros, rotunjit).
     4. Capota motorului pe spate, cu BALUSTRADA de rugina deasupra (planșa:
        maner/balustrada pe capota) si cosul de esapament (rugina) -- cosul e
        punctul cel mai inalt al corpului, 3,73.
     5. CABINA pe stanga-fata (-X): cadru vopsit, geamuri negre (fata, lateral,
        spate), acoperis. Cutia de scule pe dreapta-fata, langa piciorul
        bratului.
     6. Suportul bratului: doi obraji vopsiti de o parte si de alta a
        piciorului bratului, la X 0,55.

    arm (pivot in (0,55; 0,42; 1,95) Blender; coborat; X +-0,46, Y -0,10..5,28,
    Z -1,03..1,81 in spatiul pivotului = cutia fixa din ExcavatorHazard):
     7. BOOM-ul in doua tronsoane (urca si se indoaie: „banana" din planșă),
        cu articulatia cotului ca punct cel mai inalt.
     8. STICK-ul care coboara din cot spre furca.
     9. Cilindri hidraulici negri cu tije de rugina: doi la boom (pe flancuri),
        unul pe spatele boom-ului spre stick, unul pe stick spre furca.
    10. Furtunuri negre pe flancurile boom-ului.
    11. FURCA: traversa de rugina (0,92 lat = toata latimea brațului) si DOUA
        COARNE lungi (~1,3 m) de rugina, coborate si date spre inainte, cu
        varfurile negre (planșa: coarnele intunecate la capat). Nu cupa.
    12. Culori: vopsea DRY_VEGETATION (nu galbenul planșei), rugina RUST_METAL,
        negru VOLCANIC_BLACK; fara text, numere, logo-uri (planșa are inscriptii
        pe capota: nu se modeleaza).
    """
    bp, br, bk = Builder(), Builder(), Builder()
    ap, ar, ak = Builder(), Builder(), Builder()
    P, R, K = CRR_PAINT, CRR_RUST, CRR_BLACK
    y0, y1 = EX_BODY_Y
    xt = EX_BODY_X - EX_TRACK_W / 2          # axa senilei

    # --- 1. senilele -----------------------------------------------------------
    for sx in (-1, 1):
        _track_belt(bk, sx * xt, y0, y1, EX_TRACK_H, EX_TRACK_W)
        xo = sx * (xt + EX_TRACK_W / 2 - 0.10)               # fata exterioara, retrasa
        bp.box((sx * xt, (y0 + y1) / 2, 0.47), (EX_TRACK_W - 0.18, 3.5, 0.42), P)   # cadru
        bp.box((xo + sx * 0.02, -0.4, 0.40), (0.02, 1.6, 0.18), CRR_DUST)          # praf
        for yy in (y1 - 0.475, y0 + 0.475):
            br.cylinder((xo, yy, 0.475), 0.33, 0.14, R, segments=12, axis="X")
            bk.cylinder((xo + sx * 0.07, yy, 0.475), 0.10, 0.06, K, segments=8, axis="X")
        for k in range(4):
            br.cylinder((xo, -1.2 + k * 0.8, 0.26), 0.15, 0.12, R, segments=10, axis="X")

    # --- 2. sasiu + coroana ---------------------------------------------------------
    br.box((0.0, -0.02, 0.62), (2.3, 2.2, 0.45), R)
    bk.cylinder((0.0, -0.1, 1.05), 1.25, 0.22, K, segments=16)

    # --- 3. platforma + contragreutatea ------------------------------------------------
    # runda 3: platforma in DOUA trepte (fusta ingusta jos, corpul lat sus)
    # -- runda 2 era un singur zid plat de 1,2 m pe flanc, planșa are o linie
    # de umbra sub corp si grile de motor pe flanc
    bp.box((0.0, -0.55, 1.36), (2.9, 3.1, 0.44), P)                 # fusta: Z 1,14..1,58
    bp.box((0.0, -0.55, 1.98), (3.2, 3.3, 0.80), P)                 # corpul: Z 1,58..2,38
    for sx in (-1, 1):
        for k in range(3):                                          # grila motorului
            bk.box((sx * 1.605, -1.45, 1.80 + k * 0.17), (0.02, 1.10, 0.08), K)
        bp.box((sx * 1.455, -0.55, 1.22), (0.02, 2.2, 0.14), CRR_DUST)  # praf pe fusta
    cw = []
    for sx in (-1, 1):
        for zz in (1.18, 2.40):
            cw.append(Vector((sx * 1.60, -1.9, zz)))
            cw.append(Vector((sx * 1.35, y0 + 0.02, zz)))
            cw.append(Vector((sx * 1.62, -2.30, zz)))
    _hull(bp, cw, P)
    bp.box((0.0, y0 + 0.30, 1.40), (2.6, 0.04, 0.10), CRR_DUST)     # praf pe contragreutate

    # --- 4. capota + balustrada + cos ------------------------------------------------------
    bp.box((0.15, -1.30, 2.65), (2.9, 1.75, 0.42), P)               # capota
    bk.box((0.15, -1.30, 2.88), (2.2, 0.9, 0.04), K)                # grila de aerisire
    for xx in (-0.9, 0.9):
        for yy in (-1.95, -0.65):
            br.beam((xx, yy, 2.86), (xx, yy, 3.30), 0.07, R)
        br.beam((xx, -1.98, 3.27), (xx, -0.62, 3.27), 0.08, R)
    br.beam((-0.93, -1.95, 3.27), (0.93, -1.95, 3.27), 0.08, R)
    br.cylinder((1.15, -1.75, 3.28), 0.10, 0.90, R, segments=8)     # cos: varf 3,73
    bk.cylinder((1.15, -1.75, 3.71), 0.07, 0.04, K, segments=8)

    # --- 5. cabina + cutia de scule ------------------------------------------------------------
    bp.box((-0.92, 0.42, 2.98), (1.25, 1.55, 1.06), P)              # cadrul cabinei 2,45..3,51
    bp.box((-0.92, 0.38, 3.55), (1.35, 1.70, 0.08), P)              # acoperis
    bk.box((-0.92, 1.205, 3.05), (1.05, 0.02, 0.78), K)             # parbriz
    bk.box((-1.55, 0.42, 3.08), (0.02, 1.25, 0.70), K)              # geam stanga
    bk.box((-0.29, 0.55, 3.08), (0.02, 1.05, 0.70), K)              # geam dreapta
    bk.box((-0.92, -0.365, 3.12), (1.00, 0.02, 0.55), K)            # luneta
    bp.box((1.28, 0.55, 2.62), (0.64, 1.0, 0.36), P)                # cutia de scule

    # --- 6. suportul bratului ------------------------------------------------------------------
    for xx in (0.04, 1.06):
        bp.box((xx, 0.42, 1.95), (0.07, 0.62, 0.62), P)
    bk.cylinder((0.55, 0.42, 1.95), 0.10, 1.14, K, segments=8, axis="X")  # bolt

    # ============================== arm (spatiul pivotului) ===============================
    hx = EX_ARM_HX
    # --- 7. boom-ul --------------------------------------------------------------------------
    # piciorul porneste la Y +0,14: sectiunea inclinata (~38 grade) ar trece
    # altfel de Y -0,10 (garda masura -0,25 in prima varianta)
    taper_box(ap, (0.0, 0.14, 0.10), (0.0, 1.55, 1.25), 0.60, 0.62, 0.56, 0.58, P)
    taper_box(ap, (0.0, 1.45, 1.22), (0.0, 3.30, 1.42), 0.56, 0.58, 0.50, 0.52, P)
    ap.cylinder((0.0, 3.40, 1.45), 0.36, 0.56, P, segments=12, axis="X")   # cotul: Z 1,81
    ak.cylinder((0.0, 3.40, 1.45), 0.10, 0.70, K, segments=8, axis="X")
    ak.cylinder((0.0, 0.0, 0.0), 0.10, 0.68, K, segments=8, axis="X")       # boltul piciorului

    # --- 8. stick-ul ----------------------------------------------------------------------------
    # runda 2: stick-ul se opreste mai sus (Z +0,30), ca furca sa aiba coarne
    # LUNGI (~1,3 m, ca pe planșa) in aceeasi cutie a bratului
    taper_box(ap, (0.0, 3.40, 1.40), (0.0, 4.60, 0.36), 0.46, 0.50, 0.42, 0.44, P)

    # --- 9. cilindrii ---------------------------------------------------------------------------
    for sx in (-1, 1):
        x = sx * 0.37
        ak.beam((x, 0.12, -0.62), (x, 1.05, 0.30), 0.19, K)              # boom: corp
        ar.beam((x, 1.00, 0.25), (x, 1.75, 0.98), 0.09, R)               # tija, intra sub boom
    ak.beam((0.0, 1.05, 1.42), (0.0, 2.35, 1.62), 0.17, K)               # boom -> stick
    ar.beam((0.0, 2.30, 1.61), (0.0, 3.05, 1.68), 0.08, R)
    ak.beam((0.0, 3.62, 1.30), (0.0, 4.12, 0.78), 0.15, K)               # stick -> furca
    ar.beam((0.0, 4.08, 0.82), (0.0, 4.52, 0.40), 0.07, R)

    # --- 10. furtunurile -------------------------------------------------------------------------
    for sx in (-1, 1):
        polyline_beam(ak, [(sx * 0.31, 0.15, 0.40), (sx * 0.31, 1.50, 1.60),
                           (sx * 0.27, 3.20, 1.73), (sx * 0.26, 3.75, 1.35),
                           (sx * 0.24, 4.45, 0.55)], 0.05, K)

    # --- 11. furca -----------------------------------------------------------------------------------
    ar.box((0.0, 4.64, 0.26), (2 * hx, 0.42, 0.36), R)                  # traversa: X +-0,46
    ak.cylinder((0.0, 4.64, 0.38), 0.09, 2 * hx - 0.04, K, segments=8, axis="X")
    for sx in (-1, 1):
        x = sx * 0.33
        polyline_beam(ar, [(x, 4.66, 0.18), (x, 4.80, -0.40), (x, 4.98, -0.80)],
                      (0.18, 0.16), R, up=(1, 0, 0))
        polyline_beam(ak, [(x, 4.98, -0.80), (x, 5.18, -0.94)], (0.16, 0.13), K, up=(1, 0, 0))

    body = bpy.data.objects.new("body", None)
    bpy.context.collection.objects.link(body)
    arm = bpy.data.objects.new("arm", None)
    bpy.context.collection.objects.link(arm)
    arm.parent = body
    arm.location = EX_PIVOT
    meshes = []
    for b, name, par in ((bp, "Body_Paint", body), (br, "Body_Rust", body), (bk, "Body_Black", body),
                         (ap, "Arm_Paint", arm), (ar, "Arm_Rust", arm), (ak, "Arm_Black", arm)):
        o = b.to_object(name)
        o.parent = par
        meshes.append(o)
    bpy.context.view_layer.update()
    return meshes, [body, arm]


clear_built()
if not ONLY or ONLY == "derrick":
    emit_fixed(build_derrick(), "structures/derrick.glb",
               {"Jib": AO_DK_JIB, "TowerCrane": AO_DK_MAST}, bevel=0.05,
               smooth_angle=40.0)
    clear_built()
if not ONLY or ONLY == "marble_block_hooked":
    emit_fixed(build_marble_block_hooked(), "props/marble_block_hooked.glb",
               {"": AO_BLOCK}, bevel=0.0, smooth_angle=40.0)
    clear_built()
if not ONLY or ONLY == "lizza_sled":
    emit_crr(build_lizza_sled(), "props/lizza_sled.glb", AO_SLED, bevel=0.03,
             bevels={"_Marble": 0.0, "_MarbleBase": 0.0, "_Rope": 0.015}, smooth_angle=40.0)
    clear_built()
if not ONLY or ONLY == "block_informe_a":
    emit_crr(build_block_informe_a(), "rocks/block_informe_a.glb", AO_INFORME, bevel=0.0,
             smooth_angle=20.0)
    clear_built()
if not ONLY or ONLY == "quarry_excavator":
    _ex_meshes, _ex_empties = build_quarry_excavator()
    emit_fixed(_ex_meshes, "vehicles/quarry_excavator.glb",
               {"": AO_EX_BODY, "Arm_Paint": AO_EX_ARM, "Arm_Rust": AO_EX_ARM,
                "Arm_Black": AO_EX_ARM}, bevel=0.03, bevels={"_Black": 0.02},
               smooth_angle=40.0, extra=_ex_empties)
    clear_built()
    for _o in _ex_empties:
        bpy.data.objects.remove(_o, do_unlink=True)
if not ONLY or ONLY == "quarry_truck":
    emit_crr(build_quarry_truck(), "vehicles/quarry_truck.glb", AO_TRUCK,
             bevel=0.035, bevels={"_Marble": 0.0, "_MarbleBase": 0.0, "_Black": 0.03},
             smooth_angle=40.0)
    clear_built()
report_crr()
