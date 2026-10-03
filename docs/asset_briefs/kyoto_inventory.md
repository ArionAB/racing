# Inventar assets — Kyoto (`Track18`), val 0: pilotul

Contract: `docs/asset_briefs/kyoto_kit.md` §1.1, §1.2, §3 val 0. Runda 4 (aprobată după verdictul „pică" al coordonatorului) înlocuiește rundele 1–3. Verdict kit:
`bash tools/blender/verify_kyoto.sh` → `VERDICT KIT: OK` (2/2 GLB, pe 3 oct 2026, după runda 4).

Comparațiile alăturate (decupare | randare din GLB exportat, culoare reală din
atlas, fundal `#CFCFCF`):
- `docs/asset_briefs/img/kyoto_fidelity/yasaka_pagoda.png`
- `docs/asset_briefs/img/kyoto_fidelity/momiji_a.png`
- control propriu, 4 azimuturi: `…/momiji_a_views.png`

Verdictul final e al coordonatorului; abaterile rămase sunt în tabelele de mai jos.

## `structures/yasaka_pagoda.glb` (runda 4, aprobată de coordonator)

Runda 4 după verdictul „pică": corpuri retrase (perete ≈ 0,53 din streașină),
console vermilion, lemn roșu-maroniu (`RUST`), parter cu panouri albe în rame
vermilion + ușă închisă pe soclu de piatră deschisă, fără ferestre albăstrui,
fără balustrade, colțuri ridicate 0,55–0,65 m, muchie de streașină subțiată.

- **Triunghiuri:** 7 526 (`Pagoda_Body` 3 792, `Pagoda_Roof` 2 230,
  `Pagoda_Windows` 1 152, `Pagoda_Spire` 352). Buget verify 7 700.
- **Noduri:** `Pagoda_Body` (`CONCRETE`, `RUST`, `FOAM_WHITE`, `LOG_DARK`,
  `LAVA_ORANGE`: fără clasă), `Pagoda_Roof` (`VOLCANIC_BLACK` + fațete `LOG_DARK`),
  `Pagoda_Windows` (`LOG_DARK`, `RUST`), `Pagoda_Spire` (`CAR_YELLOW`, verify cu
  `--allow-car-slots=Pagoda_Spire`).
- **Cote măsurate:** 24,10 m înălțime; streașina de jos **11,6 × 11,6 m**
  (±5,8); streașini (semilățime @ cotă): 5,5 @ 4,5; 5,05 @ 7,6; 4,55 @ 10,7;
  4,0 @ 13,8; 3,4 @ 16,9; vârf acoperiș 19,5; sorin 4,6 m. Pereții:
  semilățime 2,9 / 2,65 / 2,4 / 2,1 / 1,8 (raport 0,53 față de streașina
  etajului). Soclu 7,8 × 7,8 × 0,55. Origine la bază, centrată, fără scală pe
  rădăcină; fața (ușa) pe +Y Blender = −Z Godot.
- **h/l siluetă (3/4):** decupare ≈ 1,66, randare ≈ 1,67.
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | acoperișuri | 5, patru ape, colțuri ridicate, gri-albăstrui | 5, patru ape, colțuri 0,6 m, nervuri | OK (ale mele sunt mai netede și mai uniform întunecate) |
  | corpuri | retrase mult, benzi înalte roșu-maroniu | retrase (0,53), `RUST` | OK |
  | console | bandă vermilion sub fiecare streașină + blocuri | 2 inele vermilion + blocuri pe fiecare latură | OK ca poziție și culoare; planșa are un „țesut" mai fin de console |
  | goluri etaje 2–5 | grile/ferestre întunecate | 3 goluri/latură `LOG_DARK` | OK |
  | parter | panouri albe în rame vermilion, ușă închisă la mijloc, soclu de piatră | 2 panouri albe/latură (fața din față), ușă maro în ramă vermilion, soclu `CONCRETE` | OK; panourile par gri-verzui în randare (lumina), nu alb pur |
  | sorin | aurit, lung, cu bulb jos | `CAR_YELLOW`, bol+ou+9 inele+flacără, 19% | OK (planșa îl are puțin mai gros) |
  | balustrade | absente | absente | OK |

## `plants/momiji_a.glb` (runda 4, aprobată de coordonator)

Runda 4: coroana schimbată din lentile turtite („farfurii") în **ciorchini
volumetrici**: icosferă subdiv 3 (320 tri) turtită la ~0,72 pe verticală, cu
fiecare vârf împins radial aleator, 9 ciorchini care se suprapun parțial.
Trunchi scurt cu evazare, furcă la 2 m în 5 crengi groase care intră în
ciorchini. Vocabular nou: `kyoto_shapes.leaf_blob`.

- **Triunghiuri:** 3 056 (`Maple_Crown` 2 880, `Maple_Trunk` 176). Buget verify 3 100.
- **Noduri:** `Maple_Trunk` (`WOOD`), `Maple_Crown` (`KERB_RED`, clasă
  `maple_crimson`). Fără scală pe rădăcină, origine la bază.
- **Cote măsurate:** 8,58 m înălțime, **12,2 m** lățime coroană, 6,7 m
  adâncime; trunchi vizibil 0–2,0 m (23% din înălțime), baza Ø ~1,9 m (evazare),
  Ø ~1,0 m sub furcă. Raza trunchiului pentru coliziunea `trunk`: ~0,5 m.
- **h/l siluetă:** decupare ≈ 0,83, randare ≈ 0,70 (**−16%, ușor peste bandă**:
  coroana e mai lată decât pe planșă; se corectează strângând x cu ~10% dacă
  coordonatorul vrea).
- **Verificat din 4 azimuturi** (`momiji_a_views.png`): se citește „copac cu
  ciorchini" din toate; crengile se văd între ciorchinii de jos.
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | ciorchini | 8–10, voluminoși, suprapuși, margine zimțată | 9, icosferă subdiv 3 turtită, vârfuri aleatoare | OK ca volum și suprapunere; zimțarea e „piatră spartă", nu lobi de frunză (limita uneltei: o icosferă nu face lobi simetrici) |
  | trunchi | scurt (~22%), evazat, se desface în 3–4 crengi | 23%, evazat, 5 crengi groase | OK |
  | crengi vizibile | 2–3 prin goluri | 3–4 între ciorchinii de jos și laterali | OK |
  | goluri | câteva | câteva (între cei de jos și cei laterali) | OK |
  | formă generală | dom mai lat decât înalt | dom, ~1,4 lat/înalt | usor prea lat |
  | culoare | roșu-portocaliu, fețe sus mai luminoase | `#BB3522` × AO (interior și dedesubt întunecat) | OK pentru un slot; fără nuanță sus/jos |

## Contracte înghețate în geometrie

- `yasaka_pagoda`: origine la bază, centrată; 4 noduri; −Z Godot = fața
  parterului; fără coliziune proprie; fără scală pe rădăcină.
- `momiji_a`: origine la bază pe axa trunchiului; un nod de trunchi + unul de
  coroană (clasele se leagă per nod); `Maple_Crown` are doar `KERB_RED`.

## Ce nu s-a făcut / ce rămâne

- planșele de grup cu cutia de referință de 4 × 1,8 × 1,5 m (`--group`) — doar
  `--compare`, `--views`, `--solo`, `--sheet`;
- `.blend` sursă (`assets/blender/`): nu se salvează încă;
- variația de nuanță sus/jos pe coroană (cere al doilea slot pe nod, deci
  pierde clasa — de decis la integrare);

## Stare la oprire

*Actualizată la ultimul commit.*

- Făcut (runda 4 inclusă): decupările (59, `kyoto_assets_v1/`), `kyoto_kit.md`, uneltele
  (`kyoto_shapes.py`, `preview_kyoto.py`, `compose_kyoto.py`,
  `verify_kyoto.sh`, `crop_kyoto_sheet.py`), pilotul (`yasaka_pagoda`,
  `momiji_a`), ambele cu verify OK și comparație alăturată.
- Urmează: valul 1 (`niomon_gate`, `inari_romon`, `kakezukuri_scaffold`) după
  verdictul coordonatorului pe pilot. Pentru a adăuga o piesă: funcție în
  `build_kyoto_<grupa>.py`, intrare în `SPECS` din `preview_kyoto.py`, linie în
  `verify_kyoto.sh`, apoi `--compare`.
- Comenzi: build `D:/Blender/blender.exe --background --factory-startup
  --python tools/blender/run_build.py -- build_kyoto_pagodas.py`; comparație
  `… -- preview_kyoto.py -- --compare yasaka_pagoda` (cu `mkdir
  D:/GameDev/.render_lock` înainte, `rmdir` după).

---

# Grupa kit-d: orasul (`build_kyoto_town.py`, kit §1.6)

Verdict: `bash tools/blender/verify_kyoto.sh` -> OK pe cele 8 GLB. Comparatii:
`img/kyoto_fidelity/{machiya_a..e,teahouse_front,paper_lantern,temple_wall}.png`
(+ `*_views.png` pentru case/felinar/zid), **planșa celor 5 case langa decuparile lor:
`machiya_row.png`** (sus decuparile, jos randarile), **zid x3: `temple_wall_x3.png`**.
Toate sunt construite cu `emit_keep_xy` (kyoto_shapes.py): XY pastrat, doar Z coborat;
originea e pe axa constructiei (casa: centrul peretilor; felinar: baza stalpului).

| fisier | tri | cote masurate (X x Y x Z) | noduri |
|---|---:|---|---|
| buildings/machiya_a | 1468 | 6,27 x 7,23 x 7,77 | Machiya_Wood/Trim/Plaster/Roof/Noren(alb) |
| buildings/machiya_b | 1336 | idem | idem, Noren = CAR_BLUE (`--allow-car-slots=Machiya_Noren`) |
| buildings/machiya_c | 2260 | idem | Wood/Trim/Plaster/Roof |
| buildings/machiya_d | 1840 | idem | Wood/Trim/Plaster/Roof/Bamboo (SAND_MID) |
| buildings/machiya_e | 1912 | 6,6 x 7,23 x 7,77 (cu streasina laterala) | Wood/Trim/Plaster/Roof |
| props/teahouse_front | 728 | 4,20 x 3,00 x 3,17 | Tea_Red (CAR_RED), Tea_Wood |
| props/paper_lantern | 404 | 1,45 x 0,77 x 3,60 | Lantern_Wood, Lantern_Paper, Lantern_Band (ICE_CRACK, negrul cel mai apropiat) |
| structures/temple_wall | 1176 | 1,22 x 8,00 x 3,31 | Wall_Stone, Wall_Plaster, Wall_Roof |

**Fata spre drum (masurat pe GLB):** nodurile fatadei (noren, jaluzele, ferestre) stau la
z glTF = -2,6..-2,8, deci fata bogata e **-Z Godot = +Y Blender**; spatele (z +) are doar
stalpi si brauri. Verificat si cu `--views` (azimuturile 35/125 arata fata, 215/305 spatele).
Coliziunea: toate nodurile cer corp doar pe `Machiya_Wood` (miezul), nu pe streasina.
Pozitia in lot: fatada e simetrica pe X, hisashi iese 1,05 m in +Y (Y bbox 7,23 = adancimea
peretilor 5,2 + streasini); axa casei ramane la origine.

**Cum se citesc cele 5 case (functie comuna `_H`, difera pe fatada):** a = noren alb + 4
ferestre albe; b = noren ALBASTRU + perete alb sus cu fereastra cu 3 panouri; c = trei
ferestre inalte sus + trei travei de zabrele fine jos, FARA noren; d = 4 jaluzele de
bambus ocru; e = perete alb cu cadru aparent + geam divizat + streasina laterala.

| element | pe planșă | in GLB | verdict |
|---|---|---|---|
| silueta, h/l | ~0,95-1,0 | ~1,05 (randare) | OK |
| acoperis 2 ape + streasina intermediara | da | da, creasta paralela cu strada | OK; la noi acoperisul pare putin mai inalt/greu |
| noren a (alb) / b (albastru) | 2 panze albe / 3 albastre | 2 / 3 fasii | OK ca pozitie si culoare; a se citeste cam "geam" (alb cenusiu sub streasina) |
| jaluzele d | 4 panouri inclinate ocru | 4 panouri drepte ocru | OK (fara inclinare) |
| e: half-timber + streasina laterala | da | da, simplificat | OK |
| culoarea lemnului | brun cald, mediu | `machiya_wood` #4A3526 = aceeasi cu Trim -> randarea e mai intunecata si cu contrast mai mic decat planșa | ABATERE de clasa (se decide la integrare, textura clasei trebuie sa ridice lemnul) |
| fatada pe 3D | planse pictate | zabrele/rame ca geometrie fina | OK |

teahouse_front: banca rosie cu spatar de zabrele, cutie, stalp, umbrela rosie cu 16 fete.
Abateri: umbrela mai mica relativ la banca decat pe planșă; banca/cutia sunt cutii drepte;
lungimea totala 4,2 m depaseste cota ~3 m din contract (decuparea castiga: umbrela mare).
paper_lantern: fara semn rosu, fara text; bandele sunt ICE_CRACK. Lantern ovala cu 4 inele.
temple_wall: soclu 3 randuri de pietre CUBICE (planșa le are rotunjite, poligonale, cu
muschi: abatere; muschiul vine din clasa/nodul separat la integrare), perete alb, capac in
doua ape cu 16 nervuri pe parte; capete plane la +-4 m, nervurile cad simetric
(pas 0,5, offset 0,25 de la capat) -> 3 module alaturate se imbina fara cusatura (`temple_wall_x3.png`).

Ambiguitati de contract: casele "6,5 x 9 m" nu se potrivesc cu decuparea (fatada ~6,3 m
cu streasina, adancime mica); am urmat decuparea (fatada 6,27, adancime 7,2 cu hisashi).
Culoarea albastra a norenului cere exceptia `--allow-car-slots=Machiya_Noren` (declarata).

## Stare la oprire (kit-d)
Toate cele 8 piese construite, verificate si comparate; casele ar mai castiga in rundele 5+
inclinarea acoperisului/ornamente si lemnul mai deschis (clasa). Comenzi: build
`D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_kyoto_town.py [machiya_a ...]`.

## kit-d, runda dupa verdictul coordonatorului (case + ceainarie)

- Proportie: parter 3,4 m, etaj 2,8 m, panta ~33 grade; casele au acum 6,27 x 7,23 x **8,97 m** (amprenta peretilor 5,2 x 5,2). Tri neschimbati ca ordin (1336-2260).
- Contrast: `Machiya_Trim` = `WOOD` (deschis: stalpi, brauri, rame, zabrele, scanduri de usa), `Machiya_Wood` (clasa `machiya_wood`) = miezul peretilor, timpanele si fondul intunecat al golurilor. Grinzile de streasina/creasta au trecut pe nodul `Machiya_Roof` (`LOG_DARK`).
- Soclu de piatra (`CONCRETE`) mai lat, in Trim. Noren (a, b): bara sub streasina intermediara, 2/3 fasii cu fante, coboara 2 m; usa intunecata se vede dedesubt.
- teahouse_front: banca mutata in stanga (ca pe decupare), randata. 
- Ramas: randarea pastreaza acoperisul mai greu decat planșa, noren-ul alb inca se poate citi ca geam (stau sub streasina), soclul tot mai subtire decat pe decupari.
