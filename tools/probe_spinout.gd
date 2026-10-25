extends Node
## Spin-out assist (docs/feel_checklist.md, `spinout-assist`).
##
## Contractele, pe teren plat, cu gaz tinut:
##   1. masina care merge la 20 m/s si e invartita cu 150 grade fata de
##      directia de mers (botul inapoi) are botul la <= 40 grade de directia
##      INITIALA de mers dupa 1.2 s si inca merge pe ea (> 5 m/s). Fara asistenta
##      fizica o intoarce singura pe directia gresita: ramane cu botul inapoi;
##   2. marsarier din voie (frana, 6 m/s inapoi): asistenta NU porneste, botul
##      nu se roteste (<= 10 grade intr-o secunda);
##   3. drift cu frana de mana la 85% din max_speed: unghiul de derapaj ramane
##      sub 60 grade si asistenta nu porneste NICIODATA;
##   4. un slip de 80 grade (sub prag) nu declanseaza asistenta.
## Sabotaj (trebuie sa PICE): `-- --off` pune spinout_enabled = false.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSpinout.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _off: bool = false


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 1.0
	var drift: bool = false
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return drift
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3000, 1, 3000)
	cs.shape = sh
	ground.add_child(cs)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	print("")
	print("=== Spin-out assist ===")
	if _off:
		print("  (SABOTAJ: spinout_enabled = false)")
	await _test_spin()
	await _test_reverse()
	await _test_drift()
	await _test_sub_threshold()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn() -> Car:
	var car := Car.new()
	car.spinout_enabled = not _off
	add_child(car)
	car.global_position = Vector3(0, 0.7, 0)
	car.set_controller(ScriptDriver.new())
	car.race_active = true
	return car


func _settle(car: Car) -> void:
	(car.controller as ScriptDriver).throttle = 0.0
	for _f in 50:
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


## Unghiul (grade, absolut) dintre botul masinii si viteza ei orizontala.
func _slip_deg(car: Car) -> float:
	var v := Vector3(car.linear_velocity.x, 0.0, car.linear_velocity.z)
	if v.length() < 0.5:
		return 0.0
	var f := -car.global_transform.basis.z
	f.y = 0.0
	return rad_to_deg(absf(f.normalized().angle_to(v.normalized())))


## Pune masina cu botul rotit cu `off_deg` fata de viteza (spre -Z), la `speed`.
func _launch_rotated(car: Car, off_deg: float, speed: float) -> void:
	car.rotation.y = deg_to_rad(off_deg)
	car.linear_velocity = Vector3(0, 0, -speed)
	(car.controller as ScriptDriver).throttle = 1.0


func _test_spin() -> void:
	print("")
	print("-- 1. spin de 150 grade la 20 m/s, gaz tinut --")
	var car := _spawn()
	await _settle(car)
	_launch_rotated(car, 150.0, 20.0)
	var t := 0.0
	var off_line := 999.0
	var along := -99.0
	var t_back := -1.0
	for _f in 120:
		await get_tree().physics_frame
		t += STEP
		var f := -car.global_transform.basis.z
		var ang := rad_to_deg(Vector3(f.x, 0.0, f.z).normalized().angle_to(Vector3(0, 0, -1)))
		if t_back < 0.0 and ang <= 40.0:
			t_back = t
		if absf(t - 1.2) < STEP * 0.5:
			off_line = ang
			along = -car.linear_velocity.z # pe directia initiala de mers
	print("  la 1.2 s botul e la %.0f grade de directia initiala (<= 40 grade dupa %s), viteza pe directia initiala %.1f m/s"
		% [off_line, ("%.2f s" % t_back) if t_back >= 0.0 else "NICIODATA", along])
	_check(off_line <= 40.0, "botul inapoi pe linie (<= 40 grade de directia initiala) dupa 1.2 s")
	_check(along > 5.0, "inca merge pe linie (> 5 m/s pe directia initiala)")
	car.queue_free()
	await get_tree().physics_frame


func _test_reverse() -> void:
	print("")
	print("-- 2. marsarier din voie: frana, 6 m/s inapoi --")
	var car := _spawn()
	await _settle(car)
	car.rotation.y = 0.0
	car.linear_velocity = Vector3(0, 0, 6.0) # inapoi (botul spre -Z)
	(car.controller as ScriptDriver).throttle = -1.0
	var yaw0 := car.rotation.y
	var fired := false
	for _f in 60:
		await get_tree().physics_frame
		if car._spinout_on:
			fired = true
	var dyaw := absf(rad_to_deg(angle_difference(yaw0, car.rotation.y)))
	print("  dupa 1 s: botul s-a rotit %.1f grade, asistenta pornita: %s" % [dyaw, fired])
	_check(not fired and dyaw <= 10.0, "asistenta nu porneste in marsarier din voie")
	car.queue_free()
	await get_tree().physics_frame


func _test_drift() -> void:
	print("")
	print("-- 3. drift cu frana de mana la 85% din max_speed --")
	var car := _spawn()
	await _settle(car)
	var drv := car.controller as ScriptDriver
	drv.throttle = 1.0
	var guard := 0
	while car.horizontal_speed() < car.max_speed * 0.85 and guard < 900:
		await get_tree().physics_frame
		guard += 1
	drv.steer = 1.0
	for _f in 30:
		await get_tree().physics_frame
	drv.drift = true
	var max_slip := 0.0
	var fired := false
	for _f in 150:
		await get_tree().physics_frame
		max_slip = maxf(max_slip, _slip_deg(car))
		if car._spinout_on:
			fired = true
	print("  derapaj maxim %.0f grade, asistenta pornita: %s" % [max_slip, fired])
	_check(max_slip < 60.0, "unghiul de drift ramane sub 60 grade")
	_check(not fired, "asistenta nu porneste in drift")
	car.queue_free()
	await get_tree().physics_frame


func _test_sub_threshold() -> void:
	print("")
	print("-- 4. slip de 80 grade (sub prag): fara asistenta --")
	var car := _spawn()
	await _settle(car)
	_launch_rotated(car, 80.0, 20.0)
	var fired := false
	for _f in 30:
		await get_tree().physics_frame
		if car._spinout_on:
			fired = true
	_check(not fired, "sub prag asistenta nu porneste")
	car.queue_free()
	await get_tree().physics_frame
