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
  bulgar           (tf-a) bulgare de zapada aproape izotrop (portalul Balea rev. 4).
  faces_to_dust    (tf-a) muta fete din zapada pe nodul de praf (pata, nu volum).
  extrude_xz       prisma dintr-un contur in planul XZ (poate fi concav), pe Y.
  tilt_front       inclina fata din fata a unei prisme (placa lasata inapoi).
  tube_lining      captuseala de umbra a gurii: banda fara capace, normale spre gol.
  faceted_block    bloc unghiular (convex hull), baza plata (bolovanii semnelor).
  dust_patch       bucata scurta de praf, inclinata (pilot rev. 2; nefolosit acum).
  schist_blade     (tf-a, MINIMA) lama de sist pe foliatie; la integrare se
                   unifica cu `tf_shapes_nature.schist_blade` (tf-b).
  dry_stone_wall   (tf-a) zid de sprijin: corp cu fete mari + randul de sus din
                   pietre individuale, periodic, cu varianta curba (`bend_R`).
  emit_tf          finish pe fiecare nod + export in assets/models/transfagarasan/.

STUB-URI (valul 1, vezi docstring-urile):
  tin_roof

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
      'face'   fata verticala a unui strat     'band<l>' banda de praf a stratului l
      'ledge<l>' pragul de deasupra stratului l 'top'   creasta topita
      'slope'  fata dinspre versant            'sbase'  baza murdara dinspre versant
      'base'   baza murdara spre drum           'bottom' talpa
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
            pts.append((xf[l], zt - 0.09, "face"))         # buza rotunjita a stratului
            pts.append((xf[l] + 0.09, zt, "ledge%d" % l))  # pragul spre stratul de sus
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
                     dust_thr=None):
    """Modulul de perete de zapada veche (kit §1.1 `snow_wall`, corectura
    coordonatorului): sectiunea `snow_wall_section` trasa pe Y intre -L/2 si
    +L/2, cu inele pe cuspidele scobiturilor (capetele cad pe cuspida). Capete
    plane, identice (toata variatia e periodica pe L).

    Praful e PATA pe fete, nu volum: fetele din benzile de la baza straturilor
    (`band<l>`), de pe praguri (`ledge<l>`) si de la baza ('base', 'sbase') trec
    in `dust` (acelasi contur, alt nod) doar unde un zgomot periodic depaseste
    pragul stratului -> petice neregulate, nu dungi continue. Fetele se scriu cu
    infasurarea spre exterior (verificata pe volum), deci nodurile se fac cu
    `to_obj`, fara recalc de normale."""
    n = cells * rings_per_cell
    ys = [-L * 0.5 + L * i / n for i in range(n + 1)]
    secs = [snow_wall_section(y, H, L, seed, cells=cells) for y in ys]
    m = len(secs[0])
    # praguri de praf (mai mic = mai mult praf)
    thr = {"base": -0.05, "sbase": 0.25, "band1": 0.35, "band2": 0.25, "band3": 0.45,
           "ledge0": 0.70, "ledge1": 0.55, "ledge2": 0.80}
    thr.update(dust_thr or {})
    harm = {}
    for i, tag in enumerate(sorted(thr)):
        harm[tag] = [(1, 0.55, seed + i * 1.7), (2, 0.6, seed * 0.5 + i), (3, 0.5, i * 2.3),
                     (5, 0.35, seed + i * 0.9), (7, 0.25, i)]

    # orientarea: sectiunea e parcursa in sens orar in (x, z) -> verificam aria
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
        ymid = (ys[k] + ys[k + 1]) * 0.5
        for i in range(m):
            j = (i + 1) % m
            quad = [rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]]
            # (x,z) antiorar vazut din +Y; extrudat spre +Y -> normala spre exterior
            # cere ordinea inversa
            if ccw:
                quad.reverse()
            tag = secs[k][i][2]
            if tag not in thr:
                f = snow.bm.faces.new(quad)
                f[snow.slot] = TF_SNOW
                continue
            # fetele etichetate se aleg pe TRIUNGHI (margini zdrentuite, nu
            # dreptunghiuri); zgomotul se decaleaza cu cota -> petele se
            # inclina usor, ca scurgerile, si randurile nu se aliniaza
            zmid = (secs[k][i][1] + secs[k][j][1]) * 0.5
            for ti, tri in enumerate(((quad[0], quad[1], quad[2]), (quad[0], quad[2], quad[3]))):
                if _per(ymid + (ti - 0.5) * 0.14 + 0.9 * zmid, L, harm[tag]) > thr[tag]:
                    dust_faces.append([v.co.copy() for v in tri])
                else:
                    f = snow.bm.faces.new(tri)
                    f[snow.slot] = TF_SNOW
    # capetele plane (n-gon concav, triangulat la export)
    cap0 = list(rings[0])
    cap1 = list(rings[-1])
    if ccw:
        cap1.reverse()
    else:
        cap0.reverse()
    for cap in (cap0, cap1):
        f = snow.bm.faces.new(cap)
        f[snow.slot] = TF_SNOW
    for q in dust_faces:
        f = dust.bm.faces.new([dust.bm.verts.new(p) for p in q])
        f[dust.slot] = TF_DUST
    return len(dust_faces)


def bulgar(b, center, r, slot, seed=0, base=None, ratio=(1.0, 0.92, 0.86), jitter=0.06,
           npts=(14, 18)):
    """Bulgare de zapada APROAPE IZOTROP (portalul Balea, rev. 4): invelitoarea
    convexa a 14-18 puncte (10-13 dau cioburi neregulate, verificat in runda 3)
    pe un elipsoid cu semiaxele `r * ratio` (aproape
    sfera: 1 : 0,92 : 0,86), raza jitterata doar +-`jitter`, rotit aleator.
    Iese un bulgare fatetat, gros, nu un ciob (rev. 3 avea 1 : 0,8 : 0,7 si
    jitter 0,95-1,25 -> placi subtiri, "hartie mototolita"). Cu `base`
    punctele de sub cota se ridica la ea (baza se turteste pe sol).
    Pornit din generatorul rev. 3 (`70abe521`)."""
    import random
    rnd = random.Random(seed)
    cx, cy, cz = center
    n = rnd.randint(*npts)
    rot = (Matrix.Rotation(rnd.random() * math.tau, 3, "Z")
           @ Matrix.Rotation(math.radians((rnd.random() - 0.5) * 60.0), 3, "X")
           @ Matrix.Rotation(math.radians((rnd.random() - 0.5) * 60.0), 3, "Y"))
    pts = []
    for _ in range(n):
        d = Vector((rnd.gauss(0, 1), rnd.gauss(0, 1), rnd.gauss(0, 1))).normalized()
        k = 1.0 + jitter * (2.0 * rnd.random() - 1.0)
        p = rot @ (Vector((d.x * ratio[0], d.y * ratio[1], d.z * ratio[2])) * (r * k))
        z = cz + p.z
        if base is not None:
            z = max(z, base)
        pts.append((cx + p.x, cy + p.y, z))
    _hull(b, pts, slot)


def faces_to_dust(snow, dust, pick, slot=None):
    """Praful ca PATA pe fete, nu ca volum: fetele alese (`pick` = BMFace din
    `snow`) se copiaza in `dust` cu ACEEASI infasurare si se sterg din `snow`."""
    slot = TF_DUST if slot is None else slot
    for f in pick:
        nf = dust.bm.faces.new([dust.bm.verts.new(v.co.copy()) for v in f.verts])
        nf[dust.slot] = slot
    bmesh.ops.delete(snow.bm, geom=list(pick), context="FACES_ONLY")


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


def dry_stone_wall(b, L=8.0, H=5.0, top_w=1.2, base_w=2.0, stones=8, seed=0.0,
                   slot=None, bend_R=None, cap_h=(0.62, 0.86)):
    """Zid de sprijin din piatra uscata (kit §1.1 `retaining_wall_*`).

    Axe: Y lungul zidului (capete plane la +-L/2), X spre VALE, Z sus. Originea
    pe muchia dinspre drum a crestei (x = 0, z = 0): creasta e PLANA la cota 0
    (acolo sta marginea drumului), zidul atarna pana la z = -H. Spatele (x = 0)
    e vertical, ingropat in umplutura; fata spre vale coboara de la x = top_w la
    x = base_w (talus ~10 grade pentru 1,2 -> 2,0 pe 5 m).

    * CORPUL: masa cu FETE MARI (inele la 0,5 m pe Y, 4 randuri pe fata de
      vale, jitter periodic pe L pe X, +-0,2 m) -- piatra se citeste din clasa
      `stone_wall`, nu din geometrie;
    * RANDUL DE SUS: `stones` pietre INDIVIDUALE pe perioada L (hull-uri cu
      colturi jitterate, fata de sus plana la z = 0, buza spre vale tesita, iesite
      0,06-0,14 m din fata, rosturi de ~5 cm). Rosturile sunt periodice pe L, iar
      piatra care incalca un capat se construieste o data si se taie PLAN la
      ambele capete (copia ei decalata cu L), deci modulele se leaga piatra-n
      piatra;
    * `bend_R`: modulul curb. Fiecare punct (x, y) trece pe arcul cu centrul la
      (-bend_R, 0); coarda la x = 0 ramane L (unghiul pe capat = asin(L/2R)),
      capetele raman plane (radiale) si cu ACEEASI sectiune ca modulul drept."""
    import random
    slot = TF_SCHIST if slot is None else slot
    rnd = random.Random(int(seed * 1000) + 7)
    h = L * 0.5
    z_top_body = -0.60

    def face_x(z):          # fata spre vale (fara jitter), z in [-H, 0]
        return top_w + (base_w - top_w) * (-z / H)

    # --- corpul: inele pe Y
    n = int(round(L / 0.5))
    ys = [-h + L * i / n for i in range(n + 1)]
    zr = [-H, -0.80 * H, -0.61 * H, -0.42 * H, -0.24 * H, z_top_body]
    rings = []
    for y in ys:
        sec = [(0.0, z_top_body), (0.0, -H)]
        for j, z in enumerate(zr):
            jit = 0.0 if j in (0, len(zr) - 1) else 0.11 * _per(y, L, [(2, 0.8, seed + j * 1.9), (3, 0.7, seed * 2 + j * 2.3), (4, 0.5, j * 0.7)])
            sec.append((face_x(z) + jit, z))
        rings.append([(x, y, z) for x, z in sec])
    # orientarea fetelor o reface `Builder.to_object` (corp inchis + hull-uri)
    vr = [[b.bm.verts.new(p) for p in r] for r in rings]
    m = len(vr[0])
    for k in range(len(vr) - 1):
        for i in range(m):
            j = (i + 1) % m
            f = b.bm.faces.new((vr[k][i], vr[k][j], vr[k + 1][j], vr[k + 1][i]))
            f[b.slot] = slot
    f = b.bm.faces.new(list(reversed(vr[0])))
    f[b.slot] = slot
    f = b.bm.faces.new(vr[-1])
    f[b.slot] = slot

    # --- randul de sus: rosturi periodice
    widths = [0.8 + 0.5 * rnd.random() for _ in range(stones)]
    sc = L / sum(widths)
    widths = [w * sc for w in widths]
    j0 = -h + 0.35 + 0.3 * rnd.random()
    joints = [j0]
    for w in widths:
        joints.append(joints[-1] + w)          # ultimul = j0 + L
    gap = 0.05
    for si in range(stones):
        y0, y1 = joints[si] + gap * 0.5, joints[si + 1] - gap * 0.5
        srnd = random.Random(int(seed * 1000) + 101 * si)
        zb = -(cap_h[0] + (cap_h[1] - cap_h[0]) * srnd.random())
        xf = top_w + 0.10 + 0.10 * srnd.random()
        pts = []
        for yy in (y0, y1):
            dj = lambda: (srnd.random() - 0.5) * 0.10
            pts.append(Vector((0.0 + 0.03 * srnd.random(), yy + dj(), 0.0)))
            pts.append(Vector((xf - 0.05, yy + dj() * 0.5, 0.0)))
            pts.append(Vector((xf, yy + dj() * 0.5, -0.05)))
            pts.append(Vector((xf + 0.03 * srnd.random(), yy + dj(), zb + 0.12 + srnd.random() * 0.1)))
            pts.append(Vector((xf - 0.10 * srnd.random(), yy + dj() + (0.08 if yy == y0 else -0.08), zb + (srnd.random() - 0.5) * 0.10)))
            pts.append(Vector((0.02, yy + dj(), zb)))
        ym = (y0 + y1) * 0.5
        pts.append(Vector((xf + 0.05, ym + (srnd.random() - 0.5) * 0.3, zb * (0.45 + 0.2 * srnd.random()))))
        for shift in (0.0, -L, L):
            q = [p + Vector((0.0, shift, 0.0)) for p in pts]
            ylo = min(p.y for p in q)
            yhi = max(p.y for p in q)
            if yhi <= -h or ylo >= h:
                continue
            if ylo < -h or yhi > h:
                q = _clip_hull_pts(q, -h, h)
            _hull(b, q, slot)

    if bend_R:
        alpha = math.asin(h / bend_R)
        for v in b.bm.verts:
            x, y, z = v.co
            th = y / h * alpha
            r = bend_R + x
            v.co = Vector((-bend_R + r * math.cos(th), r * math.sin(th), z))


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
