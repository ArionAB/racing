"""Preview pentru piesele crr-a (derrick, blocul agatat, sania, blocul informe,
excavatorul) -- ruleaza `preview_carrara.py` NESCHIMBAT, cu doua adaosuri locale:

  * camerele pieselor (SPECS), ca planșa si randarea sa aiba acelasi azimut,
    fara sa atinga dictionarul din preview_carrara.py (trei constructori in
    paralel l-ar fi modificat pe aceeasi linie);
  * derrick-ul se compune ca in joc: in GLB `Jib` sta in origine (codul il muta
    pe pivotul de la JIB_HEIGHT), deci aici se ridica la 22,05 m.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_crr_a.py -- --compare derrick

Argumentele sunt cele din preview_carrara.py (--compare / --views / --vs).
RANDAREA RULEAZA PE GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
"""
import os

_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview_carrara.py"),
            encoding="utf-8").read()
_cut = _src.index("\nargv = sys.argv")
exec(compile(_src[:_cut], "preview_carrara.py", "exec"))

# azimutul camerei: (cos a, sin a); fata piesei e +Y Blender. 35-55 = din fata-
# dreapta (bratul/fata spre dreapta imaginii, ca pe planșe).
SPECS.update({
    "derrick": {"camera": {"azimuth": 18.0, "elevation": 10.0, "lens": 55.0, "margin": 1.06}},
    "marble_block_hooked": {"camera": {"azimuth": 62.0, "elevation": 14.0, "lens": 60.0, "margin": 1.08}},
    "lizza_sled": {"camera": {"azimuth": 28.0, "elevation": 26.0, "lens": 55.0, "margin": 1.06}},
    "block_informe_a": {"camera": {"azimuth": 55.0, "elevation": 14.0, "lens": 60.0, "margin": 1.08}},
    "quarry_excavator": {"camera": {"azimuth": 38.0, "elevation": 14.0, "lens": 55.0, "margin": 1.06}},
})

DK_JIB_HEIGHT = 22.05
_import_path_orig = _import_path


def _import_path(path, offset=(0.0, 0.0, 0.0)):
    meshes = _import_path_orig(path, offset)
    if os.path.basename(path) == "derrick.glb":
        for o in meshes:
            if o.parent is None and o.name.split(".")[0] == "Jib":
                o.location.z += DK_JIB_HEIGHT
        bpy.context.view_layer.update()
    return meshes


exec(compile(_src[_cut:], "preview_carrara.py", "exec"))
