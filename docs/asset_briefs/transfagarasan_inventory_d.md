# Inventar tf-d — barajul și reperele (Transfăgărășan, Track21, valul 2)

Contract: `docs/asset_briefs/transfagarasan_kit.md` §1.2. Build:
`tools/blender/build_tf_landmarks.py` (`TF_ONLY=<piesă>` reface o piesă).
Preview: `tools/blender/preview_tf_d.py` (`--compare`, `--views`, `--chain vidraru_dam`).
Cote MĂSURATE pe GLB-ul exportat (`verify_glb.py`, `measure_tf_deck.py`).
Axe: Blender X lateral, +Y înainte (= −Z Godot), Z sus.

## structures/vidraru_dam.glb

Trei noduri-rădăcină (Empty, scala 1, rotație 0, toate la origine). Originea
fiecăruia e la cota drumului, pe axa drumului. Geometria e poziționată față de
ea: turnul pe −X (lacul), centrala la picior pe +X (hăul). Integrarea pune
`Dam_Tower`/`Dam_PowerHouse` cu **același** transform ca modulul lângă care
stau.

| rădăcină | nod | slot | tri |
|---|---|---|---:|
| `Dam_Module` | `Dam_Module_Concrete` | CONCRETE 8 | 832 |
| | `Dam_Rail` | KERB_RED 7 | 176 |
| `Dam_Tower` | `Dam_Tower_Concrete` | CONCRETE 8 | 808 |
| | `Dam_Tower_Void` | VOLCANIC_BLACK 20 | 132 |
| `Dam_PowerHouse` | `Dam_PowerHouse_Concrete` | CONCRETE 8 | 440 |
| | `Dam_PowerHouse_Void` | VOLCANIC_BLACK 20 | 144 |
| total | | | **2 532** |

### Cote măsurate față de contract

| cotă | contract | GLB |
|---|---|---|
| modul pe Y | 16 m, capete plane la ±8 | 16,00 m (Y −8,00..+8,00) |
| coronament | 14 m (\|x\| ≤ 7) | 14,0 m; cornișa iese 0,6 m peste fața din aval, pe 2,1 m înălțime |
| aval | 40 m | Z −40,00 (piciorul) |
| amonte | 9 m vizibili (fundul lacului la −9) | fața de amonte, verticală la x = −7, coboară până la −40 (sub −9 e îngropată în teren) |
| fața din aval | verticală sus, concavă în ultimii 15 m | verticală la x = 6,4 până la −25, apoi x crește cu pătratul: +9 m la bază (piciorul la x = 15,6) |
| rosturi | canelură de 0,3 m la capete | 0,15 m lățime × 0,15 m adâncime pe fiecare capăt = **0,30 m** între două module |
| benzi de cofraj | 3, trepte de 5 cm | la −8 / −15 / −22 m, câte 5 cm |
| parapet | 1,1 m, 6,25 ≤ \|x\| ≤ 7,0 | **1,100 m** pe ambele părți (măsurat), blocuri de 4 m beton / roșu alternativ (ca pe serpentine), rost de 4 cm |
| turnul | 6 × 6 m, +8 m | Ø 6,6 m (placa acoperișului; cabina Ø 5,6, putul Ø 5,0), vârful la **+8,00**, centrul la x = −16,3; puțul coboară la −10 |
| pasarela | 6 m | de la x = −13,6 la −7,0 (6,6 m), 2,4 m lată, la cota coronamentului |
| centrala | 14 × 9 × 8 m | 14,0 (Y) × 9,0 (X, de la 16,2 la 25,2) × 8,0 (−40..−32) m, plus cornișa acoperișului |

### CONTRACT: nimic pe asfalt (`measure_tf_deck.py`, pe GLB)

Triunghiurile se **taie** la marginea benzii, deci se măsoară exact, nu după
vârfuri. Pe o grilă de 0,25 m se mai caută și suprafața cea mai înaltă de sub
fiecare punct.

| măsură | valoare | contract |
|---|---|---|
| cota maximă în \|x\| ≤ 6,0 | **−0,080 m** | ≤ −0,05 |
| suprafața de sub drum, min / max | −0,080 / −0,080 m | — |
| acoperire (coronamentul ține tot drumul) | 100,0 % | ≥ 99 % |
| parapet −X / +X | 1,100 / 1,100 m | 1,1 |

Sabotaj: cu `--contract=-0.10` iese `INCALCAT`, iar cu banda lărgită la 6,5 m
prinde parapetul (1,100). Deci garda chiar măsoară. Intră automat în
`verify_transfagarasan.sh` (`deck_check`).

`verify_glb.py --origin=rim --rim-above=8.1`: corpul atârnă sub origine
(Y −40,00..+8,00). Peste ea stau doar parapetul și turnul, de aceea s-a
adăugat flagul `--rim-above` (vezi „Fișiere partajate”).

### Fidelitate

Comparațiile:
- piesa izolată: `img/transfagarasan_fidelity/vidraru_dam.png`;
- 4 azimuturi: `vidraru_dam_views.png`;
- **6 module înlănțuite**, cu turnul lângă al doilea și centrala la piciorul
  celui de-al patrulea: `vidraru_dam_chain.png`. Lacul (−4,5 m) și fundul
  hăului (−40 m) sunt doar planuri de preview.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| zidul plin, bej-gri | zid lung, fără ferestre | modul plin, `*_Concrete` (#B8B4AA în preview) | OK |
| rosturi / panouri | ~7 panouri cu caneluri înguste | un modul = un plot, canelura de 0,30 m între module. În lanțul de 6 se citesc 6 panouri | OK |
| cornișa | bandă continuă ieșită, ~1/12 din înălțime | 2,1 m, ieșită 0,6 m (1/19 din 40 m) | OK. Runda 1 o avea prea slabă (1,5 m, ieșită 0,25 m), mărită în runda 2 |
| parapetul | jos, deschis, dungi roșii scurte, distanțate | blocuri de 4 m alternând beton / roșu | abatere asumată: kitul cere stilul serpentinelor. Pe planșă roșul e în liniuțe mici, în diorama e alternanță roșu-alb ca aici |
| profilul | zid aproape vertical, ușoară lărgire la bază | vertical sus, concav în ultimii 15 m (+9 m) | corectura coordonatorului. Pe lanț se citește ca piciorul unui baraj-arc |
| coronamentul în plan | ușor curb | drept | corectura coordonatorului |
| turnul | masiv, la capătul din dreapta, lipit de zid, 3 ferestre sus | cilindru pe partea lacului, cu pasarelă, cabina cu 6 ferestre, casa troliului cu 4 fante | corectura. **Abatere:** văzut din aval (camera din diorama) turnul e în spatele parapetului și citește mic. Pe planșă e reperul dominant al capătului |
| abutmentul din stânga | pilastru gros cu ceva pe el | nu intră | capetele le dă terenul (Prometeu stă pe pinten, piesă separată) |
| centrala | (din dioramă) cutie de beton la picior, apa iese la bază | cutie de 14 × 9 × 8 m, 4 ferestre înalte între 5 pilaștri, 2 ieșiri negre cu copertină, câte 3 ferestre pe laturi | OK |
| drumul | asfalt închis pe coronament | nu intră (cod); coronamentul e la −0,08 | OK |

Runde: 1 (cornișă slabă; planurile de preview ieșeau negre, fiindcă
materialul de preview înmulțește cu AO, iar ele nu aveau strat AO), apoi 2
(cornișă 2,1 m / 0,6 m, planurile reparate).

## buildings/poenari_ruin.glb — stânca refăcută (contract revizuit după val 2)

**Verdictul coordonatorului pe runda 3:** stânca citea „tort cu două etaje”
(un tambur: pereți verticali, margine de platou dreaptă, plată și continuă).
Ruina e acceptată și rămâne. Talpa de piatră ieșea ca o bandă albă continuă.
Contractul nou (kit §1.2, actualizat în același commit):
- profil conic;
- 4–6 mase mari și 3–4 ravene;
- muchia creștetului ruptă;
- talpa subțire și discontinuă.

S-au făcut 2 runde noi (4 și 5); a fost **aleasă runda 5**.

| nod | slot | tri |
|---|---|---:|
| `Poenari_Schist` | MARBLE_GREY 29 (→ `tf_schist`) | 978 |
| `Poenari_Brick` | TILE_TERRACOTTA 23 | 2 934 |
| `Poenari_Stone` | MARBLE_GREY 29 (talpa, numai pe alocuri, plus scara și molozul de piatră; → `stone_wall`) | 3 322 |
| `Poenari_Grass` | TROPICAL_GREEN 21 | 420 |
| total | `--origin=assembly`, scala aplicată | **7 654** |

### Ruina (acceptată din runda 3, neschimbată în afară de talpă)
- **Incinta:** X −11,0..+11,0 × Y(Blender) −6,0..+6,0, adică **22,0 × 12,0 m**.
  Cărămida urcă la Y 28,52. Pornește de la 17,18, fiindcă zidurile sunt
  îngropate 0,3 m, iar turnul semicircular pleacă de la 16,6 de pe masa lui.
- **Zidurile** sunt 4, rupte la 1,6–8,0 m peste creștet, cu 3 breșe și
  creneluri pe 2 bucăți.
- **8 goluri reale** de fereastră.
- **Turnul rectangular** are 6 × 6 m, e gol și are 10 m.
- **Turnul semicircular** are R 3 m și iese pe −X.
- **Moloz:** 9 bucăți în curte.
- **Scara** are 4 rampe pe −Y, 56 de trepte.
- Fără acoperiș, turle, steaguri sau verde pe ziduri.
- **Totalul** e 28,52 m; h/l e 28,5 / 36 = 0,79 pe amprenta stâncii, față de
  ținta ~0,85.

### Stânca nouă (`build_poenari_ruin`, lista din docstring)
- **Miezul conic** are 3 straturi neregulate (`rock_tier`, 16 puncte, jitter
  4%): baza 33 × 25 (rotundă), creștetul **25 × 15** (dreptunghi rotunjit care
  ține incinta), înalt de 18 m.
- **6 mase** de 6,5–10 m urcă la 7 / 8,5 / 11 / 13 / 15,5 / 17,4 m. Fiecare e o
  pană în două trepte: fața de jos e la ~60°, cea de sus la ~72°, cu o coamă la
  mijloc. Vârful fiecărei mase urmează foliația.
- **4 ravene** (85° / 35° / 350° / 145°) arată miezul 2–4 m mai în spate. În ele
  nu sunt blocuri mici; câte o limbă de iarbă coboară 8–12 m pe fiecare.
- **Muchia creștetului** e ruptă de 13 blocuri care ies 0,3–1,1 m peste ea.
  Covorul de iarbă e retras 0,6 m de la muchie, deci nu face inel. Mai sunt 3
  petice pe vârfurile maselor.
- **Talpa zidurilor** are 0,3–0,7 m și e doar pe jumătate din bucăți. Restul
  zidurilor pornește direct din stâncă, îngropat 0,3 m. Turnul semicircular
  stă pe masa de la −X, fără talpă.
- Molozul (16 lespezi) și scara de pe −Y au rămas.

### Măsurat pe GLB

Sonda temporară face profilul pe benzi de cotă (percentila 99,5 a ocupării) și
conturul văzut de sus (raza maximă pe 180 de direcții).

| măsură | runda 3 (respinsă) | runda 4 | **runda 5** | contract |
|---|---|---|---|---|
| amprenta la 0–1 m (cu molozul) | 36,1 × 27,2 | — | **39,2 × 30,5** (bbox 39,6 × 30,7) | ~36 × 28 |
| la 17–18 m | 27,8 × 18,3 | — | 31,2 × 16,3 | creștetul ~25 × 15 |
| panta flancului pe Y | 75° | 67° | **67°** | 60–70° |
| panta flancului pe X | 76° | 82° | **77°** | 60–70° — **ABATERE** |
| cea mai lungă muchie dreaptă văzută de sus (toleranța 0,3 m) | 7,0 m | 7,5 m | **4,6 m** | ≤ ~6 |
| adâncimea medie a scobiturilor conturului | 0,16 m | 0,57 m | 0,43 m | — |
| înălțimea stâncii | 18 | 18 | 18,0 (platoul); blocurile de pe muchie ating 20,1 | 18 |

**Abaterea pe X, cu cauza măsurată:** la 17–18 m silueta pe X are 31,2 m, nu
25. Cele două mase de la capete urcă prea sus:
- cea de la −X, la 17,4 m, poartă turnul semicircular, care iese peste muchie;
- cea de la +X urcă la 15,5 m.

Reparația (n-am mai făcut-o, fiindcă s-au epuizat cele 2 runde): masa de la +X
coboară la ~9 m, iar cea de la −X se îngustează doar sub turn (~6 m lățime).
Altfel turnul ar atârna în gol.

### Fidelitate

Comparațiile sunt în `img/transfagarasan_fidelity/`:
- `poenari_ruin.png` și `poenari_ruin_views.png`;
- **de la 190 m:** `poenari_ruin_far190.png`, cu ochiul la 10 m deasupra bazei
  și FOV vertical 68°. Panoul A e camera de joc (aplecată 28,75°), panoul B e
  privirea aproape orizontală (−3°). Zoom pe B (4×, nearest):
  `poenari_ruin_far190_zoom.png`.

**„Se citește ruină pe un colț de stâncă?” Da, de la 190 m:** o movilă
trapezoidală de stâncă gri, cu mase și ravene verzi, și ruina portocalie
deasupra. De aproape, stânca citește mai degrabă **trunchi de con cu
contraforturi** decât grămadă neregulată de blocuri. Linia creștetului e încă
aproape orizontală, iar blocurile de pe muchie sunt mici față de masa ei.

**În camera de joc la 190 m, ruina stă la marginea de sus a cadrului:** plafonul
cadrului la 190 m e ~27,5 m, iar turnul are 28,5. Asta e o chestiune de
amplasare, nu de piesă.

| element | pe planșă | runda 5 | verdict |
|---|---|---|---|
| silueta stâncii | movilă lată jos, îngustă sus, contur rupt | trapez cu 6 mase și 4 ravene; Y 67°, X 77° | **parțial:** conic pe Y; pe X masele de la capete țin flancul abrupt |
| blocurile | 12–16 blocuri mari, fisuri adânci | 6 mase în trepte, 26 de blocuri mici, 13 pe muchie | mai puțin fragmentat decât planșa: masele au fețe mari, netede |
| muchia creștetului | neregulată, cu mușchi | ruptă de blocuri, covorul retras, fără inel | OK |
| iarba / mușchiul | pete mari pe umeri și în ravene | limbi late pe 4 ravene, petice pe vârfurile maselor | OK ca așezare; mai puțin verde pe fețe decât pe planșă |
| talpa de piatră | bandă pe alocuri | 0,3–0,7 m, doar pe jumătate din bucăți; nu se mai vede ca bandă | OK |
| ruina | — | neschimbată (acceptată), cu excepția tălpii | OK |

Runde:
1. **(4)** Miezul conic, 6 contraforturi, ravene cu limbi, blocuri pe muchie,
   talpa discontinuă. Contraforturile aveau fețele aproape verticale, deci
   silueta citea „piedestal cu umflături” (X 82°).
2. **(5)** Miezul cu baza lărgită și rotundă, masele în pană (~60° jos, ~72°
   sus), blocurile de pe muchie mai joase și mai late, limbile de iarbă mai
   late. **Aleasă:** conturul de sus a scăzut de la 7,5 la 4,6 m, iar flancul
   pe X de la 82° la 77°.

## props/prometheus_statue.glb

| nod | slot | tri |
|---|---|---:|
| `Statue_Bronze` | LARCH_RUST 27; părul și pânza de pe șolduri LOG_DARK 28 | 402 |
| `Statue_Bolt` | CAR_YELLOW 16 (`--allow-car-slots=Statue_Bolt`) | 64 |
| `Statue_Schist` | MARBLE_GREY 29 (→ `tf_schist`) | 204 |
| `Statue_Grass` | DRY_VEGETATION 13 | 60 |
| total | `--origin=assembly` | **730** |

Abateri de la lista de noduri din kit, cu motiv:
- **`Statue_Grass` e nod în plus.** Iarba de pe creștet nu poate sta în
  `Statue_Schist`, fiindcă clasa `tf_schist` șterge sloturile (regula 6).
  Slotul e `DRY_VEGETATION`, pentru că iarba de pe decupare e
  galben-verzuie, nu verde;
- **`--allow-car-slots=Statue_Bolt` în loc de `*_Bolt`:** `verify_glb`
  potrivește pe prefix, deci `*_Bolt` nu ar prinde nimic.

| cotă | contract | GLB |
|---|---|---|
| total | 9 m | **9,10 m** (vârful fulgerului) |
| soclul | 3 m, Ø ~4 m | 3,10 m (blocurile ies 0,1 peste creștet); tamburul Ø 4,6 → 3,2 la creștet, cu blocurile și molozul 5,7 m |
| figura | 6 m cu brațul ridicat | creștetul capului la 7,33 (4,3 m peste soclu), pumnul ridicat la 8,24, fulgerul la 9,10 |
| fulgerul | 3 segmente, 1,5 m | 3 segmente plate de 0,12 m grosime, axa de 1,5 m la 55°, ultimul segment ascuțit |
| h/l | ~1,6 | 9,1 / 5,7 = 1,60 |

### Fidelitate

Comparațiile sunt `img/transfagarasan_fidelity/prometheus_statue.png` și
`prometheus_statue_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| soclul | tambur scund, fețe plane, creștet plat cu iarbă galbenă, 4 bolovani | tambur cu 7 blocuri pe foliație, 5 lespezi la picior, iarbă în interiorul creștetului | OK |
| figura | masivă, umeri lați, pas larg, genunchi îndoiți, trunchi aplecat | umeri de 2 m, coapse groase, genunchi îndoiți în afară, piept aplecat 0,15 m | OK ca masă. **Abatere:** poza e simetrică și frontală, iar pe planșă trunchiul e răsucit. Mușchii sunt plăci mari, nu anatomie |
| brațul ridicat | fulgerul ramificat mare, în diagonală spre exterior | brațul drept (+X) ridicat, fulgerul cu 3 segmente | contractul (brațul drept, 3 segmente) bate decuparea (brațul stâng, ramificat). Fulgerul citește mai vertical și mai mic decât pe planșă |
| fulgerul mic | în mâna coborâtă | 0,8 m, spre jos-afară | OK (e pe decupare și nu e contrazis) |
| silueta din spate | — | brațul și fulgerul ies din contur pe toate cele 4 azimuturi | OK |
| text | fără | fără | OK |

Runde:
1. Figura subțire, ca de robot, cu pectoralii ca doi ochi; iarba ieșea peste
   soclu ca un capac.
2. Umeri mai lați, o singură placă de piept, iarba trasă înăuntru; fulgerul
   citea ca un steag (prea lat față de zig-zag).
3. Picioare scurte și groase, genunchi îndoiți, piept aplecat, cap între
   umeri, fulger îngust (0,17 m) cu zig-zag mai adânc. **Aleasă.**

## Fișiere partajate schimbate

- `tools/blender/verify_glb.py`: flagul nou `--rim-above=M`, adică cât are voie
  să urce geometria peste coronament la `--origin=rim`. Implicitul e 0,01,
  deci comportamentul de dinainte. Zidurile de sprijin (`--origin=rim`) trec
  identic.
- `tools/blender/verify_transfagarasan.sh`: secțiunea „val 2, tf-d” (înaintea
  blocului „GLB-uri nedeclarate”), cu `deck_check`.
- `tools/blender/tf_shapes_nature.py`, `transfagarasan_shapes.py`,
  `preview_transfagarasan.py`: **neatinse**. Helperele noi (`se_ring`,
  `rock_tier`, `tier_blocks`, `grass_ledge`, `emit_roots`) stau în
  `build_tf_landmarks.py`.
- Noi: `tools/blender/measure_tf_deck.py`, `tools/blender/preview_tf_d.py`
  (`--compare`, `--views`, `--chain vidraru_dam`, `--far <nume>`: vederea de
  la 190 m cu ochiul la 10 m).
- `docs/asset_briefs/transfagarasan_kit.md` §1.2: rândul `poenari_ruin`
  rescris pe contractul revizuit al stâncii (în commitul refacerii).

## Verdictele coordonatorului (13 oct 2026)

- **`vidraru_dam`: ACCEPTAT.** Turnul mic rămâne abatere scrisă și se
  reverifică în joc.
- **`prometheus_statue`: ACCEPTAT.** Poza frontală și simetrică rămâne
  abatere scrisă.
- **`poenari_ruin`:** stânca e refăcută pe contractul revizuit (rundele 4–5,
  mai sus), iar ruina e acceptată. Pentru stâncă se așteaptă verdictul.

## Stare la oprire (tf-d, 13 oct 2026)

Gata, pe ramura `transfagarasan/kit-d`, un commit pe piesă:
- `vidraru_dam` (2 runde);
- `poenari_ruin` (3 runde, plus stânca refăcută în 2 runde, runda 5 aleasă);
- `prometheus_statue` (3 runde).

`bash tools/blender/verify_transfagarasan.sh` → **VERDICT KIT: OK**. Contractul
„nimic pe asfalt” e măsurat pe GLB și intră automat în verdict. Acceptarea pe
comparații rămâne a coordonatorului.

De făcut la montarea în Track21 (coordonatorul):
- **barajul:**
  - 6 × `Dam_Module` la pas de 16 m pe coronament (fracțiile 0,078–0,123);
  - `Dam_Tower` și `Dam_PowerHouse` cu **același** transform ca modulul lângă
    care stau: turnul iese singur pe partea lacului, centrala la picior;
  - capetele lanțului se îngroapă în pereții culoarului de stâncă;
  - clasa `concrete` pe `*_Concrete`;
- **Poenari:** `tf_schist` pe `Poenari_Schist`, `stone_wall` pe
  `Poenari_Stone` (talpa palidă trebuie întunecată spre stâncă), coliziune
  `mesh` pe `Poenari_Schist`;
- **Prometeu:** `tf_schist` pe `Statue_Schist`, pus pe pintenul de la capătul de
  est al barajului.
