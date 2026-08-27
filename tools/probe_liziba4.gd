extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	# ce e la x in [2.5,4.5] si z in [-11,-9]?
	for zone in [[2.5,4.5,-11.0,-9.0,"obstacol +x z-10"], [-4.5,-2.5,-11.0,-9.0,"obstacol -x z-10"], [4.5,6.5,-1.0,1.0,"stalp x+5.5"], [-21.0,-19.0,-1.0,1.0,"perete x-20"]]:
		var lo := Vector3(INF,INF,INF); var hi := Vector3(-INF,-INF,-INF); var cnt := 0
		for t in range(verts.size()/3):
			for k in 3:
				var p := verts[t*3+k]
				if p.x >= zone[0] and p.x <= zone[1] and p.z >= zone[2] and p.z <= zone[3]:
					lo = Vector3(minf(lo.x,p.x),minf(lo.y,p.y),minf(lo.z,p.z))
					hi = Vector3(maxf(hi.x,p.x),maxf(hi.y,p.y),maxf(hi.z,p.z)); cnt += 1
		print("%s: %d vf, x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f" % [zone[4],cnt,lo.x,hi.x,lo.y,hi.y,lo.z,hi.z])
	# cota tavanului deasupra axei centrale
	var ceil_y := INF
	for t in range(verts.size()/3):
		for k in 3:
			var p := verts[t*3+k]
			if absf(p.x) < 2.5 and absf(p.z) < 12.0 and p.y > 0.5:
				ceil_y = minf(ceil_y, p.y)
	print("cea mai joasa geometrie peste axa centrala (|x|<2.5, |z|<12, y>0.5): %.2f" % ceil_y)
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
