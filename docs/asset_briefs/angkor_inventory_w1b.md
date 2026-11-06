# Inventar — kit Angkor, val 1, grupul B (poarta Angkor Wat + poarta-copac)

Contract: `docs/asset_briefs/angkor_kit.md` §1.2. Build: `tools/blender/build_angkor_gates_w.py`
(docstring = lista de elemente, scrisă înainte de geometrie). Gardă:
`tools/blender/measure_angkor_w1b.py` (în `verify_angkor.sh`, blocul `# --- val 1, grupul B ---`).
Randări: `tools/blender/preview_angkor_w1b.py` (înveliș peste `preview_angkor.py`, fără să-l
modifice). Imagini: `docs/asset_briefs/img/angkor_fidelity/<nume>{,_views,_gamecam}.png`.
Singura modificare în harnasul comun: `emit_angkor` primește `anchor=(x,y)` (originea pe axa
trecerii, nu pe centrul bbox) și `ao_tint` (umbre calde pe rădăcini); compatibil înapoi.

## Cote măsurate din fișier (coordonate Godot)

| | contract | măsurat |
|---|---|---|
| `aw_west_gopura` lungime (X) | 50–56 | **52,00** (−26…+26) |
| înălțime | turn 14–16 | **15,91** |
| adâncime (Z, cu scările porticelor) | ~10 | **11,00** |
| gol la 0–2,5 m (proiecție pe secțiune) | ≥ 10,0 | **10,10** (5,05 + 5,05) |
| înălțime liberă în |x|<5,0 | ≥ 8,0 | **9,00** |
| `ta_prohm_tree_gate` gresie lat | ~14 | **14,10** |
| vârful gresiei | 7–9 | **7,80** |
| arborele întreg | 18–22 | **21,30** (lat 20,18 cu rădăcini, adânc 12,13) |
| gol | ≥ 6,6 | **6,80** (3,40 + 3,40) |
| înălțime liberă în |x|<3,3 (toate nodurile) | ≥ 5,5 | **5,60** (buiandrugul); cea mai joasă rădăcină în fâșie: **5,96** |

Originea: baza, pe axa trecerii (x = 0, y = 0). Scala 1 / rotația identitate pe rădăcini
(verificat). Golul e măsurat din triunghiurile fișierului, tăiate pe banda de înălțime.

## Triunghiuri, materiale, sloturi

- `aw_west_gopura`: **21.950** tri (`Gopura_Stone` 18.046, `Gopura_Lichen` 3.088, `Gopura_Streak` 816).
  3 materiale/noduri: gresie `ROCK_LIGHT` 3; lichen `LAVA_ORANGE` 30 (0,21% din arie) + `CACTUS_GREEN` 12; dâre `VOLCANIC_BLACK` 20.
- `ta_prohm_tree_gate`: **19.828** tri (`TreeGate_Stone` 6.016, `_Lichen` 1.692, `_Streak` 288,
  `_Root` 8.232, `_Canopy` 3.600). 5 materiale: + rădăcini `CORAL_SAND` 19 (AO cald, exponent
  per canal 1,0/1,3/1,7) și coronament `TROPICAL_GREEN` 21 + ciorchini `CACTUS_GREEN` 12 (mase de elipsoizi, fără alpha).
- Fără alb, fără `ROCK_DARK`, fără texturi proprii. Bevel 0 pe toate nodurile. Fără fețe.
- Primitive rotunde: bobocuri 14 laturi, rădăcini 8, trunchi 10–12, coroană 10×6.

## Fidelitate (după runda de formă cerută de coordonator)

| element | pe desen | în GLB | verdict |
|---|---|---|---|
| gopura: acoperișuri | pantă cu țigle, creastă | **înveliș convex pantat** (streașină 4,8 m, creastă 7,75 m) cu nervuri de țiglă de la creastă la streașină, antefixe pe streașină | citește ca acoperiș pantat; mai bombat (butoi) decât panta dreaptă a desenului |
| gopura: turnuri | boboc de lotus din etaje rotunde | central și de capăt: bază pătrată cu blocuri, **etaje rotunde bombate** (4 / 3) sub cornișe evazate, boboc de lotus | citesc ca turnuri-boboc; **mai scunde și mai simple** decât desenul (central 15,9 m, capăt 12,5 m) |
| gopura: trecerea | frontonul ascuțit ridică turnul | turnul urcă direct din blocul trecerii (bază pătrată peste cornișă); **fronton ascuțit cu cadru ridicat** (două prisme, apex la 12 m) pe ambele fețe, deasupra cotei 9,0 | citește; fără ornamente de flacără |
| gopura: porticuri | fronton mic + portic | fronton ascuțit cu cadru, 2 stâlpi, trepte, pe fiecare galerie, față/spate | OK |
| gopura: lichen/dâre | lichen verde-galben peste tot | pete mici, 0,29% portocaliu, dâre scurte | **abatere voită** (contract) |
| tree gate: piatra | galerie ruinată pe ambele părți ale golului | picioare cu blocuri + **aripi pe ambele părți** (3 tronsoane cu vârfuri inegale, 2,4–6,0 m), stâlpi rupți, blocuri de acoperiș prăbușite, bolovani pe cornișă și la bază (doar la \|x\| ≥ 4,5), cornișă ruinată (7,8 / 7,45 m) | gresia are 14,1 m și o siluetă inegală, dar **rămâne joasă** sub rădăcini; din cameră stâlpii aripilor aproape nu se văd |
| tree gate: copacul | pe ruină, decalat | trunchi la x = 3,4 (decalat de axă), 7,3 → 14 m, evazat gros în acoperiș (R 3,0), 6 contraforturi, 4 ramuri | decalarea citește; trunchiul rămâne un con cu fațete |
| tree gate: rădăcini | peste piatră, lipite | 4 mari (peste placă → fața cornișei și a piciorului; cascadă peste buiandrug spre piciorul stâng; peste aripi) × față/spate + 8 subțiri, raze 0,95 → 0,1 de-a lungul fiecăreia | **lipite de suprafețe**, nu mai atârnă în aer; dar **netede și drepte ca țevile**, citesc ca „picioare” în unele unghiuri; mult mai puține decât în desen |
| tree gate: coroană | masă neregulată | 12 mase late la înălțimi diferite, 4 din ele `CACTUS_GREEN` mai deschise | mai plată și neregulată, încă „nori rotunzi” |

## Runde

**Runda 1–3 (gopura 2, tree gate 3).** Vezi istoricul din commit-ul anterior: soclu în trepte sub turn,
defectul prins de gardă (pilaștrii la 4,98 m de axă) la gopura; la poarta-copac rădăcini subțiri →
mai groase → contraforturi.

**Runda 4 (corectura de formă a coordonatorului).**
- *Gopura:* acoperișul în trepte a devenit înveliș pantat (`PROF` 6 puncte, hull convex) cu nervuri de
  țiglă generate pe segmente; turnurile din prisme octogonale → `round_tier`/`lotus_tower` (etaje de
  revoluție bombate + cornișă evazată + `lotus_bud`); blocul trecerii urcă direct în turn (boltă în 2
  trepte, cornișă, bază pătrată de 8 × 7,4 m în loc de soclul lat), frontoane ascuțite cu cadru ridicat
  (`gable`); turnurile de capăt mai înalte (12,5 m), cu bază patrată și porticuri cu fronton ascuțit.
  Golul (10,10), înălțimea liberă (9,00) și lungimea (52,00) neschimbate; garda verde.
- *Poarta-copac:* piatra rescrisă ca galerie pe ambele părți (aripi cu 3 tronsoane, stâlpi, blocuri
  prăbușite); copacul mutat pe ruină (x = 3,4); rădăcinile scrise cu puncte de-a lungul suprafețelor
  reale (placă → cornișă → fața piciorului → sol; aripi), 4 mari + 8 subțiri cu raza variind pe
  lungime; coroană lată, neregulată, cu ciorchini de `CACTUS_GREEN`. Golul (6,80) și înălțimea liberă
  (5,60 piatră / 5,96 rădăcină) rămân; garda verde. Nu am iterat mai departe.

## Abateri și deschise

1. Frontoanele și bobocurile sunt simplificate (decizia dezvoltatorului): plăci și forme mari.
2. Gopura are adâncime 11,0 (scările porticelor ies la ±5,5); golul și lungimea sunt în contract.
3. Rădăcinile sunt tuburi netede, culoare plată `CORAL_SAND` + AO cald; fără noduri/striații.
4. Coroana e din elipsoizi: dimensiunea corectă, forma de brocoli.
5. Sabotajele din `--selftest` sunt făcute pe lista de triunghiuri citită din fișier (în
   memorie), nu pe copii GLB rescrise; garda pică pe toate 9 și trece pe originale.
6. Fără `Gate_*`: numele nodurilor sunt `TreeGate_*`/`Gopura_*` cum cere sarcina (kit §1.2 spunea `Gate_*`).

## Camera de joc (`--gamecam`) — citire onestă, nu acceptare

Gopura: la 30 m în față, cu camera de joc, citește ca **poartă lată cu trei turnuri și acoperișuri pantate**, golul
de 10 m se vede ca dreptunghi curat, colonadele și zidul cu blocuri se disting; trăsăturile mici
(antefixe, pete) se pierd. Poarta-copac: golul e încadrat de picioare și aripi, iar rădăcinile curg peste cornișă și pe
fața piciorelor (lipite), dar de la distanță masa rădăcinilor domină piatra și citește ca un
copac-„păianjen” așezat pe o bancă joasă; trunchiul e un con. Coroana iese din cadru.
Verdictul îl dă criticul orb.
