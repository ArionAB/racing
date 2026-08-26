"""Chongqing — kitul nodului Huangjuewan (plansa, pozitia 5).

  structures/ramp_straight_10m.glb   tronson drept de 10 m, cu parapet pe ambele parti
  structures/ramp_arc_15deg.glb      tronson curb de 15°, raza 40 m
  structures/pillar_round.glb        pilon rotund cu capitel si soclu
  structures/parapet_module.glb      parapet New Jersey de 4 m (separator mobil)
  structures/launch_ramp.glb         rampa-kicker de la etajul 2
  props/construction_barrier.glb     bariera de santier cu lampa

Kitul ASTA e spirala: din piesele de aici se construieste nodul rutier pe
care drumul trece peste el insusi. Doua lucruri decid daca se citeste ca
infrastructura si nu ca jucarie de plastic:

1. **Tablierul are BURTA.** Cand treci pe SUB un etaj, ce vezi e dedesubtul
   lui — un tavan scurt cu grinzi longitudinale (brief §2.0: senzatia de
   stiva se construieste de sus in jos, prin piloni si prin burta pasajului).
   Deci fiecare tronson primeste doua grinzi de sub carosabil, nu doar o
   placa. Fara ele, pe sub pasaj se vede o foaie de hartie.
2. **Parapetul e MASIV.** style_bible §3 interzice balustradele subtiri, iar
   aici e si corect tehnic: pe un viaduct nu stau lise, sta beton turnat.
   Profil New Jersey (baza lata, gat inclinat, coama) — silueta aia se
   recunoaste de la 60 km/h, un simplu perete vertical nu.

Racordarea: piesele se imbina cap la cap pe axa +Y (Blender), cu originea in
CAPATUL DE START, pe axa drumului. Asa se pot insirui in Godot fara sa
calculezi offseturi — pui urmatoarea piesa la capatul precedentei.
Exceptie: pilonul si bariera, care sunt piese de sine statatoare (origine
centrata in XY, contractul standard `finish(origin="base")`).

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_interchange.py
"""

import math
from mathutils import Matrix, Vector

AO_DECK = dict(samples=24, dist=6.0, gradient="vertical",
               low=0.42, high=1.00, power=0.9, floor=0.10)
AO_PROP = dict(samples=22, dist=3.0, gradient="vertical",
               low=0.48, high=1.00, power=0.9, floor=0.15)

# Latimea de carosabil a rampelor din brief (§2, POI F): 7 m.
ROAD_W = 7.0
DECK_T = 0.55          # grosimea tablierului (placa + burta)
PARAPET_H = 0.95       # inaltimea parapetului peste carosabil
KERB = ASPHALT_EDGE    # banda de racord intre asfalt si parapet


def deck_slab(b, y0, y1, half_w=ROAD_W * 0.5, z=0.0, slot=ASPHALT):
    """Placa de carosabil intre doua cote pe Y, cu burta de beton dedesubt.

    Carosabilul e ASPHALT (suprafata pe care conduci), tot ce e structura e
    CONCRETE. Separarea nu e cosmetica: banda inchisa a drumului e ce citeste
    ochiul ca "linie de curs" la viteza (style_bible §1).
    """
    length = y1 - y0
    yc = (y0 + y1) * 0.5
    # suprafata de rulare
    b.box((0.0, yc, z - 0.06), (half_w * 2.0, length, 0.12), slot)
    # burta: placa de beton + doua grinzi longitudinale (se vad de sub pasaj)
    b.box((0.0, yc, z - 0.24), (half_w * 2.0 - 0.10, length, 0.24), CONCRETE)
    for sx in (-1.0, 1.0):
        b.box((sx * half_w * 0.52, yc, z - 0.52), (0.55, length, 0.42), CONCRETE)


def parapet_run(b, y0, y1, x, z=0.0, slot=CONCRETE, chevrons=False):
    """Parapet New Jersey de-a lungul lui Y, la distanta x de axa.

    Profilul in trei trepte (baza lata -> gat -> coama) e ce face silueta
    recognoscibila. `chevrons` adauga benzi rosii pe coama — pe curbele oarbe
    ale spiralei, brief §8 le cere explicit.
    """
    length = y1 - y0
    yc = (y0 + y1) * 0.5
    sgn = 1.0 if x > 0 else -1.0
    # baza lata
    b.box((x, yc, z + 0.14), (0.52, length, 0.28), slot)
    # gat inclinat spre carosabil
    b.box((x + sgn * 0.06, yc, z + 0.48), (0.38, length, 0.42), slot)
    # coama
    b.box((x + sgn * 0.10, yc, z + PARAPET_H - 0.09), (0.30, length, 0.18), slot)
    if chevrons:
        # benzi rosii pe coama, la ~2 m: semnalizare de curba oarba
        n = max(int(length / 2.0), 1)
        for i in range(n):
            yy = y0 + length * (i + 0.5) / n
            b.box((x + sgn * 0.11, yy, z + PARAPET_H - 0.09),
                  (0.32, 0.55, 0.19), KERB_RED)


def build_ramp_straight():
    """Tronson drept de 10 m: unitatea de baza a spiralei."""
    b = Builder()
    L = 10.0
    deck_slab(b, 0.0, L)
    half = ROAD_W * 0.5
    for sx in (-1.0, 1.0):
        parapet_run(b, 0.0, L, sx * (half - 0.26))
    # banda de racord (kerb) intre asfalt si parapet
    for sx in (-1.0, 1.0):
        b.box((sx * (half - 0.60), L * 0.5, 0.02), (0.36, L, 0.16), KERB)
    o = b.to_object("RampStraight")
    return o


def build_ramp_arc():
    """Tronson curb de 15° pe raza 40 m — piesa care face spirala sa se inchida.

    Se construieste ca 6 segmente drepte rotite in jurul centrului de arc:
    la 15° impartiti in 6, coarda unui segment e 17 cm pe 7 m latime, adica
    sub bevel. Un arc "adevarat" (revolve) ar costa de 3 ori mai mult si nu
    s-ar vedea diferenta.
    """
    b = Builder()
    R = 40.0
    total = math.radians(15.0)
    steps = 6
    half = ROAD_W * 0.5
    # Centrul de arc pe -X: piesa coteste la stanga, ca sa se lege cap la cap
    # cu tronsonul drept care intra pe +Y.
    cx = -R

    def at(ang, r, zz):
        return (cx + r * math.cos(ang), r * math.sin(ang), zz)

    for i in range(steps):
        a0 = total * i / steps
        a1 = total * (i + 1) / steps
        am = (a0 + a1) * 0.5
        seg_len = R * (a1 - a0) + 0.02      # mica suprapunere: fara fante
        rot = Matrix.Rotation(am, 3, "Z")
        # carosabil
        p = at(am, R, -0.06)
        b.box(p, (ROAD_W, seg_len, 0.12), ASPHALT, rotation=rot)
        # burta
        p = at(am, R, -0.24)
        b.box(p, (ROAD_W - 0.10, seg_len, 0.24), CONCRETE, rotation=rot)
        for sr in (-1.0, 1.0):
            p = at(am, R + sr * half * 0.52, -0.52)
            b.box(p, (0.55, seg_len, 0.42), CONCRETE, rotation=rot)
        # Parapete: profil in trei trepte, pe ambele margini.
        #
        # Lungimea feliei se ia pe RAZA EI, nu pe axa drumului. Cu lungimea de
        # pe axa, parapetul interior (raza mai mica, arc mai scurt) se
        # suprapune cu 16 cm si cel exterior lasa 12 cm gol — adica exact
        # balustrada rupta in blocuri din prima randare de control.
        for sr in (-1.0, 1.0):
            rr = R + sr * (half - 0.26)
            rail_len = rr * (a1 - a0) + 0.02
            b.box(at(am, rr, 0.14), (0.52, rail_len, 0.28), CONCRETE, rotation=rot)
            b.box(at(am, rr + sr * 0.06, 0.48), (0.38, rail_len, 0.42), CONCRETE,
                  rotation=rot)
            # Coama: la fiecare al doilea segment e ROSIE in loc de gri. Banda
            # de semnalizare se face din SLOTUL coamei, nu dintr-o cutie lipita
            # peste ea — o placuta in plus iese in relief si citeste ca un
            # obiect agatat, nu ca vopsea (prima randare de control).
            b.box(at(am, rr + sr * 0.10, PARAPET_H - 0.09), (0.30, rail_len, 0.18),
                  KERB_RED if i % 2 == 0 else CONCRETE, rotation=rot)
    o = b.to_object("RampArc")
    return o


def build_pillar():
    """Pilon rotund: soclu, fus cu inele de cofraj, capitel.

    Inelele orizontale nu sunt ornament — sunt urmele de cofraj ale betonului
    turnat in etape, si sunt singurul lucru care da SCARA unui cilindru gri.
    Fara ele, un pilon de 8 m si unul de 3 m arata identic.
    """
    b = Builder()
    H = 8.0
    R = 0.62
    b.cylinder((0, 0, 0.22), R + 0.34, 0.44, CONCRETE, segments=10)   # soclu
    b.cylinder((0, 0, H * 0.5 + 0.4), R, H, CONCRETE, segments=10)    # fus
    # inele de cofraj la ~2.2 m
    n = int(H / 2.2)
    for i in range(1, n + 1):
        b.cylinder((0, 0, 0.4 + H * i / (n + 1)), R + 0.05, 0.14,
                   MARBLE_GREY, segments=10)
    # capitel: evazat, ca sa primeasca tablierul
    b.frustum((0, 0, H + 0.62), R + 0.10, R + 0.55, 0.44, CONCRETE, segments=10)
    o = b.to_object("PillarRound")
    return o


def build_parapet_module():
    """Parapet mobil New Jersey de 4 m — separatorul care se muta cu macaraua."""
    b = Builder()
    L = 4.0
    b.box((0.0, 0.0, 0.16), (0.62, L, 0.32), CONCRETE)             # talpa
    b.box((0.0, 0.0, 0.55), (0.42, L, 0.48), CONCRETE)             # gat
    b.box((0.0, 0.0, 0.88), (0.26, L, 0.20), CONCRETE)             # coama
    # golurile de ridicare din talpa (doua scobituri) — se citesc ca "mobil"
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * L * 0.28, 0.10), (0.66, 0.30, 0.16), ASPHALT)
    o = b.to_object("ParapetModule")
    return o


def build_launch_ramp():
    """Rampa-kicker de la etajul 2 (brief §2, POI F): te arunca peste etajul 1.

    Panta e 14°: peste asta masina decoleaza cu botul in sus si aterizeaza pe
    spate. Suprafata de rulare e o placa inclinata continua — fara trepte,
    fiindca raza rotii cade in orice gol (memoria `suprafete-cu-goluri`).
    """
    b = Builder()
    L = 7.0
    ang = math.radians(14.0)
    rise = L * math.tan(ang)
    half = ROAD_W * 0.5
    slope_len = math.hypot(L, rise)
    rot = Matrix.Rotation(ang, 3, "X")   # urca spre +Y (sensul de mers)

    # Pana de sustinere. `prism` extrudeaza pe Y, deci conturul e in XZ si
    # umplutura trebuie construita ca felii pe Y — altfel panta iese
    # perpendiculara pe sensul de mers si carosabilul se aseaza intr-un JGHEAB
    # intre pereti (exact ce a aratat prima randare de control).
    slabs = 7
    for i in range(slabs):
        y0 = -L * 0.5 + L * i / slabs
        y1 = -L * 0.5 + L * (i + 1) / slabs
        top = rise * (i + 0.5) / slabs      # cota medie a feliei
        b.box((0.0, (y0 + y1) * 0.5, top * 0.5),
              (ROAD_W, L / slabs, max(top, 0.02)), CONCRETE)

    # suprafata de rulare: o SINGURA placa inclinata, continua (fara trepte —
    # raza rotii cade in orice gol)
    b.box((0.0, 0.0, rise * 0.5 + 0.06), (ROAD_W, slope_len, 0.14), ASPHALT,
          rotation=rot)
    # borduri laterale joase, ca sa citesti latimea in aer. Stau PE placa,
    # nu langa ea.
    for sx in (-1.0, 1.0):
        b.box((sx * (half - 0.16), 0.0, rise * 0.5 + 0.22),
              (0.30, slope_len, 0.20), KERB, rotation=rot)
    # buza de sus: banda rosu-alb, semnalul ca aici decolezi
    for i in range(6):
        b.box((-half + ROAD_W * (i + 0.5) / 6.0, L * 0.5 - 0.16, rise + 0.10),
              (ROAD_W / 6.0 * 0.8, 0.30, 0.11),
              KERB_RED if i % 2 == 0 else FOAM_WHITE)
    o = b.to_object("LaunchRamp")
    return o


def build_construction_barrier():
    """Bariera de santier: panou rosu-alb pe doua capre + lampa galbena.

    Marcheaza pasajul rotativ cand e "inchis" (brief §3). Lampa e slot
    LAVA_ORANGE — portocaliul cald e singura sursa de accent din decor si
    exact ce trebuie sa vada soferul.
    """
    b = Builder()
    W = 2.4
    # panoul, in dungi alternante
    n = 6
    for i in range(n):
        x = -W * 0.5 + W * (i + 0.5) / n
        b.box((x, 0.0, 0.78), (W / n * 0.98, 0.10, 0.30),
              KERB_RED if i % 2 == 0 else FOAM_WHITE)
    # rama panoului
    for sz in (-1.0, 1.0):
        b.box((0.0, 0.0, 0.78 + sz * 0.17), (W, 0.13, 0.06), PAINTED)
    # capre in A, la capete
    for sx in (-1.0, 1.0):
        x = sx * (W * 0.5 - 0.18)
        for sy in (-1.0, 1.0):
            b.beam((x, sy * 0.30, 0.0), (x, 0.0, 0.62), 0.09, PAINTED)
    # lampa de santier pe un capat
    b.cylinder((W * 0.5 - 0.10, 0.0, 1.06), 0.05, 0.26, PAINTED, segments=6)
    b.box((W * 0.5 - 0.10, 0.0, 1.26), (0.20, 0.16, 0.16), LAVA_ORANGE)
    o = b.to_object("ConstructionBarrier")
    return o


# --- build ------------------------------------------------------------------

clear_built()

PIECES = [
    (build_ramp_straight, "structures/ramp_straight_10m.glb", AO_DECK, "base_axis"),
    (build_ramp_arc, "structures/ramp_arc_15deg.glb", AO_DECK, "base_axis"),
    (build_pillar, "structures/pillar_round.glb", AO_DECK, "base"),
    (build_parapet_module, "structures/parapet_module.glb", AO_PROP, "base"),
    (build_launch_ramp, "structures/launch_ramp.glb", AO_DECK, "base"),
    (build_construction_barrier, "props/construction_barrier.glb", AO_PROP, "base"),
]

for fn, path, ao, origin in PIECES:
    obj = fn()
    stats = finish(obj, bevel=0.035, ao=ao, origin=origin)
    out, size = export_glb([obj], "chongqing/" + path)
    print("%-38s tris=%5d ao=%.2f..%.2f  %6.1f kB"
          % (path, stats["tris"], stats["ao_min"], stats["ao_max"], size / 1024.0))
