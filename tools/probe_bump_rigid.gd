extends Node
## Imbrancelile cu masa pe fizica intreaga (#257).
##
## Solverul imparte impulsul dupa raportul maselor din constructie; sonda
## verifica exact REGULILE arcade puse deasupra:
##   1. identitatea prin masa: autobuz (2.6) in sport (0.9) la ~12 m/s
##      inchidere -> raportul delta-v = raportul maselor ± 15%;
##   2. plafonul de violenta: la o inchidere absurda (30 m/s), victima nu
##      incaseaza peste bump_max_dv (+ o marja de un cadru);
##   3. impingerea sustinuta e impingere, nu catapulta: viteza victimei nu
##      trece de a impingatorului, fara varfuri de impuls pe cadru;
##   4. lovitura in colt ROTESTE victima, dar plafonat (bump_yaw_max);
##   5. atingerea laterala sub prag e frecare: fara semnal, fara ghiont.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBumpRigid.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false
## Contorizate de lambda-uri: MEMBRI, nu locale (capturare prin valoare).
var _signals: int = 0
var _last_dv: float = 0.0


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
	print("=== Imbranceli cu masa pe RigidCar ===")
	await _test_mass_ratio()
	await _test_cap()
	await _test_push()
	await _test_corner()
	await _test_side_touch()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _spawn(pos: Vector3, factor: float, with_driver: bool = false) -> RigidCar:
	var car := RigidCar.new()
	car.mass_factor = factor # inainte de add_child: _ready citeste masa
	add_child(car)
	car.global_position = pos
	if with_driver:
		car.set_controller(ScriptDriver.new())
	car.bumped.connect(func(_c: RigidCar, _o: RigidCar, dv: float) -> void:
		_signals += 1
		_last_dv = dv)
	return car


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _settle(cars: Array[RigidCar]) -> void:
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	for car in cars:
		car.linear_velocity = Vector3.ZERO


## Cel mai mare delta-v pe UN cadru — impulsul de coliziune se aplica
## intr-un singur pas de solver, deci asta e "lovitura".
func _watch_impact(victim: RigidCar, attacker: RigidCar, seconds: float
		) -> Dictionary:
	var v_prev := victim.linear_velocity
	var a_prev := attacker.linear_velocity
	var v_max_dv := 0.0
	var a_max_dv := 0.0
	var closing := 0.0
	for _f in int(seconds / STEP):
		await get_tree().physics_frame
		var v_dv := (victim.linear_velocity - v_prev).length()
		var a_dv := (attacker.linear_velocity - a_prev).length()
		if v_dv > v_max_dv:
			v_max_dv = v_dv
			# Inchiderea, citita chiar inainte de lovitura maxima.
			closing = (a_prev - v_prev).length()
		a_max_dv = maxf(a_max_dv, a_dv)
		v_prev = victim.linear_velocity
		a_prev = attacker.linear_velocity
	return {"victim_dv": v_max_dv, "attacker_dv": a_max_dv, "closing": closing}


# ------------------------------------------------------------------ testele

func _test_mass_ratio() -> void:
	print("")
	print("-- 1. identitatea prin masa (autobuz 2.6 -> sport 0.9) --")
	_signals = 0
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(0, 0.7, 8), 2.6)
	await _settle([sport, bus])
	bus.linear_velocity = Vector3(0, 0, -13)
	var r := await _watch_impact(sport, bus, 1.5)
	var ratio: float = float(r.victim_dv) / maxf(float(r.attacker_dv), 0.001)
	var target := 2.6 / 0.9
	print("  inchidere %.1f m/s: sportul incaseaza %.1f, autobuzul %.1f -> raport %.2f (tinta %.2f)"
		% [float(r.closing), float(r.victim_dv), float(r.attacker_dv),
			ratio, target])
	print("  semnale bumped: %d, ultimul delta-v raportat %.1f" % [_signals, _last_dv])
	_check(ratio >= target * 0.85 and ratio <= target * 1.15,
		"raportul delta-v = raportul maselor (± 15%)")
	_check(_signals >= 1, "semnalul bumped se emite la izbitura")
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame


func _test_cap() -> void:
	print("")
	print("-- 2. plafonul de violenta (inchidere 30 m/s) --")
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(0, 0.7, 14), 2.6)
	await _settle([sport, bus])
	bus.linear_velocity = Vector3(0, 0, -30)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	# Dupa plafonare (aplicata la tick-ul urmator loviturii), viteza ramasa a
	# victimei nu poate depasi plafonul plus zgomotul unui cadru.
	var speed := sport.horizontal_speed()
	print("  viteza sportului dupa izbitura: %.1f m/s (plafon %.1f)"
		% [speed, sport.bump_max_dv])
	_check(speed <= sport.bump_max_dv + 1.0,
		"victima nu incaseaza peste bump_max_dv")
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame


func _test_push() -> void:
	print("")
	print("-- 3. impingere sustinuta 3 s (bara-n bara) --")
	_signals = 0
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(0, 0.7, 4.2), 2.6, true)
	await _settle([sport, bus])
	(bus.controller as ScriptDriver).throttle = 0.6
	var sport_max_frame_dv := 0.0
	var prev := sport.linear_velocity
	for _f in int(3.0 / STEP):
		await get_tree().physics_frame
		sport_max_frame_dv = maxf(sport_max_frame_dv,
			(sport.linear_velocity - prev).length())
		prev = sport.linear_velocity
	var sport_speed := sport.horizontal_speed()
	var bus_speed := bus.horizontal_speed()
	print("  dupa 3 s: sport %.1f m/s, autobuz %.1f m/s, varf pe cadru %.1f, semnale %d"
		% [sport_speed, bus_speed, sport_max_frame_dv, _signals])
	_check(sport_speed <= bus_speed + 2.0,
		"impins, nu catapultat (viteza victimei <= a impingatorului)")
	_check(sport_max_frame_dv <= 6.0,
		"fara varfuri de impuls in contactul sustinut")
	_check(_signals <= 3, "semnalul nu se acumuleaza in contact sustinut")
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame


func _test_corner() -> void:
	print("")
	print("-- 4. lovitura in colt roteste, dar plafonat --")
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(1.3, 0.7, 8), 2.6)
	await _settle([sport, bus])
	var yaw_before := sport.rotation.y
	bus.linear_velocity = Vector3(0, 0, -13)
	# Viteza de rotatie a victimei, masurata DUPA ce plafonul din
	# _process_bumps a apucat sa ruleze (nu in cadrul brut al solverului).
	var max_yaw_rate := 0.0
	var contact_seen := false
	var frames_after := 0
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
		if not contact_seen and sport.horizontal_speed() > 0.5:
			contact_seen = true
		if contact_seen:
			frames_after += 1
			if frames_after >= 3:
				max_yaw_rate = maxf(max_yaw_rate,
					absf(sport.angular_velocity.y))
	var turned := absf(wrapf(sport.rotation.y - yaw_before, -PI, PI))
	print("  rotatie totala %.0f°, viteza de rotatie max %.2f rad/s (plafon %.1f)"
		% [rad_to_deg(turned), max_yaw_rate, sport.bump_yaw_max])
	_check(turned > deg_to_rad(5.0), "lovitura excentrica chiar roteste (> 5°)")
	_check(max_yaw_rate <= sport.bump_yaw_max + 0.4,
		"rotatia ramane plafonata (te sucesti, nu piruete)")
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame


func _test_side_touch() -> void:
	print("")
	print("-- 5. atingere laterala sub prag: frecare, nu ghiont --")
	_signals = 0
	var sport := _spawn(Vector3(0, 0.7, 0), 0.9)
	var bus := _spawn(Vector3(2.2, 0.7, 0), 2.6)
	await _settle([sport, bus])
	sport.linear_velocity = Vector3(1.2, 0, 0) # aluneca usor spre autobuz
	var bus_max_dv := 0.0
	var prev := bus.linear_velocity
	for _f in int(2.0 / STEP):
		await get_tree().physics_frame
		bus_max_dv = maxf(bus_max_dv, (bus.linear_velocity - prev).length())
		prev = bus.linear_velocity
	print("  ghiontul incasat de autobuz: %.2f m/s, semnale bumped: %d"
		% [bus_max_dv, _signals])
	_check(bus_max_dv < 1.5, "atingerea nu impinge (delta-v < 1.5 m/s)")
	_check(_signals == 0, "fara semnal sub pragul de inchidere")
	sport.queue_free()
	bus.queue_free()
	await get_tree().physics_frame
