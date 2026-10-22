extends Node
## Capturi pentru efectele de feel (scanteile de razuire, frecare, fumul de
## drift, praful de aterizare, soferul): numaratoarea de emitatori din sonde
## trece si cand pe ecran nu apare nimic, deci aici se ARATA.
##
## Cere FEREASTRA (randarea nu merge headless) si o ruleaza o singura data:
##   godot --fixed-fps 60 --path . res://tools/CaptureFeelVfx.tscn -- --out=C:/tmp/vfx [--only=scrape,rub,drift,land,fist]
##
## Camera e cea din joc (12.5 m in spate, 10 m sus, 28.7 grade, fov 68), cu
## UNA din abateri: nu intarzie in urma masinii, o urmareste rigid. La etapa
## `fist` camera e MAI APROAPE (soferul de la 12.5 m are cativa pixeli), deci
## acolo imaginea nu e vederea de joc. Lumea e o scena minima (sol gri,
## perete, soare), nu o pista: culorile prafului sunt cele de asfalt.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const STEP: float = 1.0 / 60.0

var _out: String = ""
var _only: Array[String] = []
var _cam: Camera3D
var _follow: Car = null
var _cam_offset: Vector3 = Vector3(-12.5, 10.0, 0.0)
var _marks: Node3D
var _shot_n: int = 0


class ScriptDriver:
	extends CarController
	var steer: float = 0.0
	var throttle: float = 0.0
	var drift: bool = false
	func get_steer() -> float:
		return steer
	func get_throttle() -> float:
		return throttle
	func is_drift_pressed() -> bool:
		return drift


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			for s in arg.trim_prefix("--only=").split(","):
				_only.append(s)
	if _out == "":
		_out = OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_build_world()
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("[capture] out=", _out)
	if _only.is_empty() or "scrape" in _only:
		await _stage_scrape()
	if _only.is_empty() or "rub" in _only:
		await _stage_rub()
	if _only.is_empty() or "drift" in _only:
		await _stage_drift()
	if _only.is_empty() or "land" in _only:
		await _stage_land()
	if _only.is_empty() or "fist" in _only:
		await _stage_fist()
	if _only.is_empty() or "props" in _only:
		await _stage_props()
	if _only.is_empty() or "veg" in _only:
		await _stage_veg()
	if _only.is_empty() or "toy" in _only:
		await _stage_toy()
	if _only.is_empty() or "pose" in _only:
		await _stage_pose()
	print("[capture] gata, %d imagini" % _shot_n)
	get_tree().quit(0)


func _process(_delta: float) -> void:
	if _cam == null or _follow == null or not is_instance_valid(_follow):
		return
	var p := _follow.global_position
	_cam.global_position = p + _cam_offset
	_cam.look_at(p + Vector3(4.0, 0.0, 0.0), Vector3.UP)


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.75, 0.9)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.65, 0.72)
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_energy = 1.1
	add_child(sun)
	# Sol: asfalt gri mediu.
	var ground := StaticBody3D.new()
	var gcs := CollisionShape3D.new()
	var gsh := BoxShape3D.new()
	gsh.size = Vector3(1200, 1, 1200)
	gcs.shape = gsh
	ground.add_child(gcs)
	ground.position = Vector3(0, -0.5, 0)
	add_child(ground)
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1200, 1200)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.36, 0.36, 0.38)
	gmat.roughness = 1.0
	plane.material = gmat
	gm.mesh = plane
	add_child(gm)
	# Perete lung la z = -20, fata spre +Z.
	var wall := StaticBody3D.new()
	var wcs := CollisionShape3D.new()
	var wsh := BoxShape3D.new()
	wsh.size = Vector3(600, 3, 1)
	wcs.shape = wsh
	wall.add_child(wcs)
	wall.position = Vector3(0, 1.5, -20.5)
	add_child(wall)
	var wmesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(600, 3, 1)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.78, 0.7, 0.55)
	box.material = wmat
	wmesh.mesh = box
	wall.add_child(wmesh)
	_marks = Node3D.new()
	_marks.name = "Marks"
	add_child(_marks)
	_cam = Camera3D.new()
	_cam.fov = 68.0
	_cam.far = 400.0
	add_child(_cam)
	_cam.current = true


func _spawn(pos: Vector3, yaw: float, data_index: int = 0) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[data_index])
	car.global_position = pos
	car.rotation.y = yaw
	car.skid_parent = _marks
	car.race_active = true
	return car


func _wait(seconds: float) -> void:
	for _f in int(seconds / STEP):
		await get_tree().physics_frame


func _settle(cars: Array) -> void:
	await _wait(0.8)
	for c in cars:
		(c as Car).linear_velocity = Vector3.ZERO
		(c as Car).angular_velocity = Vector3.ZERO


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [_out, name]
	img.save_png(path)
	_shot_n += 1
	print("[capture] ", path)


## Yaw-ul unei masini cu botul pe directia `dir` (orizontala).
func _yaw_for(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)


func _stage_scrape() -> void:
	print("[capture] -- scrape (razuire lunga) si rafala la izbitura")
	_cam_offset = Vector3(-12.5, 10.0, 0.0)
	# 1. Razuire: 6 grade, cu gaz, ca sa tina viteza pe perete.
	var dir := Vector3(cos(deg_to_rad(6.0)), 0, -sin(deg_to_rad(6.0)))
	var car := _spawn(Vector3(-90, 0.7, -17.4), _yaw_for(dir))
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	_follow = car
	await _settle([car])
	car.rotation.y = _yaw_for(dir)
	car.linear_velocity = dir * 26.0
	drv.throttle = 1.0
	var f := 0
	while not (car.wall_contact and car.wall_scrape_speed > 9.0) and f < 300:
		await get_tree().physics_frame
		f += 1
	print("[capture] contact dupa %d cadre: v=%.1f raz=%.1f" % [f, car.horizontal_speed(), car.wall_scrape_speed])
	await _wait(0.05)
	print("[capture] raz=%.1f scrape emite=%s la %s" % [car.wall_scrape_speed,
		car._scrape_sparks.emitting, car._scrape_sparks.global_position])
	await _shot("scrape_1")
	await _wait(0.12)
	await _shot("scrape_2")
	await _wait(0.2)
	print("[capture] raz=%.1f scrape emite=%s" % [car.wall_scrape_speed, car._scrape_sparks.emitting])
	await _shot("scrape_3")
	car.queue_free()
	_follow = null
	await get_tree().physics_frame
	# 2. Izbitura mai frontala: rafala.
	var dir2 := Vector3(cos(deg_to_rad(40.0)), 0, -sin(deg_to_rad(40.0)))
	var c2 := _spawn(Vector3(-100, 0.7, -8.0), _yaw_for(dir2))
	_follow = c2
	await _settle([c2])
	c2.rotation.y = _yaw_for(dir2)
	var hit: Array[float] = [0.0]
	c2.impact.connect(func(_c, k, s, _n, _p, _o) -> void:
		if k == &"wall" and hit[0] == 0.0:
			hit[0] = s)
	c2.linear_velocity = dir2 * 22.0
	f = 0
	while hit[0] == 0.0 and f < 300:
		await get_tree().physics_frame
		f += 1
	print("[capture] izbitura %.1f m/s, rafala emite=%s la %s (masina la %s)" % [
		hit[0], c2._sparks.emitting, c2._sparks.global_position, c2.global_position])
	await _wait(0.05)
	await _shot("burst_1")
	await _wait(0.1)
	await _shot("burst_2")
	c2.queue_free()
	_follow = null
	await get_tree().physics_frame


func _stage_rub() -> void:
	print("[capture] -- rub")
	_cam_offset = Vector3(-12.5, 10.0, 0.0)
	var a := _spawn(Vector3(0, 0.7, 40), -PI * 0.5)
	var b := _spawn(Vector3(3.0, 0.7, 37.9), -PI * 0.5, 2)
	_follow = a
	await _settle([a, b])
	a.linear_velocity = Vector3(17.0, 0, -1.0)
	b.linear_velocity = Vector3(7.0, 0, 0)
	var f := 0
	var shots := 0
	var shots_gap := 99
	while f < 90 and shots < 4:
		if f < 80:
			a.apply_central_force(Vector3(0, 0, -16.0 * a.mass))
			b.apply_central_force(Vector3(2.0 * b.mass, 0, 0))
		await get_tree().physics_frame
		f += 1
		shots_gap += 1
		if f % 10 == 0:
			print("[capture] rub f=%d rub_car=%s rub_speed=%.1f va=%.1f vb=%.1f dz=%.2f" % [
				f, a.rub_car != null, a.rub_speed, a.horizontal_speed(),
				b.horizontal_speed(), a.global_position.z - b.global_position.z])
		if a.rub_car == b and a.rub_speed > 3.0 and shots_gap >= 5:
			print("[capture] frecare: viteza %.1f, emite A=%s B=%s" % [
				a.rub_speed, a._scrape_sparks.emitting, b._scrape_sparks.emitting])
			shots += 1
			shots_gap = 0
			await _shot("rub_%d" % shots)
	a.queue_free()
	b.queue_free()
	_follow = null
	await get_tree().physics_frame


func _stage_drift() -> void:
	print("[capture] -- drift")
	_cam_offset = Vector3(-12.5, 10.0, 0.0)
	var car := _spawn(Vector3(-200, 0.7, 150), -PI * 0.5)
	var drv := ScriptDriver.new()
	car.set_controller(drv)
	_follow = car
	await _settle([car])
	drv.throttle = 1.0
	await _wait(3.5)
	drv.steer = 1.0
	drv.drift = true
	var got_low := false
	var got_high := false
	for _f in int(4.0 / STEP):
		await get_tree().physics_frame
		if not got_low and car.is_drifting and car.slip_angle_deg >= 14.0 and car.slip_angle_deg < 22.0:
			got_low = true
			print("[capture] drift usor: unghi %.1f, alunecare %.2f, pufuri %.2f" % [
				car.slip_angle_deg, car.slide_amount, (car._drift_density as Gradient).get_offset(1)])
			await _shot("drift_1_low")
		elif got_low and not got_high and car.is_drifting and car.slip_angle_deg >= 28.0:
			got_high = true
			print("[capture] drift plin: unghi %.1f, alunecare %.2f, pufuri %.2f" % [
				car.slip_angle_deg, car.slide_amount, (car._drift_density as Gradient).get_offset(1)])
			await _shot("drift_2_high")
			await _wait(0.4)
			await _shot("drift_3_high_later")
			break
	car.queue_free()
	_follow = null
	await get_tree().physics_frame


func _stage_land() -> void:
	print("[capture] -- land")
	_cam_offset = Vector3(-12.5, 10.0, 0.0)
	var car := _spawn(Vector3(-200, 5.5, -150), -PI * 0.5)
	_follow = car
	var landed: Array[float] = []
	car.landed.connect(func(_c, v: float) -> void: landed.append(v))
	var f := 0
	while landed.is_empty() and f < 240:
		await get_tree().physics_frame
		f += 1
	print("[capture] aterizare la %s m/s" % [landed])
	await _wait(0.12)
	await _shot("land_1")
	await _wait(0.3)
	await _shot("land_2")
	car.queue_free()
	_follow = null
	await get_tree().physics_frame


func _stage_fist() -> void:
	print("[capture] -- fist (camera aproape, NU vederea de joc)")
	_cam_offset = Vector3(-6.0, 3.2, 2.6)
	var a := _spawn(Vector3(300, 0.7, 100), -PI * 0.5, 5)
	var b := _spawn(Vector3(300, 0.7, 109), 0.0, 1)
	_follow = a
	await _settle([a, b])
	var hit: Array[int] = [0]
	a.impact.connect(func(_c, k, _s, _n, _p, _o) -> void:
		if k == &"car" and hit[0] == 0:
			hit[0] = 1)
	b.linear_velocity = Vector3(0, 0, -12)
	var f := 0
	while hit[0] == 0 and f < 240:
		await get_tree().physics_frame
		f += 1
	await _shot("fist_0_impact")
	await _wait(0.12)
	await _shot("fist_1")
	await _wait(0.2)
	await _shot("fist_2")
	await _wait(0.2)
	await _shot("fist_3")
	a.queue_free()
	b.queue_free()
	_follow = null


## Pozele soferului, de aproape si din lateral (dreapta masinii), fortate:
## repaus, brate in aer (pozitia veche, de referinta), pumn la varf.
func _stage_pose() -> void:
	print("[capture] -- pose (camera aproape, din dreapta)")
	var car := _spawn(Vector3(-300, 0.7, -300), -PI * 0.5, 5)
	_follow = null
	await _settle([car])
	# Camera din dreapta masinii (+Z), priveste spre sofer.
	var seat: Vector3 = car._driver.global_position
	_cam.global_position = seat + Vector3(0.6, 0.9, 3.4)
	_cam.look_at(seat + Vector3(0.0, 0.25, 0.0), Vector3.UP)
	var drv: Driver = car._driver
	car.set_physics_process(false) # pozele le fortam noi
	drv.set_physics_process(false)
	var poses := {"rest": [-1.0, 0.0], "air": [-1.0, 1.0], "fist": [0.3, 0.0]}
	for key in poses.keys():
		drv._fist_t = poses[key][0]
		drv._arms_up = poses[key][1]
		drv._fist_side = 1.0
		drv._fist_yaw = -0.9
		# Doua tick-uri de pose, cu pasii facuti de mana (fizica e oprita).
		for _i in 3:
			drv._clock += STEP
			var extra_dt := 0.0
			drv._physics_process(STEP)
			drv._fist_t = poses[key][0]
			drv._arms_up = poses[key][1]
			extra_dt += 1.0
		await get_tree().process_frame
		await _shot("pose_" + key)
	car.queue_free()


## Butoaie knockable lovite la viteza de cursa: aschii si praf, camera de joc.
func _stage_props() -> void:
	print("[capture] -- props (camera de joc)")
	_cam_offset = Vector3(-12.5, 10.0, 0.0)
	var car := _spawn(Vector3(-380, 0.7, 250), -PI * 0.5)
	_follow = car
	var holder := Node3D.new()
	add_child(holder)
	for i in 5:
		var b := Barrel.new()
		holder.add_child(b)
		b.global_position = Vector3(-352 + i * 0.5, 0, 250 + (i - 2) * 0.85)
	await _settle([car])
	car.linear_velocity = Vector3(24, 0, 0)
	var f := 0
	var m: Variant = load("res://scenes/props/prop_debris.gd").instance()
	var b0: int = int(m.bursts)
	while int(m.bursts) == b0 and f < 300:
		await get_tree().physics_frame
		f += 1
	print("[capture] primul contact dupa %d cadre, forta %.1f" % [f, m.last_strength])
	await _wait(0.06)
	await _shot("props_1")
	await _wait(0.14)
	await _shot("props_2")
	await _wait(0.2)
	await _shot("props_3")
	car.queue_free()
	holder.queue_free()
	_follow = null


## Citirea REALA a tufelor dintr-o pista (Track01) si frunzele la trecere.
## Doar cu fereastra: headless MultiMesh da pozitii zero.
func _stage_veg() -> void:
	print("[capture] -- veg (Track01, citire reala de chunk-uri)")
	var SoftVeg := load("res://scenes/props/soft_vegetation.gd")
	var t := (load("res://scenes/tracks/Track01.tscn") as PackedScene).instantiate() as Track
	add_child(t)
	for _i in 4:
		await get_tree().process_frame
	var n: int = SoftVeg.scan(t)
	print("[capture] tufe citite din Track01: %d" % n)
	if n == 0:
		return
	# Prima tufa de langa un loc plat: masina vine spre ea pe directia +X.
	var e: Dictionary = SoftVeg._cache[t.get_instance_id()]
	var pick := Vector3.ZERO
	for cell in e["cells"].keys():
		var arr: PackedFloat32Array = e["cells"][cell]
		pick = Vector3(arr[0], arr[1], arr[2])
		break
	print("[capture] tufa aleasa la %s" % pick)
	var car := _spawn(pick + Vector3(-14.0, 1.5, 0.0), -PI * 0.5)
	car.soft_veg_root = t
	_follow = car
	_cam_offset = Vector3(-12.5, 10.0, 0.0)
	await _wait(0.9)
	car.linear_velocity = Vector3(26, 0, 0)
	var m: Variant = load("res://scenes/props/prop_debris.gd").instance()
	var l0: int = int(m.leaf_bursts) if m != null else 0
	var f := 0
	while (m == null or int(m.leaf_bursts) == l0) and f < 200:
		await get_tree().physics_frame
		m = load("res://scenes/props/prop_debris.gd").instance()
		f += 1
	print("[capture] frunze dupa %d cadre, depth %.2f" % [f, car._veg_depth])
	await _wait(0.08)
	await _shot("veg_1")
	await _wait(0.15)
	await _shot("veg_2")
	car.queue_free()
	t.queue_free()
	_follow = null


## Antena si cheia pe mai multe masini, din spate-dreapta, de aproape; apoi o
## franare cu antena aplecata (camera de joc).
func _stage_toy() -> void:
	print("[capture] -- toy (camera aproape, din spate-dreapta)")
	_follow = null
	var i := 0
	for idx in [0, 2, 3, 4, 5]:
		var car := _spawn(Vector3(500 + i * 20, 0.7, 500), -PI * 0.5, idx)
		await _settle([car])
		var c := car.global_position + Vector3(0, 0.9, 0)
		_cam.global_position = c + Vector3(-3.6, 1.8, 2.6)
		_cam.look_at(c, Vector3.UP)
		await get_tree().process_frame
		await _shot("toy_%d" % idx)
		_cam.global_position = c + Vector3(-3.4, 0.5, 0.0)
		_cam.look_at(c + Vector3(0, -0.1, 0), Vector3.UP)
		await get_tree().process_frame
		await _shot("toyrear_%d" % idx)
		car.queue_free()
		i += 1
		await get_tree().physics_frame
	# Franare: antena inainte.
	_cam_offset = Vector3(-7.0, 3.0, 4.5)
	var car2 := _spawn(Vector3(300, 0.7, -300), -PI * 0.5, 0)
	var drv := ScriptDriver.new()
	car2.set_controller(drv)
	_follow = car2
	await _settle([car2])
	drv.throttle = 1.0
	await _wait(3.0)
	drv.throttle = -1.0
	await _wait(0.25)
	await _shot("toy_brake_1")
	await _wait(0.2)
	await _shot("toy_brake_2")
	car2.queue_free()
	_follow = null
