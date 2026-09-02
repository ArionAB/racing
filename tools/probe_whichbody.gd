extends Node
## Corpurile statice generate direct sub Track13, in ordine, cu AABB-ul lor.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	for c in t.get_children():
		if not (c is StaticBody3D): continue
		var owner_hint := ""
		for m in c.get_children():
			if m is CollisionShape3D and m.shape is ConcavePolygonShape3D:
				var f: PackedVector3Array = (m.shape as ConcavePolygonShape3D).get_faces()
				if f.size() == 0: continue
				var mn := f[0]; var mx := f[0]
				for v in f:
					mn = mn.min(v); mx = mx.max(v)
				owner_hint += " tris=%d aabb y[%.1f..%.1f] x[%.0f..%.0f] z[%.0f..%.0f]" % [
					f.size()/3, mn.y, mx.y, mn.x, mx.x, mn.z, mx.z]
		print("%s%s" % [c.name, owner_hint])
	get_tree().quit(0)
