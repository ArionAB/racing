# Inventar — kitul Okinawa v2 (Track20)

Contract: `docs/asset_briefs/okinawa_kit_v2.md`. Cotele sunt MASURATE din GLB
(`verify_glb.py`, `measure_gap.py`; Godot Y-up, Blender +Y = Godot -Z).
Build: `tools/blender/build_okinawa_castle.py` (vocabular: `okinawa_shapes.py`).
Verdict: `bash tools/blender/verify_okinawa_v2.sh` -> `VERDICT KIT: OK`.

## structures/ryukyu_gate.glb (PILOT, revizia 4 — ierarhia de acoperisuri, ceruta de coordonator)

| nod | slot | tri |
|---|---|---:|
| `Gate_Lacquer` | KERB_RED 7 | 1128 |
| `Gate_Roof` | TILE_TERRACOTTA 23 (un singur material, nervuri de olane in relief) | 17736 |
| `Gate_Mortar` | FOAM_WHITE 22 (DOAR coama, muchiile de colt si bordura streasinii) | 3432 |
| `Gate_Limestone` | MARBLE_GREY 29 (cele 4 socluri) | 352 |
| `Gate_Gold` | CAR_YELLOW 16 (panouri, console, ornamente; `--allow-car-slots=Gate_Gold`) | 928 |
| total | `VERDICT KIT: OK`, `--origin=assembly`, scala/rotatia aplicate pe radacini | 23576 |

Cote masurate: **23,76 m** lat (X) x **5,97 m** adanc (Y) x **14,70 m** inalt
(varful ornamentelor; coama centralului la ~13,1 m); h/l = 0,62. Streasina centrala
~9,7 m, cele laterale ~7,0 m. Origine: ansamblu centrat pe XY, baza la 0. Poarta e
simetrica fata/spate. Triunghiurile cresc fata de runda 3 (11.236) din nervurile de
olane (pas 0,2 m) — raportat, fara plafon; verify are bugetul 40.000.

### CONTRACT INGHETAT: golul portii (`measure_gap.py`, proiectie pe plan, grila 5 cm)

Masurat pe GLB-ul exportat, TOATE nodurile, pe fereastra caroseriei (identic cu
rundele anterioare, nu s-a schimbat din rev. 3):

- **gol lateral, banda y 0,15-2,0 m: 14,35 m** (x -7,18..+7,17; contract >= 14,0)
- **inaltime libera pe tot golul: 6,20 m** (contract >= 6,0) — grinda de jos (z 6,2-6,9)
  e minimul; peste ea: grinda de sus (8,1), panoul, acoperisul central (streasina
  ~9,7) si streasinile laterale (>= 6,85 m, intra peste |x| 5,5..7,2)
- **gol util (inaltime >= 6 m): 14,35 m**
- drumul are +-6,0 m: marja laterala ~1,2 m pe parte.
Orice modificare a portii se re-masoara (`verify_okinawa_v2.sh` pica sub contract).

### Fidelitate

Comparatia: `docs/asset_briefs/img/okinawa_fidelity/ryukyu_gate.png` (decupare |
randare din GLB, 3/4 din fata, culoare reala; `Gate_Roof` randat pe tinta
`#B8452E` din brief — **rosul olanelor vine din clasa `roof_tiles` la integrare**,
slotul 23 e portocaliu-pal), 4 azimuturi: `ryukyu_gate_views.png`.
Runde: 1-3 (constructor), **4 = ceruta de coordonator** (ierarhie, panta, olane,
grinzi duble, console aurii).

| element | pe planșă | în GLB (rev. 4) | verdict |
|---|---|---|---|
| stâlpi | 2+2 vizibili, pe socluri | 8 (4/parte: interior+exterior x fata/spate), r 0,5, pe 4 socluri de calcar | OK; interiorii la +-7,85 (golul de contract), nu +-4,5 ca in desen |
| acoperis central | bloc inalt si scurt, ~55% din latime | 17,2 m lat (~72% din 23,8: trebuie sa acopere stalpii interiori la 7,85), 5,5 m adanc, streasina 9,7, coama ~13,1, panta abrupta (rise 3,4 / hv 2,75), coama scurta (R 3,5), colturi +1,0 | mai apropiat; abatere: ~72% nu 55%, stalpii interiori sunt sub el |
| acoperisuri laterale | mari (~35% fiecare), mai jos, sub streasina centralului | 6,2 x 5,6 m fiecare (~26%), x 5,5..11,7, streasina 7,0, piramida +2,0, colturi +0,8, se suprapun sub streasina centrala | OK ca ierarhie (etaj 2 clar); abatere: ~26%, nu 35% |
| streasini | curbe vizibile in sus la colturi | colturi ridicate (+1,0 / +0,8), profil concav | OK |
| olane | randuri dese de nervuri in culoarea olanelor | nervuri in relief 9 cm, pas ~0,4 m, in `Gate_Roof`; fara dungi albe pe panta | OK |
| alb | doar coama, muchii de colt, bordura streasinii | exact acestea (`Gate_Mortar`) | OK |
| grinzi + panou | doua grinzi orizontale cu panou gol intre ele | grinda jos 6,2-6,9, sus 8,1-8,8, panou intre ele pe fiecare fata: rama rosie, fond auriu, GOL, fara text | OK; panoul se citeste ca banda aurie lata (planșa il are decorat si mai mic) |
| console | aurii | aurii (`Gate_Gold`), 3 trepte sub fiecare streasina; al doilea nivel pe stalpii interiori sub streasina laterala | OK |
| ornamente aurii | 2 sus + cate unul pe fiecare coama laterala | 2 pe coama de sus (1,4x) + 2 pe varful piramidelor laterale (0,9x); bila+flacara, nu floare | OK ca numar/pozitie, forma simplificata |
| socluri | 4, calcar, evazate | 4, 2,7 x 1,7 x 1,3 m, MARBLE_GREY | OK |
| text, asfalt, tufe | — / pe decupare / pe decupare | fara text; nu intra in GLB | OK |
| h/l | ~0,55 | 14,7/23,8 = 0,62 | la limita (+12%) |

Abateri ramase: central ~72% (nu 55%) si laterale ~26% (nu 35%) din latime — stalpii
interiori trebuie sa stea la +-7,85 sub centralul care ii acopera; ornamentele sunt
simple; stalpii exteriori sunt lungi (~6 m sub streasina laterala).

### Stare la oprire

- Pilot livrat: harnas (`okinawa_shapes.py`, `preview_okinawa.py`,
  `verify_okinawa_v2.sh`) + `ryukyu_gate`. `VERDICT KIT: OK`, gol 14,35 m / 6,20 m (rev. 4).
- `okinawa_shapes.py` are `HipRoof` (reutilizabil: palat, case, refugiu),
  `lacquer_pillar`, `bracket`, `stone_plinth`, `gold_finial`, `limestone_wall`
  (talus; NETESTAT in GLB, doar API), `emit_ok`.
- Nu e facut: palatul, zidurile gusuku (valul 1); `limestone_wall` nu a fost
  exersat pe o piesa. Clasele (`ok_limestone`, `ok_lacquer`, `roof_tiles`) si
  coliziunea sunt ale coordonatorului.


## val 1, ok-a: castelul (palat + ziduri gusuku)

Build: `build_okinawa_castle.py` (`OK_ONLY=<piesa>` reface una). Vocabular nou in
`okinawa_shapes.py` (la final): `inset_convex`, `banded_prism`, `slab_grid`, `karahafu`,
`gold_dragon`, `gusuku_wall`, `gusuku_n`, `arch_blocks`, `prism_yz`, `wall_to_roof`.
Singura schimbare la o functie existenta: `stone_plinth(..., z0=0.0)` (parametru nou la
sfarsit, compatibil). Comparatii: `img/okinawa_fidelity/{ryukyu_palace,gusuku_wall_curve,
gusuku_wall_straight,gusuku_arch_gate}.png`.

### buildings/ryukyu_palace.glb — 41.084 tri, 32,01 x 18,31 x 16,75 m (h/l 0,52)

| nod | slot | tri |
|---|---|---:|
| `Palace_Lacquer` | KERB_RED 7 | 3908 |
| `Palace_Roof` | TILE_TERRACOTTA 23 | 28188 |
| `Palace_Mortar` | FOAM_WHITE 22 | 4992 |
| `Palace_Limestone` | MARBLE_GREY 29 | 1742 |
| `Palace_Gold` | CAR_YELLOW 16 (`--allow-car-slots=Palace_Gold`) | 598 |
| `Palace_Wood` | WOOD 9 + LOG_DARK 28 | 1656 |

Platforma 2,5 m, scara pe +Y (9 trepte), 12 coloane pe fata, doua acoperisuri in patru ape
(streasini 6,3 / 11,0 m, coama ~14,4 m), karahafu peste intrare, 2 dragoni de coama.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| platformă | zid înalt de piatră (~35% din h) cu scară și cheeks | 2,5 m (15% din h, contract), 3 asize, parapet, scară 6 m cu obraji | abatere: mult mai joasă (cota de contract) |
| etaj jos | sală roșie cu uși/ferestre, coloane | pereți roșii, ușă dublă, 4 ferestre/parte, 12 coloane | OK |
| acoperiș jos | larg, streașină ridicată, olane | 31,2 x 12,8 m, ridicare colțuri 0,8 m, coame albe | OK; curbura colțurilor mai teatrală decât pe planșă |
| fronton karahafu | curbat, ornament auriu | 7,6 m, margine în S, panou roșu, bordură albă, ornament | OK (ornament simplificat) |
| etaj sus + acoperiș | acoperiș înalt, coamă scurtă | pereți roșii 5 ferestre, coamă R 4,2, rise 3,4 | OK, mai turtit decât desenul |
| dragoni | 2 aurii pe capetele coamei, voluminoși | 2, ~1,7 m, S în sus, cap spre exterior | OK ca poziție; mai subțiri decât pe planșă |
| pavilioane laterale mici | 2 | nu sunt | abatere (nelistate în contract) |
| tufe, copaci | pe decupare | nu intră | OK |

### Runda 4, ceruta de coordonator: zidariile refacute (zidurile si poarta boltita)

Coordonatorul a respins prima varianta (4 asize de ~2 m, umbrire moale, bulb rotunjit, bolta mica).
Acum, pe `gusuku_wall`: **miez** cu sectiune identica (talus pe +X, creasta PLATA cu capac iesit 10 cm,
colturi rotunjite doar in plan) + **blocuri fasonate pe ambele fete**: 11 asize de 0,6-0,8 m, blocuri de
0,8-1,5 m decalate pe randuri, perne cu fete plate, rost 5 cm si relief 4-7 cm, usor neregulate (jitter
de 1,5 cm). **Umbrire plata** (`smooth_angle=None`, fete plate, ca la Monument Valley). Pe randurile pare
blocurile de la capete nu au rost spre capat (doua module vecine fac un bloc continuu), pe cele impare au:
imbinarea e decalata ca restul zidariei. Nu am implementat blocul inalt cat doua asize (deviatie).

### structures/gusuku_wall_curve.glb — 6.872 tri (A 3436, B 3436), 4,25 x 17,04 x 8,0 m

Doua radacini: `Wall_A_Limestone` (R 20 m) si `Wall_B_Limestone` (R 40 m, mutat +10 m pe X); numele nu pot
fi ambele `Wall_Limestone` (nume unice in Blender), se termina in `_Limestone` (clasa pe sufix). Origine =
mijlocul corzii, baza la 0. Capete la (0, +-8), plane, perpendiculare pe tangenta (rotita +-23,58 deg la A,
+-11,54 deg la B).

### structures/gusuku_wall_straight.glb — 2.556 tri, 2,64 x 12,0 x 8,0 m
Nod `Wall_Limestone`; capete la y = +-6.

### Capete identice, MASURATE pe GLB (`tools/blender/measure_okinawa_castle.py`)
Vertecsii din planul fiecarui capat (perpendicular pe tangenta) au fost comparati cu cele 8 puncte ale
sectiunii de miez (baza 2,5 m, creasta ~1,65 m + capac 0,1 m pe parte, 8 m): drept (+/-), curb A (+/-),
curb B (+/-): **abatere maxima 0,00000 m** pe toate cele 6 capete (136 vertecsi in plan fiecare).
Captura de lant (drept + A + B + drept, 3/4): `img/okinawa_fidelity/gusuku_wall_chain.png`, imbinarile
nu se vad, zidul se citeste ca unul singur.

### structures/gusuku_arch_gate.glb — 2.788 tri (Arch_Limestone 2548, Arch_Wood 240), 3,31 x 14,0 x 8,0 m
Deschidere **~5,5 x 5,5 m** (decizia coordonatorului, runda 4; contractul initial: 4 x 4,5 m): semicerc
r 2,8 pe linia de nastere de 2,75 m, tunel taiat boolean pe axa X; 11 bolțari (r 2,75-3,55 + cheie),
4+4 blocuri de sambure, canat din doua aripi (una inchisa, una ~40 deg spre -X). Canatul e decor, nu
intra in gol. **`measure_gap.py`** pe copia rotita (doar piatra, tunel pe Y), banda 0,15-2,0 m:
**gol lateral 5,45 m** (x -2,70..+2,75; grila de 5 cm), inaltime libera la axa **5,5 m** (la margini
2,75 m = linia de nastere, e semicerc), mediana 5,05 m.

| element | pe planșă | în GLB (runda 4) | verdict |
|---|---|---|---|
| asize | 10-12, blocuri ~0,6-0,8 m x 0,8-1,5 m, decalate | 11 asize 0,6-0,8 m, blocuri 0,8-1,5 m decalate, jitter | OK; lipsesc blocurile inalte pe doua asize |
| rosturi | in relief, prind umbra | 5 cm rost, 4-7 cm relief, perne cu fete plate | OK |
| umbrire | plata | fete plate, fara smooth | OK |
| creasta | plata, margine usor iesita | plata + capac iesit 10 cm | OK |
| colțuri | rotunjite in plan | rotunjite in plan (arc) ; capetele drepte, cerinta de inlantuire | OK |
| talus | ~8 deg | ~5,4 deg pe fata exterioara (grosimile de contract) | abatere minora |
| bolta | ~40% din lungime, ~60% din inaltime | 5,5/14 = 39%, 5,5/8 = 69% (cu cheia 6,5 m) | OK |
| bolțari | perne in relief, scara zidariei | 11, aceeasi perna | OK |
| vegetatie, dalaj, bolovani | pe decupare | nu intra | OK |
