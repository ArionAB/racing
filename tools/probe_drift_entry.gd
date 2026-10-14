extends Node
## Intrarea si iesirea din drift, la trei viteze: cat de BRUSC se schimba
## rotatia cand tragi / eliberezi frana de mana, si cata viteza pastrezi.
##
## Scenariul e cel de la volan pe tastatura: virajul e digital (±1), tii volanul
## plin 0.5 s, apoi tragi frana de mana 1.5 s, apoi o eliberezi cu volanul tot
## plin. Gazul ramane apasat tot timpul (pe touch e auto-accelerate).
##
## Contractele (oct 2026, „frana de mana vireaza prea brusc"):
##   1. intrarea si iesirea nu sar: rotatia (ω) se schimba cu cel mult
##      MAX_YAW_JUMP intr-un tick. Inainte de rampa: 1.3-1.5 rad/s intr-un
##      singur cadru la intrare, 1.1 la iesire.
##   2. driftul rapid pastreaza viteza: intrat la 85% din max_speed, dupa 0.5 s
##      ai inca MIN_KEEP din viteza de intrare. Inainte: 62% (29 -> 18 m/s) —
##      acelasi pivot strans la orice viteza, care franeaza ca un zid.
## Sabotaj (trebuie sa PICE): `-- --ramp-in=0.0001 --ramp-out=0.0001` pica 1,
## `-- --yaw-top=1 --grip-top=2` pica 2 (amandoua = comportamentul vechi).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDriftEntry.tscn
## Suprascrieri pentru tunare (dupa `--`): --ramp-in= --ramp-out= --yaw-top=
## --grip-top= --grip= ; --car=<nume> incarca scenes/cars/data/<nume>.tres.

const STEP: float = 1.0 / 60.0
## Viteze de intrare ca fractie din max_speed-ul masinii testate.
const SPEEDS: Array[float] = [0.45, 0.62, 0.85]
const SAMPLES: Array[float] = [0.1, 0.2, 0.3, 0.5, 1.0]
const HOLD: float = 1.5
const MAX_YAW_JUMP: float = 0.4
const MIN_KEEP: float = 0.75

var _overrides: Dictionary = {}
var _car_data: String = ""
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
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		if kv[0] == "car":
			_car_data = kv[1]
		else:
			_overrides[kv[0]] = float(kv[1])
	if not _overrides.is_empty():
		print("suprascrieri: ", _overrides)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000, 1, 2000)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame

	print("")
	print("=== Intrarea in drift (volan plin, gaz plin) %s ===" % _car_data)
	for v in SPEEDS:
		await _run(v)
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _slip_angle_deg(car: Car) -> float:
	var hvel := Vector3(car.linear_velocity.x, 0.0, car.linear_velocity.z)
	if hvel.length() < 3.0:
		return 0.0
	var fwd := -car.global_transform.basis.z
	var fwd_h := Vector3(fwd.x, 0.0, fwd.z).normalized()
	var right_h := fwd_h.cross(Vector3.UP)
	return rad_to_deg(atan2(hvel.dot(right_h), hvel.dot(fwd_h)))


func _run(speed_frac: float) -> void:
	var car := Car.new()
	add_child(car)
	if _car_data != "":
		car.apply_data(load("res://scenes/cars/data/%s.tres" % _car_data))
	var target_speed := car.max_speed * speed_frac
	car.global_position = Vector3(0, 0.7, 0)
	var props := {"ramp-in": "drift_ramp_in", "ramp-out": "drift_ramp_out",
		"yaw-top": "drift_yaw_at_top", "grip-top": "drift_grip_at_top",
		"grip": "drift_grip"}
	for k: String in _overrides:
		car.set(props[k], _overrides[k])
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	car.race_active = true
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame

	# Prinde viteza in linie dreapta.
	drv.throttle = 1.0
	var guard := 0
	while car.horizontal_speed() < target_speed and guard < 600:
		await get_tree().physics_frame
		guard += 1

	# Volan plin 0.5 s, fara frana de mana: virajul normal, reperul. Treapta de
	# volan (tasta) nu e treaba driftului, deci se consuma inainte de masurare.
	drv.steer = 1.0
	for _f in int(0.5 / STEP):
		await get_tree().physics_frame
	var yaw_normal := car.angular_velocity.y
	var v_in := car.horizontal_speed()

	# Frana de mana trasa.
	drv.drift = true
	var prev_yaw := car.angular_velocity.y
	var max_jump_in := 0.0
	var v_half := 0.0
	var t := 0.0
	var line := ""
	var sample_i := 0
	for _f in int(HOLD / STEP):
		await get_tree().physics_frame
		t += STEP
		var yaw := car.angular_velocity.y
		max_jump_in = maxf(max_jump_in, absf(yaw - prev_yaw))
		prev_yaw = yaw
		if sample_i < SAMPLES.size() and t >= SAMPLES[sample_i] - 0.001:
			line += "\n    t=%.1f ω=%.2f slip=%2.0f° v=%4.1f" % [t, yaw,
				absf(_slip_angle_deg(car)), car.horizontal_speed()]
			if is_equal_approx(SAMPLES[sample_i], 0.5):
				v_half = car.horizontal_speed()
			sample_i += 1
	var v_end := car.horizontal_speed()

	# Frana de mana eliberata, volanul inca plin.
	drv.drift = false
	var max_jump_out := 0.0
	prev_yaw = car.angular_velocity.y
	for _f in int(0.6 / STEP):
		await get_tree().physics_frame
		var yaw := car.angular_velocity.y
		max_jump_out = maxf(max_jump_out, absf(yaw - prev_yaw))
		prev_yaw = yaw

	print("")
	print("-- intrare la %.1f m/s = %.0f%% din max (la final %.1f m/s) --"
		% [v_in, speed_frac * 100.0, v_end])
	print("  viraj normal ω=%.2f rad/s%s" % [yaw_normal, line])
	_check(max_jump_in <= MAX_YAW_JUMP and max_jump_out <= MAX_YAW_JUMP,
		"fara treapta: salt max de ω pe tick %.2f la intrare, %.2f la iesire (<= %.1f)"
		% [max_jump_in, max_jump_out, MAX_YAW_JUMP])
	if speed_frac >= 0.8:
		_check(v_half >= v_in * MIN_KEEP,
			"driftul rapid pastreaza viteza: %.0f%% dupa 0.5 s (>= %.0f%%)"
			% [v_half / v_in * 100.0, MIN_KEEP * 100.0])
	car.queue_free()
	await get_tree().physics_frame
