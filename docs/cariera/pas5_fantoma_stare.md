# Pasul 5 - fantoma din contratimp (stare)

Ramura `cariera/pas5-fantoma` (din `cariera/pas2-contratimp`). Local, fara server.

## Ce exista

- `scenes/career/ghost_data.gd` (`GhostData`): formatul + `transform_at(ms)`
  (lerp pe origin, slerp pe rotatie; inainte de primul = primul, dupa ultimul = ultimul).
- `scenes/career/ghost_recorder.gd` (`GhostRecorder`): copil al `Race`, doar in
  contratimp. De la `_go` esantioneaza `player.global_transform` la 20 Hz
  (acumulator pe `delta` in `_physics_process`), se opreste in `_finish_race`.
- `scenes/career/ghost_car.gd` (`GhostCar`, `Node3D`): doar modelul masinii
  (`Car.build_model`, functie statica scoasa din `_build_visual`, comportament
  identic), un singur material partajat semitransparent (alfa 0.45), fara umbra,
  zero corpuri de coliziune. `Race._tick_race` ii da ceasul cursei prin `set_clock_ms`.
- `Career`: `ghost_dir` (`user://ghosts/`), `ghost_path(id)`,
  `save_ghost_if_best(id, data, race_ms, previous_best_ms)`, `load_ghost(id)`.
- UI: eticheta `GHOST 3:12.4` langa SEALED, ` · GHOST` pe subtitlul butonului
  TIME TRIAL, ` · NEW GHOST` in titlul rezultatelor.
- Garda: `tools/probe_ghost.gd` + `ProbeGhost.tscn`, in `verify_local.sh` dupa
  "Rezervor sigilat".

## Formatul fisierului (`user://ghosts/<track_id>.bin`)

`StreamPeerBuffer`, little-endian:

```
i32 version (=1) | utf8 string track_id | i32 car_index | i32 laps |
i32 rate_hz | i32 total_ms | i32 sample_count | sample_count * 7 * f32
```

Un esantion = `origin.xyz` + quaternion `xyzw`. ~28 B/esantion; 3 tururi de 60 s
la 20 Hz = ~34 KB (sonda: 33.639 B pentru 1200 de esantioane).

Alegere: `StreamPeerBuffer` in loc de `store_var`, fiindcă are antet fix: versiunea
se citeste inainte de orice, iar lungimea sirului de esantioane se verifica exact
(fisier trunchiat = respins). Versiune diferita de 1 => `load_ghost` da null cu
`push_warning`, iar `save_ghost_if_best` NU suprascrie fisierul (regula `career.cfg`).

## Cum rulezi sonda

```
Godot --headless --fixed-fps 60 --path . res://tools/ProbeGhost.tscn
```

Numara: esantioane 1190..1210 pe 60 s, round-trip (1 cm / 0,5 grade, 50 momente),
interpolare pe cercul de raza 50 (+-0,5 m), fisier (scrie / nu rescrie pe timp
slab sau egal / rescrie pe timp mai bun / v99 neatins), GhostCar (mesh-uri >= 1,
0 corpuri fizice, 1 material transparent partajat, pozitia la `set_clock_ms`).
`MIN_CHECKS` = 60 (ruleaza 195).

## Abateri de la brief

- `GhostCar` nu are `_physics_process`: `set_clock_ms` seteaza direct
  `global_transform`; cursa il cheama in fiecare tick, deci e acelasi lucru.
- `GhostRecorder.to_bytes()` exista (cerut), dar poarta metadate goale; cursa
  foloseste `build_data(track_id, car_index, laps, total_ms)`.
- `save_ghost_if_best` primeste `previous_best_ms` explicit (varianta permisa de brief).
- Foaia pistei verifica doar `FileAccess.file_exists`, nu parseaza fisierul; un
  fisier corupt apare cu " · GHOST" dar `load_ghost` il ignora la start (fara fantoma, fara eticheta).
- Mașinile fără `palette_model` (FBX RgsDev) primesc un material simplu in culoarea masinii
  (n-au atlas), tot unul singur.
- `ProbeCareer` nu a fost extins (netrivial fara beneficiu; ghost-ul are sonda proprie).
- Verificat si cap-coada manual (script temporar, sters): `Race` in contratimp cu o
  fantoma salvata => `GhostRecorder` + `GhostCar` create, esantioane inregistrate, fantoma la pozitie.
  Terminarea unei curse reale cu salvare nu e acoperita de o garda automata.

## Ce ramane

- Fantoma rivalului (pasul 3) si fantoma "dev" - nu intra.
- Selectia "a ta / a rivalului".
- Ghost per mașină/numar de ture diferit: acum o singura fantoma per pista
  (cea mai buna, indiferent de masina; `car_index` decide modelul).
