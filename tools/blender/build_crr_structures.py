"""Carrara -- structurile (brief docs/asset_briefs/carrara_kit.md §1.3), grupa crr-b.

  carrara/structures/ponti_di_vara.glb     viaductul de caramida pe pile de marmura
  carrara/structures/gallery_portal.glb    gura galeriei Ravaccione (blocuri taiate)
  carrara/structures/marmifera_portal.glb  portalul de piatra al tunelului Marmifera

`gallery_pillar` e AMANAT (kit §1.3: sala de 16 m nu exista in cod).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_crr_structures.py
Variabila de mediu CRR_ONLY=<piesa> reface doar piesa respectiva.

Axe: X latime, Y lungime/adancime (fata spre +Y in Blender = -Z in Godot), Z sus.
Piesele se construiesc DIRECT fata de originea ceruta; exportul nu muta nimic
(`emit_fixed`), deci offsetul e acelasi pe toate nodurile prin constructie:
  ponti_di_vara   originea pe axa drumului la cota drumului (asfaltul din cod e
                  la 0), totul atarna dedesubt (`--origin=rim`); peste -0,05 in
                  |x| <= 4,6 nu sta nimic, peste 0 doar `Viaduct_Parapet`.
  portalurile     originea pe axa drumului, la planul fetei (y = 0), baza la z = 0
                  (`--origin=assembly`); fata pe +Y, spatele intra in munte.

Garzile (pe GLB-ul exportat): `measure_crr_structures.py deck` (banda drumului)
si `... gap` (golul MASURAT CA GOL), rulate de `verify_carrara.sh`.
"""

import math
import os
import random
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "carrara_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("CRR_ONLY", "")

# --- sloturile pe roluri (kit §0, tabelul de sloturi) ------------------------
CRR_BRICK = TILE_TERRACOTTA     # 23: caramida viaductului (*_Brick, clasa roof_tiles)
CRR_STREAK = LARCH_RUST         # 27: darele de rugina pe marmura (*_Rust, atlas)
CRR_STONE = MARBLE_GREY         # 29: piatra portalului Marmifera (*_Stone, clasa tf_stone)
CRR_MOSS = TROPICAL_GREEN       # 21: muschiul de pe portalul Marmifera (pete)
CRR_METAL = PAINTED             # 11 (PAINTED_METAL): sinele, balustrada
CRR_WOOD = WOOD                 # 9 (WOOD_WEATHERED):  traversele
CRR_GLOW = SAND_LIGHT           # 0:  sticla lampilor (*_Glow)
CRR_VOID = VOLCANIC_BLACK       # 20: golurile, captuseala de umbra, feroneria lampii


# ---------------------------------------------------------------------------
# helpere (doar ale structurilor; vocabularul comun ramane in carrara_shapes.py)
# ---------------------------------------------------------------------------

def extrude_yz(b, outline, x0, x1, slot):
    """Prisma dintr-un contur (y, z) -- poate fi CONCAV (timpanul cu arce) --
    extrudata pe X intre x0 si x1. Normalele le reface `Builder.to_object`."""
    n = len(outline)
    a = [b.bm.verts.new((x0, y, z)) for y, z in outline]
    c = [b.bm.verts.new((x1, y, z)) for y, z in outline]
    f = b.bm.faces.new(a)
    f[b.slot] = slot
    f = b.bm.faces.new(list(reversed(c)))
    f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((a[i], a[j], c[j], c[i]))
        f[b.slot] = slot


def extrude_poly_xz(b, pts, y0, y1, slot, bulge=0.0):
    """Piatra din contur (x, z) ANTIORAR, intre y0 (spate) si y1 (fata). Cu
    `bulge` > 0 fata devine un evantai din centroid impins inainte (piatra bruta,
    fata bombata) -- doar pe contururi convexe."""
    n = len(pts)
    fr = [b.bm.verts.new((x, y1, z)) for x, z in pts]
    bk = [b.bm.verts.new((x, y0, z)) for x, z in pts]
    f = b.bm.faces.new(bk)
    f[b.slot] = slot
    if bulge > 0.0:
        cx = sum(p[0] for p in pts) / n
        cz = sum(p[1] for p in pts) / n
        ap = b.bm.verts.new((cx, y1 + bulge, cz))
        for i in range(n):
            f = b.bm.faces.new((fr[i], fr[(i + 1) % n], ap))
            f[b.slot] = slot
    else:
        f = b.bm.faces.new(list(reversed(fr)))
        f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((fr[i], fr[j], bk[j], bk[i]))
        f[b.slot] = slot


def _rect_at(bot, top, z0, z1, z):
    t = (z - z0) / (z1 - z0)
    return tuple(bot[i] + (top[i] - bot[i]) * t for i in range(4))


def _rect_pts(r, z):
    xa, xb, ya, yb = r
    return [Vector((x, y, z)) for x in (xa, xb) for y in (ya, yb)]


def tapered_split(marble, base, bot, top, z0, z1, z_split):
    """Masa de marmura cu sectiune dreptunghiulara care se strange liniar de la
    `bot` (z0) la `top` (z1); dreptunghiurile sunt (x_min, x_max, y_min, y_max).
    Sub `z_split` merge in nodul de patina (*_MarbleBase), deasupra in *_Marble;
    cele doua se ating pe acelasi plan (fara gol, fara suprapunere)."""
    if z_split <= z0 + 1e-6:
        _hull(marble, _rect_pts(bot, z0) + _rect_pts(top, z1), CRR_MARBLE)
        return
    if z_split >= z1 - 1e-6:
        _hull(base, _rect_pts(bot, z0) + _rect_pts(top, z1), CRR_MARBLE_BASE)
        return
    mid = _rect_at(bot, top, z0, z1, z_split)
    _hull(base, _rect_pts(bot, z0) + _rect_pts(mid, z_split), CRR_MARBLE_BASE)
    _hull(marble, _rect_pts(mid, z_split) + _rect_pts(top, z1), CRR_MARBLE)


def box_split(marble, base, lo, hi, z_split):
    """Cutie aliniata (lo, hi colturi), taiata la z_split in patina / lumina."""
    r = (lo[0], hi[0], lo[1], hi[1])
    tapered_split(marble, base, r, r, lo[2], hi[2], z_split)


def streak(b, p_top, normal_xy, along, width, length, slot=CRR_STREAK, lean=(0.0, 0.0)):
    """Dara ingusta (rugina) lipita pe o fata verticala sau usor inclinata:
    p_top = punctul de sus PE fata, normal_xy = normala orizontala a fetei,
    `along` = directia orizontala din planul fetei, `lean` = cat se retrage
    fata pe metru de coborare (pilele teșite). Se ingusteaza spre varf-jos."""
    nx, ny = normal_xy
    ax, ay = along
    pts = []
    for dz, w in ((0.0, width), (length, width * 0.35)):
        for off in (0.010, 0.030):
            for s in (-0.5, 0.5):
                x = p_top[0] + nx * (off + lean[0] * dz) + ax * w * s
                y = p_top[1] + ny * (off + lean[1] * dz) + ay * w * s
                pts.append(Vector((x, y, p_top[2] - dz)))
    _hull(b, pts, slot)


def emit_fixed(objs, path, ao, bevel=0.0, bevels=None, smooth_angle=None):
    """Finish pe fiecare nod FARA sa mute nimic (piesele sunt construite fata de
    originea ceruta, deci offsetul de ansamblu e zero prin constructie) + export
    in assets/models/carrara/<path>."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    total, per_node = 0, {}
    for o in objs:
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        st = finish(o, bevel=bw, bevel_angle=30.0, ao=ao, origin=None,
                    smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    print("%s: bbox X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f" % (
        path, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    _, sz = export_glb(objs, "carrara/" + path)
    CRR_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    return total


# ---------------------------------------------------------------------------
# ponti_di_vara
# ---------------------------------------------------------------------------

AO_VIADUCT = dict(samples=16, dist=3.0, gradient="vertical", low=0.66, high=1.0,
                  power=0.8, floor=0.40, z_range=(-26.0, 0.9))

PV_HALF = 18.0              # 36 m pe Y
PV_TOP = -0.06              # fata de sus a tablierului (sub asfaltul din cod)
PV_FACE = 4.70              # fata laterala a timpanelor de caramida
PV_SPRING = -5.40           # nasterea arcelor = crestetul pilelor
PV_BOTTOM = -26.0           # fundul cheii (+17 fata de drumul de la +43)
PV_ABUT = 4.8               # culeile de la capete (lungime pe Y)
PV_PIER = 3.8               # pilele interioare (lungime pe Y, la crestet)
PV_SPAN = (2 * PV_HALF - 2 * PV_ABUT - 2 * PV_PIER) / 3.0   # 6,27 m
PV_R = PV_SPAN * 0.5
PV_RING = 0.80              # grosimea inelului de bolțari de caramida
PV_PATINA = PV_BOTTOM + (PV_SPRING - 0.45 - PV_BOTTOM) / 3.0  # treimea de jos a pilelor
PV_ARCH_SEG = 14


def _pv_arch_centers():
    y0 = -PV_HALF + PV_ABUT + PV_R
    return [y0, y0 + PV_SPAN + PV_PIER, y0 + 2 * (PV_SPAN + PV_PIER)]


def build_ponti_di_vara():
    """LISTA DE ELEMENTE (decuparea `ponti_di_vara.png`, diorama `diorama_v01_iter2`;
    scrisa INAINTE de geometrie; cotele vin din kit §1.3, nu din planșa):

     1. ARCE: 3, de caramida, in plin cintru (planșa: usor turtite, aproape
        semicerc), deschidere 6,27 m, nasterea la -5,40; inelul de bolțari iese
        0,10 m din fata timpanului, 14 bolțari pe fiecare fata (rostul de 5 cm
        ii desparte ca mase), grosime 0,80 m. Intradosul (bolta) e caramida.
     2. TIMPANE: caramida plina intre nasteri si cornisa, pe toata lungimea
        (36 m, si peste culei, ca pe planșa), fata la |x| = 4,70.
     3. PILE: 2 interioare (3,8 m la crestet, teșite spre fund: 5,0 m x 10,6 m la
        baza) + 2 CULEI la capete (4,8 m, fata spre chei teșita, capatul de
        36 m vertical). Toate de marmura crem, coboara 26 m: CAPITEL (impost)
        iesit 0,15 m sub nastere, un BRAU la -14 m, SOCLU iesit 0,25 m la fund,
        COLTARE pe muchiile dinspre chei (runda 2: 18 asize alternante
        1,15 / 0,70 m, iesite 0,06 m; pe planșa muchiile pilelor sunt blocuri).
        Planșa are pile scurte (h/l ~0,26); tabelul cere pile de 26 m (h/l ~0,75)
        si dioramă le arata inalte -> pilele se LUNGESC, arcele raman.
     4. COLTARE de marmura la ambele capete, pe fete: 9 asize alternante
        (lungi/scurte) de la nastere pana sub cornisa (planșa: culeile au
        marmura urcata pe colt).
     5. CORNISA: doua trepte de marmura (sus 0,36 m iesita 0,65 m; jos 0,28 m
        iesita 0,30 m), pe toata lungimea; fata de sus la -0,06 sub tot drumul.
     6. GOLURI DE DRENAJ: 2 pe fiecare fata, rotunde (12 laturi), deasupra
        pilelor interioare: inel de marmura + disc negru. Planșa are 4 pe fata
        (si deasupra culeilor); kitul cere doua -> se urmeaza kitul.
     7. RUGINA: dare inguste LARCH_RUST sub capitelurile pilelor si culeilor,
        3 pe fata la pile, 2 la culei (planșa: pete portocalii pe blocuri).
     8. PATINA: treimea de jos a pilelor (sub -19,3) pe MARBLE_GREY
        (`Viaduct_MarbleBase`), restul crem (`Viaduct_Marble`).
     9. PARAPET: nod separat `Viaduct_Parapet` la |x| 4,70..5,30, 0,90 m: bordura
        joasa de marmura + stalpi la 1,5 m si 2 rigle de tabla vopsita
        (planșa: balustrada metalica pe bordura).
    10. NU intra: drumul (asfaltul e din cod), tufele si bolovanii de la baza
        pilelor (corectura de kit), nimic peste -0,05 in |x| <= 4,6.

    Noduri: Viaduct_Brick (23), Viaduct_Marble (19), Viaduct_MarbleBase (29),
    Viaduct_Rust (27), Viaduct_Void (20), Viaduct_Parapet (19 + 11)."""
    brick, marble, mbase = Builder(), Builder(), Builder()
    rust, void, para = Builder(), Builder(), Builder()
    centers = _pv_arch_centers()

    # --- 1-2. timpanele cu bolta arcelor (un singur corp extrudat pe X) -------
    corn_bot = -0.70
    outline = [(-PV_HALF, PV_SPRING)]
    for yc in centers:
        for k in range(PV_ARCH_SEG + 1):
            a = math.pi - math.pi * k / PV_ARCH_SEG
            outline.append((yc + PV_R * math.cos(a), PV_SPRING + PV_R * math.sin(a)))
    outline += [(PV_HALF, PV_SPRING), (PV_HALF, corn_bot), (-PV_HALF, corn_bot)]
    extrude_yz(brick, outline, -PV_FACE, PV_FACE, CRR_BRICK)

    # --- 1. bolțarii: 14 pe fiecare fata a fiecarui arc, iesiti 0,10 m ---------
    dg = 0.05 / PV_R                                   # rostul de 5 cm
    for yc in centers:
        for sx in (-1, 1):
            for k in range(PV_ARCH_SEG):
                a0 = math.pi * k / PV_ARCH_SEG + dg * 0.5
                a1 = math.pi * (k + 1) / PV_ARCH_SEG - dg * 0.5
                pts = []
                for a in (a0, a1):
                    for r in (PV_R, PV_R + PV_RING):
                        for x in (PV_FACE - 0.02, PV_FACE + 0.10):
                            pts.append(Vector((sx * x, yc + r * math.cos(a),
                                               PV_SPRING + r * math.sin(a))))
                _hull(brick, pts, CRR_BRICK)

    # --- 5. cornisa --------------------------------------------------------------
    marble.box((0.0, 0.0, (PV_TOP - 0.42) * 0.5), (2 * 5.35, 2 * PV_HALF, PV_TOP + 0.42), CRR_MARBLE)
    marble.box((0.0, 0.0, (-0.42 + corn_bot) * 0.5), (2 * 5.00, 2 * PV_HALF, -0.42 - corn_bot), CRR_MARBLE)

    # --- 3. pile si culei ----------------------------------------------------------
    z_cap0 = PV_SPRING - 0.45          # sub capitel
    z_plinth = PV_BOTTOM + 1.2         # peste soclu
    z_belt = -14.0
    piers = []                          # (y_min_top, y_max_top, y_min_bot, y_max_bot)
    piers.append((-PV_HALF, -PV_HALF + PV_ABUT, -PV_HALF, -PV_HALF + PV_ABUT + 0.6))
    for k in range(2):
        yc = centers[k] + PV_R + PV_PIER * 0.5
        piers.append((yc - PV_PIER * 0.5, yc + PV_PIER * 0.5, yc - 2.5, yc + 2.5))
    piers.append((PV_HALF - PV_ABUT, PV_HALF, PV_HALF - PV_ABUT - 0.6, PV_HALF))
    hx_top, hx_bot = 4.80, 5.30
    for (ya1, yb1, ya0, yb0) in piers:
        bot = (-hx_bot, hx_bot, ya0, yb0)
        top = (-hx_top, hx_top, ya1, yb1)
        tapered_split(marble, mbase, bot, top, z_plinth, z_cap0, PV_PATINA)
        # capitelul (impost), iesit 0,15 m pe laturile libere (nu dincolo de capete)
        ya_c = ya1 - (0.15 if ya1 > -PV_HALF + 1e-6 else 0.0)
        yb_c = yb1 + (0.15 if yb1 < PV_HALF - 1e-6 else 0.0)
        marble.box((0.0, (ya_c + yb_c) * 0.5, z_cap0 + 0.225),
                   (2 * (hx_top + 0.15), yb_c - ya_c, 0.45), CRR_MARBLE)
        # braul de la -14 m: o asiza iesita 0,12 m
        r = _rect_at(bot, top, z_plinth, z_cap0, z_belt)
        ya_b = r[2] - (0.12 if r[2] > -PV_HALF + 1e-6 else 0.0)
        yb_b = r[3] + (0.12 if r[3] < PV_HALF - 1e-6 else 0.0)
        marble.box((0.0, (ya_b + yb_b) * 0.5, z_belt + 0.15),
                   (2 * (r[1] + 0.12), yb_b - ya_b, 0.30), CRR_MARBLE)
        # soclul, iesit 0,25 m, tot pe patina
        ya_p = ya0 - (0.25 if ya0 > -PV_HALF + 1e-6 else 0.0)
        yb_p = yb0 + (0.25 if yb0 < PV_HALF - 1e-6 else 0.0)
        mbase.box((0.0, (ya_p + yb_p) * 0.5, PV_BOTTOM + 0.6),
                  (2 * (hx_bot + 0.25), yb_p - ya_p, 1.2), CRR_MARBLE_BASE)

    # --- 3b. coltarele pilelor: asize alternante pe muchiile verticale, iesite
    # 0,06 m, care urmaresc teșirea (planșa: muchiile pilelor din blocuri decalate)
    for (ya1, yb1, ya0, yb0) in piers:
        bot = (-hx_bot, hx_bot, ya0, yb0)
        top = (-hx_top, hx_top, ya1, yb1)
        n_c = 18
        hc = (z_cap0 - z_plinth) / n_c
        for k in range(n_c):
            za, zb = z_plinth + k * hc + 0.03, z_plinth + (k + 1) * hc - 0.03
            if za < z_belt + 0.35 and zb > z_belt - 0.05:
                continue                       # braul trece peste coltare
            for sx in (-1, 1):
                for sy in (-1, 1):
                    edge_y = (ya1, yb1)[sy > 0]
                    if abs(abs(edge_y) - PV_HALF) < 1e-6:
                        continue               # capetele de 36 m intra in mal
                    ax_, ay_ = (1.15, 0.70) if (k + (sx > 0) + (sy > 0)) % 2 == 0 else (0.70, 1.15)
                    pts = []
                    for zz in (za, zb):
                        r = _rect_at(bot, top, z_plinth, z_cap0, zz)
                        xe = (r[0], r[1])[sx > 0]
                        ye = (r[2], r[3])[sy > 0]
                        for dx in (-sx * ax_, sx * 0.06):
                            for dy in (-sy * ay_, sy * 0.06):
                                pts.append(Vector((xe + dx, ye + dy, zz)))
                    low = zb <= PV_PATINA + 1e-6
                    _hull(mbase if low else marble, pts, CRR_MARBLE_BASE if low else CRR_MARBLE)

    # --- 4. coltarele de la capete: 9 asize alternante, pe ambele fete ----------
    n_q = 9
    hq = (corn_bot - PV_SPRING) / n_q
    for sy in (-1, 1):
        for sx in (-1, 1):
            for k in range(n_q):
                ln = 1.25 if k % 2 == 0 else 0.75
                z0 = PV_SPRING + k * hq + 0.025
                z1 = PV_SPRING + (k + 1) * hq - 0.025
                y_out = sy * PV_HALF
                y_in = sy * (PV_HALF - ln)
                marble.box((sx * (PV_FACE + 0.03), (y_out + y_in) * 0.5, (z0 + z1) * 0.5),
                           (0.10, ln, z1 - z0), CRR_MARBLE)

    # --- 6. golurile de drenaj, deasupra pilelor interioare ------------------------
    for k in range(2):
        yh = centers[k] + PV_R + PV_PIER * 0.5
        for sx in (-1, 1):
            marble.torus((sx * (PV_FACE + 0.02), yh, -2.45), 0.47, 0.09, CRR_MARBLE,
                         major_seg=12, minor_seg=4, axis="X")
            void.cylinder((sx * (PV_FACE + 0.005), yh, -2.45), 0.39, 0.04, CRR_VOID,
                          segments=12, axis="X")

    # --- 7. darele de rugina sub capiteluri -----------------------------------------
    rnd = random.Random(23)
    lean_x = (hx_bot - hx_top) / (z_cap0 - z_plinth)
    for (ya1, yb1, ya0, yb0) in piers:
        n_s = 2 if (ya1 <= -PV_HALF + 1e-6 or yb1 >= PV_HALF - 1e-6) else 3
        for sx in (-1, 1):
            for i in range(n_s):
                y = ya1 + (yb1 - ya1) * (i + 0.5 + (rnd.random() - 0.5) * 0.5) / n_s
                ln = 2.5 + rnd.random() * 3.5
                w = 0.12 + rnd.random() * 0.14
                streak(rust, (sx * hx_top, y, z_cap0 - 0.02), (sx, 0.0), (0.0, 1.0), w, ln,
                       lean=(lean_x * sx * sx, 0.0))

    # --- 9. parapetul (nod separat) ---------------------------------------------------
    for sx in (-1, 1):
        para.box((sx * 5.0, 0.0, (PV_TOP + 0.22) * 0.5), (0.60, 2 * PV_HALF, 0.22 - PV_TOP),
                 CRR_MARBLE)
        n_p = 25
        for i in range(n_p):
            y = -PV_HALF + 0.5 + (2 * PV_HALF - 1.0) * i / (n_p - 1)
            para.box((sx * 5.0, y, (0.22 + 0.83) * 0.5), (0.11, 0.11, 0.61), CRR_METAL)
        para.box((sx * 5.0, 0.0, 0.55), (0.07, 2 * PV_HALF - 0.9, 0.07), CRR_METAL)
        para.box((sx * 5.0, 0.0, 0.865), (0.08, 2 * PV_HALF - 0.9, 0.07), CRR_METAL)

    return [brick.to_object("Viaduct_Brick"), marble.to_object("Viaduct_Marble"),
            mbase.to_object("Viaduct_MarbleBase"), rust.to_object("Viaduct_Rust"),
            void.to_object("Viaduct_Void"), para.to_object("Viaduct_Parapet")]


# ---------------------------------------------------------------------------
# gallery_portal
# ---------------------------------------------------------------------------

AO_GALLERY = dict(samples=16, dist=2.4, gradient="vertical", low=0.66, high=1.0,
                  power=0.8, floor=0.40, z_range=(0.0, 15.0))

GP_HX = 9.0          # rama 18 m
GP_H = 15.0
GP_BACK = -2.65      # adancimea 3 m: spate la -2,65, fata blocurilor pana la +0,35
GP_OX = 5.2          # golul: +-5,2 (10,4 m), cu captuseala 10,34
GP_OZ = 10.9         # buiandrugul: 10,9 m (captuseala 10,87)
GP_PATINA = 5.0      # treimea de jos a fetei (15 m)
GP_JOINT = 0.09      # jumatate de rost (runda 2: rosturi de 18 cm)


def build_gallery_portal():
    """LISTA DE ELEMENTE (decuparea `gallery_portal.png`, scrisa INAINTE de
    geometrie; cotele si golul din kit §1.3):

     1. RAMA 18 x 15 x 3 m din BLOCURI MARI de marmura, taiate drept, muchii vii,
        rosturi de 0,18 m, adanci de 0,25 m (miezul se vede doar in rosturi):
          - stalpul stang: 2 blocuri (0-5 si 5-10,9 m), cel de jos pe patina;
          - stalpul drept: 2 blocuri (0-5, 5-10,9). Planșa are 3 pe dreapta;
            kitul cere 6-10 blocuri in total -> 2 (abatere notata);
          - 2 blocuri de colt inalte (10,9-15 m), ca pe planșa;
          - buiandrugul: 2 asize x 2 blocuri, cu rosturile decalate.
        Total 10 blocuri. Fiecare iese din fata cu 0-0,35 m (mase, nu plan),
        cresteturile de sus difera cu pana la 0,10 m; 4 blocuri au cate un colt
        SPART (fateta mare, runda 2). Blocurile trec prin toata adancimea, deci
        si fata de sus si laturile arata blocurile (planșa).
     2. GOLUL: dreptunghi taiat drept, 10,4 x 10,9 m (contract: >= 10,0 x 10,5
        MASURAT CA GOL; rama de beton din cod are 9,6 x 9,8 si sta in el).
     3. `Portal_Void`: captuseala neagra pe pereti si tavan, 2,0 m (de la -0,65
        la -2,65), fara podea; primii 0,65 m ai intradosului raman marmura
        luminata, ca pe planșa. In preview, un plan negru in spate.
     4. LAMPA: una, pe buiandrug, deasupra golului (`Portal_Glow` = sticla pe
        SAND_LIGHT 0, consola si capacele negre in `Portal_Void`). Planșa o
        are in interior, pe peretele din fund; kitul o cere pe buiandrug.
     5. DARE DE RUGINA: 9 fasii inguste LARCH_RUST care coboara din rosturi si
        de sub buiandrug (`Portal_Rust`); venele marmurei le da clasa.
     6. PATINA: tot ce e sub 5 m (treimea de jos) e `Portal_MarbleBase`.
     7. NU intra: molozul si bolovanii de la baza (corectura de kit), podeaua
        de dale din interior (drumul e din cod), spatele (intra in munte).
    Fata pe +Y. Noduri: Portal_Marble (19), Portal_MarbleBase (29),
    Portal_Rust (27), Portal_Glow (0), Portal_Void (20)."""
    marble, mbase, rust = Builder(), Builder(), Builder()
    glow, void = Builder(), Builder()
    j = GP_JOINT

    # --- miezul (vizibil doar in rosturi): retras 0,15 m pe fata, sus si laturi
    cx, ctop, cfront = GP_HX - 0.25, GP_H - 0.25, -0.25
    for sx in (-1, 1):
        x0, x1 = sorted((sx * cx, sx * GP_OX))
        box_split(marble, mbase, (x0, GP_BACK, 0.0), (x1, cfront, GP_PATINA + 0.0), GP_PATINA)
    upper = [(-cx, GP_PATINA), (-GP_OX, GP_PATINA), (-GP_OX, GP_OZ), (GP_OX, GP_OZ),
             (GP_OX, GP_PATINA), (cx, GP_PATINA), (cx, ctop), (-cx, ctop)]
    extrude_xz(marble, upper, GP_BACK, cfront, CRR_MARBLE)

    # --- 1. blocurile: (x0, x1, z0, z1, iesire fata) ----------------------------
    blocks = [
        (-GP_HX, -GP_OX, 0.0, 5.0, 0.10, None),            # stalp stang jos (patina)
        (-GP_HX, -GP_OX, 5.0, GP_OZ, 0.30, (-1, 1, 0.6)),  # stalp stang sus
        (GP_OX, GP_HX, 0.0, 5.0, 0.0, None),               # stalp drept jos (patina)
        (GP_OX, GP_HX, 5.0, GP_OZ, 0.22, None),            # stalp drept sus
        (-GP_HX, -5.6, GP_OZ, 15.0, 0.35, (-1, 1, 0.9)),   # colt stanga
        (5.6, GP_HX, GP_OZ, 14.92, 0.15, (1, 1, 0.5)),     # colt dreapta
        (-5.6, -0.6, GP_OZ, 13.1, 0.08, None),             # buiandrug, asiza de jos
        (-0.6, 5.6, GP_OZ, 13.1, 0.26, None),
        (-5.6, 1.9, 13.1, 14.9, 0.0, None),                # buiandrug, asiza de sus
        (1.9, 5.6, 13.1, 14.97, 0.18, (1, 1, 0.7)),
    ]
    fronts = []
    for (x0, x1, z0, z1, pr, chip) in blocks:
        # rost doar la imbinarile interioare: nu pe conturul exterior si nu in gol
        xa = x0 + (j if x0 > -GP_HX + 1e-6 and abs(x0 - GP_OX) > 1e-6 else 0.0)
        xb = x1 - (j if x1 < GP_HX - 1e-6 and abs(x1 + GP_OX) > 1e-6 else 0.0)
        spans_gap = x0 < -GP_OX + 1e-6 and x1 > GP_OX - 1e-6 or (x0 < GP_OX and x1 > -GP_OX)
        za = z0 + (j if z0 > 1e-6 and not (abs(z0 - GP_OZ) < 1e-6 and spans_gap) else 0.0)
        zb = z1 - (j if z1 < 14.0 else 0.0)
        if chip and za >= GP_PATINA:
            # colt SPART (planșa: blocuri ciobite pe muchii): coltul din fata
            # (sx, sz) inlocuit de o fateta mare, taiata drept
            csx, csz, c = chip
            xc = xb if csx > 0 else xa
            zc = zb if csz > 0 else za
            pts = []
            for x in (xa, xb):
                for y in (GP_BACK, pr):
                    for z in (za, zb):
                        if y == pr and x == xc and z == zc:
                            pts += [Vector((x - csx * c, y, z)), Vector((x, y, z - csz * c)),
                                    Vector((x, y - c, z))]
                        else:
                            pts.append(Vector((x, y, z)))
            _hull(marble, pts, CRR_MARBLE)
        else:
            box_split(marble, mbase, (xa, GP_BACK, za), (xb, pr, zb), GP_PATINA)
        fronts.append((xa, xb, za, zb, pr))

    # --- 3. captuseala de umbra: 2,0 m, fara podea --------------------------------
    mouth = [(-GP_OX, 0.0), (-GP_OX, GP_OZ), (GP_OX, GP_OZ), (GP_OX, 0.0)]
    tube_lining(void, mouth, GP_BACK, -0.65 + 0.02, 0.0, inset=0.03, slot=CRR_VOID)

    # --- 4. lampa pe buiandrug (blocul de la x = 0 iese 0,16) ----------------------
    yf = 0.26
    void.box((0.0, yf + 0.20, 12.62), (0.10, 0.40, 0.08), CRR_VOID)        # consola
    void.box((0.0, yf + 0.45, 12.55), (0.50, 0.50, 0.08), CRR_VOID)        # capac sus
    void.box((0.0, yf + 0.45, 11.97), (0.44, 0.44, 0.06), CRR_VOID)        # capac jos
    void.box((0.0, yf + 0.45, 12.70), (0.16, 0.16, 0.12), CRR_VOID)        # cos
    glow.box((0.0, yf + 0.45, 12.26), (0.36, 0.36, 0.52), CRR_GLOW)       # sticla
    void.box((0.0, yf + 0.03, 12.30), (0.30, 0.06, 0.70), CRR_VOID)        # placa de prindere

    # --- 5. darele de rugina: (bloc, x relativ 0..1, z sus, lungime, latime) -------
    streaks = [(1, 0.30, GP_OZ - 0.10, 3.2, 0.22), (1, 0.75, GP_OZ - 0.10, 2.0, 0.14),
               (3, 0.20, GP_OZ - 0.10, 2.6, 0.18), (3, 0.65, 8.0, 1.8, 0.12),
               (6, 0.15, 13.0, 1.5, 0.16), (7, 0.55, 13.0, 1.7, 0.20),
               (4, 0.55, 14.9, 3.4, 0.24), (5, 0.40, 14.8, 2.6, 0.16),
               (9, 0.70, 14.9, 1.4, 0.14)]
    for (bi, fx, zt, ln, w) in streaks:
        xa, xb, za, zb, pr = fronts[bi]
        x = xa + (xb - xa) * fx
        zt = min(zt, zb - 0.02)
        ln = min(ln, zt - za - 0.05)
        streak(rust, (x, pr, zt), (0.0, 1.0), (1.0, 0.0), w, ln)

    return [marble.to_object("Portal_Marble"), mbase.to_object("Portal_MarbleBase"),
            rust.to_object("Portal_Rust"), glow.to_object("Portal_Glow"),
            to_obj(void, "Portal_Void")]


# ---------------------------------------------------------------------------
# marmifera_portal
# ---------------------------------------------------------------------------

AO_MARMIFERA = dict(samples=16, dist=2.0, gradient="vertical", low=0.64, high=1.0,
                    power=0.8, floor=0.40, z_range=(0.0, 11.0))

MP_W0 = 7.0           # jumatatea latimii la baza (14 m)
MP_BATTER = 0.055     # cat se strange fiecare latura pe metru de inaltime
MP_H = 11.0
MP_BACK = -2.3        # adancimea 2,5 m: spate la -2,3, fata pietrelor pana la ~+0,2
MP_R = 5.5            # intradosul arcului (golul 11,0 m; captuseala 10,94)
MP_ZS = 4.2           # nasterea arcului
MP_RING = 0.70        # bolțarii (extradosul la 6,2 m: cheia inelului la 10,4)
MP_COPE = 10.40       # coronamentul (asiza de sus) incepe aici
MP_SEG = 16
MP_CROWN_HX = 4.6     # coronamentul ridicat are |x| <= 4,6 (2/3 din latime, ca pe planșa)
MP_SH_Z = 8.6         # umerii coboara pana aici la margine (runda 2)


def _mp_top(x):
    """Linia de sus a fruntarului: plata la 10,4 pe |x| <= 4,6, apoi umeri in
    panta pana la 8,6 pe latura (planșa: umeri inclinati sub coronament)."""
    ax = abs(x)
    if ax <= MP_CROWN_HX:
        return MP_COPE
    xe = _mp_w(MP_SH_Z)
    return MP_COPE - (ax - MP_CROWN_HX) * (MP_COPE - MP_SH_Z) / (xe - MP_CROWN_HX)


def _mp_w(z):
    return MP_W0 - MP_BATTER * z


def _poly_area(pts):
    return 0.5 * sum(pts[i][0] * pts[(i + 1) % len(pts)][1] -
                     pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))


def _simplify(pts, eps=1e-4):
    """Scoate punctele duble si pe cele coliniare (muchiile drepte esantionate)."""
    pts = list(pts)
    changed = True
    while changed and len(pts) > 3:
        changed = False
        for i in range(len(pts)):
            a, b, c = pts[i - 1], pts[i], pts[(i + 1) % len(pts)]
            cr = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
            if abs(cr) < eps or abs(a[0] - b[0]) + abs(a[1] - b[1]) < 0.01:
                pts.pop(i)
                changed = True
                break
    return pts


def _mp_stone_outline(rect, ro, above):
    """Conturul unei pietre de fata = dreptunghiul `rect` (x0, x1, z0, z1)
    TAIAT: pe laturi de linia teșita |x| <= w(z); sub nastere (`above` False) de
    gol (|x| >= R, taietura dreapta); peste nastere de discul inelului de
    bolțari (raza `ro`, centrul in (0, zs)), cu arcul inlocuind bucata de contur
    din disc. Intoarce lista (x, z) ANTIORAR, fara puncte coliniare, sau []."""
    x0, x1, z0, z1 = rect
    if not above:
        # sub nastere golul e o banda dreapta |x| < R: taietura la nivel de
        # dreptunghi (o piatra de 1,7 m nu poate incaleca ambele margini)
        if x1 <= -MP_R or x0 >= MP_R:
            pass
        elif x0 < -MP_R < x1:
            x1 = -MP_R
        elif x0 < MP_R < x1:
            x0 = MP_R
        else:
            return []
    N = 12
    ring = []
    for (ax, az, bx, bz) in ((x0, z0, x1, z0), (x1, z0, x1, z1),
                             (x1, z1, x0, z1), (x0, z1, x0, z0)):
        for t in range(N):
            s = t / float(N)
            ring.append((ax + (bx - ax) * s, az + (bz - az) * s))
    out = []
    for x, z in ring:
        w = _mp_w(z)
        x = max(-w, min(w, x))
        out.append((x, min(z, _mp_top(x))))
    ring = out
    if above:
        def inside(p):
            return math.hypot(p[0], p[1] - MP_ZS) < ro

        def cross(po, pi_):
            lo, hi = po, pi_          # lo afara, hi inauntru
            for _ in range(40):
                m = ((lo[0] + hi[0]) * 0.5, (lo[1] + hi[1]) * 0.5)
                if inside(m):
                    hi = m
                else:
                    lo = m
            return lo

        n = len(ring)
        ins = [inside(p) for p in ring]
        if all(ins):
            return []
        if any(ins):
            k = ins.index(False)
            ring = ring[k:] + ring[:k]
            ins = ins[k:] + ins[:k]
            res = []
            i = 0
            while i < n:
                if not ins[i]:
                    res.append(ring[i])
                    i += 1
                    continue
                jj = i
                while jj < n and ins[jj]:
                    jj += 1
                e = cross(ring[i - 1], ring[i])
                x_ = cross(ring[jj % n], ring[jj - 1])
                ae = math.atan2(e[1] - MP_ZS, e[0])
                ax_ = math.atan2(x_[1] - MP_ZS, x_[0])
                d = ax_ - ae
                while d > math.pi:
                    d -= 2 * math.pi
                while d < -math.pi:
                    d += 2 * math.pi
                m = max(2, int(abs(d) / (math.pi / 16)) + 1)
                for t in range(m + 1):
                    a = ae + d * t / m
                    res.append((ro * math.cos(a), MP_ZS + ro * math.sin(a)))
                i = jj
            ring = res
    pts = _simplify(ring)
    if len(pts) < 3 or abs(_poly_area(pts)) < 0.15:
        return []
    xs_ = [p[0] for p in pts]
    zs_ = [p[1] for p in pts]
    if max(xs_) - min(xs_) < 0.25 or max(zs_) - min(zs_) < 0.2:
        return []
    if _poly_area(pts) < 0:
        pts.reverse()
    return pts


def build_marmifera_portal():
    """LISTA DE ELEMENTE (decuparea `marmifera_portal.png`, scrisa INAINTE de
    geometrie; cotele si golul din kit §1.3):

     1. ARC in plin cintru, R 5,5 m (golul 11,0 m), nasterea la 4,2 m, din 15
        BOLȚARI (cheia la mijloc, mai mare si mai iesita); planșa are ~13 + cheia.
        Contractul (>= 10 m pe 0-6 m, cheia >= 8,5) coboara nasterea la 4,2 m:
        pe planșa arcul se naste la ~3/4 din inaltimea golului (abatere voita).
     2. FRUNTAR de piatra bruta: asize de pietre dreptunghiulare (0,5-0,65 m
        inalte, 0,7-1,3 m lungi, rosturi alternate), fiecare iesita 0-0,10 m si
        cu fata BOMBATA (evantai, +0,015..0,04 m); pietrele de langa arc sunt
        taiate dupa extradosul lui (muscatura concava), cele de sub nastere
        formeaza stalpii. Laturile se strang spre varf (14 m jos, ~12,8 sus),
        ca pe planșa unde fruntarul se evazeaza la baza.
     3. CORONAMENT: o asiza de pietre mari pe |x| <= 4,6 (2/3 din latime), pe
        toata adancimea, cu cresteturi neregulate intre 10,75 si 11,0 m; UMERII
        coboara in panta de la 10,4 la 8,6 m spre laturi, cu cate 2 pietre de
        cap in trepte (planșa: blocul de sus mai ingust, umeri inclinati).
     4. MUSCHI (`Portal_Moss`, TROPICAL_GREEN 21): pete plate pe pietrele de
        sus si de pe laturi, pe colturile de jos si pe coronament / umeri. Pete
        de culoare, nu masa.
     5. SINE: doua sine (`Portal_Rail`, PAINTED_METAL 11) cu ecartament normal,
        de la 5 m in fata pana in spatele portalului, pe traverse de lemn
        (WOOD 9) la 0,65 m; 7 cm peste drum (integrarea le poate taia).
     6. `Portal_Void`: captuseala neagra a intradosului, 2,0 m (de la -0,3 la
        -2,3), fara podea. In preview, un plan negru in spate.
     7. LAMPA: una, in tunel, atarnata de intrados la dreapta cheii (x 2,2,
        y -1,3), cu baza la 8,62 m (> 8,5, nu intra in gol): sticla in
        `Portal_Glow` (SAND_LIGHT 0), feroneria in `Portal_Void`. Planșa o are
        pe peretele din dreapta, mai jos (abatere: acolo ar intra in gol).
     8. NU intra: tufele si bolovanii lipiti (corectura de kit), asfaltul.
    Fata pe +Y. Noduri: Portal_Stone (MARBLE_GREY 29, clasa tf_stone),
    Portal_Moss (21), Portal_Rail (11 + 9), Portal_Glow (0), Portal_Void (20)."""
    stone, moss, rail = Builder(), Builder(), Builder()
    glow, void = Builder(), Builder()
    rnd = random.Random(29)
    ro = MP_R + MP_RING

    # --- miezul: fruntarul cu golul arcuit, retras 0,12 m in spatele pietrelor --------
    arc = [(MP_R * math.cos(math.pi - math.pi * k / MP_SEG),
            MP_ZS + MP_R * math.sin(math.pi - math.pi * k / MP_SEG)) for k in range(MP_SEG + 1)]
    core = ([(-MP_W0, 0.0), (-MP_R, 0.0)] + arc + [(MP_R, 0.0), (MP_W0, 0.0),
            (_mp_w(MP_SH_Z), MP_SH_Z), (MP_CROWN_HX, MP_COPE),
            (-MP_CROWN_HX, MP_COPE), (-_mp_w(MP_SH_Z), MP_SH_Z)])
    extrude_xz(stone, core, MP_BACK, -0.12, CRR_STONE)

    # --- 1. bolțarii: 15, cheia mai mare -------------------------------------------------
    n_v = 15
    dg = 0.06 / MP_R
    for k in range(n_v):
        a0 = math.pi * k / n_v + dg * 0.5
        a1 = math.pi * (k + 1) / n_v - dg * 0.5
        key = (k == n_v // 2)
        r_out = MP_R + (MP_RING + 0.20 if key else MP_RING)
        y_f = 0.22 if key else 0.12 + rnd.random() * 0.05
        pts = []
        for a in (a0, a1):
            for r in (MP_R, r_out):
                for y in (-0.40, y_f):
                    pts.append(Vector((r * math.cos(a), y, MP_ZS + r * math.sin(a))))
        _hull(stone, pts, CRR_STONE)

    # --- 2. pietrele fruntarului + 4. petele de muschi ----------------------------------
    def moss_patch(cx, cz, rx, rz, y, seed):
        rr = random.Random(seed)
        n = 7
        pts = []
        for i in range(n):
            a = 2 * math.pi * i / n + rr.random() * 0.4
            k = 0.7 + rr.random() * 0.3
            pts.append((cx + math.cos(a) * rx * k, cz + math.sin(a) * rz * k))
        extrude_poly_xz(moss, pts, y - 0.01, y + 0.015, CRR_MOSS)

    # randurile: 6 asize de 0,70 m pana la nastere (4,2 m), apoi 0,65-0,85 m
    rows = [(k * 0.60, (k + 1) * 0.60, False) for k in range(7)]
    z = MP_ZS
    while z < MP_COPE - 0.01:
        z1 = min(z + 0.50 + rnd.random() * 0.15, MP_COPE)
        if MP_COPE - z1 < 0.35:
            z1 = MP_COPE
        rows.append((z, z1, True))
        z = z1
    moss_seed = 500
    n_stones = 0
    for row, (z0, z1, above) in enumerate(rows):
        x = -MP_W0 - 0.3 - (0.55 if row % 2 else 0.0)
        while x < MP_W0:
            x1 = x + 0.7 + rnd.random() * 0.6
            rect = (x + 0.03, x1 - 0.03, z0 + 0.03, z1 - 0.03)
            x = x1
            pts = _mp_stone_outline(rect, ro + 0.03, above)
            if not pts:
                continue
            n_stones += 1
            plain = (len(pts) == 4 and abs(abs(_poly_area(pts)) -
                     (rect[1] - rect[0]) * (rect[3] - rect[2])) < 1e-4)
            if not plain:
                # taiata de arc / latura / gol: fata plana
                extrude_poly_xz(stone, pts, -0.35, 0.02 + rnd.random() * 0.06, CRR_STONE)
                continue
            y_f = rnd.random() * 0.10
            cxm = (rect[0] + rect[1]) * 0.5
            czm = (rect[2] + rect[3]) * 0.5
            want_moss = ((abs(cxm) > 3.0 and czm > 7.6) or (abs(cxm) > 5.8 and czm < 2.2)
                         or (abs(cxm) > 5.9 and 3.5 < czm < 7.0))
            if want_moss and rnd.random() < 0.75:
                extrude_poly_xz(stone, pts, -0.35, y_f, CRR_STONE)
                moss_patch(cxm + (rnd.random() - 0.5) * 0.2, czm - 0.05,
                           (rect[1] - rect[0]) * 0.44, (rect[3] - rect[2]) * 0.42,
                           y_f + 0.01, moss_seed)
                moss_seed += 1
            else:
                extrude_poly_xz(stone, pts, -0.35, y_f, CRR_STONE,
                                bulge=0.015 + rnd.random() * 0.025)
    print("marmifera_portal: %d pietre de fata, %d pete de muschi pe fata" % (n_stones, moss_seed - 500))

    # --- 3. coronamentul: pe |x| <= 4,6, pe toata adancimea, cresteturi neregulate;
    # pe umeri, cate 2 pietre de cap in trepte care urmaresc panta ------------------
    x = -MP_CROWN_HX
    tops = []
    while x < MP_CROWN_HX - 0.3:
        x1 = min(x + 1.2 + rnd.random() * 0.8, MP_CROWN_HX)
        if MP_CROWN_HX - x1 < 0.6:
            x1 = MP_CROWN_HX
        zt = 10.75 + rnd.random() * 0.25
        y_f = 0.06 + rnd.random() * 0.10
        xa = x + (0.03 if x > -MP_CROWN_HX + 1e-6 else 0.0)
        xb = x1 - (0.03 if x1 < MP_CROWN_HX - 1e-6 else 0.0)
        extrude_poly_xz(stone, [(xa, MP_COPE), (xb, MP_COPE), (xb, zt), (xa, zt)],
                        MP_BACK, y_f, CRR_STONE)
        tops.append((xa, xb, zt))
        x = x1
    xe = _mp_w(MP_SH_Z)
    for sx in (-1, 1):
        n_sh = 2
        for k in range(n_sh):
            u0 = MP_CROWN_HX + (xe - MP_CROWN_HX) * k / n_sh + (0.03 if k else 0.0)
            u1 = MP_CROWN_HX + (xe - MP_CROWN_HX) * (k + 1) / n_sh - (0.03 if k < n_sh - 1 else 0.0)
            ztop = _mp_top(u0) + 0.32 + rnd.random() * 0.08
            u1t = min(u1, _mp_w(ztop))
            pts = [(u0, _mp_top(u0)), (u1, _mp_top(u1)), (u1t, ztop), (u0, ztop)]
            if sx < 0:
                pts = [(-p[0], p[1]) for p in reversed(pts)]
            extrude_poly_xz(stone, pts, MP_BACK, 0.10 + rnd.random() * 0.06, CRR_STONE)
            xa, xb = sorted((sx * u0, sx * u1t))
            tops.append((xa, xb, ztop))
    # muschi pe coronament (pete orizontale)
    for i, (xa, xb, zt) in enumerate(tops):
        if i % 2 == 0 or abs((xa + xb) * 0.5) > 3.5:
            rr = random.Random(700 + i)
            cxm = (xa + xb) * 0.5 + (rr.random() - 0.5) * 0.3
            cym = -0.4 - rr.random() * 1.2
            n = 7
            pts = []
            for k in range(n):
                a = 2 * math.pi * k / n + rr.random() * 0.4
                kk = 0.7 + rr.random() * 0.3
                pts.append(Vector((cxm + math.cos(a) * (xb - xa) * 0.36 * kk,
                                   cym + math.sin(a) * 0.55 * kk, zt - 0.01)))
            pts += [Vector((p.x, p.y, zt + 0.015)) for p in pts]
            _hull(moss, pts, CRR_MOSS)

    # --- 6. captuseala: 2,0 m, fara podea -------------------------------------------------
    mouth = [(-MP_R, 0.0)] + arc + [(MP_R, 0.0)]
    tube_lining(void, mouth, MP_BACK, -0.30 + 0.02, 0.0, inset=0.03, slot=CRR_VOID)

    # --- 7. lampa atarnata de intrados -----------------------------------------------------
    lx, ly = 2.2, -1.3
    z_in = MP_ZS + math.sqrt((MP_R - 0.03) ** 2 - lx * lx)
    void.box((lx, ly, (z_in + 0.10 + 8.95) * 0.5), (0.05, 0.05, z_in + 0.10 - 8.95), CRR_VOID)
    void.box((lx, ly, 8.94), (0.30, 0.30, 0.06), CRR_VOID)
    void.box((lx, ly, 8.65), (0.26, 0.26, 0.05), CRR_VOID)
    glow.box((lx, ly, 8.79), (0.22, 0.22, 0.26), CRR_GLOW)

    # --- 5. sinele si traversele ---------------------------------------------------------------
    y_r0, y_r1 = MP_BACK, 5.0
    for sx in (-1, 1):
        rail.box((sx * 0.7535, (y_r0 + y_r1) * 0.5, 0.045), (0.07, y_r1 - y_r0, 0.05), CRR_METAL)
    ys = MP_BACK + 0.3
    while ys < y_r1 - 0.1:
        rail.box((0.0, ys, 0.01), (2.4, 0.24, 0.02), CRR_WOOD)
        ys += 0.65

    return [stone.to_object("Portal_Stone"), moss.to_object("Portal_Moss"),
            rail.to_object("Portal_Rail"), glow.to_object("Portal_Glow"),
            to_obj(void, "Portal_Void")]


# ---------------------------------------------------------------------------

clear_built()
if not ONLY or ONLY == "ponti_di_vara":
    emit_fixed(build_ponti_di_vara(), "structures/ponti_di_vara.glb", AO_VIADUCT)
    clear_built()
if not ONLY or ONLY == "gallery_portal":
    emit_fixed(build_gallery_portal(), "structures/gallery_portal.glb", AO_GALLERY)
    clear_built()
if not ONLY or ONLY == "marmifera_portal":
    emit_fixed(build_marmifera_portal(), "structures/marmifera_portal.glb", AO_MARMIFERA)
    clear_built()
report_crr()
