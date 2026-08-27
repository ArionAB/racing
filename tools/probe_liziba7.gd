extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	print("--- capatul x = -20.3: Z -14..14, Y 0..8")
	var occ := {}
	for t in range(verts.size()/3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		for u in range(0, 13):
			for w in range(0, 13-u):
				var p := a + (b-a)*(u/12.0) + (c-a)*(w/12.0)
				if p.x > -18.5: continue
				if p.y > 8.5: continue
				occ[Vector2i(int(round(p.z*2)), int(round(p.y*2)))] = true
	for yi in range(17, -1, -1):
		var line := ""
		for zi in range(-28, 29): line += "#" if occ.has(Vector2i(zi, yi)) else "."
		print("y%5.1f %s" % [yi/2.0, line])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
