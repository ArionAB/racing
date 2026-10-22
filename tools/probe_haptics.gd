extends Node
## Vibratia (feel: haptics), fara hardware: tot ce vibreaza trece prin
## `HapticsFeed.pulse()`, iar sonda citeste jurnalul si captura de la `output`.
##
## Verifica:
##   A. marimea pulsului creste cu intensitatea (impact, aterizare), in
##      [15, 60] ms si [0.25, 1.0]; sub prag nu vibreaza nimic; turbo da un puls fix;
##   B. limita de ritm: cel mult un puls pe 0.15 s (ceas simulat), spatiate
##      cu 0.16 s trec toate;
##   C. setarea oprita => zero pulsuri; reactivata => revin;
##   D. setarea persista (GameState.save_settings/load_settings), implicit pornita,
##      fara a strica fisierul real de setari al dezvoltatorului (se face backup);
##   E. cablajul din Race.tscn REAL: nimic in numaratoare, pulsuri in cursa de la
##      semnalele jucatorului, nimic dupa final; maneta/telefonul primesc aceleasi.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHaptics.tscn

const FeedScript := preload("res://scenes/race/haptics_feed.gd")

var _failed: bool = false
var _t: float = 0.0
var _captured: Array = []


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== Vibratie ===")
	var measured := 0
	var feed: Node = FeedScript.new()
	add_child(feed)
	var car := Car.new()
	add_child(car)
	feed.setup(car)
	feed.clock = func() -> float: return _t
	feed.output = func(ms: int, amp: float) -> void: _captured.append([ms, amp])
	measured += _part_a(feed, car)
	measured += _part_b(feed, car)
	measured += _part_c(feed, car)
	measured += _part_d()
	if measured == 0:
		_check(false, "n-am masurat nimic")
	await _part_e()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Trece timpul simulat cu `dt` secunde (peste limita de ritm daca dt >= 0.15).
func _advance(dt: float) -> void:
	_t += dt


func _fire(feed: Node, car: Car, strength: float) -> Dictionary:
	_advance(0.5)
	var n := _captured.size()
	car.impact.emit(car, &"wall", strength, Vector3.BACK, Vector3.ZERO, null)
	if _captured.size() > n:
		return {"ms": _captured[n][0], "amp": _captured[n][1]}
	return {}


func _part_a(feed: Node, car: Car) -> int:
	print("")
	print("-- A. marimea pulsului urmeaza intensitatea --")
	var low := _fire(feed, car, 4.0)
	var mid := _fire(feed, car, 10.0)
	var high := _fire(feed, car, 20.0)
	var over := _fire(feed, car, 60.0)
	print("  impact 4 m/s: %s · 10 m/s: %s · 20 m/s: %s · 60 m/s: %s" % [low, mid, high, over])
	_check(not low.is_empty() and not mid.is_empty() and not high.is_empty(),
		"fiecare impact peste prag vibreaza")
	if low.is_empty() or mid.is_empty() or high.is_empty():
		return 0
	_check(int(low.ms) < int(mid.ms) and int(mid.ms) < int(high.ms), "durata creste cu forta")
	_check(float(low.amp) < float(mid.amp) and float(mid.amp) < float(high.amp),
		"amplitudinea creste cu forta")
	_check(int(low.ms) >= 15 and int(over.ms) <= 60, "durata ramane in [15, 60] ms")
	_check(float(low.amp) >= 0.25 and float(over.amp) <= 1.0, "amplitudinea ramane in [0.25, 1]")
	var faint := _fire(feed, car, 1.0)
	_check(faint.is_empty(), "sub prag (1 m/s) nu vibreaza")
	# Aterizare.
	_advance(0.5)
	var n := _captured.size()
	car.landed.emit(car, 8.0)
	_advance(0.5)
	car.landed.emit(car, 18.0)
	_advance(0.5)
	car.landed.emit(car, 3.0)
	print("  aterizari 8 / 18 / 3 m/s => %d pulsuri: %s" % [_captured.size() - n,
		_captured.slice(n)])
	_check(_captured.size() - n == 2, "aterizarea moale (3 m/s) nu vibreaza, cele dure da")
	if _captured.size() - n == 2:
		_check(int(_captured[n + 1][0]) > int(_captured[n][0]), "aterizarea mai dura vibreaza mai lung")
	# Turbo.
	_advance(0.5)
	n = _captured.size()
	car.boost_started.emit(car)
	_check(_captured.size() == n + 1 and _captured[n][0] == 30,
		"pornirea turbo-ului da un puls de 30 ms")
	return 1


func _part_b(feed: Node, car: Car) -> int:
	print("")
	print("-- B. limita de ritm: cel mult un puls / 0.15 s --")
	_advance(1.0)
	var n := _captured.size()
	# 40 de impacturi, unul la 10 ms (0.4 s).
	for i in 40:
		_t += 0.01
		car.impact.emit(car, &"wall", 15.0, Vector3.BACK, Vector3.ZERO, null)
	var burst := _captured.size() - n
	print("  40 impacturi in 0.4 s => %d pulsuri (maxim 3 posibile)" % burst)
	_check(burst >= 1 and burst <= 3, "rafala de 0.4 s: 1..3 pulsuri (nu 40)")
	# Spatiate cu 0.16 s trec toate.
	_advance(1.0)
	n = _captured.size()
	for i in 10:
		_t += 0.16
		car.impact.emit(car, &"wall", 15.0, Vector3.BACK, Vector3.ZERO, null)
	print("  10 impacturi la 0.16 s => %d pulsuri" % (_captured.size() - n))
	_check(_captured.size() - n == 10, "la 0.16 s intre ele trec toate 10")
	# Nicio pereche consecutiva din jurnal nu e mai aproape de 0.15 s.
	var min_gap := 99.0
	for i in range(1, feed.pulse_log.size()):
		min_gap = minf(min_gap, float(feed.pulse_log[i].t) - float(feed.pulse_log[i - 1].t))
	print("  cel mai mic interval din jurnal: %.3f s" % min_gap)
	_check(min_gap >= 0.15 - 1e-6, "jurnalul nu are doua pulsuri la mai putin de 0.15 s")
	return 1


func _part_c(feed: Node, car: Car) -> int:
	print("")
	print("-- C. setarea oprita => zero pulsuri --")
	var was: bool = GameState.haptics_enabled
	GameState.haptics_enabled = false
	_advance(1.0)
	var n := _captured.size()
	car.impact.emit(car, &"car", 25.0, Vector3.BACK, Vector3.ZERO, null)
	_advance(0.5)
	car.landed.emit(car, 20.0)
	_advance(0.5)
	car.boost_started.emit(car)
	print("  oprit: %d pulsuri la output, %d refuzate (off)" % [_captured.size() - n, feed.dropped.off])
	_check(_captured.size() == n, "cu vibratia oprita nu iese niciun puls")
	_check(int(feed.dropped.off) >= 3, "cele 3 evenimente au fost numarate ca refuzate")
	GameState.haptics_enabled = true
	_advance(1.0)
	car.impact.emit(car, &"car", 25.0, Vector3.BACK, Vector3.ZERO, null)
	_check(_captured.size() == n + 1, "pornita la loc: pulsul revine")
	GameState.haptics_enabled = was
	return 1


func _part_d() -> int:
	print("")
	print("-- D. setarea persista --")
	var path: String = GameState.SETTINGS_PATH
	var had := FileAccess.file_exists(path)
	var backup := PackedByteArray()
	if had:
		backup = FileAccess.get_file_as_bytes(path)
	var was: bool = GameState.haptics_enabled
	_check(was, "implicit pornita (valoarea curenta fara fisier explicit: true)")
	GameState.haptics_enabled = false
	GameState.save_settings()
	GameState.haptics_enabled = true
	GameState.load_settings()
	_check(not GameState.haptics_enabled, "oprita + salvata + reincarcata => ramane oprita")
	GameState.haptics_enabled = true
	GameState.save_settings()
	GameState.haptics_enabled = false
	GameState.load_settings()
	_check(GameState.haptics_enabled, "pornita + salvata + reincarcata => ramane pornita")
	# Fisier vechi fara cheia: implicit pornita.
	var cfg := ConfigFile.new()
	cfg.set_value("input", "steer_sensitivity", 1.0)
	cfg.save(path)
	GameState.haptics_enabled = false
	GameState.load_settings()
	_check(GameState.haptics_enabled, "fisier fara cheie => implicit pornita")
	# Restaureaza fisierul dezvoltatorului exact cum era.
	if had:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_buffer(backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	GameState.load_settings()
	GameState.haptics_enabled = was
	return 1


func _part_e() -> void:
	print("")
	print("-- E. cablaj in Race.tscn --")
	GameState.total_laps = 99
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(race)
	var guard := 0
	while race.get("haptics") == null and guard < 1500:
		await get_tree().process_frame
		guard += 1
	var hf: Node = race.get("haptics")
	_check(hf != null, "Race.haptics construit")
	if hf == null:
		return
	var player: Car = race.player
	var got: Array = []
	hf.output = func(ms: int, amp: float) -> void: got.append([ms, amp])
	# Ceas simulat: headless-ul ruleaza mai repede decat timpul real, deci limita de
	# ritm (in secunde reale) s-ar vedea gresit cu pauzele de joc.
	hf.clock = func() -> float: return _t
	_check(race.state == race.State.COUNTDOWN, "cursa e in numaratoare")
	player.impact.emit(player, &"wall", 15.0, Vector3.BACK, Vector3.ZERO, null)
	player.landed.emit(player, 15.0)
	print("  numaratoare: %d pulsuri, %d refuzate (idle)" % [got.size(), hf.dropped.idle])
	_check(got.is_empty() and int(hf.dropped.idle) >= 2, "nimic in numaratoare")
	var g2 := 0
	while race.state != race.State.RUNNING and g2 < 3000:
		await get_tree().physics_frame
		g2 += 1
	_check(race.state == race.State.RUNNING, "cursa a pornit")
	_advance(0.5)
	got.clear()
	player.impact.emit(player, &"car", 12.0, Vector3.BACK, Vector3.ZERO, null)
	_check(got.size() == 1, "in cursa: impactul jucatorului vibreaza")
	_advance(0.5)
	# Un impact al UNEI ALTE masini nu vibreaza (doar jucatorul).
	var other: Car = race.cars[1]
	var n := got.size()
	other.impact.emit(other, &"car", 18.0, Vector3.BACK, Vector3.ZERO, null)
	_check(got.size() == n, "impactul unui AI nu vibreaza telefonul")
	_advance(0.5)
	n = got.size()
	player.landed.emit(player, 14.0)
	_check(got.size() == n + 1, "in cursa: aterizarea dura vibreaza")
	race.call("_finish_race")
	_advance(0.5)
	n = got.size()
	player.impact.emit(player, &"wall", 20.0, Vector3.BACK, Vector3.ZERO, null)
	_check(got.size() == n, "dupa final: nimic")
	Engine.time_scale = 1.0
