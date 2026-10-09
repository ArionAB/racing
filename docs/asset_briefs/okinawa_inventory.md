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

## Val 1, ok-b: coasta (`tools/blender/build_okinawa_coast.py`)

Toate sunt `VERDICT: OK` in `verify_okinawa_v2.sh` (sectiunea „val 1, ok-b”),
`--origin=assembly`, scala/rotatia aplicate pe radacini. Comparatii:
`docs/asset_briefs/img/okinawa_fidelity/<nume>.png` (+ `<nume>_views.png` pentru
notch_a, heart_rock, cliff, far); plansa: `okinawa_fidelity_val1-ok-b.png`.
Sloturi: calcar MARBLE_GREY 29, nise SAND_SHADOW 2 (benzi), iarba TROPICAL_GREEN 21.
Atentie la integrare: clasa `ok_limestone` pe `*_Limestone` suprascrie culoarea
slotului, deci banda SAND_SHADOW a nisei se pierde in joc; nisa ramane citibila
doar prin geometrie (gat ingust, buza) + AO copt. Preview-ul o arata la fel (clasa).

| piesa | cote masurate (X x Y x Z) | tri | noduri | origine / linie apei |
|---|---|---:|---|---|
| `rocks/notch_rock_a.glb` | 7,12 x 6,57 x 8,97 m (cap ~7, picior Ø3, nisa z 0,4..1,9) | 624 | Notch_Limestone 454, Notch_Grass 170 | axa piciorului pe XY, baza la Z=0; apa presupusa la z ~0,4 |
| `rocks/notch_rock_b.glb` | 8,85 x 8,45 x 5,56 m (cap ~8,8, nisa z 0,3..1,3) | 666 | idem (496 / 170) | idem, apa la z ~0,3 |
| `rocks/notch_rock_c.glb` | 8,35 x 5,74 x 6,88 m (cap deplasat 2,0 m pe +X, nisa z 0,4..1,7) | 624 | idem (454 / 170) | idem, apa la z ~0,4; aplecata spre +X |
| `rocks/heart_rock.glb` | 8,86 x 6,77 x 7,41 m (inima ~6,9 lat in X, 7,0 inalta) | 696 | Heart_Limestone | varful la Z=0, XY pe axa; apa presupusa la z ~0,9 (banda SAND_SHADOW z 0,25..1,25) |
| `rocks/limestone_cliff_module.glb` | 5,90 x 12,00 x 14,77 m | 496 | Cliff_Limestone 234, Cliff_Grass 262 | baza la Z=0 (apa la z ~0,5, pe linia nisei); spre mare = +X, capete plane la y=+-6,0 identice |
| `buildings/cape_lighthouse.glb` | 12,53 x 7,22 x 20,20 m (turn Ø3,6->2,6; casa 6x5x3,5 la +X/+Y) | 1082 | Plaster 332, Limestone 160, Metal 546, Lamp 44 | axa turnului pe XY=0, baza la Z=0 (stanca/apa nu intra) |
| `structures/coral_stone_wall.glb` | 0,90 x 4,00 x 1,31 m | 696 | Coral_Wall_Coral | centrat pe XY, baza la Z=0, capete la y=+-2,0 |

### Fidelitate (ok-b)

| piesa | element | pe planșă | în GLB | verdict |
|---|---|---|---|---|
| notch a/b/c | siluete | aproape identice (corectura: distincte) | a inalta/zvelta (h/l 1,26), b lata/joasa (0,63), c aplecata cu cap deplasat 2 m (0,82) | OK, distincte |
| notch | nisa | gat roas sub cap | gat mai ingust decat piciorul, banda SAND_SHADOW + AO | OK ca forma; culoarea nisei se pierde sub clasa |
| notch | iarba | pernă + 3 tufe pe crestet | invelis `Notch_Grass` + 3 tufe joase | abatere: tufe de forma blocuri rotunjite, nu frunziș |
| notch | facete | facete mari ca bolovani | triunghiuri low-poly (jag 0,10) | abatere: fatete mai mici si mai uniforme decat planșa |
| notch | h/l | a ~1,2 / b ~0,55 / c ~1,0 | a 1,26 / b 0,63 / c 0,82 | a OK; b +15%; c -18% (limita) |
| heart_rock | doi lobi + varf in apa | doi lobi inalti, cleft adanc | 2 lobi rotunjiti (7,0 / 6,6 m), varf r 0,45 la z 0; se citeste ca inima din cele 4 azimuturi (35/125/215/305) | OK; abatere: lobii mai netezi si mai simetrici decat planșa, 4 bolovani mici in loc de 6 |
| faleza | fateta + nisa + creastet | ~5 fete, trepte de bolovani, nisa la apa | 6 fete late 1,3..2,8 m, 6 bombari, nisa ~2 m; iarba + 4 tufe | OK; abatere: planșa e mai lata (h/l 1,1 din contract = 14/12, nu din desen), tufele nu sunt frunziș; mic artefact de triunghiulare la capatul +Y al |
| far | turn, galerie, felinar, casa | turn alb conic, galerie, felinar+cupola, casa cu acoperis rosu | toate; acoperis plat de calcar (contractul spune plat; roșul nu are slot) | OK; abatere: cupola si felinarul simplificate, fara stancile/tufele din jur |
| zid corali | pietre rotunjite | blocuri dreptunghiulare (corectura: rotunjite) | 3 randuri 6/5/8 pietre, rand de sus 8 | OK; abatere: pietrele sunt „perne” moi, rosturile (miez SAND_SHADOW) abia se vad |

Runde de comparatie: notch a/b/c 3 (impreuna), heart 3, faleza 2, far 3, zid 3.

### Stare la oprire (ok-b)

- Livrate: cele 7 piese, `VERDICT KIT: OK`. Adaugat in `okinawa_shapes.py`:
  `ring_points`, `faceted_shell`, `notch_profile`, `notch_rock`, `foot_boulders`,
  `lobe_profile`, `_ok_rand` (stanca roasa de val; reutilizabil pentru
  stancile-ciuperca si faleza). Semnaturile existente neatinse.
- Capcana: un `frustum` cu doar doua inele da AO intunecat pe tot turnul (normalele
  netezite ale capacelor); farul foloseste `revolve` cu inele intermediare.
- Neverificat: cum arata cu clasele `ok_limestone`/`coral_rock` in Godot.

### Runda 4, ceruta de coordonator (ok-b): aglomerari de blocuri + umbrire plata

Cauza comuna a respingerii: profil rotit + AO coapt pe vertex = gradient moale
(pahar / perna). Reparat: (1) `emit_ok(..., flat_ao=True)` (kwarg nou, optional):
muchiile se sparg inainte de coacere, iar AO-ul fiecarei fete = media ei, deci
fiecare fateta e un plan de o singura valoare; (2) forma din `chunk()` =
bolovani fatetati rotiti (`okinawa_shapes.py`), nu din inele rotite. Piatra,
iarba si zidul sunt umbrire plata; farul ramane neted (turn rotund). Max. 2
comparatii pe piesa in aceasta runda.

| piesa | cote (X x Y x Z) | tri | ce s-a schimbat |
|---|---|---:|---|
| notch_rock_a | 8,70 x 7,18 x 8,26 | 1502 | cap din 12 bolovani (7+4+1), picior neregulat 7 laturi, gat ~3,6 m, fusta 7+2 bolovani, 11 ciorchini de iarba pe 2 tonuri (21 / 12) |
| notch_rock_b | 8,90 x 8,05 x 5,53 | 1524 | cap din 13 bolovani (8+4+1), picior scurt gros care se largeste in cap, fusta 7+2 |
| notch_rock_c | 7,88 x 6,85 x 6,69 | 1344 | cap din 11 bolovani deplasat 2,0 m pe +X, picior aplecat (t^2), fusta 6+2 |
| heart_rock | 8,86 x 8,39 x 7,41 | 780 | umbrire plata + 6 bolovani (2 noi) |
| limestone_cliff_module | 5,72 x 12,04 x 15,03 | 1286 | masa din spate cu sectiune constanta + nisa ~2,5 m scobita 1 m; 6 coloane-bolovan jos si 5 sus care ies 0,6..1,5 m, crapaturi adanci; iarba cu 9 ciorchini |
| coral_stone_wall | 0,82 x 4,00 x 1,32 | 948 | 5 asize (8/8/8/8/7 pietre, ~0,5 x 0,25 m), pebble 6 laturi x 2 inele, umbrire plata; putin peste ~900 tri |
| cape_lighthouse | 12,55 x 7,25 x 20,20 | 1034 | nod nou `Lighthouse_Roof` (TILE_TERRACOTTA 23, placa 6,5 x 5,5 x 0,3), restul neschimbat |

Captura inlantuita: `docs/asset_briefs/img/okinawa_fidelity/limestone_cliff_module_chain.png`
(`preview_okinawa.py --chain limestone_cliff_module 3`). **Tiparul se repeta vizibil**
(acelasi modul de 3 ori); capetele sunt simetrice, deci la integrare modulele se pot
oglindi pe Y (scale.y = -1) si alterna; o a doua varianta de faleza ar rezolva de fapt.

Abateri ramase (cinstit): la notch_rock_a/b capul se citeste ca un morman de bolovani
rotunjiti (fatetele sunt mai mici si mai netede decat pe planșă), iar nisa e mai
putin accentuata decat pe decupare (a are picior gros, 3,6 m, cum s-a cerut, deci
surplomba capului e ~1,8 m pe fiecare parte). Ciorchinii de iarba sunt blocuri
fatetate, nu frunzis. Pietrele zidului sunt mai netede decat blocurile planșei.
