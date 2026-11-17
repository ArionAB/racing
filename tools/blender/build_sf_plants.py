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
# in lumina calda de apus; sclipirile sunt galben-verzi, ca petele de soare din decupare, si
# stau pe crestetul si pe fata dinspre vant a fiecarei mase (`windward`), ca straturile sa se
# desparta in lumina.
CYP_CARDS = {"a": (1050, "41784A", "8DAE58"),
             "b": (1000, "41784A", "8DAE58"),
             "c": (800, "41784A", "8DAE58")}
STREET_CARDS = (205, "8FA83A", "CBD05C")
# Masa de departe (`*_Crown`, doar in MeshForest) nu are grosimea cardurilor: se umfla putin.
FAR_UP_K, FAR_DN_K = 1.15, 1.1
SMOOTH_TREE = {"_Trunk": 70.0, "_Crown": 80.0}

clear_built()


# ---------------------------------------------------------------------------
# Chiparosii (V1) -- v3 (verdictul coordonatorului, 16 nov 2026)
#
# v1 citea pin tuns in nori (niwaki: perne-bila stivuite pe un trunchi zvelt, ~10 x 9 m).
# v2 a reparat proportiile (mai lat decat inalt), aplecarea si cozile spre +X, dar politele
# de ~1,2 m pe crengi lungi si goale citeau salcam / bonsai cu polite (silueta salcamilor din
# Serengeti, interzisa de inventar §3.1). v3 pastreaza tot ce a reusit v2 si pune MASA:
# fiecare strat e un NOR gros de 2-2,8 m (lobi de baza cu crestet bombat si burta plata, plus
# un rand de domuri deasupra), care se subtiaza spre coada din +X; norii se suprapun pe
# verticala ~30 % si sunt esalonati pe Z (adancime), deci din lateral coroana e un singur
# corp in trepte, pieptanat de vant, cu putine goluri de cer, iar crengile se vad mai ales
# dedesubt, langa trunchi. Garda masoara umplerea siluetei (>= 55 %) si adancimea (>= 6,5 m).
# ---------------------------------------------------------------------------

def cloud(x0, x1, z, y=0.0, depth=4.0, thick=1.8, lobes=4, rise=0.2, wobble=0.35, k=0.72):
    """Un NOR de frunzis pieptanat de vant, de la capatul bont din vant (x0) la coada din +X
    (x1). Doua randuri de ciorchini:
      - BAZA: `lobes` ciorchini care se suprapun ca tiglele si scad spre +X (semi-axa pe X a
        lobului i = A * k^i, centrele la 0,62 x (a_i + a_i+1), A ales ca norul sa aiba exact
        lungimea x1 - x0); crestet bombat (0,55 x grosimea), burta plata (0,32 x);
      - DOMURI: pe toti lobii in afara de ultimul, cate un ciorchine mai mic ridicat deasupra,
        spre vant -- crestetul in bulgari din decupare.
    Grosimea (`thick` = burta + crestet ale primului lob, fara domuri si fara carduri) scade
    spre coada (0,8^i), adancimea (pe Y Blender = Z Godot) la fel (0,88^i). Norul urca usor
    (`rise`) spre +X. Intoarce lista de ciorchini (cx, cy, cz, ax, ay, az_sus, az_jos)."""
    ws = [k ** i for i in range(lobes)]
    span = ws[0] + sum(0.62 * (ws[i] + ws[i + 1]) for i in range(lobes - 1)) + ws[-1]
    A = (x1 - x0) / span
    out = []
    cx = x0 + A * ws[0]
    for i in range(lobes):
        t = i / max(lobes - 1, 1)
        ax = A * ws[i]
        ay = depth * 0.5 * (0.88 ** i)
        th = thick * (0.80 ** i)
        cy = y + wobble * (1 if i % 2 else -1) * (0.5 + 0.5 * t)
        cz = z + rise * t
        out.append((cx, cy, cz, ax, ay, th * 0.62, th * 0.38))
        if i < lobes - 1:
            out.append((cx - ax * 0.15, cy - wobble * 0.5, cz + th * 0.45,
                        ax * 0.72, ay * 0.72, th * 0.45, th * 0.25))
        if i < lobes - 1:
            cx += 0.62 * (A * ws[i] + A * ws[i + 1])
    return out


def _cypress(trunks, limbs, clouds, cards, seed, roots):
    """trunks: [(puncte, raze, faza)], limbs: [(puncte, r0, r1)], clouds: liste de ciorchini
    (din `cloud`), roots: (raza bazei, numar de contraforturi). Intoarce cele patru noduri."""
    tr, cr, co, lv = Builder(), Builder(), Builder(), Builder()
    pads = [p for c in clouds for p in c]
    for (pts, radii, phase) in trunks:
        # 15 laturi / 5 caneluri rasucite (3 varfuri pe canelura): mai multe creste decat v2
        twisted_trunk(tr, pts, radii, BARK, BARK_LIGHT, segments=15, flutes=5, depth=0.13,
                      turns=0.55, phase=phase, crest=0.35)
    root_flare(tr, roots[0], roots[1], BARK, seed=seed, height=1.0, reach=1.6, thick=0.48,
               segments=7, toe=True)
    for (pts, r0, r1) in limbs:
        limb(tr, pts, r0, r1, BARK, segments=7 if r0 >= 0.3 else 6)
    for k, (x, y, z, ax, ay, azu, azd) in enumerate(pads):
        pad_mass(cr, (x, y, z, ax * 1.03, ay * 1.03, azu * FAR_UP_K, azd * FAR_DN_K),
                 CYPRESS_GREEN, seg=7, seed=seed * 31 + k, lobe=0.10)
    core_lens(co, pads, CYPRESS_GREEN, shrink=0.85, seg=6)
    n = sf_leaf_cards(lv, pads, CYPRESS_GREEN, cards[0], cards[1], accent_hex=cards[2],
                      seed=seed, size=(0.95, 1.30), shell=(0.82, 1.05), below=0.15,
                      radial=0.10, accent=0.32, shade_lo=0.48, size_by_pad=True,
                      windward=0.8)
    print("  carduri:", n)
    return (tr.to_object("Cypress_Trunk"), cr.to_object("Cypress_Crown"),
            co.to_object("Cypress_Core"), lv.to_object("Cypress_Leaves"))


def build_cypress_a():
    """`sf_cypress_a.png` -- UN SINGUR TRUNCHI APLECAT (v3). Lista de elemente:

    1. trunchi MASIV si scurt (O baza ~1,9 m), rasucit (5 caneluri in spirala, creste mai
       deschise), care se culca in S spre +X; 5 contraforturi cu varful rotunjit;
    2. furca JOASA (~2 m), crengi groase (O >= 0,6 m la furca, >= 0,36 m unde intra in nor);
    3. norul de SUS (~6,6 m), cel mai lung, de la 0 la +7,6: depaseste baza cu peste 7 m pe +X
       si se termina in coada;
    4. norul de mijloc din vant (~4,9 m, -2,6..+4,8), esalonat spre fata (Z-), si norul de
       mijloc din spate (~5,2 m, +0,5..+6,6), esalonat spre spate: impreuna cu cel de sus fac un
       singur corp in trepte, suprapus ~30 % pe verticala;
    5. norul jos din dreapta (~3,4 m) pe creanga orizontala lunga spre +X, coada pana la +8,1;
    6. norul mic si bont din vant (~3 m), pe creanga scurta spre -X;
    7. norii au crestet in bulgari (domuri), burta plata si intunecata; crengile se vad mai
       ales dedesubt, langa trunchi; 3-5 goluri mici de cer;
    8. ansamblu mai LAT decat inalt (~12,4 x ~8,4 m), adanc de ~7 m, masa spre +X.
    """
    trunks = [([(0, 0, 0), (0.2, 0, 0.7), (0.7, 0, 1.4), (1.5, 0, 1.95), (2.4, 0, 2.65),
                (2.9, 0, 3.6), (3.0, 0, 4.7), (3.2, 0, 5.7), (3.6, 0, 6.7)],
               [0.95, 0.82, 0.72, 0.64, 0.55, 0.47, 0.40, 0.33, 0.26], 0.0)]
    limbs = [
        ([(1.6, 0, 2.0), (3.0, -0.2, 2.75), (4.6, -0.4, 3.25), (6.0, -0.5, 3.45)], 0.40, 0.19),
        ([(0.6, 0, 1.1), (-0.8, 0.3, 1.8), (-2.0, 0.6, 2.4), (-2.7, 0.8, 2.85)], 0.34, 0.18),
        ([(2.6, 0, 3.0), (1.5, 0.4, 3.95), (0.3, 0.9, 4.55), (-1.0, 1.2, 4.85)], 0.36, 0.19),
        ([(2.95, 0, 4.1), (3.6, -0.8, 4.7), (4.3, -1.4, 5.05)], 0.30, 0.18),
        ([(3.3, 0, 6.1), (4.8, 0.05, 6.5), (6.0, 0, 6.7)], 0.30, 0.18),
        ([(3.5, 0, 6.5), (2.3, 0.05, 6.6), (1.2, 0, 6.7)], 0.26, 0.18),
    ]
    clouds = [
        cloud(0.0, 7.6, 6.6, y=0.0, depth=4.4, thick=1.8, lobes=4, rise=0.2),
        cloud(-2.6, 4.8, 4.9, y=1.4, depth=4.0, thick=1.8, lobes=4, rise=0.2),
        cloud(0.5, 6.6, 5.1, y=-1.5, depth=3.6, thick=1.6, lobes=3, rise=0.15),
        cloud(3.2, 8.1, 3.4, y=-0.6, depth=3.4, thick=1.6, lobes=3, rise=0.15),
        cloud(-4.0, -0.8, 3.05, y=0.9, depth=3.0, thick=1.5, lobes=2, rise=0.05),
    ]
    return _cypress(trunks, limbs, clouds, CYP_CARDS["a"], seed=3, roots=(0.95, 5))


def build_cypress_b():
    """`sf_cypress_b.png` -- URIASUL CU DOUA TRUNCHIURI (v3). Lista de elemente:

    1. baza ENORMA (O ~2,2 m) din care pleaca doua trunchiuri rasucite, arcuite, lipite jos;
       6 contraforturi cu varful rotunjit;
    2. trunchiul stang se arcuieste spre -X si revine: poarta norul de sus din STANGA (~5,9 m)
       si, pe o creanga groasa joasa spre -X, norul bont din vant (~2,9 m);
    3. trunchiul drept se culca puternic spre +X de la baza: poarta norul de sus din DREAPTA
       (~6,8 m, cel mai inalt si cel mai lung, coada pana la +8,2), norul de mijloc din dreapta
       (~4,6 m, esalonat spre spate) si norul jos din dreapta (~2,8 m);
    4. norul central (~4,3 m), esalonat spre fata, leaga cele doua jumatati;
    5. norii se suprapun pe verticala ~30 %: din lateral un singur corp lat in trepte;
    6. ansamblu mult MAI LAT decat inalt (~12,7 x ~8,6 m), adanc de ~7 m, masa spre +X.
    """
    trunks = [
        ([(-0.45, 0, 0), (-0.9, 0, 0.9), (-1.3, 0, 1.9), (-1.2, 0, 3.0), (-0.7, 0, 4.0),
          (-0.1, 0, 4.9), (0.4, 0, 5.6), (0.7, 0, 6.1)],
         [0.90, 0.78, 0.66, 0.56, 0.48, 0.40, 0.32, 0.24], 0.0),
        ([(0.45, 0, 0), (1.1, 0, 0.7), (2.0, 0, 1.4), (3.0, 0, 2.1), (3.9, 0, 3.0),
          (4.5, 0, 4.1), (4.8, 0, 5.4), (4.9, 0, 6.6), (4.9, 0, 7.2)],
         [0.95, 0.82, 0.70, 0.60, 0.50, 0.42, 0.34, 0.26, 0.18], 1.3),
    ]
    limbs = [
        ([(-1.3, 0, 1.8), (-2.2, -0.3, 2.4), (-2.9, -0.5, 2.9)], 0.36, 0.19),
        ([(0.2, 0, 5.6), (-0.9, 0.6, 5.8), (-2.0, 1.0, 5.9)], 0.30, 0.18),
        ([(0.5, 0, 6.0), (1.6, 0.6, 6.1)], 0.26, 0.18),
        ([(-0.85, 0, 3.7), (0.4, 0.8, 4.1), (1.8, 1.3, 4.3)], 0.32, 0.18),
        ([(4.4, 0, 4.0), (5.6, -0.7, 4.4), (7.0, -1.2, 4.6)], 0.36, 0.19),
        ([(3.0, 0, 2.1), (4.4, 0.3, 2.5), (6.0, 0.5, 2.75)], 0.34, 0.18),
        ([(4.9, 0, 6.6), (3.4, -0.2, 7.0), (2.2, -0.3, 7.1)], 0.26, 0.18),
        ([(4.9, 0, 6.8), (6.4, -0.2, 7.1)], 0.24, 0.18),
    ]
    clouds = [
        cloud(1.2, 8.2, 6.8, y=-0.3, depth=4.4, thick=1.8, lobes=4, rise=0.2),
        cloud(-3.2, 2.4, 5.9, y=1.3, depth=4.0, thick=1.8, lobes=4, rise=0.2),
        cloud(2.6, 8.3, 4.6, y=-1.4, depth=3.8, thick=1.7, lobes=4, rise=0.15),
        cloud(-1.2, 3.6, 4.3, y=1.6, depth=3.2, thick=1.5, lobes=3, rise=0.15),
        cloud(4.6, 8.1, 2.8, y=0.6, depth=3.0, thick=1.4, lobes=3, rise=0.1),
        cloud(-4.3, -1.4, 2.9, y=-0.6, depth=3.0, thick=1.5, lobes=2, rise=0.05),
    ]
    return _cypress(trunks, limbs, clouds, CYP_CARDS["b"], seed=7, roots=(1.1, 6))


def build_cypress_c():
    """`sf_cypress_c.png` -- MIC, COMPACT (v3). Lista de elemente:

    1. trunchi gros si scurt (O baza ~1,7 m) in S, culcat spre +X, rasucit; 5 contraforturi;
    2. furca joasa: creanga groasa spre -X (in vant) cu norul bont din stanga (~2,6 m),
       esalonat spre spate;
    3. norul jos din dreapta (~2,3 m) pe o creanga orizontala spre +X, esalonat spre spate;
    4. norul de mijloc din dreapta (~3,9 m), esalonat spre fata;
    5. norul de SUS (~5,6 m), de la -0,6 la +5,9, coada spre +X;
    6. norii se suprapun pe verticala: un corp in trepte, mai mic si mai strans decat a si b
       (~9,7 x ~7,5 m), adanc de ~6 m.
    """
    trunks = [([(0, 0, 0), (0.4, 0, 0.7), (1.0, 0, 1.4), (1.6, 0, 2.1), (2.0, 0, 3.0),
                (2.1, 0, 4.0), (2.3, 0, 5.0), (2.6, 0, 5.8)],
               [0.85, 0.74, 0.64, 0.56, 0.48, 0.40, 0.32, 0.24], 0.6)]
    limbs = [
        ([(0.5, 0, 0.9), (-0.7, 0.5, 1.6), (-1.8, 1.0, 2.2), (-2.4, 1.3, 2.5)], 0.32, 0.18),
        ([(1.6, 0, 2.1), (2.8, 0.4, 2.25), (4.0, 0.8, 2.4)], 0.32, 0.18),
        ([(2.1, 0, 3.7), (3.4, -0.6, 3.9), (4.6, -1.1, 4.0)], 0.30, 0.18),
        ([(2.5, 0, 5.6), (1.2, 0.05, 5.7), (0.4, 0, 5.75)], 0.24, 0.18),
        ([(2.6, 0, 5.7), (4.0, 0, 5.85), (5.0, 0, 5.95)], 0.24, 0.18),
    ]
    clouds = [
        cloud(-0.6, 5.9, 5.6, y=0.0, depth=4.0, thick=1.7, lobes=4, rise=0.2),
        cloud(1.4, 6.1, 3.9, y=-1.2, depth=3.4, thick=1.6, lobes=3, rise=0.15),
        cloud(1.8, 5.7, 2.3, y=0.9, depth=2.8, thick=1.4, lobes=3, rise=0.1),
        cloud(-3.5, -0.6, 2.6, y=1.4, depth=2.8, thick=1.4, lobes=2, rise=0.05),
    ]
    return _cypress(trunks, limbs, clouds, CYP_CARDS["c"], seed=11, roots=(0.85, 5))


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
_emit_tree(build_cypress_a, "plants/sf_cypress_a.glb", 5200, "sf_cypress_a.blend")
_emit_tree(build_cypress_b, "plants/sf_cypress_b.glb", 5200, "sf_cypress_b.blend")
_emit_tree(build_cypress_c, "plants/sf_cypress_c.glb", 5200, "sf_cypress_c.blend")
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
