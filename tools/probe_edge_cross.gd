extends Node
## Inventarul IESIRII si INTRARII de pe drum (issue #607/#608, Okinawa).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeEdgeCross.tscn -- --track=20
##   ... -- --track=20 --step=1.5 --report-all
##
## `--track=N` e numarul din NUMELE FISIERULUI (20 = Okinawa, indexul 13 in
## GameState). Ruleaza ca SCENA (car.gd cere autoload-uri).
##
## Intrebarea: „poate masina sa treaca din banda spre exterior, si de pe teren
## inapoi pe asfalt?". Raspunsul vine de la o masina REALA, nu din socoteli pe
## cutii: la fiecare `--step` % din tur, pe fiecare parte, o masina cu gaz
## apasat si un volan care tine un cap fix (35 grade fata de drum) pleaca
##   - IESIRE: de la 0.6 din semilatime, spre exterior; reusita = ajunge la
##     semilatime + 8 m;
##   - INTRARE: de la semilatime + 10 m, spre axa; reusita = ajunge sub
##     semilatime (e „pe drum" dupa `is_on_road`).
## Un start fara pamant (mare / prapastie: terenul la > 3 m de cota soselei sau
## sub linia apei) nu se numara: se raporteaza separat, ca „nu e teren".
##
## Pentru fiecare esec, o scanare statica spune DE CE: un gabarit de masina e
## plimbat lateral din jumatate in jumatate de metru, si se noteaza primul corp
## atins, plus cea mai mare treapta de teren intre doua esantioane.

const CAR_W: float = 2.2
const CAR_H: float = 1.2
const CAR_L: float = 3.6

const FRAMES: int = 200
const HEAD_DEG: float = 35.0
const SPEED: float = 14.0
const EXIT_EXTRA: float = 8.0
const ENTRY_OFFSET: float = 10.0

class HeadingController extends CarController:
	var target_dir: Vector3 = Vector3.FORWARD
	func get_steer() -> float:
		var f := -car.global_transform.basis.z
		f.y = 0.0
		f = f.normalized()
		var t := target_dir
		t.y = 0.0
		t = t.normalized()
		var cr := f.cross(t).y # >0: tinta e la stanga
		var d := f.dot(t)
		var ang := atan2(cr, d)
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0

var _track: Track
var _frac_step: float = 0.015
var _report_all: bool = false
var _rows: Array = []
var _tag: String = "run"


func _ready() -> void:
	var only := 20
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--step="):
			_frac_step = float(arg.trim_prefix("--step=")) / 100.0
		elif arg == "--report-all":
			_report_all = true
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	var path := "res://scenes/tracks/Track%02d.tscn" % only
	_track = (load(path) as PackedScene).instantiate() as Track
	add_child(_track)
	for i in 6:
		await get_tree().physics_frame
	await _run()


func _ground(x: float, z: float, y_ref: float) -> Dictionary:
	var space := get_viewport().world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, y_ref + 25.0, z),
		Vector3(x, y_ref - 60.0, z))
	var hit := space.intersect_ray(q)
	return hit


func _run() -> void:
	var baked: PackedVector3Array = _track.baked
	var n := baked.size()
	var sea_y := -INF
	if _track.theme_flag("water", false):
		sea_y = _track._sampler.mean_road_y() + _track.sea_level_offset
	var count := int(1.0 / _frac_step)
	var ex_ok := 0
	var ex_bad := 0
	var ex_none := 0
	var en_ok := 0
	var en_bad := 0
	var en_none := 0
	var lines: Array[String] = []
	var dry_wall := 0
	for k in count:
		var frac := float(k) * _frac_step
		var idx := int(frac * float(n)) % n
		var here := baked[idx]
		var dir := (baked[(idx + 4) % n] - here)
		dir.y = 0.0
		dir = dir.normalized()
		var side := dir.cross(Vector3.UP).normalized() # dreapta
		var hw := _track.width_at(frac)
		for s in [-1, 1]:
			var out_dir: Vector3 = side * float(s)
			var tag_side := "D" if s > 0 else "S"
			# --- IESIRE ---
			var p_in := here + out_dir * hw * 0.6
			var tgt_out := (dir * cos(deg_to_rad(HEAD_EGE())) + out_dir * sin(deg_to_rad(HEAD_EGE()))).normalized()
			var r_out := await _trial(idx, here, p_in, tgt_out, out_dir, hw, true, sea_y)
			# --- INTRARE ---
			var p_out := here + out_dir * (hw + ENTRY_OFFSET)
			var tgt_in := (dir * cos(deg_to_rad(HEAD_EGE())) - out_dir * sin(deg_to_rad(HEAD_EGE()))).normalized()
			var r_in := await _trial(idx, here, p_out, tgt_in, out_dir, hw, false, sea_y)
			var why_out := ""
			var why_in := ""
			if r_out["status"] == "bad":
				why_out = "ma opreste: %s | %s" % [r_out["stuck"], _scan(here, out_dir, dir, hw, sea_y)]
			if r_in["status"] == "bad":
				why_in = "ma opreste: %s | %s" % [r_in["stuck"], _scan(here, out_dir, dir, hw, sea_y)]
			# ZID INVIZIBIL PE USCAT: peretele de margine (`OuterWall`) e justificat
			# doar langa apa. Daca masina a fost oprita de el si dincolo de
			# margine nu e apa (aceeasi regula ca `_build_walls`), e bug.
			for why: String in [why_out, why_in]:
				if why.contains("OuterWall") and not _wet_near(idx, s, sea_y):
					dry_wall += 1
					lines.append("  ^ ZID INVIZIBIL PE USCAT la frac %.3f %s" % [frac, tag_side])
			match r_out["status"]:
				"ok": ex_ok += 1
				"bad": ex_bad += 1
				_: ex_none += 1
			match r_in["status"]:
				"ok": en_ok += 1
				"bad": en_bad += 1
				_: en_none += 1
			if _report_all or r_out["status"] == "bad" or r_in["status"] == "bad":
				lines.append("frac %.3f %s  EXIT %-4s (lat %.1f/%.1f v%.1f)%s | ENTRY %-4s (lat %.1f v%.1f dy%+.1f)%s" % [
					frac, tag_side, r_out["status"], r_out["lat"], hw + EXIT_EXTRA, r_out["speed"],
					(" [" + why_out + "]") if why_out != "" else "",
					r_in["status"], r_in["lat"], r_in["speed"], r_in["dy"],
					(" [" + why_in + "]") if why_in != "" else ""])
	for l in lines:
		print(l)
	print("")
	print("zid invizibil pe uscat: %d" % dry_wall)
	print("TOTAL %s  exit ok %d / blocat %d / fara-teren %d   |   intrare ok %d / blocata %d / fara-teren %d" % [
		_tag, ex_ok, ex_bad, ex_none, en_ok, en_bad, en_none])
	print("VERDICT: ", "PICAT" if dry_wall > 0 else "OK")
	get_tree().quit(1 if dry_wall > 0 else 0)


func HEAD_EGE() -> float:
	return HEAD_DEG


## Un incercare. status: ok / bad / none.
func _trial(idx: int, axis: Vector3, start_xz: Vector3, tgt: Vector3,
		out_dir: Vector3, hw: float, is_exit: bool, sea_y: float) -> Dictionary:
	var g := _ground(start_xz.x, start_xz.z, axis.y)
	var res := {"status": "none", "lat": 0.0, "speed": 0.0, "dy": 0.0}
	if g.is_empty():
		return res
	var gy: float = (g["position"] as Vector3).y
	if absf(gy - axis.y) > 3.0 or gy < sea_y + 0.05:
		return res
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	car.track = _track
	_track.add_child(car)
	car.global_position = Vector3(start_xz.x, gy + 0.7, start_xz.z)
	car.look_at(car.global_position + tgt, Vector3.UP)
	car.road_index = idx
	car.race_active = true
	var c := HeadingController.new()
	c.target_dir = tgt
	car.set_controller(c)
	car.linear_velocity = tgt * SPEED
	var best := -1e9 if is_exit else 1e9
	var ok := false
	var slow_frames := 0
	for f in FRAMES:
		await get_tree().physics_frame
		if not is_instance_valid(car):
			break
		var off := car.global_position - axis
		var lat := off.dot(out_dir)
		if is_exit:
			best = maxf(best, lat)
			if lat >= hw + EXIT_EXTRA:
				ok = true
				break
		else:
			if lat < best:
				best = lat
				res["dy"] = car.global_position.y - axis.y
			var ridx := _track.closest_index_global(car.global_position)
			if _track.is_on_road(ridx, car.global_position) 					or (lat <= hw - 0.5 and absf(off.y) < 2.5):
				ok = true
				break
		if car.horizontal_speed() < 1.5 and f > 30:
			slow_frames += 1
			if slow_frames > 40:
				break
	res["speed"] = car.horizontal_speed() if is_instance_valid(car) else 0.0
	res["lat"] = best
	res["stuck"] = ""
	if not ok and is_instance_valid(car) and car.horizontal_speed() < 3.0:
		res["stuck"] = _what_stops(car, tgt)
	res["status"] = "ok" if ok else "bad"
	if is_instance_valid(car):
		car.queue_free()
	await get_tree().physics_frame
	return res


## De ce: gabaritul plimbat lateral; primul corp atins si cea mai mare treapta.
func _scan(axis: Vector3, out_dir: Vector3, dir: Vector3, hw: float, sea_y: float) -> String:
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
	while d <= hw + ENTRY_OFFSET + 1.0:
		var p := axis + out_dir * d
		var g := _ground(p.x, p.z, axis.y)
		if g.is_empty():
			d += 0.5
			continue
		var gy: float = (g["position"] as Vector3).y
		var st := gy - prev_y
		if absf(st) > absf(max_step) and absf(st) < 6.0:
			max_step = st
			step_at = d
		prev_y = gy
		if first_body == "":
			q.transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
				Vector3(p.x, gy + 0.45 + CAR_H * 0.5, p.z))
			for h in space.intersect_shape(q, 8):
				var col := h["collider"] as Node
				if col == null:
					continue
				first_body = "%s<%s>" % [col.name, col.get_class()]
				first_at = d
				break
		d += 0.5
	return "corp %s la %.1f m; treapta max %+.2f m la %.1f m" % [
		first_body if first_body != "" else "-", first_at, max_step, step_at]


## Ce sta in fata unei masini ramase pe loc: corpurile din jurul botului ei.
func _what_stops(car: Car, tgt: Vector3) -> String:
	var space := get_viewport().world_3d.direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_W + 1.2, 1.0, CAR_L + 1.2)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.collide_with_areas = false
	q.exclude = [car.get_rid()]
	var names: Array[String] = []
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	var base := car.global_position + fwd.normalized() * 1.2
	for dy in [0.1, 0.6]:
		q.transform = Transform3D(Basis.looking_at(fwd.normalized(), Vector3.UP),
			base + Vector3.UP * (dy + 0.5))
		for h in space.intersect_shape(q, 12):
			var col := h["collider"] as Node
			if col == null:
				continue
			var nm := "%s" % col.name
			if col.get_parent() != null:
				nm = "%s/%s" % [col.get_parent().name, col.name]
			if not names.has(nm):
				names.append(nm)
	return ", ".join(names) if not names.is_empty() else "nimic-gasit"


## Ca `_wet_beyond`, dar si pe vecinii din +-20 m: peretele se emite pe segmente
## de ~1 m, iar masina il atinge la cativa metri de capatul lui.
func _wet_near(idx: int, side_sign: int, sea_y: float) -> bool:
	var baked: PackedVector3Array = _track.baked
	var n := baked.size()
	for di: int in [-20, -10, 0, 10, 20]:
		var i := (idx + di + n * 2) % n
		var d := baked[(i + 4) % n] - baked[i]
		d.y = 0.0
		var out_dir: Vector3 = d.normalized().cross(Vector3.UP).normalized() * float(side_sign)
		if _wet_beyond(baked[i], out_dir, _track.width_at_index(i), sea_y):
			return true
	return false


## Dincolo de marginea soselei e apa? (regula din `_build_walls`: fundul sub
## oglinda marii la 3, 8 sau 15 m in afara).
func _wet_beyond(axis: Vector3, out_dir: Vector3, hw: float, sea_y: float) -> bool:
	for k: float in [3.0, 8.0, 15.0]:
		var q := axis + out_dir * (hw + k)
		if _track._sampler.ground_y(q.x, q.z) < sea_y:
			return true
	return false
