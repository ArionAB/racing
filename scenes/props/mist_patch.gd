@tool
class_name MistPatch
extends Node3D
## Petic de CEATA JOASA pentru padurea de ceata (Serengeti, POI D): un pumn de
## billboard-uri moi, unshaded, cu textura de fum, culcate intre trunchiuri
## la 0.5-3 m de sol. E ceata care se VEDE in cadru — spre deosebire de
## `FogCorridorHazard`, care misca ceata de adancime a Environment-ului doar
## cand jucatorul e inauntru (deci nu apare intr-o captura fara masina si nu
## sta „intre trunchiuri": ceata de adancime e un voal pe distanta, nu un
## petic la sol).
##
## [b]Cost[/b]: UN material partajat de toate peticele (static, `_mat`) si UN
## draw call per petic (MultiMeshInstance3D). Ce costa pe mobil e
## overdraw-ul: `count` x quad-uri de `size` m suprapuse. De aia numarul e
## mic (8 implicit) si peticele se pun unde camera le vede prin trunchiuri,
## nu pe toata padurea.
##
## Fara coliziune, fara umbra, fara scriere in adancime (e gaz). WorldProp nu
## il atinge: nu e instanta de .glb.

const TEX_PATH: String = "res://assets/textures/smoke_puff.png"

## Cate billboard-uri in petic.
@export_range(1, 24) var count: int = 8:
	set(v):
		count = v
		_rebuild()
## Raza elipsei la sol in care se imprastie (m), pe X si pe Z locale.
@export var footprint: Vector2 = Vector2(9.0, 5.0):
	set(v):
		footprint = v
		_rebuild()
## Latura unui billboard (m): min si max.
@export var size: Vector2 = Vector2(6.0, 11.0):
	set(v):
		size = v
		_rebuild()
## Centrul billboard-ului sta intre cotele astea deasupra originii (m).
@export var height: Vector2 = Vector2(0.8, 2.6):
	set(v):
		height = v
		_rebuild()
## Culoarea cetii (alpha = densitatea unui singur strat).
@export var tint: Color = Color(0.86, 0.88, 0.87, 0.30):
	set(v):
		tint = v
		_rebuild()
@export var seed: int = 7:
	set(v):
		seed = v
		_rebuild()

static var _mat: StandardMaterial3D
var _mmi: MultiMeshInstance3D


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_mat.billboard_keep_scale = true
		_mat.vertex_color_use_as_albedo = true
		_mat.albedo_texture = load(TEX_PATH) as Texture2D
		# Ceata de adancime a scenei o inghite si pe ea, ca pe orice altceva:
		# un petic la 150 m nu are voie sa ramana alb pe fundalul violet.
		_mat.disable_fog = false
	return _mat


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mmi != null:
		_mmi.queue_free()
		_mmi = null
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = material()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = count
	for i in count:
		var a := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf())
		var p := Vector3(cos(a) * r * footprint.x,
			rng.randf_range(height.x, height.y), sin(a) * r * footprint.y)
		var s := rng.randf_range(size.x, size.y)
		# Latit: ceata joasa e o panza, nu o bila.
		var b := Basis.IDENTITY.scaled(Vector3(s, s * 0.55, 1.0))
		mm.set_instance_transform(i, Transform3D(b, p))
		var c := tint
		c.a = tint.a * rng.randf_range(0.7, 1.0)
		mm.set_instance_color(i, c)
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Ceata"
	_mmi.multimesh = mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)
