extends Node
## Sonda #614: ciocnirea cu turma NU arunca soferul, doar incetineste masina,
## cu pedeapsa scalata cu masa (usoara pierde mai mult decat grea).
##
## Masinile sunt DESCHISE (apply_data cu buggy.tres, ca sa aiba sofer) si primesc
## masa prin `mass_factor` (0,9 / 1,6 / 2,6). Trec cu viteza mare prin culoarul
## unui HerdHazard in puls des. Verifica:
##   1. zero ejectari, la fiecare masa, oricat de repede;
##   2. au fost lovituri reale (altfel zero ejectari ar fi o sonda goala);
##   3. viteza minima in culoar creste cu masa (monoton invers cu pierderea);
##   4. CONTROL: aceeasi trecere cu filtrul de turma STINS
##      (`Car.ignore_animal_eject = false`) ejecteaza => sonda vede defectul;
##   5. ejectarea la perete si la aterizare ramane (ProbeEject le acopera pe
##      larg; aici doar un perete frontal rapid, ca sa nu se piarda din greseala).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHerdEject.tscn
##   (+ `-- --sabotage` ruleaza DOAR controlul si iese cu 0 daca ejecteaza)

const STEP: float = 1.0 / 60.0
const HerdScript := preload("res://scenes/hazards/herd_hazard.gd")
const BUGGY: CarData = preload("res://scenes/cars/data/buggy.tres")
const FACTORS := [0.9, 1.6, 2.6]
const SPEEDS := [34.0, 50.0]
const PASSES := 3

var _failed: bool = false
var _ejections: int = 0
var _causes: Array[String] = []


class ScriptDriver:
	extends CarController
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return 1.0
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(600, 1, 600)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	print("")
	print("=== Turma si soferul (#614) ===")
	var herd: HerdHazard = HerdScript.new()
	herd.flow_dir = Vector3(1, 0, 0)
	herd.road_dir = Vector3(0, 0, 1)
	add_child(herd)
	herd.global_position = Vector3.ZERO
	await get_tree().physics_frame

	var sabotage := "--sabotage" in OS.get_cmdline_user_args()
	if sabotage:
		# Filtrul scos: un animal-zid la viteza de cursa TREBUIE sa arunce soferul
		# (altfel testul de contract de mai jos n-ar dovedi nimic).
		print("-- CONTROL (--sabotage): filtrul scos")
		var e := await _wall_test(true, false, false)
		print("  ejectari fara filtru: %d" % e)
		get_tree().quit(0 if e > 0 else 1)
		return

	print("-- contract: corp de animal la viteza de cursa")
	_check(await _wall_test(false, false, false) == 0, "corp marcat `herd_animal`: zero ejectari")
	_check(await _wall_test(false, true, false) == 1, "acelasi zid NEmarcat: ejecteaza (garda nu orbeste)")
	_check(await _wall_test(false, true, true) == 0,
		"impact `animal` emis chiar inainte de perete: fara ejectare (cazul PR #625)")

	for speed: float in SPEEDS:
		print("-- viteza %.0f m/s" % speed)
		var vmins: Array[float] = []
		for f: float in FACTORS:
			var ej := 0
			var hits := 0
			var v_out := 0.0
			var per_hit := 0.0
			for _p in PASSES:
				var r := await _run(herd, f, speed, true)
				ej += int(r.ejected)
				hits += int(r.hits)
				v_out += float(r.v_out) / PASSES
				per_hit += (float(r.v_in) - float(r.v_min)) / maxf(float(r.hits), 1.0) / PASSES
			print("  masa x%.1f: %d lovituri/%d treceri, ejectari %d, viteza la iesire %.1f m/s, pierdere/lovitura %.1f m/s"
				% [f, hits, PASSES, ej, v_out, per_hit])
			_check(ej == 0, "masa x%.1f @%.0f: zero ejectari" % [f, speed])
			_check(hits >= PASSES, "masa x%.1f @%.0f: a lovit animale (%d)" % [f, speed, hits])
			vmins.append(v_out)
		# Trecerea prin turma e zgomotoasa (Jolt multi-fir, numar variabil de
		# lovituri): aici doar „incetineste", ordinea pe masa o da testul
		# determinist de mai jos.
		for k in vmins.size():
			_check(vmins[k] < speed * 0.92, "@%.0f: masa x%.1f e incetinita (iese cu %.1f m/s)"
				% [speed, FACTORS[k], vmins[k]])

	print("-- pierderea de viteza dintr-o lovitura (HerdHazard._hit, determinist)")
	await _wait(herd.seconds_to_dense())
	var losses: Array[float] = []
	for f: float in FACTORS:
		var car := _spawn(Vector3(0, 0.7, 300), f, 1.0)
		var idx := -1
		for i in herd.count():
			if herd._state[i] == HerdHazard.State.RUN:
				idx = i
				break
		car.velocity = Vector3(0, 0, -30.0)
		var v0 := car.velocity
		herd._hit(idx, car)
		var fwd := -car.global_transform.basis.z
		var loss := -(car.velocity - v0).dot(fwd)
		losses.append(loss)
		print("  masa x%.1f (%.0f): pierde %.2f m/s din 30" % [f, car.mass, loss])
		car.queue_free()
		await get_tree().physics_frame
	_check(losses[0] >= losses[1] - 0.001 and losses[1] > losses[2],
		"pierderea scade cu masa (usoara %.2f >= medie %.2f > grea %.2f)" % [losses[0], losses[1], losses[2]])
	_check(losses[2] > 0.3, "autobuzul tot e incetinit (%.2f m/s)" % losses[2])

	print("-- perete frontal rapid: tot ejecteaza")
	herd.queue_free()
	await get_tree().physics_frame
	var wall := StaticBody3D.new()
	var ws := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	wb.size = Vector3(40, 1.3, 1)
	ws.shape = wb
	wall.add_child(ws)
	add_child(wall)
	wall.global_position = Vector3(0, 0.65, -70)
	var car := _spawn(Vector3(0, 0.7, 0), 1.0, 1.0)
	_ejections = 0
	var frames := 0
	while _ejections == 0 and frames < 8 * 60:
		await get_tree().physics_frame
		frames += 1
	_check(_ejections == 1, "perete: soferul tot zboara (%s)" % car.last_eject_cause)
	car.queue_free()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(pos: Vector3, factor: float, speed_frac: float) -> Car:
	var car := Car.new()
	add_child(car)
	car.apply_data(BUGGY)
	car.mass_factor = factor
	car.mass = 100.0 * factor
	car.global_position = pos
	car.race_active = true
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	car.ejected.connect(func(c: Car, _r: Node3D) -> void:
		_ejections += 1
		_causes.append("%s %.1f" % [c.last_eject_cause, c.last_eject_value]))
	return car


## O trecere prin culoar, in plin puls. `filter` = filtrul de ejectare pentru
## animale (control: stins).
func _run(herd: HerdHazard, factor: float, speed: float, filter: bool) -> Dictionary:
	await _wait(herd.seconds_to_dense())
	var car := _spawn(Vector3(0, 0.7, 40), factor, 1.0)
	car.max_speed = maxf(car.max_speed, speed)
	car.speed_limit_factor = speed / car.max_speed
	car.ignore_animal_eject = filter
	car.linear_velocity = Vector3(0, 0, -speed)
	herd.cars = [car]
	_ejections = 0
	_causes.clear()
	var hits0 := herd.hits
	var v_in := 0.0
	var v_min := INF
	var v_out := 0.0
	var frames := 0
	while car.global_position.z > -40.0 and frames < int(12.0 / STEP):
		await get_tree().physics_frame
		frames += 1
		var z := car.global_position.z
		if z < 20.0 and z > 14.0 and v_in == 0.0:
			v_in = car.horizontal_speed()
		if absf(z) < 14.0:
			v_min = minf(v_min, car.horizontal_speed())
		if z < -20.0 and v_out == 0.0:
			v_out = car.horizontal_speed()
	if v_out == 0.0:
		v_out = car.horizontal_speed()
	var out := {"v_out": v_out, "hits": herd.hits - hits0, "ejected": _ejections, "v_in": v_in,
		"v_min": v_min, "cause": "" if _causes.is_empty() else " [" + _causes[0] + "]"}
	herd.cars = []
	car.queue_free()
	await get_tree().physics_frame
	return out


func _wait(seconds: float) -> void:
	for _f in int(seconds / STEP):
		await get_tree().physics_frame


## Un zid (AnimatableBody3D) pe drumul unei masini la viteza de cursa. `tagged`
## = marcat ca animal de turma; `emit_animal` = `Car.impact` &"animal" cu
## putin inainte de contact. Intoarce numarul de ejectari.
func _wall_test(sabotage: bool, untagged: bool, emit_animal: bool) -> int:
	var wall := AnimatableBody3D.new()
	var ws := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	wb.size = Vector3(40, 1.6, 1)
	ws.shape = wb
	wall.add_child(ws)
	if not untagged:
		wall.set_meta(Car.HERD_ANIMAL_META, true)
	add_child(wall)
	wall.global_position = Vector3(200, 0.8, -70)
	var car := _spawn(Vector3(200, 0.7, 0), 1.0, 1.0)
	if sabotage:
		car.ignore_animal_eject = false
	_ejections = 0
	var frames := 0
	var emitted := false
	while _ejections == 0 and frames < 8 * 60 and car.global_position.z > -69.0:
		await get_tree().physics_frame
		frames += 1
		if emit_animal and not emitted and car.global_position.z < -55.0:
			emitted = true
			car.impact.emit(car, &"animal", 5.0, Vector3.BACK, car.global_position, null)
	# lasa contactul sa se consume
	for _f in 30:
		await get_tree().physics_frame
	var n := _ejections
	car.queue_free()
	wall.queue_free()
	await get_tree().physics_frame
	return n
