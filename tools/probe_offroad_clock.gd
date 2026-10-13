extends Node
## #497: ceasul de offroad al jucatorului. Trei scenarii pe aceeasi cursa:
##   iarba    — mutata 22 m lateral, pe teren, oprita: ceasul porneste, iar la
##              ~3 s (+1 s tranzitie) e repusa pe drum, langa punctul de iesire;
##   revenire — mutata pe iarba, inapoi pe drum dupa 1,5 s: ceasul dispare,
##              nicio repunere in urmatoarele 5 s;
##   banda    — (doar pe piste cu banda deschisa) mutata pe axa benzii: ceasul
##              nu porneste deloc.
## Jucatorul ramane pe PlayerController fara nicio tasta, deci sta pe loc.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeOffroadClock.tscn -- --track=4

const RACE_SCENE := "res://scenes/race/Race.tscn"
const SIDE_M := 22.0

var _race: Race
var _t := 0.0
var _phase := ""
var _phase_t := 0.0
var _respawned_at := -1.0
var _clock_seen := false
var _exit_index := 0
var _fails: PackedStringArray = []


func _ready() -> void:
	var idx := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(_race)
	_race.player.respawned.connect(func(_c: Car) -> void:
		if _respawned_at < 0.0:
			_respawned_at = _phase_t)


func _physics_process(delta: float) -> void:
	_t += delta
	_phase_t += delta
	if _race.state != Race.State.RUNNING:
		return
	var p := _race.player
	if _race._offroad_left >= 0.0:
		_clock_seen = true
	match _phase:
		"":
			if _phase_t > 2.0:
				_begin("iarba")
				_exit_index = p.last_safe_index
				_teleport_off(p)
		"iarba":
			if _respawned_at >= 0.0 and _phase_t > _respawned_at + 0.5:
				var r: TrackRoute = _race.track.route_at(0)
				var on_road := _race.track.is_on_road(p.road_index, p.global_position, p.route)
				var n := r.baked.size()
				var d := r.wrap_index(_exit_index - p.road_index)
				if d > n / 2:
					d -= n
				var back := float(d) * r.length() / float(n)
				print("[offroad-clock] iarba: ceas vazut %s, repusa la %.2f s, pe drum %s, %.0f m in urma iesirii"
					% [_clock_seen, _respawned_at, on_road, back])
				if not _clock_seen:
					_fails.append("iarba: ceasul n-a pornit")
				if _respawned_at < 3.7 or _respawned_at > 4.4:
					_fails.append("iarba: repusa la %.2f s (vrem ~4: 3 s ceas + 1 s tranzitie)" % _respawned_at)
				if not on_road:
					_fails.append("iarba: repusa in afara drumului")
				if absf(back) > 40.0:
					_fails.append("iarba: repusa la %.0f m in urma punctului de iesire" % back)
				_begin("revenire")
				_exit_index = p.last_safe_index
				_teleport_off(p)
			elif _phase_t > 10.0:
				_fails.append("iarba: nerepusa in 10 s (ceas vazut %s)" % _clock_seen)
				_begin("revenire")
		"revenire":
			if _phase_t > 1.5 and _phase_t - delta <= 1.5:
				var t := _race.track.recovery_transform(_exit_index, 0.0, 0)
				p.global_transform = t
				p.velocity = Vector3.ZERO
				p.angular_velocity = Vector3.ZERO
			# Imediat dupa revenire ceasul trebuie sa fi disparut. Doar fereastra
			# asta: mai tarziu, oprita pe linia de start, masina poate fi impinsa
			# legitim in afara drumului de AI-urile care trec (masurat pe Dunele).
			if _phase_t > 1.8 and _phase_t - delta <= 1.8 and _race._offroad_left >= 0.0:
				_fails.append("revenire: ceasul ramane pornit pe drum (%.1f s)" % _race._offroad_left)
			if _phase_t > 2.5:
				print("[offroad-clock] revenire: ceas vazut %s, repusa %s"
					% [_clock_seen, _respawned_at >= 0.0])
				if not _clock_seen:
					_fails.append("revenire: ceasul n-a pornit pe iarba")
				if _respawned_at >= 0.0:
					_fails.append("revenire: repusa desi a revenit pe drum")
				_next_after_return()
		"banda":
			if _phase_t > 3.5:
				print("[offroad-clock] banda: ceas vazut %s, ruta %d" % [_clock_seen, p.route])
				if _clock_seen:
					_fails.append("banda: ceasul a pornit pe o banda declarata")
				_finish()


func _next_after_return() -> void:
	var track := _race.track
	for bi in range(1, track.routes.size()):
		var br := track.route_at(bi)
		if br == null or br.baked.size() < 10 or not track.branch_is_open(bi):
			continue
		_begin("banda")
		var p := _race.player
		var i := br.baked.size() / 2
		var dir := br.baked[i + 1] - br.baked[i]
		dir.y = 0.0
		p.global_transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP),
			br.baked[i] + Vector3.UP * 1.2)
		p.velocity = Vector3.ZERO
		p.angular_velocity = Vector3.ZERO
		p.route = bi
		p.road_index = i
		return
	print("[offroad-clock] banda: pista fara banda deschisa, sarit")
	_finish()


func _teleport_off(p: Car) -> void:
	var track := _race.track
	var r: TrackRoute = track.route_at(0)
	var i := p.road_index
	var side := r.side_at(i)
	var pos := r.baked[i] + side * (track.width_at_index(i) + SIDE_M)
	var space := p.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 40.0, pos + Vector3.DOWN * 60.0)
	q.exclude = [p.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		pos = (hit.position as Vector3) + Vector3.UP * 1.2
	var dir := r.baked[r.wrap_index(i + 1)] - r.baked[i]
	dir.y = 0.0
	p.global_transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), pos)
	p.velocity = Vector3.ZERO
	p.angular_velocity = Vector3.ZERO


func _begin(phase: String) -> void:
	_phase = phase
	_phase_t = 0.0
	_respawned_at = -1.0
	_clock_seen = false


func _finish() -> void:
	for f in _fails:
		print("    " + f)
	print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
	get_tree().quit(0)
