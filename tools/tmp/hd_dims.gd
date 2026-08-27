extends Node
func _ready() -> void:
	for path in ["res://assets/models/chongqing/structures/hongya_dong.glb",
			"res://assets/models/chongqing/buildings/liziba_block.glb", "res://assets/models/chongqing/buildings/restaurant_front.glb", "res://assets/models/chongqing/buildings/tower_silhouette_a.glb", "res://assets/models/chongqing/buildings/shophouse_b.glb"]:
		var sc := (load(path) as PackedScene).instantiate()
		var aabb := AABB()
		var first := true
		var tris := 0
		var stack: Array = [sc]
		while not stack.is_empty():
			var n = stack.pop_back()
			for c in n.get_children(): stack.append(c)
			var mi := n as MeshInstance3D
			if mi != null and mi.mesh != null:
				var a: AABB = mi.get_aabb()
				a = mi.transform * a
				if first: aabb = a; first = false
				else: aabb = aabb.merge(a)
				for s in mi.mesh.get_surface_count():
					var arr := mi.mesh.surface_get_arrays(s)
					if arr[Mesh.ARRAY_INDEX] != null:
						tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		print("%s pos=%s size=%s tris=%d" % [path.get_file(), aabb.position, aabb.size, tris])
	get_tree().quit(0)
