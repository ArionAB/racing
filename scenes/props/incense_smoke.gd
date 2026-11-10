class_name IncenseSmoke
extends CPUParticles3D
## FUMUL DE TAMAIE (Angkor, POI E, brief §3 „Teatrul"): cateva coloane subtiri si lente care
## urca din altarele de langa drum, intre turnurile cu fete ale Bayonului.
##
## UN SINGUR emitator pentru toate coloanele: `emission_points` poarta pozitiile surselor in
## coordonate de LUME (nodul sta la origine, `top_level`, `local_coords = false`), deci
## 5-6 coloane costa UN draw call si o suta de particule cel mult — nu cate un nod pe altar.
##
## Particula e un cadran billboard cu o textura radiala cu cadere CONTINUA (centru opac,
## margine zero), nu o sfera: memoria „particule-muchia-nu-numarul" — un nor moale iese din
## marginea lui, nu din cate particule ai. Sfera cu 8 segmente a prafului de la ghionturi
## (`PropDebris`) are muchie poligonala si arata ca o bila, nu ca un fum.
##
## Materialul e unul singur, partajat intre instante (`static var`): nealuminat, deci nu depinde
## de soare. Nu atinge bugetul de materiale al decorului (e de particule, nu din atlas).

## Pozitiile surselor, in lume (m). Scrise de generator din `SMOKE` din fisierele de zona.
@export var sources: PackedVector3Array = PackedVector3Array():
	set(v):
		sources = v
		if is_inside_tree():
			_apply()
## Particule per coloana in zbor la un moment dat (≈ durata de viata / pauza dintre pufuri).
@export_range(2, 20) var puffs_per_column: int = 12
## Cat urca fumul (m/s). Lent: tamaia sta in aer, nu e un cos de fabrica.
@export_range(0.2, 2.0, 0.05) var rise_speed: float = 1.0
## Cat de tare il impinge vantul pe orizontala (m/s²); acelasi sens pentru toate coloanele.
@export var wind: Vector3 = Vector3(0.10, 0.0, 0.04)
@export var smoke_color: Color = Color(0.92, 0.90, 0.86)

static var _material: StandardMaterial3D = null
static var _mesh: QuadMesh = null


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_apply()


func _apply() -> void:
	if sources.is_empty():
		emitting = false
		return
	local_coords = false
	emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	emission_points = sources
	amount = sources.size() * puffs_per_column
	lifetime = 8.0
	preprocess = 8.0 # fumul exista deja cand incepe cursa
	explosiveness = 0.0
	direction = Vector3.UP
	spread = 5.0
	initial_velocity_min = rise_speed * 0.8
	initial_velocity_max = rise_speed * 1.1
	gravity = wind
	damping_min = 0.0
	damping_max = 0.0
	angle_min = -180.0
	angle_max = 180.0
	scale_amount_min = 0.9
	scale_amount_max = 1.2
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 2.2))
	scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.2, 0.7, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.0)]))
	color_ramp = fade
	color = smoke_color
	mesh = _shared_mesh()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emitting = true


static func _shared_mesh() -> QuadMesh:
	if _mesh != null:
		return _mesh
	if _material == null:
		var tex := GradientTexture2D.new()
		tex.width = 64
		tex.height = 64
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		var g := Gradient.new()
		# Cadere continua: miez moale, zero la margine. Fara treapta, deci fara contur.
		g.set_offsets(PackedFloat32Array([0.0, 0.45, 1.0]))
		g.set_colors(PackedColorArray([
			Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)]))
		tex.gradient = g
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = tex
		m.disable_receive_shadows = true
		_material = m
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 1.6)
	q.material = _material
	_mesh = q
	return q
