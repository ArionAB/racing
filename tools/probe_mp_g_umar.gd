extends Node
## Profilul FIN al umarului pe partea care cade, in felia G: cota solului din
## 0,5 in 0,5 m de la muchie pana la 20 m. Raspunde la o intrebare: exista
## destul gol ca zidul de sprijin sa aiba o FATA vizibila, si de la ce distanta?
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
	print("; frac | partea care cade | cota fata de drum la 6.5 7 8 9 10 11 12 14 16 18 20 m de ax")
	var f := 0.740
	while f <= 0.920:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var dl := _sol(p + s * -20.0) - p.y
		var dr := _sol(p + s * 20.0) - p.y
		var sgn := -1.0 if dl < dr else 1.0
		var row: Array[String] = []
		for off: float in [6.5, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0, 18.0, 20.0]:
			row.append("%+5.1f" % (_sol(p + s * sgn * off) - p.y))
		print("; %.3f  %s  %s" % [f, "-side" if sgn < 0 else "+side", " ".join(row)])
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
