# Modul Carieră — „Turul lumii” — v0.9 (brief de design; pasul 0 retunat, pașii 1, 2 și 4a construiți)

> Cerut de dezvoltator pe 16 oct 2026, în perioada de polish pentru release:
> „pornind de la modul Adventure din Crash Team Racing, ce idei ai pentru
> jocul nostru pentru a face modul carieră captivant și să te facă să vrei să
> progresezi?”, apoi „putem începe, scrie în docs și fă un branch separat”.
> Documentul ia modelul CTR (trei treceri pe aceeași pistă, boși, chei), îl
> traduce la principiile noastre (fără items, turbo-resursă, masă, AI onest,
> burst play) și îl leagă de ce există azi în cod (§2). Planul de
> implementare e în §11, deciziile care rămân ale dezvoltatorului în §12.
>
> Monetizarea rămâne nedecisă (`docs/monetizare/model_de_monetizare.md`);
> cariera e proiectată să meargă cu oricare din modelele de acolo, dar e
> croită pe cel recomandat: „gratuit de încercat, plătești o dată pentru tot”.
>
> **v0.1 (16 oct 2026):** analiza din conversație, structura, inventarul
> semnalelor din cod, planul în pași.
>
> **v0.2 (16 oct 2026), decizia dezvoltatorului:** trei lumi de câte 4
> piste — 1 (gratis): Monument Valley, Kyoto, Cappadocia, Serengeti; 2:
> Transfăgărășan, Chongqing, Machu Picchu, Okinawa; 3: Baikal, Stromboli,
> Jodhpur, Fiordland. **Ha Long rămâne deocamdată în afara carierei** (doar
> cursă rapidă). Cerința: „gruparea să poată fi refăcută ușor” — deci lumile
> sunt **date** (o resursă `CareerConfig`, §3), progresul se ține **pe
> pistă**, nu pe lume (§10), iar o regrupare e o editare de `.tres`, zero
> cod, zero progres pierdut. Rivalii refăcuți pe 3 lumi + un rival final (§5).
>
> **v0.3 (16 oct 2026), rezerva dezvoltatorului:** „sunt mașini ca autobuzul
> sau pompierii care sunt încete; indiferent de hartă, mașina care câștigă
> mereu e Poliția”. Verificată cu `ProbeRace` (§2.1): garajul are **două
> clase**, nu șase stiluri — Pompierii și Autobuzul sunt cu 17–27% mai lenți
> pe tur decât trio-ul ușor, pe orice pistă. Un rival în autobuz e un
> pushover și „câștigi mașina rivalului” e un premiu gol. Decizia: **pasul 0,
> echilibrul garajului, înaintea carierei** (§11), cu matricea ca gardă.
> Rivalii (§5) rămân, dar pista fiecăruia o aleg datele, după pasul 0.
>
> **v0.4 (17 oct 2026), decizii:** ce cumpără masa = **(a) hazardele scalate
> cu masa + (b) trece prin turmă/trafic fără să piardă viteza**, bara de
> turbo neatinsă; pragul de veto pe ecart **8%, provizoriu**, se fixează
> după prima rundă de retuning. Pasul 0 pornește cu sonda (`tools/car_balance.sh`),
> apoi retuning-ul A/B.
>
> **v0.5 (17 oct 2026), măsurat:** sonda există — `tools/car_balance.sh`
> (PR #553), toate cele 6 mașini pe aceeași grilă, viteză egală, 12 piste ×
> 2 seed-uri. Rezultat: **Poliția prima pe 12/12**, Pompierii +17–25%,
> Autobuzul +23–35% (§2.1). Prima matrice din v0.3 avea un artefact
> (`speed_scale` 1,0 doar pe slotul jucătorului) — corectată; linia de bază
> „înainte” e `echilibru_garaj_baseline_2026-10-17_viteza_egala.md`.
>
> **v0.6 (17 oct 2026), retunat:** două runde pe ramura
> `cariera/pas0-retuning`, A/B pe aceeași matrice (§2.1.1): ecart **23–35%
> → 5–11% → 3–6% pe 10 piste din 12**; locul 1 împărțit (Poliția 5, Taxi 4,
> Buggy 2, Pompierii 1). Cele două piste rămase peste 8% sunt de gimmick
> (kicker-ul din Serengeti pentru autobuz, gheața din Baikal), nu de mașină.
> Tuning-ul din cifre se oprește aici; urmează verdictul dezvoltatorului la
> volan (§11 pasul 0, ultimul punct).
>
> **v0.7 (17 oct 2026), pasul 1 construit** (PR #556, ramura
> `cariera/pas1-raft`, constructor Sonnet pe brief auto-conținut): lumile ca
> resurse `.tres` (`scenes/career/`), `TrackInfo.id` pe toate cele 16 piste,
> autoload `Career` (progres pe pistă/rival în `user://career.cfg` v1,
> ștampile calculate, read-only pe versiune necunoscută), raftul
> (`CareerPanel`: pașaport, cutii, carduri cu medalii, lacăt), CAREER în locul
> lui CHAMPIONSHIP, medalia cursei după loc + „BACK TO CAREER”, garda
> `ProbeCareer` (130 de verificări, cu sabotaj) în `verify_local.sh` (13/13).
> Pasul 0 a fost merge-uit (#553, #555); verdictul la volan rămâne deschis.
>
> **v0.8 (17 oct 2026), pasul 2 construit** (PR #561, stivuit pe #556):
> semnalele `lap_completed` / `race_finished` pe `Race`, `Car.turbo_recharge`
> (rezervorul sigilat: bara pornește plină și nu se mai încarcă, arderea
> merge), modul TIME_TRIAL în `Career` (singur pe pistă, `ai_count` restaurat
> la ieșire), țintele `tt_gold/silver/bronze_ms` în `TrackInfo` (toate 0 până
> le pune dezvoltatorul la volan), foaia pistei pe raft (RACE / TIME TRIAL /
> CHALLENGE „soon”), rezultatele cu cele trei ținte, eticheta SEALED în HUD.
> Gărzi: `ProbeSealedTurbo` (0,300 → 0,300 sigilat cu 360 de cadre de drift;
> contra-probă 0,300 → 1,000; arderea 0,300 → 0,020) și `ProbeCareer` la 180
> de verificări; `verify_local` 14/14. Contratimpul nu a fost rulat la volan.
>
> **v0.9 (17 oct 2026), pasul 4a construit** (PR #563, stivuit pe #561):
> `CareerChallenge` ca resursă per pistă, `ChallengeTracker` cu regula „zero
> evenimente” abonat la semnalele existente (numără doar jucătorul; hazard
> lipsă = `push_warning`, nu reușită tăcută), modul CHALLENGE (cursă normală
> cu tracker; o condiție per probă, fără medalie de cursă), butonul CHALLENGE
> activ pe foaie, HUD „CHALLENGE: …” / „FAILED”. Cele 7 piste cu semnal:
> Kyoto (aruncat), Stromboli (minge de foc), Serengeti (animal), Okinawa (val,
> prag 0,5: 0,22 în apă / 0,75 creasta), Monument Valley (strivit), Machu
> Picchu (împins de autobuz), Jodhpur (tuk-tuk). Gardă `ProbeChallenge` (99 de
> verificări, sabotaj + contra-probă); `verify_local` 15/15. Rămân pentru 4b
> cele 5 piste care cer semnal nou. Pasul 5 (fantoma) lansat în paralel.

## 0. Într-o propoziție

Mașinuța face turul lumii: un raft cu diorame (trei lumi de câte 4 piste,
gruparea e date, nu cod), fiecare pistă jucată de trei ori cu alt obiectiv
(cursă, contratimp cu rezervor sigilat, provocarea gimmick-ului), fiecare
lume cu un rival 1 contra 1 a cărui mașină o câștigi, iar progresul se numără
în ștampile pe pașaport — orice medalie e o ștampilă, deci niciun obiectiv nu
blochează singur drumul mai departe.

## 1. Ce ține un jucător într-o carieră (și ce luăm din CTR)

Trei resorturi, toate verificate pe CTR (1999) și pe refacerea Nitro-Fueled
(2019):

1. **Următorul lucru e vizibil și la 3 minute distanță.** Pe raft se vede
   mereu ce urmează și ce lipsește („mai ai 2 ștampile”). CTR face asta bine:
   ușile închise din hub se văd de la început.
2. **Poți alege cum ajungi acolo.** CTR face asta prost: Oxide și boșii sunt
   ziduri obligatorii, iar Nitro-Fueled a adăugat un grind de monede. La noi:
   lumea următoare se deschide pe ștampile, iar ștampilele vin din oricare
   din cele trei probe — jucătorul blocat pe o cursă își ia ștampila din
   contratimp sau din provocare.
3. **Recompensa e identitate, nu putere.** Mașină nouă cu alt stil, abțibild
   pe caroserie, pagină de pașaport — niciodată +5% viteză. E principiul 4
   din `CLAUDE.md` și verdictul §3.5 din docul de monetizare.

Ce luăm din CTR: cele trei treceri pe aceeași pistă (înmulțește conținutul
fără piste noi), bosul cu personalitate, progresul vizibil ca procent. Ce nu
luăm: hub-ul condus (scump pentru un solo dev, iar fun-ul e pe pistă), cutiile
de înghețat timpul (turbo-ul e deja resursa), itemele boșilor (avem masă),
moneda și magazinul.

## 2. Starea din cod (16 oct 2026)

Completează §2 din docul de monetizare (13 oct); aici doar ce contează
pentru carieră.

- **Piste**: 15 în `GameState.TRACK_SCENES`; după cele două swap-uri încă
  nefăcute (Monument Valley peste Dunele, Okinawa nouă peste Okinawa manual)
  rămân **13**: Transfăgărășan, Baikal, Stromboli, Chongqing, Cappadocia,
  Serengeti, Machu Picchu, Fiordland, Jodhpur, Kyoto, Monument Valley,
  Okinawa, Ha Long. **În carieră intră 12**: Ha Long rămâne deocamdată doar
  în cursa rapidă (decizia dezvoltatorului, 16 oct). `TrackInfo` are
  `display_name`, `region`, `accent` — **fără `id` stabil**; recordurile au
  cheia pe nume, deci o redenumire pierde recordul (Monument Valley e marcă
  înregistrată, vezi brief-ul §3.1).
- **Campionatul** = primele `CHAMP_ROUNDS = 3` piste din listă, adică azi
  Dunele + Okinawa manual + Transfăgărășan — două din trei sunt piste de scos.
  Cariera îl absoarbe (§7, cupa lumii), butonul CHAMPIONSHIP dispare.
- **Garaj**: 6 mașini (`CAR_DATA`: Muscle, Poliția, Taxi, Autobuzul,
  Pompierii, Buggy), toate deblocate; tuk-tuk-ul e doar trafic pe Jodhpur
  (`max_speed` 18 față de 30–37 — nu poate fi rival fără retuning).

  | Mașină | `max_speed` | `acceleration` | `grip` | `mass_factor` |
  |---|---|---|---|---|
  | Buggy | 35 | 16 | 8,5 | 1,00 |
  | Poliția | 36 | 17 | 10,0 | 0,90 |
  | Taxi | 33 | (implicit 16) | 9,0 | 1,15 |
  | Muscle | 37 | 15 | 7,0 | 1,35 |
  | Pompierii | 32 | 12 | (implicit 8) | 2,00 |
  | Autobuzul | 30 | 11 | (implicit 8) | 2,60 |

- **AI**: 5 adversari, lineup fix `Race.AI_CARS = [Autobuz, Poliția,
  Pompieri, Taxi, Autobuz]`, piloți `PILOTS = ["Tu", "Robo", "Vex", "Luna",
  "Kai", "Nyx"]`. Variația e pe linie (`line_offset` aleator în ±0,28) și pe
  severitatea virajului; AI-ul folosește turbo-ul (`ai_controller.gd` ~639).
  **Fără parametru de dificultate sau de calitate a liniei** — asta e piesa
  nouă pentru rivali (§5).
- **Cursă fără adversari** merge deja: `GameState.ai_count` e variabilă,
  `tools/probe_race.gd --ai=0` o pune pe zero. Contratimpul e la un pas.
- **Persistență**: `user://records.cfg` (tur pe nume de pistă, cursă pe
  `nume@ture`), `user://settings.cfg`. Fără versiune de schemă.
- **Fluxul cursei** e pe funcții, nu pe semnale: `_on_player_lap` →
  `try_record`; `_finish_race` → `try_race_record` + `record_results` (dacă e
  campionat) → `_show_results(title, rows, primary)` → `_on_results_primary`
  → `_show_champion`. `race_finished` / `lap_completed` cerute de `CLAUDE.md`
  există doar în comentarii.
- **Ceasul de off-road**: 3 s pe iarbă (`OFFROAD_LIMIT_S`) și te repune,
  judecat cu `track.is_on_road`. Provocarea „fără iarbă” se citește de aici.
- **Semnale deja emise** (ce poate asculta o provocare fără cod nou în
  hazard):
  - pe `Car`: `boost_started`, `wall_hit(impact)`, `landed(fall_speed)`,
    `respawned`, `bumped(other, delta_v)`, `crushed(severity)`, `ignited`,
    `splashed(strength)`, `blinded`, `ejected`;
  - pe hazarde: `car_thrown` (Gion Matsuri, Shishimai, Shishi-odoshi, Daruma),
    `fireball_hit` (Stromboli), `spun` (vârtej de praf), `animal_hit(mass_ratio)`
    (turmă), `shoved` (autobuzul din Machu Picchu), `bus_hit` +
    `signal_changed(red)` (semaforul de tunel: Fiordland, Transfăgărășan),
    `surfacing` (hipopotam), `phase_changed` (maree, Ha Long), `toppled`
    (hornul crăpat), `erupted`, `rain_changed`.
  - **Fără semnal**: hazardele pe `HazardMarker` (`SLIDING`, `ROCKFALL`,
    `TRAIN`, `TYPHOON`, `WAVE`, `ICE_SLAB`, `TRAIN_ALONG`, `FUMAROLE`),
    telecabina/monorail/pasajul rotativ (Chongqing), baloanele (Cappadocia),
    pontonul (Ha Long), scurtăturile (`TrackBranch`).
- **UI**: QUICK RACE / CHAMPIONSHIP / GARAGE / SETTINGS / QUIT;
  `TrackCard` arată regiunea și recordurile LAP / RACE; `GaragePanel` cu bare
  de statistici; `HUD.show_results(title, rows, primary)`.
- **Fantomă (replay)**: nu există.

## 2.1 Echilibrul garajului, măsurat (16–17 oct 2026)

Observația dezvoltatorului, la volan: „indiferent de hartă, mașina care
câștigă mereu e Poliția; autobuzul și pompierii sunt încete”. Verificată
cu `tools/car_balance.sh` (PR #553): toate cele 6 mașini pe aceeași grilă
(`ProbeRace --ai-cars=1,2,3,4,5`), același `AIController` la volanul
tuturor, **viteză egală** (`--equal-speed`), 240 s/cursă, 2 seed-uri, pe
toate cele 12 piste din carieră. **Cel mai bun tur, în secunde**, minimul
pe seed-uri; în paranteză, ecartul față de cea mai rapidă mașină a pistei:

| Mașină | Mon. Valley | Kyoto | Cappadocia | Serengeti | Transfăg. | Chongqing | Machu P. | Okinawa | Baikal | Stromboli | Jodhpur | Fiordland | locul 1 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Poliția | **60,5** | **62,5** | **68,5** | **69,3** | **65,7** | **63,2** | **67,8** | **58,9** | **50,9** | **68,2** | **64,5** | **63,9** | **12** |
| Muscle | 61,6 (+2%) | 64,1 (+3%) | 73,2 (+7%) | 71,1 (+3%) | 69,2 (+5%) | 64,2 (+2%) | 70,2 (+4%) | 61,0 (+4%) | 52,8 (+4%) | 68,7 (+1%) | 66,5 (+3%) | 67,1 (+5%) | 0 |
| Buggy | 61,6 (+2%) | 64,7 (+4%) | 70,8 (+3%) | 73,0 (+5%) | 68,1 (+4%) | 65,5 (+4%) | 70,0 (+3%) | 61,6 (+5%) | 52,8 (+4%) | 68,9 (+1%) | 66,6 (+3%) | 65,9 (+3%) | 0 |
| Taxi | 64,0 (+6%) | 66,8 (+7%) | 71,4 (+4%) | 74,7 (+8%) | 70,2 (+7%) | 67,9 (+7%) | 71,8 (+6%) | 64,2 (+9%) | 53,2 (+4%) | 71,5 (+5%) | 69,1 (+7%) | 69,2 (+8%) | 0 |
| Pompierii | 72,5 (+20%) | 75,8 (+21%) | 83,5 (+22%) | 87,0 (+25%) | 79,0 (+20%) | 77,5 (+22%) | 81,9 (+21%) | 71,6 (+22%) | 59,7 (+17%) | 79,6 (+17%) | 77,2 (+20%) | 79,2 (+24%) | 0 |
| Autobuzul | 77,0 (+27%) | 81,8 (+31%) | 92,3 (+35%) | *fals* | 85,3 (+30%) | 83,0 (+31%) | 86,8 (+28%) | 77,9 (+32%) | 67,1 (+32%) | 84,1 (+23%) | 82,2 (+27%) | 83,9 (+31%) | 0 |
| *ecart* | 27% | 31% | 35% | 25% | 30% | 31% | 28% | 32% | 32% | 23% | 27% | 31% | |

Raportul complet, cu blocajele și repunerile fiecărei mașini pe fiecare
pistă, e în `echilibru_garaj_baseline_2026-10-17_viteza_egala.md` — **linia
de bază „înainte”** pentru A/B-ul de la pasul 0 (24 de curse, ~85 s
fiecare, headless, ~35 min; e gardă la cerere, nu ceremonie).

**Corecție față de prima măsurătoare (16 oct).** Prima matrice (4 piste,
`ProbeRace --car=N`, păstrată în `echilibru_garaj_baseline_2026-10-16.md`)
dădea Muscle/Buggy primele și Poliția la +2–4%. Era un artefact: `ProbeRace`
dă adversarilor de grilă `speed_scale` 0,88–0,97 (variația onestă a AI-ului)
și lasă slotul jucătorului la 1,0 — corect când măsori pista, dar slotul
jucătorului (Muscle sau Buggy în acele rulări) pornea cu 3–12% avantaj. La
viteză egală ordinea e exact cea de la volan (memoria
`proberace-speed-scale-contamineaza-comparatia`).

### 2.1.1 Rundele 1–2 de retuning (17 oct 2026, ramura `cariera/pas0-retuning`)

Aceeași matrice, aceleași 12 piste × 2 seed-uri; rapoartele complete în
`echilibru_garaj_runda1_2026-10-17.md` și `echilibru_garaj_runda2_2026-10-17.md`.

| Mașină | viteză / accel / grip (înainte → runda 2) | ecart înainte | runda 1 | runda 2 | locul 1 (r2) |
|---|---|---|---|---|---|
| Poliția | 36/17/10 → **34,5**/17/**9,5** | — (12/12) | 0…+2% | 0…+3% | **5** |
| Taxi | 33/16/9 → **35**/16/9 | +4…+9% | 0…+6% | 0…+5% | **4** |
| Buggy | 35/16/8,5 + **off-road 0,65** | +1…+5% | +1…+6% | 0…+6% | **2** |
| Pompierii | 32/12/8 → **35/15**/8 | +17…+25% | +1…+7% | 0…+5% | **1** |
| Muscle | 37/15/7 → **36**/15/**7,5** | +1…+7% | +1…+11% | 0…+3% | 0 |
| Autobuzul | 30/11/8 → **35/14,5**/8 | +23…+35% | +5…+11% | +2…+6% | 0 |
| *ecart pe pistă* | | **23–35%** | 5–11% (Baikal 32%) | **3–6%** pe 10/12 | |

Masele n-au fost atinse (`--mode=bump` identic). Ce a decis fiecare rundă:

- **Runda 1** a strâns viteza maximă în 34,5–36 și a dat celor grele
  accelerație (cu drag 0,35, viteza lor terminală accel/drag era 31–34 —
  se târau spre plafon; acum 40–43). A tăiat accelerația Muscle-ului la 14
  ca „cruiser”: **greșit**, a devenit cel mai lent pe 5 piste — pe pistele
  noastre, întoarse, accelerația și grip-ul bat plafonul. Și a arătat că
  **Baikal** (gheața acumulează stres proporțional cu masa, 0,29 s până la
  rupere pentru autobuz) e singura pistă unde masa pedepsește direct timpul.
- **Runda 2** a dat Muscle-ului înapoi 15 și grip 7,5, autobuzului 35/14,5,
  Poliției grip 9,5, și a comprimat masa din stresul gheții (√: autobuzul
  161, Poliția 95 — ordinea rămâne, gimmick-ul trece cu orice mașină).
- **Cele două veto-uri rămase sunt de gimmick, nu de mașină**: Serengeti 10%
  (autobuzul, 13 repuneri pe kicker-ul `FlyoffRamp` — nu are viteza să-l ia
  nici acum), Baikal 20% (13–22 repuneri pentru toate mașinile; cel mai bun
  tur al Poliției și al autobuzului include repuneri — zgomot pe 2 seed-uri).
  Se tratează ca pasabilitate (§11 pasul 0, „gimmick-urile trec cu orice
  mașină”), nu prin alte cifre în `CarData`.
- **Ce cumpără masa, (a)**: `Car.hazard_mass_ratio` = clamp(135/masă, 0,4–1)
  — 1,0 până la Muscle (mașina implicită, pe care s-au măsurat contractele),
  Pompierii 0,68, Autobuzul 0,52; doar reduce. Aplicat în vârtej, taifun,
  macara, monorail. Kyoto și turma aveau deja raportul lor (referința 100).
  Împingerile cu forță × masă (balon, arzător, telecabină, haboob) rămân
  neutre — fiecare are un contract măsurat ca accelerație, se decide la
  volan dacă merită. Orbirea nu se scalează: e a șoferului.
- Matricea măsoară **potențialul** mașinii cu AI-ul la volan, nu
  accesibilitatea ei pentru om; de aceea tuning-ul din cifre se oprește la
  runda 2 și verdictul e al dezvoltatorului, pe fiecare mașină, pe 3 piste.

Ce spun cifrele:

- **Poliția e prima pe 12 din 12 piste.** Exact observația de la volan.
  Muscle și Buggy la +1–7%, Taxi +4–9%: un trio-plus-unu în 10%. Pompierii
  +17–25% și Autobuzul +23–35%: **o clasă separată, cu un sfert mai lentă pe
  tur, pe orice pistă** — pe o cursă de 3 tururi, 50–80 s în urmă. Nicio
  pistă nu echilibrează asta: viteza se plătește pe fiecare metru, masa
  (singurul lor atu) doar la contact. Principiul 4 („alegerea mașinii =
  alegerea stilului”) e azi un slider de dificultate.
- **Nu e o pistă care s-o favorizeze pe Poliție** — nici serpentinele
  (Transfăgărășan +5% față de Muscle), nici drepte lungi (Chongqing +2%),
  nici gheața (Baikal +4%). Accelerația 17 + grip 10 + 0,9 masă câștigă
  peste tot fiindcă nu plătesc nimic în afara contactului.
- **Mașinile grele pică și gimmick-urile.** Autobuzul: 18 repuneri pe
  kicker-ul `FlyoffRamp` din Serengeti (nu are viteza să-l ia), blocaje pe
  Chongqing (3) și Stromboli (3); Pompierii, 3 blocaje pe Machu Picchu —
  pantele. Echilibrul nu e doar timp pe tur, e și „poate mașina asta să
  treacă de fiecare gimmick”.
- **Baikal: 11–29 repuneri pentru toate mașinile** (plăcile de gheață) —
  proprietate a pistei, nu a mașinii; cele rapide cad mai des (Muscle 29,
  Poliția 25, Pompierii 11). Nu intră în echilibru, dar e cifra pe care o
  verifici când retuning-ul schimbă vitezele.
- **Descoperire colaterală, de tratat separat**: pe Serengeti autobuzul are
  un „tur” de 15,8 s (16 oct: 17,8 s), imediat după o repunere lângă linia
  de start. Ipoteza: repunerea peste linie numără un tur. Dacă e așa,
  `try_record` poate salva un record fals și pentru jucător (recover după
  off-road lângă linie). Sonda îl respinge acum singură (sub jumătatea
  medianei pistei = fals), dar fix-ul e în `Race` — issue separat (§12.8).

Consecința pentru carieră: **rivalii (§5) și „câștigi mașina rivalului” cer
ca fiecare mașină să fie cea mai bună undeva.** Cariera nu creează problema,
dar o scoate la lumină la fiecare rival și la fiecare țintă de contratimp
(care ar fi atinsă doar de Poliție). De aceea echilibrul e pasul 0 din §11.

## 3. Structura: raftul cu lumi și pașaportul

**Raftul.** Ecranul carierei e un raft cu cutii de jucării — câte una per
lume, în stilul dioramei din `docs/style_bible.md`. Cutia deschisă arată cele
3–4 piste ale lumii ca `TrackCard`-uri cu medaliile lor; cutia sigilată arată
numele lumii, silueta și „mai ai N ștampile”. E un ecran 2D (Control), nu un
hub 3D condus.

**Lumile** (decizia dezvoltatorului, 16 oct 2026): 12 piste în trei cutii
de câte 4, Ha Long în afara carierei deocamdată.

| # | Lume | Piste | Gratis |
|---|---|---|---|
| 1 | *(nume de ales — §12)* | Monument Valley, Kyoto, Cappadocia, Serengeti | **da** |
| 2 | *(nume de ales)* | Transfăgărășan, Chongqing, Machu Picchu, Okinawa | nu |
| 3 | *(nume de ales)* | Baikal, Stromboli, Jodhpur, Fiordland | nu |

Lumea gratuită e cea din modelul de monetizare recomandat; de aceea trebuie
să conțină **toată bucla**: cursă, contratimp, provocare, rival și o mașină
câștigată (§8).

**Gruparea e date, nu cod** (cerința: „să poată fi refăcută ușor”). O
resursă `CareerConfig` (`resources/career/career_config.tres`) ține lista de
lumi; fiecare lume e o resursă `CareerWorld` cu `id`, `display_name`,
`tracks: Array[StringName]` (id-uri de pistă, §10), `rival` (§5), `free:
bool`, `stamps_to_unlock`. Regulile care decurg de aici:

- **a regrupa = a edita un `.tres`**, zero cod; o pistă poate fi mutată, o
  lume adăugată sau scoasă, Ha Long introdus mai târziu;
- **progresul se ține pe pistă** (medalii, provocare, timp) și pe `id` de
  rival, **niciodată pe lume** — deci o regrupare nu pierde nimic și nu
  cere migrare; ștampilele se recalculează din ce e pe piste (§10);
- lumea gratuită e cea cu `free = true`, nu „prima din listă”; garda
  `ProbeCareer` verifică că exact una e gratuită și că lumile nu împart
  piste;
- o pistă din `TRACK_SCENES` care nu apare în nicio lume e doar cursă
  rapidă (Ha Long azi) — nu e eroare, e starea normală a unei piste noi până
  o pui într-o cutie.

**Pașaportul.** Fiecare medalie, de orice culoare, pe orice probă, plus
fiecare rival învins, e o **ștampilă**. Lumea următoare se deschide la un
prag de ștampile cumulat (`stamps_to_unlock` pe fiecare `CareerWorld`;
propunere de pornire, de tunat la volan: lumea 2 la 6, lumea 3 la 14;
maximul e 12 piste × 3 probe + 3 rivali + rivalul final = 40). Pragurile
sunt alese ca o lume să se poată deschide **fără niciun aur și fără rivalul**
lumii curente — rivalul dă mașina, nu cheia. Pașaportul e și ecranul de
progres: ștampile, medalii pe culori, mașini, abțibilduri, procent.

## 4. Cele trei probe pe fiecare pistă

Aceeași pistă, trei abilități diferite; 12 piste devin 36 de obiective fără
conținut nou.

### 4.1 Cursa

Cursa de azi: 3 tururi, 5 AI. Medalie după locul final: **aur** = 1,
**argint** = 2, **bronz** = 3. Nimic sub 3, dar cursa se poate repeta
oricând. Nu se atinge nimic din feel.

### 4.2 Contratimpul cu rezervor sigilat

Singur pe pistă (`ai_count = 0`), 3 tururi. Pornești cu bara de turbo plină
și **nu se mai încarcă** pe toată proba (un steag pe `Car`, `turbo_recharge =
false`, nimic altceva nu se schimbă). Asta e echivalentul Relic Race, dar
măsoară exact skill-ul de decizie din principiul 2: pe ce dreaptă, înaintea
cărei sărituri, în ce tur arzi rezervorul. Drift-ul rămâne unealtă de viraj,
doar că nu mai hrănește bara.

Țintele: trei timpi pe pistă în `TrackInfo` (`tt_gold_ms`, `tt_silver_ms`,
`tt_bronze_ms`), export vars, **stabiliți de dezvoltator la volan** — aurul e
un timp pe care el îl face curat, argintul ≈ aur × 1,06, bronzul ≈ aur × 1,15
ca punct de pornire. Nu se calculează din AI: AI-ul nu conduce cu rezervor
sigilat. Pe ecranul de rezultate: timpul tău, cele trei ținte, care a căzut.

Recordurile existente pe tur și pe cursă rămân cum sunt (cursa normală);
contratimpul își ține recordul separat, fiindcă regula e alta.

### 4.3 Provocarea gimmick-ului

Fiecare pistă are gimmick-ul ei, deci provocarea e **unică per pistă și e
scrisă cu numele lui** (memoria `garda-cu-numele-gimmickului`: contractul ca
cifră). Se joacă în cursă normală, cu adversari; condiția se verifică de un
`ChallengeTracker` care ascultă semnale (§2) și numără. Reușita dă o
ștampilă și un **abțibild** care se lipește pe mașina jucătorului — cosmetic
câștigat, nu cumpărat, vizibil în garaj și în cursă.

Propuneri, cu ce semnal există deja și ce trebuie adăugat. Cele 8 cu semnal
existent se fac primele.

| Pistă | Gimmick | Provocare (contract) | Semnal |
|---|---|---|---|
| Okinawa | taifunul + valul care spală șoseaua | termină cursa fără să te ia valul (0 × `splashed` peste prag) | **există** `Car.splashed` |
| Ha Long *(în afara carierei deocamdată)* | pontonul + mareea | traversează pontonul la maree înaltă în fiecare tur | `tide.phase_changed` există; lipsește „ești pe ponton” |
| Stromboli | gheizerele de foc + lava care crește pe tururi | 3 tururi fără nicio minge de foc | **există** `fireball_hit` |
| Kyoto | carul de Gion + shishimai | nu te lasă aruncat niciodată | **există** `car_thrown` |
| Chongqing | telecabina + pasajul rotativ | prinde telecabina în fiecare tur | de adăugat pe `CablewayHazard` |
| Jodhpur | traficul de tuk-tuk-uri + porțile | 3 tururi fără să lovești un tuk-tuk | **există** `Car.bumped` (tuk-tuk-urile sunt `Car`) |
| Serengeti | turma + hipopotamul + vârtejul | 3 tururi fără să lovești un animal | **există** `animal_hit` |
| Monument Valley | haboob-ul + bolovanii de pe buză | treci de bolovani fără să fii strivit | **există** `Car.crushed` |
| Cappadocia | stânca goală cu spirala + baloanele | spirala fără să atingi peretele, 3 tururi | `Car.wall_hit` există; lipsește zona „în spirală” (`CameraZone` o are deja) |
| Transfăgărășan | semaforul de tunel + autocarul | treci pe roșu de 3 ori și nu te lovește autocarul | **există** `signal_changed`, `bus_hit` |
| Machu Picchu | autobuzul pe serpentine | depășește autobuzul fără să te împingă | **există** `shoved` |
| Baikal | plăcile de gheață crăpate | un tur fără să spargi o placă | de adăugat pe `IceFieldHazard` |
| Fiordland | scurtătura „drumul vechi din pădure” + torentul | ia scurtătura în toate cele 3 tururi | de adăugat pe `TrackBranch` (`branch_taken`) |

Regula de scriere: provocarea cere **ceva ce AI-ul nu face** (ocolește
riscul, sau îl ia conștient), ca jucătorul să aibă de ce să joace altfel
decât în cursă. Nu cere locul 1 în plus — ar fi dublă condiție, a doua
ștampilă ar costa cât două.

## 5. Rivalii

Boșii din CTR aruncă obiecte; noi avem masă și linie. Fiecare lume are un
**rival**: o mașină cu pilot și caracter, 1 contra 1, 3 tururi, pe o pistă a
lumii. Când îl învingi, **mașina lui intră în garajul tău**. E recompensa
centrală: ai văzut-o 3 minute cum conduce altfel decât tine, acum o ai.

**Condiționat de pasul 0 (§2.1, §11).** Cu garajul de azi, un rival în
Pompieri sau în Autobuz e cu un sfert mai lent pe tur: îl depășești pe
prima dreaptă și proba s-a terminat. Rivalii se proiectează **după**
echilibru, iar pista fiecăruia o alege **matricea**: rivalul rulează pe
pista din lumea lui pe care mașina lui e cea mai rapidă (sau cel mai
aproape de cea mai rapidă). Dacă după pasul 0 o mașină tot nu e prima
nicăieri, nu e rival — se câștigă din cupa lumii (§7).

Garajul de start: **Buggy + Taxi** (ușoară și agilă / echilibrată — cele două
stiluri de bază). Trei lumi, deci trei rivali din ce în ce mai grei, plus un
**rival final** care se deschide după ce i-ai învins pe toți trei — așa
toate cele 6 mașini se câștigă prin joc. Perechile pilot–mașină sunt cele
din grila de azi (`Race.AI_CARS` × `PILOTS`: Vex conduce Poliția, Luna
Pompierii, Robo Autobuzul), ca jucătorul să-i recunoască:

| Lume | Rival | Mașină | Caracterul la volan | Ce te învață |
|---|---|---|---|---|
| 1 | **Vex** | Poliția (0,9; grip 10) | driftează curat, ține turbo-ul pentru dreapta mare | drift ca unealtă de viraj, turbo pe decizie |
| 2 | **Luna** | Pompierii (2,0) | te împinge la contact, nu cedează linia | cum te ferești de o masă dublă, când o folosești |
| 3 | **Robo** | Autobuzul (2,6) | blochează; pe banda îngustă n-ai pe unde | răbdare, linie și scurtătura pe care el n-o poate lua |
| final | **Nyx** | Muscle (1,35; viteză 37) | cel mai rapid pe drepte, slab în viraj strâns | unde câștigi un viraj contra unei mașini mai rapide |

Pistele rivalilor nu se scriu aici: ies din matricea de după pasul 0 și
stau în `CareerWorld` (`rival`, `rival_track`), deci se mută odată cu
gruparea. Propunerile de stil (Vex pe virajele strânse din Kyoto, Luna pe
serpentinele din Machu Picchu unde autobuzul-hazard deja împinge, Robo pe
Fiordland unde blocajul e bătut de scurtătură, Nyx pe Monument Valley ca
să închidă bucla pe prima pistă) sunt ipoteze de verificat cu cifra, nu
decizii.

Numele sunt cele din `Race.PILOTS`, ca piloții să fie aceiași în cursă și
ca rivali (jucătorul îi „cunoaște” deja din grilă).

**Ce cere în cod, și de ce rămâne onest.** Rivalul rulează aceeași fizică și
aceeași `CarData` ca mașina pe care o vei primi — nicio viteză trișată
(principiul 5). Diferența față de un AI de grilă e **calitatea**, nu
numerele:
- `line_offset = 0` (linia ideală, nu ±0,28 aleator) și pragurile de turbo
  cele mai bune — un buton „calitate a liniei” pe `AIController`, care azi nu
  există;
- un comportament de **apărare** pentru rivalii grei (Kai, Robo): când
  mașina din spate e pe aceeași bandă și aproape, rivalul se mută pe linia
  ei. E comportament nou, mic (o regulă peste `_avoid_line`), și e exact ce
  face autobuzul interesant — fără el, un autobuz cu `max_speed` 30 e depășit
  pe prima dreaptă și proba s-a terminat;
- rivalul pornește din pole, jucătorul din spate.

Rivalul apare pe raft de la 2 ștampile din lumea lui, ca să nu fie prima
cursă pe care o vezi acolo; rivalul final apare când cei trei sunt învinși.

Garda: `ProbeRace` cu rivalul contra AI-ului de grilă pe aceeași mașină —
rivalul trebuie să iasă **măsurabil mai rapid pe distribuție** (memoria
`proberace-nedeterminism`: compară distribuții, nu o rulare), altfel butonul
de calitate nu e conectat.

## 6. Fantoma

În contratimp, la fiecare record personal se înregistrează
`global_transform`-ul mașinii la 20 Hz (3 tururi × ~70 s × 20 × 28 B ≈ 120
KB) în `user://ghosts/<track_id>.bin` și se redă ca model fără coliziune,
semitransparent. Două fantome disponibile: **a ta** (record personal) și
**a rivalului lumii**, după ce l-ai învins — același conținut, al doilea
rol. Fantoma „dev” (timpul de aur) e opțională: ar însemna să livrăm 13
fișiere cu jocul; de decis după ce există cele două.

E cel mai ieftin „încă o tură” din orice racer și e 100% local, fără
server.

## 7. Cârlige secundare

- **Cupa lumii**: campionatul cu puncte de azi (`champ_points`,
  `CHAMP_POINTS`), pe cele 3–4 piste ale lumii, cu lineup-ul normal. Nu
  blochează nimic; dă pagina completă de pașaport a lumii (set de abțibilduri)
  și înlocuiește butonul CHAMPIONSHIP, care azi joacă două piste de scos.
- **Provocarea zilei**: pistă + mașină + regulă (rezervor sigilat / fără
  iarbă / mașina grea) alese dintr-un seed derivat din data curentă. Fără
  clasament, fără cont; se ține un „serial” de zile la rând. Ieftin și respectă
  „zero server”.
- **Provocarea semnăturii** per mașină: „Autobuzul pe Transfăgărășan”,
  „Buggy pe Baikal” — te obligă să înveți toate stilurile, nu să rămâi pe
  favorită. Dă abțibild.
- **Sens invers** ca deblocare târzie: dublează pistele, dar hazardele și
  waypoint-urile AI sunt direcționale (trenul pe sens, semaforul de tunel,
  deflectorul) — se verifică pistă cu pistă cu `ProbeRace` înainte să intre;
  nu e gratis și nu intră în v1 fără dovadă.
- **Turul complet**: toate aururile de contratimp + toate abțibildurile +
  toate mașinile = 100% în pașaport. Echivalentul lui 101% din CTR.

## 8. Legătura cu monetizarea

Cu modelul recomandat (gratuit de încercat, o plată pentru tot), **cutia cu
`free = true` (Lumea 1: Monument Valley, Kyoto, Cappadocia, Serengeti) e
gratis și conține toată bucla**: 4 piste × 3 probe, un rival (Vex), o
mașină câștigată (Poliția), abțibilduri. Plata e a doua cutie sigilată, pe
care o vezi de la început. Jucătorul plătește după ce a simțit
tot, nu ca să afle ce e. Dacă modelul ales e premium pur, cutiile se deschid
toate pe ștampile și nimic nu se schimbă în cod în afara gardei de
deblocare.

Nimic din carieră nu introduce monedă, consumabile sau upgrade-uri —
abțibildurile sunt singurul „inventar” și se câștigă doar prin joc.

## 9. Ce evită designul (lecțiile CTR)

- **Zidul unic** (Oxide, boșii obligatorii) → ștampile cumulate din trei
  probe; rivalul dă mașina, nu cheia.
- **Grind-ul de monede** (Nitro-Fueled) → fără monedă; docul de monetizare
  §3.5 și §3.9 o respinge deja.
- **Upgrade-uri de statistici ca progresie** → nu: ar strica AI-ul onest
  (ținta de viteză e `car.max_speed`) și identitatea mașinilor.
- **Hub-ul condus** → raft 2D; fun-ul e pe pistă, nu între piste.
- **Două condiții pe o ștampilă** (CTR cere literele *și* locul 1) → o
  condiție per probă.

## 10. Date și persistență

Un fișier nou, `user://career.cfg`, `ConfigFile` ca `records.cfg`, cu
**versiune de schemă** (`[meta] version = 1`) — lipsa ei la recorduri e deja
o capcană. Cheile pe un **`id` stabil** nou în `TrackInfo` (`okinawa`,
`halong`, …), nu pe `display_name`; recordurile vechi pe nume rămân cum sunt
și se migrează o dată la primul start, pe mapare nume→id.

```
[meta]       version = 1
[track:kyoto]     race_medal = 2   tt_medal = 1   tt_best_ms = 183420   challenge = true
[rival:vex]       beaten = true
[cup:world_1]     won = false
[garage]     unlocked = ["buggy", "taxi", "police_sports"]
[stickers]   kyoto = true
[daily]      last_date = "2026-10-16"   streak = 4
```

Cheile sunt **pe pistă și pe rival**, nu pe lume: o regrupare (§3) mută
pistele între cutii fără să atingă fișierul. Singura cheie pe lume e cupa
(`[cup:<world_id>]`), care chiar aparține grupării — dacă lumea dispare,
cupa ei devine orfană și se ignoră, nu strică nimic. Ștampilele nu se
stochează: se **calculează** din medalii + rivali, ca să nu poată diverge.
`CareerState` e un autoload nou (`scripts/autoload/career.gd`), nu încă un
bloc în `GameState` (care are deja garaj, campionat, touch, setări,
recorduri); citește `CareerConfig` la pornire și expune `worlds()`,
`stamps()`, `is_unlocked(world)`.

## 11. Planul de implementare, în PR-uri mici

Fiecare pas are o gardă headless, ca restul proiectului; capturile de UI se
fac cu fereastră (memoria `snapshot-nu-merge-headless`).

0. **Echilibrul garajului** (înaintea carierei; §2.1, decizia
   dezvoltatorului din 16 oct). Retuning în `CarData`, export vars, fără
   sisteme noi — feel-ul se găsește prin iterare:
   - **viteza maximă strânsă în ≤5%** (34–36): 30 față de 37 nu se
     recuperează cu nimic;
   - **trade-uri pe axe care se plătesc pe fiecare metru**: Poliția =
     sprinter (accelerația cea mai mare, viteza maximă cea mai mică, cea mai
     ușoară — pierde cel mai mult la contact și la hazarde); Muscle =
     cruiser (viteză maximă, accelerație slabă, grip 7); Taxi = echilibrat;
     Buggy = agil + **off-road** (pierde mai puțin din cei 45% pe
     iarbă/nisip — e un buggy);
   - **masa plătește și fără contact**, altfel Pompierii și Autobuzul n-au
     ce vinde. **Decis (17 oct):** (a) hazardele scalate cu masa —
     `car_thrown`, `spun`, `splashed`, `blinded` aplică efectul ×
     1/`mass_factor`, autobuzul nu e aruncat de carul de Gion; (b) trec prin
     turmă, tuk-tuk-uri și bolovani fără să piardă viteza (`animal_hit`
     deja poartă `mass_ratio`). Respins: rezervor de turbo mai mare — bara
     de turbo e identitatea comună a jocului și nu se atinge per mașină;
   - **gimmick-urile trebuie să treacă cu orice mașină**: autobuzul se
     înțepenește azi pe kicker-ul din Serengeti (§2.1).

   *Gardă:* `tools/car_balance.sh` (PR #553) — matricea din §2.1 ca sondă, pe toate cele
   12 piste din carieră, cel puțin 2 seed-uri (nedeterminism), raportată ca
   tabel în log. Trei praguri: (i) **veto**: ecartul de best lap pe o pistă
   între cea mai rapidă și cea mai lentă mașină ≤ 8%, provizoriu până după
   prima rundă de retuning (azi 23–35%); (ii)
   **veto**: nicio mașină cu blocaje/repuneri pe gimmick peste linia de
   bază a pistei din `ProbeRace`; (iii) **raportat, nu veto**: fiecare
   mașină cea mai rapidă pe cel puțin o pistă — asta e ținta de design, dar
   un prag de veto pe ea ar cere ceremonie la fiecare retuning (lecția
   plafonului de triunghiuri din `CLAUDE.md`). Verdictul final rămâne **la
   volan**: matricea măsoară potențialul mașinii, nu accesibilitatea ei —
   dezvoltatorul conduce fiecare mașină pe 3 piste după retuning. Livrare:
   un PR cu sonda + unul cu retuning-ul, A/B pe aceeași matrice (memoria
   `proberace-nedeterminism`: distribuții, nu o rulare).

1. **Date + raft + ștampile + gating — CONSTRUIT (PR #556, 17 oct).**
   Starea exactă, abaterile și ce a rămas: `pas1_raft_stare.md`. Notă: „Okinawa”
   din lumea 2 e `okinawa` = Track20 (cea nouă); `okinawa_manual` (Track08),
   Dunele și Alpii rămân în afara lumilor, ca Ha Long. Fluxul în joc (medalie →
   BACK TO CAREER → raft) e acoperit de sondă, nu rulat la volan. Planul inițial
   al pasului: resursele `CareerWorld` /
   `CareerConfig` cu gruparea din §3 (trei `.tres` de lume + unul de
   config; Ha Long în niciuna), `Career` autoload, `id` pe `TrackInfo`,
   migrarea recordurilor, ecranul raftului cu cutii și `TrackCard`-uri cu
   medalii, pașaportul. Butonul CAREER în meniu, CHAMPIONSHIP dispare.
   *Gardă:* `ProbeCareer` scrie rezultate sintetice și verifică pragurile,
   persistența și migrarea (inclusiv un `career.cfg` cu versiune necunoscută
   → nu se corupe, se ignoră cu mesaj), plus **config-ul**: exact o lume
   `free`, nicio pistă în două lumi, fiecare `id` de pistă există în
   `TRACK_SCENES`, `rival_track` e în lumea lui; și **regruparea**: mută o
   pistă între două lumi în config-ul de test și verifică că medaliile ei
   și ștampilele totale nu se schimbă.
2. **Medalii pe cursă + contratimpul cu rezervor sigilat — CONSTRUIT (PR
   #561, 17 oct).** Starea: `pas2_contratimp_stare.md`. Țintele din
   `TrackInfo` sunt 0 pe toate pistele până le pui la volan. Planul inițial:
   semnalele
   `lap_completed` / `race_finished` pe `Race` (cerute de `CLAUDE.md` de
   mult), `turbo_recharge` pe `Car`, modul contratimp (`ai_count = 0`, HUD cu
   cele trei ținte), `tt_*_ms` pe fiecare `TrackInfo` — **valorile le pune
   dezvoltatorul la volan**, PR-ul le lasă pe 0 = „fără țintă încă”. *Gardă:*
   `ProbeRace --ai=0 --sealed-turbo` confirmă că bara nu crește; ecranul de
   rezultate arată medalia corectă pentru timpi sintetici.
3. **Rivalii** — butonul de calitate pe `AIController` (`line_quality`,
   `line_offset` 0, praguri de turbo), comportamentul de apărare, modul 1v1
   din pole, deblocarea mașinii în garaj (garajul citește `Career.unlocked`,
   mașinile blocate se văd gri cu „învinge-l pe Luna”). *Gardă:* `ProbeRace`
   rival vs AI de grilă, aceeași mașină, pe distribuție (§5).
4. **Provocările de gimmick — 4a CONSTRUIT (PR #563, 17 oct)**: tracker-ul
   generic „zero evenimente” + cele 7 piste cu semnal existent; starea în
   `pas4a_provocari_stare.md`. 4b (cele 5 piste cu semnal nou, reguli pe tur
   / pe zonă) rămâne. Planul inițial: `ChallengeTracker` + contractul per pistă,
   **câte un PR per pistă**, întâi cele 8 cu semnal existent (Okinawa,
   Stromboli, Kyoto, Jodhpur, Serengeti, Monument Valley, Machu Picchu,
   Transfăgărășan), apoi cele 4 din carieră care cer semnal nou (Chongqing,
   Cappadocia, Baikal, Fiordland); Ha Long când intră într-o lume. Abțibildul
   = un decal pe materialul de clasă al mașinii, **nu o textură per asset**
   (regula din `CLAUDE.md`; o clasă „abțibilduri” cu un atlas partajat).
   *Gardă:* o sondă care aruncă semnalul sintetic și verifică verdictul, plus
   sabotaj (semnalul greșit nu trece).
5. **Fantoma** — înregistrare, fișier, redare, selecția „a ta / a rivalului”.
   *Gardă:* înregistrare sintetică de 3 tururi → fișier → redare la aceeași
   poziție în același cadru (toleranță 1 cm).
6. **Polish** — cupa lumii pe campionatul existent, provocarea zilei,
   animația de ștampilă, pagina de 100%.

Pasul 0 merge **primul și singur**: e fizică și feel, cere verdictul
dezvoltatorului la volan, și toate țintele de mai jos (contratimp, rivali)
depind de el. Pașii 1 și 2 sunt fundația și se fac în serie — pasul 1 (date
+ raft) nu depinde de 0 și poate merge în paralel cu el. 3, 4 și 5 sunt
independente între ele după 2 și pot merge în paralel pe worktree-uri frați
(`D:/GameDev/wt-cariera-<pas>`, memoria `orchestrare-agenti-worktree-frate`),
cu constructori Sonnet și coordonare Fable (memoria
`coordonator-fable-constructori-sonnet`). Integrarea, ca la piste: fiecare PR
cu `bash tools/verify_local.sh` înainte de merge.

Ce **nu** intră în v1: sens invers (§7, cere dovadă per pistă), fantoma
„dev”, provocarea semnăturii dincolo de 2–3 exemple.

## 12. Decizii deschise (ale dezvoltatorului)

**Decise (16 oct 2026):** gruparea lumilor și lumea gratuită (§3), Ha Long
în afara carierei deocamdată, gruparea ca date refăcută dintr-un `.tres`.

Rămase:

1. **Numele celor trei lumi** — grupele nu sunt pe continent sau pe climă,
   deci numele vine din altceva (etape ale turului? „Lumea 1/2/3”?). Apare
   pe cutie, deci decide și iconografia raftului.
2. **Garajul de start**: Buggy + Taxi, sau o singură mașină (progresie mai
   lungă, început mai sărac).
3. **Rivalii** (§5): perechile Vex/Poliția, Luna/Pompierii, Robo/Autobuzul,
   Nyx/Muscle final — propunere; pistele lor le alege matricea **după pasul
   0**. Robo cere comportamentul de apărare, fără el altă mașină în lumea 3.
4. **Pragurile de ștampile** (6 / 14) și **țintele de contratimp** —
   amândouă se pun la volan, nu din calcul.
5. **Vocabularul** în joc: „ștampile / pașaport / cutii” sau alt vocabular
   de jucărie („abțibilduri pe cutie”, „raftul”).
6. **Sens invers** — intră sau nu în v1 după ce `ProbeRace` îl rulează pe
   fiecare pistă.
7. **Ha Long** — când intră în carieră și în ce lume (a patra cutie, sau a
   cincea pistă a uneia existente; `CareerWorld.tracks` nu are limită).
8. **Turul fals după repunere** (§2.1): issue separat, de verificat înainte
   ca recordurile de carieră să conteze — o repunere peste linie nu are
   voie să numere un tur.

**Decise (17 oct 2026):** ce cumpără masa = (a) hazarde scalate cu masa +
(b) trece prin turmă/trafic/bolovani fără să piardă viteza; bara de turbo
nu se atinge. Pragul de veto pe ecartul best lap per pistă: **8%,
provizoriu** — sub 5% mașinile devin la fel, peste 10% cele lente rămân
lente; se fixează după prima rundă de retuning. **După runda 2 (§2.1.1):**
8% e atins pe 10 piste din 12 și cele două rămase sunt de gimmick, deci
pragul rămâne 8%; nu se ridică pentru ele (lecția plafonului de
triunghiuri), se repară pasabilitatea.
