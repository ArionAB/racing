"""Plansa de vocabular -- randeaza fiecare forma din `jodhpur_shapes.py`
langa cutia de referinta 4 x 1.8 x 1.5 m (brief TASK A), ca sa se poata
verifica prin Read ca fiecare forma citeste ca forma intentionata inainte de
a fi folosita in piesele reale.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py \
        -- build_jodhpur_shapes_sheet.py

`run_build.py` da fiecare script rulat cu globale PROASPETE (un build nu are
voie sa depinda de starea altuia) -- deci vocabularul se incarca aici, in
capul scriptului, cu exec, la fel cum `dio_lib.py` e incarcat de `run_build.py`
insusi.
"""

import math

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

clear_built()

REF = (4.0, 1.8, 1.5)
STONE = ROCK_LIGHT
WALL = FOAM_WHITE
GLOW = VOLCANIC_BLACK

AO = dict(samples=16, dist=4.0, gradient="vertical", low=0.5, high=1.0,
          power=0.85, floor=0.2)

entries = []  # (name, objs, extent_y)


def add(name, objs, extent_y):
    entries.append((name, objs, extent_y))


# 1. arch_opening -- un perete cu un singur gol, cele 3 stiluri unul langa altul
b1 = Builder()
bg1 = Builder()
wall_w, wall_h, wall_t = 6.5, 3.4, 0.5
b1.box((0.0, 0.0, wall_h * 0.5), (wall_w, wall_t, wall_h), STONE)
styles = ["round", "pointed", "cusped"]
for i, st in enumerate(styles):
    cx = -2.0 + i * 2.0
    arch_opening(b1, bg1, (cx, 0.0, 0.0), 1.4, 2.6, 1.3, wall_t, STONE, GLOW,
                 style=st, rotation=None)
o1 = b1.to_object("Shape_ArchOpening")
og1 = bg1.to_object("Shape_ArchOpening_Glow")
add("arch_opening (round/pointed/cusped)", [o1, og1], wall_w)

# 2. arcade
b2 = Builder()
bg2 = Builder()
res = arcade(b2, bg2, (-3.0, 0.0, 0.0), (3.0, 0.0, 0.0), 3, opening_h=2.4,
             pier_h=1.2, pier_w=0.35, wall_t=0.5, slot=STONE, glow_slot=GLOW,
             style="pointed", glass=False)
o2 = b2.to_object("Shape_Arcade")
og2 = bg2.to_object("Shape_Arcade_Glow")
add("arcade (3 opening, open)", [o2, og2], 6.5)

# 3. dome -- hemisphere and onion, side by side
b3 = Builder()
dome(b3, (-1.6, 0.0, 0.0), 1.0, STONE, drum_h=0.4, profile="hemisphere",
     segments=12, ribs=0, lotus_ring=True, finial=True)
dome(b3, (1.6, 0.0, 0.0), 1.0, STONE, drum_h=0.4, profile="onion",
     segments=12, ribs=8, lotus_ring=True, finial=True)
o3 = b3.to_object("Shape_Dome")
add("dome (hemisphere / onion+ribs)", [o3], 4.0)

# 4. chhatri
b4 = Builder()
bg4 = Builder()
chhatri(b4, bg4, (0.0, 0.0, 0.0), 6, 1.1, 1.6, STONE, GLOW, col_r=0.13,
        arch_style="cusped")
o4 = b4.to_object("Shape_Chhatri")
og4 = bg4.to_object("Shape_Chhatri_Glow")
add("chhatri (6 columns)", [o4, og4], 3.0)

# 5. balustrade + railing_on_brackets + balcony_band
b5 = Builder()
balustrade(b5, (-3.0, 0.0, 0.0), (0.2, 0.0, 0.0), 0.6, STONE)
railing_on_brackets(b5, (0.6, 0.0, 0.8), (3.0, 0.0, 0.8), 0.8, WALL)
balcony_band(b5, (0.0, -2.0, 0.0), 1.2, 1.5, 0.25, STONE, segments=16,
             crenellated=True)
o5 = b5.to_object("Shape_Balustrade")
add("balustrade / railing_on_brackets / balcony_band", [o5], 5.0)

# 6. chajja
b6 = Builder()
b6.box((0.0, -0.3, 1.0), (3.0, 0.2, 2.0), STONE)
chajja(b6, (0.0, -0.2, 2.0), 3.4, 0.6, STONE, thickness=0.14, slope=0.4)
o6 = b6.to_object("Shape_Chajja")
add("chajja (wall + cornice)", [o6], 3.4)

# 7. crenellation
b7 = Builder()
b7.box((0.0, 0.0, 0.5), (5.0, 0.4, 1.0), STONE)
crenellation(b7, (-2.5, 0.0, 1.0), (2.5, 0.0, 1.0), 0.5, STONE,
             style="rectangular")
crenellation(b7, (-2.5, 1.0, 1.0), (2.5, 1.0, 1.0), 0.5, STONE,
             style="rounded")
o7 = b7.to_object("Shape_Crenellation")
add("crenellation (rectangular / rounded)", [o7], 5.0)

# 8. solid_stair
b8 = Builder()
b8.box((-2.0, 0.0, 1.5), (1.0, 1.0, 3.0), WALL)
solid_stair(b8, (-1.4, -1.5, 0.0), (-1.4, 1.5, 3.0), 1.0, STONE,
            nosing=True, nosing_slot=WALL)
o8 = b8.to_object("Shape_SolidStair")
add("solid_stair (with cheeks + nosing)", [o8], 4.0)

# 9. stepped_plinth
b9 = Builder()
stepped_plinth(b9, (0.0, 0.0, 0.0),
               [(4.0, 4.0, 0.4), (3.2, 3.2, 0.4), (2.4, 2.4, 0.4)], STONE)
o9 = b9.to_object("Shape_SteppedPlinth")
add("stepped_plinth (3 levels)", [o9], 4.0)


# --- randare: fiecare forma pe randul ei, cu cutia de referinta alaturi -----

y = 0.0
all_objs = []
for name, objs, extent in entries:
    # un Builder GLOW poate ramane gol (arcade/chhatri cu glass=False nu scrie
    # nimic in `bg`) -- exact cazul normal de folosire, `finish` pe un mesh
    # fara varfuri crapa la set_origin_base, deci se sare, ca ar face-o si un
    # build script real (nu emite un nod gol in GLB).
    objs = [o for o in objs if len(o.data.vertices) > 0]
    for o in objs:
        st = finish(o, bevel=0.02, ao=AO, origin="base", smooth_angle=40.0)
        print(name, "->", o.name, "tris:", st["tris"])
    span = max(extent, 2.0)
    half = span * 0.5
    for o in objs:
        for v in o.data.vertices:
            v.co.y += y + half
        o.data.update()
    # cutia de referinta langa fiecare forma
    import bmesh as _bmesh
    bm = _bmesh.new()
    _bmesh.ops.create_cube(bm, size=1.0)
    me = __import__("bpy").data.meshes.new("RefBox_%d" % len(all_objs))
    bm.to_mesh(me)
    bm.free()
    ref = __import__("bpy").data.objects.new(me.name, me)
    __import__("bpy").context.collection.objects.link(ref)
    ref.scale = REF
    ref.location = (-(extent * 0.5 + REF[0] * 0.5 + 1.0), y + half, REF[2] * 0.5)
    all_objs += objs + [ref]
    y += span + 2.5

save_blend(all_objs, "jodhpur_shapes_sheet.blend")

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
out_path = os.path.join(PROJECT, "docs", "asset_briefs", "img", "jodhpur_shapes.png")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
for o in all_objs:
    if o.data and o.data.materials:
        continue
    if o.type == "MESH":
        o.data.materials.clear()
        o.data.materials.append(atlas_material())
for o in list(__import__("bpy").data.objects):
    if o.type == "MESH":
        o.hide_render = o not in all_objs

shot(all_objs, out_path, azimuth=180.0 - 35.0, elevation=22.0,
     res=(2200, 1300), margin=1.15)
print("plansa vocabular:", out_path)
