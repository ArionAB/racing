extends Node
## #499: mesajul WRONG WAY. Pe o cursa reala, sonda impune viteza jucatorului
## (fizica in rest neatinsa) in trei faze:
##   spin    — botul intors invers, dar alunecand INAINTE 3 s: fara mesaj;
##   invers  — mers pe contrasens 3 s: mesajul apare la ~WRONG_WAY_ON_S;
##   inapoi  — din nou pe sens: mesajul dispare in ~WRONG_WAY_OFF_S.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWrongWay.tscn -- [--track=4]

const RACE_SCENE := "res://scenes/race/Race.tscn"
const SPEED := 12.0

var _race: Race
var _phase := ""
var _phase_t := 0.0
var _on_at := -1.0
var _off_at := -1.0
var _seen := false
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


func _tangent(p: Car) -> Vector3:
	var r: TrackRoute = _race.track.route_at(p.route)
	var i := p.road_index
	var t := r.baked[r.wrap_index(i + 1)] - r.baked[r.wrap_index(i - 1)]
	t.y = 0.0
	return t.normalized()


func _physics_process(delta: float) -> void:
	if _race.state != Race.State.RUNNING:
		return
	_phase_t += delta
	var p := _race.player
	var tan := _tangent(p)
	var vy := p.velocity.y
	match _phase:
		"":
			if _phase_t > 1.0:
				_begin("spin")
				p.global_transform.basis = Basis.looking_at(-tan, Vector3.UP)
		"spin":
			p.velocity = tan * SPEED + Vector3.UP * vy
			p.angular_velocity = Vector3.ZERO
			if _race._wrong_way:
				_seen = true
			if _phase_t > 3.0:
				print("[wrong-way] spin (bot invers, mers inainte): mesaj %s" % _seen)
				if _seen:
					_fails.append("spin: WRONG WAY aparut desi masina merge pe sens")
				_begin("invers")
		"invers":
			p.velocity = -tan * SPEED + Vector3.UP * vy
			p.angular_velocity = Vector3.ZERO
			if _race._wrong_way and _on_at < 0.0:
				_on_at = _phase_t
			if _phase_t > 3.0:
				print("[wrong-way] contrasens: mesaj dupa %.2f s" % _on_at)
				if _on_at < Race.WRONG_WAY_ON_S - 0.1 or _on_at > Race.WRONG_WAY_ON_S + 0.3:
					_fails.append("contrasens: mesaj la %.2f s (vrem ~%.1f)" % [_on_at, Race.WRONG_WAY_ON_S])
				_begin("inapoi")
				p.global_transform.basis = Basis.looking_at(tan, Vector3.UP)
		"inapoi":
			p.velocity = tan * SPEED + Vector3.UP * vy
			p.angular_velocity = Vector3.ZERO
			if not _race._wrong_way and _off_at < 0.0:
				_off_at = _phase_t
			if _phase_t > 2.0:
				print("[wrong-way] inapoi pe sens: mesaj stins dupa %.2f s" % _off_at)
				if _off_at < 0.0 or _off_at > Race.WRONG_WAY_OFF_S + 0.3:
					_fails.append("inapoi: mesajul nu se stinge (%.2f s)" % _off_at)
				for f in _fails:
					print("    " + f)
				print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
				get_tree().quit(0)


func _begin(phase: String) -> void:
	_phase = phase
	_phase_t = 0.0
	_seen = false
