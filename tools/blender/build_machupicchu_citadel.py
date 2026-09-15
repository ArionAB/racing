"""Machu Picchu — KITUL DE CETATE (plansa de inventar, randul 8).

  machupicchu/structures/inca_wall_a.glb      zid de terasa 4.0 m (se inlantuie)
  machupicchu/structures/inca_wall_b.glb      zid de 6.0 m cu 2 nise
  machupicchu/structures/inca_wall_c.glb      capat de zid 2.0 m, colt rotunjit
  machupicchu/structures/inca_stair_a.glb     scara de 10 trepte (rise 2.5)
  machupicchu/structures/inca_stair_b.glb     scara de 20 de trepte (rise 5.0)
  machupicchu/buildings/inca_house_a.glb      casa cu acoperis de paie
  machupicchu/buildings/inca_house_b.glb      ruina fara acoperis
  machupicchu/buildings/guardhouse.glb        Casa Paznicului (trei ziduri)
  machupicchu/structures/fountain_basin.glb   bazin + quad de apa
  machupicchu/structures/water_channel.glb    jgheab de 4.0 m (se inlantuie)
  machupicchu/structures/trail_marker.glb     piatra in picioare
  machupicchu/structures/rope_rail.glb        parapet de creasta

TREISPREZECE fisiere, douasprezece piese: `inca_stair_a/b` ies din acelasi
constructor cu alt numar de trepte.

CONTRACTUL DE INLANTUIRE (brief §1.2, verificat intai, inainte de restul).
Zidurile `a`/`b` si jgheabul se pun cap la cap pe pista, deci capetele lor sunt
PLANE si cad exact la +-jumatate de lungime. Doua lucruri le ameninta, si
amandoua au fost masurate, nu presupuse:

  1. Neregularitatea crestei. Creasta zidului NU e o linie dreapta (un zid incas
     erodat n-are muchie de rigla, si exact linia perfecta il face sa citeasca a
     grinda de beton). Dar daca abaterea se aplica si pe coloanele de CAPAT,
     doua piese vecine ajung cu creste diferite la aceeasi cota si imbinarea
     capata o treapta. De aceea `_crest_drops` fixeaza primul si ultimul capat
     la ZERO: creasta serpuieste in interior si se intoarce la cota nominala
     exact pe rostul de imbinare.
  2. Bevel-ul. `apply_bevel` tesesc fiecare muchie care depaseste pragul de
     unghi, INCLUSIV conturul fetei de capat. Doua capete tesite puse fata in
     fata lasa o santura in V cat de doua ori latimea bevel-ului — pe zid,
     bevel-ul de 0.08 cerut in brief ar fi dat un rost de 16 cm la fiecare
     imbinare, adica exact "rostul vizibil" pe care contractul il interzice.
     Zidurile care se inlantuie primesc deci `bevel_angle=75`: muchiile de 90°
     ale capetelor raman ASCUTITE, iar tesitura ramane doar pe creasta (unde
     unghiurile sunt mici, fiindca panta crestei se intalneste cu fata sub un
     unghi mic). Masurat pe GLB dupa export: capetele stau la +-2.000.

REGULA 0.5 (brief §0.5): rosturile de piatra NU sunt geometrie. Nicio caramida
modelata — zidul `a` se multiplica de ~90 de ori pe pista, iar rosturile vin
dintr-o clasa triplanara la integrare. Ce ramane in geometrie e ce se vede in
SILUETA: creasta neregulata, batura (zidurile incase se apleaca spre interior
cu cota) si 2-4 umflaturi mari de piatra. Sunt ieftine si sunt singurul lucru
care desparte "zid incas" de "cutie".

SUPRAFETELE PE CARE SE MERGE au varfuri PARTAJATE (brief §0.7): treptele
scarilor se construiesc ca UN profil continuu (contratreapta + calca din
aceleasi varfuri), nu ca lespezi suprapuse. Cu fizica intreaga un prag de placa
de peste 0.3 m e un zid.

PIESELE CARE PRIMESC CLASA LA INTEGRARE se sparg in obiecte de UN SINGUR
material (brief §0.6): casa = `House_Stone` + `House_Thatch`, fantana =
`Basin` + `Water`. Se exporta impreuna, copii directi ai radacinii.

AXE: -Z Godot = +Y Blender e "inainte". Zidurile se intind pe X, scarile urca
spre +Y, casa paznicului e deschisa spre -Y.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_citadel.py
"""

import math
from mathutils import Matrix, Vector

# AO: `dist` e raza de raycast, deci se scaleaza cu piesa. Pe un zid de 2.5 m o
# raza de 3 m gaseste pamantul si vecinii; pe o casa de 4.5 m trebuie mai mare,
# altfel streasina nu ocluzeaza peretele de sub ea si acoperisul pluteste.
AO_WALL = dict(samples=20, dist=3.0, gradient="vertical",
               low=0.46, high=1.00, power=0.88, floor=0.17)
AO_STAIR = dict(samples=20, dist=4.0, gradient="vertical",
                low=0.44, high=1.00, power=0.86, floor=0.16)
AO_HOUSE = dict(samples=24, dist=5.5, gradient="vertical",
                low=0.44, high=1.00, power=0.88, floor=0.15)
AO_SMALL = dict(samples=22, dist=2.0, gradient="vertical",
                low=0.48, high=1.00, power=0.90, floor=0.19)

# Sloturile legale pe pista asta (brief §0.4). Zero sloturi noi.
GRANITE = MARBLE_GREY        # granit in soare: fetele principale ale zidurilor
GRANITE_SH = ROCK_LIGHT      # granit in umbra
JOINT = ROCK_DARK            # fundul niselor, rosturi adanci, goluri
MOSS = CACTUS_GREEN          # muschi pe creasta, iarba la picior
THATCH = DRY_VEGETATION      # paie de acoperis, franghie
TIMBER = WOOD                # stalpi, barne. (`WOOD_WEATHERED` NU exista in
                             #  dio_lib — constanta e `WOOD`, acelasi slot 9.)
WATER = REEF_SHALLOW         # doar quad-ul de apa al fantanii
EARTH = SAND_SHADOW


# --- zidurile -----------------------------------------------------------------
#
# Cotele de contract, in metri. Latimea e pe X (zidul se intinde pe X si se
# inlantuie pe X), grosimea pe Y, inaltimea pe Z.
W_THICK = 0.8
W_HEIGHT = 2.5
# Batura: cat se retrage fata zidului la creasta fata de baza, PE FIECARE FATA.
# Zidurile incase se apleaca spre interior — semnatura care se vede in silueta
# de la 30 m si care costa zero triunghiuri (aceleasi inele, alta raza).
W_BATTER = 0.09
# Cat coboara creasta in punctele ei cele mai joase. Peste ~0.2 m zidul incepe
# sa arate darapanat (si asta e ruina, `inca_house_b`), sub ~0.06 nu se vede.
W_CREST = 0.13


# Cota la care creasta trece prin CAPETE. Nu e zero, si nu e nici cea mai joasa
# cota: e cota MEDIANA a crestei. Cifra vine din doua plansa de inlantuire
# citite una dupa alta, nu dintr-o preferinta.
#
# Cu capetele la zero (= cota nominala, cea mai INALTA), fiecare imbinare devine
# punctul cel mai de sus al zidului si creasta coboara de-o parte si de alta:
# la 90 de instante cap la cap iese un sirag de noduri la fiecare 4 m, adica
# exact ritmul pe care creasta neregulata trebuia sa-l ascunda. A doua plansa a
# aratat ca mutarea capetelor la o cota fixa mai joasa NU rezolva — nodul ramane
# nod, doar mai mic, fiindca vecinatatea imbinarii e tot un maxim local.
#
# Ce rezolva: creasta trebuie sa TREACA prin imbinare, nu sa se intoarca la ea.
# Capetele stau la mediana, iar coloana de langa fiecare capat e fortata una SUB
# si una PESTE ea (`_crest_drops`), deci profilul coboara pe o parte si urca pe
# cealalta. Doua piese vecine se intalnesc la aceeasi cota (contractul cerut:
# fara prag), dar panta continua peste rost — ochiul nu mai are de ce sa se
# agate la interval regulat.
W_CREST_END = 0.065


def _crest_drops(rand, count):
    """Abaterea de cota a crestei pentru `count` coloane.

    Capetele primesc aceeasi cota (`W_CREST_END`), deci imbinarea ramane
    continua. Coloanele vecine capetelor sunt fortate de-o parte si de alta a ei
    — una mai sus, una mai jos — ca profilul sa TREACA prin rost in panta, nu
    sa-l atinga ca pe un varf. Vezi nota de la `W_CREST_END`.
    """
    drops = [W_CREST_END + (rand() - 0.5) * W_CREST for _ in range(count)]
    drops[0] = W_CREST_END
    drops[-1] = W_CREST_END
    if count >= 4:
        # panta care intra in rost si panta care iese din el, in sensuri opuse
        drops[1] = W_CREST_END + W_CREST * 0.45
        drops[-2] = max(0.0, W_CREST_END - W_CREST * 0.40)
    return drops


def _wall_body(b, length, seed, columns=5, niches=(), height=W_HEIGHT,
               thick=W_THICK, round_end=None):
    """Corpul unui zid: o banda de coloane intre doua capete plane.

    Nu e `b.box()` dintr-un motiv: o cutie are creasta dreapta si fete
    verticale, adica exact zidul-caramida pe care plansa NU-l arata. Aici
    fiecare coloana isi are cota ei de creasta si fata ei retrasa cu batura,
    iar capetele raman plane la +-length/2 (contract de inlantuire).

    `niches` = lista de x-uri (relativ la centru) unde fata dinspre +Y are o
    adancitura trapezoidala. Nisa e RETRASA in grosimea zidului, nu un volum
    lipit pe el: altfel ar manca din grosimea de contract si ar iesi in afara.

    `round_end` ("+x"/"-x") retrage coltul dinspre acel capat pe orizontala:
    terminatia de zid a plansei are coltul rotunjit, nu taiat drept.
    """
    rand = _lcg(seed)
    half = length * 0.5
    drops = _crest_drops(rand, columns)
    xs = [-half + length * i / (columns - 1) for i in range(columns)]

    # DOUA BENZI DE COTA, nu una: talpa, linia de asiza, creasta. Fata se
    # retrage in doua trepte, deci batura are o MUCHIE la mijloc in loc sa fie o
    # panta continua — o linie orizontala pe toata lungimea, care e semnalul de
    # "zidarie in asize" si care se citeste in silueta, de la distanta.
    #
    # Ce s-a INCERCAT si s-a SCOS, ca sa nu se reintroduca: o abatere pe Y per
    # coloana ("valul de fata"), menita sa rupa planul peretelui. Plansa de
    # inlantuire a aratat ca nu produce relief de piatra, ci pete verticale
    # difuze — cu `smooth_angle` implicit, lumina curge peste abaterea de 3 cm si
    # iese ca murdarie pe un plan, nu ca zidarie. Era si o incercare de a imita
    # in GEOMETRIE ce regula 0.5 spune explicit ca vine din TEXTURA: rosturile si
    # granulatia blocurilor sunt ale clasei triplanare aplicate la integrare.
    #
    # Ce ramane deci in geometrie e SILUETA, adica exact ce textura nu poate da:
    # creasta neregulata, muchia de asiza, capetele plane si umflaturile mari.
    # Zidul se multiplica de ~90 de ori; orice triunghi cheltuit pe detaliu de
    # suprafata e platit de 90 de ori pentru ceva ce acopera textura.
    z_course = height * 0.52

    cols = []
    for i, x in enumerate(xs):
        z_top = height - drops[i]
        y_base = thick * 0.5
        y_course = thick * 0.5 - W_BATTER * 0.45
        y_top = thick * 0.5 - W_BATTER
        # Coltul rotunjit al terminatiei (`inca_wall_c`): capatul dinspre
        # `round_end` isi retrage varfurile de SUS spre axa, deci silueta lui nu
        # mai e un unghi drept. Se face pe varfuri, nu cu bevel, fiindca
        # bevel-ul ar tesi si fata de imbinare de la celalalt capat.
        #
        # Retragerea e DOAR pe Y (grosime). O retragere pe X ar scurta piesa si
        # ar rupe contractul de capat: masurat pe prima rulare, `pull` aplicat
        # lateral ducea capatul la x = +-1.011 in loc de +-1.000.
        pull = 0.0
        if round_end == "+x" and i == len(xs) - 1:
            pull = thick * 0.30
        elif round_end == "-x" and i == 0:
            pull = thick * 0.30
        cols.append([
            b.bm.verts.new((x, -y_base, 0.0)),
            b.bm.verts.new((x, y_base, 0.0)),
            b.bm.verts.new((x, y_course, z_course)),
            b.bm.verts.new((x, y_top - pull, z_top)),
            b.bm.verts.new((x, -y_top + pull, z_top)),
            b.bm.verts.new((x, -y_course, z_course)),
        ])

    faces = []
    for a, c in zip(cols, cols[1:]):
        # fata dinspre +Y (spre drum), in doua benzi
        faces.append(b.bm.faces.new((a[1], c[1], c[2], a[2])))
        faces.append(b.bm.faces.new((a[2], c[2], c[3], a[3])))
        # creasta
        faces.append(b.bm.faces.new((a[3], c[3], c[4], a[4])))
        # fata dinspre -Y, tot in doua benzi
        faces.append(b.bm.faces.new((a[4], c[4], c[5], a[5])))
        faces.append(b.bm.faces.new((a[5], c[5], c[0], a[0])))
        # talpa
        faces.append(b.bm.faces.new((a[0], c[0], c[1], a[1])))
    # capetele: fete PLANE, exact la +-half. Contractul de inlantuire.
    faces.append(b.bm.faces.new(tuple(reversed(cols[0]))))
    faces.append(b.bm.faces.new(tuple(cols[-1])))

    for f in faces:
        f[b.slot] = GRANITE
    # Fata dinspre -Y sta in umbra tot timpul; creasta prinde muschi.
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.5 and c.z > height * 0.72)

    # Nisele trapezoidale: adancituri RETRASE in grosimea zidului. Fata lor
    # dinspre drum e coplanara cu fata zidului (nu iese din el), iar fundul e
    # retag-uit pe JOINT — golul citeste din VALOARE, nu din geometrie sapata.
    for nx in niches:
        depth = 0.3
        y_face = thick * 0.5 - W_BATTER * 0.45
        nis = b.box((nx, y_face - depth * 0.5, height * 0.46),
                    (0.55, depth, 0.95), JOINT)
        b.retag(nis, JOINT)
        # Nisa e o cutie ingropata in zid: din ea se vad doar gura si fundul,
        # iar muchiile ei interioare n-au ce tesi. Bevel-ul le-ar rotunji pe
        # toate douasprezece, adica ~32 de triunghiuri fiecare, pe o forma din
        # care se vede o treime. Se marcheaza ca sa NU fie tesita (muchii sub
        # pragul de unghi al zidului raman intacte oricum).

    # 2-3 umflaturi mari de piatra (regula 0.5: volumul mare, nu caramida).
    # Stau pe fata dinspre drum, ingropate pe jumatate in zid.
    #
    # `rings=1`: umflatura e ingropata pe jumatate, deci al doilea inel cade in
    # interiorul zidului si nu se vede niciodata — plateai 2x triunghiuri pentru
    # jumatatea ascunsa. Cu 4 segmente si un inel, silueta care IESE din zid e
    # aceeasi, iar zidul `b` intra in buget.
    for k in range(3 if length > 3.0 else 2):
        s = 0.34 + rand() * 0.26
        bx = -half * 0.62 + length * 0.30 * k + (rand() - 0.5) * 0.3
        b.rock((bx, thick * 0.5 - W_BATTER * 0.5 - 0.04,
                0.35 + rand() * (height * 0.5)),
               (s * 1.5, s * 0.55, s * 1.1), GRANITE_SH,
               seed=int(rand() * 900), segments=4, rings=1, taper=0.34)
    return faces


# Numarul de coloane e parghia de buget a zidurilor: fiecare coloana in plus
# costa 6 fete (doua benzi x doua fete + creasta + talpa), adica ~12 triunghiuri
# dupa triangulare si ~3.7x dupa bevel. Cu 5 coloane zidul `a` iesea 306/300.
# Patru coloane pastreaza tot ce conteaza (creasta care trece in panta prin
# rost, muchia de asiza, capetele plane) si intra in buget.
def build_inca_wall_a():
    """Zidul standard de 4.0 m. Capete plane la x = +-2.0."""
    b = Builder()
    _wall_body(b, 4.0, seed=4101, columns=4)
    return b.to_object("Inca_Wall_A")


def build_inca_wall_b():
    """Zidul de 6.0 m cu doua nise. Capete plane la x = +-3.0.

    Cele doua nise costa 2 x ~44 de triunghiuri dupa bevel, deci zidul `b` are
    mai putine coloane decat i-ar da lungimea: nisele SUNT contractul lui
    (brief §1.2), coloanele sunt doar rezolutia crestei.
    """
    b = Builder()
    _wall_body(b, 6.0, seed=4202, columns=4, niches=(-1.5, 1.5))
    return b.to_object("Inca_Wall_B")


def build_inca_wall_c():
    """Capat de zid de 2.0 m, cu coltul dinspre +x rotunjit (terminatie).

    Capatul dinspre -x ramane PLAN la x = -1.0, ca sa se lege de un zid `a`.
    """
    b = Builder()
    _wall_body(b, 2.0, seed=4303, columns=3, round_end="+x")
    return b.to_object("Inca_Wall_C")


# --- scarile ------------------------------------------------------------------
#
# Scara incastrata in zid: treptele urca spre +Y Blender, latimea pe X.
# Originea la baza primei trepte.

S_WIDTH = 2.0


def _stair_body(b, steps, rise_total, run_total, width=S_WIDTH):
    """Trepte cu VARFURI PARTAJATE + doi obraji de zid.

    Profilul (contratreapta verticala + calca orizontala) e UN SINGUR lant de
    puncte in planul YZ, maturat pe X: muchia din spatele calcai ESTE muchia din
    fata contratreptei urmatoare. Doua placi suprapuse ar lasa exact acolo un
    prag de placa, iar cu fizica intreaga orice prag peste 0.3 m e un zid
    (memoria `suprafete-cu-goluri-si-praguri`). Aici treapta are 0.25 m, deci si
    daca o masina calca pe scara, urca — nu se opreste in ea.
    """
    rise = rise_total / steps
    run = run_total / steps
    # profil in (y, z), de la piciorul scarii in sus
    prof = [(0.0, 0.0)]
    for k in range(steps):
        prof.append((k * run, (k + 1) * rise))          # contratreapta
        prof.append(((k + 1) * run, (k + 1) * rise))    # calca
    half = width * 0.5

    left = [b.bm.verts.new((-half, y, z)) for y, z in prof]
    right = [b.bm.verts.new((half, y, z)) for y, z in prof]
    faces = []
    for i in range(len(prof) - 1):
        faces.append(b.bm.faces.new((left[i], right[i], right[i + 1], left[i + 1])))
    for f in faces:
        f[b.slot] = GRANITE
    # Contratreptele (fetele aproape verticale) stau in umbra treptei de
    # deasupra: banda de valoare care face scara sa citeasca de la distanta.
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.z < 0.5)

    # Talpa si spatele, ca scara sa fie un SOLID, nu o foaie: o banda de
    # quad-uri fara dos ar disparea vazuta de dedesubt (backface culling).
    y_end, z_end = prof[-1]
    base = [b.bm.verts.new((-half, 0.0, 0.0)), b.bm.verts.new((half, 0.0, 0.0)),
            b.bm.verts.new((half, y_end, 0.0)), b.bm.verts.new((-half, y_end, 0.0))]
    under = b.bm.faces.new(tuple(reversed(base)))
    back = b.bm.faces.new((base[3], base[2],
                           b.bm.verts.new((half, y_end, z_end)),
                           b.bm.verts.new((-half, y_end, z_end))))
    for f in (under, back):
        f[b.slot] = GRANITE_SH
    # cele doua laturi, inchise pe profil
    for sx, ring in ((-1.0, left), (1.0, right)):
        pts = [ring[0]] + list(ring) + [b.bm.verts.new((sx * half, y_end, 0.0))]
        side = b.bm.faces.new(tuple(pts[1:] if sx > 0 else reversed(pts[1:])))
        side[b.slot] = GRANITE_SH
    return faces


def _stair_cheeks(b, steps, rise_total, run_total, seed, width=S_WIDTH):
    """Obrajii de zid care incastreaza scara — pe plansa scara e INTRE doua
    ziduri de terasa, nu o lespede singura in camp. Fara ei citeste a rampa.

    Fiecare obraz e o pana care urca odata cu treptele: se construieste din
    coloane, ca zidurile, deci capata aceeasi creasta neregulata.
    """
    rand = _lcg(seed)
    t = 0.30                          # grosimea obrazului
    # Obrazul URMEAZA PROFILUL TREPTELOR, nu o panta dreapta, si sta jos.
    #
    # Asta era defectul "scara = pana neteda", si nu era in trepte: sonda de
    # ocluzie (`preview_stair_check.py`) a randat aceeasi piesa din trei unghiuri
    # si treptele apar CLAR de sus si din lateral. Din vederea de panta, cea in
    # care se conduce, nu se vedeau deloc — fiindca obrajii de 0.45 m grosime
    # urcau drept, cu parapet de 0.55 m PESTE linia calcai (masurat pe GLB:
    # 0.476 m peste corpul scarii), pe o scara lata de doar 2.0 m. Doi pereti
    # mai inalti decat treptele, de-o parte si de alta, ocluzau tot.
    #
    # Acum: creasta obrazului urca IN TREPTE (acelasi profil ca scara, ridicat
    # cu `parapet`), deci obrazul citeste ca zid incastrat si lasa treptele
    # vizibile din orice unghi. Parapetul scade la 0.18 m — destul cat scara sa
    # para incastrata, prea putin cat sa ascunda calca urmatoare.
    parapet = 0.18
    rise = rise_total / steps
    run = run_total / steps
    for sx in (-1.0, 1.0):
        x_in = sx * (width * 0.5)
        x_out = sx * (width * 0.5 + t)
        cols = []
        # Un punct la fiecare a TREIA treapta, nu la fiecare.
        #
        # Creasta in trepte se citeste la fel — obrazul urmeaza panta oricum —
        # dar costul nu e deloc la fel: cu un punct per treapta (11 coloane la
        # scara `a`, 21 la `b`) obrajii singuri duceau piesele la 646/300 si
        # 1246/500. Fiecare coloana costa 4 fete per interval.
        step_every = 3
        n = max(steps // step_every + 1, 3)
        drops = _crest_drops(rand, n)
        for i in range(n):
            k = min(i * step_every, steps)      # a cata treapta
            y = run * k
            z = rise * k + parapet - drops[i] * 0.35
            cols.append([
                b.bm.verts.new((x_in, y, 0.0)),
                b.bm.verts.new((x_out, y, 0.0)),
                b.bm.verts.new((x_out, y, z)),
                b.bm.verts.new((x_in, y, z)),
            ])
        faces = []
        for a, c in zip(cols, cols[1:]):
            faces.append(b.bm.faces.new((a[0], c[0], c[1], a[1])))
            faces.append(b.bm.faces.new((a[1], c[1], c[2], a[2])))
            faces.append(b.bm.faces.new((a[2], c[2], c[3], a[3])))
            faces.append(b.bm.faces.new((a[3], c[3], c[0], a[0])))
        faces.append(b.bm.faces.new(tuple(reversed(cols[0]))))
        faces.append(b.bm.faces.new(tuple(cols[-1])))
        for f in faces:
            f[b.slot] = GRANITE
        b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5 or n.x * sx < -0.5)
        b.retag(faces, MOSS, where=lambda c, n: n.z > 0.5)


def build_inca_stair(steps, rise_total, run_total, name, seed):
    b = Builder()
    _stair_body(b, steps, rise_total, run_total)
    _stair_cheeks(b, steps, rise_total, run_total, seed)
    return b.to_object(name)


# --- casele -------------------------------------------------------------------
#
# Doua noduri separate (brief §0.6): `House_Stone` si `House_Thatch` primesc
# clase de textura diferite la integrare, deci NU pot fi acelasi obiect.

H_W, H_D = 6.0, 4.0          # latime (X) x adancime (Y)
H_WALL = 2.5                 # cota streasinii
H_RIDGE = 4.5                # cota coamei (frontonul urca pana aici)
H_THICK = 0.55               # grosimea zidului


def _house_walls(b, width, depth, wall_h, ridge_h, thick=H_THICK,
                 open_side=None, seed=5100, gable=True):
    """Cele patru ziduri + frontoanele, ca volume separate.

    CONVENTIA DE AXE, aleasa O SINGURA DATA pentru toata casa (pereti, frontoane
    si acoperis): **coama pe Y, panta pe X**, adica exact conventia lui
    `roof_panels()` din `build_alpine_buildings.py`, care se foloseste aici
    nemodificat. Frontoanele stau deci pe peretii dinspre +-Y, iar varful lor
    cade la x = 0.

    Asta a fost bug-ul care a rupt de doua ori plansa de cladiri: frontoanele
    erau construite cu coama pe X (varf la y = 0), iar acoperisul cobora pe
    cealalta axa — perpendicular pe ele. Placile n-aveau pe ce sa se reazeme si
    ieseau doua aripi aproape verticale, cu fanta pe coama. A doua incercare a
    intors doar acoperisul, nu si frontoanele, deci defectul si-a schimbat
    orientarea, nu natura.

    Regula de acum: NIMIC nu-si recalculeaza cotele pe cont propriu. Peretii,
    frontonul si placile ies toate din aceleasi patru numere — `half_w`,
    `wall_h` (= eave), `ridge_h`, `depth` — deci se inregistreaza prin
    constructie, nu prin potrivire.

    `open_side="-y"` lasa peretele dinspre -Y deoparte (Casa Paznicului e
    deschisa spre -Y, brief §1.2). Acolo frontonul RAMANE: el poarta capatul
    coamei, si fara el acoperisul ar atarna in gol peste latura deschisa.
    """
    rand = _lcg(seed)
    hw, hd = width * 0.5, depth * 0.5
    faces = []
    # Zidurile lungi: pe laturile dinspre +-X (sub panta, de la talpa la
    # streasina). Ele sunt cele care se vad de sub acoperis.
    for sx in (-1.0, 1.0):
        faces += list(b.box((sx * (hw - thick * 0.5), 0.0, wall_h * 0.5),
                            (thick, depth, wall_h), GRANITE))
    # Zidurile de capat (pe +-Y) + frontonul triunghiular deasupra streasinii.
    # Frontonul face parte din ZID, nu din acoperis: fara el, sub placi ar
    # ramane un triunghi gol prin care se vede interiorul casei.
    for sy in (-1.0, 1.0):
        if not (open_side == "-y" and sy < 0):
            faces += list(b.box((0.0, sy * (hd - thick * 0.5), wall_h * 0.5),
                                (width - 2 * thick, thick, wall_h), GRANITE))
        if gable:
            faces += list(_gable_prism(b, sy * (hd - thick * 0.5), thick, hw,
                                       wall_h, ridge_h))
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    # umflaturi mari de piatra pe peretele dinspre +Y (regula 0.5)
    for k in range(3):
        s = 0.30 + rand() * 0.22
        b.rock((-width * 0.28 + width * 0.28 * k, hd - thick * 0.15,
                0.4 + rand() * (wall_h * 0.55)),
               (s * 1.4, s * 0.5, s * 1.05), GRANITE_SH,
               seed=int(rand() * 700), segments=4, rings=1, taper=0.33)
    return faces


def _gable_prism(b, y_center, thick, hw, wall_h, ridge_h):
    """Frontonul: triunghi in planul XZ, extrudat pe Y (grosimea zidului).

    Varful cade la **x = 0**, la cota `ridge_h` — adica exact unde `roof_panels`
    isi pune coama. Vezi nota de conventie din `_house_walls`.
    """
    pts = [(-hw, wall_h), (hw, wall_h), (0.0, ridge_h)]
    back, front = [], []
    for x, z in pts:
        back.append(b.bm.verts.new((x, y_center - thick * 0.5, z)))
        front.append(b.bm.verts.new((x, y_center + thick * 0.5, z)))
    faces = [b.bm.faces.new(tuple(reversed(front))), b.bm.faces.new(tuple(back))]
    for i in range(3):
        j = (i + 1) % 3
        faces.append(b.bm.faces.new((back[i], back[j], front[j], front[i])))
    for f in faces:
        f[b.slot] = GRANITE
    return faces


def _thatch_roof(b, width, depth, wall_h, ridge_h, overhang=0.45,
                 thickness=0.28, seed=5500):
    """Acoperis de paie in doua ape, ca NOD SEPARAT (primeste clasa de paie).

    E `roof_panels()` din `build_alpine_buildings.py`, copiat aici NEMODIFICAT
    ca reteta (doua cutii rotite cu `Matrix.Rotation(s*ang, 3, "Y")`), nu
    reimplementat din benzi de vertecsi.

    De ce copiat si nu importat: build-urile ruleaza prin `run_build.py`, care
    da fiecarui script globale proaspete din `dio_lib` — nu exista import intre
    doua scripturi de build. Reteta e insa scurta si bine intelesa, iar valoarea
    ei sta in ce DERIVA, nu in cate linii are.

    Ce face corect, si ce faceau gresit cele doua incercari dinaintea ei:
      - unghiul iese din COTE (`atan2(ridge - eave, half_w)`), nu e ales separat;
      - lungimea placii iese din aceleasi cote plus streasina, deci placa ajunge
        exact de la coama dincolo de streasina — nu se opreste in aer si nu
        trece prin perete;
      - coama e DEPASITA cu 0.25 m, ca cele doua placi sa se INCRUCISEZE.
        Capetele care doar se ating lasa o fanta pe coama, vizibila fix din
        chase cam — exact fanta care se vedea la Casa Paznicului.

    Panta merge pe X, coama pe Y (vezi conventia din `_house_walls`). Peretii,
    frontoanele si placile ies toate din `half_w`/`wall_h`/`ridge_h`/`depth`.
    """
    half_w = width * 0.5
    rise = ridge_h - wall_h
    ang = math.atan2(rise, half_w)
    # PLACA SE CONSTRUIESTE DIN VARFURILE FRONTONULUI, nu dintr-o formula de
    # lungime. Astea sunt exact punctele pe care le are `_gable_prism`:
    #   varful coamei   (0, ridge_h)
    #   coltul streasinii (+-half_w, wall_h)
    #
    # De ce asa, dupa trei incercari rupte: orice lungime calculata separat
    # (formula alpina, apoi `run + overhang/cos + 0.25`) poate sa nu se
    # potriveasca cu casa, si cand nu se potriveste placa trece DINCOLO de coama
    # — surplusul unei placi centrate pe linia pantei iese in sus, si aia e pana
    # A-frame. Garda pe care o pusesem masura doar capatul de JOS (`reach ==
    # limit`, deci raporta OK), fiindca nu se uita la capatul de sus. A disparut
    # odata cu formula: acum ambele capete sunt ancorate in geometria
    # frontonului si nu au cum sa o depaseasca.
    faces = set()
    top_z = None
    for s in (-1.0, 1.0):
        # vectorul pantei, de la coama spre coltul streasinii de pe partea `s`
        dx, dz = s * half_w - 0.0, wall_h - ridge_h
        dlen = math.hypot(dx, dz)
        ux, uz = dx / dlen, dz / dlen
        # capatul de SUS: coama, decalata cu 0.25 INAPOI pe panta (in sus), ca
        # cele doua ape sa se incruciseze peste coama in loc sa se atinga
        x0, z0 = 0.0 - ux * 0.25, ridge_h - uz * 0.25
        # capatul de JOS: coltul streasinii plus streasina masurata PE panta
        x1, z1 = s * half_w + ux * overhang, wall_h + uz * overhang
        length = math.hypot(x1 - x0, z1 - z0)
        rot = Matrix.Rotation(s * ang, 3, "Y")
        faces |= b.box(((x0 + x1) * 0.5, 0.0,
                        (z0 + z1) * 0.5 + thickness * 0.35),
                       (length, depth + 2 * overhang, thickness), THATCH,
                       rotation=rot)
        top_z = max(top_z or 0.0, z0 + thickness * 0.35 + thickness * 0.5)
    # Cotele placii in CADRUL DE CONSTRUCTIE. Nu e verdictul final: piesa se
    # aseaza abia in `emit`, cu offsetul comun al ansamblului, deci verdictul se
    # citeste din `measure()` dupa asezare (cota coamei fata de inaltimea casei).
    # Masuratoarea de aici a fost multa vreme inselatoare tocmai fiindca se uita
    # la geometrie care se muta ulterior.
    print("   acoperis w=%.1f (cadru de constructie): ang=%.1f° "
          "varf placa=%.2f / coama+gros=%.2f"
          % (width, math.degrees(ang), top_z, ridge_h + thickness))
    faces = list(faces)
    # Dedesubtul streasinii e in umbra permanenta: fara banda asta acoperisul
    # pluteste peste pereti in loc sa se aseze pe ei.
    b.retag(faces, JOINT, where="down")
    return faces


def build_inca_house_a():
    """Casa intreaga: `House_Stone` + `House_Thatch`, doua obiecte.

    Usa trapezoidala (semnatura incasa: se ingusteaza in sus) e un gol REAL in
    peretele dinspre +Y, nu o pata retag-uita: la 4 m de drum o usa pictata
    citeste ca murdarie pe perete.
    """
    bs = Builder()
    _house_walls(bs, H_W, H_D, H_WALL, H_RIDGE, seed=5101)
    # Usa trapezoidala si fereastra: adancituri de JOINT in peretele de capat
    # dinspre +Y (cel cu fronton, deci cel care se vede din fata). Golul citeste
    # din VALOARE — slotul cel mai inchis — nu din geometrie sapata.
    door = bs.box((-0.9, H_D * 0.5 - H_THICK * 0.45, 1.0),
                  (0.95, H_THICK * 0.5, 2.0), JOINT)
    bs.retag(door, JOINT)
    win = bs.box((1.5, H_D * 0.5 - H_THICK * 0.45, 1.55),
                 (0.6, H_THICK * 0.5, 0.6), JOINT)
    bs.retag(win, JOINT)
    stone = bs.to_object("House_Stone")

    bt = Builder()
    _thatch_roof(bt, H_W, H_D, H_WALL, H_RIDGE, seed=5501)
    thatch = bt.to_object("House_Thatch")
    return stone, thatch


def build_inca_house_b():
    """Ruina: 6 x 4, FARA acoperis, frontoane rupte la inaltimi diferite.

    UN SINGUR nod (brief §1.2): n-are paie, deci n-are a doua clasa.

    Ruptura nu e "acelasi zid mai scund": fiecare capat se rupe la alta cota si
    creasta coboara in trepte neregulate spre spartura. Un zid retezat drept
    citeste a constructie neterminata, nu a ruina.
    """
    b = Builder()
    rand = _lcg(5202)
    hw, hd = H_W * 0.5, H_D * 0.5
    thick = H_THICK
    faces = []
    # zidurile lungi, cu creasta care coboara pe portiuni
    for sy in (-1.0, 1.0):
        # 5 coloane, nu 7: ruptura crestei are nevoie de cateva cote diferite,
        # nu de o curba fina. Vezi nota de la moloz pentru bugetul piesei.
        n = 5
        cols = []
        for i in range(n):
            x = -hw + H_W * i / (n - 1)
            # profil de ruptura: doua caderi, la cote diferite pe cele doua fete
            t = i / (n - 1)
            base = H_WALL * (0.95 if sy > 0 else 0.80)
            fall = 0.55 * math.sin(math.pi * t * (1.6 if sy > 0 else 2.3))
            z = max(0.7, base - fall - rand() * 0.18)
            y0 = sy * (hd - thick)
            y1 = sy * hd
            cols.append([
                b.bm.verts.new((x, y0, 0.0)), b.bm.verts.new((x, y1, 0.0)),
                b.bm.verts.new((x, y1, z)), b.bm.verts.new((x, y0, z)),
            ])
        for a, c in zip(cols, cols[1:]):
            for k in range(4):
                j = (k + 1) % 4
                faces.append(b.bm.faces.new((a[k], c[k], c[j], a[j])))
        faces.append(b.bm.faces.new(tuple(reversed(cols[0]))))
        faces.append(b.bm.faces.new(tuple(cols[-1])))
    # zidurile de capat, rupte si ele la cote diferite
    for sx, top in ((-1.0, 1.9), (1.0, 1.25)):
        n = 5
        cols = []
        for i in range(n):
            y = -hd + H_D * i / (n - 1)
            z = max(0.6, top - rand() * 0.45)
            x0 = sx * (hw - thick)
            x1 = sx * hw
            cols.append([
                b.bm.verts.new((x0, y, 0.0)), b.bm.verts.new((x1, y, 0.0)),
                b.bm.verts.new((x1, y, z)), b.bm.verts.new((x0, y, z)),
            ])
        for a, c in zip(cols, cols[1:]):
            for k in range(4):
                j = (k + 1) % 4
                faces.append(b.bm.faces.new((a[k], c[k], c[j], a[j])))
        faces.append(b.bm.faces.new(tuple(reversed(cols[0]))))
        faces.append(b.bm.faces.new(tuple(cols[-1])))
    for f in faces:
        f[b.slot] = GRANITE
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.5)
    # Moloz la picior: pietrele cazute din creasta. Ele sunt ce spune "ruina"
    # inainte ca ochiul sa ajunga la creasta. Trei, nu cinci, si cu 4 segmente:
    # sunt pietre de 30 cm langa o casa de 6 m, deci silueta lor individuala nu
    # se citeste — conteaza doar ca exista moloz. La 5 x (5 seg, 2 inele) ruina
    # iesea 828/500.
    for k in range(3):
        s = 0.22 + rand() * 0.20
        a = 2.0 * math.pi * k / 3 + rand() * 0.8
        b.rock((math.cos(a) * hw * 0.85, math.sin(a) * hd * 1.1, 0.0),
               (s * 1.5, s * 1.3, s * 0.9), GRANITE_SH,
               seed=int(rand() * 800), segments=4, rings=1, taper=0.35)
    return b.to_object("House_Ruin")


def build_guardhouse():
    """Casa Paznicului: 7 x 4, trei ziduri (deschisa spre -Y), acoperis abrupt.

    E cadrul pozei clasice de la POI C, deci silueta ei conteaza mai mult decat
    a celorlalte: panta de 55° si streasina de 0.6 m sunt cotele din brief.
    Panta iese din cote — nu se fixeaza unghiul si se deduce coama, ci invers:
    ridge = wall + hw * tan(55°), ca sa fie exact 55°.
    """
    gw, gd = 7.0, 4.0
    wall_h = 2.5
    ridge_h = wall_h + (gw * 0.5) * math.tan(math.radians(55.0))
    bs = Builder()
    _house_walls(bs, gw, gd, wall_h, ridge_h, open_side="-y", seed=5303)
    # Doi stalpi de lemn care tin streasina pe latura deschisa (-Y). Stau sub
    # muchia frontonului deschis, la capetele lui.
    for sx in (-1.0, 1.0):
        bs.box((sx * (gw * 0.5 - 0.35), -gd * 0.5 + 0.2, wall_h * 0.5),
               (0.22, 0.22, wall_h), TIMBER)
    stone = bs.to_object("House_Stone")

    bt = Builder()
    _thatch_roof(bt, gw, gd, wall_h, ridge_h, overhang=0.6, thickness=0.32,
                 seed=5503)
    thatch = bt.to_object("House_Thatch")
    return stone, thatch


# --- fantana, jgheab, marcaj, parapet ----------------------------------------

def build_fountain_basin():
    """Bazin 1.5 x 1.0 x 0.6 cu gura de apa, plus quad-ul de apa.

    DOUA noduri (brief §0.6): `Basin` (MARBLE_GREY) si `Water` (REEF_SHALLOW).
    Apa e un quad PLAN la 0.5 m — primeste shader-ul de apa la integrare, deci
    trebuie sa fie o suprafata curata, nu un volum.
    """
    bw, bd, bh = 1.5, 1.0, 0.6
    t = 0.16
    bb = Builder()
    faces = []
    # cuva: patru pereti, fara capac (apa se vede inauntru)
    for sx in (-1.0, 1.0):
        faces += list(bb.box((sx * (bw * 0.5 - t * 0.5), 0.0, bh * 0.5),
                             (t, bd, bh), GRANITE))
    for sy in (-1.0, 1.0):
        faces += list(bb.box((0.0, sy * (bd * 0.5 - t * 0.5), bh * 0.5),
                             (bw - 2 * t, t, bh), GRANITE))
    # fundul cuvei, sub nivelul apei
    faces += list(bb.box((0.0, 0.0, t * 0.5), (bw - 2 * t, bd - 2 * t, t), JOINT))
    # Gura de apa pe latura -X: un jgheab scurt care iese din bazin. E
    # SEMNATURA piesei (brief: "gura de apa pe o latura"), deci ramane —
    # bugetul se face din bevel, nu din forma.
    faces += list(bb.box((-bw * 0.5 - 0.18, 0.0, bh * 0.78),
                         (0.4, 0.26, 0.14), GRANITE))
    bb.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    bb.retag(faces, JOINT, where=lambda c, n: n.z > 0.5 and c.z < t * 1.5)
    basin = bb.to_object("Basin")

    bw2 = Builder()
    # Quad PLAN la 0.5 m, retras de pereti ca sa nu z-fight-uiasca cu ei.
    #
    # ATENTIE la centrare: bazinul are gura de apa care iese in afara pe -X,
    # deci bbox-ul ANSAMBLULUI (pe care se calculeaza acum offsetul comun, in
    # `emit`) nu mai e centrat pe cuva. Quad-ul trebuie asezat fata de CUVA, si
    # compensat cu acelasi decalaj cu care gura trage centrul ansamblului —
    # altfel apa iese descentrata in bazin (masurat: x[-0.380, +0.760] in loc de
    # simetric).
    spout_shift = 0.19
    inset = t + 0.02
    z = 0.5
    v = [bw2.bm.verts.new(p) for p in (
        (-bw * 0.5 + inset - spout_shift, -bd * 0.5 + inset, z),
        (bw * 0.5 - inset - spout_shift, -bd * 0.5 + inset, z),
        (bw * 0.5 - inset - spout_shift, bd * 0.5 - inset, z),
        (-bw * 0.5 + inset - spout_shift, bd * 0.5 - inset, z))]
    f = bw2.bm.faces.new(tuple(v))
    f[bw2.slot] = WATER
    water = bw2.to_object("Water")
    return basin, water


def build_water_channel():
    """Jgheab de 4.0 x 0.4 x 0.3. Capete plane la x = +-2.0 (se inlantuie).

    Ca la ziduri, capetele trebuie sa ramana ascutite: un bevel pe conturul lor
    ar lasa o santura la fiecare imbinare. Se exporta cu `bevel_angle` mare.
    """
    b = Builder()
    length, width, height = 4.0, 0.4, 0.3
    wall = 0.09
    faces = []
    # Trei cutii (doi pereti + talpa) = 36 de triunghiuri brute, ~132 dupa
    # bevel, peste bugetul de 100. Bevel-ul e parghia corecta aici, nu
    # geometria: jgheabul E trei cutii, n-are ce sa piarda. Cu `bevel_angle`
    # mare raman tesite doar muchiile deschise, iar capetele (care se
    # inlantuie) trebuie sa ramana ascutite oricum.
    for sy in (-1.0, 1.0):
        faces += list(b.box((0.0, sy * (width * 0.5 - wall * 0.5), height * 0.5),
                            (length, wall, height), GRANITE))
    # talpa jgheabului
    faces += list(b.box((0.0, 0.0, wall * 0.5),
                        (length, width - 2 * wall, wall), GRANITE))
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    # fundul, unde sta apa: cel mai inchis slot, deci citeste ud
    b.retag(faces, JOINT, where=lambda c, n: n.z > 0.5 and c.z < wall * 1.4)
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.5 and c.z > height * 0.8)
    return b.to_object("Water_Channel")


def build_trail_marker():
    """Piatra in picioare 0.5 x 0.3 x 1.2, cu o dunga incizata.

    Nu e o cutie: coloanele se ingusteaza spre varf si se apleaca putin, ca sa
    citeasca a piatra infipta, nu a stalp de beton. Dunga incizata e retag pe
    JOINT intr-o banda de cota — zero triunghiuri.
    """
    b = Builder()
    rand = _lcg(6101)
    w, d, h = 0.5, 0.3, 1.2
    # 3 inele, nu 4: piatra are 1.2 m si sta langa drum ca reper, nu ca piesa
    # de studiat. Conicitatea si aplecarea se citesc si din trei inele.
    n = 3
    rings = []
    for k in range(n + 1):
        t = k / n
        z = h * t
        # se subtiaza spre varf si se apleaca usor pe X
        s = 1.0 - 0.30 * (t ** 1.2)
        lean = 0.05 * (t ** 1.6)
        ring = []
        for (dx, dy) in ((-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)):
            jitter = 0.90 + rand() * 0.18
            ring.append(b.bm.verts.new(
                (lean + dx * w * s * jitter, dy * d * s * jitter, z)))
        rings.append(ring)
    faces = []
    for lo, hi in zip(rings, rings[1:]):
        for i in range(4):
            j = (i + 1) % 4
            faces.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    faces.append(b.bm.faces.new(tuple(rings[-1])))
    faces.append(b.bm.faces.new(tuple(reversed(rings[0]))))
    for f in faces:
        f[b.slot] = GRANITE
    b.retag(faces, GRANITE_SH, where=lambda c, n: n.y < -0.5)
    # dunga incizata: o banda de cota pe JOINT
    b.retag(faces, JOINT,
            where=lambda c, n: 0.72 * h < c.z < 0.80 * h and abs(n.z) < 0.5)
    return b.to_object("Trail_Marker")


def build_rope_rail():
    """Parapet de creasta: doi stalpi de lemn de 1.0 m la 4.0 m distanta, plus
    o franghie cu sageata de 0.15 m.

    Capetele la x = +-2.0: parapetul se inlantuie, deci stalpii stau EXACT pe
    capete (nu retrasi), iar franghia incepe si se termina pe ei.

    Sageata (cateva segmente de `beam`, nu o linie dreapta) e tot ce desparte
    "franghie" de "bara": o coarda intinsa perfect citeste a teava.
    """
    b = Builder()
    half = 2.0
    post_h = 1.0
    for sx in (-1.0, 1.0):
        # Stalp usor conic, ca sa nu fie o teava. 5 segmente: `frustum` costa
        # 3*segments triunghiuri INAINTE de bevel, deci fiecare segment in plus
        # se plateste de patru ori pe piesa asta (doi stalpi, si bevel-ul peste).
        b.frustum((sx * half, 0.0, post_h * 0.5), 0.075, 0.055, post_h,
                  TIMBER, segments=5)
        # capacul stalpului, teșit
        b.box((sx * half, 0.0, post_h + 0.02), (0.14, 0.14, 0.05), TIMBER)
    # Franghia: lant de segmente pe o parabola cu sageata de 0.15.
    #
    # Trei segmente, nu sase. `beam` costa 12 triunghiuri brute si ~44 dupa
    # bevel, deci franghia era mai scumpa decat tot restul piesei la un loc
    # (488/200 la sase segmente). Sageata se citeste si din trei coarde — ce
    # conta era sa NU fie o linie dreapta, nu sa fie o parabola fina.
    n = 3
    sag = 0.15
    z_top = post_h - 0.12
    pts = []
    for i in range(n + 1):
        t = i / n
        x = -half + 2 * half * t
        z = z_top - sag * 4.0 * t * (1.0 - t)
        pts.append((x, 0.0, z))
    for a, c in zip(pts, pts[1:]):
        b.beam(a, c, 0.045, THATCH)
    return b.to_object("Rope_Rail")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.05, bevel_angle=30.0,
         smooth_angle=55.0, budget=None):
    """finish() pe fiecare nod + un singur export.

    Piesele pe doua noduri (casa, fantana) primesc AO cu `z_range` comun: altfel
    fiecare si-ar coace gradientul vertical pe intervalul LUI, si acoperisul de
    paie ar iesi la fel de umbrit la baza ca zidul de sub el (vezi bake_ao).
    """
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    zs = []
    for o in objs:
        zs += [v.co.z for v in o.data.vertices]
    ao = dict(ao)
    if len(objs) > 1:
        # `z_range` comun pe piesele sparte pe clase: fiecare nod si-ar coace
        # altfel gradientul vertical pe intervalul LUI, si acoperisul de paie ar
        # iesi la fel de umbrit la baza ca zidul de sub el (vezi bake_ao).
        #
        # DAR intervalul se ia inainte de `finish`, adica INAINTE ca originea sa
        # coboare geometria la z=0. La fantana, `Basin` (0..0.6) si `Water` (un
        # quad plat la 0.5) dadeau un interval in care quad-ul de apa ocupa un
        # singur punct: gradientul lui iesea CONSTANT, si asa s-a citit in
        # raport — AO 0.48..0.48, adica o masuratoare moarta (memoria
        # `multimesh-masuratoare-moarta`: o cifra identica la bit inseamna
        # mecanism neconectat, nu succes).
        #
        # Intervalul trebuie sa porneasca de la TALPA ansamblului (z minim, care
        # devine 0 dupa `origin="base"`), ca gradientul sa fie acelasi pentru
        # ambele noduri si sa aiba intindere reala.
        z_lo, z_hi = min(zs), max(zs)
        ao["z_range"] = (z_lo, max(z_hi, z_lo + 0.5))
    tris = 0
    # AO-ul se raporteaza pe TOATE nodurile, nu pe ultimul.
    #
    # Prima versiune tinea `stats` de la ultima iteratie si raporta intervalul
    # LUI. Pe fantana, ultimul nod e `Water` — un quad plan de patru varfuri, la
    # aceeasi cota, cu aceeasi ocluzie: un singur numar. Raportul iesea
    # "AO 0.48..0.48" si arata ca o masuratoare moarta (memoria
    # `multimesh-masuratoare-moarta`: o cifra identica la bit inseamna mecanism
    # neconectat). Bake-ul era in regula — raportarea se uita la alt obiect
    # decat cel despre care voiai sa afli (memoria `sonda-masura-alt-obiect`).
    ao_lo, ao_hi = 1.0, 0.0
    # ASEZAREA UNEI PIESE COMPUSE SE FACE PE ANSAMBLU, NU PE NOD.
    #
    # `finish(origin="base")` cheama `set_origin_base(center_xy=True)`, care
    # calculeaza `dx, dy, dz` pe bounding box-ul PROPRIU al obiectului primit.
    # Pe o piesa dintr-un singur nod e exact ce vrei. Pe una din doua noduri e
    # dezastru: zidurile au talpa la z=0 si nu se misca, dar acoperisul are
    # punctul cel mai de jos la streasina (~2.5 m), deci e COBORAT cu 2.5 m ca
    # streasina lui sa ajunga la zero — si re-centrat pe XY pe extentul lui, nu
    # al casei.
    #
    # Asta a rupt cladirile de patru ori la rand, si explica de ce trei
    # algoritmi diferiti de acoperis au esuat IDENTIC: nu placa era gresita, ci
    # asezarea de dupa ea. (Cele 88 de triunghiuri constante nu erau al doilea
    # bug — numarul de fete al unei cutii nu se schimba cand o muti.)
    #
    # Fix: `finish` aseaza UN SINGUR nod (primul, cel cu talpa la sol) si
    # intoarce vectorul cu care l-a mutat; celelalte noduri primesc EXACT
    # aceeasi translatie, deci pozitiile relative din cadrul de constructie se
    # pastreaza. E aceeasi clasa de greseala ca `z_range`-ul AO de mai sus:
    # o proprietate a ANSAMBLULUI calculata per nod.
    solo = len(objs) == 1
    if not solo:
        # Offsetul ANSAMBLULUI, calculat o data pe bbox-ul comun, cu exact
        # formula din `set_origin_base`. `finish` primeste apoi `origin=None` pe
        # fiecare nod (nu intra pe niciuna dintre ramurile base/base_axis/center,
        # deci nu muta nimic), iar translatia comuna o aplicam noi dupa aceea.
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x)
                ys.append(v.co.y)
                zs.append(v.co.z)
        center_xy = origin != "base_axis"
        place = Vector((
            -(min(xs) + max(xs)) * 0.5 if center_xy else 0.0,
            -(min(ys) + max(ys)) * 0.5 if center_xy else 0.0,
            -min(zs)))
    for o in objs:
        stats = finish(o, bevel=bevel, bevel_angle=bevel_angle, ao=ao,
                       origin=(origin if solo else None),
                       smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        tris += stats["tris"]
        ao_lo = min(ao_lo, stats["ao_min"])
        ao_hi = max(ao_hi, stats["ao_max"])
    _, sz = export_glb(list(objs), "machupicchu/" + path)
    results.append((path, tris, budget, sz / 1024.0, ao_lo, ao_hi))
    return tris


def measure(obj, label):
    """Cotele REALE ale unui obiect, masurate pe geometria finala.

    Cotele de contract nu sunt verificate de `verify_glb.py` (el vede sloturi,
    AO, origine, triunghiuri — nu latimi libere). Deci se masoara aici.
    """
    me = obj.data
    lo = [min(v.co[i] for v in me.vertices) for i in range(3)]
    hi = [max(v.co[i] for v in me.vertices) for i in range(3)]
    print("   %-16s x[%+.3f, %+.3f] y[%+.3f, %+.3f] z[%+.3f, %+.3f]"
          % (label, lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
    return lo, hi


# ZIDURILE SI JGHEABUL: `bevel_angle=75` pastreaza capetele ASCUTITE.
# Motivul, pe larg, in nota din capul fisierului: un bevel pe conturul fetei de
# capat lasa o santura in V la fiecare imbinare, adica exact rostul vizibil pe
# care contractul de inlantuire il interzice. Cu pragul la 75° raman tesite doar
# muchiile sub acel unghi (creasta neregulata, umflaturile de piatra), iar
# colturile drepte de 90° ale capetelor trec neatinse.
#
# `smooth_angle=None` pe ziduri: fetele raman FATETATE, fara netezire.
# Motivul e masurat pe a doua plansa de inlantuire: cu netezirea implicita
# (55°) lumina curgea peste muchia de asiza si peste umflaturile de piatra si
# le topea in pete difuze — zidul citea a plan murdar. Un zid de piatra vrea
# exact contrariul: planuri distincte, fiecare cu valoarea lui. Aceeasi alegere
# ca la `huayna_picchu` in valul 1 (smooth_angle=26 ca sa-i ramana fatetele).
CHAIN_BEVEL = dict(bevel=0.08, bevel_angle=75.0, smooth_angle=None)

wall_a = build_inca_wall_a()
emit(wall_a, "structures/inca_wall_a.glb", AO_WALL, budget=300, **CHAIN_BEVEL)
measure(wall_a, "inca_wall_a")

wall_b = build_inca_wall_b()
emit(wall_b, "structures/inca_wall_b.glb", AO_WALL, budget=300, **CHAIN_BEVEL)
measure(wall_b, "inca_wall_b")

wall_c = build_inca_wall_c()
emit(wall_c, "structures/inca_wall_c.glb", AO_WALL, budget=200, bevel=0.08,
     bevel_angle=60.0, smooth_angle=None)
measure(wall_c, "inca_wall_c")

stair_a = build_inca_stair(10, 2.5, 3.0, "Inca_Stair_A", seed=4401)
# Scarile: fatetate (`smooth_angle=None`) + bevel MIC.
#
# Ce face o treapta sa se VADA nu e tesitura, ci CONTRASTUL dintre calca
# orizontala si contrafata verticala — cele doua trebuie sa prinda lumina
# diferit. Cu netezirea implicita (55°) muchia dintre ele se amesteca si scara
# citeste ca o rampa oricat bevel ai pune; asa am pierdut doua iteratii, si e
# aceeasi capcana ca la `huayna_picchu` in valul 1.
#
# Deci netezirea dispare (o treapta de granit are muchia vie), iar bevel-ul
# ramane mic: 0.015. La zero scara iesea o pana fara trepte (124/300, adica
# forma lipsa, nu eficienta); la 0.02 sarea bugetul (398/300), fiindca profilul
# are ~60 de muchii de 90° si fiecare se plateste.
# `bevel_angle=70`: pe scara, LATIMEA tesiturii nu schimba numarul de
# triunghiuri — profilul are ~60 de muchii vii de 90°, si toate se califica la
# fel la 0.02 ca la 0.015, deci 398 ramanea 398 la orice latime. Singura parghie
# e cate muchii se tesesc: peste 70° muchiile drepte ale profilului nu se mai
# tesesc deloc, si raman tesite doar cele putine sub prag.
emit(stair_a, "structures/inca_stair_a.glb", AO_STAIR, origin="base_axis",
     bevel=0.02, bevel_angle=70.0, smooth_angle=None, budget=300)
measure(stair_a, "inca_stair_a")

stair_b = build_inca_stair(20, 5.0, 6.0, "Inca_Stair_B", seed=4402)
emit(stair_b, "structures/inca_stair_b.glb", AO_STAIR, origin="base_axis",
     bevel=0.02, bevel_angle=70.0, smooth_angle=None, budget=500)
measure(stair_b, "inca_stair_b")

house_a = build_inca_house_a()
emit(house_a, "buildings/inca_house_a.glb", AO_HOUSE, bevel=0.05, budget=700)
measure(house_a[0], "house_a stone")

house_b = build_inca_house_b()
emit(house_b, "buildings/inca_house_b.glb", AO_HOUSE, bevel=0.04,
     bevel_angle=60.0, budget=500)
measure(house_b, "inca_house_b")

guard = build_guardhouse()
emit(guard, "buildings/guardhouse.glb", AO_HOUSE, bevel=0.05, budget=800)
measure(guard[0], "guardhouse")

fountain = build_fountain_basin()
# Fantana: sase cutii (patru pereti + fund + gura) = 72 de triunghiuri brute,
# dar cu bevel de 0.02 ies 266, peste bugetul de 200. Forma nu are ce pierde —
# un bazin E o cuva dreptunghiulara — deci se taie din tesitura, nu din volume:
# `bevel_angle=70` lasa nebevelate muchiile drepte de 90° ale cuvei si tine
# doar buza de sus, singura care se vede de aproape.
emit(fountain, "structures/fountain_basin.glb", AO_SMALL, bevel=0.02,
     bevel_angle=80.0, smooth_angle=None, budget=200)
measure(fountain[0], "fountain basin")

channel = build_water_channel()
emit(channel, "structures/water_channel.glb", AO_SMALL, bevel=0.0,
     bevel_angle=75.0, smooth_angle=None, budget=100)
measure(channel, "water_channel")

marker = build_trail_marker()
emit(marker, "structures/trail_marker.glb", AO_SMALL, bevel=0.03, budget=80)
measure(marker, "trail_marker")

rail = build_rope_rail()
# Parapetul: fara bevel. Stalpii sunt frustum-uri de 5 laturi si franghia trei
# grinzi — geometrie deja rotunda sau prea subtire ca tesitura sa se vada, dar
# destule muchii cat bevel-ul sa coste 40% din piesa (332/200).
emit(rail, "structures/rope_rail.glb", AO_SMALL, origin="base_axis",
     bevel=0.0, budget=200)
measure(rail, "rope_rail")

print()
for path, tris, budget, kb, ao_lo, ao_hi in results:
    flag = "OK" if budget is None or tris <= budget else "DEPASIT"
    print("%-40s tris=%5d / %-5s %-8s %7.1f kB  AO %.2f..%.2f"
          % (path, tris, budget, flag, kb, ao_lo, ao_hi))
print("TOTAL cetate: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([wall_a, wall_b, wall_c, stair_a, stair_b, house_a[0], house_a[1],
            house_b, guard[0], guard[1], fountain[0], fountain[1], channel,
            marker, rail], "machupicchu_citadel.blend")
