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
