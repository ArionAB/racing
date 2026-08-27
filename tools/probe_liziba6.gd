extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var verts := PackedVector3Array()
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array): verts.append(v[i])
	# tavanul deasupra culoarului lateral x in [4.5,19.5]
	var ceil_y := INF
	var floor_geo := -INF
	for t in range(verts.size()/3):
		for k in 3:
			var p := verts[t*3+k]
			if p.x < 4.5 or p.x > 19.5: continue
			if absf(p.z) > 12.5: continue
			if p.y > 0.4: ceil_y = minf(ceil_y, p.y)
			else: floor_geo = maxf(floor_geo, p.y)
	print("culoar lateral x 4.5..19.5, |z|<12.5: tavan la y=%.2f, geometrie de podea pana la y=%.2f" % [ceil_y, floor_geo])
	# fatada: unde sunt golurile de intrare pe z = -13.62 / +13.62?
	print("--- fatada z=-13.6, y 0..8, x -21..21 (pas 0.5)")
	var occ := {}
	for t in range(verts.size()/3):
		var a := verts[t*3]; var b := verts[t*3+1]; var c := verts[t*3+2]
		for u in range(0, 13):
			for w in range(0, 13-u):
				var p := a + (b-a)*(u/12.0) + (c-a)*(w/12.0)
				if p.z > -12.6: continue
				if p.y > 8.5: continue
				occ[Vector2i(int(round(p.x*2)), int(round(p.y*2)))] = true
	for yi in range(17, -1, -1):
		var line := ""
		for xi in range(-42, 43): line += "#" if occ.has(Vector2i(xi, yi)) else "."
		print("y%5.1f %s" % [yi/2.0, line])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
