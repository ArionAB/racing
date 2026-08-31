extends SceneTree
func _initialize() -> void:
	var want := ["hornUmbra8"]
	var packed: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		var sh := n as ChimneyShape
		if sh == null or not (String(sh.name) in want): continue
		var st2: Array[Node] = [sh]
		while not st2.is_empty():
			var x: Node = st2.pop_back()
			for c in x.get_children(): st2.append(c)
			var mi := x as MeshInstance3D
			if mi == null or mi.mesh == null: continue
			var arr: Array = mi.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ab := mi.mesh.get_aabb()
			var h: float = maxf(ab.size.y,0.001); var y0: float = ab.position.y
			var cx: float = ab.position.x+ab.size.x*0.5
			var cz: float = ab.position.z+ab.size.z*0.5
			const N := 20
			var rad := PackedFloat32Array(); rad.resize(N)
			for tri in v.size()/3:
				for e in 3:
					var a := v[tri*3+e]; var b := v[tri*3+(e+1)%3]
					var ta: float = clampf((a.y-y0)/h,0.0,0.9999)
					var tb: float = clampf((b.y-y0)/h,0.0,0.9999)
					var ka := int(ta*N); var kb := int(tb*N)
					if ka>kb: var sw:=ka; ka=kb; kb=sw
					for k in range(ka,kb+1):
						var tm: float=(float(k)+0.5)/float(N)
						var u: float=0.0
						if not is_equal_approx(ta,tb): u=clampf((tm-ta)/(tb-ta),0.0,1.0)
						var px: float=lerpf(a.x,b.x,u)-cx
						var pz: float=lerpf(a.z,b.z,u)-cz
						var r: float=sqrt(px*px+pz*pz)
						if r>rad[k]: rad[k]=r
			var line := ""
			for k in N: line += "%.2f " % rad[k]
			var sc: Vector3 = mi.global_transform.basis.get_scale()
			print("%s  tri=%d  h=%.2f  scale=%.2f  aabb=%.2f x %.2f" % [mi.name, v.size()/3, h, sc.x, ab.size.x, ab.size.z])
			print("   ", line)
	quit()
