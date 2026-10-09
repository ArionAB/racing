# Inventar — kitul Okinawa v2 (Track20)

Contract: `docs/asset_briefs/okinawa_kit_v2.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, `measure_gap.py`; Godot Y-up, Blender +Y = Godot -Z).
Build: `tools/blender/build_okinawa_castle.py` (vocabular: `okinawa_shapes.py`).
Verdict: `bash tools/blender/verify_okinawa_v2.sh` -> `VERDICT KIT: OK`.

## structures/ryukyu_gate.glb (PILOT)

| nod | slot | tri |
|---|---|---:|
| `Gate_Lacquer` | KERB_RED 7 | 1392 |
| `Gate_Roof` | TILE_TERRACOTTA 23 (un singur material, pentru clasa roof_tiles) | 6448 |
| `Gate_Mortar` | FOAM_WHITE 22 (coama, muchii de colt, rosturi in relief) | 2160 |
| `Gate_Limestone` | MARBLE_GREY 29 (cele 4 socluri) | 352 |
| `Gate_Gold` | CAR_YELLOW 16 (`--allow-car-slots=Gate_Gold`) | 884 |
| total | `VERDICT KIT: OK`, `--origin=assembly`, scala/rotatia aplicate pe radacini | 11236 |

Cote masurate: **20,90 m** lat (X; acoperisurile laterale +-10,25, mortarul +-10,45)
x **5,60 m** adanc (Y; acoperisul de sus +-2,6, stalpii +-1,55) x **11,50 m** inalt
(varful ornamentelor; coama acoperisului de sus 9,96 m); h/l = 0,55. Origine:
ansamblu centrat pe XY, baza la 0. Fata +Y (poarta e simetrica fata/spate).

### CONTRACT INGHETAT: golul portii (`measure_gap.py`, proiectie pe plan, grila 5 cm)

Masurat pe GLB-ul exportat, TOATE nodurile, pe fereastra caroseriei:

- **gol lateral, banda y 0,15-2,0 m: 14,40 m** (x -7,20..+7,20; contract >= 14,0)
- **inaltime libera pe tot golul: 6,20 m** (contract >= 6,0) — buiandrugul rosu
  (z 6,2-6,9) e singurul element sub coama, mediana tot 6,20
- **gol util (inaltime >= 6 m): 14,40 m**
- aceeasi cifra pe ferestrele 0,15-0,6 m si 0,15-5,8 m (14,40 m): nimic nu iese
  in gol cu inaltimea (stalpii r 0,5 la x +-7,85 -> fata 7,35; soclurile incep la
  |x| = 7,2; acoperisurile laterale incep la |x| >= 7,45)
- drumul are +-6,0 m: marja laterala 1,2 m pe parte. Coliziunea `mesh` pe stalpi,
  golul liber.
Orice modificare a portii se re-masoara (`verify_okinawa_v2.sh` pica sub contract).

### Fidelitate

Comparatia: `docs/asset_briefs/img/okinawa_fidelity/ryukyu_gate.png` (decupare |
randare din GLB, 3/4 din fata, culoare reala), 4 azimuturi: `ryukyu_gate_views.png`.
3 runde facute (azimut/elevatie schimbate la runda 3 ca sa se vada panoul).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| stâlpi | 2+2 vizibili, grupati, pe socluri | 8 (4/parte: interior+exterior x fata/spate), r 0,5, pe 4 socluri de calcar | OK; pe decupare stalpii par la +-4,5 m, in GLB la +-7,85/9,05 (golul de contract) |
| treapta de sus | un acoperis mare in patru ape, deasupra grinzii, coame albe, streasini curbate | un acoperis in patru ape 18,6 x 5,2 m, coama lunga, streasina ridicata la colturi (+0,75), coama + 4 muchii albe + rosturi | abatere: mai lat si mai plat decat pe planșă (planșa il are mai mic si mai inalt, cu o a doua streasina scurta dedesubt) |
| treapta de jos | cate un acoperis lateral mare, ca palarie pe fiecare grup | cate unul pe parte, in patru ape, coama pe Y, 2,8 x 5,2 m | abatere: mult mai mici decat pe planșă; nu pot creste spre interior (golul >= +-7,2 m) iar latimea totala e fixata la ~20 m |
| streasini ridicate | colturi curbate in sus | colturi ridicate (+0,75 sus, +0,8 jos), concav spre streasina | OK |
| coame albe | coama + muchii | coama, 4 muchii de colt, rosturi in relief (Gate_Mortar) | OK; rosturile sunt mai rare si mai groase decat olanele de pe planșă |
| olane | rânduri fine rosii | ondulare 6 cm pe coloane de 30 cm in geometrie | OK ca forma; slotul 23 e portocaliu-pal (#C4784F), nu rosu: il aduce clasa roof_tiles la integrare |
| buiandrug + panou | grinda rosie transversala, panou decorat sub streasina | buiandrug 0,7 m la z 6,2, panou gol in rama (z 6,9-8,0) | abatere: panoul se vede slab din 3/4, il acopera streasina de sus (supraplinul de 2,6 m); se citeste din fata/jos |
| ornamente aurii | 2 sus + cate unul pe fiecare coama laterala; flori | 2 pe coama de sus (1,4x), 2 mici pe coamele laterale, medalion pe panou (2) | OK ca numar si pozitie; forma e bila+flacara, nu floare |
| socluri | 4, calcar, evazate | 4, 2,7 x 1,7 x 1,3 m, talpa evazata + placa de capat, MARBLE_GREY | OK |
| consolele | capete de grinda aurii | console in trepte rosii sub streasina | abatere minora: nu sunt aurii |
| panou: text | — | fara text | OK |
| h/l | ~0,55 | 11,5/20,9 = 0,55 | OK |
| asfalt, tufe | pe decupare | NU in GLB | OK |

Abateri nerezolvate dupa 3 runde: proportia treptelor (central prea larg/plat,
laterale prea mici) si panoul ascuns de streasina din unghiul 3/4. Cauza comuna:
contractul de gol (14 m) muta stalpii departe de pozitia din desen.
Nu am gasit o rezolvare fara sa incalc golul; propunere: coordonatorul decide daca
acoperisurile laterale pot coborî mai mult peste soclu (mai "palarie") sau daca
treapta de sus se ingusteaza la +-8,3 m.

### Stare la oprire

- Pilot livrat: harnas (`okinawa_shapes.py`, `preview_okinawa.py`,
  `verify_okinawa_v2.sh`) + `ryukyu_gate`. `VERDICT KIT: OK`, gol 14,40 m / 6,20 m.
- `okinawa_shapes.py` are `HipRoof` (reutilizabil: palat, case, refugiu),
  `lacquer_pillar`, `bracket`, `stone_plinth`, `gold_finial`, `limestone_wall`
  (talus; NETESTAT in GLB, doar API), `emit_ok`.
- Nu e facut: palatul, zidurile gusuku (valul 1); `limestone_wall` nu a fost
  exersat pe o piesa. Clasele (`ok_limestone`, `ok_lacquer`, `roof_tiles`) si
  coliziunea sunt ale coordonatorului.
