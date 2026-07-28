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
