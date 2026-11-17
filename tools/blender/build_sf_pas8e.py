"""San Francisco (Track25), pasul 8e: ultimele piese -- POARTA cu acoperisuri de tigla verde (H5),
PASARILE pentru FlockProp (T2: pescarusul si papagalul), VELIERUL din golf (T3) si SIRUL DE
LAMPIOANE de pe strada portii (M9).

Contract: docs/asset_briefs/sanfrancisco_inventory.md §5.1 (H5), §5.3 (M9), §5.5 (T2, T3); comanda
pasului 8e. Regulile comune (atlas pe centre de slot, AO copt in vertex colors, scara metrica,
radacini fara transformari, fara text / firme / sigle / embleme, nimic mai subtire de 0,08 m langa
drum, fara sloturile 14-16 si 30) sunt cele din docs/asset_briefs/sf_cable_car.md §5-§9 si din
`build_sf_struct.py`. Decuparile de caracter: docs/track_briefs/img/sf_assets_v1/
sf_dragon_gate.png, sf_seagull.png, sf_parrot.png. Unde decuparea si inventarul nu se potrivesc,
castiga inventarul (ex. stalpii portii: piatra, nu rosii ca in decupare).

  structures/sf_dragon_gate.glb    Gate_Pillar_1..4, Gate_Frame             (H5)
  animals/sf_gull_perch.glb        Gull_Perch                               (T2, FlockProp)
  animals/sf_gull_glide.glb        Gull_Glide                               (T2, FlockProp)
  animals/sf_parrot_perch.glb      Parrot_Perch                             (T2, FlockProp)
  animals/sf_parrot_fly.glb        Parrot_Fly                               (T2, FlockProp)
  vehicles/sf_sailboat.glb         Sailboat                                 (T3, PathMover)
  props/sf_lantern_string.glb      LanternString                            (M9)

Axe (Blender): X = latimea, Y = -Z Godot (+Y Blender = FATA = -Z Godot), Z = sus. Toate piesele se
construiesc DIRECT in cadrul final, nodurile la identitate (fara recentrare per nod).

H5 -- POARTA (`sf_dragon_gate.png`). 12,0 m lata (X, cu carligele de la colturi) x 9,0 m inalta,
golul central 6,0 m LIBER LA SOL (intre soclurile stalpilor interiori), simetrica fata/spate (fata
declarata -Z Godot). Originea in centrul amprentei, la sol. Cinci noduri, ca hull-ul implicit al
`WorldProp` (un poliedru convex per nod) sa dea corp DOAR pe stalpi: Gate_Pillar_1..4 (de la -X la
+X, cu socluri si tobe), Gate_Frame (tot ce sta peste stalpi: grinzi, friza, console, acoperisuri).
  G1. Stalpii interiori: fus octogonal (tesit) de piatra MARBLE_GREY 29, 0,62 m, la x +-3,40, pana
      la +7,15. Soclul lung pe Y (0,80 x 2,20, VOLCANIC_BLACK 20), blocul de piatra, gulerul inchis
      si doua TOBE de piatra (fata si spate) pe cate un postament -- tobele de la baza stalpilor de
      poarta. Stalpii exteriori: fus 0,50 la x +-5,10, pana la +5,35, soclu si tobe mai mici.
  G2. Grinzile rosii (KERB_RED 7): doua pe deschiderea centrala (+5,55..6,05 si +6,75..7,15), doua
      pe fiecare deschidere laterala (+4,30..4,65 si +5,05..5,35), iesite 0,18 m dincolo de stalpi.
      (Capetele vopsite verde din prima randare citeau ca niste cuburi verzi lipite pe stalpi: scoase.)
  G3. Friza dintre grinzi: panouri retrase PAINTED_METAL 11, despartite de montanti rosii, cu un
      romb verde (21) in mijlocul fiecarui panou. Ornament geometric, FARA text, fara placa cu nume.
  G4. Console (dougong): siruri de console in trei trepte (21 / 11 / 21) pe o scandura de fund
      intunecata (LOG_DARK 28), sub fiecare acoperis; pana de streasina rosie peste ele.
  G5. Contrafisele curbe rosii in colturile de sus ale fiecarei deschideri.
  G6. Acoperisurile in patru ape, CONCAVE, cu streasina ridicata la colturi: cel central (9,5 x
      3,1 m, coama la ~+8,7) si doua laterale, mai jos (coama la ~+6,5) -- treptele. Tigla verde
      TROPICAL_GREEN 21 in randuri (olanele = coloane ridicate alternativ, 0,4 m), muchia
      streasinii verde, dedesubtul (cosoroabele) PAINTED_METAL 11.
  G7. Coamele si coamele de colt CORAL_SAND 19 ("aurul" decuparii, crem), cu carlige ridicate la
      colturi si volute la capetele coamei centrale (curbe abstracte, NU dragoni, nu pesti).
  Fara text, fara inscriptii, fara embleme (brief §8, inventarul).

T2 -- PASARILE (`sf_seagull.png`, `sf_parrot.png`). FlockProp ia UN mesh (`mesh_name`; gol = primul
nod) si il pune static, cu yaw si scara uniforma (0,9-1,15) per instanta: nu exista animatie.
De aceea fiecare specie are DOUA poze, fiecare in FISIERUL ei, cu un singur nod: un GLB cu doua
poze (ca `okinawa/animals/egret.glb`) merge in FlockProp prin `mesh_name`, dar pus ca DecorManual
(o pasare pe un stalp) ar instantia ambele poze una peste alta. Ciocul spre -Z Godot. <= 150 tri
pe nod, un singur material (atlasul).
  Pescarusul (~0,6 m): corp alb FOAM_WHITE 22, spatele si aripile PAINTED_METAL 11 (gri-albastrui),
      varfurile aripilor VOLCANIC_BLACK 20, ciocul SAND_LIGHT 0, picioarele TILE_TERRACOTTA 23.
      Gull_Perch: originea la talpi (Y 0). Gull_Glide: aripi deschise (~1,3 m anvergura), punctul
      cel mai de jos la Y 0.
  Papagalul (~0,6 m, supradimensionat ca pescarusul): corp verde, spatele TROPICAL_GREEN 21 si
      pieptul / dedesubtul aripilor CACTUS_GREEN 12 (mai deschis, galbui), CAPUL ROSU KERB_RED 7
      (singurul semn care-l scoate din verdele chiparosilor), inel alb la ochi, cioc crem 19.
      Parrot_Perch: originea la talpi; coada ATARNA sub creanga (pana la -0,20). Parrot_Fly: aripi
      deschise (~1,0 m), punctul cel mai de jos la Y 0.

T3 -- VELIERUL. Sloop de ~7,6 m, prova spre -Z Godot (conventia PathMover), originea la linia
apei (Y 0) in centrul amprentei. Coca alba (22) cu dunga de linie de plutire VOLCANIC_BLACK 20,
puntea CORAL_SAND 19, cabina alba cu ferestre inchise, catargul si bomul MARBLE_GREY 29.
Vela mare ~8,3 m pe catarg (luff), focul pana la +8,6; panzele albe (22), cu burta. Fara coliziune
(PathMover `collide = false`), fara numar pe vela.

M9 -- SIRUL DE LAMPIOANE. Modul de 7,0 m intre cele doua puncte de prindere (X +-3,5), originea la
mijloc, la cota prinderilor (Y 0 = fata de sus a cablului); totul atarna dedesubt. Cablu gros
(0,09 m) VOLCANIC_BLACK 20, patru lampioane de hartie de 0,60 m, KERB_RED 7, cu capace si ciucur
LOG_DARK 28. Modulele se insiruie cap la cap (festoane). Fara lumina proprie (ora de aur).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_pas8e.py [-- --only=gate,gull,parrot,sail,lantern]
Verificare: tools/blender/measure_sf_pas8e.py (+ --selftest) si verify_sanfrancisco.sh.
"""

import math
import os
import sys
import bmesh
import bpy
from mathutils import Matrix, Vector

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "sf_struct_shapes.py"), encoding="utf-8").read())

WHITE = FOAM_WHITE          # 22
DARK = VOLCANIC_BLACK       # 20
STONE = MARBLE_GREY         # 29
CREAM = CORAL_SAND          # 19
RED = KERB_RED              # 7
STEEL = PAINTED             # 11
JADE = TROPICAL_GREEN       # 21


# ============================================================ lantul comun (ca in build_sf_struct.py)
def uv_from_slots(o):
    me = o.data
    attr = me.attributes["slot"]
    uv = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        u = slot_u(int(attr.data[poly.index].value))
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)
    me.attributes.remove(attr)


def finish_obj(b, name, ao, smooth=None):
    o = b.to_object(name)
    apply_smooth(o, smooth)
    uv_from_slots(o)
    o.data.materials.clear()
    o.data.materials.append(atlas_material())
    zs = [v.co.z for v in o.data.vertices]
    ao = dict(ao)
    ao.setdefault("z_range", (min(zs), max(zs)))
    bake_ao(o, **ao)
    return o


def report(o):
    xs = [v.co.x for v in o.data.vertices]
    ys = [v.co.y for v in o.data.vertices]
    zs = [v.co.z for v in o.data.vertices]
    print("  %-16s %6d tris  AABB Godot X %.3f..%.3f  Y %.3f..%.3f  Z %.3f..%.3f"
          % (o.name, tri_count(o), min(xs), max(xs), min(zs), max(zs), -max(ys), -min(ys)))


def export(objs, rel, blend=None):
    for o in objs:
        report(o)
    print("export:", export_glb(objs, rel))
    if blend:
        print("blend:", save_blend(objs, blend))


def bbox_all(objs):
    vs = [v.co for o in objs for v in o.data.vertices]
    return ([min(v[i] for v in vs) for i in range(3)], [max(v[i] for v in vs) for i in range(3)])


def recenter_xy(o, z_to_zero=True):
    """Originea pe centrul bbox-ului in XY si (optional) la baza: pentru pasari, piese mici."""
    vs = o.data.vertices
    xs = [v.co.x for v in vs]
    ys = [v.co.y for v in vs]
    zs = [v.co.z for v in vs]
    d = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5, -min(zs) if z_to_zero else 0.0))
    for v in vs:
        v.co += d
    return d


def prism_z(b, outline, z0, z1, slot):
    """Contur (x, y) extrudat pe Z intre z0 si z1."""
    return _prism(b, [(x, y, z0) for x, y in outline], [(x, y, z1) for x, y in outline], slot)


def octagon(cx, cy, s, c):
    """Patrat de latura s, tesit cu c la colturi."""
    h = s * 0.5
    return [(cx + h, cy - h + c), (cx + h, cy + h - c), (cx + h - c, cy + h), (cx - h + c, cy + h),
            (cx - h, cy + h - c), (cx - h, cy - h + c), (cx - h + c, cy - h), (cx + h - c, cy - h)]


# ============================================================ H5: poarta
GATE_W2 = 6.0                # jumatatea latimii totale (cu carligele)
GATE_H = 9.0
IN_X, IN_S = 3.40, 0.62      # stalpii interiori: centrul, fusul
IN_BX, IN_BY = 0.80, 2.20    # soclul interior: fata lui interioara la x 3,00 -> golul de 6,00
OUT_X, OUT_S = 5.10, 0.50
OUT_BX, OUT_BY = 0.66, 1.40
IN_TOP, OUT_TOP = 7.15, 5.35
# acoperisurile: (cx, hw, hd, z_e, rise, lift, slab, nu, nh)
ROOF_C = dict(cx=0.0, hw=4.75, hd=1.55, z_e=7.82, rise=0.78, lift=0.50, slab=0.20, nu=24, nh=8)
ROOF_S = dict(cx=4.48, hw=1.30, hd=1.00, z_e=5.946, rise=0.55, lift=0.30, slab=0.18, nu=8, nh=6)
LEVELS_TOP = (0.0, 0.12, 0.30, 0.52, 0.76, 0.94)
LEVELS_BOT = (0.0, 0.30, 0.76, 0.94)
CREST = 0.06                 # olanele: coloanele impare ridicate


def gate_pillar(b, cx, inner):
    sgn = 1.0 if cx > 0 else -1.0
    if inner:
        s, bx, by, top = IN_S, IN_BX, IN_BY, IN_TOP
        blk = (0.72, 0.90, 0.22, 1.00)        # blocul de piatra: X, Y, z0, z1
        col = (0.70, 1.00, 1.12)
        drum = dict(px=0.56, py=0.60, z1=0.70, r=0.36, ln=0.42)
    else:
        s, bx, by, top = OUT_S, OUT_BX, OUT_BY, OUT_TOP
        blk = (0.60, 0.70, 0.20, 0.80)
        col = (0.58, 0.80, 0.90)
        drum = dict(px=0.46, py=0.30, z1=0.50, r=0.24, ln=0.34)
    # soclul lung pe Y, intunecat
    box_mm(b, cx - bx / 2, cx + bx / 2, -by / 2, by / 2, 0.0, 0.22 if inner else 0.20, DARK)
    z_pl = 0.22 if inner else 0.20
    # blocul de piatra si gulerul
    box_mm(b, cx - blk[0] / 2, cx + blk[0] / 2, -blk[1] / 2, blk[1] / 2, blk[2], blk[3], STONE)
    box_mm(b, cx - col[0] / 2, cx + col[0] / 2, -col[0] / 2, col[0] / 2, col[1], col[2], DARK)
    # tobele de piatra, fata si spate: postament + toba culcata pe X
    for sy in (-1, 1):
        yc = sy * (blk[1] / 2 + drum["py"] / 2)
        box_mm(b, cx - drum["px"] / 2, cx + drum["px"] / 2, yc - drum["py"] / 2, yc + drum["py"] / 2,
               z_pl, drum["z1"], STONE)
        b.cylinder((cx, yc, drum["z1"] + drum["r"] - 0.04), drum["r"], drum["ln"], STONE, segments=10, axis="X")
    # fusul octogonal
    prism_z(b, octagon(cx, 0.0, s, 0.07), col[2] - 0.02, top, STONE)


def _brace(b, pts, t):
    prism_xz(b, pts, -t, t, RED)


def _bracket(b, x, z0, tiers):
    """Consola in trepte, pe toata adancimea: (latime X, semi-adancime Y, inaltime)."""
    z = z0
    for k, (w, dy, h) in enumerate(tiers):
        box_mm(b, x - w / 2, x + w / 2, -dy, dy, z, z + h, JADE if k % 2 == 0 else STEEL)
        z += h


def roof_shell(b, cx, hw, hd, z_e, rise, lift, slab, nu, nh, top=JADE, under=STEEL, fascia=JADE):
    """Acoperis in patru ape, CONCAV, ca o coaja inchisa (deci normalele ies corect).

    Fiecare inel e dreptunghiul de semi-latura (hw - hd v, hd (1 - v)): la v = 1 se strange pe
    coama, iar coloanele unesc punctele de streasina cu proiectia lor pe coama (fetele de pe laturi
    si cele doua ape de capat). Inaltimea: z_e + rise v^1,55 (concav: plat la streasina, abrupt
    spre coama) + ridicarea streasinii spre colturi, lift r^2 (1 - v)^1,5, r = cat de aproape e
    coloana de colt (pe ultimii L m ai streasinii). Olanele: coloanele impare ale fetei de sus
    +CREST. Dedesubtul: aceleasi coloane, fara olane, cu `slab` mai jos."""
    L = min(1.5, hd)
    N = 2 * (nu + nh)

    def ring(v):
        a = hw - hd * v
        bb = hd * (1.0 - v)
        out = []
        for k in range(nu):
            t = k / nu
            out.append((a - 2 * a * t, bb, hw - 2 * hw * t, hd, 0))
        for k in range(nh):
            t = k / nh
            out.append((-a, bb - 2 * bb * t, -hw, hd - 2 * hd * t, 1))
        for k in range(nu):
            t = k / nu
            out.append((-a + 2 * a * t, -bb, -hw + 2 * hw * t, -hd, 2))
        for k in range(nh):
            t = k / nh
            out.append((a, -bb + 2 * bb * t, hw, -hd + 2 * hd * t, 3))
        return out

    def lift_at(xe, ye, side, v):
        if side in (0, 2):
            r = (abs(xe) - (hw - L)) / L
        else:
            r = (abs(ye) - (hd - L)) / L
        r = max(0.0, min(1.0, r))
        return lift * r * r * (1.0 - v) ** 1.5

    def z_of(v, xe, ye, side):
        return z_e + rise * v ** 1.55 + lift_at(xe, ye, side, v)

    tops, bots = [], []
    for v in LEVELS_TOP:
        rv = []
        for i, (x, y, xe, ye, side) in enumerate(ring(v)):
            z = z_of(v, xe, ye, side) + (CREST if i % 2 == 1 else 0.0)
            rv.append(b.bm.verts.new((cx + x, y, z)))
        tops.append(rv)
    for v in LEVELS_BOT:
        rv = []
        for (x, y, xe, ye, side) in ring(v):
            rv.append(b.bm.verts.new((cx + x, y, z_of(v, xe, ye, side) - slab)))
        bots.append(rv)
    faces = []

    def quad(a, b_, c, d, slot):
        f = b.bm.faces.new((a, b_, c, d))
        f[b.slot] = slot
        faces.append(f)

    for r0, r1 in zip(tops, tops[1:]):
        for i in range(N):
            j = (i + 1) % N
            quad(r0[i], r0[j], r1[j], r1[i], top)
    for r0, r1 in zip(bots, bots[1:]):
        for i in range(N):
            j = (i + 1) % N
            quad(r1[i], r1[j], r0[j], r0[i], under)
    for i in range(N):
        j = (i + 1) % N
        quad(bots[0][i], bots[0][j], tops[0][j], tops[0][i], fascia)
    f = b.bm.faces.new(tuple(tops[-1]))
    f[b.slot] = top
    f = b.bm.faces.new(tuple(reversed(bots[-1])))
    f[b.slot] = under
    return z_of


def roof_trim(b, cx, hw, hd, z_e, rise, lift, curl_dz, hook=0.36, curl=1.0):
    """Coama, coamele de colt cu carlige si volutele de la capetele coamei (CREAM 19)."""
    vmax = LEVELS_TOP[-1]
    a = hw - hd * vmax
    z_top = z_e + rise * vmax ** 1.55
    ridge_top = z_e + rise + 0.10
    box_mm(b, cx - a - 0.10, cx + a + 0.10, -0.15, 0.15, z_top - 0.04, ridge_top, CREAM)
    # coamele de colt: pe coloana de colt, de la coama la streasina, apoi carligul in sus
    for sx in (-1, 1):
        for sy in (-1, 1):
            pts = []
            for v in reversed(LEVELS_TOP):
                aa = hw - hd * v
                bb = hd * (1.0 - v)
                z = z_e + rise * v ** 1.55 + lift * (1.0 - v) ** 1.5 + 0.08
                pts.append((cx + sx * aa, sy * bb, z))
            c = Vector(pts[-1])
            d = Vector((sx, sy, 0.0)).normalized()
            pts.append(tuple(c + d * (hook * 0.55) + Vector((0, 0, 0.12))))
            pts.append(tuple(c + d * hook + Vector((0, 0, 0.34))))
            radii = [0.085] * (len(pts) - 2) + [0.07, 0.035]
            b.taper_sweep(pts, radii, CREAM, segments=4)
    # volutele de la capetele coamei: lamela in planul XZ, curbata in sus si inapoi
    for sx in (-1, 1):
        x0 = cx + sx * (a + 0.02)
        k = curl
        path = [(x0 - sx * 0.10 * k, 0.0, ridge_top - 0.12 * k), (x0 + sx * 0.16 * k, 0.0, ridge_top - 0.02 * k),
                (x0 + sx * 0.30 * k, 0.0, ridge_top + 0.12 * k + curl_dz * 0.5),
                (x0 + sx * 0.24 * k, 0.0, ridge_top + 0.24 * k + curl_dz)]
        b.blade(path, [0.26 * k, 0.22 * k, 0.15 * k, 0.05 * k], 0.18 * k, CREAM, up=(0, 1, 0))
    return ridge_top


def gate_frame(b, side_shift, curl_dz):
    # ---- deschiderea centrala
    xi = IN_X + IN_S / 2              # fata exterioara a stalpului interior (3,71)
    xf = IN_X - IN_S / 2              # fata dinspre gol a fusului (3,09)
    for z0, z1, dy in ((5.55, 6.05, 0.26), (6.75, 7.15, 0.24)):
        box_mm(b, -xi - 0.18, xi + 0.18, -dy, dy, z0, z1, RED)
    # friza: panourile retrase, montantii rosii, rombul verde
    box_mm(b, -xf, xf, -0.17, 0.17, 6.05, 6.75, STEEL)
    for x in (-1.05, 1.05):
        box_mm(b, x - 0.11, x + 0.11, -0.21, 0.21, 6.05, 6.75, RED)
    rot = Matrix.Rotation(math.radians(45), 3, "Y")
    for x in (-2.07, 0.0, 2.07):
        for sy in (-1, 1):
            b.box((x, sy * 0.19, 6.40), (0.30, 0.05, 0.30), JADE, rotation=rot)
    # contrafisele curbe in colturile de sus ale golului
    for sx in (-1, 1):
        pts = [(sx * xf, 5.56), (sx * 2.05, 5.56), (sx * 2.25, 5.31), (sx * 2.55, 5.06), (sx * 2.85, 4.87),
               (sx * xf, 4.66)]
        if sx < 0:
            pts = list(reversed(pts))
        _brace(b, pts, 0.12)
    # consolele: scandura de fund, 12 console pe toata adancimea, pana de streasina, tavanul
    box_mm(b, -xi, xi, -0.14, 0.14, 7.15, 7.72, LOG_DARK)
    n = 12
    for k in range(n):
        _bracket(b, -3.40 + k * 6.80 / (n - 1), 7.15, [(0.22, 0.34, 0.19), (0.32, 0.56, 0.19), (0.44, 0.80, 0.19)])
    for sy in (-1, 1):
        box_mm(b, -4.30, 4.30, sy * 0.80 - 0.12, sy * 0.80 + 0.12, 7.68, 7.86, RED)
    box_mm(b, -4.30, 4.30, -0.80, 0.80, 7.70, 7.95, LOG_DARK)
    roof_shell(b, **ROOF_C)
    roof_trim(b, ROOF_C["cx"], ROOF_C["hw"], ROOF_C["hd"], ROOF_C["z_e"], ROOF_C["rise"], ROOF_C["lift"], curl_dz)
    # ---- deschiderile laterale
    xo = OUT_X + OUT_S / 2            # fata exterioara a stalpului exterior (5,35)
    xo_in = OUT_X - OUT_S / 2         # fata lui dinspre gol (4,85)
    for sx in (-1, 1):
        def X(a, c):
            return sorted((sx * a, sx * c))
        for z0, z1, dy in ((4.30, 4.65, 0.22), (5.05, 5.35, 0.21)):
            x0, x1 = X(IN_X, xo + 0.18)
            box_mm(b, x0, x1, -dy, dy, z0, z1, RED)
        x0, x1 = X(xi, xo_in)
        box_mm(b, x0, x1, -0.15, 0.15, 4.65, 5.05, STEEL)
        for sy in (-1, 1):
            b.box((sx * (xi + xo_in) * 0.5, sy * 0.17, 4.85), (0.22, 0.05, 0.22), JADE, rotation=rot)
        # contrafise mici, in ambele colturi de sus ale golului lateral
        for xa, d in ((xi, 1.0), (xo_in, -1.0)):
            pts = [(xa, 4.31), (xa + d * 0.46, 4.31), (xa + d * 0.32, 4.14), (xa + d * 0.16, 4.00), (xa, 3.93)]
            pts = [(sx * x, z) for x, z in pts]
            if (sx * d) < 0:
                pts = list(reversed(pts))
            _brace(b, pts, 0.10)
        x0, x1 = X(xi, xo)
        box_mm(b, x0, x1, -0.12, 0.12, 5.35, 5.72, LOG_DARK)
        for xx in (4.02, 4.52, OUT_X):
            _bracket(b, sx * xx, 5.35, [(0.20, 0.28, 0.13), (0.28, 0.46, 0.12), (0.38, 0.66, 0.12)])
        x0, x1 = X(3.50, 5.65)
        for sy in (-1, 1):
            box_mm(b, x0, x1, sy * 0.68 - 0.10, sy * 0.68 + 0.10, 5.72, 5.86, RED)
        box_mm(b, x0, x1, -0.68, 0.68, 5.72, 5.95, LOG_DARK)
        rs = dict(ROOF_S)
        rs["cx"] = sx * (ROOF_S["cx"] + side_shift)
        roof_shell(b, **rs)
        roof_trim(b, rs["cx"], rs["hw"], rs["hd"], rs["z_e"], rs["rise"], rs["lift"], 0.0, hook=0.30, curl=0.65)


GATE_AO = dict(samples=24, dist=1.6, gradient="vertical", low=0.78, high=1.0, power=0.8, floor=0.40,
               z_range=(0.0, GATE_H))


def build_gate():
    side_shift, curl_dz = 0.0, 0.0
    for it in range(3):
        clear_built("Gate_")
        objs = []
        for k, (cx, inner) in enumerate(((-OUT_X, False), (-IN_X, True), (IN_X, True), (OUT_X, False))):
            b = Builder()
            gate_pillar(b, cx, inner)
            objs.append(b.to_object("Gate_Pillar_%d" % (k + 1)))
        b = Builder()
        gate_frame(b, side_shift, curl_dz)
        objs.append(b.to_object("Gate_Frame"))
        lo, hi = bbox_all(objs)
        dx = GATE_W2 - max(hi[0], -lo[0])
        dz = GATE_H - hi[2]
        print("  poarta, iteratia %d: X %.4f..%.4f  Z %.4f..%.4f  (corectii dx %.4f dz %.4f)"
              % (it, lo[0], hi[0], lo[2], hi[2], dx, dz))
        if abs(dx) < 0.0005 and abs(dz) < 0.0005:
            break
        side_shift += dx
        curl_dz += dz
    out = []
    for o in objs:
        name = o.name
        apply_smooth(o, 40.0)
        uv_from_slots(o)
        o.data.materials.clear()
        o.data.materials.append(atlas_material())
        bake_ao(o, **GATE_AO)
        out.append(o)
    return out


# ============================================================ T2: pasarile
def _retag_by_normal(b, faces, up_slot, down_slot, thresh=0.0):
    b.retag(faces, up_slot, where=lambda c, n: n.z >= thresh)
    b.retag(faces, down_slot, where=lambda c, n: n.z < thresh)


def gull(pose):
    b = Builder()
    if pose == "perch":
        body = loft(b, [(0, -0.24, 0.175), (0, -0.17, 0.188), (0, -0.07, 0.205), (0, 0.04, 0.222),
                        (0, 0.12, 0.248), (0, 0.160, 0.272)],
                    [0, (0.030, 0.056), (0.080, 0.095), (0.098, 0.102), (0.082, 0.082), 0], WHITE,
                    side=(1, 0, 0), segments=6)
        # spatele (aripile stranse) gri, pieptul si burta albe
        b.retag(body, STEEL, where=lambda c, n: n.z > 0.30 and c.y < 0.10)
        loft(b, [(0, 0.120, 0.255), (0, 0.152, 0.325), (0, 0.185, 0.385), (0, 0.228, 0.398), (0, 0.255, 0.396)],
             [(0.052, 0.050), (0.054, 0.052), (0.060, 0.056), (0.045, 0.041), 0], WHITE, side=(1, 0, 0), segments=6)
        b.taper_sweep([(0, 0.243, 0.390), (0, 0.318, 0.380)], [0.021, 0.0], SAND_LIGHT, segments=4)
        b.box((0.0, 0.205, 0.406), (0.122, 0.022, 0.022), DARK)                          # ochii
        # varfurile aripilor, negre, incrucisate peste coada
        b.blade([(0, -0.06, 0.262), (0, -0.19, 0.236), (0, -0.30, 0.214)], [0.16, 0.11, 0.0], 0.03, DARK)
        b.box((0.0, 0.01, 0.085), (0.085, 0.026, 0.17), TILE_TERRACOTTA)                 # picioarele
    else:
        z0 = 0.105
        body = loft(b, [(0, -0.31, z0 + 0.01), (0, -0.20, z0 + 0.015), (0, -0.06, z0 + 0.005), (0, 0.08, z0),
                        (0, 0.19, z0 + 0.012), (0, 0.250, z0 + 0.018), (0, 0.285, z0 + 0.016)],
                    [0, (0.022, 0.070), (0.072, 0.088), (0.085, 0.090), (0.062, 0.060), (0.050, 0.046), 0],
                    WHITE, side=(1, 0, 0), segments=6)
        b.taper_sweep([(0, 0.275, z0 + 0.012), (0, 0.345, z0 + 0.0)], [0.019, 0.0], SAND_LIGHT, segments=4)
        b.box((0.0, 0.255, z0 + 0.030), (0.098, 0.020, 0.020), DARK)
        for s in (-1, 1):
            w = b.blade([(s * 0.06, 0.05, z0 + 0.03), (s * 0.30, 0.03, z0 + 0.085), (s * 0.52, -0.04, z0 + 0.075),
                         (s * 0.66, -0.12, z0 + 0.045)], [0.22, 0.20, 0.13, 0.02], 0.025, WHITE, up=(0, 0, 1))
            _retag_by_normal(b, w, STEEL, WHITE, thresh=0.0)
            b.retag(w, DARK, where=lambda c, n: abs(c.x) > 0.50)
    o = finish_obj(b, "Gull_Perch" if pose == "perch" else "Gull_Glide",
                   dict(samples=16, dist=0.12, gradient="vertical", low=0.85, high=1.0, power=0.8, floor=0.55),
                   smooth=50.0)
    return o


# Verdele papagalului: (spatele + aripile, pieptul + dedesubtul aripilor). "verde" = decuparea
# (TROPICAL_GREEN 21 / CACTUS_GREEN 12). Variantele sunt parghii de masurare pe captura: in fata
# chiparosilor verdele se pierde (vezi raportul pasului 8e).
PARROT_SCHEMES = {"verde": (TROPICAL_GREEN, CACTUS_GREEN), "turcoaz": (CACTUS_GREEN, REEF_SHALLOW)}
PARROT_SCHEME = os.environ.get("SF_PARROT_SCHEME", "verde")


def parrot(pose):
    back, belly = PARROT_SCHEMES[PARROT_SCHEME]
    b = Builder()
    if pose == "perch":
        body = loft(b, [(0, -0.235, -0.200), (0, -0.170, -0.080), (0, -0.110, 0.030), (0, -0.045, 0.120),
                        (0, 0.005, 0.200), (0, 0.030, 0.272)],
                    [0, (0.012, 0.040), (0.046, 0.068), (0.094, 0.102), (0.106, 0.108), (0.080, 0.082)],
                    back, side=(1, 0, 0), segments=6)
        # pieptul (fata spre +Y) mai deschis, spatele (aripile stranse) verde inchis
        b.retag(body, belly, where=lambda c, n: n.y > 0.25)
        loft(b, [(0, 0.032, 0.288), (0, 0.052, 0.345), (0, 0.082, 0.387), (0, 0.108, 0.394)],
             [(0.068, 0.072), (0.078, 0.076), (0.056, 0.058), 0], RED, side=(1, 0, 0), segments=6)
        b.taper_sweep([(0, 0.100, 0.370), (0, 0.150, 0.358), (0, 0.152, 0.318)], [0.030, 0.020, 0.0], CREAM,
                      segments=4)
        b.box((0.0, 0.072, 0.360), (0.150, 0.036, 0.036), WHITE)                         # inelul de la ochi
        b.box((0.0, 0.010, 0.015), (0.090, 0.060, 0.030), ASPHALT_EDGE)                 # ghearele pe creanga
    else:
        z0 = 0.075
        body = loft(b, [(0, -0.340, z0 + 0.000), (0, -0.220, z0 + 0.012), (0, -0.100, z0 + 0.022),
                        (0, 0.020, z0 + 0.030), (0, 0.125, z0 + 0.040)],
                    [0, (0.012, 0.042), (0.048, 0.064), (0.072, 0.078), (0.060, 0.064)], back,
                    side=(1, 0, 0), segments=6)
        b.retag(body, belly, where=lambda c, n: n.z < -0.25)
        loft(b, [(0, 0.120, z0 + 0.040), (0, 0.180, z0 + 0.052), (0, 0.228, z0 + 0.050), (0, 0.258, z0 + 0.046)],
             [(0.060, 0.064), (0.066, 0.066), (0.048, 0.050), 0], RED, side=(1, 0, 0), segments=6)
        b.taper_sweep([(0, 0.250, z0 + 0.034), (0, 0.290, z0 + 0.018), (0, 0.290, z0 - 0.022)], [0.026, 0.018, 0.0],
                      CREAM, segments=4)
        b.box((0.0, 0.205, z0 + 0.066), (0.135, 0.030, 0.030), WHITE)
        for s in (-1, 1):
            w = b.blade([(s * 0.05, 0.06, z0 + 0.05), (s * 0.28, 0.01, z0 + 0.105),
                         (s * 0.50, -0.13, z0 + 0.075)], [0.17, 0.13, 0.0], 0.022, back, up=(0, 0, 1))
            _retag_by_normal(b, w, back, belly, thresh=0.0)
    o = finish_obj(b, "Parrot_Perch" if pose == "perch" else "Parrot_Fly",
                   dict(samples=16, dist=0.10, gradient="vertical", low=0.85, high=1.0, power=0.8, floor=0.55),
                   smooth=50.0)
    return o


def build_birds(kind):
    out = []
    for pose in (("perch", "glide") if kind == "gull" else ("perch", "fly")):
        o = gull(pose) if kind == "gull" else parrot(pose)
        if pose == "perch":
            # originea la talpi: X/Z pe bbox, Y la talpa (talpile sunt la z 0 prin constructie)
            recenter_xy(o, z_to_zero=False)
        else:
            recenter_xy(o, z_to_zero=True)
        out.append(o)
    return out


# ============================================================ T3: velierul
SB_STATIONS = [  # (y, semi-latimea, cota puntii, cota fundului); prova la +Y
    (-3.55, 1.02, 0.78, -0.18), (-2.60, 1.22, 0.76, -0.32), (-1.20, 1.30, 0.75, -0.40),
    (0.30, 1.26, 0.76, -0.40), (1.60, 1.08, 0.80, -0.34), (2.70, 0.74, 0.86, -0.22),
    (3.50, 0.34, 0.93, -0.06), (4.05, 0.0, 1.00, 0.30)]
SB_PROFILE = [(1.00, 1.0), (0.97, 0.55), (0.93, 0.22), (0.88, 0.04), (0.62, -0.55), (0.0, -1.0)]
MAST_Y, MAST_TOP = 0.95, 10.45


def hull(b):
    """Coca din sectiuni: pe fiecare statie un contur (babord -> carena -> tribord), puntea
    inchide sus. Profilul: (fractia din semi-latime, fractia din pescaj / bord liber)."""
    def zof(t, zd, zb):
        return zd if t >= 1.0 else (zd * t if t >= 0 else zb * (-t))

    rings = []
    for (y, w, zd, zb) in SB_STATIONS[:-1]:
        ring = [(-w * f, y, zof(t, zd, zb)) for f, t in SB_PROFILE]                 # babord, in jos
        ring += [(w * f, y, zof(t, zd, zb)) for f, t in reversed(SB_PROFILE[:-1])]  # tribord, in sus
        rings.append([b.bm.verts.new(p) for p in ring])
    n = len(rings[0])                      # 11: 0..5 babord (5 = chila), 6..10 tribord
    yb, _w, zdb, zbb = SB_STATIONS[-1]     # prova: o singura muchie verticala (x 0)
    bow = [b.bm.verts.new((0.0, yb, zof(t, zdb, zbb))) for _f, t in SB_PROFILE]
    faces = []
    for r0, r1 in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            faces.append(b.bm.faces.new((r0[i], r0[j], r1[j], r1[i])))
    last = rings[-1]
    bow_idx = list(range(len(SB_PROFILE))) + list(range(len(SB_PROFILE) - 2, -1, -1))
    for i in range(n):
        j = (i + 1) % n
        a, c = bow[bow_idx[i]], bow[bow_idx[j]]
        if a is c:
            faces.append(b.bm.faces.new((last[i], last[j], a)))
        else:
            faces.append(b.bm.faces.new((last[i], last[j], c, a)))
    faces.append(b.bm.faces.new(tuple(reversed(rings[0]))))       # oglinda pupei
    for f in faces:
        if not f.is_valid:
            continue
        c = f.calc_center_median()
        f.normal_update()
        if abs(f.normal.z) > 0.8 and c.z > 0.6:
            f[b.slot] = CREAM                     # puntea
        elif c.z < 0.16:
            f[b.slot] = DARK                      # dunga de la linia apei si carena
        else:
            f[b.slot] = WHITE
    return faces


def sail(b, a, top, clew, belly, rows=4, cols=3, t=0.05):
    """Vela triunghiulara cu burta: randuri de la ralinga de jos (a -> clew) spre varf; burta
    pe `belly` (vector lateral), maxima la mijlocul fiecarui rand si mai mica spre varf."""
    a, top, clew, belly = Vector(a), Vector(top), Vector(clew), Vector(belly)
    nrm = (top - a).cross(clew - a).normalized()
    grid_hi, grid_lo = [], []
    for r in range(rows + 1):
        h = r / rows
        p0 = a.lerp(top, h)
        p1 = clew.lerp(top, h)
        row_hi, row_lo = [], []
        if r == rows:
            row_hi = [b.bm.verts.new(top + nrm * t * 0.5)]
            row_lo = [b.bm.verts.new(top - nrm * t * 0.5)]
        else:
            for c in range(cols + 1):
                u = c / cols
                p = p0.lerp(p1, u) + belly * (math.sin(math.pi * u) * (1.0 - h) ** 0.8)
                row_hi.append(b.bm.verts.new(p + nrm * t * 0.5))
                row_lo.append(b.bm.verts.new(p - nrm * t * 0.5))
        grid_hi.append(row_hi)
        grid_lo.append(row_lo)
    fs = []
    for g, flip in ((grid_hi, False), (grid_lo, True)):
        for r in range(rows):
            lo, hi = g[r], g[r + 1]
            for c in range(cols):
                if len(hi) == 1:
                    q = (lo[c], lo[c + 1], hi[0])
                else:
                    q = (lo[c], lo[c + 1], hi[c + 1], hi[c])
                fs.append(b.bm.faces.new(tuple(reversed(q)) if flip else q))
    # muchiile: ralinga de jos, cele doua laturi
    edge_loops = []
    for g in (grid_hi, grid_lo):
        loop = list(g[0]) + [g[r][-1] for r in range(1, rows)] + [g[rows][0]] + [g[r][0] for r in range(rows - 1, 0, -1)]
        edge_loops.append(loop)
    hi_l, lo_l = edge_loops
    for i in range(len(hi_l)):
        j = (i + 1) % len(hi_l)
        fs.append(b.bm.faces.new((hi_l[i], hi_l[j], lo_l[j], lo_l[i])))
    for f in fs:
        f[b.slot] = WHITE
    return fs


def build_sail():
    b = Builder()
    hull(b)
    # cabina, cu ferestrele intunecate
    box_mm(b, -0.72, 0.72, -1.75, 0.55, 0.70, 1.22, WHITE)
    box_mm(b, -0.62, 0.62, -1.62, 0.42, 1.22, 1.30, WHITE)
    for sx in (-1, 1):
        xs = sorted((sx * 0.70, sx * 0.735))
        box_mm(b, xs[0], xs[1], -1.30, 0.20, 0.88, 1.08, DARK)
    # catargul si bomul (bomul iese 22 de grade spre tribord)
    b.cylinder((0.0, MAST_Y, (0.76 + MAST_TOP) * 0.5), 0.075, MAST_TOP - 0.76, STONE, segments=6)
    ang = math.radians(22.0)
    boom_end = Vector((math.sin(ang) * 3.35, MAST_Y - math.cos(ang) * 3.35, 1.88))
    b.beam((0.0, MAST_Y, 1.80), tuple(boom_end), 0.10, STONE)
    # vela mare: ralinga de jos pe bom, varful la +10,2, burta spre babord (vantul din tribord)
    belly = Vector((-math.cos(ang), -math.sin(ang), 0.0)) * 0.38
    sail(b, (0.06, MAST_Y - 0.10, 1.90), (0.02, MAST_Y - 0.06, 10.22), tuple(boom_end + Vector((0, 0, 0.06))), belly,
         rows=4, cols=3)
    # focul: de la prova la +8,6 pe catarg, clew-ul spre tribord, inaintea catargului
    jib_clew = Vector((0.85, MAST_Y + 0.35, 1.30))
    sail(b, (0.0, 3.85, 1.12), (0.0, MAST_Y + 0.12, 8.60), tuple(jib_clew), Vector((-0.30, 0.0, 0.0)),
         rows=3, cols=2)
    # straiul (gros, sa nu sclipeasca) dinaintea focului
    b.beam((0.0, 4.02, 1.02), (0.0, MAST_Y + 0.05, 9.0), 0.06, STONE)
    o = finish_obj(b, "Sailboat", dict(samples=16, dist=1.2, gradient="vertical", low=0.80, high=1.0,
                                       power=0.8, floor=0.45), smooth=40.0)
    print("  velier: originea mutata cu", tuple(round(c, 3) for c in recenter_xy(o, z_to_zero=False)))
    return [o]


# ============================================================ M9: sirul de lampioane
LS_HALF = 3.5
LS_SAG = 0.55
LS_R = 0.045                     # raza cablului (O 0,09)
LS_XS = (-2.1, -0.7, 0.7, 2.1)


def _cable_z(x):
    return -LS_R - LS_SAG * (1.0 - (x / LS_HALF) ** 2)


def build_lanterns():
    b = Builder()
    pts = [(x, 0.0, _cable_z(x)) for x in [-LS_HALF + 2 * LS_HALF * k / 10 for k in range(11)]]
    b.taper_sweep(pts, LS_R, DARK, segments=4)
    for sx in (-1, 1):                                       # bratarile de prindere
        box_mm(b, sx * LS_HALF - 0.07, sx * LS_HALF + 0.07, -0.07, 0.07, -0.13, -0.0, DARK)
    prof = [(0.07, -0.46), (0.17, -0.33), (0.30, -0.11), (0.30, 0.11), (0.17, 0.33), (0.06, 0.37), (0.0, 0.50)]
    for x in LS_XS:
        zc = _cable_z(x) - 0.50 - 0.02
        fs = b.revolve(prof, RED, segments=6, origin=(x, 0.0, zc))
        b.retag(fs, LOG_DARK, where=lambda c, n, zc=zc: abs(c.z - zc) > 0.30)
    o = finish_obj(b, "LanternString", dict(samples=16, dist=0.6, gradient="none", floor=0.50), smooth=50.0)
    return [o]


# ============================================================ main
def main():
    only = None
    for a in sys.argv:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))

    def want(k):
        return only is None or k in only

    clear_built()
    if want("gate"):
        export(build_gate(), "sanfrancisco/structures/sf_dragon_gate.glb", "sf_dragon_gate.blend")
        clear_built()
    for kind in ("gull", "parrot"):
        if want(kind):
            # un fisier pe poza: FlockProp ia primul nod, DecorManual si vitrina instantiaza tot fisierul
            for o in build_birds(kind):
                stem = "sf_" + o.name.lower()
                if kind == "parrot" and PARROT_SCHEME != "verde":
                    stem += "_" + PARROT_SCHEME          # varianta de masurare: alt fisier, nu se comite
                export([o], "sanfrancisco/animals/%s.glb" % stem, stem + ".blend")
            clear_built()
    if want("sail"):
        export(build_sail(), "sanfrancisco/vehicles/sf_sailboat.glb", "sf_sailboat.blend")
        clear_built()
    if want("lantern"):
        export(build_lanterns(), "sanfrancisco/props/sf_lantern_string.glb", "sf_lantern_string.blend")


main()
