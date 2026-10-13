"""Transfagarasan -- cladirile (brief docs/asset_briefs/transfagarasan_kit.md §1.3).

  transfagarasan/buildings/cabana_balea_lac.glb       cabana Balea Lac (contract revizuit)
  transfagarasan/buildings/cabana_balea_cascada.glb   cabana Balea Cascada (un nivel, anexa in L)
  transfagarasan/buildings/stana.glb                  stana: coliba + tarcul
  transfagarasan/buildings/arges_house_a.glb          casa din vale A (patru ape, prispa)
  transfagarasan/buildings/arges_house_b.glb          casa din vale B (fronton spre drum, sura)
  transfagarasan/props/souvenir_stall.glb             taraba cu cas si fructe

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
ROOF_RUST = RUST             # 10 RUST_METAL: tabla ruginie (cascada, cosul stanii)
PLASTER = FOAM_WHITE         # 22: tencuiala alba (clasa plaster pe *_Plaster)

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
            cross=True, sill=True, depth=OPEN_D, at=None):
        """Gol pe fata `face` ('+X','-X','+Y','-Y') a corpului `key`; `plane` =
        distanta fetei de la axa (semnul il da `face`), `c` = pozitia centrului
        de-a lungul peretelui. Pentru un corp care nu e pe axa se da `at` =
        coordonata absoluta a fetei."""
        sg = 1.0 if face[0] == "+" else -1.0
        plane = sg * abs(plane) if at is None else at      # `at`: coordonata absoluta
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


def dormer(wood_b, roof_b, op, R, xc, y_front, w, roof_slot, y_back=0.4, win=(1.0, 0.8),
           rise=1.3):
    """Lucarna in doua ape pe apa +Y a unui acoperis cu coama pe X: corp de lemn
    (pentagon extrudat pe Y, ingropat in acoperis), tabla proprie cu coama pe Y,
    o fereastra (gol) in fata."""
    zt = R["top"](xc, y_front)
    z_de = zt + rise
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
# unelte pentru casele din vale si stana
# ---------------------------------------------------------------------------

def plank_fence(b, p0, p1, h, slot=None, post_slot=None, post_step=2.0, board_w=0.12,
                gap=0.06):
    """Gard de SCANDURI: stalpi la `post_step`, doua lise, scanduri verticale
    cu rost (kit: "gard de scanduri", ca pe decupari)."""
    slot = WOOD if slot is None else slot
    post_slot = TRIM if post_slot is None else post_slot
    p0, p1 = Vector(p0), Vector(p1)
    L = (p1 - p0).length
    u = (p1 - p0).normalized()
    railing_boards(b, p0, p1, h - 0.05, slot, board_w=board_w, gap=gap, t=0.025, rail=(0.08, 0.07))
    n = max(1, int(round(L / post_step)))
    for i in range(n + 1):
        p = p0 + u * (L * i / n)
        b.box((p.x, p.y, p.z + h * 0.5), (0.12, 0.12, h), post_slot)


def rail_fence(b, p0, p1, h, slot=None, post_step=2.0, rails=3, seed=0):
    """Tarcul stanii: pari (stalpi grosi, usor stramb) la `post_step` si
    `rails` randuri de barne orizontale prinse pe fata lor."""
    import random
    rnd = random.Random(seed)
    slot = WOOD if slot is None else slot
    p0, p1 = Vector(p0), Vector(p1)
    L = (p1 - p0).length
    u = (p1 - p0).normalized()
    nrm = Vector((-u.y, u.x, 0.0))
    n = max(1, int(round(L / post_step)))
    for i in range(n + 1):
        p = p0 + u * (L * i / n)
        hh = h + 0.12 + 0.08 * rnd.random()
        rot = Matrix.Rotation(math.radians((rnd.random() - 0.5) * 4.0), 3, u)
        b.box((p.x, p.y, hh * 0.5), (0.16, 0.16, hh), TRIM, rotation=rot)
    for k in range(rails):
        z = 0.3 + (h - 0.3) * (k + 0.5) / rails + 0.12
        off = nrm * 0.12
        b.beam(p0 + off + Vector((0, 0, z)), p1 + off + Vector((0, 0, z + 0.03 * (k - 1))),
               (0.11, 0.13), slot, up=(0, 0, 1))


def battens(b, face, plane, a0, a1, z0, z_top_fn, slot, step=0.45, w=0.06, out=0.03,
            absolute=False, holes=()):
    """Sipci verticale pe o fata (scanduri verticale cu sipca, ca forma):
    `z_top_fn(a)` = cota de sus la pozitia `a` (pe fronton urmareste tabla)."""
    sg = 1.0 if face[0] == "+" else -1.0
    pl = (plane if absolute else sg * abs(plane)) + sg * (GAP + out * 0.5)
    n = int((a1 - a0) / step)
    for i in range(1, n + 1):
        a = a0 + (a1 - a0) * i / (n + 1)
        if any(abs(a - hc) < hw * 0.5 + FRAME + w for hc, hw in holes):
            continue          # sipca nu trece peste usa / fereastra
        zt = z_top_fn(a) - 0.04
        if zt - z0 < 0.2:
            continue
        c = (pl, a, (z0 + zt) * 0.5) if face[1] == "X" else (a, pl, (z0 + zt) * 0.5)
        sz = (out, w, zt - z0) if face[1] == "X" else (w, out, zt - z0)
        b.box(c, sz, slot)


def shingle_roof(b, cx, cy, hx, hy, z_eave, pitch, slot, axis="X", course=0.34, kick=4.0):
    """Acoperis de SINDRILA in doua ape: placa de baza (`tin_roof` fara
    nervuri, cu capacul de coama) + randuri de sindrila suprapuse, fiecare
    rasucita cu `kick` grade fata de panta, deci muchia de jos iese ~2-3 cm:
    treptele se vad ca linii orizontale de umbra (forma, nu textura)."""
    R = tin_roof(b, cx, cy, hx, hy, z_eave, pitch, slot, axis=axis, ribs=False,
                 cap=(0.24, 0.12))
    t = math.tan(math.radians(pitch))
    L = hy / math.cos(math.radians(pitch))
    n = int(L / course)
    for s in (1.0, -1.0):
        for k in range(n):
            d = (k + 0.5) * course                 # de la streasina, pe panta
            v = s * (hy - d * math.cos(math.radians(pitch)))
            z = z_eave + d * math.sin(math.radians(pitch))
            ang = math.radians(pitch - kick)
            nrm = Vector((0.0, s * math.sin(ang), math.cos(ang)))
            if axis == "X":
                p1, p2 = Vector((cx - hx, cy + v, z)), Vector((cx + hx, cy + v, z))
                up = nrm
            else:
                p1, p2 = Vector((cx - v, cy - hx, z)), Vector((cx - v, cy + hx, z))
                up = Vector((-nrm.y, 0.0, nrm.z))
            off = up * 0.03
            b.beam(p1 + off, p2 + off, (course + 0.08, 0.04), slot, up=up)
    return R


def gate_open(b, hinge, width, h, ang_deg, slot=None):
    """Poarta de scanduri DESCHISA: segment de `width` din balamaua `hinge`,
    rotit cu `ang_deg` fata de +X (in plan)."""
    a = math.radians(ang_deg)
    p0 = Vector(hinge)
    p1 = p0 + Vector((math.cos(a), math.sin(a), 0.0)) * width
    railing_boards(b, p0, p1, h - 0.1, WOOD if slot is None else slot, board_w=0.12, gap=0.05,
                   t=0.03, rail=(0.08, 0.08))
    b.beam(p0 + Vector((0, 0, 0.2)), p1 + Vector((0, 0, h - 0.2)), (0.07, 0.04), TRIM,
           up=(0, 0, 1))   # contrafisa in diagonala


# ---------------------------------------------------------------------------
# cabana_balea_cascada
# ---------------------------------------------------------------------------

def build_cabana_balea_cascada():
    """Cabana Balea Cascada (`cabana_balea_cascada`), kit §1.3: 12 x 9 m + anexa
    6 x 5 m, 8 m la coama.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/cabana_balea_cascada.png`,
    scrisa INAINTE de primul vertex). Corectura coordonatorului: pe plansa e
    aproape identica cu Balea Lac -> ALTA FORMA, deci lista urmeaza corectura
    unde se bat:
      1) UN SINGUR NIVEL de lemn (decuparea: un etaj + mansarda) pe un SOCLU
         DE PIATRA jos (decuparea: ~1 m, vizibil mai ales in dreapta)
      2) PODUL MANSARDAT: frontoane inalte cu 2 ferestre de mansarda fiecare
         (decuparea: 1 fereastra mare + 1 mica in fronton)
      3) 1 LUCARNA pe apa din fata (decuparea: 1)
      4) ACOPERIS de tabla RUGINIE (RUST_METAL, corectura; decuparea: gri), in
         doua ape, coama pe latura lunga
      5) PRISPA de-a lungul fatadei lungi (+Y), sub streasina prelungita a
         acoperisului, pe 6 stalpi, cu parapet jos din scanduri drepte si 2
         trepte la usa (decuparea: o terasa mica cu trepte la capatul stang si
         treptele de piatra la usa din dreapta -> contractul: prispa lunga)
      6) ANEXA JOASA IN L (corectura; nu e pe decupare): 6 x 5 m, lipita de
         frontonul +X, aliniata cu peretele din spate, deci retrasa 4 m fata
         de fatada -> L in plan; un nivel de lemn pe soclu, acoperis propriu
         mai jos, tot ruginiu; o usa mare de sopron + o fereastra
      7) FERESTRE: fatada +Y 4 ferestre + usa; frontonul -X 2 + 2 la
         mansarda; frontonul +X 1 (restul e acoperit de anexa) + 2 la
         mansarda; spatele 3; usa si ferestrele cu rama si cruce
      8) COS de piatra pe apa din spate
      9) NU intra: bradul si tufele din stanga (vegetatia la integrare),
         pietrele de la baza
    Noduri: Cascada_Stone, Cascada_Wood, Cascada_Roof, Cascada_Void."""
    stone, wood_body, trim, roof, void = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, trim)
    HX, HY = 6.0, 4.5
    SX, SY = 5.85, 4.35
    Z1, ZW = 0.8, 3.8
    PITCH, OVER, PRISPA = 40.0, 0.5, 1.75
    t = math.tan(math.radians(PITCH))
    roof_top_wall = ZW + 0.02 + 0.12 * math.sqrt(1 + t * t)
    ridge = roof_top_wall + HY * t
    z_eave = ridge - (HY + OVER) * t
    R = tin_roof(roof, 0.0, 0.0, HX + OVER, HY + OVER, z_eave, PITCH, ROOF_RUST,
                 extend=(PRISPA, 0.0))
    zu_wall = R["under"](0.0, HY) - 0.02
    zu_ridge = R["under"](0.0, 0.0) - 0.02

    stone_base(stone, SX, SY, Z1, quoins=False)
    prism_yz(wood_body, [(-HY, Z1), (HY, Z1), (HY, zu_wall), (0.0, zu_ridge), (-HY, zu_wall)],
             -HX, HX, WOOD)
    wood_bands(trim, HX, HY, (Z1,), zu_wall)
    for sx in (-1, 1):          # brau la baza frontonului
        trim.box((sx * (HX + 0.06), 0.0, zu_wall - 0.05), (0.2, 2 * HY + 0.1, 0.2), TRIM)
    barge_boards(trim, R, HX + OVER, HY + OVER)
    # lucarna jos pe panta: coama ei ramane sub coama mare (runda 1: 8,15 > 7,83)
    dormer(wood_body, roof, op, R, 1.6, 3.4, 1.9, ROOF_RUST, win=(0.8, 0.7), rise=1.15)
    chimney(stone, void, -2.6, -1.4, zu_ridge - 2.0, ridge + 0.9, size=0.8)

    # --- anexa in L: lipita de frontonul +X, aliniata cu spatele
    AX0, AX1, AY0, AY1 = HX, HX + 6.0, -HY, -HY + 5.0
    acx, acy = (AX0 + AX1) * 0.5, (AY0 + AY1) * 0.5
    A_Z1, A_ZW, A_P = 0.5, 2.7, 35.0
    ta = math.tan(math.radians(A_P))
    a_top_wall = A_ZW + 0.02 + 0.12 * math.sqrt(1 + ta * ta)
    a_ridge = a_top_wall + 2.5 * ta
    a_eave = a_ridge - (2.5 + 0.4) * ta
    RA = tin_roof(roof, acx + 0.2, acy, 3.0 + 0.2, 2.5 + 0.4, a_eave, A_P, ROOF_RUST)
    a_uw = RA["under"](acx, AY1) - 0.02
    a_ur = RA["under"](acx, acy) - 0.02
    stone.box((acx, acy, A_Z1 * 0.5), (AX1 - AX0 - 0.3 + 0.15, AY1 - AY0 - 0.3, A_Z1), STONE)
    prism_yz(wood_body, [(AY0, A_Z1), (AY1, A_Z1), (AY1, a_uw), (acy, a_ur), (AY0, a_uw)],
             AX0 - 0.3, AX1, WOOD)
    trim.box((AX1 - 0.07, AY0 + 0.07, (A_Z1 + a_uw) * 0.5), (0.22, 0.22, a_uw - A_Z1), TRIM)
    trim.box((AX1 - 0.07, AY1 - 0.07, (A_Z1 + a_uw) * 0.5), (0.22, 0.22, a_uw - A_Z1), TRIM)
    for i in range(2):          # bordura frontonului anexei (+X)
        yy = AY0 - 0.4 if i == 0 else AY1 + 0.4
        trim.beam((AX1 + 0.34, yy, RA["under"](AX1, yy) - 0.15), (AX1 + 0.34, acy, a_ur - 0.13),
                  (0.26, 0.06), WOOD, up=(1, 0, 0))
    battens(trim, "+Y", AY1, AX0 + 0.1, AX1 - 0.1, A_Z1, lambda a: a_uw, WOOD, step=0.5,
            holes=[(acx - 0.6, 1.8)])
    battens(trim, "+X", AX1, AY0 + 0.1, AY1 - 0.1, A_Z1,
            lambda a: RA["under"](AX1, a) - 0.02, WOOD, step=0.5, holes=[(acy, 0.6)])
    op.add("wood", "+Y", AY1, acx - 0.6, 1.8, A_Z1 + 0.02, A_Z1 + 2.0, kind="door")
    op.add("wood", "+X", AX1, acy, 0.6, A_Z1 + 0.9, A_Z1 + 1.5)

    # --- golurile corpului principal
    zw0, zw1 = Z1 + 0.7, Z1 + 1.75
    za0, za1 = zu_wall + 0.5, zu_wall + 1.4
    for x in (-4.6, -2.4, 2.6, 4.6):
        op.add("wood", "+Y", HY, x, 0.85, zw0, zw1)
    op.add("wood", "+Y", HY, 0.2, 1.0, Z1 + 0.02, Z1 + 2.1, kind="door")
    for y in (-2.0, 2.0):
        op.add("wood", "-X", HX, y, 0.85, zw0, zw1)
    for y in (-0.9, 0.9):
        op.add("wood", "-X", HX, y, 0.7, za0, za1)
        op.add("wood", "+X", HX, y, 0.7, za0 + 0.6, za1 + 0.6)
    op.add("wood", "+X", HX, 2.6, 0.85, zw0, zw1)
    for x in (-3.5, 0.0, 3.5):
        op.add("wood", "-Y", HY, x, 0.85, zw0, zw1)
    for x in (-3.0, 3.0):
        op.add("stone", "-Y", SY, x, 0.45, 0.25, 0.6, cross=False)

    # --- prispa pe +Y, sub streasina prelungita
    py0, py1, pz = HY, HY + PRISPA - 0.05, 0.42
    terr = Builder()
    terr.box((0.0, (py0 + py1) * 0.5 + 0.05, pz - 0.1), (2 * HX, py1 - py0 + 0.1, 0.2), WOOD)
    terr.box((0.0, py1 - 0.1, pz * 0.5 - 0.1), (2 * HX, 0.2, pz - 0.2), STONE)
    ypost = py1 - 0.15
    xs = [-HX + 0.15, -3.6, -1.2, 1.6, 3.6, HX - 0.15]
    for x in xs:
        zt = R["under"](x, ypost) - 0.02
        terr.box((x, ypost, (pz + zt) * 0.5), (0.2, 0.2, zt - pz), TRIM)
    zb = R["under"](0.0, ypost) - 0.12
    terr.box((0.0, ypost, zb), (2 * HX + 0.1, 0.22, 0.2), TRIM)
    for a, c in ((-HX + 0.15, -1.2), (1.6, HX - 0.15)):
        railing_boards(terr, (a, py1 - 0.06, pz), (c, py1 - 0.06, pz), 0.75, WOOD)
    for i in range(2):          # treptele spre usa
        hs = pz - 0.14 * (i + 1)
        terr.box((0.2, py1 + 0.17 + 0.3 * i, hs * 0.5), (1.6, 0.32, hs), WOOD)

    st_o = op.apply("stone", Builder.to_object(stone, "Cascada_Stone"), STONE)
    wb_o = op.apply("wood", Builder.to_object(wood_body, "WoodBody"), WOOD)
    wood_o = join([wb_o, Builder.to_object(trim, "WoodTrim"), Builder.to_object(terr, "WoodPorch")],
                  "Cascada_Wood")
    print("cabana_balea_cascada: goluri %d | coama %.2f, anexa %.2f, streasina prispei %.2f"
          % (len(op.log), ridge, a_ridge, R["top"](0.0, HY + OVER + PRISPA)))
    return [st_o, wood_o, Builder.to_object(roof, "Cascada_Roof"), to_obj(void, "Cascada_Void")]


# ---------------------------------------------------------------------------
# stana
# ---------------------------------------------------------------------------

def build_stana():
    """Stana (`stana`), kit §1.3: coliba 5 x 4 m, 3,2 m la coama; tarcul
    14 x 10 m, gard de 1,2 m.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/stana.png`, scrisa
    INAINTE de primul vertex):
      1) COLIBA joasa de SCANDURI VERTICALE (aici scanduri cu sipci la 0,45 m),
         frontonul spre tarc (+Y, fata bogata) cu o USA MARE deschisa in
         mijloc (gol) si 1 fereastra mica langa ea; latura lunga cu 1 fereastra
      2) ACOPERIS in doua ape, coama pe Y (frontonul in fata). Contractul cere
         SINDRILA -> randuri de sindrila ca trepte; pe decupare acoperisul e
         gri -> ASPHALT_EDGE (sindrila veche, cenusie)
      3) COS DE TABLA (contract; decuparea: nu se vede) -> burlan ruginiu
         (RUST_METAL) cu palarie, pe apa din spate
      4) TARCUL 14 x 10 m: PARI la ~2 m si 3 randuri de BARNE (decuparea: 3
         randuri, pari mai inalti decat barnele), 1,2 m
      5) O POARTA DESCHISA in tarc (decuparea: tarcul e deschis spre fata) ->
         poarta de 2,4 m pe latura +Y, rotita spre exterior
      6) coliba sta in coltul din spate-dreapta al tarcului, cu usa spre tarc
      7) BUTUCUL de despicat lemne langa coliba, cu 2 lemne despicate
      8) NU intra: oile si cainii (vin din turma si decor), iarba, pamantul
         batatorit din tarc, tufa din dreapta
    Noduri: Stana_Wood, Stana_Roof, Stana_Fence, Stana_Void (golurile)."""
    wood_body, trim, roof, fence, void = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, trim)
    # coliba: 4 m pe X (frontonul), 5 m pe Y; centrul in coltul din spate-dreapta
    hcx, hcy = 3.9, -2.2
    HXh, HYh = 2.0, 2.5
    ZW, PITCH, OVER = 1.95, 28.0, 0.35
    t = math.tan(math.radians(PITCH))
    roof_top_wall = ZW + 0.02 + 0.12 * math.sqrt(1 + t * t)
    ridge = roof_top_wall + HXh * t
    z_eave = ridge - (HXh + OVER) * t
    R = shingle_roof(roof, hcx, hcy, HYh + OVER, HXh + OVER, z_eave, PITCH, ROOF_SILVER, axis="Y")
    zu_w = R["under"](hcx + HXh, hcy) - 0.02
    zu_r = R["under"](hcx, hcy) - 0.02
    x0, x1, y0, y1 = hcx - HXh, hcx + HXh, hcy - HYh, hcy + HYh
    prism_xz(wood_body, [(x0, 0.0), (x1, 0.0), (x1, zu_w), (hcx, zu_r), (x0, zu_w)], y0, y1, WOOD)
    for x in (x0, x1):
        for y in (y0, y1):
            trim.box((x + (0.06 if x == x0 else -0.06), y + (0.06 if y == y0 else -0.06), zu_w * 0.5),
                     (0.18, 0.18, zu_w), TRIM)
    gable = lambda a: R["under"](a, y1) - 0.02
    battens(trim, "+Y", y1, x0 + 0.1, x1 - 0.1, 0.05, gable, WOOD, absolute=True,
            holes=[(hcx - 0.35, 1.3), (hcx + 1.3, 0.5)])
    battens(trim, "-Y", y0, x0 + 0.1, x1 - 0.1, 0.05, gable, WOOD, absolute=True)
    battens(trim, "+X", x1, y0 + 0.1, y1 - 0.1, 0.05, lambda a: zu_w, WOOD, absolute=True)
    battens(trim, "-X", x0, y0 + 0.1, y1 - 0.1, 0.05, lambda a: zu_w, WOOD, absolute=True,
            holes=[(hcy + 0.6, 0.55)])
    # barge pe frontoane (sub sindrila)
    for yy in (y1 + OVER - 0.05, y0 - OVER + 0.05):
        for xe in (x0 - OVER, x1 + OVER):
            trim.beam((xe, yy, R["under"](xe, yy) - 0.13), (hcx, yy, R["under"](hcx, yy) - 0.13),
                      (0.24, 0.06), WOOD, up=(0, 1 if yy > hcy else -1, 0))
    op.add("wood", "+Y", 0.0, hcx - 0.35, 1.3, 0.02, 1.95, kind="door", at=y1)
    op.add("wood", "+Y", 0.0, hcx + 1.3, 0.5, 1.0, 1.5, cross=False, at=y1)
    op.add("wood", "-X", 0.0, hcy + 0.6, 0.55, 1.0, 1.5, cross=False, at=x0)
    # cos de tabla ruginit, pe apa din spate (-X)
    cx_, cy_ = hcx - 0.9, hcy - 1.2
    zr = R["top"](cx_, cy_)
    roof.cylinder((cx_, cy_, zr + 0.45), 0.11, 1.3, ROOF_RUST, segments=8)
    roof.frustum((cx_, cy_, zr + 1.2), 0.28, 0.06, 0.22, ROOF_RUST, segments=8)
    # butucul de despicat, langa coliba (in fata-stanga a usii)
    bx, by = hcx - 2.7, y1 + 0.9
    trim.cylinder((bx, by, 0.25), 0.34, 0.5, TRIM, segments=10)
    trim.box((bx + 0.7, by + 0.1, 0.12), (0.5, 0.22, 0.24), WOOD,
             rotation=Matrix.Rotation(math.radians(25), 3, "Z"))
    trim.box((bx + 0.55, by - 0.45, 0.12), (0.45, 0.2, 0.24), WOOD,
             rotation=Matrix.Rotation(math.radians(-40), 3, "Z"))

    # --- tarcul 14 x 10, poarta deschisa pe +Y
    FX, FY, FH = 7.0, 5.0, 1.2
    gx0, gx1 = -3.6, -1.2
    rail_fence(fence, (-FX, FY, 0), (gx0, FY, 0), FH, seed=1, post_step=1.6)
    rail_fence(fence, (gx1, FY, 0), (FX, FY, 0), FH, seed=2)
    rail_fence(fence, (FX, FY, 0), (FX, -FY, 0), FH, seed=3)
    rail_fence(fence, (FX, -FY, 0), (-FX, -FY, 0), FH, seed=4)
    rail_fence(fence, (-FX, -FY, 0), (-FX, FY, 0), FH, seed=5)
    a = math.radians(235.0)                 # poarta deschisa spre interiorul tarcului
    hinge = Vector((gx1, FY + 0.12, 0.0))
    tip = hinge + Vector((math.cos(a), math.sin(a), 0.0)) * (gx1 - gx0 - 0.1)
    for k in range(3):
        z = 0.35 + k * 0.38
        fence.beam(hinge + Vector((0, 0, z)), tip + Vector((0, 0, z)), (0.12, 0.14), WOOD, up=(0, 0, 1))
    fence.beam(hinge + Vector((0, 0, 0.3)), tip + Vector((0, 0, 1.1)), (0.1, 0.1), WOOD, up=(0, 0, 1))
    for q in (hinge + (tip - hinge) * 0.04, tip):
        fence.box((q.x, q.y, 0.65), (0.13, 0.13, 1.15), TRIM)

    wb_o = op.apply("wood", Builder.to_object(wood_body, "WoodBody"), WOOD)
    wood_o = join([wb_o, Builder.to_object(trim, "WoodTrim")], "Stana_Wood")
    print("stana: coama %.2f, goluri %d" % (ridge, len(op.log)))
    return [wood_o, Builder.to_object(roof, "Stana_Roof"), Builder.to_object(fence, "Stana_Fence"),
            to_obj(void, "Stana_Void")]


# ---------------------------------------------------------------------------
# arges_house_a / arges_house_b
# ---------------------------------------------------------------------------

def build_arges_house_a():
    """Casa din valea Argesului A (`arges_house_a`), kit §1.3: 9 x 7 m, 6,5 m la
    coama; gard de 1,2 m pe +Y.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/arges_house_a.png`,
    scrisa INAINTE de primul vertex; contractul bate decuparea unde se bat):
      1) PERETI ALBI TENCUITI, un nivel (~3 m), pe un soclu gri subtire
         (decuparea: perete alb pana jos; soclul e citire de umbra)
      2) ACOPERIS IN PATRU APE de tabla argintie (contract; decuparea arata
         doua ape cu fronton de scanduri -> acela e B), STREASINA LARGA (0,6 m;
         runda 1 cu 0,8 m si pereti de 3 m citea "ciuperca": numai acoperis)
      3) PRISPA DE LEMN pe stalpi pe +Y, pe toata latimea, sub acoperis
         (decuparea: prispa ingusta cu usa si 2 ferestre in spate)
      4) FERESTRE CU RAMA DE LEMN: fata +Y 2 ferestre + usa; laturile cate 2;
         spatele 2 (decuparea: 2 pe latura vazuta)
      5) COS tencuit pe apa din spate (decuparea: cos albastru-gri)
      6) GARD DE SCANDURI in fata (+Y), cu POARTA (decuparea: gard pe fata si
         pe laturi, poarta deschisa in dreapta) -> fata + doua intoarceri pana
         la colturile casei; poarta mica deschisa in dreptul usii
      7) NU intra: tufele din curte
    Noduri: House_Plaster, House_Wood, House_Roof, House_Void."""
    plaster, wood, roof, void, stone = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, frame_slot=WOOD)
    HX, Y0, YF, YP = 4.5, -3.5, 1.9, 3.5        # corp de la Y0 la YF, prispa pana la YP
    ZW, OVER = 3.2, 0.6
    # tabla deasupra peretilor laterali/spate (la OVER de streasina) -> ZW
    hy = (YP - Y0) * 0.5 + OVER
    cy = (YP + Y0) * 0.5
    hx = HX + OVER
    ridge_target = 6.5 - 0.06
    t = (ridge_target - (ZW + 0.2)) / (hy - OVER)
    PITCH = math.degrees(math.atan(t))
    z_eave = ZW + 0.02 + 0.12 * math.sqrt(1 + t * t) - OVER * t
    R = tin_roof(roof, 0.0, cy, hx, hy, z_eave, PITCH, ROOF_SILVER, kind="hip")
    # corpul tencuit: pana la ZW, plus soclul
    plaster.box((0.0, (Y0 + YF) * 0.5, ZW * 0.5), (2 * HX, YF - Y0, ZW), PLASTER)
    stone.box((0.0, (Y0 + YF) * 0.5, 0.2), (2 * HX + 0.08, YF - Y0 + 0.08, 0.4), STONE)
    # timpanul de deasupra peretelui din fata, pana sub tabla (in umbra prispei)
    zf = R["under"](0.0, YF) - 0.02
    prism_yz(plaster, [(YF - 0.3, ZW - 0.1), (YF, ZW - 0.1), (YF, zf), (YF - 0.3, zf)],
             -HX + 1.6, HX - 1.6, PLASTER)
    # prispa: podea, stalpi, grinda, parapet jos din scanduri
    pz = 0.35
    wood.box((0.0, (YF + YP) * 0.5, pz - 0.1), (2 * HX, YP - YF, 0.2), WOOD)
    wood.box((0.0, YP - 0.1, pz * 0.5 - 0.1), (2 * HX, 0.2, pz - 0.2), STONE)
    ypost = YP - 0.15
    for x in (-HX + 0.15, -1.6, 1.6, HX - 0.15):
        zt = R["under"](x, ypost) - 0.02
        wood.box((x, ypost, (pz + zt) * 0.5), (0.2, 0.2, zt - pz), WOOD)
        wood.box((x, ypost, zt - 0.3), (0.5, 0.12, 0.12), WOOD,
                 rotation=None)          # sprijin (consola simpla)
    wood.box((0.0, ypost, R["under"](0.0, ypost) - 0.12), (2 * HX + 0.1, 0.22, 0.2), WOOD)
    for a, c in ((-HX + 0.15, -0.7), (0.7, HX - 0.15)):
        railing_boards(wood, (a, YP - 0.06, pz), (c, YP - 0.06, pz), 0.7, WOOD)
    wood.box((0.0, YP + 0.18, 0.1), (1.2, 0.36, 0.2), STONE)        # treapta
    # golurile (rama de lemn)
    z0, z1 = 0.95, 2.15
    op.add("plaster", "+Y", YF, -2.6, 1.0, z0, z1)
    op.add("plaster", "+Y", YF, 2.6, 1.0, z0, z1)
    op.add("plaster", "+Y", YF, 0.0, 0.95, 0.42, 2.3, kind="door")
    for y in (-2.0, 0.6):
        op.add("plaster", "+X", HX, y, 0.95, z0, z1)
        op.add("plaster", "-X", HX, y, 0.95, z0, z1)
    for x in (-2.2, 2.2):
        op.add("plaster", "-Y", -Y0, x, 0.95, z0, z1)
    chimney(plaster, void, 1.6, -1.2, ZW - 0.3, R["ridge_z"] + 0.6, size=0.6, slot=PLASTER)
    # gardul de scanduri: fata la y = 6,2, intoarceri pana la colturile prispei
    FY = YP + 2.7
    gx = 0.0
    plank_fence(wood, (-HX - 0.4, FY, 0.0), (gx - 0.65, FY, 0.0), 1.2)
    plank_fence(wood, (gx + 0.65, FY, 0.0), (HX + 0.4, FY, 0.0), 1.2)
    plank_fence(wood, (-HX - 0.4, FY, 0.0), (-HX - 0.4, YP, 0.0), 1.2)
    plank_fence(wood, (HX + 0.4, FY, 0.0), (HX + 0.4, YP, 0.0), 1.2)
    gate_open(wood, (gx + 0.6, FY - 0.05, 0.0), 1.15, 1.1, 120.0)

    pl_o = op.apply("plaster", Builder.to_object(plaster, "PlasterBody"), PLASTER)
    print("arges_house_a: panta %.1f, coama %.2f, goluri %d" % (PITCH, R["ridge_z"], len(op.log)))
    pl_o.name = pl_o.data.name = "House_Plaster"
    return [pl_o, Builder.to_object(stone, "House_Stone"), Builder.to_object(wood, "House_Wood"),
            Builder.to_object(roof, "House_Roof"), to_obj(void, "House_Void")]


def build_arges_house_b():
    """Casa din valea Argesului B (`arges_house_b`), kit §1.3: 8 x 6 m + sura
    5 x 4 m, 6 m la coama.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/arges_house_b.png`,
    scrisa INAINTE de primul vertex; corecturile bat decuparea):
      1) ALTA FORMA decat A: FRONTONUL spre drum (+Y), ACOPERIS IN DOUA APE de
         tabla ROSIE (KERB_RED), coama pe Y (decuparea: rosu, fronton in stanga)
      2) PERETI TENCUITI ALBI (FOAM_WHITE, corectura: pe plansa sunt verzi)
      3) FRONTONUL DE SCANDURI deasupra peretelui, cu sipci si o fereastra de pod
         (decuparea: fronton de lemn cu 1 fereastra)
      4) FERESTRE CU RAMA DE LEMN: frontonul +Y 2; latura -X (curtea) usa +
         2 ferestre, cu o treapta; spatele 1; latura +X 1
      5) COS de caramida pe coama (decuparea: cos rosu-caramiziu) ->
         TILE_TERRACOTTA, in nodul de tencuiala
      6) SURA DE LEMN alaturata (corectura; nu e pe decupare): 5 x 4 m, lipita
         de latura +X, retrasa spre spate, scanduri verticale cu sipci,
         acoperis in doua ape cu coama pe X, mai jos, tabla rosie; poarta
         mare de sura (gol) spre +Y
      7) ACELASI GARD ca la A, pe +Y, cu poarta deschisa
      8) NU intra: tufele
    Noduri: House_Plaster, House_Wood, House_Roof, House_Void."""
    plaster, wood, roof, void, stone = Builder(), Builder(), Builder(), Builder(), Builder()
    op = Openings(void, wood, frame_slot=WOOD)
    HXh, HYh = 3.0, 4.0                 # casa: 6 m pe X (frontonul), 8 m pe Y
    ZW, OVER = 2.8, 0.5
    ridge_target = 6.0 - 0.06
    t = (ridge_target - (ZW + 0.2)) / HXh
    PITCH = math.degrees(math.atan(t))
    z_eave = ZW + 0.02 + 0.12 * math.sqrt(1 + t * t) - OVER * t
    R = tin_roof(roof, 0.0, 0.0, HYh + OVER, HXh + OVER, z_eave, PITCH, ROOF_RED, axis="Y")
    zu_w = R["under"](HXh, 0.0) - 0.02
    zu_r = R["under"](0.0, 0.0) - 0.02
    plaster.box((0.0, 0.0, zu_w * 0.5), (2 * HXh, 2 * HYh, zu_w), PLASTER)
    stone.box((0.0, 0.0, 0.2), (2 * HXh + 0.08, 2 * HYh + 0.08, 0.4), STONE)
    # frontoanele de scanduri (lemn), deasupra peretelui: prisma triunghiulara
    gbody = Builder()
    prism_xz(gbody, [(-HXh, zu_w), (HXh, zu_w), (0.0, zu_r)], -HYh, HYh, WOOD)
    gable = lambda a: R["under"](a, HYh) - 0.02
    battens(wood, "+Y", HYh, -HXh + 0.1, HXh - 0.1, zu_w + 0.05, gable, TRIM, step=0.4,
            holes=[(0.0, 0.6)])
    battens(wood, "-Y", HYh, -HXh + 0.1, HXh - 0.1, zu_w + 0.05, gable, TRIM, step=0.4)
    for sgn in (1, -1):
        wood.box((0.0, sgn * (HYh + 0.05), zu_w + 0.06), (2 * HXh + 0.2, 0.18, 0.16), TRIM)
    barge_boards(wood, R, HYh + OVER, HXh + OVER, axis="Y")
    op.add("gable", "+Y", HYh, 0.0, 0.6, zu_w + 0.6, zu_w + 1.35)
    # golurile casei
    z0, z1 = 0.95, 2.05
    for x in (-1.4, 1.4):
        op.add("plaster", "+Y", HYh, x, 0.95, z0, z1)
    op.add("plaster", "-X", HXh, 1.4, 0.95, 0.42, 2.2, kind="door")
    for y in (-1.6, 3.0):
        op.add("plaster", "-X", HXh, y, 0.95, z0, z1)
    op.add("plaster", "+X", HXh, 2.6, 0.95, z0, z1)
    op.add("plaster", "-Y", HYh, 0.0, 0.95, z0, z1)
    wood.box((-HXh - 0.3, 1.4, 0.1), (0.6, 1.3, 0.2), STONE)        # treapta usii
    wood.box((-HXh - 0.3, 1.4, 0.3), (0.35, 1.3, 0.2), STONE)
    # cosul de caramida in nodul de lemn (fara clasa: tencuiala l-ar albi)
    chimney(wood, void, 0.0, -1.8, zu_r - 1.0, R["ridge_z"] + 0.7, size=0.55, slot=TILE_TERRACOTTA)
    # --- sura: alaturata pe +X (0,5 m de streasina casei), retrasa spre spate
    BX0, BX1, BY0, BY1 = HXh + OVER + 0.5, HXh + OVER + 5.5, -HYh, -HYh + 4.0
    bcx, bcy = (BX0 + BX1) * 0.5, (BY0 + BY1) * 0.5
    B_ZW, B_P = 2.6, 32.0
    tb = math.tan(math.radians(B_P))
    b_ridge = B_ZW + 0.02 + 0.12 * math.sqrt(1 + tb * tb) + 2.0 * tb
    b_eave = b_ridge - 2.4 * tb
    RB = tin_roof(roof, bcx, bcy, 2.5 + 0.3, 2.0 + 0.4, b_eave, B_P, ROOF_RED)
    b_uw = RB["under"](bcx, BY1) - 0.02
    b_ur = RB["under"](bcx, bcy) - 0.02
    prism_yz(gbody, [(BY0, 0.0), (BY1, 0.0), (BY1, b_uw), (bcy, b_ur), (BY0, b_uw)], BX0, BX1, WOOD)
    battens(wood, "-X", BX0, BY0 + 0.1, BY1 - 0.1, 0.05, lambda a: RB["under"](BX0, a) - 0.02, TRIM,
            step=0.45, absolute=True)
    battens(wood, "+Y", BY1, BX0 + 0.1, BX1 - 0.1, 0.05, lambda a: b_uw, TRIM, step=0.45,
            holes=[(bcx, 2.2)])
    battens(wood, "+X", BX1, BY0 + 0.1, BY1 - 0.1, 0.05, lambda a: RB["under"](BX1, a) - 0.02, TRIM,
            step=0.45)
    for xx in (BX0 + 0.07, BX1 - 0.07):
        for yy in (BY1 - 0.07, BY0 + 0.07):
            wood.box((xx, yy, b_uw * 0.5), (0.2, 0.2, b_uw), TRIM)
    op.add("gable", "+Y", BY1, bcx, 2.2, 0.02, 2.2, kind="door")
    # gardul (acelasi ca la A)
    FY = HYh + 2.6
    plank_fence(wood, (-HXh - 0.6, FY, 0.0), (-0.9, FY, 0.0), 1.2)
    plank_fence(wood, (0.4, FY, 0.0), (BX1 + 0.3, FY, 0.0), 1.2)
    plank_fence(wood, (-HXh - 0.6, FY, 0.0), (-HXh - 0.6, 0.0, 0.0), 1.2)
    plank_fence(wood, (BX1 + 0.3, FY, 0.0), (BX1 + 0.3, BY1 + 0.3, 0.0), 1.2)
    gate_open(wood, (-0.85, FY - 0.05, 0.0), 1.2, 1.1, 60.0)

    pl_o = op.apply("plaster", Builder.to_object(plaster, "PlasterBody"), PLASTER)
    gb_o = op.apply("gable", Builder.to_object(gbody, "GableBody"), WOOD)
    pl_o.name = pl_o.data.name = "House_Plaster"
    wood_o = join([gb_o, Builder.to_object(wood, "WoodTrim")], "House_Wood")
    print("arges_house_b: panta %.1f, coama %.2f, sura %.2f, goluri %d"
          % (PITCH, R["ridge_z"], b_ridge, len(op.log)))
    return [pl_o, Builder.to_object(stone, "House_Stone"), wood_o, Builder.to_object(roof, "House_Roof"),
            to_obj(void, "House_Void")]


def retag_below(obj, z, slot):
    """Fetele cu centrul sub `z` trec pe `slot` (soclul gri dupa boolean)."""
    retag_where(obj, lambda c: c.z < z, slot)


def retag_where(obj, pred, slot):
    me = obj.data
    a = me.attributes["slot"]
    for i, p in enumerate(me.polygons):
        if pred(p.center):
            a.data[i].value = slot


# ---------------------------------------------------------------------------
# souvenir_stall
# ---------------------------------------------------------------------------

def build_souvenir_stall():
    """Taraba de suveniruri (`souvenir_stall`), kit §1.3: 3,5 x 2 m, 2,8 m.

    LISTA DE ELEMENTE (decuparea `transfagarasan_assets_v1/souvenir_stall.png`,
    scrisa INAINTE de primul vertex):
      1) 4 STALPI de lemn, grinzi sus; peretele din spate din scanduri
         verticale (decuparea: spate inchis, laturi deschise)
      2) ACOPERIS INTR-O APA DIN SCANDURI (contract; decuparea arata doua ape
         -> contractul): scandurile ca nervuri la 0,25 m, streasina spre client
      3) TEJGHEAUA in fata (+Y), la 0,9 m, cu un raft jos sub ea
      4) pe tejghea: 3 ROTI DE CAS (segments 10), una peste alta in stanga, si
         2 COSURI: zmeura (KERB_RED) si afine (ICE_DEEP) in dreapta
         (decuparea: 3 roti, gramada rosie)
      5) pe raftul de jos: 2 lazi cu fructe (decuparea: gramezi magenta)
      6) SUB STREASINA atarna 8 bucati de CAS AFUMAT IN COAJA DE BRAD
         (cilindri mici maro, LARCH_RUST) pe o bara (decuparea: ~10 bucati)
      7) FARA TEXT, FARA FIRMA (decuparea: niciuna)
      8) NU intra: lemnele sprijinite in stanga, florile de la baza
    Noduri: Stall_Wood, Stall_Roof, Stall_Goods (cas, fructe, cosuri)."""
    wood, roof, goods = Builder(), Builder(), Builder()
    HX, HY = 1.75, 1.0
    # acoperisul intr-o apa: sus in spate (2,8 m), streasina in fata
    rt = math.radians(14.0)
    hy_r = HY + 0.3
    z_hi = 2.8 - 0.06
    z_eave = z_hi - 2 * hy_r * math.tan(rt)
    R = tin_roof(roof, 0.0, 0.12, HX + 0.15, hy_r, z_eave, 14.0, WOOD, kind="shed",
                 thick=0.06, rib_h=0.03, rib_w=0.05, step=0.25)
    for x in (-HX + 0.08, HX - 0.08):
        for y in (-HY + 0.08, HY - 0.08):
            zt = R["under"](x, y) - 0.01
            wood.box((x, y, zt * 0.5), (0.14, 0.14, zt), TRIM)
    for y in (-HY + 0.08, HY - 0.08):
        zt = R["under"](0.0, y) - 0.09
        wood.box((0.0, y, zt), (2 * HX, 0.12, 0.16), TRIM)
    for x in (-HX + 0.08, HX - 0.08):
        wood.beam((x, -HY + 0.08, R["under"](x, -HY + 0.08) - 0.09),
                  (x, HY - 0.08, R["under"](x, HY - 0.08) - 0.09), (0.12, 0.16), TRIM, up=(1, 0, 0))
    # peretele din spate: scanduri verticale
    railing_boards(wood, (-HX + 0.08, -HY + 0.1, 0.0), (HX - 0.08, -HY + 0.1, 0.0),
                   R["under"](0.0, -HY + 0.1) - 0.18, WOOD, board_w=0.2, gap=0.03, t=0.03,
                   rail=(0.06, 0.06))
    # tejgheaua si raftul
    wood.box((0.0, HY - 0.35, 0.88), (2 * HX - 0.1, 0.75, 0.08), WOOD)
    wood.box((0.0, HY - 0.4, 0.3), (2 * HX - 0.1, 0.65, 0.05), WOOD)          # raftul de jos
    # marfa
    for x, y, r, z in ((-1.0, 0.62, 0.24, 0.98), (-0.97, 0.62, 0.21, 1.105), (-0.45, 0.7, 0.22, 0.98)):
        goods.cylinder((x, y, z), r, 0.12, SAND_LIGHT, segments=10)
    for x, slot in ((0.55, KERB_RED), (1.15, ICE_DEEP)):
        goods.frustum((x, 0.62, 1.02), 0.2, 0.27, 0.2, WOOD, segments=10)       # cosul
        goods.frustum((x, 0.62, 1.14), 0.25, 0.12, 0.12, slot, segments=10)     # gramada de fructe
    for x, slot in ((-0.8, KERB_RED), (0.6, ICE_DEEP)):
        goods.box((x, 0.6, 0.43), (0.7, 0.45, 0.22), WOOD)
        goods.box((x, 0.6, 0.56), (0.6, 0.36, 0.06), slot)
    # casul afumat in coaja de brad, atarnat sub streasina
    yb = HY - 0.25
    zb = R["under"](0.0, yb) - 0.25
    wood.box((0.0, yb, zb), (2 * HX - 0.2, 0.05, 0.05), TRIM)
    for i in range(8):
        x = -1.35 + i * 0.385
        L = 0.2 + 0.05 * (i % 3)
        goods.box((x, yb, zb - 0.07), (0.02, 0.02, 0.14), TRIM)
        goods.frustum((x, yb, zb - 0.14 - L * 0.5), 0.1, 0.075, L, LARCH_RUST, segments=8)
    print("souvenir_stall: streasina %.2f, sus %.2f" % (z_eave, z_hi))
    return [Builder.to_object(wood, "Stall_Wood"), Builder.to_object(roof, "Stall_Roof"),
            Builder.to_object(goods, "Stall_Goods")]


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

if _want("cabana_balea_cascada"):
    emit_tf(build_cabana_balea_cascada(), "buildings/cabana_balea_cascada.glb",
            dict(AO_BUILDING, z_range=(0.0, 9.0)), keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("stana"):
    emit_tf(build_stana(), "buildings/stana.glb", dict(AO_BUILDING, z_range=(0.0, 4.0), dist=1.0),
            keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("arges_house_a"):
    emit_tf(build_arges_house_a(), "buildings/arges_house_a.glb",
            dict(AO_BUILDING, z_range=(0.0, 7.0)), keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("arges_house_b"):
    emit_tf(build_arges_house_b(), "buildings/arges_house_b.glb",
            dict(AO_BUILDING, z_range=(0.0, 7.0)), keep_xy=True, bevel=0.0, smooth_angle=None)

if _want("souvenir_stall"):
    emit_tf(build_souvenir_stall(), "props/souvenir_stall.glb",
            dict(AO_BUILDING, z_range=(0.0, 3.0), dist=0.6), keep_xy=True, bevel=0.0,
            smooth_angle=None)

report_tf()
