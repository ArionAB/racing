extends Node
## Sonda culoarului de ceata (Chongqing, brief §2 POI E si §3): ceata se
## ingroasa treptat pe 60-80 m, se iese din ea BRUSC, marcajele raman
## vizibile, si nu costa nicio secunda.
##
## Sonda citeste `Environment`-ul pistei — ce vede CAMERA — nu o variabila
## interna a hazardului. Memoria „efectele nu se verifica numarand": o sonda
## care se uita la propriul contor al hazardului trece si atunci cand pe ecran
## nu s-a schimbat nimic.
##
##  (0)   geometria: culoarul are lungimea ceruta (60-80 m din brief), iar
##        reperele sunt mai dese decat bate vederea in ceata plina — altfel
##        exista locuri din care nu se vede niciun reper.
##  (i)   profilul: ceata creste MONOTON pe intrare si tine platoul; intrarea
##        se intinde pe zeci de metri.
##  (ii)  IESIREA E BRUSCA: drumul pe care ceata cade de la plin la limpede e
##        de cateva ori mai scurt decat cel pe care a crescut.
##  (iii) masina REALA trece prin culoar si Environment-ul chiar se misca:
##        `fog_depth_end` scade pana aproape de valoarea din culoar si revine.
##  (iv)  contract de cost ZERO: fata de un tur de control fara hazard, timpul
##        prin culoar nu creste, masina nu e strivita, nu e albita, nu e
##        incetinita si isi duce indexul mai departe.
##  (v)   pista se pune la loc: dupa iesire, toti parametrii de ceata sunt
##        EXACT cei dinainte. Un culoar care lasa pista albita ar strica
##        atmosfera pentru tot restul cursei.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFogCorridor.tscn
## Iese cu cod 1 la orice verdict picat.

const FogScript := preload("res://scenes/hazards/fog_corridor_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 10.0
const START_Z: float = 120.0
const FINISH_Z: float = -60.0
const ENTRY_SPEED: float = 26.0

var _track: TrackFromPath
var _hazard: FogScript
var _fails: int = 0


func _ready() -> void:
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeFogCorridor"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame

	print("=== CULOARUL DE CEATA: profil, iesire brusca, cost zero ===")
	# Turul de control se face INAINTE ca hazardul sa existe: asa „fara ceata"
	# chiar inseamna fara ea, nu „cu ea, dar stinsa".
	var t_clean := await _drive("CONTROL", [])
	print("    tur de control (fara culoar): %.2f s" % t_clean)

	_hazard = FogScript.new()
	_hazard.name = "FogCorridor"
	_hazard.position = Vector3(0.0, 0.0, 20.0)
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("  culoar %.0f m (intrare %.0f m, iesire %.0f m), ceata %.0f->%.0f m, repere la %.1f m"
		% [_hazard.length, _hazard.ramp_in, _hazard.ramp_out,
		_hazard.fog_begin_inside, _hazard.fog_end_inside, _hazard.marker_spacing])
	var base: Dictionary = _hazard.base_fog()
	print("  ceata pistei: mod %d, %.1f->%.1f m, densitate %.4f, culoare %s"
		% [base["mode"], base["begin"], base["end"], base["density"],
		str(base["color"])])

	await _run(t_clean, base)
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _spawn(at: Vector3, speed: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	# Ceata e a CAMEREI: culoarul se uita doar dupa masina jucatorului.
	car.is_player = true
	return car


## Cat de departe se vede ACUM, citit din Environment-ul pistei.
##
## Se citeste parametrul pe care pista il FOLOSESTE: pe ceata de adancime,
## `fog_depth_end` (metri — mai mic = mai orb); pe cea exponentiala,
## `fog_density` (mai mare = mai orb). Prima versiune a sondei citea mereu
## `fog_depth_end` si a picat pe tema de test, care e exponentiala: raporta
## „vederea nu s-a scurtat" pentru un camp de 100 m care nici nu era folosit.
func _fog_value() -> float:
	var env: Environment = _hazard.environment()
	if env == null:
		return 0.0
	return env.fog_depth_end if env.fog_mode == Environment.FOG_MODE_DEPTH 		else env.fog_density


## Unde trebuie sa ajunga valoarea de mai sus cand culoarul e plin.
func _fog_target() -> float:
	var env: Environment = _hazard.environment()
	if env != null and env.fog_mode == Environment.FOG_MODE_DEPTH:
		return _hazard.fog_end_inside
	return _hazard.fog_density_inside


## Conduce de la START_Z la FINISH_Z. Daca hazardul exista, aduna in `samples`
## triplete [adancime in culoar, cat de departe se vede, cat de plin e culoarul].
func _drive(label: String, samples: Array) -> float:
	var car := _spawn(Vector3(0.0, 0.7, START_Z), ENTRY_SPEED)
	var driver := WaypointDriver.new()
	driver.waypoints = [Vector3(0.0, 0.0, FINISH_Z - 40.0)]
	driver.target_speed = ENTRY_SPEED
	car.set_controller(driver)
	var t := 0.0
	var crush := 0.0
	var blind := 0.0
	var min_speed := INF
	while t < 24.0 and car.global_position.z > FINISH_Z:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		crush = maxf(crush, car.crush_time)
		blind = maxf(blind, car.blind_time)
		min_speed = minf(min_speed, car.horizontal_speed())
		if _hazard != null:
			var local := _hazard.to_local(car.global_position)
			var depth := _hazard.length * 0.5 - local.z
			samples.append([depth, _fog_value(), _hazard.amount()])
	var arrived := car.global_position.z <= FINISH_Z
	print("--- %s: %s in %.2f s; viteza min %.2f, strivire %.2f, albire %.2f, index -> %d"
		% [label, "ajunsa" if arrived else "NEAJUNSA", t, min_speed, crush,
		blind, car.road_index])
	if label != "CONTROL":
		_verdict(crush <= 0.01, "%s: nu e strivita (%.2f)" % [label, crush])
		_verdict(blind <= 0.01, "%s: nu e albita ca la fumarola (%.2f)" % [label, blind])
		_verdict(car.race_active, "%s: ramane in cursa" % label)
	car.queue_free()
	await get_tree().physics_frame
	return t if arrived else INF


# ------------------------------------------------------------------ profilul

func _check_shape() -> void:
	print("--- (0)+(i)+(ii) geometria si profilul culoarului")
	_verdict(_hazard.length >= 60.0 and _hazard.length <= 80.0,
		"lungimea e in fereastra din brief 60-80 m (%.0f)" % _hazard.length)
	_verdict(_hazard.marker_spacing < _hazard.fog_end_inside,
		"reperele (la %.1f m) sunt mai dese decat bate vederea in ceata plina (%.0f m)"
		% [_hazard.marker_spacing, _hazard.fog_end_inside])
	_verdict(_hazard.markers().size() >= 4,
		"culoarul are repere pe margini (%d)" % _hazard.markers().size())

	# Profilul, esantionat din metru in metru.
	var rise_lo := -1.0
	var rise_hi := -1.0
	var fall_hi := -1.0
	var fall_lo := -1.0
	var prev := 0.0
	var monotone_in := true
	var d := 0.0
	while d <= _hazard.length:
		var a: float = _hazard.ramp_at(d)
		if a > 0.05 and rise_lo < 0.0:
			rise_lo = d
		if a > 0.95 and rise_hi < 0.0:
			rise_hi = d
		if rise_hi > 0.0 and a < 0.95 and fall_hi < 0.0:
			fall_hi = d
		if fall_hi > 0.0 and a < 0.05 and fall_lo < 0.0:
			fall_lo = d
		if d < _hazard.ramp_in and a < prev - 0.001:
			monotone_in = false
		prev = a
		d += 1.0
	var rise_len := rise_hi - rise_lo
	var fall_len := fall_lo - fall_hi
	print("    ceata creste de la %.0f la %.0f m (%.0f m), cade de la %.0f la %.0f m (%.0f m)"
		% [rise_lo, rise_hi, rise_len, fall_hi, fall_lo, fall_len])
	_verdict(monotone_in, "ceata se ingroasa monoton pe intrare")
	_verdict(rise_len > 25.0, "intrarea e treptata (%.0f m)" % rise_len)
	_verdict(fall_len > 0.0 and fall_len * 4.0 < rise_len,
		"iesirea e brusca: %.0f m fata de %.0f m la intrare" % [fall_len, rise_len])


func _run(t_clean: float, base: Dictionary) -> void:
	_check_shape()

	print("--- (iii) masina reala prin culoar: ceata camerei chiar se misca")
	var t_fog := await _drive_through(base, "exponentiala")

	print("--- (iv) contract de cost ZERO")
	print("    control %.2f s, prin ceata %.2f s (diferenta %+.2f)"
		% [t_clean, t_fog, t_fog - t_clean])
	_verdict(t_fog < INF, "a terminat bucata prin culoar")
	_verdict(absf(t_fog - t_clean) < 0.25,
		"culoarul nu costa timp (%+.2f s fata de control)" % (t_fog - t_clean))

	print("--- (v) pista se pune la loc dupa iesire")
	for _f in 30:
		await get_tree().physics_frame
	var env: Environment = _hazard.environment()
	print("    dupa iesire: mod %d, %.1f->%.1f m, densitate %.4f, culoare %s"
		% [env.fog_mode, env.fog_depth_begin, env.fog_depth_end, env.fog_density,
		str(env.fog_light_color)])
	_verdict(env.fog_mode == base["mode"], "modul de ceata e cel al pistei")
	_verdict(absf(env.fog_depth_begin - base["begin"]) < 0.01
			and absf(env.fog_depth_end - base["end"]) < 0.01,
		"cotele cetii sunt cele ale pistei (%.1f->%.1f)"
		% [env.fog_depth_begin, env.fog_depth_end])
	_verdict(env.fog_light_color.is_equal_approx(base["color"]),
		"culoarea cetii e cea a pistei")

	# --------------------------------------------- si pe ceata de ADANCIME
	#
	# Tema de test e exponentiala, dar Chongqing (ca mai toate temele cu
	# distanta in cadru) va folosi ceata pe adancime — si aia e cealalta ramura
	# din `_apply`. O sonda care nu trece prin ea ar valida jumatate de hazard.
	print("--- (vi) acelasi culoar pe o pista cu ceata pe ADANCIME")
	_hazard.queue_free()
	await get_tree().physics_frame
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 90.0
	env.fog_depth_end = 250.0
	_hazard = FogScript.new()
	_hazard.name = "FogCorridorDepth"
	_hazard.position = Vector3(0.0, 0.0, 20.0)
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var base2: Dictionary = _hazard.base_fog()
	print("    ceata pistei acum: mod %d, %.1f->%.1f m" % [base2["mode"],
		base2["begin"], base2["end"]])
	_verdict(int(base2["mode"]) == Environment.FOG_MODE_DEPTH,
		"culoarul a luat ceata de adancime ca baza")
	await _drive_through(base2, "adancime")
	for _f in 30:
		await get_tree().physics_frame
	print("    dupa iesire: %.1f->%.1f m" % [env.fog_depth_begin, env.fog_depth_end])
	_verdict(absf(env.fog_depth_begin - 90.0) < 0.01
			and absf(env.fog_depth_end - 250.0) < 0.01,
		"si pe adancime pista se pune la loc (%.1f->%.1f)"
		% [env.fog_depth_begin, env.fog_depth_end])


## O trecere prin culoar cu masina reala, cu verdictele pe parametrul de ceata
## pe care il foloseste pista.
func _drive_through(base: Dictionary, label: String) -> float:
	var samples: Array = []
	var t_fog := await _drive("CEATA-" + label, samples)
	var deepest := 0.0
	var max_amount := 0.0
	var target := _fog_target()
	var toward_zero: bool = int(base["mode"]) == Environment.FOG_MODE_DEPTH
	deepest = INF if toward_zero else 0.0
	for s in samples:
		if s[0] > 0.0 and s[0] < _hazard.length:
			deepest = minf(deepest, s[1]) if toward_zero else maxf(deepest, s[1])
		max_amount = maxf(max_amount, s[2])
	var was: float = base["end"] if toward_zero else base["density"]
	print("    in culoar (%s): valoarea a mers de la %.4f la %.4f (culoar: %.4f); umplere max %.2f"
		% [label, was, deepest, target, max_amount])
	_verdict(max_amount > 0.9, "%s: culoarul chiar s-a umplut (%.2f)"
		% [label, max_amount])
	var moved := deepest < was * 0.6 if toward_zero else deepest > was * 2.0
	_verdict(moved, "%s: vederea chiar s-a scurtat (%.4f fata de %.4f)"
		% [label, deepest, was])
	_verdict(absf(deepest - target) < maxf(absf(target) * 0.1, 0.001),
		"%s: a ajuns la valoarea ceruta in culoar (%.4f, cerut %.4f)"
		% [label, deepest, target])
	return t_fog
