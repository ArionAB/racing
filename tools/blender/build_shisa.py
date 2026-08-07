"""shisa_statue.glb + shisa_statue_closed.glb — perechea de lei-caini.

Referinta: assets/okinawa_inspiration/, randul SHISA GUARDIANS
(SHISA_OPEN_MOUTH 1.8 m, SHISA_CLOSED_MOUTH 1.6 m). Shisa stau in perechi la
poarta: cel cu gura deschisa alunga raul, cel cu gura inchisa tine norocul
inauntru. La gura deschisa cavitatea e REALA, cu falca de jos coborata si un
gol intre falci — nu o crestatura pictata.

DOUA FISIERE, nu doua variante intr-unul, si asta e impus de cum incarca Godot
landmark-urile: `Track._build_landmark` instantiaza TOT ce e in GLB la o
singura pozitie, deci doi shisa in acelasi fisier ar sta unul in altul. Ca
pereche adevarata, fiecare primeste un id in `_LANDMARKS` si `_landmark_spots()`
ii aseaza pe aceeasi fractie, pe laturi opuse.

Numele pieselor sunt IDENTICE in ambele fisiere (`Shisa_Base` / `Shisa_Stone` /
`Shisa_Detail`): sunt scene separate, deci nu se ciocnesc, iar cele doua intrari
din `_LANDMARKS` pot folosi acelasi dictionar de clase.

Cum se citeste un shisa de la 20 m, in ordinea importantei: (1) coama de bucle
in jurul capului, (2) postura asezata cu picioarele din fata drepte, (3) gura
deschisa. Bugetul s-a impartit dupa lista asta — buclele de coama costa cat
doua degete modelate si se vad de zece ori mai bine.

Trei piese: corpul pe clasa `concrete` (piatra fin granulata, cioplita),
soclul pe `stone_wall` (zidarie de calcar), si detaliile intunecate (ochi,
gura, colti) pe atlas, fiindca o clasa de material acopera toata piesa si
ochii ar fi iesit din aceeasi piatra ca botul.

Orientare: fata spre +Y in Blender = -Z in Godot (nota de axe din dio_lib).
Buget: ~4600 tris, hero de marginea drumului. E capatul de sus al plajei
de 1000-5000 din style_bible §3 si e platit constient: 30 de bulgari (coama,
mase de corp, coada) inmultiti cu bevel-ul. Alternativa era o coama plata, iar
coama e primul lucru dupa care se recunoaste un shisa.
"""

import math
from mathutils import Vector

PED_TOP = 0.55          # cota capacului soclului
# Scara corpului. 0.86 a fost calibrat pe cei 1.8 m ai variantei cu gura
# deschisa; celei inchise (1.6 m) i se deriva proportional, ca sa nu ajungem cu
# doua seturi de cote scrise de mana care diverg la prima corectie de forma.
S_REF, H_REF = 0.86, 1.81
S = S_REF


def P(x, y, z):
    """Punct in coordonatele corpului (z masurat de la capacul soclului)."""
    return (x * S, y * S, PED_TOP + z * S)


def D(sx, sy, sz):
    return (sx * S, sy * S, sz * S)


def pedestal(b):
    """Soclul in trei trepte. Treptele nu sunt decor: ele fac diferenta dintre
    'statuie pe o cutie' si 'monument', si costa 12 triunghiuri."""
    b.box((0.0, 0.0, 0.09), (1.12, 1.02, 0.18), CORAL_SAND)
    b.box((0.0, 0.0, 0.36), (0.92, 0.84, 0.38), CORAL_SAND)
    b.box((0.0, 0.0, PED_TOP - 0.05), (1.04, 0.94, 0.14), CORAL_SAND)


def body(b, slot, open_mouth=True):
    """Postura asezata, in trei etaje distincte: crupa jos si in spate, piept
    INALT si ingust, cap deasupra umerilor cu un gat vizibil intre ele.

    Prima versiune avea pieptul la fel de lat cat de inalt si capul asezat
    direct pe umeri: iesea un urs. Un leu asezat se citeste din VERTICALA —
    pieptul urca, picioarele din fata cad drept de sub el.
    """
    b.boulder(P(0, -0.28, 0.38), D(0.62, 0.62, 0.62), slot, seed=7,
              segments=8, rings=4, deviation=0.10)
    b.boulder(P(0, 0.10, 0.62), D(0.56, 0.50, 0.70), slot, seed=13,
              segments=8, rings=4, deviation=0.10)
    b.boulder(P(0, 0.06, 0.88), D(0.54, 0.46, 0.34), slot, seed=19,
              segments=8, rings=3, deviation=0.10)
    # Labele din spate, pliate sub crupa.
    for sx in (-1.0, 1.0):
        b.box(P(sx * 0.24, -0.06, 0.10), D(0.24, 0.44, 0.20), slot)
    # Picioarele din fata: drepte, ca la un leu asezat.
    for sx in (-1.0, 1.0):
        b.taper_sweep([P(sx * 0.18, 0.22, 0.70), P(sx * 0.19, 0.27, 0.36),
                       P(sx * 0.19, 0.30, 0.07)],
                      [0.110 * S, 0.095 * S, 0.100 * S], slot, segments=6)
        b.box(P(sx * 0.19, 0.36, 0.06), D(0.25, 0.30, 0.13), slot)
        # Trei degete: doar crestaturile dintre ele se vad, dar fara ele laba e
        # o caramida.
        for k in (-1, 0, 1):
            b.box(P(sx * 0.19 + k * 0.072, 0.48, 0.05), D(0.06, 0.10, 0.10),
                  slot)
    # Gatul: scurt, dar EXISTA. Fara el capul pluteste pe umeri.
    b.taper_sweep([P(0, 0.10, 0.90), P(0, 0.20, 1.12)],
                  [0.175 * S, 0.155 * S], slot, segments=7)
    b.boulder(P(0, 0.26, 1.22), D(0.44, 0.44, 0.40), slot, seed=23,
              segments=8, rings=4, deviation=0.09)
    # Botul: falca de sus si cea de jos. La varianta deschisa raman un gol de
    # 8 cm intre ele — golul E asset-ul. La cea inchisa falca urca si se lipeste,
    # deci botul citeste ca un bloc, exact diferenta dintre cei doi shisa.
    b.box(P(0, 0.46, 1.19), D(0.32, 0.26, 0.15), slot)
    b.box(P(0, 0.43, 1.04 if open_mouth else 1.115), D(0.27, 0.23, 0.11), slot)
    # Nasul si arcadele.
    b.boulder(P(0, 0.56, 1.24), D(0.15, 0.11, 0.11), slot, seed=29,
              segments=6, rings=3, deviation=0.08)
    for sx in (-1.0, 1.0):
        b.box(P(sx * 0.12, 0.42, 1.365), D(0.17, 0.15, 0.08), slot)
        # Urechile: peste coama, altfel le inghite.
        b.boulder(P(sx * 0.21, 0.20, 1.38), D(0.15, 0.10, 0.19), slot,
                  seed=31 + int(sx), segments=6, rings=3, deviation=0.10)


def mane(b, slot, seed=53):
    """Coama: bucle in jurul capului si pe ceafa. Ce face un shisa recunoscut.

    Buclele sunt puse pe o SFERA in jurul capului, dar numai pe emisfera din
    spate si pe laturi — pe fata ar fi acoperit botul, adica exact ce trebuie
    citit.

    Si NU peste crestet: prima versiune lasa inclinarea sa urce pana la +1.05
    din raza, iar coama crestea cu un cap intreg peste cap. Silueta iesea o
    conopida. Intervalul e acum -0.55..+0.40, deci coama incadreaza capul in
    loc sa-l inghita.
    """
    rnd = _lcg(seed)
    head = Vector(P(0, 0.24, 1.20))
    for k in range(9):
        a = math.radians(35.0 + k * 34.0)     # ocoleste fata
        tilt = -0.55 + rnd() * 0.95
        r = 0.30 * S
        p = head + Vector((math.cos(a) * r, math.sin(a) * r * 0.85,
                           tilt * r * 0.95))
        size = (0.20 + rnd() * 0.07) * S
        b.boulder(p, (size, size, size * 0.92), slot, seed=seed + k * 9,
                  segments=6, rings=3, deviation=0.15)
    # Bucle pe ceafa si pe spinare — leaga capul de corp.
    for k in range(4):
        t = k / 3.0
        p = Vector(P(0, 0.06 - t * 0.40, 0.98 - t * 0.12))
        size = (0.23 - t * 0.045) * S
        b.boulder(p + Vector((0, 0, size * 0.35)), (size, size, size * 0.85),
                  slot, seed=seed + 100 + k, segments=6, rings=3,
                  deviation=0.15)


def tail(b, slot, seed=67):
    """Coada rasucita peste crupa, tot din bucle."""
    path = [P(0, -0.46, 0.50), P(0, -0.60, 0.82), P(0, -0.52, 1.10),
            P(0, -0.30, 1.22)]
    b.taper_sweep(path, [0.14 * S, 0.115 * S, 0.095 * S, 0.075 * S], slot,
                  segments=6)
    rnd = _lcg(seed)
    for k, p in enumerate(path[1:]):
        size = (0.22 - k * 0.03 + rnd() * 0.05) * S
        b.boulder((p[0] - 0.06 * S, p[1] - 0.05 * S, p[2] + 0.04 * S),
                  (size, size, size * 0.9), slot, seed=seed + k * 11,
                  segments=6, rings=3, deviation=0.15)


def detail(b, open_mouth=True):
    """Ochii, cavitatea gurii si coltii — pe atlas, nu pe clasa de piatra.

    Cavitatea e o cutie INTUNECATA impinsa intre falci: fara ea, prin gura
    deschisa s-ar vedea spatele capului, care e backface si deci CULLED — adica
    o gaura prin care se vede peisajul. Aceeasi capcana ca fantele dintre
    stancile stivuite.
    """
    if open_mouth:
        b.box(P(0, 0.42, 1.115), D(0.25, 0.21, 0.12), VOLCANIC_BLACK)
    else:
        # Gura inchisa: doar linia dintre falci, o lama subtire intunecata.
        b.box(P(0, 0.47, 1.113), D(0.28, 0.18, 0.022), VOLCANIC_BLACK)
    for sx in (-1.0, 1.0):
        b.boulder(P(sx * 0.128, 0.455, 1.300), D(0.115, 0.095, 0.11),
                  VOLCANIC_BLACK, seed=41 + int(sx), segments=6, rings=3,
                  deviation=0.06)
        # Coltii: doi sus, doi jos, in colturile gurii. Cel cu gura inchisa
        # ii arata doar pe cei de sus, si mai scurti — restul sunt inghititi.
        b.box(P(sx * 0.095, 0.49, 1.125 if open_mouth else 1.098),
              D(0.05, 0.065, 0.08 if open_mouth else 0.045), CORAL_SAND)
        if open_mouth:
            b.box(P(sx * 0.085, 0.46, 1.075), D(0.045, 0.055, 0.07), CORAL_SAND)


AO_SPEC = dict(samples=30, dist=1.8, gradient="vertical",
               low=0.46, high=1.0, power=0.8, floor=0.15)

# (fisier, gura deschisa, inaltime ceruta)
VARIANTS = [
    ("props/shisa_statue.glb", True, 1.80),
    ("props/shisa_statue_closed.glb", False, 1.60),
]

for filename, open_mouth, height in VARIANTS:
    S = S_REF * height / H_REF
    PARTS = [
        ("Shisa_Base", lambda b: pedestal(b), 0.04, 1.4),
        ("Shisa_Stone", lambda b, om=open_mouth: (body(b, CONCRETE, om),
                                                  mane(b, CONCRETE),
                                                  tail(b, CONCRETE)), 0.02, 1.0),
        ("Shisa_Detail", lambda b, om=open_mouth: detail(b, om), 0.02, None),
    ]
    clear_built("Shisa_")
    built = []
    for name, fill, bevel, uv_size in PARTS:
        b = Builder()
        fill(b)
        obj = b.to_object(name)
        min_z = min(v[2] for v in obj.bound_box)
        stats = finish(obj, bevel=bevel, origin="base_axis",
                       ao=dict(AO_SPEC, z_range=(0.0, height)))
        obj.location.z = min_z
        if uv_size is not None:
            cube_uvs(obj, uv_size)
        built.append((obj, stats))
        print("  %-14s %4d tris  AO %.2f..%.2f  uv=%s"
              % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
                 ("cub %.1f m" % uv_size) if uv_size else "atlas"))

    objs = [o for o, _s in built]
    bpy.context.view_layer.update()
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
    hi = max(max((o.matrix_world @ Vector(c)).z for c in o.bound_box) for o in objs)
    print("%s  TOTAL %d tris  inaltime %.2f m (cerut %.1f)"
          % (filename, sum(s["tris"] for _o, s in built), hi - lo, height))
    print("GLB:  %s (%d B)" % export_glb(objs, filename))
    print("BLEND: %s (%d B)" % save_blend(objs, filename.replace(".glb", ".blend")))
