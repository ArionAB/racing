extends Node
func _ready() -> void:
	var sc := load("res://assets/models/cappadocia/rocks/red_mesa.glb") as PackedScene
	var n := sc.instantiate()
	add_child(n)
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children(): stack.append(c)
		var mi := nd as MeshInstance3D
		if mi != null and mi.mesh != null:
			var ab := mi.mesh.get_aabb()
			print("%s : aabb pos=%s size=%s  surfaces=%d" % [
				mi.name, str(ab.position), str(ab.size), mi.mesh.get_surface_count()])
			for s in mi.mesh.get_surface_count():
				print("   surf %d tris=%d" % [s,
					mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size() / 3])
	get_tree().quit(0)
