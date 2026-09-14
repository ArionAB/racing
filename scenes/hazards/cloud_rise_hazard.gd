@tool
class_name CloudRiseHazard
extends FogCorridorHazard
## NORUL care urca din defileu (Machu Picchu, brief §2 POI B-C, §3 „Norul"):
## un val alb urca pe perete de SUB banda, acopera drumul ~4 s si se retrage,
## pe un ciclu de ~31 s. Hazardul FALS al pistei, clasa teatru: prima data
## franezi, a doua oara treci cu turbo — fiindca nu face nimic masinii.
##
## Reuse [FogCorridorHazard] cu un ceas: culoarul de ceata e acelasi (zona
## in care e masina jucatorului, ceata pistei impinsa spre cea a culoarului,
## doar pentru `is_player`, zero colizor, zero forte), inmultit cu o
## ACOPERIRE 0..1 care urca, tine si coboara pe ciclu. Corpul vizibil e o
## PANZA billboard cu margine moale (gradient radial procedural, un singur
## material, un quad — memoria `particule-muchia-nu-numarul`), care urca din
## defileu (`cloud_bottom` sub cota drumului, pe partea `cloud_side_offset`)
## pana peste banda: se vede 3-4 s ridicandu-se pe perete inainte sa-ti intre
## in drum, ca baloanele din Cappadocia — un nor „de sus" nu s-ar vedea
## (brief §2.0).
##
## Declarare: nod cu scriptul asta PE axa soselei, cu -Z local pe sensul de
## mers (ca FogCorridor); `length`/`half_width` acopera drumul, iar norul
## vizibil sta la `cloud_side_offset` metri lateral (+X local = dreapta).
## Reperele de pe margine ale culoarului NU se construiesc aici: norul nu e
## un culoar permanent, e un eveniment.
##
## Contract de cost: ZERO pe masina (mostenit). Ceasul e al nodului (`phase`
## muta faza de la tur la tur, ca la restul ceasurilor pistei).

@export_group("Ciclu")
## Durata ciclului (s). Brief: ~31, si NU divizor al turului.
@export_range(5.0, 120.0, 0.5) var period: float = 31.0
## Cat urca (s), cat sta peste drum (s), cat se retrage (s).
@export_range(0.5, 20.0, 0.1) var rise_time: float = 3.5
@export_range(0.0, 20.0, 0.1) var hold_time: float = 4.0
@export_range(0.5, 20.0, 0.1) var fall_time: float = 2.5
## Decalajul ciclului (0..1 din period).
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

@export_group("Nor")
## Latimea si inaltimea panzei (m).
@export_range(5.0, 120.0, 1.0) var cloud_width: float = 48.0
@export_range(5.0, 60.0, 1.0) var cloud_height: float = 24.0
## Unde sta panza lateral (m, +X local = dreapta sensului de mers): peste
## defileu, de unde urca.
@export_range(-60.0, 60.0, 0.5) var cloud_side_offset: float = 14.0
## Cota panzei (centrul ei) fata de drum: jos, cand e ascunsa in defileu, si
## sus, cand acopera banda.
@export_range(-80.0, 0.0, 0.5) var cloud_bottom: float = -36.0
@export_range(-10.0, 20.0, 0.5) var cloud_top: float = 4.0

var _cloud: MeshInstance3D
var _time: float = 0.0
var _started: bool = false
var _cover: float = 0.0
static var _cloud_material: StandardMaterial3D


func _ready() -> void:
	# Ceata norului e ALBA si scurta: implicitele culoarului sunt ale malului
	# din Chongqing (gri, 46 m). Se pun doar daca nimeni nu le-a schimbat in
	# scena.
	if fog_color == Color(0.72, 0.75, 0.79):
		fog_color = Color(0.94, 0.95, 0.97)
	super()
	_build_cloud()
	_place_cloud()


## Fara repere: norul nu e un culoar permanent.
func _build_markers() -> void:
	pass


static func cloud_material() -> StandardMaterial3D:
	if _cloud_material == null:
		var grad := Gradient.new()
		grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		grad.add_point(0.45, Color(1.0, 1.0, 1.0, 0.85))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 1.0)
		tex.width = 128
		tex.height = 128
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_texture = tex
		m.albedo_color = Color(1.0, 1.0, 1.0, 0.94)
		_cloud_material = m
	return _cloud_material


func _build_cloud() -> void:
	_cloud = MeshInstance3D.new()
	_cloud.name = "Cloud"
	var quad := QuadMesh.new()
	quad.size = Vector2(cloud_width, cloud_height)
	_cloud.mesh = quad
	_cloud.material_override = cloud_material()
	_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cloud)


## Acoperirea 0..1 la momentul t din ciclu: urca, tine, coboara.
func cover_at(t: float) -> float:
	if t < rise_time:
		return smoothstep(0.0, 1.0, t / rise_time)
	if t < rise_time + hold_time:
		return 1.0
	var falling := t - rise_time - hold_time
	if falling < fall_time:
		return 1.0 - smoothstep(0.0, 1.0, falling / fall_time)
	return 0.0


func _place_cloud() -> void:
	if _cloud == null:
		return
	_cloud.position = Vector3(cloud_side_offset,
		lerpf(cloud_bottom, cloud_top, _cover), 0.0)
	_cloud.visible = _cover > 0.001


func _physics_process(delta: float) -> void:
	if not _started:
		_started = true
		_time = phase * period
	_time += delta
	_cover = cover_at(fposmod(_time, period))
	_place_cloud()
	if Engine.is_editor_hint():
		return
	super(delta)


## Ceata culoarului inmultita cu acoperirea norului: fara nor pe drum,
## culoarul nu exista.
func _depth_amount() -> float:
	return super() * _cover


# ---------------------------------------------------------- pentru sonde si capturi

func cover() -> float:
	return _cover


func cycle_time() -> float:
	return fposmod(_time, period)


## Aduce norul la momentul t din ciclu (snapshot --cloud-at).
func set_cycle_time(t: float) -> void:
	_started = true
	_time = t
	_cover = cover_at(fposmod(_time, period))
	_place_cloud()
