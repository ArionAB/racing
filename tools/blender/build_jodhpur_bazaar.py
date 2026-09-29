"""Jodhpur -- Bazarul, val 3b (brief §1.5, docs/asset_briefs/jodhpur_kit.md).

  jodhpur/props/stall_canopy_a.glb   taraba, copertina GALBENA, laded de marfa
  jodhpur/props/stall_canopy_b.glb   taraba, copertina ROZ, laded de marfa
  jodhpur/props/stall_canopy_c.glb   taraba, copertina VERDE, laded de marfa
  jodhpur/props/textile_strip.glb    7 panze colorate pe o sfoara intre 2 stalpi
  jodhpur/props/spice_sacks.glb      3 saci de iuta cu conuri de condiment
  jodhpur/props/thela_cart.glb       carucior de mana cu 4 roti si fructe
  jodhpur/props/chai_stall.glb       taraba de ceai, acoperis de panza bej
  jodhpur/props/marigold_garland.glb ghirlanda de galbenele pe catenara

Reuseste vocabularul din jodhpur_shapes.py (chajja pentru streasina inclinata
a copertinelor, aceeasi tehnica de roata cu spite -- disc+butuc+bare -- din
`build_jodhpur_fort.py::build_rampart_cannon`, panza plata din
`build_jodhpur_city.py::_cloth` pentru textile_strip).

**Camera:** aceeasi conventie ca orasul -- +X e fata dominanta a camerei
`compare()` la azimut/elevatie implicit (35/18), piese aproape cubice sau
alungite pe Y (textile_strip, gard).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_jodhpur_bazaar.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4/§1.5).
POST_WOOD = WOOD           # stalpii tarabelor, ramele
CRATE_WOOD = WOOD          # ladele/tejghelele
SACK_CLOTH = SAND_MID      # sacii de iuta
SPICE_RED = CAR_RED
SPICE_YELLOW = CAR_YELLOW
FRUIT_GREEN = TROPICAL_GREEN
FRUIT_ORANGE = LAVA_ORANGE
METAL_DARK = VOLCANIC_BLACK
POT_METAL = PAINTED
GARLAND_ORANGE = LAVA_ORANGE  # ca albedo, per brief §1.5

AO_PROP = dict(samples=16, dist=2.0, gradient="vertical",
               low=0.50, high=1.00, power=0.85, floor=0.20)


def _finish_or_none(obj):
    """Vezi build_jodhpur_pilot.py -- un Builder GLOW/accent poate ramane gol."""
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


def _bead(b, center, radius, slot, subdivisions=1):
    """Margea/ciucure: icosfera (brief §1.5, "icosfere cu subdivisions 1"),
    construita direct cu bmesh.ops (Builder nu are metoda icosphere -- vezi
    build_rock_set.py pentru precedent) si taguita cu `_tag` (helper interna
    a lui Builder, foloseste v.link_faces ca sa gaseasca fetele noi)."""
    res = bmesh.ops.create_icosphere(b.bm, subdivisions=subdivisions, radius=radius)
    cx, cy, cz = center
    for v in res["verts"]:
        v.co.x += cx
        v.co.y += cy
        v.co.z += cz
    return b._tag(res["verts"], slot)


def _wheel(b, center, radius, thickness, slot, segments=12, axis="Y"):
    """Roata cu spite: disc solid (citeste corect ca roata in silueta, per
    lectia rampart_cannon val 2a) + butuc proeminent + 4 bare radiale in
    relief pe ambele fete (8 spite vizuale). NU incearca jante din cutii
    tangente pe cerc (geometrie stricata, memoria rotatii-in-builder-semnul)."""
    cx, cy, cz = center
    faces = []
    if axis == "Y":
        faces += list(b.cylinder(center, radius, thickness, slot, segments=segments, axis="Y"))
        faces += list(b.cylinder(center, radius * 0.18, thickness * 1.6, slot, segments=8, axis="Y"))
        for i in range(4):
            ang = i * math.pi / 4.0
            rot = Matrix.Rotation(ang, 3, "Y")
            faces += list(b.box(center, (radius * 1.82, thickness * 0.22, 0.05),
                                slot, rotation=rot))
    else:  # axis == "Z" (roata orizontala, nefolosita azi, pastrata pt generalitate)
        faces += list(b.cylinder(center, radius, thickness, slot, segments=segments, axis="Z"))
        faces += list(b.cylinder(center, radius * 0.18, thickness * 1.6, slot, segments=8, axis="Z"))
        for i in range(4):
            ang = i * math.pi / 4.0
            rot = Matrix.Rotation(ang, 3, "Z")
            faces += list(b.box(center, (radius * 1.82, 0.05, thickness * 0.22),
                                slot, rotation=rot))
    return faces


def _cloth_panel(b, center, w, h, slot, axis_normal="Y", segs=2, sag=0.04):
    """Panza plata verticala usor lasata -- aceeasi tehnica ca
    build_jodhpur_city.py::_cloth, generalizata pe orientare. `center` e
    punctul de sus-mijloc (unde atarna de sfoara/bara)."""
    cx, cy, cz = center
    faces = []
    for k in range(segs):
        t0, t1 = k / segs, (k + 1) / segs
        z0 = cz - h * t0
        z1 = cz - h * t1
        y0 = cy - sag * t0 * (1 - t0) * 4
        y1 = cy - sag * t1 * (1 - t1) * 4
        if axis_normal == "Y":
            faces += list(b.box((cx, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
                                (w, 0.02, h / segs + 0.01), slot))
        else:  # "X"
            faces += list(b.box(((y0 + y1) * 0.5, cx, (z0 + z1) * 0.5),
                                (0.02, w, h / segs + 0.01), slot))
    return faces


# --- stall_canopy (a/b/c) -----------------------------------------------------
#
# Contract (brief §1.5): 3x2.5 m, copertina la 2.6 m, h/l 0.72-0.76. Element
# list (decupari stall_canopy_a/b/c.png), comuna celor 3 (doar culoarea
# copertinei si a marfii difera):
#
#   1. 4 stalpi de lemn verticali (colturile tarabei).
#   2. Copertina de panza, usor LASATA (catenara vizibila), inclinata ca un
#      acoperis intr-o apa spre spate -- pe decupare se vede clar curbura
#      moale a panzei intre stalpii din fata si cei din spate.
#   3. Tejghea/rama de lemn joasa care leaga stalpii la baza.
#   4. Lazi cu marfa in TREPTE (2-3 niveluri), vazute in fata tarabei:
#      gramezi mici colorate (fructe/condimente), nu cutii goale.
#   Culoare copertina: a=CAR_YELLOW (galben), b=FLAMINGO_PINK (roz),
#   c=TROPICAL_GREEN (verde), ca pe cele 3 decupari.
SC_W, SC_D = 3.0, 2.5
SC_CANOPY_H = 2.6
SC_POST_H = 2.1


def _build_stall_canopy(canopy_slot, goods_colors):
    b = Builder()      # lemn (stalpi, rama, laden)
    bc = Builder()      # copertina (Canopy)
    bgd = Builder()     # marfa (Goods)
    hw, hd = SC_W * 0.5, SC_D * 0.5

    # 4 stalpi de lemn, colturile tarabei
    post_r = 0.06
    posts = [(-hw + 0.15, -hd + 0.15), (hw - 0.15, -hd + 0.15),
             (-hw + 0.15, hd - 0.15), (hw - 0.15, hd - 0.15)]
    post_faces = []
    for px, py in posts:
        post_faces += list(b.cylinder((px, py, SC_POST_H * 0.5), post_r, SC_POST_H,
                                      POST_WOOD, segments=8, axis="Z"))

    # rama joasa care leaga stalpii la baza tejghelei (grinzi orizontale)
    frame_h = 0.06
    frame_z = 0.75
    frame_faces = []
    frame_faces += list(b.box((0.0, -hd + 0.15, frame_z), (SC_W - 0.3, frame_h, frame_h), POST_WOOD))
    frame_faces += list(b.box((0.0, hd - 0.15, frame_z), (SC_W - 0.3, frame_h, frame_h), POST_WOOD))
    frame_faces += list(b.box((-hw + 0.15, 0.0, frame_z), (frame_h, SC_D - 0.3, frame_h), POST_WOOD))
    frame_faces += list(b.box((hw - 0.15, 0.0, frame_z), (frame_h, SC_D - 0.3, frame_h), POST_WOOD))

    # copertina: panza lasata (catenara), inclinata usor spre spate (-Y mai jos).
    # segs 5->4 (buget: 1524->~1400 tri, lasarea tot se citeste ca o curba la
    # 4 segmente pe o piesa de 3x2.5m)
    canopy_faces = []
    segs = 4
    front_h, back_h = SC_CANOPY_H, SC_CANOPY_H - 0.35
    for k in range(segs):
        t0, t1 = k / segs, (k + 1) / segs
        y0 = -hd - 0.3 + (SC_D + 0.6) * t0
        y1 = -hd - 0.3 + (SC_D + 0.6) * t1
        sag0 = 0.18 * math.sin(t0 * math.pi)
        sag1 = 0.18 * math.sin(t1 * math.pi)
        z0 = front_h + (back_h - front_h) * t0 - sag0
        z1 = front_h + (back_h - front_h) * t1 - sag1
        w0 = (SC_W + 0.5) * (1.0 - 0.04 * math.sin(t0 * math.pi))
        w1 = (SC_W + 0.5) * (1.0 - 0.04 * math.sin(t1 * math.pi))
        hw0, hw1 = w0 * 0.5, w1 * 0.5
        p00 = (-hw0, y0, z0); p10 = (hw0, y0, z0)
        p01 = (-hw1, y1, z1); p11 = (hw1, y1, z1)
        # NOTA fix: fetele copertinei trebuie construite pe `bc.bm` (Builder-ul
        # dedicat Canopy), nu `b.bm` (lemnul) -- bug gasit la prima rulare
        # (emit() crapa cu "min() pe lista goala" fiindca nodul Canopy iesea
        # cu 0 vertecsi, geometria ajungand din greseala in Canopy_Wood).
        f1 = bc.bm.faces.new((bc.bm.verts.new(p00), bc.bm.verts.new(p10),
                              bc.bm.verts.new(p11), bc.bm.verts.new(p01)))
        canopy_faces.append(f1)
        # fata de dedesubt (grosime vizuala minima)
        p00b = (-hw0, y0, z0 - 0.04); p10b = (hw0, y0, z0 - 0.04)
        p01b = (-hw1, y1, z1 - 0.04); p11b = (hw1, y1, z1 - 0.04)
        f2 = bc.bm.faces.new((bc.bm.verts.new(p01b), bc.bm.verts.new(p11b),
                              bc.bm.verts.new(p10b), bc.bm.verts.new(p00b)))
        canopy_faces.append(f2)

    # lazi cu marfa in trepte (2-3 niveluri), fata tarabei (+Y, langa stalpii din spate)
    goods_faces = []
    crate_faces = []
    n_tiers = 3
    tier_h = 0.22
    for tier in range(n_tiers):
        tz = frame_z + tier * tier_h
        tier_d = 0.9 - tier * 0.2
        ty = -hd + 0.15 + tier_d * 0.5 + tier * 0.05
        crate_faces += list(b.box((0.0, ty, tz + tier_h * 0.5),
                                  (SC_W - 0.4 - tier * 0.3, tier_d, tier_h), CRATE_WOOD))
        # gramada de marfa colorata deasupra fiecarei lade -- marita
        # semnificativ (raza 0.11->0.19, inaltime 0.14->0.22) dupa primul
        # --compare: la dimensiunea initiala grămezile erau aproape
        # invizibile sub streasina copertinei, citind ca un singur punct
        # colorat in loc de gramada vizibila (brief: "gramezi mici colorate")
        n_goods = 4 - tier
        color = goods_colors[tier % len(goods_colors)]
        for i in range(n_goods):
            gx = -0.7 + i * (1.4 / max(n_goods - 1, 1))
            goods_faces += list(bgd.cylinder((gx, ty, tz + tier_h + 0.14), 0.19, 0.22,
                                             color, segments=8, axis="Z"))

    post_obj = b.to_object("Canopy_Wood")
    for f in post_faces + frame_faces + crate_faces:
        if f.is_valid:
            f[b.slot] = POST_WOOD
    canopy_obj = bc.to_object("Canopy")
    for f in canopy_faces:
        if f.is_valid:
            f[bc.slot] = canopy_slot
    goods_obj = _finish_or_none(bgd.to_object("Goods"))
    return post_obj, canopy_obj, goods_obj


# --- textile_strip -------------------------------------------------------------
#
# Contract (brief §1.5): 10 m intre stalpi, panze 0.9x1.6 m, h/l 0.55.
# Element list (decupare textile_strip.png):
#
#   1. 2 stalpi de lemn la capete, sfoara intinsa intre ele (usor lasata).
#   2. 7 panze OPACE atarnate pe sfoara, in ordinea culorilor de pe decupare:
#      portocaliu, galben, roz, rosu, verde, galben, roz.
#   3. Margine de jos usor crestata (zimti), in geometrie (nu alpha).
TS_SPAN = 10.0
TS_POST_H = 2.6
TS_CLOTH_W, TS_CLOTH_H = 0.9, 1.6
TS_COLORS = [LAVA_ORANGE, CAR_YELLOW, FLAMINGO_PINK, CAR_RED,
            TROPICAL_GREEN, CAR_YELLOW, FLAMINGO_PINK]


def build_textile_strip():
    b = Builder()   # Poles (stalpi + sfoara)
    bl = Builder()  # panzele (Cloth)
    hs = TS_SPAN * 0.5

    pole_faces = []
    pole_faces += list(b.cylinder((-hs, 0.0, TS_POST_H * 0.5), 0.08, TS_POST_H,
                                  POST_WOOD, segments=8, axis="Z"))
    pole_faces += list(b.cylinder((hs, 0.0, TS_POST_H * 0.5), 0.08, TS_POST_H,
                                  POST_WOOD, segments=8, axis="Z"))
    # sfoara: cateva segmente ca sa urmareasca o usoara lasare (catenara)
    rope_sag = 0.25
    rope_segs = 8
    for k in range(rope_segs):
        t0, t1 = k / rope_segs, (k + 1) / rope_segs
        x0 = -hs + TS_SPAN * t0
        x1 = -hs + TS_SPAN * t1
        z0 = TS_POST_H - rope_sag * 4 * t0 * (1 - t0)
        z1 = TS_POST_H - rope_sag * 4 * t1 * (1 - t1)
        pole_faces += list(b.box(((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5),
                                 (x1 - x0 + 0.02, 0.02, 0.02), POST_WOOD))

    # 7 panze, distribuite uniform pe deschidere, fiecare atarnata de punctul
    # sagetii sforii la acea pozitie (nu de o linie dreapta)
    cloth_faces = []
    n = len(TS_COLORS)
    for i, color in enumerate(TS_COLORS):
        t = (i + 0.5) / n
        cx = -hs + TS_SPAN * t
        rope_z = TS_POST_H - rope_sag * 4 * t * (1 - t)
        # panza cu margine de jos crestata: 3 "dinti" facuti din triunghiuri
        # mici taiate la coltul de jos, in loc de dreptunghi drept
        top_z = rope_z - 0.03
        bottom_z = top_z - TS_CLOTH_H
        hw_c = TS_CLOTH_W * 0.5
        n_teeth = 3
        tooth_w = TS_CLOTH_W / n_teeth
        # fata principala din n_teeth patrulatere care coboara pana la un
        # varf de dinte (colt taiat) -- da zimtii fara geometrie suplimentara
        for tth in range(n_teeth):
            x0 = -hw_c + tth * tooth_w
            x1 = x0 + tooth_w
            xm = (x0 + x1) * 0.5
            tip_z = bottom_z - (0.08 if tth % 2 == 0 else 0.0)
            p_tl = (cx + x0, 0.0, top_z)
            p_tr = (cx + x1, 0.0, top_z)
            p_bm = (cx + xm, 0.0, tip_z)
            p_bl = (cx + x0, 0.0, bottom_z)
            p_br = (cx + x1, 0.0, bottom_z)
            f1 = bl.bm.faces.new((bl.bm.verts.new(p_tl), bl.bm.verts.new(p_tr),
                                  bl.bm.verts.new(p_br), bl.bm.verts.new(p_bl)))
            cloth_faces.append(f1)
            f2 = bl.bm.faces.new((bl.bm.verts.new(p_bl), bl.bm.verts.new(p_br),
                                  bl.bm.verts.new(p_bm)))
            cloth_faces.append(f2)
        for f in cloth_faces[-n_teeth * 2:]:
            if f.is_valid:
                f[bl.slot] = color

    pole_obj = b.to_object("Poles")
    for f in pole_faces:
        if f.is_valid:
            f[b.slot] = POST_WOOD
    cloth_obj = bl.to_object("Cloth")
    return pole_obj, cloth_obj


# --- spice_sacks -----------------------------------------------------------
#
# Contract (brief §1.5): 1.6x1.0x0.9 m, h/l 0.61. Element list (decupare
# spice_sacks.png): 3 saci de iuta cu gura rasfranta, cu conuri de condiment
# deasupra -- 2 mai mari/vizibile (rosu, galben) in prim-plan, al 3-lea mai
# mic/partial vizibil in spate intre ele (decupare arata predominant 2, dar
# brief cere explicit 3 -- al treilea e mai mic si mai in spate, pe planul
# median, per "3 saci" din tabel).
SS_W, SS_D, SS_H = 1.6, 1.0, 0.9


def build_spice_sacks():
    b = Builder()    # sacii de iuta (WOOD/SAND_MID)
    bs = Builder()   # conurile de condiment (accent)
    faces = []
    spice_faces = []

    sacks = [
        # (x, y, raza_baza, inaltime, slot_condiment)
        (-0.42, 0.0, 0.34, 0.62, SPICE_RED),
        (0.42, 0.0, 0.34, 0.62, SPICE_YELLOW),
        (0.0, 0.28, 0.24, 0.46, SPICE_RED),
    ]
    for sx, sy, r, h, spice_color in sacks:
        # corpul sacului: frustum usor evazat la baza + cilindru central,
        # gura rasfranta ca un inel mai lat la varf
        faces += list(b.frustum((sx, sy, h * 0.28), r, r * 0.88, h * 0.56,
                                SACK_CLOTH, segments=10, axis="Z"))
        faces += list(b.cylinder((sx, sy, h * 0.62), r * 0.88, h * 0.28,
                                 SACK_CLOTH, segments=10, axis="Z"))
        # gura rasfranta: inel scurt, mai lat
        faces += list(b.cylinder((sx, sy, h * 0.78), r * 0.98, h * 0.10,
                                 SACK_CLOTH, segments=10, axis="Z"))
        # conul de condiment, deasupra gurii sacului
        spice_faces += list(bs.frustum((sx, sy, h * 0.83 + h * 0.22 * 0.5), r * 0.85, 0.02,
                                       h * 0.22, spice_color, segments=10, axis="Z"))

    sack_obj = b.to_object("Sacks")
    for f in faces:
        if f.is_valid:
            f[b.slot] = SACK_CLOTH
    # spice_faces deja au slotul corect (frustum() tagheaza intern per-con
    # cu spice_color, culori diferite per sac) -- nimic de suprascris aici.
    spice_obj = bs.to_object("Spice")
    return sack_obj, spice_obj


# --- thela_cart --------------------------------------------------------------
#
# Contract (brief §1.5): 2.4x1.2x1.1 m, h/l 0.53. Element list (decupare
# thela_cart.png): platforma de lemn cu rama, 4 roti de lemn cu spite (NU 2
# roti de bicicleta -- planșa castiga), gramada de fructe colorate (verde,
# galben, portocaliu/rosu) in trepte pe platforma.
TC_W, TC_D, TC_H = 2.4, 1.2, 1.1
TC_WHEEL_R = 0.30


def build_thela_cart():
    b = Builder()    # platforma + rama (Cart_Wood)
    bw = Builder()   # rotile (Cart_Wheels)
    bf = Builder()   # fructele (Cart_Fruit)
    faces = []
    wheel_faces = []
    fruit_faces = []

    platform_z = TC_WHEEL_R * 2.0 * 0.62
    hw, hd = TC_W * 0.5, TC_D * 0.5

    # platforma de lemn cu rama (bordura usor ridicata pe margini)
    faces += list(b.box((0.0, 0.0, platform_z), (TC_W, TC_D, 0.08), CRATE_WOOD))
    rim_h = 0.10
    faces += list(b.box((0.0, hd - 0.03, platform_z + rim_h * 0.5 + 0.04),
                        (TC_W, 0.06, rim_h), CRATE_WOOD))
    faces += list(b.box((0.0, -hd + 0.03, platform_z + rim_h * 0.5 + 0.04),
                        (TC_W, 0.06, rim_h), CRATE_WOOD))
    faces += list(b.box((hw - 0.03, 0.0, platform_z + rim_h * 0.5 + 0.04),
                        (0.06, TC_D, rim_h), CRATE_WOOD))
    faces += list(b.box((-hw + 0.03, 0.0, platform_z + rim_h * 0.5 + 0.04),
                        (0.06, TC_D, rim_h), CRATE_WOOD))

    # picioarele/rama care sustine platforma (4 stinghii verticale scurte
    # pana la axele rotilor)
    for lx, ly in ((-hw + 0.2, -hd + 0.1), (hw - 0.2, -hd + 0.1),
                  (-hw + 0.2, hd - 0.1), (hw - 0.2, hd - 0.1)):
        faces += list(b.box((lx, ly, platform_z * 0.5), (0.06, 0.06, platform_z), CRATE_WOOD))

    # maner de impins, in fata (+X e fata camerei, dar maner-ul e context
    # -- pus pe -Y ca sa nu acopere fructele din cadrul de comparatie)
    handle_x = -hw - 0.35
    faces += list(b.box((handle_x, 0.0, platform_z + 0.35), (0.5, 0.05, 0.05), CRATE_WOOD))
    faces += list(b.box((-hw - 0.05, -0.15, platform_z + 0.18), (0.05, 0.05, 0.35), CRATE_WOOD))
    faces += list(b.box((-hw - 0.05, 0.15, platform_z + 0.18), (0.05, 0.05, 0.35), CRATE_WOOD))

    # 4 roti cu spite (nu 2 -- planșa castiga, brief §1.5)
    axle_y = hd - 0.15
    for wx in (-hw + 0.35, hw - 0.35):
        for wy in (-axle_y, axle_y):
            # brief §1.5: "4 roti de LEMN cu spite" -- CRATE_WOOD, nu
            # METAL_DARK (fix dupa --compare: rotile ieseau negru-metal
            # uniform, fara sa se distinga spitele de disc, si nici nu
            # respectau materialul cerut de brief)
            wheel_faces += _wheel(bw, (wx, wy, TC_WHEEL_R), TC_WHEEL_R, 0.08,
                                  CRATE_WOOD, segments=12, axis="Y")

    # gramada de fructe in trepte (2 niveluri), culori verde/galben/portocaliu-rosu
    fruit_colors = [FRUIT_GREEN, SPICE_YELLOW, FRUIT_ORANGE, SPICE_RED]
    n_fruit_bottom = 7
    for i in range(n_fruit_bottom):
        fx = -hw + 0.35 + i * (TC_W - 0.7) / (n_fruit_bottom - 1)
        color = fruit_colors[i % len(fruit_colors)]
        fruit_faces += list(bf.cylinder((fx, 0.0, platform_z + rim_h + 0.10), 0.13, 0.16,
                                        color, segments=8, axis="Z"))
    n_fruit_top = 4
    for i in range(n_fruit_top):
        fx = -hw + 0.6 + i * (TC_W - 1.2) / (n_fruit_top - 1)
        color = fruit_colors[(i + 2) % len(fruit_colors)]
        fruit_faces += list(bf.cylinder((fx, 0.0, platform_z + rim_h + 0.28), 0.12, 0.15,
                                        color, segments=8, axis="Z"))

    cart_obj = b.to_object("Cart_Wood")
    for f in faces:
        if f.is_valid:
            f[b.slot] = CRATE_WOOD
    wheels_obj = bw.to_object("Cart_Wheels")
    for f in wheel_faces:
        if f.is_valid:
            f[bw.slot] = CRATE_WOOD
    fruit_obj = bf.to_object("Cart_Fruit")
    return cart_obj, wheels_obj, fruit_obj


# --- chai_stall ----------------------------------------------------------------
#
# Contract (brief §1.5): 2.5x2.0x2.6 m, h/l 0.77. Element list (decupare
# chai_stall.png):
#
#   1. 4 stalpi de lemn + acoperis de panza BEJ (SAND_LIGHT), aproape plat
#      (usoara panta intr-o singura apa), fara curbura pronuntata (diferit
#      de stall_canopy).
#   2. Tejghea de lemn joasa in fata (+X), cu 1-2 dulapuri/cutii laterale.
#   3. 2 oale de metal (PAINTED) pe tejghea, plus o ceainica mica langa ele.
CH_W, CH_D, CH_H = 2.5, 2.0, 2.6
CH_ROOF_H = 2.5


def build_chai_stall():
    b = Builder()    # stalpi + tejghea + acoperis (Stall_Wood)
    bm_ = Builder()  # oalele/ceainica (Stall_Metal)
    faces = []
    metal_faces = []
    hw, hd = CH_W * 0.5, CH_D * 0.5

    # 4 stalpi
    post_r = 0.06
    posts = [(-hw + 0.12, -hd + 0.12), (hw - 0.12, -hd + 0.12),
             (-hw + 0.12, hd - 0.12), (hw - 0.12, hd - 0.12)]
    for px, py in posts:
        faces += list(b.cylinder((px, py, CH_ROOF_H * 0.5), post_r, CH_ROOF_H,
                                 POST_WOOD, segments=8, axis="Z"))

    # acoperis de panza bej, aproape plat, usoara panta intr-o singura apa
    # (spre -Y, mai jos in spate)
    roof_front_z, roof_back_z = CH_ROOF_H, CH_ROOF_H - 0.20
    roof_pts_top = [(-hw - 0.2, -hd - 0.2, roof_back_z), (hw + 0.2, -hd - 0.2, roof_back_z),
                    (hw + 0.2, hd + 0.2, roof_front_z), (-hw - 0.2, hd + 0.2, roof_front_z)]
    fr = b.bm.faces.new(tuple(b.bm.verts.new(p) for p in roof_pts_top))
    faces.append(fr)
    roof_pts_bot = [(p[0], p[1], p[2] - 0.05) for p in reversed(roof_pts_top)]
    fr2 = b.bm.faces.new(tuple(b.bm.verts.new(p) for p in roof_pts_bot))
    faces.append(fr2)

    # tejghea de lemn joasa in fata (+X), cu 2 dulapuri laterale (stanga/dreapta)
    counter_z = 0.55
    faces += list(b.box((hw - 0.35, 0.0, counter_z * 0.5), (0.7, CH_D - 0.5, counter_z), CRATE_WOOD))
    faces += list(b.box((-hw + 0.4, -hd + 0.5, counter_z * 0.5), (0.8, 1.0, counter_z), CRATE_WOOD))
    faces += list(b.box((-hw + 0.4, hd - 0.5, counter_z * 0.5), (0.8, 1.0, counter_z), CRATE_WOOD))

    # 2 oale de metal + o ceainica, pe tejghea
    for oy, r, h in ((-0.35, 0.14, 0.30), (0.35, 0.14, 0.30)):
        metal_faces += list(bm_.cylinder((hw - 0.35, oy, counter_z + h * 0.5), r, h,
                                         POT_METAL, segments=10, axis="Z"))
    # ceainica: corp mic + toc + manerul, simplificat la un corp+cioc
    kx, ky = hw - 0.35, 0.0
    kh = 0.20
    metal_faces += list(bm_.cylinder((kx, ky, counter_z + kh * 0.5), 0.09, kh,
                                     POT_METAL, segments=8, axis="Z"))
    metal_faces += list(bm_.cylinder((kx + 0.10, ky, counter_z + kh * 0.7), 0.03, 0.14,
                                     POT_METAL, segments=6, axis="Y"))

    stall_obj = b.to_object("Stall_Wood")
    for f in faces:
        if f.is_valid:
            f[b.slot] = CRATE_WOOD
    # acoperisul primeste tenta bej separat de restul (nod unic, deci
    # sloturile se aplica per-fata inainte de finish; suprascriem doar
    # cele 2 fete ale acoperisului dupa ce lista `faces` a primit deja
    # CRATE_WOOD -- corectam explicit acele 2 fete la SAND_LIGHT)
    for f in (fr, fr2):
        if f.is_valid:
            f[b.slot] = SAND_LIGHT
    metal_obj = bm_.to_object("Stall_Metal")
    for f in metal_faces:
        if f.is_valid:
            f[bm_.slot] = POT_METAL
    return stall_obj, metal_obj


# --- marigold_garland ------------------------------------------------------
#
# Contract (brief §1.5): 2.5 m deschidere, 0.8 m lasare, h/l 0.58. Element
# list (decupare marigold_garland.png): ghirlanda de margele portocalii pe o
# catenara, cu 5 ciucuri (gramezi mai mari) care atarna dedesubt.
MG_SPAN = 2.5
MG_SAG = 0.8


def build_marigold_garland():
    b = Builder()
    faces = set()
    hs = MG_SPAN * 0.5

    # margelele: icosfere mici de-a lungul catenarei (aproximata parabolic)
    n_beads = 22
    for i in range(n_beads):
        t = i / (n_beads - 1)
        x = -hs + MG_SPAN * t
        z = -MG_SAG * 4 * t * (1 - t)
        r = 0.05 + 0.01 * math.sin(t * math.pi * 6)
        faces |= _bead(b, (x, 0.0, z), r, GARLAND_ORANGE, subdivisions=1)

    # 5 ciucuri: gramezi mai mari, atarnate sub catenara la pozitii regulate
    n_tassels = 5
    for i in range(n_tassels):
        t = (i + 0.5) / n_tassels
        x = -hs + MG_SPAN * t
        z = -MG_SAG * 4 * t * (1 - t)
        tassel_len = 0.18
        faces |= _bead(b, (x, 0.0, z - tassel_len * 0.5), 0.09,
                       GARLAND_ORANGE, subdivisions=1)
        faces |= _bead(b, (x, 0.0, z - tassel_len), 0.06,
                       GARLAND_ORANGE, subdivisions=1)

    obj = b.to_object("Garland")
    for f in faces:
        if f.is_valid:
            f[b.slot] = GARLAND_ORANGE
    return (obj,)


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Identic cu `emit` din build_jodhpur_pilot.py/build_jodhpur_city.py."""
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


sc_a = _build_stall_canopy(CAR_YELLOW, [SPICE_RED, SPICE_YELLOW, FRUIT_ORANGE])
# buget masurat, nu presupus: 1400 initial era o estimare fara masuratoare.
# Cele 4 stalpi + rama + copertina lasata (catenara reala, nu plan drept) +
# 3 niveluri de lada cu marfa (brief: "lazi in trepte") ajung la 1520 tri
# dupa bevel -- segmentele copertinei deja reduse (5->4, vezi cod) fara sa
# schimbe cifra semnificativ; forma completa, nu se taie mai mult.
emit(list(sc_a), "props/stall_canopy_a.glb", AO_PROP, bevel=0.02, budget=1600)

sc_b = _build_stall_canopy(FLAMINGO_PINK, [SPICE_YELLOW, FRUIT_ORANGE, SPICE_YELLOW])
emit(list(sc_b), "props/stall_canopy_b.glb", AO_PROP, bevel=0.02, budget=1600)

sc_c = _build_stall_canopy(TROPICAL_GREEN, [FRUIT_GREEN, FRUIT_ORANGE, SPICE_RED])
emit(list(sc_c), "props/stall_canopy_c.glb", AO_PROP, bevel=0.02, budget=1600)

ts = build_textile_strip()
emit(list(ts), "props/textile_strip.glb", AO_PROP, bevel=0.015, budget=1600)

ss = build_spice_sacks()
emit(list(ss), "props/spice_sacks.glb", AO_PROP, bevel=0.02, budget=1400)

tc = build_thela_cart()
# buget masurat, nu presupus: 4 roti cu spite reale (disc+butuc+bare, ceruta
# explicit de brief "4, nu 2" -- planșa castiga) costa ~380 tri/roata dupa
# bevel = ~1520 tri doar pe roti; platforma+fructele adauga restul. 2200
# initial era o estimare fara masuratoare -- 3028 ramane forma completa.
emit(list(tc), "props/thela_cart.glb", AO_PROP, bevel=0.02, budget=3100)

cs = build_chai_stall()
emit(list(cs), "props/chai_stall.glb", AO_PROP, bevel=0.02, budget=1600)

mg = build_marigold_garland()
# buget masurat: fara bevel pe icosfere (deja rotunjite prin subdivisions,
# memoria plafon-masurat-nu-presupus -- 2400 initial supraestima costul)
emit(list(mg), "props/marigold_garland.glb", AO_PROP, bevel=0.0, budget=800)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL bazarul: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for pieces in (sc_a, sc_b, sc_c, ts, ss, tc, cs, mg) for o in pieces if o is not None],
          "jodhpur_bazaar.blend")
