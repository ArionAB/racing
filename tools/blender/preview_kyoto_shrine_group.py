"""Planse de grup pentru grupa F (templele): piesele alaturate, la aceeasi scara.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_kyoto_shrine_group.py -- --group A|B
        ... -- preview_kyoto_shrine_group.py -- --chain cyclopean_wall

  --group A   votive_torii_cluster, kitsune a/b, yukimi_lantern  (randurile 3-4)
  --group B   lanterns a/b, small_shrine, ema_rack, bell_tower, chozuya,
              cyclopean_wall (randul 7)
  --chain <n> 3 module ale unei piese inlantuibile, cap la cap pe X

Randarile se salveaza in docs/asset_briefs/img/kyoto_fidelity/ si se aseaza
langa randul din planșa de inventar cu tools/blender/compose_kyoto_group.py
(Python de sistem, PIL). Lacatul de randare: vezi regulile (mkdir .render_lock).
"""
import os
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_saved = sys.argv
sys.argv = ["x"]                       # preview_kyoto cere doar functiile
exec(open(os.path.join(_here, "preview_kyoto.py")).read())
sys.argv = _saved

GROUPS = {
    "A": ["votive_torii_cluster", "kitsune_statue_a", "kitsune_statue_b", "yukimi_lantern"],
    "B": ["stone_lantern_a", "stone_lantern_b", "small_shrine", "ema_rack", "bell_tower",
          "chozuya", "cyclopean_wall"],
}


def _xr(meshes):
    lo, hi = _bounds(meshes)
    return lo, hi


def group(key):
    _clear()
    allm = []
    cursor = 0.0
    gap = 1.2
    for name in GROUPS[key]:
        ms = _import(SPECS[name], name)
        lo, hi = _bounds(ms)
        dx = cursor - lo.x
        for o in ms:
            o.location.x += dx
        cursor += (hi.x - lo.x) + gap
        allm += ms
    bpy.context.view_layer.update()
    out = os.path.join(FID_DIR, "grup_templele_%s.png" % key)
    os.makedirs(FID_DIR, exist_ok=True)
    _render(allm, out, azimuth=105.0, elevation=9.0, lens=60.0, margin=1.06,
            res_height=700, aspect=2.6)
    print("grup:", out)


def chain(name):
    _clear()
    allm = []
    for k in range(3):
        ms = _import(SPECS[name], name)
        for o in ms:
            o.location.x += 8.0 * (k - 1)
        allm += ms
    bpy.context.view_layer.update()
    out = os.path.join(FID_DIR, name + "_chain.png")
    _render(allm, out, azimuth=120.0, elevation=12.0, lens=60.0, margin=1.06,
            res_height=600, aspect=2.2)
    print("lant:", out)


a = sys.argv
if "--group" in a:
    group(a[a.index("--group") + 1])
elif "--chain" in a:
    chain(a[a.index("--chain") + 1])
