"""Ha Long, valul 2 — satul plutitor (brief docs/asset_briefs/halong_kit.md §1.3).

  halong/buildings/floating_house_a.glb   casa de lemn pe pluta, 7 x 5 m, 4 m
  halong/buildings/floating_house_b.glb   varianta, alt acoperis si alt lemn
  halong/structures/fish_farm.glb         tarc de plase pe punti, modul 8 x 8 m
  halong/props/net_drying_rack.glb        rastel de plase la uscat, 4 x 3 m
  halong/structures/stone_quay.glb        cheiul de piatra cu babale, modul 12 m

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_halong_village.py

Variabila HL_ONLY=<piesa> reface doar piesa respectiva.

DE CE VALUL 2 A ASTEPTAT
------------------------
Casa de 4 m si jonca de 12 m nu au scara proprie: ele citesc "mic" sau "mare"
doar langa un turn de 45-65 m. Daca `r_mid` al turnurilor s-ar fi schimbat
dupa playtest, toate piesele astea ar fi fost construite pe o premisa moarta.
Verdictul la volan (16 oct 2026) a fost "acele turnuri par ok ca si inaltime",
deci cotele din §1.1 sunt fixe si satul se poate dimensiona fata de ele.

PLUTA, SI DE CE E CONTRACTUL PIESEI
-----------------------------------
O casa de sat plutitor nu sta pe pamant: sta pe o pluta de barne legate peste
butoaie. Deci silueta are TREI registre, de jos in sus:

    butoaie (CAR_BLUE 15)   cilindri culcati, pe jumatate sub linia de plutire
    pluta   (WOOD_WEATHERED) grinzi incrucisate, fata de sus la z = 0,45
    casa    (WOOD_WEATHERED + PAINTED_METAL) pereti de scandura, tabla ondulata

Butoaiele sunt SINGURUL albastru saturat de aici si stau NUMAI sub plute si
sub tarcuri (brief §0.4). `verify_halong.sh` le accepta prin
`--allow-car-slots=House_Drums` / `=Farm_Drums`, deci nodul trebuie sa se
numeasca exact asa: slotul 15 pe orice alt nod PICA garda, si asta e intentia.

NODURI (brief §0.6): piesele care primesc clasa triplanara la integrare se
sparg in obiecte de un singur material.
  casa:  House_Timber + House_Roof + House_Raft + House_Drums
  tarc:  Farm_Deck + Farm_Nets + Farm_Drums
  chei:  (un singur nod, piatra) Quay_Stone
Rastelul si plasele lui stau pe DRY_VEGETATION, deci un nod.

SATUL E LOCUIT SI INTRETINUT, nu saracacios (promptul de diorama, brief §1.3):
tabla e vopsita, nu rupta; plasele sunt intinse pe rastel, nu mototolite;
puntea are balustrada pe latura dinspre larg.

MODULARITATE: `fish_farm` si `stone_quay` se insiruie, deci au capetele plane
la x = +/- jumatate din modul si NU se centreaza pe bbox (`keep_xy=True`).
Avertismentul de necentrare din `verify_glb.py` e corect si intentionat —
brief-ul il declara la §0, "MODULARE".
"""

import os
import math

_here_hv = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_hv, "okinawa_shapes.py")).read())

clear_built()

# --- sloturile pe roluri (halong_kit.md §0.4) --------------------------------
# SLOTURILE SE VERIFICA IN ATLAS, NU DUPA NUME (lectia valului 1: slotul 3,
# numit ROCK_LIGHT, e #CE8D4A portocaliu — stanca de desert, nu calcar).
HL_STONE = MARBLE_GREY        # 29: piatra cioplita, cheiul
HL_WOOD = WOOD                # 9: barne, plute, punti, rame de tarc
HL_ROOF = PAINTED             # 11: tabla ondulata
HL_DRUM = CAR_BLUE            # 15: butoaie de plastic — accent DECLARAT
HL_NET = DRY_VEGETATION       # 13: plase, franghii, paie
HL_DARK = VOLCANIC_BLACK      # 20: goluri de fereastra, cauciucuri
HL_WASHED = SAND_SHADOW       # 2: lemn spalat de soare
HL_LIME = FOAM_WHITE          # 22: var

HL_RESULTS = []


def _ao(top, dist=2.0):
    """AO pe gradient vertical, pe inaltimea piesei. O casa de 4 m cere alt
    `z_range` decat un chei de 12 m lungime si 1,5 m inaltime."""
    return dict(samples=20, dist=dist, gradient="vertical", low=0.45, high=1.0,
                power=0.8, floor=0.22, z_range=(0.0, top))


def emit_hl(objs, path, ao, keep_xy=False, bevel=0.0, smooth_angle=None,
            budget=None, bevel_angle=30.0, bevels=None, flat_ao=False):
    """Finish pe fiecare nod + export in assets/models/halong/<path>.

    Offsetul de origine se calculeaza O DATA pe ansamblu (memoria
    `finish-recentreaza-fiecare-nod-separat`): altfel `finish` re-centreaza
    fiecare nod pe bbox-ul LUI, iar casa s-ar desface — acoperisul ar coboari
    la zero, butoaiele ar urca. Copie dupa `emit_hl` din build_halong_karst.py,
    ca piesele valului 2 sa iasa cu aceeasi convetie ca turnurile."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
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
    """Scoate nodurile dupa export, ca urmatoarea piesa sa-si pastreze numele
    (altfel Blender adauga .001, iar Godot cauta nodurile dupa nume)."""
    for o in objs:
        if o is not None:
            bpy.data.objects.remove(o, do_unlink=True)


def _want(name):
    only = os.environ.get("HL_ONLY", "")
    return (not only) or (only == name)


# ---------------------------------------------------------------------------
# pluta: butoaie + grinzi. Folosita de casa si de tarc.
# ---------------------------------------------------------------------------

def raft_drums(b, hx, hy, rows=2, cols=3, r=0.30, z=0.12):
    """Butoaie culcate sub pluta, pe o grila. Axa pe Y (culcate pe lung), deci
    se vad ca cilindri de sub bordura plutei.

    `segments=8` explicit: un cilindru lasat la rezolutia implicita sare cu
    zeci de mii de triunghiuri (CLAUDE.md — regula primitivelor)."""
    for i in range(cols):
        for j in range(rows):
            x = -hx * 0.72 + (1.44 * hx) * (i / max(1, cols - 1))
            y = -hy * 0.58 + (1.16 * hy) * (j / max(1, rows - 1))
            b.cylinder((x, y, z), r, hy * 0.74, HL_DRUM, segments=6, axis="Y")


def raft_deck(b, hx, hy, z_top=0.45, beam=0.17):
    """Grinzi incrucisate cu fata de sus la `z_top`: 5 pe X, 3 pe Y.

    Barnele se SUPRAPUN (nu sunt placi independente) — pentru fizica intreaga
    un prag de 15 cm e zid, iar aici puntea e suprafata pe care sta casa
    (memoria `suprafete-cu-goluri-si-praguri`). Puntea e un singur corp
    continuu: cadrul de jos pe toata aria, scandurile deasupra lui."""
    # cadrul: doua grinzi lungi pe Y, la margini, plus trei traverse pe X
    for sx in (-1.0, 0.0, 1.0):
        b.box((sx * hx * 0.88, 0.0, z_top - beam * 0.5),
              (beam, hy * 2.0, beam), HL_WOOD)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * hy * 0.90, z_top - beam * 0.5),
              (hx * 2.0, beam, beam), HL_WOOD)
    # scandurile: o placa continua, ca sa nu existe rosturi de 15 cm
    b.box((0.0, 0.0, z_top - 0.035), (hx * 2.0, hy * 2.0, 0.07), HL_WOOD)


# ---------------------------------------------------------------------------
# floating_house_a / _b
# ---------------------------------------------------------------------------

def build_house(variant):
    """Casa de lemn pe pluta. 7 x 5 m pluta, 4 m inaltime totala.

    Varianta A: acoperis in doua pante, tabla verzuie, terasa pe latura -Y.
    Varianta B: acoperis intr-o panta (sopron), tabla mai inchisa, lemn
                spalat de soare, terasa pe +X. Alt acoperis si alta culoare de
                lemn, cum cere brief §1.3 — nu doar alt seed.
    """
    a = variant == "a"
    hx, hy = 3.5, 2.5                 # pluta 7 x 5 m
    deck_z = 0.45
    wall_h = 2.35
    wood = HL_WOOD if a else HL_WASHED

    drums = Builder()
    raft_drums(drums, hx, hy, rows=2, cols=2, r=0.32, z=0.12)
    o_drums = drums.to_object("House_Drums")

    raft = Builder()
    raft_deck(raft, hx, hy, z_top=deck_z)
    # bordura plutei, ca butoaiele sa nu pluteasca vizual in aer
    for sy in (-1.0, 1.0):
        raft.box((0.0, sy * (hy - 0.06), deck_z - 0.16),
                 (hx * 2.0, 0.12, 0.2), wood)
    o_raft = raft.to_object("House_Raft")

    tb = Builder()
    # corpul casei: 4,6 x 3,4 m, lasat spre +Y ca sa rtamana terasa
    cx, cy = (0.0, 0.45) if a else (-0.55, 0.0)
    wx, wy = (2.3, 1.7) if a else (2.0, 2.0)
    # pereti: patru placi cu grosime, suprapuse la colturi
    for sx in (-1.0, 1.0):
        tb.box((cx + sx * wx, cy, deck_z + wall_h * 0.5),
               (0.1, wy * 2.0, wall_h), wood)
    for sy in (-1.0, 1.0):
        tb.box((cx, cy + sy * wy, deck_z + wall_h * 0.5),
               (wx * 2.0, 0.1, wall_h), wood)
    # podeaua casei, peste punte
    tb.box((cx, cy, deck_z + 0.04), (wx * 2.0, wy * 2.0, 0.08), wood)
    # stalpii terasei + balustrada spre larg (satul e INTRETINUT)
    if a:
        rail_y = cy - wy - 1.55
        for sx in (-1.0, 1.0):
            tb.box((sx * (hx - 0.3), rail_y, deck_z + 0.5),
                   (0.09, 0.09, 1.0), wood)
        tb.railing(( -(hx - 0.3), rail_y, deck_z),
                   ((hx - 0.3), rail_y, deck_z),
                   0.95, 1.5, 0.08, 0.06, wood, rails=2)
    else:
        rail_x = cx + wx + 1.35
        tb.railing((rail_x, -(hy - 0.3), deck_z),
                   (rail_x, (hy - 0.3), deck_z),
                   0.95, 1.5, 0.08, 0.06, wood, rails=2)
    # golurile de fereastra si usa: placi negre in fata peretelui
    if a:
        tb.box((cx - 0.9, cy - wy - 0.055, deck_z + 1.15), (0.8, 0.04, 1.1), HL_DARK)
        tb.box((cx + 1.1, cy - wy - 0.055, deck_z + 1.3), (0.6, 0.04, 0.6), HL_DARK)
        tb.box((cx + wx + 0.055, cy, deck_z + 1.3), (0.04, 0.9, 0.7), HL_DARK)
    else:
        tb.box((cx + wx + 0.055, cy + 0.5, deck_z + 1.15), (0.04, 0.8, 1.1), HL_DARK)
        tb.box((cx + wx + 0.055, cy - 0.9, deck_z + 1.3), (0.04, 0.55, 0.6), HL_DARK)
        tb.box((cx, cy + wy + 0.055, deck_z + 1.3), (0.9, 0.04, 0.7), HL_DARK)
    # var pe soclul pereteilor — satul e intretinut
    tb.box((cx, cy, deck_z + 0.22), (wx * 2.0 + 0.04, wy * 2.0 + 0.04, 0.3), HL_LIME)
    o_timber = tb.to_object("House_Timber")

    rf = Builder()
    z0 = deck_z + wall_h
    if a:
        # doua pante, coama pe X (casa e mai lunga pe X)
        rise = 0.85
        ridge = z0 + rise
        over = 0.42
        for sy in (-1.0, 1.0):
            # panta ca o placa inclinata: beam intre coama si streasina
            rf.beam((cx - wx - over, cy + sy * (wy + over), z0 + 0.02),
                    (cx + wx + over, cy + sy * (wy + over), z0 + 0.02),
                    0.16, HL_ROOF)
        # panza propriu-zisa: doua placi inclinate, muchie comuna pe coama
        for sy in (-1.0, 1.0):
            y_eave = cy + sy * (wy + over)
            rf.blade([(cx - wx - over, (y_eave + cy) * 0.5, (z0 + 0.02 + ridge) * 0.5),
                      (cx + wx + over, (y_eave + cy) * 0.5, (z0 + 0.02 + ridge) * 0.5)],
                     [abs(y_eave - cy) * 1.06, abs(y_eave - cy) * 1.06],
                     0.1, HL_ROOF, up=(0.0, sy * 0.52, 0.86))
        rf.box((cx, cy, ridge + 0.03), (wx * 2.0 + over, 0.22, 0.1), HL_ROOF)
    else:
        # o panta (sopron), cade spre -X
        rise = 0.72
        over = 0.40
        rf.blade([(cx, cy - wy - over, z0 + rise * 0.5 + 0.04),
                  (cx, cy + wy + over, z0 + rise * 0.5 + 0.04)],
                 [(wx + over) * 2.06, (wx + over) * 2.06],
                 0.1, HL_ROOF, up=(0.60, 0.0, 0.80))
        rf.box((cx + wx + over * 0.6, cy, z0 + rise + 0.02),
               (0.2, wy * 2.0 + over, 0.1), HL_ROOF)
    o_roof = rf.to_object("House_Roof")

    # plasele de pe terasa: satul e locuit, plasele sunt INTINSE pe un cadru
    nt = Builder()
    if a:
        ny = cy - wy - 1.3
        nt.box((0.0, ny, deck_z + 0.62), (hx * 0.62, 0.03, 0.5), HL_NET)
    else:
        nx = cx + wx + 1.1
        nt.box((nx, 0.0, deck_z + 0.62), (0.03, hy * 0.62, 0.5), HL_NET)
    o_net = nt.to_object("House_Nets")

    name = "floating_house_%s" % variant
    # plasele intra in nodul de lemn: acelasi slot de clasa la integrare nu e
    # cerut pentru ele, dar un nod separat de 24 de triunghiuri e risipa de
    # draw call. Le unim in House_Timber prin JOIN pe acelasi slot? Nu: slotul
    # difera (13 vs 9), deci nodul rtamane separat — un nod per material, cum
    # cere §0.6, iar bugetul il acopera.
    objs = [o_timber, o_roof, o_raft, o_drums, o_net]
    # bevel=0.0: pe cutii bevelul TRIPLEAZA triunghiurile (masurat: un cilindru
    # seg=8 sarea de la 32 la 92 tri) pentru o muchie care la viteza de cursa
    # nu se vede. Valul 1 ruleaza la fel.
    emit_hl(objs, "buildings/%s.glb" % name, _ao(4.2), budget=600,
            bevel=0.0, smooth_angle=None)
    _drop(objs)


# ---------------------------------------------------------------------------
# fish_farm — tarc patrat de plase pe punti, MODULAR (se inlanuie pe X)
# ---------------------------------------------------------------------------

def build_fish_farm():
    """Tarc de 8 x 8 m: patru punti inguste in cadru patrat, plase intinse
    intre ele, butoaie dedesubt. Modular: capetele plane la x = +/- 4.

    `keep_xy=True` la emit, ca modulele sa se insiruie fara sa se mute
    centrul: un tarc recentrat pe bbox ar aluneca jumatate de modul la fiecare
    verig adaugata."""
    M = 4.0                            # jumatate de modul
    walk = 0.72                        # latimea puntii
    deck_z = 0.42

    drums = Builder()
    # butoaie sub cele patru laturi, nu sub mijloc (mijlocul e plasa)
    for sx in (-1.0, 1.0):
        for t in (-0.6, 0.6):
            drums.cylinder((sx * (M - walk * 0.5), t * M * 1.3, 0.1), 0.27,
                           walk * 0.82, HL_DRUM, segments=6, axis="Y")
    o_drums = drums.to_object("Farm_Drums")

    dk = Builder()
    # cadrul de punti: patru fasii, suprafete continue (nu placi separate)
    for sx in (-1.0, 1.0):
        dk.box((sx * (M - walk * 0.5), 0.0, deck_z - 0.05),
               (walk, M * 2.0, 0.1), HL_WOOD)
    for sy in (-1.0, 1.0):
        dk.box((0.0, sy * (M - walk * 0.5), deck_z - 0.05),
               (M * 2.0 - walk * 2.0, walk, 0.1), HL_WOOD)
    # rame verticale care tin plasele, pe colturi si la mijlocul laturilor
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            dk.box((sx * (M - 0.18), sy * (M - 0.18), deck_z + 0.42),
                   (0.11, 0.11, 0.84), HL_WOOD)
    for sx in (-1.0, 1.0):
        dk.box((sx * (M - 0.18), 0.0, deck_z + 0.42), (0.11, 0.11, 0.84), HL_WOOD)
    # FARA balustrada. Doua motive, si al doilea e cel care decide:
    #  1. buget — `railing` cu stalpi la 2 m plus doua lise costa ~90 tri, si
    #     tarcul sarea la 428 din 400;
    #  2. tarcul e MODULAR pe X si se poate lega si pe Y la integrare (brief
    #     §1.3 il cere "modular (se inlanuie)", fara sa fixeze axa). O
    #     balustrada pe laturile de Y ar aparea ca gard INTRE doua module
    #     alipite pe acolo. Ramelele verticale care tin plasele dau deja
    #     silueta de tarc, iar puntea se citeste ca potecă fara mana curenta —
    #     ce e si in fotografiile de ferme de pesti din Ha Long.
    o_deck = dk.to_object("Farm_Deck")

    nets = Builder()
    # plasele: patru panze verticale in interiorul cadrului, intinse (nu
    # mototolite — satul e intretinut), plus o panza orizontala sub apa
    inner = M - walk
    for sx in (-1.0, 1.0):
        nets.box((sx * inner, 0.0, deck_z - 0.55), (0.03, inner, 1.0), HL_NET)
    for sy in (-1.0, 1.0):
        nets.box((0.0, sy * inner, deck_z - 0.55), (inner, 0.03, 1.0), HL_NET)
    nets.box((0.0, 0.0, deck_z - 1.05), (inner, inner, 0.03), HL_NET)
    o_nets = nets.to_object("Farm_Nets")

    objs = [o_deck, o_nets, o_drums]
    emit_hl(objs, "structures/fish_farm.glb", _ao(1.7), keep_xy=True,
            budget=400, bevel=0.0)
    _drop(objs)


# ---------------------------------------------------------------------------
# net_drying_rack — rastel de plase la uscat, 4 m lat, 3 m inalt
# ---------------------------------------------------------------------------

def build_net_rack():
    """Rastel: doi stalpi in A, o bara de coama, plase INTINSE pe ea.

    Un singur nod (`Rack`): lemnul si plasele iau sloturi diferite, dar piesa
    nu primeste clasa triplanara la integrare (nu e nici roca, nici zidarie),
    deci §0.6 nu cere spargerea. Buget 250, deci geometria sta simpla."""
    b = Builder()
    W, H = 2.0, 3.0                    # jumatate de latime, inaltime
    for sx in (-1.0, 1.0):
        # picioarele in A: doua bare inclinate care se intalnesc sub coama
        b.beam((sx * W, -0.75, 0.0), (sx * (W - 0.33), 0.0, H - 0.12), 0.11, HL_WOOD)
        b.beam((sx * W, 0.75, 0.0), (sx * (W - 0.33), 0.0, H - 0.12), 0.11, HL_WOOD)
        # traversa care leaga picioarele
        b.box((sx * (W - 0.17), 0.0, H * 0.42), (0.09, 0.78, 0.09), HL_WOOD)
    # coama
    b.box((0.0, 0.0, H - 0.06), (W * 2.0 - 0.5, 0.11, 0.11), HL_WOOD)
    # plasele: doua panze mari intinse de pe coama spre jos, in V deschis
    for sy in (-1.0, 1.0):
        b.blade([(-(W - 0.42), 0.0, H - 0.12), ((W - 0.42), 0.0, H - 0.12)],
                [1.9, 1.9], 0.03, HL_NET, up=(0.0, sy * 0.72, -0.69))
    # o plasa strans facuta sul, pe traversa — detaliu de "locuit"
    b.cylinder((0.0, 0.0, H * 0.42 + 0.17), 0.16, W * 1.1, HL_NET,
               segments=8, axis="X")
    o = b.to_object("Rack")
    emit_hl([o], "props/net_drying_rack.glb", _ao(3.1), budget=250, bevel=0.0)
    _drop([o])


# ---------------------------------------------------------------------------
# stone_quay — cheiul de piatra cu babale, MODUL de 12 m (start/sosire)
# ---------------------------------------------------------------------------

def build_stone_quay():
    """Chei de piatra: modul de 12 m pe X, 3,2 m adancime, 1,5 m inaltime.

    Suprafata de SUS e carosabila (start/sosire e aici), deci:
      - varfuri partajate, fara placi independente (memoria
        `suprafete-cu-goluri-si-praguri`: un prag de 15 cm e zid pentru fizica
        intreaga);
      - fata de sus PLANA la z = 1,5 exact, ca modulele sa se lege fara prag.
    Capetele plane la x = +/- 6, deci `keep_xy=True`.

    Babalele (bollard) sunt scurte, 0,45 m: la 0,9 m ar fi obstacol pe linia
    de start. Stau pe marginea dinspre apa (+Y), nu pe mijloc."""
    L, D, H = 6.0, 1.6, 1.5            # jumatati + inaltime
    b = Builder()
    # corpul: asize de piatra cu talus usor, pe contur dreptunghiular.
    # `banded_prism` da rosturile orizontale fara geometrie in plus.
    outline = [(-L, -D), (L, -D), (L, D), (-L, D)]
    banded_prism(b, outline, 0.0, H, courses=3, batter=0.035, groove=0.05,
                 cap_h=0.18, cap_over=0.07, slot=HL_STONE)
    # fata de sus: o placa plana peste tot, ca sa nu existe prag intre asiza
    # de capat si placa lui `banded_prism`
    b.box((0.0, 0.0, H - 0.05), (L * 2.0, D * 2.0, 0.1), HL_STONE)
    o_stone = b.to_object("Quay_Stone")

    # babalele + cauciucurile de amortizare: nod separat, slot diferit
    f = Builder()
    # babale: doua, nu trei — pe un modul de 12 m doua sunt destule, iar linia
    # de start nu trebuie aglomerata. seg=6: la 0,17 m raza, a saptea fata nu
    # se vede de pe sosea.
    for x in (-3.0, 3.0):
        f.frustum((x, D - 0.34, H + 0.2), 0.17, 0.14, 0.4, HL_STONE, segments=6)
        f.frustum((x, D - 0.34, H + 0.42), 0.21, 0.19, 0.1, HL_STONE, segments=6)
    # cauciucuri de amortizare: `torus` 8x6 costa 96 tri BUCATA, si propriul lui
    # docstring spune ca e scump pentru cat de mic e in cadru. Un disc turtit din
    # frustum (seg=6, 24 tri) se citeste identic de pe sosea.
    for x in (-4.4, -1.5, 1.5, 4.4):
        f.frustum((x, D + 0.02, H * 0.52), 0.25, 0.25, 0.14, HL_DARK,
                  segments=6, axis="Y")
    o_fit = f.to_object("Quay_Fittings")

    objs = [o_stone, o_fit]
    emit_hl(objs, "structures/stone_quay.glb", _ao(1.9), keep_xy=True,
            budget=350, bevel=0.0)
    _drop(objs)


# ---------------------------------------------------------------------------

if _want("floating_house_a"):
    build_house("a")
if _want("floating_house_b"):
    build_house("b")
if _want("fish_farm"):
    build_fish_farm()
if _want("net_drying_rack"):
    build_net_rack()
if _want("stone_quay"):
    build_stone_quay()

print()
print("=== Ha Long val 2 — satul plutitor ===")
for path, tris, dims, budget, per_node, kb in HL_RESULTS:
    flag = ""
    if budget:
        flag = "OK" if tris <= budget else "PESTE BUGET (%d)" % budget
    print("  %-38s %5d tri  %5.1f x %4.1f x %4.1f m  %7.1f kB  %s"
          % (path, tris, dims.x, dims.y, dims.z, kb, flag))
    for n, t in sorted(per_node.items()):
        print("        %-28s %5d tri" % (n, t))
