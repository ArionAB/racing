extends Node
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus_y := 0.0
func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var n := _track.baked.size()
	# candidati de gara: rama de dincolo, dar DEPARTE de drumul de la z=-104
	print("cand   x      z     sol    dist_margine_drum")
	for xk: float in [-205.0, -196.0, -188.0, -180.0, -172.0, -164.0]:
		for zk: float in [-121.0, -118.0, -115.0, -112.0]:
			var lo := 1e9
			for j in n:
				var bp := _track.baked[j]
				var dd: float = Vector2(bp.x - xk, bp.z - zk).length() - _track.width_at_index(j) - 4.0
				lo = minf(lo, dd)
			print("  (%.0f,%.0f) sol=%+.1f  gol=%.1f" % [xk, zk, _sol(xk, zk), lo])
	get_tree().quit(0)
func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus_y, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	if r.is_empty(): return -999.0
	return float((r["position"] as Vector3).y)
