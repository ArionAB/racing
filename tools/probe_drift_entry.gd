extends Node
## Intrarea, tinerea si iesirea din drift, la trei viteze: cat de BRUSC se
## schimba rotatia, cat UNGHI face, cata VITEZA pastreaza si daca spatele se
## poate PRINDE cu contravolan.
##
## Scenariul e cel de la volan pe tastatura: virajul e digital (±1), tii
## volanul plin 0.5 s, tragi frana de mana si o tii: 1.0 s cu volanul spre
## interior, apoi 0.6 s cu CONTRAVOLAN plin (frana de mana tot trasa), apoi
## volanul inapoi spre interior si frana de mana eliberata. Gazul ramane
## apasat tot timpul (▲ + DRIFT = powerslide).
##
## Contractele:
##   1. (oct 2026, „frana de mana vireaza prea brusc") intrarea si iesirea nu
##      sar: rotatia (ω) se schimba cu cel mult MAX_YAW_JUMP intr-un tick.
##      Inainte de rampa: 1.3-1.5 rad/s intr-un singur cadru.
##   2. (oct 2026, „frana de mana doar franeaza") driftul rapid pastreaza
##      viteza: intrat la 85% din max_speed, dupa 1 s de drift ai inca
##      MIN_KEEP din viteza de intrare. Inainte de impulsul intors
##      (drift_momentum_keep): 85% la 0.5 s, dar 57% la 1 s — o frana, nu un
##      drift. Se masoara la 1 s, nu la 0.5: pe jumatate de secunda gazul
##      inca acopera pierderea si contractul nu ar prinde nimic.
##   3. (acelasi feedback) driftul rapid are UNGHI: la 85% din max_speed,
##      derapajul la 0.5 s e cel putin MIN_SLIP_FAST grade. Fara unghi, la
##      viteza de cursa frana de mana arata ca un viraj normal cu ruliu.
##   4. (acelasi feedback) contravolanul PRINDE, nu inverseaza: cu frana de
##      mana trasa si volanul plin in sens opus, ω nu schimba semnul (maparea
##      CTR: volanul alege raza, nu sensul) si scade cu INERTIE — la 0.1 s
##      dupa contravolan mai ai cel putin MIN_INERTIA_KEEP din ω de dinainte
##      (scris direct, ca pe asfalt, ar ramane ~20%).
## Sabotaj (fiecare trebuie sa PICE): `-- --ramp-in=0.0001 --ramp-out=0.0001`
## pica 1; `-- --keep=0` pica 2; `-- --arc-top=0.3` pica 3; `-- --inertia=0`
## pica 4 (inertia); `-- --arc-wide=-1.1` pica 4 (inversarea = maparea veche,
## in care contravolanul intorcea masina).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDriftEntry.tscn
## Suprascrieri pentru tunare (dupa `--`): --ramp-in= --ramp-out= --arc-tight=
## --arc-top= --arc-wide= --inertia= --keep= --grip-top= --grip= ;
## --car=<nume> incarca scenes/cars/data/<nume>.tres; --drift-throttle=<g>
## pune gazul la g cat tine frana de mana (1 = AI / ^+DRIFT, 0 = inertie,
## -1 = frana): asa s-a vazut ca DRIFT singur pe touch, mapat ca frana (#578),
## pastra 9% din viteza dupa 1 s, fata de 99% cu gaz.

const STEP: float = 1.0 / 60.0
## Viteze de intrare ca fractie din max_speed-ul masinii testate.
const SPEEDS: Array[float] = [0.45, 0.62, 0.85]
const SAMPLES: Array[float] = [0.1, 0.2, 0.3, 0.5, 1.0]
## Cat tii volanul spre interior cu frana de mana trasa, apoi cat tii
## contravolan (tot cu frana de mana trasa).
const HOLD_IN: float = 1.0
const HOLD_COUNTER: float = 0.6
const MAX_YAW_JUMP: float = 0.4
const MIN_KEEP: float = 0.85
const MIN_SLIP_FAST: float = 18.0
const MIN_INERTIA_KEEP: float = 0.5
## Toleranta de semn pentru „nu inverseaza": zgomotul solverului in jurul lui
## zero, nu o rotatie in sens opus.
const REVERSE_TOL: float = 0.05

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
	# Podea peste drift_min_speed: la tuk-tuk 45% din vmax CADE pe pragul de
	# intrare (9.0 m/s) si frana de mana nu se mai trage deloc — masurai un
	# viraj normal si il raportai drept drift.
	var target_speed := maxf(car.max_speed * speed_frac,
		car.drift_min_speed * 1.15)
	car.global_position = Vector3(0, 0.7, 0)
	var props := {"ramp-in": "drift_ramp_in", "ramp-out": "drift_ramp_out",
		"arc-tight": "drift_arc_tight", "arc-top": "drift_arc_tight_top",
		"arc-wide": "drift_arc_wide", "inertia": "drift_yaw_inertia",
		"keep": "drift_momentum_keep", "grip-top": "drift_grip_at_top",
		"grip": "drift_grip"}
	for k: String in _overrides:
		if k == "drift-throttle":
			continue
		assert(props.has(k), "suprascriere necunoscuta: " + k)
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

	# Frana de mana trasa, volanul spre interior. `--drift-throttle=` pune
	# gazul la valoarea data cat tine frana de mana (0 = DRIFT singur pe
	# touch, -1 = DRIFT ca frana, cum e din #578); implicit ramane 1.
	drv.drift = true
	if _overrides.has("drift-throttle"):
		drv.throttle = float(_overrides["drift-throttle"])
	var prev_yaw := car.angular_velocity.y
	var max_jump_in := 0.0
	var slip_half := 0.0
	var entered := false
	var t := 0.0
	var line := ""
	var sample_i := 0
	for _f in int(HOLD_IN / STEP):
		await get_tree().physics_frame
		t += STEP
		var yaw := car.angular_velocity.y
		max_jump_in = maxf(max_jump_in, absf(yaw - prev_yaw))
		prev_yaw = yaw
		entered = entered or car.is_drifting
		if sample_i < SAMPLES.size() and t >= SAMPLES[sample_i] - 0.001:
			line += "\n    t=%.1f ω=%.2f slip=%2.0f° v=%4.1f" % [t, yaw,
				absf(_slip_angle_deg(car)), car.horizontal_speed()]
			if is_equal_approx(SAMPLES[sample_i], 0.5):
				slip_half = absf(_slip_angle_deg(car))
			sample_i += 1
	var v_end_in := car.horizontal_speed()

	# Contravolan plin, frana de mana tot trasa: spatele trebuie PRINS, nu
	# intors. Sensul driftului e +1 (volanul a fost +1 la intrare), deci ω
	# ramane pozitiv daca maparea tine.
	drv.steer = -1.0
	var yaw_0 := car.angular_velocity.y
	var yaw_at_01 := 0.0
	var min_yaw := yaw_0
	var counter_line := "ω %.2f" % yaw_0
	t = 0.0
	for _f in int(HOLD_COUNTER / STEP):
		await get_tree().physics_frame
		t += STEP
		var yaw := car.angular_velocity.y
		min_yaw = minf(min_yaw, yaw)
		if is_zero_approx(yaw_at_01) and t >= 0.1 - 0.001:
			yaw_at_01 = yaw
		if t >= 0.1 - 0.001 and t < 0.1 + 0.009 \
				or t >= 0.3 - 0.001 and t < 0.3 + 0.009 \
				or t >= 0.6 - 0.001:
			counter_line += " -> %.2f (%.1f s, slip %2.0f°)" % [yaw, t,
				absf(_slip_angle_deg(car))]
	var inertia_ratio := yaw_at_01 / maxf(yaw_0, 0.01)

	# Frana de mana eliberata, volanul inapoi spre interior.
	drv.steer = 1.0
	drv.drift = false
	var max_jump_out := 0.0
	prev_yaw = car.angular_velocity.y
	for _f in int(0.6 / STEP):
		await get_tree().physics_frame
		var yaw := car.angular_velocity.y
		max_jump_out = maxf(max_jump_out, absf(yaw - prev_yaw))
		prev_yaw = yaw

	print("")
	print("-- intrare la %.1f m/s = %.0f%% din max (dupa %.1f s de drift %.1f m/s) --"
		% [v_in, speed_frac * 100.0, HOLD_IN, v_end_in])
	print("  viraj normal ω=%.2f rad/s%s" % [yaw_normal, line])
	print("  contravolan: %s, min %.2f" % [counter_line, min_yaw])
	_check(entered, "frana de mana s-a tras (is_drifting pe durata tinerii)")
	_check(max_jump_in <= MAX_YAW_JUMP and max_jump_out <= MAX_YAW_JUMP,
		"fara treapta: salt max de ω pe tick %.2f la intrare, %.2f la iesire (<= %.1f)"
		% [max_jump_in, max_jump_out, MAX_YAW_JUMP])
	if speed_frac >= 0.8:
		_check(v_end_in >= v_in * MIN_KEEP,
			"driftul rapid pastreaza viteza: %.0f%% dupa %.1f s (>= %.0f%%)"
			% [v_end_in / v_in * 100.0, HOLD_IN, MIN_KEEP * 100.0])
		_check(slip_half >= MIN_SLIP_FAST,
			"driftul rapid are unghi: %.0f° dupa 0.5 s (>= %.0f°)"
			% [slip_half, MIN_SLIP_FAST])
	_check(min_yaw >= -REVERSE_TOL,
		"contravolanul nu inverseaza: ω min %.2f cu volanul plin in sens opus (>= -%.2f)"
		% [min_yaw, REVERSE_TOL])
	_check(inertia_ratio >= MIN_INERTIA_KEEP,
		"contravolanul prinde cu inertie: ω la 0.1 s = %.0f%% din cel dinainte (>= %.0f%%)"
		% [inertia_ratio * 100.0, MIN_INERTIA_KEEP * 100.0])
	car.queue_free()
	await get_tree().physics_frame
