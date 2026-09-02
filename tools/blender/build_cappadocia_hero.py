"""Cappadocia — HERO: piesele unice, cate una pe pista (plansa, grupurile 1, 6, 7, 8).

  cappadocia/structures/hollow_rock.glb        stanca-castel goala cu spirala interioara
  cappadocia/structures/twin_chimney_gate.glb  poarta de hornuri gemene (POI B)
  cappadocia/structures/cave_entrance.glb      gura orasului subteran (POI F)
  cappadocia/structures/vent_shaft.glb         putul de ventilatie (POI F)

**`hollow_rock` e cea mai grea piesa din tot proiectul** si singura al carei
INTERIOR e pista. Geometria e derivata, si pe drum a corectat brief-ul §5.2 —
cifrele de acolo (baza 70 m, varf 30 m, raza elicei 28 m) **nu inchid**:

Brief-ul §5.2 da trei cifre — baza 70 m, varf 30 m, **2 ture cu raza 28 m** —
si ele **nu inchid**. Doua masuratori, in ordinea in care au aparut:

  - o stanca ce se subtiaza de la 70 m la 30 m nu poate tine o elice de raza
    28 m: la varf raza interioara utila ramane 10.2 m, adica panta ar sari de
    la 10.8% la ~30%. Prima incercare a facut stanca aproape cilindrica
    (76 m constant) ca sa incapa raza 28 — a trecut aritmetica, dar randarea
    de control a aratat **o galeata**: la 76 m diametru, o rampa de 7 m pe
    perete e o dunga, iar interiorul e 60 m de gol. Silueta murise.
  - **Corectia care tine amandoua:** nu raza se pastreaza, ci PANTA. Cu
    **3 ture la raza 18 m** ies 339 m de rampa -> **11.2%**, deci sub 13% cu
    aceeasi marja ca varianta din brief, dar stanca scade la **49 m diametru**
    (18 + 3.5 rampa + 3 perete, x2). La scara aia rampa ocupa o treime din
    raza si spirala se CITESTE ca spirala din orice unghi.
  - Separarea intre ture devine 38/3 = **12.7 m**, tot peste cele 12 m cerute
    de `custom_overpass_ranges` (PR #353) — verificat inainte de a alege 3, nu
    dupa. Cu 3.5 ture ar fi picat la 10.9 m si sonda ar fi respins-o.
  - **Diferente fata de brief, de notat la integrare:** 3 ture in loc de 2,
    raza 18 in loc de 28, baza 49 m in loc de 70 m. Lotul din harta se
    MICSOREAZA, nu creste.

Rampa e modelata ca **geometrie de decor**, nu ca sosea: soseaua reala o
genereaza `TrackFromPath` din Curve3D (memoria `pista-peste-pista`). Ce
livram aici e stanca din jurul ei + o consola pe care sa se sprijine vizual,
altfel rampa ar pluti. De-aia rampa din GLB e usor MAI LATA (7 m) decat
carosabilul (6 m): asfaltul se aseaza peste ea si o acopera, in loc sa lase o
dunga de z-fighting pe margine (memoria `suprafete-suprapuse-si-valuri`).

`origin="base_axis"`: axa cilindrului e originea, nu centrul bbox-ului —
spirala se aliniaza cu Curve3D-ul pe axa, iar ferestrele au azimuturi fixe.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_hero.py
"""

import math
from mathutils import Matrix, Vector

AO_HERO = dict(samples=14, dist=14.0, gradient="vertical",
               low=0.34, high=1.00, power=0.80, floor=0.10)
AO_GATE = dict(samples=18, dist=9.0, gradient="vertical",
               low=0.42, high=1.00, power=0.85, floor=0.14)
AO_CAVE = dict(samples=26, dist=6.0, gradient="vertical",
               low=0.30, high=1.00, power=0.95, floor=0.08)
AO_SHAFT = dict(samples=22, dist=5.0, gradient="vertical",
                low=0.36, high=1.00, power=0.90, floor=0.10)

TUFF = CORAL_SAND
TUFF_MID = SAND_MID
TUFF_SH = SAND_SHADOW
CAP = VOLCANIC_BLACK
CAVE = ROCK_DARK           # interiorul sapat — mereu mai inchis ca exteriorul
BAND_RED = TILE_TERRACOTTA
BAND_RUST = LARCH_RUST
ROAD = ASPHALT_EDGE        # pamant batut pe rampa interioara
FLAME = LAVA_ORANGE        # emisiv la integrare (reuse shaderul de lava)
IRON = RUST
WOODW = WOOD


# --- hollow_rock -------------------------------------------------------------

HR_H = 45.0                # inaltime
HR_R_BASE = 24.5           # raza la baza (diametru 49 m) — vezi docstring
HR_R_TOP = 21.5            # raza la varf (diametru 43 m)
HR_WALL = 3.0              # grosimea peretelui la baza
HR_WALL_TOP = 2.2          # ... si la varf; ambele intra in calculul de raza
HR_RAMP_R = 18.0           # raza axei rampei elicoidale (11.2% pe 3 ture)
HR_RAMP_W = 7.0            # latimea rampei (7 > 6 al carosabilului, vezi docstring)
HR_TURNS = 3.0
HR_Z0 = 3.0                # cota de intrare a rampei (fata de baza piesei)
HR_RISE = 38.0             # urcarea totala a elicei


def _hr_radius(z, r_base=HR_R_BASE, r_top=HR_R_TOP):
    """Raza exterioara la cota z — conul trunchiat al stancii."""
    t = min(max(z / HR_H, 0.0), 1.0)
    return r_base + (r_top - r_base) * (t ** 0.88)


def hollow_shell(b, segments=28):
    """Peretele: doua suprafete de revolutie (exterior + interior) cusute la
    coronament. NU e un cilindru gol facut cu boolean — un boolean pe 45 m de
    geometrie ar fi lasat n-gon-uri degenerate exact pe muchia pe care se
    sprijina rampa.

    Peretele se subtiaza cu inaltimea (3.0 m jos -> 2.2 m sus): asa citeste ca
    stanca erodata, si asa incape raza de 18 m a rampei pana sus — raza
    interioara ramane >= 21.5 m pe toata inaltimea (vezi docstring-ul modulului).
    """
    rings_out, rings_in = [], []
    rand = _lcg(1301)
    zs = [i * HR_H / 9.0 for i in range(10)]
    for z in zs:
        r_o = _hr_radius(z)
        wall = HR_WALL + (HR_WALL_TOP - HR_WALL) * (z / HR_H)
        r_i = r_o - wall
        ring_o, ring_i = [], []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            # perturbatie determinista: stanca, nu turn de racire
            w = 1.0 + (rand() - 0.5) * 0.055
            ring_o.append(b.bm.verts.new((r_o * w * math.cos(a),
                                          r_o * w * math.sin(a), z)))
            ring_i.append(b.bm.verts.new((r_i * math.cos(a),
                                          r_i * math.sin(a), z)))
        rings_out.append(ring_o)
        rings_in.append(ring_i)

    faces_out, faces_in = [], []
    for lo, hi in zip(rings_out, rings_out[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            faces_out.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    for lo, hi in zip(rings_in, rings_in[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            faces_in.append(b.bm.faces.new((lo[j], lo[i], hi[i], hi[j])))
    # coronamentul: inelul care leaga exteriorul de interior sus
    top_o, top_i = rings_out[-1], rings_in[-1]
    crown = []
    for i in range(segments):
        j = (i + 1) % segments
        crown.append(b.bm.faces.new((top_o[i], top_o[j], top_i[j], top_i[i])))
    # talpa: inelul de jos, ca piesa sa nu fie deschisa pe dedesubt
    bot_o, bot_i = rings_out[0], rings_in[0]
    for i in range(segments):
        j = (i + 1) % segments
        b.bm.faces.new((bot_o[j], bot_o[i], bot_i[i], bot_i[j]))

    for f in faces_out:
        f[b.slot] = TUFF
    for f in faces_in:
        f[b.slot] = CAVE
    for f in crown:
        f[b.slot] = TUFF_MID
    # benzile exterioare: doua fasii de culoare pe inaltime, zero triunghiuri
    b.retag(faces_out, TUFF_SH, where=lambda c, n: c.z < HR_H * 0.10)
    b.retag(faces_out, BAND_RED, where=lambda c, n: HR_H * 0.16 < c.z < HR_H * 0.27)
    b.retag(faces_out, BAND_RUST, where=lambda c, n: HR_H * 0.40 < c.z < HR_H * 0.46)
    b.retag(faces_out, TUFF_MID, where=lambda c, n: HR_H * 0.62 < c.z < HR_H * 0.74)
    return faces_out, faces_in


def helix_ramp(b, steps=96):
    """Rampa elicoidala pe interiorul peretelui: banda + parapet + consola.

    Banda e o serie de quad-uri intre raza interioara si exterioara a rampei,
    la cote care urca liniar. Nu folosim `taper_sweep` fiindca aici sectiunea
    e o PLACA orizontala (drum), nu un tub: un tub ar da o balustrada rotunda
    pe care masina n-are pe ce sa stea.
    """
    r_in = HR_RAMP_R - HR_RAMP_W * 0.5
    r_out = HR_RAMP_R + HR_RAMP_W * 0.5
    T = 0.55                                  # grosimea placii
    verts = []
    for i in range(steps + 1):
        t = i / steps
        a = 2.0 * math.pi * HR_TURNS * t
        z = HR_Z0 + HR_RISE * t
        ca, sa = math.cos(a), math.sin(a)
        verts.append((
            b.bm.verts.new((r_in * ca, r_in * sa, z)),
            b.bm.verts.new((r_out * ca, r_out * sa, z)),
            b.bm.verts.new((r_in * ca, r_in * sa, z - T)),
            b.bm.verts.new((r_out * ca, r_out * sa, z - T)),
        ))
    top, side_in, side_out, bottom = [], [], [], []
    for (a_in, a_out, a_ind, a_outd), (b_in, b_out, b_ind, b_outd) in zip(verts, verts[1:]):
        top.append(b.bm.faces.new((a_in, a_out, b_out, b_in)))
        bottom.append(b.bm.faces.new((a_ind, b_ind, b_outd, a_outd)))
        side_in.append(b.bm.faces.new((a_in, b_in, b_ind, a_ind)))
        side_out.append(b.bm.faces.new((a_out, a_outd, b_outd, b_out)))
    for f in top:
        f[b.slot] = ROAD
    for f in bottom + side_in:
        f[b.slot] = CAVE
    for f in side_out:
        f[b.slot] = TUFF_SH

    # parapetul de pe marginea INTERIOARA (spre gol) — buza joasa, nu zid:
    # brief §2.0, marginile fara parapet se taie in panta; aici e o buza de
    # 0.45 m, sub raza rotii (13 cm podea) ca sa nu fie prag-zid
    # (memoria `suprafete-cu-goluri-si-praguri`).
    for i in range(0, steps, 2):
        t = i / steps
        a = 2.0 * math.pi * HR_TURNS * t
        z = HR_Z0 + HR_RISE * t
        ca, sa = math.cos(a), math.sin(a)
        step_a = 2.0 * math.pi * HR_TURNS * (2.0 / steps)
        ln = r_in * step_a
        rot = Matrix.Rotation(a, 3, "Z")
        b.box((r_in * ca, r_in * sa, z + 0.20), (0.42, ln * 1.06, 0.40),
              TUFF_MID, rotation=rot)

    # consolele care sprijina rampa de perete la fiecare 1/8 de tura
    n_brace = int(HR_TURNS * 7)
    for k in range(1, n_brace):
        t = k / float(n_brace * 1.0) / HR_TURNS * HR_TURNS
        t = k / float(n_brace)
        a = 2.0 * math.pi * HR_TURNS * t
        z = HR_Z0 + HR_RISE * t
        ca, sa = math.cos(a), math.sin(a)
        wall_r = _hr_radius(z) - (HR_WALL + (HR_WALL_TOP - HR_WALL) * (z / HR_H))
        b.beam((r_out * ca, r_out * sa, z - T),
               (wall_r * ca, wall_r * sa, max(z - 4.2, 0.4)), 0.85, TUFF_SH)


def rock_windows(b, count=16):
    """Ferestrele spre vale: gauri REALE prin perete (aici chiar trebuie sa fie
    reale — prin ele se vad baloanele, brief §2 POI G).

    O "gaura pictata" ar fi mers pe un horn de langa drum, dar nu si aici:
    jucatorul urca lipit de perete si se uita PRIN ele. Gaura se face cu doua
    cadre (exterior + interior) cusute, adica un tunel scurt de 4 fete — mai
    ieftin decat un boolean si fara n-gon-uri.
    """
    rand = _lcg(2207)
    for k in range(count):
        t = (k + 0.5) / count
        a = 2.0 * math.pi * (0.37 + 2.13 * t)
        z = 6.0 + 33.0 * t
        w = 2.0 + rand() * 1.6
        h = 2.4 + rand() * 1.8
        r_o = _hr_radius(z)
        wall = HR_WALL + (HR_WALL_TOP - HR_WALL) * (z / HR_H)
        ca, sa = math.cos(a), math.sin(a)
        rot = Matrix.Rotation(a, 3, "Z")
        # ancadramentul: patru cutii care formeaza rama, deci golul e real
        for (dz, hh) in ((h * 0.5 + 0.35, 0.70), (-h * 0.5 - 0.35, 0.70)):
            b.box(((r_o - wall * 0.5) * ca, (r_o - wall * 0.5) * sa, z + dz),
                  (wall * 1.05, w + 1.4, hh), CAVE, rotation=rot)
        for sy in (-1.0, 1.0):
            off = sy * (w * 0.5 + 0.35)
            px = (r_o - wall * 0.5) * ca - off * sa
            py = (r_o - wall * 0.5) * sa + off * ca
            b.box((px, py, z), (wall * 1.05, 0.70, h), CAVE, rotation=rot)


def build_hollow_rock():
    b = Builder()
    hollow_shell(b)
    helix_ramp(b)
    rock_windows(b)

    # gura de sus: taietura in coronament prin care iesi cu kickerul (POI G).
    # E un prag COBORAT, nu o gaura: rampa ajunge la 41 m, coronamentul e la
    # 45 m, deci lipsesc 4 m — se taie o sa in perete pe ~34° de arc.
    a_exit = 2.0 * math.pi * HR_TURNS          # unde se termina elicea
    for k in range(6):
        a = a_exit + math.radians(-17.0 + k * 6.8)
        z = HR_H - 2.0
        r_o = _hr_radius(z)
        ca, sa = math.cos(a), math.sin(a)
        rot = Matrix.Rotation(a, 3, "Z")
        b.box(((r_o - 1.6) * ca, (r_o - 1.6) * sa, z + 1.4),
              (4.6, 5.2, 4.0), CAVE, rotation=rot)

    # fagurele de la Uchisar: gauri mici de porumbar pe fata exterioara,
    # doar in treimea de sus (unde le vezi de pe platou, nu de pe rampa)
    rand = _lcg(3301)
    for k in range(26):
        a = 2.0 * math.pi * rand()
        z = HR_H * (0.52 + 0.42 * rand())
        r_o = _hr_radius(z)
        s = 0.55 + rand() * 0.45
        ca, sa = math.cos(a), math.sin(a)
        b.box(((r_o - 0.25) * ca, (r_o - 0.25) * sa, z), (0.6, s, s * 1.2),
              CAVE, rotation=Matrix.Rotation(a, 3, "Z"))

    # moloz la baza: leaga stanca de teren (fara el pare pusa pe masa)
    for k in range(16):
        a = 2.0 * math.pi * rand()
        s = 1.2 + rand() * 2.4
        r = HR_R_BASE * (0.98 + rand() * 0.10)
        b.rock((r * math.cos(a), r * math.sin(a), 0.0),
               (s * 2.2, s * 1.9, s), TUFF_SH, seed=int(rand() * 900),
               segments=6, rings=3, taper=0.50)
    return b.to_object("Hollow_Rock")


# --- twin_chimney_gate -------------------------------------------------------

def build_twin_chimney_gate():
    """Poarta din POI B: doua hornuri inclinate unul spre altul, lipite sus.

    Cota libera sub arc e **12 m** pe verticala si **13.2 m** pe orizontala
    (calculul e in cod). Verticala e cota de contract:
    `ChaseCamera` sta la 10 m, iar `_unclip` o impinge afara din orice perete,
    deci sub ~11.5 m camera ar sari. Se verifica pe clip < 1 s la 8 m lungime
    de arc.

    Hornurile NU sunt verticale: se inclina 9° unul spre altul si se
    intalnesc intr-o punte de tuf. Inclinatia e ce transforma doua conuri
    alaturate intr-o POARTA.
    """
    b = Builder()
    # Deschiderea LIBERA sub arc, la cota lui, trebuie sa lase drumul (6-7 m,
    # brief §2 POI B) plus joc de o parte si de alta. Verificat aritmetic:
    # la inclinare `LEAN` gaturile se apropie cu tan(LEAN)*CLEAR de fiecare
    # parte, deci deschiderea la cota arcului e SPAN - 2*tan(LEAN)*CLEAR, din
    # care se scad razele gaturilor (~1.5 m fiecare la cota aia).
    #   SPAN 20.0, LEAN 9°, CLEAR 12  ->  20 - 2*0.158*12 = 16.2 m intre axe,
    #   minus 2*1.5 = **13.2 m liber**. Drumul de 7 m trece cu 3 m de fiecare
    # parte — destul cat sa nu para o usa, cat sa para o poarta.
    # Prima versiune avea SPAN 9.4 si LEAN 11°: 4.7 m liber, adica sub latimea
    # drumului. Se vedea in randarea de control ca o furca, nu ca o poarta.
    SPAN = 20.0                # deschiderea intre axe la baza
    LEAN = 9.0                 # inclinarea fiecarui gat spre celalalt, grade
    CLEAR = 12.0               # cota libera sub arc (contract de camera)
    H = 19.5
    for sx in (-1.0, 1.0):
        lean = math.radians(LEAN) * sx
        # gatul, construit din felii inclinate (nu revolve: axa e oblica)
        steps = 8
        for i in range(steps):
            t0, t1 = i / steps, (i + 1) / steps
            z0, z1 = H * t0, H * t1
            r0 = 3.10 + (1.30 - 3.10) * (t0 ** 0.62)
            r1 = 3.10 + (1.30 - 3.10) * (t1 ** 0.62)
            x0 = sx * SPAN * 0.5 - math.tan(lean) * z0
            x1 = sx * SPAN * 0.5 - math.tan(lean) * z1
            slot = TUFF_SH if t0 < 0.20 else (TUFF_MID if 0.45 < t0 < 0.63 else TUFF)
            b.taper_sweep([(x0, 0.0, z0), (x1, 0.0, z1)], [r0, r1], slot,
                          segments=9, cap_start=(i == 0), cap_end=(i == steps - 1))
        # palaria de bazalt, pe axa inclinata
        xt = sx * SPAN * 0.5 - math.tan(lean) * H
        b.frustum((xt, 0.0, H + 0.15), 1.34, 2.75, 0.95, CAP, segments=9)
        b.frustum((xt, 0.0, H + 1.10), 2.75, 2.00, 1.05, CAP, segments=9)

    # puntea: masa de tuf care leaga cele doua gaturi peste drum.
    # Marginea de jos la CLEAR, arcuita usor in sus la mijloc.
    x_top = SPAN * 0.5 - math.tan(math.radians(LEAN)) * CLEAR
    for k in range(7):
        u = (k + 0.5) / 7.0
        x = -x_top + 2.0 * x_top * u
        sag = 0.55 * math.sin(math.pi * u)      # bolta arcului
        b.box((x, 0.0, CLEAR + 2.05 + sag), (2.0 * x_top / 7.0 * 1.05, 5.2,
                                             4.1 - sag * 0.5), TUFF)
    # buza de sub arc, umbrita — asta face arcul sa citeasca drept arc
    b.box((0.0, 0.0, CLEAR + 0.20), (2.0 * x_top * 0.98, 5.5, 0.40), TUFF_SH)
    return b.to_object("Twin_Chimney_Gate")


# --- cave_entrance -----------------------------------------------------------

def build_cave_entrance():
    """Gura orasului subteran: arc sapat de 10 m in faleza, cu torte si soare
    incizat (motivul din plansa).

    Deschiderea e 10 m lata x 7.2 m inalta: peste latimea drumului (6-8 m) si
    peste plafonul de care are nevoie camera pe cei ~3 m de gat. Portalul e
    o placa de faleza cu golul taiat, nu un tunel — tunelul il face terenul.
    """
    b = Builder()
    W, H, D = 15.0, 12.0, 2.6         # blocul de faleza
    OW, OH = 10.0, 7.2                # golul

    # blocul, spart in patru piese ca sa lase golul (fara boolean)
    side = (W - OW) * 0.5
    for sx in (-1.0, 1.0):
        b.box((sx * (OW * 0.5 + side * 0.5), 0.0, H * 0.5), (side, D, H), TUFF)
    b.box((0.0, 0.0, OH + (H - OH) * 0.5), (OW, D, H - OH), TUFF)
    # arcul: trepte de sapare care rotunjesc coltul de sus al golului
    for i, (w, dz, t) in enumerate(((OW * 0.94, OH - 0.30, 0.55),
                                    (OW * 0.80, OH + 0.18, 0.50),
                                    (OW * 0.60, OH + 0.60, 0.45))):
        b.box((0.0, 0.10, dz), (w, D * 0.92, t), TUFF_SH if i else TUFF_MID)
    # ancadramentul iesit in fata: buza care prinde lumina de zori
    for sx in (-1.0, 1.0):
        b.box((sx * (OW * 0.5 + 0.45), D * 0.5 + 0.25, OH * 0.5),
              (0.95, 0.65, OH + 1.0), TUFF_MID)
    b.box((0.0, D * 0.5 + 0.25, OH + 0.55), (OW + 1.9, 0.65, 0.95), TUFF_MID)

    # soarele incizat deasupra portalului (motivul din plansa): raze scurte
    cz = OH + 2.35
    b.cylinder((0.0, D * 0.5 + 0.14, cz), 0.85, 0.30, BAND_RED, segments=10, axis="Y")
    for k in range(12):
        a = 2.0 * math.pi * k / 12.0
        b.box((1.42 * math.cos(a), D * 0.5 + 0.12, cz + 1.42 * math.sin(a)),
              (0.72, 0.26, 0.24), BAND_RUST,
              rotation=Matrix.Rotation(a, 3, "Y"))

    # doua torte flancand intrarea (piesa `torch` e separata, dar portalul are
    # nevoie de ele ca sa citeasca "locuit"; aici sunt doar consolele + flacara)
    for sx in (-1.0, 1.0):
        x = sx * (OW * 0.5 + 0.55)
        b.beam((x, D * 0.5 + 0.30, 3.55), (x, D * 0.5 + 1.15, 4.05), 0.13, IRON)
        b.cylinder((x, D * 0.5 + 1.15, 4.28), 0.30, 0.55, IRON, segments=7)
        b.revolve([(0.26, 0.0), (0.20, 0.55), (0.0, 1.05)], FLAME, segments=7,
                  origin=(x, D * 0.5 + 1.15, 4.52))

    # Moloz la baza pragului. `b.rock` CENTREAZA elipsoidul pe punctul dat, deci
    # z-ul lui e jumatatea inaltimii, nu talpa. Cu z=0.0 piesa cobora la -s/2
    # (masurat: -0.482), iar `emit(..., origin="base")` ridica TOT portalul cu
    # atat ca sa aduca cel mai jos punct la zero. Consecinta, masurata cu
    # ProbeRace: cei sase bolovani ajungeau la 0.0-0.96 m, adica FIX in usa, la
    # inaltimea barei de protectie — 27-42 de repuneri pe seed, toate la frac
    # 0.653-0.657, si pragul frontal ajungea la 0.47 m (peste limita de 0.3 m
    # din `suprafete-cu-goluri-si-praguri`). Molozul se aseaza deci cu TALPA la
    # zero, si atunci `origin="base"` nu mai are ce ridica.
    #
    # Si al doilea motiv, care e cel care chiar inchidea drumul: molozul se
    # imprastia pe -6.3..+6.3, iar GOLUL e OW=10 m, adica -5..+5. Deci sase
    # bolovani stateau taman in deschidere, pe unde trec masinile. Masurat cu
    # ProbeLaneGap: 0.00 m liber pe toti cei 16 m de latime — nu "ingust", ZID.
    # Molozul ramane (portalul are nevoie de el ca sa nu arate taiat cu cutitul)
    # dar sta doar pe UMERI, in afara golului, cu o garda de o jumatate de piesa
    # ca sa nu intre nici cu marginea.
    rand = _lcg(4409)
    for k in range(6):
        s = 0.4 + rand() * 0.6
        # jumatatea stanga sau dreapta, in afara golului
        side = -1.0 if k % 2 == 0 else 1.0
        x0 = OW * 0.5 + s * 1.0          # marginea golului + raza piesei
        x = side * (x0 + rand() * (W * 0.5 - x0))
        b.rock((x, D * 0.5 + 0.4 + rand() * 0.7, s * 0.5),
               (s * 2.0, s * 1.7, s), TUFF_SH, seed=int(rand() * 900),
               segments=6, rings=3, taper=0.50)
    return b.to_object("Cave_Entrance")


# --- vent_shaft --------------------------------------------------------------

def build_vent_shaft():
    """Putul de ventilatie: cilindru de 5 m cu bordura la suprafata.

    Dubla functie (brief §3): jos e coloana de lumina care cade in sala 1,
    sus e o GAURA in platou prin care poti sari ca scurtatura. Deci piesa
    trebuie sa fie corecta si privita de sus (bordura, gura), si privita de
    jos din sala (gatul care urca si se pierde).

    `origin="base_axis"` — se aseaza cu gura la cota platoului si coboara;
    coborarea e in negativ fata de origine, deci NU se centreaza pe Z.
    """
    b = Builder()
    R, DEPTH = 2.5, 9.0
    segments = 12
    # gatul: doua inele (exterior gros, interior gol) coborand sub Z=0
    rings_o, rings_i = [], []
    rand = _lcg(5501)
    for i in range(5):
        z = -DEPTH * i / 4.0
        w = 1.0 + (rand() - 0.5) * 0.06
        ro, ri = [], []
        for k in range(segments):
            a = 2.0 * math.pi * k / segments
            ro.append(b.bm.verts.new(((R + 0.85) * w * math.cos(a),
                                      (R + 0.85) * w * math.sin(a), z)))
            ri.append(b.bm.verts.new((R * math.cos(a), R * math.sin(a), z)))
        rings_o.append(ro)
        rings_i.append(ri)
    inner = []
    for lo, hi in zip(rings_i, rings_i[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            inner.append(b.bm.faces.new((lo[j], lo[i], hi[i], hi[j])))
    outer = []
    for lo, hi in zip(rings_o, rings_o[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            outer.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    for i in range(segments):     # inelul de sus (coronamentul gurii)
        j = (i + 1) % segments
        f = b.bm.faces.new((rings_o[0][i], rings_o[0][j], rings_i[0][j], rings_i[0][i]))
        f[b.slot] = TUFF_MID
    for f in inner:
        f[b.slot] = CAVE
    for f in outer:
        f[b.slot] = TUFF_SH

    # bordura de la suprafata: inel de blocuri de tuf, ca sa se vada gura de
    # departe (altfel e o pata neagra pe platou si nimeni nu sare in ea)
    for k in range(segments):
        a = 2.0 * math.pi * (k + 0.5) / segments
        rr = R + 0.72
        b.box((rr * math.cos(a), rr * math.sin(a), 0.42),
              (1.05, 2.0 * math.pi * rr / segments * 1.04, 0.84),
              TUFF if k % 3 else TUFF_MID, rotation=Matrix.Rotation(a, 3, "Z"))
    return b.to_object("Vent_Shaft")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.05):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


emit(build_hollow_rock(), "structures/hollow_rock.glb", AO_HERO,
     origin="base_axis", bevel=0.07)
emit(build_twin_chimney_gate(), "structures/twin_chimney_gate.glb", AO_GATE,
     bevel=0.06)
emit(build_cave_entrance(), "structures/cave_entrance.glb", AO_CAVE)
emit(build_vent_shaft(), "structures/vent_shaft.glb", AO_SHAFT,
     origin="base_axis")

print()
for path, tris, kb in results:
    print("%-40s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL hero: %d tris" % sum(t for _, t, _ in results))
