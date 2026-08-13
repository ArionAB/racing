@tool # vizibil (si animat) si in preview-ul din editor
class_name CarouselHazard
extends Node3D
## Caruselul: o morisca uriasa plantata in mijlocul soselei, cu vane care
## MATURA toata latimea drumului. Gimmick de TIMING — nu exista linie sigura,
## doar fereastra dintre doua vane. O vezi de la 100m, deci e cinstit:
## incetinesti si o lasi sa treaca, sau intri tare si speri.
##
## Vanele sunt un AnimatableBody3D (corp mutat din cod, cu viteza calculata
## corect de fizica) — te blocheaza onest. Peste asta, un Area3D adauga un
## ghiont pe TANGENTA rotatiei, ca maturatul sa se simta ca o maturare, nu ca
## un stalp. Butucul din centru ramane solid: e si el obstacol, dar vizibil.

## Cat de departe ajunge varful vanei de la butuc (tinut sub half_width ca
## sa nu intre in pereti).
var arm_reach: float = 6.8
var arm_count: int = 2
## Secunde pentru o rotatie completa. Cu 2 vane, o fereastra la fiecare
## jumatate de perioada — destul de lent ca sa fie citibil de departe.
var period: float = 4.2
## m/s adaugati pe tangenta masinii maturate.
var sweep_push: float = 6.5
var vane_colors: Array[Color] = [Color(0.9, 0.22, 0.18), Color(0.98, 0.82, 0.15)]

## Turnul de langa drum, ca morisca sa apartina unei gospodarii (#245).
##
## Gol = butucul procedural de dinainte (talpa + stalp). Cu model, mecanica NU
## se schimba deloc: bratele maturau si maturau la fel, doar ca acum au un motiv
## sa existe acolo.
##
## De ce turn LANGA drum si nu chiar moara peste sosea: paletele lui
## `windmill.glb` au raza 1.3 m si stau la 9.66 m inaltime (masurat) — sunt o
## cladire, nu un obstacol. Mecanica cere 6.8 m de bataie la nivelul masinii.
## Scalata cat sa matura drumul, moara ar fi avut turnul de 50 m; coborata la
## sol, ar fi fost o moara ingropata. Asa ca moara ramane moara, iar peste drum
## trece ARIPA ei lunga — piesa care oricum se invarte.
## Numele piesei de palete din GLB-ul morii — se arunca (vezi `_build_tower`).
const BLADES_NODE := "Blades"

var tower_scene: PackedScene
var tower_node: String = ""
var tower_scale: float = 1.0
var tower_class: String = ""
## Cat de lateral sta turnul fata de axa drumului. Se pune de pista: turnul NU
## are voie sa stea pe carosabil, doar bratele trec peste el.
var tower_offset: float = 0.0
## Bratele arata ca aripi de moara (lati, cu zabrele), nu ca vane de carusel.
var mill_blades: bool = false

var _rotor: AnimatableBody3D
var _area: Area3D
var _angle: float = 0.0
## Cat mai are fiecare masina pana poate fi maturata iar (altfel primeste
## ghiontul de 60 de ori pe secunda cat sta lipita de vana).
var _cooldown: Dictionary = {}

func _ready() -> void:
	add_to_group("hazards")
	_build_hub()
	_build_rotor()

## Butucul: talpa lata in nisip + stalpul pe care se invarte morisca.
##
## Cu `tower_scene`, in locul stalpului procedural vine cladirea morii, asezata
## LANGA drum. Coliziunea ii ramane a ei, la fel de solida — un turn prin care
## treci ar fi mai rau decat un stalp.
func _build_hub() -> void:
	if tower_scene != null and _build_tower():
		return
	var hub := StaticBody3D.new()
	add_child(hub)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.55
	base_mesh.bottom_radius = 1.0
	base_mesh.height = 0.5
	base.mesh = base_mesh
	base.position = Vector3.UP * 0.25
	base.material_override = _flat(Color(0.35, 0.36, 0.42))
	hub.add_child(base)
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.22
	post_mesh.bottom_radius = 0.28
	post_mesh.height = 2.2
	post.mesh = post_mesh
	post.position = Vector3.UP * 1.35
	post.material_override = _flat(Color(0.82, 0.84, 0.88))
	hub.add_child(post)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.75
	cyl.height = 2.4
	shape.shape = cyl
	shape.position = Vector3.UP * 1.2
	hub.add_child(shape)

## Cladirea morii, langa drum. Intoarce `false` daca modelul n-a putut fi
## folosit (si atunci se cade pe butucul procedural).
func _build_tower() -> bool:
	var root := tower_scene.instantiate() as Node3D
	if root == null:
		return false
	if not tower_node.is_empty():
		var kept: Node3D = null
		for child in root.get_children():
			if child.name == tower_node:
				kept = child as Node3D
			else:
				root.remove_child(child) # vezi nota de mai jos despre queue_free
				child.queue_free()
		if kept == null:
			root.queue_free()
			return false
	else:
		# Paletele proprii ale cladirii se ARUNCA: ele stau sus, la 9.66 m, si
		# s-ar invarti separat de bratele care matura drumul. Doua seturi de
		# palete pe aceeasi moara, rotindu-se independent, e chiar genul de
		# lucru pe care nimeni nu-l observa in cod si toata lumea il vede pe
		# ecran.
		for child in root.get_children():
			if String(child.name).begins_with(BLADES_NODE):
				# `remove_child` INAINTE de `queue_free`: eliberarea e amanata la
				# sfarsitul cadrului, deci pana atunci paletele ar fi ramas in
				# arbore — se randau si se numarau, chiar daca „au fost sterse".
				root.remove_child(child)
				child.queue_free()
	root.scale = Vector3.ONE * tower_scale
	if tower_class.is_empty():
		Palette.apply_world_material(root)
	elif Palette.CLASS_TRIPLANAR_SCALE.has(tower_class):
		Palette.apply_object_triplanar_class(root, tower_class, tower_scale)
	else:
		Palette.apply_class_materials(root, {"": tower_class})

	var body := StaticBody3D.new()
	add_child(body)
	# Turnul sta LATERAL, dincolo de bataia bratelor: pe axa drumului ar fi fost
	# un zid in mijlocul soselei, iar caruselul trebuie sa lase o fereastra.
	body.position = Vector3(tower_offset, 0.0, 0.0)
	body.add_child(root)
	var aabb := Track.model_aabb(root)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = maxf(maxf(aabb.size.x, aabb.size.z) * 0.5, 0.6)
	cyl.height = maxf(aabb.size.y, 1.0)
	shape.shape = cyl
	shape.position = Vector3.UP * cyl.height * 0.5
	body.add_child(shape)
	return true


## Rotorul: vanele care matura, plus zona de ghiont care le insoteste.
func _build_rotor() -> void:
	_rotor = AnimatableBody3D.new()
	_rotor.sync_to_physics = true
	add_child(_rotor)
	_area = Area3D.new()
	_rotor.add_child(_area)
	# Vana e joasa si lata: prinde caroseria (colizerul masinii sta la 0.1..1.1).
	var vane_h := 0.95
	var vane_t := 0.32
	for k in arm_count:
		var angle := TAU * float(k) / float(arm_count)
		var dir := Vector3(cos(angle), 0.0, -sin(angle))
		var center := dir * arm_reach * 0.5 + Vector3.UP * (vane_h * 0.5 + 0.12)
		var basis := Basis.looking_at(dir, Vector3.UP)
		if mill_blades:
			_add_mill_blade(basis, center, vane_h, vane_t, arm_reach)
		else:
			var mesh_inst := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(vane_t, vane_h, arm_reach)
			mesh_inst.mesh = box
			mesh_inst.transform = Transform3D(basis, center)
			mesh_inst.material_override = _flat(
				vane_colors[k % vane_colors.size()])
			_rotor.add_child(mesh_inst)
		var col_shape := CollisionShape3D.new()
		var col_box := BoxShape3D.new()
		col_box.size = Vector3(vane_t, vane_h, arm_reach)
		col_shape.shape = col_box
		col_shape.transform = Transform3D(basis, center)
		_rotor.add_child(col_shape)
		# Zona de ghiont: un pic mai grasa decat vana, ca sa prinda contactul.
		var area_shape := CollisionShape3D.new()
		var area_box := BoxShape3D.new()
		area_box.size = Vector3(vane_t + 1.1, vane_h + 0.4, arm_reach)
		area_shape.shape = area_box
		area_shape.transform = Transform3D(basis, center)
		_area.add_child(area_shape)

## O aripa de moara: lonjeronul de lemn plus panza intinsa pe el.
##
## Aceeasi amprenta ca vana de carusel (coliziunea nici nu se atinge — se
## construieste separat, din aceleasi cote), doar ca se citeste ca aripa: lemn,
## nu plastic colorat, si o panza mai lata decat grinda.
func _add_mill_blade(basis: Basis, center: Vector3, vane_h: float,
		vane_t: float, reach: float) -> void:
	var spar := MeshInstance3D.new()
	var spar_box := BoxMesh.new()
	spar_box.size = Vector3(vane_t, vane_h * 0.42, reach)
	spar.mesh = spar_box
	spar.transform = Transform3D(basis, center)
	spar.material_override = _flat(Color(0.42, 0.30, 0.19)) # lemn
	_rotor.add_child(spar)
	# Panza: mai lata si mai subtire decat lonjeronul, impinsa spre VARFUL
	# aripii — langa butuc o aripa de moara e goala, panza incepe mai incolo.
	#
	# `Basis.looking_at(dir)` pune -Z pe directia bratului, deci "spre varf"
	# inseamna -Z local, adica `-basis.z` in lume.
	var cloth := MeshInstance3D.new()
	var cloth_box := BoxMesh.new()
	cloth_box.size = Vector3(vane_t * 0.35, vane_h, reach * 0.62)
	cloth.mesh = cloth_box
	var outward := -basis.z.normalized()
	cloth.transform = Transform3D(basis, center + outward * reach * 0.16)
	cloth.material_override = _flat(Color(0.88, 0.85, 0.76)) # panza patata
	_rotor.add_child(cloth)


func _physics_process(delta: float) -> void:
	_angle = fposmod(_angle + TAU * delta / period, TAU)
	_rotor.rotation.y = _angle
	if Engine.is_editor_hint():
		return
	_sweep_cars(delta)

func _sweep_cars(delta: float) -> void:
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	for body in _area.get_overlapping_bodies():
		var car := body as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = 0.35
		var radial := car.global_position - global_position
		radial.y = 0.0
		if radial.length() < 0.3:
			continue
		# Tangenta in sensul rotatiei: pentru rotatie pozitiva pe Y, un punct
		# la raza r se deplaseaza spre UP x r.
		var tangent := Vector3.UP.cross(radial.normalized()).normalized()
		car.apply_sweep(tangent * sweep_push + Vector3.UP * 1.2)

func _flat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat
