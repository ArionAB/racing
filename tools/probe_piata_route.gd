extends Node
## Cadrul EXACT pe care il foloseste Snapshot --gamecam: route_at(0).baked.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var route := track.route_at(0)
	var pts: PackedVector3Array = route.baked
	var n := pts.size()
	print("route baked n=%d" % n)
	for f: float in [0.005, 0.012, 0.020, 0.030]:
		var idx: int = int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		var right := dir.cross(Vector3.UP).normalized()
		print("frac %.3f idx=%d focus=(%.1f,%.2f,%.1f) dir=(%.3f,%.3f) right=(%.3f,%.3f)"
			% [f, idx, focus.x, focus.y, focus.z, dir.x, dir.z, right.x, right.z])
		for sgn: float in [1.0, -1.0]:
			var vals := ""
			for d: float in [4.0, 8.0, 12.0, 16.0, 20.0, 25.0]:
				var o: Vector3 = focus + right * sgn * d + Vector3.UP * 60.0
				var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 220.0)
				var h := space.intersect_ray(q)
				vals += " %.0f:%s" % [d, ("%.0f" % h.position.y) if not h.is_empty() else "--"]
			print(("    right(+)" if sgn > 0.0 else "    left(-) ") + vals)
	get_tree().quit()
