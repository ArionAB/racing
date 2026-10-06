extends Node
## Sonda haboob-ului (Monument Valley, Track19; brief §3, §7 pasul 7): zidul de
## praf pe o DREAPTA sintetica, nu pe pista.
##
##  (0)   ceasul e deterministic (doua instante, aceleasi cifre bit cu bit);
##        la start zidul e in LINISTE (memoria `ceasul-porneste-in-prima-faza`);
##        perioada nu imparte turul.
##  (i)   masini REALE (jucator cu sofer de sonda la 20 si 30 m/s, trei
##        mașini; plus trei AI) trec prin zid. Vantul se masoara din viteza
##        LATERALA a corpului (`linear_velocity` pe directia de mers a zidului),
##        fata de o trecere de control FARA hazard, nu din functiile hazardului:
##        o sonda care compara hazardul cu propria lui functie iese 0,00 prin
##        constructie (memoria `garda-circulara-propria-functie`).
##        Fiecare masina: vant cand e inauntru, zero cand e afara; albire o
##        singura data pe trecere (doar jucatorul); nu iese din banda si nu se
##        opreste.
##  (ii)  mediul revine BIT-IDENTIC: toate campurile `fog_*` ale
##        `Environment`-ului, citite de sonda INAINTE sa existe hazardul, se
##        compara cu cele de dupa iesire (nu cu `base_fog()`, care e copia
##        hazardului). Si pe ceata exponentiala, si pe cea de adancime.
##  (iii) frontul MOBIL: ceasul liber, zidul ajunge din vest peste drum;
##        albire exact o data, ceata ajunge la `fog_end_inside`, mediul revine.
##  (iv)  materiale: quad-urile impart UN material; hazardul aduce cel mult 2.
##
## [b]--sabotaj[/b]: ruleaza aceleasi verdicte pe doua hazarduri stricate —
## unul care NU restaureaza ceata, unul cu vant ZERO. Garda e armata doar daca
## amandoua PICA. Cod de iesire: 1 = au picat amandoua (cum trebuie), 3 = un
## sabotaj a trecut (garda e moarta), 2 = n-am masurat nimic.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHaboob.tscn [-- --sabotaj]
## Iese cu cod 1 la orice verdict picat.

const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
const HALF_WIDTH: float = 10.0
const START_Z: float = 120.0
const FINISH_Z: float = -75.0
## Zidul: centrul pe z=20, jumatate de latime 40 => zid pe z in [-20, 60].
const WALL_Z: float = 20.0
const WALL_HALF_WIDTH: float = 40.0
const PATH_X: float = 300.0
## Momentul din ciclu la care centrul zidului e pe x=0 (`wall_speed` * t = PATH_X).
const T_CENTER: float = PATH_X / 7.0
## Cat de mult trebuie sa depaseasca viteza laterala medie din zid pe cea din
## control ca sa socotim ca vantul se simte (m/s). Cu 12 m/s^2 (implicit) se
## masoara ~+0.6..0.8; controlul pentru jucator/coast e 0.00.
const WIND_MIN_GAIN: float = 0.3

## Sofer care TINE viteza si nu virează: volan zero, gaz doar cat sa nu piarda
## viteza (fara gaz o masina de 30 m/s se opreste in cateva secunde din drag).
## Nimic din soferul asta nu contracareaza vantul, deci viteza laterala a corpului
## e raspunsul curat al masinii la forta.
class Coast extends CarController:
	var target_speed: float = 20.0
	var _throttle: float = 0.0
	func update(_delta: float) -> void:
		if car == null:
			return
		_throttle = 1.0 if car.horizontal_speed() < target_speed else -0.2
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return _throttle

class NoRestore extends HaboobHazard:
	## Sabotaj: nu restaureaza ceata cand iesi.
	func _apply(amount: float) -> void:
		if amount <= 0.0001:
			return
		super(amount)

class NoWind extends HaboobHazard:
	## Sabotaj: vant zero.
	func _wind_accel() -> float:
		return 0.0

var _track: TrackFromPath
var _hazard: HaboobHazard
var _env: Environment
var _fails: int = 0
var _measured: int = 0
var _sabotage: bool = false
## `--wind=N`: suprascrie acceleratia vantului (explorare: cat trebuie ca sa se simta).
var _wind_override: float = -1.0


func _ready() -> void:
	_sabotage = "--sabotaj" in OS.get_cmdline_user_args()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wind="):
			_wind_override = float(a.trim_prefix("--wind="))
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeHaboob"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame
	_env = _find_env(_track)
	if _env == null:
		print("PICAT: nu gasesc Environment-ul pistei (n-am masurat nimic)")
		get_tree().quit(2)
		return

	print("=== HABOOB%s ===" % (" (SABOTAJ)" if _sabotage else ""))
	if _sabotage:
		await _run_sabotage()
	else:
		await _run_normal()


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ---------------------------------------------------------------- utilitare

func _find_env(n: Node) -> Environment:
	if n is WorldEnvironment:
		return (n as WorldEnvironment).environment
	for c in n.get_children():
		var e := _find_env(c)
		if e != null:
			return e
	return null


## Toate campurile `fog_*` ale mediului, citite DIRECT din resursa — nu din
## hazard. Ceata e partea pe care o ating hazardurile de ceata, dar comparam tot
## ce incepe cu `fog_` ca un camp uitat sa nu scape.
func _fog_state() -> Dictionary:
	var out := {}
	for p in _env.get_property_list():
		var nm: String = p["name"]
		if nm.begins_with("fog_"):
			out[nm] = _env.get(nm)
	return out


func _diff_fog(a: Dictionary, b: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	for k in a.keys():
		if typeof(a[k]) != typeof(b[k]) or a[k] != b[k]:
			bad.append("%s: %s != %s" % [k, str(a[k]), str(b[k])])
	return bad


func _make_hazard(script_kind: String, half_width: float = WALL_HALF_WIDTH) -> HaboobHazard:
	var h: HaboobHazard
	match script_kind:
		"norestore":
			h = NoRestore.new()
		"nowind":
			h = NoWind.new()
		_:
			h = HaboobHazard.new()
	h.name = "Haboob"
	h.half_width = half_width
	h.dust_count = 32
	if _wind_override >= 0.0:
		h.wind_min = _wind_override
		h.wind_max = _wind_override
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	# Din vest (x negativ) spre est: vantul bate pe +X, peste soseaua de pe x=0.
	curve.add_point(Vector3(-PATH_X, 0.0, WALL_Z))
	curve.add_point(Vector3(PATH_X, 0.0, WALL_Z))
	path.curve = curve
	h.add_child(path)
	add_child(h)
	return h


func _spawn(kind: String, data_idx: int, speed: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[data_idx])
	car.track = _track
	var at := Vector3(0.0, 0.7, START_Z)
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	if kind == "coast":
		var hold := Coast.new()
		hold.target_speed = speed
		car.set_controller(hold)
	elif kind == "player":
		car.is_player = true
		var driver := WaypointDriver.new()
		driver.waypoints = [Vector3(0.0, 0.0, FINISH_Z - 40.0)]
		driver.target_speed = speed
		car.set_controller(driver)
	else:
		var ai := AIController.new()
		car.set_controller(ai)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261006 + data_idx
		ai.configure(_track, rng)
		ai.line_offset = 0.0
	return car


## O trecere. Intoarce statistici masurate pe CORPUL masinii si pe Environment.
## `hz` poate fi null (trecerea de control).
func _drive(kind: String, data_idx: int, speed: float, hz: HaboobHazard,
		moving: bool = false) -> Dictionary:
	var car := _spawn(kind, data_idx, speed)
	# Contoare in Array: lambda-ul captureaza primitivele PRIN VALOARE.
	var blinds: Array[int] = [0]
	car.blinded.connect(func(_c: Car, _s: float) -> void: blinds[0] += 1)
	var in_vx := -INF
	var in_vx_sum := 0.0
	var in_n := 0
	var out_vx_abs := 0.0
	var out_n := 0
	var out_fog := 0.0
	var in_fog := 0.0
	var max_x := 0.0
	var min_speed := INF
	var min_fog_end := INF
	var min_fog_dens := 0.0
	var max_fog_dens := 0.0
	var t := 0.0
	var respawned: Array[int] = [0]
	car.respawned.connect(func(_c: Car) -> void: respawned[0] += 1)
	while t < 26.0 and car.global_position.z > FINISH_Z:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var p := car.global_position
		var vx := car.linear_velocity.x
		max_x = maxf(max_x, absf(p.x))
		if t > 1.0:
			min_speed = minf(min_speed, car.horizontal_speed())
		var inside := p.z > WALL_Z - WALL_HALF_WIDTH + 8.0 and p.z < WALL_Z + WALL_HALF_WIDTH - 8.0
		var outside := p.z > WALL_Z + WALL_HALF_WIDTH + 18.0 or p.z < WALL_Z - WALL_HALF_WIDTH - 18.0
		if inside:
			in_vx = maxf(in_vx, vx)
			in_vx_sum += vx
			in_n += 1
		elif outside and t > 1.5:
			out_vx_abs = maxf(out_vx_abs, absf(vx))
			out_n += 1
		# Ceata din Environment (nu din hazard) in afara zonei de gameplay, dar in
		# volumul vizual: aici vantul trebuie sa fie zero, ceata nu.
		if outside and p.z > WALL_Z + WALL_HALF_WIDTH + 18.0 and p.z < WALL_Z + 190.0:
			out_fog = maxf(out_fog, _env.fog_density)
		if inside:
			in_fog = maxf(in_fog, _env.fog_density)
		if _env.fog_mode == Environment.FOG_MODE_DEPTH:
			min_fog_end = minf(min_fog_end, _env.fog_depth_end)
		else:
			max_fog_dens = maxf(max_fog_dens, _env.fog_density)
	var arrived := car.global_position.z <= FINISH_Z
	var res := {
		"arrived": arrived, "t": t, "blinds": blinds[0], "in_vx": in_vx,
		"in_vx_mean": in_vx_sum / maxf(float(in_n), 1.0), "in_n": in_n,
		"out_vx_abs": out_vx_abs, "out_n": out_n, "max_x": max_x,
		"min_speed": min_speed, "fog_end": min_fog_end, "fog_dens": max_fog_dens,
		"respawns": respawned[0], "out_fog": out_fog, "race_active": car.race_active,
	}
	car.queue_free()
	# Masina iese din scena inauntrul volumului vizual (ceata ajunge pana la
	# z=-180): lista de suprapuneri a zonei ramane veche un cadru, deci mediul se
	# restaureaza cu cateva cadre intarziere. Sabotajul (fara restaurare) ramane
	# prins: nu restaureaza NICIODATA.
	for _f in 6:
		await get_tree().physics_frame
	return res


func _fmt(r: Dictionary) -> String:
	return "%s %.1fs | vx dentro max %.2f med %.2f (n=%d) | vx afara max %.2f (n=%d) | x max %.2f | v min %.1f | albiri %d | ceata end %.1f dens %.4f | repuneri %d" % [
		"ajunsa" if r["arrived"] else "NEAJUNSA", r["t"], r["in_vx"], r["in_vx_mean"],
		r["in_n"], r["out_vx_abs"], r["out_n"], r["max_x"], r["min_speed"],
		r["blinds"], r["fog_end"], r["fog_dens"], r["respawns"]]


# ------------------------------------------------------------- verdicte comune

## Vantul, citit din corpul masinii: in zid viteza laterala depaseste cu
## `margin` pe cea din trecerea de control, iar afara e ca in control.
func _check_wind(label: String, r: Dictionary, ctrl: Dictionary,
		expect_wind: bool = true) -> void:
	_measured += 1
	_verdict(int(r["in_n"]) > 20 and int(ctrl["in_n"]) > 20,
		"%s: masurat (cadre in zid %d, control %d)" % [label, r["in_n"], ctrl["in_n"]])
	var gain: float = float(r["in_vx_mean"]) - float(ctrl["in_vx_mean"])
	print("    %s: viteza laterala medie in zid %.2f fata de control %.2f => +%.2f m/s"
		% [label, r["in_vx_mean"], ctrl["in_vx_mean"], gain])
	if expect_wind:
		_verdict(gain > WIND_MIN_GAIN, "%s: vantul chiar impinge masina lateral (+%.2f m/s)" % [label, gain])
	_verdict(float(r["out_vx_abs"]) < maxf(float(ctrl["out_vx_abs"]) + 0.6, 0.8),
		"%s: zero vant in afara zidului (|vx| %.2f, control %.2f)"
		% [label, r["out_vx_abs"], ctrl["out_vx_abs"]])


func _check_restored(label: String, before: Dictionary) -> void:
	var after := _fog_state()
	var bad := _diff_fog(before, after)
	for line in bad:
		print("    diferenta: " + line)
	_verdict(bad.is_empty(),
		"%s: mediul revine BIT-IDENTIC (%d campuri fog_* comparate, %d diferite)"
		% [label, before.size(), bad.size()])


# --------------------------------------------------------------------- normal

func _run_normal() -> void:
	# --- (0) ceasul
	print("--- (0) ceas deterministic, liniste la start, perioada")
	var trace_a := await _clock_trace()
	var trace_b := await _clock_trace()
	_verdict(trace_a.size() > 500 and trace_a == trace_b,
		"doua rulari, aceleasi cifre (%d esantioane, identice bit cu bit)" % trace_a.size())
	var probe := _make_hazard("normal")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var lap_s := 70.0
	_verdict(fmod(probe.period, lap_s) > 1.0 and not is_equal_approx(probe.period, lap_s),
		"perioada %.0f s nu imparte turul (~%.0f s)" % [probe.period, lap_s])
	var quiet_ok := true
	var t_q := probe.start_clock
	var first_cover := probe.cover_at(fposmod(t_q, probe.period))
	for k in 5:
		if probe.cover_at(fposmod(t_q + float(k), probe.period)) > 0.0:
			quiet_ok = false
	_verdict(quiet_ok and first_cover == 0.0,
		"la t=0 al cursei (start_clock %.0f) zidul e in LINISTE: acoperire 0 cel putin 5 s" % probe.start_clock)
	_verdict(probe.wall() != null and not probe.wall().visible,
		"si zidul e ascuns (vizibil=%s)" % str(probe.wall().visible if probe.wall() != null else "?"))
	var tel := probe.cover_at(probe.telegraph_time * 0.5)
	_verdict(tel > 0.0 and tel < 1.0 and probe.cover_at(probe.telegraph_time + 10.0) == 1.0,
		"telegraful creste (%.2f la jumatate), traversarea e plina" % tel)
	_verdict(probe.front_distance_at(10.0) < probe.front_distance_at(30.0),
		"frontul inainteaza cu timpul (functie de timp, nu viteza integrata)")
	probe.queue_free()
	await get_tree().physics_frame

	# --- controale FARA hazard
	print("--- controale (fara hazard): aceleasi masini, acelasi drum")
	var configs: Array = [
		["player", 0, 20.0], ["player", 1, 30.0], ["player", 2, 20.0],
		["player", 3, 30.0], ["player", 0, 30.0], ["player", 1, 20.0],
		["ai", 0, 22.0], ["ai", 1, 22.0], ["ai", 2, 22.0],
		["coast", 0, 20.0], ["coast", 1, 30.0], ["coast", 2, 20.0],
		["coast", 3, 30.0], ["coast", 0, 30.0], ["coast", 1, 20.0],
	]
	var ctrls: Array = []
	for c in configs:
		var r := await _drive(c[0], c[1], c[2], null)
		print("    control %s/%d/%.0f: %s" % [c[0], c[1], c[2], _fmt(r)])
		ctrls.append(r)

	var ai_v_ctrl := await _ai_speed_in_wall()
	print("    viteza medie AI in fereastra zidului, FARA hazard: %.2f" % ai_v_ctrl)

	# --- (i)+(ii) trecerile prin zid (frozen, centrat pe x=0)
	print("--- (i) masini reale prin zid (ceas inghetat, zid pe drum)")
	var before := _fog_state()
	_hazard = _make_hazard("normal")
	_hazard.force_clock = T_CENTER
	await get_tree().physics_frame
	await get_tree().physics_frame
	var wd := _hazard.wind_direction()
	_verdict(wd.dot(Vector3.RIGHT) > 0.99, "vantul bate pe directia de mers a zidului (%s)" % str(wd))
	_verdict(_hazard.cover() > 0.99, "zidul e plin la t=%.1f s (acoperire %.2f)" % [T_CENTER, _hazard.cover()])
	for i in configs.size():
		var c: Array = configs[i]
		var label := "%s car%d @%.0f" % [c[0], c[1], c[2]]
		var r := await _drive(c[0], c[1], c[2], _hazard)
		print("    %s: %s" % [label, _fmt(r)])
		_check_wind(label, r, ctrls[i], c[0] != "ai")
		_verdict(bool(r["arrived"]) and bool(r["race_active"]) and int(r["respawns"]) == 0,
			"%s: trece (ajunsa, in cursa, %d repuneri)" % [label, r["respawns"]])
		_verdict(float(r["max_x"]) < HALF_WIDTH - 0.5,
			"%s: nu iese din banda (|x| max %.2f din %.1f)" % [label, r["max_x"], HALF_WIDTH])
		_verdict(float(r["min_speed"]) > 5.0,
			"%s: nu se opreste (viteza min %.1f m/s)" % [label, r["min_speed"]])
		var want_blind := 1 if c[0] == "player" else 0
		_verdict(int(r["blinds"]) == want_blind,
			"%s: albiri %d (asteptat %d)" % [label, r["blinds"], want_blind])
		if c[0] == "player":
			# Ceata: pe mediul exponential al temei de test.
			var target := _hazard.fog_density_inside
			_verdict(float(r["out_fog"]) > target * 0.9,
				"%s: ceata se aplica si in volumul VIZUAL din afara zonei de gameplay (dens %.4f, cerut %.4f)"
				% [label, r["out_fog"], target])
			_verdict(float(r["fog_dens"]) > target * 0.9,
				"%s: ceata camerei s-a ingrosat in zid (dens %.4f, cerut %.4f)"
				% [label, r["fog_dens"], target])
		else:
			_verdict(float(r["fog_dens"]) <= float(ctrls[i]["fog_dens"]) + 0.0001,
				"%s: ceata camerei nu se misca pentru AI (%.4f)" % [label, r["fog_dens"]])
		_check_restored(label, before)

	# --- AI: tinta de viteza in miez
	print("--- AI: tinta de viteza in miezul zidului")
	var core := Vector3(0.0, 0.5, WALL_Z)
	var edge := Vector3(0.0, 0.5, WALL_Z + WALL_HALF_WIDTH + 30.0)
	var s_core := _hazard.ai_speed_scale_at(core)
	var s_out := _hazard.ai_speed_scale_at(edge)
	print("    scala in miez %.3f, in afara %.3f" % [s_core, s_out])
	_verdict(is_equal_approx(s_core, _hazard.ai_speed_factor) and is_equal_approx(s_out, 1.0),
		"scara AI: %.2f in miez, 1.00 in afara" % s_core)
	_verdict(get_tree().get_nodes_in_group(HaboobHazard.AI_SPEED_GROUP).has(_hazard),
		"hazardul e in grupul `ai_speed_zones`")
	# Masurat pe CORP: o masina AI chiar merge mai incet in zid decat in control.
	# Zid LARG (jumatate de latime 200 m, ca cel real de ~400 m): AI-ul are timp sa
	# reactioneze. In cel de 80 m al restului sondei traversarea dureaza 2 s si
	# franarea abia incepe.
	var h_ai := _make_hazard("normal", 200.0)
	h_ai.force_clock = T_CENTER
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ai_v_wall := await _ai_speed_in_wall()
	h_ai.queue_free()
	await get_tree().physics_frame
	print("    viteza medie AI in fereastra zidului: control %.2f, cu zid %.2f (%.1f%%)"
		% [ai_v_ctrl, ai_v_wall, 100.0 * ai_v_wall / maxf(ai_v_ctrl, 0.01)])
	_verdict(ai_v_ctrl > 5.0 and ai_v_wall < ai_v_ctrl * 0.97 and ai_v_wall > ai_v_ctrl * 0.80,
		"AI-ul chiar incetineste ~10%% in zid (%.2f fata de %.2f)" % [ai_v_wall, ai_v_ctrl])

	# --- ceata de ADANCIME
	print("--- (ii-b) acelasi zid pe ceata de ADANCIME")
	_hazard.queue_free()
	await get_tree().physics_frame
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_depth_begin = 90.0
	_env.fog_depth_end = 250.0
	var before_d := _fog_state()
	_hazard = _make_hazard("normal")
	_hazard.force_clock = T_CENTER
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rd := await _drive("player", 1, 30.0, _hazard)
	print("    adancime: %s" % _fmt(rd))
	_verdict(absf(float(rd["fog_end"]) - _hazard.fog_end_inside) < _hazard.fog_end_inside * 0.1,
		"vederea a ajuns la fog_end_inside (%.1f cerut %.1f)" % [rd["fog_end"], _hazard.fog_end_inside])
	_check_restored("adancime", before_d)
	_hazard.queue_free()
	await get_tree().physics_frame

	# --- (iii) frontul mobil
	print("--- (iii) frontul MOBIL peste drum (ceas liber)")
	_env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	var before_m := _fog_state()
	_hazard = _make_hazard("normal")
	# Frontul (centrul - 35 m) ajunge pe x=0 la s = 300 - 35 => t = 265/7; plec cu
	# ~5 s inainte. Ceasul curge liber din acest punct.
	var t_front := (PATH_X - _hazard.length * 0.5) / _hazard.wall_speed
	_hazard.start_clock = t_front - 5.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rm := await _drive("player", 0, 8.0, _hazard, true)
	print("    mobil: %s" % _fmt(rm))
	_verdict(int(rm["blinds"]) == 1, "frontul mobil albeste o singura data (%d)" % rm["blinds"])
	_verdict(float(rm["fog_dens"]) > 0.0 and float(rm["fog_dens"]) > _env.fog_density * 1.5,
		"ceata s-a ingrosat cand frontul a trecut (dens %.4f)" % rm["fog_dens"])
	for _f in 30:
		await get_tree().physics_frame
	# Dupa iesire din zid, dar cat timp ceasul inca ruleaza, mediul trebuie sa fie
	# curat: masina a disparut (queue_free) deci nimeni nu mai e in zid.
	_check_restored("front mobil", before_m)
	_hazard.queue_free()
	await get_tree().physics_frame

	# --- (iv) materiale
	print("--- (iv) materiale")
	var h := _make_hazard("normal")
	await get_tree().physics_frame
	var mats := {}
	for q in h.quads():
		mats[(q.material_override as Material).get_instance_id()] = true
	_verdict(mats.size() == 1 and h.quads().size() >= 2,
		"%d quad-uri, un singur material partajat (%d)" % [h.quads().size(), mats.size()])
	var dust_mat: Material = null
	for ch in h.wall().get_children():
		if ch is CPUParticles3D:
			dust_mat = ((ch as CPUParticles3D).mesh as PrimitiveMesh).material
			_verdict((ch as CPUParticles3D).amount <= 32, "praf: %d particule (<= 32)" % (ch as CPUParticles3D).amount)
	_verdict(dust_mat != null and dust_mat != h.quads()[0].material_override,
		"praful are materialul lui partajat (al doilea)")
	print("    materiale noi aduse de hazard: wall_material + dust_material = 2")
	print("    tumbleweeds: %d (doar vizuale, fara coliziune: %s)" % [h.weeds().size(),
		str(not _has_collision(h.weeds()))])
	_verdict(h.weeds().size() >= 4 and not _has_collision(h.weeds()),
		"4-8 tumbleweeds, fara coliziune")
	h.queue_free()
	await get_tree().physics_frame
	_finish()


func _has_collision(nodes: Array[Node3D]) -> bool:
	for n in nodes:
		for c in n.find_children("*", "CollisionObject3D", true, false):
			return true
	return false


## Viteza medie a unei masini AI pe z in [-60, 40] (in zidul larg, centrat pe z=20).
func _ai_speed_in_wall() -> float:
	var car := _spawn("ai", 1, 22.0)
	var sum := 0.0
	var n := 0
	var t := 0.0
	while t < 26.0 and car.global_position.z > FINISH_Z:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var z := car.global_position.z
		if z < 40.0 and z > -60.0:
			sum += car.horizontal_speed()
			n += 1
	car.queue_free()
	await get_tree().physics_frame
	return sum / maxf(float(n), 1.0)


## Urma ceasului pe 900 de cadre: (timp in ciclu, acoperire, front, pozitia
## zidului), ca text — egalitatea de siruri e egalitate bit cu bit a reprezentarii.
func _clock_trace() -> Array:
	var h := _make_hazard("normal")
	h.start_clock = 70.0 # traverseaza telegraful -> risipire in 900 de cadre
	var out: Array = []
	for _f in 900:
		await get_tree().physics_frame
		out.append("%s|%s|%s|%s" % [var_to_str(h.cycle_time()), var_to_str(h.cover()),
			var_to_str(h.wall().global_position), var_to_str(h.wall().visible)])
	h.queue_free()
	await get_tree().physics_frame
	return out


# ------------------------------------------------------------------- sabotaj

func _run_sabotage() -> void:
	var ctrl := await _drive("player", 1, 30.0, null)
	print("    control: %s" % _fmt(ctrl))

	print("--- sabotaj 1: NU restaureaza ceata la iesire (trebuie sa PICE)")
	var before := _fog_state()
	var h1 := _make_hazard("norestore")
	h1.force_clock = T_CENTER
	await get_tree().physics_frame
	await get_tree().physics_frame
	var r1 := await _drive("player", 1, 30.0, h1)
	print("    %s" % _fmt(r1))
	var fails_before := _fails
	for _f in 30:
		await get_tree().physics_frame
	_check_restored("sabotaj/norestore", before)
	var caught_restore := _fails > fails_before
	h1.queue_free()
	await get_tree().physics_frame
	# Curat mediul stricat de sabotaj ca al doilea sa porneasca de la baza.
	for k in before.keys():
		_env.set(k, before[k])

	print("--- sabotaj 2: vant ZERO (trebuie sa PICE)")
	var h2 := _make_hazard("nowind")
	h2.force_clock = T_CENTER
	await get_tree().physics_frame
	await get_tree().physics_frame
	var r2 := await _drive("player", 1, 30.0, h2)
	print("    %s" % _fmt(r2))
	fails_before = _fails
	_check_wind("sabotaj/nowind", r2, ctrl)
	var caught_wind := _fails > fails_before
	h2.queue_free()
	await get_tree().physics_frame

	print("=== SABOTAJ: restaurare %s, vant %s ===" % [
		"PRINS" if caught_restore else "NEPRINS", "PRINS" if caught_wind else "NEPRINS"])
	if _measured == 0:
		print("n-am masurat nimic")
		get_tree().quit(2)
	elif caught_restore and caught_wind:
		print("garda ARMATA: ambele sabotaje au picat (cod 1)")
		get_tree().quit(1)
	else:
		print("GARDA MOARTA: un sabotaj a trecut (cod 3)")
		get_tree().quit(3)


func _finish() -> void:
	if _measured == 0:
		print("=== PICAT: n-am masurat nimic ===")
		get_tree().quit(2)
		return
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)
