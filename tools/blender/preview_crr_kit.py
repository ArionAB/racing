"""Capturi de grup pentru kitul de cariera (kit §1.5, §3 val 1 crr-c).

Refoloseste `preview_carrara.py` (import din GLB-urile EXPORTATE, culoare
reala pe sloturi, *_Marble pe #E8D6B2, cubul implicit ascuns) si adauga:

  --compare a,b,c        mai multe comparatii decupare | randare intr-o rulare
  --views a,b            4 azimuturi pentru fiecare piesa
  --blocks               12 blocuri (marble_block_a/b/c) in stiva si imprastiate
                         -> marble_blocks_group12.png: marmura trebuie sa
                         citeasca CREM, nu alb (nimic nu are voie sa para zapada)
  --chain <nume> <n>     n module inlantuite pe Y la pas de 6 m, din doua
                         azimuturi -> <nume>_chain<n>.png
  --lineup <tag> a,b,c   piesele alaturate la aceeasi scara, stranse, ca sa se
                         poata judeca cele mici -> crr_kit_lineup_<tag>.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_crr_kit.py -- --blocks

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import math
import os
import sys

from mathutils import Vector

_here_k = os.path.dirname(os.path.abspath(__file__))
_argv_k = list(sys.argv)
sys.argv = ["preview_carrara.py"]          # preview_carrara isi citeste argv la incarcare
exec(compile(open(os.path.join(_here_k, "preview_carrara.py"), encoding="utf-8").read(),
             "preview_carrara.py", "exec"))
sys.argv = _argv_k


def _autocrop(path, pad=24):
    """Taie randarea transparenta pe alfa (plus o margine): cadrarea din
    `_render` se face pe colturile bbox-ului 3D, deci un grup rar (blocuri
    imprastiate, module lungi) iese mic in mijlocul unui cadru gol."""
    code = ("import sys; from PIL import Image; im = Image.open(sys.argv[1]); "
            "b = im.getchannel('A').getbbox(); p = %d; "
            "b and im.crop((max(b[0]-p,0), max(b[1]-p,0), min(b[2]+p,im.width), "
            "min(b[3]+p,im.height))).save(sys.argv[1])" % pad)
    import subprocess
    for exe in ("python", "py"):
        try:
            if subprocess.run([exe, "-c", code, path]).returncode == 0:
                return
        except FileNotFoundError:
            continue


def _place(name, offset=(0, 0, 0), yaw_deg=0.0):
    meshes = _import_path(_find_glb(name), offset=offset)
    for o in meshes:
        if o.parent is None:
            o.rotation_mode = "XYZ"          # importerul glTF lasa QUATERNION
            o.rotation_euler = (0.0, 0.0, math.radians(yaw_deg))
    import bpy
    bpy.context.view_layer.update()
    return meshes


def blocks_group():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    layout = [
        # (piesa, x, y, z, yaw) -- 3 x c, 4 x b, 5 x a; doua stive
        ("marble_block_c", 0.0, 0.0, 0.0, 0.0),
        ("marble_block_b", 0.3, 0.0, 2.0, 8.0),
        ("marble_block_a", 0.2, 0.1, 4.0, -10.0),
        ("marble_block_c", 4.0, 1.0, 0.0, 90.0),
        ("marble_block_c", -1.0, -4.0, 0.0, -8.0),
        ("marble_block_a", -1.4, -4.0, 2.0, 12.0),
        ("marble_block_b", -3.6, -0.5, 0.0, 15.0),
        ("marble_block_b", 5.0, -3.0, 0.0, 5.0),
        ("marble_block_b", -5.6, 3.9, 0.0, 0.0),
        ("marble_block_a", -3.0, 2.2, 0.0, 40.0),
        ("marble_block_a", 2.0, 3.5, 0.0, -20.0),
        ("marble_block_a", 1.5, -2.8, 0.0, 30.0),
    ]
    objs = []
    for name, x, y, z, yaw in layout:
        objs += _place(name, (x, y, z), yaw)
    tmp = os.path.join(FID_DIR, "_group12.png")
    _render(objs, tmp, azimuth=125.0, elevation=24.0, lens=55.0, margin=1.06,
            res_height=1400, aspect=1.5)
    _autocrop(tmp)
    # langa comparatia izolata a blocului _b, pe fundalul #C4C4C4
    _compose(["--montage", ",".join([os.path.join(FID_DIR, "marble_block_b.png"), tmp]),
              "--out", os.path.join(FID_DIR, "marble_blocks_group12.png")])
    _rm(tmp)


def chain(name, n):
    os.makedirs(FID_DIR, exist_ok=True)
    outs = []
    for az, el in ((160.0, 24.0), (20.0, 24.0)):
        _clear()
        objs = []
        for k in range(n):
            objs += _place(name, (0.0, (k - (n - 1) * 0.5) * 6.0, 0.0))
        p = os.path.join(FID_DIR, "_chain_%s_%d.png" % (name, int(az)))
        _render(objs, p, azimuth=az, elevation=el, lens=55.0, margin=1.05,
                res_height=1000, aspect=1.6)
        _autocrop(p)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out",
              os.path.join(FID_DIR, "%s_chain%d.png" % (name, n))])
    _rm(*outs)


def lineup(tag, names, az=125.0, el=20.0, gap=0.6):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    a = math.radians(az)
    right = Vector((-math.sin(a), math.cos(a), 0.0))
    objs = []
    cursor = 0.0
    for name in names:
        meshes = _place(name)
        lo, hi = _bounds(meshes)
        # extinderea piesei pe axa ecranului (proiectia bbox-ului pe `right`)
        cs = [Vector((x, y, 0)) for x in (lo.x, hi.x) for y in (lo.y, hi.y)]
        ext = [c.dot(right) for c in cs]
        w0, w1 = min(ext), max(ext)
        shift = cursor - w0
        for o in meshes:
            if o.parent is None:
                o.location = o.location + right * shift
        cursor += (w1 - w0) + gap
        objs += meshes
    import bpy
    bpy.context.view_layer.update()
    tmp = os.path.join(FID_DIR, "_lineup_%s.png" % tag)
    _render(objs, tmp, azimuth=az, elevation=el, lens=55.0, margin=1.04,
            res_height=1000, aspect=3.0)
    _autocrop(tmp)
    _compose(["--montage", tmp, "--out", os.path.join(FID_DIR, "crr_kit_lineup_%s.png" % tag)])
    _rm(tmp)


_a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in _a:
    for n in _a[_a.index("--compare") + 1].split(","):
        compare(n)
if "--views" in _a:
    for n in _a[_a.index("--views") + 1].split(","):
        views(n)
if "--blocks" in _a:
    blocks_group()
if "--chain" in _a:
    i = _a.index("--chain")
    chain(_a[i + 1], int(_a[i + 2]))
if "--lineup" in _a:
    i = _a.index("--lineup")
    lineup(_a[i + 1], _a[i + 2].split(","))
