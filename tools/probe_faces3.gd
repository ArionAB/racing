extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var arr := mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	print("--- horizontal (|ny|>0.7) area by y band")
	var b := {}
	for i in range(0, idx.size(), 3):
		var a := v[idx[i]]; var q := v[idx[i+1]]; var c := v[idx[i+2]]
		var nn := (q-a).cross(c-a); var ar := nn.length()*0.5
		if ar <= 0.0: continue
		nn = nn.normalized()
		if absf(nn.y) < 0.7: continue
		var y := int(floor((a.y+q.y+c.y)/3.0))
		b[y] = b.get(y,0.0)+ar
	var ys := b.keys(); ys.sort()
	for y in ys: print("  y=%d area=%.1f" % [y, b[y]])
	print("--- footprint at y bands: x/z extents of geometry")
	for lo in [0,5,10,15,20,23]:
		var mn := Vector3(999,0,999); var mx := Vector3(-999,0,-999)
		for p in v:
			if p.y >= lo and p.y < lo+2:
				mn.x = minf(mn.x,p.x); mx.x = maxf(mx.x,p.x); mn.z = minf(mn.z,p.z); mx.z = maxf(mx.z,p.z)
		print("  y %d..%d  x[%.1f..%.1f] z[%.1f..%.1f]" % [lo, lo+2, mn.x, mx.x, mn.z, mx.z])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
