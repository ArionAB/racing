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
în libertate** traversează drumul. **Ocolești piciorul lui West Mitten**,
peretele de 30 m crescând în parbriz, pe grohotișul de unde se desprind
bolovani, intri în **trecătoarea dintre mese**, un defileu de 12 m în
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
| **West Mitten și East Mitten** (~300 m peste câmpie), cu „degetul mare” ca o turlă lipită de corp | **reperul pistei**: hero GLB pe un `TerrainPeak` de grohotiș, scalate la ~45 m (§2.0). West Mitten se vede întreg de pe coamă, apoi drumul îl ocolește pe la picior (POI D) |
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
- **D ocolește monolitul cu el pe INTERIORUL curbei.** Memoria
  `perete-paralel-nu-se-vede`: un perete paralel cu drumul e la 90°, adică
  în afara cadrului. Doar o curbă care se strânge spre interior ține peretele
  în parbriz. Contract: pe ≥ 70% din punctele lui D, peretele lui West Mitten
  e la ≤ 50° de direcție. Drumul trece la **30–40 m** de piciorul peretelui,
  pe grohotiș (memoria `munte-flanc-nu-fundal`: un masiv se simte doar la
  < 40 m).
- **Trecătoarea E e în contralumină.** E merge spre vest, cu soarele de
  18° în față, dar soarele e **peste** marginea de sus a cadrului (+5,25°),
  deci nu intră în cadru și nu orbește. Pereții sunt în umbră, cu muchia
  aprinsă. **Asta e intenția**: singurul loc întunecat al pistei. Se
  verifică pe captură că asfaltul nu devine o pată (memoria
  `umbra-fara-culoare-e-negru-mort`).
- **Haboob-ul se vede de pe F.** Cornișa F e la **+14** față de câmpie și
  merge spre nord, cu valea G în dreapta-față. Zidul are **50 m** de la cota
  câmpiei, deci +36 față de drumul de pe cornișă. Calculul: 10 + 0,092·d ≥ 36
  ⇒ **d ≥ 283 m** ca să încapă întreg. Între 150 și 280 m se vede tăiat sus,
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
spre siluete, Valley Drive e intrarea în tablou, ocolul lui West Mitten e
peretele care te înghite, trecătoarea e umbra, cornișa e telegraful,
câmpia e furtuna, albia e saltul, US-163 înapoi e drumul acasă.**

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2,1 km** (tur ~70 s, 3 tururi ≈ 3:30, în fereastra
Ignition 65–80 s din `ref_notes/sisteme.md`). **Atenție: runda 1 a
campionatului se lungește** de la ~1:55 (Dunele) la ~3:30. Dezvoltatorul
decide în §3.1 dacă e acceptabil pentru prima impresie.

**Sens orar pe plan:**
- A spre est, pe latura de nord;
- B spre sud, pe latura de est;
- C, D și E spre vest, pe latura de sud;
- F și G spre nord, pe latura de vest;
- H spre est, înapoi pe latura de nord.

Interiorul buclei e valea, cu Mittens-urile în colțul de SE. Convenția de
hartă e cea din `gen_kyoto_route.py` (gx = x, gz = −y, **fără oglindire**):
„dreapta” din brief e dreapta din cadru.

Cote: platoul **+12 m**, câmpia **0 m**, trecătoarea **+4 → +10**, cornișa F
**+14** (punctul cel mai înalt), fundul albiei **−5**, apoi înapoi pe platou
la +12.

Pante (de remăsurat):

| porțiune | cote | lungime | pantă |
|---|---|---|---|
| coborârea B | 12 m | ~260 m | **4,6%** |
| urcarea E | +4 → +10 | ~200 m | **3%** |
| urcarea F | +10 → +14 | ~120 m | **3,3%** |
| coborârea G | +14 → 0 | ~180 m | **7,8%** |
| urcarea H | 0 → +12 | ~250 m | **4,8%** |

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
   [F] cornișa Artist's Point (+14)               ▼
    ▲   valea în dreapta, haboob-ul vine       [D] ocolul lui West Mitten
    │                                             │   peretele pe interior, grohotiș
   [E′] arcul de gresie ◄── [E] trecătoarea dintre mese (+4→+10) ◄─┘
                                defileu de 12 m în contralumină
```

| # | frac | POI | ce se întâmplă | semilățime |
|---|---|---|---|---|
| **A** | 0.00–0.04 | **Start pe platou.** Asfalt, grila de start pe linia dublă galbenă. În stânga, postul de negoț de piatră cu prispă, un pickup vechi parcat, moara de vânt, turnul de apă. Câmpia **nu se vede încă**: buza platoului o ascunde | respiro; viraj larg la dreapta pe buză | 7 m |
| **B** | 0.04–0.17 | **Coama și dreapta US-163.** Treci peste buza platoului și **valea se deschide**: Mittens și Merrick în capăt, pe ax, la 260–320 m (§2.0). Apoi o dreaptă de ~260 m în coborâre, cu stâlpi de telegraf pe dreapta, gard de sârmă și salvie | **momentul-semnătură vizual**. Prima dreaptă de turbo. Coama dă **airtime** dacă geometria o permite (§3, de măsurat); altfel e doar dezvăluire, și e destul | 7 m |
| **C** | 0.17–0.26 | **Grila pentru vite și Valley Drive.** Viraj la dreapta de pe asfalt pe **pământ roșu**, peste grila pentru vite (huruit, §3). Semnul galben cu calul. **Doi cai** traversează drumul la ~37 s | **pragul de suprafață**: grip mai mic, praf roșu. Caii sunt hazardul de traversare | 6,5 m |
| **D** | 0.26–0.40 | **Ocolul lui West Mitten.** Curbă lungă la dreapta (~120°, rază ~70 m) cu **monolitul pe interior**, pe grohotiș, la 30–40 m de piciorul peretelui de 30 m. **Rockfall #1** din grohotiș, pe un traseu desenat (`Path3D`) | **peretele care te înghite** (§2.0). Drift lung, deci **bara de turbo se încarcă**. Bolovanul vine din interiorul curbei, pe linia ideală | 6,5 m |
| **E** | 0.40–0.51 | **Trecătoarea dintre mese.** Culoar spre vest între două mese, pereții `TrackCliffs` de 12 m la 0,8 m de drum (`custom_gorge_ranges`), în contralumină. **Rockfall #2** de pe peretele din stânga | **umbra**, singurul loc închis. Defileul Dunelor, cu un loc real | 5,5 m |
| **E′** | 0.51 | **Arcul de gresie** peste drum, la ieșirea din trecătoare (`custom_arch_fracs`, `rocks/rock_arch.glb` recolorat pe clasa `mv_sandstone`) | **poarta**: ieșirea din umbră în lumină. Libertate declarată (§1) | 5,5 m |
| **F** | 0.51–0.62 | **Cornișa de la Artist's Point.** Urcare scurtă pe buza unei mese (+14), drum de cornișă **fără parapet spre dreapta**, cu valea dedesubt (`custom_cornice_ravines`, cădere de ~14 m). **Haboob-ul se vede** traversând valea, în dreapta-față | **telegraful**: aici decizi dacă tai prin dune sau ocolești. Căzut = repunere (~2 s), cu `RespawnZone` | 6 m |
| **G** | 0.62–0.84 | **Câmpia deschisă.** Coborâre de pe cornișă și drum de pământ peste câmpie, cu S-uri largi. **Haboob-ul traversează porțiunea asta** (§3). Un **vârtej de praf** (`DustDevilHazard`) rătăcește pe câmpie. **Al doilea grup de cai** la ~53 s | **furtuna**: vizibilitate scurtă și vânt lateral când te prinde. Altfel e cea mai rapidă porțiune pe pământ | 8 m (deschis) |
| **G′** | 0.66–0.79 (buclă) | **Scurtătura „Dunele”**: `TrackBranch` peste dunele roșii de la Sand Springs, pe interiorul S-urilor din G, **~25% mai scurtă**. Suprafață `SAND`, `speed_factor` ~0,8, cocoașe de dună care dau salturi mici. Gura e la ieșirea din F, vizibilă de pe cornișă | **risc/recompensă** (principiul 3, **prima scurtătură** a pistei). Câștigul se reglează pe sondă la 0,5–1,5 s, ca la Chasm. Cu haboob-ul peste dune, gura nu se mai vede | 3,5 m (`branch_half_width`) |
| **G2** | 0.80–0.83 | **Săritura peste albia secată.** Wash cu maluri tăiate, adânc de 5 m și lat de ~12 m, peste care drumul sare (`TrackChannel jump`, **fără apă**). Aterizare pe pământ, pe malul opus | **airtime** (principiul 1). Ratat = în albie = repunere (~2 s) | 7 m |
| **H** | 0.84–1.00 | **US-163 înapoi.** Grila pentru vite înapoi pe asfalt, apoi o dreaptă lungă spre est, **în urcare spre platou**, cu soarele în spate. Stâlpi de telegraf, turnul de apă și moara pe ax | **a doua dreaptă de turbo**: aici se arde bara încărcată în D și în dune | 7 m |

**Ritmul turului:**
1. platou (respiro);
2. coama (dezvăluirea);
3. dreapta (turbo, siluetele cresc);
4. grila (pragul de suprafață, caii);
5. ocolul lui West Mitten (drift, peretele, bolovanul);
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
     (≤ 15°, 260–320 m), peretele din D (≤ 50° pe ≥ 70%) și soarele față de B
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
   se simte dezvăluirea de pe coamă? Ocolul lui West Mitten? Scurtătura prin
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

- **Patru axe, scrise înaintea traseului.** Coama, ocolul pe interior și
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

## 9. Prompturile pentru ChatGPT (dioramă + planșă de inventar)

**Se scriu după ce există `Track19.tscn`**, direct în varianta v0.2: pe
captura reală de sus a pistei construite, adnotată, nu pe un plan schematic
(memoria `diorama-din-geometria-reala`; la Kyoto, dioramă v0.1 avea
topologia greșită față de pista construită). Ce trebuie să conțină:
- planul real cu POI A–H și G′;
- regula de artă din §0.1 (diorama stilizată din `style_bible.md`, nu foto);
- cele trei etaje ale monoliților, lumina de 18° din VSV, haboob-ul în
  faza de traversare peste G;
- interdicțiile din §8 (fără text, fără logo-uri, fără saguaro, fără tipi,
  fără oameni în costum).

Planșa de inventar are numele de fișier = contractul (categoria
`assets/models/monumentvalley/`), cu cotele din §2.0 și §5.2.

## Istoric

- **v0.1 (4 oct 2026):** concept. Aleasă dintre Monument Valley / Wadi Rum
  → Petra / Sahara marocană, cu traseul redesenat de la zero (~2,1 km), ca
  înlocuitor al Dunelor pe indexul 0. Hazard unic: haboob-ul. Structura
  (Track19 nou, înregistrare în doi pași, Track01 păstrat ca banc de test) e
  verificată pe cod.
