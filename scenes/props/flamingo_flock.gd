@tool
class_name FlamingoFlock
extends Node3D
## STOL DE FLAMINGI pe malul lacului de soda (Serengeti, POI G — brief §2 E/G,
## §5 „flamingo.glb / flamingo_wings.glb"). Decor static: UN MultiMesh per
## GLB, in loc de sute de noduri (fiecare nod = un desen; stolul de 150 ar fi
## fost 150 de draw call-uri pentru 1,2 m de pasare la 40 m).
##
## Pasarile se aseaza SINGURE pe linia apei, la rulare: se cauta puncte in
## jurul nodului (raza `radius`) a caror cota de teren e intr-o fereastra fata
## de nivelul apei (`depth_min..depth_max` sub apa = in apa mica, pana la
## `crust_max` peste apa = pe crusta), deci nodul se trage pe mal si stolul isi
## gaseste linia — daca se muta lacul, se muta si flamingii, fara sa ramana
## pasari pe uscat sau in adanc (memoria `terrain-mesh-y-extrapoleaza`: cota
## se ia cu RAZA pe TerrainBody, nu din camp).
##
## Materialul e atlasul comun (`Palette.world_material`), deci stolul nu aduce
## niciun material in plus (garda din tools/probe_decor.gd). Coliziune: niciuna
## (flamingii sunt fantome, ca in `WorldProp.PROP_COLLISION`).

const GLB_STAND := "res://assets/models/serengeti/plants/flamingo.glb"
const GLB_WINGS := "res://assets/models/serengeti/plants/flamingo_wings.glb"

## Cate pasari, in total (stand + cu aripile deschise).
@export_range(1, 600, 1) var count: int = 120
## Raza (m) in jurul nodului in care se cauta linia apei.
@export_range(5.0, 200.0, 1.0) var radius: float = 40.0
## Fereastra de cota fata de apa in care sta o pasare: de la `depth_max` sub
## apa (apa mica, picioarele in apa) pana la `crust_max` peste apa (pe crusta).
@export_range(0.0, 3.0, 0.05) var depth_max: float = 0.6
@export_range(0.0, 5.0, 0.05) var crust_max: float = 1.6
## Fractia cu aripile deschise (a doua stare din kit).
@export_range(0.0, 1.0, 0.05) var wings_fraction: float = 0.25
## Samanta: aceeasi asezare la fiecare rulare (capturile trebuie sa fie
## comparabile intre runde).
@export var seed: int = 1407

var placed: int = 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Terenul e construit de parintele Track in _ready-ul LUI, care vine DUPA
	# al copiilor; corpul de coliziune ajunge in serverul de fizica un cadru
	# mai tarziu. Deci: doua cadre de proces + doua de fizica, apoi razele.
	_build.call_deferred()


func _build() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var track := _find_track()
	if track == null:
		push_warning("FlamingoFlock %s: nu e sub o pista, nimic de asezat" % name)
		return
	var sea_y: float = track._sampler.mean_road_y() + track.sea_level_offset
	var stand_mesh := HerdHazard._animal_mesh_from(GLB_STAND)
	var wings_mesh := HerdHazard._animal_mesh_from(GLB_WINGS)
	if stand_mesh == null:
		push_warning("FlamingoFlock: %s nu se incarca" % GLB_STAND)
		return
	if wings_mesh == null:
		wings_mesh = stand_mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var stand_xf: Array[Transform3D] = []
	var wings_xf: Array[Transform3D] = []
	var space := get_world_3d().direct_space_state
	var origin := global_position
	var tries := 0
	while stand_xf.size() + wings_xf.size() < count and tries < count * 40:
		tries += 1
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radius
		var x := origin.x + cos(a) * r
		var z := origin.z + sin(a) * r
		var g := _ground(space, x, z, track)
		if is_nan(g):
			continue
		var rel := g - sea_y
		if rel < -depth_max or rel > crust_max:
			continue
		# Cu picioarele in apa pasarea sta pe FUND, nu pe suprafata: corpul
		# (1,27 m) ramane oricum deasupra apei de 0,6 m.
		var yaw := rng.randf() * TAU
		var scl := rng.randf_range(0.9, 1.1)
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
		var xf := Transform3D(basis, Vector3(x, g, z))
		if rng.randf() < wings_fraction:
			wings_xf.append(xf)
		else:
			stand_xf.append(xf)
	placed = stand_xf.size() + wings_xf.size()
	if placed == 0:
		push_warning("FlamingoFlock %s: niciun punct pe linia apei in raza de %.0f m (apa la %.2f)"
			% [name, radius, sea_y])
		return
	_make_lot("Stand", stand_mesh, stand_xf)
	_make_lot("Wings", wings_mesh, wings_xf)
	if OS.is_stdout_verbose() or "--flock-report" in OS.get_cmdline_user_args():
		print("FlamingoFlock %s: %d pasari (%d cu aripi) din %d incercari, apa la %.2f"
			% [name, placed, wings_xf.size(), tries, sea_y])


func _make_lot(lot_name: String, mesh: Mesh, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = lot_name
	mmi.multimesh = mm
	# Transformurile sunt in spatiul LUMII (razele au dat cote de lume), deci
	# nodul nu trebuie sa le mai mute o data — aceeasi capcana ca la turma.
	mmi.top_level = true
	mmi.transform = Transform3D.IDENTITY
	mmi.material_override = Palette.world_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)


## Cota solului dintr-o raza pe TerrainBody; NAN daca nu exista teren acolo.
func _ground(space: PhysicsDirectSpaceState3D, x: float, z: float,
		track: Track) -> float:
	var top := global_position.y + 120.0
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, top, z), Vector3(x, top - 400.0, z))
	q.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and guard < 8:
		var col := hit["collider"] as Node
		if col != null and col.name == "TerrainBody":
			return float(hit["position"].y)
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if track._sampler != null:
		return track._sampler.ground_y(x, z)
	return NAN


func _find_track() -> Track:
	var n := get_parent()
	while n != null:
		if n is Track:
			return n as Track
		n = n.get_parent()
	return null
