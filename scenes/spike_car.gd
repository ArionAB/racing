class_name SpikeCar
extends CharacterBody3D
## Masina arcade 3D — jucator SAU adversar AI (acelasi corp, alt "creier",
## ca in proiectul 2D). Fizica: viteza descompusa in "inainte" + "lateral",
## grip-ul amortizeaza lateralul, drift-ul il lasa sa alunece; gravitatia si
## pantele raman in grija lui move_and_slide().
##
## Mecanici Ignition: iarba e LENTA (scurtaturile devin risc/recompensa),
## masinile se imbrancesc la contact (masa conteaza — autobuzul impinge,
## puricele zboara), presetari de masini cu stiluri diferite.

@export_group("Motor")
@export var max_speed: float = 34.0
@export var acceleration: float = 16.0
@export var brake_force: float = 30.0
@export var reverse_speed: float = 10.0
@export var drag: float = 0.5

@export_group("Directie")
@export var steer_speed: float = 1.9
@export var grip: float = 8.0
@export var drift_grip: float = 2.0
@export var drift_steer_bonus: float = 1.5
@export var drift_min_speed: float = 9.0

@export_group("Diverse")
@export var gravity: float = 28.0
@export var body_color: Color = Color(0.95, 0.45, 0.1)
@export var mass_factor: float = 1.0 # cine impinge pe cine la contact
@export var offroad_speed_factor: float = 0.45

var car_name: String = "Vipera"
var is_player: bool = true
var track: Track3D
var start_transform: Transform3D
var is_drifting: bool = false
var road_index: int = 0 # ultimul index cunoscut pe curba (citit si de Main)

# stare AI
var ai_line: float = 0.0
var ai_speed_factor: float = 1.0
var _stuck_time: float = 0.0
var _reverse_time: float = 0.0

var _visual: Node3D

func _ready() -> void:
	floor_snap_length = 2.0
	_build_visual()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	shape.shape = box
	shape.position = Vector3(0, 0.6, 0)
	add_child(shape)
	start_transform = global_transform

func _physics_process(delta: float) -> void:
	if track != null:
		road_index = track.closest_index(road_index, global_position)
	var cmd := _gather_input(delta) # x=throttle, y=steer, z=drift(0/1)
	var throttle := cmd.x
	var steer := cmd.y

	velocity.y -= gravity * delta

	var forward := -global_transform.basis.z
	var fwd_h := Vector3(forward.x, 0.0, forward.z).normalized()
	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	var fwd_speed := hvel.dot(fwd_h)

	is_drifting = cmd.z > 0.5 and fwd_speed > drift_min_speed

	# Iarba e lenta: plafonul de viteza scade dur in afara soselei.
	var on_road := track == null or track.is_on_road(road_index, global_position)
	var vmax := max_speed * ai_speed_factor * (1.0 if on_road else offroad_speed_factor)

	if throttle > 0.0 and fwd_speed < vmax:
		hvel += fwd_h * acceleration * throttle * delta
	elif throttle < 0.0:
		if fwd_speed > 2.0:
			hvel += fwd_h * brake_force * throttle * delta
		elif fwd_speed > -reverse_speed:
			hvel += fwd_h * acceleration * 0.6 * throttle * delta
	hvel -= hvel * drag * delta

	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var steer_mult := drift_steer_bonus if is_drifting else 1.0
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	rotate_y(steer * steer_speed * steer_mult * speed_frac * reverse_sign * delta)

	forward = -global_transform.basis.z
	fwd_h = Vector3(forward.x, 0.0, forward.z).normalized()
	fwd_speed = hvel.dot(fwd_h)
	var lateral := hvel - fwd_h * fwd_speed
	lateral *= exp(-(drift_grip if is_drifting else grip) * delta)
	if fwd_speed > vmax:
		fwd_speed = move_toward(fwd_speed, vmax, 20.0 * delta)
	hvel = fwd_h * fwd_speed + lateral

	velocity.x = hvel.x
	velocity.z = hvel.z
	move_and_slide()
	_handle_bumping()
	_update_visual_tilt(delta, steer, fwd_speed)

# ------------------------------------------------------------------ creier

func _gather_input(delta: float) -> Vector3:
	if is_player:
		if Input.is_action_just_pressed("reset"):
			reset()
			return Vector3.ZERO
		return Vector3(
			Input.get_axis("brake", "accelerate"),
			Input.get_axis("steer_right", "steer_left"),
			1.0 if Input.is_action_pressed("drift") else 0.0)
	return _ai_input(delta)

## AI-ul urmareste centrul soselei cu doua puncte de tintire (aproape =
## directie, departe = anticiparea virajului), cu o linie laterala proprie.
func _ai_input(delta: float) -> Vector3:
	if track == null:
		return Vector3.ZERO
	var speed := horizontal_speed()

	# anti-blocaj: mars inapoi scurt daca stam pe loc
	if _reverse_time > 0.0:
		_reverse_time -= delta
		return Vector3(-1.0, 0.0, 0.0)
	if speed < 2.0:
		_stuck_time += delta
		if _stuck_time > 1.2:
			_reverse_time = 0.9
			_stuck_time = 0.0
	else:
		_stuck_time = 0.0

	var near := track.lookahead_point(road_index, 24.0, ai_line)
	var far := track.lookahead_point(road_index, 55.0, ai_line)
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var to_near := near - global_position
	to_near.y = 0.0
	var to_far := far - global_position
	to_far.y = 0.0
	# semnul unghiului fata de UP: pozitiv = tinta e la stanga = steer pozitiv
	var a_near := fwd.signed_angle_to(to_near.normalized(), Vector3.UP)
	var a_far := fwd.signed_angle_to(to_far.normalized(), Vector3.UP)

	var steer := clampf(a_near * 2.0, -1.0, 1.0)
	var throttle := 1.0
	if absf(a_far) > 0.9 and speed > max_speed * 0.5:
		throttle = 0.2
	var drift := 1.0 if absf(a_far) > 0.55 and speed > drift_min_speed * 1.2 else 0.0
	return Vector3(throttle, steer, drift)

# ------------------------------------------------------------- imbranceli

## Contactul intre masini: amandoua primesc un branci de-a lungul normalei,
## scalat cu raportul maselor — masina grea abia simte, cea usoara zboara.
func _handle_bumping() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider() as SpikeCar
		if other == null:
			continue
		var n := col.get_normal() # arata dinspre celalalt spre noi
		n.y = 0.0
		other.velocity += -n * 4.5 * (mass_factor / other.mass_factor)
		velocity += n * 4.5 * (other.mass_factor / mass_factor)

# ------------------------------------------------------------------ restul

func reset() -> void:
	global_transform = start_transform
	velocity = Vector3.ZERO
	if track != null:
		road_index = track.closest_index_global(global_position)

func horizontal_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()

func apply_preset(preset: Dictionary) -> void:
	car_name = preset.name
	max_speed = preset.max_speed
	acceleration = preset.accel
	grip = preset.grip
	mass_factor = preset.mass
	body_color = preset.color
	if _visual != null:
		_visual.queue_free()
	_build_visual()

func _update_visual_tilt(delta: float, steer: float, fwd_speed: float) -> void:
	var speed_frac := clampf(fwd_speed / max_speed, 0.0, 1.0)
	var target_roll := -steer * 0.09 * speed_frac * (1.6 if is_drifting else 1.0)
	var target_pitch := clampf(-velocity.y * 0.02, -0.15, 0.15) * speed_frac
	_visual.rotation.z = lerpf(_visual.rotation.z, target_roll, 8.0 * delta)
	_visual.rotation.x = lerpf(_visual.rotation.x, target_pitch, 5.0 * delta)

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_add_box(Vector3(2.2, 0.7, 3.6), Vector3(0, 0.55, 0), body_color)
	_add_box(Vector3(1.6, 0.55, 1.7), Vector3(0, 1.1, 0.2), body_color.darkened(0.5))
	_add_box(Vector3(2.3, 0.18, 0.7), Vector3(0, 0.9, 1.85), body_color.darkened(0.25))
	for corner in [Vector3(-1.05, 0.45, -1.2), Vector3(1.05, 0.45, -1.2),
			Vector3(-1.05, 0.45, 1.25), Vector3(1.05, 0.45, 1.25)]:
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.48
		cyl.bottom_radius = 0.48
		cyl.height = 0.42
		wheel.mesh = cyl
		wheel.rotation.z = PI / 2.0
		wheel.position = corner
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.1, 0.1, 0.1)
		wheel.material_override = mat
		_visual.add_child(wheel)

func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	inst.material_override = mat
	_visual.add_child(inst)
