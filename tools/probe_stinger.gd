extends Node
## Stinger de schimbare a pozitiei (docs/feel_checklist.md: position-change, partea
## de sunet), legat pe `PositionWatch.announced`.
##
## Verifica:
##   1. un PositionWatch real: 3 -> 2 tinut 0,4 s da UN stinger de urcare, 2 -> 3 unul
##      de coborare; 4 -> 3 -> 2 coalescat da UN singur stinger (urcare); o pozitie
##      care nu se tine nu da nimic; inactiv (numaratoare) nu da nimic;
##   2. stinger-ul e 2D, la `stinger_db`, la pitch exact (sunt note, fara zgomot de
##      pitch), scurt (sub 0,5 s), iar playerul real din pool poarta streamul;
##   3. in Race.tscn REAL semnalul `announced` e legat la stinger (si tot acolo la
##      popup): un anunt emis prin el scoate sunetul.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeStinger.tscn

const PositionWatchScript := preload("res://scenes/race/position_watch.gd")
const STEP: float = 1.0 / 60.0

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _names() -> Array:
	return AudioManager.sfx_log.map(func(e: Dictionary) -> StringName: return e["name"])


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== Stinger de pozitie ===")
	await _test_watch()
	_test_stream()
	await _test_race_wiring()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Tine pozitia `pos` timp de `seconds` prin observe(), tick cu tick.
func _hold(w: Node, pos: int, seconds: float, active: bool = true) -> void:
	for _f in int(round(seconds / STEP)):
		w.observe(pos, STEP, active)
		await get_tree().physics_frame


func _test_watch() -> void:
	print("")
	print("-- 1. PositionWatch -> stinger --")
	var w := PositionWatchScript.new()
	add_child(w)
	w.announced.connect(AudioManager.play_stinger)
	await _hold(w, 3, 0.2) # pozitia de referinta
	AudioManager.sfx_log.clear()
	await _hold(w, 2, 0.6)
	_check(_names() == [&"stinger_up"], "3 -> 2 tinut: un stinger de urcare %s" % str(_names()))
	AudioManager.sfx_log.clear()
	await _hold(w, 2, 1.0)
	await _hold(w, 3, 0.6)
	_check(_names() == [&"stinger_down"], "2 -> 3 tinut: un stinger de coborare %s" % str(_names()))
	# Coalescat: 3 -> 4 -> ... -> 1 in sub 0,4 s.
	await _hold(w, 3, 1.0)
	AudioManager.sfx_log.clear()
	await _hold(w, 2, 0.2)
	await _hold(w, 1, 0.7)
	_check(_names() == [&"stinger_up"], "3 -> 2 -> 1 coalescat: UN stinger de urcare %s" % str(_names()))
	# O pozitie care nu se tine.
	await _hold(w, 1, 1.0)
	AudioManager.sfx_log.clear()
	await _hold(w, 2, 0.2)
	await _hold(w, 1, 0.8)
	_check(_names().is_empty(), "pozitie pierduta si recastigata in 0,2 s: nimic")
	# Inactiv: numaratoarea inverse / dupa final.
	AudioManager.sfx_log.clear()
	await _hold(w, 5, 1.0, false)
	await _hold(w, 4, 1.0, false)
	_check(_names().is_empty(), "inactiv (active = false): nimic")
	# Direct: egal / zero.
	AudioManager.play_stinger(2, 2)
	AudioManager.play_stinger(0, 3)
	_check(_names().is_empty(), "pozitii egale sau zero: nimic")
	w.queue_free()


func _test_stream() -> void:
	print("")
	print("-- 2. stinger-ul in sine --")
	for sfx: StringName in [&"stinger_up", &"stinger_down"]:
		AudioManager.sfx_log.clear()
		if sfx == &"stinger_up":
			AudioManager.play_stinger(1, 2)
		else:
			AudioManager.play_stinger(2, 1)
		var e: Dictionary = AudioManager.sfx_log[0] if not AudioManager.sfx_log.is_empty() else {}
		_check(not e.is_empty() and e["name"] == sfx, "%s a sunat" % sfx)
		if e.is_empty():
			continue
		_check(not e["positional"], "%s: 2D" % sfx)
		_check(absf(float(e["db"]) - AudioManager.stinger_db) < 0.001, "%s: la stinger_db (%.1f)"
			% [sfx, float(e["db"])])
		_check(absf(float(e["pitch"]) - 1.0) < 0.0001, "%s: pitch exact (%.4f)" % [sfx, float(e["pitch"])])
		_check(AudioManager.stream(sfx).get_length() < 0.5, "%s: scurt (%.2f s)"
			% [sfx, AudioManager.stream(sfx).get_length()])
		var found := false
		for p in AudioManager._pool:
			if p.stream == AudioManager.stream(sfx) and absf(p.volume_db - AudioManager.stinger_db) < 0.01 \
					and absf(p.pitch_scale - 1.0) < 0.0001:
				found = true
		_check(found, "%s: playerul din pool poarta streamul, volumul si pitch-ul" % sfx)


func _test_race_wiring() -> void:
	print("")
	print("-- 3. cablaj in Race --")
	GameState.total_laps = 99
	GameState.selected_track = 12
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(race)
	var guard := 0
	while race.get("position_watch") == null and guard < 1500:
		await get_tree().process_frame
		guard += 1
	var watch: Node = race.get("position_watch")
	_check(watch != null, "Race.position_watch construit")
	if watch == null:
		race.queue_free()
		return
	var conns: Array = watch.announced.get_connections()
	var to_audio := false
	for c in conns:
		if (c["callable"] as Callable).get_object() == AudioManager:
			to_audio = true
	_check(to_audio, "`announced` e legat la AudioManager (%d consumatori)" % conns.size())
	AudioManager.sfx_log.clear()
	watch.announced.emit(2, 4)
	_check(_names() == [&"stinger_up"], "anunt 4 -> 2 prin semnalul din Race: stinger_up %s" % str(_names()))
	AudioManager.sfx_log.clear()
	watch.announced.emit(5, 3)
	_check(_names() == [&"stinger_down"], "anunt 3 -> 5: stinger_down %s" % str(_names()))
	race.queue_free()
	await get_tree().process_frame
