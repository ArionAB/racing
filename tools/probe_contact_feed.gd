extends Node
## Feed-ul comun de contact (docs/feel_checklist.md): semnalul `impact` si
## starea continua (wall_contact / wall_scrape_speed / rub_car / rub_speed).
##
## Verifica:
##   1. izbitura frontala in perete: `impact` &"wall", normala dinspre perete
##      spre masina (aici +Z), forta ~ viteza de inchidere;
##   2. razuire in unghi mic: wall_contact tine mai multe cadre, iar
##      wall_scrape_speed > 3 m/s cat timp aluneci pe langa perete;
##   3. lovitura laterala intre masini: `impact` &"car" pe AMANDOUA, fiecare
##      cu normala spre ea insasi (opuse intre ele), si rub_car setat.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeContactFeed.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _events: Array[Dictionary] = []


func _ready() -> void:
	var ground := _box(Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	add_child(ground)
	# Perete lung pe axa X, la z = -20, fata spre +Z.
	add_child(_box(Vector3(200, 3, 1), Vector3(0, 1.5, -20.5)))
	await get_tree().physics_frame
	print("")
	print("=== Feed-ul comun de contact ===")
	await _test_head_on()
	await _test_scrape()
	await _test_car_side()
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


func _spawn(pos: Vector3, yaw: float = 0.0) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	car.rotation.y = yaw
	car.race_active = true
	car.impact.connect(func(c: Car, kind: StringName, strength: float,
			normal: Vector3, point: Vector3, other: Node) -> void:
		_events.append({"car": c, "kind": kind, "strength": strength,
			"normal": normal, "point": point, "other": other}))
	return car


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _settle(cars: Array) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	for c in cars:
		(c as Car).linear_velocity = Vector3.ZERO


func _test_head_on() -> void:
	print("")
	print("-- 1. frontal in perete la 14 m/s --")
	_events.clear()
	var car := _spawn(Vector3(0, 0.7, -8))
	await _settle([car])
	car.linear_velocity = Vector3(0, 0, -14)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	var walls := _events.filter(func(e: Dictionary) -> bool: return e.kind == &"wall")
	print("  evenimente wall: %d" % walls.size())
	if walls.is_empty():
		_check(false, "impact &\"wall\" emis")
	else:
		var e: Dictionary = walls[0]
		var n: Vector3 = e.normal
		print("  forta %.1f, normala (%.2f, %.2f, %.2f), punct z=%.2f"
			% [float(e.strength), n.x, n.y, n.z, (e.point as Vector3).z])
		_check(true, "impact &\"wall\" emis")
		_check(n.z > 0.9, "normala dinspre perete spre masina (+Z)")
		_check(float(e.strength) > 8.0, "forta urmeaza inchiderea (> 8 m/s)")
		_check(absf((e.point as Vector3).z + 20.0) < 1.5, "punctul e pe fata peretelui")
	car.queue_free()
	await get_tree().physics_frame


func _test_scrape() -> void:
	print("")
	print("-- 2. razuire la 15 grade, 16 m/s --")
	_events.clear()
	var car := _spawn(Vector3(-40, 0.7, -17.6), -PI * 0.5)
	await _settle([car])
	var dir := Vector3(cos(deg_to_rad(15.0)), 0, -sin(deg_to_rad(15.0)))
	car.rotation.y = atan2(-dir.x, -dir.z)
	car.linear_velocity = dir * 16.0
	var contact_frames := 0
	var max_scrape := 0.0
	for _f in int(2.0 / STEP):
		await get_tree().physics_frame
		if car.wall_contact:
			contact_frames += 1
			max_scrape = maxf(max_scrape, car.wall_scrape_speed)
	print("  cadre in contact: %d, viteza maxima de razuire %.1f m/s, normala (%.2f, %.2f)"
		% [contact_frames, max_scrape, car.wall_normal.x, car.wall_normal.z])
	_check(contact_frames >= 3, "wall_contact tine mai multe cadre")
	_check(max_scrape > 3.0, "wall_scrape_speed masoara alunecarea pe perete")
	_check(car.wall_normal.z > 0.8, "wall_normal arata spre pista")
	car.queue_free()
	await get_tree().physics_frame


func _test_car_side() -> void:
	print("")
	print("-- 3. T-bone intre masini la 10 m/s --")
	_events.clear()
	# T-bone: `a` cu botul spre +X (yaw -90°) intra in coasta lui `b`.
	var a := _spawn(Vector3(30, 0.7, 10), -PI * 0.5)
	var b := _spawn(Vector3(37, 0.7, 10))
	await _settle([a, b])
	a.linear_velocity = Vector3(10, 0, 0)
	var rubbed := false
	for _f in int(1.2 / STEP):
		await get_tree().physics_frame
		if a.rub_car == b or b.rub_car == a:
			rubbed = true
	var ea := _events.filter(func(e: Dictionary) -> bool:
		return e.kind == &"car" and e.car == a)
	var eb := _events.filter(func(e: Dictionary) -> bool:
		return e.kind == &"car" and e.car == b)
	print("  evenimente car: a=%d b=%d" % [ea.size(), eb.size()])
	_check(not ea.is_empty() and not eb.is_empty(), "impact &\"car\" pe amandoua masinile")
	if not ea.is_empty() and not eb.is_empty():
		var na: Vector3 = ea[0].normal
		var nb: Vector3 = eb[0].normal
		print("  normala a (%.2f, %.2f), b (%.2f, %.2f)" % [na.x, na.z, nb.x, nb.z])
		_check(na.x < -0.8 and nb.x > 0.8, "fiecare normala arata spre masina ei")
		_check(ea[0].other == b and eb[0].other == a, "`other` e masina lovita")
	_check(rubbed, "rub_car se seteaza in contact")
	a.queue_free()
	b.queue_free()
	await get_tree().physics_frame
