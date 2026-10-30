"""Randari de control pentru structurile Carrara (grupa crr-b) -- din GLB-urile EXPORTATE.

Foloseste `preview_carrara.py` neschimbat (exec, fara argumentele lui) si adauga
doar ce cer structurile (kit §1.3):
  * un PLAN NEGRU in spatele gurii portalurilor (NU e in GLB): captuseala
    `Portal_Void` are doar 2 m, iar fara plan s-ar vedea fundalul prin tunel;
  * camera si aspectul randarii per piesa (viaductul e lung: aspectul decuparii,
    4:1, l-ar face mic in cadru).

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_crr_structures.py -- --compare ponti_di_vara
    ... -- preview_crr_structures.py -- --views gallery_portal
    ... -- preview_crr_structures.py -- --front marmifera_portal   # din fata, la nivelul ochiului

RANDAREA RULEAZA PE GPU: inainte, `mkdir D:/GameDev/.render_lock`, dupa, `rmdir`.
"""
import os
import sys

_HERE_S = os.path.dirname(os.path.abspath(__file__))
_argv = sys.argv
sys.argv = [_argv[0]]
exec(open(os.path.join(_HERE_S, "preview_carrara.py"), encoding="utf-8").read())
sys.argv = _argv

# camera: azimutul a pune camera la (cos a, sin a); fata pieselor e +Y.
CRR_B_SPECS = {
    # planșa: elevatia laterala, usor de sus; viaductul e lung pe Y -> camera pe +X
    "ponti_di_vara": dict(camera=dict(azimuth=12.0, elevation=8.0, lens=60.0, margin=1.06),
                          aspect=1.45, void=None),
    # planșa: 3/4 din fata-stanga (se vede latura stanga a ramei)
    # (ecranul priveste fata +Y, deci dreapta ecranului e -X: latura +X iese in stanga)
    "gallery_portal": dict(camera=dict(azimuth=66.0, elevation=18.0, lens=55.0, margin=1.08),
                           aspect=1.22, void=(-3.0, 5.6, 11.3)),
    # planșa: aproape din fata, putin din stanga (sinele intra pe diagonala)
    "marmifera_portal": dict(camera=dict(azimuth=76.0, elevation=14.0, lens=55.0, margin=1.08),
                             aspect=1.38, void=(-2.4, 5.6, 4.2, "arch")),
}


def _void_plane(spec):
    """Plan negru la y (Blender) acoperind gura: (y, jumatate de latime, inaltime[, "arch"])."""
    if not spec:
        return None
    y, hw, h = spec[:3]
    if len(spec) > 3:      # gura arcuita: dreptunghi pana la nastere h, semicerc de raza hw
        pts = [(-hw, y, -0.05), (hw, y, -0.05)]
        pts += [(hw * math.cos(math.pi * k / 16), y, h + hw * math.sin(math.pi * k / 16))
                for k in range(17)]
    else:
        pts = [(-hw, y, -0.05), (hw, y, -0.05), (hw, y, h), (-hw, y, h)]
    me = bpy.data.meshes.new("Preview_Void")
    me.from_pydata(pts, [], [tuple(range(len(pts)))])
    ob = bpy.data.objects.new("Preview_Void", me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(_flat_material("#050505"))
    return ob


def _scene(name):
    _clear()
    meshes = _import(name)
    if not meshes:
        return []
    vp = _void_plane(CRR_B_SPECS.get(name, {}).get("void"))
    return meshes + ([vp] if vp else [])


def compare_s(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = _find_crop(name)
    if crop is None:
        print("LIPSA decupare:", name)
        return
    objs = _scene(name)
    if not objs:
        return
    spec = CRR_B_SPECS.get(name, {})
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    _render(objs, tmp, res_height=res_height, aspect=spec.get("aspect", 1.2),
            **spec.get("camera", _camera_for(name)))
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])
    _rm(tmp)


def views_s(name, res_height=700):
    os.makedirs(FID_DIR, exist_ok=True)
    objs = _scene(name)
    if not objs:
        return
    outs = []
    for az in (35.0, 125.0, 215.0, 305.0):
        cam = dict(CRR_B_SPECS.get(name, {}).get("camera", _camera_for(name)))
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(objs, p, res_height=res_height, aspect=1.4, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, name + "_views.png")])
    _rm(*outs)


def front_s(name, res_height=800):
    """Din fata (portaluri) / din lateral (viaduct), aproape la nivelul ochiului:
    proportiile golului si ale arcelor, fara perspectiva de 3/4."""
    os.makedirs(FID_DIR, exist_ok=True)
    objs = _scene(name)
    if not objs:
        return
    az = 0.0 if name == "ponti_di_vara" else 90.0
    p = os.path.join(FID_DIR, name + "_front.png")
    tmp = p.replace(".png", "_tmp.png")
    _render(objs, tmp, azimuth=az, elevation=3.0, lens=80.0, margin=1.05,
            res_height=res_height, aspect=1.4)
    _compose(["--montage", tmp, "--out", p])
    _rm(tmp)


_args = _argv[_argv.index("--") + 1:] if "--" in _argv else []
if "--compare" in _args:
    compare_s(_args[_args.index("--compare") + 1])
elif "--views" in _args:
    views_s(_args[_args.index("--views") + 1])
elif "--front" in _args:
    front_s(_args[_args.index("--front") + 1])
else:
    print(__doc__)
