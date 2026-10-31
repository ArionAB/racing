extends Node
## Garda #617 (Stromboli): repunerea de la vulcan trebuie sa lase elan pentru
## rampa de peste cuva craterului.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeStromboliRamp.tscn
##   ... -- --mode=runup            tabel: cat de in spate vs viteza la buza
##   ... -- --mode=respawn          repunere FORTATA din fiecare punct al zonei
##   ... -- --mode=respawn --old    retragerea veche (regula zonei oprita)
##   ... -- --cars=3,0,1            masinile (indici CAR_DATA); implicit 3 (autobuz,
##                                   cea mai lenta la accelerare), 0, 1
##
## Masina de proba tine gazul la fund si vireaza dupa axa soselei (ca un
## jucator care nu greseste): masoara FIZICA rampei, nu AI-ul. Reusit = aterizeaza
## pe sosea DUPA buza de aterizare, fara o noua repunere.
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const WATCH_S: float = 14.0
## Elanul pe care il cere garda #617 intre repunere si buza (m).
const MIN_RUNUP_M: float = 60.0

class PursuitController extends CarController:
	var track: Track
	var idx: int = 0
	func update(_d: float) -> void:
		idx = track.closest_index(idx, car.global_position)
	func get_steer() -> float:
		var n := track.baked.size()
		var target := track.baked[(idx + 6) % n]
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var t := target - car.global_position
		t.y = 0.0
		if f.length() < 0.01 or t.length() < 0.01:
			return 0.0
		var ang := atan2(f.normalized().cross(t.normalized()).y, f.normalized().dot(t.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0

var _track: Track
var _ch: Dictionary = {}
var _cars: Array[int] = [3, 0, 1]
var _mode: String = "respawn"
var _old: bool = false
var _spacing: float = 1.0
var _trace: bool = false
var _drop: float = 2.4
var _backs: Array = [14.0, 25.0, 40.0, 60.0, 70.0]
var _v0s: Array = [8.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 18.0, 20.0]


func _ready() -> void:
	var track_idx := 4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.trim_prefix("--mode=")
		elif a == "--old":
			_old = true
		elif a.begins_with("--cars="):
			_cars.clear()
			for s in a.trim_prefix("--cars=").split(","):
				_cars.append(int(s))
		elif a.begins_with("--drop="):
			_drop = float(a.trim_prefix("--drop="))
		elif a == "--trace":
			_trace = true
		elif a.begins_with("--v0s="):
			_v0s.clear()
			for q in a.trim_prefix("--v0s=").split(","):
				_v0s.append(float(q))
		elif a.begins_with("--track="):
			track_idx = int(a.trim_prefix("--track="))
	await get_tree().process_frame
	_track = (load(GameState.TRACK_SCENES[track_idx]) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	for ch: Dictionary in _track.get("_channels"):
		if bool(ch.get("jump", false)):
			_ch = ch
			break
	if _ch.is_empty():
		print("fara canal cu jump")
		get_tree().quit(1)
		return
	if _old:
		# Regula veche: fara elan minim si fara oprirea dincolo de gol.
		_ch["respawn_runup_m"] = 0.0
		_ch["respawn_past_gap"] = false
	var n := _track.baked.size()
	_spacing = float(_track.get("_dists")[n]) / float(n)
	print("== %s | near %d far %d | pas %.2f m | gap %.2f | respawn_past_gap=%s runup=%s ==" % [
		_track.track_name, int(_ch["near"]), int(_ch["far"]), _spacing, float(_ch["gap"]),
		str(_ch.get("respawn_past_gap", false)), str(_ch.get("respawn_runup_m", 0.0))])
	var fails := 0
	if _mode == "bowl":
		get_tree().quit(await _bowl())
		return
	for ci in _cars:
		print("-- %s (acc %.1f) --" % [GameState.CAR_DATA[ci].display_name,
			(GameState.CAR_DATA[ci] as CarData).acceleration])
		if _mode == "stat":
			# Raza de ratare cu abateri laterale (un jucator nu vine perfect pe axa).
			for back_m in _backs:
				var fails_b := 0
				var tot := 0
				for lat in [-2.5, -1.5, -0.7, 0.0, 0.7, 1.5, 2.5]:
					var r := await _run(ci, _idx_back(back_m), false, back_m, 9.0, lat)
					tot += 1
					if not r["ok"]:
						fails_b += 1
				print("  %5.0f m in spate: %d din %d ratate" % [back_m, fails_b, tot])
		elif _mode == "minv":
			# Viteza minima la buza: pornire la 6 m, cu viteza v0 data direct.
			for v0 in _v0s:
				var r := await _run(ci, _idx_back(6.0), false, 6.0, v0)
				print("  v0 %4.1f -> v_buza %5.1f  %s" % [v0, r["v"], "TRECUT" if r["ok"] else "RATAT"])
		elif _mode == "runup":
			for back_m in [14.0, 30.0, 50.0, 70.0, 90.0, 110.0, 130.0]:
				var r := await _run(ci, _idx_back(back_m), false, back_m)
				print("  %5.0f m in spate: v_buza %5.1f  %s" % [back_m, r["v"], "TRECUT" if r["ok"] else "RATAT"])
		else:
			# last_safe_index de la 120 m inainte de buza pana la 60 m dupa aterizare.
			var near: int = _ch["near"]
			var far: int = _ch["far"]
			var from_i := near - int(120.0 / _spacing)
			var to_i := far + int(60.0 / _spacing)
			var step := maxi(int(6.0 / _spacing), 1)
			var i := from_i
			while i <= to_i:
				var r := await _run(ci, posmod(i, n), true, 0.0)
				var tag := "TRECUT" if r["ok"] else "RATAT "
				print("  last_safe %+4.0f m fata de buza: repus la %6.1f m in spate (%s) v_buza %5.1f  %s" % [
					float(i - near) * _spacing, r["back"], r["where"], r["v"], tag])
				if not r["ok"]:
					fails += 1
				# Contractul #617: inainte de golul de aterizare, repunerea lasa
				# cel putin MIN_RUNUP_M pana la buza; dupa el, nu cade inapoi in gol.
				var back: float = r["back"]
				if i <= far:
					if back < MIN_RUNUP_M - 1.0:
						fails += 1
						print("    ^ CONTRACT: elan %.1f m < %.0f m" % [back, MIN_RUNUP_M])
				elif back > -(float(far - near) * _spacing + 2.0):
					fails += 1
					print("    ^ CONTRACT: repus in gol / pe rampa (%.1f m)" % back)
				i += step
	print("RATARI: %d" % fails)
	get_tree().quit(1 if fails > 0 and _mode == "respawn" else 0)


## Indexul aflat la `m` metri INAINTE de buza de plecare.
func _idx_back(m: float) -> int:
	var n := _track.baked.size()
	return posmod(int(_ch["near"]) - int(m / _spacing), n)


func _run(car_i: int, index: int, via_respawn: bool, back_m: float,
		v0: float = 9.0, lat: float = 0.0) -> Dictionary:
	var n := _track.baked.size()
	var near: int = _ch["near"]
	var far: int = _ch["far"]
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[car_i])
	car.track = _track
	var pc := PursuitController.new()
	pc.track = _track
	car.set_controller(pc)
	var res := {"ok": false, "v": 0.0, "back": 0.0, "where": ""}
	car.race_active = true
	if via_respawn:
		# Masina e pusa in pozitia de la care ar fi cazut, apoi repusa cu
		# retragerea implicita a celor 12-14 m (rata, blocaj, buton), exact ca in joc.
		var p := _track.baked[index]
		car.global_position = p + Vector3.UP * 1.5
		car.road_index = index
		car.last_safe_index = index
		car.last_safe_route = 0
		await get_tree().physics_frame
		car.respawn(14.0)
		await get_tree().physics_frame
		var ri := _track.closest_index_global(car.global_position, 0)
		res["back"] = float(posmod(near - ri, n)) * _spacing
		if posmod(ri - near, n) < n / 2:
			res["back"] = -float(posmod(ri - near, n)) * _spacing
		res["where"] = "inainte" if float(res["back"]) > 0.0 else "DUPA/PE gol"
	else:
		var p2 := _track.baked[index]
		var d := (_track.baked[(index + 1) % n] - p2).normalized()
		p2 += d.cross(Vector3.UP).normalized() * lat
		car.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), p2 + Vector3.UP * 0.6)
		car.velocity = d * v0
		car.road_index = index
		car.last_safe_index = index
	pc.idx = car.road_index
	# Cutie, nu bool: lambda-urile GDScript captureaza variabilele locale prin valoare.
	var rflag: Array[bool] = [false]
	car.respawned.connect(func(_c: Car) -> void: rflag[0] = true)
	var t := 0.0
	var v_lip := -1.0
	var done_ok := false
	while t < WATCH_S:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var ri := _track.closest_index_global(car.global_position, 0)
		if _trace and int(round(t * 60.0)) % 4 == 0:
			var rel := float(posmod(ri - near + n / 2, n) - n / 2) * _spacing
			if absf(rel) < 40.0:
				print("    t=%.2f rel=%+6.1f y=%6.2f dy_road=%+5.2f v=%5.1f vy=%+5.1f floor=%s" % [
					t, rel, car.global_position.y, car.global_position.y - _track.baked[ri].y,
					Vector2(car.velocity.x, car.velocity.z).length(), car.velocity.y,
					str(car.is_on_floor())])
		if v_lip < 0.0 and posmod(ri - near, n) < n / 2 and posmod(ri - near, n) >= 0 and ri != near and posmod(near - ri, n) > n / 2:
			v_lip = Vector2(car.velocity.x, car.velocity.z).length()
		if rflag[0]:
			break
		var past := posmod(ri - far, n)
		if past > int(6.0 / _spacing) and past < n / 4 and car.is_on_floor() \
				and absf(car.global_position.y - _track.baked[ri].y) < 3.5:
			done_ok = true
			break
	res["ok"] = done_ok and not rflag[0]
	res["v"] = maxf(v_lip, 0.0)
	car.queue_free()
	await get_tree().physics_frame
	return res


## Cazut in cuva (nu in apa/prapastie): masina ramane PE FUNDUL cuvei, la ~3 m
## sub drum, si CraterFall trebuie s-o prinda — altfel sta acolo pana scoate
## watchdog-ul ceva. Reusit = repusa, la >= 60 m inaintea buzei.
func _bowl() -> int:
	var zone: Area3D = null
	for c in _track.get_children():
		if c.name == "CraterFall":
			zone = c as Area3D
	if zone == null:
		print("fara CraterFall")
		return 1
	if _old:
		# Zona veche: tavan la 56,3 (centru 50,05, inaltime 12,5).
		zone.position.y = 50.05
		(zone.get_node("Shape") as CollisionShape3D).shape = (
			BoxShape3D.new() as BoxShape3D)
		((zone.get_node("Shape") as CollisionShape3D).shape as BoxShape3D).size = Vector3(30, 12.5, 30)
	var near: int = _ch["near"]
	var n := _track.baked.size()
	var bad := 0
	for ci in _cars:
		var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
		add_child(car)
		car.apply_data(GameState.CAR_DATA[ci])
		car.track = _track
		car.race_active = true
		var lip := _track.baked[near]
		var far_lip := _track.baked[int(_ch["far"])]
		var mid := (lip + far_lip) * 0.5
		# Fundul cuvei: ~3,2 m sub drum (masurat in urma: dy_road -3.19).
		# `--drop` ramane pe centrul cuvei; implicit masina se pune pe CORNISA de sub
		# buza de aterizare (1 m inaintea ei), unde a ramas masurat un esec
		# (dy_road -3,19) — in afara zonei vechi, care incepea doar la 56,3.
		var spot := mid
		if _drop == 2.4:
			var along := (far_lip - lip)
			along.y = 0.0
			spot = far_lip - along.normalized() * 1.0
			car.global_position = Vector3(spot.x, lip.y - 3.0, spot.z)
		else:
			car.global_position = Vector3(spot.x, lip.y - _drop, spot.z)
		car.road_index = near
		car.last_safe_index = near
		var rf: Array[bool] = [false]
		car.respawned.connect(func(_c: Car) -> void: rf[0] = true)
		for f in 120:
			await get_tree().physics_frame
			if rf[0]:
				break
		var respawned: bool = rf[0]
		if _trace:
			var sh := zone.get_node("Shape") as CollisionShape3D
			print("    zona y=%.2f size=%s | masina y=%.2f mask=%d layer=%d zmask=%d" % [
				zone.global_position.y, str((sh.shape as BoxShape3D).size),
				car.global_position.y, car.collision_mask, car.collision_layer, zone.collision_mask])
		var back := 0.0
		if respawned:
			back = float(posmod(near - _track.closest_index_global(car.global_position, 0), n)) * _spacing
		var ok := respawned and back >= 60.0
		print("  %s: cazut pe fundul cuvei -> %s, elan %.1f m  %s" % [
			GameState.CAR_DATA[ci].display_name, "repus" if respawned else "RAMANE IN CUVA",
			back, "OK" if ok else "RATAT"])
		if not ok:
			bad += 1
		car.queue_free()
		await get_tree().physics_frame
	print("BOWL RATARI: %d" % bad)
	return 1 if bad > 0 else 0
