extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var arr := mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var col: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	# area by (dir, uvslot)
	var dirs := {"+X": Vector3.RIGHT, "-X": Vector3.LEFT, "+Y": Vector3.UP, "-Y": Vector3.DOWN, "+Z": Vector3.BACK, "-Z": Vector3.FORWARD}
	var m := {}
	for i in range(0, idx.size(), 3):
		var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
		var nn := (b-a).cross(c-a)
		var ar := nn.length()*0.5
		if ar <= 0.0: continue
		nn = nn.normalized()
		var best := ""; var bd := -2.0
		for d in dirs:
			var dv: float = nn.dot(dirs[d])
			if dv > bd: bd = dv; best = d
		var u := (uv[idx[i]] + uv[idx[i+1]] + uv[idx[i+2]]) / 3.0
		var key := "%s uv(%.3f,%.3f)" % [best, snappedf(u.x, 0.02), snappedf(u.y, 0.02)]
		m[key] = m.get(key, 0.0) + ar
	var ks := m.keys(); ks.sort()
	for k in ks: print("  %s area=%.1f" % [k, m[k]])
	# vertical extent of the vertical faces (X and Z) -> where are floors
	print("--- vertical-face area by y band (1m), for +Z faces and +X faces")
	var bz := {}; var bx := {}
	for i in range(0, idx.size(), 3):
		var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
		var nn := (b-a).cross(c-a); var ar := nn.length()*0.5
		if ar <= 0.0: continue
		nn = nn.normalized()
		var y := int(floor((a.y+b.y+c.y)/3.0))
		if absf(nn.z) > 0.7: bz[y] = bz.get(y,0.0)+ar
		if absf(nn.x) > 0.7: bx[y] = bx.get(y,0.0)+ar
	var ys := bz.keys(); for k in bx.keys(): if not ys.has(k): ys.append(k)
	ys.sort()
	for y in ys: print("  y=%d  Zfaces=%.1f  Xfaces=%.1f" % [y, bz.get(y,0.0), bx.get(y,0.0)])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
