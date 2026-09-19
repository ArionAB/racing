class_name ToyRagdoll
extends Node3D
## Figurina aruncata din masina, ca RAGDOLL din piese rigide.
##
## Fiecare piesa a GLB-ului (Hips, Torso, Head, Arm_L/R, Leg_L/R) devine un
## RigidBody3D cu o cutie de coliziune din AABB-ul mesh-ului, iar piesele se
## leaga cu PinJoint3D (articulatie sferica libera) exact in ORIGINEA piesei
## copil — care in GLB e articulatia (umar, gat, sold). Asa e o jucarie cu
## membre din bucati, nu un schelet skinnuit: fara PhysicalBone3D, fara
## Skeleton3D, 7 corpuri care simuleaza ~2,5 s si apoi ingheata.
##
## Doua reguli care NU se negociaza (vezi CLAUDE.md, principiul 1 si „AI
## onest"):
##   1. Ragdoll-ul NU se ciocneste cu masinile. Un corp pe asfalt ar fi un
##      obstacol static pe care AI-ul nu-l vede (lectia pietei din Goreme),
##      iar un contact cu propria masina ar da un impuls fantoma exact in
##      cadrul aruncarii. Toate masinile primite in `exclude` sunt exceptate.
##   2. Ragdoll-ul nu scrie nimic in starea jocului. E teatru: nimeni nu-l
##      citeste, deci ProbeRace trebuie sa dea aceleasi cifre cu sau fara el.

## Ordinea conteaza doar pentru `bodies()`; articulatiile vin din Driver.PARENT.
const MASSES: Dictionary = {
	&"Hips": 2.4, &"Torso": 3.0, &"Head": 1.4,
	&"Arm_L": 0.7, &"Arm_R": 0.7, &"Leg_L": 1.1, &"Leg_R": 1.1,
}
## Cat simuleaza, cat mai sta pe jos inghetat, si cat dureaza disparitia.
@export var simulate_seconds: float = 2.6
@export var linger_seconds: float = 2.4
@export var fade_seconds: float = 0.35

var _bodies: Dictionary = {}   # StringName -> RigidBody3D
## Parametrii aruncarii, tinuti pana la `_ready`: corpurile primesc
## transformari GLOBALE, deci ragdoll-ul trebuie sa fie deja in arbore.
var _pending: Array = []
var _age: float = 0.0
var _frozen: bool = false
var _fading: bool = false
var _rng := RandomNumberGenerator.new()


## `xforms`: transformarea GLOBALA a fiecarei piese (din soferul asezat);
## `fling`: viteza initiala comuna; `exclude`: corpurile cu care NU ne ciocnim.
## Se construieste la `_ready` (cine ne cheama face add_child imediat dupa).
func prepare(scene: PackedScene, xforms: Dictionary, fling: Vector3,
		exclude: Array) -> void:
	_pending = [scene, xforms, fling, exclude]


func _ready() -> void:
	if _pending.size() == 4:
		build(_pending[0], _pending[1], _pending[2], _pending[3])
		_pending = []


func build(scene: PackedScene, xforms: Dictionary, fling: Vector3,
		exclude: Array) -> void:
	_rng.seed = hash(fling) # aceeasi aruncare -> aceeasi rasucire (sonde)
	var model := scene.instantiate() as Node3D
	Palette.apply_world_material(model)
	var pmat := PhysicsMaterial.new()
	pmat.friction = 0.85
	pmat.bounce = 0.15
	for child in model.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var key := StringName(mi.name)
		if not xforms.has(key):
			continue
		var body := RigidBody3D.new()
		body.name = String(key)
		body.mass = float(MASSES.get(key, 1.0))
		body.physics_material_override = pmat
		body.angular_damp = 1.2
		body.linear_damp = 0.05
		# Ca sonda sa poata verifica regula 1 (niciun contact cu masinile).
		body.contact_monitor = true
		body.max_contacts_reported = 4
		add_child(body)
		body.global_transform = xforms[key]
		mi.owner = null # altfel Godot se plange ca owner-ul scenei GLB e inconsistent
		model.remove_child(mi)
		body.add_child(mi)
		mi.transform = Transform3D.IDENTITY
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var aabb: AABB = mi.mesh.get_aabb()
		box.size = Vector3(maxf(aabb.size.x, 0.08), maxf(aabb.size.y, 0.08),
			maxf(aabb.size.z, 0.08))
		shape.shape = box
		shape.position = aabb.get_center()
		body.add_child(shape)
		for other in exclude:
			if other is PhysicsBody3D:
				body.add_collision_exception_with(other as PhysicsBody3D)
		# Toate piesele pleaca cu viteza masinii; o rasucire mica per piesa,
		# ca sa nu zboare ca un bloc.
		body.linear_velocity = fling + Vector3(
			_rng.randf_range(-1.0, 1.0), _rng.randf_range(0.0, 1.5),
			_rng.randf_range(-1.0, 1.0))
		body.angular_velocity = Vector3(
			_rng.randf_range(-6.0, 6.0), _rng.randf_range(-4.0, 4.0),
			_rng.randf_range(-6.0, 6.0))
		_bodies[key] = body
	model.queue_free()
	# Articulatiile, dupa ce toate corpurile sunt in arbore.
	for key: StringName in Driver.PARENT.keys():
		var parent_key: StringName = Driver.PARENT[key]
		if not _bodies.has(key) or not _bodies.has(parent_key):
			continue
		var child_body: RigidBody3D = _bodies[key]
		var joint := PinJoint3D.new()
		add_child(joint)
		joint.global_position = child_body.global_position
		joint.node_a = joint.get_path_to(_bodies[parent_key])
		joint.node_b = joint.get_path_to(child_body)
		joint.set_param(PinJoint3D.PARAM_DAMPING, 1.0)


## Piesa pe care o urmareste camera cat tine aruncarea.
func focus_node() -> Node3D:
	if _bodies.has(&"Torso"):
		return _bodies[&"Torso"]
	return self


func bodies() -> Array[RigidBody3D]:
	var out: Array[RigidBody3D] = []
	for key in Driver.PART_NAMES:
		if _bodies.has(key):
			out.append(_bodies[key])
	return out


func _physics_process(delta: float) -> void:
	_age += delta
	if not _frozen and _age >= simulate_seconds:
		# Inghetat pe loc: nu mai costa nimic si nu mai tremura.
		_frozen = true
		for body: RigidBody3D in _bodies.values():
			body.freeze = true
	if not _fading and _age >= simulate_seconds + linger_seconds:
		_fading = true
		# Se micsoreaza mesh-urile, nu corpurile (un RigidBody3D scalat se
		# plange, si oricum sunt inghetate).
		var tw := create_tween()
		for body: RigidBody3D in _bodies.values():
			for child in body.get_children():
				if child is MeshInstance3D:
					tw.parallel().tween_property(child, "scale",
						Vector3.ONE * 0.01, fade_seconds)
		tw.tween_callback(queue_free)
