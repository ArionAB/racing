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

# Grupa kit-b: pagode vermilion + Kinkaku-ji (ramura `kyoto/kit-b`)

## `structures/sanjunoto_pagoda.glb` si `structures/koyasu_pagoda.glb` (3 runde)

Construite cu `_verm_pagoda(cfg)` din `build_kyoto_pagodas.py` (hip_roof, frame_ring, ring_stack, corp retras 0,55, console vermilion, colturi ridicate). `yasaka_pagoda.glb` neschimbat (7 526 tri, git fara diff).

- sanjunoto: 4 362 tri, 10,0 x 10,0 x 18,0 m, streasini 4,7/4,35/4,0 semilatime, sorin 4,5 m (25%). koyasu: 3 898 tri, 7,6 x 7,6 x 14,0 m, streasini 3,5/3,4/3,25, sorin 3,4 m (24%).
- Noduri: `Pagoda_Roof`, `Pagoda_Body`, `Pagoda_Windows`, `Pagoda_Spire` (verify cu `--allow-car-slots=Pagoda_Spire`).
- Comparatii: `docs/asset_briefs/img/kyoto_fidelity/{sanjunoto,koyasu}_pagoda.png`, planșa comuna cu yasaka: `docs/asset_briefs/img/kyoto_fidelity_valkitb_pagode.png`.
- Abateri ramase: ferestrele sunt patrate cu rama alba (pe planșa sunt rotunjite, cu inel alb gros); la koyasu consolele ascund ferestrele; acoperisul e mai inchis/violaceu decat gri-ul planșei (slotul `VOLCANIC_BLACK` e cerut); galeria e un sort plin vermilion + lisa, fara balustrada fina; planșa are corpurile mai inalte vizibil intre streasini.
- Diferente intre cele doua: sanjunoto mai lata, streasini descrescatoare, sorin gros; koyasu mai ingusta, streasini aproape egale, varf mai inalt, sorin subtire.

## `structures/kinkakuji.glb` (2 runde)

- 3 632 tri, 14,0 x 11,4 x 13,6 m (streasina etajului 2 = 13,2 m lat; fenixul urca pana la 13,6). Noduri: `Kin_Wood` (`BEAM`/`WOOD`, 600), `Kin_Gold` (`CAR_YELLOW`, 1 724; verify cu `--allow-car-slots=Kin_Gold`), `Kin_Roof` (1 008), plus `Kin_Windows` (goluri) si `Kin_Stone` (platforma) in plus fata de contract. Fara `SAND_LIGHT` pe fetele de sus.
- Comparatie: `docs/asset_briefs/img/kyoto_fidelity/kinkakuji.png`, 4 azimuturi: `kinkakuji_views.png`.
- Abateri: parterul e perete intunecat cu stalpi si panouri (pe planșa, ferestre mari cu zabrele); acoperisul de sus pe planșa e mai larg si mai plat, cu varf curbat; fenixul e un grup de cutii aurii (se citeste "pasare" doar de aproape); etajul 3 mai putin retras decat pe desen.

## Runda de corectura (dupa verdictul coordonatorului)

- Tigla tuturor celor 4 piese: `VOLCANIC_BLACK` (#55535A) -> `ASPHALT_EDGE` 6 (#696765); pe randare primul iesea ~(79,77,84), violet. `yasaka_pagoda` re-verificata: 7 526 tri, cote 11,6 x 11,6 x 24,1 neschimbate. Contractul de sloturi din `kyoto_kit.md` actualizat.
- Ferestre pagode: rotunjite (arc sus) cu inel alb gros, 3 pe fata (`_arch_window`). sanjunoto 7 146 tri, koyasu 6 698 tri (ferestrele cu arc dubleaza triunghiurile fata de runda 1).
- koyasu: corp retras 0,5 din streasina, console joase (un inel + blocuri mici) care nu acopera ferestrele, streasini 3,7/3,65/3,55 cu `swell` 0,5 si colturi ridicate 0,7-0,8 (acoperis de sus mai lat si evazat), 8,4 x 8,4 x 14,1 m.
- kinkakuji: parter cu ferestre mari cu zabrele (montanti + traverse peste fundal intunecat retras), acoperis de sus 6,2 x 5,0, rise 1,5 (mai lat, mai plat), etaj 3 retras 2,9 x 2,2 (fata de 4,9 x 3,8 la etajul 2), varf auriu mic (bulb + ou + flacara) in locul fenixului. 5 348 tri, 14,0 x 11,4 x 13,7 m.
- Planșa comuna a pagodelor refacuta: `docs/asset_briefs/img/kyoto_fidelity_valkitb_pagode.png`.

## Stare la oprire (kit-b)

Toate cele trei piese facute, verify OK, runda de corectura aplicata si comisa.

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

## Poduri (kit-e, `build_kyoto_bridges.py`)

**Latimile sunt ale DRUMULUI REAL** (`Track18.tscn` `custom_width_segments`, semilatimi, si
fractiunile din `tools/gen_kyoto_route.py`; v2 dupa verdictul coordonatorului):
tsutenkyo +-4,5 m (frac 0,449-0,466, plus parapet procedural imediat in afara), podul
trenului +-6,0 m (frac 0,804), togetsukyo +-7,0 m (frac 0,832-0,894).

| piesa | tri | cote (m) | gol/liber masurat (`measure_gap.py`, banda 0,15-2,0) | noduri | comparatie |
|---|---:|---|---|---|---|
| `tsutenkyo_roof_module` | 2460 | 13,82 lat (streasina +-6,9) x 6,00 lung x 10,03 (coama +8,3..8,8, piloni la -1,0); stalpi la x=+-5,4, inalti 4,95 m | liber lateral intre stalpi **10,45 m**; **inaltime libera >= 4,65 m pe toata latimea drumului +-4,5 m** (mediana 4,85; muchia de jos a grinzilor ~4,83, a streasinii la x=6,9 ~4,8) | `Tsu_Roof`, `Tsu_Wood`, `Tsu_Rail` | `img/kyoto_fidelity/tsutenkyo_roof_module.png` (+`_chain`, `_views`) |
| `togetsukyo_module` | 1188 | 15,26 lat (punte +-7,6, balustrada +-7,4) x 10,00 lung x 3,38 | liber intre balustrade **14,35 m** (+-7,17) | `Toget_Wood`, `Toget_Rail` | `img/kyoto_fidelity/togetsukyo_module.png` (+`_chain`, `_views`) |
| `iron_truss_bridge` | 1524 | 21,16 (X; travee ~20,8 m) x 5,80 (Y) x 10,55 | **gol 15,15 m** (x -7,58..+7,57), **inaltime libera min 6,25 m** (mediana 6,40) | `Truss_Iron` (CAR_RED, exceptie), `Truss_Stone`, `Truss_Deck` | `img/kyoto_fidelity/iron_truss_bridge.png` (+`_views`) |

**Contract inghetat (iron_truss_bridge):** drumul +-6,0 m trece pe Y; golul liber 15,15 m
(culeele solide la |x| >= 7,6, deci 1,6 m fata de marginea drumului) x >= 6,25 m inaltime.

Module: capete plane la Y=+-L/2, cusaturi verificate pe `_chain`. Tsutenkyo are
frontoane deschise (hipul de capat e in afara modulului). Podina are fata de sus la
Z=-0,04 (sub drum). Verify: `--origin=waterline` (module), `--origin=assembly
--allow-car-slots=Truss_Iron` (pod). Preview: `preview_kyoto_bridges.py`.

**Verdict:** forma ok. Abateri: lemnul mai maro decat decuparea (slotul `WOOD`); roșul
podului putin mai aprins (CAR_RED); balustrada togetsukyo mai putin densa; culeele nu
sunt in decupare.

**Stare la oprire:** v3 (tsutenkyo cu streasina sus, liber >= 4,5 m); v2 cu latimile reale, verify OK, comparatii refacute.

# Grupa halls (`build_kyoto_halls.py`, kit §1.3) -- runda 2 (dupa verdictul „pica pe forma")

Unealta: `tools/blender/measure_gap.py <glb> [--band=0.15,2.0] [--need=h]` -- golul
de trecere ca GOL (proiectie pe planul transversal, 5 cm, transformarile
nodurilor aplicate), nu AABB. Comparatii: `docs/asset_briefs/img/kyoto_fidelity/<nume>.png`
(+ `<nume>_views.png`; schela: `kakezukuri_scaffold_chain.png`).

## `structures/niomon_gate.glb` (runda 3, contract de gol corectat)
- 6 694 tri (`Gate_Wood` 4 340, `Gate_Roof` 1 166, `Gate_Plaster` 1 188), **30,5 lat x 14,1 adanc x 18,65 inalt, h/l 0,61**. Stalpi grosi (1,0 m) de 8 m, travei laterale de ~6 m inchise cu panouri albe (jos si sus, 3 nuki), etaj 2 de ~3,4 m cu galerie pe 4 laturi, banda de console vermilion cu accente albe, acoperis irimoya: 4 ape concave (rise 5,2, sag 2,2) + fronton vermilion pe laturile scurte.
- **Contract inghetat (GOL, measure_gap.py, banda 0,15–2,0 m): gol liber 14,30 m (x −7,15…+7,15), inaltime libera minima 7,10 m** (cerut: ≥ 14,0 m si ≥ 6 m). Motiv: drumul principal are pana la ±6,0 m si coliziunea e `mesh` solida.
## `structures/inari_romon.glb` (runda 3)
- 6 170 tri, **28,5 x 12,5 x 19,25 m, h/l 0,675** (poarta-turn, mai compacta si mai inalta relativ). Galerie doar fata/spate, 4 ferestre, creasta scurta (6,5 m), travei de ~4,8 m, fara usa laterala cu zabrele.
- **Contract inghetat: gol liber 14,10 m (x −7,05…+7,05), inaltime libera minima 7,50 m.**
- Abateri ambele: acoperisul are ~32–35% din inaltime (decupari ~40%) si frontonul vermilion e un pentagon plin sub un hood drept, nu curbat; consolele sunt blocuri nu ciorchini; panourile albe din travei sunt mari si plate; proportia latime/adancime (30 x 14) face traveele lungi.
## `structures/kakezukuri_scaffold.glb` (runda 2)
- 720 tri, 6,8 x 6,8 x 15,92 m (stalpii/puntea 6,0 x 6,0; grinzile ies 0,4 m in toate directiile). Stalpi drepti (`LARCH_RUST`, mai deschis), 4 niveluri de grinzi `WOOD` (mai inchis) CONTINUE prin toti stalpii pe toata latimea si iesind 0,4 m; stalpii de capat sunt jumatati (0,31 m), doua module dau un stalp intreg. Lant de 3: grinzile se continua peste cusaturi.
- Nota: capetele nu mai sunt strict plane in grinzi (ies 0,4 m, suprapunere identica cu vecinul); AABB-ul modulului e 6,8 pe X, deci placerul pune pasul la 6,0.
## `structures/kiyomizu_hondo.glb` (runda 2)
- 5 372 tri, 31,9 x 22,1 x 14,3 m. Acoperis principal abrupt (rise 6,4, sag 2,5), coama inalta; ACOPERIS TRANSVERSAL cu fronton de lemn triunghiular dreapta-fata deasupra unui portic, fronton mai mic pe mijloc-fata, anexa-fusta in stanga; pereti albi adusi in planul verandei (vizibili); veranda pe 45 piloni; SCARA LATA (8,4 m, 10 trepte joase, palier).
- Abateri: frontoanele sunt mai simple (fara curbura karahafu); acoperisul transversal intra in cel principal fara racordare; anexa din stanga e un singur hip, nu un inel de fuste; scara fara balustrade pe palier.

## Stare la oprire (halls)
- Facut: toate 4; portile in runda 3 (gol 14,3/14,1 m, h libera 7,1/7,5 m, h/l 0,61/0,675). Verify OK (buget gates 7000/6600). Verdictul de fidelitate e al coordonatorului.

## Grupa kit-g: grădina și bambusul (kit §1.8) — `build_kyoto_garden.py`

Verdict kit: `bash tools/blender/verify_kyoto.sh` → toate cele 11 GLB `OK`. Planșa de grup
(sub rândul lor din inventar, la scară metrică; bambusul înalt separat):
`docs/asset_briefs/img/kyoto_fidelity/garden_group.png` (`preview_kyoto_garden.py`).
Comparații: `…/kyoto_fidelity/<nume>.png`; modulul de gard în lanț: `shiba_fence_x3.png`;
4 azimuturi: `shiba_fence_views`, `garden_rock_a_views`, `moss_mound_views`, `leaf_pile_views`,
`bamboo_crown_views`. Patru runde de comparație (rock_b: 3, vezi abaterile).

| piesă | tri | cote măsurate (X×Y×Z) | noduri |
|---|---:|---|---|
| `props/shiba_fence` | 328 | 0,19 × 3,00 × 1,12 (lungime pe Y, capete plane la ±1,5, jumătăți de stâlp de 0,13) | `Shiba_Fence` |
| `plants/karikomi_shrub_a` | 64 | 1,61 × 1,52 × 0,86 | `Karikomi_A` |
| `plants/karikomi_shrub_b` | 70 | 1,96 × 1,60 × 0,85 | `Karikomi_B` |
| `rocks/garden_rock_a` | 132 | 2,07 × 1,57 × 1,02 | `Rock_Stone`, `Rock_Moss` |
| `rocks/garden_rock_b` | 28 | 1,49 × 0,94 × 0,62 | `RockB_Stone` |
| `rocks/garden_rock_c` | 106 | 1,31 × 1,41 × 0,97 | `RockC_Stone`, `RockC_Moss` |
| `rocks/stepping_stones` | 252 | 1,61 × 2,75 × 0,24 | `Stepping_Stone` |
| `rocks/moss_mound` | 302 | 3,16 × 2,35 × 0,96 | `Moss_Mound`, `Moss_Stone` |
| `props/leaf_pile` | 2 326 | 1,85 × 1,77 × 0,51 | `Leaf_Pile` |
| `plants/moso_culm` | 860 | 2,64 × 2,46 × 19,65 (tulpina Ø 0,26→0,15; 6 segmente) | `Moso_Culm` |
| `plants/bamboo_crown` | 7 564 | 5,52 × 4,37 × 9,23 (13 tulpini) | `Bamboo_Culms` 2 884, `Bamboo_Leaves` 4 680 |

Abateri față de decupare / contract (sincer):
- rocile: fețe mari (hull de ~11 puncte), culoare pe față după normală; `garden_rock_b` rămâne
  cel mai slab: crește unghiular, fără benzile paralele de pe decupare. Muschiul e petice
  rotunjite, nu limbi pe fețe.
- `garden_rock_a`/`c`: cota din contract luată ca dimensiunea cea mai mare; `a` are în plus o
  piatră mică sprijinită (decuparea o are).
- gardul: nuiele hexagonale groase în perechi, fără legăturile rotunjite și fără gura de nuiele
  ieșită din lisa de sus; culori `SAND_MID`/`TROPICAL_GREEN`/`CACTUS_GREEN`.
- karikomi: ~36 fețe (contract ~20), fără petecul ruginiu discret din `b`.
- bambus: tulpina e `CACTUS_GREEN` + inele `DRY_VEGETATION` (decuparea e verde-gălbui; contractul
  zicea `TROPICAL_GREEN`). `bamboo_crown`: frunzele mai mici/ascuțite și mai întunecate decât lime
  de pe decupare; decuparea e cvasi-pătrată (h/l ~1), contractul 2,2: cotele de gabarit (9 m) păstrate,
  rezultă h/l ~1,7; tulpini Ø 0,34→0,22, mai groase decât `moso_culm`.
- `leaf_pile`: sloturi mixte `LAVA_ORANGE`/`KERB_RED`/`LARCH_RUST` (după decupare); clasa
  `leaf_litter` le va uniformiza. Plăcuțe rombice, nu frunze lobate.
- `moss_mound`: preview-ul îl vopsește cu clasa `moss` plată; decuparea are petice lime variate (vin din clasă).

Contracte înghețate: gard pe Y cu capete plane; piese multi-nod (`Rock_*`, `RockC_*`, `Moss_*`,
`Bamboo_*`) cu offset de origine pe ansamblu; `moso_culm` cu XY păstrat pe axa tulpinii.

**Stare la oprire (kit-g):** toate cele 11 piese livrate și comise; nimic de reluat.
