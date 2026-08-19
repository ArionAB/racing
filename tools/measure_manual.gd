extends SceneTree
## Ce randeaza REAL decorul manual dintr-o pista: triunghiuri per fisier sursa,
## numarand doar nodurile vizibile (ca probe_decor).
func _init() -> void:
	var tr := (load("res://scenes/tracks/Track10.tscn") as PackedScene).instantiate()
	root.add_child(tr)
	var dm := tr.get_node_or_null("DecorManual")
	if dm == null:
		print("fara DecorManual"); quit(); return
	var by := {}
	var tot := 0
	for inst in dm.get_children():
		var src := (inst as Node).scene_file_path.get_file()
		var t := _tris_visible(inst)
		by[src] = int(by.get(src, 0)) + t
		tot += t
	var keys := by.keys()
	keys.sort_custom(func(a, b): return by[a] > by[b])
	print("--- decor manual, doar ce se vede")
	for k in keys:
		print("  %-28s %8d tris" % [k, by[k]])
	print("  TOTAL %d instante, %d tris" % [dm.get_child_count(), tot])
	quit()

func _tris_visible(node: Node) -> int:
	var t := 0
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		var n3 := cur as Node3D
		if n3 != null and not n3.visible:
			continue
		var mi := cur as MeshInstance3D
		if mi != null and mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				t += (idx.size() / 3) if idx.size() > 0 else 0
		for ch in cur.get_children():
			stack.push_back(ch)
	return t
