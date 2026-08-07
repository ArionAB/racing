"""wooden_pier.glb — pontonul de lemn din golful de sub urcarea de coasta.

Referinta: imaginea generata pentru decorul manual al urcarii (PR decor climb):
un ponton ingust de scanduri pe piloni, iesit in laguna turcoaz, cu o barca
sabani acostata la capat. Piesa care face golful sa arate LOCUIT, nu doar
frumos — aceeasi logica cu barcile din port (sectorul 2).

Geometrie, pe axe:
  - lungimea pe X (ca zidurile si parapetele: `face: "along"` aliniaza X-ul),
    originea la capatul dinspre MAL, puntea intinsa spre +X;
  - z = 0 e LINIA APEI, nu baza obiectului: puntea sta la +0.72, pilonii coboara
    pana la -1.9. Asezat cu `y = sea_level`, iese din apa exact cum trebuie —
    cine il pune nu are nevoie sa stie cat de adanci sunt pilonii.

O singura parte, `Pier_Wood`, pe clasa `wood` (UV cubic 1.2 m, ca Sabani_Hull):
scandurile puntii sunt TRANSVERSALE si cu rost intre ele — de sus (asa se vede
din masina, de pe buza falezei) puntea fara rosturi ar fi un dreptunghi maro.
"""

LENGTH = 14.0
WIDTH = 2.30
DECK_Z = 0.72        # fata puntii, peste linia apei
PLANK_W = 0.34       # scandura transversala
PLANK_GAP = 0.06     # rostul dintre scanduri, vizibil de sus
PLANK_T = 0.07
POST_T = 0.20        # sectiunea pilonului
# Pilonii coboara 4 m sub linia apei, nu 1.9: laguna e limpede (se vede nisipul
# prin ea, vezi track07 despre lagoon_depth), deci un pilon care se termina in
# apa la 2 m deasupra fundului s-ar citi ca ponton plutitor. La -4 ajung in
# fund pe toata lungimea masurata a golfului (fundul la -5.6 doar la capat).
POST_BOTTOM = -4.00
POST_STEP = 2.70     # perechi de piloni
BOLLARD_H = 0.55     # bintele de amaraj de la capat, peste punte

b = Builder()

# Pilonii: perechi la pas fix, cu capul ras deasupra puntii — la un ponton
# adevarat pilonul trece prin punte si se vede ciotul.
x = 0.55
while x < LENGTH - 0.3:
    for sy in (-1.0, 1.0):
        b.box((x, sy * (WIDTH * 0.5 - 0.14), (POST_BOTTOM + DECK_Z + 0.10) * 0.5),
              (POST_T, POST_T, DECK_Z + 0.10 - POST_BOTTOM), WOOD)
    # Traversa dintre piloni, pe care se reazema lonjeroanele.
    b.box((x, 0.0, DECK_Z - PLANK_T - 0.10),
          (POST_T * 0.8, WIDTH - 0.12, 0.14), WOOD)
    x += POST_STEP

# Lonjeroanele: doua grinzi pe toata lungimea, sub scanduri.
for sy in (-1.0, 1.0):
    b.box((LENGTH * 0.5, sy * (WIDTH * 0.5 - 0.30), DECK_Z - PLANK_T - 0.005),
          (LENGTH, 0.14, 0.16), WOOD)

# Puntea: scanduri transversale cu rost. Nu un box pe toata lungimea — rostul
# e ce citeste "ponton" de la 20 m deasupra.
x = PLANK_W * 0.5
while x < LENGTH:
    b.box((x, 0.0, DECK_Z - PLANK_T * 0.5), (PLANK_W, WIDTH, PLANK_T), WOOD)
    x += PLANK_W + PLANK_GAP

# Bintele de amaraj de la capatul din larg, usor inclinate in afara.
for sy in (-1.0, 1.0):
    b.beam((LENGTH - 0.45, sy * (WIDTH * 0.5 - 0.18), DECK_Z),
           (LENGTH - 0.38, sy * (WIDTH * 0.5 + 0.02), DECK_Z + BOLLARD_H),
           (0.16, 0.16), WOOD)

obj = b.to_object("Pier_Wood")
# AO: intuneric jos la linia apei, deschis pe punte — gradientul vertical face
# pilonii sa se citeasca uzi fara nicio textura in plus.
stats = finish(obj, bevel=0.025, origin="none",
               ao=dict(samples=24, dist=1.8, gradient="vertical",
                       low=0.45, high=1.0, power=0.8, floor=0.20,
                       # Cu 5 cm sub baza reala: la z_lo exact, eroarea de
                       # virgula flotanta face t negativ si t**0.8 complex.
                       z_range=(POST_BOTTOM - 0.05, DECK_Z + 0.2)))
cube_uvs(obj, 1.2)
d = obj.dimensions
print("Pier_Wood  %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
      % (stats["tris"], stats["ao_min"], stats["ao_max"], d.x, d.y, d.z))
print("GLB:  %s (%d B)" % export_glb([obj], "wooden_pier.glb"))
print("BLEND: %s (%d B)" % save_blend([obj], "wooden_pier.blend"))
