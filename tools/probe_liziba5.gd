extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	# pentru fiecare banda de x de 0.25 m, cate varfuri cu y in [0.3,5.0] (parter)
	var hist := {}
	for t in range(verts.size()/3):
		for k in 3:
			var p := verts[t*3+k]
			if p.y < 0.3 or p.y > 5.0: continue
			if absf(p.z) > 13.7: continue
			var key := int(floor(p.x * 4.0))
			hist[key] = hist.get(key, 0) + 1
	var keys := hist.keys(); keys.sort()
	for k in keys: print("x %6.2f .. %6.2f : %d" % [k/4.0, k/4.0+0.25, hist[k]])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
