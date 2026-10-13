"""Randari de control pentru grupa tf-a (drumul) -- peste `preview_transfagarasan.py`.

Refoloseste functiile harnasului (import din GLB-ul EXPORTAT, culoarea pe slot /
clasa, camera, compunerea) fara sa-l modifice: adauga doar
  * camerele pieselor tf-a (SPECS; la integrare se pot muta in harnas);
  * variantele: `--compare snow_wall` randeaza DOAR `SnowWall_A` (variantele
    stau suprapuse la origine), `--views` le pune alaturi (B decalat pe X);
  * `--chain snow_wall [--radius 30]`: 4 module `SnowWall_A` inlantuite pe o
    curba (peretele pe exteriorul curbei, fata spre drum = spre centru), cu
    pasul ales ca muchiile EXTERIOARE sa se atinga (in interior se suprapun).

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_tf_a.py -- --compare snow_wall

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

# camerele tf-a. Azimutul: camera la (cos a, sin a); fata spre drum a peretilor
# e -X, deci 3/4 dinspre drum = azimut ~200 (capatul -Y in dreapta, ca pe decupare).
SPECS.update({
    "snow_wall": {"camera": {"azimuth": 205.0, "elevation": 16.0, "lens": 60.0, "margin": 1.08},
                  "variant": "SnowWall_A", "side": {"SnowWall_B": (0.0, -10.0, 0.0)}},
    "rock_tunnel_portal": {"camera": {"azimuth": 62.0, "elevation": 14.0, "lens": 60.0, "margin": 1.08}},
    "retaining_wall_straight": {"camera": {"azimuth": 30.0, "elevation": 16.0, "lens": 60.0, "margin": 1.08}},
    "retaining_wall_curve": {"camera": {"azimuth": 20.0, "elevation": 18.0, "lens": 60.0, "margin": 1.08}},
    "snow_pole": {"camera": {"azimuth": 60.0, "elevation": 10.0, "lens": 80.0, "margin": 1.1}},
    "road_works": {"camera": {"azimuth": 70.0, "elevation": 14.0, "lens": 60.0, "margin": 1.08}},
    "level_crossing": {"camera": {"azimuth": 75.0, "elevation": 10.0, "lens": 60.0, "margin": 1.08}},
    "bear_warning_sign": {"camera": {"azimuth": 88.0, "elevation": 6.0, "lens": 80.0, "margin": 1.1}},
})


def _root_of(o):
    while o.parent is not None:
        o = o.parent
    return o


def _base(name):
    return re.sub(r"\.\d{3}$", "", name)


def _import_a(name, mode):
    """Importa GLB-ul; filtreaza/decaleaza variantele dupa SPECS."""
    meshes = _import(name)
    spec = SPECS.get(name, {})
    var = spec.get("variant")
    if not var:
        return meshes
    keep = []
    for o in meshes:
        root = _base(_root_of(o).name)
        if mode == "compare":
            if root == var:
                keep.append(o)
            else:
                o.hide_render = True
        else:
            off = spec.get("side", {}).get(root)
            if off:
                _root_of(o).rotation_mode = "XYZ"
                _root_of(o).location = Vector(off)
            keep.append(o)
    bpy.context.view_layer.update()
    return keep


def compare_a(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = os.path.join(CROPS, SPECS.get(name, {}).get("crop", name) + ".png")
    _clear()
    meshes = _import_a(name, "compare")
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


def views_a(name, res_height=700):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import_a(name, "views")
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


def chain(name, radius=30.0, count=4, res_height=800):
    """`count` module ale variantei din SPECS pe un arc de raza `radius` (la axa
    modulului), peretele pe EXTERIORUL curbei: -X (fata spre drum) spre centru.
    Pasul unghiular face ca muchiile exterioare (+X, y = +-L/2) sa coincida."""
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    spec = SPECS.get(name, {})
    var = spec.get("variant")
    half_w, half_l = 1.25, 4.0
    dphi = 2.0 * math.atan(half_l / (radius + half_w))
    shown = []
    for i in range(count):
        meshes = _import(name)
        roots = {}
        for o in meshes:
            r = _root_of(o)
            if var and _base(r.name) != var:
                o.hide_render = True
                continue
            roots[r.name] = r
            shown.append(o)
        phi = (i - (count - 1) * 0.5) * dphi
        for r in roots.values():
            # centrul curbei la origine; modulul la raza `radius`, X local = radial
            r.location = Vector((radius * math.cos(phi), radius * math.sin(phi), 0.0))
            r.rotation_mode = "XYZ"      # importul glTF lasa radacinile pe QUATERNION
            r.rotation_euler = Euler((0.0, 0.0, phi))
    bpy.context.view_layer.update()
    print("chain: %d module, R = %.1f m, pas %.2f grade (coarda la exterior 8,00 m)"
          % (count, radius, math.degrees(dphi)))
    out = os.path.join(FID_DIR, name + "_chain.png")
    # camera: dinspre drum (din centrul curbei, inapoi si sus), ca din masina
    _render(shown, out, azimuth=180.0 + 25.0, elevation=20.0, lens=40.0, margin=1.05,
            res_height=res_height, aspect=1.8)
    _compose(["--montage", out, "--out", out])
    print("chain:", out)


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare_a(args[args.index("--compare") + 1])
elif "--views" in args:
    views_a(args[args.index("--views") + 1])
elif "--chain" in args:
    rad = float(args[args.index("--radius") + 1]) if "--radius" in args else 30.0
    chain(args[args.index("--chain") + 1], radius=rad)
else:
    print(__doc__)
