"""Planse de control pentru shishimai.glb, randate din obiectele tocmai construite
(acelasi atlas_material + AO ca in export).

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_shishimai.py -- OUT_DIR

Vederi: 3/4 din fata, lateral, de sus, si doua vederi de "sofer" cu parametrii camerei
de joc (10 m sus, 12,5 m in spate, fov 68; masina la 50 m si la 25 m de leu). Leul priveste
spre -Y Blender (= +Z Godot); soferul vine dinspre -Y. Sosea: banda gri de 14 m latime
(semilatime 7), cota z = 0.
"""
import sys
import math
import os

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_kyoto_shishimai.py")).read())

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."
os.makedirs(OUT, exist_ok=True)

mine = set(objs)
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

road = _slab("PreviewRoad", -7.0, 7.0, -200, 60, -0.01, (0.24, 0.23, 0.24))
vergeL = _slab("PreviewVergeL", -60, -7.0, -200, 60, -0.012, (0.30, 0.38, 0.22))
vergeR = _slab("PreviewVergeR", 7.0, 60, -200, 60, -0.012, (0.30, 0.38, 0.22))

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


def _look(eye, target, fov=50):
    # FOV VERTICAL (Godot: keep_height), ca in ChaseCamera
    cam.location = eye
    d = (Vector(target) - Vector(eye)).normalized()
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam.data.sensor_fit = "VERTICAL"
    cam.data.sensor_height = 36.0
    cam.data.sensor_width = 36.0
    cam.data.lens = 18.0 / math.tan(math.radians(fov) / 2.0)


def _render(name, res=(1280, 720)):
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("PREVIEW:", scene.render.filepath)


# 3/4 din fata-stanga, aproape
_look((-9.0, -11.0, 4.2), (0.0, 0.0, 2.2), fov=50)
_render("fata_34")
# frontal de aproape (capul)
_look((0.0, -11.0, 3.4), (0.0, 0.0, 2.9), fov=45)
_render("fata_cap")
# lateral
_look((18.0, -0.4, 2.4), (0.0, -0.4, 2.2), fov=45)
_render("lateral")
# de sus
_look((0.0, -0.4, 22.0), (0.0, -0.4, 0.0), fov=45)
cam.rotation_euler = (0.0, 0.0, 0.0)
_render("sus")
# soferul: masina la d m de leu
_look((-3.2, -2.5, 3.0), (-3.0, -0.4, 1.6), fov=60)
_render("lateral_aproape")
for d in (70, 45, 25):
    _look((0.0, -(d + 12.5), 10.0), (0.0, -d + 5.0, 1.2), fov=68)
    _render("sofer_%d" % d)
# lateral stanga (flancul -X)
_look((-18.0, -0.4, 2.4), (0.0, -0.4, 2.0), fov=40)
_render("lateral_stanga")


# ---------------------------------------------------------------------------
# Pozele din joc (aceleasi cifre ca `_apply_state` din shishimai_hazard.gd). Rotatiile in
# jurul lui X si Y(Godot)=Z(Blender) au acelasi semn in cele doua sisteme (transformarea
# e proprie); jos = + pe X. Falca devine copil al capului ca in joc.
def _pose(pitch, look, jaw_open, drop, hop, legs_scale, shift_x=0.0, body_yaw=0.0):
    names = {o.name: o for o in objs}
    head, jaw = names["Head"], names["Jaw"]
    for o in objs:
        o.rotation_mode = "YXZ"
        o.rotation_euler = (0.0, 0.0, 0.0)
        o.scale = (1.0, 1.0, 1.0)
    base = {o.name: o.location.copy() for o in objs}
    if jaw.parent is None:
        jaw.parent = head
        jaw.matrix_parent_inverse = head.matrix_world.inverted()
    for o in objs:
        dz = hop - drop if o.name.startswith(("Head", "Body")) else 0.0
        if o.name.startswith("Leg"):
            dz = hop - drop
            o.scale = (1.0, 1.0, legs_scale)
        if o.name != "Jaw":
            o.location = base[o.name] + Vector((shift_x, 0.0, dz))
        if o.name.startswith("Body"):
            o.rotation_euler = (0.0, 0.0, body_yaw)
    head.rotation_euler = (pitch, 0.0, look)
    jaw.rotation_euler = (jaw_open, 0.0, 0.0)
    bpy.context.view_layer.update()


_pose(-0.42, 0.62, 0.62, 0.28, 0.0, (0.95 - 0.28) / 0.95)
_look((0.0, -12.0, 4.2), (0.0, 0.0, 2.6), fov=50)
_render("poza_telegraf_fata")
_look((-9.0, -11.0, 4.2), (0.0, 0.0, 2.2), fov=50)
_render("poza_telegraf_34")
_look((0.0, -(25 + 12.5), 10.0), (0.0, -25 + 5.0, 1.2), fov=68)
_render("poza_telegraf_sofer25")
_pose(0.34, 0.30, 0.0, 0.0, 0.9 * 0.7, 1.0, shift_x=3.0)
_look((3.0, -12.0, 4.2), (3.0, 0.0, 2.6), fov=50)
_render("poza_atac_fata")
_pose(0.0, 0.0, 0.42, 0.0, 0.0, 1.0)
_look((0.0, -12.0, 4.2), (0.0, 0.0, 2.6), fov=50)
_render("poza_dans_fata")
