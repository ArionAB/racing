extends Node
## Sonda 1d San Francisco: PODUL ROSU CAROSABIL, dus-intors cu despartitor mobil
## (brief docs/track_briefs/san_francisco.md §7 pasul 1d), pe strada SINTETICA
## tools/SondaSfPod*.tscn (generata de tools/gen_sf_pod.py). NU e Track25.
##
## Ruleaza CA SCENA, headless:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfPod.tscn -- \
##       --mode=race --config=mobil --seed=3 --seconds=200 --out=C:/tmp/s3.json
##   godot ... -- --mode=solo --car=3 --pilot=hug --phase=0.25 --config=mobil
##
## `--config=`  mobil  (bariera mobila, AI-ul citeste culoarul curent)
##              fix    (bariera FIXA la axa, fara camion — despartitorul clasic)
##              orb    SABOTAJ: mobila, AI-ul nu citeste bariera deloc
##              static SABOTAJ: mobila, AI-ul citeste bariera de la t=0
##   Se aplica pe nodul `MovableMedianHazard` INAINTE de primul tick.
## `--phase=`   faza camionului (fractie din ciclu), implicit cea din scena.
##
## RACE: 8 masini (jucatorul primeste creier AI, ca in ProbeCarrara), cifre per
## TRECERE PESTE POD (o masina pe tablier, de la un capat la celalalt):
##   contacte cu bariera / cu camionul, treceri peste despartitor (centrul masinii
##   pe partea gresita a barierei de ACUM), [blocaj] (sub 6 m/s 3 s, ca ProbeRace),
##   repuneri, ejectari (sofer), ciocniri frontale intre masini (sensuri opuse),
##   depasiri pe tablier si cate din ele in banda ingusta (< 10 m liberi),
##   intalnirile cu camionul (masina la < 30 m de el pe latura lui) si cate cad
##   sub 10 m/s (coada). Iesirea JSON o citeste tools/sf_pod_report.py.
##
## SOLO: o singura masina, pilot scriptat cu gazul la fund, urmeaza soseaua cu o
## tinta laterala pe tablier:
##   `--pilot=hug`   lipit de bariera (centrul la fata barierei + 0,6 m: freaca
##                   peretele si intra in fiecare S si in coltul camionului);
##   `--pilot=line`  linie dreapta fixa la `--line-z=` (z local, pe latura
##                   proprie: 2,5 implicit), pe care bariera o taie cand e pe
##                   partea noastra — lovitura in unghiul S-ului, la viteza de cursa;
##   `--pilot=axis`  pe axa benzii (martorul de timp).
## Un tur: trecerea pe DUS si pe INTORS. Linia `=== SF POD SOLO` are tot.
##
## [b]Limita asumata[/b] (memoria `harnas-sintetic-comportament-emergent`): bucla
## e sintetica; cifrele de pluton valideaza MECANISMUL, verdictul de flota se da
## pe Track25.
const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const CONTACT_GAP_S: float = 0.5
const NARROW_M: float = 10.0
const TRUCK_NEAR_M: float = 30.0

class Pilot extends CarController:
	var probe: Node = null
	var throttle: float = 1.0
	func get_steer() -> float:
		return probe.call("pilot_steer", car)
	func get_throttle() -> float:
		return throttle

var _scene: String = "res://tools/SondaSfPod.tscn"
var _mode: String = "race"
var _config: String = "mobil"
var _seed: int = 20261113
var _seconds: float = 200.0
var _player_car: int = 0
var _ai_cars: Array[int] = [3, 1, 4, 5, 8, 7, 2]
var _out: String = ""
var _phase: float = -1.0
var _pilot_kind: String = "hug"
var _line_z: float = 2.5
var _label: String = ""
## `--trace-car=Buggy --trace-window=20,27`: pozitia unei masini la 10 Hz.
var _trace_car: String = ""
var _trace_win: Vector2 = Vector2(0.0, 1e9)

var _race: Node = null
var _track: Track = null
var _med: MovableMedianHazard = null
var _len: float = 1.0
var _t: float = 0.0
var _done: bool = false
var _c: Array[Dictionary] = []
var _passes: Array[Dictionary] = []
var _blocaj: Array[Dictionary] = []
var _respawns: Array[Dictionary] = []
var _ejects: Array[Dictionary] = []
var _crossings: Array[Dictionary] = []
var _headon: Array[Dictionary] = []
var _overtakes: Array[Dictionary] = []
var _pair_order: Dictionary = {}
var _headon_last: Dictionary = {}
var _tick_us: Array[int] = []
var _moved: Array[int] = []
var _pilot: Pilot = null


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
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
		elif arg.begins_with("--phase="):
			_phase = float(arg.trim_prefix("--phase="))
		elif arg.begins_with("--pilot="):
			_pilot_kind = arg.trim_prefix("--pilot=")
		elif arg.begins_with("--line-z="):
			_line_z = float(arg.trim_prefix("--line-z="))
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--trace-car="):
			_trace_car = arg.trim_prefix("--trace-car=")
		elif arg.begins_with("--trace-window="):
			var tw := arg.trim_prefix("--trace-window=").split(",")
			_trace_win = Vector2(float(tw[0]), float(tw[1]))
		elif arg.begins_with("--median-read="):
			AIController.median_read_s = float(arg.trim_prefix("--median-read="))
		elif arg.begins_with("--median-margin="):
			AIController.median_margin_m = float(arg.trim_prefix("--median-margin="))
	_start()


func _start() -> void:
	GameState.selected_track = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.traffic_override = -1
	var solo := _mode == "solo"
	var none: Array[int] = []
	GameState.ai_cars_override = none if solo else _ai_cars
	GameState.ai_count = 0 if solo else _ai_cars.size()
	GameState.selected_car = clampi(_player_car, 0, GameState.CAR_DATA.size() - 1)
	GameState.track_scene_override = _scene
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	# configuratia hazardului INAINTE de _ready-ul lui (constructia blocurilor)
	var track_node: Node = null
	add_child(_race)
	_track = _race.track
	track_node = _track
	for n in track_node.find_children("*", "MovableMedianHazard", true, false):
		_med = n as MovableMedianHazard
	if _med == null:
		push_error("probe_sf_pod: scena n-are MovableMedianHazard")
		get_tree().quit(2)
		return
	_apply_config()
	_len = _track.routes[0].length()
	var cars: Array[Car] = _race.cars
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	if solo:
		_pilot = Pilot.new()
		_pilot.probe = self
		player.set_controller(_pilot)
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed
		(_race._rng as RandomNumberGenerator).seed = _seed
		for car in cars:
			if car == player:
				var ai := AIController.new()
				car.set_controller(ai)
				var visible: Array[Car] = cars.duplicate()
				ai.configure(_track, rng, visible)
			else:
				(car.controller as AIController).line_offset = rng.randf_range(-0.35, 0.35)
			car.speed_scale = 1.0 if car == player else rng.randf_range(0.88, 0.97)
	for i in cars.size():
		var car := cars[i]
		_c.append({"name": "%s (%s)" % [car.pilot_name, car.car_name], "car_name": car.car_name,
			"stuck_t": 0.0, "stuck_reports": 0, "pass": -1, "prev": {}, "u": 0.0,
			"u_init": false, "last_d": 0.0, "off": 0.0, "laps_t": [], "lap_n": 0,
			"block_last": -99.0, "truck_last": -99.0, "wrong": false, "last_contact_t": -99.0,
			"respawns": 0, "slow_s": 0.0})
		var idx := i
		car.respawned.connect(func(_cc: Car) -> void: _on_respawn(idx))
		car.ejected.connect(func(cc: Car, _rd: Node3D) -> void: _on_eject(idx, cc))
	print("probe_sf_pod: %s mode=%s config=%s seed=%d lungime %.1f m, faza %.3f, ciclu camion %.1f s, pilot=%s" % [
		_scene.get_file(), _mode, _config, _seed, _len, _med.phase, _med.cycle_s(), _pilot_kind])


func _apply_config() -> void:
	# Nodul e deja construit (blocurile stau unde le-a pus faza din scena). Ce se
	# poate schimba fara reconstructie: citirea AI-ului si faza. „fix" cere o
	# scena separata (SondaSfPodFix.tscn), fiindca blocurile si camionul se
	# construiesc la _ready.
	match _config:
		"mobil":
			_med.ai_reads_corridor = true
			_med.ai_static_read = false
		"orb":
			_med.ai_reads_corridor = false
			_med.remove_from_group(MovableMedianHazard.AI_GROUP)
		"static":
			_med.ai_reads_corridor = true
			_med.ai_static_read = true
		"fix":
			if not _med.static_center:
				push_error("probe_sf_pod: --config=fix cere --scene=res://tools/SondaSfPodFix.tscn")
				get_tree().quit(2)
	if _config != "orb" and not _med.is_in_group(MovableMedianHazard.AI_GROUP):
		_med.add_to_group(MovableMedianHazard.AI_GROUP)
	if _phase >= 0.0:
		_med.phase = _phase
		# blocurile si fotografia de la t=0 a sabotajului „static", pe faza noua
		_med.set("_static_s_t", _med.call("_truck_s_at", _med.call("_cycle_time", 0.0)))
		_med.truck_s = _med.get("_static_s_t")
		for k in _med.call("_block_count"):
			_med.call("_place_block", k, (float(k) + 0.5) * _med.block_len, _med.truck_s, true)
		_med.call("_place_truck")


# ----------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if _done or _race == null or _med == null:
		return
	if _race.state != Race.State.RUNNING:
		return
	_t += delta
	_tick_us.append(_med.last_tick_usec)
	_moved.append(_med.last_moved)
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		_tick_car(i, cars[i], delta)
	if _mode == "race":
		_tick_pairs(cars)
	if _t >= _seconds or (_mode == "solo" and _solo_done()):
		_finish()


func _local(car: Car) -> Vector3:
	return _med.global_transform.affine_inverse() * car.global_position


## Latura PROPRIE a masinii pe tablier: dupa sensul soselei la indexul ei
## (+1 = latura +Z, unde merge sensul +X), nu dupa unde e acum.
func _own_side(car: Car) -> float:
	var r := _track.route_at(car.route)
	var i := car.road_index
	var d := r.baked[r.wrap_index(i + 1)] - r.baked[r.wrap_index(i)]
	var dl := _med.global_transform.basis.inverse() * d
	return float(_med.plus_dir_side) * (1.0 if dl.x >= 0.0 else -1.0)


func _on_deck(local: Vector3) -> bool:
	return local.x >= 0.0 and local.x <= _med.deck_length and absf(local.z) < _med.deck_half_width + 1.0 \
		and local.y > -3.0


func _tick_car(i: int, car: Car, delta: float) -> void:
	var c := _c[i]
	var speed := car.horizontal_speed()
	var local := _local(car)
	var rc := _track.road_coords(car.road_index, car.global_position)
	# distanta desfasurata (ture)
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
	c.u = float(c.off) + d
	var lap_n := int(floor(float(c.u) / _len))
	if lap_n > int(c.lap_n) and lap_n >= 1:
		(c.laps_t as Array).append(snappedf(_t, 0.001))
	c.lap_n = maxi(int(c.lap_n), lap_n)
	if speed < 4.0:
		c.slow_s = float(c.slow_s) + delta
	var on_deck := _on_deck(local)
	var side := _own_side(car)
	if not _trace_car.is_empty() and String(c.name).contains(_trace_car) 			and _t >= _trace_win.x and _t <= _trace_win.y and Engine.get_physics_frames() % 6 == 0:
		var fw := _med.global_transform.basis.inverse() * (-car.global_transform.basis.z)
		print("[trace] t=%.2f %s s=%.1f z=%.2f y=%.2f v=%.1f cap=%.0f steer=%.2f gaz=%.2f drift=%s idx=%d lat=%.2f roti=%d" % [
			_t, c.name, local.x, local.z, local.y, speed, rad_to_deg(atan2(fw.z, fw.x)),
			car.controller.get_steer(), car.controller.get_throttle(), str(car.is_drifting),
			car.road_index, rc.y, car.wheels_on_ground])
	# --- trecerea peste pod ---
	if on_deck and int(c.pass) < 0:
		_passes.append({"car": i, "name": c.name, "car_name": c.car_name, "side": side,
			"t_in": _t, "s_in": local.x, "t_out": -1.0, "v_in": speed, "v_min": speed,
			"block_contacts": 0, "block_frames": 0, "truck_contacts": 0, "truck_frames": 0,
			"cross": 0, "respawn": false, "eject": false, "w_min": 99.0, "w_sum": 0.0, "n": 0,
			"truck_near": false, "truck_slow": false, "truck_s_in": _med.truck_s,
			"lat_min_face": 99.0, "complete": false})
		c.pass = _passes.size() - 1
	if int(c.pass) >= 0:
		var p: Dictionary = _passes[int(c.pass)]
		if on_deck:
			p.v_min = minf(float(p.v_min), speed)
			var w := _med.lane_width_at(local.x, side)
			p.w_min = minf(float(p.w_min), w)
			if w < NARROW_M:
				p.narrow_n = int(p.get("narrow_n", 0)) + 1
			p.w_sum = float(p.w_sum) + w
			p.n = int(p.n) + 1
			# distanta de la marginea masinii la fata barierei (negativ = suprapunere)
			var face := _med.obstacle_face(local.x, side)
			p.lat_min_face = minf(float(p.lat_min_face), side * local.z - face)
			# trecere peste despartitor: centrul pe partea gresita a barierei de ACUM
			var wrong := side * (local.z - _med.offset_at(local.x)) < 0.0
			if wrong and not bool(c.wrong):
				p.cross = int(p.cross) + 1
				var rec := {"t": snappedf(_t, 0.01), "car": i, "name": c.name, "s": snappedf(local.x, 0.1),
					"z": snappedf(local.z, 0.01), "offset": snappedf(_med.offset_at(local.x), 0.01),
					"v": snappedf(speed, 0.1), "y": snappedf(local.y, 0.01)}
				_crossings.append(rec)
				print("[trecere] t=%.1f %s s=%.1f z=%.2f bariera la %.2f v=%.1f y=%.2f" % [
					_t, c.name, local.x, local.z, float(rec.offset), speed, local.y])
			c.wrong = wrong
			# camionul: pe latura noastra, la < 30 m in fata sau alaturi
			var tb := _med.truck_body()
			if tb != null:
				var dt := (local.x - _med.truck_s) * (1.0 if side * float(_med.plus_dir_side) > 0.0 else -1.0)
				if dt > -TRUCK_NEAR_M and dt < 6.0:
					p.truck_near = true
					if speed < 10.0:
						p.truck_slow = true
		var leaving: bool = not on_deck and (local.x < -1.0 or local.x > _med.deck_length + 1.0 \
			or absf(local.z) > _med.deck_half_width + 1.0 or local.y < -3.0)
		if leaving:
			p.t_out = _t
			p.v_out = speed
			p.complete = (side > 0.0 and local.x > _med.deck_length) or (side < 0.0 and local.x < 0.0)
			c.pass = -1
			c.wrong = false
	# --- contacte ---
	var hit_block := false
	var hit_truck := false
	for b in car.get_colliding_bodies():
		if _med.is_block(b):
			hit_block = true
		elif b == _med.truck_body():
			hit_truck = true
	if hit_block or hit_truck:
		c.last_contact_t = _t
		if _mode == "solo" and _t > float(c.get("escape_until", -1.0)) + 0.5:
			c.escape_until = _t + 1.5
			c.line_hit_pass = int(c.pass)
	if int(c.pass) >= 0:
		var p2: Dictionary = _passes[int(c.pass)]
		if hit_block:
			p2.block_frames = int(p2.block_frames) + 1
			if _t - float(c.block_last) > CONTACT_GAP_S:
				p2.block_contacts = int(p2.block_contacts) + 1
				if not p2.has("block_v"):
					p2.block_v = speed
					p2.block_s = local.x
			c.block_last = _t
		if hit_truck:
			p2.truck_frames = int(p2.truck_frames) + 1
			if _t - float(c.truck_last) > CONTACT_GAP_S:
				p2.truck_contacts = int(p2.truck_contacts) + 1
				if not p2.has("truck_v"):
					p2.truck_v = speed
			c.truck_last = _t
	# --- blocaj (ca ProbeRace._watch_stuck) ---
	if speed > 6.0:
		c.stuck_t = 0.0
	else:
		c.stuck_t = float(c.stuck_t) + delta
		if float(c.stuck_t) >= 3.0 and int(c.stuck_reports) < 6:
			c.stuck_t = 0.0
			c.stuck_reports = int(c.stuck_reports) + 1
			var touching: Array[String] = []
			for body in car.get_colliding_bodies():
				if _med.is_block(body):
					touching.append("BARIERA")
				elif body == _med.truck_body():
					touching.append("CAMION")
				elif body is Node:
					touching.append(String((body as Node).name))
			var rec := {"t": snappedf(_t, 0.1), "car": i, "name": c.name, "s": snappedf(local.x, 0.1),
				"z": snappedf(local.z, 0.1), "on_deck": on_deck, "v": snappedf(speed, 0.1),
				"touching": touching, "since_contact": snappedf(_t - float(c.last_contact_t), 0.1),
				"truck_d": snappedf(absf(local.x - _med.truck_s), 0.1)}
			_blocaj.append(rec)
			print("[blocaj] t=%5.1fs %-22s s=%.1f z=%.1f pod=%s v=%.1f camion@%.0fm contact_acum %.1fs atinge %s" % [
				_t, c.name, local.x, local.z, str(on_deck), speed, float(rec.truck_d),
				_t - float(c.last_contact_t), ", ".join(touching) if not touching.is_empty() else "-"])
	c.prev = {"s": local.x, "z": local.z, "y": local.y, "v": speed, "on_deck": on_deck}


## Ciocniri frontale intre masini de sensuri opuse si depasiri pe tablier.
func _tick_pairs(cars: Array[Car]) -> void:
	for i in cars.size():
		var a := cars[i]
		for b in a.get_colliding_bodies():
			var cb := b as Car
			if cb == null:
				continue
			var j := cars.find(cb)
			if j <= i:
				continue
			var fa := -a.global_transform.basis.z
			var fb := -cb.global_transform.basis.z
			if Vector2(fa.x, fa.z).normalized().dot(Vector2(fb.x, fb.z).normalized()) < -0.3:
				var key := i * 100 + j
				if _t - float(_headon_last.get(key, -99.0)) > 1.0:
					var la := _local(a)
					# pe coridorul cu doua sensuri (gat de balon la gat de balon)?
					var lane_z := float(_track.get_meta("sf_pod", {}).get("lane_z", 6.2))
					var x_f := float(_track.get_meta("sf_pod", {}).get("x_f", 624.0))
					var x0 := _med.global_position.x
					var corr := la.x > -x0 and la.x < x_f - x0 and absf(la.z) < 2.0 * lane_z + 1.0
					_headon.append({"t": snappedf(_t, 0.01), "a": _c[i].name, "b": _c[j].name,
						"s": snappedf(la.x, 0.1), "z": snappedf(la.z, 0.1), "corridor": corr})
					print("[frontal] t=%.1f %s x %s s=%.1f z=%.1f" % [_t, _c[i].name, _c[j].name, la.x, la.z])
				_headon_last[key] = _t
	# depasiri: doua masini pe tablier, pe aceeasi latura, ordinea pe s se inverseaza
	for i in cars.size():
		var li := _local(cars[i])
		if not _on_deck(li):
			continue
		var si := _own_side(cars[i])
		for j in range(i + 1, cars.size()):
			var lj := _local(cars[j])
			var key := i * 100 + j
			if not _on_deck(lj) or _own_side(cars[j]) != si or absf(li.x - lj.x) > 15.0:
				_pair_order.erase(key)
				continue
			var dir := si * float(_med.plus_dir_side)
			var order := signf((li.x - lj.x) * dir)
			var prev: float = _pair_order.get(key, 0.0)
			if prev != 0.0 and order != 0.0 and order != prev:
				var w := _med.lane_width_at((li.x + lj.x) * 0.5, si)
				_overtakes.append({"t": snappedf(_t, 0.01), "s": snappedf((li.x + lj.x) * 0.5, 0.1),
					"w": snappedf(w, 0.1), "narrow": w < NARROW_M})
			if order != 0.0:
				_pair_order[key] = order


func _on_eject(i: int, car: Car) -> void:
	if _race.state != Race.State.RUNNING:
		return
	var p: Dictionary = _c[i].prev
	_ejects.append({"t": snappedf(_t, 0.1), "car": i, "name": _c[i].name,
		"cause": car.last_eject_cause, "value": snappedf(car.last_eject_value, 0.1),
		"s": snappedf(float(p.get("s", 0.0)), 0.1), "z": snappedf(float(p.get("z", 0.0)), 0.1),
		"on_deck": p.get("on_deck", false),
		"since_contact": snappedf(_t - float(_c[i].last_contact_t), 0.1)})
	if int(_c[i].pass) >= 0:
		(_passes[int(_c[i].pass)] as Dictionary).eject = true
	print("[ejectare] t=%.1f %s %s dv=%.1f s=%.1f z=%.1f pod=%s contact_acum %.1fs" % [
		_t, _c[i].name, car.last_eject_cause, car.last_eject_value, float(p.get("s", 0.0)),
		float(p.get("z", 0.0)), str(p.get("on_deck", false)), _t - float(_c[i].last_contact_t)])


func _on_respawn(i: int) -> void:
	if _race.state != Race.State.RUNNING:
		return
	var c := _c[i]
	c.respawns = int(c.respawns) + 1
	var p: Dictionary = c.prev
	var rec := {"t": snappedf(_t, 0.1), "car": i, "name": c.name, "s": snappedf(float(p.get("s", 0.0)), 0.1),
		"z": snappedf(float(p.get("z", 0.0)), 0.1), "y": snappedf(float(p.get("y", 0.0)), 0.1),
		"v": snappedf(float(p.get("v", 0.0)), 0.1), "on_deck": p.get("on_deck", false),
		"since_contact": snappedf(_t - float(c.last_contact_t), 0.1)}
	_respawns.append(rec)
	if int(c.pass) >= 0:
		(_passes[int(c.pass)] as Dictionary).respawn = true
		(_passes[int(c.pass)] as Dictionary).t_out = _t
		c.pass = -1
	print("[repunere] t=%.1f %s s=%.1f z=%.1f y=%.1f v=%.1f pod=%s contact_acum %.1fs" % [
		_t, c.name, float(rec.s), float(rec.z), float(rec.y), float(rec.v), str(rec.on_deck),
		float(rec.since_contact)])


# ----------------------------------------------------------------- pilot

func pilot_steer(car: Car) -> float:
	var local := _local(car)
	var side := _own_side(car)
	var r := _track.route_at(car.route)
	var i := car.road_index
	var speed := maxf(car.horizontal_speed(), 3.0)
	# tinta laterala (m de la axa benzii, + dreapta) — pe tablier, din z local
	var target_lat := 0.0
	var lane_z := float(_track.get_meta("sf_pod", {}).get("lane_z", 6.2))
	var on_span := local.x > 0.0 and local.x < _med.deck_length and absf(local.z) < 16.0
	# Dupa un contact pilotul iese pe axa benzii, ca un om (nu un zid care tot
	# apasa in bariera): `hug` 1,5 s, apoi se lipeste iar; `line` pana la capatul
	# trecerii (o singura lovitura „oarba" pe trecere).
	var c0: Dictionary = _c[0]
	var escaping := _t < float(c0.get("escape_until", -1.0)) 		or (_pilot_kind == "line" and int(c0.get("line_hit_pass", -2)) == int(c0.pass) and int(c0.pass) >= 0)
	if on_span and _pilot_kind != "axis" and not escaping:
		var want_z := 0.0
		if _pilot_kind == "hug":
			# caroseria freaca fata barierei (10 cm de suprapunere)
			var half_w: float = car.data.body_width * 0.5 if car.data != null else 1.1
			want_z = side * (_med.obstacle_face(local.x, side) + half_w - 0.1)
		else:
			want_z = side * _line_z
		# z local -> lateral fata de axa benzii: pe latura + (spre +X) dreapta e +Z,
		# pe latura - (spre -X) dreapta e -Z
		target_lat = side * (want_z - side * lane_z)
	var far := _track.lookahead_point(i, clampf(speed * 0.55, 8.0, 24.0), 0.0, car.route)
	var sv := r.side_at(r.wrap_index(i))
	var fwd := -car.global_transform.basis.z
	fwd.y = 0.0
	var to := far + sv * target_lat - car.global_position
	to.y = 0.0
	var ang := fwd.normalized().signed_angle_to(to.normalized(), Vector3.UP)
	return clampf(ang * 2.4, -1.0, 1.0)


func _solo_done() -> bool:
	# un tur intreg (ambele treceri peste pod)
	return _c.size() > 0 and float(_c[0].u) >= _len + 5.0


# ----------------------------------------------------------------- final

func _finish() -> void:
	_done = true
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		if int(_c[i].pass) >= 0:
			(_passes[int(_c[i].pass)] as Dictionary).t_out = -1.0
	var tick_sorted := _tick_us.duplicate()
	tick_sorted.sort()
	var res := {"label": _label, "mode": _mode, "config": _config, "seed": _seed,
		"seconds": _t, "scene": _scene, "len": _len, "phase": _med.phase, "cycle": _med.cycle_s(),
		"passes": _passes, "blocaj": _blocaj, "respawns": _respawns, "ejects": _ejects,
		"crossings": _crossings, "headon": _headon, "overtakes": _overtakes,
		"tick_us_med": tick_sorted[tick_sorted.size() / 2] if not tick_sorted.is_empty() else 0,
		"tick_us_p99": tick_sorted[int(tick_sorted.size() * 0.99)] if not tick_sorted.is_empty() else 0,
		"moved_max": _moved.max() if not _moved.is_empty() else 0,
		"cars": []}
	for i in cars.size():
		res.cars.append({"name": _c[i].name, "car_name": _c[i].car_name, "laps_t": _c[i].laps_t,
			"respawns": _c[i].respawns, "slow_s": _c[i].slow_s})
	if not _out.is_empty():
		var f := FileAccess.open(_out, FileAccess.WRITE)
		f.store_string(JSON.stringify(res))
		f.close()
	if _mode == "solo":
		_print_solo(res)
	else:
		_print_race(res)
	get_tree().quit(0)


func _print_solo(res: Dictionary) -> void:
	var parts: Array[String] = []
	for p: Dictionary in res.passes:
		parts.append("%s: %.2f s, v_in %.1f v_min %.1f, bariera %d (%d cadre, v %.1f), camion %d (%d cadre), treceri %d, ejectat %s, repus %s, culoar min %.1f m, fata min %.2f, %s" % [
			"DUS" if float(p.side) > 0.0 else "INTORS",
			float(p.t_out) - float(p.t_in) if float(p.t_out) > 0.0 else -1.0,
			float(p.v_in), float(p.v_min), int(p.block_contacts), int(p.block_frames),
			float(p.get("block_v", -1.0)), int(p.truck_contacts), int(p.truck_frames), int(p.cross),
			str(p.eject), str(p.respawn), float(p.w_min), float(p.lat_min_face),
			"complet" if bool(p.complete) else "INCOMPLET"])
	print("=== SF POD SOLO car=%d (%s) pilot=%s config=%s faza %.3f: tur %.2f s, ejectari %d, repuneri %d, treceri %d | %s" % [
		_player_car, (_race.player as Car).car_name, _pilot_kind, _config, _med.phase, _t,
		(res.ejects as Array).size(), (res.respawns as Array).size(), (res.crossings as Array).size(),
		" | ".join(parts)])


func _print_race(res: Dictionary) -> void:
	var n := (res.passes as Array).size()
	var bc := 0
	var tc := 0
	for p: Dictionary in res.passes:
		bc += int(p.block_contacts)
		tc += int(p.truck_contacts)
	var laps := 0
	for c in res.cars:
		laps += (c.laps_t as Array).size()
	print("=== SF POD RACE config=%s seed=%d %.0fs: tururi %d, treceri pe pod %d, contacte bariera %d, camion %d, treceri peste despartitor %d, frontale %d, blocaje %d, repuneri %d, ejectari %d, tick median %d us (p99 %d), blocuri mutate max %d" % [
		_config, _seed, _t, laps, n, bc, tc, (res.crossings as Array).size(), (res.headon as Array).size(),
		(res.blocaj as Array).size(), (res.respawns as Array).size(), (res.ejects as Array).size(),
		int(res.tick_us_med), int(res.tick_us_p99), int(res.moved_max)])
	if laps == 0:
		print("VERDICT: PROBLEMA (zero tururi)")
	else:
		print("VERDICT: OK (rulare completa)")
