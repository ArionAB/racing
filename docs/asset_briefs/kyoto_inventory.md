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

# Grupa halls (`build_kyoto_halls.py`, kit §1.3)

Unealta noua: `tools/blender/measure_gap.py <glb> [--band=0.15,2.0] [--need=h]` —
golul de trecere ca GOL (proiectie pe planul transversal, rasterizata la 5 cm,
transformarile nodurilor aplicate), nu AABB.

## `structures/niomon_gate.glb` (runda 3)
- **Triunghiuri:** 3 738 (`Gate_Wood` 2 796, `Gate_Roof` 882, `Gate_Plaster` 60). Noduri: `Gate_Wood` (`LAVA_ORANGE`, `LOG_DARK`, `WOOD`, `CONCRETE` socluri), `Gate_Roof` (`VOLCANIC_BLACK` + `LOG_DARK`), `Gate_Plaster` (`FOAM_WHITE`).
- **Cote:** 20,9 lat x 13,1 adanc x 13,55 inalt. **Contract inghetat (masurat ca GOL, banda 0,15–2,0 m): gol liber 11,80 m (x −5,90…+5,90), inaltime libera minima 4,10 m peste tot golul.** Directia de mers = Y Blender (−Z Godot); golul e centrat pe x = 0. Stalpii laterali (cate 2 pe adancime, x = ±6,6 si ±8,7) pot fi solizi; nimic nu intra in banda golului sub 4,1 m.
## `structures/inari_romon.glb` (runda 3)
- **Triunghiuri:** 3 218. Aceleasi noduri. **Cote:** 18,5 x 11,7 x 12,65 m. **Contract inghetat: gol 11,50 m (x ±5,75), inaltime libera minima 3,80 m.**
- Diferit de Niomon (nu e copie): galerie doar fata/spate, etaj mai ingust si mai inalt, 4 ferestre vs 3, creasta scurta (3 m vs 5 m), panta mai abrupta, stalpi mai scurti, fara usa cu zabrele laterala.
- **Fidelitate (ambele), runda 3:** OK: 2 etaje, acoperis gri 4 ape cu streasina curbata, galerie cu balustrada vermilion, ferestre intunecate, panouri albe in travee, gol larg, socluri de piatra, culori pe zone. **Abateri:** fara fronton (irimoya) vizibil pe latura, acoperisul e yosemune simplu; consolele sub streasina sunt mai rare si mai simple decat „ciorchinii" de pe planșă; travee laterale mai usoare decat masivele de pe planșă; Romon: o „ureche" de arete in dreapta acoperisului (artefact de colt cu creasta scurta); inaltimea Niomon 13,55 vs 13 (ornamentele de creasta).
- Comparatii: `img/kyoto_fidelity/niomon_gate.png`, `inari_romon.png` (+ `_views`).

## Stare la oprire (halls)
- Facut: niomon_gate, inari_romon. Urmeaza: kakezukuri_scaffold, kiyomizu_hondo.
