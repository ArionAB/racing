"""chevron_sign.glb — semne chevron de viraj, comunicare de gameplay.
Brief: docs/asset_briefs/chevron_sign.md

Trei variante, copii directi ai radacinii, exportate la origine:
  Chevron_A  triplu, lat (2.4 m), pentru virajele stranse
  Chevron_B  simplu, patrat, pentru virajele medii
  Chevron_C  geometria lui B, inclinat ca dupa un impact

TOATE arata spre stanga — dreapta se obtine in engine cu scale.x = -1.
Fata cu chevronele se orienteaza spre +Y in Blender (= -Z in Godot).

Chevronele NU sunt fete decupate in panou (brieful §3 cerea inset, dar dio_lib
n-are taiere in fata existenta): sunt prisme subtiri PE JUMATATE INGROPATE in
panou, cu fata la 3 cm de a lui. La 70 m distanta cele doua solutii sunt
identice pe ecran; abaterea e documentata in brief §11.
"""

import math
import bmesh
from mathutils import Matrix

# ------------------------------------------------------------------ cote
PANEL_T = 0.06        # grosimea tablei
BAND_T = 0.05         # grosimea prismei de chevron; iese ~3 cm din panou
BAND_PROUD = 0.035    # centrul prismei fata de fata panoului

A_W, A_H = 2.4, 0.8   # panoul triplu
A_ZC = 1.2            # centrul panoului: jos la 0.8, sus la 1.6
A_POST = 0.12         # sectiunea stalpilor

B_W = 0.9             # panoul patrat
B_ZC = 1.15           # jos la 0.7, sus la 1.6
B_POST = 0.14

TILT_X, TILT_Y, TILT_Z = 10.0, 7.0, 8.0   # Chevron_C


def tilt(builder, deg, axis):
    rot = Matrix.Rotation(math.radians(deg), 3, axis)
    for v in builder.bm.verts:
        v.co = rot @ v.co


def chevron_outline(x_apex, x_end, slope, t):
    """Hexagon concav in planul XZ, centrat vertical pe 0, cu VARFUL la x_apex.

    Varful sta pe +X: Blender +X = Godot +X = STANGA soferului care priveste
    fata semnului (soferul se uita spre +Z Godot, deci dreapta lui e -X).
    Prima versiune avea varful pe -X si sagetile ieseau spre dreapta.

    slope = dz/dx al bratelor; t = grosimea VERTICALA a benzii (cea
    perpendiculara e t*cos(atan(slope))). t trebuie sa ramana mult sub
    inaltimea bratului: la t~z_top golul dintre brate dispare si chevronul
    se citeste ca un triunghi plin (buton de play, nu sageata)."""
    z_top = slope * (x_apex - x_end)
    xi = x_apex - t / slope      # varful interior, unde se intalnesc bratele
    return [(x_apex, 0.0), (x_end, z_top), (x_end, z_top - t),
            (xi, 0.0), (x_end, -(z_top - t)), (x_end, -z_top)]


def add_panel(b, width, height, zc):
    """Tabla: rugina pe spate si muchii, rosu de kerb pe fata."""
    faces = b.box(center=(0.0, 0.0, zc), size=(width, PANEL_T, height), slot=RUST)
    b.retag(faces, KERB_RED, where=lambda c, n: n.y > 0.5)
    return faces


def add_bands(b, centers, zc, x_apex, x_end, slope, t):
    y = PANEL_T * 0.5 + BAND_PROUD - BAND_T * 0.5   # pe jumatate in tabla
    for cx in centers:
        # [::-1]: oglindirea varfului pe +X a inversat sensul conturului, iar
        # recalc_face_normals a intors TOT shell-ul (ramas deschis dupa
        # stergerea capacului) cu fata spre panou — chevrone invizibile in
        # Godot. Inversarea listei reda infasurarea originala, cu fata pe +Y.
        pts = [(cx + x, z) for x, z in chevron_outline(x_apex, x_end, slope, t)][::-1]
        faces = b.prism(pts, BAND_T, CONCRETE, center=(0.0, y + BAND_T * 0.5, zc))
        # Capacul din spate e ingropat in tabla si nu se vede de nicaieri;
        # stergerea lui taie si bevel-ul muchiilor lui — masurat, ~30 de
        # triunghiuri pe chevron.
        for f in faces:
            f.normal_update()
        back = [f for f in faces if f.is_valid and f.normal.y < -0.5]
        bmesh.ops.delete(b.bm, geom=back, context="FACES")


def build_triple():
    b = Builder()
    add_panel(b, A_W, A_H, A_ZC)
    # Trei chevrone la -0.75 / 0 / +0.75; fiecare 0.66 m lat, panta 0.5 (~27°).
    # Panta e data de panou, nu de conventia rutiera: bratul trebuie sa ramana
    # la 7 cm de marginea de sus, altfel bevel-ul muschie banda de rama.
    add_bands(b, (-0.75, 0.0, 0.75), A_ZC, x_apex=0.33, x_end=-0.33,
              slope=0.5, t=0.20)
    # Stalpii urca pana la mijlocul panoului si intra 1 cm in spatele lui, ca
    # bevel-ul sa nu deschida o fanta de lumina intre lemn si tabla.
    for sx in (-0.9, 0.9):
        b.box(center=(sx, -0.08, A_ZC * 0.5), size=(A_POST, A_POST, A_ZC),
              slot=WOOD)
    return b


def build_single():
    b = Builder()
    add_panel(b, B_W, B_W, B_ZC)
    add_bands(b, (0.0,), B_ZC, x_apex=0.30, x_end=-0.30, slope=0.6, t=0.20)
    b.box(center=(0.0, -0.09, B_ZC * 0.5), size=(B_POST, B_POST, B_ZC),
          slot=WOOD)
    return b


clear_built("Chevron")
built = []

built.append(("Chevron_A", build_triple()))
built.append(("Chevron_B", build_single()))

# Chevron_C: acelasi panou, dar lovit. Inclinat pe DOUA axe (lectia din
# marker_post: pe o singura axa, jumatate din unghiurile de camera il prind
# exact din directia inclinarii si pare drept) + rasucit in jurul stalpului.
b = build_single()
tilt(b, TILT_X, "X")
tilt(b, TILT_Y, "Y")
tilt(b, TILT_Z, "Z")
built.append(("Chevron_C", b))

# ------------------------------------------------------------------ finisaj
objs = []
for name, b in built:
    obj = b.to_object(name)
    stats = finish(
        obj,
        bevel=0.02, bevel_angle=30.0,   # clasa "prop" din style_bible §3
        ao=dict(samples=32, dist=1.5, gradient="vertical",
                low=0.55, high=1.00, power=1.0, floor=0.32),
    )
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    half = max(max(xs) - min(xs), max(ys) - min(ys)) * 0.5
    print("%-10s %3d tris | h=%.3f m | jumatate latime=%.3f m | AO %.2f..%.2f"
          % (name, stats["tris"], max(zs) - min(zs), half,
             stats["ao_min"], stats["ao_max"]))
    objs.append(obj)

# Toate trei la origine: Godot le cauta ca fii directi si le aseaza el
# (blender_export.md, sectiunea despre GLB-uri cu variante).
for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "signs/chevron_sign.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "chevron_sign.blend"))
for i, o in enumerate(objs):
    o.location = (i * 3.2, 0.0, 0.0)
