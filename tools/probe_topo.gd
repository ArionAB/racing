extends SceneTree
func _init() -> void:
	for p in ["res://assets/models/cappadocia/rocks/chimney_a.glb",
			"res://assets/models/cappadocia/rocks/chimney_c.glb",
			"res://assets/models/cappadocia/rocks/chimney_mushroom.glb"]:
		var ps := load(p)
		if ps == null:
			print(p, " LIPSA"); continue
		var n: Node = ps.instantiate()
		var st: Array[Node] = [n]
		while st.size() > 0:
			var x: Node = st.pop_back()
			for c in x.get_children(): st.append(c)
			if x is MeshInstance3D:
				var m: Mesh = (x as MeshInstance3D).mesh
				var ab := m.get_aabb()
				print(p.get_file(), " nod=", x.name, " surf=", m.get_surface_count(),
					" aabb_y=", ab.position.y, "..", ab.position.y + ab.size.y)
				for s in m.get_surface_count():
					var a := m.surface_get_arrays(s)
					var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
					var idx: Variant = a[Mesh.ARRAY_INDEX]
					var ys := {}
					for q in v:
						ys[snappedf(q.y, 0.02)] = true
					var k := ys.keys(); k.sort()
					print("   surf", s, " verts=", v.size(),
						" indexed=", idx != null,
						" mat=", m.surface_get_material(s),
						" cote(", k.size(), ")=", k)
		n.queue_free()
	quit()
