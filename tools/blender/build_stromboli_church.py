"""Stromboli — biserica din sat (brief docs/asset_briefs/stromboli_church.md).

  StromboliChurch  stromboli/buildings/stromboli_church.glb
                   Church_Body / Church_Tower / Church_Trim

POI-ul liniei de start: masinile trec pe langa ea la FIECARE tur, la 10-15 m.
Deci ce conteaza e SILUETA contra cerului — frontonul curb si campanilul — nu
detaliul de zidarie. Brief-ul cere explicit sa simplificam fata de plansele de
referinta, care au iesit machete de catedrala; familia e biserica din Khuzhir
(Baikal), adica volume curate.

Trei lucruri de stiut inainte sa umbli la fisier:

1. **Fatada e spre +Y in Blender.** Brief-ul o cere spre -Z, dar aia e cota
   Godot: exportul Y-up roteste axele, si +Y_blender devine -Z_godot. Verificat
   pe route66_sign, care isi construieste scutul pe +Y si trece
   `verify_glb --front=-Z`. Daca o construiesti pe -Y, biserica ajunge cu
   spatele la drum si nimeni nu vede frontonul.

2. **Golurile nu se taie.** Nu avem booleene in pipeline; usa, ferestrele si
   golurile de clopot sunt PANOURI RETRASE (helperul `window` din dio_lib, plus
   panouri simple unde nu trebuie rama). Umbra proprie a retragerii e ce le
   face sa citeasca drept goluri — vezi lectia din mine_portal.md.

3. **Frontonul curb se face din `prism`.** Silueta baroc-mediteraneana (doua
   volute laterale + segment de arc sus) e un contur 2D extrudat, nu un solid
   sculptat. Conturul se esantioneaza o data, in `_gable_outline`.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_stromboli_church.py
"""

import math
from mathutils import Matrix, Vector

# Varul are nevoie de AO ca sa nu iasa carton (brief). `dist` mare: fatada e
# lata de 12 m si frontonul trebuie sa-si arunce umbra pe corp.
AO_LIME = dict(samples=30, dist=6.0, gradient="vertical",
               low=0.70, high=1.00, power=0.9, floor=0.30)
AO_TRIM = dict(samples=24, dist=3.0, gradient="vertical",
               low=0.75, high=1.00, power=0.9, floor=0.35)

BODY_W = 12.0        # pe X
BODY_D = 8.0         # pe Y
BODY_H = 6.0         # pana la streasina/atic
FACADE_Y = BODY_D * 0.5     # planul fatadei, +Y

TOWER_S = 3.0        # 3 x 3 m
TOWER_H = 14.0
# lipit de coltul din dreapta-fatada. "Dreapta" privind fatada dinspre +Y
# inseamna -X: privitorul se uita in directia -Y, deci dreapta lui e -X.
TOWER_X = -(BODY_W * 0.5) + TOWER_S * 0.5
TOWER_Y = FACADE_Y - TOWER_S * 0.5

STEP_H = 0.25
STEPS = 3

LIME = FOAM_WHITE        # var eolian (albul exista deja: nu se duplica slot)
# ABATERE DE LA BRIEF, masurata pe foaia de referinta. Brief-ul cere
# PAINTED_METAL (11, #7692A8) pentru usi/obloane. Pe var (FOAM_WHITE, L=0.941)
# vine la 1.69x contrast, iar in randare usa iesea (136,137,132) langa un zid
# de (141,142,136) — adica INVIZIBILA, o pata alba pe alb.
#
# Usile din panoul 2 al foii de referinta sunt un albastru profund, masurat
# (40,81,112), L=0.292. Cel mai apropiat slot existent e SEA_DEEP (18,
# #2E5F6B): distanta de culoare 16 fata de referinta (PAINTED e la 116) si
# 2.81x contrast fata de var. Nu consuma slot nou, iar albastrul marin e deja
# in paleta pistei — insula e inconjurata de el.
SHUTTER = SEA_DEEP       # albastru profund eolian (vezi nota de mai sus)
VOID = ASPHALT           # cea mai inchisa suprafata: citeste ca gol
TRIM = MARBLE_GREY


def _gable_outline(half_w, base_z, rise, volute_drop=1.1, steps=9):
    """Conturul frontonului baroc: doua volute laterale + arc de cerc sus.

    Returneaza puncte (x, z) in sens trigonometric, gata de `prism`.

    Arcul NU e un semicerc peste toata latimea — ala ar da o bolta de hangar.
    E un segment turtit (raza mai mare decat jumatatea deschiderii), care se
    naste din umerii voluteor. Silueta asta e tot ce trebuie sa se citeasca de
    la 25 m; restul detaliului de pe plansa e zgomot la scara noastra.
    """
    shoulder_x = half_w * 0.58          # unde se termina volutele
    shoulder_z = base_z + rise - volute_drop
    top_z = base_z + rise

    # arc care trece prin (-shoulder_x, shoulder_z), (0, top_z), (shoulder_x, ...)
    # centru pe axa X=0, la z = cz; raza din conditia de a trece prin ambele
    sag = top_z - shoulder_z
    r = (shoulder_x * shoulder_x + sag * sag) / (2.0 * sag)
    cz = top_z - r

    pts = [(-half_w, base_z)]
    # volut stang: sfert de racordare de la umar in jos spre coltul cladirii
    for i in range(1, 4):
        t = i / 4.0
        x = -half_w + (half_w - shoulder_x) * t
        z = base_z + volute_drop * (t ** 1.7) * 0.42
        pts.append((x, z))
    for i in range(steps + 1):
        a = math.pi - (math.pi - 0.0) * 0.0   # placeholder, se calculeaza mai jos
        t = i / float(steps)
        x = -shoulder_x + 2.0 * shoulder_x * t
        z = cz + math.sqrt(max(r * r - x * x, 0.0))
        pts.append((x, z))
    for i in range(3, 0, -1):
        t = i / 4.0
        x = half_w - (half_w - shoulder_x) * t
        z = base_z + volute_drop * (t ** 1.7) * 0.42
        pts.append((x, z))
    pts.append((half_w, base_z))
    return pts


def build_church():
    clear_built()

    # =================================================== corpul + treptele
    b = Builder()

    # Nava. Corpul e o cutie, DAR faţada nu poate fi peretele ei din faţă: uşa
    # trebuie să fie un gol real, iar noi n-avem booleene. Deci cutia se
    # opreşte înainte de planul faţadei, iar faţada se construieşte separat,
    # din trei fâşii care lasă golul uşii între ele.
    nave_d = BODY_D - 0.5           # cutia, fără ultimii 0.5 m
    b.box((0.0, -0.25, BODY_H * 0.5), (BODY_W, nave_d, BODY_H), LIME)

    # aticul din spatele frontonului (acoperis plat, NU sarpanta — brief)
    b.box((0.0, 0.0, BODY_H + 0.18), (BODY_W - 0.5, BODY_D - 0.5, 0.36), LIME)

    # Frontonul curb, pe fatada. Grosime 0.45 m ca sa aiba umbra proprie.
    # `rise` 1.7, nu 2.6: la 2.6 arcul se inalta atat de mult peste umeri incat
    # iese o CAPITA (se vede in prima randare). Frontonul baroc-mediteranean e
    # lat si turtit — miscarea vine din volute, nu din inaltime.
    b.prism(_gable_outline(BODY_W * 0.5, BODY_H, 1.7), 0.45, LIME,
            center=(0.0, FACADE_Y - 0.22, 0.0))

    # treptele: 3 x 0.25 m pe toata fatada, fiecare mai adanca decat cea de sus
    for i in range(STEPS):
        z = STEP_H * (STEPS - i) - STEP_H * 0.5
        depth = 0.9 + 0.55 * i
        b.box((0.0, FACADE_Y + depth * 0.5, z),
              (BODY_W * 0.62 + 0.5 * i, depth, STEP_H), LIME)

    # usa: panou plat retras 0.3 m, cu arc sus. Arcul = un al doilea panou
    # semicircular deasupra dreptunghiului (nu avem gol taiat).
    door_w, door_h = 1.2, 2.2
    door_z = STEP_H * STEPS
    # Faţada: trei fâşii de zid care lasă golul uşii între ele. Grosime 0.5 m,
    # de la nave_d până la planul faţadei.
    fac_t = 0.5
    fac_cy = FACADE_Y - fac_t * 0.5
    side_w = (BODY_W - door_w - 0.36) * 0.5     # 0.36 = jocul ancadramentului
    for dx in (-1, 1):
        b.box((dx * (door_w * 0.5 + 0.18 + side_w * 0.5), fac_cy, BODY_H * 0.5),
              (side_w, fac_t, BODY_H), LIME)
    # buiandrugul peste uşă
    lintel_z = door_z + door_h + 0.10
    b.box((0.0, fac_cy, (lintel_z + BODY_H) * 0.5),
          (door_w + 0.36, fac_t, BODY_H - lintel_z), LIME)
    # pragul de sub uşă (fâşiile laterale coboară la 0, uşa începe la door_z)
    b.box((0.0, fac_cy, door_z * 0.5), (door_w + 0.36, fac_t, door_z), LIME)

    # Panoul întunecat al uşii stă în SPATELE golului, nu în interiorul unei
    # mase: acum are ce să-l lase la vedere.
    b.box((0.0, FACADE_Y - fac_t - 0.06, door_z + door_h * 0.5),
          (door_w, 0.12, door_h), SHUTTER)
    # lunetа de deasupra usii
    b.revolve([(door_w * 0.5, 0.0), (door_w * 0.42, 0.16), (0.0, 0.30)],
              SHUTTER, segments=8,
              origin=(0.0, FACADE_Y - 0.56, door_z + door_h - 0.04))

    # Ferestre: doua pe fiecare latura lunga. FARA rotatie — `window` isi
    # construieste deja geamul subtire pe Y (size = (w-2t, t*0.6, h-2t)), adica
    # exact orientarea de care au nevoie peretii lungi ai navei, care privesc
    # spre +-Y. Prima versiune le rotea cu 90 grade pe Z "ca sa fie pe perete"
    # si le intorcea CU MUCHIA spre privitor: in randare ieseau patru aschii
    # verticale de 8 cm, nu ferestre.
    #
    # Cadrul iese spre +Y prin constructie, deci pe peretele dinspre -Y se
    # roteste cu 180 (nu 90) ca rama sa iasa in AFARA, nu in interiorul navei.
    for sy in (-1, 1):
        for ox in (-2.6, 2.6):
            b.window(center=(ox, sy * (nave_d * 0.5 - 0.10) - 0.25, 3.4),
                     w=0.95, h=1.6, frame_t=0.13, depth=0.34,
                     glass_slot=VOID, frame_slot=LIME,
                     rotation=(None if sy > 0
                               else Matrix.Rotation(math.radians(180), 3, "Z")))

    body = b.to_object("Church_Body")

    # =================================================== campanilul
    b = Builder()
    # Fusul turnului se opreşte SUB registrul de clopote. Registrul e spart în
    # stâlpi ca golurile să fie reale (vezi antetul patch-ului): un bloc plin cu
    # panouri împinse în el nu produce nicio deschidere, doar geometrie ascunsă.
    shaft_h = TOWER_H - 2.3
    b.box((TOWER_X, TOWER_Y, shaft_h * 0.5), (TOWER_S, TOWER_S, shaft_h), LIME)

    # Registrul de clopote: patru stâlpi de colţ + buiandrug, cu goluri REALE
    # între ei. Panoul întunecat stă în spatele golului, la mijlocul turnului.
    bell_z = shaft_h
    bh = TOWER_H - bell_z
    # Stalp 0.95, nu 0.62: la 0.62 deschiderea inghitea 55% din latimea
    # turnului si registrul iesea o CUTIE NEAGRA in varf, nu o clopotnita.
    # Pe foaia de referinta golul e o fanta de cam o treime din latime — cu
    # 0.95 miezul intunecat ajunge la 33%, adica proportia din plansa.
    pier = 0.95                      # latura stalpului de colt
    bw = TOWER_S - 2 * pier          # deschiderea liberă între stâlpi
    # doua pe fatada (+Y), unul lateral (+X)
    openings = [(0.0, 1.0), (0.0, 1.0), (1.0, 0.0)]

    # cei patru stâlpi de colţ
    for sx in (-1, 1):
        for sy in (-1, 1):
            b.box((TOWER_X + sx * (TOWER_S - pier) * 0.5,
                   TOWER_Y + sy * (TOWER_S - pier) * 0.5,
                   bell_z + bh * 0.5), (pier, pier, bh), LIME)
    # miezul întunecat: un bloc mai mic decât deschiderea, în axul turnului.
    # Se vede prin toate cele patru goluri şi ţine loc de interior de clopotniţă.
    b.box((TOWER_X, TOWER_Y, bell_z + bh * 0.5),
          (TOWER_S - 2 * pier - 0.10, TOWER_S - 2 * pier - 0.10, bh), VOID)


    # coronament in trepte: doua praguri care ies putin
    b.box((TOWER_X, TOWER_Y, TOWER_H + 0.16), (TOWER_S + 0.5, TOWER_S + 0.5, 0.32), LIME)
    b.box((TOWER_X, TOWER_Y, TOWER_H + 0.52), (TOWER_S - 0.2, TOWER_S - 0.2, 0.40), LIME)

    tower = b.to_object("Church_Tower")

    # =================================================== accente
    # Nod separat ca sa poata primi alt slot decat corpul (brief).
    b = Builder()

    # ancadramentul usii: rame plate de 0.15 m
    # Rama sta LANGA gol (montantii la door_w/2 + jumatate de rama), nu peste
    # el, si iese doar 6 cm din fatada: un ancadrament care acopera deschiderea
    # anuleaza tocmai umbra pentru care am sapat-o.
    fy = FACADE_Y + 0.03
    for dx in (-1, 1):
        b.box((dx * (door_w * 0.5 + 0.09), fy, door_z + door_h * 0.5),
              (0.18, 0.12, door_h + 0.34), TRIM)
    b.box((0.0, fy, door_z + door_h + 0.38),
          (door_w + 0.36, 0.12, 0.18), TRIM)

    # Ancadramentele golurilor de clopot NU se modeleaza. Erau 6 cutii = ~264
    # de triunghiuri dupa bevel, adica singura cauza pentru care Church_Trim
    # iesea 646 fata de bugetul de 300. Golurile stau la 12-14 m inaltime si au
    # 0.92 m latime: de la 25 m (distanta din brief) o rama de 18 cm in jurul
    # lor e sub un pixel. Ce citeste la distanta aia e PATA intunecata a
    # golului, si aia ramane. Ancadramentul usii se pastreaza — usa e la
    # nivelul ochiului, langa linia de start.

    # clopotul: bipiramida simpla in golul principal (brief: <= 40 tris)
    bell_x = TOWER_X
    bell_y = TOWER_Y
    b.revolve([(0.30, 0.0), (0.32, 0.22), (0.22, 0.52), (0.06, 0.62)],
              TRIM, segments=6, origin=(bell_x, bell_y, bell_z + 0.55))

    # crucea de 1 m in varf
    top = TOWER_H + 0.72
    b.box((TOWER_X, TOWER_Y, top + 0.50), (0.09, 0.09, 1.00), TRIM)
    b.box((TOWER_X, TOWER_Y, top + 0.72), (0.44, 0.09, 0.09), TRIM)

    # manerul usii
    b.box((door_w * 0.5 - 0.22, fy + 0.04, door_z + 1.05), (0.10, 0.08, 0.10), TRIM)

    trim = b.to_object("Church_Trim")

    # =================================================== finisare
    # origin=None pe toate trei: sunt un ANSAMBLU cu origine comuna (turnul
    # chiar trebuie sa fie mai inalt decat corpul, iar accentele plutesc prin
    # definitie). Coborarea la sol se face o data, pe tot ansamblul.
    zr = (0.0, TOWER_H + 1.8)
    # Turnul primeste bevel 0.05, nu 0.10: stalpii registrului au 0.95 m latura,
    # iar o tesitura de 10 cm pe fiecare muchie ii rotunjea in CILINDRI (se vede
    # in randarea de control). Bevelul e semnatura de familie, dar pe piesele
    # subtiri se scaleaza cu piesa, nu cu cladirea.
    for obj, ao, bev in ((body, AO_LIME, 0.10), (tower, AO_LIME, 0.05),
                         (trim, AO_TRIM, 0.03)):
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])

    objs = [body, tower, trim]
    _drop_to_zero(objs)
    return objs


def _drop_to_zero(objs):
    """Coboara ANSAMBLUL ca cel mai jos punct sa fie la z=0, centrat in XY.

    Se face pe tot grupul deodata: piesele isi pastreaza pozitiile relative
    (turnul e mai inalt decat corpul, crucea pluteste peste turn), dar
    ansamblul se aseaza pe sol si originea comuna cade in centrul lui.
    """
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    off = Vector(((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, lo.z))
    for o in objs:
        for v in o.data.vertices:
            v.co -= off
        o.data.update()


if __name__ == "__main__":
    objs = build_church()
    total = sum(tri_count(o) for o in objs)
    for o in objs:
        print("%-14s %4d tris" % (o.name, tri_count(o)))
    print("TOTAL          %4d tris  (buget 2300)" % total)
    path, size = export_glb(objs, "stromboli/buildings/stromboli_church.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
