"""Stromboli, kit de sat — pergola pulèra (brief village_kit, piesa 4).

  PergolaPulera  stromboli/buildings/pergola_pulera.glb
                 Pergola_Frame / Pergola_Canopy

4 x 3 x 2.5 m. Stalpii sunt CILINDRICI si GROSI (Ø 0.35) — pulèra eoliana, nu
bare de lemn. Aia e toata identitatea piesei: un pergolat pe patru bare
subtiri arata mediteraneean generic, unul pe patru cilindri albi grosi arata
eolian.

Doua noduri fiindca umbrarul de vita (`Pergola_Canopy`) poate primi la
integrare vertex-wind, iar cadrul nu.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_pergola_pulera.py
"""

import math
from mathutils import Matrix, Vector

AO_FRAME = dict(samples=22, dist=3.0, gradient="vertical",
                low=0.66, high=1.00, power=0.9, floor=0.34)
AO_LEAF = dict(samples=18, dist=2.0, gradient="vertical",
               low=0.72, high=1.00, power=0.9, floor=0.42)

W, D, H = 4.0, 3.0, 2.5
LIME = FOAM_WHITE
WOOD_S = WOOD
LEAF = TROPICAL_GREEN


if __name__ == "__main__":
    clear_built()

    # --- cadrul: patru pulère + grinzi -------------------------------------
    b = Builder()
    px, py = W * 0.5 - 0.3, D * 0.5 - 0.3
    for sx in (-1, 1):
        for sy in (-1, 1):
            # Ø 0.35 => raza 0.175. 8 laturi: la 5 m citeste rotund, iar
            # stalpul e prea gros ca 6 laturi sa nu se vada ca hexagon.
            b.cylinder((sx * px, sy * py, H * 0.5), 0.175, H, LIME, segments=8)
    # grinzile lungi, peste stalpi
    for sy in (-1, 1):
        b.box((0.0, sy * py, H + 0.09), (W - 0.2, 0.16, 0.18), WOOD_S)
    # traverse
    for gx in (-1.15, 0.0, 1.15):
        b.box((gx, 0.0, H + 0.25), (0.13, D - 0.2, 0.13), WOOD_S)
    frame = b.to_object("Pergola_Frame")

    # --- umbrarul de vita ---------------------------------------------------
    # Trei placi verzi neregulate peste grinzi, la inaltimi usor diferite.
    # NU e frunzis modelat: brief-ul cere "sugerat", iar la 5-20 m ce se vede e
    # pata verde care rupe soarele, nu frunza.
    b = Builder()
    st = [7]

    def rnd():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)

    for k in range(3):
        cx = -1.1 + 1.1 * k + (rnd() - 0.5) * 0.3
        cy = (rnd() - 0.5) * 0.5
        w = 1.5 + rnd() * 0.6
        d = D * 0.72 + rnd() * 0.4
        z = H + 0.34 + rnd() * 0.06
        # placa usor rotita, ca sa nu iasa trei dreptunghiuri aliniate
        rot = Matrix.Rotation((rnd() - 0.5) * 0.35, 3, "Z")
        b.box((cx, cy, z), (w, d, 0.09), LEAF, rotation=rot)
    canopy = b.to_object("Pergola_Canopy")

    zr = (0.0, H + 0.5)
    total = 0
    for obj, ao, bev in ((frame, AO_FRAME, 0.04), (canopy, AO_LEAF, 0.03)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        print("%-16s %4d tris" % (obj.name, tri_count(obj)))
        total += tri_count(obj)
    print("TOTAL            %4d tris  (buget 450)" % total)
    path, size = export_glb([frame, canopy],
                            "stromboli/buildings/pergola_pulera.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
