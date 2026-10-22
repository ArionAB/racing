extends Node
## Jolt-ul caroseriei VIZUALE la izbitura (feel_checklist: body-jolt).
##
## Verifica, pe Car real:
##   1. o izbitura frontala REALA in perete impinge `_visual` in directia
##      normalei (offset local +Z, varful se apleaca inapoi), nu corpul fizic;
##   2. varful: 3-10 cm si 1-6 grade la o izbitura mare, proportional cu forta;
##   3. revenire: sub 12% din varf la 0.4 s, sub 5% la 0.6 s (arc subamortizat:
##      trece o data prin zero, nu ramane intins);
##   4. se COMPUNE cu restul scriitorilor lui `_visual`: ruliul de drift
##      ramane (nu e mancat de jolt), invartirea de tromba la fel, iar tween-ul
##      de squash isi pastreaza scala;
##   5. repunerea (`respawned`) sterge jolt-ul.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBodyJolt.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	var drift: bool = false
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return drift


func _ready() -> void:
	var ground := _box(Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	add_child(ground)
	add_child(_box(Vector3(200, 3, 1), Vector3(0, 1.5, -20.5)))
	await get_tree().physics_frame
	print("")
	print("=== Body jolt pe caroseria vizuala ===")
	await _test_real_wall()
	await _test_scaling_and_return()
	await _test_composition()
	await _test_respawn_clears()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	return b


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(pos: Vector3) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	car.race_active = true
	return car


func _settle(car: Car) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


## Unghiul (grade) cu care varful caroseriei vizuale s-a abatut de la vertical.
func _tilt_deg(car: Car) -> float:
	var up: Vector3 = car._visual.basis * Vector3.UP
	return rad_to_deg(acos(clampf(up.normalized().y, -1.0, 1.0)))


## Pe ce parte cade varful (componenta orizontala, spatiul masinii).
func _top_lean(car: Car) -> Vector3:
	var up: Vector3 = car._visual.basis * Vector3.UP
	return Vector3(up.x, 0.0, up.z)


func _test_real_wall() -> void:
	print("")
	print("-- 1. izbitura frontala reala in perete la 14 m/s --")
	var car := _spawn(Vector3(0, 0.7, -8))
	await _settle(car)
	car.linear_velocity = Vector3(0, 0, -14)
	var peak_off := 0.0
	var peak_tilt := 0.0
	var off_at_peak := Vector3.ZERO
	var lean_at_peak := Vector3.ZERO
	var hit_frame := -1
	var hits: Array[float] = []
	car.impact.connect(func(_c, _k, s, _n, _p, _o) -> void: hits.append(s))
	for f in int(1.0 / STEP):
		await get_tree().physics_frame
		if not hits.is_empty() and hit_frame < 0:
			hit_frame = f
		if hit_frame >= 0 and f - hit_frame < 30:
			var o: Vector3 = car._visual.position
			if o.length() > peak_off:
				peak_off = o.length()
				off_at_peak = o
			if _tilt_deg(car) > peak_tilt:
				peak_tilt = _tilt_deg(car)
				lean_at_peak = _top_lean(car)
	print("  forta izbiturii %.1f; varf offset %.3f m la (%.3f, %.3f, %.3f); varf inclinare %.2f grade, varful cade spre (%.3f, %.3f)"
		% [hits[0] if not hits.is_empty() else 0.0, peak_off, off_at_peak.x,
			off_at_peak.y, off_at_peak.z, peak_tilt, lean_at_peak.x, lean_at_peak.z])
	_check(hit_frame >= 0, "izbitura a emis `impact`")
	_check(off_at_peak.z > 0.5 * peak_off, "offset-ul e pe +Z local (spre normala, inapoi)")
	_check(lean_at_peak.z > 0.0, "varful caroseriei se apleaca inapoi, in afara peretelui")
	_check(peak_off >= 0.03 and peak_off <= 0.10, "varf 3-10 cm")
	_check(peak_tilt >= 1.0 and peak_tilt <= 6.0, "inclinare 1-6 grade")
	car.queue_free()
	await get_tree().physics_frame


func _test_scaling_and_return() -> void:
	print("")
	print("-- 2. proportional cu forta; revenire in 0.4 s (injectat, masina stand pe loc) --")
	var car := _spawn(Vector3(40, 0.7, 40))
	await _settle(car)
	var peaks: Array[float] = []
	var back_ok := true
	var crossed := false
	for dv in [3.0, 8.0, 14.0]:
		# Pauza: arcul de la proba precedenta se stinge.
		for _f in 40:
			await get_tree().physics_frame
		car.impact.emit(car, &"wall", dv, Vector3.RIGHT, car.global_position, null)
		var peak := 0.0
		var at04 := 0.0
		var at06 := 0.0
		var sign_prev := 0.0
		var crossings := 0
		for f in 45:
			await get_tree().physics_frame
			var x: float = (car._visual.position as Vector3).x
			peak = maxf(peak, absf(x))
			if f == 24:
				at04 = absf(x)
			if f == 36:
				at06 = absf(x)
			var sg := signf(x) if absf(x) > 0.0005 else 0.0
			if sg != 0.0 and sign_prev != 0.0 and sg != sign_prev:
				crossings += 1
			if sg != 0.0:
				sign_prev = sg
		peaks.append(peak)
		print("  dv %.0f: varf %.3f m, la 0.4 s %.4f (%.1f%%), la 0.6 s %.4f, treceri prin zero %d"
			% [dv, peak, at04, 100.0 * at04 / maxf(peak, 1e-6), at06, crossings])
		if at04 > 0.12 * peak or at06 > 0.05 * peak:
			back_ok = false
		if crossings >= 1:
			crossed = true
	_check(peaks[0] < peaks[1] and peaks[1] < peaks[2], "varful creste cu forta (3 < 8 < 14 m/s)")
	_check(peaks[0] > 0.01, "chiar si o lovitura mica de 3 m/s se vede (> 1 cm)")
	_check(back_ok, "revenire: < 12% din varf la 0.4 s, < 5% la 0.6 s")
	_check(crossed, "arc subamortizat: trece o data prin zero")
	car.queue_free()
	await get_tree().physics_frame


func _test_composition() -> void:
	print("")
	print("-- 3. compus cu ruliul de drift, tromba si squash --")
	var car := _spawn(Vector3(-60, 0.7, 60))
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	await _settle(car)
	drv.throttle = 1.0
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
	drv.steer = 1.0
	drv.drift = true
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	var roll_before := absf(car._visual.rotation.z)
	print("  ruliu de drift inainte de lovitura: %.4f rad, drifting=%s" % [roll_before, car.is_drifting])
	_check(car.is_drifting and roll_before > 0.01, "ruliul de drift exista (> 0.01 rad)")
	# Lovitura laterala injectata; ruliul de drift trebuie sa ramana in jur.
	car.impact.emit(car, &"wall", 14.0, car.global_transform.basis.x, car.global_position, null)
	for _f in 60:
		await get_tree().physics_frame
	var roll_after := absf(car._visual.rotation.z)
	print("  ruliu dupa revenire: %.4f rad (inainte %.4f)" % [roll_after, roll_before])
	_check(roll_after > 0.5 * roll_before and roll_after < 1.5 * roll_before,
		"dupa revenire ruliul de drift e inapoi (nu l-a sters jolt-ul)")
	drv.drift = false
	drv.steer = 0.0
	drv.throttle = 0.0
	for _f in 60:
		await get_tree().physics_frame
	# Squash: tween-ul de scala nu e calcat de jolt.
	car._punch_scale(Vector3(1.15, 0.8, 1.15))
	car.impact.emit(car, &"wall", 14.0, Vector3.BACK, car.global_position, null)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var sc: Vector3 = car._visual.scale
	print("  scala in squash cu jolt activ: (%.3f, %.3f, %.3f)" % [sc.x, sc.y, sc.z])
	_check(sc.y < 0.95 and sc.x > 1.02, "squash-ul ruleaza peste jolt (scala nestearsa)")
	_check((car._visual.position as Vector3).length() > 0.005, "iar jolt-ul se vede in acelasi timp")
	for _f in 60:
		await get_tree().physics_frame
	_check(car._visual.scale.is_equal_approx(Vector3.ONE), "squash-ul revine la scala 1")
	# Tromba: spin_body pe Y ramane.
	car.spin_body(8.0, 0.4)
	car.impact.emit(car, &"wall", 14.0, Vector3.BACK, car.global_position, null)
	for _f in 12:
		await get_tree().physics_frame
	var yaw: float = car._visual.rotation.y
	print("  rotatia tromba (Y) cu jolt activ: %.3f rad" % yaw)
	_check(absf(yaw) > 0.2, "tromba (spin_body) continua sa roteasca caroseria")
	car.queue_free()
	await get_tree().physics_frame


func _test_respawn_clears() -> void:
	print("")
	print("-- 4. repunerea sterge jolt-ul --")
	var car := _spawn(Vector3(80, 0.7, 80))
	await _settle(car)
	car.impact.emit(car, &"wall", 14.0, Vector3.RIGHT, car.global_position, null)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var before := (car._visual.position as Vector3).length()
	car.respawned.emit(car)
	var after := (car._visual.position as Vector3).length()
	print("  offset inainte %.4f, dupa respawned %.4f" % [before, after])
	_check(before > 0.005 and after < 0.0001, "respawned reseteaza offset-ul si inclinarea")
	car.queue_free()
	await get_tree().physics_frame
