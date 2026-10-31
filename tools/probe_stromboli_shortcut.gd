extends Node
## Garda #616 (Stromboli): de pe scurtatura (sau de langa ea) se poate urca
## inapoi pe scurtatura?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeStromboliShortcut.tscn
##   ... -- --mode=edge     din EXTERIOR, de pe teren, spre banda, in sensul cursei
##   ... -- --mode=climb    din OPRIRE, cu botul in sus pe banda (contra sensului),
##                          de pe banda si de pe sosea, dupa iesire
##   ... -- --mode=all      (implicit) amandoua
##   ... -- --no-smooth     SABOTAJ: terenul langa banda ca inainte de #616
##                          (cota celui mai apropiat punct copt, pe trepte)
##   ... -- --cars=3,1,0    masinile (indici CAR_DATA); implicit 3 (autobuz), 1, 0
##   ... -- --step=2        pasul pe index al esantionarii (puncte coapte)
##   ... -- --speed=0 --head=70 --off=4   cum porneste masina din exterior
##   ... -- --allow=1       cate blocari sunt acceptate (vezi VERDICT)
##
## Masina REALA (Car.tscn), gazul la fund. Un esec tipareste de ce: corpul
## atins de gabaritul masinii si cea mai mare treapta de teren in lateral.
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const CAR_W: float = 2.2
const CAR_H: float = 1.2
const CAR_L: float = 3.6


class AimController extends CarController:
	var target_fn: Callable
	func get_steer() -> float:
		var target: Vector3 = target_fn.call()
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var t := target - car.global_position
		t.y = 0.0
		if f.length() < 0.01 or t.length() < 0.01:
			return 0.0
		var ang := atan2(f.normalized().cross(t.normalized()).y,
			f.normalized().dot(t.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0


var _track: Track
var _br: TrackRoute
var _cars: Array[int] = [3, 1, 0]
var _step: int = 2
var _allow: int = 1
var _no_smooth: bool = false
var _mode: String = "all"
var _speed: float = 0.0
var _head: float = 70.0
var _off: float = 4.0


func _ready() -> void:
	var track_idx := 4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.trim_prefix("--mode=")
		elif a.begins_with("--step="):
			_step = int(a.trim_prefix("--step="))
		elif a.begins_with("--allow="):
			_allow = int(a.trim_prefix("--allow="))
		elif a == "--no-smooth":
			_no_smooth = true
		elif a.begins_with("--speed="):
			_speed = float(a.trim_prefix("--speed="))
		elif a.begins_with("--head="):
			_head = float(a.trim_prefix("--head="))
		elif a.begins_with("--off="):
			_off = float(a.trim_prefix("--off="))
		elif a.begins_with("--track="):
			track_idx = int(a.trim_prefix("--track="))
		elif a.begins_with("--cars="):
			_cars.clear()
			for s in a.trim_prefix("--cars=").split(","):
				_cars.append(int(s))
	await get_tree().process_frame
	_track = (load(GameState.TRACK_SCENES[track_idx]) as PackedScene).instantiate() as Track
	if _no_smooth:
		# Sabotaj: cota benzii din cel mai apropiat punct copt (comportamentul vechi).
		_track.branch_smooth_level = false
	add_child(_track)
	for i in 8:
		await get_tree().physics_frame
	_br = _track.route_at(1)
	if _br == null:
		print("fara scurtatura")
		get_tree().quit(1)
		return
	print("== %s | scurtatura %d puncte, %.0f m, hw %.1f ==" % [_track.track_name,
		_br.baked.size(), _br.dists[_br.baked.size() - 1], _br.half_width])
	var bad := 0
	if _mode == "edge" or _mode == "all":
		bad += await _edge()
	if _mode == "climb" or _mode == "all":
		bad += await _climb()
	# O singura blocare e naturala: autobuzul de la k14, parte stanga, porneste
	# la 7 m de axa, in fata unui mal de 1,4 m al dealului (taietura soselei
	# principale), nu al benzii. Restul trebuie sa urce.
	print("ESECURI: %d (permise %d)" % [bad, _allow])
	print("VERDICT: ", "PICAT" if bad > _allow else "OK")
	get_tree().quit(1 if bad > _allow else 0)


func _ground(x: float, z: float, y_ref: float) -> Dictionary:
	var space := get_viewport().world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, y_ref + 25.0, z),
		Vector3(x, y_ref - 60.0, z))
	return space.intersect_ray(q)


func _spawn(car_i: int, pos: Vector3, dir: Vector3, speed: float, target_fn: Callable) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	_track.add_child(car)
	car.apply_data(GameState.CAR_DATA[car_i])
	car.track = _track
	car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), pos)
	car.race_active = true
	var c := AimController.new()
	c.target_fn = target_fn
	car.set_controller(c)
	car.velocity = dir * speed
	return car


## INTRARE din exterior, in sensul cursei, pe fiecare parte.
func _edge() -> int:
	print("-- din exterior spre banda (masina reala, %.0f m/s, %.0f grade, de la %.0f m de margine) --" % [_speed, _head, _off])
	var bad := 0
	var total := 0
	var n := _br.baked.size()
	var hw := _br.half_width
	for ci in _cars:
		for k in range(0, n - 4, _step):
			var here := _br.baked[k]
			var dir := _br.baked[mini(k + 3, n - 1)] - here
			dir.y = 0.0
			dir = dir.normalized()
			var side := dir.cross(Vector3.UP).normalized()
			for s in [-1, 1]:
				var out_dir: Vector3 = side * float(s)
				var start_xz := here + out_dir * (hw + _off)
				var g := _ground(start_xz.x, start_xz.z, here.y)
				if g.is_empty():
					continue
				var gy: float = (g["position"] as Vector3).y
				if absf(gy - here.y) > 3.0:
					continue
				var tgt := (dir * cos(deg_to_rad(_head))
					- out_dir * sin(deg_to_rad(_head))).normalized()
				var kk := k
				var car := _spawn(ci, Vector3(start_xz.x, gy + 0.7, start_xz.z), tgt, _speed,
					func() -> Vector3: return _br.baked[mini(kk + 3, n - 1)])
				var ok := false
				var slow := 0
				for f in 240:
					await get_tree().physics_frame
					var bi := _br.closest_index_global(car.global_position)
					if _track.is_on_road(bi, car.global_position, 1) \
							and absf(car.global_position.y - _br.baked[bi].y) < 2.5:
						ok = true
						break
					if f > 30 and car.horizontal_speed() < 1.5:
						slow += 1
						if slow > 40:
							break
				total += 1
				if not ok:
					bad += 1
					print("  %s k%02d (d=%3.0f) lado %s: NU URCA  %s" % [
						GameState.CAR_DATA[ci].display_name, k, _br.dists[k],
						"S" if s < 0 else "D", _why(here, out_dir, dir, hw)])
				car.queue_free()
				await get_tree().physics_frame
	print("  edge: %d din %d blocate" % [bad, total])
	return bad


## URCARE din oprire, cu botul contra sensului cursei, pana la capatul de sus.
func _climb() -> int:
	print("-- urcare din oprire, contra sensului (spre intrarea scurtaturii) --")
	var bad := 0
	var total := 0
	var n := _br.baked.size()
	var main_n := _track.baked.size()
	var starts: Array[Dictionary] = []
	for k in range(n - 1, 5, -_step * 2):
		starts.append({"pos": _br.baked[k], "tag": "banda k%02d" % k})
	var exit_main := _track.closest_index_global(_br.baked[n - 1], 0)
	var sp := float(_track.get("_dists")[main_n]) / float(main_n)
	for m in [8.0, 20.0]:
		var mi := posmod(exit_main + int(m / sp), main_n)
		starts.append({"pos": _track.baked[mi], "tag": "sosea +%.0f m dupa iesire" % m})
	for ci in _cars:
		for st: Dictionary in starts:
			var pos: Vector3 = st["pos"]
			var bi0 := _br.closest_index_global(pos)
			var dir := _br.baked[maxi(bi0 - 3, 0)] - pos
			dir.y = 0.0
			if dir.length() < 0.5:
				dir = _br.baked[n - 4] - _br.baked[n - 1]
				dir.y = 0.0
			dir = dir.normalized()
			var holder: Array = []
			var car := _spawn(ci, pos + Vector3.UP * 0.7, dir, 0.0, func() -> Vector3:
				var c: Car = holder[0]
				var bi := _br.closest_index_global(c.global_position)
				return _br.baked[clampi(bi - 6, 0, n - 1)])
			holder.append(car)
			var ok := false
			var best := n
			for f in 900:
				await get_tree().physics_frame
				var bi := _br.closest_index_global(car.global_position)
				if car.global_position.distance_to(_br.baked[bi]) < _br.half_width + 1.5:
					best = mini(best, bi)
				if best <= 3:
					ok = true
					break
			total += 1
			if not ok:
				bad += 1
				print("  %s din %s: BLOCAT la k%02d (%.0f m din %.0f), v %.1f  %s" % [
					GameState.CAR_DATA[ci].display_name, st["tag"], best,
					_br.dists[best], _br.dists[n - 1], car.horizontal_speed(),
					_what_stops(car)])
			car.queue_free()
			await get_tree().physics_frame
	print("  climb: %d din %d blocate" % [bad, total])
	return bad


func _why(axis: Vector3, out_dir: Vector3, dir: Vector3, hw: float) -> String:
	var space := get_viewport().world_3d.direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_W, CAR_H, CAR_L)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.collide_with_areas = false
	var prev_y := axis.y
	var max_step := 0.0
	var step_at := 0.0
	var first_body := ""
	var first_at := 0.0
	var d := hw * 0.6
	while d <= hw + 9.0:
		var p := axis + out_dir * d
		var g := _ground(p.x, p.z, axis.y)
		if g.is_empty():
			d += 0.5
			continue
		var gy: float = (g["position"] as Vector3).y
		var stp := gy - prev_y
		if absf(stp) > absf(max_step) and absf(stp) < 6.0:
			max_step = stp
			step_at = d
		prev_y = gy
		if first_body == "":
			q.transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
				Vector3(p.x, gy + 0.45 + CAR_H * 0.5, p.z))
			for h in space.intersect_shape(q, 8):
				var col := h["collider"] as Node
				if col != null:
					first_body = "%s<%s>" % [col.name, col.get_class()]
					first_at = d
					break
		d += 0.5
	return "corp %s la %.1f m; treapta max %+.2f m la %.1f m" % [
		first_body if first_body != "" else "-", first_at, max_step, step_at]


func _what_stops(car: Car) -> String:
	var space := get_viewport().world_3d.direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_W + 1.2, 1.0, CAR_L + 1.2)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.collide_with_areas = false
	q.exclude = [car.get_rid()]
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var names: Array[String] = []
	for dy in [0.1, 0.6]:
		q.transform = Transform3D(Basis.looking_at(fwd, Vector3.UP),
			car.global_position + fwd * 1.2 + Vector3.UP * (dy + 0.5))
		for h in space.intersect_shape(q, 12):
			var col := h["collider"] as Node
			if col != null:
				var nm := "%s" % col.name
				if col.get_parent() != null:
					nm = "%s/%s" % [col.get_parent().name, col.name]
				if not names.has(nm):
					names.append(nm)
	return "in fata: %s" % [", ".join(names) if not names.is_empty() else "nimic"]
