# --- market_gate -----------------------------------------------------------
#
# ESCALADARE OPUS (runda 3; rundele 1-2 respinse: gol dreptunghiular in "T",
# culoare prea inchisa). Rescris de la zero, fara `arch_opening`/`chhatri`/
# `crenellation` din `jodhpur_shapes.py`:
#   - `arch_opening(open=False)` umple panoul pe BOUNDING-BOX-ul golului, deci
#     silueta golului iese intotdeauna dreptunghiulara (arcul apare doar pe
#     firida). Aici panoul e un solid construit direct INTRE conturul arcului
#     si dreptunghiul panoului (`_ring_solid`), deci golul E arcul.
#   - `_arch_profile("pointed")` cu rise < half_w (arcul turtit cerut aici)
#     degenereaza in "M" (centrul iese in afara, arcul trece peste cheie si
#     coboara inapoi). Profilul de aici (`_mg_arch_half`) e un arc ascutit
#     turtit cu varf usor ogee, definit direct.
#   - `chhatri()` foloseste `_arch_band` (arcade deschise cu coloane stramba,
#     bug documentat la val 2a) -- aici chhatri-ul e din panouri cu gol
#     arcuit, construite cu acelasi `_ring_solid`.
#
# LISTA DE ELEMENTE (decuparea market_gate.png, citita inainte de primul
# vertex; vedere aproape frontala):
#   1. UN panou central de zid intre turnuri, cu UN gol mare in arc ASCUTIT
#      turtit (doua centre, varf usor ogee), deschis pana la sol.
#   2. Arhivolta: banda IN RELIEF care urmareste arcul si coboara pe
#      ambrazuri pana la sol (1 pe fiecare fata).
#   3. Cadrul dreptunghiular in relief (alfiz) in jurul arcului: 2 benzi
#      verticale + 1 banda orizontala sus. 2 medalioane rotunde in
#      timpane (stanga/dreapta cheii).
#   4. 2 canaturi de lemn DESCHISE, cate unul pe fiecare ambrazura, in
#      interiorul golului, cu tepi de fier (grila 4 x 7 pe fata vizibila).
#   5. Cornisa (brau in relief) la varful panoului, apoi parapetul cu
#      merloane "kangura" (dreptunghi + umeri rotunjiti + varf), 11 pe fata
#      (decuparea are 9 pe un gol de ~30% din latime; la 53% parapetul se
#      lungeste -- abaterea permisa), fiecare cu un punct intunecat.
#   6. 2 turnuri patrate cu colturi tesite (octogon neregulat), mai inalte
#      decat panoul, cu soclu mai lat la baza si 1 fanta de tragere pe fata.
#   7. Pe fiecare turn: balcon in consola (2 trepte de consola) cu parapet
#      jos, apoi chhatri DESCHIS: 3 arcade ascutite pe fiecare latura (4
#      laturi), streasina, cupola emisferica pe inel de lotus, finial.
#   8. La ambele capete, contraforti in trepte: o masa inalta lipita de
#      turn (varf tesit) + o masa joasa in afara ei -- silueta se evazeaza.
#   Ce iese din contur: chhatri-urile (cupole + finial) si contrafortii.
#
# LAYOUT (X = latimea portii, fata spre -Y = spre camera de comparatie,
# simetric fata/spate): golul 22,2 m intre ambrazuri, canaturile ocupa cate
# 1,9 m in proiectie -> GOLUL LIBER (proiectie pe planul portii, pana la
# 2,0 m, canaturi incluse) = 18,4 m. Arcul: nasterea la 6,1 m, cheia la
# 11,6 m. Panoul pana la 13,0 m, merloane pana la 14,6 m, turnurile pana la
# 13,0 m + balcon + chhatri pana la ~17,1 m.
#
# De ce 22,2 m de gol si nu 18,4: canaturile deschise nu au voie in golul de
# 18 m (contract), deci stau in afara lui. Proiectia unui canat pe planul
# portii e L*sin(a) + t*cos(a) -- exact cat se vede din fata. Oricat de
# lat/inclinat e canatul, cat se vede din el e cat ingusteaza golul. Pentru
# ca usile sa se vada deloc, golul fizic trebuie sa fie mai lat decat cel
# liber. Pretul: latimea totala ~38 m in loc de 34 (turnurile pastreaza
# latimea, parapetul se lungeste -- abaterea permisa din tabel).
GATE_TOTAL_W = 34.0
GATE_H = 17.0
GATE_D = 6.0
GATE_GAP_W = 18.4     # golul LIBER (contract >=18.0), cu canaturile incluse
GATE_CROWN_MIN = 11.0  # cheia arcului, contract minim
GATE_CROWN_TARGET = 11.6  # tinta constructiei -- marja reala peste minim

MG_LEAF_L = 5.2        # latimea canatului
MG_LEAF_T = 0.22       # grosimea canatului
MG_LEAF_ANG = 19.0     # unghiul canatului fata de ambrazura (grade)
# jumatatea golului fizic: golul liber + proiectia canatului deschis
MG_OPEN_HW = GATE_GAP_W * 0.5 + (MG_LEAF_L * math.sin(math.radians(MG_LEAF_ANG))
                                 + MG_LEAF_T * math.cos(math.radians(MG_LEAF_ANG)))
MG_SPRING = 6.1
MG_WALL_T = 5.4        # grosimea panoului central
MG_PANEL_HW = MG_OPEN_HW + 1.3
MG_WALL_TOP = 13.0
MG_TOWER_W = 4.4       # latimea turnului (X)
MG_TOWER_D = 6.4       # adancimea turnului (Y) -- iese 0,5 m peste zid, fata si spate
MG_TOWER_CX = MG_PANEL_HW + MG_TOWER_W * 0.5


def _mg_arch_half(half_w, rise, n=12, k=0.40, ogee=0.07):
    """Jumatatea STANGA a intradosului, de la nastere (-half_w, 0) la cheie
    (0, rise), ca (x, z). g(u) = (1-k)*sqrt(1-(1-u)^2) + k*u + ogee*u'^2:
    termenul circular da nasterea verticala (curba la umar), termenul liniar
    da panta nenula la cheie (VARF, nu bolta rotunda), iar ultimul ridica
    ultimul sfert ca un mic varf ogee. Esantionare densa la nastere
    (u = 1 - cos), unde curba e cea mai stransa."""
    pts = []
    norm = 1.0 + ogee
    for i in range(n + 1):
        t = i / n
        u = 1.0 - math.cos(t * math.pi * 0.5)
        g = (1.0 - k) * math.sqrt(max(0.0, 1.0 - (1.0 - u) ** 2)) + k * u
        g += ogee * max(0.0, (u - 0.75) / 0.25) ** 2
        pts.append((-half_w * (1.0 - u), rise * g / norm))
    return pts


def _mg_hole(half_w, spring, rise, z0=0.0, n=12):
    """Conturul complet al golului, de la baza ambrazurii stangi, prin arc,
    la baza celei drepte: lista (x, z)."""
    left = [(x, z0 + spring + z) for x, z in _mg_arch_half(half_w, rise, n)]
    right = [(-x, z) for x, z in reversed(left[:-1])]
    return [(-half_w, z0)] + left + right + [(half_w, z0)]


def _offset_contour(pts, d):
    """Deplaseaza o polilinie deschisa cu `d` spre EXTERIORUL golului
    (normala stanga a sensului de parcurgere stanga-jos -> dreapta-jos)."""
    out = []
    n = len(pts)
    for i in range(n):
        x0, z0 = pts[max(i - 1, 0)]
        x1, z1 = pts[min(i + 1, n - 1)]
        tx, tz = x1 - x0, z1 - z0
        ln = math.hypot(tx, tz) or 1e-6
        nx, nz = -tz / ln, tx / ln   # normala stanga
        x, z = pts[i]
        out.append((x - nx * d, z - nz * d))
    # capetele (baza ambrazurilor) raman strict verticale sub nastere
    out[0] = (pts[0][0] - d, pts[0][1])
    out[-1] = (pts[-1][0] + d, pts[-1][1])
    return out


def _rect_mapped(hole, panel_hw, panel_top, spring_idx):
    """Punctele de pe conturul dreptunghiului panoului corespunzatoare,
    unu-la-unu, punctelor golului: ambrazura -> latura panoului, arcul ->
    latura + sus, cu coltul de sus prins EXACT pe un punct (altfel panoul
    iese cu coltul tesit)."""
    n = len(hole)
    apex = n // 2
    out = [None] * n
    # jumatatea stanga
    out[0] = (-panel_hw, hole[0][1])
    out[spring_idx] = (-panel_hw, hole[spring_idx][1])
    side = panel_top - hole[spring_idx][1]
    path = side + panel_hw
    m = apex - spring_idx
    corner_k = max(1, min(m - 1, int(round(m * side / path))))
    for j in range(1, m + 1):
        if j <= corner_k:
            z = hole[spring_idx][1] + side * j / corner_k
            out[spring_idx + j] = (-panel_hw, z)
        else:
            x = -panel_hw + panel_hw * (j - corner_k) / (m - corner_k)
            out[spring_idx + j] = (x, panel_top)
    for i in range(apex + 1, n):
        x, z = out[n - 1 - i]
        out[i] = (-x, z)
    return out


def _ring_solid(b, inner, outer, y0, y1, slot, xf=None):
    """Solid INCHIS intre doua contururi deschise corespondente unu-la-unu
    (inner[i] <-> outer[i]), in planul XZ, extrudat pe Y intre y0 si y1.
    Varfuri partajate (manifold), deci `recalc_face_normals` le orienteaza
    corect. Capetele (i=0, i=n-1) se inchid. `xf(x, y, z)` optional
    transforma in coordonate lume (rotatie/translatie pentru chhatri)."""
    xf = xf or (lambda x, y, z: (x, y, z))
    bm = b.bm
    n = len(inner)

    def row(pts, y):
        return [bm.verts.new(xf(x, y, z)) for x, z in pts]
    fi, fo = row(inner, y0), row(outer, y0)
    bi, bo = row(inner, y1), row(outer, y1)
    faces = []
    for i in range(n - 1):
        j = i + 1
        faces.append(bm.faces.new((fi[i], fi[j], fo[j], fo[i])))   # fata y0
        faces.append(bm.faces.new((bi[i], bo[i], bo[j], bi[j])))   # fata y1
        faces.append(bm.faces.new((fi[i], bi[i], bi[j], fi[j])))   # intrados
        faces.append(bm.faces.new((fo[i], fo[j], bo[j], bo[i])))   # exterior
    faces.append(bm.faces.new((fi[0], fo[0], bo[0], bi[0])))
    faces.append(bm.faces.new((fi[-1], bi[-1], bo[-1], fo[-1])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _prism_z(b, outline_xy, z0, z1, slot):
    """Prisma verticala dintr-un contur convex in planul XY (sens trigonometric)."""
    bm = b.bm
    lo = [bm.verts.new((x, y, z0)) for x, y in outline_xy]
    hi = [bm.verts.new((x, y, z1)) for x, y in outline_xy]
    n = len(outline_xy)
    faces = [bm.faces.new(tuple(reversed(lo))), bm.faces.new(tuple(hi))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _chamfer_rect(cx, cy, hw, hd, c):
    """Dreptunghi cu colturile tesite (octogon neregulat), sens trigonometric."""
    return [(cx - hw + c, cy - hd), (cx + hw - c, cy - hd), (cx + hw, cy - hd + c),
            (cx + hw, cy + hd - c), (cx + hw - c, cy + hd), (cx - hw + c, cy + hd),
            (cx - hw, cy + hd - c), (cx - hw, cy - hd + c)]


def _mg_kangura(b, bg, x, y, z, w, h, t):
    """Un merlon "kangura": dreptunghi + umeri rotunjiti + varf ascutit,
    prisma pe Y (grosime t), cu un punct intunecat (GLOW) pe ambele fete."""
    hw = w * 0.5
    outline = [(-hw, 0.0), (hw, 0.0), (hw, 0.52 * h), (0.43 * w, 0.70 * h),
               (0.30 * w, 0.83 * h), (0.14 * w, 0.93 * h), (0.0, h),
               (-0.14 * w, 0.93 * h), (-0.30 * w, 0.83 * h), (-0.43 * w, 0.70 * h),
               (-hw, 0.52 * h)]
    faces = list(b.prism(outline, t, STONE, center=(x, y, z)))
    for s in (-1.0, 1.0):
        bg.box((x, y + s * (t * 0.5 + 0.01), z + 0.45 * h), (0.26, 0.03, 0.26), GLOW)
    return faces


def _mg_chhatri(b, bg, cx, cy, z0):
    """Chhatri patrat deschis: 3 arcade ascutite pe fiecare latura (panouri
    `_ring_solid`, coloanele sunt ambrazurile dintre goluri), streasina,
    inel de lotus, cupola emisferica, finial. Intoarce cota varfului."""
    side = 3.4
    col_h = 1.5
    t = 0.26
    bays = 3
    bay = side / bays
    hole_hw = bay * 0.30
    spring = 0.78
    rise = 0.46
    hole = _mg_hole(hole_hw, spring, rise, z0=0.0, n=6)
    outer = _rect_mapped(hole, bay * 0.5, col_h, 1)
    hs = side * 0.5
    for k in range(4):
        ang = k * math.pi * 0.5
        ca, sa = math.cos(ang), math.sin(ang)
        for i in range(bays):
            lx = -hs + bay * (i + 0.5)

            def xf(x, y, z, lx=lx, ca=ca, sa=sa):
                # cadru local: x de-a lungul laturii, y spre exterior; latura
                # k=0 e fata -Y (spre camera), rotita in jurul lui Z
                px, py = lx + x, -hs + y
                return (cx + px * ca - py * sa, cy + px * sa + py * ca, z0 + z)
            _ring_solid(b, hole, outer, -t * 0.5, t * 0.5, STONE, xf=xf)
    # streasina (chajja) + placa
    b.box((cx, cy, z0 + col_h + 0.07), (side + 0.9, side + 0.9, 0.14), STONE)
    b.box((cx, cy, z0 + col_h + 0.19), (side + 0.4, side + 0.4, 0.10), STONE)
    dome_z = z0 + col_h + 0.24
    dome(b, (cx, cy, dome_z), 1.30, STONE, drum_h=0.0, profile="hemisphere",
         segments=12, lotus_ring=True, finial=True, finial_h=0.62)
    return dome_z + 0.12 + 1.30 + 0.62 * 0.96


def build_market_gate():
    b = Builder()
    bg = Builder()
    doorb = Builder()

    hw = MG_OPEN_HW
    rise = GATE_CROWN_TARGET - MG_SPRING
    yf, yb = -MG_WALL_T * 0.5, MG_WALL_T * 0.5

    # 1. panoul central cu golul in arc (solid intre arc si dreptunghi)
    hole = _mg_hole(hw, MG_SPRING, rise, n=14)
    outer = _rect_mapped(hole, MG_PANEL_HW, MG_WALL_TOP, 1)
    _ring_solid(b, hole, outer, yf, yb, STONE)

    # 2. arhivolta in relief (0,6 m lata, 0,22 m iesita), fata si spate
    arch_band = _offset_contour(hole, 0.6)
    for y0, y1 in ((yf - 0.22, yf), (yb, yb + 0.22)):
        _ring_solid(b, hole, arch_band, y0, y1, STONE)

    # 3. alfiz: 2 benzi verticale + banda de sus, iesite 0,32 m; medalioane
    fr_x0, fr_x1 = hw + 0.72, hw + 1.22
    fr_top0, fr_top1 = GATE_CROWN_TARGET + 0.62, GATE_CROWN_TARGET + 1.12
    for y_c in (yf - 0.16, yb + 0.16):
        for s in (-1.0, 1.0):
            b.box((s * (fr_x0 + fr_x1) * 0.5, y_c, fr_top1 * 0.5),
                  (fr_x1 - fr_x0, 0.32, fr_top1), STONE)
        b.box((0.0, y_c, (fr_top0 + fr_top1) * 0.5),
              (2.0 * fr_x1, 0.32, fr_top1 - fr_top0), STONE)
        for s in (-1.0, 1.0):
            b.cylinder((s * hw * 0.70, y_c, GATE_CROWN_TARGET - 0.55), 0.62, 0.30,
                       STONE, segments=12, axis="Y")
            b.cylinder((s * hw * 0.70, y_c + math.copysign(0.14, y_c), GATE_CROWN_TARGET - 0.55),
                       0.40, 0.08, STONE, segments=12, axis="Y")

    # 5. cornisa + parapet cu merloane kangura (fata si spate)
    b.box((0.0, 0.0, MG_WALL_TOP - 0.45), (2.0 * MG_PANEL_HW, MG_WALL_T + 0.5, 0.30), STONE)
    n_m = 11
    m_w, m_h, m_t = 1.75, 1.6, 0.7
    span = 2.0 * MG_PANEL_HW - 0.6
    for i in range(n_m):
        x = -span * 0.5 + span * (i + 0.5) / n_m
        for yc in (yf + m_t * 0.5, yb - m_t * 0.5):
            _mg_kangura(b, bg, x, yc, MG_WALL_TOP, m_w, m_h, m_t)

    # 6-7. turnurile: soclu, corp tesit, fanta, balcon, chhatri
    top_z = 0.0
    for s in (-1.0, 1.0):
        cx = s * MG_TOWER_CX
        thw, thd = MG_TOWER_W * 0.5, MG_TOWER_D * 0.5
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.45, thd + 0.45, 0.9), 0.0, 0.7, STONE)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.22, thd + 0.22, 0.75), 0.7, 1.3, STONE)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw, thd, 0.6), 1.3, MG_WALL_TOP, STONE)
        # fanta de tragere, flush + inchisa (lectia val 2a), fata si spate
        for sy in (-1.0, 1.0):
            bg.box((cx, sy * (thd + 0.01), 7.6), (0.36, 0.04, 1.45), GLOW)
        # balconul in consola: doua trepte de consola + placa
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.2, thd + 0.2, 0.7), 12.35, 12.75, STONE)
        _prism_z(b, _chamfer_rect(cx, 0.0, thw + 0.5, thd + 0.5, 0.85), 12.75, 13.2, STONE)
        # parapetul jos al balconului (4 laturi)
        bw_, bd_ = thw + 0.42, thd + 0.42
        for (px, py, sx, sy2) in ((cx, -bd_, 2 * bw_, 0.16), (cx, bd_, 2 * bw_, 0.16),
                                  (cx - bw_, 0.0, 0.16, 2 * bd_), (cx + bw_, 0.0, 0.16, 2 * bd_)):
            b.box((px, py, 13.2 + 0.25), (sx, sy2, 0.5), STONE)
        top_z = max(top_z, _mg_chhatri(b, bg, cx, 0.0, 13.2))

    # 8. contrafortii in trepte (prisme cu profil tesit, extrudate pe Y)
    for s in (-1.0, 1.0):
        x_in = MG_TOWER_CX + MG_TOWER_W * 0.5 - 0.3
        tall = [(x_in, 0.0), (x_in + 2.0, 0.0), (x_in + 1.75, 4.6), (x_in + 1.1, 6.0),
                (x_in, 6.5)]
        low = [(x_in + 1.6, 0.0), (x_in + 3.2, 0.0), (x_in + 3.0, 2.5), (x_in + 2.4, 3.4),
               (x_in + 1.6, 3.6)]
        for outline, depth in ((tall, 5.2), (low, 4.4)):
            pts = [(s * x, z) for x, z in outline]
            if s < 0:
                pts = list(reversed(pts))
            b.prism(pts, depth, STONE, center=(0.0, 0.0, 0.0))

    # 4. canaturile deschise, in golul fizic, in afara golului liber
    ang = math.radians(MG_LEAF_ANG)
    leaf_h = MG_SPRING + 0.35
    for s in (-1.0, 1.0):
        hinge = Vector((s * hw, yf + 0.18, 0.0))
        # directia canatului: din balama spre interiorul trecerii (+Y),
        # inclinata cu `ang` spre axul portii
        d = Vector((-s * math.sin(ang), math.cos(ang), 0.0))
        nrm = Vector((-s * math.cos(ang), -math.sin(ang), 0.0))  # spre ax/camera
        rot = Matrix(((nrm.x, d.x, 0.0), (nrm.y, d.y, 0.0), (0.0, 0.0, 1.0)))
        c = hinge + d * (MG_LEAF_L * 0.5) + nrm * (MG_LEAF_T * 0.5)
        doorb.box((c.x, c.y, leaf_h * 0.5), (MG_LEAF_T, MG_LEAF_L, leaf_h), TRIM_WOOD,
                  rotation=rot)
        # 3 benzi de fier + grila de tepi 4 x 7 pe fata dinspre ax
        face_c = c + nrm * (MG_LEAF_T * 0.5 + 0.03)
        for zb in (0.18, 0.5, 0.82):
            doorb.box((face_c.x, face_c.y, leaf_h * zb), (0.05, MG_LEAF_L * 0.96, 0.14),
                      GLOW, rotation=rot)
        for ix in range(4):
            for iz in range(7):
                p = face_c + d * ((ix - 1.5) * MG_LEAF_L * 0.22)
                doorb.box((p.x, p.y, leaf_h * (0.10 + 0.12 * iz)), (0.12, 0.16, 0.16),
                          GLOW, rotation=rot)

    stone_obj = b.to_object("Gate_Stone")
    door_obj = doorb.to_object("Gate_Doors")
    glow_obj = _finish_or_none(bg.to_object("Gate_Glow"))
    print("market_gate: varf chhatri z=%.2f m" % top_z)
    return stone_obj, door_obj, glow_obj, GATE_CROWN_TARGET


def measure_market_gate(objs):
    """Masoara contractele DIN geometria finala (dupa bevel/origine):
    - golul liber: 2*min|x| al varfurilor sub 2,0 m, pe toata adancimea,
      pe TOATE nodurile (piatra + canaturi + fante) -- proiectia pe planul
      portii, pe gabaritul caroseriei (memoria golul-se-masoara-pe-fereastra-lui);
    - cheia: cel mai jos varf de piatra peste ax (|x| < 0,3 m, z > 2 m)."""
    min_x = 1e9
    crown = 1e9
    for o in objs:
        if o is None:
            continue
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            if p.z < 2.0:
                min_x = min(min_x, abs(p.x))
            if o.name.endswith("Gate_Stone") and abs(p.x) < 0.3 and p.z > 2.0:
                crown = min(crown, p.z)
    return 2.0 * min_x, crown


