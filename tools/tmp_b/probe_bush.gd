extends SceneTree
func _init() -> void:
	for p in ["res://assets/models/plants/broadleaf_shrub.glb", "res://assets/models/cappadocia/plants/shrub_dry.glb",
			"res://assets/models/stromboli/plants/caper_bush.glb", "res://assets/models/plants/tropical_shrub.glb",
			"res://assets/models/plants/alpine_shrub.glb", "res://assets/models/stromboli/plants/ginestra_bush.glb"]:
		var ps := load(p) as PackedScene
		if ps == null:
			print(p, " NU se incarca"); continue
		var root := ps.instantiate() as Node3D
		var box := Track.model_aabb(root)
		var hist := {}
		var tris := 0
		var stack: Array[Node] = [root]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			for k in n.get_children(): stack.append(k)
			if n is MeshInstance3D:
				var mi := n as MeshInstance3D
				for s in mi.mesh.get_surface_count():
					var arr := mi.mesh.surface_get_arrays(s)
					var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
					var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
					tris += (idx.size() if idx.size() > 0 else uv.size()) / 3
					for u in uv:
						var sl := int(floor(u.x * 32.0)); hist[sl] = hist.get(sl, 0) + 1
		print("%s  size=(%.2f, %.2f, %.2f) y0=%.2f tris=%d slots=%s" % [p.get_file(), box.size.x, box.size.y, box.size.z, box.position.y, tris, str(hist)])
		root.free()
	quit(0)
