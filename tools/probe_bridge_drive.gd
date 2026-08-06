extends Node
## O SINGURA masina trecuta peste podul mobil, cu profilul ei tiparit metru cu
## metru. Sonda de diagnostic, nu de garda.
##
## De ce nu ajunge `probe_race`: acolo se vede CA plutonul se opreste la fractia
## 0.31, nu DE CE. Cifrele agregate (viteza medie pe felie, izbituri in pereti)
## descriu simptomul; ca sa gasesti obstacolul iti trebuie o masina, o intrare
## curata si o coloana de cote.
##
## Ruleaza CA SCENA: masina are nevoie de autoload-urile GameState/AudioManager.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBridgeDrive.tscn
##   ... -- --track=4 --speed=30 --open
##
## `--open` tine traveea ridicata tot timpul; fara el, podul e inchis. Cele doua
## rulari raspund la intrebari diferite: inchis = "trec pe pod?", deschis = "sar
## golul?".

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## De cati metri inainte de pod porneste masina. Se poate schimba cu --runup=,
## si trebuie: pornirea implicita de 120 m cadea fix peste bariera mobila de la
## fractia 0.256, deci prima rulare a masurat bariera, nu podul.
var _run_up: float = 70.0
## Cat urmarim, dupa ce a pornit.
const WATCH_SECONDS: float = 12.0

var _track_index: int = 4
var _entry_speed: float = 30.0
var _force_open: bool = false
var _track: Track
var _car: Car
var _bridge: LiftBridgeHazard
var _origin: Vector3
var _across: Vector3
var _time: float = 0.0
var _last_print: float = -1.0
var _done: bool = false
var _min_clearance: float = 1e9
var _hits: Dictionary = {}
## Ce obstacol vertical a atins masina, si la ce z.
var _touch: Dictionary = {}
var _normals: Dictionary = {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--speed="):
			_entry_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--runup="):
			_run_up = float(arg.trim_prefix("--runup="))
		elif arg == "--open":
			_force_open = true
	_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_track)
	for child in _track.get_children():
		if child is LiftBridgeHazard:
			_bridge = child
	if _bridge == null:
		print("probe_bridge_drive: pista nu are pod mobil")
		get_tree().quit(1)
		return
	var channels: Array = _track.get("_channels")
	var ch: Dictionary = channels[0]
	_origin = ch["origin"]
	_across = ch["across"]

	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.track = _track
	# Pornire pe axa soselei, cu RUN_UP metri inainte de pod si cu viteza ceruta
	# deja in ea: ne intereseaza podul, nu acceleratia.
	var start := _origin - _across * _run_up
	start.y = _track_road_y(start) + 0.6
	_car.global_transform = Transform3D(
		Basis.looking_at(_across, Vector3.UP), start)
	_car.velocity = _across * _entry_speed
	_car.road_index = _track.closest_index_global(start)
	_car.last_safe_index = _car.road_index
	# Creier de AI, nu volan blocat: intrebarea e ce pateste PLUTONUL pe pod, iar
	# un AI care franeaza inainte de viraj face parte din raspuns.
	var ai := AIController.new()
	_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260806
	ai.configure(_track, rng)
	ai.line_offset = 0.0
	_car.race_active = true
	_car.respawned.connect(func(_c: Car) -> void:
		_note("REPUNERE"))
	_car.wall_hit.connect(func(_c: Car, impact: float) -> void:
		_note("PERETE %.1f m/s" % impact))
	var shp: CollisionShape3D = null
	for c in _car.get_children():
		if c is CollisionShape3D:
			shp = c
	print("--- geometrie: gap=%.2f near_lip=%s far_lip=%s" % [
		_bridge.gap, str(_bridge.near_lip), str(_bridge.far_lip)])
	print("--- colizor masina: %s la %s" % [
		str(shp.shape) if shp != null else "?",
		str(shp.position) if shp != null else "?"])
	if shp != null and shp.shape is BoxShape3D:
		print("--- cutia masinii: %s" % str((shp.shape as BoxShape3D).size))
	print("=== TRECERE PESTE POD: %s, intrare %.0f m/s, travee %s ==="
		% [_track.track_name, _entry_speed, "SUS" if _force_open else "JOS"])
	print("  z e distanta pana la mijlocul podului (+ inainte, - dupa)")
	print("     t     z      y   viteza  sol  eveniment")


## Cota soselei pe axa, la o pozitie oarecare.
func _track_road_y(at: Vector3) -> float:
	var i := _track.closest_index_global(at)
	return _track.baked[i].y


func _note(text: String) -> void:
	_hits[_z()] = text


func _z() -> float:
	return roundf((_origin - _car.global_position).dot(_across))


func _physics_process(delta: float) -> void:
	if _done or _car == null:
		return
	# Faza podului se REIMPUNE: `_physics_process`-ul lui isi avanseaza ceasul.
	if _force_open:
		_bridge.set("_time", LiftBridgeHazard.LIFT_TIME)
		_bridge.call("_apply_cycle", LiftBridgeHazard.LIFT_TIME)
	else:
		_bridge.set("_time", 0.0)
		_bridge.call("_apply_cycle", 0.0)
	_time += delta
	var z := _z()
	# CINE l-a oprit, nu doar ca a fost oprit. Semnalul `wall_hit` nu duce
	# colizorul cu el, iar fara nume diagnosticul ramane la ghicit.
	for i in _car.get_slide_collision_count():
		var col := _car.get_slide_collision(i)
		var n := col.get_normal()
		if absf(n.y) > 0.7:
			continue # podea, nu obstacol
		var who: Node = col.get_collider()
		var parent := who.get_parent() if who != null else null
		_normals["%s" % str(n.snappedf(0.01))] = z
		_touch["%s / %s" % [
			String(parent.name) if parent != null else "?",
			String(who.name) if who != null else "?"]] = z
	if _time - _last_print > 0.1:
		_last_print = _time
		var event: String = String(_hits.get(z, ""))
		print("  %5.2f %5.0f %6.2f %6.1f   %s  %s"
			% [_time, z, _car.global_position.y, _car.horizontal_speed(),
				"da " if _car.is_on_floor() else "NU ", event])
	if _time > WATCH_SECONDS or z < -80.0:
		_report()


func _report() -> void:
	_done = true
	print("")
	if not _touch.is_empty():
		print("  obstacole verticale atinse:")
		for k: String in _touch.keys():
			print("    %-46s la z=%.0f" % [k, _touch[k]])
	for k: String in _normals.keys():
		print("    normala %s la z=%.0f" % [k, _normals[k]])
	if _hits.is_empty():
		print("REZULTAT: trecere curata")
	else:
		var keys := _hits.keys()
		keys.sort()
		for k: float in keys:
			print("  la z=%.0f: %s" % [k, _hits[k]])
	get_tree().quit(0)
