class_name SpikeCar
extends CharacterBody3D
## Masinuta arcade 3D. Aceeasi reteta ca in kart-ul 2D, mutata pe un plan
## orizontal: viteza se descompune in "inainte" si "lateral" fata de directia
## masinii, grip-ul amortizeaza lateralul, drift-ul il lasa sa alunece.
## Diferenta fata de 2D: gravitatia si pantele — de restul se ocupa
## move_and_slide() cu floor snapping.
##
## Conventie Godot 3D: "inainte" = -Z (asa sunt orientate camerele si modelele).

@export_group("Motor")
@export var max_speed: float = 34.0        # m/s (~120 km/h)
@export var acceleration: float = 16.0
@export var brake_force: float = 30.0
@export var reverse_speed: float = 10.0
@export var drag: float = 0.5

@export_group("Directie")
@export var steer_speed: float = 1.9       # rad/s la viteza plina
@export var grip: float = 8.0
@export var drift_grip: float = 2.0
@export var drift_steer_bonus: float = 1.5
@export var drift_min_speed: float = 9.0

@export_group("Diverse")
@export var gravity: float = 28.0          # mai mare decat realul = arcade
@export var body_color: Color = Color(0.95, 0.45, 0.1)

var start_transform: Transform3D
var is_drifting: bool = false

var _visual: Node3D

func _ready() -> void:
	floor_snap_length = 2.0 # "lipeste" masina de asfalt peste creste de deal
	_build_visual()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 3.8)
	shape.shape = box
	shape.position = Vector3(0, 0.6, 0)
	add_child(shape)
	start_transform = global_transform

func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("brake", "accelerate")
	# axa pozitiva = viraj stanga, pentru ca rotate_y pozitiv = stanga
	var steer := Input.get_axis("steer_right", "steer_left")

	if Input.is_action_just_pressed("reset"):
		reset()
		return

	# Gravitatie mereu; pe sol, snapping-ul tine masina lipita.
	velocity.y -= gravity * delta

	var forward := -global_transform.basis.z
	var fwd_h := Vector3(forward.x, 0.0, forward.z).normalized()
	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	var fwd_speed := hvel.dot(fwd_h)

	is_drifting = Input.is_action_pressed("drift") and fwd_speed > drift_min_speed

	# --- Motor / frana ---
	if throttle > 0.0 and fwd_speed < max_speed:
		hvel += fwd_h * acceleration * throttle * delta
	elif throttle < 0.0:
		if fwd_speed > 2.0:
			hvel += fwd_h * brake_force * throttle * delta
		elif fwd_speed > -reverse_speed:
			hvel += fwd_h * acceleration * 0.6 * throttle * delta
	hvel -= hvel * drag * delta

	# --- Directie (scalata cu viteza, inversata in marsarier) ---
	var speed_frac := clampf(absf(fwd_speed) / (max_speed * 0.5), 0.0, 1.0)
	var steer_mult := drift_steer_bonus if is_drifting else 1.0
	var reverse_sign := -1.0 if fwd_speed < -0.5 else 1.0
	rotate_y(steer * steer_speed * steer_mult * speed_frac * reverse_sign * delta)

	# --- Grip lateral pe noua directie ---
	forward = -global_transform.basis.z
	fwd_h = Vector3(forward.x, 0.0, forward.z).normalized()
	fwd_speed = hvel.dot(fwd_h)
	var lateral := hvel - fwd_h * fwd_speed
	lateral *= exp(-(drift_grip if is_drifting else grip) * delta)
	if fwd_speed > max_speed:
		fwd_speed = move_toward(fwd_speed, max_speed, 20.0 * delta)
	hvel = fwd_h * fwd_speed + lateral

	velocity.x = hvel.x
	velocity.z = hvel.z
	move_and_slide()

	_update_visual_tilt(delta, steer, fwd_speed)

func reset() -> void:
	global_transform = start_transform
	velocity = Vector3.ZERO

func horizontal_speed() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length()

## Juice ieftin: caroseria se inclina in viraje (roll) si pe pante (pitch),
## fara sa complice fizica — doar copilul vizual se roteste.
func _update_visual_tilt(delta: float, steer: float, fwd_speed: float) -> void:
	var speed_frac := clampf(fwd_speed / max_speed, 0.0, 1.0)
	var target_roll := -steer * 0.09 * speed_frac * (1.6 if is_drifting else 1.0)
	var target_pitch := clampf(-velocity.y * 0.02, -0.15, 0.15) * speed_frac
	_visual.rotation.z = lerpf(_visual.rotation.z, target_roll, 8.0 * delta)
	_visual.rotation.x = lerpf(_visual.rotation.x, target_pitch, 5.0 * delta)

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	# Proportii de jucarie: caroserie scurta si lata, roti mari.
	_add_box(Vector3(2.2, 0.7, 3.6), Vector3(0, 0.55, 0), body_color)
	_add_box(Vector3(1.6, 0.55, 1.7), Vector3(0, 1.1, 0.2), body_color.darkened(0.5))
	_add_box(Vector3(2.3, 0.18, 0.7), Vector3(0, 0.9, 1.85), body_color.darkened(0.25)) # eleron
	for corner in [Vector3(-1.05, 0.45, -1.2), Vector3(1.05, 0.45, -1.2),
			Vector3(-1.05, 0.45, 1.25), Vector3(1.05, 0.45, 1.25)]:
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.48
		cyl.bottom_radius = 0.48
		cyl.height = 0.42
		wheel.mesh = cyl
		wheel.rotation.z = PI / 2.0 # cilindrul sta vertical implicit; il culcam
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
