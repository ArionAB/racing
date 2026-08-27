extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	# histograma de y pentru geometria din culoarul central
	var hist := {}
	for t in range(verts.size()/3):
		for k in 3:
			var p := verts[t*3+k]
			if absf(p.x) > 2.5 or absf(p.z) > 12.0: continue
			hist[int(floor(p.y*10))] = hist.get(int(floor(p.y*10)), 0) + 1
	var keys := hist.keys(); keys.sort()
	print("y in culoarul central |x|<2.5, |z|<12:")
	for k in keys: print("  %.1f .. %.1f : %d varfuri" % [k/10.0, k/10.0+0.1, hist[k]])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
