"""Biblioteca de build pentru assets-urile "diorama" (Blender 4.x/5.x).

Contractul implementat aici e cel din docs/blender_export.md:
  1. UV-urile fiecarei fete colapsate pe CENTRUL unui slot din palette_atlas.png
  2. Vertex colors = AO copt (aici: raycast real in emisfera, nu doar gradient)
  3. Scara in metri, originea la baza obiectului, centrata in XY (Blender)
  4. Bevel consistent, aplicat in geometrie
  5. Export GLB cu UV + vertex colors

Rulare (din Blender, prin MCP):
    exec(open(r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py").read())

Nota de axe: exportatorul glTF converteste Blender Z-up -> glTF Y-up prin
(x, y, z) -> (x, z, -y). Deci **Blender +Y devine Godot -Z**. Brief-urile cer
"fata spre -Z" in spatiul Godot, adica geometria din fata se modeleaza spre
+Y in Blender.
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

# --- Paleta: indicii trebuie sa ramana identici cu scripts/palette.gd ---------
SLOTS = 32

SAND_LIGHT, SAND_MID, SAND_SHADOW = 0, 1, 2
ROCK_LIGHT, ROCK_DARK = 3, 4
ASPHALT, ASPHALT_EDGE, KERB_RED = 5, 6, 7
CONCRETE, WOOD, RUST, PAINTED = 8, 9, 10, 11
CACTUS_GREEN, DRY_VEGETATION = 12, 13

PROJECT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ATLAS = os.path.join(PROJECT, "assets", "textures", "palette_atlas.png")
MODELS = os.path.join(PROJECT, "assets", "models")
BLENDS = os.path.join(PROJECT, "assets", "blender")


def slot_u(slot):
    """Coordonata u care nimereste centrul slotului (v e mereu 0.5)."""
    return (slot + 0.5) / SLOTS


# --- Constructie de geometrie -------------------------------------------------

class Builder:
    """Aduna toate piesele intr-un singur bmesh, marcand fiecare fata cu slotul
    ei de paleta. Slotul se pastreaza intr-un layer int si se transforma in UV
    abia dupa bevel (vezi assign_uvs)."""

    def __init__(self):
        self.bm = bmesh.new()
        self.slot = self.bm.faces.layers.int.new("slot")

    def _tag(self, verts, slot):
        faces = set()
        for v in verts:
            faces.update(v.link_faces)
        for f in faces:
            f[self.slot] = slot
        return faces

    def box(self, center, size, slot, rotation=None):
        """Cutie aliniata pe axe (sau rotita), definita prin centru + dimensiuni."""
        mat = Matrix.Translation(Vector(center))
        if rotation is not None:
            rot = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            mat = mat @ rot.to_4x4()
        mat = mat @ Matrix.Diagonal(Vector(size).to_4d())
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat)
        return self._tag(res["verts"], slot)

    def beam(self, p1, p2, thickness, slot, up=None):
        """Grinda dreptunghiulara intre doua puncte. Baza pentru schele/turnuri."""
        p1, p2 = Vector(p1), Vector(p2)
        d = p2 - p1
        length = d.length
        if length < 1e-6:
            return set()
        z = d.normalized()
        ref = Vector(up) if up else (Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0)))
        x = ref.cross(z)
        if x.length < 1e-6:
            x = Vector((1, 0, 0)).cross(z)
        x.normalize()
        y = z.cross(x)
        rot = Matrix((x, y, z)).transposed().to_4x4()
        t = thickness if isinstance(thickness, (tuple, list)) else (thickness, thickness)
        mat = Matrix.Translation((p1 + p2) * 0.5) @ rot @ Matrix.Diagonal(Vector((t[0], t[1], length, 1.0)))
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat)
        return self._tag(res["verts"], slot)

    def cylinder(self, center, radius, depth, slot, segments=8, axis="Z"):
        """Cilindru cu capace (ngon)."""
        rot = {
            "Z": Matrix.Identity(4),
            "X": Matrix.Rotation(math.radians(90), 4, "Y"),
            "Y": Matrix.Rotation(math.radians(-90), 4, "X"),
        }[axis]
        mat = Matrix.Translation(Vector(center)) @ rot
        try:
            res = bmesh.ops.create_cone(
                self.bm, cap_ends=True, cap_tris=False, segments=segments,
                radius1=radius, radius2=radius, depth=depth, matrix=mat)
        except TypeError:  # Blender < 3.0 folosea diameter1/diameter2
            res = bmesh.ops.create_cone(
                self.bm, cap_ends=True, cap_tris=False, segments=segments,
                diameter1=radius, diameter2=radius, depth=depth, matrix=mat)
        return self._tag(res["verts"], slot)

    def revolve(self, profile, slot, segments=8, origin=(0, 0, 0), cap_bottom=True):
        """Suprafata de revolutie in jurul axei Z locale.

        profile: lista de (raza, z) de jos in sus. O raza 0 la varf produce un apex
        (varf rotunjit/dom, in functie de cum e desenat profilul)."""
        ox, oy, oz = origin
        rings = []
        apex = None
        for r, z in profile:
            if r <= 1e-6:
                apex = self.bm.verts.new((ox, oy, oz + z))
                break
            ring = []
            for i in range(segments):
                a = 2.0 * math.pi * i / segments
                ring.append(self.bm.verts.new((ox + r * math.cos(a), oy + r * math.sin(a), oz + z)))
            rings.append(ring)

        new_verts = [v for ring in rings for v in ring] + ([apex] if apex else [])
        for lo, hi in zip(rings, rings[1:]):
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        if apex and rings:
            top = rings[-1]
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((top[i], top[j], apex))
        if cap_bottom and rings:
            self.bm.faces.new(tuple(reversed(rings[0])))
        return self._tag(new_verts, slot)

    def sweep(self, path, radius, slot, segments=6, dome_end=True, cap_start=True,
              dome_rings=2):
        """Tub poligonal de-a lungul unei polilinii; optional dom la capat.
        Folosit pentru bratele de cactus (cotul clasic de saguaro)."""
        pts = [Vector(p) for p in path]
        if len(pts) < 2:
            return set()

        tangents = []
        for i, p in enumerate(pts):
            if i == 0:
                t = (pts[1] - pts[0])
            elif i == len(pts) - 1:
                t = (pts[-1] - pts[-2])
            else:
                t = (pts[i + 1] - pts[i - 1])
            tangents.append(t.normalized())

        # transport paralel ca sa nu se rasuceasca inelele
        ref = Vector((0, 1, 0)) if abs(tangents[0].y) < 0.9 else Vector((1, 0, 0))
        x_axis = ref.cross(tangents[0]).normalized()
        rings, new_verts = [], []
        for i, (p, t) in enumerate(zip(pts, tangents)):
            if i > 0:
                x_axis = (x_axis - t * x_axis.dot(t))
                if x_axis.length < 1e-6:
                    x_axis = (Vector((0, 0, 1)).cross(t))
                x_axis.normalize()
            y_axis = t.cross(x_axis)
            ring = []
            for k in range(segments):
                a = 2.0 * math.pi * k / segments
                ring.append(self.bm.verts.new(p + x_axis * (radius * math.cos(a)) + y_axis * (radius * math.sin(a))))
            rings.append(ring)
            new_verts.extend(ring)

        for lo, hi in zip(rings, rings[1:]):
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))

        if cap_start:
            self.bm.faces.new(tuple(reversed(rings[0])))

        if dome_end:
            t = tangents[-1]
            x_axis_d = x_axis
            y_axis_d = t.cross(x_axis_d)
            prev = rings[-1]
            base = pts[-1]
            angles = {1: (55.0,), 2: (40.0, 70.0), 3: (30.0, 55.0, 75.0)}[dome_rings]
            for ang in angles:
                rad = math.radians(ang)
                r = radius * math.cos(rad)
                c = base + t * (radius * math.sin(rad))
                ring = []
                for k in range(segments):
                    a = 2.0 * math.pi * k / segments
                    ring.append(self.bm.verts.new(c + x_axis_d * (r * math.cos(a)) + y_axis_d * (r * math.sin(a))))
                new_verts.extend(ring)
                for i in range(segments):
                    j = (i + 1) % segments
                    self.bm.faces.new((prev[i], prev[j], ring[j], ring[i]))
                prev = ring
            tip = self.bm.verts.new(base + t * radius)
            new_verts.append(tip)
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((prev[i], prev[j], tip))
        else:
            self.bm.faces.new(tuple(rings[-1]))

        return self._tag(new_verts, slot)

    def prism(self, outline, thickness, slot, center=(0, 0, 0)):
        """Prisma dintr-un contur 2D in planul XZ, extrudata pe Y.

        Fata "din fata" (spre +Y in Blender) devine -Z in Godot — vezi nota de
        axe din capul fisierului. Folosita pentru placi: scut de semn, panouri."""
        cx, cy, cz = center
        half = thickness * 0.5
        front, back = [], []
        for x, z in outline:
            back.append(self.bm.verts.new((cx + x, cy - half, cz + z)))
            front.append(self.bm.verts.new((cx + x, cy + half, cz + z)))
        n = len(outline)
        self.bm.faces.new(tuple(front))
        self.bm.faces.new(tuple(reversed(back)))
        for i in range(n):
            j = (i + 1) % n
            self.bm.faces.new((back[i], back[j], front[j], front[i]))
        return self._tag(front + back, slot)

    def to_object(self, name):
        """Scrie bmesh-ul intr-un obiect nou, pastrand slotul ca atribut de fata."""
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        obj = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(obj)
        return obj


# --- Post-procesare: bevel, UV, AO, origine ----------------------------------

def snapshot_slots(obj):
    """Retine geometria + slotul fiecarei fete INAINTE de bevel, ca sa putem
    reatribui UV-urile dupa. Fetele nou create de bevel iau slotul celei mai
    apropiate fete originale -> banda de bevel primeste una din culorile vecine,
    curat, fara interpolare intre sloturi (care ar amesteca culori din atlas)."""
    me = obj.data
    me.calc_loop_triangles()  # BVHTree nu accepta ngon-uri (capace de cilindru/revolutie)
    attr = me.attributes.get("slot")
    verts = [v.co.copy() for v in me.vertices]
    tris, slots = [], []
    for lt in me.loop_triangles:
        tris.append(tuple(lt.vertices))
        slots.append(int(attr.data[lt.polygon_index].value) if attr else 0)
    return {"bvh": BVHTree.FromPolygons(verts, tris, all_triangles=True), "slots": slots}


def apply_bevel(obj, width, segments=1, angle_deg=30.0):
    if width <= 0:
        return
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(angle_deg)
    # numele s-a schimbat intre versiuni (clamp_overlap -> use_clamp_overlap in 5.x)
    for attr in ("use_clamp_overlap", "clamp_overlap"):
        if hasattr(mod, attr):
            setattr(mod, attr, True)
            break
    mod.miter_outer = "MITER_ARC"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def assign_uvs(obj, snap):
    """Colapseaza UV-urile fiecarei fete pe centrul slotului ei."""
    me = obj.data
    uv = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
    bvh, slots = snap["bvh"], snap["slots"]
    for poly in me.polygons:
        loc, nor, idx, dist = bvh.find_nearest(poly.center)
        slot = slots[idx] if idx is not None and idx < len(slots) else 0
        u = slot_u(slot)
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)


def _hemisphere_dirs(n):
    """Directii distribuite uniform in emisfera (spirala Fibonacci) — determinist,
    deci build-uri reproductibile."""
    ga = math.pi * (3.0 - math.sqrt(5.0))
    out = []
    for i in range(n):
        z = (i + 0.5) / n
        r = math.sqrt(max(0.0, 1.0 - z * z))
        a = ga * i
        out.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    return out


def bake_ao(obj, samples=32, dist=2.5, gradient="vertical",
            low=0.55, high=1.0, power=1.0, floor=0.30, strength=1.0,
            radial_axis="Z"):
    """AO real prin raycast in emisfera + gradient, scris in vertex colors.

    gradient='vertical' -> jos mai inchis (cladiri, turnuri, cactusi)
    gradient='radial'   -> centru mai inchis (roata morii: trebuie sa arate bine
                           in ORICE rotatie, deci fara gradient directional)
    gradient='none'     -> doar ocluzia geometrica
    """
    me = obj.data
    me.calc_loop_triangles()
    bvh = BVHTree.FromPolygons([v.co.copy() for v in me.vertices],
                               [tuple(lt.vertices) for lt in me.loop_triangles],
                               all_triangles=True)
    dirs = _hemisphere_dirs(samples)

    zs = [v.co.z for v in me.vertices]
    z_lo, z_hi = min(zs), max(zs)
    span = max(z_hi - z_lo, 1e-6)
    # roata morii e construita in planul XZ, deci raza ei se masoara fata de axa Y
    if radial_axis == "Y":
        radii = [math.hypot(v.co.x, v.co.z) for v in me.vertices]
    else:
        radii = [math.hypot(v.co.x, v.co.y) for v in me.vertices]
    r_max = max(max(radii), 1e-6)

    values = []
    for i, v in enumerate(me.vertices):
        n = v.normal.normalized()
        ref = Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))
        tx = ref.cross(n).normalized()
        ty = n.cross(tx)
        basis = Matrix((tx, ty, n)).transposed()
        origin = v.co + n * 0.003

        occ = 0.0
        for d in dirs:
            hit = bvh.ray_cast(origin, basis @ d, dist)
            if hit[0] is not None:
                occ += 1.0 - min(hit[3] / dist, 1.0)  # atenuare cu distanta
        ao = 1.0 - (occ / len(dirs)) * strength

        if gradient == "vertical":
            t = (v.co.z - z_lo) / span
            g = low + (high - low) * (t ** power)
        elif gradient == "radial":
            t = radii[i] / r_max
            g = low + (high - low) * (t ** power)
        else:
            g = 1.0

        values.append(max(floor, min(1.0, ao * g)))

    for ca in list(me.color_attributes):
        me.color_attributes.remove(ca)
    ca = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="POINT")
    for i, val in enumerate(values):
        ca.data[i].color = (val, val, val, 1.0)
    me.color_attributes.active_color_index = 0
    me.color_attributes.render_color_index = 0
    return min(values), max(values)


def set_origin_base(obj, center_xy=True, to_z=0.0):
    """Muta geometria astfel incat originea sa fie la baza, centrata in XY.
    Godot: global_position aseaza propul direct pe sol."""
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    dx = -(min(xs) + max(xs)) * 0.5 if center_xy else 0.0
    dy = -(min(ys) + max(ys)) * 0.5 if center_xy else 0.0
    dz = to_z - min(zs)
    for v in me.vertices:
        v.co.x += dx
        v.co.y += dy
        v.co.z += dz
    return Vector((dx, dy, dz))


def set_origin_at(obj, point):
    """Muta geometria ca originea obiectului sa cada exact in `point`
    (folosit pentru pivotul rotii morii, in centrul butucului)."""
    p = Vector(point)
    for v in obj.data.vertices:
        v.co -= p
    obj.location = obj.location + p
    return p


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# --- Material de preview + export --------------------------------------------

def atlas_material():
    """Material unic de preview care arata spre acelasi atlas ca in joc.
    In Godot materialul e inlocuit oricum de Palette.apply_world_material();
    aici exista ca sa garanteze exportul UV-urilor si ca sa putem verifica
    vizual culorile in viewport."""
    mat = bpy.data.materials.get("PaletteAtlas")
    if mat:
        return mat
    mat = bpy.data.materials.new("PaletteAtlas")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.9
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.1

    img = bpy.data.images.get("palette_atlas.png")
    if img is None and os.path.exists(ATLAS):
        img = bpy.data.images.load(ATLAS)
    if img:
        img.colorspace_settings.name = "sRGB"
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Closest"  # fara amestec intre sloturi vecine
        tex.location = (-600, 200)
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "AO"
    col.location = (-600, -150)
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.location = (-300, 100)
    if img:
        nt.links.new(tex.outputs["Color"], mix.inputs[6])
    nt.links.new(col.outputs["Color"], mix.inputs[7])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    return mat


def finish(obj, bevel=0.04, bevel_angle=30.0, ao=None, origin="base"):
    """Lantul standard: bevel -> UV pe sloturi -> origine -> AO copt.

    origin="base"      centreaza si XY pe bounding box
    origin="base_axis" coboara doar pe Z, pastrand XY asa cum a fost construit
                       (cand piesa e asimetrica: un semn al carui scut iese in
                       fata, dar a carui origine trebuie sa stea pe axa stalpului)
    Ordinea conteaza: originea se muta INAINTE de bake, ca gradientul vertical
    de AO sa se calculeze de la baza reala (z=0).
    """
    snap = snapshot_slots(obj)
    apply_bevel(obj, bevel, angle_deg=bevel_angle)
    assign_uvs(obj, snap)
    if origin == "base":
        set_origin_base(obj, center_xy=True)
    elif origin == "base_axis":
        set_origin_base(obj, center_xy=False)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    rng = bake_ao(obj, **(ao or {}))
    if "slot" in obj.data.attributes:  # atributul de lucru nu are ce cauta in GLB
        obj.data.attributes.remove(obj.data.attributes["slot"])
    return {"tris": tri_count(obj), "ao_min": round(rng[0], 3), "ao_max": round(rng[1], 3)}


def export_glb(objects, filename):
    """Export GLB cu UV + vertex colors, Y-up, modificatori aplicati."""
    os.makedirs(MODELS, exist_ok=True)
    path = os.path.join(MODELS, filename)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_texcoords=True,
        export_vertex_color="ACTIVE",
        export_materials="EXPORT",
        # Materialul se pastreaza (altfel exportatorul arunca UV-urile), dar imaginea
        # NU se incorporeaza: Godot ar extrage-o intr-un PNG separat langa fiecare GLB
        # si am ajunge cu 4 copii ale aceluiasi atlas in build. Culoarea vine oricum
        # din Palette.apply_world_material, la instantiere.
        export_image_format="NONE",
        export_cameras=False,
        export_lights=False,
        export_extras=False,
    )
    return path, os.path.getsize(path)


def save_blend(objects, filename):
    """Scrie sursa .blend FARA sa schimbe fisierul deschis in sesiunea curenta."""
    os.makedirs(BLENDS, exist_ok=True)
    path = os.path.join(BLENDS, filename)
    bpy.data.libraries.write(path, set(objects), fake_user=True)
    return path, os.path.getsize(path)


def clear_built(prefix=None):
    """Sterge obiectele construite de scripturi (nu atinge restul scenei).

    Sterge si mesh-urile ramase orfane: altfel numele se acumuleaza intre rulari
    (Cactus_A -> Cactus_A.001 -> ...), iar nodurile din GLB trebuie sa aiba nume
    stabile (Godot cauta nodul "Blades" al morii dupa nume)."""
    for o in list(bpy.data.objects):
        if o.type == "MESH" and (prefix is None or o.name.startswith(prefix)):
            bpy.data.objects.remove(o, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0 and (prefix is None or me.name.startswith(prefix)):
            bpy.data.meshes.remove(me)


print("dio_lib incarcat | atlas:", os.path.exists(ATLAS), "| models:", MODELS)
