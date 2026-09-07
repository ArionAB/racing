class_name HerdBackdrop
extends Node3D
## TURMA DE FUNDAL (Serengeti, POI B — docs/track_briefs/serengeti.md §2.0):
## „restul turmei (fundal viu, 300+ instante) sta pe campie la 30-120 m de
## drum, ca masa in miscare lenta, nu ca indivizi".
##
## Nu e hazard: zero corpuri, zero contact, zero ceas. E un DECOR din doua
## MultiMesh-uri (gnu + zebra) cu acelasi mesh si acelasi material ca
## HerdHazard (`_animal_mesh_from`, `_herd_material`), deci costa 2 desene si
## un material deja platit de turma de pe drum. Sta sub `DecorManual`, in zona
## POI-ului, ca orice alta piesa de decor — dar nu e un GLB instantiat, ci un
## nod cu script, fiindca 300 de instante ca noduri ar fi 300 de desene si
## 300 de corpuri convexe degeaba.
##
## Geometrie, in spatiul nodului: animalele stau in doua benzi paralele cu
## axa X locala, la |z| in [band_near, band_far], cu x in [-half_x, half_x].
## Pe Track14 nodul sta pe axa culoarului de migratie (70, 0, 165), cu axele
## lumii: X e axa drumului (drumul e drept pe z = 165), Z e directia curgerii.
## Partea cu z < 0 (dreapta soferului) se poate stinge din `near_side`,
## fiindca acolo, la 40-50 m, trece DRUMUL DE INTOARCERE (z ~ 113-127) si
## dincolo de el urca flancul craterului.
##
## Cota vine dintr-o raza reala pe teren, trasa in primul cadru de fizica (in
## `_ready` spatiul fizic nu raspunde inca); memoria
## `terrain-mesh-y-extrapoleaza` spune de ce nu se foloseste campul neted.

## Cate animale in total (gnu + zebre).
@export_range(0, 1200) var count: int = 320
## Jumatatea intinderii pe X local (de-a lungul drumului), in metri.
@export_range(5.0, 200.0, 1.0) var half_x: float = 55.0
## Banda pe Z local: de la `band_near` la `band_far` metri de axa nodului.
@export_range(5.0, 200.0, 1.0) var band_near: float = 34.0
@export_range(10.0, 300.0, 1.0) var band_far: float = 120.0
## Partea cu z > 0 (stanga soferului pe Track14) si partea cu z < 0.
@export var far_side: bool = true
@export var near_side: bool = false
## Zebre la suta (turma de pe drum are 0.2).
@export_range(0.0, 1.0, 0.05) var zebra_ratio: float = 0.2
## Cati dintre ei galopeaza pe loc (shader-ul turmei); restul pasc, nemiscati.
@export_range(0.0, 1.0, 0.05) var gallop_ratio: float = 0.0
## Toti cu fata in directia curgerii (+Z local), cu abaterea asta in radiani.
@export_range(0.0, 3.14, 0.05) var heading_spread: float = 0.6
@export var seed: int = 1403

var _mmi_gnu: MultiMeshInstance3D
var _mmi_zebra: MultiMeshInstance3D
var _built := false


func _ready() -> void:
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if _built:
		set_physics_process(false)
		return
	_built = true
	_build()
	set_physics_process(false)


func _build() -> void:
	if count <= 0 or Engine.is_editor_hint():
		return
	var gnu_mesh := HerdHazard._animal_mesh_from(HerdHazard.WILDEBEEST_GLB)
	var zebra_mesh := HerdHazard._animal_mesh_from(HerdHazard.ZEBRA_GLB)
	if gnu_mesh == null:
		push_warning("HerdBackdrop: %s nu se incarca; fundalul lipseste" % HerdHazard.WILDEBEEST_GLB)
		return
	if zebra_mesh == null:
		zebra_mesh = gnu_mesh
	# Materialul turmei (atlas + galop in vertex shader), luat de la un
	# HerdHazard temporar ca sa nu existe doua copii ale shader-ului.
	var donor := HerdHazard.new()
	var mat: ShaderMaterial = donor._herd_material(true)
	donor.free()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var sides: Array[float] = []
	if far_side:
		sides.append(1.0)
	if near_side:
		sides.append(-1.0)
	if sides.is_empty():
		return
	var xf_gnu: Array[Transform3D] = []
	var xf_zebra: Array[Transform3D] = []
	var space := get_world_3d().direct_space_state
	var top := global_position.y + 150.0
	for i in count:
		var sgn: float = sides[i % sides.size()]
		var lx := rng.randf_range(-half_x, half_x)
		# Mai desi aproape de drum decat departe (t patrat pe uniform: jumatate
		# din animale in primul sfert al benzii), ca in referinta, unde primul
		# rand e compact si fundalul se rareste.
		var t := rng.randf()
		t = t * t
		var lz := sgn * lerpf(band_near, band_far, t)
		var wp := global_transform * Vector3(lx, 0.0, lz)
		var gy := global_position.y
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(wp.x, top, wp.z), Vector3(wp.x, top - 400.0, wp.z))
		q.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(q)
		if not hit.is_empty():
			gy = float(hit["position"].y)
		var yaw := rng.randf_range(-heading_spread, heading_spread)
		# -Z e „inainte" la mesh-urile din kit; curgerea merge pe +Z local,
		# deci fata spre +Z inseamna yaw PI.
		var basis := Basis(Vector3.UP, PI + yaw)
		var scl := rng.randf_range(0.92, 1.08)
		var xf := Transform3D(basis.scaled(Vector3(scl, scl, scl)),
			Vector3(wp.x, gy, wp.z))
		if rng.randf() < zebra_ratio:
			xf_zebra.append(xf)
		else:
			xf_gnu.append(xf)
	_mmi_gnu = _lot("FundalGnu", gnu_mesh, xf_gnu, mat, rng)
	_mmi_zebra = _lot("FundalZebra", zebra_mesh, xf_zebra, mat, rng)


func _lot(lot_name: String, mesh: Mesh, xfs: Array[Transform3D],
		mat: Material, rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		var still := 0.0 if rng.randf() < gallop_ratio else 1.0
		mm.set_instance_custom_data(i, Color(rng.randf(), still, 0.0, 0.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = lot_name
	mmi.multimesh = mm
	# Transformurile sunt in spatiul LUMII (raza pe teren e globala), ca la
	# HerdHazard — vezi acolo de ce `top_level`.
	mmi.top_level = true
	mmi.transform = Transform3D.IDENTITY
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)
	return mmi
