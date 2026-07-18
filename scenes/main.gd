extends Node3D
## Scena spike-ului: mediu, pista, cursa cu 3 AI, chase cam, HUD.
## Totul construit in cod — e un prototip de masura, nu produs.

const TOTAL_LAPS: int = 3

## Presetari de masini (stiluri distincte, ca garajul din Ignition).
## Tastele 1/2/3 schimba masina jucatorului.
const PRESETS: Array[Dictionary] = [
	{"name": "Vipera", "max_speed": 37.0, "accel": 15.0, "grip": 7.0,
		"mass": 1.0, "color": Color(0.95, 0.25, 0.15)},
	{"name": "Buldog", "max_speed": 32.0, "accel": 13.0, "grip": 9.0,
		"mass": 1.8, "color": Color(0.2, 0.45, 0.9)},
	{"name": "Purice", "max_speed": 30.0, "accel": 19.0, "grip": 12.0,
		"mass": 0.7, "color": Color(0.95, 0.85, 0.2)},
]
const AI_COLORS: Array[Color] = [
	Color(0.3, 0.8, 0.4), Color(0.8, 0.4, 0.9), Color(0.9, 0.6, 0.3)]

var car: SpikeCar # masina jucatorului (numele e folosit si de sonde)
var cars: Array[SpikeCar] = []
var track: Track3D
var camera: ChaseCamera

var _hud: Label
var _progress: Array[Dictionary] = []
var _lap_start_ms: int = -1
var _best_lap_ms: int = -1
var _finish_text: String = ""

func _ready() -> void:
	_build_environment()
	track = Track3D.new()
	add_child(track)
	_spawn_cars()
	camera = ChaseCamera.new()
	add_child(camera)
	camera.target = car
	camera.snap_behind()
	_build_hazard()
	_build_hud()

func _spawn_cars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var spawns := track.spawn_transforms(4)
	for i in 4:
		var c := SpikeCar.new()
		c.track = track
		add_child(c)
		c.global_transform = spawns[i]
		c.start_transform = spawns[i]
		c.road_index = track.closest_index_global(c.global_position)
		if i == 0:
			car = c
			c.is_player = true
			c.apply_preset(PRESETS[0])
		else:
			c.is_player = false
			var preset: Dictionary = PRESETS[i % PRESETS.size()].duplicate()
			preset.color = AI_COLORS[(i - 1) % AI_COLORS.size()]
			c.apply_preset(preset)
			c.ai_line = rng.randf_range(-0.35, 0.35)
			c.ai_speed_factor = rng.randf_range(0.88, 0.97)
		cars.append(c)
		var frac := track.frac_at(c.road_index)
		_progress.append({
			"frac": frac,
			"total": frac - 1.0 if frac > 0.5 else frac,
			"laps": 0,
		})

func _build_hazard() -> void:
	# Bariera mobila pe segmentul dintre chicane si al doilea deal.
	var idx := int(0.58 * float(track.baked.size()))
	var hazard := SlidingHazard.new()
	add_child(hazard)
	var p := track.baked[idx]
	var n := track.baked.size()
	var dir := (track.baked[(idx + 1) % n] - p).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	hazard.center = p
	hazard.travel = side * Track3D.HALF_WIDTH * 0.9
	hazard.global_position = p

func _physics_process(_delta: float) -> void:
	for i in cars.size():
		var c := cars[i]
		if c.global_position.y < -12.0:
			c.reset()
		# progres continuu (tururi + fractie), cu corectie la trecerea de start
		var st := _progress[i]
		var frac := track.frac_at(c.road_index)
		var d := frac - float(st.frac)
		if d < -0.5:
			d += 1.0
		elif d > 0.5:
			d -= 1.0
		st.frac = frac
		st.total = float(st.total) + d
		var laps := int(floor(float(st.total)))
		if laps > int(st.laps):
			st.laps = laps
			if c == car:
				_on_player_lap(laps)
	_update_hud()

func _on_player_lap(laps: int) -> void:
	var now := Time.get_ticks_msec()
	if _lap_start_ms >= 0:
		var lap_ms := now - _lap_start_ms
		if _best_lap_ms < 0 or lap_ms < _best_lap_ms:
			_best_lap_ms = lap_ms
	_lap_start_ms = now
	if laps >= TOTAL_LAPS and _finish_text == "":
		_finish_text = "FINISH — locul %d!" % _player_position()

func _player_position() -> int:
	var player_total := float(_progress[0].total)
	var pos := 1
	for i in range(1, cars.size()):
		if float(_progress[i].total) > player_total:
			pos += 1
	return pos

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

# --------------------------------------------------------------------- HUD

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1: car.apply_preset(PRESETS[0])
		KEY_2: car.apply_preset(PRESETS[1])
		KEY_3: car.apply_preset(PRESETS[2])

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(20, 14)
	_hud.add_theme_font_size_override("font_size", 24)
	_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud)

func _update_hud() -> void:
	var kmh := car.horizontal_speed() * 3.6
	var lap_text := "--:--.-"
	if _lap_start_ms >= 0:
		lap_text = _fmt_ms(Time.get_ticks_msec() - _lap_start_ms)
	var best_text := _fmt_ms(_best_lap_ms) if _best_lap_ms >= 0 else "--:--.-"
	var lap_no := clampi(int(_progress[0].laps) + 1, 1, TOTAL_LAPS)
	var line := "%3.0f km/h   loc %d/%d   tur %d/%d\ntur:  %s\nbest: %s\n%s   [1/2/3] masina   [R] reset" % [
		kmh, _player_position(), cars.size(), lap_no, TOTAL_LAPS,
		lap_text, best_text, car.car_name]
	if _finish_text != "":
		line = _finish_text + "\n" + line
	_hud.text = line

func _fmt_ms(ms: int) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000, (ms % 1000) / 100]
