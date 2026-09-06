extends Node
## Sondele tehnice de dinaintea traseului Serengeti (brief §7 pasul 1).
##
## Trei mecanici noi, fiecare cu contractul ei din brief §3, pe un sol plat:
##   A. RAUL DE GNU (HerdHazard)
##      1. fereastra: culoarul e liber pe toate benzile cel putin o data pe
##         perioada, si o masina care pleaca la deschidere trece FARA contact;
##      2. pulsul des: sportul (0.9) care intra in turma e deviat lateral si
##         franat; autobuzul (2.6) e deviat si franat MAI PUTIN (identitatea
##         prin masa), si in ambele cazuri animale se rostogolesc;
##      3. siguranta: masina nu e ridicata in aer si nu e ingropata de
##         corpurile cinematice (y ramane in [0.2, 2.0]);
##      4. costul: tick-ul turmei sub 1500 us cu 2 masini pe camp.
##   B. HIPOPOTAMUL (HippoHazard): sus, spinarea arunca masina (airtime);
##      scufundat, trecerea e plata.
##   C. VARTEJUL (DustDevilHazard): trecerea roteste masina cu ~180° fara
##      s-o rastoarne, si o lasa pe sol.
##
## Ruleaza CA SCENA (are nevoie de autoload-uri prin Car):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSerengeti.tscn

const STEP: float = 1.0 / 60.0
const HerdScript := preload("res://scenes/hazards/herd_hazard.gd")
const HippoScript := preload("res://scenes/hazards/hippo_hazard.gd")
const DevilScript := preload("res://scenes/hazards/dust_devil_hazard.gd")

var _failed: bool = false
## Scris de lambda: MEMBRU, nu local (lambdele captureaza prin valoare).
var _spun: bool = false


class ScriptDriver:
	extends CarController
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
	print("=== Serengeti: sondele tehnice ===")
	await _test_herd()
	await _test_hippo()
	await _test_devil()
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


## Masina cu botul spre -Z, tinuta la `speed` de guvernator (throttle 1 +
## plafon), ca sa masuram efectul hazardului, nu al acceleratiei.
func _spawn(pos: Vector3, factor: float, speed: float) -> Car:
	var car := Car.new()
	car.mass_factor = factor
	add_child(car)
	car.global_position = pos
	car.race_active = true
	var drv := ScriptDriver.new()
	drv.throttle = 1.0
	car.set_controller(drv)
	car.speed_limit_factor = speed / car.max_speed
	car.linear_velocity = Vector3(0, 0, -speed)
	return car


func _settle(cars: Array[Car]) -> void:
	for _f in int(0.5 / STEP):
		await get_tree().physics_frame
	for car in cars:
		car.linear_velocity = Vector3.ZERO


func _wait(seconds: float) -> void:
	for _f in int(seconds / STEP):
		await get_tree().physics_frame


# ------------------------------------------------------------------ A. turma

func _test_herd() -> void:
	print("")
	print("-- A. raul de gnu --")
	var herd: HerdHazard = HerdScript.new()
	herd.flow_dir = Vector3(1, 0, 0)
	herd.road_dir = Vector3(0, 0, 1)
	add_child(herd)
	herd.global_position = Vector3.ZERO
	await get_tree().physics_frame
	print("  animale: %d, perioada %.1f s, bucla %.0f m" % [herd.count(), herd.period(),
		herd.period() * herd.speed])

	# 1. fereastra exista si e destul de lunga
	var open_total := 0.0
	var samples := int(herd.period() / 0.05)
	for k in samples:
		if herd.strip_free_at(0, k * 0.05) and herd.strip_free_at(1, k * 0.05) \
				and herd.strip_free_at(2, k * 0.05):
			open_total += 0.05
	print("  fereastra libera pe toate benzile: %.1f s din %.1f" % [open_total, herd.period()])
	_check(open_total >= 3.0, "fereastra de cel putin 3 s pe perioada")

	# 2. o masina care pleaca la deschiderea ferestrei trece fara contact
	var t_open := herd.seconds_to_window()
	await _wait(t_open)
	var run := await _cross(herd, 0.9, 18.0)
	print("  fereastra: lovituri %d, deviere %.2f m, viteza %.1f -> %.1f m/s"
		% [run.hits, run.lateral, run.v_in, run.v_out])
	_check(run.hits == 0, "prin fereastra: zero contact")
	_check(absf(run.lateral) < 1.0, "prin fereastra: fara deviere")

	# 3. pulsul des: sport apoi autobuz
	var t_dense := herd.seconds_to_dense()
	await _wait(t_dense)
	var sport := await _cross(herd, 0.9, 18.0)
	print("  sport in puls: lovituri %d, deviere %.2f m, viteza %.1f -> min %.1f in culoar, traversare %.2f s (liber %.2f), y in [%.2f, %.2f]"
		% [sport.hits, sport.lateral, sport.v_in, sport.v_min, sport.t_cross, run.t_cross,
			sport.y_min, sport.y_max])
	_check(sport.hits >= 1, "sportul loveste animale in puls")
	_check(absf(sport.lateral) >= 1.5, "sportul e deviat lateral (>= 1.5 m)")
	_check(sport.v_min < sport.v_in * 0.7, "sportul e franat in culoar (> 30%)")
	_check(sport.t_cross > run.t_cross * 1.25, "sportul pierde timp in puls (> 25%)")
	_check(sport.y_min > -0.3 and sport.y_max < 1.5, "sportul nu e ingropat/aruncat")
	# pana la urmatorul puls
	await _wait(herd.seconds_to_dense())
	var bus := await _cross(herd, 2.6, 18.0)
	print("  autobuz in puls: lovituri %d, deviere %.2f m, viteza %.1f -> min %.1f in culoar, traversare %.2f s, y in [%.2f, %.2f]"
		% [bus.hits, bus.lateral, bus.v_in, bus.v_min, bus.t_cross, bus.y_min, bus.y_max])
	_check(bus.hits >= 1, "autobuzul loveste animale in puls")
	_check(absf(bus.lateral) < absf(sport.lateral),
		"autobuzul e deviat mai putin decat sportul (identitatea prin masa)")
	_check(bus.v_min > sport.v_min and bus.t_cross < sport.t_cross,
		"autobuzul pastreaza mai multa viteza decat sportul")
	_check(bus.y_min > -0.3 and bus.y_max < 1.5, "autobuzul nu e ingropat/aruncat")
	_check(herd.tumbles >= 2, "animalele lovite se rostogolesc (%d)" % herd.tumbles)

	# 4. costul cu doua masini parcate langa culoar
	var a := _spawn(Vector3(-4, 0.7, 3), 0.9, 0.0)
	var b := _spawn(Vector3(4, 0.7, -3), 2.6, 0.0)
	await _settle([a, b])
	var total := 0
	var n := int(3.0 / STEP)
	var worst := 0
	for _f in n:
		await get_tree().physics_frame
		total += herd.last_tick_usec
		worst = maxi(worst, herd.last_tick_usec)
	print("  tick turma: mediu %d us, varf %d us (%d animale, %d corpuri)"
		% [total / n, worst, herd.count(), herd.body_pool])
	_check(total / n < 1500, "tick-ul turmei sub 1500 us in medie")
	a.queue_free()
	b.queue_free()
	herd.queue_free()
	await get_tree().physics_frame


## O masina pleaca de la z = +40 spre -Z prin culoar, pana la z = -40.
func _cross(herd: HerdHazard, factor: float, speed: float) -> Dictionary:
	var car := _spawn(Vector3(0, 0.7, 40), factor, speed)
	herd.cars = [car]
	var hits0 := herd.hits
	var y_min := INF
	var y_max := -INF
	var v_in := 0.0
	var v_out := 0.0
	var v_min := INF
	var in_frames := 0
	var frames := 0
	while car.global_position.z > -40.0 and frames < int(12.0 / STEP):
		await get_tree().physics_frame
		frames += 1
		var z := car.global_position.z
		if z < 20.0 and z > 14.0 and v_in == 0.0:
			v_in = car.horizontal_speed()
		if absf(z) < 16.0:
			y_min = minf(y_min, car.global_position.y)
			y_max = maxf(y_max, car.global_position.y)
		if absf(z) < 14.0:
			v_min = minf(v_min, car.horizontal_speed())
			in_frames += 1
		if z < -20.0 and v_out == 0.0:
			v_out = car.horizontal_speed()
	if v_out == 0.0:
		v_out = car.horizontal_speed()
	var lateral := car.global_position.x
	herd.cars = []
	car.queue_free()
	await get_tree().physics_frame
	return {"hits": herd.hits - hits0, "lateral": lateral, "v_in": v_in,
		"v_out": v_out, "v_min": v_min, "t_cross": in_frames * STEP,
		"y_min": y_min, "y_max": y_max}


# ------------------------------------------------------------------ B. hipopotam

func _test_hippo() -> void:
	print("")
	print("-- B. hipopotamul din vad --")
	var hippo: HippoHazard = HippoScript.new()
	add_child(hippo)
	hippo.global_position = Vector3(0, 0, 0)
	await get_tree().physics_frame

	# scufundat: trecere plata (masina ajunge dupa 2 s intr-o fereastra de calm de 4 s)
	var flat := await _drive_over(hippo, 15.0, hippo.seconds_to_calm(4.0))
	print("  scufundat: y max %.2f, aer %d cadre" % [flat.y_max, flat.air])
	_check(flat.y_max < 0.5 and flat.air <= 2, "scufundat: trecerea e plata")

	# sus: masina ajunge la el exact cand e ridicat
	var t_up := hippo.seconds_to_up()
	var travel := 30.0 / 15.0 # 30 m la 15 m/s
	var up := await _drive_over(hippo, 15.0, maxf(t_up - travel + 0.1, 0.0))
	print("  sus: y max %.2f, aer %d cadre, aterizat %s" % [up.y_max, up.air, str(up.landed)])
	_check(up.y_max > 1.0, "sus: masina e ridicata peste spinare (y max > 1.0 m)")
	_check(up.air >= 10, "sus: airtime real (>= 10 cadre)")
	_check(up.landed, "sus: masina aterizeaza pe roti")
	hippo.queue_free()
	await get_tree().physics_frame


func _drive_over(hippo: HippoHazard, speed: float, wait_first: float) -> Dictionary:
	await _wait(wait_first)
	var car := _spawn(Vector3(0, 0.7, 30), 0.9, speed)
	var y_max := -INF
	var air := 0
	var frames := 0
	var hippo_y_at_pass := 0.0
	while car.global_position.z > -30.0 and frames < int(8.0 / STEP):
		await get_tree().physics_frame
		frames += 1
		if absf(car.global_position.z) < 12.0:
			y_max = maxf(y_max, car.global_position.y)
			if not car.is_on_floor():
				air += 1
		if absf(car.global_position.z) < 2.5:
			hippo_y_at_pass = hippo.global_position.y
	print("    (hipopotamul la y = %.2f cand masina trece)" % hippo_y_at_pass)
	var landed := car.is_on_floor() and car.global_transform.basis.y.y > 0.8
	car.queue_free()
	await get_tree().physics_frame
	return {"y_max": y_max, "air": air, "landed": landed}


# ------------------------------------------------------------------ C. vartej

func _test_devil() -> void:
	print("")
	print("-- C. vartejul de praf --")
	var devil: DustDevilHazard = DevilScript.new()
	devil.amplitude = Vector2.ZERO # sta pe loc pentru masuratoare
	add_child(devil)
	devil.global_position = Vector3.ZERO
	await get_tree().physics_frame
	var car := _spawn(Vector3(0, 0.7, 30), 0.9, 20.0)
	var heading0 := -car.global_transform.basis.z
	_spun = false
	devil.spun.connect(func(_c: Car) -> void: _spun = true)
	var frames := 0
	var min_up := 1.0
	var t_after := 0.0
	var heading_after := heading0
	while frames < int(4.0 / STEP):
		await get_tree().physics_frame
		frames += 1
		min_up = minf(min_up, car.global_transform.basis.y.y)
		if _spun:
			t_after += STEP
			if t_after >= 1.0 and heading_after == heading0:
				heading_after = -car.global_transform.basis.z
	var turned := rad_to_deg(heading0.signed_angle_to(heading_after, Vector3.UP))
	print("  rotit: %s, unghi la 1 s dupa: %.0f°, up minim %.2f, pe sol %s, viteza %.1f m/s"
		% [str(_spun), turned, min_up, str(car.is_on_floor()), car.horizontal_speed()])
	_check(_spun, "vartejul a prins masina")
	_check(absf(absf(turned) - 180.0) <= 40.0, "rotire de ~180° (± 40)")
	_check(min_up > 0.7, "masina nu se rastoarna")
	_check(car.is_on_floor(), "masina ramane pe sol")
	car.queue_free()
	devil.queue_free()
	await get_tree().physics_frame
