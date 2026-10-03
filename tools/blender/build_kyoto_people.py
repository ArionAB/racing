"""Kyoto -- vehicule si oameni (brief docs/asset_briefs/kyoto_kit.md §1.9).

  kyoto/vehicles/sagano_train.glb   locomotiva + 3 vagoane, un singur corp
  kyoto/vehicles/jinrikisha.glb     ricsa + alergator (palarie conica)
  kyoto/vehicles/yakatabune.glb     barca de lemn cu acoperis pe stalpi
  kyoto/props/monk_sweeper.glb      calugar cu matura de bambus (static)

CONTRACT INGHETAT DE AXE (masurat pe GLB cu `preview_kyoto.py --views`, vezi
kyoto_inventory.md): "inainte" = +Y in Blender = -Z in Godot pentru toate patru.
Locomotiva sta la capatul +Y (Godot -Z); alergatorul, in fata cutiei (+Y);
barca are provai (mai inalta, ascutita) la +Y; calugarul priveste spre +Y.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_people.py [nume ...]
"""

import math
import bmesh
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

AO_VEH = dict(samples=12, dist=1.8, gradient="vertical",
              low=0.62, high=1.0, power=0.8, floor=0.30)
AO_FIG = dict(samples=14, dist=0.8, gradient="vertical",
              low=0.62, high=1.0, power=0.8, floor=0.30)


def _verts_of(faces):
    return list({v for f in faces for v in f.verts})


def _rot(b, faces, pivot, deg, axis):
    bmesh.ops.rotate(b.bm, cent=pivot, matrix=Matrix.Rotation(math.radians(deg), 3, axis),
                     verts=_verts_of(faces))


def _lp(p, pivot, deg, axis="X"):
    """Acelasi punct dupa aceeasi rotatie ca `_rot` (pentru a lega brate de torsul inclinat)."""
    return Vector(pivot) + Matrix.Rotation(math.radians(deg), 3, axis) @ (Vector(p) - Vector(pivot))


# ===========================================================================
# 1. TRENUL SAGANO
# ===========================================================================
TRAIN_RED = CAR_RED          # exceptie de nod: Train_Body
TRAIN_TRIM = KERB_RED
TRAIN_ROOF = ASPHALT
TRAIN_UNDER = ASPHALT
TRAIN_WHEEL = VOLCANIC_BLACK
TRAIN_GLASS = VOLCANIC_BLACK


def sagano_train():
    """`sagano_train.png` -- elementele de pe decupare:
    - 4 corpuri in linie: locomotiva scunda (stanga in desen = FATA) + 3
      vagoane identice ca lungime, rosii, cu acoperis arcuit gri-inchis.
    - locomotiva: capota (boiler) joasa in fata cu un COS negru inalt cu
      palnie, cabina inalta spre vagon cu o fereastra laterala patrata, un
      ventilator mic pe acoperisul cabinei, 3 axe de roti.
    - vagonul 1: 4 ferestre mari dreptunghiulare; vagonul 2: 5; vagonul 3: 6
      (acelasi gabarit, ferestre tot mai dese spre coada). 2 ventilatoare
      dreptunghiulare mai deschise pe acoperis.
    - sasiu negru jos, cate 2 boghiuri cu 2 axe pe vagon (4 roti vizibile
      pe parte), tampoane la capete. Fara livrea, fara text.
    Cote: ~25 m x 2.4 x 3.2 (cosul pana la 3,2; acoperisul vagoanelor 3,22)."""
    body, trim, roof, under, glass = (Builder() for _ in range(5))

    def wheels(yb, r=0.4, pitch=0.7):
        for dy in (-pitch, pitch):
            under.cylinder((0, yb + dy, r), 0.07, 1.9, TRAIN_UNDER, segments=6, axis="X")
            for sx in (-1, 1):
                under.cylinder((sx * 0.98, yb + dy, r), r, 0.1, TRAIN_WHEEL,
                               segments=10, axis="X")
                under.cylinder((sx * 1.04, yb + dy, r), 0.12, 0.05, TRAIN_UNDER,
                               segments=6, axis="X")

    def coach(y0, y1, nwin):
        L = y1 - y0
        yc = (y0 + y1) * 0.5
        body.box((0, yc, 1.8), (2.3, L, 1.9), TRAIN_RED)
        under.box((0, yc, 0.7), (2.1, L + 0.2, 0.3), TRAIN_UNDER)
        for sx in (-1, 1):
            trim.box((sx * 1.17, yc, 1.1), (0.06, L, 0.2), TRAIN_TRIM)       # banda de jos
            trim.box((sx * 1.17, yc, 1.56), (0.06, L - 0.04, 0.08), TRAIN_TRIM)  # prag
            trim.box((sx * 1.17, yc, 2.46), (0.06, L - 0.04, 0.08), TRAIN_TRIM)  # buiandrug
        pitch = (L - 1.0) / nwin
        for k in range(nwin):
            yw = y0 + 0.5 + pitch * (k + 0.5)
            for sx in (-1, 1):
                glass.box((sx * 1.14, yw, 2.0), (0.06, pitch * 0.66, 0.84), TRAIN_GLASS)
        for k in range(nwin + 1):
            yp = y0 + 0.5 + pitch * k
            for sx in (-1, 1):
                body.box((sx * 1.17, yp, 2.0), (0.06, pitch * 0.2, 0.9), TRAIN_RED)
        for ye, sg in ((y1, 1), (y0, -1)):
            for sx in (-1, 1):
                glass.box((sx * 0.45, ye + sg * 0.01, 1.75), (0.55, 0.06, 1.2), TRAIN_GLASS)
            under.box((0, ye + sg * 0.12, 0.62), (2.0, 0.24, 0.08), TRAIN_UNDER)   # treapta
            for sx in (-1, 1):
                under.box((sx * 0.85, ye + sg * 0.2, 0.78), (0.24, 0.3, 0.24), TRAIN_UNDER)  # tampon
        # acoperis arcuit (prisma pe Y) + 2 ventilatoare
        roof.prism([(-1.22, 2.7), (1.22, 2.7), (1.2, 2.85), (1.0, 3.05), (0.6, 3.17),
                    (0.0, 3.22), (-0.6, 3.17), (-1.0, 3.05), (-1.2, 2.85)],
                   L + 0.1, TRAIN_ROOF, center=(0, yc, 0))
        for dy in (-1.4, 1.4):
            roof.box((0, yc + dy, 3.25), (0.9, 1.1, 0.1), ASPHALT_EDGE)
        wheels(y0 + 1.3)
        wheels(y1 - 1.3)

    # vagoanele, de la coada (y mic) spre locomotiva (y mare)
    coach(0.3, 6.3, 6)
    coach(7.2, 13.2, 5)
    coach(14.1, 20.1, 4)

    # locomotiva: cabina spre vagon, capota in fata (+Y)
    y0, y1 = 20.9, 24.9
    ycab0, ycab1 = y0, 22.8
    yc = (ycab0 + ycab1) * 0.5
    body.box((0, yc, 1.85), (2.3, ycab1 - ycab0, 2.0), TRAIN_RED)
    glass_y = 21.8
    for sx in (-1, 1):
        glass.box((sx * 1.14, glass_y, 2.1), (0.06, 1.0, 0.8), TRAIN_GLASS)
        trim.box((sx * 1.17, yc, 1.1), (0.06, ycab1 - ycab0, 0.2), TRAIN_TRIM)
        trim.box((sx * 1.17, glass_y, 1.64), (0.06, 1.2, 0.08), TRAIN_TRIM)
        trim.box((sx * 1.17, glass_y, 2.56), (0.06, 1.2, 0.08), TRAIN_TRIM)
        body.box((sx * 1.17, glass_y - 0.62, 2.1), (0.06, 0.14, 0.95), TRAIN_RED)
        body.box((sx * 1.17, glass_y + 0.62, 2.1), (0.06, 0.14, 0.95), TRAIN_RED)
    glass.box((0, y0 - 0.01, 1.8), (0.7, 0.06, 1.1), TRAIN_GLASS)          # usa spre vagon
    roof.prism([(-1.3, 2.85), (1.3, 2.85), (1.15, 3.02), (0.0, 3.1), (-1.15, 3.02)],
               ycab1 - ycab0 + 0.3, TRAIN_ROOF, center=(0, yc, 0))
    roof.box((0.45, yc + 0.3, 3.14), (0.4, 0.5, 0.12), ASPHALT_EDGE)       # ventilator
    # capota (boiler)
    yh = (ycab1 + y1) * 0.5
    body.box((0, yh, 1.55), (2.0, y1 - ycab1, 1.4), TRAIN_RED)
    for sx in (-1, 1):
        trim.box((sx * 1.02, yh, 1.1), (0.06, y1 - ycab1, 0.2), TRAIN_TRIM)
    roof.box((0, yh, 2.28), (2.1, y1 - ycab1 + 0.1, 0.1), TRAIN_ROOF)
    under.cylinder((0, y1 + 0.02, 1.55), 0.62, 0.12, TRAIN_UNDER, segments=10, axis="Y")
    glass.box((0, y1 + 0.08, 2.0), (0.34, 0.14, 0.3), TRAIN_GLASS)         # far
    under.frustum((0, 24.2, 2.72), 0.17, 0.2, 0.95, TRAIN_UNDER, segments=8)  # cos
    under.frustum((0, 24.2, 3.12), 0.18, 0.32, 0.2, TRAIN_UNDER, segments=8)   # palnie
    under.frustum((0, 23.2, 2.42), 0.3, 0.22, 0.28, TRAIN_UNDER, segments=8)  # dom
    # sasiu + boghiuri locomotiva (3 axe)
    under.box((0, (y0 + y1) / 2, 0.7), (2.1, y1 - y0 + 0.2, 0.3), TRAIN_UNDER)
    for yw in (21.7, 23.1, 24.3):
        under.cylinder((0, yw, 0.45), 0.07, 1.9, TRAIN_UNDER, segments=6, axis="X")
        for sx in (-1, 1):
            under.cylinder((sx * 0.98, yw, 0.45), 0.45, 0.1, TRAIN_WHEEL, segments=10, axis="X")
            under.cylinder((sx * 1.04, yw, 0.45), 0.14, 0.05, TRAIN_UNDER, segments=6, axis="X")
    under.box((0, y1 + 0.2, 0.75), (2.2, 0.3, 0.3), TRAIN_UNDER)            # grinda de tampoane
    for sx in (-1, 1):
        under.box((sx * 0.85, y1 + 0.4, 0.78), (0.24, 0.3, 0.24), TRAIN_UNDER)
    return [body.to_object("Train_Body"), trim.to_object("Train_Trim"),
            roof.to_object("Train_Roof"), under.to_object("Train_Under"),
            glass.to_object("Train_Glass")]


# ===========================================================================
# 2. JINRIKISHA
# ===========================================================================
RICK_BLACK = VOLCANIC_BLACK
RICK_CUSHION = CAR_RED        # exceptie de nod: Rick_Red
RICK_CLOTH = ASPHALT
RICK_HAT = SAND_LIGHT
RICK_SKIN = TILE_TERRACOTTA


def jinrikisha():
    """`jinrikisha.png` -- elementele de pe decupare:
    - ricsa cu 2 ROTI MARI cu spite (~12 spite, jante negre, Ø ~1,0 m), caseta
      neagra joasa, PERNA SI SPATAR ROSII (nodul Rick_Red), capota neagra
      mare, rotunjita, coborata spre fata, deschisa in fata (se vede
      captuseala rosie).
    - 2 oglinzi/varfuri: doua BRATE (oiste) negre care pornesc de la caseta
      si se unesc intr-un mâner transversal in fata.
    - alergatorul in FATA, intre brate: palarie conica de paie (tan),
      haina si pantaloni inchisi, picioare in pas, mainile pe brate, usor
      aplecat; mai mic decat capota (~1,4 m, desen = figurina).
    Cote: 2,6 x 1,2 x 1,9 (capota la 1,9)."""
    frame, red, wheels, runner = (Builder() for _ in range(4))
    R = 0.5
    wy = 0.35
    for sx in (-1, 1):
        x = sx * 0.57
        frame_ring = wheels.torus((x, wy, R), R - 0.035, 0.035, RICK_BLACK,
                                  major_seg=14, minor_seg=4, axis="X")
        wheels.cylinder((x, wy, R), 0.08, 0.14, RICK_BLACK, segments=8, axis="X")
        for k in range(12):
            a = math.radians(k * 30.0)
            wheels.beam((x, wy, R), (x, wy + (R - 0.04) * math.cos(a), R + (R - 0.04) * math.sin(a)),
                        0.03, ASPHALT_EDGE)
    wheels.cylinder((0, wy, R), 0.04, 1.1, RICK_BLACK, segments=6, axis="X")   # axa
    # caseta
    frame.box((0, 0.55, 0.62), (0.92, 1.1, 0.1), RICK_BLACK)                    # podea
    for sx in (-1, 1):
        frame.box((sx * 0.45, 0.45, 0.88), (0.06, 0.86, 0.4), RICK_BLACK)       # lateral
    frame.box((0, 1.07, 0.86), (0.96, 0.07, 0.46), RICK_BLACK)                  # parapet fata
    frame.box((0, 1.12, 0.55), (0.9, 0.3, 0.07), RICK_BLACK)                    # scandura picioare
    red.box((0, 0.42, 0.78), (0.78, 0.7, 0.14), RICK_CUSHION)                   # perna
    red.box((0, 0.04, 1.15), (0.78, 0.13, 0.68), RICK_CUSHION)                  # spatar
    # capota: tub arcuit (sectiune in C) loftat pe Y, mai inalt in spate, coborat in fata
    stations = ((-0.10, 1.95, 0.55), (0.25, 1.88, 0.55), (0.65, 1.74, 0.54), (1.0, 1.58, 0.50))
    prev = None
    for (y, ztop, w) in stations:
        zb = 1.0
        outer = []
        for k in range(7):                       # arc exterior stanga -> dreapta
            a = math.pi * k / 6.0
            outer.append((-w * math.cos(a), y, zb + (ztop - zb) * math.sin(a)))
        inner = [(x * 0.9 if abs(x) > 1e-6 else 0.0, yy, zb + (z - zb) * 0.93 - (0.0 if z == zb else 0.04))
                 for (x, yy, z) in outer]
        ring = [frame.bm.verts.new(p) for p in outer] + [frame.bm.verts.new(p) for p in reversed(inner)]
        if prev is not None:
            n = len(ring)
            for i in range(n):
                j = (i + 1) % n
                f = frame.bm.faces.new((prev[i], prev[j], ring[j], ring[i]))
                f[frame.slot] = RICK_BLACK
        else:
            f = frame.bm.faces.new(tuple(ring)); f[frame.slot] = RICK_BLACK
        prev = ring
    f = frame.bm.faces.new(tuple(reversed(prev))); f[frame.slot] = RICK_BLACK
    for sx in (-1, 1):
        frame.beam((sx * 0.46, 0.98, 0.9), (sx * 0.46, 1.0, 1.55), 0.04, RICK_BLACK)
    # oistea + manerul
    for sx in (-1, 1):
        frame.beam((sx * 0.38, 0.9, 0.62), (sx * 0.38, 2.3, 0.92), 0.05, RICK_BLACK)
    frame.beam((-0.42, 2.3, 0.92), (0.42, 2.3, 0.92), 0.05, RICK_BLACK)
    frame.box((0, -0.18, 0.55), (0.1, 0.3, 0.06), RICK_BLACK)                   # sprijin
    # alergatorul (~1,4 m), usor aplecat
    yr = 1.85
    for sx, dy in ((-1, 0.14), (1, -0.14)):
        runner.taper_sweep([(sx * 0.1, yr, 0.74), (sx * 0.1, yr + dy * 0.7, 0.4),
                            (sx * 0.1, yr + dy, 0.05)], [0.075, 0.06, 0.05],
                           RICK_CLOTH, segments=6)
        runner.box((sx * 0.1, yr + dy + 0.07, 0.03), (0.1, 0.26, 0.06), WOOD)
    torso = runner.frustum((0, yr, 0.93), 0.19, 0.15, 0.48, RICK_CLOTH, segments=8)
    head = runner.revolve([(0.04, -0.07), (0.08, -0.03), (0.085, 0.03), (0.06, 0.07), (0.0, 0.09)],
                          RICK_SKIN, segments=8, origin=(0, yr, 1.24))
    hat = runner.frustum((0, yr, 1.35), 0.31, 0.01, 0.22, RICK_HAT, segments=10)
    pivot = (0, yr, 0.72)
    for fs in (torso, head, hat):
        _rot(runner, fs, pivot, -10.0, "X")
    for sx in (-1, 1):
        sh = _lp((sx * 0.17, yr, 1.1), pivot, -10.0)
        hand = (sx * 0.38, 2.15, 0.9)
        runner.beam(sh, hand, 0.075, RICK_CLOTH)
        runner.box(hand, (0.08, 0.08, 0.08), RICK_SKIN)
    return [frame.to_object("Rick_Frame"), red.to_object("Rick_Red"),
            wheels.to_object("Rick_Wheels"), runner.to_object("Rick_Runner")]


# ===========================================================================
# 3. YAKATABUNE
# ===========================================================================
BOAT_HULL = ROCK_LIGHT
BOAT_POST = SAND_MID
BOAT_ROOF = SAND_MID
BOAT_WOOD = WOOD
BOAT_DARK = VOLCANIC_BLACK

# statie: y, semilatime, cota punte, ridicarea fundului
BOAT_STATIONS = ((-4.5, 0.12, 1.30, 0.85), (-4.1, 0.45, 1.12, 0.42), (-3.0, 0.85, 0.95, 0.12),
                 (-1.5, 0.98, 0.86, 0.0), (0.0, 1.0, 0.82, 0.0), (1.5, 0.98, 0.86, 0.0),
                 (3.0, 0.85, 0.98, 0.12), (4.0, 0.5, 1.22, 0.5), (4.5, 0.12, 1.55, 1.0))


def yakatabune():
    """`yakatabune.png` -- elementele de pe decupare:
    - COCA lunga de lemn cu fundul plat si borduri ridicate la capete: PROVA
      (+Y, dreapta in desen) ascutita si mai inalta, pupa (-Y) mai joasa si
      mai tocita; ghirlanda de scanduri (bordura) mai inchisa.
    - CABINA deschisa pe laturi: 6 stalpi pe parte, grinda de streasina pe
      ei, balustrada joasa intre stalpi, interiorul INCHIS la culoare vazut
      printre stalpi; panouri de capat cu o fereastra.
    - ACOPERIS in patru ape, lat (iese peste stalpi), cu nervuri de scandura,
      culoare mai deschisa decat coca. Nicio livrea, niciun text.
    Cote: 9 x 2.2 x 2.4; baza = fundul bordului (plutitor)."""
    hull, wood, post, roof, dark = (Builder() for _ in range(5))
    rings = []
    for y, w, g, lift in BOAT_STATIONS:
        zm = lift + (g - lift) * 0.4
        pts = [(-0.5 * w, y, lift), (0.5 * w, y, lift), (w, y, zm), (w, y, g),
               (-w, y, g), (-w, y, zm)]
        rings.append([hull.bm.verts.new(p) for p in pts])
    for lo, hi in zip(rings, rings[1:]):
        for i in range(6):
            j = (i + 1) % 6
            f = hull.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
            f[hull.slot] = BOAT_HULL
    hull.bm.faces.new(tuple(reversed(rings[0])))[hull.slot] = BOAT_HULL
    hull.bm.faces.new(tuple(rings[-1]))[hull.slot] = BOAT_HULL
    # borduri (ghirlanda) pe marginea de sus
    for (ya, wa, ga, _), (yb, wb, gb, _) in zip(BOAT_STATIONS, BOAT_STATIONS[1:]):
        for sx in (-1, 1):
            wood.beam((sx * wa, ya, ga + 0.04), (sx * wb, yb, gb + 0.04), (0.1, 0.1), BOAT_WOOD)
    wood.beam((0, 4.42, 1.5), (0, 4.62, 1.95), 0.11, BOAT_WOOD)               # prova
    wood.beam((0, -4.42, 1.25), (0, -4.66, 1.52), 0.11, BOAT_WOOD)            # pupa
    # cabina
    wood.box((0, 0, 0.84), (1.8, 6.4, 0.06), SAND_SHADOW)                     # podea
    ys = (-2.8, -1.68, -0.56, 0.56, 1.68, 2.8)
    for sx in (-1, 1):
        for y in ys:
            post.box((sx * 0.92, y, 1.41), (0.12, 0.12, 1.1), BOAT_POST)
        wood.beam((sx * 0.92, -3.0, 1.97), (sx * 0.92, 3.0, 1.97), (0.14, 0.1), BOAT_HULL)
        wood.beam((sx * 0.92, -2.9, 1.28), (sx * 0.92, 2.9, 1.28), (0.08, 0.07), BOAT_HULL)
        dark.box((sx * 0.84, 0, 1.62), (0.04, 5.8, 0.62), BOAT_DARK)         # interior inchis
    for sy in (-1, 1):
        wood.box((0, sy * 3.0, 1.4), (1.8, 0.07, 1.06), BOAT_POST)              # perete de capat
        dark.box((0, sy * 3.05, 1.55), (1.0, 0.06, 0.55), BOAT_DARK)            # fereastra
        post.box((0, sy * 3.0, 1.97), (1.9, 0.12, 0.1), BOAT_HULL)
    # acoperis in patru ape (construit cu creasta pe X, rotit apoi pe Y)
    hip_roof(roof, 0.0, 0.0, 1.98, 3.55, 1.1, 0.52, BOAT_ROOF, ridge_half=2.2,
             lift=0.14, thick=0.12, fascia_slot=BOAT_HULL, tile_step=0.85, rib=0.035, sag=1.3)
    bmesh.ops.rotate(roof.bm, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 3, "Z"),
                     verts=roof.bm.verts[:])
    return [hull.to_object("Boat_Hull"), wood.to_object("Boat_Wood"),
            post.to_object("Boat_Posts"), roof.to_object("Boat_Roof"),
            dark.to_object("Boat_Dark")]


# ===========================================================================
# 4. MONK_SWEEPER
# ===========================================================================
MONK_ROBE = ASPHALT
MONK_HAT = SAND_MID


def monk_sweeper():
    """`monk_sweeper.png` -- elementele de pe decupare:
    - calugar aplecat in fata, cu PALARIE CONICA larga de paie (tan), kimono
      gri-inchis cu maneci largi si guler alb in V, picioare in sandale de
      lemn (geta), cu ciorapi albi.
    - MATURA DE BAMBUS: drug lung (~1,9 m) care porneste jos in fata, dintr-un
      snop evazat de nuiele (brun) si trece pe la mijlocul trupului spre
      spatele umarului, tinut cu ambele maini; varful drugului ajunge la
      inaltimea palariei.
    Cote: 1,75 m inaltime; priveste spre +Y."""
    b = Builder()
    pivot = (0.0, 0.0, 0.85)
    LEAN = -14.0
    for sx in (-1, 1):
        b.box((sx * 0.1, 0.04, 0.03), (0.1, 0.26, 0.06), WOOD)                  # geta
        b.box((sx * 0.1, 0.05, 0.07), (0.07, 0.2, 0.05), FOAM_WHITE)            # tabi
        b.cylinder((sx * 0.09, 0.0, 0.2), 0.045, 0.28, FOAM_WHITE, segments=6)
    skirt = b.frustum((0, 0.0, 0.58), 0.27, 0.2, 0.66, MONK_ROBE, segments=8)
    torso = b.frustum((0, 0.0, 1.1), 0.21, 0.2, 0.5, MONK_ROBE, segments=8)
    collar = b.box((0, 0.14, 1.28), (0.14, 0.04, 0.26), FOAM_WHITE, rotation=Matrix.Rotation(math.radians(-8), 3, "X"))
    head = b.revolve([(0.05, -0.1), (0.09, -0.05), (0.1, 0.02), (0.07, 0.08), (0.0, 0.11)],
                     TILE_TERRACOTTA, segments=8, origin=(0, 0.06, 1.44))
    hat = b.frustum((0, 0.06, 1.66), 0.43, 0.02, 0.24, MONK_HAT, segments=10)
    for fs in (torso, collar, head, hat):
        _rot(b, fs, pivot, LEAN, "X")
    # matura: bundle de nuiele + drug
    bx = -0.17
    b.frustum((bx, 0.72, 0.2), 0.23, 0.06, 0.42, SAND_SHADOW, segments=8)
    b.frustum((bx, 0.72, 0.07), 0.25, 0.2, 0.14, SAND_MID, segments=8)
    b.cylinder((bx, 0.72, 0.4), 0.075, 0.05, DRY_VEGETATION, segments=6)         # legatura
    b.beam((bx, 0.72, 0.38), (bx, -0.05, 1.8), 0.036, DRY_VEGETATION)
    # brate: de la umerii torsului inclinat la mainile de pe drug
    for sx, zh in ((1, 0.86), (-1, 1.16)):
        sh = _lp((sx * 0.2, 0.0, 1.27), pivot, LEAN)
        yh = 0.72 + (-0.05 - 0.72) * (zh - 0.38) / (1.8 - 0.38)
        hand = Vector((bx, yh, zh))
        mid = (sh + hand) * 0.5 + Vector((sx * 0.07, 0.0, -0.04))
        b.beam(sh, mid, 0.13, MONK_ROBE)
        b.beam(mid, hand, 0.095, MONK_ROBE)
        b.box(hand, (0.07, 0.07, 0.07), TILE_TERRACOTTA)
    return [b.to_object("Monk")]


PIECES = {
    "sagano_train": (sagano_train, "vehicles/sagano_train.glb", AO_VEH, 4200, {}),
    "jinrikisha": (jinrikisha, "vehicles/jinrikisha.glb", AO_FIG, 1800, {}),
    "yakatabune": (yakatabune, "vehicles/yakatabune.glb", AO_VEH, 3600, {}),
    "monk_sweeper": (monk_sweeper, "props/monk_sweeper.glb", AO_FIG, 1000, {}),
}

import sys as _sys
_only = [a for a in _sys.argv[_sys.argv.index("--") + 1:]] if "--" in _sys.argv else []
_only = [a for a in _only if not a.endswith(".py") and not a.startswith("-")]
for _name, (_fn, _path, _ao, _bud, _kw) in PIECES.items():
    if _only and _name not in _only:
        continue
    clear_built()
    emit(_fn(), _path, _ao, budget=_bud, **_kw)
report()
