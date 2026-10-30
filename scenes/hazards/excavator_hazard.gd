@tool # vizibil (si animat) si in preview-ul din editor
class_name ExcavatorHazard
extends StaticBody3D
## Excavator de jucarie parcat pe marginea soselei; BRATUL (nod articulat
## in modelul Blender) coboara si se ridica ciclic peste o banda. Cand
## bratul e coborat, coliziunea lui blocheaza banda; cand e ridicat, treci.
## Cronometraj — ca barierele din Ignition, dar cu personalitate de sandbox.

var model_scene: PackedScene
## Rigul din care se MASOARA sasiul (null = chiar `model_scene`). Un model nou
## care respecta contractul rigului (±0.1 m fata de rusted_digger) isi pastreaza
## colizoarele rigului de referinta: masurat pe Track23, quarry_excavator are
## sasiul cu doar 1.6 cm / 4 mm altfel, si totusi seria de 16 curse a sarit de la
## 6 la 19 repuneri (cu cutia rigului fortata: 7). Cursa e haotica la milimetru,
## deci schimbarea vizualului nu trebuie sa atinga fizica.
var collider_scene: PackedScene
## Rusted_digger e construit la scara lumii; cel de plastic cerea 0.75.
var model_scale: float = 1.0
var period: float = 7.0 # jos 2.5s + urca 1s + sus 2.5s + coboara 1s
var raise_angle: float = 0.55
## Clasa triplanara pe TOT modelul. Implicit `rust_metal` (rusted_digger e
## integral rugina). Gol = modelul isi tine sloturile din atlas si trece prin
## maparea pe PARTI (`WorldProp.prop_classes()`): quarry_excavator are vopseaua
## galbena pe atlas si doar `*_Rust` pe clasa.
var model_class: String = "rust_metal"

## AI-ul da cu zarul la apropiere (`AIController._exc_line`): 1-3 ocoleste pe
## banda libera, 4-6 trece pe sub brat. Implicit stins = bit-identic.
var ai_dice: bool = false
## Lovitura (brat sau sasiu) NU ejecteaza soferul: ghiont + strivire scurta.
## Implicit stins = bit-identic. Vezi `Car._process_contacts` (meta).
var soft_contact: bool = false
var soft_crush_s: float = 1.0
const AI_GROUP: StringName = &"ai_excavator"

var _body_shape: CollisionShape3D
var _arm: Node3D
var _arm_base_rot: float = 0.0
var _arm_shape: CollisionShape3D
var _time: float = 0.0

func _ready() -> void:
	add_to_group("hazards")
	if soft_contact:
		set_meta(&"soft_hit_crush", soft_crush_s)
	if ai_dice:
		add_to_group(AI_GROUP)
	# Sasiul se MASOARA; bratul NU. Vezi de ce mai jos — sunt doua cazuri
	# diferite, si al doilea e cazul in care masuratoarea iese mai prost decat
	# valoarea potrivita de mana.
	var body_aabb := AABB(Vector3(-1.7, 0.0, -0.7), Vector3(3.4, 3.4, 3.4))
	if model_scene != null:
		var model := model_scene.instantiate() as Node3D
		model.scale = Vector3.ONE * model_scale
		add_child(model)
		_arm = model.find_child("arm", true, false) as Node3D
		if _arm != null:
			_arm_base_rot = _arm.rotation.x
		# Clasa rust_metal (triplanar): excavatorul e integral metal ruginit.
		# Static — nu se misca din loc — deci triplanarul de lume nu "inoata";
		# bratul se leagana, dar amplitudinea e mica si textura de rugina e
		# aperiodica, deci nu se citeste.
		if model_class.is_empty():
			Palette.apply_object_class_materials(model, WorldProp.prop_classes(),
				model_scale)
		else:
			Palette.apply_triplanar_class(model, model_class)
		var rig := model
		if collider_scene != null:
			rig = collider_scene.instantiate() as Node3D
			rig.scale = model.scale
		var body_node := rig.find_child("body", true, false) as Node3D
		if body_node != null:
			# `arm` e COPIL al lui `body` in GLB, deci fara skip iese o cutie de
			# 10 m pe adancime care ar bloca soseaua permanent. Sasiul e o masa
			# compacta, deci AABB-ul lui e o aproximare buna.
			body_aabb = rig.transform * Track.model_aabb(body_node,
				rig.find_child("arm", true, false) as Node3D)
		if rig != model:
			rig.free()
	# Corpul excavatorului (mereu solid).
	var body_shape := CollisionShape3D.new()
	var body_box := BoxShape3D.new()
	body_box.size = body_aabb.size
	body_shape.shape = body_box
	body_shape.position = body_aabb.position + body_aabb.size * 0.5
	add_child(body_shape)
	_body_shape = body_shape
	# Bratul intins peste drum (solid doar cand e coborat) — dimensionat
	# sa se opreasca unde se opreste si vizualul, nu mai departe.
	#
	# Cutia asta ramane potrivita de mana, INTENTIONAT. Bratul e o grinda
	# diagonala, iar AABB-ul unei diagonale supra-acopera grosolan: pe rigul
	# vechi masuratoarea dadea 3.60 m inaltime pentru un brat de vreo 1 m
	# grosime, ridicat cu un metru fata de unde e de fapt.
	#
	# Re-potrivita pe rigul rusted_digger (masurat cu probe_dims): bratul
	# ocupa X 0.09..1.01, Y 0.92..3.76, Z -5.70..-0.32 in spatiul modelului.
	# Cutia coboara pana la sol desi bratul incepe la 0.92 m: colizorul masinii
	# sta la 0.1..1.1, deci o cutie care porneste de la 0.9 ar lasa doar 20 cm
	# de suprapunere si o masina rapida ar putea trece prin ea.
	#
	# Cotele se scaleaza cu modelul, deci un digger mai mare/mai mic ramane
	# coerent; ce NU se ia singur dupa model e forma. Cand se schimba rigul,
	# re-potriveste-le cu `probe_dims.gd` (vezi ONBOARDING).
	var k := model_scale / 1.0 # 1.0 = scara la care au fost potrivite
	_arm_shape = CollisionShape3D.new()
	var arm_box := BoxShape3D.new()
	arm_box.size = Vector3(1.2, 2.6, 5.4) * k
	_arm_shape.shape = arm_box
	_arm_shape.position = Vector3(0.55, 1.3, -3.0) * k
	add_child(_arm_shape)

func _physics_process(delta: float) -> void:
	_time += delta
	var t := fmod(_time, period)
	var raised := 0.0 # 0 = coborat (blocheaza), 1 = ridicat (liber)
	if t < 2.5:
		raised = 0.0
	elif t < 3.5:
		raised = t - 2.5
	elif t < 6.0:
		raised = 1.0
	else:
		raised = 1.0 - (t - 6.0)
	if _arm != null:
		_arm.rotation.x = _arm_base_rot + raise_angle * raised
	# Cand bratul e destul de sus, banda devine libera.
	var solid := raised <= 0.35
	# Cutia nu se INCHIDE peste o masina: aparuta in jurul ei, Jolt o scoate pe
	# drumul cel mai scurt, iar cu cutia de la sol la 2.6 m acela e IN JOS, prin
	# asfalt (~1.1 m, fata de ~2.5 in sus). Urmarit pe Carrara (Track23, seed 8):
	# y 25 -> 22 in 0.4 s, apoi un tur intreg sub drum pana la culeea viaductului.
	# Asteapta sa iasa masina; bratul vizual coboara oricum, deci trece "prin" ea.
	if solid and _arm_shape.disabled and _car_in_arm_box():
		solid = false
	_arm_shape.disabled = not solid


func _car_in_arm_box() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _arm_shape.shape
	query.transform = _arm_shape.global_transform
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 8):
		if hit.get("collider") is Car:
			return true
	return false


## Cutiile solide in LUME (colturile), pentru AI: sasiul e mereu solid, bratul
## doar cand e coborat — dar AI-ul foloseste doar GEOMETRIA lor (unde se afla
## banda libera), nu faza. Intoarce {"arm": [colturi], "body": [colturi]}.
func ai_box_corners() -> Dictionary:
	var out := {"arm": PackedVector3Array(), "body": PackedVector3Array()}
	for pair: Array in [["arm", _arm_shape], ["body", _body_shape]]:
		var sh := pair[1] as CollisionShape3D
		if sh == null or not (sh.shape is BoxShape3D):
			continue
		var size := (sh.shape as BoxShape3D).size
		var corners := PackedVector3Array()
		for sx in [-0.5, 0.5]:
			for sy in [-0.5, 0.5]:
				for sz in [-0.5, 0.5]:
					corners.append(sh.global_transform * (size * Vector3(sx, sy, sz)))
		out[pair[0]] = corners
	return out
