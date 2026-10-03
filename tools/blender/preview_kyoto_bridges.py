"""Previzualizari pentru podurile Kyoto (build_kyoto_bridges.py).

Reutilizeaza `preview_kyoto.py` (fara sa-l modifice): ii incarca functiile,
ii adauga specificatiile podurilor si ruleaza `--compare`, `--views`, `--chain`.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_bridges.py -- --chain togetsukyo_module

  --compare <nume>  decupare | randare   --views <nume>  4 azimuturi
  --chain <nume>    3 module alaturate pe axa lungimii (Y), pentru cusaturi
RANDAREA RULEAZA PE GPU: mkdir D:/GameDev/.render_lock inainte, rmdir dupa.
"""
import os
import sys

_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         "preview_kyoto.py")).read()
_src = _src[:_src.index("argv = sys.argv")]
exec(compile(_src, "preview_kyoto.py", "exec"))

SPECS.update({
    "tsutenkyo_roof_module": {"category": "structures",
        "camera": {"azimuth": 20.0, "elevation": 12.0, "lens": 80.0, "margin": 1.1},
        "chain_camera": {"azimuth": 20.0, "elevation": 14.0, "lens": 60.0},
        "chain_step": 6.0},
    "togetsukyo_module": {"category": "structures",
        "camera": {"azimuth": 25.0, "elevation": 14.0, "lens": 80.0, "margin": 1.1},
        "chain_camera": {"azimuth": 25.0, "elevation": 16.0, "lens": 60.0},
        "chain_step": 10.0},
    "iron_truss_bridge": {"category": "structures",
        "camera": {"azimuth": 70.0, "elevation": 10.0, "lens": 80.0, "margin": 1.1}},
})


def chain(name, n=3, res_height=800):
    spec = SPECS[name]
    step = spec.get("chain_step", 6.0)
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    allm = []
    for i in range(n):
        ms = _import(spec, name)
        for o in ms:
            o.location.y += (i - (n - 1) / 2.0) * step
        allm += ms
    bpy.context.view_layer.update()
    cam = dict(_camera_for(spec))
    cam.update(spec.get("chain_camera", {}))
    _render(allm, os.path.join(FID_DIR, name + "_chain.png"), res_height=res_height,
            aspect=1.5, **cam)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--chain" in args:
    chain(args[args.index("--chain") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--solo" in args:
    solo(args[args.index("--solo") + 1])
else:
    print(__doc__)
