"""Planse de control pentru kitul Jodhpur — randate DIN GLB-urile exportate.

Ca `preview_fiordland.py`: importa fisierele, nu reconstruieste piesele, deci
verifica ce a ajuns in GLB (origine, orientare, AO, sloturi). Cubul implicit
si tot ce nu e in lista primesc `hide_render` (memoria
`blender-preview-cub-implicit`).

Trei moduri (brief §0.1 pasul 3, §2):
  1. planse de grup, cu cutia de referinta 4.0 x 1.8 x 1.5 m in cadru:
         blender --background --factory-startup --python tools/blender/run_build.py \
             -- preview_jodhpur.py -- --group pilot
  2. comparatie decupare <-> randare, per piesa (criteriul de fidelitate,
     brief §0.1): decupare in STANGA, randare a GLB-ului exportat in DREAPTA,
     aceeasi inaltime in pixeli, unghi ~3/4 stanga-fata (azimut 35, elevatie
     18), lumina de zi neutra, fundal #CFCFCF, culoare REALA (atlas_material +
     textura de clasa inmultita cu tenta, doar in preview):
         ... -- preview_jodhpur.py -- --compare ghanta_ghar
  3. planta valului: aduna comparatiile deja randate intr-o singura imagine:
         ... -- preview_jodhpur.py -- --sheet 1

Rulare (headless, fara argumente = randeaza toate grupele existente):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- preview_jodhpur.py
"""

import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

REF_CAR = (4.0, 1.8, 1.5)  # lungime (Y Blender) x latime (X) x inaltime (Z)

# (categorie, piese, step) per val (brief §3). Doar valul 1 (pilotul) exista
# la scrierea asta -- restul se adauga pe masura ce valurile se livreaza.
GROUPS = {
    "pilot": ("buildings", ["ghanta_ghar", "blue_house_a"], 10.0),
    "landmarks": ("structures", ["market_gate", "stepwell_flight_module",
                                 "stepwell_corner", "stepwell_pavilion",
                                 "jaswant_thada"], 12.0),
}

# Tenta de preview per piesa/nod, pentru culoare REALA (brief §0.1 pasul 3,
# TASK C a instantei v2, extinsa in runda 3 dupa critica orbului + sef):
# FLAT hex * AO copt, fara textura de clasa proxy -- vezi `_apply_flat_tint`.
#
# REVIZUIRE runda 3: doar `Tower_Stone`/`House_Wall` aveau tenta declarata --
# restul nodurilor (Clock_Glow, Tower_Glow, House_Trim, House_Rail) cadeau pe
# `atlas_material()` implicit (textura de paleta UV-mapata simplu), care
# randeaza aproape alb/gri neutru pe fetele fara UV real -- exact bug-ul
# semnalat ("cupola/acoperisul ies gri/aproape alb"). ACUM fiecare nod din
# fiecare piesa are o tenta explicita:
#   - piatra turnului (orice nod STONE): #B8703F, gresie portocalie
#   - golurile GLOW pure (Tower_Glow): #2A2A2E, aproape negru -- ziua sunt
#     goluri inchise (brief regula 7), nu trebuie sa fie albe/pale
#   - `Clock_Glow` amesteca DOUA sloturi in acelasi nod (discul pe
#     FOAM_WHITE=22, acele pe VOLCANIC_BLACK=20) -- contract inghetat
#     (brief §1.1), nu se desparte in doua noduri doar pentru preview. Tenta
#     e un DICT {slot: hex}, aplicat per-fata prin `_apply_multi_flat_tint`
#     (recupereaza slotul din UV.x, colapsat pe centrul slotului).
#   - peretele/scara casei (House_Wall, House_Rail -- ambele pe slotul WALL):
#     #8FB0DC, albastru
#   - usa/obloanele (House_Trim, slot WOOD): #6B4A2E, maro lemn cald
COMPARE_SPECS = {
    "ghanta_ghar": {
        "category": "buildings",
        "tints": {
            "Tower_Stone": "#B8703F",
            "Clock_Glow": {FOAM_WHITE: "#F2F2F2", VOLCANIC_BLACK: "#2A2A2E"},
            "Tower_Glow": "#2A2A2E",
        },
    },
    "blue_house_a": {
        "category": "buildings",
        "tints": {
            "House_Wall": "#8FB0DC",
            "House_Rail": "#8FB0DC",
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
        },
    },
    # Val 2b -- reperele (brief §1.3). Tente: gresia portii/fortului aceeasi
    # ca ghanta_ghar (#B8703F, ROCK_LIGHT -> clasa red_sandstone la
    # integrare); gresia roz a fantanii SAND_MID -> clasa rose_sandstone,
    # tenta de comparatie #D4957A (data explicit in brief); marmura
    # cenotafului FOAM_WHITE -> tenta #EEE8DF (data explicit), fetele
    # umbrite MARBLE_GREY -> un gri cald mai inchis, ca sa se citeasca
    # dedesubturile/umbrele fara sa fie negru.
    "market_gate": {
        "category": "structures",
        "tints": {
            "Gate_Stone": "#B8703F",
            "Gate_Doors": {WOOD: "#6B4A2E", VOLCANIC_BLACK: "#2A2A2E"},
            "Gate_Glow": "#2A2A2E",
        },
        # REVIZUIRE runda 2 (respins de sef): fatada (arch_opening implicit)
        # e pe -Y local, gasita cu testul fetelor colorate la azimuturile
        # cardinale (0/90/180/270) -- azimut 270 e frontal DREPT; 250 (20
        # grade in lateral, ca in decupare) arata ambele turnuri, nu doar
        # unul. Pe o piesa de 36x6x17 m, distanta implicita (calculata din
        # latime) aduce camera atat de aproape incat cele doua turnuri au
        # paralaxa mare -- `lens` mai lung (105 mm, fata de 55 mm implicit)
        # comprima perspectiva, iar `margin` marit (1.15) lasa loc turnurilor
        # sa nu iasa din cadru.
        # ESCALADARE OPUS: decuparea e aproape FRONTALA, usor din stanga
        # (se vad fetele stangi ale contrafortilor) si aproape la nivelul
        # ochiului -- 262/7, lens lung. `sun_follow`: soarele fix al uneltei
        # vine din azimutul 35, iar camera portii sta la ~260 -> fata se vedea
        # din UMBRA (culoarea "prea inchisa" a rundei 2 era lumina, nu tenta).
        "camera": {"azimuth": 262.0, "elevation": 7.0, "lens": 110.0, "margin": 1.08},
        "sun_follow": {"offset": -30.0, "tilt": 50.0},
    },
    "stepwell_flight_module": {
        "category": "structures",
        "tints": {"Well_Stone": "#D4957A"},
        # fatada (fata cu treptele in relief) e pe +Y local, gasita cu
        # testul fetelor colorate la azimuturile cardinale -- 90 e frontal
        # drept, 72 (18 grade in lateral) arata usor 3/4, ca in decupare.
        "camera": {"azimuth": 72.0, "elevation": 15.0, "lens": 65.0, "margin": 1.15},
    },
    "stepwell_corner": {
        "category": "structures",
        "tints": {"Well_Stone": "#D4957A"},
    },
    "stepwell_pavilion": {
        "category": "structures",
        "tints": {
            "Well_Stone": "#D4957A",
            "Well_Glow": "#2A2A2E",
        },
        # fatada (zidul de fundal + arcada) e pe +Y -- azimut 90 e frontal
        # drept; 100 (10 grade lateral) arata ambele aripi simetric, ca in
        # decupare, cu lens mai lung ca sa umple cadrul pe o piesa de 20 m.
        "camera": {"azimuth": 100.0, "elevation": 13.0, "lens": 75.0, "margin": 1.25},
    },
    "jaswant_thada": {
        "category": "structures",
        "tints": {
            "Thada_Stone": {FOAM_WHITE: "#EEE8DF", MARBLE_GREY: "#B9B0A2"},
            "Thada_Glow": "#2A2A2E",
        },
        # fatada (scara centrala) e pe +Y -- azimut 90 e frontal drept; 75
        # (15 grade lateral) da 3/4 usor, ca in decupare. Piesa era "tiny in
        # its frame" cu implicitul (margin 1.2, lens 55) -- margin redus +
        # lens usor mai lung o umple mult mai bine.
        "camera": {"azimuth": 75.0, "elevation": 14.0, "lens": 60.0, "margin": 1.05},
    },
    # --- val 2a: cetatea (brief §1.2) -- toate pe gresie STONE (#B8703F),
    # cu exceptia canaturilor (lemn/fier) si tepilor/tunului (fier).
    #
    # REVIZUIRE runda 2 (val 2a respins de sef pe fidelitate): decuparile
    # sunt aproape FRONTALE (fatada principala catre camera, azimut 15-20
    # grade, elevatie ~12 grade), nu 3/4 la 35/18 (implicitul mostenit din
    # pilot, gandit pentru piese aproape patrate ca ghanta_ghar/blue_house_a).
    # Piesele alungite ale cetatii (lungime pe Y, fata pe +X, vezi nota de
    # orientare din build_jodhpur_fort.py) au acum azimut/elevatie proprii,
    # mai aproape de frontal, si margin redus (~1.05) pentru cadrare la
    # ~80% din latimea cadrului (brief: "framing la ~80%").
    # Wall_Stone/Turret_Stone/Bastion_Stone amesteca ACUM doua sloturi
    # (piatra + fantele de tragere STUD, runda 2) -- tenta e DICT, ca la
    # portile de mai sus.
    # ESCALADARE OPUS: decuparea arata un TRONSON de ~3 module intre doua
    # turnuri (brief §1.2, coloana h/l); un modul singur (12 x 14 m) citea ca
    # o placa patrata. `chain`: modulul se importa de 3 ori cap la cap pe Y,
    # cu `fort_wall_turret` la ambele capete (iesit in fata cu `ends_dx`),
    # ca in decupare. Vedere aproape frontala (turnurile isi arata ambele
    # fete interioare pe decupare -> camera centrata).
    "fort_wall_segment": {
        "category": "structures",
        "tints": {"Wall_Stone": "#B8703F", "Wall_Glow": "#2A2A2E",
                  "Turret_Stone": {3: "#B8703F", 20: "#2A2A2E"}},
        "azimuth": 4.0, "elevation": 9.0, "margin": 1.04, "lens": 70.0,
        "sun_follow": {"offset": -35.0, "tilt": 50.0},
        "chain": {"n": 3, "step": 12.0, "ends": ("structures", "fort_wall_turret"),
                  "ends_half": 2.25, "ends_dx": 1.0},
    },
    "fort_wall_turret": {
        "category": "structures",
        "tints": {"Turret_Stone": {3: "#B8703F", 20: "#2A2A2E"}},
        "azimuth": 18.0, "elevation": 12.0, "margin": 1.05,
    },
    "fort_bastion": {
        "category": "structures",
        "tints": {"Bastion_Stone": {3: "#B8703F", 20: "#2A2A2E"}},
        "azimuth": 20.0, "elevation": 12.0, "margin": 1.05,
    },
    # Gate_Stone amesteca ACUM doua sloturi (ROCK_LIGHT=3 piatra, +
    # VOLCANIC_BLACK=20 fantele de tragere, runda 2) -- tenta e un DICT,
    # ca la Clock_Glow, altfel `_apply_flat_tint` (un singur hex pe nod)
    # ar picta fantele la fel ca piatra si ar ascunde exact fix-ul de
    # "guri de tragere ies ca relief, nu ca fante intunecate".
    "fort_gate_jai": {
        "category": "structures",
        "tints": {"GateJai_Stone": {3: "#B8703F", 20: "#2A2A2E"}, "GateJai_Doors": "#6B4A2E"},
        "azimuth": 18.0, "elevation": 12.0, "margin": 1.05,
    },
    "fort_gate_fateh": {
        "category": "structures",
        "tints": {"GateFateh_Stone": {3: "#B8703F", 20: "#2A2A2E"}, "GateFateh_Doors": "#6B4A2E"},
        "azimuth": 18.0, "elevation": 12.0, "margin": 1.05,
    },
    "fort_gate_loha": {
        "category": "structures",
        "tints": {"GateLoha_Stone": {3: "#B8703F", 20: "#2A2A2E"}, "GateLoha_Doors": "#4A4A4E"},
        "azimuth": 18.0, "elevation": 12.0, "margin": 1.05,
    },
    "palace_facade_a": {
        "category": "structures",
        "tints": {"Palace_Stone": "#B8703F", "Palace_Glow": "#2A2A2E"},
        "azimuth": 15.0, "elevation": 10.0, "margin": 1.05,
    },
    "palace_facade_b": {
        "category": "structures",
        "tints": {"Palace_Stone": "#B8703F", "Palace_Glow": "#2A2A2E"},
        "azimuth": 15.0, "elevation": 10.0, "margin": 1.05,
    },
    # ESCALADARE OPUS: tentele = culorile REALE din atlas ale sloturilor
    # (masurate pe palette_atlas.png): VOLCANIC_BLACK #56545B (gri inchis, nu
    # negru -- #2A2A2E innegrea teava in preview, nu in joc), WOOD #875F35.
    # Camera din stanga-fata a tevii (teava spre +X, gura in dreapta
    # cadrului, putin spre camera -- se vede gaura gurii, ca in decupare).
    "rampart_cannon": {
        "category": "props",
        "tints": {"Cannon_Metal": "#56545B", "Cannon_Wood": "#875F35"},
        "azimuth": 318.0, "elevation": 13.0, "margin": 1.1, "lens": 60.0,
        "sun_follow": {"offset": -35.0, "tilt": 50.0},
    },
    # --- val 3: orasul albastru (brief §1.4) -- reuseste conventia
    # pilotului (blue_house_a): +X e fatada camerei, casele sunt aproape
    # cubice, deci camera implicita (azimut 35/elevatie 18) ramane
    # neschimbata, ca la ghanta_ghar/blue_house_a. Tente: light #8FB0DC
    # (majoritatea caselor), indigo #4F6FB8 (blue_house_d, haveli_facade --
    # brief §1.4 coloana "tenta in preview"), trim lemn #6B4A2E, glow
    # #2A2A2E, balustrada alba FARA tenta separata de perete (House_Rail
    # foloseste aceeasi tenta ca House_Wall pe casele light) sau neagra
    # (House_Rail=GLOW pe blue_house_d, grilaj de fier per contract).
    # blue_house_b: House_Wall amesteca TREI sloturi (peretele WALL, +
    # rezervorul TANK_DARK=LOG_DARK, + planta CACTUS_GREEN -- fix bug gasit
    # la primul --compare al valului 3: rezervorul si planta apareau
    # albastre, vezi jurnalul in inventar). blue_house_c: doar WALL+
    # TANK_DARK (nu are planta).
    "blue_house_b": {
        "category": "buildings",
        "tints": {
            "House_Wall": {FOAM_WHITE: "#8FB0DC", LOG_DARK: "#2A2A2E", CACTUS_GREEN: "#4C8C3C"},
            # runda 3: House_Rail = balustrade/coame ALBE fara tenta (brief
            # §1.4, "nod separat de perete"), nu albastru
            "House_Rail": "#F2F2F2",
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
        },
        # decuparea: fata +X (stanga) si +Y (dreapta) aproape egale => az ~46
        "camera": {"azimuth": 46.0, "elevation": 16.0, "margin": 1.3, "lens": 90.0},
        "sun_follow": {"offset": -30.0, "tilt": 50.0},
    },
    "blue_house_c": {
        "category": "buildings",
        "tints": {
            "House_Wall": {FOAM_WHITE: "#8FB0DC", LOG_DARK: "#2A2A2E"},
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
        },
        # runda 3: decuparea arata fata cu USA (+Y) frontala si fata +X in
        # fuga (latimi aparente 455/240 px => azimut ~62), privita usor de sus
        "camera": {"azimuth": 62.0, "elevation": 17.0, "margin": 1.35, "lens": 90.0},
        "sun_follow": {"offset": -30.0, "tilt": 50.0},
    },
    "blue_house_d": {
        "category": "buildings",
        "tints": {
            "House_Wall": "#4F6FB8",
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
            # balustrada e GLOW (grilaj negru de fier pe blue_house_d, brief
            # §1.4: "parapet inchis la culoare", contract in cod: rail_faces
            # scrise pe slotul GLOW, nu RAIL_WHITE)
            "House_Rail": "#2A2A2E",
        },
    },
    "blue_house_e": {
        "category": "buildings",
        "tints": {
            "House_Wall": "#8FB0DC",
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
            # runda 3: treptele, parapetul scarii si balustradele sunt ALBE
            # (nod fara tenta), ca pe decupare
            "House_Rail": "#F2F2F2",
        },
        "camera": {"azimuth": 48.0, "elevation": 16.0, "margin": 1.3, "lens": 90.0},
        "sun_follow": {"offset": -30.0, "tilt": 50.0},
    },
    "haveli_facade": {
        "category": "buildings",
        # runda 3: decuparea e albastru DESCHIS (#7896DE pe fata luminata);
        # indigo #4F6FB8 randa "albastru-marin" (verdictul liderului) -> tenta
        # light. Nodurile: perete, usi de lemn (Trim), geamuri GLOW.
        "tints": {
            "House_Wall": "#8FB0DC",
            "House_Trim": "#6B4A2E",
            "House_Glow": "#2A2A2E",
        },
        # fata lata (+Y, 10 m) frontala, latura +X in fuga: latimi aparente
        # 570/200 px => az ~60
        "camera": {"azimuth": 60.0, "elevation": 12.0, "margin": 1.2, "lens": 90.0},
        "sun_follow": {"offset": -30.0, "tilt": 50.0},
    },
    "rooftop_tank": {
        "category": "props",
        "tints": {"Tank_Body": "#2A2A2E"},
    },
    # Clutter_Base amesteca 4 sloturi (placa WALL, rezervor TANK_DARK=
    # LOG_DARK, oale WOOD, stalpi+sfoara LOG_DARK) -- fix bug gasit la
    # primul --compare (totul aparea albastru, vezi jurnalul in inventar).
    "rooftop_clutter": {
        "category": "props",
        "tints": {
            "Clutter_Base": {FOAM_WHITE: "#8FB0DC", LOG_DARK: "#2A2A2E", WOOD: "#6B4A2E"},
            "Clutter_Laundry": {CAR_YELLOW: "#F2C230", FLAMINGO_PINK: "#E874A1"},
        },
    },
    # --- val 3b: bazarul (brief §1.5) -- aceeasi conventie de camera decat
    # orasul (piese aproape cubice sau alungite pe Y, +X fata dominanta),
    # exceptie textile_strip (foarte alungita pe X, camera dedicata mai jos).
    "stall_canopy_a": {
        "category": "props",
        "tints": {
            "Canopy_Wood": "#6B4A2E",
            "Canopy": "#F2C230",  # CAR_YELLOW
            "Goods": {CAR_RED: "#D94A38", CAR_YELLOW: "#F2C230", LAVA_ORANGE: "#E8792E"},
        },
    },
    "stall_canopy_b": {
        "category": "props",
        "tints": {
            "Canopy_Wood": "#6B4A2E",
            "Canopy": "#E874A1",  # FLAMINGO_PINK
            "Goods": {CAR_YELLOW: "#F2C230", LAVA_ORANGE: "#E8792E"},
        },
    },
    "stall_canopy_c": {
        "category": "props",
        "tints": {
            "Canopy_Wood": "#6B4A2E",
            "Canopy": "#3FA556",  # TROPICAL_GREEN
            "Goods": {TROPICAL_GREEN: "#3FA556", LAVA_ORANGE: "#E8792E", CAR_RED: "#D94A38"},
        },
    },
    "textile_strip": {
        "category": "props",
        "tints": {
            "Poles": "#6B4A2E",
            "Cloth": {LAVA_ORANGE: "#E8792E", CAR_YELLOW: "#F2C230",
                     FLAMINGO_PINK: "#E874A1", CAR_RED: "#D94A38",
                     TROPICAL_GREEN: "#3FA556"},
        },
        # piesa e 10 m intinsa pe X (stalpii, sfoara), panzele sunt panouri
        # plate in planul XZ -- camera la azimut mic (aproape din lungul
        # stalpilor) vede piesa din MUCHIE (comprimata intr-o banda ingusta,
        # confirmat vizual la prima runda). Fix: azimut ~80 (aproape
        # perpendicular pe axa X), ca sa se vada latimea/culorile panzelor.
        "camera": {"azimuth": 80.0, "elevation": 12.0, "margin": 1.15},
    },
    "spice_sacks": {
        "category": "props",
        "tints": {
            "Sacks": "#C9A876",  # SAND_MID
            "Spice": {CAR_RED: "#D94A38", CAR_YELLOW: "#F2C230"},
        },
    },
    "thela_cart": {
        "category": "props",
        # Cart_Wheels e acum lemn (CRATE_WOOD), nu metal -- brief §1.5 "4
        # roti de LEMN cu spite", fix dupa --compare (rotile ieseau negru
        # uniform, spitele nedistinse de disc).
        "tints": {
            "Cart_Wood": "#6B4A2E",
            "Cart_Wheels": "#6B4A2E",
            "Cart_Fruit": {TROPICAL_GREEN: "#3FA556", CAR_YELLOW: "#F2C230",
                          LAVA_ORANGE: "#E8792E", CAR_RED: "#D94A38"},
        },
        # piesa mica (2.4x1.2m) -- margin redus ca sa umple mai mult cadrul
        "camera": {"azimuth": 35.0, "elevation": 18.0, "margin": 1.0},
    },
    "chai_stall": {
        "category": "props",
        "tints": {
            "Stall_Wood": {WOOD: "#6B4A2E", SAND_LIGHT: "#D9C9A3"},
            # PAINTED, corectat de la gri (#8A8A8E) la un metal inchis cald
            # (aluminiu/cositor patinat) -- pe decupare oalele sunt
            # inchis-maroniu, nu gri neutru
            "Stall_Metal": "#4A4238",
        },
        # margin implicit (1.2) lasa prea mult gol in jurul piesei (masurat
        # dupa runda de corectii: stalpii/acoperisul ocupau doar ~55% din
        # cadru) -- margin redus si elevatie usor mai mica, ca in decupare
        # (camera aproape la nivelul tejghelei, nu de sus).
        "camera": {"azimuth": 35.0, "elevation": 22.0, "margin": 1.55},
    },
    "marigold_garland": {
        "category": "props",
        "tints": {"Garland": "#E8792E"},  # LAVA_ORANGE, ca albedo per brief
    },
}


def _clear():
    for o in list(bpy.data.objects):
        if o.type in ("MESH", "EMPTY", "ARMATURE"):
            bpy.data.objects.remove(o, do_unlink=True)


def _import(category, name, models_dir):
    rel = name if not category else os.path.join(category, name)
    path = os.path.join(models_dir, "jodhpur", rel + ".glb")
    if not os.path.exists(path):
        return []
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.context.selected_objects if o.type in ("MESH", "ARMATURE")]


def _fix_ao_layer_name(obj):
    """Bug gasit prin masurare (nu presupus): `dio_lib.bake_ao` scrie AO-ul
    intr-un attribute numit "AO", dar exportul glTF are UN SINGUR slot de
    vertex color (COLOR_0) si Blender il RE-IMPORTA sub numele "Color", nu
    "AO". `apply_class`/`atlas_material` cauta explicit `layer_name = "AO"`
    (preview.py:123) -- pe o piesa importata dintr-un GLB, acel layer nu
    exista, ShaderNodeVertexColor citeste negru implicit, iar MULTIPLY cu
    negru scoate tot obiectul negru, indiferent de textura/tenta (exact ce s-a
    randat prima data pe ghanta_ghar: turnul intreg negru). `apply_class` nu
    e nicaieri altundeva apelat pe un mesh IMPORTAT (doar pe cele proaspat
    construite in acelasi build, unde attributul se numeste deja "AO"), deci
    fix-ul apartine aici, nu lui dio_lib."""
    attrs = obj.data.attributes
    if "AO" in attrs:
        return
    if "Color" in attrs:
        attrs["Color"].name = "AO"


def _make_ref_car(name="RefCar"):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    obj.scale = (REF_CAR[0], REF_CAR[1], REF_CAR[2])
    obj.location = (0.0, 0.0, REF_CAR[2] * 0.5)
    bpy.context.view_layer.update()
    mat = obj.matrix_world.copy()
    for v in obj.data.vertices:
        v.co = mat @ v.co
    obj.matrix_world.identity()
    mcar = bpy.data.materials.get("RefCarYellow")
    if mcar is None:
        mcar = bpy.data.materials.new("RefCarYellow")
        mcar.use_nodes = True
        bsdf = mcar.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (1.0, 0.82, 0.05, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.5
    obj.data.materials.clear()
    obj.data.materials.append(mcar)
    return obj


def sheet(group, path, models_dir=None, azimuth=180.0 - 35.0, elevation=16.0,
          res=(1600, 720), place_car=True, margin=1.25):
    models_dir = models_dir or MODELS
    category, names, step = GROUPS[group]
    _clear()
    built = []
    y = 0.0
    for n in names:
        objs = _import(category, n, models_dir)
        if not objs:
            print("LIPSA:", n)
            continue
        roots = [o for o in objs if o.parent is None]
        meshes = [o for o in objs if o.type == "MESH"]
        if not meshes:
            continue
        span_y = max(max(o.dimensions.y for o in meshes), 0.5)
        half = span_y * 0.5
        for o in roots:
            o.location.y += y + half
        bpy.context.view_layer.update()
        piece_center_y = y + half
        y += span_y + max(step, 2.0)
        built += meshes

        if place_car:
            car = _make_ref_car()
            piece_span_x = max(max(o.dimensions.x for o in meshes), 0.5)
            car.location = (-(piece_span_x * 0.5 + REF_CAR[1] * 0.5 + 1.5),
                            piece_center_y, 0.0)
            built.append(car)

    if not built:
        print("plansa", group, "SARITA (niciun GLB exportat inca)")
        return []

    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in built) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1
    shot(built, path, azimuth=azimuth, elevation=elevation, res=res, margin=margin)
    return [(o.name, len(o.data.polygons)) for o in built]


# --- comparatie de fidelitate (brief §0.1 pasul 3) ----------------------------

def _apply_flat_tint(obj, hex_color):
    """Material de preview FLAT: culoare de baza = hex-ul tintei * AO copt,
    fara nicio textura de clasa proxy (TASK C, instanta v2 a kitului).

    Motivul schimbarii fata de v1 (`_apply_tint`, pastrata mai jos doar ca
    istoric/referinta daca vreun consumator vechi o mai cheama): proxy-urile
    de textura (`plaster.png`, `alpine_granite.png`) nu exista sub numele
    claselor reale ale pistei si aveau luminanta gresita (gri-brun mediu, nu
    aproape-alb), ceea ce a cerut o corectie de gamma fragila si tot ieseau
    desaturate sub AgX. `view_transform=Standard` (deja setat in
    `_neutral_shot`) plus un multiply DIRECT hex*AO da exact culoarea din
    tabelul de sloturi (brief §0.4), fara ghicit de gamma sau proxy gresit."""
    mat = _flat_material(hex_color)
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def _apply_multi_flat_tint(obj, slot_tints):
    """Ca `_apply_flat_tint`, dar PE FATA, recuperand slotul din UV.x --
    pentru noduri care amesteca mai multe sloturi (ex. `Clock_Glow`: discul
    alb pe FOAM_WHITE si acele pe VOLCANIC_BLACK, in ACELASI nod -- contract
    inghetat, brief §1.1, nu se desparte in doua noduri doar pentru preview).

    Un singur `_apply_flat_tint` (un material FLAT pe tot obiectul) ar
    colora tot nodul cu o singura culoare, stergand contrastul disc/ace --
    exact bug-ul gasit runda 3 ("cadranele ies gri/pale, fara contrast").

    `slot_tints`: {slot_int: hex_color}. UV-urile sunt colapsate pe centrul
    slotului (`dio_lib.slot_u`), deci `round(u * SLOTS - 0.5)` recupereaza
    slotul exact, fara ambiguitate."""
    me = obj.data
    uv = me.uv_layers.active
    if uv is None:
        return
    mats = {}
    for slot, hexcol in slot_tints.items():
        mats[slot] = _flat_material(hexcol)
    obj.data.materials.clear()
    mat_index = {}
    for slot in slot_tints:
        mat_index[slot] = len(obj.data.materials)
        obj.data.materials.append(mats[slot])
    default_slot = next(iter(slot_tints))
    for poly in me.polygons:
        li = poly.loop_indices[0]
        u = uv.data[li].uv[0]
        slot = round(u * SLOTS - 0.5)
        poly.material_index = mat_index.get(slot, mat_index[default_slot])


def _srgb_to_linear(c):
    """sRGB [0,1] -> liniar, formula standard (IEC 61966-2-1).

    REVIZUIRE runda 3, cauza reala a desaturarii semnalate de critic (17%
    randat vs 35% nativ hex-ului, MASURAT chiar si izolat, cu AO fortat la
    1,0, fara alt multiply): `Base Color`-ul unui Principled BSDF asteapta
    valori LINIARE, dar codul punea direct `int(hex,16)/255` (adica
    fractia sRGB) in acel input. Blender interpreteaza acele numere ca
    liniare si le trece prin conversia liniar->afisaj (sRGB OETF) INCA O
    DATA la randare -- o dubla aplicare a curbei gamma, care comprima toate
    culorile spre mijlocul intervalului (desatureaza), indiferent de
    view_transform (Standard sau AgX -- ambele presupun input liniar).
    Fara aceasta conversie, orice tenta flat din acest fisier era gresita
    de la inceput, nu doar albastrul casei -- turnul (portocaliu, mai
    aproape de mijlocul intervalului) mascase bug-ul, fiind mai putin
    vizibil la ochi decat pe un albastru saturat."""
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def _flat_material(hex_color):
    """Materialul FLAT (hex * AO) folosit de `_apply_flat_tint` si
    `_apply_multi_flat_tint` -- extras ca sa nu se duplice graful de noduri."""
    name = "PreviewFlat_%s" % hex_color.lstrip("#")
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])

    r = _srgb_to_linear(int(hex_color[1:3], 16) / 255.0)
    gg = _srgb_to_linear(int(hex_color[3:5], 16) / 255.0)
    bcol = _srgb_to_linear(int(hex_color[5:7], 16) / 255.0)

    vcol = nt.nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "AO"
    ao_mix = nt.nodes.new("ShaderNodeMix")
    ao_mix.data_type = "RGBA"
    ao_mix.blend_type = "MULTIPLY"
    ao_mix.inputs["Factor"].default_value = 1.0
    ao_mix.inputs[6].default_value = (r, gg, bcol, 1.0)
    nt.links.new(ao_mix.inputs[7], vcol.outputs["Color"])
    nt.links.new(bsdf.inputs["Base Color"], ao_mix.outputs[2])
    return mat


def _strip_dup_suffix(name):
    """Blender adauga ".001"/".002".. cand numele obiectului e deja ocupat
    de un data-block orfan ramas in bpy.data (build_jodhpur_city.py exporta
    7 piese in ACEEASI sesiune, fara sa stearga obiectele intre emit()-uri
    -- gasit prin masurare, nu presupus: `House_Wall` din blue_house_b ramane
    orfan in bpy.data.objects, deci blue_house_c importa ca `House_Wall.001`.
    Fara acest strip, lookup-ul in COMPARE_SPECS["tints"] rateaza exact pe
    numele nodului principal si piesa cade pe atlas_material() implicit
    (gri/alb) -- bug reprodus vizual pe blue_house_b/c/e (casele ies gri, nu
    albastre) la prima comparatie a valului 3."""
    import re
    return re.sub(r"\.\d{3}$", "", name)


def _import_for_compare(name, spec, models_dir):
    objs = _import(spec["category"], name, models_dir)
    meshes = [o for o in objs if o.type == "MESH"]
    for o in meshes:
        _fix_ao_layer_name(o)
        base_name = _strip_dup_suffix(o.name)
        tints = spec.get("tints", {})
        tint = tints.get(o.name, tints.get(base_name))
        if isinstance(tint, dict):
            _apply_multi_flat_tint(o, tint)
        elif tint is not None:
            _apply_flat_tint(o, tint)
        else:
            atlas_material()  # forteaza materialul standard sa existe
            o.data.materials.clear()
            o.data.materials.append(atlas_material())
    return meshes


def _dename(name):
    import re
    return re.sub(r"\.\d{3}$", "", name)


def _tint_obj(o, spec):
    _fix_ao_layer_name(o)
    tint = spec.get("tints", {}).get(_dename(o.name))
    if isinstance(tint, dict):
        _apply_multi_flat_tint(o, tint)
    elif tint is not None:
        _apply_flat_tint(o, tint)


def _chain_for_compare(name, spec, chain, first, models_dir):
    """Modul inlantuibil: `n` copii ale GLB-ului cap la cap pe Y (pas
    `step`), plus piesa de capat (`ends`) la ambele capete, iesita cu
    `ends_dx` pe X. Toate importate din GLB, deci rosturile care se vad sunt
    cele reale."""
    n = chain.get("n", 3)
    step = chain.get("step", 12.0)
    out = list(first)
    for o in first:
        if o.parent is None:
            o.location.y += -step * (n - 1) * 0.5
    for k in range(1, n):
        objs = _import(spec["category"], name, models_dir)
        for o in objs:
            if o.type == "MESH":
                _tint_obj(o, spec)
                out.append(o)
            if o.parent is None:
                o.location.y += -step * (n - 1) * 0.5 + step * k
    ends = chain.get("ends")
    if ends:
        cat, end_name = ends
        span = step * n * 0.5 + chain.get("ends_half", 0.0)
        for sgn in (-1.0, 1.0):
            objs = _import(cat, end_name, models_dir)
            for o in objs:
                if o.type == "MESH":
                    _tint_obj(o, spec)
                    out.append(o)
                if o.parent is None:
                    o.location.y += sgn * span
                    o.location.x += chain.get("ends_dx", 0.0)
    bpy.context.view_layer.update()
    return out


def compare(name, models_dir=None, res_height=900, out_dir=None):
    """Decupare (stanga) + randare din GLB exportat (dreapta), la aceeasi
    inaltime in pixeli (brief §0.1 pasul 3)."""
    models_dir = models_dir or MODELS
    out_dir = out_dir or os.path.join(PROJECT, "docs", "asset_briefs", "img",
                                      "jodhpur_fidelity")
    os.makedirs(out_dir, exist_ok=True)
    spec = COMPARE_SPECS.get(name)
    if spec is None:
        print("LIPSA specificatie compare pentru", name)
        return None

    crop_path = os.path.join(PROJECT, "docs", "track_briefs", "img",
                             "jodhpur_assets_v1", name + ".png")
    if not os.path.exists(crop_path):
        print("LIPSA decupare:", crop_path)
        return None

    _clear()
    meshes = _import_for_compare(name, spec, models_dir)
    if not meshes:
        print("LIPSA GLB pentru compare:", name)
        return None
    chain = spec.get("chain")
    if chain:
        meshes = _chain_for_compare(name, spec, chain, meshes, models_dir)

    for o in bpy.data.objects:
        if o.type == "MESH":
            o.hide_render = (o not in meshes) and not o.name.startswith("Preview")
    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        bpy.context.scene.collection.objects.link(cam)
    cam.data.clip_end = 500.0
    cam.data.clip_start = 0.1

    render_path = os.path.join(out_dir, "_render_" + name + ".png")
    # fundal gri deschis #CFCFCF, lumina de zi neutra (nu tema calda din
    # `_world`/`_light`: aici vrem sa se citeasca CULOAREA reala a piesei, nu
    # tenta calda de apus a temei) -- randam manual, fara `shot()`.
    #
    # REVIZUIRE (runda 2, ambele valuri respinse de sef pe fidelitate):
    # decuparile pieselor late sunt aproape FRONTALE (~15-20 grade azimut,
    # ~10-15 elevatie), nu 3/4 la 35/18 (implicitul pilotului). Fiecare piesa
    # isi poate declara unghiul in COMPARE_SPECS, fie in dictul `camera`
    # (val 2b), fie direct pe spec (val 2a); implicit 35/18/1.2/55.
    cam_spec = dict(spec)
    cam_spec.update(spec.get("camera", {}))
    _neutral_shot(meshes, render_path,
                 azimuth=cam_spec.get("azimuth", 35.0),
                 elevation=cam_spec.get("elevation", 18.0),
                 res_height=res_height,
                 margin=cam_spec.get("margin", 1.2),
                 lens=cam_spec.get("lens", 55.0),
                 sun_follow=spec.get("sun_follow"))

    # Blender-ul headless n-are PIL in Python-ul lui bundle-uit (masurat: nu
    # exista, si nu instalam pachete in interpretorul lui Blender). Stitch-ul
    # crop+randare si planta de val se fac cu Python-ul de SISTEM, intr-un
    # proces separat -- `compose_jodhpur.py`, apelat aici prin subprocess.
    out_path = os.path.join(out_dir, name + ".png")
    _run_compose(["--compare", name, "--crop", crop_path,
                 "--render", render_path, "--out", out_path,
                 "--height", str(res_height)])
    print("comparatie salvata (compose extern):", out_path)
    return out_path


def _run_compose(extra_args):
    import subprocess
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "compose_jodhpur.py")
    # Python de sistem, nu cel din Blender: incearca "python", apoi "py".
    for exe in ("python", "py"):
        try:
            r = subprocess.run([exe, script] + extra_args, capture_output=True, text=True)
            if r.returncode == 0:
                if r.stdout.strip():
                    print(r.stdout.strip())
                return True
            print("compose_jodhpur.py a esuat (%s):" % exe, r.stderr.strip())
        except FileNotFoundError:
            continue
    print("Nu am gasit python de sistem -- ruleaza manual:")
    print("    python tools/blender/compose_jodhpur.py", " ".join(extra_args))
    return False


def _neutral_shot(objects, path, azimuth, elevation, res_height, margin=1.2, lens=55.0,
                  sun_follow=None):
    """Ca `shot()`, dar cu lumina de zi NEUTRA si fundal #CFCFCF (brief §0.1
    pasul 3), nu tema calda de apus din `preview._light`/`_world`.

    `lens` (mm): implicit 55. Pe piese FOARTE late si putin adanci (poarta,
    modulul de trepte -- rata lungime/adancime >5:1), un obiectiv normal la
    distanta calculata din latime aduce camera atat de aproape incat cele
    doua capete (turnuri) ies la scari foarte diferite (paralaxa mare intre
    ele) -- exact raportat de sef runda 2 ("vazuta din lateral/din spate").
    Un `lens` mai lung (teleobiectiv, 100-150 mm) COMPRIMA perspectiva,
    apropiind scara capetelor, ca in decupare (care e un randaj aproape
    ortografic)."""
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objects:
        for corner in o.bound_box:
            p = o.matrix_world @ Vector(corner)
            lo = Vector((min(lo[i], p[i]) for i in range(3)))
            hi = Vector((max(hi[i], p[i]) for i in range(3)))
    center = (lo + hi) * 0.5
    ext = hi - lo
    res_x = int(res_height * 4 / 3)
    res = (res_x, res_height)

    cam = bpy.data.objects.get("PreviewCam")
    if cam is None:
        data = bpy.data.cameras.new("PreviewCam")
        cam = bpy.data.objects.new("PreviewCam", data)
        scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.lens = lens
    sensor = cam.data.sensor_width
    aspect = res[0] / float(res[1])
    hfov = 2.0 * math.atan(sensor / (2.0 * cam.data.lens))
    vfov = 2.0 * math.atan(math.tan(hfov / 2.0) / aspect)
    width = math.hypot(ext.x, ext.y)
    dist = margin * max(width * 0.5 / math.tan(hfov / 2.0),
                        ext.z * 0.5 / math.tan(vfov / 2.0))
    a = math.radians(azimuth)
    e = math.radians(elevation)
    eye = center + Vector((math.cos(a) * math.cos(e), math.sin(a) * math.cos(e),
                           math.sin(e))) * dist
    cam.location = eye
    look = (center - eye).normalized()
    cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()

    # lumina de zi neutra: soare alb, sus, fara tenta calda
    for o in list(bpy.data.objects):
        if o.type == "LIGHT":
            bpy.data.objects.remove(o, do_unlink=True)

    # REVIZUIRE runda 3 (nota sefului): lumina principala trebuie sa fie PE
    # PARTEA CAMEREI (azimut la <=40 grade de camera), altfel fetele vazute
    # de camera cad in umbra si citesc desaturat, indiferent cat de tare e
    # fill-ul. Masurat direct: cu `rotation_euler=(45,0,35)` (Z=azimutul
    # camerei, in grade, dar Euler-ul unui SUN nu se comporta ca un azimut
    # direct -- directia de iluminare rezultata e la ~90 grade de camera, nu
    # la 35), fata cu usa a casei albastre (+Y) cadea in umbra AMBELOR
    # lumini directionale. Rezolvat prin cautare numerica: pentru camera la
    # azimut=35/elevatie=18 (formula `_neutral_shot`), directia care
    # ILUMINEAZA exact partea camerei e `rotation_euler=(radians(65), 0,
    # radians(125))` (produsul scalar cu directia camerei = 0,99, verificat
    # cu Euler().to_matrix() @ (0,0,-1)) -- NU Z=azimut direct.
    sdata = bpy.data.lights.new("NeutralSun", type="SUN")
    sun = bpy.data.objects.new("NeutralSun", sdata)
    scene.collection.objects.link(sun)
    # REVIZUIRE: energiile de mai jos au fost coborate agresiv (pana la
    # 1,2/0,9) in timp ce cautam cauza desaturarii, presupunand supra-
    # expunere -- cauza REALA era conversia sRGB->liniar lipsa din
    # `_flat_material` (vezi `_srgb_to_linear`), nu lumina. Cu bug-ul de
    # culoare corectat, energii rezonabile (fata luminata direct, fara
    # supra-expunere pe alb la AO=1) sunt 2,4/1,0.
    sun.data.energy = 2.4
    sun.data.color = (1.0, 1.0, 1.0)
    sun.data.angle = math.radians(3.0)
    sun.data.specular_factor = 0.0
    sun.rotation_euler = (math.radians(65.0), 0.0, math.radians(125.0))
    if sun_follow:
        # Soarele urmeaza camera (optional, per piesa): un SUN cu
        # rotation_euler (X, 0, Z) lumineaza DINSPRE azimutul Z - 90 (masurat:
        # directia -Z locala rotita da sursa la atan2(-cos Z, sin Z)), la
        # elevatia 90 - X. Deci sursa la azimutul camerei + `offset` cere
        # Z = azimut + 90 + offset. Implicitul (65, 0, 125) = sursa la 35,
        # potrivit doar camerei implicite (35/18) -- piesele cu camera
        # proprie departe de 35 (poarta la ~260) se vedeau din umbra.
        sun.rotation_euler = (math.radians(sun_follow.get("tilt", 65.0)), 0.0,
                              math.radians(azimuth + 90.0 + sun_follow.get("offset", 0.0)))

    # fill mai slab (soarele principal acopera acum fata camerei) -- doar ca
    # sa nu ramana complet negre fetele din umbra opusa.
    fill_data = bpy.data.lights.new("NeutralFill", type="SUN")
    fill = bpy.data.objects.new("NeutralFill", fill_data)
    scene.collection.objects.link(fill)
    fill.data.energy = 1.0
    fill.data.color = (1.0, 1.0, 1.0)
    fill.rotation_euler = (math.radians(90 - 55), 0.0, math.radians(35.0 + 180.0))

    world = scene.world or bpy.data.worlds.new("PreviewWorldNeutral")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.812, 0.812, 0.812, 1.0)  # #CFCFCF
        # Ambientul gri se amesteca aditiv cu fetele umbrite -- prea puternic
        # desatureaza (griul domina). Cu soarele acum aliniat pe fata camerei
        # (vezi mai sus) si bug-ul real de desaturare corectat
        # (`_srgb_to_linear`), 0,5 e suficient doar ca sa umple umbrele
        # adanci fara sa spele culoarea fetelor luminate.
        bg.inputs[1].default_value = 0.5

    # AgX (implicit in Blender 4/5) comprima si desatureaza puternic culorile
    # -- masurat direct: o tenta albastra `#8FB0DC` inmultita cu plaster.png
    # iesea gri neutru complet (176,176,176), nedistinctibil de netintat.
    # Comparatia cere "culoare REALA" (brief §0.1 pasul 3), deci view transform
    # Standard, ca hex-ul din tabel sa se vada asa cum a fost scris.
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0

    scene.render.engine = "BLENDER_EEVEE_NEXT" if hasattr(
        bpy.types, "RenderEngineEeveeNext") or "BLENDER_EEVEE_NEXT" in [
        e2.identifier for e2 in
        bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items
    ] else "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    return path


WAVE_PIECES = {
    1: ["ghanta_ghar", "blue_house_a"],
    # "2b" (nu 2 -- brief-ul numeste valul reperelor "Val 2b" in inventar):
    # cele 5 piese-reper, brief §1.3.
    "2b": ["market_gate", "stepwell_flight_module", "stepwell_corner",
          "stepwell_pavilion", "jaswant_thada"],
    # val 2a (brief §1.2, cetatea) -- "2a" ramane STRING (nu val int), vezi
    # `fidelity_sheet`/argparsing mai jos, ca sa nu forteze `int()` pe un
    # nume de val alfanumeric.
    # escaladarea Opus (cele 3 piese respinse de doua ori in valul 2)
    "2-opus": ["market_gate", "fort_wall_segment", "rampart_cannon"],
    "2a": ["fort_gate_jai", "fort_gate_fateh", "fort_gate_loha",
           "fort_wall_segment", "fort_wall_turret", "fort_bastion",
           "palace_facade_a", "palace_facade_b", "rampart_cannon"],
    # val 3 (brief §1.4+§1.5, orasul albastru + bazarul) -- 7 piese din
    # build_jodhpur_city.py + 8 din build_jodhpur_bazaar.py.
    "3": ["blue_house_b", "blue_house_c", "blue_house_d", "blue_house_e",
          "haveli_facade", "rooftop_tank", "rooftop_clutter",
          "stall_canopy_a", "stall_canopy_b", "stall_canopy_c",
          "textile_strip", "spice_sacks", "thela_cart", "chai_stall",
          "marigold_garland"],
}


def fidelity_sheet(wave, out_dir=None, names=None):
    """Aduna comparatiile deja randate ale valului intr-o singura imagine
    (brief §0.1 pasul 5). Delegat catre `compose_jodhpur.py` (Python de
    sistem, cu PIL) -- vezi motivul in `compare()`.

    `wave` poate fi int (valurile numerice) sau str (ex. "2b", valul
    reperelor) -- WAVE_PIECES accepta ambele chei, iar numele fisierului
    foloseste `str(wave)` (nu `%d`, care ar pica pe un wave alfanumeric)."""
    fid_dir = os.path.join(PROJECT, "docs", "asset_briefs", "img", "jodhpur_fidelity")
    out_dir = out_dir or os.path.join(PROJECT, "docs", "asset_briefs", "img")
    names = names or WAVE_PIECES.get(wave, [])
    out_path = os.path.join(out_dir, "jodhpur_fidelity_val%s.png" % wave)
    ok = _run_compose(["--sheet", str(wave), "--fid-dir", fid_dir,
                       "--names", ",".join(names), "--out", out_path])
    if ok:
        print("planta fidelitate val", wave, "salvata:", out_path)
        return out_path
    return None


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview.py")).read())
OUT = os.path.join(PROJECT, "docs", "asset_briefs", "img")
os.makedirs(OUT, exist_ok=True)

argv = sys.argv
args = argv[argv.index("--") + 1:] if "--" in argv else []

if "--compare" in args:
    idx = args.index("--compare")
    piece = args[idx + 1]
    compare(piece)
elif "--sheet" in args:
    idx = args.index("--sheet")
    wave_arg = args[idx + 1]
    # int daca e numeric (valurile 1, 2, ...), altfel string ("2a")
    wave = int(wave_arg) if wave_arg.isdigit() else wave_arg
    fidelity_sheet(wave)
elif "--group" in args:
    idx = args.index("--group")
    g = args[idx + 1]
    print("plansa", g, sheet(g, os.path.join(OUT, "jodhpur_%s.png" % g)))
else:
    for g in GROUPS:
        print("plansa", g, sheet(g, os.path.join(OUT, "jodhpur_%s.png" % g)))
