extends SceneTree
## Ce arata liziba_block pe FIECARE fata, separat. Raportul global 0.42 amesteca
## terasele cu peretii; ce conteaza e ce vede camera de pe o singura latura.
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _f(ps.instantiate())
	var arr := mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var ab := mi.mesh.get_aabb()
	print("aabb pos=%v size=%v" % [ab.position, ab.size])
	var dirs := {"+X": Vector3.RIGHT, "-X": Vector3.LEFT, "+Z": Vector3.BACK,
		"-Z": Vector3.FORWARD, "+Y": Vector3.UP}
	for k in dirs:
		var dir: Vector3 = dirs[k]
		var sa := {}
		var tot := 0.0
		var win_tris := 0
		for i in range(0, idx.size(), 3):
			var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
			var nn := (b-a).cross(c-a); var ar := nn.length()*0.5
			if ar <= 0.0: continue
			if nn.normalized().dot(dir) < 0.7: continue
			var s := clampi(int(((uv[idx[i]]+uv[idx[i+1]]+uv[idx[i+2]])/3.0).x*32.0),0,31)
			sa[s] = sa.get(s,0.0)+ar
			tot += ar
			if s == 30: win_tris += 1
		var ks: Array = sa.keys(); ks.sort()
		var line := "fata %s arie=%.0f  ferestre(30)=%.1f%% tri30=%d  " % [
			k, tot, 100.0*sa.get(30,0.0)/maxf(tot,0.001), win_tris]
		for kk in ks: line += "s%d:%.0f " % [kk, sa[kk]]
		print(line)
	quit()
func _f(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _f(c)
		if r: return r
	return null
