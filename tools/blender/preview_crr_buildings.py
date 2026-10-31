"""Randari de control pentru satul Colonnata si blocul-semn (grupa crr-e) -- din
GLB-urile EXPORTATE.

Foloseste `preview_carrara.py` neschimbat (exec, fara argumentele lui) si adauga
doar ce cere satul (kit §1.4, §3 crr-e):
  * camera per piesa, pe azimutul decuparii (decuparile caselor A, C si a blocului sunt
    vazute din dreapta-fata, ale bisericii si casei B din stanga-fata);
  * `--village`: biserica si cele trei case ALATURI, la aceeasi scara (siluetele
    trebuie sa difere), plus aceeasi lineup „la distanta de joc": camera la
    150 m, cu FOV-ul vertical al ChaseCamera (68 grade) pe 1080 px, adica cat
    de mare iese satul pe ecran din coborarea G (brief §2: 120-160 m lateral).
    Banda de jos e marita x4 cu NEAREST, ca sa se vada pixelii reali.

    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- preview_crr_buildings.py -- --compare colonnata_church
    ... -- preview_crr_buildings.py -- --views colonnata_house_a
    ... -- preview_crr_buildings.py -- --village
    ... -- preview_crr_buildings.py -- --all          # toate de mai sus, intr-o singura rulare

RANDAREA RULEAZA PE GPU: inainte, `until mkdir D:/GameDev/.render_lock; do sleep 5; done`,
dupa, `rmdir D:/GameDev/.render_lock`.
"""
import os
import sys

_HERE_S = os.path.dirname(os.path.abspath(__file__))
_argv = sys.argv
sys.argv = [_argv[0]]
exec(open(os.path.join(_HERE_S, "preview_carrara.py"), encoding="utf-8").read())
sys.argv = _argv

# azimutul a pune camera la (cos a, sin a); fata bogata e +Y. La 125 se vad +Y
# (in stanga ecranului) si -X (in dreapta); la 55 se vad +X (stanga) si +Y (dreapta).
CRR_E_SPECS = {
    "colonnata_church": dict(azimuth=125.0, elevation=16.0, lens=55.0, margin=1.06),
    "colonnata_house_a": dict(azimuth=55.0, elevation=18.0, lens=55.0, margin=1.06),
    "colonnata_house_b": dict(azimuth=125.0, elevation=18.0, lens=55.0, margin=1.06),
    "colonnata_house_c": dict(azimuth=55.0, elevation=18.0, lens=55.0, margin=1.06),
    "quarry_sign_block": dict(azimuth=55.0, elevation=22.0, lens=55.0, margin=1.08),
}
VILLAGE = ["colonnata_church", "colonnata_house_a", "colonnata_house_b", "colonnata_house_c"]


def compare_e(name, res_height=900):
    os.makedirs(FID_DIR, exist_ok=True)
    crop = _find_crop(name)
    if crop is None:
        print("LIPSA decupare:", name)
        return
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    img = bpy.data.images.load(crop)
    cw, ch = img.size
    bpy.data.images.remove(img)
    tmp = os.path.join(FID_DIR, "_render_" + name + ".png")
    _render(meshes, tmp, res_height=res_height, aspect=max(0.6, min(2.0, cw / float(ch))),
            **CRR_E_SPECS[name])
    out = os.path.join(FID_DIR, name + ".png")
    _compose(["--compare", name, "--crop", crop, "--render", tmp, "--out", out,
              "--height", str(res_height)])
    _rm(tmp)


def views_e(name, res_height=700):
    os.makedirs(FID_DIR, exist_ok=True)
    _clear()
    meshes = _import(name)
    if not meshes:
        return
    outs = []
    for az in (35.0, 125.0, 215.0, 305.0):
        cam = dict(CRR_E_SPECS[name])
        cam["azimuth"] = az
        p = os.path.join(FID_DIR, "_view_%s_%d.png" % (name, int(az)))
        _render(meshes, p, res_height=res_height, aspect=1.3, **cam)
        outs.append(p)
    _compose(["--montage", ",".join(outs), "--out", os.path.join(FID_DIR, name + "_views.png")])
    _rm(*outs)


def _lineup(azimuth, gap=4.0):
    """Importa satul si il insira pe axa orizontala a ecranului (pentru azimutul
    dat), in ordinea VILLAGE, cu `gap` m intre amprentele proiectate."""
    _clear()
    a = math.radians(azimuth)
    right = Vector((-math.sin(a), math.cos(a), 0.0))
    groups = []
    for n in VILLAGE:
        ms = _import(n)
        lo, hi = _bounds(ms)
        # latimea proiectata pe axa ecranului (colturile amprentei)
        proj = [Vector((x, y, 0.0)).dot(right) for x in (lo.x, hi.x) for y in (lo.y, hi.y)]
        groups.append((ms, min(proj), max(proj)))
    s = 0.0
    allm = []
    for ms, p0, p1 in groups:
        off = right * (s - p0)
        for o in ms:
            if o.parent is None:
                o.location = o.location + off
        allm += ms
        s += (p1 - p0) + gap
    bpy.context.view_layer.update()
    return allm


def _render_from(objs, path, cam_loc, target, fov_v_deg, res):
    """Ca `_render`, dar cu camera FIXA (pozitie, tinta, FOV vertical): masura in
    pixeli e cea a jocului, nu „umple cadrul"."""
    scene = bpy.context.scene
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = o not in objs
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        cam = bpy.data.objects.new("PreviewCam", bpy.data.cameras.new("PreviewCam"))
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle_y = math.radians(fov_v_deg)
    cam.data.clip_start = 0.5
    cam.data.clip_end = 3000.0
    cam.location = Vector(cam_loc)
    look = (Vector(target) - cam.location).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    bpy.context.view_layer.update()
    # lumina si lumea: aceleasi ca `_render` (o randare de 4 px ca sa le puna)
    _render(objs, path, azimuth=125.0, elevation=16.0, lens=55.0, margin=1.1, res_height=4, aspect=1.0)
    cam.data.sensor_fit = "VERTICAL"
    cam.data.angle_y = math.radians(fov_v_deg)
    cam.location = Vector(cam_loc)
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def village(azimuth=125.0):
    """Plansa satului: (1) lineup 3/4 la scara comuna, (2) lineup la 150 m cu
    FOV-ul jocului, decupat pe sat si marit x4 NEAREST."""
    os.makedirs(FID_DIR, exist_ok=True)
    objs = _lineup(azimuth)
    p1 = os.path.join(FID_DIR, "_village_3q.png")
    _render(objs, p1, azimuth=azimuth, elevation=14.0, lens=55.0, margin=1.04,
            res_height=800, aspect=2.6)
    lo, hi = _bounds(objs)
    center = (lo + hi) * 0.5
    a = math.radians(azimuth)
    # ochiul soferului: satul e la +15..+22 m peste drum, camera la +10 peste
    # drum -> camera ~7 m SUB baza satului, la 150 m in plan
    d = 150.0
    cam = Vector((center.x + math.cos(a) * d, center.y + math.sin(a) * d, -7.0))
    p2 = os.path.join(FID_DIR, "_village_150.png")
    _render_from(objs, p2, cam, (center.x, center.y, 4.0), 68.0, (1920, 1080))
    out = os.path.join(FID_DIR, "colonnata_village.png")
    script = os.path.join(_HERE_S, "compose_crr_buildings.py")
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script, "--village", p1, p2, "--out", out],
                               capture_output=True, text=True)
            print(r.stdout.strip() or r.stderr.strip())
            if r.returncode == 0:
                break
        except FileNotFoundError:
            continue
    _rm(p1, p2)


_args = _argv[_argv.index("--") + 1:] if "--" in _argv else []
if "--compare" in _args:
    compare_e(_args[_args.index("--compare") + 1])
elif "--views" in _args:
    views_e(_args[_args.index("--views") + 1])
elif "--village" in _args:
    village()
elif "--all" in _args:
    names = _args[_args.index("--all") + 1].split(",") if len(_args) > _args.index("--all") + 1 \
        else list(CRR_E_SPECS)
    for n in names:
        compare_e(n)
        views_e(n)
    if any(n in VILLAGE for n in names):
        village()
else:
    print(__doc__)
