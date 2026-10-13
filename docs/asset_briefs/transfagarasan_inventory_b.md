# Inventar tf-b — stânci și plante (Transfăgărășan, Track21, valul 1)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §0 (regulile 7–8), §1.4, §1.5.
Build: `tools/blender/build_tf_rocks.py`, `tools/blender/build_tf_plants.py`.
Vocabular: `tools/blender/tf_shapes_nature.py` (fișier nou, separat de
`transfagarasan_shapes.py`). Captura de grup: `tools/blender/preview_tf_group.py`.
Verdict: `bash tools/blender/verify_transfagarasan.sh` → `VERDICT KIT: OK`
(blocul „val 1, tf-b”, toate cu `--origin=assembly`, bujorul și cu `--allow-slots=31`).

Cotele sunt **măsurate pe GLB** (X × Y × Z-sus, Blender). `h/l` e măsurat pe
silueta randării din comparație (panoul din dreapta, 3/4 din față), cu
excepțiile notate. Triunghiurile se raportează, fără plafon.

Comparațiile sunt în `docs/asset_briefs/img/transfagarasan_fidelity/<nume>.png`
(decupare | randare), cu 4 azimuturi în `<nume>_views.png`. Planșele de grup:
- `transfagarasan_fidelity_val1b_stanci.png` (a | b | c alăturate);
- `transfagarasan_fidelity_val1b_plante.png`;
- `transfagarasan_fidelity/jneapan_group.png` (pâlcul: 5 × a + 3 × b la pas de
  3 m, rotiri și scări 0,85–1,15 variate, cameră la 35°).

## Rezumat

| piesă | cote măsurate (m) | contract | h/l măsurat / cerut | tri | noduri (slot) |
|---|---|---|---|---:|---|
| `rocks/schist_outcrop_a` | 5,79 × 6,22 × **5,88** | 6 × 5 | **1,11** / 1,2 | 638 | `Schist_Schist` (29), `Schist_Crack` (20) |
| `rocks/schist_outcrop_b` | 6,30 × 8,84 × **3,40** | 3,5 × 8 | **0,48** / 0,45 | 494 | idem |
| `rocks/schist_outcrop_c` | 3,58 × 4,40 × **7,73** | 8 × 4 | **1,97** / 2,0 | 380 | idem |
| `rocks/scree_cone` | **13,49** × 6,81 × **4,13** | Ø 12 × 4 | 0,31 din față* / 0,35 | 1 534 | `Scree_Schist` (29) |
| `plants/jneapan_a` | **4,15** × 3,98 × **1,23** | 1,2 × 4 | 0,30* / 0,3 | 3 792 | `Jneapan_Bark` (9), `Jneapan_Needles` (28) |
| `plants/jneapan_b` | **3,38** × 2,61 × **1,44** | 1,5 × 3 | 0,43* / 0,5 | 3 112 | idem |
| `plants/beech_tree_a` | **11,03** × 9,26 × **12,60** | 13, coroana 10 | **1,15** / 1,3 | 2 846 | `Beech_Bark` (29), `Beech_Leaves` (21) |
| `plants/beech_tree_b` | **10,04** × 6,92 × **10,29** | 10, coroana 9 | **1,07** / 1,1 | 2 532 | idem |
| `plants/bujor_de_munte` | **1,39** × 1,33 × **0,64** | 0,6 × 1,2 | 0,46* / 0,5 | 2 224 | `Bujor_Leaves` (21), `Bujor_Bloom` (31) |
| `plants/afin` | **0,76** × 0,73 × **0,47** | 0,5 × 0,9 | 0,62* / 0,55 | 1 736 | `Afin_Leaves` (21), `Afin_Berry` (25) |

\* Din cotele GLB (înălțime / lățimea cea mai mare). La piesele joase, vederea 3/4
(camera la 24–28°) adaugă adâncimea în înălțimea siluetei; randarea dă 0,51
(grohotiș), 0,62 (bujor) și 0,74 (afin).

Stâncile au originea pe centrul bbox-ului ansamblului, cu baza la 0. Copacii au
originea **la baza trunchiului**, nu pe centrul bbox-ului; fagul b e aplecat și
asimetric. Coliziunea `trunk` a coordonatorului stă la origine. Tufele au
originea în centrul de unde pornesc ramurile. Nicio oglindire (MultiMesh). Scala
și rotația sunt aplicate pe rădăcini, verificate de `verify_transfagarasan.sh`.

## Stâncile — fidelitate

Notă comună: comparația pune `*_Schist` pe #7E8478, deci fețele sunt de un singur
gri-verzui. Pe planșă, fețele luminate sunt bej și cele din umbră aproape negre.
Contrastul de valoare din randare e **mai mic** decât pe planșă: diferența dintre
fețe o fac doar lumina și AO-ul. **Mușchiul verde-galben de pe planșă NU e pus**
(corectura „fără vegetație lipită pe stânci”).

### schist_outcrop_a — commit `628fc359`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| lame ca „cărți aplecate” | 3–4 plăci suprapuse, fețele lungi coboară spre dreapta, fisurile diagonale paralele cu ele | stivă de 4 plăci pe foliație (`foliation_stack`), vârfuri în trepte la 6,1 / 4,9 / 3,6 / 2,4 m | OK |
| lama dominantă | vârf la ~6 m lângă marginea stângă | pana de bază, vârf la 5,88 m (după teșire) | OK |
| înclinarea | fețele lungi la ~50–58° față de orizontală | **68°** față de orizontală | **abatere**: contractul spune ~40°. La 40° față de orizontală, pana de 6 m ar ieși lată de 7,2 m (h/l 0,83). La 50–55°, 4 plăci ies late de 6–7 m. 68° e singura valoare care ține 4 plăci în ~5 m |
| fisurile | rosturi închise, diagonale | rost de 0,14 m + `Schist_Crack` adâncit 0,04 m în rost + AO; plus o bandă de 0,16 m sub lama din față | OK, se citesc ca linii închise diagonale |
| lama joasă din față-stânga | blocul înalt din stânga-jos | 3,2 m, în fața piciorului dominantei | OK |
| blocuri la picior | 8–10 + pietriș mărunt | 6 lespezi | OK (contractul cere 4–6) |
| ordinea luminozităților | bej luminat / gri / fisuri negre | gri uniform / fisuri închise | abatere de preview (clasa), vezi nota |

Runde: 3. (1) lamele erau foi cu fața spre cameră: citire greșită a structurii.
(2) plăci înclinate pe foliație: citeau ca aripioare subțiri, fără fisura
diagonală vizibilă. (3) stivă de 4 plăci subțiri, fisuri vizibile, spate subțiat
(din lateral pană, nu cutie).

### schist_outcrop_b — commit `3136ca4c`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | grup ÎNALT cu 3 vârfuri, aproape identic cu c | **creastă joasă și lată**, după corectura kitului | OK (urmez tabelul) |
| dinte de ferăstrău din lateral | — (tabel) | 3 plăci pe foliație culcată la 27°, dinți la 2,5 / 3,5 / 3,1 m, fiecare ieșit 0,8–1,5 m peste placa de dinainte | OK |
| capătul din aval | — | tăiat de o fractură abruptă (~65°) la 7,7 m | decizie: altfel ultima placă ar coborî până la 10 m |
| fisurile | diagonale | 2 rosturi diagonale `Schist_Crack` | OK |
| blocuri | multe, rotunjite | 5 lespezi plate, îngropate 40% | OK |

Runde: 2. (1) avea și un al 4-lea dinte, o placă subțire care citea ca o cutie
așezată deasupra; blocurile groase citeau ca „picioare”. (2) dintele scos,
lespezile turtite.

### schist_outcrop_c — commit `3136ca4c`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | grup lat cu 2 vârfuri, aproape identic cu b | **un ac**, după corectura kitului | OK (urmez tabelul) |
| acul | — | lamă aproape verticală (foliația la 80°), vârf teșit la 7,73 m, spatele aplecat 7° | OK |
| crăpat pe lung | — | a doua jumătate, de 0,75 m, lipită pe fața acului, cu o fisură aproape verticală de la sol la ~4,4 m | OK |
| umărul la jumătate | — | vârful jumătății a doua tăiat de o diaclază aproape orizontală la ~4,5 m: umăr plat, vizibil din toate azimuturile | OK |
| blocuri | multe | 5 lespezi strânse la picior | OK |

Runde: 3. (1) umărul ieșea o așchie ascuțită: tăietura era aproape paralelă
cu foliația. (2) diaclază orizontală, dar h/l 1,45. (3) ac mai îngust și
blocuri strânse: h/l 1,97.

**Siluetele a / b / c sunt distincte:** a e un ferăstrău de cărți care coboară
de la 6 m, b e o creastă joasă de 8 m, c e un ac de 8 m cu umăr. Se vede în
`transfagarasan_fidelity_val1b_stanci.png`.

### scree_cone — commit `a6fa6958`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| forma | con întreg, liber, ~35° | **jumătate de con** cu latura −Y plană, după contract („lipită de stâncă”), pantă de 34° | OK (urmez contractul) |
| pietre plate | lespezi unghiulare de mărimi variate | 81 de lespezi culcate pe pantă, sortate (0,6–0,9 m sus, 1,1–1,6 m jos), plus 5 lespezi mari (1,5–2,1 m) | OK |
| blocuri la picior | 5–7 mari | 6 (1,2–1,7 m) | OK |
| pietriș pe sol | da | 16 pietre mici până la ~7 m | OK |
| fisuri | umbra dintre pietre | doar AO, fără nod de fisuri (golurile *sunt* fisurile; regula 8 interzice un slot închis întins pe suprafață) | decizie |

Runde: 2. (1) 244 de pietre mărunte, 12,9k tri, citeau ca dale. (2) pietre mai
mari și mai groase, plus lespezile mari.

## Plantele — fidelitate

### jneapan_a, jneapan_b — commit `6067a513`

Preview: `*_Needles` e randat pe #34503A (ținta jneapănului din brief §4). Slotul
LOG_DARK 28 e maro și există doar ca rezervă: culoarea o dă clasa `pine_needles`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| culcat, nu brad mic | ramuri groase radiale pe sol, ridicate la capete | a: 6 ramuri de 1,55–1,9 m, culcate la 0,05–0,2 m, vârfurile la 0,5–0,85 m; b: 5 culcate + 3 scurte care urcă din centru | OK |
| perne de ace | crengi plate ca de ferigă, margine zimțată | 24 de perne plate (a), fiecare un miez plus 3 lobi alternanți pe parte | OK ca formă; **abatere**: lobii au contur poligonal (5 laturi), deci citesc ca bulgări fațetați, nu ca ace pufoase. Netezirea umbririi (runda 3) nu schimbă conturul |
| ramurile maro vizibile | în centru, între perne | da, în centru și la capete | OK |
| b: asimetric, pernă ieșită într-o parte | (planșa b ≈ a) | ramura lungă spre +X cu 4 perne | OK |
| b: mai înalt și compact | — | 1,44 m (contract 1,5), lățime 3,38 m (+13%) | OK în toleranță |
| pâlcul de 8 | — | `jneapan_group.png`: covor jos și continuu pe versant, nu brăduți | OK |

Runde: 3. (1) perne din bile înșirate (mărgele); b avea o bilă mare în centru.
(2) perne plate și zimțate, ramuri care urcă în b. (3) umbrire netedă. Pragul de
75° n-a netezit nimic, fiindcă fețele ciorchinilor cu 5 laturi se întâlnesc la
72–90°. L-am corectat la 100° ca să se aplice ce cerea runda 3; nu l-am numărat
ca rundă nouă.

### beech_tree_a, beech_tree_b — commit `5309e6bf`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| trunchiul | maro, gros, cu rădăcini | **gri, neted** (MARBLE_GREY 29, după contract), Ø 0,84 m (a) / 0,72 m (b), 4 pinteni de rădăcină | OK (urmez contractul) |
| coroana a | ovală, lată, ~15–20 de lobi zimțați | 7 mase (contractul cere 5–7), fiecare cu miez și 7 ciorchini turtiți | OK ca masă și siluetă |
| baza coroanei | ~1/3 din înălțime, brațe vizibile între lobi | ~4,2 m pe laturi; brațele se văd puțin | **abatere**: a citește încă parțial ca „acadea” (coroana pe un trunchi gol). Pe planșă brațele în evantai se văd mult mai clar |
| culoarea coroanei | verde-lime cald | TROPICAL_GREEN #3F7A3C, mai rece și mai închis | de integrare: clasa `beech_canopy` cu tenta recalculată (contract) |
| b: altă siluetă | (planșa b ≈ a) | furcă la 2,7 m, cu doi conducători divergenți vizibili din toate azimuturile, aplecat 5° spre +X, coroană asimetrică și mai joasă, cu o masă joasă ieșită spre +X | OK |
| h/l | — | a 1,15 (cerut 1,3, −12%), b 1,07 (cerut 1,1) | OK în toleranță |

Runde: 3. (1) bule rotunde pe un băț lung, ca o acadea. (2) mase mai joase,
ciorchini mai mari și turtiți. (3) miezul maselor mai mic (core_scale 0,70),
furca lui b coborâtă, conducătorii mai divergenți.

### bujor_de_munte — commit `dfdeb6dd`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| tufă joasă și deasă | da | calotă de 12 ciorchini, 1,39 × 1,33 × 0,64 m | OK (+16% lățime) |
| frunzele de pe margine | rozete ovale, verzi | 12 frunze cu pliu în V, radiale | OK; frunzele sunt mai ascuțite decât rozetele ovale de pe planșă |
| capetele de flori | 6–7 capete mari, ~60% din vederea de sus | 8 capete de ~0,4 m: **53,6%** din suprafața văzută de sus (măsurat pe GLB, z-buffer), contractul cere ~40% | OK |
| culoarea florilor | magenta #B63A7A | FLAMINGO_PINK #D2A0BE, **roz pal** | **măsurat: slotul iese prea pal**. Magenta vine din tenta de la integrare, cum prevede contractul |

Runde: 2. (1) 7 capete mici, ~15% din vederea de sus. (2) 8 capete mari.

### afin — commit `dfdeb6dd`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| tufă măruntă, verde | dreaptă, din crenguțe cu frunze, ca de ferigă | calotă din miez plus 14 crenguțe pe două inele (5 drepte în centru, 9 culcate pe margine) | **abatere**: silueta e corectă, dar citește mai compactă și mai „bulgăroasă” decât crenguțele aerisite de pe planșă |
| bobițele | ~20 de puncte albastre | 20 de bobițe ICE_DEEP de 7 cm, 5,8% din vederea de sus | OK |
| cote | 0,5 × 0,9 | 0,47 × 0,76 (−16% lățime) | abatere mică de lățime |

Runde: 3. (1) movilă de bulgări cu frunze ca foaia, 0,37 m. (2) un singur inel
de crenguțe evazate, deci o vază goală la mijloc. (3) două inele, calotă.

## Decizii luate singur

1. **Fisurile sunt într-un nod separat** (`Schist_Crack`, VOLCANIC_BLACK 20). Clasa
   `tf_schist` pe `*_Schist` e `material_override` și ar șterge slotul închis
   (memoria `clase-pe-piese-de-kit`). Tabelul cere doar `Schist_Schist`;
   integrarea lasă `*_Crack` pe atlas.
2. **Același cadru (s, v) pe toată piesa**, cu foliația coborând la 120° în
   plan. În vederea 3/4 standard, fețele lungi privesc spre cameră și coboară
   spre dreapta, ca pe planșă. La integrare piesele se rotesc oricum aleator.
3. **Înclinarea lui a** e 68°, nu ~40° (vezi tabelul). b e la 27° (contract ~25°)
   și c la 80°.
4. **b și c urmează tabelul**, nu planșa (corectura „variantele diferă ca
   siluetă”). Din planșă iau doar vocabularul.
5. **Grohotișul e jumătate de con**, tăiat plan pe −Y (contractul). Planșa arată
   un con întreg.
6. **Fără mușchi și iarbă pe stânci, fără pietre la baza jnepenilor** (corectura
   kitului: vegetația și decorul se pun la integrare).
7. **Ramurile jneapănului sunt pe WOOD 9.** Tabelul nu dă slot pentru scoarța
   jneapănului; WOOD 9 seamănă cu ramurile maro-portocalii de pe planșă.
8. **Preview**: `_Needles` → #34503A în `CLASS_BY_SUFFIX` și `SPECS` cu elevația
   camerei pentru jneapăn (28°), bujor (26°) și afin (24°), fiindcă plantele joase
   sunt desenate de sus pe planșă.
9. **AO**: `z_range` pornește de la −0,01. Altfel, un z negativ de ordinul 1e-9,
   ridicat la puterea fracționară din `bake_ao`, dă număr complex și build-ul
   crapă (s-a întâmplat la grohotiș).

## Stare la oprire (13 oct 2026)

Făcut: toate cele 10 piese din §1.4 și §1.5, comparațiile, vederile din 4
azimuturi, planșa a | b | c, planșa plantelor și pâlcul de 8 jnepeni. `VERDICT
KIT: OK`. Acceptarea rămâne a coordonatorului.

Abaterile deschise, de la cea mai mare la cea mai mică:
1. `beech_tree_a` citește încă parțial ca „acadea”: brațele se văd puțin.
2. `afin` iese mai compact și mai bulgăros decât crenguțele aerisite; lățimea
   e −16%.
3. Lobii jneapănului au contur poligonal, deci citesc ca bulgări, nu ca ace.
   Clasa `pine_needles` de la integrare poate ajuta, dar nu schimbă conturul.
4. La stânci, contrastul luminat/umbră e mai mic decât pe planșă: preview-ul
   pune toată clasa pe un singur ton. Se judecă în joc.
5. `schist_outcrop_a` e la 68° în loc de ~40°: decizie de cote, nu defect.
6. Bujorul e roz pal pe slot; magenta vine din tenta de la integrare.

Nimic nu e neînceput.
