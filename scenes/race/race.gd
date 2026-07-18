class_name Race
extends Node3D
## Orchestreaza o cursa: mediu, pista, masini (player + AI), countdown cu
## rocket start, progres/tururi/pozitii, HUD. Portat din racing 2D.

const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/Track01.tscn")
const CAR_SCENE: PackedScene = preload("res://scenes/cars/Car.tscn")
const CAR_DATA: Array[Resource] = [
	preload("res://scenes/cars/data/vipera.tres"),
	preload("res://scenes/cars/data/buldog.tres"),
	preload("res://scenes/cars/data/purice.tres"),
]
const AI_COLORS: Array[Color] = [
	Color(0.3, 0.8, 0.4), Color(0.8, 0.4, 0.9), Color(0.9, 0.6, 0.3)]

enum State { COUNTDOWN, RUNNING, FINISHED }

var state: State = State.COUNTDOWN
var track: Track
var player: Car
var cars: Array[Car] = []
var camera: ChaseCamera
var hud: RaceHUD

var _progress: Array[Dictionary] = []
var _countdown_left: float = 3.6
var _last_beep: int = -1
var _skid_parent: Node3D
var _drift_hold: Dictionary = {} # Car -> secunde de drift tinut la start
var _lap_start_ms: int = -1
var _best_lap_ms: int = -1
var _finish_text: String = ""
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_build_environment()
	track = TRACK_SCENE.instantiate() as Track
	add_child(track)
	_skid_parent = Node3D.new()
	_skid_parent.name = "SkidMarks"
	add_child(_skid_parent)
	_spawn_cars()
	camera = ChaseCamera.new()
	add_child(camera)
	camera.target = player
	camera.snap_behind()
	hud = RaceHUD.new()
	add_child(hud)
	hud.restart_requested.connect(GameState.start_race)
	hud.menu_requested.connect(GameState.go_to_menu)
	hud.show_countdown("READY?")
	# Juice: camera reactioneaza la evenimentele jucatorului.
	player.wall_hit.connect(func(_c: Car, impact: float) -> void:
		camera.add_trauma(clampf(impact / 45.0, 0.15, 0.5)))
	player.landed.connect(func(_c: Car, fall: float) -> void:
		camera.add_trauma(clampf(fall / 30.0, 0.1, 0.35)))
	player.boost_started.connect(func(_c: Car) -> void:
		camera.add_trauma(0.18))

func _spawn_cars() -> void:
	var count := GameState.ai_count + 1
	var spawns := track.spawn_transforms(count)
	for i in count:
		var car := CAR_SCENE.instantiate() as Car
		car.track = track
		add_child(car)
		car.global_transform = spawns[i]
		car.start_transform = spawns[i]
		car.road_index = track.closest_index_global(car.global_position)
		car.skid_parent = _skid_parent
		if i == 0:
			player = car
			car.is_player = true
			car.apply_data(CAR_DATA[0] as CarData)
			car.set_controller(PlayerController.new())
		else:
			car.apply_data(CAR_DATA[i % CAR_DATA.size()] as CarData,
				AI_COLORS[(i - 1) % AI_COLORS.size()])
			var ai := AIController.new()
			car.set_controller(ai)
			ai.configure(track, _rng)
			# Variatie onesta, nu viteza trisata.
			car.speed_scale = _rng.randf_range(0.88, 0.97)
		cars.append(car)
		var frac := track.frac_at(car.road_index)
		_progress.append({
			"frac": frac,
			"total": frac - 1.0 if frac > 0.5 else frac,
			"laps": 0,
		})

func _physics_process(delta: float) -> void:
	if state == State.COUNTDOWN:
		_tick_countdown(delta)
	else:
		_tick_race()
	_update_hud()

# -------------------------------------------------------------- countdown

func _tick_countdown(delta: float) -> void:
	_countdown_left -= delta
	# Rocket start: masuram cat tine fiecare "creier" TURBO apasat.
	for car in cars:
		if car.controller != null and car.controller.is_turbo_pressed():
			_drift_hold[car] = float(_drift_hold.get(car, 0.0)) + delta
		else:
			_drift_hold[car] = 0.0
	if _countdown_left > 3.0:
		return
	if _countdown_left > 0.0:
		var number := ceili(_countdown_left)
		hud.show_countdown(str(number))
		if number != _last_beep:
			_last_beep = number
			AudioManager.play_sfx(&"count_beep")
		return
	_go()

func _go() -> void:
	state = State.RUNNING
	hud.show_countdown("GO!")
	AudioManager.play_sfx(&"go_beep")
	get_tree().create_timer(0.7, false).timeout.connect(
		func() -> void: hud.show_countdown(""))
	_lap_start_ms = Time.get_ticks_msec()
	for car in cars:
		car.race_active = true
		var hold := float(_drift_hold.get(car, 0.0))
		if car == player:
			if hold > 0.05 and hold <= 1.05:
				car.force_boost(1.2)
				hud.flash_message("ROCKET START!")
			elif hold > 1.05:
				hud.flash_message("Prea devreme...")
		elif _rng.randf() < 0.45:
			car.force_boost(0.8)

# ------------------------------------------------------------------ cursa

func _tick_race() -> void:
	for i in cars.size():
		var car := cars[i]
		if car.global_position.y < -12.0:
			car.reset()
		var st := _progress[i]
		var frac := track.frac_at(car.road_index)
		var d := frac - float(st.frac)
		if d < -0.5:
			d += 1.0
		elif d > 0.5:
			d -= 1.0
		st.frac = frac
		if not car.finished:
			st.total = float(st.total) + d
		var laps := int(floor(float(st.total)))
		if laps > int(st.laps):
			st.laps = laps
			if car == player:
				_on_player_lap(laps)
			if laps >= GameState.total_laps and not car.finished:
				car.finished = true
	_update_positions()

func _on_player_lap(laps: int) -> void:
	var now := Time.get_ticks_msec()
	if _lap_start_ms >= 0:
		var lap_ms := now - _lap_start_ms
		if _best_lap_ms < 0 or lap_ms < _best_lap_ms:
			_best_lap_ms = lap_ms
	_lap_start_ms = now
	if laps >= GameState.total_laps and _finish_text == "":
		state = State.FINISHED
		_finish_text = "FINISH — locul %d!" % player.race_position
		hud.flash_message(_finish_text)

func _update_positions() -> void:
	var order := range(cars.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return float(_progress[a].total) > float(_progress[b].total))
	for rank in cars.size():
		cars[order[rank]].race_position = rank + 1

# -------------------------------------------------------------------- HUD

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: player.apply_data(CAR_DATA[0] as CarData)
		KEY_2: player.apply_data(CAR_DATA[1] as CarData)
		KEY_3: player.apply_data(CAR_DATA[2] as CarData)

func _update_hud() -> void:
	var lap_text := "--:--.-"
	if _lap_start_ms >= 0 and state != State.COUNTDOWN:
		lap_text = _fmt_ms(Time.get_ticks_msec() - _lap_start_ms)
	var best_text := _fmt_ms(_best_lap_ms) if _best_lap_ms >= 0 else "--:--.-"
	var lap_no := clampi(int(_progress[0].laps) + 1, 1, GameState.total_laps)
	var info := "%3.0f km/h   loc %d/%d   tur %d/%d\ntur:  %s\nbest: %s\n%s   [SPACE] turbo  [SHIFT] drift  [1/2/3] masina  [R] reset" % [
		player.horizontal_speed() * 3.6, player.race_position, cars.size(),
		lap_no, GameState.total_laps, lap_text, best_text, player.car_name]
	if _finish_text != "":
		info = _finish_text + "\n" + info
	hud.set_info(info)
	hud.set_turbo(player.turbo_charge, player.is_boosting)

func _fmt_ms(ms: int) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000, (ms % 1000) / 100]

# ------------------------------------------------------------------- mediu

func _build_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.85, 0.95)
	env.fog_density = 0.004
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2000, 2000)
	ground.mesh = plane
	ground.position = Vector3(60, -0.3, -100)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.27)
	ground.material_override = mat
	add_child(ground)
	var ground_body := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(2000, 1, 2000)
	ground_shape.shape = ground_box
	ground_shape.position = Vector3(60, -0.8, -100)
	ground_body.add_child(ground_shape)
	add_child(ground_body)
