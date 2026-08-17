"""cable_car_gondola.glb — cabina de telecabina, perechea pilonului alpin.

  CableCarGondola   vehicles/cable_car_gondola.glb   2.3 x 2.1 x 4.0 m   <= 3000

Dupa referinta "Cable Car Gondola (isolated)": cabina rosie cu ferestre pe toate
cele patru laturi in jumatatea de sus, o banda neagra sub geamuri, acoperis
inchis, iar deasupra bratul de suspensie cu clema si doua role pe cablu.
Inaltimea totala 4.0 m e cota din planşa; cabina singura are ~2.6 m.

Sloturi (fara nimic nou):
  KERB_RED (#BB3522)      caroseria — singurul rosu de mediu din paleta; e sub
                          pragul de saturatie al masinilor, dar destul de viu
                          ca gondola sa se citeasca pe cer si pe zapada.
  ASPHALT (#4B4B4D)       geamurile — cel mai inchis slot, citeste ca gol
                          (regula din Builder.window).
  VOLCANIC_BLACK (#55535A) banda sub geamuri, acoperisul, clema si rolele —
                          acelasi "otel negru" ca bateriile de rulouri de pe
                          pilon, ca cele doua sa arate din acelasi kit.
  PAINTED (#7692A8)       bratul de suspensie — otelul vopsit al pilonului.
  FOAM_WHITE (#E9F2F0)    numarul "07" de pe fata, din segmente (nu textura).

Contract cu Godot:
  - un singur nod: `CableCarGondola`
  - originea la BAZA cabinei (ca tot restul kitului); punctul de prindere pe
    cablu e la GRIP_Z = 4.0 m deasupra originii, pe axa nodului. Cine o agata
    de cablu pune nodul la (cablu.y - 4.0). Rolele ruleaza pe X (cablul trece
    pe X, la fel ca traversa pilonului) — fata cu numarul priveste spre +Y in
    Blender, adica -Z in Godot.

Rulare (headless, ca tot kitul alpin):
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_cable_car_gondola.py
"""

import math
from mathutils import Matrix

CAB_W, CAB_D = 2.2, 2.0          # X, Y
BODY_TOP = 1.05                   # sus panoul rosu de jos
GLASS_LO, GLASS_HI = 1.15, 2.35   # zona vitrata
ROOF_Z = 2.42
GRIP_Z = 4.0                      # cota clemei pe cablu — contract
TAPER_LO = 0.90                   # latimea la podea, fractie din CAB_W/CAB_D
DIGIT_Z = 0.58


def rot_z(deg):
    return Matrix.Rotation(math.radians(deg), 3, "Z")


def digit(b, ch, cx, cz, y, w=0.24, h=0.40, t=0.055, slot=FOAM_WHITE):
    """Cifra din segmente (afisaj cu 7 segmente) lipita pe fata +Y.

    Privita din exterior, fata +Y are +X pe STANGA — de-asta X-urile sunt
    negate: fara asta "07" se citea "ГO" (prima randare)."""
    segs = {"0": "abcdef", "7": "abc", "1": "bc", "2": "abged",
            "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc",
            "8": "abcdefg", "9": "abcdfg"}[ch]
    hw, hh = w * 0.5, h * 0.5
    horiz = {"a": hh, "g": 0.0, "d": -hh}
    for s in segs:
        if s in horiz:
            b.box((-cx, y, cz + horiz[s]), (w, 0.02, t), slot)
        else:
            sx = -hw if s in "ef" else hw
            sz = hh * 0.5 if s in "bf" else -hh * 0.5
            b.box((-(cx + sx), y, cz + sz), (t, 0.02, hh), slot)


def build_gondola():
    b = Builder()

    # --- corpul de jos: panou rosu, cu prag inchis dedesubt --------------
    b.box((0.0, 0.0, 0.05), (CAB_W - 0.3, CAB_D - 0.3, 0.10), VOLCANIC_BLACK)
    b.box((0.0, 0.0, (0.10 + BODY_TOP) * 0.5), (CAB_W, CAB_D, BODY_TOP - 0.10),
          KERB_RED)
    # banda neagra sub geamuri (iese 2 cm in relief pe tot conturul)
    b.box((0.0, 0.0, (BODY_TOP + GLASS_LO) * 0.5),
          (CAB_W + 0.04, CAB_D + 0.04, GLASS_LO - BODY_TOP), VOLCANIC_BLACK)

    # taper: cabina se ingusteaza spre podea (referinta nu e o cutie).
    # Doar corpul de jos, deasupra tot ce e vitrat ramane drept.
    for v in b.bm.verts:
        if v.co.z < BODY_TOP:
            f = TAPER_LO + (1.0 - TAPER_LO) * max(v.co.z, 0.0) / BODY_TOP
            v.co.x *= f
            v.co.y *= f

    # --- zona vitrata: patru stalpi de colt + o fereastra pe fiecare fata --
    gz = (GLASS_LO + GLASS_HI) * 0.5
    gh = GLASS_HI - GLASS_LO
    post = 0.16
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            b.box((sx * (CAB_W - post) * 0.5, sy * (CAB_D - post) * 0.5, gz),
                  (post, post, gh), KERB_RED)
    # miez opac: fara el, prin geamurile de pe fete opuse s-ar vedea cerul
    b.box((0.0, 0.0, gz), (CAB_W - 0.2, CAB_D - 0.2, gh), ASPHALT)
    # fata / spate (privesc pe Y): trei ochiuri
    for sy, deg in ((1.0, 0.0), (-1.0, 180.0)):
        b.window((0.0, sy * CAB_D * 0.5, gz), CAB_W - 2 * post + 0.02, gh,
                 0.08, 0.08, ASPHALT, KERB_RED, mullions=(2, 0),
                 rotation=rot_z(deg))
    # laterale (privesc pe X): doua ochiuri
    for sx, deg in ((1.0, -90.0), (-1.0, 90.0)):
        b.window((sx * CAB_W * 0.5, 0.0, gz), CAB_D - 2 * post + 0.02, gh,
                 0.08, 0.08, ASPHALT, KERB_RED, mullions=(1, 0),
                 rotation=rot_z(deg))

    # --- acoperis: rama neagra + capac gri usor retras -----------------------
    b.box((0.0, 0.0, ROOF_Z), (CAB_W + 0.10, CAB_D + 0.10, 0.14), VOLCANIC_BLACK)
    b.box((0.0, 0.0, ROOF_Z + 0.12), (CAB_W - 0.30, CAB_D - 0.30, 0.12),
          ASPHALT_EDGE)

    # --- bratul de suspensie ---------------------------------------------
    mount_z = ROOF_Z + 0.18
    b.box((0.0, 0.0, mount_z + 0.12), (0.55, 0.40, 0.24), PAINTED)      # soclu
    b.beam((0.0, 0.0, mount_z + 0.20), (0.0, 0.0, GRIP_Z - 0.55), 0.18, PAINTED)
    # tirantul oblic (amortizorul din referinta) + articulatia lui
    b.beam((0.55, 0.0, mount_z + 0.22), (0.05, 0.0, GRIP_Z - 0.75), 0.07, PAINTED)
    b.cylinder((0.55, 0.0, mount_z + 0.22), 0.09, 0.14, VOLCANIC_BLACK,
               segments=8, axis="Y")
    # clema: corp negru pe cablu, cu doua role si bara de sus
    b.box((0.0, 0.0, GRIP_Z - 0.40), (0.95, 0.30, 0.34), VOLCANIC_BLACK)
    for sx in (-0.34, 0.34):
        b.cylinder((sx, 0.0, GRIP_Z - 0.14), 0.15, 0.20, VOLCANIC_BLACK,
                   segments=10, axis="Y")
    b.box((0.0, 0.0, GRIP_Z - 0.06), (1.05, 0.22, 0.10), PAINTED)

    # --- numarul "07" pe fata din +Y ---------------------------------------
    # fata e inclinata de taper: y-ul ei la cota cifrelor, plus 1 cm relief
    y_face = CAB_D * 0.5 * (TAPER_LO + (1.0 - TAPER_LO) * DIGIT_Z / BODY_TOP) + 0.01
    digit(b, "0", -0.19, DIGIT_Z, y_face)
    digit(b, "7", 0.19, DIGIT_Z, y_face)
    return b


# ------------------------------------------------------------------ build
NAME, GLB, BUDGET = "CableCarGondola", "vehicles/cable_car_gondola.glb", 3000
AO = dict(samples=24, dist=2.0, gradient="vertical", low=0.55, high=1.0,
          power=1.0, floor=0.18)

clear_built(NAME)
obj = build_gondola().to_object(NAME)
stats = finish(obj, bevel=0.025, bevel_angle=40.0, ao=AO)
me = obj.data
dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
        for i in range(3)]
print("%-16s %5d tris (buget %d) %s | %.2f x %.2f x %.2f m | AO %.2f..%.2f"
      % (NAME, stats["tris"], BUDGET,
         "OK" if stats["tris"] <= BUDGET else "DEPASIT",
         dims[0], dims[1], dims[2], stats["ao_min"], stats["ao_max"]))
print("GLB:   %s (%d B)" % export_glb([obj], GLB))
print("BLEND: %s (%d B)" % save_blend([obj], "cable_car_gondola.blend"))
