"""coconut_palm.glb + beach_palm_bent.glb — cocotierii insulei.

Referinta: assets/okinawa_inspiration/, randul PALMS AND TREES
(COCONUT_PALM_01 7.0 m, BEACH_PALM_BENT 3.0 m).

Un singur script pentru doua fisiere, si asta e o abatere deliberata de la
"un build per GLB": tot ce e greu aici (frunza pliata in V) e comun, iar doi
palmieri cu frunze construite din doua functii aproape identice ar diverge la
prima corectie de forma. Ce difera intre ei e traseul trunchiului si numarul de
frunze — adica date, nu cod.

DE CE FRUNZA E UN VOLUM, nu un plan: Godot face backface culling, deci un
singur strat de fete dispare cand masina trece pe sub palmier. `Builder.blade`
scoate o lamela turtita cu grosime — se vede din orice unghi. Si de ce e PLIATA
in V din doua jumatati: o frunza plata citeste ca o scandura vopsita verde;
cuta de pe nervura e ce ii da volum la 40 m, unde nu se mai vede nicio frunzulita.

Materiale: trunchiul pe clasa `bark` (UV cubic 1.3 m = scara reala a scanarii
palm_tree_bark, deci inelele de cicatrici cad cat trebuie), coroana pe atlasul
de paleta (TROPICAL_GREEN). Vegetatia NU primeste textura: nicio dala PolyHaven
nu arata a frunzis tropical — cele mai bune candidate erau litiera de padure
(maro) sau iarba, care gradate spre verde ies noroi. Cuta si AO-ul fac treaba.
"""

import math
from mathutils import Vector, Matrix

FROND_THICK = 0.055
FOLD_DEG = 26.0          # cat urca fiecare jumatate de frunza fata de orizontala


def trunk(b, path, radii, slot):
    """Trunchiul + evazarea de la baza (radacinile care ies din nisip).

    STUB-ul vertical de la baza nu e cosmetic. Primul inel al unui
    `taper_sweep` e perpendicular pe TANGENTA, deci pe un trunchi inclinat se
    inclina si el si coboara sub cota 0 cu raza x sin(unghi) — 6.5 cm masurat pe
    palmierul batut de vant, prins de `verify_glb --origin=assembly`. Cu doua
    puncte suprapuse pe verticala la baza, tangenta de start e (0,0,1) si inelul
    iese ORIZONTAL, exact pe sol.
    """
    base = Vector(path[0])
    pts = [base, base + Vector((0, 0, 0.18))] + [Vector(p) for p in path[1:]]
    rs = [radii[0], radii[0] * 0.98] + list(radii[1:])
    b.taper_sweep(pts, rs, slot, segments=8, cap_start=True, cap_end=False)
    # Evazarea porneste de la z=0 EXACT, nu de sub sol: contractul din
    # docs/blender_export.md cere baza la Y=0, iar `verify_glb --origin=assembly`
    # il verifica pe ansamblu. Ingroparea "ca sa nu se vada rostul" pare
    # gratuita, dar muta toata piesa fata de cota pe care o aseaza Godot.
    b.taper_sweep([base, base + Vector((0, 0, 0.45))],
                  [radii[0] * 1.55, radii[0] * 1.02], slot, segments=8)


STATIONS = 9             # cate sectiuni are o jumatate de frunza
W_MAX = 0.30             # latimea unei jumatati la cel mai lat punct
ZIGZAG = 0.66            # cat se stramteaza sectiunile pare (vezi mai jos)


def frond(b, base, azimuth, length, slot, droop=1.0, rise=0.55):
    """O frunza: urca din coroana, se apleaca, cade cu varful.

    `droop` scaleaza cat de tare cade varful — la palmierul batut de vant
    frunzele atarna mult mai mult decat la unul drept.

    ZIMTAREA e trucul care face diferenta intre "frunza de palmier" si "scandura
    verde", si costa ZERO in plus: latimea sectiunilor pare se strange la 66%,
    deci muchia exterioara iese in dinti. Nu sunt frunzulite modelate (ar fi
    insemnat 3 lamele per jumatate, adica de trei ori bugetul pe un asset care
    e deja cel mai scump din lot) — dar silueta pe cer, singura care se vede la
    40 m, e a unei frunze penate.

    Fara bevel pe coroana, ca la cactus: o lamela de 5 cm grosime nu are muchii
    de rotunjit, iar bevel-ul ii tripleaza costul degeaba.
    """
    a = math.radians(azimuth)
    d = Vector((math.cos(a), math.sin(a), 0.0))
    path, widths = [], []
    for i in range(STATIONS):
        t = i / (STATIONS - 1)
        # Cota: urca pana pe la jumatate, apoi cade tot mai repede (t³).
        dz = rise * 4.0 * t * (1.0 - t) - droop * 1.30 * t ** 3
        path.append(Vector(base) + d * (length * t) + Vector((0, 0, dz)))
        if i == STATIONS - 1:
            widths.append(0.0)              # varf ascutit
        else:
            w = max(0.075, W_MAX * math.sin(math.pi * t ** 0.75))
            widths.append(w * (ZIGZAG if i % 2 == 0 else 1.0))
    up_l = Matrix.Rotation(math.radians(FOLD_DEG), 4, d) @ Vector((0, 0, 1))
    up_r = Matrix.Rotation(math.radians(-FOLD_DEG), 4, d) @ Vector((0, 0, 1))
    b.blade(path, widths, FROND_THICK, slot, up=up_l, side_bias=1.0)
    b.blade(path, widths, FROND_THICK, slot, up=up_r, side_bias=-1.0)


def crown(b, base, slot):
    """Bulbul de la baza frunzelor — fara el, frunzele par lipite cu banda."""
    b.rock(base, (0.62, 0.62, 0.52), slot, seed=17, segments=8, rings=2,
           taper=0.5)


def nuts(b, base, count, radius, slot, seed=5):
    """Ciorchinele de nuci de cocos, agatat sub coroana."""
    rnd = _lcg(seed)
    for k in range(count):
        a = 2.0 * math.pi * k / count + rnd() * 0.5
        p = Vector(base) + Vector((math.cos(a) * radius, math.sin(a) * radius,
                                   -0.28 - rnd() * 0.18))
        b.rock(p, (0.30, 0.30, 0.34), slot, seed=seed * 7 + k, segments=6,
               rings=2, taper=0.7)


# --- Datele celor doi palmieri ----------------------------------------------
#
# Trunchiul e o polilinie (x, y, z) plus raza in fiecare punct. Cocotierul are
# o curbura lenta si o coroana la 5.8 m; cel de plaja e indoit de vant, deci
# coroana lui pleaca lateral cu 2.2 m — silueta care rupe verticalele si spune
# "vant dinspre mare" fara niciun efect.
PALMS = {
    "coconut_palm.glb": dict(
        prefix="Palm_",
        trunk_path=[(0.00, 0.00, 0.00), (0.04, 0.02, 1.30), (0.14, 0.06, 2.60),
                    (0.30, 0.12, 3.80), (0.55, 0.20, 5.15), (0.78, 0.28, 6.05)],
        trunk_radii=[0.30, 0.245, 0.215, 0.195, 0.180, 0.170],
        fronds=9, frond_len=2.95, droop=1.0, rise=0.60,
        nut_count=5, nut_radius=0.34,
    ),
    "beach_palm_bent.glb": dict(
        prefix="BentPalm_",
        trunk_path=[(0.00, 0.00, 0.00), (0.16, 0.00, 0.62), (0.52, 0.03, 1.22),
                    (1.02, 0.08, 1.72), (1.62, 0.12, 2.08), (2.20, 0.16, 2.28)],
        trunk_radii=[0.26, 0.225, 0.200, 0.180, 0.163, 0.155],
        fronds=7, frond_len=2.30, droop=1.45, rise=0.42,
        nut_count=3, nut_radius=0.26,
    ),
}

AO_SPEC = dict(samples=28, dist=2.6, gradient="vertical",
               low=0.46, high=1.0, power=0.85, floor=0.15)

for filename, spec in PALMS.items():
    prefix = spec["prefix"]
    clear_built(prefix)
    top = Vector(spec["trunk_path"][-1])
    total_h = top.z + spec["rise"] + 0.55   # coroana + cat urca frunzele

    # Trunchiul: obiect separat, fiindca doar el primeste clasa `bark`.
    bt = Builder()
    trunk(bt, spec["trunk_path"], spec["trunk_radii"], WOOD)
    bark_obj = bt.to_object(prefix + "Bark")

    # Coroana: frunze + bulb + nuci, toate pe atlas (verde si maro din paleta).
    bc = Builder()
    crown(bc, top, TROPICAL_GREEN)
    for k in range(spec["fronds"]):
        # Unghiul de start rupt din 137.5° (unghiul de aur): la o impartire
        # egala, frunzele se aliniaza in perechi opuse si coroana citeste ca o
        # elice, nu ca un palmier.
        az = (k * 137.5) % 360.0
        frond(bc, top, az, spec["frond_len"], TROPICAL_GREEN,
              droop=spec["droop"], rise=spec["rise"])
    nuts(bc, top, spec["nut_count"], spec["nut_radius"], DRY_VEGETATION)
    crown_obj = bc.to_object(prefix + "Fronds")

    built = []
    for obj, bevel in ((bark_obj, 0.035), (crown_obj, 0.0)):
        min_z = min(v[2] for v in obj.bound_box)
        # z_range al ANSAMBLULUI: altfel trunchiul si-ar coace un gradient
        # complet pe 5.8 m, iar coroana inca unul pe 1.5 m, si coroana ar iesi
        # la fel de intunecata la baza ca radacinile.
        stats = finish(obj, bevel=bevel, origin="base_axis",
                       ao=dict(AO_SPEC, z_range=(0.0, total_h)))
        obj.location.z = min_z
        built.append((obj, stats))
    cube_uvs(bark_obj, 1.3)

    total = sum(s["tris"] for _o, s in built)
    for obj, s in built:
        print("  %-18s %4d tris  AO %.2f..%.2f"
              % (obj.name, s["tris"], s["ao_min"], s["ao_max"]))
    objs = [o for o, _s in built]
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
    hi = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
    print("%s  TOTAL %d tris  inaltime %.2f m" % (filename, total, hi - lo))
    print("GLB:  %s (%d B)" % export_glb(objs, filename))
    print("BLEND: %s (%d B)" % save_blend(objs, filename.replace(".glb", ".blend")))
