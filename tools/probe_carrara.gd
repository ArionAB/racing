extends Node
## Sondele tehnice AI de dinaintea pistei Carrara (brief docs/track_briefs/
## carrara.md §7 pasul 1 (a) si (b)), pe pista SINTETICA tools/SondaCarrara.tscn.
##
##   (a) doua camioane (BusHazard, Kamaz) pe aceeasi bucla, phase 0.0 / 0.5,
##       urca terasele IN SENS INVERS cursei pe banda STANGA a cursei;
##   (b) excavatorul (ExcavatorHazard) parcat pe o dreapta de 400 m / 10 m.
##
## Ruleaza CA SCENA (Car are nevoie de autoload-uri), headless:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarrara.tscn -- \
##       --config=trucks --seed=3 --seconds=200 --out=C:/tmp/r_trucks_3.json
##
## `--config=` base | trucks | exc | both   (ce hazard ramane in scena; restul se
##   scoate INAINTE de prima fizica — acelasi tipar ca `--no-tub` din ProbeRace).
## `--scene=res://tools/SondaCarraraHint.tscn`  alta varianta de scena.
## `--ai-cars=3,1,4,5,8,7,2`  lineup-ul AI (indecsi in CAR_DATA); jucatorul = --car.
## `--apex=0.5 --shove=3 --side-accel=8`  exporturile BusHazard, suprascrise.
## `--dump-route=<csv>`  scrie axa coapta (x,y,z,half_width,frac) si iese.
## `--diag`  doar pozitia hazardelor (camioane/brat) fata de drum, fara cursa.
##
## Iesirea JSON (`--out=`) o citeste tools/carrara_sonda_report.py (tabele
## cu/fara pe 16 seed-uri). Memoria `proberace-nedeterminism`: Jolt e
## multithread, deci se compara DISTRIBUTII pe seed-uri, nu o rulare.
##
## [b]Limita asumata[/b] (memoria `harnas-sintetic-comportament-emergent`):
## bucla e sintetica, deci cifrele valideaza MECANISMUL si ordinul de marime;
## verdictul de flota se da pe Track23, cu ProbeRace, cand exista.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const APPROACH_M: float = 60.0
const BUCKET_M: float = 10.0
const CONTACT_GAP_S: float = 0.5
const TRUCK_HALF_W: float = 1.34

var _scene: String = "res://tools/SondaCarrara.tscn"
var _config: String = "base"
var _seed: int = 20260729
var _seconds: float = 200.0
var _player_car: int = 0
var _ai_cars: Array[int] = [3, 1, 4, 5, 8, 7, 2]
var _out: String = ""
var _dump_route: String = ""
var _diag: bool = false
var _apex: float = -1.0
var _shove: float = -1.0
var _side_accel: float = -1.0
var _equal_speed: bool = false
var _label: String = ""

var _race: Node = null
var _track: Track = null
var _t: float = 0.0
var _done: bool = false
var _len: float = 1.0
var _zones: Dictionary = {}
var _trucks: Array = []   # BusHazard
var _exc: Node = null     # ExcavatorHazard
var _exc_dist: float = -1.0
var _exc_lat_lo: float = 0.0
var _exc_lat_hi: float = 0.0

# --- per masina ---
var _c: Array[Dictionary] = []
# --- evenimente ---
var _encounters: Array[Dictionary] = []
var _contacts: Array[Dictionary] = []
var _exc_events: Array[Dictionary] = []
var _blocaj: Array[Dictionary] = []
var _respawns: Array[Dictionary] = []
var _truck_stats: Dictionary = {}
var _truck_rows: Array = []
var _truck_events: Array = []
var _truck_rc: Array = [Vector2(1e9, 1e9), Vector2(1e9, 1e9)]
var _ejects: Array[Dictionary] = []
var _last_eject: Dictionary = {}
var _truck_offroad_ticks: int = 0
var _hairpin: Dictionary = {"n": 0, "n_right": 0, "n_inside": 0, "cars": {}}
var _exc_arm_rows: Array = []
var _exc_block_ticks: int = 0
var _exc_ticks: int = 0
var _arm_down_prev: bool = false
var _arm_t_down: float = 0.0
var _arm_cycles: Array[float] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--config="):
			_config = arg.trim_prefix("--config=")
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--car="):
			_player_car = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--ai-cars="):
			_ai_cars.clear()
			for s in arg.trim_prefix("--ai-cars=").split(","):
				_ai_cars.append(int(s))
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--dump-route="):
			_dump_route = arg.trim_prefix("--dump-route=")
		elif arg.begins_with("--apex="):
			_apex = float(arg.trim_prefix("--apex="))
		elif arg.begins_with("--shove="):
			_shove = float(arg.trim_prefix("--shove="))
		elif arg.begins_with("--side-accel="):
			_side_accel = float(arg.trim_prefix("--side-accel="))
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg == "--equal-speed":
			_equal_speed = true
		elif arg == "--diag":
			_diag = true
	if not _dump_route.is_empty():
		_do_dump_route.call_deferred()
		return
	_start_race()


# ------------------------------------------------------------ dump de ruta

func _do_dump_route() -> void:
	var t := (load(_scene) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4:
		await get_tree().process_frame
	var r: TrackRoute = t.routes[0]
	var n := r.baked.size()
	var f := FileAccess.open(_dump_route, FileAccess.WRITE)
	f.store_line("x,y,z,half_width,frac")
	for i in n:
		var p: Vector3 = r.baked[i]
		f.store_line("%.3f,%.3f,%.3f,%.3f,%.5f" % [p.x, p.y, p.z,
			t.width_at_index(i), r.frac_at(i)])
	f.close()
	print("dump-route: %d puncte, lungime %.1f m, bake_interval %.2f -> %s" % [
		n, r.length(), t.curve.bake_interval, _dump_route])
	get_tree().quit(0)


# ----------------------------------------------------------------- cursa

func _start_race() -> void:
	GameState.selected_track = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.traffic_override = -1
	GameState.ai_cars_override = _ai_cars
	GameState.selected_car = clampi(_player_car, 0, GameState.CAR_DATA.size() - 1)
	GameState.ai_count = _ai_cars.size()
	GameState.track_scene_override = _scene
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	_track = _race.track
	_len = _track.routes[0].length()
	var z: Variant = _track.get_meta("zones", {})
	_zones = z if z is Dictionary else {}
	# hazardele: ce nu e cerut se scoate acum, inainte de prima fizica
	var want_trucks := _config == "trucks" or _config == "both"
	var want_exc := _config == "exc" or _config == "both"
	for n in _track.find_children("*", "BusHazard", true, false):
		if want_trucks:
			_trucks.append(n)
		else:
			n.free()
	for n in _track.find_children("*", "ExcavatorHazard", true, false):
		if want_exc:
			_exc = n
		else:
			n.free()
	_trucks.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name) < String(b.name))
	for tr in _trucks:
		if _apex >= 0.0:
			tr.apex_outer_m = _apex
		if _shove >= 0.0:
			tr.shove = _shove
		if _side_accel >= 0.0:
			tr.side_accel = _side_accel
	if want_trucks and _trucks.is_empty():
		push_error("probe_carrara: --config=%s dar scena n-are BusHazard" % _config)
		get_tree().quit(2)
		return
	if want_exc and _exc == null:
		push_error("probe_carrara: --config=%s dar scena n-are ExcavatorHazard" % _config)
		get_tree().quit(2)
		return
	for j in _trucks.size():
		var jj := j
		(_trucks[j] as BusHazard).descent_started.connect(func(_b: BusHazard) -> void:
			_truck_events.append([jj, "porneste", snappedf(_t, 0.1)]))
		(_trucks[j] as BusHazard).descent_ended.connect(func(_b: BusHazard) -> void:
			_truck_events.append([jj, "ascuns", snappedf(_t, 0.1)]))
	if _diag:
		_diag_setup()
		return
	# Jucatorul primeste tot un creier AI (ca in ProbeRace): masuram pista.
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	(_race._rng as RandomNumberGenerator).seed = _seed
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == player:
			var ai := AIController.new()
			car.set_controller(ai)
			var visible: Array[Car] = cars.duplicate()
			ai.configure(_track, rng, visible)
		else:
			(car.controller as AIController).line_offset = rng.randf_range(-0.35, 0.35)
		var roll := rng.randf_range(0.88, 0.97)
		car.speed_scale = 1.0 if (car == player or _equal_speed) else roll
		var st := {
			"name": "%s (%s)" % [car.pilot_name, car.car_name],
			"car_name": car.car_name, "mass": car.mass,
			"mass_factor": car.data.mass_factor if car.data != null else 1.0,
			"line_offset": (car.controller as AIController).line_offset,
			"slow_s": 0.0, "rev_s": 0.0, "off_s": 0.0, "stuck_t": 0.0,
			"stuck_reports": 0, "respawns": 0, "walls": 0,
			"u": 0.0, "u_init": false, "last_d": 0.0, "off": 0.0,
			"max_k": -999999, "cross": [], "laps_t": [], "lap_n": 0,
			"tc_last": [-99.0, -99.0], "tc_open": [-1, -1],
			"ec_last": -99.0, "ec_open": -1,
			"enc_open": [-1, -1], "last_contact_t": -99.0,
			"prev": {}, "exc_prev_delta": 0.0, "exc_pass_done": -1,
			"wall_count": 0,
		}
		_c.append(st)
		var idx := i
		car.respawned.connect(func(_cc: Car) -> void: _on_respawn(idx))
		car.wall_hit.connect(func(_cc: Car, _imp: float) -> void:
			_c[idx].walls = int(_c[idx].walls) + 1)
		car.ejected.connect(func(cc: Car, _rd: Node3D) -> void: _on_eject(idx, cc))
	if _exc != null:
		_locate_exc()
	print("probe_carrara: scena %s config=%s seed=%d lungime %.1f m, %d camioane, excavator=%s, zone=%s" % [
		_scene.get_file(), _config, _seed, _len, _trucks.size(), str(_exc != null), str(_zones)])


func _locate_exc() -> void:
	# axa + extinderea LATERALA a bratului (cutia lui de coliziune), in
	# coordonatele soselei: (distanta de-a lungul, lateral cu semn, + dreapta).
	var pos: Vector3 = _exc.global_position
	var idx := _track.closest_index_global(pos)
	var rc := _track.road_coords(idx, pos)
	_exc_dist = rc.x
	var shape: CollisionShape3D = _exc._arm_shape
	var box := shape.shape as BoxShape3D
	var lo := 1e9
	var hi := -1e9
	for sx in [-0.5, 0.5]:
		for sy in [-0.5, 0.5]:
			for sz in [-0.5, 0.5]:
				var w: Vector3 = shape.global_transform * (box.size * Vector3(sx, sy, sz))
				var wi := _track.closest_index_global(w)
				var l := _track.road_coords(wi, w).y
				lo = minf(lo, l)
				hi = maxf(hi, l)
	_exc_lat_lo = lo
	_exc_lat_hi = hi
	var hw := _track.width_at_index(idx)
	print("excavator: dist %.1f m, parcat la lateral %.2f (hw %.2f); BRAT lateral [%.2f, %.2f], inaltime y [%.2f, %.2f]" % [
		_exc_dist, rc.y, hw, lo, hi, shape.global_position.y - box.size.y * 0.5,
		shape.global_position.y + box.size.y * 0.5])


func _diag_setup() -> void:
	if _exc != null:
		_locate_exc()
	print("probe_carrara --diag: doar hazardele, %.0f s" % _seconds)


func _zone_of(frac: float) -> String:
	for k: String in _zones:
		var v: Vector2 = _zones[k]
		if frac >= v.x and frac <= v.y:
			return k
	return "RET"


func _physics_process(delta: float) -> void:
	if _done or _race == null:
		return
	if _diag:
		_t += delta
		_tick_trucks_diag()
		_tick_exc_diag()
		if _t >= _seconds:
			_finish()
		return
	if _race.state != Race.State.RUNNING:
		return
	_t += delta
	_tick_trucks_diag()
	_tick_exc_diag()
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		_tick_car(i, cars[i], delta)
	if _t >= _seconds:
		_finish()


# ----------------------------------------------------- hazarde (adevarul)

func _tick_trucks_diag() -> void:
	for j in _trucks.size():
		var tr: BusHazard = _trucks[j]
		if tr.is_hidden():
			_truck_rc[j] = Vector2(1e9, 1e9)
			continue
		var pos: Vector3 = tr._body.global_position
		var idx := _track.closest_index_global(pos)
		var rc := _track.road_coords(idx, pos)
		_truck_rc[j] = rc
		var hw := _track.width_at_index(idx)
		var zone := _zone_of(_track.frac_at(idx))
		# intrarea/iesirea de serviciu (in afara drumului) nu intra in statistica
		# pe zone: sunt contorizate separat
		if absf(rc.y) > hw + 1.5:
			_truck_offroad_ticks += 1
			continue
		var s: Dictionary = _truck_stats.get(zone, {"n": 0, "sum": 0.0, "lo": 1e9,
			"hi": -1e9, "inner": -1e9, "outer_over": -1e9, "hw": hw})
		s.hw = minf(float(s.hw), hw)
		s.n = int(s.n) + 1
		s.sum = float(s.sum) + rc.y
		s.lo = minf(float(s.lo), rc.y)
		s.hi = maxf(float(s.hi), rc.y)
		# marginea INTERIOARA a corpului (spre axa) si cat iese marginea
		# EXTERIOARA peste asfalt: pozitiv = in afara carosabilului
		s.inner = maxf(float(s.inner), rc.y + TRUCK_HALF_W)
		s.outer_over = maxf(float(s.outer_over), -rc.y + TRUCK_HALF_W - hw)
		_truck_stats[zone] = s
		if int(_t * 2.0) != int((_t - 1.0 / 60.0) * 2.0) and _truck_rows.size() < 4000:
			_truck_rows.append([snappedf(_t, 0.01), j, snappedf(rc.x, 0.1),
				snappedf(rc.y, 0.01), zone, snappedf(tr.distance(), 0.1)])


func _tick_exc_diag() -> void:
	if _exc == null:
		return
	var shape: CollisionShape3D = _exc._arm_shape
	var blocking := not shape.disabled
	_exc_ticks += 1
	if blocking:
		_exc_block_ticks += 1
	if blocking and not _arm_down_prev:
		_arm_cycles.append(_t)
	_arm_down_prev = blocking


# ------------------------------------------------------------- masini

func _tick_car(i: int, car: Car, delta: float) -> void:
	var c := _c[i]
	var speed := car.horizontal_speed()
	var rc := _track.road_coords(car.road_index, car.global_position)
	var frac := _track.frac_at(car.road_index, car.route)
	var zone := _zone_of(frac)
	var on_road := _track.is_on_road(car.road_index, car.global_position, car.route)
	# distanta desfasurata (m de la linia de start; grila e inainte = negativ)
	var d := rc.x
	if not bool(c.u_init):
		c.u_init = true
		c.off = -_len if d > _len * 0.5 else 0.0
		c.last_d = d
	var dd: float = d - float(c.last_d)
	if dd < -_len * 0.5:
		c.off = float(c.off) + _len
	elif dd > _len * 0.5:
		c.off = float(c.off) - _len
	c.last_d = d
	var u: float = float(c.off) + d
	c.u = u
	var k := int(floor(u / BUCKET_M)) + 40
	if k > int(c.max_k):
		if int(c.max_k) == -999999:
			c.max_k = k - 1
		for kk in range(int(c.max_k) + 1, k + 1):
			(c.cross as Array).append([kk, snappedf(_t, 0.001)])
		c.max_k = k
	var lap_n := int(floor(u / _len))
	if lap_n > int(c.lap_n) and lap_n >= 1:
		(c.laps_t as Array).append(snappedf(_t, 0.001))
	c.lap_n = maxi(int(c.lap_n), lap_n)
	if speed < 4.0:
		c.slow_s = float(c.slow_s) + delta
	if car.controller != null and car.controller.get_throttle() < -0.5:
		c.rev_s = float(c.rev_s) + delta
	if not on_road:
		c.off_s = float(c.off_s) + delta

	# --- hazarde: distante, contacte, intalniri ---
	# O INTALNIRE = camionul e pe ACELASI drum cu masina (diferenta de distanta
	# pe ruta, lateral < 10 m), in fata ei pe sensul cursei, la mai putin de
	# APPROACH_M. Terasa de alaturi (30 m lateral) nu conteaza.
	var near_truck := 1e9
	for j in _trucks.size():
		var tr: BusHazard = _trucks[j]
		if tr.is_hidden():
			_close_encounter(i, j, car, u, "ascuns")
			continue
		var tp: Vector3 = tr._body.global_position
		var dist := Vector2(car.global_position.x - tp.x, car.global_position.z - tp.z).length()
		var trc: Vector2 = _truck_rc[j]
		var ahead: float = trc.x - d
		if ahead > _len * 0.5:
			ahead -= _len
		elif ahead < -_len * 0.5:
			ahead += _len
		var same_road: bool = absf(trc.y - rc.y) < 10.0 and absf(trc.y) < 8.0
		if same_road:
			near_truck = minf(near_truck, dist)
		var open: bool = int((c.enc_open as Array)[j]) >= 0
		if same_road and ((not open and ahead > 0.0 and ahead < APPROACH_M) 				or (open and ahead > -8.0 and ahead < APPROACH_M + 10.0)):
			_update_encounter(i, j, car, tr, dist, u, rc, zone, speed)
			if zone == "H1" or zone == "H2":
				_hairpin.n = int(_hairpin.n) + 1
				if rc.y > 0.0:
					_hairpin.n_right = int(_hairpin.n_right) + 1
				if (zone == "H1" and rc.y > 0.0) or (zone == "H2" and rc.y < 0.0):
					_hairpin.n_inside = int(_hairpin.n_inside) + 1
				var pc: Dictionary = _hairpin.cars
				var rec: Array = pc.get(i, [0, 0.0])
				rec[0] = int(rec[0]) + 1
				rec[1] = float(rec[1]) + rc.y
				pc[i] = rec
		else:
			_close_encounter(i, j, car, u, "plecat")
	var near_exc := 1e9
	if _exc != null:
		near_exc = Vector2(car.global_position.x - _exc.global_position.x,
			car.global_position.z - _exc.global_position.z).length()

	var hit_truck := -1
	var hit_exc := false
	for hit in car.get_colliding_bodies():
		var hn := hit as Node
		if hn == null:
			continue
		var par := hn.get_parent()
		if par is BusHazard:
			hit_truck = _trucks.find(par)
		elif hn is ExcavatorHazard:
			hit_exc = true
	if hit_truck >= 0:
		_contact_truck(i, hit_truck, car, rc, zone, speed)
	if hit_exc:
		_contact_exc(i, car, rc, speed)
	if hit_truck >= 0 or hit_exc:
		c.last_contact_t = _t
	_tick_exc_pass(i, car, rc, speed)
	_track_open_contacts(i, speed)

	# --- blocaj (copie din ProbeRace._watch_stuck, cu atribuire) ---
	if speed > 6.0:
		c.stuck_t = 0.0
	else:
		c.stuck_t = float(c.stuck_t) + delta
		if float(c.stuck_t) >= 3.0 and int(c.stuck_reports) < 6:
			c.stuck_t = 0.0
			c.stuck_reports = int(c.stuck_reports) + 1
			var touching: Array[String] = []
			for body in car.get_colliding_bodies():
				var hb := body as Node3D
				if hb != null:
					var nm := String(hb.name)
					if hb.get_parent() is BusHazard:
						nm = "CAMION:" + String(hb.get_parent().name)
					elif hb is ExcavatorHazard:
						nm = "EXCAVATOR"
					touching.append(nm)
			var rec := {"t": snappedf(_t, 0.1), "car": i, "name": c.name,
				"frac": snappedf(frac, 0.001), "zone": zone, "v": snappedf(speed, 0.1),
				"lat": snappedf(rc.y, 0.1), "touching": touching,
				"truck_d": snappedf(near_truck, 0.1), "exc_d": snappedf(near_exc, 0.1),
				"since_contact": snappedf(_t - float(c.last_contact_t), 0.1),
				"on_road": on_road}
			_blocaj.append(rec)
			print("[blocaj] t=%5.1fs  %-18s frac=%.3f zona=%s v=%4.1f lat=%4.1f camion@%.0fm exc@%.0fm contact_acum %.1fs  atinge: %s" % [
				_t, c.name, frac, zone, speed, rc.y, near_truck, near_exc,
				_t - float(c.last_contact_t),
				", ".join(touching) if not touching.is_empty() else "-"])
	# starea anterioara (pentru respawn)
	c.prev = {"frac": frac, "zone": zone, "lat": rc.y, "speed": speed,
		"truck_d": near_truck, "exc_d": near_exc, "u": u, "on_road": on_road,
		"y": car.global_position.y, "road_y": _track.point_at(car.road_index, car.route).y}


func _on_eject(i: int, car: Car) -> void:
	if _race.state != Race.State.RUNNING:
		return
	var p: Dictionary = _c[i].prev
	_last_eject[i] = _t
	_ejects.append({"t": snappedf(_t, 0.1), "car": i, "name": _c[i].name,
		"cause": car.last_eject_cause, "value": snappedf(car.last_eject_value, 0.1),
		"zone": p.get("zone", "?"), "frac": snappedf(float(p.get("frac", -1.0)), 0.001),
		"lat": snappedf(float(p.get("lat", 0.0)), 0.1),
		"truck_d": snappedf(float(p.get("truck_d", 1e9)), 0.1),
		"since_contact": snappedf(_t - float(_c[i].last_contact_t), 0.1)})
	print("[ejectare] t=%5.1fs %-18s %s dv=%.1f zona=%s lat=%.1f camion@%.0fm contact_acum %.1fs" % [
		_t, _c[i].name, car.last_eject_cause, car.last_eject_value, p.get("zone", "?"),
		float(p.get("lat", 0.0)), float(p.get("truck_d", 1e9)), _t - float(_c[i].last_contact_t)])


func _on_respawn(i: int) -> void:
	if _race.state != Race.State.RUNNING:
		return
	var c := _c[i]
	c.respawns = int(c.respawns) + 1
	var p: Dictionary = c.prev
	var rec := {"t": snappedf(_t, 0.1), "car": i, "name": c.name,
		"frac": snappedf(float(p.get("frac", -1.0)), 0.001), "zone": p.get("zone", "?"),
		"lat": snappedf(float(p.get("lat", 0.0)), 0.1),
		"v": snappedf(float(p.get("speed", 0.0)), 0.1),
		"truck_d": snappedf(float(p.get("truck_d", 1e9)), 0.1),
		"exc_d": snappedf(float(p.get("exc_d", 1e9)), 0.1),
		"since_contact": snappedf(_t - float(c.last_contact_t), 0.1),
		"on_road": p.get("on_road", true),
		"eject": _t - float(_last_eject.get(i, -99.0)) < 3.0,
		"drop_m": snappedf(float(p.get("road_y", 0.0)) - float(p.get("y", 0.0)), 0.1)}
	_respawns.append(rec)
	print("[repunere] t=%5.1fs %-18s frac=%.3f zona=%s lat=%4.1f v=%4.1f camion@%.0fm exc@%.0fm contact_acum %.1fs cadere %.1fm" % [
		_t, c.name, float(rec.frac), rec.zone, float(rec.lat), float(rec.v),
		float(rec.truck_d), float(rec.exc_d), float(rec.since_contact),
		float(rec.drop_m)])


# ------------------------------------------------------- intalniri camion

func _update_encounter(i: int, j: int, car: Car, tr: BusHazard, dist: float, u: float,
		rc: Vector2, zone: String, speed: float) -> void:
	var c := _c[i]
	var open: Array = c.enc_open
	if int(open[j]) < 0:
		_encounters.append({"car": i, "truck": j, "t_in": snappedf(_t, 0.01),
			"u_in": snappedf(u, 0.1), "zone_in": zone, "d_min": dist, "t_min": _t,
			"zone_min": zone, "lat_min": rc.y, "tlat_min": 0.0, "v_in": speed,
			"v_min": speed, "contact": false, "contact_frames": 0,
			"t_out": -1.0, "u_out": -1.0, "reason": "", "respawn": false,
			"head_on": false})
		open[j] = _encounters.size() - 1
	var e: Dictionary = _encounters[int(open[j])]
	e.v_min = minf(float(e.v_min), speed)
	if dist < float(e.d_min):
		e.d_min = dist
		e.t_min = _t
		e.zone_min = zone
		e.lat_min = rc.y
		var tp: Vector3 = tr._body.global_position
		var ti := _track.closest_index_global(tp)
		e.tlat_min = _track.road_coords(ti, tp).y
		var fwd := -car.global_transform.basis.z
		var tfwd := -tr._body.global_transform.basis.z
		e.head_on = Vector2(fwd.x, fwd.z).normalized().dot(
			Vector2(tfwd.x, tfwd.z).normalized()) < -0.3


func _close_encounter(i: int, j: int, car: Car, u: float, reason: String) -> void:
	var c := _c[i]
	var open: Array = c.enc_open
	if int(open[j]) < 0:
		return
	var e: Dictionary = _encounters[int(open[j])]
	e.t_out = snappedf(_t, 0.01)
	e.u_out = snappedf(u, 0.1)
	e.reason = reason
	e.d_min = snappedf(float(e.d_min), 0.1)
	e.t_min = snappedf(float(e.t_min), 0.01)
	e.lat_min = snappedf(float(e.lat_min), 0.01)
	e.tlat_min = snappedf(float(e.tlat_min), 0.01)
	e.v_in = snappedf(float(e.v_in), 0.1)
	e.v_min = snappedf(float(e.v_min), 0.1)
	open[j] = -1


func _contact_truck(i: int, j: int, car: Car, rc: Vector2, zone: String, speed: float) -> void:
	var c := _c[i]
	var last: Array = c.tc_last
	var open: Array = c.tc_open
	if _t - float(last[j]) > CONTACT_GAP_S:
		var tr: BusHazard = _trucks[j]
		var rel: Vector3 = tr._body.global_transform.affine_inverse() * car.global_position
		var fwd := -car.global_transform.basis.z
		var tfwd := -tr._body.global_transform.basis.z
		_contacts.append({"t": snappedf(_t, 0.01), "car": i, "name": c.name,
			"truck": j, "frac": snappedf(_track.frac_at(car.road_index), 0.001),
			"zone": zone, "lat": snappedf(rc.y, 0.01), "v_in": snappedf(speed, 0.1),
			"v_min": speed, "frames": 0, "rel_x": snappedf(rel.x, 0.01),
			"rel_z": snappedf(rel.z, 0.01),
			"head_on": Vector2(fwd.x, fwd.z).normalized().dot(
				Vector2(tfwd.x, tfwd.z).normalized()) < -0.3,
			"t_last": snappedf(_t, 0.01), "off_after": false})
		open[j] = _contacts.size() - 1
		# marcheaza intalnirea deschisa ca avand contact
		var eo: Array = c.enc_open
		if int(eo[j]) >= 0:
			(_encounters[int(eo[j])] as Dictionary).contact = true
	last[j] = _t
	var ct: Dictionary = _contacts[int(open[j])]
	ct.frames = int(ct.frames) + 1
	ct.v_min = minf(float(ct.v_min), speed)
	ct.t_last = snappedf(_t, 0.01)
	var eo2: Array = c.enc_open
	if int(eo2[j]) >= 0:
		var e: Dictionary = _encounters[int(eo2[j])]
		e.contact = true
		e.contact_frames = int(e.contact_frames) + 1


func _track_open_contacts(i: int, speed: float) -> void:
	# viteza minima si "pe drum dupa 1.5 s" pentru contactele recente
	var c := _c[i]
	var open: Array = c.tc_open
	for j in 2:
		if int(open[j]) < 0:
			continue
		var ct: Dictionary = _contacts[int(open[j])]
		if _t - float(ct.t_last) < 1.5:
			ct.v_min = minf(float(ct.v_min), speed)


# --------------------------------------------------------------- excavator

func _contact_exc(i: int, car: Car, rc: Vector2, speed: float) -> void:
	var c := _c[i]
	var shape: CollisionShape3D = _exc._arm_shape
	var blocking := not shape.disabled
	var box := shape.shape as BoxShape3D
	var lp: Vector3 = shape.global_transform.affine_inverse() * car.global_position
	var q := Vector3(maxf(absf(lp.x) - box.size.x * 0.5, 0.0),
		maxf(absf(lp.y) - box.size.y * 0.5, 0.0),
		maxf(absf(lp.z) - box.size.z * 0.5, 0.0))
	var arm_d := q.length()
	if _t - float(c.ec_last) > CONTACT_GAP_S:
		_exc_events.append({"kind": "contact", "t": snappedf(_t, 0.01), "car": i,
			"name": c.name, "lat": snappedf(rc.y, 0.01), "v_in": snappedf(speed, 0.1),
			"v_min": speed, "blocking": blocking, "arm_d": snappedf(arm_d, 0.2),
			"frames": 0, "t_last": _t, "dist_along": snappedf(rc.x - _exc_dist, 0.1)})
		c.ec_open = _exc_events.size() - 1
	c.ec_last = _t
	var ev: Dictionary = _exc_events[int(c.ec_open)]
	ev.frames = int(ev.frames) + 1
	ev.v_min = minf(float(ev.v_min), speed)
	ev.t_last = _t
	# ajunge brat-ul (cat sta in banda lui) sau sasiul? pe parcurs
	if blocking:
		ev.blocking = true


func _tick_exc_pass(i: int, car: Car, rc: Vector2, speed: float) -> void:
	if _exc == null:
		return
	var c := _c[i]
	var delta_d: float = rc.x - _exc_dist
	if delta_d > _len * 0.5:
		delta_d -= _len
	elif delta_d < -_len * 0.5:
		delta_d += _len
	var prev: float = float(c.exc_prev_delta)
	c.exc_prev_delta = delta_d
	# fereastra de trecere: de la -60 m la +30 m fata de excavator; se
	# inregistreaza viteza minima si lateralul pe tot parcursul ei
	if delta_d > -60.0 and delta_d < 30.0:
		var w: Dictionary = c.get("exc_win", {})
		if w.is_empty():
			w = {"t_in": _t, "v_min": speed, "v_in": speed, "lat_in": rc.y,
				"lat_min_v": rc.y, "lat_at_pass": rc.y, "blocking_at_pass": false,
				"blocking_min_d": false, "lat_far": rc.y, "u_in": float(c.u),
				"passed": false, "d_at_vmin": delta_d}
		if speed < float(w.v_min):
			w.v_min = speed
			w.lat_min_v = rc.y
			w.d_at_vmin = delta_d
		if delta_d > -10.0 and delta_d < 0.0:
			w.lat_10 = rc.y
		if delta_d > -30.0 and delta_d < -29.0:
			w.lat_30 = rc.y
		if prev < 0.0 and delta_d >= 0.0:
			w.passed = true
			w.lat_at_pass = rc.y
			w.blocking_at_pass = not (_exc._arm_shape as CollisionShape3D).disabled
			w.t_pass = _t
			w.u_pass = float(c.u)
		if not (_exc._arm_shape as CollisionShape3D).disabled and delta_d > -25.0 and delta_d < 5.0:
			w.blocking_min_d = true
		c.exc_win = w
	else:
		var w2: Dictionary = c.get("exc_win", {})
		if not w2.is_empty():
			w2.t_out = _t
			w2.u_out = float(c.u)
			_exc_events.append({"kind": "pass", "car": i, "name": c.name, "win": w2})
			c.exc_win = {}


# --------------------------------------------------------------------- final

func _finish() -> void:
	_done = true
	if _diag:
		_report_diag()
		get_tree().quit(0)
		return
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		for j in _trucks.size():
			_close_encounter(i, j, cars[i], float(_c[i].u), "final")
	var res := {
		"label": _label, "config": _config, "seed": _seed, "seconds": _seconds,
		"scene": _scene, "len": _len, "bucket_m": BUCKET_M, "bucket_base": 40,
		"zones": _zones, "exc_dist": _exc_dist,
		"exc_lat": [_exc_lat_lo, _exc_lat_hi],
		"exc_block_frac": float(_exc_block_ticks) / maxf(float(_exc_ticks), 1.0),
		"apex": _apex, "cars": [], "encounters": _encounters, "contacts": _contacts,
		"exc_events": _exc_events, "blocaj": _blocaj, "respawns": _respawns,
		"truck_stats": _truck_stats, "hairpin": _hairpin, "truck_events": _truck_events, "ejects": _ejects,
	}
	for i in cars.size():
		var c := _c[i]
		var cc := {}
		for k in ["name", "car_name", "mass", "mass_factor", "line_offset", "slow_s",
				"rev_s", "off_s", "respawns", "walls", "cross", "laps_t"]:
			cc[k] = c[k]
		res.cars.append(cc)
	if not _out.is_empty():
		var f := FileAccess.open(_out, FileAccess.WRITE)
		f.store_string(JSON.stringify(res))
		f.close()
	_print_summary(res)
	get_tree().quit(0)


func _print_summary(res: Dictionary) -> void:
	var blocked := (res.blocaj as Array).size()
	var resp := (res.respawns as Array).size()
	var cont := (res.contacts as Array).size()
	var enc := (res.encounters as Array).size()
	var laps := 0
	var slow := 0.0
	for c in res.cars:
		laps += (c.laps_t as Array).size()
		slow += float(c.slow_s)
	# garda: masuratori nule = verdict fals (memoria garda-verde-pe-zero-masuratori)
	var samples := 0
	for c in res.cars:
		samples += (c.cross as Array).size()
	print("=== CARRARA SONDA config=%s seed=%d %.0fs: tururi %d, blocaje %d, repuneri %d, lent %.1fs total, contacte camion %d, intalniri %d, contacte exc %d" % [
		_config, _seed, _t, laps, blocked, resp, slow, cont, enc,
		(res.exc_events as Array).size()])
	if samples == 0:
		push_error("probe_carrara: ZERO masuratori (nicio masina n-a trecut un singur bucket) — garda armata")
		print("VERDICT: PROBLEMA (zero masuratori)")
		return
	if _config != "base" and (_trucks.is_empty() and _exc == null):
		print("VERDICT: PROBLEMA (zero hazarde)")
		return
	print("VERDICT: OK (rulare completa)")


func _report_diag() -> void:
	print("=== DIAG camioane (pozitia corpului fata de axa, in coordonatele soselei, + = dreapta cursei)")
	for zone: String in _truck_stats:
		var s: Dictionary = _truck_stats[zone]
		print("  zona %-4s n=%5d lat medie %6.2f  [min %6.2f .. max %6.2f]  hw local %.2f  margine interioara max %6.2f (<0 = ramane pe stanga axei)  marginea exterioara iese peste asfalt cu max %6.2f m" % [
			zone, int(s.n), float(s.sum) / maxf(float(s.n), 1.0), float(s.lo), float(s.hi),
			float(s.hw), float(s.inner), float(s.outer_over)])
	if _trucks.is_empty():
		print("  (fara camioane)")
	print("  ticks in afara drumului (intrare/iesire de serviciu): %d" % _truck_offroad_ticks)
	print("  evenimente camion: %s" % str(_truck_events))
	if _exc != null:
		print("=== DIAG excavator: coliziunea bratului activa %.1f%% din timp (%d cicluri)" % [
			100.0 * float(_exc_block_ticks) / maxf(float(_exc_ticks), 1.0), _arm_cycles.size()])
	if not _out.is_empty():
		var f := FileAccess.open(_out, FileAccess.WRITE)
		f.store_string(JSON.stringify({"truck_stats": _truck_stats, "rows": _truck_rows,
			"arm_cycles": _arm_cycles, "exc_block_frac":
			float(_exc_block_ticks) / maxf(float(_exc_ticks), 1.0)}))
		f.close()
