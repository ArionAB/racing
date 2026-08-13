extends Node
## Testbed-ul nucleului de fizica intreaga (#255): RigidCar pe suspensie de
## raycast, masurat pe un teren construit din cod — platou, panta de 20°,
## banda de denivelari. Nicio pista reala: aici se valideaza CORPUL, nu jocul.
##
## Cele 5 teste (criteriile din issue):
##   1. asezare    — lasata sa cada, se aseaza repede, 4/4 roti, arcul lucreaza
##   2. dreapta    — acceleratie plina atinge vmax si tine linia
##   3. panta      — pe 20°, 4/4 roti si tangajul caroseriei = unghiul pantei
##   4. viraj      — cerc complet, ruliu vizibil dar fara rasturnare
##   5. denivelari — caroseria se leagana masurabil, fara oscilatie divergenta
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSuspension.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false


## "Creier" minimal cu interfata CarController — comenzi setate de test.
class ScriptDriver:
	extends Node
	var steer: float = 0.0
	var throttle: float = 0.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_build_world()
	await get_tree().physics_frame

	print("")
	print("=== Testbed suspensie RigidCar ===")
	await _test_settle()
	await _test_straight()
	await _test_slope()
	await _test_circle()
	await _test_bumps()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


## Platoul, panta si banda de denivelari — StaticBody3D-uri simple.
func _build_world() -> void:
	_add_static_box(Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	# Panta de 20°, urcare spre -Z, centrata pe x=120.
	var ramp := _add_static_box(Vector3(40, 1, 80), Vector3(120, 0, -20))
	ramp.rotation.x = deg_to_rad(20.0)
	# Denivelari: 9 dale de 8 cm inaltime la fiecare 3 m, pe culoarul x=-120.
	for i in 9:
		_add_static_box(Vector3(30, 0.16, 0.5),
			Vector3(-120, 0.08, -20.0 - 3.0 * float(i)))


func _add_static_box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = pos
	return body


func _spawn(pos: Vector3) -> RigidCar:
	var car := RigidCar.new()
	add_child(car)
	car.global_position = pos
	car.set_controller(ScriptDriver.new())
	return car


func _driver(car: RigidCar) -> ScriptDriver:
	return car.controller as ScriptDriver


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


# ------------------------------------------------------------------ testele

func _test_settle() -> void:
	print("")
	print("-- 1. asezare (cadere de la 0.8 m) --")
	var car := _spawn(Vector3(0, 0.8 + 0.65, 100))
	var heights: Array[float] = []
	for f in int(2.5 / STEP):
		await get_tree().physics_frame
		if f >= int(2.0 / STEP):
			heights.append(car.global_position.y)
	var speed := car.linear_velocity.length()
	var h_min := 1e9
	var h_max := -1e9
	for h in heights:
		h_min = minf(h_min, h)
		h_max = maxf(h_max, h)
	var comp_frac_min := 1e9
	var comp_frac_max := -1e9
	for compression in car.wheel_compression:
		var frac: float = compression / car.suspension_rest
		comp_frac_min = minf(comp_frac_min, frac)
		comp_frac_max = maxf(comp_frac_max, frac)
	print("  viteza reziduala %.3f m/s, roti pe sol %d/4, inaltime ±%.1f mm,"
		% [speed, car.wheels_on_ground, (h_max - h_min) * 500.0])
	print("  compresie de repaus %.0f%%..%.0f%% din cursa"
		% [comp_frac_min * 100.0, comp_frac_max * 100.0])
	_check(speed < 0.05, "se aseaza (viteza reziduala < 0.05 m/s)")
	_check(car.wheels_on_ground == 4, "4/4 roti pe sol")
	_check(h_max - h_min < 0.01, "fara oscilatie remanenta (< 1 cm)")
	_check(comp_frac_min > 0.15 and comp_frac_max < 0.6,
		"arcul lucreaza (compresie 15-60%)")
	car.queue_free()
	await get_tree().physics_frame


func _test_straight() -> void:
	print("")
	print("-- 2. linia dreapta (acceleratie plina 8 s) --")
	var car := _spawn(Vector3(0, 0.7, 150))
	for _f in int(1.0 / STEP): # intai se aseaza
		await get_tree().physics_frame
	_driver(car).throttle = 1.0
	var max_speed_seen := 0.0
	var max_drift := 0.0
	for _f in int(8.0 / STEP):
		await get_tree().physics_frame
		max_speed_seen = maxf(max_speed_seen, car.horizontal_speed())
		max_drift = maxf(max_drift, absf(car.global_position.x))
	print("  viteza de varf %.1f m/s (vmax %.1f), deriva laterala %.2f m"
		% [max_speed_seen, car.max_speed, max_drift])
	_check(max_speed_seen >= car.max_speed * 0.95, "atinge >= 95% din vmax")
	_check(max_speed_seen <= car.max_speed * 1.1, "nu trece de vmax + 10%")
	_check(max_drift < 1.0, "tine linia (deriva < 1 m)")
	car.queue_free()
	await get_tree().physics_frame


func _test_slope() -> void:
	print("")
	print("-- 3. panta de 20° (asezare pe urcare) --")
	# Pe partea URCATA a rampei (rampa urca spre -Z; la z=-40 suprafata e la
	# ~7.8 m). Prima versiune spawna la z=-15 — partea coborata, SUB platou —
	# si masina cadea 9 m pe plat, ricosand din colizerul caroseriei.
	var car := _spawn(Vector3(120, 8.4, -40))
	# Aliniata cu panta de la inceput (rotatia rampei), ca toate cele patru
	# raycasturi sa prinda suprafata deodata, nu intai botul si apoi coada.
	car.rotation.x = deg_to_rad(20.0)
	var pitch_deg := 0.0
	var grounded := 0
	for f in int(1.5 / STEP):
		await get_tree().physics_frame
		if f == int(1.2 / STEP):
			grounded = car.wheels_on_ground
			# Tangajul caroseriei fata de orizontala, pe axa de mers.
			var fwd := -car.global_transform.basis.z
			pitch_deg = rad_to_deg(asin(clampf(fwd.y, -1.0, 1.0)))
	print("  roti pe sol %d/4, tangaj %.1f° (panta 20°)" % [grounded, pitch_deg])
	_check(grounded == 4, "4/4 roti in contact pe panta")
	_check(absf(pitch_deg - 20.0) <= 3.0, "caroseria urmeaza panta (±3°)")
	car.queue_free()
	await get_tree().physics_frame


func _test_circle() -> void:
	print("")
	print("-- 4. viraj sustinut (volan plin la viteza) --")
	var car := _spawn(Vector3(-60, 0.7, 100))
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	_driver(car).throttle = 1.0
	for _f in int(3.0 / STEP): # prinde viteza
		await get_tree().physics_frame
	_driver(car).steer = 1.0
	var yaw_total := 0.0
	var prev_yaw := car.rotation.y
	var max_roll := 0.0
	var flipped := false
	for _f in int(10.0 / STEP):
		await get_tree().physics_frame
		var yaw := car.rotation.y
		yaw_total += absf(wrapf(yaw - prev_yaw, -PI, PI))
		prev_yaw = yaw
		# Ruliul: cat s-a culcat axa "sus" a masinii fata de verticala.
		var up := car.global_transform.basis.y
		var tilt := rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
		max_roll = maxf(max_roll, tilt)
		if up.dot(Vector3.UP) < 0.5:
			flipped = true
	print("  rotatie totala %.0f° (cerc complet = 360°), inclinare maxima %.1f°"
		% [rad_to_deg(yaw_total), max_roll])
	_check(yaw_total >= TAU, "inchide cercul in 10 s")
	_check(max_roll > 0.5, "ruliul exista (se vede ca se lasa in viraj)")
	_check(max_roll < 25.0 and not flipped, "fara rasturnare (< 25°)")
	car.queue_free()
	await get_tree().physics_frame


func _test_bumps() -> void:
	print("")
	print("-- 5. denivelari (dale de 8 cm la viteza) --")
	var car := _spawn(Vector3(-120, 0.7, 10))
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	_driver(car).throttle = 1.0
	var comp_min := 1e9
	var comp_max := -1e9
	var max_tilt := 0.0
	var airtime := 0.0
	var cur_air := 0.0
	var max_airtime := 0.0
	var flipped := false
	for _f in int(6.0 / STEP):
		await get_tree().physics_frame
		if car.global_position.z > -18.0 or car.global_position.z < -50.0:
			continue # masuram doar pe banda de dale
		for compression in car.wheel_compression:
			comp_min = minf(comp_min, float(compression))
			comp_max = maxf(comp_max, float(compression))
		var up := car.global_transform.basis.y
		var tilt := rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
		max_tilt = maxf(max_tilt, tilt)
		if up.dot(Vector3.UP) < 0.5:
			flipped = true
		if car.wheels_on_ground == 0:
			cur_air += STEP
			airtime += STEP
			max_airtime = maxf(max_airtime, cur_air)
		else:
			cur_air = 0.0
	var articulation := (comp_max - comp_min) / car.suspension_rest
	print("  articulatie %.0f%% din cursa, inclinare maxima %.1f°,"
		% [articulation * 100.0, max_tilt])
	print("  aer total %.2f s (cea mai lunga desprindere %.2f s)"
		% [airtime, max_airtime])
	_check(articulation > 0.05, "suspensia articuleaza pe dale (> 5% din cursa)")
	_check(max_tilt < 20.0 and not flipped, "caroseria ramane controlata (< 20°)")
	_check(max_airtime < 0.3, "fara zbor complet peste dale (< 0.3 s)")
	car.queue_free()
	await get_tree().physics_frame
