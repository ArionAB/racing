extends Node
## Cine trece gaura craterului si cu ce viteza (#511).
##
## Ruleaza o cursa si, pentru fiecare masina, noteaza viteza la BUZA
## (frac 0.497) si daca a ajuns pe partea cealalta sau a cazut in cuva.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeStromSaritura.tscn -- --track=4 --seconds=200 [--seed=N]

const RACE_SCENE := "res://scenes/race/Race.tscn"
const LIP := 0.497
const LAND := 0.503

var _race: Race
var _t := 0.0
var _secs := 200.0
var _armed := {}
var _vlip := {}
var _lat := {}
var _vy := {}
var _up := {}
var _ok := {}
var _fail := {}
var _names := {}


func _ready() -> void:
	var idx := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--seconds="):
			_secs = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			seed(int(arg.trim_prefix("--seed=")))
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.ai_count = 5
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(_race)
	await get_tree().process_frame
	print("[saritura] pista: %s" % GameState.track_label(idx))
	for c in _race.cars:
		_names[c] = c.pilot_name
		_ok[c] = 0
		_fail[c] = 0
		_armed[c] = false
		_vlip[c] = []
		_lat[c] = []
		_vy[c] = []
		_up[c] = []
		c.respawned.connect(func(_car: Car) -> void:
			if bool(_armed.get(c, false)):
				_fail[c] = int(_fail[c]) + 1
				_armed[c] = false)


func _physics_process(delta: float) -> void:
	if _race == null:
		return
	_t += delta
	for c in _race.cars:
		var f := _race.track.frac_at(c.road_index, c.route)
		if not bool(_armed.get(c, false)) and f >= LIP - 0.004 and f <= LIP + 0.004:
			_armed[c] = true
			var rr: TrackRoute = _race.track.route_at(c.route)
			var lat := rr.lateral_distance(c.road_index, c.global_position)
			var sidev := rr.side_at(c.road_index)
			var signed: float = lat * (1.0 if (c.global_position - rr.baked[c.road_index]).dot(sidev) > 0.0 else -1.0)
			var fwd := -c.global_transform.basis.z
			var dirv := c.linear_velocity
			dirv.y = 0.0
			var up := c.global_transform.basis.y.dot(Vector3.UP)
			(_vlip[c] as Array).append(c.horizontal_speed())
			(_lat[c] as Array).append(signed)
			(_vy[c] as Array).append(c.linear_velocity.y)
			(_up[c] as Array).append(up)
		elif bool(_armed.get(c, false)) and f > LAND + 0.004 and f < LAND + 0.08:
			_ok[c] = int(_ok[c]) + 1
			_armed[c] = false
	if _t > _secs:
		_report()


func _report() -> void:
	print("")
	print("  masina            treceri  caderi   v_buza med   lat med/min/max   vy med   up med")
	for c in _race.cars:
		var vs: Array = _vlip[c]
		var lo := INF
		var hi := -INF
		var sum := 0.0
		for v: float in vs:
			lo = minf(lo, v); hi = maxf(hi, v); sum += v
		var med := sum / maxf(float(vs.size()), 1.0)
		var la: Array = _lat[c]
		var llo := INF; var lhi := -INF; var lsum := 0.0
		for v: float in la:
			llo = minf(llo, v); lhi = maxf(lhi, v); lsum += v
		var vya: Array = _vy[c]
		var vysum := 0.0
		for v: float in vya: vysum += v
		var upa: Array = _up[c]
		var upsum := 0.0
		for v: float in upa: upsum += v
		var k := maxf(float(la.size()), 1.0)
		print("  %-18s %5d   %5d   %6.1f   %+5.1f /%+5.1f /%+5.1f   %+5.1f   %5.2f"
			% [_names[c], _ok[c], _fail[c], med,
				lsum / k, 0.0 if is_inf(llo) else llo, 0.0 if is_inf(lhi) else lhi,
				vysum / k, upsum / k])
	get_tree().quit(0)
