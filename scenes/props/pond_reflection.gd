class_name PondReflection
extends Node3D
## Reflexia unui model intr-o apa plana si OPACA (Kyoto POI F: Pavilionul de
## Aur pe iaz). Nodul sta cu ACEEASI transformare ca modelul real; la rulare
## instantiaza o copie a modelului si ii pune pe toate mesh-urile materialul
## `pond_reflection.gdshader`, care oglindeste varfurile fata de apa si le
## proiecteaza pe planul apei pe raza camerei (vezi antetul shaderului: de ce nu
## copie sub apa, de ce nu gaura in iaz). Costul: +1 material (brief §3.1
## decizia 4), o copie a modelului, umbra stinsa.
##
## Nodul NU sta sub `DecorManual`: `world_prop.gd` ar pune materialul lumii peste
## copie. Copia e adaugata fara `owner`, deci nu intra in `.tscn`.

@export var model: PackedScene
## Cota apei (m, lume) si cat sta imaginea deasupra ei.
@export var water_y: float = -1.0
@export var lift: float = 0.16
@export_range(0.0, 1.0, 0.01) var strength: float = 0.6
@export_range(0.0, 2.0, 0.01) var gain: float = 0.9
@export var fade_depth_m: float = 18.0
## Nodurile modelului care NU se reflecta (platforma de piatra are UV de clasa,
## nu de atlas, si sta oricum la nivelul apei).
@export var skip_nodes: PackedStringArray = PackedStringArray(["Kin_Stone"])
## Culoarea apei, daca nu se gaseste materialul iazului (liniar).
@export var water_col: Color = Color(0.05, 0.12, 0.15)
## Numele nodului de apa din pista din care se ia `deep_col` (prefix).
@export var water_node_prefix: String = "RavineWaterSurface"

var _mat: ShaderMaterial
var _copy: Node3D


func _ready() -> void:
	if Engine.is_editor_hint() or model == null:
		return
	_build.call_deferred()


func material() -> ShaderMaterial:
	return _mat


func _build() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://assets/shaders/pond_reflection.gdshader") as Shader
	_mat.set_shader_parameter("albedo_atlas", load(Palette.ATLAS_PATH))
	_mat.set_shader_parameter("water_y", water_y)
	_mat.set_shader_parameter("lift", lift)
	_mat.set_shader_parameter("strength", strength)
	_mat.set_shader_parameter("gain", gain)
	_mat.set_shader_parameter("fade_depth_m", fade_depth_m)
	var wc := _pond_color()
	_mat.set_shader_parameter("water_col", Vector3(wc.r, wc.g, wc.b))
	_copy = model.instantiate() as Node3D
	_copy.name = "Copie"
	add_child(_copy)
	_dress(_copy)


## `deep_col` din materialul apei iazului, ca reflexia sa se amestece cu exact
## culoarea pe care o randeaza apa.
func _pond_color() -> Color:
	var p := get_parent()
	if p != null:
		for c in p.get_children():
			if str(c.name).begins_with(water_node_prefix) and c is MeshInstance3D:
				var sm := (c as MeshInstance3D).material_override as ShaderMaterial
				if sm != null:
					var v: Variant = sm.get_shader_parameter("deep_col")
					if v is Vector3:
						return Color((v as Vector3).x, (v as Vector3).y, (v as Vector3).z)
	return water_col


func _dress(n: Node) -> void:
	for c in n.get_children():
		if skip_nodes.has(str(c.name)):
			(c as Node3D).visible = false
			continue
		var mi := c as MeshInstance3D
		if mi != null:
			mi.material_override = _mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Imaginea sta pe apa, in FATA modelului, nu in AABB-ul lui.
			mi.extra_cull_margin = 40.0
		_dress(c)
