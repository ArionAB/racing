# Ha Long — contractul per POI pentru gauntlet

> Fișa de lucru a celor **7** perechi constructor/critic. Bara este
> `docs/track_briefs/img/halong_diorama_v1.jpg` (diorama acceptată pe
> măsurătoare), decupată per POI în
> `docs/track_briefs/img/bar_halong/bara_poi_<X>.png`
> (`tools/bar/crop_halong_bar.py`). Planul real al traseului e
> `docs/track_briefs/img/halong_plan/halong_plan.png`; tabelul POI-urilor e în
> `docs/track_briefs/halong.md` §2. Kitul (24 GLB) e în
> `docs/asset_briefs/halong_kit.md`.

## De ce există documentul ăsta abia acum

Decorul Ha Long a fost făcut o dată **fără** gauntlet, pe categorii: o buclă
pentru toată vegetația, una pentru toți parapeții, una pentru dig. 120 de
piese, toate gărzile verzi, bugete sănătoase. Verdictul dezvoltatorului la
volan: *„the track feels empty overall. It is the worst job from all tracks so
far. Did you do each POI on its own?"*

Măsurat **după** întrebarea lui, pe fracție de traseu:

| POI | piese | % din tur |
|---|---|---|
| A cheiul | **3** | 7% |
| B pontoanele | 25 | 19% |
| C digul și grota | 11 | 12% |
| D urcarea + belvedere | 49 | 17% |
| **E coborârea + plaja** | **0** | **21%** |
| **F canalul** | **2** | **10%** |
| G coasta | 30 | 14% |

POI E — o cincime din tur — n-avea **nicio** piesă. A plus F mai iau 20% cu
cinci piese între ele. Media pe toată pista ascundea distribuția, și niciuna
dintre cele patru gărzi scrise atunci nu se uita la acoperire per POI.

**Regula, de aici încolo:** fiecare POI se construiește ca o unitate, dus până
la capăt, judecat pe bucata lui. Garda de acoperire (`ProbePoiCoverage`) pică
dacă un POI rămâne sub prag, oricât de mare ar fi totalul.

## Regula care se încalcă cel mai des

**Bara nu e layout, e look.** Diorama e o machetă comprimată: pune satul,
pontoanele și belvederea într-un singur cadru, iar pista noastră nu face și nu
trebuie să facă asta (traseul real e în `halong_plan.png`, cu gărzile verzi).
Criticul compară **cum arată materia** — cât de îmbrăcat e versantul, cât de
dens e satul, cum arată apa la baza stâncii — nu unde cade fiecare obiect.

Corolar: un critic care spune „la noi satul nu e lângă pontoane" a comparat
layout-ul și a ratat sarcina. Singura diferență care contează e una pe care o
poți repara în decorul POI-ului.

## Trei lucruri din dioramă care NU se iau ca atare

Declarate aici ca să nu le ceară criticul la nesfârșit:

1. **Drumul suspendat pe coama turnurilor.** În dioramă șoseaua urcă pe creste
   de calcar cu pereți verticali de 40+ m. La noi `_lift_peaks` stinge
   masivele lângă șosea (`PEAK_ROAD_CLEAR` 6 m, `PEAK_ROAD_FULL` 32 m), ca să
   nu crească munte peste drum — măsurat pe `TurnGrota`: declarat 58 m,
   terenul real urcă la **+5,4**. Deci pereții de lângă drum vin din **decor**
   (`karst_tower_*`), nu din relief.
2. **Tunelul prin baza turnului.** Golul piesei `grotto_portal` are **8,95 m**
   liberi la cota mașinii; carosabilul are **14 m**. Nu încap, iar la scara
   1,56× piesa ar avea 18 m înălțime, peste tavanul de 11 m al lui
   `CameraGrota`. Decizie deschisă a dezvoltatorului (sapă perete real, sau
   altă piesă cu gol de 14 m).
3. **Scara satului.** În dioramă satul are ~20 de case lipite, văzute de sus.
   La noi e decor de margine la 34–72 m lateral. Se compară **ce se vede de pe
   șosea**, nu macheta.

## Ieșirea din buclă

Aceeași ca la Fiordland (memoria `gauntlet-iesirea-din-bucla`): pe Serengeti
0/8 au câștigat orb, pe Machu Picchu 0/3, pe Fiordland 0/8. O dioramă randată
e o pictură; un cadru low-poly nu o bate orb oricâte runde ar primi.

- **judecata rămâne oarbă** (`tools/bar/blind_pair.py`, o planșă per rundă,
  A sau B, **o singură** diferență numită);
- **ieșirea e** una din: (a) criticul alege a noastră orb; (b) criticul nu mai
  numește nicio diferență **reparabilă în decorul POI-ului**; (c) criticul
  numește **aceeași diferență de două ori la rând** — atunci cauza e sub decor
  (relief, lumină, shader, asset), se **oprește bucla** și decizia merge la
  dezvoltator (memoria `criticul-cere-ce-zona-nu-poate-da`);
- **acceptarea finală e verdictul dezvoltatorului la volan**, pe scena
  integrată.

## Contractul fiecărui POI

Fracțiile sunt din `halong.md` §2. „Ce trebuie să se citească" e ce caută
criticul în decupajul barei.

| POI | frac | ce trebuie să se citească | capcane |
|---|---|---|---|
| **A** cheiul | 0,98 → 0,05 | sat **dens** pe plute: case lipite, țarcuri cu flotoare albastre, bărci legate, plase întinse. Nu trei case răzlețe | satul e **locuit**, nu sărăcăcios (brief §1.3) |
| **B** pontoanele | 0,05 → 0,24 | turnuri mici care ies **drept** din apă, fiecare cu smoc de verde pe vârf și moloz la linia apei; tablierul pe flotoare | nișa de val e contractul turnurilor (§1.1) |
| **C** digul + grota | 0,24 → 0,36 | drum pe zid de piatră la marginea apei, stâncă mâncată la bază, bolovani la poale | grota: vezi excepția 2 |
| **D** urcarea + belvedere | 0,36 → 0,53 | versant **îmbrăcat** în vegetație, cu rocă ieșind în petice; parapet spre gol; pavilion pe vârf | aici erau 48 de piese răzlețe pe nisip gol — densitatea e defectul |
| **E** coborârea + plaja | 0,53 → 0,74 | serpentine pe flanc verde, plajă de nisip la bază, bolovani în apa mică | **zero piese azi** — se construiește de la capăt |
| **F** canalul | 0,74 → 0,84 | apă deschisă între turnuri, jonca cu velă ruginie, bărci mici, turnuri cu poală de moloz | **două piese azi** |
| **G** coasta | 0,84 → 0,98 | șosea tăiată în perete de calcar, maimuțe pe parapet, vegetație agățată pe perete | peretele vine din decor, nu din relief (excepția 1) |

## Ce se măsoară pe scena integrată (niciodată pe worktree-ul POI-ului)

Convenția de indici (memoria `probe-decor-numar-de-scena`): **`probe_decor` ia
numărul de SCENĂ (22); `ProbeRace` și restul iau INDEXUL (14).**

| gardă | comandă | prag |
|---|---|---|
| ProbeRace | `res://tools/ProbeRace.tscn -- --mode=race --track=14 --seconds=170` | **0 `[blocaj]`**; citește și lent/invers/carusel, nu doar repuneri (memoria `zero-repuneri-ascunde-blocajul`) |
| probe_decor | `--script res://tools/probe_decor.gd -- --track=22` | **≤ 38 materiale** (azi 15) |
| ProbePoiCoverage | `res://tools/ProbePoiCoverage.tscn -- --track=14` | **fiecare POI ≥ pragul lui**; un POI gol pică |
| SvHalongCote | `res://tools/SvHalongCote.tscn` | 0 îngropate, 0 plutind |
| SvHalongGabarit | `res://tools/SvHalongGabarit.tscn` | 0 peste gabarit |
| ProbePerf | `res://tools/ProbePerf.tscn -- --track=22 --mobile` | raportat; azi 45 desene (Track08 1088) |

## Gărzi care au trecut peste defecte reale — de ce

Două dintre gărzile scrise în sesiunea fără gauntlet au raportat verde pe
defecte pe care dezvoltatorul le-a văzut imediat la volan. Ambele măsurau o
axă, nu ce vede jucătorul:

- **`SvHalongCote`** avea linia `if gy < sea_y - 1.0: continue` — sărea orice
  piesă de peste apă adâncă, presupunând că e ancorată de linia apei. Adevărat
  pentru bărci, **fals pentru copaci**: ficușii stăteau cu trunchiul în mare
  și garda raporta „0 plutind". **Reparat**: vegetația se verifică separat,
  nu are voie peste apă.
- **`SvHalongGabarit`** măsura distanța orizontală de la ax, cu prag 8 m. Un
  turn de 9–16 m rază așezat la 30 m trece pragul, dar de pe șosea citește ca
  **bolovan pe pistă** — exact ce a raportat dezvoltatorul. Distanța nu e
  același lucru cu „nu pare obstacol".
