"""Captura de GRUP pentru plantele/stancile tf-b (kit Transfagarasan, §3 val 1:
"jneapanul, cu o captura de 8 tufe la 3 m una de alta (palcul de pe versant)").

Compune in Blender, din GLB-urile EXPORTATE, mai multe instante pe o grila
neregulata (pas dat), cu rotatie si scara variate, si le randeaza cu aceeasi
lumina si aceleasi culori ca `preview_transfagarasan.py` (il incarca prin exec,
fara sa-i ruleze modurile).

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_tf_group.py -- \
        --group jneapan_a:5,jneapan_b:3 --step 3 --out jneapan_group

-> docs/asset_briefs/img/transfagarasan_fidelity/<out>.png
RANDAREA RULEAZA PE GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
"""
import math
import os
import sys
from mathutils import Matrix, Vector

_my_args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
sys.argv = [sys.argv[0]]                      # preview-ul nu ruleaza niciun mod
_here_g = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_g, "preview_transfagarasan.py"), encoding="utf-8").read())


def _lcg_g(seed):
    st = [seed * 7919 + 13]

    def r():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return r


def group(spec, step, out, elevation=22.0, azimuth=58.0, cols=4):
    _clear()
    names = []
    for part in spec.split(","):
        n, c = part.split(":")
        names += [n] * int(c)
    r = _lcg_g(5)
    # amesteca determinist
    order = sorted(range(len(names)), key=lambda i: r())
    names = [names[i] for i in order]
    meshes = []
    for i, n in enumerate(names):
        got = _import(n)
        row, col = divmod(i, cols)
        x = (col - (cols - 1) * 0.5) * step + (r() - 0.5) * step * 0.35 + (row % 2) * step * 0.5
        y = -row * step + (r() - 0.5) * step * 0.35
        m = Matrix.Translation((x, y, 0.0)) @ Matrix.Rotation(r() * 2 * math.pi, 4, "Z")
        sc = 0.85 + 0.3 * r()
        m = m @ Matrix.Diagonal((sc, sc, sc, 1.0))
        for o in got:
            if o.parent is None:
                o.matrix_world = m @ o.matrix_world
        meshes += got
    bpy.context.view_layer.update()
    os.makedirs(FID_DIR, exist_ok=True)
    tmp = os.path.join(FID_DIR, "_group_" + out + ".png")
    _render(meshes, tmp, azimuth=azimuth, elevation=elevation, lens=50.0, margin=1.05,
            res_height=800, aspect=1.7)
    _compose(["--montage", tmp, "--out", os.path.join(FID_DIR, out + ".png")])
    try:
        os.remove(tmp)
    except OSError:
        pass


if "--group" in _my_args:
    g = _my_args[_my_args.index("--group") + 1]
    st = float(_my_args[_my_args.index("--step") + 1]) if "--step" in _my_args else 3.0
    o = _my_args[_my_args.index("--out") + 1] if "--out" in _my_args else "group"
    el = float(_my_args[_my_args.index("--elevation") + 1]) if "--elevation" in _my_args else 22.0
    group(g, st, o, elevation=el)
