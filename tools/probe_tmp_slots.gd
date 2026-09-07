extends Node
func _ready() -> void:
	var ps := load("res://scenes/tracks/Track14.tscn") as PackedScene
	var t := ps.instantiate()
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var z := t.get_node("DecorManual/ZoneB_RaulDeGnu")
	var seen := 0
	for c in z.get_children():
		if seen >= 3: break
		if not str(c.name).begins_with("acacie"): continue
		seen += 1
		var stack: Array[Node] = [c]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for k in n.get_children(): stack.append(k)
			if n is MeshInstance3D:
				var mi := n as MeshInstance3D
				var hist := {}
				for s in mi.mesh.get_surface_count():
					var uv: PackedVector2Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_TEX_UV]
					for u in uv:
						var sl := int(floor(u.x * 32.0))
						hist[sl] = hist.get(sl, 0) + 1
				print("%s %s %s mat=%s" % [c.name, c.scene_file_path.get_file(), str(hist), str(mi.material_override)])
	get_tree().quit(0)
