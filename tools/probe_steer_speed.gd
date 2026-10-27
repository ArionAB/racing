extends Node
## Volan care se strange cu viteza + netezirea volanului digital
## (docs/feel_checklist.md, `steering-speed`).
##
## Contractele:
##   1. Viteza de rotatie (omega) la volan plin, normalizata la rampa de viteza
##      (omega / (steer_speed * speed_frac)) = "cat din volan a ramas":
##      >= 0.95 la 30% si 50% din max_speed, 0.60-0.70 la 100%, descrescator.
##   2. Driftul e scutit: cu frana de mana trasa la 85% din max_speed, omega
##      dupa 0.5 s si 1.0 s difera cu cel mult 8% fata de aceeasi manevra cu
##      strangerea oprita (steer_taper_at_top = 1.0).
##   3. PlayerController: o apasare ajunge la 90% in 0.07-0.13 s; eliberarea
##      coboara la 0 in <= 0.10 s; la inversare iesirea trece prin zero in
##      primul tick (niciun cadru cu semnul vechi) si nu sare (<= 0.25/tick);
##      o atingere de 0.05 s nu atinge volanul plin.
## Sabotaj (trebuie sa PICE): `-- --off` opreste strangerea si netezirea.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSteerSpeed.tscn

const STEP: float = 1.0 / 60.0
const PlayerCtl := preload("res://scenes/cars/player_controller.gd")

var _failed: bool = false
var _off: bool = false


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
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2000, 1, 2000)
	cs.shape = sh
	ground.add_child(cs)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	print("")
	print("=== Volan dependent de viteza + netezire ===")
	if _off:
		print("  (SABOTAJ: strangere si netezire oprite)")
	await _test_lock_vs_speed()
	await _test_drift_exempt()
	await _test_player_smoothing()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(taper: float = 0.65) -> Car:
	var car := Car.new()
	car.steer_taper_at_top = 1.0 if _off else taper
	add_child(car)
	car.global_position = Vector3(0, 0.7, 0)
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	car.race_active = true
	return car


func _settle(car: Car) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO


## omega la volan plin, viteza FIXATA la fractia data (reimpusa in fiecare tick).
func _yaw_at(car: Car, frac: float) -> float:
	var drv := car.controller as ScriptDriver
	drv.steer = 1.0
	drv.throttle = 1.0
	var sum := 0.0
	var n := 0
	for f in 12:
		var fwd := -car.global_transform.basis.z
		car.linear_velocity = Vector3(fwd.x, 0.0, fwd.z).normalized() \
			* car.max_speed * frac
		await get_tree().physics_frame
		if f >= 4:
			sum += car.angular_velocity.y
			n += 1
	drv.steer = 0.0
	return sum / float(n)


func _test_lock_vs_speed() -> void:
	print("")
	print("-- 1. cat din volan ramane (omega normalizat) --")
	var car := _spawn()
	await _settle(car)
	var fracs: Array[float] = [0.3, 0.5, 0.65, 0.8, 1.0]
	var lock: Array[float] = []
	# Referinta: omega/speed_frac la 50% din max (inceputul strangerii). Valoarea
	# MASURATA e ~84% din cea scrisa de Car (solverul amortizeaza dupa), deci
	# normalizam la masuratoare, nu la steer_speed.
	var ref := 0.0
	for fr in fracs:
		# Doar X/Z/yaw: o teleportare pe verticala scoate roatele de pe sol.
		car.global_position = Vector3(0, car.global_position.y, 0)
		car.rotation = Vector3.ZERO
		var w := await _yaw_at(car, fr)
		var speed_frac := clampf(fr / 0.5, 0.0, 1.0)
		var per_frac := w / speed_frac
		if fr == 0.5:
			ref = per_frac
		lock.append(per_frac)
		print("  %3.0f%% din max: w=%.2f rad/s" % [fr * 100.0, w])
	for i in lock.size():
		lock[i] /= ref
		print("  %3.0f%% din max: volan ramas %.0f%% (fata de 50%%)" % [fracs[i] * 100.0, lock[i] * 100.0])
	_check(lock[0] >= 0.95 and lock[1] >= 0.95, "volan plin la 30% si 50% din max")
	_check(lock[4] >= 0.60 and lock[4] <= 0.70,
		"60-70%% din volan la viteza maxima (%.0f%%)" % (lock[4] * 100.0))
	var mono := true
	for i in range(1, lock.size()):
		if lock[i] > lock[i - 1] + 0.01:
			mono = false
	_check(mono, "strangerea creste monoton cu viteza")
	car.queue_free()
	await get_tree().physics_frame


func _drift_run(taper: float) -> Array[float]:
	var car := _spawn(taper)
	var drv := car.controller as ScriptDriver
	await _settle(car)
	drv.throttle = 1.0
	var guard := 0
	while car.horizontal_speed() < car.max_speed * 0.85 and guard < 900:
		await get_tree().physics_frame
		guard += 1
	drv.steer = 1.0
	for _f in 30:
		await get_tree().physics_frame
	drv.drift = true
	var out: Array[float] = []
	var t := 0.0
	for _f in 60:
		await get_tree().physics_frame
		t += STEP
		if absf(t - 0.5) < STEP * 0.5 or absf(t - 1.0) < STEP * 0.5:
			out.append(car.angular_velocity.y)
	car.queue_free()
	await get_tree().physics_frame
	return out


func _test_drift_exempt() -> void:
	print("")
	print("-- 2. driftul e scutit de strangere (85% din max) --")
	var with_taper := await _drift_run(0.65)
	var without := await _drift_run(1.0)
	if with_taper.size() < 2 or without.size() < 2:
		_check(false, "esantioane de drift colectate")
		return
	for i in 2:
		var d := absf(with_taper[i] - without[i]) / maxf(absf(without[i]), 0.1)
		print("  t=%.1f s: w cu strangere %.2f, fara %.2f (diferenta %.1f%%)"
			% [0.5 * (i + 1), with_taper[i], without[i], d * 100.0])
		_check(d <= 0.08, "w in drift neschimbat la t=%.1f s" % (0.5 * (i + 1)))
	_check(with_taper[0] > 1.5, "driftul inca vireaza (w > 1.5 rad/s)")


func _test_player_smoothing() -> void:
	print("")
	print("-- 3. PlayerController: netezirea volanului digital --")
	var pc: CarController = PlayerCtl.new()
	if _off:
		pc.set("steer_smoothing", false)
	add_child(pc)
	# Pe ecran -1 = stanga; in fizica stanga = +1 (vezi PlayerController).
	GameState.touch_steer = -1.0
	var t90 := -1.0
	var t := 0.0
	for _f in 30:
		pc.update(STEP)
		t += STEP
		if t90 < 0.0 and pc.get_steer() >= 0.9:
			t90 = t
	print("  apasare: 90%% in %.3f s (tinta 0.07-0.13)" % t90)
	_check(t90 >= 0.07 and t90 <= 0.13, "rampa de intrare ~0.1 s")

	GameState.touch_steer = 0.0
	var t0 := -1.0
	t = 0.0
	for _f in 30:
		pc.update(STEP)
		t += STEP
		if t0 < 0.0 and pc.get_steer() <= 0.001:
			t0 = t
	print("  eliberare: 0 in %.3f s (tinta 0.03-0.10)" % t0)
	_check(t0 >= 0.03 and t0 <= 0.10, "eliberarea e rapida, dar nu instantanee")

	# Inversare: de la +1 plin direct la -1.
	GameState.touch_steer = -1.0
	for _f in 30:
		pc.update(STEP)
	GameState.touch_steer = 1.0
	var prev := 0.0 # iesirea veche a fost +1: prima valoare noua trebuie sa fie mica
	var wrong := 0
	var max_jump := 0.0
	var first := 0.0
	for f in 12:
		pc.update(STEP)
		var s := pc.get_steer()
		if f == 0:
			first = s
		if s > 0.001:
			wrong += 1
		max_jump = maxf(max_jump, absf(s - prev))
		prev = s
	print("  inversare: primul tick %.2f, cadre cu semnul vechi %d, salt maxim %.2f"
		% [first, wrong, max_jump])
	_check(wrong == 0, "trece prin zero imediat (niciun cadru cu semnul vechi)")
	_check(max_jump <= 0.25, "fara salt peste 0.25 pe tick dupa inversare")

	# Atingere scurta.
	GameState.touch_steer = 0.0
	for _f in 30:
		pc.update(STEP)
	GameState.touch_steer = -1.0
	var peak := 0.0
	for _f in 3:
		pc.update(STEP)
		peak = maxf(peak, pc.get_steer())
	GameState.touch_steer = 0.0
	for _f in 30:
		pc.update(STEP)
		peak = maxf(peak, pc.get_steer())
	print("  atingere de 0.05 s: varf %.2f" % peak)
	_check(peak < 0.6, "o atingere scurta nu da volan plin")
	GameState.touch_steer = 0.0
	pc.queue_free()
