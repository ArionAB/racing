extends Node3D
func _ready() -> void:
	var t := load("res://scenes/tracks/Track12.tscn").instantiate()
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	for p in [Vector3(25,5,196), Vector3(26,5,195), Vector3(28,5,195), Vector3(244,26,89)]:
		var sh := SphereShape3D.new(); sh.radius = 5.0
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = sh; q.transform = Transform3D(Basis(), p)
		q.collide_with_bodies = true
		var res := space.intersect_shape(q, 64)
		print("=== punct ", p, " -> ", res.size(), " forme")
		var seen := {}
		for r in res:
			var c = r.collider
			var path := String(c.get_path()) if is_instance_valid(c) else "?"
			if seen.has(path): continue
			seen[path] = true
			print("   ", path, "  @", c.global_position)
	get_tree().quit()
