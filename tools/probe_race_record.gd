extends Node
## #498: recordul pe toata cursa. O cursa de 1 tur, cu un AI la volanul
## jucatorului, si o pauza de 2 s in mijlocul ei. Verifica:
##   - la sosire, `GameState.best_race` = timpul cursei, iar fisierul de
##     recorduri il contine (recitit de pe disc);
##   - pauza NU intra in timp (ceasul cursei sta cat arborele e pe pauza);
##   - pe 1 tur, timpul turului = timpul cursei (acelasi ceas).
## `user://records.cfg` al masinii e salvat la inceput si pus la loc la final.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRaceRecord.tscn -- [--track=6]

const RACE_SCENE := "res://scenes/race/Race.tscn"
const PAUSE_AT_S := 20.0
const PAUSE_S := 2.0

var _race: Race
var _backup: PackedByteArray
var _had_file := false
var _t := 0.0
var _paused_at := -1.0
var _clock_before := 0.0
var _clock_after := -1.0
var _fails: PackedStringArray = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_had_file = FileAccess.file_exists(GameState.RECORDS_PATH)
	if _had_file:
		_backup = FileAccess.get_file_as_bytes(GameState.RECORDS_PATH)
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 1
	# Fara record vechi pe pista asta: primul timp trebuie sa devina record.
	GameState.race_records.erase(GameState.race_record_key(idx, 1))
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	# Copilul sondei ar mosteni PROCESS_MODE_ALWAYS; in joc Race e radacina
	# scenei, deci se opreste pe pauza.
	_race.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_race)
	var p := _race.player
	var old: CarController = p.controller
	p.remove_child(old)
	old.free()
	var ai := AIController.new()
	p.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	ai.configure(_race.track, rng, _race.cars.duplicate())


func _process(delta: float) -> void:
	_t += delta
	if _paused_at >= 0.0 and get_tree().paused and _t - _paused_at >= PAUSE_S:
		get_tree().paused = false
		_clock_after = _race._race_clock
	if _race.state == Race.State.RUNNING and _paused_at < 0.0 \
			and _race._race_clock >= PAUSE_AT_S:
		_paused_at = _t
		_clock_before = _race._race_clock
		get_tree().paused = true
	if _race.state == Race.State.FINISHED and _race._player_race_ms >= 0:
		_report()
	if _t > 400.0:
		_fails.append("cursa neterminata in 400 s")
		_finish()


func _report() -> void:
	var ms := _race._player_race_ms
	var key := GameState.race_record_key(GameState.selected_track, 1)
	var cfg := ConfigFile.new()
	cfg.load(GameState.RECORDS_PATH)
	var on_disk := int(cfg.get_value("race_records", key, 0))
	print("[race-record] cursa %d ms, best_race %d, pe disc %d, tur %d ms, record nou %s"
		% [ms, GameState.best_race(GameState.selected_track), on_disk,
			_race._best_lap_ms, _race._race_record_new])
	print("[race-record] pauza: ceas %.3f -> %.3f dupa %.1f s de pauza"
		% [_clock_before, _clock_after, PAUSE_S])
	if GameState.best_race(GameState.selected_track) != ms:
		_fails.append("best_race != timpul cursei")
	if on_disk != ms:
		_fails.append("recordul nu e pe disc (%d)" % on_disk)
	if not _race._race_record_new:
		_fails.append("primul timp n-a fost marcat record")
	if _clock_after < 0.0 or absf(_clock_after - _clock_before) > 0.05:
		_fails.append("ceasul a curs in pauza (%.3f -> %.3f)" % [_clock_before, _clock_after])
	if absi(_race._best_lap_ms - ms) > 20:
		_fails.append("pe 1 tur, turul (%d) != cursa (%d)" % [_race._best_lap_ms, ms])
	_finish()


func _finish() -> void:
	if _had_file:
		var f := FileAccess.open(GameState.RECORDS_PATH, FileAccess.WRITE)
		f.store_buffer(_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.RECORDS_PATH))
	for f in _fails:
		print("    " + f)
	print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
	get_tree().quit(0)
	set_process(false)
