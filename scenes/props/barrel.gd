@tool # vizibil si in preview-ul din editor (fara simulare fizica acolo)
class_name Barrel
extends RigidBody3D
## Bidon de tabla, bump-abil — sta adormit pana il lovesti, apoi se rostogoleste.
## Fara model .glb: primitiva GDScript, per docs/blender_export.md (filler
## rapid, validabil headless, zero dependente).

const HEIGHT: float = 0.9
const RADIUS: float = 0.34

func _ready() -> void:
	add_to_group("bump_props")
	mass = 2.2
	sleeping = true
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS * 0.92
	mesh.bottom_radius = RADIUS
	mesh.height = HEIGHT
	body.mesh = mesh
	body.position = Vector3.UP * HEIGHT * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.57, 0.33, 0.21) # rust_metal, vezi docs/style_bible.md
	body.material_override = mat
	add_child(body)
	# Doua dungi ca sa se citeasca drept bidon, nu drept butuc de copac.
	for t in [0.32, 0.62]:
		var band := MeshInstance3D.new()
		var band_mesh := CylinderMesh.new()
		band_mesh.top_radius = RADIUS + 0.02
		band_mesh.bottom_radius = RADIUS + 0.02
		band_mesh.height = 0.07
		band.mesh = band_mesh
		band.position = Vector3.UP * HEIGHT * t
		var band_mat := StandardMaterial3D.new()
		band_mat.albedo_color = Color(0.3, 0.3, 0.32)
		band.material_override = band_mat
		add_child(band)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = HEIGHT
	shape.shape = cyl
	shape.position = Vector3.UP * HEIGHT * 0.5
	add_child(shape)
