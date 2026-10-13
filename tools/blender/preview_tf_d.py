"""Randari de control pentru grupa tf-d (barajul si reperele) -- peste
`preview_transfagarasan.py`, fara sa-l modifice (tiparul `preview_tf_a.py`).

  --compare <nume>   decupare | randare din GLB-ul EXPORTAT (culoare reala pe slot /
                     clasa), camera din SPECS de mai jos
  --views <nume>     4 azimuturi -> <nume>_views.png
  --chain vidraru_dam [--count 6]
                     `count` module `Dam_Module` inlantuite pe Y (pas 16 m, coronament
                     de 96 m), `Dam_Tower` langa al doilea modul (partea lacului, -X),
                     `Dam_PowerHouse` la piciorul celui de-al patrulea. DOAR in
                     preview: un plan de apa la -4,5 m pe partea lacului si fundul
                     haului la -40 m, ca sa se compare cu diorama
                     -> vidraru_dam_chain.png

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_tf_d.py -- --compare vidraru_dam

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import math
import os
import re
import sys

_argv_keep = sys.argv
sys.argv = ["preview_transfagarasan.py"]      # harnasul isi tipareste doar doc-ul
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "preview_transfagarasan.py"), encoding="utf-8").read())
sys.argv = _argv_keep

from mathutils import Vector, Euler  # noqa: E402

# camera: azimutul a pune camera la (cos a, sin a). Barajul: decuparea arata fata
# din aval (+X) cu capatul +Y in dreapta-departe -> camera pe +X, putin spre -Y.
SPECS.update({
    "vidraru_dam": {"camera": {"azimuth": -38.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "poenari_ruin": {"camera": {"azimuth": -60.0, "elevation": 20.0, "lens": 60.0, "margin": 1.06}},
    "prometheus_statue": {"camera": {"azimuth": 75.0, "elevation": 12.0, "lens": 70.0, "margin": 1.08}},
})


def _root_of(o):
    while o.parent is not None:
        o = o.parent
    return o


def _base(name):
    return re.sub(r"\.\d{3}$", "", name)


def _plane(name, x0, x1, y0, y1, z, hexc):
    me = bpy.data.meshes.new(name)
    me.from_pydata([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], [], [(0, 1, 2, 3)])
    me.update()
    ao = me.color_attributes.new("AO", "FLOAT_COLOR", "POINT")   # materialul inmulteste cu AO
    for d in ao.data:
        d.color = (1.0, 1.0, 1.0, 1.0)
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(_flat_material(hexc))
    return o


def compare_d(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = os.path.join(CROPS, name + ".png")
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    aspect = max(0.5, min(8.0, cw / float(ch)))
    _render(meshes, tmp, res_height=res_height, aspect=aspect, **_camera_for(name))
    _compose(["--compare", name, "--crop", crop, "--render", tmp,
              "--out", os.path.join(FID_DIR, name + ".png"), "--height", str(res_height)])
    os.remove(tmp)


def views_d(name, res_height=700):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    outs = []
    for az in (35.0, 125.0, 215.0, 305.0):
        cam = _camera_for(name)
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(meshes, p, res_height=res_height, aspect=1.4, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, name + "_views.png")])
    for p in outs:
        os.remove(p)


def chain_dam(count=6, res_height=900):
    """`count` module pe Y, turnul la al doilea, centrala la al patrulea."""
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    L = 16.0
    ys = [(i - (count - 1) * 0.5) * L for i in range(count)]
    shown = []
    for i, y in enumerate(ys):
        want = {"Dam_Module"}
        if i == 1:
            want.add("Dam_Tower")
        if i == 3:
            want.add("Dam_PowerHouse")
        meshes = _import("vidraru_dam")
        roots = {}
        for o in meshes:
            r = _root_of(o)
            if _base(r.name) not in want:
                o.hide_render = True
                continue
            roots[r.name] = r
            shown.append(o)
        for r in roots.values():
            r.location = Vector((0.0, y, 0.0))
    bpy.context.view_layer.update()
    span = count * L * 0.5
    ctx = [_plane("PreviewLake", -36.0, -7.0, -span, span, -4.5, "#2F5446"),
           _plane("PreviewGorge", 7.0, 45.0, -span, span, -40.0, "#5B6B4A")]
    print("chain: %d module, coronament %.0f m" % (count, count * L))
    out = os.path.join(FID_DIR, "vidraru_dam_chain.png")
    # camera ca in diorama: din aval, de sus, pe +X
    _render(shown + ctx, out, azimuth=-12.0, elevation=30.0, lens=40.0, margin=1.02,
            res_height=res_height, aspect=1.6)
    _compose(["--montage", out, "--out", out])
    print("chain:", out)


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare_d(args[args.index("--compare") + 1])
elif "--views" in args:
    views_d(args[args.index("--views") + 1])
elif "--chain" in args:
    cnt = int(args[args.index("--count") + 1]) if "--count" in args else 6
    chain_dam(count=cnt)
else:
    print(__doc__)
