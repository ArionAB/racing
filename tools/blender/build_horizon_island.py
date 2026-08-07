"""horizon_island.glb — siluetele de insula de la orizont (Okinawa).

Inlocuiesc butte-urile de desert pentru tema `island`. Rolul lor e cel din
style_bible §7: repere de ORIENTARE. „Sunt langa insula cu doua varfuri" trebuie
sa fie o informatie reala, deci cele trei siluete sunt DELIBERAT diferite ca
forma, nu trei marimi ale aceleiasi movile.

  Island_Low     42 x 9 m  — insula plata, ca un banc de nisip cu vegetatie
  Island_Peak    30 x 26 m — con vulcanic, silueta cea mai citibila
  Island_Ridge   58 x 15 m — creasta lunga cu doua varfuri

Cotele sunt NOMINALE: `Track._build_horizon` le scaleaza cu 1.2-2.4 in functie
de inel, deci in joc ies intre 36 si 140 m latime.

Buget: fundal pur, zero coliziune, la 150-320 m de camera. Sub 250 tris fiecare
— segments 7 si rings 3, ca la butte. Orice peste atat se pierde in ceata.

Culoare: sloturile insulei prin `strata_slots` — bazalt jos (ce bate valul),
verde tropical sus. Nu primesc textura de clasa: la 200 m si prin ceata,
`fog_depth` le spala oricum spre culoarea orizontului.
"""

import math

# (nume, lungime, latime, inaltime, seed, cate movile)
ISLANDS = [
    ("Island_Low", 42.0, 26.0, 9.0, 11, 2),
    ("Island_Peak", 30.0, 24.0, 26.0, 23, 1),
    ("Island_Ridge", 58.0, 22.0, 15.0, 37, 3),
]

# Bazaltul spalat de valuri jos, vegetatia sus. Ordinea e de la inelul de jos
# in sus, deci primul slot e cel de la nivelul marii.
STRATA = (VOLCANIC_BLACK, VOLCANIC_BLACK, TROPICAL_GREEN, TROPICAL_GREEN)

AO_SPEC = dict(samples=16, dist=12.0, gradient="vertical",
               low=0.62, high=1.0, power=0.9, floor=0.35)

clear_built("Island_")
built = []
for i, (name, length, width, height, seed, humps) in enumerate(ISLANDS):
    b = Builder()
    rnd = _lcg(seed)
    for k in range(humps):
        t = 0.0 if humps == 1 else k / float(humps - 1) - 0.5
        # Movilele se insira pe axa lunga; cea din mijloc e cea mai inalta.
        h = height * (1.0 if humps == 1 else 0.62 + 0.38 * (1.0 - abs(t) * 1.4))
        b.rock((t * length * 0.42, (rnd() - 0.5) * width * 0.20, h * 0.5),
               (length * (0.55 + rnd() * 0.30), width * (0.75 + rnd() * 0.30),
                h),
               VOLCANIC_BLACK, seed=seed + k * 13, segments=7, rings=3,
               # `taper` mare: insulele vazute de departe sunt CONURI tocite, nu
               # mese cu capac plat — capacul plat e semnatura desertului si
               # exact ce trebuie sa NU semene cu butte-urile de pe Dunele.
               taper=0.62, squash=0.92, strata_slots=STRATA)
    obj = b.to_object(name)
    # Bevel de stanca (0.15 din style_bible §3), scalat la marimea reala: la
    # 40 m latime un bevel de 4 cm nu exista.
    stats = finish(obj, bevel=0.30, ao=AO_SPEC)
    built.append(obj)
    d = obj.dimensions
    print("%-16s %4d tris  AO %.2f..%.2f  bbox %.1f x %.1f x %.1f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "effects/horizon_island.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "horizon_island.blend"))
for i, o in enumerate(built):
    o.location = (i * 70.0, 0.0, 0.0)
