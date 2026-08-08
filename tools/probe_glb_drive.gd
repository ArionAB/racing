extends Node
## Proba lantului Marble: un GLB arbitrar (export World Labs sau stand-in-ul
## din make_standin_glb.gd) devine lume condusibila prin GlbWorld, iar o masina
## reala conduce pe el. Masoara, nu presupune:
##
##   - masina NU cade prin teren (trimesh + backface_collision functioneaza)
##   - masina inainteaza (terenul e sub floor_max_angle, grip-ul musca)
##   - masina sta pe sol majoritatea timpului (nu sare haotic din poligoane)
##
## Rulare (ca SCENA, nu ca --script: car.gd cheama AudioManager neconditionat,
## iar autoload-urile nu exista in modul --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGlbDrive.tscn \
##       -- --glb=C:/cale/teren.glb [--scale=1.0] [--seconds=12]

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const CAR_DATA: String = "res://scenes/cars/data/muscle.tres"

## Sub raza asta fata de centru masina hoinareste; peste, e intoarsa spre casa.
const HOME_RADIUS: float = 55.0
## Praguri de verdict, alese conservator: Muscle tine ~25-30 m/s pe drum drept,
## deci 40 m in 12 s inseamna "abia se misca, dar se misca pe teren accidentat".
const MIN_DISTANCE: float = 40.0
const MIN_FLOOR_RATIO: float = 0.55
## Cat de adanc sub cutia lumii inseamna "a cazut prin teren".
const FALL_MARGIN: float = 2.0

## Volan cu doua stari: hoinareste in sinus ca sa guste terenul din mai multe
## directii, dar se intoarce spre centru cand se apropie de marginea lumii —
## altfel proba ar masura "a cazut de pe marginea mesh-ului", nu conducerea.
class WanderController extends CarController:
	var home: Vector3 = Vector3.ZERO
	var _t: float = 0.0

	func update(delta: float) -> void:
		_t += delta

	func get_steer() -> float:
		if car == null:
			return 0.0
		var away := car.global_position - home
		away.y = 0.0
		if away.length() > HOME_RADIUS:
			var fwd := -car.global_transform.basis.z
			fwd.y = 0.0
			# rotate_y pozitiv = stanga, acelasi semn ca signed_angle_to pe UP.
			return clampf(fwd.normalized().signed_angle_to(
				-away.normalized(), Vector3.UP) * 1.5, -1.0, 1.0)
		return 0.35 * sin(_t * 0.7)


var _glb: String = ""
var _scale: float = 1.0
var _seconds: float = 12.0

var _world: GlbWorld = null
var _car: Car = null
var _elapsed: float = 0.0
var _frames: int = 0
var _floor_frames: int = 0
var _distance: float = 0.0
var _min_y: float = INF
var _peak_speed: float = 0.0
var _slow_time: float = 0.0
var _max_slow_streak: float = 0.0
var _last_pos: Vector3 = Vector3.ZERO
var _done: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--glb="):
			_glb = arg.trim_prefix("--glb=")
		elif arg.begins_with("--scale="):
			_scale = float(arg.trim_prefix("--scale="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
	if _glb.is_empty():
		push_error("probe_glb_drive: lipseste --glb=<cale sau res://...>")
		get_tree().quit(1)
		return
	_world = GlbWorld.new()
	add_child(_world)
	if not _world.build(_glb, _scale):
		print("VERDICT: PROBLEMA")
		get_tree().quit(1)
		return
	var b := _world.bounds
	print("lume: %d mesh-uri, %d triunghiuri, cutie %.0fx%.0fx%.0f m (y %.1f..%.1f)" % [
		_world.mesh_count, _world.triangle_count,
		b.size.x, b.size.y, b.size.z, b.position.y, b.end.y])


func _physics_process(delta: float) -> void:
	if _done or _world == null:
		return
	if _car == null:
		_spawn_car()
		return
	_elapsed += delta
	_frames += 1
	var pos := _car.global_position
	if _car.is_on_floor():
		_floor_frames += 1
	var step := pos - _last_pos
	step.y = 0.0
	_distance += step.length()
	_last_pos = pos
	_min_y = minf(_min_y, pos.y)
	var speed := _car.horizontal_speed()
	_peak_speed = maxf(_peak_speed, speed)
	# Un blocaj adevarat e o masina care nu mai progreseaza, nu o clipa lenta.
	if _elapsed > 2.0 and speed < 1.0:
		_slow_time += delta
		_max_slow_streak = maxf(_max_slow_streak, _slow_time)
	else:
		_slow_time = 0.0
	if pos.y < _world.bounds.position.y - FALL_MARGIN:
		print("[cadere] t=%.1fs poz=(%.0f,%.1f,%.0f) — sub fundul lumii" % [
			_elapsed, pos.x, pos.y, pos.z])
		_report()
		return
	if _elapsed >= _seconds:
		_report()


## Cauta un loc de pornire plat printr-o grila de raycast-uri: intai centrul,
## apoi inele tot mai largi, primul punct cu normala aproape verticala castiga.
## Ruleaza in _physics_process pentru ca direct_space_state nu exista mai
## devreme — de-asta masina apare abia la al doilea tick.
func _spawn_car() -> void:
	var b := _world.bounds
	var center := b.get_center()
	var spot := Vector3.INF
	for radius: float in [0.0, 8.0, 16.0, 28.0, 44.0]:
		var candidates := 1 if radius == 0.0 else 8
		for i in candidates:
			var ang := TAU * float(i) / float(candidates)
			var hit := _world.ground_hit(center.x + cos(ang) * radius,
				center.z + sin(ang) * radius)
			if not hit.is_empty() and (hit.normal as Vector3).y >= 0.75:
				spot = hit.position
				break
		if spot != Vector3.INF:
			break
	if spot == Vector3.INF:
		push_error("probe_glb_drive: niciun loc de pornire cu normala verticala")
		print("VERDICT: PROBLEMA")
		_done = true
		get_tree().quit(1)
		return
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(load(CAR_DATA) as CarData)
	_car.global_position = spot + Vector3.UP * 1.0
	_car.race_active = true
	var ctrl := WanderController.new()
	ctrl.home = spot
	_car.set_controller(ctrl)
	_last_pos = _car.global_position
	print("pornire: (%.0f, %.1f, %.0f)" % [spot.x, spot.y, spot.z])


func _report() -> void:
	_done = true
	var floor_ratio := float(_floor_frames) / maxf(float(_frames), 1.0)
	var fell := _min_y < _world.bounds.position.y - FALL_MARGIN
	print("\n=== CONDUS PE GLB: %s (scala %.2f) ===" % [_glb.get_file(), _scale])
	print("timp %.1fs · distanta %.0f m · varf %.1f m/s · pe sol %.0f%% · y minim %.1f" % [
		_elapsed, _distance, _peak_speed, floor_ratio * 100.0, _min_y])
	print("cel mai lung blocaj sub 1 m/s: %.1fs" % _max_slow_streak)
	var problems: Array[String] = []
	if fell:
		problems.append("a cazut prin teren")
	if _distance < MIN_DISTANCE:
		problems.append("distanta %.0f m sub pragul de %.0f m" % [_distance, MIN_DISTANCE])
	if floor_ratio < MIN_FLOOR_RATIO:
		problems.append("pe sol doar %.0f%% din timp" % (floor_ratio * 100.0))
	for p in problems:
		print("  ! %s" % p)
	print("VERDICT: %s" % ("PROBLEMA" if not problems.is_empty() else "OK"))
	get_tree().quit(1 if not problems.is_empty() else 0)
