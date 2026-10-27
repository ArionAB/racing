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
| `quarry_truck.glb` | **2,830** | **3,380** | **7,730** | 0,000 | −Z (z mediu al vârfurilor 2,44 m față de centru) |
| contract | ≤ 2,9 | ≤ 3,4 | 7,6–8,2 | ≈ 0 | −Z |

Garda a fost rulată și pe Kamaz: reproduce 2,68 × 3,13 × 8,0 (deci măsoară bine).

- Triunghiuri: **7.612** (Black 4.924 din cauza a 6 × 14 crampoane, Rust 1.560,
  Body 1.080, Marble 24, MarbleBase 24). Fără plafon.
- Noduri: `Truck_Body` (DRY_VEGETATION 13 + pete SAND_SHADOW 2), `Truck_Rust`
  (RUST_METAL 10), `Truck_Black` (VOLCANIC_BLACK 20), `Truck_Marble`
  (CORAL_SAND 19), `Truck_MarbleBase` (MARBLE_GREY 29). **Materiale: 5** (un
  nod = un material). Fără CAR_YELLOW, FOAM_WHITE, text, logo-uri.
- Origine: baza amprentei, centrat pe X și Y; scala 1 și rotația identitate pe
  rădăcini (verificat în `verify_carrara.sh`).
- Primitive rotunde: roți 14 laturi, axe/evacuator 8–10.

## Fidelitate (runda 3 din 3 maxim: s-au făcut 2)

Imagini: `docs/asset_briefs/img/carrara_fidelity/quarry_truck.png` (decupare |
randare), `quarry_truck_vs_kamaz.png` (3/4 și din față, aceeași scară, Kamaz în
stânga), `quarry_truck_views.png` (4 azimuturi).

Runda 1 a dat un camion militar lung, cu capotă și roți mici; runda 2 a scurtat
nasul (cabina lipită de grilă, ca pe planșă), a mărit roțile (r 0,86) și a
ridicat podeaua benei peste ele.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| cabina | scurtă, lățită peste roți, parbriz înclinat, geam lateral | corp lat peste roțile din față, seră cu parbriz retras 27°, geam lateral, lunetă | OK |
| grila | mare, neagră, pe fața cabinei | neagră, 3 bare de vopsea | OK |
| bara | de protecție lată, galben-rugină | bară de rugină, destul de groasă | abatere mică (mai grea decât pe planșă) |
| copertina | scut inclinat peste cabină | copertină lasată 3° + bordură rugină + 2 console | OK |
| bena | adâncă, laterale înalte, perete din spate ridicat | rigidă, laterale evazate 6°, spate cu 0,30 m peste laterale, sine + 5 nervuri/parte | abatere: laterale mai joase decât pe planșă (înălțimea 3,4 m e plafon) |
| pană de bază a benei spre cabină | pană înclinată | perete drept | abatere (nemodelată) |
| roți | 4 vizibile + dublă în spate, uriașe, bandă cu crampoane | 6 roți (2 + 4 duble), r 0,86, 14 laturi, 14 crampoane, jante cu capac | OK ca număr/rol; roțile pe planșă sunt mai late/mai înalte relativ la caroserie (anvelopa de 2,83 m nu permite mai mult) |
| blocuri | 3–4 în stivă, ies mult peste bena | 2 (1,85×1,80×1,40 și 1,80×1,70×1,36), 2 tonuri, un colț spart | OK conform corecturii (2 blocuri); înălțimea 1,4 m vs 1,4–1,6 |
| culoare | galben saturat | galben-spălăcit 13 + rugină 10 | **abatere voită** (corectura de kit) |
| proporții h/l | ~0,7 în 3/4 | vizual comparabile în 3/4 (randare ~0,66) | OK ±15% |
| iese din contur | oglinzi mari, plasă pe fața cabinei | oglinzi mici în lățimea roților, nimic atârnat | OK (voit) |
| lățime | 3,6 m | 2,83 m | **abatere voită** (anvelopa Kamaz) |

Praf (SAND_SHADOW) doar ca o fâșie pe flancul benei. Marmura n-are vene, dungi
și lumină din clasă (apar la integrare, în joc); în preview e `#E8D6B2` / `#B8B4AC`.

## Contracte înghețate

- Anvelopa camionului: ≤ 2,9 × ≤ 3,4 × 7,6–8,2 m, botul pe +Y Blender (−Z Godot),
  originea jos la mijlocul amprentei; coliziunea e AABB-ul, nimic nu iese din contur.
- Numele de noduri `Truck_Body/Rust/Black/Marble/MarbleBase`.
- ProbeRace pe camioane se reia la schimbarea modelului (coordonatorul).

## Stare la oprire

- Pilotul e complet: harnasul, GLB-ul, garda, comparațiile. `bash
  tools/blender/verify_carrara.sh` → `VERDICT KIT: OK`.
- Nu s-a atins `scenes/` sau `scripts/`; integrarea (`BusHazard.model`, clasa
  `carrara_marble` pe `*_Marble`) și ProbeRace rămân coordonatorului.
- Rămas deschis (estetic, nu de contract): laterale de bena mai adânci și pana
  de lângă cabină; bara de rugină poate fi subțiată. Se schimbă în
  `build_quarry_truck` fără a atinge anvelopa dacă coordonatorul le cere.
- Neverificat: aspectul în Godot (clasa de marmură, umbre) și coliziunea pe
  ProbeRace.
