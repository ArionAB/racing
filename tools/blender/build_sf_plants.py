"""San Francisco -- vegetatia valului 2 (docs/asset_briefs/sanfrancisco_inventory.md §5.4).

  sanfrancisco/plants/sf_cypress_a.glb      V1 chiparos de Monterey, un singur trunchi aplecat
  sanfrancisco/plants/sf_cypress_b.glb      V1 chiparos cu doua trunchiuri, lat
  sanfrancisco/plants/sf_cypress_c.glb      V1 chiparos mic, compact
  sanfrancisco/plants/sf_hydrangea.glb      V3 tufa de hortensii, roz cu putin albastru
  sanfrancisco/plants/sf_hydrangea_blue.glb V3 aceeasi tufa, albastra cu putin roz
  sanfrancisco/plants/sf_street_tree.glb    V4 arbore de strada cu coroana rotunda
  sanfrancisco/props/sf_front_garden.glb    N2 gradinita de 7 x 3 m din fata casei

Arborii sunt COROANA PUNCTATA (Palette.CROWN_PREFIX, ca artarii Kyoto): patru noduri,
`*_Trunk` (atlas), `*_Crown` (masa de departe, ascunsa de WorldProp), `*_Core` (miezul
neluminat) si `*_Leaves` (cardurile punctate, assets/shaders/leaf_cards.gdshader).
Hortensia si gradinita sunt un singur nod pe atlas (zero materiale noi).

Vantul vine din -X si bate spre +X: toti chiparosii se apleaca spre +X, deci un palc pus
cu yaw 0 se citeste modelat de vant. Originea arborilor = baza trunchiului (coroana e
aplecata, deci NU e centrul cutiei); a gradinitei = centrul amprentei de 7 x 3.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_plants.py [-- --cypress]
"""

import math
import sys
from mathutils import Vector

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "sf_plant_shapes.py"), encoding="utf-8").read())

BARK = LOG_DARK          # 28 #4A3526, lemnul inchis (inventar V1)
BARK_LIGHT = WOOD        # 9 #835C34, crestele fibrei rasucite
CYPRESS_GREEN = TROPICAL_GREEN   # 21: masa de departe si miezul
STREET_GREEN = CACTUS_GREEN      # 12: coroana arborelui de strada (inventar V4)

AO_TREE = dict(gradient="vertical", samples=20, dist=3.2, low=0.55, high=1.0,
               power=0.8, floor=0.30)
AO_SMALL = dict(gradient="vertical", samples=24, dist=0.6, low=0.55, high=1.0,
                power=0.9, floor=0.30)
AO_GARDEN = dict(gradient="vertical", samples=24, dist=0.8, low=0.85, high=1.0,
                 power=0.9, floor=0.35)

# Cardurile: (numar, verde de baza, sclipirile de pe crestete). Verdele chiparosului e
# adanc si putin RECE (albastrui in umbra, vezi sf_leaf_cards), ca sa nu se faca maro-oliv
# in lumina calda de apus; sclipirile sunt galben-verzi, ca petele de soare din decupare.
CYP_CARDS = {"a": (820, "41784A", "8DAE58"),
             "b": (790, "41784A", "8DAE58"),
             "c": (620, "41784A", "8DAE58")}
STREET_CARDS = (205, "8FA83A", "CBD05C")
# Masa de departe (`*_Crown`, doar in MeshForest) nu are grosimea cardurilor (~0,7 m in plus
# pe verticala): se ingroasa putin, ca polita de departe sa aiba aceeasi grosime vizuala.
FAR_UP_K, FAR_DN_K = 1.25, 1.2
SMOOTH_TREE = {"_Trunk": 70.0, "_Crown": 80.0}

clear_built()


# ---------------------------------------------------------------------------
# Chiparosii (V1) -- v2 (verdictul coordonatorului, 16 nov 2026)
#
# v1 citea pin tuns in nori (niwaki: perne-bila stivuite pe un trunchi zvelt, ~10 x 9 m),
# adica silueta pinului niwaki din Kyoto -- iar inventarul cere ca doua piste sa nu imparta
# silueta unui arbore. v2 urmeaza decuparile: arbore MAI LAT DECAT INALT (h/l ~0,6), POLITE
# lungi si plate (4-7 m pe X, 2,5-4 m pe Z, <= ~1,3 m grosime), bonte in vant (-X) si
# ascutite in coada spre +X; trunchi masiv si scurt cu furca joasa si crengi groase care
# merg aproape ORIZONTAL spre +X sub fiecare polita.
# ---------------------------------------------------------------------------

def shelf(x0, x1, z, y=0.0, depth=3.0, thick=0.62, lobes=4, rise=0.25, wobble=0.25, k=0.72):
    """O POLITA de frunzis: `lobes` ciorchini care se suprapun ca tiglele, de la capatul bont
    din vant (x0, cel mai mare si mai gros) spre coada ascutita din +X (x1). Semi-axa pe X a
    lobului i e A * k^i, centrele la 0,62 x (a_i + a_i+1) unul de altul, A ales ca polita sa
    aiba exact lungimea x1 - x0. Adancimea (pe Y Blender = Z Godot) si grosimea scad si ele
    spre coada; polita urca usor (`rise`) spre +X, ca tiglele unui acoperis.
    Intoarce lista de ciorchini (cx, cy, cz, ax, ay, az_sus, az_jos)."""
    ws = [k ** i for i in range(lobes)]
    span = ws[0] + sum(0.62 * (ws[i] + ws[i + 1]) for i in range(lobes - 1)) + ws[-1]
    A = (x1 - x0) / span
    out = []
    cx = x0 + A * ws[0]
    for i in range(lobes):
        t = i / max(lobes - 1, 1)
        ax = A * ws[i]
        ay = depth * 0.5 * (0.86 ** i)
        th = thick * (0.78 ** i)
        cy = y + wobble * (1 if i % 2 else -1) * (0.5 + 0.5 * t)
        out.append((cx, cy, z + rise * t, ax, ay, th * 0.62, th * 0.38))
        if i < lobes - 2:
            # smocul de pe crestet (decuparea: politele au crestetul in bulgari de nor, nu
            # o tabla): un lob mai mic, ridicat, spre vant pe primele polite
            out.append((cx - ax * 0.25, cy - wobble * 0.6, z + rise * t + th * 0.42,
                        ax * 0.55, ay * 0.6, th * 0.42, th * 0.22))
        if i < lobes - 1:
            cx += 0.62 * (A * ws[i] + A * ws[i + 1])
    return out


def _cypress(trunks, limbs, shelves, cards, seed, roots):
    """trunks: [(puncte, raze, faza)], limbs: [(puncte, r0, r1)], shelves: liste de ciorchini
    (din `shelf`), roots: (raza bazei, numar de contraforturi). Intoarce cele patru noduri."""
    tr, cr, co, lv = Builder(), Builder(), Builder(), Builder()
    # r3 a plansei v2: politele ieseau de ~0,9 m vizual, mai subtiri decat in decupare;
    # grosimea masei x1,3 => ~1,2-1,3 m vizual pe capatul bont, coada ramane subtire
    pads = [(x, y, z, ax, ay, azu * 1.3, azd * 1.3) for s in shelves for (x, y, z, ax, ay, azu, azd) in s]
    for (pts, radii, phase) in trunks:
        # 9 laturi / 3 caneluri: 3 varfuri pe canelura (cu 10/4 crestele aliasau)
        twisted_trunk(tr, pts, radii, BARK, BARK_LIGHT, segments=9, flutes=3, depth=0.15,
                      turns=0.6, phase=phase, crest=0.35)
    root_flare(tr, roots[0], roots[1], BARK, seed=seed, height=1.0, reach=1.6, thick=0.46,
               segments=7)
    for (pts, r0, r1) in limbs:
        limb(tr, pts, r0, r1, BARK, segments=6)
    for k, (x, y, z, ax, ay, azu, azd) in enumerate(pads):
        pad_mass(cr, (x, y, z, ax * 1.04, ay * 1.04, azu * FAR_UP_K, azd * FAR_DN_K),
                 CYPRESS_GREEN, seg=7, seed=seed * 31 + k, lobe=0.10)
    core_lens(co, pads, CYPRESS_GREEN, shrink=0.85, seg=6)
    n = sf_leaf_cards(lv, pads, CYPRESS_GREEN, cards[0], cards[1], accent_hex=cards[2],
                      seed=seed, size=(0.72, 0.98), shell=(0.86, 1.05), below=0.15,
                      radial=0.10, accent=0.30, shade_lo=0.50, size_by_pad=True)
    print("  carduri:", n)
    return (tr.to_object("Cypress_Trunk"), cr.to_object("Cypress_Crown"),
            co.to_object("Cypress_Core"), lv.to_object("Cypress_Leaves"))


def build_cypress_a():
    """`sf_cypress_a.png` -- UN SINGUR TRUNCHI APLECAT (v2). Lista de elemente:

    1. trunchi MASIV si scurt (O baza ~1,9 m), rasucit (caneluri in spirala, creste mai
       deschise), care se culca spre +X;
    2. 5 contraforturi de radacina mari;
    3. furca JOASA (~2 m): liderul urca aplecat spre +X pana sub polita de sus;
    4. creanga groasa (O ~0,8 m) aproape ORIZONTALA spre +X care poarta polita joasa din
       dreapta (~3,7 m), coada pana la +8 m;
    5. creanga scurta spre -X (in vant) cu perna mica si bonta din stanga (~2,6 m);
    6. creanga spre stanga-sus la polita de MIJLOC (~5,1 m), de la -2,4 la +4,4;
    7. polita de SUS (~7 m), cea mai lunga, de la +0,4 la +7,4: depaseste baza cu peste
       7 m pe +X si se termina in coada ascutita;
    8. politele sunt plate (<= ~1,3 m), bonte in vant si ascutite in coada, suprapuse ca
       tiglele, cu GOL intre ele prin care se vad crengile orizontale;
    9. ansamblu MAI LAT DECAT INALT (~12 x ~7,8 m), masa deplasata spre +X.
    """
    trunks = [([(0, 0, 0), (0.2, 0, 0.7), (0.7, 0, 1.4), (1.5, 0, 1.95), (2.4, 0, 2.65),
                (2.9, 0, 3.6), (3.0, 0, 4.7), (3.2, 0, 5.7), (3.6, 0, 6.7)],
               [0.95, 0.82, 0.72, 0.64, 0.55, 0.46, 0.38, 0.30, 0.22], 0.0)]
    limbs = [
        ([(1.6, 0, 2.0), (3.0, 0.1, 2.75), (4.6, 0.05, 3.25), (6.2, 0, 3.55)], 0.40, 0.14),
        ([(0.6, 0, 1.1), (-0.8, 0.05, 1.65), (-2.0, 0.1, 2.15), (-2.8, 0, 2.4)], 0.34, 0.12),
        ([(2.6, 0, 3.0), (1.5, 0, 3.95), (0.3, 0.05, 4.6), (-1.0, 0.1, 4.95)], 0.36, 0.12),
        ([(2.95, 0, 4.3), (3.3, 0.5, 4.75)], 0.24, 0.10),
        ([(3.3, 0, 6.1), (4.8, 0.05, 6.65), (6.2, 0, 6.95)], 0.22, 0.09),
        ([(3.5, 0, 6.6), (2.3, 0.05, 6.85), (1.2, 0, 6.95)], 0.18, 0.08),
        ([(2.95, 0, 4.1), (2.8, -1.0, 4.8), (2.7, -1.5, 5.0)], 0.18, 0.08),
        ([(3.15, 0, 5.4), (3.3, 1.0, 6.3), (3.5, 1.4, 6.8)], 0.16, 0.08),
    ]
    shelves = [
        shelf(0.4, 7.4, 7.0, y=0.0, depth=3.8, thick=0.70, lobes=4, rise=0.25),
        shelf(-2.4, 4.4, 5.05, y=0.7, depth=3.4, thick=0.64, lobes=4, rise=0.2),
        shelf(3.6, 8.0, 3.6, y=-0.8, depth=2.8, thick=0.58, lobes=3, rise=0.15),
        shelf(-4.0, -1.5, 2.55, y=0.4, depth=2.5, thick=0.56, lobes=2, rise=0.05),
    ]
    return _cypress(trunks, limbs, shelves, CYP_CARDS["a"], seed=3, roots=(0.95, 5))


def build_cypress_b():
    """`sf_cypress_b.png` -- URIASUL CU DOUA TRUNCHIURI (v2). Lista de elemente:

    1. baza ENORMA (O ~2,2 m) din care pleaca doua trunchiuri rasucite, lipite jos;
    2. 6 contraforturi de radacina mari;
    3. trunchiul stang urca abrupt, apoi se apleaca spre +X: poarta polita de sus din STANGA
       (~6,3 m) si, printr-o creanga joasa spre -X, perna bonta din vant (~3,1 m);
    4. trunchiul drept se culca puternic spre +X de la baza: poarta polita de sus din
       DREAPTA (~7,6 m, cea mai inalta si cea mai lunga, coada pana la +8,2 m), polita de
       mijloc din dreapta (~4,8 m) pe o creanga orizontala si polita joasa din dreapta
       (~2,8 m);
    5. o creanga spre centru cu polita centrala (~4,6 m);
    6. politele sunt plate, bonte in vant si ascutite spre +X, suprapuse in trepte;
    7. ansamblu mult MAI LAT DECAT INALT (~12,4 x ~8,4 m), masa spre +X.
    """
    trunks = [
        ([(-0.45, 0, 0), (-0.9, 0, 0.9), (-1.3, 0, 1.9), (-1.2, 0, 3.0), (-0.7, 0, 4.0),
          (-0.1, 0, 4.9), (0.4, 0, 5.6), (0.7, 0, 6.1)],
         [0.90, 0.78, 0.66, 0.56, 0.48, 0.40, 0.32, 0.24], 0.0),
        ([(0.45, 0, 0), (1.1, 0, 0.7), (2.0, 0, 1.4), (3.0, 0, 2.1), (3.9, 0, 3.0),
          (4.5, 0, 4.1), (4.8, 0, 5.4), (4.9, 0, 6.6), (4.9, 0, 7.3)],
         [0.95, 0.82, 0.70, 0.60, 0.50, 0.42, 0.34, 0.26, 0.18], 1.3),
    ]
    limbs = [
        ([(-1.3, 0, 1.8), (-2.2, 0.1, 2.4), (-2.9, 0.05, 2.9)], 0.36, 0.12),
        ([(0.2, 0, 5.6), (-0.9, 0.1, 6.0), (-2.0, 0, 6.2)], 0.26, 0.10),
        ([(0.5, 0, 6.0), (1.6, 0, 6.25)], 0.20, 0.10),
        ([(-0.85, 0, 3.7), (0.4, 0.05, 4.2), (1.8, 0, 4.5)], 0.30, 0.10),
        ([(4.4, 0, 4.0), (5.6, 0.05, 4.5), (7.0, 0, 4.8)], 0.36, 0.12),
        ([(3.0, 0, 2.1), (4.4, 0.05, 2.5), (6.0, 0, 2.75)], 0.34, 0.12),
        ([(4.9, 0, 6.8), (3.4, 0.1, 7.3), (2.2, 0, 7.5)], 0.22, 0.10),
        ([(4.9, 0, 7.0), (6.4, 0, 7.5)], 0.20, 0.10),
        ([(4.6, 0, 4.6), (4.4, -1.0, 5.3)], 0.18, 0.08),
        ([(-0.3, 0, 4.6), (-0.4, 1.0, 5.3)], 0.18, 0.08),
    ]
    shelves = [
        shelf(1.4, 8.2, 7.55, y=0.0, depth=3.9, thick=0.70, lobes=4, rise=0.25),
        shelf(-3.0, 2.6, 6.3, y=0.6, depth=3.4, thick=0.64, lobes=4, rise=0.2),
        shelf(2.9, 8.2, 4.85, y=-0.8, depth=3.2, thick=0.62, lobes=4, rise=0.15),
        shelf(-1.0, 3.4, 4.55, y=1.0, depth=2.8, thick=0.56, lobes=3, rise=0.15),
        shelf(4.7, 8.0, 2.85, y=0.5, depth=2.6, thick=0.54, lobes=3, rise=0.1),
        shelf(-4.2, -1.6, 3.1, y=-0.3, depth=2.6, thick=0.56, lobes=2, rise=0.05),
    ]
    return _cypress(trunks, limbs, shelves, CYP_CARDS["b"], seed=7, roots=(1.1, 6))


def build_cypress_c():
    """`sf_cypress_c.png` -- MIC, COMPACT (v2). Lista de elemente:

    1. trunchi gros si scurt (O baza ~1,65 m) in S, culcat spre +X, rasucit;
    2. 5 contraforturi de radacina;
    3. furca joasa: creanga lunga spre -X (in vant) cu perna bonta din stanga (~2,6 m);
    4. polita joasa din dreapta (~2,4 m) pe o creanga orizontala spre +X;
    5. polita de mijloc din dreapta (~4,3 m);
    6. polita de SUS (~6,3 m), de la -0,4 la +5,8, coada ascutita spre +X;
    7. mai mic si mai strans decat a si b (~9,4 x ~7,1 m), tot mai lat decat inalt.
    """
    trunks = [([(0, 0, 0), (0.4, 0, 0.7), (1.0, 0, 1.4), (1.6, 0, 2.1), (2.0, 0, 3.0),
                (2.1, 0, 4.0), (2.3, 0, 5.0), (2.6, 0, 5.8)],
               [0.83, 0.72, 0.62, 0.54, 0.46, 0.38, 0.30, 0.22], 0.6)]
    limbs = [
        ([(0.5, 0, 0.9), (-0.7, 0.05, 1.6), (-1.8, 0.1, 2.2), (-2.4, 0, 2.45)], 0.30, 0.10),
        ([(1.6, 0, 2.1), (2.8, 0.05, 2.3), (4.0, 0, 2.5)], 0.30, 0.10),
        ([(2.1, 0, 3.7), (3.4, 0.05, 4.0), (4.6, 0, 4.2)], 0.26, 0.10),
        ([(2.5, 0, 5.6), (1.2, 0.05, 6.0), (0.4, 0, 6.2)], 0.20, 0.08),
        ([(2.6, 0, 5.8), (4.0, 0, 6.2), (5.0, 0, 6.35)], 0.20, 0.08),
        ([(2.1, 0, 4.2), (2.0, -1.0, 4.9)], 0.15, 0.08),
    ]
    shelves = [
        shelf(-0.4, 5.8, 6.3, y=0.0, depth=3.4, thick=0.66, lobes=4, rise=0.2),
        shelf(1.6, 6.0, 4.3, y=-0.7, depth=3.0, thick=0.60, lobes=3, rise=0.15),
        shelf(2.0, 5.6, 2.45, y=0.6, depth=2.6, thick=0.54, lobes=3, rise=0.1),
        shelf(-3.4, -0.7, 2.65, y=0.3, depth=2.5, thick=0.56, lobes=2, rise=0.05),
    ]
    return _cypress(trunks, limbs, shelves, CYP_CARDS["c"], seed=11, roots=(0.83, 5))


# ---------------------------------------------------------------------------
# Arborele de strada (V4)
# ---------------------------------------------------------------------------

def build_street_tree():
    """`sf_street_tree.png` -- COROANA ROTUNDA PE TRUNCHI DREPT. Lista de elemente:

    1. trunchi DREPT, GROS, vertical (O ~0,58 m la baza), cu o evazare mica de radacini;
    2. furca la ~2,2 m in 5 crengi groase care urca oblic si INTRA in coroana (in decupare
       se vad intre ciorchinii de jos);
    3. coroana ROTUNDA, O ~4,7 m, de la ~2,6 la ~7 m, din 8 ciorchini (1 sus, 3 in inelul
       de sus, 4 in inelul de jos) -- bulgari, nu o sfera neteda;
    4. verde-galbui (lime-oliv), alt verde decat chiparosul, ca strada sa nu se confunde cu
       parcul;
    5. (decuparea are o rama patrata de groapa in trotuar: NU e in GLB, vezi raportul --
       pe panta de 28 % a lantului o rama plata de 1,3 m ar pluti 18 cm pe o latura.)
    Cote: ~7,0 m inalt, coroana ~4,7 m (X si Z).
    """
    tr, cr, co, lv = Builder(), Builder(), Builder(), Builder()
    twisted_trunk(tr, [(0, 0, 0), (0.0, 0.0, 0.8), (0.02, 0.0, 1.6), (0.0, 0.02, 2.35)],
                  [0.29, 0.25, 0.23, 0.21], BARK, BARK_LIGHT, segments=8, flutes=3,
                  depth=0.10, turns=0.35)
    root_flare(tr, 0.30, 5, BARK, seed=5, height=0.55, reach=1.45, thick=0.16, segments=5)
    for (pts, r0, r1) in (
            ([(0.0, 0, 2.1), (0.75, 0.1, 2.9), (1.15, 0.15, 3.7)], 0.16, 0.08),
            ([(0.0, 0, 2.1), (-0.7, -0.2, 2.9), (-1.1, -0.3, 3.7)], 0.16, 0.08),
            ([(0.0, 0, 2.1), (-0.2, 0.75, 3.0), (-0.3, 1.1, 3.8)], 0.15, 0.08),
            ([(0.0, 0, 2.1), (0.25, -0.75, 3.0), (0.35, -1.0, 3.9)], 0.15, 0.08),
            ([(0.0, 0, 2.2), (0.05, 0.0, 3.4), (0.1, -0.1, 4.8)], 0.15, 0.08)):
        limb(tr, pts, r0, r1, BARK, segments=5)
    pads = [(0.0, 0.0, 5.75, 1.30, 1.30, 0.88, 0.70)]
    for k in range(3):
        a = 2.0 * math.pi * k / 3 + 0.4
        pads.append((math.cos(a) * 1.12, math.sin(a) * 1.12, 4.95, 1.15, 1.15, 0.80, 0.70))
    for k in range(4):
        a = 2.0 * math.pi * k / 4 + 0.15
        pads.append((math.cos(a) * 1.28, math.sin(a) * 1.28, 3.8, 1.05, 1.05, 0.75, 0.62))
    for k, p in enumerate(pads):
        pad_mass(cr, p, STREET_GREEN, seg=6, seed=50 + k, lobe=0.10)
    # miezul: UN glob pe toata coroana, nu o lentila pe ciorchine (r2: lentilele turtite
    # se vedeau printre carduri ca romburi negre)
    core_blob(co, (0.0, 0.0, 4.75), 1.55, 1.55, 1.45, STREET_GREEN)
    n = sf_leaf_cards(lv, pads, STREET_GREEN, STREET_CARDS[0], STREET_CARDS[1],
                      accent_hex=STREET_CARDS[2], seed=19, size=(0.80, 1.10),
                      shell=(0.82, 1.08), below=0.35, radial=0.45, shade_lo=0.55,
                      accent=0.32)
    print("  carduri:", n)
    return (tr.to_object("StreetTree_Trunk"), cr.to_object("StreetTree_Crown"),
            co.to_object("StreetTree_Core"), lv.to_object("StreetTree_Leaves"))


# ---------------------------------------------------------------------------
# Hortensia (V3)
# ---------------------------------------------------------------------------

def build_hydrangea(blue_heavy):
    """`sf_hydrangea.png` -- TUFA DE HORTENSII. Lista de elemente:

    1. movila de frunzis joasa si rotunda (TROPICAL_GREEN 21), O ~1,0 m, burta pe sol;
    2. 8 frunze LATE, OVALE (varf rotunjit, nervura ridicata), care ies pe margine de sub
       flori -- nu tepi;
    3. 11 flori MOPHEAD: BILE rotunde (O ~0,36-0,42 m), granulate, care se ating intre
       ele, pe toata calota: 1 in varf, 4 in inelul de sus, 6 in inelul de jos;
    4. culorile pe flori, in proportia decuparii: varianta roz are 7 roz (FLAMINGO_PINK 31)
       si 4 albastru-gri (PAINTED_METAL 11) grupate pe o parte; varianta `_blue` le
       inverseaza (7 albastre, 4 roz);
    5. citita de sus (10 m): pete rotunde roz/albastre pe verde.
    Un singur nod `Hydrangea` (MultiMesh). Cote: ~0,95 m inalt, ~1,2 m lat.
    """
    b = Builder()
    pad_mass(b, (0.0, 0.0, 0.26, 0.50, 0.50, 0.30, 0.26), TROPICAL_GREEN, seg=6, seed=71,
             lobe=0.10)
    for k in range(8):
        az = 360.0 * k / 8 + 14.0 * ((k * 7) % 3)
        a = math.radians(az)
        base = (math.cos(a) * 0.32, math.sin(a) * 0.32, 0.14 + 0.06 * (k % 2))
        oval_leaf(b, base, az, 0.34, 0.26, 0.08, TROPICAL_GREEN)
    heads = [((0.0, 0.0, 0.73), 0.21)]
    for k in range(4):
        a = 2.0 * math.pi * k / 4 + 0.3
        heads.append(((math.cos(a) * 0.30, math.sin(a) * 0.30, 0.60), 0.20))
    for k in range(6):
        a = 2.0 * math.pi * k / 6 + 0.75
        heads.append(((math.cos(a) * 0.47, math.sin(a) * 0.47, 0.38), 0.185))
    # albastrele (in varianta roz): grupate pe o parte, ca in decupare
    minority = {2, 7, 8, 6}
    for k, (c, r) in enumerate(heads):
        pink = (k in minority) if blue_heavy else (k not in minority)
        ball_head(b, c, r, FLAMINGO_PINK if pink else PAINTED, seg=7, seed=90 + k, jag=0.05)
    return b.to_object("Hydrangea")


# ---------------------------------------------------------------------------
# Gradinita din fata casei (N2)
# ---------------------------------------------------------------------------

GARDEN_X, GARDEN_Y = 3.5, 1.5     # semi-amprenta 7,0 x 3,0 (X x Z Godot)
STREET_Y = GARDEN_Y               # Blender +Y = Godot -Z = strada (fatada casei e la -Z)
KERB_W = 0.28


def build_front_garden():
    """`sf_front_garden.png` -- GRADINITA 7 x 3 m. Lista de elemente:

    1. bordura de piatra crem (CORAL_SAND 19), blocuri de 0,28 m latime si 0,26 / 0,30 m
       inaltime, alternante ca sa se vada rosturile, pe latura de STRADA si pe cele doua
       capete; latura casei libera (se lipeste de soclu);
    2. gazon plat (CACTUS_GREEN 12) pe toata amprenta dinauntrul bordurii;
    3. gard viu de ~0,6 m in L: pe TOATA latura de strada si pe capatul -X, pana la casa;
       tronsoane scurte cu inaltimi si grosimi diferite (tufe tunse, silueta zimtata, nu o
       cutie), laturile TROPICAL_GREEN 21, crestetul CACTUS_GREEN 12 (mai galbui: varful
       luminat din decupare);
    4. jardiniera MARE de lemn (WOOD_WEATHERED 9, 2,3 x 0,75 x 0,5 m) lipita de casa, in
       coltul +X, cu o scandura in relief si buza de sus. Privita dinspre casa, gradinita e
       chiar decuparea: gard viu in spate si in stanga, jardiniera in fata-dreapta; din strada
       (camera de joc) jardiniera se vede peste gardul viu;
    5. in jardiniera: movila de frunze si 5 flori roz rotunde (FLAMINGO_PINK 31).
    Strada e la Blender +Y = Godot -Z (aceeasi orientare ca fatada casei, `--front=-Z`).
    Nimic peste 1,2 m. Un singur nod `Garden_Body`, fara coliziune. Fetele de jos (pe sol)
    sunt scoase: nu se vad niciodata, iar bugetul e de 400.
    """
    b = Builder()
    kh = (0.26, 0.30)
    xs = [-GARDEN_X + 7.0 * k / 4 for k in range(5)]
    for k in range(4):
        h = kh[k % 2]
        b.box(((xs[k] + xs[k + 1]) * 0.5, STREET_Y - KERB_W * 0.5, h * 0.5),
              (xs[k + 1] - xs[k], KERB_W, h), CORAL_SAND)
    inner_y0, inner_y1 = -GARDEN_Y, STREET_Y - KERB_W
    for sx in (-1, 1):
        h = kh[1] if sx < 0 else kh[0]
        b.box((sx * (GARDEN_X - KERB_W * 0.5), (inner_y0 + inner_y1) * 0.5, h * 0.5),
              (KERB_W, inner_y1 - inner_y0, h), CORAL_SAND)
    lx = GARDEN_X - KERB_W
    b.box((0.0, (inner_y0 + inner_y1) * 0.5, 0.07), (2 * lx, inner_y1 - inner_y0, 0.14),
          CACTUS_GREEN)

    def hedge(x0, x1, y0, y1, h):
        bm = b.bm
        cx, cy = (x0 + x1) * 0.5, (y0 + y1) * 0.5
        hx, hy = (x1 - x0) * 0.5, (y1 - y0) * 0.5
        ring = lambda z, ix, iy: [bm.verts.new((cx + sx * (hx - ix), cy + sy * (hy - iy), z))
                                  for (sx, sy) in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        lo = ring(0.0, 0.0, 0.0)
        mid = ring(h - 0.14, 0.0, 0.0)
        top = ring(h, 0.10, 0.10)
        for r0, r1, sl in ((lo, mid, TROPICAL_GREEN), (mid, top, CACTUS_GREEN)):
            for k in range(4):
                j = (k + 1) % 4
                f = bm.faces.new((r0[k], r0[j], r1[j], r1[k]))
                f[b.slot] = sl
        f = bm.faces.new(tuple(top))
        f[b.slot] = CACTUS_GREEN
    hy1 = inner_y1
    hx0 = -lx
    # latura de strada: 5 tronsoane, inaltimi si grosimi diferite
    cuts = [hx0, -1.6, 0.0, 1.6, lx]
    for k in range(4):
        h = (0.62, 0.57, 0.64, 0.59, 0.63)[k]
        d = (0.56, 0.50, 0.58, 0.52, 0.55)[k]
        hedge(cuts[k] - (0.03 if k else 0.0), cuts[k + 1], hy1 - d, hy1, h)
    # capatul -X, pana la casa: 2 tronsoane
    hedge(hx0, hx0 + 0.56, -0.25, hy1 - 0.48, 0.60)
    hedge(hx0, hx0 + 0.52, -GARDEN_Y, -0.22, 0.64)
    # jardiniera mare lipita de casa, coltul +X
    px1 = lx - 0.05
    px0 = px1 - 2.3
    py0, py1 = -GARDEN_Y + 0.04, -GARDEN_Y + 0.79
    pcx, pcy = (px0 + px1) * 0.5, (py0 + py1) * 0.5
    pw, pd = px1 - px0, py1 - py0
    b.box((pcx, pcy, 0.25), (pw, pd, 0.50), WOOD)
    b.box((pcx, pcy, 0.24), (pw + 0.05, pd + 0.05, 0.10), WOOD)
    b.box((pcx, pcy, 0.48), (pw + 0.07, pd + 0.06, 0.07), WOOD)
    pad_mass(b, (pcx, pcy, 0.54, pw * 0.46, pd * 0.42, 0.14, 0.05), TROPICAL_GREEN, seg=5,
             seed=301, lobe=0.08)
    for k in range(5):
        x = px0 + 0.25 + (pw - 0.50) * k / 4
        y = pcy + (0.10 if k % 2 else -0.10)
        ball_head(b, (x, y, 0.70 + 0.03 * (k % 2)), 0.21, FLAMINGO_PINK, seg=5, seed=310 + k,
                  jag=0.05)
    drop_ground_faces(b)
    return b.to_object("Garden_Body")


# ---------------------------------------------------------------------------

def _emit_tree(fn, path, budget, blend):
    clear_built()
    emit_sf(list(fn()), path, AO_TREE, smooth=SMOOTH_TREE, budget=budget,
            post=card_post, blend=blend)


# `-- --cypress` (dupa al doilea `--` al lui run_build): doar chiparosii. Arborele de strada,
# hortensiile si gradinita au fost acceptate la v1 si nu se mai rescriu.
_ONLY_CYP = "--cypress" in sys.argv
_emit_tree(build_cypress_a, "plants/sf_cypress_a.glb", 4000, "sf_cypress_a.blend")
_emit_tree(build_cypress_b, "plants/sf_cypress_b.glb", 4000, "sf_cypress_b.blend")
_emit_tree(build_cypress_c, "plants/sf_cypress_c.glb", 4000, "sf_cypress_c.blend")
if not _ONLY_CYP:
    _emit_tree(build_street_tree, "plants/sf_street_tree.glb", 1100, "sf_street_tree.blend")

    for blue, name in ((False, "sf_hydrangea"), (True, "sf_hydrangea_blue")):
        clear_built()
        emit_sf([build_hydrangea(blue)], "plants/%s.glb" % name, AO_SMALL,
                smooth={"Hydrangea": 85.0}, budget=650, blend=name + ".blend")

    clear_built()
    emit_sf([build_front_garden()], "props/sf_front_garden.glb", AO_GARDEN,
            smooth={"Garden_Body": 50.0}, budget=400, blend="sf_front_garden.blend")

if report_sf():
    raise SystemExit("buget de triunghiuri depasit")
