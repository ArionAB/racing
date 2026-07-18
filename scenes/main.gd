extends Node3D
## Scena spike-ului: mediu, pista, masina, chase cam, cronometru de tur.
## Totul construit in cod — e un prototip de masura, nu produs.

var car: SpikeCar
var track: Track3D
var camera: ChaseCamera

var _hud: Label
var _lap_start_ms: int = -1
var _best_lap_ms: int = -1
var _lap_cooldown: float = 0.0

func _ready() -> void:
	_build_environment()
	track = Track3D.new()
	add_child(track)

	car = SpikeCar.new()
	add_child(car)
	var dir := track.start_direction()
	car.global_position = track.start_point() + Vector3.UP * 0.5 - dir * 6.0
	# looking_at orienteaza -Z (fata masinii) spre directia de mers.
	car.global_basis = Basis.looking_at(dir, Vector3.UP)
	car.start_transform = car.global_transform

	camera = ChaseCamera.new()
	add_child(camera)
	camera.target = car
	camera.snap_behind()

	_build_lap_trigger()
	_build_hud()

func _physics_process(delta: float) -> void:
	_lap_cooldown = maxf(_lap_cooldown - delta, 0.0)
	if car.global_position.y < -12.0:
		car.reset() # a cazut de pe lume
	_update_hud()

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

	# "Iarba": un plan urias sub tot.
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

# ------------------------------------------------------------------ tururi

func _build_lap_trigger() -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(Track3D.HALF_WIDTH * 2.0, 6.0, 2.0)
	shape.shape = box
	area.add_child(shape)
	area.global_position = track.start_point() + Vector3.UP * 2.0
	area.global_basis = Basis.looking_at(track.start_direction(), Vector3.UP)
	area.body_entered.connect(_on_start_line_crossed)
	add_child(area)

func _on_start_line_crossed(body: Node3D) -> void:
	if body != car or _lap_cooldown > 0.0:
		return
	_lap_cooldown = 10.0 # anti dublu-trigger la aceeasi trecere
	var now := Time.get_ticks_msec()
	if _lap_start_ms >= 0:
		var lap_ms := now - _lap_start_ms
		if _best_lap_ms < 0 or lap_ms < _best_lap_ms:
			_best_lap_ms = lap_ms
	_lap_start_ms = now

# --------------------------------------------------------------------- HUD

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
	_hud.text = "%3.0f km/h\ntur:  %s\nbest: %s\n[R] reset" % [kmh, lap_text, best_text]

func _fmt_ms(ms: int) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000, (ms % 1000) / 100]
