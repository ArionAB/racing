"""Elevatia de FATA a unei case de rand (kitul San Francisco): ce se vede din strada, pe
clase — pastel (nodul `Row_Wall`) / alb (slot 22) / sticla (slot 20 vertical) / acoperis
(slot 20 inclinat) / altele (piatra 8, garaj 9, nisa 28). DOAR CITESTE GLB-ul.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/measure_sf_row_facade.py -- <glb> [<glb> ...] [--z0=3.2] [--step=0.02]
        [--png=<folder>]   (scrie si harta claselor, <folder>/<glb>_fatada.png, -2,4 -> 12,7)
        [--x0=-3.5 --x1=3.5]   (latimea rasterului pe fatada; coltul: --x0=-5.5 --x1=4.5)
        [--face=-x|+x]     (a doua fatada a coltului: raze dinspre -X / +X, `x0..x1` = Godot -Z..
                            spre spate, adica Blender Y de la +x1 la -x0; implicit fata -Z)
        [--top=12.7]       (sus-ul zonei `etaje+fronton`; coltul: 15,0)

Cum se calculeaza: raster ORTOGRAFIC de vizibilitate, din fata (Godot -Z, Blender +Y),
cu pasul `--step` (implicit 2 cm) pe X in [-3,5, +3,5] si pe inaltime in [`--z0`, 12,7];
pentru fiecare pixel o raza orizontala spre spatele casei, contra unui BVH cu AMBELE noduri
(deci ce e acoperit de o rama, de bovindou sau de cornisa nu se numara ca perete), iar
fata lovita se clasifica dupa nod si slotul din UV (u * 32). Pixelii fara lovitura (cerul
de langa fronton) nu intra in suma. Procentele se dau pe pixelii lovitii fara acoperis
(muchia placii de ardezie, ~1 %), cum s-a raportat v1; cifrele cu acoperis sunt alaturi.

Zonele: `etaje+fronton` (z0 = 3,2: de la brau in sus, contractul pilotului), plus
`parter` (0 -> 3,2) si `fronton` (9,6 -> 12,7) separat, pentru diagnostic.
"""
import math
import os
import sys

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

S_WHITE, S_DARK = 22, 20


def _args():
    argv = sys.argv
    a = argv[argv.index("--") + 1:] if "--" in argv else []
    paths, opts = [], {"z0": 3.2, "step": 0.02, "x0": -3.5, "x1": 3.5, "top": 12.7}
    for x in a:
        if x.startswith("--png="):
            opts["png_dir"] = x[6:]
        elif x.startswith("--face="):
            opts["face"] = x[7:]
        elif x.startswith("--") and "=" in x:
            k, v = x[2:].split("=", 1)
            opts[k] = float(v)
        elif x != "--":
            paths.append(x)
    return paths, opts


def _load(path):
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=path)
    verts, tris, info = [], [], []
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        me = o.data
        me.calc_loop_triangles()
        uv = me.uv_layers.active
        mw = o.matrix_world
        nm = mw.to_3x3().inverted().transposed()
        base = len(verts)
        verts.extend(mw @ v.co for v in me.vertices)
        is_wall = o.name.split(".")[0] == "Row_Wall"
        for lt in me.loop_triangles:
            tris.append(tuple(base + i for i in lt.vertices))
            slot = int(math.floor(uv.data[lt.loops[0]].uv[0] * 32)) if uv else -1
            n = (nm @ lt.normal).normalized()
            if is_wall:
                cls = "pastel"
            elif slot == S_WHITE:
                cls = "alb"
            elif slot == S_DARK:
                cls = "sticla" if abs(n.z) < 0.35 else "acoperis"
            else:
                cls = "altele"
            info.append(cls)
    return BVHTree.FromPolygons(verts, tris, all_triangles=True), info


COLORS = {"pastel": (0.71, 0.78, 0.86), "alb": (0.96, 0.96, 0.94), "sticla": (0.12, 0.12, 0.14),
          "acoperis": (0.35, 0.33, 0.36), "altele": (0.78, 0.62, 0.45)}


RANGE = {"x0": -3.5, "x1": 3.5, "face": None}


def _ray(x, z):
    """Raza pentru coloana `x` a rasterului: din fata (Blender +Y) sau, la colt, dinspre o
    latura (`--face=-x|+x`; coloana = adancimea, de la fatada spre spate)."""
    f = RANGE["face"]
    if f == "-x":
        return Vector((-30.0, -x, z)), Vector((1.0, 0.0, 0.0))
    if f == "+x":
        return Vector((30.0, -x, z)), Vector((-1.0, 0.0, 0.0))
    return Vector((x, 30.0, z)), Vector((0.0, -1.0, 0.0))


def _raster(bvh, info, z0, z1, step, grid=None):
    cnt = {}
    x0r, x1r = RANGE["x0"], RANGE["x1"]
    nx = int(round((x1r - x0r) / step))
    nz = int(round((z1 - z0) / step))
    for i in range(nx):
        x = x0r + (i + 0.5) * step
        for k in range(nz):
            z = z0 + (k + 0.5) * step
            org, d = _ray(x, z)
            hit = bvh.ray_cast(org, d, 60.0)
            if hit[0] is None:
                continue
            c = info[hit[2]]
            cnt[c] = cnt.get(c, 0) + 1
            if grid is not None:
                grid[(i, k)] = c
    return cnt


def _png(bvh, info, step, path):
    z0, z1 = -2.4, 12.7
    grid = {}
    _raster(bvh, info, z0, z1, step, grid)
    w, h = int(round((RANGE["x1"] - RANGE["x0"]) / step)), int(round((z1 - z0) / step))
    img = bpy.data.images.new("fatada", w, h, alpha=False)
    px = [0.6] * (w * h * 4)
    for (i, k), c in grid.items():
        r, g, b = COLORS[c]
        o = (k * w + (w - 1 - i)) * 4   # vazut din strada: +X (garajul) in stanga
        px[o:o + 4] = [r, g, b, 1.0]
    for j in range(w * h):          # fundalul: gri
        if px[j * 4 + 3] != 1.0:
            px[j * 4:j * 4 + 4] = [0.6, 0.6, 0.6, 1.0]
    img.pixels = px
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    print("PNG", path)


def _fmt(label, cnt):
    tot = sum(cnt.values())
    nr = tot - cnt.get("acoperis", 0)
    parts = []
    for c in ("pastel", "alb", "sticla", "altele"):
        parts.append("%s %5.1f%%" % (c, 100.0 * cnt.get(c, 0) / max(nr, 1)))
    wr = ", ".join("%s %.1f%%" % (c, 100.0 * cnt.get(c, 0) / max(tot, 1))
                   for c in ("pastel", "alb", "sticla", "acoperis", "altele"))
    return "  %-14s %s   (cu acoperis: %s; %d px)" % (label, "  ".join(parts), wr, tot)


def main():
    paths, o = _args()
    RANGE.update(x0=o["x0"], x1=o["x1"], face=o.get("face"))
    for p in paths:
        bvh, info = _load(os.path.abspath(p))
        print("FATADA", os.path.basename(p), "(pas %.3f m)" % o["step"])
        print(_fmt("etaje+fronton", _raster(bvh, info, o["z0"], o["top"], o["step"])))
        print(_fmt("etaje", _raster(bvh, info, o["z0"], 9.6, o["step"])))
        print(_fmt("fronton", _raster(bvh, info, 9.6, 12.7, o["step"])))
        print(_fmt("parter", _raster(bvh, info, 0.0, 3.2, o["step"])))
        if o.get("png_dir"):
            _png(bvh, info, o["step"], os.path.join(
                o["png_dir"], os.path.splitext(os.path.basename(p))[0] + "_fatada.png"))


main()
