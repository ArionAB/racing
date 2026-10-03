extends Node
## Sonda CAR GION MATSURI (Kyoto, Track18 POI F): carul de festival pe un drum de test
## (bucla-stadion ca la `probe_kyoto_daruma.gd`, dreapta de est pe x = 0, sensul -Z,
## carul la z = 0; `side` = +1 il pune intai pe dreapta si merge spre -X).
##
## Patru contracte, tiparite ca tabel + PASS/PICAT:
##   (a) LOVITURA pe 6 masini x 20/30 m/s, pe ambele sensuri (spre interior si spre
##       exterior): pierdere de viteza si de timp, urcare, deplasare pe sensul carului.
##       Cifrele trebuie sa DIFERE intre masini (masa conectata; `--sabotage-mass`
##       TREBUIE sa pice), nimeni nu iese din lume, nimeni nu e oprit sau repus.
##   (b) AI CARE CITESTE vs AI ORB, 180 s pe 5 seed-uri: cititorul are ~0 contacte si 0
##       opriri; orbul are contacte > 0 (altfel garda nu e armata). Se numara cate
##       treceri au RIDICAT piciorul.
##   (c) FEREASTRA DE TRECERE, masurata ca GOL pe gabaritul caroseriei (interogari de
##       fizica pe corpul si zona carului, nu AABB): pe tot ciclul, latimea acoperita
##       de car si cel mai lung interval fara nicio acoperire. Carul nu acopera
##       niciodata toata soseaua (un culoar de >= 2,2 m ramane mereu), iar intervalul
##       liber e >= `rest + telegraph`. `--sabotage-wide` (car de 13 m) TREBUIE sa pice.
##   (d) CICLUL, in timp real, 2 cicluri: doua traversari pe ciclu, pozitie CONTINUA
##       (niciun salt vizibil), viteza maxima in 3-6,5 m/s, fiecare telegraf cu muzica
##       pornita (numarator), fara teleportare.
##
## Garda nu poate iesi verde pe zero masuratori: fiecare verdict cere un numar minim de
## masuratori si pica altfel.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoGion.tscn
##   argumente (dupa `--`): --only=a|b|c|d  --seconds=180  --seeds=5  --car=i
##   --sabotage-mass  --sabotage-wide  --trace

const GionScript := preload("res://scenes/hazards/gion_matsuri_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 5.5
const FINISH_Z: float = -100.0
const OUT_OF_WORLD_M: float = 20.0
## Latimea minima a unui culoar pe care il poate lua o masina (m): caroseria ~2 m + marja.
const CORRIDOR_MIN: float = 2.2
## Cat timp (s) pe traversare poate fi carul un zid pe toata soseaua (culoar < CORRIDOR_MIN).
const WALL_MAX_S: float = 0.5

var _track: TrackFromPath
var _hz: GionMatsuriHazard
var _fails: int = 0
var _only: String = ""
var _trace: bool = false
var _sabotage_mass: bool = false
var _sabotage_wide: bool = false
var _car_only: int = -1
var _ai_seconds: float = 180.0
var _seeds: int = 5
var _free_cache: Dictionary = {}
var _rows: Array[Dictionary] = []


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg == "--sabotage-mass":
			_sabotage_mass = true
		elif arg == "--sabotage-wide":
			_sabotage_wide = true
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
	_track.custom_name = "ProbeKyotoGion"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hz = GionScript.new() as GionMatsuriHazard
	_hz.name = "GionMatsuri"
	_hz.road_half_width = HALF_WIDTH
	_hz.side = 1
	if _sabotage_mass:
		# Sabotaj: masa deconectata (raport saturat, fara bonus de masa). Verdictul
		# „cifrele difera intre masini" TREBUIE sa pice.
		_hz.reference_mass = 0.001
		_hz.keep_per_mass = 0.0
	if _sabotage_wide:
		# Sabotaj: carul acopera toata soseaua (13 m). Verdictele din (c) „culoar
		# liber" TREBUIE sa pice.
		_hz.cart_length = 13.0
	add_child(_hz)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== SONDA: Car Gion Matsuri (drum de test) ===")
	print("  etapa %.1f s = odihna %.1f + telegraf %.1f + traversare %.1f; ciclu mare %.1f s; centrul in odihna la +-%.2f m, caroserie %.1f x %.1f m, viteza maxima %.2f m/s"
		% [_hz.leg_seconds(), _hz.rest_seconds, _hz.telegraph_seconds, _hz.cross_seconds,
		_hz.total_seconds(), _hz.rest_x(), _hz.cart_length, _hz.cart_width, _hz.peak_speed()])
	print("  fereastra de pericol (fata de inceputul traversarii) %s, adica %.2f s din %.2f s"
		% [str(_hz.danger_window()), _hz.danger_window().y - _hz.danger_window().x, _hz.cross_seconds])
	_hz.force_clock(0.0)
	if _only == "" or _only == "c":
		await _test_window()
	if _only == "" or _only == "a":
		await _test_strike()
	if _only == "" or _only == "b":
		await _test_ai()
	if _only == "" or _only == "d":
		await _test_cycle()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["PASS" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ------------------------------------------------------------------ o trecere

## Ceasul la care centrul carului e la x = 0 pe etapa `l`, minus `lead` secunde.
func _clock_center(l: int, lead: float) -> float:
	return float(l) * _hz.leg_seconds() + _hz.rest_seconds + _hz.telegraph_seconds \
		+ _hz.cross_seconds * 0.5 - lead


## O trecere a unei masini pe dreapta de test. `strike` = carul ajunge cu centrul pe
## axa soselei (x = 0) in clipa in care masina trece de z = 0; `false` = ceasul tinut in
## repaus (trecere libera, de referinta). `leg` = sensul carului (0 spre -X = interior).
func _pass(data: CarData, speed: float, strike: bool, leg: int) -> Dictionary:
	var z0 := speed * 3.0
	var free_key := "%s/%.0f" % [data.display_name, speed]
	var t_cross_free: float = 3.0
	if _free_cache.has(free_key):
		t_cross_free = float(_free_cache[free_key])
	if strike:
		_hz.force_clock(_clock_center(leg, t_cross_free))
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

	var dir_x := _hz.leg_dir(leg)
	var t := 0.0
	var t_cross := -1.0
	var t_finish := -1.0
	var y0 := -INF
	var y_max := -INF
	var y_min := INF
	var x_dir_max := -INF # + = pe sensul carului
	var v_pre := 0.0
	var v_min_after := INF
	var t_hit := -1.0
	var saw_hit := false
	var resp := 0
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
		if z > 12.0 and z < 40.0:
			y0 = maxf(y0, car.global_position.y)
		if z < 8.0:
			y_max = maxf(y_max, car.global_position.y)
			y_min = minf(y_min, car.global_position.y)
			x_dir_max = maxf(x_dir_max, x * dir_x)
		if not saw_hit and z > 4.0:
			v_pre = car.horizontal_speed()
		if saw_hit and t - t_hit < 1.0:
			v_min_after = minf(v_min_after, car.horizontal_speed())
		if _trace and strike and z < 14.0 and z > -14.0:
			print("      t=%.2f clk=%.2f z=%6.2f x=%6.2f y=%5.2f v=%5.1f vy=%5.1f vx=%5.1f thr=%d" % [t, _hz.clock(), z, x, car.global_position.y, car.horizontal_speed(), car.velocity.y, car.velocity.x, _hz.throws])
		if z <= FINISH_Z:
			t_finish = t
			break
	var res := {
		"t_cross": t_cross, "t_finish": t_finish, "y_rise": y_max - y0,
		"y_min": y_min, "x_final": car.global_position.x, "x_dir": x_dir_max,
		"v_pre": v_pre, "v_min": v_min_after if saw_hit else v_pre,
		"throws": _hz.throws, "respawns": resp, "finished": t_finish > 0.0,
	}
	if not strike:
		_free_cache[free_key] = t_cross
	car.queue_free()
	await get_tree().physics_frame
	return res


# ----------------------------------------------------------------- (c) fereastra

func _test_window() -> void:
	print("")
	print("-- (c) fereastra de trecere, masurata ca GOL pe gabaritul caroseriei --")
	var probe_car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(probe_car)
	probe_car.apply_data(GameState.CAR_DATA[0])
	var car_len := probe_car.collider_half_length() * 2.0
	probe_car.queue_free()
	var space := _hz.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	# Gabaritul caroseriei: inaltime 0.1..1.1 m, lungimea ei, latime ~0.
	box.size = Vector3(0.05, 1.0, car_len)
	q.shape = box
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.collision_mask = 0xFFFFF
	var step := 0.1
	var n := int(round(2.0 * HALF_WIDTH / step)) + 1
	var samples := 0
	var max_covered := 0.0 # cea mai mare latime acoperita (m)
	var min_corridor := INF # cel mai mic culoar liber, pe tot ciclul (m)
	var free_run := 0.0
	var longest_free := 0.0
	var wall_s := 0.0 # timpul cu culoarul liber sub CORRIDOR_MIN: zid pe toata soseaua
	var t := 0.0
	var dt := 0.1
	var total := _hz.total_seconds()
	var blocked_series: Array[bool] = []
	while t < total * 1.0 + 0.0001:
		_hz.force_clock(t)
		await get_tree().physics_frame
		await get_tree().physics_frame
		samples += 1
		var covered := 0
		var longest_gap := 0 # cel mai lung culoar liber contiguu (in pasi)
		var run := 0
		for i in n:
			var x := -HALF_WIDTH + float(i) * step
			q.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.6, 0.0))
			var hit_any := false
			for hit in space.intersect_shape(q, 16):
				var c: Object = hit["collider"]
				if c == _hz.body() or c == _hz.hit_zone():
					hit_any = true
					break
			if hit_any:
				covered += 1
				run = 0
			else:
				run += 1
				longest_gap = maxi(longest_gap, run)
		max_covered = maxf(max_covered, float(covered) * step)
		min_corridor = minf(min_corridor, float(longest_gap) * step)
		if float(longest_gap) * step < CORRIDOR_MIN:
			wall_s += dt
		blocked_series.append(covered > 0)
		if covered == 0:
			free_run += dt
			longest_free = maxf(longest_free, free_run)
		else:
			free_run = 0.0
		t += dt
	# intervalul liber ciclic (sfarsit + inceput al seriei)
	var lead_free := 0.0
	for b in blocked_series:
		if b:
			break
		lead_free += dt
	var tail_free := 0.0
	for k in range(blocked_series.size() - 1, -1, -1):
		if blocked_series[k]:
			break
		tail_free += dt
	var wrapped := lead_free + tail_free
	var longest := maxf(longest_free, wrapped)
	var blocked_s := 0.0
	for b in blocked_series:
		if b:
			blocked_s += dt
	print("  %d cadre pe ciclul de %.1f s; latimea soselei %.1f m" % [samples, total, 2.0 * HALF_WIDTH])
	print("    acoperire maxima %.1f m din %.1f; cel mai mic culoar liber de pe tot ciclul %.1f m; carul atinge soseaua %.1f s din %.1f (%.0f%%); timp ca ZID (culoar < %.1f m): %.1f s pe ciclu = %.1f s pe traversare"
		% [max_covered, 2.0 * HALF_WIDTH, min_corridor, blocked_s, total, 100.0 * blocked_s / total, CORRIDOR_MIN, wall_s, wall_s * 0.5])
	print("    cel mai lung interval fara nicio acoperire: %.1f s (odihna + telegraf = %.1f s)"
		% [longest, _hz.rest_seconds + _hz.telegraph_seconds])
	_verdict(samples >= 200, "destule cadre masurate (%d, minim 200)" % samples)
	_verdict(max_covered > 4.0, "garda e armata: carul acopera cel putin 4 m din sosea (%.1f m)" % max_covered)
	_verdict(min_corridor >= 2.0,
		"mereu un culoar: cel mai mic culoar liber de pe tot ciclul %.1f m (>= 2,0 m)" % min_corridor)
	_verdict(wall_s * 0.5 <= WALL_MAX_S,
		"carul acopera doar o parte din latime: ca zid pe toata soseaua doar %.1f s pe traversare (<= %.1f s), in rest ramane un culoar >= %.1f m"
		% [wall_s * 0.5, WALL_MAX_S, CORRIDOR_MIN])
	_verdict(longest >= _hz.rest_seconds + _hz.telegraph_seconds - 0.3,
		"fereastra libera: %.1f s fara nicio acoperire (>= %.1f s = odihna + telegraf)"
		% [longest, _hz.rest_seconds + _hz.telegraph_seconds - 0.3])
	_verdict(blocked_s / total <= 0.5,
		"carul atinge soseaua cel mult jumatate din timp: %.0f%% (<= 50%%)" % (100.0 * blocked_s / total))
	_hz.force_clock(0.0)
	_hz.resume_clock()


# --------------------------------------------------------------- (a) lovitura

func _test_strike() -> void:
	print("")
	print("-- (a) lovitura (centrul carului la axa in clipa trecerii) pe 6 masini x 20/30 m/s --")
	print("  sens      masina       v   masa  v_pre  v_min  pierd_s  urcare  pe_sens  x_fin  rep")
	_rows.clear()
	for leg in [0, 1]:
		for speed in [20.0, 30.0]:
			for data_i in GameState.CAR_DATA.size():
				if _car_only >= 0 and data_i != _car_only:
					continue
				var data := GameState.CAR_DATA[data_i] as CarData
				var free: Dictionary = await _pass(data, speed, false, leg)
				var hit: Dictionary = await _pass(data, speed, true, leg)
				var row := {
					"name": data.display_name, "speed": speed, "leg": leg,
					"mass": 100.0 * data.mass_factor,
					"v_pre": hit["v_pre"], "v_min": hit["v_min"],
					"loss_s": float(hit["t_finish"]) - float(free["t_finish"]),
					"rise": hit["y_rise"], "x_dir": hit["x_dir"], "x_final": hit["x_final"],
					"y_min": hit["y_min"], "hit_ok": int(hit["throws"]) > 0,
					"fin_ok": bool(hit["finished"]) and bool(free["finished"]),
					"resp": hit["respawns"],
				}
				_rows.append(row)
				print("  %-8s %-10s %4.0f %5.0f %6.1f %6.1f %7.2f %7.2f %8.2f %6.2f %4d"
					% ["interior" if leg == 0 else "exterior", row["name"], speed, row["mass"],
					row["v_pre"], row["v_min"], row["loss_s"], row["rise"], row["x_dir"],
					row["x_final"], row["resp"]])
	var expected := 24 if _car_only < 0 else 4
	_verdict(_rows.size() == expected, "%d masuratori (2 sensuri x 6 masini x 2 viteze): %d" % [expected, _rows.size()])
	var all_hit := true
	var all_in := true
	var all_fin := true
	var all_stay := true
	for r in _rows:
		all_hit = all_hit and bool(r["hit_ok"])
		all_fin = all_fin and bool(r["fin_ok"])
		all_stay = all_stay and int(r["resp"]) == 0
		# Nimeni nu iese din lume: lateral < 20 m de marginea drumului, deasupra solului.
		var beyond: float = float(r["x_dir"]) - HALF_WIDTH
		all_in = all_in and beyond < OUT_OF_WORLD_M and float(r["y_min"]) > -0.5
	_verdict(all_hit, "toate treceri au fost LOVITE de car (throws >= 1)")
	_verdict(all_fin, "toate au terminat dreapta (nimeni oprit)")
	_verdict(all_stay, "nimeni repus (0 repuneri)")
	_verdict(all_in, "nimeni nu iese din lume (< %.0f m de drum, deasupra solului)" % OUT_OF_WORLD_M)
	for leg in [0, 1]:
		var losses_all: Array[float] = []
		for r in _rows:
			if int(r["leg"]) == leg:
				losses_all.append(float(r["loss_s"]))
		if not losses_all.is_empty():
			var lm := _mean(losses_all)
			_verdict(lm >= 0.8 and lm <= 2.2,
				"sens %s: pierdere de timp 0,8-2,2 s: medie %.2f s (min %.2f, max %.2f)"
				% ["interior" if leg == 0 else "exterior", lm, losses_all.min(), losses_all.max()])
	if _car_only >= 0:
		return
	for speed in [20.0, 30.0]:
		var losses: Array[float] = []
		var rises: Array[float] = []
		var lats: Array[float] = []
		for r in _rows:
			if float(r["speed"]) == speed and int(r["leg"]) == 0:
				losses.append(float(r["loss_s"]))
				rises.append(float(r["rise"]))
				lats.append(float(r["x_dir"]))
		_verdict(_spread(losses) >= 0.15 and _spread(rises) >= 0.15 and _spread(lats) >= 0.5,
			"la %.0f m/s cifrele DIFERA intre masini (timp +-%.2f s, urcare +-%.2f m, lateral +-%.2f m)"
			% [speed, _spread(losses), _spread(rises), _spread(lats)])
	var light: Dictionary = {}
	var heavy: Dictionary = {}
	for r in _rows:
		if float(r["speed"]) != 20.0 or int(r["leg"]) != 0:
			continue
		if light.is_empty() or float(r["mass"]) < float(light["mass"]):
			light = r
		if heavy.is_empty() or float(r["mass"]) > float(heavy["mass"]):
			heavy = r
	_verdict(float(heavy["rise"]) < float(light["rise"]) - 0.1
			and float(heavy["x_dir"]) < float(light["x_dir"]),
		"masa conectata: %s (%.0f) urca %.2f m / lateral %.2f < %s (%.0f) urca %.2f m / lateral %.2f"
		% [heavy["name"], heavy["mass"], heavy["rise"], heavy["x_dir"], light["name"],
		light["mass"], light["rise"], light["x_dir"]])


func _spread(a: Array[float]) -> float:
	if a.is_empty():
		return 0.0
	return a.max() - a.min()


func _mean(a: Array[float]) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(float(a.size()), 1.0)


# ----------------------------------------------------------------------- (b) AI

func _test_ai() -> void:
	print("")
	print("-- (b) AI pe bucla cu carul, %.0f s x %d seed-uri: CITESTE vs ORB --" % [_ai_seconds, _seeds])
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
	_verdict(int(rd["lifts"]) >= 5,
		"garda e ARMATA pe cititor: %d treceri cu piciorul ridicat (minim 5)" % rd["lifts"])
	_verdict(int(rd["contacts"]) <= 1,
		"AI care citeste: contacte AI-car = %d pe %d treceri (<= 1)" % [rd["contacts"], rd["passes"]])
	_verdict(int(rd["stops"]) == 0, "AI care citeste: opriri = %d (== 0)" % rd["stops"])
	_verdict(int(bl["contacts"]) > 0,
		"AI ORB: contacte AI-car = %d pe %d treceri (> 0, altfel garda nu e armata)" % [bl["contacts"], bl["passes"]])


func _blank_run() -> Dictionary:
	return {"passes": 0.0, "near": 0.0, "lifts": 0.0, "contacts": 0.0, "stops": 0.0,
		"respawns": 0.0, "speed_sum": 0.0, "min_ratio_sum": 0.0}


func _report_ai(label: String, r: Dictionary) -> void:
	var passes := maxf(float(r["passes"]), 1.0)
	print("  [%-16s] treceri %3d, in fereastra %3d, piciorul ridicat %3d, contacte %3d, opriri %d, repuneri %d, viteza medie la car %.1f m/s, cea mai joasa viteza (fata de croaziera) %.0f%%"
		% [label, r["passes"], r["near"], r["lifts"], r["contacts"], r["stops"],
		r["respawns"], float(r["speed_sum"]) / passes, 100.0 * float(r["min_ratio_sum"]) / maxf(float(r["lifts"]), 1.0)])


func _ai_run(blind: bool, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	_hz.resume_clock()
	_hz.seek(3.0 + float(seed_v % 7))
	_hz.throws = 0
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
		car.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), p + Vector3.UP * 0.7)
		car.velocity = fwd * 10.0
		car.route = 0
		car.road_index = idx % n
		car.last_safe_index = car.road_index
		car.last_safe_route = 0
		car.pilot_name = "AI%d" % i
		car.race_active = true
		var ai := AIController.new()
		ai.configure(_track, rng, cars)
		ai.reads_gion = not blind
		car.speed_scale = rng.randf_range(0.88, 0.97)
		car.set_controller(ai)
		cars.append(car)
		ais.append(ai)
	var res := _blank_run()
	var on_thrown := func(c: Car) -> void:
		if _trace:
			print("    [contact] %s x=%+.2f z=%+.2f v=%.1f ceas=%.2f linie=%s" % [c.pilot_name, c.global_position.x, c.global_position.z, c.horizontal_speed(), _hz.clock(), "orb" if blind else "citeste"])
	_hz.car_thrown.connect(on_thrown)
	var prev_z: Array[float] = []
	var slow_for: Array[float] = []
	var stopped: Array[bool] = []
	var lifted: Array[bool] = []
	var min_ratio: Array[float] = []
	for c in cars:
		prev_z.append(c.global_position.z)
		slow_for.append(0.0)
		stopped.append(false)
		lifted.append(false)
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
			# Pe ultimii 70 m inaintea carului: a ridicat piciorul? cat de jos a coborat?
			if z > 0.0 and z < 70.0 and absf(x) < 14.0:
				var st: Dictionary = ais[i]._daruma_state
				for key in st.keys():
					if bool((st[key] as Dictionary)["lift"]):
						lifted[i] = true
				var cruise := c.max_speed * c.speed_scale
				if lifted[i]:
					min_ratio[i] = minf(min_ratio[i], c.horizontal_speed() / maxf(cruise, 1.0))
			# Trecere = coboara prin z = 0 pe dreapta de est.
			if prev_z[i] > 0.0 and z <= 0.0 and absf(x) < 14.0:
				res["passes"] = float(res["passes"]) + 1.0
				res["speed_sum"] = float(res["speed_sum"]) + c.horizontal_speed()
				var w := _hz.window_rel(0.0)
				if w.x <= 0.5 and w.y >= -0.5:
					res["near"] = float(res["near"]) + 1.0
				if lifted[i]:
					res["lifts"] = float(res["lifts"]) + 1.0
					res["min_ratio_sum"] = float(res["min_ratio_sum"]) + min_ratio[i]
				lifted[i] = false
				min_ratio[i] = 1.0
			prev_z[i] = z
			# Oprire: sub 1 m/s mai mult de 2 s cat curse e activa.
			if c.horizontal_speed() < 1.0 and c.race_active:
				slow_for[i] += 1.0 / 60.0
				if slow_for[i] > 2.0 and not stopped[i]:
					stopped[i] = true
					res["stops"] = float(res["stops"]) + 1.0
					print("    [oprire] %s la %s t=%.0f" % [c.pilot_name, str(c.global_position.round()), t])
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


# ------------------------------------------------------------------- (d) ciclu

func _test_cycle() -> void:
	print("")
	print("-- (d) ciclul in timp real, >= 2 cicluri --")
	_hz.resume_clock()
	_hz.seek(0.0)
	_hz.telegraphs = 0
	_hz.crossings = 0
	var prev_x := _hz.cart_x()
	var max_jump := 0.0
	var vmax := 0.0
	var elapsed := 0.0
	var target := _hz.total_seconds() * 2.0 + 1.0
	var cycles := 0
	var prev_clock := 0.0
	var dir_changes := 0
	var last_sign := 0
	var x_min := INF
	var x_max := -INF
	var mid_speed_sum := 0.0
	var mid_n := 0
	while elapsed < target:
		await get_tree().physics_frame
		elapsed += 1.0 / 60.0
		var g := _hz.clock()
		if g < prev_clock - 1.0:
			cycles += 1
		prev_clock = g
		var x := _hz.cart_x()
		if absf(x - prev_x) < 3.0:
			max_jump = maxf(max_jump, absf(x - prev_x))
		var v := absf(_hz.cart_speed_at(g))
		vmax = maxf(vmax, v)
		if v > 0.3:
			mid_speed_sum += v
			mid_n += 1
			var sgn := signi(int(signf(_hz.cart_speed_at(g))))
			if sgn != last_sign:
				dir_changes += 1
				last_sign = sgn
		x_min = minf(x_min, x)
		x_max = maxf(x_max, x)
		prev_x = x
	var vmean := mid_speed_sum / maxf(float(mid_n), 1.0)
	print("  cicluri complete %d, telegrafe %d, traversari complete %d, schimbari de sens %d; x de la %+.2f la %+.2f; viteza maxima %.2f m/s, medie in miscare %.2f m/s, salt maxim pe cadru %.3f m"
		% [cycles, _hz.telegraphs, _hz.crossings, dir_changes, x_min, x_max, vmax, vmean, max_jump])
	_verdict(cycles >= 2, "cel putin 2 cicluri mari complete (%d)" % cycles)
	_verdict(_hz.crossings >= 4, "doua traversari pe ciclu: %d traversari in %d cicluri (minim 4)" % [_hz.crossings, cycles])
	_verdict(_hz.telegraphs >= 4 and absi(_hz.telegraphs - _hz.crossings) <= 1,
		"un telegraf (muzica pornita) inainte de fiecare traversare: %d telegrafe, %d traversari" % [_hz.telegraphs, _hz.crossings])
	_verdict(dir_changes >= 4, "carul isi schimba sensul la fiecare etapa (%d schimbari)" % dir_changes)
	_verdict(vmax >= 3.0 and vmax <= 6.5, "viteza maxima in 3-6,5 m/s (carul e greu): %.2f m/s" % vmax)
	_verdict(vmean >= 2.0 and vmean <= 5.0, "viteza medie in miscare in 2-5 m/s: %.2f m/s" % vmean)
	_verdict(max_jump <= 0.12, "pozitie continua, fara teleportare: salt maxim pe cadru %.3f m (<= 0,12)" % max_jump)
	_verdict(x_min <= -_hz.rest_x() + 0.05 and x_max >= _hz.rest_x() - 0.05,
		"carul ajunge pe ambele margini (x de la %+.2f la %+.2f, odihna +-%.2f)" % [x_min, x_max, _hz.rest_x()])
