"""Randari de control pentru fundalul Carrara (kit §1.6, val 2, crr-f).

Refoloseste `preview_carrara.py` (import din GLB-ul EXPORTAT, culoare reala pe
sloturi, cubul implicit ascuns, lumina de zi neutra, fundal #C4C4C4) si adauga
alegerea unui NOD din `carrara_horizon.glb` (cele trei creste stau toate in
acelasi fisier, suprapuse in origine):

  --compare        decuparea DEASUPRA, randarea nodului dedesubt, la aceeasi
                   latime in pixeli (decuparile sunt fasii de 4,4:1, alaturate
                   ar iesi o imagine de 9:1):
                     apuan_ridge   <- ApuanRidge_A  (din fata, usor de sus)
                     apuan_ridge_b <- ApuanRidge_B  (de sus, ca planșa)
                   -> docs/asset_briefs/img/carrara_fidelity/<decupare>.png
  --views          cele trei creste din 4 azimuturi (o banda pe creasta)
                   -> carrara_horizon_views.png
  --lineup         cele trei alaturate, din fata, la aceeasi scara
                   -> carrara_horizon_lineup.png

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_crr_horizon.py -- --compare

RANDAREA RULEAZA PE GPU: inainte `mkdir D:/GameDev/.render_lock`, dupa `rmdir`.
"""

import math
import os
import re
import subprocess
import sys

from mathutils import Vector

_here_h = os.path.dirname(os.path.abspath(__file__))
_argv_h = list(sys.argv)
sys.argv = ["preview_carrara.py"]          # preview_carrara isi citeste argv la incarcare
exec(compile(open(os.path.join(_here_h, "preview_carrara.py"), encoding="utf-8").read(),
             "preview_carrara.py", "exec"))
sys.argv = _argv_h

import bpy  # noqa: E402

HORIZON = os.path.join(MODELS_DIR, "effects", "carrara_horizon.glb")
NODES = ["ApuanRidge_A", "ApuanRidge_B", "ApuanRidge_C"]
# decupare -> (nod, azimut, elevatie): azimutul -90 = camera pe -Y, priveste
# lungimea crestei (X) din fata, cum e desenata planșa
COMPARE = {"apuan_ridge": ("ApuanRidge_A", -90.0, 9.0),
           "apuan_ridge_b": ("ApuanRidge_B", -90.0, 28.0)}


def _node(name, offset=(0.0, 0.0, 0.0)):
    """Importa GLB-ul si pastreaza doar nodul cerut."""
    meshes = _import_path(HORIZON)
    keep = []
    for o in meshes:
        if re.sub(r"\.\d{3}$", "", o.name) == name:
            keep.append(o)
        else:
            bpy.data.objects.remove(o, do_unlink=True)
    for o in keep:
        o.location = o.location + Vector(offset)
    bpy.context.view_layer.update()
    return keep


def _pil(code, *args):
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, "-c", code] + list(args), capture_output=True, text=True)
            if r.returncode == 0:
                print(r.stdout.strip())
                return True
            print("PIL a esuat:", r.stderr.strip())
        except FileNotFoundError:
            continue
    return False


_STACK = r"""
import sys
from PIL import Image
BG = (196, 196, 196)
crop = Image.open(sys.argv[1]).convert("RGB")
ren = Image.open(sys.argv[2]).convert("RGBA")
bg = Image.new("RGBA", ren.size, BG + (255,))
ren = Image.alpha_composite(bg, ren).convert("RGB")
b = Image.open(sys.argv[2]).getchannel("A").getbbox()
if b:
    p = 16
    ren = ren.crop((max(b[0]-p, 0), max(b[1]-p, 0), min(b[2]+p, ren.width), min(b[3]+p, ren.height)))
w = int(sys.argv[4])
crop = crop.resize((w, max(1, int(crop.height * w / crop.width))), Image.LANCZOS)
ren = ren.resize((w, max(1, int(ren.height * w / ren.width))), Image.LANCZOS)
img = Image.new("RGB", (w, crop.height + 12 + ren.height), BG)
img.paste(crop, (0, 0))
img.paste(ren, (0, crop.height + 12))
img.save(sys.argv[3])
print("comparatie:", sys.argv[3])
"""

_ROWS = r"""
import sys
from PIL import Image
BG = (196, 196, 196)
out = sys.argv[1]
w = int(sys.argv[2])
cols = int(sys.argv[3])
ims = []
for p in sys.argv[4:]:
    im = Image.open(p).convert("RGBA")
    b = im.getchannel("A").getbbox()
    if b:
        im = im.crop((max(b[0]-16, 0), max(b[1]-16, 0), min(b[2]+16, im.width), min(b[3]+16, im.height)))
    bg = Image.new("RGBA", im.size, BG + (255,))
    im = Image.alpha_composite(bg, im).convert("RGB")
    ims.append(im)
rows = [ims[i:i + cols] for i in range(0, len(ims), cols)]
cell_w = w // cols
out_rows = []
for r in rows:
    rs = [i.resize((cell_w, max(1, int(i.height * cell_w / i.width))), Image.LANCZOS) for i in r]
    h = max(i.height for i in rs)
    row = Image.new("RGB", (w, h), BG)
    for k, i in enumerate(rs):
        row.paste(i, (k * cell_w, (h - i.height) // 2))
    out_rows.append(row)
H = sum(r.height + 8 for r in out_rows)
img = Image.new("RGB", (w, H), BG)
y = 0
for r in out_rows:
    img.paste(r, (0, y))
    y += r.height + 8
img.save(out)
print("montaj:", out)
"""


def compare_all():
    os.makedirs(FID_DIR, exist_ok=True)
    for crop_name, (node, az, el) in COMPARE.items():
        crop = _find_crop(crop_name)
        if crop is None:
            print("LIPSA decupare:", crop_name)
            continue
        _clear()
        objs = _node(node)
        tmp = os.path.join(FID_DIR, "_render_%s.png" % crop_name)
        _render(objs, tmp, azimuth=az, elevation=el, lens=70.0, margin=1.04,
                res_height=700, aspect=4.4)
        _pil(_STACK, crop, tmp, os.path.join(FID_DIR, crop_name + ".png"), "2000")
        _rm(tmp)


def views_all():
    os.makedirs(FID_DIR, exist_ok=True)
    outs = []
    for node in NODES:
        for az in (-90.0, 0.0, 90.0, 180.0):
            _clear()
            objs = _node(node)
            p = os.path.join(FID_DIR, "_view_%s_%d.png" % (node, int(az)))
            _render(objs, p, azimuth=az, elevation=12.0, lens=70.0, margin=1.05,
                    res_height=600, aspect=2.6)
            outs.append(p)
    _pil(_ROWS, os.path.join(FID_DIR, "carrara_horizon_views.png"), "2400", "4", *outs)
    _rm(*outs)


def lineup_all():
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    objs = []
    x = 0.0
    for node in NODES:
        o = _node(node)
        lo, hi = _bounds(o)
        for m in o:
            m.location.x += x - lo.x
        x += (hi.x - lo.x) + 20.0
        objs += o
    bpy.context.view_layer.update()
    p = os.path.join(FID_DIR, "_lineup_horizon.png")
    _render(objs, p, azimuth=-90.0, elevation=6.0, lens=85.0, margin=1.03,
            res_height=700, aspect=5.0)
    _pil(_ROWS, os.path.join(FID_DIR, "carrara_horizon_lineup.png"), "2400", "1", p)
    _rm(p)


args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--compare" in args:
    compare_all()
if "--views" in args:
    views_all()
if "--lineup" in args:
    lineup_all()
if not args:
    print(__doc__)
