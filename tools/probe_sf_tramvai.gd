extends Node
## Sonda 1c San Francisco, partea SOLO (brief docs/track_briefs/san_francisco.md
## §7 pasul 1c, contractul 2): o singura masina, condusa de un pilot scriptat,
## intra INTENTIONAT in tramvai pe urcarea de 11,5% (tools/SondaSfTramvai*.tscn,
## generate de tools/gen_sf_tramvai.py) si se masoara ce costa: ejectare (nu
## are voie), strivire, viteza minima si timpul pierdut pana in varful urcarii,
## fata de aceeasi masina, pe aceeasi linie, fara tramvai.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfTramvai.tscn -- \
##       --car=3 --mode=rear --tram=1 [--scene=res://tools/SondaSfTramvai.tscn]
##
## `--mode=` rear   pe ax, in coada lui (lovitura din spate, plina);
##          corner  la 1,6 m de ax (coltul din spate, jumatate de suprapunere);
##          side    alaturi la 3,3 m, apoi trage de volan spre ax cand botul
##                  ajunge la coada lui (`--side-arm=9`: centrul masinii la 9 m
##                  in spatele centrului tramvaiului) — lovitura in flanc.
##                  Masina vine cu ~25 m/s mai repede ca el: daca ar astepta sa
##                  fie alaturi, l-ar depasi inainte sa vireze (0 contacte).
##   Dupa primul contact pilotul iese la 3,5 m (pe partea lui) si depaseste — ca
##   un om, nu ca un zid care tot apasa gazul in coada tramvaiului.
## `--tram=0`  scoate tramvaiul inainte de prima fizica (linia de baza).
## `--phase=0.12`  faza tramvaiului: la verde e pe ax la ~x 215, deci masina
##   singura il prinde pe la x 240-260, la mijlocul portiunii lui de ax.
## `--gap`  tipareste o data inclinarea corpului si cat de sus/jos sunt colturile
##   cutiei fata de drum (verifica `pitch_to_ground` pe panta).
##
## Iesire: o linie `=== SF TRAMVAI` cu toate cifrele (o citeste
## tools/sf_tramvai_solo.sh).
const RACE_SCENE: String = "res://scenes/race/Race.tscn"
## Varful urcarii (x lumii): LEAD 96 + racord 24 + urcare 290 + racord 24 + 6.
const X_END: float = 440.0

class Pilot extends CarController:
	var target_z: float = 0.0
	func get_steer() -> float:
		var v := car.linear_velocity
		var sp := maxf(Vector2(v.x, v.z).length(), 3.0)
		var z := car.global_position.z
		return clampf(0.18 * (z - target_z) + 2.0 * (v.z / sp), -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0

var _scene: String = "res://tools/SondaSfTramvai.tscn"
var _car_idx: int = 0
var _mode: String = "rear"
var _tram_on: bool = true
var _phase: float = 0.12
var _gap: bool = false
var _race: Node = null
var _car: Car = null
var _tram: BusHazard = null
var _pilot: Pilot = null
var _t: float = 0.0
var _done: bool = false
var _contact_frames: int = 0
var _first_contact_t: float = -1.0
var _first_contact_v: float = 0.0
var _contact_rel: Vector3 = Vector3.ZERO
var _ejected: bool = false
var _eject_dv: float = 0.0
var _crushes: int = 0
var _respawns: int = 0
var _v_min_after: float = 1e9
var _t_end: float = -1.0
var _side_armed: bool = false
var _side_arm: float = 9.0
var _gap_done: bool = false
var _escaped: bool = false
var _prev_v: float = 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			_scene = arg.trim_prefix("--scene=")
		elif arg.begins_with("--car="):
			_car_idx = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--tram="):
			_tram_on = arg.trim_prefix("--tram=") == "1"
		elif arg.begins_with("--phase="):
			_phase = float(arg.trim_prefix("--phase="))
		elif arg.begins_with("--side-arm="):
			_side_arm = float(arg.trim_prefix("--side-arm="))
		elif arg == "--gap":
			_gap = true
	GameState.selected_track = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.traffic_override = -1
	GameState.ai_cars_override = []
	GameState.ai_count = 0
	GameState.selected_car = clampi(_car_idx, 0, GameState.CAR_DATA.size() - 1)
	GameState.track_scene_override = _scene
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	var track: Track = _race.track
	for n in track.find_children("*", "BusHazard", true, false):
		if _tram_on and _tram == null:
			_tram = n as BusHazard
			_tram.phase = _phase
		else:
			n.free()
	_car = _race.player
	var old: CarController = _car.controller
	_car.remove_child(old)
	old.free()
	_pilot = Pilot.new()
	_car.set_controller(_pilot)
	_pilot.target_z = {"rear": 0.0, "corner": 1.6, "side": 3.3}.get(_mode, 0.0)
	_car.ejected.connect(func(c: Car, _r: Node3D) -> void:
		_ejected = true
		_eject_dv = c.last_eject_value)
	_car.crushed.connect(func(_c: Car, _s: float) -> void: _crushes += 1)
	_car.respawned.connect(func(_c: Car) -> void: _respawns += 1)


func _physics_process(delta: float) -> void:
	if _done or _race == null or _race.state != Race.State.RUNNING:
		return
	_t += delta
	var pos := _car.global_position
	var v := _car.horizontal_speed()
	if _tram != null and not _tram.is_hidden():
		var tp := _tram.body_position()
		if _gap and not _gap_done and tp.x > 260.0:
			_print_gap()
		# side: alaturi de tramvai (centrul masinii intre coada si mijlocul lui)
		if _mode == "side" and not _side_armed and _first_contact_t < 0.0 \
				and pos.x > tp.x - _side_arm:
			_side_armed = true
			_pilot.target_z = 0.0
		var touching := false
		for b in _car.get_colliding_bodies():
			if (b as Node).get_parent() == _tram:
				touching = true
		if touching:
			_contact_frames += 1
			if _first_contact_t < 0.0:
				_first_contact_t = _t
				_first_contact_v = _prev_v
				_contact_rel = _tram._body.global_transform.affine_inverse() * pos
		if _first_contact_t >= 0.0 and not _escaped:
			# iese pe partea lui si depaseste
			_escaped = true
			_pilot.target_z = 3.5 if pos.z >= tp.z else -3.5
	if _first_contact_t >= 0.0 and _t_end < 0.0:
		_v_min_after = minf(_v_min_after, v)
	if _t_end < 0.0 and pos.x >= X_END and absf(pos.z) < 20.0:
		_t_end = _t
	_prev_v = v
	if _t_end >= 0.0 or _t > 60.0:
		_finish()


func _print_gap() -> void:
	_gap_done = true
	var body := _tram._body
	var box: BoxShape3D = null
	var cs_pos := Vector3.ZERO
	for c in body.get_children():
		var cs := c as CollisionShape3D
		if cs != null and cs.shape is BoxShape3D:
			box = cs.shape as BoxShape3D
			cs_pos = cs.position
			break
	var space := body.get_world_3d().direct_space_state
	var out := []
	for sz in [-1.0, 1.0]:
		var corner: Vector3 = body.global_transform * (cs_pos + Vector3(0.0, -box.size.y * 0.5, sz * box.size.z * 0.5))
		var q := PhysicsRayQueryParameters3D.create(corner + Vector3.UP * 5.0,
			corner - Vector3.UP * 5.0, 0xFFFFFFFF, [body.get_rid()])
		var hit := space.intersect_ray(q)
		var gy: float = (hit["position"] as Vector3).y if not hit.is_empty() else NAN
		out.append("%s %.2f m" % ["bot" if sz < 0.0 else "coada", corner.y - gy])
	var fwd := -body.global_transform.basis.z
	print("[gap] tramvai la x=%.1f: inclinare %.2f grade (panta drumului %.2f grade); colturile de jos fata de drum: %s" % [
		body.global_position.x, rad_to_deg(asin(clampf(fwd.y, -1.0, 1.0))),
		rad_to_deg(atan(0.115)), ", ".join(out)])


func _finish() -> void:
	_done = true
	print("=== SF TRAMVAI car=%d (%s) mode=%s tram=%d: t_varf=%.2f s, contact=%s (t %.2f, v inainte %.1f m/s, rel %s, %d cadre), ejectat=%s (dv %.1f), strivit=%d, repuneri=%d, v_min dupa contact=%.1f" % [
		_car_idx, _car.car_name, _mode, int(_tram_on), _t_end,
		str(_first_contact_t >= 0.0), _first_contact_t, _first_contact_v,
		"(%.1f, %.1f, %.1f)" % [_contact_rel.x, _contact_rel.y, _contact_rel.z],
		_contact_frames, str(_ejected), _eject_dv, _crushes, _respawns,
		_v_min_after if _v_min_after < 1e8 else -1.0])
	get_tree().quit(0)
