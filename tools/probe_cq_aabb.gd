extends SceneTree
func _init() -> void:
	var dirs := ["buildings", "props", "structures", "vehicles"]
	for d in dirs:
		var da := DirAccess.open("res://assets/models/chongqing/" + d)
		if da == null: continue
		for f in da.get_files():
			if not f.ends_with(".glb"): continue
			var ps := load("res://assets/models/chongqing/%s/%s" % [d, f]) as PackedScene
			if ps == null: continue
			var n := ps.instantiate()
			var aabb := AABB()
			var first := true
			var tri := 0
			for m in _meshes(n):
				var a: AABB = (m as MeshInstance3D).get_aabb()
				var t: Transform3D = _rel(m, n)
				a = t * a
				if first: aabb = a; first = false
				else: aabb = aabb.merge(a)
				var mesh := (m as MeshInstance3D).mesh
				if mesh: for s in mesh.get_surface_count(): tri += mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size() / 3
			print("%-14s %-26s size(%6.2f,%6.2f,%6.2f) min(%7.2f,%7.2f,%7.2f) max(%7.2f,%7.2f,%7.2f) tri %d" % [
				d, f, aabb.size.x, aabb.size.y, aabb.size.z,
				aabb.position.x, aabb.position.y, aabb.position.z,
				aabb.end.x, aabb.end.y, aabb.end.z, tri])
			n.free()
	quit()

func _meshes(root: Node) -> Array:
	var out := []
	if root is MeshInstance3D: out.append(root)
	for c in root.get_children(): out.append_array(_meshes(c))
	return out

func _rel(n: Node3D, root: Node) -> Transform3D:
	var t := Transform3D()
	var cur := n
	while cur != null and cur != root:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t
