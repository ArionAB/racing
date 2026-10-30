# Inventar — kit Carrara, val 1, constructorul crr-a

Contract: `docs/asset_briefs/carrara_kit.md` §1.1 (utilajele-hazard, fără
`quarry_truck`, care e al pilotului: `carrara_inventory.md`). Ramura
`carrara/kit-a`. Toate cotele de mai jos sunt **măsurate pe GLB-ul exportat**,
în coordonate Godot (Y sus, −Z înainte), de gărzile din
`tools/blender/measure_carrara_crr_a.py` și `measure_carrara_excavator.py`.

## Fișiere

| fișier | rol |
|---|---|
| `tools/blender/build_crr_machines.py` | `build_derrick`, `build_marble_block_hooked`, `build_lizza_sled`, `build_block_informe_a`, `build_quarry_excavator` (docstring = lista de elemente, scrisă înainte de geometrie) + helperele `emit_fixed` (export FĂRĂ recentrare: originea e contract de cod), `taper_box`, `polyline_beam`, `marble_box`, `_clipped_box`, `_track_belt`. `CRR_ONLY=<piesă>` reface o singură piesă |
| `tools/blender/preview_crr_a.py` | rulează `preview_carrara.py` **neschimbat**, cu camerele pieselor (azimut ca pe planșă) și cu `Jib`-ul derrick-ului urcat la 22,05 m, ca în joc |
| `tools/blender/measure_carrara_crr_a.py` | gărzile `derrick`, `block`, `sled`, `informe` |
| `tools/blender/measure_carrara_excavator.py` | garda rigului excavatorului (ierarhie body/arm, pivot, cutia brațului, ±0,1 m) |
| `tools/blender/verify_carrara.sh` | secțiunea „val 1, crr-a”: `verify_glb` + garda + numele nodurilor pe fiecare piesă |
| `tools/probe_carrara_derrick.gd` | flag nou `--carrara` (derrick.glb + marble_block_hooked.glb în locul stand-in-ului Chongqing) |
| `tools/probe_carrara_sled.gd` | flag nou `--glb=res://...` (sania din kit în locul cutiilor sintetice; golul se măsoară sub tălpile GLB-ului) |

Nimic din `scenes/`, `scripts/`, `carrara_shapes.py`, `preview_carrara.py`,
`measure_carrara_truck.py` nu s-a schimbat.

## Cote măsurate față de contract

| piesă | contract | măsurat pe GLB | tri | noduri (= materiale) |
|---|---|---|---:|---|
| `structures/derrick.glb` | catarg cu vârful la **22,05** (JIB_HEIGHT), ±1,8 pe X (MAST_SIDE); brațul până la **17,9** pe −Z; `Jib` rădăcină cu originea în balama; fără bloc, fără cablu | `TowerCrane` Y 0,000…22,050, X ±1,780, Z −1,750…+7,850 (A-frame-ul se deschide în spate, în lungul drumului); `Jib` fără translație, Y −0,412…+8,000, Z −18,375…+0,930; cârligul desenat la **Z −17,885** | 3.436 (Jib 1.664, TowerCrane 1.772) | `Jib`, `TowerCrane` (2) |
| `props/marble_block_hooked.glb` | umple **4,6 × 2,99 × 2,2** de la Y −3,05 la −0,06; chingi + inel până la 0 | tot: X ±2,30 (+2 mm dunga de vopsea), Y −3,050…0,000, Z ±1,100; marmura: X ±2,300, Y −3,015…−0,060, Z ±1,065 (retrasă cu grosimea chingii, 3,5 cm, pe fața/spatele/talpa unde stau chingile) | 360 | `Block_Marble`, `Block_MarbleBase`, `Block_Strap`, `Block_Paint` (4) |
| `props/lizza_sled.glb` | amprentă **2,4 × 2,4** (±0,2), talpă 0,4, bloc 2,0 | 2,412 × 2,412, înălțime 2,510 (2,4 + funiile peste bloc); rază sferei = 1,206 | 1.504 | `Sled_Wood`, `Sled_Rope`, `Sled_Marble`, `Sled_MarbleBase` (4) |
| `rocks/block_informe_a.glb` | **3 m** ±10 %, X ≈ Z | 2,991 × 2,927 × 2,890 (X × Y × Z); \|X−Z\| = 0,10 | 394 | `Informe_Marble` (1) |
| `vehicles/quarry_excavator.glb` | `body` fără arm X ±1,95, Y 0…3,73, Z −2,45…2,48; pivot (0,55; 1,95; −0,42); arm X 0,09…1,01, Y 0,92…3,76, Z −5,70…−0,32; toleranță ±0,1 | body X ±1,950, Y 0,004…3,730, Z −2,433…2,463; pivot (0,550; 1,950; −0,420); arm X 0,085…1,015, Y 0,924…3,760, Z −5,680…−0,328; `arm` copil al lui `body`, rotație identitate | 8.612 (Body_Black 4.608 din 2 × 36 de zale) | `Body_Paint`, `Body_Rust`, `Body_Black`, `Arm_Paint`, `Arm_Rust`, `Arm_Black` (6) + nodurile goale `body`, `arm` |

Sloturi (din `verify_glb`): utilajele pe `DRY_VEGETATION` 13 + `RUST_METAL` 10 +
`VOLCANIC_BLACK` 20 (+ `SAND_SHADOW` 2 pete de praf pe excavator, `LOG_DARK` 28
la papucii derrick-ului); marmura pe `CORAL_SAND` 19 / `MARBLE_GREY` 29 ca noduri
separate; sania `WOOD_WEATHERED` 9 + `LOG_DARK` 28; marcajul `LAVA_ORANGE` 30
(0,14 m²). **Fără** `FOAM_WHITE` 22, **fără** `CAR_YELLOW` 16, fără text,
cifre sau logo-uri. Scala 1 și rotația identitate pe toate rădăcinile
(verificat în `verify_carrara.sh`). Primitive rotunde: 8–16 segmente.

`bash tools/blender/verify_carrara.sh` → **`VERDICT KIT: OK`**.

### Gărzile, verificate pe intrări greșite (sabotaj)

| gardă | intrarea | rezultat |
|---|---|---|
| `measure_carrara_excavator.py` | `quarry_excavator.glb` (final) | `rig: OK` |
| | `vehicles/rusted_digger.glb` (referința) | `rig: OK` — reproduce cotele din brief, deci măsoară bine |
| | `quarry_truck.glb` (fără body/arm) | PROBLEME: „lipsesc nodurile body/arm” |
| | copie a lui `quarry_excavator.glb` cu pivotul mutat +0,3 pe Y | PROBLEME: pivot Y 2,25, arm Y 1,21…4,06 |
| | **prima variantă a excavatorului** (nesabotată) | PROBLEME, și pe bună dreptate: tijele cilindrilor erau în builder-ul *corpului* (body Z −4,63) și piciorul boom-ului trecea de Y −0,10 (arm Z max −0,17). Ambele reparate |
| `measure_carrara_crr_a.py derrick` | `tower_crane.glb` (Chongqing) | PROBLEME: cârligul la Z −12,96, nu −17,9 |
| | copie a lui `derrick.glb` cu `Jib` translatat la 22,05 | PROBLEME: „Jib are translație” |
| | **derrick-ul nesabotat, înainte de reparație** | PROBLEME, real: papucii din față ieșeau la −Z 1,825 (> 1,8). Scurtați la 0,90 m |
| `… block` | copie cu `Block_Marble` coborât 0,2 m | PROBLEME: marmura nu mai atinge −0,06 |
| | `prefab_slab.glb` | PROBLEME („fără marmură”): nu e control pozitiv, garda cere nodurile de marmură |
| `… sled` / `… informe` | GLB-ul celeilalte piese | PROBLEME pe toate cotele |

## Sondele

### `probe_carrara_derrick.gd`: stand-in (`tower_crane.glb` + `prefab_slab.glb`) față de kit (`--carrara`)

Aceeași rulare, aceeași fază, aceleași mașini. **Ambele: `=== TOATE OK ===`,
21 de verdicte OK, 0 picate.** Ce diferă e doar geometria citită din model:

| măsura | stand-in Chongqing | kit Carrara |
|---|---|---|
| catargul din mesh (după `model_scale` 0,7256) | 16,000 m | 16,000 m |
| pivotul / colizorul catargului | 16,000 / 16,000 | 16,000 / 16,000 |
| mesh-ul brațului, în spațiul pivotului | y −4,37…+3,07, z −13,09…+5,51 | y −0,30…+5,80, z −13,33…+0,67 |
| cârligul desenat față de sarcină (z −13,00) | **z −9,40** (cablul codului atârna la 3,6 m de cârligul desenat) | **z −12,98** |
| sarcina: vizual / colizor | 3,64 × 2,20 × 3,29 / 3,34 × 2,17 × 1,60 | 3,61 × 2,23 × 3,25 / 3,34 × 2,17 × 1,60 |
| tălpile vizuală / a colizorului | 0,546 / 0,644 (−0,098) | 0,551 / 0,644 (−0,093) |
| treceri, cota tălpii, benzi, lovituri (16 combinații centrale + decalaje, 32 de rulaje) | identice | **identice la bit** |
| calibrarea Chongqing 22 m / derrick 16 m | identică | identică |

De ce sunt identice cifrele mașinilor: colizorii hazardului sunt **constante
de cod** (`MAST_SIDE`, `JIB_HEIGHT`, `SLAB_SIZE`), nu ies din model. Că modelul
chiar s-a încărcat se vede pe liniile de geometrie (brațul și cârligul diferă).
Note:
- „vizual 3,61 × 2,23 × 3,25” e AABB-ul de lume al sarcinii rotite cu brațul,
  nu cota blocului; la fel și la stand-in.
- Diferența de −0,09 m dintre talpa vizuală și cea a colizorului e
  `SLAB_TOP_OFFSET` după scară, aceeași ca la stand-in.

Sonda s-a rulat a doua oară pe GLB-ul final (după scurtarea papucilor cu
7,5 cm): verdictele, geometria și tabelul mașinilor sunt identice cu prima
rulare (21 OK, ieșire 0).

### `probe_carrara_sled.gd`: sania sintetică (cutii) față de `--glb=…lizza_sled.glb`

| măsura | sintetică 2,4 / 2,4 / 0,4 / 2,0 | `lizza_sled.glb` (final) |
|---|---|---|
| raza sferei măsurată de hazard | 1,200 | 1,206 |
| gol max / min sub talpă (prag ±0,15) | +0,009 / −0,112 | +0,009 / −0,112 (talpa de contact a tălpilor: X ±1,01, Z +1,20…−0,70) |
| racordare lentă (informativ) | +0,005 / −0,068 | +0,005 / −0,072 |
| `roll_model` false / true | 80,2° / 2.157° | 80,2° / 2.146° |
| timp pierdut, 8 combinații centrale (prag 0,4–1,6 s) | 0,86…1,41 s | 0,86…1,41 s |
| verdict | TOATE OK | **TOATE OK** |

Runda 2 a saniei avea tălpile de **2,6 m** (în toleranța de ±0,2 a kitului):
sfera a crescut la r 1,30 și sonda a picat „timp pierdut” (0,88…**1,64** s >
1,6). Revenit la 2,4: verde. **Contractul de 2,4 nu e o cifră aproximativă**:
toleranța de ±0,2 din kit e mai largă decât ce ține sonda.

## Fidelitate

Imagini (decupare | randare din GLB, culoare reală pe sloturi, marmura pe
ținta clasei): `docs/asset_briefs/img/carrara_fidelity/<nume>.png`, plus
`<nume>_views.png` (4 azimuturi) pentru toate cinci. Toate cinci au folosit
cele 3 runde. Culoarea utilajelor (galben-spălăcit 13 față de galbenul
planșei) e **abatere voită** (corectura kitului) și nu se mai repetă mai jos.

### derrick (3 runde)

R1: trestle simetric 3,6 × 3,6 → un turn subțire, nu un derrick. R2: A-frame
deschis în lungul drumului, braț la ~20°. R3: picioare mai groase (0,75),
cap mai mare, plăcile de îmbinare pe vopsea (pe rugină citeau ca dungi de
barieră), braț ~22°.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| catarg | A-frame din 4 picioare de grindă, față dreaptă, spate deschis | 4 picioare 0,75 m, față aproape verticală, spate cu talpa la 7,4 m în spate; trapez în vedere din față | OK |
| bază | ramă de bârne, papuci întunecați | 2 tălpi lungi + 3 traverse, 4 papuci `LOG_DARK` | OK |
| brâu + contravântuiri | brâu cu plăci la jumătate, X în panoul de jos | brâu la 9,2 m cu plăci, X pe fețele laterale și pe cea din față | OK |
| cap | bloc mare cu roată | bloc 2,3 m + coroană și roată de rugină (în `Jib`) | OK |
| braț | grindă plină, groasă, ~25°, rugină pe față | cheson plin 1,3→0,85 m, ~22°, 2 plăci de îmbinare, 4 pete de rugină | OK; puțin mai plat |
| raport braț / catarg | ~1,1 | 17,9 / 22,05 = 0,81 | **abatere de cotă** (cote din cod) |
| trosă + cârlig | 2–4 fire scurte, mufla, cârlig mare | 2 fire de 5 m, mufla, cârlig în J | abatere: firele sunt lungi (vârful e la 7,4 m peste balama, cablul codului pornește de la cota balamalei); cârligul e mic la scara asta |
| cabluri spre bază | 2 cabluri de la vârf la troliu | lipsesc | **abatere voită**: s-ar rupe la rotația brațului; troliul de la bază există |
| ce iese din contur | baza, spre spate | picioarele din spate până la Z +7,85, **în afara colizorului** 3,6 × 3,6 | de știut la integrare (vezi mai jos) |

### marble_block_hooked (3 runde)

R1: 2 × 2 blocuri, patina tăiată în mijlocul rândului de jos. R2: 2 × 3
blocuri, patina = rândul de jos, chingi mai înguste. R3: rândul de jos
aliniat cu treimea de patină (verificat pe `_views`).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| blocul | pachet de dale, rosturi orizontale și una verticală, aproape cub | 6 blocuri (2 × 3), rosturi de 4 cm, 4,6 × 2,99 × 2,2 | **abatere de proporție** impusă de `SLAB_SIZE` (l/h 1,54 față de ~1) |
| patina | — | rândul de jos pe `MARBLE_GREY` | OK (regula 8) |
| chingi | două benzi verticale pe fața lată, urcă în piramidă la inel | două benzi verticale pe față și spate, pe sub talpă; sus, 4 fâșii diagonale culcate pe fața de sus, încrucișate în centru | **abatere de siluetă**: piramida peste bloc nu încape (contractul lasă 6 cm peste bloc) |
| inel + rolă | inel, rolă, cârlig deasupra | tor culcat, vârful exact la Y 0 | abatere (rola/cârligul sunt ale derrick-ului; inelul abia se vede) |
| marcaj | — | dungă `LAVA_ORANGE` 10 cm pe capătul +X | OK |
| vene portocalii | pictate | nu sunt geometrie | voit (clasa) |

### lizza_sled (3 runde)

R1: tălpi de 2,4 sub blocul de 2,0 — sania nu se vede. R2: tălpi de 2,6 cu
vârful ridicat — **pică sonda**. R3: înapoi la 2,4 (vârf ridicat la 0,60 m
pe ultimii 0,5 m), cameră mai laterală.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| proporția | sanie lungă (~2,5:1), blocul pe jumătatea din spate | 2,4 × 2,4, blocul de 2,0 o acoperă aproape toată | **abatere mare de siluetă**, impusă de contract (amprenta pătrată = sfera de coliziune; 2,6 pică sonda) |
| tălpi | două bârne groase, capete pătrate | două tălpi 0,42 × 0,25, vârful din față ridicat | OK ca element; se văd doar capetele |
| traverse | 5–6, capete ieșite lateral, lungimi diferite | 5, capete până la ±1,2, lungimi 2,28–2,40 | OK |
| fiare la îmbinări | plăci închise | colțare `LOG_DARK` pe fața tălpilor | OK |
| blocul | 2 × 2 blocuri pe față | 4 blocuri (2 × 2), patina pe treimea de jos | OK |
| funii | groase, cânepă deschisă, verticale + o diagonală | 2 pe Y + 1 pe X, încrucișate sus, `LOG_DARK` | **abatere de nuanță** (închise, ca să se citească pe crem) |

### block_informe_a (3 runde)

R1: 3 mase convexe — „pâine” netedă. R2: mănunchi de fragmente cu tăieturi
aproape paralele cu fețele — așchii ca niște aripi. R3: doar teșituri de colț
spre exterior: 18 prisme (3 × 3 × 2) decalate cu 2–7 cm, plus miez.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| masa | ~cub de 3 m, vârful în trepte | 2,99 × 2,93 × 2,89, înălțimi diferite pe rândul de sus | OK |
| spărtura | mănunchi de prisme sparte, crăpături în V | 18 prisme cu 2–4 fațete de colț, crăpături între ele | OK ca idee |
| regularitate | neregulat, rotunjit jos | rosturile urmează o grilă 3 × 3 și un rost orizontal continuu | **abatere**: citește mai „stivă” decât planșa |
| fețe tăiate | — | talpa, +X și −Y rămân mai plane | OK |
| culoare | crem cu vene | `CORAL_SAND` (venele din clasă) | OK |

### quarry_excavator (3 runde)

R1: furca scurtă, coarne de 0,6 m. R2: stick-ul se oprește mai sus, coarne de
~1,3 m; cilindrii boom-ului mai lungi, cu tija intrând sub boom. R3:
platforma în două trepte (fustă îngustă + corp lat) și grila motorului pe
flancuri, în locul zidului plat.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| șenile | 2, zale cu pinteni, roți de întindere/motoare, role | 2 × 36 de zale cu pinten, 2 roți + 4 role de rugină pe fața exterioară, cadru vopsit cu praf | OK |
| platforma | lungă, joasă, cu trepte și grile | două trepte, contragreutate rotunjită, grilă cu 3 lamele | OK; mai cutie decât planșa |
| capota + balustrada | da | da, balustradă de rugină, coș de eșapament | OK |
| cabina | stânga-față, geamuri închise | stânga-față, parbriz + 3 geamuri negre, acoperiș | OK |
| boom | „banana” înaltă, trece mult peste cabină | două tronsoane + cot, vârful la 3,76 (abia peste cabină, 3,59) | **abatere de proporție**: cutia brațului din cod (Y ≤ 3,76, Z ≥ −5,70) e mult mai mică decât brațul din planșă |
| stick + cilindri + furtunuri | da | da (4 cilindri, 2 furtunuri) | OK |
| furca | traversă + 2 coarne lungi, întunecate la vârf | traversă 0,92 m + 2 coarne ~1,3 m de rugină, vârfuri negre | OK |
| inscripții | pe capotă | nu | voit |

## Contracte înghețate (crr-a)

- **derrick:** `TowerCrane` cu vârful la **22,05** exact, pe X în **±1,8**,
  în față (−Z) în 1,8; `Jib` rădăcină **fără translație**, cârligul desenat la
  **Z −17,9** (sarcina atârnă acolo cu `hook_radius` 17,9 la `model_scale`
  0,7256 = 13 m în joc). Numele nodurilor `Jib`, `TowerCrane`.
- **marble_block_hooked:** marmura umple `SLAB_SIZE` (±2,30 × −3,015…−0,06 ×
  ±1,065; chingile completează până la ±1,1 / −3,05), nimic peste Y 0.
- **lizza_sled:** amprenta **2,4 × 2,4** (sfera r 1,206), talpa de contact a
  tălpilor X ±1,01, Z +1,20…−0,70, vârful ridicat în față (−Z Godot).
- **block_informe_a:** 3 m ±10 %, |X − Z| ≤ 0,15, un singur nod.
- **quarry_excavator:** rigul `rusted_digger` (cotele de mai sus, ±0,1),
  `arm` copil al lui `body`, rotație identitate pe `arm`.

## De știut la integrare (coordonatorul)

1. **Semnul din contract la derrick.** Kitul cere ca picioarele de sprijin să
   iasă „doar spre +X (spre exterior, departe de drum: turnul stă pe stânga)”.
   În `CraneHazard`, `tower_side = -1` (stânga) pune turnul la **x = −7**, cu
   drumul spre **+X**: „+X” ar fi spre drum (picioare de 4 m ar ajunge la
   x ≈ −3, pe carosabil). Ca să nu depind de semn, A-frame-ul se deschide **în
   lungul drumului** (Godot +Z, Blender −Y): pe X nimic nu trece de 1,78.
2. **Picioarele din spate ies din colizor.** `MAST_SIDE` e o cutie de
   3,6 × 3,6 în jurul axei; A-frame-ul ajunge la Z +7,85 (+5,7 m în joc), deci
   o mașină ieșită de pe drum pe acolo ar trece prin papucii din spate. Pe
   Track23 zona e la 1,2 m în afara marginii; dacă e accesibilă, trebuie un
   colizor în plus sau rotirea hazardului.
3. **Cârligul desenat cere `hook_radius = 17,9`** (= 13 m / 0,7256, cum îl
   pune și sonda) cu `model_scale` 0,7256. Codul atârnă sarcina la
   `hook_radius` de balama; cu altă valoare, cablul desenat de cod nu mai iese
   din cârligul modelat.
4. **Excavatorul** așteaptă codul (`_build_excavator` încarcă fix
   `rusted_digger.glb` și pune `rust_metal` pe tot modelul, kit §1.1).
5. **Sania:** sonda trece pe GLB, dar contractul de 2,4 e strâns (2,6 pică).

## Stare la oprire

- Cele cinci piese sunt exportate, verificate (`VERDICT KIT: OK`), cu gărzile
  lor rulate și pe intrări sabotate, comparațiile și cele 4 azimuturi văzute
  piesă cu piesă. Commit pe `carrara/kit-a`.
- Sondele: derrick (stand-in față de kit) și sania (sintetic față de GLB) —
  ambele TOATE OK pe GLB-urile kitului.
- Abateri **nerezolvate** (după 3 runde, raportate, nu declarate „trece”):
  sania e dominată de bloc (contractul); brațul excavatorului e mult mai mic
  decât în planșă (cutia din cod); blocul informe citește ca stivă regulată;
  piramida de chingi a blocului agățat nu încape; trosa derrick-ului e lungă.
- Neverificat: aspectul în Godot cu clasele (`carrara_marble`), umbrele și
  lumina temei; ProbeRace pe Track23 (piesele nu sunt montate, e treaba
  coordonatorului); coliziunea picioarelor din spate ale derrick-ului.
