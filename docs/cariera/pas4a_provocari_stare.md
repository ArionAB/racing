# Pasul 4a — provocarea gimmick-ului (stare)

Ramura `cariera/pas4-provocari` (peste `cariera/pas2-contratimp`).

## Ce s-a construit

- `CareerChallenge` (resursa, `scenes/career/career_challenge.gd`): pista, titlu,
  hint, regula (`ZERO_EVENTS`), `event`, `threshold`. Date in
  `scenes/career/data/challenges/*.tres`, listate in `career_config.tres`.
- `Career`: `Mode.CHALLENGE` (cursa normala cu AI, `ai_count` neatins),
  `challenge_for(id)`, `is_challenge()`, `finish_challenge(success)` (bifeaza prin
  `set_challenge`, nu pierde reusita veche, nu da medalie de cursa) si
  validarea provocarilor in `validate()` (pista exista, event cunoscut, o
  provocare pe pista).
- `ChallengeTracker` (`scenes/career/challenge_tracker.gd`): copil al lui `Race`,
  se aboneaza la semnalele existente; primul eveniment al JUCATORULUI pica
  provocarea (`failed`, `failed_changed`). `evaluate()` = `not failed`, citit la
  `_finish_race`.
- Race/HUD: eticheta mica verde "CHALLENGE: <titlu>" in aceeasi zona cu SEALED,
  devine "CHALLENGE FAILED" (rosiatic) + `flash_message` o singura data;
  rezultate "CHALLENGE — <titlu> — DONE/FAILED", buton BACK TO CAREER.
- Foaia pistei: `ChallengeButton` activ pe pistele cu provocare (titlu + hint,
  sau titlu + DONE verde); fara provocare ramane dezactivat cu SOON.

## Cele 7 provocari

| Pista | event | prag | Clasa/semnalul ascultat |
|---|---|---|---|
| kyoto | `thrown` | - | `GionMatsuriHazard`, `ShishimaiHazard`, `ShishiOdoshiHazard`, `DarumaOtoshiHazard` -> `car_thrown(car[, on_strike])` |
| stromboli | `fireball` | - | `FireballGeyser.fireball_hit(car)` |
| serengeti | `animal` | - | `HerdHazard.animal_hit(car, mass_ratio)` |
| okinawa | `splash` | 0.5 | `Car.splashed(car, strength)` al jucatorului |
| monument_valley | `crush` | - | `Car.crushed(car, severity)` al jucatorului |
| machu_picchu | `shove` | - | `BusHazard.shoved(bus, car)` |
| jodhpur | `traffic_bump` | - | `Car.bumped(car, other, dv)` cu `other.controller is TrafficController` |

## Ce s-a gasit in cod (si abateri)

- **Okinawa**: valul (`WaveSurge`) emite prin `Car.splash(strength)`: 0.22 cat
  esti in apa (zguduitura de fond, la interval) si 0.75 cand creasta trece peste
  masina (+ `apply_sweep`). Pragul 0.5 le desparte: stropirea nu pica provocarea,
  valul da. `TyphoonHazard` foloseste doar `apply_sweep`, fara semnal: nu conteaza.
- **Kyoto**: `ShishiOdoshiHazard.car_thrown` are un al doilea argument
  (`on_strike`); handler-ul accepta argument optional. Titlul spune "NO THROWS"
  (nu doar Gion/shishimai): toate cele patru hazarde de aruncare din Kyoto conteaza.
- **Crush (Monument Valley)**: se numara ORICE `crushed` al jucatorului, nu doar
  bolovanii; pe aceasta pista singura sursa de strivire e bolovanul/stancile.
- **Stromboli**: "3 tururi" = toata cursa; tracker-ul nu numara tururi.
- **traffic_bump**: ascult `player.bumped` (fiecare masina emite pentru ea
  insasi, cu cooldown per pereche), deci ciocnirea cu un tuk-tuk se numara o data.
- **Sursele in sonda**: s-a ales `setup(..., sources: Array[Node])` (variantei
  din brief) — sonda pasa instante reale ale scripturilor de hazard create cu
  `.new()` (fara scena); tracker-ul se aboneaza dupa NUME de semnal. In cursa
  `sources` e gol si le gaseste in pista dupa clasa. Lipsa oricarei surse da
  `push_warning` cu pista si semnalul.
- `probe_career.gd` (pas 1) avea doua verificari ca CHALLENGE e dezactivat/SOON
  pe primul card; acum e activ (Monument Valley are provocare) si au fost
  actualizate. Singura atingere a pasilor 1-2.
- Rezultatele provocarii nu apar in campionat; modul nu schimba cursa rapida,
  campionatul sau contratimpul.

## Garda

`godot --headless --path . res://tools/ProbeChallenge.tscn` (inregistrata in
`tools/verify_local.sh`: "Provocari: tracker-ul numara doar ce trebuie"). Verifica:
datele + 3 sabotaje, tracker-ul pe fiecare semnal (alta masina = 0, jucatorul = 1,
prag splash, AI vs TrafficController), `Career` (mod, ai_count, bifa, reusita
pastrata), foaia (activ/DONE/SOON), si ca pistele reale contin sursa semnalului.
Ce NU verifica: ca un hazard real emite intr-o cursa condusa (semnalele sunt
sintetice pe instante reale); pentru asta e `ProbeRace` / test la volan.

## Ramane pentru 4b si dupa

- Reguli noi: `EVERY_LAP` / zone (ex. Transfagarasan semafor-cu-autocar,
  Cappadocia spirala, Chongqing telecabina, Baikal gheata, Fiordland
  scurtatura) cer semnale noi pe hazarde si evaluare pe tur.
- Abtibilduri (cosmetic pe masina): nu intra aici.
- Verdictul de feel (prag Okinawa 0.5, titluri) la volan.
