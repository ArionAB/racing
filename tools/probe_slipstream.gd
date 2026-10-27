extends Node
## Slipstream (docs/feel_checklist.md, `slipstream`).
##
## O masina lider e tinuta la viteza maxima (34 m/s) pe teren plat; urmaritorul
## are gaz tinut. Contractele:
##   1. la 8 m in spate, pe axa: `draft` ajunge la 1 in <= 0.8 s, iar
##      urmaritorul trece de plafonul lui obisnuit (> max_speed + 0.8 m/s);
##   2. NU exista aspiratie: la 20 m (prea departe), la 1 m (prea aproape), cu
##      3 m lateral (in afara conului), cu liderul lent (8 m/s), cu urmaritorul
##      lent (10 m/s), si pentru masina din FATA (liderul nu aspira urmaritorul);
##   3. iesit din con, `draft` scade la 0 in <= 0.6 s;
##   4. se poate depasi: o masina alaturi (lateral 3 m, la acelasi nivel) nu are
##      draft, deci aspiratia nu o tine lipita de lider.
## Sabotaj (trebuie sa PICE): `-- --off` pune slipstream_enabled = false.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSlipstream.tscn

const STEP: float = 1.0 / 60.0

var _failed: bool = false
var _off: bool = false


class ScriptDriver:
	extends CarController
	var throttle: float = 1.0
	func get_throttle() -> float:
		return throttle


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(6000, 1, 6000)
	cs.shape = sh
	ground.add_child(cs)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	print("")
	print("=== Slipstream ===")
	if _off:
		print("  (SABOTAJ: slipstream_enabled = false)")
	await _test_follow()
	await _test_negatives()
	await _test_fade()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(pos: Vector3, speed: float) -> Car:
	var car := Car.new()
	car.slipstream_enabled = not _off
	add_child(car)
	car.global_position = pos
	car.set_controller(ScriptDriver.new())
	car.race_active = true
	car.linear_velocity = Vector3(0, 0, -speed)
	return car


func _settle() -> void:
	for _f in 40:
		await get_tree().physics_frame


## Lider fixat la `lead_speed` (viteza reimpusa in fiecare tick, pe -Z).
func _hold_leader(leader: Car, lead_speed: float) -> void:
	var v := leader.linear_velocity
	leader.linear_velocity = Vector3(0, v.y, -lead_speed)


func _test_follow() -> void:
	print("")
	print("-- 1. urmarire la 8 m, lider la 34 m/s --")
	var leader := _spawn(Vector3(0, 0.7, -50), 0.0)
	var follower := _spawn(Vector3(0, 0.7, -42), 0.0)
	await _settle()
	leader.linear_velocity = Vector3(0, 0, -34)
	follower.linear_velocity = Vector3(0, 0, -30)
	var t := 0.0
	var t_full := -1.0
	var vmax_seen := 0.0
	for _f in 150:
		_hold_leader(leader, 34.0)
		await get_tree().physics_frame
		t += STEP
		if t_full < 0.0 and follower.draft >= 0.99:
			t_full = t
		if t > 2.0:
			vmax_seen = maxf(vmax_seen, follower.horizontal_speed())
	var gap := follower.global_position.distance_to(leader.global_position)
	print("  draft complet la %s, viteza maxima urmaritor %.1f m/s (plafon %.0f), distanta ramasa %.1f m"
		% [("%.2f s" % t_full) if t_full >= 0.0 else "NICIODATA", vmax_seen, follower.max_speed, gap])
	_check(t_full >= 0.0 and t_full <= 0.8, "draft = 1 in <= 0.8 s")
	_check(vmax_seen > follower.max_speed + 0.8, "trece de plafonul obisnuit (> +0.8 m/s)")
	leader.queue_free()
	follower.queue_free()
	await get_tree().physics_frame


## Un singur caz negativ: urmaritorul la (x, z_off) fata de lider.
func _draft_case(label: String, dz: float, dx: float, lead_speed: float,
		foll_speed: float, swap: bool = false) -> void:
	var leader := _spawn(Vector3(0, 0.7, -100), 0.0)
	var follower := _spawn(Vector3(dx, 0.7, -100 + dz), 0.0)
	await _settle()
	leader.linear_velocity = Vector3(0, 0, -lead_speed)
	follower.linear_velocity = Vector3(0, 0, -foll_speed)
	var peak := 0.0
	var watched: Car = leader if swap else follower
	for _f in 40:
		_hold_leader(leader, lead_speed)
		follower.linear_velocity = Vector3(0, follower.linear_velocity.y, -foll_speed)
		await get_tree().physics_frame
		peak = maxf(peak, watched.draft)
	print("  %s: draft maxim %.2f" % [label, peak])
	_check(peak < 0.05, "%s: fara aspiratie" % label)
	leader.queue_free()
	follower.queue_free()
	await get_tree().physics_frame


func _test_negatives() -> void:
	print("")
	print("-- 2. cazuri fara aspiratie --")
	await _draft_case("prea departe (20 m)", 20.0, 0.0, 34.0, 34.0)
	await _draft_case("prea aproape (1 m)", 1.0, 0.0, 34.0, 34.0)
	await _draft_case("lateral 3 m (alaturi, 8 m)", 8.0, 3.0, 34.0, 34.0)
	await _draft_case("lider lent (8 m/s)", 8.0, 0.0, 8.0, 34.0)
	await _draft_case("urmaritor lent (10 m/s)", 8.0, 0.0, 34.0, 10.0)
	await _draft_case("masina din fata nu aspira", 8.0, 0.0, 34.0, 34.0, true)


func _test_fade() -> void:
	print("")
	print("-- 3. iesirea din con --")
	var leader := _spawn(Vector3(0, 0.7, -100), 0.0)
	var follower := _spawn(Vector3(0, 0.7, -92), 0.0)
	await _settle()
	leader.linear_velocity = Vector3(0, 0, -34)
	follower.linear_velocity = Vector3(0, 0, -34)
	for _f in 60:
		_hold_leader(leader, 34.0)
		await get_tree().physics_frame
	var had := follower.draft
	# Urmaritorul sare lateral din con.
	follower.global_position += Vector3(4.0, 0, 0)
	var t := 0.0
	var t_zero := -1.0
	for _f in 60:
		_hold_leader(leader, 34.0)
		await get_tree().physics_frame
		t += STEP
		if t_zero < 0.0 and follower.draft <= 0.001:
			t_zero = t
	print("  draft inainte %.2f, dupa iesire 0 la %s" % [had,
		("%.2f s" % t_zero) if t_zero >= 0.0 else "NICIODATA"])
	_check(had >= 0.99, "inainte de iesire draft = 1")
	_check(t_zero >= 0.0 and t_zero <= 0.6, "draft = 0 in <= 0.6 s dupa iesire")
	leader.queue_free()
	follower.queue_free()
	await get_tree().physics_frame
