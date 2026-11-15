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
        --python tools/blender/run_build.py -- build_sf_plants.py
"""

import math
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
CYP_CARDS = {"a": (540, "41784A", "8DAE58"),
             "b": (540, "41784A", "8DAE58"),
             "c": (440, "41784A", "8DAE58")}
STREET_CARDS = (205, "8FA83A", "CBD05C")
# Runda 2 (plansa r1: trunchi subtire ca de pin, perne subtiri si rare): trunchiul si
# crengile groase se ingroasa pe toti, pernele se ingroasa pe verticala, iar cardurile
# (1,0-1,3 m) se indesesc ~1,6x -- masa citita in decupare e DEASA.
TRUNK_K, LIMB_K = 1.35, 1.25
PAD_UP_K, PAD_DN_K = 1.35, 1.25
# Runda 3 (plansa de vederi r2: din capatul din vant coroana era o coloana de 4,5-5,5 m, adica
# un arbore-totem): adancimea (Y) se lateste -- pozitiile pe Y ale pernelor si crengilor x1,5,
# semi-axele Y x1,2. Silueta laterala (X-Z) nu se schimba.
DEPTH_POS_K, DEPTH_AX_K = 1.5, 1.2
# Masa de departe (`*_Crown`, doar in MeshForest) nu are grosimea cardurilor: pe plansa de
# siluete r2 citea discuri plate pe tije (exact umbrela interzisa, §3.1). Se umfla pe verticala.
FAR_UP_K, FAR_DN_K, FAR_AX_K = 1.75, 1.6, 1.08
SMOOTH_TREE = {"_Trunk": 70.0, "_Crown": 80.0}

clear_built()


# ---------------------------------------------------------------------------
# Chiparosii (V1)
# ---------------------------------------------------------------------------

def _cypress(trunks, limbs, pads, cards, seed, roots=(1.05, 5), twigs=()):
    """trunks: [(puncte, raze, faza)], limbs: [(puncte, r0, r1)], pads: ciorchinii
    (cx, cy, cz, ax, ay, az_sus, az_jos). Intoarce cele patru noduri."""
    tr, cr, co, lv = Builder(), Builder(), Builder(), Builder()
    pads = [(x, y * DEPTH_POS_K, z, ax, ay * DEPTH_AX_K, azu * PAD_UP_K, azd * PAD_DN_K)
            for (x, y, z, ax, ay, azu, azd) in pads]
    deep = lambda pts: [(p[0], p[1] * DEPTH_POS_K, p[2]) for p in pts]
    limbs = [(deep(pts), r0, r1) for (pts, r0, r1) in limbs]
    twigs = [(deep(pts), r0, r1) for (pts, r0, r1) in twigs]
    for k, (pts, radii, phase) in enumerate(trunks):
        # 12 laturi / 3 caneluri: 4 varfuri pe canelura (r2: 10/4 aliasa si crestele
        # deschise se anulau in medie -- trunchiul iesea de o singura culoare)
        twisted_trunk(tr, pts, [r * TRUNK_K for r in radii], BARK, BARK_LIGHT, segments=12,
                      flutes=3, depth=0.15, turns=0.6, phase=phase, crest=0.35)
    # contraforturi scurte si groase (r1: picioare de paianjen), mai multe
    root_flare(tr, roots[0] * TRUNK_K * 0.9, roots[1] + 2, BARK, seed=seed, height=0.9,
               reach=1.18, thick=0.40, segments=7)
    for (pts, r0, r1) in limbs:
        limb(tr, pts, r0 * LIMB_K, r1, BARK, segments=6)
    for (pts, r0, r1) in twigs:
        limb(tr, pts, r0, r1, BARK, segments=5)
    for k, p in enumerate(pads):
        x, y, z, ax, ay, azu, azd = p
        pad_mass(cr, (x, y, z, ax * FAR_AX_K, ay * FAR_AX_K, azu * FAR_UP_K, azd * FAR_DN_K),
                 CYPRESS_GREEN, seg=6, seed=seed * 31 + k)
    core_lens(co, pads, CYPRESS_GREEN, shrink=0.70, seg=7)
    n = sf_leaf_cards(lv, pads, CYPRESS_GREEN, cards[0], cards[1], accent_hex=cards[2],
                      seed=seed, size=(1.0, 1.3), shell=(0.80, 1.08), below=0.22,
                      radial=0.15, accent=0.30, shade_lo=0.50)
    print("  carduri:", n)
    return (tr.to_object("Cypress_Trunk"), cr.to_object("Cypress_Crown"),
            co.to_object("Cypress_Core"), lv.to_object("Cypress_Leaves"))


def build_cypress_a():
    """`sf_cypress_a.png` -- UN SINGUR TRUNCHI APLECAT. Lista de elemente:

    1. trunchi SCURT si GROS (O baza ~1,45 m), rasucit (caneluri in spirala, creste mai
       deschise), care se apleaca spre +X: pleaca aproape vertical si se culca spre dreapta;
    2. 5 contraforturi de radacina care intra in pamant (evazare la baza);
    3. furca la ~2,6 m: liderul continua aplecat spre +X pana in stratul de sus;
    4. creanga LUNGA, aproape orizontala, spre +X (sub vant) care poarta perna joasa din
       dreapta (~4,2 m);
    5. creanga SCURTA spre -X (in vant) cu perna mica joasa din stanga (~3,1 m);
    6. creanga spre stanga-sus care poarta stratul de MIJLOC, centrat spre -X (~6 m);
    7. stratul de SUS (~8,6 m), lung si turtit, care CURGE spre +X si se subtiaza in coada
       (ciorchinii scad spre dreapta);
    8. straturile sunt perne orizontale, cu burta plata si intunecata si crestet de smocuri,
       cu GOL intre ele prin care se vad crengile;
    9. ansamblu asimetric: masa coroanei e deplasata spre +X fata de trunchi.
    Cote: ~9,8 m inalt, coroana ~9,4 m lata (X).
    """
    trunks = [([(0, 0, 0), (0.25, 0, 0.85), (0.8, 0.05, 1.6), (1.55, 0, 2.35),
                (2.15, -0.05, 3.2), (2.45, 0, 4.2), (2.4, 0.05, 5.2), (2.5, 0, 6.3),
                (2.75, 0, 7.3), (2.95, 0, 8.2)],
               [0.72, 0.64, 0.56, 0.50, 0.44, 0.38, 0.32, 0.27, 0.22, 0.15], 0.0)]
    limbs = [
        ([(1.6, 0, 2.4), (2.5, 0.1, 2.8), (3.3, 0.05, 3.45), (4.1, 0, 4.0)], 0.30, 0.11),
        ([(0.5, 0, 1.2), (-0.6, 0.05, 1.85), (-1.6, 0.1, 2.5), (-2.2, 0.1, 2.95)], 0.27, 0.10),
        ([(2.0, 0, 3.0), (1.1, 0, 4.1), (-0.1, 0.05, 4.95), (-1.1, 0.1, 5.7)], 0.28, 0.11),
        ([(2.4, 0, 4.9), (2.95, 0.1, 5.4), (3.4, 0, 5.8)], 0.18, 0.09),
        ([(2.4, 0, 4.0), (1.8, -0.9, 5.0), (1.3, -1.5, 5.7)], 0.18, 0.09),
        ([(2.45, 0, 5.6), (2.35, 0.9, 6.8), (2.1, 1.4, 7.9)], 0.16, 0.08),
    ]
    twigs = [
        ([(2.78, 0, 7.4), (1.0, 0.1, 8.1)], 0.13, 0.08),
        ([(2.88, 0, 7.8), (3.9, 0, 8.3)], 0.12, 0.08),
    ]
    pads = [
        (0.6, 0.2, 8.45, 1.55, 1.50, 0.55, 0.36),    # T1 sus, inceputul stratului
        (2.3, -0.15, 8.65, 1.75, 1.70, 0.60, 0.40),  # T2 sus, cel mai mare
        (4.0, 0.15, 8.55, 1.45, 1.35, 0.50, 0.34),   # T3 sus, spre coada
        (4.75, -0.1, 8.35, 0.85, 0.85, 0.38, 0.26),  # T4 coada stratului de sus
        (2.0, 1.5, 8.2, 1.30, 1.00, 0.45, 0.32),     # T5 sus, fata
        (1.6, -1.6, 8.3, 1.30, 1.00, 0.45, 0.32),    # T6 sus, spate
        (-2.0, 0.1, 5.9, 1.40, 1.35, 0.52, 0.36),    # M1 mijloc, capatul din vant
        (-0.4, 0.3, 6.15, 1.60, 1.50, 0.58, 0.40),   # M2 mijloc
        (1.3, -0.1, 6.05, 1.50, 1.45, 0.55, 0.38),   # M3 mijloc
        (2.9, 0.15, 5.85, 1.20, 1.10, 0.45, 0.32),   # M4 mijloc, coada
        (0.9, -1.6, 5.9, 1.20, 0.95, 0.45, 0.32),    # M5 mijloc, spate
        (3.6, 0.1, 4.2, 1.15, 1.05, 0.45, 0.30),     # R1 perna joasa din dreapta
        (4.7, -0.05, 4.05, 0.85, 0.80, 0.36, 0.25),  # R2 coada ei
        (-2.3, 0.1, 3.1, 1.05, 1.00, 0.45, 0.30),    # L1 perna joasa din stanga (in vant)
    ]
    return _cypress(trunks, limbs, pads, CYP_CARDS["a"], seed=3, roots=(1.0, 5), twigs=twigs)


def build_cypress_b():
    """`sf_cypress_b.png` -- DOUA TRUNCHIURI, LAT. Lista de elemente:

    1. baza MASIVA (O ~2,2 m) din care pleaca doua trunchiuri groase, rasucite, lipite jos;
    2. 6 contraforturi de radacina, evazare larga;
    3. trunchiul din stanga urca aproape vertical si poarta stratul de sus din STANGA
       (~7 m), cu o creanga spre -X la perna joasa din stanga (~3,1 m) si una la stratul
       de mijloc din stanga (~4,9 m);
    4. trunchiul din dreapta se culca puternic spre +X si poarta stratul de sus din DREAPTA
       (~8,4 m, cel mai inalt si cel mai lung, curge spre +X);
    5. din trunchiul drept: stratul de mijloc din dreapta (~5,2 m), perna mica joasa din
       dreapta (~3,5 m) si o creanga spre centru cu un strat central (~5,8 m);
    6. straturile sunt perne orizontale cu burta plata, despartite de goluri prin care se
       vad cele doua trunchiuri si crengile;
    7. ansamblu mai LAT decat inalt, masa deplasata spre +X.
    Cote: ~9,6 m inalt, coroana ~9,8 m lata (X).
    """
    # r2: trunchiurile erau doi stalpi drepti; acum stangul se arcuieste spre -X si revine,
    # dreptul se culca in arc spre +X (ca in decupare)
    trunks = [
        ([(-0.30, 0, 0), (-0.72, 0, 1.0), (-1.08, 0.05, 2.0), (-1.18, 0, 3.0),
          (-0.92, 0, 4.1), (-0.52, 0, 5.2), (-0.1, 0, 6.1), (0.3, 0, 6.9)],
         [0.70, 0.61, 0.52, 0.45, 0.38, 0.31, 0.25, 0.18], 0.0),
        ([(0.30, 0, 0), (0.82, 0, 0.9), (1.62, 0, 1.7), (2.5, -0.05, 2.5), (3.2, 0, 3.5),
          (3.6, 0, 4.7), (3.82, 0, 6.0), (3.75, 0, 6.9)],
         [0.72, 0.63, 0.54, 0.47, 0.40, 0.33, 0.27, 0.20], 1.3),
    ]
    limbs = [
        ([(-1.08, 0, 2.0), (-1.9, 0.1, 2.5), (-2.6, 0.05, 2.95), (-2.95, 0, 3.15)], 0.26, 0.10),
        ([(-1.15, 0, 3.4), (-1.8, 0.05, 4.3), (-2.3, 0, 4.85)], 0.22, 0.10),
        ([(3.25, 0, 3.6), (4.0, 0.05, 4.4), (4.5, 0, 4.95)], 0.24, 0.10),
        ([(2.5, 0, 2.5), (3.4, -0.05, 3.0), (4.2, 0, 3.45)], 0.20, 0.09),
        ([(3.3, 0, 4.0), (2.3, 0.1, 5.0), (1.3, 0.05, 5.8)], 0.18, 0.08),
        ([(3.6, 0, 5.0), (3.3, -0.8, 6.2), (3.1, -1.4, 7.9)], 0.15, 0.08),
        ([(-0.55, 0, 5.0), (-0.4, 0.8, 5.8), (-0.2, 1.3, 6.7)], 0.15, 0.08),
        ([(3.8, 0, 6.4), (3.4, 0.9, 7.2), (3.3, 1.35, 7.9)], 0.13, 0.08),
    ]
    twigs = [
        ([(3.78, 0, 6.6), (3.0, 0.1, 7.5), (2.4, 0.1, 8.15)], 0.16, 0.08),
        ([(3.78, 0, 6.7), (4.2, 0, 7.6), (4.8, 0, 8.25)], 0.16, 0.08),
        ([(3.78, 0, 6.8), (3.8, -0.1, 7.7), (3.9, -0.1, 8.3)], 0.14, 0.08),
        ([(0.2, 0, 6.6), (-0.9, 0.1, 6.95)], 0.11, 0.08),
    ]
    pads = [
        (2.4, 0.1, 8.25, 1.50, 1.45, 0.55, 0.38),    # sus dreapta 1
        (3.9, -0.1, 8.45, 1.60, 1.50, 0.60, 0.40),   # sus dreapta 2, cel mai mare
        (4.75, 0.1, 8.2, 0.80, 0.90, 0.40, 0.28),    # coada stratului de sus
        (3.3, 1.4, 8.0, 1.20, 0.90, 0.45, 0.32),     # sus dreapta, fata
        (3.2, -1.5, 8.1, 1.20, 0.90, 0.45, 0.30),    # sus dreapta, spate
        (-0.9, 0.15, 6.95, 1.45, 1.40, 0.55, 0.38),  # sus stanga 1
        (0.7, -0.1, 7.15, 1.40, 1.35, 0.55, 0.36),   # sus stanga 2
        (-0.2, -1.4, 6.9, 1.10, 0.90, 0.42, 0.30),   # sus stanga, spate
        (3.3, 0.1, 5.25, 1.30, 1.20, 0.48, 0.34),    # mijloc dreapta
        (4.55, -0.1, 5.05, 0.92, 1.00, 0.40, 0.28),  # mijloc dreapta, coada
        (1.2, 0.3, 5.75, 1.30, 1.20, 0.48, 0.34),    # stratul central
        (-2.3, 0.1, 4.85, 1.30, 1.25, 0.50, 0.34),   # mijloc stanga
        (-0.9, 0.9, 5.0, 1.00, 0.90, 0.42, 0.30),    # mijloc stanga, fata
        (-2.95, 0.05, 3.15, 0.95, 0.95, 0.42, 0.30), # perna joasa din stanga
        (4.3, 0.1, 3.45, 0.85, 0.80, 0.36, 0.25),    # perna joasa din dreapta
    ]
    return _cypress(trunks, limbs, pads, CYP_CARDS["b"], seed=7, roots=(1.25, 6), twigs=twigs)


def build_cypress_c():
    """`sf_cypress_c.png` -- MIC, COMPACT. Lista de elemente:

    1. un trunchi gros si scurt cu evazare, in S: pleaca spre +X, se indreapta, apoi se
       apleaca din nou spre +X sus;
    2. 5 contraforturi de radacina;
    3. stratul de SUS (~7,3 m), lung, care curge spre +X si se subtiaza in coada;
    4. stratul de mijloc din DREAPTA (~5,4 m), pe o creanga scurta spre +X;
    5. perna joasa din STANGA (~3,5 m), pe o creanga lunga spre -X (in vant), singura masa
       care iese spre vant;
    6. perna joasa din dreapta (~3,0 m), pe o creanga spre +X;
    7. goluri intre straturi prin care se vad crengile; mai inalt decat lat (spre deosebire
       de a si b), masa tot spre +X.
    Cote: ~8,6 m inalt, coroana ~8,1 m lata (X).
    """
    trunks = [([(0, 0, 0), (0.3, 0, 0.8), (0.9, 0, 1.6), (1.4, 0, 2.4), (1.58, 0, 3.3),
                (1.38, 0, 4.2), (1.3, 0, 5.1), (1.55, 0, 6.0), (1.85, 0, 6.95)],
               [0.60, 0.54, 0.48, 0.42, 0.37, 0.32, 0.27, 0.21, 0.15], 0.6)]
    limbs = [
        ([(0.6, 0, 1.25), (-0.5, 0.05, 2.15), (-1.5, 0.1, 2.9), (-2.05, 0, 3.25)], 0.25, 0.10),
        ([(1.4, 0, 2.4), (2.1, 0.05, 2.55), (2.8, 0, 2.85)], 0.22, 0.10),
        ([(1.4, 0, 4.1), (2.1, 0.05, 4.75), (2.7, 0, 5.2)], 0.18, 0.08),
        ([(1.3, 0, 4.8), (1.1, -0.7, 5.3), (1.0, -1.1, 5.55)], 0.13, 0.08),
        ([(1.5, 0, 5.9), (1.45, 0.8, 6.6), (1.4, 1.1, 6.9)], 0.12, 0.08),
    ]
    twigs = [
        ([(1.65, 0, 6.3), (0.4, 0.05, 6.95)], 0.12, 0.08),
        ([(1.75, 0, 6.6), (3.1, 0, 7.05)], 0.11, 0.08),
    ]
    pads = [
        (0.1, 0.1, 7.2, 1.30, 1.25, 0.52, 0.36),     # sus 1
        (1.7, -0.1, 7.45, 1.50, 1.40, 0.58, 0.38),   # sus 2, cel mai mare
        (3.2, 0.1, 7.3, 1.20, 1.10, 0.48, 0.32),     # sus 3
        (4.2, 0.0, 7.05, 0.66, 0.75, 0.34, 0.24),    # coada stratului de sus
        (1.4, 1.2, 7.0, 1.00, 0.80, 0.40, 0.30),     # sus, fata
        (1.2, -1.3, 7.05, 1.00, 0.80, 0.40, 0.30),   # sus, spate
        (2.2, 0.1, 5.4, 1.25, 1.15, 0.48, 0.34),     # mijloc dreapta
        (3.3, -0.05, 5.25, 0.85, 0.85, 0.38, 0.26),  # mijloc dreapta, coada
        (1.0, -1.2, 5.6, 0.90, 0.80, 0.38, 0.28),    # mijloc, spate
        (-2.15, 0.05, 3.45, 1.25, 1.05, 0.46, 0.32),  # perna joasa din stanga
        (-0.8, 0.25, 3.6, 0.80, 0.80, 0.36, 0.26),   # langa ea, spre trunchi
        (2.7, 0.1, 3.05, 1.05, 0.95, 0.42, 0.30),    # perna joasa din dreapta
    ]
    return _cypress(trunks, limbs, pads, CYP_CARDS["c"], seed=11, roots=(0.9, 5), twigs=twigs)


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


_emit_tree(build_cypress_a, "plants/sf_cypress_a.glb", 2900, "sf_cypress_a.blend")
_emit_tree(build_cypress_b, "plants/sf_cypress_b.glb", 2900, "sf_cypress_b.blend")
_emit_tree(build_cypress_c, "plants/sf_cypress_c.glb", 2900, "sf_cypress_c.blend")
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
