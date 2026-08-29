extends SceneTree
func _init() -> void:
	for nm in ["tower_silhouette_a","tower_silhouette_b","tower_silhouette_c","liziba_block","shophouse_a"]:
		var ps := load("res://assets/models/chongqing/buildings/%s.glb" % nm) as PackedScene
		if ps == null: continue
		var mi: MeshInstance3D = _f(ps.instantiate())
		if mi == null: continue
		var ab := mi.mesh.get_aabb()
		var arr := mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var dirs := {"+X": Vector3.RIGHT, "+Z": Vector3.BACK, "+Y": Vector3.UP}
		var out := "%s aabb_size=%v  " % [nm, ab.size]
		for k in dirs:
			var dir: Vector3 = dirs[k]
			var tot := 0.0; var win := 0.0
			for i in range(0, idx.size(), 3):
				var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
				var nn := (b-a).cross(c-a); var ar := nn.length()*0.5
				if ar <= 0.0: continue
				if nn.normalized().dot(dir) < 0.7: continue
				var s := clampi(int(((uv[idx[i]]+uv[idx[i+1]]+uv[idx[i+2]])/3.0).x*32.0),0,31)
				tot += ar
				if s == 30: win += ar
			out += "%s:arie=%.0f fer=%.1f%%  " % [k, tot, 100.0*win/maxf(tot,0.001)]
		print(out)
	quit()
func _f(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _f(c)
		if r: return r
	return null
