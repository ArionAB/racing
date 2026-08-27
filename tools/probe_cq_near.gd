extends Node
## Ce corp static sta cel mai aproape de un punct dat, si cine e.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var pts: Array[Vector3] = [Vector3(244,25,94), Vector3(246,26,91), Vector3(26,5,196), Vector3(30,5,193)]
	var space := get_viewport().world_3d.direct_space_state
	var sh := SphereShape3D.new()
	sh.radius = 4.0
	var par := PhysicsShapeQueryParameters3D.new()
	par.shape = sh
	for p in pts:
		par.transform = Transform3D(Basis.IDENTITY, p)
		var res := space.intersect_shape(par, 12)
		print("langa %s:" % p)
		for hit: Dictionary in res:
			var col := hit.get("collider") as Node
			if col == null: continue
			var parts: Array[String] = []
			var cur := col
			for _k in 8:
				if cur == null: break
				parts.push_front(str(cur.name))
				if str(cur.name) == "Track12": break
				cur = cur.get_parent()
			var extra := ""
			if col is Node3D:
				extra = " @ %s" % (col as Node3D).global_position
				for c2 in col.get_children():
					if c2 is CollisionShape3D:
						var shp := (c2 as CollisionShape3D).shape
						if shp is BoxShape3D:
							extra += "  box %s" % (shp as BoxShape3D).size
			print("   %s%s" % ["/".join(parts), extra])
	get_tree().quit()
