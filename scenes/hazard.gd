class_name SlidingHazard
extends AnimatableBody3D
## Obstacol mobil care traverseaza soseaua dintr-o parte in alta — omagiu
## trenului/barierelor din Ignition. AnimatableBody3D = corp "static" pe
## care il misti tu din cod, iar fizica ii calculeaza corect viteza pentru
## corpurile care il ating.

var center: Vector3
var travel: Vector3 # amplitudinea (vector lateral, jumatate de cursa)
var period: float = 3.2

var _time: float = 0.0

func _ready() -> void:
	sync_to_physics = true
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(4.5, 2.2, 2.6)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.15)
	mesh.material_override = mat
	mesh.position = Vector3.UP * 1.1
	add_child(mesh)
	var shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(4.5, 2.2, 2.6)
	shape.shape = col_box
	shape.position = Vector3.UP * 1.1
	add_child(shape)

func _physics_process(delta: float) -> void:
	_time += delta
	global_position = center + travel * sin(TAU * _time / period)
