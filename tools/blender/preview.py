"""Randare de control pentru assets, din Blender (nu din joc).

De ce exista, cand exista deja tools/snapshot.gd: sonda din Godot cere ca
asset-ul sa fie deja instantiat pe o pista. Intre "a iesit din bmesh" si "e pe
pista" se pierd doua ore pe un model rotit gresit sau cu AO invers. Asta e
verificarea de doi pasi mai devreme.

Capcanele rezolvate aici (invatate pe pielea noastra, vezi si nota de memorie
despre Blender MCP):
  - `get_viewport_screenshot` randeaza view-ul de NAVIGATIE, nu camera scenei,
    si intoarce cadrul precedent. Nu e utilizabil pentru verificare.
  - `bpy.ops.render.opengl()` foloseste implicit `view_context=True`, deci are
    aceeasi problema.
  - becul POINT implicit din scena noua ("Light") arunca un blob de specular pe
    fete plate si face totul sa arate lucios; se stinge.
  - ambientul luat din cerul albastru implicit vopseste rece tot ce e deschis
    (exact ce reclama style_bible §5); aici e cald si slab, iar soarele are
    `specular_factor = 0` ca sa nu adauge luciu peste materialul de atlas.

Unghiul implicit e cel din §5: soare la 42° elevatie, 315° azimut.

    exec(open(P + "/preview.py").read(), g)
    shot(built, "d:/.../tetrapod.png", height=3.8)
"""

import bpy
import math
import os
from mathutils import Vector

PROJECT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

SUN_ELEV = 42.0
SUN_AZIM = 315.0


def _bounds(objects):
    # matrix_world e evaluat lene: fara update, un obiect mutat chiar inainte de
    # randare se incadreaza dupa pozitia VECHE si iese din cadru.
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objects:
        for corner in o.bound_box:
            p = o.matrix_world @ Vector(corner)
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    return lo, hi


def _light(scene):
    for o in list(bpy.data.objects):
        if o.type == "LIGHT" and o.name != "PreviewSun":
            o.hide_render = True
    sun = bpy.data.objects.get("PreviewSun")
    if sun is None:
        data = bpy.data.lights.new("PreviewSun", type="SUN")
        sun = bpy.data.objects.new("PreviewSun", data)
        scene.collection.objects.link(sun)
    sun.hide_render = False
    sun.data.energy = 3.2
    sun.data.color = (1.0, 0.87, 0.68)      # #FFD6A3 din style_bible §5
    sun.data.angle = math.radians(2.5)
    sun.data.specular_factor = 0.0
    e = math.radians(SUN_ELEV)
    a = math.radians(SUN_AZIM)
    sun.rotation_euler = (math.pi / 2 - e, 0.0, a + math.pi / 2)
    return sun


def _world(scene, warm=(0.42, 0.40, 0.36)):
    world = scene.world or bpy.data.worlds.new("PreviewWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (warm[0], warm[1], warm[2], 1.0)
        bg.inputs[1].default_value = 1.0


CLASSES_DIR = os.path.join(PROJECT, "assets", "textures", "classes")


def apply_class(obj, cls, triplanar=False, scale=1.0):
    """Pune pe obiect textura de clasa, ca sa se vada in preview CE VA FI in joc.

    Fara asta, o piesa cu UV cubic apare cu dungi de curcubeu: UV-urile ei nu
    mai nimeresc centrele sloturilor, deci baleiaza tot atlasul de paleta. Nu e
    un bug al modelului — in Godot `Palette.class_material` inlocuieste
    materialul — dar face previzualizarea inutilizabila exact pe piesele
    texturate, adica alea de dragul carora exista clasele.

    `triplanar=True` reproduce `Palette.triplanar_class_material`: proiectie BOX
    din coordonatele obiectului, cu `scale` interpretat la fel ca `uv1_scale`
    din Godot (o repetitie la 1/scale metri).
    """
    img_path = os.path.join(CLASSES_DIR, cls + ".png")
    if not os.path.exists(img_path):
        raise FileNotFoundError(img_path)
    name = "Preview_" + cls + ("_tri" if triplanar else "_uv")
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = nt.nodes.get("Principled BSDF")
        bsdf.inputs["Roughness"].default_value = 0.9
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.15
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(img_path, check_existing=True)
        if triplanar:
            tex.projection = "BOX"
            tex.projection_blend = 0.3
            coord = nt.nodes.new("ShaderNodeTexCoord")
            mapping = nt.nodes.new("ShaderNodeMapping")
            mapping.inputs["Scale"].default_value = (scale, scale, scale)
            nt.links.new(mapping.inputs["Vector"], coord.outputs["Object"])
            nt.links.new(tex.inputs["Vector"], mapping.outputs["Vector"])
        # AO copt: se inmulteste peste albedo, exact ca
        # `vertex_color_use_as_albedo` in Godot.
        vcol = nt.nodes.new("ShaderNodeVertexColor")
        vcol.layer_name = "AO"
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        nt.links.new(mix.inputs[6], tex.outputs["Color"])
        nt.links.new(mix.inputs[7], vcol.outputs["Color"])
        nt.links.new(bsdf.inputs["Base Color"], mix.outputs[2])
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def shot(objects, path, azimuth=35.0, elevation=14.0, margin=1.25,
         res=(960, 720), ground=True, driver=False):
    """Randeaza `objects` intr-un PNG. `driver=True` coboara camera la 1.2 m si
    ingusteaza FOV-ul la cel de joc — vederea din care se judeca de fapt un
    asset (vezi nota de memorie despre vederile de sus care mint)."""
    scene = bpy.context.scene
    # Podeaua de preview e scalata la de patru ori lotul. Daca ajunge in lista de
    # incadrat (usor de facut: "toate mesh-urile nevizibile-ascunse"), camera
    # incadreaza 240 m de nisip si assets-urile dispar intr-un cadru gri gol.
    objects = [o for o in objects if not o.name.startswith("Preview")]
    lo, hi = _bounds(objects)
    center = (lo + hi) * 0.5
    size = max((hi - lo).x, (hi - lo).y, (hi - lo).z)

    if ground:
        pad = bpy.data.objects.get("PreviewGround")
        if pad is None:
            me = bpy.data.meshes.new("PreviewGround")
            pad = bpy.data.objects.new("PreviewGround", me)
            scene.collection.objects.link(pad)
            import bmesh
            bm = bmesh.new()
            bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=1.0)
            bm.to_mesh(me)
            bm.free()
            mat = bpy.data.materials.new("PreviewGroundMat")
            mat.use_nodes = True
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            bsdf.inputs["Base Color"].default_value = (0.82, 0.70, 0.48, 1.0)
            bsdf.inputs["Roughness"].default_value = 1.0
            me.materials.append(mat)
        pad.hide_render = False
        pad.location = (center.x, center.y, lo.z - 0.005)
        pad.scale = (size * 4, size * 4, 1.0)

    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        scene.collection.objects.link(cam)
    scene.camera = cam

    if driver:
        cam.data.lens = 38.0                 # ~50° FOV, ca in joc
        elevation = math.degrees(math.atan2(1.2 - center.z, size * 2.2))
        dist = size * 2.2
    else:
        cam.data.lens = 55.0
        # Distanta se scoate din CAMPUL VIZUAL, nu din "cea mai mare latura x 2".
        # Formula veche folosea `size = max(extent)`, deci un rand lung de
        # assets (60 m lat, 9 m inalt) trimitea camera la 114 m si tot lotul
        # iesea o dunga de pixeli pe orizont — masurat, nu presupus.
        sensor = cam.data.sensor_width
        aspect = res[0] / float(res[1])
        hfov = 2.0 * math.atan(sensor / (2.0 * cam.data.lens))
        vfov = 2.0 * math.atan(math.tan(hfov / 2.0) / aspect)
        ext = hi - lo
        width = math.hypot(ext.x, ext.y)     # cazul cel mai prost la orice azimut
        dist = margin * max(width * 0.5 / math.tan(hfov / 2.0),
                            ext.z * 0.5 / math.tan(vfov / 2.0))

    a = math.radians(azimuth)
    e = math.radians(elevation)
    eye = center + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e),
                           math.sin(e))) * dist
    cam.location = eye
    look = (center - eye).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()

    _light(scene)
    _world(scene)
    scene.render.engine = "BLENDER_EEVEE_NEXT" if hasattr(
        bpy.types, "RenderEngineEeveeNext") or "BLENDER_EEVEE_NEXT" in [
        e.identifier for e in
        bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    ] else "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    return path
