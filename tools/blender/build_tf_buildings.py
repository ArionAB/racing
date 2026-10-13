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

# WOOD (dio_lib) = 9 WOOD_WEATHERED #835C34; RUST = 10 RUST_METAL
TRIM = LOG_DARK        # 28 #4A3526: brauri, stalpi de colt, rame
STONE = MARBLE_GREY    # 29 #B8B4AC: parterul, cosul
VOID = VOLCANIC_BLACK  # 20
ROOF_SILVER = ASPHALT_EDGE   # 6 #696765: tabla argintie (decizia coordonatorului:
                             # PAINTED_METAL #7692A8 iesea albastru; clasa o lumineaza)
ROOF_RED = KERB_RED          # 7: tabla rosie (arges_house_b)
ROOF_RUST = RUST             # 10 RUST_METAL: tabla ruginie (cascada, stana)

AO_BUILDING = dict(samples=16, dist=1.6, gradient="vertical", low=0.66, high=1.0,
                   power=0.8, floor=0.38, z_range=(0.0, 14.0))


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
# piese de cladire comune (cabane, case)
# ---------------------------------------------------------------------------

def stone_base(b, SX, SY, Z1, quoins=True, slot=None):
    """Parter / soclu de piatra plin (+-SX, +-SY, 0..Z1) cu pietre de colt
    alternante (relief 3 cm pe ambele fete)."""
    slot = STONE if slot is None else slot
    b.box((0.0, 0.0, Z1 * 0.5), (2 * SX, 2 * SY, Z1), slot)
    if not quoins:
        return
    n = max(1, int((Z1 - 0.2) / 0.72))
    for sx in (-1, 1):
        for sy in (-1, 1):
            for k in range(n):
                z = 0.2 + k * 0.72 + 0.17
                lx, ly = (0.62, 0.34) if k % 2 == 0 else (0.34, 0.62)
                b.box((sx * (SX - lx * 0.5 + 0.03), sy * (SY - ly * 0.5 + 0.03), z),
                      (lx, ly, 0.34), slot)


def wood_bands(trim, HX, HY, levels, z_top, posts=True):
    """Braurile LOG_DARK (ies 6 cm) la baza fiecarui nivel de lemn si stalpii
    de colt pana sub tabla."""
    for zl in levels:
        zb0, zb1 = zl - 0.06, zl + 0.2
        for sy in (-1, 1):
            trim.box((0.0, sy * (HY - 0.04), (zb0 + zb1) * 0.5), (2 * HX + 0.2, 0.2, zb1 - zb0), TRIM)
        for sx in (-1, 1):
            trim.box((sx * (HX - 0.04), 0.0, (zb0 + zb1) * 0.5), (0.2, 2 * HY + 0.2, zb1 - zb0), TRIM)
    if posts:
        z0 = levels[0] + 0.2
        for sx in (-1, 1):
            for sy in (-1, 1):
                trim.box((sx * (HX - 0.07), sy * (HY - 0.07), (z0 + z_top) * 0.5),
                         (0.24, 0.24, z_top - z0), TRIM)


def barge_boards(trim, R, ex, ey, slot=None, axis="X"):
    """Scanduri de bordura sub marginea frontoanelor (sub placa de tabla), la
    capetele coamei (+-ex de-a lungul ei; streasina la +-ey)."""
    slot = WOOD if slot is None else slot
    for s in (-1, 1):
        for sy in (-1, 1):
            if axis == "X":
                xb = s * (ex - 0.06)
                pa, pb = (xb, sy * ey), (xb, 0.0)
                up = (s, 0.0, 0.0)
            else:
                yb = s * (ex - 0.06)
                pa, pb = (sy * ey, yb), (0.0, yb)
                up = (0.0, s, 0.0)
            za = R["under"](*pa) - 0.15
            zb = R["under"](*pb) - 0.15
            trim.beam((pa[0], pa[1], za), (pb[0], pb[1], zb), (0.3, 0.07), slot, up=up)


def dormer(wood_b, roof_b, op, R, xc, y_front, w, roof_slot, y_back=0.4, win=(1.0, 0.8)):
    """Lucarna in doua ape pe apa +Y a unui acoperis cu coama pe X: corp de lemn
    (pentagon extrudat pe Y, ingropat in acoperis), tabla proprie cu coama pe Y,
    o fereastra (gol) in fata."""
    zt = R["top"](xc, y_front)
    z_de = zt + 1.3
    prism_xz(wood_b, [(xc - w * 0.5, zt - 0.6), (xc + w * 0.5, zt - 0.6),
                      (xc + w * 0.5, z_de), (xc, z_de + w * 0.5 - 0.1),
                      (xc - w * 0.5, z_de)], y_back, y_front, WOOD)
    tin_roof(roof_b, xc, (y_back + y_front + 0.3) * 0.5, (y_front + 0.3 - y_back) * 0.5,
             w * 0.5 + 0.25, z_de - 0.06, 45.0, roof_slot, axis="Y", rib_w=0.04)
    op.add("wood", "+Y", y_front, xc, win[0], zt + 0.25, zt + 0.25 + win[1])


def chimney(stone_b, void_b, x, y, z0, z_top, size=0.9, slot=None):
    """Cos de piatra (sau tabla, cu `slot`) cu coronament si gura neagra."""
    slot = STONE if slot is None else slot
    stone_b.box((x, y, (z0 + z_top) * 0.5), (size, size, z_top - z0), slot)
    stone_b.box((x, y, z_top + 0.08), (size + 0.2, size + 0.2, 0.16), slot)
    void_b.box((x, y, z_top + 0.16 + GAP + 0.01), (size * 0.47, size * 0.47, 0.02), VOID)


def terrace(terr, tx0, tx1, ty0, ty1, deck_top, stair=None, rh=1.0):
    """Terasa simpla pe +Y (podea, stalpi, grinda) cu balustrada din scanduri
    drepte pe 3 laturi; `stair` = (x0, x1): scara dreapta care coboara
    perpendicular pe perete, spre +Y, din muchia din fata."""
    terr.box(((tx0 + tx1) * 0.5, (ty0 + ty1) * 0.5 + 0.05, deck_top - 0.1),
             (tx1 - tx0, ty1 - ty0 + 0.1, 0.2), WOOD)
    for x in (tx0 + 0.15, (tx0 + tx1) * 0.5, tx1 - 0.15):
        terr.box((x, ty1 - 0.15, (deck_top - 0.2) * 0.5), (0.22, 0.22, deck_top - 0.2), TRIM)
    terr.box(((tx0 + tx1) * 0.5, ty1 - 0.15, deck_top - 0.32), (tx1 - tx0, 0.2, 0.24), TRIM)
    front = [(tx0 + 0.05, tx1 - 0.05)]
    if stair:
        sx0, sx1 = stair
        nst = max(2, int(round(deck_top / 0.26)) - 1)
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
            terr.beam((x, ty1, deck_top + rh - 0.05), (x, foot - 0.2, 1.0), (0.07, 0.08), WOOD,
                      up=(0.0, 0.0, 1.0))
            terr.box((x, foot - 0.2, 0.5), (0.1, 0.1, 1.0), TRIM)
        front = [(tx0 + 0.05, sx0), (sx1, tx1 - 0.05)]
    for a, c in front:
        railing_boards(terr, (a, ty1 - 0.05, deck_top), (c, ty1 - 0.05, deck_top), rh, WOOD)
    railing_boards(terr, (tx0 + 0.05, ty0 + 0.08, deck_top), (tx0 + 0.05, ty1 - 0.05, deck_top), rh, WOOD)
    railing_boards(terr, (tx1 - 0.05, ty0 + 0.08, deck_top), (tx1 - 0.05, ty1 - 0.05, deck_top), rh, WOOD)
    posts = [tx0 + 0.05, tx1 - 0.05] + (list(stair) if stair else [])
    for x in posts:
        terr.box((x, ty1 - 0.05, deck_top + rh * 0.5), (0.12, 0.12, rh + 0.08), TRIM)


# ---------------------------------------------------------------------------
# cabana_balea_lac
# ---------------------------------------------------------------------------

def build_cabana_balea_lac():
    """Cabana Balea Lac (`cabana_balea_lac`), kit §1.3, CONTRACT REVIZUIT de
    coordonator dupa etapa 1: 13 x 10 m, parter de piatra 3 m, DOUA niveluri
    intregi de lemn de 2,7 m (peretele lung ~8,4 m pana la streasina), panta
    ~45-48, coama ~13 m. Rev. 1 (16 x 10, coama 11) citea sura lunga si joasa.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/cabana_balea_lac.png`,
    scrisa INAINTE de primul vertex; fasia alba din piesa vecina, la marginea
    stanga a decuparii, se ignora). Pe decupare frontonul e in stanga (aici +X),
    latura lunga cu terasa in dreapta (aici +Y, fata bogata):
      1) PARTER DE PIATRA, 3 m, gri, pe tot conturul; colturile din pietre mai
         mari (aici 4 pietre de colt alternante pe fiecare muchie, relief 3 cm)
      2) DOUA NIVELURI DE LEMN de 2,7 m (contractul revizuit), lemnul iese
         putin peste piatra (aici 0,15 m); brau inchis la baza lemnului si
         intre niveluri; stalpi de colt inchisi
      3) FRONTONUL de deasupra nivelului 2, despartit printr-un brau orizontal
         (decuparea: o streasina mica), cu aerisirea sub varf
      4) ACOPERIS ABRUPT de tabla argintie in doua ape (ASPHALT_EDGE 6,
         decizia coordonatorului: PAINTED_METAL iesea albastru), coama paralela
         cu latura lunga, streasina larga, falturi pe panta; scanduri de bordura
         sub marginea frontoanelor
      5) LUCARNE: decuparea arata 1 pe apa din fata; contractul cere 2 -> 2
         lucarne in doua ape pe apa +Y, cu cate o fereastra
      6) COS: 1, langa varful frontonului din stanga, iese ~1,2 m peste coama.
         Pe decupare e caramiziu; contractul cere "cos de piatra" -> piatra
      7) un tub mic de aerisire pe coama (decuparea: punct negru pe coama)
      FERESTRE, in randuri regulate, cu rama de lemn si cruce (4 ochiuri):
      8) fronton (+X): TREI randuri, ca pe decupare: parter 3 mici; nivelul 1
         4 (doua perechi); nivelul 2 3 grupate; + 1 aerisire sub varf
      9) latura +Y: parter 1 fereastra + 1 usa sub terasa; nivelul 1 3 ferestre
         + usa spre terasa + 1 fereastra peste terasa; nivelul 2 5 ferestre
     10) latura -Y si frontonul -X (nevazute pe decupare): ferestre in aceleasi
         randuri, mai putine
     11) TERASA pe +Y la capatul -X (decuparea: dreapta), la nivelul 1 (+3 m),
         pe 3 stalpi, cu BALUSTRADA DIN SCANDURI DREPTE pe 3 laturi
         (corectura: fara balcon sculptat) si o SCARA dreapta care coboara
         perpendicular pe perete, spre +Y
     12) NU intra: veranda de jos cu acoperis propriu din dreapta decuparii
         (corectura: "cel mult o terasa simpla"), bolovanii si iarba de la
         baza, tufa lipita in stanga (vegetatia vine la integrare)

    Cote: corpul de lemn 13 x 10 m, piatra 12,7 x 9,7 x 3 m, lemnul 3,0 -> 8,4 m
    (2 x 2,7); panta 45 de grade, streasina 0,6 m. Coama iese ~13,6 m: cu
    peretele la 8,4 si semideschiderea de 5 m, 45 de grade dau +5 m (contractul
    "~13 m" si "45-48" nu incap amandoua; s-a pastrat peretele de 2 x 2,7).
    Noduri: Cabana_Stone, Cabana_Wood, Cabana_Roof, Cabana_Void."""
    stone, wood_body, trim, roof, void = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, trim)

    HX, HY = 6.5, 5.0            # corpul de lemn (semi)
    SX, SY = 6.35, 4.85          # parterul de piatra (semi)
    Z1, Z2, ZW = 3.0, 5.7, 8.4   # piatra / nivelul 1 / nivelul 2 / sub tabla
    PITCH = 45.0
    OVER = 0.6
    t = math.tan(math.radians(PITCH))
    roof_top_wall = ZW + 0.02 + 0.12 * math.sqrt(1 + t * t)   # tabla deasupra peretelui
    RIDGE_TOP = roof_top_wall + HY * t
    z_eave = RIDGE_TOP - (HY + OVER) * t
    R = tin_roof(roof, 0.0, 0.0, HX + OVER, HY + OVER, z_eave, PITCH, ROOF_SILVER)
    zu_wall = R["under"](0.0, HY) - 0.02          # = ZW
    zu_ridge = R["under"](0.0, 0.0) - 0.02

    # --- 1) parterul de piatra
    stone_base(stone, SX, SY, Z1)

    # --- 2/3) corpul de lemn: doua niveluri + frontoanele, pana sub tabla
    prism_yz(wood_body, [(-HY, Z1), (HY, Z1), (HY, zu_wall), (0.0, zu_ridge), (-HY, zu_wall)],
             -HX, HX, WOOD)
    wood_bands(trim, HX, HY, (Z1, Z2), zu_wall)
    zg = zu_wall - 0.05
    for sx in (-1, 1):
        trim.box((sx * (HX + 0.06), 0.0, zg), (0.22, 2 * HY + 0.1, 0.22), TRIM)
        trim.beam((sx * (HX + 0.16), -HY - 0.05, zg + 0.17), (sx * (HX + 0.16), HY + 0.05, zg + 0.17),
                  (0.14, 0.32), TRIM, up=(sx * 0.6, 0.0, 1.0))
    barge_boards(trim, R, HX + OVER, HY + OVER)

    # --- 5) lucarnele (doua, pe apa +Y)
    for xc in (2.6, -2.4):
        dormer(wood_body, roof, op, R, xc, 3.2, 2.4, ROOF_SILVER)

    # --- 6) cosul de piatra, langa varful frontonului +X, peste coama
    chimney(stone, void, HX - 1.5, -0.2, zu_ridge - 1.5, RIDGE_TOP + 1.25)
    # 7) tubul de aerisire pe apa din spate, langa coama
    void.cylinder((-3.4, -0.9, R["top"](-3.4, -0.9) + 0.35), 0.08, 0.9, VOID, segments=8)

    # --- 8) frontonul +X: trei randuri + aerisirea
    zs0, zs1 = 1.1, 1.85                       # parter
    zw0, zw1 = Z1 + 0.62, Z1 + 1.62            # nivelul 1
    zv0, zv1 = Z2 + 0.62, Z2 + 1.62            # nivelul 2
    for y in (-3.0, 0.0, 3.0):
        op.add("stone", "+X", SX, y, 0.7, zs0, zs1)
    for y in (-3.5, -2.1, 2.1, 3.5):
        op.add("wood", "+X", HX, y, 0.8, zw0, zw1)
    for y in (-1.1, 0.0, 1.1):
        op.add("wood", "+X", HX, y, 0.72, zv0, zv1)
    op.add("wood", "+X", HX, 0.0, 0.4, zu_wall + 1.2, zu_wall + 1.9, cross=False)
    # --- 9) latura +Y (fata bogata)
    op.add("stone", "+Y", SY, 3.6, 0.7, zs0, zs1)
    op.add("stone", "+Y", SY, -3.7, 1.0, 0.04, 2.05, kind="door")
    for x in (5.0, 2.6, 0.2):
        op.add("wood", "+Y", HY, x, 0.8, zw0, zw1)
    op.add("wood", "+Y", HY, -4.4, 1.0, Z1 + 0.26, Z1 + 2.2, kind="door")
    op.add("wood", "+Y", HY, -2.3, 0.8, zw0, zw1)
    for x in (5.0, 2.6, 0.2, -2.2, -4.6):
        op.add("wood", "+Y", HY, x, 0.8, zv0, zv1)
    # --- 10) spatele (-Y) si frontonul -X
    for x in (-4.0, 0.0, 4.0):
        op.add("stone", "-Y", SY, x, 0.7, zs0, zs1)
    for x in (-4.5, -1.5, 1.5, 4.5):
        op.add("wood", "-Y", HY, x, 0.8, zw0, zw1)
        op.add("wood", "-Y", HY, x, 0.8, zv0, zv1)
    for y in (-2.5, 2.5):
        op.add("stone", "-X", SX, y, 0.7, zs0, zs1)
        op.add("wood", "-X", HX, y, 0.8, zw0, zw1)
        op.add("wood", "-X", HX, y, 0.8, zv0, zv1)
    op.add("wood", "-X", HX, 0.0, 0.4, zu_wall + 1.2, zu_wall + 1.9, cross=False)

    # --- 11) terasa pe +Y, capatul -X, la nivelul 1, si scara
    terr = Builder()
    terrace(terr, -6.2, -1.0, HY, HY + 2.4, Z1, stair=(-2.55, -1.4))

    # --- obiectele: taiere, lipire, noduri
    st_o = op.apply("stone", Builder.to_object(stone, "Cabana_Stone"), STONE)
    wb_o = op.apply("wood", Builder.to_object(wood_body, "WoodBody"), WOOD)
    wood_o = join([wb_o, Builder.to_object(trim, "WoodTrim"), Builder.to_object(terr, "WoodTerrace")],
                  "Cabana_Wood")
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
