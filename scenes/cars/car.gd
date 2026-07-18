class_name Car
extends CharacterBody3D
## Masina arcade 3D — doar fizica; comenzile vin de la un CarController
## (player sau AI), identitatea (statistici/culoare) dintr-un CarData.
##
## Fizica: viteza descompusa in "inainte" + "lateral" fata de directia
## masinii; grip-ul amortizeaza lateralul, drift-ul il lasa sa alunece.
## Gravitatia si pantele raman in grija lui move_and_slide().
##
## Drift model CTR (portat din racing 2D): cat timp tii drift-ul se incarca
## un boost in 3 niveluri; il banchezi cand dai drumul — cu cat mai tarziu,
## cu atat mai puternic. Prea tarziu = backfire (pierzi tot). Boost-urile se
## pot inlantui (chaining).

signal boost_started(car: Car, level: int)
signal backfired(car: Car)

const DRIFT_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),   # nivel 0: gri
	Color(0.3, 0.7, 1.0),   # nivel 1: albastru
	Color(1.0, 0.6, 0.15),  # nivel 2: portocaliu
	Color(0.8, 0.3, 1.0),   # nivel 3: violet
]

# --- Statistici (suprascrise de CarData la apply_data) ---
@export_group("Motor")
@export var max_speed: float = 34.0
@export var acceleration: float = 16.0
@export var brake_force: float = 30.0
@export var reverse_speed: float = 10.0
@export var drag: float = 0.5

@export_group("Directie")
@export var steer_speed: float = 1.9
@export var grip: float = 8.0

@export_group("Drift & Boost (model CTR)")
@export var drift_grip: float = 2.0
@export var drift_steer_bonus: float = 1.5
@export var drift_bias: float = 0.4
@export var drift_min_speed: float = 9.0
@export var drift_level_times: Array[float] = [0.7, 1.5, 2.4]
@export var backfire_time: float = 3.3
@export var boost_durations: Array[float] = [0.55, 0.95, 1.5]
@export var boost_speed_bonus: float = 10.0 # m/s peste plafon la nivel 3
@export var boost_max_bank: float = 3.0

@export_group("Diverse")
@export var gravity: float = 28.0
@export var body_color: Color = Color(0.95, 0.45, 0.1)
@export var mass_factor: float = 1.0
@export var offroad_speed_factor: float = 0.45

# --- Stare de cursa (scrisa de Race) ---
var race_active: bool = false
var finished: bool = false
var race_position: int = 1
var is_player: bool = false
var speed_scale: float = 1.0 # variatia onesta a AI (0.88..0.97), 1.0 la player

var car_name: String = "?"
var controller: CarController
var track: Track
var road_index: int = 0
var start_transform: Transform3D

# --- Drift/boost ---
var is_drifting: bool = false
var drift_dir: float = 0.0
var drift_charge: float = 0.0
var boost_time: float = 0.0
var boost_level: int = 0

var _visual: Node3D

func _ready() -> void:
	floor_snap_length = 2.0 # tine masina lipita de asfalt peste creste
	_build_visual()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	shape.shape = box
	shape.position = Vector3(0, 0.6, 0)
	add_child(shape)
	start_transform = global_transform

func set_controller(new_controller: CarController) -> void:
	controller = new_controller
	add_child(new_controller)
	new_controller.setup(self)

func apply_data(data: CarData, color_override: Color = Color(0, 0, 0, 0)) -> void:
	car_name = data.display_name
	max_speed = data.max_speed
	acceleration = data.acceleration
	grip = data.grip
	mass_factor = data.mass_factor
	body_color = data.color if color_override.a == 0.0 else color_override
	if _visual != null:
		_visual.queue_free()
	_build_visual()

func _physics_process(delta: float) -> void:
	boost_time = maxf(boost_time - delta, 0.0)
	if boost_time <= 0.0:
		boost_level = 0
	if track != null:
		road_index = track.closest_index(road_index, global_position)

	var steer := 0.0
	var throttle := 0.0
	var drift_pressed := false
	if controller != null and race_active and not finished:
		controller.update(delta)
		steer = clampf(controller.get_steer(), -1.0, 1.0)
		throttle = clampf(controller.get_throttle(), -1.0, 1.0)
		drift_pressed = controller.is_drift_pressed()

	velocity.y -= gravity * delta

	var forward := -global_transform.basis.z
	var fwd_h := Vector3(forward.x, 0.0, forward.z).normalized()
	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	var fwd_speed := hvel.dot(fwd_h)

	_update_drift(drift_pressed, steer, fwd_speed, delta)

	# --- Motor / frana ---
	var vmax := _current_max_speed()
	if throttle > 0.0 and fwd_speed < vmax:
		hvel += fwd_h * acceleration * throttle * delta
	elif throttle < 0.0:
		if fwd_speed > 2.0:
			hvel += fwd_h * brake_force * throttle * delta
		elif fwd_speed > -reverse_speed:
			hvel += fwd_h * acceleration * 0.6 * throttle * delta
	hvel -= hvel * drag * delta

	# --- Directie (amplificata si "impinsa" in directia drift-ului) ---
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var effective_steer := steer
	if is_drifting:
		effective_steer = clampf(
			steer * drift_steer_bonus + drift_dir * drift_bias, -1.6, 1.6)
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	rotate_y(effective_steer * steer_speed * speed_frac * reverse_sign * delta)

	# --- Grip lateral pe noua directie ---
	forward = -global_transform.basis.z
	fwd_h = Vector3(forward.x, 0.0, forward.z).normalized()
	fwd_speed = hvel.dot(fwd_h)
	var lateral := hvel - fwd_h * fwd_speed
	lateral *= exp(-(drift_grip if is_drifting else grip) * delta)
	if fwd_speed > vmax:
		fwd_speed = move_toward(fwd_speed, vmax, 12.0 * delta)
	hvel = fwd_h * fwd_speed + lateral

	velocity.x = hvel.x
	velocity.z = hvel.z
	move_and_slide()
	_handle_bumping()
	_update_visual_tilt(delta, steer, fwd_speed)

## Plafonul de viteza al momentului: taiat de iarba, ridicat de boost.
## Boost-ul se aplica SI pe iarba — scurtatura cu boost e o alegere valida.
func _current_max_speed() -> float:
	var vmax := max_speed * speed_scale
	if track != null and not track.is_on_road(road_index, global_position):
		vmax *= offroad_speed_factor
	if boost_time > 0.0:
		vmax += boost_speed_bonus * (0.5 + 0.5 * float(boost_level) / 3.0)
	return vmax

# ------------------------------------------------------------------- drift

func _update_drift(drift_pressed: bool, steer: float, fwd_speed: float, delta: float) -> void:
	if not is_drifting:
		if drift_pressed and fwd_speed > drift_min_speed and absf(steer) > 0.25:
			is_drifting = true
			drift_dir = signf(steer)
			drift_charge = 0.0
		return
	drift_charge += delta
	var too_slow := fwd_speed < drift_min_speed * 0.55
	if drift_charge >= backfire_time:
		_backfire()
	elif not drift_pressed or too_slow:
		_release_drift(not too_slow)

func drift_level() -> int:
	var level := 0
	for t in drift_level_times:
		if drift_charge >= t:
			level += 1
	return level

func _release_drift(give_boost: bool) -> void:
	is_drifting = false
	var level := drift_level()
	drift_charge = 0.0
	if give_boost and level > 0:
		apply_boost(boost_durations[level - 1], level)

func _backfire() -> void:
	is_drifting = false
	drift_charge = 0.0
	boost_time = 0.0
	boost_level = 0
	velocity *= 0.6
	backfired.emit(self)

## Chaining: boost-urile succesive se aduna (pana la boost_max_bank).
func apply_boost(duration: float, level: int) -> void:
	boost_time = minf(boost_time + duration, boost_max_bank)
	boost_level = maxi(boost_level, level)
	var forward := -global_transform.basis.z
	velocity += Vector3(forward.x, 0.0, forward.z).normalized() * 3.5 * float(level)
	boost_started.emit(self, level)

# ------------------------------------------------------------- imbranceli

func _handle_bumping() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider() as Car
		if other == null:
			continue
		var n := col.get_normal() # dinspre celalalt spre noi
		n.y = 0.0
		other.velocity += -n * 4.5 * (mass_factor / other.mass_factor)
		velocity += n * 4.5 * (other.mass_factor / mass_factor)

# ------------------------------------------------------------------ restul

func reset() -> void:
	global_transform = start_transform
	velocity = Vector3.ZERO
	is_drifting = false
	drift_charge = 0.0
	if track != null:
		road_index = track.closest_index_global(global_position)

func horizontal_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()

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
