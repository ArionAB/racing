"""Stromboli — interiorul craterului (brief docs/asset_briefs/crater_bowl.md).

  CraterBowl   stromboli/structures/crater_bowl.glb
               Crater_Bowl / Crater_Vents

E primul asset al pistei fiindca e SINGURUL lucru pe care camera il vede cand
masina trece pe buza (Track11, frac 0.47-0.52): chase cam-ul priveste 63 in
JOS, deci interiorul cuvei umple cadrul. Restul insulei se vede in treacat,
craterul se vede fix in momentul in care jucatorul are timp sa se uite.

Doua decizii de constructie merita explicate:

1. **Cuva nu e o revolutie.** `revolve` ar da inele concentrice perfecte, adica
   un tort de nunta — exact ce interzice brief-ul ("terasele NU sunt cercuri
   concentrice curate"). Aici inelele se construiesc direct in bmesh, cu raza
   perturbata determinist PE UNGHI: fiecare terasa isi primeste propriul
   defazaj, deci muchiile lor nu se aliniaza pe aceeasi raza si silueta se
   citeste ca surpare, nu ca strunjire.

2. **Crapaturile nu sunt textura si nu sunt scufundate cu un modificator.**
   Sunt fasii de geometrie proprie, asezate la 4 cm peste podeaua cuvei,
   pornind din buza fiecarei guri. Stau DEASUPRA, nu dedesubt, fiindca in
   Godot primesc materialul emisiv al lavei: o fasie ingropata ar fi taiata de
   z-fighting cu fundul, iar una la nivel ar palpai. 4 cm e sub raza rotii
   (13 cm), deci nu e prag pentru nimeni — dar craterul oricum nu e carosabil.

AO-ul are o exceptie ceruta explicit de brief: crapaturile si buzele
incandescente raman la 1.0. `bake_ao` scrie uniform pe tot mesh-ul, deci
valorile lor se rescriu DUPA, pe indicii de varf retinuti la constructie
(vezi `_lift_ao`). Fara asta, ocluzia din fundul cuvei (~0.45) ar stinge exact
semnalul pentru care exista slotul 30.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_crater_bowl.py
"""

import math

# Cuva se vede de sus, de la 10-20 m: ocluzia conteaza pe distanta MARE (raza
# craterului e 29 m), altfel terasele nu-si arunca umbra una in alta.
# ABATERE DE LA BRIEF, masurata. Brief-ul cere MARBLE_GREY (29, #B8B4AC)
# pentru "podestele prafuite de cenusa". Pe scorie (#55535A) iese la 2.15x
# luminanta ei — adica mai LUMINOS decat lava insasi (1.46x). In randarea de
# control cenusa devenea suprafata cu cel mai mare contrast din cadru si
# tragea ochiul de pe guri, exact de pe semnalul pentru care pista are un slot
# portocaliu. ASPHALT_EDGE (6, #696765) e la 1.23x: se citeste ca praf pe
# roca, ramane sub lava in ierarhia de contrast, si nu consuma un slot nou.
# Daca la integrare craterul iese prea monocrom vazut de sus, calea de
# intoarcere e coverage-ul din `_ash`, nu slotul.
ASH_SLOT = ASPHALT_EDGE

AO_BOWL = dict(samples=32, dist=14.0, gradient="vertical",
               low=0.45, high=1.00, power=1.0, floor=0.30)
AO_VENTS = dict(samples=28, dist=6.0, gradient="vertical",
                low=0.55, high=1.00, power=0.9, floor=0.35)

RIM_R = 29.0          # raza la coronament (diametru 58 m)
SKIRT_R = 32.0        # fusta exterioara, 3 m, tesita in jos
SKIRT_DROP = 1.6      # cat coboara fusta, ca sa se ingroape in teren
FLOOR_R = 9.0         # platou de fund, ~18 m diametru
FLOOR_Z = -13.0
SEG = 40              # segmente pe inel: fatete de ~4.5 m la coronament

# Terasele, de sus in jos: (raza, z, tip_al_BENZII_de_deasupra).
#
# A treia coloana descrie banda dintre inelul PRECEDENT si asta.
#
# Cotele NU sunt alese din ochi, si asta a fost lectia primei versiuni: aveam
# "pereti" care cadeau 2.6 m pe 3.3 m de raza, adica pante de 38 grade, iar
# podestele veneau la 19-24. O diferenta de 16 grade intre "perete" si
# "podest" nu se citeste ca treapta — prima randare a iesit o PALNIE neteda,
# exact ce interzice brief-ul ("cuva, nu palnie"). Vinovatul nu era shading-ul,
# cum parea la prima vedere: era profilul.
#
# Acum cele cinci terase sunt scrise ca perechi (podest, perete) si SCALATE
# aritmetic ca profilul sa cada fix pe tintele din brief — raza 9 m si -13 m
# la fund. Rezultatul masurat: podeste la 6.5-6.8 grade, pereti la 68-71,
# caderi de 1.7-2.6 m. Pasul de 64 de grade dintre ele e ce face treapta
# vizibila de la 10-20 m, unghiul de la care se vede craterul in joc.
TERRACES = [
    (RIM_R,   0.00, None),
    (25.66,  -0.40, "podest"),
    (24.87,  -2.67, "perete"),
    (21.11,  -3.11, "podest"),
    (20.23,  -5.73, "perete"),
    (16.99,  -6.10, "podest"),
    (16.26,  -8.19, "perete"),
    (13.23,  -8.55, "podest"),
    (12.39, -10.95, "perete"),
    ( 9.68, -11.27, "podest"),
    (FLOOR_R, -13.00, "perete"),
]


def _jit(seed):
    """LCG determinist -> [0,1). Aceeasi silueta la fiecare rulare."""
    state = [seed & 0x7FFFFFFF]

    def nxt():
        state[0] = (state[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return state[0] / float(0x7FFFFFFF)
    return nxt


def _ring(bm, radius, z, seed, amp, phase, slump=None):
    """Un inel de varfuri cu raza perturbata pe unghi.

    `amp` e amplitudinea perturbatiei ca fractie din raza; `phase` decaleaza
    zgomotul, ca doua terase vecine sa nu-si alinieze umflaturile.
    `slump` = (unghi_centru, latime_rad, adancime) — pana de grohotis care
    impinge inelul spre INTERIOR pe un arc, adica o surpare locala.
    """
    rnd = _jit(seed)
    # o valoare de zgomot per segment, apoi netezita cu vecinii: perturbatie de
    # frecventa JOASA (umflaturi de 8-10 m), nu zimti de un segment
    raw = [rnd() * 2.0 - 1.0 for _ in range(SEG)]
    smooth = [(raw[i - 1] + 2.0 * raw[i] + raw[(i + 1) % SEG]) * 0.25
              for i in range(SEG)]
    verts = []
    for i in range(SEG):
        a = 2.0 * math.pi * i / SEG + phase
        r = radius * (1.0 + amp * smooth[i])
        dz = 0.0
        if slump is not None:
            ca, half, depth = slump
            # distanta unghiulara pana la centrul penei, pe cercul complet
            d = abs((a - ca + math.pi) % (2.0 * math.pi) - math.pi)
            if d < half:
                t = 0.5 + 0.5 * math.cos(math.pi * d / half)  # 1 in centru
                r -= radius * 0.055 * t
                dz = -depth * t
        verts.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z + dz)))
    return verts


def _bridge(bm, lo, hi, slot_layer, slot):
    """Leaga doua inele cu un brau de quad-uri.

    `slot` poate fi un int (tot braul la fel) sau un callable(i) -> slot, ca
    sa se poata rupe banda PE SEGMENT. Vezi `_ash` — cenusa asezata pe inel
    intreg iese tinta de tir.
    """
    pick = slot if callable(slot) else (lambda i: slot)
    faces = []
    for i in range(SEG):
        j = (i + 1) % SEG
        f = bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        f[slot_layer] = pick(i)
        faces.append(f)
    return faces


def _ash(idx, coverage):
    """Alege cenusa/scorie pe SEGMENT, in petice continue.

    A doua incercare pe podeste. Prima punea MARBLE_GREY pe toate podestele de
    sus, deci cenusa iesea inel INCHIS: randarea de control arata o tinta de
    tir alb-negru, nu un crater. Cenusa reala se aduna in petice — pe partea
    ferita de vant, in scobituri — deci aici se aleg 2-3 arce continue per
    terasa, cu lungimi si pozitii diferite de la o terasa la alta.

    `coverage` scade cu adancimea: sus se depune si ramane, jos cade material
    proaspat peste ea.
    """
    rnd = _jit(509 + idx * 13)
    on = [False] * SEG
    arcs = 2 if idx % 2 else 3
    for _ in range(arcs):
        start = int(rnd() * SEG)
        span = int(SEG * coverage / arcs * (0.7 + 0.6 * rnd()))
        for k in range(span):
            on[(start + k) % SEG] = True

    def pick(i):
        return ASH_SLOT if on[i] else VOLCANIC_BLACK
    return pick


def build_crater():
    clear_built()
    bm = bmesh.new()
    slot_layer = bm.faces.layers.int.new("slot")

    # --- fusta exterioara ---------------------------------------------------
    # Se termina SUB zero si tesita in jos: la integrare craterul intra intr-o
    # gaura sapata in teren (custom_ravines[0]), iar fusta ascunde imbinarea.
    # Fara ea, coronamentul ar fi o muchie de tabla taiata deasupra reliefului.
    skirt = _ring(bm, SKIRT_R, -SKIRT_DROP, seed=17, amp=0.035, phase=0.4)
    rim = _ring(bm, RIM_R, 0.0, seed=23, amp=0.030, phase=0.0)
    _bridge(bm, skirt, rim, slot_layer, VOLCANIC_BLACK)

    # --- terasele interioare ------------------------------------------------
    # Doua pene de grohotis care taie peste mai multe terase (brief: 2-3).
    # Acelasi unghi pe terase consecutive = o limba continua de surpare, nu
    # gropi independente.
    slump_a = (math.radians(35.0), math.radians(28.0), 0.0)
    slump_b = (math.radians(212.0), math.radians(22.0), 0.0)

    prev = rim
    ao_free = []          # varfuri care NU primesc intunecare suplimentara
    for idx, (radius, z, kind) in enumerate(TERRACES[1:], start=1):
        # Defazaj ALTERNANT, nu progresiv. Prima versiune folosea 0.37*idx,
        # adica fiecare inel rotit putin mai mult decat cel de deasupra — ceea
        # ce inseamna, geometric, o SPIRALA: in randarea de sus craterul iesea
        # un melc, nu terase. Doua valori care se schimba intre ele rup
        # alinierea radiala (scopul initial) fara sa introduca sens de rotatie.
        phase = 0.0 if idx % 2 == 0 else 0.41
        seed = 31 + idx * 7
        amp = 0.030 + 0.006 * idx      # mai neregulat pe masura ce coboara

        # Penele de grohotis: doua limbi care taie fiecare peste doua terase
        # (brief: "2-3 pene care taie peste doua terase"). Indicii sunt pe
        # tabelul de 10 benzi — pana A prinde terasele 1-2, pana B terasa 4.
        sl = None
        if 2 <= idx <= 5:
            sl = (slump_a[0], slump_a[1], 0.45 + 0.10 * idx)
        elif 7 <= idx <= 9:
            sl = (slump_b[0], slump_b[1], 0.40 + 0.08 * idx)

        ring = _ring(bm, radius, z, seed, amp, phase, slump=sl)
        # Peretii alterneaza scorie / fata umbrita (brief: "fetele verticale
        # din umbra ale teraselor, alternativ"), podestele alterneaza cenusa /
        # scorie ca sa nu iasa un inel gri continuu.
        # ROCK_DARK (#67421F) a fost incercat pe peretii din umbra si e
        # GRESIT aici: e maroul de desert al canionului, iar pe un vulcan a
        # iesit noroi ruginiu langa negru. Umbra peretilor o face AO-ul (au
        # 70 de grade panta, deci se auto-ocluzeaza tare), nu un al doilea
        # slot de culoare. Peretii raman scorie curata.
        if kind == "perete":
            slot = VOLCANIC_BLACK
        else:
            # Cenusa in PETICE, nu pe inel intreg (vezi _ash), si PUTINA.
            #
            # A treia calibrare. Peticele largi de MARBLE_GREY (#C8BDA9) langa
            # scorie (#55535A) ies zapada, nu cenusa: sunt cu ~2.5 ori mai
            # luminoase si trag ochiul de pe guri, adica exact de pe semnalul
            # pentru care exista pista. Cenusa ramane doar pe primele doua
            # podeste (unde chiar se depune, la adapost de buza) si acopera
            # sub un sfert din inel. Restul e scorie — intunericul e ce face
            # portocaliul sa se vada.
            slot = _ash(idx, 0.30) if idx <= 3 else VOLCANIC_BLACK
        _bridge(bm, prev, ring, slot_layer, slot)
        prev = ring

    # --- fundul cuvei -------------------------------------------------------
    # Platou neregulat, usor bombat spre centru (lava racita, nu farfurie).
    rnd = _jit(101)
    inner = _ring(bm, FLOOR_R * 0.45, FLOOR_Z + 0.35, seed=97, amp=0.09, phase=1.1)
    _bridge(bm, prev, inner, slot_layer, VOLCANIC_BLACK)
    hub = bm.verts.new((0.0, 0.0, FLOOR_Z + 0.55))
    for i in range(SEG):
        j = (i + 1) % SEG
        f = bm.faces.new((inner[i], inner[j], hub))
        f[slot_layer] = VOLCANIC_BLACK

    me = bpy.data.meshes.new("Crater_Bowl")
    bm.to_mesh(me)
    bm.free()
    bowl = bpy.data.objects.new("Crater_Bowl", me)
    bpy.context.collection.objects.link(bowl)
    return bowl


# Gurile: descentrate pe fundul cuvei, Ø 4 / 3 / 2.5 m (brief).
# (x, y, raza_baza, raza_gura, inaltime, unghi_crapaturi)
VENTS = [
    (-2.6, 1.9, 2.00, 1.25, 2.4, [0.5, 2.3, 4.4]),
    (3.1, -1.4, 1.50, 0.95, 1.9, [1.4, 3.9]),
    (0.4, 3.6, 1.25, 0.80, 1.5, [2.9, 5.5]),
]


def build_vents():
    """Conurile + crapaturile radiale. Piesa separata: in Godot primeste
    materialul de clasa EMISIV al lavei, partajat cu lava_flow si
    volcanic_bomb (un singur material in plus pe toata pista)."""
    b = Builder()
    glow_centers = []     # unde trebuie ca AO-ul sa ramana 1.0

    for (vx, vy, r_base, r_mouth, h, angles) in VENTS:
        base_z = FLOOR_Z + 0.45
        # conul: trunchi, ca sa aiba gura deschisa (brief: "cu gura tesita")
        cone = b.frustum((vx, vy, base_z + h * 0.5), r_base, r_mouth, h,
                         VOLCANIC_BLACK, segments=8)
        # Buza incandescenta e capacul de SUS al conului, re-etichetat — nu un
        # inel de geometrie in plus. Un cilindru subtire in jurul gurii costa
        # 348 de triunghiuri dupa bevel (masurat) pentru un contur pe care
        # capacul il deseneaza oricum; `retag` costa zero. Bugetul de 700 al
        # piesei nu incape trei inele decorative, iar de la 10-20 m diferenta
        # dintre "inel de 16 cm" si "gura plina" nu se vede — ce se vede e
        # PATA portocalie in varful conului, si aia ramane identica.
        b.retag(cone, LAVA_ORANGE, where="up")
        glow_centers.append((vx, vy, base_z + h))

        # crapaturi radiale pe fundul cuvei, plecand din baza conului
        for a in angles:
            length = 3.4 + (r_base * 1.6)
            w = 0.30 + r_base * 0.14      # 0.3-0.6 m, ca in brief
            x0 = vx + math.cos(a) * (r_base * 0.85)
            y0 = vy + math.sin(a) * (r_base * 0.85)
            x1 = vx + math.cos(a) * (r_base * 0.85 + length)
            y1 = vy + math.sin(a) * (r_base * 0.85 + length)
            # fasie plata la 4 cm peste podea (vezi nota din capul fisierului)
            # bevel 0 pe crapaturi: sunt fasii plate lipite de podea, iar
            # tesitura lor nu se vede de la 10 m — dar costa x3.67 (masurat).
            b.beam((x0, y0, FLOOR_Z + 0.42), (x1, y1, FLOOR_Z + 0.30),
                   (w, 0.08), LAVA_ORANGE, up=(0, 0, 1))
            glow_centers.append(((x0 + x1) * 0.5, (y0 + y1) * 0.5, FLOOR_Z + 0.36))

    vents = b.to_object("Crater_Vents")
    return vents, glow_centers


def _lift_ao(obj, centers, radius, value=1.0):
    """Ridica AO-ul la `value` pe varfurile din raza `radius` a centrelor date.

    Brief-ul cere explicit ca buzele si crapaturile sa ramana la 1.0: sunt
    singurul semnal portocaliu al pistei, iar ocluzia din fundul cuvei le-ar
    duce la ~0.45, adica maro. Se ruleaza DUPA finish() (care coace AO-ul),
    altfel bake-ul le-ar suprascrie inapoi.
    """
    me = obj.data
    ca = me.color_attributes.get("AO")
    if ca is None:
        return 0
    r2 = radius * radius
    touched = 0
    for i, v in enumerate(me.vertices):
        for (cx, cy, cz) in centers:
            dx, dy, dz = v.co.x - cx, v.co.y - cy, v.co.z - cz
            if dx * dx + dy * dy + dz * dz <= r2:
                ca.data[i].color = (value, value, value, 1.0)
                touched += 1
                break
    return touched


if __name__ == "__main__":
    bowl = build_crater()
    vents, glow = build_vents()

    # Originea la coronament, centrata in XZ: cuva coboara in -Y de la origine,
    # ca sa se aseze direct la cota drumului de pe buza (brief).
    # `origin="base"` ar aduce FUNDUL la zero — exact invers. Deci se lasa
    # geometria unde e (originea e deja la 0 = coronament) si se cere doar
    # bevel + UV + AO. z_range comun pentru amandoua piesele: gurile stau in
    # fundul cuvei si trebuie sa fie la fel de intunecate ca el, nu sa-si
    # coaca fiecare propriul gradient (vezi bake_ao z_range).
    zr = (FLOOR_Z, 0.0)

    stats = {}
    for obj, ao, bev in ((bowl, AO_BOWL, 0.15), (vents, AO_VENTS, 0.08)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        rng = bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        stats[obj.name] = {"tris": tri_count(obj),
                           "ao": (round(rng[0], 3), round(rng[1], 3))}

    lit = _lift_ao(vents, glow, radius=3.0)

    total = sum(s["tris"] for s in stats.values())
    print("Crater_Bowl : %4d tris  AO %s" % (stats["Crater_Bowl"]["tris"],
                                             stats["Crater_Bowl"]["ao"]))
    print("Crater_Vents: %4d tris  AO %s  (%d varfuri ridicate la 1.0)"
          % (stats["Crater_Vents"]["tris"], stats["Crater_Vents"]["ao"], lit))
    print("TOTAL       : %4d tris  (buget 3100)" % total)

    path, size = export_glb([bowl, vents], "stromboli/structures/crater_bowl.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
