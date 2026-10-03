"""Planșa arborilor Kyoto la ACEEASI scara, intr-un singur cadru (kit §1.2).

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_trees.py

Reuseste definitiile din preview_kyoto.py (fara a-i rula CLI-ul). Randeaza pe
GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
-> docs/asset_briefs/img/kyoto_fidelity/arbori_scara.png
"""
import os
_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         "preview_kyoto.py"), encoding="utf-8").read()
exec(_src[:_src.index("argv = sys.argv")])

NAMES = ["momiji_a", "momiji_b", "momiji_c", "ginkgo", "niwaki_pine"]
_clear()
allm = []
az = math.radians(125.0)
perp = Vector((-math.sin(az), math.cos(az), 0.0))
for i, n in enumerate(NAMES):
    ms = _import(SPECS[n], n)
    for o in ms:
        o.location = perp * (i - 2) * 13.0
    allm += ms
bpy.context.view_layer.update()
os.makedirs(FID_DIR, exist_ok=True)
_render(allm, os.path.join(FID_DIR, "arbori_scara.png"), azimuth=125.0,
        elevation=10.0, lens=70.0, margin=1.05, res_height=700, aspect=3.2)
