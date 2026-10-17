# Pasul 4b — provocarile cu semnal nou / reguli pe tur (stare)

Ramura `cariera/pas4b-provocari` (peste `cariera/pas4-provocari`). 4a ramane in
`pas4a_provocari_stare.md`; aici e doar ce a adaugat 4b.

## Regulile (`CareerChallenge.Rule`)

| Regula | Reusit daca | Pica pe loc |
|---|---|---|
| `ZERO_EVENTS` | niciun eveniment al jucatorului | primul eveniment |
| `AT_LEAST` | `events >= count` si `fail_event` nu s-a intamplat | `fail_event` al jucatorului |
| `EVERY_LAP` | fiecare tur incheiat a avut >= 1 eveniment | un tur incheiat cu 0 |
| `CLEAN_LAP` | exista un tur incheiat cu 0 evenimente | niciodata (se decide la final) |

Campuri noi: `count`, `fail_event` (`bus_hit`), `zone` (nume de nod din pista).
`threshold` se refoloseste: la `wall_hit` e dv-ul minim (m/s).
Turele vin de la `Race`: `lap_completed` -> `ChallengeTracker.notify_lap(laps)`
(emis inainte de `_finish_race`, deci si al treilea tur e evaluat).

## Cele 12 provocari

| Pista | Titlu | Regula | event | prag / zona / count | Ascultat |
|---|---|---|---|---|---|
| kyoto | (4a) | ZERO_EVENTS | `thrown` | - | `car_thrown` pe cele 4 hazarde de aruncare |
| stromboli | (4a) | ZERO_EVENTS | `fireball` | - | `FireballGeyser.fireball_hit` |
| serengeti | (4a) | ZERO_EVENTS | `animal` | - | `HerdHazard.animal_hit` |
| okinawa | (4a) | ZERO_EVENTS | `splash` | prag 0.5 | `Car.splashed` |
| monument_valley | (4a) | ZERO_EVENTS | `crush` | - | `Car.crushed` |
| machu_picchu | (4a) | ZERO_EVENTS | `shove` | - | `BusHazard.shoved` |
| jodhpur | (4a) | ZERO_EVENTS | `traffic_bump` | - | `Car.bumped` + `TrafficController` |
| transfagarasan | RED RUNNER | AT_LEAST | `red_run` | count 3, `fail_event = bus_hit` | `TunnelSignalHazard.passed_on_red` + `.bus_hit` |
| cappadocia | CLEAN SPIRAL | ZERO_EVENTS | `wall_hit` | prag 12, zona `StancaSpirala` | `Car.wall_hit` al jucatorului, filtrat |
| chongqing | ALL ABOARD | EVERY_LAP | `boarded` | - | `CablewayHazard.boarded` |
| baikal | THIN ICE | CLEAN_LAP | `plate_broken` | jucatorul in `cars` | `IceFieldHazard.plate_broken(cars)` |
| fiordland | OLD ROAD | EVERY_LAP | `branch` | - | sondaj `player.route != 0` |

## Semnale adaugate in hazarde (doar `signal` + `emit`)

- `TunnelSignalHazard.passed_on_red(car)` — **semaforul nu avea detectie de
  trecere** (Transfagarasan si Fiordland il folosesc, ambele pe `Mode.LANE`, unde
  AI-ul nu se opreste). Am adaugat `_detect_red_runs()`, apelat din
  `_physics_process`: pentru fiecare masina din grupul `cars`, retine z-ul local
  si emite cand trece z=0 (linia = originea nodului, +Z spre tunel) cu
  `is_red()` adevarat, in lat. de 12 m, dintr-un pas < 4 m (o repunere nu e
  trecere). Un set `_red_counted` (golit la verde) face o singura emisie per masina
  per rosu. Nu am folosit `frac_at`: linia e deja in coordonatele hazardului.
  `bus_hit` exista deja.
- `CablewayHazard.boarded(car)` — in `_on_state_changed`, in bucla care
  populeaza `_aboard` cand usile se inchid (o data per masina per imbarcare,
  nu per tick de `_hold_aboard`). Se emite la ambele plecari (sus si jos).
- `IceFieldHazard.plate_broken(cars: Array[Car])` — la trecerea placii in
  `BROKEN`, cu `on_plate`.

## Pragul Cappadocia: 12 m/s

`Car` emite `wall_hit` de la `dv_h > 8` (frecare de perete, cooldown 0.35 s),
iar la `dv_h >= eject_wall_dv = 26` soferul e aruncat. Shake-ul camerei e
`clamp(dv/45, 0.15, 0.5)`: la 12 e ~0.27, un impact vizibil. 8–12 e frecarea
unei aripi pe care o faci fara sa vrei in spirala; peste 12 e o lovitura
clara. **De validat la volan** (poate coborat spre 10 daca "CLEAN SPIRAL" iese
prea usor).

Zona `StancaSpirala` e un `CameraZone` in **mod fractie** (`frac_from 0.756`,
`frac_to 0.99`, nu cutie): tracker-ul intreaba `CameraZone._player_inside()`,
care citeste fractia masinii tinta a camerei. Deci in cursa merge exact ca
zona de camera; in sonda e testat doar modul cutie (sintetic), iar pe pista
reala doar ca zona exista si e pe fractie.

## Ce s-a gasit / abateri

- `wall_hit` + zona: `overlaps_body` NU merge pe `StancaSpirala` (Area3D fara
  masca utila, apartenenta e pe fractie) — de aceea `_player_inside()`.
- Lipsa zonei in pista: `push_warning` si evenimentul nu numara niciodata =
  provocare mereu reusita; sonda verifica zona pe `Track13.tscn`.
- Baikal: `IceFieldHazard` se construieste in `Track._ready` din marker/ranges,
  deci scena neinstantiata in arbore nu-l contine; sonda verifica markerul
  `ICE_SLAB` / `custom_ice_ranges` pe `Track10.tscn`.
- `ProbeIceField` (punctul 5, traversare) si `ProbeFiordSemafor` (treceri
  clare pe rosu <= 1) dau PROBLEMA si **pe ramura de baza**, cu aceleasi cifre
  (verificat prin inlocuirea temporara a fisierului hazardului): nu sunt ale 4b.
- Fiordland/Transfagarasan pe LANE: rosul tine ~18 s din 34–40, iar AI-ul
  trece (ProbeFiordSemafor: 10 treceri/150 s). "3 treceri pe rosu" in 3 ture
  inseamna sa nu eviti semaforul; cifra de validat la volan.
- HUD: acelasi label ca la 4a; progresul (`1 / 3`, `LAP 2 ✓`, `LAP 1: 2 PLATES`)
  se adauga langa titlu; dupa esec ramane doar "CHALLENGE FAILED".
- `branch` numara o data pe tur (primul tick cu `route != 0`).

## Garda

`godot --headless --path . res://tools/ProbeChallenge.tscn` (aceeasi linie din
`verify_local.sh`). 186 verificari: datele (12 provocari, `validate()` goala,
sabotaje: `AT_LEAST` count 0, `fail_event` inventat, `wall_hit` fara zona),
regulile pe semnale sintetice (instante reale `.new()` de hazard), detectia
reala de trecere pe rosu (sabotat: fara `red` pica "trecere pe VERDE"), semnalele
exista, pistele reale contin sursele / zona / `TrackBranch`.
Ce NU verifica: ca un hazard emite intr-o cursa condusa cap-coada (pentru asta:
test la volan).

## Ramane

- Abtibilduri (cosmetic) — nu intra aici.
- Prag Cappadocia (12) si "3 treceri pe rosu" de validat la volan.
- Pista Halong (22) fara provocare.
