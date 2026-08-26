"""Chongqing — structurile fixe ale pistei (plansa, pozitiile 8-12).

  vehicles/cargo_ship.glb              nava de containere, ~62 m (POI E)
  structures/bay_bridge.glb            podul peste golf, tronson de 40 m
  buildings/kuixinglou_pavilion.glb    chioscul-pagoda din piata de start
  structures/stone_stairway.glb        scara Shibati, tronson de 12 m
  structures/footbridge.glb            pasarela de intoarcere spre piata

Nota de scara: podul si scara sunt TRONSOANE modulare, nu piese unice —
se insiruie pe traseu cap la cap (originea in capatul de start, ca la kitul
nodului). Nava, chioscul si pasarela sunt piese unice.

Scara Shibati e singura care are o cerinta de GAMEPLAY, nu doar vizuala:
treptele sunt suprafata pe care ajungi daca ratezi saltul (brief §2, POI B),
deci **fiecare treapta e sub 15 cm** — peste atat roata se agata in loc sa
urce (memoria `suprafete-cu-goluri-si-praguri`).

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_structures.py
"""

import math
from mathutils import Matrix, Vector

AO_BIG = dict(samples=26, dist=8.0, gradient="vertical",
              low=0.42, high=1.00, power=0.9, floor=0.12)
AO_MID = dict(samples=24, dist=5.0, gradient="vertical",
              low=0.46, high=1.00, power=0.9, floor=0.14)

CONC = CONCRETE
CONC2 = MARBLE_GREY
STEEL = PAINTED
HULL = ASPHALT_EDGE        # coca inchisa a navei
HULL_RED = KERB_RED        # opera vie (sub linia de plutire)
GLOW = LAVA_ORANGE
GLASS = ASPHALT
TIMBER = LOG_DARK
TIMBER_L = WOOD
ROOF = VOLCANIC_BLACK
STONE = ROCK_LIGHT


# --- 8. nava de containere --------------------------------------------------

def build_cargo_ship():
    """Nava care trece pe sub pod si al carei siaj inunda cheiul (brief §3).

    E fundal-erou: se vede de pe chei, de pe pod si de pe cornisa, mereu de
    la distanta si mereu de SUS. Deci silueta si containerele coloratenite
    conteaza, nu detaliul de punte.
    """
    b = Builder()
    L, W = 62.0, 11.0
    # --- coca: se ingusteaza spre prova, in trei tronsoane ------------------
    # Un paralelipiped ar citi ca o barja. Ingustarea la prova e ce face
    # silueta de nava, si se vede exact de sus.
    SEGS = [(-0.50, -0.18, 1.00, 1.00), (-0.18, 0.22, 1.00, 0.98),
            (0.22, 0.40, 0.98, 0.82), (0.40, 0.50, 0.82, 0.42)]
    for f0, f1, w0, w1 in SEGS:
        y0, y1 = L * f0, L * f1
        yc, ln = (y0 + y1) * 0.5, (y1 - y0)
        ww = W * (w0 + w1) * 0.5
        b.box((0.0, yc, 1.9), (ww, ln, 3.8), HULL)          # bord liber
        b.box((0.0, yc, -0.5), (ww * 0.94, ln, 1.0), HULL_RED)   # opera vie
    # puntea
    b.box((0.0, -L * 0.04, 3.95), (W * 0.98, L * 0.86, 0.30), CONC2)
    # --- containerele: doua straturi, culori alternante --------------------
    rand = _lcg(77)
    PALETTE = (KERB_RED, TROPICAL_GREEN, RUST, CONC2, SAND_SHADOW)
    rows, cols, lay = 9, 3, 2
    for r in range(rows):
        for c in range(cols):
            for k in range(lay):
                if rand() > 0.88:
                    continue                     # goluri: incarcatura reala
                y = -L * 0.40 + L * 0.62 * r / (rows - 1)
                x = (c - 1) * W * 0.29
                b.box((x, y, 4.9 + k * 2.6), (W * 0.26, L * 0.062, 2.5),
                      PALETTE[int(rand() * len(PALETTE)) % len(PALETTE)])
    # --- suprastructura la pupa -------------------------------------------
    sy = -L * 0.42
    b.box((0.0, sy, 6.6), (W * 0.72, 7.0, 5.0), FOAM_WHITE)
    for f in range(3):
        b.box((0.0, sy + 3.6, 5.4 + f * 1.5), (W * 0.66, 0.24, 0.85), GLASS)
    b.box((0.0, sy, 9.7), (W * 0.62, 6.0, 1.2), FOAM_WHITE)     # timonerie
    b.box((0.0, sy + 3.1, 9.7), (W * 0.58, 0.22, 0.95), GLASS)
    # cosul de fum
    b.box((0.0, sy - 2.2, 11.6), (2.6, 2.8, 3.6), CONC2)
    b.box((0.0, sy - 2.2, 13.5), (2.2, 2.4, 0.5), HULL)
    # catargul + luminile de navigatie (nava e luminata — brief)
    b.beam((0.0, sy + 1.0, 10.3), (0.0, sy + 1.0, 15.5), 0.22, STEEL)
    b.box((0.0, sy + 1.0, 15.6), (0.30, 0.30, 0.34), GLOW)
    for sx in (-1.0, 1.0):
        b.box((sx * W * 0.36, sy + 3.2, 7.4), (0.26, 0.22, 0.28), GLOW)
    # prova: ancora + o banda de punte
    b.box((0.0, L * 0.455, 4.1), (W * 0.42, L * 0.08, 0.34), CONC2)
    return b.to_object("CargoShip")


# --- 9. podul peste golf ----------------------------------------------------

def build_bay_bridge():
    """Tronson de pod de 40 m: tablier + doi piloni + stalpi de lampa.

    Plansa arata un pod SIMPLU pe piloni scurti, nu unul hobanat. Corect:
    brief §2.0 spune ca pilonii inalti nu primesc geometrie fiindca nu-i vezi
    niciodata de pe carosabil. Ce vezi e parapetul si sirul de lampi.
    """
    b = Builder()
    L, W = 40.0, 9.0        # brief §2: latimea pe pod e 9 m
    # tablierul
    b.box((0.0, 0.0, -0.10), (W, L, 0.20), ASPHALT)
    b.box((0.0, 0.0, -0.45), (W - 0.2, L, 0.50), CONC)
    for sx in (-1.0, 1.0):
        b.box((sx * W * 0.34, 0.0, -0.95), (0.70, L, 0.55), CONC)
    # parapet plin, jos (pe pod nu ai unde cadea, deci nu e "cornisa")
    for sx in (-1.0, 1.0):
        x = sx * (W * 0.5 - 0.22)
        b.box((x, 0.0, 0.32), (0.40, L, 0.64), CONC2)
        b.box((x, 0.0, 0.68), (0.48, L, 0.14), CONC)
    # pilonii: doi, la treimi
    for k in (-1.0, 1.0):
        y = k * L * 0.25
        b.box((0.0, y, -3.6), (5.2, 2.2, 5.2), CONC)
        b.box((0.0, y, -6.4), (6.2, 2.8, 0.8), CONC2)      # radier
    # stalpi de lampa la 10 m, alternand pe cele doua parti
    n = int(L / 10.0)
    for i in range(n + 1):
        y = -L * 0.5 + L * i / n
        sx = 1.0 if i % 2 == 0 else -1.0
        x = sx * (W * 0.5 - 0.30)
        b.cylinder((x, y, 2.3), 0.11, 3.8, STEEL, segments=6)
        b.beam((x, y, 4.15), (x - sx * 0.85, y, 4.35), 0.13, STEEL)
        b.box((x - sx * 0.95, y, 4.28), (0.52, 0.30, 0.20), GLOW)
    return b.to_object("BayBridge")


# --- 10. chioscul-pagoda din piata -----------------------------------------

def build_pavilion():
    """Kuixinglou: chioscul din piata de start, cu acoperis in DOUA streasini.

    Doua streasini suprapuse (nu una) — asta e ce distinge un pavilion
    chinezesc de un foisor. Se vede de la start, in fata masinii, deci e
    piesa cea mai aproape de camera din toata pista: merita bevel de 2
    segmente si colturi ridicate adevarate.
    """
    b = Builder()
    R = 3.4                 # semi-latura platformei
    # --- soclu in doua trepte + scara pe o latura --------------------------
    b.box((0.0, 0.0, 0.16), (R * 2.5, R * 2.5, 0.32), STONE)
    b.box((0.0, 0.0, 0.46), (R * 2.2, R * 2.2, 0.30), STONE)
    for i in range(3):
        b.box((0.0, R * 1.25 + 0.28 + i * 0.34, 0.44 - i * 0.16),
              (2.6, 0.36, 0.16), STONE)
    # --- opt stalpi rosii pe un octogon ------------------------------------
    H = 3.2
    posts = []
    for i in range(8):
        a = math.radians(22.5 + i * 45.0)
        x, y = R * math.cos(a), R * math.sin(a)
        b.cylinder((x, y, 0.61 + H * 0.5), 0.16, H, KERB_RED, segments=6)
        posts.append((x, y))
    # centuri intre stalpi: jos (balustrada) si sus (arhitrava)
    for i in range(8):
        x0, y0 = posts[i]
        x1, y1 = posts[(i + 1) % 8]
        b.beam((x0, y0, 0.61 + H - 0.18), (x1, y1, 0.61 + H - 0.18), 0.16,
               TIMBER)
        # balustrada joasa doar pe 5 laturi (intrarea ramane libera)
        if i not in (1, 2, 3):
            b.beam((x0, y0, 1.15), (x1, y1, 1.15), 0.13, KERB_RED)
            b.pickets((x0, y0, 0.63), (x1, y1, 0.63), 0.42,
                      (0.07, 0.07, 0.52), TIMBER)
    # --- acoperisul: doua streasini suprapuse ------------------------------
    def eave(z, r_in, r_out, rise, slot=ROOF):
        """O streasina octogonala: opt lespezi inclinate + coama."""
        for i in range(8):
            a0 = math.radians(i * 45.0)
            a1 = math.radians((i + 1) * 45.0)
            am = (a0 + a1) * 0.5
            # Lespedea, ca o cutie inclinata pe directia radiala.
            #
            # `Ry(t)` duce +X in (cos t, 0, -sin t), deci ca streasina sa
            # COBOARE spre exterior semnul e +ang cu ang = atan2(rise, dr).
            # Cu semnul invers iese o palnie — streasina urca in loc sa
            # coboare si pavilionul citeste ca o antena satelit (prima
            # randare de control).
            dr = r_out - r_in
            ln = math.hypot(dr, rise)
            ang = math.atan2(rise, dr)
            mid_r = (r_in + r_out) * 0.5
            # coama e SUS (z + rise), streasina jos (z): mijlocul e la jumatate
            mid_z = z + rise * 0.5
            rot = (Matrix.Rotation(am, 3, "Z")
                   @ Matrix.Rotation(ang, 3, "Y"))
            b.box((mid_r * math.cos(am), mid_r * math.sin(am), mid_z),
                  (ln, 2.0 * r_out * math.tan(math.radians(22.5)) * 1.05, 0.16),
                  slot, rotation=rot)
            # coltul ridicat, la varful fiecarei laturi
            # coltul ridicat sta la streasina (cota z), si se rasuceste in
            # SUS: -30 grade cu aceeasi conventie Ry inseamna varf ridicat.
            b.box((r_out * math.cos(am) * 1.04, r_out * math.sin(am) * 1.04,
                   z + 0.20),
                  (0.60, 0.32, 0.16), slot,
                  rotation=Matrix.Rotation(am, 3, "Z")
                  @ Matrix.Rotation(math.radians(-32.0), 3, "Y"))
    base_z = 0.61 + H
    eave(base_z + 0.10, 0.55, R + 1.15, 1.15)          # streasina de jos
    # tamburul dintre streasini
    b.cylinder((0.0, 0.0, base_z + 1.45), R * 0.42, 0.90, KERB_RED, segments=8)
    eave(base_z + 1.85, 0.35, R * 0.78, 0.95)          # streasina de sus
    # varful: bila + ac
    b.cylinder((0.0, 0.0, base_z + 2.95), 0.20, 0.40, TIMBER, segments=6)
    b.box((0.0, 0.0, base_z + 3.28), (0.34, 0.34, 0.34), GLOW)
    # --- lampioane rosii sub streasina de jos -------------------------------
    for i in (0, 2, 4, 6):
        a = math.radians(22.5 + i * 45.0)
        x, y = (R + 0.55) * math.cos(a), (R + 0.55) * math.sin(a)
        b.beam((x, y, base_z + 0.05), (x, y, base_z - 0.30), 0.05, TIMBER)
        b.cylinder((x, y, base_z - 0.52), 0.17, 0.34, KERB_RED, segments=6)
    return b.to_object("KuixinglouPavilion")


# --- 11. scara Shibati ------------------------------------------------------

STEP_RISE = 0.14           # SUB 15 cm: peste atat roata se agata (memorie)
STEP_RUN = 0.36


def build_stone_stairway():
    """Tronson de scara: 12 m de trepte + parapete laterale + felinare.

    E suprafata de PEDEAPSA a POI-ului B: daca ratezi kickerul aterizezi aici
    si primesti tremur + grip 0.8x. Deci treptele trebuie sa fie conducibile,
    nu decorative — 14 cm inaltime, 36 cm calcatura.
    """
    b = Builder()
    W = 9.0
    n = 34                                   # 34 trepte x 0.36 = 12.2 m
    for i in range(n):
        y = i * STEP_RUN
        z = i * STEP_RISE
        # treapta: latimea plina, cu nasul putin iesit
        b.box((0.0, y, z + STEP_RISE * 0.5), (W, STEP_RUN, STEP_RISE), STONE)
        b.box((0.0, y - STEP_RUN * 0.42, z + STEP_RISE * 0.72),
              (W, STEP_RUN * 0.22, STEP_RISE * 0.5), CONC2)
        # Umplutura sub trepte. Se aseaza SUB cota treptei (z), nu peste ea:
        # varianta veche punea o cutie inalta de `z` centrata la z*0.5, adica
        # exact peste treptele deja construite — scara iesea un zid plin
        # (prima randare de control).
        if i % 3 == 0 and z > 0.25:
            b.box((0.0, y, z * 0.5), (W - 0.5, STEP_RUN * 3.0, z), STONE)
    total_y = n * STEP_RUN
    total_z = n * STEP_RISE
    # parapete laterale: ziduri inclinate care urmeaza panta
    ang = math.atan2(total_z, total_y)
    ln = math.hypot(total_y, total_z)
    for sx in (-1.0, 1.0):
        x = sx * (W * 0.5 + 0.32)
        b.box((x, total_y * 0.5, total_z * 0.5 + 0.34), (0.64, ln, 0.68),
              STONE, rotation=Matrix.Rotation(ang, 3, "X"))
        # mana curenta pe parapet
        b.box((x, total_y * 0.5, total_z * 0.5 + 0.76), (0.72, ln, 0.16),
              CONC2, rotation=Matrix.Rotation(ang, 3, "X"))
    # felinare la fiecare 8 trepte, alternand partile
    for k in range(1, 5):
        i = k * 8
        if i >= n:
            break
        sx = 1.0 if k % 2 == 0 else -1.0
        x = sx * (W * 0.5 + 0.34)
        y, z = i * STEP_RUN, i * STEP_RISE + 0.7
        b.cylinder((x, y, z + 1.05), 0.09, 2.1, TIMBER, segments=6)
        b.box((x, y, z + 2.22), (0.34, 0.34, 0.40), GLOW)
        b.box((x, y, z + 2.46), (0.42, 0.42, 0.10), ROOF)
    return b.to_object("StoneStairway")


# --- 12. pasarela -----------------------------------------------------------

def build_footbridge():
    """Pasarela de intoarcere spre piata (brief §2, iesirea din G).

    Plansa o arata cu grinzi vizibile sub tablier si balustrada deasa —
    e o pasarela metalica, nu un pod de beton.
    """
    b = Builder()
    L, W = 24.0, 4.6
    # tablierul + grinzile longitudinale
    b.box((0.0, 0.0, -0.09), (W, L, 0.18), ASPHALT)
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.28), 0.0, -0.45), (0.34, L, 0.72),
              TROPICAL_GREEN)
    # traverse la 2 m (se vad de dedesubt, cand treci pe sub pasarela)
    for i in range(int(L / 2.0) + 1):
        y = -L * 0.5 + i * 2.0
        b.box((0.0, y, -0.42), (W - 0.5, 0.20, 0.36), TROPICAL_GREEN)
    # balustrada deasa pe ambele parti
    for sx in (-1.0, 1.0):
        x = sx * (W * 0.5 - 0.14)
        b.railing((x, -L * 0.5, 0.0), (x, L * 0.5, 0.0), 1.15, 2.0, 0.12,
                  0.09, TROPICAL_GREEN, rails=2)
        # sipci verticale intre stalpi
        b.pickets((x, -L * 0.5 + 0.2, 0.0), (x, L * 0.5 - 0.2, 0.0), 0.42,
                  (0.06, 0.06, 1.05), TROPICAL_GREEN)
    # picioarele: doua cadre in V
    for k in (-1.0, 1.0):
        y = k * L * 0.28
        for sx in (-1.0, 1.0):
            b.beam((sx * (W * 0.5 - 0.3), y, -0.7),
                   (sx * (W * 0.5 + 0.5), y, -4.6), 0.26, TROPICAL_GREEN)
        b.beam((-W * 0.5 - 0.5, y, -4.6), (W * 0.5 + 0.5, y, -4.6), 0.30,
               TROPICAL_GREEN)
        b.box((0.0, y, -4.95), (W + 1.6, 1.0, 0.5), CONC)
    return b.to_object("Footbridge")


clear_built()

PIECES = [
    (build_cargo_ship, "vehicles/cargo_ship.glb", AO_BIG, "base", 0.04, 1),
    (build_bay_bridge, "structures/bay_bridge.glb", AO_BIG, "base", 0.04, 1),
    (build_pavilion, "buildings/kuixinglou_pavilion.glb", AO_MID, "base",
     0.035, 2),
    (build_stone_stairway, "structures/stone_stairway.glb", AO_BIG,
     "base_axis", 0.03, 1),
    (build_footbridge, "structures/footbridge.glb", AO_MID, "base", 0.03, 1),
]

for fn, path, ao, origin, bev, seg in PIECES:
    obj = fn()
    st = finish(obj, bevel=bev, bevel_segments=seg, ao=ao, origin=origin)
    _, sz = export_glb([obj], "chongqing/" + path)
    print("%-38s tris=%6d ao=%.2f..%.2f %8.1f kB"
          % (path, st["tris"], st["ao_min"], st["ao_max"], sz / 1024.0))
