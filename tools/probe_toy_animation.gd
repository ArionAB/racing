extends Node
## Jucaria de pe caroserie: antena cu arc si cheia de intors (feel_checklist:
## toy-animation).
##
## Pe FIECARE masina din garaj (GameState.CAR_DATA) verifica:
##   1. antena si cheia exista, au sub 600 de triunghiuri impreuna, iar cu
##      `toy_animation = false` nu exista deloc;
##   2. montajul e pe suprafata modelului, nu in aer: raza in jos din dreptul
##      antenei ajunge la caroserie la <= 5 cm de baza ei, iar fata din spate e
##      la <= 6 cm de baza cheii;
##   3. nu intra in caroserie: segmentele de la baza antenei la varf (in repaus
##      si inclinata la 0.25 rad in 8 directii) si de la axa cheii la varfurile
##      aripilor ei (12 unghiuri de rotatie) nu intalnesc niciun triunghi al
##      modelului pe drum.
## Si, pe o masina, dinamica:
##   4. frana tare: varful antenei se apleaca INAINTE (-Z) > 8 grade, oscileaza
##      (trece prin zero) si se linisteste sub 2 grade intr-o secunda dupa
##      oprire; demarajul o apleaca inapoi; o lovitura laterala zvacneste in
##      partea opusa;
##   5. cheia: turatia la 25 m/s > de 2 ori cea de la 6 m/s, si zero pe loc.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeToyAnimation.tscn

const STEP: float = 1.0 / 60.0
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

var _failed: bool = false


class ScriptDriver:
	extends CarController
	var throttle: float = 0.0
	func get_throttle() -> float:
		return throttle


func _ready() -> void:
	var g := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2400, 1, 2400)
	cs.shape = sh
	g.add_child(cs)
	g.position = Vector3(0, -0.5, 0)
	add_child(g)
	await get_tree().physics_frame
	print("")
	print("=== Jucaria: antena si cheia ===")
	var datas: Array = GameState.CAR_DATA.duplicate()
	datas.append(GameState.CAR_DATA_TUKTUK)
	var i := 0
	for d in datas:
		await _test_mount(d as CarData, i)
		i += 1
	await _test_flag_off()
	await _test_dynamics()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(d: CarData, pos: Vector3) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(d)
	car.global_position = pos
	car.race_active = true
	return car


func _tris(n: Node) -> int:
	var t := 0
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var idx := arr[Mesh.ARRAY_INDEX] as PackedInt32Array
			t += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	for c in n.get_children():
		t += _tris(c)
	return t


## Segment liber de caroserie? (primul triunghi lovit e dincolo de capat)
func _clear(parts: Array, a: Vector3, b: Vector3) -> bool:
	var dir := b - a
	var len := dir.length()
	if len < 0.001:
		return true
	var hit: Dictionary = Car.toy_ray(parts, a, dir / len)
	return hit.is_empty() or float(hit["distance"]) > len - 0.01


func _test_mount(d: CarData, idx: int) -> void:
	var car := _spawn(d, Vector3(idx * 12.0, 0.7, 0))
	await get_tree().physics_frame
	print("")
	print("-- %s --" % d.display_name)
	var ant: Node3D = car._toy_antenna
	var key: Node3D = car._toy_key
	if d.model == null:
		_check(ant == null and key == null, "(fara model: fara jucarie)")
		car.queue_free()
		return
	var tris := (_tris(ant) if ant != null else 0) + (_tris(key) if key != null else 0)
	print("  antena=%s cheie=%s, %d triunghiuri" % [ant != null, key != null, tris])
	_check(ant != null and key != null, "antena si cheia au gasit unde sa se monteze")
	_check(tris < 600, "sub 600 de triunghiuri (%d)" % tris)
	if ant == null or key == null:
		car.queue_free()
		return
	var parts: Array = []
	car._toy_collect(car._visual.get_child(0) as Node3D, Transform3D.IDENTITY, parts)
	# 2. contact cu suprafata.
	var base := ant.position
	var down: Dictionary = Car.toy_ray(parts, base + Vector3(0, 1.0, 0), Vector3.DOWN)
	var gap_a := absf((down["position"] as Vector3).y - base.y) if not down.is_empty() else 99.0
	var kb := key.position
	var back: Dictionary = Car.toy_ray(parts, kb + Vector3(0, 0, 1.0), Vector3(0, 0, -1))
	var gap_k := absf((back["position"] as Vector3).z - kb.z) if not back.is_empty() else 99.0
	print("  distanta fata de suprafata: antena %.3f m, cheie %.3f m" % [gap_a, gap_k])
	_check(gap_a <= 0.05, "antena sta pe caroserie (nu in aer)")
	_check(gap_k <= 0.06, "cheia sta pe fata din spate")
	# 3. fara intrare in caroserie, masurat pe GEOMETRIA construita (nu pe
	# cifrele din cod): vergeaua si aripile reale, citite din noduri.
	var length := 0.0
	for c in ant.get_children():
		var m := c as MeshInstance3D
		length = maxf(length, m.position.y + m.mesh.get_aabb().end.y)
	var from := base + Vector3(0, 0.06, 0)
	var blocked_rest := 0 if _clear(parts, from, base + Vector3(0, length, 0)) else 1
	var blocked_tilt := 0
	for k in 8:
		var yaw := TAU * k / 8.0
		var tilted := base + Vector3(sin(0.25) * cos(yaw), cos(0.25), sin(0.25) * sin(yaw)) * length
		if not _clear(parts, from, tilted):
			blocked_tilt += 1
	var blocked_key := 0
	var tested := 0
	for c in key.get_children():
		var m := c as MeshInstance3D
		if m == null or not (m.mesh is ArrayMesh):
			continue
		var bb := m.mesh.get_aabb()
		if bb.size.x < bb.size.y * 1.2 and bb.size.x < bb.size.z * 1.2:
			continue # fusul, nu aripa
		# Colturile contururilor aripii (x, y) la z-ul ei, rotite in jurul axei Z.
		var wz := m.position.z + bb.end.z
		for ca in [Vector2(bb.position.x, bb.position.y), Vector2(bb.end.x, bb.position.y),
				Vector2(bb.position.x, bb.end.y), Vector2(bb.end.x, bb.end.y)]:
			var corner := Vector2(m.position.x + ca.x, m.position.y + ca.y)
			for k in 12:
				var rot := corner.rotated(TAU * k / 12.0)
				tested += 1
				var axis := kb + Vector3(0, 0, wz)
				if not _clear(parts, axis, kb + Vector3(rot.x, rot.y, wz)):
					blocked_key += 1
	print("  intersectii: antena in repaus %d, inclinata 0.25 rad %d/8, aripile cheii %d/%d" % [
		blocked_rest, blocked_tilt, blocked_key, tested])
	_check(blocked_rest == 0, "antena in repaus nu intra in caroserie")
	_check(blocked_tilt == 0, "antena inclinata la 0.25 rad (8 directii) nu intra in caroserie")
	_check(tested > 0 and blocked_key == 0, "aripile cheii, in toate cele 12 unghiuri, nu intra in caroserie")
	car.queue_free()
	await get_tree().physics_frame


func _test_flag_off() -> void:
	print("")
	print("-- toy_animation = false --")
	var d := (GameState.CAR_DATA[0] as CarData).duplicate() as CarData
	d.toy_animation = false
	var car := _spawn(d, Vector3(-60, 0.7, 0))
	await get_tree().physics_frame
	var has := car._visual.find_child("ToyAntenna", true, false) != null \
		or car._visual.find_child("ToyKey", true, false) != null
	_check(car._toy_antenna == null and car._toy_key == null and not has, "fara jucarie cand flag-ul e stins")
	var plain := Car.new()
	add_child(plain)
	await get_tree().physics_frame
	_check(plain._toy_antenna == null, "(masina fara model: nicio jucarie, nicio eroare)")
	car.queue_free()
	plain.queue_free()


func _top_lean(car: Car) -> Vector3:
	var up: Vector3 = (car._toy_antenna as Node3D).quaternion * Vector3.UP
	return Vector3(up.x, 0.0, up.z)


func _test_dynamics() -> void:
	print("")
	print("-- dinamica: arc, impact, cheie --")
	var car := _spawn(GameState.CAR_DATA[0] as CarData, Vector3(-100, 0.7, 100))
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	# Demaraj: antena inapoi (+Z).
	drv.throttle = 1.0
	var accel_peak := 0.0
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
		accel_peak = maxf(accel_peak, _top_lean(car).z)
	print("  demaraj: varful antenei se duce inapoi cu %.3f" % accel_peak)
	_check(accel_peak > 0.08, "demaraj: antena se apleaca inapoi (+Z)")
	# Viteza de croaziera, cheia.
	for _f in int(4.0 / STEP):
		await get_tree().physics_frame
	var k_fast := await _key_rate(car)
	print("  cheie la viteza mare (%.0f m/s): %.1f rad/s" % [car.horizontal_speed(), k_fast])
	# Frana tare.
	drv.throttle = -1.0
	var fwd_peak := 0.0
	var sign_changes := 0
	var prev_sign := 0.0
	var stopped_at := -1.0
	var t := 0.0
	var settle_lean := -1.0
	for _f in int(5.0 / STEP):
		await get_tree().physics_frame
		t += STEP
		var l := _top_lean(car)
		fwd_peak = maxf(fwd_peak, -l.z)
		var sg := signf(l.z) if absf(l.z) > 0.01 else 0.0
		if sg != 0.0 and prev_sign != 0.0 and sg != prev_sign:
			sign_changes += 1
		if sg != 0.0:
			prev_sign = sg
		if stopped_at < 0.0 and car.horizontal_speed() < 0.5:
			stopped_at = t
		if stopped_at > 0.0:
			drv.throttle = 0.0 # fara asta, frana tinuta da marsarier
		if stopped_at > 0.0 and t >= stopped_at + 2.0 and settle_lean < 0.0:
			settle_lean = l.length()
	print("  frana: varful se duce inainte cu %.3f (%.1f grade), treceri prin zero %d, oprit la %.2f s, aplecare 2 s dupa oprire %.3f"
		% [fwd_peak, rad_to_deg(asin(clampf(fwd_peak, 0.0, 1.0))), sign_changes, stopped_at, settle_lean])
	_check(fwd_peak > 0.14, "frana: antena se apleaca inainte (> 8 grade)")
	_check(sign_changes >= 1, "arc: oscileaza (trece prin zero)")
	_check(settle_lean >= 0.0 and settle_lean < 0.035, "se linisteste (< 2 grade) la 2 s dupa oprire")
	# Cheie la repaus.
	drv.throttle = 0.0
	for _f in 20:
		await get_tree().physics_frame
	print("  viteza la proba de repaus: %.2f m/s" % car.horizontal_speed())
	var k_idle := await _key_rate(car)
	print("  cheie pe loc: %.2f rad/s" % k_idle)
	_check(k_idle < 0.5, "cheia sta pe loc cand masina sta")
	# Lovitura laterala.
	for _f in 40:
		await get_tree().physics_frame
	car.impact.emit(car, &"wall", 12.0, Vector3.RIGHT, car.global_position, null)
	var side := Vector3.ZERO
	var best := 0.0
	for _f in 20:
		await get_tree().physics_frame
		if _top_lean(car).length() > best:
			best = _top_lean(car).length()
			side = _top_lean(car)
	print("  lovitura (impins spre dreapta): varful se duce la (%.3f, %.3f)" % [side.x, side.z])
	_check(side.x < -0.08, "lovitura laterala zvacneste antena in partea opusa (-X)")
	car.queue_free()
	await get_tree().physics_frame
	# Cheie: 6 vs 25 m/s pe doua masini.
	var rates: Array[float] = []
	for sp in [6.0, 25.0]:
		var c := _spawn(GameState.CAR_DATA[0] as CarData, Vector3(-100, 0.7, -100))
		var dr := ScriptDriver.new()
		c.set_controller(dr)
		for _f in int(0.8 / STEP):
			await get_tree().physics_frame
		c.linear_velocity = Vector3(0, 0, -sp)
		for _f in 5:
			await get_tree().physics_frame
		c.linear_velocity = Vector3(0, 0, -sp)
		rates.append(await _key_rate(c, sp))
		c.queue_free()
		await get_tree().physics_frame
	print("  cheie: %.1f rad/s la 6 m/s, %.1f rad/s la 25 m/s" % [rates[0], rates[1]])
	_check(rates[1] > 2.0 * rates[0] and rates[0] > 0.5, "cheia se invarte de >2 ori mai repede la 25 m/s decat la 6")


## Turatia cheii (rad/s), masurata din unghiul real al nodului pe 6 cadre.
func _key_rate(car: Car, hold_speed: float = -1.0) -> float:
	var a0: float = (car._toy_key as Node3D).rotation.z
	var total := 0.0
	for _f in 6:
		await get_tree().physics_frame
		if hold_speed > 0.0:
			car.linear_velocity = Vector3(0, 0, -hold_speed)
		var a1: float = (car._toy_key as Node3D).rotation.z
		total += absf(wrapf(a1 - a0, -PI, PI))
		a0 = a1
	return total / (6.0 * STEP)
