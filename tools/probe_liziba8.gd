extends SceneTree
## Ce e in model la z in [-12,-4], y in [0,2], toate x-urile?
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	print("--- z in [-12,-3], y in [-0.2, 2.0]: X -21..21 pas 0.5 x Z -12..-3 pas 0.5")
	var occ := {}
	for t in range(verts.size()/3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		for u in range(0, 17):
			for w in range(0, 17-u):
				var p := a + (b-a)*(u/16.0) + (c-a)*(w/16.0)
				if p.z < -12.2 or p.z > -2.8: continue
				if p.y < -0.25 or p.y > 2.0: continue
				occ[Vector2i(int(round(p.x*2)), int(round(p.z*2)))] = true
	for zi in range(-24, -5):
		var line := ""
		for xi in range(-42, 43): line += "#" if occ.has(Vector2i(xi, zi)) else "."
		print("z%6.1f %s" % [zi/2.0, line])
	# si ce cota are podeaua in mijloc
	var lo := INF; var hi := -INF
	for t in range(verts.size()/3):
		for k in 3:
			var p := verts[t*3+k]
			if absf(p.x) < 2.0 and p.z > -12.0 and p.z < -4.0:
				lo = minf(lo, p.y); hi = maxf(hi, p.y)
	print("in |x|<2, z -12..-4: y de la %.2f la %.2f" % [lo, hi])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
