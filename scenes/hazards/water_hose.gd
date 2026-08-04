@tool # vizibil si in preview-ul din editor
class_name WaterHose
extends Node3D
## Furtun de gradina la marginea soselei: pulseaza apa peste drum in cicluri.
## Banda uda = grip aproape zero (aquaplanare) — cronometreaza-ti trecerea
## sau tine-te tare de volan. Radacina sta PE CENTRUL soselei, orientata pe
## directia de mers; furtunul e decalat lateral, cu duza spre drum.

## Nodul vizual, pregatit de apelant (o singura varianta scoasa din GLB).
## Se pune INAINTE de add_child, ca la RoadMarker.
var model: Node3D
## Conducta noua e construita la scara lumii; furtunul vechi cerea 0.45.
var model_scale: float = 1.0
var road_width: float = 14.0
var period: float = 6.0
var on_time: float = 2.6

var _zone: Area3D
var _spray: CPUParticles3D
var _puddle: MeshInstance3D
var _time: float = 0.0

func _ready() -> void:
	add_to_group("hoses")
	if model != null:
		model.scale = Vector3.ONE * model_scale
		model.position = Vector3(road_width * 0.5 + 2.5, 0, 0)
		model.rotation.y = PI / 2.0 # duza modelului (-Z) se intoarce spre drum
		add_child(model)
		# Conducta sparta: metal ruginit, un singur material dominant.
		Palette.apply_triplanar_class(model, "rust_metal")

	_zone = Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(road_width + 2.0, 3.0, 4.5)
	shape.shape = box
	shape.position = Vector3.UP * 1.0
	_zone.add_child(shape)
	add_child(_zone)

	# Balta translucida, vizibila doar cand tasneste apa.
	_puddle = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.04
	_puddle.mesh = disc
	_puddle.scale = Vector3(road_width * 0.5, 1.0, 2.2)
	_puddle.position = Vector3.UP * 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.9, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_puddle.material_override = mat
	_puddle.visible = false
	add_child(_puddle)

	# Jetul de apa dinspre duza spre drum.
	_spray = CPUParticles3D.new()
	_spray.position = Vector3(road_width * 0.5 + 1.2, 1.6, 0)
	_spray.direction = Vector3(-1, 0.35, 0)
	_spray.spread = 8.0
	_spray.initial_velocity_min = 11.0
	_spray.initial_velocity_max = 14.0
	_spray.gravity = Vector3(0, -9.0, 0)
	_spray.amount = 70
	_spray.lifetime = 1.0
	_spray.emitting = false
	var drop := BoxMesh.new()
	drop.size = Vector3(0.14, 0.14, 0.14)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.vertex_color_use_as_albedo = true
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = drop_mat
	_spray.mesh = drop
	_spray.color = Color(0.55, 0.78, 1.0)
	add_child(_spray)

func _physics_process(_delta: float) -> void:
	_time += _delta
	var active := fmod(_time, period) < on_time
	_spray.emitting = active
	_puddle.visible = active
	if active:
		for body in _zone.get_overlapping_bodies():
			var car := body as Car
			if car != null:
				car.apply_slip()
