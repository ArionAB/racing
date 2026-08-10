"""Randari de control pentru kitul alpin. Se ruleaza DUPA build-uri, in
aceeasi invocare (scena acumuleaza obiectele intre scripturi):

    blender --background --factory-startup --python tools/blender/run_build.py -- \
        build_alpine_buildings.py ... preview_alpine.py

Fiecare asset se randeaza singur: restul se ascund cu hide_render (shot()
incadreaza doar obiectele date, dar tot ce e vizibil intra in cadru).
"""

import os

exec(compile(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
    "preview.py")).read(), "preview.py", "exec"))

OUT = r"C:\Users\Arion\AppData\Local\Temp\claude\d--GameDev-ignition-spike\225c1a9e-dd9d-4b40-8287-7023861995c4\scratchpad\alpine"
os.makedirs(OUT, exist_ok=True)

GROUPS = {
    "alpine_church": ["AlpineChurch"],
    "mountain_chalet_large": ["MountainChaletLarge"],
    "mountain_chalet_small": ["MountainChaletSmall"],
    "cable_car_station": ["CableCarStation"],
    "cable_car_pylon": ["CableCarPylon"],
    "mountain_tunnel": ["MountainTunnel"],
    "stream_bridge": ["StreamBridge"],
    "jump_kicker": ["JumpKicker"],
    "wooden_fence": ["Fence_A", "Fence_B"],
    "hay_cart": ["HayCart"],
    "timber_sled": ["TimberSled"],
    "cow": ["Cow"],
    "snowplow": ["Snowplow"],
    "hay_bale": ["HayBale"],
    "wood_stack": ["WoodStack"],
    "alpine_signpost": ["AlpineSignpost"],
    "mountain_peak": ["MountainPeak"],
    "alpine_shrub": ["AlpineShrub"],
    "flower_cluster": ["FlowerCluster"],
    "snow_patch": ["SnowPatch"],
}

DRIVER = {"alpine_church", "mountain_chalet_large", "cable_car_station",
          "mountain_tunnel", "cable_car_pylon"}

all_names = {n for names in GROUPS.values() for n in names}

for fname, names in GROUPS.items():
    objs = []
    for o in bpy.data.objects:
        if o.type != "MESH" or o.name.startswith("Preview"):
            continue
        o.hide_render = o.name not in names
        if o.name in names:
            objs.append(o)
    if not objs:
        print("PREVIEW LIPSA: %s (niciun obiect gasit)" % fname)
        continue
    # variantele de gard stau suprapuse la origine — le departam pentru cadru
    if len(objs) > 1:
        for i, o in enumerate(objs):
            o.location = (i * 2.4, 0.0, 0.0)
    shot(objs, os.path.join(OUT, fname + ".png"))
    if fname in DRIVER:
        shot(objs, os.path.join(OUT, fname + "_driver.png"), driver=True)
    if len(objs) > 1:
        for o in objs:
            o.location = (0.0, 0.0, 0.0)
    print("PREVIEW: %s" % fname)

for o in bpy.data.objects:
    if o.type == "MESH":
        o.hide_render = False
print("PREVIEW: gata -> %s" % OUT)
