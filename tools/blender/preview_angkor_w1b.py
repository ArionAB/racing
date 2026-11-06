"""Randari pentru grupul B din valul 1 (aw_west_gopura, ta_prohm_tree_gate).

Invelis peste `preview_angkor.py` (fara sa-l modifice, ca grupurile paralele sa nu
se bata pe `SPECS`): ruleaza aceeasi sursa, adauga camerele pieselor largi si un
`views` cu aspect panoramic. Aceleasi moduri: --compare / --views / --gamecam.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_angkor_w1b.py -- --compare aw_west_gopura

Inainte de randare: `mkdir D:/GameDev/.render_lock`; dupa: `rmdir`.
"""
import os

_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview_angkor.py"),
            encoding="utf-8").read()
_head, _sep, _tail = _src.partition("argv = sys.argv")
exec(compile(_head, "preview_angkor.py", "exec"), globals())

SPECS.update({
    # galeria se vede din fata (dinspre -Y), putin din lateral, ca in decupare
    "aw_west_gopura": {"camera": {"azimuth": 292.0, "elevation": 7.0, "lens": 40.0, "margin": 1.05},
                       "aspect_views": 1.6, "views_h": 460},
    "ta_prohm_tree_gate": {"camera": {"azimuth": 282.0, "elevation": 8.0, "lens": 50.0, "margin": 1.05},
                           "aspect_views": 0.9},
})


def views(name, res_height=800):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    outs = []
    asp = SPECS.get(name, {}).get("aspect_views", 0.6)
    res_height = SPECS.get(name, {}).get("views_h", res_height)
    base = _camera_for(name)["azimuth"]
    for k in range(4):
        cam = _camera_for(name)
        cam["azimuth"] = base + 90.0 * k
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, k))
        _render(meshes, p, res_height=res_height, aspect=asp, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, name + "_views.png")])
    _rm(*outs)


exec(compile(_sep + _tail, "preview_angkor.py", "exec"), globals())
