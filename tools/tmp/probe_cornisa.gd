extends Node
## Masoara profilul cornisei D: cota drumului, buza falezei, panta laterala
## si CURBURA — ca sa aleg locul UNUI singur hero, nu un sir.
const TRACK := "res://scenes/tracks/Track12.tscn"
var _track: Track
var _space: PhysicsDirectSpaceState3D
var _sampler: TrackSideSampler
var _path
var _excluded: Array[RID] = []

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for i in 6:
		await get_tree().physics_frame
	_sampler = _track._sampler
	_path = TrackScenography._Path.new(_sampler)
	_space = _track.get_world_3d().direct_space_state
	for root_name: String in ["DecorManual", "Decor"]:
		var root := _track.get_node_or_null(NodePath(root_name))
		if root == null: continue
		var stack: Array = [root]
		while not stack.is_empty():
			var x = stack.pop_back()
			for c in x.get_children(): stack.append(c)
			var b := x as CollisionObject3D
			if b != null: _excluded.append(b.get_rid())
	print("total=%.1f" % _path.total)
	print("frac | road_y | curb(+1) profil lateral 8/12/16/20/26/34/45 m | dir_change_deg_per_10m")
	var f := 0.985
	while f <= 1.06:
		var st = _path.at(_path.total * fmod(f, 1.0))
		var road: Vector3 = st["pos"]
		var line := "%.3f y=%6.2f | R:" % [f, road.y]
		for d in [8.0, 12.0, 16.0, 20.0, 26.0, 34.0, 45.0]:
			var p := _off(st, 1.0, d)
			line += " %5.1f" % _ground(p.x, p.z, road.y)
		line += " | L:"
		for d in [11.0, 16.0, 24.0, 34.0]:
			var p := _off(st, -1.0, d)
			line += " %5.1f" % _ground(p.x, p.z, road.y)
		# curbura: unghiul intre tangentele la +-12 m
		var sa = _path.at(_path.total * fmod(f, 1.0) - 12.0)
		var sb = _path.at(_path.total * fmod(f, 1.0) + 12.0)
		var ta: Vector3 = sa["right"]; var tb: Vector3 = sb["right"]
		var ang := rad_to_deg(atan2(ta.x, ta.z) - atan2(tb.x, tb.z))
		while ang > 180.0: ang -= 360.0
		while ang < -180.0: ang += 360.0
		line += " | curb=%+6.1f" % ang
		print(line)
		f += 0.004
	get_tree().quit(0)

func _off(st: Dictionary, side: float, dist: float) -> Vector3:
	var road: Vector3 = st["pos"]
	var r: Vector3 = st["right"] * side
	return Vector3(road.x + r.x * dist, road.y, road.z + r.z * dist)

func _ground(wx: float, wz: float, hint: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(wx, hint + 90.0, wz), Vector3(wx, hint - 400.0, wz))
	q.exclude = _excluded
	var hit := _space.intersect_ray(q)
	if hit.is_empty(): return -999.0
	return (hit["position"] as Vector3).y
