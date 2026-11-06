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
| `ta_prohm_tree_gate` gresie lat | ~14 | **14,20** |
| vârful gresiei | 7–9 | **7,85** |
| arborele întreg | 18–22 | **21,53** (lat 17,77 cu rădăcini, adânc 12,69 cu bolovanii) |
| gol | ≥ 6,6 | **6,80** (3,40 + 3,40) |
| înălțime liberă în |x|<3,3 (toate nodurile) | ≥ 5,5 | **5,65** (buiandrugul); cea mai joasă rădăcină în fâșie: **5,92** |

Originea: baza, pe axa trecerii (x = 0, y = 0). Scala 1 / rotația identitate pe rădăcini
(verificat). Golul e măsurat din triunghiurile fișierului, tăiate pe banda de înălțime.

## Triunghiuri, materiale, sloturi

- `aw_west_gopura`: **17.302** tri (`Gopura_Stone` 13.398, `Gopura_Lichen` 3.088, `Gopura_Streak` 816).
  3 materiale/noduri: gresie `ROCK_LIGHT` 3; lichen `LAVA_ORANGE` 30 (0,21% din arie) + `CACTUS_GREEN` 12; dâre `VOLCANIC_BLACK` 20.
- `ta_prohm_tree_gate`: **18.904** tri (`TreeGate_Stone` 4.432, `_Lichen` 1.692, `_Streak` 288,
  `_Root` 8.592, `_Canopy` 3.900). 5 materiale: + rădăcini `CORAL_SAND` 19 (AO cald, exponent
  per canal 1,0/1,3/1,7) și coronament `TROPICAL_GREEN` 21 (mase de elipsoizi, fără alpha).
- Fără alb, fără `ROCK_DARK`, fără texturi proprii. Bevel 0 pe toate nodurile. Fără fețe.
- Primitive rotunde: bobocuri 14 laturi, rădăcini 8, trunchi 10–12, coroană 10×6.

## Fidelitate (după runda finală)

| element | pe desen | în GLB | verdict |
|---|---|---|---|
| gopura: siluetă | 3 turnuri, galerii joase, poarta înaltă | 3 turnuri (15,9 / 11,3 m), galerii de 7,3 m, gol de 10 × 9 m | citește ca poartă-galerie; **mai blocată și mai „în trepte”** decât desenul |
| gopura: turnul central | fronton în arc ornat, vârf de boboc | cornișă + soclu în trepte + 3 etaje + boboc, frontoane de placi pe ambele fețe | **abatere:** frontonul e o stivă de plăci, nu arc ornat; bobocul e mic |
| gopura: galerii | acoperiș înclinat cu țigle, colonadă | acoperiș în 5 trepte cu antefixe, colonadă pe fiecare parte, zid cu blocuri | acoperișul e în trepte, nu pantă; stâlpii citesc bine |
| gopura: turnuri de capăt | înalte, cu fronton | 11,3 m, portic cu fronton de plăci pe fiecare parte | citesc; mai scunde decât pe desen |
| gopura: lichen/dâre | lichen verde-galben peste tot | pete mici (0,21% portocaliu), dâre scurte | **abatere voită** (contract) |
| tree gate: poarta | arc scund de blocuri, ruină | picioare cu blocuri, buiandrug, cornișă ruinată (jumătate mai joasă), aripi și stâlpi rupți, bolovani | citește ca poartă ruinată, dar **mică** sub arbore |
| tree gate: rădăcini | cascadă deasă peste tot zidul | 10 mari + 4 secundare + 6 contraforturi pe trunchi, groase, spline | **cea mai slabă piesă:** puține și netede față de desen; citesc ca „copac peste ruină”, dar încă puțin ca „lighioane” din unele unghiuri |
| tree gate: coroană | frunziș în plasă | ~13 mase rotunde | **abatere:** ciupercă/brocoli, nu coroană de ficus |

## Runde

Gopura: **runda 1** (primul build): turn central prea plat, soclu lat de 17,8 m care domina;
**runda 2:** soclu în trepte sub turn, TOP 15,9, bobocul mai înalt. Garda a prins un defect
real: umflăturile pilaștrilor de la gol intrau la 4,98 m de axă (golul 9,96 < 10,0, înălțime
liberă 1,0 din treapta pilastrului) — fixat, umflătura nu mai iese spre axă (gol 10,10).
Tree gate: **runda 1:** rădăcini subțiri ca picioare de păianjen, trunchi conic subțire, poarta
pierdută sub coroană; **runda 2:** trunchi 1,8–3,0 m, rădăcini ×1,5 (cascada R2 exceptată, ca să
rămână ≥ 5,5), a doua cascadă R3, capetele rădăcinilor mai aproape de zid; **runda 3:** raza
×1,25, contraforturi pe trunchi (nu mai e con neted), bolovani pe cornișă, R5 lipit de aripi.
Nu am mai iterat după a treia.

## Abateri și deschise

1. Frontoanele și bobocurile sunt simplificate (decizia dezvoltatorului): plăci și forme mari.
2. Gopura are adâncime 11,0 (scările porticelor ies la ±5,5); golul și lungimea sunt în contract.
3. Rădăcinile sunt tuburi netede, culoare plată `CORAL_SAND` + AO cald; fără noduri/striații.
4. Coroana e din elipsoizi: dimensiunea corectă, forma de brocoli.
5. Sabotajele din `--selftest` sunt făcute pe lista de triunghiuri citită din fișier (în
   memorie), nu pe copii GLB rescrise; garda pică pe toate 9 și trece pe originale.
6. Fără `Gate_*`: numele nodurilor sunt `TreeGate_*`/`Gopura_*` cum cere sarcina (kit §1.2 spunea `Gate_*`).

## Camera de joc (`--gamecam`) — citire onestă, nu acceptare

Gopura: la 30 m în față, cu camera de joc, citește clar ca **poartă lată cu trei turnuri**, golul
de 10 m se vede ca dreptunghi curat, colonadele și zidul cu blocuri se disting; trăsăturile mici
(antefixe, pete) se pierd. Poarta-copac: din cameră se vede un **trunchi ca un con neted** peste o
masă de rădăcini groase și o poartă mică și întunecată; coroana iese din cadru (camera la 10 m).
Citește „copac peste ruină”, dar fără detaliul rădăcinilor din desen; verdictul îl dă criticul orb.
