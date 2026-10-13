"""Randari si masuratori de control pentru grupa tf-e (cladirile) -- peste
`preview_transfagarasan.py`, fara sa-l modifice (import din GLB-ul EXPORTAT,
culoarea pe slot, camera si compunerea harnasului).

  --compare <nume>   decupare | randare (camera din SPECS de mai jos)
  --views <nume>     4 azimuturi
  --facade <nume>    MASOARA pe GLB fata bogata: aria golurilor (nodul *_Void,
                     fetele din fata ale placilor negre) pe fiecare directie
                     +X/-X/+Y/-Y, plus cat iese geometria peste corpul cladirii
                     pe fiecare parte (terasa, scara, prispa). Nu randeaza.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_tf_e.py -- --compare cabana_balea_lac

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`
(--facade nu randeaza, nu cere lacatul).
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

from mathutils import Vector  # noqa: E402

# Camerele tf-e. Azimutul: camera la (cos a, sin a); fata bogata e +Y (90).
# cabana_balea_lac: pe decupare frontonul (+X) e fata mai frontala (~25-30 de
# grade fata de normala lui), latura lunga cu terasa (+Y) intra in dreapta.
SPECS.update({
    "cabana_balea_lac": {"camera": {"azimuth": 32.0, "elevation": 22.0, "lens": 60.0, "margin": 1.06}},
})


def _base(name):
    return re.sub(r"\.\d{3}$", "", name)


def facade(name):
    """Aria golurilor pe directie + iesirile din corp, masurate pe GLB."""
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    bpy.context.view_layer.update()
    lo, hi = _bounds(meshes)
    body = [o for o in meshes if _base(o.name).endswith(("_Stone", "_Plaster"))]
    blo, bhi = _bounds(body) if body else (lo, hi)
    cen = (blo + bhi) * 0.5
    area = {"+X": 0.0, "-X": 0.0, "+Y": 0.0, "-Y": 0.0, "sus": 0.0}
    count = dict.fromkeys(area, 0)
    for o in meshes:
        if not _base(o.name).endswith("_Void"):
            continue
        mw = o.matrix_world
        nm = mw.to_3x3().inverted().transposed()
        for p in o.data.polygons:
            n = (nm @ p.normal).normalized()
            c = mw @ p.center
            if n.z > 0.7:
                area["sus"] += p.area
                continue
            if abs(n.x) > 0.7:
                k = "+X" if n.x > 0 else "-X"
                outward = (c.x - cen.x) * n.x > 0
            elif abs(n.y) > 0.7:
                k = "+Y" if n.y > 0 else "-Y"
                outward = (c.y - cen.y) * n.y > 0
            else:
                continue
            if outward and p.area > 0.05:
                area[k] += p.area
                count[k] += 1
    print("FACADE %s (Blender: +Y = fata, = -Z in Godot)" % name)
    print("  corp (piatra/tencuiala): x %.2f..%.2f  y %.2f..%.2f" % (blo.x, bhi.x, blo.y, bhi.y))
    print("  bbox total:              x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f"
          % (lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))
    for k in ("+X", "-X", "+Y", "-Y"):
        print("  goluri %s: %5.2f m2 in %2d placi" % (k, area[k], count[k]))
    print("  iese peste corp: +Y %.2f m, -Y %.2f m, +X %.2f m, -X %.2f m"
          % (hi.y - bhi.y, blo.y - lo.y, hi.x - bhi.x, blo.x - lo.x))
    best = max(("+X", "-X", "+Y", "-Y"), key=lambda k: area[k])
    print("  fata cu cele mai multe goluri: %s" % best)


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare(args[args.index("--compare") + 1])
elif "--views" in args:
    views(args[args.index("--views") + 1])
elif "--facade" in args:
    facade(args[args.index("--facade") + 1])
else:
    print(__doc__)
