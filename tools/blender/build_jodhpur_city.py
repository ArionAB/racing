"""Jodhpur -- Orasul albastru, val 3a (brief §1.4, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/buildings/blue_house_b.glb    3 volume in trepte, rezervor + planta
  jodhpur/buildings/blue_house_c.glb    cub simplu, usa in arc, rezervor
  jodhpur/buildings/blue_house_d.glb    terasa cu balustrada pe tot perimetrul
  jodhpur/buildings/blue_house_e.glb    volum in L, scara pe fata
  jodhpur/buildings/haveli_facade.glb   casa bogata: arcade + balcoane de piatra
  jodhpur/props/rooftop_tank.glb        rezervor negru, nervuri orizontale
  jodhpur/props/rooftop_clutter.glb     placa de terasa cu rufe + oale

Reuseste vocabularul din jodhpur_shapes.py (arch_opening, chajja, solid_stair,
balustrade, railing_on_brackets) si constructia lui blue_house_a (pilot,
ACCEPTATA -- brief spune explicit "reuse its construction"): miez retras pe
fata cu goluri + benzi late pe restul peretelui, ca `arch_opening` sa se
lipeasca flush fara sa z-fighteze cu o cutie plina alaturata.

**Camera:** testul cu cub colorat pe fete al pilotului (v3, blue_house_a) a
gasit ca +X e fata DOMINANTA a camerei `compare()` la azimut/elevatie implicit
(35/18) -- pastram aceeasi conventie pe toate casele astea (aproape cubice, ca
pilotul, nu alungite ca cetatea): fatada principala (usa/scara/arcade) pe +X.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_city.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4) -- identice cu pilotul.
WALL = FOAM_WHITE        # peretele albastru (alb x tenta blue_lime_light/indigo)
TRIM_WOOD = WOOD         # usi
GLOW = VOLCANIC_BLACK    # goluri de geam/usa, ziua inchise
RAIL_WHITE = FOAM_WHITE  # balustrada, FARA tenta (nod separat de perete)
TANK_DARK = LOG_DARK     # rezervoarele negre de pe acoperis
PLANT_GREEN = CACTUS_GREEN
LAUNDRY_YELLOW = CAR_YELLOW
LAUNDRY_PINK = FLAMINGO_PINK

# `low` ridicat fata de pilot (0.46 -> 0.58, runda de corectii): masurat cu
# --compare, fetele SOARE-LUMINATE ale caselor pe 2-3 etaje (blue_house_c/d/e,
# haveli) ieseau la ~55-85% din hex-ul tinta (pilotul blue_house_a atinge
# ~97%) -- aceeasi formula AO, dar volumele mai inalte/mai ingropate (chajja,
# balustrade, tank pe fiecare etaj) se auto-umbresc mai mult pe fetele mari.
# `low` mai ridicat pastreaza gradientul (colturile/firidele tot mai
# inchise), dar nu mai trage fetele plate spre gri-indigo ("iese
# indigo-cenusiu inchis in loc de albastru deschis" -- verdictul liderului).
AO_HOUSE = dict(samples=20, dist=4.0, gradient="vertical",
                low=0.58, high=1.00, power=0.88, floor=0.24)
AO_PROP = dict(samples=16, dist=2.0, gradient="vertical",
               low=0.50, high=1.00, power=0.85, floor=0.20)


def _finish_or_none(obj):
    """Vezi build_jodhpur_pilot.py -- un Builder GLOW poate ramane gol."""
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


def _cheap_arch_opening(b, bg, center, w, h, pier_frac, wall_t, slot, glow_slot,
                        rotation=None, open=False):
    """Gol arcuit IEFTIN pentru piese cu buget mic (haveli, <=900 tri total):
    un dreptunghi cu cele DOUA colturi de sus TAIATE (octogon simplificat),
    in loc de profilul de arc cu `steps` segmente al lui `arch_opening`. La
    30 m in joc un colt tesit citeste ca un arc rotunjit (brief regula 5:
    geometria conteaza doar daca schimba silueta/umbra la acea distanta) --
    fara sa coste cele ~40-60 de fete per gol ale versiunii complete.

    `open=True`: doar o BANDA subtire (jgheab) pe conturul golului, fara
    panou (arcada deschisa a parterului). `open=False`: panou plin in jurul
    golului + firida + placa GLOW retrasa (fereastra inchisa).

    Contur (in planul local XZ, Y=0): octogon cu 6 varfuri -- 2 la baza,
    2 la mijlocul inaltimii (unde incepe taierea), 2 la varf (taiate)."""
    cx, cy, cz = center
    hw = w * 0.5
    pier_h = h * pier_frac
    chamfer = min(hw, h - pier_h)

    def rot_pt(x, y, z):
        p = Vector((x, y, z))
        if rotation is not None:
            m = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            p = m @ p
        return (cx + p.x, cy + p.y, cz + p.z)

    hole = [(-hw, 0.0), (-hw, pier_h), (-hw + chamfer * 0.5, h),
           (hw - chamfer * 0.5, h), (hw, pier_h), (hw, 0.0)]

    if open:
        band_w = wall_t * 0.4
        faces = []
        n = len(hole)
        for i in range(n):
            x0, z0 = hole[i]
            x1, z1 = hole[(i + 1) % n] if i < n - 1 else hole[i]
            if i == n - 1:
                break
            dx, dz = x1 - x0, z1 - z0
            ln = math.hypot(dx, dz) or 1e-6
            nx, nz = -dz / ln, dx / ln
            a0 = (x0 - nx * band_w * 0.5, z0 - nz * band_w * 0.5)
            a1 = (x0 + nx * band_w * 0.5, z0 + nz * band_w * 0.5)
            b0 = (x1 - nx * band_w * 0.5, z1 - nz * band_w * 0.5)
            b1 = (x1 + nx * band_w * 0.5, z1 + nz * band_w * 0.5)
            for y_val, flip in ((wall_t * 0.5, False), (-wall_t * 0.5, True)):
                quad = (a0, b0, b1, a1) if not flip else (a1, b1, b0, a0)
                pts = [rot_pt(x, y_val, z) for x, z in quad]
                faces.append(b.bm.faces.new(tuple(b.bm.verts.new(p) for p in pts)))
        for f in faces:
            if f.is_valid:
                f[b.slot] = slot
        return faces

    # NOTA cost: varianta ieftina renunta la inelul de firida separat
    # (reveal) fata de `arch_opening` -- glow-ul sta chiar la fata peretelui
    # (fara adancime de firida), ceea ce economiseste 5 fete/gol (x6 ferestre
    # = 30 fete, semnificativ la un buget de 900). La aceasta scara (ferestre
    # mici, etaj superior) diferenta vizuala e minora -- golul tot citeste
    # inchis la culoare (VOLCANIC_BLACK), doar fara umbra de adancime.
    panel_w, panel_h = w * 2.0, h * 1.25
    hw_panel = panel_w * 0.5
    hole_x0, hole_x1 = -hw, hw
    hole_z0, hole_z1 = 0.0, h
    inner_edge, back_edge = wall_t * 0.5, -wall_t * 0.5
    faces = []

    def flat_rect(x0, x1, z0, z1, y_val, flip):
        if x1 - x0 < 1e-6 or z1 - z0 < 1e-6:
            return None
        pts = [(x0, y_val, z0), (x1, y_val, z0), (x1, y_val, z1), (x0, y_val, z1)]
        if flip:
            pts = list(reversed(pts))
        return b.bm.faces.new(tuple(b.bm.verts.new(rot_pt(*p)) for p in pts))

    def panel_fill(y_val, flip):
        out = []
        f = flat_rect(-hw_panel, hw_panel, hole_z1, panel_h, y_val, flip)
        if f:
            out.append(f)
        f = flat_rect(-hw_panel, hole_x0, hole_z0, hole_z1, y_val, flip)
        if f:
            out.append(f)
        f = flat_rect(hole_x1, hw_panel, hole_z0, hole_z1, y_val, flip)
        if f:
            out.append(f)
        return out

    faces += panel_fill(inner_edge, False)
    faces += panel_fill(back_edge, True)
    for f in faces:
        if f.is_valid:
            f[b.slot] = slot

    glow_outline = [(x * 0.85, z if z < 1e-6 else z * 0.94 + hole_z0 * 0.06) for x, z in hole]
    glow_edge = inner_edge - wall_t * 0.3   # usor retras fata de fata peretelui
    gpts = [rot_pt(x, glow_edge, z) for x, z in glow_outline]
    gf = bg.bm.faces.new(tuple(bg.bm.verts.new(p) for p in gpts))
    if gf.is_valid:
        gf[bg.slot] = glow_slot
    return faces


def _rooftop_tank(b, center, radius=0.6, height=1.4, slot=TANK_DARK, n_ribs=4):
    """Rezervor: cilindru negru cu nervuri orizontale + capac usor bombat.
    Folosit atat ca piesa de sine statatoare (props/rooftop_tank.glb) cat si
    inline pe fiecare casa (blue_house_b/c). `segments` 12 (brief §1.4)."""
    cx, cy, cz = center
    faces = list(b.cylinder((cx, cy, cz + height * 0.5), radius, height, slot,
                            segments=12, axis="Z"))
    rib_h = 0.05
    for i in range(1, n_ribs):
        rz = cz + height * i / n_ribs
        faces += list(b.frustum((cx, cy, rz), radius * 1.04, radius * 1.04,
                                rib_h, slot, segments=12, axis="Z"))
    # capac usor bombat (frustum ingust + disc mic)
    faces += list(b.frustum((cx, cy, cz + height + 0.05), radius * 1.02,
                            radius * 0.55, 0.10, slot, segments=12, axis="Z"))
    faces += list(b.cylinder((cx, cy, cz + height + 0.14), radius * 0.55, 0.08,
                             slot, segments=12, axis="Z"))
    return faces


# --- blue_house_b ------------------------------------------------------------
#
# Contract (brief §1.4): 7x6 m, 3 etaje IN TREPTE, 9,5 m, h/l 1,09, tenta
# light. Element list (decupare blue_house_b.png, RECITITA in runda de
# corectii -- raportul anterior "nicio abatere" era fals, vezi zoom 4x):
#
#   1. Volum 1 (cel mai jos/mai lat, parter): cub simplu, cam 2/3 din
#      amprenta totala, cu 2 usi de lemn (arc rotunjit) vazute pe fata din
#      fata -- usa STANGA (langa tufis) si o a doua usa MAI MARE spre
#      dreapta -- plus 1 FEREASTRA MICA dreptunghiulara intre ele (centrul
#      fetei, mai sus decat usile) -- un tufis verde (planta) in coltul
#      STANGA-JOS langa prima usa.
#   2. Volum 2 (etajul 2, RETRAS spre spate si mai ingust): 2 FERESTRE MICI
#      dreptunghiulare pe fata vizibila din fata (partea stanga a fetei,
#      una langa alta) -- balustrada alba pe marginea din FATA a terasei
#      volumului 1 ramase vizibile.
#   3. Volum 3 (cel mai sus, cel mai ingust, retras SI MAI mult spre spate):
#      cub mic, cu 1 USA de lemn (arc) pe fata din fata (dreapta) si
#      rezervorul NEGRU pe acoperis.
#   Cele 3 volume se vad clar TREPTELE intre ele (fiecare mai retras si mai
#   sus decat cel de dedesubt), nu o piramida continua.
# Silueta: h/l 1,09 (mai inalta decat lata) -- volumele in trepte dau un
# profil zvelt, nu un bloc patrat.
#
# Corectie (runda 2): FEREASTRA lipsa pe volum 1, cele 2 FERESTRE lipsa pe
# volum 2, USA lipsa pe volum 3 -- toate 4 adaugate mai jos cu
# `arch_opening` (glow separat in `bglow`).
HB_W, HB_D = 7.0, 6.0
HB_H = 9.5


def build_blue_house_b():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    br = Builder()
    wall_faces, rail_faces = [], []

    hw, hd = HB_W * 0.5, HB_D * 0.5
    WALL_T = 0.5

    # volum 1: parter, amprenta ~7x6, inaltime 3.6, usi pe fata +X.
    v1_h = 3.6
    core_hw = hw - WALL_T * 0.5
    core_hd = hd - WALL_T * 0.5
    wall_faces += list(b.box((0.0, 0.0, v1_h * 0.5), (core_hw * 2, core_hd * 2, v1_h), WALL))
    band_x = hw - core_hw
    band_d = hd - core_hd
    wall_faces += list(b.box((-(hw - band_x * 0.5), 0.0, v1_h * 0.5),
                             (band_x, core_hd * 2, v1_h), WALL))
    wall_faces += list(b.box((0.0, (hd - band_d * 0.5), v1_h * 0.5),
                             (HB_W, band_d, v1_h), WALL))
    wall_faces += list(b.box((0.0, -(hd - band_d * 0.5), v1_h * 0.5),
                             (HB_W, band_d, v1_h), WALL))
    wall_faces += list(b.box((0.0, 0.0, 0.16), (HB_W + 0.16, HB_D + 0.16, 0.32), WALL))

    # 2 usi in arc rotunjit pe fata +X: usa stanga (langa tufis) + usa mai
    # mare spre dreapta (decupare: cele doua usi NU sunt alaturate -- fereastra
    # dintre ele, vezi mai jos).
    door_rot = Matrix.Rotation(math.radians(-90.0), 3, "Z")
    door_w, door_h = 1.05, 2.3
    for dy in (-1.85, 0.55):
        res_door = arch_opening(b, bg, (hw, dy, 0.0), door_w, door_h,
                                door_h * 0.94, WALL_T, WALL, GLOW, style="round",
                                rotation=door_rot, glass=True, reveal=0.10, glass_depth=0.08,
                                panel_w=1.35, panel_h=door_h * 1.4)
        wall_faces += res_door["stone"]
        for f in res_door["glass"]:
            if f.is_valid:
                f[bg.slot] = TRIM_WOOD

    # fereastra mica dreptunghiulara intre cele 2 usi (mai sus, centrul fetei)
    # -- corectie: lipsea complet (raportul vechi "nicio abatere" era fals).
    res_w1 = arch_opening(b, bglow, (hw, -0.7, 1.5), 0.6, 0.9,
                          0.28, WALL_T, WALL, GLOW, style="round", rotation=door_rot,
                          glass=True, reveal=0.10, panel_w=1.2, panel_h=1.3)
    wall_faces += res_w1["stone"]

    # parapet + chajja pe volumul 1
    for nx, ny, w in ((0, 1, HB_W + 0.5), (0, -1, HB_W + 0.5), (1, 0, HB_D + 0.5), (-1, 0, HB_D + 0.5)):
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        cx, cy = nx * hw, ny * hd
        wall_faces += list(chajja(b, (cx, cy, v1_h), w, 0.45, WALL,
                                  thickness=0.10, slope=0.4, rotation=rot))

    # planta (tufis) in coltul dreapta-jos (fata +X, Y pozitiv) al terasei v1.
    # NU adaugata la wall_faces: acelasi bug/fix ca la rezervor (gasit la
    # --compare -- planta era invizibila, pictata WALL de overwrite-ul
    # general in loc de PLANT_GREEN). Tentata separat, DUPA overwrite.
    plant_faces = []
    plant_c = (hw - 0.5, hd - 0.5, v1_h)
    for i in range(5):
        ang = i * 1.3
        r = 0.16 + 0.05 * (i % 3)
        px = plant_c[0] + math.cos(ang) * r * 0.4
        py = plant_c[1] + math.sin(ang) * r * 0.4
        plant_faces += list(b.box((px, py, plant_c[2] + 0.18 + 0.05 * i),
                                  (0.22, 0.22, 0.30), PLANT_GREEN))

    # volum 2: etaj 2, retras spre spate (Y negativ = spate, fata camerei e +X
    # deci "spate" e -Y), mai ingust, inaltime 3.2
    v2_w, v2_d, v2_h = 5.0, 4.2, 3.2
    v2_hw, v2_hd = v2_w * 0.5, v2_d * 0.5
    v2_cy = -hd + v2_hd + 0.3
    v2_z0 = v1_h
    wall_faces += list(b.box((0.0, v2_cy, v2_z0 + v2_h * 0.5), (v2_w, v2_d, v2_h), WALL))
    wall_faces += list(b.box((0.0, v2_cy, v2_z0 + 0.06), (v2_w + 0.12, v2_d + 0.12, 0.12), WALL))
    for nx, ny, w in ((0, 1, v2_w + 0.4), (0, -1, v2_w + 0.4), (1, 0, v2_d + 0.4), (-1, 0, v2_d + 0.4)):
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        cx, cy = nx * v2_hw, v2_cy + ny * v2_hd
        wall_faces += list(chajja(b, (cx, cy, v2_z0 + v2_h), w, 0.35, WALL,
                                  thickness=0.09, slope=0.4, rotation=rot))
    # 2 ferestre mici pe fata +X a volumului 2 (partea stanga a fetei, una
    # langa alta) -- corectie: lipseau complet. `center` z e absolut (baza
    # golului), fara offset -- `arch_opening` nu recentreaza pe Z.
    v2_win_rot = door_rot
    v2_win_sill = v2_z0 + 0.9
    for wy in (v2_cy - 1.2, v2_cy - 0.15):
        res_w2 = arch_opening(b, bglow, (v2_hw, wy, v2_win_sill),
                              0.55, 0.85, 0.28, WALL_T, WALL, GLOW, style="round",
                              rotation=v2_win_rot, glass=True, reveal=0.10,
                              panel_w=1.1, panel_h=1.2)
        wall_faces += res_w2["stone"]
    # balustrada pe marginea din FATA (+Y) a terasei v1 ramase vizibile,
    # adica intre marginea v1 (+Y) si fata din fata a v2
    terr_y = v2_cy + v2_hd
    rail_faces += list(balustrade(br, (-hw + 0.4, terr_y, v2_z0), (hw - 0.4, terr_y, v2_z0),
                                  0.75, RAIL_WHITE, merlon_w=0.14, merlon_gap=0.10))

    # volum 3: etaj 3, cel mai retras si mai ingust, inaltime 2.7, rezervor pe
    # acoperis + 1 usa de lemn pe fata +X (dreapta) -- corectie: lipsea
    # complet. Miez retras pe +X (ca la v1/v2), banda ingusta umple restul.
    v3_w, v3_d, v3_h = 3.0, 2.6, 2.7
    v3_hw, v3_hd = v3_w * 0.5, v3_d * 0.5
    v3_cy = v2_cy - v2_hd + v3_hd + 0.15
    v3_z0 = v2_z0 + v2_h
    v3_core_hw = v3_hw - WALL_T * 0.5
    wall_faces += list(b.box((-(v3_hw - v3_core_hw), v3_cy, v3_z0 + v3_h * 0.5),
                             (v3_core_hw * 2, v3_d, v3_h), WALL))
    wall_faces += list(b.box((0.0, v3_cy, v3_z0 + 0.05), (v3_w + 0.10, v3_d + 0.10, 0.10), WALL))

    v3_door_w, v3_door_h = 0.85, 1.9
    res_door3 = arch_opening(b, bg, (v3_hw, v3_cy, v3_z0), v3_door_w, v3_door_h,
                             v3_door_h * 0.94, WALL_T, WALL, GLOW, style="round",
                             rotation=door_rot, glass=True, reveal=0.09, glass_depth=0.07,
                             panel_w=v3_d, panel_h=v3_h)
    wall_faces += res_door3["stone"]
    for f in res_door3["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    # NU adaugat la wall_faces: bug real gasit la --compare (rezervorul
    # aparea ALBASTRU in loc de negru) -- overwrite-ul de mai jos
    # (`f[b.slot] = WALL` pe toate fetele din wall_faces) picta peste
    # slotul TANK_DARK deja scris de `_rooftop_tank`. Tank-ul e tentat
    # separat, DUPA overwrite-ul general.
    tank_faces = _rooftop_tank(b, (0.3, v3_cy, v3_z0 + v3_h), radius=0.55, height=1.2)

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL
    for f in tank_faces:
        if f.is_valid:
            f[b.slot] = TANK_DARK
    for f in plant_faces:
        if f.is_valid:
            f[b.slot] = PLANT_GREEN
    trim_obj = bg.to_object("House_Trim")
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    for f in rail_faces:
        if f.is_valid:
            f[br.slot] = RAIL_WHITE
    rail_obj = _finish_or_none(br.to_object("House_Rail"))

    return wall_obj, trim_obj, glow_obj, rail_obj


# --- blue_house_c ------------------------------------------------------------
#
# Contract (brief §1.4): 7x7 m, 2 etaje, 6,5 m, h/l 0,88, tenta light.
# Element list (decupare blue_house_c.png), de jos in sus:
#
#   1. Cub simplu (7x7, 2 etaje) cu parapet plat.
#   2. Usa in arc pe fata din FATA (+X), aproape centrata, usor spre stanga.
#   3. 3 ferestre MICI (nu 2 -- corectie, lipsea a treia): 2 alaturate in
#      STANGA usii (o pereche apropiata), 1 SINGURA in DREAPTA usii.
#   4. Rezervor NEGRU pe acoperis, aproape de colt.
HC_SIDE = 7.0
HC_WALL = 6.5


def build_blue_house_c():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    wall_faces = []
    hs = HC_SIDE * 0.5
    WALL_T = 0.5
    h_wall = 6.0
    parapet_h = HC_WALL - h_wall

    core_hw = hs - WALL_T * 0.5
    wall_faces += list(b.box((0.0, 0.0, h_wall * 0.5), (core_hw * 2, core_hw * 2, h_wall), WALL))
    band = hs - core_hw
    wall_faces += list(b.box((-(hs - band * 0.5), 0.0, h_wall * 0.5), (band, core_hw * 2, h_wall), WALL))
    wall_faces += list(b.box((0.0, (hs - band * 0.5), h_wall * 0.5), (HC_SIDE, band, h_wall), WALL))
    wall_faces += list(b.box((0.0, -(hs - band * 0.5), h_wall * 0.5), (HC_SIDE, band, h_wall), WALL))
    wall_faces += list(b.box((0.0, 0.0, 0.18), (HC_SIDE + 0.18, HC_SIDE + 0.18, 0.36), WALL))
    wall_faces += list(b.box((0.0, 0.0, h_wall + parapet_h * 0.5), (HC_SIDE, HC_SIDE, parapet_h), WALL))
    cornice_z = h_wall + parapet_h
    for nx, ny, w in ((0, 1, HC_SIDE + 0.5), (0, -1, HC_SIDE + 0.5), (1, 0, HC_SIDE + 0.5), (-1, 0, HC_SIDE + 0.5)):
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        cx, cy = nx * hs, ny * hs
        wall_faces += list(chajja(b, (cx, cy, cornice_z), w, 0.4, WALL,
                                  thickness=0.10, slope=0.4, rotation=rot))

    # usa in arc, aproape centrata pe fata +X, usor spre stanga (Y negativ)
    door_rot = Matrix.Rotation(math.radians(-90.0), 3, "Z")
    door_w, door_h = 1.35, 2.5
    door_y = -0.35
    res_door = arch_opening(b, bg, (hs, door_y, 0.0), door_w, door_h,
                            door_h * 0.92, WALL_T, WALL, GLOW, style="round",
                            rotation=door_rot, glass=True, reveal=0.10, glass_depth=0.08,
                            panel_w=2.3, panel_h=door_h * 1.4)
    wall_faces += res_door["stone"]
    for f in res_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD

    # 3 ferestre mici: 2 alaturate in stanga usii (pereche apropiata) + 1 in
    # dreapta -- corectie: lipsea a treia (raportul vechi numara doar 2).
    win_rot = door_rot
    win_z = h_wall * 0.72
    for wy in (-2.5, -1.15, 1.7):
        res_w = arch_opening(b, bglow, (hs, wy, win_z - h_wall * 0.5), 0.65, 0.95,
                             0.3, WALL_T, WALL, GLOW, style="round", rotation=win_rot,
                             glass=True, reveal=0.10, panel_w=1.1, panel_h=1.4)
        wall_faces += res_w["stone"]

    # rezervor negru pe acoperis, aproape de colt -- NU adaugat la
    # wall_faces, acelasi bug/fix ca la blue_house_b (vezi comentariul de
    # acolo): tentat separat, DUPA overwrite-ul general pe WALL.
    tank_faces = _rooftop_tank(b, (hs - 1.1, hs - 1.1, HC_WALL), radius=0.55, height=1.2)

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL
    for f in tank_faces:
        if f.is_valid:
            f[b.slot] = TANK_DARK
    trim_obj = bg.to_object("House_Trim")
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    return wall_obj, trim_obj, glow_obj


# --- blue_house_d ------------------------------------------------------------
#
# Contract (brief §1.4): 7x7 m, 2 etaje + camera pe acoperis, 8,5 m, h/l
# 0,88, tenta INDIGO. Element list (decupare blue_house_d.png), de jos in
# sus:
#
#   1. Cub (7x7, 2 etaje, h~6.0) cu usa mare in arc pe fata +X, aproape
#      centrata, cu 2-3 trepte de piatra in fata usii.
#   2. O fereastra mica sus-stanga pe fata +X.
#   3. Terasa cu BALUSTRADA (grilaj negru, nu alba -- decuparea arata un
#      parapet inchis la culoare) pe TOT PERIMETRUL acoperisului.
#   4. Camera mica de pe acoperis, RETRASA spre spate (Y negativ) -- CORECTIE:
#      decuparea (rezasata) arata clar 1 usa (stanga) + 1 fereastra (dreapta)
#      pe fata ei din fata; comentariul vechi "fara geamuri" era o citire
#      gresita a plansei.
HD_SIDE = 7.0
HD_WALL = 6.0
HD_TOTAL = 8.5


def build_blue_house_d():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    br = Builder()
    wall_faces, rail_faces = [], []
    hs = HD_SIDE * 0.5
    WALL_T = 0.5
    h_wall = HD_WALL

    core_hw = hs - WALL_T * 0.5
    wall_faces += list(b.box((0.0, 0.0, h_wall * 0.5), (core_hw * 2, core_hw * 2, h_wall), WALL))
    band = hs - core_hw
    wall_faces += list(b.box((-(hs - band * 0.5), 0.0, h_wall * 0.5), (band, core_hw * 2, h_wall), WALL))
    wall_faces += list(b.box((0.0, (hs - band * 0.5), h_wall * 0.5), (HD_SIDE, band, h_wall), WALL))
    wall_faces += list(b.box((0.0, -(hs - band * 0.5), h_wall * 0.5), (HD_SIDE, band, h_wall), WALL))
    wall_faces += list(b.box((0.0, 0.0, 0.18), (HD_SIDE + 0.18, HD_SIDE + 0.18, 0.36), WALL))

    # usa mare in arc, aproape centrata
    door_rot = Matrix.Rotation(math.radians(-90.0), 3, "Z")
    door_w, door_h = 1.6, 2.8
    door_y = 0.1
    res_door = arch_opening(b, bg, (hs, door_y, 0.0), door_w, door_h,
                            door_h * 0.90, WALL_T, WALL, GLOW, style="round",
                            rotation=door_rot, glass=True, reveal=0.12, glass_depth=0.09,
                            panel_w=2.6, panel_h=door_h * 1.35)
    wall_faces += res_door["stone"]
    for f in res_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    # 2-3 trepte de piatra in fata usii
    for i, s in enumerate((0.9, 0.6, 0.3)):
        step_y0 = door_y - door_w * 0.5 * s - 0.1
        wall_faces += list(b.box((hs + 0.15 + i * 0.16, door_y, 0.05 + i * 0.0),
                                 (0.16, door_w + 0.4 + i * 0.3, 0.10), WALL))

    # fereastra mica sus-stanga
    win_rot = door_rot
    res_w = arch_opening(b, bglow, (hs, -1.7, h_wall * 0.62 - h_wall * 0.5), 0.7, 1.0,
                         0.32, WALL_T, WALL, GLOW, style="round", rotation=win_rot,
                         glass=True, reveal=0.10, panel_w=1.35, panel_h=1.45)
    wall_faces += res_w["stone"]

    # balustrada NEAGRA (grilaj) pe tot perimetrul acoperisului
    rail_h = 1.0
    rz = h_wall
    corners = [(-hs + 0.15, -hs + 0.15), (hs - 0.15, -hs + 0.15),
              (hs - 0.15, hs - 0.15), (-hs + 0.15, hs - 0.15)]
    for i in range(4):
        p1 = (corners[i][0], corners[i][1], rz)
        p2 = (corners[(i + 1) % 4][0], corners[(i + 1) % 4][1], rz)
        rail_faces += list(railing_on_brackets(br, p1, p2, rail_h, GLOW,
                                               bracket_step=1.4, bracket_out=0.0))

    # camera de pe acoperis, retrasa spre spate (-Y), CU 1 usa (stanga) + 1
    # fereastra (dreapta) pe fata ei din fata (+X) -- corectie: comentariul
    # vechi zicea gresit "fara geamuri", decuparea le arata clar pe amandoua.
    rc_w, rc_d, rc_h = 3.4, 2.8, 2.5
    rc_hw, rc_hd = rc_w * 0.5, rc_d * 0.5
    rc_cy = -hs + rc_d * 0.5 + 0.4
    rc_core_hw = rc_hw - WALL_T * 0.5
    wall_faces += list(b.box((-(rc_hw - rc_core_hw), rc_cy, h_wall + rc_h * 0.5),
                             (rc_core_hw * 2, rc_d, rc_h), WALL))
    wall_faces += list(b.box((0.0, rc_cy, h_wall + 0.05), (rc_w + 0.10, rc_d + 0.10, 0.10), WALL))
    wall_faces += list(b.box((0.0, rc_cy, h_wall + rc_h + 0.06), (rc_w + 0.14, rc_d + 0.14, 0.12), WALL))

    rc_door_w, rc_door_h = 0.8, 1.9
    res_rc_door = arch_opening(b, bg, (rc_hw, rc_cy - 0.6, h_wall), rc_door_w, rc_door_h,
                               rc_door_h * 0.94, WALL_T, WALL, GLOW, style="round",
                               rotation=door_rot, glass=True, reveal=0.09, glass_depth=0.07,
                               panel_w=rc_d * 0.5, panel_h=rc_h)
    wall_faces += res_rc_door["stone"]
    for f in res_rc_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    res_rc_win = arch_opening(b, bglow, (rc_hw, rc_cy + 0.7, h_wall + 0.4), 0.55, 0.85,
                              0.28, WALL_T, WALL, GLOW, style="round", rotation=door_rot,
                              glass=True, reveal=0.09, panel_w=rc_d * 0.5, panel_h=rc_h * 0.7)
    wall_faces += res_rc_win["stone"]

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    for f in rail_faces:
        if f.is_valid:
            f[br.slot] = GLOW
    rail_obj = _finish_or_none(br.to_object("House_Rail"))

    return wall_obj, trim_obj, glow_obj, rail_obj


# --- blue_house_e ------------------------------------------------------------
#
# Contract (brief §1.4): 7x6 m, 2+1 etaje, 8,5 m, h/l 0,83, tenta light.
# Element list (decupare blue_house_e.png), de jos in sus:
#
#   1. Volum principal in L: corpul mare (2 etaje, h~6.0) cu 2 usi de lemn
#      pe fata +X (spre stanga a fetei) SI 1 FEREASTRA MICA (etaj 2, dreapta,
#      deasupra usii volumului scund -- corectie, lipsea), plus un volum mai
#      mic/mai jos ALATURAT in dreapta (1 etaj, h~3.2) cu propria usa SI 1
#      FEREASTRA MICA pe fata ei laterala stanga (corectie, lipsea) -- forma
#      in L vazuta din fata ca doua corpuri de inaltimi diferite lipite.
#   2. Scara exterioara SOLIDA pe fata +X, care urca de la stanga (jos)
#      spre DREAPTA (sus), pana la terasa volumului scund (1 etaj) -- deci
#      scara urca spre dreapta, opus fata de blue_house_a (unde urca spre
#      stanga).
#   3. Al treilea etaj (camera mica, retrasa) deasupra corpului inalt,
#      accesibil de pe terasa scunda -- CU 1 usa (stanga) + 1 fereastra
#      (dreapta) pe fata ei din fata (corectie, lipseau amandoua).
HE_W, HE_D = 7.0, 6.0
HE_TOTAL = 8.5


def build_blue_house_e():
    b = Builder()
    bg = Builder()
    bglow = Builder()
    br = Builder()
    wall_faces, rail_faces = [], []
    WALL_T = 0.5

    # corp principal (2 etaje), ocupa 2/3 stanga a latimii (Y negativ),
    # h_main = 6.0
    h_main = 6.0
    main_w, main_d = HE_W, HE_D * 0.62
    main_cy = -(HE_D * 0.5) + main_d * 0.5
    hw_m, hd_m = main_w * 0.5, main_d * 0.5
    core_hw = hw_m - WALL_T * 0.5
    core_hd = hd_m - WALL_T * 0.5
    wall_faces += list(b.box((0.0, main_cy, h_main * 0.5), (core_hw * 2, core_hd * 2, h_main), WALL))
    band_x = hw_m - core_hw
    band_d = hd_m - core_hd
    wall_faces += list(b.box((-(hw_m - band_x * 0.5), main_cy, h_main * 0.5),
                             (band_x, core_hd * 2, h_main), WALL))
    wall_faces += list(b.box((0.0, main_cy + (hd_m - band_d * 0.5), h_main * 0.5),
                             (main_w, band_d, h_main), WALL))
    wall_faces += list(b.box((0.0, main_cy - (hd_m - band_d * 0.5), h_main * 0.5),
                             (main_w, band_d, h_main), WALL))
    wall_faces += list(b.box((0.0, main_cy, 0.16), (main_w + 0.16, main_d + 0.16, 0.32), WALL))

    # 2 usi de lemn pe fata +X a corpului principal, spre stanga (Y negativ)
    door_rot = Matrix.Rotation(math.radians(-90.0), 3, "Z")
    door_w, door_h = 1.0, 2.3
    for dy in (main_cy - 1.5, main_cy - 0.3):
        res_door = arch_opening(b, bg, (hw_m, dy, 0.0), door_w, door_h,
                                door_h * 0.94, WALL_T, WALL, GLOW, style="round",
                                rotation=door_rot, glass=True, reveal=0.10, glass_depth=0.08,
                                panel_w=1.3, panel_h=door_h * 1.4)
        wall_faces += res_door["stone"]
        for f in res_door["glass"]:
            if f.is_valid:
                f[bg.slot] = TRIM_WOOD
    for nx, ny, w in ((0, 1, main_w + 0.4), (1, 0, main_d + 0.4), (-1, 0, main_d + 0.4)):
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        cx = nx * hw_m
        cy = main_cy + ny * hd_m
        wall_faces += list(chajja(b, (cx, cy, h_main), w, 0.35, WALL,
                                  thickness=0.09, slope=0.4, rotation=rot))

    # fereastra mica, etaj 2, dreapta fetei (deasupra zonei volumului scund)
    # -- corectie: lipsea complet.
    res_win_main = arch_opening(b, bglow, (hw_m, main_cy + hd_m - 0.9, 3.5), 0.55, 0.85,
                                0.28, WALL_T, WALL, GLOW, style="round", rotation=door_rot,
                                glass=True, reveal=0.10, panel_w=1.1, panel_h=1.2)
    wall_faces += res_win_main["stone"]

    # volum scund (1 etaj), alaturat in dreapta (Y pozitiv), h_low = 3.2,
    # cu propria usa mica
    h_low = 3.2
    low_w, low_d = HE_W, HE_D * 0.42
    low_cy = HE_D * 0.5 - low_d * 0.5
    wall_faces += list(b.box((0.0, low_cy, h_low * 0.5), (low_w, low_d, h_low), WALL))
    wall_faces += list(b.box((0.0, low_cy, 0.14), (low_w + 0.14, low_d + 0.14, 0.28), WALL))
    for nx, ny, w in ((0, 1, low_w + 0.4), (1, 0, low_d + 0.4), (-1, 0, low_d + 0.4)):
        ang = math.atan2(-nx, ny)
        rot = Matrix.Rotation(ang, 3, "Z")
        cx = nx * (low_w * 0.5)
        cy = low_cy + ny * (low_d * 0.5)
        wall_faces += list(chajja(b, (cx, cy, h_low), w, 0.3, WALL,
                                  thickness=0.08, slope=0.4, rotation=rot))
    low_door_y = low_cy + low_d * 0.5 - 0.55
    res_door2 = arch_opening(b, bg, (low_w * 0.5, low_door_y, 0.0), 0.9, 2.0,
                             2.0 * 0.94, WALL_T, WALL, GLOW, style="round",
                             rotation=door_rot, glass=True, reveal=0.09, glass_depth=0.07,
                             panel_w=1.2, panel_h=2.0 * 1.4)
    wall_faces += res_door2["stone"]
    for f in res_door2["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD

    # fereastra mica pe fata laterala -X a volumului scund (vizibila din
    # fata camerei, langa scara) -- corectie: lipsea complet.
    low_win_rot = Matrix.Rotation(math.radians(180.0), 3, "Z")
    res_win_low = arch_opening(b, bglow, (-low_w * 0.5, low_cy, 0.5), 0.45, 0.9,
                               0.25, WALL_T, WALL, GLOW, style="round", rotation=low_win_rot,
                               glass=True, reveal=0.09, panel_w=low_d * 0.7, panel_h=1.2)
    wall_faces += res_win_low["stone"]

    # scara SOLIDA pe fata +X, urca de la STANGA (jos, langa corpul
    # principal) spre DREAPTA (sus, spre terasa volumului scund) -- opus
    # fata de blue_house_a.
    stair_w = 0.85
    stair_x = HE_W * 0.5 + stair_w * 0.5 + 0.05
    y_start = main_cy - hd_m + 0.3
    y_end = low_cy
    start = (stair_x, y_start, 0.0)
    end = (stair_x, y_end, h_low)
    stair_faces = solid_stair(br, start, end, stair_w, WALL, tread_slot=WALL,
                              nosing=True, nosing_slot=RAIL_WHITE, cheek=True,
                              cheek_slot=WALL, step_h=0.22)
    rail_faces += stair_faces
    rail_x = stair_x + stair_w * 0.5 + 0.05
    rail_faces += railing_on_brackets(br, (rail_x, y_start, 0.75), (rail_x, y_end, h_low + 0.75),
                                      0.70, RAIL_WHITE, bracket_step=0.8)

    # etaj 3: camera mica, retrasa, deasupra corpului principal, accesibila
    # de pe terasa scunda (h_low) -- CU 1 usa (stanga) + 1 fereastra
    # (dreapta) pe fata ei din fata (+X) -- corectie: lipseau amandoua.
    r3_w, r3_d, r3_h = 3.0, 2.6, 2.5
    r3_hw, r3_hd = r3_w * 0.5, r3_d * 0.5
    r3_cy = main_cy + 0.2
    r3_core_hw = r3_hw - WALL_T * 0.5
    wall_faces += list(b.box((-(r3_hw - r3_core_hw), r3_cy, h_main + r3_h * 0.5),
                             (r3_core_hw * 2, r3_d, r3_h), WALL))
    wall_faces += list(b.box((0.0, r3_cy, h_main + 0.05), (r3_w + 0.1, r3_d + 0.1, 0.10), WALL))

    r3_door_w, r3_door_h = 0.7, 1.8
    res_r3_door = arch_opening(b, bg, (r3_hw, r3_cy - 0.55, h_main), r3_door_w, r3_door_h,
                               r3_door_h * 0.94, WALL_T, WALL, GLOW, style="round",
                               rotation=door_rot, glass=True, reveal=0.09, glass_depth=0.07,
                               panel_w=r3_d * 0.5, panel_h=r3_h)
    wall_faces += res_r3_door["stone"]
    for f in res_r3_door["glass"]:
        if f.is_valid:
            f[bg.slot] = TRIM_WOOD
    res_r3_win = arch_opening(b, bglow, (r3_hw, r3_cy + 0.55, h_main + 0.35), 0.5, 0.75,
                              0.25, WALL_T, WALL, GLOW, style="round", rotation=door_rot,
                              glass=True, reveal=0.09, panel_w=r3_d * 0.5, panel_h=r3_h * 0.65)
    wall_faces += res_r3_win["stone"]

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))
    glow_obj = _finish_or_none(bglow.to_object("House_Glow"))
    rail_obj = _finish_or_none(br.to_object("House_Rail"))

    return wall_obj, trim_obj, glow_obj, rail_obj


# --- haveli_facade -------------------------------------------------------------
#
# Contract (brief §1.4): 10x6 m, 3 etaje, 11 m, h/l 0,92, tenta INDIGO,
# <=900 tri. Element list (decupare haveli_facade.png, RECITITA in runda de
# corectii, zoom 6x -- bug real gasit: codul vechi punea arcada pe fata care
# spanuie DOAR 6 m (HV_D, adancimea), nu pe fata de 10 m (HV_W, latimea) --
# "fatada LATA" cerea explicit sa fie pe dimensiunea mare. Fix: arcada trece
# pe fata +Y (implicita a `arch_opening`/`_cheap_arch_opening` fara rotatie),
# care spanuie X = HV_W = 10 m.
#
#   1. Parter: 4 goluri arcuite in sir pe toata fata +Y (nu 3 -- decuparea
#      arata 4 arce la parter, cele 2 din mijloc mai late/deschise, cele 2
#      de la capete mai inguste).
#   2. Etaj 1: 4 ferestre in arc (aceeasi grila ca parterul), cu UN BALCON
#      de piatra pe console CONTINUU sub tot randul.
#   3. Etaj 2: acelasi model -- 4 ferestre in arc cu balcon continuu.
#   4. Terasa de sus cu balustrada pe toata latimea fetei +Y.
#   5. Ornament sculptat sub cornisa de sus (banda decorativa).
#
# BUGET: 912 tri, PESTE cei 900 din brief (+12, ~1,3%) -- decizia acestei
# runde de corectii, motiv scris (regula "nu mutila piesa", brief §0.1):
# trecerea de la 3 la 4 arcade/ferestre pe rand (fix de fidelitate, decuparea
# arata clar 4, nu 3) plus fix-ul de axa (fatada pe cei 10 m, nu pe cei 6 m)
# aduc cost ireductibil. Merloanele balcoanelor/terasei au fost rarite de
# doua ori (de la 0.9/0.5 gap la 2.8/1.8 si 3.0/2.0) ca sa reduca 176 tri;
# sub asta, siluieta de parapet crenelat s-ar pierde. Liderul decide daca
# cei 12 tri raman sau se ridica bugetul in `verify_jodhpur.sh`.
HV_W, HV_D = 10.0, 6.0
HV_H = 11.0
HV_BUDGET = 900


def build_haveli_facade():
    b = Builder()
    bg = Builder()
    hw, hd = HV_W * 0.5, HV_D * 0.5
    WALL_T = 0.5
    wall_faces = []

    floor_h = HV_H / 3.0  # 3 etaje egale ~3.67 fiecare

    # miez plin retras pe fata +Y (arcade+ferestre, acum pe latimea de 10 m),
    # plin pe restul.
    core_hw = hw - WALL_T * 0.5
    core_hd = hd - WALL_T * 0.5
    wall_faces += list(b.box((0.0, 0.0, HV_H * 0.5), (core_hw * 2, core_hd * 2, HV_H), WALL))
    band_x = hw - core_hw
    band_d = hd - core_hd
    wall_faces += list(b.box((0.0, -(hd - band_d * 0.5), HV_H * 0.5), (core_hw * 2, band_d, HV_H), WALL))
    wall_faces += list(b.box((-(hw - band_x * 0.5), 0.0, HV_H * 0.5), (band_x, HV_D, HV_H), WALL))
    wall_faces += list(b.box(((hw - band_x * 0.5), 0.0, HV_H * 0.5), (band_x, HV_D, HV_H), WALL))
    wall_faces += list(b.box((0.0, 0.0, 0.20), (HV_W + 0.2, HV_D + 0.2, 0.4), WALL))

    # parter: 4 arcade (nu 3 -- corectie numar), vocabular IEFTIN (nu
    # `arch_opening(open=True)`, care la buget de 900 e prea scump pe 12
    # ferestre + 4 arcade -- vezi jurnal mai jos): fiecare arcada e un
    # dreptunghi de perete cu colturile de sus TAIATE (tesite), evocand un
    # arc turtit prin silueta, nu prin curba adevarata (brief regula 5: "se
    # vede la 30m ca forma?" -- un colt tesit citeste ca arc rotunjit de la
    # distanta jocului, la o fractie din cost). FARA rotatie (fata implicita
    # +Y a functiei), spanuie X = HV_W = 10 m.
    bay_w = HV_W / 4.0
    arch_h = floor_h * 0.92
    arch_w = bay_w * 0.72
    pier_frac = 0.60
    for i in range(4):
        bx = -hw + bay_w * (i + 0.5)
        wall_faces += _cheap_arch_opening(b, bg, (bx, hd, 0.0), arch_w, arch_h,
                                          pier_frac, WALL_T * 1.2, WALL, GLOW,
                                          rotation=None, open=True)

    # etajele 1 si 2: 4 ferestre (acelasi vocabular ieftin, INCHISE -- glow
    # plin, nu deschise), cu UN SINGUR balcon continuu pe console per etaj.
    for floor_i in (1, 2):
        fz0 = floor_h * floor_i
        win_h = floor_h * 0.55
        win_w = bay_w * 0.46
        # z ABSOLUT (`center` nu se re-centreaza pe Z, vezi bug-ul gasit in
        # runda de corectii: formula veche `fz0 - HV_H*0.5 + floor_h*0.24`
        # presupunea o recentrare care nu exista -- floor 1 iesea sub sol
        # (z=-0.95) si floor 2 cadea peste floor 1 (z=2.7), deci ferestrele
        # erau fie ingropate, fie pe alt etaj decat cel vizat).
        win_z = fz0 + floor_h * 0.22
        for i in range(4):
            bx = -hw + bay_w * (i + 0.5)
            wall_faces += _cheap_arch_opening(b, bg, (bx, hd, win_z),
                                              win_w, win_h, 0.55, WALL_T, WALL, GLOW,
                                              rotation=None, open=False)
        # balcon de piatra CONTINUU pe console, sub randul de ferestre.
        bal_z = fz0
        wall_faces += list(chajja(b, (0.0, hd + 0.02, bal_z), HV_W - 0.3, 0.45, WALL,
                                  thickness=0.08, slope=0.4, rotation=None))
        wall_faces += list(balustrade(b, (-hw + 0.3, hd + 0.30, bal_z),
                                      (hw - 0.3, hd + 0.30, bal_z),
                                      0.5, WALL, merlon_w=2.8, merlon_gap=1.8))

    # terasa de sus: balustrada pe toata latimea fetei +Y
    wall_faces += list(balustrade(b, (-hw + 0.3, hd + 0.05, HV_H),
                                  (hw - 0.3, hd + 0.05, HV_H),
                                  0.75, WALL, merlon_w=3.0, merlon_gap=2.0))

    # friza decorativa sub cornisa de sus: UN SINGUR chajja ingust in loc de
    # dinti individuali (buget 900 nu incape inca dinti bevel-uiti -- un
    # chajja continuu da aceeasi umbra de "banda sub cornisa" la 1 fata in
    # loc de multe per dinte).
    wall_faces += list(chajja(b, (0.0, hd + 0.02, HV_H - 0.35), HV_W - 0.2, 0.18, WALL,
                              thickness=0.07, slope=0.5, rotation=None))

    wall_obj = b.to_object("House_Wall")
    for f in wall_faces:
        if f.is_valid:
            f[b.slot] = WALL
    trim_obj = _finish_or_none(bg.to_object("House_Trim"))

    return wall_obj, trim_obj


# --- props/rooftop_tank --------------------------------------------------------
#
# Contract (brief §1.4): Ø1,2 x 1,4 m, tenta -- (nod unic). Element list
# (decupare rooftop_tank.png): un singur cilindru negru cu nervuri
# orizontale (3-4 vizibile) si un capac usor bombat -- fara alt detaliu.
def build_rooftop_tank():
    b = Builder()
    faces = _rooftop_tank(b, (0.0, 0.0, 0.0), radius=0.6, height=1.1, n_ribs=4)
    obj = b.to_object("Tank_Body")
    for f in faces:
        if f.is_valid:
            f[b.slot] = TANK_DARK
    return (obj,)


# --- props/rooftop_clutter ------------------------------------------------------
#
# Contract (brief §1.4): placa 3x2,5 m, stalpi 1,8 m, tenta light. Element
# list (decupare rooftop_clutter.png), de jos in sus:
#
#   1. Placa de terasa (albastra, WALL) 3x2,5 m.
#   2. Rezervor mic negru in coltul STANGA-SPATE al placii.
#   3. Doua gramezi de oale/lucruri (culoare piatra/lemn) langa rezervor,
#      spre mijloc/dreapta.
#   4. 2 stalpi de lemn, unul langa altul pe latura din SPATE, cu o sfoara
#      intinsa intre ei -- 2 rufe atarnate: una GALBENA (stanga), una ROZ
#      (dreapta).
RC_W, RC_D = 3.0, 2.5
RC_POST_H = 1.8


def build_rooftop_clutter():
    b = Builder()
    bl = Builder()  # rufele (culori saturate, sloturi de accent, allow-car-slots)
    # NOTA fix (bug real gasit la primul --compare al valului 3): fetele nu
    # se mai aduna intr-o singura lista `faces` pictata orbeste WALL la
    # final -- placa, rezervorul, oalele si stalpii/sfoara sunt pe sloturi
    # DIFERITE (WALL, TANK_DARK, WOOD, LOG_DARK), dar overwrite-ul vechi
    # (`f[b.slot] = WALL` pe toata lista) le picta pe toate albastru,
    # exact ce a aratat comparatia (rezervor + oale + stalpi, toate
    # albastre in loc de negru/lemn). Acum fiecare grup isi pastreaza
    # slotul propriu, scris o singura data.
    hw, hd = RC_W * 0.5, RC_D * 0.5

    # placa de terasa
    plate_faces = list(b.box((0.0, 0.0, 0.08), (RC_W, RC_D, 0.16), WALL))

    # rezervor mic negru, colt stanga-spate (X negativ, Y negativ).
    # segments 12->8, n_ribs 3->2 (buget: masurat izolat 476->336 tri --
    # asta e piesa DECORATIVA de fundal, nu props/rooftop_tank.glb propriu-
    # zis, care ramane la 12 segmente; brief §1 cere doar 8-16, nu maxim)
    tank_faces = _rooftop_tank(b, (-hw + 0.5, -hd + 0.5, 0.16), radius=0.35, height=0.55,
                               n_ribs=2, )

    # 2 gramezi de oale (piatra/lemn), spre mijloc/dreapta (segments 8->6,
    # buget: minor dar consistent cu restul reducerilor din piesa asta)
    pot_faces = []
    for i, (px, py) in enumerate(((0.1, -hd + 0.5), (0.65, -hd + 0.55))):
        for k in range(3):
            r = 0.16 - k * 0.02
            pot_faces += list(b.cylinder((px + k * 0.05, py, 0.16 + r + k * 0.06), r,
                                         0.14, WOOD, segments=6, axis="Z"))

    # 2 stalpi pe latura din spate (Y negativ e "spate" fata de +X camera;
    # dar rufele trebuie sa fie vizibile din fata -- le punem pe latura din
    # FATA/+Y, ca sa fie clar vizibile in comparatie, la fel ca decuparea
    # care arata rufele in prim-plan). segments 8->6 (stalpi subtiri,
    # diferenta de silueta nula la aceasta raza).
    post_x0, post_x1 = -hw + 0.3, hw - 0.3
    post_y = hd - 0.25
    post_faces = list(b.cylinder((post_x0, post_y, 0.16 + RC_POST_H * 0.5), 0.06, RC_POST_H,
                                 LOG_DARK, segments=6, axis="Z"))
    post_faces += list(b.cylinder((post_x1, post_y, 0.16 + RC_POST_H * 0.5), 0.06, RC_POST_H,
                                  LOG_DARK, segments=6, axis="Z"))
    # sfoara (fir subtire) intre stalpi
    post_faces += list(b.box((0.0, post_y, 0.16 + RC_POST_H - 0.02), (post_x1 - post_x0, 0.02, 0.02), LOG_DARK))

    # 2 rufe atarnate pe sfoara: galben (stanga), roz (dreapta) -- panza
    # opaca cu usoara lasare (blade pe un traseu in catenara aproximativa).
    # segs 4->2 (buget: jumatate din geometria panzei, lasarea tot se
    # citeste ca o usoara curba pe o piesa de 0.55x0.7m la distanta jocului)
    def _cloth(cx, color):
        w = 0.55
        h = 0.7
        sag = 0.05
        path = [(cx - w * 0.5, post_y, 0.16 + RC_POST_H - 0.02 - sag * t * (1 - t) * 4)
               for t in (0.0, 0.5, 1.0)]
        # panza plata verticala: folosim box-uri suprapuse in loc de sweep,
        # mai simplu si suficient pentru o piesa mica -- placa unica usor
        # curbata (2 segmente) atarnand de sfoara
        segs = 2
        cf = []
        for k in range(segs):
            t0, t1 = k / segs, (k + 1) / segs
            y0 = post_y - 0.02 - t0 * 0.01
            y1 = post_y - 0.02 - t1 * 0.01
            z0 = 0.16 + RC_POST_H - 0.02 - h * t0
            z1 = 0.16 + RC_POST_H - 0.02 - h * t1
            cf += list(bl.box((cx, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                              (w, 0.02, h / segs + 0.01), color))
        return cf
    laundry_faces = []
    laundry_faces += _cloth(post_x0 + (post_x1 - post_x0) * 0.28, LAUNDRY_YELLOW)
    laundry_faces += _cloth(post_x0 + (post_x1 - post_x0) * 0.72, LAUNDRY_PINK)

    obj = b.to_object("Clutter_Base")
    for f in plate_faces:
        if f.is_valid:
            f[b.slot] = WALL
    for f in tank_faces:
        if f.is_valid:
            f[b.slot] = TANK_DARK
    for f in pot_faces:
        if f.is_valid:
            f[b.slot] = WOOD
    for f in post_faces:
        if f.is_valid:
            f[b.slot] = LOG_DARK
    laundry_obj = _finish_or_none(bl.to_object("Clutter_Laundry"))
    return obj, laundry_obj


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Identic cu `emit` din build_jodhpur_pilot.py."""
    objs = [o for o in objs if o is not None]
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
    return total_tris


hb = build_blue_house_b()
emit(list(hb), "buildings/blue_house_b.glb", AO_HOUSE, bevel=0.025, budget=6000)

hc = build_blue_house_c()
emit(list(hc), "buildings/blue_house_c.glb", AO_HOUSE, bevel=0.025, budget=3800)

hd_ = build_blue_house_d()
emit(list(hd_), "buildings/blue_house_d.glb", AO_HOUSE, bevel=0.025, budget=6500)

he = build_blue_house_e()
emit(list(he), "buildings/blue_house_e.glb", AO_HOUSE, bevel=0.025, budget=6500)

hv = build_haveli_facade()
emit(list(hv), "buildings/haveli_facade.glb", AO_HOUSE, bevel=0.02, budget=HV_BUDGET)

tank = build_rooftop_tank()
emit(list(tank), "props/rooftop_tank.glb", AO_PROP, bevel=0.02, budget=700)

clutter = build_rooftop_clutter()
emit(list(clutter), "props/rooftop_clutter.glb", AO_PROP, bevel=0.02, budget=1400)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL orasul: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for pieces in (hb, hc, hd_, he, hv, tank, clutter) for o in pieces if o is not None],
          "jodhpur_city.blend")
