extends Node
## Decorul usor lovit se aude (docs/feel_checklist.md: things-fly, partea de
## sunet): fiecare rafala de aschii a `PropDebris` scoate un „tac" de lemn / plastic
## la locul loviturii.
##
## Pe corpuri reale (BumpProp, ca ProbePropDebris), cu un Camera3D real ca ureche.
##
## Verifica:
##   1. un con lovit la 18 m/s scoate un `prop_knock_*` pozitional la piesa, pe
##      playerul 3D real, nu pe cel 2D; adormit sau atins sub prag nu scoate nimic;
##   2. mai tare si mai grav la lovitura puternica decat la una usoara;
##   3. gramada de 48 de piese: rata sunetelor limitata de `knock_interval_s`, si
##      un sunet de decor (prioritate 0) nu fura un player ocupat de sunete de
##      jucator;
##   4. departe de camera (peste 40 m) nu se aude nimic.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePropKnock.tscn

const STEP: float = 1.0 / 60.0
const PropDebris := preload("res://scenes/props/prop_debris.gd")

var _failed: bool = false
var _cam: Camera3D


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	AudioManager.clock = func() -> float: return 30000.0 + float(Engine.get_physics_frames()) * STEP
	add_child(_ground())
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true
	await get_tree().physics_frame
	print("")
	print("=== Decor lovit: sunet ===")
	await _test_single()
	await _test_scaling()
	await _test_pile()
	await _test_range()
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _ground() -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2400, 1, 2400)
	cs.shape = sh
	b.add_child(cs)
	b.position = Vector3(0, -0.5, 0)
	return b


func _spawn_car(pos: Vector3) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	car.rotation.y = -PI * 0.5 # botul spre +X
	car.race_active = true
	return car


func _settle(car: Car) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


func _lone_prop(pos: Vector3) -> BumpProp:
	var holder := Node3D.new()
	add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.9, 0.6)
	mi.mesh = box
	holder.add_child(mi)
	mi.position = Vector3(0, 0.45, 0)
	holder.global_position = pos
	return BumpProp.wrap(mi)


func _knocks() -> Array:
	return AudioManager.sfx_log.filter(func(e: Dictionary) -> bool:
		return String(e["name"]).begins_with("prop_knock"))


## Un con la `x0 + 9` lovit de o masina cu `speed`. Intoarce {knocks, bursts, prop_x}.
func _ram(x0: float, z: float, speed: float) -> Dictionary:
	_cam.global_position = Vector3(x0 + 6.0, 10, z + 13)
	var car := _spawn_car(Vector3(x0, 0.7, z))
	var prop := _lone_prop(Vector3(x0 + 9.0, 0, z))
	await _settle(car)
	await get_tree().physics_frame
	var m: Variant = PropDebris.instance()
	var b0 := int(m.bursts)
	AudioManager.sfx_log.clear()
	car.linear_velocity = Vector3(speed, 0, 0)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	var out := {"knocks": _knocks(), "bursts": int(m.bursts) - b0}
	car.queue_free()
	prop.get_parent().queue_free()
	await get_tree().physics_frame
	return out


func _test_single() -> void:
	print("")
	print("-- 1. un con lovit --")
	var r := await _ram(-500.0, 0.0, 18.0)
	var k: Array = r["knocks"]
	print("  rafale %d, prop_knock %d" % [int(r["bursts"]), k.size()])
	_check(int(r["bursts"]) >= 1 and not k.is_empty(), "lovitura la 18 m/s scoate un prop_knock")
	if not k.is_empty():
		_check((k[0] as Dictionary)["positional"], "pozitional")
		var p: Vector3 = (k[0] as Dictionary)["pos"]
		_check(p.x > -495.0 and p.x < -480.0, "la locul loviturii (x = %.1f, conul sta la -491)" % p.x)
		# Playerul liber e refolosit de sunetul urmator: il cautam dupa ULTIMA intrare.
		p = (k[k.size() - 1] as Dictionary)["pos"]
		var found := false
		for pl in AudioManager.pool3d():
			if pl.stream != null and String(pl.stream.resource_path).contains("prop_knock") \
					and pl.global_position.distance_to(p) < 0.01:
				found = true
		_check(found, "un player 3D real poarta prop_knock la acea pozitie")
	var slow := await _ram(-400.0, 0.0, 3.0)
	_check((slow["knocks"] as Array).is_empty() and int(slow["bursts"]) == 0,
		"lovitura la 3 m/s (sub prag): niciun sunet")


func _test_scaling() -> void:
	print("")
	print("-- 2. tare vs usor --")
	var mid := await _ram(-300.0, 0.0, 7.0)
	var fast := await _ram(-200.0, 0.0, 20.0)
	var km: Array = mid["knocks"]
	var kf: Array = fast["knocks"]
	if km.is_empty() or kf.is_empty():
		_check(false, "ambele lovituri scot sunet (%d / %d)" % [km.size(), kf.size()])
		return
	var m0: Dictionary = km[0]
	var f0: Dictionary = kf[0]
	for e in kf:
		if float(e["db"]) > float(f0["db"]):
			f0 = e
	print("  7 m/s: %.1f dB pitch %.2f; 20 m/s: %.1f dB pitch %.2f"
		% [float(m0["db"]), float(m0["pitch"]), float(f0["db"]), float(f0["pitch"])])
	_check(float(f0["db"]) > float(m0["db"]) + 3.0, "mai tare la lovitura puternica")
	_check(float(f0["pitch"]) < float(m0["pitch"]) - 0.05, "mai grav la lovitura puternica")


func _test_pile() -> void:
	print("")
	print("-- 3. gramada de 48 de piese --")
	var x0 := -300.0
	var z := 300.0
	_cam.global_position = Vector3(x0 + 6.0, 10, z + 13)
	var car := _spawn_car(Vector3(x0, 0.7, z))
	var props: Array[BumpProp] = []
	for i in 48:
		var p := _lone_prop(Vector3(x0 + 8.0 + (i % 6) * 0.9, 0, z + (i / 6 - 3.5) * 0.9))
		if p != null:
			props.append(p)
	await _settle(car)
	var m: Variant = PropDebris.instance()
	var b0 := int(m.bursts)
	AudioManager.sfx_log.clear()
	var t0 := float(AudioManager.clock.call())
	car.linear_velocity = Vector3(20, 0, 0)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	var elapsed := float(AudioManager.clock.call()) - t0
	var n := _knocks().size()
	var cap := int(floor(elapsed / AudioManager.knock_interval_s)) + 1
	print("  %d piese, %d rafale, %d sunete in %.2f s (plafon %d)" % [props.size(), int(m.bursts) - b0, n, elapsed, cap])
	_check(props.size() >= 40, "(control) gramada exista")
	_check(int(m.bursts) - b0 > n, "mai multe rafale decat sunete (pauza taie) (%d > %d)" % [int(m.bursts) - b0, n])
	_check(n >= 1 and n <= cap, "sunetele respecta knock_interval_s (%d <= %d)" % [n, cap])
	_check(AudioManager.pool3d().size() == 4, "pool-ul ramane de 4")
	# Prioritate: decorul nu fura un player ocupat de sunet de jucator. Intai lasam
	# pauza proprie a decorului sa expire, ca respingerea sa vina din prioritate.
	for _f in 30:
		await get_tree().physics_frame
	for i in 4:
		AudioManager.play_sfx_at(&"impact_crash_a", Vector3(1000 + i, 0, 0), 1.0, -6.0, 3)
	var before: Array = []
	for pl in AudioManager.pool3d():
		before.append(pl.global_position)
	_cam.global_position = Vector3(1005, 10, 13)
	var ok := AudioManager.prop_knock(Vector3(1005, 0, 0), 0.8)
	var changed := false
	for i in 4:
		if AudioManager.pool3d()[i].global_position.distance_to(before[i]) > 0.01:
			changed = true
	_check(not changed, "un sunet de decor nu fura un player 3D ocupat de sunete de jucator (%s)" % str(ok))
	car.queue_free()
	for p in props:
		if is_instance_valid(p):
			p.get_parent().queue_free()
	await get_tree().physics_frame


func _test_range() -> void:
	print("")
	print("-- 4. departe de camera --")
	_cam.global_position = Vector3(0, 10, 13)
	for _f in 30:
		await get_tree().physics_frame # pauzele vechi expira
	AudioManager.sfx_log.clear()
	var far := AudioManager.prop_knock(Vector3(0, 0, -100), 0.8)
	var near := AudioManager.prop_knock(Vector3(0, 0, -5), 0.8)
	_check(not far and near, "la 115 m de camera nu suna, la 18 m da (%s / %s)" % [str(far), str(near)])
