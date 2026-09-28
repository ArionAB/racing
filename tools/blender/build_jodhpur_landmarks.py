"""Jodhpur -- Piesele-reper (brief §1.3, val 2b din docs/asset_briefs/jodhpur_kit.md).

  jodhpur/structures/market_gate.glb              poarta pietei (peste grila de start)
  jodhpur/structures/stepwell_flight_module.glb    modul de trepte al fantanii
  jodhpur/structures/stepwell_corner.glb           colt interior al fantanii
  jodhpur/structures/stepwell_pavilion.glb         galeria de vest a fantanii
  jodhpur/structures/jaswant_thada.glb             cenotaful de marmura

Foloseste vocabularul din `jodhpur_shapes.py` (arch_opening, dome, chhatri,
balustrade, crenellation, solid_stair, stepped_plinth) -- vezi pilotul
(`build_jodhpur_pilot.py`) pentru pattern-ul complet (doi Builder-i, STONE +
GLOW separate, `emit()` cu origine pe ansamblu).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_jodhpur_landmarks.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

# Sloturile legale pe Jodhpur (brief §0.4).
STONE = ROCK_LIGHT       # gresia fortului/portii -> clasa red_sandstone la integrare
WELL_STONE = SAND_MID    # gresia roz a fantanii -> clasa rose_sandstone
MARBLE = FOAM_WHITE      # marmura cenotafului (alb)
MARBLE_SHADE = MARBLE_GREY  # fetele umbrite ale marmurei
TRIM_WOOD = WOOD         # canaturile de lemn ale portii
GLOW = VOLCANIC_BLACK    # goluri de geam/tinta, ziua inchise
ROCK = ROCK_DARK         # bolovanii de la baza portii


def _finish_or_none(obj):
    """Un Builder GLOW poate ramane gol -- vezi build_jodhpur_pilot.py."""
    if len(obj.data.vertices) == 0:
        name = obj.name
        me = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.meshes.remove(me)
        return None
    return obj


# --- market_gate -----------------------------------------------------------
#
# Contract (brief §1.3): 34 m latime totala, 17 m inalta, adancime 6 m; golul
# >= 18 m (masurat ca GAP pe planul portii), cheia >= 11 m. Lista de elemente,
# scrisa dupa (re)citirea decuparii (market_gate.png), de jos in sus:
#
#   1. Soclu TESIT care iese LATERAL fata de baza turnurilor (stepped_plinth),
#      cu bolovani (ROCK_DARK) ingramaditi la baza, de o parte si de alta --
#      NU parte din corpul turnurilor, ci un umar separat, mai lat.
#   2. Doua turnuri OCTOGONALE subtiri, unul in stanga si unul in dreapta
#      arcadei centrale -- corp octogonal drept, cu o singura fanta ingusta
#      (arrow-slit) verticala pe fata exterioara vizibila.
#   3. Parapet CRENELAT DREPT intre cele doua turnuri, deasupra arcului
#      central -- creneluri dese, dreptunghiulare (numarate pe decupare:
#      ~9-10 pe latimea dintre turnuri).
#   4. In varful FIECARUI turn: o galerie/balcon in consola cu balustrada,
#      apoi un chhatri mic deschis (coloane + arce + cupola bulboasa mica +
#      finial) -- turnurile se termina in chhatri, nu plat.
#   5. Arcada centrala: UN gol mare, cu profil de arc SEGMENTAL (turtit, nu
#      ascutit -- la 18 m gol / 34 m latime totala golul trece de 50% din
#      latime, deci arcul trebuie sa fie mult mai plat decat "pointed" ca sa
#      nu atinga coronamentul turnurilor -- abaterea permisa explicita din
#      tabel).
#   6. Canaturi de lemn DESCHISE, lipite de ambrazura, cate un canat de o
#      parte si de alta a golului (WOOD, cu grila mica de tepi -- vizibile ca
#      dungi orizontale/verticale pe decupare).
#   7. O nisa mica decorativa (medalion) pe fiecare fata a peretelui de
#      deasupra arcului, langa creneluri -- geometrie mica, opționala,
#      omisa aici (sub pragul "se vede la 30 m din masina ca forma").
#
# Nimic nu iese din contur in afara de bolovanii de la baza si chhatri-urile
# turnurilor.
GATE_TOTAL_W = 34.0
GATE_H = 17.0
GATE_D = 6.0
GATE_GAP_W = 18.4     # golul (contract >=18.0) -- marja mica peste minim
GATE_CROWN_MIN = 11.0  # cheia arcului, contract minim
GATE_CROWN_TARGET = 11.6  # tinta constructiei -- marja reala peste minim


def build_market_gate():
    b = Builder()
    bg = Builder()
    doorb = Builder()

    stone_faces = []
    door_faces = []

    tower_w = 4.4          # latimea (diametrul) turnului octogonal
    tower_gap_half = GATE_GAP_W * 0.5
    tower_cx = tower_gap_half + tower_w * 0.5 + 0.15  # centrul fiecarui turn pe X

    # 1. soclu tesit, mai lat decat turnul, cu bolovani laterali
    plinth_levels = [(tower_w + 1.6, GATE_D + 1.2, 0.55),
                     (tower_w + 0.9, GATE_D + 0.6, 0.45)]
    for side in (-1.0, 1.0):
        stone_faces += list(stepped_plinth(b, (side * tower_cx, 0.0, 0.0),
                                           plinth_levels, STONE))
    plinth_h = sum(lvl[-1] for lvl in plinth_levels)

    # bolovani laterali (ROCK), ingramaditi in afara turnurilor -- umarul care
    # iese lateral, ca pe decupare (nu parte din corpul turnului).
    import random
    rnd = random.Random(7)
    for side in (-1.0, 1.0):
        base_x = side * (tower_cx + tower_w * 0.5 + 1.3)
        for i in range(5):
            rx = base_x + side * rnd.uniform(0.0, 2.6)
            ry = rnd.uniform(-GATE_D * 0.45, GATE_D * 0.45)
            rr = rnd.uniform(0.55, 1.05)
            stone_faces += list(b.box((rx, ry, rr * 0.5), (rr * 1.4, rr * 1.3, rr), ROCK,
                                      rotation=Matrix.Rotation(rnd.uniform(0, math.pi), 3, "Z")))

    # 2. turnuri octogonale
    #
    # REVIZUIRE: `tower_top = GATE_H*0.62 = 10.54` era MAI JOS decat cheia
    # arcului (`crown_z = GATE_CROWN_TARGET = 11.6`) -- panoul arcului
    # (`panel_h=parapet_z`) rezulta mai scund decat arcul insusi, iar
    # umplutura de sus a panoului (`flat_rect` intre `hole_z1` si `panel_z1`)
    # degenereaza (inaltime negativa, sarita de garda `if x1-x0<1e-6`), deci
    # ramane un GOL deasupra cheii -- exact ce se vedea in randare (parapetul
    # crenelat plutind ca o "punte", cu un vid mare dedesubt in loc de arc
    # plin). Fix: turnul (si parapetul de pe el) trebuie sa fie CLAR mai
    # inalt decat cheia arcului, cu marja pentru banda de parapet.
    tower_top = max(GATE_H * 0.62, GATE_CROWN_TARGET + 1.6)
    tower_base_z = plinth_h
    tower_body_h = tower_top - tower_base_z
    tower_r = tower_w * 0.5
    for side in (-1.0, 1.0):
        cx = side * tower_cx
        stone_faces += list(b.cylinder((cx, 0.0, tower_base_z + tower_body_h * 0.5),
                                       tower_r, tower_body_h, STONE, segments=8, axis="Z"))
        # fanta ingusta pe fata exterioara (spre afara de arcada, adica +Y)
        # -- merge in `bg` (slot GLOW), NU in `stone_faces` (Builder `b`).
        slit_cz = tower_base_z + tower_body_h * 0.42
        bg.box((cx, tower_r * 0.92, slit_cz), (0.14, 0.10, 1.6), GLOW)

    # 3. parapet crenelat drept intre turnuri, deasupra golului
    parapet_z = tower_top
    parapet_h_solid = 0.55
    stone_faces += list(b.box((0.0, 0.0, parapet_z + parapet_h_solid * 0.5),
                              (GATE_GAP_W + tower_w * 0.3, GATE_D * 0.6, parapet_h_solid), STONE))
    # REVIZUIRE runda 2 (sef): merloanele parapetului trebuie sa fie
    # ROTUNJITE (crop: varfuri curbate), nu dreptunghiulare drepte.
    stone_faces += crenellation(b, (-(GATE_GAP_W * 0.5 + tower_w * 0.1), 0.0, parapet_z + parapet_h_solid),
                                (GATE_GAP_W * 0.5 + tower_w * 0.1, 0.0, parapet_z + parapet_h_solid),
                                0.55, STONE, width=0.55, gap=0.42, style="rounded")

    # 4. galerie + chhatri pe fiecare turn
    #
    # REVIZUIRE: bugetul de inaltime al chhatri-ului era calculat cu
    # `GATE_H - (gal_z+0.55)` folosind vechiul `gal_z` (mai jos) -- dupa
    # ridicarea lui `tower_top` (fix-ul anterior pentru arcul ingropat),
    # aceeasi formula lasa doar `col_h` corect, dar `chhatri()` ADAUGA
    # deasupra coloanelor chajja+placa+cupola+finial fara sa plafoneze la
    # `col_h` -- turnul complet iesea la 18,3 m (masurat cu verify_glb.py),
    # peste contractul de 17 m. Fix: `col_h` foloseste un buget EXPLICIT mai
    # mic, calculat inapoi din inaltimea tipica adaugata de dome+finial
    # (~1,3x raza cupolei), nu doar diferenta bruta pana la GATE_H.
    gal_z = tower_top
    chhatri_top_budget = GATE_H - (gal_z + 0.55)  # spatiu total ramas pt chhatri
    ch_dome_r = (tower_r - 0.35) * 0.62
    # overhead masurat direct (nu aproximat): pentru dome_radius=0.5, cupola
    # onion + lotus_ring + finial (implicit `chhatri`) adauga 1,444 m peste
    # `col_h` -- raportul (1,444-0,22)/0,5 = 2,448 pe partea de cupola.
    ch_overhead = 0.22 + ch_dome_r * 2.45
    ch_col_h = max(chhatri_top_budget - ch_overhead, 0.6)
    for side in (-1.0, 1.0):
        cx = side * tower_cx
        stone_faces += list(balcony_band(b, (cx, 0.0, gal_z), tower_r - 0.15, tower_r + 0.30,
                                         0.16, STONE, segments=8))
        stone_faces += list(balustrade(b, (cx - 0.75, tower_r + 0.05, gal_z + 0.16),
                                       (cx + 0.75, tower_r + 0.05, gal_z + 0.16),
                                       0.45, STONE, merlon_w=0.14, merlon_gap=0.10))
        res_ch = chhatri(b, bg, (cx, 0.0, gal_z + 0.55), 8, tower_r - 0.35,
                         ch_col_h, STONE, GLOW,
                         col_r=0.11, dome_radius=ch_dome_r,
                         arch_style="round", chajja_out=0.30, segments_dome=10)
        stone_faces += res_ch["stone"]

    # 5. arcada centrala: profil SEGMENTAL (turtit) -- abatere permisa
    # explicita din tabel: la 18 m gol / 34 m latime, un arc "round" clasic
    # (semicerc) ar avea rise = half_w = 9.2 m, depasind cu mult cheia minima
    # si atingand coronamentul turnurilor. Aproximam segmental cu "round" la
    # `rise` mic (fractie din half_w), care da exact profilul turtit cerut,
    # fara sa introducem un nou stil in vocabular.
    #
    # REVIZUIRE: `panel_w=GATE_TOTAL_W` (34 m) facea din panoul arcului un
    # SINGUR perete plin care acoperea toata latimea portii, INGROPAND
    # turnurile octogonale (la +-9,35, deja construite mai sus) in interiorul
    # lui -- acelasi material/locatie, deci invizibile in randare (verificat:
    # comparatia arata doar panoul cu arcul, FARA turnuri/chhatri/creneluri,
    # desi geometria lor exista in fisier). Fix: panoul arcului se opreste
    # DOAR intre turnuri (panel_w putin peste GATE_GAP_W), nu peste toata
    # latimea -- turnurile raman piese vizual separate, cum apar pe decupare.
    # REVIZUIRE runda 2 (sef): arcul trebuie sa se citeasca vizibil curbat
    # (nu gol dreptunghiular) -- rise-ul a crescut de la 0,30 la 0,55 din
    # jumatatea golului, pastrand totusi profilul mult mai turtit decat un
    # semicerc complet (rise=half_w la "round" clasic) -- abaterea permisa
    # explicita din tabel ("arcul devine mai turtit, dar NU creste inaltimea
    # ca sa pastreze raportul").
    gate_pier_h = GATE_CROWN_TARGET - GATE_GAP_W * 0.5 * 0.55  # rise mai mare -> curbura vizibila
    gate_pier_h = max(gate_pier_h, GATE_H * 0.30)
    gate_rise = GATE_CROWN_TARGET - gate_pier_h
    gate_wall_t = GATE_D
    gate_panel_w = GATE_GAP_W + tower_w * 0.35   # se opreste langa turnuri, nu peste ele
    # REVIZUIRE runda 2 (sef): arcul trebuie sa se CITEASCA curbat, nu ca un
    # gol dreptunghiular -- `reveal=0` elimina firida (banda care arata
    # curbura intradosului din umbra), facand arcul sa para taiat drept.
    # `reveal>0` pastreaza un inel vizibil al curburii pe toata adancimea
    # peretelui (`gate_wall_t=6 m`), cu umbra proprie (memoria
    # `silueta-inainte-de-umbrire`).
    res_gate = arch_opening(b, bg, (0.0, 0.0, 0.0), GATE_GAP_W, gate_pier_h + gate_rise,
                            gate_pier_h, gate_wall_t, STONE, GLOW, style="round",
                            rotation=None, glass=False, reveal=0.9,
                            panel_w=gate_panel_w, panel_h=parapet_z, panel_z0=0.0, open=False)
    stone_faces += res_gate["stone"]
    crown_z = gate_pier_h + gate_rise

    # 6. canaturi de lemn deschise, lipite de ambrazura -- cate un canat de o
    # parte si de alta a golului, usor rotite ca sa se citeasca "deschise".
    # REVIZUIRE: leaf_c folosea `rot @ (side*door_w*0.5, 0, 0)` -- pentru
    # side=-1 (canatul stang), asta rotea punctul (-4.4, 0) cu +28 grade, care
    # muta centrul canatului la x=-13,0 (MAI DEPARTE de centrul golului decat
    # balamaua, adica in interiorul TURNULUI de la -11,55, nu in arcada) --
    # exact "planul strain" semnalat: doua dreptunghiuri late plutind langa
    # turnuri, nu canaturi in prag. Balamaua sta la marginea golului
    # (`hinge_x`), iar canatul trebuie sa se roteasca astfel incat capatul lui
    # LIBER sa intre spre centrul golului (x=0), nu sa iasa spre turn -- deci
    # offset-ul local trebuie sa fie spre INTERIOR (-side), nu spre exterior
    # (side).
    door_w = GATE_GAP_W * 0.5 - 0.35
    door_h = gate_pier_h * 0.94
    for side, open_ang in ((-1.0, 28.0), (1.0, -28.0)):
        hinge_x = side * (GATE_GAP_W * 0.5 - 0.10)
        rot = Matrix.Rotation(math.radians(open_ang), 3, "Z")
        leaf_c = Vector((hinge_x, 0.0, door_h * 0.5)) + rot @ Vector((-side * door_w * 0.5, 0.0, 0.0))
        door_faces += list(doorb.box((leaf_c.x, leaf_c.y, leaf_c.z),
                                     (door_w, 0.10, door_h), TRIM_WOOD, rotation=rot))
        # tepi de fier: grila mica 3x5 pe fata canatului (geometrie mica)
        for ix in range(3):
            for iz in range(5):
                lx = (ix - 1) * door_w * 0.32
                lz = (iz - 2) * door_h * 0.16
                local = Vector((lx, 0.07, lz))
                p = Vector((hinge_x, 0.0, door_h * 0.5)) + rot @ (Vector((-side * door_w * 0.5, 0.0, 0.0)) + local)
                door_faces += list(doorb.box((p.x, p.y, p.z), (0.05, 0.05, 0.05), GLOW, rotation=rot))

    stone_obj = b.to_object("Gate_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = STONE
    # `door_faces` nu mai are nevoie de re-tagging: `doorb.box(...)` a scris
    # deja slotul corect pe fiecare fata (TRIM_WOOD canatul, GLOW tepii) --
    # ambele in ACELASI nod `Gate_Doors`, intentionat (contract §1.3: canaturi
    # de lemn cu tepi de fier, un singur nod de decor).
    door_obj = doorb.to_object("Gate_Doors")
    glow_obj = _finish_or_none(bg.to_object("Gate_Glow"))

    # NOTA (istoricul rotatiei): o incercare anterioara a rotit ansamblul 90°
    # in jurul lui Z, presupunand ca testul cu cubul de fete colorate (facut
    # PE UN CUB SIMPLU 34x6x17) cerea ca fatada sa fie pe +X. Randarea cu
    # rotatia aplicata arata insa clar poarta din CAPAT (parapetul crenelat
    # vazut pe lungime, turnurile asimetrice) -- deci axa lunga trebuie sa
    # ramana pe X (asa cum a fost construita, fara rotatie): fatada
    # (arch_opening, implicit +Y) ramane spre camera fara nicio rotatie
    # suplimentara, la fel ca la restul pieselor din pilot. Bug-ul real care
    # ascundea turnurile nu era orientarea, ci panoul arcului supradimensionat
    # (`panel_w=GATE_TOTAL_W`, fix separat mai sus) -- odata ingropat turnul
    # scos la vedere, orientarea originala (fara rotatie) e cea corecta.

    return stone_obj, door_obj, glow_obj, crown_z


# --- stepwell_flight_module --------------------------------------------------
#
# Contract (brief §1.3): 12 m lat x 3 m inalt x 2,5 m adanc. Lista de
# elemente (decupare stepwell_flight_module.png): un perete lung, jos, cu
# TREI V-uri de trepte inversate taiate in profilul de sus -- fiecare V are
# un varf inalt (la 4 m distanta) si coboara pe ambele parti spre un punct
# jos intre V-uri consecutive. Rosturile de caramida sunt textura (nu
# geometrie -- regula 0.5); TREPTELE insele sunt geometrie (0,3 m pe treapta,
# brief regula 5). Capete PLANE la x=+-6, ca sa se inlantuie cu alt modul.
WELL_MOD_W = 12.0
WELL_MOD_H = 3.0
WELL_MOD_D = 2.5
WELL_STEP_H = 0.3


def _flight_steps(b, apex_x, base_x_left, base_x_right, apex_z, base_z,
                  wall_front_y, projection, slot):
    """Un singur V de trepte, de la baza (stanga, joasa) urcand spre varf
    (centru, inalt) si coborand la baza (dreapta, joasa).

    REVIZUIRE runda 2 (sef, FAIL): prima versiune facea fiecare treapta o
    cutie care se intindea pe TOATA adancimea modulului (`depth=WELL_MOD_D=
    2,5 m`) -- vazute din fata, ele citeau ca ARIPIOARE/COASTE perpendiculare
    pe perete, tepi care ies spre camera, nu ca trepte incrustate in fata
    zidului. Cerinta corecta (crop): un zid SOLID (fundal plin, pe toata
    adancimea, construit separat in `build_stepwell_flight_module`), iar pe
    FATA lui (+Y), treptele proiecteaza doar 0,3-0,6 m -- geometrie MICA,
    suprapusa pe suprafata zidului, nu structura care strapunge zidul.

    `wall_front_y`: coordonata Y a fetei din fata a zidului plin (treptele
    proiecteaza spre +Y de acolo). `projection`: cat ies treptele din fata
    zidului (0,3-0,6 m, creste usor cu inaltimea ca sa se vada palierele)."""
    faces = []
    half_run_l = apex_x - base_x_left
    half_run_r = base_x_right - apex_x
    n_l = max(int(round((apex_z - base_z) / WELL_STEP_H)), 1)
    n_r = max(int(round((apex_z - base_z) / WELL_STEP_H)), 1)
    step_t = WELL_STEP_H * 0.92  # grosimea verticala a fiecarei trepte (usor sub rise, ca sa se vada muchia)
    # panta stanga: urca de la base_x_left (jos) spre apex_x (sus)
    for k in range(n_l):
        x0 = base_x_left + half_run_l * (k / n_l)
        x1 = base_x_left + half_run_l * ((k + 1) / n_l)
        z_top = base_z + (apex_z - base_z) * ((k + 1) / n_l)
        proj = projection
        faces += list(b.box(((x0 + x1) * 0.5, wall_front_y + proj * 0.5, z_top - step_t * 0.5),
                            (x1 - x0 + 0.02, proj, step_t), slot))
    # panta dreapta: coboara de la apex_x (sus) spre base_x_right (jos)
    for k in range(n_r):
        x0 = apex_x + half_run_r * (k / n_r)
        x1 = apex_x + half_run_r * ((k + 1) / n_r)
        z_top = base_z + (apex_z - base_z) * (1.0 - k / n_r)
        proj = projection
        faces += list(b.box(((x0 + x1) * 0.5, wall_front_y + proj * 0.5, z_top - step_t * 0.5),
                            (x1 - x0 + 0.02, proj, step_t), slot))
    return faces


def build_stepwell_flight_module():
    """REVIZUIRE runda 2 (sef, FAIL -- "fins sticking out perpendicular to
    the wall"): rescris complet. Acum e un zid SOLID (12x3x2,5 m, plin pe
    toata adancimea) cu treptele ca RELIEF PROIECTAT pe fata din fata
    (+Y), nu structuri care strapung tot zidul."""
    b = Builder()
    stone_faces = []
    hw = WELL_MOD_W * 0.5
    hd = WELL_MOD_D * 0.5

    # trei V-uri pe 12 m -> 4 m per V. Varfurile la x = -4, 0, +4; punctele
    # joase (intre V-uri si la capete) la x = -6, -2, +2, +6.
    apexes = [-4.0, 0.0, 4.0]
    lows = [-6.0, -2.0, 2.0, 6.0]
    low_z = WELL_STEP_H * 1.0     # baza joasa, nu chiar 0 -- prag mic de soclu
    apex_z = WELL_MOD_H

    # zidul SOLID de fundal, pe toata amprenta (12 x 2,5 x 3 m) -- masa
    # plina care sustine reliefului treptelor, NU doar o placa subtire de
    # soclu. Fata din fata e la y=+hd; treptele proiecteaza de acolo spre +Y.
    stone_faces += list(b.box((0.0, 0.0, WELL_MOD_H * 0.5),
                              (WELL_MOD_W, WELL_MOD_D, WELL_MOD_H), WELL_STONE))

    wall_front_y = hd
    for i, apex_x in enumerate(apexes):
        base_l = lows[i]
        base_r = lows[i + 1]
        stone_faces += _flight_steps(b, apex_x, base_l, base_r, apex_z, low_z,
                                     wall_front_y, 0.45, WELL_STONE)

    # capete plane la x=+-6, ca sa se inlantuie -- deja acoperite de zidul
    # solid (fata plana pe toata inaltimea), coping (banda usor iesita) pe
    # muchia de sus, pe toata lungimea.
    stone_faces += list(b.box((0.0, 0.0, WELL_MOD_H + 0.06),
                              (WELL_MOD_W + 0.2, WELL_MOD_D + 0.1, 0.12), WELL_STONE))

    stone_obj = b.to_object("Well_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = WELL_STONE
    return stone_obj


# --- stepwell_corner ----------------------------------------------------------
#
# Contract (brief §1.3): 6x6x3 m. Lista de elemente (decupare
# stepwell_corner.png): colt INTERIOR in forma de L -- doua ziduri (fetele
# exterioare) care se intalnesc in unghi de 90 de grade; pe fiecare zid, un
# flux de trepte coboara spre INTERIOR, cele doua fluxuri se intalnesc in
# coltul interior (varful in colt, baza la capetele exterioare ale celor doua
# ziduri). Coronament plat (coping) pe muchia de sus a zidurilor.
WELL_CORNER_SIZE = 6.0


def build_stepwell_corner():
    b = Builder()
    stone_faces = []
    s = WELL_CORNER_SIZE
    apex_z = WELL_MOD_H
    low_z = WELL_STEP_H

    # colt interior la (0,0); ziduri de-a lungul +X (fata la y=0, plan XZ) si
    # +Y (fata la x=0, plan YZ). Pe decupare, cele doua scari coboara DINSPRE
    # colturile exterioare (sus, la marginea zidului) SPRE coltul interior
    # (jos) -- apex (inalt) la capatul exterior, baza (joasa) in colt.
    #
    # brat pe X: de la coltul interior (x=0, jos=low_z) urcand spre x=s
    # (capatul exterior, sus=apex_z). REVIZUIRE runda 2 (sef, "close, accept
    # cu o corectie"): explicit 10 trepte pe flux (nu doar rotunjire din
    # apex_z/WELL_STEP_H, care da 9) -- rise-ul per treapta scade usor
    # (0,27 m in loc de 0,3 m) ca sa incapa exact 10 in cei 2,7 m de urcare.
    n = 10
    for k in range(n):
        x0 = s * (k / n)
        x1 = s * ((k + 1) / n)
        z_top = low_z + (apex_z - low_z) * ((k + 1) / n)
        stone_faces += list(b.box(((x0 + x1) * 0.5, WELL_MOD_D * 0.5, (low_z + z_top) * 0.5),
                                  (x1 - x0 + 0.02, WELL_MOD_D, z_top - low_z), WELL_STONE))
    # brat pe Y: de la coltul interior (y=0, jos) urcand spre y=s (capat, sus)
    for k in range(n):
        y0 = s * (k / n)
        y1 = s * ((k + 1) / n)
        z_top = low_z + (apex_z - low_z) * ((k + 1) / n)
        stone_faces += list(b.box((WELL_MOD_D * 0.5, (y0 + y1) * 0.5, (low_z + z_top) * 0.5),
                                  (WELL_MOD_D, y1 - y0 + 0.02, z_top - low_z), WELL_STONE))
    # zid de fundal (exterior), sustine ambele brate -- doua placi in L,
    # pe toata inaltimea modulului, coronament plat pe muchia de sus.
    stone_faces += list(b.box((s * 0.5, s - 0.15, WELL_MOD_H * 0.5),
                              (s, 0.30, WELL_MOD_H), WELL_STONE))
    stone_faces += list(b.box((s - 0.15, s * 0.5, WELL_MOD_H * 0.5),
                              (0.30, s, WELL_MOD_H), WELL_STONE))
    # coping (banda subtire pe muchia de sus a fiecarui zid)
    stone_faces += list(b.box((s * 0.5, s - 0.15, WELL_MOD_H + 0.06),
                              (s + 0.3, 0.34, 0.12), WELL_STONE))
    stone_faces += list(b.box((s - 0.15, s * 0.5, WELL_MOD_H + 0.06),
                              (0.34, s + 0.3, 0.12), WELL_STONE))

    stone_obj = b.to_object("Well_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = WELL_STONE

    # REVIZUIRE: dupa `finish(origin="base")`, piesa se centreaza pe bbox --
    # zidurile (construite langa x=s/y=s) ajung pe partea +X/+Y, exact spre
    # camera `_neutral_shot` (azimut 35), care le arata ca doua fete PLINE,
    # blocand complet vederea spre interiorul in trepte (colt-ul, la x=y=0
    # inainte de centrare, ajunge pe partea -X/-Y, cu spatele la camera --
    # verificat vizual: prima randare arata doar doi pereti plini, FARA nicio
    # treapta). Fix: rotim 180° in jurul lui Z, ca interiorul deschis (unde
    # coboara treptele) sa ajunga cu fata spre camera.
    for v in stone_obj.data.vertices:
        v.co.x, v.co.y = -v.co.x, -v.co.y
    return stone_obj


# --- stepwell_pavilion ---------------------------------------------------------
#
# Contract (brief §1.3): 20x6 m, 2 etaje, 9 m + cupola centrala pana la 12 m.
#
# REVIZUIRE runda 2 (sef, FAIL -- "floating arches with no walls and a cube
# underneath: parts are detached"): lista de elemente RE-scrisa dupa o
# recitire atenta a decuparii (nu doar din memorie) -- pe crop e o cladire
# CONTINUA, cu UN singur etaj pe aripi (nu doua, cum presupusesem prima
# data):
#   1. Zid SOLID de fundal, plin, pe toata lungimea (20 m), jos (~1,5-2 m).
#   2. Podea/soclu la baza.
#   3. Aripi cu UN singur etaj: colonada de 4 arce ROTUNJITE pe coloane pe
#      fiecare parte, coloanele ating podeaua SI sustin acoperisul (nimic nu
#      pluteste).
#   4. Acoperis PLAT peste toata lungimea (aripi + centru), cu cornisa care
#      iese si un parapet scund pe muchie.
#   5. Chhatri mici la cele DOUA capete exterioare ale acoperisului.
#   6. Pavilion central, PROIECTAT in fata (+Y), pe DOUA etaje: parter cu
#      arc(uri) de intrare, etaj cu balcon (2 arce) intre soclu si cupola,
#      banda de balcon, chajja.
#   7. Cupola MARE nervurata pe tambur, cu finial, deasupra pavilionului
#      central.
# Simetric stanga-dreapta fata de centru.
WELL_PAV_W = 20.0
WELL_PAV_D = 6.0
WELL_PAV_H = 9.0
WELL_PAV_DOME_TOP = 12.0


def build_stepwell_pavilion():
    b = Builder()
    bg = Builder()
    stone_faces = []
    hw = WELL_PAV_W * 0.5

    # REVIZUIRE runda 2 (a doua trecere): fatada (verificata cu testul de
    # fete colorate) e pe +Y -- zidul de fundal trebuie sa stea in SPATE
    # (Y NEGATIV, departe de camera), iar arcada in FATA (Y catre +), altfel
    # zidul plin acopera complet arcada din vederea frontala (exact ce s-a
    # vazut: aripile ieseau ca pereti plini fara nicio arcada vizibila).
    wing_h = WELL_PAV_H * 0.62          # inaltimea aripilor (UN etaj, pana la cornisa)
    col_r = 0.28
    wall_y = -(WELL_PAV_D * 0.5 - 0.3)  # zidul de fundal, aproape de muchia din SPATE (-Y)
    col_y = WELL_PAV_D * 0.5 - col_r * 2  # coloanele arcadei, aproape de muchia din FATA (+Y)

    # 1. zid SOLID de fundal -- plin, pe toata lungimea, de la podea pana la
    # nivelul acoperisului (asta e ce "prinde" arcele -- fara el, coloanele
    # ar sta izolate in aer, exact defectul semnalat).
    stone_faces += list(b.box((0.0, wall_y, wing_h * 0.5),
                              (WELL_PAV_W, 0.35, wing_h), WELL_STONE))

    # 2. podea/soclu la baza, pe toata amprenta (aripi + iesirea centrala)
    slab_h = 0.25
    stone_faces += list(b.box((0.0, 0.0, -slab_h * 0.5), (WELL_PAV_W, WELL_PAV_D, slab_h), WELL_STONE))

    # 3. aripile: colonada de 4 arce rotunjite PE FIECARE parte, intre
    # capatul exterior si pavilionul central -- coloanele ating podeaua
    # (base_z=0) si urca pana la wing_h, unde le prinde cornisa/acoperisul.
    central_half_w = 3.2   # jumatate din latimea ocupata de pavilionul central pe fatada
    n_bays_wing = 4
    for side in (-1.0, 1.0):
        wing_x0 = side * central_half_w
        wing_x1 = side * hw
        res = arcade(b, bg, (wing_x0, col_y, 0.0), (wing_x1, col_y, 0.0), n_bays_wing,
                    wing_h * 0.78, wing_h * 0.10, col_r * 2, 0.55, WELL_STONE, GLOW,
                    style="round", glass=False, base_z=0.0)
        stone_faces += res["stone"]
        # coloanele arcadei (`arcade` foloseste `pier_w`=col_r*2 ca stalpi
        # dreptunghiulari intre arce) ajung la wing_h prin propriul
        # `opening_h+pier_h` -- verificam explicit ca acopera toata
        # inaltimea aripii pana la acoperis (arcada e construita sa
        # opening_h*1 + pier_h_frac*wing_h = wing_h aproximativ; ramane un
        # mic decalaj acoperit de cornisa de mai jos).

    # 4. acoperis PLAT peste toata lungimea (aripi + centru), cu cornisa
    # care iese, sprijinit DIRECT pe coloanele aripilor si pe zidul de
    # fundal -- nu o placa separata plutind deasupra.
    roof_z0 = wing_h
    roof_h = 0.22
    stone_faces += list(b.box((0.0, 0.0, roof_z0 + roof_h * 0.5), (WELL_PAV_W, WELL_PAV_D, roof_h), WELL_STONE))
    # cornisa proeminenta pe muchia frontala a acoperisului (chajja lunga)
    stone_faces += list(chajja(b, (0.0, WELL_PAV_D * 0.5, roof_z0 + roof_h), WELL_PAV_W, 0.5,
                               WELL_STONE, thickness=0.12, slope=0.4))
    # parapet scund pe acoperis
    stone_faces += list(balustrade(b, (-hw + 0.3, 0.0, roof_z0 + roof_h),
                                   (hw - 0.3, 0.0, roof_z0 + roof_h),
                                   0.45, WELL_STONE, merlon_w=0.18, merlon_gap=0.14))

    # 5. chhatri mici la cele DOUA capete exterioare ale acoperisului.
    for side in (-1.0, 1.0):
        cx = side * (hw - 0.6)
        res_ch = chhatri(b, bg, (cx, 0.0, roof_z0 + roof_h), 6, 0.55, 1.1,
                         WELL_STONE, GLOW, col_r=0.09, dome_radius=0.42,
                         arch_style="round", chajja_out=0.18, segments_dome=10)
        stone_faces += res_ch["stone"]

    # 6. pavilion central, PROIECTAT in fata (+Y), doua etaje -- corp SOLID
    # (nu doar coloane) care se conecteaza direct la zidul de fundal comun.
    cw = central_half_w * 2.0
    cy = 0.9   # iese in fata cu 0,9 m peste linia coloanelor aripilor
    floor1_h = WELL_PAV_H * 0.42
    stone_faces += list(b.box((0.0, cy * 0.5, floor1_h * 0.5),
                              (cw, WELL_PAV_D + cy, floor1_h), WELL_STONE))
    # arc de intrare la parter, pe fata din fata a pavilionului central
    res_door = arch_opening(b, bg, (0.0, cy + WELL_PAV_D * 0.5 - 0.05, 0.0), cw * 0.45, floor1_h * 0.92,
                            floor1_h * 0.5, 0.5, WELL_STONE, GLOW, style="round",
                            glass=True, panel_w=cw, panel_h=floor1_h)
    stone_faces += res_door["stone"]

    # balcon la etaj (banda + balustrada pe console) -- se sprijina pe
    # corpul parterului, nu pluteste.
    bal_z = floor1_h
    stone_faces += list(balcony_band(b, (0.0, cy * 0.5, bal_z), cw * 0.5 - 0.2, cw * 0.5 + 0.30,
                                     0.14, WELL_STONE, segments=12))
    stone_faces += list(balustrade(b, (-cw * 0.5 + 0.35, cy + WELL_PAV_D * 0.5 + 0.05, bal_z + 0.14),
                                   (cw * 0.5 - 0.35, cy + WELL_PAV_D * 0.5 + 0.05, bal_z + 0.14),
                                   0.5, WELL_STONE, merlon_w=0.16, merlon_gap=0.12))

    # etaj 2 al pavilionului central: 2 arce pe fatada (colonada deschisa cu
    # chajja), care se leaga in corpul zidului central, nu pluteste separat.
    upper_h = roof_z0 - bal_z - 0.14
    upper_z0 = bal_z + 0.14
    stone_faces += list(b.box((0.0, cy * 0.5, upper_z0 + upper_h * 0.5),
                              (cw, WELL_PAV_D + cy, upper_h), WELL_STONE))
    n_bays_upper = 2
    res_upper = arcade(b, bg, (-cw * 0.5 + 0.3, cy + WELL_PAV_D * 0.5 - 0.02, upper_z0),
                       (cw * 0.5 - 0.3, cy + WELL_PAV_D * 0.5 - 0.02, upper_z0),
                       n_bays_upper, upper_h * 0.75, upper_h * 0.15, 0.30, 0.5,
                       WELL_STONE, GLOW, style="round", glass=True, base_z=upper_z0)
    stone_faces += res_upper["stone"]
    dome_base_z = roof_z0 + 0.30
    stone_faces += list(chajja(b, (0.0, cy + WELL_PAV_D * 0.5, dome_base_z - 0.05), cw + 0.6, 0.4,
                               WELL_STONE, thickness=0.12, slope=0.4))

    # 7. cupola MARE nervurata pe tambur, cu finial, pana la 12 m total.
    remaining = WELL_PAV_DOME_TOP - dome_base_z
    drum_h = remaining * 0.26
    finial_h = remaining * 0.18
    dome_r = remaining - drum_h - finial_h - 0.12
    stone_faces += dome(b, (0.0, cy * 0.5, dome_base_z), dome_r, WELL_STONE, drum_h=drum_h,
                        drum_r=cw * 0.30, profile="hemisphere", segments=16, ribs=12,
                        lotus_ring=True, finial=True, finial_h=finial_h)

    stone_obj = b.to_object("Well_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = WELL_STONE
    glow_obj = _finish_or_none(bg.to_object("Well_Glow"))
    return stone_obj, glow_obj


# --- jaswant_thada ---------------------------------------------------------------
#
# Contract (brief §1.3): 30x20 m amprenta (cu scarile), 14 m inalt. Lista de
# elemente (decupare jaswant_thada.png), de jos in sus / centru spre colturi:
#   1. Soclu in TREPTE (podium), cu scara CENTRALA LATA care urca in fata
#      (spre camera).
#   2. Corpul central: pavilion DESCHIS pe coloane (arce vizibile, interior
#      intunecat), cu o cupola MARE bulboasa/nervurata pe tambur, finial in
#      varf.
#   3. 4 chhatri MICI la colturi (2 stanga, 2 dreapta, la distante diferite
#      fata de centru -- pe decupare par pe DOUA randuri de distanta: unul
#      mai aproape si mai mic langa centru, unul mai indepartat), fiecare pe
#      soclul lui propriu mic.
# Totul MARMURA alba (FOAM_WHITE), cu fetele umbrite / dedesubturile pe
# MARBLE_GREY.
THADA_W = 30.0
THADA_D = 20.0
THADA_H = 14.0


def build_jaswant_thada():
    b = Builder()
    bg = Builder()
    stone_faces = []

    # 1. soclu in trepte -- doua nivele, cel de sus mai ingust, urmat de
    # scara centrala lata care urca pe fata +Y (spre camera).
    plinth_levels = [(THADA_W * 0.72, THADA_D * 0.72, 0.9),
                     (THADA_W * 0.5, THADA_D * 0.5, 0.7)]
    stone_faces += list(stepped_plinth(b, (0.0, 0.0, 0.0), plinth_levels, MARBLE))
    plinth_h = sum(lvl[-1] for lvl in plinth_levels)
    plinth2_hw = THADA_W * 0.25
    plinth2_hd = THADA_D * 0.25

    # REVIZUIRE runda 2 (sef: "stair is odd"): `stair_start` avea Y=8,2 m,
    # dincolo de marginea soclului de jos (jumatate din THADA_D*0,72=7,2 m)
    # -- scara incepea in aer, dincolo de conturul soclului, nu chiar pe
    # muchia lui. Fix: porneste exact la marginea soclului INFERIOR (nivel
    # 1, cel mai lat), la z=0.
    plinth1_hd = THADA_D * 0.72 * 0.5
    stair_w = THADA_W * 0.22
    stair_start = (0.0, plinth1_hd, 0.0)
    stair_end = (0.0, plinth2_hd - 0.1, plinth_h)
    stone_faces += list(solid_stair(b, stair_start, stair_end, stair_w, MARBLE_SHADE,
                                    tread_slot=MARBLE, nosing=False, cheek=True,
                                    cheek_slot=MARBLE_SHADE, step_h=0.24))

    # 2. corp central deschis: coloane + arce + cupola mare
    body_r = min(THADA_W, THADA_D) * 0.20
    body_col_h = THADA_H * 0.38
    res_body = chhatri(b, bg, (0.0, 0.0, plinth_h), 10, body_r, body_col_h,
                       MARBLE, GLOW, col_r=0.22, dome_radius=body_r * 0.72,
                       arch_style="round", chajja_out=0.55, segments_dome=16)
    stone_faces += res_body["stone"]
    dome_base_z = plinth_h + body_col_h + 0.55  # +chajja/plafon din chhatri

    remaining = THADA_H - dome_base_z
    drum_h = remaining * 0.22
    finial_h = min(remaining * 0.16, THADA_H * 0.10)
    dome_r = remaining - drum_h - finial_h - 0.12
    stone_faces += dome(b, (0.0, 0.0, dome_base_z), dome_r, MARBLE, drum_h=drum_h,
                        drum_r=body_r * 0.55, profile="hemisphere", segments=18,
                        ribs=14, lotus_ring=True, finial=True, finial_h=finial_h)

    # 3. 4 chhatri la colturi -- REVIZUIRE runda 2 (sef, FAIL pe compozitie):
    # dupa recitirea decuparii, layout-ul REAL e:
    #   - 2 chhatri MEDII, LIPITE de corpul central, stanga si dreapta,
    #     usor in spate (nu la marginile amprentei) -- domul lor ajunge
    #     cam la 45-50% din inaltimea cupolei centrale.
    #   - 2 chhatri MICI, la colturile EXTERIOARE din FATA, pe soclul de
    #     jos (nu la aceeasi adancime ca cele medii) -- domul lor ajunge
    #     la ~30% din cupola centrala.
    # Runda 1 le pusese pe toate 4 pe acelasi rand, la distante mici intre
    # ele -- citeau "imprastiate" (scattered), nu grupate ca pe decupare.
    med_r = 2.0
    small_r = 1.2
    chhatri_specs = [
        (-THADA_W * 0.20, -THADA_D * 0.02, med_r, THADA_H * 0.44),    # mediu, stanga, langa centru
        (THADA_W * 0.20, -THADA_D * 0.02, med_r, THADA_H * 0.44),     # mediu, dreapta, langa centru
        (-THADA_W * 0.42, THADA_D * 0.16, small_r, THADA_H * 0.30),   # mic, colt exterior stanga-fata
        (THADA_W * 0.42, THADA_D * 0.16, small_r, THADA_H * 0.30),    # mic, colt exterior dreapta-fata
    ]
    for cx, cy, r, total_h in chhatri_specs:
        plinth_r = r * 1.5
        plinth_h2 = 0.5
        stone_faces += list(b.box((cx, cy, plinth_h2 * 0.5), (plinth_r * 2, plinth_r * 2, plinth_h2), MARBLE_SHADE))
        col_h_c = max(total_h - plinth_h2 - r * 1.6, 0.5)  # total_h minus soclu si overhead cupola (masurat ~r*1,6 la r mic)
        res_c = chhatri(b, bg, (cx, cy, plinth_h2), 8, r, col_h_c,
                        MARBLE, GLOW, col_r=0.10 * (r / small_r), dome_radius=r * 0.6,
                        arch_style="round", chajja_out=0.24, segments_dome=12)
        stone_faces += res_c["stone"]

    stone_obj = b.to_object("Thada_Stone")
    for f in stone_faces:
        if f.is_valid:
            f[b.slot] = MARBLE
    glow_obj = _finish_or_none(bg.to_object("Thada_Glow"))
    return stone_obj, glow_obj


# --- emit ------------------------------------------------------------------

clear_built()
results = []


_emitted_objs = []  # toate obiectele exportate pana acum (pentru save_blend la final)


def _dename(name):
    """Strip sufixul Blender de coliziune de nume (`.001`, `.002`, ...)."""
    import re
    return re.sub(r"\.\d{3}$", "", name)


def emit(objs, path, ao, origin="base", bevel=0.03, smooth_angle=45.0,
         budget=None, allow_car_slots=None, bevel_angle=30.0):
    """Ca `emit` din build_jodhpur_pilot.py: offsetul de origine se
    calculeaza O DATA pe ansamblu si se aplica identic tuturor nodurilor.

    REVIZUIRE: mai multe piese din acest fisier refolosesc acelasi nume de
    nod intre ele (`Well_Stone` la toate cele 3 piese de fantana) -- Blender
    dezambiguizeaza automat in scena (`Well_Stone.001`, `.002`, ...), iar
    fara fix GLB-ul exportat avea nodul numit LITERAL "Well_Stone.002"
    (masurat cu verify_glb.py). Fiecare GLB e independent, deci contractul
    de nume per-piesa (brief §1.3) trebuie curat in FIECARE fisier. Fix: dupa
    export, obiectele deja exportate sunt REDENUMITE cu un prefix unic
    (`path`-ul lor), eliberand numele de baza pentru piesa urmatoare care-l
    cere din nou -- `save_blend` de la final nu depinde de nume, doar de
    identitatea obiectelor (pastrate in `_emitted_objs`)."""
    objs = [o for o in objs if o is not None]
    for o in objs:
        o.name = _dename(o.name)
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                        -min(zs)))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                    origin=(origin if solo else None), smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "jodhpur/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    _emitted_objs.extend(objs)
    # elibereaza numele de baza (Well_Stone etc.) pentru piesa URMATOARE --
    # vezi docstring-ul de mai sus. Prefixul e unic per `path`, deci nu
    # coliziune intre piesele deja exportate.
    tag = path.rsplit("/", 1)[-1].replace(".glb", "")
    for o in objs:
        o.name = "_exported_%s_%s" % (tag, o.name)
    return total_tris


AO_GATE = dict(samples=24, dist=6.0, gradient="vertical",
              low=0.42, high=1.00, power=0.85, floor=0.16)
AO_WELL = dict(samples=20, dist=4.0, gradient="vertical",
              low=0.46, high=1.00, power=0.88, floor=0.18)
AO_THADA = dict(samples=22, dist=5.0, gradient="vertical",
                low=0.50, high=1.00, power=0.85, floor=0.22)

gate_stone, gate_doors, gate_glow, gate_crown_z = build_market_gate()
emit([gate_stone, gate_doors, gate_glow], "structures/market_gate.glb",
     AO_GATE, origin="assembly", bevel=0.03, budget=10500)  # runda 2: reveal marit + rise marit pt arc curbat vizibil
print("market_gate: cheie arcului la z=%.2f m (contract >=11.0)" % gate_crown_z)
print("market_gate: gol=%.2f m (contract >=18.0)" % GATE_GAP_W)

well_flight = build_stepwell_flight_module()
emit([well_flight], "structures/stepwell_flight_module.glb", AO_WELL,
     origin="base", bevel=0.02, budget=3600)

well_corner = build_stepwell_corner()
emit([well_corner], "structures/stepwell_corner.glb", AO_WELL,
     origin="base", bevel=0.02, budget=2400)

well_pav_stone, well_pav_glow = build_stepwell_pavilion()
emit([well_pav_stone, well_pav_glow], "structures/stepwell_pavilion.glb", AO_WELL,
     origin="assembly", bevel=0.025, budget=12000)  # runda 2: rescris complet (zid solid + aripi 1 etaj + acoperis + pavilion central 2 etaje), 11201 masurat

thada_stone, thada_glow = build_jaswant_thada()
emit([thada_stone, thada_glow], "structures/jaswant_thada.glb", AO_THADA,
     origin="assembly", bevel=0.025, budget=15000)  # 14552 masurat: corp central + cupola mare nervurata + 4 chhatri de colt

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-46s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL reperele: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([o for o in (gate_stone, gate_doors, gate_glow, well_flight, well_corner,
                        well_pav_stone, well_pav_glow, thada_stone, thada_glow)
           if o is not None], "jodhpur_landmarks.blend")
