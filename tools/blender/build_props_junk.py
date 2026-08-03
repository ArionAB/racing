"""props_junk.glb — butoaie, lazi si cauciucuri, ca obiecte fizice bump-abile.
Pentru #7.

De ce exista fisierul: #7 cere sa transformam "bidoanele / anvelopele / lazile
din decor static" in `RigidBody`. Alea NU EXISTA. Cautate: niciun GLB de butoi,
anvelopa sau lada in assets/models. Singurele din tot proiectul sunt coapte in
`gas_station.glb` (#D1), deci nu pot fi instantiate separat. Issue-ul presupunea
un decor care nu fusese construit niciodata.


CONTRACTUL, citit din cod si nu din brief
------------------------------------------
`scenes/props/road_marker.gd` e tiparul, si e deja `RigidBody3D`. Doua lucruri
ies de acolo, si amandoua schimba ce livrez:

1. Colizorul se MASOARA din model (`Track.model_aabb(model)`), nu se citeste
   dintr-un nod `_col`. Deci proxy-uri de coliziune ar fi geometrie moarta care
   ar si umfla masuratoarea. Nu livrez niciunul — in schimb fiecare forma e
   aleasa sa aiba un AABB STRANS: cilindri si cutii, nimic care iese.

2. Apelantul alege UN nod din GLB si il paseaza gata ales
   (`road_marker.gd:16-18`), fiindca 110 copii identice se citesc ca un gard.
   De aia sunt sase noduri frati, nu un ansamblu.

Toate sase: origine la baza, centrate in XZ, exportate la (0,0,0).

Buget: astea se REPETA, iar repetitia e ce costa — lectia din #B1, unde popicele
faceau 31% din toata pista. De aia sunt tinute lean, spre deosebire de valul 3.
"""

import math
from mathutils import Matrix, Vector

# Cote reale: butoiul de 55 de galoane are 0.59 m diametru si 0.88 m inaltime.
BARREL_R, BARREL_H = 0.30, 0.88
BARREL_SEG = 10
HOOP_OUT = 0.026          # cat ies cercurile peste corp
HOOP_H = 0.085

TYRE_MAJOR, TYRE_MINOR = 0.34, 0.135     # exterior 0.95 m, sectiune 0.27 m
TYRE_SEG = (10, 4)

BEVEL = 0.02
# Prag mare, la fel ca la conducta din #B5: pe geometrie cilindrica fetele
# laterale vecine se intalnesc la 36° (10 laturi), deci un prag de 55° le sare
# si beveleaza doar muchiile de 90° — buzele butoiului, colturile lazii.
BEVEL_ANGLE = 55.0


def barrel(name, r=BARREL_R, h=BARREL_H, dents=()):
    """Butoi: corp + doua cercuri de rostogolire.

    Cercurile sunt frustum-uri scurte de raza usor mai mare, nu `torus`: un torus
    de 10x4 costa 80 de triunghiuri, un frustum 30, si la 0.6 m diametru
    diferenta dintre un tor si un inel drept nu exista.
    """
    b = Builder()
    body = b.frustum(center=(0.0, 0.0, h * 0.5), r_bottom=r, r_top=r, depth=h,
                     slot=RUST, segments=BARREL_SEG)
    for z in (h * 0.24, h * 0.76):
        b.frustum(center=(0.0, 0.0, z), r_bottom=r + HOOP_OUT, r_top=r + HOOP_OUT,
                  depth=HOOP_H, slot=RUST, segments=BARREL_SEG)
    # Capacul, mai inchis: pe un butoi abandonat acolo se aduna apa si rugina.
    # `retag`, deci zero triunghiuri.
    b.retag(body, SAND_SHADOW, where="up")
    # Lovituri: varfuri impinse spre axa. Un butoi perfect cilindric citeste a
    # obiect nou, si astea sunt de aruncat la marginea drumului.
    for (ang, zc, depth) in dents:
        a = math.radians(ang)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        for v in b.bm.verts:
            if abs(v.co.z - zc) < 0.16 and Vector((v.co.x, v.co.y, 0.0)).normalized().dot(d) > 0.82:
                v.co -= d * depth
    return b.to_object(name)


def crate(name, w, d, h, band=True):
    """Lada: cutie plus doua chingi. Nu `corrugate` si nu sipci separate — o lada
    de 0.9 m vazuta cand o lovesti se citeste din proportie si din chingi, iar
    sipcile individuale ar insemna 8 cutii pentru un obiect care se repeta."""
    b = Builder()
    body = b.box(center=(0.0, 0.0, h * 0.5), size=(w, d, h), slot=WOOD)
    if band:
        for z in (h * 0.22, h * 0.78):
            b.box(center=(0.0, 0.0, z), size=(w + 0.03, d + 0.03, 0.07), slot=RUST)
    b.retag(body, SAND_MID, where="up")   # praf pe fata de sus
    return b.to_object(name)


def tyre_ring(b, z, rot_deg=0.0):
    faces = b.torus(center=(0.0, 0.0, z), major_r=TYRE_MAJOR, minor_r=TYRE_MINOR,
                    slot=ASPHALT, major_seg=TYRE_SEG[0], minor_seg=TYRE_SEG[1])
    if rot_deg:
        rot = Matrix.Rotation(math.radians(rot_deg), 3, "Z")
        for v in {v for f in faces for v in f.verts}:
            v.co = rot @ v.co
    return faces


clear_built("Barrel")
clear_built("Crate")
clear_built("Tyre")

objs = []

# Doua butoaie: unul aproape intreg, unul lovit pe o parte. Varietatea conteaza
# la obiecte care se instantiaza in gramezi.
objs.append(barrel("Barrel_A", dents=((35.0, 0.55, 0.045),)))
objs.append(barrel("Barrel_B", r=0.29, h=0.86,
                   dents=((200.0, 0.34, 0.075), (20.0, 0.62, 0.05))))

objs.append(crate("Crate_A", 0.90, 0.70, 0.65))
objs.append(crate("Crate_B", 0.62, 0.55, 0.48, band=False))

# Teanc de trei, rotite intre ele: un teanc perfect aliniat arata turnat, nu
# aruncat. Rotatia costa zero triunghiuri.
bs = Builder()
for k, z in enumerate((TYRE_MINOR, TYRE_MINOR + 0.255, TYRE_MINOR + 0.505)):
    tyre_ring(bs, z, rot_deg=k * 13.0)
objs.append(bs.to_object("TyreStack"))

# Una singura, culcata: pentru cazurile in care un teanc ar fi prea mult.
bt = Builder()
tyre_ring(bt, TYRE_MINOR)
objs.append(bt.to_object("Tyre"))

total = 0
for obj in objs:
    stats = finish(
        obj, bevel=BEVEL, bevel_angle=BEVEL_ANGLE, origin="base",
        ao=dict(samples=24, dist=1.2, gradient="vertical",
                low=0.52, high=1.00, power=1.0, floor=0.14))
    me = obj.data
    ext = [(min(v.co[a] for v in me.vertices), max(v.co[a] for v in me.vertices))
           for a in range(3)]
    total += stats["tris"]
    # Cotele se dau in GODOT (x, y, z) = (x_bl, z_bl, -y_bl): acolo se scriu
    # colizoarele, iar `road_marker.gd:38-40` face exact asta — raza din
    # amprenta, inaltimea din AABB.
    w, dpt, hgt = ext[0][1] - ext[0][0], ext[1][1] - ext[1][0], ext[2][1] - ext[2][0]
    print("%-10s %3d tris | AABB Godot %.3f x %.3f x %.3f m | raza cilindru %.3f | AO %.2f..%.2f"
          % (obj.name, stats["tris"], w, hgt, dpt, max(w, dpt) * 0.5,
             stats["ao_min"], stats["ao_max"]))

print("TOTAL: %d tris pe sase noduri" % total)

for o in objs:
    o.location = (0.0, 0.0, 0.0)
print("GLB:   %s (%d B)" % export_glb(objs, "props_junk.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "props_junk.blend"))
for i, o in enumerate(objs):
    o.location = (i * 1.6, 0.0, 0.0)
