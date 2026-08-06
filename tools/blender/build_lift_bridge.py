"""bridge_ramp.glb + tall_ship.glb — piesele podului mobil din Okinawa manual.

Sursa e Kenney Watercraft Pack (CC0), cerut explicit de dezvoltator:
`ramp-wide.glb` pentru rampa si `ship-large.glb` pentru vapor. Amandoua intra
prin acelasi lant ca restul assets-urilor (docs/blender_export.md): UV colapsat
pe sloturi de paleta, AO copt in vertex colors, zero texturi proprii.

DE CE NU SE FOLOSESC ASA CUM VIN: kitul Kenney isi aduce `colormap.png`, adica
al 23-lea material intr-o garda care numara materialele per pista. Culoarea lui
nu se pierde insa — `_slot_from_colormap` citeste chiar pixelul din colormap
pentru fiecare fata si alege slotul nostru cel mai apropiat. Coca ramane
maro-lemn, panzele albe, drapelele colorate, fara ca cineva sa scrie de mana o
tabela de corespondenta care ar ramane in urma la prima piesa noua din kit.

RAMPA nu e o singura bucata de kit scalata: `ramp-wide` are 5.14 m, iar soseaua
14. Scalata pe X de 2.7 ori, fiecare scandura ar fi iesit de 1.7 m latime —
adica o punte de barne de tren, nu de scanduri. Se pun TREI bucati cap la cap,
deci grinzile isi pastreaza sectiunea si numarul lor creste cu latimea, cum se
intampla la o rampa adevarata.

Rulare (Blender, namespace comun cu dio_lib):
    g = {"__name__": "__main__", "__file__": r"<repo>/tools/blender/dio_lib.py"}
    exec(open(r"<repo>/tools/blender/dio_lib.py").read(), g)
    exec(open(r"<repo>/tools/blender/build_lift_bridge.py").read(), g)
"""

import bmesh
import bpy
import os
from mathutils import Matrix, Vector

KIT = r"D:/GameDev/downloaded assets/kenney_watercraft-pack/Models/GLB format"

# Sloturile candidate pentru potrivirea de culoare. NU toata paleta:
#   - accentele de masina (14..16) sunt rezervate prin style_bible §1, altfel
#     coca portocalie a kitului ar fi nimerit in CAR_RED si vaporul ar fi
#     concurat cu masinile pentru atentie;
#   - apa (17/18) n-are ce cauta pe o coca;
#   - TILE_TERRACOTTA e slotul de OLANE, si tocmai el e cel mai apropiat
#     numeric de maro-portocaliul kitului: prima rulare a dat rampa 85%
#     terracotta, adica o punte de scanduri vopsita in acoperis de casa de sat,
#     la 400 m de satul care chiar are acoperisurile alea. Potrivirea de
#     culoare nu stie ce e obiectul; lista asta ii spune.
CANDIDATES = [SAND_LIGHT, SAND_MID, SAND_SHADOW, ROCK_LIGHT, ROCK_DARK,
              ASPHALT, ASPHALT_EDGE, KERB_RED, CONCRETE, WOOD, RUST, PAINTED,
              CACTUS_GREEN, DRY_VEGETATION, CORAL_SAND, VOLCANIC_BLACK,
              TROPICAL_GREEN, FOAM_WHITE]

# Latimea soselei pe Okinawa (2 * half_width) si profilul rampei. Unghiul iese
# atan(1.6 / 5.0) = 17.7°, adica exact panta cu care o masina la ~26 m/s trece
# golul de 14 m — vezi LiftBridgeHazard pentru calcul.
RAMP_WIDTH = 14.0
RAMP_RUN = 5.0
RAMP_RISE = 1.6
RAMP_TILES = 3


def _colormap_pixels(obj):
    """Pixelii texturii sursa a obiectului, ca (w, h, lista de float RGBA)."""
    for slot in obj.material_slots:
        mat = slot.material
        if mat is None or not mat.use_nodes:
            continue
        for node in mat.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image is not None:
                img = node.image
                return img.size[0], img.size[1], list(img.pixels)
    return 0, 0, []


_SLOT_RGB = {}


def _slot_colors():
    """Culoarea medie a fiecarui slot, citita din ATLASUL REAL.

    Nu dintr-o tabela de HEX copiata din palette.gd: o a doua copie a paletei ar
    ramane in urma la prima recalibrare de culoare (si a fost deja una, in
    august 2026). Atlasul e artefactul din care se vopseste jocul, deci el e
    sursa. Se mediaza pe latimea slotului fiindca sloturile sunt patch-uri
    texturate, nu patrate uniforme — un singur pixel ar prinde un fir de lemn.
    """
    if _SLOT_RGB:
        return _SLOT_RGB
    img = bpy.data.images.get("palette_atlas.png")
    # O sesiune Blender tine imaginile intre rulari, iar scripturile astea se
    # ruleaza din git worktree-uri care apar si dispar. Un `palette_atlas.png`
    # ramas de la un worktree sters are size (0, 0) si zero pixeli — nu da
    # eroare, doar intoarce negru pentru toate sloturile, deci TOATA geometria
    # ar cadea pe slotul 0. S-a intamplat; de-aia se verifica `has_data`.
    if img is None:
        img = bpy.data.images.load(ATLAS)
    elif not img.has_data or img.size[0] == 0:
        img.filepath = ATLAS
        img.reload()
    w, h, px = img.size[0], img.size[1], list(img.pixels)
    if w == 0 or h == 0:
        raise RuntimeError("palette_atlas.png nu s-a putut citi din " + ATLAS)
    band = w // SLOTS
    row = h // 2
    for slot in range(SLOTS):
        acc = [0.0, 0.0, 0.0]
        # Marginea slotului se sare: acolo filtrarea amesteca vecinul.
        xs = range(slot * band + band // 4, slot * band + band - band // 4)
        for x in xs:
            i = (row * w + x) * 4
            for k in range(3):
                acc[k] += px[i + k]
        n = float(max(len(xs), 1))
        _SLOT_RGB[slot] = [_to_srgb(acc[k] / n) for k in range(3)]
    return _SLOT_RGB


_TIMBER = [WOOD, SAND_SHADOW, ROCK_DARK, CONCRETE, RUST]


def _nearest_slot(rgb, candidates=None):
    """Slotul de paleta cel mai apropiat de o culoare, in spatiu sRGB.

    Distanta e ponderata pe verde (coeficientii de luminanta): doua culori cu
    aceeasi valoare dar nuante diferite trebuie sa ramana distincte, pe cand
    doua nuante apropiate la valori diferite nu au voie sa colapseze — altfel
    puntea si coca, care difera doar in valoare, ar fi primit acelasi slot.
    """
    table = _slot_colors()
    pool = candidates or CANDIDATES
    best, best_d = pool[0], 1e9
    for slot in pool:
        ref = table[slot]
        d = (2.0 * (ref[0] - rgb[0]) ** 2 + 4.0 * (ref[1] - rgb[1]) ** 2
             + (ref[2] - rgb[2]) ** 2)
        if d < best_d:
            best_d, best = d, slot
    return best


# Paleta noastra e scrisa in HEX de sRGB, imaginile Blender sunt liniare.
def _to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055


def _tag_from_colormap(obj, src_uv_obj=None, candidates=None):
    """Scrie atributul de fata `slot` din culoarea citita in colormap.

    Se cheama INAINTE de orice transformare de UV: `finish()` colapseaza
    UV-urile pe sloturi si sterge informatia din care s-a decis slotul.

    `candidates` restrange paleta pentru piesele al caror MATERIAL e cunoscut
    dinainte. Potrivirea pe culoare nu stie ce e obiectul, iar maro-portocaliul
    kitului cade cel mai aproape de sloturile de piatra si de olane: rampa,
    care e din scanduri, ar fi primit granulatia de roca din detail_mask.
    """
    me = obj.data
    w, h, px = _colormap_pixels(src_uv_obj or obj)
    attr = me.attributes.get("slot")
    if attr is None:
        attr = me.attributes.new(name="slot", type="INT", domain="FACE")
    uv = me.uv_layers.active
    if uv is None or w == 0:
        for poly in me.polygons:
            attr.data[poly.index].value = WOOD
        return {}
    tally = {}
    for poly in me.polygons:
        u = sum(uv.data[li].uv[0] for li in poly.loop_indices) / poly.loop_total
        v = sum(uv.data[li].uv[1] for li in poly.loop_indices) / poly.loop_total
        x = min(max(int(u * w), 0), w - 1)
        y = min(max(int(v * h), 0), h - 1)
        i = (y * w + x) * 4
        rgb = [_to_srgb(px[i + k]) for k in range(3)]
        slot = _nearest_slot(rgb, candidates)
        attr.data[poly.index].value = slot
        tally[slot] = tally.get(slot, 0) + 1
    return tally


SLOT_NAMES = {SAND_LIGHT: "sand_light", SAND_MID: "sand_mid",
              SAND_SHADOW: "sand_shadow", ROCK_LIGHT: "rock_light",
              ROCK_DARK: "rock_dark", ASPHALT: "asphalt",
              ASPHALT_EDGE: "asphalt_edge", KERB_RED: "kerb_red",
              CONCRETE: "concrete", WOOD: "wood", RUST: "rust",
              PAINTED: "painted", CACTUS_GREEN: "cactus_green",
              DRY_VEGETATION: "dry_veg", CORAL_SAND: "coral_sand",
              VOLCANIC_BLACK: "volcanic", TROPICAL_GREEN: "tropical",
              FOAM_WHITE: "foam_white", TILE_TERRACOTTA: "terracotta"}


def _report_tally(label, tally):
    """Cate fete au cazut pe fiecare slot. Se citeste, nu se decoreaza: daca
    tot obiectul aterizeaza pe un singur slot, potrivirea de culoare a esuat
    (s-a intamplat, cu un atlas ramas de la un worktree sters)."""
    total = max(sum(tally.values()), 1)
    parts = ["%s %d%%" % (SLOT_NAMES.get(s, str(s)), round(100.0 * c / total))
             for s, c in sorted(tally.items(), key=lambda kv: -kv[1])]
    print("  %-12s %s" % (label, ", ".join(parts)))


def _load(name):
    if name not in bpy.data.objects:
        bpy.ops.import_scene.gltf(filepath=os.path.join(KIT, name + ".glb"))
    return bpy.data.objects[name]


def _weld(me, dist=1e-4):
    """Sudeaza vertecsii coincidenti — glTF stocheaza varfuri de FATA, deci un
    mesh importat e topologic o gramada de petice. Fara sudura, bevel-ul si
    netezirea lucreaza pe petice si lasa crapaturi reale (vezi
    build_megakit_rocks._weld pentru diagnosticul complet)."""
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=dist)
    bm.to_mesh(me)
    bm.free()


def _copy(src, name):
    me = src.data.copy()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    obj.matrix_world = src.matrix_world.copy()
    return obj


def _bake_transform(obj):
    """Coace matricea in vertecsi — pe copiile din kit rotatia de import (X 90°)
    sta in obiect, iar `join` de mai jos ar amesteca spatii diferite."""
    obj.data.transform(obj.matrix_world)
    obj.matrix_world = Matrix.Identity(4)


def _bbox(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    return lo, hi


def _join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


# ---------------------------------------------------------------------- rampa

def build_ramp():
    src = _load("ramp-wide")
    tiles = []
    tally = {}
    for i in range(RAMP_TILES):
        t = _copy(src, "RampTile%d" % i)
        _bake_transform(t)
        for slot, count in _tag_from_colormap(t, src, _TIMBER).items():
            tally[slot] = tally.get(slot, 0) + count
        tiles.append(t)
    _report_tally("ramp", tally)
    lo, hi = _bbox(tiles[:1])
    span = hi - lo
    # Bucatile se aseaza cap la cap pe X, cu o suprapunere de 2 cm ca sa nu
    # ramana o fanta de lumina in cusatura (aceeasi grija ca la sample_edge).
    step = span.x - 0.02
    for i, t in enumerate(tiles):
        t.data.transform(Matrix.Translation(Vector((
            (i - (RAMP_TILES - 1) * 0.5) * step, 0.0, 0.0))))
    obj = _join(tiles, "Bridge_Ramp")
    _weld(obj.data)

    lo, hi = _bbox([obj])
    span = Vector((max(hi.x - lo.x, 1e-6), max(hi.y - lo.y, 1e-6),
                   max(hi.z - lo.z, 1e-6)))
    mid = (lo + hi) * 0.5
    obj.data.transform(
        Matrix.Diagonal(Vector((RAMP_WIDTH / span.x, RAMP_RUN / span.y,
                                RAMP_RISE / span.z)).to_4d())
        @ Matrix.Translation(Vector((-mid.x, -mid.y, -lo.z))))
    # Panta trebuie sa urce spre +Y (= Godot -Z, sensul de mers). Sursa e o
    # cala de lansare, deci coboara spre apa; daca vertexul cel mai inalt a
    # iesit la -Y, piesa se intoarce ACUM, nu in cod.
    top_y = max(v.co.y for v in obj.data.vertices if v.co.z > RAMP_RISE * 0.8)
    if top_y < 0.0:
        obj.data.transform(Matrix.Rotation(3.141592653589793, 4, "Z"))
    return obj


# ---------------------------------------------------------------------- vapor

def build_ship():
    src = _load("ship-large")
    parts = [src] + [c for c in src.children_recursive if c.type == "MESH"]
    copies = []
    for p in parts:
        c = _copy(p, "ShipPart_" + p.name)
        _bake_transform(c)
        _report_tally(p.name, _tag_from_colormap(c, p))
        copies.append(c)
    obj = _join(copies, "Tall_Ship")
    # FARA sudura globala: panzele si drapelele sunt suprafete separate lipite
    # de catarg, iar remove_doubles peste tot le-ar coase de el si ar strica
    # normalele. Sursa e curata oricum — kitul e modelat, nu scanat.
    return obj


# ------------------------------------------------------------------- executie

clear_built("Bridge_")
clear_built("Tall_")
clear_built("RampTile")
clear_built("ShipPart_")

_slot_colors()  # esueaza zgomotos daca atlasul lipseste, inainte de orice munca

ramp = build_ramp()
# Bevel 0: sursa are deja muchii modelate, iar o rampa e din scanduri drepte.
# AO scurt (dist 1.2): piesa are 1.6 m inaltime, o raza mai mare ar innegri
# scandurile una de la alta pana la sters.
ramp_stats = finish(ramp, bevel=0.0, ao=dict(samples=20, dist=1.2,
                                             gradient="vertical", low=0.52,
                                             high=1.0, power=0.9, floor=0.16),
                    origin="base")
print("Bridge_Ramp  %.1f x %.1f x %.1f m | %4d tris | AO %.2f..%.2f"
      % (ramp.dimensions.x, ramp.dimensions.y, ramp.dimensions.z,
         ramp_stats["tris"], ramp_stats["ao_min"], ramp_stats["ao_max"]))

ship = build_ship()
# `origin="base"` pune zero la CHILA. Codul de joc scufunda vaporul cu
# LiftBridgeHazard.SHIP_DRAFT ca sa iasa linia de apa unde trebuie — pragul de
# plutire e o decizie de scena, nu de asset.
ship_stats = finish(ship, bevel=0.0, ao=dict(samples=24, dist=2.6,
                                             gradient="vertical", low=0.45,
                                             high=1.0, power=0.85, floor=0.14),
                    origin="base", smooth_angle=40.0)
print("Tall_Ship    %.1f x %.1f x %.1f m | %4d tris | AO %.2f..%.2f"
      % (ship.dimensions.x, ship.dimensions.y, ship.dimensions.z,
         ship_stats["tris"], ship_stats["ao_min"], ship_stats["ao_max"]))

report_slits([ramp], "bridge_ramp")

ramp.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb([ramp], "bridge_ramp.glb"))
print("BLEND: %s (%d B)" % save_blend([ramp], "bridge_ramp.blend"))
ship.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb([ship], "tall_ship.glb"))
print("BLEND: %s (%d B)" % save_blend([ship], "tall_ship.blend"))

ship.location = (24.0, 0.0, 0.0)
