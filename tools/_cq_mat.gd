extends Node
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track12.tscn") as PackedScene).instantiate()
	add_child(t)
	for i in 10:
		await get_tree().process_frame
	var world_mat := Palette.world_material()
	var mats := {}
	var tris := 0
	var cache := {}
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		var mesh: Mesh = null
		var mat: Material = null
		var cnt := 1
		if n is Node3D and not (n as Node3D).is_visible_in_tree():
			var p := n.get_parent(); var under := false
			while p != null:
				if p.name == &"DecorManual": under = true; break
				p = p.get_parent()
			if under: continue
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh; mat = (n as MeshInstance3D).material_override
		elif n is MultiMeshInstance3D:
			var mm := (n as MultiMeshInstance3D).multimesh
			if mm == null: continue
			mesh = mm.mesh; mat = (n as MultiMeshInstance3D).material_override; cnt = mm.instance_count
		else: continue
		if mesh == null: continue
		if mat == null and mesh.get_surface_count() > 0: mat = mesh.surface_get_material(0)
		for s in mesh.get_surface_count():
			var m: Material = mat
			if m == null: m = mesh.surface_get_material(s)
			if m != null: mats[m.get_instance_id()] = m.resource_name if m.resource_name else str(m)
		var rid := mesh.get_rid()
		if not cache.has(rid):
			var f := mesh.get_faces().size() / 3
			cache[rid] = f
		tris += cache[rid] * cnt
	print("MATERIALE UNICE: ", mats.size(), "   triunghiuri: ", tris)
	get_tree().quit()
