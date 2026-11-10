extends Node
## Sonda lantului de sarituri San Francisco (brief san_francisco.md, pasul 1).
##
## Trece fiecare masina din garaj pe strada sintetica `tools/SondaSf*.tscn`
## (generata de tools/gen_sf_sonda.py: N blocuri abrupte cu intersectii plate
## intre ele) si masoara, PE FIECARE MUCHIE, ce se intampla cand vii in lant:
## viteza la muchie, airtime, lungimea zborului, inaltimea peste sosea, viteza
## normala la aterizare, panta pe care aterizezi (pe bloc sau dincolo de el, pe
## plat), tangajul masinii fata de drum, hopurile, si incidentele (ejectare,
## repunere, rasturnare, iesire de pe carosabil).
##
## Ruleaza CA SCENA (autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfCrest.tscn -- \
##       --scene=res://tools/SondaSfAngkor.tscn
##   ... --cars=3,1          indici GameState.CAR_DATA (implicit: toate)
##   ... --modes=28,max,t1,t3   viteza de intrare: numar (m/s), `max` = plafonul
##                           masinii, `tK` = plafon + TURBO apasat cu 40 m
##                           inaintea muchiei K (o bara plina, 2,2 s)
##   ... --lats=0,-3,3       abaterea laterala tinuta (m)
##   ... --ai                AIController in loc de pilotul de proba (fara tK)
##   ... --detail            cate un rand pe muchie, nu doar rezumatul
##
## Pilotul de proba tine gazul la fund si axa strazii (tiparul
## `PursuitController` din probe_stromboli_ramp.gd): masoara GEOMETRIA, nu AI-ul.
## Strada sintetica e pe +X la z = 0, deci coordonata in lungul ei e chiar x.
##
## Exit 1 daca n-a masurat niciun zbor (o sonda care nu masoara nimic e goala,
## nu verde — memoria `garda-verde-pe-zero-masuratori`).

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Sub atat, o desprindere e hop de suspensie, nu zbor.
const FLIGHT_MIN_S: float = 0.25
const HOP_MIN_S: float = 0.08
## Panta peste care aterizarea e "pe plat" (dincolo de bloc), nu pe panta lui.
const FLAT_GRADE: float = -0.04


class StreetController extends CarController:
	var lat: float = 0.0
	var turbo_from_x: float = INF
	var fired: bool = false
	func update(_d: float) -> void:
		if not fired and car.global_position.x >= turbo_from_x:
			fired = true
			car.turbo_charge = 1.0
	func get_steer() -> float:
		var p := car.global_position
		var target := Vector3(p.x + 16.0, p.y, lat)
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var t := target - p
		t.y = 0.0
		if f.length() < 0.01:
			return 0.0
		var ang := atan2(f.normalized().cross(t.normalized()).y, f.normalized().dot(t.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0
	func is_turbo_pressed() -> bool:
		return fired


var _track: Track
var _lips: Array[Vector3] = []
var _block_len: float = 60.0
var _xs: PackedFloat32Array = PackedFloat32Array()
var _ys: PackedFloat32Array = PackedFloat32Array()
var _cars: Array[int] = []
var _modes: PackedStringArray = PackedStringArray(["28", "max", "t1", "t3"])
var _lats: Array[float] = [0.0]
var _ai: bool = false
var _detail: bool = false
var _runup: float = 70.0
## rezultate: cheie "mod|muchie" -> Array de Dictionary
var _rows: Dictionary = {}
var _by_car: Dictionary = {}


func _ready() -> void:
	var scene_path := "res://tools/SondaSfAngkor.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.trim_prefix("--scene=")
		elif arg.begins_with("--cars="):
			for s in arg.trim_prefix("--cars=").split(","):
				_cars.append(int(s))
		elif arg.begins_with("--modes="):
			_modes = arg.trim_prefix("--modes=").split(",")
		elif arg.begins_with("--lats="):
			_lats.clear()
			for s in arg.trim_prefix("--lats=").split(","):
				_lats.append(float(s))
		elif arg.begins_with("--runup="):
			_runup = float(arg.trim_prefix("--runup="))
		elif arg == "--ai":
			_ai = true
		elif arg == "--detail":
			_detail = true
	if _cars.is_empty():
		for i in GameState.CAR_DATA.size():
			_cars.append(i)
	if _ai:
		_modes = PackedStringArray(["max"])
	await get_tree().process_frame
	_track = (load(scene_path) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	if not _track.has_meta("sf_lips"):
		print("probe_sf_crest: scena n-are metadata/sf_lips (nu e o SondaSf)")
		get_tree().quit(2)
		return
	for l: Vector3 in _track.get_meta("sf_lips"):
		_lips.append(l)
	_block_len = float(_track.get_meta("sf_block_len"))
	_build_profile()
	print("")
	print("=== LANT DE SARITURI — %s | %d muchii, bloc %.0f m, plat %.0f m, profil %s | pilot: %s ===" % [
		scene_path.get_file(), _lips.size(), _block_len, float(_track.get_meta("sf_flat")),
		str(_track.get_meta("sf_profile")), "AI" if _ai else "proba (gaz la fund, pe axa)"])
	_print_baked_grades()
	if _detail:
		print("  masina        mod  lat | m  v_muchie  air   zbor   h_max  v_norm  panta_at  tangaj  hop  incidente")
	for ci in _cars:
		for mode in _modes:
			for lat in _lats:
				await _run(ci, mode, lat)
	_summary()
	var flights := 0
	for key: String in _rows:
		for r: Dictionary in _rows[key]:
			if float(r["air"]) >= FLIGHT_MIN_S:
				flights += 1
	get_tree().quit(0 if flights > 0 else 1)


## Profilul REAL (copt) al strazii: punctele cu z ~ 0, sortate dupa x.
func _build_profile() -> void:
	var pairs: Array[Vector2] = []
	for p in _track.baked:
		if absf(p.z) < 0.5:
			pairs.append(Vector2(p.x, p.y))
	pairs.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for q in pairs:
		if _xs.size() > 0 and q.x - _xs[_xs.size() - 1] < 0.05:
			continue
		_xs.append(q.x)
		_ys.append(q.y)


func _road_y(x: float) -> float:
	var i := _xs.bsearch(x)
	if i <= 0:
		return _ys[0]
	if i >= _xs.size():
		return _ys[_ys.size() - 1]
	var f := (x - _xs[i - 1]) / maxf(_xs[i] - _xs[i - 1], 0.001)
	return lerpf(_ys[i - 1], _ys[i], f)


func _road_grade(x: float) -> float:
	return (_road_y(x + 1.0) - _road_y(x - 1.0)) / 2.0


## Panta coapta pe primul bloc, din 4 in 4 m: ce a facut spline-ul din profil.
func _print_baked_grades() -> void:
	var x0 := _lips[0].x
	var parts: PackedStringArray = PackedStringArray()
	var worst := 0.0
	var x := x0 - 12.0
	while x < x0 + _block_len + 12.0:
		var g := (_road_y(x + 4.0) - _road_y(x)) / 4.0
		worst = minf(worst, g)
		parts.append("%+.0f" % (g * 100.0))
		x += 4.0
	print("  panta coapta pe blocul 1 (%%, din 4 in 4 m, de la -12 m): %s | maxima %.1f%%" % [
		" ".join(parts), -worst * 100.0])


func _start_index(x_target: float) -> int:
	var best := 0
	var bd := 1e18
	for i in _track.baked.size():
		var p := _track.baked[i]
		if absf(p.z) > 0.5:
			continue
		var d := absf(p.x - x_target)
		if d < bd:
			bd = d
			best = i
	return best


func _crest_of(x: float) -> int:
	var k := -1
	for i in _lips.size():
		if x >= _lips[i].x - 2.0:
			k = i
	return k


func _run(ci: int, mode: String, lat: float) -> void:
	var data: CarData = GameState.CAR_DATA[ci]
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(data)
	car.track = _track
	var si := _start_index(_lips[0].x - _runup)
	var start := _track.baked[si] + Vector3(0.0, 0.6, lat)
	car.global_transform = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), start)
	var v0 := car.max_speed
	var turbo_k := -1
	if mode.begins_with("t"):
		turbo_k = int(mode.trim_prefix("t")) - 1
	elif mode != "max":
		v0 = float(mode)
	car.velocity = Vector3(v0, 0.0, 0.0)
	car.road_index = si
	car.last_safe_index = si
	if _ai:
		var ai := AIController.new()
		car.set_controller(ai)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261110 + ci
		ai.configure(_track, rng)
		ai.line_offset = lat
	else:
		var ctl := StreetController.new()
		ctl.lat = lat
		if turbo_k >= 0 and turbo_k < _lips.size():
			ctl.turbo_from_x = _lips[turbo_k].x - 40.0
		car.set_controller(ctl)
	car.race_active = true
	# Lambdele captureaza localele prin VALOARE: evenimentele merg intr-un Dictionary.
	var ev := {"eject": false, "respawn": false, "wall": 0.0, "fall": 0.0}
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: ev["eject"] = true)
	car.respawned.connect(func(_c: Car) -> void: ev["respawn"] = true)
	car.wall_hit.connect(func(_c: Car, imp: float) -> void: ev["wall"] = maxf(float(ev["wall"]), imp))
	car.landed.connect(func(_c: Car, fs: float) -> void: ev["fall"] = fs)

	var crests: Array[Dictionary] = []
	for i in _lips.size():
		crests.append({"v_lip": -1.0, "air": 0.0, "dist": 0.0, "h": 0.0, "vn": 0.0, "grade": 0.0,
			"pitch": 0.0, "hops": 0, "inc": PackedStringArray(), "land_x": 0.0})
	var end_x := _lips[_lips.size() - 1].x + _block_len + 50.0
	var half_w := _track.half_width
	var t := 0.0
	var was_air := false
	var air_t := 0.0
	var air_k := -1
	var air_h := 0.0
	var lift := Vector3.ZERO
	var prev_vel := car.velocity
	var stop := ""
	while t < 40.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var p := car.global_position
		var k := _crest_of(p.x)
		if k >= 0 and float(crests[k]["v_lip"]) < 0.0 and p.x >= _lips[k].x:
			crests[k]["v_lip"] = Vector2(car.velocity.x, car.velocity.z).length()
		var on_floor := car.is_on_floor()
		if not on_floor:
			if not was_air:
				air_t = 0.0
				air_k = k
				air_h = 0.0
				lift = p
			air_t += 1.0 / 60.0
			air_h = maxf(air_h, p.y - _road_y(p.x))
			was_air = true
		elif was_air:
			was_air = false
			if air_k >= 0:
				var c: Dictionary = crests[air_k]
				if air_t >= HOP_MIN_S:
					c["hops"] = int(c["hops"]) + 1
				if air_t > float(c["air"]):
					var g := _road_grade(p.x)
					var n := Vector3(-g, 1.0, 0.0).normalized()
					var fwd := -car.global_transform.basis.z
					c["air"] = air_t
					c["dist"] = Vector2(p.x - lift.x, p.z - lift.z).length()
					c["h"] = air_h
					c["vn"] = -prev_vel.dot(n)
					c["grade"] = g
					c["pitch"] = rad_to_deg(asin(clampf(fwd.y, -1.0, 1.0)) - atan(g))
					c["land_x"] = p.x - _lips[air_k].x
		if k >= 0:
			var inc: PackedStringArray = crests[k]["inc"]
			if car.global_transform.basis.y.dot(Vector3.UP) < 0.3 and not inc.has("RASTURNAT"):
				inc.append("RASTURNAT")
			if absf(p.z) > half_w + 0.5 and not inc.has("AFARA"):
				inc.append("AFARA")
			if bool(ev["eject"]):
				inc.append("EJECTAT(%.0f)" % float(ev["fall"]))
				stop = "ejectat"
				# Ce a lovit: `_last_static` e corpul static cu normala ne-verticala din
				# tickul contactului (car.gd `_scan_contact_state`), nu soseaua de sub roti.
				var hit: Node = car.get("_last_static")
				print("      ! ejectare %s %.0f: %s lat %+.1f muchia %d, x=%.1f (%.1f m dupa muchie) z=%+.1f | lovit: %s | v inainte %s -> dupa %s | roti pe sol %d" % [
					car.last_eject_cause, car.last_eject_value, data.display_name, lat, k + 1,
					p.x, p.x - _lips[k].x, p.z,
					("%s/%s" % [hit.get_parent().name, hit.name]) if hit != null else "-",
					str(prev_vel.snapped(Vector3.ONE * 0.1)), str(car.velocity.snapped(Vector3.ONE * 0.1)),
					car.wheels_on_ground])
			elif bool(ev["respawn"]):
				inc.append("REPUS")
				stop = "repus"
			if float(ev["wall"]) > 0.0:
				inc.append("perete %.0f" % float(ev["wall"]))
				ev["wall"] = 0.0
		prev_vel = car.velocity
		if stop != "" or p.x > end_x:
			break
	if stop == "" and car.global_position.x <= end_x:
		stop = "timp"
	var cname: String = data.display_name
	for i in crests.size():
		var c: Dictionary = crests[i]
		if float(c["v_lip"]) < 0.0:
			continue # n-a ajuns la muchia asta
		c["car"] = cname
		c["mass"] = data.mass_factor
		var key := "%s|%d" % [mode, i]
		if not _rows.has(key):
			_rows[key] = []
		(_rows[key] as Array).append(c)
		var ck := "%s|%s" % [cname, mode]
		if not _by_car.has(ck):
			_by_car[ck] = []
		(_by_car[ck] as Array).append(c)
		if _detail:
			print("  %-12s %4s %+4.1f | %d   %5.1f   %4.2f  %5.1f  %5.2f   %5.1f   %+5.0f%%   %+5.1f   %d   %s" % [
				cname.left(12), mode, lat, i + 1, float(c["v_lip"]), float(c["air"]), float(c["dist"]),
				float(c["h"]), float(c["vn"]), float(c["grade"]) * 100.0, float(c["pitch"]),
				int(c["hops"]), " ".join(c["inc"] as PackedStringArray)])
	if _detail and stop != "":
		print("      ^ oprit: %s la x=%.0f" % [stop, car.global_position.x])
	car.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	a.sort()
	return float(a[a.size() / 2]) if a.size() % 2 == 1 else (float(a[a.size() / 2 - 1]) + float(a[a.size() / 2])) * 0.5


func _summary() -> void:
	print("")
	print("  REZUMAT pe mod x muchie (toate masinile si abaterile):")
	print("  mod  m | treceri  zboruri | v_muchie med | air med [min-max] | zbor med/max | h_max | v_norm max | pe plat | incidente")
	for mode in _modes:
		for i in _lips.size():
			var key := "%s|%d" % [mode, i]
			if not _rows.has(key):
				print("  %4s %d | nicio trecere" % [mode, i + 1])
				continue
			var rows: Array = _rows[key]
			var airs: Array = []
			var dists: Array = []
			var vs: Array = []
			var flights := 0
			var on_flat := 0
			var h := 0.0
			var vn := 0.0
			var incs: Dictionary = {}
			for r: Dictionary in rows:
				vs.append(float(r["v_lip"]))
				if float(r["air"]) >= FLIGHT_MIN_S:
					flights += 1
					airs.append(float(r["air"]))
					dists.append(float(r["dist"]))
					h = maxf(h, float(r["h"]))
					vn = maxf(vn, float(r["vn"]))
					if float(r["grade"]) > FLAT_GRADE:
						on_flat += 1
				for s: String in r["inc"]:
					var tag := s.get_slice("(", 0).get_slice(" ", 0)
					incs[tag] = int(incs.get(tag, 0)) + 1
			var amin := 0.0
			var amax := 0.0
			var dmax := 0.0
			for a: float in airs:
				amin = a if amin == 0.0 else minf(amin, a)
				amax = maxf(amax, a)
			for d: float in dists:
				dmax = maxf(dmax, d)
			print("  %4s %d |   %2d       %2d    |    %5.1f     | %4.2f [%4.2f-%4.2f]  | %4.1f / %4.1f  | %4.2f  |   %5.1f    |   %2d    | %s" % [
				mode, i + 1, rows.size(), flights, _median(vs), _median(airs), amin, amax,
				_median(dists), dmax, h, vn, on_flat, str(incs) if not incs.is_empty() else "-"])
	print("")
	print("  PE MASINA (airtime pe fiecare muchie, in ordine):")
	for ck: String in _by_car:
		var parts: PackedStringArray = PackedStringArray()
		for r: Dictionary in _by_car[ck]:
			parts.append("%.2f" % float(r["air"]))
		var first: Dictionary = (_by_car[ck] as Array)[0]
		print("  %-22s masa %.2f | %s" % [ck, float(first["mass"]), "  ".join(parts)])
