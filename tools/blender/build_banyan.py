"""banyan.glb — gajumaru, banyanul din Okinawa (BANYAN_GAJUMARU, 6.0 m).

Referinta: assets/okinawa_inspiration/, randul PALMS AND TREES. Arborele care
tine tot satul la umbra: trunchi scurt spart in mai multe tulpini, o padure de
RADACINI AERIENE care cad din ramuri, si o coroana lata si joasa.

Radacinile aeriene sunt tot ce distinge un gajumaru de "un copac". Sunt si
ieftine: cate un `taper_sweep` cu 5 laturi si varf colapsat, 40 de triunghiuri
bucata. Coroana e facuta din bulgari suprapusi (`Builder.rock`), nu dintr-o
sfera — o sfera la rezolutia implicita a lui Godot are 4224 de triunghiuri
(nota din CLAUDE.md), un bulgare cu 8 segmente si 3 inele are 64 si arata mai
bine, fiindca silueta iese neregulata.

Materiale: `bark` pe trunchi/ramuri/radacini, atlas pe coroana. Coroana
alterneaza TROPICAL_GREEN si CACTUS_GREEN pe bulgari — variatia de valoare
dintre bulgari e ce impiedica masa verde sa citeasca plat, exact rolul pe care
il joaca `strata_slots` la stanci.
"""

import math
from mathutils import Vector

TRUNK_H = 1.60
STEMS = 4
CANOPY_Z = 4.35
CANOPY_R = 3.35
LUMPS = 11


def trunk(b, slot):
    """Butucul cu contraforti + tulpinile care se despart din el."""
    b.taper_sweep([(0, 0, 0.0), (0, 0, 0.55), (0, 0, TRUNK_H)],
                  [0.72, 0.60, 0.50], slot, segments=9)
    # Contraforti: pinteni verticali lipiti de butuc, semnatura ficusului.
    rnd = _lcg(29)
    for k in range(6):
        a = 2.0 * math.pi * k / 6 + rnd() * 0.3
        d = Vector((math.cos(a), math.sin(a), 0.0))
        # Primele doua puncte au ACELASI xy: inelul de start al unui
        # `taper_sweep` e perpendicular pe tangenta, iar un contrafort care
        # pleaca oblic din prima il inclina si il baga 10 cm sub sol (prins de
        # `verify_glb --origin=assembly`). Cu un stub vertical, baza sta pe cota.
        b.taper_sweep([d * 0.62 + Vector((0, 0, 0.0)),
                       d * 0.62 + Vector((0, 0, 0.16)),
                       d * 0.50 + Vector((0, 0, 0.45)),
                       d * 0.30 + Vector((0, 0, 1.05))],
                      [0.30, 0.28, 0.22, 0.13], slot, segments=6)
    tips = []
    for k in range(STEMS):
        a = 2.0 * math.pi * k / STEMS + 0.4
        d = Vector((math.cos(a), math.sin(a), 0.0))
        tip = d * (CANOPY_R * 0.55) + Vector((0, 0, CANOPY_Z - 0.35))
        b.taper_sweep([Vector((0, 0, TRUNK_H - 0.25)),
                       d * 0.35 + Vector((0, 0, TRUNK_H + 0.75)),
                       d * (CANOPY_R * 0.34) + Vector((0, 0, CANOPY_Z - 1.0)),
                       tip],
                      [0.34, 0.26, 0.19, 0.13], slot, segments=7)
        tips.append(tip)
    return tips


def aerial_roots(b, tips, slot, seed=41):
    """Radacinile care atarna din ramuri pana in pamant (si cateva scurte, care
    inca nu au ajuns — alea vand ca arborele CRESTE)."""
    rnd = _lcg(seed)
    # Cinci radacini per ramura, nu sase: a sasea costa 2000 de triunghiuri pe
    # tur (patru banyani) si nu schimba silueta — ce vinde gajumaru e ca sunt
    # MULTE si de lungimi diferite, nu numarul exact.
    for tip in tips:
        for _k in range(5):
            a = rnd() * 2.0 * math.pi
            r = 0.35 + rnd() * 1.35
            x = tip.x * 0.75 + math.cos(a) * r
            y = tip.y * 0.75 + math.sin(a) * r
            z0 = CANOPY_Z - 0.55 - rnd() * 0.7
            reaches_ground = rnd() < 0.6
            z1 = 0.0 if reaches_ground else z0 * (0.35 + rnd() * 0.3)
            # Usoara deriva laterala: o radacina perfect verticala arata ca o
            # sarma intinsa.
            drift = Vector((math.cos(a) * 0.12, math.sin(a) * 0.12, 0.0))
            path = [Vector((x, y, z0)),
                    Vector((x, y, (z0 + z1) * 0.5)) + drift,
                    Vector((x, y, z1)) + drift * 1.4]
            r0 = 0.062 if reaches_ground else 0.045
            b.taper_sweep(path, [r0, r0 * 0.8, 0.0 if not reaches_ground else r0 * 0.7],
                          slot, segments=5)


def canopy(b, seed=59):
    """Bulgari suprapusi intr-o calota lata si joasa.

    Inaltimea coroanei e mica fata de latime (6 m lat, 2.2 m gros): asa arata un
    gajumaru batran, si tot asa se vede de sub el — masina trece PE SUB coroana,
    deci fata de dedesubt e cea care conteaza.
    """
    rnd = _lcg(seed)
    for k in range(LUMPS):
        # Doua inele de bulgari plus unul in varf: cu un singur inel, coroana
        # arata a coroana de flori, cu gaura in mijloc.
        inner = k % 3 == 0
        a = 2.0 * math.pi * k / LUMPS + rnd() * 0.4
        r = (0.0 if k == 0 else
             CANOPY_R * ((0.28 if inner else 0.58) + rnd() * 0.30))
        z = CANOPY_Z + (0.62 if k == 0 else 0.0) - rnd() * 0.40 \
            - (0.0 if inner else 0.25)
        size = 2.35 - r * 0.22 + rnd() * 0.40
        slot = TROPICAL_GREEN if k % 3 else CACTUS_GREEN
        # `boulder`, nu `rock`: rock construieste inele de la baza in sus cu
        # capac plat, deci un bulgare de frunzis iesea CON — noua corturi de
        # circ pe un trunchi. Elipsoidul inchis e forma corecta pentru o masa
        # care nu sta pe sol.
        b.boulder((math.cos(a) * r, math.sin(a) * r, z),
                  (size, size * 0.92, size * 0.66), slot,
                  seed=seed + k * 13, segments=8, rings=4, deviation=0.17)


AO_SPEC = dict(samples=28, dist=3.2, gradient="vertical",
               low=0.42, high=1.0, power=0.9, floor=0.13)

clear_built("Banyan_")

bb = Builder()
tips = trunk(bb, WOOD)
aerial_roots(bb, tips, WOOD)
bark_obj = bb.to_object("Banyan_Bark")

bc = Builder()
canopy(bc)
canopy_obj = bc.to_object("Banyan_Canopy")

built = []
for obj, bevel in ((bark_obj, 0.04), (canopy_obj, 0.05)):
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, origin="base_axis",
                   ao=dict(AO_SPEC, z_range=(0.0, 6.0)))
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
print("banyan.glb  TOTAL %d tris  inaltime %.2f m"
      % (sum(s["tris"] for _o, s in built), hi - lo))
print("GLB:  %s (%d B)" % export_glb(objs, "banyan.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "banyan.blend"))
