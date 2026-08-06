extends Node
## Sonda TEMPORARA: se poate reintra pe sosea dupa ce ai iesit pe nisip?
##
## Doua masuratori, ambele headless:
##   step  — raycast in jos pe un profil transversal (de la axa pana la 10 m
##           dincolo de asfalt) si raporteaza TREAPTA de la marginea drumului.
##           Masoara coliziunea reala, nu campul de inaltime: exact ce atinge
##           masina.
##   drive — pune masina pe nisip, cu botul spre sosea, si vede daca ajunge
##           inapoi pe asfalt. Fara plasa de repunere din race.gd.
##
## Rulare:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeReentry.tscn \
##       -- --mode=step --track=0

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Fractiile de traseu testate.
const FRACS: Array[float] = [0.05, 0.18, 0.31, 0.44, 0.57, 0.70, 0.83, 0.95]
## Offseturi fata de MARGINEA asfaltului, in metri (negativ = pe asfalt).
const PROFILE: Array[float] = [-2.0, -0.5, 0.1, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 8.0]
## Cat de sus incepe raza si cat de jos coboara.
const RAY_UP: float = 40.0
const RAY_DOWN: float = 60.0

## Cat de departe de marginea asfaltului porneste masina in modul drive.
const DRIVE_OFFSET: float = 5.0
## Unghiul de atac spre sosea (0 = paralel cu drumul, 90 = perpendicular).
const DRIVE_ANGLE_DEG: float = 30.0
const DRIVE_ENTRY_SPEED: float = 14.0
const DRIVE_SECONDS: float = 8.0

var _mode: String = "step"
var _track_index: int = 0
var _track: Track = null
var _rows: Array[Dictionary] = []
var _case: int = -1
var _cases: Array[Dictionary] = []
var _car: Car = null
var _time: float = 0.0
var _back_on: bool = false
var _min_lat: float = INF
var _done: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.substr(7)
		elif arg.begins_with("--track="):
			_track_index = int(arg.substr(8))
	GameState.selected_track = _track_index
	_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_track)
	# Doua cadre de fizica inainte de orice raycast: colizoarele abia s-au
	# adaugat in scena si spatiul nu le stie inca.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _mode == "step":
		_run_step()
	else:
		var n := _track.baked.size()
		for frac in FRACS:
			for side: float in [-1.0, 1.0]:
				_cases.append({"idx": int(frac * float(n)) % n,
					"side": side, "frac": frac})
		_next_drive_case()


func _side_at(i: int) -> Vector3:
	var n := _track.baked.size()
	var dir: Vector3 = (_track.baked[(i + 1) % n] - _track.baked[i]).normalized()
	return dir.cross(Vector3.UP).normalized()


func _ray(x: float, z: float) -> Dictionary:
	var space := get_viewport().world_3d.direct_space_state
	var from := Vector3(x, RAY_UP, z)
	var to := Vector3(x, -RAY_DOWN, z)
	# Colideaza cu TOT: sosea, teren, faleze.
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = false
	return space.intersect_ray(q)


func _run_step() -> void:
	print("\n=== PROFIL TRANSVERSAL, COLIZIUNE REALA (%s) ==="
		% GameState.TRACK_NAMES[_track_index])
	print("offset = metri dincolo de marginea asfaltului (negativ = pe asfalt)")
	var header := "%8s %5s" % ["fractie", "parte"]
	for off: float in PROFILE:
		header += " %7.1f" % off
	header += " %8s" % "treapta"
	print(header)
	print("-".repeat(header.length()))
	var worst := 0.0
	var blocked := 0
	for frac: float in FRACS:
		var n := _track.baked.size()
		var idx := int(frac * float(n)) % n
		var base: Vector3 = _track.baked[idx]
		for side: float in [-1.0, 1.0]:
			var lat := _side_at(idx) * side
			var line := "%8.2f %5s" % [frac, "st" if side < 0.0 else "dr"]
			var edge_y := INF
			var sand_y := INF
			for off: float in PROFILE:
				var p := base + lat * (_track.half_width + off)
				var hit := _ray(p.x, p.z)
				if hit.is_empty():
					line += " %7s" % "-"
					continue
				var y: float = (hit["position"] as Vector3).y
				line += " %7.2f" % y
				if is_equal_approx(off, -0.5):
					edge_y = y
				if is_equal_approx(off, 2.0):
					sand_y = y
			var step := edge_y - sand_y if edge_y < INF and sand_y < INF else 0.0
			line += " %8.2f" % step
			worst = maxf(worst, step)
			# Peste ~0.15 m un CharacterBody3D cu cutie nu mai urca: fundul
			# cutiei sta la 0.1 deasupra originii, iar Godot nu are step-up.
			if step > 0.15:
				blocked += 1
			print(line)
	print("\ntreapta maxima: %.2f m; %d/%d profile peste 0.15 m"
		% [worst, blocked, FRACS.size() * 2])
	_quit(1 if blocked > 0 else 0)


func _next_drive_case() -> void:
	if _car != null:
		_car.queue_free()
		_car = null
	_case += 1
	if _case >= _cases.size():
		_report_drive()
		return
	var c := _cases[_case]
	var idx: int = c["idx"]
	var side: float = c["side"]
	var n := _track.baked.size()
	var p: Vector3 = _track.baked[idx]
	var fwd: Vector3 = (_track.baked[(idx + 1) % n] - p).normalized()
	var lat := _side_at(idx) * side
	var start := p + lat * (_track.half_width + DRIVE_OFFSET)
	# Pe SOLUL de acolo, nu la o cota inventata — si daca solul e o faleza,
	# cazul se sare: am masura "masina intepenita in stanca", nu reintrarea.
	# Peretii de canion au sonda lor (probe_race --mode=cliff).
	var hit := _ray(start.x, start.z)
	if hit.is_empty() or (hit["position"] as Vector3).y > p.y + 1.0:
		_skip(c, "faleza")
		return
	start.y = (hit["position"] as Vector3).y + 0.6
	# Un ZID intre nisip si asfalt inseamna ca locul asta e inchis intentionat
	# (gardul de pe exteriorul circuitului). Masina n-are cum sa ajunga acolo
	# intr-o cursa, deci nu e cazul pe care il masuram — sonda ar raporta ca
	# esec exact regula de design.
	var space := get_viewport().world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		start + Vector3.UP * 0.5, p + Vector3.UP * 0.5)
	if not space.intersect_ray(q).is_empty():
		_skip(c, "zid")
		return
	# Botul spre sosea, sub DRIVE_ANGLE_DEG fata de directia de mers.
	var dir := fwd.rotated(Vector3.UP, deg_to_rad(DRIVE_ANGLE_DEG) * side) \
		.normalized()
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0] as CarData)
	_car.track = _track
	_car.road_index = _track.closest_index_global(start)
	_car.last_safe_index = _car.road_index
	_car.global_position = start
	_car.look_at(start + dir, Vector3.UP)
	_car.race_active = true
	# AI adevarat la volan, nu volan blocat: cu unghi fix masina descrie un cerc
	# si "nu s-a intors pe sosea" ar putea insemna doar ca a virat prea tare.
	# AIController tine linia si stie sa dea marsarier daca se opreste — daca
	# NICI EL nu urca inapoi, atunci chiar geometria e de vina.
	var ai := AIController.new()
	_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260806 + _case
	ai.configure(_track, rng)
	_car.velocity = dir * DRIVE_ENTRY_SPEED
	_time = 0.0
	_back_on = false
	_min_lat = INF


## Cazul nu se poate masura: se noteaza cu motivul si se trece mai departe.
func _skip(c: Dictionary, why: String) -> void:
	_rows.append({"frac": c["frac"], "side": c["side"], "skip": why,
		"back": false, "t": 0.0, "min_lat": 0.0})
	_next_drive_case()


func _physics_process(delta: float) -> void:
	if _mode != "drive" or _car == null or _done:
		return
	_time += delta
	var idx := _track.closest_index_global(_car.global_position)
	var p: Vector3 = _track.baked[idx]
	var lat := absf(_side_at(idx).dot(_car.global_position - p))
	_min_lat = minf(_min_lat, lat)
	if lat < _track.half_width - 0.5:
		_back_on = true
	if _back_on or _time >= DRIVE_SECONDS:
		var c := _cases[_case]
		# Cine o tine pe loc — fara asta un esec spune doar "nu s-a intors",
		# nu si daca vina e a terenului, a unei stanci sau a unui gard.
		var into := ""
		for k in _car.get_slide_collision_count():
			var b := _car.get_slide_collision(k).get_collider()
			if b is Node3D and not (b is Car):
				var owner_name: String = (b as Node3D).name
				if b.get_parent() != null:
					owner_name = "%s/%s" % [b.get_parent().name, owner_name]
				if not into.contains(owner_name):
					into += (" " if into != "" else "") + owner_name
		_rows.append({"frac": c["frac"], "side": c["side"], "skip": "",
			"back": _back_on, "t": _time, "min_lat": _min_lat, "into": into})
		_next_drive_case()


func _report_drive() -> void:
	print("\n=== REINTRARE PE SOSEA DUPA IESIRE PE NISIP (%s) ==="
		% GameState.TRACK_NAMES[_track_index])
	print("start la %.1f m de marginea asfaltului, %.0f m/s, unghi %.0f°, %.0fs"
		% [DRIVE_OFFSET, DRIVE_ENTRY_SPEED, DRIVE_ANGLE_DEG, DRIVE_SECONDS])
	print("%8s %5s %10s %8s %10s" % ["fractie", "parte", "reintrat", "timp",
		"apropiere"])
	print("-".repeat(46))
	var failed := 0
	var skipped := 0
	for row in _rows:
		var side_txt: String = "st" if float(row["side"]) < 0.0 else "dr"
		if row["skip"] != "":
			skipped += 1
			print("%8.2f %5s %10s" % [row["frac"], side_txt,
				"(%s)" % row["skip"]])
			continue
		if not row["back"]:
			failed += 1
		print("%8.2f %5s %10s %7.1fs %8.2f m  %s" % [
			row["frac"], side_txt,
			"da" if row["back"] else "NU", row["t"],
			float(row["min_lat"]) - _track.half_width, row["into"]])
	print("\n%d cazuri (%d sarite: loc inchis prin design), %d fara reintrare"
		% [_rows.size(), skipped, failed])
	print("VERDICT: %s" % ("PROBLEMA" if failed > 0 else "OK"))
	_quit(1 if failed > 0 else 0)



func _quit(code: int) -> void:
	_done = true
	get_tree().quit(code)
