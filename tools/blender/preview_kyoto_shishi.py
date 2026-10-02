"""Planse de control pentru shishi_odoshi.glb, randate din obiectele tocmai
construite (acelasi atlas_material + AO ca in export).

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_shishi.py -- OUT_DIR

Vederi: aproape (3/4), lateral la 3 unghiuri ale tubului (sus / ~orizontal /
lovit), si "sofer" (la 50 m si 120 m pe drum, camera la 10 m inaltime).
Sosea: banda gri y in [0, 11] (pivotul pe margine, axa la y = 5.5), cota
z = -6.6. Tubul se roteste cu `rotation_euler.x = unghi` (+ = gura in sus).
"""
import sys
import math
import os

_here = os.path.dirname(os.path.abspath(__file__)) if "__file__" in globals() else "."
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_kyoto_shishi.py")).read())

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."
os.makedirs(OUT, exist_ok=True)

# Cubul implicit si orice nu e al nostru: hide_render (memoria blender-preview-cub-implicit)
mine = {tube, frame, kakei, stone}
for o in bpy.data.objects:
    if o.type == "MESH" and o not in mine:
        o.hide_render = True

import bmesh
def _slab(name, x0, x1, y0, y1, z, rgb):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in ((x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z))]
    bm.faces.new(vs)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    mat = bpy.data.materials.new(name + "Mat")
    mat.use_nodes = True
    b = mat.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = 1.0
    me.materials.append(mat)
    return ob

road = _slab("PreviewRoad", -400, 150, 0.0, 11.0, GROUND, (0.24, 0.23, 0.24))
bank = _slab("PreviewBank", -400, 150, -60, 0.0, GROUND, (0.30, 0.38, 0.22))
pond = _slab("PreviewPond", -400, 150, 11.0, 80, GROUND - 0.5, (0.18, 0.37, 0.42))
extras = [road, bank, pond]

scene = bpy.context.scene
_light(scene)
_world(scene, warm=(0.55, 0.62, 0.72))
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [
    e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
] else "BLENDER_EEVEE"
scene.render.film_transparent = False

cam = bpy.data.objects.get("PreviewCam")
if cam is None:
    cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
    scene.collection.objects.link(cam)
scene.camera = cam


def _look(eye, target, lens=None, fov=None):
    cam.location = eye
    d = (Vector(target) - Vector(eye)).normalized()
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    if fov:
        cam.data.sensor_width = 36.0
        cam.data.lens = 18.0 / math.tan(math.radians(fov) / 2.0)
    elif lens:
        cam.data.lens = lens


def _render(name, res=(1280, 720)):
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("PREVIEW:", scene.render.filepath)


ANGLES = {"sus": 35.0, "orizontal": 8.0, "lovit": -30.0}
for tag, deg in ANGLES.items():
    tube.rotation_euler = (math.radians(deg), 0.0, 0.0)
    # aproape, 3/4 din fata-stanga (dinspre drum, spre mal)
    _look((-26.0, 22.0, 4.0), (0.0, 3.0, 1.0), fov=50)
    _render("close_%s" % tag)
    # lateral, perpendicular pe tub (privind in -Y = spre mal)
    _look((0.0, -34.0, 0.0), (0.0, 0.0, 0.0), fov=60)
    scene.render.resolution_x = 1280
    _render("side_%s" % tag)
    # soferul: pe axa soselei (y=5.5), cadru de joc (fov 68, 10 m deasupra, privind 20 m inainte)
    for dist in (120, 50):
        _look((-dist - 12.5, 5.5, GROUND + 10.0), (-dist + 25.0, 5.5, GROUND + 1.0), fov=68)
        _render("driver_%s_%d" % (tag, dist))
tube.rotation_euler = (0.0, 0.0, 0.0)
