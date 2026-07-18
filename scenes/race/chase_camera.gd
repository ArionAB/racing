class_name ChaseCamera
extends Node3D
## Chase cam: sta in spatele si putin deasupra masinii, o urmareste cu
## intarziere lina (lag-ul face virajele sa "se simta") si mareste FOV-ul
## cu viteza — trucul clasic de senzatie de viteza.

@export var distance: float = 7.5
@export var height: float = 3.2
@export var follow_speed: float = 5.0
@export var base_fov: float = 68.0

var target: Car

var _cam: Camera3D

func _ready() -> void:
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true

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
	var speed_frac := clampf(target.horizontal_speed() / target.max_speed, 0.0, 1.0)
	_cam.fov = lerpf(_cam.fov, base_fov + 14.0 * speed_frac, 3.0 * delta)

func snap_behind() -> void:
	if target == null:
		return
	var fwd := -target.global_transform.basis.z
	global_position = target.global_position - fwd * distance + Vector3.UP * height
	look_at(target.global_position + Vector3.UP * 1.2, Vector3.UP)
