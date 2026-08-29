extends Node
## Profilul REAL al terenului lateral la piata Kuixinglou, prin raycast.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var path := track.get_node("Path") as Path3D
	var c: Curve3D = path.curve
	var L := c.get_baked_length()
	print("baked_length=%.1f" % L)
	for f: float in [0.003, 0.008, 0.012, 0.018, 0.025, 0.032]:
		var s: float = f * L
		var p := c.sample_baked(s)
		var p2 := c.sample_baked(minf(s + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var line := "frac %.3f  road=(%.1f,%.2f,%.1f)  " % [f, p.x, p.y, p.z]
		# probe both sides to find the ravine side
		for sgn: float in [1.0, -1.0]:
			var vals := ""
			for d: float in [4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 20.0, 25.0]:
				var o: Vector3 = p + right * sgn * d + Vector3.UP * 40.0
				var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 200.0)
				var h := space.intersect_ray(q)
				vals += " %.0f:%s/%s" % [d, ("%.0f" % h.position.y) if not h.is_empty() else "--", str(h.collider.name).substr(0,10) if not h.is_empty() else "-"]
			line += ("\n    right(+)" if sgn > 0.0 else "\n    left(-) ") + vals
		print(line)
	get_tree().quit()
