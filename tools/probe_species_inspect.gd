extends SceneTree
## Inspecteaza un GLB de specie: noduri, suprafete, triunghiuri, componente conexe (ca MeshForest).
##   godot --headless --path . --script res://tools/probe_species_inspect.gd -- --glb=res://assets/models/angkor/plants/sugar_palm.glb
func _initialize() -> void:
	var path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--glb="):
			path = a.trim_prefix("--glb=")
	var root := (load(path) as PackedScene).instantiate()
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			for si in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(si)
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				var comps := MeshForest._components(arr)
				var tris: PackedInt32Array = comps["tris"]
				var mx := 0
				for t in tris:
					mx = maxi(mx, t)
				print("INSPECT %s s%d tris=%d verts=%d comps=%d maxcomp=%d stalks=%d cards=%s aabb=%s" % [mi.name, si,
					idx.size() / 3, (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), tris.size(), mx,
					(comps["stalks"] as PackedInt32Array).size(), str(comps["cards"]), str(mi.mesh.get_aabb())])
	quit()
