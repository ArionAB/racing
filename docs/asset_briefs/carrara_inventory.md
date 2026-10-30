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
