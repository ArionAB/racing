"""Machu Picchu — HERO: piesele unice, cate una pe pista (plansa, randurile 2, 3, 4, 5).

  machupicchu/rocks/huayna_picchu.glb            varful-flanc de 30 m (POI H, se vede de la C)
  machupicchu/structures/inti_punku.glb          Poarta Soarelui: doua camere, 14 m liber (POI C)
  machupicchu/structures/main_gate.glb           Poarta Principala trapezoidala (POI H)
  machupicchu/structures/inca_bridge_ledge.glb   cornisa cu golul de 4.25 m (POI H)
  machupicchu/structures/sun_temple.glb          Templul Soarelui: zid curb pe stanca
  machupicchu/structures/intihuatana.glb         movila cu trepte + piatra-ceas (POI A)
  machupicchu/structures/three_windows.glb       zidul cu 3 ferestre (silueta pietei, POI A)

SAPTE piese. Podul de franghie si turnurile lui NU sunt aici (se decid separat),
iar traveea de barne a golului nu se genereaza deloc — vezi nota de la
`inca_bridge_beams` mai jos.

REGULA 0.5 (brief §0.5): rosturile de piatra NU sunt geometrie. Fiecare zid de
aici e o cutie cu bevel plus 2-4 umflaturi mari, cu fetele din umbra retag-uite
pe ROCK_DARK. Rosturile vin dintr-o clasa de textura triplanara la integrare.
Fara caramizi modelate — altfel bugetul se duce pe detaliu care oricum dispare
la 60 km/h, si numarul de materiale (singurul test cu drept de veto) creste.

SUPRAFETELE PE CARE SE MERGE au varfuri PARTAJATE (brief §0.7): treapta dintre
camerele Portii Soarelui si treptele Intihuatanei sunt construite ca O SINGURA
banda de quad-uri cusute, nu ca placi suprapuse. Cu fizica intreaga orice prag
de peste 0.3 m e un zid, iar doua placi independente lasa exact asa un prag.

Trei cote sunt CONTRACT DE GAMEPLAY, inghetate in geometrie si verificate
aritmetic in cod (nu ochiometric), fiindca drumul trece PRIN ele:
  - Inti Punku: 14.0 m liber intre camere, pe drum de 13 m (semi-latime 6.5)
  - main_gate:  8.4 m la baza / 6.0 m liber sub buiandrug, pe drum de 8 m
  - ledge:      4.25 m gol, care e fix traveea barnelor de 4.6 m (0.175 m
                rezemare pe fiecare buza)

AXE: -Z Godot = +Y Blender e "inainte". La cele trei piese de mai sus drumul
trece pe **Y Blender**, deci deschiderea libera se masoara pe **X**.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_hero.py
"""

import math
from mathutils import Matrix, Vector

# AO: `dist` e raza de raycast, deci se scaleaza cu piesa — pe Huayna Picchu
# (90 m baza) o distanta de 5 m n-ar gasi nimic de ocluzat si AO-ul ar iesi
# constant 1.0, adica exact "prop-ul plat" din docs/blender_export.md §2.
AO_PEAK = dict(samples=12, dist=26.0, gradient="vertical",
               low=0.40, high=1.00, power=0.85, floor=0.14)
AO_GATE = dict(samples=18, dist=8.0, gradient="vertical",
               low=0.42, high=1.00, power=0.86, floor=0.15)
AO_LEDGE = dict(samples=16, dist=10.0, gradient="vertical",
                low=0.38, high=1.00, power=0.88, floor=0.12)
AO_SMALL = dict(samples=22, dist=3.0, gradient="vertical",
                low=0.46, high=1.00, power=0.90, floor=0.18)

# Sloturile legale pe pista asta (brief §0.4). Zero sloturi noi.
GRANITE = MARBLE_GREY        # granit in soare: ziduri, trepte, buiandrug
GRANITE_SH = ROCK_LIGHT      # granit in umbra
JOINT = ROCK_DARK            # rosturi adanci, nise, interiorul golurilor
MOSS = CACTUS_GREEN          # iarba de terasa, muschi pe pervaz
CLOUD_FOREST = TROPICAL_GREEN  # padure de nori pe flanc
DEEP_SHADE = LOG_DARK        # umbra adanca de padure
EARTH = SAND_SHADOW          # pamant ocru
EARTH_MID = SAND_MID
# (slotul de lemn WOOD_WEATHERED 9 nu mai e folosit aici: singura piesa de lemn
# din lista era traveea de barne, care nu se mai genereaza)


# --- huayna_picchu -----------------------------------------------------------
#
# Cotele: 30 m inalt, baza ~90 m diametru, varf ascutit usor aplecat.
#
# `rock()` cu taper mare, NU `mesa()`. Memoria `mesa-la-40m-da-butoaie`: mesa
# stivuieste lespezi cu buza vizibila, ceea ce la 40+ m citeste ca un butoi
# hexagonal, nu ca un varf. Aici silueta E piesa — se vede de la 250 m de la
# Poarta Soarelui — deci conteaza conturul, si conturul il da un corp unic cu
# taper puternic.
#
# TREI ETAJE DE CULOARE CA RETAG, NU CA VOLUM (brief §1.1 + memoria
# `munte-flanc-nu-fundal`): un singur corp, trei benzi de slot dupa cota.
# `retag` costa ZERO triunghiuri — variatia de valoare fara niciun triunghi in
# plus. Daca etajele ar fi volume separate, ar trebui cusute (fante) si ar
# tripla costul pe o piesa care oricum are buget stramt.
HP_H = 30.0                  # inaltimea peste origine
HP_BASE = 90.0               # diametrul bazei
HP_BURY = 3.0                # cat coboara geometria sub origine (se ingroapa)
# Fractiile de cota la care se schimba etajul de culoare, masurate pe corpul
# VIZIBIL (0 = originea, 1 = varful), nu pe bbox-ul care include ingroparea.
HP_CROWN = 0.66              # de aici in sus: coroana de granit
HP_FLANK = 0.24              # intre FLANK si CROWN: padure de nori
# Aplecarea varfului: varful se decaleaza lateral fata de axa bazei. Fara ea
# conul e simetric si citeste ca o movila; cu ea capata directie (brief: "varf
# ascutit usor aplecat").
HP_LEAN = 4.5


def build_huayna_picchu():
    """Varful-flanc: un corp de stanca cu taper mare, trei etaje de culoare ca
    retag, si 3-4 terase mici la baza cu varfuri PARTAJATE.

    Corpul e construit din inele proprii (nu `rock()` direct) dintr-un singur
    motiv: varful trebuie sa se APLECE, iar `rock()` centreaza fiecare inel pe
    aceeasi axa. Restul retetei e a lui — perturbatie determinista per coloana
    si per inel, ca sa iasa stanca si nu con de plastic.
    """
    b = Builder()
    rand = _lcg(7701)
    # 8 segmente: fatete LATE. Cu 11 iesea un con aproape neted — de la 50 m
    # ochiul nu mai vedea niciun plan, doar o movila. style_bible §3 cere stanci
    # fatetate, si aici fatetele sunt tot ce desparte "colt de granit" de "deal".
    segments, rings = 8, 6

    # Perturbatie MARE per coloana (0.62..1.00): la o piesa de 90 m diferenta
    # dintre doua coloane vecine trebuie sa fie de metri, nu de centimetri,
    # altfel se pierde inainte sa ajunga pe ecran. Se tine sub 1.0 ca HP_BASE
    # sa ramana diametrul MAXIM (masurat: cu perturbatie peste 1 iesea 99 m).
    # Media perturbatiei fixeaza diametrul REAL: cu 0.62..1.00 (medie 0.81)
    # baza iesea 75.6 m in loc de ~90 (masurat pe GLB). Intervalul de mai jos
    # are media ~0.90, deci baza se intoarce la ~90 m, pastrand diferenta mare
    # intre coloane care da fatetele.
    col_dev = [0.78 + rand() * 0.24 for _ in range(segments)]
    # A doua armonica: face ca doua coloane vecine sa nu fie niciodata la fel,
    # deci muchiile verticale citesc ca creste de granit, nu ca un poligon.
    col_dev2 = [0.86 + rand() * 0.14 for _ in range(segments)]

    rings_v = []
    zs = []
    for k in range(rings + 1):
        t = k / rings
        z = -HP_BURY + (HP_H + HP_BURY) * t
        zs.append(z)
        # Profil: puternic conic. Exponentul sub 1 tine baza lata si strange
        # repede spre varf = silueta de colt infipt, nu de movila.
        frac_above = max(0.0, (z) / HP_H)
        radius_scale = (1.0 - 0.90 * (max(t, 0.0) ** 0.72))
        ring_dev = 0.90 + rand() * 0.10
        # APLECAREA: varful se duce lateral pe X SI pe Y, iar inelele de sus nu
        # mai sunt coaxiale cu baza. Fara componenta pe Y piesa era simetrica
        # fata de planul XZ si citea tot ca un con, oricat de aplecata pe X.
        lean_x = HP_LEAN * (max(frac_above, 0.0) ** 1.6)
        lean_y = HP_LEAN * 0.45 * (max(frac_above, 0.0) ** 2.0)
        ring = []
        for i in range(segments):
            a = 2.0 * math.pi * i / segments
            ca, sa = math.cos(a), math.sin(a)
            # deviatia coloanei se schimba cu cota: coloana lata jos se poate
            # ingusta sus, deci fateta e un PLAN inclinat, nu o banda paralela
            d = col_dev[i] * (1.0 - t) + col_dev2[i] * t
            r = radius_scale * ring_dev * d
            ring.append(b.bm.verts.new((
                lean_x + ca * r * HP_BASE * 0.5,
                lean_y + sa * r * HP_BASE * 0.5,
                z)))
        rings_v.append(ring)

    body = []
    for lo, hi in zip(rings_v, rings_v[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            body.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    # talpa (se ingroapa, dar piesa nu are voie sa fie deschisa pe dedesubt)
    base_face = b.bm.faces.new(tuple(reversed(rings_v[0])))
    # varful: un apex peste ultimul inel, ca sa fie ASCUTIT. Un inel plat sus ar
    # da un capac poligonal care straluceste in soare la 250 m. Apexul sta pe
    # varticala aplecarii, nu pe axa bazei.
    apex = b.bm.verts.new((HP_LEAN * 1.15, HP_LEAN * 0.45, HP_H))
    tip = []
    for i in range(segments):
        j = (i + 1) % segments
        tip.append(b.bm.faces.new((rings_v[-1][i], rings_v[-1][j], apex)))

    for f in body + tip:
        f[b.slot] = CLOUD_FOREST
    base_face[b.slot] = EARTH

    # --- cele trei etaje, ca RETAG pe fete (zero triunghiuri) ---
    # Ordinea conteaza: se pune de jos in sus, ultimul retag castiga.
    all_faces = body + tip
    b.retag(all_faces, MOSS, where=lambda c, n: c.z < HP_H * HP_FLANK)
    b.retag(all_faces, CLOUD_FOREST,
            where=lambda c, n: HP_H * HP_FLANK <= c.z < HP_H * HP_CROWN)
    b.retag(all_faces, GRANITE, where=lambda c, n: c.z >= HP_H * HP_CROWN)
    # Umbra adanca de padure pe fetele dinspre -Y (spatele, dinspre defileu):
    # un flanc de o singura valoare citeste plat de la 50 m.
    b.retag(all_faces, DEEP_SHADE,
            where=lambda c, n: (HP_H * HP_FLANK <= c.z < HP_H * HP_CROWN
                                and n.y < -0.35))
    # Fete mari taioase de granit in coroana: doua fatete retag-uite pe umbra,
    # ca treimea de sus sa nu fie o pata uniforma de MARBLE_GREY.
    b.retag(all_faces, GRANITE_SH,
            where=lambda c, n: c.z >= HP_H * HP_CROWN and n.x < -0.30)

    # --- terasele de la baza: 4 trepte de 2 m cu VARFURI PARTAJATE ---
    # Sunt pe fata dinspre +Y (spre cetate), unde se vad din masina la POI H.
    # Fiecare terasa e o banda inchisa de quad-uri cusuta din aceleasi varfuri:
    # calca + contratreapta impart muchia, deci nu exista prag de placa.
    _huayna_terraces(b)
    return b.to_object("Huayna_Picchu")


def _huayna_terraces(b, count=4, rise=2.0):
    """4 terase mici pe flancul dinspre cetate, ca trepte cusute.

    Varfuri PARTAJATE: contratreapta si calca folosesc ACELEASI varfuri pe
    muchia comuna (se construiesc ca un profil continuu), deci nu apare prag de
    placa. Terasele sunt decor la baza unui varf de 30 m, dar stau langa drum
    la POI H, deci regula §0.7 li se aplica.
    """
    segments = 9
    # arcul pe care se intind terasele, pe fata dinspre +Y (spre cetate)
    a0, a1 = math.radians(28.0), math.radians(152.0)

    # Terasele stau pe UN SINGUR flanc (spre cetate), ca niste lespezi
    # suprapuse care ies DIN stanca — nu ca inele in jurul intregului con.
    #
    # Prima versiune le facea pe un arc si le lipea de raza conului la fiecare
    # cota: rezultatul, vazut in plansa de control, era un teanc de polite
    # concentrice sapate in aceeasi fata (silueta de melc). Cifrele treceau,
    # forma era gresita. Acum fiecare terasa e o platforma care IESE in consola
    # din flanc, cu latimea ei proprie, si se retrage cu cota — adica exact
    # profilul de terasa incasa.
    #
    # Perturbatia per coloana rupe uniformitatea rotationala: terasele nu mai
    # sunt arce perfecte, ci lespezi cu muchia franta.
    rnd = _lcg(8123)
    jitter = [0.88 + rnd() * 0.24 for _ in range(segments)]

    def cone_r(z):
        """Raza corpului stancii la cota z."""
        r = HP_BASE * 0.5 * (1.0 - 0.90 * ((z + HP_BURY) / (HP_H + HP_BURY)) ** 0.72)
        return r

    def ring_at(z, radius_fn):
        out = []
        for i in range(segments):
            a = a0 + (a1 - a0) * i / (segments - 1)
            r = radius_fn(i)
            out.append(b.bm.verts.new((math.cos(a) * r, math.sin(a) * r, z)))
        return out

    # VARFURI PARTAJATE (§0.7): muchia din spatele calcai ESTE muchia din fata
    # contratreptei urmatoare — acelasi obiect de vertex, transportat prin
    # `prev`. Fara asta ar ramane praguri de placa de 2 m, adica ziduri pentru
    # fizica intreaga (memoria `suprafete-cu-goluri-si-praguri`).
    z_base = 0.4
    # Terasele se SAPA in flanc, nu ies din el. Buza fiecareia sta PUTIN sub
    # raza corpului la cota ei (0.96), iar calca intra spre axa — deci lespedea
    # e taiata in panta, cum e o terasa incasa.
    #
    # Varianta precedenta pornea de la `cone_r(z_base) * 1.06` si scadea un pas
    # fix: terasele ieseau in consola in fata stancii si, la a treia-a patra,
    # pluteau in aer langa flanc (se vedea in plansa ca o scara in semiluna
    # lipita pe dreapta). Acum fiecare buza e ancorata pe corpul stancii la cota
    # ei, deci urmeaza panta si ramane INFIPTA in ea.
    out_r = [cone_r(z_base + k * rise) * 0.96 for k in range(count + 1)]
    prev = ring_at(z_base, lambda i: out_r[0] * jitter[i])
    risers, treads = [], []
    for k in range(count):
        z_hi = z_base + (k + 1) * rise
        # contratreapta VERTICALA: aceeasi raza ca muchia de sub ea
        lip = ring_at(z_hi, lambda i, kk=k: out_r[kk] * jitter[i])
        for i in range(segments - 1):
            risers.append(b.bm.faces.new(
                (prev[i], prev[i + 1], lip[i + 1], lip[i])))
        # calca: se retrage spre stanca pana la raza corpului la cota noua,
        # adica terasa se INFIGE in flanc in loc sa iasa din el
        deep = ring_at(z_hi, lambda i, kk=k: out_r[kk + 1] * jitter[i] * 0.93)
        for i in range(segments - 1):
            treads.append(b.bm.faces.new(
                (lip[i], lip[i + 1], deep[i + 1], deep[i])))
        prev = deep
    for f in risers:
        f[b.slot] = GRANITE_SH
    for f in treads:
        f[b.slot] = MOSS         # iarba de terasa pe calca
    return


# --- inti_punku --------------------------------------------------------------
#
# Poarta Soarelui. Drumul la POI C are semi-latime 6.5 (13 m lat), deci poarta
# NU are buiandrug: doua camere de piatra fara acoperis care flancheaza drumul.
# Un buiandrug peste 13 m ar fi fost o grinda de piatra de 13 m — imposibil ca
# obiect real si, mai important, ar fi taiat cadrul exact la dezvaluirea
# cetatii (POI C e "dezvaluirea castigata prin urcare").
IP_CLEAR = 14.0              # liber intre camere, pe axa X (drumul trece pe Y)
IP_ROOM = (5.0, 4.0, 5.0)    # camera: X (latime) x Y (adancime) x Z (inaltime)
IP_WALL = 0.8                # grosimea zidului camerei
IP_STEP_H = 0.10             # pragul treptei dintre camere (max 0.1 m)
IP_STEP_LEN = 4.0            # cat de lunga e treapta pe axa drumului (Y)


def _stone_room(b, cx, mirror=1.0):
    """O camera de piatra fara acoperis: patru ziduri cu bevel, doua nise
    trapezoidale pe fata dinspre drum, umflaturi mari de piatra.

    Regula 0.5: zidurile sunt CUTII, nu caramizi. Nisele sunt adancituri
    retag-uite pe ROCK_DARK in fund — golul citeste din valoare, nu din
    geometrie sapata.
    """
    w, d, h = IP_ROOM
    t = IP_WALL
    faces = []
    # zidul dinspre drum (spre centru) — cel care se vede din masina.
    # Centrat pe `cx - mirror*(w/2 - t/2)` => fata interioara exact la
    # `cx - mirror*w/2`, adica pe buza golului. Vezi nota din build_inti_punku.
    inner = b.box((cx - mirror * (w * 0.5 - t * 0.5), 0.0, h * 0.5),
                  (t, d, h), GRANITE)
    # zidul exterior
    outer = b.box((cx + mirror * (w * 0.5 - t * 0.5), 0.0, h * 0.5),
                  (t, d, h), GRANITE)
    # cele doua capete (pe axa drumului)
    for sy in (-1.0, 1.0):
        faces += list(b.box((cx, sy * (d * 0.5 - t * 0.5), h * 0.5),
                            (w, t, h), GRANITE))
    faces += list(inner) + list(outer)

    # Fetele dinspre interiorul camerei si cele dinspre nord stau in umbra.
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)

    # Doua nise trapezoidale pe zidul dinspre drum: adancituri RETRASE in zid,
    # retag JOINT (fundul e cel mai inchis slot => citeste ca gol).
    #
    # Nisa se INFUNDA in zid, nu iese din el. Prima versiune o centra pe
    # `nx + mirror*0.14` cu nx = cx - mirror*(w/2 - t), deci fata ei dinspre drum
    # ajungea la 7.64 in loc de 7.0 si MANCA din golul de contract: masurat pe
    # GLB, deschiderea iesea 15.28 m in loc de 14.0. Acum fata dinspre drum a
    # nisei e coplanara cu fata zidului (x = cx - mirror*w/2) si adancitura
    # merge spre INTERIORUL zidului.
    n_depth = t * 0.75
    for k, sy in enumerate((-1.0, 1.0)):
        nz = 2.3
        ny = sy * d * 0.22
        # fata dinspre drum a zidului
        x_face = cx - mirror * w * 0.5
        # centrul nisei, impins in grosimea zidului
        nis = b.box((x_face + mirror * n_depth * 0.5, ny, nz),
                    (n_depth, 0.9, 1.5), JOINT)
        b.retag(nis, JOINT)

    # 2-3 umflaturi mari de piatra pe zidul exterior (regula 0.5: volumul mare,
    # nu caramida). Ele sunt ce face zidul sa citeasca "incas" de la distanta.
    rand = _lcg(int(8800 + cx * 13))
    for k in range(3):
        by = -d * 0.3 + d * 0.3 * k
        bz = 0.9 + rand() * 2.8
        s = 0.55 + rand() * 0.45
        bulge = b.rock((cx + mirror * (w * 0.5 + 0.10), by, bz),
                       (s * 1.1, s * 1.7, s * 1.3), GRANITE_SH,
                       seed=int(rand() * 700), segments=6, rings=2, taper=0.30)
    return faces


def build_inti_punku():
    """Doua camere de 5x4x5 m la 14.0 m una de alta, cu o treapta lata de granit
    intre ele. Drumul trece pe Y Blender, deci deschiderea e pe X.

    Treapta are VARFURI PARTAJATE si prag de 0.10 m: peste 0.3 m ar fi zid
    pentru fizica intreaga (memoria `suprafete-cu-goluri-si-praguri`). Se
    construieste ca o singura banda de quad-uri cusuta, cu muchiile tesite pe
    ambele capete, nu ca o placa asezata peste teren.
    """
    b = Builder()
    half = IP_CLEAR * 0.5
    # Camerele: fata lor dinspre drum sta exact la +-half.
    #
    # Zidul dinspre drum e o cutie de grosime IP_WALL centrata pe
    # `cx - (w/2 - t/2)`, deci fata lui interioara cade la `cx - w/2`. Ca fata
    # aia sa fie exact la `half`, centrul camerei trebuie impins cu w/2 — NU cu
    # w/2 + t/2, cum era intai: acel jumatate de zid in plus deschidea golul la
    # 15.28 m in loc de 14.0 (masurat pe GLB, nu pe bbox).
    cx = half + IP_ROOM[0] * 0.5
    _stone_room(b, -cx, mirror=-1.0)
    _stone_room(b, +cx, mirror=+1.0)

    # --- treapta lata intre camere: varfuri PARTAJATE, prag 0.10 m ---
    # Profil pe axa drumului (Y): teren -> muchie tesita -> platou -> muchie
    # tesita -> teren. Tesirea e ce tine pragul frontal sub 0.3 m indiferent din
    # ce parte vine masina.
    bevel_run = 0.5
    ys = [-IP_STEP_LEN * 0.5 - bevel_run, -IP_STEP_LEN * 0.5,
          IP_STEP_LEN * 0.5, IP_STEP_LEN * 0.5 + bevel_run]
    hs = [0.0, IP_STEP_H, IP_STEP_H, 0.0]
    xs = [-half, -half * 0.5, 0.0, half * 0.5, half]
    grid = []
    for y, h in zip(ys, hs):
        row = [b.bm.verts.new((x, y, h)) for x in xs]
        grid.append(row)
    step_faces = []
    for r in range(len(grid) - 1):
        for c in range(len(xs) - 1):
            step_faces.append(b.bm.faces.new(
                (grid[r][c], grid[r][c + 1], grid[r + 1][c + 1], grid[r + 1][c])))
    for f in step_faces:
        f[b.slot] = GRANITE
    # muchia tesita dinspre nord prinde mai putina lumina
    b.retag(step_faces, GRANITE_SH, where=lambda c, n: c.y < -IP_STEP_LEN * 0.5)
    return b.to_object("Inti_Punku")


# --- main_gate ---------------------------------------------------------------
#
# Poarta Principala (POI H). Trapezoidala, ca toate deschiderile incase.
#
# ABATERE DE LA BRIEF-UL PISTEI, DELIBERATA: brief-ul pistei §2 POI H scrie
# "4 m latime, 5 m inalta". Brief-ul de assets §1.1 cere 8.4 m la baza / 6.0 m
# liber, si el are dreptate din aritmetica: drumul de acolo are semi-latime 4
# (deci 8 m lat), iar o poarta de 4 m pe un drum de 8 m nu e gatuire, e zid cu
# o fanta. Se construieste dupa §1.1. Diferenta e notata in raport.
MG_BASE = 8.4                # deschiderea la baza
MG_TOP = 7.4                 # ... si sub buiandrug (trapez)
MG_CLEAR = 6.0               # liber pe verticala sub buiandrug
MG_JAMB = 1.2                # grosimea tocului
MG_H = 7.5                   # inaltimea totala
MG_WING = 3.0                # restul de zid de fiecare parte


def build_main_gate():
    """Buiandrug monolit pe doi usciori trapezoidali, plus un rest de zid de
    3 m de fiecare parte. Drumul pe Y Blender.

    Usciorii sunt trapezoidali (se apleaca spre interior cu cota) — semnatura
    incasa. Se construiesc ca prisme din contur, nu ca cutii rotite: o cutie
    rotita ar lasa baza inclinata fata de teren.
    """
    b = Builder()
    depth = 2.2              # grosimea portii pe axa drumului (Y)

    # --- usciorii trapezoidali ---
    # Conturul in XZ: fata dinspre gol se apleaca de la MG_BASE/2 la MG_TOP/2.
    for sx in (-1.0, 1.0):
        x_in_lo = sx * MG_BASE * 0.5
        x_in_hi = sx * MG_TOP * 0.5
        x_out_lo = sx * (MG_BASE * 0.5 + MG_JAMB)
        x_out_hi = sx * (MG_TOP * 0.5 + MG_JAMB)
        outline = [(x_in_lo, 0.0), (x_out_lo, 0.0),
                   (x_out_hi, MG_CLEAR), (x_in_hi, MG_CLEAR)]
        if sx < 0:
            outline = list(reversed(outline))
        jamb = b.prism(outline, depth, GRANITE, center=(0.0, 0.0, 0.0))
        # fata dinspre gol, in umbra tot timpul
        b.retag(jamb, GRANITE_SH,
                where=lambda c, n, s=sx: n.x * s < -0.5)

    # --- buiandrugul monolit ---
    # Sta PESTE golul liber: de la MG_CLEAR in sus, lat cat toata deschiderea
    # plus cei doi usciori.
    lintel_w = MG_TOP + 2.0 * MG_JAMB
    lintel_h = MG_H - MG_CLEAR
    lint = b.box((0.0, 0.0, MG_CLEAR + lintel_h * 0.5),
                 (lintel_w, depth * 1.06, lintel_h), GRANITE)
    # fata de dedesubt (se vede din masina, la trecere) — umbra adanca
    b.retag(lint, JOINT, where="down")

    # --- restul de zid de 3 m de fiecare parte ---
    for sx in (-1.0, 1.0):
        wx = sx * (MG_BASE * 0.5 + MG_JAMB + MG_WING * 0.5)
        wall = b.box((wx, 0.0, (MG_H - 1.6) * 0.5),
                     (MG_WING, depth * 0.85, MG_H - 1.6), GRANITE)
        b.retag(wall, GRANITE_SH, where=lambda c, n: n.y < -0.5)
        # doua umflaturi mari de piatra (regula 0.5), nu caramizi
        rand = _lcg(int(9100 + sx * 31))
        for k in range(2):
            s = 0.6 + rand() * 0.5
            b.rock((wx + (rand() - 0.5) * MG_WING * 0.5,
                    sx * depth * 0.42, 1.0 + rand() * 3.4),
                   (s * 1.4, s * 0.9, s * 1.2), GRANITE_SH,
                   seed=int(rand() * 800), segments=6, rings=2, taper=0.32)
    return b.to_object("Main_Gate")


# --- inca_bridge_ledge -------------------------------------------------------
#
# Cornisa Podului Incas (POI H). Peretele sta pe DREAPTA drumului; cornisa e
# VIZUALA (drumul real e terenul). Golul e LIBER in GLB — barnele sunt piesa
# separata, fiindca `LiftBridgeHazard` le scoate pe ciclu.
LG_LEN = 30.0                # lungimea peretelui pe axa drumului (Y)
LG_H = 12.0                  # inaltimea peretelui
LG_LEDGE = 1.5               # latimea cornisei taiate la baza
LG_GAP = 4.25                # golul la mijloc (contract cu barnele de 4.6 m)
LG_THICK = 3.0               # adancimea masei de stanca in spatele cornisei


def build_inca_bridge_ledge():
    """Perete de stanca de 30x12 m cu o cornisa de 1.5 m taiata la baza si un
    gol de 4.25 m la mijloc.

    Originea e pe axa golului, la baza cornisei (`origin="base_axis"` pastreaza
    XY asa cum e construit, deci golul ramane centrat pe Y=0).

    Golul e liber: nu se pune nimic in el. Bârnele de 4.6 m ale piesei separate
    reazema 0.175 m pe fiecare buza.
    """
    b = Builder()
    half_gap = LG_GAP * 0.5

    # --- peretele, in doua tronsoane (nordic si sudic), ca sa lase golul ---
    # Peretele e o masa de stanca cu fata verticala spre drum (spre -X).
    # `rock(wall_axis="y")` nu ajuta aici: fata verticala trebuie sa fie pe X,
    # si e mai ieftin si mai controlabil un set de inele proprii.
    for sy in (-1.0, 1.0):
        y0 = sy * half_gap
        y1 = sy * LG_LEN * 0.5
        _ledge_section(b, y0, y1, seed=int(9300 + sy * 17))

    # --- cornisa: banda orizontala de 1.5 m la baza, cu varfuri PARTAJATE ---
    # E vizuala (se conduce pe teren), dar sta exact sub roti, deci se
    # construieste ca banda cusuta, nu ca placi.
    for sy in (-1.0, 1.0):
        y0 = sy * half_gap
        y1 = sy * LG_LEN * 0.5
        n = 7
        rows = []
        for i in range(n):
            t = i / (n - 1)
            y = y0 + (y1 - y0) * t
            rows.append(y)
        top, front = [], []
        outer = [b.bm.verts.new((-LG_LEDGE, y, 0.0)) for y in rows]
        inner = [b.bm.verts.new((0.0, y, 0.0)) for y in rows]
        drop = [b.bm.verts.new((-LG_LEDGE, y, -0.9)) for y in rows]
        for i in range(n - 1):
            if sy > 0:
                top.append(b.bm.faces.new(
                    (outer[i], inner[i], inner[i + 1], outer[i + 1])))
                front.append(b.bm.faces.new(
                    (drop[i], drop[i + 1], outer[i + 1], outer[i])))
            else:
                top.append(b.bm.faces.new(
                    (outer[i + 1], inner[i + 1], inner[i], outer[i])))
                front.append(b.bm.faces.new(
                    (drop[i + 1], drop[i], outer[i], outer[i + 1])))
        for f in top:
            f[b.slot] = GRANITE_SH
        for f in front:
            f[b.slot] = JOINT
        # muschi pe pervaz: fetele de sus ale cornisei, retag CACTUS_GREEN pe
        # portiunile dinspre capete (unde nu calca nimeni)
        b.retag(top, MOSS,
                where=lambda c, n, s=sy: abs(c.y) > LG_LEN * 0.30)

    # --- buzele golului: fetele verticale care marginesc traveea ---
    # Fara ele golul ar fi o taietura fara grosime si s-ar vedea spatele
    # peretelui (backface, deci culled) — gaura ar citi ca o crapatura.
    for sy in (-1.0, 1.0):
        y = sy * half_gap
        jamb = b.box((-LG_LEDGE * 0.5 + LG_THICK * 0.25, y - sy * 0.12,
                      LG_H * 0.22),
                     (LG_LEDGE + LG_THICK * 0.5, 0.24, LG_H * 0.44), JOINT)
        b.retag(jamb, JOINT)
    return b.to_object("Inca_Bridge_Ledge")


def _ledge_section(b, y0, y1, seed):
    """Un tronson de perete: inele verticale cu fata dinspre drum (-X) plana si
    spatele perturbat. Fata plana e ce face peretele sa citeasca "taiat", nu
    "movila lipita langa drum"."""
    rand = _lcg(seed)
    n_y, n_z = 6, 5
    grid = []
    for iz in range(n_z + 1):
        tz = iz / n_z
        z = tz * LG_H
        row = []
        for iy in range(n_y + 1):
            ty = iy / n_y
            y = y0 + (y1 - y0) * ty
            # fata dinspre drum: aproape verticala, cu o usoara retragere spre
            # varf (peretii tăiati in stanca se apleaca in spate)
            x_face = -LG_LEDGE + tz * 0.9 + (rand() - 0.5) * 0.35
            row.append(b.bm.verts.new((x_face, y, z)))
        grid.append(row)
    faces = []
    for iz in range(n_z):
        for iy in range(n_y):
            faces.append(b.bm.faces.new(
                (grid[iz][iy], grid[iz][iy + 1],
                 grid[iz + 1][iy + 1], grid[iz + 1][iy])))
    for f in faces:
        f[b.slot] = GRANITE_SH
    # benzi orizontale de valoare (roca stratificata), zero triunghiuri
    b.retag(faces, JOINT, where=lambda c, n: 0.18 * LG_H < c.z < 0.31 * LG_H)
    b.retag(faces, GRANITE, where=lambda c, n: 0.55 * LG_H < c.z < 0.70 * LG_H)
    # muschi pe pervazurile de sus
    b.retag(faces, MOSS, where=lambda c, n: c.z > LG_H * 0.88 and n.z > 0.25)

    # masa din spate: inchide peretele, ca sa nu fie o foaie fara grosime
    y_mid = (y0 + y1) * 0.5
    b.box((LG_THICK * 0.5, y_mid, LG_H * 0.5),
          (LG_THICK, abs(y1 - y0), LG_H), GRANITE_SH)
    # cateva umflaturi pe fata (regula 0.5: volume mari, nu caramizi)
    for k in range(3):
        s = 0.7 + rand() * 0.8
        b.rock((-LG_LEDGE + 0.15, y0 + (y1 - y0) * (0.2 + 0.3 * k),
                1.5 + rand() * 7.5),
               (s * 1.2, s * 2.0, s * 1.5), GRANITE_SH,
               seed=int(rand() * 900), segments=6, rings=2, taper=0.35)


# --- inca_bridge_beams: NU SE GENEREAZA --------------------------------------
#
# Traveea mobila de 3 barne a fost scoasa din kit (corectie de sarcina).
# `LiftBridgeHazard` isi construieste span-ul vertex cu vertex in SurfaceTool
# din cotele buzelor (`scenes/hazards/lift_bridge_hazard.gd:406-460`), iar
# colizorul e un ConvexPolygonShape3D din aceleasi colturi (`:474-488`). Clasa
# NU are export `model` / `model_node`, deci nu exista niciun hook prin care un
# GLB sa intre in ea; nodul e deja configurat procedural in Track15.tscn:90-106
# (`BarnePodIncas`, gap=4.25, descend=true). Un GLB aici ar fi fost 120 de
# triunghiuri moarte — acelasi tipar ca podul de franghie si turnurile lui.
#
# Golul de 4.25 m din `inca_bridge_ledge` RAMANE liber si neschimbat: el e
# contractul geometric pe care hazardul isi construieste traveea.


# --- sun_temple --------------------------------------------------------------

ST_R = 4.0                   # raza semicercului
ST_WALL_H = 3.5
ST_WALL_T = 0.8
ST_ROCK = (6.0, 6.0, 2.0)    # stanca de dedesubt


def build_sun_temple():
    """Zid curb (semicerc r 4 m, 3.5 m inalt) pe o stanca de 6x6x2 m, cu o
    fereastra. MARBLE_GREY pe zid, ROCK_LIGHT pe stanca.

    Zidul e o banda de quad-uri pe semicerc (nu `revolve`, care ar inchide
    cercul si ar pune si o baza). Fereastra e un gol REAL lasat prin sarirea
    unui segment si cusut cu usciori — la 4 m de drum o "fereastra pictata" se
    vede ca pata.
    """
    b = Builder()
    rock_h = ST_ROCK[2]
    # Stanca de dedesubt: `rock()` cu putine segmente si strate, ca sa aiba
    # caracter de ROCA. Prima versiune folosea acelasi apel dar cu 8 segmente si
    # taper mic, si in plansa de control iesea un soclu neted, tesit — templul
    # citea a cada pe piedestal. Cu 6 segmente si strate apar fatete si benzi.
    st = b.rock((0.0, 0.0, 0.0), (ST_ROCK[0], ST_ROCK[1], rock_h * 1.22),
                GRANITE_SH, seed=9500, segments=6, rings=3, taper=0.34,
                flat_top=True,
                strata_slots=(GRANITE_SH, ROCK_DARK, GRANITE_SH))
    top_z = Builder.flat_top_z(0.0, rock_h * 1.22)
    b.retag(st, MOSS, where=lambda c, n: n.z > 0.6 and c.z > top_z * 0.8)
    # bolovani la picior: leaga stanca de teren si ii rup conturul de elipsa
    rr = _lcg(9511)
    for k in range(5):
        a = 2.0 * math.pi * k / 5 + rr() * 0.7
        s = 0.55 + rr() * 0.55
        b.boulder((math.cos(a) * ST_ROCK[0] * 0.52, math.sin(a) * ST_ROCK[1] * 0.52,
                   s * 0.35),
                  (s * 1.6, s * 1.4, s * 1.0), GRANITE_SH,
                  seed=9520 + k, segments=6, rings=3, deviation=0.14)

    # zidul curb: inele interior/exterior pe un semicerc
    segments = 12
    win_seg = 7                      # segmentul in care e fereastra
    win_lo, win_hi = 1.1, 2.4        # cotele golului
    zs = [0.0, win_lo, win_hi, ST_WALL_H]
    # Coronamentul NU e o linie dreapta: un zid incas erodat are creasta
    # neregulata, si exact linia perfecta facea zidul sa citeasca a jgheab de
    # beton in plansa de control. Fiecare coloana isi coboara putin capatul de
    # sus, determinist.
    crest = _lcg(9601)
    crest_drop = [crest() * 0.42 for _ in range(segments + 1)]
    ring_o, ring_i = [], []
    for i in range(segments + 1):
        a = math.pi * i / segments        # 0..180°
        ca, sa = math.cos(a), math.sin(a)
        col_o, col_i = [], []
        for zi, z in enumerate(zs):
            # doar cota de sus (ultima) primeste neregularitatea
            dz = -crest_drop[i] if zi == len(zs) - 1 else 0.0
            col_o.append(b.bm.verts.new(
                ((ST_R + ST_WALL_T * 0.5) * ca, (ST_R + ST_WALL_T * 0.5) * sa,
                 top_z + z + dz)))
            col_i.append(b.bm.verts.new(
                ((ST_R - ST_WALL_T * 0.5) * ca, (ST_R - ST_WALL_T * 0.5) * sa,
                 top_z + z + dz)))
        ring_o.append(col_o)
        ring_i.append(col_i)

    outer, inner, caps = [], [], []
    for i in range(segments):
        for k in range(len(zs) - 1):
            skip = (i == win_seg and k == 1)      # golul ferestrei
            if skip:
                continue
            outer.append(b.bm.faces.new(
                (ring_o[i][k], ring_o[i + 1][k],
                 ring_o[i + 1][k + 1], ring_o[i][k + 1])))
            inner.append(b.bm.faces.new(
                (ring_i[i + 1][k], ring_i[i][k],
                 ring_i[i][k + 1], ring_i[i + 1][k + 1])))
    # coronamentul
    for i in range(segments):
        caps.append(b.bm.faces.new(
            (ring_o[i][-1], ring_o[i + 1][-1], ring_i[i + 1][-1], ring_i[i][-1])))
    # talpa
    for i in range(segments):
        caps.append(b.bm.faces.new(
            (ring_i[i][0], ring_i[i + 1][0], ring_o[i + 1][0], ring_o[i][0])))
    # capetele zidului (cele doua fete plane de la 0° si 180°)
    for idx in (0, segments):
        for k in range(len(zs) - 1):
            f = b.bm.faces.new((ring_o[idx][k], ring_i[idx][k],
                                ring_i[idx][k + 1], ring_o[idx][k + 1]))
            caps.append(f)
    # usciorii ferestrei: cusatura golului, ca sa aiba grosime
    i = win_seg
    k = 1
    for (ia, ib) in ((i, i), (i + 1, i + 1)):
        caps.append(b.bm.faces.new(
            (ring_o[ia][k], ring_i[ib][k], ring_i[ib][k + 1], ring_o[ia][k + 1])))
    caps.append(b.bm.faces.new(
        (ring_o[i][k], ring_o[i + 1][k], ring_i[i + 1][k], ring_i[i][k])))
    caps.append(b.bm.faces.new(
        (ring_o[i][k + 1], ring_i[i][k + 1], ring_i[i + 1][k + 1],
         ring_o[i + 1][k + 1])))

    for f in outer + caps:
        f[b.slot] = GRANITE
    for f in inner:
        f[b.slot] = GRANITE_SH
    b.retag(outer, GRANITE_SH, where=lambda c, n: n.y < -0.45)
    return b.to_object("Sun_Temple")


# --- intihuatana -------------------------------------------------------------

IH_D = 6.0                   # diametrul movilei
IH_H = 1.5                   # inaltimea totala (3 trepte)
IH_STONE = 1.2               # piatra-ceas


def build_intihuatana():
    """Movila cu 3 trepte (6 m diametru, 1.5 m) + piatra-ceas de 1.2 m.

    VARFURI PARTAJATE pe trepte: e langa grila de start, masinile o pot atinge.
    Se construieste ca un profil continuu revolvit manual (calca + contratreapta
    din aceleasi inele), nu ca trei discuri suprapuse — trei discuri ar lasa
    praguri de placa de 0.5 m, adica ziduri pentru fizica intreaga.
    """
    b = Builder()
    steps = 3
    segments = 12
    rise = IH_H / steps
    # profil (raza, z) de jos in sus, alternand calca si contratreapta.
    # Inelele sunt CUSUTE intre ele, deci muchiile sunt partajate.
    prof = [(IH_D * 0.5, 0.0)]
    for k in range(steps):
        r_lo = IH_D * 0.5 * (1.0 - k / float(steps) * 0.62)
        r_hi = IH_D * 0.5 * (1.0 - (k + 1) / float(steps) * 0.62)
        z_lo = k * rise
        z_hi = (k + 1) * rise
        prof.append((r_lo, z_hi))      # contratreapta (verticala)
        prof.append((r_hi, z_hi))      # calca (orizontala)
    # Uniformitatea ROTATIONALA e ce facea movila sa citeasca a tort de discuri
    # in plansa de control. Plansa de inventar (randul 4) arata trepte
    # NEREGULATE de piatra. O perturbatie per coloana, aceeasi pe toata
    # inaltimea, rupe cercurile fara sa strice cusatura: varfurile raman
    # PARTAJATE (acelasi lant de inele), doar razele difera.
    jit = _lcg(9805)
    col = [0.84 + jit() * 0.32 for _ in range(segments)]
    rings = []
    for r, z in prof:
        ring = []
        for i in range(segments):
            a = 2.0 * math.pi * i / segments
            rr = r * col[i]
            ring.append(b.bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        rings.append(ring)
    faces = []
    for lo, hi in zip(rings, rings[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            faces.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    # capacul de sus
    faces.append(b.bm.faces.new(tuple(rings[-1])))
    # talpa
    faces.append(b.bm.faces.new(tuple(reversed(rings[0]))))
    for f in faces:
        f[b.slot] = GRANITE
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.6 and c.z < rise * 0.6)

    # Piatra-ceas: soclu + deget (gnomonul) inclinat, semnatura piesei.
    # Cota totala e CONTRACT: movila 1.5 + piatra 1.2 = 2.7 m. Soclul si degetul
    # se impart cei 1.2 m ca varful degetului sa cada exact la 2.7 — prima
    # versiune le suprapunea si iesea 2.81 m.
    top = IH_H
    base_h = IH_STONE * 0.55                  # soclul
    tip_h = IH_STONE - base_h                 # degetul, pana la 2.7 exact
    stone = b.box((0.0, 0.0, top + base_h * 0.5),
                  (0.95, 0.95, base_h), GRANITE)
    b.retag(stone, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    # degetul, usor inclinat; inclinarea il ridica putin, deci se scade cosinusul
    tilt = math.radians(9.0)
    b.box((0.10, 0.0, top + base_h + tip_h * 0.5 * math.cos(tilt)),
          (0.42, 0.42, tip_h), GRANITE,
          rotation=Matrix.Rotation(tilt, 3, "Y"))
    return b.to_object("Intihuatana")


# --- three_windows -----------------------------------------------------------

TW_W = 10.0
TW_T = 0.9
TW_H = 4.0
TW_WIN = (1.0, 0.8, 1.4)     # jos / sus / inalt (trapez)
TW_SILL = 1.5                # cota pervazului


def build_three_windows():
    """Zid de 10 x 0.9 x 4 m cu 3 ferestre trapezoidale. Silueta pietei.

    Ferestrele sunt goluri REALE (zidul se sparge in coloane si buiandrugi),
    fiindca zidul e silueta pietei vazuta din spate — prin ele se vede cerul, si
    exact asta il face sa citeasca a Templu al celor Trei Ferestre si nu a gard.

    Trapezoidale: 1.0 m jos, 0.8 m sus. Se construiesc din prisme cu contur, ca
    usciorii sa fie inclinati; o cutie dreapta ar da ferestre dreptunghiulare.
    """
    b = Builder()
    n = 3
    # pozitiile pe X ale axelor ferestrelor
    pitch = TW_W / (n + 1.0)
    axes = [-TW_W * 0.5 + pitch * (k + 1) for k in range(n)]
    w_lo, w_hi, w_h = TW_WIN
    z0, z1 = TW_SILL, TW_SILL + w_h

    # Coloanele dintre / langa ferestre, pe intervalul de cota al golului.
    #
    # Fereastra incasa se INGUSTEAZA in sus (1.0 jos -> 0.8 sus), deci muchia
    # coloanei dinspre fereastra se apropie de axa ferestrei cu cota. Numai
    # muchiile dinspre GOL se inclina; capetele zidului (+-TW_W/2) si muchiile
    # dinspre coloana vecina raman VERTICALE.
    #
    # Prima versiune inclina si capatul exterior al coloanelor de margine
    # (`x_lo_t = -TW_W*0.5` pastrat, dar `x_hi_t` dus spre gol cu w_hi/2 in loc
    # de w_lo/2), deci coloanele se apropiau una de alta si golul se inchidea
    # intr-un V: in plansa de control ferestrele citeau ca pene pline, nu ca
    # deschideri. Se vedea in captura, nu in cifre — verify trecea OK.
    def col_edges(k):
        """(x_jos_stanga, x_jos_dreapta, x_sus_stanga, x_sus_dreapta)."""
        if k == 0:
            left_lo = left_hi = -TW_W * 0.5           # capat de zid: vertical
        else:
            left_lo = axes[k - 1] + w_lo * 0.5        # buza ferestrei din stanga
            left_hi = axes[k - 1] + w_hi * 0.5        # ... se strange spre axa
        if k == n:
            right_lo = right_hi = TW_W * 0.5          # capat de zid: vertical
        else:
            right_lo = axes[k] - w_lo * 0.5           # buza ferestrei din dreapta
            right_hi = axes[k] - w_hi * 0.5
        return left_lo, right_lo, left_hi, right_hi

    faces = []
    for k in range(n + 1):
        x_lo, x_hi, x_lo_t, x_hi_t = col_edges(k)
        # coloana e un trapez in XZ intre cotele ferestrei; sub pervaz si peste
        # buiandrug zidul e continuu (benzile de mai jos).
        outline = [(x_lo, z0), (x_hi, z0), (x_hi_t, z1), (x_lo_t, z1)]
        faces += list(b.prism(outline, TW_T, GRANITE))

    # banda de sub pervaz (continua pe toata latimea) si cea de peste buiandrug
    band_lo = b.box((0.0, 0.0, z0 * 0.5), (TW_W, TW_T, z0), GRANITE)
    band_hi = b.box((0.0, 0.0, z1 + (TW_H - z1) * 0.5),
                    (TW_W, TW_T, TW_H - z1), GRANITE)
    faces += list(band_lo) + list(band_hi)

    # umbra pe fata dinspre -Y si rosturi pe buiandrugi
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    b.retag(band_hi, JOINT, where="down")
    # 3 umflaturi mari de piatra (regula 0.5)
    rand = _lcg(9700)
    for k in range(3):
        s = 0.5 + rand() * 0.4
        b.rock((-TW_W * 0.3 + TW_W * 0.3 * k, TW_T * 0.45,
                0.5 + rand() * 0.8),
               (s * 1.5, s * 0.7, s * 1.1), GRANITE_SH,
               seed=int(rand() * 800), segments=6, rings=2, taper=0.32)
    return b.to_object("Three_Windows")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(obj, path, ao, origin="base", bevel=0.05, smooth_angle=55.0):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin,
                smooth_angle=smooth_angle)
    _, sz = export_glb([obj], "machupicchu/" + path)
    results.append((path, st["tris"], sz / 1024.0, st["ao_min"], st["ao_max"]))
    return st


# smooth_angle=26: varful trebuie sa aiba FETE MARI TAIOASE (brief §1.1), iar
# pragul implicit de 55° netezea tot conul intr-o movila fara fatete — se vedea
# in plansa de control. Sub prag muchiile raman crispe, deci silueta capata
# planuri de granit.
emit(build_huayna_picchu(), "rocks/huayna_picchu.glb", AO_PEAK,
     origin="base_axis", bevel=0.12, smooth_angle=26.0)
emit(build_inti_punku(), "structures/inti_punku.glb", AO_GATE,
     origin="base_axis", bevel=0.06)
emit(build_main_gate(), "structures/main_gate.glb", AO_GATE,
     origin="base_axis", bevel=0.06)
emit(build_inca_bridge_ledge(), "structures/inca_bridge_ledge.glb", AO_LEDGE,
     origin="base_axis", bevel=0.08)
emit(build_sun_temple(), "structures/sun_temple.glb", AO_SMALL, bevel=0.05)
emit(build_intihuatana(), "structures/intihuatana.glb", AO_SMALL, bevel=0.04)
emit(build_three_windows(), "structures/three_windows.glb", AO_SMALL, bevel=0.05)

print()
for path, tris, kb, ao_lo, ao_hi in results:
    print("%-44s tris=%6d %8.1f kB  AO %.2f..%.2f"
          % (path, tris, kb, ao_lo, ao_hi))
print("TOTAL hero: %d tris" % sum(t for _, t, _, _, _ in results))
