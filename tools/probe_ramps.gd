extends Node
## Inventar + airtime pentru rampele de saritura ale unei piste (issue #610).
##
## Gaseste in pista corpurile fizice de tip rampa (nume: Ramp, FlyoffRamp,
## ChannelKicker, RampNear/RampFar) si MeshInstance-ul Hummock, le tipareste cu
## semnatura de COLIZIUNE (AABB + aria triunghiurilor: dovada ca profilul de
## rulare nu s-a schimbat) si, cu --drive, trece o masina peste fiecare si
## masoara airtime-ul si inaltimea maxima peste cota buzei.
##
## Ruleaza CA SCENA (autoload-uri). `--track=` = INDEXUL din GameState.TRACK_SCENES
## (sau numarul scenei, vezi resolve_track_index); tipareste pista incarcata.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRamps.tscn -- --track=0
##   ... -- --track=0 --drive [--speed=30] [--car=0] [--only=0]
##
## Exit 1 daca nu gaseste nicio rampa (o garda care nu masoara nimic e goala,
## nu verde).

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const RAMP_NAMES: Array[String] = ["Ramp", "FlyoffRamp", "ChannelKicker", "RampNear", "RampFar"]

var _track: Track
var _speed: float = 30.0
var _car_index: int = 0
var _drive: bool = false
var _classes: bool = false
var _cams: bool = false
var _only: int = -1
var _run_up: float = 45.0


func _ready() -> void:
	var idx := 0
	var scene_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--scene="):
			scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--speed="):
			_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--car="):
			_car_index = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--only="):
			_only = int(arg.trim_prefix("--only="))
		elif arg.begins_with("--runup="):
			_run_up = float(arg.trim_prefix("--runup="))
		elif arg == "--cams":
			_cams = true
		elif arg == "--classes":
			_classes = true
		elif arg == "--drive":
			_drive = true
	if scene_path != "":
		idx = 0
	if idx < 0:
		print("probe_ramps: pista necunoscuta")
		get_tree().quit(2)
		return
	await get_tree().process_frame
	_track = (load(scene_path if scene_path != "" else GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	print("")
	print("=== RAMPE - %s (indice %d) ===" % [scene_path if scene_path != "" else GameState.track_label(idx), idx])
	var ramps := _find_ramps()
	if ramps.is_empty():
		print("nicio rampa (corp fizic cu nume din %s, sau Hummock)" % str(RAMP_NAMES))
		get_tree().quit(1)
		return
	if _classes:
		print("clase triplanare pe pista: %s" % str(Palette._tri_mats.keys()))
	var k := 0
	for r: Dictionary in ramps:
		print("[%d] %-14s frac=%.3f  aabb=%s  col_area=%.1f  tri=%d  mat=%s" % [
			k, r["name"], r["frac"], r["aabb"], r["area"], r["tris"], r["mat"]])
		if _cams:
			_print_cams(r)
		k += 1
	if _drive:
		k = 0
		print("")
		print("  rampa   viteza   airtime  vy_lip  y_max_peste_buza  zbor_m  repus")
		for r: Dictionary in ramps:
			if _only < 0 or _only == k:
				await _run_one(k, r)
			k += 1
	get_tree().quit()


func _find_ramps() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child in _track.get_children():
		var nm := String(child.name)
		var is_body: bool = child is StaticBody3D and nm.rstrip("0123456789") in RAMP_NAMES
		# Al doilea corp cu acelasi nume iese "@StaticBody3D@N" (Godot nu-l
		# uniformizeaza), dar numele pe care garzile il cunosc trebuie sa ramana
		# "Ramp": il recunoastem dupa forma (prisma mica, 1.5-4.5 m inaltime).
		var anon := child is StaticBody3D and nm.begins_with("@StaticBody3D@") and _small_wedge(child)
		if anon:
			is_body = true
			nm = "Ramp?"
		var is_hum := child is MeshInstance3D and nm.begins_with("Hummock")
		if not (is_body or is_hum):
			continue
		var tri_points := PackedVector3Array()
		var area := 0.0
		var mat := "-"
		if is_body:
			for sh in child.get_children():
				if sh is CollisionShape3D and (sh as CollisionShape3D).shape is ConcavePolygonShape3D:
					tri_points = ((sh as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces()
			# Perechea vizuala: MeshInstance-ul adaugat chiar inainte de corp.
			var prev := _track.get_child(child.get_index() - 1)
			if prev is MeshInstance3D:
				mat = _mat_name((prev as MeshInstance3D).material_override)
		else:
			tri_points = (child as MeshInstance3D).mesh.get_faces()
			mat = _mat_name((child as MeshInstance3D).material_override)
		if tri_points.is_empty():
			continue
		var aabb := AABB(tri_points[0], Vector3.ZERO)
		for i in tri_points.size():
			aabb = aabb.expand(tri_points[i])
			if i % 3 == 0:
				area += (tri_points[i + 1] - tri_points[i]).cross(tri_points[i + 2] - tri_points[i]).length() * 0.5
		var c := aabb.get_center()
		var bi := _nearest_index(c)
		out.append({"name": nm, "aabb": _fmt_aabb(aabb), "area": area,
			"tris": tri_points.size() / 3, "mat": mat, "center": c,
			"index": bi, "frac": _track.frac_at(bi), "points": tri_points})
	return out


## Argumente gata de lipit pentru Snapshot: vederi LIBERE in jurul rampei, din
## spate (soferul care soseste), din fata (cel care a trecut), si din lateral.
func _print_cams(r: Dictionary) -> void:
	var n := _track.baked.size()
	var i: int = r["index"]
	var dir := (_track.baked[(i + 1) % n] - _track.baked[i]).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var c: Vector3 = r["center"]
	var ext := (r["aabb"] as String)
	var cams := {
		"spate": [c - dir * 20.0 + Vector3.UP * 4.0 + side * 5.0, c],
		"fata": [c + dir * 20.0 + Vector3.UP * 4.0 - side * 5.0, c],
		"lateral": [c + side * 18.0 + Vector3.UP * 3.0, c],
		"lateral2": [c - side * 18.0 + Vector3.UP * 3.0, c],
	}
	for key: String in cams:
		var e: Vector3 = cams[key][0]
		var l: Vector3 = cams[key][1]
		print("    %-9s --eye=%.1f,%.1f,%.1f --look=%.1f,%.1f,%.1f" % [key, e.x, e.y, e.z, l.x, l.y, l.z])
	print("    sofer     --frac=%.4f --driver" % maxf(0.0, r["frac"] - 0.012))


func _small_wedge(body: Node) -> bool:
	for sh in body.get_children():
		if sh is CollisionShape3D and (sh as CollisionShape3D).shape is ConcavePolygonShape3D:
			var f := ((sh as CollisionShape3D).shape as ConcavePolygonShape3D).get_faces()
			if f.size() == 0 or f.size() / 3 > 40:
				return false
			var a := AABB(f[0], Vector3.ZERO)
			for p in f:
				a = a.expand(p)
			return a.size.y >= 1.5 and a.size.y <= 4.5 and a.size.x < 22.0 and a.size.z < 22.0
	return false


func _mat_name(m: Material) -> String:
	if m == null:
		return "null"
	var s := "%s" % m.get_class()
	if m is BaseMaterial3D:
		s += "(%s)" % (m as BaseMaterial3D).albedo_color.to_html(false)
	return s


func _fmt_aabb(a: AABB) -> String:
	return "[%.2f,%.2f,%.2f +%.2f,%.2f,%.2f]" % [a.position.x, a.position.y, a.position.z,
		a.size.x, a.size.y, a.size.z]


func _nearest_index(p: Vector3) -> int:
	var best := 0
	var bd := 1e18
	for i in _track.baked.size():
		var d := Vector2(_track.baked[i].x - p.x, _track.baked[i].z - p.z).length_squared()
		if d < bd:
			bd = d
			best = i
	return best


func _run_one(k: int, r: Dictionary) -> void:
	var n := _track.baked.size()
	var pts: PackedVector3Array = r["points"]
	var center_i: int = r["index"]
	var dir := (_track.baked[(center_i + 1) % n] - _track.baked[center_i]).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var lip_y := -1e9
	var min_s := 1e9
	var c: Vector3 = r["center"]
	for p in pts:
		lip_y = maxf(lip_y, p.y)
		min_s = minf(min_s, (p - c).dot(dir))
	var lateral := (c - _track.baked[center_i]).dot(side)
	var entry := c + dir * min_s
	var back := _nearest_index(entry)
	var walked := 0.0
	while walked < _run_up:
		var prev := ((back - 1) % n + n) % n
		walked += _track.baked[prev].distance_to(_track.baked[back])
		back = prev
	var start := _track.baked[back] + side * lateral
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[_car_index])
	car.track = _track
	var sdir := (_track.baked[(back + 1) % n] - _track.baked[back]).normalized()
	car.global_transform = Transform3D(Basis.looking_at(sdir, Vector3.UP), start + Vector3.UP * 0.6)
	car.velocity = sdir * _speed
	car.road_index = back
	car.last_safe_index = back
	var ai := AIController.new()
	car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260610
	ai.configure(_track, rng)
	ai.line_offset = lateral
	car.race_active = true
	var respawned := false
	car.respawned.connect(func(_c: Car) -> void: respawned = true)
	var t := 0.0
	var air := 0.0
	var best_air := 0.0
	var was_air := false
	var vy_lip := 0.0
	var ymax := -1e9
	var armed := false
	var lift_pos := Vector3.ZERO
	var land_pos := Vector3.ZERO
	while t < 7.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var p := car.global_position
		var s_in := (p - c).dot(dir) - min_s
		if not armed and s_in > 0.0:
			armed = true
		if not armed:
			continue
		ymax = maxf(ymax, p.y)
		var fl := car.is_on_floor()
		if not fl:
			if not was_air:
				if best_air == 0.0:
					vy_lip = car.velocity.y
					lift_pos = p
				air = 0.0
			air += 1.0 / 60.0
			was_air = true
		elif was_air:
			if air > best_air:
				best_air = air
				land_pos = p
			was_air = false
			if air > 0.15:
				break
			air = 0.0
		if respawned:
			break
	print("  [%d]    %4.0f m/s  %5.2f s  %+5.1f   %5.2f           %5.1f   %s   (lat=%.1f)" % [
		k, _speed, best_air, vy_lip, ymax - lip_y,
		lift_pos.distance_to(land_pos) if best_air > 0.0 else 0.0,
		str(respawned), lateral])
	car.queue_free()
	await get_tree().process_frame
