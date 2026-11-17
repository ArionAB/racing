extends Node
## TROTUARELE de pe Track25 (brief san_francisco.md §7 pasul 8d): placa de la buza asfaltului pana
## sub fatadele caselor, declarata de scena in `paved_level_zones` (Vector4(de_la, pana_la, latime,
## latura), scrise de tools/gen_sf_route.py) si construita de track.gd ca prag PLAT la cota buzei.
## Decizia: o masina pe trotuar are viteza de drum; dincolo de el, plafonul de offroad ramane.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfTrotuar.tscn [-- --sabotaj]
##
## GARDA, pe scena reala:
##   A. DRUM. (1) Static: pe fiecare zona, din 3 in 3 puncte coapte, `is_on_road` raspunde DA pe
##      latura cu trotuar (la 0,8 m dupa buza si la 0,6 m inainte de capatul placii), NU dincolo de
##      placa (+1,5 m), NU pe latura fara trotuar (+1,5 m dupa buza) si NU in golurile dintre
##      randuri (strazile transversale). (2) Dinamic: o masina de joc reala (CarData 0), pornita cu
##      25 m/s si gaz la fund, tine o linie paralela cu axa pe doua strazi cu case pe O singura
##      latura (ocolul spre V `EAN`, strada de intors `G1V`): pe banda (3,5 m), pe trotuar (7,9 m) si
##      pe latura fara trotuar (8,5 m). Contractul: plafonul ei de viteza (`_current_max_speed`) pe
##      trotuar = cel de pe banda; pe latura fara trotuar = plafonul de offroad (x
##      `offroad_speed_factor`). Vitezele de la capat sunt raportate (masurate, nu doar calculate).
##      Corpurile `trunk` ale stalpilor sunt scoase pe durata cursei dinamice (masuram suprafata, nu
##      stalpii; felinarele stau la 9,3 m pe latura caselor).
##   B. TREAPTA. In fiecare punct copt al fiecarei zone, pe latura cu trotuar: cota primei suprafete
##      de rulare (asfalt `RoadTop`/`RoadSides`, trotuar `Trotuar`/`Shoulders`, teren) la 0,15 m
##      INAINTE de buza si la 0,15 m DUPA ea. |treapta| <= STEP_MAX (0,15 m, plafonul de bordura din
##      brief §5.1; proiectul e la nivel, deci masurat ~0). Si pe latimea placii (din 0,25 in 0,25 m,
##      pana la 0,45 m inaintea capatului): nicio diferenta intre vecini > PROFILE_MAX (fara trepte
##      ascunse) si niciun punct in care prima suprafata e TERENUL (nisip peste placa).
##   `--sabotaj` ridica placa la 0,30 m peste buza (`Track.paved_lift_m`, bordura verticala reala, cu
##   coliziune): garda TREBUIE sa pice pe B.
## Exit 1 daca pica ceva sau daca n-a masurat nimic (zero zone = scena fara trotuare).

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const STEP_MAX: float = 0.15
const PROFILE_MAX: float = 0.05
const WALK: Array[String] = ["RoadTop", "RoadSides", "Trotuar", "Shoulders", "TerrainBody"]

var _sabotage := false
var _space: PhysicsDirectSpaceState3D
var _track: Track
var _fails := 0


class OffsetController extends CarController:
	var track: Track
	var lat: float = 0.0
	func get_steer() -> float:
		var n := track.baked.size()
		var k := posmod(car.road_index + 6, n)
		var t := track.baked[k] + track._side_at(k) * lat
		var p := car.global_position
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var d := t - p
		d.y = 0.0
		if f.length() < 0.01 or d.length() < 0.01:
			return 0.0
		var ang := atan2(f.normalized().cross(d.normalized()).y, f.normalized().dot(d.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0


func _ready() -> void:
	var path := "res://scenes/tracks/Track25.tscn"
	for a in OS.get_cmdline_user_args():
		if a == "--sabotaj":
			_sabotage = true
		elif a.begins_with("--scene="):
			path = a.trim_prefix("--scene=")
	_track = (load(path) as PackedScene).instantiate() as Track
	if _sabotage:
		_track.paved_lift_m = 0.30
	add_child(_track)
	for _i in 3:
		await get_tree().process_frame
		await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state
	print("=== ProbeSfTrotuar: %s (%s)%s ===" % [_track.track_name, path.get_file(),
		" [SABOTAJ: placa ridicata la 0,30 m]" if _sabotage else ""])
	var zones := _track.paved_level_zones
	print("zone de trotuar: %d" % zones.size())
	if zones.is_empty():
		print("VERDICT: PICA (scena fara trotuare)")
		get_tree().quit(1)
		return
	_check_step(zones)
	_check_road_static(zones)
	await _check_road_dynamic(zones)
	print("VERDICT: %s%s" % ["PICA (%d)" % _fails if _fails > 0 else "OK",
		" [sabotaj]" if _sabotage else ""])
	get_tree().quit(1 if _fails > 0 else 0)


## Prima suprafata de rulare sub punct: [cota, nume corp] sau [NAN, ""].
func _surface(p: Vector3) -> Array:
	var excl: Array[RID] = []
	for _k in 10:
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 6.0, p + Vector3.DOWN * 12.0)
		q.exclude = excl
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return [NAN, ""]
		var col := hit["collider"] as Node
		var nm := String(col.name) if col != null else ""
		if nm in WALK:
			return [float((hit["position"] as Vector3).y), nm]
		excl.append(hit["rid"])
	return [NAN, ""]


## Indicii coapti cu latimea plina a zonei pe latura ei.
func _zone_indices(z: Vector4) -> Array[int]:
	var out: Array[int] = []
	var side := 1.0 if z.w > 0.0 else -1.0
	for k in _track.baked.size():
		if _track._paved_level_at(k, side) >= z.z - 0.01 and _in_window(k, z):
			out.append(k)
	return out


func _in_window(k: int, z: Vector4) -> bool:
	var n := _track.baked.size()
	var f := _track._dists[k] / _track._dists[n]
	return f > z.x and f < z.y


func _check_step(zones: Array[Vector4]) -> void:
	var worst := 0.0
	var worst_at := Vector3.ZERO
	var prof_worst := 0.0
	var prof_at := Vector3.ZERO
	var n_pts := 0
	var n_bad_step := 0
	var n_bad_prof := 0
	var n_sand := 0
	var sand_at: Array[Vector3] = []
	var hw := _track.half_width
	for z in zones:
		var side := 1.0 if z.w > 0.0 else -1.0
		for k in _zone_indices(z):
			var b := _track.baked[k]
			var s := _track._side_at(k) * side
			var r: Array = _surface(b + s * (_track.width_at_index(k) - 0.15))
			var pv: Array = _surface(b + s * (_track.width_at_index(k) + 0.15))
			if is_nan(float(r[0])) or is_nan(float(pv[0])):
				continue
			n_pts += 1
			var st := float(pv[0]) - float(r[0])
			if absf(st) > absf(worst):
				worst = st
				worst_at = b + s * hw
			if absf(st) > STEP_MAX:
				n_bad_step += 1
			# profilul pe latimea placii
			var prev := float(pv[0])
			var lat := _track.width_at_index(k) + 0.4
			while lat <= _track.width_at_index(k) + z.z - 0.45:
				var h: Array = _surface(b + s * lat)
				if String(h[1]) == "TerrainBody":
					n_sand += 1
					if sand_at.size() < 6:
						sand_at.append(b + s * lat)
				elif not is_nan(float(h[0])):
					var d := absf(float(h[0]) - prev)
					if d > prof_worst:
						prof_worst = d
						prof_at = b + s * lat
					if d > PROFILE_MAX:
						n_bad_prof += 1
					prev = float(h[0])
				lat += 0.25
	print("B. treapta asfalt -> trotuar: %d puncte coapte, cea mai mare %+.3f m la (%.0f, %.1f, %.0f) [prag %.2f], peste prag %d"
		% [n_pts, worst, worst_at.x, worst_at.y, worst_at.z, STEP_MAX, n_bad_step])
	print("   profilul placii: salt maxim intre vecini (0,25 m) %.3f m la (%.0f, %.1f, %.0f) [prag %.2f], peste prag %d; nisip peste placa %d%s"
		% [prof_worst, prof_at.x, prof_at.y, prof_at.z, PROFILE_MAX, n_bad_prof, n_sand,
			(" la " + ", ".join(sand_at.map(func(v: Vector3) -> String: return "(%.0f,%.0f)" % [v.x, v.z]))) if n_sand > 0 else ""])
	if n_pts == 0 or n_bad_step > 0 or n_bad_prof > 0 or n_sand > 0:
		_fails += 1
		print("   PICA: treapta / profil / nisip")


func _check_road_static(zones: Array[Vector4]) -> void:
	var n := _track.baked.size()
	var cnt := {"pe_trotuar": 0, "pe_trotuar_rau": 0, "dincolo": 0, "dincolo_rau": 0, "latura_goala": 0,
		"latura_goala_rau": 0, "gol": 0, "gol_rau": 0}
	var paved_any := PackedByteArray()
	paved_any.resize(n * 2)
	for k in n:
		paved_any[k * 2] = 1 if _track._paved_level_at(k, -1.0) > 0.01 else 0
		paved_any[k * 2 + 1] = 1 if _track._paved_level_at(k, 1.0) > 0.01 else 0
	for z in zones:
		var side := 1.0 if z.w > 0.0 else -1.0
		var idx := _zone_indices(z)
		for j in range(0, idx.size(), 3):
			var k: int = idx[j]
			var b := _track.baked[k] + Vector3.UP * 0.5
			var sv := _track._side_at(k)
			var w := _track.width_at_index(k)
			for lat: float in [w + 0.8, w + z.z - 0.6]:
				cnt["pe_trotuar"] += 1
				if not _track.is_on_road(k, b + sv * side * lat):
					cnt["pe_trotuar_rau"] += 1
			cnt["dincolo"] += 1
			if _track.is_on_road(k, b + sv * side * (w + z.z + 1.5)):
				cnt["dincolo_rau"] += 1
			if paved_any[k * 2 + (0 if side > 0.0 else 1)] == 0:
				cnt["latura_goala"] += 1
				if _track.is_on_road(k, b - sv * side * (w + 1.5)):
					cnt["latura_goala_rau"] += 1
		# golurile: 6..9 m dupa ultimul punct plin si inainte de primul (strazile transversale)
		if idx.is_empty():
			continue
		for end_k: int in [idx[idx.size() - 1], idx[0]]:
			var dir := 1 if end_k == idx[idx.size() - 1] else -1
			for step_m: float in [6.0, 9.0]:
				var kk := posmod(end_k + dir * int(round(step_m / 1.5)), n)
				if paved_any[kk * 2 + (1 if side > 0.0 else 0)] == 1:
					continue
				var bb := _track.baked[kk] + Vector3.UP * 0.5
				cnt["gol"] += 1
				if _track.is_on_road(kk, bb + _track._side_at(kk) * side * (_track.width_at_index(kk) + 2.0)):
					cnt["gol_rau"] += 1
	print("A1. is_on_road static: pe trotuar %d puncte (NU %d) | dincolo de placa %d (DA %d) | latura fara trotuar %d (DA %d) | goluri dintre randuri %d (DA %d)"
		% [cnt["pe_trotuar"], cnt["pe_trotuar_rau"], cnt["dincolo"], cnt["dincolo_rau"], cnt["latura_goala"],
			cnt["latura_goala_rau"], cnt["gol"], cnt["gol_rau"]])
	if cnt["pe_trotuar"] == 0 or cnt["pe_trotuar_rau"] > 0 or cnt["dincolo_rau"] > 0 \
			or cnt["latura_goala_rau"] > 0 or cnt["gol_rau"] > 0 or cnt["latura_goala"] == 0:
		_fails += 1
		print("   PICA: is_on_road")


func _check_road_dynamic(zones: Array[Vector4]) -> void:
	# stalpii scosi (corpurile `trunk`) pe durata cursei dinamice
	var removed := 0
	var dm := _track.get_node_or_null(^"DecorManual")
	if dm != null:
		for b in dm.find_children("*", "StaticBody3D", true, false):
			if String((b as Node).get_meta("mod_coliziune", "")) == "trunk":
				(b as Node).queue_free()
				removed += 1
	await get_tree().physics_frame
	print("A2. dinamic (CarData 0, 25 m/s, gaz la fund; %d corpuri de stalp scoase pe durata ei):" % removed)
	# strazile: zona cu trotuar pe O latura, alese dupa latime (3,8 m) si dupa latura (cea fara pereche)
	var picked := 0
	for z in zones:
		if absf(z.z - 3.8) > 0.05:
			continue
		var side := 1.0 if z.w > 0.0 else -1.0
		var idx := _zone_indices(z)
		if idx.size() < 30:
			continue
		var mid: int = idx[idx.size() / 2]
		if _track._paved_level_at(mid, -side) > 0.01:
			continue          # trotuar pe ambele laturi (lantul, strada spre N a ocolului)
		picked += 1
		if picked > 2:
			break
		var k0: int = idx[4]
		var steps := idx.size() - 10
		var res := {}
		for case_name: String in ["banda", "trotuar", "latura fara trotuar"]:
			var lat := 3.5 * side
			if case_name == "trotuar":
				lat = (_track.half_width + 0.9) * side
			elif case_name == "latura fara trotuar":
				lat = -(_track.half_width + 1.5) * side
			res[case_name] = await _drive(k0, steps, lat)
		var lane: Dictionary = res["banda"]
		var pav: Dictionary = res["trotuar"]
		var off: Dictionary = res["latura fara trotuar"]
		var b0 := _track.baked[k0]
		print("   strada la (%.0f, %.0f), %d m:" % [b0.x, -b0.z, int(_track._dists[idx[idx.size() - 6]] - _track._dists[k0])])
		for case_name: String in ["banda", "trotuar", "latura fara trotuar"]:
			var r: Dictionary = res[case_name]
			print("     %-20s plafon %.2f..%.2f m/s, pe drum %3.0f%% din tick-uri, v la capat %.1f m/s, v max %.1f, contacte cu altceva %d"
				% [case_name, float(r["cap_min"]), float(r["cap_max"]), 100.0 * float(r["on_road"]),
					float(r["v_end"]), float(r["v_max"]), int(r["hits"])])
		var car_f := float(lane["off_factor"])
		var ok_pav := absf(float(pav["cap_min"]) - float(lane["cap_min"])) < 0.01 and float(pav["on_road"]) > 0.99 \
			and float(pav["v_end"]) >= 0.95 * float(lane["v_end"])
		var ok_off := absf(float(off["cap_max"]) - float(lane["cap_min"]) * car_f) < 0.05 and float(off["on_road"]) < 0.01 \
			and float(off["v_end"]) < 0.8 * float(lane["v_end"])
		print("     trotuar = banda: %s | latura fara trotuar = plafonul de offroad (x %.2f): %s"
			% ["DA" if ok_pav else "NU", car_f, "DA" if ok_off else "NU"])
		if not ok_pav or not ok_off:
			_fails += 1
			print("   PICA: viteza pe trotuar / dincolo")
	if picked == 0:
		_fails += 1
		print("   PICA: nicio strada cu trotuar pe o singura latura")


func _drive(k0: int, steps: int, lat: float) -> Dictionary:
	var n := _track.baked.size()
	var b := _track.baked[k0]
	var fwd := (_track.baked[(k0 + 1) % n] - b)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var start := b + _track._side_at(k0) * lat + Vector3.UP * 0.6
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0] as CarData)
	car.track = _track
	car.road_index = k0
	car.last_safe_index = k0
	car.global_position = start
	car.look_at(start + fwd, Vector3.UP)
	var ctl := OffsetController.new()
	ctl.track = _track
	ctl.lat = lat
	car.set_controller(ctl)
	car.race_active = true
	car.linear_velocity = fwd * 25.0
	car.velocity = fwd * 25.0
	var end_s := _track._dists[(k0 + steps) % n]
	var cap_min := INF
	var cap_max := -INF
	var on := 0
	var ticks := 0
	var v_max := 0.0
	var hits := 0
	var t := 0.0
	while t < 8.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if t < 0.3:
			continue
		var cap: float = car._current_max_speed()
		cap_min = minf(cap_min, cap)
		cap_max = maxf(cap_max, cap)
		ticks += 1
		if _track.is_on_road(car.road_index, car.global_position):
			on += 1
		v_max = maxf(v_max, car.horizontal_speed())
		for bd in car.get_colliding_bodies():
			var nm := String((bd as Node).name)
			if not (nm in WALK):
				hits += 1
		if _track._dists[car.road_index] >= end_s:
			break
	var out := {"cap_min": cap_min, "cap_max": cap_max, "on_road": float(on) / maxf(ticks, 1.0),
		"v_end": car.horizontal_speed(), "v_max": v_max, "hits": hits, "off_factor": car.offroad_speed_factor}
	car.queue_free()
	await get_tree().physics_frame
	return out
