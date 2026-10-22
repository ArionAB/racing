# Audio — surse si licente

Registrul **tuturor** fisierelor de sunet din joc, cu sursa si licenta
fiecaruia. Se completeaza **la import**, nu retroactiv: cand ajungem la store
listing si la ecranul de Credits, reconstituirea din memorie pentru 100+ de
fisiere e imposibila, iar o licenta pe care n-o poti dovedi e o licenta pe care
n-o ai.

Analog cu `assets/CREDITS.md` (care acopera **modelele** CC-BY), dar registrul de
audio le listeaza pe **toate**, nu doar pe cele cu atribuire obligatorie: la
audio mai probabil greseala e sa nu stii *de unde* vine un fisier, nu sa uiti sa
scrii un nume.

## Starea de acum (22 oct 2026)

**Zero assets audio externe. Zero obligatii de licenta.**

Toate cele **55** de fisiere din `assets/audio/` sunt sintetizate procedural
(WAV mono 22050 Hz / 16-bit): cele 28 vechi si cele 16 de eveniment de
`tools/generate_sfx.gd`, cele 11 ale vocilor continue de masina (motor, derapaj,
suprafete, turbo, vant) de `tools/generate_sfx_car.gd` — cod scris in cadrul
proiectului, deci drepturile sunt ale noastre. Nu exista nicio inregistrare
descarcata, niciun sample de biblioteca, nimic generat de AI.

Verificat prin regenerare in worktree curat (14 oct 2026): 26 din 28 de fisiere
ies **identice bit-pentru-bit** cu cele din git, si doua rulari consecutive dau
acelasi rezultat — generatorul e determinist (`rng.seed = 20260718`).

`generate_sfx_car.gd` are `rng`-ul lui (`seed = 20261022`) si nu atinge niciun fisier
vechi: rulat peste cele 28, hash-urile lor raman neschimbate (verificat 22 oct 2026),
iar cele 11 noi ies identice la doua rulari consecutive. Fisier separat tocmai ca sa
nu mute zgomotul generatorului vechi (un singur `rng` semanat o data).

Cele **16** de fisiere de eveniment adaugate pe 22 oct 2026 (impact in straturi,
hartaieli, claxon, stinger, hazarde, decor) se genereaza dintr-un sir de zgomot
**separat** (`rng_ev.seed = 20261022`, blocul `_save_event_sounds`), asa ca
adaugarea lor n-a mutat niciun bit din cele 28 de dinainte (verificat: dupa
regenerare, `git status` arata modificate doar cele doua fisiere Gion de mai jos).

Pentru cele doua excepții vezi [Datoria tehnica](#datorie-tehnica-doua-fisiere-nu-se-mai-regenereaza).

### Inventar

| Fisier | Rol | Sursa | Licenta |
|---|---|---|---|
| `engine_loop.wav` | bucla de motor veche (inlocuita pe masini de `engine_whine`/`engine_whirr`; ramane ca `AudioManager.ENGINE_LOOP`) | `generate_sfx.gd` | proprietate proiect |
| `engine_whine.wav` | motor de jucarie, stratul tiuit (bucla 0.5 s, 330 Hz; jucator si AI) | `generate_sfx_car.gd` | proprietate proiect |
| `engine_whirr.wav` | motor de jucarie, stratul zumzet de angrenaje (bucla 0.5 s; doar jucator, sub sarcina) | `generate_sfx_car.gd` | proprietate proiect |
| `skid_gravel.wav` | sisait de derapaj pe sol afanat (bucla 0.6 s) | `generate_sfx_car.gd` | proprietate proiect |
| `roll_grass.wav` / `roll_gravel.wav` / `roll_water.wav` | rularea pe iarba / pietris-nisip / apa mica (bucle 1 s) | `generate_sfx_car.gd` | proprietate proiect |
| `kerb_rattle.wav` | zdranganeala de bordura (bucla 0.4 s) | `generate_sfx_car.gd` | proprietate proiect |
| `wind_loop.wav` | vant dupa viteza (bucla 1.2 s, doar jucator) | `generate_sfx_car.gd` | proprietate proiect |
| `turbo_click.wav` / `turbo_release.wav` | clickul la apasarea turbo / sisaitul de la capat | `generate_sfx_car.gd` | proprietate proiect |
| `turbo_whoosh.wav` | suvoiul turbo cat arde (bucla 0.8 s) | `generate_sfx_car.gd` | proprietate proiect |
| `skid_loop.wav` | bucla de derapaj | `generate_sfx.gd` | proprietate proiect |
| `boost.wav` | turbo | `generate_sfx.gd` | proprietate proiect |
| `drift_start.wav` / `drift_level.wav` | intrare in drift / prag de bara | `generate_sfx.gd` | proprietate proiect |
| `backfire.wav` | rateu la ridicarea piciorului | `generate_sfx.gd` | proprietate proiect |
| `wall_hit.wav` / `bump.wav` / `metal_hit.wav` | perete / masina-masina / tabla pe tabla | `generate_sfx.gd` | proprietate proiect |
| `land.wav` | aterizare dupa saritura | `generate_sfx.gd` | proprietate proiect |
| `splash.wav` | intrare in apa | `generate_sfx.gd` | proprietate proiect |
| `count_beep.wav` / `go_beep.wav` | countdown / start | `generate_sfx.gd` | proprietate proiect |
| `rock_warn.wav` / `rock_impact.wav` | rockfall: avertisment / impact | `generate_sfx.gd` | proprietate proiect |
| `train_horn.wav` / `crossing_bell.wav` | tren / trecere la nivel | `generate_sfx.gd` | proprietate proiect |
| `typhoon_roar.wav` | tromba (bucla, Okinawa) | `generate_sfx.gd` | proprietate proiect |
| `wave_wash.wav` | val peste dig (bucla, Okinawa) | `generate_sfx.gd` | proprietate proiect |
| `avalanche_rumble.wav` / `avalanche_hit.wav` | avalansa: huruit (bucla) / impact | `generate_sfx.gd` | proprietate proiect |
| `ice_crack.wav` | trosnet de gheata (Baikal) | `generate_sfx.gd` | proprietate proiect |
| `daruma_toc.wav` / `daruma_slide.wav` | daruma-otoshi (Kyoto) | `generate_sfx.gd` | proprietate proiect |
| `shishimai_music.wav` / `shishimai_clack.wav` | shishimai (Kyoto) | `generate_sfx.gd` | proprietate proiect |
| `gion_bayashi.wav` / `gion_wheels.wav` | car Gion Matsuri (Kyoto) | `generate_sfx.gd` | proprietate proiect |
| `impact_tap_a.wav` / `impact_tap_b.wav` | impact usor, strat tap (doua variante, ~0,1 s) | `generate_sfx.gd` | proprietate proiect |
| `impact_crunch_a.wav` / `impact_crunch_b.wav` | impact mediu, strat crunch (~0,26 s) | `generate_sfx.gd` | proprietate proiect |
| `impact_crash_a.wav` / `impact_crash_b.wav` | impact tare, strat crash (~0,55 s) | `generate_sfx.gd` | proprietate proiect |
| `scrape_loop.wav` / `rub_loop.wav` | bucle de contact: razuire pe perete / frecare intre masini | `generate_sfx.gd` | proprietate proiect |
| `land_heavy.wav` | strat greu al aterizarii (peste `land.wav`) | `generate_sfx.gd` | proprietate proiect |
| `toy_horn.wav` | claxon de jucarie al AI-ului (ranchiuna, frecare) | `generate_sfx.gd` | proprietate proiect |
| `stinger_up.wav` / `stinger_down.wav` | stinger la depasire / la fiind depasit | `generate_sfx.gd` | proprietate proiect |
| `hazard_barrier_hit.wav` / `hazard_bus_hit.wav` | contact cu bariera glisanta / cu autobuzul | `generate_sfx.gd` | proprietate proiect |
| `prop_knock_a.wav` / `prop_knock_b.wav` | decor usor lovit (lemn / plastic) | `generate_sfx.gd` | proprietate proiect |

**Muzica: nu exista.** Nici piese, nici ambianta de fundal, nici bus `Music`.
`AudioManager` are doua bus-uri (`SFX`, `Engine`) si doua slidere in setari
(«Volum efecte», «Volum motor»). Primul fisier de muzica adus in proiect cere si
bus + slider, altfel n-are volum reglabil.

## Regula de licenta

Pentru un joc **comercial** in store (chiar si gratuit cu reclame), filtrul e
simplu. Se accepta:

- **CC0 / Public Domain** — zero obligatii, nici atribuire. Prima alegere.
- **CC-BY** — gratuit, dar atribuirea e **conditie a licentei**: intra in
  `assets/CREDITS.md` *si* in ecranul de Credits din joc.
- **Licenta comerciala explicita** (ex. pachetele Sonniss GDC) — permisa,
  de obicei fara atribuire. Se pastreaza textul licentei in repo.

Se **refuza**, fara discutie:

- **CC-BY-NC** — non-commercial: blocheaza orice monetizare, inclusiv reclame.
- **CC-BY-SA** / **GPL** pe assets — share-alike, contaminant.
- «free for personal use», «free for non-commercial», «demo» — nu sunt licente
  pentru ce facem noi.
- orice fisier fara licenta scrisa si verificabila. Daca nu poti arata de unde
  vine, nu intra in joc.

## Surse recomandate

**SFX**
- **Sonniss — GDC Game Audio Bundle**: arhive mari, licenta comerciala inclusa,
  fara atribuire. Cea mai buna calitate gratuita; arhivele din anii trecuti
  rezista.
- **Freesound.org**: filtrat **explicit pe CC0** (are si CC-BY si NC — se
  verifica per fisier, nu per site).
- **Kenney.nl**: CC0, UI si impacturi, facute pentru gamedev.
- **OpenGameArt.org**: mixt, filtrat pe CC0.

**Muzica**
- **Incompetech** (Kevin MacLeod): CC-BY — merge, dar cere atribuire.
- **FreePD.com**: CC0.

**AI generativ** — util, cu doua conditii:
- Drepturile comerciale vin din **planul platit** (Suno, Udio, ElevenLabs). Pe
  planul gratuit **nu** exista drept comercial.
- Se noteaza in registru ca e generat de AI, cu unealta si planul. Statutul
  juridic al output-ului de AI e inca neclarificat in unele jurisdictii;
  riscul practic pentru un proiect solo e mic, dar un audit de IP (vanzare,
  publisher) se uita la asta.

Unde AI-ul e **mai bun** decat bibliotecile: muzica per pista (avem teme
distincte per lume) si ambianta de tema. Unde e **mai slab**: motorul — are
nevoie de layere pe RPM, nu de un singur sample; aici o inregistrare reala
(sau sinteza, ca acum) bate generarea.

## Cum se adauga un fisier audio

1. Verifica licenta **inainte** de download si salveaza dovada (URL, autor,
   text de licenta).
2. Pune fisierul in `assets/audio/`.
3. **Adauga un rand in tabelul de mai sus** — fisier, rol, sursa, licenta.
   Pentru AI: unealta + planul. Pentru CC-BY: si in `assets/CREDITS.md`.
4. Inregistreaza-l in `AudioManager.SFX` (sau pe bus-ul de muzica, cand exista).
5. Fisierul sursa nemodificat sta **in afara repo-ului** (ca la modele:
   `D:/GameDev/downloaded assets/`).

Un fisier audio in `assets/audio/` care **nu** e in tabel se trateaza ca
licenta necunoscuta — adica se scoate pana se dovedeste.

## Datorie tehnica: doua fisiere nu se mai regenereaza

`gion_bayashi.wav` si `gion_wheels.wav` din git **nu** mai pot fi reproduse de
`tools/generate_sfx.gd` in forma lui actuala. Masurat (14 oct 2026):

| | lungime | RMS commit / regenerat | dif. medie | dif. varf |
|---|---|---|---|---|
| `gion_bayashi` | identica (66150 cadre) | 3098 / 2943 | 209 | 43,1% din scala |
| `gion_wheels` | identica (44982 cadre) | 2970 / 2995 | 2839 | 79,1% din scala |

Nu e nedeterminism: doua rulari consecutive dau acelasi rezultat, iar celelalte
26 de fisiere ies identice bit-pentru-bit. Lungimile si nivelurile (RMS) sunt
practic egale — deci nu e un fisier «stricat», e **aceeasi reteta cu alta
realizare de zgomot**: fisierele au fost comise inainte de o ajustare ulterioara
a functiilor lor.

Consecinta practica: cine ruleaza generatorul primeste doi fisiere modificati in
`git status`, fara sa fi schimbat nimic — exact capcana pe care comentariile din
generator incearca sa o previna pentru ordinea apelurilor.

De decis (nu rezolvat aici, fiindca schimba sunetul a doua hazarde din Kyoto):
fie se accepta renderul nou si se comit cele doua fisiere, fie se restaureaza
functiile care au produs versiunile din git. **Pana atunci: nu comite cele doua
fisiere daca apar modificate dupa o rulare a generatorului.**
