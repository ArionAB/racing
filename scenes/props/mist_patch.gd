@tool
class_name MistPatch
extends Node3D
## Petic de CEATA JOASA pentru padurea de ceata (Serengeti, POI D): o
## PATURA de panze aproape ORIZONTALE, cu textura de fum, culcate
## la 1.2-2.2 m de sol intre trunchiuri. E ceata care se VEDE in cadru —
## spre deosebire de `FogCorridorHazard`, care misca ceata de adancime a
## Environment-ului doar cand jucatorul e inauntru.
##
## [b]De ce NU unshaded (runda 6)[/b]: un petic UNSHADED are aceeasi
## luminanta sub coroana si in soare — se citeste ca PODEA solida, nu ca gaz.
## Normala quad-ului e in sus, deci `SHADING_MODE_PER_PIXEL` il face sa
## raspunda la soare/umbra ca orice suprafata orizontala.
##
## [b]De ce ORIZONTALE (runda 2)[/b]: pana aici materialul avea
## `billboard_mode = BILLBOARD_ENABLED`. Un billboard se roteste ca sa
## priveasca spre camera, deci o panza „latita" (scale 1 x 0.42) ramane
## VERTICALA in ecran: din masina se citeau ca tepi albi atarnand de coroane
## si ca placi gri stand in picioare intre trunchiuri. Ceata joasa reala e o
## patura care taie trunchiurile la baza — deci quad-ul se culca pe sol
## (rotit -90 deg pe X, normala in sus), cu o inclinare mica aleatoare, si NU
## se mai orienteaza dupa camera. Consecinte masurabile: inaltimea totala a
## unei panze ajunge `size * sin(tilt)` (sub 1 m la tilt <= 14 deg) in loc de
## `size * 0.42` (5-8 m), raportul latime/inaltime trece de 4:1 pe toate, iar
## marginea de sus ramane sub prima ramura.
##
## [b]Cost[/b]: UN material partajat de toate peticele (static, `_mat`) si UN
## draw call per petic (MultiMeshInstance3D). Ce costa pe mobil e
## overdraw-ul: `count` x quad-uri de `size` m suprapuse.
##
## Fara coliziune, fara umbra, fara scriere in adancime (e gaz). WorldProp nu
## il atinge: nu e instanta de .glb.

const TEX_PATH: String = "res://assets/textures/smoke_puff.png"

## Cate panze in petic.
@export_range(1, 48) var count: int = 8:
	set(v):
		count = v
		_rebuild()
## Raza elipsei la sol in care se imprastie (m), pe X si pe Z locale.
@export var footprint: Vector2 = Vector2(9.0, 5.0):
	set(v):
		footprint = v
		_rebuild()
## Latura unei panze (m): min si max. Panza e patrata si CULCATA, deci asta e
## intinderea ei pe sol, nu inaltimea.
@export var size: Vector2 = Vector2(6.0, 11.0):
	set(v):
		size = v
		_rebuild()
## Centrul panzei sta intre cotele astea deasupra originii (m). Tine-l jos:
## garda cere `y_top - teren <= 2.5 m`, iar y_top = height.y + size_max*sin(tilt)/2.
@export var height: Vector2 = Vector2(0.3, 1.4):
	set(v):
		height = v
		_rebuild()
## Inclinarea maxima fata de orizontala (grade). Peste ~16 deg panza incepe
## sa se citeasca ca placa in picioare si raportul latime/inaltime scade sub 4.
@export_range(0.0, 30.0) var tilt_deg: float = 10.0:
	set(v):
		tilt_deg = v
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
		# RUNDA 6: NU mai e UNSHADED. Fiind opac la luminanta indiferent de
		# lumina, un petic sub coroana (umbra) iesea la fel de deschis ca unul
		# in soare — se citea ca PODEA solida, nu ca gaz. Normala quad-ului e
		# in sus (vezi antetul clasei), deci PER_PIXEL raspunde la soare/umbra
		# ca orice suprafata orizontala: mai stins sub coroane, mai deschis in
		# culoarele de soare — exact contrastul care lipsea.
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		# NU billboard: panza e culcata pe sol si trebuie sa RAMANA culcata
		# indiferent de unde priveste camera (vezi antetul clasei).
		_mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		_mat.vertex_color_use_as_albedo = true
		_mat.albedo_texture = load(TEX_PATH) as Texture2D
		# Ceata de adancime a scenei o inghite si pe ea, ca pe orice altceva.
		_mat.disable_fog = false
	return _mat


## Transformarea unei singure panze. Statica si publica fiindca garda
## (`tools/probe_mist.gd`) trebuie sa masoare EXACT geometria desenata, nu o
## reimplementare a ei: scena Track14 nu se poate adauga in arbore in afara
## unei curse, deci peticele nu-si construiesc MultiMesh-ul acolo si garda le
## reconstruieste din aceeasi functie.
static func quad_transform(rng: RandomNumberGenerator, foot: Vector2,
		sz: Vector2, hgt: Vector2, tmax: float) -> Transform3D:
	var a := rng.randf_range(0.0, TAU)
	var r := sqrt(rng.randf())
	var p := Vector3(cos(a) * r * foot.x,
		rng.randf_range(hgt.x, hgt.y), sin(a) * r * foot.y)
	var s := rng.randf_range(sz.x, sz.y)
	# Panza e alungita pe o axa: o patura, nu un disc. Scara se aplica INTAI,
	# in spatiul quad-ului (XY), apoi se culca si se roteste — `Basis.scaled`
	# inmulteste la STANGA, deci dupa rotatie ar intinde axele lumii.
	var b := Basis.IDENTITY.scaled(Vector3(s, s * rng.randf_range(0.45, 0.8), 1.0))
	# QuadMesh sta in planul XY cu normala pe +Z; rotit cu -90 deg pe X ajunge
	# culcat, cu normala in sus.
	b = Basis(Vector3.RIGHT, -PI * 0.5) * b
	b = Basis(Vector3.UP, rng.randf_range(0.0, TAU)) * b
	b = Basis(Vector3.RIGHT, rng.randf_range(-tmax, tmax)) * b
	b = Basis(Vector3.FORWARD, rng.randf_range(-tmax, tmax)) * b
	return Transform3D(b, p)


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
	var tmax := deg_to_rad(tilt_deg)
	for i in count:
		mm.set_instance_transform(i, quad_transform(rng, footprint, size, height, tmax))
		var c := tint
		c.a = tint.a * rng.randf_range(0.7, 1.0)
		mm.set_instance_color(i, c)
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Ceata"
	_mmi.multimesh = mm
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mmi)
