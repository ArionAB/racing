"""pandanus.glb — pandanus / adan (Okinawa, PANDANUS_ADAN, 2.5 m).

Referinta: assets/okinawa_inspiration/, randul PALMS AND TREES. Adanul e tufa
care margineste orice plaja din Okinawa: o fantana de frunze-sabie ridicata pe
RADACINI-PICIOR, cu trunchiul aproape ascuns. Radacinile aeriene sunt semnatura
lui — fara ele iese o iuca oarecare.

Frunzele nu se pliaza in V ca la palmier: sunt lame late si drepte care se
rasucesc si cad in arc. Diferenta de forma e si o diferenta de cost — o singura
lamela per frunza, deci 24 de frunze intra in bugetul a 9 frunze de palmier.

Materiale: `bark` pe trunchi si radacini, atlas (TROPICAL_GREEN) pe frunze.
"""

import math
from mathutils import Vector

TRUNK_H = 1.05
LEAVES = 24
LEAF_LEN = 1.70
LEAF_STATIONS = 7
ROOTS = 7
# Cat urca varful frunzei inainte sa se aplece. Cifra e derivata din COTA
# CERUTA (2.5 m), nu aleasa din ochi: maximul lui `rise*sin(1.45t) - fall*t³`
# cade pe la t = 0.75, deci coroana ajunge la TRUNK_H + ~0.65*rise. Prima
# incercare avea rise 1.15 si planta iesea de 1.66 m — o tufa, nu un adan.
LEAF_RISE = 2.10


def trunk(b, slot):
    b.taper_sweep([(0, 0, 0.0), (0, 0, TRUNK_H * 0.55), (0, 0, TRUNK_H)],
                  [0.26, 0.21, 0.185], slot, segments=8)


def prop_roots(b, slot, seed=13):
    """Radacinile-picior: pleaca de sub coroana si intra oblic in nisip.

    Varful e raza 0 (`taper_sweep` colapseaza inelul), nu un cilindru retezat:
    o radacina cu capac poligonal sclipeste in soare exact acolo unde ar trebui
    sa dispara in nisip.
    """
    rnd = _lcg(seed)
    for k in range(ROOTS):
        a = 2.0 * math.pi * k / ROOTS + rnd() * 0.35
        reach = 0.52 + rnd() * 0.30
        start_z = TRUNK_H * (0.42 + rnd() * 0.34)
        d = Vector((math.cos(a), math.sin(a), 0.0))
        path = [Vector((0, 0, start_z)) + d * 0.10,
                Vector((0, 0, start_z * 0.55)) + d * (reach * 0.55),
                Vector((0, 0, start_z * 0.18)) + d * (reach * 0.92),
                Vector((0, 0, 0.0)) + d * reach]
        b.taper_sweep(path, [0.085, 0.070, 0.055, 0.0], slot, segments=6,
                      cap_start=True)


def leaf(b, azimuth, slot, seed_t=0.0):
    """O sabie: urca aproape vertical, se apleaca peste umar si cade.

    `seed_t` variaza lungimea si cat de tare cade — 24 de frunze identice
    rotite in cerc citesc ca o umbrela, nu ca o tufa.
    """
    a = math.radians(azimuth)
    d = Vector((math.cos(a), math.sin(a), 0.0))
    length = LEAF_LEN * (0.78 + 0.42 * seed_t)
    fall = 1.35 + 0.90 * seed_t
    path, widths = [], []
    for i in range(LEAF_STATIONS):
        t = i / (LEAF_STATIONS - 1)
        # Arc: urca repede (sin), apoi varful cade sub baza coroanei.
        dz = LEAF_RISE * math.sin(t * 1.45) - fall * t ** 3.0
        # Raza creste incet la inceput: frunzele stau stranse in rozeta si abia
        # dupa aia se deschid.
        radial = length * (t ** 1.25)
        path.append(Vector((0, 0, TRUNK_H)) + d * radial + Vector((0, 0, dz)))
        widths.append(0.0 if i == LEAF_STATIONS - 1
                      else max(0.055, 0.115 * math.sin(math.pi * t ** 0.55)))
    b.blade(path, widths, 0.035, slot, up=(0, 0, 1))


AO_SPEC = dict(samples=26, dist=2.2, gradient="vertical",
               low=0.44, high=1.0, power=0.85, floor=0.14)

clear_built("Pandanus_")

bb = Builder()
trunk(bb, WOOD)
prop_roots(bb, WOOD)
bark_obj = bb.to_object("Pandanus_Bark")

bl = Builder()
for k in range(LEAVES):
    az = (k * 137.5) % 360.0
    leaf(bl, az, TROPICAL_GREEN, seed_t=((k * 7) % 5) / 4.0)
leaf_obj = bl.to_object("Pandanus_Leaves")

built = []
for obj, bevel in ((bark_obj, 0.03), (leaf_obj, 0.0)):
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, origin="base_axis",
                   ao=dict(AO_SPEC, z_range=(0.0, 2.5)))
    obj.location.z = min_z
    built.append((obj, stats))
cube_uvs(bark_obj, 1.3)

objs = [o for o, _s in built]
for obj, s in built:
    print("  %-18s %4d tris  AO %.2f..%.2f"
          % (obj.name, s["tris"], s["ao_min"], s["ao_max"]))
bpy.context.view_layer.update()
lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
hi = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
print("pandanus.glb  TOTAL %d tris  inaltime %.2f m"
      % (sum(s["tris"] for _o, s in built), hi - lo))
print("GLB:  %s (%d B)" % export_glb(objs, "pandanus.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "pandanus.blend"))
