# Inventar — kit Carrara, val 1, constructorul crr-c (kitul de carieră, §1.5)

Contract: `docs/asset_briefs/carrara_kit.md` §1.5. Fișierul ăsta e al grupei
crr-c; coordonatorul îl contopește cu `carrara_inventory.md` la integrare.

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_crr_kit.py` | cele 17 piese; docstring-ul fiecărei funcții = lista de elemente, scrisă înainte de geometrie, cu rundele notate. Ajutoare proprii (nu în `carrara_shapes.py`): `open_box`, `split_block`, `chip_pts` (cutie cu colțuri sparte plan), `clip_z` / `hull_two_tone` (hull tăiat la sol și la cota patinei), `emit_kit` (ca `emit_crr`, plus offset explicit și `z_range` AO pe ansamblu) |
| `tools/blender/preview_crr_kit.py` | refolosește `preview_carrara.py`: `--compare a,b,c`, `--blocks` (12 blocuri), `--chain <nume> <n>`, `--lineup <tag> a,b` |
| `tools/blender/measure_crr_kit.py` | garda kitului: noduri, cote față de tabel, sloturi interzise (FOAM_WHITE 22, CAR_* 14–16), capete identice la module |
| `tools/blender/verify_carrara.sh` | doar declarații adăugate: secțiunea „val 1, crr-c” |

Rulare: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_crr_kit.py` (`CRR_ONLY=a,b` reface doar piesele date). Build-ul e determinist: o reconstruire completă lasă GLB-urile identice la bit (`git status` curat).

## Cote măsurate (din GLB, coordonate Godot: X lățime, Y sus, Z lungime)

| piesă | măsurat X × Y × Z | contract | tri | noduri (tri) |
|---|---|---|---:|---|
| `rocks/marble_block_a` | 1,50 × 1,50 × 1,50 | cub 1,5 | 20 | `Block_Marble` 10, `Block_MarbleBase` 10 |
| `rocks/marble_block_b` | 2,00 × 2,00 × 2,01 | cub 2 (+1 cm dunga) | 32 | + `Block_Paint` 12 (LAVA_ORANGE, 0,14 m²) |
| `rocks/marble_block_c` | 3,00 × 2,00 × 2,00 | 3 × 2 × 2 | 20 | ca `_a` |
| `rocks/block_stack_a` | 2,21 × 2,95 × 1,96 | 2 blocuri de ~2 m | 32 | `Stack_Marble` 22, `Stack_MarbleBase` 10 |
| `rocks/block_stack_b` | 2,32 × 3,60 × 2,14 | 3 blocuri de ~2 m | 44 | `Stack_Marble` 34, `Stack_MarbleBase` 10 |
| `rocks/block_informe_b` | 2,39 × 1,57 × 2,14 | ~2 m, mai turtit decât `_a` (3 m) | 306 | `Informe_Marble` 226, `Informe_MarbleBase` 80 |
| `rocks/rubble_pile_a` | 3,90 × 1,44 × 4,01 | Ø 4, 1,5 | 944 | `Rubble_Marble` 888 (25 fragmente), `Rubble_MarbleBase` 56 (miezul) |
| `rocks/rubble_pile_b` | 2,73 × 1,20 × 3,07 | Ø 3, 1,2 | 824 | `Rubble_Marble` 768 (22 fragmente), `Rubble_MarbleBase` 56 |
| `structures/safety_berm` | 1,37 × 0,62 × **6,00** | 1,4 × 0,6 × 6 | 982 | `Berm_Marble` 966, `Berm_MarbleBase` 16 |
| `props/work_lamp` | 1,60 × 2,98 × 1,54 | 3 m | 1.488 | `Lamp_Body` 1.464, `Lamp_Glow` 24 |
| `props/cable_reel` | 1,12 × 1,70 × 1,60 | Ø 1,6, 1 m lat | 2.112 | `Reel_Body` |
| `props/water_tank` | 2,06 × 3,00 × 2,01 | Ø 2, 3 m | 1.522 | `WaterTank_Body` |
| `props/fuel_tank` | 2,01 × 2,42 × 3,88 | 4 × 2, 2,4 | 1.484 | `FuelTank_Body` |
| `buildings/office_container` | 6,00 × 2,60 × 2,92 | 6 × 2,5 × 2,6 | 2.772 | `Office_Body` |
| `props/quarry_sign_a` | 1,20 × 1,80 × 0,18 | panou 1,2 × 0,8, stâlpi 1,8 | 260 | `Sign_Body` |
| `props/quarry_sign_b` | 1,20 × 1,80 × 0,18 | idem | 328 | `Sign_Body` |
| `props/pipe_run` | 0,80 × 1,52 × **6,00** | modul 6, 2 × Ø 0,4 | 672 | `Pipe_Metal` 636, `Pipe_Marble` 36 |

Note la cote:
- container: Z 2,92 = cutia de 2,50 + treptele (0,36) + traversele; originea e
  pe centrul **cutiei**, nu al bbox-ului (`place` explicit), deci treptele nu
  mută originea. La fel `fuel_tank`: originea pe axa rezervorului, scara iese
  0,2 m pe −X (în Godot).
- `marble_block_b`: dunga iese 1 cm pe fața +Y (Blender), deci Z = 2,01;
  originea a rămas pe centrul blocului.
- `safety_berm` și `pipe_run`: exact 6,000 m, capete la ±3.
- Scala 1 și rotația identitate pe toate rădăcinile (garda din `verify_carrara.sh`).
- Primitive rotunde: 8–16 laturi (catarg 8, conducte 12, rezervoare 14, tambur 16).
- Sloturi folosite: 19, 29, 30 (blocuri); 13, 20, 0 (lampa); 9, 28, 20, 10
  (tambur); 11, 10, 20 (rezervorul de apă); 10, 20 (motorină); 8, 6, 9, 20
  (container); 13, 20, 10 (semne); 11, 10, 19 (conducte). Niciun FOAM_WHITE,
  niciun CAR_*.

## Decizia pentru blocurile de 12 triunghiuri

Tabelul cere „cutie de 12 triunghiuri” **și** (aceeași secțiune) separarea
`*_Marble` / `*_MarbleBase` a regulii 8. Cele două nu se pot avea simultan:
un singur corp de 12 triunghiuri are un singur slot. Am ales **două noduri**
(regula 8 e numită explicit ca excepție în §1.5, iar patina gri a bazei e ce
desparte blocul de un cub de zahăr / de zăpadă), dar **fără fața comună**:
baza are 5 fețe (fără capac), partea în lumină 5 fețe (fără fund) →
**20 de triunghiuri**, nu 24. Cost real pe GPU: neglijabil; costul care
contează la MultiMesh e numărul de suprafețe (2 pe variantă, 3 pe `_b`).
Dacă integrarea dă aceeași clasă `carrara_marble` ambelor noduri fără o
tentă diferită, tonul patinei se pierde oricum în joc și nodurile se pot
contopi la 12 triunghiuri — decizia de clasă e a coordonatorului.

Corpurile `*_Marble` ale blocurilor sunt cutii deschise (fără fund): un
colizor `hull` din vârfuri rămâne solid, dar un colizor `mesh` (trimesh) pe
nodul `*_Marble` singur ar avea gaură jos. Recomandare: colizor `box`/`hull`
pe ansamblu.

## Capturi de grup

- `docs/asset_briefs/img/carrara_fidelity/marble_blocks_group12.png` — comparația
  izolată a lui `_b` și **12 blocuri** (3 × `_c`, 4 × `_b`, 5 × `_a`), două stive.
  Marmura citește **crem** (#E8D6B2, ținta clasei în preview) cu patina gri la
  bază, nu alb. **Nevăzut:** culoarea reală în joc, cu clasa `carrara_marble`,
  soarele temei și ceața — preview-ul pune doar ținta clasei.
- `safety_berm_chain4.png` — 4 module (din −X, spre drum, și din +X, spre gol):
  fără cusătură vizibilă. Măsurat: capacele de la −3 și +3 au aceeași arie
  (0,6296 m²) și se acoperă reciproc (`measure_crr_kit.py`).
- `pipe_run_chain3.png` — 3 module; la îmbinare se întâlnesc două flanșe
  (voit). Capace 0,6774 / 0,6774 m².
- `crr_kit_lineup_rocks.png`, `crr_kit_lineup_props.png` — toate piesele la
  aceeași scară, strânse, ca să se poată judeca cele mici.
- `docs/asset_briefs/img/carrara_fidelity_val1c.png` — planșa cu toate cele 17
  comparații, una sub alta (`preview_carrara.py --sheet 1c ...`).

Garda capetelor a fost **verificată pe sabotaj**: o cutie de 8 cm lipită doar
de capătul +3 al bermei → „arii diferite: 0,6376 / 0,6296”, kitul pică; fără
ea, trece. (Prima variantă a gărzii compara liste de vârfuri și pica fals: un
hull păstrează uneori un vârf coliniar pe o latură la un capăt și nu la
celălalt, fără nicio treaptă reală. Acum compară aria și acoperirea.)

## Fidelitate (decupare | randare, `docs/asset_briefs/img/carrara_fidelity/<nume>.png`)

Culoarea din comparații e reală pe sloturi; `*_Marble` e pe ținta clasei.
Pe decupări dungile de fir și venele sunt textură: la noi le dă clasa (regula 7).

### marble_block_a / _b / _c (1 rundă)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| formă | cub cu fețe tăiate drept | cutie, muchii vii | OK |
| dungi de fir, vene | pictate | absente (clasa) | OK (regula 7) |
| `_c` | pare cub | 3 × 2 × 2 | abatere voită (tabelul) |
| tonuri | crem uniform | crem + treimea de jos gri | abatere voită (regula 8) |
| dunga de vopsea `_b` | nu se vede | dungă verticală 10 cm, LAVA_ORANGE | din tabel |

### block_stack_a / _b (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| număr | 2 / 3 blocuri suprapuse | 2 / 3 mase separate | OK |
| decalaj, rotație | ușor decalate | 0,1–0,2 m, ±3–5° | OK |
| proporții | jos cel mai mare (`_b`) | 2,3 → 2,0 → 1,85 m | OK după runda 2 (runda 1: blocul din mijloc ieșea peste cel de jos) |
| patina | — | doar blocul de jos | decizie: patina vine de la sol |

### block_informe_b (3 runde din 3)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| silueta | bulgăre îngrămădit, mai înalt la mijloc | 5 mase convexe sparte, vârf 1,57 m | OK ca siluetă după runda 3 (r1 și r2 ieșeau lespede) |
| fațete | multe, mici-medii | ~20 de fațete mari, masa centrală are fețe plane largi | **abatere rămasă**: masa centrală se citește încă puțin „cutie spartă” |
| concavități | adânci între bucăți | 4 umflături pe o masă de bază | parțial |

### rubble_pile_a / _b (3 runde din 3)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| fragmente | ~40 vizibile, unghiulare | 25 / 22 (tabel: 15–25), cutii cu 4–6 colțuri sparte | OK |
| goluri întunecate | da | miezul gri se vede printre bucăți | OK (r1, r2: miezul gri se vedea ca movilă netedă) |
| silueta | con cu vârf | movilă mai rotundă, mai turtită | **abatere mică** |
| pietriș mărunt la poală | da | nu (cele mai mici bucăți au ~0,3 m) | abatere: ar cere mult mai multe piese |

### safety_berm (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| masă | bolovani rotunjiți pe 2 rânduri | 3 rânduri de blocuri cu colțuri sparte, pe miez gri | **abatere voită**: regula 7 cere blocuri tăiate / sparte, nu bulgări |
| flori galbene | da | nu | corectura „fără vegetație lipită” |
| profil | — | pantă spre −X (Blender), abrupt spre +X | OK (contract) |
| înălțime | pare ~1 m | 0,62 m | contractul (0,6) |
| înlănțuire | — | capete identice, măsurat | OK |

### work_lamp (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| trepied | picioare lungi, butucul la jumătate | butucul la 1,40 m, rază 0,85 m, 3 contravântuiri | OK după runda 2 (r1: picioare prea scurte) |
| reflectoare | 2 carcase negre cu sticlă | 2, sticla pe `Lamp_Glow` (SAND_LIGHT) | OK |
| culoare | galben saturat | DRY_VEGETATION 13 | abatere voită |
| cablul | atârnă lângă catarg | coboară pe catarg, pleacă pe sol | se vede slab |

### cable_reel (1 rundă)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| flanșe cu spițe | 2, ~8 spițe | 2, 6 spițe în relief | OK |
| cablul | negru, spire fine | negru, 6 inele în relief | spirele se citesc ca trepte, mai grosiere |
| leagăn | ramă de lemn | 2 tălpi, 2 traverse, 4 pene | OK |
| lemnul | portocaliu deschis | WOOD_WEATHERED (mai închis) | paleta |

### water_tank (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| corp | cilindru înalt, cercuri, con sus și jos | idem, cercuri în fază cu peretele | OK după runda 2 (r1: picioare prea lungi, cercuri în zigzag) |
| culoare | albastru saturat | PAINTED_METAL 11 | corectura de sus |
| picioare | 4, rugină | 4 aproape verticale + 4 contravântuiri | OK |
| bara de sus | o țeavă curbă peste capac | lipsește | abatere mică |

### fuel_tank (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| corp | cilindru orizontal ruginit, capete bombate, 2 cercuri | idem | OK |
| gura de sus | gât larg | gât + buză + gură neagră | OK după runda 2 |
| scară | pe flanc + una pe capăt, balustradă curbă sus | una pe flancul vizibil, fără balustradă | **abatere**: balustrada ar ridica piesa peste 2,4 m |
| proporții | scurt, gros | 3,9 × 1,8 (tabelul 4 × 2) | tabelul |
| praf | — | scos (petele se citeau ca scânduri) | — |

### office_container (1 rundă)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| fața lungă | perete gol, fereastră, ușă, fereastră | aceeași ordine, pe +Y (Blender) | OK |
| capăt | o fereastră mică | o fereastră pe −X | OK |
| nervuri | dese pe tot peretele | la 0,45 m, doar între goluri | mai rare decât pe planșă |
| treptele | metalice | o treaptă + 2 vange | OK |
| culoare | bej cald | CONCRETE 8 (gri-bej), rama ASPHALT_EDGE | tabelul de sloturi |
| urechile de ridicare de pe acoperiș | 2 | lipsesc | abatere mică |

### quarry_sign_a / _b (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| chevroni `_a` | 3, spre dreapta | 3, spre dreapta privitorului, relief 1,5 cm | OK după runda 2 (r1: îndreptați invers). Tabelul spune „chevron dublu”; am urmat decuparea (3) |
| pictograma `_b` | cârlig, cabluri în V, bloc în 3/4 | idem, muchiile cubului pe culoarea câmpului | OK după runda 2 (r1: câmpul ieșea negru — fața din spate a reliefului era coplanară cu câmpul și îi fura slotul la `assign_uvs`; acum relieful stă la 2 mm) |
| câmp | galben saturat | DRY_VEGETATION 13 | abatere voită |
| panoul `_b` | aproape pătrat | 1,2 × 0,8 culcat | **abatere**: tabelul (1,2 × 0,8) |
| stâlpi | scurți sub panou | 1,0 m vizibili sub panou | tabelul (1,8 m) |

### pipe_run (2 runde)

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| conducte | 2, **una peste alta** | 2 suprapuse, Ø 0,4 | OK după runda 2 (r1 le punea alăturate) |
| suporți | 3 blocuri de marmură | 3 × 0,8 × 0,6 × 0,6 | OK |
| coliere | rugină, pe fiecare suport | inel pe fiecare conductă + 2 chingi + bară sus | OK |
| culoare | oțel gri | PAINTED_METAL 11 | tabelul |
| capete | deschise, negre | flanșe închise (se întâlnesc la înlănțuire) | voit |
| patina suporților | — | fără `*_MarbleBase` (tabelul cere doar `Pipe_Metal`, `Pipe_Marble`) | — |

## Contracte înghețate

- Numele nodurilor din tabelul de cote (clasa se pune pe sufixul `_Marble` /
  `_MarbleBase`; `Lamp_Glow` poate fi aprins la integrare).
- Modulele `safety_berm` și `pipe_run`: 6,000 m pe Z (Godot), capete identice
  la ±3, originea pe mijlocul modulului; suporții conductelor la pas de 2 m
  și între module.
- `safety_berm`: panta lungă spre **−X** (drumul; Blender și Godot au aceeași
  axă X), cădere abruptă spre +X (golul).
- Fețele desenate (semne, containerul, sticla lămpii) privesc +Y în Blender =
  **−Z în Godot**.

## Stare la oprire

- Toate cele 17 piese din §1.5 (fără `block_informe_a`, care e al lui crr-a)
  sunt construite, comparate și măsurate. `bash tools/blender/verify_carrara.sh`
  → `VERDICT KIT: OK` (inclusiv pilotul).
- Abateri rămase (raportate, nereparate): masa centrală a lui
  `block_informe_b` încă puțin cutie (3 runde folosite); pietrișul mărunt și
  vârful conic la `rubble_pile_*` (3 runde folosite); balustrada și a doua
  scară la `fuel_tank`; bara de sus la `water_tank`; urechile de ridicare la
  container; panoul `_b` culcat, nu pătrat.
- Nevăzut: piesele în Godot, cu clasa `carrara_marble`, lumina temei, umbrele
  și ceața; colizoarele; MultiMesh-ul blocurilor. Nu s-a atins `scenes/` sau
  `scripts/`.
- Neverificat de coordonator: comparațiile (kit §0.1 pasul 6).
