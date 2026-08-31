extends SceneTree
## Profilul de raza al unui GLB din kit, BRUT, inainte de orice deformare.
func _initialize() -> void:
	for f in ["chimney_a","chimney_b","chimney_c","chimney_d","chimney_mushroom","chimney_triple"]:
		var ps: PackedScene = load("res://assets/models/cappadocia/rocks/%s.glb" % f)
		var nd: Node = ps.instantiate()
		var mi := _first(nd)
		if mi == null:
			print(f, ": fara mesh"); continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ab := mi.mesh.get_aabb()
		var h: float = maxf(ab.size.y, 0.001); var y0: float = ab.position.y
		var cx: float = ab.position.x + ab.size.x*0.5
		var cz: float = ab.position.z + ab.size.z*0.5
		const N := 20
		var rad := PackedFloat32Array(); rad.resize(N)
		for tri in v.size()/3:
			for e in 3:
				var a := v[tri*3+e]; var b := v[tri*3+(e+1)%3]
				var ta: float = clampf((a.y-y0)/h,0.0,0.9999)
				var tb: float = clampf((b.y-y0)/h,0.0,0.9999)
				var ka := int(ta*N); var kb := int(tb*N)
				if ka > kb: var sw := ka; ka = kb; kb = sw
				for k in range(ka, kb+1):
					var tm: float = (float(k)+0.5)/float(N)
					var u: float = 0.0
					if not is_equal_approx(ta,tb): u = clampf((tm-ta)/(tb-ta),0.0,1.0)
					var px: float = lerpf(a.x,b.x,u)-cx
					var pz: float = lerpf(a.z,b.z,u)-cz
					var r: float = sqrt(px*px+pz*pz)
					if r > rad[k]: rad[k] = r
		var line := ""
		for k in N: line += "%.2f " % rad[k]
		print("%-18s h=%.2f  tri=%d" % [f, h, v.size()/3])
		print("   t=0..1: ", line)
	quit()

func _first(n: Node) -> MeshInstance3D:
	var st: Array[Node] = [n]; var best: MeshInstance3D = null; var bf := 0
	while not st.is_empty():
		var x: Node = st.pop_back()
		for c in x.get_children(): st.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		var f: int = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		if f > bf: bf = f; best = mi
	return best
