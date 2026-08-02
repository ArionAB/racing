@tool # vizibil (si animat) si in preview-ul din editor
class_name ExcavatorHazard
extends StaticBody3D
## Excavator de jucarie parcat pe marginea soselei; BRATUL (nod articulat
## in modelul Blender) coboara si se ridica ciclic peste o banda. Cand
## bratul e coborat, coliziunea lui blocheaza banda; cand e ridicat, treci.
## Cronometraj — ca barierele din Ignition, dar cu personalitate de sandbox.

var model_scene: PackedScene
var model_scale: float = 0.75
var period: float = 7.0 # jos 2.5s + urca 1s + sus 2.5s + coboara 1s
var raise_angle: float = 0.55

var _arm: Node3D
var _arm_base_rot: float = 0.0
var _arm_shape: CollisionShape3D
var _time: float = 0.0

func _ready() -> void:
	add_to_group("hazards")
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
		var body_node := model.find_child("body", true, false) as Node3D
		if body_node != null:
			# `arm` e COPIL al lui `body` in GLB, deci fara skip iese o cutie de
			# 10 m pe adancime care ar bloca soseaua permanent. Sasiul e o masa
			# compacta, deci AABB-ul lui e o aproximare buna.
			body_aabb = model.transform * Track.model_aabb(body_node, _arm)
	# Corpul excavatorului (mereu solid).
	var body_shape := CollisionShape3D.new()
	var body_box := BoxShape3D.new()
	body_box.size = body_aabb.size
	body_shape.shape = body_box
	body_shape.position = body_aabb.position + body_aabb.size * 0.5
	add_child(body_shape)
	# Bratul intins peste drum (solid doar cand e coborat) — dimensionat
	# sa se opreasca unde se opreste si vizualul, nu mai departe.
	#
	# Cutia asta ramane potrivita de mana, INTENTIONAT. Bratul e o grinda
	# diagonala, iar AABB-ul unei diagonale supra-acopera grosolan: masurat, dau
	# 3.60 m inaltime pentru un brat de vreo 1 m grosime, ridicat cu un metru
	# fata de unde e de fapt. O cutie stransa pe axa bratului e mai aproape de
	# adevar decat una aliniata pe axe.
	#
	# Cotele se scaleaza cu modelul, deci un digger mai mare/mai mic ramane
	# coerent; ce NU se ia singur dupa model e forma. Cand se schimba rigul,
	# re-potriveste-le cu `probe_dims.gd` (vezi ONBOARDING).
	var k := model_scale / 0.75 # 0.75 = scara la care au fost potrivite
	_arm_shape = CollisionShape3D.new()
	var arm_box := BoxShape3D.new()
	arm_box.size = Vector3(1.6, 2.0, 4.6) * k
	_arm_shape.shape = arm_box
	_arm_shape.position = Vector3(0, 1.1, -2.9) * k
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
	_arm_shape.disabled = raised > 0.35
