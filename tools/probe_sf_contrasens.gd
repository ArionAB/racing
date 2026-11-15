extends Node
## CONTRASENSUL PE POD, CU INTENTIE (Track25 B200, brief san_francisco.md §7 pasul 2b, runda 2).
## Intrebarea coordonatorului: poate JUCATORUL, intentionat, sa intre pe contrasens pe la capetele
## despartitorului? Un pilot scriptat (gaz la fund, plafon de viteza) conduce o singura masina pe
## un sir de puncte de HARTA (x est, y nord) care incearca sa treaca de pe banda proprie pe cea
## opusa, la fiecare capat al coridorului, si raporteaza: a ajuns pe banda opusa IN coridor (centrul
## pe partea gresita a despartitorului, ca observatorul probe_sf_watch.gd), cu ce s-a lovit, cat a
## mers off-road.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfContrasens.tscn [-- --only=A]
##
## Scenariile (puncte de harta; primul = pozitia de start, directia spre al doilea):
##   A  baza podului, PRIN S: de pe banda spre larg (nord), taie spre banda spre oras (sud) in S;
##   B  baza podului, PE LANGA capatul de V al zidului: de pe strada de intors, peste insula dintre
##      viraje, pe virajul benzii spre oras luat invers;
##   C  malul celalalt, PRIN S: iesit din balon pe banda spre oras, taie in S pe banda spre larg si
##      o ia spre oras pe ea (contrasens);
##   D  malul celalalt, PE LANGA capatul de E al zidului: din balon, iesirea benzii spre larg luata
##      INVERS (adica pista condusa pe dos).
## Cu `--cap-s=0` zidul din S e scos inaintea cursei (martorul: fara el, A si C trebuie sa reuseasca).
const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const SCENARIOS := {
	"A": [Vector2(178, 242.0), Vector2(205, 233.0), Vector2(232, 222.0), Vector2(300, 222.4), Vector2(400, 222.4)],
	"B": [Vector2(150, 330.0), Vector2(150, 285.0), Vector2(128, 240.0), Vector2(140, 200.0),
		Vector2(165, 210.0), Vector2(200, 216.0), Vector2(240, 222.4), Vector2(330, 222.4)],
	"C": [Vector2(588, 211.0), Vector2(565, 215.0), Vector2(540, 228.0), Vector2(515, 235.5),
		Vector2(450, 234.8), Vector2(380, 234.8)],
	"D": [Vector2(612, 222.0), Vector2(600, 240.0), Vector2(565, 243.5), Vector2(525, 236.0),
		Vector2(450, 234.8), Vector2(380, 234.8)],
}

class Pilot extends CarController:
	var probe: Node = null
	func get_steer() -> float:
		return probe.call("pilot_steer")
	func get_throttle() -> float:
		return probe.call("pilot_throttle")

var _race: Node
var _track: Track
var _med: MovableMedianHazard
var _car: Car
var _pilot: Pilot
var _names: Array = []
var _cur: int = -1
var _wp: Array = []
var _wi: int = 1
var _t: float = 0.0
var _res: Dictionary = {}
var _all: Array = []
var _cap_s: bool = true
var _vmax: float = 22.0


func _ready() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		elif a == "--cap-s=0":
			_cap_s = false
		elif a.begins_with("--vmax="):
			_vmax = float(a.trim_prefix("--vmax="))
	for k in SCENARIOS:
		if only.is_empty() or only.contains(k):
			_names.append(k)
	GameState.selected_track = GameState.index_of_scene("Track25")
	GameState.champ_active = false
	GameState.total_laps = 99
	var none: Array[int] = []
	GameState.ai_cars_override = none
	GameState.ai_count = 0
	GameState.selected_car = 0
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	_track = _race.track
	for n in _track.find_children("*", "MovableMedianHazard", true, false):
		_med = n as MovableMedianHazard
	if not _cap_s:
		var cs := _track.find_child("CapS", true, false)
		if cs != null:
			cs.get_parent().remove_child(cs)
			cs.free()
			print("=== --cap-s=0: zidul din S scos (martor)")
	_car = _race.player
	var old: CarController = _car.controller
	_car.remove_child(old)
	old.free()
	_pilot = Pilot.new()
	_pilot.probe = self
	_car.set_controller(_pilot)


static func _g(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, -p.y)


func _start_scenario() -> void:
	_cur += 1
	if _cur >= _names.size():
		_finish()
		return
	var k: String = _names[_cur]
	_wp = SCENARIOS[k]
	_wi = 1
	_t = 0.0
	var p0 := _g(_wp[0], 22.0)
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(p0 + Vector3.UP * 10.0, p0 + Vector3.DOWN * 30.0))
	if not hit.is_empty():
		p0.y = (hit["position"] as Vector3).y + 0.6
	var d := _g(_wp[1], p0.y) - p0
	d.y = 0.0
	_car.global_transform = Transform3D(Basis.looking_at(d.normalized(), Vector3.UP), p0)
	_car.set("velocity", d.normalized() * 15.0)
	_car.linear_velocity = d.normalized() * 15.0
	_res = {"scenariu": k, "pe_contrasens_in_coridor": false, "prima_trecere": "", "contacte": {},
		"offroad_s": 0.0, "terminat": false, "max_s_contrasens": 0.0}


func pilot_steer() -> float:
	if _cur < 0 or _cur >= _names.size():
		return 0.0
	var target := _g(_wp[_wi], 0.0)
	var pos := _car.global_position
	var to := target - pos
	to.y = 0.0
	if to.length() < 9.0 and _wi < _wp.size() - 1:
		_wi += 1
	var fwd := -_car.global_transform.basis.z
	fwd.y = 0.0
	return clampf(fwd.normalized().signed_angle_to(to.normalized(), Vector3.UP) * 2.0, -1.0, 1.0)


func pilot_throttle() -> float:
	return 1.0 if _car.horizontal_speed() < _vmax else 0.0


func _physics_process(delta: float) -> void:
	if _race == null or _race.state != Race.State.RUNNING:
		return
	if _cur < 0:
		_start_scenario()
		return
	if _cur >= _names.size():
		return
	_t += delta
	var l := _med.global_transform.affine_inverse() * _car.global_position
	var in_corr := l.x >= -_med.approach_m and l.x <= _med.deck_length + _med.approach_m \
		and absf(l.z) < _med.deck_half_width + 1.0 and l.y > -4.0 and l.y < 6.0
	# sensul ales de scenariu: A/B spre +X pe banda de SUD (+Z local) = contrasens; C/D spre -X pe
	# banda de NORD (-Z) = contrasens. Pe stanga: spre +X se circula pe -Z.
	# sensul INTENTIONAT al scenariului (A/B spre +X, C/D spre -X), nu cel de moment: o masina
	# intoarsa de bariera nu e „pe contrasens" doar fiindca s-a rasucit pe banda ei
	var going := 1.0 if String(_res.scenariu) in ["A", "B"] else -1.0
	var own_side := float(_med.plus_dir_side) * going      # latura pe care AR TREBUI sa fie
	if in_corr and own_side * (l.z - _med.offset_at(l.x)) < 0.0:
		if not bool(_res.pe_contrasens_in_coridor):
			_res.prima_trecere = "s=%.1f z=%.2f v=%.1f" % [l.x, l.z, _car.horizontal_speed()]
		_res.pe_contrasens_in_coridor = true
		_res.max_s_contrasens = float(_res.max_s_contrasens) + _car.horizontal_speed() * delta
	if not _track.is_on_road(_car.road_index, _car.global_position):
		_res.offroad_s = float(_res.offroad_s) + delta
	for b in _car.get_colliding_bodies():
		var nm := String((b as Node).name)
		if nm in ["RoadTop", "Shoulders", "RoadSides", "TerrainBody"] or nm.begins_with("@"):
			continue
		(_res.contacte as Dictionary)[nm] = int((_res.contacte as Dictionary).get(nm, 0)) + 1
	var last := _g(_wp[_wp.size() - 1], 0.0)
	var dist := Vector2(_car.global_position.x - last.x, _car.global_position.z - last.z).length()
	if dist < 10.0 or _t > 30.0:
		_res.terminat = dist < 10.0
		print("[contrasens] %s cap_s=%s: pe contrasens in coridor = %s (%s; %.0f m parcursi pe contrasens), ajuns la capat = %s in %.1f s, contacte %s" % [
			_res.scenariu, str(_cap_s), str(_res.pe_contrasens_in_coridor), _res.prima_trecere,
			float(_res.max_s_contrasens), str(_res.terminat), _t, str(_res.contacte)])
		print("    off-road %.1f s" % float(_res.offroad_s))
		_all.append(_res.duplicate())
		_start_scenario()


func _finish() -> void:
	var n := 0
	for r in _all:
		if bool(r.pe_contrasens_in_coridor):
			n += 1
	print("=== SF CONTRASENS cap_s=%s: %d din %d scenarii au ajuns pe contrasens in coridor" % [
		str(_cap_s), n, _all.size()])
	get_tree().quit(0)
