@tool
class_name Tire
extends RigidBody3D
## Cauciuc — cel mai usor si mai "rostogolitor" dintre cele trei: coliziune
## cilindrica joasa, centru de masa aproape de sol. Cel mai satisfacator de
## lovit in plin (zboara si se rostogoleste departe). Vezi Barrel/Crate.

const HEIGHT: float = 0.32
const RADIUS: float = 0.42

func _ready() -> void:
	add_to_group("bump_props")
	mass = 1.1
	sleeping = true
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = RADIUS * 0.55
	mesh.outer_radius = RADIUS
	body.mesh = mesh # implicit plat pe XZ (gaura pe Y) — exact ca un cauciuc culcat
	body.position = Vector3.UP * HEIGHT * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.12, 0.13) # cauciuc, mai inchis decat asfaltul
	body.material_override = mat
	add_child(body)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = HEIGHT
	shape.shape = cyl
	shape.position = Vector3.UP * HEIGHT * 0.5
	add_child(shape)
