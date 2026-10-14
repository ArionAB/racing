extends Node
## #495: repunerea cu tranzitie. Doua scenarii pe aceeasi cursa:
##   manual    — `Race._on_respawn_requested` (butonul / tasta R): cat trece pana
##               la `respawned` (trebuie ~Car.RECOVER_S, nu 0), daca masina
##               clipeste intre timp si daca butonul e dezactivat;
##   rasturnat — masina jucatorului intoarsa pe acoperis, pe asfalt, oprita:
##               o prinde plasa din Race? in cat timp? apare pe roti, pe drum?
## Jucatorul ramane pe PlayerController fara nicio tasta, deci sta pe loc.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRecover.tscn -- [--track=0]

const RACE_SCENE := "res://scenes/race/Race.tscn"

var _race: Race
var _t := 0.0
var _phase := ""
var _phase_t := 0.0
var _respawned_at := -1.0
var _started_at := -1.0
var _blink_off := 0
var _button_off := false
var _fails: PackedStringArray = []


func _ready() -> void:
	var idx := 0
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
			_respawned_at = _t)
	_race.player.recovery_started.connect(func(_c: Car, _s: float) -> void:
		if _started_at < 0.0:
			_started_at = _t)


func _physics_process(delta: float) -> void:
	_t += delta
	_phase_t += delta
	if _race.state != Race.State.RUNNING:
		return
	var p := _race.player
	match _phase:
		"":
			# 2 s de cursa: cooldown-ul de start trece, AI-ul pleaca.
			if _phase_t > 2.0:
				_begin("manual")
				_race._on_respawn_requested()
		"manual":
			_sample(p)
			if _respawned_at >= 0.0 or _phase_t > 4.0:
				_report_manual()
				_begin("rasturnat")
				var t := p.global_transform
				t.basis = t.basis.rotated(t.basis.z.normalized(), PI)
				p.global_transform = Transform3D(t.basis, t.origin + Vector3.UP * 1.5)
				p.velocity = Vector3.ZERO
				p.angular_velocity = Vector3.ZERO
		"rasturnat":
			if _respawned_at >= 0.0 and _phase_t > _respawned_at - _phase_start() + 1.0:
				_report_flip(p)
				_finish()
			elif _phase_t > 12.0:
				_fails.append("rasturnat: neprinsa in 12 s (up.y=%.2f)"
					% p.global_transform.basis.y.y)
				_finish()


var _phase_start_t := 0.0

func _phase_start() -> float:
	return _phase_start_t


func _begin(phase: String) -> void:
	_phase = phase
	_phase_t = 0.0
	_phase_start_t = _t
	_respawned_at = -1.0
	_started_at = -1.0
	_blink_off = 0
	_button_off = false


func _sample(p: Car) -> void:
	if p._visual != null and not p._visual.visible:
		_blink_off += 1
	if not p.can_respawn():
		_button_off = true


func _report_manual() -> void:
	var dt := _respawned_at - _phase_start_t if _respawned_at >= 0.0 else -1.0
	print("[recover] manual: tranzitie %.2f s, cadre stinse %d, buton blocat %s"
		% [dt, _blink_off, _button_off])
	if dt < Car.RECOVER_S - 0.1 or dt > Car.RECOVER_S + 0.2:
		_fails.append("manual: tranzitie %.2f s (vrem ~%.1f)" % [dt, Car.RECOVER_S])
	if _blink_off == 0:
		_fails.append("manual: masina nu a clipit")
	if not _button_off:
		_fails.append("manual: butonul ramane activ in tranzitie")


func _report_flip(p: Car) -> void:
	var caught := _started_at - _phase_start_t
	var tr := p.global_transform
	var on_road := _race.track.is_on_road(p.road_index, p.global_position, p.route)
	print("[recover] rasturnat: prinsa dupa %.2f s, repusa dupa %.2f s, up.y=%.2f, pe drum %s, vizibila %s"
		% [caught, _respawned_at - _phase_start_t, tr.basis.y.y, on_road,
			p._visual.visible if p._visual != null else true])
	if tr.basis.y.y < 0.8:
		_fails.append("rasturnat: tot nu sta pe roti (up.y=%.2f)" % tr.basis.y.y)
	if not on_road:
		_fails.append("rasturnat: repusa in afara drumului")


func _finish() -> void:
	for f in _fails:
		print("    " + f)
	print("VERDICT: %s" % ("OK" if _fails.is_empty() else "PROBLEMA"))
	get_tree().quit(0)
