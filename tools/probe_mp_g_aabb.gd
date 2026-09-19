extends SceneTree
func _init() -> void:
	for m in ["structures/inca_wall_a", "structures/inca_wall_b", "structures/inca_wall_c",
			"plants/polylepis_a", "plants/polylepis_b", "rocks/moss_boulder_a",
			"rocks/moss_boulder_b", "rocks/moss_boulder_c", "structures/trail_marker",
			"structures/rope_rail", "plants/tree_fern"]:
		var ps := load("res://assets/models/machupicchu/%s.glb" % m) as PackedScene
		var n := ps.instantiate()
		var boxes: Array = []
		_walk(n, Transform3D.IDENTITY, boxes)
		for b in boxes:
			var a: AABB = b[1]
			print("%s | %s | y %.3f..%.3f | x %.3f..%.3f | z %.3f..%.3f" % [
				m, b[0], a.position.y, a.end.y, a.position.x, a.end.x,
				a.position.z, a.end.z])
		n.free()
	quit()

func _walk(n: Node, t: Transform3D, out: Array) -> void:
	var tt := t
	if n is Node3D:
		tt = t * (n as Node3D).transform
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			out.append([str(n.name), tt * mi.mesh.get_aabb()])
	for c in n.get_children():
		_walk(c, tt, out)
