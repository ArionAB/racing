extends Node
## Soferul reactioneaza (feel_checklist: driver-reacts, driver-social).
##
## Masoara TRANSFORMARILE pieselor figurinei (cele pe care le deseneaza
## jocul), nu variabilele interne:
##   1. tresarire: la o izbitura frontala capul si trunchiul se duc INAPOI de
##      lovitura (spre fata, pentru ca normala e spre spate), varf capul 15-45
##      de grade, revin sub 15% la 0.4 s; o lovitura laterala le duce lateral;
##      o masina in repaus nu are nicio deviatie (control);
##   2. tremurul bratelor: pe teren cu trepte (`inca_steps`) bratele tremura
##      de cateva ori mai mult decat pe teren neted, la aceeasi viteza;
##   3. privirea: cu o masina la 3 m pe dreapta capul se intoarce spre ea
##      (fata capului capata componenta +X), la stanga invers; cu masina la
##      9 m sau in fata/spate nu se intoarce;
##   4. pumnul: dupa ce alta masina te loveste din dreapta, bratul DREPT urca si
##      se agita, mai putin de o secunda, iar capul se uita spre cel care te-a
##      lovit; masina care LOVESTE nu isi agita pumnul; un perete nu scoate
##      pumnul.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDriverReact.tscn

const STEP: float = 1.0 / 60.0
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

var _failed: bool = false


class ScriptDriver:
	extends CarController
	var throttle: float = 0.0
	func get_throttle() -> float:
		return throttle


func _ready() -> void:
	add_child(_box(Vector3(1200, 1, 1200), Vector3(0, -0.5, 0), false))
	# Teren cu trepte, departe de cel neted.
	add_child(_box(Vector3(200, 1, 1200), Vector3(1500, -0.5, 0), true))
	await get_tree().physics_frame
	print("")
	print("=== Soferul reactioneaza ===")
	await _test_flinch()
	await _test_rough()
	await _test_glance()
	await _test_fist()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _box(size: Vector3, pos: Vector3, steps: bool) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	if steps:
		b.set_meta(&"inca_steps", true)
	return b


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _open_data() -> CarData:
	for d in GameState.CAR_DATA:
		var cd := d as CarData
		if cd.open_cockpit and cd.driver_model != null:
			return cd
	return null


func _spawn(pos: Vector3, yaw: float = 0.0) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(_open_data())
	car.global_position = pos
	car.rotation.y = yaw
	car.race_active = true
	return car


func _settle(cars: Array) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	for c in cars:
		(c as Car).linear_velocity = Vector3.ZERO
		(c as Car).angular_velocity = Vector3.ZERO


## Cu cate grade e abatuta piesa de la repaus.
func _deflect(drv: Driver, part: StringName) -> float:
	var cur: Basis = (drv._parts[part] as Node3D).transform.basis
	var rest: Basis = (drv._rest[part] as Transform3D).basis
	var ang := (rest.inverse() * cur).get_rotation_quaternion().get_angle()
	# get_angle() e in [0, 2 PI]: o rotatie de 120 grade poate veni ca 240.
	return rad_to_deg(minf(ang, TAU - ang))


## Unde arata varful piesei (+Y) / fata ei (-Z) in spatiul masinii, abatere
## fata de repaus (orizontala).
func _top_shift(drv: Driver, part: StringName) -> Vector3:
	var cur: Basis = (drv._parts[part] as Node3D).transform.basis
	var rest: Basis = (drv._rest[part] as Transform3D).basis
	var d: Vector3 = cur * Vector3.UP - rest * Vector3.UP
	return Vector3(d.x, 0.0, d.z)


func _face_shift(drv: Driver) -> Vector3:
	var cur: Basis = (drv._parts[&"Head"] as Node3D).transform.basis
	var rest: Basis = (drv._rest[&"Head"] as Transform3D).basis
	var d: Vector3 = cur * Vector3.FORWARD - rest * Vector3.FORWARD
	return Vector3(d.x, 0.0, d.z)


func _test_flinch() -> void:
	print("")
	print("-- 1. tresarire la impact --")
	var car := _spawn(Vector3(0, 0.7, 0))
	await _settle([car])
	var drv: Driver = car._driver
	_check(drv != null, "(control) masina deschisa are sofer")
	var base := _deflect(drv, &"Head")
	print("  repaus: deviatia capului %.2f grade" % base)
	_check(base < 2.0, "fara impact capul sta la repaus (< 2 grade)")

	# Frontala: normala +Z (spre spatele masinii), capul se duce inainte (-Z).
	car.impact.emit(car, &"wall", 14.0, Vector3.BACK, car.global_position, null)
	var peak := 0.0
	var peak_torso := 0.0
	var shift := Vector3.ZERO
	var at04 := 0.0
	var at06 := 0.0
	for f in 45:
		await get_tree().physics_frame
		var h := _deflect(drv, &"Head")
		if h > peak:
			peak = h
			shift = _top_shift(drv, &"Head")
		peak_torso = maxf(peak_torso, _deflect(drv, &"Torso"))
		if f == 24:
			at04 = h
		if f == 36:
			at06 = h
	print("  frontala 14 m/s: varf cap %.1f grade (varful se duce la %+.2f, %+.2f), trunchi %.1f; la 0.4 s %.1f (%.0f%%), la 0.6 s %.1f"
		% [peak, shift.x, shift.z, peak_torso, at04, 100.0 * at04 / maxf(peak, 0.01), at06])
	_check(peak >= 15.0 and peak <= 45.0, "capul: varf 15-45 grade")
	_check(peak_torso >= 8.0, "trunchiul tresare si el (>= 8 grade)")
	_check(shift.z < -0.1 and absf(shift.x) < 0.1, "capul se duce INAPOI de lovitura (inainte, -Z)")
	_check(at04 < 0.15 * peak and at06 < 0.06 * peak, "revenire: < 15% la 0.4 s, < 6% la 0.6 s")

	# Laterala: normala +X (impins spre dreapta) -> capul spre stanga.
	car.impact.emit(car, &"wall", 14.0, Vector3.RIGHT, car.global_position, null)
	var side := Vector3.ZERO
	var side_peak := 0.0
	for _f in 20:
		await get_tree().physics_frame
		if _deflect(drv, &"Head") > side_peak:
			side_peak = _deflect(drv, &"Head")
			side = _top_shift(drv, &"Head")
	print("  laterala (impins spre dreapta): varful capului se duce la %+.2f, %+.2f" % [side.x, side.z])
	_check(side.x < -0.1, "lovitura laterala duce capul in partea opusa (-X)")

	# Proportional: o atingere mica tresare mai putin.
	for _f in 40:
		await get_tree().physics_frame
	car.impact.emit(car, &"wall", 3.0, Vector3.BACK, car.global_position, null)
	var small := 0.0
	for _f in 20:
		await get_tree().physics_frame
		small = maxf(small, _deflect(drv, &"Head"))
	print("  atingere de 3 m/s: varf cap %.1f grade" % small)
	_check(small > 3.0 and small < peak * 0.7, "o atingere mica tresare mai putin, dar se vede")
	car.queue_free()
	await get_tree().physics_frame


func _arm_activity(x0: float) -> float:
	var car := _spawn(Vector3(x0, 0.7, 400))
	var drv_ctl := ScriptDriver.new()
	car.set_controller(drv_ctl)
	await _settle([car])
	drv_ctl.throttle = 1.0
	for _f in int(3.5 / STEP): # prinde viteza
		await get_tree().physics_frame
	var drv: Driver = car._driver
	var samples: Array[float] = []
	var speed := car.horizontal_speed()
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
		samples.append(_deflect(drv, &"Arm_L"))
	var mn := 999.0
	var mx := 0.0
	for v in samples:
		mn = minf(mn, v)
		mx = maxf(mx, v)
	print("  x=%.0f: viteza %.1f m/s, aspritate %.2f, bratul stang variaza %.2f..%.2f grade (amplitudine %.2f)"
		% [x0, speed, drv._rough, mn, mx, mx - mn])
	car.queue_free()
	await get_tree().physics_frame
	return mx - mn


func _test_rough() -> void:
	print("")
	print("-- 2. tremurul bratelor pe teren aspru --")
	var smooth := await _arm_activity(0.0)
	var rough := await _arm_activity(1500.0)
	_check(rough > 2.0, "pe trepte bratele tremura vizibil (> 2 grade amplitudine)")
	_check(rough > 3.0 * maxf(smooth, 0.3), "de cel putin 3 ori mai mult decat pe teren neted")


func _test_glance() -> void:
	print("")
	print("-- 3. privirea spre masina de alaturi --")
	var results := {}
	for case in [["dreapta 3 m", Vector3(3, 0, 0)], ["stanga 3 m", Vector3(-3, 0, 0)],
			["dreapta 9 m", Vector3(9, 0, 0)], ["in fata 3 m", Vector3(0, 0, -3)],
			["in spate 3 m", Vector3(0, 0, 3)]]:
		var a := _spawn(Vector3(300, 0.7, -300))
		var b := _spawn(Vector3(300, 0.7, -300) + (case[1] as Vector3))
		await _settle([a, b])
		for _f in 40:
			await get_tree().physics_frame
		var shift := _face_shift(a._driver)
		results[case[0]] = shift
		print("  %s: fata capului se muta cu (%+.2f, %+.2f)" % [case[0], shift.x, shift.z])
		a.queue_free()
		b.queue_free()
		await get_tree().physics_frame
	_check((results["dreapta 3 m"] as Vector3).x > 0.3, "masina la dreapta: capul se intoarce spre dreapta")
	_check((results["stanga 3 m"] as Vector3).x < -0.3, "masina la stanga: capul se intoarce spre stanga")
	_check(absf((results["dreapta 9 m"] as Vector3).x) < 0.1, "la 9 m nu se uita")
	_check(absf((results["in fata 3 m"] as Vector3).x) < 0.1 and absf((results["in spate 3 m"] as Vector3).x) < 0.1,
		"o masina in fata sau in spate nu e „alaturi”")


func _test_fist() -> void:
	print("")
	print("-- 4. pumnul dupa ce esti lovit de alta masina --")
	# A sta; B vine din dreapta (x = +9) cu 12 m/s spre -X si o loveste lateral.
	var a := _spawn(Vector3(-300, 0.7, 300))
	var b := _spawn(Vector3(-291, 0.7, 300), PI * 0.5)
	await _settle([a, b])
	b.linear_velocity = Vector3(-12, 0, 0)
	var a_arm_r := 0.0
	var a_arm_l := 0.0
	var b_arm_r := 0.0
	var b_arm_l := 0.0
	var fist_on := 0.0
	var started := -1.0
	var ended := -1.0
	var yaw_shift := Vector3.ZERO
	var impacts: Array[Dictionary] = []
	a.impact.connect(func(_c, k, s, _n, _p, _o) -> void: impacts.append({"who": "A", "k": k, "s": s}))
	b.impact.connect(func(_c, k, s, _n, _p, _o) -> void: impacts.append({"who": "B", "k": k, "s": s}))
	var t := 0.0
	for _f in int(2.5 / STEP):
		await get_tree().physics_frame
		t += STEP
		var ar: float = _deflect(a._driver, &"Arm_R")
		a_arm_r = maxf(a_arm_r, ar)
		a_arm_l = maxf(a_arm_l, _deflect(a._driver, &"Arm_L"))
		b_arm_r = maxf(b_arm_r, _deflect(b._driver, &"Arm_R"))
		b_arm_l = maxf(b_arm_l, _deflect(b._driver, &"Arm_L"))
		if (a._driver as Driver)._fist_t >= 0.0:
			if started < 0.0:
				started = t
			ended = t
			if _deflect(a._driver, &"Arm_R") > fist_on:
				fist_on = _deflect(a._driver, &"Arm_R")
				yaw_shift = _face_shift(a._driver)
	print("  impacturi: %s" % [impacts])
	print("  A (lovit din dreapta): brat drept max %.0f grade, brat stang %.0f; pumn activ %.2f..%.2f s (durata %.2f s), fata capului %+.2f,%+.2f"
		% [a_arm_r, a_arm_l, started, ended, ended - started, yaw_shift.x, yaw_shift.z])
	print("  B (cel care loveste): brat drept %.0f, brat stang %.0f grade" % [b_arm_r, b_arm_l])
	_check(started > 0.0, "(control) A a fost lovita")
	_check(a_arm_r > 60.0 and a_arm_l < 0.5 * a_arm_r, "bratul DIN PARTEA loviturii urca (> 60 grade), celalalt (doar tresarirea trunchiului) mult mai putin")
	_check(ended - started < 1.0, "pumnul tine sub o secunda")
	_check(yaw_shift.x > 0.2, "capul se uita spre cel care a lovit (dreapta)")
	_check(b_arm_r < 30.0 and b_arm_l < 30.0, "masina care loveste nu isi agita pumnul")
	# Dupa pumn: bratul revine.
	var back := _deflect(a._driver, &"Arm_R")
	print("  la sfarsit bratul drept e la %.1f grade de repaus" % back)
	_check(back < 15.0, "bratul revine dupa pumn")
	a.queue_free()
	b.queue_free()
	await get_tree().physics_frame

	# Perete: tresare, dar fara pumn.
	add_child(_box(Vector3(60, 3, 1), Vector3(-300, 1.5, 270.5), false))
	var c := _spawn(Vector3(-300, 0.7, 276))
	await _settle([c])
	c.linear_velocity = Vector3(0, 0, -14)
	var fist_wall := false
	var arm_wall := 0.0
	for _f in int(1.2 / STEP):
		await get_tree().physics_frame
		if (c._driver as Driver)._fist_t >= 0.0:
			fist_wall = true
		arm_wall = maxf(arm_wall, _deflect(c._driver, &"Arm_R"))
	print("  perete: pumn=%s, brat drept max %.0f grade" % [fist_wall, arm_wall])
	_check(not fist_wall and arm_wall < 40.0, "un perete nu scoate pumnul")
	c.queue_free()
	await get_tree().physics_frame
