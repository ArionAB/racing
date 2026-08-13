extends Node
## Driftul handbrake si turbo-ul Ignition pe fizica intreaga (#256).
##
## Cele 4 criterii din issue:
##   1. unghi de drift SUSTINUT: 10-30° tinut cel putin 2 s (sub 5° nu se
##      simte, peste 45° e pierdut);
##   2. iesirea din drift: sub 5° in < 1 s, cel mult o trecere prin zero
##      (revii asezat, nu ca un pendul);
##   3. turbo: bara se umple in turbo_fill_time din mers, de
##      turbo_drift_multiplier ori mai repede in drift (MASURAT, nu citit din
##      export), iar arderea ridica varful cu turbo_speed_bonus ± 10%;
##   4. suprafata lenta: cu speed_limit_factor = 0.45, viteza de echilibru e
##      45% din vmax ± 5% — contractul offroad pe care il va folosi #258.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDriftRigid.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false
## Setat de lambda conectata la boost_started. MEMBRU, nu variabila locala:
## lambdele GDScript captureaza localele prin VALOARE, deci o atribuire din
## lambda intr-o locala nu se vede in functie — prima versiune a sondei a
## raportat "semnal neemis" desi viteza urcase la 45 m/s, adica boost-ul
## pornise cu tot cu semnal.
var _boost_seen: bool = false


class ScriptDriver:
	extends Node
	var steer: float = 0.0
	var throttle: float = 0.0
	var drift: bool = false
	var turbo: bool = false
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return drift
	func is_turbo_pressed() -> bool:
		return turbo


func _ready() -> void:
	_add_static_box(Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	await get_tree().physics_frame

	print("")
	print("=== Drift handbrake + turbo Ignition pe RigidCar ===")
	await _test_drift_and_release()
	await _test_turbo()
	await _test_slow_surface()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _add_static_box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = pos


func _spawn() -> RigidCar:
	var car := RigidCar.new()
	add_child(car)
	car.global_position = Vector3(0, 0.7, 0)
	car.set_controller(ScriptDriver.new())
	return car


func _driver(car: RigidCar) -> ScriptDriver:
	return car.controller as ScriptDriver


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


## Unghiul de derapaj: intre directia caroseriei si directia de mers, semnat
## (pozitiv = spatele fuge spre dreapta). Sub 3 m/s nu inseamna nimic.
func _slip_angle_deg(car: RigidCar) -> float:
	var hvel := Vector3(car.linear_velocity.x, 0.0, car.linear_velocity.z)
	if hvel.length() < 3.0:
		return 0.0
	var fwd := -car.global_transform.basis.z
	var fwd_h := Vector3(fwd.x, 0.0, fwd.z).normalized()
	var right_h := fwd_h.cross(Vector3.UP)
	return rad_to_deg(atan2(hvel.dot(right_h), hvel.dot(fwd_h)))


# ------------------------------------------------------------------ testele

func _test_drift_and_release() -> void:
	print("")
	print("-- 1+2. drift sustinut si iesirea din el --")
	var car := _spawn()
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	_driver(car).throttle = 1.0
	for _f in int(3.0 / STEP): # prinde viteza
		await get_tree().physics_frame

	# Intra in drift: volan plin + handbrake, 4 secunde. Bara de turbo se
	# GOLESTE la intrare, altfel se umple pana la plafon in timpul masurarii
	# si rata pe drift iese taiata de cap (prima rulare: 1.5x in loc de 2.5x,
	# fiindca bara era deja la 0.3 din acceleriarea de dinainte si a atins 1.0).
	_driver(car).steer = 1.0
	_driver(car).drift = true
	car.turbo_charge = 0.0
	var in_window := 0.0
	var best_window := 0.0
	var angle_min := 1e9
	var angle_max := -1e9
	var drift_time := 0.0
	var drift_gain := 0.0
	var prev_charge: float = car.turbo_charge
	for _f in int(4.0 / STEP):
		await get_tree().physics_frame
		var a := absf(_slip_angle_deg(car))
		if car.is_drifting:
			angle_min = minf(angle_min, a)
			angle_max = maxf(angle_max, a)
			# Rata se masoara doar cat chiar drifteaza si doar sub plafon.
			if car.turbo_charge < 1.0:
				drift_time += STEP
				drift_gain += car.turbo_charge - prev_charge
		prev_charge = car.turbo_charge
		if a >= 10.0 and a <= 30.0:
			in_window += STEP
			best_window = maxf(best_window, in_window)
		else:
			in_window = 0.0
	var drift_fill_rate := drift_gain / maxf(drift_time, 0.001)
	print("  unghi in drift %.0f..%.0f°, fereastra 10-30° tinuta %.2f s"
		% [angle_min, angle_max, best_window])
	_check(best_window >= 2.0, "unghi de drift sustinut 10-30° timp de >= 2 s")

	# Iesirea: volan drept, handbrake liber.
	_driver(car).steer = 0.0
	_driver(car).drift = false
	var recovered_at := -1.0
	var crossings := 0
	var prev_sign := signf(_slip_angle_deg(car))
	var t := 0.0
	for _f in int(2.0 / STEP):
		await get_tree().physics_frame
		t += STEP
		var a := _slip_angle_deg(car)
		var s := signf(a)
		if s != 0.0 and prev_sign != 0.0 and s != prev_sign:
			crossings += 1
		if s != 0.0:
			prev_sign = s
		if recovered_at < 0.0 and absf(a) < 5.0:
			recovered_at = t
		elif recovered_at >= 0.0 and absf(a) >= 5.0:
			recovered_at = -1.0 # a iesit inapoi din banda: nu era asezata
	print("  revenire sub 5° la %.2f s, treceri prin zero: %d"
		% [recovered_at, crossings])
	_check(recovered_at >= 0.0 and recovered_at < 1.0,
		"iese din drift asezat (< 5° in sub 1 s)")
	_check(crossings <= 1, "fara pendulare (cel mult o trecere prin zero)")

	# Bonus masurat aici ca sa nu mai facem inca un drift: rata de umplere.
	set_meta("drift_fill_rate", drift_fill_rate)
	car.queue_free()
	await get_tree().physics_frame


func _test_turbo() -> void:
	print("")
	print("-- 3. turbo Ignition (umplere, raport pe drift, ardere) --")
	var car := _spawn()
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	# Umplerea din mers drept, masurata de la zero.
	_driver(car).throttle = 1.0
	car.turbo_charge = 0.0
	var fill_time := -1.0
	var t := 0.0
	for _f in int(12.0 / STEP):
		await get_tree().physics_frame
		t += STEP
		if fill_time < 0.0 and car.turbo_charge >= 1.0:
			fill_time = t
	var straight_rate := 1.0 / maxf(fill_time, 0.001)
	var drift_rate := float(get_meta("drift_fill_rate", 0.0))
	var ratio := drift_rate / straight_rate
	print("  umplere din mers: %.1f s (tinta %.1f)" % [fill_time, car.turbo_fill_time])
	print("  rata pe drift / rata pe drept: %.2fx (tinta %.1fx)"
		% [ratio, car.turbo_drift_multiplier])
	_check(absf(fill_time - car.turbo_fill_time) <= 0.5,
		"bara se umple in turbo_fill_time (± 0.5 s)")
	_check(ratio >= car.turbo_drift_multiplier * 0.85
		and ratio <= car.turbo_drift_multiplier * 1.15,
		"driftul hraneste bara de ~%.1f ori mai repede" % car.turbo_drift_multiplier)

	# Arderea: de la vmax, tine TURBO si masoara varful.
	_boost_seen = false
	car.boost_started.connect(func(_c: RigidCar) -> void: _boost_seen = true)
	_driver(car).turbo = true
	var top := 0.0
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
		top = maxf(top, car.horizontal_speed())
	var target := car.max_speed + car.turbo_speed_bonus
	print("  varf cu turbo: %.1f m/s (tinta %.1f ± 10%%)" % [top, target])
	_check(_boost_seen, "semnalul boost_started se emite")
	_check(top >= target * 0.9 and top <= target * 1.1,
		"turbo ridica varful cu turbo_speed_bonus (± 10%)")
	car.queue_free()
	await get_tree().physics_frame


func _test_slow_surface() -> void:
	print("")
	print("-- 4. suprafata lenta (speed_limit_factor = 0.45) --")
	var car := _spawn()
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	car.speed_limit_factor = 0.45
	_driver(car).throttle = 1.0
	for _f in int(8.0 / STEP):
		await get_tree().physics_frame
	var speed := car.horizontal_speed()
	var target := car.max_speed * 0.45
	print("  viteza de echilibru %.1f m/s (tinta %.1f ± 5%%)" % [speed, target])
	_check(speed >= target * 0.95 and speed <= target * 1.05,
		"plafonul offroad tine (45% din vmax ± 5%)")
	car.queue_free()
	await get_tree().physics_frame
