"""Kyoto -- podurile (brief docs/asset_briefs/kyoto_kit.md §1.5).

  kyoto/structures/tsutenkyo_roof_module.glb   pod acoperit, modul 6 m
  kyoto/structures/togetsukyo_module.glb       punte joasa pe piloni, modul 10 m
  kyoto/structures/iron_truss_bridge.glb       pod feroviar cu zabrele, drumul pe sub el

MODULELE (tsutenkyo, togetsukyo) se repeta pe o curba de cod nou: origine in
centru pe axa, nivelul puntii la Z = 0 (Blender; Y in Godot), lungimea pe Y
(+Y Blender = -Z Godot = "inainte"), capete plane si identice la Y = +-L/2.
Piloni coboara sub Z = 0, acoperisul urca deasupra: de aceea NU se foloseste
`kyoto_shapes.emit` (care recentreaza ansamblul si il pune pe sol) -- aici
`emit_fixed` pastreaza coordonatele construite. Verify: `--origin=waterline`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_kyoto_bridges.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "kyoto_shapes.py")).read())

# Sloturi (brief kyoto_kit §0.4; tigla pe ASPHALT_EDGE 6 -- decizia valului
# anterior, VOLCANIC_BLACK iese violet pe randare)
TILE = ASPHALT_EDGE        # tigla kawara, nervuri in geometrie
BEAM = LOG_DARK            # grinzi, fateta streasinii, console
POST = WOOD                # stalpi, balustrade, punte
IRON = CAR_RED             # zabrelele (RUST iese maro-ocru; exceptie --allow-car-slots=Truss_Iron)
STONE = MARBLE_GREY        # culei, balast
TIE = LOG_DARK             # traverse
STEEL = ASPHALT            # sine

clear_built()


def emit_fixed(objs, path, ao, budget=None, z_range=None):
    """Ca `emit`, dar FARA recentrarea ansamblului: coordonatele construite
    ramana cele din contract (centru pe axa, puntea la Z = 0)."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    ao = dict(ao)
    ao["z_range"] = z_range or (min(zs), max(zs))
    total, per_node = 0, {}
    for o in objs:
        st = finish(o, bevel=0.0, ao=ao, origin=None, smooth_angle=None)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "kyoto/" + path)
    RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))
    return total


def slab_profile(b, pts_top, pts_bot, y0, y1, top_slot, bot_slot, edge_slot):
    """Prisma extrudata pe Y dintr-un profil in plan XZ: `pts_top` si `pts_bot`
    au acelasi numar de puncte (de la -X la +X). Fete: sus, jos, capete plate
    la y0/y1 si cele doua margini (streasinile)."""
    n = len(pts_top)
    V = lambda x, y, z: b.bm.verts.new((x, y, z))
    top = [(V(x, y0, z), V(x, y1, z)) for x, z in pts_top]
    bot = [(V(x, y0, z), V(x, y1, z)) for x, z in pts_bot]
    faces = []

    def quad(vs, slot):
        f = b.bm.faces.new(vs)
        f[b.slot] = slot
        faces.append(f)

    for i in range(n - 1):
        quad((top[i][0], top[i][1], top[i + 1][1], top[i + 1][0]), top_slot)
        quad((bot[i + 1][0], bot[i + 1][1], bot[i][1], bot[i][0]), bot_slot)
        # capete (y0: normala -Y; y1: normala +Y)
        quad((top[i][0], top[i + 1][0], bot[i + 1][0], bot[i][0]), edge_slot)
        quad((top[i + 1][1], top[i][1], bot[i][1], bot[i + 1][1]), edge_slot)
    quad((top[0][1], top[0][0], bot[0][0], bot[0][1]), edge_slot)       # margine -X
    quad((top[-1][0], top[-1][1], bot[-1][1], bot[-1][0]), edge_slot)   # margine +X
    return set(faces)


# ---------------------------------------------------------------------------
# tsutenkyo_roof_module
# ---------------------------------------------------------------------------

AO_TSU = dict(samples=12, dist=3.0, gradient="vertical", low=0.78, high=1.0,
              power=0.8, floor=0.35)


def build_tsutenkyo():
    """`tsutenkyo_roof_module.png` -- lista de elemente (inainte de modelare):

    - acoperis lung de tigla gri-inchis in doua ape (capetele hip raman la
      cap de pod, in cod), profil usor concav cu streasina ridicata la varf;
      nervuri de kawara pe fiecare panta, coama groasa;
    - sub el o cusca deschisa de stalpi de lemn portocaliu-brun la pas de
      ~1,5 m (pe decupare ~12 deschideri), cu grinda longitudinala sus si
      console (brate) care sustin streasina;
    - balustrada de lemn pe ambele laturi: lisa de sus, lisa de mijloc si
      sipci verticale; laturile raman DESCHISE (se vede prin ele);
    - sub punte: grinzi transversale si piloni scurti de lemn, pe perechi;
    - iese din contur: streasina ridicata, coama.
    Cote: 6 m lung, streasina 9 m lat, coama la 5 m.
    """
    L = 6.0
    h = L / 2
    roof, wood, rail = Builder(), Builder(), Builder()
    px = 5.4                      # axa stalpilor (drumul real +-4,5 m + parapet; liber interior 10,5 m)

    # --- acoperis: profil concav, coama la z=5.0, streasina 4.5 m ---
    half = [(0.0, 8.3), (1.5, 7.9), (3.15, 6.85), (4.95, 5.75), (6.3, 5.1),
            (6.9, 5.3)]
    thick = [0.34, 0.34, 0.36, 0.40, 0.46, 0.5]
    top = [(-x, z) for x, z in reversed(half[1:])] + half
    thk = [t for t in reversed(thick[1:])] + thick
    bot = [(x, z - t) for (x, z), t in zip(top, thk)]
    slab_profile(roof, top, bot, -h, h, TILE, BEAM, BEAM)
    # nervuri de kawara: 8 pe modul, pas 0,75 (perioada divide 6 m: cusatura curata)
    for k in range(8):
        y = -h + 0.375 + 0.75 * k
        for i in range(len(top) - 1):
            (xa, za), (xb, zb) = top[i], top[i + 1]
            roof.beam((xa, y, za + 0.03), (xb, y, zb + 0.03), (0.10, 0.07), TILE)
    # coama: baza groasa + creasta
    roof.box((0, 0, 8.42), (1.1, L, 0.34), TILE)
    roof.box((0, 0, 8.68), (0.6, L, 0.2), BEAM)

    # --- stalpi, grinzi, console (Tsu_Wood) ---
    pys = [-h + 0.075, -1.5, 0.0, 1.5, h - 0.075]
    for y in pys:
        d = 0.15 if abs(y) > 2.9 else 0.30
        for sx in (-1, 1):
            wood.box((sx * px, y, 2.475), (0.30, d, 4.95), POST)           # stalp
            # consola de la stalp la streasina
            wood.beam((sx * px, y, 4.3), (sx * 6.2, y, 5.05), (d, 0.22), BEAM)
            # contrafisa spre interior
            wood.beam((sx * px, y, 4.4), (sx * 3.8, y, 5.1), (d, 0.20), BEAM)
        # grinda transversala sub coama
        wood.box((0, y, 5.0), (2 * px + 0.5, d, 0.34), BEAM)
        wood.box((0, y, 6.57), (0.26, d, 2.8), BEAM)
        for sx in (-1, 1):
            wood.box((sx * 2.7, y, 5.98), (0.22, d, 1.62), BEAM)                       # popa
    for sx in (-1, 1):
        wood.box((sx * px, 0, 5.0), (0.38, L, 0.34), BEAM)               # pana
        wood.box((sx * 6.2, 0, 5.05), (0.30, L, 0.22), BEAM)             # pana streasina
    # punte: talpi laterale, grinzi transversale, piloni
    for sx in (-1, 1):
        wood.box((sx * px, 0, -0.22), (0.50, L, 0.44), POST)
    for y in (-1.5, 0.0, 1.5):
        wood.box((0, y, -0.40), (2 * px, 0.30, 0.30), POST)
    wood.box((0, 0, -0.10), (2 * px - 0.2, L, 0.12), POST)                # podina (sub drum)
    for y in (-1.5, 1.5):
        for sx in (-1, 1):
            wood.box((sx * px, y, -0.75), (0.42, 0.42, 1.0), POST)        # pilon

    # --- balustrada: lise + sipci (Tsu_Rail) ---
    for sx in (-1, 1):
        rail.box((sx * px, 0, 1.08), (0.18, L, 0.14), POST)
        rail.box((sx * px, 0, 0.58), (0.14, L, 0.12), POST)
        for k in range(12):
            y = -2.75 + 0.5 * k
            rail.box((sx * px, y, 0.80), (0.09, 0.09, 0.52), POST)
            rail.box((sx * px, y, 0.29), (0.09, 0.09, 0.50), POST)
    return roof, wood, rail


# ---------------------------------------------------------------------------
# togetsukyo_module
# ---------------------------------------------------------------------------

AO_TOG = dict(samples=12, dist=3.0, gradient="vertical", low=0.72, high=1.0,
              power=0.8, floor=0.30)


def build_togetsukyo():
    """`togetsukyo_module.png` -- lista de elemente:

    - punte joasa lunga de lemn portocaliu-brun, cu marginile ingrosate;
    - balustrada continua pe ambele parti: stalpi cu capac la ~2,5 m, doua
      lise orizontale, sipci verticale dese intre ele;
    - dedesubt grinzi masive si rânduri de piloni scurti si groși, in
      grupuri (bente) la ~2,5 m, cu grinda de capat si contrafise in X;
    - iese din contur: capacele stalpilor.
    Cote: 10 m lung, ~7,8 m lat, ~3 m inaltime (balustrada 1,3 + piloni 1,7).
    """
    L = 10.0
    h = L / 2
    wood, rail = Builder(), Builder()
    dx = 7.6                      # semi-latimea puntii (drumul real +-7,0 m)
    rx = 7.4                      # axa balustradei (liber interior 7,25 m)

    # punte: podina cu margini ingrosate (sub nivelul drumului)
    wood.box((0, 0, -0.10), (2 * dx, L, 0.12), POST)
    for sx in (-1, 1):
        wood.box((sx * (dx - 0.22), 0, -0.26), (0.50, L, 0.60), POST)     # talpa de margine
    for k in range(8):
        y = -h + 0.625 + 1.25 * k
        wood.box((0, y, -0.45), (2 * dx - 0.8, 0.28, 0.28), BEAM)         # grinda transversala
    for sx in (-1, 1):
        for x in (sx * 5.6, sx * 2.8, 0.0):
            wood.box((x, 0, -0.50), (0.30, L, 0.30), BEAM)                # lungerine
    # bente de piloni: la +-1,25 si +-3,75 (spatiere 2,5 si peste cusatura)
    for y in (-3.75, -1.25, 1.25, 3.75):
        for x in (-6.4, -2.2, 2.2, 6.4):
            wood.box((x, y, -1.15), (0.62, 0.62, 1.30), POST)             # pilon
        wood.box((0, y, -0.72), (2 * 7.0, 0.40, 0.34), BEAM)              # grinda de capat
        for sx in (-1, 1):                                               # contrafise X
            wood.beam((sx * 6.4, y, -1.7), (sx * 2.2, y, -0.8), (0.16, 0.30), BEAM)
        wood.box((0, y, -1.62), (2 * 7.0, 0.34, 0.18), BEAM)              # talpa jos

    # balustrada: stalpi la 2,5 m (jumatati la capete), lise, sipci
    for sx in (-1, 1):
        for y in (-h + 0.125, -2.5, 0.0, 2.5, h - 0.125):
            d = 0.25 if abs(y) > 4.8 else 0.50
            rail.box((sx * rx, y, 0.70), (0.30, d, 1.40), POST)
            rail.box((sx * rx, y, 1.46), (0.38, d, 0.14), BEAM)   # capac
        rail.box((sx * rx, 0, 1.12), (0.20, L, 0.16), POST)
        rail.box((sx * rx, 0, 0.62), (0.16, L, 0.14), POST)
        rail.box((sx * rx, 0, 0.14), (0.14, L, 0.28), POST)               # plinta
        for k in range(20):
            y = -h + 0.25 + 0.5 * k
            if min(abs(y - p) for p in (-2.5, 0.0, 2.5, -h, h)) < 0.3:
                continue
            rail.box((sx * rx, y, 0.87), (0.09, 0.09, 0.50), POST)
    return wood, rail


# ---------------------------------------------------------------------------
# iron_truss_bridge
# ---------------------------------------------------------------------------

AO_TRUSS = dict(samples=12, dist=3.5, gradient="vertical", low=0.78, high=1.0,
                power=0.8, floor=0.35)

# Contract inghetat (masurat ca GOL cu tools/blender/measure_gap.py):
GAP_X_HALF = 7.6        # fetele interioare ale culeelor, x = +-7.6 (drumul real +-6,0 m) -> gol 15,2 m
DECK_BOTTOM = 6.3       # intradosul podului, deasupra drumului (z = 0)


def build_truss():
    """`iron_truss_bridge.png` -- lista de elemente:

    - doua ferme laterale cu talpa de sus orizontala si montanti inclinati la
      capete; ~8 panouri cu montanti verticali si diagonale;
    - contravantuiri: traverse sus intre ferme si X de vant;
    - tablier jos: grinzi, balast gri, traverse de lemn inchis si doua sine;
    - culee de piatra la capete, cu cap de zidarie;
    - culoare: rosu-ruginiu pe fier.
    Span 16 m (X), 4,5 m latime (Y). Drumul trece pe sub el, pe Y.
    """
    iron, stone, deck = Builder(), Builder(), Builder()
    yT = 2.1                      # axa fermelor
    zd = DECK_BOTTOM              # intrados (fata de jos a grinzii)
    z_chord = zd + 0.45           # axa talpii de jos
    z_top = zd + 4.0              # axa talpii de sus
    xs = [-6.9, -4.6, -2.3, 0.0, 2.3, 4.6, 6.9]

    for sy in (-1, 1):
        y = sy * yT
        # talpa de jos (grinda cutie) pe toata lungimea
        iron.box((0, y, z_chord), (21.0, 0.5, 0.7), IRON)
        # talpa de sus + montanti inclinati de capat
        iron.box((0, y, z_top), (13.8, 0.5, 0.5), IRON)
        for sx in (-1, 1):
            iron.beam((sx * 10.4, y, z_chord), (sx * 6.9, y, z_top), (0.5, 0.5), IRON)
        # montanti verticali
        for x in xs:
            iron.box((x, y, (z_chord + z_top) / 2), (0.36, 0.36, z_top - z_chord), IRON)
        # diagonale: spre centru, X in panourile centrale
        for i in range(len(xs) - 1):
            xa, xb = xs[i], xs[i + 1]
            if xb <= 0:
                iron.beam((xa, y, z_top), (xb, y, z_chord), (0.32, 0.32), IRON)
            elif xa >= 0:
                iron.beam((xa, y, z_chord), (xb, y, z_top), (0.32, 0.32), IRON)
        for sx in (-1, 1):                                  # panouri de capat
            xe = sx * 6.9
            xi = sx * 6.9
            iron.beam((sx * 10.4, y, z_chord), (xi, y, z_top - 0.0), (0.28, 0.28), IRON)
        # X central (contra-diagonale)
        iron.beam((-2.3, y, z_chord), (0.0, y, z_top), (0.28, 0.28), IRON)
        iron.beam((0.0, y, z_chord), (2.3, y, z_top), (0.28, 0.28), IRON)

    # contravantuiri sus: traverse la fiecare nod + X de vant
    for x in xs:
        iron.box((x, 0, z_top), (0.34, 2 * yT, 0.34), IRON)
    for i in range(len(xs) - 1):
        iron.beam((xs[i], -yT, z_top), (xs[i + 1], yT, z_top), (0.18, 0.18), IRON)
    # portal la capete (talpa de sus intre ferme, jos)
    for sx in (-1, 1):
        iron.box((sx * 7.4, 0, z_top - 0.9), (0.30, 2 * yT, 0.30), IRON)
    # grinzi transversale sub tablier
    for k in range(21):
        x = -10.0 + k
        iron.box((x, 0, zd + 0.15), (0.30, 2 * yT, 0.30), IRON)

    # tablier: balast + traverse + sine
    deck.box((0, 0, zd + 0.62), (21.0, 3.6, 0.34), STONE)                # balast
    for k in range(40):
        x = -9.75 + 0.5 * k
        deck.box((x, 0, zd + 0.88), (0.26, 3.0, 0.20), TIE)
    for ry in (-0.72, 0.72):
        deck.box((0, ry, zd + 1.06), (21.0, 0.16, 0.18), STEEL)

    # culee de piatra: fata dinspre drum la x = +-GAP_X_HALF
    for sx in (-1, 1):
        cx = sx * (GAP_X_HALF + 0.9)
        stone.box((cx, 0, zd * 0.5), (1.8, 5.2, zd), STONE)
        stone.box((cx + sx * 0.15, 0, zd + 0.05), (2.1, 5.6, 0.3), MARBLE_GREY)  # cap
        stone.box((cx + sx * 1.2, 0, 0.9), (1.6, 5.8, 1.8), STONE)                 # soclu in exterior
    return iron, stone, deck


if __name__ == "__main__" or True:
    r, w, rl = build_tsutenkyo()
    emit_fixed([r.to_object("Tsu_Roof"), w.to_object("Tsu_Wood"), rl.to_object("Tsu_Rail")],
               "structures/tsutenkyo_roof_module.glb", AO_TSU, budget=6000)
    w2, rl2 = build_togetsukyo()
    emit_fixed([w2.to_object("Toget_Wood"), rl2.to_object("Toget_Rail")],
               "structures/togetsukyo_module.glb", AO_TOG, budget=4000)
    ir, st, dk = build_truss()
    emit_fixed([ir.to_object("Truss_Iron"), st.to_object("Truss_Stone"),
                dk.to_object("Truss_Deck")],
               "structures/iron_truss_bridge.glb", AO_TRUSS, budget=3000)
    report()
