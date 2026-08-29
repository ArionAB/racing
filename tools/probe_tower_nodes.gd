extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/tower_silhouette_b.glb") as PackedScene
	var r := ps.instantiate()
	_walk(r, 0)
	quit()
func _walk(n: Node, d: int) -> void:
	var s := ""
	for i in d: s += "  "
	var extra := ""
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		extra = " MESH aabb=%v vis=%s xform_origin=%v" % [mi.mesh.get_aabb().size, str(mi.visible), mi.transform.origin]
	elif n is VisualInstance3D:
		extra = " VIS aabb=%v" % (n as VisualInstance3D).get_aabb().size
	print("%s%s [%s]%s" % [s, n.name, n.get_class(), extra])
	for c in n.get_children(): _walk(c, d + 1)
