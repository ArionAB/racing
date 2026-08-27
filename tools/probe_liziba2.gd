extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var mesh := mi.mesh
	var verts := PackedVector3Array()
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	# sectiune verticala: plan z in [-1,1] -> harta (x, y)
	print("--- sectiune z in [-2,2]:  X -21..21, Y 0..25")
	var occ := {}
	for t in range(verts.size() / 3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		for u in range(0, 9):
			for w in range(0, 9 - u):
				var p := a + (b - a) * (u/8.0) + (c - a) * (w/8.0)
				if absf(p.z) > 2.0: continue
				occ[Vector2i(int(round(p.x)), int(round(p.y)))] = true
	var y := 25
	while y >= 0:
		var line := ""
		for x in range(-21, 22): line += "#" if occ.has(Vector2i(x, y)) else "."
		print("y%3d %s" % [y, line])
		y -= 1
	print("--- sectiune x in [-2,2]:  Z -14..14, Y 0..25")
	var occ2 := {}
	for t in range(verts.size() / 3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		for u in range(0, 9):
			for w in range(0, 9 - u):
				var p := a + (b - a) * (u/8.0) + (c - a) * (w/8.0)
				if absf(p.x) > 2.0: continue
				occ2[Vector2i(int(round(p.z)), int(round(p.y)))] = true
	y = 25
	while y >= 0:
		var line := ""
		for z in range(-14, 15): line += "#" if occ2.has(Vector2i(z, y)) else "."
		print("y%3d %s" % [y, line])
		y -= 1
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
