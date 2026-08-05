"""sabani_boat.glb — barca traditionala okinawana (SABANI_BOAT, 5.0 m).

Referinta: assets/okinawa_inspiration/, randul HAZARD OBJECTS. Sabani e barca de
pescuit din Ryukyu: coca ingusta si adanca, prova si pupa RIDICATE si ascutite,
lemn nevopsit cu o dunga colorata pe bord. Sta esuata pe plaja si in port, si
serveste si ca `hazard_model` tematic (#107) — o barca targ ita peste causeway.

DE CE O FUNCTIE PROPRIE DE COCA si nu `taper_sweep`: taper_sweep face sectiuni
CIRCULARE. O coca are sectiune in V — lata sus la copastie, ascutita jos la
chila — iar diferenta e toata silueta obiectului. Sase puncte per sectiune
(copastie stanga/dreapta, bordaj stanga/dreapta, chila fata/spate) o dau exact,
la 10 sectiuni = 480 de triunghiuri.

Doua piese: `Sabani_Hull` pe clasa `wood` (UV cubic 1.2 m — scandurile de
bordaj) si `Sabani_Trim` pe atlas (dunga vopsita, banchetele, catargul — accente
de culoare pe care o textura de lemn le-ar sterge).
"""

import math
from mathutils import Vector

LENGTH = 5.00
BEAM = 0.98          # latimea maxima, la copastie
DEPTH = 0.60         # de la copastie la chila
RISE = 0.52          # cat urca prova/pupa fata de mijloc


def _section(t):
    """Cotele sectiunii la fractiunea t din lungime (0 = pupa, 1 = prova).

    `half` merge la 0 la capete (barca se ascute), dar nu chiar la 0 — o muchie
    de latime zero da fete degenerate la bevel, exact ca la varful frunzei.
    """
    # Latimea: maxima cam la 55% spre prova, nu la mijloc — asa arata o coca
    # care taie apa, si e diferenta dintre "barca" si "migdala".
    half = BEAM * 0.5 * math.sin(math.pi * (t ** 0.85)) ** 0.75
    half = max(half, 0.035)
    # Chila urca spre capete; copastia urca si mai mult (sheer).
    keel = RISE * 0.62 * (2.0 * t - 1.0) ** 2
    sheer = RISE * (2.0 * t - 1.0) ** 2
    depth = DEPTH * (0.55 + 0.45 * math.sin(math.pi * t ** 0.9))
    return half, keel, sheer, depth


def hull(b, slot, stations=11):
    """Coca: sectiuni in V lipite intre ele.

    Se construieste direct pe `b.bm` fiindca nicio primitiva din dio_lib nu face
    o suprafata riglata intre sectiuni de forma data. Inelul are 6 varfuri, in
    ordine: chila-jos, bordaj stanga, copastie stanga, copastie dreapta,
    bordaj dreapta, inapoi la chila.
    """
    rings = []
    for i in range(stations):
        t = i / float(stations - 1)
        half, keel, sheer, depth = _section(t)
        x = (t - 0.5) * LENGTH
        z_top = sheer + depth
        ring = [
            (x, 0.0, keel),                          # chila
            (x, -half * 0.72, keel + depth * 0.45),  # bordaj stanga
            (x, -half, z_top),                       # copastie stanga
            (x, half, z_top),                        # copastie dreapta
            (x, half * 0.72, keel + depth * 0.45),   # bordaj dreapta
        ]
        rings.append([b.bm.verts.new(p) for p in ring])

    new_verts = [v for r in rings for v in r]
    # Inelul se parcurge CICLIC (%len), deci coca iese un tub inchis. Fata
    # copastie-copastie e puntea: fara ea barca ar fi o coaja deschisa, iar
    # fetele interioare sunt backface si deci culled — s-ar fi vazut peisajul
    # prin barca, aceeasi capcana ca gura shisa.
    m = len(rings[0])
    for lo, hi in zip(rings, rings[1:]):
        for k in range(m):
            j = (k + 1) % m
            b.bm.faces.new((lo[k], lo[j], hi[j], hi[k]))
    # Capacele de la prova si pupa.
    b.bm.faces.new(tuple(reversed(rings[0])))
    b.bm.faces.new(tuple(rings[-1]))
    b._tag(new_verts, slot)


def trim(b):
    """Dunga vopsita pe bord, banchetele si catargul."""
    # Dunga: o bara subtire care urmeaza copastia. Se aproximeaza cu segmente,
    # cate unul pe interval de sectiune.
    stations = 11
    prev = None
    for i in range(stations):
        t = i / float(stations - 1)
        half, keel, sheer, depth = _section(t)
        x = (t - 0.5) * LENGTH
        cur = (x, half, sheer + depth - 0.055)
        if prev is not None:
            for sy in (-1.0, 1.0):
                b.beam((prev[0], prev[1] * sy, prev[2]),
                       (cur[0], cur[1] * sy, cur[2]), (0.05, 0.075), KERB_RED)
        prev = cur
    # Banchetele: trei traverse.
    for t in (0.32, 0.50, 0.68):
        half, keel, sheer, depth = _section(t)
        x = (t - 0.5) * LENGTH
        b.box((x, 0.0, sheer + depth - 0.10), (0.16, half * 1.9, 0.07), WOOD)
    # Catargul culcat pe banchete (sabani navigheaza si cu vela).
    b.taper_sweep([(-LENGTH * 0.34, 0.16, 0.60), (LENGTH * 0.40, 0.16, 0.72)],
                  [0.048, 0.036], WOOD, segments=5)


AO_SPEC = dict(samples=24, dist=2.0, gradient="vertical",
               low=0.50, high=1.0, power=0.8, floor=0.18)

clear_built("Sabani_")
built = []
for name, fill, bevel, uv in (
        ("Sabani_Hull", lambda b: hull(b, WOOD), 0.03, 1.2),
        ("Sabani_Trim", trim, 0.02, None)):
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    min_z = min(v[2] for v in obj.bound_box)
    stats = finish(obj, bevel=bevel, origin="base_axis",
                   ao=dict(AO_SPEC, z_range=(0.0, 1.3)))
    obj.location.z = min_z
    if uv is not None:
        cube_uvs(obj, uv)
    built.append((obj, stats))
    print("  %-14s %4d tris  AO %.2f..%.2f"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"]))

objs = [o for o, _s in built]
bpy.context.view_layer.update()
lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
hi = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
d = objs[0].dimensions
print("sabani_boat.glb  TOTAL %d tris  %.2f m lungime, %.2f m inaltime"
      % (sum(s["tris"] for _o, s in built), d.x, hi - lo))
print("GLB:  %s (%d B)" % export_glb(objs, "sabani_boat.glb"))
print("BLEND: %s (%d B)" % save_blend(objs, "sabani_boat.blend"))
