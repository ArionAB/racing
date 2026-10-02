extends Node
## Sonda SHISHI-ODOSHI (Kyoto, brief §3 si §7 pasul 1 a+b): tubul de bambus pe un
## drum de test (bucla-stadion ca la `probe_crane.gd`, dreapta de est pe x = 0,
## sensul -Z, tubul la z = 0 cu pivotul pe dreapta = exteriorul curbei).
##
## Cele patru contracte, tiparite ca tabel + verdict:
##   (a) LOVITURA pe 6 masini x 20/30 m/s: pierdere de viteza si de timp, inaltime,
##       distanta laterala. Cifrele trebuie sa DIFERE intre masini (masa conectata),
##       iar nimeni nu iese din lume (< 15 m de drum, deasupra solului).
##   (b) AI CARE CITESTE TUBUL, ~3 minute: contacte ~ 0 si zero opriri. Cu `--blind`
##       (AI-ul ignora tubul) contactele trebuie sa fie > 0 — altfel garda nu e armata.
##       Ambele cifre se raporteaza; ruleaza si pe `--only=b`.
##   (c) EXTERIORUL LIBER, masurat ca GOL pe gabaritul caroseriei (interogare de
##       fizica pe corpul si zona tubului, nu formula): >= 7 m.
##   (d) COSTUL: prins pe linia gresita 1-2 s; ocol pe exterior ~0,3 s.
##
## Garda nu poate iesi verde pe zero masuratori: fiecare verdict cere un numar minim
## de masuratori (loviri reale, treceri, ocoluri „in pericol") si pica altfel.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoTub.tscn
##   argumente (dupa `--`): --only=a|b|c|d  --blind  --pivot-h=6.5  --seconds=180

const CraneScript := preload("res://scenes/hazards/shishi_odoshi_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 9.0
const FINISH_Z: float = -100.0
const OUT_OF_WORLD_M: float = 15.0

var _track: TrackFromPath
var _hz: ShishiOdoshiHazard
var _fails: int = 0
var _only: String = ""
var _blind: bool = false
var _pivot_h: float = -1.0
var _trace: bool = false
var _seed: int = 7
var _car_only: int = -1
var _ai_seconds: float = 180.0
var _free_cache: Dictionary = {}
var _rows: Array[Dictionary] = []


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg == "--trace":
			_trace = true
		elif arg.begins_with("--car="):
			_car_only = int(arg.trim_prefix("--car="))
		elif arg == "--blind":
			_blind = true
		elif arg.begins_with("--pivot-h="):
			_pivot_h = float(arg.trim_prefix("--pivot-h="))
		elif arg.begins_with("--seconds="):
			_ai_seconds = float(arg.trim_prefix("--seconds="))


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
	_track.custom_name = "ProbeKyotoTub"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hz = CraneScript.new() as ShishiOdoshiHazard
	_hz.name = "ShishiOdoshi"
	_hz.road_width = HALF_WIDTH * 2.0
	_hz.side = 1
	if _pivot_h > 0.0:
		_hz.pivot_height = _pivot_h
	add_child(_hz)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== SONDA: Shishi-odoshi (tub de bambus, drum de test) ===")
	print("  ciclu %.1f s (umplere %.1f + lovitura %.1f + golire %.1f + revenire %.1f), unghiuri %.0f -> %.0f -> %.0f grade"
		% [_hz.cycle_seconds(), _hz.fill_seconds, _hz.strike_seconds,
		_hz.drain_seconds, _hz.return_seconds, _hz.fill_start_deg,
		_hz.fill_end_deg, _hz.strike_deg])
	print("  pivot la %.1f m, tub %.1f m (coada %.1f), pivot la %.1f m de axa; fereastra de pericol %s"
		% [_hz.pivot_height, _hz.tube_length, _hz.tail_length, _hz.pivot_offset,
		str(_hz.danger_window())])
	_hz.force_clock(0.0)
	if _only == "" or _only == "c":
		await _test_gap()
	if _only == "" or _only == "a" or _only == "d":
		await _test_strike()
	if _only == "" or _only == "d":
		await _test_cost()
	if _only == "" or _only == "b":
		await _test_ai()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ------------------------------------------------------------------ o trecere

## O trecere a unei masini pe dreapta de test. `path` = lista de puncte (x, z);
## `clock_at_cross` = ceasul tubului in clipa in care masina trece de z = 0
## (< 0: tubul sta sus, in umplere, toata trecerea).
func _pass(data: CarData, speed: float, path: Array[Vector2],
		clock_at_cross: float) -> Dictionary:
	var z0 := speed * 3.0
	var free_key := "%s/%.0f/%s" % [data.display_name, speed, str(path)]
	var t_cross_free: float = 3.0
	if _free_cache.has(free_key):
		t_cross_free = float(_free_cache[free_key])
	var seek_to := 0.0
	if clock_at_cross >= 0.0:
		seek_to = clock_at_cross - t_cross_free
	_hz.force_clock(seek_to)
	_hz.resume_clock()
	_hz.throws = 0
	_hz.strike_throws = 0

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(data)
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(path[0].x, 0.7, z0))
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(car.global_position, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	var driver := WaypointDriver.new()
	var wps: Array[Vector3] = []
	# path[0] = doar abscisa de start; urmatoarele sunt punctele de urmat.
	for p in path.slice(1):
		wps.append(Vector3(p.x, 0.0, p.y))
	driver.waypoints = wps
	driver.target_speed = speed
	car.set_controller(driver)

	var t := 0.0
	var t_cross := -1.0
	var t_finish := -1.0
	var y0 := -INF
	var y_max := -INF
	var y_min := INF
	var x_out_max := -INF # + = spre exterior (pivot)
	var v_pre := 0.0
	var v_min_after := INF
	var t_hit := -1.0
	var saw_hit := false
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
		if z > 12.0 and z < 40.0:
			y0 = maxf(y0, car.global_position.y)
		if z < 8.0:
			y_max = maxf(y_max, car.global_position.y)
			y_min = minf(y_min, car.global_position.y)
			x_out_max = maxf(x_out_max, x)
		if not saw_hit and z > 4.0:
			v_pre = car.horizontal_speed()
		if saw_hit and t - t_hit < 1.0:
			v_min_after = minf(v_min_after, car.horizontal_speed())
		if _trace and clock_at_cross >= 0.0 and z < 14.0 and z > -14.0:
			print("      t=%.2f clk=%.2f z=%6.2f x=%6.2f y=%5.2f v=%5.1f vy=%5.1f vx=%5.1f solid=%s zone=%s thr=%d" % [t, _hz.clock(), z, x, car.global_position.y, car.horizontal_speed(), car.velocity.y, car.velocity.x, str(_hz.is_solid()), str(_hz.is_zone_on()), _hz.throws])
		if z <= FINISH_Z:
			t_finish = t
			break
	var res := {
		"t_cross": t_cross, "t_finish": t_finish, "y_rise": y_max - y0,
		"y_min": y_min, "x_final": car.global_position.x, "x_out": x_out_max,
		"v_pre": v_pre, "v_min": v_min_after if saw_hit else v_pre,
		"throws": _hz.throws, "strike_throws": _hz.strike_throws,
		"respawns": 0 if car.race_active else 1,
		"x_end": car.global_position.x, "finished": t_finish > 0.0,
	}
	if clock_at_cross < 0.0:
		_free_cache[free_key] = t_cross
	car.queue_free()
	await get_tree().physics_frame
	return res


const STRAIGHT: Array[Vector2] = [Vector2(0, 100), Vector2(0, -60), Vector2(0, -140)]


# --------------------------------------------------------------------- (c) gol

func _test_gap() -> void:
	print("")
	print("-- (c) exteriorul liber, masurat ca GOL pe gabaritul caroseriei --")
	# Tubul culcat (golirea): cea mai grea stare pentru banda exterioara.
	_hz.force_clock(_hz.fill_seconds + _hz.strike_seconds + 0.5)
	for _i in 4:
		await get_tree().physics_frame
	var probe_car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(probe_car)
	probe_car.apply_data(GameState.CAR_DATA[0])
	var car_len := probe_car.collider_half_length() * 2.0
	probe_car.queue_free()
	var space := _hz.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	# Gabaritul: inaltimea caroseriei (0.1..1.1 m), lungimea ei, latime ~0 — se
	# cauta MARGINEA obstacolului, nu locul unde incape o masina.
	box.size = Vector3(0.05, 1.0, car_len)
	q.shape = box
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.collision_mask = 0xFFFFF
	var edge := _hz.pivot_offset
	var first_solid := INF
	var first_zone := INF
	var x := edge
	while x > -edge:
		q.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.6, 0.0))
		for hit in space.intersect_shape(q, 16):
			var c: Object = hit["collider"]
			if c == _hz.body():
				if first_solid == INF:
					first_solid = x
			elif c == _hz.hit_zone():
				if first_zone == INF:
					first_zone = x
		x -= 0.02
	var gap_solid := edge - first_solid if first_solid < INF else INF
	var gap_zone := edge - first_zone if first_zone < INF else INF
	var gap := minf(gap_solid, gap_zone)
	print("  marginea soselei (pivot) la x=%+.2f; tubul culcat (%.0f grade) incepe:" % [
		edge, _hz.strike_deg])
	print("    corp solid:     x=%+.2f -> gol %.2f m" % [first_solid, gap_solid])
	print("    zona de ghiont: x=%+.2f -> gol %.2f m" % [first_zone, gap_zone])
	print("    formula (free_gap_m): %.2f m ; brief: 7.3 m" % _hz.free_gap_m())
	_verdict(first_solid < INF and first_zone < INF,
		"am MASURAT ambele obstacole (nu iese verde pe zero)")
	_verdict(gap >= 7.0, "exteriorul liber (gol) >= 7.0 m (masurat %.2f m)" % gap)


# --------------------------------------------------------------- (a) lovitura

func _test_strike() -> void:
	print("")
	print("-- (a) lovitura (tub in coborare la trecere) pe 6 masini x 20/30 m/s --")
	print("  masina       v   masa  v_pre  v_min  pierd_s  urcare  lat_max  x_fin  | culcat: pierd_s  lat")
	_rows.clear()
	for speed in [20.0, 30.0]:
		for data_i in GameState.CAR_DATA.size():
			if _car_only >= 0 and data_i != _car_only:
				continue
			var data := GameState.CAR_DATA[data_i] as CarData
			var free: Dictionary = await _pass(data, speed, STRAIGHT, -1.0)
			var hit: Dictionary = await _pass(data, speed, STRAIGHT,
				_hz.fill_seconds + 0.45)
			var lying: Dictionary = await _pass(data, speed, STRAIGHT,
				_hz.fill_seconds + _hz.strike_seconds + 0.6)
			var row := {
				"name": data.display_name, "speed": speed,
				"mass": 100.0 * data.mass_factor,
				"v_pre": hit["v_pre"], "v_min": hit["v_min"],
				"loss_s": float(hit["t_finish"]) - float(free["t_finish"]),
				"rise": hit["y_rise"], "x_out": hit["x_out"], "x_final": hit["x_final"],
				"y_min": hit["y_min"], "hit_ok": int(hit["strike_throws"]) > 0,
				"fin_ok": bool(hit["finished"]) and bool(free["finished"]),
				"lying_loss": float(lying["t_finish"]) - float(free["t_finish"]),
				"lying_x": lying["x_out"], "lying_throws": lying["throws"],
				"lying_y_min": lying["y_min"], "lying_fin": lying["finished"],
			}
			_rows.append(row)
			print("  %-10s %4.0f %5.0f %6.1f %6.1f %7.2f %7.2f %8.2f %6.2f  |        %6.2f %5.1f"
				% [row["name"], speed, row["mass"], row["v_pre"], row["v_min"],
				row["loss_s"], row["rise"], row["x_out"], row["x_final"],
				row["lying_loss"], row["lying_x"]])
	_verdict(_rows.size() == 12, "12 masuratori (6 masini x 2 viteze): %d" % _rows.size())
	var all_hit := true
	var all_in := true
	var all_fin := true
	for r in _rows:
		all_hit = all_hit and bool(r["hit_ok"])
		all_fin = all_fin and bool(r["fin_ok"]) and bool(r["lying_fin"])
		# Nimeni nu iese din lume: lateral < 15 m de marginea drumului, deasupra
		# solului (cota soselei e 0).
		var beyond: float = float(r["x_out"]) - _hz.pivot_offset
		all_in = all_in and beyond < OUT_OF_WORLD_M and float(r["y_min"]) > -0.5 \
			and float(r["lying_y_min"]) > -0.5 \
			and float(r["lying_x"]) - _hz.pivot_offset < OUT_OF_WORLD_M
	_verdict(all_hit, "toate cele 12 treceri au fost LOVITE de tub (strike_throws >= 1)")
	_verdict(all_fin, "toate au terminat dreapta (nimeni oprit/repus)")
	_verdict(all_in, "nimeni nu iese din lume (< %.0f m de drum, deasupra solului)"
		% OUT_OF_WORLD_M)
	for speed in [20.0, 30.0]:
		var losses: Array[float] = []
		var rises: Array[float] = []
		var lats: Array[float] = []
		for r in _rows:
			if float(r["speed"]) == speed:
				losses.append(float(r["loss_s"]))
				rises.append(float(r["rise"]))
				lats.append(float(r["x_out"]))
		_verdict(_spread(losses) >= 0.15 and _spread(rises) >= 0.15
				and _spread(lats) >= 0.5,
			"la %.0f m/s cifrele DIFERA intre masini (timp +-%.2f s, urcare +-%.2f m, lateral +-%.2f m)"
			% [speed, _spread(losses), _spread(rises), _spread(lats)])
	# Masa e conectata, nu doar cifrele diferite: cea mai grea urca mai putin
	# decat cea mai usoara.
	var light: Dictionary = _rows[0]
	var heavy: Dictionary = _rows[0]
	for r in _rows:
		if float(r["speed"]) != 20.0:
			continue
		if float(r["mass"]) < float(light["mass"]) or float(light["speed"]) != 20.0:
			light = r
		if float(r["mass"]) > float(heavy["mass"]) or float(heavy["speed"]) != 20.0:
			heavy = r
	_verdict(float(heavy["rise"]) < float(light["rise"]),
		"masa conectata: %s (%.0f) urca %.2f m < %s (%.0f) urca %.2f m"
		% [heavy["name"], heavy["mass"], heavy["rise"], light["name"],
		light["mass"], light["rise"]])


func _spread(a: Array[float]) -> float:
	if a.is_empty():
		return 0.0
	return a.max() - a.min()


# -------------------------------------------------------------------- (d) cost

func _test_cost() -> void:
	print("")
	print("-- (d) cost: linia gresita vs ocolul pe exterior --")
	var lane := _hz.ai_safe_lane_m()
	print("  banda exterioara: centru la x=%+.2f m (gol liber %.2f m)" % [lane, _hz.free_gap_m()])
	var detour: Array[Vector2] = [Vector2(0, 100), Vector2(0, 45), Vector2(lane, 25),
		Vector2(lane, -25), Vector2(0, -45), Vector2(0, -140)]
	var wrong: Array[float] = []
	var ext: Array[float] = []
	var ext_throws := 0
	print("  masina       v  linia gresita (s)   ocol exterior (s)  ocol fara tub (s)")
	for speed in [20.0, 30.0]:
		for data_i in GameState.CAR_DATA.size():
			var data := GameState.CAR_DATA[data_i] as CarData
			var free: Dictionary = await _pass(data, speed, STRAIGHT, -1.0)
			var freed: Dictionary = await _pass(data, speed, detour, -1.0)
			var hit: Dictionary = await _pass(data, speed, STRAIGHT,
				_hz.fill_seconds + 0.45)
			var ext_hit: Dictionary = await _pass(data, speed, detour,
				_hz.fill_seconds + 0.45)
			var w := float(hit["t_finish"]) - float(free["t_finish"])
			var e := float(ext_hit["t_finish"]) - float(free["t_finish"])
			var e_free := float(freed["t_finish"]) - float(free["t_finish"])
			wrong.append(w)
			ext.append(e)
			ext_throws += int(ext_hit["throws"])
			print("  %-10s %4.0f %14.2f %18.2f %17.2f" % [data.display_name, speed, w, e, e_free])
	var w_mean := _mean(wrong)
	var e_mean := _mean(ext)
	print("  media: linia gresita %.2f s (min %.2f, max %.2f) ; ocol exterior %.2f s (min %.2f, max %.2f)"
		% [w_mean, wrong.min(), wrong.max(), e_mean, ext.min(), ext.max()])
	_verdict(wrong.size() == 12 and ext.size() == 12, "12 + 12 masuratori")
	_verdict(ext_throws == 0, "ocolul pe exterior nu e lovit niciodata (%d lovituri)" % ext_throws)
	_verdict(w_mean >= 1.0 and w_mean <= 2.0,
		"prins pe linia gresita pierde 1-2 s (media %.2f s)" % w_mean)
	_verdict(e_mean >= 0.0 and e_mean <= 0.6,
		"pe exterior ~0,3 s (media %.2f s, plafon 0.6)" % e_mean)


func _mean(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(float(a.size()), 1.0)


# ----------------------------------------------------------------------- (b) AI

func _test_ai() -> void:
	print("")
	print("-- (b) AI pe bucla cu tubul, %.0f s %s --"
		% [_ai_seconds, "(ORB: ignora tubul)" if _blind else "(citeste tubul)"])
	var reading := await _ai_run(false)
	_report_ai("citeste", reading)
	var blind := await _ai_run(true)
	_report_ai("ORB", blind)
	_verdict(int(reading["passes"]) >= 20 and int(blind["passes"]) >= 20,
		"destule treceri masurate (citeste %d, orb %d, minim 20)"
		% [reading["passes"], blind["passes"]])
	_verdict(int(reading["danger_passes"]) >= 3,
		"garda e ARMATA pe cititor: %d treceri in fereastra de pericol (minim 3), %d pe exterior"
		% [reading["danger_passes"], reading["evaded"]])
	_verdict(int(reading["contacts"]) <= 1,
		"AI care citeste: contacte AI-tub = %d (<= 1)" % reading["contacts"])
	_verdict(int(reading["stops"]) == 0, "AI care citeste: opriri = %d (== 0)" % reading["stops"])
	_verdict(int(blind["contacts"]) > 0,
		"AI ORB: contacte AI-tub = %d (> 0, altfel garda nu e armata)" % blind["contacts"])


func _report_ai(label: String, r: Dictionary) -> void:
	print("  [%s] treceri %d, in pericol %d (pe exterior %d), contacte %d (lovitura %d), opriri %d, repuneri %d, viteza medie la tub %.1f m/s"
		% [label, r["passes"], r["danger_passes"], r["evaded"], r["contacts"],
		r["strike_contacts"], r["stops"], r["respawns"], r["mean_speed"]])


func _ai_run(blind: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_hz.resume_clock()
	_hz.seek(3.0)
	_hz.throws = 0
	_hz.strike_throws = 0
	var main := _track.route_at(0)
	var n := main.baked.size()
	var cars: Array[Car] = []
	var ais: Array[AIController] = []
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
		ai.reads_shishi = not blind
		car.speed_scale = rng.randf_range(0.88, 0.97)
		car.set_controller(ai)
		cars.append(car)
		ais.append(ai)
	var contacts_before := 0
	var on_thrown := func(c: Car, on_strike: bool) -> void:
		print("    [contact] %s x=%+.2f z=%+.2f v=%.1f ceas=%.2f lovitura=%s linie=%s" % [c.pilot_name, c.global_position.x, c.global_position.z, c.horizontal_speed(), _hz.clock(), str(on_strike), "orb" if blind else "citeste"])
	_hz.car_thrown.connect(on_thrown)
	var res := {"passes": 0, "danger_passes": 0, "evaded": 0, "contacts": 0,
		"strike_contacts": 0, "stops": 0, "respawns": 0, "mean_speed": 0.0}
	var prev_z: Array[float] = []
	var slow_for: Array[float] = []
	var stopped: Array[bool] = []
	var respawns: Array[int] = []
	for c in cars:
		prev_z.append(c.global_position.z)
		slow_for.append(0.0)
		stopped.append(false)
		respawns.append(0)
		c.respawned.connect(func(_c: Car) -> void: res["respawns"] = int(res["respawns"]) + 1)
	var speed_sum := 0.0
	var t := 0.0
	var edge := _hz.pivot_offset
	var danger_lo := _hz.pivot_offset - _hz.free_gap_m()
	while t < _ai_seconds:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		for i in cars.size():
			var c := cars[i]
			var z := c.global_position.z
			var x := c.global_position.x
			# Trecere = coboara prin z = 0 pe dreapta de est (nu pe cea de vest).
			if prev_z[i] > 0.0 and z <= 0.0 and absf(x) < 14.0:
				res["passes"] = int(res["passes"]) + 1
				speed_sum += c.horizontal_speed()
				if _hz.is_zone_on() or _hz.blocks_in(0.0):
					res["danger_passes"] = int(res["danger_passes"]) + 1
					# Pe exterior = dincolo de inceputul zonei blocate, spre pivot.
					if x > danger_lo + 0.9:
						res["evaded"] = int(res["evaded"]) + 1
			prev_z[i] = z
			# Oprire: sub 1 m/s mai mult de 2 s cat curse e activa.
			if c.horizontal_speed() < 1.0 and c.race_active:
				slow_for[i] += 1.0 / 60.0
				if slow_for[i] > 2.0 and not stopped[i]:
					stopped[i] = true
					res["stops"] = int(res["stops"]) + 1
					print("    [oprire] %s la %s t=%.0f" % [c.pilot_name,
						str(c.global_position.round()), t])
			else:
				slow_for[i] = 0.0
				stopped[i] = false
	_hz.car_thrown.disconnect(on_thrown)
	res["contacts"] = _hz.throws - contacts_before
	res["strike_contacts"] = _hz.strike_throws
	res["mean_speed"] = speed_sum / maxf(float(res["passes"]), 1.0)
	for c in cars:
		c.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	return res
