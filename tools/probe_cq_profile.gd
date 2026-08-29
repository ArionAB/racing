extends Node
## Profilul lateral real al rapei pe sectorul pietei: cota terenului la distante
## laterale crescande, pe fractii esantionate. Ca sa asez turnurile pe perete,
## nu in aer si nu pe asfalt.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	var fr := [0.000, 0.005, 0.010, 0.015, 0.020, 0.025, 0.030, 0.035]
	for f in fr:
		var p := c.sample_baked(f * L)
		var p2 := c.sample_baked(fmod(f * L + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var line := "frac=%.3f sosea_y=%.1f  " % [f, p.y]
		for d in [6, 8, 10, 12, 14, 17, 20, 25, 30]:
			var o: Vector3 = p + right * float(d) + Vector3.UP * 40.0
			var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 400.0)
			q.collide_with_areas = false
			var h := space.intersect_ray(q)
			if h.is_empty():
				line += "%dm:-- " % d
			else:
				var nm := str((h.collider as Node).name)
				var tag := "T" if nm.begins_with("Terrain") else "?"
				line += "%dm:%.0f%s " % [d, h.position.y, tag]
		print(line)
	get_tree().quit()
