@tool # vizibil si in preview-ul din editor
class_name WaterHose
extends WaterHazard
## Conducta sparta la marginea soselei: pulseaza apa peste drum in cicluri.
## Banda uda = grip aproape zero (aquaplanare) — cronometreaza-ti trecerea sau
## tine-te tare de volan. Radacina sta PE CENTRUL soselei, orientata pe directia
## de mers; conducta e decalata lateral, cu duza spre drum.
##
## Ce e AICI si nu in `WaterHazard`: doar sursa — teava, jetul si ciclul lor.
## Petecul ud e al bazei, acelasi cu al valului de pe Okinawa (`wave_surge.gd`).

## Nodul vizual, pregatit de apelant (o singura varianta scoasa din GLB).
## Se pune INAINTE de add_child, ca la RoadMarker.
var model: Node3D
## Conducta noua e construita la scara lumii; furtunul vechi cerea 0.45.
var model_scale: float = 1.0
var period: float = 6.0
var on_time: float = 2.6

var _spray: CPUParticles3D
var _time: float = 0.0


func _build_source() -> void:
	if model != null:
		model.scale = Vector3.ONE * model_scale
		model.position = Vector3(road_width * 0.5 + 2.5, 0, 0)
		model.rotation.y = PI / 2.0 # duza modelului (-Z) se intoarce spre drum
		add_child(model)
		# Conducta sparta: metal ruginit, un singur material dominant.
		Palette.apply_triplanar_class(model, "rust_metal")

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


func _advance(delta: float) -> bool:
	_time += delta
	var active := fmod(_time, period) < on_time
	_spray.emitting = active
	return active
