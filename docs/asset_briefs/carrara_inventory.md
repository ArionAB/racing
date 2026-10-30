# Inventar — kit Carrara (Track23)

Contract: `docs/asset_briefs/carrara_kit.md`. Acest fișier e al pilotului
(harnas + `quarry_truck`); piesele din valurile următoare se adaugă aici.

## Harnasul

| fișier | rol |
|---|---|
| `tools/blender/carrara_shapes.py` | vocabular: `cut_marble_block` (bloc tăiat cu fir, două noduri `*_Marble` / `*_MarbleBase`, colț spart opțional), `tilted_box`, `wheel_crr`, `emit_crr` (finish per nod, offset de origine o dată pe ansamblu) |
| `tools/blender/build_crr_machines.py` | `quarry_truck` (docstring = lista de elemente, scrisă înainte de geometrie) |
| `tools/blender/preview_carrara.py` | `--compare`, `--views`, `--vs <nume> <ref.glb>`, `--sheet` |
| `tools/blender/measure_carrara_truck.py` | garda anvelopei, citește GLB-ul (JSON + accesoare + transformări), în coordonate Godot |
| `tools/blender/verify_carrara.sh` | `verify_glb` pe fiecare GLB, scala/rotația pe rădăcini, anvelopa camionului, numele nodurilor, GLB-uri nedeclarate |

## quarry_truck.glb — cote măsurate (Godot, din fișier)

| | lățime X | înălțime Y | lungime Z | min Y | cabina |
|---|---:|---:|---:|---:|---|
| `kamaz_truck.glb` (referința) | 2,685 | 3,126 | 8,000 | 0,000 | −Z |
| `quarry_truck.glb` | **2,830** | **3,376** | **7,730** | 0,005 | −Z (z mediu al vârfurilor −1,34, adică partea cabinei/copertinei) |
| contract | ≤ 2,9 | ≤ 3,4 | 7,6–8,2 | ≈ 0 | −Z |

Garda a fost rulată și pe Kamaz: reproduce 2,68 × 3,13 × 8,0 (deci măsoară bine).

- Triunghiuri: **8.148** (Black 5.548 din cauza a 6 × 16 crampoane, Rust 856,
  Body 1.696, Marble 24, MarbleBase 24). Fără plafon.
- Noduri: `Truck_Body` (DRY_VEGETATION 13 + pete SAND_SHADOW 2), `Truck_Rust`
  (RUST_METAL 10), `Truck_Black` (VOLCANIC_BLACK 20), `Truck_Marble`
  (CORAL_SAND 19), `Truck_MarbleBase` (MARBLE_GREY 29). **Materiale: 5** (un
  nod = un material). Fără CAR_YELLOW, FOAM_WHITE, text, logo-uri.
- Origine: baza amprentei, centrat pe X și Y; scala 1 și rotația identitate pe
  rădăcini (verificat în `verify_carrara.sh`).
- Primitive rotunde: roți 14 laturi, axe/evacuator 8–10.

## Fidelitate (3 runde din 3 folosite)

Imagini: `docs/asset_briefs/img/carrara_fidelity/quarry_truck.png` (decupare |
randare), `quarry_truck_vs_kamaz.png` (3/4 și din față, aceeași scară, Kamaz în
stânga), `quarry_truck_views.png` (4 azimuturi).

Runda 1: camion militar lung, cu capotă. Runda 2: nas scurt, roți mari. Runda 3
(corectura coordonatorului): bena devine CAROSERIE PLINĂ de oțel (fără rame și
stâlpi), peretele din față e o pană care urcă spre față și se continuă cu
copertina peste cabină, toate în `Truck_Body`; blocurile ies mult peste buza
laterală; bara de rugină are jumătate de secțiune; anvelope cu 16 crampoane.
AABB-ul pe X și Z a rămas identic (2,83 / 7,73).

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| bena | placă laterală plină, nervuri verticale, buză sus, spate ridicat | plăci pline evazate 6°, 4 nervuri în relief (7 cm), buză rulată, spate cu 0,40 m peste laterale | OK ca formă; nervurile și buza sunt aceeași culoare, deci se citesc subtil din 3/4 |
| copertina | perete din față în pantă, prelungit peste cabină | pană spre față + placă peste cabină + 2 plăci triunghiulare laterale, un singur corp | OK; mai plată și mai mică decât pe planșă (cota 3,0–3,17 m) |
| cabina | scurtă, lată, parbriz înclinat | corp lat peste roțile din față, seră cu parbriz retras 31°, geam lateral, lunetă | OK |
| grila | mare, neagră | neagră, 3 bare de vopsea | OK |
| bara | lată, groasă, galben-rugină | bară de rugină subțire (0,28 × 0,26 m) | abatere mică: pe planșă e din vopsea, aici rugină (conform tabelului de sloturi) |
| roți | uriașe, duble în spate, crampoane adânci | 6 roți (2 + 4 duble), r 0,86 (cât permite plafonul de 3,4 m cu blocurile), 16 laturi, 16 crampoane, jante cu capac | OK ca număr/rol; relativ la caroserie, planșa are roți mai late și mai înalte |
| blocuri | 3–4, ies mult peste buză | 2 (1,85×1,80×1,40 și 1,80×1,70×1,36), ies ~0,8 m peste buza laterală, 2 tonuri, un colț spart | OK conform corecturii (2 blocuri) |
| culoare | galben saturat | galben-spălăcit 13 + rugină 10 | **abatere voită** (paleta) |
| proporții | h/l ~0,7 în 3/4 | comparabile în 3/4 | OK ±15% |
| iese din contur | oglinzi, plasă | oglinzi mici în lățimea roților | OK (voit) |
| lățime | 3,6 m | 2,83 m | **abatere voită** (anvelopa Kamaz) |

## Contracte înghețate

- Anvelopa camionului: ≤ 2,9 × ≤ 3,4 × 7,6–8,2 m, botul pe +Y Blender (−Z Godot),
  originea jos la mijlocul amprentei; coliziunea e AABB-ul, nimic nu iese din contur.
- Numele de noduri `Truck_Body/Rust/Black/Marble/MarbleBase`.
- ProbeRace pe camioane se reia la schimbarea modelului (coordonatorul).

## Integrare pe Track23 (coordonator, 27 oct 2026)

**Acceptat** după runda 3: caroseria basculantei e plină, cu baldachinul peste
cabină, iar blocurile ies ~0,8 m peste bordură. Abaterile rămase sunt cele din
tabelul de fidelitate (baldachin mai plat, roți mai mici relativ la caroserie,
nervurile slab vizibile în aceeași culoare); oliv-ul slotului 13 e decizia de
paletă din brief §4, nu o abatere de corectat aici.

Schimbarea: `Track23.tscn`, resursa `8_kamaz` (ambele camioane, `Camion1B` și
`Camion2Pod`) trece de pe `baikal/vehicles/kamaz_truck.glb` pe
`carrara/vehicles/quarry_truck.glb`. Id-ul resursei a rămas, ca diff-ul să fie o
linie. Remaparea `kamaz_truck` din `SLOTS_CARRARA` nu mai prinde nimic pe pistă
și rămâne pentru Kamaz-ul parcat din A (brief §5.3), dacă se pune.

**ProbeRace A/B** (`tools/carrara_race_run.sh`, 16 seed-uri × 210 s, 8 mașini,
același cod, aceeași pistă; doar modelul camionului diferă):

| | Kamaz | quarry_truck |
|---|---|---|
| cadre de contact cu camioanele (`bus_hits`) | 130 | 131 |
| `[blocaj]` / repuneri atribuibile camioanelor | 0 / 0 | 0 / 0 |
| ture | 298 | 303 |
| tur minim / mediu (mediana pe seed-uri) | 65,06 / 69,70 s | 65,09 / 69,44 s |
| `[blocaj]` total / la excavator (frac 0,048–0,050) | 9 / 7 | 15 / 15 |
| repuneri / ejectări total | 6 / 3 | 9 / 4 |

Verdict: **schimbarea e neutră pe camioane** — contactele identice, zero
blocaje sau repuneri lângă camioane în ambele serii. Diferența de blocaje e în
întregime la brațul excavatorului de pe piazzale (coada de la start, problemă
deschisă din brief §7 pasul 5, unde aceeași măsurătoare dădea 21), adică
zgomot de nedeterminism Jolt pe un hazard pe care schimbarea nu-l atinge
(memoria `proberace-nedeterminism`). Cutia nouă e cu 0,15 m mai lată și cu
0,27 m mai scurtă decât a Kamaz-ului; n-a mișcat nimic măsurabil.

Nevăzut încă: camionul în joc cu fereastră (lumina temei, umbrele, clasa
marmurei pe blocuri). Captura vine cu primul val, la integrare.

## Valul 1 — acceptarea coordonatorului (27 oct 2026)

Trei constructori Opus în paralel (cerința dezvoltatorului pe sesiunea asta),
ramurile `carrara/kit-a`, `kit-b`, `kit-c`, unite aici fără conflict.
`verify_carrara.sh` → `VERDICT KIT: OK` pe toate cele **26** de GLB-uri.
Detaliile pe piese sunt în `carrara_inventory_crr-a.md`, `_crr-b.md`,
`_crr-c.md`; coordonatorul a văzut comparațiile.

| grup | piese | verdict |
|---|---|---|
| crr-a, utilaje-hazard | `derrick`, `marble_block_hooked`, `block_informe_a`, `quarry_excavator` | **acceptate**. Sonda derrick-ului dă aceleași verdicte ca stand-in-ul (21 OK), iar cârligul desenat cade acum pe sarcină (−12,98 față de −13,00). Rigul excavatorului e în ±0,1 m față de `rusted_digger` |
| crr-a | `lizza_sled` | **refăcută (v2, `carrara/sled-v2`), de judecat de coordonator**. v1 citea „ladă pe palet” (blocul de 2,0 m acoperea toată sania). v2: amprenta tot **2,40 × 2,39 m** (sfera r 1,200, ca sania sintetică a sondei), **monolit de 1,90 × 1,40 × 1,22 m** pe jumătatea din spate, puntea din față liberă **0,77 m**, tălpi plate pe contactul sondei și **vârfuri întoarse până la 0,85 m**, bară de cap între vârfuri, funiile longitudinale întinse în diagonală spre ea; înălțime totală 1,72 m (v1 2,51), 2.048 tri (v1 1.504), aceleași 4 noduri și sloturi. Garda `sled` strânsă la **±0,05** pe amprentă și armată pe formă (marmura 1,2–1,4 m, puntea ≥ 0,6, vârfurile ≥ 0,6, talpa la Y 0); pică pe copia de 2,6 m și pe v1. Sonda: gol, benzi, rotație, timp pierdut (0,86…1,41 s) identice cu v1 și cu sintetica; **un verdict pică pe cuantizare**: la 25 m/s `lat_max` iese 1,05298 (Muscle) față de 1,05314 (Pompierii), egale la rotunjirea de 1 mm a verdictului „cifrele diferă între mașini” (sintetica trece la limită, 1,05298 / 1,05357). Comparație: `img/carrara_fidelity/lizza_sled.png`, `_views.png`; în joc: `img/carrara_montaj/sanie_v2_G_*.png` |
| crr-b, structuri | `ponti_di_vara`, `gallery_portal`, `marmifera_portal` | **acceptate**. Nimic peste −0,05 pe banda drumului (−0,060 măsurat), goluri 10,30 × 10,85 m și 10,20 m / cheia 9,60 m; fiecare gardă pică pe copia sabotată |
| crr-c, kitul de carieră | 17 piese | **acceptate**. Blocurile citesc crem, nu alb (captura de 12 blocuri). Blocurile au 20 de triunghiuri, nu 12, fiindcă păstrează împărțirea pe două tonuri |

**Decizii pentru integrare (Godot, Track23):**
1. **Banda de patină** (`*_MarbleBase`, treimea de jos) iese o dungă gri tare
   în preview pe toate piesele de marmură (blocuri, viaduct, portalul
   galeriei, sanie). Se judecă în joc: dacă clasa `carrara_marble` o
   înmoaie, rămâne; dacă nu, nodurile `*_MarbleBase` primesc o tentă mai
   apropiată de crem sau se contopesc cu `*_Marble` (atunci blocurile revin
   la 12 triunghiuri).
2. **Derrick-ul pe Track23** cere `model_scale` 0,7256 **și** `hook_radius`
   17,9 (cum îl rulează sonda), altfel cablul din cod nu iese din cârligul
   desenat.
3. **Picioarele din spate ale derrick-ului** ajung la +7,85 m pe Z (5,7 m în
   joc), în afara colizorului catargului din cod (3,6 × 3,6). O mașină ieșită
   de pe drum trece prin ele: se pune coliziune pe instanță sau se verifică
   cu ProbeRace că nimeni nu ajunge acolo.
4. **Kitul avea semnul greșit** la derrick: cu turnul pe stânga
   (`tower_side = −1`, x = −7), +X e SPRE drum, nu dinspre el. Constructorul
   a deschis A-ul de-a lungul drumului (Z), deci nimic nu trece de ±1,78 pe
   X. Corectat în `carrara_kit.md`.
5. **Excavatorul** așteaptă codul: `_build_excavator` încarcă fix
   `rusted_digger.glb` și pune `rust_metal` pe tot modelul (punctul 1 din
   lista de cod a brief-ului §5.6).
6. **Coliziunile** structurilor: `mesh` pe viaduct și pe portaluri;
   `Viaduct_Parapet` se stinge dacă rămâne berma din cod pe pod; șinele din
   portalul Marmifera se taie dacă încurcă.

### Clasele cablate (coordonator, 27 oct 2026)

`CLASSES_CARRARA` în `scenes/props/world_prop.gd` (scopat pe tema `carrara`,
celelalte piste neatinse): `*_Marble` → `carrara_marble` pe blocuri, stive,
blocurile informe, moloz, bermă, conducte, portalul galeriei și pilele
viaductului; prefixul `X_Marble` prinde și `X_MarbleBase`, deci **dunga gri a
patinei dispare în joc** (decizia 1 închisă). `Portal_Stone` (Marmifera) →
`tf_stone`. `Viaduct_Brick` → **`ok_roof`**: pe atlas ieșea portocaliu-viu, pe
`roof_tiles` (fără tentă pe temă) aproape alb, pe `ok_roof` cărămidă roșie.

| captură | ce arată |
|---|---|
| `clase_A_coridor.png` | stivele citesc piatră tăiată cu vene, nu lemn. Containerul și rezervorul de motorină rămân pe atlas, dungate (piese de metal, fără clasă) |
| `clase_viaduct_sus_a.png`, `_sus_b.png` | arcele de cărămidă roșie pe pile de marmură, în V-ul cheiului, sub tablier |
| `clase_viaduct_chei_b.png` | camera a ieșit sub teren (vedere nevalidă ca joc); arată doar că pilele citesc marmură |
| `clase_C_blocuri.png`, `clase_galerie_iesire.png` | pentru comparație cu capturile de dinainte |

Materiale pe pistă (`probe_decor --track=23`): **21** (≤ 38).
Hazardele (blocul derrick-ului, sania, camionul) iau clasele prin
`prop_classes()`, nu prin tema pistei: blocurile lor de marmură rămân pe atlas
până se adaugă acolo.

## Stare la oprire

- Pilotul e complet: harnasul, GLB-ul, garda, comparațiile. `bash
  tools/blender/verify_carrara.sh` → `VERDICT KIT: OK`.
- Nu s-a atins `scenes/` sau `scripts/`; integrarea (`BusHazard.model`, clasa
  `carrara_marble` pe `*_Marble`) și ProbeRace rămân coordonatorului.
- Rămas deschis (estetic): pana laterală a benei spre cabină e mai scurtă
  decât pe planșă; nervurile din relief sunt pe aceeași culoare cu placa (se
  citesc mai bine în joc, cu AO și umbră decât în preview).
- Neverificat: aspectul în Godot (clasa de marmură, umbre) și coliziunea pe
  ProbeRace.

## Montajul valului 1 pe Track23 (27 oct 2026)

Ramura `carrara/kit-montaj` (din `carrara/kit-val1`). Integratorul a montat pe pistă
derrick-ul, sania, viaductul, cele patru portaluri și o primă trecere ușoară a
kitului de carieră. Fracțiile de mai jos sunt **pe index** (`TrackRoute.frac_at`, ca
în `metadata/zones`), nu ale brief-ului.

### Cum supraviețuiește regenerării

Track23 e **generat** (`tools/gen_carrara_route.py` rescrie tot `.tscn`-ul). Montajul
e scris **în generator**, nu de mână în scenă: un bloc nou (secțiunea „MONTAJUL
VALULUI 1") derivă fiecare transformare din axa coaptă (`tools/data/carrara_baked.csv`)
și din etichetele traseului, deci piesele urmează drumul dacă se mută. Scena de pe
ramură e exact ieșirea generatorului. Tot acolo, camionul: generatorul scria încă
`kamaz_truck.glb`, iar schimbarea pe `quarry_truck.glb` fusese făcută de mână în
scenă, deci o regenerare ar fi întors-o. Acum o scrie generatorul.

Două lucruri sunt **măsurate pe teren** și scrise ca cifre: `KIT_Y` (cota fiecărei
piese de decor și a portalurilor) și `DERRICK_DROP` (0,30 m). Se remăsoară cu
`tools/ProbeCarraraMontaj.tscn -- --decor --portals --no-manual-batch` (și `--scan=...`
pentru teren) dacă se schimbă relieful sau traseul în A, C, D, F, H. O piesă fără
intrare în `KIT_Y` cade pe „drum − 0,3".

**Cod partajat atins (un singur loc, implicit neschimbat):** `HazardMarker.rock_roll_model`
(export, implicit `true`) + o linie în `Track._build_rockfall`. `RockfallHazard.roll_model`
exista, dar nodul nu-l putea seta. Cheia intră în spec doar când e stinsă, deci
celelalte piste rămân bit-identice. Commit separat.

### Ce s-a montat

| piesă | unde | setări | coliziune |
|---|---|---|---|
| **derrick** (`CraneHazard`, `Hazarduri/Derrick`) | frac 0,3124, x 128,5 z −20,0, pe dreapta de 41 m a fundului C (x 103 → 144, spre E); −Z al nodului pe sensul de mers (0,0° măsurat) | `crane_model` derrick.glb, `slab_model` marble_block_hooked.glb, `model_scale` 0,7256, `hook_radius` 17,9 (rază 12,99 m), `tower_side` −1, `tower_offset` 7, `period` 23, `road_half_width` 4,5, `load_clearance` 0,9 | catargul: colizorul din cod; picioarele din spate: `PicioareSpate`, cutie 2,58 × 3,0 × 4,39 m pe +Z local (talpa de bârne + picioarele A-frame-ului, +1,31 … +5,70 m), marginea dinspre drum la 5,71 m de axă (decizia 3) |
| **sania** (`HazardMarker` kind ROCKFALL, `Hazarduri/Sanie` + `Jgheab`) | trecerea la frac 0,8153 (x −329,8 z 61,8), după colțul SV, drumul spre N | `model` lizza_sled.glb, scara 1, `rock_speed` 6,5, `rock_pause` 33,57 (7,43 s de mers + pauză = **41,0 s**), `rock_roll_model` false, `rock_stick_to_ground` true; jgheab drept de 43 m la 40° față de axă, vine din dreapta-spate (în sus pe pantă) și se oprește pe platoul din stânga | sfera clasei; lovitura = strivirea de 3 s a clasei |
| **viaduct** (`DecorManual/Viaduct/PontiDiVara`) | centrul la frac 0,7137 (x −152,5 z 112), peste rapa 0 (0,706–0,721) | originea pe axă, Z-ul modelului în lungul drumului, **înclinat cu panta drumului** (−2,46°, dreapta de sub profilul concav cu golul maxim cel mai mic): drumul coboară ~1,5 m pe cei 36 m, iar un viaduct orizontal ar fi ieșit cu ~0,6 m prin asfalt la capătul de V. `Viaduct_Parapet` **stins** (`visible = false` + `keep_variants`) | `mesh` |
| **portaluri** (`DecorManual/Portaluri`) | `GalerieIntrare` frac 0,4004 (fața la x 290,14), `GalerieIesire` 0,5909 (x 99,82), `MarmiferaIntrare` 0,9516 (x −250,30), `MarmiferaIesire` 0,9748 (x −199,30) | aceeași plimbare pe axa coaptă ca `Track._build_tunnel` (capacul la 0,3 m în afara capătului, rama încă 1,2 m): planul feței GLB = fața ramei de beton din cod (**0,00 m** măsurat cu o rază pe axă), −Z spre exterior; baza pe terenul minim de sub stâlpi − 5 cm (umerii stau cu ~0,3 m sub asfalt). Marmifera: `Portal_Rail` **tăiat** (șinele ieșeau 5 m pe drum în afara tubului) | `mesh` + `camera_blocker` |
| **coridorul A** (`DecorManual/ZonaA`) | 0,012–0,042: 6 piese pe stânga (lat −8,5 … −9,2), 5 pe dreapta (lat +9,0 … +9,4, pe bancul dintre berma din cod și buza de 13 m) — `block_stack_a/b`, `marble_block_b/c`, yaw ±2–7°; `office_container` (0,004, −13, lungul pe drum), `fuel_tank` (0,0087, −12,5), `work_lamp` (0,046, +9,5, lângă excavator) | coridorul din stânga se oprește înainte de ieșirea camionului 1 (x > −50); toate la ≥ 27 m de curbele camioanelor | `hull` (implicit) |
| **blocuri informi C** (`DecorManual/ZonaC`) | 4 pe dreapta la lat +12,5 (0,298 / 0,338 / 0,352 / 0,375), unul pe stânga la −8,8 (0,370, interiorul cotului 2); toate la ≥ 37 m de turnul derrick-ului (raza sarcinii 13 m) | prima variantă la 8–8,5 m: `C_Informe3` (0,375, exteriorul ieșirii din cotul 2) a dat o ejectare-perete la 30 m/s pe ProbeRace, identică în două serii → mutate la 12,5 m | `hull` |
| **berme la capetele podului** (`DecorManual/ZonaF`) | 4 × `safety_berm`, la 0,7012 și 0,7234, lat ±8,2 (dincolo de berma din cod), deschise ±15°, înclinate cu panta drumului; panta modulului (−X) spre drum | punctuație; berma din cod rămâne marginea AI-ului | `hull` |

Nemontat, cum cere scopul: satul, creasta, utilajele valului 2, colțul de muzeu, și
**blocul basculat din D** — trăiește în sala de 16 m din galerie, care nu s-a construit
(tubul are 8 m pe toată lungimea).

### Măsurătorile montajului (`ProbeCarraraMontaj`, înainte de orice cursă)

| | rezultat |
|---|---|
| turnul derrick-ului | lateral −7,00 m (stânga, drumul ±4,5), −Z al nodului la 0,0° de sensul de mers; baza la 1,70, terenul sub turn 1,71, asfaltul 2,00 |
| sarcina | 392 de cadre peste drum pe o perioadă (6,5 s), lateral −4,49 … +4,49 (ambele benzi), **talpa la 0,64–0,67 m peste asfalt**, 2 treceri pe perioadă |
| sania | perioada 41,00 s, `roll_model` stins, abaterea de la jgheab 0,00 m, traversează −4,50 … +4,46, la 35,7° față de axă la intrarea pe drum; golul sub tălpi **0,04 m în afara marginii drumului**, 0,32 m pe banda de margine (treapta de 0,3 m dintre asfalt și umăr: o talpă rigidă de 2,4 m are un colț în aer sau în asfalt câteva cadre, oricum) |
| viaduct | 85 de puncte de drum peste el; cea mai înaltă față a lui e la **−0,060 m** sub asfalt |
| portaluri | stâlpii nu plutesc (−0,05 pe toate patru); fața GLB = fața ramei din cod (±0,00) |
| decor (27 de piese) | plutire max −0,03 (nimic în aer); îngropare 1–9% (blocuri), 31–46% la capătul din deal al modulelor de bermă |

### Gărzile — înainte (ramura cum am găsit-o) / după

| gardă | înainte | după |
|---|---|---|
| `ProbeLaneClear --track=15` | 9 blocate × 3 rulări (**fără linie de bază**: ieșea 0 orice ar fi găsit) | 9 × 3, aceleași 9 (excavatorul la 0,050 ×4, camionul 2 la 0,685 ×5); **armată**: `"Carrara (Track23)": 9`, `--sabotaj` → `REGRESIE — 12 > 9`, ieșire 1 |
| `ProbeBuried --track=15` | OK, 0 îngropate, 198 tavane | OK, 0 îngropate, 198 tavane |
| `ProbeDecorBuried --track=15` | PICAT: „pista n-are DecorManual" | TRECUT: 0 îngropate din 28 |
| `probe_decor --track=23` (materiale) | **16** materiale, 43 de prop-uri | **19** materiale (≤ 38), 125 de prop-uri |
| `probe_solid --track=23` | „fără DecorManual" | 28 de corpuri (23 hull, 5 mesh), gabaritul trece liber pe toată linia |
| `probe_decor_overlap --track=23 --manual` | — | 66 de piese, 0 peste asfalt, 0 una în alta |
| `bash tools/verify_local.sh --no-import` | — | **`VERIFICARE LOCALA: OK (57 pasi)`**, ieșire 0 (pe starea comisă) |
| `probe_manual --track=23` | nu compilează în modul `--script` (`GameState` lipsă), și pe ramura de bază | idem — înlocuită de `ProbeDecorBuried` |

### ProbeRace A/B (`SEEDS=16 PAR=5`, 210 s, 8 mașini)

Linia de bază = ramura cum am găsit-o. „după 1" și „după 2" = montajul cu blocurile
din C la 8–8,5 m (aceleași 16 seed-uri, de două ori: majoritatea seed-urilor au dat
**aceleași** evenimente la aceeași secundă, deci diferențele față de bază sunt
sistematice, nu zgomot Jolt). „după 3" = **starea comisă** (blocurile din C mutate la
12,5 m). Loviturile de hazard sunt numărate DISCRET de contorul nou din `probe_race.gd`.

| | bază | după 1 | după 2 | **după 3 (final)** |
|---|---:|---:|---:|---:|
| repuneri | 13 | 12 | 12 | **6** |
| ejectări | 5 | 5 | 5 | **2** |
| `[blocaj]` total / la excavator (0,047–0,051) | 16 / 11 | 11 / 8 | 13 / 12 | **12 / 11** |
| `[blocaj]` pe zone | A 11, T1 2, T2 3 | A 9, F 2 | A 13 | **A 12** |
| repuneri pe zone | A 8, C 1, H1 1, T1 1, T2 2 | A 3, C 2, E 4, T2 3 | A 5, C 2, E 3, T2 2 | **A 4, T2 2** |
| ejectări pe zone | A 4, C 1 | A 2, C 2, F 1 | A 2, C 2, F 1 | **A 1, F 1** |
| ture | 301 | 300 | 300 | 302 |
| tur minim / mediu (mediana pe seed-uri) | 65,07 / 69,50 s | 65,04 / 69,77 | 65,22 / 69,91 | **65,11 / 70,04** |
| timp pe felii (mediana mașinii, față de bază) | — | −0,08 s | −0,03 s | **−0,11 s** |
| cadre de contact cu camioanele | 127 | 242 (124 într-un singur seed) | 326 | 214 (76 într-un seed) |
| lovituri derrick / sanie | — | 21 / 15 | 23 / 13 | **17 / 10** |

Atribuirea fiecărui eveniment nou:
- **Derrick:** 17–23 de lovituri pe 16 curse (~1 la 15 treceri prin C), la 0,305–0,317,
  exact unde sarcina trece axa (0,307 și 0,317). Felia 0,30–0,35 are aceeași viteză
  mediană ca în bază (31,7 → 32,1 m/s): **teatru apropiat**, pedeapsa o plătește doar
  cine e lovit. Trei lovituri la rând pe aceeași mașină încetinită (s12, 6–8 m/s,
  1,6 s) — sarcina lentă o prinde din nou după `hit_cooldown`; fără blocaj.
  Zero `[blocaj]`/repuneri lângă turn sau lângă colizorul picioarelor.
- **Sania:** 10–15 lovituri pe 16 curse, grupate la t ≈ 127–128 s și ≈ 209 s: ciclul
  de 41 s e determinist și cade pe sosirea plutonului în turul 2 și 3 (faza vine din
  fracție, `Track._build_rockfall`). Felia 0,80–0,85 −0,3 m/s mediană. **Pedeapsă
  reală, rară** — aproximativ o lovitură pe cursă.
- **Ejectarea din F (0,704, s8, în toate trei seriile):** NU e a podului. Urmărită la
  0,1 s (`PROBE_RACE_TRACE=2`, seed 8, reproductibilă): la t = 76,7 s mașina trece pe
  lângă **excavator** (x −43, frac 0,050), viteza cade 36,8 → 21,7 m/s și e **împinsă
  prin asfalt** (y 25,0 → 22,0 în 0,4 s); apoi merge **3 m sub drum** cu 14,5 m/s un tur
  întreg (40% „în afara șoselei") și la 0,704 lovește fața de capăt a viaductului (singurul
  corp de sub drum pe care îl întâlnește) → ejectare + repunere. Cauza e excavatorul
  (problemă deschisă din brief §7 pasul 5); coliziunea viaductului doar a terminat o
  mașină-fantomă.
- **Repunerile din E (după 1–2: s1, s11, s15) și blocajul din F (s11):** mașini ieșite pe
  DREAPTA bermei din cod la x −63 … −120 (cu 15–70 m înaintea podului), atingând
  `Parapet` (berma din cod), nicio piesă montată la mai puțin de 7 m. Orele se potrivesc
  exact cu **camionul 2 venind din față** spre capătul lui de la E (reapare la 39,7 s și
  99,7 s, 8 m/s → la x −110 pe la 56 s și la x −70 pe la 124 s). Ipoteză: hazardele noi
  mută puțin sosirea plutonului (+0,3 s/tur la coada distribuției) și întâlnirea cap în
  cap cu camionul se schimbă. În după 3 nu mai apar deloc — sensibilitate de calendar a
  unui hazard existent, nu geometrie nouă.
- **Ejectările din C (după 1–2):** s5, 0,374, 30 m/s, la 1,5 m de colțul lui
  `C_Informe3` (8,5 m pe dreapta, exteriorul ieșirii din cotul 2) → **a mea**, reparată
  (blocurile la 12,5 m; în după 3 dispare). s7, 0,398 (gura de jos a galeriei, lat +6,
  în spatele aripii din cod): aceeași clasă exista în bază (s8 0,398); în după 3 nu mai apare.
- **Excavatorul** (0,047–0,051): 11 / 8 / 12 / 11 blocaje, în banda cunoscută (7–15).

### Capturi (`docs/asset_briefs/img/carrara_montaj/`, cu fereastră, camera de joc)

Unealta: `tools/snapshot.gd` (`--gamecam` = parametrii reali ai camerei de urmărire;
`--eye/--look` pentru vederile pe care camera de joc nu le are; `--crane-at` e nou,
`--rock-at` exista). Toate privite. Fără clasele de material (vezi „Deschise"),
deci marmura e pe atlas.

| fișier | ce arată | verdict |
|---|---|---|
| `derrick_C_bloc_peste_drum.png` | camera de joc la 0,300, `--crane-at=13.58` (sarcina pe axă) | blocul în chingi atârnă deasupra drumului, catargul pe stânga, cablul vertical. Se citește |
| `derrick_C_ansamblu.png` | camera liberă din dreapta | A-frame-ul deschis în lungul drumului, brațul galben, blocul la ~0,6 m de asfalt; baza de bârne stă pe teren (nodul coborât cu 0,30 m) |
| `C_blocuri_informi.png` | camera de joc la 0,355 | blocurile la 12,5 m, pe podea; citesc gri-albăstrui pe partea umbrită, nu crem |
| `sanie_G_traversare.png` | camera de joc la 0,803, `--rock-at=4.97` | sania pe asfalt, la jumătatea traversării, în diagonală |
| `sanie_G_jgheab.png` | `--rock-at=1.6` | sania în dreapta, pe jgheab. **Jgheabul nu se vede**: terenul e plat acolo (vezi „Deschise"); piesa citește „ladă pe palet", cum a spus acceptarea |
| `viaduct_F_apropiere.png` | camera de joc la 0,697 | de pe drum viaductul nu se vede (e sub tablier); se văd bermele din cod pe pod și modulele `safety_berm` la capăt. Nimic nu iese prin asfalt |
| `viaduct_F_lateral.png`, `viaduct_F_din_chei.png`, `viaduct_F_dreapta.png` | camere libere din chei și din cariera de sus | trei arce de cărămidă pe pile de marmură, culeele intră în maluri, pilele intră în V-ul cheiului (cheiul real are ~13 m adâncime, nu 26: restul pilelor e în teren). Cărămida iese portocaliu viu (atlas, fără `roof_tiles`) |
| `galerie_intrare.png` | camera de joc la 0,392 | portalul în peretele rapei C, rama de beton și aripile codului în gol; laturile GLB-ului intră în pereții rapei. Așezat bine |
| `galerie_iesire.png` | camera liberă din E | portalul stă pe banc, cu movila tubului în spate; **fără munte în spate**, citește ca o fațadă liberă deasupra movilei (masivul galeriei e departe de gura de sus) |
| `marmifera_intrare.png`, `marmifera_iesire.png` | camera de joc la 0,944 / camera liberă dinspre piazzale | arcul de piatră cu mușchi peste rama din cod, fără șine pe drum; colțurile de sus ale ramei de beton intră puțin în bolțari (rama e 9,6 × 7,8 m peste asfalt; cu portalul coborât 0,33–0,38 m pe umeri, arcul are ~7,6 m lățime la 7,8 m peste asfalt). Colțurile se pierd în piatră, nu ies în față |
| `A_coridor.png`, `A_coridor_mijloc.png` | camera de joc la 0,004 / 0,022 | coridorul de stive pe ambele părți, containerul și rezervorul la start, lampa lângă excavator; totul pe teren, cu umbră de contact. Blocurile citesc **dungate ca lemnul** (detaliul triplanar al lumii, fără clasa de marmură), iar treimea de jos (`*_MarbleBase`) e o bandă gri-albastră tare |

### Deschise

1. **Jgheabul saniei nu are pantă.** Versantul de deșeu („ravaneto") din dreapta lui G nu
   există pe teren: măsurat, +1 m pe 40 m (0,81–0,85, lat +40 … +130). Jgheabul de azi
   coboară 36,6 → 35,5 pe 43 m (~1,5°). Mecanica (perioadă, traversare, lovitură) nu
   depinde de pantă — viteza e a traseului — dar „sania coboară jgheabul de 30°" nu se
   vede. Cere relieful POI G (un `TerrainPeak`/platou în dreapta), apoi doar `Jgheab`
   se regenerează. Clopotul de 2 s nu există în cod (telegraful clasei e umbra de 1,4 s).
2. **Clasele de material nu sunt cablate** (decizia 1 a rămas nejudecată). Piesele stau pe
   atlas: blocurile citesc dungate ca lemnul, `*_MarbleBase` e o bandă gri-albastră tare
   pe stive, portaluri și viaduct, cărămida viaductului e portocaliu viu. Cablarea e o
   intrare în `CLASSES_CARRARA` (`world_prop.gd`, cod partajat, în afara permisiunii
   mele): `*_Marble`/`*_MarbleBase` → `carrara_marble` (deja pe pistă: tubul, nisipul),
   `Viaduct_Brick` → `roof_tiles`, `Portal_Stone` → `tf_stone`. Abia după ea se poate
   decide banda de patină. Metadata `clasa_triplanara` per instanță nu ajută: pune clasa
   pe TOT modelul (și pe `Portal_Glow`/`_Void`/`_Rust`).
3. **Gura de sus a galeriei** stă ca o fațadă liberă: în spate e doar movila tubului
   (~12 m), masivul galeriei e departe. Cere teren, nu GLB.
4. **Excavatorul împinge mașini prin asfalt** (vezi atribuirea) — nou găsit, nereparat.
5. Marmifera: colțurile de sus ale ramei de beton din cod intră în bolțari (se pierd în
   piatră). Galeria: laturile de 18 m intră în pereții rapei C la gura de jos (natural).
6. `lizza_sled`: v2 pe `carrara/sled-v2` (bloc de 1,22 m, vârfuri întoarse), aceleași noduri și amprentă; montajul nu se schimbă.
7. Blocul basculat din D nu s-a montat: sala de 16 m nu există.
8. `tools/probe_manual.gd` nu compilează în `--script` (autoload-uri lipsă) și pe
   ramura de bază; am folosit `ProbeDecorBuried` + modul `--decor` al sondei noi.
