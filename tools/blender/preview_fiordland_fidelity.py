"""Comparatiile de fidelitate pentru kitul Fiordland -- din GLB-urile EXPORTATE.

Refoloseste randarea din `preview_okinawa.py` (culoarea REALA pe slot, din UV,
inmultita cu AO; fundal #C8C8C8; lumina de zi neutra): corpul lui se executa
fara dispecerul de la coada, apoi se repun caile si camerele pe Fiordland.

  --compare <nume>       decupare (stanga) | randare din GLB (dreapta)
                         -> docs/asset_briefs/img/fiordland_fidelity/<nume>.png
  --all                  toate piesele din PIECES, intr-o singura sesiune
  --sheet <val> a,b,...  aduna comparatiile intr-o plansa
                         -> docs/asset_briefs/img/fiordland_fidelity_<val>.png

    D:/Blender/5.2/../blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_fiordland_fidelity.py -- --all

Decuparile: docs/track_briefs/img/fiordland_assets_v1/<nume>.png
(`crop_fiordland_sheet.py`). Doua cazuri speciale, fiindca o decupare nu e un
fisier: `tree_avalanche` are 4 noduri `Boulder_A..D` la acelasi pivot (se
intind pe X doar pentru randare), iar `FarWall_A`/`SnowRidge_A/B` sunt noduri
din `rocks/fiordland_horizon.glb`.

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock` (daca
esueaza, alt proces randeaza), dupa, `rmdir`.
"""

import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(_HERE, "preview_okinawa.py"), encoding="utf-8").read()
exec(compile(_src[:_src.index("\nargv = sys.argv")], "preview_okinawa.py", "exec"), globals())

MODELS_DIR = os.path.join(PROJ, "assets", "models", "fiordland")
CROPS = os.path.join(PROJ, "docs", "track_briefs", "img", "fiordland_assets_v1")
FID_DIR = os.path.join(PROJ, "docs", "asset_briefs", "img", "fiordland_fidelity")
CLASS_BY_SUFFIX = {}

# In joc, nodurile astea NU arata slotul: `WorldProp` le pune o clasa
# triplanara (world_prop.gd, CLASSES_BY_MODEL), deci culoarea de pe ecran e
# a clasei. Aproximari ale tentei finale (dala x CLASS_TINT, sRGB), doar ca
# comparatia sa judece culoarea care ajunge pe ecran. Cheie (fisier, nod).
_GNEISS, _BARK, _CANOPY, _WETWOOD = "#6A6B6E", "#3B3430", "#486335", "#6B5A48"
CLASS_BY_NODE = {
    ("stirling_ledge", "Wall"): _GNEISS,
    ("torrent_chute", "Rock"): _GNEISS,
    ("chasm_rock", "Rock.001"): _GNEISS,
    ("gneiss_block", "Gneiss_Block"): _GNEISS,
    ("beech_a", "Trunk"): _BARK, ("beech_a", "Crown"): _CANOPY,
    ("beech_b", "Trunk.001"): _BARK, ("beech_b", "Crown.001"): _CANOPY,
    ("beech_c", "Trunk.002"): _BARK, ("beech_c", "Crown.002"): _CANOPY,
    ("beech_dead", "Beech_Dead"): _BARK,
    ("driftwood", "Driftwood"): _WETWOOD,
}

# Piesele native ale kitului care au desen pe planșă (fern_clump_*,
# CloudBank_A sunt reuse / cod, vezi fiordland_inventory.md).
PIECES = [
    "stirling_ledge", "torrent_chute", "traffic_light_pole", "snow_pole", "guard_rock",
    "road_sign_blank", "FarWall_A", "SnowRidge_A", "SnowRidge_B", "wharf", "cafe_shed",
    "heli_pad", "lodge", "luggage_container", "cruise_boat", "kayak_a", "kayak_b",
    "driftwood", "bush_plane", "coach_fiordland", "beech_a", "beech_b", "beech_c",
    "beech_dead", "rata_tree", "tussock_clump", "stump", "chasm_rock", "gneiss_block",
    "chasm_bridge_rail", "tree_avalanche", "scree_slab", "kea", "penguin_tawaki",
]
HORIZON_NODES = {"FarWall_A", "SnowRidge_A", "SnowRidge_B"}

# Planșa e desenata de sus-dreapta, ~25-30 grade: camera la azimut ~-50
# (fata piesei e +Y, deci azimut 90 = din fata).
SPECS = {n: {"camera": {"azimuth": 55.0, "elevation": 24.0, "lens": 60.0, "margin": 1.08}}
         for n in PIECES}
SPECS["coach_fiordland"]["camera"].update(azimuth=40.0)
SPECS["bush_plane"]["camera"].update(azimuth=40.0, elevation=28.0)
SPECS["cruise_boat"]["camera"].update(azimuth=20.0, elevation=20.0)
for _n in ("kayak_a", "kayak_b", "driftwood"):
    SPECS[_n]["camera"].update(azimuth=20.0, elevation=40.0)
SPECS["chasm_rock"]["camera"].update(azimuth=55.0, elevation=35.0)
SPECS["gneiss_block"]["camera"].update(azimuth=55.0, elevation=35.0)
SPECS["stirling_ledge"]["camera"].update(azimuth=205.0, elevation=22.0)
SPECS["torrent_chute"]["camera"].update(azimuth=205.0, elevation=22.0)
SPECS["scree_slab"]["camera"].update(azimuth=55.0, elevation=24.0)
SPECS["wharf"]["camera"].update(azimuth=-20.0, elevation=30.0)
SPECS["chasm_bridge_rail"]["camera"].update(azimuth=10.0, elevation=24.0)
for _n in HORIZON_NODES:
    SPECS[_n]["camera"].update(azimuth=0.0, elevation=6.0)


def _import_piece(name):
    if name in HORIZON_NODES:
        meshes = _import("fiordland_horizon")
        keep = [o for o in meshes if o.name.startswith(name)]
        for o in meshes:
            if o not in keep:
                bpy.data.objects.remove(o, do_unlink=True)
        return keep
    meshes = _import(name)
    for o in meshes:
        hexc = CLASS_BY_NODE.get((name, o.name))
        if hexc:
            _per_slot_tint(o, hexc)
    if name == "tree_avalanche":
        x = 0.0
        for o in sorted(meshes, key=lambda o: o.name):
            lo, hi = _bounds([o])
            o.location.x += x - lo.x
            x += (hi.x - lo.x) + 0.6
        bpy.context.view_layer.update()
    return meshes


def compare_piece(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = os.path.join(CROPS, {"gneiss_block": "chasm_rock"}.get(name, name) + ".png")
    if not os.path.exists(crop):
        print("LIPSA decupare:", crop)
        return
    _clear()
    meshes = _import_piece(name)
    if not meshes:
        return
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    aspect = max(0.5, min(8.0, cw / float(ch)))
    _render(meshes, tmp, res_height=res_height, aspect=aspect, **_camera_for(name))
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])
    try:
        os.remove(tmp)
    except OSError:
        pass


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    for n in args[args.index("--compare") + 1].split(","):
        compare_piece(n)
elif "--all" in args:
    for n in PIECES:
        compare_piece(n, res_height=600)
elif "--sheet" in args:
    val = args[args.index("--sheet") + 1]
    names = args[args.index("--sheet") + 2].split(",")
    _compose(["--sheet", val, "--fid-dir", FID_DIR, "--names", ",".join(names),
              "--out", os.path.join(PROJ, "docs", "asset_briefs", "img",
                                    "fiordland_fidelity_%s.png" % val)])
else:
    print(__doc__)
