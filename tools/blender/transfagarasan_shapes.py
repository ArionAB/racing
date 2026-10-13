"""Vocabular de forme pentru kitul Transfagarasan (Track21).

Contract: docs/asset_briefs/transfagarasan_kit.md. Lectia Okinawa/Monument
Valley: fara vocabular comun, fiecare constructor reinventeaza forma din cutii.
Pe pilot (tunnel_portal_balea) s-au scris DOAR formele folosite de portal; cele
care vin in valul 1 sunt stub-uri cu contractul in docstring (NU au corp: ridica
NotImplementedError, ca sa nu le foloseasca nimeni pe nevazute).

FOLOSITE (pilot):
  ring_stack       masa inchisa din inele de puncte 3D (acelasi numar de puncte
                   pe inel). Doua inele consecutive la ACEEASI cota = un prag
                   orizontal (treapta). Baza pentru `snow_layers`.
  snow_layers      peretele de zapada veche: 4 straturi cu trepte de 0,3 m pe
                   fetele taiate de plug (+-Y), dungi de praf (nod separat),
                   muchia de sus rotunjita si ondulata, baza murdara. Va fi
                   refolosit de `snow_wall` (valul 1) cu alti parametri.
  segmental_arch   punctele unui arc turtit (segmental) prin doua capete si o
                   sageata, stanga -> dreapta.
  extrude_xz       prisma dintr-un contur in planul XZ (poate fi concav), pe Y.
  prism_yz         prisma dintr-un profil in planul YZ, extrudata pe X (contrafort).
  arch_band        rama plata a unei guri cu arc (latime constanta pe arc).
  mouth_lining     captuseala de umbra pe peretii/tavanul gurii: banda fara capace,
                   cu normalele spre interiorul golului.
  concrete_cornice cornisa in doua trepte (filet + placa), iesita pe fata si spate.
  emit_tf          finish pe fiecare nod + export in assets/models/transfagarasan/.

STUB-URI (valul 1, vezi docstring-urile):
  schist_blade, dry_stone_wall, tin_roof

Se incarca cu exec, dupa dio_lib (vezi build_tf_*.py). Axe: X latime, Y adancime
(fata spre +Y in Blender = -Z in Godot), Z sus. Reutilizeaza `_face`, `to_obj`
din monument_shapes.py.
"""

import math
from mathutils import Vector, Matrix

_here_tf = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_tf, "monument_shapes.py")).read())

# --- sloturile pe roluri (kit §0, tabelul de sloturi) ------------------------
TF_SCHIST = MARBLE_GREY        # 29: *_Schist (clasa tf_schist la integrare)
TF_SNOW = FOAM_WHITE           # 22: *_Snow (clasa snow)
TF_DUST = CONCRETE             # 8:  dungile de praf pe zapada (nod *_Dust)
TF_CONCRETE = CONCRETE         # 8:  *_Concrete (clasa concrete)
TF_VOID = VOLCANIC_BLACK       # 20: goluri, captuseala de umbra a gurii
TF_RED = KERB_RED              # 7:  dungi rosii
TF_WHITE = FOAM_WHITE          # 22: campuri albe


def _wob(a, b, seed=0.0):
    """Zgomot determinist in [-1, 1] din doua coordonate (fara RNG consumat)."""
    return (math.sin(a * 2.31 + b * 1.17 + seed) * 0.6
            + math.sin(a * 5.07 - b * 3.33 + seed * 1.7) * 0.4)


# ---------------------------------------------------------------------------
# mase din inele
# ---------------------------------------------------------------------------

def ring_stack(b, rings, slot, cap_bottom=True, cap_top=True):
    """Masa inchisa din `rings` = lista de inele, fiecare o lista de puncte 3D
    (x, y, z), toate cu ACELASI numar de puncte, in ordine ANTIORARA vazut de
    sus. Fetele laterale sunt dintre inele consecutive; doua inele la aceeasi
    cota dau un prag orizontal. Vertecsii inelului sunt PARTAJATI (umbrire
    neteda pe curbe; muchiile drepte raman ascutite prin apply_smooth)."""
    vr = [[b.bm.verts.new(p) for p in ring] for ring in rings]
    n = len(vr[0])
    for k in range(len(vr) - 1):
        for i in range(n):
            j = (i + 1) % n
            f = b.bm.faces.new((vr[k][i], vr[k][j], vr[k + 1][j], vr[k + 1][i]))
            f[b.slot] = slot
    if cap_top:
        f = b.bm.faces.new(vr[-1])
        f[b.slot] = slot
    if cap_bottom:
        f = b.bm.faces.new(list(reversed(vr[0])))
        f[b.slot] = slot
    return vr


def _snow_poly(sx, x_in, x_out, half_len, cut):
    """Conturul in plan al unui strat de zapada, ANTIORAR. Pe partea sx=+1 peretele
    portalului e la x_in, spre exterior pana la x_out; pe sx=-1 oglindit.
    Colturile exterioare sunt tesite cu `cut` (rotunjire topita)."""
    pts = [(x_in, -half_len), (x_out - cut, -half_len), (x_out, -half_len + cut),
           (x_out, half_len - cut), (x_out - cut, half_len), (x_in, half_len)]
    if sx < 0:
        pts = [(-x, y) for x, y in reversed(pts)]
    return pts


# profilul unui perete de zapada: (cota, avans_exterior_m, semilungime_m) pe
# inelele din cate DOUA per strat (jos / sus), cu PRAG intre straturi (treapta
# 0,3 m, si pe exterior, si pe fetele taiate +-Y); apoi doua inele de topire.
SNOW_PROFILE = [
    # strat 0 (baza murdara), 0 -> 1,0
    (0.00, 6.00, 4.00), (1.00, 5.85, 3.95),
    # strat 1, 1,0 -> 2,0 (treapta de 0,3 m)
    (1.00, 5.55, 3.65), (2.00, 5.25, 3.60),
    # strat 2, 2,0 -> 3,0
    (2.00, 4.95, 3.30), (3.00, 4.40, 3.25),
    # strat 3, 3,0 -> 3,7
    (3.00, 4.10, 2.95), (3.70, 3.60, 2.90),
    # topirea: muchia de sus rotunjita (doua inele)
    (3.90, 3.00, 2.65), (4.00, 2.20, 2.30),
]
SNOW_LAYER_STARTS = (0, 2, 4, 6)   # indicii inelelor "jos" ale celor 4 straturi


def snow_layers(snow, dust, sx, x_in, height=4.0, profile=None, cut=0.9,
                seed=0.0, melt=0.12):
    """Peretele de zapada veche lipit de un zid vertical (portal), pe partea `sx`.

    Contractul (kit corectura `snow_wall`): 3-4 straturi orizontale vizibile ca
    FORMA (trepte de 0,2-0,4 m pe fata taiata de plug, +-Y), dungi de praf pe
    fetele spre drum (`dust`, nod separat, slot CONCRETE), muchia de sus
    rotunjita si ondulata (topita), baza murdara (banda de praf mai groasa).
    Simetric fata-spate: ondularea e functie de |y|.

    `snow`, `dust` = Builder-e. `x_in` = fata zidului (|x|); masa intra 0,1 m
    in zid ca sa nu apara rost. `profile` = lista (z, avans_exterior, semilungime).
    Returneaza (x_out_la_baza, z_sus)."""
    profile = profile or SNOW_PROFILE
    inner = x_in - 0.10
    rings = []
    for k, (z, adv, hl) in enumerate(profile):
        x_out = x_in + adv
        poly = _snow_poly(sx, inner, x_out, hl, cut * max(0.45, min(1.0, adv / 5.0)))
        ring = []
        for (x, y) in poly:
            zz = z
            top = k >= len(profile) - 2
            if top and abs(x) > x_in + 0.2:
                # creasta topita: ondulare simetrica fata-spate (functie de |y|)
                zz = z + melt * _wob(x, abs(y), seed) * (1.0 if k == len(profile) - 1 else 0.5)
            ring.append((x, y, zz))
        rings.append(ring)
    ring_stack(snow, rings, TF_SNOW)

    # --- dungile de praf pe fetele taiate (+-Y), la baza fiecarui strat --------
    def x_range(z):
        for (z0, a0, l0), (z1, a1, l1) in zip(profile, profile[1:]):
            if z0 <= z <= z1 and z1 > z0:
                t = (z - z0) / (z1 - z0)
                return x_in + a0 + (a1 - a0) * t - cut, l0 + (l1 - l0) * t
        return x_in + profile[-1][1] - cut, profile[-1][2]

    for li, ri in enumerate(SNOW_LAYER_STARTS):
        z0 = profile[ri][0]
        stripes = [(z0 + 0.02, 0.45 if li == 0 else 0.16, 1.0)]
        if li in (1, 3):
            stripes.append((z0 + 0.52, 0.08, 0.6))
        for (zb, hh, frac) in stripes:
            xe, hl = x_range(zb + hh * 0.5)
            x0 = inner + 0.15
            w = (xe - x0) * frac
            for sy in (-1, 1):
                yc = sy * (hl - 0.01)
                xc = (x0 + x0 + w) * 0.5 * sx
                dust.box((xc, yc, zb + hh * 0.5), (w, 0.10, hh), TF_DUST)
    return x_in + profile[0][1], profile[-1][0]


# ---------------------------------------------------------------------------
# beton: arc, prisme, rama, cornisa, contrafort, captuseala
# ---------------------------------------------------------------------------

def segmental_arch(half_span, spring_z, rise, n=10):
    """Puncte (x, z) ale unui arc turtit (segmental): de la (-half_span, spring_z)
    la (+half_span, spring_z), cu sageata `rise` la mijloc, in n segmente.
    Intoarce (puncte, raza, z_centru)."""
    R = (half_span * half_span + rise * rise) / (2.0 * rise)
    zc = spring_z + rise - R
    th0 = math.asin(half_span / R)
    pts = []
    for i in range(n + 1):
        th = -th0 + 2.0 * th0 * i / n
        pts.append((R * math.sin(th), zc + R * math.cos(th)))
    return pts, R, zc


def extrude_xz(b, outline, y0, y1, slot):
    """Prisma dintr-un contur (x, z) ANTIORAR (axa X spre dreapta, Z in sus),
    extrudata intre y0 si y1. Conturul poate fi CONCAV (ex. fatada cu gura);
    fetele de capat sunt n-gon-uri, triangulate la export. Normalele se
    recalculeaza pe obiect (`Builder.to_object`) — piesa e o carcasa inchisa."""
    n = len(outline)
    fr = [b.bm.verts.new((x, y1, z)) for x, z in outline]
    bk = [b.bm.verts.new((x, y0, z)) for x, z in outline]
    for ring, rev in ((fr, True), (bk, False)):   # CCW in XZ => normala -Y
        f = b.bm.faces.new(list(reversed(ring)) if rev else ring)
        f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((fr[i], fr[j], bk[j], bk[i]))
        f[b.slot] = slot


def prism_yz(b, poly_yz, x0, x1, slot):
    """Prisma dintr-un profil (y, z) CONVEX, extrudata intre x0 si x1 (contrafort
    cu capat in panta)."""
    n = len(poly_yz)
    lo = [b.bm.verts.new((x0, y, z)) for y, z in poly_yz]
    hi = [b.bm.verts.new((x1, y, z)) for y, z in poly_yz]
    for ring in (lo, list(reversed(hi))):
        f = b.bm.faces.new(ring)
        f[b.slot] = slot
    for i in range(n):
        j = (i + 1) % n
        f = b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        f[b.slot] = slot


def concrete_cornice(b, hx, y_body, z0, z1, slot=TF_CONCRETE):
    """Cornisa in doua trepte: filet (z0 -> z0+35%) iesit 0,18 si placa
    (restul) iesita 0,38, pe toata latimea 2*hx, FARA sa iasa in X (fetele laterale
    raman in planul zidului, ca zapada sa se lipeasca curat)."""
    zm = z0 + (z1 - z0) * 0.38
    b.box((0.0, 0.0, (z0 + zm) * 0.5), (2 * hx, 2 * (y_body + 0.18), zm - z0), slot)
    b.box((0.0, 0.0, (zm + z1) * 0.5), (2 * hx, 2 * (y_body + 0.38), z1 - zm), slot)


def arch_band(b, jamb_x, spring_z, rise, width, y_face, depth, n=10, slot=TF_CONCRETE):
    """Rama plata (iesita `depth` m) in jurul unei guri cu arc turtit, cu
    latimea `width` pe tot conturul (jamburi + arc), pe fata y_face (>0: fata,
    <0: spate; grosimea creste spre exterior). Conturul = bucla jos-stanga ->
    sus pe jamb -> arc -> jos pe jamb dreapta, apoi inapoi pe exterior."""
    inner, R, zc = segmental_arch(jamb_x, spring_z, rise, n)
    outer = []
    for (x, z) in inner:
        dx, dz = x, z - zc
        L = math.hypot(dx, dz)
        outer.append((x + dx / L * width, z + dz / L * width))
    jx = jamb_x + width
    # inner: (-jx0,0) sus (arc...) (jx0,0); outer in sens invers
    pts = [(-jamb_x, 0.0)] + inner + [(jamb_x, 0.0), (jx, 0.0), (jx, spring_z)] \
        + list(reversed(outer)) + [(-jx, spring_z), (-jx, 0.0)]
    # conturul nu e antiorar in aceasta ordine: il intoarcem
    area = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
               for i in range(len(pts)))
    if area < 0:
        pts = list(reversed(pts))
    if y_face > 0:
        extrude_xz(b, pts, y_face, y_face + depth, slot)
    else:
        extrude_xz(b, pts, y_face - depth, y_face, slot)


def mouth_lining(b, jamb_x, spring_z, rise, y_half, inset=0.03, n=10, slot=TF_VOID):
    """Captuseala de umbra pe peretii si tavanul gurii: o banda FARA capace,
    de-a lungul jamb stang -> arc -> jamb drept, pe y in [-y_half, y_half], retrasa
    `inset` spre interior fata de reveniri (ca sa nu faca z-fighting cu betonul).
    Normalele spre INTERIORUL golului. NU inchide golul: stransa doar cu `inset`
    pe parte, la masurarea golului intra in cifra."""
    arc, R, zc = segmental_arch(jamb_x, spring_z, rise, n)
    path = [(-jamb_x, 0.0)] + arc + [(jamb_x, 0.0)]
    # retragere spre interior: jamburile pe x, arcul pe raza
    shifted = []
    for i, (x, z) in enumerate(path):
        if i == 0:
            shifted.append((x + inset, z))
        elif i == len(path) - 1:
            shifted.append((x - inset, z))
        else:
            dx, dz = x, z - zc
            L = math.hypot(dx, dz)
            shifted.append((x - dx / L * inset, z - dz / L * inset))
    centre = Vector((0.0, 0.0, spring_z * 0.5))
    for i in range(len(shifted) - 1):
        (x0, z0), (x1, z1) = shifted[i], shifted[i + 1]
        vs = [(x0, -y_half, z0), (x1, -y_half, z1), (x1, y_half, z1), (x0, y_half, z0)]
        f = b.bm.faces.new([b.bm.verts.new(p) for p in vs])
        f.normal_update()
        mid = Vector(((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5))
        if f.normal.dot(centre - mid) < 0:
            f.normal_flip()
        f[b.slot] = slot


# ---------------------------------------------------------------------------
# STUB-URI (valul 1) -- contractul din kit; fara corp pana le foloseste cineva
# ---------------------------------------------------------------------------

def schist_blade(b, *args, **kw):
    """STUB (tf-b, `schist_outcrop_*`, `scree_cone`): lama de sist inclinata la
    30-50 grade, toate in ACEEASI directie pe o piesa; fisura inchisa dintre lame
    din geometrie + AO (slot VOLCANIC_BLACK in benzi inguste, NU ROCK_DARK)."""
    raise NotImplementedError("schist_blade: valul 1 (tf-b)")


def dry_stone_wall(b, *args, **kw):
    """STUB (tf-a, `retaining_wall_*`): zid de piatra uscata cu talus ~10 grade pe
    fata spre vale, 7-9 pietre individuale DOAR pe randul de sus, masa cu fete mari
    in rest, creasta plana la cota 0, capete plane la +-L/2 (inlantuibil)."""
    raise NotImplementedError("dry_stone_wall: valul 1 (tf-a)")


def tin_roof(b, *args, **kw):
    """STUB (tf-e, cabane si case): acoperis de tabla cu falturi (nervuri in
    relief), in doua sau patru ape, nod `*_Roof` pe PAINTED_METAL / KERB_RED /
    RUST_METAL dupa piesa."""
    raise NotImplementedError("tin_roof: valul 1 (tf-e)")


# ---------------------------------------------------------------------------
# emit -- comun tuturor build-urilor Transfagarasan
# ---------------------------------------------------------------------------

TF_RESULTS = []


def emit_tf(objs, path, ao, keep_xy=True, bevel=0.0, bevels=None, smooth_angle=None,
            bevel_angle=30.0):
    """Finish pe fiecare nod + export in assets/models/transfagarasan/<path>.

    Offsetul de origine se calculeaza O DATA pe ansamblu (memoria finish-
    recentreaza-fiecare-nod-separat): `keep_xy=True` pastreaza XY (piesa e deja
    construita pe axa drumului), baza ansamblului la Z=0. `bevels` = {sufix_nod:
    latime} suprascrie `bevel` pe nodurile cu acel sufix."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao, origin=None,
                    smooth_angle=smooth_angle)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "transfagarasan/" + path)
    TF_RESULTS.append((path, total, dims, per_node, sz / 1024.0))
    return total


def report_tf():
    print()
    for path, tris, dims, per_node, kb in TF_RESULTS:
        print("%-44s tris=%6d  %.2f x %.2f x %.2f m  %.0f kB" %
              (path, tris, dims.x, dims.y, dims.z, kb))
        print("    noduri:", per_node)
