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

## Grupa kit-c: arborii (`build_kyoto_trees.py`, kit §1.2)

Planșa de scară comună (aceeași cameră, 5 copaci): `img/kyoto_fidelity/arbori_scara.png`
(`preview_kyoto_trees.py`). `momiji_a` verificat identic după refactor (md5 GLB
neschimbat, 3 056 tri, 8,58 m). `_tree` are doar parametri noi opționali
(`trunk_fn`, `limb_w`); calea veche e neatinsă.

| piesă | tri (trunchi+coroană) | cote măsurate (L×A×H m) | noduri / slot | comparație | runde |
|---|---|---|---|---|---:|
| `momiji_b` | 2 440 (200+2 240) | 10,35 × 5,35 × 8,28 | `Maple_Trunk` WOOD, `Maple_Crown` LAVA_ORANGE | `momiji_b.png` | 3 |
| `momiji_c` | 3 056 (176+2 880) | 11,32 × 5,54 × 7,38 | `Maple_Trunk`, `Maple_Crown` LARCH_RUST | `momiji_c.png`, `_views` | 3 |
| `ginkgo` | 3 080 (200+2 880) | 10,40 × 6,44 × 9,83 | `Ginkgo_Trunk`, `Ginkgo_Crown` CAR_YELLOW | `ginkgo.png` | 2 |
| `niwaki_pine` | 712 (312 trunchi + 400 coroană) | 8,71 × 3,18 × 5,14 | `Pine_Trunk` WOOD, `Pine_Crown` TROPICAL_GREEN | `niwaki_pine.png` | 3 |

Fidelitate (verdict sincer):
- `momiji_b`: 3 etaje înguste, trunchi vizibil sub coroană, h/l ≈ 0,8; silueta
  „pagodă" diferă clar de `a`. Decuparea e însă un dom lat și plin (contractul și
  decuparea se contrazic; am urmat contractul). Zimțarea e „piatră spartă", nu lobi.
- `momiji_c`: tabular, asimetric, trunchi înclinat (cerut de contract); decuparea
  e un dom rotund simetric, deci **abatere mare față de planșă**, asumată din
  contract. Se citește ca acacia/arțar-bonsai, nu ca pe planșă.
- `ginkgo`: con în 5 trepte, bun ca siluetă; planșa are conul mai asimetric și cu
  crengi vizibile prin goluri (la noi doar trunchiul sub coroană). 4 252 tri.
- `niwaki_pine`: 5 nori plați pe crengi orizontale, trunchi sinuos; trunchiul
  din frustumuri suprapuse arată în trepte (nu neted); norii sunt mai netezi
  decât pe planșă. h/l ≈ 0,6 (contract 0,7).
- Cele 3 arțari au siluete distincte pe planșa de scară (dom / pagodă / tabular).

Contract ambiguu: `momiji_b/c` decupările contrazic contractul de siluetă
(ambele sunt domuri late pe planșă); `ginkgo` cere `--allow-car-slots`
(adăugat în `verify_kyoto.sh`). `preview_kyoto.py --sheet` pică pe Windows
(UnicodeEncodeError cp1252 la tipărire) — nefolosit.

Stare la oprire (kit-c): toate cele 4 piese verify OK + comparații făcute; nimic
în așteptare.

**Runda 5 (verdictul coordonatorului: decuparea castiga contractul).**
`momiji_c` refacut ca dom larg aerisit (9 ciorchini mai mici in 3 nivele, gol in
centru cu 5 crengi groase vizibile, trunchi scurt gros evazat; jos coborat la
~35%); `ginkgo` refacut ca triunghi lat (9 ciorchini turtiti in 4 nivele, baza la
~22%, trunchi scurt cu 5 crengi vizibile, l/h ~1,0, 3 080 tri). Verdict sincer:
ambele seamana acum cu decuparea ca siluetă si golurile; zimtarea ramane
"piatra sparta", nu lobi; `momiji_c` e inca putin mai simetric/rotund decat
planșa si fara nuanta sus/jos. Planșa `arbori_scara.png` refacuta.
