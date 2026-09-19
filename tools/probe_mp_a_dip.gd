extends Node
## Sonda de unica folosinta (runda 9, POI A).
##
## Prima intrebare: de ce difera cota de coliziune de campul neted la
## (-114.2, 126.8)? `probe_manual` citeste `_sampler.ground_y` si vede -0.26;
## generatorul citeste raycast pe TerrainBody si vede -2.85.
## RASPUNS MASURAT: niciuna nu „minte" — acolo terenul chiar COBOARA, de la
## -0.22 la -5.25 pe vreo 12 m, iar campul neted ramane in urma pe rampa cu
## pana la 2,4 m. Deci piesa sta corect pe sol, dar sta pe o RAMPA.
##
## A doua intrebare, cea care conteaza pentru compozitie: pe ce interval
## lateral e platou si de unde incepe rampa, pe FIECARE fractie a zonei si
## la COTELE PE CARE LE FOLOSESC EFECTIV (14-52 m), nu la ±40/55/70/90 cum
## esantionase `--survey`. Un bloc de camere are 12-20 m latura; daca prinde
## rampa, camerele lui ies la cote diferite si zidul se rupe.

const TRACK := "res://scenes/tracks/Track15.tscn"

var _t: Track
var _rid: RID = RID()
var _sus := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _t.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	for c in _t.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	var lats: Array[float] = [-52.0, -44.0, -35.0, -28.0, -22.0, -16.0,
		16.0, 23.0, 30.0, 38.0, 45.0, 52.0, 58.0]
	var head := "; frac  "
	for l in lats:
		head += "%7.0f" % l
	print(head + "   (cota fata de sosea, raycast pe TerrainBody)")
	var f := -0.012
	while f <= 0.0505:
		var i := _idx(f)
		var p: Vector3 = _t.baked[i]
		var s: Vector3 = _t._side_at(i)
		var row := "; %+.4f" % f
		for l in lats:
			var q := p + s * l
			row += "%7.1f" % (_ray(q.x, q.z) - p.y)
		print(row)
		f += 0.002
	get_tree().quit(0)


func _idx(frac: float) -> int:
	var n := _t.baked.size()
	var i := int(round(frac * float(n)))
	return ((i % n) + n) % n


func _ray(x: float, z: float) -> float:
	var space := _t.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus, z), Vector3(x, _sus - 1200.0, z))
	q.collide_with_areas = false
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	return -999.0 if hit.is_empty() else float(hit["position"].y)
