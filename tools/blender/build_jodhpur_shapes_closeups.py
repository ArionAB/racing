"""Randari individuale, apropiate, ale fiecarei forme din jodhpur_shapes.py --
plansa de ansamblu (build_jodhpur_shapes_sheet.py) le arata prea mic ca sa se
verifice forma. Un fisier PNG per forma, in
docs/asset_briefs/img/jodhpur_shapes_closeup_<n>.png.
"""

import math

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "jodhpur_shapes.py")).read())

clear_built()

STONE = ROCK_LIGHT
WALL = FOAM_WHITE
GLOW = VOLCANIC_BLACK
AO = dict(samples=16, dist=4.0, gradient="vertical", low=0.5, high=1.0,
          power=0.85, floor=0.2)

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)


def render_one(name, objs, out_name, azimuth=180.0 - 35.0, elevation=20.0,
               res=(1100, 850), margin=1.2):
    objs = [o for o in objs if len(o.data.vertices) > 0]
    for o in objs:
        finish(o, bevel=0.02, ao=AO, origin="base", smooth_angle=40.0)
        o.data.materials.clear()
        o.data.materials.append(atlas_material())
    for o in list(bpy.data.objects):
        if o.type == "MESH":
            o.hide_render = o not in objs
    path = os.path.join(OUT, out_name)
    shot(objs, path, azimuth=azimuth, elevation=elevation, res=res, margin=margin)
    print(name, "->", path)


# 1. arch_opening: round, pointed, cusped -- fiecare separat, fata directa.
# `arch_opening` isi construieste SINGUR panoul din jurul golului (nu se mai
# adauga o cutie plina separata -- ar acoperi golul din exterior, exact bug-ul
# gasit la prima incercare a acestei plansei).
for st in ("round", "pointed", "cusped"):
    b = Builder(); bg = Builder()
    arch_opening(b, bg, (0.0, 0.0, 0.0), 1.4, 2.6, 1.3, 0.5, STONE, GLOW,
                style=st, panel_w=3.0, panel_h=3.6)
    o = b.to_object("Close_Arch_%s" % st)
    og = bg.to_object("Close_Arch_%s_Glow" % st)
    render_one("arch_opening_" + st, [o, og], "jodhpur_shapes_arch_%s.png" % st,
              elevation=8.0)

# 2. arcade
b = Builder(); bg = Builder()
arcade(b, bg, (-3.0, 0.0, 0.0), (3.0, 0.0, 0.0), 3, opening_h=2.4, pier_h=1.2,
      pier_w=0.35, wall_t=0.5, slot=STONE, glow_slot=GLOW, style="pointed",
      glass=False)
o = b.to_object("Close_Arcade")
og = bg.to_object("Close_Arcade_Glow")
render_one("arcade", [o, og], "jodhpur_shapes_arcade.png", elevation=10.0)

# 3. dome hemisphere
b = Builder()
dome(b, (0.0, 0.0, 0.0), 1.2, STONE, drum_h=0.5, profile="hemisphere",
    segments=14, lotus_ring=True, finial=True)
o = b.to_object("Close_Dome_Hemi")
render_one("dome_hemisphere", [o], "jodhpur_shapes_dome_hemisphere.png",
          elevation=15.0)

# 3b. dome onion + ribs
b = Builder()
dome(b, (0.0, 0.0, 0.0), 1.2, STONE, drum_h=0.5, profile="onion",
    segments=14, ribs=10, lotus_ring=True, finial=True)
o = b.to_object("Close_Dome_Onion")
render_one("dome_onion", [o], "jodhpur_shapes_dome_onion.png", elevation=15.0)

# 4. chhatri
b = Builder(); bg = Builder()
chhatri(b, bg, (0.0, 0.0, 0.0), 6, 1.1, 1.6, STONE, GLOW, col_r=0.13,
       arch_style="cusped")
o = b.to_object("Close_Chhatri")
og = bg.to_object("Close_Chhatri_Glow")
render_one("chhatri", [o, og], "jodhpur_shapes_chhatri.png", elevation=14.0)

# 5. balustrade
b = Builder()
balustrade(b, (-2.0, 0.0, 0.0), (2.0, 0.0, 0.0), 0.7, STONE)
o = b.to_object("Close_Balustrade")
render_one("balustrade", [o], "jodhpur_shapes_balustrade.png", elevation=18.0)

# 5b. railing_on_brackets
b = Builder()
railing_on_brackets(b, (-2.0, 0.0, 0.0), (2.0, 0.0, 0.0), 0.8, WALL)
o = b.to_object("Close_RailBrackets")
render_one("railing_on_brackets", [o], "jodhpur_shapes_railing_brackets.png",
          elevation=8.0)

# 5c. balcony_band
b = Builder()
balcony_band(b, (0.0, 0.0, 0.0), 1.2, 1.5, 0.25, STONE, segments=16,
            crenellated=True)
o = b.to_object("Close_BalconyBand")
render_one("balcony_band", [o], "jodhpur_shapes_balcony_band.png", elevation=18.0)

# 6. chajja
b = Builder()
b.box((0.0, -0.3, 1.0), (3.0, 0.2, 2.0), STONE)
chajja(b, (0.0, -0.2, 2.0), 3.4, 0.6, STONE, thickness=0.14, slope=0.4)
o = b.to_object("Close_Chajja")
render_one("chajja", [o], "jodhpur_shapes_chajja.png", elevation=2.0)

# 7. crenellation
b = Builder()
b.box((0.0, 0.0, 0.5), (5.0, 0.4, 1.0), STONE)
crenellation(b, (-2.5, 0.0, 1.0), (2.5, 0.0, 1.0), 0.5, STONE,
            style="rectangular")
o = b.to_object("Close_Crenel_Rect")
render_one("crenellation_rect", [o], "jodhpur_shapes_crenel_rect.png",
          elevation=10.0)

b = Builder()
b.box((0.0, 0.0, 0.5), (5.0, 0.4, 1.0), STONE)
crenellation(b, (-2.5, 0.0, 1.0), (2.5, 0.0, 1.0), 0.5, STONE, style="rounded")
o = b.to_object("Close_Crenel_Round")
render_one("crenellation_round", [o], "jodhpur_shapes_crenel_round.png",
          elevation=10.0)

# 8. solid_stair
b = Builder()
solid_stair(b, (-1.4, -1.5, 0.0), (-1.4, 1.5, 3.0), 1.0, STONE, nosing=True,
           nosing_slot=WALL)
o = b.to_object("Close_Stair")
render_one("solid_stair", [o], "jodhpur_shapes_solid_stair.png", azimuth=140.0,
          elevation=20.0)

# 9. stepped_plinth
b = Builder()
stepped_plinth(b, (0.0, 0.0, 0.0),
              [(4.0, 4.0, 0.4), (3.2, 3.2, 0.4), (2.4, 2.4, 0.4)], STONE)
o = b.to_object("Close_Plinth")
render_one("stepped_plinth", [o], "jodhpur_shapes_stepped_plinth.png",
          elevation=25.0)

print("gata")
