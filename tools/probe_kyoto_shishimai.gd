extends Node
## Sonda SHISHIMAI (Kyoto, Track18 POI H): leul care danseaza peste sosea, pe un drum de
## test (bucla-stadion ca la `probe_kyoto_daruma.gd`, dreapta de est pe x = 0, sensul
## -Z, leul la z = 0 pe axa, semilatimea soselei 7 m ca pe dreapta finala).
##
## Cinci contracte, tiparite ca tabel + PASS/PICAT:
##   (a) CULOAR LIBER pe tot tiparul (36 s): masurat cu interogari de FIZICA pe zona de
##       lovire (nu din `center_at_clock`, ar fi circular): cea mai lata fasie fara zona
##       in care incape o masina de 2 m, la fiecare 0,1 s. `--sabotage-corridor`
##       largeste dansul si gabaritul: verdictul TREBUIE sa pice.
##   (b) TELEGRAF inainte de atac, masurat pe nodurile VAZUTE (capul, ghemuirea, centrul
##       nodului), nu pe functiile pure: ghemuire + cap dat inapoi cu >= 1,2 s inainte ca
##       leul sa se miste cu > 8 m/s; capul e intors spre partea atacului; atacul
##       acopera 3-5 m. `--sabotage-telegraph` scurteaza telegraful: TREBUIE sa pice.
##   (c) ARUNCAREA pe 6 masini x 25/38 m/s: lovita o data, lateral, urcare mica, fara
##       oprire, fara repunere, nu iese din lume; cifrele DIFERA dupa masa
##       (`--sabotage-mass` TREBUIE sa pice).
##   (d) POZITIA CORPULUI fata de axa: centrul nodului ramane in +-max_center si tot
##       corpul VIZIBIL (AABB-urile mesh-urilor, in cadrul soselei) ramane pe sosea si
##       in gabaritul zonei de lovire (+ coama).
##   (e) AI CARE CITESTE vs AI ORB (`--blind` doar il alege pe cel afisat primul), 180 s
##       pe 5 seed-uri: cititorul are putine contacte si 0 opriri, orbul are contacte > 0
##       (altfel garda nu e armata).
##
## Garda nu poate iesi verde pe zero masuratori: fiecare verdict cere un numar minim de
## masuratori si pica altfel.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoShishimai.tscn
##   argumente (dupa `--`): --only=a|b|c|d|e  --seconds=180  --seeds=5  --car=i
##   --sabotage-corridor  --sabotage-telegraph  --sabotage-mass  --trace

const ShishimaiScript := preload("res://scenes/hazards/shishimai_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const MODEL_PATH: String = "res://assets/models/kyoto/props/shishimai.glb"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 7.0
const FINISH_Z: float = -100.0
const OUT_OF_WORLD_M: float = 6.0

var _track: TrackFromPath
var _hz: ShishimaiHazard
var _fails: int = 0
var _only: String = ""
var _trace: bool = false
var _sab_corridor: bool = false
var _sab_telegraph: bool = false
var _sab_mass: bool = false
var _car_only: int = -1
var _ai_seconds: float = 180.0
var _seeds: int = 5
var _free_cache: Dictionary = {}
var _rows: Array[Dictionary] = []


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg == "--sabotage-corridor":
			_sab_corridor = true
		elif arg == "--sabotage-telegraph":
			_sab_telegraph = true
		elif arg == "--sabotage-mass":
			_sab_mass = true
		elif arg == "--trace":
			_trace = true
		elif arg.begins_with("--car="):
			_car_only = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--seconds="):
			_ai_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seeds="):
			_seeds = int(arg.trim_prefix("--seeds="))


func _ready() -> void:
	await get_tree().process_frame
	_parse_args()
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeKyotoShishimai"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hz = ShishimaiScript.new() as ShishimaiHazard
	_hz.name = "Shishimai"
	_hz.road_half_width = HALF_WIDTH
	_hz.model = load(MODEL_PATH) as PackedScene
	if _sab_corridor:
		# Sabotaj: dans de 6 m, atac de 6 m si gabarit de 3,5 m semilatime: corpul
		# acopera aproape toata soseaua. Verdictul (a) TREBUIE sa pice.
		_hz.dance_amplitude = 6.0
		_hz.lunge_reach = 6.0
		_hz.max_center = 6.5
		_hz.hit_half_width = 3.5
	if _sab_telegraph:
		# Sabotaj: telegraf de 0,1 s (leul se repede fara avertisment). TREBUIE sa pice (b).
		_hz.telegraph_seconds = 0.1
	if _sab_mass:
		# Sabotaj: masa deconectata (raport saturat, fara bonus de masa). TREBUIE sa pice (c).
		_hz.reference_mass = 0.001
		_hz.keep_per_mass = 0.0
	add_child(_hz)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== SONDA: Shishimai (leul care danseaza, drum de test, semilatime %.1f m) ===" % HALF_WIDTH)
	print("  ciclu %.1f s x %d = tipar %.0f s; dans A=%.1f m, perioada %.1f s; telegraf %.1f s (%.1f..%.1f), atac %.2f s, %.1f m; gabarit +-%.2f m x [%.1f..-%.1f] m"
		% [_hz.cycle_seconds, ShishimaiHazard.LUNGE_DIRS.size(), _hz.pattern_seconds(),
		_hz.dance_amplitude, _hz.dance_period, _hz.telegraph_seconds,
		_hz.telegraph_start(), _hz.lunge_at, _hz.lunge_seconds, _hz.lunge_reach,
		_hz.hit_half_width, _hz.hit_front, _hz.hit_back])
	_hz.force_clock(0.0)
	if _only == "" or _only == "a":
		await _test_corridor()
	if _only == "" or _only == "b":
		await _test_telegraph()
	if _only == "" or _only == "d":
		await _test_body()
	if _only == "" or _only == "c":
		await _test_throw()
	if _only == "" or _only == "e":
		await _test_ai()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _mean(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(float(a.size()), 1.0)


func _spread(a: Array[float]) -> float:
	if a.is_empty():
		return 0.0
	return a.max() - a.min()


# ------------------------------------------------------------ (a) culoar liber

func _test_corridor() -> void:
	print("")
	print("-- (a) culoar liber pe tot tiparul, masurat cu fizica pe zona de lovire --")
	var probe_car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(probe_car)
	probe_car.apply_data(GameState.CAR_DATA[0])
	var car_len := probe_car.collider_half_length() * 2.0
	var car_w := probe_car.collider_half_width() * 2.0
	probe_car.queue_free()
	var space := _hz.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(car_w, 1.0, car_len)
	q.shape = box
	q.collide_with_areas = true
	q.collide_with_bodies = false
	q.collision_mask = 0xFFFFF
	var step_x := 0.2
	var x_lo := -HALF_WIDTH + car_w * 0.5
	var x_hi := HALF_WIDTH - car_w * 0.5
	var n := int(round((x_hi - x_lo) / step_x)) + 1
	var widths: Array[float] = []
	var worst := INF
	var worst_t := 0.0
	var g := 0.0
	var samples := 0
	while g < _hz.pattern_seconds():
		_hz.force_clock(g)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var best_run := 0.0
		var run_start := -1
		for i in n:
			var x := x_lo + float(i) * step_x
			q.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.6, 0.0))
			var blocked := false
			for hit in space.intersect_shape(q, 8):
				if hit["collider"] == _hz.hit_zone():
					blocked = true
					break
			if not blocked:
				if run_start < 0:
					run_start = i
				var run_w := float(i - run_start) * step_x + car_w
				best_run = maxf(best_run, run_w)
			else:
				run_start = -1
		widths.append(best_run)
		samples += 1
		if best_run < worst:
			worst = best_run
			worst_t = g
		g += 0.1
	var sorted := widths.duplicate()
	sorted.sort()
	print("  %d cadre (pas 0,1 s pe %.0f s); latimea soselei %.1f m, masina %.1f x %.1f m" % [samples, _hz.pattern_seconds(), 2.0 * HALF_WIDTH, car_w, car_len])
	print("    culoar liber: minim %.2f m (la ceas %.1f s, faza %s), p5 %.2f, mediana %.2f, maxim %.2f"
		% [worst, worst_t, String(_hz.phase_name(worst_t)), sorted[int(sorted.size() * 0.05)],
		sorted[sorted.size() / 2], sorted[sorted.size() - 1]])
	_verdict(samples >= 300, "destule cadre masurate (%d, minim 300)" % samples)
	_verdict(worst >= 4.4, "pe TOT ciclul ramane un culoar de >= 4,4 m (masina %.1f m + marja): minim %.2f m" % [car_w, worst])
	_hz.force_clock(0.0)


# ---------------------------------------------------------------- (b) telegraf

func _test_telegraph() -> void:
	print("")
	print("-- (b) telegraful, masurat pe nodurile vazute (cap, ghemuire, centru) --")
	var body := _hz.rig().find_child("Body_1", true, false) as Node3D
	var head := _hz.head_node()
	_hz.force_clock(0.0)
	var body_rest := body.position.y
	var rows: Array[Dictionary] = []
	for k in ShishimaiHazard.LUNGE_DIRS.size():
		var t0 := float(k) * _hz.cycle_seconds
		var dir := _hz.lunge_dir(k)
		var warn_at := -1.0
		var move_at := -1.0
		var yaw_at_lunge := 0.0
		var x_start := 0.0
		var x_end := 0.0
		var prev_x := 0.0
		var max_pre_v := 0.0
		var step := 1.0 / 60.0
		var s := 0.0
		while s < _hz.cycle_seconds:
			_hz.seek(t0 + s)
			var x := _hz.rig().position.x
			var v := absf(x - prev_x) / step if s > 0.0 else 0.0
			prev_x = x
			var pitch_dev := head.rotation.x
			var crouched := body_rest - body.position.y
			if warn_at < 0.0 and pitch_dev < -0.2 and crouched >= 0.06:
				warn_at = s
			if move_at < 0.0 and v > 8.0:
				move_at = s
			if move_at < 0.0:
				max_pre_v = maxf(max_pre_v, v)
			if absf(s - (_hz.lunge_at - 0.03)) < 0.5 * step:
				yaw_at_lunge = head.rotation.y
			if absf(s - _hz.lunge_at) < 0.5 * step:
				x_start = x
			if absf(s - (_hz.lunge_at + _hz.lunge_seconds)) < 0.5 * step:
				x_end = x
			s += step
		rows.append({"k": k, "dir": dir, "warn": warn_at, "move": move_at,
			"lead": move_at - warn_at, "yaw": yaw_at_lunge, "dx": x_end - x_start,
			"pre_v": max_pre_v})
		print("    ciclu %d dir %+d: ghemuit+cap inapoi de la s=%.2f, se misca >8 m/s de la s=%.2f -> avertisment %.2f s; cap intors %+.2f rad; atac %+.2f m; viteza max inainte %.1f m/s"
			% [k, int(dir), warn_at, move_at, move_at - warn_at, yaw_at_lunge, x_end - x_start, max_pre_v])
	var lead_ok := true
	var dir_ok := true
	var reach_ok := true
	var calm_ok := true
	for r in rows:
		lead_ok = lead_ok and float(r["warn"]) >= 0.0 and float(r["move"]) >= 0.0 \
			and float(r["lead"]) >= 1.1
		dir_ok = dir_ok and signf(float(r["yaw"])) == float(r["dir"]) \
			and absf(float(r["yaw"])) >= 0.4
		reach_ok = reach_ok and absf(float(r["dx"])) >= 3.0 and absf(float(r["dx"])) <= 5.5 \
			and signf(float(r["dx"])) == float(r["dir"])
		calm_ok = calm_ok and float(r["pre_v"]) < 8.0
	_verdict(rows.size() == ShishimaiHazard.LUNGE_DIRS.size(), "toate cele %d cicluri masurate" % rows.size())
	_verdict(lead_ok, "ghemuirea si capul dat inapoi apar cu >= 1,1 s INAINTE ca leul sa se miste > 8 m/s")
	_verdict(dir_ok, "capul e intors spre partea atacului (>= 0,4 rad, semnul = directia)")
	_verdict(reach_ok, "atacul acopera 3-5,5 m, pe partea anuntata")
	_verdict(calm_ok, "nicio miscare > 8 m/s inainte de avertisment (dansul ramane sub aceasta viteza)")
	_hz.force_clock(0.0)


# ------------------------------------------------------------ (d) pozitia corpului

## Extinderea VIZIBILA reala: varfurile triunghiurilor fiecarui mesh (nu AABB-ul, care
## pentru o piesa rotita iese mult prea larg), in cadrul soselei (`lo`/`hi`) si in
## cadrul leului (`rlo`/`rhi`, fara scara si fara deplasarea lui pe sosea).
func _visual_extent() -> Dictionary:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var rlo := Vector3(INF, INF, INF)
	var rhi := Vector3(-INF, -INF, -INF)
	for node in _hz.rig().find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var xf := mi.global_transform
		for v in mi.mesh.get_faces():
			var gp := xf * v
			var p := _hz.to_local(gp)
			var rp := _hz.rig().to_local(gp)
			lo = lo.min(p)
			hi = hi.max(p)
			rlo = rlo.min(rp)
			rhi = rhi.max(rp)
	return {"lo": lo, "hi": hi, "rlo": rlo, "rhi": rhi}


func _test_body() -> void:
	print("")
	print("-- (d) pozitia corpului fata de axa soselei, pe tot tiparul --")
	var max_c := 0.0
	var vis_lo_x := INF
	var vis_hi_x := -INF
	var vis_lo_z := INF
	var vis_hi_z := -INF
	var vis_hi_y := -INF
	var rel_lo := Vector3(INF, INF, INF)
	var rel_hi := Vector3(-INF, -INF, -INF)
	var out_of_zone := 0.0
	var samples := 0
	var g := 0.0
	var zone_x := _hz.hit_half_width * _hz.model_scale
	while g < _hz.pattern_seconds():
		_hz.seek(g)
		var c := _hz.rig().position.x
		max_c = maxf(max_c, absf(c))
		var ext := _visual_extent()
		var lo: Vector3 = ext["lo"]
		var hi: Vector3 = ext["hi"]
		vis_lo_x = minf(vis_lo_x, lo.x)
		vis_hi_x = maxf(vis_hi_x, hi.x)
		vis_lo_z = minf(vis_lo_z, lo.z)
		vis_hi_z = maxf(vis_hi_z, hi.z)
		vis_hi_y = maxf(vis_hi_y, hi.y)
		var rlo: Vector3 = ext["rlo"]
		var rhi: Vector3 = ext["rhi"]
		rel_lo = rel_lo.min(rlo)
		rel_hi = rel_hi.max(rhi)
		# corpul (cu coama) fata de zona de lovire: masoara iesirea
		out_of_zone = maxf(out_of_zone, maxf(-zone_x - rlo.x, rhi.x - zone_x))
		samples += 1
		g += 0.25
	print("  %d cadre; centrul nodului |x| max %.2f m; corpul vizibil in cadrul soselei x in [%.2f, %.2f] m, y max %.2f m; in cadrul leului x in [%.2f, %.2f], z in [%.2f, %.2f]; iesire maxima din zona de lovire (cu coama) %.2f m"
		% [samples, max_c, vis_lo_x, vis_hi_x, vis_hi_y, rel_lo.x, rel_hi.x, rel_lo.z, rel_hi.z, out_of_zone])
	_verdict(samples >= 140, "destule cadre masurate (%d, minim 140)" % samples)
	_verdict(max_c <= _hz.max_center + 0.01, "centrul nodului ramane in +-%.1f m de axa (%.2f)" % [_hz.max_center, max_c])
	_verdict(vis_lo_x >= -HALF_WIDTH + 0.05 and vis_hi_x <= HALF_WIDTH - 0.05,
		"tot corpul VIZIBIL (coama inclusa) ramane pe sosea, in +-%.1f m: [%.2f, %.2f]" % [HALF_WIDTH, vis_lo_x, vis_hi_x])
	_verdict(out_of_zone <= 1.0,
		"corpul vizibil nu iese din zona de lovire cu mai mult de coama (1,0 m, cap intors inclus): %.2f m" % out_of_zone)
	var zf := _hz.hit_front * _hz.model_scale
	var zb := _hz.hit_back * _hz.model_scale
	_verdict(rel_hi.z <= zf + 0.5 and rel_lo.z >= -(zb + 0.5),
		"corpul vizibil sta in gabaritul pe lungime al zonei [%.1f..-%.1f] (+-0,5): z in [%.2f, %.2f]" % [zf, zb, rel_lo.z, rel_hi.z])
	_hz.force_clock(0.0)


# --------------------------------------------------------------- (c) aruncarea

## Ceasul la care leul trece prin axa (x = 0) in dansul pur, in prima jumatate de ciclu.
func _clock_at_axis() -> float:
	var prev := _hz.center_at_clock(0.5)
	var g := 0.5
	while g < 4.5:
		g += 0.01
		var c := _hz.center_at_clock(g)
		if signf(c) != signf(prev) and absf(c) < 1.0:
			return g
		prev = c
	return 1.0


func _pass(data: CarData, speed: float, strike: bool) -> Dictionary:
	var z0 := speed * 3.0
	var free_key := "%s/%.0f" % [data.display_name, speed]
	var t_cross_free: float = 3.0
	if _free_cache.has(free_key):
		t_cross_free = float(_free_cache[free_key])
	if strike:
		_hz.force_clock(fposmod(_clock_at_axis() - t_cross_free, _hz.pattern_seconds()))
	else:
		_hz.force_clock(0.0)
	_hz.resume_clock()
	_hz.throws = 0

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(data)
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.7, z0))
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(car.global_position, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	var driver := WaypointDriver.new()
	var wps: Array[Vector3] = [Vector3(0.0, 0.0, -100.0), Vector3(0.0, 0.0, -140.0)]
	driver.waypoints = wps
	driver.target_speed = speed
	car.set_controller(driver)

	var t := 0.0
	var t_cross := -1.0
	var t_finish := -1.0
	var y0 := -INF
	var y_max := -INF
	var y_min := INF
	var x_out_max := 0.0
	var v_pre := 0.0
	var v_min_after := INF
	var t_hit := -1.0
	var saw_hit := false
	var resp := 0
	var x_hit := 0.0
	car.respawned.connect(func(_c: Car) -> void: resp += 1)
	while t < 22.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var z := car.global_position.z
		var x := car.global_position.x
		if t_cross < 0.0 and z <= 0.0:
			t_cross = t
		if not saw_hit and _hz.throws > 0:
			saw_hit = true
			t_hit = t
			x_hit = x
		if z > 12.0 and z < 40.0:
			y0 = maxf(y0, car.global_position.y)
		if z < 12.0:
			y_max = maxf(y_max, car.global_position.y)
			y_min = minf(y_min, car.global_position.y)
			x_out_max = maxf(x_out_max, absf(x))
		if not saw_hit and z > 6.0:
			v_pre = car.horizontal_speed()
		if saw_hit and t - t_hit < 1.0:
			v_min_after = minf(v_min_after, car.horizontal_speed())
		if _trace and strike and z < 14.0 and z > -14.0:
			print("      t=%.2f clk=%.2f z=%6.2f x=%6.2f y=%5.2f v=%5.1f vy=%5.1f vx=%5.1f lion=%+.2f thr=%d" % [t, _hz.clock(), z, x, car.global_position.y, car.horizontal_speed(), car.velocity.y, car.velocity.x, _hz.current_center(), _hz.throws])
		if z <= FINISH_Z:
			t_finish = t
			break
	var res := {
		"t_cross": t_cross, "t_finish": t_finish, "y_rise": y_max - y0,
		"y_min": y_min, "x_final": car.global_position.x, "x_out": x_out_max,
		"v_pre": v_pre, "v_min": v_min_after if saw_hit else v_pre,
		"throws": _hz.throws, "respawns": resp, "finished": t_finish > 0.0,
		"x_hit": x_hit,
	}
	if not strike:
		_free_cache[free_key] = t_cross
	car.queue_free()
	await get_tree().physics_frame
	return res


func _test_throw() -> void:
	print("")
	print("-- (c) aruncarea (leul trece prin axa in clipa trecerii) pe 6 masini x 25/38 m/s --")
	print("  masina       v   masa  v_pre  v_min  pierd_s  urcare  |x|max  x_fin  rep")
	_rows.clear()
	for speed in [25.0, 38.0]:
		for data_i in GameState.CAR_DATA.size():
			if _car_only >= 0 and data_i != _car_only:
				continue
			var data := GameState.CAR_DATA[data_i] as CarData
			var free: Dictionary = await _pass(data, speed, false)
			var hit: Dictionary = await _pass(data, speed, true)
			var row := {
				"name": data.display_name, "speed": speed,
				"mass": 100.0 * data.mass_factor,
				"v_pre": hit["v_pre"], "v_min": hit["v_min"],
				"loss_s": float(hit["t_finish"]) - float(free["t_finish"]),
				"rise": hit["y_rise"], "x_out": hit["x_out"], "x_final": hit["x_final"],
				"y_min": hit["y_min"], "throws": int(hit["throws"]),
				"fin_ok": bool(hit["finished"]) and bool(free["finished"]),
				"resp": hit["respawns"],
			}
			_rows.append(row)
			print("  %-10s %4.0f %5.0f %6.1f %6.1f %7.2f %7.2f %7.2f %6.2f %4d"
				% [row["name"], speed, row["mass"], row["v_pre"], row["v_min"],
				row["loss_s"], row["rise"], row["x_out"], row["x_final"], row["resp"]])
	var expected := 12 if _car_only < 0 else 2
	_verdict(_rows.size() == expected, "%d masuratori (6 masini x 2 viteze): %d" % [expected, _rows.size()])
	var all_hit := true
	var all_in := true
	var all_fin := true
	var all_stay := true
	for r in _rows:
		all_hit = all_hit and int(r["throws"]) == 1
		all_fin = all_fin and bool(r["fin_ok"])
		all_stay = all_stay and int(r["resp"]) == 0
		var beyond: float = float(r["x_out"]) - HALF_WIDTH
		all_in = all_in and beyond < OUT_OF_WORLD_M and float(r["y_min"]) > -0.5
	_verdict(all_hit, "fiecare trecere a fost lovita EXACT o data (throws == 1)")
	_verdict(all_fin, "toate au terminat dreapta (nimeni oprit)")
	_verdict(all_stay, "nimeni repus (0 repuneri)")
	_verdict(all_in, "nimeni nu iese din lume: |x| max < %.1f m (marginea %.1f + %.1f), deasupra solului"
		% [HALF_WIDTH + OUT_OF_WORLD_M, HALF_WIDTH, OUT_OF_WORLD_M])
	var losses_all: Array[float] = []
	for r in _rows:
		losses_all.append(float(r["loss_s"]))
	if not losses_all.is_empty():
		var lm := _mean(losses_all)
		_verdict(lm >= 0.2 and lm <= 2.0,
			"pierdere de timp 0,2-2 s: medie %.2f s (min %.2f, max %.2f)"
			% [lm, losses_all.min(), losses_all.max()])
	if _car_only >= 0:
		return
	for speed in [25.0, 38.0]:
		var losses: Array[float] = []
		var rises: Array[float] = []
		var lats: Array[float] = []
		for r in _rows:
			if float(r["speed"]) == speed:
				losses.append(float(r["loss_s"]))
				rises.append(float(r["rise"]))
				lats.append(float(r["x_out"]))
		_verdict(_spread(losses) >= 0.1 and _spread(rises) >= 0.1 and _spread(lats) >= 0.4,
			"la %.0f m/s cifrele DIFERA intre masini (timp +-%.2f s, urcare +-%.2f m, lateral +-%.2f m)"
			% [speed, _spread(losses), _spread(rises), _spread(lats)])
	var light: Dictionary = {}
	var heavy: Dictionary = {}
	for r in _rows:
		if float(r["speed"]) != 25.0:
			continue
		if light.is_empty() or float(r["mass"]) < float(light["mass"]):
			light = r
		if heavy.is_empty() or float(r["mass"]) > float(heavy["mass"]):
			heavy = r
	_verdict(float(heavy["rise"]) < float(light["rise"]) - 0.1
			and float(heavy["x_out"]) < float(light["x_out"])
			and float(heavy["v_min"]) > float(light["v_min"]),
		"masa conectata: %s (%.0f) urca %.2f m / lateral %.2f / v_min %.1f < %s (%.0f) urca %.2f m / lateral %.2f / v_min %.1f"
		% [heavy["name"], heavy["mass"], heavy["rise"], heavy["x_out"], heavy["v_min"], light["name"],
		light["mass"], light["rise"], light["x_out"], light["v_min"]])


# ----------------------------------------------------------------------- (e) AI

func _blank_run() -> Dictionary:
	return {"passes": 0.0, "contacts": 0.0, "stops": 0.0, "respawns": 0.0,
		"speed_sum": 0.0, "min_ratio_sum": 0.0, "dist_sum": 0.0, "near_lunge": 0.0}


func _report_ai(label: String, r: Dictionary) -> void:
	var passes := maxf(float(r["passes"]), 1.0)
	print("  [%-16s] treceri %3d, contacte %3d (%.0f%%), opriri %d, repuneri %d, viteza medie la leu %.1f m/s, distanta medie fata de centrul leului %.1f m, treceri in faza de atac %d"
		% [label, r["passes"], r["contacts"], 100.0 * float(r["contacts"]) / passes,
		r["stops"], r["respawns"], float(r["speed_sum"]) / passes,
		float(r["dist_sum"]) / passes, r["near_lunge"]])


func _test_ai() -> void:
	print("")
	print("-- (e) AI pe bucla cu leul, %.0f s x %d seed-uri: CITESTE vs ORB --" % [_ai_seconds, _seeds])
	var tot := {"reading": _blank_run(), "blind": _blank_run()}
	for seed_i in _seeds:
		for blind in [false, true]:
			var label := "orb" if blind else "citeste"
			var r: Dictionary = await _ai_run(blind, 100 + seed_i)
			_report_ai("%s seed %d" % [label, seed_i], r)
			var acc: Dictionary = tot["blind" if blind else "reading"]
			for k in acc.keys():
				acc[k] = float(acc[k]) + float(r[k])
	var rd: Dictionary = tot["reading"]
	var bl: Dictionary = tot["blind"]
	_report_ai("TOTAL citeste", rd)
	_report_ai("TOTAL orb    ", bl)
	_verdict(int(rd["passes"]) >= 60 and int(bl["passes"]) >= 60,
		"destule treceri masurate (citeste %d, orb %d, minim 60)" % [rd["passes"], bl["passes"]])
	_verdict(int(bl["contacts"]) > 0,
		"AI ORB: contacte = %d pe %d treceri (> 0, altfel garda nu e armata)" % [bl["contacts"], bl["passes"]])
	var rate_rd := float(rd["contacts"]) / maxf(float(rd["passes"]), 1.0)
	var rate_bl := float(bl["contacts"]) / maxf(float(bl["passes"]), 1.0)
	_verdict(rate_rd <= 0.25 and rate_rd < rate_bl * 0.5,
		"AI care citeste: %.0f%% contacte pe trecere (<= 25%% si sub jumatate din orb: %.0f%%)"
		% [100.0 * rate_rd, 100.0 * rate_bl])
	_verdict(int(rd["stops"]) == 0, "AI care citeste: opriri = %d (== 0)" % rd["stops"])
	var ratio := float(rd["min_ratio_sum"]) / maxf(float(rd["passes"]), 1.0)
	_verdict(ratio >= 0.8, "AI care citeste NU franeaza: cea mai joasa viteza la leu = %.0f%% din croaziera (>= 80%%)" % (100.0 * ratio))


func _ai_run(blind: bool, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	_hz.resume_clock()
	_hz.seek(3.0 + float(seed_v % 7))
	_hz.throws = 0
	var main := _track.route_at(0)
	var n := main.baked.size()
	var cars: Array[Car] = []
	for i in GameState.CAR_DATA.size():
		var data := GameState.CAR_DATA[i] as CarData
		var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
		add_child(car)
		car.apply_data(data)
		car.track = _track
		var idx := (i * n) / GameState.CAR_DATA.size() + 5
		var p: Vector3 = main.baked[idx % n]
		var fwd: Vector3 = main.baked[(idx + 1) % n] - p
		fwd.y = 0.0
		fwd = fwd.normalized()
		car.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP),
			p + Vector3.UP * 0.7)
		car.velocity = fwd * 10.0
		car.route = 0
		car.road_index = idx % n
		car.last_safe_index = car.road_index
		car.last_safe_route = 0
		car.pilot_name = "AI%d" % i
		car.race_active = true
		var ai := AIController.new()
		ai.configure(_track, rng, cars)
		ai.reads_shishimai = not blind
		car.speed_scale = rng.randf_range(0.88, 0.97)
		car.set_controller(ai)
		cars.append(car)
	var res := _blank_run()
	var on_thrown := func(c: Car) -> void:
		if _trace:
			print("    [contact] %s x=%+.2f z=%+.2f v=%.1f ceas=%.2f faza=%s leu=%+.2f linie=%s" % [c.pilot_name, c.global_position.x, c.global_position.z, c.horizontal_speed(), _hz.clock(), String(_hz.phase_name(_hz.clock())), _hz.current_center(), "orb" if blind else "citeste"])
	_hz.car_thrown.connect(on_thrown)
	var prev_z: Array[float] = []
	var slow_for: Array[float] = []
	var stopped: Array[bool] = []
	var min_ratio: Array[float] = []
	for c in cars:
		prev_z.append(c.global_position.z)
		slow_for.append(0.0)
		stopped.append(false)
		min_ratio.append(1.0)
		c.respawned.connect(func(_c: Car) -> void: res["respawns"] = float(res["respawns"]) + 1.0)
	var t := 0.0
	while t < _ai_seconds:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		for i in cars.size():
			var c := cars[i]
			var z := c.global_position.z
			var x := c.global_position.x
			# cea mai joasa viteza (fata de croaziera) pe ultimii 60 m inaintea leului
			if z > 0.0 and z < 60.0 and absf(x) < 14.0:
				var cruise := c.max_speed * c.speed_scale
				min_ratio[i] = minf(min_ratio[i], c.horizontal_speed() / maxf(cruise, 1.0))
			# Trecere = coboara prin z = 0 pe dreapta de est.
			if prev_z[i] > 0.0 and z <= 0.0 and absf(x) < 14.0:
				res["passes"] = float(res["passes"]) + 1.0
				res["speed_sum"] = float(res["speed_sum"]) + c.horizontal_speed()
				res["min_ratio_sum"] = float(res["min_ratio_sum"]) + min_ratio[i]
				res["dist_sum"] = float(res["dist_sum"]) + absf(x - _hz.current_center())
				var ph := _hz.phase_name(_hz.clock())
				if ph == &"atac" or ph == &"pauza" or ph == &"telegraf":
					res["near_lunge"] = float(res["near_lunge"]) + 1.0
				min_ratio[i] = 1.0
			prev_z[i] = z
			if c.horizontal_speed() < 1.0 and c.race_active:
				slow_for[i] += 1.0 / 60.0
				if slow_for[i] > 2.0 and not stopped[i]:
					stopped[i] = true
					res["stops"] = float(res["stops"]) + 1.0
					print("    [oprire] %s la %s t=%.0f" % [c.pilot_name,
						str(c.global_position.round()), t])
			else:
				slow_for[i] = 0.0
				stopped[i] = false
	_hz.car_thrown.disconnect(on_thrown)
	res["contacts"] = float(_hz.throws)
	for c in cars:
		c.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	return res
