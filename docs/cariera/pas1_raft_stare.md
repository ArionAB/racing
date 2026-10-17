# Cariera, pasul 1: date, raft, stampile, gating

Stare la sfarsitul pasului 1 (ramura `cariera/pas1-raft`). Brief-ul: `mod_cariera.md` (pe alta ramura).

## Ce exista

- **Date** (`scenes/career/`): `CareerWorld` si `CareerConfig` (resurse), `data/world_1..3.tres` + `data/career_config.tres`.
  Lumea 1 (free): monument_valley, kyoto, cappadocia, serengeti. Lumea 2 (6 stampile): transfagarasan, chongqing, machu_picchu, okinawa.
  Lumea 3 (14): baikal, stromboli, jodhpur, fiordland. Ha Long nu e in nicio lume (doar cursa rapida). Numele lumilor sunt placeholder ("LUMEA 1/2/3").
  A muta o pista intre lumi sau a schimba un prag = editezi un `.tres`.
- **`TrackInfo.id`**: cheie stabila per pista, completata in toate cele 16 `Track*.tres`; fallback `scene_key().to_lower()`; `TrackInfo.index_of_id()` (cu cache static).
- **Autoload `Career`** (`scripts/autoload/career.gd`, dupa `GameState`): config, validare (`validate()`), persistenta `user://career.cfg` (v1), stampile calculate, deblocare, medalii, starea cursei de cariera (`start_track`, `finish_active`, `leave`), semnal `progress_changed`.
  Cheile din `career.cfg` sunt pe pista si pe rival; singura cheie pe lume e cupa. Un fisier cu versiune > 1 nu se incarca si nu se rescrie.
- **UI**: `CareerPanel` (pasaport + o cutie per lume; carduri sau lacat), `TrackCard.set_medals` (3 discuri desenate), butonul CAREER in meniu (in locul lui CHAMPIONSHIP, care ramane in `GameState`).
- **Cursa**: la final, `Career.finish_active(pozitia)` salveaza medalia (aur/argint/bronz pentru locurile 1/2/3); titlul rezultatelor o arata, butonul principal e „BACK TO CAREER”, care duce direct pe raft (`GameState.menu_open_panel`). `GameState.go_to_menu()` apeleaza `Career.leave()`.

## Garda

```
D:/GameDev/Godot_v4.7-stable_win64_console.exe --headless --path . res://tools/ProbeCareer.tscn -- --check
```
Inregistrata in `tools/verify_local.sh` („Cariera: config, persistenta, gating, raft”). Contine sabotaje pe config, contra-probe, numarare pe noduri si un minim de verificari (`MIN_CHECKS`).

## Lasat pentru pasii 2+

Contratimp (`set_time_trial` exista, nimic nu il cheama), provocari (`set_challenge`), rivali si `rival_track` (schema exista, campurile raman goale), cupa lumii (`set_cup_won`; campionatul din `GameState` o va folosi), abtibilduri, garaj blocat (`[garage] unlocked` se citeste/scrie, nu blocheaza nimic), numele reale ale lumilor.

## Abateri de la brief

- Clasa de desen a medaliilor se numeste `_Medals` (un singur Control care deseneaza cele 3 discuri), nu `_Medal`.
- `Career.validate(cfg)` primeste un config optional, ca sonda sa sabotese un config in memorie. `Career.config` e public din acelasi motiv.
- `Career.race_starter` (Callable) exista, implicit gol => `GameState.start_race`; il foloseste doar sonda.
- `TrackSelectPanel`: antetul si logica grilei au devenit functii statice (`build_header`, `fit_cards`) refolosite de `CareerPanel`; comportamentul cursei rapide e neschimbat.
- `GameState.start_quick_race` si `start_championship` apeleaza `Career.leave()`, ca o cursa rapida sa nu mostenteasca o stare activa de cariera.
- `Career.medal_counts()` adaugat pentru randul de medalii din pasaport.
- Cursa de cariera nu a fost rulata cap-coada in joc (headless nu poate); fluxul `_finish_race` -> medalie -> BACK TO CAREER e verificat doar prin sonda pe `Career` si prin parsarea scenei, nu printr-o cursa reala.
