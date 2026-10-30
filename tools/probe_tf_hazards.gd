extends Node
## Garda hazardelor animale de pe Transfagarasan (Track21), #603 si #604.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTfHazards.tscn
##   ... -- --control      (hazardul mutat sub pista: cat pierde drumul singur)
##
## Masoara, pe pista REALA (cursa, nu o scena de laborator), ce simte un jucator
## care loveste hazardul, ca DIFERENTA fata de aceeasi lansare fara hazard
## (`--control`):
##
##   OILE (HerdHazard, #604): masina intra in turma densa, la 12 si la 25 m/s.
##     Masurat: timp pe 70 m, viteza minima, deviatia laterala, loviturile si oile
##     cazute. Verdictul cere ca turma sa atinga masina si sa NU o opreasca (nu zid).
##     Cat timp pierzi fata de control se citeste din cele doua rulari.
##   URSUL (SlidingHazard cu `brown_bear.glb`, #603): trebuie sa existe cel putin
##     doi, unul DUPA saritura peste parau (~0.667); la mijlocul traversarii,
##     masina care il loveste nu e aruncata in aer.
##
## Faza hazardului se FORTEAZA (`_time`) la sosirea masinii: altfel verdictul ar
## depinde de ceasul cursei (memoria `ceasul-porneste-in-prima-faza`).

const RACE_SCENE := "res://scenes/race/Race.tscn"
const RUN_UP := 30.0
const MEASURE_LEN := 40.0
## Oile nu sunt zid: masina nu scade sub aceasta fractie din viteza de intrare.
const SHEEP_MIN_SPEED_FRAC := 0.35
## Un efect SIMTIT: timpul pe tronson, in turma densa, fata de control (s).
const SHEEP_MIN_LOSS_S := 0.35
const BEAR_MAX_AIR_VY := 3.0
## Cate secunde de control pentru fiecare viteza (cifre scrise dupa o rulare --control).
const CONTROL_S := {"12": 1.75, "25": 1.42}


class Scripted extends CarController:
	func get_throttle() -> float:
		return 1.0


var _race: Race
var _go := false
var _fails: PackedStringArray = []
var _control := false
var _jobs: Array = []
var _job: Dictionary = {}
var _log: Array = []
var _impacts := 0


func _ready() -> void:
	GameState.selected_track = 2
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.ai_count = 0
	_control = OS.get_cmdline_user_args().has("--control")
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(_race)


func _physics_process(delta: float) -> void:
	if _race.state != Race.State.RUNNING:
		return
	if not _go:
		_go = true
		_race.player.impact.connect(func(_c: Car, _k: StringName, _st: float, _n: Vector3,
				_pt: Vector3, _o: Node) -> void: _impacts += 1)
		_setup_jobs()
	if _job.is_empty():
		if _jobs.is_empty():
			_finish()
			return
		_start_job(_jobs.pop_front())
		return
	_step_job(delta)


func _herd() -> HerdHazard:
	for n in _race.track.find_children("*", "HerdHazard", true, false):
		return n as HerdHazard
	return null


func _bears() -> Array[SlidingHazard]:
	var out: Array[SlidingHazard] = []
	for n in _race.track.find_children("*", "SlidingHazard", true, false):
		var s := n as SlidingHazard
		if s.model_scene != null and s.model_scene.resource_path.ends_with("brown_bear.glb"):
			out.append(s)
	return out


func _setup_jobs() -> void:
	var r: TrackRoute = _race.track.route_at(0)
	var herd := _herd()
	if herd == null:
		_fails.append("nu exista HerdHazard pe pista")
	else:
		var i := r.closest_index_global(herd.global_position)
		print("[tf] turma: %d animale, masa %.0f, kick %.1f, pierdere %.2f, reach %.0f; la %.1f m lateral de axa, cota turma %.2f drum %.2f" % [
			herd.count(), herd.animal_mass, herd.kick_speed, herd.forward_loss,
			herd.body_reach, r.lateral_distance(i, herd.global_position),
			herd.global_position.y, r.baked[i].y])
		for v in [12.0, 25.0]:
			_jobs.append({"kind": "sheep", "speed": v})
	var bears := _bears()
	print("[tf] ursi pe pista: %d" % bears.size())
	var n := float(r.baked.size())
	var after := 0
	for b in bears:
		var f := float(r.closest_index_global(b.center)) / n
		print("[tf]   %s la fractia %.3f, cursa %.1f m, viteza max %.2f m/s" % [
			b.name, f, b.travel.length() * 2.0, b.max_sweep_speed])
		if f > 0.68 and f < 0.78:
			after += 1
			_jobs.append({"kind": "bear", "node": b, "speed": 18.0})
	if bears.size() < 2:
		_fails.append("sub 2 ursi pe pista (e nevoie de unul dupa saritura peste parau)")
	if after < 1:
		_fails.append("niciun urs intre 0.68 si 0.78 (dupa saritura peste parau, ~0.667)")


func _place(dir: Vector3, at: Vector3, speed: float) -> void:
	var p := _race.player
	if not (p.controller is Scripted):
		var old := p.controller
		var c := Scripted.new()
		p.set_controller(c)
		if old != null and old != c:
			old.queue_free()
	var from := at - dir * RUN_UP
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 8.0, from + Vector3.DOWN * 12.0)
	q.exclude = [p.get_rid()]
	var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
	from.y = ((hit.position as Vector3).y if not hit.is_empty() else at.y) + 1.0
	p.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), from)
	p.velocity = dir * speed
	p.angular_velocity = Vector3.ZERO


func _start_job(job: Dictionary) -> void:
	_job = job
	_job["t"] = 0.0
	_job["min_v"] = INF
	_job["max_vy"] = 0.0
	_job["max_lat"] = 0.0
	_impacts = 0
	var r: TrackRoute = _race.track.route_at(0)
	var t_arr := RUN_UP / float(job["speed"])
	if String(job["kind"]) == "sheep":
		var h := _herd()
		# directia REALA a drumului in dreptul turmei, nu `road_dir` declarat
		var ri := r.closest_index_global(h.global_position)
		var rt := r.baked[r.wrap_index(ri + 1)] - r.baked[r.wrap_index(ri - 1)]
		rt.y = 0.0
		_job["dir"] = rt.normalized()
		_job["origin"] = r.baked[ri]
		print("[tf] drum la turma: %s, road_dir declarat %s, unghi %.1f grade" % [
			rt.normalized(), h.road_dir, rad_to_deg(rt.normalized().angle_to(h.road_dir))])
		_job["hz_pos"] = h.global_position
		_job["hits0"] = h.hits
		var best := 0.0
		var found := false
		for k in 400:
			var tt := float(k) * 0.1
			var busy := true
			for s in h.strips:
				if h.strip_free_at(s, tt + t_arr):
					busy = false
			if busy:
				best = tt
				found = true
				break
		if not found:
			_fails.append("nu gasesc o faza cu turma densa pe toate benzile")
		h._time = best
		if _control:
			h.global_position += Vector3.DOWN * 500.0
	else:
		var b: SlidingHazard = job["node"]
		var i := r.closest_index_global(b.center)
		var tan := r.baked[r.wrap_index(i + 1)] - r.baked[r.wrap_index(i - 1)]
		tan.y = 0.0
		_job["dir"] = tan.normalized()
		_job["origin"] = b.center
		# `_offset_at(_time + t_arr)` ~ 0: ursul sta pe axa la sosire
		var best_t := -1.0
		for k in 2000:
			var tt := float(k) * 0.05
			if absf(b._offset_at(tt + t_arr)) < 0.03 and not b._in_telegraph(tt + t_arr):
				best_t = tt
				break
		if best_t < 0.0:
			_fails.append("nu gasesc faza cu ursul pe axa")
			best_t = 0.0
		b._time = best_t
		if _control:
			b.center += Vector3.DOWN * 500.0
	_place(_job["dir"], _job["origin"], float(job["speed"]))


func _step_job(delta: float) -> void:
	var p := _race.player
	var dir: Vector3 = _job["dir"]
	_job["t"] = float(_job["t"]) + delta
	var rel: Vector3 = p.global_position - (_job["origin"] as Vector3)
	var along: float = rel.dot(dir)
	var lat: float = rel.cross(dir).y
	if along > -RUN_UP + 12.0 and along < MEASURE_LEN - 20.0 + 5.0:
		_job["min_v"] = minf(float(_job["min_v"]), p.horizontal_speed())
		_job["max_vy"] = maxf(float(_job["max_vy"]), p.velocity.y)
		_job["max_lat"] = maxf(float(_job["max_lat"]), absf(lat))
	if not _job.has("t_in") and along > -20.0:
		_job["t_in"] = _job["t"]
		_job["v_in"] = p.horizontal_speed()
	if _job.has("t_in") and not _job.has("t_out") and along > MEASURE_LEN - 20.0:
		_job["t_out"] = _job["t"]
		_job["v_out"] = p.horizontal_speed()
	if _job.has("t_out") or float(_job["t"]) > 14.0:
		_end_job()


func _end_job() -> void:
	var kind: String = _job["kind"]
	var t_seg := 99.0
	if _job.has("t_out"):
		t_seg = float(_job["t_out"]) - float(_job["t_in"])
	var hits := 0
	if kind == "sheep":
		hits = _herd().hits - int(_job["hits0"])
	print("[tf] %s %.0f m/s%s: %.2f s pe %.0f m, intrare %.1f, minima %.1f, iesire %.1f m/s, vy max %.2f, deviatie max %.1f m, %d lovituri, %d semnale impact" % [
		kind, float(_job["speed"]), " (CONTROL)" if _control else "",
		t_seg, MEASURE_LEN, float(_job.get("v_in", 0.0)), float(_job["min_v"]),
		float(_job.get("v_out", 0.0)), float(_job["max_vy"]), float(_job["max_lat"]), hits, _impacts])
	_log.append({"kind": kind, "speed": _job["speed"], "t": t_seg,
		"min_v": _job["min_v"], "v_in": _job.get("v_in", 0.0),
		"vy": _job["max_vy"], "hits": hits, "impacts": _impacts})
	if kind == "sheep" and _control:
		_herd().global_position = _job["hz_pos"]
	_job = {}


func _finish() -> void:
	if not _control:
		for e in _log:
			if String(e["kind"]) == "sheep":
				var v: float = e["v_in"]
				if float(e["min_v"]) < v * SHEEP_MIN_SPEED_FRAC:
					_fails.append("oile: masina oprita (%.1f din %.1f m/s la %.0f)" % [e["min_v"], v, e["speed"]])
				if int(e["hits"]) <= 0:
					_fails.append("oile: nicio lovitura la %.0f m/s (turma nu atinge masina)" % e["speed"])
				if int(e["impacts"]) <= 0:
					_fails.append("oile: lovitura fara semnal `impact` (camera/sunet tac) la %.0f m/s" % e["speed"])
				var key := str(int(e["speed"]))
				var ctl: float = float(CONTROL_S.get(key, 0.0))
				if ctl > 0.0 and float(e["t"]) - ctl < SHEEP_MIN_LOSS_S:
					_fails.append("oile: efect prea mic la %s m/s (%.2f s fata de control %.2f)" % [key, e["t"], ctl])
			elif String(e["kind"]) == "bear":
				if float(e["vy"]) > BEAR_MAX_AIR_VY:
					_fails.append("ursul arunca masina in aer (vy %.1f)" % e["vy"])
	for f in _fails:
		print("    " + f)
	print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
	get_tree().quit(0)
	set_physics_process(false)
