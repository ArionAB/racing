"""lighthouse.glb — farul de la cap (LIGHTHOUSE, 9.0 m).

Referinta: assets/okinawa_inspiration/, randul ROADSIDE. Cel mai inalt reper al
insulei: turn conic cu benzi rosii si albe, galerie cu balustrada, felinar cu
cupola rosie. Rolul lui in pista e de LANDMARK — se vede de pe jumatate de tur
si spune unde esti, deci silueta (conicitatea + galeria care iese in consola)
conteaza mai mult decat orice detaliu.

Patru piese, fiindca benzile alternante nu se pot face altfel: o clasa de
material acopera TOATA piesa pe care e pusa, deci albul si rosul trebuie sa fie
obiecte diferite. Alb -> clasa `plaster`, rosu -> KERB_RED din atlas (accentele
de masina 14-16 sunt interzise in decor), piatra -> `stone_wall`, metalul si
geamul -> atlas.

Buget: hero, o singura instanta pe pista -> tinta 2000-4000 tris.
"""

import math

SEG = 12               # sectiune de 12 laturi: turnul e cilindric si se vede de aproape
BASE_TOP = 0.92
TOWER_TOP = 6.85
GALLERY_Z = 6.95
LANTERN_TOP = 8.05
R_BOTTOM = 0.98
R_TOP = 0.62

# Benzile, ca fractiuni din inaltimea turnului. Alterneaza alb/rosu si NU sunt
# egale: banda alba de jos e cea mai lunga, ca in referinta si ca la farurile
# reale — benzi egale citesc ca un cod de bare.
BANDS = [(0.00, 0.26, False), (0.26, 0.38, True), (0.38, 0.60, False),
         (0.60, 0.72, True), (0.72, 0.90, False), (0.90, 1.00, True)]


def _radius(t):
    """Raza turnului la fractiunea t din inaltime — conicitate liniara."""
    return R_BOTTOM + (R_TOP - R_BOTTOM) * t


def stone(b):
    """Soclul de piatra: doua trepte peste care se ridica turnul."""
    b.frustum((0, 0, 0.18), 1.62, 1.48, 0.36, CORAL_SAND, segments=SEG)
    b.frustum((0, 0, 0.64), 1.34, 1.16, 0.56, CORAL_SAND, segments=SEG)


def _band(b, lo, hi, slot):
    z0 = BASE_TOP + (TOWER_TOP - BASE_TOP) * lo
    z1 = BASE_TOP + (TOWER_TOP - BASE_TOP) * hi
    b.frustum(((0, 0, (z0 + z1) * 0.5)), _radius(lo), _radius(hi), z1 - z0,
              slot, segments=SEG)


def white(b):
    for (lo, hi, is_red) in BANDS:
        if not is_red:
            _band(b, lo, hi, CONCRETE)
    # Galeria: consola care iese din turn. Fara ea farul e un con, si conul nu
    # citeste ca far nici in silueta, nici de aproape.
    b.frustum((0, 0, GALLERY_Z - 0.08), R_TOP + 0.10, R_TOP + 0.44, 0.16,
              CONCRETE, segments=SEG)
    b.frustum((0, 0, GALLERY_Z + 0.04), R_TOP + 0.44, R_TOP + 0.40, 0.10,
              CONCRETE, segments=SEG)


def red(b):
    for (lo, hi, is_red) in BANDS:
        if is_red:
            _band(b, lo, hi, KERB_RED)
    # Cupola felinarului + varful.
    b.frustum((0, 0, LANTERN_TOP + 0.10), R_TOP + 0.14, R_TOP * 0.55, 0.20,
              KERB_RED, segments=SEG)
    b.revolve([(R_TOP * 0.55, 0.0), (R_TOP * 0.42, 0.22),
               (R_TOP * 0.22, 0.40), (0.0, 0.52)],
              KERB_RED, segments=SEG, origin=(0, 0, LANTERN_TOP + 0.20))
    b.cylinder((0, 0, LANTERN_TOP + 0.86), 0.045, 0.40, KERB_RED, segments=6)


def metal(b):
    """Balustrada galeriei, cadrul felinarului si geamul."""
    r = R_TOP + 0.38
    posts = 10
    for k in range(posts):
        a = 2.0 * math.pi * k / posts
        x, y = math.cos(a) * r, math.sin(a) * r
        b.beam((x, y, GALLERY_Z + 0.06), (x, y, GALLERY_Z + 0.62), 0.055,
               PAINTED)
    # Mana curenta: un tor, nu 10 bare drepte care se intalnesc in colturi.
    for dz in (0.60, 0.34):
        b.torus((0, 0, GALLERY_Z + dz), r, 0.035, PAINTED,
                major_seg=posts * 2, minor_seg=4)
    # Geamul felinarului: un cilindru inchis la culoare, cu montanti verticali.
    b.cylinder((0, 0, (GALLERY_Z + 0.10 + LANTERN_TOP) * 0.5), R_TOP * 0.88,
               LANTERN_TOP - GALLERY_Z - 0.10, VOLCANIC_BLACK, segments=SEG)
    for k in range(6):
        a = 2.0 * math.pi * k / 6
        x, y = math.cos(a) * R_TOP * 0.90, math.sin(a) * R_TOP * 0.90
        b.beam((x, y, GALLERY_Z + 0.10), (x, y, LANTERN_TOP), 0.05,
               PAINTED)
    # Usa de la baza turnului, spre fata (+Y in Blender = -Z in Godot).
    b.box((0.0, R_BOTTOM * 0.98, BASE_TOP + 0.78), (0.62, 0.12, 1.56),
          PAINTED)


AO_SPEC = dict(samples=26, dist=2.6, gradient="vertical",
               low=0.52, high=1.0, power=0.7, floor=0.20)

# (nume, functie, bevel, latura cubului de UV sau None = ramane pe atlas)
PARTS = [
    ("Lighthouse_Stone", stone, 0.05, 1.4),
    ("Lighthouse_White", white, 0.04, 1.6),
    ("Lighthouse_Red", red, 0.04, None),
    ("Lighthouse_Metal", metal, 0.02, None),
]

clear_built("Lighthouse_")
built = []
for name, fill, bevel, uv_size in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, origin="base_axis",
                   ao=dict(AO_SPEC, z_range=(0.0, 9.0)))
    obj.location.z = min_z
    if uv_size is not None:
        cube_uvs(obj, uv_size)
    built.append((obj, stats))
    print("  %-18s %4d tris  AO %.2f..%.2f  uv=%s"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             ("cub %.1f m" % uv_size) if uv_size else "atlas"))

objs = [o for o, _s in built]
bpy.context.view_layer.update()
lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
hi = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
print("lighthouse.glb  TOTAL %d tris  inaltime %.2f m"
      % (sum(s["tris"] for _o, s in built), hi - lo))
print("GLB:  %s (%d B)" % export_glb(objs, "buildings/lighthouse.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "lighthouse.blend"))
