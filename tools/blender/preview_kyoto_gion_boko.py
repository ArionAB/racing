"""Planse de control pentru gion_boko.glb, randate din obiectele tocmai construite.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_gion_boko.py -- OUT_DIR

Vederi: 3/4 de aproape, din lateral (cum il vede soferul: capatul lung pe X, camera pe
-Y Blender = +Z Godot), de la capat, si "sofer" (camera la 1.2 m).
"""
import sys
import os

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "build_kyoto_gion_boko.py")).read())

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."
os.makedirs(OUT, exist_ok=True)

mine = set(objs)
for o in bpy.data.objects:
    if o.type == "MESH" and o not in mine:
        o.hide_render = True

shot(objs, os.path.join(OUT, "gion_boko_34.png"), azimuth=-55.0, elevation=12.0, margin=1.5, res=(720, 1000))
shot(objs, os.path.join(OUT, "gion_boko_lateral.png"), azimuth=-90.0, elevation=6.0, margin=1.5, res=(720, 1000))
shot(objs, os.path.join(OUT, "gion_boko_capat.png"), azimuth=0.0, elevation=8.0, margin=1.5, res=(720, 1000))
shot(objs, os.path.join(OUT, "gion_boko_sofer.png"), azimuth=-70.0, elevation=3.0, margin=1.6, res=(960, 720), driver=True)
