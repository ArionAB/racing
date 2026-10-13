"""Vocabular de forme pentru kitul Transfagarasan (Track21).

Contract: docs/asset_briefs/transfagarasan_kit.md. Lectia Okinawa/Monument
Valley: fara vocabular comun, fiecare constructor reinventeaza forma din cutii.
Pe pilot (tunnel_portal_balea) s-au scris DOAR formele folosite de portal; cele
care vin in valul 1 sunt stub-uri cu contractul in docstring (NU au corp: ridica
NotImplementedError, ca sa nu le foloseasca nimeni pe nevazute).

FOLOSITE (pilot + val 1 tf-a):
  ring_stack       masa inchisa din inele de puncte 3D (acelasi numar de puncte
                   pe inel). Doua inele consecutive la ACEEASI cota = un prag.
  snow_wall_section / snow_wall_module   (tf-a) peretele de zapada veche: 3-4
                   straturi cu trepte pe fata taiata de plug, scobituri de freza,
                   praful ca PETE pe fete (nod *_Dust), creasta topita; totul
                   periodic pe lungimea modulului -> capete identice.
  extrude_xz       prisma dintr-un contur in planul XZ (poate fi concav), pe Y.
  tilt_front       inclina fata din fata a unei prisme (placa lasata inapoi).
  tube_lining      captuseala de umbra a gurii: banda fara capace, normale spre gol.
  faceted_block    bloc de zapada unghiular (convex hull), baza plata (portalul
                   Balea rev. 2, bolovanii semnelor).
  dust_patch       bucata scurta de praf, inclinata (portalul Balea rev. 2).
  schist_blade     (tf-a, MINIMA) lama de sist pe foliatie; la integrare se
                   unifica cu `tf_shapes_nature.schist_blade` (tf-b).
  dry_stone_wall   (tf-a) zid de sprijin: 17 pietre mari cu muchii tesite pe
                   fata, coronament din pietre lipite, varianta curba (`bend_R`).
  emit_tf          finish pe fiecare nod + export in assets/models/transfagarasan/.

  tin_roof         (tf-e, val 2) acoperis de tabla cu falturi: ape plane groase,
                   nervuri de 3-4 cm la 0,5 m pe panta, coama + muchii de hip
                   acoperite; `gable` (doua ape) sau `hip` (patru ape), coama
                   pe X sau pe Y; intoarce cotele fetei de sus / de jos.

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


# ---------------------------------------------------------------------------
# zapada veche: snow_wall (valul 1, tf-a)
# ---------------------------------------------------------------------------

def _per(y, L, harmonics):
    """Zgomot PERIODIC pe lungimea modulului: suma de sinusuri cu un numar INTREG
    de perioade pe L, deci valoarea si panta sunt identice la -L/2 si +L/2
    (modulele se leaga fara rost). `harmonics` = lista (k, amplitudine, faza)."""
    u = 2.0 * math.pi * (y + L * 0.5) / L
    return sum(a * math.sin(k * u + ph) for k, a, ph in harmonics)


def _scoop(y, L, cells, depth):
    """Scobitura frezei de zapada pe fata taiata: `cells` celule concave pe
    lungimea modulului, cu muchii (cuspide) la capetele fiecarei celule. Capetele
    modulului cad pe cuspide (adancime 0), deci se leaga."""
    c = L / cells
    u = ((y + L * 0.5) / c) % 1.0
    return depth * (1.0 - (2.0 * u - 1.0) ** 2)


def snow_wall_section(y, H, L=8.0, seed=0.0, base_w=2.5, top_w=1.2, cells=7):
    """Sectiunea (x, z) a peretelui de zapada veche la pozitia `y` pe modul.

    Fata spre drum pe -X (taiata vertical de plug, cu trepte de strat), fata
    dinspre versant pe +X (rotunjita), baza intre x = -base_w/2 si +base_w/2.
    Intoarce lista de (x, z, eticheta_segment) cu ACELASI numar de puncte la
    orice `y`; segmentul i -> i+1 poarta eticheta punctului i:
      'face'   fata verticala a unui strat     'band<l>' baza stratului l (fara praf)
      'step<l>' MUCHIA treptei de deasupra stratului l: buza rotunjita + pragul
      'top'    creasta topita                  'slope'  fata dinspre versant
      'sbase'  baza fetei din spate             'base'   baza murdara spre drum
      'bottom' talpa
    Totul periodic pe L (vezi `_per`)."""
    s = seed
    nl = 4 if H >= 3.5 else 3
    # cotele straturilor (fara ultimul, care merge pana la creasta)
    span = (H - 0.95) / (nl - 1)
    bounds = [0.0] + [l * span + 0.07 * _per(y, L, [(1, 1.0, s + l * 1.3), (3, 0.5, s * 2 + l)])
                      for l in range(1, nl)]
    # treptele: cat se retrage fata la fiecare prag (0,2-0,4 m, contract)
    base_steps = [0.30, 0.24, 0.28, 0.22]
    x0 = -base_w * 0.5
    sc = _scoop(y, L, cells, 0.11)
    xf = []
    acc = 0.0
    for l in range(nl):
        if l > 0:
            acc += base_steps[l - 1] + 0.05 * _per(y, L, [(2, 1.0, s + l * 2.1), (5, 0.4, l)])
        xf.append(x0 + acc + sc)
    pts = []
    # --- fata spre drum, strat cu strat (de jos in sus)
    for l in range(nl):
        zb = bounds[l]
        band_h = 0.30 if l == 0 else 0.16
        tag = "base" if l == 0 else "band%d" % l
        pts.append((xf[l], zb, tag))
        pts.append((xf[l], zb + band_h * 0.5, tag))      # doua randuri: margine zdrentuita
        pts.append((xf[l], zb + band_h, "face"))
        if l < nl - 1:
            zt = bounds[l + 1]
            pts.append((xf[l], zt - 0.09, "step%d" % l))   # buza rotunjita a stratului
            pts.append((xf[l] + 0.09, zt, "step%d" % l))   # pragul spre stratul de sus
    # --- creasta topita si ondulata (stratul de sus)
    Ht = H - 0.14 - 0.07 * _per(y, L, [(2, 1.0, s + 0.7), (3, 0.6, s + 2.0), (5, 0.3, s)])
    xl = xf[-1]
    xb = xl - sc + top_w                        # muchia din spate: 1,2 m la varf
    pts.append((xl, Ht - 0.48, "face"))
    pts.append((xl + 0.07, Ht - 0.20, "top"))
    pts.append((xl + 0.26, Ht - 0.04, "top"))
    pts.append((xl + 0.62, Ht + 0.04 * _per(y, L, [(4, 1.0, s + 1.1)]), "top"))
    pts.append((xb - 0.18, Ht - 0.10, "top"))
    pts.append((xb + 0.02, Ht - 0.38, "slope"))
    # --- fata dinspre versant: umar rotunjit, coboara la x = +base_w/2
    zs0 = Ht - 0.38
    xs0 = xb + 0.02
    xe = base_w * 0.5
    for f in (0.78, 0.55, 0.34, 0.14):
        z = zs0 * f
        x = min(xe, xe - (xe - xs0) * f ** 2.2 + 0.05 * _per(y, L, [(3, 1.0, s + f * 4.0)]))
        pts.append((x, z, "slope"))
    pts.append((xe, 0.28, "sbase"))
    pts.append((xe, 0.14, "sbase"))
    pts.append((xe, 0.0, "bottom"))
    return pts


def snow_wall_module(snow, dust, H, L=8.0, seed=0.0, rings_per_cell=4, cells=7,
                     dust_frac=None):
    """Modulul de perete de zapada veche (kit §1.1 `snow_wall`, corectura
    coordonatorului): sectiunea `snow_wall_section` trasa pe Y intre -L/2 si
    +L/2, cu inele pe cuspidele scobiturilor (capetele cad pe cuspida). Capete
    plane, identice (toata variatia e periodica pe L).

    Praful e PATA pe fete, nu volum, si sta DOAR unde se aduna praful real
    (verdictul coordonatorului, val 1): pe banda de la baza primului strat
    ('base') si pe MUCHIILE treptelor ('step<l>': buza + prag). Se alege pe
    QUAD, pe coloane intregi (fara sah de triunghiuri), cu un zgomot periodic de
    frecventa joasa -> petice lungi de-a lungul muchiei. Acoperirea pe eticheta
    e EXACTA (cuantila pe coloane, `dust_frac`); randul de sus al benzii de baza
    primeste mai putin, deci peticul are margine in trepte. Fetele se scriu cu
    infasurarea spre exterior, nodurile se fac cu `to_obj`."""
    n = cells * rings_per_cell
    ys = [-L * 0.5 + L * i / n for i in range(n + 1)]
    secs = [snow_wall_section(y, H, L, seed, cells=cells) for y in ys]
    m = len(secs[0])
    frac = {"base": 0.38, "step0": 0.15, "step1": 0.13, "step2": 0.13}
    frac.update(dust_frac or {})
    ymids = [(ys[k] + ys[k + 1]) * 0.5 for k in range(n)]
    noise, cut = {}, {}
    for t_i, tag in enumerate(sorted(frac)):
        hm = [(1, 0.7, seed + t_i * 1.7), (2, 0.9, seed * 0.5 + t_i * 2.9),
              (3, 0.5, t_i * 2.3), (4, 0.3, seed + t_i)]
        vals = [_per(y, L, hm) for y in ymids]
        noise[tag] = vals
        srt = sorted(vals)

        def q(f, srt=srt):
            return srt[max(0, min(len(srt) - 1, int(round((1.0 - f) * len(srt)))))]
        cut[tag] = (q(frac[tag]), q(frac[tag] * 0.55))   # (rand de jos, rand de sus)
    # al catelea segment din eticheta e (randul) -- pe sectiunea 0
    row_of = {}
    seen = {}
    for i in range(m):
        tag = secs[0][i][2]
        row_of[i] = seen.get(tag, 0)
        seen[tag] = row_of[i] + 1

    a2 = 0.0
    sec = secs[0]
    for i in range(m):
        x1, z1, _ = sec[i]
        x2, z2, _ = sec[(i + 1) % m]
        a2 += x1 * z2 - x2 * z1
    ccw = a2 > 0   # antiorar in (x, z)

    rings = [[snow.bm.verts.new((x, y, z)) for (x, z, _) in sec] for y, sec in zip(ys, secs)]
    dust_faces = []
    for k in range(n):
        for i in range(m):
            j = (i + 1) % m
            quad = [rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]]
            if ccw:
                quad.reverse()
            tag = secs[k][i][2]
            if tag in frac:
                lo_cut, hi_cut = cut[tag]
                thr = hi_cut if (tag == "base" and row_of[i] > 0) else lo_cut
                if noise[tag][k] >= thr:
                    dust_faces.append([v.co.copy() for v in quad])
                    continue
            f = snow.bm.faces.new(quad)
            f[snow.slot] = TF_SNOW
    cap0 = list(rings[0])
    cap1 = list(rings[-1])
    if ccw:
        cap1.reverse()
    else:
        cap0.reverse()
    for cap in (cap0, cap1):
        f = snow.bm.faces.new(cap)
        f[snow.slot] = TF_SNOW
    for q4 in dust_faces:
        f = dust.bm.faces.new([dust.bm.verts.new(p) for p in q4])
        f[dust.slot] = TF_DUST
    return len(dust_faces)


# ---------------------------------------------------------------------------
# beton: arc, prisme, rama, cornisa, contrafort, captuseala
# ---------------------------------------------------------------------------

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


def tilt_front(b, y_front, tan_back, z_ref=0.0):
    """Inclina FATA din fata a unei prisme extrudate: vertecsii cu y ~ y_front se
    retrag cu `tan_back` * (z - z_ref) spre -Y (placa se inclina inapoi)."""
    for v in b.bm.verts:
        if abs(v.co.y - y_front) < 1e-6:
            v.co.y = y_front - tan_back * (v.co.z - z_ref)


def tube_lining(b, path_xz, y_back, y_front, tan_back, inset=0.03, slot=TF_VOID):
    """Captuseala de umbra a unei guri: banda FARA capace de-a lungul conturului
    deschis `path_xz` (stanga jos -> sus -> dreapta jos), intre y_back si fata
    inclinata (capatul din fata urmareste inclinarea `tan_back`), retrasa `inset`
    spre interior pe colturi (miter). Normalele spre INTERIORUL golului. Nu are
    podea si nu inchide golul; la masurare intra in cifra (strange cu `inset`)."""
    pts = [Vector(p) for p in path_xz]
    n = len(pts)
    cen = Vector((0.0, 6.0))
    shifted = []
    for i, p in enumerate(pts):
        segs = []
        if i > 0:
            segs.append((p - pts[i - 1]).normalized())
        if i < n - 1:
            segs.append((pts[i + 1] - p).normalized())
        nrm = []
        for d in segs:
            nn = Vector((-d.y, d.x))          # normala stanga a directiei
            if nn.dot(cen - p) < 0:
                nn = -nn
            nrm.append(nn)
        off = nrm[0] if len(nrm) == 1 else (nrm[0] + nrm[1]) / (1.0 + nrm[0].dot(nrm[1]))
        shifted.append(p + off * inset)
    for i in range(n - 1):
        (x0, z0), (x1, z1) = shifted[i], shifted[i + 1]
        yf0 = y_front - tan_back * z0 - 0.02
        yf1 = y_front - tan_back * z1 - 0.02
        vs = [(x0, y_back, z0), (x1, y_back, z1), (x1, yf1, z1), (x0, yf0, z0)]
        f = b.bm.faces.new([b.bm.verts.new(q) for q in vs])
        f.normal_update()
        mid = Vector(((x0 + x1) * 0.5, f.calc_center_median().y, (z0 + z1) * 0.5))
        if f.normal.dot(Vector((0.0, mid.y, 4.0)) - mid) < 0:
            f.normal_flip()
        f[b.slot] = slot


def faceted_block(b, center, size, slot, seed=0, jag=0.22, base_flat=True):
    """Bloc de zapada: invelitoare convexa (convex hull) a unor puncte din jurul
    unei cutii `size` (sx, sy, sz) cu centrul pe (cx, cy) si BAZA la z = center[2]:
    fete plane, unghiulare, 2-4 m, nu trepte regulate. Colturile de sus sunt
    trase spre interior (`jag`), 4 puncte de mijloc ies usor din fete. Baza e
    plata (se aseaza pe teren)."""
    import random
    rnd = random.Random(seed)
    cx, cy, z0 = center
    sx, sy, sz = size
    hx, hy = sx * 0.5, sy * 0.5
    pts = []
    for ix in (-1, 1):
        for iy in (-1, 1):
            j = lambda: 1.0 - jag * rnd.random()
            pts.append((cx + ix * hx * (0.9 + 0.1 * rnd.random()), cy + iy * hy * (0.9 + 0.1 * rnd.random()), z0))
            pts.append((cx + ix * hx * j() * 0.8, cy + iy * hy * j() * 0.8,
                        z0 + sz * (1.0 - 0.25 * jag * rnd.random())))
    zm = z0 + sz * (0.45 + 0.2 * rnd.random())
    for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        pts.append((cx + ax * hx * (1.0 + 0.06 * rnd.random()) + (rnd.random() - 0.5) * hx * 0.4 * ay,
                    cy + ay * hy * (1.0 + 0.06 * rnd.random()) + (rnd.random() - 0.5) * hy * 0.4 * ax,
                    zm + (rnd.random() - 0.5) * sz * 0.2))
    vs = [b.bm.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(b.bm, input=vs)
    bmesh.ops.delete(b.bm, geom=list(res["geom_interior"]) + list(res["geom_unused"]),
                     context="VERTS")
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace) and f.is_valid:
            f[b.slot] = slot


def dust_patch(b, center, length, tilt_deg, height=0.2, depth=0.7, slot=TF_DUST):
    """Bucata scurta de praf, INCLINATA in planul fetei (rotatie pe Y), pe fata
    din fata a unui bloc; adanca (`depth`) ca sa nu pluteasca pe o fata retrasa."""
    rot = Matrix.Rotation(math.radians(tilt_deg), 3, "Y")
    b.box(center, (length, depth, height), slot, rotation=rot)


# ---------------------------------------------------------------------------
# STUB-URI (valul 1) -- contractul din kit; fara corp pana le foloseste cineva
# ---------------------------------------------------------------------------

def schist_blade(b, center, size, slot=None, dip_deg=40.0, strike_deg=0.0, seed=0,
                 jag=0.12, lip=0.45):
    """Lama de sist (varianta MINIMA tf-a, pentru `rock_tunnel_portal`; la
    integrare se unifica cu `tf_shapes_nature.schist_blade` din grupa tf-b).

    Invelitoarea convexa a unei cutii orientate pe foliatie, cu colturile
    jitterate: `size` = (lungime pe DIRECTIE, latime pe INCLINARE, grosime).
    Directia (strike) e orizontala, la `strike_deg` de +Y (0 = lama curge pe Y);
    inclinarea (dip) urca spre +X local cu `dip_deg` (30-50, ACEEASI pe toata
    piesa: kit regula 7). Muchia de sus a lamei (capatul +dip) e ascutita: fata
    ei de sus se retrage cu `lip` din grosime, deci lama se termina in buza, nu
    in cant drept. Fisura dintre lame vine din geometrie (lamele se suprapun cu
    rost) + AO, nu dintr-un slot inchis."""
    import random
    slot = TF_SCHIST if slot is None else slot
    rnd = random.Random(seed)
    a = math.radians(strike_deg)
    dp = math.radians(dip_deg)
    sv = Vector((math.sin(a), math.cos(a), 0.0))
    hv = Vector((math.cos(a), -math.sin(a), 0.0))
    dv = hv * math.cos(dp) + Vector((0.0, 0.0, math.sin(dp)))
    nv = sv.cross(dv).normalized()
    if nv.z < 0:
        nv = -nv
    c = Vector(center)
    L, W, T = size
    pts = []
    for iu in (-1, 1):
        for iw in (-1, 1):
            for it in (-1, 1):
                ju = 1.0 - jag * rnd.random()
                jw = 1.0 - jag * rnd.random()
                tt = T * 0.5
                if iw > 0 and it > 0:
                    tt *= (1.0 - lip)                      # buza: capatul de sus ascutit
                p = (c + sv * (iu * L * 0.5 * ju) + dv * (iw * W * 0.5 * jw)
                     + nv * (it * tt * (1.0 - 0.5 * jag * rnd.random())))
                pts.append(p)
    # doua puncte pe mijlocul lungimii, ca muchia lunga sa nu fie perfect dreapta
    for iw in (-1, 1):
        pts.append(c + sv * ((rnd.random() - 0.5) * L * 0.4) + dv * (iw * W * 0.5 * (1.0 + 0.05 * rnd.random()))
                   + nv * (T * 0.5 * (0.2 if iw > 0 else 0.7)))
    vs = [b.bm.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(b.bm, input=vs)
    junk = [g for g in set(res["geom_interior"]) | set(res["geom_unused"]) if g.is_valid]
    bmesh.ops.delete(b.bm, geom=junk, context="VERTS")
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace) and f.is_valid:
            f[b.slot] = slot


def _clip_hull_pts(pts, y_lo, y_hi):
    """Punctele politopului convex conv(pts) taiat la y_lo <= y <= y_hi: varfurile
    din interior + intersectiile muchiilor hull-ului cu cele doua plane. Asa o
    piatra care incalca capatul modulului se taie PLAN, fara boolean."""
    tmp = bmesh.new()
    vs = [tmp.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(tmp, input=vs)
    edges = [e for e in res["geom"] if isinstance(e, bmesh.types.BMEdge) and e.is_valid]
    out = [Vector(v.co) for v in tmp.verts if v.is_valid and v.link_edges
           and y_lo - 1e-6 <= v.co.y <= y_hi + 1e-6]
    for e in edges:
        a, b = e.verts[0].co, e.verts[1].co
        for yp in (y_lo, y_hi):
            if (a.y - yp) * (b.y - yp) < 0:
                t = (yp - a.y) / (b.y - a.y)
                out.append(Vector(a.lerp(b, t)))
    tmp.free()
    return out


def _hull(b, pts, slot):
    vs = [b.bm.verts.new(p) for p in pts]
    bmesh.ops.remove_doubles(b.bm, verts=vs, dist=1e-4)
    vs = [v for v in vs if v.is_valid]
    res = bmesh.ops.convex_hull(b.bm, input=vs)
    junk = [g for g in set(res["geom_interior"]) | set(res["geom_unused"]) if g.is_valid]
    bmesh.ops.delete(b.bm, geom=junk, context="VERTS")
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace) and f.is_valid:
            f[b.slot] = slot


def _periodic_joints(rnd, L, n, wmin, wmax):
    """`n` latimi aleatoare in [wmin, wmax] scalate la suma L, cu un decalaj
    aleator: rosturile sunt periodice pe L (capetele modulului se potrivesc)."""
    ws = [wmin + (wmax - wmin) * rnd.random() for _ in range(n)]
    sc = L / sum(ws)
    ws = [w * sc for w in ws]
    j = -L * 0.5 + rnd.random() * ws[0]
    out = [j]
    for w in ws:
        out.append(out[-1] + w)
    return out


def _emit_periodic_hull(b, pts, L, slot):
    """Hull-ul punctelor, plus copiile decalate cu +-L, taiate plan la +-L/2:
    o piatra care incalca un capat apare jumatate la fiecare capat, identic."""
    h = L * 0.5
    for shift in (0.0, -L, L):
        q = [Vector(p) + Vector((0.0, shift, 0.0)) for p in pts]
        ylo = min(p.y for p in q)
        yhi = max(p.y for p in q)
        if yhi <= -h or ylo >= h:
            continue
        if ylo < -h or yhi > h:
            q = _clip_hull_pts(q, -h, h)
        if len(q) >= 4:
            _hull(b, q, slot)


def dry_stone_wall(b, L=8.0, H=5.0, top_w=1.2, base_w=2.0, seed=0.0, slot=None,
                   bend_R=None, cope_h=0.55, cope_over=0.05, rows=(4, 5, 4, 4),
                   joint=0.05, depth=0.06, inset=0.05):
    """Zid de sprijin din piatra uscata (kit §1.1 `retaining_wall_*`, contract
    revizuit de coordonator dupa val 1).

    Axe: Y lungul zidului (capete plane la +-L/2), X spre VALE, Z sus. Originea
    e pe muchia dinspre drum a crestei (x = 0, z = 0): creasta e PLANA la cota 0,
    iar zidul atarna pana la z = -H. Spatele (x = 0) e vertical, ingropat in
    umplutura.

    * CORONAMENTUL (coping): un rand de pietre LIPITE, cu fata de sus in ACELASI
      plan (z = 0), de la x = 0 la x = top_w, inalte `cope_h`; ies `cope_over`
      peste fata zidului de dedesubt. Intre ele se vede doar o tesitura de 3 cm
      (rost in V), nu goluri.
    * FATA SPRE VALE (talus ~10 grade, de la top_w - cope_over sub coronament la
      base_w la baza): pietre MARI ca forma, in randuri neregulate (`rows` =
      pietre pe rand, 17 pe modul), cu colturile tesite aleator (contur de 8
      laturi, piatra de camp). Fiecare piatra e un hull: conturul pe
      planul retras al corpului (`depth` in spate), fata din fata retrasa cu
      `inset` pe contur, deci muchia e tesita si rosturile (`joint`, plus
      colturi stranse aleator 0-8 cm) fac umbra. Granulatia ramane a clasei
      `stone_wall`.
    * CORPUL: masa din spatele pietrelor (fata retrasa cu `depth`), inchisa.
    * Rosturile tuturor randurilor sunt periodice pe L, iar piatra care incalca
      un capat se taie plan la ambele capete -> capete identice, modulele se
      leaga piatra-n piatra.
    * `bend_R`: modulul curb. Fiecare punct (x, y) trece pe arcul cu centrul la
      (-bend_R, 0); coarda la x = 0 ramane L, capetele raman plane (radiale) si
      cu ACEEASI sectiune ca modulul drept."""
    import random
    slot = TF_SCHIST if slot is None else slot
    rnd = random.Random(int(seed * 1000) + 7)
    h = L * 0.5
    x_top = top_w - cope_over                     # fata zidului sub coronament
    span = H - cope_h
    nrm = Vector((span, 0.0, base_w - x_top)).normalized()   # normala fetei spre vale

    def face(y, z):                                # punct pe planul fetei
        t = (-cope_h - z) / span
        return Vector((x_top + (base_w - x_top) * t, y, z))

    # --- corpul: inele pe Y (pentru indoire), fata retrasa cu `depth`
    n = int(round(L / 0.5))
    rings = []
    for i in range(n + 1):
        y = -h + L * i / n
        ft = face(y, -cope_h) - nrm * depth
        fb = face(y, -H) - nrm * depth
        rings.append([(0.0, y, -cope_h), (0.0, y, -H), (fb.x, y, -H), (ft.x, y, ft.z)])
    vr = [[b.bm.verts.new(p) for p in r] for r in rings]
    for k in range(n):
        for i in range(4):
            j = (i + 1) % 4
            f = b.bm.faces.new((vr[k][i], vr[k][j], vr[k + 1][j], vr[k + 1][i]))
            f[b.slot] = slot
    for cap in (list(reversed(vr[0])), vr[-1]):
        f = b.bm.faces.new(cap)
        f[b.slot] = slot

    # --- pietrele fetei: randuri neregulate
    hs = [0.9 + 0.35 * rnd.random() for _ in rows]
    sc = span / sum(hs)
    zb = [-cope_h]
    for hh in hs:
        zb.append(zb[-1] - hh * sc)
    zb[-1] = -H
    stones = 0
    for r, cnt in enumerate(rows):
        z_top, z_bot = zb[r], zb[r + 1]
        joints = _periodic_joints(rnd, L, cnt, 1.3, 2.2)
        for si in range(cnt):
            y0, y1 = joints[si] + joint * 0.5, joints[si + 1] - joint * 0.5
            zt = z_top - (joint * 0.5 if r > 0 else 0.02)
            zbt = z_bot + (joint * 0.5 if r < len(rows) - 1 else 0.0)
            sr = random.Random(int(seed * 1000) + 977 * r + 31 * si)
            k = lambda: 0.08 * sr.random()
            quad = [(y0 + k(), zt - k()), (y1 - k(), zt - k()),
                    (y1 - k(), zbt + (k() if r < len(rows) - 1 else 0.0)),
                    (y0 + k(), zbt + (k() if r < len(rows) - 1 else 0.0))]
            # piatra de camp, nu bloc taiat: fiecare colt tesit aleator
            # 0,12-0,32 m -> contur neregulat de 8 laturi; in colturi raman
            # goluri triunghiulare (umbra), ca pe decupare
            corners = []
            for qi in range(4):
                P = Vector(quad[qi])
                A = Vector(quad[qi - 1]) - P
                B = Vector(quad[(qi + 1) % 4]) - P
                ca = min(0.12 + 0.20 * sr.random(), A.length * 0.35)
                cb = min(0.12 + 0.20 * sr.random(), B.length * 0.35)
                pa, pb = P + A.normalized() * ca, P + B.normalized() * cb
                corners += [(pa.x, pa.y), (pb.x, pb.y)]
            cy = sum(c[0] for c in corners) / len(corners)
            cz = sum(c[1] for c in corners) / len(corners)
            pts = []
            for (yy, zz) in corners:
                pts.append(face(yy, zz) - nrm * depth)                      # pe corp
                dy, dz = cy - yy, cz - zz
                ln = math.hypot(dy, dz) or 1.0
                fi = inset * (1.0 + 0.2 * sr.random())
                pts.append(face(yy + dy / ln * fi, zz + dz / ln * fi)
                           + nrm * 0.01 * sr.random())                     # fata, retrasa
            pts.append(face(cy + (sr.random() - 0.5) * 0.3, cz) + nrm * 0.06)   # bombata
            for p in pts:              # normala are si z: nimic sub baza zidului
                p.z = max(p.z, -H)
            _emit_periodic_hull(b, pts, L, slot)
            stones += 1

    # --- coronamentul: pietre lipite, aceeasi fata de sus
    c = 0.03
    joints = _periodic_joints(rnd, L, 8, 0.85, 1.2)
    for si in range(8):
        y0, y1 = joints[si], joints[si + 1]
        pts = []
        for ya, sgn in ((y0, 1.0), (y1, -1.0)):
            yi = ya + sgn * c
            pts += [Vector((0.0, yi, 0.0)), Vector((top_w - c, yi, 0.0)),
                    Vector((top_w, yi, -c)), Vector((top_w, yi, -cope_h)),
                    Vector((0.0, ya, -c)), Vector((top_w - c, ya, -c)),
                    Vector((top_w - c, ya, -cope_h)), Vector((0.0, ya, -cope_h))]
        _emit_periodic_hull(b, pts, L, slot)

    if bend_R:
        alpha = math.asin(h / bend_R)
        for v in b.bm.verts:
            x, y, z = v.co
            th = y / h * alpha
            r = bend_R + x
            v.co = Vector((-bend_R + r * math.cos(th), r * math.sin(th), z))
    return stones


def _slab(b, top, n, thick, slot):
    """Placa plana: poligonul `top` (3D, coplanar, convex) si copia lui coborata
    cu `thick` pe -n, inchisa pe laturi. Infasurarea o repara `Builder.to_object`
    (recalc pe carcasa inchisa)."""
    vt = [b.bm.verts.new(Vector(p)) for p in top]
    vb = [b.bm.verts.new(Vector(p) - n * thick) for p in top]
    m = len(vt)
    for face in (vt, list(reversed(vb))):
        f = b.bm.faces.new(face)
        f[b.slot] = slot
    for i in range(m):
        j = (i + 1) % m
        f = b.bm.faces.new((vt[i], vb[i], vb[j], vt[j]))
        f[b.slot] = slot


def tin_roof(b, cx, cy, hx, hy, z_eave, pitch_deg, slot, kind="gable", axis="X",
             thick=0.12, rib_h=0.035, rib_w=0.045, step=0.5, cap=(0.26, 0.10),
             ribs=True):
    """Acoperis de TABLA CU FALTURI (tf-e: cabane, case, stana): ape plane cu
    nervuri in relief de-a lungul pantei, coama si (la `hip`) muchiile acoperite.

    Plan: dreptunghiul acoperisului cu streasina INCLUSA, centrul (cx, cy),
    semi-laturile `hx` (de-a lungul coamei) si `hy` (de la coama la streasina).
    `axis="X"`: coama paralela cu X (streasinile la cy +- hy); `axis="Y"`: coama
    paralela cu Y (planul rotit 90 de grade; hx tot de-a lungul coamei).
      kind="gable"  doua ape, fronton la capete (coama pe toata lungimea 2*hx)
      kind="hip"    patru ape: coama 2*(hx - hy), ape triunghiulare la capete,
                    muchii (hip) la 45 de grade in plan, aceeasi panta peste tot
    Streasina e la `z_eave` (fata de SUS a tablei, pe muchia streasinii), panta
    `pitch_deg`. Fiecare apa e o placa groasa `thick` (cantul se vede ca
    streasina). Falturile: nervuri `rib_w` x `rib_h` (3-4 cm, contract) la pasul
    `step` (0,5 m), de la streasina pana la coama sau pana la muchia de hip;
    capetele lor de la hip sunt acoperite de capacul muchiei (`cap` = latime,
    inaltime). Totul pe UN slot (nodul `*_Roof`: ASPHALT_EDGE / KERB_RED /
    RUST_METAL dupa piesa; tabla argintie pe ASPHALT_EDGE 6, decizia
    coordonatorului din val 2: PAINTED_METAL iesea albastru).

    Intoarce dict: `ridge_z` (fata de sus la coama), `tan`, `top(x, y)` (cota
    fetei de sus a tablei), `under(x, y)` (cota fetei de jos: pe ea se opresc
    peretii si frontoanele)."""
    t = math.tan(math.radians(pitch_deg))
    hip = kind == "hip"
    r = (hx - hy) if hip else hx
    if r < 0:
        raise ValueError("tin_roof hip: hx < hy")
    z_r = z_eave + hy * t
    sec = math.sqrt(1.0 + t * t)

    def W(u, v, z):
        return Vector((cx + u, cy + v, z)) if axis == "X" else Vector((cx - v, cy + u, z))

    def WN(nu, nv, nz):
        n = Vector((nu, nv, nz)) if axis == "X" else Vector((-nv, nu, nz))
        return n.normalized()

    def loc(x, y):
        return (x - cx, y - cy) if axis == "X" else (y - cy, -(x - cx))

    def top(x, y):
        u, v = loc(x, y)
        d = hy - abs(v)
        if hip:
            d = min(d, hx - abs(u))
        return z_eave + d * t

    def under(x, y):
        return top(x, y) - thick * sec

    def rib(p1, p2, n):
        off = n * (rib_h * 0.5)
        b.beam(p1 + off, p2 + off, (rib_w, rib_h), slot, up=n)

    # --- apele lungi (+v / -v)
    for s in (1.0, -1.0):
        n = WN(0.0, s * t, 1.0)
        _slab(b, [W(-hx, s * hy, z_eave), W(hx, s * hy, z_eave), W(r, 0.0, z_r),
                  W(-r, 0.0, z_r)], n, thick, slot)
        if not ribs:
            continue
        k = 0
        while True:
            u = -hx + step * 0.5 + k * step
            k += 1
            if u > hx - 1e-6:
                break
            v_end = max(0.0, abs(u) - r)
            if v_end > hy - 0.15:
                continue
            rib(W(u, s * hy, z_eave), W(u, s * v_end, z_eave + (hy - v_end) * t), n)
    # --- apele de capat (hip)
    if hip:
        for s in (1.0, -1.0):
            n = WN(s * t, 0.0, 1.0)
            _slab(b, [W(s * hx, -hy, z_eave), W(s * hx, hy, z_eave), W(s * r, 0.0, z_r)]
                  if s > 0 else [W(s * hx, hy, z_eave), W(s * hx, -hy, z_eave), W(s * r, 0.0, z_r)],
                  n, thick, slot)
            if not ribs:
                continue
            k = 0
            while True:
                v = -hy + step * 0.5 + k * step
                k += 1
                if v > hy - 1e-6:
                    break
                u_end = r + abs(v)
                if hx - u_end < 0.15:
                    continue
                rib(W(s * hx, v, z_eave), W(s * u_end, v, z_eave + (hx - u_end) * t), n)
    # --- capacele: coama si muchiile de hip
    cw, ch = cap
    lift = Vector((0.0, 0.0, ch * 0.5 - 0.02))
    if r > 1e-3:
        b.beam(W(-r, 0.0, z_r) + lift, W(r, 0.0, z_r) + lift,
               (cw, ch), slot, up=(0.0, 0.0, 1.0))
    if hip:
        for su in (1.0, -1.0):
            for sv in (1.0, -1.0):
                a = W(su * hx, sv * hy, z_eave) + lift
                c = W(su * r, 0.0, z_r) + lift
                b.beam(a, c, (cw, ch), slot, up=(0.0, 0.0, 1.0))
    return {"ridge_z": z_r, "tan": t, "top": top, "under": under}


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
