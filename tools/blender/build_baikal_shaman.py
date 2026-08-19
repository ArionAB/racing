"""Baikal — Stanca Samanului + stalpii serge (planşa "Baikal kit", pozitiile 1 si 2).

  ShamanRock   baikal/rocks/shaman_rock.glb    Shaman_Crag_Big / Shaman_Crag_Small / Shaman_Ice
  SergePole    baikal/props/serge_pole.glb     Serge_A / Serge_B / Serge_C (+ panglici)

Stanca Samanului (capul Burhan) e POI-ul de la fractia 0.10 si silueta pe care
o vezi de pe gheata, deci e singura piesa din lot careia ii dam doi "dinti" cu
o SA intre ei: forma reala e recognoscibila exact prin decupajul ala, iar un
bolovan generic ar fi sters identitatea locului.

Marmura: MARBLE_GREY (29), slot nou, cu vene diagonale in atlas. Lichenii sunt
KERB_RED — pete mici pe fetele insorite (+Y), singurul accent cald pe piatra.
Gheata de la baza: ICE_TURQUOISE, un guler jos care leaga stanca de lac.

Panglicile serge folosesc sloturile de MASINA (vezi RIBBON_SLOTS in dio_lib si
nota lunga din scripts/palette.gd): sunt accentele saturate ale pistei si
semnaleaza vantul, care pe Baikal e mecanica, nu ornament.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_shaman.py
"""

import math
from mathutils import Matrix, Vector

AO_ROCK = dict(samples=32, dist=6.0, gradient="vertical",
               low=0.38, high=1.00, power=0.95, floor=0.10)
AO_PROP = dict(samples=24, dist=2.5, gradient="vertical",
               low=0.50, high=1.00, power=0.9, floor=0.15)

# Cele 5 culori de panglica, in ordinea din brief: albastru, alb, galben,
# rosu, verde. Sirul se cicleaza pe stalp si intre stalpi.
RIBBON = RIBBON_SLOTS


# ============================================================ Stanca Samanului
# Doi colti: 22x14x18 m (mare, dinspre lac) si 15x10x12 m (mic), cu o sa intre
# ei. Cotele sunt din brief; distanta dintre centre iese din ele, nu invers —
# coltii trebuie sa se ATINGA la baza (masiv comun) si sa se desparta clar sus.

def build_shaman_rock():
    clear_built()

    # --- coltul mare -------------------------------------------------------
    # Un singur `rock` da un butoi: perturbatia lui e blanda si silueta iese
    # rotunda, cum a aratat prima randare de control. Coltul real e un DINTE
    # inclinat, cu fete late si o muchie de creasta. Il compunem din trei
    # volume care se intrepatrund, cu axe usor diferite — asa apare muchia
    # unde se intersecteaza, gratis, si silueta capata directie.
    #
    # taper mic (0.18-0.26): marmura de Olkhon e masiva. Un taper mare da o
    # movila, iar movila nu se recunoaste ca Stanca Samanului din nicio parte.
    b = Builder()
    b.rock((0.0, 0.0, 0.0), (20.0, 13.0, 18.0), MARBLE_GREY, seed=4021,
                   segments=7, rings=5, taper=0.18, squash=0.80)
    # a doua masa, decalata si mai scunda: taie o fata oblica in prima
    b.rock((3.2, 2.4, -1.0), (13.0, 10.0, 14.5), MARBLE_GREY, seed=1177,
                    segments=7, rings=4, taper=0.30, squash=0.85)
    # un umar jos care ancoreaza dintele in teren
    b.rock((-4.5, -2.0, -0.8), (11.0, 9.0, 7.5), MARBLE_GREY, seed=8802,
                    segments=7, rings=3, taper=0.42, squash=0.9)
    big = b.to_object("Shaman_Crag_Big")

    # --- coltul mic --------------------------------------------------------
    # Asezat pe +X la 17 m — nu 13. La 13 m semi-latimile (10 si 7.5) lasau
    # doar 0.5 m intre mase, deci dupa bevel cei doi colti se lipeau intr-un
    # bloc si SAUA disparea. Saua e insa exact ce face silueta recognoscibila
    # (doi "dinti" cu o crestatura intre ei), asa ca distanta se DERIVA din
    # ea: 17 m intre centre lasa ~5 m de gol la jumatatea inaltimii, iar
    # bazele tot se ating prin umarul de mai jos.
    b = Builder()
    b.rock((17.0, -1.5, 0.0), (13.5, 9.5, 12.0), MARBLE_GREY, seed=778,
                   segments=7, rings=5, taper=0.22, squash=0.86)
    b.rock((19.4, 1.2, -0.6), (8.5, 7.0, 8.0), MARBLE_GREY, seed=5510,
                    segments=7, rings=3, taper=0.38, squash=0.9)
    small = b.to_object("Shaman_Crag_Small")

    # --- gulerul de gheata de la baza --------------------------------------
    # Nu un inel uniform: cinci lobi de inaltimi diferite, altfel citeste ca o
    # sosea turnata in jurul pietrei.
    b = Builder()
    for i, (cx, cy, sx, sy, h) in enumerate((
            (-7.5, -3.0, 9.0, 6.5, 2.2), (1.0, 5.5, 8.0, 5.0, 1.5),
            (8.5, -4.5, 8.5, 6.0, 2.6), (16.0, 4.0, 7.5, 5.5, 1.8),
            (22.0, -3.5, 7.0, 5.0, 1.3))):
        b.rock((cx, cy, -0.5), (sx, sy, h), ICE_TURQUOISE, seed=300 + i * 37,
               segments=7, rings=3, taper=0.55, squash=0.7)
    ice = b.to_object("Shaman_Ice")

    for obj in (big, small, ice):
        finish(obj, bevel=0.10, ao=AO_ROCK, origin=None)
    # Lichenul vine DUPA finish, in vertex colors — vezi _tint_lichen.
    for obj in (big, small):
        _tint_lichen(obj)
    # Origine COMUNA pentru toate trei piesele: fiecare cu originea ei le-ar
    # despartii la instantiere in Godot. Coboram tot grupul la z=0 pastrand XY.
    _drop_group((big, small, ice))

    tris = sum(tri_count(o) for o in (big, small, ice))
    print("ShamanRock: %d tris" % tris)
    export_glb([big, small, ice], "baikal/rocks/shaman_rock.glb")
    save_blend([big, small, ice], "baikal_shaman_rock.blend")
    return big, small, ice


def _tint_lichen(obj, warm=(1.30, 0.72, 0.42)):
    """Licheni portocalii pe marmura, ca TINTA in vertex colors — nu ca slot.

    Doua incercari prin `retag` au esuat inainte de asta, si motivul merita
    scris fiindca priveste orice pata organica pe geometrie low-poly: un slot
    se aplica pe FATA INTREAGA. Fetele stancii au 1-4 m, deci orice criteriu
    per-fata produce dreptunghiuri rosii curate — "stickere", cum s-a vazut in
    a doua randare de control. Nu exista prag care sa repare asta; e o limita a
    mecanismului, nu o alegere de parametri.

    Vertex colors interpoleaza intre varfuri, deci pata are margine MOALE si
    poate acoperi o fractiune de fata. Costa zero triunghiuri si zero
    materiale, exact ca retag — dar da forma organica.

    Multiplicativ peste AO-ul deja copt (aceeasi regula ca `tint_gradient`):
    poate deplasa nuanta marmurii spre caramiziu, nu o poate lumina peste
    valoarea din atlas. De aceea `warm` are r > 1: compenseaza scaderea de pe
    g/b ca pata sa nu iasa doar mai inchisa.
    """
    me = obj.data
    ca = me.color_attributes.get("AO")
    if ca is None:
        return
    # normala per varf: lichenul creste pe fetele expuse la soare (+Y)
    nrm = {}
    for poly in me.polygons:
        for vi in poly.vertices:
            nrm.setdefault(vi, []).append(poly.normal.copy())
    for v in me.vertices:
        ns = nrm.get(v.index)
        if not ns:
            continue
        ny = sum(n.y for n in ns) / len(ns)
        c = v.co
        # trei frecvente necomensurabile: tipar care nu se repeta vizibil
        n = (math.sin(c.x * 0.9 + c.z * 0.5)
             + math.cos(c.y * 0.8 - c.z * 0.65) * 0.8
             + math.sin((c.x + c.y) * 1.4) * 0.6)
        # cerere combinata: fata insorita, sus (sub 4 m e zapada), si in pata
        strength = 0.0
        if ny > 0.15 and c.z > 3.5:
            strength = max(0.0, min(1.0, (n - 0.75) / 0.9))
            strength *= min(1.0, (c.z - 3.5) / 3.0)
        if strength <= 0.0:
            continue
        col = ca.data[v.index].color
        ca.data[v.index].color = (
            col[0] * (1.0 + (warm[0] - 1.0) * strength),
            col[1] * (1.0 + (warm[1] - 1.0) * strength),
            col[2] * (1.0 + (warm[2] - 1.0) * strength),
            1.0)


def _drop_group(objs):
    """Coboara un grup de obiecte astfel incat MINIMUL comun sa cada la z=0.

    finish(origin=None) lasa originile in loc; fara pasul asta fiecare piesa ar
    fi fost centrata separat si s-ar fi imprastiat la instantiere.
    """
    lo = min(min((o.matrix_world @ Vector(c)).z for c in o.bound_box)
             for o in objs)
    for o in objs:
        o.location.z -= lo


# ============================================================ Stalpii serge
# 2.5 m inaltime, diametru 20 cm, trei crestaturi. Trei variante: difera prin
# unghiul de inclinare, numarul si lungimea panglicilor. Un sir de 13 pe
# promontoriu — cu o singura varianta s-ar vedea repetitia de la prima privire.

def build_serge_poles():
    clear_built()
    objs = []
    specs = (
        # (nume, inclinare°, azimut°, inaltime, n_panglici, lungime_max)
        ("Serge_A", 0.0, 0.0, 2.50, 5, 0.90),
        ("Serge_B", 4.5, 35.0, 2.35, 4, 0.75),
        ("Serge_C", -3.0, 200.0, 2.65, 6, 0.85),
    )
    for i, (name, tilt, azim, height, n_rib, rib_len) in enumerate(specs):
        objs.append(_serge(name, tilt, azim, height, n_rib, rib_len,
                           seed=91 + i * 13, x_offset=i * 2.0))

    tris = sum(tri_count(o) for o in objs)
    print("SergePole: %d tris in %d fisiere (%s)"
          % (tris, len(objs), ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    # UN FISIER PE VARIANTA. Cele trei serge stau toate la x=0 in kit, deci
    # nu erau un "rand" ci trei VARIANTE suprapuse, alese cu `keep` — exact
    # cazul in care fisierul separat e mai simplu decat filtrul de noduri.
    files = {
        "Serge_A": "baikal/props/serge_pole_a.glb",
        "Serge_B": "baikal/props/serge_pole_b.glb",
        "Serge_C": "baikal/props/serge_pole_c.glb",
    }
    for o in objs:
        export_glb([o], files[o.name])
    save_blend(objs, "baikal_serge_pole.blend")
    return objs


def _serge(name, tilt_deg, azim_deg, height, n_ribbons, rib_len, seed,
           x_offset):
    b = Builder()
    r = 0.10          # raza stalpului: Ø 20 cm din brief
    x0 = x_offset

    # Trunchiul: usor conic (cioplit din bustean, mai gros la baza) si ingropat
    # 0.15 m sub zero — stalpii sunt batuti in pamant, nu asezati pe el.
    b.frustum((x0, 0.0, height * 0.5 - 0.15), r * 1.15, r * 0.92, height + 0.15,
              WOOD, segments=8)

    # Cele trei crestaturi rituale. Inele de raza mai MICA (taietura in lemn,
    # nu braziera) si INTUNECATE — la 2.5 m inaltime, un inel de 5 cm cu aceeasi
    # culoare ca trunchiul e invizibil din masina; ce se citeste e umbra din
    # santul taiat, deci o dam prin slot, nu prin geometrie fina.
    for k in range(3):
        z = height * (0.50 + k * 0.115)
        b.cylinder((x0, 0.0, z), r * 0.66, 0.13, LOG_DARK, segments=8)

    # Capacul de sus, tesit — capatul plat al unui par cioplit citeste ca teava.
    b.frustum((x0, 0.0, height + 0.045), r * 0.92, r * 0.55, 0.09,
              WOOD, segments=8)

    rand = _lcg(seed)
    # Panglicile: fasii plane (mesh de 2 fete), legate la inaltimi diferite in
    # treimea de sus. Fiecare pleaca radial si CADE — punctul de mijloc e mai
    # jos decat cel de capat ridicat de vant, ca sa se citeasca fluturarea si in
    # imagine statica (shader-ul de vertex-wind vine peste, in Godot).
    for j in range(n_ribbons):
        slot = RIBBON[j % len(RIBBON)]
        a = math.radians(azim_deg + j * (360.0 / n_ribbons) + rand() * 25.0)
        z_tie = height * (0.62 + 0.30 * (j / max(n_ribbons - 1, 1)))
        length = rib_len * (0.72 + rand() * 0.28)
        _ribbon(b, (x0 + r * 0.95 * math.cos(a), r * 0.95 * math.sin(a), z_tie),
                a, length, slot, width=0.16, seed=int(rand() * 9999))

    obj = b.to_object(name)
    # Bevel mic: panglicile au 7.5 cm latime, un bevel de 0.04 le-ar fi mancat.
    finish(obj, bevel=0.012, ao=AO_PROP, origin="base_axis")
    # Stalpul se roteste DUPA finish, ca originea sa ramana la baza, pe axa.
    if abs(tilt_deg) > 1e-6:
        obj.rotation_euler = (math.radians(tilt_deg), 0.0,
                              math.radians(azim_deg * 0.3))
    return obj


def _ribbon(b, tie, azim, length, slot, width, seed):
    """O fasie de panglica: patru segmente inlantuite care se departeaza si cad.

    Construita cu `beam` (care leaga DOUA PUNCTE), nu cu `box` rotit: box se
    roteste in jurul propriului centru, deci un lant de cutii rotite se rupe de
    ancora si segmentele plutesc — exact ce a aratat prima randare de control.
    Cu beam, capatul fiecarui segment E punctul de start al urmatorului, deci
    fasia ramane continua si legata de stalp prin constructie.

    Curbura conteaza: o panglica dreapta citeste ca o scandura. Caderea se
    accelereaza spre capat, iar latimea se subtiaza — asa se citeste textila.
    """
    rand = _lcg(seed)
    p0 = Vector(tie)
    # Directia de fluturare: toate panglicile pistei bat in ACELASI sens
    # (vantul dinspre larg) — brief-ul o cere explicit. Azimutul propriu decide
    # doar de pe ce parte a stalpului pleaca fasia.
    wind = Vector((math.cos(azim), math.sin(azim), 0.0))
    step = length / 4.0
    drop = 0.0
    for k in range(4):
        # cadere accelerata + o unduire mica, ca fasia sa nu fie un arc perfect
        drop += step * (0.14 + k * 0.11) + math.sin(k * 1.9 + rand()) * 0.015
        # deviatie laterala mica: panglica nu sta intr-un plan vertical
        side = Vector((-wind.y, wind.x, 0.0)) * math.sin(k * 1.3) * step * 0.18
        p1 = p0 + wind * step + side - Vector((0.0, 0.0, drop))
        # se subtiaza spre capat: 100% -> 70% din latime
        w = width * (1.0 - 0.06 * k)
        b.beam(p0, p1, (w, 0.018), slot)
        p0 = p1


if __name__ == "__main__":
    build_shaman_rock()
    build_serge_poles()
