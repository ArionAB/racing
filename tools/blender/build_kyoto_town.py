"""Kyoto -- orasul (brief docs/asset_briefs/kyoto_kit.md §1.6).

  kyoto/buildings/machiya_a..e.glb   case de oras (se multiplica de zeci de ori)
  kyoto/props/teahouse_front.glb     banca + umbrela rosie
  kyoto/props/paper_lantern.glb      stalp cu brat si felinar de hartie
  kyoto/structures/temple_wall.glb   modul de zid 8 m (capete plane)

Casele folosesc O SINGURA functie (`_machiya`) cu parametri; ce le face sa se
citeasca diferit sunt dezvoltarile fatadei (noren alb / albastru / niciunul,
jaluzele de bambus, ferestre mari sau divizate, perete alb sus) -- exact ce
difera pe decupari. Fata bogata = +Y Blender = -Z Godot (se masoara pe GLB cu
`--views`). Spatele e simplu: stalpi si o bordura.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_town.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

TILE = VOLCANIC_BLACK      # tigla kawara, din atlas
TRIM = WOOD                # rame, stalpi, brauri, zabrele: lemn DESCHIS (contrast cu scandurile)
RFB = LOG_DARK             # grinzi de streasina/creasta (nodul Roof)
WOODS = WOOD               # lemn de machiya (clasa machiya_wood)
PLASTER = FOAM_WHITE       # var (clasa village_plaster)
STONE_SILL = CONCRETE      # soclu de casa
BAMBOO = SAND_MID          # jaluzele de bambus
NOREN_BLUE = CAR_BLUE      # noren albastru (exceptie --allow-car-slots=Machiya_Noren)
NOREN_WHITE = FOAM_WHITE

AO_HOUSE = dict(samples=10, dist=2.6, gradient="vertical",
                low=0.70, high=1.0, power=0.8, floor=0.30)
AO_PROP = dict(samples=14, dist=1.6, gradient="vertical",
               low=0.75, high=1.0, power=0.8, floor=0.35)

clear_built()

# ---------------------------------------------------------------- case ------
HX, HY = 3.25, 2.6            # semi-latimea fatadei (6,5 m) si semi-adancimea
Z_PLINTH = 0.35
XSCALE = 0.8                  # latimea reala = 6,5 m cu streasina (decuparea e mai ingusta decat contractul)
GT = 3.1                    # varful golurilor parterului
UP0, UP1 = 4.25, 6.2        # deschiderile etajului (jos, sus)
Z_MID = 3.75                   # brau intre parter si etaj
Z_WALL = 6.55                  # varful peretilor
Z_EAVE = 6.5                 # streasina mare, la margine
Z_RIDGE = 8.7
EAVE_Y = 3.4                  # streasina mare iese cu 0,8 m fata si spate
EAVE_X = 3.85                 # si cu 0,6 m pe lateral


def _slab(b, p1, p2, width, thick, slot):
    """Placa inclinata intre doua puncte, latime pe X."""
    return b.beam(p1, p2, (width, thick), slot)


def _course(b, y, z, half, ty, tz, slot):
    """Rand de tigla: grinda pe X, la (y, z)."""
    return b.beam((-half, y, z), (half, y, z), (ty, tz), slot)


class _H:
    """Constructorii unei case + ajutoare de fatada (planul fetei: y = HY)."""

    def __init__(self):
        self.wd = Builder()
        self.tr = Builder()
        self.pl = Builder()
        self.rf = Builder()
        self.nr = Builder()
        self.bm = Builder()

    # -- plan: cutie lipita pe fata, y = HY .. HY + proud
    def _face_box(self, b, x0, x1, z0, z1, proud, slot, off=0.0):
        # fatada e desenata ca in decupare, vazuta din drum (stanga = +X)
        x0, x1 = -x1, -x0
        b.box(((x0 + x1) / 2.0, HY + off + proud / 2.0, (z0 + z1) / 2.0),
              (x1 - x0, proud, z1 - z0), slot)

    def post(self, x, z0, z1, w=0.17, proud=0.12):
        self._face_box(self.tr, x - w / 2, x + w / 2, z0, z1, proud, TRIM)

    def rail(self, x0, x1, z, h=0.14, proud=0.12):
        self._face_box(self.tr, x0, x1, z - h / 2, z + h / 2, proud, TRIM)

    def frame(self, x0, x1, z0, z1, t=0.1, proud=0.12):
        self._face_box(self.tr, x0, x1, z0, z0 + t, proud, TRIM)
        self._face_box(self.tr, x0, x1, z1 - t, z1, proud, TRIM)
        self._face_box(self.tr, x0, x0 + t, z0, z1, proud, TRIM)
        self._face_box(self.tr, x1 - t, x1, z0, z1, proud, TRIM)

    def dark(self, x0, x1, z0, z1, proud=0.05):
        self._face_box(self.wd, x0, x1, z0, z1, proud, WOODS)   # gol intunecat = nodul cu clasa

    # -- deschideri
    def shoji(self, x0, x1, z0, z1, cols=2, rows=2, t=0.1, pane=PLASTER):
        """Fereastra cu panouri albe de hartie in rama intunecata."""
        self.dark(x0, x1, z0, z1, 0.05)
        self._face_box(self.pl, x0 + t, x1 - t, z0 + t, z1 - t, 0.085, pane)
        self.frame(x0, x1, z0, z1, t, 0.13)
        for i in range(1, cols):
            x = x0 + (x1 - x0) * i / cols
            self._face_box(self.tr, x - 0.035, x + 0.035, z0, z1, 0.11, TRIM)
        for j in range(1, rows):
            z = z0 + (z1 - z0) * j / rows
            self._face_box(self.tr, x0, x1, z - 0.035, z + 0.035, 0.11, TRIM)

    def glass(self, x0, x1, z0, z1, cols=2, rows=1, t=0.09):
        """Geam intunecat in rama de lemn (fara hartie alba)."""
        self.dark(x0, x1, z0, z1, 0.06)
        self.frame(x0, x1, z0, z1, t, 0.12)
        for i in range(1, cols):
            x = x0 + (x1 - x0) * i / cols
            self._face_box(self.tr, x - 0.04, x + 0.04, z0, z1, 0.1, TRIM)
        for j in range(1, rows):
            z = z0 + (z1 - z0) * j / rows
            self._face_box(self.tr, x0, x1, z - 0.04, z + 0.04, 0.1, TRIM)

    def lattice(self, x0, x1, z0, z1, pitch=0.16, rails=0, t=0.1):
        """Zabrele koshi: sipci verticale de lemn pe fond intunecat."""
        self.dark(x0, x1, z0, z1, 0.05)
        n = max(int((x1 - x0) / pitch), 2)
        for i in range(n):
            x = x0 + t + (x1 - x0 - 2 * t) * (i + 0.5) / n
            self._face_box(self.tr, x - 0.03, x + 0.03, z0 + t, z1 - t, 0.12, TRIM)
        for j in range(rails):
            z = z0 + (z1 - z0) * (j + 1) / (rails + 1)
            self._face_box(self.tr, x0, x1, z - 0.04, z + 0.04, 0.13, TRIM)
        self.frame(x0, x1, z0, z1, t, 0.14)

    def boards(self, x0, x1, z0, z1, pitch=0.2, t=0.09):
        """Usa/perete de scanduri verticale cu rosturi intunecate."""
        self.dark(x0, x1, z0, z1, 0.04)
        n = max(int((x1 - x0) / pitch), 2)
        for i in range(n):
            xa = x0 + (x1 - x0) * i / n + 0.018
            xb = x0 + (x1 - x0) * (i + 1) / n - 0.018
            self._face_box(self.tr, xa, xb, z0 + t, z1 - t, 0.09, TRIM)
        self.frame(x0, x1, z0, z1, t, 0.13)

    def doorway(self, x0, x1, z0, z1):
        self.dark(x0, x1, z0, z1, 0.06)
        self.frame(x0, x1, z0, z1, 0.1, 0.13)

    def noren(self, x0, x1, ztop, drop, flaps, slot, builder):
        """Draperie de usa: bara + `flaps` fasii cu rost intre ele."""
        self._face_box(self.tr, x0 - 0.05, x1 + 0.05, ztop - 0.05, ztop + 0.03, 0.2, TRIM)
        w = (x1 - x0) / flaps
        for i in range(flaps):
            xa = x0 + w * i + 0.06
            xb = x0 + w * (i + 1) - 0.06
            self._face_box(builder, xa, xb, ztop - drop, ztop - 0.05, 0.035, slot, off=0.17)

    def bamboo_blind(self, x0, x1, z0, z1, pitch=0.2):
        """Jaluzea de bambus: leturi late, rola sus."""
        self.dark(x0, x1, z0, z1, 0.05)
        n = max(int((x1 - x0) / pitch), 3)
        for i in range(n):
            xa = x0 + (x1 - x0) * i / n + 0.02
            xb = x0 + (x1 - x0) * (i + 1) / n - 0.02
            self._face_box(self.bm, xa, xb, z0 + 0.12, z1 - 0.1, 0.1, BAMBOO)
        self._face_box(self.tr, x0 - 0.04, x1 + 0.04, z1 - 0.12, z1, 0.16, TRIM)
        self._face_box(self.tr, x0 - 0.04, x1 + 0.04, z0, z0 + 0.1, 0.14, TRIM)
        self.frame(x0, x1, z0, z1, 0.08, 0.15)

    def plaster_band(self, z0, z1):
        """Perete alb (var) pe toata latimea, sub deschiderile etajului."""
        self._face_box(self.pl, -HX, HX, z0, z1, 0.05, PLASTER)

    def hisashi(self, y_out=1.05, side=None):
        """Streasina intermediara peste parter (tigla pe consolele de lemn)."""
        rf, tr = self.rf, self.tr
        ze = Z_MID - 0.38
        # placa: de la perete (sus) la margine (jos)
        _slab(rf, (0, HY + 0.02, ze + 0.62), (0, HY + y_out, ze), 2 * (HX + 0.28), 0.16, TILE)
        for k in range(4):
            f = (k + 0.5) / 4.0
            _course(rf, HY + 0.02 + (y_out - 0.02) * f, ze + 0.62 * (1 - f) + 0.1,
                    HX + 0.28, 0.12, 0.07, TILE)
        # fateta streasinii
        _course(rf, HY + y_out + 0.03, ze - 0.06, HX + 0.3, 0.1, 0.2, RFB)
        # console (4) sub streasina
        for x in (-HX + 0.2, -HX / 3, HX / 3, HX - 0.2):
            tr.beam((x, HY + 0.02, ze - 0.15), (x, HY + y_out - 0.12, ze - 0.12),
                    (0.1, 0.1), TRIM)

    def roof(self, ridge_dir="x"):
        """Acoperisul in doua ape, creasta pe X (paralel cu strada)."""
        rf, tr = self.rf, self.tr
        half = EAVE_X
        for sgn in (1, -1):
            _slab(rf, (0, sgn * EAVE_Y, Z_EAVE), (0, 0.0, Z_RIDGE), 2 * half, 0.2, TILE)
            for k in range(6):
                f = (k + 0.5) / 6.0
                _course(rf, sgn * EAVE_Y * (1 - f), Z_EAVE + (Z_RIDGE - Z_EAVE) * f + 0.11,
                        half, 0.2, 0.09, TILE)
            # fateta streasinii (grinda de capat) + capete de tigla
            _course(rf, sgn * (EAVE_Y + 0.03), Z_EAVE - 0.07, half, 0.14, 0.26, RFB)
        # creasta
        _course(rf, 0.0, Z_RIDGE + 0.12, half + 0.05, 0.36, 0.3, RFB)
        # frontoanele: sipci de vant (barge) pe laturile scurte
        for sx in (-1, 1):
            for sgn in (1, -1):
                rf.beam((sx * (half + 0.02), sgn * EAVE_Y, Z_EAVE - 0.05),
                        (sx * (half + 0.02), 0.0, Z_RIDGE + 0.05), (0.1, 0.22), RFB)

    def walls(self, plaster_upper=False):
        """Miezul: lemn pe tot corpul, timpane, brauri si stalpi pe laturi/spate."""
        wd, tr = self.wd, self.tr
        zc = (Z_PLINTH + Z_WALL) / 2.0
        wd.box((0, 0, zc), (2 * HX, 2 * HY, Z_WALL - Z_PLINTH), WOODS)
        # soclu
        tr.box((0, 0, Z_PLINTH / 2.0), (2 * HX + 0.34, 2 * HY + 0.34, Z_PLINTH), STONE_SILL)
        # timpanele (lemn) sub acoperis
        for sx in (-1, 1):
            xa, xb = (HX - 0.02, HX) if sx > 0 else (-HX, -HX + 0.02)
            tri_prism_x(wd, xa, xb, [(-HY, Z_WALL), (HY, Z_WALL), (0.0, Z_RIDGE - 0.25)], WOODS)
        # brau intre etaje si la varf, pe toate laturile
        for sy in (-1, 1):
            tr.box((0, sy * (HY + 0.05), Z_MID), (2 * HX + 0.2, 0.14, 0.26), TRIM)
            tr.box((0, sy * (HY + 0.05), Z_WALL - 0.12), (2 * HX + 0.2, 0.14, 0.24), TRIM)
        for sx in (-1, 1):
            tr.box((sx * (HX + 0.05), 0, Z_MID), (0.14, 2 * HY + 0.1, 0.26), TRIM)
            tr.box((sx * (HX + 0.05), 0, Z_WALL - 0.12), (0.14, 2 * HY + 0.1, 0.24), TRIM)
            # stalpi pe laturi
            for y in (-HY, -HY / 3, HY / 3, HY):
                tr.box((sx * (HX + 0.05), y, (Z_PLINTH + Z_WALL) / 2.0),
                       (0.14, 0.17, Z_WALL - Z_PLINTH), TRIM)
        # spatele: stalpi simpli (fara deschideri)
        for x in (-HX, -HX / 3, HX / 3, HX):
            tr.box((x, -HY - 0.05, (Z_PLINTH + Z_WALL) / 2.0), (0.17, 0.14, Z_WALL - Z_PLINTH), TRIM)
        # coltarele fatadei
        self.post(-HX, Z_PLINTH, Z_WALL, 0.2, 0.14)
        self.post(HX, Z_PLINTH, Z_WALL, 0.2, 0.14)
        # brau de fatada
        self.rail(-HX, HX, Z_MID, 0.26, 0.14)
        self.rail(-HX, HX, Z_WALL - 0.12, 0.24, 0.14)

    def objs(self, prefix):
        for b in (self.wd, self.tr, self.pl, self.rf, self.nr, self.bm):
            for v in b.bm.verts:
                v.co.x *= XSCALE
        out = [self.wd.to_object(prefix + "_Wood"), self.tr.to_object(prefix + "_Trim"),
               self.pl.to_object(prefix + "_Plaster"), self.rf.to_object(prefix + "_Roof")]
        if len(self.nr.bm.verts):
            out.append(self.nr.to_object(prefix + "_Noren"))
        if len(self.bm.bm.verts):
            out.append(self.bm.to_object(prefix + "_Bamboo"))
        return out


def _machiya_a():
    """`machiya_a.png` -- lista de elemente (inainte de modelare):
    - 2 etaje, acoperis in doua ape cu creasta paralela cu strada, tigla gri,
      streasina mare peste etaj; streasina INTERMEDIARA peste parter pe toata
      latimea; lateral (stanga in randare) peretele de capat cu timpan.
    - parter: stanga usa de scanduri; centru usa deschisa cu NOREN ALB in 2
      fasii; dreapta zabrele fine (koshi) joase.
    - etaj: stanga o fereastra ingusta alba; dreapta 3 ferestre cu hartie alba
      in rame intunecate, aliniate; lemn brun intre ele.
    - fara bambus, fara perete alb.
    """
    h = _H()
    h.walls()
    h.hisashi()
    h.roof()
    # parter
    h.boards(-3.0, -1.75, Z_PLINTH, GT)
    h.doorway(-1.5, 0.95, Z_PLINTH, GT)
    h.noren(-1.4, 0.85, GT, 2.0, 2, NOREN_WHITE, h.nr)
    h.lattice(1.25, 3.0, 0.75, GT, pitch=0.15)
    # etaj
    h.shoji(-3.0, -2.05, UP0, UP1, cols=1, rows=1)
    h.shoji(-1.75, -0.35, UP0, UP1, cols=1, rows=1)
    h.shoji(-0.1, 1.3, UP0, UP1, cols=1, rows=1)
    h.shoji(1.55, 2.95, UP0, UP1, cols=1, rows=1)
    for x in (-3.25, -2.05, -0.22, 1.43, 3.25):
        h.post(x, Z_MID + 0.13, Z_WALL - 0.24)
    return h.objs("Machiya")


def _machiya_b():
    """`machiya_b.png`:
    - aceeasi carcasa; etajul e PERETE ALB (var) cu o singura fereastra larga
      de lemn cu 3 panouri, deasupra usii; rame brune groase.
    - parter: stanga usa de scanduri; centru usa cu NOREN ALBASTRU in 3 fasii
      (cu mica placuta alba); dreapta panou de scanduri cu fereastra mica.
    """
    h = _H()
    h.walls()
    h.hisashi()
    h.roof()
    # parter
    h.boards(-3.0, -1.55, Z_PLINTH, GT)
    h.doorway(-1.3, 1.35, Z_PLINTH, GT)
    h.noren(-1.2, 1.25, GT, 2.0, 3, NOREN_BLUE, h.nr)
    h.boards(1.65, 3.0, Z_PLINTH, GT, pitch=0.22)
    h.shoji(1.95, 2.7, 1.5, 2.6, cols=1, rows=2)
    # etaj: perete alb + fereastra mare cu 3 panouri
    h.plaster_band(Z_MID + 0.13, Z_WALL - 0.24)
    h.shoji(-1.45, 1.45, UP0 + 0.1, UP1 - 0.1, cols=3, rows=1, t=0.14)
    for x in (-3.25, -2.2, 2.2, 3.25):
        h.post(x, Z_MID + 0.13, Z_WALL - 0.24, 0.2)
    h.rail(-HX, HX, UP0 - 0.08, 0.12, 0.16)
    return h.objs("Machiya")


def _machiya_c():
    """`machiya_c.png`:
    - aceeasi carcasa, soclu mai inalt de piatra clara.
    - etaj: TREI ferestre mari, inalte, cu hartie alba si cate un montant
      central, in rame brune; lemn intre ele.
    - parter: TREI travei de zabrele FINE (koshi, pas 0,1 m) pe toata latimea.
    - fara noren.
    """
    h = _H()
    h.walls()
    h.hisashi()
    h.roof()
    bays = ((-3.0, -1.2), (-0.95, 0.95), (1.2, 3.0))
    for x0, x1 in bays:
        h.lattice(x0, x1, 1.7, GT, pitch=0.1, t=0.1)
        h.boards(x0, x1, Z_PLINTH, 1.65, pitch=0.3)
        h.shoji(x0, x1, UP0, UP1, cols=2, rows=2, t=0.12)
    for x in (-3.25, -1.075, 1.075, 3.25):
        h.post(x, Z_MID + 0.13, Z_WALL - 0.24, 0.22)
    return h.objs("Machiya")


def _machiya_d():
    """`machiya_d.png`:
    - aceeasi carcasa; etajul poarta JALUZELE DE BAMBUS: trei panouri late de
      leturi galben-ocru, cu rola sus, intre stalpi bruni; stanga o fereastra
      mica alba.
    - parter: stanga geam intunecat, centru usa/geam larg cu zabrele rare,
      dreapta doua geamuri cu zabrele.
    """
    h = _H()
    h.walls()
    h.hisashi()
    h.roof()
    h.glass(-3.0, -1.7, 0.9, GT, cols=1, rows=2)
    h.lattice(-1.45, 0.65, 0.45, GT, pitch=0.28, rails=1)
    h.lattice(0.9, 3.0, 0.9, GT, pitch=0.22)
    h.shoji(-3.0, -2.45, UP0, UP1, cols=1, rows=2)
    h.bamboo_blind(-2.2, -1.0, UP0, UP1)
    h.bamboo_blind(-0.85, 0.35, UP0, UP1)
    h.bamboo_blind(0.5, 1.7, UP0, UP1)
    h.bamboo_blind(1.85, 3.0, UP0, UP1)
    for x in (-3.25, -2.3, -0.92, 0.42, 1.78, 3.25):
        h.post(x, Z_MID + 0.13, Z_WALL - 0.24)
    return h.objs("Machiya")


def _machiya_e():
    """`machiya_e.png`:
    - aceeasi carcasa + MICA STREASINA LATERALA pe capatul din dreapta (in
      randare), peste parter.
    - etaj: perete alb cu CADRU APARENT (half-timber): montanti si traverse
      bruni, doua ferestre cu panouri DIVIZATE 3 x 2.
    - parter: trei usi glisante cu geam divizat (zabrele rare, 2 rame), fara
      noren.
    """
    h = _H()
    h.walls()
    h.hisashi()
    h.roof()
    h.plaster_band(Z_MID + 0.13, Z_WALL - 0.24)
    h.glass(-0.95, 0.95, UP0 + 0.1, UP1 - 0.05, cols=2, rows=2, t=0.1)
    h.shoji(-2.75, -1.35, UP0 + 0.2, UP1 - 0.2, cols=1, rows=1, t=0.1)
    h.shoji(1.35, 2.75, UP0 + 0.2, UP1 - 0.2, cols=1, rows=1, t=0.1)
    for x in (-3.25, -3.0, -1.15, 1.15, 3.0, 3.25):
        h.post(x, Z_MID + 0.13, Z_WALL - 0.24, 0.17)
    h.rail(-HX, HX, UP0 - 0.08, 0.14, 0.16)
    h.rail(-HX, HX, UP1 + 0.1, 0.14, 0.16)
    for x0, x1 in ((-3.0, -1.0), (-0.85, 0.85), (1.0, 3.0)):
        h.lattice(x0, x1, 1.7, GT, pitch=0.33, rails=1, t=0.1)
        h.boards(x0, x1, Z_PLINTH, 1.65, pitch=0.3)
    # streasina laterala (dreapta spre -X in randare: capatul de -X)
    rf, tr = h.rf, h.tr
    xo = -HX - 1.0
    rf.beam((-HX - 0.02, 0.0, Z_MID + 0.3), (xo, 0.0, Z_MID - 0.3), (2 * HY + 0.5, 0.16), TILE)
    for k in range(4):
        f = (k + 0.5) / 4.0
        rf.beam((-HX - 0.02 - (1.0 - 0.02) * f, -HY - 0.2, Z_MID + 0.3 - 0.6 * f + 0.1),
                (-HX - 0.02 - (1.0 - 0.02) * f, HY + 0.2, Z_MID + 0.3 - 0.6 * f + 0.1),
                (0.12, 0.07), TILE)
    rf.box((xo - 0.03, 0.0, Z_MID - 0.36), (0.1, 2 * HY + 0.5, 0.2), RFB)
    return h.objs("Machiya")


MACHIYAS = (("machiya_a", _machiya_a, 0), ("machiya_b", _machiya_b, 0),
            ("machiya_c", _machiya_c, 0), ("machiya_d", _machiya_d, 0),
            ("machiya_e", _machiya_e, 0))


# ------------------------------------------------------------ ceainarie -----
def build_teahouse_front():
    """`teahouse_front.png` -- lista de elemente:
    - banca joasa cu sezut ROSU (pernita) si spatar de lemn cu zabrele, 4
      picioare; sta in stanga/fata.
    - cutie de lemn cu sipci (postament), in dreapta/spate.
    - stalp central subtire din cutie, care sustine UMBRELA rosie (nodate-gasa):
      cupola larga, usor concava spre margine, cu varf (finial) si 8 spite
      vizibile pe dedesubt.
    Cote: ~3 x 2,4 x 3 m. Fata (banca) spre +Y.
    """
    red = Builder()
    wood = Builder()
    # banca (lunga, joasa, cu spatar inalt)
    bx, by, bl = 1.0, 0.3, 1.8
    red.box((bx, by, 0.5), (bl, 0.7, 0.16), CAR_RED)                   # sezut / perna
    for sx in (-1, 1):
        for sy in (-1, 1):
            wood.box((bx + sx * (bl / 2 - 0.1), by + sy * 0.25, 0.21), (0.12, 0.12, 0.42), WOOD)
    wood.box((bx, by, 0.4), (bl - 0.04, 0.6, 0.06), WOOD)
    # spatar: rama + zabrele dese
    wood.box((bx, by - 0.34, 1.12), (bl, 0.1, 0.1), WOOD)
    wood.box((bx, by - 0.34, 0.6), (bl, 0.1, 0.1), WOOD)
    for k in range(13):
        x = bx - bl / 2 + 0.12 + (bl - 0.24) * k / 12.0
        wood.box((x, by - 0.34, 0.86), (0.08, 0.08, 0.56), WOOD)
    for sx in (-1, 1):
        wood.box((bx + sx * (bl / 2 - 0.05), by - 0.34, 0.86), (0.1, 0.1, 0.62), WOOD)
    # cutia de lemn
    px, py = -0.8, -0.3
    wood.box((px, py, 0.36), (0.78, 0.78, 0.72), WOOD)
    for k in range(5):
        z = 0.12 + 0.14 * k
        wood.box((px, py + 0.4, z + 0.04), (0.8, 0.03, 0.05), WOOD)
        wood.box((px + 0.4, py, z + 0.04), (0.03, 0.8, 0.05), WOOD)
    wood.box((px, py, 0.74), (0.84, 0.84, 0.06), WOOD)
    # stalp
    wood.box((px, py, 1.6), (0.13, 0.13, 1.7), WOOD)
    # umbrela: cupola larga, concava la margine
    prof = [(1.5, 2.25), (1.36, 2.36), (1.08, 2.54), (0.74, 2.72), (0.4, 2.88),
            (0.16, 2.98), (0.0, 3.05)]
    red.revolve(prof, CAR_RED, segments=16, origin=(px, py, 0.0), cap_bottom=True)
    wood.frustum((px, py, 3.1), 0.06, 0.0, 0.14, WOOD, segments=6)       # finial
    for k in range(8):
        a_ = 2 * math.pi * k / 8.0
        wood.beam((px, py, 2.22), (px + 1.4 * math.cos(a_), py + 1.4 * math.sin(a_), 2.22),
                  (0.04, 0.04), WOOD)
    return (red.to_object("Tea_Red"), wood.to_object("Tea_Wood"))


# --------------------------------------------------------------- felinar ----
def build_paper_lantern():
    """`paper_lantern.png` -- lista de elemente:
    - stalp de lemn patrat, subtire, ~3,6 m, putin lat la baza.
    - BRAT orizontal de lemn la varf, spre dreapta, cu un cleste (diagonala)
      de sprijin; pe planșa e in forma de L inversat.
    - felinar de hartie ALB, oval (cap la cap ~1 m), agatat de capatul bratului
      cu o sfoara scurta; banda NEAGRA sus si jos; cateva nervuri subtiri.
    - FARA semnul rosu (corectura coordonatorului), fara text.
    Origine la baza stalpului (nu centrul bbox). Brat pe +X, fata plata +Y.
    """
    wood = Builder()
    paper = Builder()
    band = Builder()
    wood.box((0, 0, 1.8), (0.17, 0.17, 3.6), WOOD)
    wood.box((0, 0, 0.18), (0.26, 0.26, 0.36), WOOD)                  # picior mai lat
    wood.box((0.5, 0, 3.52), (1.2, 0.12, 0.12), WOOD)                 # bratul (de la -0.1 la 1.1)
    wood.beam((0.05, 0, 2.95), (0.62, 0, 3.46), (0.07, 0.1), WOOD)     # clestele
    lx = 0.95
    wood.box((lx, 0, 3.44), (0.04, 0.04, 0.12), WOOD)                  # sfoara
    prof = [(0.2, 3.38), (0.3, 3.28), (0.355, 3.12), (0.37, 2.95), (0.355, 2.78),
            (0.3, 2.62), (0.2, 2.52)]
    paper.revolve(prof, FOAM_WHITE, segments=10, origin=(lx, 0, 0.0), cap_bottom=True)
    band.frustum((lx, 0, 3.4), 0.17, 0.22, 0.1, ICE_CRACK, segments=10)
    band.frustum((lx, 0, 2.48), 0.22, 0.17, 0.1, ICE_CRACK, segments=10)
    for z, r in ((3.2, 0.32), (3.0, 0.375), (2.8, 0.375), (2.6, 0.32)):
        band.cylinder((lx, 0, z), r + 0.012, 0.02, ICE_CRACK, segments=10)
    return (wood.to_object("Lantern_Wood"), paper.to_object("Lantern_Paper"),
            band.to_object("Lantern_Band"))


# ----------------------------------------------------------------- zid ------
def build_temple_wall():
    """`temple_wall.png` -- lista de elemente:
    - soclu de PIATRA ciclopica din ~3 randuri (11 / 10 / 9 pietre, esalonate),
      ~1,0 m inalt, usor mai lat decat peretele.
    - perete ALB de var, plat, ~1,7 m, pe soclu.
    - CAPAC de tigla in doua ape, mic, cu o rand de capete de tigla rotunde
      la streasina (ribs pe panta la 0,5 m), creasta joasa.
    Modul 8 m pe Y (capete plane, identice, la +-4), 0,6 m grosime pe X,
    3,2 m inaltime. Lantul: nervurile si pietrele cad simetric fata de capete.
    """
    st = Builder()
    pl = Builder()
    rf = Builder()
    L = 8.0
    # soclu: 3 randuri esalonate
    rows = (11, 10, 9)
    rng = _lcg(7)
    z = 0.0
    for r, n in enumerate(rows):
        hgt = (0.43, 0.4, 0.37)[r]
        # taieturi: n pietre, capetele rand impar cu jumatati lipite de capete
        cuts = [(-L / 2.0)]
        base = [i / n for i in range(1, n)]
        for t in base:
            cuts.append(-L / 2.0 + L * (t + (rng() - 0.5) * 0.35 / n))
        cuts.append(L / 2.0)
        for i in range(n):
            y0, y1 = cuts[i] + 0.02, cuts[i + 1] - 0.02
            if i == 0:
                y0 = -L / 2.0
            if i == n - 1:
                y1 = L / 2.0
            w = 0.62 + 0.06 * (1 if r == 0 else 0) - 0.03 * r + (rng() - 0.5) * 0.04
            hh = hgt + (rng() - 0.5) * 0.03
            st.box((0, (y0 + y1) / 2.0, z + hh / 2.0), (w, y1 - y0, hh), MARBLE_GREY)
        z += hgt
    pl.box((0, 0, z + 0.75), (0.46, L, 1.5), FOAM_WHITE)
    zt = z + 1.5                                                  # 2.7
    # capac
    rise, half = 0.5, 0.52
    for sgn in (1, -1):
        rf.beam((sgn * half, 0, zt + 0.0), (0.0, 0, zt + rise), (L, 0.16), TILE)
    rf.box((0, 0, zt + rise + 0.05), (0.22, L, 0.12), LOG_DARK)
    # nervuri pe panta (capete de tigla) la 0.5 m, simetrice fata de capete
    ys = [-L / 2.0 + 0.25 + 0.5 * k for k in range(int(L / 0.5))]
    for sgn in (1, -1):
        for y in ys:
            rf.beam((sgn * (half + 0.03), y, zt - 0.03), (sgn * 0.05, y, zt + rise + 0.07),
                    (0.2, 0.09), TILE)
            rf.box((sgn * (half + 0.04), y, zt - 0.06), (0.1, 0.2, 0.12), LOG_DARK)
    return (st.to_object("Wall_Stone"), pl.to_object("Wall_Plaster"),
            rf.to_object("Wall_Roof"))


# ------------------------------------------------------------------ main ----
import sys as _sys
_only = [a for a in _sys.argv[_sys.argv.index("--") + 1:]] if "--" in _sys.argv else []
_only = [a for a in _only if not a.endswith(".py") and not a.startswith("-")]

for _name, _fn, _ in MACHIYAS:
    if _only and _name not in _only:
        continue
    clear_built()
    _objs = _fn()
    emit_keep_xy(_objs, "buildings/%s.glb" % _name, AO_HOUSE, budget=3200)

if not _only or "teahouse_front" in _only:
    clear_built()
    emit_keep_xy(list(build_teahouse_front()), "props/teahouse_front.glb", AO_PROP, budget=1800)
if not _only or "paper_lantern" in _only:
    clear_built()
    emit_keep_xy(list(build_paper_lantern()), "props/paper_lantern.glb", AO_PROP, budget=800)
if not _only or "temple_wall" in _only:
    clear_built()
    emit_keep_xy(list(build_temple_wall()), "structures/temple_wall.glb", AO_HOUSE, budget=2000)
report()
