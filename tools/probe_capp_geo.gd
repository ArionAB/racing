extends SceneTree
func _init() -> void:
	for m in ["chimney_a","chimney_b","chimney_c","chimney_d","chimney_mushroom",
			"chimney_triple","cracked_chimney_a","cracked_chimney_b",
			"cracked_chimney_c","cave_house_a"]:
		var ps := load("res://assets/models/cappadocia/rocks/%s.glb" % m) as PackedScene
		if ps == null:
			ps = load("res://assets/models/cappadocia/props/%s.glb" % m) as PackedScene
		if ps == null:
			print(m, " lipseste"); continue
		var n := ps.instantiate()
		var stack: Array[Node] = [n]
		var tris := 0
		var aabb := AABB()
		var first := true
		var ys := PackedFloat32Array()
		while not stack.is_empty():
			var nd: Node = stack.pop_back()
			for c in nd.get_children(): stack.append(c)
			var mi := nd as MeshInstance3D
			if mi == null or mi.mesh == null: continue
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				tris += v.size() / 3
				for i in v.size(): ys.append(v[i].y)
			var a := mi.transform * mi.mesh.get_aabb()
			if first: aabb = a; first = false
			else: aabb = aabb.merge(a)
		# cate cote distincte de vertex (rezolutia pe verticala)
		var uniq := {}
		for y in ys: uniq[snappedf(y, 0.05)] = true
		print("%-20s h=%.2f  tri=%d  cote distincte(5cm)=%d  y %.2f..%.2f" % [
			m, aabb.size.y, tris, uniq.size(), aabb.position.y,
			aabb.position.y + aabb.size.y])
		n.free()
	quit()
