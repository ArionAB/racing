extends SceneTree
## Ce vertex colors are huayna_picchu DUPA ce trece prin WorldProp?
## Ipoteza de verificat: AO-ul din .glb (0.23..0.94) ajunge sau nu in scena.
func _initialize() -> void:
	var sc: PackedScene = load("res://scenes/props/WorldProp.tscn")
	var wp := sc.instantiate()
	wp.set("model", load("res://assets/models/machupicchu/rocks/huayna_picchu.glb"))
	wp.set("auto_collision", false)
	get_root().add_child(wp)
	await process_frame
	await process_frame
	_walk(wp)
	quit()

func _walk(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		var m := mi.mesh
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var raw: Variant = arr[Mesh.ARRAY_COLOR]
			if raw is PackedColorArray and (raw as PackedColorArray).size() > 0:
				var cols: PackedColorArray = raw
				var rs: Array[float] = []
				for c in cols: rs.append(c.r)
				rs.sort()
				var q = func(f): return rs[clampi(int(rs.size()*f),0,rs.size()-1)]
				print("%s surf%d: vcol R p10=%.2f p50=%.2f p90=%.2f (n=%d)" % [mi.name, s, q.call(0.1), q.call(0.5), q.call(0.9), rs.size()])
			else:
				print("%s surf%d: FARA vertex colors in scena" % [mi.name, s])
			var mat := mi.material_override if mi.material_override != null else m.surface_get_material(s)
			if mat is StandardMaterial3D:
				var sm: StandardMaterial3D = mat
				print("   mat: vcol_as_albedo=%s albedo=%s triplanar=%s" % [sm.vertex_color_use_as_albedo, sm.albedo_color, sm.uv1_triplanar])
			else:
				print("   mat: ", mat)
	for c in n.get_children():
		_walk(c)
