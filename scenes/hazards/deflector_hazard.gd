@tool # vizibil si in preview-ul din editor
class_name DeflectorHazard
extends Node3D
## Deviatorul: o bariera oblica ancorata pe o margine a soselei, care taie
## drumul in diagonala. Nu te opreste — iti SCHIMBA traiectoria: intri pe
## banda gresita, aluneci pe lama si iesi pe cealalta parte a drumului.
## Gimmick de LINIE (spre deosebire de carusel, care e gimmick de timing):
## te obliga sa alegi banda din timp, nu sa nimeresti o fereastra.
##
## Spatiul local: -Z = sensul cursei, +X = marginea din dreapta a soselei.

var road_half_width: float = 7.0
## +1 = ancorata pe dreapta si taie spre stanga; -1 = invers.
var side_sign: float = 1.0
## Cat de adanc intra lama in sosea, ca fractie din latimea totala. Peste 0.5
## trece de mijloc — banda "gresita" chiar nu mai e o optiune.
var cut_frac: float = 0.58
## Lungimea pe care lama se strecoara in drum (cu cat mai lung, cu atat mai
## lin devierea — scurt = zid, lung = tobogan).
var slide_len: float = 13.0
## m/s adaugati lateral masinii care atinge lama.
var push: float = 7.0

## Modelul din care se face bariera. Gol = lama alba cu dungi, ca inainte.
##
## Mecanica e buna asa cum e (gimmick de linie), dar vizualul era o RIGLA: un
## BoxMesh alb cu dungi rosii, identic pe orice tema. Orice lume are insa un
## obiect cazut peste jumatate de drum — un trunchi, o statuie rasturnata, un
## bolovan. Regula testoasei din track08: obstacolul apartine LUMII, mecanica
## ramane a pistei.
var model_scene: PackedScene
## Nodul din GLB care se pastreaza (celelalte se arunca). Gol = tot fisierul.
##
## Kiturile isi tin mai multe piese intr-un singur fisier — `beach_clutter.glb`
## are cinci, din care noua ne trebuie doar bustanul.
var model_node: String = ""
var model_scale: float = 1.0
## Clasa de material triplanar ("" = atlasul comun al lumii).
var tri_class: String = ""

var _area: Area3D
var _push_dir: Vector3 = Vector3.ZERO
var _cooldown: Dictionary = {}

func _ready() -> void:
	add_to_group("hazards")
	var road_width := road_half_width * 2.0
	# Capatul ancorat, pe marginea drumului, un pic in amonte.
	var anchor := Vector3(side_sign * (road_half_width - 0.3), 0.0, 2.5)
	# Capatul liber, adancit in sosea si deplasat in aval (-Z).
	var tip := Vector3(side_sign * (road_half_width - road_width * cut_frac),
		0.0, 2.5 - slide_len)
	var along := (tip - anchor).normalized()
	var blade_len := anchor.distance_to(tip)
	var blade_h := 1.45
	var blade_t := 0.55
	var center := (anchor + tip) * 0.5 + Vector3.UP * blade_h * 0.5
	var basis := Basis.looking_at(along, Vector3.UP)
	# Devierea e curata daca impinsul e perpendicular pe drum, nu pe lama:
	# masina pleaca lateral, dar nu isi pierde inaintarea.
	_push_dir = Vector3(-side_sign, 0.0, 0.0)

	var body := StaticBody3D.new()
	add_child(body)
	# Cu model: obiectul din lume tine locul lamei, iar semnalul de avertizare
	# ramane un element SEPARAT, mic, la capatul ancorat. Dungile nu se picteaza
	# pe obiect — o statuie cu dungi de santier ar strica exact povestea pentru
	# care am pus-o acolo.
	if model_scene != null:
		var placed := _add_objects(body, anchor, tip)
		if placed:
			_add_warning_post(body, anchor, blade_h)
		else:
			_add_blade(body, basis, center, Vector3(blade_t, blade_h, blade_len))
			_add_stripes(body, anchor, tip, blade_h)
	else:
		_add_blade(body, basis, center, Vector3(blade_t, blade_h, blade_len))
		_add_stripes(body, anchor, tip, blade_h)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(blade_t, blade_h, blade_len)
	shape.shape = box
	shape.transform = Transform3D(basis, center)
	body.add_child(shape)

	# Zona de ghiont, lipita pe fata dinspre mijlocul drumului.
	_area = Area3D.new()
	add_child(_area)
	var area_shape := CollisionShape3D.new()
	var area_box := BoxShape3D.new()
	area_box.size = Vector3(blade_t + 1.2, blade_h + 0.4, blade_len)
	area_shape.shape = area_box
	area_shape.transform = Transform3D(basis, center + _push_dir * 0.65)
	_area.add_child(area_shape)

## Bariera facuta din obiectul cerut, repetat pe diagonala. Intoarce `false`
## daca modelul n-a putut fi folosit (si atunci se cade pe lama de dinainte).
##
## Se REPETA, nu se intinde: un bustean de 4 m scalat la 13 m ar fi un bustean
## deformat, si s-ar vedea imediat pe grosime. Lungimea reala se MASOARA din
## AABB — acelasi tipar ca la SlidingHazard, unde cutia de coliziune se ia din
## model tocmai ca sa nu ramana pe cotele altui obiect.
func _add_objects(body: StaticBody3D, anchor: Vector3, tip: Vector3) -> bool:
	var sample := _instance_model()
	if sample == null:
		return false
	var aabb := Track.model_aabb(sample)
	var piece := maxf(aabb.size.x, aabb.size.z)
	if piece < 0.2:
		sample.queue_free()
		return false
	sample.queue_free()
	var along := (tip - anchor).normalized()
	var span := anchor.distance_to(tip)
	# Piesele se suprapun putin (0.85), ca bariera sa nu aiba gauri prin care
	# masina sa treaca fara sa atinga nimic.
	var step := piece * 0.85
	var count := maxi(int(ceilf(span / step)), 1)
	var yaw := atan2(along.x, along.z)
	for k in count:
		var node := _instance_model()
		if node == null:
			return k > 0
		var t := (float(k) + 0.5) * step
		var pos := anchor + along * minf(t, span)
		# Fiecare piesa e rotita altfel in jurul axei ei: un sir de busteni
		# identici, aliniati perfect, se citeste ca gard, nu ca lucruri cazute.
		node.rotation = Vector3(0.0, yaw + float(k) * 0.31, 0.0)
		node.position = pos - Vector3.UP * (aabb.size.y * 0.15)
		body.add_child(node)
	return true


## Un stalp de avertizare la capatul ancorat: semnalul ramane al PISTEI, nu se
## picteaza pe obiectul din lume.
func _add_warning_post(body: StaticBody3D, anchor: Vector3,
		blade_h: float) -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.22, blade_h * 1.15, 0.22)
	post.mesh = box
	post.position = anchor + Vector3.UP * blade_h * 0.58
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.16, 0.12)
	post.material_override = mat
	body.add_child(post)


## O instanta a modelului, cu piesa ceruta pastrata si materialul de clasa pus.
func _instance_model() -> Node3D:
	if model_scene == null:
		return null
	var root := model_scene.instantiate() as Node3D
	if root == null:
		return null
	if not model_node.is_empty():
		var kept: Node3D = null
		for child in root.get_children():
			if child.name == model_node:
				kept = child as Node3D
			else:
				# `remove_child` inainte de `queue_free`: eliberarea e amanata la
				# sfarsitul cadrului, deci pana atunci piesele nedorite ar
				# ramane in arbore si s-ar randa.
				root.remove_child(child)
				child.queue_free()
		if kept == null:
			root.queue_free()
			return null
		# Piesa se aduce in origine, ca pozitia ei din kit sa nu deplaseze
		# bariera fata de drum.
		root.position = -kept.position
	root.scale = Vector3.ONE * model_scale
	if tri_class.is_empty():
		Palette.apply_world_material(root)
	elif Palette.CLASS_TRIPLANAR_SCALE.has(tri_class):
		# Clasele triplanare sunt cele pentru assets cu UV-uri COLAPSATE (roca,
		# rugina): proiectia tine loc de UV. Aici e in spatiul obiectului,
		# fiindca bariera poate fi rotita.
		Palette.apply_object_triplanar_class(root, tri_class, model_scale)
	else:
		# Restul claselor (lemn, tencuiala) presupun UV-uri proprii pe model —
		# trecute prin triplanar, ar fi picat pe assert-ul din Palette
		# (`CLASS_TRIPLANAR_SCALE` are doar clasele cu UV colapsate). Un bustean
		# de driftwood ISI ARE UV-urile, deci merge pe calea normala.
		#
		# Prefixul gol se potriveste cu ORICE nume de mesh, deci toata piesa
		# primeste clasa — exact ce vrem la un obiect dintr-un singur material.
		Palette.apply_class_materials(root, {"": tri_class})
	# Wrapper, ca `position`/`rotation` puse de apelant sa nu se bata cu
	# corectia de origine de mai sus.
	var holder := Node3D.new()
	holder.add_child(root)
	return holder


func _add_blade(body: StaticBody3D, basis: Basis, center: Vector3,
		size: Vector3) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.transform = Transform3D(basis, center)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.94, 0.94, 0.92)
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

## Dungile roșii pe lama alba: semnul universal de "ocolește pe aici".
## Doar vizual — coliziunea o face lama.
func _add_stripes(body: StaticBody3D, anchor: Vector3, tip: Vector3,
		blade_h: float) -> void:
	var along := (tip - anchor).normalized()
	var basis := Basis.looking_at(along, Vector3.UP)
	var blade_len := anchor.distance_to(tip)
	var stripe_len := 1.3
	var count := int(blade_len / (stripe_len * 2.0))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.16, 0.12)
	for k in count:
		var offset := stripe_len * 0.5 + float(k) * stripe_len * 2.0
		var mesh_inst := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.62, blade_h * 0.9, stripe_len)
		mesh_inst.mesh = box
		mesh_inst.transform = Transform3D(basis,
			anchor + along * offset + Vector3.UP * blade_h * 0.5)
		mesh_inst.material_override = mat
		body.add_child(mesh_inst)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	for overlap in _area.get_overlapping_bodies():
		var car := overlap as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = 0.3
		car.apply_sweep(global_basis * _push_dir * push)
