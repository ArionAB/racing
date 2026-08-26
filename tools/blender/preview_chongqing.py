"""Randeaza plansa de control pentru assets-urile Chongqing.

Importa GLB-urile deja exportate (nu le reconstruieste: verifica CE A AJUNS
in fisier, ca verify_glb, dar vizual) si scoate cate un PNG 3/4 per piesa.

    blender --background --factory-startup --python tools/blender/preview_chongqing.py \
        -- <out_dir> [subpath.glb ...]

Fara lista de piese, randeaza tot ce e sub assets/models/chongqing/.
"""

import bpy
import os
import sys
import math

HERE = os.path.dirname(os.path.abspath(__file__))
g = {"__name__": "__main__", "__file__": os.path.join(HERE, "dio_lib.py")}
exec(compile(open(os.path.join(HERE, "dio_lib.py")).read(), "dio_lib.py", "exec"), g)
exec(compile(open(os.path.join(HERE, "preview.py")).read(), "preview.py", "exec"), g)

MODELS = g["MODELS"]
shot = g["shot"]

argv = sys.argv[sys.argv.index("--") + 1:]
out_dir = argv[0]
wanted = argv[1:]
os.makedirs(out_dir, exist_ok=True)

root = os.path.join(MODELS, "chongqing")
if wanted:
    paths = [os.path.join(root, w) for w in wanted]
else:
    paths = []
    for d, _, files in os.walk(root):
        for f in sorted(files):
            if f.endswith(".glb"):
                paths.append(os.path.join(d, f))

# `--factory-startup` lasa cubul implicit de 2 m in scena (memoria
# `blender-preview-cub-implicit`). Daca ramane, se randeaza langa asset si
# citeste ca o bucata din el — o jumatate de ora pierduta cautand un bug in
# geometrie care era de fapt cubul lui Blender.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()

for p in paths:
    if not os.path.exists(p):
        print("LIPSA", p)
        continue
    # scena curata per piesa: altfel se aduna si camera incadreaza tot
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for blk in list(bpy.data.meshes):
        if blk.users == 0:
            bpy.data.meshes.remove(blk)

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=p)
    new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    if not new:
        print("GOL", p)
        continue
    name = os.path.splitext(os.path.basename(p))[0]
    png = os.path.join(out_dir, name + ".png")
    shot(new, png, azimuth=35.0, elevation=16.0, res=(640, 520))
    print("SHOT", name)
print("== preview: gata ==")
