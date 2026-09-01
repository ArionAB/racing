extends Node
## Verifica daca remaparea de sloturi a tufului (WorldProp._retint_tuff) chiar
## ajunge pe piesele nou-introduse. Citeste UV-ul dupa _ready si raporteaza
## slotul efectiv per model.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var seen := {}
	var stack: Array = [t]
	while not stack.is_empty():
		var q = stack.pop_back()
		for c in q.get_children(): stack.append(c)
		var n3 := q as Node3D
		if n3 == null or n3.scene_file_path.is_empty(): continue
		var stem := n3.scene_file_path.get_file().get_basename()
		if seen.has(stem): continue
		var st2: Array = [n3]
		while not st2.is_empty():
			var r = st2.pop_back()
			for c in r.get_children(): st2.append(c)
			var mi := r as MeshInstance3D
			if mi == null or mi.mesh == null: continue
			var uv = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
			if uv == null or uv.size() == 0: continue
			var slots := {}
			for u in uv: slots[int(floor(u.x * 32.0))] = true
			var k := slots.keys(); k.sort()
			print("%-24s parte=%-24s sloturi=%s" % [stem, r.name, str(k)])
			seen[stem] = true
			break
	get_tree().quit(0)
