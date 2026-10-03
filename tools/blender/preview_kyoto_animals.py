"""Pozele animalelor Kyoto, randate din GLB-ul EXPORTAT (actiunile citite din fisier),
langa decupari.  -> docs/asset_briefs/img/kyoto_fidelity/sika_deer.png (3 randuri) si crow.png

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_animals.py
(RANDARE PE GPU: .render_lock inainte/dupa)"""
import bpy, os, sys, subprocess
_src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview_kyoto.py"), encoding="utf-8").read()
exec(_src[:_src.index("\nargv = sys.argv")])

POSES = [("sika_deer", "sika_deer_stand", "Stand", 1), ("sika_deer", "sika_deer_graze", "Graze", 1),
         ("sika_deer", "sika_deer_bow", "Bow", 30), ("crow", "crow", "Fly", 1), ("crow", "crow", "Fly", 7)]
CAM = {"sika_deer": dict(azimuth=35.0, elevation=8.0, lens=60.0, margin=1.15),
       "crow": dict(azimuth=60.0, elevation=25.0, lens=60.0, margin=1.25)}

os.makedirs(FID_DIR, exist_ok=True)
outs = {}
for glb, crop, act, frame in POSES:
    _clear()
    spec = {"category": "animals", "glb": glb}
    meshes = _import(spec, glb)
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    a = bpy.data.actions[act]
    arm.animation_data.action = a
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    tmp = os.path.join(FID_DIR, "_render_%s_%s_%d.png" % (glb, act, frame))
    img = bpy.data.images.load(os.path.join(CROPS, crop + ".png")); cw, ch = img.size; bpy.data.images.remove(img)
    _render(meshes, tmp, res_height=700, aspect=max(0.5, cw / float(ch)), **CAM[glb])
    out = os.path.join(FID_DIR, "_cmp_%s_%s_%d.png" % (glb, act, frame))
    _compose(["--compare", crop, "--crop", os.path.join(CROPS, crop + ".png"), "--render", tmp,
              "--out", out, "--height", "500"])
    outs.setdefault(glb, []).append(out)
for glb, lst in outs.items():
    code = ("from PIL import Image;ims=[Image.open(p) for p in %r];w=max(i.width for i in ims);"
            "h=sum(i.height for i in ims);o=Image.new('RGB',(w,h),(207,207,207));y=0\n"
            "for i in ims:\n o.paste(i,(0,y));y+=i.height\n"
            "o.save(%r)" % (lst, os.path.join(FID_DIR, glb + ".png")))
    subprocess.run(["python", "-c", code])
