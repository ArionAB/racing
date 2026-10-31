extends Node
## Macacii care traverseaza (Ha Long, POI G, #597): contactul trebuie SIMTIT.
##
## Hazardul real e `HerdHazard` (acelasi cod ca gnu din Serengeti si oile din
## Transfagarasan); aici se iau parametrii EI din Track22.tscn
## (Hazarduri/MaimutePerete) si se pun pe un sol plat, cu o masina scriptata
## la viteza de cursa (28 m/s) prin culoarul cu pulsul des.
##
## Contracte (viteza de cursa, 3 mase: sport 0.9, Muscle 1.35, autobuz 2.6):
##   1. fereastra libera: zero contact (hazardul ramane corect, o poti evita);
##   2. in puls des: viteza pierduta pe traversare dintr-un 5-35% — simtita, dar
##      nu zid; masina usoara pierde mai mult decat cea grea (masa conteaza);
##   3. zdruncinatura: cel putin o lovitura ridica masina (jolt vertical) si
##      emite `impact` (kind &"animal") pe masina — camera/caroseria/haptica;
##   4. macacul lovit se rostogoleste (tumbles >= 1);
##   5. masina nu e azvarlita/ingropata (y in [-0.3, 1.5]) si trece (iese din
##      culoar, viteza de iesire > 40% din cea de intrare).
## `--sabotaj`: aceleasi masuratori cu efectul pe ZERO (forward_loss = 0, kick
## = 0, jolt = 0): contractele 2 si 3 trebuie sa PICE.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHalongMacaques.tscn [-- --sabotaj]

const STEP: float = 1.0 / 60.0
const SPEED: float = 28.0
const HerdScript := preload("res://scenes/hazards/herd_hazard.gd")
const PROPS := ["corridor_m", "animal_mass", "speed", "spacing", "zebra_ratio", "no_body_radius",
	"body_reach", "pulse_on", "pulse_off", "strips", "files_per_strip", "kick_speed",
	"forward_loss", "hit_cooldown", "tumble_time", "mass_ratio_floor", "jolt_speed",
	"hit_feedback", "animal_model", "alt_model"]

var _failed: bool = false
var _sabotage: bool = false
var _template: Node


class ScriptDriver:
	extends CarController
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return 1.0
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	call_deferred("_go")


func _make_herd() -> HerdHazard:
	var herd: HerdHazard = HerdScript.new()
	herd.flow_dir = Vector3(1, 0, 0)
	herd.road_dir = Vector3(0, 0, 1)
	for p: String in PROPS:
		if p in _template:
			herd.set(p, _template.get(p))
	if _sabotage:
		herd.forward_loss = 0.0
		herd.kick_speed = 0.0
		herd.jolt_speed = 0.0
	return herd


func _spawn(pos: Vector3, factor: float) -> Car:
	var car := Car.new()
	car.mass_factor = factor
	car.is_player = true
	add_child(car)
	car.global_position = pos
	car.race_active = true
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	car.speed_limit_factor = SPEED / car.max_speed
	car.linear_velocity = Vector3(0, 0, -SPEED)
	return car


func _wait(seconds: float) -> void:
	for _f in int(seconds / STEP):
		await get_tree().physics_frame


func _go() -> void:
	_sabotage = "--sabotaj" in OS.get_cmdline_user_args()
	var ts := (load("res://scenes/tracks/Track22.tscn") as PackedScene).instantiate()
	_template = ts.get_node("Hazarduri/MaimutePerete")
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(800, 1, 800)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	print("")
	print("=== Ha Long: macacii (%s) ===" % ("SABOTAJ: efect pe zero" if _sabotage else "parametrii din Track22"))

	var herd := _make_herd()
	add_child(herd)
	herd.global_position = Vector3.ZERO
	await get_tree().physics_frame
	print("  animale %d, perioada %.1f s, masa animal %.0f, loss %.2f, kick %.1f, jolt %.2f, min_ratio %.2f" % [
		herd.count(), herd.period(), herd.animal_mass, herd.forward_loss, herd.kick_speed,
		herd.jolt_speed, herd.mass_ratio_floor])

	await _wait(herd.seconds_to_window())
	var free := await _cross(herd, 0.9)
	print("  fereastra: lovituri %d, viteza %.1f -> %.1f" % [free.hits, free.v_in, free.v_out])
	_check(free.hits == 0, "fereastra libera: zero contact")

	var loss: Dictionary = {}
	for f: float in [0.9, 1.35, 2.6]:
		await _wait(herd.seconds_to_dense())
		var r := await _cross(herd, f)
		var drop: float = 1.0 - float(r.v_min) / maxf(float(r.v_in), 0.1)
		loss[f] = drop
		print("  masa %.2f: lovituri %d, v %.1f -> min %.1f (pierdere %.0f%%), impact-uri %d (forta max %.1f), hop max %.2f m, y [%.2f, %.2f], v iesire %.1f, tumbles %d" % [
			f, r.hits, r.v_in, r.v_min, drop * 100.0, r.impacts, r.impact_max, r.hop, r.y_min, r.y_max, r.v_out, herd.tumbles])
		_check(drop >= 0.05 and drop <= 0.35, "masa %.2f: pierdere de viteza 5-35%% (%.0f%%)" % [f, drop * 100.0])
		_check(r.hop >= 0.04, "masa %.2f: zdruncinatura verticala >= 4 cm (%.2f m)" % [f, r.hop])
		_check(r.impacts >= 1 and r.impact_max >= 1.0,
			"masa %.2f: `impact` real pe masina (forta max %.1f >= 1.0 m/s)" % [f, r.impact_max])
		_check(r.y_min > -0.3 and r.y_max < 1.5, "masa %.2f: nu e ingropata/azvarlita" % f)
		_check(r.v_out > r.v_in * 0.4, "masa %.2f: trece prin culoar (v iesire %.1f)" % [f, r.v_out])
	_check(herd.tumbles >= 1, "macacii loviti se rostogolesc (%d)" % herd.tumbles)
	_check(float(loss[0.9]) > float(loss[2.6]) * 1.3, "masina usoara pierde mai mult decat autobuzul (%.0f%% vs %.0f%%)" % [
		float(loss[0.9]) * 100.0, float(loss[2.6]) * 100.0])
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _cross(herd: HerdHazard, factor: float) -> Dictionary:
	var car := _spawn(Vector3(0, 0.7, 45), factor)
	herd.cars = [car]
	var hits0 := herd.hits
	var impacts: Array[float] = []
	car.impact.connect(func(_c: Car, kind: StringName, strength: float, _n: Vector3,
			_p: Vector3, _o: Node) -> void:
		if kind == &"animal":
			impacts.append(strength))
	var y_min := INF
	var y_max := -INF
	var v_in := 0.0
	var v_min := INF
	var v_out := 0.0
	var base_y := 0.0
	var hop := 0.0
	var frames := 0
	while car.global_position.z > -45.0 and frames < int(10.0 / STEP):
		await get_tree().physics_frame
		frames += 1
		var z := car.global_position.z
		if z < 28.0 and z > 22.0 and v_in == 0.0:
			v_in = car.horizontal_speed()
			base_y = car.global_position.y
		if absf(z) < 16.0:
			v_min = minf(v_min, car.horizontal_speed())
			y_min = minf(y_min, car.global_position.y)
			y_max = maxf(y_max, car.global_position.y)
			hop = maxf(hop, car.global_position.y - base_y)
		if z < -30.0 and v_out == 0.0:
			v_out = car.horizontal_speed()
	if v_out == 0.0:
		v_out = car.horizontal_speed()
	var mx := 0.0
	for s in impacts:
		mx = maxf(mx, s)
	herd.cars = []
	car.queue_free()
	await get_tree().physics_frame
	return {"hits": herd.hits - hits0, "v_in": v_in, "v_out": v_out, "v_min": v_min,
		"y_min": y_min, "y_max": y_max, "hop": hop, "impacts": impacts.size(), "impact_max": mx}
