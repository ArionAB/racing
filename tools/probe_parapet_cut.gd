extends Node
## SABOTAJ pentru parapetele serpentinelor (Track21): incearca sa TAI o
## serpentina coborand pe iarba de pe o ramura pe urmatoarea.
##
## Pune o masina pe ramura N, aproape de marginea din vale, cu botul spre vale
## (perpendicular sau pe diagonala, la doua viteze), cu acceleratia apasata si
## volanul drept — NU un AI, care s-ar intoarce singur pe sosea. Masoara daca
## ajunge pe ramura N+1 (o mai apropie de ea decat half_width de un punct copt
## al ramurii urmatoare).
##
## Verdict, cu parapet: NICIUN caz de taiere (in afara golului declarat la
## acul 3, care TREBUIE sa taie). Fara parapet (`--no-parapet`): taie, altfel
## sonda n-ar dovedi nimic (garda verde pe zero masuratori).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeParapetCut.tscn \
##       -- --track=21 [--no-parapet]

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const SECONDS: float = 7.0
## (eticheta, fractia de pe ramura, fractia de pe ramura urmatoare, deschidere?)
## Ramurile sunt cele din gen_transfagarasan_route.py (PARAP). 0.493 e in golul
## de la acul 3 (scurtatura ciobanilor, brief §3.1 decizia 4).
const CASES: Array[Dictionary] = [
	{"label": "ramura1", "f": 0.391, "next": 0.4415, "gap": false},
	{"label": "ramura2", "f": 0.4415, "next": 0.482, "gap": false},
	{"label": "ramura3", "f": 0.482, "next": 0.536, "gap": false},
	{"label": "ramura3-gol", "f": 0.493, "next": 0.536, "gap": true},
	{"label": "ramura4", "f": 0.536, "next": 0.60, "gap": false},
	# Acele de par la mijlocul arcului, iesire spre EXTERIOR (ext) sau INTERIOR
	# (int). Aici nu exista "ramura urmatoare" de atins (`next` < 0, `side`
	# fixeaza latura): trecerea de parapet = ai iesit >1.5 m din drum.
	{"label": "ac1-ext", "f": 0.419, "next": -1.0, "side": -1.0, "gap": false},
	{"label": "ac1-int", "f": 0.419, "next": -1.0, "side": 1.0, "gap": false},
	{"label": "ac2-ext", "f": 0.4635, "next": -1.0, "side": 1.0, "gap": false},
	{"label": "ac2-int", "f": 0.4635, "next": -1.0, "side": -1.0, "gap": false},
	{"label": "ac3-ext", "f": 0.5165, "next": -1.0, "side": -1.0, "gap": false},
	{"label": "ac3-int", "f": 0.5165, "next": -1.0, "side": 1.0, "gap": false},
	{"label": "ac4-ext", "f": 0.5585, "next": -1.0, "side": 1.0, "gap": false},
	{"label": "ac4-int", "f": 0.5585, "next": -1.0, "side": -1.0, "gap": false},
]
const SPEEDS: Array[float] = [12.0, 22.0]
## Unghiul fata de directia de mers, spre vale: 90 = perpendicular.
const ANGLES: Array[float] = [90.0, 50.0]

var _track: Track = null
var _runs: Array[Dictionary] = []
var _run: int = -1
var _combos: Array[Dictionary] = []
var _car: Car = null
var _t: float = 0.0
var _min_to_next: float = 999.0
var _max_exc: float = 0.0
var _next_range: Array[int] = []
var _valley_sign: float = 1.0
var _idx0: int = 0
var _done: bool = false
var _hit_parapet: bool = false


func _ready() -> void:
	var track_arg := 21
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = int(arg.trim_prefix("--track="))
		elif arg == "--no-parapet":
			Track.probe_skip_parapets = true
	var resolved := GameState.resolve_track_index(track_arg)
	if resolved < 0:
		printerr("probe_parapet_cut: --track invalid")
		get_tree().quit(1)
		return
	GameState.selected_track = resolved
	_track = (load(GameState.TRACK_SCENES[resolved]) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for c in CASES:
		for sp in SPEEDS:
			for an in ANGLES:
				_combos.append({"case": c, "speed": sp, "angle": an})
	print("probe_parapet_cut: %d cazuri, parapet %s" % [_combos.size(),
		"OPRIT (sabotaj)" if Track.probe_skip_parapets else "PORNIT"])
	_next_case()


func _idx_at(frac: float) -> int:
	return int(frac * float(_track.baked.size())) % _track.baked.size()


func _next_case() -> void:
	if _car != null:
		_car.queue_free()
		_car = null
	_run += 1
	if _run >= _combos.size():
		_report()
		return
	var combo: Dictionary = _combos[_run]
	var c: Dictionary = combo["case"]
	var n := _track.baked.size()
	var idx := _idx_at(float(c["f"]))
	_idx0 = idx
	var p: Vector3 = _track.baked[idx]
	var fwd: Vector3 = (_track.baked[(idx + 1) % n] - p).normalized()
	var side := _track._side_at(idx)
	# Latura vaii = cea dinspre ramura urmatoare.
	if float(c["next"]) >= 0.0:
		var q: Vector3 = _track.baked[_idx_at(float(c["next"]))]
		_valley_sign = signf(side.dot(q - p))
	else:
		_valley_sign = float(c["side"])
	var valley := side * _valley_sign
	var hw := _track.width_at_index(idx)
	var start := p + valley * (hw - 3.0)
	start.y = p.y + 0.6
	var ang := deg_to_rad(float(combo["angle"]))
	var dir := (fwd * cos(ang) + valley * sin(ang)).normalized()
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0] as CarData)
	_car.track = _track
	_car.road_index = _track.closest_index_global(start)
	_car.last_safe_index = _car.road_index
	_car.global_position = start
	_car.look_at(start + dir, Vector3.UP)
	_car.race_active = true
	_car.velocity = dir * float(combo["speed"])
	_t = 0.0
	_min_to_next = 999.0
	_max_exc = 0.0
	_hit_parapet = false
	# Indicii ramurii urmatoare (+-15 m in jurul fractiei ei).
	_next_range.clear()
	if float(c["next"]) >= 0.0:
		var span := int(15.0 / 3.0)
		var ni := _idx_at(float(c["next"]))
		for k in range(-span, span + 1):
			_next_range.append((ni + k + n) % n)


func _physics_process(delta: float) -> void:
	if _car == null or _done or _run >= _combos.size():
		return
	_t += delta
	var pos := _car.global_position
	for i in _next_range:
		var b: Vector3 = _track.baked[i]
		var d := Vector2(pos.x - b.x, pos.z - b.z).length()
		_min_to_next = minf(_min_to_next, d - _track.width_at_index(i))
	var idx := _track.closest_index_global(pos)
	var b2: Vector3 = _track.baked[idx]
	var exc := _track._side_at(idx).dot(pos - b2) * _valley_sign - _track.width_at_index(idx)
	_max_exc = maxf(_max_exc, exc)
	for b in _car.get_colliding_bodies():
		if b is Node3D and (b as Node3D).name == "Parapet":
			_hit_parapet = true
	if _t >= SECONDS:
		var combo: Dictionary = _combos[_run]
		var c2: Dictionary = combo["case"]
		_runs.append({"label": (combo["case"] as Dictionary)["label"], "gap": (combo["case"] as Dictionary)["gap"],
			"speed": combo["speed"], "angle": combo["angle"],
			"reached": (_min_to_next < 0.0) if float(c2["next"]) >= 0.0 else (_max_exc > 1.5), "min_next": _min_to_next, "exc": _max_exc, "hit": _hit_parapet})
		_next_case()


func _report() -> void:
	print("\n%-14s %6s %6s %9s %10s %9s %s" % ["caz", "v m/s", "unghi", "taie?", "min->next", "exc vale", "parapet"])
	var cuts_closed := 0
	var cuts_gap := 0
	var gap_cases := 0
	for r in _runs:
		print("%-14s %6.0f %6.0f %9s %9.1f m %7.1f m %s" % [r["label"], r["speed"], r["angle"],
			"DA" if r["reached"] else "nu", r["min_next"], r["exc"], "atins" if r["hit"] else "-"])
		if r["gap"]:
			gap_cases += 1
			if r["reached"]:
				cuts_gap += 1
		elif r["reached"]:
			cuts_closed += 1
	print("\ntaieri pe portiuni inchise: %d / %d · taieri prin golul acului 3: %d / %d"
		% [cuts_closed, _runs.size() - gap_cases, cuts_gap, gap_cases])
	if Track.probe_skip_parapets:
		# Sabotajul: fara parapet trebuie sa taie (macar o parte din cazuri).
		var any := cuts_closed + cuts_gap
		print("VERDICT: %s (fara parapet: %d taieri)" % ["OK" if any > 0 else "PROBLEMA: sonda nu taie nici fara parapet", any])
	else:
		print("VERDICT: %s" % ("OK" if cuts_closed == 0 else "PROBLEMA"))
	_done = true
	get_tree().quit(0)
