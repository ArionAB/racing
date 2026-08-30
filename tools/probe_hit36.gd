extends Node
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var space := t.get_world_3d().direct_space_state
	var i := int(0.36 * n)
	var p: Vector3 = r.baked[i]
	var a: Vector3 = r.baked[(i + 4) % n]
	var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
	var q: Vector3 = p + side * 40.0
	var excl: Array[RID] = []
	for k in 8:
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(q.x, p.y + 250.0, q.z), Vector3(q.x, p.y - 350.0, q.z))
		ray.exclude = excl
		var hit := space.intersect_ray(ray)
		if hit.is_empty(): print("  (gata)"); break
		var col = hit["collider"]
		var chain := str(col.name); var par = col.get_parent(); var d := 0
		while par != null and d < 5:
			chain = str(par.name) + "/" + chain; par = par.get_parent(); d += 1
		print("  hit%d dy=%7.1f  parent_is_track=%s  %s" % [k,
			float(hit["position"].y) - p.y, str(col.get_parent() == t), chain])
		excl.append(hit["rid"])
	get_tree().quit(0)
