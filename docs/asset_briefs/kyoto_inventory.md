# Inventar assets — Kyoto (`Track18`), val 0: pilotul

Contract: `docs/asset_briefs/kyoto_kit.md` §1.1, §1.2, §3 val 0. Verdict kit:
`bash tools/blender/verify_kyoto.sh` → `VERDICT KIT: OK` (2/2 GLB, pe 3 oct 2026).

Comparațiile alăturate (decupare | randare din GLB exportat, culoare reală din
atlas, fundal `#CFCFCF`):
- `docs/asset_briefs/img/kyoto_fidelity/yasaka_pagoda.png`
- `docs/asset_briefs/img/kyoto_fidelity/momiji_a.png`
- control propriu, 4 azimuturi: `…/yasaka_pagoda_views.png`

**Verdict propriu, sever:** ambele piese au silueta și numărul de elemente
corecte, dar **nu sunt la nivelul planșei la detaliu** (vezi „Abateri"). Nu le
declar „trec" fără ochii coordonatorului.

## `structures/yasaka_pagoda.glb` (runda 2 din max 3; 3 randări de comparație)

- **Triunghiuri:** 9 534 (`Pagoda_Body` 5 352, `Pagoda_Roof` 2 390,
  `Pagoda_Windows` 1 440, `Pagoda_Spire` 352). Fără plafon (CLAUDE.md); buget
  declarat în `verify_kyoto.sh`: 9 600.
- **Noduri / materiale:** 4 noduri, un material fiecare la integrare.
  `Pagoda_Body` conține patru sloturi (`WOOD`, `FOAM_WHITE`, `LOG_DARK`,
  `MARBLE_GREY`) — **nu primește clasă** (atlas); `Pagoda_Roof` e `VOLCANIC_BLACK`
  + fațetele streașinii pe `LOG_DARK` (atlas, fără clasă); `Pagoda_Spire`
  `CAR_YELLOW` (verify cu `--allow-car-slots=Pagoda_Spire`).
- **Cote măsurate din GLB:**
  - înălțime totală **24,10 m** (contract 24 m, +0,4%); sorin **4,6 m** (19%);
  - streașina de jos **12,6 × 12,6 m** (nodul `Pagoda_Roof`: ±6,3); corpul
    etajului de jos 6,9 × 6,9 m; soclul 9,2 × 9,2 × 0,55 m;
  - cele 5 streșini (semilățime, cotă): 6,0 @ 4,5 m; 5,5 @ 7,6; 4,95 @ 10,7;
    4,35 @ 13,8; 3,65 @ 16,9; vârful acoperișului de sus la 19,5 m;
  - origine la bază, centrată (`--origin=assembly` OK; bbox ±6,3 pe X/Z).
- **Orientare:** piesa are simetrie de 4 ori; „fața" (golul și ușa mare a
  parterului) e pe +Y Blender = −Z Godot. `verify_glb --front=-Z` marchează doar
  sorin-ul (cilindru rotund); nu e o eroare de orientare.
- **h/l siluetă (3/4):** decupare ≈ 1,66, randare ≈ 1,50 (**−10%**, în ±15%).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | acoperișuri | 5, în patru ape, colțuri ridicate, gri-albăstrui | 5, patru ape, colțuri ridicate, nervuri de țiglă | OK (acoperișurile mele sunt ceva mai groase și mai întunecate) |
  | raport streașini jos:sus | ≈ 1 : .60 | 1 : .61 | OK |
  | console sub fiecare acoperiș | rând dublu, brun-roșcat, aglomerat | 2 inele + blocuri de capăt pe fiecare latură | abatere: mai puțin „aglomerat" decât pe planșă |
  | pereți etaje 2–5 | benzi înalte brun-roșcat cu grile/ferestre | benzi brun cu 3 goluri/latură, balustradă joasă | abatere: planșa n-are balustradă vizibilă; benzile mele sunt mai joase |
  | parter | stâlpi roșu-brun, panouri albe și goluri întunecate, ușă dreaptă | stâlpi brun, panouri albe proeminente, goluri | abatere: panouri mai subțiri/mai întunecate, ușă mai puțin lizibilă |
  | sorin | aurit, lung, subțire, bulb jos | aurit, bol + ou + 9 inele + flacără, ~19% din înălțime | OK (planșa îl arată puțin mai gros) |
  | soclu | scund, de piatră | 0,55 m, de piatră | OK |

- **Abateri cunoscute:** vezi coloana „verdict". Fără cifre de culoare măsurate
  (comparația e vizuală; culoarea compusă în joc rămâne pentru integrare).

## `plants/momiji_a.glb` (3 runde; 4 randări de comparație)

- **Triunghiuri:** 1 620 (`Maple_Crown` 1 404, `Maple_Trunk` 216). Buget în
  verify: 1 700.
- **Noduri:** `Maple_Trunk` (`WOOD`), `Maple_Crown` (`KERB_RED`, clasă
  `maple_crimson` la integrare). Fără scală pe rădăcină.
- **Cote măsurate:** înălțime **8,03 m**; lățime coroană **10,94 m** (±5,47),
  adâncime 6,0 m; trunchiul 0–5,6 m (cu crengile din coroană), baza Ø ~1,9 m la
  flare, furcă la 2,5 m; origine la bază (`--origin=assembly` OK).
- **Contract de coliziune la integrare (`trunk`):** raza trunchiului ~0,55 m
  (nu 0,95 cât are flare-ul).
- **h/l siluetă:** decupare ≈ 0,83, randare ≈ 0,83 (în bandă).
- **Tabel de fidelitate:**

  | element | pe planșă | în GLB | verdict |
  |---|---|---|---|
  | trunchi | gros, scurt (~25% din înălțime), crengi vizibile prin coroană | con drept, curat 2,5 m + furcă, crengi scurte | **abatere:** trunchiul meu e mai înalt (31%) și mai drept; crengile se văd puțin |
  | coroană | ~8 mase mari de frunze lobate, foarte suprapuse, margini zimțate adânc | 13 ciorchini turtiți cu 9 lobi, în 4 etaje, goluri între ei | **abatere:** la mine ciorchinii sunt mai separați și mai „farfurii" (orizontali), planșa e mai voluminoasă/verticală |
  | goluri | puține, prin care se văd crengile | goluri între etaje | OK, dar mai multe decât pe planșă |
  | culoare | roșu-portocaliu, fețele de sus mai luminoase | `#BB3522` plat × AO, fără variație sus/jos | **abatere:** o singură nuanță pe nod (clasa unică); variația vine doar din AO |
  | siluetă | coroană „în pom" (umflată sus) | coroană tabulară | abatere moderată: nu e glob (corect), dar mai plată |

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
- a 4-a rundă pe `momiji_a` (limita e 3): trunchiul și volumul coroanei.

## Stare la oprire

*Actualizată la ultimul commit.*

- Făcut: decupările (59, `kyoto_assets_v1/`), `kyoto_kit.md`, uneltele
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
