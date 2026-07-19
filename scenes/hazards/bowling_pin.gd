@tool # vizibil si in preview-ul din editor (fara simulare fizica acolo)
class_name BowlingPin
extends RigidBody3D
## Popica de jucarie — delimitator de pista FIZIC: sta cuminte (adormita)
## pana o lovesti, apoi zboara. RigidBody adormit costa aproape nimic.

var model_scene: PackedScene
var model_scale: float = 0.53

func _ready() -> void:
	add_to_group("pins")
	mass = 0.4
	sleeping = true
	if model_scene != null:
		var model := model_scene.instantiate() as Node3D
		model.scale = Vector3.ONE * model_scale
		add_child(model)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 1.55
	shape.shape = cyl
	shape.position = Vector3.UP * 0.78
	add_child(shape)
