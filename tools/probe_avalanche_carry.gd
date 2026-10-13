extends Node
## Defectul avalansei de pe ramura intai a serpentinelor (Track21, ~0.40):
## masa duce masina ~23 m spre dreapta (spre vale), iar repunerea o punea pe
## RAMURA A DOUA (castig de ~64 m). Sonda inghite o masina la axa avalansei si
## masoara unde e REPUSA: pe ce ramura, la cate fractii fata de locul inghitirii.
##
## Parapetul nu opreste caratul — masa muta `global_position` direct, fara
## coliziuni — asa ca remedierea e in checkpoint (`keep_origin_checkpoint`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAvalancheCarry.tscn \
##       -- --track=21 [--no-keep] [--no-parapet]
##
## Verdict OK doar daca masina e repusa IN SPATE fata de locul inghitirii
## (frac_dupa <= frac_inghitire) si pe aceeasi ramura (distanta pana la axa
## ramurii a doua > half_width). `--no-keep` = comportamentul vechi: trebuie sa
## arate defectul (sonda altfel ar fi verde pe zero masuratori).

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
var _track: Track
var _av: AvalancheHazard
var _car: Car
var _t: float = 0.0
var _state: int = 0
var _swallow_frac: float = 0.0
var _swallow_pos: Vector3
var _max_carry: float = 0.0
var _resp_pos: Vector3
var _prev_pos: Vector3
var _keep: bool = true
var _speeds: Array[float] = [14.0, 14.0, 14.0, 24.0, 24.0, 24.0]
## Decalajul lateral al masinii la inghitire (+ = spre vale/dreapta): pe axa, apoi pe
## jumatatea dinspre ramura a doua, unde defectul apare (24 m carat + 4-5 m decalaj
## ajung la <7 m de axa ramurii a doua).
var _lats: Array[float] = [0.0, 3.5, 5.5, 0.0, 3.5, 5.5]
var _case: int = 0
var _rows: Array[String] = []
var _bad: int = 0


func _ready() -> void:
	var track_arg := 21
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = int(arg.trim_prefix("--track="))
		elif arg == "--no-parapet":
			Track.probe_skip_parapets = true
		elif arg == "--no-keep":
			_keep = false
	var resolved := GameState.resolve_track_index(track_arg)
	GameState.selected_track = resolved
	_track = (load(GameState.TRACK_SCENES[resolved]) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var avs := _track.find_children("*", "AvalancheHazard", true, false)
	if avs.is_empty():
		print("PICAT: pista n-are AvalancheHazard")
		get_tree().quit(1)
		return
	_av = avs[0] as AvalancheHazard
	_av.keep_origin_checkpoint = _keep
	print("probe_avalanche_carry: keep_origin_checkpoint=%s parapet=%s hazard la %s"
		% [_keep, "OPRIT" if Track.probe_skip_parapets else "PORNIT", _av.global_position])
	_start_case()


func _frac(p: Vector3) -> float:
	return _track.frac_at(_track.closest_index_global(p))


func _start_case() -> void:
	if _car != null:
		_car.queue_free()
		_car = null
	if _case >= _speeds.size():
		_report()
		return
	var n := _track.baked.size()
	var idx := _track.closest_index_global(_av.global_position)
	var p: Vector3 = _track.baked[idx]
	var fwd: Vector3 = (_track.baked[(idx + 1) % n] - p).normalized()
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0] as CarData)
	_car.track = _track
	var start := p - fwd * 6.0 + _track._side_at(idx) * _lats[_case]
	start.y = p.y + 0.6
	_car.road_index = _track.closest_index_global(start)
	_car.last_safe_index = _car.road_index
	_car.global_position = start
	_car.look_at(start + fwd, Vector3.UP)
	_car.race_active = true
	_car.velocity = fwd * _speeds[_case]
	_t = 0.0
	_state = 0
	_max_carry = 0.0
	_swallow_frac = _frac(start)
	_swallow_pos = start


func _physics_process(delta: float) -> void:
	if _car == null or _av == null:
		return
	_t += delta
	match _state:
		0:
			# Cateva cadre de rulaj, apoi inghitirea directa (ocoleste ceasul
			# hazardului: caratul si repunerea sunt ce masuram, nu momentul).
			if _t > 0.3:
				_swallow_pos = _car.global_position
				_swallow_frac = _frac(_swallow_pos)
				_av._swallow(_car)
				_state = 1
				_t = 0.0
		1:
			_max_carry = maxf(_max_carry, _car.global_position.distance_to(_swallow_pos))
			if _t > 1.35 + 1.6:
				_resp_pos = _car.global_position
				var fr := _frac(_resp_pos)
				var idx := _track.closest_index_global(_resp_pos)
				var lat := absf(_track._side_at(idx).dot(_resp_pos - _track.baked[idx]))
				var behind := fr <= _swallow_frac + 0.0005
				var on_road := lat < _track.width_at_index(idx)
				var ok := behind and on_road
				if not ok:
					_bad += 1
				_rows.append("v=%2.0f m/s lat=%+.1f  inghitita la frac %.4f, carata %.1f m, repusa la frac %.4f (%+.1f m pe traseu) %s %s" % [
					_speeds[_case], _lats[_case], _swallow_frac, _max_carry, fr,
					(fr - _swallow_frac) * float(_track._dists[_track.baked.size()]),
					"IN SPATE" if behind else "IN FATA (cadou)", "pe sosea" if on_road else "IN AFARA"])
				_case += 1
				_start_case()


func _report() -> void:
	print("")
	for r in _rows:
		print(r)
	if _keep:
		print("VERDICT: %s" % ("OK" if _bad == 0 else "PROBLEMA"))
	else:
		print("VERDICT: %s (fara remediere: %d/%d cazuri cu defect)" % [
			"OK" if _bad > 0 else "PROBLEMA: defectul nu se reproduce, sonda nu dovedeste nimic", _bad, _rows.size()])
	get_tree().quit(0)
