# Okinawa — contractul per POI pentru gauntlet

> Fișa de lucru a perechilor constructor/critic pe Track20 (`okinawa`).
> Bara e `docs/track_briefs/img/okinawa_plan/diorama_v02.jpg` (a doua generare,
> acceptată), decupată per POI în `docs/track_briefs/img/bar_okinawa/<POI>.png`
> (mărit, ≥ 1800 px; `tools/bar/crop_okinawa_bar.py`, cu justificarea fiecărei
> casete în cod; planșa de control `bar_okinawa/_index.png` arată dreptunghiurile
> pe dioramă). Densitatea (casele, trestia) mai bună în `diorama_v02_iter1.jpg`
> vine în decupajele `A_iter1` și `C_iter1`, **doar pentru densitate**.
> **`B_iter1` nu există**: iter1 are asfalt cu chiparoși în loc de aleea de nisip
> (defectul nr. 1 al primei generări, brief §9.2); arborii conici de acolo nu sunt
> fukugi. Planul real al traseului e `img/okinawa_plan/okinawa_plan.png`. Kitul
> (36 GLB) e în `docs/asset_briefs/okinawa_kit_v2.md` (cote, contracte) și
> `okinawa_inventory.md` (cotele măsurate din GLB, „Stare la oprire”).
> **Sursa de adevăr pentru traseu e măsurătoarea de mai jos
> (`tools/sv_ok_fractii.gd`), nu brief-ul §2.**
>
> Măsurătorile sunt pe `okinawa/poi-bara` = **7d940d84** (montarea kitului, PR
> #470) + această ramură (în `Track20.tscn` doar cele 8 noduri `ZonaA … ZonaH` cu
> metadata `fractii`; traseul, terenul, hazardele și piesele montate sunt
> neatinse). Se re-rulează
> `godot --headless --path . res://tools/SvOkFractii.tscn` după orice atingere a
> traseului sau a terenului și se corectează tabelul.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e o machetă pictată, văzută de sus și din
colțul de SV, în care satul, portul, aleea, câmpul de trestie, castelul, capul,
podul, insula mică și digul încap toate într-un cadru, cu dealul bombat și cu
apa aproape de fiecare drum. Pista nu face asta și nu trebuie să facă asta: din
mașină drumul e o **creastă plată** (§Premise 1), marea e la 66–110 m pe trei
sferturi din tur, iar apa apare lângă asfalt doar pe cornișă, insula mică, pod și
dig. Criticul compară **cum arată materia**, nu unde cade fiecare obiect:

- **apa turcoaz peste nisip alb** (golful, plaja G) și albastrul adânc al largului,
  cu creste albe fațetate; **spuma** ca forme plate albe;
- **olanele roșii-cărămizii cu mortar alb** în relief, case joase cu shisa pe
  creastă și zid de corali în jur; casele de beton albe cu rezervor rotund;
- **calcarul gri-crem, poros, ros la bază de val** (zidurile gusuku, falezele,
  stâncile-ciupercă): `MARBLE_GREY` + clasa `ok_limestone`, **nu** `ROCK_LIGHT`;
- **fukugi verde închis, lucios, în șiruri dese, în coloană** (nu bile rotunde);
  pin Ryukyu răsucit cu coroane turtite; pandanus pe plajă; cicade;
- **trestia de zahăr verde-gălbuie** în panouri late;
- **roșul lăcuit al porții și al palatului** cu aur în puncte mici;
- **tetrapozii gri-deschis de beton** (nu bolovani maro), numai pe dig;
- accentele vii: **hibiscus roșu** și **bougainvillea magenta**, în petice, niciodată
  aliniate; nisipul coraligen crem pe aleea B;
- cerul: albastru, cumulus mari, **peretele de furtună ardezie** la SE.

Corolar: un critic care spune „la noi dealul nu urcă în stânga drumului”, „la noi
marea nu e lângă aleea de fukugi” sau „poarta nu e pe un drum lateral” a comparat
layout-ul și a ratat sarcina. Singura diferență care contează e una pe care o poți
repara în decorul POI-ului.

**Defectele dioramei care NU se iau din imagine** (verificate pe decupajele mărite
față de pistă; brief §9.2 și măsurătorile de mai jos le confirmă):

| în dioramă | în joc | de ce |
|---|---|---|
| poarta roșie stă pe un **drum lateral**, într-o intersecție în T, lângă zidul castelului | `Poarta_D` e **PESTE bucla**, la **0.4298**, 0,5 m de axă, drumul are acolo semilățimea **6,0** (12 m), golul kitului **14,35 × 6,20 m** → 1,2 m marjă pe parte | geometria vine din traseu (brief §9.2: „o rundă în plus risca să strice”); orice poartă laterală e greșeală |
| **stânca-inimă dublă** (în golf + pe insula mică) | o singură `heart_rock`; locul ei e în apa golfului, pe dreapta insulei G (la 30–50 m, în `[golf]`) | brief §9.2 (rămas nerezolvat din dioramă); `okinawa_kit_v2.md` cere „o singură dată” |
| **tetrapozi pe tot frontul satului**, de la pod până la capătul de V | doar pe dig, **0.84–0.96** (sea la 10–14 m stânga); pe A marea e la **66–72 m** de axă, fără dig | în joc sunt 42 de tetrapozi provizorii, lângă dig |
| castelul și satul **lipite de drum**, pe un deal înalt peste el | drumul stă pe **creastă**: terenul lateral e plat la cota drumului (−0,2…−0,5 m) pe **±50 m** la A, B, C, D (§Premise 1) | relief, nu decor |
| **marea lipită de aleea B** (plajă de 20–30 px lângă zid) | marea e la **72–86 m** de aleea B | §Premise 2 |
| **cocotieri / palmieri** pe insula mică și peste tot în sat | `coconut_palm` (36) și `beach_palm_bent` (14) sunt **scatterul vechi** moștenit din Track08 (`probe_decor`); kitul nou nu are cocotier. Palmieri doar `fan_palm`, în port; insula mică ia `pandanus`/cicade | brief §0.1 |
| **mașinile de curse**, mașina în aer pe traveea ridicată, dâra de lansare | cursa e cod | nu e decor |
| **tromba, valul, feribotul sub pod** | `TyphoonHazard` (marker 0.7758), `WaveSurge` (marker 0.8811), `LiftBridgeHazard` (0.6696) — hazarde din cod | decupajele `G_tromba` / `H_val` sunt doar pentru culoarea norilor și a spumei |
| **vaporul de coastă** în larg (iter1), **farul mic de pe dig** (iter1), **trei faruri** (prima generare) | un singur far, `Far_capul_E` | brief §9.2 |
| **două drumuri / poteci** printre trestii (iter1: potecile dintre panouri) | o singură bucla | brief §9 „ONE CLOSED LOOP” |
| **bivol, egrete, broască țestoasă** pe drum | decor la ≥ 12 m de axă, nu pe bandă | brief §3.1.3 |
| palatul „pe un deal separat” | palatul e la **26–28 m STÂNGA** de axă, pe platoul de la cota drumului (+30), terenul e plat | §D |

Un critic care cere una din astea a citit diorama, nu pista.

**Respectul și interdicțiile** (brief §8): niciun *utaki*, niciun mormânt-broască,
nimic din 1945 sau militar, niciun om în costum, fără ceremonii; fără mărci, fără
text lizibil (automatele fără text), „Heart Rock” nu apare în nume vizibile.

**Pista are o singură lumină** (soare −25° din VSV, `custom_sun_rotation_deg`
(−25, −70, 0)); nu există ciclu de zi. Hazardele cu ceas (pod, trombă, val) se
capturează în fază forțată (`--bridge-at`, `--typhoon-at`, `--wave-at`, vezi
`tools/snapshot.gd` rândurile 56–66), altfel „valul pe drum” e noroc.

## Ieșirea din buclă (aceeași ca la Monument, Fiordland, Jodhpur)

Pe Serengeti 0/8 POI-uri au câștigat orb, pe Machu Picchu 0/3, pe Fiordland 0/8,
pe Monument Valley 0 la prima trecere. O dioramă pictată nu se bate orb de un cadru
low-poly (memoria `gauntlet-iesirea-din-bucla`). Deci:

- **judecata rămâne oarbă** (`blind_pair.py`, o planșă per rundă, A sau B, o
  singură diferență numită);
- **ieșirea din buclă e** una din: (a) criticul alege a noastră orb; (b) criticul
  **nu mai numește nicio diferență reparabilă în decorul POI-ului**; (c) criticul
  numește **aceeași diferență de două ori la rând** — atunci cauza e sub decor
  (relief, lumină, shader, clasă de textură, asset) și se **oprește bucla**, cu
  decizia pusă în fața dezvoltatorului (memoria `criticul-cere-ce-zona-nu-poate-da`);
  verdictele se pun unul lângă altul;
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena integrată,
  cu 5 eșantioane pe captură (memoria `o-captura-nu-e-un-verdict`).

Locuri unde (c) e de așteptat de la început, ca să nu ardă runde:
1. **dealul** (castelul „pe deal”, trestia care urcă lateral): relief; drumul e pe
   creastă, interiorul coboară (§Premise 1);
2. **marea lipită de sat / de aleea B** (relief: apa la 66–100 m);
3. **cornișa E** cu faleză de calcar vizibilă: `limestone_cliff_module` e provizoriu
   (citește bazalt columnar după 5 runde; „Stare la oprire”); cornisa o face terenul
   din cod (`custom_ravines`): asset + relief;
4. **spuma valului și forma pâlniei** (hazarde din cod, nu decor);
5. **fukugi „perete continuu”**: la pas 3,0–3,2 m rămâne un gol ~0,5 m la sol (asset);
6. **culoarea magentă a bougainvilleei** și **olanele portocaliu-pal** pe slotul 23:
   se rezolvă prin clase/tente (decizie la integrare), nu din decor.

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

**Convenția de indici pentru Okinawa: `--track=20` la TOATE uneltele.** 20 e peste
lungimea listei, deci se rezolvă ca număr de SCENĂ (`GameState.resolve_track_index`).
Atenție: `probe_decor` și `probe_manual` cu un număr mic ar măsura altă pistă și ar
da verde fals (memoria `probe-decor-numar-de-scena`).

Liniile de bază sunt măsurate azi, pe starea de la 7d940d84 + Zonele (înainte de
orice decor de POI):

| gardă | comandă | linia de bază / prag |
|---|---|---|
| ProbeLaneClear | `res://tools/ProbeLaneClear.tscn -- --track=20` | **baza = 4**, exact, toate la pod: 0.665 `RampNear` (h 1,0, la 1,75 m) și `LiftSpan` (h 1,6, la 4,37 m), 0.670 `RampFar` (h 0,4 și 1,0). Orice raportare nouă e coliziune pe bandă; atribuie-o sau scoate piesa. Verdict „OK — exact linia de bază” |
| probe_decor | `--headless --path . --script res://tools/probe_decor.gd -- --track=20` | **≤ 30 materiale** (cerința brief §6; garda pică la 38). Azi **24 materiale** (856 prop-uri, 251 desene, **362 756 triunghiuri**; procedural 59 prop-uri / 21 materiale / 102 736 tri; `coral_rock` 111, `island_scatter` 436, `tetrapod` 42, `cane_clump` 27, `stirling_ledge` 11, **`coconut_palm` 36, `beach_palm_bent` 14, `banyan` 8, `pandanus` 10, `hibiscus_bush` 95, `beach_clutter` 6** — scatterul vechi din Track08). Triunghiurile se raportează, nu pică. Un material nou se cere explicit în raport, cu ce cumpără vizual |
| probe_decor_overlap | `--script res://tools/probe_decor_overlap.gd -- --track=20 --manual` | azi **1 piesă peste asfalt**: `Wall_Limestone` intră **0,51 m** peste asfalt la (21, −243) — zidul provizoriu `Ziduri_D/Gusuku03/04` (la 9,2–9,6 m de axă). **E linia de bază și datoria lui D** (nu a unui alt POI); 0 îngropate în altă piesă. Pe restul POI-urilor: 0 piese peste asfalt |
| probe_manual | `--script res://tools/probe_manual.gd -- --track=20` | 1 „obiect de reparat” = `Poarta_D` marcată „IN DRUM” (+0,28 m peste teren; **intenționat**, poarta stă peste drum). Restul (42 tetrapozi la 11–16 m, 11 gusuku la ~9,2 m, farul la 54 m, la −0,1…−0,2 m față de teren) „ok” |
| probe_solid | `--script res://tools/probe_solid.gd -- --track=20` | **OK**. Obligatoriu pentru orice piesă `hull`/`mesh` lângă drum (plimbă CHIAR corpul mașinii) |
| ProbeBuried | `res://tools/ProbeBuried.tscn -- --track=20` | **0 îngropate, 0 tavane**, cel mai adânc +0,00 m la 0.000 |
| ProbeCameraSolid | `res://tools/ProbeCameraSolid.tscn -- --track=20` | **1 incident = linia de bază din fundație**: **0.672–0.678**, `LiftSpan` (la 8,5 și 9,1 m) + `@StaticBody3D@113` (12,2 m) între mașină și cameră, camera la (314,3; 19,0; 139,7). E la pod, nu al decorului; „pista fără linie de bază” cum spune garda; orice incident nou în afara lui e camera în solid |
| ProbeLayout | `res://tools/ProbeLayout.tscn -- --track=20` | **2058,3 m**, 1026 puncte, rază minimă **24,1 m la 0.52**, pantă maximă **8,3 % la 0.52**, apropiere de sine **55,1 m la 0.32**; verdict OK. Constructorii de POI nu ating traseul |
| probe_load_time (cu fereastră) | `--rendering-driver vulkan --script res://tools/probe_load_time.gd -- --track=20` | **3,08 / 2,03 / 2,04 s** (la rece / cald), față de Monument **5,10 / 3,78 / 3,80 s** (aceeași mașină, RTX 3070). Brief §6: ≤ Track19 + 0,5 s |
| **ProbeRace** | `--headless --fixed-fps 60 res://tools/ProbeRace.tscn -- --mode=race --track=20 --seconds=150 --seed=N --ai=7` | **8 mașini, 16 seed-uri (1..16)**: **47 repuneri în total (0–7 pe cursă, medie 2,9)**, **toate la pod: 0.635–0.665** (31 la 0.661, restul 0.635 ×5, 0.657, 0.658 ×3, 0.660 ×6, 0.665); **11 `[blocaj]`**, toate la **0.666–0.669** (`LiftSpan`/`RampNear`, v ≈ 0–4 m/s; unul fără contact la 0.669); **11 ejectări „perete”** (26–32 m/s, la 0.666 și 0.672: intrarea pe traveea ridicată); 0 ejectări „aterizare”; 0 iesiri din lume; tur minim **59,87–62,98 s** (12 ture pe cursă, 11 pe seeds 10 și 15), tur mediu **70,5–73,4 s**; `invers` ≤ 1,1 s per mașină (Kai, seed 1), 0 `carusel`; coloana `0.95–1.00: 16,7 m/s, ~38 % lent` e pre-grila de start, nu un defect. **Tot ce e în afara pasajului 0.635–0.672 e zero**: decorul nu are voie să adauge repuneri sau `[blocaj]` nicăieri altundeva (memoria `zero-repuneri-ascunde-blocajul`) |
| ProbeRace pe felie | idem + `--slice=A,B` | A: `0.974,1.0` apoi `0.0,0.1023`; B: `0.1023,0.205`; C: `0.205,0.333`; D: `0.333,0.474`; E: `0.474,0.612`; F: `0.612,0.737`; G: `0.737,0.824`; H: `0.824,0.974` — **înainte ȘI după** orice piesă cu coliziune pe felie; distribuții pe 16 seed-uri, nu o rulare (memoria `proberace-nedeterminism`) |
| sv_ok_fractii | `res://tools/SvOkFractii.tscn` (headless) | nu e gardă; re-rulat după orice atingere de traseu/teren |

`--import` înaintea oricărei serii (memoria `import-invechit-falsifica-masuratoarea`)
și după FIECARE merge (memoria `merge-curat-scena-stricata`).

## Captura: ce comandă, pentru care POI

Din mașină, `--gamecam` (camera reală: 10 m sus, 12,5 m spate, fov 68 — memoria
`verifica-cu-parametrii-lui`). Snapshot **cere fereastră**, nu merge `--headless`
(memoria `snapshot-nu-merge-headless`); capturile se fac **serial**, prin lacătul
de GPU, gărzile în paralel (memoria `capturile-nu-se-paralelizeaza`). **Snapshot
scrie mereu `snapshots/okinawa_joc.png`: copiază fișierul după FIECARE captură**
(altfel rămâne doar ultima).

```
mkdir D:/GameDev/.render_lock || (aștepți: alt agent randează)
D:/GameDev/Godot_v4.7-stable_win64.exe --rendering-driver vulkan --path <worktree> \
    res://tools/Snapshot.tscn -- --track=20 --frac=<F> --gamecam [flaguri]
cp snapshots/okinawa_joc.png <destinatie>
rmdir D:/GameDev/.render_lock
```

Fracțiile sunt **pe index** (cele pe care le ia `--frac`); pe Track20 divergența
index–lungime e de cel mult **0,0022 = 4,4 m** (la 0.989), deci contează doar pe A.

**Capturile de bază (fără decor)** sunt în `docs/track_briefs/img/okinawa_plan/poi_baza/`
(`<POI>_f<frac>.png`, 1280×720, `--track=20 --frac=<F> --gamecam`, fără alt flag):
A 0.020, B 0.140, C 0.280, D 0.420, E 0.560, F 0.640, G 0.770, H 0.900. Ce arată:
pe A/B/C/D teren verde-gri uniform, iarbă plată, asfalt albastru-închis cu bordură
roșie (kerb), în A palmieri vechi din scatterul Track08, pe B aleea de nisip crem
fără niciun arbore (la 0.140), pe D poarta roșie în parbriz, goală; pe E marea
turcoaz la stânga și nimic pe cornișă (farul nu intră în cadru la 0.56); pe F
feriboturile și traveea (în stânga-față) și golful; pe G tromba (colțul stânga) pe
nisip; pe H tetrapozii maro din kitul vechi pe stânga și golful pe dreapta. Sunt punctul
de plecare al fiecărei perechi.

| POI | frac de captură (index) | poziție (x, z) | flaguri | bară |
|---|---|---|---|---|
| A port + sat | **0.960**, **0.985**, **0.000**, **0.020**, **0.060**, **0.095** | (~110, 212), (≈70, 170), (35, 165), (−9, 167), (−108, 165), (−165, 147) | — | `A`, `A_port`, `A_iter1`, `ORIZONT` |
| B aleea | **0.105**, **0.140** (după viraj), **0.170**, **0.195** | (−178, 140), (−213, 60), (−206, 2), (−224, −47) | — | `B` |
| C trestia | **0.215**, **0.260**, **0.300**, **0.325** | (−218, −56), (−174, −141), (−95, −186), (−55, −220) | — | `C`, `C_iter1` |
| D castelul | **0.345**, **0.380**, **0.415** (poarta în parbriz), **0.4298** (sub poartă), **0.455** | (−30, −241), (28, −231), (110, −257), (143, −250), (190, −240) | — | `D`, `D_poarta`, `ORIZONT` |
| E capul + cornișa | **0.490**, **0.520**, **0.545**, **0.575**, **0.605** | (240, −210), (272, −143), (275, −90), (272, −18), (262, 30) | — | `E` |
| F coborârea + podul | **0.625**, **0.650**, **0.667**, **0.690**, **0.715** | (264, 62), (298, 118), (316, 142), (345, 172), (385, 220) | `--bridge-at=` (traveea sus + feribotul sub ea, doar pe 0.640–0.670) | `F` |
| G insula mică | **0.745**, **0.765**, **0.775**, **0.800**, **0.820** | (408, 262), (405, 305), (396, 334), (345, 361), (318, 370) | `--typhoon-at=` (pe 0.76–0.78) | `G`, `G_tromba` |
| H digul | **0.840**, **0.870**, **0.881**, **0.920**, **0.955** | (286, 364), (240, 340), (207, 320), (165, 285), (112, 232) | `--wave-at=` (pe 0.86–0.89) | `H`, `H_val` |

(pozițiile cu „~/≈” sunt interpolate din tabelul de waypoint-uri; cele fără sunt
din măsurătoare. Verifică pe captură, nu pe tabel.)

## Fracțiile reale ale traseului (NU cele din brief §2)

Măsurate pe `Track20.tscn` la 7d940d84 cu `tools/sv_ok_fractii.gd` (headless):
**2058,3 m**, 1026 puncte coapte, pas 2,0 m, **marea la y = +0,05**. Convenția de
hartă: x est, **z sud (z = −y din brief)**, sens orar pe plan. Brief-ul §2 dă
punctele în (x, y-nord); pista are z = −y. Fracții pe index (cele de aici), pe
lungime diferă cu ≤ 0,0022.

| reper | brief §2 | frac (index) | lungime | cotă | semi | poziție (x, z) |
|---|---|---|---|---|---|---|
| grila de start | (A 0,97) | **0.000** | 0 m | +2,0 | 7,0 | (35, 165) |
| „A sat port” | | 0.0448 | 94 m | +2,0 | 7,0 | (−59, 168) |
| **viraj +54° în B** (r ≈ 43) = capătul lui A | A→B 0,10 | **0.0994** | 206 m | +2,5 | 5,7 | (−168,8; 148,5) |
| **aleea de nisip** (dirt + semi 5,5) | B 0,10–0,22 | **0.1023–0.203** (semi 0.103–0.203) | 213–418 m | +2,6 → +6,4 | 5,5 | (−174, 144) → (−224, −47) |
| șicana (viraj −34°, r 68) | | 0.1803 | 372 m | +5,1 | 5,5 | (−207, −4) |
| **viraj +53° la ieșirea din B** (r 43) | B→C 0,22 | **0.2047** | 421 m | +6,5 | 5,6 | (−225, −51) |
| urcarea C: pantă 5–8 % | C 0,22–0,33 | 0.205–0.333 | 422–685 m | +6,5 → +24 | 7,0 | (−225, −51) → (−49, −231) |
| **începutul zidurilor** (semi 6,0) | D 0,33 | **0.333** | 684 m | +24,1 | 6,0 | (−49, −232) |
| viraj +57° (r 41) intrarea în D | | 0.3392 | 698 m | +25,1 | 6,0 | (−36, −240) |
| viraj −42° (r 54) | | 0.3674 | 756 m | +28,0 | 6,0 | (21, −234) |
| **cota maximă (culmea D)** | +30 | **0.4045** | 831 m | **+30,03** | 6,0 | (90, −261) |
| **poarta `Poarta_D`** | ~0,43 | **0.4298** (marker); waypoint „D poarta” 0.4337 | 891 m | +30,0 | 6,0 | (142,8; −249,9) |
| sfârșitul semi 6,0 | | 0.442 | 909 m | +29,4 | 6,0 | |
| **viraj +45° (E colț S cap)** = capătul lui D | D→E 0,46 | **0.4737** | 974 m | +27,0 | 7,0 | (227, −222) |
| `Far_capul_E` | 0,47–0,55 | 0.5166 (cel mai apropiat), **54,1 m STÂNGA** | 1063 m | drum +22,2; far +21,4 | 7,0 | (318, −170) |
| **cornișa** (`custom_ravines` 0, adânc 30, **latura stângă**) | E 0,46–0,58 | **0.5175–0.6109** (lung) | 1065–1257 m | +22,2 → +9,1 | 7,0 | (271, −143) → (258, 46) |
| pantă maximă 8,3 % | | 0.5214 | 1072 m | +21,8 | 7,0 | (272,6; −136,8) |
| **apa la 12 m stânga** | | **de la ~0.55**: apa la 12 m la 0.56 și 0.60 | | +15,4 → +10,3 | 7,0 | |
| **viraj −41° (r 56)** = capătul lui E | E→F 0,58 | **0.6121** | 1259 m | +9,0 | 7,0 | (258, 47) |
| **podul** (`custom_ravines` 1 = viaduct, adânc 12,5; semi 6,5) | 0,645–0,698 | **0.6365–0.7018** (lung; semi 0.625–0.718) | 1309–1442 m | +8,6 → +8,2 | 6,5 | (279, 92) → (365, 194) |
| **traveea** (`PodMobil`) | 0,669 | **0.6696** | 1378 m | +8,5 | 6,5 | (320,6; 146,4) |
| **viraj +47° (r 49)** = capătul lui F | F→G 0,70 | **0.7368** | 1514 m | +4,9 | 7,0 | (408, 251) |
| **tromba** (`HazardMarker` TYPHOON) | 0,77 | **0.7758** | 1597 m | +3,0 | 7,0 | (397,2; 330,3) |
| viraj +50° (r 46) pe plajă | | 0.7778 | 1598 m | +2,9 | 7,0 | (396, 333) |
| `custom_ravines` 2 (adânc 5, stânga) | | 0.735–0.805 | | | | |
| **viraj +47° (r 49)** = capătul lui G | G→H 0,83 | **0.8236** | 1693 m | +2,0 | 6,5 | (312, 372) |
| **digul** (`custom_ravines` 3, adânc 6, ambele laturi; semi 6,5) | H 0,83–0,97 | **0.835–0.946** (lung); semi 0.82–0.971 | 1720–1948 m | +1,9 → +1,7 | 6,5 | (286, 364) → (121, 216) |
| **valul** (`HazardMarker` WAVE) | 0,87 | **0.8811** | 1814 m | +1,6 | 6,5 | (207, 319,8) |
| cota minimă | | 0.8723 | 1792 m | +1,60 | 6,5 | (221, 334) |
| **viraj −54° (r 43)** = capătul lui H | H→A 0,97 | **0.9747** | 2003 m | +1,8 | 6,6 | (89,8; 171,4) |

Rază minimă a pistei **24,1 m la 0.52**; pantă maximă **8,3 % la 0.52**; golful
(`custom_lagoon`, 12 vârfuri, centroid (258, 201), adânc 14,6) conține **83 din 1026**
de puncte de drum (podul și digul); distanța minimă pod ↔ dig **165,1 m** (brief: 124 m).
Hazardele: pod → trombă **0.106 = 218 m**, trombă → val **0.105 = 216 m** (≥ 200 m ✓),
val → pod prin start ≈ 1640 m.

**Limitele de proprietate** (zona fiecărui POI; metadata `fractii` din `Track20.tscn`
le poartă acum; granițele sunt **virajele-colț măsurate**: colțul aparține POI-ului
care se termină cu el, ca să nu se calce două POI-uri):

| zonă | fracții (index) | în lume (x, z) | semi |
|---|---|---|---|
| **A** | 0.974–1.000 + 0.000–0.1023 | x −170…91, z 148…172 | 7,0 (5,7 în colț) |
| **B** | 0.1023–0.205 | x −224…−172, z −49…146 | 5,5 |
| **C** | 0.205–0.333 | x −225…−49, z −231…−51 | 7,0 |
| **D** | 0.333–0.474 (colțul r 41 de la 0.3392 e al lui D; colțul r 49 de la 0.4737 e al lui D) | x −48…225, z −261…−223 | 6,0 |
| **E** | 0.474–0.612 (colțul r 56 de la 0.6121 e al lui E) | x 227…278, z −222…43 | 7,0 |
| **F** | 0.612–0.737 (podul 0.6365–0.7018) | x 258…408, z 46…249 | 7,0 / 6,5 |
| **G** | 0.737–0.824 | x 313…410, z 251…372 | 7,0 / 6,5 |
| **H** | 0.824–0.974 (colțul de port r 43 de la 0.9747 e al lui H) | x 93…312, z 174…372 | 6,5 |

**Față de brief §2** (brief vs. măsurat):

| POI | brief | măsurat | |
|---|---|---|---|
| A | 0,97 → 0,10 | 0.974 → 0.1023 (grila la 0.000) | ✓ |
| B | 0,10 → 0,22 | 0.1023 → 0.205 | se termină cu 0.015 mai devreme |
| C | 0,22 → 0,33 | 0.205 → 0.333 | începe cu 0.015 mai devreme |
| D | 0,33 → 0,46 | 0.333 → 0.474 | se termină cu 0.014 mai târziu; poarta 0.4298 (brief ~0,43 ✓) |
| E | 0,46 → 0,58 | 0.474 → 0.612 | apa la 12 m **abia de la ~0.55** (§Premise 6) |
| F | 0,58 → 0,70 | 0.612 → 0.737 | podul 0.6365–0.7018 ✓ (brief 0,645–0,698) |
| G | 0,70 → 0,83 | 0.737 → 0.824 | tromba 0.7758 (brief ~0,77 ✓) |
| H | 0,83 → 0,97 | 0.824 → 0.974 | **valul 0.8811** (brief ~0,87) |

## Premise din brief găsite false (la 7d940d84)

Nu sunt defecte de POI; sunt fapte despre pistă pe care constructorii trebuie să le
știe înainte să citească brief-ul §2 / §9. Toate sunt **măsurate** pe scenă
(`sv_ok_fractii.gd`, profil lateral cu `_terrain_mesh_y`, pas 2 m până la 200 m).

1. **Nu există deal lângă drum: drumul e pe creastă.** Pe A, B, C și D terenul
   lateral e **plat la cota drumului (−0,2…−0,5 m) pe ±50 m** pe ambele părți. În
   interiorul buclei terenul **coboară** (la +100 m dreapta: A +3,5…+5,8 [rampa spre
   interior], B +1,2…+4,4, **C −1,6…−4,5, D −5,0…−12,9**), iar în exterior cade
   spre mare după 66–110 m. Deci „castelul pe un deal peste drum” și „trestia care
   urcă lateral” **nu sunt relief**: urcarea C e panta drumului însuși (5–8 %,
   +6,5 → +24), castelul stă pe platoul de la cota drumului (+30 sub poartă: teren
   +29,7), iar palatul (110, −285) e la **26–28 m STÂNGA** de axă pe același plat.
   Decorul e **la nivelul drumului** și coboară în **interiorul** buclei (ZONA C-D).
2. **Marea nu e lipită de sat și de aleea B.** Prima apă pe stânga: **A 66–72 m**
   (la 0.975 DREAPTA la 28 m, golful de lângă port), **B 72–86 m**, **C 86–100 m**,
   **D 100–110 m**; terenul dintre drum și mare e **plat, la −0,3…−0,5 m**, deci
   benzi de 60–100 m late de loc plat. În dioramă marea atinge zidul aleei: în joc
   sunt 70–86 m de iarbă/nisip. Apa apare lângă asfalt doar pe: **E (12 m stânga de
   la ~0.55), pod (2 m, viaduct), G (20–22 m stânga, 28–32 m dreapta), H (10–14 m
   stânga, 10–24 m dreapta)**.
3. **Portul nu e în fața grilei: e în spatele ei.** Golful se termină în V la
   (108–112, 128–178); colțul H→A (0.9747, (89,8; 171,4)) e la ~20 m de el, iar
   grila (35, 165) la 55 m **după** el. Cheiul (`harbour_quay`) stă pe **dreapta
   colțului**, vizibil din 0.94–0.99 (sfârșitul digului) și de la grilă înapoi
   nu se vede (camera privește spre V). Pe A, dreapta (N) e uscat până la +100 m;
   golful nu apare lateral decât la 0.975 (apa la 28 m dreapta).
4. **Poarta e peste drum, nu pe un drum lateral, și e mai înaltă decât camera.**
   `Poarta_D` (0.4298, 0,5 m de axă, yaw 75°, drumul are heading 105°): semilățimea
   6,0 (12 m), golul kitului **14,35 × 6,20 m** (marjă 1,2 m pe parte), înălțime
   **14,7 m** vs camera la 10 m: `metadata/camera_blocker = true` în scenă; în cadru
   (varful) pe **0.155–0.175, 0.210–0.410, 0.870–0.965** — din coborârea C (și de pe
   dig, la 0.87–0.965, peste interiorul insulei!) până aproape de ea.
5. **Palatul se vede de pe dig și din C, nu doar de pe culme**: în cadru pe
   **0.150–0.175, 0.210–0.390, 0.870–0.970**, cel mai aproape 26 m la 0.413. De pe
   dig (0.87–0.97) e la ~600 m peste golf: zona H nu poate pune nimic înalt pe axa
   spre el, iar ceața (140 → 350 m) îl topește (reper departe, nu fundal).
6. **Farul nu e „pe cornișă”: stă la 54 m STÂNGA de axă, la 0.5166, înaintea
   căderii.** Cornișa propriu-zisă (apa la 12 m) începe abia pe ~0.55. Farul e în
   cadru pe **0.215–0.220, 0.250–0.310, 0.335–0.490** (de pe creastă D și din
   C), nu de pe cornișă: de la 0.49 rămâne în stânga-spate. Pe 0.474–0.545 stânga
   e **plat la cota drumului, apă la ~98 m**, deci farul stă pe teren (+21,5,
   „nod − teren −0,1 m”) și are loc lateral, dar nu are **mare dedesubt** în cadru.
   `cape_lighthouse` e deja montat; E poate să-l mute doar pe teren real.
7. **Cornișa E are marea într-o singură parte și pe ultima treime.** `custom_ravines`
   0 (adânc 30, stânga) pe 0.5175–0.6109; la 0.52 stânga e încă pantă (−3,4…−4,2 m
   la 10–25 m), la **0.56 și 0.60 apa e la 12 m** (cădere 15–30 m). Dreapta: plat
   (−0,3…−0,6 m la 10–50 m). Deci „cădere fără parapet” = ultimii ~60 m ai cornișei
   (0.55–0.61); pe 0.474–0.545 e drum pe culme.
8. **Insula mică G e o fâșie de ~50 m, nu o insulă largă.** La 0.76–0.78 apa e la
   **20–22 m stânga (larg) și 28–32 m dreapta (golf)**; terenul între apă și drum e
   nisip plat −0,3…−1,2 m. În dioramă insula are 150 m de pandanus și stânci. În joc:
   **10–15 m de plajă pe fiecare parte** în care încap pandanus, 2–3 `notch_rock`
   și `heart_rock` (în **apa golfului, la 30–50 m dreapta**, `[golf]`).
9. **Digul e îngust: 3,5 m umăr stânga, 4–17 m dreapta.** La 0.88–0.92 stânga apă la
   **10–14 m**, dreapta la **10–24 m**; `custom_ravines` 3 (adânc 6, ambele laturi).
   Cei 42 de tetrapozi provizorii stau la **11,5–16 m STÂNGA**, adică chiar la
   marginea apei (nod − teren +1,5…+2,4 m: stau pe fundul de apă la 0.89–0.93).
   **Tetrapozii noi stau pe stânga, doar pe 0.84–0.96.** Pe A nu există dig: marea
   e la 66–72 m.
10. **Pod ↔ dig: 165 m, nu 124 m**, iar între ele e golful; fiecare capăt al podului
    are apă pe ambele laturi de la 2 m de axă (viaductul), apa golfului pe dreapta,
    larg pe stânga la 0.62 (50 m) și 0.70 (86 m). Terenul **sub nodul `PodMobil`**
    e −5,1 m (apă), nodul stă la +8,5 (traveea): corect.
11. **Zidurile provizorii ale lui D nu sunt gusuku-ul final.** 11 `Gusuku*` drepte la
    9,2–9,6 m de axă (≈ 3 m de marginea asfaltului la semi 6,0), pe **ambele laturi**
    alternat; unul intră **0,51 m peste asfalt** (`Wall_Limestone` la (21, −243)).
    Zidurile curbe (`gusuku_wall_curve`) vin pe curbă, la ≥ 6 m de margine.
12. **Tromba e pe drum, nu în apă.** Marker la (397,2; 330,3), +3,0, 0,7 m de axă
    (terenul +2,6): pâlnia „iese din mare” e problema `TyphoonHazard` (cod), nu a
    decorului; decorul de lângă ea (apă la 20–22 m stânga) nu are voie să taie
    traseul ei de rătăcire (§G).
13. **Scatterul vechi e încă activ pe Track20**: 36 `coconut_palm` + 14
    `beach_palm_bent` + 8 `banyan` + 10 `pandanus` + 95 `hibiscus_bush` (+ 436
    `island_scatter`, 111 `coral_rock`) vin din temă (copie de `island`, în
    `track08.gd`). Scoaterea cocotierilor din tema `okinawa` e o decizie de
    **integrare** (coordonator, `track_decor.gd` nu e al constructorilor); până atunci
    capturile vor avea palmieri ai căror loc îl iau fukugi/fan_palm.
14. **Hazardele cu ceas dau toată linia de bază a ProbeRace.** Cele 47 de repuneri,
    11 `[blocaj]` și 11 ejectări sunt între 0.635 și 0.672: intrarea pe pod cu
    traveea ridicată. Nu se „repară” din decor (e mecanica: oprire); decorul **nu are
    voie să adauge nimic** în afara ei.

## Fapte din fundație și montare (PR #467, #470, main 02d1fdbb)

- **Kitul e plasabil:** 36 GLB în `assets/models/okinawa/` (buildings, structures,
  rocks, plants, props, animals, vehicles, effects), clase `ok_limestone`, `ok_roof`
  (clasă nouă, `roof_tiles` e partajată), tente pe atlas `atint:` (`ok_lacquer`,
  `ok_leaves`, `ok_bloom`); 24 de materiale pe pistă (28 cu tot kitul). **Nu comite
  niciun `.glb.import` regenerat local** (memoria `textura-noua-import-mipmaps`).
- **Piese montate acum în `DecorManual`:** `Dig_tetrapozi/Tetra00–41` (42, provizorii,
  stânga digului), `Ziduri_D/Gusuku00–10` (11 module drepte provizorii),
  `Far_capul_E` (0.5166, 54 m stânga), `Poarta_D` (0.4298, peste drum, cu
  `camera_blocker`). Le las unde sunt (mutarea în zona lor ar rescrie noduri existente
  într-un `.tscn` care nu se rescrie): **`Dig_tetrapozi` → ZonaH, `Ziduri_D` și
  `Poarta_D` → ZonaD, `Far_capul_E` → ZonaE** la prima atingere a POI-ului respectiv
  (constructorul le mută cu `reparent` în scena lui și raportează).
- **Zonele goale `ZonaA … ZonaH`** sunt în `Track20.tscn` sub `DecorManual`
  (`metadata/fractii` = fracțiile reale de mai sus). **Nu s-au pus `ext_resource`-uri
  noi în antet**: kitul se referă la `res://assets/models/okinawa/...` din `.tscn` al
  POI-ului; dacă doi constructori adaugă linii în antet apar conflicte garantate. De
  aceea: **fiecare constructor adaugă `ext_resource`-urile lui în blocul propriu,
  cu `id` prefixat de litera zonei** (`a_…`, `b_…`), iar coordonatorul rezolvă
  mecanic la integrare (concatenare). Excepții scrise: **C** poate adăuga în
  `custom_*` doar prin coordonator; hazardele (`Hazarduri/*`) și proprietățile
  rădăcină (`custom_ravines`, `custom_lagoon`, `custom_width_segments`) nu se ating.
- **Relief:** terenul urmărește drumul (plat lateral ±50 m, apoi cade la mare), cornișa
  E (`custom_ravines` 0), viaductul (rapa 1), plaja G (rapa 2), digul (rapa 3), golful
  (`custom_lagoon`). **Treptele de piatră nu sunt teren.**
- **Stare la oprire a kitului** (`okinawa_inventory.md`): `limestone_cliff_module`(`_b`)
  **provizorii** (citesc bazalt columnar): **E se decide fără ele sau cu ele marcate
  provizoriu**; `ryukyu_gate` golul 14,35 × 6,20 m; feribotul `island_ferry` (varf 11,0 m,
  `ship_model`/`ship_node` în `PodMobil`); **fukugi în tunelul B la pas 3,0–3,2 m** (la
  3,5 m rămâne un gol de ~0,5 m la sol); **`bougainvillea` cu `coliziune = "none"` pe
  instanță** (rămâne magenta prin tenta `ok_bloom`, nu prin slotul 31); casele Ryukyu
  A/B/C, `concrete_house_a/b`, `harbour_quay`, `bus_stop_shelter`, `vending_machine`,
  `convex_mirror`, `fishing_net_rack` (slab, prop mic), `water_buffalo`, `egret`,
  `coastal_freighter`, `fishing_boat` sunt acceptate. Build-ul complet NU reproduce piesele
  revizuite (RNG de modul): GLB-urile comise sunt cele bune, **nu rula build-ul complet**.
- **Orizontul:** `okinawa_horizon.glb` (4/4 siluete, 0 cu degajare relaxată).
- **Cifrele de plecare** (scena de azi) sunt în tabelul gărzilor de mai sus.

## Piesele refolosite din kitul vechi (Track08)

`tetrapod` (1,8 / 3,5 m, **scalat 1,4–1,8×**, gri-deschis, doar H), `pandanus` (2,4 m,
**~1,6×**, plaja G și mal), `banyan` (5,6 m, **~1,6×**, sat/A și B), `hibiscus_bush`
(0,9 m, accent roșu), `sugar_cane_clump` (2,8–3,6 m, C), `sabani_boat` (5 m, port și
plajă), `beach_clutter` (lăzi, flotoare, port și plajă), `shisa_statue` (perechea de
la intrarea în sat, ~1,5×, cu gura deschisă/închisă), `sea_turtle` (animat, **decor
pe plajă G, nu pe drum**), `sea_wall_segment`, `wave_surge`/`typhoon` (cod, nu decor).
Scoase: `coconut_palm`, `beach_palm_bent` (câțiva `coconut_palm` doar lângă port, A),
`stone_gate_torii`, `tall_ship`, `fence_ranch`, `lighthouse` roșu-alb, `gusuku_wall` vechi.

## Contractele per POI

Fiecare: **ce se vede în decupaj** (obligația vizuală) + **cifre alocate** (din
brief §9: numărătorile din prompt, rotunjite pe lungimea reală) + **piesele** + **ce e
lateral** (măsurat) + **densitatea lângă drum** pe benzi (distanță de la MARGINEA
asfaltului: 0–10 / 10–30 / 30–60 m) + **ce e interzis** + **gărzile** + **capturile**.

### Reguli comune

- **Banda liberă:** nimic cu coliziune la < 2,5 m de MARGINEA asfaltului;
  ProbeLaneClear cere banda (semilățime + 0,5 m) liberă. Nimic cu prag > 0,3 m pe
  bandă (memoria `suprafete-cu-goluri-si-praguri`). Semilățimea: **A/C/E/G 7,0, B 5,5,
  D 6,0, F/H 6,5**.
- **Gabaritul camerei:** camera stă 10 m sus, 12,5 m în spate; ce trece peste drum
  (poarta) cere golul măsurat ca GOL, pe gabaritul caroseriei și al camerei (memoriile
  `cota-de-contract-se-masoara-ca-gol`, `golul-se-masoara-pe-fereastra-lui`). Înălțimea
  vizibilă la distanța d e 10 + 0,092·d m peste cota drumului.
- **Orientarea:** în kit „fața” = +Y Blender = −Z Godot (casele cu fața pe +Y,
  măsurată pe goluri); derivă rotația cu produs scalar, nu o ghici (memoria
  `rotatii-in-builder-semnul`); azimutul Blender↔Godot (memoria `azimut-blender-vs-godot`).
- **Piese în masă:** peste ~1000 de piese **MultiMesh feliat**, nu noduri (memoria
  `decor-in-masa-cere-multimesh`); `DecorManual` = piesele hero și primul rând cu
  coliziune; vegetația în masă (fukugi, trestie, flori) în MultiMesh. Costul
  vegetației: piese = lungime/pas, apoi probe (memoria `vegetatie-cost-pe-pas`).
  Instanțele MultiMesh nu se citesc în `--headless`: verifică pe captură/`ProbeMasca`.
- **Generator de .tscn din cod pe teren real** (memoria `decor-manual-din-cod`):
  `DecorManual` e sursa de adevăr, nu codul; piesele sunt noduri în `.tscn` pe tot
  parcursul, cu `_terrain_mesh_y` pentru cotă (memoria `terrain-mesh-y-extrapoleaza`:
  nu aseza pe extrapolare); corpul fizic vine automat din `world_prop`
  (`decor-manual-coliziune`: `probe_solid` plimbă gabaritul). Un `.tscn` editat de
  mână nu se rescrie din cod (memoria `tscn-editat-de-mana-nu-se-rescrie`): verifică
  `git status` înainte; editorul Godot deschis rescrie `.tscn` (memoria
  `editor-godot-deschis-rescrie-tscn`); comentariile `#` între proprietăți taie
  parserul.
- **Aranjamentul bate numărul** (memoria `aranjamentul-bate-numarul`): nu grilă,
  jitter ≥ 0,5 din pas, yaw variat, grupări de 2–3, densitate care **crește spre drum**;
  floarea (bougainvillea/hibiscus) **doar în petice**, accentul viu.
- **Materiale:** ≤ **30** pe pistă (brief §6; azi 24; garda pică la 38); piesele kitului
  folosesc clasele din temă; tenta de clasă se decide la integrare (memoria
  `tenta-de-clasa-se-decide-la-integrare`). Un asset nu aduce niciodată texturi proprii
  (CLAUDE.md).
- **Nimic peste asfalt** (`probe_decor_overlap` 0, cu excepția liniei de bază de la D),
  nimic îngropat în altă piesă (regula de 55 % din cutie).
- **Capturi serial** (lacătul de GPU), **gărzi în paralel**; copiază
  `snapshots/okinawa_joc.png` după fiecare.
- **Interdicții de conținut** (brief §8): fără utaki, kamekobaka, memoriale, militar,
  ceremonii, oameni în costum; fără mărci sau text lizibil; fără cocotier ca peisaj
  dominant; fără torii, pagode, cireși.
- **Nu atinge** GLB-uri, `.glb.import`, `track.gd` / `track_decor.gd` / `track08.gd`,
  traseul, `Hazarduri/*`, `custom_*` din rădăcină.
- **Plafonul de proprietate:** doar nodurile din zona proprie (+ mutarea pieselor
  provizorii din tabel).

### A — Portul și satul (0.974–1.000 + 0.000–0.1023; semi 7,0)

Din decupaj (`A`, `A_port`, `A_iter1`, `ORIZONT`): **25–30 de case Ryukyu** joase cu
olane roșii și mortar alb, **shisa pe creastă**, fiecare în **zid de corali** cu
paravan *hinpun*; **8–10 case de beton** albe/pastel cu **rezervor rotund** și rufe;
**palmieri evantai** doar lângă port; **hibiscus și bougainvillea** peste ziduri;
**cheiul de beton cu scări** în bazinul portului, **6–8 bărci** (`fishing_boat`,
`sabani_boat`), plase, flotoare, lăzi; **2–3 automate** fără text, **adăpost de
autobuz**, **oglindă convexă** la colțuri; **pereche de shisa mari** la intrarea în sat;
banian mare în sat (reper); `ORIZONT`: conul Iejima.

Lateral (măsurat): **dreapta (N) uscat până la +100 m**, teren +3,5…+5,8 m la 100 m
(satul se așază în rampa spre interior, la +10…+60 m, plat −0,3 m); **stânga (S) plat
−0,3 m, apa la 66–72 m [larg]**: o fâșie de 60 m între drum și mare (plajă, bărci
trase pe nisip). Portul (golful) e în V al golfului, la colțul 0.9747 și înainte
de grilă (§Premise 3): cheiul se așază acolo (≈ (100–125, 150–170)), nu pe A propriu-zis.

Cifre alocate: 26 case Ryukyu (a/b/c amestecate), 9 case de beton, 1 quay + 7 bărci,
10 `fan_palm` (doar în port, la ≥ 30 m de axă), 2 `vending_machine`, 1 `bus_stop_shelter`,
3 `convex_mirror`, 2 `fishing_net_rack`, 1 banian (≥ 12 m de axă), 40 hibiscus, 20
bougainvillea (în petice), 1 pereche shisa la intrare. **Cocotierii din scatter sunt
scoși la integrare (§Premise 13).**

Piese: `ryukyu_house_a/b/c`, `concrete_house_a/b`, `harbour_quay`, `fishing_boat`,
`bus_stop_shelter`, `vending_machine`, `convex_mirror`, `fishing_net_rack`, `fan_palm`,
`coral_stone_wall`, `bougainvillea`, `hibiscus_bush`, `banyan` (kit vechi), `shisa_statue`
(vechi), `sabani_boat`, `beach_clutter`. Coliziune: casele `hull`, plantele `none`/`trunk`
(tabel `PROP_COLLISION`).

Densitate: **0–10 m:** `coral_stone_wall` (joasă, la ≥ 2,5 m de margine), flori, mici
recuzite; **10–30 m:** primul rând de case (fațada spre drum), `hinpun`, palmieri,
automate, adăpost; **30–60 m:** al doilea rând de case de beton, banianul, cheiul, trestia
din C se vede în spate. Nimic mai înalt de 8 m în afara banianului și a caselor.

Interzis: **grila (0.000, (35, 165)) liberă pe 30 m în față și 15 m lateral**; nimic
cu coliziune pe banda de start; **fără dig / tetrapozi pe A** (apa e la 66 m); fără cocotieri
ca peisaj; **corpurile cinematice atribuite aproape de grilă** (memoria
`corp-cinematic-aparut-in-masina`; bărcile statice, nu `AnimatableBody3D`); nimic
în **culoarul de lansare al grilei**. Pe A **nu se pune** pod/dig/tetrapozi.

Gărzi: ProbeLaneClear (baza 4), probe_solid, probe_manual, probe_decor ≤ 30 (azi 24),
probe_decor_overlap (baza 1 = zidul lui D), ProbeCameraSolid (baza 1 la 0.672),
ProbeRace `--slice=0.974,1.0` + `--slice=0.0,0.1023` (16 seed-uri; baza: 0 repuneri,
pre-grila nu se judecă). Capturi: 0.960, 0.985, 0.000, 0.020, 0.060, 0.095 vs `A` +
`A_port` + `A_iter1`, cu `ORIZONT` la 0.985.

Capcana: memoria `munte-flanc-nu-fundal` nu se aplică (nu e masiv); `ceata-in-familia-solului`
(în familia mării).

### B — Aleea de fukugi (0.1023–0.205; semi 5,5; `custom_dirt_ranges` 0.103–0.203)

Din decupaj (`B`): **aleea de nisip coraligen crem** (nu asfalt) între **două ziduri
joase de corali**, **șiruri dese de fukugi** pe ambele laturi, **coroane care se
închid** (tunelul, lumină pătată), case în spatele zidurilor, flori în petice,
petice de plajă și apă în stânga (în dioramă; în joc apa e la 72–86 m).

Lateral (măsurat): **plat −0,3…−0,5 m pe ±50 m**; stânga **apa la 72–86 m [larg]**
(la 0.17 și 0.20 la 86 și 82 m); dreapta uscat, +1,2…+4,4 m la 100 m.

Cifre alocate: **150+ fukugi** pe tot jocul (≈ 70 pe B): **2 rânduri pe fiecare latură, la
pas 3,0–3,2 m**, primul rând la **~10 m de axă** (4,5 m de margine; coroanele de 2,8–3,0 m
se închid deasupra), al doilea la ~13 m, jitter de poziție ≤ 0,3 m ca să rămână tunel, nu
grilă; 3 variante `fukugi_tree_a/b/c` în amestec; **`coral_stone_wall` joasă la ~8,0 m de axă**
(2,5 m de margine, între aleea de nisip și primul rând de fukugi), pe ambele laturi; 4 case
Ryukyu în spatele zidului; 12 petice de bougainvillea (nu aliniate); 1 `convex_mirror` la
șicană (0.18); `egret` doar în C. **Șicana (0.1803, viraj −34°) rămâne liberă.**

Piese: `fukugi_tree_a/b/c` (7,1 / 8,5 / 5,4 m înălțime; Ø 2,8–3,0 m), `coral_stone_wall`,
`ryukyu_house_*`, `bougainvillea`, `convex_mirror`, `cycad`. Coliziune: `fukugi` `trunk`,
zid `hull` jos.

Densitate: **0–10 m:** fukugi la 3,0–3,2 m (rând dublu), zidul de corali, aleea; **10–30 m:**
a doua linie (cicade, bougainvillea, case); **30–60 m:** cornul de pe dreapta (rampa spre
interior), în stânga iarbă plată și marea (în ceață).

Interzis: **nimic mai aproape de 3,0 m de margine cu coliziune** (aleea de 11 m e
îngustă: ProbeRace aici = zona de `[blocaj]`; baza 0); fără arbori care taie linia ProbeRace
(7 m între coroane în axă la ≥ 3,0 m deasupra solului: coroana la 6+ m e deasupra
camerei; verifică ProbeCameraSolid); fără ienupăr/chiparos (iter1 le are: defect); aleea
rămâne **nisip** (nu se acoperă cu asfalt/iarbă); **cocotieri nu**.

Gărzi: **ProbeRace `--slice=0.1023,0.205` pe 16 seed-uri înainte și după, cu `[blocaj]`
citit** (alee de 11 m cu zid + fukugi `trunk`; baza 0), ProbeLaneClear, probe_solid,
ProbeCameraSolid (coroane la 6–8 m deasupra: camera la 10 m trece pe deasupra), ProbeBuried,
probe_decor ≤ 30, probe_decor_overlap, probe_manual. Capturi: 0.105, 0.140, 0.170, 0.195 vs
`B` (tunelul din dioramă; **forma de coloană**, nu bile).

Capcana: memoriile `benzi-vertex-color-bisect`, `adancimea-siluetei-nu-fata-piesei`;
la pas 3,0–3,2 m „din axă citește perete” dar din 3/4 lateral rămâne șir de coloane
(abatere declarată a kitului: nu e a decorului).

### C — Trestia și urcarea (0.205–0.333; semi 7,0)

Din decupaj (`C`, `C_iter1`): **panouri late de trestie verde-gălbuie** în rânduri, în
trei câmpuri separate de **ziduri joase de piatră** și poteci (iter1; în joc **o singură
bucla**, deci potecile nu se iau), **egrete albe**, **bivol de apă**, banian/fukugi
în margine, flori, casele cu rezervor în fundal-stânga, drum care urcă pe margine.

Lateral (măsurat): **plat −0,1…−0,5 m pe ±25 m, apoi −0,5…−1,1 m la 50 m, −1,6…−4,5 m la
+100 m dreapta (interior)**; stânga **apa la 86–100 m [larg]**. Panta drumului 5–8 %,
deci trestia **nu urcă lateral**: urcă drumul (§Premise 1); câmpul de trestie se așază
**în interiorul buclei, pe dreapta, la 8–60 m, la cota drumului sau mai jos** (nu „pe un deal
peste drum”).

Cifre alocate: **3 câmpuri de trestie** (≈ 60 m × 40 m, panouri de `sugar_cane_clump` /
`cane_clump` instanțiate MultiMesh), 2 `egret` (la ≥ 15 m de axă), 1 `water_buffalo`
(≥ 20 m), **12 pini Ryukyu** distribuiți pe C–D (nu pe bandă), 25 `cycad`, ziduri joase
`coral_stone_wall` ca limită de câmp (nu poteci), 6 petice de hibiscus. Castelul (palatul
+ poarta) trebuie să **apară în parbriz de la 0.215**: **ceața lasă palatul întreg din
0.210** (`fog_end` 350; fereastra palatului 0.210–0.390), deci nimic > 14 m în axa spre
palat între 0.20 și 0.33.

Piese: `sugar_cane_clump` (kit vechi; 2,8–3,6 m, MultiMesh), `water_buffalo`, `egret`,
`ryukyu_pine`, `cycad`, `coral_stone_wall`, `hibiscus_bush`. Coliziune: trestia `none`
(nu coliziune; se trece prin ea doar dacă iese pe bandă — nu are voie), pinii `trunk`.

Densitate: **0–10 m:** margine de trestie (fără coliziune la < 2,5 m), tufe; **10–30 m:**
primul panou (dreapta), pini rari, hibiscus; **30–60 m:** panourile mari, zidul de câmp,
bivolul.

Interzis: **nimic care ascunde palatul** (axa spre (110, −285) între 0.215 și 0.33); trestie
pe banda de 7,5 m; ziduri paralele cu drumul la < 6 m (perete paralel nu se vede,
memoria `perete-paralel-nu-se-vede`); **o singură bucla**, fără poteci; fără dealuri
artificiale.

Gărzi: ProbeRace `--slice=0.205,0.333` (16 seed-uri, baza 0), ProbeLaneClear, probe_decor
≤ 30, probe_decor_overlap, probe_manual. Capturi: 0.215, 0.260, 0.300, 0.325 vs `C`, `C_iter1`.

Capcana: `vegetatie-cost-pe-pas` (câmpuri = mii de instanțe: MultiMesh feliat);
`aranjamentul-bate-numarul` (panouri cu margini neregulate, nu dreptunghiuri).

### D — Castelul și poarta (0.333–0.474; semi 6,0)

Din decupaj (`D`, `D_poarta`, `ORIZONT`): **ziduri curbe de calcar gri-crem** cu colțuri
rotunjite, 6–10 m înălțime, care șerpuiesc pe creastă; drumul în **S-uri** la baza lor; **pini
Ryukyu răsuciți** cu coroane turtite pe platou; **palatul roșu** pe platformă de piatră
(două nivele, olane cu mortar alb, ornamente aurii); **poarta lăcuită roșie** cu acoperiș în
două trepte. Poarta în dioramă e pe un drum lateral: **doar materia se ia**.

Lateral (măsurat): **plat la cota drumului (−0,3…−0,9 m) pe ±50 m**; **stânga apa la
100–110 m [larg]**; **dreapta (interior) −5,0…−12,9 m la +100 m** (platoul se rupe în
interior). Palatul (110, −285) e la 26 m stânga (pe plat); poarta și palatul sunt vizibile
din C și de pe dig (0.87–0.97, peste golf). Culmea la **0.4045**, +30,03.

Cifre alocate: **palatul** (`ryukyu_palace`, 16 m) la ~ (110, +30, −285) pe platformă
(cota terenului +29,7), **poarta rămâne `Poarta_D`** (0.4298; nu o muta), **ziduri
`gusuku_wall_curve`/`straight`/`gusuku_arch_gate`** pe ~280 m de culme (≈ 20 module,
înlocuiesc cele 11 `Gusuku*` provizorii), **12–15 `ryukyu_pine`** (2–3 la 6–10 m de zid),
2 `gusuku_arch_gate` (în zid, nu peste drum), `shisa_statue` pereche la poartă (≈ 1,5×, pe
socluri la 8 m de axă, în afara golului de 14,35 m).

Piese: `ryukyu_palace`, `gusuku_wall_curve` / `_straight`, `gusuku_arch_gate` (gol 5,45 ×
5,5 m, abatere decisă), `ryukyu_pine`, `shisa_statue`, `notch_rock_*` (colț de platou),
`coral_stone_wall`. Coliziune: zidurile `mesh`/`hull` (probe_solid obligatoriu), palatul `hull`.

Densitate: **0–10 m:** nimic cu coliziune la < 2,5 m (zidul la ≥ 6 m de margine, nu 3 m
ca cel provizoriu); **10–30 m:** zidul curb (peretele care se simte), pini; **30–60 m:** al doilea
rând de zid, palatul, pini mari.

Interzis (bandă liberă, gabarit, coliziuni): **golul porții 14,35 × 6,20 m liber** (nimic
în 8 m de axă pe ±8 m); **nu se mută `Poarta_D`** și nu se scoate
`metadata/camera_blocker`; **datoria lui D: scoate `Wall_Limestone` de 0,51 m peste
asfalt** (zidul provizoriu Gusuku03/04 la (21, −243)); zidul nu strânge drumul sub 12
m între fețe; fără utaki/ceremonii (palatul e monument); fără drum lateral spre poartă;
**relieful** (platoul) nu se schimbă (ieșirea (c)).

Gărzi: **ProbeRace `--slice=0.333,0.474` pe 16 seed-uri înainte și după** (S-uri cu zid
`mesh`/`hull`: aici apar blocajele), ProbeLaneClear, **probe_solid** (zidurile lângă bandă),
probe_decor_overlap (trebuie să ajungă la 0), probe_manual, ProbeBuried, **ProbeCameraSolid**
(poarta 14,7 m > camera 10 m: zona de cameră sub poartă; zidurile la ≥ 6 m), probe_decor ≤ 30.
Capturi: 0.345, 0.380, 0.415, 0.4298, 0.455 vs `D`, `D_poarta`.

Capcana: memoriile `adancimea-siluetei-nu-fata-piesei`, `perete-paralel-nu-se-vede`
(zidurile laterale nu se văd pe cadru: contează cele din față, la 0.339 și 0.4737),
`azimutul-soarelui-fata-de-drum` (D e luminat din spate: poarta luminată din față).

### E — Capul și cornișa (0.474–0.612; semi 7,0)

Din decupaj (`E`): **faleză de calcar gri-crem** cu tufe verzi, **stânci-ciupercă** (`notch_rock`)
roase la bază de val, **farul alb** pe vârful capului, drumul pe buza falezei **fără parapet**,
**marea albastră dedesubt**; pini Ryukyu rari pe terasa de sus.

Lateral (măsurat): pe 0.474–0.545 **stânga plat la cota drumului, apa la ~98 m**; pe
**0.55–0.61 apa la 12 m** (cădere 15–30 m); **dreapta plat −0,3…−0,6 m la 10–50 m**.
Farul stă la **54 m STÂNGA** (0.5166), pe teren, **înaintea** căderii; în cadru pe 0.335–0.490
(§Premise 6).

Cifre alocate: **10–14 `notch_rock`** pe tot jocul, din care **3–4 la baza cornișei**
(0.55–0.61, în apă la 20–40 m stânga, `notch_rock_a/b/c`); `cape_lighthouse` rămâne (54 m
stânga, 0.5166); **8 pini Ryukyu** pe terasă; 6 petice de tufe; `limestone_cliff_module` **doar
dacă** capturile îl justifică, marcat provizoriu (citește bazalt). Cornișa se face din
`custom_ravines` (relief), nu din decor.

Piese: `notch_rock_a/b/c` (8–9 m, `hull`), `cape_lighthouse` (existent), `ryukyu_pine`, `cycad`,
`limestone_cliff_module(_b)` provizorii, `coral_rock` (scatter). Coliziune: stâncile `hull`.

Densitate: **0–10 m:** nimic cu coliziune pe stânga la < 2,5 m (căderea); iarbă/tufe; **10–30 m:**
tufe, pini, la baza cornișei stânci în apă; **30–60 m:** farul (stânga), terasa, pinii.

Interzis: **nimic pe dreapta la < 14 m lateral de la 0.55** (căderea e stânga; `PlasaCornisa`/
repunerea acoperă marginea); **nimic care atinge traseul lui `PlasaCornisa`**; farul nu se
mută pe apă; **nu se schimbă rapa/relieful** (cere „faleză reală” → **(c)**); nimic care
ascunde podul din 0.55–0.61 (canalul și vaporul de la +22 m în jos, telegraful vizual al
podului, brief §2.0).

Gărzi: **ProbeRace `--slice=0.474,0.612` pe 16 seed-uri** (baza: **0 repuneri** pe E; ejectările
„perete” sunt la 0.666/0.672, în F), ProbeLaneClear, ProbeBuried (cornișa), probe_solid,
probe_decor ≤ 30, probe_manual (farul pe teren real), ProbeCameraSolid. Capturi: 0.490, 0.520,
0.545, 0.575, 0.605 vs `E` (deja 0.560 în `poi_baza/`).

Capcana: memoriile `umarul-ingust-ascunde-caderea` (verifică **unghiul** căderii din camera de
joc, nu adâncimea), `masoara-inainte-nu-langa` (farul stă înainte, nu lateral), `perete-paralel-nu-se-vede`.

### F — Coborârea și podul (0.612–0.737; semi 7,0 → 6,5 pe pod)

Din decupaj (`F`): **doi piloni de beton subțiri**, **traveea ridicată**, **feribotul alb cu
două punți** pe canal, **apa turcoaz a golfului**, stânci pe mal, drumul care coboară spre pod.
În dioramă feribotul e între piloni; în joc e `PodMobil` (`island_ferry`, vârf 11,0 m).

Lateral (măsurat): **apă pe ambele laturi de la 2 m de axă pe pod (0.6365–0.7018)**: golful pe
dreapta, largul pe stânga; la **0.62** apa la 50 m stânga / 36 m dreapta; **0.70–0.72**: apa la
82–86 m stânga, 32–34 m dreapta. Terenul sub traveea e −5,1 m (apă). Pod ↔ dig 165 m.

Cifre alocate: **`coastal_freighter`** în larg (1, decor, **la ≥ 200 m**, pe inelul de fundal, nu
pe canal), 2 `notch_rock` la capătul de V al podului (în apă, pe stânga, 0.62), **mal de
calcar** cu 1–2 pini, flori; rampa de acces (0.62–0.6365) cu `coral_stone_wall` la ≥ 6 m de
margine; **traveea, pilonii și feribotul sunt cod/kit montat — nu se ating**.

Piese: `notch_rock_*`, `coastal_freighter`, `coral_stone_wall`, `ryukyu_pine`, `fan_palm`,
`bougainvillea`. Coliziune: stâncile `hull`.

Densitate: **0–10 m:** nimic pe pod; **10–30 m:** mal cu pini și stânci în apă; **30–60 m:**
stânci, freighterul la distanță.

Interzis: **nimic pe pod, nimic în culoarul feribotului/canalului** (`PodMobil`: water_half 26,
bank 20, reach 100); **ProbeLaneClear rămâne 4** (rampa și traveea sunt linia de bază);
**ProbeCameraSolid rămâne 1** (0.672–0.678); piesele noi lângă `RampNear/RampFar/LiftSpan` cer
`--slice=0.612,0.737` înainte și după; fără vapoare noi pe canal; **nu se ating**
`custom_ravines` 1, `PodMobil`.

Gărzi: **ProbeRace `--slice=0.612,0.737` pe 16 seed-uri** — **baza = toată linia de bază a pistei**
(47 repuneri, 11 blocaje, 11 ejectări, toate 0.635–0.672); decorul adaugă **zero** (comparați pe
distribuții, memoria `proberace-nedeterminism`), ProbeLaneClear (4), ProbeCameraSolid (1),
probe_solid, ProbeBuried, probe_decor ≤ 30. Capturi: 0.625, 0.650, 0.667, 0.690, 0.715 vs `F`;
cu `--bridge-at=` (traveea sus + feribotul sub ea) pe 0.650–0.667.

Capcana: memoriile `reperul-se-vede-pe-patru-axe`, `golul-se-masoara-pe-fereastra-lui`,
`garda-circulara-propria-functie` (sonda vs propria funcție a hazardului = 0 prin construcție).

### G — Insula mică și tromba (0.737–0.824; semi 7,0 → 6,5)

Din decupaj (`G`, `G_tromba`): **plajă de nisip alb-crem**, **pandanus** cu rădăcini aeriene (nu
cocotieri), stânci de calcar și bolovani în **apă turcoaz puțin adâncă**, drumul de plajă în curbă,
**o singură stâncă-inimă** în apa golfului, broasca țestoasă pe nisip, peretele de furtună în
spate, tromba ca pâlnie gri-albă (hazard din cod).

Lateral (măsurat): **fâșie de ~50 m**: apa la **20–22 m stânga [larg] și 28–32 m dreapta [golf]**
(0.76–0.78); la 0.74 stânga apa la 78 m; la 0.80–0.82 stânga 58–68 m, dreapta 26–28 m.
Terenul e nisip plat −0,3…−1,2 m. Marker-ul trombei (0.7758) e pe drum (+3,0).

Cifre alocate: **30 pandanus pe tot jocul** (≈ 12 pe G, grupate de 3–4, la ≥ 6 m de
margine), **5–6 `notch_rock`** în apa de lângă plajă (la 12–40 m, ambele laturi), **1
`heart_rock`** în apa golfului (dreapta, 30–50 m, `[golf]`), **2 `sabani_boat`** trase pe
nisip, 1 `sea_turtle` pe plajă (≥ 10 m, animat), `beach_clutter` (6), `egret`, tufe de
`hibiscus_bush`.

Piese: `pandanus` (kit vechi, ~1,6×), `notch_rock_a/b/c`, `heart_rock`, `sabani_boat`,
`sea_turtle`, `beach_clutter`, `cycad`, `coral_rock` (scatter), `fan_palm` (cel mult 2,
spre pod). Coliziune: stâncile `hull`, pandanus `trunk`.

Densitate: **0–10 m:** scatter existent (iarbă de plajă, lemn de apă); **10–30 m:** pandanus,
stânci joase, bărci; **30–60 m:** `heart_rock`, stâncile în apă.

Interzis: **cercul de rătăcire al trombei** (`TyphoonHazard`, 11 s dus-întors pe 0.76–0.78):
nimic cu coliziune pe ±20 m de axă pe 0.755–0.80; **nimic pe banda de 7,5 m**; **cocotieri nu**;
**a doua stâncă-inimă nu**; **fără utaki/kamekobaka**; pâlnia trebuie să pară că iese din mare:
decorul **nu o acoperă**; tromba rămâne vizibilă de pe pod (în cadru **0.350–0.360, 0.470–0.745**;
pe pod e drept în față, la 140–310 m).

Gărzi: **ProbeRace `--slice=0.737,0.824` pe 16 seed-uri** (baza: **0 repuneri, 0 blocaje** în G),
ProbeLaneClear (4), probe_solid, probe_decor ≤ 30, probe_decor_overlap, probe_manual.
Capturi: 0.745, 0.765, 0.775 (cu `--typhoon-at=`), 0.800, 0.820 vs `G`, `G_tromba`.

Capcana: memoria `amprenta-hull-nu-raza-nominala` (hull-ul e mai mare decât raza nominală — pe
o fâșie de 15 m laterali contează); `celula-de-apa-plana-peste-mal` (stânci în apă sortate după
AABB); `strop-apa-particule`.

### H — Digul, tetrapozii și valul (0.824–0.974; semi 6,5)

Din decupaj (`H`, `H_val`): **tetrapozi mari de beton gri-deschis** pe partea dinspre larg (în
dioramă pe tot frontul; în joc doar pe 0.84–0.96), **hula albastră cu creste albe fațetate**,
**valul** care trece peste șosea în spumă, golful turcoaz calm pe dreapta, `coral_stone_wall`
joasă pe marginea dinspre golf, bărci/cheiul (spre capăt).

Lateral (măsurat): **stânga apa la 10–14 m [larg]** (0.88–0.92), **dreapta apa la 10–24 m
[golf]**; la 0.84 stânga 56 m, la 0.96 stânga 76 m. **Umăr de 3,5 m stânga, 3,5–17 m dreapta**
(semi 6,5). Valul (0.8811) e pe drum; cota drumului +1,6 (cel mai jos punct al pistei).

Cifre alocate: **60+ tetrapozi** (acum 42 provizorii, kit vechi 1,8 m, **scalat 1,4–1,8×**, gri-deschis
`concrete`), pe **stânga, la 8–14 m de axă, doar pe 0.84–0.96**, în 2–3 straturi (nu un șir), cu
spuma (particule cu limită de count) la baza lor; `coral_stone_wall` pe dreapta (golful), 6
`notch_rock` în larg (≥ 25 m stânga), **fără cocotieri**; capătul dinspre port: `harbour_quay`
(în A), nu aici.

Piese: `tetrapod` (kit vechi, scalat), `notch_rock_*`, `coral_stone_wall`, `sea_wall_segment` (vechi),
`fishing_net_rack`. Coliziune: tetrapozii `hull` (deja), zidul `hull` jos.

Densitate: **0–10 m:** `coral_stone_wall` joasă pe dreapta (≥ 2,5 m de margine), nimic pe
stânga; **10–30 m:** tetrapozii (stânga, la 8–14 m, **dincolo** de umărul de 3,5 m), spuma; **30–60
m:** stâncile din larg, hula.

Interzis: **nimic cu coliziune la < 2,5 m de margine** (umăr stânga 3,5 m: tetrapozii la ≥ 6 m
de margine); **valul (0.8811) trece pe toată lățimea**: nimic care se interpune între larg și
șosea pe 0.86–0.90 în afară de tetrapozii deja acolo (valul vine din SV, dinspre larg, nu dinspre
golf); **fără dig pe A**; tetrapozii nu se mută pe dreapta; **relieful** (rapa 3, digul) nu se
atinge (**(c)** dacă se cere „dig mai lat”).

Gărzi: **ProbeRace `--slice=0.824,0.974` pe 16 seed-uri înainte și după** (baza: **0 repuneri,
0 blocaje**), ProbeLaneClear (4), probe_solid (tetrapozii `hull`), probe_decor ≤ 30, probe_manual
(tetrapozii „ok”: nod − teren +1,5…+2,4 m — **stau pe fundul de apă la 0.89–0.93**, trebuie
reașezați pe terenul real), probe_decor_overlap, ProbeCameraSolid. Capturi: 0.840, 0.870,
**0.881 cu `--wave-at=`**, 0.920, 0.955 vs `H`, `H_val`.

Capcana: memoriile `umarul-ingust-ascunde-caderea` (apa la 10 m), `strop-apa-particule`,
`apa-iluminata-v12` (spuma în contralumină).

## Bucla oarbă

1. Constructorul (Sonnet, memoria `coordonator-fable-constructori-sonnet`) lucrează în
   `D:/GameDev/wt-ok-poi-<x>` pe `okinawa/poi-<x>`, plecat din vârful ramurii după merge-ul
   fundației (`okinawa/poi-bara`); `--import` la creare; comite după fiecare pas care trece o
   gardă; **prima rundă începe cu `git status` / `git diff`**; **niciodată `git stash`**
   (memoria `git-stash-partajat-intre-sesiuni`); lucrează dintr-un git worktree separat
   (memoria `shared-worktree-collision`).
2. Face captura din mașină la fracțiile din tabel, cu `--gamecam` și flagurile de hazard, prin
   lacătul de GPU, **copiind `snapshots/okinawa_joc.png` după fiecare**. 5 eșantioane pe verdict.
3. Criticul, **context proaspăt**, primește planșa din:

   ```
   python tools/bar/blind_pair.py "<captura>" "docs/track_briefs/img/bar_okinawa/<POI>.png" "<out>.png" --seed <N>
   ```

   **O singură planșă per rundă.** Decupajul-bară se mărește la rezoluție plină înainte de
   verdict (memoria `numaratoarea-trece-amplasarea-nu`).
4. Criticul **deschide** planșa, alege A sau B, **apoi** citește cheia și raportează cinstit
   dacă a nimerit.
5. Numește **o singură** diferență care contează, reparabilă în decorul POI-ului.
6. Ieșirea din buclă: (a)/(b)/(c). La (a) sau (b): gărzile pe scena integrată, apoi merge. La
   (c): oprire și decizie.

Seed-ul planșei și numele fișierului se schimbă la fiecare rundă (memoria
`critic-orb-coliziune-de-plansa`). Verdictul de fidelitate nu se deleagă constructorului.

## Valurile (câte 3 POI-uri, niciodată 8)

Memoria `valuri-de-trei-nu-opt-agenti`. Regula: **două POI-uri care se calcă pe decor nu merg în
același val** (un worktree nu vede ce pune celălalt). Distanța minimă dintre drumurile POI-urilor
(m, măsurată pe curba coaptă cu granițele de mai sus):

|  | A | B | C | D | E | F | G | H |
|---|---|---|---|---|---|---|---|---|
| **A** | | 3 | 206 | 397 | 211 | 204 | 299 | 3 |
| **B** | 3 | | 2 | 255 | 442 | 442 | 536 | 267 |
| **C** | 206 | 2 | | 2 | 276 | 413 | 664 | 389 |
| **D** | 397 | 255 | 2 | | 2 | 271 | 508 | 414 |
| **E** | 211 | 442 | 276 | 2 | | 3 | 257 | 209 |
| **F** | 204 | 442 | 413 | 271 | 3 | | 2 | 156 |
| **G** | 299 | 536 | 664 | 508 | 257 | 2 | | 2 |
| **H** | 3 | 267 | 389 | 414 | 209 | 156 | 2 | |

Cifrele 2–3 = vecini pe traseu (granița e cifrată: colțul aparține POI-ului care se termină cu el).
Bucla e un inel de 8 POI-uri, deci **A-B, B-C, C-D, D-E, E-F, F-G, G-H, H-A sunt adiacente**.

**Propunerea din cerere (val 1 = A, B, D; val 2 = C, E, F; val 3 = G, H)** are trei perechi
adiacente în același val (A–B, E–F, G–H), fiecare cu un colț comun la 2–3 m. Merge numai cu
granițele cifrate de mai sus (colțurile 0.1023, 0.6121, 0.8236 la POI-ul care se termină) și cu
o regulă de „nimic în 40 m de colț de partea celuilalt”.

**Propunerea mea (nicio pereche adiacentă într-un val; toate distanțele ≥ 156 m):**

| val | POI-uri | de ce |
|---|---|---|
| **1** | **A, C, F** | A–C 206 m, A–F 204 m, C–F 413 m. A = satul (cel mai mult decor mic, banca de teste pentru kit), C = MultiMesh de trestie (riscul de costuri), F = podul (singura zonă cu linie de bază, riscul `[blocaj]`) |
| **2** | **B, D, G** | B–D 255 m, B–G 536 m, D–G 508 m. B = tunelul de fukugi (risc ProbeRace), D = identitatea (poarta, castelul; **datoria zidului peste asfalt**), G = insula mică (tromba) |
| **3** | **E, H** | E–H 209 m. E = cornișa + farul (kit provizoriu, risc (c)), H = digul + tetrapozii + valul (vecin de val 1 prin colțul 0.9747 cu A) |

Dependențe: B și C vecini (B în val 2, C în val 1): C se integrează **înainte** să pornească B; la fel
D (val 2) față de C (val 1), E (val 3) față de D și F (val 1/2), H (val 3) față de A și G. Fiecare val
se integrează într-un worktree dedicat (memoria `orchestrare-agenti-worktree-frate`) înainte să
pornească următorul; gărzile **doar pe scena integrată**; după fiecare merge: `--import` și verifică
ramura înainte de commit (memoria `merge-ul-lasa-tree-ul-pe-main`) și că reparațiile chiar au
ajuns (memoria `reparat-pe-ramura-nu-inseamna-livrat`). **Val 4:** reluarea celui mai slab + trecerea
de integrare (scoaterea cocotierilor din scatter, `ProbeRace` complet, `probe_load_time`, verdictul la
volan) + swap-ul pe indexul 1.

**Riscuri de conflict între constructori:**

- `Track20.tscn` unic: nu au fost puse `ext_resource`-uri noi în antet (acum sunt 8, deschise de
  fundație/montare); fiecare constructor își pune `ext_resource`-urile cu `id` prefixat de literă
  (`a_…`) și coordonatorul concatenează; sub `Zona…` proprie doar noduri.
- **Colțurile comune:** în val 1 nu e nicio pereche adiacentă, deci nu se calcă; dacă se folosește
  propunerea din cerere, cele 3 colțuri se cifrează ca mai sus.
- **Pieselor provizorii** (`Dig_tetrapozi`, `Ziduri_D`, `Far_capul_E`, `Poarta_D`) le mută constructorul
  POI-ului respectiv în zona lui (`reparent`), cu `git status` înainte (memoria
  `tscn-editat-de-mana-nu-se-rescrie`).
- **Materialele:** probe_decor se măsoară pe scena integrată; trei constructori pe worktree-uri
  separate nu văd suma. Azi 24 (≤ 30): fiecare constructor raportează ce materiale NOI adaugă
  (clase, tente), coordonatorul însumează.
- **Hazardele care taie banda** (pod, trombă, val) au culoare libere declarate mai sus; orice piesă cu
  `hull` pe ele schimbă distribuția ProbeRace.
- **Scatterul vechi** (cocotieri, `beach_palm_bent`) e al integrării, nu al constructorilor.
