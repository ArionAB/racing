class_name ChaseCamera
extends Node3D
## Chase cam: urmarire cu intarziere lina (lag-ul face virajele sa "se
## simta"), FOV care creste cu viteza si sare la boost, screen shake pe
## modelul "trauma" (shake = trauma^2, se stinge singur — impacturile mici
## abia se simt, cele mari zguduie serios).

@export var distance: float = 7.5
@export var height: float = 3.2
@export var follow_speed: float = 5.0
@export var base_fov: float = 68.0

const MAX_SHAKE: float = 0.35 # metri de offset la trauma maxima

var target: Car
var trauma: float = 0.0

var _cam: Camera3D

func _ready() -> void:
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true

func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var fwd := -target.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var desired := target.global_position - fwd * distance + Vector3.UP * height
	var t := 1.0 - exp(-follow_speed * delta) # urmarire independenta de fps
	global_position = global_position.lerp(desired, t)
	look_at(target.global_position + Vector3.UP * 1.2 + fwd * 3.0, Vector3.UP)

	# FOV: viteza + kick suplimentar cat tine boost-ul.
	var speed_frac := clampf(target.horizontal_speed() / target.max_speed, 0.0, 1.0)
	var boost_kick := 6.0 if target.boost_time > 0.0 else 0.0
	_cam.fov = lerpf(_cam.fov, base_fov + 14.0 * speed_frac + boost_kick, 3.0 * delta)

	# Shake in spatiul ecranului (h/v offset pe camera, nu pe rig).
	trauma = maxf(trauma - 1.8 * delta, 0.0)
	var shake := trauma * trauma
	_cam.h_offset = randf_range(-1.0, 1.0) * MAX_SHAKE * shake
	_cam.v_offset = randf_range(-1.0, 1.0) * MAX_SHAKE * shake

func snap_behind() -> void:
	if target == null:
		return
	var fwd := -target.global_transform.basis.z
	global_position = target.global_position - fwd * distance + Vector3.UP * height
	look_at(target.global_position + Vector3.UP * 1.2, Vector3.UP)
