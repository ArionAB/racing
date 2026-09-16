extends Node
## Profilul terenului pe AMBELE parti in felia G, ca sa se vada daca rapele de
## cornisa 5-8 chiar taie ceva si pe ce parte. Cifrele sunt cote RELATIVE la
## sosea, din coliziunea reala (TerrainBody), din 2 in 2 m pana la 24 m.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _rid: RID = RID()
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	var n := _track.baked.size()
	var offs: Array[float] = [4.0, 6.0, 7.0, 8.0, 10.0, 12.0, 16.0, 20.0, 24.0]
	var head: Array[String] = []
	for o in offs:
		head.append("%5.0f" % o)
	print("; frac  half   -side(%s)  |  +side(%s)" % [" ".join(head), " ".join(head)])
	var f := 0.735
	while f <= 0.925:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var l: Array[String] = []
		var r: Array[String] = []
		for o in offs:
			l.append("%+5.1f" % (_sol(p + s * -o) - p.y))
			r.append("%+5.1f" % (_sol(p + s * o) - p.y))
		print("; %.3f  %4.1f  %s  |  %s" % [f, half, " ".join(l), " ".join(r)])
		f += 0.005
	get_tree().quit(0)

func _sol(q: Vector3) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var sp := _track.get_world_3d().direct_space_state
	var pr := PhysicsRayQueryParameters3D.create(
		Vector3(q.x, _sus, q.z), Vector3(q.x, _sus - 1200.0, q.z))
	pr.collide_with_areas = false
	var hit: Dictionary = sp.intersect_ray(pr)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		pr.exclude = pr.exclude + [hit["rid"]]
		hit = sp.intersect_ray(pr)
		g += 1
	return float(hit["position"].y) if not hit.is_empty() else -999.0
