"""Cappadocia — BALOANE + HORNUL CRAPAT (plansa, grupurile 4 si 5).

  cappadocia/props/balloon_envelope_{a,b,c}.glb  trei panze umflate, 12 m
  cappadocia/props/balloon_basket.glb            cosul de rachita + arzator
  cappadocia/props/balloon_landed.glb            panza dezumflata, 20x8 m
  cappadocia/props/balloon_tether.glb            cablul + tarusul de ancorare
  cappadocia/rocks/cracked_chimney_{a,b,c}.glb   horn: in picioare / cazut / moloz

**Panza si cosul sunt piese SEPARATE, si asta e o decizie de mecanica**, nu de
comoditate. Brief §3: coșul e platforma pe care poti ateriza
(`platform_velocity`, ca la telecabina — memoria `telecabina-platforma-mobila`)
si e corpul de coliziune; panza e doar un mesh mare care nu trebuie sa aiba
coliziune deloc (un elipsoid de 12 m ar face din balon un zid zburator). Doua
GLB-uri = doua noduri = doua regimuri de coliziune, fara nicio linie de cod
care sa dezactiveze ceva.

**Originile sunt pe punctul de MISCARE, nu la baza bbox-ului:**
  - `balloon_basket` are originea pe PODEAUA cosului (z=0), fiindca masina sta
    pe ea — exact ca podeaua cabinei de telecabina (memoria `chongqing-assets-kit`);
  - `balloon_envelope_*` are originea in punctul de PRINDERE de jos (gura
    panzei), ca sa se ataseze la coș fara offset calculat de mana. Deci panza
    **atarna sub origine**: bbox-ul urca de la 0, dar gura e la 0, nu varful.

**Cele trei stari ale hornului crapat** sunt trei GLB-uri, nu o animatie: brief
§3 cere doua stari plus moloz, comutate din cod (`visible = false` pe cele
nefolosite — garda de triunghiuri nu numara ce nu se randeaza, vezi CLAUDE.md).
Starea (b), hornul cazut, e RAMPA pe care se sare, deci fata ei de sus e o
suprafata continua fara praguri: memoria `suprafete-cu-goluri-si-praguri` —
orice prag lateral peste 0.3 m devine zid pentru o roata de 13 cm.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_balloons.py
"""

import math
from mathutils import Matrix, Vector

AO_FABRIC = dict(samples=14, dist=5.0, gradient="vertical",
                 low=0.62, high=1.00, power=0.7, floor=0.34)
AO_BASKET = dict(samples=26, dist=1.8, gradient="vertical",
                 low=0.46, high=1.00, power=0.9, floor=0.18)
AO_LANDED = dict(samples=16, dist=3.0, gradient="vertical",
                 low=0.58, high=1.00, power=0.8, floor=0.30)
AO_ROCK = dict(samples=20, dist=7.0, gradient="vertical",
               low=0.42, high=1.00, power=0.85, floor=0.14)
AO_RUBBLE = dict(samples=22, dist=3.0, gradient="vertical",
                 low=0.44, high=1.00, power=0.9, floor=0.16)

TUFF = CORAL_SAND
TUFF_MID = SAND_MID
TUFF_SH = SAND_SHADOW
CAP = VOLCANIC_BLACK
CAVE = ROCK_DARK
WICKER = DRY_VEGETATION    # rachita
WOODW = WOOD
IRON = RUST
FLAME = LAVA_ORANGE
# Baloanele sunt singurul loc din decor unde sloturile de MASINA sunt legale:
# brief §4 le aloca explicit (14/15/16), fiindca panzele au nevoie de rosu,
# albastru si galben saturate si nu exista alta sursa in atlas. `verify_glb`
# respinge in mod normal 14-16 in decor — pentru piesele astea se ruleaza cu
# --class-parts sau se accepta avertismentul; e o exceptie DECLARATA, nu o
# scapare. (Vezi brief §4, randul "baloane".)
B_RED, B_BLUE, B_YELLOW = CAR_RED, CAR_BLUE, CAR_YELLOW
B_WHITE = FOAM_WHITE
B_PINK = 31                # NEON_PINK — accent, un balon din zece (brief §4)


def envelope_profile(height, r_max, neck_r, bulge=0.62):
    """Profilul panzei umflate: (raza, z) de la gura pana la coronament.

    Forma reala de balon nu e o sfera: e o para intoarsa — gura ingusta jos,
    diametrul maxim la ~62% din inaltime, si un coronament aproape plat sus.
    `bulge` e cota diametrului maxim; sub 0.55 iese lacrima, peste 0.70 iese
    ciuperca.
    """
    prof = []
    n = 9
    for i in range(n + 1):
        t = i / n
        if t < bulge:
            u = t / bulge
            r = neck_r + (r_max - neck_r) * math.sin(u * math.pi * 0.5) ** 0.85
        else:
            u = (t - bulge) / (1.0 - bulge)
            r = r_max * math.cos(u * math.pi * 0.5) ** 0.62
        prof.append((max(r, 0.0), height * t))
    return prof


def build_envelope(variant):
    """Trei panze: crem simplu, cu felii verticale colorate, cu benzi orizontale.

    Feliile sunt `retag` pe fetele generate de `revolve`, deci culoarea costa
    ZERO triunghiuri — exact ce cere un obiect care apare in 20-30 de exemplare
    in vale (brief §2 POI C). 16 segmente: sub 12 se vede poligonul pe silueta
    rotunda a unui balon, peste 20 nu mai castiga nimic la 30+ m distanta.
    """
    b = Builder()
    H, R = 12.0, 4.6
    segments = 16
    prof = envelope_profile(H, R, 0.85)
    faces = b.revolve(prof, B_WHITE, segments=segments, cap_bottom=False)

    if variant == 0:
        # crem cu o singura banda: balonul "de fundal"
        b.retag(faces, TUFF, where=lambda c, n: c.z < H * 0.30)
        b.retag(faces, B_RED, where=lambda c, n: H * 0.72 < c.z < H * 0.82)
    elif variant == 1:
        # felii verticale alternante — semnatura de balon
        cols = (B_RED, B_WHITE, B_BLUE, B_YELLOW)
        for f in faces:
            c = f.calc_center_median()
            k = int(((math.atan2(c.y, c.x) + math.pi) / (2 * math.pi)) * segments)
            f[b.slot] = cols[k % len(cols)]
    else:
        # benzi orizontale late
        bands = ((0.00, 0.22, B_BLUE), (0.22, 0.40, B_WHITE),
                 (0.40, 0.58, B_RED), (0.58, 0.76, B_WHITE),
                 (0.76, 1.01, B_YELLOW))
        for (lo, hi, slot) in bands:
            b.retag(faces, slot,
                    where=lambda c, n, lo=lo, hi=hi: H * lo <= c.z < H * hi)

    # cusaturile verticale: nervuri subtiri, care dau volum siluetei
    for k in range(0, segments, 2):
        a = 2.0 * math.pi * k / segments
        pts, radii = [], []
        for (r, z) in prof:
            pts.append(((r + 0.06) * math.cos(a), (r + 0.06) * math.sin(a), z))
            radii.append(0.055)
        b.taper_sweep(pts, radii, TUFF_SH, segments=4, cap_start=False,
                      cap_end=False)
    # gura panzei: inelul de jos, cu care se prinde de cablurile cosului
    b.torus((0.0, 0.0, 0.06), 0.88, 0.09, WOODW, major_seg=segments, minor_seg=4)
    return b.to_object("Balloon_Envelope_" + "ABC"[variant])


def build_basket():
    """Cosul: 2x2 m de rachita + arzator + montanti.

    Originea e pe PODEA (z=0): brief §3 spune ca poti ateriza pe cos si el te
    duce sus, deci podeaua e suprafata de contact si trebuie sa fie exact la
    originea nodului (memoria `telecabina-platforma-mobila`).
    """
    b = Builder()
    W, H = 2.0, 1.25
    T = 0.10
    # podeaua — fata de sus e ce atinge masina, deci e o placa plina
    b.box((0.0, 0.0, -T * 0.5), (W, W, T), WOODW)
    # peretii de rachita: patru panouri + impletitura sugerata din sipci
    for (sx, sy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        c = (sx * W * 0.5, sy * W * 0.5, H * 0.5)
        size = (T, W, H) if sx else (W, T, H)
        b.box(c, size, WICKER)
        # trei nervuri orizontale pe fiecare panou (impletitura la distanta)
        for z in (H * 0.25, H * 0.55, H * 0.85):
            s2 = (T * 1.6, W * 1.02, 0.09) if sx else (W * 1.02, T * 1.6, 0.09)
            b.box((c[0], c[1], z), s2, WOODW)
    # colturile
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * W * 0.5, sy * W * 0.5, H * 0.5), (0.14, 0.14, H + 0.06),
                  WOODW)
    # montantii spre arzator
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.beam((sx * (W * 0.5 - 0.08), sy * (W * 0.5 - 0.08), H),
                   (sx * 0.34, sy * 0.34, H + 1.35), 0.075, IRON)
    # arzatorul: rama + doua duze + flacara (emisiv la integrare)
    b.box((0.0, 0.0, H + 1.42), (0.86, 0.86, 0.14), IRON)
    for sx in (-1.0, 1.0):
        b.cylinder((sx * 0.22, 0.0, H + 1.62), 0.15, 0.34, IRON, segments=8)
    b.taper_sweep([(0.0, 0.0, H + 1.80), (0.0, 0.0, H + 2.28),
                   (0.0, 0.0, H + 2.62)], [0.30, 0.20, 0.0], FLAME, segments=8)
    # butelii in cos
    for sx in (-1.0, 1.0):
        b.cylinder((sx * 0.55, -0.55, 0.42), 0.20, 0.84, IRON, segments=8)
    return b.to_object("Balloon_Basket")


def build_balloon_landed():
    """Panza dezumflata, intinsa 20x8 m peste drum (brief §2 POI E).

    Suprafata e LENTA (0.6x) la integrare, deci geometria trebuie sa fie
    aproape PLATA: o panza cu cute de 40 cm ar fi praguri pentru o roata de
    13 cm (memoria `suprafete-cu-goluri-si-praguri`). Cutele de aici au 12-18
    cm si sunt lungi si line — se vad, dar nu se simt in volan.

    Culoarea e tare (dungi saturate) fiindca e semnal de gameplay: trebuie sa
    citesti de la 60 m ca drumul e acoperit.
    """
    b = Builder()
    L, W = 20.0, 8.0
    nx, ny = 14, 7
    cols = (B_RED, B_WHITE, B_BLUE, B_YELLOW, B_WHITE)
    verts = []
    rand = _lcg(7703)
    for i in range(nx + 1):
        row = []
        for j in range(ny + 1):
            x = -L * 0.5 + L * i / nx
            y = -W * 0.5 + W * j / ny
            # cutele: doua unde lungi + zgomot mic. Amplitudine max 0.18 m.
            z = (0.10 * math.sin(x * 0.55 + y * 0.30)
                 + 0.06 * math.sin(y * 1.1 - x * 0.2)
                 + (rand() - 0.5) * 0.03)
            # marginile cad la zero: panza atinge solul, nu pluteste
            edge = min(1.0, min(i, nx - i) / 2.2) * min(1.0, min(j, ny - j) / 1.6)
            row.append(b.bm.verts.new((x, y, 0.02 + z * edge)))
        verts.append(row)
    faces = []
    for i in range(nx):
        for j in range(ny):
            faces.append(b.bm.faces.new((verts[i][j], verts[i + 1][j],
                                         verts[i + 1][j + 1], verts[i][j + 1])))
    # dungile: pe latime, ca sa se citeasca traversand drumul
    for f in faces:
        c = f.calc_center_median()
        k = int((c.x + L * 0.5) / L * 5.0)
        f[b.slot] = cols[min(k, 4)]
    # gura panzei, la un capat: inelul care se strange
    b.torus((-L * 0.5 + 0.5, 0.0, 0.22), 1.05, 0.16, WOODW, major_seg=10,
            minor_seg=4)
    return b.to_object("Balloon_Landed")


def build_balloon_tether():
    """Cablul de ancorare + tarusul. Piesa mica dar necesara: brief §2 POI C
    spune ca baloanele care urca sunt ANCORATE, iar fara cablu vizibil un balon
    care se opreste la 30 m si coboara arata ca un bug, nu ca o macara.

    Cablul e un tub de 6 cm pe 30 m: la distanta dispare in ceata, dar de
    aproape (cand cosul e la bandă) se vede si explica mecanica.
    """
    b = Builder()
    LEN = 30.0
    # tarusul: pana in pamant + inel
    b.taper_sweep([(0.0, 0.0, 0.5), (0.0, 0.0, -0.6)], [0.13, 0.0], IRON,
                  segments=6)
    b.torus((0.0, 0.0, 0.52), 0.20, 0.05, IRON, major_seg=8, minor_seg=4)
    # cablul: usor curbat, ca sa nu para o teava
    pts, radii = [], []
    n = 8
    for i in range(n + 1):
        t = i / n
        pts.append((0.35 * math.sin(t * 1.4), 0.22 * t, 0.55 + LEN * t))
        radii.append(0.055)
    b.taper_sweep(pts, radii, IRON, segments=4)
    # doi saci de balast la baza
    for sx in (-1.0, 1.0):
        b.box((sx * 0.55, 0.30, 0.22), (0.62, 0.44, 0.44), WICKER)
    return b.to_object("Balloon_Tether")


# --- hornul crapat, trei stari ----------------------------------------------

CC_H, CC_RB, CC_RN = 16.0, 2.55, 0.95


def _cracked_body(b, seed=8801, cracks=True):
    """Corpul hornului crapat — folosit si de starea (a), si (dupa rotire) de (b).

    Crapaturile sunt benzi `retag` in slot inchis + trei santuri putin adancite.
    Telegraph-ul din brief §3 (pietricele + praf + trosnet 2 s) e cod si
    particule; ce trebuie sa dea assetul e ca hornul sa arate CRAPAT inainte sa
    cada — altfel prabusirea pare arbitrara.
    """
    prof = []
    rand = _lcg(seed)
    for i in range(8):
        t = i / 7.0
        r = CC_RB + (CC_RN - CC_RB) * (t ** 0.62)
        r *= 1.0 + (rand() - 0.5) * 0.13
        prof.append((r, CC_H * t))
    faces = b.revolve(prof, TUFF, segments=9)
    b.retag(faces, TUFF_SH, where=lambda c, n: c.z < CC_H * 0.20)
    b.retag(faces, TUFF_MID, where=lambda c, n: CC_H * 0.44 < c.z < CC_H * 0.60)
    if cracks:
        # trei crapaturi: santuri inguste intrate in corp, la inaltimi diferite
        for (z, a_deg, ln) in ((4.2, 20.0, 3.4), (7.8, -110.0, 4.6),
                               (11.0, 140.0, 2.8)):
            a = math.radians(a_deg)
            t = z / CC_H
            r = (CC_RB + (CC_RN - CC_RB) * (t ** 0.62)) * 0.96
            b.box((r * math.cos(a), r * math.sin(a), z), (0.5, 0.20, ln),
                  CAVE, rotation=Matrix.Rotation(a, 3, "Z"))
    # palaria de bazalt
    b.frustum((0.0, 0.0, CC_H - 0.35), CC_RN * 1.02, CC_RN * 1.95, 0.70, CAP,
              segments=9)
    b.frustum((0.0, 0.0, CC_H + 0.42), CC_RN * 1.95, CC_RN * 1.45, 0.85, CAP,
              segments=9)
    return faces


def build_cracked_a():
    """(a) In picioare, crapat. Sta in mijlocul drumului (brief §2 POI D)."""
    b = Builder()
    _cracked_body(b)
    # cateva pietricele deja cazute la baza: telegraph static
    rand = _lcg(9001)
    for k in range(5):
        a = 2.0 * math.pi * rand()
        r = CC_RB * (1.05 + rand() * 0.6)
        s = 0.18 + rand() * 0.24
        b.rock((r * math.cos(a), r * math.sin(a), 0.0), (s * 2.0, s * 1.7, s),
               TUFF_SH, seed=int(rand() * 900), segments=5, rings=3, taper=0.5)
    return b.to_object("Cracked_Chimney_A")


def build_cracked_b():
    """(b) Cazut — **e RAMPA**, deci geometria de sus e contract de gameplay.

    Hornul culcat da o panta naturala doar daca varful lui e in jos si baza in
    sus... ceea ce e invers fata de cum cade in realitate. Solutia (si asa e si
    in plansa): hornul cade peste un prag de moloz, deci **baza lui ramane
    ridicata pe molozul propriu**, iar corpul coboara spre varf. Panta iese din
    diferenta de raza: baza 2.55 m, varf 0.95 m, pe 16 m lungime.

    Fata de rulare e o BANDA PLATA sapata in corpul culcat (nu suprafata
    cilindrica: o roata pe un cilindru de 2.5 m raza aluneca lateral). Banda
    are 4.5 m latime si margini in PANTA, nu praguri — regula din memoria
    `suprafete-cu-goluri-si-praguri`.
    """
    b = Builder()
    L = CC_H
    # corpul culcat: trunchi de con orizontal, cu axa pe X
    n = 9
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        x0, x1 = -L * 0.5 + L * t0, -L * 0.5 + L * t1
        r0 = CC_RB + (CC_RN - CC_RB) * (t0 ** 0.62)
        r1 = CC_RB + (CC_RN - CC_RB) * (t1 ** 0.62)
        # inclinatia: capatul gros e mai sus (sta pe moloz)
        z0 = 2.30 * (1.0 - t0) + 0.55
        z1 = 2.30 * (1.0 - t1) + 0.55
        slot = TUFF_SH if t0 < 0.18 else (TUFF_MID if 0.42 < t0 < 0.62 else TUFF)
        b.taper_sweep([(x0, 0.0, z0), (x1, 0.0, z1)], [r0, r1], slot,
                      segments=9, cap_start=(i == 0), cap_end=(i == n - 1))

    # banda de rulare: placa plata sapata pe spatele hornului culcat.
    # Se aseaza PESTE cilindru cu 0.12 m, ca sa nu ramana o dunga de
    # z-fighting pe muchie (memoria `suprafete-suprapuse-si-valuri`).
    # Banda e o fasie CONTINUA de varfuri partajate — nu placi independente.
    # Prima versiune facea cate un quad per pas, fiecare cu varfurile lui: la
    # randarea de control se vedeau TREPTE de ~15 cm intre placi, adica exact
    # pragurile-zid din memoria `suprafete-cu-goluri-si-praguri` (roata are
    # 13 cm pana la podea). Cu varfuri partajate suprafata e neteda prin
    # constructie, indiferent cate segmente are.
    BW = 4.5
    steps = 12
    rows = []
    for i in range(steps + 1):
        t = i / steps
        x = -L * 0.5 + L * t
        r = CC_RB + (CC_RN - CC_RB) * (t ** 0.62)
        z = 2.30 * (1.0 - t) + 0.55 + r - 0.12
        w = min(BW, r * 1.75)
        rows.append((
            b.bm.verts.new((x, -(w * 0.5 + 0.55), z - 0.30)),   # buza stanga
            b.bm.verts.new((x, -w * 0.5, z)),
            b.bm.verts.new((x, w * 0.5, z)),
            b.bm.verts.new((x, w * 0.5 + 0.55, z - 0.30)),      # buza dreapta
        ))
    for a_row, b_row in zip(rows, rows[1:]):
        for k in range(3):
            f = b.bm.faces.new((a_row[k], a_row[k + 1], b_row[k + 1], b_row[k]))
            # doar fasia din mijloc e carosabil; buzele sunt panta de racordare
            f[b.slot] = ASPHALT_EDGE if k == 1 else TUFF_MID

    # palaria, desprinsa si cazuta langa varf
    b.frustum((L * 0.5 + 1.6, 1.9, 0.55), CC_RN * 1.95, CC_RN * 1.45, 0.80, CAP,
              segments=9, axis="Y")
    # molozul pe care sta capatul gros — el e ce face rampa sa inceapa lin
    rand = _lcg(9101)
    for k in range(9):
        s = 0.45 + rand() * 0.85
        b.rock((-L * 0.5 + (rand() - 0.2) * 2.6, (rand() - 0.5) * 4.4, 0.0),
               (s * 2.2, s * 1.9, s), TUFF_SH, seed=int(rand() * 900),
               segments=6, rings=3, taper=0.50)
    return b.to_object("Cracked_Chimney_B")


def build_cracked_c():
    """(c) Moloz: gramada joasa, grip 0.8x la integrare (brief §2 POI D).

    Trebuie sa fie JOASA (max 1.4 m) si fara bolovan izolat mai inalt de 0.5 m
    langa margine: altfel e un zid ascuns intr-o textura de pietris.
    """
    b = Builder()
    rand = _lcg(9201)
    # movila de baza, turtita
    b.rock((0.0, 0.0, 0.0), (9.5, 6.4, 1.15), TUFF_SH, seed=331, segments=8,
           rings=3, flat_top=True, taper=0.55)
    # bolovani peste ea, descrescatori spre margini
    for k in range(22):
        a = 2.0 * math.pi * rand()
        rr = rand() ** 0.6
        x, y = 4.2 * rr * math.cos(a), 2.9 * rr * math.sin(a)
        s = (0.30 + rand() * 0.55) * (1.15 - rr * 0.55)
        slot = TUFF if rand() < 0.55 else TUFF_MID
        b.rock((x, y, 0.35 * (1.0 - rr)), (s * 2.1, s * 1.8, s), slot,
               seed=int(rand() * 900), segments=5, rings=3, taper=0.55)
    # cioburi de palarie: pete negre care spun DE UNDE vine molozul
    for k in range(4):
        a = 2.0 * math.pi * rand()
        s = 0.28 + rand() * 0.30
        b.rock((3.0 * rand() * math.cos(a), 2.0 * rand() * math.sin(a), 0.55),
               (s * 2.4, s * 2.0, s * 0.7), CAP, seed=int(rand() * 900),
               segments=5, rings=2, flat_top=True, taper=0.4)
    return b.to_object("Cracked_Chimney_C")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.035):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


for v in range(3):
    emit(build_envelope(v), "props/balloon_envelope_%s.glb" % "abc"[v],
         AO_FABRIC, origin="base_axis", bevel=0.02)
emit(build_basket(), "props/balloon_basket.glb", AO_BASKET,
     origin="base_axis", bevel=0.015)
emit(build_balloon_landed(), "props/balloon_landed.glb", AO_LANDED, bevel=0.02)
emit(build_balloon_tether(), "props/balloon_tether.glb", AO_BASKET,
     origin="base_axis", bevel=0.015)
emit(build_cracked_a(), "rocks/cracked_chimney_a.glb", AO_ROCK, bevel=0.05)
emit(build_cracked_b(), "rocks/cracked_chimney_b.glb", AO_ROCK, bevel=0.045)
emit(build_cracked_c(), "rocks/cracked_chimney_c.glb", AO_RUBBLE, bevel=0.04)

print()
for path, tris, kb in results:
    print("%-42s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL baloane+horn: %d tris" % sum(t for _, t, _ in results))
