"""Vocabular de forme indo-saracenice, pentru kitul Jodhpur.

De ce exista fisierul asta: pilotul (`build_jodhpur_pilot.py`, val 1) a fost
RESPINS pe fidelitate (`jodhpur_fidelity_val1.png`) -- `ghanta_ghar` avea
fante dreptunghiulare in loc de arcade, fara balustrade, acoperis piramidal
in loc de cupola; `blue_house_a` avea scara din trepte plutitoare in loc de
masa solida. Cauza radacina (brief, sectiunea TASK A a instantei): "nicio
functie din `dio_lib` nu stie sa deseneze un ARC" -- tot ce exista sunt cutii,
cilindri si prisme drepte. Fara vocabular, orice constructor reinventeaza
arcul din cutii tesite si iese exact ce a iesit: fante, nu goluri.

Fisierul e o COLECTIE DE FUNCTII, nu o clasa -- ca `arch_outline` din
`build_alpine_structures.py` si `_arch_outline` din
`build_machupicchu_tunnel.py`, care le-au precedat. Fiecare functie primeste
un `Builder` (`b`) si adauga geometrie direct in `b.bm`, intorcand fetele noi
(sau un dict cu mai multe seturi, cand piesa are mai multe roluri de slot --
piatra plina vs. gol GLOW). Se importa cu exec, la fel ca `dio_lib.py`:

    exec(open(r"tools/blender/jodhpur_shapes.py").read())

sau, din `run_build.py`, un build script poate face
    exec(open(os.path.join(HERE, "jodhpur_shapes.py")).read())
inainte de-a folosi functiile (vezi `build_jodhpur_pilot.py`, care il incarca
asa la inceput).

Toate functiile sunt slot-aware (parametrul `slot`/`glow_slot`) si low-poly
(parametru `segments`/`n` explicit, nicio primitiva rotunda cu implicitul
Blender-ului -- CLAUDE.md: "cand creezi o primitiva in cod, seteaza-i
radial_segments/rings").

Contractul GLOW (brief regula 7): orice geometrie care trebuie sa fie
intunecata ziua si luminata noaptea NU poate sta in acelasi Builder ca piesa
care primeste clasa triplanara la integrare (motivul e documentat pe larg in
`build_jodhpur_pilot.py`, critica #3: un slot GLOW ramas in bmesh-ul unei
piese cu un singur material triplanar la integrare devine invizibil, pentru
ca triplanar ignora UV-ul). De-asta `arch_opening` primeste DOUA Builder-e
separate -- `b` (peretele plin, primeste `slot`) si `bg` (geamul retras,
primeste `glow_slot`) -- niciodata unul singur.
"""

import math
from mathutils import Vector, Matrix


# ---------------------------------------------------------------------------
# 1. arch_opening -- gol real intr-un perete, cu profil de arc
# ---------------------------------------------------------------------------

def _arch_profile(style, half_w, rise, steps, point=0.2):
    """Puncte (lat, z) ale INTRADOSULUI arcului, de la piciorul stang (-half_w,
    0) la piciorul drept (half_w, 0), trecand prin cheie. `rise` e inaltimea
    cheii peste picioare (nu inaltimea totala a golului -- aia e pier_h+rise).

    - "round": semicerc adevarat (bolta romana/mogul rotunjita).
    - "pointed": doua arce de cerc care se intalnesc intr-un varf (ogiva --
      forma dominanta pe planse: ghanta_ghar, portile cetatii).
    - "cusped": ca "pointed", dar cu `lobes` festoane mici pe fiecare jumatate
      de arc (multifoil/scalop -- arcadele de chhatri si palat)."""
    pts = []
    if style == "round":
        for i in range(steps + 1):
            t = i / steps
            a = math.pi * (1.0 - t)
            pts.append((half_w * math.cos(a), rise * math.sin(a)))
        return pts
    if style == "pointed":
        # "two-centred": jumatatea STANGA a arcului e un arc de cerc centrat
        # pe axa, la DREAPTA (centru (+cx, 0)), care trece prin piciorul
        # stang (-half_w, 0) si urca pana la cheie (0, rise) -- si simetric
        # pentru jumatatea dreapta (centru (-cx, 0)). `cx` si `R` se deduc
        # din conditia ca cercul sa treaca prin ambele puncte:
        #   (half_w+cx)^2 = R^2         (trece prin piciorul stang)
        #   cx^2 + rise^2 = R^2         (trece prin cheie, x=0)
        # => (half_w+cx)^2 = cx^2 + rise^2 => cx = (rise^2 - half_w^2) / (2*half_w)
        cx = (rise * rise - half_w * half_w) / (2.0 * half_w)
        if cx < 0.0:
            # REPARAT (escaladare Opus, market_gate): cu rise < half_w (arc
            # TURTIT) formula de mai sus pune centrul la cx < 0, pe linia
            # nasterii, iar arcul parcurs de la pi la a_end trece prin pi/2
            # -- adica urca PESTE cheie (z = R > rise) si coboara inapoi:
            # profilul iese in "M". Un arc ascutit turtit ("drop arch")
            # are centrele SUB linia nasterii: pastram centrul pe partea
            # opusa (c >= 0, deci jumatatea stanga ramane strict la stanga
            # varfului cercului, x si z cresc monoton) si deducem zc < 0
            # din conditia ca cercul sa treaca prin picior si prin cheie:
            #   (half_w + c)^2 + zc^2 = c^2 + (rise - zc)^2
            # `point`: cat de ascutit e varful arcului turtit (0 = aproape
            # segmental, 0,4 = varf clar) -- centrul fiecarei jumatati sta la
            # point*half_w de ax, pe partea opusa.
            c = point * half_w
            zc = (rise * rise - (half_w + c) ** 2 + c * c) / (2.0 * rise)
            R = math.hypot(half_w + c, zc)
            a_start = math.atan2(-zc, -half_w - c)
            a_end = math.atan2(rise - zc, -c)
            for i in range(steps + 1):
                t = i / steps
                a = a_start + (a_end - a_start) * t
                pts.append((c + R * math.cos(a), zc + R * math.sin(a)))
            pts[0] = (-half_w, 0.0)
            pts[-1] = (0.0, rise)
            right = [(-x, z) for x, z in reversed(pts[:-1])]
            return pts + right
        R = math.hypot(half_w + cx, 0.0)
        # unghiul de start (la piciorul stang, vazut din centrul +cx) si cel
        # de la cheie (x=0, vazut din acelasi centru) -- ambele masurate
        # standard (0 = spre +X din centru).
        a_start = math.atan2(0.0, -half_w - cx)      # piciorul stang
        a_end = math.atan2(rise, 0.0 - cx)            # cheia
        for i in range(steps + 1):
            t = i / steps
            a = a_start + (a_end - a_start) * t
            pts.append((cx + R * math.cos(a), R * math.sin(a)))
        # jumatatea dreapta: oglindirea in X a primei jumatati, parcursa
        # invers (cheie -> piciorul drept), ca sa continue acelasi sens
        right = [(-x, z) for x, z in reversed(pts[:-1])]
        pts = pts + right
        return pts
    if style == "cusped":
        base = _arch_profile("pointed", half_w, rise, steps)
        lobes = 3
        out = []
        n = len(base)
        for i, (x, z) in enumerate(base):
            t = i / (n - 1)
            # festoanele scad spre picioare si spre cheie (t=0/0.5/1), ca sa
            # nu rupa continuitatea acolo -- un sin cu `lobes` perioade pe
            # fiecare jumatate, amortizat la capete
            half = t if t <= 0.5 else 1.0 - t
            wobble = math.sin(t * lobes * math.pi * 2.0) * 0.05 * min(1.0, half * 3.0)
            # scobim usor spre interiorul golului (radial), nu doar pe Z --
            # aproximam cu o reducere radiala fata de centrul geometric
            cx0, cz0 = 0.0, rise * 0.35
            dx, dz = x - cx0, z - cz0
            d = math.hypot(dx, dz) or 1e-6
            scale = 1.0 - wobble
            out.append((cx0 + dx * scale, cz0 + dz * scale))
        return out
    raise ValueError("stil de arc necunoscut: " + style)


def _arch_band(b, center, w, h, pier_h, slot, style, steps, rotation,
               band_w, band_t):
    """Banda solida (jgheab) care urmareste conturul unui arc, FARA umplutura
    intre picioare -- coloana stanga, arcul, coloana dreapta, ca un profil
    dreptunghiular maturat de-a lungul conturului. Folosita de `arch_opening
    (open=True)` pentru colonade deschise (`arcade(glass=False)`, `chhatri`)."""
    cx, cy, cz = center
    half_w = w * 0.5
    rise = max(h - pier_h, 0.05)

    def rot_pt(x, y, z):
        p = Vector((x, y, z))
        if rotation is not None:
            m = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            p = m @ p
        return (cx + p.x, cy + p.y, cz + p.z)

    profile = _arch_profile(style, half_w, rise, steps)
    centerline = [(-half_w, pier_h * 0.5)]  # capatul stang, la mijlocul picioarelor (coloana o acopera)
    centerline += [(x, pier_h + z) for x, z in profile]
    centerline += [(half_w, pier_h * 0.5)]

    faces = []
    hw_band = band_w * 0.5
    for i in range(len(centerline) - 1):
        x0, z0 = centerline[i]
        x1, z1 = centerline[i + 1]
        dx, dz = x1 - x0, z1 - z0
        ln = math.hypot(dx, dz) or 1e-6
        nx, nz = -dz / ln, dx / ln  # normala in planul XZ local (spre intrados)
        a0 = (x0 - nx * hw_band, z0 - nz * hw_band)  # intrados (spre interiorul golului)
        a1 = (x0 + nx * hw_band, z0 + nz * hw_band)  # extrados (spre exterior)
        b0 = (x1 - nx * hw_band, z1 - nz * hw_band)
        b1 = (x1 + nx * hw_band, z1 + nz * hw_band)
        # fata (spre +Y local) si spatele benzii -- doua fasii plate
        for y_val, flip in ((band_t * 0.5, False), (-band_t * 0.5, True)):
            quad = (a0, b0, b1, a1) if not flip else (a1, b1, b0, a0)
            pts = [rot_pt(x, y_val, z) for x, z in quad]
            faces.append(b.bm.faces.new(tuple(b.bm.verts.new(p) for p in pts)))
        # intradosul (fata dinspre interiorul golului) si extradosul (fata
        # dinspre exterior), unind fata cu spatele -- inchid banda ca solid
        intrados = [rot_pt(a0[0], band_t * 0.5, a0[1]), rot_pt(a1[0], band_t * 0.5, a1[1])]
        for pts, flip3 in (
            ((rot_pt(a0[0], band_t * 0.5, a0[1]), rot_pt(b0[0], band_t * 0.5, b0[1]),
              rot_pt(b0[0], -band_t * 0.5, b0[1]), rot_pt(a0[0], -band_t * 0.5, a0[1])), True),
            ((rot_pt(a1[0], band_t * 0.5, a1[1]), rot_pt(b1[0], band_t * 0.5, b1[1]),
              rot_pt(b1[0], -band_t * 0.5, b1[1]), rot_pt(a1[0], -band_t * 0.5, a1[1])), False),
        ):
            pts2 = tuple(reversed(pts)) if flip3 else pts
            faces.append(b.bm.faces.new(tuple(b.bm.verts.new(p) for p in pts2)))
    for f in faces:
        f[b.slot] = slot
    return {"stone": faces, "glass": []}


def arch_opening(b, bg, center, w, h, pier_h, wall_t, slot, glow_slot,
                  style="pointed", reveal=0.18, glass_depth=0.06,
                  steps=10, rotation=None, glass=True, panel_w=None,
                  panel_h=None, panel_z0=0.0, open=False, band_w=None, point=0.2):
    """Panou de perete cu un GOL REAL, cu capac de arc, taiat prin el -- pe
    fata +Y locala a lui `center` (rotit cu `rotation` daca peretele nu
    priveste spre +Y).

    E functia centrala a vocabularului -- fara ea totul degenereaza in cutii
    tesite (exact bug-ul pilotului respins). **Important:** functia
    construieste ea insasi panoul de perete din jurul golului (nu presupune
    ca exista deja o cutie plina alaturata) -- o cutie plina separata,
    nemodificata, ar ramane deasupra firidei si ar ascunde golul complet din
    exterior (aceeasi capcana documentata in `build_jodhpur_pilot.py`, critica
    #3: "o fata plina suprapusa peste un gol nu se vede niciodata"). Deci
    apelantul NU mai adauga propriul perete plin in dreptul golului -- ii cere
    lui `arch_opening` panoul (`panel_w`/`panel_h`), care iese deja perforat.

    Geometria produsa in `b` (`slot`):
      1. panoul PLIN, ca un inel intre dreptunghiul exterior (panel_w x
         panel_h, centrat pe `center`, extins de la `panel_z0`) si conturul
         golului, la grosimea `wall_t` -- fata din fata (spre +Y local).
      2. fata din SPATE, acelasi inel (peretele e un solid, nu o folie).
      3. intradosul: peretii golului pe TOATA grosimea (golul trece prin
         perete; panoul e un solid inchis). `reveal` fixeaza doar adancimea
         placii GLOW fata de fata exterioara (firida vizibila in fata ei).
    `bg` (Builder SEPARAT, obligatoriu -- vezi nota din capul fisierului)
    primeste placa GLOW retrasa in spatele firidei, pe `glow_slot`.
    `glass=False` omite placa (pentru arcade complet deschise, unde nu exista
    fund -- `arcade`/`chhatri`).

    `w`/`h` sunt latimea si inaltimea TOTALA a golului; `pier_h` e inaltimea
    picioarelor drepte de sub arc (restul e alocat arcului). `wall_t` e
    grosimea peretelui. `panel_w`/`panel_h` (implicit `w*2.2`/`h*1.35`)
    dimensioneaza panoul plin din jurul golului -- suficient de mare cat sa
    nu iasa vreo geometrie exterioara prin margine.

    `open=True` schimba total regimul: NU mai construieste panoul plin (nu
    exista perete intre arce -- colonada deschisa a lanternei/chhatri-ului),
    ci doar o BANDA subtire care urmareste conturul golului (intrados +
    extrados + capete), ca un jgheab de piatra -- arcul insusi, fara umplutura
    intre picioare. `band_w` (implicit `wall_t*0.4`) e latimea benzii.

    Intoarce dict {"stone": [fete], "glass": [fete]}."""
    cx, cy, cz = center
    half_w = w * 0.5
    rise = max(h - pier_h, 0.05)

    if open:
        return _arch_band(b, center, w, h, pier_h, slot, style=style,
                          steps=steps, rotation=rotation,
                          band_w=band_w if band_w is not None else wall_t * 0.4,
                          band_t=wall_t)
    panel_w = panel_w if panel_w is not None else w * 2.2
    panel_h = panel_h if panel_h is not None else h * 1.35 + panel_z0

    def rot_pt(x, y, z):
        p = Vector((x, y, z))
        if rotation is not None:
            m = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            p = m @ p
        return (cx + p.x, cy + p.y, cz + p.z)

    profile = _arch_profile(style, half_w, rise, steps, point=point)
    hole = arch_hole_contour(style, w, h, pier_h, steps, profile=profile)

    hw_panel = panel_w * 0.5
    panel_z1 = panel_z0 + panel_h

    inner_edge = wall_t * 0.5                    # fata exterioara a peretelui
    back_edge = -wall_t * 0.5                     # fata din spate
    reveal_edge = inner_edge - reveal             # unde incepe firida (retras)
    glass_edge = reveal_edge - glass_depth        # unde sta geamul

    # REPARAT (escaladare Opus, market_gate): versiunea veche umplea panoul
    # din 4 DREPTUNGHIURI pe bounding-box-ul golului (sus/jos/stanga/dreapta)
    # -- colturile dintre arc si dreptunghi (timpanele) ramaneau GOALE pe
    # ambele fete, deci silueta golului era mereu dreptunghiulara, iar arcul
    # exista doar ca banda de firida (`reveal`) -- golul in "T" de pe planse.
    # Acum panoul e un SOLID INCHIS (varfuri partajate, manifold): prisma
    # extrudata pe Y a poligonului concav "dreptunghi minus gol". Golul E
    # arcul, pe toata grosimea (intradosul e fata laterala a prismei).
    #   - gol care atinge baza panoului (usa, poarta): un singur poligon in
    #     "U" intors;
    #   - gol suspendat (fereastra): doua poligoane, stanga/dreapta de axa
    #     x=0 (un poligon cu gaura nu e un ngon simplu).
    # Fetele concave din fata/spate se triunghiuleaza explicit (polyfill).
    hz0 = hole[0][1]
    touches = abs(hz0 - panel_z0) < 1e-4
    left_arc = [p for p in hole if p[0] <= 1e-9]          # (-hw,hz0) .. cheia
    if touches:
        polys = [[(-hw_panel, panel_z0)] + hole + [(hw_panel, panel_z0),
                                                    (hw_panel, panel_z1),
                                                    (-hw_panel, panel_z1)]]
    else:
        left = ([(0.0, panel_z0), (0.0, hz0)] + left_arc +
                [(0.0, panel_z1), (-hw_panel, panel_z1), (-hw_panel, panel_z0)])
        # left_arc incepe la (-hw, hz0): lipim baza golului (0,hz0)->(-hw,hz0)
        right = [(-x, z) for x, z in reversed(left)]
        polys = [left, right]

    stone_faces = []
    y_front = inner_edge
    y_back = back_edge
    for poly in polys:
        # curata dublurile consecutive (pier_h = 0, cheia pe x=0 etc.)
        clean = []
        for p in poly:
            if not clean or math.hypot(p[0] - clean[-1][0], p[1] - clean[-1][1]) > 1e-5:
                clean.append(p)
        if math.hypot(clean[0][0] - clean[-1][0], clean[0][1] - clean[-1][1]) <= 1e-5:
            clean.pop()
        fr = [b.bm.verts.new(rot_pt(x, y_front, z)) for x, z in clean]
        bk = [b.bm.verts.new(rot_pt(x, y_back, z)) for x, z in clean]
        m = len(clean)
        # capacele concave: ear-clipping propriu in 2D. `bmesh.ops.triangulate`
        # pe ngon-ul concav (BEAUTY) a pus triunghiuri PESTE gol (masurat:
        # 5 triunghiuri de capac cu centrul in gol) -- poarta iesea plina.
        caps = []
        for i0, i1, i2 in _ear_clip(clean):
            caps.append(b.bm.faces.new((fr[i0], fr[i1], fr[i2])))
            caps.append(b.bm.faces.new((bk[i2], bk[i1], bk[i0])))
        sides = []
        for i in range(m):
            j = (i + 1) % m
            sides.append(b.bm.faces.new((fr[i], bk[i], bk[j], fr[j])))
        stone_faces += caps + sides

    if glass:
        # placa GLOW in gol, la adancimea firidei: acopera tot conturul
        # golului (golul trece acum prin toata grosimea -- nu mai lasam un
        # inel prin care se vede prin perete). Rama o face firida.
        #
        # REVIZUIRE (contract vizual incalcat, palace_facade_b: ferestrele
        # nu araratau NICIODATA sticla inchisa, doar conturul de piatra):
        # masurat direct normalele fetei GLOW exportate -- ieseau (-1,0,0)
        # in loc de (+1,0,0), adica intoarse SPRE interiorul zidului, opusul
        # camerei -- randate ca fete nelumnate/negre, indistincte de piatra
        # umbrita. Cauza: `to_object()` din `dio_lib.py` (comun, nu se
        # modifica aici) cheama necondiitonat `recalc_face_normals` pe TOT
        # bmesh-ul la creare -- pentru o placa SINGURA, izolata (fara alta
        # geometrie manifold cu care sa fie consistenta), euristica de
        # recalculare alege o directie arbitrara, verificat empiric ca iese
        # mereu spre interior aici, indiferent de ordinea punctelor sau de
        # un `normal_flip()` facut INAINTE (recalc il suprascrie oricum).
        # Fix: geamul nu mai e o singura fata deschisa, ci o PLACA SUBTIRE
        # inchisa (fata + spate + laturi, ca peretele STONE de mai sus) --
        # un solid, chiar minuscul, pe care `recalc_face_normals` il
        # orienteaza corect si consistent (are geometrie manifold reala de
        # care sa se lege), plus fata din spate ramane vizibila prin gol
        # daca vreodata camera ajunge in spatele peretelui.
        glass_t = min(glass_depth * 0.5, 0.02)
        gy_front = glass_edge + glass_t
        gy_back = glass_edge - glass_t
        gfr = [bg.bm.verts.new(rot_pt(x, gy_front, z)) for x, z in hole]
        gbk = [bg.bm.verts.new(rot_pt(x, gy_back, z)) for x, z in hole]
        n = len(hole)
        glass_faces = [bg.bm.faces.new(tuple(gfr)), bg.bm.faces.new(tuple(reversed(gbk)))]
        for i in range(n):
            j = (i + 1) % n
            glass_faces.append(bg.bm.faces.new((gfr[i], gbk[i], gbk[j], gfr[j])))
        for f in glass_faces:
            f[bg.slot] = glow_slot
    else:
        glass_faces = []

    stone_faces = [f for f in stone_faces if f.is_valid]
    for f in stone_faces:
        f[b.slot] = slot
    return {"stone": stone_faces, "glass": glass_faces}


def _ear_clip(poly):
    """Triunghiulare prin ear-clipping a unui poligon 2D SIMPLU (concav
    permis), lista (x, z). Intoarce triplete de indici, in sensul
    poligonului."""
    n = len(poly)
    area = 0.0
    for i in range(n):
        x0, z0 = poly[i]
        x1, z1 = poly[(i + 1) % n]
        area += x0 * z1 - x1 * z0
    sgn = 1.0 if area > 0 else -1.0

    def cross(o, a, c):
        return (a[0] - o[0]) * (c[1] - o[1]) - (a[1] - o[1]) * (c[0] - o[0])

    def inside(p, a, c, d):
        c1, c2, c3 = cross(a, c, p) * sgn, cross(c, d, p) * sgn, cross(d, a, p) * sgn
        return c1 >= -1e-12 and c2 >= -1e-12 and c3 >= -1e-12

    idx = list(range(n))
    out = []
    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        best = None
        for k in range(len(idx)):
            ia, ib, ic = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, c, d = poly[ia], poly[ib], poly[ic]
            if cross(a, c, d) * sgn <= 1e-12:
                continue
            if any(inside(poly[j], a, c, d) for j in idx
                   if j not in (ia, ib, ic) and poly[j] not in (a, c, d)):
                continue
            # prefera urechea cu unghiul cel mai aproape de 90 -> fara triunghiuri-ac
            ab = math.hypot(a[0] - c[0], a[1] - c[1])
            cb = math.hypot(d[0] - c[0], d[1] - c[1])
            q = cross(a, c, d) * sgn / max(ab * cb, 1e-12)
            if best is None or q > best[0]:
                best = (q, k)
        if best is None:
            break
        k = best[1]
        out.append((idx[k - 1], idx[k], idx[(k + 1) % len(idx)]))
        idx.pop(k)
    if len(idx) == 3:
        out.append(tuple(idx))
    return out


def arch_hole_contour(style, w, h, pier_h, steps=10, profile=None, point=0.2):
    """Conturul golului unui arc, ca lista (x, z) in planul peretelui, de la
    baza ambrazurii stangi (-w/2, 0), in sus pe ambrazura, peste arc, si in
    jos pe ambrazura dreapta pana la (w/2, 0) -- deschis jos. Fara dubluri
    consecutive. Folosit de `arch_opening` si de piesele care pun relief pe
    conturul golului (arhivolta, alfiz)."""
    half_w = w * 0.5
    rise = max(h - pier_h, 0.05)
    if profile is None:
        profile = _arch_profile(style, half_w, rise, steps, point=point)
    raw = [(-half_w, 0.0), (-half_w, pier_h)]
    raw += [(x, pier_h + z) for x, z in profile]
    raw += [(half_w, pier_h), (half_w, 0.0)]
    out = []
    for p in raw:
        if not out or math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) > 1e-5:
            out.append(p)
    return out


# ---------------------------------------------------------------------------
# 2. arcade -- rand de arce pe piloni
# ---------------------------------------------------------------------------

def arcade(b, bg, p1, p2, n, opening_h, pier_h, pier_w, wall_t, slot,
           glow_slot, style="pointed", glass=False, base_z=0.0):
    """Rand de `n` goluri in arc de-a lungul segmentului p1->p2, cu piloni
    intre ele. Pilonii sunt cutii pline (`slot`); fiecare gol foloseste
    `arch_opening`. `glass=False` (implicit): arcada e complet deschisa --
    coloane + arce, fara fund (chhatri, galerii de fantana). `glass=True`:
    fiecare gol primeste geam retras (arcade oarbe pe fatada palatului).

    p1/p2 sunt punctele de la BAZA capetelor arcadei (nu centrul pilonilor).
    Foloseste orientarea segmentului ca `rotation` pentru `arch_opening` --
    arcada poate sta pe orice latura, nu doar pe +Y."""
    a, c = Vector(p1), Vector(p2)
    d = c - a
    length = d.length
    axis = d.normalized() if length > 1e-6 else Vector((1.0, 0.0, 0.0))
    # `rotation` care duce +Y local pe `axis`: unghiul din jurul lui Z intre
    # (0,1,0) si `axis`.
    ang = math.atan2(axis.x, axis.y)  # atan2(x,y): 0 cand axis==+Y
    rot = Matrix.Rotation(ang, 3, "Z")

    bay = length / n
    stone_faces = []
    glass_faces = []
    for i in range(n):
        t = (i + 0.5) / n
        center = a + axis * (bay * i + bay * 0.5)
        pier_c = a + axis * (bay * i)
        if i > 0:
            faces = b.box((pier_c.x, pier_c.y, base_z + pier_h * 0.5),
                          (pier_w, wall_t, pier_h), slot)
            stone_faces += list(faces)
        res = arch_opening(b, bg, (center.x, center.y, base_z), bay - pier_w,
                           opening_h, pier_h, wall_t, slot, glow_slot,
                           style=style, rotation=rot, glass=glass,
                           panel_w=bay, panel_h=opening_h * 1.12,
                           open=not glass, band_w=wall_t * 0.5)
        stone_faces += res["stone"]
        glass_faces += res["glass"]
    # piloni de capat
    for end in (a, c):
        faces = b.box((end.x, end.y, base_z + pier_h * 0.5),
                      (pier_w, wall_t, pier_h), slot)
        stone_faces += list(faces)
    return {"stone": stone_faces, "glass": glass_faces}


# ---------------------------------------------------------------------------
# 3. dome -- cupola (hemisferica sau usor bombata/onion), cu tambur si finial
# ---------------------------------------------------------------------------

def dome(b, center, radius, slot, drum_h=0.0, drum_r=None, profile="hemisphere",
         segments=12, ribs=0, rib_slot=None, lotus_ring=True, finial=True,
         finial_h=None):
    """Cupola pe axa Z, deasupra lui `center` (baza tamburului).

    `profile`:
      - "hemisphere": emisfera curata, `revolve` cu profil semicircular.
      - "onion": bombeaza peste raza (umar larg sub varf), profilul clasic
        mogul -- se largeste, apoi se ingusteaza brusc spre un gat ingust
        inainte de finial.

    `drum_h`/`drum_r`: tamburul cilindric de sub cupola (0 = cupola direct pe
    perete). `ribs`: numar de nervuri verticale late (0 = cupola neteda) --
    geometrie, nu textura (CLAUDE.md regula rosturilor). `lotus_ring`: inel
    ingust la baza cupolei (banda "lotus" tipica). `finial`: kalash -- tija
    subtire cu un bulb, in varf.

    Intoarce lista de fete (un singur slot; nervurile folosesc `rib_slot` daca
    dat, altfel `slot`)."""
    cx, cy, cz = center
    rib_slot = rib_slot or slot
    faces = []

    z = cz
    if drum_h > 0.0:
        dr = drum_r if drum_r is not None else radius * 0.92
        faces += list(b.cylinder((cx, cy, z + drum_h * 0.5), dr, drum_h, slot,
                                 segments=segments, axis="Z"))
        z += drum_h
        radius = dr * 1.04  # cupola iese usor peste tambur (streasina mica)

    if lotus_ring:
        faces += list(b.frustum((cx, cy, z + 0.06), radius * 1.1, radius * 0.98,
                                0.12, slot, segments=segments, axis="Z"))
        z += 0.12

    if profile == "hemisphere":
        # profil de sfert de cerc, de la ecuator (r=radius, z=0) pana la pol
        # (r=0, z=radius) -- k creste, unghiul creste, RAZA SCADE spre varf
        # (nu invers: un profil care nu ajunge la 0 lasa `revolve` sa deschida
        # un tub fara capac, cupola devine invizibila din exterior -- exact
        # bug-ul gasit la prima randare a plansei de vocabular).
        n_rings = 6
        prof = [(radius * math.cos(math.pi * 0.5 * k / n_rings),
                radius * math.sin(math.pi * 0.5 * k / n_rings))
               for k in range(n_rings + 1)]
        apex_r = radius * 0.14
    else:  # onion
        # profil manual: bulb care iese peste `radius`, apoi un gat ingust,
        # inchis la 0 in varf (altfel `revolve` lasa un tub deschis sus --
        # acelasi bug gasit la hemisfera).
        prof = [
            (radius * 0.55, 0.0),
            (radius * 1.0, radius * 0.30),
            (radius * 0.92, radius * 0.62),
            (radius * 0.46, radius * 0.86),
            (radius * 0.18, radius * 0.98),
            (0.0, radius * 1.08),
        ]
        apex_r = radius * 0.14

    faces += list(b.revolve(prof, slot, segments=segments, origin=(cx, cy, z),
                            cap_bottom=False))
    dome_top_z = z + prof[-1][1]

    if ribs > 0:
        # nervuri: fasii verticale LATE (geometrie, nu textura) suprapuse pe
        # cupola, ca niste meridian-uri -- late, nu subtiri: citesc de la
        # distanta cerintei brief-ului ("ribbed dome").
        rib_w = (2.0 * math.pi * radius) / ribs * 0.32
        rib_h_extra = 0.03
        for i in range(ribs):
            a = 2.0 * math.pi * i / ribs
            # inaltimea nervurii aproximeaza silueta cupolei intre baza si varf
            n_seg = 5
            pts = []
            for k in range(n_seg + 1):
                t = k / n_seg
                # interpoleaza raza din profilul cupolei
                idx = min(int(t * (len(prof) - 1)), len(prof) - 2)
                r0, z0 = prof[idx]
                r1, z1 = prof[idx + 1]
                loc = t * (len(prof) - 1) - idx
                r = r0 + (r1 - r0) * loc
                zz = z0 + (z1 - z0) * loc
                pts.append((r + rib_h_extra, zz))
            path = [(cx + math.cos(a) * r, cy + math.sin(a) * r, z + zz) for r, zz in pts]
            faces += list(b.sweep(path, rib_w * 0.5, rib_slot, segments=5,
                                  dome_end=False, cap_start=False)) if hasattr(b, "sweep") else []

    if finial:
        fh = finial_h if finial_h is not None else radius * 1.1
        stem = list(b.cylinder((cx, cy, dome_top_z + fh * 0.35), apex_r * 0.22,
                               fh * 0.7, slot, segments=6, axis="Z"))
        bulb = list(b.revolve(
            [(apex_r * 0.05, 0.0), (apex_r * 0.6, fh * 0.10), (apex_r * 0.4, fh * 0.20),
             (0.0, fh * 0.28)],
            slot, segments=8, origin=(cx, cy, dome_top_z + fh * 0.68), cap_bottom=True))
        faces += stem + bulb

    return faces


# ---------------------------------------------------------------------------
# 4. chhatri -- pavilion deschis: coloane + arce + chajja + cupola + finial
# ---------------------------------------------------------------------------

def chhatri(b, bg, center, n_columns, radius, col_h, slot, glow_slot,
            col_r=0.14, dome_radius=None, arch_style="cusped", chajja_out=0.35,
            segments_dome=10):
    """Chioscul cu cupola: `n_columns` (4/6/8) coloane pe cerc, arce intre ele
    (deschise, fara geam), o cornisa/chajja subtire proeminenta deasupra
    arcelor, apoi o cupola mica + finial. Piesa recurenta pe fiecare
    reper -- lanterna turnului, colturile cenotafului, galeriile fantanii.

    Nu are podea/tavan propriu (se aseaza direct pe tier-ul care il poarta).
    Intoarce {"stone": [...], "glass": []} (glass ramane gol -- arcadele sunt
    deschise, dar semnatura e consistenta cu `arcade`/`arch_opening`)."""
    cx, cy, cz = center
    dome_radius = dome_radius if dome_radius is not None else radius * 0.62
    stone = []

    positions = []
    for i in range(n_columns):
        a = 2.0 * math.pi * i / n_columns
        positions.append((cx + radius * math.cos(a), cy + radius * math.sin(a)))
    for px, py in positions:
        stone += list(b.cylinder((px, py, cz + col_h * 0.5), col_r, col_h,
                                 slot, segments=8, axis="Z"))

    # arcele: intre fiecare pereche de coloane vecine, un `arch_opening` FARA
    # geam (deschis), orientat pe coarda dintre ele
    for i in range(n_columns):
        p0 = Vector((positions[i][0], positions[i][1], cz))
        p1 = Vector((positions[(i + 1) % n_columns][0],
                     positions[(i + 1) % n_columns][1], cz))
        mid = (p0 + p1) * 0.5
        chord = (p1 - p0)
        chord_len = chord.length
        axis = chord.normalized() if chord_len > 1e-6 else Vector((1, 0, 0))
        ang = math.atan2(axis.x, axis.y)
        rot = Matrix.Rotation(ang, 3, "Z")
        res = arch_opening(b, bg, (mid.x, mid.y, cz), max(chord_len - col_r * 1.6, 0.3),
                           col_h * 0.86, col_h * 0.30, col_r * 1.7, slot, glow_slot,
                           style=arch_style, rotation=rot, glass=False, reveal=0.02,
                           open=True, band_w=col_r * 1.3)
        stone += res["stone"]

    # chajja: cornisa subtire iesita peste arce, pe tot perimetrul
    stone += list(b.frustum((cx, cy, cz + col_h + 0.05), radius + chajja_out,
                            radius + chajja_out * 0.55, 0.10, slot,
                            segments=n_columns * 2, axis="Z"))
    # placa de plafon a pavilionului, sub cupola
    stone += list(b.cylinder((cx, cy, cz + col_h + 0.12), radius * 0.7, 0.06,
                             slot, segments=n_columns * 2, axis="Z"))
    stone += dome(b, (cx, cy, cz + col_h + 0.16), dome_radius, slot,
                  profile="onion", segments=segments_dome, lotus_ring=True,
                  finial=True, finial_h=dome_radius * 1.3)
    return {"stone": stone, "glass": []}


# ---------------------------------------------------------------------------
# 5. balustrade / railing pe consola + balcony_band
# ---------------------------------------------------------------------------

def balustrade(b, p1, p2, height, slot, post_step=0.55, post_t=0.06,
               rail_t=0.07, merlon_w=0.20, merlon_gap=0.16):
    """Parapet plin jos + creneluri mici dese sus, intre p1 si p2 (puncte de
    BAZA) -- forma din decupare pentru balconul turnului si terasele caselor,
    distincta de `dio_lib.railing` (care e doar stalpi+lise, pentru scari).

    Buget mic: un parapet plin (o singura cutie lunga) + un rand de merloane
    mici, nu geometrie per-metru."""
    a, c = Vector(p1), Vector(p2)
    d = c - a
    length = d.length
    if length < 1e-6:
        return []
    axis = d.normalized()
    mid = (a + c) * 0.5
    ang = math.atan2(axis.x, axis.y)
    rot = Matrix.Rotation(ang, 3, "Z")
    faces = []
    plinth_h = height * 0.55
    faces += list(b.box((mid.x, mid.y, a.z + plinth_h * 0.5),
                        (post_t * 2.2, length, plinth_h), slot, rotation=rot))
    n = max(int(length / (merlon_w + merlon_gap)), 1)
    step = length / n
    for i in range(n):
        t = (i + 0.5) / n
        p = a + d * t
        faces += list(b.box((p.x, p.y, a.z + plinth_h + (height - plinth_h) * 0.5),
                            (post_t * 2.4, merlon_w, height - plinth_h), slot,
                            rotation=rot))
    return faces


def railing_on_brackets(b, p1, p2, height, slot, bracket_slot=None,
                        post_step=0.5, post_t=0.05, rail_t=0.06,
                        bracket_step=1.1, bracket_out=0.30):
    """Balustrada pe o platforma in consola: `dio_lib.railing` de-a lungul
    p1->p2, plus console triunghiulare dedesubt la pas regulat -- balconul
    ceasului si terasele caselor ies din perete pe console vizibile, nu
    plutesc."""
    bracket_slot = bracket_slot or slot
    faces = list(b.railing(p1, p2, height, post_step, post_t, rail_t, slot, rails=2))
    a, c = Vector(p1), Vector(p2)
    d = c - a
    length = d.length
    if length > 1e-6:
        axis = d.normalized()
        n = max(int(length / bracket_step), 1)
        for i in range(n + 1):
            t = i / n
            p = a + d * t
            faces += list(b.box((p.x, p.y, a.z - bracket_out * 0.4),
                                (0.10, 0.10, bracket_out * 0.8), bracket_slot))
    return faces


def balcony_band(b, center, radius_in, radius_out, h, slot, segments=16,
                 crenellated=False, merlon_count=12, merlon_h=0.0,
                 merlon_style="rectangular"):
    """Banda circulara iesita in consola in jurul unui tier (balconul
    turnului). `crenellated=True` adauga un rand de merloane deasupra --
    varianta compacta a lui `balustrade` pentru piese pe plan circular/
    octogonal (unde segmentarea pe cerc e mai simpla decat pe poligon)."""
    cx, cy, cz = center
    faces = list(b.frustum((cx, cy, cz + h * 0.5), radius_out, radius_in, h,
                           slot, segments=segments, axis="Z"))
    if crenellated:
        mh = merlon_h if merlon_h > 0.0 else h * 1.4
        for i in range(merlon_count):
            a = 2.0 * math.pi * (i + 0.5) / merlon_count
            gx, gy = math.cos(a) * radius_out * 0.94, math.sin(a) * radius_out * 0.94
            if i % 2 == 0:
                faces += list(crenel_merlon(b, (gx, gy, cz + h), mh, slot,
                                            width=radius_out * 0.5,
                                            style=merlon_style,
                                            rotation=Matrix.Rotation(a, 3, "Z")))
    return faces


# ---------------------------------------------------------------------------
# 6. chajja / cornice -- consola subtire cu fata inferioara inclinata
# ---------------------------------------------------------------------------

def chajja(b, center, w, d, slot, thickness=0.10, slope=0.35, segments=1,
          rotation=None):
    """Cornisa/streasina subtire proeminenta, in jurul unui tier dreptunghiular
    (sau ca banda liniara pe o fatada). Fata de SUS e plata (orizontala), fata
    de JOS coboara spre exterior cu `slope` (fractie din `thickness`) -- forma
    caracteristica indo-saracenica, vizibila ca umbra sub streasina.

    Se construieste ca o prisma trapezoidala extrudata pe X (latimea `w`),
    adanca `d` spre +Y local (`rotation` roteste ansamblul, ca la
    `arch_opening` -- o cornisa pe fata +X are nevoie de `rotation` care duce
    +Y local pe +X), nu ca o simpla cutie -- diferenta e exact profilul
    inclinat de dedesubt, altfel citeste ca o banda plata, nu ca streasina."""
    # Pana solida cu 6 varfuri: un dreptunghi SUS (plat, +Y = spre exterior),
    # si dedesubt doua muchii la inaltimi diferite -- exterioara (+Y) mai
    # joasa cu `drop`, interioara (-Y, lipita de perete) la z=0. Ca o cutie
    # careia i s-a taiat un pana din muchia de jos-exterior.
    cx, cy, cz = center
    hw, hd = w * 0.5, d * 0.5
    drop = thickness * slope

    def V(x, y, z):
        p = Vector((x, y, z))
        if rotation is not None:
            m = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            p = m @ p
        return b.bm.verts.new((cx + p.x, cy + p.y, cz + p.z))

    # sus: patru colturi la z=thickness
    t_ext_l, t_ext_r = V(-hw, hd, thickness), V(hw, hd, thickness)
    t_int_l, t_int_r = V(-hw, -hd, thickness), V(hw, -hd, thickness)
    # jos-exterior: coboara doar cu `drop` (nu pana la 0) -- de-aici iese
    # muchia inclinata caracteristica
    b_ext_l, b_ext_r = V(-hw, hd, thickness - drop), V(hw, hd, thickness - drop)
    # jos-interior: la z=0, lipit de perete
    b_int_l, b_int_r = V(-hw, -hd, 0.0), V(hw, -hd, 0.0)

    faces = [
        b.bm.faces.new((t_ext_l, t_ext_r, t_int_r, t_int_l)),   # sus, plata
        b.bm.faces.new((b_ext_r, b_ext_l, b_int_l, b_int_r)),   # dedesubt, inclinata
        b.bm.faces.new((t_ext_l, t_ext_r, b_ext_r, b_ext_l)),   # muchia exterioara (fata vazuta de jos)
        b.bm.faces.new((t_int_r, t_int_l, b_int_l, b_int_r)),   # fata interioara, lipita de perete
        b.bm.faces.new((t_ext_l, t_int_l, b_int_l, b_ext_l)),   # capat -X
        b.bm.faces.new((t_ext_r, b_ext_r, b_int_r, t_int_r)),   # capat +X
    ]
    for f in faces:
        f[b.slot] = slot
    return faces


# ---------------------------------------------------------------------------
# 7. crenellation -- merloane rectangulare/rotunjite de-a lungul unei muchii
# ---------------------------------------------------------------------------

def crenel_merlon(b, center, height, slot, width=0.42, depth=None,
                  style="rectangular", rotation=None):
    """Un singur merlon (dinte de parapet). `style`: "rectangular" (cutie
    plina, zidurile de cetate) sau "rounded" (varf rotunjit, bastioanele --
    decuparea le arata crestate diferit de ziduri, brief §1.2)."""
    depth = depth if depth is not None else width
    if style == "rectangular":
        return list(b.box(center, (width, depth, height), slot, rotation=rotation))
    # rounded: cutie + capac semicilindric pe varf
    cx, cy, cz = center
    body_h = height * 0.7
    faces = list(b.box((cx, cy, cz - (height - body_h) * 0.5), (width, depth, body_h),
                       slot, rotation=rotation))
    cap_axis = "X" if depth >= width else "Y"
    faces += list(b.cylinder((cx, cy, cz + body_h * 0.5), min(width, depth) * 0.5,
                             max(width, depth), slot, segments=8, axis=cap_axis))
    return faces


def crenellation(b, p1, p2, height, slot, width=0.42, gap=0.34,
                 style="rectangular", z=None):
    """Rand de merloane de-a lungul p1->p2 (puncte de BAZA a crenelurilor,
    adica varful parapetului plin de dedesubt). Alterneaza solid/gol pe pas
    regulat -- `style` "rectangular" (ziduri, brief §1.2 fort_wall_segment) sau
    "rounded" (bastioane)."""
    a, c = Vector(p1), Vector(p2)
    d = c - a
    length = d.length
    if length < 1e-6:
        return []
    axis = d.normalized()
    ang = math.atan2(axis.x, axis.y)
    rot = Matrix.Rotation(ang, 3, "Z")
    step = width + gap
    n = max(int(length / step), 1)
    faces = []
    zc = z if z is not None else a.z
    for i in range(n + 1):
        t = i / n if n > 0 else 0.0
        p = a + d * t
        faces += crenel_merlon(b, (p.x, p.y, zc + height * 0.5), height, slot,
                               width=width, style=style, rotation=rot)
    return faces


# ---------------------------------------------------------------------------
# 8. solid_stair -- masa solida in trepte, cu obraz/dedesubt plin
# ---------------------------------------------------------------------------

def solid_stair(b, start, end, width, slot, tread_slot=None, n_steps=None,
                step_h=0.22, nosing=False, nosing_slot=None, cheek=True,
                cheek_slot=None):
    """Bloc SOLID in trepte, lipit de-un perete -- inlocuieste "treptele
    plutitoare" gasite in critica pilotului (blue_house_a): fiecare treapta
    e o cutie plina care coboara pana la treapta urmatoare (nu o placa
    subtire suspendata), plus un obraz/perete lateral inclinat care umple
    golul de sub scara, ca masa sa se citeasca dintr-o data ca "bloc care
    urca", nu ca o insiruire de dale separate.

    start/end: punctele de la mijlocul MUCHIEI SUPERIOARE a primei si ultimei
    trepte (la nivelul solului la `start`, la nivelul terasei la `end` -- doar
    XY conteaza pentru pozitie, Z vine din start.z/end.z). `width`: latimea
    scarii (perpendicular pe directia de urcare).

    `nosing=True` adauga o banda alba ingusta pe muchia fiecarei calcai
    (tread nosing alb-marginit, ca pe decupare) -- `nosing_slot` separat de
    `tread_slot`, geometrie mica suprapusa pe muchia din fata a fiecarei
    trepte.

    `cheek=True` adauga un perete plin triunghiular sub linia treptelor, pe
    ambele laturi, pana la sol -- ASTA e diferenta fata de o insiruire de
    cutii: fara el, se vede cerul/fundalul PE SUB scara, care citeste ca
    "trepte plutitoare" chiar daca fiecare treapta insasi e solida."""
    tread_slot = tread_slot or slot
    cheek_slot = cheek_slot or slot
    nosing_slot = nosing_slot or slot
    a, c = Vector(start), Vector(end)
    run = Vector((c.x - a.x, c.y - a.y, 0.0))
    run_len = run.length
    total_rise = c.z - a.z
    if n_steps is None:
        n_steps = max(int(round(abs(total_rise) / step_h)), 1)
    axis = run.normalized() if run_len > 1e-6 else Vector((0.0, 1.0, 0.0))
    perp = Vector((-axis.y, axis.x, 0.0))
    rise = total_rise / n_steps
    run_step = run_len / n_steps

    faces = []
    for k in range(n_steps):
        y0 = run_step * k
        y1 = run_step * (k + 1)
        z_top = a.z + rise * (k + 1)
        z_bottom = a.z          # SOLID pana la baza -- nu doar pana la treapta anterioara
        mid = a + axis * ((y0 + y1) * 0.5)
        step_h_full = z_top - z_bottom
        c_step = (mid.x, mid.y, z_bottom + step_h_full * 0.5)
        size = (width, run_step + 0.02, step_h_full)
        rot = Matrix((axis, perp, Vector((0, 0, 1)))).transposed()
        faces += list(b.box(c_step, size, tread_slot, rotation=rot))
        if nosing:
            nose_c = mid + Vector((0, 0, z_top - z_bottom)) * 0 + Vector((0, 0, 0))
            nose_pos = a + axis * y1
            faces += list(b.box((nose_pos.x, nose_pos.y, z_top - 0.015),
                                (width, 0.05, 0.03), nosing_slot, rotation=rot))

    if cheek:
        # obraz = pana SOLIDA de-o parte si de alta: fata exterioara urmeaza
        # linia treptelor (in trepte, ca creasta zidurilor din
        # `_stair_cheeks` la Machu Picchu), fata interioara e planul vertical
        # lipit de trepte (x = +-width/2), iar dedesubt/capetele inchid
        # solidul -- altfel se vede cerul PE SUB scara din lateral, exact
        # defectul "trepte plutitoare" din critica pilotului.
        t = 0.10
        for side in (-1.0, 1.0):
            inner_off = perp * (side * width * 0.5)
            outer_off = perp * (side * (width * 0.5 + t))
            outer_top = []
            inner_top = []
            for k in range(n_steps + 1):
                y = run_step * k
                z = a.z + rise * k + 0.02
                p_in = a + axis * y + inner_off
                p_out = a + axis * y + outer_off
                inner_top.append(b.bm.verts.new((p_in.x, p_in.y, z)))
                outer_top.append(b.bm.verts.new((p_out.x, p_out.y, z)))
            base_in0 = b.bm.verts.new((inner_top[0].co.x, inner_top[0].co.y, a.z))
            base_in1 = b.bm.verts.new((inner_top[-1].co.x, inner_top[-1].co.y, a.z))
            base_out0 = b.bm.verts.new((outer_top[0].co.x, outer_top[0].co.y, a.z))
            base_out1 = b.bm.verts.new((outer_top[-1].co.x, outer_top[-1].co.y, a.z))
            # fata exterioara: banda in trepte (urmeaza creasta)
            for k in range(n_steps):
                f = b.bm.faces.new((outer_top[k], outer_top[k + 1],
                                    inner_top[k + 1], inner_top[k]))
                f[b.slot] = cheek_slot
                faces.append(f)
            # fata verticala exterioara (dinspre afara, sub creasta in trepte)
            f = b.bm.faces.new(tuple([base_out0] + outer_top + [base_out1]))
            f[b.slot] = cheek_slot
            faces.append(f)
            # talpa (dedesubt, inchide solidul)
            f = b.bm.faces.new((base_in0, base_out0, base_out1, base_in1))
            f[b.slot] = cheek_slot
            faces.append(f)
            # cele doua capete (inceput/sfarsit al obrazului)
            f = b.bm.faces.new((base_in0, inner_top[0], outer_top[0], base_out0))
            f[b.slot] = cheek_slot
            faces.append(f)
            f = b.bm.faces.new((base_in1, base_out1, outer_top[-1], inner_top[-1]))
            f[b.slot] = cheek_slot
            faces.append(f)
    return faces


# ---------------------------------------------------------------------------
# 9. stepped_plinth -- soclu in trepte
# ---------------------------------------------------------------------------

def stepped_plinth(b, center, levels, slot, shape="box", segments=16):
    """Soclu in TREPTE: fiecare nivel mai ingust decat cel de dedesubt.
    `levels`: lista de (w_or_r, d_or_None, h) de jos in sus -- pentru
    `shape="box"`, (w, d, h); pentru `shape="round"`/"octagon", (r, h) (d
    ignorat). Folosit la cenotaf (soclu in trepte + scara centrala) si la
    orice tier care se ingusteaza in trepte discrete (nu taper continuu)."""
    cx, cy, cz = center
    z = cz
    faces = []
    for lvl in levels:
        if shape == "box":
            w, d, h = lvl
            faces += list(b.box((cx, cy, z + h * 0.5), (w, d, h), slot))
        else:
            r, h = lvl[0], lvl[-1]
            faces += list(b.cylinder((cx, cy, z + h * 0.5), r, h, slot,
                                     segments=segments, axis="Z"))
        z += lvl[-1]
    return faces


# ---------------------------------------------------------------------------
# masuratoarea unui gol de contract (poarta, tunel) -- ca GOL, nu AABB
# ---------------------------------------------------------------------------

def _clip_band(poly, axis, lo, hi):
    """Taie un poligon 2D (lista (a, b)) la banda lo <= p[axis] <= hi
    (Sutherland-Hodgman pe doua semiplane)."""
    def clip(pts, keep, inter):
        out = []
        n = len(pts)
        for i in range(n):
            p, q = pts[i], pts[(i + 1) % n]
            kp, kq = keep(p), keep(q)
            if kp:
                out.append(p)
            if kp != kq:
                out.append(inter(p, q))
        return out

    def at(p, q, v):
        t = (v - p[axis]) / ((q[axis] - p[axis]) or 1e-12)
        return (p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t)
    pts = clip(poly, lambda p: p[axis] >= lo, lambda p, q: at(p, q, lo))
    if pts:
        pts = clip(pts, lambda p: p[axis] <= hi, lambda p, q: at(p, q, hi))
    return pts


def measure_opening(objs, windows=((0.15, 1.8), (0.15, 5.0)), axis_x=0.0,
                    crown_half=0.3, crown_from=2.0, lateral="x"):
    """Golul unei porti masurat ca GOL (memoriile cota-de-contract-se-masoara-
    ca-gol, golul-se-masoara-pe-fereastra-lui): proiectia TRIUNGHIURILOR
    tuturor nodurilor pe planul portii (X lateral, Z sus; directia de mers
    e Y), in coordonate lume. `lateral="y"` pentru piesele cu fata pe +X
    (portile cetatii: latimea pe Y, mersul pe X).

    - pentru fiecare fereastra (z0, z1): latimea benzii libere care contine
      axul x = axis_x (0 daca ceva o blocheaza pe ax);
    - cheia: cel mai jos punct ocupat peste `crown_from`, in coloana
      |x - axis_x| <= crown_half.
    Intoarce ({(z0, z1): latime}, cheie)."""
    tris = []
    for o in objs:
        if o is None:
            continue
        mw = o.matrix_world
        me = o.data
        me.calc_loop_triangles()
        vs = [mw @ v.co for v in me.vertices]
        for lt in me.loop_triangles:
            tris.append([((vs[i].x if lateral == "x" else vs[i].y), vs[i].z)
                         for i in lt.vertices])
    gaps = {}
    for z0, z1 in windows:
        left, right = -1e9, 1e9
        blocked = False
        for t in tris:
            c = _clip_band(t, 1, z0, z1)
            if len(c) < 2:
                continue
            xs = [p[0] - axis_x for p in c]
            lo, hi = min(xs), max(xs)
            if hi - lo < 1e-9 and max(p[1] for p in c) - min(p[1] for p in c) < 1e-9:
                continue
            if lo < 0.0 < hi:
                blocked = True
            elif hi <= 0.0:
                left = max(left, hi)
            else:
                right = min(right, lo)
        gaps[(z0, z1)] = 0.0 if blocked else right - left
    crown = 1e9
    for t in tris:
        c = _clip_band(t, 0, axis_x - crown_half, axis_x + crown_half)
        if len(c) < 2:
            continue
        zs = [p[1] for p in c]
        if max(zs) > crown_from:
            crown = min(crown, max(min(zs), crown_from))
    return gaps, crown


def densify_for_ao(b, max_len=2.5, passes=6):
    """Taie muchiile mai lungi de `max_len` (m), ca AO-ul copt PE VARF sa
    aiba esantioane si in mijlocul fetelor mari. Fara asta, o fata de 12 m
    cu varfuri doar la sol (gradient vertical intunecat) si sub cornisa
    (umbrita) iese intunecata pe toata inaltimea -- masurat pe market_gate:
    pilastrii si panoul langa ambrazura la (68,38,18), fata de (156,94,52) pe
    restul panoului, aceeasi tenta. Taieturile sunt coplanare, deci bevel-ul
    (limita de unghi) nu le atinge; slotul fetei se copiaza la impartire."""
    bm = b.bm
    for _ in range(passes):
        edges = [e for e in bm.edges if e.calc_length() > max_len]
        if not edges:
            break
        bmesh.ops.subdivide_edges(bm, edges=edges, cuts=1, use_grid_fill=True)


def kangura_merlon(b, center, w, h, t, slot, facing="Y"):
    """Merlon "kangura" (planse Jodhpur: zidurile cetatii, poarta pietei):
    dreptunghi + umeri rotunjiti + varf ascutit, prisma de grosime `t`.
    `center` = mijlocul BAZEI. `facing` = axa fetei mari ("Y": fata spre
    +-Y, latimea pe X; "X": fata spre +-X, latimea pe Y). Solid manifold."""
    cx, cy, cz = center
    hw = w * 0.5
    outline = [(-hw, 0.0), (hw, 0.0), (hw, 0.52 * h), (0.43 * w, 0.70 * h),
               (0.30 * w, 0.83 * h), (0.14 * w, 0.93 * h), (0.0, h),
               (-0.14 * w, 0.93 * h), (-0.30 * w, 0.83 * h), (-0.43 * w, 0.70 * h),
               (-hw, 0.52 * h)]

    def P(u, d, z):
        if facing == "Y":
            return (cx + u, cy + d, cz + z)
        return (cx + d, cy + u, cz + z)
    bm = b.bm
    fa = [bm.verts.new(P(u, -t * 0.5, z)) for u, z in outline]
    fb = [bm.verts.new(P(u, t * 0.5, z)) for u, z in outline]
    n = len(outline)
    faces = [bm.faces.new(tuple(fa)), bm.faces.new(tuple(reversed(fb)))]
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((fa[i], fb[i], fb[j], fa[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


# ---------------------------------------------------------------------------
# 10. facade -- perete PLAN cu goluri retrase (grila), plus facade_bays
# ---------------------------------------------------------------------------
#
# Promovat aici din build_jodhpur_city.py (runda 3 a orasului) si din copia
# lui din build_jodhpur_fort.py (runda fort3), care divergeau: cetatea adauga
# `fill="none"`, `fill="jali"`, `point` per gol si `facade_bays`; orasul avea
# `fill="shutter"`, montantul usii de lemn si pragul `step`. Versiunea de aici
# e reuniunea lor; singura cota care diferea (pervazul, 0,10/0,08 la oras vs
# 0,12/0,10 la cetate) a devenit parametru per gol (`sill_h`, `sill_out`).
# Criteriul promovarii: ambele build-uri scot GLB-uri identice la byte.
#
# De ce grila: `arch_opening` pe goluri izolate pune fiecare gol intr-un PANOU
# propriu care iese din perete ("arcade in rame iesite"). Aici peretele e o
# GRILA: coloane la marginile golurilor x randuri la pragurile/buiandrugii
# lor; fiecare celula e plina sau gol. Fata, spatele si firidele golurilor
# partajeaza varfurile (fara fete interne => fara rosturi de bevel), timpanele
# arcelor se lipesc de aceleasi varfuri. Rama e o banda SUBTIRE care iese
# 4-5 cm. Golurile raman retrase (brief §1.4), cu placa GLOW / lemn in fund.

def _fx(p0, u, n):
    P0 = Vector(p0)
    U = Vector(u).normalized()
    N = Vector(n).normalized()

    def W(uu, z, d):
        return P0 + U * uu + N * d + Vector((0.0, 0.0, z))
    return W


def _lbox(b, W, u0, u1, z0, z1, d0, d1, slot):
    """Cutie inchisa in coordonatele locale (u, z, d) ale unei fete."""
    if u1 - u0 < 1e-4 or z1 - z0 < 1e-4 or abs(d1 - d0) < 1e-5:
        return []
    vs = {}
    for iu, uu in enumerate((u0, u1)):
        for iz, z in enumerate((z0, z1)):
            for idd, d in enumerate((d0, d1)):
                vs[(iu, iz, idd)] = b.bm.verts.new(W(uu, z, d))

    def v(a, c, e):
        return vs[(a, c, e)]
    quads = [
        (v(0, 0, 0), v(0, 0, 1), v(0, 1, 1), v(0, 1, 0)),
        (v(1, 0, 0), v(1, 1, 0), v(1, 1, 1), v(1, 0, 1)),
        (v(0, 0, 0), v(1, 0, 0), v(1, 0, 1), v(0, 0, 1)),
        (v(0, 1, 0), v(0, 1, 1), v(1, 1, 1), v(1, 1, 0)),
        (v(0, 0, 0), v(0, 1, 0), v(1, 1, 0), v(1, 0, 0)),
        (v(0, 0, 1), v(1, 0, 1), v(1, 1, 1), v(0, 1, 1)),
    ]
    faces = [b.bm.faces.new(q) for q in quads]
    for f in faces:
        f[b.slot] = slot
    return faces


def _lprism(b, W, poly, d0, d1, slot):
    """Prisma inchisa dintr-un poligon simplu (u, z), extrudata pe normala."""
    clean = []
    for p in poly:
        if not clean or math.hypot(p[0] - clean[-1][0], p[1] - clean[-1][1]) > 1e-5:
            clean.append(p)
    if len(clean) > 2 and math.hypot(clean[0][0] - clean[-1][0],
                                     clean[0][1] - clean[-1][1]) <= 1e-5:
        clean.pop()
    if len(clean) < 3:
        return []
    fr = [b.bm.verts.new(W(uu, z, d1)) for uu, z in clean]
    bk = [b.bm.verts.new(W(uu, z, d0)) for uu, z in clean]
    faces = []
    for i0, i1, i2 in _ear_clip(clean):
        faces.append(b.bm.faces.new((fr[i0], fr[i1], fr[i2])))
        faces.append(b.bm.faces.new((bk[i2], bk[i1], bk[i0])))
    m = len(clean)
    for i in range(m):
        j = (i + 1) % m
        faces.append(b.bm.faces.new((fr[i], bk[i], bk[j], fr[j])))
    for f in faces:
        f[b.slot] = slot
    return faces


def _lband(b, W, pts, width, d0, d1, slot, closed=False, outward=True):
    """Banda de sectiune dreptunghiulara de-a lungul unei polilinii (u, z) --
    rama. Polilinia merge in sensul golului, stanga sensului = in afara lui."""
    n = len(pts)
    if n < 2:
        return []
    nseg = n if closed else n - 1
    segn = []
    for i in range(nseg):
        a, c = pts[i], pts[(i + 1) % n]
        dx, dz = c[0] - a[0], c[1] - a[1]
        ln = math.hypot(dx, dz) or 1e-9
        segn.append((-dz / ln, dx / ln))
    sgn = 1.0 if outward else -1.0
    offs = []
    for i in range(n):
        if closed:
            n0, n1 = segn[i - 1], segn[i % nseg]
        else:
            n0 = segn[max(i - 1, 0)]
            n1 = segn[min(i, nseg - 1)]
        mx, mz = n0[0] + n1[0], n0[1] + n1[1]
        ml = math.hypot(mx, mz) or 1e-9
        mx, mz = mx / ml, mz / ml
        cosv = max(mx * n0[0] + mz * n0[1], 0.35)
        offs.append((pts[i][0] + sgn * mx * width / cosv,
                     pts[i][1] + sgn * mz * width / cosv))
    ring = []
    for i in range(n):
        ring.append([b.bm.verts.new(W(pts[i][0], pts[i][1], d1)),
                     b.bm.verts.new(W(offs[i][0], offs[i][1], d1)),
                     b.bm.verts.new(W(offs[i][0], offs[i][1], d0)),
                     b.bm.verts.new(W(pts[i][0], pts[i][1], d0))])
    faces = []
    for i in range(nseg):
        A, B = ring[i], ring[(i + 1) % n]
        for k in range(4):
            k2 = (k + 1) % 4
            faces.append(b.bm.faces.new((A[k], B[k], B[k2], A[k2])))
    if not closed:
        faces.append(b.bm.faces.new(tuple(ring[0])))
        faces.append(b.bm.faces.new(tuple(reversed(ring[-1]))))
    for f in faces:
        f[b.slot] = slot
    return faces


def _opening_contour(o, steps=8):
    uc, z, w, h = o["u"], o["z"], o["w"], o["h"]
    hw = w * 0.5
    if o.get("arch"):
        pier = o.get("pier", h - hw)
        pts = arch_hole_contour(o.get("style", "round"), w, h, pier, steps,
                                point=o.get("point", 0.2))
        return [(uc + x, z + zz) for x, zz in pts]
    return [(uc - hw, z), (uc - hw, z + h), (uc + hw, z + h), (uc + hw, z)]


def facade(b, bglow, btrim, p0, u, n, width, height, thick, openings, slot,
           glow_slot, trim_slot, frame_slot=None, steps=8, bframe=None,
           cap_left=True, cap_right=True, cap_top=True):
    """Perete plan `width` x `height`, coltul stanga-jos al FETEI in `p0`,
    `u` = spre dreapta vazut din afara, `n` = normala exterioara, gros `thick`
    spre interior. `cap_left/right/top`: inchide capatul (False cand capatul
    se lipeste coplanar de peretele vecin -- altfel bevel-ul face un rost).

    Gol: dict cu u (centru), z (prag), w, h; optional arch=True, style,
    pier, point (arc ascutit turtit, implicit 0.2); fill:
      "glow"    placa GLOW retrasa (implicit);
      "wood"    usa de lemn retrasa, cu un montant la mijloc (orasul);
      "shutter" placa GLOW + oblon-rama si montant (orasul);
      "open"    placa GLOW in spatele peretelui (gol vazut prin perete);
      "none"    gol strapuns, fara fund (gura portii, cetatea);
      "jali"    placa GLOW + grila de piatra 3 x 4 in fata ei (palatul);
    frame (latimea ramei, 0 = fara), frame_out, reveal (adancimea fundului);
    sill=True pervaz sub gol, cu sill_h (implicit 0,10) si sill_out (iesirea
    peste frame_out, implicit 0,08) -- cetatea le da 0,12 / 0,10;
    step=True prag de piatra la usa (orasul).
    Intoarce {"wall", "frame", "glow", "trim"}."""
    frame_slot = frame_slot if frame_slot is not None else slot
    bf = bframe if bframe is not None else b
    W = _fx(p0, u, n)
    wall, frame, glow, trim = [], [], [], []
    ops = [dict(o) for o in openings]
    for o in ops:
        o["_hw"] = o["w"] * 0.5
        o["_pier"] = o.get("pier", o["h"] - o["_hw"]) if o.get("arch") else o["h"]

    def key(x):
        return round(x, 5)
    us, zs = {0.0, width}, {0.0, height}
    for o in ops:
        us |= {o["u"] - o["_hw"], o["u"] + o["_hw"]}
        zs |= {o["z"], o["z"] + o["h"]}
        if o.get("arch"):
            us.add(o["u"])
            zs.add(o["z"] + o["_pier"])
    us = sorted({key(min(max(x, 0.0), width)) for x in us})
    zs = sorted({key(min(max(x, 0.0), height)) for x in zs})
    nu, nz = len(us) - 1, len(zs) - 1

    def cell(i, j):
        if i < 0 or j < 0 or i >= nu or j >= nz:
            return "out"
        um, zm = (us[i] + us[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5
        for o in ops:
            if abs(um - o["u"]) < o["_hw"] and o["z"] < zm < o["z"] + o["h"]:
                if o.get("arch") and zm > o["z"] + o["_pier"]:
                    return "rise"
                return "hole"
        return "solid"

    V = {}

    def gv(i, j, layer):
        k = (i, j, layer)
        if k not in V:
            V[k] = b.bm.verts.new(W(us[i], zs[j], 0.0 if layer == 0 else -thick))
        return V[k]

    def quad(a, c, d, e):
        f = b.bm.faces.new((a, c, d, e))
        f[b.slot] = slot
        wall.append(f)

    for i in range(nu):
        for j in range(nz):
            if cell(i, j) != "solid":
                continue
            quad(gv(i, j, 0), gv(i + 1, j, 0), gv(i + 1, j + 1, 0), gv(i, j + 1, 0))
            quad(gv(i, j + 1, 1), gv(i + 1, j + 1, 1), gv(i + 1, j, 1), gv(i, j, 1))
            for di, dj, e0, e1 in ((-1, 0, (i, j), (i, j + 1)), (1, 0, (i + 1, j + 1), (i + 1, j)),
                                   (0, -1, (i + 1, j), (i, j)), (0, 1, (i, j + 1), (i + 1, j + 1))):
                nb = cell(i + di, j + dj)
                if nb in ("solid", "rise"):
                    continue
                if nb == "out":
                    if di == -1 and not cap_left:
                        continue
                    if di == 1 and not cap_right:
                        continue
                    if dj == 1 and not cap_top:
                        continue
                a0, a1 = gv(e0[0], e0[1], 0), gv(e1[0], e1[1], 0)
                b0, b1 = gv(e0[0], e0[1], 1), gv(e1[0], e1[1], 1)
                quad(a0, b0, b1, a1)

    for o in ops:
        if not o.get("arch"):
            continue
        uc, hw = o["u"], o["_hw"]
        zp, top = o["z"] + o["_pier"], o["z"] + o["h"]
        rise = top - zp
        prof = _arch_profile(o.get("style", "round"), hw, rise, steps, point=o.get("point", 0.2))
        left = [p for p in prof if p[0] <= 1e-9]
        if abs(left[-1][0]) > 1e-6:
            left.append((0.0, rise))
        iu0, iuc, iu1 = us.index(key(uc - hw)), us.index(key(uc)), us.index(key(uc + hw))
        jz0, jz1 = zs.index(key(zp)), zs.index(key(top))
        for side in (-1, 1):
            arc = [(uc - side * x, zp + zz) for x, zz in left[1:-1]]
            outer_i = iu0 if side < 0 else iu1
            front = [gv(outer_i, jz0, 0)] + [b.bm.verts.new(W(p[0], p[1], 0.0)) for p in arc] + \
                    [gv(iuc, jz1, 0), gv(outer_i, jz1, 0)]
            back = [gv(outer_i, jz0, 1)] + [b.bm.verts.new(W(p[0], p[1], -thick)) for p in arc] + \
                   [gv(iuc, jz1, 1), gv(outer_i, jz1, 1)]
            poly = [(us[outer_i], zs[jz0])] + arc + [(uc, top), (us[outer_i], top)]
            for i0, i1, i2 in _ear_clip(poly):
                wall.append(b.bm.faces.new((front[i0], front[i1], front[i2])))
                wall.append(b.bm.faces.new((back[i2], back[i1], back[i0])))
            m = len(front) - 1
            for k in range(m - 1):
                wall.append(b.bm.faces.new((front[k], back[k], back[k + 1], front[k + 1])))
        for f in wall:
            if f.is_valid:
                f[b.slot] = slot

    for o in ops:
        uc, z0, w, h = o["u"], o["z"], o["w"], o["h"]
        hw, pier = o["_hw"], o["_pier"]
        fill = o.get("fill", "glow")
        reveal = o.get("reveal", thick * 0.6)
        cont = _opening_contour(o, steps)
        fw = o.get("frame", 0.07)
        fo = o.get("frame_out", 0.04)
        door_like = z0 <= 1e-6
        if fw > 0.0:
            frame += _lband(bf, W, cont, fw, -0.01, fo, frame_slot, closed=not door_like)
        if o.get("sill"):
            frame += _lbox(bf, W, uc - hw - fw - 0.06, uc + hw + fw + 0.06,
                           z0 - o.get("sill_h", 0.10), z0, -0.02,
                           fo + o.get("sill_out", 0.08), frame_slot)
        if o.get("step"):
            frame += _lbox(bf, W, uc - hw - 0.3, uc + hw + 0.3, 0.0, 0.14, -0.02,
                           0.42, frame_slot)
        if fill == "none":
            continue
        if fill == "open":
            glow += _lprism(bglow, W, cont, -thick - 0.30, -thick - 0.26, glow_slot)
            continue
        if fill == "wood":
            trim += _lprism(btrim, W, cont, -reveal - 0.04, -reveal, trim_slot)
            trim += _lbox(btrim, W, uc - 0.03, uc + 0.03, z0 + 0.02, z0 + pier - 0.05,
                          -reveal, -reveal + 0.025, trim_slot)
            continue
        glow += _lprism(bglow, W, cont, -reveal - 0.03, -reveal, glow_slot)
        if fill == "shutter":
            tw = max(0.08, w * 0.22)
            trim += _lband(btrim, W, cont, tw, -reveal, -reveal + 0.04, trim_slot,
                           closed=True, outward=False)
            trim += _lbox(btrim, W, uc - tw * 0.4, uc + tw * 0.4, z0, z0 + pier,
                          -reveal, -reveal + 0.035, trim_slot)
        if fill == "jali":
            # grila de piatra 3 x 4 in fata placii GLOW (brief §1.2: "fete
            # retrase cu grila de 3 x 4 gauri"): 2 montanti + 3 traverse,
            # sub nasterea arcului
            bt = 0.07
            dj0, dj1 = -reveal + 0.01, -reveal + 0.10
            for k in (1, 2):
                uu = uc - hw + w * k / 3.0
                frame += _lbox(bf, W, uu - bt * 0.5, uu + bt * 0.5, z0, z0 + pier,
                               dj0, dj1, frame_slot)
            for k in (1, 2, 3):
                zz = z0 + pier * k / 4.0
                frame += _lbox(bf, W, uc - hw, uc + hw, zz - bt * 0.5, zz + bt * 0.5,
                               dj0, dj1, frame_slot)
    return {"wall": wall, "frame": frame, "glow": glow, "trim": trim}


def facade_bays(b, bglow, btrim, p0, u, n, width, height, thick, openings, slot,
                glow_slot, trim_slot, pad=0.35, **kw):
    """`facade` pe un perete LUNG, spart in travee: golurile se grupeaza pe
    intervalele lor laterale (plus rama), iar peretele se taie la mijlocul
    spatiului dintre grupuri. Fiecare bucata e un `facade` propriu, cu
    capetele interioare deschise (cap_left/right=False, coplanare), deci
    coloanele unui gol nu mai taie tot peretele in felii."""
    ivs = sorted(((o["u"] - o["w"] * 0.5 - pad, o["u"] + o["w"] * 0.5 + pad) for o in openings))
    groups = []
    for a0, a1 in ivs:
        if groups and a0 <= groups[-1][1]:
            groups[-1][1] = max(groups[-1][1], a1)
        else:
            groups.append([a0, a1])
    cuts = [0.0]
    for g0, g1 in zip(groups, groups[1:]):
        c = (g0[1] + g1[0]) * 0.5
        if 0.05 < c < width - 0.05:
            cuts.append(c)
    cuts.append(width)
    U = Vector(u).normalized()
    out = {"wall": [], "frame": [], "glow": [], "trim": []}
    for k in range(len(cuts) - 1):
        s0, s1 = cuts[k], cuts[k + 1]
        ops = []
        for o in openings:
            if s0 <= o["u"] < s1:
                o2 = dict(o)
                o2["u"] = o["u"] - s0
                ops.append(o2)
        res = facade(b, bglow, btrim, Vector(p0) + U * s0, u, n, s1 - s0, height, thick,
                     ops, slot, glow_slot, trim_slot,
                     cap_left=(k == 0) and kw.get("cap_left", True),
                     cap_right=(k == len(cuts) - 2) and kw.get("cap_right", True),
                     cap_top=kw.get("cap_top", True), steps=kw.get("steps", 8),
                     frame_slot=kw.get("frame_slot"), bframe=kw.get("bframe"))
        for kk in out:
            out[kk] += res[kk]
    return out
