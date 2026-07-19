class_name SlidingHazard
extends AnimatableBody3D
## Obstacol mobil care traverseaza soseaua dintr-o parte in alta.
## AnimatableBody3D = corp "static" pe care il misti tu din cod, iar fizica
## ii calculeaza corect viteza pentru corpurile care il ating.
##
## Poate folosi un model 3D (ex. mingea de plaja din Blender); fara model,
## cade pe cutia galbena placeholder. Cu roll_radius > 0 modelul se
## ROSTOGOLESTE fizic corect: unghi = distanta parcursa / raza.

var center: Vector3
var travel: Vector3 # amplitudinea (vector lateral, jumatate de cursa)
var period: float = 3.2

## Model optional + configuratia lui.
var model_scene: PackedScene
var model_scale: float = 1.0
var roll_radius: float = 0.0 # >0 = sfera care se rostogoleste

var _time: float = 0.0
var _pivot: Node3D
var _last_pos: Vector3

func _ready() -> void:
	sync_to_physics = true
	_last_pos = global_position
	if model_scene != null:
		_build_model()
	else:
		_build_placeholder_box()

func _build_model() -> void:
	# Pivotul sta la inaltimea centrului sferei; modelul (origine in centru)
	# se aseaza in pivot, iar rostogolirea roteste pivotul.
	_pivot = Node3D.new()
	_pivot.position = Vector3.UP * roll_radius
	add_child(_pivot)
	var model := model_scene.instantiate() as Node3D
	model.scale = Vector3.ONE * model_scale
	_pivot.add_child(model)
	var shape := CollisionShape3D.new()
	if roll_radius > 0.0:
		var sphere := SphereShape3D.new()
		sphere.radius = roll_radius
		shape.shape = sphere
		shape.position = Vector3.UP * roll_radius
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(4.5, 2.2, 2.6)
		shape.position = Vector3.UP * 1.1
		shape.shape = box
	add_child(shape)

func _build_placeholder_box() -> void:
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
	if _pivot != null and roll_radius > 0.0:
		# Rostogolire: rotatie in jurul axei perpendiculare pe miscare.
		var moved := global_position - _last_pos
		moved.y = 0.0
		if moved.length() > 0.0001:
			var axis := Vector3.UP.cross(moved.normalized()).normalized()
			_pivot.global_rotate(axis, -moved.length() / roll_radius)
	_last_pos = global_position
