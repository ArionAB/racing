extends Node
## Control in aer (docs/feel_checklist.md, `jump-skill`): gazul apleaca botul,
## frana il ridica, doar pentru jucator, fara control pe yaw.
##
## Masina e lasata sa cada de la 14 m (fara roti pe sol ~1.3 s), cu viteza
## inainte, pe un PlayerController real (butoanele touch din GameState).
## Contractele, masurate la 0.5 s de zbor:
##   1. fara comenzi: tangajul ramane ~acelasi cu al unui zbor fara control
##      (|delta| < 3 grade);
##   2. gaz: botul coboara cu 15..60 grade fata de zborul neutru;
##   3. frana: botul urca cu 15..60 grade fata de zborul neutru;
##   4. volan tinut in aer: viteza de yaw ramane ~0 (< 0.3 rad/s);
##   5. AI (CarController obisnuit, gaz 1): zbor identic cu cel neutru (< 3 grade).
## Sabotaj (trebuie sa PICE): `-- --off` pune air_control_enabled = false.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAirControl.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _off: bool = false


class AiLike:
	extends CarController
	func get_throttle() -> float:
		return 1.0


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3000, 1, 3000)
	cs.shape = sh
	ground.add_child(cs)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	print("")
	print("=== Control in aer ===")
	if _off:
		print("  (SABOTAJ: air_control_enabled = false)")
	var neutral := await _flight(0, false)
	var gas := await _flight(1, false)
	var brake := await _flight(-1, false)
	var steer := await _flight(0, true)
	var ai := await _flight(2, false)
	print("  tangaj la 0.5 s (grade, + = bot in sus): neutru %.1f, gaz %.1f, frana %.1f, AI %.1f"
		% [neutral.x, gas.x, brake.x, ai.x])
	print("  yaw cu volan tinut: %.2f rad/s" % absf(steer.y))
	_check(absf(gas.x - neutral.x) >= 15.0 and gas.x < neutral.x
			and absf(gas.x - neutral.x) <= 60.0, "gazul apleaca botul cu 15..60 grade")
	_check(brake.x > neutral.x and absf(brake.x - neutral.x) >= 15.0
			and absf(brake.x - neutral.x) <= 60.0, "frana ridica botul cu 15..60 grade")
	_check(absf(steer.y) < 0.3, "fara control pe yaw in aer")
	_check(absf(ai.x - neutral.x) < 3.0, "AI-ul ramane neutru in aer")
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


## mode: 0 neutru, 1 gaz, -1 frana, 2 AI (gaz 1). Intoarce (tangaj la 0.5 s
## in grade, viteza de yaw).
func _flight(mode: int, with_steer: bool) -> Vector2:
	var car := Car.new()
	car.air_control_enabled = not _off
	add_child(car)
	car.global_position = Vector3(0, 14.0, 0)
	car.race_active = true
	GameState.touch_gas = false
	GameState.touch_brake = false
	GameState.touch_steer = 0.0
	if mode == 2:
		car.set_controller(AiLike.new())
	else:
		car.set_controller(PlayerController.new())
		GameState.touch_gas = mode == 1
		GameState.touch_brake = mode == -1
		GameState.touch_steer = 1.0 if with_steer else 0.0
	car.linear_velocity = Vector3(0, 0, -15)
	var pitch := 0.0
	var yaw_rate := 0.0
	for f in 30:
		await get_tree().physics_frame
	var fwd := -car.global_transform.basis.z
	pitch = rad_to_deg(asin(clampf(fwd.y, -1.0, 1.0)))
	yaw_rate = car.angular_velocity.y
	var in_air := car.wheels_on_ground == 0
	if not in_air:
		print("  (atentie: masina nu mai e in aer la 0.5 s)")
	GameState.touch_gas = false
	GameState.touch_brake = false
	GameState.touch_steer = 0.0
	car.queue_free()
	await get_tree().physics_frame
	return Vector2(pitch, yaw_rate)
