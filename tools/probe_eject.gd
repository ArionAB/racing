extends Node
## Sonda prototipului „sofer + ragdoll" (buggy-ul deschis).
##
## Verifica REGULILE, nu senzatia (aia e a dezvoltatorului, la volan):
##   1. izbitura frontala de perete la viteza de cursa arunca soferul: semnal
##      `ejected` o singura data, ragdoll cu 7 corpuri care chiar zboara
##      (trunchiul se departeaza de masina), soferul asezat dispare;
##   2. NICIUN corp al ragdoll-ului nu atinge vreo masina (regula 1 din
##      ToyRagdoll) — masurat pe toate cadrele simularii;
##   3. dupa `eject_hold` soferul e inapoi pe scaun (fara pista nu exista
##      repunere, deci se reaseaza direct);
##   4. atingerea unui perete la viteza mica NU arunca (pragul e prag);
##   5. caderea de la inaltime arunca; saritura normala nu.
##
## Ruleaza CA SCENA (are nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeEject.tscn
## Cu fereastra, salveaza si o captura a momentului in snapshots/eject_probe.png:
##   godot --fixed-fps 60 --path . res://tools/ProbeEject.tscn -- --capture

const STEP: float = 1.0 / 60.0
const BUGGY: CarData = preload("res://scenes/cars/data/buggy.tres")
const WALL_Z: float = -70.0

var _failed: bool = false
var _ejections: int = 0
var _last_ragdoll: ToyRagdoll
var _capture: bool = false
var _cam: Camera3D
## Scrise de lambda-uri: MEMBRI, nu locale (lambda captureaza prin valoare).
var _hits: int = 0
var _landed_speed: float = 0.0


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return false
	func is_turbo_pressed() -> bool:
		return false


func _ready() -> void:
	_capture = "--capture" in OS.get_cmdline_user_args()
	_build_world()
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("")
	print("=== Sofer + ragdoll (buggy) ===")
	await _test_wall_eject()
	await _test_soft_wall()
	await _test_landing(16.0, true)
	await _test_landing(5.0, false)
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)


func _build_world() -> void:
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(400, 1, 400)
	gs.shape = gb
	ground.add_child(gs)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	var wall := StaticBody3D.new()
	var ws := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	# Bariera de pista (1,3 m), nu zid: figurina trebuie sa poata zbura PESTE.
	wb.size = Vector3(40, 1.3, 1)
	ws.shape = wb
	wall.add_child(ws)
	add_child(wall)
	wall.global_position = Vector3(0, 0.65, WALL_Z)
	if _capture:
		var gm := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(400, 400)
		gm.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.62, 0.45)
		gm.material_override = mat
		add_child(gm)
		var wm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = wb.size
		wm.mesh = bm
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.5, 0.5, 0.52)
		wm.material_override = wmat
		wall.add_child(wm)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-48, 35, 0)
		sun.shadow_enabled = true
		add_child(sun)
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.62, 0.74, 0.88)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.7, 0.72, 0.78)
		e.ambient_light_energy = 0.9
		env.environment = e
		add_child(env)
		_cam = Camera3D.new()
		_cam.fov = 60.0
		add_child(_cam)
		_cam.current = true


func _spawn(pos: Vector3, throttle: float) -> Car:
	var car := Car.new()
	add_child(car)
	car.apply_data(BUGGY)
	car.global_position = pos
	car.race_active = true
	var drv := ScriptDriver.new()
	drv.throttle = throttle
	car.set_controller(drv)
	car.ejected.connect(func(_c: Car, rag: Node3D) -> void:
		_ejections += 1
		_last_ragdoll = rag as ToyRagdoll)
	return car


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


## Cadre de fizica, cu urmarirea contactelor ragdoll <-> masina.
func _run(frames: int, car: Car) -> int:
	var touches := 0
	for _f in frames:
		await get_tree().physics_frame
		if is_instance_valid(_last_ragdoll):
			for body in _last_ragdoll.bodies():
				for hit in body.get_colliding_bodies():
					if hit is Car:
						touches += 1
	return touches


func _test_wall_eject() -> void:
	print("-- perete frontal la viteza de cursa")
	_ejections = 0
	_last_ragdoll = null
	var car := _spawn(Vector3(0, 0, 0), 1.0)
	_check(car.driver_seated(), "soferul e pe scaun la start")
	# Viteza MAXIMA vazuta = viteza de impact: in cadrul izbiturii solverul a
	# schimbat deja viteza cand sonda se trezeste, deci „ultima citita" minte.
	var impact_speed := 0.0
	var frames := 0
	while _ejections == 0 and frames < 8 * 60:
		impact_speed = maxf(impact_speed, car.horizontal_speed())
		await get_tree().physics_frame
		frames += 1
	_check(_ejections == 1, "o singura ejectare la impact (viteza %.1f m/s)" % impact_speed)
	if _ejections != 1:
		car.queue_free()
		return
	_check(not car.driver_seated(), "soferul asezat a disparut")
	_check(car.is_ejected and car._eject_left > 0.0, "masina e in fereastra fara sofer")
	var bodies := _last_ragdoll.bodies()
	_check(bodies.size() == 7, "ragdoll cu 7 corpuri (%d)" % bodies.size())
	var start := _last_ragdoll.focus_node().global_position
	var touches := await _run(int(0.5 / STEP), car)
	var torso := _last_ragdoll.focus_node().global_position
	var flown := torso.distance_to(start)
	_check(flown > 3.0, "trunchiul a zburat %.2f m in 0,5 s" % flown)
	_check(torso.z < WALL_Z - 0.5, "figurina a trecut PESTE bariera (z=%.1f)" % torso.z)
	_check(torso.y > -0.5, "figurina n-a cazut prin sol (y=%.2f)" % torso.y)
	_check(touches == 0, "niciun contact ragdoll <-> masina (%d)" % touches)
	if _capture:
		await _capture_frame(car, torso)
	# Dupa fereastra: soferul inapoi (fara pista nu e repunere, se reaseaza).
	touches = await _run(int((car.eject_hold + 0.3) / STEP), car)
	_check(touches == 0, "niciun contact nici pana la reasezare (%d)" % touches)
	_check(car.driver_seated() and not car.is_ejected,
		"soferul e inapoi pe scaun dupa %.1f s" % car.eject_hold)
	_check(_ejections == 1, "nicio a doua ejectare din acelasi impact")
	car.queue_free()
	await get_tree().physics_frame


func _test_soft_wall() -> void:
	print("-- atingere de perete la viteza mica")
	_ejections = 0
	var car := _spawn(Vector3(6, 0, 0), 1.0)
	car.max_speed = 9.0
	_hits = 0
	car.wall_hit.connect(func(_c: Car, _i: float) -> void: _hits += 1)
	for _f in 12 * 60:
		await get_tree().physics_frame
		if _hits > 0:
			break
	await _run(30, car)
	_check(_hits > 0, "peretele a fost atins (%d)" % _hits)
	_check(_ejections == 0, "fara ejectare sub prag")
	_check(car.driver_seated(), "soferul a ramas pe scaun")
	car.queue_free()
	await get_tree().physics_frame


func _test_landing(height: float, expect: bool) -> void:
	print("-- cadere de la %.0f m (%s)" % [height, "arunca" if expect else "nu arunca"])
	_ejections = 0
	_last_ragdoll = null
	var car := _spawn(Vector3(-30, height, 20), 0.0)
	_landed_speed = 0.0
	car.landed.connect(func(_c: Car, fall: float) -> void: _landed_speed = fall)
	for _f in 4 * 60:
		await get_tree().physics_frame
		if _landed_speed > 0.0:
			break
	await _run(20, car)
	_check(_landed_speed > 0.0, "a aterizat cu %.1f m/s" % _landed_speed)
	_check((_ejections == 1) == expect, "ejectare: %d (asteptat %s)" % [
		_ejections, "1" if expect else "0"])
	if is_instance_valid(_last_ragdoll):
		await _run(int(0.4 / STEP), car)
		_check(_last_ragdoll.focus_node().global_position.y > 0.3,
			"figurina e deasupra solului dupa aruncare")
	car.queue_free()
	await get_tree().physics_frame


func _capture_frame(car: Car, torso: Vector3) -> void:
	# Camera din spatele masinii, putin de sus, ca in joc.
	var back := car.global_position + Vector3(0, 5.0, 11.0)
	_cam.global_position = back
	_cam.look_at((car.global_position + torso) * 0.5 + Vector3.UP * 0.5)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "res://snapshots/eject_probe.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://snapshots"))
	var err := img.save_png(path)
	print("  captura: %s (%s)" % [path, "ok" if err == OK else str(err)])
