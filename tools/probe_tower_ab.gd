extends SceneTree
func _init() -> void:
	for nm in ["tower_silhouette_a","tower_silhouette_b","tower_silhouette_c"]:
		var ps := load("res://assets/models/chongqing/buildings/%s.glb" % nm) as PackedScene
		var mi: MeshInstance3D = _f(ps.instantiate())
		var ab := mi.mesh.get_aabb()
		var xf := mi.transform
		print("%s aabb_pos=%v size=%v  mi_xform_origin=%v scale=%v" % [nm, ab.position, ab.size, xf.origin, xf.basis.get_scale()])
	quit()
func _f(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _f(c)
		if r: return r
	return null
