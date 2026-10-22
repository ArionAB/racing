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
##   5. cheia: turatia la 25 m/s > de 2 ori cea de la 6 m/s, si zero pe loc;
##   6. zdranganeala (piese de plastic care zornaie): pe bordura, trepte, teren
##      afanat si dupa aterizari antena (si cheia) tremura mic si repede, mai mult
##      cu viteza; pe drum neted la aceeasi viteza si pe loc, deloc. Apoi pe o
##      pista reala, tinuta pe banda de bordura la 25 m/s fata de axa soselei.
## Sabotaj (trebuie sa PICE): `-- --off` stinge `toy_rattle_enabled`.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeToyAnimation.tscn

const STEP: float = 1.0 / 60.0
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

var _failed: bool = false
var _off: bool = false


class ScriptDriver:
	extends CarController
	var throttle: float = 0.0
	func get_throttle() -> float:
		return throttle


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
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
	await _test_rattle()
	await _test_rattle_real_kerb()
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
	if _off:
		car.toy_rattle_enabled = false
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


# ------------------------------------------------------- zdranganeala

## Cat de repede se misca varful antenei de la un cadru la altul (rad/cadru, RMS):
## tremurul rapid, nu aplecarea lenta a arcului. `setup` ruleaza inaintea fiecarui
## pas (flaguri de teren fortate), `speed` e viteza data lui `_update_toys`.
func _jitter(car: Car, speed: float, frames: int, setup: Callable) -> Dictionary:
	var prev := _top_lean(car)
	var prev_key := Vector2((car._toy_key as Node3D).rotation.x, (car._toy_key as Node3D).rotation.y)
	var sq := 0.0
	var sq_key := 0.0
	var mean_r := 0.0
	for _f in frames:
		setup.call()
		car._update_toys(STEP, speed)
		var l := _top_lean(car)
		var kk := Vector2((car._toy_key as Node3D).rotation.x, (car._toy_key as Node3D).rotation.y)
		sq += (l - prev).length_squared()
		sq_key += (kk - prev_key).length_squared()
		prev = l
		prev_key = kk
		mean_r += car.toy_rattle
	return {"ant": sqrt(sq / float(frames)), "key": sqrt(sq_key / float(frames)),
		"rattle": mean_r / float(frames)}


func _test_rattle() -> void:
	print("")
	print("-- 6. zdranganeala: bordura, trepte, afanat, aterizare --")
	if _off:
		print("  (SABOTAJ: toy_rattle_enabled = false)")
	var car := _spawn(GameState.CAR_DATA[0] as CarData, Vector3(-200, 0.7, 200))
	car.set_controller(ScriptDriver.new())
	for _f in int(1.0 / STEP):
		await get_tree().physics_frame
	_check(car.wheels_on_ground > 0, "masina de proba sta pe roti (%d)" % car.wheels_on_ground)
	var none := func() -> void:
		car.on_kerb = false
		car.on_steps = false
		car._toy_loose = false
	var kerb := func() -> void:
		car.on_kerb = true
		car.on_steps = false
		car._toy_loose = false
	var steps := func() -> void:
		car.on_kerb = false
		car.on_steps = true
		car._toy_loose = false
	var loose := func() -> void:
		car.on_kerb = false
		car.on_steps = false
		car._toy_loose = true
	# Aceeasi viteza (20 m/s), aceeasi masina: doar terenul difera. Se lasa 20 de
	# cadre sa se aseze nivelul, apoi se masoara 120.
	var res: Dictionary = {}
	for pair in [["neted", none, 20.0], ["bordura", kerb, 20.0], ["trepte", steps, 20.0],
			["afanat", loose, 20.0], ["bordura 4 m/s", kerb, 4.0], ["bordura pe loc", kerb, 0.0]]:
		var setup: Callable = pair[1]
		_jitter(car, float(pair[2]), 20, setup)
		res[pair[0]] = _jitter(car, float(pair[2]), 120, setup)
		var r: Dictionary = res[pair[0]]
		print("  %-15s antena %.4f rad/cadru, cheie %.4f, nivel mediu %.2f"
			% [pair[0], r.ant, r.key, r.rattle])
	var smooth_ant: float = res["neted"].ant
	var smooth_key: float = res["neted"].key
	_check(smooth_ant < 0.002 and smooth_key < 0.002,
		"drum neted la 20 m/s: antena si cheia nu tremura (%.4f / %.4f)" % [smooth_ant, smooth_key])
	for nm: String in ["bordura", "trepte", "afanat"]:
		var r: Dictionary = res[nm]
		var floor_ant := maxf(smooth_ant, 0.001)
		_check(float(r.ant) > 10.0 * floor_ant and float(r.ant) > 0.01,
			"%s la 20 m/s: antena tremura (%.4f, de %.0f ori peste drumul neted)"
			% [nm, r.ant, float(r.ant) / floor_ant])
		_check(float(r.key) > 10.0 * maxf(smooth_key, 0.001),
			"%s la 20 m/s: si cheia se clatina pe ax (%.4f)" % [nm, r.key])
	_check(float(res["bordura"].ant) < 0.12,
		"tremurul ramane mic (< 0.12 rad/cadru, e plastic, nu o furtuna): %.4f"
		% float(res["bordura"].ant))
	_check(float(res["bordura"].ant) > 1.8 * float(res["bordura 4 m/s"].ant),
		"mai repede = mai tare: bordura 20 m/s %.4f vs 4 m/s %.4f"
		% [float(res["bordura"].ant), float(res["bordura 4 m/s"].ant)])
	_check(float(res["bordura pe loc"].ant) < 0.002 and float(res["bordura pe loc"].rattle) < 0.01,
		"pe loc, chiar pe bordura: nimic (%.4f)" % float(res["bordura pe loc"].ant))
	# Aterizare: rafala scurta, apoi liniste.
	none.call()
	for _k in 40:
		car._update_toys(STEP, 0.0)
	var base_r := car.toy_rattle
	car.landed.emit(car, 12.0)
	var burst := _jitter(car, 0.0, 12, none)
	for _k in 30:
		car._update_toys(STEP, 0.0)
	var later := _jitter(car, 0.0, 30, none)
	print("  aterizare 12 m/s (pe loc): primele 12 cadre antena %.4f, nivel %.2f; dupa 0.7 s: %.4f"
		% [burst.ant, burst.rattle, later.ant])
	_check(base_r < 0.01, "inainte de aterizare: liniste")
	_check(float(burst.ant) > 0.01 and float(burst.rattle) > 0.4,
		"aterizare grea: antena zornaie chiar si pe loc")
	_check(float(later.ant) < 0.002, "rafala moare in sub o secunda")
	car.landed.emit(car, 6.5)
	var soft := _jitter(car, 0.0, 12, none)
	print("  aterizare 6.5 m/s: antena %.4f (vs %.4f la 12 m/s)" % [soft.ant, burst.ant])
	_check(float(soft.ant) < float(burst.ant), "aterizarea usoara zornaie mai putin decat cea grea")
	car.queue_free()
	await get_tree().physics_frame


## Pe o pista REALA cu borduri: masina jucatorului tinuta la 25 m/s pe banda
## bordurii vs pe axa soselei; aceeasi procedura, aceeasi masina.
func _test_rattle_real_kerb() -> void:
	print("")
	print("-- 7. pista reala: bordura vs axa soselei --")
	var measured := false
	for t in [2, 0, 1, 3, 5, 7, 8, 9]:
		GameState.selected_track = t
		GameState.champ_active = false
		GameState.total_laps = 99
		var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate() as Race
		add_child(race)
		var track: Track = race.track
		var spots: Array[int] = []
		for i in track._kerb_idx.size():
			if track._kerb_idx[i] == 1 and i % 2 == 0:
				spots.append(i)
		if spots.size() < 30 or race.player._toy_antenna == null:
			race.queue_free()
			await get_tree().physics_frame
			continue
		print("  pista %d (%s)" % [t, track.track_name])
		var guard := 0
		while race.state != Race.State.RUNNING and guard < 1800:
			await get_tree().physics_frame
			guard += 1
		race.player.toy_rattle_enabled = not _off
		var on := await _ride_ant(race, track, spots, 0.45, 25.0)
		var axis := await _ride_ant(race, track, spots,
			track.width_at_index(spots[spots.size() / 3]), 25.0)
		var slow := await _ride_ant(race, track, spots, 0.45, 1.0)
		print("  bordura 25 m/s: antena %.4f rad/cadru, nivel %.2f; axa: %.4f, nivel %.2f; bordura 1 m/s: %.4f, nivel %.2f"
			% [on.x, on.y, axis.x, axis.y, slow.x, slow.y])
		_check(on.y > 0.4, "pe bordura reala nivelul de zdranganeala urca (%.2f)" % on.y)
		_check(on.x > 2.0 * maxf(axis.x, 0.002),
			"antena tremura pe bordura de >2 ori mai mult decat pe axa (%.4f vs %.4f)" % [on.x, axis.x])
		_check(axis.y < 0.15, "pe axa soselei zdranganeala ramane joasa (%.2f)" % axis.y)
		_check(slow.y < 0.1, "oprit pe bordura: fara zdranganeala (%.2f)" % slow.y)
		measured = true
		race.queue_free()
		await get_tree().physics_frame
		break
	_check(measured, "o pista cu borduri si jucarie a fost gasita si masurata")


class HoldDriver:
	extends CarController
	func get_throttle() -> float:
		return 0.0


## Tine masina pe lateralul dorit al unui tronson cu borduri si masoara tremurul
## antenei (RMS al deplasarii varfului pe cadru) si nivelul mediu de zdranganeala.
func _ride_ant(race: Race, track: Track, spots: Array[int], lat_from_edge: float,
		speed: float) -> Vector2:
	var car := race.player
	car.set_controller(HoldDriver.new())
	var i0 := spots[spots.size() / 3]
	var side := track._side_at(i0)
	var w := track.width_at_index(i0)
	var pos: Vector3 = track.baked[i0] + side * (w - lat_from_edge)
	var tang: Vector3 = track.baked[(i0 + 3) % track.baked.size()] - track.baked[i0]
	tang.y = 0.0
	tang = tang.normalized()
	car.global_transform = Transform3D(Basis.looking_at(tang, Vector3.UP), pos + Vector3.UP * 0.6)
	car.linear_velocity = tang * speed
	car.angular_velocity = Vector3.ZERO
	car.race_active = true
	car.road_index = i0
	car.last_safe_index = i0
	race.state = Race.State.RUNNING
	var prev := Vector3.ZERO
	var sq := 0.0
	var n := 0
	var level := 0.0
	for f in 90:
		var idx := track.closest_index(car.road_index, car.global_position)
		var s2 := track._side_at(idx)
		var w2 := track.width_at_index(idx)
		var t2: Vector3 = track.baked[(idx + 3) % track.baked.size()] - track.baked[idx]
		t2.y = 0.0
		t2 = t2.normalized()
		var lat := (car.global_position - track.baked[idx]).dot(s2)
		var want := w2 - lat_from_edge
		var v := t2 * speed + s2 * clampf((want - lat) * 6.0, -3.0, 3.0)
		v.y = car.linear_velocity.y
		car.linear_velocity = v
		car.rotation.y = atan2(-t2.x, -t2.z)
		await get_tree().physics_frame
		if f >= 20:
			var l := _top_lean(car)
			if n > 0:
				sq += (l - prev).length_squared()
			prev = l
			n += 1
			level += car.toy_rattle
	return Vector2(sqrt(sq / float(maxi(n - 1, 1))), level / float(maxi(n, 1)))
