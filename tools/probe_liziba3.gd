extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	print("--- parter: geometrie cu y in [1.0, 4.0], grila 0.5m  X -21..21 (pas .5), Z -14..14")
	var occ := {}
	for t in range(verts.size() / 3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		for u in range(0, 13):
			for w in range(0, 13 - u):
				var p := a + (b - a) * (u/12.0) + (c - a) * (w/12.0)
				if p.y < 1.0 or p.y > 4.0: continue
				occ[Vector2i(int(round(p.x*2)), int(round(p.z*2)))] = true
	for zi in range(-28, 29):
		var line := ""
		for xi in range(-42, 43): line += "#" if occ.has(Vector2i(xi, zi)) else "."
		print("z%6.1f %s" % [zi/2.0, line])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
