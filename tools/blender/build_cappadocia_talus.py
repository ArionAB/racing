"""Cappadocia — GROHOTIS: conul de moloz care INGROAPA talpa peretelui.

  cappadocia/rocks/talus_block.glb    bloc de ~1.6 m, baza conului
  cappadocia/rocks/talus_cobble.glb   bolovan de ~0.8 m, mijlocul pantei
  cappadocia/rocks/talus_gravel.glb   plac de pietris de ~3 m, acostament

De ce exista fisierul asta (verdictul rundei 2, criticul D): "talpa peretelui e
o curba desenata cu rigla". Linia unde malul intalnea terenul era o curba
continua, neintrerupta, si citea ca o taietura de bisturiu — orice peisaj real
are acolo un con de grohotis care ACOPERA imbinarea.

Trei piese, nu una, fiindca cerinta e un GRADIENT de marime: blocuri de ordinul
metrului la baza, pietris pe acostament. Un singur asset scalat da acelasi
contur repetat si citeste ca stampila; trei siluete distincte plus rotatie pe Z
sparg repetitia. `talus_gravel` e deliberat un PLAC turtit (squash mic,
flat_top): la marimea aia bolovanii individuali nu se mai citesc de la 20 m, se
citeste doar o suprafata granulara mai inchisa la valoare decat nisipul.

Sloturile sunt cele existente ale temei (regula CLAUDE.md: fara sloturi noi) —
tuf umbrit si roca, adica exact familia peretelui de deasupra, fiindca
grohotisul E peretele cazut.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_talus.py
"""

import math
from mathutils import Matrix, Vector

AO_TALUS = dict(samples=16, dist=3.0, gradient="vertical",
                low=0.30, high=1.00, power=1.05, floor=0.10)

# SLOTUL E CORAL_SAND, ca tot tuful temei — si asta e o CORECTIE masurata, nu
# o preferinta. Prima versiune folosea SAND_SHADOW + ROCK_DARK; pe captura de
# sofer la 0.64 grohotisul a iesit PORTOCALIU, citind ca scanduri, nu ca roca.
# Motivul e scris chiar in tema (track.gd, "cappadocia"): SAND_MID/#D4994D e
# ocru saturat si a fost respins explicit pentru tuf, iar memoria
# `rock-dark-nu-pe-bazalt` spune ca ROCK_DARK vireaza spre rugina.
#
# Grohotisul E peretele cazut, deci trebuie sa fie din exact acelasi material,
# doar mai INTUNECAT — iar intunecarea vine din vertex color (memoria
# `surfacetool-clamp-vertex-color`: vertex color poate doar sa scada), nu
# dintr-un al doilea slot. De aia toate piesele stau pe CORAL_SAND si isi iau
# valoarea din AO.
TUFF = CORAL_SAND
TUFF_SH = CORAL_SAND
ROCK_L = CORAL_SAND
ROCK_D = CORAL_SAND


def build_talus_block():
    """Blocul de la baza: ~1.6 m, fatetat, cu straturi orizontale vizibile.

    Astea sunt cele care trebuie sa se vada individual de pe sosea, deci au
    `strata_slots` — dunga de valoare le da volum fara niciun triunghi in plus.
    """
    b = Builder()
    b.rock((0.0, 0.0, 0.62), (1.75, 1.45, 1.25), TUFF_SH, seed=13,
           segments=7, rings=4, taper=0.30, flat_top=True,
           strata_slots=(TUFF_SH, ROCK_D, TUFF_SH, ROCK_L))
    # un al doilea bloc mai mic, rezemat: perechea citeste ca prabusire, nu ca
    # piatra asezata de om
    b.rock((0.95, -0.55, 0.34), (0.95, 0.85, 0.68), ROCK_D, seed=29,
           segments=6, rings=3, taper=0.38)
    return b.to_object("Talus_Block")


def build_talus_cobble():
    """Bolovanul de mijloc: ~0.8 m, trei bucati intr-un grup."""
    b = Builder()
    rand = _lcg(77)
    for (dx, dy, s) in ((0.0, 0.0, 1.00), (0.72, 0.38, 0.68), (-0.55, 0.44, 0.55)):
        h = 0.46 * s
        b.rock((dx, dy, h * 0.5), (0.92 * s, 0.80 * s, h), TUFF_SH,
               seed=int(rand() * 900), segments=6, rings=3, taper=0.42)
    return b.to_object("Talus_Cobble")


def build_talus_gravel():
    """Placul de pietris: 3 m turtit, o SUPRAFATA nu niste pietre.

    flat_top + squash mic: la 20 m nu se mai vad pietre, se vede o pata de
    valoare mai inchisa care rupe nisipul continuu. Aia e treaba lui.
    """
    b = Builder()
    b.rock((0.0, 0.0, 0.11), (3.10, 2.30, 0.26), TUFF_SH, seed=101,
           segments=8, rings=3, taper=0.16, squash=0.55, flat_top=True,
           strata_slots=(TUFF_SH, ROCK_D))
    b.rock((1.35, 0.70, 0.09), (1.40, 1.15, 0.20), ROCK_D, seed=137,
           segments=6, rings=2, taper=0.20, squash=0.60, flat_top=True)
    return b.to_object("Talus_Gravel")


results = []


def emit(obj, path, ao, origin="base", bevel=0.03):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


emit(build_talus_block(), "rocks/talus_block.glb", AO_TALUS)
emit(build_talus_cobble(), "rocks/talus_cobble.glb", AO_TALUS)
emit(build_talus_gravel(), "rocks/talus_gravel.glb", AO_TALUS)

print()
for path, tris, kb in results:
    print("%-40s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL grohotis: %d tris" % sum(t for _, t, _ in results))
