"""Chongqing — Urban Kit B: cladiri si trafic (plansa, pozitia 16).

  buildings/shophouse_{a,b,c}.glb      case-magazin de 2 niveluri (Shibati)
  buildings/restaurant_front.glb       fatada de restaurant hot-pot (POI C)
  buildings/tower_silhouette_{a,b,c}   turnuri de fundal, peste rau
  vehicles/bus.glb                     autobuzul din nodul de trafic (POI A)
  vehicles/mini_car_{a,b,c}.glb        masinute de trafic, 3 culori
  props/container.glb                  container de chei (POI E)

Doua reguli din brief §2.0, si amandoua se vad in dimensiunile de aici:

1. **Langa drum, nimic peste 4 niveluri.** Casele-magazin au 2, restaurantul
   are 1 + copertina. Un bloc de 30 m langa carosabil s-ar vedea ca un perete
   de 12-15 m fara varf — adica bani aruncati pe geometrie invizibila.
2. **Turnurile exista DOAR ca siluete peste rau**, la 150-250 m. Deci sunt
   cutii cu ferestre aprinse si atat: zero detaliu de fatada, zero intrari.
   Trei variante de inaltime/latime ca sa nu se citeasca repetitia.

Traficul (autobuz + 3 masinute) e "nodul de trafic" din POI A: decor STATIC cu
coliziune, cu o singura fanta de 3 m intre doua autobuze. Costa zero cod si e
foarte Ignition. Masinutele sunt scurte si late (proportii de jucarie, ca si
masinile jucatorului) — style_bible: masina de jucarie, nu masina reala.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_kit_b.py
"""

import math
from mathutils import Matrix, Vector

AO_BUILD = dict(samples=24, dist=6.0, gradient="vertical",
                low=0.44, high=1.00, power=0.9, floor=0.12)
AO_VEH = dict(samples=22, dist=3.5, gradient="vertical",
              low=0.50, high=1.00, power=0.9, floor=0.18)
AO_TOWER = dict(samples=16, dist=10.0, gradient="vertical",
                low=0.50, high=1.00, power=0.9, floor=0.20)

CONC = CONCRETE
CONC2 = MARBLE_GREY
GLOW = LAVA_ORANGE
GLASS = ASPHALT
DARK = VOLCANIC_BLACK
ROOF = VOLCANIC_BLACK
TIMBER = LOG_DARK
WOODL = WOOD
RED = KERB_RED
STONE = ROCK_LIGHT
STEEL = PAINTED


def tiled_roof(b, cx, cy, z, w, d, slot=ROOF, rise=None, overhang=0.55):
    """Acoperis in doua ape cu olane, panta pe ADANCIME.

    Aceeasi conventie de semn ca la Hongya: `Ry`/`Rx` duce +Y in
    (0, cos t, sin t), deci semnul e +ang. Panta coboara pe adancime, coama
    merge pe lungul fatadei.
    """
    rise = rise if rise is not None else d * 0.30
    half_d = d * 0.5
    t = 0.18
    for sy in (-1.0, 1.0):
        y_in, z_in = 0.0, z + rise
        y_out, z_out = sy * (half_d + overhang), z + 0.02
        dy, dz = (y_out - y_in), (z_out - z_in)
        ln = math.hypot(dy, dz)
        rot = Matrix.Rotation(math.atan2(dz, dy), 3, "X")
        b.box((cx, cy + (y_in + y_out) * 0.5, (z_in + z_out) * 0.5),
              (w + overhang, ln, t), slot, rotation=rot)
    b.box((cx, cy, z + rise + 0.08), (w + overhang * 1.1, 0.36, 0.20), slot)


def shophouse(variant):
    """Casa-magazin de doua niveluri: pravalie jos, locuinta sus.

    Identitatea vine din TREI lucruri, toate in plansa: obloanele de lemn ale
    pravaliei, copertina de panza peste trotuar si balconasul de la etaj cu
    rufe. Fara ele iese o casa generica.
    """
    b = Builder()
    W = (6.4, 7.6, 5.8)[variant]
    D = 5.4
    H1, H2 = 3.0, 2.8                # parter, etaj
    rand = _lcg(211 + variant * 17)

    # corpul
    b.box((0.0, 0.0, H1 * 0.5), (W, D, H1), CONC2)
    b.box((0.0, 0.0, H1 + H2 * 0.5), (W, D, H2), CONC if variant else CONC2)
    # centura intre niveluri
    b.box((0.0, 0.0, H1 + 0.10), (W + 0.30, D + 0.30, 0.24), CONC)

    # --- parterul: vitrina + obloane ---------------------------------------
    yf = D * 0.5
    b.box((0.0, yf - 0.06, 1.55), (W - 1.0, 0.18, 2.10),
          GLOW if variant != 1 else GLASS)
    # obloane de lemn, verticale
    n = int((W - 1.0) / 0.42)
    for i in range(n):
        x = -(W - 1.0) * 0.5 + (W - 1.0) * (i + 0.5) / n
        if rand() > 0.72:            # cateva trase, restul deschise
            b.box((x, yf + 0.02, 1.55), ((W - 1.0) / n * 0.9, 0.09, 2.10),
                  TIMBER)
    # stalpii vitrinei + pragul
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.24), yf, 1.55), (0.48, 0.42, 3.10), CONC2)
    b.box((0.0, yf + 0.10, 0.10), (W, 0.60, 0.20), STONE)

    # --- copertina peste trotuar -------------------------------------------
    b.box((0.0, yf + 0.85, 3.02), (W - 0.3, 1.80, 0.10),
          RED if variant == 0 else (TROPICAL_GREEN if variant == 1 else CONC),
          rotation=Matrix.Rotation(math.radians(-9.0), 3, "X"))
    for sx in (-1.0, 1.0):
        b.beam((sx * (W * 0.5 - 0.35), yf + 0.10, 3.05),
               (sx * (W * 0.5 - 0.35), yf + 1.70, 2.78), 0.07, STEEL)
    # firma verticala pe un stalp
    if variant != 2:
        sx = 1.0 if variant == 0 else -1.0
        b.box((sx * (W * 0.5 - 0.10), yf + 0.30, 4.30), (0.34, 0.14, 1.70), RED)
        b.box((sx * (W * 0.5 - 0.10), yf + 0.38, 4.30), (0.22, 0.06, 1.45), GLOW)

    # --- etajul: ferestre + balconas ---------------------------------------
    k = 2 if W < 7.0 else 3
    for i in range(k):
        x = -W * 0.5 + W * (i + 0.5) / k
        b.window((x, yf - 0.02, H1 + 1.45), 0.95, 1.15, 0.10, 0.16,
                 GLOW if rand() > 0.35 else GLASS, TIMBER, mullions=(1, 1))
    # balconas continuu
    b.box((0.0, yf + 0.55, H1 + 0.42), (W - 0.6, 1.10, 0.14), CONC)
    b.pickets((-W * 0.5 + 0.4, yf + 1.02, H1 + 0.49),
              (W * 0.5 - 0.4, yf + 1.02, H1 + 0.49), 0.34,
              (0.07, 0.07, 0.80), STEEL)
    b.box((0.0, yf + 1.02, H1 + 1.32), (W - 0.8, 0.10, 0.10), STEEL)
    # rufe pe balcon (doar la o varianta: repetitia se vede)
    if variant == 1:
        for i in range(3):
            x = -1.4 + i * 1.4
            b.box((x, yf + 1.05, H1 + 0.95), (0.42, 0.03, 0.55),
                  (FOAM_WHITE, ICE_TURQUOISE, RED)[i])

    # --- acoperisul ---------------------------------------------------------
    tiled_roof(b, 0.0, 0.0, H1 + H2, W, D)
    return b.to_object("Shophouse%s" % "ABC"[variant])


def build_restaurant_front():
    """Fatada de restaurant hot-pot: gura larga, lampioane, aburi, mese.

    Piesa asta e POI-ul C intreg intr-un singur asset: coridorul strâmt cu
    lampioane rosii si aburi. Se pune pe o parte a aleii si tine atmosfera.
    """
    b = Builder()
    W, D, H = 8.6, 4.2, 3.6
    # Corpul e retras (adancime D-1.2, centrat la y=-0.6), deci fatada lui NU
    # e la D*0.5: e la 0.9. Cu yf=D*0.5 tot ce tine de fatada — gura, copertina,
    # lampioanele — plutea 1.2 m in fata cladirii, si asa arata si in prima
    # randare de control: acoperis detasat peste o coaja deschisa.
    BODY_D = D - 1.2
    BODY_Y = -0.6
    yf = BODY_Y + BODY_D * 0.5          # = 0.9, fatada REALA
    b.box((0.0, BODY_Y, H * 0.5), (W, BODY_D, H), CONC2)
    b.box((0.0, yf - 0.35, 1.45), (W - 1.4, 0.5, 2.5), DARK)      # gura
    # tejgheaua luminata din fund
    b.box((0.0, -0.2, 1.05), (W - 2.2, 0.7, 1.0), WOODL)
    b.box((0.0, -0.2, 1.62), (W - 2.4, 0.5, 0.14), GLOW)
    # oale pe tejghea
    for i in range(4):
        x = -2.4 + i * 1.6
        b.cylinder((x, -0.2, 1.78), 0.24, 0.20, CONC, segments=8)
        b.cylinder((x, -0.2, 1.90), 0.20, 0.05, RED, segments=8)
    # stalpii gurii
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.32), yf - 0.3, H * 0.5), (0.64, 0.9, H), CONC2)
    # copertina rosie + firma
    b.box((0.0, yf + 0.95, 3.15), (W - 0.2, 2.10, 0.12), RED,
          rotation=Matrix.Rotation(math.radians(-8.0), 3, "X"))
    b.box((0.0, yf + 0.20, 3.95), (W - 1.0, 0.20, 0.90), RED)
    b.box((0.0, yf + 0.32, 3.95), (W - 1.6, 0.08, 0.62), GLOW)
    # sirul de lampioane sub copertina
    for i in range(6):
        x = -W * 0.5 + W * (i + 0.5) / 6
        b.beam((x, yf + 1.5, 3.02), (x, yf + 1.5, 2.74), 0.03, TIMBER)
        b.frustum((x, yf + 1.5, 2.60), 0.10, 0.17, 0.17, RED, segments=8)
        b.frustum((x, yf + 1.5, 2.43), 0.17, 0.10, 0.17, RED, segments=8)
    # mese pe trotuar, in fata
    for k, (mx, my) in enumerate(((-2.6, yf + 1.5), (2.4, yf + 1.7))):
        b.box((mx, my, 0.62), (0.85, 0.85, 0.07), WOODL)
        for sx in (-1.0, 1.0):
            for sy in (-1.0, 1.0):
                b.beam((mx + sx * 0.34, my + sy * 0.34, 0.0),
                       (mx + sx * 0.34, my + sy * 0.34, 0.60), 0.05, WOODL)
        for j, (ox, oy) in enumerate(((0.75, 0.0), (-0.72, 0.15), (0.0, 0.74))):
            b.box((mx + ox, my + oy, 0.30), (0.28, 0.28, 0.05), RED)
            b.beam((mx + ox, my + oy, 0.0), (mx + ox, my + oy, 0.28), 0.06, RED)
    # cosul de aburi pe acoperis
    b.cylinder((W * 0.28, -0.9, H + 0.45), 0.22, 0.90, RUST, segments=8)
    tiled_roof(b, 0.0, BODY_Y, H, W, BODY_D, rise=0.9)
    return b.to_object("RestaurantFront")


def tower_silhouette(variant):
    """Turn de fundal: cutie cu grila de ferestre aprinse. Zero detaliu.

    Brief §2.0: turnurile se vad DOAR ca siluete peste rau, la 150-250 m, sub
    `fog_end`. La distanta aia o intrare sau un balcon sunt sub un pixel. Ce
    citeste e conturul si grila de ferestre — si aia sunt tot ce se plateste.
    """
    b = Builder()
    W, D, H = ((11.0, 10.0, 34.0), (14.0, 11.0, 44.0), (9.0, 9.0, 27.0))[variant]
    rand = _lcg(401 + variant * 29)
    b.box((0.0, 0.0, H * 0.5), (W, D, H), CONC)
    # un corp de scara mai inalt, decalat: rupe silueta de cutie
    b.box((W * 0.28, 0.0, H * 0.5 + 1.6), (W * 0.34, D * 0.62, H + 3.2), CONC2)
    # grila de ferestre pe cele doua fete vizibile
    floors = int(H / 3.0)
    for face, (nx, ax) in enumerate(((int(W / 2.6), "y"), (int(D / 2.6), "x"))):
        for f in range(1, floors):
            for i in range(nx):
                if rand() > 0.55:
                    continue
                z = 1.6 + f * 3.0
                if ax == "y":
                    x = -W * 0.5 + W * (i + 0.5) / nx
                    b.box((x, D * 0.5, z), (0.95, 0.16, 1.05), GLOW)
                else:
                    y = -D * 0.5 + D * (i + 0.5) / nx
                    b.box((W * 0.5, y, z), (0.16, 0.95, 1.05), GLOW)
    # coronament + lumina de balizaj
    b.box((0.0, 0.0, H + 0.35), (W + 0.5, D + 0.5, 0.70), CONC2)
    b.box((W * 0.28, 0.0, H + 3.4), (W * 0.36, D * 0.64, 0.5), CONC2)
    b.box((W * 0.28, 0.0, H + 3.9), (0.3, 0.3, 0.4), RED)
    return b.to_object("TowerSilhouette%s" % "ABC"[variant])


# --- trafic -----------------------------------------------------------------

def build_bus():
    """Autobuz de oras: cutie lunga, banda de culoare, geamuri continue."""
    b = Builder()
    L, W, H = 10.5, 2.6, 3.0
    zc = 0.62 + H * 0.5
    b.box((0.0, 0.0, zc), (W, L, H), FOAM_WHITE)
    # banda verde sub geamuri (plansa: alb + verde)
    b.box((0.0, 0.0, zc - H * 0.5 + 0.55), (W + 0.04, L, 0.80), TROPICAL_GREEN)
    # geamuri: o banda continua pe fiecare parte
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.03), 0.3, zc + 0.55), (0.10, L - 2.2, 1.05),
              GLASS)
    # parbriz + luneta
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (L * 0.5 - 0.05), zc + 0.50), (W - 0.35, 0.12, 1.15),
              GLASS)
    # usi
    for sy in (-1.0, 1.0):
        b.box((W * 0.5 - 0.02, sy * 2.3, zc - 0.25), (0.09, 1.05, 2.0), CONC2)
    # acoperis + trapa de aerisire
    b.box((0.0, 0.0, zc + H * 0.5 + 0.05), (W - 0.3, L - 0.5, 0.12), CONC2)
    # roti
    for sy in (-1.0, 1.0):
        for sx in (-1.0, 1.0):
            b.cylinder((sx * (W * 0.5 - 0.12), sy * (L * 0.5 - 1.5), 0.52),
                       0.52, 0.32, DARK, segments=10, axis="X")
    # faruri + stopuri
    for sx in (-1.0, 1.0):
        b.box((sx * 0.85, L * 0.5 + 0.02, 1.05), (0.42, 0.10, 0.26), GLOW)
        b.box((sx * 0.85, -L * 0.5 - 0.02, 1.05), (0.42, 0.10, 0.26), RED)
    # afisaj de destinatie
    b.box((0.0, L * 0.5 + 0.02, zc + 1.05), (W - 0.9, 0.08, 0.34), GLOW)
    return b.to_object("Bus")


def mini_car(variant):
    """Masinuta de trafic: scurta si LATA (proportii de jucarie, style_bible)."""
    b = Builder()
    BODY = (KERB_RED, ICE_DEEP, DRY_VEGETATION)[variant]
    L, W = 3.5, 1.85
    zc = 0.34 + 0.42
    # caroseria: corp + cabina retrasa
    b.box((0.0, 0.0, zc), (W, L, 0.84), BODY)
    b.box((0.0, -0.15, zc + 0.62), (W - 0.28, L * 0.52, 0.62), BODY)
    # geamuri
    b.box((0.0, -0.15 + L * 0.26, zc + 0.60), (W - 0.5, 0.10, 0.50), GLASS)
    b.box((0.0, -0.15 - L * 0.26, zc + 0.60), (W - 0.5, 0.10, 0.50), GLASS)
    for sx in (-1.0, 1.0):
        b.box((sx * (W * 0.5 - 0.16), -0.15, zc + 0.60), (0.10, L * 0.44, 0.46),
              GLASS)
    # roti
    for sy in (-1.0, 1.0):
        for sx in (-1.0, 1.0):
            b.cylinder((sx * (W * 0.5 - 0.06), sy * (L * 0.5 - 0.78), 0.34),
                       0.34, 0.22, DARK, segments=10, axis="X")
    # faruri, stopuri, bare
    for sx in (-1.0, 1.0):
        b.box((sx * 0.58, L * 0.5 + 0.01, 0.82), (0.34, 0.08, 0.20), GLOW)
        b.box((sx * 0.58, -L * 0.5 - 0.01, 0.82), (0.34, 0.08, 0.20), RED)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * (L * 0.5 + 0.03), 0.60), (W - 0.2, 0.12, 0.18), CONC2)
    return b.to_object("MiniCar%s" % "ABC"[variant])


def build_container():
    """Container de 20 de picioare: nervuri verticale + usi la un capat."""
    b = Builder()
    L, W, H = 6.1, 2.44, 2.59
    b.box((0.0, 0.0, H * 0.5), (W, L, H), RUST)
    # nervurile: `corrugate` face fix asta, dar aici e mai ieftin cu benzi
    n = int(L / 0.32)
    for i in range(n):
        y = -L * 0.5 + L * (i + 0.5) / n
        for sx in (-1.0, 1.0):
            b.box((sx * (W * 0.5 + 0.015), y, H * 0.5), (0.05, L / n * 0.55,
                                                         H - 0.30), RUST)
    # rame sus/jos si colturi (partea care da silueta de container)
    for sz in (0.10, H - 0.10):
        b.box((0.0, 0.0, sz), (W + 0.06, L + 0.06, 0.20), CONC2)
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * W * 0.5, sy * L * 0.5, H * 0.5), (0.14, 0.14, H), CONC2)
    # usile de la un capat
    b.box((0.0, L * 0.5 + 0.02, H * 0.5), (W - 0.20, 0.06, H - 0.28), CONC2)
    for sx in (-1.0, 1.0):
        b.beam((sx * 0.5, L * 0.5 + 0.06, 0.22), (sx * 0.5, L * 0.5 + 0.06,
                                                  H - 0.22), 0.07, RUST)
    return b.to_object("Container")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.03):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "chongqing/" + path)
    results.append((path, st["tris"], sz / 1024.0))


for v in range(3):
    emit(shophouse(v), "buildings/shophouse_%s.glb" % "abc"[v], AO_BUILD)
emit(build_restaurant_front(), "buildings/restaurant_front.glb", AO_BUILD)
for v in range(3):
    emit(tower_silhouette(v), "buildings/tower_silhouette_%s.glb" % "abc"[v],
         AO_TOWER, bevel=0.05)
emit(build_bus(), "vehicles/bus.glb", AO_VEH, bevel=0.025)
for v in range(3):
    emit(mini_car(v), "vehicles/mini_car_%s.glb" % "abc"[v], AO_VEH,
         bevel=0.025)
emit(build_container(), "props/container.glb", AO_VEH, bevel=0.025)

print()
for path, tris, kb in results:
    print("%-38s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL kit B: %d tris" % sum(t for _, t, _ in results))
