"""Randari de control pentru templul prin care se trece (`angkor_wat_drive.glb`).

    (lacat GPU)  until mkdir D:/GameDev/.render_lock 2>/dev/null; do sleep 5; done
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor_drive.py -- --out <dir> [--only a,b]
    rmdir D:/GameDev/.render_lock

Cadre (toate din GLB-ul EXPORTAT, culoare reala: fiecare fata pe slotul ei din atlas, gresia pe
tinta clasei `angkor_sandstone` #AD9877, AO din culorile de varf):
  ext_sw          3/4 din sud-vest
  west_240 / west_100        camera de joc pe calea de vest (10 m peste sosea, 12,5 m in spatele
                             masinii, priveste la 0,4 m, 5 m inainte; fov vertical 68)
  west_240_zoom / west_100_zoom   aceeasi pozitie, teleobiectiv pe fatada
  chase_m<m>      camera de urmarire in tub: 5,5 m peste sosea, 12,5 m in urma punctului de pe axa,
                  priveste la 1,4 m, 6 m inainte, fov 68; m = -25, 2, 22, 45, 68, 95
  sanctuary_view  din mijlocul salii (m 43, 3 m), spre gongul din origine; `_beam`: aceeasi cu o
                  lumina-spot pe axa turnului care SIMULEAZA raza aditiva din joc (modelul n-are lumini)
  cutaway_z8      sectiune de sus la z = 8 cu conturul de coliziune (rosu) si axa (galben)
Soarele: dupa-amiaza tarziu, jos (16 grade) din VSV, cald; cer violet ca in randarile de referinta.
Masina-jucarie (cutie 2 x 4 x 1,5, rosie) la punctul privit, pentru scara.
"""

import bpy
import bmesh
import json
import math
import os
import re
import sys
from mathutils import Vector

HERE_P = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(os.path.dirname(HERE_P))
GLB = os.path.join(PROJ, "assets", "models", "angkor", "structures", "angkor_wat_drive.glb")
SHELL = json.load(open(os.path.join(PROJ, "tools", "data", "angkor_temple_shell.json")))

PALETTE_HEX = [
    "E8C074", "D4994D", "915D27", "C18446", "67421F", "4B4B4D", "696765",
    "BB3522", "C8BDA9", "835C34", "91461E", "7692A8", "5B7C34", "AF9F4E",
    "E54839", "2C82E8", "F2D03C",
    "54BFB8", "2E5F6B", "E9DCC0", "55535A", "3F7A3C", "E9F2F0", "C4784F",
    "7FC4C9", "2F6E82", "1A2A33", "A8683A", "4A3526", "B8B4AC",
    "E8622D", "D2A0BE",
]
STONE_HEX = "#AD9877"
SUN_BEARING, SUN_ELEV = 247.5, 16.0

args = sys.argv[1:]
OUT = None
ONLY = None
for i, a in enumerate(args):
    if a == "--out":
        OUT = args[i + 1]
    if a == "--only":
        ONLY = set(args[i + 1].split(","))
if OUT is None:
    raise SystemExit("--out <dir>")
os.makedirs(OUT, exist_ok=True)


def lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def flat(hex_color, use_ao=True, emit=0.0):
    name = "DFlat_%s_%d" % (hex_color.lstrip("#"), int(use_ao))
    m = bpy.data.materials.get(name)
    if m:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    col = lin(hex_color) + (1.0,)
    if use_ao:
        vc = nt.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "AO"
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        mix.inputs[6].default_value = col
        nt.links.new(mix.inputs[7], vc.outputs["Color"])
        nt.links.new(bsdf.inputs["Base Color"], mix.outputs[2])
    else:
        bsdf.inputs["Base Color"].default_value = col
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = emit
    return m


def import_temple():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=GLB)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in meshes:
        attrs = o.data.attributes
        if "AO" not in attrs and "Color" in attrs:
            attrs["Color"].name = "AO"
        base = re.sub(r"\.\d{3}$", "", o.name)
        me = o.data
        me.materials.clear()
        if base.endswith("_Stone"):
            me.materials.append(flat(STONE_HEX))
            continue
        uv = me.uv_layers.active
        idx = {}
        for poly in me.polygons:
            u = uv.data[poly.loop_indices[0]].uv[0]
            slot = max(0, min(31, int(math.floor(u * 32))))
            if slot not in idx:
                idx[slot] = len(me.materials)
                me.materials.append(flat("#" + PALETTE_HEX[slot]))
            poly.material_index = idx[slot]
    return meshes


def add_mesh(name, verts, faces, mat):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(mat)
    return ob


def road_points():
    pts = [(Vector(r["p"]), Vector((r["side"][0], r["side"][1], 0.0)), r["hw"], r["m"]) for r in SHELL["road"]]
    # prelungire spre linia de start (calea de vest e dreapta pe y = 0)
    p0 = pts[0]
    ext = []
    x = -260.0
    while x < p0[0].x - 1.0:
        ext.append((Vector((x, 0.0, 3.67)), Vector((0.0, -1.0, 0.0)), 4.5, p0[3] - (p0[0].x - x)))
        x += 10.0
    return ext + pts


ROAD = road_points()


def road_at(m):
    for a, b in zip(ROAD, ROAD[1:]):
        if a[3] <= m <= b[3]:
            t = (m - a[3]) / (b[3] - a[3])
            p = a[0].lerp(b[0], t)
            d = (b[0] - a[0])
            d.z = 0
            return p, d.normalized()
    a, b = ROAD[-2], ROAD[-1]
    d = (b[0] - a[0])
    d.z = 0
    return b[0] + d.normalized() * (m - b[3]), d.normalized()


def scenery():
    # gazon
    add_mesh("Ground", [(-700, -700, 3.65), (700, -700, 3.65), (700, 700, 3.65), (-700, 700, 3.65)],
             [(0, 1, 2, 3)], flat("#6F7347", use_ao=False))
    # soseaua
    vs, fs = [], []
    for i, (p, s, hw, m) in enumerate(ROAD):
        vs += [tuple(p - s * hw + Vector((0, 0, 0.015))), tuple(p + s * hw + Vector((0, 0, 0.015)))]
        if i:
            fs.append((2 * i - 2, 2 * i - 1, 2 * i + 1, 2 * i))
    add_mesh("Road", vs, fs, flat("#8A7058", use_ao=False))


def car_at(m):
    p, d = road_at(m)
    ob = add_mesh("Car", [(-1, -2, 0), (1, -2, 0), (1, 2, 0), (-1, 2, 0), (-1, -2, 1.5), (1, -2, 1.5), (1, 2, 1.5), (-1, 2, 1.5)],
                  [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)],
                  flat("#D8342A", use_ao=False))
    ob.location = p + Vector((0, 0, 0.02))
    ob.rotation_euler = (0, 0, math.atan2(d.y, d.x) - math.pi / 2)
    return ob


def lights(top=False):
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)
    b, e = math.radians(SUN_BEARING), math.radians(SUN_ELEV if not top else 55.0)
    to_sun = Vector((math.sin(b) * math.cos(e), math.cos(b) * math.cos(e), math.sin(e)))
    data = bpy.data.lights.new("Sun", type="SUN")
    data.energy = 4.2
    data.color = lin("FFC48A")
    data.angle = math.radians(0.8)
    ob = bpy.data.objects.new("Sun", data)
    bpy.context.scene.collection.objects.link(ob)
    ob.rotation_euler = (-to_sun).to_track_quat("-Z", "Y").to_euler()
    sc = bpy.context.scene
    w = sc.world or bpy.data.worlds.new("W")
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = lin("9C8296") + (1.0,)
    bg.inputs[1].default_value = 0.40


def setup(res):
    sc = bpy.context.scene
    ids = [x.identifier for x in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in ids else "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = False
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGB"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    ee = sc.eevee
    for attr, val in (("taa_render_samples", 48), ("use_shadows", True), ("use_raytracing", True),
                      ("shadow_ray_count", 2), ("shadow_step_count", 8)):
        if hasattr(ee, attr):
            try:
                setattr(ee, attr, val)
            except Exception:
                pass


def camera(loc, target, fov_v=68.0, lens=None, ortho=None, clip=(0.2, 2000.0)):
    sc = bpy.context.scene
    cam = bpy.data.objects.get("Cam")
    if cam is None:
        cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
        sc.collection.objects.link(cam)
    sc.camera = cam
    cd = cam.data
    cd.clip_start, cd.clip_end = clip
    if ortho:
        cd.type = "ORTHO"
        cd.ortho_scale = ortho
    else:
        cd.type = "PERSP"
        if lens:
            cd.lens = lens
            cd.sensor_fit = "AUTO"
        else:
            cd.sensor_fit = "VERTICAL"
            cd.angle = math.radians(fov_v)
    cam.location = Vector(loc)
    cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()


def render(name):
    if ONLY and name not in ONLY:
        return
    p = os.path.join(OUT, name + ".png")
    bpy.context.scene.render.filepath = p
    bpy.ops.render.render(write_still=True)
    print("randat:", p)


def tube_walls():
    """Peretii de coliziune (ca in garda): sectiunile tubului."""
    road, tube = SHELL["road"], SHELL["tube"]
    i0 = [k for k, r in enumerate(road) if abs(r["m"]) < 1e-6][0]
    acc, j = 0.0, i0
    while acc < tube["length"]:
        acc += (Vector(road[j + 1]["p"]) - Vector(road[j]["p"])).length
        j += 1
    iw = j
    P = [Vector(r["p"]) for r in road]
    S = [Vector((r["side"][0], r["side"][1], 0.0)) for r in road]
    te = (P[i0 + 1] - P[i0]).normalized()
    tw = (P[iw] - P[iw - 1]).normalized()
    c, s, w = [P[i0] - te * 0.3], [S[i0]], [road[i0]["hw"]]
    for k in range(i0, iw):
        c.append((P[k] + P[k + 1]) * 0.5)
        s.append(S[k])
        w.append((road[k]["hw"] + road[k + 1]["hw"]) * 0.5)
    c.append(P[iw] + tw * 0.3)
    s.append(S[iw - 1])
    w.append(road[iw]["hw"])
    w = [max(6.0, x) for x in w]
    return c, s, w


def outline(z):
    c, s, w = tube_walls()
    red = flat("#FF2020", use_ao=False, emit=2.0)
    yel = flat("#FFE020", use_ao=False, emit=2.0)
    for sg in (-1, 1):
        vs, fs = [], []
        for i, (cc, ss, ww) in enumerate(zip(c, s, w)):
            a = cc + ss * (sg * ww)
            n = ss * sg
            vs += [(a.x, a.y, z), (a.x + n.x * 0.3, a.y + n.y * 0.3, z)]
            if i:
                fs.append((2 * i - 2, 2 * i - 1, 2 * i + 1, 2 * i))
        add_mesh("Wall%d" % sg, vs, fs, red)
    vs, fs = [], []
    for i, (p, sd, hw, m) in enumerate(ROAD):
        vs += [(p.x - sd.x * 0.12, p.y - sd.y * 0.12, z), (p.x + sd.x * 0.12, p.y + sd.y * 0.12, z)]
        if i:
            fs.append((2 * i - 2, 2 * i - 1, 2 * i + 1, 2 * i))
    add_mesh("Axis", vs, fs, yel)
    # ramele si aripile (triunghiurile `portal`, proiectate)
    pts = SHELL["portal"]
    vs = [(p[0], p[1], z + 0.01) for p in pts]
    fs = [(i, i + 1, i + 2) for i in range(0, len(vs), 3)]
    add_mesh("PortalFlat", vs, fs, red)


def section_lines(z, zdraw):
    """Linia de sectiune a modelului la cota z (bisect), desenata alb la zdraw."""
    white = flat("#FFFFFF", use_ao=False, emit=3.0)
    vs, fs = [], []
    for o in [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("TempleDrive")]:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bm.transform(o.matrix_world)
        res = bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
                                     plane_co=(0, 0, z), plane_no=(0, 0, 1))
        for e in res["geom_cut"]:
            if not isinstance(e, bmesh.types.BMEdge):
                continue
            a_, b_ = e.verts[0].co, e.verts[1].co
            d = (b_ - a_)
            d.z = 0
            if d.length < 1e-4:
                continue
            nrm = Vector((-d.y, d.x, 0)).normalized() * 0.06
            i = len(vs)
            vs += [(a_.x - nrm.x, a_.y - nrm.y, zdraw), (a_.x + nrm.x, a_.y + nrm.y, zdraw),
                   (b_.x + nrm.x, b_.y + nrm.y, zdraw), (b_.x - nrm.x, b_.y - nrm.y, zdraw)]
            fs.append((i, i + 1, i + 2, i + 3))
        bm.free()
    add_mesh("Section", vs, fs, white)


def main():
    import_temple()
    scenery()
    lights()
    # exterior
    setup((1600, 1000))
    a = math.radians(225.0)
    e = math.radians(22.0)
    tgt = Vector((0, 0, 15.0))
    camera(tgt + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e), math.sin(e))) * 190.0, tgt, lens=50)
    render("ext_sw")
    setup((1920, 1080))
    for dist in (240, 100):
        car = Vector((-dist + 12.5, 0.0, 3.67))
        cam = Vector((-dist, 0.0, 3.67 + 10.0))
        camera(cam, car + Vector((5.0, 0.0, 0.4)), fov_v=68.0)
        c_ob = car_at(-1e9)
        c_ob.location = car
        c_ob.rotation_euler = (0, 0, -math.pi / 2)
        render("west_%d" % dist)
        camera(cam, Vector((0.0, 0.0, 16.0)), lens=135 if dist == 240 else 55)
        render("west_%d_zoom" % dist)
        bpy.data.objects.remove(c_ob, do_unlink=True)
    # interior
    for m in (-25, 2, 22, 45, 68, 95):
        pc, dc = road_at(m - 12.5)
        pl, dl = road_at(m + 6.0)
        camera(pc + Vector((0, 0, 5.5)), pl + Vector((0, 0, 1.4)), fov_v=68.0, clip=(0.1, 900.0))
        car = car_at(m + 6.0)
        render("chase_m%d" % m)
        bpy.data.objects.remove(car, do_unlink=True)
    # din sala, prin arcada, spre gong (camera la 3 m, pe axa, la m 41)
    pc, dc = road_at(43.0)
    camera(pc + Vector((0, 0, 3.0)), Vector((0.0, 0.0, 6.0)), fov_v=60.0, clip=(0.1, 900.0))
    render("sanctuary_view")
    # aceeasi, cu o lumina-spot pe axa putului care SIMULEAZA raza din joc (LightShaft-ul
    # coordonatorului; in model nu exista lumini) -- doar ca sa se vada gongul si discul
    sd = bpy.data.lights.new("ShaftBeam", type="SPOT")
    sd.energy = 60000.0
    sd.color = lin("FFE9C8")
    sd.spot_size = math.radians(28.0)
    sd.spot_blend = 0.5
    sb = bpy.data.objects.new("ShaftBeam", sd)
    bpy.context.scene.collection.objects.link(sb)
    sb.location = (0.0, 0.0, 29.0)
    sb.rotation_euler = (0.0, 0.0, 0.0)
    render("sanctuary_view_beam")
    bpy.data.objects.remove(sb, do_unlink=True)
    # sectiunea de sus
    lights(top=True)
    outline(7.9)
    section_lines(8.0, 7.97)
    setup((1600, 1700))
    camera((-10.0, 6.0, 8.0), (-10.0, 6.0, 0.0), ortho=150.0, clip=(0.001, 20.0))
    render("cutaway_z8")


main()
