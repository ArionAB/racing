# Track brief — Monument Valley (`Track19`, temă `monumentvalley`) — v0.1 (concept)

> Concept de pistă, înaintea listei definitive de assets. Scheletul e cel din
> `jodhpur.md` / `kyoto.md`. Secțiunile de assets (§5) sunt schițate, nu
> complete: se detaliază după ce traseul trece de ProbeLayout, de ProbeRace și
> de captura `--gamecam`.
> **Prima pistă care înlocuiește una existentă.** Monument Valley ia locul
> Dunelor, singura pistă fără loc real, pe **indexul 0**: pista implicită și
> runda 1 din campionat. Are patru premiere:
> - prima pistă din **America de Nord** (niciuna din cele 12 nu e pe continent);
> - primul **hazard de vreme care se deplasează peste pistă**: zidul de praf
>   (*haboob*) traversează valea, se vede venind și nu stă pe loc. Ploaia
>   Fiordlandului e globală, culoarul de ceață din Chongqing și norul din
>   Machu Picchu stau pe loc, iar vârtejul Serengeti e mic și rătăcitor;
> - prima pistă cu **asfalt și pământ pe aceeași buclă** (US-163 pe asfalt,
>   Valley Drive pe pământ roșu), cu grila pentru vite ca prag între ele;
> - primii **monoliți**: stânci verticale cu vârf plat, singure în câmpie,
>   care se citesc ca siluete de la sute de metri.
>
> **v0.1 (4 oct 2026):** aleasă de dezvoltator dintre trei propuneri
> (Monument Valley / Wadi Rum → Petra / Sahara marocană: Erg Chebbi +
> Todra/Dadès), **cu traseul redesenat de la zero (~2,1 km)**, nu ca reskin pe
> bucla de 1,15 km a Dunelor. Golurile pe care le umple: **continentul**,
> **cerul mare** (vale deschisă cu repere la sute de metri) și un **hazard
> care se mișcă la scara pistei**. Petra rămâne candidata pentru **Siq +
> Trezoreria + viitura care te urmărește pe canion**, iar Marocul pentru
> **duna care se mută + serpentinele Dadès**. Nu se exclud pentru după
> release.
>
> **Ce se întâmplă cu Dunele.** `Track01.tscn` și tema `desert` **rămân în
> repo, neatinse**: sondele o încarcă direct (`probe_jod_tuk.gd:289`),
> style_bible e calibrată pe ea (`track.gd:369-372`) și e singurul caz de
> test pentru `cliffs: true` + cactuși. Track01 iese doar din **lista de
> joc**, prin commit-ul de swap (§7). Resturile ei (plugul de zăpadă, markerul
> SLIDING orfan de la origine, porțiunea udă fără furtun) **nu se repară**:
> nu mai sunt în joc. Numele „Dunele” supraviețuiește ca **scurtătura prin
> dunele roșii de la Sand Springs** (POI G′).
>
> **Ce e diferit față de Cappadocia**, cealaltă pistă de stâncă. Cappadocia
> înseamnă *tuf moale, crem și roz, coșuri de zână, case săpate, baloane,
> zori, subteran*. Monument Valley înseamnă *gresie dură, roșu-cărămiziu,
> monoliți verticali cu vârf plat, câmpie goală, după-amiază târzie, aproape
> fără arhitectură*. Diferența se verifică pe capturi puse alături (§6), nu
> se presupune. **Față de Serengeti**, cealaltă vale deschisă: acolo e *iarbă
> aurie, acacii, animale în masă, cer violet de furtună*; aici e *nisip roșu,
> piatră, cer albastru adânc și orizontul plin de siluete*.

## 0. Într-o propoziție

După-amiaza târzie în Monument Valley, la granița dintre Utah și Arizona:
pornești de pe **platoul de lângă postul de negoț**, cu moara de vânt și
turnul de apă, virezi spre sud și **treci peste buza platoului: toată valea
se deschide sub tine, cu cele două Mittens și Merrick Butte în capătul
dreptei US-163**. Cobori pe asfalt printre stâlpi de telegraf, treci huruind
**grila pentru vite** și intri pe **Valley Drive**, pământ roșu, unde **caii
în libertate** traversează drumul. **Treci prin poarta dintre cele două
Mittens**, doi pereți de 30 m care cresc în parbriz de o parte și de alta,
pe grohotișul de unde se desprind bolovani, virezi spre vest și intri în
**trecătoarea dintre mese**, un defileu de 12 m în
contralumină, și ieși **pe sub arcul de gresie**. Urci pe cornișa de la
**Artist's Point** și de acolo **vezi haboob-ul**, zidul maro de praf de
50 m care traversează valea. Cobori în valea deschisă **chiar în calea lui**
(sau o tai **prin dunele roșii de la Sand Springs**), **sari peste albia
secată** și urci înapoi pe US-163 spre platou, cu soarele în spate.
Singura pistă din joc pe care **vremea vine spre tine de la distanță** și pe
care **reperele se văd întregi de la 300 m**.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu „Vestul sălbatic de film” (saloon, diligență, cowboy, cactus saguaro,
tipi). Nu Route 66.** Un loc real: o câmpie de nisip roșu din care ies
stânci-turn izolate, sub un cer imens. Ce trebuie să recunoască jucătorul în
3 secunde: *„două stânci-turn ca niște mănuși, una lângă alta, în capătul
unui drum drept care coboară, nisip roșu și cer albastru.”* Silueta
Mittens-urilor e pentru Monument Valley ce e scena de lemn pentru Kyoto.

Ce scoatem din Dunele, cu motiv:
- **saguaro** (cactusul-candelabru): crește doar în deșertul Sonoran, la
  ~400 km sud. Aici cresc salvia, ienupărul, yucca și *rabbitbrush*;
- **Route 66**: trece la ~250 km sud. Drumul de aici e **US-163**;
- **trenul**: în Monument Valley nu e cale ferată;
- **drive-in-ul și benzinăria-recuzită**: Americana generică. Rămâne un
  singur **post de negoț** de piatră, fără nume, plus moara și turnul de apă
  (reale pe pământul de pășune din zonă).

| pondere | strat |
|---|---|
| **40%** | monoliții și mesele: butte-uri pe **trei etaje** — poala de grohotiș (șist Organ Rock, roșu-brun cu dungi), peretele vertical (gresie De Chelly, roșu-portocaliu) și calota subțire și palidă. Siluete întregi în depărtare, pereți de aproape |
| **25%** | câmpia: nisip roșu-cărămiziu, **dune mici** la Sand Springs, albii secate cu maluri tăiate, drumul de pământ cu făgașe și praf |
| **15%** | cerul și vremea: albastru adânc sus, cald la orizont, **cumulus mari** cu umbră pe câmpie, haboob-ul ca eveniment |
| **10%** | vegetația rară: salvie gri-verde, ienupăr închis, yucca, *rabbitbrush* cu **flori galbene** (octombrie, accentul viu al pistei) |
| **10%** | urmele omului, puține și reale: asfaltul US-163 cu linie dublă galbenă, stâlpii de telegraf de lemn, gardul de sârmă, grila pentru vite, semnul „open range” fără text, postul de negoț, moara de vânt, turnul de apă, o gospodărie departe, un pickup vechi parcat |

Trei acte pe un tur, **aceeași paletă, altă proporție**:
- **platoul și dreapta** (asfalt negru + cer + siluete departe);
- **valea de aproape** (pereți roșii, pământ roșu, umbră adâncă în
  trecătoare);
- **câmpia deschisă** (nisip, cer, zidul de praf).

Nu trei palete.

## 1. De ce Monument Valley (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **US-163 dinspre nord**, cu ridicătura de la mila 13 (locul „Forrest Gump Point”, numele nu se folosește, §8): un drum drept care coboară spre monoliți | **POI B, testul de 3 secunde**: coama de pe buza platoului, apoi dreapta cu Mittens-urile **în capăt, pe ax**. Coama e și răspunsul la camera de urmărire (§2.0) |
| **West Mitten și East Mitten** (~300 m peste câmpie), cu „degetul mare” ca o turlă lipită de corp | **reperul pistei**: hero GLB pe un `TerrainPeak` de grohotiș, scalate la ~45 m (§2.0). amândoi se văd întregi de pe coamă, apoi drumul **trece printre ei** (POI D, poarta) |
| **Merrick Butte**, lângă Mittens | al treilea monolit din trio. Fără el, silueta e „două stânci”, nu Monument Valley |
| **Valley Drive**: bucla de pământ de 27 km, roșie, cu făgașe, deschisă și mașinilor turiștilor (restul văii doar cu ghid navajo) | **POI C–G pe pământ**: suprafață `dirt`, grip mai mic (`loose_grip`), praf roșu în urma mașinilor |
| **Rain God Mesa / Spearhead Mesa**: mesele pe lângă care trece Valley Drive | **POI E, trecătoarea**: defileul de 12 m al Dunelor (`custom_gorge_ranges`) devine culoarul dintre două mese |
| **Arcurile de gresie**: Ear of the Wind, Sun's Eye, Moccasin | **POI E′, arcul**: `custom_arch_fracs`, moștenit din Dunele. **Libertate declarată:** arcurile reale sunt în zone cu acces restricționat și niciunul nu trece peste un drum. Îl păstrăm ca poartă a trecătorii, ca la Kyoto, unde tunelul de torii e o compresie |
| **Artist's Point / John Ford's Point**: cornișe de piatră deasupra văii | **POI F**: drum de cornișă fără parapet, cu valea sub tine și **haboob-ul în față-dreapta** |
| **Sand Springs**: dune de nisip roșu la poalele Totem Pole | **POI G′, scurtătura „Dunele”**: `TrackBranch` pe nisip, mai scurtă și lentă |
| **Totem Pole și Yei Bi Chei**: turle subțiri, Totem Pole are ~130 m | **fundal** (`horizon_model`), doar ca siluete pe inel; **numele nu apar în joc** (§8) |
| **Wash-urile** (albii secate) și **grilele pentru vite** de la marginile pășunilor | **POI G2**, săritura peste albie. Grila e **pragul de suprafață** asfalt ↔ pământ, cu huruit (§3) |
| **Caii în libertate**: familiile navajo din vale țin cai, oi și vite pe pășune deschisă, iar semnele galbene „open range” avertizează șoferii | **hazardul de traversare**: `SlidingHazard` *crossing* cu cai. Semnul galben (cal desenat, fără text) e telegraful lor |
| **Furtunile de praf** din sezonul musonic (iulie–septembrie), cu zidul de praf împins de vântul din fața furtunii | **hazardul unic**: `HaboobHazard` (§3). Fenomenul-emblemă al deșerturilor din sud-vestul american |

**Culorile locului** (de măsurat pe fotografii la construcția temei, nu
copiate):
- nisip roșu-cărămiziu (`#C2683A`), mai închis în umbră (`#8E4426`);
- peretele de gresie, roșu-portocaliu (`#B8552E`), aprins la soare jos
  (`#D9784A`);
- grohotișul de șist, roșu-brun cu dungi (`#8A4A33`);
- calota, gri-roz palidă (`#B9A08C`);
- salvie (`#8E977C`), ienupăr (`#4B5A3C`), *rabbitbrush* galben (`#D9B23A`);
- asfalt negru-albăstrui cu linie dublă galbenă;
- cer albastru adânc sus (`#3F79C9`), cald la orizont (`#F1D3AA`);
- haboob maro-ocru (`#A8673E`), mai deschis sus.

**Lumina:** soare jos, din VSV (~18°). Fețele de vest ale monoliților se
aprind portocaliu, iar umbrele se întind spre est cât jumătate de vale.

## 2.0 Verificarea cu camera (de ce dreapta pornește de pe o coamă)

`ChaseCamera`: **10 m sus, 12,5 m în spate, 28,7° în jos, FOV 68°** (memoria
`verifica-cu-parametrii-lui`). Marginea de sus a cadrului e la **+5,25°**,
deci la distanța `d` camera vede cel mult **10 + 0,092·d** m peste cota
drumului. Lateral, jumătatea de cadru e **~50°** la 16:9. Fiecare reper e
verificat pe **patru axe**: distanță (față de ceață), verticală (față de
+5,25°), **azimut** (față de ±50°) și **ocluzie** (memoria
`reperul-se-vede-pe-patru-axe`). Tabelul se scrie **înaintea** traseului, iar
orientarea buclei se derivă din el.

- **Mittens nu pot avea scara reală.** Trei sute de metri ar intra întregi în
  cadru doar de la (300 − 10) / 0,092 ≈ **3,2 km**, dincolo de `FAR_PLANE`
  (380 m). Scara de joc e ~1:7: **West Mitten 45 m** (15 m de grohotiș +
  30 m de perete), East Mitten 42 m, Merrick Butte 38 m. Turlele din fundal
  au 35 m, pe inel.
- **Coama face trucul.** Platoul de start e la **+12 m** față de câmpie. De pe
  buza lui, creasta lui West Mitten (+45 față de câmpie) e la **+33** față de
  drum. Calculul: 10 + 0,092·d ≥ 33 ⇒ **d ≥ 250 m**. Deci coama stă la
  **260–320 m** de West Mitten, cu Mittens-urile la **≤ 15° de ax**. E sub
  `fog_end` (360) și sub `FAR_PLANE` (380). La 300 m, ceața (de la 120 m) le
  pune o pâclă caldă: **perspectiva aeriană e dorită**, așa arată și pozele
  reale.
- **Pe dreaptă, Mittens-urile cresc până ies din cadru.** Coborând la cota
  câmpiei (0), creasta e la +45 față de drum, deci încape întreagă doar de la
  380 m. Pe dreaptă sunt mai aproape, așa că vârful se taie progresiv. **E
  corect așa** (precedentul e fortul din Jodhpur): *stânca devine prea mare
  ca să încapă*. Nu se micșorează și nu se ridică marginea camerei.
- **D trece PRIN poarta dintre Mittens, nu în jurul unuia. Asta e
  măsurat, nu ales.** Prima schiță (v0.1) ocolea West Mitten pe un arc de
  rază constantă (78 m, apoi 52 m) în jurul lui. Generatorul de probă a dat
  **0 din 19 puncte** cu monolitul în cadru: pe un cerc centrat pe obiect,
  obiectul stă **exact la 90°**. Turnul (rază 25 m) apare abia la ≥ 61° de
  direcție, adică mereu în afara cadrului de ±50° (memoria
  `perete-paralel-nu-se-vede`, aici cu cifre). Varianta adoptată: Mittens
  stau **de o parte și de alta a axei dreptei** (West Mitten la +7°, East
  Mitten la −7,5° de pe coamă), deci drumul merge **spre ei** și trece
  printre ei. Măsurat: **ambii în cadru pe 22 din 28 de puncte (79%)** de la
  coamă până la poartă, iar centrele lor sunt la 38 m de axă. Cu turnul de
  rază ~14 m și semilățimea de 6,5 m, pereții sunt la **~18 m de marginea
  drumului** de fiecare parte (memoria `munte-flanc-nu-fundal`: un masiv se
  simte doar la < 40 m). Grohotișul (`TerrainPeak`, rază ≤ 28 m) se oprește
  la ~3,5 m de marginea drumului. Se verifică cu `ProbeBuried`. Contract:
  ambii Mittens la ≤ 50° de direcție pe ≥ 70% din punctele dintre coamă și
  poartă.
- **Trecătoarea E e în contralumină.** E merge spre vest, cu soarele de
  18° în față, dar soarele e **peste** marginea de sus a cadrului (+5,25°),
  deci nu intră în cadru și nu orbește. Pereții sunt în umbră, cu muchia
  aprinsă. **Asta e intenția**: singurul loc întunecat al pistei. Se
  verifică pe captură că asfaltul nu devine o pată (memoria
  `umbra-fara-culoare-e-negru-mort`).
- **Haboob-ul se vede de pe F.** Cornișa F e la **+12…+13,5** față de câmpie
  și merge spre nord, cu valea G în față și în dreapta. Zidul vine **dinspre
  vest, din afara buclei**, peste masa din stânga cornișei, și traversează G
  spre est. De pe cornișă e în **stânga-față, la ~30°, la ~300 m** (schița:
  punctul F de la (−200, −360) vede centrul frontului de la (−350, −90) la
  309 m și −29°). Zidul are **50 m** de la cota câmpiei, deci ~+37 față de
  drumul de pe cornișă. Calculul: 10 + 0,092·d ≥ 37 ⇒ **d ≥ 293 m** ca să
  încapă întreg. Între 150 și 280 m se vede tăiat sus,
  ca un zid mai înalt decât cadrul, și **asta e senzația căutată**. Contract:
  zidul e la **≤ 50° de direcție** pe ≥ 60% din punctele lui F, timp de
  **≥ 8 s înainte să atingă drumul din G**. Altfel telegraful nu există.
- **Platoul de start se vede de pe H.** H urcă spre est, cu soarele în spate,
  deci reperul din capăt e **luminat din față**. Turnul de apă (18 m) și moara
  (14 m) sunt pe ax la 150–250 m: încap întregi de la 90 m.
- **Fundalul:** inelele `horizon_rings` (Eagle Mesa, Brigham's Tomb,
  Stagecoach, turlele Totem Pole) stau la **190–340 m**, sub `fog_end` (360),
  care e sub `FAR_PLANE` (380). Memoria `efecte-de-fundal-cote-legate`: la
  Alpii, 13 siluete corect așezate dar puse după ceață n-au fost văzute
  deloc. **`cast_shadow` OFF** pe tot inelul (memoria
  `caster-departat-fura-umbra`).

Consecința: **platoul e respiro-ul, coama e dezvăluirea, dreapta e viteza
spre siluete, Valley Drive e intrarea în tablou, poarta dintre Mittens e
locul unde siluetele devin pereți, trecătoarea e umbra, cornișa e telegraful,
câmpia e furtuna, albia e saltul, US-163 înapoi e drumul acasă.**

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2,1 km** (tur ~70 s, 3 tururi ≈ 3:30, în fereastra
Ignition 65–80 s din `ref_notes/sisteme.md`). **Atenție: runda 1 a
campionatului se lungește** de la ~1:55 (Dunele) la ~3:30. Dezvoltatorul
decide în §3.1 dacă e acceptabil pentru prima impresie.

**Sens orar pe plan:**
- A spre est, pe latura de nord;
- B, C și D spre sud, pe latura de est (drept prin poarta Mittens);
- E spre vest, pe latura de sud;
- F și G spre nord, pe latura de vest;
- H spre est, înapoi pe latura de nord.

Interiorul buclei e valea. Mittens-urile stau pe latura de est, de o parte și
de alta a axei lui B–D. Merrick Butte e în afara buclei, la est. Convenția de
hartă e cea din `gen_kyoto_route.py` (gx = x, gz = −y, **fără oglindire**):
„dreapta” din brief e dreapta din cadru.

Cote: platoul **+12 m**, câmpia **0 m**, trecătoarea **+3 → +9**, cornișa F
**+12 → +13,5** (punctul cel mai înalt), fundul albiei **−5**, apoi înapoi
pe platou la +12.

**Schița măsurată** (4 oct 2026, generator de probă pe tiparul
`gen_kyoto_route.py`, fillet-uri pe arc, pas 12 m):
- **2 100 m**, sens orar;
- rază minimă **23,5 m** (colțul lui A);
- pantă maximă **8,4%** (coborârea B);
- separare minimă **94 m** între două porțiuni ale buclei;
- centroid la (67, −199), Cebîșev **263 m** (zidul lumii e la 420).

| porțiune | cote | lungime | pantă |
|---|---|---|---|
| coborârea B (de pe coamă) | 12 → 0 | ~145 m | **8,4%** |
| urcarea E (trecătoarea) | +3 → +9 | ~290 m | **~2%** |
| urcarea F (cornișa) | +10 → +13,5 | ~270 m | **~1,3%** |
| coborârea G | +13,5 → 0 | ~230 m | **~5,9%** |
| urcarea H | 0 → +12 | ~320 m | **~3,7%** |

**De măsurat cu ProbeLayout:** pantă < 13%, rază ≥ 9 m, apropiere de sine
≥ 20 m. Bucla stă la **< 420 m de centroid** și nimic sub plasa de mare
(memoria `ziduri-invizibile-ale-lumii`).

```
   N ↑
   [H] US-163 înapoi (0→+12) ─────────────►  [A] START pe platou (+12)
    ▲   stâlpi de telegraf, soarele în spate     postul de negoț, moara, turnul de apă
    │                                             │ viraj la dreapta pe buză
   [G2] săritura peste albie (−5)                 ▼
    │                                          [B] COAMA → dreapta US-163 (+12→0)
   [G] câmpia deschisă (0)       VALEA            │   Mittens + Merrick în capăt, pe ax
    │   haboob-ul o traversează                   │
    │   ┌─[G′] scurtătura „Dunele”                ▼
    │   │   dunele roșii, Sand Springs         [C] grila pentru vite → Valley Drive
    │   └─────────┘                               │   pământ roșu, caii în libertate
   [F] cornișa Artist's Point (+13,5)             ▼
    ▲   haboob-ul vine din stânga-față         [D] POARTA dintre Mittens
    │                                          WM ▓│▓ EM  pereți la ~18 m, grohotiș
   [E′] arcul de gresie ◄── [E] trecătoarea dintre mese (+3→+9) ◄──┘ viraj spre V
                                defileu de 12 m în contralumină
```

| # | frac | POI | ce se întâmplă | semilățime |
|---|---|---|---|---|
| **A** | 0.000–0.040 | **Start pe platou.** Asfalt, grila de start pe linia dublă galbenă. În stânga, postul de negoț de piatră cu prispă, un pickup vechi parcat, moara de vânt, turnul de apă. Câmpia **nu se vede încă**: buza platoului o ascunde | respiro; viraj larg la dreapta pe buză | 7 m |
| **B** | 0.040–0.131 | **Coama și dreapta US-163.** Treci peste buza platoului (coama la 0.063) și **valea se deschide**: Mittens și Merrick în capăt, pe ax, la 260–310 m (§2.0). Apoi o dreaptă de ~150 m în coborâre, cu stâlpi de telegraf pe dreapta, gard de sârmă și salvie | **momentul-semnătură vizual**. Prima dreaptă de turbo. Coama dă **airtime** dacă geometria o permite (§3, de măsurat); altfel e doar dezvăluire, și e destul | 7 m |
| **C** | 0.131–0.206 | **Grila pentru vite și Valley Drive.** Asfaltul se termină drept, la 0.137, peste grila pentru vite (huruit, §3), și dreapta continuă pe **pământ roșu**, spre Mittens. Semnul galben cu calul. **Doi cai** traversează drumul la ~37 s | **pragul de suprafață**: grip mai mic, praf roșu. Caii sunt hazardul de traversare | 6,5 m |
| **D** | 0.206–0.297 | **Poarta dintre Mittens.** Dreapta trece printre West Mitten (dreapta) și East Mitten (stânga), cu pereții de 30 m la ~18 m de marginea drumului, pe grohotiș. **Rockfall #1** din grohotișul lui West Mitten, pe un traseu desenat (`Path3D`), peste drum în poartă. Apoi un **viraj larg la dreapta** (rază ~46 m, la 0.257), spre vest | **siluetele devin pereți** (§2.0). Virajul de după poartă cere drift, deci **bara de turbo se încarcă** | 6,5 m |
| **E** | 0.297–0.434 | **Trecătoarea dintre mese.** Culoar spre vest între două mese, pereții `TrackCliffs` de 12 m la 0,8 m de drum (`custom_gorge_ranges`), în contralumină. **Rockfall #2** de pe peretele din stânga | **umbra**, singurul loc închis. Defileul Dunelor, cu un loc real | 5,5 m |
| **E′** | 0.434 | **Arcul de gresie** peste drum, la ieșirea din trecătoare (`custom_arch_fracs`, `rocks/rock_arch.glb` recolorat pe clasa `mv_sandstone`) | **poarta**: ieșirea din umbră în lumină. Libertate declarată (§1) | 5,5 m |
| **F** | 0.434–0.600 | **Cornișa de la Artist's Point.** Colț spre nord și urcare lină pe buza unei mese (+10 → +13,5), două curbe largi ale cornișei, **fără parapet spre dreapta**, cu valea dedesubt (`custom_cornice_ravines`, cădere de ~13 m). **Haboob-ul se vede** venind dinspre vest, în stânga-față | **telegraful**: aici decizi dacă tai prin dune sau ocolești. Căzut = repunere (~2 s), cu `RespawnZone` | 6 m |
| **G** | 0.600–0.834 | **Câmpia deschisă.** Coborâre de pe cornișă și drum de pământ peste câmpie, cu S-uri largi. **Haboob-ul traversează porțiunea asta** (§3). Un **vârtej de praf** (`DustDevilHazard`) rătăcește pe câmpie. **Al doilea grup de cai** la ~53 s | **furtuna**: vizibilitate scurtă și vânt lateral când te prinde. Altfel e cea mai rapidă porțiune pe pământ | 8 m (deschis) |
| **G′** | ~0.64–0.80 (buclă, de așezat la generator) | **Scurtătura „Dunele”**: `TrackBranch` peste dunele roșii de la Sand Springs, pe interiorul S-urilor din G, **~25% mai scurtă**. Suprafață `SAND`, `speed_factor` ~0,8, cocoașe de dună care dau salturi mici. Gura e la ieșirea din F, vizibilă de pe cornișă | **risc/recompensă** (principiul 3, **prima scurtătură** a pistei). Câștigul se reglează pe sondă la 0,5–1,5 s, ca la Chasm. Cu haboob-ul peste dune, gura nu se mai vede | 3,5 m (`branch_half_width`) |
| **G2** | 0.834–0.846 | **Săritura peste albia secată.** Wash cu maluri tăiate, adânc de 5 m și lat de ~12 m, peste care drumul sare (`TrackChannel jump`, **fără apă**). Aterizare pe pământ, pe malul opus | **airtime** (principiul 1). Ratat = în albie = repunere (~2 s) | 7 m |
| **H** | 0.846–1.000 | **US-163 înapoi.** Grila pentru vite înapoi pe asfalt, apoi o dreaptă lungă spre est, **în urcare spre platou**, cu soarele în spate. Stâlpi de telegraf, turnul de apă și moara pe ax | **a doua dreaptă de turbo**: aici se arde bara încărcată în D și în dune | 7 m |

### 2.1 Schița de waypoint-uri (sursa generatorului)

Măsurată pe 4 oct 2026 cu funcțiile din `gen_kyoto_route.py` (`fillet_loop`,
`assign_elev`, `resample` la 12 m). Coordonate de hartă: x est, y nord, în metri;
tuplu = (x, y, rază de fillet, cotă sau `None`, etichetă). Reperele sunt
**puncte fixe ale schiței**, nu derivate din traseu, ca garda de azimut să nu se
auto-confirme (memoria `garda-circulara-propria-functie`).

```python
WM = (262.0, -300.0)   # West Mitten
EM = (338.0, -318.0)   # East Mitten
MB = (372.0, -262.0)   # Merrick Butte (la est, in afara buclei)

WPTS = [
    (210, 40, 0, 12.0, "A start"),
    (300, 40, 34, 12.0, "A colt spre S"),
    (302, -8, 0, 12.0, "B coama"),
    (300, -150, 0, 0.0, "B capat asfalt"),
    (300, -166, 0, 0.0, "C grila"),
    (300, -228, 0, 0.0, "C cai"),
    (300, -309, 0, 0.5, "D poarta Mittens"),
    (300, -428, 46, 1.5, "D viraj spre V"),
    (210, -444, 0, 3.0, "E intrare trecatoare"),
    (120, -436, 0, 4.5, "E1"),
    (20, -450, 0, 6.5, "E2 defileu"),
    (-80, -444, 0, 9.0, "E' arcul"),
    (-150, -450, 44, 10.0, "F colt spre N"),
    (-200, -360, 40, 12.0, "F cornisa 1"),
    (-176, -258, 40, 13.5, "F cornisa 2"),
    (-198, -186, 34, 14.0, "F capat cornisa"),
    (-100, -160, 44, 6.0, "G S1 est"),
    (40, -180, 46, 1.0, "G S1 apex"),
    (80, -96, 44, 0.5, "G S1 iesire"),
    (-70, -60, 44, 0.0, "G S2 vest"),
    (-96, -14, 0, -0.5, "G2 albia"),
    (-96, 12, 30, 0.0, "G2 aterizare"),
    (-60, 40, 0, 1.0, "H inceput"),
]
```

**Ritmul turului:**
1. platou (respiro);
2. coama (dezvăluirea);
3. dreapta (turbo, siluetele cresc);
4. grila (pragul de suprafață, caii);
5. poarta dintre Mittens (pereții, bolovanul), apoi virajul (drift);
6. trecătoarea (umbra, bolovanul);
7. arcul (poarta spre lumină);
8. cornișa (telegraful, decizia);
9. câmpia sau dunele (furtuna, caii, vârtejul);
10. albia (saltul);
11. US-163 (turbo, acasă).

**Ceasuri care nu împart durata turului** (lecția Stromboli):
- haboob-ul **~101 s** (§3);
- caii din C **~37 s**, caii din G **~53 s**;
- bolovanul din D, pauză **~13 s**; cel din E, **~17 s**;
- vârtejul, rătăcire continuă.

Faza fiecărui ceas se mută de la tur la tur. Haboob-ul, mai lung decât un
tur, te prinde **în ture diferite**, nu în același loc. Memoria
`ceasul-porneste-in-prima-faza`: la start, haboob-ul e în **faza de
liniște**, iar toate sondele îl pot fixa în orice fază (`--haboob-at=`).

## 3. Hazarduri și mecanici (ce e nou pentru motor)

Acoperirea celor cinci clase din `ref_notes/sisteme.md` §3:

| clasă (Ignition) | aici |
|---|---|
| **teatru** | haboob-ul la orizont (telegraful), vârtejuri de praf departe, ciori, tumbleweeds, moara care se învârte, umbrele norilor pe câmpie, huruitul grilei, un pickup pe un drum departe |
| frecare | **pământul** de pe Valley Drive (`loose_grip` ~7), **nisipul** din G′ (0,8×), praful din haboob (doar vizibilitate, grip neschimbat) |
| **oprire** | **niciuna.** Lecția Fiordland (4 runde picate ale semaforului cu oprire) se aplică de la început |
| sabotaj de control | **haboob-ul** (vizibilitate + vânt lateral) și **vârtejul de praf** (refolosit, un singur exemplar, în G) |
| **aruncare** | bolovanii (×2), caii (corp cinematic, împing), săritura peste albie, salturile din dune, coama (dacă dă airtime) |

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Haboob-ul** (G, G′) | **Ciclu ~101 s:** ~25 s de pâclă maro care crește la orizont (telegraful, vizibil de pe F), ~55 s de traversare, ~21 s de risipire. **Zidul:** 50 m înălțime, ~400 m lățime, 60–80 m adâncime, se mișcă pe un `Path3D` peste vale (cu 6–8 m/s, cât să traverseze G în ~40 s). **Când te prinde:** (a) ceața, *doar pentru jucător*, coboară la `fog_end_inside` ~35 m, cu culoarea prafului, iar restaurarea e exactă la ieșire; (b) `blind()` de 0,3 s la trecerea frontului; (c) **vânt lateral** de 2,5–3,5 m/s², cu rafale, **pe toate mașinile** din zid; (d) 4–8 **tumbleweeds** care se rostogolesc în fața frontului, **doar vizual**. **AI-ul:** vezi §3.1. **Sunetul:** un vuiet jos care crește, ca telegraf audio | **nou — `HaboobHazard extends FogCorridorHazard`**, pe tiparul `CloudRiseHazard`. **Refolosit:** <br>• împingerea ceții pe jucător și restaurarea exactă (`fog_corridor_hazard.gd:271-279, 318-358`) <br>• API-ul de ceas `period`/`phase`/`cover_at`/`set_cycle_time` (`cloud_rise_hazard.gd:110-162`) <br>• `blind()` ca la `DustDevilHazard` (`dust_devil_hazard.gd:248-266`) <br>• formula vântului din Baikal (`track.gd:15319-15328`, aplicată ca `car.gd:599-603`), dar **local**, nu prin `Track.wind_at` (acolo bate doar pe gheață) <br><br>**Nou:** mișcarea pe `Path3D`, `_build_zone` suprascris (cutia de bază are doar 8 m), randarea și `force_clock` pentru `Snapshot --haboob-at=`. **Randarea:** 2–3 quad-uri verticale moi, cu `distance_fade` aproape de cameră și culoarea egală cu a ceții (fără salt la intrare), plus ≤ 32 de particule de praf. Rezerva, dacă overdraw-ul nu trece: miez opac `unshaded` cu franjuri subțiri. **Buget: +2–3 materiale** |
| **Asfalt + pământ pe aceeași buclă** (A, B, H pe asfalt; C–G pe pământ) | linia dublă galbenă, bordurile, urmele coapte și praful mașinii **întreabă de fracție**, nu de toată pista | **nou, mic — `custom_dirt_ranges`**, pe tiparul gheții și lemnului din `_build_road` (`track.gd:10162-10170`, `10253-10255`), cu materialul de pământ existent (`track.gd:12649-12663`, **+1 material**). Azi `custom_road_surface` e pe toată pista (`track.gd:89-97`), iar `custom_loose_ranges` schimbă doar grip-ul, fără nimic vizibil |
| **Grila pentru vite** (C, H) | bandă de metal peste drum: **huruit** (sunet), shake mic de cameră (0,08) și vibrație de suspensie. **Fără efect de fizică** | **de verificat pe cod**: `car.gd` are deja un huruit periodic pe apă (`WATER_RUMBLE`, `car.gd:1516-1529`). Dacă se poate legat de o fracție, e reuse. Altfel e o zonă de juice nouă, mică. Modelul grilei e un GLB plat cu coliziune `none` |
| **Caii în libertate** (C, G) | 2 + 2 cai traversează drumul la pas (2 m/s, ca lamele de pe Machu Picchu), cu ceasuri de ~37 / ~53 s. Telegraful e semnul galben de la 80 m și nechezatul. **Caii nu se aruncă și nu se rănesc** (§8): sunt corpuri solide, deci mașina se oprește în ei sau îi ocolește | **reuse** — `SlidingHazard`, `motion` crossing, cu export `model` (ca pe Track15). **Nu `HerdHazard`**: turma e identitatea Serengeti. Modelul e animat (`Walk`, `Stand`), pe pipeline-ul vacii (PR #270) |
| **Bolovanii** (D, E) | bolovan din grohotiș, pe o bandă, cu traseu desenat | **reuse** — `HazardMarker` ROCKFALL cu `Path3D` copil (ca pe Track01), modelul `boulder_roller.glb` pe clasa `mv_sandstone` |
| **Vârtejul de praf** (G) | un singur vârtej rătăcitor pe câmpie, cu roșu în loc de ocru | **reuse** — `DustDevilHazard` ca nod de scenă (ca pe Track14 / Track18), `dust_color` roșu |
| **Coama** (B) | dezvăluirea; airtime dacă se poate | **de măsurat:** cu gravitația jocului de 28 m/s² (`car.gd:105`), un salt de pe coamă la 34 m/s cere o rază verticală < v²/g ≈ **41 m**, adică o frântură de pantă de ~8% pe ~3 m. Pasul de 12 m al lui Catmull-Rom o netezește. Dacă iese fără airtime, coama rămâne **dezvăluire**, fără kicker artificial pe asfalt |
| **Săritura peste albie** (G2) | gol de ~12 m peste albia secată, cu repunere în albie | **reuse** — `TrackChannel jump` + `RespawnZone` + `respawn_past_gap`. **De verificat:** `TrackChannel` construiește apă (`water_half`, `water_y_drop`). Dacă nu există o albie **uscată**, trebuie un steag mic (`dry`) |
| **Cornișa** (F) | drum pe buza mesei, fără parapet spre vale | **reuse** — `custom_cornice_ravines` (buza la 0,5 m de asfalt, memoria `munte-flanc-nu-fundal`) + `RespawnZone` |
| **Trecătoarea și arcul** (E, E′) | defileu și arc moștenite de la Dunele | **reuse** — `custom_gorge_ranges`, `custom_arch_fracs`. **Schimbare mică:** `TrackCliffs` aplică azi mereu clasa `rock` (`track_cliffs.gd:521`), deci trebuie să citească `rock_class` din temă, ca arcul (`track.gd:13801-13805`). Dunele nu are `rock_class`, deci iese identică |
| **Scurtătura „Dunele”** (G′) | bandă de nisip peste dune | **reuse** — `TrackBranch`, `surface = SAND`, `speed_factor` ~0,8 (`track_branch.gd:72, 124`) |

**Ce NU e nou:** bolovanii, caii, vârtejul, săritura, cornișa, trecătoarea,
arcul și scurtătura. **Trei lucruri noi:** `HaboobHazard` (mare),
`custom_dirt_ranges` (mic) și grila pentru vite (minuscul, poate reuse).
Identitatea e **siluetele + pământul roșu + furtuna care vine**, nu numărul de
mecanici.

### 3.1 Decizii pentru dezvoltator

1. **Numele de afișare.** „Monument Valley” e și **titlul unui joc mobil
   (ustwo games, marcă înregistrată)**, pe aceeași platformă și în aceleași
   magazine. E exact regula din CLAUDE.md care a scos „Ignition”. Numele de
   loc e liber în documente și în cod (`monumentvalley`), dar **nu în UI și
   nici în store listing**. Variante:
   - **„Valea Monumentelor”** (recomandat): descriptiv, în aceeași limbă ca
     „Dunele” și „Alpii”;
   - **„Utah”**;
   - **„Four Corners”**.

   **Se decide înainte de commit-ul de swap.** Recordurile sunt pe cheie
   `TRACK_NAMES` (`game_state.gd:167-177`), deci o redenumire ulterioară le
   orfanizează.
2. **AI-ul în haboob.** Chongqing a stabilit precedentul: AI-ul nu vede ceața
   și merge la fel. Aici zidul e evenimentul pistei, iar un AI care trece
   orbește la viteză maximă pare trișat (principiul 5). **Recomandare:** în
   miezul zidului, AI-ul își scade ținta de viteză cu ~10%, cât un șofer
   prudent. Se măsoară pe ProbeRace, nu se ghicește.
3. **Runda 1 se lungește** de la ~1:55 la ~3:30. **Recomandare:** se
   acceptă. Pistele construite de la Chongqing încoace au ~2 km, deci Dunele era excepția.
4. **Gospodăria navajo din fundal** (casă modulară + hogan de locuit + țarc
   de cai), la > 80 m de drum, fără interior și fără nimic ceremonial. Dă
   locului viață reală. **Recomandare:** da, doar ca locuință; se poate
   scoate fără să schimbe pista.
5. **Viitura din albie** ca al doilea hazard (unda maro de pe wash, după
   furtună). **Recomandare: nu în v0.1.** Se suprapune cu torentul din
   Fiordland, iar cerința a fost un singur hazard unic. Rămâne în rezervă.

## 4. Paleta și lumina (fără slot nou)

**Nu există slot liber** (atlasul are 32 de sloturi, toate alocate; ultimul,
`FLAMINGO_PINK` 31, la Serengeti). Monument Valley se face **din sloturi
existente + clase noi pe dale existente** (memoria
`slot-reutilizat-intre-piste`: slotul aduce și masca de detaliu).

**Roșul de gresie e decizia de risc a pistei.** Varianta propusă:
- o clasă nouă **`mv_sandstone`** pe dala `alpine_granite.png`, pe tiparul
  lui `red_valley_tuff` (`palette.gd:590`);
- **fără** retentarea clasei `rock`, pe care o folosesc Dunele și restul
  (memoria `tenta-pe-clasa-partajata`);
- tenta doar întunecă (memoria `surfacetool-clamp-vertex-color`), deci roșul
  aprins cere **`CLASS_LIFT`**.

**Se măsoară după remap**, în joc (memoria `monocromia-se-masoara-dupa-remap`),
nu pe `.glb`.

| rol | slot existent / clasă |
|---|---|
| peretele monoliților și al meselor (dominant) | `TILE_TERRACOTTA` 23 (lumină) + clasa **`mv_sandstone`** (`#B8552E`) |
| grohotișul (șist Organ Rock) | `RUST_METAL` 10 (roșu umbrit) + `LARCH_RUST` 27 (banda din mijloc); dungi orizontale din `custom_strata_bands` |
| calota palidă | `MARBLE_GREY` 29 sau `CORAL_SAND` 19 |
| crăpăturile și umbrele | `SAND_SHADOW` 2, `ROCK_DARK` 4 |
| nisipul câmpiei (`ground_tint`) | `TILE_TERRACOTTA` 23 citit ca culoare de pornire (`#C4784F`), apoi spre roșu prin tentă |
| fețele aprinse, albiile palide | `ROCK_LIGHT` 3, `SAND_LIGHT` 0 |
| drumul de pământ (`dirt_road_tint`) | roșu-portocaliu (~0,72, 0,42, 0,28), cu făgașe mai închise |
| asfaltul (A, B, H) | `ASPHALT` 5 + `ASPHALT_EDGE` 6, **linie dublă galbenă** `CAR_YELLOW` 16 |
| salvia, ienupărul, yucca | `CACTUS_GREEN` 12 (gri-verde prăfuit), `DRY_VEGETATION` 13 |
| *rabbitbrush* în floare | `CAR_YELLOW` 16, **accentul viu al pistei**, în puncte mici |
| stâlpii de telegraf, gardul, moara | `LOG_DARK` 28, `CONCRETE` 8 |
| caii | `LOG_DARK` 28 (murg), `FOAM_WHITE` 22 + `RUST_METAL` 10 (pinto) |
| haboob-ul | culoarea ceții din temă, împinsă spre `#A8673E`; un singur material partajat |

`CliffFace` are deja rampa implicită `band_slots [23, 10, 27, …]`
(`cliff_face.gd:184`), adică exact paleta de aici.

**Lumina:**
- **soarele:** 18° din VSV (`sun_rotation_deg` ≈ (−18, −70, 0), în convenția
  temei kyoto: busola = 180 − y), `#FFD2A0`, energie ~1,0. `exposure` **se
  măsoară**, nu se copiază 1,30 din deșert;
- **ambientul:** rece, ~`#A9BEDD` la 0,30; umbrele lungi au nevoie de el
  albăstrui, altfel ies negre (memoria `umbra-fara-culoare-e-negru-mort`);
- **cerul:** `#3F79C9` sus, `#F1D3AA` la orizont, cumulus mari cu acoperire
  mică;
- **ceața:** 120 → 360 m, curbă 1,4, maximă 0,8, caldă. Toate inelele de
  fundal sunt sub 360;
- **umbrele:** pornite, `shadow_distance` 90. La 18°, o umbră are ~3× înălțimea
  obiectului, iar umbrele monoliților pe câmpie sunt jumătate din identitate.
  Memoria `umbre-exista-dar-cascada-e-scurta`: castorii sunt departe, deci se
  testează, și umbrele sunt **prima setare de stins** pe device (CLAUDE.md).

**Azimutul soarelui față de drum** (memoria
`azimutul-soarelui-fata-de-drum`; se remăsoară la fiecare redesenare a
traseului):

| porțiune | direcție | soarele | ce dă |
|---|---|---|---|
| B | spre sud | din dreapta | fața de nord a Mittens-urilor e în lumină razantă: muchia de vest aprinsă, cea de est în umbră. **Modelaj maxim**, exact ce cere memoria `adancimea-cere-lumina-nu-doar-umbra` |
| E | spre vest | din față, peste cadru | contralumina trecătorii (§2.0) |
| F, G | spre nord | din stânga-spate | valea e luminată lateral; zidul haboob-ului are fața de vest aprinsă, ca un perete de foc ocru |
| H | spre est | din spate | reperele din capăt sunt luminate frontal |

## 5. Assets (schiță — lista completă după ProbeLayout)

Categoria nouă `assets/models/monumentvalley/`, cu subfolderele `rocks/`,
`buildings/`, `structures/`, `props/`, `vehicles/`, `animals/`, `plants/`
(memoria `assets-models-categorii`).

### 5.1 Teren și suprafețe (cod, clase de textură)

- `mv_sandstone`: perete de gresie cu fisuri verticale și pete de „lac de
  deșert” (dungi închise de scurgere). **Fisurile sunt verticale, nu
  orizontale**: diferența de citire față de șistul de dedesubt;
- `mv_shale`: grohotiș stratificat orizontal, cu bolovani. Se verifică întâi
  dacă `detail_texture`-ul implicit, care are deja straturi orizontale, ține;
- `mv_sand`: nisip roșu cu riduri de vânt;
- `dirt_road` roșu, cu făgașe (materialul de pământ existent, cu tentă);
- decalul `cattle_guard` (grila);
- decalul `tyre_dust` (urme de praf pe asfalt la trecerea de pe pământ, prin
  `RoadWear`);
- shaderul `haboob_wall` (§3).

### 5.2 Hero (unice)

| asset | note |
|---|---|
| `west_mitten.glb`, `east_mitten.glb` (corp + „degetul mare”, 30 m de perete peste un `TerrainPeak` de grohotiș de 15 m) | **reperul pistei**. Silueta se judecă întâi pe captura de pe coamă (memoria `silueta-inainte-de-umbrire`), apoi lumina |
| `merrick_butte.glb` (38 m) | al treilea din trio |
| `mesa_wall_module.glb` (modul de perete de masă, 12 × 14 m, pentru E și F) | completează pereții `TrackCliffs` acolo unde codul nu ajunge |
| `trading_post.glb` (post de negoț de piatră, cu prispă de lemn, **fără nume**) | reperul lui A și H, cu pickup-ul vechi lângă el |
| `cattle_guard.glb` (grilă de metal + doi stâlpi de capăt) | pragul de suprafață din C și H; coliziune `none` |
| `open_range_sign.glb` (romb galben cu un cal, **fără text**) | telegraful cailor |
| `horse_a.glb`, `horse_b.glb` (murg și pinto, animați: `Walk`, `Stand`, `Graze`) | `SlidingHazard`; pipeline-ul vacii (PR #270, memoria `asset-animat-pipeline`) |
| `tumbleweed.glb` | **ARE CONSUMATOR NOU** (`HaboobHazard`), cu export `model` de la început |

### 5.3 Kit (modular, statistice)

- **Piatră:**
  - `butte_small_a…c.glb` (monoliți mici la 80–200 m);
  - `rock_fin.glb` (aripă de stâncă subțire);
  - `talus_boulders_a/b.glb`;
  - reuse `rocks/butte.glb` (placeholder la fundație), `rocks/rock_arch.glb`,
    `cliff_wall.glb` (variantele din `TrackCliffs`);
  - toate pe clasa `mv_sandstone`.
- **Plante:**
  - `sagebrush.glb`, `rabbitbrush.glb` (cu flori galbene), `juniper.glb`,
    `yucca.glb`;
  - pe MultiMesh dacă trec de ~1000 de piese (memoria
    `decor-in-masa-cere-multimesh`).
- **Urmele omului:**
  - `telegraph_pole.glb`: stâlp de lemn cu traversă, pe curbă, la 40 m.
    **Ritmul vertical al lui US-163**;
  - `wire_fence.glb`: stâlpi + sârmă, un segment;
  - `windmill.glb`: reuse `buildings/windmill.glb`;
  - turnul de apă: reuse din Dunele;
  - `pickup_old.glb`, `tour_truck.glb`: camion de tur, deschis, **parcat**,
    la Artist's Point;
  - `homestead_house.glb`, `hogan.glb`, `corral.glb`: §3.1.4, doar dacă se
    aprobă;
  - `mailbox.glb`, `reflector_post.glb`.
- **Teatru:** `raven.glb` (`PathMover` în cerc), vârtejuri de praf departe
  (doar vizual).

### 5.4 Fundal (`horizon_class`)

`mv_horizon.glb`, cu nodurile:
- `EagleMesa_A`, `BrighamsTomb_A`, `Stagecoach_A`, `KingOnThrone_A`;
- `Spires_A` (turlele Totem Pole: doar silueta, numele nu apar);
- `FarMesa_A/B` (mese joase care se pierd în pâclă).

Pe inele la 190–340 m, cu `angle_deg` fix pentru siluetele importante
(suportat la `track.gd:5547`), `horizon_class: "mv_sandstone"` și
**`cast_shadow` OFF**. Memoria `efecte-de-fundal-cote-legate`: dacă piesa are
benzi pictate în UV-uri, clasa goală păstrează atlasul.

### 5.5 Sunet

- **vuietul haboob-ului** (telegraful, cel mai important sunet al pistei);
- huruitul grilei;
- pietrișul sub roți pe Valley Drive (suprafața se aude);
- nechezatul și copitele cailor (telegraful lor);
- ciorile;
- vântul;
- scârțâitul morii;
- zumzetul firelor de telegraf pe US-163;
- bolovanul (rostogolire + impact).

### 5.6 Trecerea de contracte — **de făcut înainte de primul build**

Memoria `brief-cere-glb-cod-il-face-deja`: la Machu Picchu, 4 piese n-aveau
consumator. Verdictele de aici sunt preliminare și se confirmă pe cod citit.

| piesă | verdict preliminar | ce se face |
|---|---|---|
| grohotișul monoliților | CONFLICT dacă se cere GLB | `TerrainPeak` (pantă de grohotiș, grilă de 7,9 m), cu turnul GLB așezat pe el |
| pereții trecătorii | CONFLICT dacă se cere GLB | `TrackCliffs` + `custom_gorge_ranges`; `mesa_wall_module` doar ca completare |
| arcul | ARE CONSUMATOR (`_build_arch`, `rocks/rock_arch.glb`, `track.gd:13769`) | recolorat pe clasă, **fără GLB nou** în v0.1 |
| albia | CONFLICT dacă se cere GLB | `TrackChannel jump`; malurile vin din teren |
| dunele din G′ | CONFLICT dacă se cere GLB | relief (`custom_ravines` / cocoașe de teren) + suprafața `SAND` a `TrackBranch` |
| caii | ARE CONSUMATOR (`SlidingHazard.model`) | de verificat: animația `Walk` rulează în *crossing*? |
| tumbleweeds | CONSUMATOR NOU (`HaboobHazard`) | export `model` de la început (lecția `AvalancheHazard._boulder_shapes`) |
| grila pentru vite | CONSUMATOR NOU sau reuse (§3) | decal + GLB plat + zonă de huruit |
| fundalul | ARE CONSUMATOR (`horizon_model`) | cheie de temă nouă |
| `PROP_COLLISION` | intrări noi | `telegraph_pole: trunk`, `wire_fence/raven/tumbleweed/cattle_guard: none`, `trading_post: mesh`, `butte_small_*: hull`, `juniper: trunk`, `sagebrush/rabbitbrush/yucca: none` |

## 6. Bugete

- **Triunghiuri:** raportate, fără plafon. Monoliții sunt mari dar simpli;
  costul real e vegetația rară pe suprafață mare, deci MultiMesh.
- **Materiale:** atlas + ~5 clase (§5.1) + pământ (+1) + haboob (+2–3) +
  decaluri → estimat **~22**, plafon **≤ 30** (garda veto: ≤ 38).
  Comparație: Fiordland 29, Kyoto 29, Serengeti 31.
- **Fizică:** fără corpuri noi. Caii sunt cinematici, tumbleweeds vizuale.
- **Overdraw (riscul GPU):** zidul haboob-ului e o suprafață translucidă
  mare, adică exact ce costă pe mobil. Ordinea de tăiere, scrisă de acum:
  1. particulele de praf, 32 → 16;
  2. quad-urile, 3 → 2;
  3. miez opac `unshaded` + franjuri subțiri;
  4. ceața de „înăuntru” rămâne singurul efect, care e gratuit (e ceața
     mediului, nu geometrie).
- **Umbre pornite** (umbrele monoliților pe câmpie): **prima setare de
  stins** dacă device-ul nu ține 60 fps (CLAUDE.md), apoi `shadow_distance`
  90 → 60.
- **De verificat devreme:**
  1. `Snapshot --overdraw --gamecam --haboob-at=` la 300, 120 și 15 m și
     înăuntru, față de același cadru fără haboob, cu bugetul luat din ploaia
     Fiordland;
  2. pe captura de pe coamă, cu 5 eșantioane (memoria
     `o-captura-nu-e-un-verdict`): Mittens se citesc ca **Mittens**, nu ca
     „două stânci”?
  3. **captură Monument Valley lângă Cappadocia și lângă Dunele.** Dacă par
     aceeași pistă, roșul nu e destul de roșu sau monoliții nu sunt destul
     de verticali;
  4. trecătoarea în contralumină: asfaltul nu devine negru mort.

## 7. Ordinea de construcție

1. **Cod partajat, cu Dunele bit-identică** (ramură proprie, PR propriu):
   - `TrackCliffs` citește `rock_class` din temă (`track_cliffs.gd:521`);
   - `custom_dirt_ranges`: linia de mijloc (`track.gd:5139`), urmele coapte
     (`13360`), bordurile (`13514`) și praful mașinii (`car.gd:1841,1895`)
     întreabă de fracție;
   - ramura de props `monumentvalley` în `track_decor.gd`, altfel se cade pe
     ramura de deșert, cu saguaro (`track_decor.gd:404-467`) și gardul de
     ranch (`track.gd:14714`);
   - albia uscată pentru `TrackChannel`, dacă e nevoie (§3);
   - **uneltele cu index brut** trec pe `resolve_track_index`:
     `probe_reentry`, `probe_fiord_ploaie`, `probe_seethrough`,
     `probe_overtake`, `probe_path_fracs`, `export_track_map`,
     `probe_branch`, `probe_bridge_drive`, `probe_fx`, `probe_sway`.
     `probe_rock_fit` și `probe_decor_overlap` includ 19 și ies cu 1 când
     lista e goală (azi dau „OK” pe zero piste).

   **Dovada:** `ProbeTheme` + `probe_decor` înainte și după, pe toate cele 12
   piste. Diff gol.
2. **`Track19.tscn` din `tools/gen_monument_route.py`** (copie de
   `gen_kyoto_route.py`: pas 12 m, fillet-uri pe arc, **fără oglindire**):
   - garda de azimut scrisă **înaintea** traseului, pentru Mittens de pe coamă
     (≤ 15°, 260–320 m), ambii Mittens în cadru între coamă și poartă (≤ 50° pe ≥ 70%) și soarele față de B
     și E;
   - tema `monumentvalley` în `Track.themes()` (după structura temei kyoto),
     cheia în enum-ul `track_from_path.gd:26-27`, `info/Track19.tres`
     (regiune „SUA”, accent roșu);
   - `custom_name` și `world_seed_name` **înghețate** de la prima generare,
     altfel orice redenumire reamestecă lumea procedurală;
   - pe traseu: `TerrainPeak` + `butte.glb` (Mittens provizorii),
     `custom_gorge_ranges`, `custom_arch_fracs`, `custom_cornice_ravines`,
     `custom_dirt_ranges`, `TrackChannel` (albia), `TrackBranch` (dunele),
     `custom_strata_*`. Hazardele refolosite se pun ca noduri;
   - `GameState`: Track19 se adaugă **la coada listei** (indexul 12), iar
     Dunele rămâne implicită. Toate uneltele o adresează cu `--track=19`
     (`resolve_track_index` o găsește în ambele stări).
3. **Gărzi:**
   - `ProbeLayout --track=19`;
   - `ProbeBuried`;
   - `ProbeLaneClear`: linie de bază „… (Track19)” **fără marjă** și un
     `--sabotaj` care trebuie să pice (memoria
     `garda-fara-linie-de-baza-iese-zero`);
   - `ProbeCameraSolid` armat (pereții trecătorii + arcul).
4. **ProbeRace la început** (memoria `proberace-la-inceput-nu-la-final`): 8
   mașini, 16 seed-uri. Se citesc `[blocaj]` / lent / invers / carusel, nu
   doar repunerile (memoria `zero-repuneri-ascunde-blocajul`).
5. **Tabelul de frustum** (`tools/monument_frustum_table.py`, tiparul
   `fiord_frustum_table.py`, cu ocluzie prin grila de teren): Mittens de pe
   coamă, peretele din D, haboob-ul de pe F (pe un `Path3D` provizoriu),
   reperele de pe H. Garda trebuie să pice pe o stare stricată (memoria
   `garda-circulara-propria-functie`).
6. **Sonda de feel:** un tur singur, cu capturi `--gamecam` de pe coamă, din
   D și din trecătoare. **Verdictul dezvoltatorului la volan** pe pista goală:
   se simte dezvăluirea de pe coamă? Poarta dintre Mittens? Scurtătura prin
   dune e tentantă?
7. **Haboob-ul**, după verdict:
   - `ProbeHaboob` pe o dreaptă: ceas determinist, mediu bit-identic la
     ieșire, `--sabotaj` (fără restaurare) care pică, 6 mașini × 20/30 m/s;
   - `ProbeHaboobPos` pe Track19: traversează doar fracțiile declarate,
     **nu** trece peste `CameraZone` sau arc (`camera_zone.gd:237-304` scrie
     și ea baza ceții, deci s-ar bate), și se vede ≥ 8 s înainte;
   - overdraw (§6);
   - ProbeRace cu și fără `--no-haboob` (tiparul `--no-tub`): țintă +1…+3 s
     pe cursă, zero ieșiri din lume.
8. Prompturile ChatGPT v0.2 pe planul real (§9) → dioramă + planșă de
   inventar → kit Blender (`docs/asset_briefs/monumentvalley_kit.md`,
   `tools/blender/verify_monumentvalley.sh`) → integrare → POI A–H.
9. **Commit-ul de swap**, după decor și după al doilea verdict la volan:
   - Track19 pe indexul 0, Track01 scos din `TRACK_SCENES` / `TRACK_NAMES`,
     cu numele de afișare din §3.1 înghețat;
   - `verify_local.sh` trece pe `--track=19` explicit;
   - cazurile `--mode=cliff` (`CLIFF_FRACS`, `probe_race.gd:186`) se derivă
     din pereții puși, nu din fracțiile Dunelor;
   - gărzile cu cheia „Dunele (Track01)” (`probe_lane_clear.gd:219`,
     `probe_camera_solid.gd:209`) se mută;
   - sondele care au nevoie de Dunele o încarcă **după cale**.

## 8. Lecții aplicate anticipat, și ce a fost respins

- **Patru axe, scrise înaintea traseului.** Coama, poarta dintre Mittens și
  cornișa spre vale sunt **derivate** din tabelul de frustum, nu descoperite
  după construcție.
- **Scara e decizie, nu defect.** Mittens de 45 m în loc de 300 m, asumat.
  Se cere silueta întreagă **de pe coamă** și peretele **în parbriz** pe D,
  nu „monolitul întreg peste tot”.
- **Fără oprire** (lecția semaforului din Fiordland): caii traversează, nu
  blochează pe termen lung; haboob-ul orbește și împinge, nu oprește.
- **Unealta de captură înainte de captură:** `--haboob-at=` intră în
  Snapshot / ProbeRace / ProbeMasca **odată cu clasa**, nu după prima
  captură „ciudată” (memoria `unealta-de-captura-e-parte-din-masuratoare`).
- **Tumbleweeds fără coliziune.** Altfel linia de bază a lui ProbeLaneClear
  depinde de unde e ceasul, iar garda devine nedeterministă.
- **Respectul e regulă de design, nu doar de ton.** Monument Valley e **parc
  tribal al Națiunii Navajo**, iar familii navajo trăiesc în vale. Regulile:
  - nimic ceremonial sau sacru: fără desene pe nisip, fără hogan ceremonial,
    fără figuri sacre;
  - numele formațiunilor cu sens religios (Yei Bi Chei) **nu apar**, doar
    silueta;
  - **niciun om în costum**: caii sunt animale de pășune, fără călăreț
    decorativ;
  - fără modele de bijuterii sau țesături ca textură (sunt proprietate
    culturală);
  - **„Navajo” nu apare în niciun nume** (e marca Națiunii, pe care a
    apărat-o în instanță);
  - caii nu se aruncă, nu cad și nu sunt ragdoll (precedentul e vaca din
    Jodhpur).
- **Legal și nume:**
  - „Monument Valley” nu apare în UI sau în store listing (§3.1.1);
  - „Forrest Gump Point” nu apare (e film);
  - hotelul și postul de negoț reale nu apar cu numele lor;
  - semnele de drum **fără text lizibil**, fără logo-uri, fără mărci de
    mașini.
- **Respins, cu motiv:**
  - **trenul** (nu există cale ferată în Monument Valley);
  - **baloanele** (festivalul de baloane din vale e real, dar baloanele
    sunt ale Cappadociei);
  - **turma de vite / bizoni** (`HerdHazard` e identitatea Serengeti);
  - **traficul de camioane de tur** (traficul cu masă e identitatea
    Jodhpurului; camionul rămâne parcat);
  - **fulgerele** (lovitură telegrafiată pe zonă, adică clasa bombelor din
    Stromboli);
  - **viitura** (torentul din Fiordland; rămâne opțiune, §3.1.5);
  - **Antelope Canyon** (e la Page, la ~200 km; un canion-fantă cere preset
    de cavernă, iar subteranul e al Cappadociei);
  - **Route 66, saguaro, tipi, diligența, saloon-ul** (clișee, și greșite
    geografic sau cultural);
  - **John Wayne și citatele din filme western** (mărci, trade dress).

## 9. Prompt pentru ChatGPT (dioramă de referință) — v0.2, paste-ready

**Se atașează doar `docs/track_briefs/img/monument_plan/monument_plan.png`**,
într-o **conversație nouă**. Planul e captura REALĂ de sus din Godot
(`Snapshot.tscn -- --track=19 --no-fog`, cu fereastră, apoi
`python tools/annotate_monument_plan.py`), cu legenda peste ea. Pista e
sursa de adevăr (memoria `diorama-din-geometria-reala`).

### 9.0 De ce v0.2 cere densitate (verdictul de la volan, 4 oct 2026)

Dezvoltatorul a condus fundația (PR #451): **„săracă; Dunele era mai
lively”**. Cauza se vede pe plan, deci nu ține de gust:

| Dunele | Track19 la fundație |
|---|---|
| pereți de canion pe ~130 de secțiuni, de-a lungul întregii bucle | pereți doar în trecătoarea E (`cliffs_gorge_only`), restul e câmpie deschisă |
| 7 repere pe tur (turn de apă, benzinărie, drive-in, stâlp GAS, moară, baracă, indicator), plus mina și scheletul de dinozaur | 2 repere la start, 3 turnuri placeholder palide |
| butte-uri și stânci la 10–40 m de drum | stâncile mici sunt rare și departe; câmpia e goală |

Valea reală e într-adevăr goală la scară de kilometri. Diorama trebuie însă
să **comprime** viața locului lângă drum, cum face orice pistă de jucărie:
monoliți și mese **aproape**, de mărimi diferite, plus urmele oamenilor
(drum, gard, stâlpi, gospodării, turiști, cai). Prompturile de mai jos o
cer cu **cifre**, nu cu adjective, fiindcă „rich” fără număr iese tot gol.
Interdicțiile din §8 rămân: fără saguaro, tipi, text, logo-uri sau oameni
în costum.

> Create a stylized low-poly **tabletop diorama** of a toy-car racing track in
> **Monument Valley, on the Utah–Arizona border, USA, on a clear late
> afternoon in October**. **Use the attached top-down plan as the exact
> layout: same loop shape, same position of every landmark.** The letters
> A–H, E', G', G2, the circles, red arrows, text boxes and the legend strip
> under the plan are a legend: do not draw them. On the plan: the dark grey
> line is **asphalt road**, the orange line is a **red dirt road**, the red
> triangles show the driving direction, the thick dark-red band (bottom) is a
> **narrow canyon pass**, the thick violet band (left) is a **cliff-edge road**
> with the drop on its right, the orange dashed line (upper middle) is a
> **sandy shortcut over red dunes**, the three dark circles on the right are
> the bases of three **giant rock monoliths**. The pale boxes, the scattered
> small rock cubes and the flat uniform sand colour are placeholders: dress
> everything as described below.
>
> **THE ROAD IS ONE CLOSED LOOP. READ THIS FIRST [!]**
> - There is **exactly one closed loop of road**, shaped like a rounded
>   rectangle about as wide as it is tall, plus **one short sandy shortcut**
>   (G') that leaves the loop and rejoins it. No other roads, no parking lots.
> - The loop runs **clockwise on the plan** (right along the TOP, down the
>   RIGHT side, left along the BOTTOM, up the LEFT side).
> - **Start/finish: on the TOP edge, right of centre**, on a **raised flat
>   plateau** (about 12 m above the valley). The top road (H then A) is
>   **asphalt with a double yellow centre line**, lined with **wooden
>   telegraph poles** and a barbed-wire fence.
> - **TOP-RIGHT corner**: the road turns **down the plan** and drops off the
>   edge of the plateau. **From that crest the whole valley opens up: three
>   huge red rock monoliths stand ahead, slightly to both sides of the road.**
> - **Down the RIGHT side**: a long straight asphalt descent, then a **metal
>   cattle guard** across the road, after which the road becomes **red dirt
>   with tyre ruts** and continues **straight between the two "Mittens"**:
>   **West Mitten on the right of the road, East Mitten on the left**, each a
>   tall flat-topped rock tower with a thin separate spire (the "thumb") on
>   one side, standing on a cone of red scree. **Merrick Butte**, a wider
>   flat-topped tower, stands behind East Mitten, outside the loop. The road
>   passes **between** the Mittens with the rock walls close on both sides.
> - **BOTTOM-RIGHT corner**: the dirt road bends right and runs **left along
>   the BOTTOM edge** through a **narrow canyon between two red mesas**:
>   vertical red walls about 3 car lengths tall on both sides, in shade. At
>   the left end of the canyon the road passes **under a natural sandstone
>   arch** (E').
> - **BOTTOM-LEFT corner**: the road turns **up the plan** and runs along the
>   **edge of a mesa** (violet band): flat mesa top on its left, a steep drop
>   of about 13 m into the valley on its **right**, no guardrail. A small
>   **viewpoint** with a few parked tourist jeeps and tourists with cameras.
> - **Upper LEFT / middle**: the road descends into the **open valley** in wide
>   S-bends (G). The sandy shortcut G' cuts across **red sand dunes** between
>   them. A **dry wash** (a narrow sandy gully with cut banks) crosses the road
>   near the TOP-LEFT corner; the road **jumps over it** on a small earthen
>   ramp (G2). Then the road turns right, becomes asphalt again at a second
>   cattle guard and climbs gently **right along the TOP edge** back to the
>   plateau and the start.
>
> **THE WEATHER EVENT [!]:** a **haboob**, a towering wall of red-brown dust
> about 50 m tall, is rolling in **from the LEFT edge of the base** across the
> upper-left part of the valley, toward the S-bends of G. It has a sharp,
> billowing front lit orange by the low sun and fades to transparent toward
> its back. Show it **half-way in**: it has swallowed the left third of G and
> the shortcut, while the rest of the diorama is in clear sun. Tumbleweeds
> roll ahead of it.
>
> **DENSITY: THIS MUST LOOK ALIVE, NOT EMPTY [!]** (counts are mandatory):
> - **Rock monoliths and mesas of many sizes, close to the road**: besides the
>   three big ones, **12–16 smaller buttes, rock fins and hoodoos** placed
>   10–60 m from the road all around the loop, some in pairs and clusters;
>   **6–8 long flat-topped mesas** forming the background ring of the base.
>   Every monolith stands on a cone of scree with **30+ fallen boulders**.
> - **Vegetation in clusters, never spread evenly**: about **120 low
>   grey-green sagebrush**, **40 dark-green junipers** (twisted, low),
>   **25 yuccas**, and **30 rabbitbrush bushes in bright yellow bloom** (the
>   brightest accent). No cacti of any kind.
> - **Signs of people** (all real to the place, all small): **at the start**,
>   a stone **trading post** with a wooden porch and a rusty pickup in front,
>   a **steel water tower**, a **windmill water pump** with a round steel
>   trough and a few horses drinking; **along the asphalt**, **30+ wooden
>   telegraph poles** with wires and a barbed-wire fence; **2 cattle guards**
>   with yellow diamond signs showing a horse silhouette; **in the valley**,
>   **one family homestead** far from the road (a small modular house, an
>   eight-sided log-and-earth dwelling, a horse corral, a pickup, a water
>   tank); **at the viewpoint** (left side), **3 open-top tour trucks** and
>   **6–8 tourists with cameras**, a **shade ramada** of poles and branches
>   with a table under it; **2 dirt side tracks** wandering off into the
>   desert; **old tyre tracks** across the sand.
> - **Animals**: **8–10 free-roaming horses** (bay, black, pinto) in small
>   groups, two of them crossing the dirt road near the cattle guard; **a flock
>   of 10 sheep** with no shepherd near the homestead; **ravens** on poles and
>   circling; **2 small dust devils** far out in the valley.
> - **Race elements**: **4 toy racing cars** on the track (one on the crest,
>   one between the Mittens, one in the canyon, one in the air over the wash),
>   each trailing a **red dust plume** on dirt.
>
> **CAMERA AND BASE:** raised 3/4 view **from the TOP-RIGHT corner of the
> plan looking toward the bottom-left**, so the start plateau and the crest
> are nearest, the long straight leads the eye to the **Mittens in the middle
> of the image**, the canyon and arch are behind them, and the cliff-edge road
> and the haboob are at the back-left. The diorama sits on a thin dark
> rounded-rectangle base with a matte edge. Behind the base, softly out of
> focus, more mesas and buttes fade into warm haze under a big sky with a few
> large white cumulus clouds.
>
> **STYLE (strict) [!]:** **flat-shaded low-poly, like a game-asset render in a
> Blender viewport. Every face is one flat colour.** Big facets, 1–3 m wide at
> model scale. No painted texture, no photorealism, no tilt-shift look. The
> monoliths read in **three layers**: a **scree slope** at the bottom (striped
> red-brown), a **vertical wall** above it (orange-red, with **vertical
> cracks** and darker drip streaks of desert varnish), and a **thin pale cap**
> on top. Soft baked ambient occlusion under every object. Toy proportions:
> cars are stubby and about 1.3× wider than real cars.
>
> **PALETTE (strict) [!]:**
> - **valley sand: brick red `#C2683A`**, darker `#8E4426` in shade; the dirt
>   road is the **same red**, slightly darker in the ruts (NOT bright orange,
>   NOT a different colour from the ground);
> - monolith walls: orange-red `#B8552E`, glowing `#D9784A` where the sun
>   hits; scree `#8A4A33` with horizontal stripes; caps pale `#B9A08C`;
> - asphalt: blue-black with a **double yellow** centre line;
> - sagebrush `#8E977C`, juniper `#4B5A3C`, rabbitbrush yellow `#D9B23A`;
> - wood and poles weathered grey-brown; trading post stone `#B9A08C`;
> - haboob: red-brown `#A8673E`, lighter at the top;
> - sky: deep blue `#3F79C9` at the top, warm `#F1D3AA` at the horizon.
>
> **LIGHT [!]:** low late-afternoon sun, **about 18°, from the LEFT of the
> plan, slightly toward the bottom**. The west faces of every monolith glow
> orange; **long shadows** fall to the right across the valley floor; the
> canyon pass is in deep shade with sunlit rims.
>
> **FORBIDDEN:** no text or numbers anywhere, no logos, no brand names, no
> saguaro or any cactus, no tipis, no people in costume or feathers, no
> cowboys, no saloons, no stagecoaches, no trains, no hot-air balloons, no
> Route 66 signs.

### 9.1 Prompt pentru ChatGPT (planșa de inventar de assets) — v0.2, paste-ready

Se dă **în aceeași conversație**, după ce diorama e acceptată. Numele de
fișier sunt contractul (categoria `assets/models/monumentvalley/`). Cotele
vin din §2.0 și §5.2 și se remăsoară pe drum la integrare (memoria
`contract-de-kit-cere-latimea-drumului`).

> Now make an **asset inventory sheet** for this diorama, in the same
> flat-shaded low-poly style and palette: every distinct object drawn **once,
> isolated, on a plain light-grey background**, in a neat grid, in a 3/4
> view, all at the **same scale** (a toy car shown for scale in one corner),
> with **small simple text labels under each object using exactly these file
> names** (labels are the only text allowed):
>
> **Hero rocks:** `west_mitten` (45 m incl. scree, with the thumb spire),
> `east_mitten` (42 m), `merrick_butte` (38 m), `mesa_wall_module` (12 × 14 m
> straight cliff section with scree at the foot), `sandstone_arch` (spans a
> 14 m road), `butte_small_a`, `butte_small_b`, `butte_small_c`, `rock_fin`,
> `hoodoo`, `talus_boulders_a`, `talus_boulders_b`.
> **Plants:** `sagebrush`, `juniper`, `yucca`, `rabbitbrush` (yellow bloom),
> `tumbleweed`.
> **Road and people:** `cattle_guard` (steel grid with two end posts, 14 m
> wide), `open_range_sign` (yellow diamond with a horse, no text),
> `telegraph_pole` (with crossbar and wires stub), `wire_fence` (one segment),
> `trading_post` (stone, wooden porch), `water_tower`, `windmill_pump` (with
> round trough), `homestead_house`, `hogan` (eight-sided log-and-earth
> dwelling), `corral`, `shade_ramada`, `pickup_old`, `tour_truck` (open-top),
> `tourist_group` (4 people with cameras, one piece).
> **Animals:** `horse_bay`, `horse_pinto`, `horse_black` (each standing, one
> walking pose), `sheep`, `raven` (wings open).
> **Background:** `horizon_mesas` (a strip of 6 distant mesas and buttes for
> the edge of the world).

## Istoric

- **v0.2 (4 oct 2026):** §9 scris pe planul REAL al lui Track19 (`img/monument_plan/monument_plan.png`), după verdictul la volan „săracă; Dunele era mai lively”. Prompturile cer densitatea cu cifre (monoliți apropiați, vegetație în pâlcuri, urmele oamenilor, cai) și haboob-ul la jumătatea traversării.
- **v0.1.1 (4 oct 2026):** traseul schițat și măsurat (2 100 m). POI D
  devine **poarta dintre Mittens**: ocolul pe arc de rază constantă dădea 0
  din 19 puncte în cadru (§2.0). Fracțiile, cotele și pantele sunt acum
  măsurate.
- **v0.1 (4 oct 2026):** concept. Aleasă dintre Monument Valley / Wadi Rum
  → Petra / Sahara marocană, cu traseul redesenat de la zero (~2,1 km), ca
  înlocuitor al Dunelor pe indexul 0. Hazard unic: haboob-ul. Structura
  (Track19 nou, înregistrare în doi pași, Track01 păstrat ca banc de test) e
  verificată pe cod.
