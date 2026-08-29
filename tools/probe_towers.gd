extends SceneTree
func _init() -> void:
	for name in ["tower_silhouette_a","tower_silhouette_b","tower_silhouette_c"]:
		var ps := load("res://assets/models/chongqing/buildings/%s.glb" % name) as PackedScene
		var mi: MeshInstance3D = _find(ps.instantiate())
		var arr := mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var aabb := mi.mesh.get_aabb()
		print("=== %s  size=%v" % [name, aabb.size])
		var slotarea := {}
		var roof := 0.0
		var wall := 0.0
		for i in range(0, idx.size(), 3):
			var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
			var nn := (b-a).cross(c-a); var ar := nn.length()*0.5
			if ar <= 0.0: continue
			nn = nn.normalized()
			if absf(nn.y) > 0.7: roof += ar
			else: wall += ar
			var u := (uv[idx[i]] + uv[idx[i+1]] + uv[idx[i+2]]) / 3.0
			var s := int(u.x * 32.0)
			slotarea[s] = slotarea.get(s, 0.0) + ar
		print("   orizontal(acoperis+plansee)=%.1f  vertical(fatade)=%.1f  raport fatada/acoperis=%.2f" % [roof, wall, wall/roof])
		var ks := slotarea.keys(); ks.sort()
		for k in ks: print("      slot %d: %.1f" % [k, slotarea[k]])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
