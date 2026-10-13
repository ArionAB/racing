"""Transfagarasan -- cladirile (brief docs/asset_briefs/transfagarasan_kit.md §1.3).

  transfagarasan/buildings/cabana_balea_lac.glb       cabana Balea Lac (prima, judecata separat)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_buildings.py

Variabila de mediu TF_ONLY=<piesa> reface doar piesa respectiva.

Conventii (kit §0): fata bogata (terasa, scara, intrarile) pe +Y in Blender
(= -Z in Godot), masurata pe GLB (`preview_tf_e.py --facade <piesa>`). Originea
pe centrul corpului cladirii, baza la z = 0 (offset calculat O DATA pe
ansamblu, `emit_tf`). Un nod = un rol / o clasa: `*_Stone` (MARBLE_GREY),
`*_Wood` (WOOD_WEATHERED + LOG_DARK pe ramele si brauri), `*_Roof` (tabla),
`*_Plaster` (FOAM_WHITE), `*_Void` (VOLCANIC_BLACK: ferestre si usi).

Ferestrele si usile sunt GOLURI reale: corpul plin e taiat boolean cu adancimea
`OPEN_D` (0,22 m), iar fundul golului e acoperit, 2 mm in fata, de placa neagra
din nodul `*_Void`. Ramele ies 5 cm in fata peretelui, la 2 mm de el (lectia
val 1: un strat lipit coplanar fura slotul la `assign_uvs`).
Fara text, fara vegetatie lipita de cladiri (corecturile coordonatorului).
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py"), encoding="utf-8").read())

clear_built()

OPEN_D = 0.22          # adancimea golului (>= 0,15 m, contract)
FRAME = 0.08           # latimea ramei
FRAME_OUT = 0.05       # cat iese rama din perete
GAP = 0.002            # distanta dintre straturi (anti-furt de slot)

# WOOD (dio_lib) = 9, WOOD_WEATHERED #835C34; RUST = 10 RUST_METAL; PAINTED = 11 PAINTED_METAL
TRIM = LOG_DARK        # 28 #4A3526: brauri, stalpi de colt, rame
STONE = MARBLE_GREY    # 29 #B8B4AC: parterul, cosul
VOID = VOLCANIC_BLACK  # 20

AO_BUILDING = dict(samples=16, dist=1.6, gradient="vertical", low=0.66, high=1.0,
                   power=0.8, floor=0.38, z_range=(0.0, 12.0))


# ---------------------------------------------------------------------------
# unelte: prisma, goluri, boolean
# ---------------------------------------------------------------------------

def prism_yz(b, outline, x0, x1, slot):
    """Prisma dintr-un contur (y, z) extrudat pe X intre x0 si x1 (frontoane pe
    capetele X). Conturul poate fi in orice sens: normalele le repara recalc."""
    n = len(outline)
    a = [b.bm.verts.new((x0, y, z)) for y, z in outline]
    c = [b.bm.verts.new((x1, y, z)) for y, z in outline]
    for ring in (a, list(reversed(c))):
        f = b.bm.faces.new(ring)
        f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((a[i], a[j], c[j], c[i]))
        f[b.slot] = slot


def prism_xz(b, outline, y0, y1, slot):
    """Prisma dintr-un contur (x, z) extrudat pe Y intre y0 si y1."""
    n = len(outline)
    a = [b.bm.verts.new((x, y0, z)) for x, z in outline]
    c = [b.bm.verts.new((x, y1, z)) for x, z in outline]
    for ring in (a, list(reversed(c))):
        f = b.bm.faces.new(ring)
        f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((a[i], a[j], c[j], c[i]))
        f[b.slot] = slot


class Openings:
    """Colecteaza golurile unei piese: cutiile de taiere (pe material de corp),
    placile negre de fund (nodul *_Void) si ramele (nodul de lemn)."""

    def __init__(self, void_b, trim_b, frame_slot=TRIM):
        self.cut = {}            # cheie corp -> Builder de taiere
        self.void = void_b
        self.trim = trim_b
        self.frame_slot = frame_slot
        self.log = []            # (fata, tip, w, h)

    def _cut_b(self, key):
        if key not in self.cut:
            self.cut[key] = Builder()
        return self.cut[key]

    def add(self, key, face, plane, c, w, z0, z1, kind="window", frame=True,
            cross=True, sill=True, depth=OPEN_D):
        """Gol pe fata `face` ('+X','-X','+Y','-Y') a corpului `key`; `plane` =
        distanta fetei de la axa (semnul il da `face`), `c` = pozitia centrului
        de-a lungul peretelui."""
        sg = 1.0 if face[0] == "+" else -1.0
        plane = sg * abs(plane)
        onx = face[1] == "X"
        h = z1 - z0
        zc = (z0 + z1) * 0.5

        def P(along, out, z):
            """punct din (de-a lungul, iesire din fata, z) -> lume"""
            return (plane + sg * out, along, z) if onx else (along, plane + sg * out, z)

        def S(along, out, z):
            return (out, along, z) if onx else (along, out, z)

        # taierea: din aer (0,3 m in fata) pana la `depth` in corp
        self._cut_b(key).box(P(c, (0.3 - depth) * 0.5, zc), S(w, 0.3 + depth, h), 0)
        # fundul golului: placa neagra la GAP in fata fundului taiat
        self.void.box(P(c, -depth + GAP - 0.01, zc), S(w - 0.004, 0.02, h - 0.004), VOID)
        if frame:
            fs = self.frame_slot
            o = GAP + FRAME_OUT * 0.5
            self.trim.box(P(c, o, z1 + FRAME * 0.5), S(w + 2 * FRAME, FRAME_OUT, FRAME), fs)
            if kind == "window":
                so = GAP + 0.05
                self.trim.box(P(c, so, z0 - FRAME * 0.5), S(w + 2 * FRAME + 0.08, 0.10, FRAME), fs)
            for s in (-1, 1):
                zb = z0 - (FRAME if kind == "window" else 0.0)
                self.trim.box(P(c + s * (w + FRAME) * 0.5, o, (zb + z1 + FRAME) * 0.5),
                              S(FRAME, FRAME_OUT, z1 + FRAME - zb), fs)
        if cross and kind == "window":
            # montantii ferestrei in patru ochiuri, retrasi in gol
            ins = -depth * 0.45
            self.trim.box(P(c, ins, zc), S(0.05, 0.04, h - 0.01), self.frame_slot)
            self.trim.box(P(c, ins, zc), S(w - 0.01, 0.04, 0.05), self.frame_slot)
        self.log.append((face, kind, w, h))

    def apply(self, key, obj, slot):
        """Taie golurile din corpul `obj` (boolean EXACT) si pune tot corpul pe `slot`."""
        if key in self.cut:
            cutter = Builder.to_object(self.cut[key], "Cutter_" + key)
            bool_apply(obj, cutter, "DIFFERENCE")
            bpy.data.objects.remove(cutter, do_unlink=True)
        retag_all(obj, slot)
        return obj


def bool_apply(obj, cutter, op):
    mod = obj.modifiers.new("Bool", "BOOLEAN")
    mod.operation = op
    mod.object = cutter
    mod.solver = "EXACT"
    mod.use_self = True
    mod.use_hole_tolerant = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def retag_all(obj, slot):
    """Dupa boolean, fetele noi n-au slot (ar cadea pe 0, SAND_LIGHT): totul pe `slot`."""
    me = obj.data
    a = me.attributes.get("slot")
    if a is None or a.domain != "FACE":
        if a is not None:
            me.attributes.remove(a)
        a = me.attributes.new("slot", "INT", "FACE")
    for i in range(len(me.polygons)):
        a.data[i].value = slot


def join(objs, name):
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    objs[0].data.name = name
    return objs[0]


def railing_boards(b, p0, p1, h, slot, board_w=0.13, gap=0.09, t=0.03, rail=(0.12, 0.06)):
    """Balustrada din SCANDURI DREPTE (corectura coordonatorului, nu baluștri
    sculptati): mana curenta + lisa de jos + scanduri verticale cu rost."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    L = d.length
    u = d.normalized()
    nrm = Vector((-u.y, u.x, 0.0))
    b.beam(p0 + Vector((0, 0, h - rail[1] * 0.5)), p1 + Vector((0, 0, h - rail[1] * 0.5)),
           (rail[0], rail[1]), slot, up=(0, 0, 1))
    b.beam(p0 + Vector((0, 0, 0.12)), p1 + Vector((0, 0, 0.12)), (0.08, 0.06), slot, up=(0, 0, 1))
    n = max(1, int((L - 0.1) / (board_w + gap)))
    for i in range(n):
        s = (i + 0.5) / n * L
        p = p0 + u * s
        rot = Matrix((u, nrm, Vector((0, 0, 1)))).transposed()
        b.box((p.x, p.y, p.z + (0.09 + h - rail[1]) * 0.5), (board_w, t, h - rail[1] - 0.09), slot,
              rotation=rot)


# ---------------------------------------------------------------------------
# cabana_balea_lac
# ---------------------------------------------------------------------------

def build_cabana_balea_lac():
    """Cabana Balea Lac (`cabana_balea_lac`), kit §1.3: 16 x 10 m, 11 m la coama.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/cabana_balea_lac.png`,
    scrisa INAINTE de primul vertex; fasia alba din piesa vecina, la marginea
    stanga a decuparii, se ignora). Pe decupare frontonul e in stanga (aici +X),
    latura lunga cu terasa in dreapta (aici +Y, fata bogata):
      1) PARTER DE PIATRA, 3 m, gri, pe tot conturul; colturile din pietre mai
         mari (aici 4 pietre de colt alternante pe fiecare muchie, relief 3 cm)
      2) ETAJUL 1 DE LEMN (scanduri maro-portocalii), iese putin peste piatra
         (aici 0,15 m); brau inchis la baza lui (linia piatra/lemn); stalpi de
         colt inchisi
      3) AL DOILEA NIVEL DE LEMN = mansarda din fronton, desparțita de etajul 1
         printr-un brau orizontal pe fronton (decuparea: o streasina mica)
      4) ACOPERIS ABRUPT de tabla argintie-gri in doua ape, coama paralela cu
         latura lunga, streasina larga, falturi pe panta; scanduri de bordura
         (deschise la culoare) sub marginea frontoanelor
      5) LUCARNE: decuparea arata 1 pe apa din fata; contractul cere 2 -> 2
         lucarne in doua ape pe apa +Y, cu cate o fereastra
      6) COS: 1, langa varful frontonului din stanga, iese ~1,2 m peste coama.
         Pe decupare e caramiziu; contractul cere "cos de piatra" -> piatra
         (MARBLE_GREY, nodul de piatra)
      7) un tub mic de aerisire pe coama (decuparea: punct negru pe coama)
      FERESTRE, in randuri regulate, cu rama de lemn si cruce (4 ochiuri):
      8) fronton (+X): parter 3 ferestre mici; etaj 4 ferestre (doua perechi);
         mansarda 3 ferestre grupate + 1 aerisire mica sub varf
      9) latura +Y: parter 1 fereastra + 1 usa sub terasa; etaj 4 ferestre +
         1 usa spre terasa
     10) latura -Y si frontonul -X (nevazute pe decupare): ferestre in aceleasi
         randuri, mai putine (spatele nu e gol: cabana se vede si din urcare)
     11) TERASA pe +Y la capatul -X (decuparea: dreapta), la nivelul etajului,
         pe 4 stalpi, cu BALUSTRADA DIN SCANDURI DREPTE pe 3 laturi
         (corectura: fara balcon sculptat) si o SCARA dreapta care coboara
         perpendicular pe perete, spre +Y
     12) NU intra: veranda de jos cu acoperis propriu din dreapta decuparii
         (corectura: "cel mult o terasa simpla"), bolovanii si iarba de la
         baza, tufa lipita in stanga (vegetatia vine la integrare)

    Cote: corpul de lemn 16 x 10 m, piatra 15,7 x 9,7 x 3 m; panta 45 de grade
    (contract ~50: cu 50 si coama la 11 m, peretele de lemn al laturii lungi
    iese 1,6 m sub tabla, sub inaltimea unei usi; runda 2 la 47 de grade a
    aratat inca o fasie scunda sub streasina, decuparea are etaj intreg);
    streasina 0,6 m; coama (capacul) ~11,0 m.
    Noduri: Cabana_Stone, Cabana_Wood, Cabana_Roof, Cabana_Void."""
    stone, wood_body, trim, roof, void = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, trim)

    HX, HY = 8.0, 5.0            # corpul de lemn (semi)
    SX, SY = 7.85, 4.85          # parterul de piatra (semi)
    Z1 = 3.0                     # piatra / lemn
    PITCH = 45.0
    OVER = 0.6
    t = math.tan(math.radians(PITCH))
    RIDGE_TOP = 10.90            # fata de sus a tablei la coama (capacul +0,1)
    z_eave = RIDGE_TOP - (HY + OVER) * t
    R = tin_roof(roof, 0.0, 0.0, HX + OVER, HY + OVER, z_eave, PITCH, PAINTED)
    zu_wall = R["under"](0.0, HY) - 0.02          # cota de sus a peretelui lung
    zu_ridge = R["under"](0.0, 0.0) - 0.02

    # --- 1) parterul de piatra (corp plin, taiat de goluri)
    stone.box((0.0, 0.0, Z1 * 0.5), (2 * SX, 2 * SY, Z1), STONE)
    # pietre de colt alternante, 3 cm relief pe ambele fete
    for sx in (-1, 1):
        for sy in (-1, 1):
            for k in range(4):
                z = 0.2 + k * 0.72 + 0.17
                lx, ly = (0.62, 0.34) if k % 2 == 0 else (0.34, 0.62)
                stone.box((sx * (SX - lx * 0.5 + 0.03), sy * (SY - ly * 0.5 + 0.03), z),
                          (lx, ly, 0.34), STONE)

    # --- 2/3) corpul de lemn: etajul + frontoanele, pana sub tabla
    prism_yz(wood_body, [(-HY, Z1), (HY, Z1), (HY, zu_wall), (0.0, zu_ridge), (-HY, zu_wall)],
             -HX, HX, WOOD)
    # brau la baza lemnului (iese 6 cm), stalpi de colt
    zb0, zb1 = Z1 - 0.06, Z1 + 0.22
    for sy in (-1, 1):
        trim.box((0.0, sy * (HY - 0.04), (zb0 + zb1) * 0.5), (2 * HX + 0.2, 0.2, zb1 - zb0), TRIM)
    for sx in (-1, 1):
        trim.box((sx * (HX - 0.04), 0.0, (zb0 + zb1) * 0.5), (0.2, 2 * HY + 0.2, zb1 - zb0), TRIM)
        for sy in (-1, 1):
            trim.box((sx * (HX - 0.07), sy * (HY - 0.07), (zb1 + zu_wall) * 0.5),
                     (0.24, 0.24, zu_wall - zb1), TRIM)
    # 3) braul de pe fronton, intre etaj si mansarda (o streasina mica)
    zg = zu_wall - 0.05
    for sx in (-1, 1):
        trim.box((sx * (HX + 0.06), 0.0, zg), (0.22, 2 * HY + 0.1, 0.22), TRIM)
        trim.beam((sx * (HX + 0.16), -HY - 0.05, zg + 0.17), (sx * (HX + 0.16), HY + 0.05, zg + 0.17),
                  (0.14, 0.32), TRIM, up=(sx * 0.6, 0.0, 1.0))
    # 4) scanduri de bordura sub marginea frontonului (sub placa de tabla)
    for sx in (-1, 1):
        xb = sx * (HX + OVER - 0.06)
        for sy in (-1, 1):
            ya, yb = sy * (HY + OVER), 0.0
            za = R["under"](0.0, ya) - 0.15
            zb = R["under"](0.0, yb) - 0.15
            wood_trim_beam = ((xb, ya, za), (xb, yb, zb))
            trim.beam(wood_trim_beam[0], wood_trim_beam[1], (0.3, 0.07), WOOD, up=(sx, 0.0, 0.0))

    # --- 5) lucarnele (doua, pe apa +Y)
    dorm_w, dorm_y = 2.4, 3.2
    for xc in (3.2, -2.4):
        zt = R["top"](xc, dorm_y)            # tabla in fata lucarnei
        z_de = zt + 1.3                      # streasina lucarnei
        prism_xz(wood_body, [(xc - dorm_w * 0.5, zt - 0.6), (xc + dorm_w * 0.5, zt - 0.6),
                             (xc + dorm_w * 0.5, z_de), (xc, z_de + dorm_w * 0.5 - 0.1),
                             (xc - dorm_w * 0.5, z_de)], 0.4, dorm_y, WOOD)
        tin_roof(roof, xc, (0.4 + dorm_y + 0.3) * 0.5, (dorm_y + 0.3 - 0.4) * 0.5,
                 dorm_w * 0.5 + 0.25, z_de - 0.06, 45.0, PAINTED, axis="Y",
                 rib_w=0.04)
        op.add("wood", "+Y", dorm_y, xc, 1.0, zt + 0.25, zt + 1.05)

    # --- 6) cosul de piatra, langa varful frontonului +X, peste coama
    chx, chy = HX - 1.5, -0.2
    ch_top = RIDGE_TOP + 1.25
    stone.box((chx, chy, (zu_ridge - 1.5 + ch_top) * 0.5), (0.9, 0.9, ch_top - zu_ridge + 1.5), STONE)
    stone.box((chx, chy, ch_top + 0.08), (1.1, 1.1, 0.16), STONE)
    void.box((chx, chy, ch_top + 0.16 + GAP + 0.01), (0.42, 0.42, 0.02), VOID)
    # 7) tubul de aerisire pe apa din spate, langa coama
    void.cylinder((-4.2, -0.9, R["top"](-4.2, -0.9) + 0.35), 0.08, 0.9, VOID, segments=8)

    # --- 8) frontonul +X
    zs0, zs1 = 1.1, 1.85                       # parter
    zw0, zw1 = Z1 + 0.62, Z1 + 1.62            # etaj
    za0, za1 = zu_wall + 0.55, zu_wall + 1.45  # mansarda
    for y in (-3.0, 0.0, 3.0):
        op.add("stone", "+X", SX, y, 0.7, zs0, zs1)
    for y in (-3.5, -2.1, 2.1, 3.5):
        op.add("wood", "+X", HX, y, 0.8, zw0, zw1)
    for y in (-1.05, 0.0, 1.05):
        op.add("wood", "+X", HX, y, 0.62, za0, za1)
    op.add("wood", "+X", HX, 0.0, 0.32, za1 + 1.25, za1 + 1.75, cross=False, sill=False)
    # --- 9) latura +Y (fata bogata)
    op.add("stone", "+Y", SY, 4.6, 0.7, zs0, zs1)
    op.add("stone", "+Y", SY, -4.7, 1.0, 0.04, 2.05, kind="door")
    for x in (6.2, 3.6, 1.6, -0.6):
        op.add("wood", "+Y", HY, x, 0.8, zw0, zw1)
    op.add("wood", "+Y", HY, -5.8, 1.0, Z1 + 0.26, Z1 + 2.2, kind="door")
    op.add("wood", "+Y", HY, -3.6, 0.8, zw0, zw1)
    # --- 10) spatele (-Y) si frontonul -X
    for x in (-4.5, 0.0, 4.5):
        op.add("stone", "-Y", SY, x, 0.7, zs0, zs1)
    for x in (-5.5, -2.0, 2.0, 5.5):
        op.add("wood", "-Y", HY, x, 0.8, zw0, zw1)
    for y in (-2.5, 2.5):
        op.add("stone", "-X", SX, y, 0.7, zs0, zs1)
        op.add("wood", "-X", HX, y, 0.8, zw0, zw1)
    op.add("wood", "-X", HX, 0.0, 0.62, za0, za1)

    # --- 11) terasa pe +Y, capatul -X, la nivelul etajului, si scara
    tx0, tx1 = -7.6, -1.6
    ty0, ty1 = HY, HY + 2.4
    deck_top = Z1
    terr = Builder()
    terr.box(((tx0 + tx1) * 0.5, (ty0 + ty1) * 0.5 + 0.05, deck_top - 0.1),
             (tx1 - tx0, ty1 - ty0 + 0.1, 0.2), WOOD)
    for x in (tx0 + 0.15, (tx0 + tx1) * 0.5, tx1 - 0.15):
        terr.box((x, ty1 - 0.15, (deck_top - 0.2) * 0.5), (0.22, 0.22, deck_top - 0.2), TRIM)
    terr.box(((tx0 + tx1) * 0.5, ty1 - 0.15, deck_top - 0.32), (tx1 - tx0, 0.2, 0.24), TRIM)
    # scara: 1,1 m lata, coboara spre +Y de pe muchia terasei, intre x -3,0 si -1,9
    sx0, sx1 = -3.05, -1.9
    nst = 11
    rise = deck_top / (nst + 1)
    run = 0.29
    foot = ty1 + nst * run
    for i in range(nst):
        z = deck_top - rise * (i + 1)
        y = ty1 + run * (i + 0.5)
        terr.box(((sx0 + sx1) * 0.5, y, z - 0.03), (sx1 - sx0 - 0.1, run + 0.04, 0.06), WOOD)
    for x in (sx0 + 0.05, sx1 - 0.05):
        terr.beam((x, ty1 - 0.1, deck_top - 0.12), (x, foot + 0.05, 0.20), (0.28, 0.08), TRIM,
                  up=(1.0, 0.0, 0.0))
        terr.beam((x, ty1, deck_top + 0.95), (x, foot - 0.2, 1.0), (0.07, 0.08), WOOD,
                  up=(0.0, 0.0, 1.0))
        terr.box((x, foot - 0.2, 0.5), (0.1, 0.1, 1.0), TRIM)
    # balustrada din scanduri drepte: fata (lasand gura scarii), capatul -X, capatul +X
    rh = 1.0
    railing_boards(terr, (tx0 + 0.05, ty1 - 0.05, deck_top), (sx0, ty1 - 0.05, deck_top), rh, WOOD)
    railing_boards(terr, (sx1, ty1 - 0.05, deck_top), (tx1 - 0.05, ty1 - 0.05, deck_top), rh, WOOD)
    railing_boards(terr, (tx0 + 0.05, ty0 + 0.08, deck_top), (tx0 + 0.05, ty1 - 0.05, deck_top), rh, WOOD)
    railing_boards(terr, (tx1 - 0.05, ty0 + 0.08, deck_top), (tx1 - 0.05, ty1 - 0.05, deck_top), rh, WOOD)
    for x in (tx0 + 0.05, sx0, sx1, tx1 - 0.05):
        terr.box((x, ty1 - 0.05, deck_top + rh * 0.5), (0.12, 0.12, rh + 0.08), TRIM)

    # --- obiectele: taiere, lipire, noduri
    st_o = op.apply("stone", Builder.to_object(stone, "Cabana_Stone"), STONE)
    wb_o = op.apply("wood", Builder.to_object(wood_body, "WoodBody"), WOOD)
    tr_o = Builder.to_object(trim, "WoodTrim")
    te_o = Builder.to_object(terr, "WoodTerrace")
    wood_o = join([wb_o, tr_o, te_o], "Cabana_Wood")
    print("cabana_balea_lac: goluri", len(op.log), "| coama la %.2f, streasina la %.2f, perete lung %.2f"
          % (RIDGE_TOP, z_eave, zu_wall))
    return [st_o, wood_o, Builder.to_object(roof, "Cabana_Roof"), to_obj(void, "Cabana_Void")]


# ---------------------------------------------------------------------------

ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    """Curata scena inainte de fiecare piesa (altfel nume `*.001` in GLB)."""
    if ONLY and ONLY != name:
        return False
    clear_built()
    for o in list(bpy.data.objects):
        if o.type == "EMPTY":
            bpy.data.objects.remove(o, do_unlink=True)
    return True


if _want("cabana_balea_lac"):
    emit_tf(build_cabana_balea_lac(), "buildings/cabana_balea_lac.glb", AO_BUILDING,
            keep_xy=True, bevel=0.0, smooth_angle=None)

report_tf()
