"""Planșa de grup a gradinii/bambusului: toate piesele la scara metrica, intr-un
rand (front, lentila lunga ~ ortografic), sub randul lor din inventar_v02.jpg.

    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_kyoto_garden.py

RANDEAZA PE GPU: `mkdir D:/GameDev/.render_lock` inainte, `rmdir` dupa.
Iesire: docs/asset_briefs/img/kyoto_fidelity/garden_group.png
"""
import os
import subprocess
import sys

_here = os.path.dirname(os.path.abspath(__file__))
_saved = sys.argv
sys.argv = ["x"]
exec(open(os.path.join(_here, "preview_kyoto.py")).read())
sys.argv = _saved

ORDER = [("plants", "moso_culm", {}), ("plants", "bamboo_crown", {}),
         ("props", "shiba_fence", {"rot": 90.0}),
         ("plants", "karikomi_shrub_a", {}), ("plants", "karikomi_shrub_b", {}),
         ("rocks", "garden_rock_a", {}), ("rocks", "garden_rock_b", {}),
         ("rocks", "garden_rock_c", {}), ("rocks", "stepping_stones", {"rot": 90.0}),
         ("rocks", "moss_mound", {}), ("props", "leaf_pile", {})]


def _row(items, out, aspect, res_height):
    import math
    _clear()
    allm = []
    x = 0.0
    for cat, name, o in items:
        spec = {"category": cat}
        spec["tints"] = {"Rock_Moss": "moss", "RockC_Moss": "moss", "Moss_Mound": "moss"}
        ms = _import(spec, name)
        for m in ms:
            if "rot" in o and m.parent is None:
                m.rotation_mode = "XYZ"
                m.rotation_euler[2] = math.radians(o["rot"])
        bpy.context.view_layer.update()
        lo, hi = _bounds(ms)
        dx = x - hi.x            # camera la +Y priveste spre -Y: +X apare in stanga
        for m in ms:
            if m.parent is None:
                m.location.x += dx
        bpy.context.view_layer.update()
        lo, hi = _bounds(ms)
        x = lo.x - 1.0
        allm += ms
    _render(allm, out, azimuth=90.0, elevation=6.0, lens=600.0, margin=1.04,
            res_height=res_height, aspect=aspect)


def group():
    small = [i for i in reversed(ORDER) if i[1] not in ("moso_culm", "bamboo_crown")]
    tall = [("plants", "karikomi_shrub_a", {}), ("plants", "bamboo_crown", {}),
            ("plants", "moso_culm", {})]
    o1 = os.path.join(FID_DIR, "_render_garden_small.png")
    o2 = os.path.join(FID_DIR, "_render_garden_tall.png")
    _row(list(reversed(small)), o1, 5.5, 380)
    _row(tall, o2, 0.55, 760)
    inv = os.path.join(PROJ, "docs", "track_briefs", "img", "kyoto_plan", "inventar_v02.jpg")
    final = os.path.join(FID_DIR, "garden_group.png")
    code = (
        "from PIL import Image\n"
        "def flat(p):\n"
        "    r=Image.open(p).convert('RGBA'); bg=Image.new('RGBA',r.size,(207,207,207,255)); bg.alpha_composite(r); return bg.convert('RGB')\n"
        "a=Image.open(r'%s').convert('RGB').crop((0,1086,1024,1218))\n"
        "s=flat(r'%s'); t=flat(r'%s')\n"
        "w=s.size[0]; a=a.resize((w,int(a.size[1]*w/a.size[0])))\n"
        "th=360; t=t.resize((int(t.size[0]*th/t.size[1]),th))\n"
        "o=Image.new('RGB',(w,a.size[1]+s.size[1]+th),(255,255,255)); o.paste(a,(0,0)); o.paste(s,(0,a.size[1])); o.paste(t,((w-t.size[0])//2,a.size[1]+s.size[1]))\n"
        "o.save(r'%s')\n" % (inv, o1, o2, final))
    subprocess.run(["python", "-c", code], check=True)
    print("planșa:", final)


group()
