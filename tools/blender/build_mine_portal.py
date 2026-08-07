"""mine_portal.glb — intrare de mina cu sina ingusta si vagonet rasturnat.
Brief: docs/asset_briefs/mine_portal.md · issue #C2 · texturi de clasa #130

Al doilea landmark nou. Avantajul lui peste celelalte candidate e ca se leaga de
ce e deja in joc: pista are un tren care traverseaza soseaua
(`scenes/hazards/train_hazard.gd`, la frac 0.37), iar o mina cu vagonet si sina
ingusta explica de ce exista o cale ferata in mijlocul desertului.

TREI GRUPURI independente, fiecare cu ORIGINEA LUI la baza, centrata in XZ:
  Portal_*    <= 600 tris    movila, cadru de lemn, gura, steril
  MineRail_*  <= 250         traverse + sine
  MineCart_*  <= 150         lada rasturnata, roti, minereu

Separarea pe GRUPURI e cea veche si e intentionata: instanta de gameplay poate
aseza sina si vagonetul departe de portal. Separarea PE PARTI in interiorul unui
grup e noua (#130) si urmeaza clasa de suprafata:

  Portal_Rock      -> clasa `rock`, TRIPLANAR de lume (piesa e statica)
  Portal_Wood      -> clasa `wood`, UV cubic
  Portal_Trim      -> ATLAS: gura minei si sterilul
  MineRail_Wood    -> `wood`      MineRail_Metal  -> `rust_metal`
  MineCart_Wood    -> `wood`      MineCart_Metal  -> `rust_metal`
  MineCart_Trim    -> ATLAS: bucatile de minereu

De ce movila e triplanara si nu pe UV cubic: proiectia de lume face straturile
sa curga CONTINUU dintr-o piesa in vecina ei, deci movila se leaga de faleza de
care se sprijina in loc sa-si aiba propriul tipar taiat la contur. E acelasi
motiv pentru care falezele si arcada merg asa (Palette.rock_material).

De ce gura minei RAMANE pe atlas: e slotul cel mai inchis din lume, iar
intunericul ei e tot efectul. Orice textura ii adauga detaliu, adica exact ce
transforma o gaura intr-o suprafata.

Gura minei priveste spre +Y in Blender (= -Z in Godot); spatele e retezat plat,
ca portalul sa se lipeasca de o faleza fara sa pluteasca.
"""

import math
from mathutils import Vector, Matrix

# --- portal -------------------------------------------------------------------
# `rock(flat_top=True)` reteaza varful la 82% din inaltimea data, deci cota se
# scrie compensat: brieful cere o movila de 6.5 m, iar 6.5/0.82 = 7.93.
MOUND = (9.0, 8.0, 7.93)
BACK_Y = -3.30               # planul spatelui retezat
OPEN_W, OPEN_H = 4.00, 3.80  # deschiderea
POST_T = 0.35
# Planul cadrului. Trebuie sa cada PE fata movilei, nu in ea: la prima rulare
# era 2.10, iar movila (centru y=0.6, semi-adancime 4.0, retrasa cu inaltimea)
# ajunge la ~4.35 la inaltimea deschiderii — deci si cadrul, si panoul intunecat
# erau ingropate si nu se vedea nimic din portal.
FRONT_Y = 4.05
RECESS = 1.40                # cat de adanc sta panoul intunecat

# --- sina ---------------------------------------------------------------------
GAUGE = 0.90                 # ecartament de mina ingusta, nu cale ferata normala
RAIL_LEN = 9.00
SLEEPERS = 12
SLEEPER = (1.40, 0.20, 0.12)

BEVEL_PORTAL = 0.07

# Metri per repetitie, PE CLASA — aceleasi cifre ca la moara (build_windmill).
# O clasa care arata cu doua granulatii pe doua obiecte vecine nu mai e o clasa.
UV_WOOD = 1.2
UV_RUST = 2.2

STRATA = (ROCK_LIGHT, ROCK_DARK, ROCK_LIGHT)


def flatten_back(builder, y):
    """Reteaza tot ce trece in spatele planului y si il proiecteaza PE plan.

    `rock(wall_axis="y")` tine jumatatea dinspre -Y sa nu se retraga cu
    inaltimea, deci da un perete — dar unul tot perturbat. Portalul se lipeste de
    o faleza, iar 30 cm de neregularitate acolo inseamna ori o fanta prin care se
    vede cerul, ori movila infipta in perete. Taietura plana e singura care
    garanteaza contactul.
    """
    n = 0
    for v in builder.bm.verts:
        if v.co.y < y:
            v.co.y = y
            n += 1
    return n


def portal_rock(b):
    """Movila, din TREI mase: doi umeri si un capac peste deschidere.

    Prima versiune folosea o singura masa si panoul intunecat era pus "retras cu
    1.4 m in interiorul deschiderii", cum cere brieful. La render nu se vedea
    nimic, si motivul e evident dupa: movila e SOLIDA, deci panoul statea
    inauntrul ei si il ascundea propria fata din fata. Un gol care nu se taie
    trebuie sa fie spatiu INTRE mase — acelasi principiu ca la arcada din #C1.

    Umerii sunt inguste (2.5 m) fiindca o deschidere de 4 m intr-o movila de
    9 m nu lasa mai mult.

    `strata_slots` ramane in cod desi piesa merge acum pe textura de clasa, care
    nu citeste UV-uri: e sursa de adevar a formei (inelele raman despartite) si
    fallback-ul daca portalul se intoarce vreodata pe atlas.
    """
    for sx, seed in ((-1.0, 61), (1.0, 83)):
        b.rock((sx * 3.25, 0.6, 0.0), (2.5, MOUND[1] * 0.88, MOUND[2] * 0.92),
               ROCK_LIGHT, seed=seed, segments=6, rings=2, taper=0.30,
               squash=0.88, flat_top=True, wall_axis="y", strata_slots=STRATA)
    b.rock((0.0, 0.6, OPEN_H + 0.42), (MOUND[0], MOUND[1] * 0.82, MOUND[2] * 0.42),
           ROCK_LIGHT, seed=97, segments=6, rings=2, taper=0.42, squash=0.8,
           flat_top=True, wall_axis="y", strata_slots=STRATA)
    flatten_back(b, BACK_Y)


def portal_wood(b):
    """Cadrul de grinzi. Groase, nu zabrele: la 40 m o grinda de 15 cm dispare."""
    half = OPEN_W * 0.5 + POST_T * 0.5
    for sx in (-1.0, 1.0):
        b.box((sx * half, FRONT_Y, OPEN_H * 0.5), (POST_T, POST_T, OPEN_H), WOOD)
    lintel_z = OPEN_H + 0.20
    b.box((0.0, FRONT_Y, lintel_z), (OPEN_W + 2 * POST_T, POST_T, 0.40), WOOD)
    # Grinda de coronament, iesita 0.4 m in consola de fiecare parte
    b.box((0.0, FRONT_Y + 0.10, lintel_z + 0.45),
          (OPEN_W + 2 * POST_T + 0.80, POST_T * 1.1, 0.30), WOOD)
    # Doua contrafise la 45° in colturile de sus
    for sx in (-1.0, 1.0):
        rot = Matrix.Rotation(math.radians(sx * 45.0), 3, "Y")
        b.box((sx * (half - 0.55), FRONT_Y, OPEN_H - 0.55),
              (0.26, 0.26, 1.45), WOOD, rotation=rot)


def portal_trim(b):
    """Ce ramane pe ATLAS: gura minei si gramada de steril.

    Gura e ASPHALT, nu SAND_SHADOW cum cere brieful. Acelasi motiv ca la cabina
    excavatorului din #77: sand_shadow e #A97A4A, un maro mediu, si la render
    gura iesea o pata maronie, nu o gaura. Argumentul e cel din docstring-ul lui
    `window()` — "slotul cel mai inchis din lume citeste ca gol, nu ca sticla".
    Cel mai inchis slot legal e asphalt (5, #4B4B4D), iar adancimea falsa e tot
    efectul obiectului. De aceea piesa nu primeste nici textura de clasa:
    intunericul plat E continutul ei.

    Sterilul ramane si el pe atlas, la SAND_MID: pe clasa `rock` ar citi ca inca
    un bolovan, cand rostul lui e sa arate ca material desfacut si carat afara.
    """
    b.box((0.0, FRONT_Y - RECESS, OPEN_H * 0.5),
          (OPEN_W + 0.6, 0.16, OPEN_H + 0.4), ASPHALT)
    # Brieful spune ca sterilul spune "mina activa" mai tare decat portalul
    # insusi, si are dreptate: un portal fara steril e o usa in stanca.
    b.rock((5.10, 2.30, 0.0), (4.0, 3.0, 1.5), SAND_MID,
           seed=137, segments=6, rings=2, taper=0.50, squash=0.7)


def rail_wood(b):
    for i in range(SLEEPERS):
        # Ultimele traverse se rar-esc: linia se PIERDE, nu se opreste curat.
        t = i / (SLEEPERS - 1)
        y = RAIL_LEN * (t + 0.10 * t * t)
        b.box((0.0, y, SLEEPER[2] * 0.5), SLEEPER, WOOD)


def rail_metal(b):
    for sx in (-1.0, 1.0):
        x = sx * GAUGE * 0.5
        z = SLEEPER[2] + 0.06
        b.beam((x, -0.10, z), (x, RAIL_LEN * 0.78, z), (0.10, 0.12), RUST)
        # capatul frant, usor ridicat
        b.beam((x, RAIL_LEN * 0.78, z), (x + sx * 0.10, RAIL_LEN * 0.99, z + 0.26),
               (0.10, 0.12), RUST)


# Vagonet RASTURNAT. Un obiect rasturnat spune o poveste; unul drept e mobilier
# — si costa exact la fel.
CART_TIP = Matrix.Rotation(math.radians(74.0), 3, "Y")


def cart_wood(b):
    b.box((0.0, 0.0, 0.62), (1.60, 1.00, 0.90), WOOD, rotation=CART_TIP)


def cart_metal(b):
    b.box((0.10, 0.0, 0.20), (1.30, 0.80, 0.16), RUST, rotation=CART_TIP)
    # Patru roti. Doua se vad, doua raman pe jumatate in nisip — de aia sunt
    # coborate sub zero: originea grupului se ia pe ANSAMBLU, deci ingroparea se
    # face fata de restul vagonetului, nu fata de sol.
    for sy in (-1.0, 1.0):
        for (dx, dz) in ((-0.52, 0.72), (0.46, 0.30)):
            b.cylinder((dx, sy * 0.42, dz), 0.22, 0.14, RUST, segments=6, axis="Y")


def cart_trim(b):
    """Bucatile de minereu. Raman pe atlas ca sa pastreze culoarea de material
    desfacut (SAND_MID); pe `wood` ar deveni aschii, pe `rust_metal` fier."""
    for (px, py, s, seed) in ((1.15, 0.55, 0.24, 7), (0.85, -0.70, 0.20, 19)):
        b.rock((px, py, 0.0), (s * 1.2, s, s * 0.8), SAND_MID,
               seed=seed, segments=5, rings=1, taper=0.4, squash=0.8)


# --- NOTA DE BUGET ------------------------------------------------------------
# Brieful cere bevel 0.06 pe lemn si vagonet, 0.12 pe stanca. Portalul il tine;
# celelalte doua nu, si nu e aproape:
#
#   MineRail  192 brut. Cu bevel: 192 x 3.67 = 705, la un buget de 250.
#   MineCart  136 brut. Cu bevel: 136 x 3.67 = 499, la un buget de 150.
#
# Nu exista taiere care sa le salveze: 12 traverse SUNT sina, iar patru roti sunt
# un vagonet. Si, spre deosebire de portal, aici bevel-ul nici nu se vede — o
# tesitura de 6 cm pe o traversa de 0.20 m inseamna 30% din piesa, adica lemn
# umflat, nu lemn cioplit. Clasele de bevel din style_bible §3 sunt proportionale
# cu obiectul; astea sunt sub pragul unde bevel-ul mai adauga ceva.
BEVEL_SMALL = 0.0

AO_PORTAL = dict(samples=28, dist=4.0, gradient="vertical", low=0.42, high=1.00,
                 power=0.85, floor=0.10)
AO_SMALL = dict(samples=20, dist=1.5, gradient="vertical", low=0.55, high=1.00,
                power=1.0, floor=0.14)

# grup -> (buget, bevel, spec AO, [(nume piesa, umplere, marime UV cub | None)])
GROUPS = [
    ("Portal", 600, BEVEL_PORTAL, AO_PORTAL, [
        ("Portal_Rock", portal_rock, None),
        ("Portal_Wood", portal_wood, UV_WOOD),
        ("Portal_Trim", portal_trim, None),
    ]),
    ("MineRail", 250, BEVEL_SMALL, AO_SMALL, [
        ("MineRail_Wood", rail_wood, UV_WOOD),
        ("MineRail_Metal", rail_metal, UV_RUST),
    ]),
    ("MineCart", 150, BEVEL_SMALL, AO_SMALL, [
        ("MineCart_Wood", cart_wood, UV_WOOD),
        ("MineCart_Metal", cart_metal, UV_RUST),
        ("MineCart_Trim", cart_trim, None),
    ]),
]

clear_built("Portal")
clear_built("Mine")

objs = []
total = 0
for group, budget, bevel, ao, parts in GROUPS:
    # Un grup se construieste INTAI intreg, ca sa i se stie cotele: originea si
    # gradientul de AO sunt proprietati ale ANSAMBLULUI, nu ale piesei. Fara
    # asta, fiecare piesa si-ar coace un gradient complet pe portiunea ei si
    # cadrul de lemn ar iesi la fel de umbrit la baza ca movila de 8 m in care e
    # infipt (vezi `z_range` in dio_lib.bake_ao).
    raw = []
    for name, fill, uv_size in parts:
        b = Builder()
        fill(b)
        raw.append((name, b.to_object(name), uv_size))
    allv = [v.co for _, o, _ in raw for v in o.data.vertices]
    lo = Vector((min(v.x for v in allv), min(v.y for v in allv),
                 min(v.z for v in allv)))
    hi = Vector((max(v.x for v in allv), max(v.y for v in allv),
                 max(v.z for v in allv)))
    # Originea grupului: la baza, centrata in XY (Blender) — echivalentul lui
    # finish(origin="base") pe obiectul nesparte.
    shift = Vector((-(lo.x + hi.x) * 0.5, -(lo.y + hi.y) * 0.5, -lo.z))
    z_span = (lo.z + shift.z, hi.z + shift.z)

    group_tris = 0
    for name, obj, uv_size in raw:
        for v in obj.data.vertices:
            v.co += shift
        stats = finish(obj, bevel=bevel, ao=dict(ao, z_range=z_span),
                       origin=None)
        if uv_size is not None:
            cube_uvs(obj, uv_size)
        group_tris += stats["tris"]
        print("  %-16s %3d tris | AO %.2f..%.2f | uv=%s"
              % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
                 "cub %.1f m" % uv_size if uv_size else "atlas/triplanar"))
        objs.append(obj)

    total += group_tris
    size = hi - lo
    print("%-9s %3d tris (buget %3d) %s | %.2f x %.2f x %.2f m"
          % (group, group_tris, budget,
             "OK    " if group_tris <= budget else "DEPASIT",
             size.x, size.y, size.z))
    if group == "Portal":
        print("   spate plat la Y = %+.3f fata de origine "
              "(Godot -Z e +Y in Blender)" % (lo.y + shift.y))
        print("   deschidere %.2f x %.2f m, gura retrasa cu %.2f m"
              % (OPEN_W, OPEN_H, RECESS))
    if group == "MineRail":
        print("   capatul dinspre gura la Y = %+.3f fata de origine"
              % (lo.y + shift.y))

print("TOTAL: %d tris (buget 1000) %s" % (total, "OK" if total <= 1000 else "DEPASIT"))

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "buildings/mine_portal.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "mine_portal.blend"))
