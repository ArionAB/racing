"""mine_portal.glb — intrare de mina cu sina ingusta si vagonet rasturnat.
Brief: docs/asset_briefs/mine_portal.md · issue #C2

Al doilea landmark nou. Avantajul lui peste celelalte candidate e ca se leaga de
ce e deja in joc: pista are un tren care traverseaza soseaua
(`scenes/hazards/train_hazard.gd`, la frac 0.37), iar o mina cu vagonet si sina
ingusta explica de ce exista o cale ferata in mijlocul desertului.

Trei obiecte, fiecare cu ORIGINEA LUI la baza, centrata in XZ:
  Portal     <= 600 tris
  MineRail   <= 250
  MineCart   <= 150

Separarea e intentionata, nu comoditate: instanta de gameplay poate aseza sina
si vagonetul departe de portal, sau langa calea ferata existenta. Aici originea
per piesa e CORECTA — spre deosebire de arcada din #C1, unde cele cinci noduri
formeaza un singur obiect si trebuie sa-si pastreze pozitiile relative.

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


def build_portal():
    b = Builder()

    # Movila, din TREI mase: doi umeri si un capac peste deschidere.
    #
    # Prima versiune folosea o singura masa si panoul intunecat era pus "retras cu
    # 1.4 m in interiorul deschiderii", cum cere brieful. La render nu se vedea
    # nimic, si motivul e evident dupa: movila e SOLIDA, deci panoul statea
    # inauntrul ei si il ascundea propria fata din fata. Un gol care nu se taie
    # trebuie sa fie spatiu INTRE mase — acelasi principiu ca la arcada din #C1.
    #
    # Umerii sunt inguste (2.5 m) fiindca o deschidere de 4 m intr-o movila de
    # 9 m nu lasa mai mult.
    strata = (ROCK_LIGHT, ROCK_DARK, ROCK_LIGHT)
    for sx, seed in ((-1.0, 61), (1.0, 83)):
        b.rock((sx * 3.25, 0.6, 0.0), (2.5, MOUND[1] * 0.88, MOUND[2] * 0.92),
               ROCK_LIGHT, seed=seed, segments=6, rings=2, taper=0.30,
               squash=0.88, flat_top=True, wall_axis="y", strata_slots=strata)
    b.rock((0.0, 0.6, OPEN_H + 0.42), (MOUND[0], MOUND[1] * 0.82, MOUND[2] * 0.42),
           ROCK_LIGHT, seed=97, segments=6, rings=2, taper=0.42, squash=0.8,
           flat_top=True, wall_axis="y", strata_slots=strata)
    flatten_back(b, BACK_Y)

    # Gura: un panou plat, retras in golul dintre umeri. Acum chiar se vede.
    #
    # ASPHALT, nu SAND_SHADOW cum cere brieful. Acelasi motiv ca la cabina
    # excavatorului din #77: sand_shadow e #A97A4A, un maro mediu, si la render
    # gura iesea o pata maronie, nu o gaura. Argumentul e cel din docstring-ul
    # lui `window()` — "slotul cel mai inchis din lume citeste ca gol, nu ca
    # sticla". Cel mai inchis slot legal e asphalt (5, #4B4B4D), iar adancimea
    # falsa e tot efectul obiectului.
    b.box((0.0, FRONT_Y - RECESS, OPEN_H * 0.5),
          (OPEN_W + 0.6, 0.16, OPEN_H + 0.4), ASPHALT)

    # Cadrul de grinzi. Groase, nu zabrele: la 40 m o grinda de 15 cm dispare.
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

    # Gramada de steril. Brieful spune ca asta spune "mina activa" mai tare decat
    # portalul insusi, si are dreptate: un portal fara steril e o usa in stanca.
    b.rock((5.10, 2.30, 0.0), (4.0, 3.0, 1.5), SAND_MID,
           seed=137, segments=6, rings=2, taper=0.50, squash=0.7)
    return b


def build_rail():
    """Sina care iese din gura. BEVEL 0 — vezi nota de buget."""
    b = Builder()
    for i in range(SLEEPERS):
        # Ultimele traverse se rar-esc: linia se PIERDE, nu se opreste curat.
        t = i / (SLEEPERS - 1)
        y = RAIL_LEN * (t + 0.10 * t * t)
        b.box((0.0, y, SLEEPER[2] * 0.5), SLEEPER, WOOD)
    for sx in (-1.0, 1.0):
        x = sx * GAUGE * 0.5
        z = SLEEPER[2] + 0.06
        b.beam((x, -0.10, z), (x, RAIL_LEN * 0.78, z), (0.10, 0.12), RUST)
        # capatul frant, usor ridicat
        b.beam((x, RAIL_LEN * 0.78, z), (x + sx * 0.10, RAIL_LEN * 0.99, z + 0.26),
               (0.10, 0.12), RUST)
    return b


def build_cart():
    """Vagonet RASTURNAT. Un obiect rasturnat spune o poveste; unul drept e
    mobilier — si costa exact la fel."""
    b = Builder()
    tip = Matrix.Rotation(math.radians(74.0), 3, "Y")
    b.box((0.0, 0.0, 0.62), (1.60, 1.00, 0.90), WOOD, rotation=tip)
    b.box((0.10, 0.0, 0.20), (1.30, 0.80, 0.16), RUST, rotation=tip)
    # Patru roti. Doua se vad, doua raman pe jumatate in nisip — de aia sunt
    # coborate sub zero: `finish(origin="base")` ridica tot ansamblul, deci
    # ingroparea se face fata de restul vagonetului, nu fata de sol.
    for sy in (-1.0, 1.0):
        for k, (dx, dz) in enumerate(((-0.52, 0.72), (0.46, 0.30))):
            b.cylinder((dx, sy * 0.42, dz), 0.22, 0.14, RUST, segments=6, axis="Y")
    # bucati de minereu
    for (px, py, s, seed) in ((1.15, 0.55, 0.24, 7), (0.85, -0.70, 0.20, 19)):
        b.rock((px, py, 0.0), (s * 1.2, s, s * 0.8), SAND_MID,
               seed=seed, segments=5, rings=1, taper=0.4, squash=0.8)
    return b


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

clear_built("Portal")
clear_built("Mine")

PIECES = [
    ("Portal", build_portal, 600, BEVEL_PORTAL,
     dict(samples=28, dist=4.0, gradient="vertical", low=0.42, high=1.00,
          power=0.85, floor=0.22)),
    ("MineRail", build_rail, 250, BEVEL_SMALL,
     dict(samples=20, dist=1.5, gradient="vertical", low=0.55, high=1.00,
          power=1.0, floor=0.32)),
    ("MineCart", build_cart, 150, BEVEL_SMALL,
     dict(samples=20, dist=1.5, gradient="vertical", low=0.55, high=1.00,
          power=1.0, floor=0.32)),
]

objs = []
total = 0
for name, fn, budget, bev, ao in PIECES:
    obj = fn().to_object(name)
    stats = finish(obj, bevel=bev, ao=ao, origin="base")
    me = obj.data
    ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
           for a in range(3)]
    total += stats["tris"]
    print("%-9s %3d tris (buget %3d) %s | %.2f x %.2f x %.2f m | AO %.2f..%.2f"
          % (name, stats["tris"], budget,
             "OK    " if stats["tris"] <= budget else "DEPASIT",
             ext[0][1] - ext[0][0], ext[1][1] - ext[1][0], ext[2][1] - ext[2][0],
             stats["ao_min"], stats["ao_max"]))
    if name == "Portal":
        print("   spate plat la Y = %+.3f fata de origine (Godot -Z e +Y in Blender)"
              % ext[1][0])
        print("   deschidere %.2f x %.2f m, gura retrasa cu %.2f m" % (OPEN_W, OPEN_H, RECESS))
    if name == "MineRail":
        print("   capatul dinspre gura la Y = %+.3f fata de origine" % ext[1][0])
    objs.append(obj)

print("TOTAL: %d tris (buget 1000) %s" % (total, "OK" if total <= 1000 else "DEPASIT"))

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "mine_portal.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "mine_portal.blend"))
