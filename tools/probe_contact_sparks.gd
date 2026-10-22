extends Node
## Scanteile de contact (feel_checklist: scrape-sparks, side-rubbing — partea
## vizuala): razuirea pe perete, rafala la izbitura de perete, frecarea intre
## masini si aplecarea corpurilor.
##
## Verifica, pe Car real:
##   1. razuire pe perete: `ScrapeSparks` emite cat timp `wall_contact` si
##      `wall_scrape_speed` > prag, se opreste in cel mult 0.2 s dupa
##      desprindere, iar rata (partea opaca a rampei) creste cu viteza;
##   2. sub prag (alunecare lenta) nu emite;
##   3. rafala `Sparks` la izbitura de perete >= 6 m/s, nu si sub 6;
##   4. frecare intre masini: EXACT o masina din pereche emite (fara dublura),
##      opreste in 0.2 s dupa separare, iar corpurile se apleaca una de alta;
##   5. bugetul de particule pe masina: scanteile continue + rafala <= 32.
## Numaratoarea de emitatori nu dovedeste ca se VEDE ceva — vezi capturile
## din raport; sonda doar pazeste logica (cand, unde, cat).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeContactSparks.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false


func _ready() -> void:
	add_child(_box(Vector3(800, 1, 800), Vector3(0, -0.5, 0)))
	# Perete lung pe axa X, fata spre +Z la z = -20.
	add_child(_box(Vector3(300, 3, 1), Vector3(0, 1.5, -20.5)))
	await get_tree().physics_frame
	print("")
	print("=== Scantei de contact ===")
	await _test_wall_scrape()
	await _test_wall_burst()
	await _test_car_rub()
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


func _spawn(pos: Vector3, yaw: float = 0.0) -> Car:
	var car := Car.new()
	add_child(car)
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


## Razuire pe perete in unghi de `deg` grade, cu viteza `speed`; intoarce
## cadrele cu emisie, viteza maxima de razuire si rata (offset-ul rampei).
func _scrape_run(x0: float, deg: float, speed: float) -> Dictionary:
	var car := _spawn(Vector3(x0, 0.7, -17.6), -PI * 0.5)
	await _settle([car])
	var dir := Vector3(cos(deg_to_rad(deg)), 0, -sin(deg_to_rad(deg)))
	car.rotation.y = atan2(-dir.x, -dir.z)
	car.linear_velocity = dir * speed
	var e: CPUParticles3D = car._scrape_sparks
	var out := {"car": car, "emit_frames": 0, "contact_frames": 0,
		"max_scrape": 0.0, "rate": 0.0, "emit_without_contact": 0,
		"dist_to_wall": 99.0}
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
		if car.wall_contact:
			out.contact_frames += 1
			out.max_scrape = maxf(out.max_scrape, car.wall_scrape_speed)
		if e.emitting:
			out.emit_frames += 1
			out.rate = maxf(out.rate, (car._scrape_density as Gradient).get_offset(1))
			out.dist_to_wall = minf(out.dist_to_wall,
				absf(e.global_position.z - (-20.0)))
			if not (car.wall_contact and car.wall_scrape_speed > car.scrape_min_speed):
				out.emit_without_contact += 1
	return out


func _test_wall_scrape() -> void:
	print("")
	print("-- 1. razuire pe perete: 16 m/s la 12 grade, apoi 6 m/s, apoi 2 m/s --")
	var fast := await _scrape_run(-90.0, 12.0, 16.0)
	print("  rapid: contact %d cadre, viteza max de razuire %.1f, emisie %d cadre, rata %.2f, emitator la %.2f m de perete"
		% [fast.contact_frames, fast.max_scrape, fast.emit_frames, fast.rate, fast.dist_to_wall])
	_check(fast.emit_frames >= 10, "emite cat timp razuieste (>= 10 cadre)")
	_check(fast.emit_without_contact == 0, "emite DOAR cand wall_contact si viteza > prag")
	_check(fast.dist_to_wall < 1.5, "emitatorul sta pe perete (< 1.5 m de fata lui)")
	var car: Car = fast.car
	var e: CPUParticles3D = car._scrape_sparks
	# Desprindere: ducem masina departe de perete si masuram cat mai emite.
	car.linear_velocity = Vector3(0, 0, 14)
	var stop_frame := -1
	for f in int(0.6 / STEP):
		await get_tree().physics_frame
		if not e.emitting and stop_frame < 0:
			stop_frame = f
	print("  oprit dupa %d cadre (%.3f s)" % [stop_frame, stop_frame * STEP])
	_check(stop_frame >= 0 and stop_frame * STEP <= 0.2, "se opreste in cel mult 0.2 s dupa desprindere")
	_check(car._scrape_sparks.amount + car._sparks.amount <= 32,
		"buget: %d continue + %d rafala <= 32" % [car._scrape_sparks.amount, car._sparks.amount])
	car.queue_free()
	await get_tree().physics_frame

	var mid := await _scrape_run(60.0, 12.0, 8.0)
	print("  mediu: viteza max de razuire %.1f, rata %.2f" % [mid.max_scrape, mid.rate])
	(mid.car as Car).queue_free()
	await get_tree().physics_frame
	_check(mid.emit_frames >= 5, "emite si la viteza medie")
	_check(float(mid.rate) < float(fast.rate) - 0.1, "rata scade cu viteza (%.2f < %.2f)" % [mid.rate, fast.rate])

	var slow := await _scrape_run(120.0, 12.0, 2.5)
	print("  lent: viteza max de razuire %.1f, emisie %d cadre" % [slow.max_scrape, slow.emit_frames])
	_check(slow.max_scrape < 4.0, "(control) scenariul lent chiar razuieste sub prag")
	_check(slow.emit_frames == 0, "sub pragul de viteza nu sar scantei")
	(slow.car as Car).queue_free()
	await get_tree().physics_frame


func _test_wall_burst() -> void:
	print("")
	print("-- 2. rafala la izbitura de perete (prag 6 m/s) --")
	var car := _spawn(Vector3(150, 0.7, 0))
	await _settle([car])
	var s: CPUParticles3D = car._sparks
	s.emitting = false
	car.impact.emit(car, &"wall", 4.0, Vector3.BACK, Vector3(150, 1.0, -1.0), null)
	_check(not s.emitting, "izbitura de 4 m/s: fara rafala")
	car.impact.emit(car, &"wall", 9.0, Vector3.BACK, Vector3(150, 1.0, -1.0), null)
	var near: float = s.global_position.distance_to(Vector3(150, 1.1, -1.0))
	print("  9 m/s: emite=%s, %d scantei, emitator la %.2f m de punctul de impact"
		% [s.emitting, s.amount, near])
	_check(s.emitting and s.amount >= Car.SPARKS_MIN, "izbitura de 9 m/s: rafala")
	_check(near < 0.3, "rafala pleaca din punctul de impact")
	car.queue_free()
	await get_tree().physics_frame
	# Izbitura reala in perete.
	var real := _spawn(Vector3(-150, 0.7, -8))
	await _settle([real])
	real.linear_velocity = Vector3(0, 0, -14)
	var burst_frames := 0
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
		if (real._sparks as CPUParticles3D).emitting:
			burst_frames += 1
	print("  izbitura reala la 14 m/s: rafala activa %d cadre, %d scantei"
		% [burst_frames, real._sparks.amount])
	_check(burst_frames >= 1, "izbitura reala in perete aprinde rafala")
	real.queue_free()
	await get_tree().physics_frame


func _top_lean_x(car: Car) -> float:
	var up: Vector3 = car._visual.basis * Vector3.UP
	return up.x


func _test_car_rub() -> void:
	print("")
	print("-- 3. frecare intre masini: A (12 m/s) langa B (4 m/s), apasate una pe alta --")
	var a := _spawn(Vector3(220, 0.7, 40))
	var b := _spawn(Vector3(222.1, 0.7, 40))
	await _settle([a, b])
	a.linear_velocity = Vector3(1.5, 0, -14)
	b.linear_velocity = Vector3(0, 0, -2)
	var both := 0
	var only_one := 0
	var none_while_rub := 0
	var rub_frames := 0
	var max_rub := 0.0
	var max_lean_a := 0.0
	var max_lean_b := 0.0
	var lean_a_dir := 0.0
	var lean_b_dir := 0.0
	for f in int(1.0 / STEP):
		# Apasare sustinuta: A ramane lipit de B cat timp ar scapa.
		if f < 50:
			a.apply_central_force(Vector3(18.0 * a.mass, 0, 0))
		await get_tree().physics_frame
		if a.rub_car == b and a.rub_speed > a.rub_min_speed:
			rub_frames += 1
			max_rub = maxf(max_rub, a.rub_speed)
			var ea: bool = a._scrape_sparks.emitting
			var eb: bool = b._scrape_sparks.emitting
			if ea and eb:
				both += 1
			elif ea or eb:
				only_one += 1
			else:
				none_while_rub += 1
			if absf(_top_lean_x(a)) > max_lean_a:
				max_lean_a = absf(_top_lean_x(a))
				lean_a_dir = _top_lean_x(a)
			if absf(_top_lean_x(b)) > max_lean_b:
				max_lean_b = absf(_top_lean_x(b))
				lean_b_dir = _top_lean_x(b)
	print("  frecare %d cadre, viteza max %.1f; emit: una=%d amandoua=%d niciuna=%d"
		% [rub_frames, max_rub, only_one, both, none_while_rub])
	print("  aplecare A %.3f (varful pe x %+.3f), B %.3f (varful pe x %+.3f)"
		% [rad_to_deg(asin(clampf(max_lean_a, 0.0, 1.0))), lean_a_dir,
			rad_to_deg(asin(clampf(max_lean_b, 0.0, 1.0))), lean_b_dir])
	_check(rub_frames >= 10, "contact de frecare sustinut (>= 10 cadre cu rub_speed > prag)")
	_check(only_one >= rub_frames - 2 and both == 0, "EXACT o masina din pereche scanteiaza (fara dublura)")
	_check(lean_a_dir < 0.0 and lean_b_dir > 0.0, "corpurile se apleaca una de alta (A spre -x, B spre +x)")
	_check(max_lean_a > sin(deg_to_rad(1.5)) and max_lean_b > sin(deg_to_rad(1.5)),
		"aplecarea e vizibila (> 1.5 grade)")
	# Dupa separare: se opresc in 0.2 s.
	a.linear_velocity = Vector3(-8, 0, -12)
	b.linear_velocity = Vector3(8, 0, -4)
	var stop_frame := -1
	for f in int(0.6 / STEP):
		await get_tree().physics_frame
		if stop_frame < 0 and not a._scrape_sparks.emitting and not b._scrape_sparks.emitting:
			stop_frame = f
	print("  oprit dupa %d cadre (%.3f s)" % [stop_frame, stop_frame * STEP])
	_check(stop_frame >= 0 and stop_frame * STEP <= 0.2, "scanteile de frecare se opresc in 0.2 s dupa separare")
	# Frecare lenta: sub prag nu scanteiaza.
	a.queue_free()
	b.queue_free()
	await get_tree().physics_frame
	var c := _spawn(Vector3(260, 0.7, 40))
	var d := _spawn(Vector3(262.1, 0.7, 40))
	await _settle([c, d])
	c.linear_velocity = Vector3(1.0, 0, -4.0)
	d.linear_velocity = Vector3(0, 0, -3.2)
	var slow_emit := 0
	var slow_rub := 0
	for f in int(0.5 / STEP):
		if f < 20:
			c.apply_central_force(Vector3(40.0 * c.mass, 0, 0))
		await get_tree().physics_frame
		if c.rub_car == d:
			slow_rub += 1
		if c._scrape_sparks.emitting or d._scrape_sparks.emitting:
			slow_emit += 1
	print("  frecare lenta (0.8 m/s relativ): %d cadre de contact, %d cu scantei" % [slow_rub, slow_emit])
	_check(slow_emit == 0, "frecare sub 2 m/s: fara scantei")
	c.queue_free()
	d.queue_free()
	await get_tree().physics_frame
