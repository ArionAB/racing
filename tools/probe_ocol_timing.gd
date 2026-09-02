extends Node
## CAT COSTA ocolul pietrei fata de culoarul scurt? (Cappadocia, POI F)
##
## Brieful cere "+2.5 s" pentru culoarul lung. Sonda masoara EXACT segmentul
## dintre bifurcatie si revenire (fractiile FROM..TO de pe bucla), pe masini
## conduse de acelasi creier AI: jumatate din pluton e fortata pe ocol
## (`prefers_shortcut = true` — pe pista asta ramura desenata E ocolul sigur),
## jumatate pe culoarul scurt. Diferenta mediilor e costul masurat.
##
## Traficul si piatra raman pornite: costul care conteaza e cel din joc, nu
## cel dintr-un tur de unul singur. De-asta se raporteaza si numarul de
## traversari pe fiecare brat, nu doar media.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeOcolTiming.tscn -- --track=6 --seconds=240 --seed=1
const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const FROM: float = 0.700
const TO: float = 0.7555

var _race: Node
var _seed: int = 1
var _seconds: float = 240.0
var _track_index: int = 6
var _elapsed: float = 0.0
var _state: Array = [] # per masina: {in_seg, t0, on_branch}
var _samples_short: Array[float] = []
var _samples_long: Array[float] = []
var _done: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
	GameState.selected_car = 0
	GameState.selected_track = GameState.resolve_track_index(_track_index)
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	(_race._rng as RandomNumberGenerator).seed = _seed
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == player:
			var ai := AIController.new()
			car.set_controller(ai)
			ai.configure(_race.track, rng, cars)
		car.speed_scale = 1.0 # acelasi plafon: masuram traseul, nu masina
		# Jumatate pe ocol, jumatate pe scurt — impus, nu tras la zaruri.
		(car.controller as AIController).prefers_shortcut = (i % 2 == 0)
		_state.append({"in_seg": false, "t0": 0.0, "on_branch": false})


func _physics_process(delta: float) -> void:
	if _done or _race == null:
		return
	_elapsed += delta
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		var st: Dictionary = _state[i]
		var f: float = _race.track.frac_at(car.road_index, car.route)
		if not bool(st.in_seg):
			if f >= FROM and f < FROM + 0.004:
				st.in_seg = true
				st.t0 = _elapsed
				st.on_branch = false
		else:
			if car.route > 0:
				st.on_branch = true
			if f >= TO and f < TO + 0.03:
				var dt: float = _elapsed - float(st.t0)
				# O repunere sau un blocaj umfla proba fara sa spuna nimic
				# despre traseu; peste 30 s nu mai e o traversare, e un accident.
				if dt < 30.0:
					if bool(st.on_branch):
						_samples_long.append(dt)
					else:
						_samples_short.append(dt)
				st.in_seg = false
			elif f < FROM - 0.02 or f > TO + 0.05:
				st.in_seg = false # repus in alta parte a pistei
	if _elapsed >= _seconds:
		_report()


func _report() -> void:
	_done = true
	print("=== ProbeOcolTiming — seed %d, %.0f s, segment %.3f-%.3f ===" % [
		_seed, _elapsed, FROM, TO])
	for pair in [["SCURT (prin piatra)", _samples_short],
			["LUNG  (ocolul)", _samples_long]]:
		var label: String = pair[0]
		var arr: Array[float] = pair[1]
		if arr.is_empty():
			print("  %s: nicio traversare" % label)
			continue
		var sum := 0.0
		for v in arr:
			sum += v
		print("  %s: %d traversari, medie %.2f s (min %.2f, max %.2f)" % [
			label, arr.size(), sum / arr.size(), arr.min(), arr.max()])
	if not _samples_short.is_empty() and not _samples_long.is_empty():
		var ms := 0.0
		for v in _samples_short:
			ms += v
		var ml := 0.0
		for v in _samples_long:
			ml += v
		print("  DIFERENTA (lung - scurt): %+.2f s  (tinta brief: +2.5 s)" % [
			ml / _samples_long.size() - ms / _samples_short.size()])
	get_tree().quit()
