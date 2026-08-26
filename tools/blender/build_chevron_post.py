"""Stromboli — stalpul cu chevron (brief docs/asset_briefs/stromboli_roadside.md, fisierul 2).

  ChevronPost  stromboli/props/chevron_post.glb
               Chevron_Post

Semnalizarea de pe exteriorul acelor de par si de pe crestele oarbe ale
coborarii. Un singur obiect, buget 120 de triunghiuri — cel mai strans din tot
setul, si de-asta fiecare decizie e o socoteala.

**Sagetile sunt GEOMETRIE, nu textura si nu litera** (brief). Trei poligoane
rosii extrudate 0.01 m peste placa alba. `prism` le face dintr-un contur 2D:
un chevron e un hexagon concav, adica exact 6 puncte.

**Sensul:** sagetile arata spre +X (dreapta privitorului), iar placa priveste
spre -Z_godot = +Y_blender. La plantare pista oglindeste prin `scale.x = -1`
unde trebuie invers — dar atunci chevronul trebuie sa fie NOD, nu instanta de
MultiMesh (memoria `multimesh-oglindire-culling`: instantele oglindite sunt
culled).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_chevron_post.py
"""

import math
from mathutils import Matrix, Vector

AO_POST = dict(samples=20, dist=1.6, gradient="vertical",
               low=0.60, high=1.00, power=0.9, floor=0.35)

POST_H = 1.2
POST_T = 0.12
PLATE_W, PLATE_H = 0.6, 0.45
PLATE_Z = POST_H - PLATE_H * 0.5 - 0.05

WOOD_S = WOOD
PLATE = FOAM_WHITE
ARROW = KERB_RED           # aceleasi dungi ca bordurile (brief)


def _chevron(cx, cz, w, h):
    """Conturul unei sageti-chevron, ca lista de (x, z).

    Sase puncte: varful din dreapta, cele doua colturi de sus/jos si scobitura
    din stanga. Asta e forma de "> " care se citeste ca sageata la 25 m.
    """
    hw, hh = w * 0.5, h * 0.5
    notch = w * 0.42
    return [
        (cx - hw, cz + hh),
        (cx - hw + notch, cz + hh),
        (cx + hw, cz),
        (cx - hw + notch, cz - hh),
        (cx - hw, cz - hh),
        (cx - hw + notch * 0.52, cz),
    ]


if __name__ == "__main__":
    clear_built()
    b = Builder()

    # stalpul
    b.box((0.0, 0.0, POST_H * 0.5), (POST_T, POST_T, POST_H), WOOD_S)

    # placa: fond alb, subtire. Fata utila priveste spre +Y (= -Z in Godot).
    b.box((0.0, POST_T * 0.5 + 0.02, PLATE_Z), (PLATE_W, 0.04, PLATE_H), PLATE)

    # Trei sageti rosii, extrudate 0.012 peste placa.
    #
    # `prism` primeste conturul in planul XZ si extrudeaza pe Y — exact
    # orientarea de care avem nevoie, fara nicio rotatie: fata din fata (spre
    # +Y in Blender) devine -Z in Godot, adica fix directia din care se vede
    # semnul.
    plate_face_y = POST_T * 0.5 + 0.04
    aw = PLATE_W * 0.27
    for k in range(3):
        cx = -PLATE_W * 0.5 + PLATE_W * (0.20 + 0.30 * k)
        outline = _chevron(cx, 0.0, aw, PLATE_H * 0.72)
        b.prism(outline, 0.012, ARROW,
                center=(0.0, plate_face_y, PLATE_Z))

    post = b.to_object("Chevron_Post")
    # BEVEL 0 — singura cale de a incapea in bugetul de 120, si e si corecta.
    #
    # Socoteala: stalp 12 + placa 12 + 3 chevroane (hexagon concav: 8 tri pe
    # fete + 12 laterale = 20) = 84 de triunghiuri BRUTE. Cu bevel 0.008 sar la
    # 277, fiindca bevelul costa topologic, nu dupa latime — un bevel de 8 mm
    # costa exact cat unul de 10 cm (vezi apply_bevel).
    #
    # Si e alegerea corecta stilistic: bevelul e semnatura pieselor de piatra
    # si lemn din lume, dar un semn de circulatie e placa taiata si stalp
    # geluit. Muchia vie e ce il face sa citeasca a obiect fabricat.
    stats = finish(post, bevel=0.0, ao=AO_POST, origin="base_axis")
    print("Chevron_Post %3d tris  (buget 120)  AO %.2f..%.2f"
          % (stats["tris"], stats["ao_min"], stats["ao_max"]))
    # Piesa e neutra ca tema (rosu/alb/lemn, fara nimic vulcanic), iar plansa
    # Chongqing o cere la pozitia 17 pentru curbele oarbe ale spiralei. Se
    # exporta in AMBELE locuri din aceeasi sursa, ca sa nu existe doua
    # geometrii care se pot desincroniza — o pista nu trebuie sa depinda de
    # folderul alteia.
    for dest in ("stromboli/props/chevron_post.glb",
                 "chongqing/props/chevron_post.glb"):
        path, size = export_glb([post], dest)
        print("export: %s (%.1f KB)" % (path, size / 1024.0))
