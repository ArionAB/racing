class_name BumpProp
extends RigidBody3D
## Decor MIC care se imprastie la contact (#489): taburete, scutere, biciclete,
## rucsaci, tumbleweed, butoaie. Principiul 1 din CLAUDE.md — haosul fizic e
## mecanica — aplicat pe tot decorul care n-are ce cauta ca zid sau ca fantoma.
##
## Acelasi tipar ca `RoadMarker`: corp rigid ADORMIT pana il atinge cineva —
## un corp adormit costa aproape nimic in Jolt. Diferenta: modelul nu se
## construieste aici, se IMPRUMUTA. `wrap` ia un model deja asezat in lume (de
## WorldProp sau de un constructor din Track) si il muta sub un corp nou, cu
## aceeasi pozitie si rotatie.
##
## Stratul propriu (`LAYER`) e cheia: masina il loveste (Car isi adauga stratul
## in masca), dar razele suspensiei, camera si cautarea de loc liber la
## repunere folosesc masca implicita, deci NU il vad — roata nu urca pe un
## taburet, camera nu se smuceste dupa o bicicleta, repunerea nu fuge de un
## rucsac. Iar AI-ul nu vede deloc decorul; trece prin el si il imprastie.
##
## Modelul ramane sub un nod CU SCRIPT, deci coacerea in MultiMesh a decorului
## manual (`TrackDecorBatch._collect_manual`) il sare — altfel bufferul static
## ar fi lasat o copie inghetata in locul de unde a zburat.

## Stratul de coliziune al decorului bump-abil (layer 9).
const LAYER: int = 1 << 8
## Pragul de marime (#489, „de decis"): doar ce incape intr-o cutie de 2 m in
## plan si 1,8 m inaltime. O masa cu taburete (1,82 x 1,88 m, masurata) sau un
## scuter da; o masina parcata, un container sau un felinar de piatra nu —
## acelea raman colizori statici.
const MAX_FOOTPRINT_M: float = 2.0
const MAX_HEIGHT_M: float = 1.8
## Plafonul de corpuri per pista (costul pe mobil). Adormite nu costa, dar o
## izbitura in gramada le trezeste pe toate deodata. Peste plafon, piesa ramane
## statica (WorldProp cade pe hull) — nimic nu dispare.
const MAX_PER_TRACK: int = 64
## Masa din volumul cutiei, cu o densitate de JUCARIE (kg/m³): o masina are
## 100-260 kg, iar un butoi de jucarie trebuie sa zboare, nu sa opreasca. Cu
## jumatate din cutie „plina": butoiul ~4 kg, rucsacul ~0,5 kg.
const DENSITY: float = 25.0
const MIN_MASS: float = 0.3
const MAX_MASS: float = 4.0
## Sub cota de pornire cu atat (m): a cazut din lume, se sterge.
const LOST_BELOW_M: float = 25.0

var _spawn_y: float = 0.0


## Muta `model` (deja in arbore, deja asezat) sub un BumpProp nou si il
## intoarce. Null daca piesa e prea mare, daca pista si-a atins plafonul sau
## daca modelul n-are geometrie — apelantul pastreaza atunci calea statica.
static func wrap(model: Node3D) -> BumpProp:
	# In editor (Track e @tool) nu: fara simulare, corpul ar fi doar zgomot in
	# arbore, iar scriptul asta nu ruleaza acolo.
	if Engine.is_editor_hint() or model == null or not model.is_inside_tree():
		return null
	var parent := model.get_parent()
	if parent == null:
		return null
	if model.get_tree().get_nodes_in_group(&"bump_props").size() >= MAX_PER_TRACK:
		return null
	# Marimea PROPRIE a piesei (doar cu scara ei): `model_aabb` include
	# transformul radacinii, iar o masa de 1,5 m rotita la 45° ar iesi de 2,1 m.
	var saved := model.transform
	model.transform = Transform3D(Basis.from_scale(saved.basis.get_scale()),
		Vector3.ZERO)
	var aabb := Track.model_aabb(model)
	model.transform = saved
	if aabb.size.y <= 0.01 or aabb.size.y > MAX_HEIGHT_M \
			or maxf(aabb.size.x, aabb.size.z) > MAX_FOOTPRINT_M:
		return null
	var body := BumpProp.new()
	body.name = "%s_bump" % model.name
	parent.add_child(body)
	# Corpul preia pozitia si ROTATIA modelului; scara ramane pe model (un corp
	# rigid scalat are fizica gresita).
	var g := model.global_transform
	body.global_transform = Transform3D(g.basis.orthonormalized(), g.origin)
	model.reparent(body, true)
	body._setup(model)
	return body


func _setup(model: Node3D) -> void:
	add_to_group(&"bump_props")
	collision_layer = LAYER
	# Lumea si masinile (stratul 1) + celelalte piese bump-abile.
	collision_mask = 1 | LAYER
	# Cutia se masoara in spatiul CORPULUI: modelul e copilul lui acum.
	var aabb := Track.model_aabb(model)
	var box := BoxShape3D.new()
	# Putin sub vizual, ca sa nu se agate de colturi invizibile; pe sol ramane
	# asezat pe talpa (centrul coboara cu jumatate din ce s-a taiat).
	box.size = aabb.size * Vector3(0.9, 0.95, 0.9)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = aabb.get_center() - Vector3(0.0, aabb.size.y * 0.025, 0.0)
	add_child(shape)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = shape.position
	mass = clampf(aabb.size.x * aabb.size.y * aabb.size.z * 0.5 * DENSITY,
		MIN_MASS, MAX_MASS)
	var mat := PhysicsMaterial.new()
	mat.friction = 0.7
	mat.bounce = 0.2
	physics_material_override = mat
	linear_damp = 0.3
	angular_damp = 0.6
	_spawn_y = global_position.y
	sleeping = true
	set_physics_process(false)
	sleeping_state_changed.connect(func() -> void:
		set_physics_process(not sleeping))


## Ruleaza doar cat corpul e treaz: piesa aruncata peste o faleza se sterge
## cand iese din lume, ca sa nu cada la infinit pe solver.
func _physics_process(_delta: float) -> void:
	if global_position.y < _spawn_y - LOST_BELOW_M:
		queue_free()
