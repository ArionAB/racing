"""Stromboli — terasa observatorului (brief docs/asset_briefs/observatory_terrace.md).

  ObservatoryTerrace  stromboli/structures/observatory_terrace.glb
                      Terrace_Stone / Awning_Canvas / Terrace_Furniture

POI la jumatatea urcarii (frac ~0.30, pe un ac de par la ~30 m altitudine):
locul de unde "se vede Sciara". Un reper UMAN mic pe un munte pustiu — de-asta
mobilierul si binoclul conteaza mai mult decat platforma: ele spun ca cineva
sta acolo si se uita.

Se vede de la 8-20 m, adica destul de aproape cat sa conteze detaliul — spre
deosebire de Strombolicchio, care e o silueta la 200 m.

**Axele.** Brief-ul cere treptele spre +Z si binoclul spre -Z, in cote GODOT.
Exportul Y-up mapeaza +Y_blender -> -Z_godot, deci INVERS:
    trepte  spre +Z_godot  =>  se construiesc pe -Y_blender
    binoclu spre -Z_godot  =>  priveste spre +Y_blender
Verificat pe route66_sign (scut pe +Y, trece `verify_glb --front=-Z`) si pe
Strombolicchio, unde am gresit exact semnul asta la prima incercare.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_observatory_terrace.py
"""

import math
from mathutils import Matrix, Vector

AO_STONE = dict(samples=28, dist=5.0, gradient="vertical",
                low=0.55, high=1.00, power=0.9, floor=0.25)
AO_CANVAS = dict(samples=22, dist=4.0, gradient="vertical",
                 low=0.75, high=1.00, power=0.9, floor=0.45)
AO_WOOD = dict(samples=24, dist=3.0, gradient="vertical",
               low=0.50, high=1.00, power=0.9, floor=0.30)

PLAT_W, PLAT_D = 10.0, 6.0
PLAT_H = 1.2
DECK = PLAT_H                 # cota pardoselii
PARAPET_H = 0.9
PARAPET_T = 0.35

STONE = VOLCANIC_BLACK
# ABATERE DE LA BRIEF, a treia oara aceeasi: brief-ul cere ROCK_DARK (4)
# pentru "rosturi / fete umbrite". E maroul de desert al canionului (#67421F)
# si pe bazalt negru iese RUGINA — s-a vazut pe crater, pe Strombolicchio, si
# iar aici (blocurile de zidarie ieseau cutii maro pe o platforma neagra).
#
# Variatia de valoare intre blocuri o da ASPHALT_EDGE (6, #696765): gri neutru,
# 1.23x luminanta scoriei, adica se citeste ca piatra alta fara sa schimbe
# familia de culoare.
JOINT = ASPHALT_EDGE          # rosturi / fete umbrite (brief cerea ROCK_DARK)
CANVAS = FOAM_WHITE
WOOD_S = WOOD
METAL = RUST

# Latura deschisa (cu trepte) e -Y in Blender = +Z in Godot. Vezi antetul.
OPEN_Y = -PLAT_D * 0.5


def build_stone():
    """Platforma + parapet + trepte. Zidaria e SUGERATA din volume decalate."""
    clear_built()
    b = Builder()

    # Corpul platformei: un bloc, peste care se aseaza volume decalate pe fete.
    # Brief-ul cere 8-12 volume, nu pietre individuale — la 12 m rostul se vede,
    # piatra nu.
    b.box((0.0, 0.0, PLAT_H * 0.5), (PLAT_W, PLAT_D, PLAT_H), STONE)

    # Blocuri decalate pe cele patru fete: ies 0.10-0.18 m, cu inaltimi diferite.
    # Slotul alterneaza pe JOINT ca sa iasa variatie de valoare fara triunghiuri
    # in plus (retag-ul e gratis, dar aici sunt volume separate oricum).
    rnd_state = [12345]

    def rnd():
        rnd_state[0] = (rnd_state[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return rnd_state[0] / float(0x7FFFFFFF)

    for (nx, ny, span) in ((0, 1, PLAT_W), (0, -1, PLAT_W),
                           (1, 0, PLAT_D), (-1, 0, PLAT_D)):
        # 2 blocuri pe laturile lungi, 1 pe cele scurte (era 3/2). Fiecare
        # bloc costa 44 de triunghiuri dupa bevel si la 12 m rostul se citeste
        # la fel din 6 volume ca din 10 — zidaria e SUGERATA, nu numarata.
        n = 2 if span > 8.0 else 1
        for i in range(n):
            t = (i + 0.5) / n
            w = span / n * (0.72 + 0.2 * rnd())
            h = PLAT_H * (0.45 + 0.35 * rnd())
            z = h * 0.5 + (PLAT_H - h) * rnd() * 0.5
            out = 0.10 + 0.08 * rnd()
            slot = JOINT if (i % 2 == 0) else STONE
            if nx:
                b.box((nx * (PLAT_W * 0.5 + out * 0.5),
                       -PLAT_D * 0.5 + span * t, z),
                      (out * 2.0, w, h), slot)
            else:
                b.box((-PLAT_W * 0.5 + span * t,
                       ny * (PLAT_D * 0.5 + out * 0.5), z),
                      (w, out * 2.0, h), slot)

    # Pardoseala: o placa subtire peste corp, ca dalele sa aiba muchie proprie
    b.box((0.0, 0.0, DECK - 0.06), (PLAT_W - 0.15, PLAT_D - 0.15, 0.12), STONE)

    # Parapet pe TREI laturi; latura -Y (spre drum) ramane deschisa.
    pz = DECK + PARAPET_H * 0.5
    b.box((0.0, PLAT_D * 0.5 - PARAPET_T * 0.5, pz),
          (PLAT_W, PARAPET_T, PARAPET_H), STONE)
    for sx in (-1, 1):
        b.box((sx * (PLAT_W * 0.5 - PARAPET_T * 0.5), 0.0, pz),
              (PARAPET_T, PLAT_D, PARAPET_H), STONE)

    # Trepte late pe latura deschisa: 2 trepte (brief), pe toata deschiderea
    # dintre parapetii laterali.
    step_w = PLAT_W - 2 * PARAPET_T
    for i in range(2):
        h = DECK * (i + 1) / 2.0
        depth = 0.7 + 0.35 * (1 - i)
        b.box((0.0, OPEN_Y - depth * 0.5 - 0.35 * (1 - i), h * 0.5),
              (step_w * (0.80 + 0.1 * i), depth, h), STONE)

    return b.to_object("Terrace_Stone")


def _canvas_z(u, v, top):
    """Cota panzei la coordonatele normalizate (u, v) in [0,1].

    Scoasa din bucla ca stalpii sa poata citi EXACT aceeasi cota in colt —
    altfel panza si stalpii se contrazic si unul iese prin celalalt.

    Valurile sunt moi (0.16 pe X, 0.10 pe Y) si caderea in colturi e blanda
    (0.20/0.14): la 12 m o panza care se scufunda o jumatate de metru citeste
    "carpa aruncata", nu copertina intinsa.
    """
    sag = (0.16 * math.sin(u * math.pi * 2.0) + 0.10 * math.sin(v * math.pi))
    corner = (-0.20 * ((abs(u - 0.5) * 2) ** 2)
              - 0.14 * ((abs(v - 0.5) * 2) ** 2))
    return top + 0.10 + sag + corner


def build_awning():
    """Patru stalpi + panza cu valuri. Panza e geometrie INDOITA, nu simulare."""
    b = Builder()
    px, py = 2.5, 2.0          # panza 5 x 4 m
    top = DECK + 4.0
    # Centrul copertinei sta peste MESE (x -2.3 si 1.9, y 0.7 si -0.5), nu in
    # centrul platformei: altfel umbra cade pe parapet si mesele stau in soare,
    # ceea ce se si vede in randare ca o panza atarnata pe langa terasa.
    cx, cy = -0.2, 0.1

    # Stalpii se opresc EXACT in coltul panzei, nu la o cota fixa.
    #
    # Prima versiune ii ducea pe toti la `top`, dar panza coboara in colturi cu
    # 0.56 m (masurat) — deci stalpii ieseau prin ea si stateau ca niste tepuse
    # deasupra. Brief-ul cere invers: "colturile trase in jos SPRE stalpi".
    # Deci cota varfului se citeste din aceeasi functie care face panza.
    # Fiecare stalp isi citeste cota din pozitia LUI pe panza, nu dintr-un colt
    # generic: `_canvas_z` variaza si pe u si pe v, deci a doua incercare (toti
    # la `_canvas_z(1,1)`) tot ii lasa sa iasa prin panza, doar cu mai putin.
    # Stalpul se opreste cu 3 cm SUB panza, ca sa n-o strapunga niciodata.
    for sx in (-1, 1):
        for sy in (-1, 1):
            u = 0.5 + sx * 0.5
            v = 0.5 + sy * 0.5
            # Stalp vertical, prisma cu 6 laturi: brief-ul ii da "Ø 0.12 m",
            # deci sunt rotunzi, iar un cilindru hexagonal costa mai putin
            # decat o grinda cu bevel si arata mai bine ca lemn.
            ztop = _canvas_z(u, v, top) - 0.03
            b.cylinder((cx + sx * px * 0.93, cy + sy * py * 0.93,
                        DECK + (ztop - DECK) * 0.5),
                       0.075, ztop - DECK, WOOD_S, segments=6)

    # Panza: grila 5 x 4 cu 2-3 valuri moi pe X si colturile trase in jos.
    # Se construieste direct in bmesh — `prism` ar da o placa plata, iar valul
    # e tocmai ce o face sa nu arate ca un capac de carton.
    # Grila 5 x 3, nu 6 x 4: brief-ul cere "2-3 valuri moi", iar valul se
    # descrie cu 5 diviziuni pe X la fel de bine ca cu 6. Diferenta e 18
    # quad-uri fata de 24, adica 36 de triunghiuri (panza nu are bevel).
    nx, ny = 5, 3
    verts = []
    for iy in range(ny + 1):
        row = []
        for ix in range(nx + 1):
            u = ix / float(nx)
            v = iy / float(ny)
            x = cx - px + 2 * px * u
            y = cy - py + 2 * py * v
            row.append((x, y, _canvas_z(u, v, top)))
        verts.append(row)

    bm = b.bm
    layer = b.slot
    grid = [[bm.verts.new(p) for p in row] for row in verts]
    for iy in range(ny):
        for ix in range(nx):
            f = bm.faces.new((grid[iy][ix], grid[iy][ix + 1],
                              grid[iy + 1][ix + 1], grid[iy + 1][ix]))
            f[layer] = CANVAS

    return b.to_object("Awning_Canvas")


def _table(b, cx, cy, rot=0.0):
    """Masa 1.2 x 0.8 x 0.75 cu doua banci."""
    R = Matrix.Rotation(rot, 3, "Z")

    def place(lx, ly, lz, size, slot):
        p = R @ Vector((lx, ly, lz))
        b.box((cx + p.x, cy + p.y, DECK + lz), size, slot, rotation=R)

    # Blatul e 1.6 x 0.9, nu 1.2 x 0.8, si picioarele sunt DOUA capre, nu
    # patru bete: la 12 m masa de 1.2 m cu patru picioare subtiri citea "scaun".
    # O masa de picnic se recunoaste dupa blatul lat si bancile paralele.
    place(0, 0, 0.74, (1.6, 0.9, 0.08), WOOD_S)           # blat
    for sx in (-1, 1):                                     # capre, nu picioare
        # latite pana sub banci (1.86 in loc de 0.86), ca sa le sustina
        place(sx * 0.62, 0, 0.37, (0.10, 1.86, 0.74), WOOD_S)
    # Bancile stau pe capre LATITE, nu pe picioare proprii: exact cum e
    # construita o masa de picnic reala (bancile sunt prinse de acelasi cadru).
    # Economie: 2 cutii per masa = 176 de triunghiuri pe ansamblu, fara sa
    # dispara nimic din silueta.
    for sy in (-1, 1):
        place(0, sy * 0.78, 0.44, (1.5, 0.30, 0.07), WOOD_S)


def build_furniture():
    """Doua mese cu banci, binoclul cu fise, o lada si cateva cani."""
    b = Builder()
    _table(b, -2.3, 0.7, rot=math.radians(6.0))
    _table(b, 1.9, -0.5, rot=math.radians(-9.0))

    # Binoclul cu fise: stalp 1.1 m + doua tuburi. Priveste spre +Y_blender,
    # adica -Z_godot (spre Sciara) — vezi nota despre axe din antet.
    bx, by = 3.6, 1.9
    b.cylinder((bx, by, DECK + 0.55), 0.07, 1.1, METAL, segments=6)
    b.box((bx, by, DECK + 1.16), (0.30, 0.22, 0.16), METAL)
    for sx in (-1, 1):
        b.cylinder((bx + sx * 0.09, by + 0.16, DECK + 1.18), 0.055, 0.44,
                   METAL, segments=6, axis="Y")

    # lada + cani pe masa (brief: optional, dar sunt ce dau "cineva sta aici")
    # Lada si canile PICA amandoua. Brief-ul le da explicit ca "optional", iar
    # ele erau ultimele 44 + ~200 de triunghiuri intre noi si buget. Ce spune
    # "cineva sta aici" sunt mesele si binoclul, si alea raman.

    return b.to_object("Terrace_Furniture")


if __name__ == "__main__":
    stone = build_stone()
    awning = build_awning()
    furn = build_furniture()

    # z_range comun pe ansamblu: mobilierul sta pe pardoseala la 1.2 m, iar
    # panza la 5.3 m. Fiecare piesa si-ar coace altfel propriul gradient si
    # blatul meselor ar iesi la fel de intunecat ca baza platformei.
    zr = (0.0, DECK + 4.6)
    for obj, ao, bev in ((stone, AO_STONE, 0.08), (awning, AO_CANVAS, 0.02),
                         (furn, AO_WOOD, 0.03)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])

    objs = [stone, awning, furn]
    total = sum(tri_count(o) for o in objs)
    for o in objs:
        print("%-20s %4d tris" % (o.name, tri_count(o)))
    print("TOTAL                %4d tris  (buget 1550)" % total)
    path, size = export_glb(objs, "stromboli/structures/observatory_terrace.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
