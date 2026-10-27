# Cariera, pasul 2: contratimp cu rezervor sigilat

Ramura `cariera/pas2-contratimp` (peste `cariera/pas1-raft`). Brief: `mod_cariera.md` 4.2 si 11 (pe alta ramura).

## Ce exista

- **Semnale** in `Race`: `lap_completed(laps, lap_ms)` (emis dupa calculul turului jucatorului) si `race_finished(position, race_ms)` (la finalul lui `_finish_race`). Nimic din joc nu le asculta inca (le va folosi `ChallengeTracker`, pasul 4); apelurile directe catre `Career` din pasul 1 au ramas.
- **`Car.turbo_recharge`** (grupul Turbo, implicit `true`): cu `false` bara nu creste nici din mers, nici din drift; arderea merge. Nimic altceva din fizica nu s-a atins.
- **`Career`**: `enum Mode { RACE, TIME_TRIAL }`, `active_mode`, `is_time_trial()`, `start_track(id, mode)`, `finish_time_trial(ms) -> medalie`, `time_trial_medal(id, ms)` si `medal_for_time(info, ms)` (statice, pure). In contratimp `ai_count` devine 0; `leave()` il readuce (si un al doilea `start_track` peste un contratimp neinchis nu pierde valoarea originala).
- **`TrackInfo`**: `tt_gold_ms/tt_silver_ms/tt_bronze_ms` (0 = fara tinta; nu da medalie, dar timpul se salveaza), `has_targets()`, `has_time_trial_targets(index)`. Valorile din `.tres` raman 0.
- **`Race`**: in contratimp `turbo_recharge = false`, bara plina la GO, `Career.finish_time_trial` la sosire, recordurile din `GameState` (tur si cursa) NU se scriu. Rezultate: titlul `TIME TRIAL - 3:12.4 - SILVER` (sau `NO TARGET YET` / `NO MEDAL`), randul jucatorului + 3 randuri GOLD/SILVER/BRONZE cu timpul tinta.
- **UI**: tap pe card in `CareerPanel` deschide foaia pistei (RACE, TIME TRIAL, CHALLENGE dezactivat „SOON”, BACK; butoane de 72 px); `ui_cancel` inchide intai foaia. HUD: eticheta `SEALED` langa bara de turbo (`set_sealed_turbo`).

## Garda

```
D:/GameDev/Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . res://tools/ProbeSealedTurbo.tscn
D:/GameDev/Godot_v4.7-stable_win64_console.exe --headless --path . res://tools/ProbeCareer.tscn -- --check
```
`ProbeSealedTurbo` (inregistrata in `verify_local.sh`): bara 0.3 ramane 0.3 sigilat in 6 s de gaz + drift; contra-proba cu `turbo_recharge=true` creste cu 0.7; cu TURBO tinut bara scade. `ProbeCareer` are acum `_check_time_trial` (medalii, `ai_count`, minim/maxim, semnale, steag) si verifica foaia pistei in `_check_panel`; sabotat `leave()` fara restaurare, pica.

## Abateri / alegeri

- Medalia de contratimp salveaza si cand timpul nu bate bronzul (0), doar ca timp.
- Dupa o cursa de contratimp, „BACK TO CAREER” ca la RACE; `MENU` apeleaza `go_to_menu` -> `Career.leave()`, deci `ai_count` se readuce.
- `ProbeCareer` modifica temporar tintele pistei Kyoto pe resursa incarcata (si le readuce) ca sa testeze `finish_time_trial` cu tinte reale.
- Cursa de contratimp nu a fost rulata cap-coada (headless nu poate); fluxul e acoperit de sonde pe `Career`/`Car`/panou si de parsarea scenelor.

## Ramane

Tintele de timp la volan (dezvoltatorul, 16 piste), provocarile (`ChallengeTracker` pe semnalele noi), rivalii, cupa, abtibildurile. Recordul separat de contratimp (brief 4.2) e acoperit de `tt_best_ms` din `career.cfg`.
