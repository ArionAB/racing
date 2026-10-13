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

| piesă | cote măsurate (m) | contract | h/l măsurat / cerut | tri (înainte → acum) | noduri (slot) |
|---|---|---|---|---:|---|
| `rocks/schist_outcrop_a` | 6,43 × 6,81 × **5,97** | 6 × 5 | **0,99** cu moloz (1,11 fără) / 1,2 | 638 → **936** | `Schist_Schist` (29), `Schist_Crack` (20) |
| `rocks/schist_outcrop_b` | 6,86 × 8,85 × **3,49** | 3,5 × 8 | **0,56** cu moloz (0,48 fără) / 0,45 | 494 → **806** | idem |
| `rocks/schist_outcrop_c` | 3,96 × 5,02 × **7,86** | 8 × 4 | **1,78** cu moloz (1,97 fără) / 2,0 | 380 → **624** | idem |
| `rocks/scree_cone` | **13,49** × 6,81 × **4,13** | Ø 12 × 4 | 0,31 din față* / 0,35 | 1 534 | `Scree_Schist` (29) |
| `plants/jneapan_a` | **4,12** × 3,87 × **1,15** | 1,2 × 4 | 0,28* / 0,3 | 3 792 → **1 392** | `Jneapan_Bark` (9), `Jneapan_Needles` (28) |
| `plants/jneapan_b` | **3,32** × 2,73 × **1,35** | 1,5 × 3 | 0,41* / 0,5 | 3 112 → **1 322** | idem |
| `plants/beech_tree_a` | **10,27** × 10,70 × **11,55** | ~12,5, coroana ~10 | **0,99** / ~1,3 (decuparea: 0,97) | 2 846 → **3 054** | `Beech_Bark` (29), `Beech_Leaves` (21) |
| `plants/beech_tree_b` | **10,04** × 6,92 × **10,32** | 10, coroana 9 | **1,07** / 1,1 | 2 532 → **2 590** | idem |
| `plants/bujor_de_munte` | **1,39** × 1,33 × **0,64** | 0,6 × 1,2 | 0,46* / 0,5 | 2 224 | `Bujor_Leaves` (21), `Bujor_Bloom` (31) |
| `plants/afin` | **0,85** × 0,93 × **0,50** | 0,5 × 0,9 | 0,54* / 0,55 | 1 736 → **1 764** | `Afin_Leaves` (21), `Afin_Berry` (25) |

\* Din cotele GLB (înălțime / lățimea cea mai mare). La piesele joase, vederea 3/4
(camera la 24–28°) adaugă adâncimea în înălțimea siluetei; randarea dă 0,51
(grohotiș), 0,48 / 0,50 (jneapăn a / b), 0,62 (bujor) și 0,64 (afin).

## Verdictele coordonatorului (13 oct) și ce s-a făcut

| piesă | verdict | ce s-a făcut | commit |
|---|---|---|---|
| `schist_outcrop_a/b/c` | acceptate cu reglaj mic | vârfuri **teșite**: fața ruptă are cel puțin **0,4 m** (`tip_w` în `slab_profile`/`foliation_stack`, cota cerută e a feței rupte); **moloz la picior**: 12/12/10 blocuri de 0,3–1,2 m (mare/mediu/mic, sprijinite de stâncă, `foot_rubble`) | `c67ba308`, `1da01f73`, `8e1aecd4` |
| `scree_cone` | acceptat | — | `a6fa6958` |
| `bujor_de_munte` | acceptat | — | `dfdeb6dd` |
| `afin` | acceptat cu reglaj mic | **29 de bobițe** vizibile (pe suprafața ciorchinilor, spre exterior), frunziș aerisit (miez mai mic, 8 crenguțe exterioare cu goluri), lățimea 0,93 m | `a5ac4e80` |
| `jneapan_a/b` | de refăcut (max 2 runde) | plăci plate de ace, ≤ 1 500 tri: 1 392 / 1 322 (erau 3 792 / 3 112). 2 runde. Pâlcul de 8 regenerat | `15568069`, `02159da3` |
| `beech_tree_a` | de refăcut (max 2 runde) | trunchi scurt și gros, 4 brațe în evantai, coroană joasă și lată, cu goluri. 2 runde | `f742f432` |
| `beech_tree_b` | rămâne, cu trunchiul îngroșat | trunchi Ø 0,76 m, conducători Ø 0,52 m, pinteni scurți | `a9fa799f` |

Notă: `build_tf_plants.py` e un singur fișier, așa că modificările de parametri de
la afin au intrat în același diff cu commit-ul lui `beech_tree_a` (`f742f432`).
Commit-ul `a5ac4e80` aduce GLB-ul și capturile afinului.

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

**Reglaj (13 oct), comun a/b/c.** Toate vârfurile sunt acum fețe rupte plane
de cel puțin 0,4 m. Teșitura mare (~1,35 m pe fiecare față, la vârfurile de 17°)
e compensată în cotă: `height` e cota feței rupte. Molozul de la picior are
blocuri de 0,3–1,2 m, cu grosimea 45–70% din latură, pe tot perimetrul
amprentei. Molozul lărgește silueta, așa că h/l scade la a (0,99) și c (1,78).
La b crește la 0,56, fiindcă blocurile din față coboară baza siluetei în
vederea 3/4. **Abatere rămasă:** pe planșă molozul e mai dens (10–15 blocuri
plus pietriș mărunt); la noi cam jumătate din blocuri stau în spatele stâncii în
vederea 3/4.

### schist_outcrop_a — commit `628fc359` (+ reglaj `c67ba308`)

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

### schist_outcrop_b — commit `3136ca4c` (+ reglaj `1da01f73`)

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

### schist_outcrop_c — commit `3136ca4c` (+ reglaj `8e1aecd4`)

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

### jneapan_a, jneapan_b — REFĂCUT: `15568069`, `02159da3` (prima versiune `6067a513`)

Preview: `*_Needles` e randat pe #34503A (ținta jneapănului din brief §4). Slotul
LOG_DARK 28 e maro și există doar ca rezervă: culoarea o dă clasa `pine_needles`.

Contractul clarificat de coordonator cere perne = **plăci plate de ace**:
- alungite de-a lungul ramurii, ca frunzele de ferigă;
- 0,8–1,2 × 0,4–0,6 × 0,15–0,25 m;
- marginea zimțată pe lung;
- suprapuse ca solzii, aproape orizontale, ridicate la capete;
- ≤ 1 500 tri pe variantă.

`needle_pad` e rescris ca placă: contur stelat zimțat, cu evantai sus și jos și
o bandă laterală, 4·(4·teeth+2) = 56 tri la 3 dinți.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| culcat, nu brad mic | ramuri groase radiale pe sol, ridicate la capete | a: 6 ramuri de 1,55–1,9 m, culcate, vârfurile la 0,5–0,85 m; b: 5 culcate + 3 care urcă din centru | OK |
| perne de ace | crengi plate ca de ferigă, zimțate, suprapuse | a: 21 de plăci (3 pe ramură + 3 în centru); b: 19. Toate de 0,85–1,15 × 0,64–0,80 × 0,16 m, cu 3 zimți adânci pe parte și ridicate spre capăt cu 3–34° | OK. Lățimea plăcilor (0,64–0,80 m) e peste intervalul cerut de 0,4–0,6: în runda 1, la 0,5–0,6 m, citeau ca bare înguste de cărămidă, iar planșa le arată late |
| suprapuse ca solzii | da | fiecare placă următoare puțin mai sus, alternând stânga/dreapta ±0,07 m și ±6–12° | OK |
| ramurile maro vizibile | în centru | da, printre plăci | OK |
| b: asimetric și compact | — | ramura lungă spre +X; 1,35 m înălțime (contract 1,5, −10%); h/l 0,41 din cote (cerut 0,5, −18%) | abatere mică |
| buget | ≤ 1 500 | **1 392 / 1 322** (erau 3 792 / 3 112) | OK |
| pâlcul de 8 | covor jos | `jneapan_group.png`: covor continuu de ferigi joase, nu brăduți | OK |

Runde, după clarificarea contractului: 2.
1. Plăci de 0,5–0,6 m, zimți puțin adânci: citeau ca bare cu margine vălurită,
   iar tufa era rară, ca o stea de mare.
2. Plăci mai late, mai subțiri și cu zimți mai adânci; b cu 3 plăci pe ramură.

`JNEAPAN_SMOOTH` = 50°: evantaiul de sus se netezește, iar muchiile laterale
rămân vii.

### beech_tree_a — REFĂCUT: `f742f432` (prima versiune `5309e6bf`)

| element | pe planșă / contract clarificat | în GLB | verdict |
|---|---|---|---|
| trunchiul | scurt și gros, Ø 0,7 m, rădăcini evazate, 3 m până la ramificare | Ø 0,70 m, 5 pinteni scurți și groși, ramificat la 2,9 m; gri (29), închis la bază prin AO (low 0,42) | OK. Pe planșă trunchiul pare mai gros (~0,9 m raportat la coroană): am urmat cota |
| brațele | 3–4 brațe groase în evantai | 4 brațe de Ø 0,44 → 0,24 m, de la 2,9 m la 4,9 m, la 2,6 m de axă; se văd sub coroană din toate azimuturile | OK |
| coroana | joasă și lată, ~10 m, aproape rotundă (h/l coroană ≈ 0,85) | lată de 10,3–10,7 m, baza la ~3,8 m, vârful la 11,55 m: h/l coroană ≈ 0,74 | **abatere**: mai turtită decât cere contractul |
| golurile de jos | brațele se văd prin coroană | inel de 4 mase cu ciorchini doar de la ecuator în sus, cu goluri pe azimuturile dintre brațe | OK. În vederea 3/4, golul de pe axă citește ca o „gaură” la mijlocul coroanei: abatere mică |
| h/l total | ~1,3 | **0,99** (decuparea măsoară 0,97) | **abatere** față de contract (−24%), aproape de planșă |
| culoarea coroanei | verde-lime cald | TROPICAL_GREEN #3F7A3C, mai rece | de integrare (clasa `beech_canopy`) |

Runde, după clarificare: 2.
1. Coroana corectă ca structură, dar o coloană îngustă de 9 m, etajată; pinteni
   ca „picioare de păianjen”.
2. Masele mutate spre exterior, vârful lat și turtit, pinteni scurți și groși.
   S-a pierdut h/l-ul: 1,32 în runda 1, 0,99 acum.

### beech_tree_b — commit `5309e6bf` (+ reglaj `a9fa799f`)

Silueta e neschimbată: furcă la 2,7 m, aplecat 5° spre +X, coroană asimetrică și
joasă din 6 mase. Reglajul îngroașă trunchiul (Ø 0,76 m), conducătorii (Ø 0,52 m)
și pintenii. h/l 1,07 (cerut 1,1).

### bujor_de_munte — commit `dfdeb6dd`

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| tufă joasă și deasă | da | calotă de 12 ciorchini, 1,39 × 1,33 × 0,64 m | OK (+16% lățime) |
| frunzele de pe margine | rozete ovale, verzi | 12 frunze cu pliu în V, radiale | OK; frunzele sunt mai ascuțite decât rozetele ovale de pe planșă |
| capetele de flori | 6–7 capete mari, ~60% din vederea de sus | 8 capete de ~0,4 m: **53,6%** din suprafața văzută de sus (măsurat pe GLB, z-buffer), contractul cere ~40% | OK |
| culoarea florilor | magenta #B63A7A | FLAMINGO_PINK #D2A0BE, **roz pal** | **măsurat: slotul iese prea pal**. Magenta vine din tenta de la integrare, cum prevede contractul |

Runde: 2. (1) 7 capete mici, ~15% din vederea de sus. (2) 8 capete mari.

### afin — commit `dfdeb6dd` (+ reglaj `a5ac4e80`)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| tufă măruntă, verde | dreaptă, din crenguțe cu frunze, ca de ferigă | calotă: miez mic plus 13 crenguțe pe două inele (5 drepte în centru, 8 culcate pe margine, cu goluri între ele) | OK. Rămâne puțin mai „bulgăroasă” decât planșa |
| bobițele | ~20 de puncte albastre, la vedere | **29** de bobițe ICE_DEEP de 7 cm, pe suprafața ciorchinilor, spre exterior și sus. În vederea 3/4 se văd ~20 | OK (reglaj: 20–30) |
| cote | 0,5 × 0,9 | 0,50 × 0,93 | OK |

Runde: 3, plus reglajul de parametri al coordonatorului.

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

## Stare la oprire (13 oct 2026, după verdictele coordonatorului)

Făcut: toate cele 10 piese din §1.4 și §1.5, plus reglajele și refacerile cerute
pe 13 oct:
- vârfuri teșite și moloz pe a/b/c;
- afin cu 29 de bobițe, aerisit, la cotă;
- jneapăn din plăci plate, sub 1 500 tri, cu pâlcul de 8 regenerat;
- fagul a refăcut, fagul b cu trunchiul îngroșat.

Comparațiile, vederile din 4 azimuturi și planșele `val1b_stanci` / `val1b_plante`
sunt regenerate. `VERDICT KIT: OK`.

Abaterile deschise, de la cea mai mare la cea mai mică:
1. `beech_tree_a`: h/l 0,99 față de ~1,3 cerut (decuparea măsoară 0,97).
   Coroana e mai turtită (0,74 față de 0,85). Pe axă, în vederea 3/4, apare
   un gol ca o gaură.
2. Molozul de la picioarele stâncilor e mai rar decât pe planșă (10–15 blocuri
   plus pietriș). Cu el, h/l iese 0,99 (a) și 0,56 (b), în afara toleranței.
   Fără moloz, h/l era 1,11 și 0,48.
3. `jneapan_b` e mai scund decât cota (1,35 m față de 1,5); plăcile de ace sunt
   mai late decât intervalul cerut, deliberat (vezi tabelul).
4. La stânci, contrastul luminat/umbră din preview e mai mic decât pe planșă,
   fiindcă clasa pune un singur ton. Se judecă în joc.
5. Bujorul e roz pal pe slot; magenta vine din tenta de la integrare.

Nimic nu e neînceput.
