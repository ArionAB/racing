@tool
class_name Crate
extends RigidBody3D
## Lada de lemn, bump-abila — mai grea decat bidonul/cauciucul, se rostogoleste
## mai greu (colturi, nu rulment). Fara model .glb, vezi Barrel.

const SIZE: float = 0.85

func _ready() -> void:
	add_to_group("bump_props")
	mass = 3.4
	sleeping = true
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * SIZE
	body.mesh = mesh
	body.position = Vector3.UP * SIZE * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.54, 0.41, 0.28) # wood_weathered, vezi style_bible
	body.material_override = mat
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * SIZE
	shape.shape = box
	shape.position = Vector3.UP * SIZE * 0.5
	add_child(shape)
