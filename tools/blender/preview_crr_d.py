"""Preview pentru piesele crr-d (val 2: utilajele de decor si coltul de muzeu) --
ruleaza `preview_carrara.py` NESCHIMBAT, cu trei adaosuri locale (pe tiparul
preview_crr_a.py, ca grupele paralele sa nu scrie pe aceeasi linie):

  * camerele pieselor (SPECS), cu azimutul planșei;
  * decuparile coltului de muzeu: planșa are UN desen (`museum_set.png`) cu
    toate trei piesele; comparatia fiecarui GLB se face cu felia lui, taiata de
    `crop_crr_d.py` in docs/asset_briefs/img/carrara_fidelity/crops_crr_d/;
  * `Blades` (volantul masinii de fir) are UV-uri REALE (cube_uvs, pentru
    clasa `rust_metal` pe UV), deci culoarea lui nu se poate recupera din UV:
    se randeaza pe hexul slotului RUST_METAL.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_crr_d.py -- --compare wire_saw

Argumentele sunt cele din preview_carrara.py (--compare / --views).
RANDAREA RULEAZA PE GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
"""
import os

_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview_carrara.py"),
            encoding="utf-8").read()
_cut = _src.index("\nargv = sys.argv")
exec(compile(_src[:_cut], "preview_carrara.py", "exec"))

CROP_DIRS.insert(0, os.path.join(FID_DIR, "crops_crr_d"))
CLASS_BY_SUFFIX["Blades"] = "#" + PALETTE_HEX[10]

# azimutul camerei: (cos a, sin a); fata piesei e +Y Blender.
SPECS.update({
    # planșa: cutia in stanga, volantul in dreapta cu fata spre noi, sinele fug
    # spre dreapta-spate -> camera pe +X, putin din spate
    "wire_saw": {"camera": {"azimuth": -14.0, "elevation": 20.0, "lens": 85.0, "margin": 1.05}},
    # planșa: masina in stanga, lama spre dreapta -> camera pe +X, din spate
    "chain_saw_crawler": {"camera": {"azimuth": -22.0, "elevation": 14.0, "lens": 55.0, "margin": 1.05}},
    # planșa: corpul in stanga, catargul in dreapta cu burghiul spre noi -> camera din fata-dreapta
    "drill_rig": {"camera": {"azimuth": 30.0, "elevation": 10.0, "lens": 55.0, "margin": 1.05}},
    "museum_set_cart": {"camera": {"azimuth": -38.0, "elevation": 14.0, "lens": 55.0, "margin": 1.06}},
    "museum_set_wheel": {"camera": {"azimuth": -20.0, "elevation": 12.0, "lens": 55.0, "margin": 1.06}},
    "museum_set_sled": {"camera": {"azimuth": -35.0, "elevation": 24.0, "lens": 55.0, "margin": 1.06}},
})

exec(compile(_src[_cut:], "preview_carrara.py", "exec"))
