"""wave_surge.glb — valul care matura causeway-ul (WAVE_SURGE, 1.8 m).

Referinta: assets/okinawa_inspiration/, randul HAZARD OBJECTS. Modelul pentru
hazardul de pe sectorul 8 (#106): un val care trece lateral peste sosea, cu
creasta care se rastoarna si spuma in fata.

NUMELE `Wave` E CONTRACT, la fel ca `Blades` la moara: `scenes/props/wave_surge.gd`
cauta nodul dupa nume ca sa-i anime creasta si sa-i lege faza de banda uda.
`Wave_Foam` e piesa alba din fata; e separata ca sa poata pulsa independent.

Forma: creasta care se rastoarna, adica peretele din fata e mai ABRUPT decat
spatele si varful se apleaca inainte. Un val simetric citeste ca o dune de
nisip albastra. Sectiunea se construieste direct pe bmesh — profilul se schimba
pe lungime (creasta se rastoarna mai tare la mijloc decat la capete), deci nici
`revolve` nici `prism` nu-l pot da.

Cote: 1.8 m inaltime (foaia de referinta), 6.0 m latime. Raportul conteaza mai
mult decat latimea absoluta — scriptul il scaleaza oricum pe latimea soselei.
La 9 m, cat avea prima versiune, valul iesea o movila lunga si joasa; la 6 m
(1:3.3) se citeste ca val si de la 60 m.

Sloturi: REEF_SHALLOW pentru corp (turcoazul de peste recif), FOAM_WHITE pentru
creasta si spuma. Fara textura de clasa: apa isi ia aspectul din shaderul
pistei, iar stratul de detaliu e o textura de ROCA — pe apa face noroi
(style_bible §4, masca per slot).
"""

import math
from mathutils import Vector

WIDTH = 6.00
HEIGHT = 1.80
DEPTH = 2.60         # cat de "gros" e valul pe directia de inaintare
SPANS = 13           # sectiuni pe latime


def _profile(u):
    """Cotele profilului la fractiunea u pe latime (0..1).

    `curl` = cat de tare se rastoarna creasta. Maxim la mijloc, aproape zero la
    capete: asa valul are un CENTRU, si centrul e ce urmareste ochiul cand
    matura soseaua.
    """
    # Capetele coboara: valul se stinge, nu se termina taiat.
    fade = math.sin(math.pi * u) ** 0.55
    h = HEIGHT * fade
    curl = math.sin(math.pi * u) ** 2
    return h, curl


def wave(b):
    """Corpul valului: sapte puncte per sectiune, de la baza din spate pana la
    baza din fata, trecand PE SUB buza crestei.

    Cheia e ca buza (punctul 3) sta mai in FATA decat scobitura de sub ea
    (punctul 4): asa iese o consola reala, adica un val care se sparge. Prima
    versiune avea creasta doar impinsa inainte, fara scobitura, si — cu
    netezire pe 55° peste ea — se randa ca o cupola turcoaz neteda. Silueta de
    val vine din CONCAVITATEA de sub buza, nu din inaltime.
    """
    rings = []
    for i in range(SPANS):
        u = i / float(SPANS - 1)
        h, curl = _profile(u)
        x = (u - 0.5) * WIDTH
        # y negativ = spre directia in care merge valul (fata).
        ring = [
            (x, DEPTH * 0.50, 0.0),                              # coada
            (x, DEPTH * 0.14, h * 0.45),                         # panta lina
            (x, -DEPTH * 0.05, h * 0.88),                        # umar
            (x, -DEPTH * (0.15 + 0.35 * curl), h),               # buza crestei
            (x, -DEPTH * (0.05 + 0.13 * curl), h * 0.60),        # scobitura
            (x, -DEPTH * 0.30, h * 0.24),                        # perete
            (x, -DEPTH * 0.50, 0.0),                             # baza din fata
        ]
        rings.append([b.bm.verts.new(p) for p in ring])

    new_verts = [v for r in rings for v in r]
    for lo, hi in zip(rings, rings[1:]):
        for k in range(len(lo) - 1):
            b.bm.faces.new((lo[k], lo[k + 1], hi[k + 1], hi[k]))
    # Fundul: valul e vazut si de sus, de pe pod, deci nu poate fi o coaja
    # deschisa — s-ar vedea prin el (backface culling).
    for lo, hi in zip(rings, rings[1:]):
        b.bm.faces.new((lo[-1], hi[-1], hi[0], lo[0]))
    b.bm.faces.new(tuple(rings[0]))
    b.bm.faces.new(tuple(reversed(rings[-1])))
    faces = b._tag(new_verts, REEF_SHALLOW)
    # Creasta alba: retag pe fetele de sus, in loc de geometrie noua. Costa zero
    # triunghiuri si e exact ce face `strata_slots` la stanci.
    b.retag(faces, FOAM_WHITE,
            where=lambda c, n: c.z > HEIGHT * 0.52 and n.z > -0.2)


def foam(b):
    """Limba de spuma din fata valului: bulgari turtiti, aliniati pe latime.

    Piesa separata ca sa poata fi pulsata de script independent de corp —
    telegrafierea hazardului (#106) e un puls de spuma, nu o miscare de val.
    """
    rnd = _lcg(29)
    n = 9
    for k in range(n):
        u = (k + 0.5) / n
        h, curl = _profile(u)
        x = (u - 0.5) * WIDTH
        s = (0.55 + rnd() * 0.35) * (0.45 + curl)
        # Jitter generos pe toate trei axele: aliniate frumos, bulgarii citeau
        # ca un rand de dinti, nu ca spuma.
        b.boulder((x + (rnd() - 0.5) * 0.75,
                   -DEPTH * (0.34 + rnd() * 0.34),
                   h * 0.18 + rnd() * 0.22),
                  (s * 1.7, s * 1.1, s * 0.55), FOAM_WHITE,
                  seed=29 + k * 11, segments=6, rings=3, deviation=0.22)


# Fara gradient vertical: apa nu se intuneca spre baza, s-ar citi ca murdarie.
# Dar OCLUZIA GEOMETRICA ramane pornita, si e singurul lucru care face consola
# de sub buza sa se vada — un val cu AO uniform e o cupola colorata.
AO_SPEC = dict(samples=24, dist=2.2, gradient="none", floor=0.52)

clear_built("Wave")
built = []
for name, fill in (("Wave", wave), ("Wave_Foam", foam)):
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    # Fara bevel: suprafata de apa n-are muchii de tesit, iar creasta trebuie sa
    # ramana ascutita — bevel-ul ar rotunji exact silueta care telegrafiaza.
    # `smooth_angle=20` din acelasi motiv: la 55° (implicit) buza crestei se
    # topea in umar si tot valul se randa ca o cupola neteda.
    stats = finish(obj, bevel=0.0, origin="base_axis", ao=AO_SPEC,
                   smooth_angle=20.0)
    built.append(obj)
    d = obj.dimensions
    print("%-12s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "wave_surge.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "wave_surge.blend"))
