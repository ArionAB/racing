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

## buildings/poenari_ruin.glb

| nod | slot | tri |
|---|---|---:|
| `Poenari_Schist` | MARBLE_GREY 29 (→ `tf_schist`) | 1 274 |
| `Poenari_Brick` | TILE_TERRACOTTA 23 | 2 890 |
| `Poenari_Stone` | MARBLE_GREY 29 (talpa zidurilor, scara, molozul de piatră; → `stone_wall` la integrare) | 4 070 |
| `Poenari_Grass` | TROPICAL_GREEN 21 | 588 |
| total | `--origin=assembly`, scala aplicată | **8 822** |

Cote măsurate (Godot Y sus):

| cotă | contract | GLB |
|---|---|---|
| stânca | 18 m | `Poenari_Schist` Y 0,58..18,70 (platoul plat la 18,0; blocurile ies ≤ 0,12 peste el) |
| amprenta | ~32 × 24 m, mai lată la bază | corpul are 32 × 24 la bază; cu soclul de blocuri și molozul ajunge la 36,6 × 28,0 |
| zidurile | 10 m peste creștet | `Poenari_Brick` Y 18,53..28,52 (turnul rectangular: 10,0 m + zimții) |
| incinta | ~22 × 12 m | X −11,0..+11,0, Y(Blender) −6,0..+6,0 = **22,0 × 12,0** |
| total / h/l | 28 m / ~0,85 | 28,52 m; 28,5 / 32 = 0,89 pe corp (0,78 cu molozul) |

Elemente: 2 trepte abrupte, cea de jos cu vârful înclinat (8,6..11,4 m) și
platoul plat. Pe ele stau 63 de blocuri de șist în 4 inele, iar fața de sus a
fiecăruia e planul de foliație: 35°, aceeași direcție pe toată stânca
(`SchistFrame` la 25°). La picior sunt 16 lespezi (`foot_rubble`). Iarba e în
14 petice pe treapta de jos, un covor pe creștet și 11 limbi care atârnă peste
muchia platoului.

Ruina:
- 4 ziduri rupte la 1,6–8,0 m, cu talpa de piatră de 0,4–1,6 m;
- 3 breșe coboară aproape de talpă (1,6 / 2,4 / 2,8 m);
- creneluri pe **2 bucăți**;
- **8 goluri reale** de fereastră;
- turnul rectangular de 6 × 6 m, gol, de 10 m, în colțul +X/−Y;
- turnul **semicircular** (R 3 m) iese pe −X peste muchia stâncii, iar talpa
  lui coboară la cota 11;
- 9 bucăți de moloz în curte.

Scara e pe −Y, în **4 rampe în zig-zag**, cu 56 de trepte și parapet. Nu se vede
din față. Nu are acoperișuri, turle, steaguri sau verde pe ziduri.

Coliziunea `mesh` pe stâncă o pune coordonatorul. `Poenari_Schist` e nod
separat, deci poate primi corp propriu.

### Fidelitate

Comparațiile sunt `img/transfagarasan_fidelity/poenari_ruin.png` și
`poenari_ruin_views.png`.

| element | pe planșă | în GLB | verdict |
|---|---|---|---|
| stânca, masa | movilă lată, ~2/3 din total, pereți abrupți | 18 / 28,5 = 0,63, soclu lățit la bază | OK ca proporție |
| stânca, blocurile | ~12–16 blocuri mari, fețe plane, fisuri verticale adânci | 63 de blocuri cu rosturi, dar fețele mari ale treptelor se văd între ele | **abatere:** citește mai mult „perete cu plăci” decât „grămadă de blocuri”; fisurile sunt mai puțin adânci decât pe planșă |
| mușchi / iarbă | pete mari pe umeri, trepte, creștet | covor pe creștet, limbi peste muchie, petice pe treapta de jos | **abatere:** sunt mai puține pete pe fețele stâncii decât pe planșă. Corectura kitului permite verde doar pe trepte și pe creștet |
| incinta de cărămidă | ziduri rupte la înălțimi diferite, muchii în trepte | 4 ziduri pe bucăți de 1,6–8 m, colțurile de sus rupte ±0,35 m | OK |
| turnul înalt | spate-stânga, ~1,5× zidurile, gol, ferestre | rectangular, 10 m, gol, 3 ferestre, spate-stânga în 3/4 | OK |
| al doilea turn | dreapta, rectangular | semicircular pe −X | corectura kitului |
| ferestre | ~6 goluri închise | 8 goluri reale (se vede prin ele) | OK |
| piatra la bază | bandă gri pe alocuri | talpă de 0,4–1,6 m sub toată cărămida | **abatere:** în preview iese mai deschisă decât stânca: e `MARBLE_GREY` brut, iar stânca e pe ținta clasei. Talpa turnului semicircular (7 m sub platou) citește ca o coloană palidă. Se reglează cu clasa `stone_wall` |
| culoarea cărămizii | roșu-cărămiziu, umbrit | `TILE_TERRACOTTA` plat, portocaliu | abatere de slot, nu de formă |
| verde pe ziduri, moloz roșu | da | fără verde (corectura kitului); 9 bucăți de moloz | OK |

Runde:
1. Camera era pe −Y, unde se vedea scara, din cauza unei erori de semn la
   azimut. Stânca era un „tort” cu 3 trepte și inele orizontale, iar banda de
   piatră era palidă și continuă.
2. Camera corectată, 2 trepte, cea de jos înclinată, iarbă care atârnă,
   turnul mutat înăuntru, talpa de piatră variată.
3. Soclu de blocuri mari la picior, deci silueta de movilă. Mai multe blocuri,
   talpa de piatră mai subțire. **Aleasă**, fiind mai bună decât 2.

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
- Noi: `tools/blender/measure_tf_deck.py`, `tools/blender/preview_tf_d.py`.

## Stare la oprire (tf-d, 13 oct 2026)

Gata, pe ramura `transfagarasan/kit-d`, un commit pe piesă:
- `vidraru_dam` (2 runde);
- `poenari_ruin` (3 runde);
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
