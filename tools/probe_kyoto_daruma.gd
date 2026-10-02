extends Node
## Sonda DARUMA-OTOSHI (Kyoto, Track18 POI F): turnul de discuri cu ciocan, pe un drum
## de test (bucla-stadion ca la `probe_kyoto_tub.gd`, dreapta de est pe x = 0, sensul
## -Z, turnul la z = 0 pe dreapta = exterior, deci discul loveste spre -X).
##
## Patru contracte, tiparite ca tabel + PASS/PICAT:
##   (a) LOVITURA pe 6 masini x 20/30 m/s: pierdere de viteza si de timp, urcare,
##       deplasare laterala. Cifrele trebuie sa DIFERE intre masini (masa conectata;
##       `--sabotage-mass` TREBUIE sa pice verdictul), nimeni nu iese din lume, nimeni
##       nu e oprit sau repus, pierderea de timp e 1-2 s.
##   (b) AI CARE CITESTE vs AI ORB (`--blind` doar il alege pe cel afisat primul), 180 s
##       pe 5 seed-uri: cititorul are ~0 contacte si 0 opriri; orbul are contacte > 0
##       (altfel garda nu e armata). Se numara si cate treceri au RIDICAT piciorul.
##   (c) ACOPERIREA TRAVERSARII, masurata ca GOL pe gabaritul caroseriei (interogari de
##       fizica pe corpul si zona discului, nu AABB): toata latimea soselei e acoperita
##       cat dureaza traversarea, iar DUPA ea niciun disc nu ramane pe asfalt; turnul si
##       stalpii ciocanului nu intra in banda soselei.
##   (d) CICLUL MARE, in timp real, pe >= 2 cicluri: 5 lovituri pe ciclu, turnul coboara
##       cate un etaj la fiecare, iar reconstructia il aduce la loc (5 discuri, capul la
##       cota de repaus).
##
## Garda nu poate iesi verde pe zero masuratori: fiecare verdict cere un numar minim de
## masuratori si pica altfel.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoDaruma.tscn
##   argumente (dupa `--`): --only=a|b|c|d  --seconds=180  --seeds=5  --car=i
##   --sabotage-mass  --sabotage-short  --trace

const DarumaScript := preload("res://scenes/hazards/daruma_otoshi_hazard.gd")
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
const OUT_OF_WORLD_M: float = 15.0

var _track: TrackFromPath
var _hz: DarumaOtoshiHazard
var _fails: int = 0
var _only: String = ""
var _trace: bool = false
var _sabotage_mass: bool = false
var _sabotage_short: bool = false
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
		elif arg == "--sabotage-short":
			_sabotage_short = true
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
	_track.custom_name = "ProbeKyotoDaruma"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame

	_hz = DarumaScript.new() as DarumaOtoshiHazard
	_hz.name = "DarumaOtoshi"
	_hz.road_half_width = HALF_WIDTH
	_hz.side = 1
	if _sabotage_mass:
		# Sabotaj: masa deconectata (raport saturat, fara bonus de masa). Verdictul
		# „cifrele difera intre masini" TREBUIE sa pice.
		_hz.reference_mass = 0.001
		_hz.keep_per_mass = 0.0
	if _sabotage_short:
		# Sabotaj: discul se opreste pe asfalt (alunecare scurta). Verdictele din (c)
		# „niciun disc ramas pe asfalt" si „gol" TREBUIE sa pice.
		_hz.slide_distance = 9.0
	add_child(_hz)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== SONDA: Daruma-otoshi (turn de discuri + ciocan, drum de test) ===")
	print("  perioada %.1f s x %d + reconstructie %.1f s = ciclu mare %.1f s; ciocan tras %.1f s + tinut %.1f s + lovitura %.2f s; contact la %.1f s din perioada"
		% [_hz.strike_period, DarumaOtoshiHazard.LEVELS, _hz.rebuild_seconds,
		_hz.total_seconds(), _hz.windup_seconds, _hz.hold_seconds, _hz.swing_seconds,
		_hz.hit_at])
	print("  turn la %.2f m de axa (centru), disc O%.1f x %.2f, alunecare %.0f m in %.1f s; fereastra de pericol %s (fata de contact); traversare libera la tau=%.2f s"
		% [absf(_hz.tower_center_x()), _hz.disc_diameter, _hz.disc_height,
		_hz.slide_distance, _hz.slide_seconds, str(_hz.danger_window()),
		_hz.crossing_clear_tau()])
	_hz.force_clock(0.0)
	if _only == "" or _only == "c":
		await _test_coverage()
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

## O trecere a unei masini pe dreapta de test. `strike` = lovitura e sincronizata asa
## incat discul sa ajunga la axa soselei (x = 0) in clipa in care masina trece de
## z = 0; `false` = ceasul tinut in repaus (trecere libera, de referinta).
func _pass(data: CarData, speed: float, strike: bool) -> Dictionary:
	var z0 := speed * 3.0
	var free_key := "%s/%.0f" % [data.display_name, speed]
	var t_cross_free: float = 3.0
	if _free_cache.has(free_key):
		t_cross_free = float(_free_cache[free_key])
	var tau_axis := _tau_at_distance(absf(_hz.tower_center_x()))
	if strike:
		_hz.force_clock(_hz.hit_at + tau_axis - t_cross_free)
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
	var wps: Array[Vector3] = [Vector3(0.0, 0.0, 100.0 * -1.0), Vector3(0.0, 0.0, -140.0)]
	driver.waypoints = wps
	driver.target_speed = speed
	car.set_controller(driver)

	var t := 0.0
	var t_cross := -1.0
	var t_finish := -1.0
	var y0 := -INF
	var y_max := -INF
	var y_min := INF
	var x_in_max := -INF # + = spre interior (directia discului, -X)
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
			x_in_max = maxf(x_in_max, -x)
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
		"y_min": y_min, "x_final": car.global_position.x, "x_in": x_in_max,
		"v_pre": v_pre, "v_min": v_min_after if saw_hit else v_pre,
		"throws": _hz.throws, "respawns": resp, "finished": t_finish > 0.0,
	}
	if not strike:
		_free_cache[free_key] = t_cross
	car.queue_free()
	await get_tree().physics_frame
	return res


## `tau` la care discul a parcurs distanta `d` de la centrul turnului (bisectie).
func _tau_at_distance(d: float) -> float:
	var lo := 0.0
	var hi := _hz.slide_seconds
	for _i in 30:
		var mid := (lo + hi) * 0.5
		if _hz.disc_distance(mid) < d:
			lo = mid
		else:
			hi = mid
	return hi


# ----------------------------------------------------------------- (c) gol

func _test_coverage() -> void:
	print("")
	print("-- (c) traversarea discului, masurata ca GOL pe gabaritul caroseriei --")
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
	var covered_body: Array[bool] = []
	var covered_any: Array[bool] = []
	for _i in n:
		covered_body.append(false)
		covered_any.append(false)
	var tau_clear := _hz.crossing_clear_tau()
	var tau := 0.0
	var samples := 0
	while tau <= tau_clear + 0.12:
		_hz.force_clock(_hz.hit_at + tau)
		await get_tree().physics_frame
		await get_tree().physics_frame
		samples += 1
		for i in n:
			var x := -HALF_WIDTH + float(i) * step
			q.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.6, 0.0))
			for hit in space.intersect_shape(q, 16):
				var c: Object = hit["collider"]
				if c == _hz.body():
					covered_body[i] = true
					covered_any[i] = true
				elif c == _hz.hit_zone():
					covered_any[i] = true
		tau += 0.03
	var gap_body := 0.0
	var gap_any := 0.0
	for i in n:
		if not covered_body[i]:
			gap_body += step
		if not covered_any[i]:
			gap_any += step
	print("  %d cadre de traversare (tau 0..%.2f s); latimea soselei %.1f m" % [samples, tau_clear, 2.0 * HALF_WIDTH])
	print("    gol necovarit: corp %.2f m, corp+zona %.2f m" % [gap_body, gap_any])
	_verdict(samples >= 20, "destule cadre masurate (%d, minim 20)" % samples)
	_verdict(gap_any <= 0.11,
		"traversarea acopera toata latimea (corp+zona): gol %.2f m (<= 0,1)" % gap_any)
	_verdict(gap_body <= 0.11,
		"si corpul solid o acopera singur: gol %.2f m (<= 0,1)" % gap_body)

	# DUPA traversare: niciun disc pe asfalt (corp sau zona), pe toata latimea, in toate
	# fazele de pana la urmatoarea ridicare a ciocanului.
	var left_on_road := 0
	var post_samples := 0
	var t_end := _hz.strike_period - _hz.windup_seconds - _hz.hold_seconds - _hz.swing_seconds - 0.3
	var s_post := _hz.hit_at + tau_clear + 0.15
	# pana la urmatoarea lovitura (14 s mai tarziu, in perioada urmatoare): ciocanul
	# tras si turnul coborat sunt in cadru, discul trebuie sa lipseasca de pe asfalt
	while s_post < _hz.strike_period + _hz.hit_at - 0.6:
		_hz.force_clock(s_post)
		await get_tree().physics_frame
		await get_tree().physics_frame
		post_samples += 1
		for i in n:
			var x := -HALF_WIDTH + float(i) * 0.25
			if x > HALF_WIDTH:
				break
			q.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.6, 0.0))
			for hit in space.intersect_shape(q, 16):
				var c: Object = hit["collider"]
				if c == _hz.body() or c == _hz.hit_zone():
					left_on_road += 1
		s_post += 0.25
	print("  dupa traversare: %d cadre pana la sfarsitul perioadei, %d atingeri disc-asfalt" % [post_samples, left_on_road])
	_verdict(post_samples >= 5, "destule cadre post-traversare (%d, minim 5)" % post_samples)
	_verdict(left_on_road == 0, "niciun disc ramas pe asfalt dupa traversare (%d atingeri)" % left_on_road)
	# turnul si ciocanul NU intra in banda soselei, in nicio faza (ciocan tras inclusiv)
	var tower_in_lane := 0
	var lane_samples := 0
	for t_probe in [0.0, 5.0, 8.5, 10.6, 11.2, 12.0, 70.0 - 3.0]:
		_hz.force_clock(t_probe)
		await get_tree().physics_frame
		await get_tree().physics_frame
		lane_samples += 1
		for i in n:
			var x := -HALF_WIDTH + float(i) * step
			q.transform = Transform3D(Basis.IDENTITY, Vector3(x, 0.6, 0.0))
			q.collision_mask = 0xFFFFF
			for hit in space.intersect_shape(q, 16):
				var c2: Object = hit["collider"]
				if c2 is StaticBody3D and c2 != _hz.body() and _hz.is_ancestor_of(c2 as Node):
					tower_in_lane += 1
					if _trace:
						print("    [in banda] x=%.2f faza %.1f: %s" % [x, t_probe, (c2 as Node).get_path()])
	print("  turn+cadru in banda: %d atingeri pe %d faze" % [tower_in_lane, lane_samples])
	_verdict(tower_in_lane == 0, "turnul si stalpii nu intra in banda soselei (%d atingeri)" % tower_in_lane)
	_hz.force_clock(0.0)
	_hz.resume_clock()


# --------------------------------------------------------------- (a) lovitura

func _test_strike() -> void:
	print("")
	print("-- (a) lovitura (disc la axa in clipa trecerii) pe 6 masini x 20/30 m/s --")
	print("  masina       v   masa  v_pre  v_min  pierd_s  urcare  in_max  x_fin  rep")
	_rows.clear()
	for speed in [20.0, 30.0]:
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
				"rise": hit["y_rise"], "x_in": hit["x_in"], "x_final": hit["x_final"],
				"y_min": hit["y_min"], "hit_ok": int(hit["throws"]) > 0,
				"fin_ok": bool(hit["finished"]) and bool(free["finished"]),
				"resp": hit["respawns"],
			}
			_rows.append(row)
			print("  %-10s %4.0f %5.0f %6.1f %6.1f %7.2f %7.2f %7.2f %6.2f %4d"
				% [row["name"], speed, row["mass"], row["v_pre"], row["v_min"],
				row["loss_s"], row["rise"], row["x_in"], row["x_final"], row["resp"]])
	var expected := 12 if _car_only < 0 else 2
	_verdict(_rows.size() == expected, "%d masuratori (6 masini x 2 viteze): %d" % [expected, _rows.size()])
	var all_hit := true
	var all_in := true
	var all_fin := true
	var all_stay := true
	for r in _rows:
		all_hit = all_hit and bool(r["hit_ok"])
		all_fin = all_fin and bool(r["fin_ok"])
		all_stay = all_stay and int(r["resp"]) == 0
		# Nimeni nu iese din lume: lateral < 15 m de marginea drumului, deasupra solului.
		var beyond: float = float(r["x_in"]) - HALF_WIDTH
		all_in = all_in and beyond < OUT_OF_WORLD_M and float(r["y_min"]) > -0.5
	_verdict(all_hit, "toate treceri au fost LOVITE de disc (throws >= 1)")
	_verdict(all_fin, "toate au terminat dreapta (nimeni oprit)")
	_verdict(all_stay, "nimeni repus (0 repuneri)")
	_verdict(all_in, "nimeni nu iese din lume (< %.0f m de drum, deasupra solului)"
		% OUT_OF_WORLD_M)
	var losses_all: Array[float] = []
	for r in _rows:
		losses_all.append(float(r["loss_s"]))
	if not losses_all.is_empty():
		var lm := _mean(losses_all)
		_verdict(lm >= 1.0 and lm <= 2.0,
			"pierdere de timp 1-2 s: medie %.2f s (min %.2f, max %.2f)"
			% [lm, losses_all.min(), losses_all.max()])
	if _car_only >= 0:
		return
	for speed in [20.0, 30.0]:
		var losses: Array[float] = []
		var rises: Array[float] = []
		var lats: Array[float] = []
		for r in _rows:
			if float(r["speed"]) == speed:
				losses.append(float(r["loss_s"]))
				rises.append(float(r["rise"]))
				lats.append(float(r["x_in"]))
		_verdict(_spread(losses) >= 0.15 and _spread(rises) >= 0.15
				and _spread(lats) >= 0.5,
			"la %.0f m/s cifrele DIFERA intre masini (timp +-%.2f s, urcare +-%.2f m, lateral +-%.2f m)"
			% [speed, _spread(losses), _spread(rises), _spread(lats)])
	var light: Dictionary = {}
	var heavy: Dictionary = {}
	for r in _rows:
		if float(r["speed"]) != 20.0:
			continue
		if light.is_empty() or float(r["mass"]) < float(light["mass"]):
			light = r
		if heavy.is_empty() or float(r["mass"]) > float(heavy["mass"]):
			heavy = r
	_verdict(float(heavy["rise"]) < float(light["rise"]) - 0.1
			and float(heavy["x_in"]) < float(light["x_in"]),
		"masa conectata: %s (%.0f) urca %.2f m / lateral %.2f < %s (%.0f) urca %.2f m / lateral %.2f"
		% [heavy["name"], heavy["mass"], heavy["rise"], heavy["x_in"], light["name"],
		light["mass"], light["rise"], light["x_in"]])


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
	print("-- (b) AI pe bucla cu turnul, %.0f s x %d seed-uri: CITESTE vs ORB --" % [_ai_seconds, _seeds])
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
		"AI care citeste: contacte AI-disc = %d pe %d treceri (<= 1)" % [rd["contacts"], rd["passes"]])
	_verdict(int(rd["stops"]) == 0, "AI care citeste: opriri = %d (== 0)" % rd["stops"])
	_verdict(int(bl["contacts"]) > 0,
		"AI ORB: contacte AI-disc = %d pe %d treceri (> 0, altfel garda nu e armata)" % [bl["contacts"], bl["passes"]])


func _blank_run() -> Dictionary:
	return {"passes": 0.0, "near": 0.0, "lifts": 0.0, "contacts": 0.0, "stops": 0.0,
		"respawns": 0.0, "speed_sum": 0.0, "min_ratio_sum": 0.0}


func _report_ai(label: String, r: Dictionary) -> void:
	var passes := maxf(float(r["passes"]), 1.0)
	print("  [%-16s] treceri %3d, aproape de lovitura %3d, piciorul ridicat %3d, contacte %3d, opriri %d, repuneri %d, viteza medie la turn %.1f m/s, cea mai joasa viteza (fata de croaziera) %.0f%%"
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
		ai.reads_daruma = not blind
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
			# Pe ultimii 70 m inaintea turnului: a ridicat piciorul? cat de jos a coborat?
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
				var k := _hz.period_index(_hz.clock())
				var s := _hz.period_time(_hz.clock())
				if k < DarumaOtoshiHazard.LEVELS and s > _hz.hit_at - 1.0 and s < _hz.hit_at + 2.0:
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


# ------------------------------------------------------------------- (d) ciclu

func _test_cycle() -> void:
	print("")
	print("-- (d) ciclul mare in timp real, >= 2 cicluri --")
	_hz.resume_clock()
	_hz.seek(0.0)
	var h := _hz.disc_height
	var head_rest: float = 0.0
	var ok_levels := true
	var ok_head := true
	var flights := 0
	var prev_fly := false
	var cycles := 0
	var prev_clock := 0.0
	var seen: Array[String] = []
	var rebuilt_ok := 0
	var checked_period: Dictionary = {}
	var total := _hz.total_seconds()
	var elapsed := 0.0
	var head := _hz.tower_node().find_child("Head", true, false) as Node3D
	# cota de repaus a capului = valoarea de la ceasul 0
	head_rest = head.position.y
	var target := total * 2.0 + 3.0
	var min_h_seen := INF
	while elapsed < target:
		await get_tree().physics_frame
		elapsed += 1.0 / 60.0
		var g := _hz.clock()
		if g < prev_clock - 1.0:
			cycles += 1
		prev_clock = g
		var k := _hz.period_index(g)
		var s := _hz.period_time(g)
		var fly := _hz.disc_flying(g)
		if fly and not prev_fly:
			flights += 1
		prev_fly = fly
		var key := "%d/%d" % [cycles, k]
		if k < DarumaOtoshiHazard.LEVELS and s >= 1.0 and s < 1.1 and not checked_period.has(key):
			checked_period[key] = true
			var vis := _hz.visible_discs()
			var want := DarumaOtoshiHazard.LEVELS - k
			var head_y := head.position.y
			var want_y := head_rest - float(k) * h
			var lv := vis == want
			var hy := absf(head_y - want_y) < 0.03
			ok_levels = ok_levels and lv
			ok_head = ok_head and hy
			min_h_seen = minf(min_h_seen, head_y)
			seen.append("c%d/p%d: %d discuri (cerut %d), cap %.2f (cerut %.2f)" % [cycles, k, vis, want, head_y, want_y])
		if k >= DarumaOtoshiHazard.LEVELS and s >= _hz.rebuild_seconds - 0.2 and not checked_period.has(key):
			checked_period[key] = true
			var vis2 := _hz.visible_discs()
			var full := true
			for i in DarumaOtoshiHazard.LEVELS:
				var dn := _hz.disc_node(i)
				full = full and dn.visible and absf(dn.scale.y - 1.0) < 0.02
			var hy2 := absf(head.position.y - head_rest) < 0.05
			if vis2 == DarumaOtoshiHazard.LEVELS and full and hy2:
				rebuilt_ok += 1
			seen.append("c%d/reconstructie: %d discuri la scara 1: %s, cap %.2f (repaus %.2f)" % [cycles, vis2, str(full), head.position.y, head_rest])
	for line in seen:
		print("    " + line)
	print("  cicluri complete %d, lovituri (discuri zburate) %d, reconstructii OK %d" % [cycles, flights, rebuilt_ok])
	_verdict(cycles >= 2, "cel putin 2 cicluri mari complete (%d)" % cycles)
	_verdict(flights >= 10, "5 lovituri pe ciclu: %d discuri zburate pe %d cicluri (minim 10)" % [flights, cycles])
	_verdict(ok_levels and seen.size() >= 10, "turnul pierde cate un disc pe perioada (5, 4, 3, 2, 1 la fiecare ciclu)")
	_verdict(ok_head, "capul coboara cu un etaj (%.2f m) pe perioada, pana la %.2f m" % [h, min_h_seen])
	_verdict(rebuilt_ok >= 2, "reconstructia readuce turnul intreg (5 discuri, capul la repaus) de %d ori (minim 2)" % rebuilt_ok)
