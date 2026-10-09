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

## ok-c: plantele (`build_okinawa_plants.py`, kit §1.3)

Toate cu origine la baza trunchiului (bougainvillea: la baza peretelui, spatele plat pe y = 0), scala aplicata pe radacini, un nod per material. Comparatii: `docs/asset_briefs/img/okinawa_fidelity/<nume>.png`; **captura de tunel**: `.../fukugi_tunnel.png` (6 fukugi a/b/c la 3,5 m pe doua siruri la +-4 m; stanga: din axa, la 1,5 m inaltime | dreapta: 3/4 de sus; `preview_okinawa.py --tunnel`). `*_Leaves` se randeaza in preview pe culoarea slotului 21 (#3F7A3C), mai deschis decat tinta #2E5A2C; tenta de clasa il intuneca la integrare.

| piesa | cote masurate (X x Y x Z, m) | h/l | tri | noduri |
|---|---|---:|---:|---|
| fukugi_tree_a | 2,83 x 2,76 x 7,07 | 2,50 | 1852 | Fukugi_Leaves 1776, Fukugi_Bark 76 |
| fukugi_tree_b | 2,94 x 2,98 x 8,59 | 2,88 | 2148 | idem |
| fukugi_tree_c | 2,58 x 2,08 x 5,58 | 2,16 | 1754 | idem |
| ryukyu_pine | 8,99 x 6,43 x 9,26 | 1,03 | 1516 | Pine_Leaves 1092, Pine_Bark 424 |
| cycad | 2,52 x 2,48 x 2,00 | 0,79 | 3276 | Cycad_Leaves 2352, Cycad_Bark 924 |
| fan_palm | 4,15 x 4,26 x 5,97 | 1,40 | 2252 | Palm_Leaves 1584, Palm_Bark 668 |
| bougainvillea | 2,45 x 0,92 x 1,61 | 0,66 | 2656 | Bougainvillea_Leaves 640, Bougainvillea_Bloom 2016 (slot 31, `--allow-slots=31`) |

### Fidelitate / abateri (cinstit)

- **fukugi (corectura de coordonator, nu planșa):** stalp de frunzis, nu coroana rotunda; ciot de ~0,8 m; 6/7/5 mase suprapuse + 7 ciorchini pe masa (aceeasi textura vizuala de mase fatetate cu ciorchini ca pe planșa, fara silueta ei). a varf rotunjit, b varf ascutit (ultimele 3 mase 88/66/40%), c plin cu masa laterala spre +X (bbox 2,58 m). Abateri: (1) verde uniform de slot (planșa are lumini galben-verzui pe ciorchini; aici doar AO), (2) ciorchinii sunt lumpi fatetati simpli, nu frunze; (3) in tunel, la 3,5 m, ramane un gol de ~0,5-0,7 m la sol intre trunchiuri: din axa citeste perete continuu (masele se suprapun in perspectiva), din 3/4 lateral citeste inca sir de coloane dese, nu bile. Pentru perete mai ferm: plantare la 3,0-3,2 m. (4) b are h/l 2,88 (tinta 2,8, in +-15%).
- **ryukyu_pine:** trunchi rasucit (S), 4 brate + lider, 7 perne turtite cu goluri intre ele, h/l 1,03 (tinta 1,0). Abateri: pernele sunt lise (fara ciorchini ca pe planșa), trunchiul mai neted si mai subtire decat in desen; fara stanci/tufe/nisip (regula „fara vegetatie lipita”).
- **cycad:** 14 frunze (5+5+4) in 3 etaje, solzi in romburi (3 randuri x 8). Abateri: frunzele sunt lame dintate (zimti alternanti), nu foliole individuale; mai putin dense si mai rigide decat pe planșa; inaltimea 2,0 (tinta 2,2), h/l 0,79 (tinta 0,85); 3276 tri, cel mai scump per piesa.
- **fan_palm:** trunchi cu inele (WOOD/LOG_DARK), 11 evantaie plisate in 2 etaje + 3 uscate (DRY 13) la baza coroanei. Abateri: trunchiul e mult mai lung si mai subtire decat in desen (contractul cere 6 m, planșa e un palmier scurt); evantaiele au muchii mai dure; frunzele uscate atarna prea sus/mici; coroana ~4,2 m.
- **bougainvillea:** spate plat, 10 mase de frunzis + 48 ciorchini. Abateri: **floarea e roz pal** (`FLAMINGO_PINK` 31 = #D2A0BE), nu magenta saturat de pe planșa — slotul e contractul; magentul trebuie adus de integrare (tenta/clasa) sau de o decizie de slot; ciorchinii sunt lumpi, nu inflorescente; 2,45 x 1,61 (tinta 2,4 x 1,6).

### Adaugiri la harnas
`okinawa_shapes.py` (la final): `foliage_column`, `foliage_pillow`, `ring_trunk`, `pleated_fan`, `serrated_frond`. `preview_okinawa.py`: `SPECS` pentru cele 7 piese, `_scene_lights`, `_render_cam`, `tunnel()` si modul `--tunnel`. `verify_okinawa_v2.sh`: sectiunea `== val 1, ok-c: plantele ==`.

### ok-c, runda 4 (ceruta de coordonator): ciorchini fatetati, pinnate, evantaie mari

Vocabular nou in `okinawa_shapes.py`: `column_ellipsoids`, `ellipsoid_anchors`, `foliage_clumps` (anvelopa de ciorchini turtiti, doua tonuri dupa normala), `pinnate_frond`. Frunzisul fukugi/pin = miez nevazut + ciorchini; ~28% din ciorchini (normala in sus) in nodul `*_Leaves_Tip` pe CACTUS_GREEN 12. Capturi: `fukugi_tunnel.png` refacut; comparatii refacute pentru toate cele 7 (maxim 2 runde pe piesa).

| piesa | cote (X x Y x Z, m) | h/l | tri | noduri |
|---|---|---:|---:|---|
| fukugi_tree_a | 2,77 x 2,67 x 7,07 | 2,55 | 2308 | Leaves 1692, Leaves_Tip 540, Bark 76 (54 ciorchini) |
| fukugi_tree_b | 2,98 x 2,84 x 8,51 | 2,86 | 2248 | Leaves 1668, Leaves_Tip 504, Bark 76 (51) |
| fukugi_tree_c | 2,59 x 2,04 x 5,42 | 2,09 | 2308 | Leaves 1656, Leaves_Tip 540, Bark 76 (53) |
| ryukyu_pine | 9,07 x 6,86 x 9,28 | 1,02 | 3532 | Leaves 2352, Leaves_Tip 756, Bark 424 (7 perne x 11 ciorchini) |
| cycad | 2,54 x 2,37 x 2,23 | 0,88 | 5420 | Leaves ~4500 (20 frunze x 31 statii), Bark ~900 |
| fan_palm | 4,46 x 4,23 x 6,43 | 1,44 | 3438 | Leaves 1584, Bark 1854 |
| bougainvillea | 2,45 x 1,02 x 1,62 | 0,66 | 3024 | Leaves ~1200, Bloom ~1800 (96 ciorchini + 10 revarsati) |

Note si abateri:
- **Fukugi:** contur zimtat de ciorchini, doua tonuri, fara cubulete. Tip-ul apare mai ales sus (normala in sus); pe laturi domina tonul 21. In tunel ramane un gol de ~0,5 m la sol intre trunchiuri, dar din axa citeste perete. Ciorchinii sunt poligoane netede, fara lumina galbena pe fiecare (planșa).
- **Pin:** silueta pastrata, pernele sunt acum 11 ciorchini; pernele de sus par putin incarcate. 3532 tri.
- **Cicada:** frunze penate (comb din 31 de statii alternante = ~15 perechi, sub cele 25-40 cerute, ca sa ramana sub 5500 tri), 20 de frunze; mai subtiri si mai putin pline decat pe planșa, trunchiul domina vizual. Verify: buget 6500.
- **Palmier:** coroana ~4,5 m, 11 evantaie pe petioli de ~1,7 m, trunchi Ø ~0,5 m cu solzi in romb pe treimea de sus, 3 frunze uscate mari sub coroana. **Abatere:** coroana iese asimetrica (evantaiele se aduna in dreapta/sus, pare ciorchine si nu radiaza uniform), evantaiele (R ~1,0) se citesc mai mici decat Ø 1,6-2 m cerut; solzii sunt bulgari, nu romburi cu muchii. Nerezolvat in 2 runde.
- **Bougainvillea:** frunzis verde ~40% vizibil, 96 + 10 ciorchini de flori de 0,25-0,36 m, revarsati peste marginea de jos. Preview randeaza `*_Bloom` pe **#C2378F**. **Tenta de clasa necesara la integrare:** slotul 31 e #D2A0BE (pal); tinta magenta #C2378F cere inmultire pe canale (0,92, 0,34, 0,75).

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

## Val 2, ok-d: satul si portul (`tools/blender/build_okinawa_village.py`, kit §1.4)

Vocabular adaugat la FINALUL `okinawa_shapes.py` (semnaturile existente neatinse):
`hip_seams` (rosturi albe in relief pe `HipRoof`), `ellipsoid`, `shisa_lion`,
`coral_wall_segment` (zidul de corali la lungime/directie variabila; aceeasi retea de
asize mici ca `coral_stone_wall`, care ramane NESCHIMBAT), `wall_under_roof`,
`stair_wedge`, `emit_ok_nodes` (umbrire plata doar pe nodurile `_Coral`; `keep_z` pentru
originea la linia apei). `tools/blender/measure_front.py` masoara fata (raza spre
exterior din fiecare fata LOG_DARK a nodului `*_Wood`; spatele placilor ingropate nu
conteaza). Verify: sectiune `== val 2, ok-d ==`.

**Fata (masurata pe GLB, aria golurilor expuse): +Y la toate cele 5 case** —
ryukyu a 3,03 m2 pe +Y (urmeaza -Y 2,27 = ferestrele din spate), b 5,94, c 3,26,
concrete a 11,28, b 6,55.

| piesa | cote masurate (X x Y x Z) | tri | noduri (tri) |
|---|---|---:|---|
| `buildings/ryukyu_house_a.glb` | 14,01 x 12,00 x 5,17 m (curtea 14x12; varf 5,17 cu shisa) | 11.724 | Roof 2696, Mortar 1968, Plaster 416, Wood 600, Coral 5712, Shisa 332 |
| `buildings/ryukyu_house_b.glb` | 16,01 x 12,02 x 5,52 m | 17.852 | Roof 4952, Mortar 4968, Plaster 748, Wood 756, Coral 6096, Shisa 332 |
| `buildings/ryukyu_house_c.glb` | 11,08 x 10,00 x 4,67 m | 10.004 | Roof 1760, Mortar 2400, Plaster 304, Wood 444, Coral 4764, Shisa 332 |
| `buildings/concrete_house_a.glb` | 10,31 (cu scara) x 8,18 x 9,11 m (cladire 6,5 + rezervor) | 2.216 | Plaster 72, Concrete 548, Wood 1596 |
| `buildings/concrete_house_b.glb` | 8,21 x 7,16 x 6,36 m (cladire 4,0 + rezervoare) | 1.296 | Plaster 60, Concrete 684, Wood 552 |
| `structures/harbour_quay.glb` | 6,26 x 12,00 x 4,43 m; Z de la -1,5 la +2,2 (+babale); origine la linia apei | 884 | Concrete 384, Rubber 500 |
| `structures/bus_stop_shelter.glb` | 4,31 x 2,31 x 3,11 m | 3.248 | Roof 608, Mortar 1344, Wood 120, Coral 1164, Concrete 12 |
| `props/vending_machine.glb` | 1,00 x 0,91 x 1,85 m | 476 | Plaster 96, Glass 380 |
| `props/convex_mirror.glb` | 0,86 x 0,74 x 3,15 m | 156 | Frame 112, Glass 44 |
| `props/fishing_net_rack.glb` | 4,00 x 1,19 x 1,97 m | 576 | Wood 84, Net 492 |

Casele Ryukyu depasesc bugetul orientativ de ~12k (b: 17,9k) din zidul de corali al curtii
(~5-6k, cel mai mare consumator, 52 m de perimetru) — raportat, fara plafon.
`verify`: bugete 20.000 (ryukyu) / contract (restul).

### ryukyu_house_a (piesa-erou), 2 runde de `--compare`

Comparatie: `docs/asset_briefs/img/okinawa_fidelity/ryukyu_house_a.png`; cele trei pe o
planșa: `docs/asset_briefs/img/okinawa_fidelity_val2.png`.

| element | pe planșă / corectură | în GLB | verdict |
|---|---|---|---|
| varf | manerul rosu (corectura: SHISA) | leu shisa de teracota 0,6 m pe coama, cu fata spre +Y (`House_Shisa`, 332 tri) | OK ca numar/loc; la vedere de ansamblu e mic (0,6 m din 14) |
| olane | nervuri dese, rosu | nervuri in relief (pas 0,3 m, 0,1 m) pe `House_Roof`; rosul vine din clasa | OK; la 3/4 din sus nervurile se citesc slab (clasa le aduce) |
| mortar alb | coame + rosturi in relief | `House_Mortar`: coama, 4 muchii, bordura si ~14 rosturi de la streasina la coama, in relief | OK (rosturile rare si subtiri: la pas 0,9 m erau prea dese, "umbrela") |
| acoperis | 4 ape, streasina ridicata | 4 ape, coama scurta, colturi +0,15 | OK; coama mai scurta decat pe planșă |
| hinpun | lipsea pe planșă | zid liber 3 x 1,6 x 0,45 la y = 4,0 (2 m in spatele intrarii) | OK, contract |
| intrare | poarta de lemn | FARA poarta, flancata de 2 stalpi de corali 1,75 m | OK (corectura) |
| prispa | — | podea de lemn, 5 stalpi sub streasina lata, usi glisante inchise | OK |
| zid de corali | zid dreptunghiular alb | pietre rotunjite in 4 asize, 1,4 m, umbrire plata | OK; pietrele sunt mai mari/colturoase ca in desen |
| vegetatie lipita | palmieri, flori, tufe | NU modelata (corectura) | OK |
| zid vs casa | zid strans in jurul casei | curte 14 x 12 din contract: casa pare mica in ea | abatere de contract, nu de forma |

b = doua corpuri in L (casa 10 m + anexa perpendiculara mai joasa, doua shisa... doar una pe
corpul principal), intrarea decalata la x = -3,2; c = casa mica, acoperis mai abrupt
(curbura 1,15), curte 11 x 10 cu coltul (-X,+Y) taiat, intrarea pe +X. Se disting net pe planșa
`okinawa_fidelity_val2.png`. Abateri: b si c au o singura shisa; la c prispa e pe +Y
(intrarea curtii e pe +X, contract).

### Casele de beton, cheiul, refugiul, props (1-2 runde)

Comparatii: `okinawa_fidelity/{concrete_house_a,concrete_house_b,harbour_quay,bus_stop_shelter,vending_machine,convex_mirror,fishing_net_rack}.png`,
planșe `okinawa_fidelity_val3.png`, `okinawa_fidelity_val4.png`.

| piesa | abateri cinstite |
|---|---|
| concrete_house_a | tencuiala `FOAM_WHITE` (cu clasa `plaster` iese ca pe planșă); 2 niveluri, rezervor 10 segmente pe picioare, scara exterioara pe +X, sarma cu 4 rufe, 3+1 ferestre cu jaluzele pe +Y. Parapetul e in `Concrete_Plaster` (alb ca pe planșă), coronamentul in `Concrete_Concrete` (contractul punea parapetul in Concrete). Planșa arata un singur nivel + curte cu trepte si zid: nu se modeleaza (contract: 2 niveluri) |
| concrete_house_b | `FLAMINGO_PINK` 31 e mai violaceu (#D2A0BE) decat roz-somon-ul din desen: slot existent, culoarea finala o poate da clasa `plaster`. Doua rezervoare + iesire pe acoperis |
| harbour_quay | bloc 6 x 12, scara in nisa de 7 trepte pe -X, 3 babale, 5 anvelope, rosturi de placi pe fata -X (benzi). Planșa are blocuri de piatra cu accente portocalii pe babale/scara: slotul e CONCRETE (contract); bordura/babalele nu au portocaliu. Capetele y=±6 plane |
| bus_stop_shelter | acoperis HipRoof 4 x 2, 4 stalpi de lemn, perete de corali in spate + 2 jardiniere joase (fara plante), banca; acoperisul pare mult alb (mortar pe o suprafata mica) fata de planșă. Stalpi de lemn, nu de piatra ca in desen (contract) |
| vending_machine | decuparea e un panou alb gol; contractul cere vitrina cu 8 sticle: urmeaza contractul (abatere declarata). Fara text/logo |
| convex_mirror | stalp 3 m, rama portocalie 12 segmente, oglinda ICE_TURQUOISE; calota fara peisaj pictat (desenul are cer/drum) |
| fishing_net_rack | 2 capre in A + bara (desenul: 2 bare, capete rotunde), 3 plase ca saci fatetati cu flotoare; **plasele nu au ochiuri** (saci plini, nu retea): abatere mare, retelele se citesc din clasa/textura la integrare |

### Stare la oprire (ok-d)

Toate cele 10 GLB exportate, `verify_okinawa_v2.sh` -> `VERDICT KIT: OK`. Comparatiile sunt de
vazut de coordonator; cea mai slaba fidelitate: `fishing_net_rack` (fara ochiuri) si `harbour_quay`
(fara accente, tonuri uniforme).

### ok-d, runda 2, ceruta de coordonator (casele Ryukyu, cheiul, refugiul)

Comparatii refacute (cate 1-2 pe piesa): `okinawa_fidelity/{ryukyu_house_a,ryukyu_house_b,ryukyu_house_c,harbour_quay,bus_stop_shelter}.png`,
`ryukyu_house_a_views.png` (4 azimuturi: hinpun-ul apare in spatele intrarii), planșe `okinawa_fidelity_val2.png`, `val3.png`.
Casele de beton, automatul, oglinda si suportul de plase au fost acceptate si NU au fost atinse.

| piesa | schimbare | cote / tri |
|---|---|---|
| ryukyu_house_a/b/c | acoperis jos, ~drept: `HipRoof` cu `tile_step` 0,2 (perioada nervurilor 0,4 m, 0,1 m relief, ca la poarta), curbura 1,0, colturi ridicate cel mult 0,2 m; alb DOAR pe coama, cele 4 muchii de colt si bordura streasinii; `hip_seams` scos de pe case (ramane in vocabular) | a 14,00 x 12,00 x 5,17 m, 21.764 tri; b 16,00 x 12,00 x 5,52, 29.036; c 11,14 x 10,03 x 4,67, 16.476 |
| zidul curtii | acelasi tipar ca `coral_stone_wall.glb`: 5 asize, pietre de ~0,5 m, proportii originale (nucleu SAND_SHADOW 0,4 din grosime), 1,35 m, creasta plata; stalpii de la intrare 1,8 m din 7 asize; fara goluri pe randarea de aproape | coralii = 13,2k (a) / 14,2k (b) / 10,5k (c) din total; peste ~14k, acceptat de coordonator |
| hinpun | piatra de corali ca zidul, 3 x 1,6 m, grosime 0,6 | vizibil pe `ryukyu_house_a_views.png` |
| harbour_quay | UN bloc continuu 6 x 12 m; scara sapata in fata -X (nisa 1,8 m, y -2,5..3,5, 8 trepte pe lungimea fetei, primele 3 sub apa); 3 babale pe muchie (y -4,8 / -3,0 / 4,5); 4 anvelope atarnate pe fata verticala la z = 1,2 (~1 m sub muchie), in afara scarii; fata -X din blocuri mari in relief (rand de 1,4-2,6 m, umbrire plata); capete plane la ±6, origine la linia apei | 6,29 x 12,00 x 4,43 m, 828 tri |
| bus_stop_shelter | acoperis in doua ape (`gable_roof`, nou in shapes): streasina dreapta, olane dese in relief, alb DOAR pe coama si pe cele doua capete ale ei (`Shelter_Mortar` 36 tri); stalpi de lemn, perete de corali cu asizele zidului | 4,10 x 2,10 x 3,29 m (3,20 cu coama), 2.660 tri |

Abateri ramase: olanele se citesc ca benzi la randarea neutra (rosul si textura vin din clasa `roof_tiles`);
nucleul brun al zidului de corali se vede intre pietre, ca la modulul acceptat; scara cheiului e in
umbra proprie a nisei (se citeste, dar mai greu decat pe decupare); fara accentele portocalii ale desenului
(slot CONCRETE).
