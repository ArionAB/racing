"""Randari pentru grupul C din valul 2 (kitul naga): randuri inlantuite sub camera de joc.

Invelis peste `preview_angkor.py` (fara sa-l modifice): aceleasi moduri
(--compare / --views / --gamecam) plus

  --row giants     cinci uriasi (deva/asura alternand) pe marginea dreapta a unui
                   drum, spatele-n spate la 4,0 m, trupul naga continuu printre ei;
                   a doua jumatate: aceiasi pe stanga, rotiti cu 180 de grade
  --row balustrade cinci module de balustrada, un modul rupt, si capul naga la
                   capatul dinspre masina (rotit 180: priveste spre cine vine)

Fiecare da doua cadre de joc (masina pe axa si masina langa margine), cu
decuparea marita alaturi. Drumul (12 m) e un plan intunecat, ca sa se judece
scara fata de masina.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_angkor_w2c.py -- --row giants

Inainte de randare: `mkdir D:/GameDev/.render_lock`; dupa: `rmdir`.
"""
import os

_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview_angkor.py"),
            encoding="utf-8").read()
_head, _sep, _tail = _src.partition("argv = sys.argv")
exec(compile(_head, "preview_angkor.py", "exec"), globals())

SPECS.update({
    "ROW_giants": {"bury": 0.0},
    "ROW_giants_far": {"bury": 0.0},
    "ROW_balustrade": {"bury": 0.0},
})


def _place(name, x, y, yaw_deg=0.0):
    """Importa piesa `name` cu originea la (x, y, 0), rotita cu `yaw_deg` in jurul lui Z."""
    import math as _m
    before = set(bpy.data.objects)
    path = _find_glb(name)
    meshes = _import_path(path)
    new = [o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.parent is None:
            o.rotation_euler = (0.0, 0.0, _m.radians(yaw_deg))
            o.location = Vector((x, y, 0.0))
    bpy.context.view_layer.update()
    return meshes


def _road(width=12.0, length=140.0):
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.0, 0.0, 0.02))
    r = bpy.context.active_object
    r.name = "GCRoad"
    r.scale = (width, length, 1.0)
    r.data.materials.append(_plain_material("GCRoad", "#4A4742"))


def build_row(kind):
    out = []
    _road()
    if kind.startswith("giants"):
        names = ["deva_giant", "asura_giant"]
        for k, y in enumerate((-8.0, -4.0, 0.0, 4.0, 8.0)):
            out += _place(names[k % 2], 6.0, y, 0.0)
            out += _place(names[(k + 1) % 2], -6.0, y, 180.0)
    else:
        # balustrada pe marginea dreapta (x=+5): 5 module, al treilea rupt;
        # capul la capatul dinspre masina (y=-10), rotit 180 ca sa priveasca spre -Y
        x = 5.0
        ys = (-8.0, -4.0, 0.0, 4.0, 8.0)
        for k, y in enumerate(ys):
            out += _place("naga_balustrade_gap" if k == 2 else "naga_balustrade", x, y, 0.0)
        out += _place("naga_head", x, -10.0, 180.0)
        # si pe stanga, in oglinda (fata drumului pe +X): rotit 180
        for k, y in enumerate(ys):
            out += _place("naga_balustrade", -x, y, 180.0)
        out += _place("naga_head", -x, -10.0, 180.0)
    for o in out:
        o.hide_render = False
    return out


_orig_import = _import


def _import(name):
    if name.startswith("ROW_"):
        return build_row(name[4:])
    return _orig_import(name)


argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []
if "--row" in args:
    kind = args[args.index("--row") + 1]
    far = "--far" in args
    if far:
        gamecam("ROW_" + kind, ahead=60.0, suffix="_gamecam_far", cars=(("a", 0.0),))
    else:
        gamecam("ROW_" + kind, suffix="_gamecam", cars=(("a", 0.0), ("b", 3.0)))
else:
    exec(compile(_sep + _tail, "preview_angkor.py", "exec"), globals())
