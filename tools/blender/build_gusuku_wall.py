"""gusuku_wall.glb — zidul de castel Ryukyu (Urcarea gusuku, sectorul 4).

NU e in foaia de referinta — semnalat ca lipsa in PR #91, deci forma vine din
gusuku-urile reale (Nakagusuku, Zakimi), nu dintr-o plansa.

Trei lucruri fac un zid gusuku recunoscibil, si toate trei sunt aici:

1. **Bataia (batter).** Peretele nu e vertical: se inclina spre interior cu
   ~12°. E ce il face sa arate masiv si sa reziste la cutremur, si e prima
   diferenta fata de "un gard de piatra".
2. **Zidarie POLIGONALA nepotrivita** (aikata-zumi). Blocurile n-au randuri
   drepte — sunt poligoane de marimi diferite, potrivite unul in altul. Aici
   iese din randuri decalate cu blocuri de latimi variabile si cu rotire mica
   pe Z; nu e chiar aikata-zumi, dar rupe grila, care e ce se vede la 30 m.
3. **Coama rotunjita, curba in plan.** Zidurile gusuku curbeaza continuu; un
   segment drept lipit de altul drept da un poligon, nu un castel.

Trei segmente, toate de 8.0 m COARDA (nu lungime de arc): asa pot fi asezate pe
o grila de 8 m indiferent de cat curbeaza.

  Gusuku_Wall_A  curbura lina, 2.6 m
  Gusuku_Wall_B  curbura inversa, 3.0 m — se alterneaza cu A ca sa iasa serpuit
  Gusuku_Wall_C  capat cu bastion mai inalt (3.6 m), pentru inceput/sfarsit

Clasa de material: `stone_wall` pe UV cubic 1.6 m — aceeasi ca soclul portii si
al farului, deci zidul nu adauga niciun material la bugetul pistei.
"""

import math
from mathutils import Vector, Matrix

CHORD = 8.0          # contract: segmentele se aseaza pe o grila de 8 m
BATTER = 0.20        # cat se retrage peretele pe fiecare metru de inaltime
COURSES = 6          # randuri de blocuri


def wall(b, height, bow, seed, bastion=False):
    """Un segment: blocuri individuale pe randuri, cu bataie si curbura.

    `bow` e sageata curbei in metri (pozitiv = burta spre +Y). Blocurile se
    aseaza pe arc, deci fetele lor raman tangente la curba — un zid curbat din
    cutii aliniate pe axa ar fi aratat ca o scara in plan.
    """
    rnd = _lcg(seed)
    for c in range(COURSES):
        t_lo = c / float(COURSES)
        t_hi = (c + 1) / float(COURSES)
        z0, z1 = height * t_lo, height * t_hi
        # Bataia: cu cat randul e mai sus, cu atat peretele e mai subtire.
        depth = 1.05 - BATTER * z0 * 0.5
        # Randurile sunt decalate cu jumatate de bloc si au blocuri de latimi
        # DIFERITE per rand: doua randuri identice decalate tot grila raman.
        n = 6 + (c % 3)
        phase = rnd() * 0.5
        for i in range(n):
            u0 = (i + phase * (c % 2)) / float(n)
            u1 = (i + 1 + phase * (c % 2)) / float(n)
            if u0 >= 1.0:
                continue
            u1 = min(u1, 1.0)
            um = (u0 + u1) * 0.5
            x = (um - 0.5) * CHORD
            # Arc de cerc aproximat cu o parabola — la sageti de sub 1 m fata de
            # o coarda de 8 m, diferenta e sub un centimetru.
            y = bow * (1.0 - 4.0 * (um - 0.5) ** 2)
            dy_dx = bow * -8.0 * (um - 0.5) / CHORD
            yaw = math.atan(dy_dx)
            w = (u1 - u0) * CHORD * (0.90 + rnd() * 0.08)
            h = (z1 - z0) * (0.88 + rnd() * 0.10)
            b.box((x, y, (z0 + z1) * 0.5),
                  (w, depth * (0.90 + rnd() * 0.14), h), CORAL_SAND,
                  rotation=Matrix.Rotation(yaw + (rnd() - 0.5) * 0.05, 3, "Z"))
    # Coama: o banda continua peste ultimul rand, putin mai lata. Fara ea,
    # varful zidului e un sir de blocuri si se vede ca e generat.
    steps = 10
    for i in range(steps):
        um = (i + 0.5) / steps
        x = (um - 0.5) * CHORD
        y = bow * (1.0 - 4.0 * (um - 0.5) ** 2)
        yaw = math.atan(bow * -8.0 * (um - 0.5) / CHORD)
        b.box((x, y, height + 0.09), (CHORD / steps * 1.04,
                                      1.05 - BATTER * height * 0.5 + 0.12, 0.18),
              CORAL_SAND, rotation=Matrix.Rotation(yaw, 3, "Z"))
    if bastion:
        # Bastionul de capat: un bloc mai inalt, cu propria coama. Marcheaza
        # inceputul zidului in loc sa-l lase taiat in aer.
        b.box((CHORD * 0.5 - 0.85, bow * 0.05, height * 0.5 + 0.35),
              (1.70, 1.30, height + 0.70), CORAL_SAND)
        b.box((CHORD * 0.5 - 0.85, bow * 0.05, height + 0.79),
              (1.94, 1.52, 0.18), CORAL_SAND)


AO_SPEC = dict(samples=26, dist=2.4, gradient="vertical",
               low=0.44, high=1.0, power=0.85, floor=0.16)

# (nume, inaltime, sageata curbei, seed, bastion)
SEGMENTS = [
    ("Gusuku_Wall_A", 2.60, 0.55, 17, False),
    ("Gusuku_Wall_B", 3.00, -0.70, 29, False),
    ("Gusuku_Wall_C", 3.60, 0.30, 41, True),
]

clear_built("Gusuku_Wall_")
built = []
for i, (name, h, bow, seed, bastion) in enumerate(SEGMENTS):
    b = Builder()
    wall(b, h, bow, seed, bastion)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.045, ao=AO_SPEC)
    cube_uvs(obj, 1.6)
    built.append(obj)
    d = obj.dimensions
    print("%-16s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "gusuku_wall.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "gusuku_wall.blend"))
for i, o in enumerate(built):
    o.location = (0.0, i * 4.0, 0.0)
