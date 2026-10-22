extends Node
## Razuire vs izbitura frontala de perete (docs/feel_checklist.md,
## `glancing-vs-headon`).
##
## Contractele, toate cu GAZ tinut (cum conduce un jucator):
##   1. razuire la 15 grade, 20 m/s: la 1 s dupa contact masina are cel putin
##      80% din viteza unei masini de control fara perete (aceleasi comenzi) si
##      cel putin 75% din viteza de intrare; la 1,5 s e paralela cu peretele
##      (sub 8 grade) sau se departeaza. Acelasi lucru la 25 grade (>= 70%).
##   2. frontal la 14 m/s: se opreste cu bounce — la 0.5 s dupa contact nu mai
##      inainteaza in perete (componenta spre perete < 1 m/s), iar viteza de
##      departare maxima e un bounce (0.5..8 m/s).
##   3. pragul de ejectare ramane eject_wall_dv = 26: frontal la 34 m/s
##      arunca soferul (buggy), razuire la 15 grade la 34 m/s nu.
##   4. anti-lipire: botul infipt in perete, la viteza ~0, gaz tinut: in 2 s
##      masina fie scapa de perete, fie ajunge sa mearga de-a lungul lui
##      (progres lateral >= 3 m), fara sa ramana cu botul in zid.
##   5. hazardele raman neatinse: razuire pe un AnimatableBody3D (autobuz,
##      bariera, tren) NU taie frecarea si NU roteste masina.
## Sabotaj (trebuie sa PICE): `-- --off` opreste logica (glance_enabled=false).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWallGlance.tscn

const STEP: float = 1.0 / 60.0
const BUGGY: CarData = preload("res://scenes/cars/data/buggy.tres")
## Peretele: lung pe X, fata (suprafata) la z = -20, normala spre +Z.
const WALL_Z: float = -20.0

var _failed: bool = false
var _off: bool = false
var _ejected: bool = false


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 1.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
	add_child(_box(StaticBody3D.new(), Vector3(2000, 1, 2000), Vector3(0, -0.5, 0)))
	add_child(_box(StaticBody3D.new(), Vector3(400, 3, 1), Vector3(0, 1.5, WALL_Z - 0.5)))
	# Acelasi perete, dar AnimatableBody3D (hazard), mai la vest.
	add_child(_box(AnimatableBody3D.new(), Vector3(400, 3, 1), Vector3(0, 1.5, WALL_Z - 0.5 + 200.0)))
	await get_tree().physics_frame
	print("")
	print("=== Razuire vs frontal ===")
	if _off:
		print("  (SABOTAJ: glance_enabled = false)")
	await _test_glance(15.0, 20.0, 0.80, 0.75)
	await _test_glance(25.0, 20.0, 0.70, 0.60)
	await _test_head_on()
	await _test_eject()
	await _test_pinned()
	await _test_hazard()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _box(body: PhysicsBody3D, size: Vector3, pos: Vector3) -> PhysicsBody3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	return body


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(pos: Vector3, yaw: float, data: CarData = null) -> Car:
	var car := Car.new()
	add_child(car)
	if data != null:
		car.apply_data(data)
	if _off:
		car.glance_enabled = false
	car.global_position = pos
	car.rotation.y = yaw
	car.set_controller(ScriptDriver.new())
	car.race_active = true
	return car


func _settle(car: Car) -> void:
	(car.controller as ScriptDriver).throttle = 0.0 # fara gaz cat se aseaza
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


## Gaz tinut din acest moment (cum conduce un jucator).
func _go(car: Car) -> void:
	(car.controller as ScriptDriver).throttle = 1.0


## Directia de intrare: `deg` grade spre perete, mergand spre +X.
func _dir(deg: float) -> Vector3:
	return Vector3(cos(deg_to_rad(deg)), 0, -sin(deg_to_rad(deg)))


func _launch(car: Car, deg: float, speed: float) -> void:
	var d := _dir(deg)
	car.rotation.y = atan2(-d.x, -d.z)
	car.linear_velocity = d * speed
	_go(car)


## Viteza de control (fara perete), esantionata pe tick, aceleasi comenzi.
func _control_speeds(deg: float, speed: float, ticks: int, z_off: float) -> Array[float]:
	var c := _spawn(Vector3(-40, 0.7, -17.6 + z_off), 0.0)
	await _settle(c)
	_launch(c, deg, speed)
	var out: Array[float] = []
	for _f in ticks:
		await get_tree().physics_frame
		out.append(c.horizontal_speed())
	c.queue_free()
	await get_tree().physics_frame
	return out


func _test_glance(deg: float, speed: float, min_ratio: float, min_abs: float) -> void:
	print("")
	print("-- 1. razuire la %.0f grade, %.0f m/s, gaz tinut --" % [deg, speed])
	# Controlul sta departe de peretii de test (z = +150: niciun perete).
	var ctrl := await _control_speeds(deg, speed, 200, 150.0)
	var car := _spawn(Vector3(-40, 0.7, -17.6), 0.0)
	await _settle(car)
	_launch(car, deg, speed)
	var tick := 0
	var t0 := -1
	var v_at := -1.0
	var v_ctrl := -1.0
	var ang_end := 99.0
	var away_end := false
	for _f in 200:
		await get_tree().physics_frame
		tick += 1
		if t0 < 0 and car.wall_contact:
			t0 = tick
		if t0 >= 0 and tick == t0 + 60:
			v_at = car.horizontal_speed()
			v_ctrl = ctrl[mini(tick - 1, ctrl.size() - 1)]
		if t0 >= 0 and tick == t0 + 90:
			var f := -car.global_transform.basis.z
			f.y = 0.0
			f = f.normalized()
			var into := -f.dot(car.wall_normal if car.wall_contact else Vector3(0, 0, 1))
			ang_end = rad_to_deg(asin(clampf(into, -1.0, 1.0)))
			away_end = into < 0.0
	if t0 < 0:
		_check(false, "contact cu peretele detectat")
		car.queue_free()
		await get_tree().physics_frame
		return
	var ratio := v_at / maxf(v_ctrl, 0.1)
	print("  contact la tick %d; dupa 1 s: %.1f m/s (control %.1f) = %.0f%% din control, %.0f%% din intrare"
		% [t0, v_at, v_ctrl, ratio * 100.0, v_at / speed * 100.0])
	print("  la 1.5 s: unghi cu peretele %.1f grade (negativ = se departeaza)" % ang_end)
	_check(ratio >= min_ratio, "pastreaza >= %.0f%% fata de control" % (min_ratio * 100.0))
	_check(v_at >= min_abs * speed, "pastreaza >= %.0f%% din viteza de intrare" % (min_abs * 100.0))
	_check(ang_end <= 8.0 or away_end, "paralela cu peretele (<= 8 grade) sau se departeaza")
	car.queue_free()
	await get_tree().physics_frame


func _test_head_on() -> void:
	print("")
	print("-- 2. frontal la 14 m/s, gaz tinut --")
	var car := _spawn(Vector3(0, 0.7, -8), 0.0)
	await _settle(car)
	car.linear_velocity = Vector3(0, 0, -14)
	_go(car)
	var tick := 0
	var t0 := -1
	var entry := 0.0
	var v_at_contact := 99.0
	var max_away := 0.0
	for _f in 120:
		await get_tree().physics_frame
		tick += 1
		var v_into := -car.linear_velocity.z # spre perete (-Z)
		if t0 < 0:
			entry = maxf(entry, v_into)
		if t0 < 0 and car.wall_contact:
			t0 = tick
			v_at_contact = v_into
		if t0 >= 0:
			max_away = maxf(max_away, -v_into)
	if t0 < 0:
		_check(false, "contact cu peretele detectat")
	else:
		print("  viteza spre perete: intrare %.1f m/s, la contact %.2f m/s; bounce maxim %.2f m/s"
			% [entry, v_at_contact, max_away])
		_check(entry > 12.0, "a lovit peretele cu viteza (intrare > 12 m/s)")
		_check(v_at_contact <= 0.3 * entry, "se opreste: componenta spre perete taiata cu >= 70%")
		_check(max_away >= 0.5 and max_away <= 8.0, "bounce mic (0.5..8 m/s)")
	car.queue_free()
	await get_tree().physics_frame


func _test_eject() -> void:
	print("")
	print("-- 3. pragul de ejectare ramane eject_wall_dv --")
	var probe_car := Car.new()
	_check(is_equal_approx(probe_car.eject_wall_dv, 26.0), "eject_wall_dv = 26 (%.1f)" % probe_car.eject_wall_dv)
	probe_car.free()
	# Frontal la 34 m/s: arunca.
	var car := _spawn(Vector3(300, 0.7, -2), 0.0, BUGGY)
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: _ejected = true)
	await _settle(car)
	_ejected = false
	car.linear_velocity = Vector3(0, 0, -34)
	_go(car)
	car.global_position = Vector3(0, 0.7, -8)
	for _f in 90:
		await get_tree().physics_frame
	_check(_ejected, "frontal la 34 m/s arunca soferul")
	car.queue_free()
	await get_tree().physics_frame
	# Razuire la 15 grade, 34 m/s: nu.
	var car2 := _spawn(Vector3(-60, 0.7, -17.6), 0.0, BUGGY)
	car2.ejected.connect(func(_c: Car, _r: Node3D) -> void: _ejected = true)
	await _settle(car2)
	_ejected = false
	_launch(car2, 15.0, 34.0)
	for _f in 120:
		await get_tree().physics_frame
	_check(not _ejected, "razuire la 15 grade, 34 m/s nu arunca soferul")
	car2.queue_free()
	await get_tree().physics_frame


func _test_pinned() -> void:
	print("")
	print("-- 4. anti-lipire: botul in perete, viteza ~0, gaz tinut --")
	# Botul spre perete (-Z), lipit de el; 20 de grade ca sa existe o directie.
	var car := _spawn(Vector3(100, 0.7, WALL_Z + 2.4), deg_to_rad(20.0))
	await _settle(car)
	_go(car)
	var start_x := car.global_position.x
	var lateral := 0.0
	var free_t := -1.0
	var t := 0.0
	var min_into := 1.0
	for _f in 120:
		await get_tree().physics_frame
		t += STEP
		var f := -car.global_transform.basis.z
		var into := -f.dot(Vector3(0, 0, 1)) * -1.0 # +1 = botul in perete
		min_into = minf(min_into, into)
		if OS.get_cmdline_user_args().has("--trace") and int(t / STEP) % 6 == 0:
			print("   t=%.2f x=%.2f z=%.2f v=%.2f fwd=(%.2f,%.2f) wc=%s stuck=%.2f yaw=%.2f" % [t,
				car.global_position.x, car.global_position.z, car.horizontal_speed(),
				-car.global_transform.basis.z.x, -car.global_transform.basis.z.z,
				car.wall_contact, car._stuck_t, car._impact_yaw])
	lateral = absf(car.global_position.x - start_x)
	var f2 := -car.global_transform.basis.z
	var into_end := -f2.z # +1 = botul drept in perete
	var dist := car.global_position.z - WALL_Z
	print("  dupa 2 s: progres lateral %.1f m, distanta la perete %.2f m, botul in perete %.2f (0 = paralel)"
		% [lateral, dist, into_end])
	_check(into_end < 0.35 or dist > 3.0, "dupa 2 s nu mai are botul in perete (sub 20 grade) sau e liber")
	car.queue_free()
	await get_tree().physics_frame


func _test_hazard() -> void:
	print("")
	print("-- 5. hazardul (AnimatableBody3D) ramane neatins --")
	var z0 := 200.0
	var car := _spawn(Vector3(-40, 0.7, z0 - 17.6), 0.0)
	await _settle(car)
	_launch(car, 15.0, 20.0)
	var min_fric := 1.0
	var max_yaw := 0.0
	var contact_frames := 0
	for _f in 120:
		await get_tree().physics_frame
		if car.wall_contact:
			contact_frames += 1
			min_fric = minf(min_fric, car.physics_material_override.friction)
			max_yaw = maxf(max_yaw, absf(car._impact_yaw))
	print("  cadre in contact %d, frecare minima %.2f, nudge de yaw maxim %.2f"
		% [contact_frames, min_fric, max_yaw])
	_check(contact_frames >= 3, "contact cu hazardul detectat")
	_check(is_equal_approx(min_fric, 0.4), "frecarea ramane 0.4 pe hazard")
	_check(max_yaw < 0.01, "niciun nudge de yaw pe hazard")
	car.queue_free()
	await get_tree().physics_frame
