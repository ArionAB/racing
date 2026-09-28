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

def _arch_profile(style, half_w, rise, steps):
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
                  panel_h=None, panel_z0=0.0, open=False, band_w=None):
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
      3. firida: peretii dintre fata exterioara si planul geamului (adancime
         `reveal`), pe conturul golului.
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

    profile = _arch_profile(style, half_w, rise, steps)
    # profil complet al golului, in sens ANTI-orar vazut din +Y (asa iese
    # normala inelului corect fara sa mai depindem de recalc global):
    # picior stang (jos->sus) -> arc (stanga->dreapta) -> picior drept
    # (sus->jos) -> baza (dreapta->stanga).
    hole = [(-half_w, 0.0), (-half_w, pier_h)]
    hole += [(x, pier_h + z) for x, z in profile]
    hole += [(half_w, pier_h), (half_w, 0.0)]
    n = len(hole)

    hw_panel = panel_w * 0.5
    panel_z1 = panel_z0 + panel_h

    inner_edge = wall_t * 0.5                    # fata exterioara a peretelui
    back_edge = -wall_t * 0.5                     # fata din spate
    reveal_edge = inner_edge - reveal             # unde incepe firida (retras)
    glass_edge = reveal_edge - glass_depth        # unde sta geamul

    stone_faces = []

    # REVIZUIRE: prima versiune proiecta radial fiecare punct al golului spre
    # marginea dreptunghiului panoului, dintr-un centru fix -- pe panouri
    # INALTE SI INGUSTE (ferestrele fusului: panel_h aprox 3x panel_w), razele
    # loveau muchia stanga/dreapta la inaltimi foarte diferite intre puncte
    # vecine ale arcului, iar inelul rezultat facea zig-zag -- citea ca
    # "cioburi"/fulgere in loc de perete neted (vazut direct in randare).
    #
    # Fix: umplutura panoului se face din DREPTUNGHIURI SIMPLE (nu un inel
    # radial), pe bounding-box-ul golului -- banda de SUS (plina, peste tot
    # golul), banda de JOS (idem), si benzile STANGA/DREAPTA (doar pe
    # inaltimea golului). Colturile groove-ului (langa arc) raman acoperite
    # de firida (mai jos) -- geometria e garantat plana si necontorsionata,
    # indiferent de raportul panel_w/panel_h.
    hole_x0 = min(x for x, _ in hole)
    hole_x1 = max(x for x, _ in hole)
    hole_z0 = min(z for _, z in hole)
    hole_z1 = max(z for _, z in hole)

    def flat_rect(x0, x1, z0, z1, y_val, flip):
        if x1 - x0 < 1e-6 or z1 - z0 < 1e-6:
            return None
        pts = [(x0, y_val, z0), (x1, y_val, z0), (x1, y_val, z1), (x0, y_val, z1)]
        if flip:
            pts = list(reversed(pts))
        f = b.bm.faces.new(tuple(b.bm.verts.new(rot_pt(*p)) for p in pts))
        return f

    def panel_fill(y_val, flip):
        faces = []
        # sus (peste tot golul, de la panel_x0 la panel_x1)
        f = flat_rect(-hw_panel, hw_panel, hole_z1, panel_z1, y_val, flip)
        if f:
            faces.append(f)
        # jos
        f = flat_rect(-hw_panel, hw_panel, panel_z0, hole_z0, y_val, flip)
        if f:
            faces.append(f)
        # stanga (doar pe inaltimea golului)
        f = flat_rect(-hw_panel, hole_x0, hole_z0, hole_z1, y_val, flip)
        if f:
            faces.append(f)
        # dreapta
        f = flat_rect(hole_x1, hw_panel, hole_z0, hole_z1, y_val, flip)
        if f:
            faces.append(f)
        return faces

    # fata din fata (spre +Y local)
    stone_faces += panel_fill(inner_edge, flip=False)
    # fata din spate (spre -Y local)
    stone_faces += panel_fill(back_edge, flip=True)
    # firida: peretii golului intre fata exterioara si planul geamului
    hole_outer = [rot_pt(x, inner_edge, z) for x, z in hole]
    hole_reveal = [rot_pt(x, reveal_edge, z) for x, z in hole]
    for i in range(n - 1):
        quad = (hole_outer[i], hole_outer[i + 1], hole_reveal[i + 1], hole_reveal[i])
        f = b.bm.faces.new(tuple(b.bm.verts.new(p) for p in quad))
        stone_faces.append(f)
    # marginea EXTERIOARA a panoului (grosimea vazuta din lateral -- cele 4
    # muchii ale dreptunghiului panel_w x panel_h, unind fata cu spatele, ca
    # peretele sa fie un solid inchis, nu o pereche de folii)
    panel_corners = [(-hw_panel, panel_z0), (hw_panel, panel_z0),
                     (hw_panel, panel_z1), (-hw_panel, panel_z1)]
    outer_front = [rot_pt(x, inner_edge, z) for x, z in panel_corners]
    outer_back = [rot_pt(x, back_edge, z) for x, z in panel_corners]
    for i in range(4):
        j = (i + 1) % 4
        quad = (outer_front[i], outer_front[j], outer_back[j], outer_back[i])
        f = b.bm.faces.new(tuple(b.bm.verts.new(p) for p in quad))
        stone_faces.append(f)

    if glass:
        # placa GLOW la fundul firidei, usor mai mica (rama de piatra ramane
        # vizibila in jurul geamului -- ca la _glass_and_reveal_sides)
        margin = min(half_w, rise) * 0.12
        gcx_hole, gcz_hole = (hole_x0 + hole_x1) * 0.5, (hole_z0 + hole_z1) * 0.5
        glass_outline = []
        for x, z in hole:
            dx, dz = x - gcx_hole, z - gcz_hole
            d = math.hypot(dx, dz) or 1e-6
            shrink = max(0.0, 1.0 - margin / d) if d > margin else 0.0
            glass_outline.append((gcx_hole + dx * shrink, gcz_hole + dz * shrink))
        gpts_front = [rot_pt(x, glass_edge, z) for x, z in glass_outline]
        glass_faces = [bg.bm.faces.new(tuple(bg.bm.verts.new(p) for p in gpts_front))]
        for f in glass_faces:
            f[bg.slot] = glow_slot
    else:
        glass_faces = []

    for f in stone_faces:
        f[b.slot] = slot
    return {"stone": stone_faces, "glass": glass_faces}


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
