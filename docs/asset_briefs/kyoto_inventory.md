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

# Inventar assets — Kyoto, grupa F: templele (`build_kyoto_shrine.py`)

Contract: `kyoto_kit.md` §1.7. Verdict kit: `bash tools/blender/verify_kyoto.sh` -> `VERDICT KIT: OK` (13/13 GLB, 3 oct 2026).
Reguli aplicate: unde contractul contrazice decuparea castiga decuparea (exceptie: cote de gabarit); tigla gri = `ASPHALT_EDGE` 6; lemn deschis `WOOD` vs inchis `LOG_DARK`; kasagi/baze negre = `ASPHALT` 5 (decuparea e neagra, `LOG_DARK` iese maro).
Comparatii: `docs/asset_briefs/img/kyoto_fidelity/<nume>.png`; planse de grup langa randurile din inventar: `grup_templele_A_cu_inventar.png` (randurile 3-4), `grup_templele_B_cu_inventar.png` (randul 7); `cyclopean_wall_chain.png` (3 module cap la cap).

| piesa | tri | cote masurate (L x A x H, m) | noduri | h/l decupare -> randare | verdict |
|---|---:|---|---|---|---|
| `structures/votive_torii_cluster` | 1 960 | 11,5 x 1,14 x 4,26 | `Torii_Wood`, `Torii_Black` | ~0,39 -> ~0,37 | OK. 7 porti (decuparea arata 7, contractul 6), 4,2 -> 1,25 m, sirul spre -X (randat din az 72). Kasagi ceva mai subtire decat pe decupare |
| `props/stone_lantern_a` | 380 | 1,28 x 1,28 x 2,37 | `Lantern_Stone`, `Lantern_Window` | 1,6 -> ~1,85 | Abatere: fus drept-conic, decuparea il are cu talie; roata de sus plata, fara ghizduri |
| `props/stone_lantern_b` | 380 | 1,28 x 1,28 x 1,89 | idem | 1,1 -> ~1,5 | Abatere: ~0,2 m mai inalt decat contractul 1,7 (soclul tronconic gros din decupare); acoperis mai lat decat pe desen |
| `props/yukimi_lantern` | 376 | 1,08 x 1,08 x 1,38 | idem | 1,17 -> ~1,28 | Abatere: arcada e un gol dreptunghiular (decuparea: arc rotunjit); talie fara profil |
| `props/kitsune_statue_a` / `_b` | 438 | 1,48 x 1,14 x 2,04 | `Fox_Body`, `Fox_Bib` (`CAR_RED`), `Fox_Stone` | 1,2 -> ~1,4 | Abatere: gabarit 1,48 x 1,14 fata de contractul 0,9 x 0,9 (soclul larg din decupare); vulpea e mai unghiulara/zvelta decat desenul, bavetele par barba din fata; cheia in gura OMISA (optionala, nu apare pe decupari). a: capul spre dreapta, coada stanga; b: oglindit |
| `structures/small_shrine` | 1 204 | 3,40 x 2,78 x 3,59 | `Shrine_Wood`, `Shrine_Roof`, `Shrine_Stone` | 1,13 -> ~1,15 | Abatere: acoperis in doua ape cu frontoane vermilion pline (decuparea: frontoane cu cadru si console), soclul din blocuri plate, nu bolovani rotunjiti; ~0,15 m peste 3,4 |
| `props/ema_rack` | 1 252 | 3,50 x 0,78 x 2,28 | `Ema_Wood`, `Ema_Rails`, `Ema_Roof`, `Ema_Plaques` | 0,88 -> ~0,8 | OK. 4 randuri x 6 placute goale (decuparea; contractul 3x4). Placutele nu se suprapun ca pe desen |
| `structures/bell_tower` | 1 130 | 6,90 x 5,52 x 6,08 | `Bell_Wood`, `Bell_Beams`, `Bell_Roof`, `Bell_Bronze` (`TROPICAL_GREEN`), `Bell_Stone` | 0,82 -> ~0,85 | Abatere: gabarit stalpi 4,5 m / acoperis 6,9 (contract 5 x 5; decuparea cere acoperis mai lat decat stalpii); clopot verde prea viu |
| `props/chozuya` | 800 | 3,44 x 2,38 x 3,26 | `Choz_Wood`, `Choz_Beams`, `Choz_Roof`, `Choz_Stone`, `Choz_Ladles` | 0,76 -> ~0,8 | OK ca siluet; abatere: 3,26 m fata de 2,8 (acoperis mai inalt ca pe decupare); bazinul e mai deschis si mai scund |
| `structures/cyclopean_wall` | 2 422 | 8,00 x 2,58 x 4,12 | `Cyc_Stone`, `Cyc_Moss` | 0,52 -> ~0,5 | Abatere: 4 randuri de pietre (decuparea 5), pietre mai plate si mai uniforme, miez inchis; capete plane la +-4,00 m (previzualizat in lant) |

Contracte inghetate: toate piesele cu origine la baza, centrata (`--origin=assembly`), fata spre +Y Blender; sirul de torii se intinde spre -X; zidul are capetele plane la x = +-4; musch doar in `Cyc_Moss`.

Ambiguitati de contract: (1) numarul de torii (6 vs 7 pe decupare), (2) gabaritele vulpilor/clopotnitei (0,9/5 m) contrazic proportia de pe decupare, (3) `kasagi` negru: contractul zice `LOG_DARK`, decuparea e neagra (folosit `ASPHALT`).

## Stare la oprire (grupa F)

Toate cele 11 fisiere (+ perechile a/b) sunt livrate, cu verify OK si comparatii; 4 runde pe zid, 3-4 pe restul. Nerezolvat: bolovani rotunjiti si profil cu talie la felinare, frontoane cu cadru la altarel, cheia vulpii. Comenzi: build `-- build_kyoto_shrine.py`; comparatie `-- preview_kyoto.py -- --compare <nume>`; grup `-- preview_kyoto_shrine_group.py -- --group A|B`, apoi `python tools/blender/compose_kyoto_group.py --render ... --row 316,443 --out ...`.
