# Inventar — kitul Transfăgărășan, val 2, tf-e (clădirile)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.3 (cabana are contract
revizuit după etapa 1). Build: `tools/blender/build_tf_buildings.py`.
Preview și măsurători: `tools/blender/preview_tf_e.py` (`--compare`,
`--views`, `--facade`). Verdict: `bash tools/blender/verify_transfagarasan.sh`
→ `VERDICT KIT: OK` (secțiunea „val 2, tf-e”).

Cotele sunt MĂSURATE pe GLB (`verify_glb.py --origin=assembly`, Godot Y-up;
Blender +Y = Godot −Z). Fața bogată e măsurată cu `preview_tf_e.py --facade`:
aria golurilor `*_Void` pe direcție și cât iese geometria peste corp.

**Golurile sunt reale.** Corpul plin e tăiat boolean pe 0,22 m. Fundul golului
e placa `*_Void`, așezată 2 mm în fața fundului tăiat, deci la **0,218 m** de
fața peretelui. Rama iese 5 cm în față și stă la 2 mm de perete.

**Tabla argintie e pe `ASPHALT_EDGE` 6** (`#696765`). E decizia
coordonatorului din valul 2: `PAINTED_METAL` 11 ieșea albastru. Tabla roșie
rămâne pe `KERB_RED` 7, iar cea ruginie pe `RUST_METAL` 10.

## Vocabular nou în `transfagarasan_shapes.py`

`tin_roof` nu mai e stub. Acoperiș de tablă cu fălțuiri:
- ape plane groase de 0,12 m, al căror cant se vede ca streașină;
- nervuri de 4,5 × 3,5 cm la 0,5 m, pe pantă, de la streașină la coamă (la
  `hip`, până la muchie);
- capac pe coamă și pe muchiile de hip;
- `kind="gable"` (două ape) sau `"hip"` (patru ape, coama de 2·(hx−hy));
- coama pe X sau pe Y;
- întoarce cotele fețelor de sus și de jos ale tablei, pe care se opresc
  pereții și frontoanele.

`tin_roof` are acum și două opțiuni noi:
- `kind="shed"`: o singură apă (taraba);
- `extend=(+v, −v)`: o apă se prelungește pe aceeași pantă, peste prispă
  (cabana Cascadă).

**Piese comune în `build_tf_buildings.py`:**
- `Openings`: goluri prin boolean, cu placa neagră și ramele;
- `stone_base`, `wood_bands`, `barge_boards`, `dormer`, `chimney`;
- `terrace`, cu `railing_boards` (balustradă din scânduri drepte);
- `plank_fence`, `rail_fence` (parii și bârnele țarcului), `gate_open`;
- `battens`: șipci verticale care sar peste goluri;
- `shingle_roof`: rânduri de șindrilă cu treaptă de umbră.

**Măsurarea feței bogate (`--facade`) folosește un test de paritate.** Fața
din față a plăcii negre stă în aer, în golul tăiat; cea din spate e îngropată
în corpul plin. Prima variantă („spre exterior față de centrul corpului”) a
pus poarta șurii de la casa B pe −Y, fiindcă șura nu e pe axă.

## buildings/cabana_balea_lac.glb (contract revizuit, rev. 2)

| nod | slot | tri |
|---|---|---:|
| `Cabana_Stone` | MARBLE_GREY 29 (parter, pietre de colț, coș) | 508 |
| `Cabana_Wood` | WOOD_WEATHERED 9 (pereți, terasă, scară, borduri) + LOG_DARK 28 (brâuri, stâlpi de colț, rame, montanți) | 4 636 |
| `Cabana_Roof` | ASPHALT_EDGE 6 (acoperiș + 2 lucarne, falțuri) | 1 068 |
| `Cabana_Void` | VOLCANIC_BLACK 20 (43 de goluri, gura coșului, tubul de aerisire) | 556 |
| total | `--origin=assembly`, scala/rotația aplicate pe rădăcini | **6 768** |

| cotă | contract revizuit | GLB |
|---|---|---|
| amprenta (lemnul) | 13 × 10 m | 13,0 × 10,0 m (piatra 12,7 × 9,7 m + 3 cm pietre de colț) |
| parterul de piatră | 3 m | 3,0 m |
| nivelurile de lemn | 2 × 2,7 m, peretele lung ~8,4 m | 3,0 → 5,7 → 8,4 m; streașina (muchia) la 7,99 m |
| panta | ~45–48° | 45° |
| coama | ~13 m | **13,67 m** (capacul); tabla 13,59 m. Abatere +5%: peretele de 8,4 m plus semideschiderea de 5 m la 45° dau +5 m, deci cele două cote nu încap amândouă. Am păstrat cele două niveluri întregi |
| coșul | — | 15,0 m (1,3 m peste coamă) |
| bbox | — | 14,20 (X) × 16,43 (Y) × 15,02 m; Y de la −5,71 la +10,73 (piciorul scării) |

**Fața bogată, măsurată pe GLB (`--facade`):** **+Y în Blender = −Z în Godot**.
| direcție | goluri | ce iese peste corp |
|---|---:|---|
| **+Y** | **13,17 m²** (14 goluri) | **terasa + scara: 5,85 m** |
| −Y | 7,90 m² | 0,83 m (streașina) |
| +X (frontonul din decupare) | 7,14 m² (11 goluri) | 0,72 m (streașina) |
| −X | 4,49 m² | 0,72 m (streașina) |

**Imaginile:**
- comparația, cu camera la azimut 32° și elevație 22°:
  `docs/asset_briefs/img/transfagarasan_fidelity/cabana_balea_lac.png`;
- cele 4 azimuturi: `cabana_balea_lac_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| proporția | casă compactă, înaltă | 13 × 10 m, două niveluri întregi de lemn peste piatră | OK după contractul revizuit. Rev. 1 era o șură lungă și joasă |
| parter de piatră | gri, piatră brută | 3 m, 4 pietre de colț pe muchie | culoarea (aproape albă în preview) rămâne pe seama tentei `stone_wall` la integrare (verdictul coordonatorului) |
| lemnul | portocaliu | WOOD_WEATHERED, brâuri LOG_DARK la 3,0, 5,7 și 8,4 m, stâlpi de colț | mai rece decât desenul; rămâne pe tentă (verdictul coordonatorului) |
| acoperiș | abrupt, gri | 45°, ASPHALT_EDGE gri neutru, falțuri la 0,5 m, capac pe coamă, borduri de lemn | OK |
| lucarne | 1 | 2 (contractul), 2,4 m late | după contract |
| coș | cărămiziu | de piatră (contractul) | după contract |
| fronton +X | trei rânduri de ferestre + aerisire | 3 + 4 + 3 + aerisire (0,4 × 0,7 m) | OK |
| latura +Y | ferestre pe etaj, terasă, scară | parter 1 fereastră + ușă; nivelul 1: 4 ferestre + ușa spre terasă; nivelul 2: 5 ferestre | OK |
| terasă | simplă, la etaj | 5,2 × 2,4 m, la +3 m, balustradă din scânduri drepte pe 3 laturi | OK |
| scară | coboară spre privitor | 11 trepte, perpendiculară pe perete, spre +Y | OK |
| verandă de jos cu acoperiș propriu | da | lipsește | voit: corectura „cel mult o terasă simplă” |

**Rundele.** Rev. 1 a avut 3 runde (acceptată ca direcție de coordonator).
Rev. 2, pe contractul revizuit, a ieșit din prima rundă.

## buildings/cabana_balea_cascada.glb

| nod | slot | tri |
|---|---|---:|
| `Cascada_Stone` | MARBLE_GREY (soclul casei și al anexei) | 84 |
| `Cascada_Wood` | WOOD_WEATHERED + LOG_DARK; MARBLE_GREY doar pe soclul prispei | 2 722 |
| `Cascada_Roof` | **RUST_METAL 10** (casa, anexa, lucarna) | 1 212 |
| `Cascada_Void` | VOLCANIC_BLACK (20 de goluri, coșul) | 252 |
| total | `--origin=assembly` | **4 270** |

| cotă | contract | GLB |
|---|---|---|
| casa | 12 × 9 m, un nivel + pod mansardat | 12 × 9 m (lemnul); soclu de piatră 0,8 m, peretele de lemn până la 3,8 m, panta 40° |
| coama | 8 m | **7,83 m** |
| anexa în L | 6 × 5 m, joasă | 6 × 5 m, lipită de frontonul +X și aliniată cu spatele (retrasă 4 m față de fațadă); soclu 0,5 m, pereți 2,7 m, panta 35°, coama la 4,62 m |
| prispa | de-a lungul fațadei lungi | 12 m × 1,75 m pe +Y, podea la 0,42 m, 6 stâlpi, parapet din scânduri drepte, 2 trepte. Stă sub apa +Y a acoperișului, prelungită (`extend`) pe aceeași pantă; streașina de la 2,09 m |
| bbox | — | 18,90 (X) × 11,93 (Y) × 8,83 m (coșul); Y de la −5,10 la +6,83 |
| goluri | ≥ 0,15 m | 0,218 m (\|x\| max al plăcilor 5,782 = 6,0 − 0,218) |

- **Fața bogată, măsurată:** +Y (−Z în Godot). Golurile au 9,95 m² pe +Y,
  față de 3,02 pe −X, 2,96 pe −Y și 2,49 pe +X. Prispa iese 2,48 m pe +Y.
- **Diferențele de formă față de Bâlea Lac:**
  - un nivel în loc de trei;
  - acoperiș ruginiu, nu gri;
  - lungă și joasă, cu anexa în L, prispă continuă și o singură lucarnă;
  - fără terasă și fără scară.
- **Diferențele față de `arges_house_a`:** e de lemn, nu tencuită; acoperișul
  e în două ape, nu în patru; are anexă.
- **Imaginile:** `cabana_balea_cascada.png`, `cabana_balea_cascada_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| nivelul de lemn pe soclu | etaj + mansardă, soclu de piatră vizibil în dreapta | un nivel (3,0 m) pe soclu de 0,8 m, pod mansardat cu 2 ferestre în fiecare fronton | după corectură |
| acoperiș | gri | ruginiu (RUST_METAL #91461E), cu falțuri | după corectură; slotul iese portocaliu-saturat în preview |
| lucarnă | 1 | 1, jos pe pantă | OK |
| anexa în L | nu există | 6 × 5 m pe +X, mai joasă | după corectură |
| prispa | terasă mică cu trepte | prispă pe toată fațada +Y | după contract |
| treptele de piatră spre ușă | da | 2 trepte de lemn din prispă | simplificat |
| brad, tufe | da | nu | corectura (vegetația la integrare) |

**Rundele:**
1. Șipcile anexei treceau peste ușa șopronului. Lucarna avea coama la 8,15 m,
   peste coama mare (7,83 m), defect văzut abia în cifrele din `verify_glb`.
2. Am pus `battens(holes=…)`, iar lucarna a coborât pe pantă (1,9 m lățime,
   înălțată 1,15 m). Coama ei a ajuns la ~7,2 m. E starea livrată.

**Abateri:**
- prispa are sub streașină doar ~2,1 m la stâlpi și 1,67 m la muchie: panta e
  de 40°, iar streașina e prelungită;
- tabla ruginie e foarte saturată în preview.

## buildings/stana.glb

| nod | slot | tri |
|---|---|---:|
| `Stana_Wood` | WOOD_WEATHERED + LOG_DARK (coliba, șipcile, stâlpii de colț, butucul) | 692 |
| `Stana_Roof` | **ASPHALT_EDGE 6** (șindrila) + RUST_METAL (coșul de tablă) | 260 |
| `Stana_Fence` | WOOD_WEATHERED (bârnele) + LOG_DARK (parii) | 588 |
| `Stana_Void` | VOLCANIC_BLACK (ușa, 2 ferestre) | 36 |
| total | `--origin=assembly` | **1 576** |

| cotă | contract | GLB |
|---|---|---|
| coliba | 5 × 4 m, 3,2 m la coamă | 4 (X, frontonul) × 5 (Y) m, pereți de 1,95 m, panta 28°, coama 3,17 m (plus capacul, ~3,27 m); coșul ajunge la 4,0 m |
| țarcul | 14 × 10 m, gard de 1,2 m | 14 × 10 m (bbox 14,35 × 10,35 cu parii); bârnele la 1,2 m, parii la 1,32–1,40 m; pari la ~2 m, 3 rânduri de bârne |
| poarta | una, deschisă | 2,4 m pe latura +Y, deschisă spre interior (235°) |
| origine | — | pe centrul țarcului; coliba stă în colțul din spate-dreapta (centrul ei la x +3,9, y −2,2) |

- **Fața bogată, măsurată:** +Y. Ușa colibei și o fereastră au 2,74 m², spre
  țarc și spre poartă; pe −X e o fereastră (0,27 m²).
- **Imaginile:** `stana.png`, `stana_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| coliba de scânduri verticale | da | pereți de lemn cu șipci la 0,45 m (formă), stâlpi de colț | OK |
| ușa mare deschisă, în fronton | da | gol de 1,3 × 1,95 m | OK |
| acoperiș | gri | **șindrilă** (contract), 8 rânduri pe apă, treaptă de ~3 cm, în ASPHALT_EDGE gri | decizie: șindrila veche e cenușie ca pe planșă; nu există slot de lemn gri |
| coș de tablă | nu se vede | burlan ruginiu cu pălărie | după contract |
| țarcul | pari groși, 3 rânduri de bârne | 3 rânduri, parii ușor strâmbi | OK; bârnele sunt mai subțiri decât pe desen |
| poarta deschisă | țarc deschis spre față | poartă de 2,4 m deschisă spre interior | OK |
| butucul de despicat | nu se vede | butuc + 2 lemne despicate | după contract |
| coliba față de țarc | coliba mare, cam 1/3 din țarc | 4 × 5 m în 14 × 10 m: pare mică | abatere: cotele sunt din tabel |

**Rundele:**
1. Șipcile treceau peste ușă. Poarta, rotită la 115°, se vedea din muchie, ca
   un singur stâlp. Coama ieșea la 3,62 m.
2. Șipcile sar peste goluri, poarta e deschisă spre interior, cu bârne mai
   groase și stâlpi la capete, iar coama a coborât la 3,17 m (pereți de
   1,95 m, panta de 28°). E starea livrată.

## buildings/arges_house_a.glb

| nod | slot | tri |
|---|---|---:|
| `House_Plaster` | FOAM_WHITE (pereții, coșul tencuit) | 208 |
| `House_Stone` | MARBLE_GREY (soclul de 0,4 m) | 12 |
| `House_Wood` | WOOD_WEATHERED (prispa, stâlpii, ramele, gardul, poarta) + LOG_DARK + MARBLE_GREY (treapta) | 2 400 |
| `House_Roof` | **ASPHALT_EDGE 6** (patru ape) | 964 |
| `House_Void` | VOLCANIC_BLACK (9 goluri) | 120 |
| total | `--origin=assembly` | **3 704** |

| cotă | contract | GLB |
|---|---|---|
| casa | 9 × 7 m | 9 × 7 m: corpul are 5,4 m adâncime, plus prispa de 1,6 m |
| coama | 6,5 m | **6,50 m** (capacul); panta 41°, coama de 2 m |
| pereții | — | 3,2 m, cu soclu de 0,4 m |
| streașina | „largă” | 0,6 m pe toate laturile |
| gardul | 1,2 m pe +Y, cu poartă | scânduri cu rost, stâlpi la 2 m, la y = 6,2 m (2,7 m în fața prispei), cu întoarceri până la prispă; poarta de 1,15 m deschisă |
| bbox | — | 10,42 × 11,38 × 7,20 m (coșul) |

- **Fața bogată, măsurată:** +Y. Golurile au 4,16 m² (ușă + 2 ferestre),
  câte 2,26 m² pe celelalte fețe. Prispa și gardul ies 5,23 m pe +Y.
- **Imaginile:** `arges_house_a.png`, `arges_house_a_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| pereți albi tencuiți | da | FOAM_WHITE, soclu gri | OK |
| acoperiș | în două ape, cu fronton de scânduri | **în patru ape** (contract) | după contract; frontonul de scânduri a trecut la B |
| tabla | argintie-albăstruie | ASPHALT_EDGE gri închis | decizia coordonatorului (clasa o luminează) |
| prispă de lemn pe stâlpi | îngustă, la intrare | pe toată fațada +Y, 4 stâlpi, parapet jos din scânduri | după contract |
| ferestre cu ramă de lemn | da | ramă WOOD, pervaz, cruce | OK |
| gard de scânduri cu poartă | gard înalt pe față și pe laturi | față + întoarceri, poartă deschisă | OK |

**Rundele:**
1. Cu streașină de 0,8 m și pereți de 3,0 m, casa citea „ciupercă”: numai
   acoperiș.
2. Pereții au crescut la 3,2 m și streașina a scăzut la 0,6 m, cu coama
   păstrată la 6,5 m. E starea livrată. Acoperișul rămâne dominant, cum e
   firesc la patru ape pe un singur nivel.

**Abatere:** ferestrele de pe +Y stau în umbra prispei, deci din camera de sus
se citesc slab.

## buildings/arges_house_b.glb

| nod | slot | tri |
|---|---|---:|
| `House_Plaster` | FOAM_WHITE (corectura: nu verde) | 134 |
| `House_Stone` | MARBLE_GREY (soclul) | 12 |
| `House_Wood` | WOOD_WEATHERED (frontoanele de scânduri, șura, gardul) + LOG_DARK (șipci) + **TILE_TERRACOTTA** (coșul) + MARBLE_GREY (treapta) | 3 322 |
| `House_Roof` | **KERB_RED 7** (casa și șura) | 768 |
| `House_Void` | VOLCANIC_BLACK (9 goluri, inclusiv poarta șurii) | 120 |
| total | `--origin=assembly` | **4 356** |

| cotă | contract | GLB |
|---|---|---|
| casa | 8 × 6 m | 6 (X, frontonul spre drum) × 8 (Y) m, pereți de 2,8 m, panta 44° |
| coama | 6 m | **6,01 m** |
| șura | 5 × 4 m | 5 × 4 m pe +X, la 0,5 m de streașina casei, retrasă spre spate; pereți de 2,6 m, panta 32°, coama la 4,01 m, poarta de 2,2 m |
| gardul | același ca la A | scânduri, la y = 6,6 m, poarta deschisă |
| bbox | — | 13,02 × 12,12 × 6,81 m (coșul) |

- **Fața bogată, măsurată:** +Y. Golurile au 7,30 m² (2 ferestre, fereastra
  de pod din fronton, poarta șurii), față de 3,75 pe −X (ușa, 2 ferestre),
  1,04 pe +X și 1,04 pe −Y.
- **Diferențele față de A:** fronton spre drum în loc de patru ape, tablă roșie
  în loc de gri, fronton de scânduri și o șură alăturată.
- **Imaginile:** `arges_house_b.png`, `arges_house_b_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| fronton de scânduri spre drum | da (cu o fereastră) | șipci LOG_DARK pe frontonul de lemn, fereastra de pod | OK |
| acoperiș roșu în două ape | da | KERB_RED, cu falțuri | OK |
| pereții | verzi | **albi** (corectura) | după corectură |
| ușa | pe latura lungă | pe −X (latura spre curte), cu treaptă | OK |
| coș de cărămidă | da | TILE_TERRACOTTA, în nodul de lemn: clasa de tencuială l-ar fi albit | decizie de nod |
| șura | nu există | 5 × 4 m pe +X | după contract |
| gard | da | același tip ca la A | OK |

**Rundele:**
1. Șipcile treceau peste fereastra de pod și peste poarta șurii. Șura,
   lipită la început de casă, ar fi avut coama peste tabla casei, așa că am
   dezlipit-o la 0,5 m înainte de prima randare.
2. Șipcile sar peste goluri. E starea livrată.

## props/souvenir_stall.glb

| nod | slot | tri |
|---|---|---:|
| `Stall_Wood` | WOOD_WEATHERED + LOG_DARK (stâlpii, grinzile, peretele din spate, tejgheaua, rafturile) | 324 |
| `Stall_Roof` | WOOD_WEATHERED (o apă din scânduri: nervuri de 5 × 3 cm la 0,25 m) | 192 |
| `Stall_Goods` | SAND_LIGHT (cașul), KERB_RED (zmeura), ICE_DEEP (afinele), LARCH_RUST (cașul în coajă de brad), WOOD (coșurile, lăzile), LOG_DARK (sforile) | 620 |
| total | `--origin=assembly` | **1 136** |

| cotă | contract | GLB |
|---|---|---|
| taraba | 3,5 × 2 m, 2,8 m | stâlpii pe 3,5 × 2,0 m; acoperișul 3,8 × 2,6 m; sus 2,77 m, streașina din față la 2,09 m |
| tejgheaua | — | la 0,9 m, cu raft jos la 0,3 m |

- **Fața bogată, măsurată:** +Y. Nu are goluri; centroidul mărfii stă la
  y = +0,69, iar peretele din spate la y = −0,90.
- **Imaginile:** `souvenir_stall.png`, `souvenir_stall_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| acoperiș | în două ape, din scânduri | **o apă** (contract), din scânduri | după contract |
| roți de caș | 3 | 3 (2 suprapuse), `segments` 10 | OK |
| fructe | grămadă roșie + grămezi magenta jos | coș cu zmeură, coș cu afine; jos 2 lăzi (zmeură, afine) | OK; fructele din lăzi sunt plăci plane, nu grămezi |
| caș afumat atârnat | ~10 bucăți | 8 trunchiuri de con LARCH_RUST pe sfori, sub streașină | OK după runda 2 |
| fără text / firmă | — | nimic | OK |
| lemnele sprijinite, florile | da | nu | voit |

**Rundele:**
1. Acoperișul era prea mare: 0,45 m în față și 0,25 m în lateral. Fața
   tejghelei ascundea raftul de jos. Cașul atârnat se confunda cu scândurile
   din spate.
2. Streașina a scăzut la 0,3 / 0,15 m, fața tejghelei a dispărut, iar cașul
   e acum un con scurt și gros pe o sfoară scurtă. E starea livrată.

## Stare la oprire (13 oct 2026)

- **Făcut:** toate cele 6 piese din §1.3, cu `VERDICT KIT: OK`, comparații și
  câte 4 azimuturi.
- **Cabana Bâlea Lac** e pe contractul revizuit. Tabla argintie e pe
  ASPHALT_EDGE în kit și în build.
- **Rămân pentru integrare (coordonatorul):**
  - tentele: `stone_wall` pe `*_Stone`, `plaster` pe `*_Plaster`, tabla
    `*_Roof` luminată;
  - tabla ruginie, care iese foarte saturată.
- **Coliziunea** o decide coordonatorul. Gardurile și țarcul sunt geometrie
  subțire; pentru ele e nevoie de colizori simpli.
