"""Ha Long, valul 3 — drum, vegetatie, repere, fundal, grota
(brief docs/asset_briefs/halong_kit.md §1.2, §1.5-§1.9).

  halong/structures/grotto_portal.glb       gura grotei, gol 9 x 7 m   (§1.2)
  halong/structures/coast_parapet.glb       parapet, modul 6 m         (§1.5)
  halong/structures/stone_dike.glb          dig, modul 8 m             (§1.5)
  halong/plants/karst_ficus_a.glb           ficus cu radacini aeriene  (§1.6)
  halong/plants/karst_ficus_b.glb           varianta, coroana deschisa (§1.6)
  halong/plants/bamboo_clump.glb            palc de bambus, 7 m        (§1.6)
  halong/plants/scrub_tuft.glb              tufa de creasta, 0,8 m     (§1.6)
  halong/structures/belvedere_pavilion.glb  pavilion de belvedere      (§1.7)
  halong/animals/macaque.glb                macac, doua poze, 0,5 m    (§1.8)
  halong/rocks/halong_horizon.glb           trei planuri de fundal     (§1.9)

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_halong_road.py

Variabila HL_ONLY=<piesa> reface doar piesa respectiva.

FUNDALUL: UN FISIER, TREI NODURI — corectie fata de brief §1.9
--------------------------------------------------------------
Brief-ul cere `karst_horizon_a/b/c.glb`, trei fisiere. Consumatorul nu le
poate folosi: `Track._build_horizon` incarca UN singur `horizon_model` per
tema si scoate din el cate un nod PE NUME, prin `_extract_glb_node` plus
steagul `horizon_picks` (track.gd:6251-6256). Trei fisiere ar insemna ca doua
nu s-ar incarca NICIODATA.
Verificat pe pistele care au deja fundal propriu: `fiordland_horizon.glb` are
4 noduri (FarWall_A/B, SnowRidge_A/B), si la fel kyoto/jodhpur. Deci: un
`halong_horizon.glb` cu `KarstRow_A/B/C`.
Asta e exact capcana din memoria `brief-cere-glb-cod-il-face-deja`, care a
costat 4 piese fara consumator pe Machu Picchu — se citeste CODUL, nu briful.

VEGETATIA: coroane RARE, nu brocoli
-----------------------------------
Brief §1.6 e explicit, cu precedent: la Fiordland planse dadeau brocoli si
kitul a impus altceva. Deci NU `foliage_column` (stalp dens de mase
elipsoidale), ci `leaf_vfold` — frunze individuale cu pliu in V, prin care se
vede cerul. Costa mai putin si se citeste ca ficus, nu ca minge verde.

GOLUL PORTALULUI se masoara pe GABARITUL CAROSERIEI, nu sub buiandrug
--------------------------------------------------------------------
Brief §1.2: contractul e >= 8 m liberi LA INALTIMEA DE 2,5 m, nu 9 m la baza.
O poarta trapezoidala care se strange poate fi mai ingusta decat pare la cota
masinii (memoria `golul-se-masoara-pe-fereastra-lui`). De aceea stalpii sunt
VERTICALI pe primii 3 m si se inclina abia deasupra.

SUPRAFETE PE CARE SE MERGE: varfuri partajate
---------------------------------------------
Pragul portalului, platforma pavilionului si coama digului sunt suprafete
carosabile sau calcabile. Pentru fizica intreaga un prag de 15 cm e ZID
(memoria `suprafete-cu-goluri-si-praguri`), deci fiecare e o placa CONTINUA,
nu dale alipite.

MACACUL: static, doua poze in acelasi GLB
-----------------------------------------
Ca gnu-ul si zebra de pe Serengeti (memoria `serengeti-assets-kit`): intra in
MultiMesh-ul lui `HerdHazard` (nodul `MaimutePerete` din Track22.tscn —
verificat in scena, nu presupus). 0,5 m, NU 4,6 m cat ar iesi din scara
plansei.
"""

import os
import math

_here_hr = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_hr, "okinawa_shapes.py")).read())

clear_built()

# --- sloturile pe roluri (halong_kit.md §0.4) --------------------------------
HL_ROCK = MARBLE_GREY         # 29: calcar in soare, piatra cioplita, dig
# SLOTUL 3 E PORTOCALIU, nu calcar in umbra. In atlas e **#CE8D4A,
# saturatie 0,64** — stanca de desert. Folosit pentru rosturile parapetului si
# stalactite, iesea ca dungi de RUGINA pe piatra cenusie (vizibil pe captura
# POI C). Aceeasi capcana ca la corpul turnurilor, care fusese deja mutat pe
# 29: numele "ROCK_LIGHT" suna a calcar palid si nu e.
# SAND_SHADOW 2 = nisip in umbra, gri-cald inchis: piatra in umbra, nu rugina.
HL_ROCK_DARK = SAND_SHADOW    # 2: calcar in umbra, rosturi, interiorul grotei
HL_SCRUB = TROPICAL_GREEN     # 21: vegetatie de carst
HL_LEAF_DARK = LOG_DARK       # 28: umbra adanca de frunzis, lemn inchis
HL_WOOD = WOOD                # 9: barne, lemnul pavilionului
HL_NET = DRY_VEGETATION       # 13: paie, franghii
HL_DARK = VOLCANIC_BLACK      # 20: gura grotei, goluri
HL_FUR = SAND_SHADOW          # 2: blana macacului
HL_LIME = FOAM_WHITE          # 22: var pe pavilion

HL_RESULTS = []


def _ao(top=None, dist=2.0, flat=False):
    """AO vertical. `z_range` NU se da: dio_lib si-l deriva din geometrie
    (dio_lib.py:1239), ce e corect pe orice piesa — inclusiv pe una care
    coboara sub zero, unde un interval dat de mana face fractia negativa si
    `t ** power` iese COMPLEX (lectia barcilor, valul 2b)."""
    if flat:
        return dict(samples=12, dist=dist, gradient="vertical", low=0.6,
                    high=1.0, power=0.85, floor=0.3)
    return dict(samples=20, dist=dist, gradient="vertical", low=0.45,
                high=1.0, power=0.8, floor=0.22)


def emit_hl(objs, path, ao, keep_xy=False, bevel=0.0, smooth_angle=None,
            budget=None, bevel_angle=30.0, bevels=None, flat_ao=False,
            keep_z=False):
    """Offsetul de origine O DATA pe ansamblu (memoria
    `finish-recentreaza-fiecare-nod-separat`). `bevel=0.0` implicit: pe cutii
    bevelul TRIPLEAZA triunghiurile (masurat in valul 2a) pentru o muchie care
    la viteza de cursa nu se vede."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    0.0 if keep_z else -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        if flat_ao:
            _split_all_edges(o)
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        if flat_ao:
            _flatten_ao(o)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "halong/" + path)
    HL_RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))


def _drop(objs):
    for o in objs:
        if o is not None:
            bpy.data.objects.remove(o, do_unlink=True)


def _want(name):
    only = os.environ.get("HL_ONLY", "")
    return (not only) or (only == name)


# ---------------------------------------------------------------------------
# grotto_portal (§1.2) — gura grotei, gol 9 x 7 m, piesa ~18 m
# ---------------------------------------------------------------------------

def build_grotto_portal():
    """Gura grotei: perete de calcar cu un gol de 9 x 7 m, spatele PLAT ca sa
    se lipeasca de turn.

    Contractul masurabil (brief §1.2): >= 8 m liberi la cota de 2,5 m. De aceea
    montanii sunt VERTICALI pana la 3,2 m si se inclina doar deasupra — o
    poarta trapezoidala cu 9 m jos s-ar strange sub 8 m exact pe unde trece
    masina.
    Piesa NU modeleaza tunelul, doar gura lui (CameraZone din scena se ocupa de
    camera). Interiorul vizibil prin gol e ROCK_DARK."""
    HALF_GAP = 4.6          # golul: 9,2 m la baza
    TOP = 7.0               # inaltimea golului
    W = 9.0                 # semilatimea piesei (18 m)
    b = Builder()

    # ROCA, NU ZIDARIE. Prima versiune folosea `box` pentru montanti, buiandrug
    # si prag, plus un `rock` deasupra — si pe plansa iesea un SOPRON cu
    # acoperis in doua ape: cutii vizibile, muchii drepte, masa de sus citita
    # ca sarpanta. Garda trecuse (388/700, sloturi corecte), fiindca garda
    # numara, nu VEDE (memoria `harnasul-de-kit-nu-vede-forma-nici-culoarea`).
    #
    # Acum peretele e facut din MASE de stanca suprapuse (`rock`, aceeasi
    # familie ca turnurile), care nu au muchii drepte. Cutiile raman doar unde
    # contractul le cere: pragul (suprafata continua, fara praguri de 15 cm).

    # montantii: cate trei mase pe fiecare parte, tot mai mici spre varf,
    # impinse usor spre exterior ca sa nu stranga golul
    for sx in (-1.0, 1.0):
        b.rock((sx * (HALF_GAP + 1.9), 0.1, 1.5), (4.6, 2.6, 3.6), HL_ROCK,
               seed=120 + int(sx * 3), segments=7, rings=3)
        b.rock((sx * (HALF_GAP + 2.1), -0.1, 4.2), (4.2, 2.5, 3.2), HL_ROCK,
               seed=131 + int(sx * 3), segments=7, rings=3)
        # masa de sus a montantului pe rezolutie mica: e acoperita in mare
        # parte de arcada si de masele de deasupra, deci fatetele ei nu se vad.
        # 764 -> sub 700, bugetul piesei.
        b.rock((sx * (HALF_GAP + 2.4), 0.05, 6.4), (3.8, 2.4, 2.6), HL_ROCK,
               seed=142 + int(sx * 3), segments=5, rings=2)

    # arcada de deasupra golului: doua mase care se intalnesc la mijloc, deci
    # muchia de sus a golului e NEREGULATA, nu un buiandrug drept
    for sx in (-1.0, 1.0):
        b.rock((sx * 2.6, 0.0, TOP + 0.9), (7.4, 2.5, 3.0), HL_ROCK,
               seed=155 + int(sx * 3), segments=7, rings=3)
    # Masa de deasupra: TREI bucati suprapuse, nu una lata.
    # Cu un singur `rock` de 15 m latime piesa citea DOLMEN — un lintel plat
    # cu muchii drepte peste doi stalpi (plansa rundei 2). `rock` turteste
    # forma cand o axa e mult mai mare decat celelalte, deci masa iesea placa.
    # Trei mase de latimi si cote diferite se citesc ca perete de stanca.
    # Cotele sunt COBORATE fata de prima incercare cu trei mase: la TOP+2,2 /
    # +2,7 / +4,3 masele pluteau DEASUPRA montantilor, cu o dunga de cer intre
    # ele, iar piesa ajunsese la 14,3 m si 776 tri (peste bugetul de 700).
    # Acum se suprapun cu arcada (care are varful pe la TOP+2,4), deci peretele
    # e continuu, si a treia masa merge pe segments=6/rings=2 ca sa incapa.
    b.rock((-3.1, 0.1, TOP + 1.5), (7.6, 2.5, 3.4), HL_ROCK,
           seed=71, segments=7, rings=3)
    b.rock((3.4, -0.05, TOP + 1.9), (7.0, 2.4, 3.6), HL_ROCK,
           seed=83, segments=7, rings=3)
    b.rock((0.4, 0.05, TOP + 3.0), (6.2, 2.3, 2.6), HL_ROCK,
           seed=97, segments=6, rings=2)

    # aripile laterale, ca piesa sa aiba 18 m si sa se piarda in turn
    # aripile pe rezolutie mica: sunt cele mai departe de gol si cel mai des
    # acoperite de turnul de care se lipeste piesa. 724 -> sub 700.
    for sx in (-1.0, 1.0):
        b.rock((sx * (W - 1.2), 0.0, 2.4), (5.0, 2.5, 5.2), HL_ROCK,
               seed=90 + int(sx), segments=6, rings=2)

    # pragul: placa CONTINUA (prag de 15 cm = zid pentru fizica intreaga)
    b.box((0.0, 0.0, 0.07), (HALF_GAP * 2.0, 2.4, 0.14), HL_ROCK)
    o_rock = b.to_object("Portal_Rock")

    # INTERIORUL: o CAVITATE, nu o placa.
    #
    # Prima versiune punea o cutie plata la y = -1,15 (adica aproape in planul
    # portalului) si in joc citea ca un PANOU NEGRU sprijinit langa drum —
    # defectul cel mai vizibil din tot POI-ul, pe captura de la frac 0.295.
    # O gura de pestera se citeste prin ADANCIME: peretii laterali si tavanul
    # intra in stanca, iar fundul e departe si intunecat.
    #
    # Deci: fund impins la -4,2 m (nu -1,15), plus doi pereti laterali si un
    # tavan care fac tunelul scurt. `CameraZone` se ocupa de camera; piesa nu
    # modeleaza tunelul intreg (brief §1.2), doar primii metri care dau
    # senzatia de gol.
    d = Builder()
    DEEP = -4.2
    # fundul, departe
    d.box((0.0, DEEP, TOP * 0.5 + 0.1), (HALF_GAP * 2.0, 0.12, TOP), HL_DARK)
    # peretii laterali ai tunelului: inchid vederea pe lateral, deci golul nu
    # mai arata ca o placa lipita pe fata piesei
    for sx in (-1.0, 1.0):
        d.box((sx * (HALF_GAP - 0.06), (DEEP + 0.2) * 0.5, TOP * 0.5 + 0.1),
              (0.12, abs(DEEP) + 0.4, TOP), HL_DARK)
    # tavanul tunelului
    d.box((0.0, (DEEP + 0.2) * 0.5, TOP - 0.06),
          (HALF_GAP * 2.0, abs(DEEP) + 0.4, 0.12), HL_DARK)
    # podeaua tunelului, in continuarea pragului (suprafata continua)
    d.box((0.0, (DEEP + 0.2) * 0.5, 0.06),
          (HALF_GAP * 2.0, abs(DEEP) + 0.4, 0.12), HL_DARK)
    # 4 stalactite pe segments=4 (erau 5 pe 6): sunt siluete negre pe fundal
    # intunecat, vazute prin gol de la 30+ m, deci conturul e tot ce conteaza.
    # 728 -> 696 din bugetul de 700.
    # stalactite in GURA tunelului (y = -0,7), nu pe fata piesei: asa se vad
    # pe fondul intunecat si dau scara adancimii.
    for k in range(4):
        x = -HALF_GAP + (2.0 * HALF_GAP) * (k + 0.5) / 4.0
        ln = 0.5 + (k % 3) * 0.32
        d.frustum((x, -0.7, TOP - ln * 0.5), 0.22, 0.03, ln, HL_ROCK_DARK,
                  segments=4)
    o_dark = d.to_object("Portal_Dark")

    objs = [o_rock, o_dark]
    emit_hl(objs, "structures/grotto_portal.glb", _ao(), budget=700)
    _drop(objs)


# ---------------------------------------------------------------------------
# coast_parapet (§1.5) — modul 6 m, 0,9 m inalt, INLANTUIBIL
# ---------------------------------------------------------------------------

def build_coast_parapet():
    """Parapet jos de piatra-beton. Coama are o fasie plata de >= 0,35 m:
    maimutele stau pe ea (POI G), deci nu poate fi o muchie.

    Modular: capete plane la x = +/- 3, `keep_xy=True` ca modulele sa se
    insiruie fara sa alunece."""
    # 0,55 latime pe 0,75 inaltime. Prima versiune (0,42 pe 0,90) citea ca o
    # ARIPIOARA subtire pe plansa — raport 1:2,1. Un parapet de coasta e un
    # corp indesat, iar coama lui trebuie sa poata tine o maimuta asezata
    # (POI G), deci latimea conteaza si functional.
    L, T, H = 3.0, 0.275, 0.75
    b = Builder()
    # corpul, cu talus foarte usor
    loft(b, [(-L, -T), (L, -T), (L, T), (-L, T)], 0.0,
         [(-L, -T * 0.86), (L, -T * 0.86), (L, T * 0.86), (-L, T * 0.86)],
         H - 0.14, HL_ROCK)
    # coama: placa CONTINUA de 0,42 m lata (contractul cere >= 0,35)
    b.box((0.0, 0.0, H - 0.07), (L * 2.0, 0.55, 0.14), HL_ROCK)
    # rosturile verticale: trei caneluri, ca sa nu citeasca a bara de beton
    for x in (-1.5, 0.0, 1.5):
        b.box((x, 0.0, (H - 0.14) * 0.5), (0.06, T * 2.1, H - 0.2), HL_ROCK_DARK)
    o = b.to_object("Parapet")
    emit_hl([o], "structures/coast_parapet.glb", _ao(dist=1.2), keep_xy=True,
            budget=200)
    _drop([o])


# ---------------------------------------------------------------------------
# stone_dike (§1.5) — modul 8 m, INLANTUIBIL
# ---------------------------------------------------------------------------

def build_stone_dike():
    """Marginea digului de piatra: modul de 8 m. Coama e CALCABILA, deci placa
    continua. Fata dinspre mare are blocuri mari, cea dinspre drum e dreapta."""
    L, D, H = 4.0, 1.1, 1.35
    b = Builder()
    outline = [(-L, -D), (L, -D), (L, D), (-L, D)]
    banded_prism(b, outline, 0.0, H, courses=2, batter=0.05, groove=0.05,
                 cap_h=0.16, cap_over=0.06, slot=HL_ROCK)
    # coama: placa continua peste tot
    b.box((0.0, 0.0, H - 0.05), (L * 2.0, D * 2.0, 0.1), HL_ROCK)
    # blocuri de anrocament pe fata dinspre mare (+Y)
    # Blocurile se SUPRAPUN peste corp (y = D - 0,10, nu D + 0,30) si coboara
    # pana in talpa. Prima versiune le punea langa dig, cu rost vizibil:
    # masurat pe GLB, corpul se termina la Z 1,10 iar blocurile ajungeau la
    # 1,85, deci pluteau pe langa el. Un anrocament e REZEMAT de dig, nu
    # aliniat langa.
    for k in range(4):
        x = -L + (2.0 * L) * (k + 0.5) / 4.0
        b.rock((x, D - 0.10, 0.34), (1.6, 1.15, 0.78), HL_ROCK,
               seed=210 + k * 17, segments=6, rings=2)
    o = b.to_object("Dike")
    emit_hl([o], "structures/stone_dike.glb", _ao(dist=1.6), keep_xy=True,
            budget=250)
    _drop([o])


# ---------------------------------------------------------------------------
# karst_ficus_a / _b (§1.6) — coroane RARE, radacini aeriene pe stanca
# ---------------------------------------------------------------------------

def build_ficus(variant):
    """Ficus de carst. A: 6 m. B: 4,5 m, coroana mai deschisa.

    REMODELAT (oct 2026) dupa verdictul dezvoltatorului pe capturile din joc:
    "coroanele sunt mici fata de trunchiurile inalte, arata ca niste copaci pe
    picioroange". Masurat pe GLB-ul vechi, avea dreptate si cifra o spune:

        coroana 2,4 m lata x 2,1 inalta, incepand de la z = 3,83 pe un copac
        de 5,92 m  ->  65% din inaltime era TRUNCHI GOL, iar coroana era mai
        INGUSTA decat inalta.

    Un ficus (banian) real e exact invers: coroana LATA si joasa, pe trunchi
    scurt si gros. Tinta de acum:

        coroana ~5,5 m lata x 2,6 inalta, incepand de la z = 2,2 (37%)
        -> raport latime/inaltime 2,1 in loc de 1,1, trunchi gol 37% in loc de 65%

    Radacinile aeriene raman semnatura piesei, dar SCURTE si langa trunchi:
    inainte erau fire lungi splayate care citeau ca picioare de paianjen.
    """
    a = variant == "a"
    H = 6.0 if a else 4.5
    # trunchiul se opreste la 37% din inaltime (era 42%), si coroana incepe
    # chiar de acolo, nu cu un metru mai sus.
    trunk_h = H * 0.37
    b = Builder()
    # trunchi SCURT SI GROS: raza 0,42 la baza (era 0,30), pe o inaltime mai
    # mica. Un banian are trunchiul masiv, nu o prajina.
    lean = 0.18 if a else -0.22
    b.taper_sweep([(0.0, 0.0, 0.0),
                   (lean * 0.35, 0.05, trunk_h * 0.5),
                   (lean, 0.08, trunk_h)],
                  [0.42, 0.33, 0.26], HL_WOOD, segments=5)
    # radacini aeriene SCURTE, lipite de trunchi: coboara din prima treime a
    # coroanei si ating solul la 0,3-0,5 m de ax. Inainte plecau de la 0,52 m
    # si se desfaceau in jos ca niste picioare.
    # 3 radacini (erau 5): sunt scurte si lipite de trunchi, deci a patra
    # si a cincea cad in spatele celorlalte. 508 -> sub 400.
    for k in range(3):
        ang = 32.0 + k * 120.0
        rr = 0.34
        rx = math.cos(math.radians(ang)) * rr
        ry = math.sin(math.radians(ang)) * rr * 0.85
        b.taper_sweep([(lean * 0.8, 0.06, trunk_h * 0.92),
                       (rx * 0.9, ry * 0.9, trunk_h * 0.42),
                       (rx, ry, 0.0)],
                      [0.085, 0.07, 0.06], HL_WOOD, segments=3)
    # ramurile principale: pleaca aproape ORIZONTAL si departe, ca sa poarte o
    # coroana lata. Inainte urcau la 0,52-0,84 din inaltimea ramasa si ajungeau
    # la doar ~1 m lateral.
    tips = []
    # 4 ramuri (nu 5): fiecare perna costa ~70 tri, iar 6 perne dadeau
    # 592 din bugetul de 400. Cu 4 + cea centrala: 5 perne.
    nb = 4
    spread = (2.45 if a else 2.0)
    for k in range(nb):
        ang = 28.0 + k * (360.0 / nb)
        tx = math.cos(math.radians(ang)) * spread
        ty = math.sin(math.radians(ang)) * spread * 0.9
        # varful ramurii urca putin peste trunchi, nu mult: coroana e JOASA
        # varfurile urca mai mult, ca piesa sa pastreze inaltimea din
        # contract (6,0 / 4,5 m): cu 0,22 coroana cobora copacul la 4,6 m.
        tz = trunk_h + (H - trunk_h) * (0.52 + 0.16 * (k % 3))
        b.taper_sweep([(lean, 0.08, trunk_h * 0.96),
                       (tx * 0.5, ty * 0.5, trunk_h + (tz - trunk_h) * 0.65),
                       (tx, ty, tz)],
                      [0.19, 0.12, 0.07], HL_WOOD, segments=3)
        tips.append((tx, ty, tz, ang))
    o_wood = b.to_object("Ficus_Wood")

    # CORONA: perne turtite si LATE, care se ating intre ele.
    #
    # Tehnica ramane `foliage_pillow` (la 30-40 m o coroana e o MASA, nu
    # frunze — memoria `coroana-e-masa-nu-frunze`), dar proportiile se schimba:
    # perne LATE si joase (h = 0,42 din latime, era 0,62), asezate pe varfurile
    # departate, plus una centrala care leaga totul peste trunchi. Asa silueta
    # e o umbrela, nu trei bile pe bete.
    f = Builder()
    for i, (tx, ty, tz, ang) in enumerate(tips):
        w = (2.05 if a else 1.75) * (0.9 + 0.1 * (i % 2))
        slot = HL_SCRUB if i % 3 != 1 else HL_LEAF_DARK
        foliage_pillow(f, (tx * 0.78, ty * 0.78, tz + 0.1),
                       w, w * 0.92, w * 0.42, slot,
                       seed=20 + i * 7, bumps=1, seg=7, rings=2,
                       tilt_deg=9.0, tilt_azim_deg=ang)
    # perna centrala, peste trunchi: inchide golul din mijloc, ca sa nu se vada
    # cerul exact deasupra tulpinii
    wc = (2.1 if a else 1.8)
    foliage_pillow(f, (lean * 0.5, 0.05, trunk_h + (H - trunk_h) * 0.34),
                   wc, wc * 0.95, wc * 0.46, HL_SCRUB,
                   seed=77, bumps=1, seg=7, rings=2)
    o_leaf = f.to_object("Ficus_Leaf")

    objs = [o_wood, o_leaf]
    # BUGET 500, nu 400: coroana lata costa mai mult decat una ingusta, si
    # asta e exact ce cumpara piesa. Pista are 15 materiale din 38 si
    # deseneaza 45 de cadre fata de 506-1088 pe celelalte piste, deci
    # triunghiurile nu sunt constrangerea (CLAUDE.md: masurate, fara plafon).
    emit_hl(objs, "plants/karst_ficus_%s.glb" % variant, _ao(dist=1.5),
            budget=500)
    _drop(objs)


# ---------------------------------------------------------------------------
# bamboo_clump (§1.6) — palc inalt si subtire, 7 m
# ---------------------------------------------------------------------------

def build_bamboo():
    """Palc de bambus: 7 tulpini subtiri, inalte, cu frunze doar in treimea de
    sus. Silueta e VERTICALA — asta e tot ce se citeste de pe sosea.

    Bugetul e strict (300) fiindca bambusul merge pe MultiMesh peste ~1000 de
    piese (brief §1.6)."""
    H = 7.0
    b = Builder()
    culms = []
    # 5 tulpini, nu 7: un palc se citeste ca o MASA verticala si tulpinile din
    # interior cad in spatele celor de pe margine. Bugetul de 300 e strict
    # fiindca bambusul merge pe MultiMesh peste ~1000 de piese (brief 1.6).
    for k in range(4):
        ang = k * (360.0 / 4.0) + 11.0
        r = 0.16 + (k % 3) * 0.13
        x, y = math.cos(math.radians(ang)) * r, math.sin(math.radians(ang)) * r
        h = H * (0.74 + 0.26 * ((k * 7 % 5) / 4.0))
        tipx, tipy = x + (k % 3 - 1) * 0.30, y + (k % 2 - 0.5) * 0.26
        b.taper_sweep([(x, y, 0.0), (x * 1.1, y * 1.1, h * 0.55),
                       (tipx, tipy, h)],
                      [0.055, 0.044, 0.026], HL_WOOD, segments=3)
        culms.append((tipx, tipy, h))
    o_culm = b.to_object("Bamboo_Culm")

    f = Builder()
    # O frunza per tulpina (7), nu trei (21 = 840 tri pe un buget de 300).
    # La bambus silueta e TULPINA; frunzisul e doar o pata in treimea de sus,
    # iar pe MultiMesh la peste 1000 de piese fiecare triunghi se inmulteste.
    # DOUA frunze pe fiecare tulpina, la cote diferite. Cu una singura (si una
    # dintre tulpini complet goala) plansa arata PRAJINI, nu bambus: frunzisul
    # e tot ce deosebeste un palc de bambus de niste bete infipte in pamant.
    # Tulpinile au trecut pe segments=3 ca sa incapa frunzele in bugetul de 300.
    # 4 frunze pe fiecare tulpina, esalonate pe treimea de sus, la stations=2.
    # Cu 1-2 frunze palcul citea PRAJINI; frunzisul e tot ce deosebeste
    # bambusul de niste bete infipte in pamant.
    # MASA de frunzis, nu frunze — acelasi diagnostic ca la ficus, aplicat cu
    # alta forma. Ficusul primeste perne BOMBATE si rotunde; un palc de bambus
    # are frunzisul ca o pana INGUSTA SI INALTA care imbraca treimea de sus a
    # tulpinilor. Cu 9 lamele separate palcul citea PRAJINI pe plansa, oricat
    # de dese erau.
    #
    # Doua perne inalte (84 tri bucata) peste grupul de tulpini, la cote
    # diferite, plus 3 lamele lungi pe contur care rup silueta ca sa nu iasa
    # un simplu ou. Buget: 70 + 168 + 72 = 310... deci lamelele merg pe
    # stations=2 si raman 3: 70 + 168 + 3 x 24 = 310 -> 2 lamele = 286.
    hmax = max(c[2] for c in culms)
    # Trei perne LATE, esalonate pe treimea de sus (de la hmax-0,55 pana la
    # hmax-2,45): cu doua perne de 0,74 m pe tulpini de 7 m palcul citea
    # ACADELE — doua bile pe bete. Frunzisul unui palc de bambus imbraca
    # treimea superioara si e cam la fel de lat cat grupul de tulpini
    # (~1,2 m aici), nu un ciucure la varf.
    # Pernele stau pe TULPINI DIFERITE, nu concentric pe ax: cu toate trei in
    # jurul axei palcul citea MARGELE PE ATA (plansa rundei 6) — o coloana de
    # bile, nu un palc. Frunzisul de bambus pleaca din fiecare tulpina in
    # parte, deci masele se desfac lateral si se suprapun doar partial.
    for j in range(3):
        cx, cy, ch = culms[j % len(culms)]
        foliage_pillow(f, (cx * 1.45, cy * 1.45, ch - 0.5 - j * 0.72),
                       1.15 - j * 0.11, 1.05 - j * 0.1, 0.78 - j * 0.06,
                       HL_SCRUB if j != 1 else HL_LEAF_DARK,
                       seed=40 + j * 11, bumps=1, seg=7,
                       # perna de jos pe rings=2: e cea mai acoperita de
                       # celelalte doua, deci rezolutia ei nu se vede.
                       # 308 -> 286 din bugetul de 300.
                       rings=3 if j < 2 else 2)
    # Fara lamele de contur: 3 perne (252) + 5 tulpini (70) = 322 depaseste
    # bugetul de 300, iar pernele sunt ce face silueta. Tulpinile scad la 4,
    # deci 56 + 252 = 308... inca peste, deci pernele merg pe rings=2:
    # masurat mai jos.
    o_leaf = f.to_object("Bamboo_Leaf")

    objs = [o_culm, o_leaf]
    emit_hl(objs, "plants/bamboo_clump.glb", _ao(dist=2.0), budget=300)
    _drop(objs)


# ---------------------------------------------------------------------------
# scrub_tuft (§1.6) — tufa joasa gri-verde pentru varfuri de turn, 0,8 m
# ---------------------------------------------------------------------------

def build_scrub_tuft():
    """Tufa de creasta: 0,8 m, forma de perna turtita. Buget 120, deci e
    literal cateva frunze peste un miez mic — se pune pe varfurile turnurilor,
    unde se vede ca o pata de verde, nu ca o planta."""
    b = Builder()
    # Miez cu rezolutie MICA (5x2) plus trei frunze. La 0,8 m, pusa pe varful
    # unui turn de 55 m, tufa e o PATA de verde: nu se citeste nicio frunza
    # individual, deci 7 frunze erau acelasi pixel platit de 3 ori.
    b.boulder((0.0, 0.0, 0.14), (0.62, 0.56, 0.26), HL_LEAF_DARK, seed=5,
              segments=5, rings=2)
    # Doua frunze, nu trei: `leaf_vfold` costa 40 tri la stations=3, iar cu
    # miezul de 20 trei frunze dadeau 140 pe un buget de 120. Tufa are 0,8 m
    # si sta pe creasta unui turn de 55 m, deci diferenta dintre 2 si 3 frunze
    # nu exista pe ecran.
    for k in range(2):
        ang = 40.0 + k * 150.0
        r = 0.21
        x, y = math.cos(math.radians(ang)) * r, math.sin(math.radians(ang)) * r
        leaf_vfold(b, (x, y, 0.2), ang, 0.5, 0.23, 0.18,
                   HL_SCRUB if k else HL_LEAF_DARK, fold_deg=30.0,
                   stations=3, thick=0.014, droop=0.22)
    o = b.to_object("Scrub")
    emit_hl([o], "plants/scrub_tuft.glb", _ao(dist=0.8), budget=120)
    _drop([o])


# ---------------------------------------------------------------------------
# belvedere_pavilion (§1.7) — reperul construit al belvederei
# ---------------------------------------------------------------------------

def build_belvedere():
    """Pavilion deschis de piatra si lemn, pe platforma pavata cu balustrada.
    6 m lat, 4 m inalt.

    DE CE EXISTA: verdictul la volan a fost "belvedere nu am stiut unde este".
    Masurat atunci, vizibilitatea era buna (turnurile 14/14, apa 17/17) — ce
    lipsea era MARGINEA LOCULUI. Pavilionul e reperul care spune "aici e
    punctul".
    NU e templu si NU are olane curbate (brief §1.7 + lista de interdictii din
    promptul de diorama): pavilion sobru, acoperis in patru pante, drept.

    Platforma e CALCABILA, deci placa continua (prag de 15 cm = zid).
    NODURI (§0.6): Pavilion_Stone + Pavilion_Timber + Pavilion_Roof."""
    W = 3.0                      # semilatime platforma (6 m)
    st = Builder()
    plat = [(-W, -W * 0.82), (W, -W * 0.82), (W, W * 0.82), (-W, W * 0.82)]
    banded_prism(st, plat, 0.0, 0.46, courses=2, batter=0.04, groove=0.04,
                 cap_h=0.14, cap_over=0.07, slot=HL_ROCK)
    # pavajul: placa CONTINUA peste tot
    st.box((0.0, 0.0, 0.43), (W * 2.0, W * 1.64, 0.1), HL_ROCK)
    # balustrada de piatra pe trei laturi (latura dinspre priveliste e libera)
    for sx in (-1.0, 1.0):
        st.box((sx * (W - 0.14), 0.0, 0.73), (0.28, W * 1.64, 0.5), HL_ROCK)
    st.box((0.0, -(W * 0.82 - 0.14), 0.73), (W * 2.0, 0.28, 0.5), HL_ROCK)
    # var pe balustrada — pavilion intretinut
    st.box((0.0, -(W * 0.82 - 0.14), 0.96), (W * 2.0, 0.3, 0.06), HL_LIME)
    o_stone = st.to_object("Pavilion_Stone")

    tb = Builder()
    # patru stalpi de lemn
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            tb.frustum((sx * (W - 0.55), sy * (W * 0.82 - 0.5), 1.72),
                       0.17, 0.145, 2.1, HL_WOOD, segments=6)
    # grinzile de sus
    for sy in (-1.0, 1.0):
        tb.box((0.0, sy * (W * 0.82 - 0.5), 2.86),
               ((W - 0.55) * 2.0 + 0.3, 0.15, 0.2), HL_WOOD)
    for sx in (-1.0, 1.0):
        tb.box((sx * (W - 0.55), 0.0, 2.86),
               (0.15, (W * 0.82 - 0.5) * 2.0, 0.2), HL_WOOD)
    o_timber = tb.to_object("Pavilion_Timber")

    rf = Builder()
    # acoperis in patru pante, DREPT (fara curbura de olane)
    z0, zr = 2.96, 3.95
    e = 0.62                       # streasina
    ex, ey = W - 0.55 + e, W * 0.82 - 0.5 + e
    eave = [(-ex, -ey), (ex, -ey), (ex, ey), (-ex, ey)]
    ridge = [(-0.52, 0.0), (0.52, 0.0)]
    # patru fete: doua trapeze (pe X) si doua triunghiuri (pe Y)
    _face(rf, [(-ex, -ey, z0), (ex, -ey, z0), (ridge[1][0], 0.0, zr),
               (ridge[0][0], 0.0, zr)], HL_NET)
    _face(rf, [(ex, ey, z0), (-ex, ey, z0), (ridge[0][0], 0.0, zr),
               (ridge[1][0], 0.0, zr)], HL_NET)
    _face(rf, [(ex, -ey, z0), (ex, ey, z0), (ridge[1][0], 0.0, zr)], HL_NET)
    _face(rf, [(-ex, ey, z0), (-ex, -ey, z0), (ridge[0][0], 0.0, zr)], HL_NET)
    # coama
    rf.box((0.0, 0.0, zr + 0.04), (1.3, 0.2, 0.12), HL_WOOD)
    o_roof = rf.to_object("Pavilion_Roof")

    objs = [o_stone, o_timber, o_roof]
    emit_hl(objs, "structures/belvedere_pavilion.glb", _ao(dist=2.4),
            budget=700)
    _drop(objs)


# ---------------------------------------------------------------------------
# macaque (§1.8) — static, DOUA poze in acelasi GLB, 0,5 m
# ---------------------------------------------------------------------------

def _macaque_pose(b, ox, crouch):
    """O poza de macac. `crouch=False` sezand drept, `True` ghemuit.
    0,5 m inalt la poza dreapta. Coada LUNGA e semnatura speciei."""
    s = 1.0 if not crouch else 0.74
    body_z = 0.26 * s
    # corp
    b.boulder((ox, 0.0, body_z), (0.17, 0.2, 0.23 * s), HL_FUR, seed=11,
              segments=5, rings=2)
    # cap
    # cap mai rotund (6x3, nu 5x2): la 5x2 iesea un CUB pe plansa. Costa 8 tri
    # in plus si e singura parte a siluetei care spune "maimuta".
    b.boulder((ox, 0.045, body_z + 0.17 * s), (0.10, 0.105, 0.098), HL_FUR,
              seed=12, segments=6, rings=3)
    # fata mai deschisa
    # botul: infundat in cap si mai mic (era o CUTIE proeminenta pe plansa).
    b.box((ox, 0.105, body_z + 0.168 * s), (0.062, 0.028, 0.055), HL_LIME)
    # brate
    for sx in (-1.0, 1.0):
        # bratele pe segments=3: la 0,04 m raza, a patra fata nu exista pe
        # ecran. 352 -> 336 din bugetul de 350.
        b.taper_sweep([(ox + sx * 0.085, 0.03, body_z + 0.1 * s),
                       (ox + sx * 0.1, 0.075, body_z - 0.07 * s),
                       (ox + sx * 0.08, 0.1, body_z - 0.17 * s)],
                      [0.042, 0.034, 0.028], HL_FUR, segments=3)
    # picioare
    for sx in (-1.0, 1.0):
        if crouch:
            b.taper_sweep([(ox + sx * 0.075, -0.02, body_z - 0.06),
                           (ox + sx * 0.11, 0.06, body_z - 0.15),
                           (ox + sx * 0.09, 0.12, 0.012)],
                          [0.05, 0.04, 0.03], HL_FUR, segments=4)
        else:
            b.taper_sweep([(ox + sx * 0.07, -0.01, body_z - 0.1),
                           (ox + sx * 0.085, 0.03, 0.09),
                           (ox + sx * 0.08, 0.075, 0.012)],
                          [0.05, 0.04, 0.03], HL_FUR, segments=4)
    # coada: lunga, curbata. `crab-eating macaque` o are cam cat corpul.
    # Coada porneste din INTERIORUL corpului (y = -0,04, nu -0,16) si cu raza
    # mai mare la radacina. Pe plansa coada PLUTEA detasata in spatele
    # macacului: `boulder` aplica `deviation`, deci suprafata reala a corpului
    # e mai stransa decat semiaxa nominala de 0,20, iar o radacina de 0,032
    # pornita la -0,16 iesea din gol.
    b.taper_sweep([(ox, -0.04, body_z + 0.04),
                   (ox - 0.04, -0.22, body_z - 0.02),
                   (ox - 0.11, -0.36, body_z - 0.18),
                   (ox - 0.09, -0.33, body_z - 0.29)],
                  [0.055, 0.034, 0.022, 0.014], HL_FUR, segments=4)


def build_macaque():
    """Doua poze in acelasi GLB, ca gnu-ul si zebra de pe Serengeti: nodurile
    se numesc `Macaque_Sit` si `Macaque_Crouch`, iar `HerdHazard` alege.

    `--origin=assembly` in garda: a doua poza NU sta sub prima, deci regula
    "baza la Y=0" per nod ar fi greita."""
    a = Builder()
    _macaque_pose(a, 0.0, crouch=False)
    o_sit = a.to_object("Macaque_Sit")
    c = Builder()
    _macaque_pose(c, 0.9, crouch=True)
    o_cr = c.to_object("Macaque_Crouch")
    objs = [o_sit, o_cr]
    emit_hl(objs, "animals/macaque.glb", _ao(dist=0.6), budget=350)
    _drop(objs)


# ---------------------------------------------------------------------------
# halong_horizon (§1.9) — UN fisier, TREI noduri
# ---------------------------------------------------------------------------

def _karst_row(b, width, height, n, seed, slot_main, slot_pale=None,
               pale_from=0.55, rings3=True):
    """Un sir de turnuri de carst ca SILUETA: `n` conuri trunchiate cu profil
    de turn (strangere la baza, perete drept), aliniate pe X.

    Fatete MARI: la 150-320 m si scara 1,3-2,4x detaliul fin e zgomot
    (memoria `silueta-inainte-de-umbrire`). segments=6 explicit.
    Volume INCHISE, citibile din orice azimut."""
    rnd = _lcg(seed)
    half = width * 0.5
    for k in range(n):
        t = (k + 0.5) / n
        x = -half + width * t
        h = height * (0.52 + 0.48 * rnd())
        r = h * (0.26 + 0.1 * rnd())
        y = (rnd() - 0.5) * height * 0.3
        slot = slot_main
        if slot_pale is not None and rnd() > pale_from:
            slot = slot_pale
        # turnul: baza strangsa, perete drept, varf retras — profilul de carst
        # redus la trei inele (la distanta asta nu se vede mai mult)
        if rings3:
            # TREI inele, dar cu raze care VARIAZA pe inaltime.
            #
            # Prima versiune avea pereti drepti (1,0 -> 0,95) si capac plat la
            # 0,5: sirul citea ca o LINIE DE BLOCURI, un mic skyline. Am
            # incercat un al patrulea inel pentru varf rotunjit — 1720 tri din
            # 1500 si castig vizual aproape nul, deci inelul nu era cauza.
            # Cauza e peretele DREPT: un turn de carst se umfla la mijloc si se
            # strange spre varf, iar diferenta se citeste si de la 150-320 m.
            # `bulge` variaza per turn (determinist din rnd), deci sirul nu mai
            # are doua siluete identice. Acelasi buget, alta forma.
            bulge = 1.0 + 0.16 * (rnd() - 0.3)
            b.frustum((x, y, h * 0.05), r * 0.80, r * bulge, h * 0.1, slot,
                      segments=6)
            b.frustum((x, y, h * 0.5), r * bulge, r * 0.82, h * 0.8, slot,
                      segments=6)
            b.frustum((x, y, h * 0.95), r * 0.82, r * 0.26, h * 0.1, slot,
                      segments=6)
        else:
            # Planul depArtat: DOUA inele. Brief 1.9 il cere "silueta aproape
            # plata", iar la 320 m strangerea de la baza nu se mai citeste;
            # ce rtamane e conturul de sus.
            b.frustum((x, y, h * 0.5), r * 0.88, r * 0.80, h, slot,
                      segments=6)
            b.frustum((x, y, h * 0.96), r * 0.80, r * 0.24, h * 0.09, slot,
                      segments=6)


def build_horizon():
    """Trei planuri de fundal, fiecare UN nod copil al radacinii.

    UN fisier cu trei noduri, nu trei fisiere: `Track._build_horizon` incarca
    un singur `horizon_model` si scoate din el cate un nod pe nume
    (track.gd:6251-6256). Vezi antetul fisierului.

    Numele nodurilor: `KarstRow_A/B/C` (se trec in tema prin `horizon_picks`).
    Planul depArtat e mai PALID si mai plat — asta face adancimea, impreuna cu
    ceata in strat.
    `cast_shadow` OFF se pune la integrare: o silueta scalata care arunca umbra
    stinge directionala (memoria `caster-departat-fura-umbra`)."""
    specs = [
        ("KarstRow_A", 150.0, 50.0, 7, 301, HL_ROCK, None, True),
        ("KarstRow_B", 230.0, 45.0, 9, 302, HL_ROCK, HL_LIME, True),
        ("KarstRow_C", 320.0, 40.0, 11, 303, HL_LIME, HL_ROCK, False),
    ]
    objs = []
    for (name, w, h, n, seed, s_main, s_pale, r3) in specs:
        b = Builder()
        _karst_row(b, w, h, n, seed, s_main, s_pale, rings3=r3)
        objs.append(b.to_object(name))
    emit_hl(objs, "rocks/halong_horizon.glb", _ao(flat=True, dist=25.0),
            budget=1500, flat_ao=True)
    _drop(objs)


# ---------------------------------------------------------------------------

if _want("grotto_portal"):
    build_grotto_portal()
if _want("coast_parapet"):
    build_coast_parapet()
if _want("stone_dike"):
    build_stone_dike()
if _want("karst_ficus_a"):
    build_ficus("a")
if _want("karst_ficus_b"):
    build_ficus("b")
if _want("bamboo_clump"):
    build_bamboo()
if _want("scrub_tuft"):
    build_scrub_tuft()
if _want("belvedere_pavilion"):
    build_belvedere()
if _want("macaque"):
    build_macaque()
if _want("halong_horizon"):
    build_horizon()

print()
print("=== Ha Long val 3 — drum, plante, repere, fundal ===")
for path, tris, dims, budget, per_node, kb in HL_RESULTS:
    flag = ""
    if budget:
        flag = "OK" if tris <= budget else "PESTE BUGET (%d)" % budget
    print("  %-38s %5d tri  %6.1f x %5.1f x %5.1f m  %7.1f kB  %s"
          % (path, tris, dims.x, dims.y, dims.z, kb, flag))
    for n, t in sorted(per_node.items()):
        print("        %-28s %5d tri" % (n, t))
