"""Machu Picchu — PADUREA DE NORI SI TABARA (plansa de inventar, randurile 9 si 10).

  machupicchu/plants/polylepis_a.glb      quenual de 4 m, trunchi rasucit
  machupicchu/plants/polylepis_b.glb      quenual de 7 m, doua trunchiuri din aceeasi baza
  machupicchu/plants/tree_fern.glb        feriga arborescenta, 4 m, 8 frunze in evantai
  machupicchu/plants/bromeliad.glb        rozeta de 0.6 m (se aseaza inclinat pe pereti)
  machupicchu/plants/orchid_cluster.glb   0.4 m, 5 flori pe tije — singura planta saturata
  machupicchu/plants/bamboo_clump.glb     tufa de 5 m, 7-9 tulpini
  machupicchu/rocks/moss_boulder_a.glb    bolovan cu muschi, 1 m
  machupicchu/rocks/moss_boulder_b.glb    ... 2.5 m
  machupicchu/rocks/moss_boulder_c.glb    ... 4 m
  machupicchu/props/tent_a.glb            cort dom 2.2 x 2.2 x 1.4, TILE_TERRACOTTA
  machupicchu/props/tent_b.glb            idem, CACTUS_GREEN
  machupicchu/props/backpack_pile.glb     gramada de 4 rucsacuri, 1.0 x 0.8 x 0.7

VOLUM, NU FETE PLATE. Regula care conduce tot fisierul: o frunza dintr-un
singur strat de fete DISPARE la backface culling cand masina trece pe sub ea.
Deci frunzele sunt `leaf_vfold` (doua lamele cu grosime, pliate in V) si
coroanele sunt bulgari turtiti (`boulder`), niciodata planuri. Umbra e
identitate — un volum inchis arunca umbra de coroana, o placa arunca umbra de
linie.

BUGETUL E UN PLAFON, NU O TINTA. Lectia valului 1 (huayna_picchu a iesit con
neted la 522/2500 si a trebuit refacut): o piesa la 20% din buget care arata
neteda nu e eficienta, e forma lipsa. Piesele de aici stau langa drum in
padurea de nori (POI D/E/F), deci se judeca de la 3-4 m, nu ca siluete.

Sloturi (brief §0.4, zero sloturi noi): scoarta de quenual LARCH_RUST, frunzis
TROPICAL_GREEN, varfuri si muschi CACTUS_GREEN, umbra adanca / trunchi de
feriga LOG_DARK, noduri de bambus DRY_VEGETATION, roca MARBLE_GREY /
ROCK_LIGHT, placi de scoarta ROCK_DARK, cort TILE_TERRACOTTA, rucsacuri
PAINTED / RUST / LOG_DARK / CACTUS_GREEN. FLAMINGO_PINK (31) DOAR pe orhidee —
e ultima rezerva din atlas si verify o cere declarata cu `--allow-slots=31`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_machupicchu_forest.py
"""

import math
from mathutils import Matrix, Vector

# `dist` e raza de raycast si se scaleaza CU PIESA: pe o rozeta de 0.6 m o
# distanta de 3 m n-ar gasi nimic de ocluzat si AO-ul ar iesi constant 1.0,
# adica exact "prop-ul plat" din docs/blender_export.md §2.
AO_TREE = dict(samples=16, dist=4.0, gradient="vertical",
               low=0.40, high=1.00, power=0.85, floor=0.16)
AO_CLUMP = dict(samples=16, dist=3.0, gradient="vertical",
                low=0.44, high=1.00, power=0.85, floor=0.18)
AO_ROCK = dict(samples=22, dist=3.0, gradient="vertical",
               low=0.44, high=1.00, power=0.88, floor=0.16)
AO_SMALL = dict(samples=22, dist=1.0, gradient="vertical",
                low=0.50, high=1.00, power=0.90, floor=0.22)
AO_PROP = dict(samples=20, dist=1.6, gradient="vertical",
               low=0.48, high=1.00, power=0.90, floor=0.18)

BARK = LARCH_RUST            # scoarta rosie de quenual (semnatura speciei)
BARK_PEEL = ROCK_DARK        # foile de scoarta desprinse, in umbra
LEAF = TROPICAL_GREEN        # frunzis de padure de nori
LEAF_TIP = CACTUS_GREEN      # varfuri decolorate, muschi
TRUNK_DARK = LOG_DARK        # trunchi fibros de feriga, umbra adanca
NODE = DRY_VEGETATION        # nodurile de bambus
ROCK_PALE = MARBLE_GREY      # granit in soare
ROCK_MID = ROCK_LIGHT        # granit in umbra
MOSS = CACTUS_GREEN
ORCHID = 31                  # FLAMINGO_PINK — exceptie declarata, doar aici
CANVAS_A = TILE_TERRACOTTA   # panza de cort portocalie
CANVAS_B = CACTUS_GREEN      # ... si verde
ZIP = LOG_DARK               # fermoarul, ca linie inchisa
PACK_SLOTS = (PAINTED, RUST, LOG_DARK, CACTUS_GREEN)


# --- polylepis (quenual) -----------------------------------------------------
#
# Specia se recunoaste dupa DOUA lucruri, si amandoua sunt geometrie, nu
# culoare: trunchiul RASUCIT (nu un stalp drept) si scoarta care se desprinde
# in foi. Un `taper_sweep` pe o cale sinuoasa da primul; niste placi subtiri
# lipite tangential dau al doilea.
#
# Coroana e din bulgari TURTITI: un elipsoid rotund ar fi un stejar. Quenualul
# de altitudine are coroana marunta si neregulata, asezata in cateva mase.

def _twisted_trunk(b, base, height, r_base, r_top, seed, lean=0.35,
                   segments=7, slot=BARK):
    """Trunchi care se rasuceste: o cale sinuoasa in XY, nu un stalp.

    Intoarce punctele de pe axa, ca ramurile si coroana sa plece de pe ele.
    Rasucirea se face cu un unghi care AVANSEAZA cu cota (nu cu zgomot pur):
    asa iese o spirala lenta, care e exact cum creste quenualul batut de vant,
    in loc de un trunchi care serpuieste aleator.
    """
    rand = _lcg(seed)
    n = 5
    a0 = rand() * 6.28
    pts, radii = [], []
    for i in range(n):
        t = i / float(n - 1)
        # spirala: unghiul avanseaza constant, raza creste cu cota
        a = a0 + t * 2.6
        r = lean * height * 0.11 * (t ** 1.2)
        pts.append(Vector((base[0] + math.cos(a) * r,
                           base[1] + math.sin(a) * r,
                           base[2] + height * t)))
        radii.append(r_base + (r_top - r_base) * (t ** 0.85))
    b.taper_sweep(pts, radii, slot, segments=segments)
    return pts


def _bark_peels(b, axis, count, seed, width=0.18, slot=BARK_PEEL):
    """Foi de scoarta desprinse: placi subtiri, tangente la trunchi, cu capatul
    de jos departat de el.

    Sunt semnatura quenualului. Se fac cu `blade` (lamela cu GROSIME), nu cu
    plane: o foaie de scoarta e vazuta si din spate cand treci pe langa copac,
    iar un plan ar disparea la culling.
    """
    rand = _lcg(seed)
    for k in range(count):
        t = 0.18 + 0.62 * (k / max(count - 1.0, 1.0)) + rand() * 0.08
        i = min(int(t * (len(axis) - 1)), len(axis) - 2)
        f = t * (len(axis) - 1) - i
        p = axis[i].lerp(axis[i + 1], f)
        a = rand() * 6.28
        d = Vector((math.cos(a), math.sin(a), 0.0))
        h = 0.55 + rand() * 0.55
        # Foaia pleaca lipita de trunchi si se DESPRINDE in jos: capatul de jos
        # iese in afara cu cativa centimetri. Asta e ce citeste ca scoarta care
        # se cojeste, nu ca o aripioara lipita.
        #
        # Desprinderea e MARE (0.34 la capat, nu 0.22) si foaia mai lunga:
        # masurat pe plansa, la 0.22 m foile nu se distingeau deloc de trunchi
        # — costau triunghiuri fara sa aduca semnatura speciei. Daca un detaliu
        # nu se vede, ori se mareste pana se vede, ori se scoate.
        path = [p + d * 0.05, p + d * 0.14 - Vector((0, 0, h * 0.55)),
                p + d * 0.34 - Vector((0, 0, h))]
        b.blade(path, [width * 0.8, width * 1.25, width * 0.6], 0.03, slot,
                up=d.cross(Vector((0, 0, 1))))


def _crown_mass(b, center, radius, lumps, seed, squash=0.95):
    """Coroana: bulgari cu centrele DECALATE (nu coaxiale).

    Uniformitatea rotationala citeste a plastic (lectia valului 1), deci
    fiecare bulgare isi are unghiul, raza si marimea lui, iar unul din trei ia
    slotul de varf decolorat.

    `squash` e aproape 1 DELIBERAT, si e diferenta dintre quenual si acacie.
    Prima versiune folosea 0.55 (bulgari turtiti, reteta acaciei de la
    Serengeti) si in plansa quenualul iesea leit o acacie-umbrela: coroana
    plata, lata, asezata sus pe un trunchi gol. Quenualul de altitudine are
    coroana NEREGULATA si ADUNATA — o masa aproape sferica, spartita in
    cateva bucati de marimi diferite. Turtirea e ce face umbrela, deci se
    scoate.
    """
    rand = _lcg(seed)
    for k in range(lumps):
        a = 2.0 * math.pi * k / lumps + rand() * 0.8
        r = 0.0 if k == 0 else radius * (0.42 + rand() * 0.42)
        # marimi mult mai INEGALE intre bulgari (0.45..1.05 din raza): o
        # coroana din bucati egale citeste ca un ciorchine de bile
        size = radius * (0.82 if k == 0 else 0.45 + rand() * 0.60)
        z = center[2] + (rand() - 0.5) * radius * 0.80
        slot = LEAF_TIP if k % 3 == 2 else LEAF
        b.boulder((center[0] + math.cos(a) * r, center[1] + math.sin(a) * r, z),
                  (size, size * (0.82 + rand() * 0.24), size * squash), slot,
                  seed=seed + k * 13, segments=6, rings=3, deviation=0.17)


def _polylepis_branches(b, top, height, count, seed, radius):
    """Ramurile: pleaca din varful trunchiului si urca in afara, cu o
    ramificatie pe fiecare. Fara ele coroana pluteste peste un bat."""
    rand = _lcg(seed)
    for k in range(count):
        a = 2.0 * math.pi * k / count + rand() * 0.7
        d = Vector((math.cos(a), math.sin(a), 0.0))
        L = radius * (0.72 + rand() * 0.5)
        mid = top + d * (L * 0.45) + Vector((0, 0, height * 0.07))
        tip = top + d * L + Vector((0, 0, height * 0.12 + rand() * height * 0.05))
        b.taper_sweep([top, mid, tip],
                      [height * 0.022, height * 0.014, height * 0.006],
                      BARK, segments=5)
        # o ramificatie scurta pe fiecare ramura: densitatea e ce face coroana
        # sa nu citeasca a umbrela de sarma
        a2 = a + (rand() - 0.5) * 1.4
        d2 = Vector((math.cos(a2), math.sin(a2), 0.0))
        b.taper_sweep([mid, mid + d2 * (L * 0.38) + Vector((0, 0, L * 0.30))],
                      [height * 0.012, height * 0.004], BARK, segments=4)


def build_polylepis(variant):
    """`a` = 4 m, un trunchi. `b` = 7 m, DOUA trunchiuri din aceeasi baza."""
    b = Builder()
    if variant == 0:
        H = 4.0
        axis = _twisted_trunk(b, (0.0, 0.0, 0.0), H * 0.62, 0.17, 0.09,
                              seed=3101, lean=0.42)
        _bark_peels(b, axis, 3, seed=3111)
        _polylepis_branches(b, axis[-1], H, 4, 3121, H * 0.30)
        # Coroana coboara la 0.76 din inaltime si e mai lata: la 0.84 statea ca
        # o palarie deasupra unui bat (silueta de acacie). Quenualul are
        # coroana care INCEPE aproape de varful trunchiului si inghite
        # ramurile.
        _crown_mass(b, (axis[-1].x, axis[-1].y, H * 0.76), H * 0.38, 6, 3131)
        # radacini la baza: quenualul creste pe stanca, cu radacini la vedere
        rnd = _lcg(3141)
        for k in range(4):
            a = 2.0 * math.pi * k / 4 + rnd() * 0.6
            d = Vector((math.cos(a), math.sin(a), 0.0))
            b.taper_sweep([Vector((0, 0, 0.30)), d * 0.22 + Vector((0, 0, 0.12)),
                           d * 0.42 + Vector((0, 0, 0.0))],
                          [0.09, 0.06, 0.02], BARK, segments=5)
        name = "Polylepis_A"
    else:
        H = 7.0
        # Doua trunchiuri din ACEEASI baza: pleaca amandoua din origine si se
        # departeaza cu cota. E ce cere brief-ul si e si silueta reala a
        # quenualului batran (creste in tufa, nu cu un singur fus).
        tops = []
        for k, (dx, dy, h, seed) in enumerate(
                ((0.0, 0.0, H * 0.60, 3201), (0.34, 0.16, H * 0.50, 3211))):
            axis = _twisted_trunk(b, (dx * 0.25, dy * 0.25, 0.0), h,
                                  0.21 - k * 0.04, 0.10 - k * 0.02,
                                  seed=seed, lean=0.55 + k * 0.3)
            _bark_peels(b, axis, 3 if k == 0 else 2, seed=seed + 7)
            tops.append((axis[-1], h))
        for k, (top, h) in enumerate(tops):
            _polylepis_branches(b, top, H, 4, 3221 + k * 17, H * 0.26)
            _crown_mass(b, (top.x, top.y, h + H * 0.12), H * 0.30, 6,
                        3241 + k * 23)
        rnd = _lcg(3261)
        for k in range(5):
            a = 2.0 * math.pi * k / 5 + rnd() * 0.6
            d = Vector((math.cos(a), math.sin(a), 0.0))
            b.taper_sweep([Vector((0, 0, 0.42)), d * 0.30 + Vector((0, 0, 0.16)),
                           d * 0.58 + Vector((0, 0, 0.0))],
                          [0.11, 0.07, 0.02], BARK, segments=5)
        name = "Polylepis_B"
    return b.to_object(name)


# --- tree_fern ---------------------------------------------------------------
#
# Feriga arborescenta: trunchi FIBROS (nu neted — e un manunchi de radacini
# aeriene) si 8 frunze intr-un evantai care se desface din varf.
#
# Frunzele sunt `leaf_vfold`: pliul in V le da volum de la distanta si le tine
# vizibile cand treci pe SUB ele. O frunza plata ar fi o scandura verde.

def build_tree_fern():
    b = Builder()
    H = 4.0
    trunk_h = H * 0.68
    # trunchiul: usor conic, cu solzi (bazele frunzelor cazute) pe el
    b.taper_sweep([(0.0, 0.0, 0.0), (0.03, 0.02, trunk_h * 0.5),
                   (0.05, 0.03, trunk_h)],
                  [0.22, 0.18, 0.15], TRUNK_DARK, segments=8)
    # Solzii: inele scurte de cutii mici, in spirala pe trunchi. Sunt ce
    # deosebeste un trunchi de feriga de un stalp — si costa foarte putin.
    rnd = _lcg(3301)
    for i in range(9):
        t = 0.10 + 0.82 * (i / 8.0)
        z = trunk_h * t
        a = i * 2.4 + rnd() * 0.5
        r = 0.16 - t * 0.02
        for k in range(3):
            aa = a + k * 2.09
            b.box((math.cos(aa) * r, math.sin(aa) * r, z),
                  (0.10, 0.10, 0.07), BARK_PEEL,
                  rotation=Matrix.Rotation(aa, 3, "Z"))
    top = Vector((0.05, 0.03, trunk_h))
    # 8 frunze in evantai. `rise` le ridica intai, `droop` le lasa la varf:
    # profilul de fronda care se arcuieste, nu de tepusa.
    # stations=3: masurat, o fronda costa 40 tri brut la 3 statii fata de 72 la
    # 5, iar arcuirea se citeste la fel la 4 m. Diferenta se vede doar in
    # numarator.
    for k in range(8):
        a = 360.0 * k / 8.0 + rnd() * 16.0
        leaf_vfold(b, top, a, H * 0.52, 0.42, H * 0.20, LEAF,
                   fold_deg=30.0, stations=3, thick=0.03, droop=0.30)
    # cateva frunze tinere, mai scurte si mai deschise, in mijloc
    for k in range(2):
        a = 360.0 * k / 2.0 + 40.0
        leaf_vfold(b, top + Vector((0, 0, 0.10)), a, H * 0.26, 0.24,
                   H * 0.14, LEAF_TIP, fold_deg=34.0, stations=3,
                   thick=0.025, droop=0.22)
    return b.to_object("Tree_Fern")


# --- bromeliad ---------------------------------------------------------------
#
# Rozeta de 0.6 m care se aseaza INCLINAT pe pereti stancosi la integrare.
# Deci trebuie sa arate bine din orice unghi, inclusiv de dedesubt: frunzele
# sunt lamele cu grosime, dispuse pe o semisfera, nu pe un disc.

def build_bromeliad():
    b = Builder()
    rnd = _lcg(3401)
    R = 0.30
    # Doua etaje de frunze: cele de jos aproape orizontale si lasate, cele de
    # sus ridicate. Asa iese PALNIA de bromelie (aduna apa), nu o stea plata.
    #
    # stations=3 si mai putine frunze: piesa are 0.6 m si sta pe un perete
    # stancos. La marimea asta o frunza in plus nu se distinge, dar costa
    # 40 de triunghiuri brute (masurat) — si bugetul e 200.
    # 4 + 2 frunze: bugetul e 200 si o frunza costa 40 brut. Rozeta se
    # recunoaste din PALNIE (doua etaje, unul lasat, unul ridicat), nu din
    # numarul de frunze — la 0.6 m, a cincea si a sasea frunza de jos cad
    # exact peste siluetele celorlalte.
    for k in range(4):
        a = 360.0 * k / 4.0 + rnd() * 12.0
        leaf_vfold(b, (0.0, 0.0, 0.05), a, R * 1.5, 0.17, 0.10, LEAF,
                   fold_deg=32.0, stations=3, thick=0.022, droop=0.45)
    for k in range(2):
        a = 360.0 * k / 2.0 + 45.0 + rnd() * 10.0
        leaf_vfold(b, (0.0, 0.0, 0.12), a, R * 1.05, 0.13, 0.22, LEAF_TIP,
                   fold_deg=26.0, stations=3, thick=0.020, droop=0.12)
    # Inima rozetei: 3 laturi ajung. Conul e in mijlocul palniei, inconjurat de
    # frunze — se vede doar ca o pata mai inchisa, nu ca o silueta.
    b.frustum((0.0, 0.0, 0.10), 0.09, 0.03, 0.18, LEAF_TIP, segments=3)
    return b.to_object("Bromeliad")


# --- orchid_cluster ----------------------------------------------------------
#
# SINGURA planta saturata din pista. 5 flori pe tije, FLAMINGO_PINK (31).
# Slotul 31 e ultima rezerva din atlas si se randeaza magenta daca nu e
# declarat — de-aia verify il cere cu `--allow-slots=31`.

def build_orchid_cluster():
    b = Builder()
    rnd = _lcg(3501)
    # frunze bazale: scurte, late, TROPICAL_GREEN
    for k in range(2):
        a = 360.0 * k / 2.0 + rnd() * 20.0
        leaf_vfold(b, (0.0, 0.0, 0.02), a, 0.17, 0.08, 0.05, LEAF,
                   fold_deg=28.0, stations=3, thick=0.014, droop=0.35)
    for k in range(5):
        a = 2.0 * math.pi * k / 5 + rnd() * 0.7
        d = Vector((math.cos(a), math.sin(a), 0.0))
        h = 0.24 + rnd() * 0.13
        r = 0.05 + rnd() * 0.07
        # tija: se arcuieste in afara, floarea atarna la capat. 3 laturi: la
        # 1.2 cm diametru, a patra latura e sub un pixel la orice distanta.
        tip = d * r + Vector((0, 0, h))
        b.taper_sweep([Vector((0, 0, 0.03)), d * (r * 0.5) + Vector((0, 0, h * 0.62)),
                       tip], [0.012, 0.010, 0.007], LEAF, segments=3)
        # Floarea: DOUA petale ca lamele + un labelum-bulgare. Brief-ul cere
        # "5 flori pe tije" — numarul de FLORI e contractul, nu numarul de
        # petale per floare. La 0.4 m si buget 200, a treia petala costa 40 de
        # triunghiuri brute si nu se distinge de celelalte doua.
        # O petala-lamela + labelumul. Cele DOUA petale costau 80 de
        # triunghiuri per floare, adica 400 pe piesa, din bugetul de 200.
        # Ce face floarea sa se vada la 0.4 m e PATA de culoare saturata
        # (singura de pe pista), nu numarul de petale.
        leaf_vfold(b, tip, math.degrees(a) + rnd() * 14.0, 0.085, 0.065, 0.012,
                   ORCHID, fold_deg=20.0, stations=3, thick=0.010, droop=0.22)
        # labelumul: o cutie mica, nu un `boulder`. La 4 cm, un elipsoid de 4x2
        # costa 16 triunghiuri si arata identic cu o cutie de 12 — iar bugetul
        # de 200 se decide pe zeci, nu pe sute.
        b.box(tuple(tip), (0.044, 0.044, 0.034), ORCHID,
              rotation=Matrix.Rotation(a, 3, "Z"))
    return b.to_object("Orchid_Cluster")


# --- bamboo_clump ------------------------------------------------------------
#
# 7-9 tulpini de 5 m cu noduri. Nodurile sunt inele scurte de alt slot pe
# tulpina — cost zero in triunghiuri fata de tulpina simpla, si sunt exact
# genul de detaliu care nu poate veni din textura (UV-urile sunt colapsate).
# Aceeasi reteta ca dungile de mesteacan de la Baikal.

def build_bamboo_clump():
    b = Builder()
    rnd = _lcg(3601)
    # 7 tulpini (brief: 7-9) cu 5 laturi in loc de 6, si mai putine noduri: la
    # 8 tulpini x 6 laturi x 5 noduri tufa costa 2056 din 600. Numarul de
    # TULPINI e ce citeste ca bambus, deci el se pastreaza la minimul din
    # brief; laturile si nodurile, care nu se vad la 3 m, platesc.
    culms = 7
    # Nodurile se fac cu `box` rotit, nu cu `cylinder`: la 5 cm inaltime si
    # 5 laturi un cilindru costa 15 triunghiuri (2 capace ngon + laterale), o
    # cutie 12, si la 4 cm diametru niciunul nu se vede ca altceva decat un
    # inel mai inchis. Pe 7 tulpini x 3-4 noduri diferenta conteaza.
    for k in range(culms):
        a = 2.0 * math.pi * k / culms + rnd() * 0.8
        r = 0.10 + rnd() * 0.38
        base = Vector((math.cos(a) * r, math.sin(a) * r, 0.0))
        H = 3.4 + rnd() * 1.6
        # tulpinile se departeaza de centru cu cota (tufa se desface in evantai)
        lean = 0.10 + rnd() * 0.16
        d = Vector((math.cos(a), math.sin(a), 0.0))
        rad = 0.045 + rnd() * 0.022
        pts = [base, base + d * (H * lean * 0.4) + Vector((0, 0, H * 0.5)),
               base + d * (H * lean) + Vector((0, 0, H))]
        b.taper_sweep(pts, [rad, rad * 0.86, rad * 0.62], LEAF, segments=5)
        # nodurile: inele turtite, la pas mai mare (1.15 m in loc de 0.62)
        nodes = int(H / 1.15)
        for i in range(1, nodes):
            t = i / float(nodes)
            p = base + d * (H * lean * t * t) + Vector((0, 0, H * t))
            rr = rad * (1.0 - 0.38 * t) * 1.16
            b.box((p.x, p.y, p.z), (rr * 2.0, rr * 2.0, 0.05), NODE,
                  rotation=Matrix.Rotation(a, 3, "Z"))
        # doua frunze in treimea de sus (a treia nu se distingea)
        for j in range(2):
            t = 0.66 + 0.26 * j
            p = base + d * (H * lean * t * t) + Vector((0, 0, H * t))
            aa = math.degrees(a) + 120.0 * j + rnd() * 50.0
            leaf_vfold(b, p, aa, 0.52, 0.09, 0.10, LEAF_TIP,
                       fold_deg=22.0, stations=3, thick=0.012, droop=0.42)
    return b.to_object("Bamboo_Clump")


# --- moss_boulder ------------------------------------------------------------
#
# `boulder()` (elipsoid inchis), cu fetele de SUS retag CACTUS_GREEN. Retag
# costa ZERO triunghiuri: muschiul e variatie de valoare, nu geometrie.
#
# `deviation` se tine moderat — style_bible §3 cere stanci rotunjite sau
# fatetate, niciodata zimtate.

def build_moss_boulder(variant):
    b = Builder()
    size = (1.0, 2.5, 4.0)[variant]
    seed = 3701 + variant * 31
    rnd = _lcg(seed)
    # Corpul principal: putine segmente = fatete LATE, care e ce cere granitul.
    # 6 laturi pe varianta mica (buget 200), 7 pe celelalte: la 1 m diametru o
    # latura in plus e sub un grad de arc din masina, dar costa 8 triunghiuri
    # dupa bevel.
    faces = b.boulder((0.0, 0.0, size * 0.42),
                      (size, size * (0.80 + rnd() * 0.16), size * 0.80),
                      ROCK_PALE, seed=seed, segments=6 if variant == 0 else 7,
                      rings=3, deviation=0.17,
                      strata_slots=(ROCK_PALE, ROCK_MID, ROCK_PALE, ROCK_MID))
    # Muschiul: fetele orientate in SUS. Pragul e generos (0.30) ca sa prinda si
    # umerii, nu doar capacul — muschiul creste pe orice fata care aduna apa.
    # Astea sunt retag, deci costa ZERO triunghiuri: muschiul e in primul rand
    # o problema de VALOARE, si abia in al doilea de volum.
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.30)
    # A doua masa, mai mica, lipita lateral: rupe silueta de ou. Fara ea un
    # `boulder` unic citeste a cartof, oricat de perturbat.
    # A doua masa, ADANC infipta in corp (nu lipita pe flanc): la 0.34 din
    # marime iesea un nod separat, cu o crestatura vizibila la imbinare. La
    # 0.22 se intrepatrunde si citeste ca un umar al aceleiasi stanci.
    sub = b.boulder((size * 0.22, size * 0.12, size * 0.30),
                    (size * 0.56, size * 0.50, size * 0.44), ROCK_MID,
                    seed=seed + 11, segments=5, rings=3, deviation=0.18)
    b.retag(sub, MOSS, where=lambda c, n: n.z > 0.40)
    # Pietrele de la baza s-au SCOS.
    #
    # Rostul lor era sa ascunda linia unde bolovanul intra in teren. Pe plansa
    # insa, o singura piatra de 5 laturi langa un corp de 7 citea ca o cutie
    # agatata de flanc — atragea privirea exact pe imbinarea pe care trebuia
    # s-o ascunda. Linia de contact o ascunde oricum terenul la integrare
    # (bolovanii se aseaza ingropati partial), deci piesele astea plateau
    # triunghiuri ca sa STRICE silueta.
    #
    # Fara ele bolovanii intra si in buget: 200/250/300 nu incap trei corpuri.
    # Muschiul ramane pur RETAG (mai sus): variatie de valoare pe fetele care
    # aduna apa, zero triunghiuri, exact ce cere brief-ul la litera ("fetele
    # de SUS retag CACTUS_GREEN").
    #
    # Doua incercari cu volum, amandoua vazute in plansa si amandoua gresite:
    # bulgari separati pe capac citeau ca PIETRICELE lipite deasupra, iar o
    # calota turtita citea ca un CAPAC neted cusut peste o stanca fatetata.
    # Cauza e aceeasi: orice corp inchis pus langa o stanca are silueta proprie
    # si arata tot a stanca.
    #
    # ATENTIE la limita masuratorii: plansa de control randeaza GRI (vezi nota
    # din raport — materialul de atlas nu se leaga in preview), deci pe ea
    # muschiul-retag e INVIZIBIL prin constructie. Judecata "muschiul se vede?"
    # nu poate fi data din harnasamentul asta; se da la integrare, in Godot,
    # unde slotul isi ia culoarea din atlas. Ce se poate judeca aici — si s-a
    # judecat — e SILUETA, iar silueta spune ca volumele de muschi erau gresite.
    return b.to_object("Moss_Boulder_" + "ABC"[variant])


# --- corturi -----------------------------------------------------------------
#
# Cort DOM 2.2 x 2.2 x 1.4: mai LAT decat inalt, spre deosebire de piramida de
# pescuit de la Baikal (1.8 m inalt pe 2.1 m baza). Deci profilul e bombat, nu
# drept, si se face cu `revolve` pe un profil convex cu mai multe segmente.
#
# Rotit cu jumatate de pas ca spre camera sa vina o MUCHIE, nu o fata plata —
# trucul din build_baikal_ice.py, si din acelasi motiv.

def build_tent(variant):
    b = Builder()
    slot = (CANVAS_A, CANVAS_B)[variant]
    seed = 3801 + variant * 17
    rnd = _lcg(seed)
    H = 1.4
    half = 1.10
    segments = 7
    # Profilul unui dom: raza scade LENT la inceput si repede spre varf. Un
    # profil liniar ar da un con, adica un cort de circ.
    prof = []
    for i in range(5):
        t = i / 4.0
        r = half * math.cos(t * math.pi * 0.5) ** 0.72
        prof.append((r if i < 4 else 0.0, H * t))
    faces = b.revolve(prof, slot, segments=segments)
    # jumatate de pas de rotatie: o muchie spre camera
    ang = math.pi / segments
    ca, sa = math.cos(ang), math.sin(ang)
    for v in {v for f in faces for v in f.verts}:
        x, y = v.co.x, v.co.y
        v.co.x = x * ca - y * sa
        v.co.y = x * sa + y * ca
    # Fermoarul: o linie LOG_DARK care urmeaza panta panzei pe fata +Y. Doua
    # segmente, ca sa urmeze bombarea in loc s-o taie ca o coarda.
    for (z0, z1, r0, r1) in ((0.02, H * 0.46, half * 0.99, half * 0.80),
                             (H * 0.46, H * 0.86, half * 0.80, half * 0.34)):
        b.beam((0.0, r0, z0), (0.0, r1, z1), (0.05, 0.035), ZIP)
    # a doua cusatura, laterala, ca panza sa nu fie o suprafata goala
    b.beam((-half * 0.62, half * 0.42, 0.02), (-half * 0.20, half * 0.16, H * 0.72),
           (0.04, 0.03), ZIP)
    # Absida/tinda: un mic volum in fata, care da cortului DIRECTIE. Fara el
    # domul e rotational si citeste ca o caciula.
    b.revolve([(0.44, 0.0), (0.38, 0.22), (0.20, 0.40), (0.0, 0.48)],
              slot, segments=6, origin=(0.0, half * 0.74, 0.0))
    # tarusii si corzile de ancorare
    for k in range(4):
        a = math.radians(45.0 + k * 90.0)
        px, py = math.cos(a) * half * 1.24, math.sin(a) * half * 1.24
        b.beam((px, py, 0.0), (px * 0.94, py * 0.94, 0.16), 0.03, ZIP)
        # coarda: de la tarus la umarul cortului
        b.taper_sweep([Vector((px, py, 0.13)),
                       Vector((px * 0.50, py * 0.50, H * 0.62))],
                      [0.012, 0.010], NODE, segments=4)
    # o cuta de panza pe o latura (uzura, style_bible §4)
    b.boulder((half * 0.52 * rnd(), -half * 0.58, H * 0.30),
              (0.34, 0.16, 0.30), slot, seed=seed + 5, segments=6, rings=3,
              deviation=0.16)
    return b.to_object("Tent_" + "AB"[variant])


# --- backpack_pile -----------------------------------------------------------
#
# Gramada de 1.0 x 0.8 x 0.7 cu 4 rucsacuri, in patru sloturi diferite (fara
# CAR_*: sloturile 14-16 raman ale masinilor, style_bible §1).
#
# Un rucsac e un volum MOALE: `boulder` turtit, nu o cutie. Ce il face sa
# citeasca "rucsac" si nu "bolovan colorat" sunt cele trei detalii de deasupra
# — capacul, bretelele si buzunarul frontal — toate cutii mici.

def _backpack(b, center, size, slot, rot_deg, seed):
    rnd = _lcg(seed)
    rot = Matrix.Rotation(math.radians(rot_deg), 3, "Z")
    w, d, h = size

    def place(local, sz, s, extra_rot=None):
        p = rot @ Vector(local)
        r = rot if extra_rot is None else rot @ extra_rot
        return b.box((center[0] + p.x, center[1] + p.y, center[2] + p.z),
                     sz, s, rotation=r)

    # corpul: bulgare turtit, cu deviatie mica (panza plina, nu piatra)
    body = b.boulder(center, (w, d, h), slot, seed=seed, segments=6, rings=3,
                     deviation=0.11)
    _ = body
    # capacul de sus, putin mai inchis
    place((0.0, -d * 0.06, h * 0.40), (w * 0.82, d * 0.72, h * 0.22), ZIP,
          extra_rot=Matrix.Rotation(math.radians(-8.0), 3, "X"))
    # buzunarul frontal
    place((0.0, d * 0.44, -h * 0.06), (w * 0.60, d * 0.22, h * 0.40), slot)
    # O chinga orizontala. Bretelele de spate si manerul au fost SCOASE: la
    # 1 m gramada si buget 400, fiecare cutie costa ~44 de triunghiuri dupa
    # bevel si niciuna nu se distingea in plansa. Ce citeste un rucsac de la
    # 3 m e corpul moale + capacul + buzunarul, nu chingile.
    place((0.0, 0.0, -h * 0.22), (w * 1.02, d * 1.02, h * 0.10), ZIP)
    _ = rnd


def build_backpack_pile():
    """4 rucsacuri intr-o gramada de 1.0 x 0.8 x 0.7.

    Asezarea e piramidala: trei jos, unul culcat deasupra. O gramada in care
    toate stau in picioare citeste a raft, nu a bagaje trantite la gara.

    Rucsacii sunt SEPARATI si mai mari decat in prima versiune: in plansa,
    patru volume mici, apropiate si cu detalii marunte pe ele citeau ca un
    morman de cutii nedefinite. La 1 m gramada, ce trebuie sa se vada e
    silueta a patru corpuri distincte, nu bretelele fiecaruia.
    """
    b = Builder()
    # cei trei de jos, rezemati unul de altul si CLAR despartiti
    _backpack(b, (-0.30, -0.12, 0.25), (0.40, 0.28, 0.48), PACK_SLOTS[0],
              rot_deg=-18.0, seed=3901)
    _backpack(b, (0.12, 0.10, 0.27), (0.42, 0.30, 0.50), PACK_SLOTS[1],
              rot_deg=26.0, seed=3911)
    _backpack(b, (0.38, -0.18, 0.23), (0.38, 0.26, 0.44), PACK_SLOTS[3],
              rot_deg=-44.0, seed=3921)
    # al patrulea CULCAT deasupra: rotit pe X, deci inaltimea lui devine
    # adancime. Asta e ce plafoneaza gramada la 0.7 m.
    b4 = Builder()
    _backpack(b4, (0.0, 0.0, 0.0), (0.34, 0.24, 0.42), PACK_SLOTS[2],
              rot_deg=8.0, seed=3931)
    tmp = b4.to_object("_PackTmp")
    # transferul se face prin geometrie, nu prin re-desenare: rotim mesh-ul
    # temporar si il alipim. `boulder`-ul culcat isi pastreaza detaliile.
    rot = Matrix.Rotation(math.radians(76.0), 4, "X")
    tmp.data.transform(rot)
    tmp.data.transform(Matrix.Translation(Vector((0.02, 0.06, 0.56))))
    bm_tmp = bmesh.new()
    bm_tmp.from_mesh(tmp.data)
    slot_layer = bm_tmp.faces.layers.int.get("slot")
    for f in bm_tmp.faces:
        verts = [b.bm.verts.new(v.co) for v in f.verts]
        nf = b.bm.faces.new(verts)
        nf[b.slot] = f[slot_layer] if slot_layer else PACK_SLOTS[2]
    bm_tmp.free()
    bpy.data.objects.remove(tmp, do_unlink=True)
    return b.to_object("Backpack_Pile")


# --- emit --------------------------------------------------------------------

clear_built()
results = []


def emit(obj, path, ao, origin="base", bevel=0.03, smooth_angle=55.0,
         tint=None):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin,
                smooth_angle=smooth_angle)
    # Gradientul de nuanta se pune DUPA finish: bake_ao sterge atributele de
    # culoare, deci ordinea e o constrangere, nu o preferinta (dio_lib:1777).
    if tint is not None:
        tint_gradient(obj, base=tint[0], tip=tint[1])
    _, sz = export_glb([obj], "machupicchu/" + path)
    results.append((path, st["tris"], sz / 1024.0, st["ao_min"], st["ao_max"]))
    return obj


built = []
# Vegetatia primeste tint_gradient: baza spre umbra rece, varfurile aproape de
# culoarea slotului. Fara el masa verde e plata si padurea citeste ca fetru.
LEAF_TINT = ((0.52, 0.60, 0.50), (1.06, 1.02, 0.84))

# BEVEL-UL E PARGHIA PRINCIPALA DE COST, si asta s-a MASURAT, nu presupus:
# o frunza `leaf_vfold` costa 40 de triunghiuri brute si 128 dupa un bevel de
# 2 cm (x3.2); un `boulder` 6x3 costa 36 brut si 132 dupa bevel (x3.67).
#
# Pe piesele MARI bevel-ul isi merita banii: el da muchia care prinde lumina,
# fara care stanca citeste ca o cutie. Pe o orhidee de 40 cm sau o bromelie de
# 60 cm, o tesitura de 6 mm nu se vede de la nicio distanta la care piesa
# apare pe ecran — dar tripleaza factura. Deci: zero bevel pe piesele marunte,
# bevel mic pe cele medii, bevel intreg doar pe roci.
#
# Alternativa (mai putine frunze) ar fi platit aceeasi factura din SILUETA,
# adica exact ce nu avem voie sa cedam.
built.append(emit(build_polylepis(0), "plants/polylepis_a.glb", AO_TREE,
                  bevel=0.0, tint=LEAF_TINT))
built.append(emit(build_polylepis(1), "plants/polylepis_b.glb", AO_TREE,
                  bevel=0.0, tint=LEAF_TINT))
built.append(emit(build_tree_fern(), "plants/tree_fern.glb", AO_TREE,
                  bevel=0.0, tint=LEAF_TINT))
built.append(emit(build_bromeliad(), "plants/bromeliad.glb", AO_SMALL,
                  bevel=0.0, tint=LEAF_TINT))
# Orhideea NU primeste tint: `green_only` l-ar sari oricum pe petale, dar
# frunzele bazale ar inchide o piesa de 0.4 m care trebuie sa sara in ochi.
built.append(emit(build_orchid_cluster(), "plants/orchid_cluster.glb",
                  AO_SMALL, bevel=0.0))
built.append(emit(build_bamboo_clump(), "plants/bamboo_clump.glb", AO_CLUMP,
                  bevel=0.0, tint=LEAF_TINT))
# smooth_angle mic pe roci: fatetele trebuie sa ramana TAIOASE (lectia
# valului 1 — pragul implicit de 55° netezea stanca intr-o movila). Aici
# bevel-ul RAMANE: pe o stanca de 1-4 m muchia tesita e ce prinde soarele.
for v in range(3):
    built.append(emit(build_moss_boulder(v),
                      "rocks/moss_boulder_%s.glb" % "abc"[v], AO_ROCK,
                      bevel=0.03 + v * 0.015, smooth_angle=28.0))
for v in range(2):
    built.append(emit(build_tent(v), "props/tent_%s.glb" % "ab"[v], AO_PROP,
                      bevel=0.0))
built.append(emit(build_backpack_pile(), "props/backpack_pile.glb", AO_PROP,
                  bevel=0.0))

# .blend-ul ramane comun, cu piesele pe un rand ca sa fie lizibil.
x = 0.0
for o in built:
    o.location.x = x
    x += 6.0
print("BLEND: %s (%d B)" % save_blend(built, "machupicchu_forest.blend"))

print()
for path, tris, kb, ao_lo, ao_hi in results:
    print("%-44s tris=%6d %8.1f kB  AO %.2f..%.2f"
          % (path, tris, kb, ao_lo, ao_hi))
print("TOTAL padure+tabara: %d tris" % sum(t for _, t, _, _, _ in results))
