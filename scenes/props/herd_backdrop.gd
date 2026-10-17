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
## Raza ia DOAR TerrainBody, iar un loc pe care sta un corp de decor (trunchi,
## stanca, termitiera) se respinge: inainte, 157 din 856 de animale stateau in
## acacii si bolovani sau cocotate pe ele, pana la 16 m (#501). Garda e
## `tools/ProbeAnimalOverlap.tscn`.

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
## Ca la HerdHazard: cat din saturatia blanii se stinge spre gri.
@export_range(0.0, 1.0, 0.05) var herd_desat: float = 0.0

## Plafonul de valoare pe blana, pasat mai departe la materialul donorului
## (vezi `HerdHazard._herd_material`). 1.0 = neatins.
@export_range(0.4, 1.0, 0.01) var herd_white_cap: float = 1.0
## Cati dintre ei galopeaza pe loc (shader-ul turmei); restul pasc, nemiscati.
@export_range(0.0, 1.0, 0.05) var gallop_ratio: float = 0.0
## Toti cu fata in directia curgerii (+Z local), cu abaterea asta in radiani.
@export_range(0.0, 3.14, 0.05) var heading_spread: float = 0.6
## Distanta minima intre doua animale, in metri. Fara ea instantele cad una
## peste alta (siluete contopite — exact defectul „masa bruna continua"):
## uniformul nu se fereste de el insusi. Se respinge si se reincearca de
## cateva ori; 0 stinge mecanismul.
@export_range(0.0, 6.0, 0.1) var min_gap: float = 0.0
@export var seed: int = 1403

## Cate locuri se incearca pentru un animal, si din cate cer si `min_gap`.
const PLACE_TRIES := 36
const PLACE_TRIES_GAP := 12
## Amprenta folosita la testul de loc liber (vezi `_footprint_query`).
const FOOTPRINT_RADIUS := 1.2
const FOOTPRINT_HEIGHT := 1.3

var _mmi_gnu: MultiMeshInstance3D
var _mmi_zebra: MultiMeshInstance3D
var _built := false
## Transformurile in lume ale tuturor animalelor, in ordinea asezarii. Pentru
## garda `tools/probe_animal_overlap.gd`: in headless MultiMesh-ul NU le mai
## da inapoi (`get_instance_transform` iese zero — memoria
## `multimesh-masuratoare-moarta`), deci sonda le citeste de aici.
var placed_transforms: Array[Transform3D] = []


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
	donor.herd_desat = herd_desat
	donor.herd_white_cap = herd_white_cap
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
	var placed: Array[Vector2] = []
	var gap2 := min_gap * min_gap
	var body_probe := _footprint_query()
	var dropped := 0
	for i in count:
		var sgn: float = sides[i % sides.size()]
		var lx := 0.0
		var lz := 0.0
		var wp := Vector3.ZERO
		var gy := global_position.y
		var found := false
		# Primele PLACE_TRIES_GAP incercari cer si `min_gap` fata de vecini si
		# loc liber de decor; dupa ele, doar locul liber (mai bine doi gnu
		# apropiati decat un gol, si oricum banda e finita). Un animal care n-a
		# gasit deloc loc liber se sare: mai bine unul lipsa decat unul intr-o
		# acacie.
		for attempt in PLACE_TRIES:
			lx = rng.randf_range(-half_x, half_x)
			# Mai desi aproape de drum decat departe (t patrat pe uniform:
			# jumatate din animale in primul sfert al benzii), ca in referinta,
			# unde primul rand e compact si fundalul se rareste.
			var t := rng.randf()
			t = t * t
			lz = sgn * lerpf(band_near, band_far, t)
			wp = global_transform * Vector3(lx, 0.0, lz)
			gy = _terrain_y(space, wp, top)
			if is_nan(gy):
				gy = global_position.y
			if _occupied(space, body_probe, Vector3(wp.x, gy, wp.z)):
				continue
			if gap2 > 0.0 and attempt < PLACE_TRIES_GAP:
				var ok := true
				for q in placed:
					if Vector2(lx, lz).distance_squared_to(q) < gap2:
						ok = false
						break
				if not ok:
					continue
			found = true
			break
		if not found:
			dropped += 1
			continue
		if gap2 > 0.0:
			placed.append(Vector2(lx, lz))
		var yaw := rng.randf_range(-heading_spread, heading_spread)
		# -Z e „inainte" la mesh-urile din kit; curgerea merge pe +Z local,
		# deci fata spre +Z inseamna yaw PI.
		#
		# PI-ul a fost o vreme si CORECTIA unui asset stramb: gnu-ul si zebra
		# ieseau din `build_serengeti_animals.py` cu capul spre +Z (coarnele
		# masurate la z=+0.93), deci turma de pe drum alerga cu spatele iar
		# fundalul, avand PI in plus, iesea din intamplare corect. Assetul e
		# reparat la sursa (varfurile se rotesc in builder), deci PI-ul ramane
		# aici DOAR pentru ce spune comentariul: intoarcerea de la -Z la +Z.
		var basis := Basis(Vector3.UP, PI + yaw)
		var scl := rng.randf_range(0.92, 1.08)
		var xf := Transform3D(basis.scaled(Vector3(scl, scl, scl)),
			Vector3(wp.x, gy, wp.z))
		placed_transforms.append(xf)
		if rng.randf() < zebra_ratio:
			xf_zebra.append(xf)
		else:
			xf_gnu.append(xf)
	if dropped > 0:
		print("HerdBackdrop %s: %d/%d animale fara loc liber de decor, sarite"
			% [name, dropped, count])
	_mmi_gnu = _lot("FundalGnu", gnu_mesh, xf_gnu, mat, rng)
	_mmi_zebra = _lot("FundalZebra", zebra_mesh, xf_zebra, mat, rng)


## Cota TERENULUI sub punct. Raza veche lua cota din primul corp lovit, deci
## un gnu asezat sub o acacie ateriza pe varful trunchiului (pana la 9,8 m) iar
## unul langa `umarIesire38` pe stanca, la 16 m (#501). Corpurile care nu sunt
## teren se sar, ca in `FlamingoFlock._ground`.
func _terrain_y(space: PhysicsDirectSpaceState3D, wp: Vector3, top: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(wp.x, top, wp.z), Vector3(wp.x, top - 400.0, wp.z))
	q.collide_with_areas = false
	for _i in 8:
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name).begins_with("TerrainBody"):
			return float(hit["position"].y)
		q.exclude = q.exclude + [hit["rid"]]
	return NAN


## Amprenta unui animal ca cilindru vertical: raza ~ jumatate din lungimea
## gnu-ului (2,4 m) stransa putin — yaw-ul se trage DUPA alegerea locului, deci
## forma nu poate depinde de el. Pleaca la 0,2 m peste sol, ca panta sa nu
## atinga terenul (care oricum se sare dupa nume).
func _footprint_query() -> PhysicsShapeQueryParameters3D:
	var cyl := CylinderShape3D.new()
	cyl.radius = FOOTPRINT_RADIUS
	cyl.height = FOOTPRINT_HEIGHT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cyl
	q.collide_with_areas = false
	return q


## Locul e ocupat de un corp care nu e teren: trunchi, stanca, termitiera,
## cort, sosea. Decorul fara coliziune (iarba, tufe) nu conteaza — prin el se
## trece, si un gnu in iarba e chiar locul lui.
func _occupied(space: PhysicsDirectSpaceState3D,
		q: PhysicsShapeQueryParameters3D, at: Vector3) -> bool:
	q.transform = Transform3D(Basis.IDENTITY,
		at + Vector3.UP * (0.2 + FOOTPRINT_HEIGHT * 0.5))
	for r in space.intersect_shape(q, 8):
		var col := r["collider"] as Node
		if col is StaticBody3D and not String(col.name).begins_with("TerrainBody"):
			return true
	return false


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
